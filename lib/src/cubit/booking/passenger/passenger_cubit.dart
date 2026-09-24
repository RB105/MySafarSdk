import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/api/user_data.dart';
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
import 'passenger_draft_store.dart';
import 'passenger_state.dart';

class PassengerCubit extends Cubit<PassengerState> {
  final PassengerStorageService _storageService;
  final int adultCount;
  final int childCount;
  final int infantCount;

  /// Bron tokeni va narx — reys fonda qayta tekshirilgach ([updateFlight])
  /// tasdiqlangan element qiymatlari bilan almashtiriladi (№36).
  String trId;
  FlightPrice? price;

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
        _draftGeneration = PassengerDraftStore.generation,
        super(const PassengerInitial());

  final int _draftGeneration;

  int get totalPassengers => adultCount + childCount + infantCount;

  /// Fuqarolik berilmaganda standart qiymat (asosiy auditoriya).
  static const String defaultCitizen = 'UZ';

  String get _draftKey =>
      PassengerDraftStore.keyFor(adultCount, childCount, infantCount);

  /// Oxirgi [PassengerLoaded] — sahifa yopilganda qoralama shundan olinadi
  /// (holat o'sha paytda xato / saqlandi bo'lishi mumkin).
  PassengerLoaded? _latestLoaded;

  @override
  void onChange(Change<PassengerState> change) {
    super.onChange(change);
    final next = change.nextState;
    if (next is PassengerLoaded) _latestLoaded = next;
  }

  @override
  Future<void> close() {
    _saveDraft();
    return super.close();
  }

