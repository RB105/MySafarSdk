// ignore_for_file: use_build_context_synchronously

import 'package:mysafar_sdk/src/cubit/profile/users_data/users_data_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/booking/support/country_name_list.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart'
    show BookingFormStyle;
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart'
    show BookingCard;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/add_passenger_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/updated_passenger_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/widget/profile_app_bar.dart';
import 'package:shimmer/shimmer.dart';

class MyDataPage extends StatefulWidget {
  final ProfileModel? profileModel;
  const MyDataPage({super.key, required this.profileModel});
  static const String routeName = "/mydata";
  @override
  State<MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends State<MyDataPage> {
  @override
  Widget build(BuildContext context) {
    final email = widget.profileModel?.email?.trim() ?? '';
    final phone = widget.profileModel?.phoneNumber?.trim() ?? '';

    return Scaffold(
      appBar: sdkBodyColoredAppBar(context, title: "my_information".tr()),
      body: BlocProvider(
        create: (context) => UsersDataCubit(needGetUsers: true),
        child: Builder(
          builder: (context) => AppRefreshIndicator(
            onRefresh: () => context.read<UsersDataCubit>().fetchFromServer(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (email.isNotEmpty || phone.isNotEmpty) ...[
                  _SectionTitle("contact_info".tr()),
                  BookingCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        if (email.isNotEmpty)
                          _ContactRow(
                            icon: Assets.iconsProfileMailIcon,
                            label: "email".tr(),
                            value: email,
                          ),
                        if (email.isNotEmpty && phone.isNotEmpty)
                          const _RowDivider(),
                        if (phone.isNotEmpty)
                          _ContactRow(
                            icon: Assets.iconsBookingCallIcon,
                            label: "phone_number_label".tr(),
                            value: phone,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                _SectionTitle("passenger_data_title".tr()),
                BlocBuilder<UsersDataCubit, UsersDataState>(
                  builder: (context, state) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildPassengers(context, state),
                  ),
                ),
                const SizedBox(height: 12),
                _AddPassengerCard(onTap: () => _openAddPassenger(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassengers(BuildContext context, UsersDataState state) {
    if (state is UsersDataSuccessState && state.usersModel.isNotEmpty) {
      final passengers = state.usersModel;
      return BookingCard(
        key: const ValueKey('passengers'),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (int i = 0; i < passengers.length; i++) ...[
              if (i > 0) const _RowDivider(),
              _PassengerRow(
                passenger: passengers[i],
                onTap: () => _openPassenger(context, passengers[i]),
              ),
            ],
          ],
        ),
      );
    }

    if (state is UsersDataErrorState) {
      return _StatusCard(
        key: const ValueKey('error'),
        icon: Assets.iconsBookingAlertIcon,
        color: ProjectTheme.error,
        message: state.error,
        actionLabel: "retry".tr(),
        onAction: () => context.read<UsersDataCubit>().fetchFromServer(),
      );
    }

    if (state is UsersDataEmptyState || state is UsersDataSuccessState) {
      return _StatusCard(
        key: const ValueKey('empty'),
        icon: Assets.iconsProfileUsersIcon,
        color: ProjectTheme.brandColor,
        message: "no_passenger_info".tr(),
      );
    }

    return const BookingCard(
      key: ValueKey('loading'),
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _PassengerRowSkeleton(),
          _RowDivider(),
          _PassengerRowSkeleton(),
          _RowDivider(),
          _PassengerRowSkeleton(),
        ],
      ),
    );
  }

  Future<void> _openAddPassenger(BuildContext context) async {
    final value = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPassengerPage()),
    );
    if (value == true) context.read<UsersDataCubit>().fetchFromServer();
  }

  Future<void> _openPassenger(
      BuildContext context, UsersModel passenger) async {
    final value = await Navigator.pushNamed(
      context,
      UpdatedPassengerPage.routeName,
      arguments: passenger,
    );
    if (value == true) context.read<UsersDataCubit>().fetchFromServer();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: context.textTheme.bodyLarge
            ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      endIndent: 16,
      color: context.color.outline.withValues(alpha: 0.6),
    );
  }
}

/// Ikonka joylashadigan yumaloq-to'rtburchak fon (bron sahifasi uslubi).
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, this.circle = false});

  final String icon;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final Color tint = isDark ? Colors.white : ProjectTheme.brandColor;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : tint.withValues(alpha: 0.08),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(12),
      ),
      child: SvgPicture.asset(
        icon,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _IconTile(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: BookingFormStyle.label(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassengerRow extends StatelessWidget {
  const _PassengerRow({required this.passenger, required this.onTap});

  final UsersModel passenger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = "${passenger.lastname ?? ''} ${passenger.firstname ?? ''}"
        .trim()
        .toUpperCase();
    final code = (passenger.citizen ?? '').trim();
    final country = code.isEmpty
        ? ''
        : (getCountry(code)["name"]?[dataLang()] ?? '').toString();
    final subtitle = [
      if (country.isNotEmpty) country,
      if ((passenger.docnum ?? '').isNotEmpty) passenger.docnum!,
    ].join(' · ');
    final muted = BookingFormStyle.label(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const _IconTile(icon: Assets.iconsBookingUserIcon, circle: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name.isEmpty ? '—' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (code.isNotEmpty) ...[
                          _Flag(code: code),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              Assets.iconsBookingChevronRightIcon,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                BookingFormStyle.hint(context),
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.asset(
        'packages/mysafar_sdk/assets/img/flags/${code.toLowerCase()}.png',
        width: 18,
        height: 13,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _PassengerRowSkeleton extends StatelessWidget {
  const _PassengerRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final base =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE9EDF3);
    final highlight =
        isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFF6F8FB);

    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: base, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(150, 14),
                const SizedBox(height: 8),
                bar(110, 11),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bo'sh ro'yxat yoki xatolik kartasi — ikonka, matn va ixtiyoriy tugma.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String icon;
  final Color color;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final tint = isDark ? Color.lerp(color, Colors.white, 0.3)! : color;
    return BookingCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: isDark ? 0.14 : 0.08),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              icon,
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: BookingFormStyle.label(context),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? Colors.white : ProjectTheme.brandColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontFamily: 'packages/mysafar_sdk/Gilroy',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddPassengerCard extends StatelessWidget {
  const _AddPassengerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = isDark ? Colors.white : ProjectTheme.brandColor;
    return BookingCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              const _IconTile(icon: Assets.iconsProfileUserPlusIcon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "add_new_passenger".tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              SvgPicture.asset(
                Assets.iconsBookingChevronRightIcon,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  BookingFormStyle.hint(context),
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
