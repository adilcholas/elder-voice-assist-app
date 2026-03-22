import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

export const notifyCaregivers = functions.firestore
  .onDocumentCreated("alerts/{alertId}", async (event) => {
    const snap = event.data;
    if (!snap) return;

    const alert = snap.data();
    if (!alert) return;

    const elderId = alert.elderId;
    const elderName = alert.elderName;
    const alertType = alert.alertType;
    const location = alert.location;

    // Get elder document
    const elderDoc = await db.collection("users").doc(elderId).get();
    if (!elderDoc.exists) return;

    const elderData = elderDoc.data();
    const caregiverIds = elderData?.caregiverIds || [];
    if (caregiverIds.length === 0) return;

    const tokens: string[] = [];
    // collect caregiver device tokens
    for (const caregiverId of caregiverIds) {
      const caregiverDoc = await db.collection("users")
        .doc(caregiverId)
        .get();

      const token = caregiverDoc.data()?.deviceToken;
      if (token) tokens.push(token);
    }

    if (tokens.length === 0) return;

    const payload = {
      data: {
        alertId: event.params.alertId,
        elderName: elderName,
        alertType: alertType,
        location: location,
      },
    };

    await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      data: payload.data,
    });
  });
