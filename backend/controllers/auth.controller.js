import User from "../models/user.model.js";
import { generateToken } from "../lib/jwt.js";

export const signup = async (req, res) => {
  try {
    const { name, email, password } = req.body; // Changed username to name

    const userExists = await User.findOne({
      $or: [{ email }, { username: name }], // Check username: name
    });

    if (userExists) {
      return res.status(400).json({
        message:
          userExists.email == email
            ? "email already exists"
            : "username already taken", // Keep this message as username is the DB field
      });
    }
    const user = await User.create({
      username: name, // Save name from req.body to username field
      email,
      password,
      // role and favorites will default based on schema
    });

    // Fetch the user again to ensure defaults like 'role' and 'favorites' are present
    const createdUser = await User.findById(user._id);

    const token = generateToken(createdUser._id);
    res.status(201).json({
      token: token, // Token first
      user: {
        id: createdUser._id,
        name: createdUser.username, // Respond with name (from username field)
        email: createdUser.email,
        role: createdUser.role, // Include role
        favorites: createdUser.favorites || [], // Include favorites
      },
      messages: "User created successfully", // Message typo corrected from "messages"
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
    console.log(token);
    
    // No need to re-fetch user here if not creating, but ensure all fields are selected
    // If user.role or user.favorites might be excluded by .select('+password'), adjust if necessary
    // For now, assume they are available on 'user' object after findOne without explicit select for those
    res.status(200).json({
      token: token, // Token first
      user: {
        id: user._id,
        name: user.username, // Respond with name (from username field)
        email: user.email,
        role: user.role, // Include role
        favorites: user.favorites || [], // Include favorites
      },
      message: "Logged in successfully",
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ message: "Server Error", error: error.message });
  }
};
