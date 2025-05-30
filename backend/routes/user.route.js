import express from "express";
import { protectRoute } from "../middleware/auth.middleware.js";
import {
  getMe,
  getUserFavorites,
  toggleFavorite,
} from "../controllers/user.controller.js";

const router = express.Router();

router.get("/me", protectRoute, getMe);
router.get("/favorites", protectRoute, getUserFavorites);
router.post("/favorites/:movieId", protectRoute, toggleFavorite); // movieId here is tmdbId

export default router;
