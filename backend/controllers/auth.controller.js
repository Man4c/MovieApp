import User from "../models/user.model.js";
import { generateToken } from "../lib/jwt.js";

export const signup = async (req, res) => {
  try {
    const { username, email, password } = req.body;

    const userExists = await User.findOne({
      $or: [{ email }, { username }],
    });

    if (userExists) {
      return res.status(400).json({
        message:
          userExists.email == email
            ? "email already exists"
            : "username already taken",
      });
    }
    const user = await User.create({
      username,
      email,
      password,
    });

    const token = generateToken(user._id);
    res.status(201).json({
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
      },
      token: token,
      messages: "User created successfully",
    });
  } catch (error) {
    console.log("Error in signup controller");
    res.status(500).json({
      message: "Failed to create user",
      error: error.message,
    });
  }
};

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email }).select("+password");
    if (!user) {
      return res.status(401).json({ message: "Invalid credentials" });
    }
    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: "Invalid credentials" });
    }
    const token = generateToken(user._id);
    res.status(200).json({
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
      },
      token : token,
      message: "Logged in successfully",
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ message: "Server Error", error: error.message });
  }
};
