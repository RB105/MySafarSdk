import 'package:mysafar_sdk/src/service/profile/profile_cache.dart';
import 'package:lottie/lottie.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart' show ProjectAssets;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_applications/logic/my_applications_cubit.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_applications/service/my_application_model.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_applications/widget/application_card_shimmer.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/view/my_contracts_page.dart';
import 'package:mysafar_sdk/src/view/visa/myid_verification_page.dart';
import 'package:mysafar_sdk/src/cubit/profile/profile_cubit.dart';

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  static const String routeName = "/myApplications";

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  ProfileModel? _profile;
  bool _loading = true;
  late final MyApplicationsCubit _cubit;
  late final ProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();
    _cubit = MyApplicationsCubit();
    _profileCubit = ProfileCubit();
    _loadProfile();
  }

  @override
  void dispose() {
    _cubit.close();
    _profileCubit.close();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final cached = ProfileCache().read();
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _profile = ProfileModel.fromJson(cached);
        _loading = false;
      });
      _maybeLoadApplications();
      return;
    }

    final response = await _profileCubit.getProfileData();
    if (!mounted) return;
    if (response is NetworkSuccessResponse) {
      setState(() {
        _profile = response.data;
        _loading = false;
      });
      _maybeLoadApplications();
    } else {
      setState(() => _loading = false);
    }
  }

  void _maybeLoadApplications() {
    final pinfl = _pinfl;
    if (pinfl == null) return;
    _cubit.loadApplications(pinfl);
  }

  String? get _pinfl {
    final pinfl = _profile?.pinfl?.trim();
    return (pinfl == null || pinfl.isEmpty) ? null : pinfl;
  }

  bool get _hasPinfl => _pinfl != null;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text("my_applications".tr()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPinfl) {
      return MyIdVerificationPage(
        appBarTitle: "my_applications".tr(),
        onVerified: _loadProfile,
      );
    }

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text("my_applications".tr()),
        ),
        body: BlocBuilder<MyApplicationsCubit, MyApplicationsState>(
          builder: (context, state) => _buildBody(context, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyApplicationsState state) {
    if (state is MyApplicationsLoadingState ||
        state is MyApplicationsInitState) {
      return const ApplicationsListShimmer();
    }

    if (state is MyApplicationsErrorState) {
      return Center(
        child: Padding(
          padding: context.k16Padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: ProjectTheme.error,
              ),
              context.szBoxHeight12,
              Text(
                state.error,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium,
              ),
              context.szBoxHeight16,
              ElevatedButton(
                style: ProjectTheme.blueButtonStyle,
                onPressed: _retry,
                child: Text("retry".tr()),
              ),
            ],
          ),
        ),
      );
    }

    if (state is MyApplicationsSuccessState) {
      final apps = state.applications;
      if (apps.isEmpty) {
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              Lottie.asset(
                ProjectAssets.emptyTicket,
                repeat: false,
                fit: BoxFit.contain,
                height: 200,
              ),
              context.szBoxHeight16,
              Center(
                child: Text(
                  "no_applications".tr(),
                  style: context.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }

      final bottomInset = MediaQuery.of(context).padding.bottom;
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          itemCount: apps.length,
          separatorBuilder: (_, __) => context.szBoxHeight16,
          itemBuilder: (_, index) => _ApplicationCard(
            item: apps[index],
            profilePinfl: _pinfl,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _retry() {
    final pinfl = _pinfl;
    if (pinfl != null) _cubit.loadApplications(pinfl);
  }

  Future<void> _refresh() async {
    final pinfl = _pinfl;
    if (pinfl != null) await _cubit.loadApplications(pinfl, force: true);
  }
}

class _ApplicationCard extends StatelessWidget {
  final MyApplicationModel item;
  final String? profilePinfl;

  const _ApplicationCard({required this.item, this.profilePinfl});

  String? get _contractPinfl {
    final pinfl = (item.pinfl?.trim().isNotEmpty ?? false)
        ? item.pinfl!.trim()
        : profilePinfl?.trim();
    return (pinfl == null || pinfl.isEmpty) ? null : pinfl;
  }

  @override
  Widget build(BuildContext context) {
    final name = item.fullName.isEmpty ? "application".tr() : item.fullName;
    final contractPinfl = _contractPinfl;
    final statusColor = _statusColor(item.statusType);
    final isDark = context.themeProvider.isDark;
    final brand = ProjectTheme.brandColor;
    final secondaryColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final dividerColor = isDark
        ? Colors.white.withAlpha(15)
        : Colors.black.withAlpha(10);

    final rows = <Widget>[
      if (item.passport != null)
        _InfoRow(
          icon: Icons.badge_outlined,
          label: "passport".tr(),
          value: item.passport!,
          labelColor: secondaryColor,
          accent: brand,
        ),
      if (item.phone != null)
        _InfoRow(
          icon: Icons.phone_outlined,
          label: "phone".tr(),
          value: _formatPhone(item.phone!),
          labelColor: secondaryColor,
          accent: brand,
        ),
      if (item.address != null)
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: "address".tr(),
          value: item.address!,
          labelColor: secondaryColor,
          accent: brand,
        ),
      if (item.formattedCreatedAt.isNotEmpty)
        _InfoRow(
          icon: Icons.calendar_month_outlined,
          label: "application_date".tr(),
          value: item.formattedCreatedAt,
          labelColor: secondaryColor,
          accent: brand,
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          borderRadius: BorderRadius.circular(22),
          boxShadow: context.shadowDown,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient header colored by status with decorative circles
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [statusColor, statusColor.withAlpha(205)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _AvatarBadge(name: name),
                      context.szBoxWidth12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "application".tr().toUpperCase(),
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withAlpha(210),
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      context.szBoxWidth8,
                      _StatusChip(status: item.statusType),
                    ],
                  ),
                ),
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(22),
                    ),
                  ),
                ),
                Positioned(
                  right: 50,
                  top: 30,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(14),
                    ),
                  ),
                ),
              ],
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    rows[i],
                    if (i != rows.length - 1)
                      Container(
                        height: 1,
                        color: dividerColor,
                      ),
                  ],
                ],
              ),
            ),
            if (contractPinfl != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: _ViewContractsButton(pinfl: contractPinfl),
              )
            else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 9) {
      return "+998 ${digits.substring(0, 2)} ${digits.substring(2, 5)} "
          "${digits.substring(5, 7)} ${digits.substring(7)}";
    }
    if (digits.length == 12 && digits.startsWith('998')) {
      final rest = digits.substring(3);
      return "+998 ${rest.substring(0, 2)} ${rest.substring(2, 5)} "
          "${rest.substring(5, 7)} ${rest.substring(7)}";
    }
    return phone;
  }

  Color _statusColor(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.created:
        return ProjectTheme.brandColor;
      case ApplicationStatus.review:
        return ProjectTheme.warning;
      case ApplicationStatus.approved:
        return ProjectTheme.success;
      case ApplicationStatus.rejected:
        return ProjectTheme.error;
    }
  }
}

class _AvatarBadge extends StatelessWidget {
  final String name;

  const _AvatarBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(55),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(80), width: 1),
      ),
      child: Text(
        initials.isEmpty ? "?" : initials,
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ApplicationStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withAlpha(180),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.labelKey.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color labelColor;
  final Color accent;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accent.withAlpha(180)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accent.withAlpha(70),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewContractsButton extends StatelessWidget {
  final String pinfl;

  const _ViewContractsButton({required this.pinfl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pushNamed(
            context,
            MyContractsPage.routeName,
            arguments: pinfl,
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  ProjectTheme.brandColor,
                  ProjectTheme.blueBg,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ProjectTheme.brandColor.withAlpha(90),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "view_contracts".tr(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
