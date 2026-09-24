import 'package:mysafar_sdk/src/model/local/passenger_rules.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';

/// Yo'lovchi ma'lumotlari modeli
/// Type-safe va immutable model
class PassengerModel {
  final String firstname;
  final String lastname;
  final String middlename;
  final String age; // adt, chd, inf
  final String birthdate;
  final String doctype;
  final String docnum;
  final String docexp;
  final String gender;
  final String citizen;
  final String phone;
  final String email;
  final int sendEmail;

  const PassengerModel({
    this.firstname = '',
    this.lastname = '',
    this.middlename = '',
    this.age = 'adt',
    this.birthdate = '',
    this.doctype = 'A',
    this.docnum = '',
    this.docexp = '',
    this.gender = 'M',
    this.citizen = '',
    this.phone = '',
    this.email = '',
    this.sendEmail = 1,
  });

  PassengerModel copyWith({
    String? firstname,
    String? lastname,
    String? middlename,
    String? age,
    String? birthdate,
    String? doctype,
    String? docnum,
    String? docexp,
    String? gender,
    String? citizen,
    String? phone,
    String? email,
    int? sendEmail,
  }) {
    return PassengerModel(
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      middlename: middlename ?? this.middlename,
      age: age ?? this.age,
      birthdate: birthdate ?? this.birthdate,
      doctype: doctype ?? this.doctype,
      docnum: docnum ?? this.docnum,
      docexp: docexp ?? this.docexp,
      gender: gender ?? this.gender,
      citizen: citizen ?? this.citizen,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      sendEmail: sendEmail ?? this.sendEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstname': firstname,
      'lastname': lastname,
      'middlename': middlename,
      'age': age,
      'birthdate': birthdate,
      'doctype': doctype,
      'docnum': docnum,
      'docexp': docexp,
      'gender': gender,
      'citizen': citizen,
      'phone': phone,
      'email': email,
      'send_email': sendEmail,
    };
  }

