const cloudinary = require('cloudinary').v2;
require('dotenv').config();

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

console.log(
  'Cloudinary Name:',
  process.env.CLOUDINARY_CLOUD_NAME
);

console.log(
  'Cloudinary Key:',
  process.env.CLOUDINARY_API_KEY
);

console.log(
  'Cloudinary Secret Exists:',
  !!process.env.CLOUDINARY_API_SECRET
);

module.exports = cloudinary;