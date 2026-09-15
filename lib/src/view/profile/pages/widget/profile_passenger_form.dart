import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/widgets/response_state.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_cubit.dart';
import 'package:mysafar_sdk/src/cubit/profile/users_data/users_data_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_card_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_controller.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_date_picker.dart';
import 'package:mysafar_sdk/src/view/booking/widget/paymentbottomsheet.dart'
    show showCitySearchPicker;
import 'package:mysafar_sdk/src/view/booking/widget/scan_page.dart'
    show showDocumentScanner;
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart'
    show BookingCard;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/widget/profile_app_bar.dart';

/// Profildagi saqlangan yo'lovchini qo'shish ([initial] `null`) yoki
/// tahrirlash formasi — bron sahifasidagi [PassengerCardWidget] bilan bir xil
/// ko'rinish. Muvaffaqiyatli saqlansa/o'chirilsa sahifa `true` bilan yopiladi.
class ProfilePassengerForm extends StatefulWidget {
  const ProfilePassengerForm({super.key, this.initial});

  final UsersModel? initial;

  @override
  State<ProfilePassengerForm> createState() => _ProfilePassengerFormState();
}

class _ProfilePassengerFormState extends State<ProfilePassengerForm> {
  final _scrollController = ScrollController();
  final _controller = PassengerController();

  final _birthdateFormatter = MaskTextInputFormatter(
    type: MaskAutoCompletionType.lazy,
    mask: '##.##.####',
  );
  final _docexpFormatter = MaskTextInputFormatter(
    type: MaskAutoCompletionType.lazy,
    mask: '##.##.####',
  );

  final _citizenKey = GlobalKey();
  final _docnumKey = GlobalKey();
  final _docexpKey = GlobalKey();
  final _firstnameKey = GlobalKey();
  final _lastnameKey = GlobalKey();
  final _middlenameKey = GlobalKey();
  final _birthdateKey = GlobalKey();
  final _genderKey = GlobalKey();

  late final PassengerModel _initialPassenger = widget.initial == null
      ? const PassengerModel()
      : _fromUser(widget.initial!);
  late PassengerModel _passenger = _initialPassenger;

  bool _showErrors = false;
  bool _loaderOpen = false;
  bool _isDeleting = false;

  bool get _isEdit => widget.initial != null;

  bool get _hasChanges {
    final a = _payloadFields(_passenger);
    final b = _payloadFields(_initialPassenger);
    return a.entries.any((e) => e.value != b[e.key]);
  }

