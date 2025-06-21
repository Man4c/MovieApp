import express from "express";
import Stripe from "stripe";
import {
  createCustomer,
  createPaymentIntent,
  createSubscription,
  handleWebhookEvent,
  getSubscription,
} from "../services/stripe.service.js";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
import User from "../models/user.model.js";
import { protectRoute } from "../middleware/auth.middleware.js";

const router = express.Router();

// Create a subscription and return the client secret
router.post("/create-subscription", protectRoute, async (req, res) => {
  const { priceId } = req.body;
  const userId = req.user._id;

  try {
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Create or retrieve Stripe customer
    let stripeCustomerId = user.stripeCustomerId;
    if (!stripeCustomerId) {
      const customer = await createCustomer(user.email, user.username);
      stripeCustomerId = customer.id;
      user.stripeCustomerId = stripeCustomerId;
      await user.save();
    } // Create the subscription
    const result = await createSubscription(stripeCustomerId, priceId);

    // Return the client secret and subscription ID
    res.status(200).json({
      clientSecret: result.clientSecret,
      subscriptionId: result.subscriptionId,
      customerId: result.customerId,
    });
  } catch (error) {
    console.error("Error creating subscription:", error);
    res.status(500).json({
      message: "Failed to create subscription",
      error: error.message,
    });
  }
});

// Confirm subscription after successful payment
router.post("/confirm-subscription", protectRoute, async (req, res) => {
  const { subscriptionId } = req.body;
  const userId = req.user._id;

  try {
    console.log(`Confirming subscription ${subscriptionId} for user ${userId}`);

    // Get subscription details
    const subscription = await getSubscription(subscriptionId);
    console.log(
      "Raw subscription data:",
      JSON.stringify(subscription, null, 2)
    );

    const user = await User.findById(userId);
    if (!user) {
      console.log("User not found");
      return res.status(404).json({ message: "User not found" });
    }

    // Map Stripe status to our system status
    let subscriptionStatus = subscription.status;
    try {
      if (subscription.status === "incomplete" && subscription.latest_invoice) {
        console.log("Checking latest invoice...");
        const latestInvoice = await stripe.invoices.retrieve(
          subscription.latest_invoice
        );
        console.log("Latest invoice:", JSON.stringify(latestInvoice, null, 2));

        if (latestInvoice.paid) {
          subscriptionStatus = "active";
          console.log("Invoice is paid, setting status to active");
        }
      }

      // If status is still incomplete and it's been more than a minute, check payment intent
      if (subscriptionStatus === "incomplete" && subscription.created) {
        const createdTime = new Date(subscription.created * 1000);
        if (Date.now() - createdTime > 60000) {
          // More than 1 minute old
          console.log(
            "Subscription is incomplete and older than 1 minute, checking payment intent..."
          );
          if (
            subscription.latest_invoice &&
            subscription.latest_invoice.payment_intent
          ) {
            const paymentIntent = await stripe.paymentIntents.retrieve(
              subscription.latest_invoice.payment_intent
            );
            console.log("Payment intent status:", paymentIntent.status);
            if (paymentIntent.status === "succeeded") {
              subscriptionStatus = "active";
              console.log("Payment intent succeeded, setting status to active");
            }
          }
        }
      }
    } catch (err) {
      console.log("Error checking invoice/payment status:", err);
      // Continue with the current status if there's an error
    }

    console.log("Final subscription status:", subscriptionStatus);

    // Calculate current period end
    let currentPeriodEnd;
    if (subscription.current_period_end) {
      currentPeriodEnd = new Date(subscription.current_period_end * 1000);
    } else {
      // Default to 30 days from now if not provided
      currentPeriodEnd = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    }
    console.log("Current period end:", currentPeriodEnd);

    // Update user's subscription details
    user.subscription = {
      subscriptionId: subscription.id,
      planId: subscription.items.data[0].price.id,
      status: subscriptionStatus,
      currentPeriodEnd: currentPeriodEnd,
    };

    await user.save();
    console.log("User subscription updated successfully");

    res.status(200).json({
      success: true,
      subscription: {
        status: subscriptionStatus,
        planId: subscription.items.data[0].price.id,
        currentPeriodEnd: currentPeriodEnd,
      },
    });
  } catch (error) {
    console.error("Error confirming subscription:", error);
    res.status(500).json({
      message: "Failed to confirm subscription",
      error: error.message,
    });
  }
});

// Get current subscription status
router.get("/subscription-status", protectRoute, async (req, res) => {
  const userId = req.user._id;

  try {
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!user.subscription?.subscriptionId) {
      return res.status(200).json({
        status: "inactive",
        subscription: null,
      });
    }

    const subscription = await getSubscription(
      user.subscription.subscriptionId
    );

    res.status(200).json({
      status: subscription.status,
      subscription: {
        id: subscription.id,
        planId: subscription.items.data[0].price.id,
        currentPeriodEnd: new Date(subscription.current_period_end * 1000),
        status: subscription.status,
      },
    });
  } catch (error) {
    console.error("Error getting subscription status:", error);
    res.status(500).json({
      message: "Failed to get subscription status",
      error: error.message,
    });
  }
});

// Stripe webhook handler
router.post(
  "/webhook",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    const sig = req.headers["stripe-signature"];
    const rawBody = req.body;

    try {
      const event = await handleWebhookEvent(rawBody, sig);

      switch (event.type) {
        case "customer.subscription.created":
        case "customer.subscription.updated":
          const subscription = event.data.object;
          const user = await User.findOne({
            stripeCustomerId: subscription.customer,
          });

          if (user) {
            user.subscription = {
              subscriptionId: subscription.id,
              planId: subscription.items.data[0].price.id,
              status: subscription.status,
              currentPeriodEnd: new Date(
                subscription.current_period_end * 1000
              ),
            };
            await user.save();
            console.log(
              `User ${user.email} subscription updated to ${subscription.status}`
            );
          }
          break;

        case "payment_intent.succeeded":
          const paymentIntent = event.data.object;
          console.log(
            `PaymentIntent for ${paymentIntent.amount} was successful!`
          );
          break;

        default:
          console.log(`Unhandled event type ${event.type}`);
      }

      res.status(200).json({ received: true });
    } catch (err) {
      console.error("Webhook error:", err);
      res.status(400).send(`Webhook Error: ${err.message}`);
    }
  }
);

export default router;
