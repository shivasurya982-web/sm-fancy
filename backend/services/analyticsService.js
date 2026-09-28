const MonthlySale = require('../models/MonthlySale');
const Product = require('../models/Product');

const recordOrderSale = async (order) => {
  try {
    if (order.status === 'Cancelled') return; // Don't record cancelled orders initially

    const date = new Date(order.createdAt || Date.now());
    const year = date.getFullYear();
    const month = date.getMonth() + 1; // getMonth is 0-indexed

    // Find or Create monthly record
    let monthlyRecord = await MonthlySale.findOne({ year, month });
    if (!monthlyRecord) {
      monthlyRecord = new MonthlySale({ year, month, totalSales: 0, orderCount: 0, categorySales: [] });
    }

    monthlyRecord.totalSales += order.total;
    monthlyRecord.orderCount += 1;

    // Track category sales
    for (const item of order.items) {
      // We might need to fetch the product to get the category if it's not in order items
      // (The order model stores name, price, qty, but might not store category directly in orderItemSchema)
      // Let's check Product model
      const product = await Product.findById(item.product);
      if (product) {
        const category = product.category;
        const catIdx = monthlyRecord.categorySales.findIndex(c => c.category === category);
        const lineTotal = item.price * item.quantity;

        if (catIdx !== -1) {
          monthlyRecord.categorySales[catIdx].sales += lineTotal;
        } else {
          monthlyRecord.categorySales.push({ category, sales: lineTotal });
        }
      }
    }

    await monthlyRecord.save();
    console.log(`Analytics updated for ${month}/${year}`);
  } catch (err) {
    console.error('Error recording analytics snapshot:', err);
  }
};

module.exports = { recordOrderSale };
