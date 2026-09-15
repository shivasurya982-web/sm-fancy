const mongoose = require('mongoose');

const appSettingsSchema = new mongoose.Schema({
  onboardingBanners: [{
    title: { type: String, required: true },
    description: { type: String, required: true },
    image: { type: String, required: true }
  }],
  homeBanners: [{
    title: { type: String, required: true },
    description: { type: String, required: true },
    image: { type: String, required: true }
  }],
  splashTagline: { type: String, default: 'Luxury that speaks. Elegance that stays.' },
  upiQrCode: { type: String, default: '' },
  upiId: { type: String, default: '' },

  // Shipping Fee Settings
  localCity: { type: String, default: 'Tiruchendur' },
  localShippingFee: { type: Number, default: 50 },
  standardShippingFee: { type: Number, default: 100 },

  // Owner Contact Info
  ownerPhone: { type: String, default: '9443039600' },
  shopImage: { type: String, default: 'assets/images/logo.png' },
  shopDescription: { type: String, default: 'Exquisite Jewellery & Fancy Collections since 1995. Quality and trust guaranteed.' }
}, { timestamps: true });

module.exports = mongoose.model('AppSettings', appSettingsSchema);
