import Movie from "../models/movie.model.js";

export const getUniqueGenres = async (req, res) => {
  try {
    const allTypes = await Movie.distinct("genre");
    const uniqueGenres = allTypes;

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
