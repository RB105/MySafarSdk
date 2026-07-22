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

  static UsersModel fromScan(MRZResult result) {
    final names = _splitGivenNames(result.givenNames);
    return UsersModel(
      firstname: names.firstname,
      lastname: result.surnames,
      middlename: names.middlename,
      birthdate: result.birthDate.formatToDMY(),
      doctype: _mapDocType(result.documentType),
      docnum: result.documentNumber,
      docexp: result.expiryDate.formatToDMY(),
      gender: _mapSex(result.sex),
      // Fuqarolik uchun nationality; bo'sh bo'lsa issuing country.
      citizen: _mapCountry(
        result.nationalityCountryCode.isNotEmpty
            ? result.nationalityCountryCode
            : result.countryCode,
      ),
    );
  }

  /// MRZ givenNames: "ISM OTASINING ISMI" — birinchi so'z ism, qolgani otasining ismi.
  static ({String firstname, String middlename}) _splitGivenNames(
    String givenNames,
  ) {
    final parts =
        givenNames.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final list = parts.toList();
    if (list.isEmpty) return (firstname: '', middlename: '');
    if (list.length == 1) return (firstname: list.first, middlename: '');
    return (
      firstname: list.first,
      middlename: list.sublist(1).join(' '),
    );
  }

  static String _mapSex(Sex sex) {
    switch (sex) {
      case Sex.male:
        return "M";
      case Sex.female:
        return "F";
      default:
        return "";
    }
  }

  /// Loyiha doctype: passport = P, ID = A.
  static String _mapDocType(String raw) {
    final type = raw.toUpperCase();
    if (type.startsWith('P')) return 'P';
    return 'A';
  }

  static String _mapCountry(String code) {
    // ICAO 3-letter (UZB) → ISO alpha-2 (UZ).
    if (code.length >= 2) {
      return code.substring(0, 2).toUpperCase();
    }
    return code.toUpperCase();
  }
}
