import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/logic/my_contract_detail_cubit.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/service/my_contract_model.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/view/add_card/add_card_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/widget/contract_detail_shimmer.dart';

class MyContractDetailPage extends StatefulWidget {
  final String loanId;

  /// Shartnomalar ro'yxatidan keladigan `contract_id`.
  /// card-link uchun shu id ishlatiladi (detail javobida bo'lmaydi).
  final int? contractId;

  const MyContractDetailPage({
    super.key,
    required this.loanId,
    this.contractId,
  });

  @override
  State<MyContractDetailPage> createState() => _MyContractDetailPageState();
}

class _MyContractDetailPageState extends State<MyContractDetailPage> {
  late final MyContractDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = MyContractDetailCubit();
    _cubit.loadDetail(widget.loanId);
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
          title: Text(
            "${"contract".tr()} № ${widget.loanId}",
            style: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: BlocBuilder<MyContractDetailCubit, MyContractDetailState>(
          builder: (context, state) => _buildBody(context, state),
        ),
        bottomNavigationBar:
            BlocBuilder<MyContractDetailCubit, MyContractDetailState>(
          builder: (context, state) {
            if (state is! MyContractDetailSuccessState) {
              return const SizedBox.shrink();
            }
            return SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _AddCardButton(onTap: _openAddCard),
            );
          },
        ),
      ),
    );
  }

  /// Karta qo'shish. `contract_id` shartnomalar ro'yxatidan kelgan
  /// `widget.contractId` orqali uzatiladi.
  Future<void> _openAddCard() async {
    final contractId = widget.contractId;
    if (contractId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("error_other".tr())),
      );
      return;
    }
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddCardPage(contractId: contractId)),
    );
    if (!mounted) return;
    // Karta muvaffaqiyatli qo'shildi — shartnomalar ro'yxatiga qaytamiz.
    if (added == true) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildBody(BuildContext context, MyContractDetailState state) {
    if (state is MyContractDetailLoadingState ||
        state is MyContractDetailInitState) {
      return const ContractDetailShimmer();
    }

    if (state is MyContractDetailErrorState) {
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
                onPressed: () => _cubit.loadDetail(widget.loanId, force: true),
                child: Text("retry".tr()),
              ),
            ],
          ),
        ),
      );
    }

    if (state is MyContractDetailSuccessState) {
      final bottomInset = MediaQuery.of(context).padding.bottom;
      return RefreshIndicator(
        onRefresh: () async => _cubit.loadDetail(widget.loanId, force: true),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          children: [
            _HeroCard(item: state.contract),
            context.szBoxHeight16,
            _AmountsCard(item: state.contract),
            if (state.contract.products.isNotEmpty) ...[
              context.szBoxHeight16,
              for (final product in state.contract.products) ...[
                _ProductCard(product: product),
                context.szBoxHeight12,
              ],
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _AddCardButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCardButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [brand, ProjectTheme.blueBg],
              ),
              boxShadow: [
                BoxShadow(
                  color: brand.withAlpha(110),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.credit_card_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "add_card".tr(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
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

class _HeroCard extends StatelessWidget {
  final MyContractModel item;

  const _HeroCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [brand, ProjectTheme.blueBg],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: brand.withAlpha(90),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(55),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(70),
                          width: 1,
                        ),
                      ),
                      child: const Icon(Icons.description_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "contract".tr().toUpperCase(),
                            style: context.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withAlpha(210),
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "№ ${item.title}",
                            style: context.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HeroAutoChip(auto: item.auto),
                  ],
                ),
                const SizedBox(height: 20),
                _HeroProgress(item: item),
              ],
            ),
          ),
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: 70,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(16),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAutoChip extends StatelessWidget {
  final bool auto;

  const _HeroAutoChip({required this.auto});

  @override
  Widget build(BuildContext context) {
    final dotColor = auto ? ProjectTheme.success : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(70), width: 1),
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

class _HeroProgress extends StatelessWidget {
  final MyContractModel item;

  const _HeroProgress({required this.item});

  @override
  Widget build(BuildContext context) {
    final percent = (item.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "contract_paid_amount".tr().toUpperCase(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withAlpha(190),
                      letterSpacing: 1,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item.formattedPaidAmount} ${"uzs_currency".tr()}",
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(55),
                border: Border.all(
                  color: Colors.white.withAlpha(110),
                  width: 1.5,
                ),
              ),
              child: Text(
                "$percent%",
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(45),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: item.progress.clamp(0, 1).toDouble(),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withAlpha(220),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withAlpha(120),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 14, color: Colors.white.withAlpha(220)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "${"contract_total_debt".tr()}: ${item.formattedTotalDebt} ${"uzs_currency".tr()}",
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withAlpha(230),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AmountsCard extends StatelessWidget {
  final MyContractModel item;

  const _AmountsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AmountTile(
            icon: Icons.payments_outlined,
            color: ProjectTheme.error,
            label: "contract_current_debt".tr(),
            value: item.formattedCurrentDebt,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AmountTile(
            icon: Icons.check_circle_outline_rounded,
            color: ProjectTheme.success,
            label: "contract_paid_amount".tr(),
            value: item.formattedPaidAmount,
          ),
        ),
      ],
    );
  }
}

class _AmountTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _AmountTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final secondaryColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.color.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              boxShadow: context.shadowDown,
            ),
          ),
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(isDark ? 35 : 18),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, color.withAlpha(0)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withAlpha(180)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: secondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$value ${"uzs_currency".tr()}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
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

