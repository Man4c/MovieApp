import express from "express";
import {
  addMovie, // Added import for addMovie
  getAllMovies,
  getAllMovieByType,
  getMovieById
} from "../controllers/movie.controller.js";
import {
  addMovieComment,
  getMovieComments
} from "../controllers/comment.controller.js";

import { protectRoute, adminProtectRoute } from "../middleware/auth.middleware.js"; // Added adminProtectRoute

const router = express.Router();

// Admin route to add a new movie
router.post("/admin/movies", protectRoute, adminProtectRoute, addMovie);

router.get("/", protectRoute, getAllMovies);
router.get("/by-type/:type", protectRoute, getAllMovieByType);
router.get("/:tmdbId", protectRoute, getMovieById);

// Comment routes for a specific movie
router.get("/:tmdbId/comments", getMovieComments);
router.post("/:tmdbId/comments", protectRoute, addMovieComment);

export default router;