  @override
  void initState() {
    super.initState();
    _fillControllers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Model <-> forma
  // ---------------------------------------------------------------------------

  /// Server sanani `yyyy-MM-dd` yoki `dd.MM.yyyy` ko'rinishida qaytarishi
  /// mumkin — forma doim `dd.MM.yyyy` bilan ishlaydi.
  static String _toFormDate(String? raw) {
    final value = (raw ?? '').trim();
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    if (iso != null) return '${iso[3]}.${iso[2]}.${iso[1]}';
    return value;
  }

  /// `dd.MM.yyyy` → API formati `yyyy-MM-dd`; noto'g'ri bo'lsa `null`.
  static String? _toApiDate(String raw) {
    final value = raw.trim();
    if (!RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(value)) return null;
    try {
      final date = DateFormat('dd.MM.yyyy').parseStrict(value);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (_) {
      return null;
    }
  }

  static PassengerModel _fromUser(UsersModel user) {
    final passenger = const PassengerModel().copyFromUser(user);
    return passenger.copyWith(
      birthdate: _toFormDate(user.birthdate),
      docexp: _toFormDate(user.docexp),
    );
  }

  static Map<String, String> _payloadFields(PassengerModel p) => {
        'firstname': p.firstname.trim(),
        'lastname': p.lastname.trim(),
        'middlename': p.middlename.trim(),
        'birthdate': p.birthdate.trim(),
        'docnum': p.docnum.trim(),
        'docexp': p.docexp.trim(),
        'gender': p.gender,
        'citizen': p.citizen,
      };

  void _fillControllers() {
    _controller.firstnameController.text = _passenger.firstname;
    _controller.lastnameController.text = _passenger.lastname;
    _controller.middlenameController.text = _passenger.middlename;
    _controller.birthdateController.text = _passenger.birthdate;
    _controller.docnumController.text = _passenger.docnum;
    _controller.docexpController.text = _passenger.docexp;
  }

  void _updateField(String field, String value) {
    setState(() {
      _passenger = switch (field) {
        'firstname' =>
          _passenger.copyWith(firstname: PassengerCubit.sanitizeName(value)),
        'lastname' =>
          _passenger.copyWith(lastname: PassengerCubit.sanitizeName(value)),
        'middlename' =>
          _passenger.copyWith(middlename: PassengerCubit.sanitizeName(value)),
        'birthdate' => _passenger.copyWith(birthdate: value),
        'docnum' => _passenger.copyWith(docnum: value),
        'docexp' => _passenger.copyWith(docexp: value),
        'gender' => _passenger.copyWith(gender: value),
        _ => _passenger,
      };
    });
  }

  void _applyUser(UsersModel user) {
    setState(() {
      final scanned = _fromUser(user);
      _passenger = scanned.copyWith(
        gender: scanned.gender.isEmpty ? _passenger.gender : null,
        citizen: scanned.citizen.isEmpty ? _passenger.citizen : null,
      );
    });
    _fillControllers();
  }

  // ---------------------------------------------------------------------------
  // Tanlagichlar
  // ---------------------------------------------------------------------------

  Future<void> _openDocumentScanner() async {
    final scan = await showDocumentScanner(context);
    if (!mounted || scan == null) return;
    // Faqat tanilgan maydonlar yoziladi — o'qilmaganlari saqlanib qoladi.
    setState(() => _passenger = _passenger.mergeScan(scan));
    _fillControllers();
  }

  Future<void> _showCitizenPicker() async {
    final result = await showCitySearchPicker(
      context,
      selectedCode: _passenger.citizen,
    );
    if (!mounted || result == null) return;
    setState(() {
      _passenger = _passenger.copyWithCitizen(result['code'] ?? '');
    });
    _controller.docnumFocus.requestFocus();
  }

  void _showDatePicker({required bool isDocexp}) {
    PassengerDatePicker.show(
      context: context,
      controller: isDocexp
          ? _controller.docexpController
          : _controller.birthdateController,
      isFutureOnly: isDocexp,
      title: isDocexp ? 'passport_validity'.tr() : 'birth_date'.tr(),
      onDateSelected: (date) => _updateField(
        isDocexp ? 'docexp' : 'birthdate',
        DateFormat('dd.MM.yyyy').format(date),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigatsiya maydonlar bo'ylab
  // ---------------------------------------------------------------------------

  static const List<String> _formOrder = [
    'lastname',
    'firstname',
    'middlename',
    'birthdate',
    'gender',
    'citizen',
    'docnum',
    'docexp',
  ];

  /// Bo'sh yoki noto'g'ri formatdagi maydonlar (forma tartibida).
  List<String> get _invalidFields {
    final invalid = _passenger.emptyRequiredFields.toSet();
    if (_passenger.birthdate.isNotEmpty &&
        _toApiDate(_passenger.birthdate) == null) {
      invalid.add('birthdate');
    }
    if (_passenger.docexp.isNotEmpty && _toApiDate(_passenger.docexp) == null) {
      invalid.add('docexp');
    }
    return _formOrder.where(invalid.contains).toList();
  }

  FocusNode? _focusNodeByField(String field) => switch (field) {
        'lastname' => _controller.lastnameFocus,
        'firstname' => _controller.firstnameFocus,
        'middlename' => _controller.middlenameFocus,
        'birthdate' => _controller.birthdateFocus,
        'docnum' => _controller.docnumFocus,
        'docexp' => _controller.docexpFocus,
        _ => null,
      };

  GlobalKey? _keyByField(String field) => switch (field) {
        'citizen' => _citizenKey,
        'docnum' => _docnumKey,
        'docexp' => _docexpKey,
        'firstname' => _firstnameKey,
        'lastname' => _lastnameKey,
        'middlename' => _middlenameKey,
        'birthdate' => _birthdateKey,
        'gender' => _genderKey,
        _ => null,
      };

  /// Klaviaturadagi "keyingi": keyingi bo'sh majburiy maydonga o'tadi;
  /// fuqarolik bo'sh bo'lsa tanlagich ochiladi.
  void _goToNextEmptyField() {
    final order = <(String, FocusNode)>[
      ('lastname', _controller.lastnameFocus),
      ('firstname', _controller.firstnameFocus),
      ('middlename', _controller.middlenameFocus),
      ('birthdate', _controller.birthdateFocus),
      ('citizen', _controller.citizenFocus),
      ('docnum', _controller.docnumFocus),
      ('docexp', _controller.docexpFocus),
    ];
    final empty = _passenger.emptyRequiredFields.toSet();
    final focused = FocusManager.instance.primaryFocus;
    final current = order.indexWhere((e) => e.$2 == focused);

    for (var i = current + 1; i < order.length; i++) {
      final (field, node) = order[i];
      if (!empty.contains(field)) continue;
      if (field == 'citizen') {
        FocusManager.instance.primaryFocus?.unfocus();
        _showCitizenPicker();
      } else {
        node.requestFocus();
      }
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _scrollToField(GlobalKey key) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final fieldContext = key.currentContext;
    if (fieldContext == null || !fieldContext.mounted) return;
    await Scrollable.ensureVisible(
      fieldContext,
      alignment: 0.2,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ---------------------------------------------------------------------------
  // Saqlash / o'chirish
  // ---------------------------------------------------------------------------

  void _submit(BuildContext blocContext) {
    FocusManager.instance.primaryFocus?.unfocus();
    final invalid = _invalidFields;
    if (invalid.isNotEmpty) {
      setState(() => _showErrors = true);
      final first = invalid.first;
      final key = _keyByField(first);
      if (key != null) {
        _scrollToField(key).then((_) {
          if (mounted) _focusNodeByField(first)?.requestFocus();
        });
      }
      return;
    }

    final params = {
      ..._payloadFields(_passenger),
      'birthdate': _toApiDate(_passenger.birthdate)!,
      'docexp': _toApiDate(_passenger.docexp)!,
      'docnum': _passenger.docnum.trim().toUpperCase(),
    };
    final cubit = blocContext.read<UsersDataCubit>();
    if (_isEdit) {
      cubit.updateUserdata(params: params, id: widget.initial!.id ?? 0);
    } else {
      cubit.createUser(params: params);
    }
  }

  void _confirmDelete(BuildContext blocContext) {
    ProjectDialogs.showDeleteConfirmationSheet(
      context,
      onPressed: () {
        _isDeleting = true;
        _loaderOpen = true;
        ProjectDialogs.showDeleteDialog(context);
        blocContext
            .read<UsersDataCubit>()
            .deleteUserdata(id: widget.initial!.id ?? 0);
      },
    );
  }

  void _showLoader() {
    _loaderOpen = true;
    showSdkLoader(context);
  }

  void _hideLoader() {
    if (!_loaderOpen) return;
    _loaderOpen = false;
    Navigator.of(context).pop();
  }

  void _onStateChanged(BuildContext context, UsersDataState state) {
    if (state is UsersDataLoadingState) {
      if (!_loaderOpen) _showLoader();
      return;
    }
    _hideLoader();
    final wasDeleting = _isDeleting;
    _isDeleting = false;
    if (state is UsersDataCreateState && wasDeleting) {
      // O'chirilgan yo'lovchi uchun "saqlandi" sheet'i noto'g'ri — ro'yxatga
      // qaytamiz va qisqa xabar ko'rsatamiz.
      ProjectDialogs.showCustomToast(this.context, 'successful'.tr());
      Navigator.of(this.context).pop(true);
    } else if (state is UsersDataCreateState) {
      ProjectDialogs.showCustomBottomSheet(this.context, onConfirm: () {});
    } else if (state is UsersDataErrorState) {
      ResponseState.errorState(state.error, this.context);
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersDataCubit(),
      child: BlocListener<UsersDataCubit, UsersDataState>(
        listener: _onStateChanged,
        child: Builder(
          builder: (blocContext) => Scaffold(
            appBar: sdkBodyColoredAppBar(
              context,
              title: (_isEdit ? 'passenger_data' : 'add_new_passenger').tr(),
              subtitle: _isEdit ? _initialPassenger.displayName : null,
            ),
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PassengerCardWidget(
                      passenger: _passenger,
                      controller: _controller,
                      showErrors: _showErrors,
                      // Profilda saqlangan yo'lovchidan to'ldirish ma'nosiz —
                      // faqat skaner kartasi ko'rsatiladi.
                      cachedUsers: const [],
                      getSuggestions: (_) => const [],
                      onFieldChanged: _updateField,
                      onUserSelected: _applyUser,
                      onScanTap: _openDocumentScanner,
                      onCitizenTap: _showCitizenPicker,
                      onDocexpCalendarTap: () =>
                          _showDatePicker(isDocexp: true),
                      onBirthdateCalendarTap: () =>
                          _showDatePicker(isDocexp: false),
                      onNextField: _goToNextEmptyField,
                      docexpFormatter: _docexpFormatter,
                      birthdateFormatter: _birthdateFormatter,
                      citizenKey: _citizenKey,
                      docnumKey: _docnumKey,
                      docexpKey: _docexpKey,
                      firstnameKey: _firstnameKey,
                      lastnameKey: _lastnameKey,
                      middlenameKey: _middlenameKey,
                      birthdateKey: _birthdateKey,
                      genderKey: _genderKey,
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 20),
                      _DeletePassengerCard(
                        onTap: () => _confirmDelete(blocContext),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: MainButtonWidget(
                  title: 'save_info'.tr(),
                  analyticsId: _isEdit
                      ? 'profile_passenger_update'
                      : 'profile_passenger_create',
                  onTap: _isEdit && !_hasChanges
                      ? null
                      : () => _submit(blocContext),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeletePassengerCard extends StatelessWidget {
  const _DeletePassengerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color red = isDark ? const Color(0xFFFF6B61) : ProjectTheme.error;
    return BookingCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ProjectTheme.error
                      .withValues(alpha: isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(
                  Assets.iconsProfileTrashIcon,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(red, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'delete_info'.tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
