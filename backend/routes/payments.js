const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const Order = require('../models/Order');
const Product = require('../models/Product');
const Coupon = require('../models/Coupon');
const AppSettings = require('../models/AppSettings');
const User = require('../models/User');
const { verifyToken } = require('../middleware/auth');
const { createNotification } = require('./notifications');
const { recordOrderSale } = require('../services/analyticsService');

// POST /api/payments/create-order - Prepare order for Dynamic UPI QR
router.post('/create-order', verifyToken, async (req, res) => {
  try {
    const {
        items,
        address,
        couponCode,
        shipping = 0,
        tax = 0
    } = req.body;

    if (!items || items.length === 0) {
        return res.status(400).json({ message: 'No items in cart' });
    }

    // 1. Calculate and Validate Amount on Backend
    let calculatedSubtotal = 0;
    for (const item of items) {
        const product = await Product.findById(item.product);
        if (!product) return res.status(404).json({ message: `Product ${item.name} not found` });
        if (product.stock < item.quantity) return res.status(400).json({ message: `Insufficient stock for ${product.name}` });
        calculatedSubtotal += product.price * item.quantity;
    }

    let couponDiscount = 0;
    if (couponCode) {
        const coupon = await Coupon.findOne({ code: couponCode.toUpperCase(), isActive: true });
        if (coupon) {
            couponDiscount = (coupon.discountType === 'percentage')
                ? Math.min(Math.round((calculatedSubtotal * coupon.discountValue) / 100), coupon.maxDiscountAmount || calculatedSubtotal)
                : coupon.discountValue;
        }
    }

    const totalAmount = calculatedSubtotal + shipping + tax - couponDiscount;
    if (totalAmount <= 0) return res.status(400).json({ message: 'Invalid total amount' });

    // 2. Create Order in DB with status PAYMENT_PENDING
    const upiRef = `FW${Date.now()}${Math.floor(Math.random() * 1000)}`;
    const orderNumber = await Order.generateUniqueOrderNumber();

    const order = new Order({
        userId: req.userId,
        orderNumber,
        items,
        address,
        paymentMethod: 'UPI',
        paymentStatus: 'Pending',
        subtotal: calculatedSubtotal,
        shipping,
        tax,
        couponCode,
        couponDiscount,
        total: totalAmount,
        status: 'Placed',
        upiReferenceNo: upiRef,
        timeline: [
            { status: 'Placed', message: 'Order initiated via Dynamic UPI QR', isCompleted: true },
            { status: 'Pending Verification', message: 'Waiting for banking confirmation...', isCompleted: false }
        ],
    });

    try {
      await order.save();
    } catch (saveErr) {
      if (saveErr.code === 11000) {
        order.orderNumber = `FW${Date.now()}`;
        await order.save();
      } else {
        throw saveErr;
      }
    }

    // 3. Fetch Merchant VPA from Settings
    const settings = await AppSettings.findOne();
    const vpa = settings?.upiId || 'shivasurya982-1@oksbi';

    // 4. Construct Dynamic UPI Intent URL
    const upiPayload = `upi://pay?pa=${vpa}&pn=${encodeURIComponent('FANCY WORLD')}&tr=${upiRef}&am=${totalAmount.toFixed(2)}&cu=INR&tn=${encodeURIComponent('Order ' + order.orderNumber)}`;

    res.json({
        success: true,
        fancyWorldOrderId: order._id,
        orderNumber: order.orderNumber,
        amount: totalAmount,
        upiPayload: upiPayload,
        upiReferenceNo: upiRef
    });

  } catch (err) {
    console.error('[PAYMENT ERROR]', err);
    res.status(500).json({ message: 'Failed to initiate payment', error: err.message });
  }
});

// POST /api/payments/webhook
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  try {
    const signature = req.headers['x-provider-signature'];
    if (!signature) return res.status(401).send('Missing signature');

    const payload = JSON.parse(req.body.toString());
    const { transactionId, merchantReference, amount, status, utr } = payload;

    const order = await Order.findOne({ upiReferenceNo: merchantReference });
    if (!order) return res.status(404).send('Order not found');

    if (order.paymentStatus === 'Paid') return res.json({ success: true, message: 'Already processed' });

    if (status === 'SUCCESS' && parseFloat(amount) === order.total) {
        order.paymentStatus = 'Paid';
        order.upiTransactionId = utr || transactionId;
        order.status = 'Confirmed';
        order.paymentDetails = payload;
        order.timeline.push({ status: 'Confirmed', message: 'Payment verified via automated gateway', isCompleted: true });

        await order.save();
        await handlePostPayment(req.app, order);

        return res.json({ success: true });
    } else {
        order.paymentStatus = 'Failed';
        order.paymentDetails = payload;
        await order.save();
        return res.status(400).send('Payment failed or amount mismatch');
    }

  } catch (err) {
    console.error('[WEBHOOK ERROR]', err);
    res.status(500).send('Internal Server Error');
  }
});

// GET /api/payments/status/:orderId
router.get('/status/:orderId', verifyToken, async (req, res) => {
    try {
        const order = await Order.findById(req.params.orderId);
        if (!order) return res.status(404).json({ message: 'Order not found' });

        res.json({
            paymentStatus: order.paymentStatus,
            orderStatus: order.status
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

async function handlePostPayment(app, order) {
    for (const item of order.items) {
        if (item.product) {
            await Product.findByIdAndUpdate(item.product, { $inc: { stock: -item.quantity } });
        }
    }

    await recordOrderSale(order);

    const points = Math.floor(order.total / 100);
    await User.findByIdAndUpdate(order.userId, { $inc: { loyaltyPoints: points } });

    const productNames = order.items.map(i => i.name).join(', ');
    await createNotification(app, {
        userId: order.userId,
        title: 'Payment Confirmed!',
        body: `Your payment for ${productNames} has been verified and your order is confirmed.`,
        type: 'order',
        data: { orderId: order._id }
    });
}

module.exports = router;
