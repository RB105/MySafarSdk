import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart';

class FlightTariffModel {
  final FlightElement flight;
  final FeesInfo? feesInfo;

  FlightTariffModel({required this.flight, this.feesInfo});

  factory FlightTariffModel.fromJson(Map<String, dynamic> json) {
    return FlightTariffModel(
        flight: FlightElement.fromJson(json['flight']),
        feesInfo: FeesInfo.fromJson(json['fees_info']));
  }

  void getMaxBaggage() {}
}

class FeesInfo {
  final int? comsa;
  final int? partnerAffiliateFee;

  FeesInfo({this.comsa, this.partnerAffiliateFee});

  factory FeesInfo.fromJson(Map<String, dynamic> json) {
    return FeesInfo(
      comsa: json['comsa'],
      partnerAffiliateFee: json['partner_affiliate_fee'],
    );
  }
}
