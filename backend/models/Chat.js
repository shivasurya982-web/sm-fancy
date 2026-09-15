const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema(
  {
    senderId: { type: String, required: true },
    receiverId: { type: String, required: true },
    roomId: { type: String, required: true, index: true }, // sorted user IDs joined by _
    message: { type: String, default: '' },
    image: { type: String, default: '' },   // image URL if sharing an image
    productId: { type: String },            // if sharing a product
    isRead: { type: Boolean, default: false },
    isDeleted: { type: Boolean, default: false },
    isEdited: { type: Boolean, default: false },
    location: {
        latitude: Number,
        longitude: Number,
        address: String
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Chat', chatMessageSchema);
