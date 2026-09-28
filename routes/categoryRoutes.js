const express = require('express');
const router = express.Router();
const Category = require('../models/Category');
const { verifyToken, requireAdmin } = require('../middleware/auth');

router.get('/', async (req, res) => {
  try {
    const categories = await Category.find().sort({ name: 1 });
    res.json(categories);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/', verifyToken, requireAdmin, async (req, res) => {
  try {
    const category = await Category.create({
      name: req.body.name,
      image: req.body.image || '',
    });
    res.status(201).json(category);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

router.put('/:id', verifyToken, requireAdmin, async (req, res) => {
    try {
        const category = await Category.findByIdAndUpdate(req.params.id, {
            name: req.body.name,
            image: req.body.image
        }, { new: true });
        if (!category) return res.status(404).json({ message: 'Category not found' });
        res.json(category);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

router.delete('/:id', verifyToken, requireAdmin, async (req, res) => {
  try {
    const category = await Category.findByIdAndDelete(req.params.id);
    if (!category) return res.status(404).json({ message: 'Category not found' });
    res.json({ message: 'Category deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
