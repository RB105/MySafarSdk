import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_input_field_widget.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/visa/ordering_visa_card_page.dart';

class DeliveryLocationPage extends StatefulWidget {
  const DeliveryLocationPage({super.key});

  @override
  State<DeliveryLocationPage> createState() => _DeliveryLocationPageState();
}

class _DeliveryLocationPageState extends State<DeliveryLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final _regionController = TextEditingController();
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();
  final _homeController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _entranceController = TextEditingController();
  final _floorController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) ### ## ##',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final List<String> _regions = const [
    'Toshkent shahri',
    'Toshkent viloyati',
    'Andijon viloyati',
    'Buxoro viloyati',
    'Fargona viloyati',
    'Jizzax viloyati',
    'Namangan viloyati',
    'Navoiy viloyati',
    'Qashqadaryo viloyati',
    'Samarqand viloyati',
    'Sirdaryo viloyati',
    'Surxondaryo viloyati',
    'Xorazm viloyati',
    'Qoraqalpogiston Respublikasi',
  ];

  final List<String> _districts = const [
    'Mirobod tumani',
    'Mirzo Ulugbek tumani',
    'Chilonzor tumani',
    'Yakkasaroy tumani',
    'Yashnobod tumani',
    'Shayxontohur tumani',
    'Yunusobod tumani',
    'Uchtepa tumani',
    'Olmazor tumani',
    'Bektemir tumani',
    'Sergeli tumani',
  ];

  bool _submitted = false;

  bool get _isFormFilled =>
      _regionController.text.trim().isNotEmpty &&
      _districtController.text.trim().isNotEmpty &&
      _streetController.text.trim().isNotEmpty &&
      _homeController.text.trim().isNotEmpty &&
      _phoneFormatter.getUnmaskedText().length == 9;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _controllers => [
        _regionController,
        _districtController,
        _streetController,
        _homeController,
        _apartmentController,
        _entranceController,
        _floorController,
        _phoneController,
      ];

  void _onFieldChanged() {
    setState(() {});
  }

  Future<void> _selectValue({
    required String title,
    required List<String> values,
    required TextEditingController controller,
  }) async {
    final selectedValue = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.color.primaryContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: values.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    title,
                    style: context.textTheme.displayLarge,
                  ),
                );
              }

              final value = values[index - 1];
              return ListTile(
                title: Text(value),
                trailing: controller.text == value
                    ? Icon(Icons.check, color: ProjectTheme.brandColor)
                    : null,
                onTap: () => Navigator.pop(context, value),
              );
            },
          ),
        );
      },
    );

    if (selectedValue == null) return;
    controller.text = selectedValue;
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!_isFormFilled || !(_formKey.currentState?.validate() ?? false)) return;

    final address = [
      _regionController.text.trim(),
      _districtController.text.trim(),
      _streetController.text.trim(),
      'Uy ${_homeController.text.trim()}',
      if (_apartmentController.text.trim().isNotEmpty)
        'Xonadon ${_apartmentController.text.trim()}',
      if (_entranceController.text.trim().isNotEmpty)
        'Podyezd ${_entranceController.text.trim()}',
      if (_floorController.text.trim().isNotEmpty)
        'Qavat ${_floorController.text.trim()}',
      '+998 ${_phoneController.text.trim()}',
    ].join(', ');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderingVisaCardPage(deliveryAddress: address),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (!_submitted) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Majburiy maydon';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    if (!_submitted) return null;
    if (_phoneFormatter.getUnmaskedText().length != 9) {
      return "Telefon raqamini to'liq kiriting";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Yetkazib berish manzilini kiriting')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Form(
            key: _formKey,
            child: Container(
              decoration: BoxDecoration(
                color: context.color.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: context.shadowDown,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SelectionInput(
                    label: 'Hududni tanlang',
                    controller: _regionController,
                    showError: _submitted,
                    validator: _requiredValidator,
                    onTap: () => _selectValue(
                      title: 'Hududni tanlang',
                      values: _regions,
                      controller: _regionController,
                    ),
                  ),
                  context.szBoxHeight12,
                  _SelectionInput(
                    label: 'Tumanni tanlang',
                    controller: _districtController,
                    showError: _submitted,
                    validator: _requiredValidator,
                    onTap: () => _selectValue(
                      title: 'Tumanni tanlang',
                      values: _districts,
                      controller: _districtController,
                    ),
                  ),
                  context.szBoxHeight12,
                  CustomInputField(
                    label: "Ko'cha nomini kiriting",
                    controller: _streetController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    showError: _submitted,
                    validator: _requiredValidator,
                    onChanged: (_) {},
                  ),
                  context.szBoxHeight12,
                  Row(
                    children: [
                      Expanded(
                        child: CustomInputField(
                          label: 'Uy',
                          controller: _homeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textCapitalization: TextCapitalization.none,
                          textInputAction: TextInputAction.next,
                          showError: _submitted,
                          validator: _requiredValidator,
                          onChanged: (_) {},
                        ),
                      ),
                      context.szBoxWidth12,
                      Expanded(
                        child: CustomInputField(
                          label: 'Xonadon',
                          controller: _apartmentController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textCapitalization: TextCapitalization.none,
                          textInputAction: TextInputAction.next,
                          showError: false,
                          onChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                  context.szBoxHeight12,
                  Row(
                    children: [
                      Expanded(
                        child: CustomInputField(
                          label: 'Podyezd',
                          controller: _entranceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textCapitalization: TextCapitalization.none,
                          textInputAction: TextInputAction.next,
                          showError: false,
                          onChanged: (_) {},
                        ),
                      ),
                      context.szBoxWidth12,
                      Expanded(
                        child: CustomInputField(
                          label: 'Qavat',
                          controller: _floorController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textCapitalization: TextCapitalization.none,
                          textInputAction: TextInputAction.next,
                          showError: false,
                          onChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                  context.szBoxHeight16,
                  Text(
                    "Qo'shimcha aloqa raqami",
                    style: context.textTheme.bodySmall,
                  ),
                  context.szBoxHeight8,
                  CustomInputField(
                    label: 'Telefon raqami',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneFormatter],
                    textCapitalization: TextCapitalization.none,
                    textInputAction: TextInputAction.done,
                    showError: _submitted,
                    validator: _phoneValidator,
                    onChanged: (_) {},
                    perfex: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'packages/mysafar_sdk/assets/img/flags/uz.png',
                              width: 22,
                              height: 22,
                              fit: BoxFit.cover,
                            ),
                          ),
                          context.szBoxWidth4,
                          const Text('+998'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFormFilled
                  ? ProjectTheme.brandColor
                  : const Color(0xFF8E8E92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Buyurtma berish',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool showError;
  final VoidCallback onTap;
  final FormFieldValidator<String>? validator;

  const _SelectionInput({
    required this.label,
    required this.controller,
    required this.showError,
    required this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: CustomInputField(
          label: label,
          controller: controller,
          textCapitalization: TextCapitalization.none,
          textInputAction: TextInputAction.next,
          showError: showError,
          validator: validator,
          suffix: const Icon(Icons.keyboard_arrow_down_rounded),
          onChanged: (_) {},
        ),
      ),
    );
  }
}
