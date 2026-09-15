const express = require('express');
const router = express.Router();
const Chat = require('../models/Chat');
const User = require('../models/User');
const { verifyToken } = require('./auth');

// GET CHAT MESSAGES
router.get('/messages/:customerId', verifyToken, async (req, res) => {
  try {
    const customerId = req.params.customerId;

    if (req.userRole !== 'admin' && customerId !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Determine the real customer ID for the room
    const effectiveCustomerId = req.userRole === 'admin' ? customerId : req.userId;
    const roomId = [effectiveCustomerId, 'admin'].sort().join('_');

    const messages = await Chat.find({ roomId }).sort({ createdAt: 1 });

    // Mark as read
    const currentId = req.userRole === 'admin' ? 'admin' : req.userId;
    await Chat.updateMany(
        { roomId, receiverId: currentId, isRead: false },
        { isRead: true }
    );

    res.json(messages);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET CHAT THREADS (ADMIN)
router.get('/threads', verifyToken, async (req, res) => {
  try {
    if (req.userRole !== 'admin') {
      return res.status(403).json({ message: 'Admin only' });
    }

    // Find latest message from each room
    const threads = await Chat.aggregate([
        { $sort: { createdAt: -1 } },
        {
            $group: {
                _id: "$roomId",
                lastMessage: { $first: "$message" },
                lastMessageTime: { $first: "$createdAt" },
                senderId: { $first: "$senderId" },
                receiverId: { $first: "$receiverId" },
                isRead: { $first: "$isRead" }
            }
        },
        { $sort: { lastMessageTime: -1 } }
    ]);

    const result = [];
    for (const thread of threads) {
        // Customer ID is the one that isn't 'admin'
        const roomIdParts = thread._id.split('_');
        const customerId = roomIdParts.find(id => id !== 'admin');

        if (!customerId) continue;

        const user = await User.findById(customerId);
        if (!user) continue;

        const unreadCount = await Chat.countDocuments({
            roomId: thread._id,
            receiverId: 'admin',
            isRead: false
        });

        result.push({
            customerId,
            customerName: user.name,
            customerEmail: user.email,
            lastMessage: thread.lastMessage,
            lastMessageTime: thread.lastMessageTime,
            unreadCount
        });
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// SEND MESSAGE
router.post('/messages', verifyToken, async (req, res) => {
  try {
    const { customerId, message, location, image } = req.body;

    const senderId = req.userRole === 'admin' ? 'admin' : req.userId;
    const receiverId = req.userRole === 'admin' ? customerId : 'admin';

    const effectiveCustomerId = req.userRole === 'admin' ? customerId : req.userId;
    const roomId = [effectiveCustomerId, 'admin'].sort().join('_');

    const chat = new Chat({
      senderId,
      receiverId,
      roomId,
      message: message || '',
      location: location ? {
          latitude: location.lat || location.latitude,
          longitude: location.lng || location.longitude,
          address: location.address || ''
      } : null,
      image: image || ''
    });

    await chat.save();

    // Trigger Socket.io (if implemented)
    const io = req.app.get('io');
    if (io) {
        io.to(roomId).emit('receive_message', chat);
    }

    res.status(201).json(chat);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// EDIT MESSAGE
router.put('/messages/:id', verifyToken, async (req, res) => {
    try {
        const chat = await Chat.findById(req.params.id);
        if (!chat) return res.status(404).json({ message: 'Message not found' });

        const currentId = req.userRole === 'admin' ? 'admin' : req.userId;
        if (chat.senderId !== currentId) {
            return res.status(403).json({ message: 'Not authorized' });
        }

        chat.message = req.body.message;
        chat.isEdited = true;
        await chat.save();
        res.json(chat);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// DELETE MESSAGE
router.delete('/messages/:id', verifyToken, async (req, res) => {
    try {
        const chat = await Chat.findById(req.params.id);
        if (!chat) return res.status(404).json({ message: 'Message not found' });

        const currentId = req.userRole === 'admin' ? 'admin' : req.userId;
        if (chat.senderId !== currentId) {
            return res.status(403).json({ message: 'Not authorized' });
        }

        chat.isDeleted = true;
        chat.message = 'This message was deleted';
        await chat.save();
        res.json({ message: 'Message deleted' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
