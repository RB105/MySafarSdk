// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart' show DateFormat;
import 'package:mrz_parser/mrz_parser.dart';

extension _Formatters on DateTime {
  String formatToDMY() => DateFormat('dd.MM.yyyy').format(this);
}

class UsersModel {
  int? id;
  String? createdAt;
  String? updatedAt;
  String? firstname;
  String? lastname;
  String? middlename;
  String? birthdate;
  String? doctype;
  String? docnum;
  String? docexp;
  String? gender;
  String? citizen;
  String? phone;
  String? email;
  int? user;

  UsersModel({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.firstname,
    this.lastname,
    this.middlename,
    this.birthdate,
    this.doctype,
    this.docnum,
    this.docexp,
    this.gender,
    this.citizen,
    this.phone,
    this.email,
    this.user,
  });

  UsersModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    createdAt = json['created_at'] ?? "";
    updatedAt = json['updated_at'] ?? "";
    firstname = json['firstname'] ?? "";
    lastname = json['lastname'] ?? "";
    middlename = json['middlename'] ?? "";
    birthdate = json['birthdate'] ?? "";
    doctype = json['doctype'];
    docnum = json['docnum'] ?? "";
    docexp = json['docexp'] ?? "";
    gender = json['gender'] ?? "";
    citizen = json['citizen'] ?? "";
    phone = json['phone'] ?? "";
    email = json['email'] ?? "";
    user = json['user'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['firstname'] = firstname;
    data['lastname'] = lastname;
    data['middlename'] = middlename;
    data['birthdate'] = birthdate;
    data['doctype'] = doctype;
    data['docnum'] = docnum;
    data['docexp'] = docexp;
    data['gender'] = gender;
    data['citizen'] = citizen;
    data['phone'] = phone;
    data['email'] = email;
    data['user'] = user;
    return data;
  }

  /// MRZ skan natijasidan [UsersModel] yasaydi.
  ///
  /// - [firstname]  ← MRZ givenNames (butun qiymati, ism+otasini ajratmaymiz)
  /// - [middlename] ← '' (MRZ da sharif bo'lmaydi — foydalanuvchi qo'lda kiritadi)
  /// - [docnum]     ← tozalangan (< va bo'shliqlar olib tashlanadi)
  /// - [gender]     ← Sex.none → null (mavjud qiymatni ezmaslik uchun)
  /// - [citizen]    ← ICAO alpha-3 → ISO alpha-2 jadval orqali (TUR→TR, KAZ→KZ)
  static UsersModel fromScan(MRZResult result) {
    return UsersModel(
      firstname: _cleanName(result.givenNames),
      lastname: _cleanName(result.surnames),
      middlename: '',
      birthdate: result.birthDate.formatToDMY(),
      doctype: _mapDocType(result.documentType),
      docnum: _cleanDocNum(result.documentNumber),
      docexp: result.expiryDate.formatToDMY(),
      gender: _mapSex(result.sex),
      citizen: _mapCountry(
        result.nationalityCountryCode.isNotEmpty
            ? result.nationalityCountryCode
            : result.countryCode,
      ),
    );
  }

  /// Ism/familiya tozalash: katta harf, ortiqcha bo'shliqlar.
  static String _cleanName(String raw) {
    return raw.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Hujjat raqamini tozalash: < va MRZ bo'lmagan belgilarni olib tashlash.
  static String _cleanDocNum(String raw) {
    return raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// Jins: Sex.none (ID < belgisi) → null, server mavjud qiymatni saqlasin.
  static String? _mapSex(Sex sex) {
    switch (sex) {
      case Sex.male:
        return 'M';
      case Sex.female:
        return 'F';
      default:
        return null;
    }
  }

  /// Loyiha doctype: passport = P, ID = A.
  static String _mapDocType(String raw) {
    final type = raw.toUpperCase();
    if (type.startsWith('P')) return 'P';
    return 'A';
  }

  /// ICAO alpha-3 (yoki 1-2 harfli) → ISO 3166-1 alpha-2.
  ///
  /// Eski xato: `substring(0, 2)` — TUR→TU, KAZ→KA, UKR→UK, CHN→CH.
  static String _mapCountry(String code) {
    final c = code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (c.isEmpty) return '';
    if (c.length == 2) return c;
    if (c.length == 1) {
      return switch (c) {
        'D' => 'DE', // Germany legacy ICAO
        _ => c,
      };
    }
    return _icaoAlpha3ToIso2[c] ?? c.substring(0, 2);
  }

  /// ICAO alpha-3 → ISO 3166-1 alpha-2 jadvali.
  /// Substring(0,2) xato beradigan kodlar + MDH + asosiy yo'nalishlar.
  static const Map<String, String> _icaoAlpha3ToIso2 = {
    // MDH / mintaqa
    'UZB': 'UZ', 'RUS': 'RU', 'KAZ': 'KZ', 'KGZ': 'KG', 'TJK': 'TJ',
    'TKM': 'TM', 'AZE': 'AZ', 'ARM': 'AM', 'GEO': 'GE', 'BLR': 'BY',
    'UKR': 'UA', 'MDA': 'MD',
    // Yevropa
    'TUR': 'TR', 'DEU': 'DE', 'FRA': 'FR', 'GBR': 'GB', 'ITA': 'IT',
    'ESP': 'ES', 'PRT': 'PT', 'NLD': 'NL', 'BEL': 'BE', 'CHE': 'CH',
    'AUT': 'AT', 'POL': 'PL', 'CZE': 'CZ', 'SVK': 'SK', 'HUN': 'HU',
    'ROU': 'RO', 'BGR': 'BG', 'GRC': 'GR', 'SWE': 'SE', 'NOR': 'NO',
    'DNK': 'DK', 'FIN': 'FI', 'IRL': 'IE', 'ISL': 'IS', 'LUX': 'LU',
    'LTU': 'LT', 'LVA': 'LV', 'EST': 'EE', 'HRV': 'HR', 'SVN': 'SI',
    'SRB': 'RS', 'BIH': 'BA', 'MKD': 'MK', 'MNE': 'ME', 'ALB': 'AL',
    'CYP': 'CY', 'MLT': 'MT',
    // Osiyo / Yaqin Sharq
    'CHN': 'CN', 'JPN': 'JP', 'KOR': 'KR', 'PRK': 'KP', 'IND': 'IN',
    'PAK': 'PK', 'AFG': 'AF', 'IRN': 'IR', 'IRQ': 'IQ', 'ISR': 'IL',
    'PSE': 'PS', 'SAU': 'SA', 'ARE': 'AE', 'QAT': 'QA', 'KWT': 'KW',
    'BHR': 'BH', 'OMN': 'OM', 'YEM': 'YE', 'JOR': 'JO', 'LBN': 'LB',
    'SYR': 'SY', 'THA': 'TH', 'VNM': 'VN', 'IDN': 'ID', 'MYS': 'MY',
    'SGP': 'SG', 'PHL': 'PH', 'MNG': 'MN', 'NPL': 'NP', 'BGD': 'BD',
    'LKA': 'LK',
    // Amerika / boshqa
    'USA': 'US', 'CAN': 'CA', 'MEX': 'MX', 'BRA': 'BR', 'ARG': 'AR',
    'AUS': 'AU', 'NZL': 'NZ', 'ZAF': 'ZA', 'EGY': 'EG', 'MAR': 'MA',
    'DZA': 'DZ', 'TUN': 'TN', 'NGA': 'NG', 'KEN': 'KE', 'ETH': 'ET',
    // Maxsus
    'XKX': 'XK', 'TWN': 'TW', 'HKG': 'HK', 'MAC': 'MO',
  };
}
