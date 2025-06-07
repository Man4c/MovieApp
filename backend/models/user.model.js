import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const userSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: [true, "Name is required"],
      unique: true,
      trim: true,
      minlength: 3,
    },

    email: {
      type: String,
      required: [true, "Email is required"],
      unique: true,
      trim: true,
      lowercase: true,
    },

    googleId: {
      type: String,
      unique: true,
      sparse: true,
    },

    password: {
      type: String,
      required: [
        function () {
          return !this.googleId;
        },
        "Password is required",
      ],
      minlength: [6, "Password must be at least 6 characters"],
      maxLength: 128,
      select: false,
      trim: true,
    },

    favorites: [
      {
        type: String,
      },
    ],

    watchHistory: [
      {
        videoId: {
          type: String,
          required: true,
        },
        watchedAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],

    role: {
      type: String,
      enum: ["customer", "admin"],
      default: "customer",
    },
  },

  {
    timestamps: true,
  }
);

userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) {
    return next();
  }
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

userSchema.methods.matchPassword = async function (password) {
  return await bcrypt.compare(password, this.password);
};

const User = mongoose.model("User", userSchema);

export default User;
