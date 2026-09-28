const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' }, // verified purchase
    rating: { type: Number, required: true, min: 1, max: 5 },
    title: { type: String, trim: true },
    review: { type: String, trim: true },
    images: [{ type: String }], // review photo URLs
    isVerifiedPurchase: { type: Boolean, default: false },
    helpfulCount: { type: Number, default: 0 },
    isApproved: { type: Boolean, default: true },
  },
  { timestamps: true }
);

// One review per user per product
reviewSchema.index({ userId: 1, productId: 1 }, { unique: true });

// After save/delete: update product rating aggregate removed
module.exports = mongoose.model('Review', reviewSchema);
