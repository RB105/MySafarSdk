// ignore_for_file: no_logic_in_create_state

import 'package:country_list_pick/country_selection_theme.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:country_list_pick/selection_list.dart';
import 'package:country_list_pick/support/code_countries_en.dart';
import 'package:country_list_pick/support/code_country.dart';
import 'package:country_list_pick/support/code_countrys.dart';
import 'package:flutter/material.dart';

class CountryListPick extends StatefulWidget {
  const CountryListPick(
      {super.key,
      this.onChanged,
      this.initialSelection,
      this.appBar,
      this.pickerBuilder,
      this.countryBuilder,
      this.theme,
      this.useUiOverlay = true,
      this.useSafeArea = false});

  final String? initialSelection;
  final ValueChanged<CountryCode?>? onChanged;
  final PreferredSizeWidget? appBar;
  final Widget Function(BuildContext context, CountryCode? countryCode)?
      pickerBuilder;
  final CountryTheme? theme;
  final Widget Function(BuildContext context, CountryCode countryCode)?
      countryBuilder;
  final bool useUiOverlay;
  final bool useSafeArea;

  @override
  State<CountryListPick> createState() {
    List<Map> jsonList =
        theme?.showEnglishName ?? true ? countriesEnglish : codes;

    List elements = jsonList
        .map((s) => CountryCode(
              name: s['name'],
              code: s['code'],
              dialCode: s['dial_code'],
              flagUri: 'flags/${s['code'].toLowerCase()}.png',
            ))
        .toList();
    return _CountryListPickState(elements);
  }
}

class _CountryListPickState extends State<CountryListPick> {
  CountryCode? selectedItem;
  List elements = [];

  _CountryListPickState(this.elements);

  @override
  void initState() {
    if (widget.initialSelection != null) {
      selectedItem = elements.firstWhere(
          (e) =>
              (e.code.toUpperCase() ==
                  widget.initialSelection!.toUpperCase()) ||
              (e.dialCode == widget.initialSelection),
          orElse: () => elements[0] as CountryCode);
    } else {
      selectedItem = elements[0];
    }

    super.initState();
  }

  void _awaitFromSelectScreen(BuildContext context, PreferredSizeWidget? appBar,
      CountryTheme? theme) async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectionList(
            elements,
            selectedItem,
            appBar: widget.appBar ??
                AppBar(
                  backgroundColor:
                      Theme.of(context).appBarTheme.backgroundColor,
                  title: const Text("Select Country"),
                ),
            countryBuilder: widget.countryBuilder,
            useUiOverlay: widget.useUiOverlay,
            useSafeArea: widget.useSafeArea,
            theme: widget.theme,
          ),
        ));

    setState(() {
      selectedItem = result ?? selectedItem;
      widget.onChanged!(result ?? selectedItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          _awaitFromSelectScreen(context, widget.appBar, widget.theme);
        },
        child: SizedBox(
          width: double.infinity,
          height: context.height * 0.06,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                width: 1.5,
                color: context.color.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.pickerBuilder != null
                ? widget.pickerBuilder!(context, selectedItem)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        if (widget.theme?.isShowCode ?? true == true)
                          Flexible(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(selectedItem.toString()),
                            ),
                          ),
                        if (widget.theme?.isShowTitle ?? true == true)
                          Flexible(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                selectedItem!.toCountryStringOnly(),
                                style: context.textTheme.bodyLarge?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ),
                        if (widget.theme?.isDownIcon ?? true == true)
                          const Flexible(
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 24,
                            ),
                          )
                      ],
                    ),
                  ),
          ),
        ));
  }
}
