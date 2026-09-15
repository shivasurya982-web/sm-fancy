console.log('UPLOAD ROUTE LOADED');
const express = require('express');
const multer = require('multer');
const streamifier = require('streamifier');
const cloudinary = require('../config/cloudinary');
const { verifyToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

const storage = multer.memoryStorage();

const upload = multer({
  storage,
});

router.post(
  '/',
  verifyToken,
  upload.single('image'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          message: 'No image uploaded',
        });
      }

      const result = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          {
            folder: 'fancyworld/products',
          },
          (error, result) => {
            if (error) reject(error);
            else resolve(result);
          }
        );

        streamifier.createReadStream(req.file.buffer).pipe(stream);
      });

      res.json({
        imageUrl: result.secure_url,
      });
    }catch (err) {
  console.error("UPLOAD ERROR:");
  console.error(err);

  res.status(500).json({
    message: err.message,
    stack: err.stack,
  });
}
  }
);

module.exports = router;