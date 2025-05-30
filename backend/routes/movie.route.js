import express from "express";
import {
  getAllMovies,
  getAllMovieByType,
  getMovieById
} from "../controllers/movie.controller.js";

import { protectRoute } from "../middleware/auth.middleware.js";

const router = express.Router();

router.get("/", protectRoute, getAllMovies);
router.get("/by-type/:type", protectRoute, getAllMovieByType);
router.get("/:tmdbId", protectRoute, getMovieById);

export default router;