const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const OLD_EMAIL = 'alexsalles.uberbraga@gail.com';
const NEW_EMAIL = 'alexsalles.uberbraga@gmail.com'; // ← substitua antes de rodar
async function main() {
  if (NEW_EMAIL === 'SEU_EMAIL_REAL_AQUI') {
    console.error('❌ Substitua SEU_EMAIL_REAL_AQUI pelo seu email real antes de rodar.');
    process.exit(1);
  }
  const user = await admin.auth().getUserByEmail(OLD_EMAIL);
  await admin.auth().updateUser(user.uid, { email: NEW_EMAIL });
  console.log(`✅ Email atualizado com sucesso!`);
  console.log(`   UID : ${user.uid}`);
  console.log(`   De  : ${OLD_EMAIL}`);
  console.log(`   Para: ${NEW_EMAIL}`);
  process.exit(0);
}
main().catch((e) => {
  console.error('Erro:', e.message);
  process.exit(1);
});
