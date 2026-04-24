/**
 * fix_services.js
 * Corrige icon_url (chave do sprite) e sort_order de todos os serviços,
 * na ordem exata do site lavamaxstudiocar.com.br.
 * Cria serviços ausentes; desativa serviços fora da lista.
 *
 * Como rodar:
 *   node fix_services.js
 */
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// Ordem e dados conforme lavamaxstudiocar.com.br (verificado em 2026-04-23)
const SERVICES = [
  {
    sort_order: 1,
    name: 'Vitrificação de Pintura',
    icon_url: 'vitrificacao',
    description: 'Revestimento cerâmico de alta resistência e tecnologia de ponta que protege e conserva a pintura, faróis, lanternas, plásticos, couro e vidros dos carros.',
  },
  {
    sort_order: 2,
    name: 'PPF – Paint Protection Film',
    icon_url: 'ppf',
    description: 'Film de proteção de alta resistência e tecnologia de ponta que protege e conserva a pintura, faróis, lanternas e vidros dos carros.',
  },
  {
    sort_order: 3,
    name: 'Higienizações Diversas',
    icon_url: 'higienizacao',
    description: 'O interior do seu carro limpo, cheiroso e livre de fungos, ácaros, bactérias e maus odores.',
  },
  {
    sort_order: 4,
    name: 'Polimentos Técnicos',
    icon_url: 'polimentos',
    description: 'Conseguimos extrair o melhor em brilho e proteção para a pintura do seu carro.',
  },
  {
    sort_order: 5,
    name: 'Lavagem Premium',
    icon_url: 'lavagem_premium',
    description: 'Lavagens de alta qualidade com o carinho e o mimo que seu carro merece.',
  },
  {
    sort_order: 6,
    name: 'Funilaria e Pintura',
    icon_url: 'funilaria',
    description: 'Serviços rápidos para pequenos danos de funilaria e pintura com produtos de alta tecnologia.',
  },
  {
    sort_order: 7,
    name: 'Aplicações de Películas',
    icon_url: 'peliculas',
    description: 'As melhores películas do mercado com 5 anos de garantia, na cor e na tonalidade que você precisa.',
  },
  {
    sort_order: 8,
    name: 'Customização',
    icon_url: 'customizacao',
    description: 'Quer um carro único para você? Nós te ajudamos na cor das rodas, mascaramento e muito mais.',
  },
  {
    sort_order: 9,
    name: 'Limpeza Técnica de Motor',
    icon_url: 'limpeza_motor',
    description: 'Serviço preventivo e detalhado, feito totalmente a seco, com aplicação de anti-ferrugem nas peças metálicas, hidratação das borrachas e tratamento da pintura interna do motor.',
  },
  {
    sort_order: 10,
    name: 'Martelinho de Ouro',
    icon_url: 'martelinho',
    description: 'Repintar, só se não tiver jeito. Existem danos que são corrigidos sem a necessidade de repintura.',
  },
  {
    sort_order: 11,
    name: 'Pintura e Desempeno de Rodas',
    icon_url: 'rodas',
    description: 'As rodas são o charme de cada carro. Bem cuidadas e na cor certa.',
  },
  {
    sort_order: 12,
    name: 'Restauração de Faróis',
    icon_url: 'restauracao_farois',
    description: 'Recuperação da transparência dos seus faróis, remoção de manchas, arranhões e amarelamento.',
  },
  {
    sort_order: 13,
    name: 'Home Car Detail – Condomínios',
    icon_url: 'home_car_detail',
    description: 'Serviço de estética automotiva de alta qualidade dentro do seu próprio condomínio. Com a Lavamax é possível.',
  },
];

async function main() {
  console.log('Buscando serviços no Firestore...\n');
  const snap = await db.collection('services').get();

  // Índice por nome para encontrar docs existentes
  const byName = {};
  for (const doc of snap.docs) {
    const name = (doc.data().name ?? '').trim();
    byName[name] = { id: doc.id, data: doc.data() };
  }

  const correctNames = new Set(SERVICES.map(s => s.name));
  const batch = db.batch();
  let criados = 0;
  let atualizados = 0;
  let desativados = 0;

  // Atualiza ou cria cada serviço da lista
  for (const svc of SERVICES) {
    const existing = byName[svc.name];
    if (existing) {
      const ref = db.collection('services').doc(existing.id);
      batch.update(ref, {
        sort_order: svc.sort_order,
        icon_url: svc.icon_url,
        description: svc.description,
        is_active: true,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`  ✓ Atualizando [${svc.sort_order.toString().padStart(2, '0')}] ${svc.name}  →  icon_url="${svc.icon_url}"`);
      atualizados++;
    } else {
      const ref = db.collection('services').doc();
      batch.set(ref, {
        sort_order: svc.sort_order,
        name: svc.name,
        icon_url: svc.icon_url,
        description: svc.description,
        price: 0,
        duration_minutes: 60,
        is_active: true,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`  + Criando    [${svc.sort_order.toString().padStart(2, '0')}] ${svc.name}`);
      criados++;
    }
  }

  // Desativa serviços que não estão na lista
  for (const doc of snap.docs) {
    const name = (doc.data().name ?? '').trim();
    if (!correctNames.has(name)) {
      const ref = db.collection('services').doc(doc.id);
      batch.update(ref, {
        is_active: false,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`  ✗ Desativando: "${name}" (não está na lista do site)`);
      desativados++;
    }
  }

  await batch.commit();
  console.log(`\nConcluído! ${atualizados} atualizado(s), ${criados} criado(s), ${desativados} desativado(s).`);
  process.exit(0);
}

main().catch(err => {
  console.error('Erro:', err);
  process.exit(1);
});
