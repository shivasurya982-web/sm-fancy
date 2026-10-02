const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { verifyToken } = require('../middleware/auth');

const JWT_SECRET = process.env.JWT_SECRET || 'fancyworld_secret';

// Register
router.post('/register', async (req, res) => {
  const { name, email, password, role, recoveryHint } = req.body;
  try {
    let user = await User.findOne({ email });
    if (user) return res.status(400).json({ message: 'User already exists' });

    user = new User({
      name,
      email,
      password,
      recoveryHint: recoveryHint || '',
      role: role || 'user',
      referralCode: Math.random().toString(36).substring(2, 8).toUpperCase(),
    });

    await user.save();

    // Check if referred by someone
    if (req.body.referredBy) {
        const referrer = await User.findOne({ referralCode: req.body.referredBy.toUpperCase() });
        if (referrer) {
            // Reward referrer
            referrer.loyaltyPoints += 50;
            await referrer.save();
        }
    }

    const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, {
      expiresIn: '7d',
    });

    res.status(201).json({
      token,
      user: { id: user._id, name: user.name, email: user.email, role: user.role },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Invalid email or password' });

    if (user.isSuspended) {
        return res.status(403).json({ message: 'ACCOUNT SUSPENDED. Please contact admin for support.' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) return res.status(400).json({ message: 'Invalid email or password' });

    const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, {
      expiresIn: '7d',
    });

    res.json({
      token,
      user: { id: user._id, name: user.name, email: user.email, role: user.role },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/auth/me (Get Profile)
router.get('/me', verifyToken, async (req, res) => {
    try {
      const user = await User.findById(req.userId).select('-password');
      if (!user) return res.status(404).json({ message: 'User not found' });
      res.json(user);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
});

// GET /api/auth/admin-info
router.get('/admin-info', async (req, res) => {
    try {
        const admin = await User.findOne({ role: 'admin' }).select('name avatar');
        if (!admin) return res.status(404).json({ message: 'Admin not found' });
        res.json(admin);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// PUT /api/auth/me (Update Profile)
router.put('/me', verifyToken, async (req, res) => {
    try {
        const { name, phone, avatar, email } = req.body;
        const user = await User.findById(req.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        if (name) user.name = name;
        if (phone) user.phone = phone;
        if (avatar) user.avatar = avatar;
        if (email) {
            const existing = await User.findOne({ email, _id: { $ne: req.userId } });
            if (existing) return res.status(400).json({ message: 'Email already in use' });
            user.email = email;
        }

        await user.save();
        res.json(user);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// GET /api/auth/recovery-hint/:email
router.get('/recovery-hint/:email', async (req, res) => {
    try {
        const user = await User.findOne({ email: req.params.email });
        if (!user) return res.status(404).json({ message: 'User not found' });

        // Return a masked or partial hint if needed, or just the hint if it's safe
        res.json({ recoveryHint: user.recoveryHint });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// POST /api/auth/forgot-password
router.post('/forgot-password', async (req, res) => {
    const { email, recoveryHint, newPassword } = req.body;
    try {
        const user = await User.findOne({ email });
        if (!user) return res.status(404).json({ message: 'User not found' });

        if (user.recoveryHint !== recoveryHint) {
            return res.status(400).json({ message: 'Incorrect recovery hint' });
        }

        user.password = newPassword;
        await user.save();
        res.json({ message: 'Password reset successfully' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// PUT /api/auth/change-password
router.put('/change-password', verifyToken, async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    try {
      const user = await User.findById(req.userId);
      if (!user) return res.status(404).json({ message: 'User not found' });

      const isMatch = await user.comparePassword(currentPassword);
      if (!isMatch) return res.status(400).json({ message: 'Incorrect current password' });

      user.password = newPassword;
      await user.save();

      res.json({ message: 'Password changed successfully' });
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
});

// PUT /api/auth/recovery-hint
router.put('/recovery-hint', verifyToken, async (req, res) => {
  const recoveryHint = req.body.recoveryHint?.trim();
  if (!recoveryHint) {
    return res.status(400).json({ message: 'Recovery hint is required' });
  }

  try {
    const user = await User.findById(req.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.recoveryHint = recoveryHint;
    await user.save();

    res.json({ message: 'Recovery hint changed successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/auth/preferences
router.put('/preferences', verifyToken, async (req, res) => {
    const { notificationEnabled, locationEnabled } = req.body;
    try {
        const user = await User.findByIdAndUpdate(req.userId, {
            notificationEnabled,
            locationEnabled
        }, { new: true });
        res.json(user);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// GET /api/auth/users (admin)
router.get('/users', verifyToken, async (req, res) => {
  if (req.userRole !== 'admin') {
    return res.status(403).json({ message: 'Access denied. Admins only.' });
  }
  try {
    const users = await User.find({ role: 'user' }).select('-password');
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = { router, verifyToken };
