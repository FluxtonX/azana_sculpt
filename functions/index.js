const functions = require("firebase-functions");
const stripe = require("stripe");

// Define Stripe Secret Key
const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY || "";

exports.createStripePaymentIntent = functions.https.onRequest(
  async (req, res) => {
    // Set CORS headers
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      const body = req.body && req.body.data ? req.body.data : (req.body || {});
      const amount = body.amount;
      const currency = body.currency || "gbp";

      if (!amount || !currency) {
        res.status(400).json({ error: "Amount and currency are required." });
        return;
      }

      // Initialize Stripe
      const stripeInstance = stripe(STRIPE_SECRET_KEY);

      // Create PaymentIntent
      const paymentIntent = await stripeInstance.paymentIntents.create({
        amount: parseInt(amount, 10),
        currency: currency.toLowerCase(),
        payment_method_types: ["card"],
      });

      res.status(200).json({
        client_secret: paymentIntent.client_secret,
        data: {
          client_secret: paymentIntent.client_secret,
        },
      });
    } catch (error) {
      console.error("Stripe error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);
