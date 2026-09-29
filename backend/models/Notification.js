const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    // null = broadcast to all users
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    forAdmin: { type: Boolean, default: false },

    title: { type: String, required: true },
    body: { type: String, required: true },
    image: { type: String },

    type: {
      type: String,
      enum: ['order', 'offer', 'promotion', 'system', 'chat', 'complaint', 'stock', 'broadcast'],
      default: 'system',
    },

    // Deep link data
    data: {
      screen: { type: String },
      id: { type: String },
    },

    isRead: { type: Boolean, default: false },
    isSent: { type: Boolean, default: false },
    sentAt: { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Notification', notificationSchema);
