import mongoose from "mongoose";
import dotenv from "dotenv";


dotenv.config();

const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI;

    if (!mongoUri) {
      throw new Error("MongoDB URI is not defined in environment variables");
    }

    console.log("Attempting to connect to MongoDB...");
    console.log("Connection URI:", mongoUri.replace(/:[^:]*@/, ":****@")); 

    const conn = await mongoose.connect(mongoUri);

    console.log("=================================");
    console.log(`MongoDB Connected: ${conn.connection.host}`);
    console.log(`Database Name: ${conn.connection.name}`);
    console.log("=================================");

    // Setup connection error handlers
    mongoose.connection.on("error", (err) => {
      console.error("MongoDB connection error:", err);
    });

    mongoose.connection.on("disconnected", () => {
      console.log("MongoDB disconnected");
    });

    return conn;
  } catch (err) {
    console.error("=================================");
    console.error("MongoDB connection error:");
    console.error(`Error message: ${err.message}`);
    console.error("Error details:", err);
    console.error("Environment variables set:", {
      MONGO_URI: process.env.MONGO_URI ? "Set" : "Not set",
      MONGODB_URI: process.env.MONGODB_URI ? "Set" : "Not set",
    });
    console.error("=================================");
    process.exit(1);
  }
};

export default connectDB;
