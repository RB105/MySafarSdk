import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice;

sealed class PassengerState {
  const PassengerState();
}

class PassengerInitial extends PassengerState {
  const PassengerInitial();
}

class PassengerLoaded extends PassengerState {
  final List<PassengerModel> passengers;
  final String email;
  final String phone;
  final bool showErrors;

  /// "Saqlangan yo'lovchilarga qo'shish" yoqilgan yo'lovchilar indekslari.
  final Set<int> saveToProfile;

  const PassengerLoaded({
    required this.passengers,
    this.email = '',
    this.phone = '',
    this.showErrors = false,
    this.saveToProfile = const {},
  });

  PassengerLoaded copyWith({
    List<PassengerModel>? passengers,
    String? email,
    String? phone,
    bool? showErrors,
    Set<int>? saveToProfile,
  }) {
    return PassengerLoaded(
      passengers: passengers ?? this.passengers,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      showErrors: showErrors ?? this.showErrors,
      saveToProfile: saveToProfile ?? this.saveToProfile,
    );
  }

  bool get isValid {
    if (email.isEmpty || phone.isEmpty) return false;
    return passengers.every((p) => p.isValid);
  }

  (int passengerIndex, String fieldName)? get firstEmptyField {
    for (int i = 0; i < passengers.length; i++) {
      final emptyFields = passengers[i].emptyRequiredFields;
      if (emptyFields.isNotEmpty) {
        return (i, emptyFields.first);
      }
    }
    return null;
  }
}

class PassengerValidationError extends PassengerState {
  final String message;
  final int? passengerIndex;
  final String? fieldName;

  const PassengerValidationError({
    required this.message,
    this.passengerIndex,
    this.fieldName,
  });
}

class PassengerSaving extends PassengerState {
  const PassengerSaving();
}

class PassengerSaved extends PassengerState {
  final List<Map<String, dynamic>> passengersJson;

  /// Bron muvaffaqiyatli bo'lgach profilga saqlanadigan yo'lovchilar.
  final List<Map<String, dynamic>> passengersToSaveJson;
  final String trId;
  final FlightPrice? price;

  const PassengerSaved({
    required this.passengersJson,
    this.passengersToSaveJson = const [],
    required this.trId,
    required this.price,
  });
}
