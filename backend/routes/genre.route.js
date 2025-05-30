import express from "express";
import { getUniqueGenres } from "../controllers/genre.controller.js";
// import { protectRoute } from "../middleware/auth.middleware.js"; // Uncomment if protection is needed

const router = express.Router();

// Route to get all unique movie genres
// This route is public by default. If authentication/authorization is needed,
// add protectRoute middleware before getUniqueGenres.
// Example: router.get("/", protectRoute, getUniqueGenres);
router.get("/", getUniqueGenres);

export default router;
