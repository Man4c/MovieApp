import express from "express";
import { protectRoute, adminProtectRoute } from "../middleware/auth.middleware.js";
import {
  getAllUsers, // Added import for getAllUsers
  getMe,
  getUserFavorites,
  toggleFavorite,
  getWatchHistory,
  addToWatchHistory,
  clearWatchHistory,
  updateUsername,
} from "../controllers/user.controller.js";

const router = express.Router();

// Admin route to get all users
router.get("/admin/users", protectRoute, adminProtectRoute, getAllUsers);

router.get("/me", protectRoute, getMe);
router.put("/me/username", protectRoute, updateUsername);
router.get("/favorites", protectRoute, getUserFavorites);
router.post("/favorites/:movieId", protectRoute, toggleFavorite); // movieId here is tmdbId
router.get("/watch-history", protectRoute, getWatchHistory);
router.post("/watch-history/:movieId", protectRoute, addToWatchHistory);
router.delete("/watch-history", protectRoute, clearWatchHistory);

export default router;
