import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import connectDB from "./lib/db.js";
import moviesRoutes from "./routes/movie.route.js";
import authRoutes from "./routes/auth.route.js";
import userRoutes from "./routes/user.route.js";
import genreRoutes from "./routes/genre.route.js";
import passport from "./config/passport-setup.js";
import mongoose from "mongoose";

// Load environment variables first
dotenv.config();

// Validate required environment variables
const requiredEnvVars = [
  "MONGO_URI",
  "JWT_SECRET",
  "GOOGLE_CLIENT_ID",
  "GOOGLE_CLIENT_SECRET",
];

const missingEnvVars = requiredEnvVars.filter((envVar) => !process.env[envVar]);
if (missingEnvVars.length > 0) {
  console.error(
    "Missing required environment variables:",
    missingEnvVars.join(", ")
  );
  console.error("Current environment variables:", {
    PORT: process.env.PORT || "(using default)",
    MONGO_URI: process.env.MONGO_URI ? "(set)" : "(not set)",
    JWT_SECRET: process.env.JWT_SECRET ? "(set)" : "(not set)",
    GOOGLE_CLIENT_ID: process.env.GOOGLE_CLIENT_ID ? "(set)" : "(not set)",
    GOOGLE_CLIENT_SECRET: process.env.GOOGLE_CLIENT_SECRET
      ? "(set)"
      : "(not set)",
  });
  process.exit(1);
}

const app = express();
const PORT = process.env.PORT || 4002;

// CORS configuration
app.use(
  cors({
    origin: process.env.FRONTEND_URL || "http://localhost:49925",
    credentials: true,
  })
);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(passport.initialize());

// Basic health check route
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    timestamp: new Date().toISOString(),
    mongodb:
      mongoose.connection.readyState === 1 ? "connected" : "disconnected",
  });
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/movies", moviesRoutes);
app.use("/api/users", userRoutes);
app.use("/api/genres", genreRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error("Error occurred:", err);
  res.status(500).json({
    success: false,
    message: "Internal Server Error",
    error: process.env.NODE_ENV === "development" ? err.message : undefined,
  });
});

// Start server
const startServer = async () => {
  try {
    console.log("Starting server...");
    console.log("Connecting to MongoDB...");

    await connectDB();

    app.listen(PORT, "0.0.0.0", () => {
      console.log("=================================");
      console.log(`Server Running on Port: ${PORT}`);
      console.log(
        `Frontend URL: ${process.env.FRONTEND_URL || "http://localhost:49925"}`
      );
      console.log("=================================");
    });
  } catch (error) {
    console.error("Failed to start server:", error);
    process.exit(1);
  }
};

startServer();
