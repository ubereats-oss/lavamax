// seed_slots.js
// Gera slots para todas as filiais ativas no Firestore.
//
// Regras:
//   Segunda a sexta: 08h às 17h (último slot começa às 17h, termina às 18h)
//   Sábado:          08h às 11h (último slot começa às 11h, termina às 12h)
//   Domingo:         sem slots
//   Intervalo:       1 hora
//   Horizonte:       60 dias a partir de hoje
//
// COMO USAR:
//   (já deve ter rodado npm init -y e npm install firebase-admin)
//   node seed_slots.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
const DAYS_AHEAD      = 60;
const INTERVAL_HOURS  = 1;
// Retorna os pares [startHour, endHour] para um dado dia da semana (0=dom, 6=sab)
function getHoursForDay(dayOfWeek) {
  if (dayOfWeek === 0) return []; // domingo — sem slots
  if (dayOfWeek === 6) {
    // sábado: 08h às 12h
    const slots = [];
    for (let h = 8; h < 12; h += INTERVAL_HOURS) slots.push([h, h + INTERVAL_HOURS]);
    return slots;
  }
  // segunda a sexta: 08h às 18h
  const slots = [];
  for (let h = 8; h < 18; h += INTERVAL_HOURS) slots.push([h, h + INTERVAL_HOURS]);
  return slots;
}
async function seedSlots() {
  // Busca todas as filiais ativas
  const branchesSnap = await db.collection('branches').where('is_active', '==', true).get();
  if (branchesSnap.empty) {
    console.error('Nenhuma filial encontrada. Rode seed_firestore.js primeiro.');
    process.exit(1);
  }
  const branches = branchesSnap.docs.map(doc => ({ id: doc.id, name: doc.data().name }));
  console.log(`Filiais encontradas: ${branches.map(b => b.name).join(', ')}\n`);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  let totalSlots = 0;
  for (const branch of branches) {
    console.log(`Gerando slots para: ${branch.name}`);
    // Firestore permite no máximo 500 operações por batch
    let batch = db.batch();
    let batchCount = 0;
    for (let d = 0; d < DAYS_AHEAD; d++) {
      const date = new Date(today);
      date.setDate(today.getDate() + d);
      const dayOfWeek = date.getDay();
      const hourPairs = getHoursForDay(dayOfWeek);
      for (const [startH, endH] of hourPairs) {
        const startTime = new Date(date);
        startTime.setHours(startH, 0, 0, 0);
        const endTime = new Date(date);
        endTime.setHours(endH, 0, 0, 0);
        const ref = db.collection('slots').doc();
        batch.set(ref, {
          branch_id:    branch.id,
          start_time:   admin.firestore.Timestamp.fromDate(startTime),
          end_time:     admin.firestore.Timestamp.fromDate(endTime),
          is_available: true,
          appointment_id: null,
          created_at:   admin.firestore.FieldValue.serverTimestamp(),
          updated_at:   admin.firestore.FieldValue.serverTimestamp(),
        });
        batchCount++;
        totalSlots++;
        // Commit a cada 499 operações e abre novo batch
        if (batchCount === 499) {
          await batch.commit();
          batch = db.batch();
          batchCount = 0;
        }
      }
    }
    // Commit do restante
    if (batchCount > 0) {
      await batch.commit();
    }
    console.log(`  Slots gravados para ${branch.name}.`);
  }
  console.log(`\nSeed de slots concluído! Total: ${totalSlots} slots gravados.`);
}
seedSlots().catch(err => {
  console.error('Erro:', err);
  process.exit(1);
});
