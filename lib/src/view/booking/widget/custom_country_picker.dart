import 'dart:io';

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;

import '../../../core/widgets/county_pick/src/country_code_model.dart';
import '../../../core/widgets/county_pick/src/country_codes.dart';

class CountryListWidget extends StatefulWidget {


  const CountryListWidget({
    super.key,
  });

  @override
  State<CountryListWidget> createState() => _CountryListWidgetState();
}

class _CountryListWidgetState extends State<CountryListWidget> {
  List<dynamic> filteredCodes = codes;

  void _filterCountries(String query) {
    setState(() {
      filteredCodes = codes.where((country) {
        String countryName = country["country_name"]
            .toString()
            .toLowerCase();
        return countryName.contains(query.toLowerCase());
      }).toList();
    });
  }
  CountryCode _mapToCountryCode(Map<String, dynamic> countryMap) {
    return CountryCode(
      name: countryMap["country_name"]?? "",
      code: countryMap["iso_code"] ?? "",
      dialCode: countryMap["country_code"] ?? "",
      phone_format: countryMap["phone_mask"] ?? "## ### ## ##",
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox.fromSize(),
        centerTitle: true,
        title: Text(
          "select_country".tr(),
          style: context.textTheme.bodyMedium,
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.close),
          )
        ],
      ),
      body: SafeArea(
      top: Platform.isAndroid,
      bottom: Platform.isAndroid,
        child: Padding(
          padding: context.k16horizontalPadding,
          child: Column(
            children: [
              context.szBoxHeight16,
              TextFormField(
                autofocus: true,
                keyboardType: TextInputType.name,
                style: context.textTheme.bodyMedium,
                decoration: InputDecoration(
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 12.0, horizontal: 12),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(Assets.iconsSearchIcon),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                    BorderSide(color: context.color.outline, width: 1),
                  ),
                  hintText: "search_country".tr(),
                  hintStyle: context.textTheme.headlineMedium,
                  border: InputBorder.none,
                ),
                onChanged: _filterCountries,
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(0.0),
                  shrinkWrap: true,
                  itemCount: filteredCodes.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
        
                        Navigator.of(context).pop(_mapToCountryCode(filteredCodes[index]));
                      },
                      leading:Text(
                       "+${ filteredCodes[index]["country_code"] ?? ""}",
                        style: context.textTheme.bodyMedium,
                      ),
                      title: Text(
                        filteredCodes[index]["country_name"] ?? "",
                        style: context.textTheme.bodyMedium,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}