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

export const handleWebhookEvent = async (payload, signature) => {
  console.log("Handling webhook event...");
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  const event = stripe.webhooks.constructEvent(
    payload,
    signature,
    webhookSecret
  );
  return event;
};
