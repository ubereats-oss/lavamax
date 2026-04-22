const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
async function main() {
  await db.collection('config').doc('credits').set(
    { max_credits_per_customer: 1 },
    { merge: true }
  );
  console.log('✅ config/credits criado com max_credits_per_customer: 1');
  process.exit(0);
}
main().catch((e) => {
  console.error('Erro:', e);
  process.exit(1);
});
