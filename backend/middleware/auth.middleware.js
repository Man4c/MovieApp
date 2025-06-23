import jwt from "jsonwebtoken";
import User from "../models/user.model.js";
import admin from "firebase-admin";
import { createRequire } from "module";
const require = createRequire(import.meta.url);
const serviceAccount = require("../serviceAccountKey.json");

// Inisialisasi Firebase Admin hanya sekali
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

export const protectRoute = async (req, res, next) => {
  const authHeader = req.headers["authorization"];

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({
      success: false,
      message: "Access token is required",
      error: "MISSING_TOKEN",
    });
  }
  const token = authHeader.substring(7);

  if (!token) {
    return res.status(401).json({
      success: false,
      message: "Access token is required",
      error: "MISSING_TOKEN",
    });
  }

  // Coba verifikasi sebagai JWT lama dulu
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId).select("-password");
    if (!user) {
      return res.status(401).json({
        success: false,
        message: "User for this token not found.",
        error: "USER_TOKEN_NOT_FOUND",
      });
    }
    req.user = user;
    return next();
  } catch (jwtError) {
    // Jika gagal, coba verifikasi sebagai token Firebase
    try {
      const decodedFirebase = await admin.auth().verifyIdToken(token);
      // Anda bisa mencari user di DB berdasarkan decodedFirebase.uid/email jika perlu
      req.user = decodedFirebase;
      return next();
    } catch (firebaseError) {
      // Jika gagal juga, kirim error invalid token
      return res.status(401).json({
        success: false,
        message: "Invalid token",
        error: "INVALID_TOKEN",
      });
    }
  }
};

export const adminProtectRoute = async (req, res, next) => {
  if (req.user && req.user.role === "admin") {
    next();
  } else {
    res.status(403).json({
      success: false,
      message: "Access denied. Admin role required.",
      error: "FORBIDDEN",
    });
  }
};
