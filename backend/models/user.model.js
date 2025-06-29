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

    stripeCustomerId: {
      type: String,
    },
    subscription: {
      subscriptionId: {
        type: String,
      },
      planId: {
        type: String,
      },
      status: {
        type: String,
        enum: [
          "active",
          "canceled",
          "past_due",
          "inactive",
          "incomplete",
          "incomplete_expired",
          "trialing",
          "unpaid",
          "paused",
        ],
        default: "inactive",
      },
      currentPeriodEnd: {
        type: Date,
        set: function (date) {
          if (!date) {
            return new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // Default to 30 days from now
          }
          if (typeof date === "number") {
            return new Date(date * 1000);
          }
          if (date instanceof Date) {
            return date;
          }
          // Try to parse string date
          const parsedDate = new Date(date);
          if (!isNaN(parsedDate.getTime())) {
            return parsedDate;
          }
          // If all else fails, default to 30 days from now
          return new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
        },
      },
    },

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
