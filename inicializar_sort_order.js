const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Ordem exata conforme lavamaxstudiocar.com.br
const ORDER = [
  'PPF – Paint Protection Film',
  'Vitrificação de Pintura',
  'Limpeza Técnica de Motor',
  'Restauração de Faróis',
  'Customização',
  'Funilaria e Pintura',
  'Martelinho de Ouro',
  'Pintura e Desempeno de Rodas',
  'Aplicações de Películas',
  'Higienizações Diversas',
  'Polimentos Técnicos',
  'Lavagem Premium',
  'Home Car Detail – Condomínios',
];

async function main() {
  const snap = await db.collection('services').get();

  if (snap.empty) {
    console.log('Nenhum serviço encontrado.');
    return;
  }

  let atualizados = 0;
  let semMatch = [];

  for (const doc of snap.docs) {
    const nome = doc.data().name ?? '';
    const idx = ORDER.indexOf(nome);

    if (idx === -1) {
      semMatch.push(`  [${doc.id}] "${nome}" — não encontrado na lista`);
      continue;
    }

    const sortOrder = idx + 1; // 1-based
    await doc.ref.update({ sort_order: sortOrder });
    console.log(`✓ ${String(sortOrder).padStart(2, '0')}. "${nome}"`);
    atualizados++;
  }

  console.log(`\nConcluído: ${atualizados} serviço(s) atualizado(s).`);

  if (semMatch.length > 0) {
    console.log(`\nAtenção — ${semMatch.length} serviço(s) sem correspondência (sort_order não alterado):`);
    semMatch.forEach(l => console.log(l));
  }
}

main().catch(console.error);
