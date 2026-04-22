/**
 * migrar_usuario.js
 * Migra o documento do usuário do UID antigo para o UID correto no Firestore.
 * Também migra a subcoleção "vehicles" se existir.
 *
 * Como rodar:
 *   node migrar_usuario.js
 */
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
// ─── CONFIGURAÇÃO ────────────────────────────────────────────────────────────
const UID_ANTIGO = 'JRwLnA9ZfqSDkJxqcqINKGWJ8293'; // documento com os dados corretos
const UID_NOVO   = 'YNG6jLT6RhYMTUKcGwAtiCprF4U2'; // UID real do Firebase Auth
// ─────────────────────────────────────────────────────────────────────────────
async function migrar() {
  console.log('Iniciando migracao...\n');
  // 1. Lê o documento antigo
  const docAntigo = await db.collection('users').doc(UID_ANTIGO).get();
  if (!docAntigo.exists) {
    console.error(`ERRO: Documento ${UID_ANTIGO} nao encontrado.`);
    process.exit(1);
  }
  const dados = docAntigo.data();
  console.log('Dados encontrados no documento antigo:');
  console.log(JSON.stringify(dados, null, 2));
  // 2. Verifica se o documento novo já tem dados
  const docNovo = await db.collection('users').doc(UID_NOVO).get();
  if (docNovo.exists && docNovo.data() && Object.keys(docNovo.data()).length > 0) {
    console.warn(`\nAVISO: Documento ${UID_NOVO} ja possui dados:`);
    console.warn(JSON.stringify(docNovo.data(), null, 2));
    console.warn('Abortando para nao sobrescrever. Verifique manualmente.');
    process.exit(1);
  }
  const batch = db.batch();
  // 3. Grava os dados no documento com o UID correto
  batch.set(db.collection('users').doc(UID_NOVO), dados);
  console.log(`\nDocumento users/${UID_NOVO} preparado para gravacao.`);
  // 4. Migra subcoleção "vehicles" se existir
  const vehiclesSnap = await db
    .collection('users')
    .doc(UID_ANTIGO)
    .collection('vehicles')
    .get();
  if (!vehiclesSnap.empty) {
    console.log(`\nMigrando ${vehiclesSnap.size} veiculo(s)...`);
    for (const vDoc of vehiclesSnap.docs) {
      const destRef = db
        .collection('users')
        .doc(UID_NOVO)
        .collection('vehicles')
        .doc(vDoc.id);
      batch.set(destRef, vDoc.data());
      console.log(`  Veiculo ${vDoc.id} preparado.`);
    }
  } else {
    console.log('\nNenhum veiculo encontrado no documento antigo.');
  }
  // 5. Exclui o documento antigo
  batch.delete(db.collection('users').doc(UID_ANTIGO));
  console.log(`\nDocumento antigo users/${UID_ANTIGO} marcado para exclusao.`);
  // 6. Confirma tudo de uma vez
  await batch.commit();
  console.log('\nMigracao concluida com sucesso!');
  console.log(`Dados agora em: users/${UID_NOVO}`);
  process.exit(0);
}
migrar().catch((err) => {
  console.error('Erro inesperado:', err);
  process.exit(1);
});
