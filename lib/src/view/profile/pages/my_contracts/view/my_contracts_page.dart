import 'package:lottie/lottie.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart' show ProjectAssets;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/logic/my_contracts_cubit.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/service/my_contract_model.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/view/my_contract_detail_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/widget/contract_card_shimmer.dart';

class MyContractsPage extends StatefulWidget {
  final String pinfl;

  const MyContractsPage({super.key, required this.pinfl});

  static const String routeName = "/myContracts";

  @override
  State<MyContractsPage> createState() => _MyContractsPageState();
}

class _MyContractsPageState extends State<MyContractsPage> {
  late final MyContractsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = MyContractsCubit();
    _cubit.loadContracts(widget.pinfl);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text("my_contracts".tr()),
        ),
        body: BlocBuilder<MyContractsCubit, MyContractsState>(
          builder: (context, state) => _buildBody(context, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyContractsState state) {
    if (state is MyContractsLoadingState || state is MyContractsInitState) {
      return const ContractsListShimmer();
    }

    if (state is MyContractsErrorState) {
      return Center(
        child: Padding(
          padding: context.k16Padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 56, color: ProjectTheme.error),
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

    if (state is MyContractsSuccessState) {
      final contracts = state.contracts;
      if (contracts.isEmpty) {
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
                  "no_contracts".tr(),
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
          itemCount: contracts.length,
          separatorBuilder: (_, __) => context.szBoxHeight16,
          itemBuilder: (_, index) => _ContractCard(item: contracts[index]),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _retry() => _cubit.loadContracts(widget.pinfl, force: true);

  Future<void> _refresh() async =>
      _cubit.loadContracts(widget.pinfl, force: true);
}

class _ContractCard extends StatelessWidget {
  final MyContractModel item;

  const _ContractCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final brand = ProjectTheme.brandColor;
    final secondaryColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final dividerColor = isDark
        ? Colors.white.withAlpha(15)
        : Colors.black.withAlpha(10);

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
            // Gradient header with decorative circles
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [brand, ProjectTheme.blueBg],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(75),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      context.szBoxWidth12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "contract".tr().toUpperCase(),
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withAlpha(210),
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "№ ${item.title}",
                              style: context.textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                      context.szBoxWidth8,
                      _AutoChip(auto: item.auto),
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
                      color: Colors.white.withAlpha(20),
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
            // Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: _ProgressBlock(
                progress: item.progress,
                paidLabel:
                    "${item.formattedPaidAmount} ${"uzs_currency".tr()}",
                totalLabel:
                    "${item.formattedTotalDebt} ${"uzs_currency".tr()}",
                secondaryColor: secondaryColor,
                brand: brand,
              ),
            ),
            // Amounts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: "contract_total_debt".tr(),
                    value:
                        "${item.formattedTotalDebt} ${"uzs_currency".tr()}",
                    labelColor: secondaryColor,
                    accent: brand,
                  ),
                  Container(height: 1, color: dividerColor),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    label: "contract_current_debt".tr(),
                    value:
                        "${item.formattedCurrentDebt} ${"uzs_currency".tr()}",
                    labelColor: secondaryColor,
                    accent: ProjectTheme.error,
                  ),
                  Container(height: 1, color: dividerColor),
                  _InfoRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: "contract_paid_amount".tr(),
                    value:
                        "${item.formattedPaidAmount} ${"uzs_currency".tr()}",
                    labelColor: secondaryColor,
                    accent: ProjectTheme.success,
                  ),
                ],
              ),
            ),
            // Details button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: _DetailsButton(loanId: item.title, contractId: item.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  final double progress;
  final String paidLabel;
  final String totalLabel;
  final Color secondaryColor;
  final Color brand;

  const _ProgressBlock({
    required this.progress,
    required this.paidLabel,
    required this.totalLabel,
    required this.secondaryColor,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final isDark = context.themeProvider.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [brand, ProjectTheme.blueBg],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: brand.withAlpha(70),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                "$percent%",
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
            const Spacer(),
            Text(
              "$paidLabel / $totalLabel",
              style: context.textTheme.bodySmall?.copyWith(
                color: secondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(15)
                    : Colors.black.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0, 1).toDouble(),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [brand, ProjectTheme.blueBg],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: brand.withAlpha(110),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AutoChip extends StatelessWidget {
  final bool auto;

  const _AutoChip({required this.auto});

  @override
  Widget build(BuildContext context) {
    final dotColor = auto ? ProjectTheme.success : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(75), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withAlpha(160),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            auto ? "contract_auto_on".tr() : "contract_auto_off".tr(),
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

class _DetailsButton extends StatelessWidget {
  final String loanId;
  final int? contractId;

  const _DetailsButton({required this.loanId, this.contractId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MyContractDetailPage(loanId: loanId, contractId: contractId),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [ProjectTheme.brandColor, ProjectTheme.blueBg],
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
                    child: const Icon(Icons.list_alt_rounded,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "details".tr(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
