import '../models/medicine.dart';

/// Essential and regular Outpatient Department (OPD) medicines that exist by default.
///
/// Uses deterministic document IDs (`med_*`) so that insertion into Firestore
/// is strictly idempotent and can NEVER create duplicates.
///
/// Streamlined clinical schema:
/// - [productName] includes commercial brand and dosage form (e.g. 'Telma 40 tablet').
/// - [composition] includes generic active ingredients and strength (e.g. 'Telmisartan 40mg').
/// - [manufacturer] captures the pharma brand company (e.g. 'Glenmark').
const List<Medicine> defaultEssentialMedicines = [
  // Analgesics & Antipyretics
  Medicine(
    id: 'med_dolo_650',
    productName: 'Dolo 650 tablet',
    composition: 'Paracetamol 650mg',
    manufacturer: 'Micro Labs',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-1 (BD)',
    defaultTiming: 'After Food',
    defaultDurationDays: 5,
  ),
  Medicine(
    id: 'med_calpol_650',
    productName: 'Calpol 650 tablet',
    composition: 'Paracetamol 650mg',
    manufacturer: 'GSK',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-1 (BD)',
    defaultTiming: 'After Food',
    defaultDurationDays: 5,
  ),
  Medicine(
    id: 'med_crocin_500',
    productName: 'Crocin 500 tablet',
    composition: 'Paracetamol 500mg',
    manufacturer: 'GSK',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-1 (BD)',
    defaultTiming: 'After Food',
    defaultDurationDays: 5,
  ),
  Medicine(
    id: 'med_combiflam',
    productName: 'Combiflam tablet',
    composition: 'Ibuprofen 400mg + Paracetamol 325mg',
    manufacturer: 'Sanofi',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-1 (BD)',
    defaultTiming: 'After Food',
    defaultDurationDays: 3,
  ),

  // Broad-Spectrum Antibiotics
  Medicine(
    id: 'med_augmentin_625',
    productName: 'Augmentin 625 Duo tablet',
    composition: 'Amoxicillin 500mg + Clavulanic Acid 125mg',
    manufacturer: 'GSK',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-1 (BD)',
    defaultTiming: 'After Food',
    defaultDurationDays: 5,
  ),
  Medicine(
    id: 'med_moxikind_cv_625',
    productName: 'Moxikind-CV 625 tablet',
    composition: 'Amoxicillin 500mg + Clavulanic Acid 125mg',
    manufacturer: 'Mankind',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-1 (BD)',
    defaultTiming: 'After Food',
    defaultDurationDays: 5,
  ),
  Medicine(
    id: 'med_azee_500',
    productName: 'Azee 500 tablet',
    composition: 'Azithromycin 500mg',
    manufacturer: 'Cipla',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'After Food',
    defaultDurationDays: 3,
  ),
  Medicine(
    id: 'med_azithral_500',
    productName: 'Azithral 500 tablet',
    composition: 'Azithromycin 500mg',
    manufacturer: 'Alembic',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'After Food',
    defaultDurationDays: 3,
  ),
  Medicine(
    id: 'med_taxim_o_200',
    productName: 'Taxim-O 200 tablet',
    composition: 'Cefixime 200mg',
    manufacturer: 'Alkem',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-1 (BD)',
    defaultTiming: 'After Food',
    defaultDurationDays: 5,
  ),

  // Gastrointestinal & Antacids
  Medicine(
    id: 'med_pan_40',
    productName: 'Pan 40 tablet',
    composition: 'Pantoprazole 40mg',
    manufacturer: 'Alkem',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'Before Food (Empty Stomach)',
    defaultDurationDays: 14,
  ),
  Medicine(
    id: 'med_pantocid_dsr',
    productName: 'Pantocid DSR capsule',
    composition: 'Pantoprazole 40mg + Domperidone 30mg',
    manufacturer: 'Sun Pharma',
    defaultDosage: '1 Capsule',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'Before Food (Empty Stomach)',
    defaultDurationDays: 14,
  ),
  Medicine(
    id: 'med_razo_20',
    productName: 'Razo 20 tablet',
    composition: 'Rabeprazole 20mg',
    manufacturer: "Dr. Reddy's",
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'Before Food (Empty Stomach)',
    defaultDurationDays: 14,
  ),

  // Cardiovascular & Antihypertensives
  Medicine(
    id: 'med_telma_40',
    productName: 'Telma 40 tablet',
    composition: 'Telmisartan 40mg',
    manufacturer: 'Glenmark',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'After Food',
    defaultDurationDays: null, // To continue (Chronic)
  ),
  Medicine(
    id: 'med_telmikind_40',
    productName: 'Telmikind 40 tablet',
    composition: 'Telmisartan 40mg',
    manufacturer: 'Mankind',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'After Food',
    defaultDurationDays: null, // To continue (Chronic)
  ),
  Medicine(
    id: 'med_telma_h',
    productName: 'Telma-H tablet',
    composition: 'Telmisartan 40mg + Hydrochlorothiazide 12.5mg',
    manufacturer: 'Glenmark',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'After Food',
    defaultDurationDays: null, // To continue (Chronic)
  ),
  Medicine(
    id: 'med_amlokind_5',
    productName: 'Amlokind 5 tablet',
    composition: 'Amlodipine 5mg',
    manufacturer: 'Mankind',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'After Food',
    defaultDurationDays: null, // To continue (Chronic)
  ),

  // Antidiabetic
  Medicine(
    id: 'med_glycomet_500',
    productName: 'Glycomet 500 tablet',
    composition: 'Metformin 500mg',
    manufacturer: 'USV',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-1 (BD)',
    defaultTiming: 'After Food',
    defaultDurationDays: null, // To continue (Chronic)
  ),
  Medicine(
    id: 'med_glycomet_gp1',
    productName: 'Glycomet-GP 1 tablet',
    composition: 'Metformin 500mg + Glimepiride 1mg',
    manufacturer: 'USV',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'Before Food',
    defaultDurationDays: null, // To continue (Chronic)
  ),

  // Antiallergic & Respiratory
  Medicine(
    id: 'med_levocet_5',
    productName: 'Levocet 5 tablet',
    composition: 'Levocetirizine 5mg',
    manufacturer: 'Hetero',
    defaultDosage: '1 Tablet',
    defaultFrequency: '0-0-1 (HS)',
    defaultTiming: 'At Bedtime',
    defaultDurationDays: 5,
  ),
  Medicine(
    id: 'med_allegra_120',
    productName: 'Allegra 120 tablet',
    composition: 'Fexofenadine 120mg',
    manufacturer: 'Sanofi',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'After Food',
    defaultDurationDays: 5,
  ),
  Medicine(
    id: 'med_montek_lc',
    productName: 'Montek-LC tablet',
    composition: 'Montelukast 10mg + Levocetirizine 5mg',
    manufacturer: 'Sun Pharma',
    defaultDosage: '1 Tablet',
    defaultFrequency: '0-0-1 (HS)',
    defaultTiming: 'At Bedtime',
    defaultDurationDays: 7,
  ),

  // Nutritional Supplements
  Medicine(
    id: 'med_shelcal_500',
    productName: 'Shelcal 500 tablet',
    composition: 'Calcium 500mg + Vitamin D3 250 IU',
    manufacturer: 'Torrent',
    defaultDosage: '1 Tablet',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'After Food',
    defaultDurationDays: 30,
  ),
  Medicine(
    id: 'med_becosules',
    productName: 'Becosules capsule',
    composition: 'Vitamin B-Complex + Vitamin C',
    manufacturer: 'Pfizer',
    defaultDosage: '1 Capsule',
    defaultFrequency: '1-0-0 (OD)',
    defaultTiming: 'After Food',
    defaultDurationDays: 15,
  ),
];
