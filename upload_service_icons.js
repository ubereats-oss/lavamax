const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'lavamaxapp.firebasestorage.app'
});
const bucket = admin.storage().bucket();
const ICONS_FOLDER = './assets/images/services'; // pasta local com os PNG
async function uploadIcons() {
  const files = fs.readdirSync(ICONS_FOLDER);
  for (const file of files) {
    const filePath = path.join(ICONS_FOLDER, file);
    const destination = `services/icons/${file}`;
    const [uploadedFile] = await bucket.upload(filePath, {
      destination,
      metadata: {
        metadata: {
          firebaseStorageDownloadTokens: require('uuid').v4()
        }
      }
    });
    const token = uploadedFile.metadata.metadata.firebaseStorageDownloadTokens;
    const url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(destination)}?alt=media&token=${token}`;
    console.log(`${file} → ${url}`);
  }
}
uploadIcons();
