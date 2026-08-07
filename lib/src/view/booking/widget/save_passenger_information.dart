import 'dart:io';
import 'package:mysafar_sdk/src/cubit/profile/users_data/users_data_cubit.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';

import '../../imports/app_imports.dart';

void showPassengerPickerBottomSheet({
  required BuildContext context,
  required void Function(UsersModel selectedUser) onSelected,
}) {
  // Embed'da root navigator host'niki — SDK theme yo'qoladi.
  final isDark = context.isDarkMode;
  final sheetTheme = isDark ? ProjectTheme.dark : ProjectTheme.light;
  final sheetColor =
      isDark ? ProjectTheme.backgroundDark : ProjectTheme.cardColorLight;

  showModalBottomSheet(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    backgroundColor: sheetColor,
    context: context,
    isScrollControlled: true,
    useRootNavigator: false,
    builder: (sheetContext) {
      int? selectedIndex;

      return Theme(
        data: sheetTheme,
        child: BlocProvider(
          create: (context) => UsersDataCubit(needGetUsers: true),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return BlocBuilder<UsersDataCubit, UsersDataState>(
                builder: (context, state) {
                  if (state is UsersDataLoadingState) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (state is UsersDataErrorState) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Xatolik: ${state.error}"),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<UsersDataCubit>()
                                  .fetchFromServer();
                            },
                            child: const Text("Qayta urinib ko'rish"),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is UsersDataEmptyState) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text("Ma'lumotlar topilmadi"),
                    );
                  }

                  if (state is UsersDataSuccessState) {
                    final users = state.usersModel;
                    final titleColor = isDark
                        ? ProjectTheme.textColorDark
                        : ProjectTheme.textColorLight;
                    final secondaryColor = isDark
                        ? ProjectTheme.secondaryTextDark
                        : ProjectTheme.secondaryTextLight;
                    final cardColor = isDark
                        ? ProjectTheme.cardColorDark
                        : ProjectTheme.cardColorLight;

                    return SafeArea(
                      top: Platform.isAndroid,
                      bottom: Platform.isAndroid,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "saved_passenger_list".tr(),
                                    style:
                                        context.textTheme.bodyLarge?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.close,
                                    size: 24,
                                    color: titleColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 360,
                              child: ListView.separated(
                                itemCount: users.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  final isSelected = selectedIndex == index;

                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        selectedIndex = index;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? ProjectTheme.brandColor
                                              : (isDark
                                                  ? ProjectTheme.borderDark
                                                  : ProjectTheme.borderLight),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                        boxShadow: isDark
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: const Color(0x80C6C7C9)
                                                      .withValues(alpha: 0.35),
                                                  offset: const Offset(0, 2),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    "${user.firstname} ${user.lastname}",
                                                    style: context
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: titleColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    user.docnum ?? '',
                                                    style: context
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: secondaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_circle,
                                                color: ProjectTheme.success,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: ProjectTheme.brandColor,
                                          width: 1.5),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: Text(
                                      "cancel".tr(),
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: ProjectTheme.brandColor,
                                              fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: selectedIndex != null
                                        ? () {
                                            Navigator.pop(context);
                                            onSelected(users[selectedIndex!]);
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: selectedIndex != null
                                          ? ProjectTheme.brandColor
                                          : const Color.fromRGBO(
                                              0, 87, 190, 0.4),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      "choice".tr(),
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ),
      );
    },
  );
}
