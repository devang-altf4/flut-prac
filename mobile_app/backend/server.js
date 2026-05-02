const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const User = require('./models/User');

// Load env variables
dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/employee', require('./routes/employee'));

// Health check
app.get('/', (req, res) => {
  res.json({ message: 'Dayaar CRM API is running' });
});

// Seed admin user on startup
const seedAdmin = async () => {
  try {
    const adminExists = await User.findOne({ username: 'salman29' });
    if (!adminExists) {
      await User.create({
        username: 'Salman29',
        password: '123456789',
        name: 'Salman (Admin)',
        role: 'admin',
      });
      console.log('Admin user seeded: Salman29');
    } else {
      console.log('Admin user already exists');
    }
  } catch (error) {
    console.error('Admin seed error:', error);
  }
};

// Start server
const PORT = process.env.PORT || 5000;
const startServer = async () => {
  await connectDB();
  await seedAdmin();
  app.listen(PORT, () => {
    console.log(`Dayaar CRM server running on port ${PORT}`);
  });
};

if (require.main === module) {
  startServer();
}

module.exports = { app, startServer, seedAdmin };