  factory PassengerModel.fromJson(Map<String, dynamic> json) {
    return PassengerModel(
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      middlename: json['middlename'] ?? '',
      age: json['age'] ?? 'adt',
      birthdate: json['birthdate'] ?? '',
      doctype: json['doctype'] ?? 'A',
      docnum: json['docnum'] ?? '',
      docexp: json['docexp'] ?? '',
      gender: json['gender'] ?? 'M',
      citizen: json['citizen'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      sendEmail: json['send_email'] ?? 1,
    );
  }

  /// Fuqarolik tanlanganda hujjat turi ham shunga qarab belgilanadi
  /// (RU — xorijiy pasport, qolganlari — ichki hujjat).
  PassengerModel copyWithCitizen(String code) {
    return copyWith(
      citizen: code,
      doctype: code == 'RU'
          ? PassengerConstants.docTypePassport
          : PassengerConstants.docTypeId,
    );
  }

  /// Hujjat skaneri natijasini formaga qo'llaydi: faqat tanilgan (bo'sh
  /// bo'lmagan) maydonlar yoziladi — skaner o'qiy olmagan maydonga
  /// foydalanuvchi kiritgan qiymat o'chib ketmaydi.
  ///
  /// Sanalar forma ko'rinishiga (`dd.MM.yyyy`, №68), hujjat raqami
  /// normallashtiriladi (№69). Hujjat turi skaner bergan turdan emas,
  /// qo'lda kiritishdagi qoida bilan fuqarolikdan olinadi ([copyWithCitizen],
  /// №70) — aks holda skanerlangan UZ yo'lovchi P, qo'lda kiritilgan A olardi.
  PassengerModel mergeScan(UsersModel scan) {
    String pick(String? value, String current) =>
        (value != null && value.trim().isNotEmpty) ? value.trim() : current;
    String pickName(String? value, String current) {
      final name = _sanitizeName(value);
      return name.isNotEmpty ? name : current;
    }

    final merged = copyWith(
      firstname: pickName(scan.firstname, firstname),
      lastname: pickName(scan.lastname, lastname),
      middlename: pickName(scan.middlename, middlename),
      birthdate: pick(PassengerRules.toFormDate(scan.birthdate), birthdate),
      docexp: pick(PassengerRules.toFormDate(scan.docexp), docexp),
      docnum: pick(PassengerRules.normalizeDocnum(scan.docnum), docnum),
      gender: pick(scan.gender, gender),
      citizen: pick(scan.citizen?.toUpperCase(), citizen),
      doctype: pick(scan.doctype, doctype),
    );
    return merged._withDerivedDoctype();
  }

  /// Saqlangan yo'lovchi yoki skaner natijasini formaga qo'llaydi. Jins va
  /// fuqarolik bo'sh kelsa — joriy qiymati saqlanib qoladi. Sanalar serverda
  /// ISO (`1990-03-12`) — forma `dd.MM.yyyy` kutadi (№68). Hujjat turi
  /// fuqarolikdan olinadi (№70).
  PassengerModel copyFromUser(UsersModel user) {
    String keep(String? value, String current) =>
        (value != null && value.isNotEmpty) ? value : current;

    final copied = copyWith(
      firstname: _sanitizeName(user.firstname),
      lastname: _sanitizeName(user.lastname),
      middlename: _sanitizeName(user.middlename),
      birthdate: PassengerRules.toFormDate(user.birthdate),
      docexp: PassengerRules.toFormDate(user.docexp),
      docnum: PassengerRules.normalizeDocnum(user.docnum),
      gender: keep(user.gender, gender),
      citizen: keep(user.citizen?.trim().toUpperCase(), citizen),
      doctype: keep(user.doctype, doctype),
    );
    return copied._withDerivedDoctype();
  }

  /// Fuqarolik ma'lum bo'lsa hujjat turi qo'lda tanlashdagi qoida bilan
  /// ([copyWithCitizen]) belgilanadi.
  PassengerModel _withDerivedDoctype() =>
      citizen.isEmpty ? this : copyWithCitizen(citizen);

  /// Ismni aviachipta ko'rinishiga keltiradi (lotin A–Z, apostrof/raqam
  /// tashlanadi, ichki bo'sh joy bittaga qisqaradi) — `PassengerCubit.sanitizeName`
  /// bilan bir xil qoida.
  static String _sanitizeName(String? value) =>
      PassengerRules.normalizeName(value);

  /// Bron sahifasidagi slotda ko'rsatiladigan "FAMILIYA ISM".
  String get displayName => '$lastname $firstname'.trim();

  /// Barcha majburiy maydonlar to'ldirilganmi
  bool get isValid {
    return citizen.isNotEmpty &&
        docnum.isNotEmpty &&
        docexp.isNotEmpty &&
        firstname.isNotEmpty &&
        lastname.isNotEmpty &&
        birthdate.isNotEmpty &&
        gender.isNotEmpty;
  }

  /// Qaysi maydonlar bo'sh
  List<String> get emptyRequiredFields {
    final fields = <String>[];
    if (citizen.isEmpty) fields.add('citizen');
    if (docnum.isEmpty) fields.add('docnum');
    if (docexp.isEmpty) fields.add('docexp');
    if (firstname.isEmpty) fields.add('firstname');
    if (lastname.isEmpty) fields.add('lastname');
    if (birthdate.isEmpty) fields.add('birthdate');
    if (gender.isEmpty) fields.add('gender');
    return fields;
  }
}

/// Yo'lovchi konstantalari
class PassengerConstants {
  PassengerConstants._();

  // Document types
  static const String docTypePassport = 'P';
  static const String docTypeId = 'A';

  // Gender
  static const String genderMale = 'M';
  static const String genderFemale = 'F';

  // Age types
  static const String ageAdult = 'adt';
  static const String ageChild = 'chd';
  static const String ageInfant = 'inf';
}
