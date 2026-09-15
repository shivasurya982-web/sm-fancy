const mongoose = require('mongoose');

const variantSchema = new mongoose.Schema({
  name: { type: String, required: true }, // e.g. "50ml", "Red", "XL"
  price: { type: Number },
  stock: { type: Number, default: 0 },
  sku: { type: String },
});

const productSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    description: { type: String, required: true },
    price: { type: Number, required: true },
    discount: { type: Number, default: 0 }, // percentage
    discountedPrice: { type: Number },

    category: {
      type: String,
      required: true,
    },
    brand: { type: String, default: '' },
    tags: [{ type: String }],

    // Images
    imageUrl: { type: String, default: '' }, // primary image (backward compat)
    images: [{ type: String }],              // all images
    video: { type: String },                 // product video URL

    // Stock & Variants
    stock: { type: Number, default: 100 },
    variants: [variantSchema],

    // Jewelry Specific Details
    metalType: { type: String },
    purity: { type: String },
    weight: { type: String },
    stoneInfo: { type: String },
    makingCharge: { type: Number },
    hallmark: { type: String },
    certification: { type: String },
    careInstructions: { type: String },
    authenticityInfo: { type: String },

    // Flags
    isFeatured: { type: Boolean, default: false },
    isNewArrival: { type: Boolean, default: false },
    isTrending: { type: Boolean, default: false },
    isFlashSale: { type: Boolean, default: false },
    flashSaleEndsAt: { type: Date },

    // Cloudinary public IDs for deletion
    imagePublicIds: [{ type: String }],
  },
  { timestamps: true }
);

// Auto-calculate discounted price
productSchema.pre('save', function (next) {
  if (this.discount > 0) {
    this.discountedPrice = Math.round(this.price * (1 - this.discount / 100));
  } else {
    this.discountedPrice = this.price;
  }
  next();
});

// Text search index
productSchema.index({ name: 'text', description: 'text', tags: 'text', brand: 'text' });

module.exports = mongoose.model('Product', productSchema);
