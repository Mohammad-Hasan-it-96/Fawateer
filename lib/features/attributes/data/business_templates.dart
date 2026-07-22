import '../domain/entities/attribute_definition.dart';
import '../domain/entities/attribute_type.dart';

/// A curated starter set of custom fields for a business type (Plan 010).
///
/// Templates are **seed data, not a type system** — picking one inserts these
/// definitions once; the owner then edits/adds/removes freely. Held as a const
/// Dart list (app asset, versionable, no migration, no table). Labels are
/// Arabic (the app is Arabic-first) and become user data once seeded.
///
/// Deliberately **descriptive fields only** (bucket A). No IMEI/Serial (bucket
/// C — needs serialized-unit tracking) and no Size×Color variant matrix (bucket
/// B) — those are separate later plans, so we don't ship a half-working field.
class BusinessTemplate {
  final String id;
  final String nameAr;
  final String nameEn;
  final String emoji;
  final List<AttributeDefinition> definitions;

  const BusinessTemplate({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.emoji,
    required this.definitions,
  });

  bool get isEmpty => definitions.isEmpty;
}

const List<BusinessTemplate> kBusinessTemplates = [
  BusinessTemplate(
    id: 'general',
    nameAr: 'متجر عام',
    nameEn: 'General store',
    emoji: '🏪',
    definitions: [], // no custom fields — grocery/general owners never see one
  ),
  BusinessTemplate(
    id: 'mobile',
    nameAr: 'متجر هواتف',
    nameEn: 'Mobile shop',
    emoji: '📱',
    definitions: [
      // NOTE: IMEI intentionally omitted — it's a per-unit serial (bucket C),
      // not a descriptive attribute; it arrives with serialized-unit tracking.
      AttributeDefinition(
          id: 'color',
          label: 'اللون',
          type: AttributeType.select,
          options: ['أسود', 'أبيض', 'ذهبي', 'أزرق', 'أخضر'],
          showInList: true,
          showOnReceipt: true,
          sortOrder: 1),
      AttributeDefinition(
          id: 'storage',
          label: 'السعة',
          type: AttributeType.number,
          unit: 'GB',
          showInList: true,
          showOnReceipt: true,
          sortOrder: 2),
      AttributeDefinition(
          id: 'warranty', label: 'الكفالة', sortOrder: 3, showOnReceipt: true),
    ],
  ),
  BusinessTemplate(
    id: 'laptop',
    nameAr: 'متجر حواسيب',
    nameEn: 'Laptop store',
    emoji: '💻',
    definitions: [
      AttributeDefinition(
          id: 'cpu', label: 'المعالج', showInList: true, sortOrder: 1),
      AttributeDefinition(
          id: 'ram',
          label: 'الذاكرة',
          type: AttributeType.number,
          unit: 'GB',
          showInList: true,
          sortOrder: 2),
      AttributeDefinition(
          id: 'ssd',
          label: 'التخزين',
          type: AttributeType.number,
          unit: 'GB',
          sortOrder: 3),
      AttributeDefinition(id: 'gpu', label: 'كرت الشاشة', sortOrder: 4),
      AttributeDefinition(
          id: 'warranty', label: 'الكفالة', showOnReceipt: true, sortOrder: 5),
    ],
  ),
  BusinessTemplate(
    id: 'clothing',
    nameAr: 'متجر ملابس',
    nameEn: 'Clothing store',
    emoji: '👕',
    definitions: [
      AttributeDefinition(
          id: 'size',
          label: 'المقاس',
          type: AttributeType.select,
          options: ['S', 'M', 'L', 'XL', 'XXL'],
          showInList: true,
          showOnReceipt: true,
          sortOrder: 1),
      AttributeDefinition(
          id: 'color',
          label: 'اللون',
          type: AttributeType.select,
          options: ['أسود', 'أبيض', 'أحمر', 'أزرق', 'أخضر'],
          showInList: true,
          showOnReceipt: true,
          sortOrder: 2),
      AttributeDefinition(id: 'material', label: 'الخامة', sortOrder: 3),
    ],
  ),
  BusinessTemplate(
    id: 'pharmacy',
    nameAr: 'صيدلية',
    nameEn: 'Pharmacy',
    emoji: '💊',
    definitions: [
      AttributeDefinition(id: 'brand', label: 'الشركة', sortOrder: 1),
      AttributeDefinition(id: 'dosage', label: 'التركيز', sortOrder: 2),
      // Simple one-expiry-per-product date; per-batch expiry is a later plan.
      AttributeDefinition(
          id: 'expiry',
          label: 'تاريخ الانتهاء',
          type: AttributeType.date,
          showInList: true,
          sortOrder: 3),
    ],
  ),
  BusinessTemplate(
    id: 'hardware',
    nameAr: 'متجر أدوات',
    nameEn: 'Hardware store',
    emoji: '🔧',
    definitions: [
      AttributeDefinition(id: 'brand', label: 'الماركة', sortOrder: 1),
      AttributeDefinition(
          id: 'voltage',
          label: 'الفولتية',
          type: AttributeType.number,
          unit: 'V',
          sortOrder: 2),
      AttributeDefinition(id: 'power', label: 'الاستطاعة', sortOrder: 3),
    ],
  ),
  BusinessTemplate(
    id: 'perfume',
    nameAr: 'متجر عطور',
    nameEn: 'Perfume shop',
    emoji: '🌸',
    definitions: [
      AttributeDefinition(
          id: 'volume',
          label: 'الحجم',
          type: AttributeType.number,
          unit: 'ml',
          showInList: true,
          sortOrder: 1),
      AttributeDefinition(
          id: 'concentration',
          label: 'التركيز',
          type: AttributeType.select,
          options: ['Parfum', 'EDP', 'EDT', 'EDC'],
          sortOrder: 2),
      AttributeDefinition(
          id: 'gender',
          label: 'الفئة',
          type: AttributeType.select,
          options: ['رجالي', 'نسائي', 'للجنسين'],
          showInList: true,
          sortOrder: 3),
    ],
  ),
  BusinessTemplate(
    id: 'cosmetics',
    nameAr: 'متجر تجميل',
    nameEn: 'Cosmetics store',
    emoji: '💄',
    definitions: [
      AttributeDefinition(id: 'brand', label: 'الماركة', sortOrder: 1),
      AttributeDefinition(id: 'shade', label: 'الدرجة', sortOrder: 2),
      AttributeDefinition(
          id: 'volume',
          label: 'الحجم',
          type: AttributeType.number,
          unit: 'ml',
          sortOrder: 3),
    ],
  ),
];
