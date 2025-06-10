import mongoose from "mongoose";
import Comment from "../models/comment.model.js";
import Movie from "../models/movie.model.js";
import User from "../models/user.model.js";

export const addMovieComment = async (req, res) => {
  try{
    const { comment, rating, parentId } = req.body;
    const { tmdbId: movieId } = req.params; // tmdbId is the movieId
    const userId = req.user.id;
    const userRole = req.user.role;

    // Check if it's a reply and if the user is not an admin
    if (parentId && userRole !== "admin") {
      return res.status(403).json({
        success: false,
        message: "Only admins can reply to comments.",
        error: "FORBIDDEN_REPLY",
      });
    }

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
    const { tmdbId: movieId } = req.params; 

    const comments = await Comment.find({ videoId: movieId })
                                  .populate({
                                    path: 'userId',
                                    select: 'username _id'
                                  })
                                  .sort({ createdAt: 1 }); 

    if (!comments) {
      return res.status(404).json({ success: false, message: "Comments not found for this movie" });
    }

    const mappedComments = comments.map(comment => ({
      id: comment.id,
      videoId: comment.videoId,
      comment: comment.comment,
      rating: comment.rating,
      user: {
        id: comment.userId._id,
        name: comment.userId.username
      },
      parentId: comment.parentId ? comment.parentId.toString() : null,
      timestamp: comment.createdAt,
    }));

    res.status(200).json({
      success: true,
      count: mappedComments.length,
      data: mappedComments, // Send the flat list
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch comments",
      error: error.message,
    });
  }
};
