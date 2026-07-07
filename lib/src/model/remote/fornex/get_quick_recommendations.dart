class GetQuickRecommendationsModel {
  String? iata;
  String? titleUz;
  String? titleRu;
  String? titleEn;
  String? type;

  GetQuickRecommendationsModel(
      {this.iata, this.titleUz, this.titleRu, this.titleEn, this.type});

  GetQuickRecommendationsModel.fromJson(Map<String, dynamic> json) {
    iata = json['iata'];
    titleUz = json['title_uz'];
    titleRu = json['title_ru'];
    titleEn = json['title_en'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['iata'] = iata;
    data['title_uz'] = titleUz;
    data['title_ru'] = titleRu;
    data['title_en'] = titleEn;
    data['type'] = type;
    return data;
  }
}
