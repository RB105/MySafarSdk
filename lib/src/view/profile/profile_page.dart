import 'package:flutter/services.dart' show HapticFeedback, SystemUiOverlayStyle;
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart'
    show BookingFormStyle;
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart'
    show BookingCard;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_applications/view/my_applications_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_data_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/ofd_cheques_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/edit_profile_page.dart';
import 'package:mysafar_sdk/src/view/visa/myid_verification_page.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart' show showToastTr;
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/view/profile/pages/settings_page.dart';
import 'package:mysafar_sdk/src/cubit/profile/profile_cubit.dart';
import 'package:shimmer/shimmer.dart';

/// Profil tabi — boshqa tablar (Buyurtmalar, Yo'nalishlar) bilan bir xil
/// uslub: sahifa fonida markazlangan sarlavha, ostida tekis kartalar.
/// Foydalanuvchi kartasi (avatar + ism + kontakt) → profilni tahrirlash;
/// menyu guruhlari "Ma'lumotlarim" sahifasidagi qator uslubida.
class ProfilePage extends StatefulWidget {
  final ProfileModel? profileData;

  const ProfilePage({super.key, this.profileData});

  static const String routeName = "/profilePage";

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileModel? profileData;
  late final ProfileCubit _profileCubit;

  @override
  void initState() {
    profileData = widget.profileData;
    _profileCubit = ProfileCubit(needGetProfile: true);
    super.initState();
  }

  @override
  void dispose() {
    _profileCubit.close();
    super.dispose();
  }

  Future<void> _openMyDataPage(BuildContext context) async {
    final ProfileModel? updatedProfile = await Navigator.pushNamed(
      context,
      MyDataPage.routeName,
      arguments: profileData,
    ) as ProfileModel?;

    if (updatedProfile != null) {
      // ignore: use_build_context_synchronously
      BlocProvider.of<ProfileCubit>(context).updateProfileData(updatedProfile);
    }
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final profileCubit = context.read<ProfileCubit>();
    final ProfileModel? updatedProfile = await Navigator.pushNamed(
      context,
      EditProfilePage.routeName,
      arguments: profileData,
    ) as ProfileModel?;

    if (!mounted) return;
    if (updatedProfile != null) {
      setState(() {
        profileData = updatedProfile;
      });
      profileCubit.getProfileData(forceRefresh: true);
    }
  }

