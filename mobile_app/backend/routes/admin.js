const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const User = require('../models/User');
const Lead = require('../models/Lead');
const CallReport = require('../models/CallReport');
const UploadBatch = require('../models/UploadBatch');
const { protect, isAdmin } = require('../middleware/auth');
const { distributeLeads, redistributePendingLeads } = require('../utils/leadDistributor');
const { parseLeadFile } = require('../utils/fileParser');
const { generateReport } = require('../utils/pdfGenerator');

// Multer config for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '..', 'uploads');
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, `leads_${Date.now()}${path.extname(file.originalname)}`);
  },
});

const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (['.csv', '.xlsx', '.xls'].includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Only CSV and Excel files are allowed'));
    }
  },
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
});

// All admin routes require auth + admin role
router.use(protect, isAdmin);

// ==========================================
// EMPLOYEE MANAGEMENT
// ==========================================

// @route   POST /api/admin/employees
// @desc    Create a new employee
router.post('/employees', async (req, res) => {
  try {
    const { username, password, name } = req.body;

    if (!username || !password || !name) {
      return res.status(400).json({ message: 'Please provide name, username, and password' });
    }

    // Check if username exists
    const existing = await User.findOne({ username: username.toLowerCase() });
    if (existing) {
      return res.status(400).json({ message: 'Username already exists' });
    }

    const employee = await User.create({
      username: username.toLowerCase(),
      password,
      name,
      role: 'employee',
      createdBy: req.user._id,
    });

    // Redistribute pending unassigned leads when new employee is added
    const activeEmployees = await User.find({ role: 'employee', isActive: true });
    const redistResult = await redistributePendingLeads(activeEmployees, { includeAssignedActive: true });

    res.status(201).json({
      _id: employee._id,
      username: employee.username,
      name: employee.name,
      role: employee.role,
      isActive: employee.isActive,
      redistribution: redistResult || null,
    });
  } catch (error) {
    console.error('Create employee error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/admin/employees
// @desc    List all employees
router.get('/employees', async (req, res) => {
  try {
    const employees = await User.find({ role: 'employee' })
      .select('-password')
      .sort({ createdAt: -1 });

    // Get lead stats for each employee
    const employeesWithStats = await Promise.all(
      employees.map(async (emp) => {
        const totalAssigned = await Lead.countDocuments({ assignedTo: emp._id });
        const accepted = await Lead.countDocuments({ assignedTo: emp._id, status: 'accepted' });
        const rejected = await Lead.countDocuments({ assignedTo: emp._id, status: 'rejected' });
        const pending = await Lead.countDocuments({ assignedTo: emp._id, status: 'pending' });

        return {
          ...emp.toObject(),
          stats: { totalAssigned, accepted, rejected, pending },
        };
      })
    );

    res.json(employeesWithStats);
  } catch (error) {
    console.error('List employees error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   DELETE /api/admin/employees/:id
// @desc    Deactivate employee & redistribute their pending leads
router.delete('/employees/:id', async (req, res) => {
  try {
    const employee = await User.findById(req.params.id);
    if (!employee) {
      return res.status(404).json({ message: 'Employee not found' });
    }

    if (employee.role === 'admin') {
      return res.status(400).json({ message: 'Cannot deactivate admin' });
    }

    // Deactivate the employee
    employee.isActive = false;
    await employee.save();

    // Redistribute their pending leads to remaining active employees
    const activeEmployees = await User.find({ role: 'employee', isActive: true });
    const redistResult = await redistributePendingLeads(activeEmployees, { includeAssignedActive: true });

    res.json({
      message: `Employee ${employee.name} deactivated.`,
      redistribution: redistResult || null,
    });
  } catch (error) {
    console.error('Delete employee error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// ==========================================
// LEAD MANAGEMENT
// ==========================================

// @route   POST /api/admin/upload-leads
// @desc    Upload CSV/Excel file, parse & distribute leads
router.post('/upload-leads', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Please upload a file' });
    }

    // Parse the uploaded file
    const parsedLeads = await parseLeadFile(req.file.path);

    // Create upload batch record
    const batch = await UploadBatch.create({
      fileName: req.file.originalname,
      totalLeads: parsedLeads.length,
      uploadedBy: req.user._id,
    });

    // Insert all leads into database
    const leadDocs = parsedLeads.map(lead => ({
      name: lead.name,
      phone: lead.phone,
      status: 'pending',
      uploadBatchId: batch._id,
    }));

    const insertedLeads = await Lead.insertMany(leadDocs);
    const leadIds = insertedLeads.map(l => l._id);

    // Get active employees and distribute
    const activeEmployees = await User.find({ role: 'employee', isActive: true });
    const distResult = await distributeLeads(leadIds, activeEmployees);

    // Update batch distribution timestamp
    batch.distributedAt = new Date();
    await batch.save();

    // Clean up uploaded file
    fs.unlink(req.file.path, () => {});

    res.status(201).json({
      message: `Successfully uploaded ${parsedLeads.length} leads from ${req.file.originalname}`,
      batchId: batch._id,
      distribution: distResult,
    });
  } catch (error) {
    // Clean up file on error
    if (req.file) fs.unlink(req.file.path, () => {});
    console.error('Upload leads error:', error);
    res.status(500).json({ message: error.message || 'Server error' });
  }
});

// @route   GET /api/admin/leads
// @desc    View all leads with optional filters
router.get('/leads', async (req, res) => {
  try {
    const { status, employeeId, batchId, search } = req.query;

    const filter = {};
    if (status) filter.status = status;
    if (employeeId) filter.assignedTo = employeeId;
    if (batchId) filter.uploadBatchId = batchId;
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }

    const leads = await Lead.find(filter)
      .populate('assignedTo', 'name username')
      .sort({ createdAt: -1 });

    // Get call reports for leads that have them
    const leadsWithReports = await Promise.all(
      leads.map(async (lead) => {
        const report = await CallReport.findOne({ leadId: lead._id });
        return {
          ...lead.toObject(),
          report: report ? report.toObject() : null,
        };
      })
    );

    res.json(leadsWithReports);
  } catch (error) {
    console.error('Get leads error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   DELETE /api/admin/leads
// @desc    Delete ALL leads, call reports, and upload batches (fresh start)
router.delete('/leads', async (req, res) => {
  try {
    const leadCount = await Lead.countDocuments();
    await CallReport.deleteMany({});
    await Lead.deleteMany({});
    await UploadBatch.deleteMany({});

    res.json({
      message: `Successfully deleted ${leadCount} leads and all associated data.`,
      deletedLeads: leadCount,
    });
  } catch (error) {
    console.error('Delete all leads error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// ==========================================
// DASHBOARD & REPORTS
// ==========================================

// @route   GET /api/admin/dashboard
// @desc    Dashboard stats
router.get('/dashboard', async (req, res) => {
  try {
    const totalLeads = await Lead.countDocuments();
    const accepted = await Lead.countDocuments({ status: 'accepted' });
    const rejected = await Lead.countDocuments({ status: 'rejected' });
    const pending = await Lead.countDocuments({ status: 'pending' });
    const totalEmployees = await User.countDocuments({ role: 'employee', isActive: true });

    // Per-employee breakdown
    const employees = await User.find({ role: 'employee', isActive: true }).select('name username');
    const employeeStats = await Promise.all(
      employees.map(async (emp) => {
        const assigned = await Lead.countDocuments({ assignedTo: emp._id });
        const empAccepted = await Lead.countDocuments({ assignedTo: emp._id, status: 'accepted' });
        const empRejected = await Lead.countDocuments({ assignedTo: emp._id, status: 'rejected' });
        const empPending = await Lead.countDocuments({ assignedTo: emp._id, status: 'pending' });

        return {
          _id: emp._id,
          name: emp.name,
          username: emp.username,
          assigned,
          accepted: empAccepted,
          rejected: empRejected,
          pending: empPending,
        };
      })
    );

    res.json({
      totalLeads,
      accepted,
      rejected,
      pending,
      totalEmployees,
      employeeStats,
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/admin/reports/download
// @desc    Download PDF report
router.get('/reports/download', async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const leadFilter = {};
    if (startDate || endDate) {
      leadFilter.createdAt = {};
      if (startDate) leadFilter.createdAt.$gte = new Date(startDate);
      if (endDate) leadFilter.createdAt.$lte = new Date(endDate);
    }

    const totalLeads = await Lead.countDocuments(leadFilter);
    const accepted = await Lead.countDocuments({ ...leadFilter, status: 'accepted' });
    const rejected = await Lead.countDocuments({ ...leadFilter, status: 'rejected' });
    const pending = await Lead.countDocuments({ ...leadFilter, status: 'pending' });
    const employeeCount = await User.countDocuments({ role: 'employee', isActive: true });

    // Employee stats
    const employees = await User.find({ role: 'employee', isActive: true }).select('name');
    const employeeStats = await Promise.all(
      employees.map(async (emp) => ({
        name: emp.name,
        assigned: await Lead.countDocuments({ ...leadFilter, assignedTo: emp._id }),
        accepted: await Lead.countDocuments({ ...leadFilter, assignedTo: emp._id, status: 'accepted' }),
        rejected: await Lead.countDocuments({ ...leadFilter, assignedTo: emp._id, status: 'rejected' }),
        pending: await Lead.countDocuments({ ...leadFilter, assignedTo: emp._id, status: 'pending' }),
      }))
    );

    // Hot leads with reports
    const hotLeadDocs = await Lead.find({ ...leadFilter, status: 'accepted' });
    const hotLeads = await Promise.all(
      hotLeadDocs.map(async (lead) => {
        const report = await CallReport.findOne({ leadId: lead._id }).populate('employeeId', 'name');
        return {
          name: lead.name,
          phone: lead.phone,
          report: report ? {
            ...report.toObject(),
            employeeName: report.employeeId?.name || 'N/A',
          } : null,
        };
      })
    );

    // Cold leads with reports
    const coldLeadDocs = await Lead.find({ ...leadFilter, status: 'rejected' });
    const coldLeads = await Promise.all(
      coldLeadDocs.map(async (lead) => {
        const report = await CallReport.findOne({ leadId: lead._id }).populate('employeeId', 'name');
        return {
          name: lead.name,
          phone: lead.phone,
          report: report ? {
            ...report.toObject(),
            employeeName: report.employeeId?.name || 'N/A',
          } : null,
        };
      })
    );

    generateReport(res, {
      summary: { total: totalLeads, accepted, rejected, pending, employeeCount },
      employeeStats,
      hotLeads,
      coldLeads,
    });
  } catch (error) {
    console.error('Report download error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
