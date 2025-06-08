import express from "express";
import {
  getAllMovies,
  getAllMovieByType,
  getMovieById
} from "../controllers/movie.controller.js";
import {
  addMovieComment,
  getMovieComments
} from "../controllers/comment.controller.js";

import { protectRoute } from "../middleware/auth.middleware.js";

const router = express.Router();

router.get("/", protectRoute, getAllMovies);
router.get("/by-type/:type", protectRoute, getAllMovieByType);
router.get("/:tmdbId", protectRoute, getMovieById);

// Comment routes for a specific movie
router.get("/:tmdbId/comments", getMovieComments);
router.post("/:tmdbId/comments", protectRoute, addMovieComment);

export default router;