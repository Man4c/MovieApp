import express from "express";
import passport from "passport";
import {
  signup,
  login,
  logout,
  changePassword,
  verifyGoogleToken,
} from "../controllers/auth.controller.js";
import { protectRoute } from "../middleware/auth.middleware.js";
import { generateToken } from "../lib/jwt.js"; // Import generateToken

const router = express.Router();

router.post("/signup", signup);
router.post("/login", login);
router.post("/logout", logout);
router.post("/change-password", protectRoute, changePassword);
router.post("/google/token", verifyGoogleToken); // Add this line for handling Google token

// Route to initiate Google OAuth flow
router.get(
  "/google",
  passport.authenticate("google", { scope: ["profile", "email"] })
);

// Google OAuth callback route
router.get(
  "/google/callback",
  passport.authenticate("google", {
    failureRedirect: "/login",
    session: false,
  }), // session: false as we are using JWT
  (req, res) => {
    // Successful authentication
    const token = generateToken(req.user._id);
    // Instead of redirecting, send token and user data back as JSON
    res.status(200).json({
      token: token,
      user: {
        id: req.user._id,
        name: req.user.username,
        email: req.user.email,
        role: req.user.role,
        favorites: req.user.favorites || [],
        googleId: req.user.googleId,
      },
      message: "Google authentication successful",
    });
  }
);

// Google token verification route
router.post("/google/verify", verifyGoogleToken);

export default router;
