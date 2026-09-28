const express = require('express');
const router = express.Router();
const Complaint = require('../models/Complaint');
const { verifyToken, requireAdmin } = require('../middleware/auth');

// User: File a complaint
router.post('/', verifyToken, async (req, res) => {
  try {
    const { subject, message } = req.body;
    const complaint = new Complaint({
      userId: req.userId,
      subject,
      message
    });
    await complaint.save();
    res.status(201).json(complaint);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Admin: Get all complaints
router.get('/admin/all', verifyToken, requireAdmin, async (req, res) => {
  try {
    const complaints = await Complaint.find()
      .populate('userId', 'name email phone')
      .sort({ createdAt: -1 });
    res.json(complaints);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Admin: Resolve/Respond
router.put('/admin/:id', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { status, response } = req.body;
    const complaint = await Complaint.findByIdAndUpdate(req.params.id, {
      status,
      response
    }, { new: true });
    res.json(complaint);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
