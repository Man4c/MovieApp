import User from "../models/user.model.js";
import Movie from "../models/movie.model.js";
// Attempt to import mapMovieData. If movie.controller.js also exports it directly.
// If it's not directly exported, we might need to define it or extract it to a shared utils file.
// For now, let's assume it can be imported or we'll define a local version if needed.

// Placeholder for mapMovieData if direct import fails or for clarity
const mapMovieData = (movie) => {
  if (!movie) return null;
  return {
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
  };
};

export const getMe = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    res.status(200).json({
      success: true,
      data: {
        id: user._id,
        name: user.username,
        email: user.email,
        role: user.role,
        favorites: user.favorites || [], // Ensure favorites is always an array
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to get user details",
      error: error.message,
    });
  }
};

export const getUserFavorites = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    const favoriteTmdbIds = user.favorites || [];
    if (favoriteTmdbIds.length === 0) {
      return res.status(200).json({ success: true, data: [] });
    }

    const favoriteMovies = await Movie.find({ tmdbId: { $in: favoriteTmdbIds } });

    const mappedFavorites = favoriteMovies.map(mapMovieData).filter(movie => movie !== null);

    res.status(200).json({
      success: true,
      data: mappedFavorites,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to get user favorites",
      error: error.message,
    });
  }
};

export const toggleFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { movieId: tmdbId } = req.params; // movieId is tmdbId

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    const movie = await Movie.findOne({ tmdbId: tmdbId });
    if (!movie) {
      return res.status(404).json({ success: false, message: "Movie not found" });
    }

    const currentFavorites = user.favorites || [];
    const isFavorite = currentFavorites.includes(tmdbId);

    if (isFavorite) {
      // Remove from favorites
      user.favorites = currentFavorites.filter((favId) => favId !== tmdbId);
    } else {
      // Add to favorites
      user.favorites.push(tmdbId);
    }

    await user.save();

    res.status(200).json({
      success: true,
      message: isFavorite ? "Removed from favorites" : "Added to favorites",
      data: {
        favorites: user.favorites,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to update favorites",
      error: error.message,
    });
  }
};
