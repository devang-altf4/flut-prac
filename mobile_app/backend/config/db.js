const mongoose = require('mongoose');

const connectDB = async (attempt = 1) => {
  const maxAttempts = 5;
  const uri = process.env.MONGO_URI;

  if (!uri) {
    console.error('MONGO_URI is missing. Add it to backend/.env before starting the server.');
    process.exit(1);
  }

  try {
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 5000,
    });
    console.log(`MongoDB connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`MongoDB connection attempt ${attempt} failed: ${error.message}`);

    if (attempt < maxAttempts) {
      await new Promise(resolve => setTimeout(resolve, 2000));
      return connectDB(attempt + 1);
    }

    process.exit(1);
  }
};

module.exports = connectDB;
