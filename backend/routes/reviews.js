const express = require('express');
const router = express.Router();
const Review = require('../models/Review');
const Order = require('../models/Order');
const Product = require('../models/Product');
const { verifyToken, optionalAuth } = require('../middleware/auth');

// GET /api/reviews/check-eligible/:productId - Check if user has unreviewed delivered order for product
router.get('/check-eligible/:productId', verifyToken, async (req, res) => {
  try {
    const { productId } = req.params;

    // Find all delivered orders for this user containing this product
    const deliveredOrders = await Order.find({
      userId: req.userId,
      status: { $regex: /^delivered$/i },
      'items.product': productId,
    });

    if (deliveredOrders.length === 0) {
      return res.json({ canReview: false, hasReviewed: false, reason: 'No delivered purchase found for this product.' });
    }

    // Find all reviews submitted by this user for this product
    const userReviews = await Review.find({ userId: req.userId, productId });
    const reviewedOrderIds = userReviews.map(r => r.orderId?.toString()).filter(Boolean);

    // Find an unreviewed delivered order
    const unreviewedOrder = deliveredOrders.find(o => !reviewedOrderIds.includes(o._id.toString()));

    if (unreviewedOrder) {
      return res.json({ canReview: true, hasReviewed: false, orderId: unreviewedOrder._id });
    }

    // If no unreviewed order but orders exist and user has reviewed, allow updating or show reviewed status
    res.json({ canReview: false, hasReviewed: true, message: 'All delivered purchases for this item have been reviewed.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/reviews/:productId - Get reviews for a product
router.get('/:productId', optionalAuth, async (req, res) => {
  try {
    const { page = 1, limit = 10, sort = 'newest' } = req.query;
    const sortMap = {
      newest: { createdAt: -1 },
      oldest: { createdAt: 1 },
      highest: { rating: -1 },
      lowest: { rating: 1 },
    };

    const reviews = await Review.find({
      productId: req.params.productId,
      isApproved: true,
    })
      .populate('userId', 'name avatar')
      .sort(sortMap[sort] || { createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit));

    const total = await Review.countDocuments({
      productId: req.params.productId,
      isApproved: true,
    });

    const breakdown = await Review.aggregate([
      { $match: { productId: require('mongoose').Types.ObjectId.createFromHexString(req.params.productId), isApproved: true } },
      { $group: { _id: '$rating', count: { $sum: 1 } } },
    ]);

    res.json({ reviews, total, breakdown });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/reviews - Submit a review (must be logged in)
router.post('/', verifyToken, async (req, res) => {
  try {
    const { productId, rating, title, review, images } = req.body;
    let { orderId } = req.body;

    // Verify delivered order
    let isVerifiedPurchase = false;
    const deliveredOrders = await Order.find({
      userId: req.userId,
      status: { $regex: /^delivered$/i },
      'items.product': productId,
    });

    if (deliveredOrders.length > 0) {
      isVerifiedPurchase = true;
      if (!orderId) {
        // Pick an unreviewed orderId if available
        const userReviews = await Review.find({ userId: req.userId, productId });
        const reviewedOrderIds = userReviews.map(r => r.orderId?.toString()).filter(Boolean);
        const unreviewed = deliveredOrders.find(o => !reviewedOrderIds.includes(o._id.toString()));
        orderId = unreviewed ? unreviewed._id : deliveredOrders[0]._id;
      }
    }

    const newReview = new Review({
      userId: req.userId,
      productId,
      orderId,
      rating,
      title,
      review,
      images: images || [],
      isVerifiedPurchase,
    });

    await newReview.save();

    // Recalculate average rating for product
    const allReviews = await Review.find({ productId, isApproved: true });
    if (allReviews.length > 0) {
      const avg = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;
      await Product.findByIdAndUpdate(productId, { averageRating: avg, numReviews: allReviews.length });
    }

    const populated = await newReview.populate('userId', 'name avatar');
    res.status(201).json(populated);
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ message: 'You have already reviewed this purchase.' });
    }
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/reviews/:id - Update own review
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const review = await Review.findOne({ _id: req.params.id, userId: req.userId });
    if (!review) return res.status(404).json({ message: 'Review not found' });
    Object.assign(review, req.body);
    await review.save();
    res.json(review);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/reviews/:id - Delete own review
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const review = await Review.findOneAndDelete({ _id: req.params.id, userId: req.userId });
    if (!review) return res.status(404).json({ message: 'Review not found or not yours' });
    res.json({ message: 'Review deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
