import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
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

  PassengerCubit({
    required this.adultCount,
    required this.childCount,
    required this.infantCount,
    required this.trId,
    required this.price,
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
      phone = profileData.phoneNumber ?? '';
    }


    final updatedPassengers = passengers.map((p) => p.copyWith(
      email: email,
      phone: phone,
    )).toList();

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
        final phone = profileData.phoneNumber ?? '';

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
      final updatedPassengers = currentState.passengers
          .map((p) => p.copyWith(email: email))
          .toList();
      emit(currentState.copyWith(
        passengers: updatedPassengers,
        email: email,
      ));
    }
  }

  void updatePhone(String phone) {
    final currentState = state;
    if (currentState is PassengerLoaded) {
      final updatedPassengers = currentState.passengers
          .map((p) => p.copyWith(phone: phone))
          .toList();
      emit(currentState.copyWith(
        passengers: updatedPassengers,
        phone: phone,
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

  PassengerModel _updateField(PassengerModel passenger, String field, String value) {
    switch (field) {
      case 'firstname':
        return passenger.copyWith(firstname: value);
      case 'lastname':
        return passenger.copyWith(lastname: value);
      case 'middlename':
        return passenger.copyWith(middlename: value);
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

      passengers[index] = passengers[index].copyWith(
        firstname: user.firstname?.toUpperCase() ?? '',
        lastname: user.lastname?.toUpperCase() ?? '',
        middlename: user.middlename?.toUpperCase() ?? '',
        birthdate: user.birthdate ?? '',
        docexp: user.docexp ?? '',
        docnum: user.docnum ?? '',
        gender: user.gender ?? PassengerConstants.genderMale,
        citizen: user.citizen ?? '',
        phone: currentState.phone,
        email: currentState.email,
      );

      emit(currentState.copyWith(passengers: passengers));
    }
  }

  void updateCitizen(int index, String code) {
    final docType = code == 'RU'
        ? PassengerConstants.docTypePassport
        : PassengerConstants.docTypeId;

    final currentState = state;
    if (currentState is PassengerLoaded) {
      final passengers = List<PassengerModel>.from(currentState.passengers);
      passengers[index] = passengers[index].copyWith(
        citizen: code,
        doctype: docType,
      );
      emit(currentState.copyWith(passengers: passengers));
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
  String _requiredFieldMessage(String field) {
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
          message: _requiredFieldMessage('email'),
          fieldName: 'email',
        ));
        emit(currentState.copyWith(showErrors: true));
        return;
      }

      if (currentState.phone.isEmpty) {
        emit(PassengerValidationError(
          message: _requiredFieldMessage('phone'),
          fieldName: 'phone',
        ));
        emit(currentState.copyWith(showErrors: true));
        return;
      }

      final emptyField = currentState.firstEmptyField;
      if (emptyField != null) {
        emit(PassengerValidationError(
          message: _requiredFieldMessage(emptyField.$2),
          passengerIndex: emptyField.$1,
          fieldName: emptyField.$2,
        ));
        emit(currentState.copyWith(showErrors: true));
        return;
      }

      emit(const PassengerSaving());

      _storageService.savePassengerFields(
        currentState.passengers,
        currentState.phone,
      );

      _lastLoadedState = currentState;

      emit(PassengerSaved(
        passengersJson: currentState.passengers.map((p) => p.toJson()).toList(),
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
}
