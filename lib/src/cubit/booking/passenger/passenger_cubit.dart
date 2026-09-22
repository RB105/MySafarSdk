import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/tools/phone_format.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/model/local/passenger_rules.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice;
import 'package:mysafar_sdk/src/model/remote/profile/profile_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/service/passenger/passenger_storage_service.dart';
import 'package:mysafar_sdk/src/service/profile/profile_cache.dart';
import 'passenger_state.dart';

class PassengerCubit extends Cubit<PassengerState> {
  final PassengerStorageService _storageService;
  final int adultCount;
  final int childCount;
  final int infantCount;
  final String trId;
  final FlightPrice? price;

  /// Birinchi uchish / oxirgi qo'nish — yosh toifasi va pasport muddati
  /// shular bo'yicha tekshiriladi ([PassengerRules]).
  final DateTime? firstFlightDate;
  final DateTime? lastFlightDate;

  PassengerCubit({
    required this.adultCount,
    required this.childCount,
    required this.infantCount,
    required this.trId,
    required this.price,
    this.firstFlightDate,
    this.lastFlightDate,
    PassengerStorageService? storageService,
  })  : _storageService = storageService ?? PassengerStorageService(),
        super(const PassengerInitial());

  int get totalPassengers => adultCount + childCount + infantCount;

  void initialize() {
    final passengers = List.generate(totalPassengers, (index) {
      String ageType;
      if (adultCount > index) {
        ageType = PassengerConstants.ageAdult;
      } else if ((adultCount + childCount) > index) {
        ageType = PassengerConstants.ageChild;
      } else {
        ageType = PassengerConstants.ageInfant;
      }
      return PassengerModel(age: ageType);
    });

    String email = '';
    String phone = '';

    final profileData = _getCachedProfile();
    if (profileData != null) {
      email = profileData.email ?? '';
      phone = normalizePhoneDigits(profileData.phoneNumber ?? '');
    }

    final updatedPassengers = passengers
        .map((p) => p.copyWith(
              email: email,
              phone: phone,
            ))
        .toList();

    emit(PassengerLoaded(
      passengers: updatedPassengers,
      email: email,
      phone: phone,
    ));
  }

