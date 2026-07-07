import 'package:dio/dio.dart' show FormData;

class ProfileModel {
  int? id;
  String? profilePicture;
  String? email;
  String? phoneNumber;
  String? nickname;
  String? gender;
  String? firstname;
  String? lastname;
  String? middlename;
  String? brithDate;
  String? dateJoined;
  String? pinfl;
  List<dynamic>? roles;

  ProfileModel({
    this.id,
    this.profilePicture,
    this.email,
    this.phoneNumber,
    this.nickname,
    this.gender,
    this.firstname,
    this.lastname,
    this.middlename,
    this.brithDate,
    this.dateJoined,
    this.pinfl,
    this.roles,
  });

  ProfileModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    profilePicture = json['profile_picture'];
    email = json['email'];
    phoneNumber = json['phone_number'];
    nickname = json['nickname'];
    gender = json['gender'];
    firstname = json['firstname'];
    lastname = json['lastname'];
    middlename = json['middlename'];
    brithDate = json['brith_date'];
    dateJoined = json['date_joined'];
    pinfl = json['pinfl']?.toString();
    roles = List<dynamic>.from(json['roles'] ?? []);
  }

  /// `fromJson` bilan SIMMETRIK — barcha maydonlar yoziladi. Kesh (Hive)
  /// round-trip'ida `id`, `profile_picture`, `gender`, `date_joined`, `roles`
  /// yo'qolmasligi uchun (avval buzuq edi).
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['profile_picture'] = profilePicture;
    data['email'] = email;
    data['phone_number'] = phoneNumber;
    data['nickname'] = nickname;
    data['gender'] = gender;
    data['firstname'] = firstname;
    data['lastname'] = lastname;
    data['middlename'] = middlename;
    data['brith_date'] = brithDate;
    data['date_joined'] = dateJoined;
    data['pinfl'] = pinfl;
    data['roles'] = roles;
    return data;
  }

  FormData toFormData() {
    return FormData.fromMap({
      'email': email,
      'phone_number': phoneNumber,
      'nickname': nickname,
      'gender': gender,
      'firstname': firstname,
      'lastname': lastname,
      'middlename': middlename,
      'brith_date': brithDate,
      'pinfl': pinfl,
    }..removeWhere((key, value) => value == null));
  }

  ProfileModel copyWith({
    int? id,
    String? profilePicture,
    String? email,
    String? phoneNumber,
    String? nickname,
    String? gender,
    String? firstname,
    String? lastname,
    String? middlename,
    String? brithDate,
    String? dateJoined,
    String? pinfl,
    List<dynamic>? roles,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      profilePicture: profilePicture ?? this.profilePicture,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      middlename: middlename ?? this.middlename,
      brithDate: brithDate ?? this.brithDate,
      dateJoined: dateJoined ?? this.dateJoined,
      pinfl: pinfl ?? this.pinfl,
      roles: roles ?? this.roles,
    );
  }

  String getTitle() {
    if (firstname != null && firstname!.isNotEmpty) {
      return firstname!;
    } else if (lastname != null && lastname!.isNotEmpty) {
      return lastname!;
    } else if (email != null && email!.isNotEmpty) {
      return email!;
    } else if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      return phoneNumber!;
    }
    return "";
  }

  String getName() {
    String result = "";
    if (firstname?.isNotEmpty ?? false) {
      result += firstname!;

      if (lastname?.isNotEmpty ?? false) {
        result = "$firstname $lastname";
      }
    }
    if (result.isEmpty && (email?.isNotEmpty ?? false)) {
      result = email!;
    }
    return result;
  }

  String getAuthenticator() {
    if (phoneNumber?.isNotEmpty ?? false) {
      return "+$phoneNumber";
    } else {
      return email ?? "";
    }
  }
}
