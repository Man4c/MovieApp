import mongoose from "mongoose";
import Comment from "../models/comment.model.js";
import Movie from "../models/movie.model.js";
import User from "../models/user.model.js";

export const addMovieComment = async (req, res) => {
  try:
    const { comment, rating, parentId } = req.body;
    const { tmdbId: movieId } = req.params; // tmdbId is the movieId
    const userId = req.user.id;

    // Validate movie exists
    const movie = await Movie.findOne({ tmdbId: movieId });
    if (!movie) {
      return res.status(404).json({ success: false, message: "Movie not found" });
    }

    // Create new comment
    const newComment = new Comment({
      id: new mongoose.Types.ObjectId().toString(), // Generate unique ID
      videoId: movieId, // Store tmdbId as videoId
      userId,
      comment,
      rating,
      parentId: parentId || null, // Add parentId
    });

    await newComment.save();

    // Map response
    const populatedComment = await Comment.findById(newComment._id).populate('userId', '_id username');

    res.status(201).json({
      success: true,
      data: {
        id: populatedComment.id, // Use the generated string id
        videoId: populatedComment.videoId,
        comment: populatedComment.comment,
        rating: populatedComment.rating,
        parentId: populatedComment.parentId, // Include parentId in response
        user: { // Changed from userId to user object
          id: populatedComment.userId._id, // keep original user ObjectId if needed
          name: populatedComment.userId.username
        },
        timestamp: populatedComment.createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to add comment",
      error: error.message,
    });
  }
};

export const getMovieComments = async (req, res) => {
  try {
    const { tmdbId: movieId } = req.params; // tmdbId is the movieId

    const comments = await Comment.find({ videoId: movieId }).populate({
      path: 'userId', // Populate the user field
      select: 'username _id' // Select username and _id from User model
    });

    if (!comments) {
      return res.status(404).json({ success: false, message: "Comments not found for this movie" });
    }

    // Map response to include replies array and prepare for nesting
    const commentMap = {};
    const nestedComments = [];

    comments.forEach(comment => {
      const commentData = {
        id: comment.id, // Use the generated string id
        videoId: comment.videoId,
        comment: comment.comment,
        rating: comment.rating,
        parentId: comment.parentId,
        user: { // Changed from userId to user object
          id: comment.userId._id, // User's original ObjectId
          name: comment.userId.username // User's name
        },
        timestamp: comment.createdAt,
        replies: [] // Initialize replies array
      };
      commentMap[comment.id] = commentData;

      if (comment.parentId) {
        if (commentMap[comment.parentId]) {
          commentMap[comment.parentId].replies.push(commentData);
        } else {
          // Handle orphaned comment (parent not yet processed or does not exist)
          // For simplicity, adding to root, but could be handled differently
          nestedComments.push(commentData);
        }
      } else {
        nestedComments.push(commentData);
      }
    });

    res.status(200).json({
      success: true,
      count: nestedComments.length, // Count of top-level comments
      data: nestedComments,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch comments",
      error: error.message,
    });
  }
};
