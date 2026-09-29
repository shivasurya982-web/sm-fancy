const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Order = require('../models/Order');
const Notification = require('../models/Notification');
const { verifyToken, requireAdmin } = require('../middleware/auth');

// GET all users (Admin)
router.get('/', verifyToken, requireAdmin, async (req, res) => {
  try {
    // Only return customers (role: 'user') to the Customer Database view
    const users = await User.find({ role: 'user' }).select('-password');
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE own account
router.delete('/me', verifyToken, async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        // Cleanup data if needed (orders usually kept for records but anonymized)
        // Here we just delete for simplicity as requested
        await User.findByIdAndDelete(req.userId);
        await Notification.deleteMany({ userId: req.userId });

        res.json({ message: 'Account deleted successfully' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// DELETE user account (Admin)
router.delete('/:id', verifyToken, requireAdmin, async (req, res) => {
    try {
        if (req.params.id === req.userId) {
            return res.status(400).json({ message: 'You cannot delete your own admin account.' });
        }
        await User.findByIdAndDelete(req.params.id);
        res.json({ message: 'User deleted successfully' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// TOGGLE suspension (Admin)
router.put('/:id/suspend', verifyToken, requireAdmin, async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        user.isSuspended = !user.isSuspended;
        await user.save();

        res.json({ message: `User ${user.isSuspended ? 'suspended' : 'unsuspended'} successfully`, isSuspended: user.isSuspended });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
