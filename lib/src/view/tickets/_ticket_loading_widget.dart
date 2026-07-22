part of 'ticket_page.dart';

// ignore: unused_element
class _TicketsLoadingWidget extends StatelessWidget {
  final int flightType;
  const _TicketsLoadingWidget({required this.flightType});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(
              height: 24,
            ),
            Text(
              'loading_tickets'.tr(),
              style: context.textTheme.labelLarge?.copyWith(fontSize: 24),
            ),
            _AirlinesAnimator(),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  height: context.height * 0.22,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: context.color.primaryContainer,
                          borderRadius: BorderRadius.circular(20)),
                      child: Shimmer.fromColors(
                          baseColor: Colors.grey.shade400,
                          highlightColor: const Color(0xff395A87),
                          child: Column(
                            children: [
                              Expanded(
                                  flex: 8,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                  child: Container(
                                                    width: context.width * 0.2,
                                                    height:
                                                        context.height * 0.02,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        color: Colors.amber),
                                                  ),
                                                ),
                                                Container(
                                                  width: 50,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color: Colors.amber),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                  child: Container(
                                                    width: context.width * 0.2,
                                                    height:
                                                        context.height * 0.02,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        color: Colors.amber),
                                                  ),
                                                ),
                                                Container(
                                                  width: 50,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color: Colors.amber),
                                                ),
                                              ],
                                            )),
                                        Flexible(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                  child: Container(
                                                    width: context.width * 0.2,
                                                    height:
                                                        context.height * 0.02,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        color: Colors.amber),
                                                  ),
                                                ),
                                                Container(
                                                  width: 50,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color: Colors.amber),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                  child: Container(
                                                    width: context.width * 0.2,
                                                    height:
                                                        context.height * 0.02,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        color: Colors.amber),
                                                  ),
                                                ),
                                                Container(
                                                  width: 50,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color: Colors.amber),
                                                ),
                                              ],
                                            )),
                                      ],
                                    ),
                                  )),
                              Expanded(
                                  flex: 4,
                                  child: Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Row(
                                                  children: [CircleAvatar()]),
                                              Container(
                                                width: 50,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    color: Colors.amber),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  )),
                            ],
                          ))),
                ),
              ),
            )
          ],
        ),
      );
}

class _AirlinesAnimator extends StatefulWidget {
  const _AirlinesAnimator();

  @override
  State<_AirlinesAnimator> createState() => __AirlinesAnimatorState();
}

class __AirlinesAnimatorState extends State<_AirlinesAnimator>
    with SingleTickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _animationController;

  int _index = 0;
  late Timer _timer;
  final _airlinesDir = 'assets/img/tickets/airlines';

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    );
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener(
            (status) {
              if (status == AnimationStatus.completed) {
                _animationController.repeat();
                setState(() {});
              }
            },
          );

    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      setState(() {
        _index = (_index + 1) % _airlines.length;
      });
    });
    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    debugPrint('loading disposed');
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage:
                  AssetImage('$_airlinesDir/${_airlines[_index]['code']}.png'),
            ),
            const SizedBox(
              width: 12.0,
            ),
            Flexible(
              child: Text(
                "${_airlines[_index]['name']}",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24.0),
          child: LinearProgressIndicator(
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            value: _animation.value,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff395A87)),
          ),
        ),
      ],
    );
  }

  final _airlines = [
    {"name": "AMERICAN AIRLINES INC", "code": "AA"},
    {"name": "CONTINENTAL AIRLINES, INC", "code": "CO"},
    {"name": "DELTA AIR LINES, INC", "code": "DL"},
    {"name": "AIR CANADA", "code": "AC"},
    {"name": "UNITED AIRLINES, INC", "code": "UA"},
    {"name": "LUFTHANSA CARGO AG", "code": "LH"},
    {"name": "HONG KONG DRAGON AIRLINES LIMITED", "code": "KA"},
    {"name": "ALITALIA-COMPAGNIA AEREA ITALIANA S.P", "code": "AZ"},
    {"name": "AIR FRANCE", "code": "AF"},
    {"name": "AIR CALEDONIE INTERNATIONAL", "code": "SB"},
    {"name": "KLM ROYAL DUTCH AIRLINES", "code": "KL"},
    {"name": "EGYPTAIR", "code": "MS"},
    {"name": "PHILIPPINE AIRLINES, INC.", "code": "PR"},
    {"name": "QANTAS AIRWAYS LTD", "code": "QF"},
    {"name": "AIR NEW ZEALAND LTD", "code": "NZ"},
    {"name": "IRAN-AIR", "code": "IR"},
    {"name": "AIR INDIA LTD", "code": "AI"},
    {"name": "FINNAIR O/Y", "code": "AY"},
    {"name": "SCANDINAVIAN AIRLINES SYSTEM(SAS)", "code": "SK"},
    {"name": "BRITISH AIRWAYS P.L.C.", "code": "BA"},
    {"name": "GARUDA INDONESIA", "code": "GA"},
    {"name": "JAPAN AIRLINES CO LTD", "code": "JL"},
    {"name": "AEROMEXICO", "code": "AM"},
    {"name": "CATHAY PACIFIC AIRWAYS LTD.", "code": "CX"},
    {"name": "CARGOLUX AIRLINES INTL S.A.", "code": "CV"},
    {"name": "EMIRATES SKY CARGO", "code": "EK"},
    {"name": "KOREAN AIR LINES CO,LTD.", "code": "KE"},
    {"name": "ALL NIPPON AIRWAYS CO, LTD.", "code": "NH"},
    {"name": "PAKISTAN INTL AIRLINES", "code": "PK"},
    {"name": "THAI AIRWAYS INTL PUBLIC CO.,LTD", "code": "TG"},
    {"name": "MALAYSIA AIRLINES SYSTEM BERHAD", "code": "MH"},
    {"name": "TURKISH AIRLINES INC.", "code": "TK"},
    {"name": "AIR TAHITI NUI", "code": "TN"},
    {"name": "UZBEKISTAN AIRWAYS", "code": "HY"},
    {"name": "AUSTRIAN AIRLINES AG", "code": "OS"},
  ];
}
