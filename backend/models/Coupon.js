const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema(
  {
    code: { type: String, required: true, unique: true, uppercase: true, trim: true },
    description: { type: String, default: '' },

    discountType: {
      type: String,
      enum: ['percentage', 'flat'],
      default: 'percentage',
    },
    discountValue: { type: Number, required: true }, // % or flat INR

    minOrderAmount: { type: Number, default: 0 },
    maxDiscountAmount: { type: Number }, // cap for percentage coupons

    usageLimit: { type: Number, default: 100 }, // total uses allowed
    usageCount: { type: Number, default: 0 },   // total uses so far
    perUserLimit: { type: Number, default: 1 },

    applicableCategories: [{ type: String }], // empty = all categories
    applicableProducts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Product' }],

    validFrom: { type: Date, default: Date.now },
    validUntil: { type: Date, required: true },

    isActive: { type: Boolean, default: true },

    usedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Coupon', couponSchema);
