// backend/config/passport-setup.js
import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import User from '../models/user.model.js';
import { generateToken } from '../lib/jwt.js'; // Assuming this is where your JWT generation is

passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      callbackURL: process.env.GOOGLE_CALLBACK_URL || '/api/auth/google/callback', // Ensure this matches the route
      scope: ['profile', 'email'],
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        let user = await User.findOne({ googleId: profile.id });

        if (user) {
          return done(null, user);
        }

        // Check if email already exists for a non-Google user
        const existingEmailUser = await User.findOne({ email: profile.emails[0].value });
        if (existingEmailUser && !existingEmailUser.googleId) {
          // Optionally link accounts or return an error. For now, error.
          return done(new Error('Email already registered. Please log in with your password or link your Google account.'), null);
        }

        // Ensure username is unique if derived from displayName
        let username = profile.displayName.replace(/\s+/g, '').toLowerCase();
        const userWithSameUsername = await User.findOne({ username });
        if (userWithSameUsername) {
          username = `${username}${Date.now().toString().slice(-4)}`; // Append some random numbers
        }

        user = new User({
          googleId: profile.id,
          username: username, // Or derive from profile.displayName, ensure uniqueness
          email: profile.emails[0].value,
          // Password will be undefined/null (as per model changes)
          // role defaults to 'customer'
        });
        await user.save();
        return done(null, user);
      } catch (error) {
        return done(error, null);
      }
    }
  )
);

// These are not strictly necessary for JWT stateless auth but often included in passport examples.
// For session-based auth, they would be crucial. For JWT, the user object from 'done' is passed to the route handler.
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

export default passport;
