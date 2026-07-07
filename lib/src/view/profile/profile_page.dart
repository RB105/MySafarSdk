// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:math' as math;

import 'package:mysafar_sdk/src/core/tools/project_assets.dart' show ProjectAssets;
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_applications/view/my_applications_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_data_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/ofd_cheques_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/edit_profile_page.dart';
import 'package:mysafar_sdk/src/view/visa/myid_verification_page.dart';

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

  Widget _buildProfileActionTile({
    required BuildContext context,
    required String assetPath,
    required String title,
    required VoidCallback onTap,
    required Color iconBgColor,
    required Color iconColor,
    String? subtitle,
    double iconHeight = 22,
    double iconWidth = 22,
    BoxFit fit = BoxFit.contain,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: SizedBox(
                    width: iconWidth,
                    height: iconHeight,
                    child: SvgPicture.asset(
                      assetPath,
                      fit: fit,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              context.szBoxWidth12,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: context.disabledTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: context.lightDrop2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: context.color.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: context.textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: context.disabledTextColor,
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 56),
        child: Divider(
          height: 1,
          thickness: 0.6,
          color: context.theme.dividerColor.withOpacity(0.4),
        ),
      );

  /// Header ortidagi aviatsiya bezagi — jahon xaritasi + punktir parvoz
  /// yo'li + samolyot. Ikkala header'da ham qayta ishlatiladi.
  Widget _aviationBackdrop() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/img/tickets/worls_map.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            CustomPaint(
              painter: _HeaderFlightPathPainter(
                Colors.white.withOpacity(0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text(
            "MySafar",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: "Gilroy",
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ProjectTheme.brandColor,
            ProjectTheme.accentLight,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ProjectTheme.brandColor.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          _aviationBackdrop(),
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _brandChip(),
                const SizedBox(height: 18),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.flight_takeoff_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'enter_profile'.tr(),
                  style: context.theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'enter_profile_desc'.tr(),
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                MainButtonWidget(
                  onTap: () => ProjectDialogs.showAuthPhoneSheet(context),
                  title: 'enter_login'.tr(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    final name = profileData?.getName() ?? "";
    final authenticator = profileData?.getAuthenticator() ?? "";
    final hasAuthenticator = authenticator.trim().isNotEmpty;
    final isPhone = authenticator.trim().startsWith('+');
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '';
    final displayName = name.trim().isNotEmpty ? name : 'profile'.tr();

    return GestureDetector(
      onTap: () => _openEditProfile(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF003E8C),
              ProjectTheme.brandColor,
              ProjectTheme.accentLight,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: ProjectTheme.brandColor.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -50,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -50,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                right: 80,
                bottom: -20,
                child: Transform.rotate(
                  angle: 0.6,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
              ),
              _aviationBackdrop(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _brandChip(),
                        const Spacer(),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_outward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.85),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: initials.isNotEmpty
                                    ? ShaderMask(
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            ProjectTheme.brandColor,
                                            ProjectTheme.accentLight,
                                          ],
                                        ).createShader(bounds),
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: "Gilroy",
                                            letterSpacing: 0.5,
                                            height: 1.0,
                                          ),
                                        ),
                                      )
                                    : SvgPicture.asset(
                                        ProjectAssets.logoProfile,
                                        height: 32,
                                        width: 32,
                                      ),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ProjectTheme.success,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'welcome_back'.tr().toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "Gilroy",
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: "Gilroy",
                                  height: 1.1,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (hasAuthenticator) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      isPhone
                                          ? Icons.phone_rounded
                                          : Icons.mail_outline_rounded,
                                      color: Colors.white.withOpacity(0.85),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        authenticator,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: "Gilroy",
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            return Scaffold(
              appBar: AppBar(
                centerTitle: false,
                title: Text(
                  'profile'.tr(),
                  style: context.textTheme.displayLarge,
                ),
              ),
              body: SafeArea(
                top: Platform.isAndroid,
                bottom: Platform.isAndroid,
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Qo'lda yangilash — profilni serverdan majburan qayta oladi.
                    await _profileCubit.getProfileData(forceRefresh: true);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: context.k16Padding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        profileData == null
                            ? _buildGuestHeader(context)
                            : _buildUserHeader(context),
                        context.szBoxHeight24,
                        if (profileData != null) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildSectionLabel(context, 'profile'.tr()),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: context.color.primaryContainer,
                              boxShadow: context.shadowDown,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              child: Column(
                                children: [
                                  _buildProfileActionTile(
                                    context: context,
                                    assetPath: ProjectAssets.iconsProfile,
                                    title: "my_data".tr(),
                                    iconBgColor: ProjectTheme.brandColor
                                        .withOpacity(0.12),
                                    iconColor: ProjectTheme.brandColor,
                                    onTap: () => _openMyDataPage(context),
                                  ),
                                  _buildDivider(context),
                                  _buildProfileActionTile(
                                    context: context,
                                    assetPath: ProjectAssets.ticketIconProfile,
                                    title: "my_applications".tr(),
                                    iconBgColor: ProjectTheme.purpleLight
                                        .withOpacity(0.12),
                                    iconColor: ProjectTheme.purpleLight,
                                    onTap: () async {
                                      final hasPinfl = (profileData?.pinfl
                                              ?.trim()
                                              .isNotEmpty ??
                                          false);
                                      if (hasPinfl) {
                                        Navigator.pushNamed(
                                          context,
                                          MyApplicationsPage.routeName,
                                        );
                                      } else {
                                        final cubit =
                                            context.read<ProfileCubit>();
                                        final verified =
                                            await Navigator.pushNamed(
                                          context,
                                          MyIdVerificationPage.routName,
                                        );
                                        // MyID tasdiqlangach profilni qayta yuklab,
                                        // pinfl bilan yangilangan holatni ko'rsatamiz.
                                        if (verified == true) {
                                          cubit.getProfileData(
                                              forceRefresh: true);
                                        }
                                      }
                                    },
                                  ),
                                  _buildDivider(context),
                                  _buildProfileActionTile(
                                    context: context,
                                    assetPath: ProjectAssets.chequeIconProfile,
                                    title: "my_cheques".tr(),
                                    iconBgColor:
                                        ProjectTheme.success.withOpacity(0.12),
                                    iconColor: ProjectTheme.success,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      OFDChequesPage.routeName,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          context.szBoxHeight16,
                        ],
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildSectionLabel(context, 'settings'.tr()),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: context.color.primaryContainer,
                            boxShadow: context.shadowDown,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            child: Column(
                              children: [
                                _buildProfileActionTile(
                                  context: context,
                                  assetPath: ProjectAssets.iconsSettings,
                                  title: "settings".tr(),
                                  iconHeight: 24,
                                  iconWidth: 24,
                                  fit: BoxFit.cover,
                                  iconBgColor: ProjectTheme.accentLight
                                      .withOpacity(0.12),
                                  iconColor: ProjectTheme.accentLight,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    SettingsPage.routeName,
                                  ),
                                ),
                                _buildDivider(context),
                                _buildProfileActionTile(
                                  context: context,
                                  assetPath: ProjectAssets.iconsSupport,
                                  title: "support".tr(),
                                  iconBgColor:
                                      ProjectTheme.warning.withOpacity(0.14),
                                  iconColor: ProjectTheme.warning,
                                  onTap: () =>
                                      ProjectDialogs.showSupportMenu(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                        context.szBoxHeight16,
                        if (profileData != null)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () =>
                                  ProjectDialogs.showDeleteAccountDialog(
                                      context),
                              child: Container(
                                height: 56,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: ProjectTheme.error.withOpacity(0.08),
                                  border: Border.all(
                                    color: ProjectTheme.error.withOpacity(0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      size: 18,
                                      color: ProjectTheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      state.profileModel?.phoneNumber ==
                                              "998940874676"
                                          ? "delete_account_title".tr()
                                          : "logout".tr(),
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: ProjectTheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        context.szBoxHeight32,
                        Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: SvgPicture.asset(ProjectAssets.logoProfile),
                          ),
                        ),
                        context.szBoxHeight8,
                        GetAppVersion(),
                        context.szBoxHeight16,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

/// Header foni uchun punktir parvoz yo'li + samolyot — aviatsiya imzosi.
class _HeaderFlightPathPainter extends CustomPainter {
  final Color color;

  const _HeaderFlightPathPainter(this.color);

  Offset _bezier(Offset p0, Offset c, Offset p1, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * c.dx + t * t * p1.dx,
      u * u * p0.dy + 2 * u * t * c.dy + t * t * p1.dy,
    );
  }

  void _drawPlane(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(0, -7)
      ..lineTo(2, 2)
      ..lineTo(7, 4)
      ..lineTo(7, 5)
      ..lineTo(2, 4.5)
      ..lineTo(1.3, 8)
      ..lineTo(2.6, 9.5)
      ..lineTo(2.6, 10.3)
      ..lineTo(0, 9.5)
      ..lineTo(-2.6, 10.3)
      ..lineTo(-2.6, 9.5)
      ..lineTo(-1.3, 8)
      ..lineTo(-2, 4.5)
      ..lineTo(-7, 5)
      ..lineTo(-7, 4)
      ..lineTo(-2, 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p0 = Offset(size.width * 0.05, size.height * 0.88);
    final p1 = Offset(size.width * 0.95, size.height * 0.20);
    final c = Offset(size.width * 0.5, size.height * -0.05);

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(c.dx, c.dy, p1.dx, p1.dy);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = color;

    for (final metric in path.computeMetrics()) {
      double d = 0;
      const dash = 6.0;
      const gap = 6.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          linePaint,
        );
        d += dash + gap;
      }
    }

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(p0, 3, dotPaint);
    canvas.drawCircle(p1, 3, dotPaint);

    // Samolyot — yo'l bo'ylab ~62% nuqtada, urinma burchagi ostida.
    const t = 0.62;
    final pos = _bezier(p0, c, p1, t);
    final ahead = _bezier(p0, c, p1, t + 0.01);
    final angle = math.atan2(ahead.dy - pos.dy, ahead.dx - pos.dx);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle + math.pi / 2);
    _drawPlane(canvas, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeaderFlightPathPainter oldDelegate) =>
      oldDelegate.color != color;
}
