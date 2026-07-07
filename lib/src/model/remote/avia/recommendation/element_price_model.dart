part of 'get_recom_res_model.dart';

class FlightPrice {
  FluffyRub? rub;
  FluffyUzs? uzs;
  FluffyRub? usd;

  FlightPrice({required this.rub, required this.uzs, required this.usd});

  factory FlightPrice.fromJson(Map<String, dynamic> json) => FlightPrice(
        rub: json["RUB"] is Map<String, dynamic>
            ? FluffyRub.fromJson(json["RUB"])
            : FluffyRub(
                amount: "0",
              ),
        uzs: json['UZS'] is Map<String, dynamic>
            ? FluffyUzs.fromJson(json['UZS'])
            : FluffyUzs(amount: "0"),
        usd: json["USD"] is Map<String, dynamic>
            ? FluffyRub.fromJson(json["USD"])
            : FluffyRub(
                amount: "0",
              ),
      );
}

class FluffyRub {
  String? amount;

  FluffyRub({
    required this.amount,
  });

  factory FluffyRub.fromJson(Map<String, dynamic> json) => FluffyRub(
        amount: "${json["amount"]}",
      );
}

class FluffyUzs {
  String? amount;
  PassengersAmounts? passengersAmounts;
  AgentModePrices? agentModePrices;
  int? comsa;
  int? partnerAffiliateFee;
  double? startPrice;
  List<PassengersAmountsDetails>? passengersAmountsDetails;

  FluffyUzs(
      {this.amount,
      this.passengersAmounts,
      this.agentModePrices,
      this.comsa,
      this.partnerAffiliateFee,
      this.startPrice,
      this.passengersAmountsDetails});

  FluffyUzs.fromJson(Map<String, dynamic> json) {
    amount = "${json['amount']}";
    passengersAmounts = json['passengers_amounts'] != null
        ? PassengersAmounts.fromJson(json['passengers_amounts'])
        : null;
    agentModePrices = json['agent_mode_prices'] != null
        ? AgentModePrices.fromJson(json['agent_mode_prices'])
        : null;
    comsa = json['comsa'];
    partnerAffiliateFee = json['partner_affiliate_fee'];
    startPrice = _getDouble(json['start_price']);
    if (json['passengers_amounts_details'] != null) {
      passengersAmountsDetails = <PassengersAmountsDetails>[];
      json['passengers_amounts_details'].forEach((v) {
        passengersAmountsDetails!.add(PassengersAmountsDetails.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['amount'] = amount;
    if (passengersAmounts != null) {
      data['passengers_amounts'] = passengersAmounts!.toJson();
    }
    if (agentModePrices != null) {
      data['agent_mode_prices'] = agentModePrices!.toJson();
    }
    data['comsa'] = comsa;
    data['partner_affiliate_fee'] = partnerAffiliateFee;
    data['start_price'] = startPrice;
    if (passengersAmountsDetails != null) {
      data['passengers_amounts_details'] =
          passengersAmountsDetails!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PassengersAmounts {
  int? adult;

  PassengersAmounts({this.adult});

  PassengersAmounts.fromJson(Map<String, dynamic> json) {
    adult = json['adult'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['adult'] = adult;
    return data;
  }
}

class AgentModePrices {
  int? totalAmountForActiveAgentMode;
  int? totalAmountForNonActiveAgentMode;
  int? totalPartnerAffiliateFee;
  double? debitFromBalance;
  List<PassengersAmountsDetails>? passengersAmountsDetails;

  AgentModePrices(
      {this.totalAmountForActiveAgentMode,
      this.totalAmountForNonActiveAgentMode,
      this.totalPartnerAffiliateFee,
      this.debitFromBalance,
      this.passengersAmountsDetails});

  AgentModePrices.fromJson(Map<String, dynamic> json) {
    totalAmountForActiveAgentMode =
        _getInt(json['total_amount_for_active_agent_mode']);
    totalAmountForNonActiveAgentMode =
        _getInt(json['total_amount_for_non_active_agent_mode']);
    totalPartnerAffiliateFee = _getInt(json['total_partner_affiliate_fee']);
    debitFromBalance = _getDouble(json['debit_from_balance']);
    if (json['passengers_amounts_details'] != null) {
      passengersAmountsDetails = <PassengersAmountsDetails>[];
      json['passengers_amounts_details'].forEach((v) {
        passengersAmountsDetails!.add(PassengersAmountsDetails.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_amount_for_active_agent_mode'] = totalAmountForActiveAgentMode;
    data['total_amount_for_non_active_agent_mode'] =
        totalAmountForNonActiveAgentMode;
    data['total_partner_affiliate_fee'] = totalPartnerAffiliateFee;
    data['debit_from_balance'] = debitFromBalance;
    if (passengersAmountsDetails != null) {
      data['passengers_amounts_details'] =
          passengersAmountsDetails!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PassengersAmountsDetails {
  String? type;
  int? amount;
  double? tax;
  int? tariff;
  double? fee;
  int? partnerAffiliateFee;
  int? comsa;

  PassengersAmountsDetails(
      {this.type,
      this.amount,
      this.tax,
      this.tariff,
      this.fee,
      this.partnerAffiliateFee,
      this.comsa});

  PassengersAmountsDetails.fromJson(Map<String, dynamic> json) {
    type = json['type'] ?? "";
    amount = _getInt(json['amount']);
    tax = _getDouble(json['tax']);
    tariff = _getInt(json['tariff']);
    fee = _getDouble(json['fee']);
    partnerAffiliateFee = _getInt(json['fee']);
    comsa = _getInt(json['comsa']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['amount'] = amount;
    data['tax'] = tax;
    data['tariff'] = tariff;
    data['fee'] = fee;
    data['partner_affiliate_fee'] = partnerAffiliateFee;
    data['comsa'] = comsa;
    return data;
  }
}
