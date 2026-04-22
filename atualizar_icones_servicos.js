const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Mapeamento corrigido com os nomes exatos do Firestore
const ICON_MAP = {
  // Já atualizados (serão ignorados pois icon_url já está correto,
  // mas manter aqui não causa problema — update é idempotente)
  'Customização':                   'customizacao',
  'Restauração de Faróis':          'restauracao_farois',
  'Martelinho de Ouro':             'martelinho',
  'Lavagem Premium':                'lavagem_premium',
  // Corrigidos agora
  'Funilaria e Pintura':            'funilaria',
  'Home Car Detail – Condomínios':  'home_car_detail',
  'Polimentos Técnicos':            'polimentos',
  'Vitrificação de Pintura':        'vitrificacao',
  'Aplicações de Películas':        'peliculas',
  'Pintura e Desempeno de Rodas':   'rodas',
  'Higienizações Diversas':         'higienizacao',
  'PPF – Paint Protection Film':    'ppf',
  'Limpeza Técnica de Motor':       'limpeza_motor',
};

async function main() {
  const snap = await db.collection('services').get();

  if (snap.empty) {
    console.log('Nenhum serviço encontrado na coleção services.');
    return;
  }

  let atualizados = 0;
  let semMatch = [];

  for (const doc of snap.docs) {
    const nome = doc.data().name ?? '';
    const chave = ICON_MAP[nome];

    if (!chave) {
      semMatch.push(`  [${doc.id}] "${nome}" — sem correspondência no mapeamento`);
      continue;
    }

    await doc.ref.update({ icon_url: chave });
    console.log(`✓ "${nome}" → icon_url = "${chave}"`);
    atualizados++;
  }

  console.log(`\nConcluído: ${atualizados} serviço(s) atualizado(s).`);

  if (semMatch.length > 0) {
    console.log(`\nAtenção — ${semMatch.length} serviço(s) sem correspondência:`);
    semMatch.forEach(l => console.log(l));
  }
}

main().catch(console.error);
