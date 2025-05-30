import mongoose from "mongoose";

const movieSchema = new mongoose.Schema(
    {
        tmdbId: { 
            type: String, 
            required: true, 
            unique: true 
        },
        title: { 
            type: String, 
            required: true 
        },
        description: { 
            type: String, 
            required: true 
        },
        posterPath: { 
            type: String, 
            required: true 
        },
        backdropPath: { 
            type: String, 
            required: true 
        },
        videoUrl: { 
            type: String, 
            required: true 
        },
        genre: [
            { 
                type: String 
            }
        ],
        type : [
            {
                type : String 
            }
        ],
        rating: {
             type: Number, 
             required: true, 
             min: 0, 
             max: 5
        },
        releaseDate: { 
            type: String, 
            required: true 
        },
    }
);

const Movie = mongoose.model('Movie', movieSchema)

export default Movie