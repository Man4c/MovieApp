import Movie from "../models/movie.model.js";

// Helper function for field mapping
const mapMovieData = (movie) => ({
  id: movie.tmdbId,
  title: movie.title,
  description: movie.description,
  thumbnailUrl: movie.posterPath,
  backdropPath: movie.backdropPath || movie.posterPath, // Fallback to poster if no backdrop
  videoUrl: movie.videoUrl,
  categories: movie.genre,
  type: Array.isArray(movie.type) ? movie.type : [movie.type].filter(Boolean), // Ensure type is always an array
  rating: movie.rating,
  releaseDate: movie.releaseDate,
  tags: movie.tags || [],
});

export const getAllMovies = async (req, res) => {
  try {
    const searchQuery = req.query.search;
    const categoryQuery = req.query.category;
    const loadAll = req.query.loadAll === "true";

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

    let moviesQuery = Movie.find(query);

    const page = parseInt(req.query.page) || 1;
    const pageSize = 10; // Default page size

    // Only apply pagination if not loading all AND no category filter is active
    if (!loadAll && !categoryQuery) {
      moviesQuery = moviesQuery.skip((page - 1) * pageSize).limit(pageSize);
    }
    // If categoryQuery is present, pagination is skipped by default.
    // If loadAll is true, pagination is also skipped.

    const moviesFromDB = await moviesQuery;
    const mappedMovies = moviesFromDB.map(mapMovieData);

    let responseJson = {
      success: true,
      movies: mappedMovies,
    };

    if (!loadAll && !categoryQuery) {
      const totalMoviesCount = await Movie.countDocuments(query);
      responseJson.currentPage = page;
      responseJson.totalPages = Math.ceil(totalMoviesCount / pageSize);
      responseJson.totalMovies = totalMoviesCount;
    } else {
      responseJson.totalMovies = moviesFromDB.length;
    }

    res.status(200).json(responseJson);
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
    const types = await Movie.distinct("type");
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
