import Movie from "../models/movie.model.js";

export const getUniqueGenres = async (req, res) => {
  try {
    const allTypes = await Movie.distinct("genre");
    console.log(allTypes);
    
    // Define special types used for HomeScreen ordering or other non-genre categories
    const homeScreenSpecificTypes = [
      "upcoming",
      "now_playing",
      "trending",
      "top_rated",
      "movie", // Assuming 'movie' itself is a general type, not a genre for discovery
      "series", // Assuming 'series' itself is a general type, not a genre for discovery
      "trailer" // Assuming 'trailer' itself is a general type, not a genre for discovery
    ];

    // Filter out these special types and any null/empty strings
    const uniqueGenres = allTypes

    res.status(200).json({
      success: true,
      genres: uniqueGenres,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch genres",
      error: error.message,
    });
  }
};
