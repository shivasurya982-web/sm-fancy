require('dotenv').config();
const mongoose = require('mongoose');
const Order = require('../models/Order');
const MonthlySale = require('../models/MonthlySale');
const Product = require('../models/Product');

const backfill = async () => {
  try {
    const MONGODB_URI = process.env.MONGODB_URI;
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to DB...');

    // Clear existing snapshots to avoid duplication during backfill
    await MonthlySale.deleteMany({});
    console.log('Cleared existing snapshots.');

    const orders = await Order.find({});
    console.log(`Found ${orders.length} orders to process.`);

    for (const order of orders) {
      const date = new Date(order.createdAt);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;

      let record = await MonthlySale.findOne({ year, month });
      if (!record) {
        record = new MonthlySale({ year, month, totalSales: 0, orderCount: 0, categorySales: [] });
      }

      record.totalSales += order.total;
      record.orderCount += 1;

      for (const item of order.items) {
          const product = await Product.findById(item.product);
          if (product) {
              const catIdx = record.categorySales.findIndex(c => c.category === product.category);
              if (catIdx !== -1) {
                  record.categorySales[catIdx].sales += (item.price * item.quantity);
              } else {
                  record.categorySales.push({ category: product.category, sales: (item.price * item.quantity) });
              }
          }
      }
      await record.save();
    }

    console.log('Backfill complete!');
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

backfill();
