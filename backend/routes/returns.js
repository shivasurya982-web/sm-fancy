const express = require('express');
const router = express.Router();
const Return = require('../models/Return');
const Order = require('../models/Order');
const { verifyToken, requireAdmin } = require('../middleware/auth');
const { upload, uploadToCloudinary } = require('../middleware/upload');

// Request a return
router.post('/', verifyToken, upload.array('images', 3), async (req, res) => {
    try {
        const { orderId, reason, description, items } = req.body;

        const order = await Order.findById(orderId);
        if (!order) return res.status(404).json({ message: 'Order not found' });

        if (order.userId.toString() !== req.userId) {
            return res.status(403).json({ message: 'Not authorized' });
        }

        const imageUrls = [];
        if (req.files && req.files.length > 0) {
            for (const file of req.files) {
                const result = await uploadToCloudinary(file.buffer, 'fancyworld/returns');
                imageUrls.push(result.secure_url);
            }
        }

        const returnRequest = new Return({
            orderId,
            userId: req.userId,
            reason,
            description,
            items: items ? JSON.parse(items) : [],
            images: imageUrls
        });

        await returnRequest.save();

        // Update order status
        order.status = 'Return Requested';
        await order.save();

        res.status(201).json(returnRequest);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Get my returns
router.get('/my', verifyToken, async (req, res) => {
    try {
        const returns = await Return.find({ userId: req.userId }).populate('orderId');
        res.json(returns);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Admin: Get all returns
router.get('/admin/all', verifyToken, requireAdmin, async (req, res) => {
    try {
        const returns = await Return.find().populate('userId', 'name email').populate('orderId');
        res.json(returns);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Admin: Update return status
router.put('/admin/:id/status', verifyToken, requireAdmin, async (req, res) => {
    try {
        const { status, adminComment } = req.body;
        const returnReq = await Return.findById(req.params.id);
        if (!returnReq) return res.status(404).json({ message: 'Return request not found' });

        returnReq.status = status;
        if (adminComment) returnReq.adminComment = adminComment;
        await returnReq.save();

        // Update related order status if needed
        if (status === 'Approved' || status === 'Refund Processed') {
            await Order.findByIdAndUpdate(returnReq.orderId, { status: `Return ${status}` });
        }

        res.json(returnReq);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
