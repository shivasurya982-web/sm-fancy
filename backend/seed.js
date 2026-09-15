const mongoose = require('mongoose');
const User = require('./models/User');
const Product = require('./models/Product');
const Order = require('./models/Order');
const Chat = require('./models/Chat');

const seedData = async () => {
  try {
    // 1. Seed Users
    const adminCount = await User.countDocuments({ role: 'admin' });
    let adminUser;
    if (adminCount === 0) {
      adminUser = new User({
        name: 'Store Owner',
        email: 'admin@fancyworld.com',
        password: 'admin',
        role: 'admin',
      });
      await adminUser.save();
      console.log('Seeded admin user: admin@fancyworld.com / admin');
    } else {
      adminUser = await User.findOne({ role: 'admin' });
    }

    const customerCount = await User.countDocuments({ role: 'user' });
    let customerUser;
    if (customerCount === 0) {
      customerUser = new User({
        name: 'John Doe',
        email: 'customer@fancyworld.com',
        phone: '+91 98765 43210',
        password: 'customer',
        role: 'user',
      });
      await customerUser.save();
      console.log('Seeded customer user: customer@fancyworld.com / customer');
    } else {
      customerUser = await User.findOne({ role: 'user' });
    }

    // 2. Seed Products
    const productCount = await Product.countDocuments();
    if (productCount === 0) {
      const defaultProducts = [
        {
          name: 'Aura Eau de Parfum',
          description: 'A luxurious and sensual fragrance featuring top notes of jasmine and saffron, heart notes of amberwood, and base notes of fir resin and cedar. A premium perfume that commands attention and leaves a lasting impression.',
          price: 18500,
          category: 'Perfumes',
          imageUrl: 'assets/images/products/aura_perfume.jpg',
          rating: 4.9,
          ratingsCount: 69,
        },
        {
          name: 'Night Sensation Gloss',
          description: 'High shine lip gloss infused with hydrating oils to give your lips a plump, luscious look with a subtle golden shimmer.',
          price: 1500,
          category: 'Cosmetics',
          imageUrl: 'assets/images/products/lip_gloss.jpg',
          rating: 4.7,
          ratingsCount: 120,
        },
        {
          name: 'Luxurious Diamond Necklace',
          description: 'An exquisite diamond necklace crafted in 18k white gold, featuring brilliant cut diamonds that capture light from every angle.',
          price: 75000,
          category: 'Jewelry',
          imageUrl: 'assets/images/products/necklace.jpg',
          rating: 4.8,
          ratingsCount: 42,
        },
        {
          name: 'Golden Bloom Earrings',
          description: 'Elegant dangle earrings featuring intricate peacock feather details in gold filigree, perfect for weddings and festive occasions.',
          price: 12500,
          category: 'Jewelry',
          imageUrl: 'assets/images/products/earrings.jpg',
          rating: 4.6,
          ratingsCount: 88,
        },
        {
          name: 'Silk Peony Scarf',
          description: '100% pure mulberry silk scarf featuring a hand-painted floral design. Soft, lightweight, and versatile.',
          price: 4500,
          category: 'Accessories',
          imageUrl: 'assets/images/products/silk_scarf.jpg',
          rating: 4.5,
          ratingsCount: 35,
        },
        {
          name: 'Ceramic Flower Vase',
          description: 'Handcrafted ceramic vase with a ribbed texture and minimalist aesthetic, designed to elevate any modern living space.',
          price: 3200,
          category: 'Home Decor',
          imageUrl: 'assets/images/products/vase.jpg',
          rating: 4.4,
          ratingsCount: 15,
        },
      ];

      await Product.insertMany(defaultProducts);
      console.log('Seeded 6 default products');
    }

    // 3. Seed Orders (if none exist) for Admin Dashboard simulation
    const orderCount = await Order.countDocuments();
    if (orderCount === 0 && customerUser) {
      const products = await Product.find();
      if (products.length >= 2) {
        // Order 1 (Delivered)
        const order1 = new Order({
          user: customerUser._id,
          items: [
            {
              product: products[0]._id,
              name: products[0].name,
              price: products[0].price,
              quantity: 1,
            },
            {
              product: products[1]._id,
              name: products[1].name,
              price: products[1].price,
              quantity: 2,
            },
          ],
          subtotal: products[0].price + (products[1].price * 2),
          shipping: 150,
          total: products[0].price + (products[1].price * 2) + 150,
          status: 'Delivered',
          shippingAddress: {
            name: 'John Doe',
            phone: '+91 98765 43210',
            street: '12, Murugan Temple St',
            city: 'Tiruchendur',
            state: 'Tamil Nadu',
            zipCode: '628215',
          },
          paymentMethod: 'UPI',
          createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
        });
        await order1.save();

        // Order 2 (Shipped)
        const order2 = new Order({
          user: customerUser._id,
          items: [
            {
              product: products[1]._id,
              name: products[1].name,
              price: products[1].price,
              quantity: 1,
            },
          ],
          subtotal: products[1].price,
          shipping: 0,
          total: products[1].price,
          status: 'Shipped',
          shippingAddress: {
            name: 'John Doe',
            phone: '+91 98765 43210',
            street: '12, Murugan Temple St',
            city: 'Tiruchendur',
            state: 'Tamil Nadu',
            zipCode: '628215',
          },
          paymentMethod: 'Cash on Delivery',
          createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
        });
        await order2.save();

        // Order 3 (Placed)
        const order3 = new Order({
          user: customerUser._id,
          items: [
            {
              product: products[0]._id,
              name: products[0].name,
              price: products[0].price,
              quantity: 1,
            },
          ],
          subtotal: products[0].price,
          shipping: 150,
          total: products[0].price + 150,
          status: 'Placed',
          shippingAddress: {
            name: 'John Doe',
            phone: '+91 98765 43210',
            street: '12, Murugan Temple St',
            city: 'Tiruchendur',
            state: 'Tamil Nadu',
            zipCode: '628215',
          },
          paymentMethod: 'Credit Card',
          createdAt: new Date(), // Today
        });
        await order3.save();

        console.log('Seeded sample orders for admin charts');
      }
    }

    // 4. Seed Chat Message
    // 4. Seed Chat Message
const chatCount = await Chat.countDocuments();

if (chatCount === 0 && customerUser && adminUser) {
  const roomId = [
    customerUser._id.toString(),
    adminUser._id.toString(),
  ].sort().join('_');

  const messages = [
    {
      senderId: customerUser._id,
      receiverId: adminUser._id,
      roomId,
      message: 'Hello, is the Aura perfume in stock?',
      image: '',
    },
    {
      senderId: adminUser._id,
      receiverId: customerUser._id,
      roomId,
      message: 'Yes, it is! We have limited quantities left.',
      image: '',
    },
    {
      senderId: customerUser._id,
      receiverId: adminUser._id,
      roomId,
      message: 'Great, thank you! I will place an order now.',
      image: '',
    },
  ];

  await Chat.insertMany(messages);

  console.log('Seeded sample chats');
   
    }
  // 4. Seed Chat Message
    // 4. Seed Chat Messages
 
  } catch (err) {
    console.error('Error seeding database:', err);
  }
  };

module.exports = seedData;