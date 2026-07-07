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