  /// Arizalarim: PINFL bo'lsa ro'yxatga, aks holda MyID identifikatsiyasiga.
  Future<void> _openApplications(BuildContext context) async {
    final hasPinfl = profileData?.pinfl?.trim().isNotEmpty ?? false;
    if (hasPinfl) {
      Navigator.pushNamed(context, MyApplicationsPage.routeName);
      return;
    }
    // MyID sozlanmagan hostda (config.myId yo'q) identifikatsiyaga o'tmaymiz.
    if (MySafarSdk.config.myId == null) {
      showToastTr('error_other');
      return;
    }
    final cubit = context.read<ProfileCubit>();
    final verified =
        await Navigator.pushNamed(context, MyIdVerificationPage.routName);
    // MyID tasdiqlangach profilni qayta yuklab, pinfl bilan yangilangan
    // holatni ko'rsatamiz.
    if (verified == true) {
      cubit.getProfileData(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _profileCubit,
        child: BlocConsumer<ProfileCubit, ProfileState>(
          listener: (BuildContext context, ProfileState state) {
            if (state.profileInfoStatus == ActionStatus.isSuccess) {
              profileData = state.profileModel;
            }
          },
          builder: (context, state) {
            // Kesh konstruktorda darhol emit qilinganda BlocConsumer.listener
            // (initial state uchun ishlamaydi) o'tkazib yuboriladi — shuning
            // uchun profilni state'dan shu yerda ham olamiz.
            if (state.profileInfoStatus == ActionStatus.isSuccess &&
                state.profileModel != null) {
              profileData = state.profileModel;
            }
            // Login qilingan, lekin profil hali kelmagan — "Kirish" kartasi
            // lip etib ko'rinmasin, o'rniga skelet.
            final bool isLoadingProfile = profileData == null &&
                state.profileInfoStatus == ActionStatus.isLoading;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    context.isDarkMode ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    context.isDarkMode ? Brightness.dark : Brightness.light,
              ),
              child: Scaffold(
                body: Column(
                  children: [
                    const _ProfileHeader(),
                    Expanded(
                      child: AppRefreshIndicator(
                        onRefresh: () async {
                          // Qo'lda yangilash — profilni serverdan majburan
                          // qayta oladi.
                          await _profileCubit.getProfileData(
                              forceRefresh: true);
                        },
                        child: ListView(
                          // Clamping — bounce bo'shliq yo'qoladi.
                          physics: const AlwaysScrollableScrollPhysics(
                              parent: ClampingScrollPhysics()),
                          // Pastki inset scroll padding'ida — kontent shisha
                          // bottom bar ostidan o'tadi (Android va iOS bir xil).
                          padding: EdgeInsets.fromLTRB(
                              16, 8, 16, 32 + MediaQuery.paddingOf(context).bottom),
                          children: _buildContent(context, isLoadingProfile),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  List<Widget> _buildContent(BuildContext context, bool isLoadingProfile) {
    final bool fullProfile = MySafarSdk.config.enableFullProfile;
    final bool loggedIn = profileData != null;

    return [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: isLoadingProfile
            ? const _UserCardSkeleton(key: ValueKey('loading'))
            : loggedIn
                ? _UserCard(
                    key: const ValueKey('user'),
                    profile: profileData!,
                    onTap: () => _openEditProfile(context),
                  )
                : _GuestCard(
                    key: const ValueKey('guest'),
                    onLogin: () => ProjectDialogs.showAuthPhoneSheet(context),
                  ),
      ),
      if (loggedIn) ...[
        const SizedBox(height: 16),
        _MenuGroup(
          children: [
            _MenuRow(
              icon: Assets.iconsBookingUserIcon,
              title: "my_data".tr(),
              onTap: () => _openMyDataPage(context),
            ),
            // Arizalarim/cheklar faqat to'liq profil rejimida (embed'da
            // default o'chiq).
            if (fullProfile) ...[
              _MenuRow(
                icon: Assets.iconsProfileDocumentIcon,
                title: "my_applications".tr(),
                onTap: () => _openApplications(context),
              ),
              _MenuRow(
                icon: Assets.iconsProfileReceiptIcon,
                title: "my_cheques".tr(),
                onTap: () =>
                    Navigator.pushNamed(context, OFDChequesPage.routeName),
              ),
            ],
          ],
        ),
      ],
      const SizedBox(height: 16),
      _MenuGroup(
        children: [
          if (fullProfile)
            _MenuRow(
              icon: Assets.iconsProfileSettingsIcon,
              title: "settings".tr(),
              onTap: () => Navigator.pushNamed(context, SettingsPage.routeName),
            ),
          _MenuRow(
            icon: Assets.iconsProfileSupportIcon,
            title: "support".tr(),
            onTap: () => ProjectDialogs.showSupportMenu(context),
          ),
        ],
      ),
      // Hisobni o'chirish/chiqish — sessiyani host boshqaradi, embed'da
      // default ko'rsatilmaydi.
      if (fullProfile && loggedIn) ...[
        const SizedBox(height: 16),
        _MenuGroup(
          children: [
            _MenuRow(
              icon: Assets.iconsProfileLogoutIcon,
              title: "logout".tr(),
              danger: true,
              showChevron: false,
              onTap: () => ProjectDialogs.showDeleteAccountDialog(context),
            ),
          ],
        ),
      ],
    ];
  }
}

// ════════════════════════════════════════════════════════════════════
//  HEADER
// ════════════════════════════════════════════════════════════════════

/// Buyurtmalar/Yo'nalishlar tablari bilan bir xil: sahifa fonida
/// markazlangan sarlavha.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              'profile'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  FOYDALANUVCHI KARTALARI
// ════════════════════════════════════════════════════════════════════

Color _accent(BuildContext context) =>
    context.isDarkMode ? Colors.white : ProjectTheme.brandColor;

Color _tileFill(BuildContext context) => context.isDarkMode
    ? Colors.white.withValues(alpha: 0.08)
    : ProjectTheme.brandColor.withValues(alpha: 0.08);

/// Avatar (bosh harflar) + ism + telefon/email; bosilganda tahrirlash.
class _UserCard extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onTap;

  const _UserCard({super.key, required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = profile.getName().trim();
    final authenticator = profile.getAuthenticator().trim();
    final isPhone = authenticator.startsWith('+');
    final initials = name.isEmpty
        ? ''
        : name
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join();
    final muted = BookingFormStyle.label(context);
    final accent = _accent(context);

    return BookingCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _tileFill(context),
                  shape: BoxShape.circle,
                ),
                child: initials.isNotEmpty
                    ? Text(
                        initials,
                        style: TextStyle(
                          fontFamily: "packages/mysafar_sdk/Gilroy",
                          color: accent,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      )
                    : SvgPicture.asset(
                        Assets.iconsBookingUserIcon,
                        width: 28,
                        height: 28,
                        colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'profile'.tr(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (authenticator.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          SvgPicture.asset(
                            isPhone
                                ? Assets.iconsBookingCallIcon
                                : Assets.iconsProfileMailIcon,
                            width: 15,
                            height: 15,
                            colorFilter:
                                ColorFilter.mode(muted, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              authenticator,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodySmall?.copyWith(
                                fontSize: 13.5,
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
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _tileFill(context),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  Assets.iconsProfileEditIcon,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Login qilinmagan holat: ikonka + taklif matni + "Tizimga kirish".
class _GuestCard extends StatelessWidget {
  final VoidCallback onLogin;

  const _GuestCard({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return BookingCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _tileFill(context),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  Assets.iconsBookingUserIcon,
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'enter_profile'.tr(),
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'enter_profile_desc'.tr(),
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: BookingFormStyle.label(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                // MainButtonWidget bilan bir xil analytics identifikatori.
                AnalyticsService().trackButtonTap('enter_login'.tr());
                onLogin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ProjectTheme.brandColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'enter_login'.tr(),
                style: const TextStyle(
                  fontFamily: "packages/mysafar_sdk/Gilroy",
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profil yuklanayotgandagi foydalanuvchi kartasi sileti.
class _UserCardSkeleton extends StatelessWidget {
  const _UserCardSkeleton({super.key});

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

    return BookingCard(
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: base, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(160, 16),
                const SizedBox(height: 10),
                bar(120, 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  MENYU
// ════════════════════════════════════════════════════════════════════

/// Qatorlar guruhi — tekis karta, qatorlar orasida ingichka ajratkich.
class _MenuGroup extends StatelessWidget {
  final List<Widget> children;

  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return BookingCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 68,
                endIndent: 16,
                color: context.color.outline.withValues(alpha: 0.6),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Menyu qatori: rangli fondagi ikonka + nom + o'ng strelka.
/// [danger] — qizil ton (chiqish/o'chirish).
class _MenuRow extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;
  final bool showChevron;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final Color tint = danger
        ? (isDark
            ? Color.lerp(ProjectTheme.error, Colors.white, 0.25)!
            : ProjectTheme.error)
        : _accent(context);
    final Color fill = danger
        ? ProjectTheme.error.withValues(alpha: isDark ? 0.16 : 0.08)
        : _tileFill(context);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset(
                icon,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: danger ? tint : null,
                ),
              ),
            ),
            if (showChevron) ...[
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
          ],
        ),
      ),
    );
  }
}
