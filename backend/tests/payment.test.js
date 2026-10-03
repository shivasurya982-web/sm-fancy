const { test, describe, before, after } = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const mongoose = require('mongoose');

process.env.APP_KEY = 'test_secret_app_key_999';
process.env.PAYMENT_SERVER_URL = 'http://localhost:9999';

const Order = require('../models/Order');
const Product = require('../models/Product');
const { verifyHMACSignature, processPaymentUpdate } = require('../routes/payments');

describe('Payment Integration Tests', () => {
  before(async () => {
    if (mongoose.connection.readyState === 0) {
      const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/fancyworld_test';
      await mongoose.connect(uri, { family: 4 });
    }
  });

  after(async () => {
    try {
      await Order.deleteMany({ orderNumber: /^TEST_FW_/ });
      await Product.deleteMany({ name: /^TEST_PROD_/ });
      await mongoose.connection.close();
    } catch (_) {}
  });

  test('1. Callback with valid signature and SUCCESS marks order paid exactly once, even if sent twice', async () => {
    const dummyProduct = await Product.create({
      name: `TEST_PROD_1_${Date.now()}`,
      description: 'Test product description',
      price: 500,
      stock: 10,
      category: 'Test',
      images: ['test.jpg']
    });

    const order = await Order.create({
      userId: new mongoose.Types.ObjectId(),
      orderNumber: `TEST_FW_${Date.now()}_1`,
      items: [{ product: dummyProduct._id, name: dummyProduct.name, price: 500, quantity: 2 }],
      subtotal: 1000,
      shipping: 0,
      tax: 0,
      total: 1000,
      amountToPay: 1000.50,
      paymentMethod: 'UPI',
      paymentStatus: 'Pending',
      status: 'Placed',
      paymentServerOrderId: 'PS_ORDER_001'
    });

    const payload = {
      ref: order._id.toString(),
      orderId: 'PS_ORDER_001',
      status: 'SUCCESS',
      amount: 1000.50,
      paid: 1000.50,
      utr: 'UTR123456789'
    };

    // First processing
    const res1 = await processPaymentUpdate(order, payload, null);
    assert.equal(res1.success, true);
    assert.equal(res1.paymentStatus, 'Paid');

    // Reload order from DB
    const updatedOrder = await Order.findById(order._id);
    assert.equal(updatedOrder.paymentStatus, 'Paid');
    assert.equal(updatedOrder.status, 'Confirmed');

    // Verify stock was reduced
    const updatedProduct = await Product.findById(dummyProduct._id);
    assert.equal(updatedProduct.stock, 8);

    // Second processing (Idempotency check)
    const res2 = await processPaymentUpdate(updatedOrder, payload, null);
    assert.equal(res2.success, true);
    assert.equal(res2.message, 'Already processed');

    // Verify stock was NOT reduced a second time
    const updatedProduct2 = await Product.findById(dummyProduct._id);
    assert.equal(updatedProduct2.stock, 8);
  });

  test('2. Callback with wrong signature is rejected and changes nothing', async () => {
    const rawBody = Buffer.from(JSON.stringify({ ref: 'dummy_ref', status: 'SUCCESS' }));

    // Correct HMAC signature
    const hmac = crypto.createHmac('sha256', process.env.APP_KEY);
    hmac.update(rawBody);
    const validSignature = hmac.digest('hex');

    const validReq = {
      headers: { 'x-signature': validSignature },
      rawBody: rawBody,
      body: JSON.parse(rawBody.toString())
    };

    const invalidReq = {
      headers: { 'x-signature': 'invalid_signature_hex_12345' },
      rawBody: rawBody,
      body: JSON.parse(rawBody.toString())
    };

    assert.equal(verifyHMACSignature(validReq), true);
    assert.equal(verifyHMACSignature(invalidReq), false);
  });

  test('3. Callback with wrong amount or WRONG status never delivers the product', async () => {
    const dummyProduct = await Product.create({
      name: `TEST_PROD_2_${Date.now()}`,
      description: 'Test product description',
      price: 200,
      stock: 5,
      category: 'Test',
      images: ['test.jpg']
    });

    const order = await Order.create({
      userId: new mongoose.Types.ObjectId(),
      orderNumber: `TEST_FW_${Date.now()}_2`,
      items: [{ product: dummyProduct._id, name: dummyProduct.name, price: 200, quantity: 1 }],
      subtotal: 200,
      shipping: 0,
      tax: 0,
      total: 200,
      amountToPay: 200.25,
      paymentMethod: 'UPI',
      paymentStatus: 'Pending',
      status: 'Placed',
      paymentServerOrderId: 'PS_ORDER_002'
    });

    const wrongAmountPayload = {
      ref: order._id.toString(),
      orderId: 'PS_ORDER_002',
      status: 'SUCCESS',
      amount: 200.25,
      paid: 100.00,
      utr: 'UTR_WRONG_001'
    };

    const res = await processPaymentUpdate(order, wrongAmountPayload, null);
    assert.equal(res.success, false);
    assert.equal(res.paymentStatus, 'WRONG');

    const updatedOrder = await Order.findById(order._id);
    assert.equal(updatedOrder.paymentStatus, 'WRONG');
    assert.notEqual(updatedOrder.status, 'Confirmed');

    const productReload = await Product.findById(dummyProduct._id);
    assert.equal(productReload.stock, 5);
  });

  test('4. Missed callback is recovered by status check', async () => {
    const dummyProduct = await Product.create({
      name: `TEST_PROD_3_${Date.now()}`,
      description: 'Test product description',
      price: 300,
      stock: 10,
      category: 'Test',
      images: ['test.jpg']
    });

    const order = await Order.create({
      userId: new mongoose.Types.ObjectId(),
      orderNumber: `TEST_FW_${Date.now()}_3`,
      items: [{ product: dummyProduct._id, name: dummyProduct.name, price: 300, quantity: 1 }],
      subtotal: 300,
      shipping: 0,
      tax: 0,
      total: 300,
      amountToPay: 300.75,
      paymentMethod: 'UPI',
      paymentStatus: 'Pending',
      status: 'Placed',
      paymentServerOrderId: 'PS_ORDER_003'
    });

    const s2sResponse = {
      status: 'SUCCESS',
      ref: order._id.toString(),
      amount: 300.75,
      paid: 300.75,
      utr: 'UTR_MISSED_001'
    };

    const res = await processPaymentUpdate(order, s2sResponse, null);
    assert.equal(res.success, true);
    assert.equal(res.paymentStatus, 'Paid');

    const updatedOrder = await Order.findById(order._id);
    assert.equal(updatedOrder.paymentStatus, 'Paid');
    assert.equal(updatedOrder.status, 'Confirmed');
  });

  test('5. CANCELLED order can be retried with a new order', async () => {
    const order1 = await Order.create({
      userId: new mongoose.Types.ObjectId(),
      orderNumber: `TEST_FW_${Date.now()}_4`,
      items: [],
      subtotal: 100,
      total: 100,
      amountToPay: 100.10,
      paymentMethod: 'UPI',
      paymentStatus: 'Pending',
      status: 'Placed',
      paymentServerOrderId: 'PS_ORDER_004'
    });

    const cancelPayload = {
      ref: order1._id.toString(),
      orderId: 'PS_ORDER_004',
      status: 'CANCELLED',
      amount: 100.10,
      paid: 0
    };

    const res = await processPaymentUpdate(order1, cancelPayload, null);
    assert.equal(res.paymentStatus, 'Cancelled');

    const cancelledOrder = await Order.findById(order1._id);
    assert.equal(cancelledOrder.paymentStatus, 'Cancelled');
    assert.equal(cancelledOrder.status, 'Cancelled');

    const order2 = await Order.create({
      userId: order1.userId,
      orderNumber: `TEST_FW_${Date.now()}_5`,
      items: [],
      subtotal: 100,
      total: 100,
      amountToPay: 100.12,
      paymentMethod: 'UPI',
      paymentStatus: 'Pending',
      status: 'Placed',
      paymentServerOrderId: 'PS_ORDER_005'
    });

    assert.notEqual(order1._id.toString(), order2._id.toString());
    assert.equal(order2.paymentStatus, 'Pending');
  });
});
