class PaymentOtpModel {
  String? otpToken;
  String? trId;

  PaymentOtpModel({this.otpToken, this.trId});

  PaymentOtpModel.fromJson(Map<String, dynamic> json) {
    otpToken = json['otp_token'];
    trId = json['tr_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['otp_token'] = otpToken;
    data['tr_id'] = trId;
    return data;
  }
}
