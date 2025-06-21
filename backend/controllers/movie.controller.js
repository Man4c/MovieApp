import Movie from "../models/movie.model.js";

const mapMovieData = (movie) => ({
  id: movie.tmdbId,
  title: movie.title,
  description: movie.description,
  thumbnailUrl: movie.posterPath,
  backdropPath: movie.backdropPath || movie.posterPath, 
  videoUrl: movie.videoUrl,
  categories: movie.genre,
  type: Array.isArray(movie.type) ? movie.type : [movie.type].filter(Boolean),
  rating: movie.rating,
  releaseDate: movie.releaseDate,
  tags: movie.tags || [],
});

export const getAllMovies = async (req, res) => {
  try {
    const searchQuery = req.query.search;
    const categoryQuery = req.query.category;
    const filterType = req.query.filterType;
    const loadAll = req.query.loadAll === "true";

    let query = {};
    console.log("Received query params:", {
      searchQuery,
      categoryQuery,
      filterType,
      loadAll,
    });

    if (searchQuery) {
      query.$or = [
        { title: { $regex: searchQuery, $options: "i" } },
        { description: { $regex: searchQuery, $options: "i" } },
      ];
    }
    if (categoryQuery) {
      const normalizedCategory = categoryQuery.trim();
      query.genre = {
        $elemMatch: {
          $regex: new RegExp(`^${normalizedCategory}$`, "i"),
        },
      };
    }

    if (filterType) {
      const normalizedType = filterType.trim();
      query.type = {
        $elemMatch: {
          $regex: new RegExp(`^${normalizedType}$`, "i"),
        },
      };
    }

    let moviesQuery = Movie.find(query);

    const page = parseInt(req.query.page) || 1;
    const pageSize = 20; // Increased page size

    if (!loadAll && !categoryQuery) {
      moviesQuery = moviesQuery.skip((page - 1) * pageSize).limit(pageSize);
    }

    moviesQuery = moviesQuery.sort({ releaseDate: -1 });

    const queryResults = await moviesQuery;

    if (!queryResults || queryResults.length === 0) {
      console.log(`No movies found for query:`, query);
      return res.status(200).json({
        success: true,
        data: [],
      });
    }

    const mappedResults = queryResults.map(mapMovieData);
    console.log(`Found ${mappedResults.length} movies for query:`, query);

    res.status(200).json({
      success: true,
      data: mappedResults,
    });
  } catch (error) {
    console.error("Error fetching movies:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch movies",
      error: error.message,
    });
  }
};

export const addMovie = async (req, res) => {
  try {
    const {
      title,
      description,
      videoUrl,
      posterPath,
      backdropPath,
      genre,
      type,
      rating,
      releaseDate,
      tmdbId,
    } = req.body;

    if (
      !title ||
      !description ||
      !videoUrl ||
      !posterPath ||
      !genre ||
      !type ||
      !tmdbId
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Missing required fields. Title, description, videoUrl, posterPath, genre, type, and tmdbId are required.",
        error: "MISSING_FIELDS",
      });
    }

    const existingMovie = await Movie.findOne({ tmdbId });
    if (existingMovie) {
      return res.status(409).json({
        success: false,
        message: "A movie with this tmdbId already exists.",
        error: "MOVIE_ALREADY_EXISTS",
      });
    }

    const newMovie = new Movie({
      title,
      description,
      videoUrl,
      posterPath,
      backdropPath: backdropPath || posterPath, 
      genre,
      type,
      rating,
      releaseDate,
      tmdbId,
    });

    await newMovie.save();

    res.status(201).json({
      success: true,
      message: "Movie added successfully",
      data: mapMovieData(newMovie),
    });
  } catch (error) {
    console.error("Error adding movie:", error);
    res.status(500).json({
      success: false,
      message: "Failed to add movie",
      error: error.message,
    });
  }
};
export const getAllMovieByType = async (req, res) => {
  try {
    const movies = await Movie.find({ type: req.params.type });
    const mappedMovies = movies.map(mapMovieData); 
    res.status(200).json({
      success: true,
      count: mappedMovies.length, 
      data: mappedMovies,
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
      data: mapMovieData(foundMovie), 
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch movie",
      error: error.message,
    });
  }
};