  /// Kiritilganlarni faqat xotiradagi qoralamaga yozadi (diskka emas).
  void _saveDraft() {
    final loaded = _latestLoaded;
    if (loaded == null) return;
    PassengerDraftStore.write(
      generation: _draftGeneration,
      _draftKey,
      PassengerDraft(
        passengers: loaded.passengers,
        email: loaded.email,
        phone: loaded.phone,
        saveToProfile: loaded.saveToProfile,
      ),
    );
  }

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
      // Jins jimgina "Erkak" bo'lib qolmasin — foydalanuvchi o'zi tanlaydi.
      return PassengerModel(age: ageType, gender: '')
          .copyWithCitizen(defaultCitizen);
    });

    String email = '';
    String phone = '';

    final profileData = _getCachedProfile();
    if (profileData != null) {
      email = profileData.email ?? '';
      phone = normalizePhoneDigits(profileData.phoneNumber ?? '');
    }

    // Orqaga qaytib kelinganda (yoki boshqa reys tanlanganda) avval
    // kiritilganlar tiklanadi.
    final draft = PassengerDraftStore.read(_draftKey);
    if (draft != null && draft.passengers.length == passengers.length) {
      if (draft.email.isNotEmpty) email = draft.email;
      if (draft.phone.isNotEmpty) phone = draft.phone;
      for (int i = 0; i < passengers.length; i++) {
        passengers[i] = draft.passengers[i].copyWith(age: passengers[i].age);
      }
    } else if (passengers.isNotEmpty &&
        passengers.first.age == PassengerConstants.ageAdult) {
      passengers[0] = prefillFromUserData(passengers[0], MySafarSdk.userData);
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
      saveToProfile:
          draft != null && draft.passengers.length == passengers.length
              ? draft.saveToProfile
              : const {},
    ));
  }

  /// Host bergan xaridor ma'lumotlari ([MySafarUserData]) bilan yo'lovchining
  /// faqat BO'SH maydonlarini to'ldiradi.
  static PassengerModel prefillFromUserData(
      PassengerModel passenger, MySafarUserData data) {
    String pick(String? value, String current) =>
        current.isEmpty && (value?.trim().isNotEmpty ?? false)
            ? value!.trim()
            : current;
    String pickName(String? value, String current) =>
        current.isEmpty ? PassengerRules.normalizeName(value) : current;
    String date(DateTime? value) => value == null
        ? ''
        : '${value.day.toString().padLeft(2, '0')}.'
            '${value.month.toString().padLeft(2, '0')}.'
            '${value.year.toString().padLeft(4, '0')}';

    var result = passenger.copyWith(
      firstname: pickName(data.firstName, passenger.firstname),
      lastname: pickName(data.lastName, passenger.lastname),
      middlename: pickName(data.middleName, passenger.middlename),
      birthdate: pick(date(data.birthDate), passenger.birthdate),
      docnum: pick(
        PassengerRules.normalizeDocnum(data.documentNumber),
        passenger.docnum,
      ),
      docexp: pick(date(data.documentExpiry), passenger.docexp),
      gender: pick(
        switch (data.gender) {
          MySafarGender.male => PassengerConstants.genderMale,
          MySafarGender.female => PassengerConstants.genderFemale,
          null => null,
        },
        passenger.gender,
      ),
    );
    final citizen = data.citizenship?.trim().toUpperCase() ?? '';
    // Standart "UZ" ni host bergan fuqarolik almashtiradi.
    if (citizen.length == 2 &&
        (result.citizen.isEmpty || result.citizen == defaultCitizen)) {
      result = result.copyWithCitizen(citizen);
    }
    return result;
  }

  /// [index] dan boshqa slotlarda tanlangan hujjat raqamlari — saqlangan
  /// yo'lovchilar ro'yxatida qayta ko'rsatilmaydi.
  Set<String> docnumsUsedExcept(int index) {
    final current = state;
    final loaded = current is PassengerLoaded ? current : _latestLoaded;
    if (loaded == null) return const {};
    return {
      for (int i = 0; i < loaded.passengers.length; i++)
        if (i != index && loaded.passengers[i].docnum.trim().isNotEmpty)
          loaded.passengers[i].docnum.trim().toUpperCase(),
    };
  }

  /// Oddiy email formati tekshiruvi: `nom@domen.zona`.
  static bool isValidEmail(String value) => RegExp(
        // Yumshoq tekshiruv: faqat aniq xatolar (bo'shliq, @ yo'q, domen nuqtasiz)
        // ushlanadi — kirill / IDN manzillar (user@почта.рф) rad etilmaydi.
        r"^[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)*\.[^\s@.]{2,}$",
      ).hasMatch(value.trim());

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
        return passenger.copyWith(
            docnum: PassengerRules.typingDocnum(value));
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

      if (!isValidEmail(currentState.email)) {
        emit(PassengerValidationError(
          message: 'srv_invalid_email'.tr(),
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

      // Bola/chaqaloq bilan kamida bitta 18+ hamroh (№71) — aks holda server
      // bronni `srv_adult_required_for_child` bilan rad etadi.
      final adultIssue = PassengerRules.accompanyingAdultIssue(
        currentState.passengers,
        firstFlight: firstFlightDate,
      );
      if (adultIssue != null) {
        emit(PassengerValidationError(
          message: 'srv_adult_required_for_child'.tr(),
          passengerIndex: adultIssue,
          fieldName: 'birthdate',
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
      // saqlanadi (bron muvaffaqiyatli bo'lgach BookingCreateFlow'da).
      final toSave = [
        for (int i = 0; i < currentState.passengers.length; i++)
          if (currentState.saveToProfile.contains(i))
            currentState.passengers[i],
      ];

      _lastLoadedState = currentState;

      emit(PassengerSaved(
        // Hujjat raqami butun qiymat bo'yicha normallashtiriladi (№69).
        passengersJson: currentState.passengers
            .map((p) => p
                .copyWith(docnum: PassengerRules.normalizeDocnum(p.docnum))
                .toJson())
            .toList(),
        passengersToSaveJson: toSave
            .map((p) => p
                .copyWith(docnum: PassengerRules.normalizeDocnum(p.docnum))
                .toJson())
            .toList(),
        trId: trId,
        price: price,
      ));
    }
  }

  PassengerLoaded? _lastLoadedState;

  /// Fondagi tekshiruvdan o'tgan reys id'si (bron tokeni) va narxi (№36).
  void updateFlight({required String trId, required FlightPrice? price}) {
    this.trId = trId;
    this.price = price;
  }

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
