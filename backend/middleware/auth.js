const jwt = require('jsonwebtoken');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'fancyworld_secret';
console.log('MIDDLEWARE SECRET:', JWT_SECRET);
const verifyToken = async (req, res, next) => {
  const header = req.headers['authorization'];
  if (!header) return res.status(401).json({ message: 'No token provided' });

  const token = header.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Malformed token' });

  try {
    const decoded = jwt.verify(token, JWT_SECRET);

    req.userId = decoded.id;
    req.userRole = decoded.role;

    // Check if user is suspended
    const user = await User.findById(req.userId);
    if (user && user.isSuspended) {
        return res.status(403).json({ message: 'ACCOUNT SUSPENDED. Please contact admin.' });
    }

    next();
  } catch (err) {
    return res.status(401).json({
      message: "Invalid or expired token",
    });
  }
};

const requireAdmin = (req, res, next) => {
  if (req.userRole !== 'admin') {
    return res.status(403).json({ message: 'Access denied. Admins only.' });
  }
  next();
};

const optionalAuth = async (req, res, next) => {
  const header = req.headers['authorization'];
  if (!header) return next();
  const token = header.split(' ')[1];
  if (!token) return next();
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.userId = decoded.id;
    req.userRole = decoded.role;
  } catch (_) {}
  next();
};

module.exports = { verifyToken, requireAdmin, optionalAuth };
