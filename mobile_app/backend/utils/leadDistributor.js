const Lead = require('../models/Lead');

/**
 * Distributes a set of leads equally among active employees.
 * First remainder employees receive one extra lead, matching the plan.
 */
const distributeLeads = async (leadIds, employees) => {
  const totalLeads = leadIds.length;

  if (!employees || employees.length === 0) {
    if (totalLeads > 0) {
      await Lead.updateMany(
        { _id: { $in: leadIds } },
        { $set: { assignedTo: null } }
      );
    }

    return {
      distributed: false,
      message: 'No active employees found. Leads stored as unassigned.',
      totalLeads,
      employeeCount: 0,
      assignments: [],
    };
  }

  const employeeCount = employees.length;
  const leadsPerEmployee = Math.floor(totalLeads / employeeCount);
  const remainder = totalLeads % employeeCount;
  const assignments = [];
  let leadIndex = 0;

  for (let i = 0; i < employeeCount; i += 1) {
    const employee = employees[i];
    const count = leadsPerEmployee + (i < remainder ? 1 : 0);
    const assignedLeadIds = leadIds.slice(leadIndex, leadIndex + count);

    if (assignedLeadIds.length > 0) {
      await Lead.updateMany(
        { _id: { $in: assignedLeadIds } },
        { $set: { assignedTo: employee._id } }
      );
    }

    assignments.push({
      employeeId: employee._id,
      employeeName: employee.name,
      leadsAssigned: assignedLeadIds.length,
    });

    leadIndex += count;
  }

  return {
    distributed: true,
    message: `${totalLeads} leads distributed among ${employeeCount} employees.`,
    totalLeads,
    employeeCount,
    leadsPerEmployee,
    remainder,
    assignments,
  };
};

/**
 * Redistributes pending leads when employee capacity changes.
 *
 * includeAssignedActive=true is used when an employee is created/deactivated so
 * every untouched pending lead is balanced uniquely across active employees.
 */
const redistributePendingLeads = async (employees, options = {}) => {
  const { includeAssignedActive = false } = options;
  const activeEmployeeIds = (employees || []).map(employee => employee._id);

  const filter = { status: 'pending' };
  if (!includeAssignedActive) {
    filter.$or = [
      { assignedTo: null },
      { assignedTo: { $nin: activeEmployeeIds } },
    ];
  }

  const pendingLeads = await Lead.find(filter).sort({ createdAt: 1 });
  if (pendingLeads.length === 0) {
    return {
      distributed: false,
      message: 'No pending leads available for redistribution.',
      totalLeads: 0,
      employeeCount: employees ? employees.length : 0,
      assignments: [],
    };
  }

  return distributeLeads(pendingLeads.map(lead => lead._id), employees || []);
};

module.exports = { distributeLeads, redistributePendingLeads };
