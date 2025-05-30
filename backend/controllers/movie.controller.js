import Movie from "../models/movie.model.js";

export const getAllMovies = async (req, res) => {
  try {
    const movies = await Movie.find({});
    res.status(200).json({
      success: true,
      count: movies.length,
      data: movies,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch movies",
      error: error.message,
    });
  }
};

export const getAllMovieByType = async (req, res) => {
  try {
    const movies = await Movie.find({ type: req.params.type });
    res.status(200).json({
      success: true,
      count: movies.length,
      data: movies,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch movies",
      error: error.message,
    });
  }
};

export const getMovieById = async (req, res) => {
  try {
    const foundMovie = await Movie.findOne({ tmdbId: req.params.tmdbId });
    if (!foundMovie) {
      return res.status(404).json({
        success: false,
        message: "Movie not found",
      });
    }
    res.status(200).json({
      success: true,
      data: foundMovie,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch movie",
      error: error.message,
    });
  }
};
