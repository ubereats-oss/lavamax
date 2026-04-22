/**
 * seed_services_catalog.js
 * Popula (ou atualiza) os serviços do catálogo no Firestore com
 * description e icon_emoji. Não duplica — usa o nome como chave de busca.
 *
 * Como rodar:
 *   node seed_services_catalog.js
 */
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const SERVICES = [
  {
    name: 'PPF – Paint Protection Film',
    description: 'Film de proteção de alta resistência e tecnologia de ponta que protege e conserva a pintura, faróis, lanternas e vidros dos carros.',
    icon_emoji: '🛡️',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
  {
    name: 'Vitrificação de Pintura',
    description: 'Revestimento cerâmico de alta resistência e tecnologia de ponta que protege e conserva a pintura, faróis, lanternas, plásticos, couro e vidros dos carros.',
    icon_emoji: '✨',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
  {
    name: 'Lavagem Premium',
    description: 'Lavagens de alta qualidade com o carinho e o mimo que seu carro merece.',
    icon_emoji: '🚿',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
  {
    name: 'Polimentos Técnicos',
    description: 'Conseguimos extrair o melhor em brilho e proteção para a pintura do seu carro.',
    icon_emoji: '💎',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
  {
    name: 'Higienizações Diversas',
    description: 'O interior do seu carro limpo, cheiroso e livre de fungos, ácaros, bactérias e maus odores.',
    icon_emoji: '🧹',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
  {
    name: 'Aplicações de Películas',
    description: 'As melhores películas do mercado com 5 anos de garantia, na cor e na tonalidade que você precisa.',
    icon_emoji: '🎞️',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
  {
    name: 'Limpeza Técnica de Motor',
    description: 'Serviço preventivo e detalhado, feito totalmente a seco, com aplicação de anti-ferrugem nas peças metálicas, hidratação das borrachas e tratamento da pintura interna do motor.',
    icon_emoji: '⚙️',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
  {
    name: 'Restauração de Faróis',
    description: 'Recuperação da transparência dos seus faróis, remoção de manchas, arranhões e amarelamento.',
    icon_emoji: '💡',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
  {
    name: 'Martelinho de Ouro',
    description: 'Repintar, só se não tiver jeito. Existem danos que são corrigidos sem a necessidade de repintura.',
    icon_emoji: '🔨',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
  {
    name: 'Funilaria e Pintura',
    description: 'Serviços rápidos para pequenos danos de funilaria e pintura com produtos de alta tecnologia.',
    icon_emoji: '🎨',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
  {
    name: 'Pintura e Desempeno de Rodas',
    description: 'As rodas são o charme de cada carro. Bem cuidadas e na cor certa.',
    icon_emoji: '🔧',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
  {
    name: 'Customização',
    description: 'Quer um carro único para você? Nós te ajudamos na cor das rodas, mascaramento e muito mais.',
    icon_emoji: '⭐',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
  {
    name: 'Home Car Detail – Condomínios',
    description: 'Serviço de estética automotiva de alta qualidade dentro do seu próprio condomínio. Com a Lavamax é possível.',
    icon_emoji: '🏠',
    price: 0,
    duration_minutes: 60,
    is_active: true,
  },
];
async function seed() {
  console.log('Iniciando seed de serviços...\n');
  // Lê todos os serviços existentes para não duplicar
  const existingSnap = await db.collection('services').get();
  const existingByName = {};
  for (const doc of existingSnap.docs) {
    const name = doc.data().name;
    if (name) existingByName[name] = doc.id;
  }
  const batch = db.batch();
  let created = 0;
  let updated = 0;
  for (const svc of SERVICES) {
    const existingId = existingByName[svc.name];
    if (existingId) {
      // Atualiza apenas description e icon_emoji (preserva price, duration, etc.)
      const ref = db.collection('services').doc(existingId);
      batch.update(ref, {
        description: svc.description,
        icon_emoji: svc.icon_emoji,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`  Atualizando: ${svc.name}`);
      updated++;
    } else {
      // Cria novo
      const ref = db.collection('services').doc();
      batch.set(ref, {
        ...svc,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`  Criando: ${svc.name}`);
      created++;
    }
  }
  await batch.commit();
  console.log(`\nConcluído! ${created} criado(s), ${updated} atualizado(s).`);
  process.exit(0);
}
seed().catch((err) => {
  console.error('Erro:', err);
  process.exit(1);
});
