const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');
// ─── EDITE AQUI ───────────────────────────────────────────────
const IDENTIFIER = '63088827553'; // username, CPF ou telefone
const IDENTIFIER_TYPE = 'cpf';    // 'username' | 'cpf' | 'phone'
// ─────────────────────────────────────────────────────────────
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
const auth = admin.auth();
function buildFakeEmail(identifier, type) {
  let sanitized;
  if (type === 'cpf' || type === 'phone') {
    sanitized = identifier.replace(/[^0-9]/g, '');
  } else {
    sanitized = identifier.trim().toLowerCase().replace(/ /g, '_');
  }
  return `${sanitized}@lavamax.app`;
}
async function promoveMaster() {
  const fakeEmail = buildFakeEmail(IDENTIFIER, IDENTIFIER_TYPE);
  console.log(`Buscando usuario com e-mail ficticio: ${fakeEmail}`);
  const userRecord = await auth.getUserByEmail(fakeEmail);
  const uid = userRecord.uid;
  await db.collection('users').doc(uid).set(
    { role: 'master' },
    { merge: true }
  );
  console.log(`✅ Usuario "${IDENTIFIER}" (uid: ${uid}) promovido para master.`);
  process.exit(0);
}
promoveMaster().catch((err) => {
  console.error('Erro:', err.message);
  process.exit(1);
});
//**Para usar o script:**
//1. Edite `IDENTIFIER` com o username/CPF/telefone que você cadastrou no app
//2. Edite `IDENTIFIER_TYPE` com o tipo correspondente
//3. Rode:
//```
//node seed_master.js
