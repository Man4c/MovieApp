import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import connectDB from "./lib/db.js";
import moviesRoutes from "./routes/movie.route.js";
import authRoutes from "./routes/auth.route.js";
import userRoutes from "./routes/user.route.js";
import genreRoutes from "./routes/genre.route.js";

dotenv.config();
const app = express();
const PORT = process.env.PORT || 4002;

app.use(
  cors({
    origin: "http://localhost:49925",
    credentials: true,
  })
);

app.use(express.json());
app.use(express.urlencoded());

app.use("/api/auth", authRoutes);
app.use("/api/movies", moviesRoutes);
app.use("/api/users", userRoutes);
app.use("/api/genres", genreRoutes);

app.listen(PORT, () => {
  console.log(`Server Running in Port :${PORT}`);
  connectDB();
});
