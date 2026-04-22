// seed_firestore.js
// Popula as coleções 'services' e 'branches' no Firestore.
//
// COMO USAR:
//   1. Coloque este arquivo na pasta raiz do projeto lavamax (junto com pubspec.yaml)
//   2. Baixe a chave de serviço do Firebase Console:
//      Firebase Console → Configurações do projeto → Contas de serviço → Gerar nova chave privada
//      Salve o arquivo como serviceAccountKey.json na mesma pasta deste script
//   3. No cmd, na pasta do projeto, rode:
//      npm init -y
//      npm install firebase-admin
//      node seed_firestore.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
// ─── SERVIÇOS ────────────────────────────────────────────────────────────────
// Preços e durações são provisórios — edite direto no Firestore depois.
const services = [
  { name: 'Espelhamento de Pintura',         category: 'Pintura',    price: 0.00, duration_minutes: 60 },
  { name: 'Lavagem Premium',                 category: 'Lavagem',    price: 0.00, duration_minutes: 60 },
  { name: 'Vitrificação de Pintura',         category: 'Pintura',    price: 0.00, duration_minutes: 120 },
  { name: 'Aspiração',                       category: 'Limpeza',    price: 0.00, duration_minutes: 30 },
  { name: 'Aplicação de PPF',                category: 'Proteção',   price: 0.00, duration_minutes: 120 },
  { name: 'Troca de Lanterna',               category: 'Elétrica',   price: 0.00, duration_minutes: 60 },
  { name: 'Troca de Farol',                  category: 'Elétrica',   price: 0.00, duration_minutes: 60 },
  { name: 'Aplicação de Frisos',             category: 'Estética',   price: 0.00, duration_minutes: 60 },
  { name: 'Limpeza Técnica de Motor',        category: 'Limpeza',    price: 0.00, duration_minutes: 90 },
  { name: 'Restauração de Faróis',           category: 'Elétrica',   price: 0.00, duration_minutes: 60 },
  { name: 'Aplicação de Películas',          category: 'Proteção',   price: 0.00, duration_minutes: 120 },
  { name: 'Higienização',                    category: 'Limpeza',    price: 0.00, duration_minutes: 60 },
  { name: 'Polimento Técnico',               category: 'Pintura',    price: 0.00, duration_minutes: 120 },
];
// ─── FILIAIS ─────────────────────────────────────────────────────────────────
// Endereços e telefones são placeholders — edite direto no Firestore depois.
const branches = [
  {
    name: "SAM's Club",
    address: 'Endereço a preencher',
    phone: '(71) 00000-0000',
    city: 'Salvador',
    state: 'BA',
    latitude: -12.9714,
    longitude: -38.5014,
  },
  {
    name: 'Porsche',
    address: 'Endereço a preencher',
    phone: '(71) 00000-0000',
    city: 'Salvador',
    state: 'BA',
    latitude: -12.9714,
    longitude: -38.5014,
  },
  {
    name: 'Audi',
    address: 'Endereço a preencher',
    phone: '(71) 00000-0000',
    city: 'Salvador',
    state: 'BA',
    latitude: -12.9714,
    longitude: -38.5014,
  },
  {
    name: 'BMW',
    address: 'Endereço a preencher',
    phone: '(71) 00000-0000',
    city: 'Salvador',
    state: 'BA',
    latitude: -12.9714,
    longitude: -38.5014,
  },
  {
    name: 'Ladeira da Montanha',
    address: 'Endereço a preencher',
    phone: '(71) 00000-0000',
    city: 'Salvador',
    state: 'BA',
    latitude: -12.9714,
    longitude: -38.5014,
  },
];
// ─── FUNÇÕES DE SEED ─────────────────────────────────────────────────────────
async function seedServices() {
  console.log('Gravando serviços...');
  const batch = db.batch();
  for (const service of services) {
    const ref = db.collection('services').doc();
    batch.set(ref, {
      ...service,
      is_active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`  ${services.length} serviços gravados.`);
}
async function seedBranches() {
  console.log('Gravando filiais...');
  const batch = db.batch();
  for (const branch of branches) {
    const ref = db.collection('branches').doc();
    batch.set(ref, {
      ...branch,
      is_active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`  ${branches.length} filiais gravadas.`);
}
async function main() {
  try {
    await seedServices();
    await seedBranches();
    console.log('\nSeed concluído com sucesso!');
    process.exit(0);
  } catch (err) {
    console.error('Erro durante o seed:', err);
    process.exit(1);
  }
}
main();
