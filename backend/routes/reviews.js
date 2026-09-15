const express = require('express');
const router = express.Router();
const Review = require('../models/Review');
const Order = require('../models/Order');
const { verifyToken, optionalAuth } = require('../middleware/auth');

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

    // Rating breakdown
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
    const { productId, orderId, rating, title, review, images } = req.body;

    // Check verified purchase if orderId given
    let isVerifiedPurchase = false;
    if (orderId) {
      const order = await Order.findOne({
        _id: orderId,
        userId: req.userId,
        status: 'Delivered',
        'items.product': productId,
      });
      if (order) isVerifiedPurchase = true;
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
    const populated = await newReview.populate('userId', 'name avatar');
    res.status(201).json(populated);
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ message: 'You have already reviewed this product' });
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
