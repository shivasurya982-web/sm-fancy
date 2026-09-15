const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');
const { verifyToken, requireAdmin } = require('../middleware/auth');

// GET /api/notifications - User: get own notifications
router.get('/', verifyToken, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const notifications = await Notification.find({
      $or: [{ userId: req.userId }, { userId: null }],
    })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit));

    const unreadCount = await Notification.countDocuments({
      $or: [{ userId: req.userId }, { userId: null }],
      isRead: false,
    });

    res.json({ notifications, unreadCount });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/notifications/clear-all - User deletes all own notifications
router.delete('/clear-all', verifyToken, async (req, res) => {
    try {
        // Only delete private notifications for this user
        await Notification.deleteMany({ userId: req.userId });
        res.json({ message: 'Notifications cleared' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// DELETE /api/notifications/:id - User deletes single notification
router.delete('/:id', verifyToken, async (req, res) => {
    try {
        await Notification.findOneAndDelete({ _id: req.params.id, userId: req.userId });
        res.json({ message: 'Notification deleted' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// PUT /api/notifications/mark-all-read
router.put('/mark-all-read', verifyToken, async (req, res) => {
  try {
    await Notification.updateMany(
      { $or: [{ userId: req.userId }, { userId: null }], isRead: false },
      { isRead: true }
    );
    res.json({ message: 'All notifications marked as read' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Helper function to create and emit notification
const createNotification = async (app, data) => {
    try {
        const notification = new Notification({
            ...data,
            isSent: true,
            sentAt: new Date()
        });
        await notification.save();

        const io = app.get('io');
        if (io) {
            if (data.userId) {
                io.to(data.userId.toString()).emit('new_notification', notification);
            } else {
                io.emit('new_notification', notification);
            }
        }
        return notification;
    } catch (err) {
        console.error('Error creating notification:', err);
    }
};

// POST /api/notifications - Admin: send notification
router.post('/', verifyToken, requireAdmin, async (req, res) => {
  try {
    const notification = await createNotification(req.app, req.body);
    res.status(201).json(notification);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = { router, createNotification };
