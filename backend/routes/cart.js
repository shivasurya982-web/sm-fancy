const express = require('express');
const router = express.Router();
const Cart = require('../models/Cart');
const Product = require('../models/Product');
const { verifyToken } = require('./auth');

// Get cart for logged in user
router.get('/', verifyToken, async (req, res) => {
  try {
    let cart = await Cart.findOne({ user: req.userId }).populate('items.product');
    if (!cart) {
      cart = new Cart({ user: req.userId, items: [] });
      await cart.save();
    }
    res.json(cart);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Add item to cart
router.post('/', verifyToken, async (req, res) => {
  const { productId, quantity } = req.body;
  const qty = parseInt(quantity) || 1;

  try {
    const product = await Product.findById(productId);
    if (!product) return res.status(404).json({ message: 'Product not found' });

    if (product.stock < qty) {
      return res.status(400).json({ message: `Only ${product.stock} items available in stock` });
    }

    let cart = await Cart.findOne({ user: req.userId });
    if (!cart) {
      cart = new Cart({ user: req.userId, items: [] });
    }

    const itemIndex = cart.items.findIndex(
      (item) => item.product.toString() === productId
    );

    if (itemIndex > -1) {
      // product exists in the cart, check total quantity against stock
      const newQty = cart.items[itemIndex].quantity + qty;
      if (product.stock < newQty) {
          return res.status(400).json({ message: `Cannot add more. Only ${product.stock} items available in total.` });
      }
      cart.items[itemIndex].quantity = newQty;
    } else {
      // product does not exist in the cart, add new item
      cart.items.push({ product: productId, quantity: qty });
    }

    cart.updatedAt = new Date();
    await cart.save();

    const populatedCart = await Cart.findOne({ user: req.userId }).populate('items.product');
    res.json(populatedCart);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Update item quantity in cart
router.put('/:productId', verifyToken, async (req, res) => {
  const { quantity } = req.body;
  const qty = parseInt(quantity);

  if (isNaN(qty) || qty < 1) {
    return res.status(400).json({ message: 'Invalid quantity' });
  }

  try {
    const product = await Product.findById(req.params.productId);
    if (!product) return res.status(404).json({ message: 'Product not found' });

    if (product.stock < qty) {
        return res.status(400).json({ message: `Insufficient stock. Only ${product.stock} items available.` });
    }

    const cart = await Cart.findOne({ user: req.userId });
    if (!cart) return res.status(404).json({ message: 'Cart not found' });

    const itemIndex = cart.items.findIndex(
      (item) => item.product.toString() === req.params.productId
    );

    if (itemIndex > -1) {
      cart.items[itemIndex].quantity = qty;
      cart.updatedAt = new Date();
      await cart.save();

      const populatedCart = await Cart.findOne({ user: req.userId }).populate('items.product');
      return res.json(populatedCart);
    } else {
      return res.status(404).json({ message: 'Product not in cart' });
    }
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Remove item from cart
router.delete('/:productId', verifyToken, async (req, res) => {
  try {
    const cart = await Cart.findOne({ user: req.userId });
    if (!cart) return res.status(404).json({ message: 'Cart not found' });

    cart.items = cart.items.filter(
      (item) => item.product.toString() !== req.params.productId
    );

    cart.updatedAt = new Date();
    await cart.save();

    const populatedCart = await Cart.findOne({ user: req.userId }).populate('items.product');
    res.json(populatedCart);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Clear cart
router.delete('/', verifyToken, async (req, res) => {
  try {
    const cart = await Cart.findOne({ user: req.userId });
    if (cart) {
      cart.items = [];
      cart.updatedAt = new Date();
      await cart.save();
    }
    res.json({ message: 'Cart cleared successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
