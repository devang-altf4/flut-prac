const mongoose = require('mongoose');

const uploadBatchSchema = new mongoose.Schema({
  fileName: {
    type: String,
    required: true,
  },
  totalLeads: {
    type: Number,
    required: true,
  },
  uploadedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  distributedAt: {
    type: Date,
    default: null,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('UploadBatch', uploadBatchSchema);
