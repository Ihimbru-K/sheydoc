/**
 * Cloud Functions for SheyDoc - MeSomb Payment Integration
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const crypto = require('crypto');

admin.initializeApp();

// Load environment variables
require('dotenv').config();

const MESOMB_APP_KEY = process.env.MESOMB_APP_KEY;
const MESOMB_ACCESS_KEY = process.env.MESOMB_ACCESS_KEY;
const MESOMB_SECRET_KEY = process.env.MESOMB_SECRET_KEY;

/**
 * Generate random nonce
 */
function generateNonce() {
  return crypto.randomBytes(16).toString('hex');
}

/**
 * Generate HMAC signature
 */
function generateSignature(method, endpoint, timestamp, nonce, body = '') {
  const message = `${method}\n${endpoint}\n${timestamp}\n${nonce}\n${body}`;
  return crypto
      .createHmac('sha1', MESOMB_SECRET_KEY)
      .update(message)
      .digest('hex');
}

/**
 * Initialize payment
 */
exports.initializePayment = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be logged in',
      );
    }

    const {doctorId, date, time, amount, service, payer} = data;
    const userId = context.auth.uid;

    if (!doctorId || !date || !time || !amount || !service || !payer) {
      throw new functions.https.HttpsError(
          'invalid-argument',
          'Missing required fields',
      );
    }

    if (!['MTN', 'ORANGE'].includes(service)) {
      throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid service type',
      );
    }

    const phoneRegex = /^6[0-9]{8}$/;
    if (!phoneRegex.test(payer)) {
      throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid phone number format',
      );
    }

    if (amount < 100 || amount > 1000000) {
      throw new functions.https.HttpsError(
          'invalid-argument',
          'Amount must be between 100 and 1,000,000 FCFA',
      );
    }

    const doctorDoc = await admin.firestore()
        .collection('users')
        .doc(doctorId)
        .get();

    if (!doctorDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Doctor not found');
    }

    const doctorData = doctorDoc.data();
    if (amount !== doctorData.baseFee) {
      throw new functions.https.HttpsError(
          'invalid-argument',
          'Amount does not match doctor fee',
      );
    }

    const appointmentRef = await admin.firestore()
        .collection('appointments')
        .add({
          userId,
          doctorId,
          date: admin.firestore.Timestamp.fromDate(new Date(date)),
          time,
          amount,
          service,
          payer,
          status: 'pending_payment',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          paymentStatus: 'initiated',
        });

    const endpoint = '/payment/collect/v1/';
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const nonce = generateNonce();

    const requestBody = {
      amount,
      service,
      payer,
      nonce,
      trxID: appointmentRef.id,
      country: 'CM',
      currency: 'XAF',
    };

    const signature = generateSignature(
        'POST',
        endpoint,
        timestamp,
        nonce,
        JSON.stringify(requestBody),
    );

    const response = await axios.post(
        `https://mesomb.hachther.com${endpoint}`,
        requestBody,
        {
          headers: {
            'X-MeSomb-Application': MESOMB_APP_KEY,
            'X-MeSomb-Access': MESOMB_ACCESS_KEY,
            'X-MeSomb-Timestamp': timestamp,
            'X-MeSomb-Nonce': nonce,
            'X-MeSomb-Signature': signature,
            'Content-Type': 'application/json',
          },
          timeout: 60000,
        },
    );

    await appointmentRef.update({
      mesombTransactionId: response.data.reference,
      mesombResponse: response.data,
      paymentStatus: 'processing',
    });

    return {
      success: true,
      appointmentId: appointmentRef.id,
      transactionId: response.data.reference,
      message: 'Payment initiated. Please check your phone to confirm.',
    };
  } catch (error) {
    console.error('Payment initialization error:', error);

    if (error.response && error.response.data) {
      throw new functions.https.HttpsError(
          'internal',
          error.response.data.message || 'Payment failed',
          error.response.data,
      );
    }

    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Check payment status
 */
exports.checkPaymentStatus = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be logged in',
      );
    }

    const {appointmentId} = data;
    const userId = context.auth.uid;

    const appointmentDoc = await admin.firestore()
        .collection('appointments')
        .doc(appointmentId)
        .get();

    if (!appointmentDoc.exists) {
      throw new functions.https.HttpsError(
          'not-found',
          'Appointment not found',
      );
    }

    const appointment = appointmentDoc.data();

    if (appointment.userId !== userId) {
      throw new functions.https.HttpsError(
          'permission-denied',
          'Unauthorized',
      );
    }

    if (appointment.paymentStatus === 'completed') {
      return {
        status: 'completed',
        appointmentId,
      };
    }

    const transactionId = appointment.mesombTransactionId;
    const endpoint = `/payment/transactions/${transactionId}/`;
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const nonce = generateNonce();
    const signature = generateSignature('GET', endpoint, timestamp, nonce);

    const response = await axios.get(
        `https://mesomb.hachther.com${endpoint}`,
        {
          headers: {
            'X-MeSomb-Application': MESOMB_APP_KEY,
            'X-MeSomb-Access': MESOMB_ACCESS_KEY,
            'X-MeSomb-Timestamp': timestamp,
            'X-MeSomb-Nonce': nonce,
            'X-MeSomb-Signature': signature,
          },
        },
    );

    const transactionStatus = response.data.status;

    if (transactionStatus === 'SUCCESS') {
      await appointmentDoc.ref.update({
        paymentStatus: 'completed',
        status: 'confirmed',
        confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        status: 'completed',
        appointmentId,
      };
    } else if (transactionStatus === 'FAILED') {
      await appointmentDoc.ref.update({
        paymentStatus: 'failed',
        status: 'cancelled',
      });

      return {
        status: 'failed',
        message: 'Payment failed',
      };
    }

    return {
      status: 'processing',
      message: 'Payment is still processing',
    };
  } catch (error) {
    console.error('Status check error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Webhook handler
 */
exports.mesombWebhook = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    const signature = req.headers['x-mesomb-signature'];
    const computedSignature = crypto
        .createHmac('sha1', MESOMB_SECRET_KEY)
        .update(JSON.stringify(req.body))
        .digest('hex');

    if (signature !== computedSignature) {
      res.status(401).send('Invalid signature');
      return;
    }

    const {status, trxID} = req.body;

    const appointmentRef = admin.firestore()
        .collection('appointments')
        .doc(trxID);
    const appointmentDoc = await appointmentRef.get();

    if (!appointmentDoc.exists) {
      res.status(404).send('Appointment not found');
      return;
    }

    if (status === 'SUCCESS') {
      await appointmentRef.update({
        paymentStatus: 'completed',
        status: 'confirmed',
        confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
        webhookReceived: true,
      });
    } else if (status === 'FAILED') {
      await appointmentRef.update({
        paymentStatus: 'failed',
        status: 'cancelled',
        webhookReceived: true,
      });
    }

    res.status(200).send('OK');
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).send('Internal error');
  }
});