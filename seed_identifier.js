const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
async function main() {
  // Busca todos os usuários e cria entradas em identifiers
  const snap = await db.collection('users').get();
  let count = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    const identifier = data['identifier'];
    const email = data['email'];
    const identifierType = data['identifier_type'] ?? 'username';
    if (!identifier || !email) {
      console.log(`⚠️  Ignorado (sem identifier ou email): ${doc.id}`);
      continue;
    }
    const key = identifier.trim().toLowerCase();
    await db.collection('identifiers').doc(key).set({
      email: email,
      identifier_type: identifierType,
    });
    console.log(`✅ ${key} → ${email}`);
    count++;
  }
  console.log(`\nConcluido: ${count} entrada(s) criada(s) em identifiers.`);
  process.exit(0);
}
main().catch((e) => {
  console.error('Erro:', e.message);
  process.exit(1);
});
