import Movie from "../models/movie.model.js";

// Helper function for field mapping
const mapMovieData = (movie) => ({
  id: movie.tmdbId,
  title: movie.title,
  description: movie.description,
  thumbnailUrl: movie.posterPath,
  backdropPath: movie.backdropPath,
  videoUrl: movie.videoUrl,
  categories: movie.genre,
  type: movie.type,
  rating: movie.rating,
  releaseDate: movie.releaseDate,
  tags: movie.tags || [],
  // Add other fields if necessary, ensuring to remove/handle _id if needed
});

export const getAllMovies = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const pageSize = 10; // Or another sensible default
    const searchQuery = req.query.search;
    const categoryQuery = req.query.category;

    let query = {};

    if (searchQuery) {
      query.$or = [
        { title: { $regex: searchQuery, $options: "i" } },
        { description: { $regex: searchQuery, $options: "i" } },
      ];
    }

    if (categoryQuery) {
      // Assuming movie.type is an array of strings
      query.type = { $regex: new RegExp(`^${categoryQuery}$`, "i") };
    }

    const totalMovies = await Movie.countDocuments(query);
    const totalPages = Math.ceil(totalMovies / pageSize);

    const moviesFromDB = await Movie.find(query)
      .skip((page - 1) * pageSize)
      .limit(pageSize);

    const mappedMovies = moviesFromDB.map(mapMovieData);

    res.status(200).json({
      success: true,
      movies: mappedMovies,
      currentPage: page,
      totalPages: totalPages,
      totalMovies: totalMovies,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch movies",
      error: error.message,
    });
  }
};

export const getMovieTypes = async (req, res) => {
  try {
    // The 'type' field in movie.model.js is an array of strings.
    // Movie.distinct('type') will return all unique strings from all 'type' arrays.
    const types = await Movie.distinct('type');
    res.status(200).json({
      success: true,
      data: types,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch movie types",
      error: error.message,
    });
  }
};

export const getAllMovieByType = async (req, res) => {
  try {
    // This route might become redundant, but we'll keep it for now
    // Consider updating its logic similarly if it's to be kept and used
    const movies = await Movie.find({ type: req.params.type });
    const mappedMovies = movies.map(mapMovieData); // Apply mapping here too
    res.status(200).json({
      success: true,
      count: mappedMovies.length, // Based on mapped movies
      data: mappedMovies, // Send mapped movies
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch movies by type",
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
      data: mapMovieData(foundMovie), // Apply mapping here
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch movie",
      error: error.message,
    });
  }
};
