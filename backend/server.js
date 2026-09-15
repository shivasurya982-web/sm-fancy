require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const dns = require('dns');
const cors = require('cors');
const helmet = require('helmet');

// ─── DNS FIX FOR MONGODB ATLAS ──────────────────────────────────────────────
try {
  dns.setServers(['8.8.8.8', '8.8.4.4']);
  console.log('DNS: Using Google resolvers for stability.');
} catch (e) {}

console.log('ENV FILE LOADED');

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
});

const PORT = 5050;
const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.error('CRITICAL: MONGODB_URI is missing!');
  process.exit(1);
}

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

app.use((req, res, next) => {
  console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.originalUrl}`);
  next();
});

// ─── Route Imports ──────────────────────────────────────────────────────────
const { router: authRouter } = require('./routes/auth');
const productsRouter = require('./routes/products');
const cartRouter = require('./routes/cart');
const ordersRouter = require('./routes/orders');
const chatRouter = require('./routes/chat');
const analyticsRouter = require('./routes/analytics');
const usersRouter = require('./routes/users');
const couponsRouter = require('./routes/coupons');
const reviewsRouter = require('./routes/reviews');
const { router: notificationsRouter } = require('./routes/notifications');
const paymentsRouter = require('./routes/payments');
const dashboardRoutes = require('./routes/dashboard');
const uploadRoutes = require('./routes/upload');
const appSettingsRouter = require('./routes/appSettings');
const complaintsRouter = require('./routes/complaints');
const categoryRoutes = require('./routes/categoryRoutes');
const returnsRouter = require('./routes/returns');

// ─── API Registration ───────────────────────────────────────────────────────
app.use('/api/auth', authRouter);
app.use('/api/products', productsRouter);
app.use('/api/cart', cartRouter);
app.use('/api/orders', ordersRouter);
app.use('/api/chat', chatRouter);
app.use('/api/analytics', analyticsRouter);
app.use('/api/users', usersRouter);
app.use('/api/coupons', couponsRouter);
app.use('/api/reviews', reviewsRouter);
app.use('/api/notifications', notificationsRouter);
app.use('/api/payments', paymentsRouter);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/settings', appSettingsRouter);
app.use('/api/complaints', complaintsRouter);
app.use('/api/categories', categoryRoutes);
app.use('/api/returns', returnsRouter);

app.get('/health', (req, res) => res.json({ status: 'OK' }));

// ─── Database & Server Start ────────────────────────────────────────────────
const seedData = require('./seed');

const connectDB = async (retryCount = 0) => {
  try {
    await mongoose.connect(MONGODB_URI, {
      family: 4,
      serverSelectionTimeoutMS: 15000,
    });
    console.log('✅ Connected to MongoDB Atlas');
    await seedData();
  } catch (err) {
    console.error(`❌ DB Connection Error (Attempt ${retryCount + 1}):`, err.message);
    if (retryCount < 2) {
      console.log('Retrying in 5 seconds...');
      setTimeout(() => connectDB(retryCount + 1), 5000);
    } else {
      console.log('Starting in OFFLINE MODE. Admin features will return 500 until DB is whitelisted.');
    }
  }
};

connectDB();

server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 FancyWorld API running on http://127.0.0.1:${PORT}`);
});

app.set('io', io);
