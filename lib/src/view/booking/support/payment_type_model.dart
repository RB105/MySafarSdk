class PaymentTypeModel {
  final String id;
  final String selectImage;
  final String cardName;

  PaymentTypeModel({
    required this.id,
    required this.selectImage,
    this.cardName = "",
  });
}
