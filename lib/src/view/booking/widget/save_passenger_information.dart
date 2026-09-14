// Creator: Ravshanov Anzor
// Created: 14.09.2026

import 'package:mysafar_sdk/src/cubit/profile/users_data/users_data_cubit.dart';
import 'package:mysafar_sdk/src/core/tools/sdk_sheets.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/booking/support/country_name_list.dart';

import '../../imports/app_imports.dart';

/// Saqlangan yo'lovchilar ro'yxati — deyarli to'liq balandlikdagi sheet.
/// Qator bosilishi bilan yo'lovchi tanlanadi va sheet yopiladi (alohida
/// "Tanlash" tugmasi yo'q).
void showPassengerPickerBottomSheet({
  required BuildContext context,
  required void Function(UsersModel selectedUser) onSelected,
}) {
  // Tema jonli: showSdkModalBottomSheet ThemeNotifier tinglaydi.
  showSdkModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return FractionallySizedBox(
        heightFactor: 0.94,
        child: Material(
          color: sheetContext.color.primaryContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: BlocProvider(
            create: (_) => UsersDataCubit(needGetUsers: true),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetContext.color.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "saved_passenger_list".tr(),
                            style: sheetContext.textTheme.bodyLarge?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close, size: 24),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _SavedPassengersList(
                      onSelected: (user) {
                        Navigator.pop(sheetContext);
                        onSelected(user);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _SavedPassengersList extends StatelessWidget {
  final void Function(UsersModel user) onSelected;

  const _SavedPassengersList({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersDataCubit, UsersDataState>(
      builder: (context, state) {
        if (state is UsersDataErrorState) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.error, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<UsersDataCubit>().fetchFromServer(),
                    child: Text("retry_search".tr()),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is UsersDataEmptyState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text("no_passenger_info".tr()),
          );
        }

        if (state is UsersDataSuccessState) {
          final users = state.usersModel;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
            itemCount: users.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 60,
              endIndent: 8,
              color: context.color.outline,
            ),
            itemBuilder: (context, index) => _SavedPassengerTile(
              user: users[index],
              onTap: () => onSelected(users[index]),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _SavedPassengerTile extends StatelessWidget {
  final UsersModel user;
  final VoidCallback onTap;

  const _SavedPassengerTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = "${user.lastname ?? ''} ${user.firstname ?? ''}"
        .trim()
        .toUpperCase();
    final citizen = user.citizen ?? '';
    final subtitle = [
      if (citizen.isNotEmpty) getCountry(citizen)["name"][dataLang()] ?? '',
      if ((user.docnum ?? '').isNotEmpty) user.docnum!,
    ].where((e) => e.toString().isNotEmpty).join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.luggage_outlined,
                size: 28, color: ProjectTheme.brandColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.headlineSmall
                          ?.copyWith(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.textTheme.headlineSmall?.color),
          ],
        ),
      ),
    );
  }
}
