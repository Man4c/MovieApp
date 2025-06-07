import express from "express";
import { protectRoute } from "../middleware/auth.middleware.js";
import {
  getMe,
  getUserFavorites,
  toggleFavorite,
  getWatchHistory,
  addToWatchHistory,
  clearWatchHistory,
} from "../controllers/user.controller.js";

const router = express.Router();

router.get("/me", protectRoute, getMe);
router.get("/favorites", protectRoute, getUserFavorites);
router.post("/favorites/:movieId", protectRoute, toggleFavorite); // movieId here is tmdbId
router.get("/watch-history", protectRoute, getWatchHistory);
router.post("/watch-history/:movieId", protectRoute, addToWatchHistory);
router.delete("/watch-history", protectRoute, clearWatchHistory);

export default router;
