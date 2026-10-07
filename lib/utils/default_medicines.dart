import '../models/medicine.dart';

/// Essential and regular Outpatient Department (OPD) medicines that exist by default.
///
/// Uses deterministic document IDs (`med_*`) so that insertion into Firestore
/// is strictly idempotent and can NEVER create duplicates.
const List<Medicine> defaultEssentialMedicines = [
  // Analgesics & Antipyretics
  Medicine(
    id: 'med_dolo_650',
    productName: 'Dolo 650',
    composition: 'Paracetamol',
    strength: '650 mg',
    form: 'Tablet',
    manufacturer: 'Micro Labs',
    category: 'Analgesic / Antipyretic',
  ),
  Medicine(
    id: 'med_calpol_650',
    productName: 'Calpol 650',
    composition: 'Paracetamol',
    strength: '650 mg',
    form: 'Tablet',
    manufacturer: 'GSK',
    category: 'Analgesic / Antipyretic',
  ),
  Medicine(
    id: 'med_crocin_500',
    productName: 'Crocin 500',
    composition: 'Paracetamol',
    strength: '500 mg',
    form: 'Tablet',
    manufacturer: 'GSK',
    category: 'Analgesic / Antipyretic',
  ),
  Medicine(
    id: 'med_combiflam',
    productName: 'Combiflam',
    composition: 'Ibuprofen + Paracetamol',
    strength: '400 mg + 325 mg',
    form: 'Tablet',
    manufacturer: 'Sanofi',
    category: 'NSAID / Analgesic',
  ),

  // Broad-Spectrum Antibiotics
  Medicine(
    id: 'med_augmentin_625',
    productName: 'Augmentin 625 Duo',
    composition: 'Amoxicillin + Clavulanic Acid',
    strength: '625 mg',
    form: 'Tablet',
    manufacturer: 'GSK',
    category: 'Antibiotic (Penicillin)',
  ),
  Medicine(
    id: 'med_moxikind_cv_625',
    productName: 'Moxikind-CV 625',
    composition: 'Amoxicillin + Clavulanic Acid',
    strength: '625 mg',
    form: 'Tablet',
    manufacturer: 'Mankind',
    category: 'Antibiotic (Penicillin)',
  ),
  Medicine(
    id: 'med_azee_500',
    productName: 'Azee 500',
    composition: 'Azithromycin',
    strength: '500 mg',
    form: 'Tablet',
    manufacturer: 'Cipla',
    category: 'Antibiotic (Macrolide)',
  ),
  Medicine(
    id: 'med_azithral_500',
    productName: 'Azithral 500',
    composition: 'Azithromycin',
    strength: '500 mg',
    form: 'Tablet',
    manufacturer: 'Alembic',
    category: 'Antibiotic (Macrolide)',
  ),
  Medicine(
    id: 'med_taxim_o_200',
    productName: 'Taxim-O 200',
    composition: 'Cefixime',
    strength: '200 mg',
    form: 'Tablet',
    manufacturer: 'Alkem',
    category: 'Antibiotic (Cephalosporin)',
  ),

  // Gastrointestinal & Antacids
  Medicine(
    id: 'med_pan_40',
    productName: 'Pan 40',
    composition: 'Pantoprazole',
    strength: '40 mg',
    form: 'Tablet',
    manufacturer: 'Alkem',
    category: 'Antacid / PPI',
  ),
  Medicine(
    id: 'med_pantocid_dsr',
    productName: 'Pantocid DSR',
    composition: 'Pantoprazole + Domperidone',
    strength: '40 mg + 30 mg',
    form: 'Capsule',
    manufacturer: 'Sun Pharma',
    category: 'Antacid / Antiemetic',
  ),
  Medicine(
    id: 'med_razo_20',
    productName: 'Razo 20',
    composition: 'Rabeprazole',
    strength: '20 mg',
    form: 'Tablet',
    manufacturer: "Dr. Reddy's",
    category: 'Antacid / PPI',
  ),

  // Cardiovascular & Antihypertensives
  Medicine(
    id: 'med_telma_40',
    productName: 'Telma 40',
    composition: 'Telmisartan',
    strength: '40 mg',
    form: 'Tablet',
    manufacturer: 'Glenmark',
    category: 'Antihypertensive (ARB)',
  ),
  Medicine(
    id: 'med_telma_h',
    productName: 'Telma-H',
    composition: 'Telmisartan + Hydrochlorothiazide',
    strength: '40 mg + 12.5 mg',
    form: 'Tablet',
    manufacturer: 'Glenmark',
    category: 'Antihypertensive (Combination)',
  ),
  Medicine(
    id: 'med_amlokind_5',
    productName: 'Amlokind 5',
    composition: 'Amlodipine',
    strength: '5 mg',
    form: 'Tablet',
    manufacturer: 'Mankind',
    category: 'Antihypertensive (CCB)',
  ),

  // Antidiabetic
  Medicine(
    id: 'med_glycomet_500',
    productName: 'Glycomet 500',
    composition: 'Metformin',
    strength: '500 mg',
    form: 'Tablet',
    manufacturer: 'USV',
    category: 'Antidiabetic (Biguanide)',
  ),
  Medicine(
    id: 'med_glycomet_gp1',
    productName: 'Glycomet-GP 1',
    composition: 'Metformin + Glimepiride',
    strength: '500 mg + 1 mg',
    form: 'Tablet',
    manufacturer: 'USV',
    category: 'Antidiabetic (Combination)',
  ),

  // Antiallergic & Respiratory
  Medicine(
    id: 'med_levocet_5',
    productName: 'Levocet 5',
    composition: 'Levocetirizine',
    strength: '5 mg',
    form: 'Tablet',
    manufacturer: 'Hetero',
    category: 'Antihistamine',
  ),
  Medicine(
    id: 'med_allegra_120',
    productName: 'Allegra 120',
    composition: 'Fexofenadine',
    strength: '120 mg',
    form: 'Tablet',
    manufacturer: 'Sanofi',
    category: 'Antihistamine',
  ),
  Medicine(
    id: 'med_montek_lc',
    productName: 'Montek-LC',
    composition: 'Montelukast + Levocetirizine',
    strength: '10 mg + 5 mg',
    form: 'Tablet',
    manufacturer: 'Sun Pharma',
    category: 'Respiratory / Antiallergic',
  ),

  // Nutritional Supplements
  Medicine(
    id: 'med_shelcal_500',
    productName: 'Shelcal 500',
    composition: 'Calcium + Vitamin D3',
    strength: '500 mg + 250 IU',
    form: 'Tablet',
    manufacturer: 'Torrent',
    category: 'Supplement',
  ),
  Medicine(
    id: 'med_becosules',
    productName: 'Becosules',
    composition: 'Vitamin B-Complex + Vitamin C',
    strength: 'Capsule',
    form: 'Capsule',
    manufacturer: 'Pfizer',
    category: 'Vitamin Supplement',
  ),
];
