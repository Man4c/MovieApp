import express from "express";
import {
  getAllMovies,
  getAllMovieByType,
  getMovieById,
  getMovieTypes // Added getMovieTypes
} from "../controllers/movie.controller.js";
import {
  addMovieReview,
  getMovieReviews
} from "../controllers/review.controller.js";

import { protectRoute } from "../middleware/auth.middleware.js";

const router = express.Router();

// Route to get all unique movie types (public)
router.get("/types/all", getMovieTypes);

router.get("/", protectRoute, getAllMovies);
router.get("/by-type/:type", protectRoute, getAllMovieByType);
router.get("/:tmdbId", protectRoute, getMovieById);

// Review routes for a specific movie
router.get("/:tmdbId/reviews", protectRoute, getMovieReviews);
router.post("/:tmdbId/reviews", protectRoute, addMovieReview);

export default router;