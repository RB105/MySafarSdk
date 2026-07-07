import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/view/booking/support/country_name_list.dart'; // codes ma'lumotlari shu yerda

class SearchCountryWidget extends StatefulWidget {
  const SearchCountryWidget({super.key});

  @override
  State<SearchCountryWidget> createState() => _SearchCountryWidgetState();
}

class _SearchCountryWidgetState extends State<SearchCountryWidget> {
  List<dynamic> filteredCodes = countryCodes;

  void _filterCities(String query) {
    setState(() {
      filteredCodes = countryCodes.where((country) {
        String countryName = country["name"][dataLang()]
            .toString()
            .toLowerCase();
        return countryName.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox.fromSize(),
        centerTitle: true,
        title: Text(
          "citizenship".tr(),
          style: context.textTheme.bodyMedium,
        ),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.close))
        ],
      ),
      body: Padding(
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
                hintStyle: context.textTheme.headlineMedium,
                border: InputBorder.none,
              ),
              onChanged: _filterCities,
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
                      Navigator.of(context).pop(filteredCodes[index]);
                    },
                    leading: SizedBox(
                      height: 24,
                      width: 32,
                      child: Image.asset(
                        "packages/mysafar_sdk/assets/img/flags/${filteredCodes[index]["code"].toString().toLowerCase()}.png",
                      ),
                    ),
                    title: Text(
                      filteredCodes[index]["name"][dataLang()] ?? "",
                      style: context.textTheme.bodyMedium,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
