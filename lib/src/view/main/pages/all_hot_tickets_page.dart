import 'package:mysafar_sdk/src/model/remote/fornex/hot_tickets_model.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/main/main_page.dart' show HotTicketCard;

/// Barcha qaynoq chiptalar — vertikal scroll bilan ochiladigan ro'yxat.
class AllHotTicketsPage extends StatelessWidget {
  final List<HotTicket> flights;

  const AllHotTicketsPage({super.key, required this.flights});

  static const routeName = '/allHotTickets';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text("hot_tickets".tr()),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        itemCount: flights.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => SizedBox(
          height: 210,
          child: HotTicketCard(flight: flights[index]),
        ),
      ),
    );
  }
}
