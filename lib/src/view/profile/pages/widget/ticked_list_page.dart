import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:mysafar_sdk/src/view/profile/src/my_ticket_widget.dart';

class TicketList extends StatelessWidget {
  final List<ConfirmedTicketsModel> tickets;
  final Future<void> Function()? onRefresh;

  const TicketList({super.key, required this.tickets, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (tickets.isEmpty) {
      child = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  context.themeProvider.isDark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
                child: Lottie.asset(
                  Assets.profileTicketEmpty,
                  width: 150,
                  height: 150,
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
              context.szBoxHeight16,
              Text("not_found_booked_tickets".tr()),
            ],
          ),
        ],
      );
    } else {
      child = MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
            itemCount: tickets.length,
            cacheExtent: 100,
            itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 0 : 8,
                    bottom: index == tickets.length - 1 ? 0 : 8,
                  ),
                  child: MyTicketWidget(
                    ticketsModel: tickets[index],
                  ),
                )),
      );
    }

    if (onRefresh == null) return child;
    return RefreshIndicator(onRefresh: onRefresh!, child: child);
  }
}
