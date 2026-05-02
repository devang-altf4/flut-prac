const mongoose = require('mongoose');

const leadSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  phone: {
    type: String,
    required: true,
    trim: true,
  },
  assignedTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'rejected'],
    default: 'pending',
  },
  uploadBatchId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'UploadBatch',
    default: null,
  },
}, {
  timestamps: true,
});

// Indexes for fast queries
leadSchema.index({ assignedTo: 1, status: 1 });
leadSchema.index({ uploadBatchId: 1 });
leadSchema.index({ status: 1 });

module.exports = mongoose.model('Lead', leadSchema);
