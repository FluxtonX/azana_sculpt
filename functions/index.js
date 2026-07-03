const functions = require("firebase-functions");
const stripe = require("stripe");

// Define a Secret from Secret Manager
const stripeSecret = process.env.STRIPE_SECRET_KEY;

exports.createStripePaymentIntent = functions
  .https.onCall(async (data, context) => {
    // Basic authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be logged in to create a payment intent."
      );
    }

    const amount = data.amount;
    const currency = data.currency;

    if (!amount || !currency) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Amount and currency must be provided."
      );
    }

    try {
      // Initialize Stripe with the secret key retrieved from Secret Manager
      const stripeInstance = stripe(process.env.STRIPE_SECRET_KEY);

      // Create a PaymentIntent with the order amount and currency
      const paymentIntent = await stripeInstance.paymentIntents.create({
        amount: parseInt(amount, 10),
        currency: currency.toLowerCase(),
        payment_method_types: ["card"],
      });

      return {
        client_secret: paymentIntent.client_secret,
      };
    } catch (error) {
      console.error("Stripe error:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  });
