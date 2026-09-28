const express = require('express');
const router = express.Router();

const User = require('../models/User');
const Product = require('../models/Product');
const Order = require('../models/Order');

const { verifyToken, requireAdmin } = require('../middleware/auth');

router.get('/stats', verifyToken, requireAdmin, async (req, res) => {
  try {
    const totalUsers = await User.countDocuments({ role: 'user' });

    const totalProducts = await Product.countDocuments();

    const totalOrders = await Order.countDocuments();

    const orders = await Order.find();

    const totalRevenue = orders.reduce(
      (sum, order) => sum + (order.total || 0),
      0
    );

    res.json({
      totalUsers,
      totalProducts,
      totalOrders,
      totalRevenue,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
});

module.exports = router;