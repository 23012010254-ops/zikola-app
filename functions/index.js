/**
 * Zikola Firebase Cloud Functions - Midtrans Payment Gateway Backend Integration
 * 
 * Instructions:
 * 1. Install dependencies: `npm install firebase-functions firebase-admin midtrans-client crypto`
 * 2. Set environment secrets or configuration:
 *    firebase functions:config:set midtrans.server_key="YOUR_MIDTRANS_SERVER_KEY" midtrans.is_production="false"
 * 3. Deploy functions: `firebase deploy --only functions`
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const midtransClient = require("midtrans-client");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

// Retrieve Midtrans Configuration (Set via firebase config or process.env)
const MIDTRANS_SERVER_KEY = process.env.MIDTRANS_SERVER_KEY || "SB-Mid-server-YOUR-SANDBOX-KEY";
const IS_PRODUCTION = process.env.MIDTRANS_IS_PRODUCTION === "true";

// Initialize Midtrans Snap client
const snap = new midtransClient.Snap({
  isProduction: IS_PRODUCTION,
  serverKey: MIDTRANS_SERVER_KEY,
});

/**
 * 1. HTTPS Function: createSnapTransaction
 * Called by Flutter app to generate a secure Snap Token & Redirect URL
 */
exports.createSnapTransaction = functions.https.onRequest(async (req, res) => {
  // Enable CORS for web/mobile requests
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  try {
    const { orderId, amount, userId, doctorId, doctorName, paymentMethod } = req.body;

    if (!orderId || !amount || !userId) {
      return res.status(400).json({ error: "Missing required fields: orderId, amount, userId" });
    }

    const parameter = {
      transaction_details: {
        order_id: orderId,
        gross_amount: Number(amount),
      },
      item_details: [
        {
          id: doctorId || "DOC-CONSULTATION",
          price: Number(amount) - 2500,
          quantity: 1,
          name: `Konsultasi Dokter: ${doctorName || "Zikola Specialist"}`,
        },
        {
          id: "FEE-ADMIN",
          price: 2500,
          quantity: 1,
          name: "Biaya Layanan & Admin Zikola",
        },
      ],
      customer_details: {
        first_name: "Pasien / Orang Tua",
        user_id: userId,
      },
    };

    if (paymentMethod) {
      parameter.enabled_payments = [paymentMethod];
    }

    // Call Midtrans Snap API
    const transaction = await snap.createTransaction(parameter);

    // Record pending transaction in Firestore
    await db.collection("payments").doc(orderId).set({
      orderId,
      userId,
      doctorId: doctorId || "doc_default",
      amount: Number(amount),
      paymentMethod: paymentMethod || "gopay",
      status: "pending",
      snapToken: transaction.token,
      redirectUrl: transaction.redirect_url,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).json({
      success: true,
      orderId,
      snap_token: transaction.token,
      redirect_url: transaction.redirect_url,
    });
  } catch (error) {
    console.error("Error creating Midtrans transaction:", error);
    return res.status(500).json({ error: error.message || "Failed to create payment session" });
  }
});

/**
 * 2. HTTPS Webhook Function: midtransWebhook
 * Midtrans calls this HTTP POST notification URL when payment status changes (Settlement/Cancel/Expire)
 */
exports.midtransWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  try {
    const notification = req.body;
    const { order_id, status_code, gross_amount, signature_key, transaction_status, fraud_status } = notification;

    // Verify Midtrans Signature Key (order_id + status_code + gross_amount + ServerKey)
    const rawSignature = `${order_id}${status_code}${gross_amount}${MIDTRANS_SERVER_KEY}`;
    const expectedSignature = crypto.createHash("sha512").update(rawSignature).digest("hex");

    if (signature_key !== expectedSignature) {
      console.warn("Invalid Midtrans Webhook Signature!");
      return res.status(403).json({ error: "Invalid Signature Hash" });
    }

    let finalStatus = "pending";

    if (transaction_status === "capture") {
      finalStatus = fraud_status === "challenge" ? "challenge" : "settlement";
    } else if (transaction_status === "settlement") {
      finalStatus = "settlement";
    } else if (transaction_status === "cancel" || transaction_status === "deny" || transaction_status === "expire") {
      finalStatus = "failed";
    } else if (transaction_status === "pending") {
      finalStatus = "pending";
    }

    // Update payment record in Firestore
    const paymentRef = db.collection("payments").doc(order_id);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      console.warn(`Payment record for orderId ${order_id} not found.`);
      return res.status(404).json({ error: "Order not found" });
    }

    await paymentRef.update({
      status: finalStatus,
      rawMidtransStatus: transaction_status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      paidAt: finalStatus === "settlement" ? admin.firestore.FieldValue.serverTimestamp() : null,
    });

    console.log(`Payment status for order ${order_id} updated to ${finalStatus}`);
    return res.status(200).json({ status: "OK", orderId: order_id, paymentStatus: finalStatus });
  } catch (error) {
    console.error("Error processing Midtrans webhook:", error);
    return res.status(500).json({ error: error.message });
  }
});
