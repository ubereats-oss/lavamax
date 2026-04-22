// seed_vehicles.js
// Popula a coleção 'vehicle_brands' no Firestore.
// Estrutura: cada documento = uma marca, com array de modelos.
//
// COMO USAR:
//   node seed_vehicles.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyLavaMax.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
const brands = {
  "Alfa Romeo": ["145","147","155","156","164","166","2300","Spider"],
  "Aston Martin": ["Db12","Db9","Dbs","Dbx","Dbx707","Rapide","Vanquish","Vantage","Virage"],
  "Audi": ["100","80","A1","A3","A4","A5","A6","A7","A8","Allroad","Avant","E-tron","Q3","Q5","Q6","Q7","Q8","R8","Rs","Rs3","Rs4","Rs5","Rs6","Rs7","S3","S4","S5","S6","S7","S8","Sq5","Sq6","Sq8","Tt"],
  "Bmw": ["116ia","118i","120i","125i","130i","135ia","218i","220i","225i","316i","318i","320i","323i","325i","328i","330i","335i","420i","428i","430i","435ia","520i","525i/ia","528ia","530i","535ia","540i","545ia","550ia","640i","645ia","650i","730i","735i/ia","740i","745ia","750i","760il","840ci","850i","I3","I4","I5","I7","I8","Ix","M","M1","M2","M3","M4","M5","M6","M7","M8","X1","X2","X3","X4","X5","X6","X7","Z3","Z4","Z8"],
  "Byd": ["D1","Dolphin","Et3","Han","King","Seal","Shark","Song","Tan","Yuan"],
  "Cadillac": ["Deville/eldorado","Seville"],
  "Caoa Chery": ["Arrizo","Icar","Tiggo"],
  "Chrysler": ["300","Caravan","Cirrus","Grand caravan","Le","Neon","Pt cruiser","Sebring","Stratus","Town & country","Vision"],
  "Citroen": ["Aircross","Aircross7","Ax","Basalt","Berlingo","Bx","C3","C4","C5","C6","C8","Ds3","Ds4","Ds5","Evasion","Grand","Jumper","Jumpy","Xantia","Xm","Xsara","Zx"],
  "Cross lander": ["Cl-244","Cl-330"],
  "Ferrari": ["12cilinrdri","296","348","355","360","456","458","488","550","575m","612","812","California","F12","F430","F458","F599","F8","Ff","Gtc4","Portofino","Purosangue","Roma","Sf"],
  "Fiat": ["500","Argo","Brava","Bravo","Cinquecento","Coupe","Cronos","Doblo","Ducato","Duna","E-scudo","Fastback","Fiorino","Freemont","Idea","Linea","Marea","Mobi","Palio","Panorama","Pulse","Punto","Scudo","Siena","Stilo","Strada","Tempra","Tipo","Titano","Toro","Uno"],
  "Ford": ["Aerostar","Aspire","Bronco","Club","Contour","Courier","Crown","E-transit","Ecosport","Edge","Expedition","Explorer","F-100","F-1000","F-150","F-250","Fiesta","Focus","Furglaine","Fusion","Ibiza","Ka","Maverick","Mondeo","Mustang","Probe","Ranger","Royale","Taurus","Territory","Thunderbird","Transit","Windstar"],
  "Gac": ["Aion","Gs4","Hyptec"],
  "GM - Chevrolet": ["Agile","Astra","Blazer","Bolt","Bonanza","Brasinca","Calibra","Camaro","Caprice","Captiva","Cavalier","Celta","Chevy","Cheynne","Cobalt","Corsa","Corvette","Cruze","Equinox","Joy","Lumina","Malibu","Meriva","Montana","Monza","Omega","Onix","Opala","Prisma","S10","Saturn","Sierra","Silverado","Sonic","Sonoma","Spacevan","Spark","Spin","Suburban","Syclone","Tigra","Tracker","Trafic","Trailblazer","Vectra","Zafira"],
  "GWM": ["Haval","Ora","Poer","Tank","Wey"],
  "Hafei": ["Towner"],
  "Hitech Electric": ["Delivery","E-work","E.co"],
  "Honda": ["Accord","City","Civic","Cr-v","Fit","Hr-v","Odyssey","Passport","Prelude","Wr-v","Zr-v"],
  "Hyundai": ["Accent","Atos","Azera","Coupe","Creta","Elantra","Equus","Excel","Galloper","Genesis","Grand","H1","Hb20","Hr","I30","Ioniq","Ix35","Kona","Matrix","Palisade","Porter","Santa fe","Scoupe","Sonata","Terracan","Trajet","Tucson","Veloster","Veracruz"],
  "Isuzu": ["Amigo","Hombre","Rodeo"],
  "Jac": ["E-j7","E-js1","E-js4","E-jv","Hunter","Iev","J2","J3","J5","J6","T","V260"],
  "Jaecoo": ["7"],
  "Jaguar": ["Daimler","E-pace","F-pace","F-type","I-pace","S-type","X-type","Xe","Xf","Xj","Xk"],
  "Jeep": ["Cherokee","Commander","Compass","Gladiator","Renegade","Wrangler"],
  "Kia Motors": ["Besta","Bongo","Cadenza","Carens","Carnival","Cerato","Ceres","Clarus","Ev5","Ev9","Grand carnival","Magentis","Mohave","Niro","Opirus","Optima","Picanto","Quoris","Rio","Sephia","Shuma","Sorento","Soul","Sportage","Stinger","Stonic"],
  "Lamborghini": ["Aventador","Gallardo","Huracan","Revuelto","Urus"],
  "Land Rover": ["Defender","Discovery","Evoque","Freelander","Range rover","Vogue"],
  "Lexus": ["Ct200h","Es-300","Es-330","Es-350","Gs","Is","Ls","Nx","Rx","Sc","Ux"],
  "Maserati": ["222","228","3200","430","Coupe","Ghibli","Gran turismo","Grancabrio","Gransport","Levante","Mc20","Quattroporte","Shamal","Spyder"],
  "Mazda": ["323","626","929","B-2500","B2200","Millenia","Mpv","Mx-3","Mx-5","Navajo","Protege","Rx"],
  "Mercedes-Benz": ["180","190","230","260","300","500","560","A","C","Cl","Cla","Clc","Clk","Cls","E","Eqa","Eqb","Eqc","Eqe","Eqs","Esprinter","G","Gl","Gla","Glb","Glc","Gle","Glk","Gls","Gt","Ml","S","Se","Slc","Slk","Sls","Sprinter","Vito"],
  "Mini": ["Aceman","Cooper","One"],
  "Mitsubishi": ["3000","Airtrek","Asx","Colt","Diamant","Eclipse","Expo","Galant","Grandis","L200","L300","Lancer","Mirage","Montero","Outlander","Pajero","Space","Triton"],
  "Nissan": ["350z","Altima","Ax","D-21","Frontier","Gt-r","Infinit","Kait","Kicks","King-cab","Leaf","Livina","March","Maxima","Micra","Murano","Nx","Pathfinder","Pick-up","Primera","Quest","Sentra","Stanza","Sx","Terrano","Tiida","Versa","X-trail","Xterra","Zx"],
  "Omoda": ["5","7","E5"],
  "Peugeot": ["106","2008","205","206","207","208","3008","306","307","308","405","406","407","408","5008","504","505","508","605","607","806","807","Boxer","Expert","Hoggar","Partner","Rcz"],
  "Porsche": ["718","911","928","968","Boxster","Cayenne","Cayman","Macan","Panamera","Taycan"],
  "RAM": ["1500","2500","3500","Classic","Rampage"],
  "Renault": ["Boreal","Captur","Clio","Duster","Express","Fluence","Kangoo","Kardian","Kwid","Laguna","Logan","Master","Megane","Oroch","Safrane","Sandero","Scenic","Stepway","Symbol","Trafic","Twingo","Zoe"],
  "Rolls-Royce": ["Cullinan","Dawn","Ghost","Phantom","Wraith"],
  "Seat": ["Cordoba","Ibiza","Inca"],
  "Ssangyong": ["Actyon","Chairman","Istana","Korando","Kyron","Musso","Rexton","Tivoli","Xlv"],
  "Subaru": ["Forester","Impreza","Legacy","Outback","Svx","Tribeca","Vivio","Xv"],
  "Suzuki": ["Baleno","Grand vitara","Ignis","Jimny","S-cross","Samurai","Sidekick","Super","Swift","Sx4","Vitara","Wagon"],
  "Toyota": ["Avalon","Bandeirante","Camry","Celica","Corolla","Corolla cross","Corona","Etios","Hiace","Hilux","Land cruiser","Mr-2","Paseo","Previa","Prius","Rav4","Supra","T-100","Yaris"],
  "Troller": ["Pantanal","Rf","T-4"],
  "Volvo": ["440","460","850","940","960","C30","C40","C70","Ec40","Ex30","Ex40","Ex90","S40","S60","S70","S80","S90","V40","V50","V60","V70","Xc"],
  "VW - Volkswagen": ["Amarok","Apolo","Bora","Caravelle","Corrado","Crossfox","Delivery","Eos","Eurovan","Fox","Fusca","Gol","Golf","Jetta","Kombi","Logus","New beetle","Nivus","Parati","Passat","Pointer","Polo","Quantum","Santana","Saveiro","Spacecross","Spacefox","T-cross","Taos","Tera","Tiguan","Touareg","Up!","Van","Virtus","Voyage"]
};
async function seedVehicleBrands() {
  console.log('Verificando se vehicle_brands ja existe...');
  const existing = await db.collection('vehicle_brands').limit(1).get();
  if (!existing.empty) {
    console.log('Colecao vehicle_brands ja possui dados. Abortando para evitar duplicata.');
    console.log('Se quiser recriar, apague a colecao no Firebase Console primeiro.');
    process.exit(0);
  }
  console.log('Gravando marcas e modelos...');
  const batch = db.batch();
  let count = 0;
  for (const [brand, models] of Object.entries(brands)) {
    const ref = db.collection('vehicle_brands').doc();
    batch.set(ref, {
      name: brand,
      models: models,
      is_active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    count++;
  }
  await batch.commit();
  console.log(`Concluido! ${count} marcas gravadas.`);
  process.exit(0);
}
seedVehicleBrands().catch(err => {
  console.error('Erro:', err);
  process.exit(1);
});
