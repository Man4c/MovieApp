import mongoose from "mongoose";
import Review from "../models/review.model.js";
import Movie from "../models/movie.model.js";
import User from "../models/user.model.js";

export const addMovieReview = async (req, res) => {
  try {
    const { comment, rating } = req.body;
    const { tmdbId: movieId } = req.params; // tmdbId is the movieId
    const userId = req.user.id;

    // Validate movie exists
    const movie = await Movie.findOne({ tmdbId: movieId });
    if (!movie) {
      return res.status(404).json({ success: false, message: "Movie not found" });
    }

    // Create new review
    const review = new Review({
      id: new mongoose.Types.ObjectId().toString(), // Generate unique ID
      videoId: movieId, // Store tmdbId as videoId
      userId,
      comment,
      rating,
    });

    await review.save();

    // Map response
    const populatedReview = await Review.findById(review._id).populate('userId', '_id username');

    res.status(201).json({
      success: true,
      data: {
        id: populatedReview.id, // Use the generated string id
        videoId: populatedReview.videoId,
        comment: populatedReview.comment,
        rating: populatedReview.rating,
        user: { // Changed from userId to user object
          id: populatedReview.userId._id, // keep original user ObjectId if needed
          name: populatedReview.userId.username
        },
        timestamp: populatedReview.createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to add review",
      error: error.message,
    });
  }
};

export const getMovieReviews = async (req, res) => {
  try {
    const { tmdbId: movieId } = req.params; // tmdbId is the movieId

    const reviews = await Review.find({ videoId: movieId }).populate({
      path: 'userId', // Populate the user field
      select: 'username _id' // Select username and _id from User model
    });

    if (!reviews) {
      return res.status(404).json({ success: false, message: "Reviews not found for this movie" });
    }

    // Map response
    const mappedReviews = reviews.map(review => ({
      id: review.id, // Use the generated string id
      videoId: review.videoId,
      comment: review.comment,
      rating: review.rating,
      user: { // Changed from userId to user object
        id: review.userId._id, // User's original ObjectId
        name: review.userId.username // User's name
      },
      timestamp: review.createdAt,
    }));

    res.status(200).json({
      success: true,
      count: mappedReviews.length,
      data: mappedReviews,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch reviews",
      error: error.message,
    });
  }
};