  ProfileModel? _getCachedProfile() {
    final cachedData = ProfileCache().read();
    if (cachedData != null) {
      try {
        return ProfileModel.fromJson(cachedData);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void loadProfileData() {
    final currentState = state;
    if (currentState is PassengerLoaded) {
      final profileData = _getCachedProfile();
      if (profileData != null) {
        final email = profileData.email ?? '';
        final phone = normalizePhoneDigits(profileData.phoneNumber ?? '');

        final updatedPassengers = currentState.passengers
            .map((p) => p.copyWith(email: email, phone: phone))
            .toList();

        emit(currentState.copyWith(
          passengers: updatedPassengers,
          email: email,
          phone: phone,
        ));
      }
    }
  }

  void updateEmail(String email) {
    final currentState = state;
    if (currentState is PassengerLoaded) {
      final updatedPassengers =
          currentState.passengers.map((p) => p.copyWith(email: email)).toList();
      emit(currentState.copyWith(
        passengers: updatedPassengers,
        email: email,
      ));
    }
  }

  void updatePhone(String phone) {
    final currentState = state;
    if (currentState is PassengerLoaded) {
      final normalized = normalizePhoneDigits(phone);
      final updatedPassengers = currentState.passengers
          .map((p) => p.copyWith(phone: normalized))
          .toList();
      emit(currentState.copyWith(
        passengers: updatedPassengers,
        phone: normalized,
      ));
    }
  }

  void updatePassengerField(int index, String field, String value) {
    final currentState = state;
    if (currentState is PassengerLoaded) {
      final passengers = List<PassengerModel>.from(currentState.passengers);

      passengers[index] = _updateField(passengers[index], field, value);

      emit(currentState.copyWith(passengers: passengers));
    }
  }

  PassengerModel _updateField(
      PassengerModel passenger, String field, String value) {
    switch (field) {
      case 'firstname':
        return passenger.copyWith(firstname: sanitizeName(value));
      case 'lastname':
        return passenger.copyWith(lastname: sanitizeName(value));
      case 'middlename':
        return passenger.copyWith(middlename: sanitizeName(value));
      case 'birthdate':
        return passenger.copyWith(birthdate: value);
      case 'docnum':
        return passenger.copyWith(docnum: value);
      case 'docexp':
        return passenger.copyWith(docexp: value);
      case 'gender':
        return passenger.copyWith(gender: value);
      case 'citizen':
        return passenger.copyWith(citizen: value);
      case 'doctype':
        return passenger.copyWith(doctype: value);
      default:
        return passenger;
    }
  }

  void updatePassengerFromUser(int index, UsersModel user) {
    final currentState = state;
    if (currentState is PassengerLoaded) {
      final passengers = List<PassengerModel>.from(currentState.passengers);
      passengers[index] = passengers[index].copyFromUser(user).copyWith(
            phone: currentState.phone,
            email: currentState.email,
          );
      emit(currentState.copyWith(passengers: passengers));
    }
  }

  void updateCitizen(int index, String code) {
    final currentState = state;
    if (currentState is PassengerLoaded) {
      final passengers = List<PassengerModel>.from(currentState.passengers);
      passengers[index] = passengers[index].copyWithCitizen(code);
      emit(currentState.copyWith(passengers: passengers));
    }
  }

  /// Alohida "Yo'lovchi ma'lumotlari" sahifasida to'ldirilgan yo'lovchini
  /// slotga yozadi. Yosh turi, email va telefon bron sahifasiniki qoladi.
  void setPassenger(int index, PassengerModel passenger,
      {required bool saveToProfile}) {
    final currentState = state;
    if (currentState is PassengerLoaded) {
      final passengers = List<PassengerModel>.from(currentState.passengers);
      final existing = passengers[index];
      passengers[index] = passenger.copyWith(
        age: existing.age,
        email: currentState.email,
        phone: currentState.phone,
      );
      final saveSet = Set<int>.from(currentState.saveToProfile);
      saveToProfile ? saveSet.add(index) : saveSet.remove(index);
      emit(currentState.copyWith(
          passengers: passengers, saveToProfile: saveSet));
    }
  }

  void showErrors() {
    final currentState = state;
    if (currentState is PassengerLoaded) {
      emit(currentState.copyWith(showErrors: true));
    }
  }

  /// Bo'sh maydon nomini tegishli tarjima yorlig'iga bog'lab, joriy tildagi
  /// "... kiritilmagan" xabarini qaytaradi (barcha tillarda ishlaydi).
  static String requiredFieldMessage(String field) {
    final labelKey = switch (field) {
      'email' => 'email',
      'phone' => 'phone',
      'firstname' => 'first_name',
      'lastname' => 'last_name',
      'middlename' => 'father',
      'birthdate' => 'birth_date',
      'docnum' => 'passport_data',
      'docexp' => 'passport_validity',
      'gender' => 'gender',
      'citizen' => 'citizenship',
      _ => field,
    };
    return 'field_not_filled'.tr(namedArgs: {'field': labelKey.tr()});
  }

  void validateAndSave() {
    final currentState = state;
    if (currentState is PassengerLoaded) {
      emit(currentState.copyWith(showErrors: true));

      // Email va telefon tekshirish
      if (currentState.email.isEmpty) {
        emit(PassengerValidationError(
          message: requiredFieldMessage('email'),
          fieldName: 'email',
        ));
        emit(currentState.copyWith(showErrors: true));
        return;
      }

      if (currentState.phone.isEmpty) {
        emit(PassengerValidationError(
          message: requiredFieldMessage('phone'),
          fieldName: 'phone',
        ));
        emit(currentState.copyWith(showErrors: true));
        return;
      }

      // Telefon endi tahrirlanadi — chala kiritilgan raqam bilan bron qilinmaydi.
      if (currentState.phone.length < kMinPhoneDigits) {
        emit(PassengerValidationError(
          message: 'enter_full_phone_number'.tr(),
          fieldName: 'phone',
        ));
        emit(currentState.copyWith(showErrors: true));
        return;
      }

      final emptyField = currentState.firstEmptyField;
      if (emptyField != null) {
        emit(PassengerValidationError(
          message: requiredFieldMessage(emptyField.$2),
          passengerIndex: emptyField.$1,
          fieldName: emptyField.$2,
        ));
        emit(currentState.copyWith(showErrors: true));
        return;
      }

      // Aviakompaniya qoidalari (yosh toifasi, pasport muddati, lotin ism) —
      // server bronni rad etishidan oldin.
      for (int i = 0; i < currentState.passengers.length; i++) {
        final issues = PassengerRules.invalidFields(
          currentState.passengers[i],
          firstFlight: firstFlightDate,
          lastFlight: lastFlightDate,
        );
        if (issues.isEmpty) continue;
        emit(PassengerValidationError(
          message: issues.first.$2.tr(),
          passengerIndex: i,
          fieldName: issues.first.$1,
        ));
        emit(currentState.copyWith(showErrors: true));
        return;
      }

      emit(const PassengerSaving());

      _storageService.savePassengerFields(
        currentState.passengers,
        currentState.phone,
      );

      // Profilga faqat "Saqlangan yo'lovchilarga qo'shish" yoqilganlar
      // saqlanadi (bron muvaffaqiyatli bo'lgach BookingCreatePage'da).
      final toSave = [
        for (int i = 0; i < currentState.passengers.length; i++)
          if (currentState.saveToProfile.contains(i))
            currentState.passengers[i],
      ];

      _lastLoadedState = currentState;

      emit(PassengerSaved(
        passengersJson: currentState.passengers.map((p) => p.toJson()).toList(),
        passengersToSaveJson: toSave.map((p) => p.toJson()).toList(),
        trId: trId,
        price: price,
      ));
    }
  }

  PassengerLoaded? _lastLoadedState;

  void restoreState() {
    if (_lastLoadedState != null) {
      emit(_lastLoadedState!);
    }
  }

  List<String> getSuggestions(String key) {
    return _storageService.getSuggestions(key);
  }

  List<dynamic> getCachedUsers() {
    return _storageService.getCachedUsers();
  }

  /// Ism maydonlaridan raqam va bo'sh joylarni olib tashlaydi.
  static String sanitizeName(String? value) =>
      PassengerRules.normalizeName(value);
}
