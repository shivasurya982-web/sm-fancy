const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const User = require('../models/User');
const Product = require('../models/Product');
const { verifyToken } = require('../middleware/auth');
// Get admin dashboard analytics (admin only)
router.get('/dashboard', verifyToken, async (req, res) => {
  if (req.userRole !== 'admin') {
    return res.status(403).json({ message: 'Access denied. Admins only.' });
  }

  try {
    // 1. Total Sales (aggregate sum of all order totals)
    const salesAggregate = await Order.aggregate([
      {
        $group: {
          _id: null,
          total: { $sum: '$total' }
        }
      }
    ]);
    const totalSales = salesAggregate.length > 0 ? salesAggregate[0].total : 0;

    // 2. Total Customers (role: 'user')
    const totalCustomers = await User.countDocuments({ role: 'user' });

    // 3. New Orders Count (status: 'Placed', 'Packed', 'Shipped')
    const newOrders = await Order.countDocuments({
      status: { $in: ['Placed', 'Packed', 'Shipped'] }
    });

    // 4. New Customers (registered in last 30 days)
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const newCustomers = await User.countDocuments({
      role: 'user',
      createdAt: { $gte: thirtyDaysAgo }
    });

    // 5. Monthly Sales Trends (aggregate by month of the current year)
    // For demo/simplicity, if data is sparse, return custom formatted data blended with actual DB counts
    const trendsAggregate = await Order.aggregate([
      {
        $group: {
          _id: { $month: '$createdAt' },
          sales: { $sum: '$total' }
        }
      },
      {
        $sort: { _id: 1 }
      }
    ]);

    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const salesTrends = monthNames.map((name, index) => {
      const match = trendsAggregate.find((t) => t._id === index + 1);
      return {
        month: name,
        sales: match ? match.sales : 0,
      };
    });

    // 6. Top Categories distribution
    const categoryData = await Order.aggregate([
      { $unwind: '$items' },
      {
        $lookup: {
          from: 'products',
          localField: 'items.product',
          foreignField: '_id',
          as: 'prod'
        }
      },
      { $unwind: '$prod' },
      {
        $group: {
          _id: '$prod.category',
          sales: { $sum: { $multiply: ['$items.price', '$items.quantity'] } }
        }
      }
    ]);

    const topCategories = categoryData.map((c) => ({
      category: c._id,
      sales: Math.round(c.sales),
    }));

    // 7. Payment Methods breakdown
    const paymentData = await Order.aggregate([
      {
        $group: {
          _id: '$paymentMethod',
          count: { $sum: 1 }
        }
      }
    ]);

    const paymentMethods = paymentData.map((p) => ({
      method: p._id || 'Unknown',
      count: p.count,
    }));

    res.json({
      totalSales: totalSales,
      totalCustomers: totalCustomers,
      newOrdersCount: newOrders,
      newCustomersCount: newCustomers,
      salesTrends,
      topCategories,
      paymentMethods,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
