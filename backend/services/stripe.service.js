import Stripe from "stripe";
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export const createCustomer = async (email, name) => {
  console.log(`Creating Stripe customer for email: ${email}, name: ${name}`);
  const customer = await stripe.customers.create({ email, name });
  return customer;
};

export const createPaymentIntent = async (amount, currency, customerId) => {
  console.log(
    `Creating PaymentIntent for customer: ${customerId}, amount: ${amount} ${currency}`
  );
  const paymentIntent = await stripe.paymentIntents.create({
    amount,
    currency,
    customer: customerId,
    automatic_payment_methods: {
      enabled: true,
    },
  });
  return paymentIntent;
};

export const createSubscription = async (customerId, priceId) => {
  console.log(
    `Creating subscription for customer: ${customerId}, price: ${priceId}`
  );
  try {
    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{ price: priceId }],
      payment_behavior: "default_incomplete",
      payment_settings: { save_default_payment_method: "on_subscription" },
      expand: ["latest_invoice.payment_intent"],
      metadata: {
        customerId: customerId,
      },
    });

    console.log("Subscription created:", JSON.stringify(subscription, null, 2));

    // Check if we have a payment intent
    if (subscription.latest_invoice?.payment_intent) {
      return {
        subscriptionId: subscription.id,
        clientSecret: subscription.latest_invoice.payment_intent.client_secret,
        customerId: customerId,
      };
    }

    // If no payment intent was created, create one
    const paymentIntent = await stripe.paymentIntents.create({
      amount: subscription.items.data[0].price.unit_amount,
      currency: subscription.currency,
      customer: customerId,
      setup_future_usage: "off_session",
      automatic_payment_methods: {
        enabled: true,
      },
    });

    return {
      subscriptionId: subscription.id,
      clientSecret: paymentIntent.client_secret,
      customerId: customerId,
    };
  } catch (error) {
    console.error("Error in createSubscription:", error);
    throw error;
  }
};

export const getSubscription = async (subscriptionId) => {
  console.log(`Getting subscription details for: ${subscriptionId}`);
  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  return subscription;
};

export const handleWebhookEvent = async (payload, signature) => {
  console.log("Handling webhook event...");
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  const event = stripe.webhooks.constructEvent(
    payload,
    signature,
    webhookSecret
  );

  // Handle the event based on its type
  if (
    event.type === "customer.subscription.created" ||
    event.type === "customer.subscription.updated"
  ) {
    const subscription = event.data.object;
    return {
      type: "subscription_update",
      data: {
        subscriptionId: subscription.id,
        customerId: subscription.customer,
        status: subscription.status,
        planId: subscription.items.data[0].price.id,
        currentPeriodEnd: new Date(subscription.current_period_end * 1000),
      },
    };
  }

  if (event.type === "payment_intent.succeeded") {
    const paymentIntent = event.data.object;
    return {
      type: "payment_success",
      data: {
        paymentIntentId: paymentIntent.id,
        customerId: paymentIntent.customer,
        amount: paymentIntent.amount,
        currency: paymentIntent.currency,
      },
    };
  }

  return {
    type: "other",
    data: event.data.object,
  };
};
