const { setGlobalOptions } = require('firebase-functions');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');
setGlobalOptions({ maxInstances: 10 });
initializeApp();
const db = getFirestore();
const DAYS_AHEAD     = 60;
const INTERVAL_HOURS = 1;
// Offset em horas para converter UTC → BRT (Brasília = UTC-3)
// Cloud Functions rodam em UTC; somamos 3h para obter o horário local correto.
const BRT_OFFSET_HOURS = 3;
/**
 * Gera os slots de um dia para uma filial.
 * [date] deve ser meia-noite no horário de Brasília (03:00 UTC).
 * Os timestamps gravados no Firestore representam BRT correto.
 */
function getSlotsForDay(date, branchId) {
  const dayOfWeek = date.getUTCDay(); // usa UTC para não depender do fuso local
  if (dayOfWeek === 0) return [];     // domingo — sem slots
  const slots = [];
  // seg-sex: 08–18 BRT | sábado: 08–12 BRT
  const startBRT = 8;
  const endBRT   = dayOfWeek === 6 ? 12 : 18;
  for (let h = startBRT; h < endBRT; h += INTERVAL_HOURS) {
    const startTime = new Date(date);
    // BRT hh:00 = UTC (hh + 3):00
    startTime.setUTCHours(h + BRT_OFFSET_HOURS, 0, 0, 0);
    const endTime = new Date(date);
    endTime.setUTCHours(h + BRT_OFFSET_HOURS + INTERVAL_HOURS, 0, 0, 0);
    slots.push({
      branch_id:      branchId,
      start_time:     Timestamp.fromDate(startTime),
      end_time:       Timestamp.fromDate(endTime),
      is_available:   true,
      appointment_id: null,
      created_at:     FieldValue.serverTimestamp(),
      updated_at:     FieldValue.serverTimestamp(),
    });
  }
  return slots;
}
// Dispara todo dia à meia-noite no horário de Brasília (UTC-3 = 03:00 UTC)
exports.gerarSlotsDiarios = onSchedule('0 3 * * *', async () => {
  // Meia-noite BRT = 03:00 UTC
  const now = new Date();
  const todayBRT = new Date();
  todayBRT.setUTCHours(3, 0, 0, 0); // 00:00 BRT de hoje
  const targetDate = new Date(todayBRT);
  targetDate.setUTCDate(todayBRT.getUTCDate() + DAYS_AHEAD);
  if (targetDate.getUTCDay() === 0) {
    console.log('Dia alvo é domingo — sem slots a gerar.');
    return;
  }
  const branchesSnap = await db
    .collection('branches')
    .where('is_active', '==', true)
    .get();
  if (branchesSnap.empty) {
    console.log('Nenhuma filial ativa encontrada.');
    return;
  }
  let totalGravados = 0;
  for (const branchDoc of branchesSnap.docs) {
    const branchId   = branchDoc.id;
    const branchName = branchDoc.data().name;
    // Janela do dia-alvo em BRT: de 03:00 UTC (00:00 BRT) a 27:00 UTC (00:00 BRT +1)
    const startOfDay = new Date(targetDate);
    const endOfDay   = new Date(targetDate);
    endOfDay.setUTCDate(targetDate.getUTCDate() + 1);
    const existing = await db
      .collection('slots')
      .where('branch_id', '==', branchId)
      .where('start_time', '>=', Timestamp.fromDate(startOfDay))
      .where('start_time', '<',  Timestamp.fromDate(endOfDay))
      .limit(1)
      .get();
    if (!existing.empty) {
      const label = targetDate.toISOString().slice(0, 10);
      console.log(`${branchName}: slots de ${label} já existem. Pulando.`);
      continue;
    }
    const slots = getSlotsForDay(targetDate, branchId);
    const batch = db.batch();
    for (const slot of slots) {
      batch.set(db.collection('slots').doc(), slot);
    }
    await batch.commit();
    totalGravados += slots.length;
    console.log(
      `${branchName}: ${slots.length} slots gravados para ` +
      `${targetDate.toISOString().slice(0, 10)} (BRT).`
    );
  }
  console.log(`Concluído. Total gravado: ${totalGravados} slots.`);
});
