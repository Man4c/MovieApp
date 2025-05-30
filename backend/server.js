import express from 'express'
import dotenv from 'dotenv'
import connectDB from './lib/db.js'
import moviesRoutes from './routes/movie.route.js'
import authRoutes from './routes/auth.route.js'
import userRoutes from './routes/user.route.js' // Import userRoutes


dotenv.config()
const app = express()
const PORT = process.env.PORT || 4002

app.use(express.json())
app.use(express.urlencoded())

app.use('/api/auth', authRoutes)
app.use('/api/movies', moviesRoutes)
app.use('/api/users', userRoutes) // Mount userRoutes


app.listen(PORT, () => {
    console.log(`Server Running in http://localhost:${PORT}`);
    connectDB()
})