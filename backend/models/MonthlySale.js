const mongoose = require('mongoose');

const monthlySaleSchema = new mongoose.Schema({
  year: { type: Number, required: true },
  month: { type: Number, required: true }, // 1-12
  totalSales: { type: Number, default: 0 },
  orderCount: { type: Number, default: 0 },
  categorySales: [{
    category: String,
    sales: { type: Number, default: 0 }
  }]
}, { timestamps: true });

// Unique index to prevent duplicate records for the same month/year
monthlySaleSchema.index({ year: 1, month: 1 }, { unique: true });

module.exports = mongoose.model('MonthlySale', monthlySaleSchema);
