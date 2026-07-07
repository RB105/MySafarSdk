import 'dart:io';
import 'package:mysafar_sdk/src/cubit/profile/users_data/users_data_cubit.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';

import '../../imports/app_imports.dart';

void showPassengerPickerBottomSheet({
  required BuildContext context,
  required void Function(UsersModel selectedUser) onSelected,
}) {
  showModalBottomSheet(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    backgroundColor:
    context.themeProvider.isDark ? Colors.black : Colors.white,
    context: context,
    isScrollControlled: true,
    builder: (context) {
      int? selectedIndex;

      return BlocProvider(
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "saved_passenger_list".tr(),
                                    style: context.textTheme.bodyLarge?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close, size: 24),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 360,
                                child: ListView.builder(
                                  itemCount: users.length,
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
                                        height: 64,

                                        decoration: BoxDecoration(
                                          color: context.color.primaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                          border: isSelected
                                              ? Border.all(
                                            color: const Color(0xFF0057BE),
                                            width: 1,
                                          )
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: context.themeProvider.isDark
                                                  ? context.color.primaryContainer
                                                  : const Color(0x80C6C7C9),
                                              offset: const Offset(0, 2),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          title: Text(
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            "${user.firstname} ${user.lastname}",
                                            style: context.textTheme.bodyMedium
                                                ?.copyWith(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.w600),
                                          ),
                                          subtitle: Padding(
                                            padding: EdgeInsets.only(top: 0,bottom: 8), // Subtitle va title orasiga bo'shliq
                                            child: Text(
                                              user.docnum ?? '',
                                              style: context.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          trailing: isSelected
                                              ? Icon(Icons.check_circle,
                                              color: ProjectTheme.success)
                                              : null,
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
                        ));
                  }

                  return const SizedBox.shrink(); // default fallback
                },
              );
            },
          ));
    },
  );
}