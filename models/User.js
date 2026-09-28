const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const addressSchema = new mongoose.Schema({
  label: { type: String, default: 'Home' },
  fullName: { type: String, required: true },
  phone: { type: String, required: true },
  addressLine1: { type: String, required: true },
  addressLine2: { type: String },
  city: { type: String, required: true },
  state: { type: String, required: true },
  pincode: { type: String, required: true },
  country: { type: String, default: 'India' },
  isDefault: { type: Boolean, default: false },
});

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    phone: { type: String, default: '' },
    password: { type: String, required: true },
    avatar: { type: String, default: '' },
    role: { type: String, enum: ['user', 'admin'], default: 'user' },

    addresses: [addressSchema],
    wishlist: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Product' }],

    loyaltyPoints: { type: Number, default: 0 },
    wallet: { type: Number, default: 0 },

    recoveryHint: { type: String, default: '' },

    notificationEnabled: { type: Boolean, default: true },
    locationEnabled: { type: Boolean, default: false },

    isPremium: { type: Boolean, default: false },
    premiumExpiry: { type: Date },

    fcmToken: { type: String },
    language: { type: String, default: 'en' },
    referralCode: { type: String, unique: true, sparse: true },

    isSuspended: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// Hash password before save
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

// Compare password
userSchema.methods.comparePassword = async function (plainText) {
  return bcrypt.compare(plainText, this.password);
};

module.exports = mongoose.model('User', userSchema);