class _ProductCard extends StatelessWidget {
  final MyContractProduct product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    final isDark = context.themeProvider.isDark;
    final secondaryColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final headerTint = isDark ? brand.withAlpha(35) : brand.withAlpha(14);
    final dividerColor = isDark
        ? Colors.white.withAlpha(15)
        : Colors.black.withAlpha(10);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          borderRadius: BorderRadius.circular(18),
          boxShadow: context.shadowDown,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Container(color: headerTint, height: 86),
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: brand.withAlpha(isDark ? 25 : 12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [brand, ProjectTheme.blueBg],
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: brand.withAlpha(80),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.inventory_2_rounded,
                            size: 20, color: Colors.white),
                      ),
                      context.szBoxWidth12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name ?? "—",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            if (product.period != null) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _MetaPill(
                                    text:
                                        "${product.period} ${"month_short".tr()}",
                                    color: brand,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (product.formattedStartDate.isNotEmpty ||
                product.amount != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    if (product.formattedStartDate.isNotEmpty)
                      Expanded(
                        child: _MetaRow(
                          icon: Icons.event_outlined,
                          label: "product_dates".tr(),
                          value:
                              "${product.formattedStartDate} — ${product.formattedDueDate}",
                          secondaryColor: secondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            if (product.amount != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: _MetaRow(
                  icon: Icons.attach_money_rounded,
                  label: "product_amount".tr(),
                  value:
                      "${product.formattedAmount} ${"uzs_currency".tr()}",
                  secondaryColor: secondaryColor,
                ),
              ),
            if (product.graphics.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(height: 1, color: dividerColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    Icon(Icons.event_repeat_outlined,
                        size: 16, color: brand),
                    const SizedBox(width: 6),
                    Text(
                      "payment_schedule".tr(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
                child: Column(
                  children: [
                    for (var i = 0; i < product.graphics.length; i++)
                      _Timeline(
                        graphic: product.graphics[i],
                        isFirst: i == 0,
                        isLast: i == product.graphics.length - 1,
                        secondaryColor: secondaryColor,
                      ),
                  ],
                ),
              ),
            ] else
              context.szBoxHeight12,
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const _MetaPill({
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [color, color.withAlpha(210)],
              )
            : null,
        color: isDark ? null : color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: color.withAlpha(80),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        style: context.textTheme.bodySmall?.copyWith(
          color: isDark ? Colors.white : color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color secondaryColor;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: secondaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: secondaryColor,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  final MyContractGraphic graphic;
  final bool isFirst;
  final bool isLast;
  final Color secondaryColor;

  const _Timeline({
    required this.graphic,
    required this.isFirst,
    required this.isLast,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final status = graphic.status;
    final statusColor = _statusColor(status);
    final isDark = context.themeProvider.isDark;
    final lineColor = isDark
        ? Colors.white.withAlpha(20)
        : Colors.black.withAlpha(12);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : lineColor,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [statusColor, statusColor.withAlpha(210)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withAlpha(80),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(_statusIcon(status),
                      color: Colors.white, size: 14),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(10)
                      : Colors.black.withAlpha(5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: statusColor.withAlpha(isDark ? 50 : 35),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "${"period".tr()} ${graphic.periodNumber ?? '—'}",
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: isDark
                                      ? LinearGradient(
                                          colors: [
                                            statusColor,
                                            statusColor.withAlpha(210),
                                          ],
                                        )
                                      : null,
                                  color: isDark
                                      ? null
                                      : statusColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.labelKey.tr(),
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.white
                                        : statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (graphic.formattedDueDate.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.event_outlined,
                                      size: 11, color: secondaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    graphic.formattedDueDate,
                                    style:
                                        context.textTheme.bodySmall?.copyWith(
                                      color: secondaryColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${graphic.formattedPaidAmount} / ${graphic.formattedTotalAmount}",
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "uzs_currency".tr(),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: secondaryColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(GraphicStatus s) {
    switch (s) {
      case GraphicStatus.paid:
        return Icons.check_rounded;
      case GraphicStatus.pending:
        return Icons.schedule_rounded;
      case GraphicStatus.overdue:
        return Icons.priority_high_rounded;
    }
  }

  Color _statusColor(GraphicStatus s) {
    switch (s) {
      case GraphicStatus.paid:
        return ProjectTheme.success;
      case GraphicStatus.pending:
        return ProjectTheme.brandColor;
      case GraphicStatus.overdue:
        return ProjectTheme.error;
    }
  }
}
