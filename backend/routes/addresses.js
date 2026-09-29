const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { verifyToken } = require('../middleware/auth');

// GET all addresses for current user
router.get('/', verifyToken, async (req, res) => {
    console.log(`[ADDRESSES] GET request from user: ${req.userId}`);
    try {
        const user = await User.findById(req.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });
        res.json(user.addresses || []);
    } catch (err) {
        console.error('[ADDRESSES] GET Error:', err);
        res.status(500).json({ message: err.message });
    }
});

// ADD a new address
router.post('/', verifyToken, async (req, res) => {
    console.log(`[ADDRESSES] POST request from user: ${req.userId}`);
    try {
        const user = await User.findById(req.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        const { fullName, phone, addressLine1, city, state, pincode, isDefault } = req.body;

        if (!fullName || !phone || !addressLine1 || !city || !pincode) {
            return res.status(400).json({ message: 'Required fields are missing' });
        }

        const newAddress = {
            fullName,
            phone,
            addressLine1,
            city,
            state: state || 'Tamil Nadu',
            pincode,
            isDefault: isDefault || false
        };

        if (isDefault) {
            user.addresses.forEach(a => a.isDefault = false);
        }

        user.addresses.push(newAddress);
        await user.save();

        res.status(201).json(user.addresses);
    } catch (err) {
        console.error('[ADDRESSES] POST Error:', err);
        res.status(500).json({ message: err.message });
    }
});

// DELETE an address
router.delete('/:id', verifyToken, async (req, res) => {
    console.log(`[ADDRESSES] DELETE request for id: ${req.params.id} from user: ${req.userId}`);
    try {
        const user = await User.findById(req.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        user.addresses = user.addresses.filter(a => a._id.toString() !== req.params.id);
        await user.save();

        res.json(user.addresses);
    } catch (err) {
        console.error('[ADDRESSES] DELETE Error:', err);
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
