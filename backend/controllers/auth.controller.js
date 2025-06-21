import User from "../models/user.model.js";
import { generateToken } from "../lib/jwt.js";
import { OAuth2Client } from "google-auth-library";

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID; // Ensure this is available
const client = new OAuth2Client(GOOGLE_CLIENT_ID);

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
        stripeCustomerId: createdUser.stripeCustomerId,
        subscription: createdUser.subscription,
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

    
    res.status(200).json({
      token: token, // Token first
      user: {
        id: user._id,
        name: user.username, // Respond with name (from username field)
        email: user.email,
        role: user.role, // Include role
        favorites: user.favorites || [], // Include favorites
        stripeCustomerId: user.stripeCustomerId,
        subscription: user.subscription,
      },
      message: "Logged in successfully",
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ message: "Server Error", error: error.message });
  }
};

export const verifyGoogleToken = async (req, res) => {
  const { idToken } = req.body;

  if (!idToken) {
    return res.status(400).json({ message: "ID token is required" });
  }

  try {
    const ticket = await client.verifyIdToken({
      idToken,
      audience: GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const googleId = payload["sub"];
    const email = payload["email"];
    const displayName = payload["name"]; // Get full name from Google

    // Find or create user
    let user = await User.findOne({ googleId });
    console.log("Google payload:", payload);
    console.log("Display name from Google:", displayName);
    if (user) {
      // User found with googleId, log them in
      const token = generateToken(user._id);
      return res.status(200).json({
        token,
        user: {
          id: user._id,
          name: user.username, // Send username as name to frontend
          email: user.email,
          role: user.role,
          favorites: user.favorites || [],
          watchHistory: user.watchHistory || [],
          googleId: user.googleId,
          stripeCustomerId: user.stripeCustomerId,
          subscription: user.subscription,
        },
        message: "Google authentication successful",
      });
    }

    // No user with googleId, check if email exists for a non-Google user
    const existingEmailUser = await User.findOne({ email });
    if (existingEmailUser && !existingEmailUser.googleId) {
      return res.status(400).json({
        message:
          "Email already registered with a password. Please log in with your password or link your Google account (linking not implemented).",
        needsLinking: true, // Custom flag for frontend
      });
    }

    // If email exists with a googleId, it should have been caught by the first User.findOne({googleId})
    // So, if we are here, it's a new user or an existing Google user whose googleId wasn't found (should not happen if DB is consistent)    let username = displayName;
    // Keep the display name as is for better user experience
    const userWithSameUsername = await User.findOne({ username });
    if (userWithSameUsername) {
      // If username exists, append a unique identifier but keep the display name readable
      username = `${displayName} ${Date.now().toString().slice(-4)}`;
    }

    user = new User({
      googleId,
      username,
      email,
      // Password will be undefined/null
    });
    await user.save();

    const token = generateToken(user._id);
    return res.status(201).json({
      // 201 for new resource created
      token,
      user: {
        id: user._id,
        name: user.username,
        email: user.email,
        role: user.role,
        favorites: user.favorites || [],
        googleId: user.googleId,
        stripeCustomerId: user.stripeCustomerId,
        subscription: user.subscription,
      },
      message: "Google user registered and logged in successfully",
    });
  } catch (error) {
    console.error("Error verifying Google token:", error);
    if (
      error.message.includes("Invalid token signature") ||
      error.message.includes("Token used too late") ||
      error.message.includes("Invalid audience")
    ) {
      return res
        .status(401)
        .json({ message: "Invalid Google token or token expired." });
    }
    return res
      .status(500)
      .json({ message: "Failed to verify Google token", error: error.message });
  }
};

export const changePassword = async (req, res) => {
  try {
    const userId = req.user.id;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res
        .status(400)
        .json({ message: "Current password and new password are required" });
    }

    const user = await User.findById(userId).select("+password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!user.password && user.googleId) {
      return res.status(400).json({
        message: "Cannot change password for accounts registered with Google.",
      });
    }

    const isMatch = await user.matchPassword(currentPassword);
    if (!isMatch) {
      return res.status(401).json({ message: "Incorrect current password" });
    }

    if (newPassword.length < 6) {
      return res
        .status(400)
        .json({ message: "New password must be at least 6 characters" });
    }

    user.password = newPassword;
    await user.save();

    res.status(200).json({ message: "Password changed successfully" });
  } catch (error) {
    console.error("Change password error:", error);
    res.status(500).json({ message: "Server Error", error: error.message });
  }
};

export const logout = async (req, res) => {
  try {
    // Clear the JWT cookie
    res.cookie("jwt", "", {
      httpOnly: true,
      expires: new Date(0), // Set expiration date to the past
      secure: process.env.NODE_ENV !== "development", // Use secure cookies in production
      sameSite: "strict",
    });

    res.status(200).json({ message: "Logged out successfully" });
  } catch (error) {
    console.error("Logout error:", error);
    res.status(500).json({ message: "Server Error", error: error.message });
  }
};
