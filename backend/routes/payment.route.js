import express from "express";
import {
  createCustomer,
  createPaymentIntent,
  handleWebhookEvent,
} from "../services/stripe.service.js";
import User from "../models/user.model.js"; 
import { protectRoute } from "../middleware/auth.middleware.js"; 

const router = express.Router();

router.post("/create-payment-intent", protectRoute, async (req, res) => {
  const { planId } = req.body; 
  const userId = req.user._id; 
  try {
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    let stripeCustomerId = user.stripeCustomerId;
    if (!stripeCustomerId) {
      const customer = await createCustomer(user.email, user.username);
      stripeCustomerId = customer.id;
      user.stripeCustomerId = stripeCustomerId;
      await user.save();
    }
    const amount = planId === "premium" ? 1000 : 500;
    const currency = "usd";

    const paymentIntent = await createPaymentIntent(
      amount,
      currency,
      stripeCustomerId
    );
    console.log("Generated Client Secret:", paymentIntent.client_secret);
    res.status(200).json({ clientSecret: paymentIntent.client_secret });

  } catch (error) {
    console.error("Error creating payment intent:", error);
    res
      .status(500)
      .json({
        message: "Failed to create payment intent",
        error: error.message,
      });
  }
});

router.post(
  "/stripe-webhooks",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    const sig = req.headers["stripe-signature"];
    const rawBody = req.body;

    try {
      const event = await handleWebhookEvent(rawBody, sig);

      // Handle the event
      switch (event.type) {
        case "payment_intent.succeeded":
          const paymentIntent = event.data.object;
          console.log(
            `PaymentIntent for ${paymentIntent.amount} was successful!`
          );
          // TODO: Update user subscription status in MongoDB
          // Find user by stripeCustomerId (paymentIntent.customer)
          // Update subscription object (planId, status, currentPeriodEnd)
          const user = await User.findOne({
            stripeCustomerId: paymentIntent.customer,
          });
          if (user) {
            // This is a simplified update. A real scenario would involve more details.
            // e.g. matching planId from the payment to a specific plan in your system.
            user.subscription = {
              subscriptionId: paymentIntent.id, // Or a specific subscription ID if using Stripe Subscriptions
              planId: "some_plan_id", // Determine this based on paymentIntent or webhook metadata
              status: "active",
              currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // Example: 30 days from now
            };
            await user.save();
            console.log(`User ${user.email} subscription updated to active.`);
          } else {
            console.log(
              "Webhook received for unknown customer:",
              paymentIntent.customer
            );
          }
          break;
        // Add other event types to handle, e.g., 'invoice.payment_failed', 'customer.subscription.deleted'
        default:
          console.log(`Unhandled event type ${event.type}`);
      }

      res.status(200).json({ received: true });
    } catch (err) {
      console.error(
        "Webhook signature verification failed or other error:",
        err
      );
      res.status(400).send(`Webhook Error: ${err.message}`);
    }
  }
);

export default router;
