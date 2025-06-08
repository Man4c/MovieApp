// backend/config/passport-setup.js
import passport from "passport";
import { Strategy as GoogleStrategy } from "passport-google-oauth20";
import User from "../models/user.model.js";
import dotenv from "dotenv";

// Ensure environment variables are loaded
dotenv.config();

// Validate required Google OAuth configuration
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
console.log("Google OAuth Configuration loaded successfully");

if (!GOOGLE_CLIENT_ID) {
  console.error("Missing required Google client ID");
  process.exit(1);
}

passport.serializeUser((user, done) => {
  done(null, user.id);
});

passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findById(id);
    done(null, user);
  } catch (error) {
    done(error, null);
  }
});

passport.use(
  new GoogleStrategy(
    {
      clientID: GOOGLE_CLIENT_ID,
      clientSecret: "UNUSED", // Not needed for Android token verification
      callbackURL: "UNUSED", // Not needed for Android token verification
      scope: ["profile", "email"],
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        let user = await User.findOne({ googleId: profile.id });

        if (user) {
          return done(null, user);
        }

        // Check if email already exists
        const existingEmailUser = await User.findOne({
          email: profile.emails[0].value,
        });
        if (existingEmailUser && !existingEmailUser.googleId) {
          return done(
            new Error(
              "Email already registered. Please log in with your password."
            ),
            null
          );
        }

        // Create new user
        let username = profile.displayName.replace(/\s+/g, "").toLowerCase();
        const userWithSameUsername = await User.findOne({ username });
        if (userWithSameUsername) {
          username = `${username}${Date.now().toString().slice(-4)}`;
        }

        user = new User({
          googleId: profile.id,
          username: username,
          email: profile.emails[0].value,
        });

        await user.save();
        return done(null, user);
      } catch (error) {
        return done(error, null);
      }
    }
  )
);

export default passport;
