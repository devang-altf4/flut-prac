const mongoose = require('mongoose');

const callReportSchema = new mongoose.Schema({
  leadId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Lead',
    required: true,
  },
  employeeId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  status: {
    type: String,
    enum: ['accepted', 'rejected'],
    required: true,
  },
  // Rejection fields
  rejectionReason: {
    type: String,
    default: '',
  },
  // Acceptance fields
  propertyInterest: {
    type: String,
    default: '',
  },
  budgetRange: {
    type: String,
    default: '',
  },
  preferredLocation: {
    type: String,
    default: '',
  },
  bhk: {
    type: String,
    default: '',
  },
  desiredPlace: {
    type: String,
    default: '',
  },
  followUpDate: {
    type: Date,
    default: null,
  },
  notes: {
    type: String,
    default: '',
  },
  extraInfo: {
    type: String,
    default: '',
  },
}, {
  timestamps: true,
});

callReportSchema.index({ leadId: 1 });
callReportSchema.index({ employeeId: 1 });

module.exports = mongoose.model('CallReport', callReportSchema);
