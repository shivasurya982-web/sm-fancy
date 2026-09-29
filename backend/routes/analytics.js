const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Order = require('../models/Order');
const User = require('../models/User');
const Product = require('../models/Product');
const Review = require('../models/Review');
const { verifyToken, requireAdmin } = require('../middleware/auth');

// Helper to get date ranges
const getDateRange = (period) => {
  const now = new Date();
  let start = new Date();
  let prevStart = new Date();
  let prevEnd = new Date();

  switch (period) {
    case 'today':
      start.setHours(0, 0, 0, 0);
      prevStart.setDate(prevStart.getDate() - 1);
      prevStart.setHours(0, 0, 0, 0);
      prevEnd.setDate(prevEnd.getDate() - 1);
      prevEnd.setHours(23, 59, 59, 999);
      break;
    case 'yesterday':
      start.setDate(start.getDate() - 1);
      start.setHours(0, 0, 0, 0);
      now.setDate(now.getDate() - 1);
      now.setHours(23, 59, 59, 999);
      prevStart.setDate(prevStart.getDate() - 2);
      prevStart.setHours(0, 0, 0, 0);
      prevEnd.setDate(prevEnd.getDate() - 2);
      prevEnd.setHours(23, 59, 59, 999);
      break;
    case '7days':
      start.setDate(start.getDate() - 7);
      prevStart.setDate(prevStart.getDate() - 14);
      prevEnd.setDate(prevEnd.getDate() - 7);
      break;
    case '30days':
      start.setDate(start.getDate() - 30);
      prevStart.setDate(prevStart.getDate() - 60);
      prevEnd.setDate(prevEnd.getDate() - 30);
      break;
    case 'thisMonth':
      start = new Date(now.getFullYear(), now.getMonth(), 1);
      prevStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      prevEnd = new Date(now.getFullYear(), now.getMonth(), 0);
      break;
    case 'lastMonth':
      start = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      now = new Date(now.getFullYear(), now.getMonth(), 0);
      prevStart = new Date(now.getFullYear(), now.getMonth() - 2, 1);
      prevEnd = new Date(now.getFullYear(), now.getMonth() - 1, 0);
      break;
    case 'thisYear':
      start = new Date(now.getFullYear(), 0, 1);
      prevStart = new Date(now.getFullYear() - 1, 0, 1);
      prevEnd = new Date(now.getFullYear() - 1, 11, 31);
      break;
    default:
      start.setDate(start.getDate() - 30); // Default 30 days
      prevStart.setDate(prevStart.getDate() - 60);
      prevEnd.setDate(prevEnd.getDate() - 30);
  }

  return { start, end: now, prevStart, prevEnd };
};

