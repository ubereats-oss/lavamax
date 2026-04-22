const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
// 🔥 MAPEAMENTO EXATO (Firestore → arquivo)
const mapping = {
  "Funilaria e Pintura": "funilaria",
  "Restauração de Faróis": "restauracao_farois",
  "Home Car Detail – Condomínios": "home_car_detail",
  "Polimentos Técnicos": "polimentos",
  "Customização": "customizacao",
  "Vitrificação de Pintura": "vitrificacao",
  "Aplicações de Películas": "peliculas",
  "Pintura e Desempeno de Rodas": "rodas",
  "Lavagem Premium": "lavagem_premium",
  "Higienizações Diversas": "higienizacao",
  "PPF – Paint Protection Film": "ppf",
  "Martelinho de Ouro": "martelinho",
  "Limpeza Técnica de Motor": "limpeza_motor",
};
// 🔥 URLs que você já gerou
const urls = {
  customizacao: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Fcustomizacao.png?alt=media&token=a40650b4-0ad1-41b8-af8f-0ac30090ad2b",
  funilaria: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Ffunilaria.png?alt=media&token=11d61366-67f3-4634-8db1-af2f4a208c9c",
  higienizacao: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Fhigienizacao.png?alt=media&token=69705562-b50a-4d67-8462-9cc741ac16c3",
  home_car_detail: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Fhome_car_detail.png?alt=media&token=6cf3b8c3-0b5b-4eac-adfa-6b1deb41745e",
  lavagem_premium: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Flavagem_premium.png?alt=media&token=e89a83e1-80f8-4c87-8a42-09569a48893c",
  limpeza_motor: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Flimpeza_motor.png?alt=media&token=27e35c09-f10f-4b6f-b818-0952851980fc",
  martelinho: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Fmartelinho.png?alt=media&token=c628523f-728d-44a6-ad4e-50fb99c4c51c",
  peliculas: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Fpeliculas.png?alt=media&token=04375850-73ab-4300-92d9-75c362c3424f",
  polimentos: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Fpolimentos.png?alt=media&token=397d8cdc-9663-43da-a6b5-1fdfdf763b6c",
  ppf: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Fppf.png?alt=media&token=b2729ef9-68d9-4123-9d9f-fc9b5d347b54",
  restauracao_farois: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Frestauracao_farois.png?alt=media&token=6df84dfc-6f51-4d7c-bb9d-254754281877",
  rodas: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Frodas.png?alt=media&token=29434ac8-35b3-4806-a5f9-e85f93cf6578",
  vitrificacao: "https://firebasestorage.googleapis.com/v0/b/lavamaxapp.firebasestorage.app/o/services%2Ficons%2Fvitrificacao.png?alt=media&token=c676da19-53c7-4dc9-b9c2-a1f14dd34170",
};
async function run() {
  const snapshot = await db.collection('services').get();
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const fileKey = mapping[data.name];
    if (fileKey && urls[fileKey]) {
      await doc.ref.update({
        icon_url: urls[fileKey]
      });
      console.log(`✔ ${data.name}`);
    } else {
      console.log(`⚠ NÃO MAPEADO: ${data.name}`);
    }
  }
  console.log('🔥 FINALIZADO');
}
run();
