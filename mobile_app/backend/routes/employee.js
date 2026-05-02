const express = require('express');
const router = express.Router();
const Lead = require('../models/Lead');
const CallReport = require('../models/CallReport');
const { protect, isEmployee } = require('../middleware/auth');

// All employee routes require authentication + employee role
router.use(protect, isEmployee);

// @route   GET /api/employee/dashboard
// @desc    Get employee dashboard stats
router.get('/dashboard', async (req, res) => {
  try {
    const employeeId = req.user._id;

    const totalAssigned = await Lead.countDocuments({ assignedTo: employeeId });
    const accepted = await Lead.countDocuments({ assignedTo: employeeId, status: 'accepted' });
    const rejected = await Lead.countDocuments({ assignedTo: employeeId, status: 'rejected' });
    const pending = await Lead.countDocuments({ assignedTo: employeeId, status: 'pending' });

    res.json({
      name: req.user.name,
      totalAssigned,
      accepted,
      rejected,
      pending,
    });
  } catch (error) {
    console.error('Employee dashboard error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/employee/leads
// @desc    Get leads assigned to the authenticated employee
router.get('/leads', async (req, res) => {
  try {
    const { status } = req.query;

    const filter = { assignedTo: req.user._id };
    if (status) filter.status = status;

    const leads = await Lead.find(filter).sort({ createdAt: -1 });

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
    console.error('Get employee leads error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   PUT /api/employee/leads/:id/status
// @desc    Update lead status (accept/reject)
router.put('/leads/:id/status', async (req, res) => {
  try {
    const { status } = req.body;

    if (!['accepted', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'Status must be "accepted" or "rejected"' });
    }

    const lead = await Lead.findById(req.params.id);
    if (!lead) {
      return res.status(404).json({ message: 'Lead not found' });
    }

    // Verify the lead is assigned to this employee
    if (!lead.assignedTo || lead.assignedTo.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to update this lead' });
    }

    lead.status = status;
    await lead.save();

    res.json(lead);
  } catch (error) {
    console.error('Update lead status error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/employee/leads/:id/report
// @desc    Submit call report for a lead
router.post('/leads/:id/report', async (req, res) => {
  try {
    const lead = await Lead.findById(req.params.id);
    if (!lead) {
      return res.status(404).json({ message: 'Lead not found' });
    }

    // Verify the lead is assigned to this employee
    if (!lead.assignedTo || lead.assignedTo.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to report on this lead' });
    }

    const {
      status,
      rejectionReason,
      propertyInterest,
      budgetRange,
      preferredLocation,
      bhk,
      desiredPlace,
      followUpDate,
      notes,
      extraInfo,
    } = req.body;

    if (!status || !['accepted', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'Status must be "accepted" or "rejected"' });
    }

    // Update lead status
    lead.status = status;
    await lead.save();

    // Check if report already exists, update or create
    let report = await CallReport.findOne({ leadId: lead._id });

    if (report) {
      // Update existing report
      report.status = status;
      report.rejectionReason = rejectionReason || '';
      report.propertyInterest = propertyInterest || '';
      report.budgetRange = budgetRange || '';
      report.preferredLocation = preferredLocation || '';
      report.bhk = bhk || '';
      report.desiredPlace = desiredPlace || '';
      report.followUpDate = followUpDate || null;
      report.notes = notes || '';
      report.extraInfo = extraInfo || '';
      await report.save();
    } else {
      // Create new report
      report = await CallReport.create({
        leadId: lead._id,
        employeeId: req.user._id,
        status,
        rejectionReason: rejectionReason || '',
        propertyInterest: propertyInterest || '',
        budgetRange: budgetRange || '',
        preferredLocation: preferredLocation || '',
        bhk: bhk || '',
        desiredPlace: desiredPlace || '',
        followUpDate: followUpDate || null,
        notes: notes || '',
        extraInfo: extraInfo || '',
      });
    }

    res.status(201).json({
      lead: lead.toObject(),
      report: report.toObject(),
    });
  } catch (error) {
    console.error('Submit report error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