// GET /api/analytics/dashboard?period=30days
router.get('/dashboard', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { period = '30days' } = req.query;
    const { start, end, prevStart, prevEnd } = getDateRange(period);

    // 1. Basic Stats (Current vs Previous)
    const statsQuery = (s, e) => [
      { $match: { createdAt: { $gte: s, $lte: e }, paymentStatus: { $ne: 'Failed' }, status: { $ne: 'Cancelled' } } },
      {
        $group: {
          _id: null,
          sales: { $sum: '$total' },
          orders: { $sum: 1 },
          productsSold: { $sum: { $sum: '$items.quantity' } }
        }
      }
    ];

    const currentStats = await Order.aggregate(statsQuery(start, end));
    const prevStats = await Order.aggregate(statsQuery(prevStart, prevEnd));

    const cur = currentStats[0] || { sales: 0, orders: 0, productsSold: 0 };
    const prev = prevStats[0] || { sales: 0, orders: 0, productsSold: 0 };

    // 2. Customer Stats
    const totalCustomers = await User.countDocuments({ role: 'user' });
    const newCustomers = await User.countDocuments({ role: 'user', createdAt: { $gte: start, $lte: end } });
    const prevNewCustomers = await User.countDocuments({ role: 'user', createdAt: { $gte: prevStart, $lte: prevEnd } });

    // 3. Refunds/Returns
    const returns = await Order.countDocuments({ status: 'Returned', updatedAt: { $gte: start, $lte: end } });
    const prevReturns = await Order.countDocuments({ status: 'Returned', updatedAt: { $gte: prevStart, $lte: prevEnd } });

    // 4. Sales Trend
    // Determine group format based on period
    let dateFormat = "%Y-%m-%d";
    if (period === 'thisYear') dateFormat = "%Y-%m";

    const salesTrend = await Order.aggregate([
      { $match: { createdAt: { $gte: start, $lte: end }, paymentStatus: { $ne: 'Failed' }, status: { $ne: 'Cancelled' } } },
      {
        $group: {
          _id: { $dateToString: { format: dateFormat, date: "$createdAt" } },
          sales: { $sum: "$total" }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // 5. Top 5 Best-Selling Products (by Units)
    const topProductsUnits = await Order.aggregate([
      { $match: { createdAt: { $gte: start, $lte: end }, paymentStatus: { $ne: 'Failed' }, status: { $ne: 'Cancelled' } } },
      { $unwind: "$items" },
      {
        $group: {
          _id: "$items.product",
          name: { $first: "$items.name" },
          image: { $first: "$items.image" },
          sold: { $sum: "$items.quantity" },
          revenue: { $sum: { $multiply: ["$items.price", "$items.quantity"] } }
        }
      },
      { $sort: { sold: -1 } },
      { $limit: 5 },
      {
          $lookup: {
              from: 'products',
              localField: '_id',
              foreignField: '_id',
              as: 'productInfo'
          }
      },
      { $unwind: "$productInfo" },
      {
          $project: {
              name: 1,
              image: 1,
              sold: 1,
              revenue: 1,
              stock: "$productInfo.stock"
          }
      }
    ]);

    // 6. Top Products by Revenue
    const topProductsRevenue = await Order.aggregate([
        { $match: { createdAt: { $gte: start, $lte: end }, paymentStatus: { $ne: 'Failed' }, status: { $ne: 'Cancelled' } } },
        { $unwind: "$items" },
        {
          $group: {
            _id: "$items.product",
            name: { $first: "$items.name" },
            image: { $first: "$items.image" },
            sold: { $sum: "$items.quantity" },
            revenue: { $sum: { $multiply: ["$items.price", "$items.quantity"] } }
          }
        },
        { $sort: { revenue: -1 } },
        { $limit: 5 }
      ]);

    // 7. Category Performance
    const categoryPerformance = await Order.aggregate([
      { $match: { createdAt: { $gte: start, $lte: end }, paymentStatus: { $ne: 'Failed' }, status: { $ne: 'Cancelled' } } },
      { $unwind: "$items" },
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
          _id: "$prod.category",
          sales: { $sum: { $multiply: ["$items.price", "$items.quantity"] } },
          orders: { $sum: 1 },
          units: { $sum: "$items.quantity" }
        }
      },
      { $sort: { sales: -1 } }
    ]);

    // 8. Order Status Breakdown
    const orderStatuses = await Order.aggregate([
        { $match: { createdAt: { $gte: start, $lte: end } } },
        { $group: { _id: "$status", count: { $sum: 1 } } }
    ]);

    // 9. Payment Methods
    const paymentMethods = await Order.aggregate([
        { $match: { createdAt: { $gte: start, $lte: end }, paymentStatus: { $ne: 'Failed' } } },
        { $group: { _id: "$paymentMethod", count: { $sum: 1 } } }
    ]);

    // 10. Products Needing Attention
    const attentionProducts = await Product.find({
        $or: [
            { stock: 0 },
            { stock: { $lt: 5 } } // Low stock threshold
        ]
    }).select('name stock images imageUrl category').limit(10);

    // 11. Most Wishlisted
    const mostWishlisted = await User.aggregate([
        { $unwind: "$wishlist" },
        { $group: { _id: "$wishlist", count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 5 },
        {
            $lookup: {
                from: 'products',
                localField: '_id',
                foreignField: '_id',
                as: 'p'
            }
        },
        { $unwind: "$p" },
        {
            $project: {
                name: "$p.name",
                image: "$p.imageUrl",
                stock: "$p.stock",
                wishlistCount: "$count"
            }
        }
    ]);

    // 12. Feedback Overview
    const feedback = await Review.aggregate([
        {
            $group: {
                _id: null,
                avgRating: { $avg: "$rating" },
                totalReviews: { $sum: 1 },
                stars: {
                    $push: "$rating"
                }
            }
        }
    ]);

    let ratingData = { avgRating: 0, totalReviews: 0, distribution: { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 } };
    if (feedback.length > 0) {
        ratingData.avgRating = feedback[0].avgRating;
        ratingData.totalReviews = feedback[0].totalReviews;
        feedback[0].stars.forEach(s => {
            ratingData.distribution[Math.floor(s)] = (ratingData.distribution[Math.floor(s)] || 0) + 1;
        });
    }

    // 13. Location Analytics
    const locations = await Order.aggregate([
        { $match: { createdAt: { $gte: start, $lte: end } } },
        {
            $group: {
                _id: { state: "$address.state", city: "$address.city" },
                orders: { $sum: 1 },
                revenue: { $sum: "$total" }
            }
        },
        { $sort: { revenue: -1 } },
        { $limit: 10 }
    ]);

    // 14. Business Insights Logic
    const insights = [];
    if (cur.sales > prev.sales) insights.push({ type: 'good', title: 'SALES', text: 'Sales increased compared with the previous period.' });
    else if (cur.sales < prev.sales) insights.push({ type: 'bad', title: 'SALES', text: 'Sales decreased compared with the previous period.' });

    if (topProductsUnits.length > 0) insights.push({ type: 'info', title: 'PRODUCT', text: `${topProductsUnits[0].name} is your best-selling product.` });

    if (newCustomers > prevNewCustomers) insights.push({ type: 'good', title: 'CUSTOMERS', text: 'Your customer base is growing faster than last period.' });

    const outOfStockCount = await Product.countDocuments({ stock: 0 });
    if (outOfStockCount > 0) insights.push({ type: 'problem', title: 'STOCK', text: `${outOfStockCount} products are out of stock and need attention.` });

    const pendingOrders = await Order.countDocuments({ status: 'Placed' });
    if (pendingOrders > 0) insights.push({ type: 'attention', title: 'ORDERS', text: `${pendingOrders} new orders are waiting to be processed.` });

    res.json({
      overview: {
        sales: { current: cur.sales, previous: prev.sales },
        orders: { current: cur.orders, previous: prev.orders },
        productsSold: { current: cur.productsSold, previous: prev.productsSold },
        customers: { current: totalCustomers, new: newCustomers, prevNew: prevNewCustomers },
        returns: { current: returns, previous: prevReturns },
        aov: { current: cur.orders > 0 ? cur.sales / cur.orders : 0, previous: prev.orders > 0 ? prev.sales / prev.orders : 0 }
      },
      salesTrend,
      topProductsUnits,
      topProductsRevenue,
      categoryPerformance,
      orderStatuses,
      paymentMethods,
      attentionProducts,
      mostWishlisted,
      ratingData,
      locations,
      insights
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
