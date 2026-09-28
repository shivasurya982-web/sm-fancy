const mongoose = require('mongoose');

const returnSchema = new mongoose.Schema({
  orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  items: [{
    product: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
    quantity: { type: Number, required: true },
    reason: { type: String, required: true }
  }],
  reason: { type: String, required: true },
  description: { type: String },
  images: [String],
  status: {
    type: String,
    enum: ['Pending', 'Approved', 'Rejected', 'Pickup Scheduled', 'Received', 'Refund Processed'],
    default: 'Pending'
  },
  adminComment: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('Return', returnSchema);
