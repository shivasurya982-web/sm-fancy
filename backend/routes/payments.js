const express = require('express');
const router = express.Router();
const Razorpay = require('razorpay');
const crypto = require('crypto');
const Order = require('../models/Order');
const Coupon = require('../models/Coupon');
const { verifyToken } = require('../middleware/auth');
const { createNotification } = require('./notifications');

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'placeholder_secret',
});

// GET /api/payments/key - Get Razorpay Public Key
router.get('/key', verifyToken, (req, res) => {
  res.json({ key: process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder' });
});

// POST /api/payments/create-order - Create Razorpay order
router.post('/create-order', verifyToken, async (req, res) => {
  try {
    const { amount, currency = 'INR', receipt } = req.body;

    if (
      !process.env.RAZORPAY_KEY_ID ||
      process.env.RAZORPAY_KEY_ID.includes('xxxx') ||
      !process.env.RAZORPAY_KEY_SECRET ||
      process.env.RAZORPAY_KEY_SECRET === 'your_razorpay_secret'
    ) {
      return res.status(400).json({
        message: 'Razorpay is not configured on the server. Please add your API keys to the .env file.'
      });
    }

    const options = {
      amount: Math.round(amount * 100), // paise
      currency,
      receipt: receipt || `fw_${Date.now()}`,
    };

    const razorpayOrder = await razorpay.orders.create(options);
    res.json({ orderId: razorpayOrder.id, amount: razorpayOrder.amount, currency: razorpayOrder.currency });
  } catch (err) {
    console.error('Razorpay order creation failed:', err);
    res.status(500).json({
      message: 'Failed to initialize payment gateway',
      error: err.message
    });
  }
});

// POST /api/payments/verify - Verify Razorpay payment signature
router.post('/verify', verifyToken, async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, orderId } = req.body;

    const body = razorpay_order_id + '|' + razorpay_payment_id;
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || 'placeholder_secret')
      .update(body)
      .digest('hex');

    if (expectedSignature !== razorpay_signature) {
      return res.status(400).json({ message: 'Payment verification failed' });
    }

    // Update order
    if (orderId) {
      const order = await Order.findByIdAndUpdate(orderId, {
        paymentStatus: 'Paid',
        razorpayOrderId: razorpay_order_id,
        razorpayPaymentId: razorpay_payment_id,
        status: 'Confirmed',
        $push: {
          timeline: {
            status: 'Confirmed',
            message: 'Payment received and order confirmed',
            isCompleted: true,
          },
        },
      }, { new: true });

      // Notify User
      await createNotification(req.app, {
        userId: req.userId,
        title: 'Payment Secured',
        body: `Payment for order #${order.orderNumber} has been verified. Status: confirmed.`,
        type: 'order',
        data: { orderId: order._id }
      });
    }

    res.json({ verified: true, paymentId: razorpay_payment_id });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/payments/webhook - Razorpay webhook handler
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  try {
    const signature = req.headers['x-razorpay-signature'];
    const body = JSON.stringify(req.body);
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET || '')
      .update(body)
      .digest('hex');

    if (signature !== expectedSignature) {
      return res.status(400).json({ message: 'Invalid webhook signature' });
    }

    const event = req.body.event;
    if (event === 'payment.captured') {
      const paymentId = req.body.payload.payment.entity.id;
      const orderId = req.body.payload.payment.entity.notes?.orderId;
      if (orderId) {
        await Order.findByIdAndUpdate(orderId, {
          paymentStatus: 'Paid',
          razorpayPaymentId: paymentId,
        });
      }
    }

    res.json({ received: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
