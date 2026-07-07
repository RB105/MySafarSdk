Map<String, dynamic> getCountry(String code) {
  return countryCodes.firstWhere((country) => country["code"] == code,
      orElse: () => {
            "name": {
              "en": "Uzbekistan",
              "ru": "Узбекистан",
              "uz": "O'zbekiston"
            },
            "code": "UZ",
            "dial_code": "+998"
          });
}

List<Map<String, dynamic>> countryCodes = [
  {
    "name": {"en": "Uzbekistan", "ru": "Узбекистан", "uz": "O'zbekiston"},
    "code": "UZ",
    "dial_code": "+998"
  },
  {
    "name": {"en": "Afghanistan", "ru": "Афганистан", "uz": "Afgʻoniston"},
    "code": "AF",
    "dial_code": "+93"
  },
  {
    "name": {
      "en": "Åland Islands",
      "ru": "Аландские острова",
      "uz": "Aland orollari"
    },
    "code": "AX",
    "dial_code": "+358"
  },
  {
    "name": {"en": "Albania", "ru": "Албания", "uz": "Albaniya"},
    "code": "AL",
    "dial_code": "+355"
  },
  {
    "name": {"en": "Algeria", "ru": "Алжир", "uz": "Jazoir"},
    "code": "DZ",
    "dial_code": "+213"
  },
  {
    "name": {
      "en": "American Samoa",
      "ru": "Американское Самоа",
      "uz": "Amerika Samoasi"
    },
    "code": "AS",
    "dial_code": "+1684"
  },
  {
    "name": {"en": "Andorra", "ru": "Андорра", "uz": "Andorra"},
    "code": "AD",
    "dial_code": "+376"
  },
  {
    "name": {"en": "Angola", "ru": "Ангола", "uz": "Angola"},
    "code": "AO",
    "dial_code": "+244"
  },
  {
    "name": {"en": "Anguilla", "ru": "Ангилья", "uz": "Angilya"},
    "code": "AI",
    "dial_code": "+1264"
  },
  {
    "name": {"en": "Antarctica", "ru": "Антарктида", "uz": "Antarktida"},
    "code": "AQ",
    "dial_code": "+672"
  },
  {
    "name": {
      "en": "Antigua and Barbuda",
      "ru": "Антигуа и Барбуда",
      "uz": "Antigua va Barbuda"
    },
    "code": "AG",
    "dial_code": "+1268"
  },
  {
    "name": {"en": "Argentina", "ru": "Аргентина", "uz": "Argentina"},
    "code": "AR",
    "dial_code": "+54"
  },
  {
    "name": {"en": "Armenia", "ru": "Армения", "uz": "Armaniston"},
    "code": "AM",
    "dial_code": "+374"
  },
  {
    "name": {"en": "Aruba", "ru": "Аруба", "uz": "Aruba"},
    "code": "AW",
    "dial_code": "+297"
  },
  {
    "name": {"en": "Australia", "ru": "Австралия", "uz": "Avstraliya"},
    "code": "AU",
    "dial_code": "+61"
  },
  {
    "name": {"en": "Austria", "ru": "Австрия", "uz": "Avstriya"},
    "code": "AT",
    "dial_code": "+43"
  },
  {
    "name": {"en": "Azerbaijan", "ru": "Азербайджан", "uz": "Ozarbayjon"},
    "code": "AZ",
    "dial_code": "+994"
  },
  {
    "name": {
      "en": "Bahamas",
      "ru": "Багамские Острова",
      "uz": "Bagama orollari"
    },
    "code": "BS",
    "dial_code": "+1242"
  },
  {
    "name": {"en": "Bahrain", "ru": "Бахрейн", "uz": "Bahrayn"},
    "code": "BH",
    "dial_code": "+973"
  },
  {
    "name": {"en": "Bangladesh", "ru": "Бангладеш", "uz": "Bangladesh"},
    "code": "BD",
    "dial_code": "+880"
  },
  {
    "name": {"en": "Barbados", "ru": "Барбадос", "uz": "Barbados"},
    "code": "BB",
    "dial_code": "+1246"
  },
  {
    "name": {"en": "Belarus", "ru": "Беларусь", "uz": "Belarus"},
    "code": "BY",
    "dial_code": "+375"
  },
  {
    "name": {"en": "Belgium", "ru": "Бельгия", "uz": "Belgiya"},
    "code": "BE",
    "dial_code": "+32"
  },
  {
    "name": {"en": "Belize", "ru": "Белиз", "uz": "Beliz"},
    "code": "BZ",
    "dial_code": "+501"
  },
  {
    "name": {"en": "Benin", "ru": "Бенин", "uz": "Benin"},
    "code": "BJ",
    "dial_code": "+229"
  },
  {
    "name": {
      "en": "Bermuda",
      "ru": "Бермудские Острова",
      "uz": "Bermud orollari"
    },
    "code": "BM",
    "dial_code": "+1441"
  },
  {
    "name": {"en": "Bhutan", "ru": "Бутан", "uz": "Butan"},
    "code": "BT",
    "dial_code": "+975"
  },
  {
    "name": {"en": "Bolivia", "ru": "Боливия", "uz": "Boliviya"},
    "code": "BO",
    "dial_code": "+591"
  },
  {
    "name": {
      "en": "Bosnia and Herzegovina",
      "ru": "Босния и Герцеговина",
      "uz": "Bosniya va Gertsegovina"
    },
    "code": "BA",
    "dial_code": "+387"
  },
  {
    "name": {"en": "Botswana", "ru": "Ботсвана", "uz": "Botsvana"},
    "code": "BW",
    "dial_code": "+267"
  },
  {
    "name": {"en": "Bouvet Island", "ru": "Остров Буве", "uz": "Buve oroli"},
    "code": "BV",
    "dial_code": "+47"
  },
  {
    "name": {"en": "Brazil", "ru": "Бразилия", "uz": "Braziliya"},
    "code": "BR",
    "dial_code": "+55"
  },
  {
    "name": {
      "en": "British Indian Ocean Territory",
      "ru": "Британская территория в Индийском океане",
      "uz": "Britaniya Hind okeani hududi"
    },
    "code": "IO",
    "dial_code": "+246"
  },
  {
    "name": {"en": "Brunei", "ru": "Бруней", "uz": "Bruney"},
    "code": "BN",
    "dial_code": "+673"
  },
  {
    "name": {"en": "Bulgaria", "ru": "Болгария", "uz": "Bolgariya"},
    "code": "BG",
    "dial_code": "+359"
  },
  {
    "name": {"en": "Burkina Faso", "ru": "Буркина-Фасо", "uz": "Burkina-Faso"},
    "code": "BF",
    "dial_code": "+226"
  },
  {
    "name": {"en": "Burundi", "ru": "Бурунди", "uz": "Burundi"},
    "code": "BI",
    "dial_code": "+257"
  },
  {
    "name": {"en": "Cambodia", "ru": "Камбоджа", "uz": "Kambodja"},
    "code": "KH",
    "dial_code": "+855"
  },
  {
    "name": {"en": "Cameroon", "ru": "Камерун", "uz": "Kamerun"},
    "code": "CM",
    "dial_code": "+237"
  },
  {
    "name": {"en": "Canada", "ru": "Канада", "uz": "Kanada"},
    "code": "CA",
    "dial_code": "+1"
  },
  {
    "name": {"en": "Cape Verde", "ru": "Кабо-Верде", "uz": "Kabo-Verde"},
    "code": "CV",
    "dial_code": "+238"
  },
  {
    "name": {
      "en": "Cayman Islands",
      "ru": "Каймановы острова",
      "uz": "Kayman orollari"
    },
    "code": "KY",
    "dial_code": "+1345"
  },
  {
    "name": {
      "en": "Central African Republic",
      "ru": "Центральноафриканская Республика",
      "uz": "Markaziy Afrika Respublikasi"
    },
    "code": "CF",
    "dial_code": "+236"
  },
  {
    "name": {"en": "Chad", "ru": "Чад", "uz": "Chad"},
    "code": "TD",
    "dial_code": "+235"
  },
  {
    "name": {"en": "Chile", "ru": "Чили", "uz": "Chili"},
    "code": "CL",
    "dial_code": "+56"
  },
  {
    "name": {"en": "China", "ru": "Китай", "uz": "Xitoy"},
    "code": "CN",
    "dial_code": "+86"
  },
  {
    "name": {
      "en": "Christmas Island",
      "ru": "Остров Рождества",
      "uz": "Rojdestvo oroli"
    },
    "code": "CX",
    "dial_code": "+61"
  },
  {
    "name": {
      "en": "Cocos (Keeling) Islands",
      "ru": "Кокосовые острова",
      "uz": "Kokos orollari"
    },
    "code": "CC",
    "dial_code": "+61"
  },
  {
    "name": {"en": "Colombia", "ru": "Колумбия", "uz": "Kolumbiya"},
    "code": "CO",
    "dial_code": "+57"
  },
  {
    "name": {"en": "Comoros", "ru": "Коморы", "uz": "Komor orollari"},
    "code": "KM",
    "dial_code": "+269"
  },
  {
    "name": {"en": "Congo", "ru": "Конго", "uz": "Kongo"},
    "code": "CG",
    "dial_code": "+242"
  },
  {
    "name": {
      "en": "Democratic Republic of the Congo",
      "ru": "Демократическая Республика Конго",
      "uz": "Kongo Demokratik Respublikasi"
    },
    "code": "CD",
    "dial_code": "+243"
  },
  {
    "name": {"en": "Cook Islands", "ru": "Острова Кука", "uz": "Kuk orollari"},
    "code": "CK",
    "dial_code": "+682"
  },
  {
    "name": {"en": "Costa Rica", "ru": "Коста-Рика", "uz": "Kosta-Rika"},
    "code": "CR",
    "dial_code": "+506"
  },
  {
    "name": {"en": "Côte d'Ivoire", "ru": "Кот-д’Ивуар", "uz": "Kot-d’Ivuar"},
    "code": "CI",
    "dial_code": "+225"
  },
  {
    "name": {"en": "Croatia", "ru": "Хорватия", "uz": "Xorvatiya"},
    "code": "HR",
    "dial_code": "+385"
  },
  {
    "name": {"en": "Cuba", "ru": "Куба", "uz": "Kuba"},
    "code": "CU",
    "dial_code": "+53"
  },
  {
    "name": {"en": "Cyprus", "ru": "Кипр", "uz": "Qibris"},
    "code": "CY",
    "dial_code": "+357"
  },
  {
    "name": {"en": "Czech Republic", "ru": "Чехия", "uz": "Chexiya"},
    "code": "CZ",
    "dial_code": "+420"
  },
  {
    "name": {"en": "Denmark", "ru": "Дания", "uz": "Daniya"},
    "code": "DK",
    "dial_code": "+45"
  },
  {
    "name": {"en": "Djibouti", "ru": "Джибути", "uz": "Jibuti"},
    "code": "DJ",
    "dial_code": "+253"
  },
  {
    "name": {"en": "Dominica", "ru": "Доминика", "uz": "Dominika"},
    "code": "DM",
    "dial_code": "+1767"
  },
  {
    "name": {
      "en": "Dominican Republic",
      "ru": "Доминиканская Республика",
      "uz": "Dominikan Respublikasi"
    },
    "code": "DO",
    "dial_code": "+1"
  },
  {
    "name": {"en": "Ecuador", "ru": "Эквадор", "uz": "Ekvador"},
    "code": "EC",
    "dial_code": "+593"
  },
  {
    "name": {"en": "Egypt", "ru": "Египет", "uz": "Misr"},
    "code": "EG",
    "dial_code": "+20"
  },
  {
    "name": {"en": "El Salvador", "ru": "Сальвадор", "uz": "Salvador"},
    "code": "SV",
    "dial_code": "+503"
  },
  {
    "name": {
      "en": "Equatorial Guinea",
      "ru": "Экваториальная Гвинея",
      "uz": "Ekvatorial Gvineya"
    },
    "code": "GQ",
    "dial_code": "+240"
  },
  {
    "name": {"en": "Eritrea", "ru": "Эритрея", "uz": "Eritreya"},
    "code": "ER",
    "dial_code": "+291"
  },
  {
    "name": {"en": "Estonia", "ru": "Эстония", "uz": "Estoniya"},
    "code": "EE",
    "dial_code": "+372"
  },
  {
    "name": {"en": "Ethiopia", "ru": "Эфиопия", "uz": "Efiopiya"},
    "code": "ET",
    "dial_code": "+251"
  },
  {
    "name": {
      "en": "Falkland Islands",
      "ru": "Фолклендские острова",
      "uz": "Folklend orollari"
    },
    "code": "FK",
    "dial_code": "+500"
  },
  {
    "name": {
      "en": "Faroe Islands",
      "ru": "Фарерские острова",
      "uz": "Farer orollari"
    },
    "code": "FO",
    "dial_code": "+298"
  },
  {
    "name": {"en": "Fiji", "ru": "Фиджи", "uz": "Fiji"},
    "code": "FJ",
    "dial_code": "+679"
  },
  {
    "name": {"en": "Finland", "ru": "Финляндия", "uz": "Finlandiya"},
    "code": "FI",
    "dial_code": "+358"
  },
  {
    "name": {"en": "France", "ru": "Франция", "uz": "Fransiya"},
    "code": "FR",
    "dial_code": "+33"
  },
  {
    "name": {
      "en": "French Guiana",
      "ru": "Французская Гвиана",
      "uz": "Fransuz Gvianasi"
    },
    "code": "GF",
    "dial_code": "+594"
  },
  {
    "name": {
      "en": "French Polynesia",
      "ru": "Французская Полинезия",
      "uz": "Fransuz Polineziyasi"
    },
    "code": "PF",
    "dial_code": "+689"
  },
  {
    "name": {
      "en": "French Southern Territories",
      "ru": "Французские Южные территории",
      "uz": "Fransuz Janubiy hududlari"
    },
    "code": "TF",
    "dial_code": "+262"
  },
  {
    "name": {"en": "Gabon", "ru": "Габон", "uz": "Gabon"},
    "code": "GA",
    "dial_code": "+241"
  },
  {
    "name": {"en": "Gambia", "ru": "Гамбия", "uz": "Gambiya"},
    "code": "GM",
    "dial_code": "+220"
  },
  {
    "name": {"en": "Georgia", "ru": "Грузия", "uz": "Gruziya"},
    "code": "GE",
    "dial_code": "+995"
  },
  {
    "name": {"en": "Germany", "ru": "Германия", "uz": "Germaniya"},
    "code": "DE",
    "dial_code": "+49"
  },
  {
    "name": {"en": "Ghana", "ru": "Гана", "uz": "Gana"},
    "code": "GH",
    "dial_code": "+233"
  },
  {
    "name": {"en": "Gibraltar", "ru": "Гибралтар", "uz": "Gibraltar"},
    "code": "GI",
    "dial_code": "+350"
  },
  {
    "name": {"en": "Greece", "ru": "Греция", "uz": "Gretsiya"},
    "code": "GR",
    "dial_code": "+30"
  },
  {
    "name": {"en": "Greenland", "ru": "Гренландия", "uz": "Grenlandiya"},
    "code": "GL",
    "dial_code": "+299"
  },
  {
    "name": {"en": "Grenada", "ru": "Гренада", "uz": "Grenada"},
    "code": "GD",
    "dial_code": "+1473"
  },
  {
    "name": {"en": "Guadeloupe", "ru": "Гваделупа", "uz": "Gvadelupa"},
    "code": "GP",
    "dial_code": "+590"
  },
  {
    "name": {"en": "Guam", "ru": "Гуам", "uz": "Guam"},
    "code": "GU",
    "dial_code": "+1671"
  },
  {
    "name": {"en": "Guatemala", "ru": "Гватемала", "uz": "Gvatemala"},
    "code": "GT",
    "dial_code": "+502"
  },
  {
    "name": {"en": "Guernsey", "ru": "Гернси", "uz": "Gernsi"},
    "code": "GG",
    "dial_code": "+44"
  },
  {
    "name": {"en": "Guinea", "ru": "Гвинея", "uz": "Gvineya"},
    "code": "GN",
    "dial_code": "+224"
  },
  {
    "name": {
      "en": "Guinea-Bissau",
      "ru": "Гвинея-Бисау",
      "uz": "Gvineya-Bisau"
    },
    "code": "GW",
    "dial_code": "+245"
  },
  {
    "name": {"en": "Guyana", "ru": "Гайана", "uz": "Gayana"},
    "code": "GY",
    "dial_code": "+592"
  },
  {
    "name": {"en": "Haiti", "ru": "Гаити", "uz": "Gaiti"},
    "code": "HT",
    "dial_code": "+509"
  },
  {
    "name": {
      "en": "Heard Island and McDonald Islands",
      "ru": "Остров Херд и острова Макдональд",
      "uz": "Xerd va Makdonald orollari"
    },
    "code": "HM",
    "dial_code": "+0"
  },
  {
    "name": {"en": "Vatican City", "ru": "Ватикан", "uz": "Vatikan"},
    "code": "VA",
    "dial_code": "+379"
  },
  {
    "name": {"en": "Honduras", "ru": "Гондурас", "uz": "Gonduras"},
    "code": "HN",
    "dial_code": "+504"
  },
  {
    "name": {"en": "Hong Kong", "ru": "Гонконг", "uz": "Gonkong"},
    "code": "HK",
    "dial_code": "+852"
  },
  {
    "name": {"en": "Hungary", "ru": "Венгрия", "uz": "Vengriya"},
    "code": "HU",
    "dial_code": "+36"
  },
  {
    "name": {"en": "Iceland", "ru": "Исландия", "uz": "Islandiya"},
    "code": "IS",
    "dial_code": "+354"
  },
  {
    "name": {"en": "India", "ru": "Индия", "uz": "Hindiston"},
    "code": "IN",
    "dial_code": "+91"
  },
  {
    "name": {"en": "Indonesia", "ru": "Индонезия", "uz": "Indoneziya"},
    "code": "ID",
    "dial_code": "+62"
  },
  {
    "name": {"en": "Iran", "ru": "Иран", "uz": "Eron"},
    "code": "IR",
    "dial_code": "+98"
  },
  {
    "name": {"en": "Iraq", "ru": "Ирак", "uz": "Iroq"},
    "code": "IQ",
    "dial_code": "+964"
  },
  {
    "name": {"en": "Ireland", "ru": "Ирландия", "uz": "Irlandiya"},
    "code": "IE",
    "dial_code": "+353"
  },
  {
    "name": {"en": "Isle of Man", "ru": "Остров Мэн", "uz": "Men oroli"},
    "code": "IM",
    "dial_code": "+44"
  },
  {
    "name": {"en": "Israel", "ru": "Израиль", "uz": "Isroil"},
    "code": "IL",
    "dial_code": "+972"
  },
  {
    "name": {"en": "Italy", "ru": "Италия", "uz": "Italiya"},
    "code": "IT",
    "dial_code": "+39"
  },
  {
    "name": {"en": "Jamaica", "ru": "Ямайка", "uz": "Yamayka"},
    "code": "JM",
    "dial_code": "+1876"
  },
  {
    "name": {"en": "Japan", "ru": "Япония", "uz": "Yaponiya"},
    "code": "JP",
    "dial_code": "+81"
  },
  {
    "name": {"en": "Jersey", "ru": "Джерси", "uz": "Jersi"},
    "code": "JE",
    "dial_code": "+44"
  },
  {
    "name": {"en": "Jordan", "ru": "Иордания", "uz": "Iordaniya"},
    "code": "JO",
    "dial_code": "+962"
  },
  {
    "name": {"en": "Kazakhstan", "ru": "Казахстан", "uz": "Qozogʻiston"},
    "code": "KZ",
    "dial_code": "+7"
  },
  {
    "name": {"en": "Kenya", "ru": "Кения", "uz": "Keniya"},
    "code": "KE",
    "dial_code": "+254"
  },
  {
    "name": {"en": "Kiribati", "ru": "Кирибати", "uz": "Kiribati"},
    "code": "KI",
    "dial_code": "+686"
  },
  {
    "name": {
      "en": "North Korea",
      "ru": "Северная Корея",
      "uz": "Shimoliy Koreya"
    },
    "code": "KP",
    "dial_code": "+850"
  },
  {
    "name": {"en": "South Korea", "ru": "Южная Корея", "uz": "Janubiy Koreya"},
    "code": "KR",
    "dial_code": "+82"
  },
  {
    "name": {"en": "Kosovo", "ru": "Косово", "uz": "Kosovo"},
    "code": "XK",
    "dial_code": "+383"
  },
  {
    "name": {"en": "Kuwait", "ru": "Кувейт", "uz": "Quvayt"},
    "code": "KW",
    "dial_code": "+965"
  },
  {
    "name": {"en": "Kyrgyzstan", "ru": "Кыргызстан", "uz": "Qirgʻiziston"},
    "code": "KG",
    "dial_code": "+996"
  },
  {
    "name": {"en": "Laos", "ru": "Лаос", "uz": "Laos"},
    "code": "LA",
    "dial_code": "+856"
  },
  {
    "name": {"en": "Latvia", "ru": "Латвия", "uz": "Latviya"},
    "code": "LV",
    "dial_code": "+371"
  },
  {
    "name": {"en": "Lebanon", "ru": "Ливан", "uz": "Livan"},
    "code": "LB",
    "dial_code": "+961"
  },
  {
    "name": {"en": "Lesotho", "ru": "Лесото", "uz": "Lesoto"},
    "code": "LS",
    "dial_code": "+266"
  },
  {
    "name": {"en": "Liberia", "ru": "Либерия", "uz": "Liberiya"},
    "code": "LR",
    "dial_code": "+231"
  },
  {
    "name": {"en": "Libya", "ru": "Ливия", "uz": "Liviya"},
    "code": "LY",
    "dial_code": "+218"
  },
  {
    "name": {"en": "Liechtenstein", "ru": "Лихтенштейн", "uz": "Lixtenshteyn"},
    "code": "LI",
    "dial_code": "+423"
  },
  {
    "name": {"en": "Lithuania", "ru": "Литва", "uz": "Litva"},
    "code": "LT",
    "dial_code": "+370"
  },
  {
    "name": {"en": "Luxembourg", "ru": "Люксембург", "uz": "Lyuksemburg"},
    "code": "LU",
    "dial_code": "+352"
  },
  {
    "name": {"en": "Macau", "ru": "Макао", "uz": "Makao"},
    "code": "MO",
    "dial_code": "+853"
  },
  {
    "name": {
      "en": "North Macedonia",
      "ru": "Северная Македония",
      "uz": "Shimoliy Makedoniya"
    },
    "code": "MK",
    "dial_code": "+389"
  },
  {
    "name": {"en": "Madagascar", "ru": "Мадагаскар", "uz": "Madagaskar"},
    "code": "MG",
    "dial_code": "+261"
  },
  {
    "name": {"en": "Malawi", "ru": "Малави", "uz": "Malavi"},
    "code": "MW",
    "dial_code": "+265"
  },
  {
    "name": {"en": "Malaysia", "ru": "Малайзия", "uz": "Malayziya"},
    "code": "MY",
    "dial_code": "+60"
  },
  {
    "name": {"en": "Maldives", "ru": "Мальдивы", "uz": "Maldiv orollari"},
    "code": "MV",
    "dial_code": "+960"
  },
  {
    "name": {"en": "Mali", "ru": "Мали", "uz": "Mali"},
    "code": "ML",
    "dial_code": "+223"
  },
  {
    "name": {"en": "Malta", "ru": "Мальта", "uz": "Malta"},
    "code": "MT",
    "dial_code": "+356"
  },
  {
    "name": {
      "en": "Marshall Islands",
      "ru": "Маршалловы Острова",
      "uz": "Marshall orollari"
    },
    "code": "MH",
    "dial_code": "+692"
  },
  {
    "name": {"en": "Martinique", "ru": "Мартиника", "uz": "Martinika"},
    "code": "MQ",
    "dial_code": "+596"
  },
  {
    "name": {"en": "Mauritania", "ru": "Мавритания", "uz": "Mavritaniya"},
    "code": "MR",
    "dial_code": "+222"
  },
  {
    "name": {"en": "Mauritius", "ru": "Маврикий", "uz": "Mavrikiy"},
    "code": "MU",
    "dial_code": "+230"
  },
  {
    "name": {"en": "Mayotte", "ru": "Майотта", "uz": "Mayotta"},
    "code": "YT",
    "dial_code": "+262"
  },
  {
    "name": {"en": "Mexico", "ru": "Мексика", "uz": "Meksika"},
    "code": "MX",
    "dial_code": "+52"
  },
  {
    "name": {"en": "Micronesia", "ru": "Микронезия", "uz": "Mikroneziya"},
    "code": "FM",
    "dial_code": "+691"
  },
  {
    "name": {"en": "Moldova", "ru": "Молдова", "uz": "Moldova"},
    "code": "MD",
    "dial_code": "+373"
  },
  {
    "name": {"en": "Monaco", "ru": "Монако", "uz": "Monako"},
    "code": "MC",
    "dial_code": "+377"
  },
  {
    "name": {"en": "Mongolia", "ru": "Монголия", "uz": "Moʻgʻuliston"},
    "code": "MN",
    "dial_code": "+976"
  },
  {
    "name": {"en": "Montenegro", "ru": "Черногория", "uz": "Chernogoriya"},
    "code": "ME",
    "dial_code": "+382"
  },
  {
    "name": {"en": "Montserrat", "ru": "Монтсеррат", "uz": "Montserrat"},
    "code": "MS",
    "dial_code": "+1664"
  },
  {
    "name": {"en": "Morocco", "ru": "Марокко", "uz": "Marokash"},
    "code": "MA",
    "dial_code": "+212"
  },
  {
    "name": {"en": "Mozambique", "ru": "Мозамбик", "uz": "Mozambik"},
    "code": "MZ",
    "dial_code": "+258"
  },
  {
    "name": {"en": "Myanmar", "ru": "Мьянма", "uz": "Myanma"},
    "code": "MM",
    "dial_code": "+95"
  },
  {
    "name": {"en": "Namibia", "ru": "Намибия", "uz": "Namibiya"},
    "code": "NA",
    "dial_code": "+264"
  },
  {
    "name": {"en": "Nauru", "ru": "Науру", "uz": "Nauru"},
    "code": "NR",
    "dial_code": "+674"
  },
  {
    "name": {"en": "Nepal", "ru": "Непал", "uz": "Nepal"},
    "code": "NP",
    "dial_code": "+977"
  },
  {
    "name": {"en": "Netherlands", "ru": "Нидерланды", "uz": "Niderlandiya"},
    "code": "NL",
    "dial_code": "+31"
  },
  {
    "name": {
      "en": "Netherlands Antilles",
      "ru": "Нидерландские Антильские острова",
      "uz": "Niderland Antill orollari"
    },
    "code": "AN",
    "dial_code": "+599"
  },
  {
    "name": {
      "en": "New Caledonia",
      "ru": "Новая Каледония",
      "uz": "Yangi Kaledoniya"
    },
    "code": "NC",
    "dial_code": "+687"
  },
  {
    "name": {
      "en": "New Zealand",
      "ru": "Новая Зеландия",
      "uz": "Yangi Zelandiya"
    },
    "code": "NZ",
    "dial_code": "+64"
  },
  {
    "name": {"en": "Nicaragua", "ru": "Никарагуа", "uz": "Nikaragua"},
    "code": "NI",
    "dial_code": "+505"
  },
  {
    "name": {"en": "Niger", "ru": "Нигер", "uz": "Niger"},
    "code": "NE",
    "dial_code": "+227"
  },
  {
    "name": {"en": "Nigeria", "ru": "Нигерия", "uz": "Nigeriya"},
    "code": "NG",
    "dial_code": "+234"
  },
  {
    "name": {"en": "Niue", "ru": "Ниуэ", "uz": "Niue"},
    "code": "NU",
    "dial_code": "+683"
  },
  {
    "name": {
      "en": "Norfolk Island",
      "ru": "Остров Норфолк",
      "uz": "Norfolk oroli"
    },
    "code": "NF",
    "dial_code": "+672"
  },
  {
    "name": {
      "en": "Northern Mariana Islands",
      "ru": "Северные Марианские острова",
      "uz": "Shimoliy Mariana orollari"
    },
    "code": "MP",
    "dial_code": "+1670"
  },
  {
    "name": {"en": "Norway", "ru": "Норвегия", "uz": "Norvegiya"},
    "code": "NO",
    "dial_code": "+47"
  },
  {
    "name": {"en": "Oman", "ru": "Оман", "uz": "Ummon"},
    "code": "OM",
    "dial_code": "+968"
  },
  {
    "name": {"en": "Pakistan", "ru": "Пакистан", "uz": "Pokiston"},
    "code": "PK",
    "dial_code": "+92"
  },
  {
    "name": {"en": "Palau", "ru": "Палау", "uz": "Palau"},
    "code": "PW",
    "dial_code": "+680"
  },
  {
    "name": {"en": "Palestine", "ru": "Палестина", "uz": "Falastin"},
    "code": "PS",
    "dial_code": "+970"
  },
  {
    "name": {"en": "Panama", "ru": "Панама", "uz": "Panama"},
    "code": "PA",
    "dial_code": "+507"
  },
  {
    "name": {
      "en": "Papua New Guinea",
      "ru": "Папуа — Новая Гвинея",
      "uz": "Papua Yangi Gvineya"
    },
    "code": "PG",
    "dial_code": "+675"
  },
  {
    "name": {"en": "Paraguay", "ru": "Парагвай", "uz": "Paragvay"},
    "code": "PY",
    "dial_code": "+595"
  },
  {
    "name": {"en": "Peru", "ru": "Перу", "uz": "Peru"},
    "code": "PE",
    "dial_code": "+51"
  },
  {
    "name": {"en": "Philippines", "ru": "Филиппины", "uz": "Filippin"},
    "code": "PH",
    "dial_code": "+63"
  },
  {
    "name": {
      "en": "Pitcairn Islands",
      "ru": "Острова Питкэрн",
      "uz": "Pitkern orollari"
    },
    "code": "PN",
    "dial_code": "+64"
  },
  {
    "name": {"en": "Poland", "ru": "Польша", "uz": "Polsha"},
    "code": "PL",
    "dial_code": "+48"
  },
  {
    "name": {"en": "Portugal", "ru": "Португалия", "uz": "Portugaliya"},
    "code": "PT",
    "dial_code": "+351"
  },
  {
    "name": {"en": "Puerto Rico", "ru": "Пуэрто-Рико", "uz": "Puerto-Riko"},
    "code": "PR",
    "dial_code": "+1939"
  },
  {
    "name": {"en": "Puerto Rico", "ru": "Пуэрто-Рико", "uz": "Puerto-Riko"},
    "code": "PR",
    "dial_code": "+1787"
  },
  {
    "name": {"en": "Qatar", "ru": "Катар", "uz": "Qatar"},
    "code": "QA",
    "dial_code": "+974"
  },
  {
    "name": {"en": "Romania", "ru": "Румыния", "uz": "Ruminiya"},
    "code": "RO",
    "dial_code": "+40"
  },
  {
    "name": {"en": "Russia", "ru": "Россия", "uz": "Rossiya"},
    "code": "RU",
    "dial_code": "+7"
  },
  {
    "name": {"en": "Rwanda", "ru": "Руанда", "uz": "Ruanda"},
    "code": "RW",
    "dial_code": "+250"
  },
  {
    "name": {"en": "Réunion", "ru": "Реюньон", "uz": "Reyunyon"},
    "code": "RE",
    "dial_code": "+262"
  },
  {
    "name": {
      "en": "Saint Barthélemy",
      "ru": "Сен-Бартелеми",
      "uz": "Sen-Bartelemi"
    },
    "code": "BL",
    "dial_code": "+590"
  },
  {
    "name": {
      "en": "Saint Helena",
      "ru": "Остров Святой Елены",
      "uz": "Muqaddas Yelena oroli"
    },
    "code": "SH",
    "dial_code": "+290"
  },
  {
    "name": {
      "en": "Saint Kitts and Nevis",
      "ru": "Сент-Китс и Невис",
      "uz": "Sent-Kits va Nevis"
    },
    "code": "KN",
    "dial_code": "+1869"
  },
  {
    "name": {"en": "Saint Lucia", "ru": "Сент-Люсия", "uz": "Sent-Lyusiya"},
    "code": "LC",
    "dial_code": "+1758"
  },
  {
    "name": {"en": "Saint Martin", "ru": "Сен-Мартен", "uz": "Sen-Marten"},
    "code": "MF",
    "dial_code": "+590"
  },
  {
    "name": {
      "en": "Saint Pierre and Miquelon",
      "ru": "Сен-Пьер и Микелон",
      "uz": "Sen-Pyer va Mikelon"
    },
    "code": "PM",
    "dial_code": "+508"
  },
  {
    "name": {
      "en": "Saint Vincent and the Grenadines",
      "ru": "Сент-Винсент и Гренадины",
      "uz": "Sent-Vinsent va Grenadinlar"
    },
    "code": "VC",
    "dial_code": "+1784"
  },
  {
    "name": {"en": "Samoa", "ru": "Самоа", "uz": "Samoa"},
    "code": "WS",
    "dial_code": "+685"
  },
  {
    "name": {"en": "San Marino", "ru": "Сан-Марино", "uz": "San-Marino"},
    "code": "SM",
    "dial_code": "+378"
  },
  {
    "name": {
      "en": "São Tomé and Príncipe",
      "ru": "Сан-Томе и Принсипи",
      "uz": "San-Tome va Prinsipi"
    },
    "code": "ST",
    "dial_code": "+239"
  },
  {
    "name": {
      "en": "Saudi Arabia",
      "ru": "Саудовская Аравия",
      "uz": "Saudiya Arabistoni"
    },
    "code": "SA",
    "dial_code": "+966"
  },
  {
    "name": {"en": "Senegal", "ru": "Сенегал", "uz": "Senegal"},
    "code": "SN",
    "dial_code": "+221"
  },
  {
    "name": {"en": "Serbia", "ru": "Сербия", "uz": "Serbiya"},
    "code": "RS",
    "dial_code": "+381"
  },
  {
    "name": {
      "en": "Seychelles",
      "ru": "Сейшельские Острова",
      "uz": "Seyshel orollari"
    },
    "code": "SC",
    "dial_code": "+248"
  },
  {
    "name": {"en": "Sierra Leone", "ru": "Сьерра-Леоне", "uz": "Syerra-Leone"},
    "code": "SL",
    "dial_code": "+232"
  },
  {
    "name": {"en": "Singapore", "ru": "Сингапур", "uz": "Singapur"},
    "code": "SG",
    "dial_code": "+65"
  },
  {
    "name": {"en": "Slovakia", "ru": "Словакия", "uz": "Slovakiya"},
    "code": "SK",
    "dial_code": "+421"
  },
  {
    "name": {"en": "Slovenia", "ru": "Словения", "uz": "Sloveniya"},
    "code": "SI",
    "dial_code": "+386"
  },
  {
    "name": {
      "en": "Solomon Islands",
      "ru": "Соломоновы Острова",
      "uz": "Solomon orollari"
    },
    "code": "SB",
    "dial_code": "+677"
  },
  {
    "name": {"en": "Somalia", "ru": "Сомали", "uz": "Somali"},
    "code": "SO",
    "dial_code": "+252"
  },
  {
    "name": {
      "en": "South Africa",
      "ru": "Южная Африка",
      "uz": "Janubiy Afrika"
    },
    "code": "ZA",
    "dial_code": "+27"
  },
  {
    "name": {"en": "South Sudan", "ru": "Южный Судан", "uz": "Janubiy Sudan"},
    "code": "SS",
    "dial_code": "+211"
  },
  {
    "name": {
      "en": "South Georgia",
      "ru": "Южная Георгия",
      "uz": "Janubiy Jorjiya"
    },
    "code": "GS",
    "dial_code": "+500"
  },
  {
    "name": {"en": "Spain", "ru": "Испания", "uz": "Ispaniya"},
    "code": "ES",
    "dial_code": "+34"
  },
  {
    "name": {"en": "Sri Lanka", "ru": "Шри-Ланка", "uz": "Shri-Lanka"},
    "code": "LK",
    "dial_code": "+94"
  },
  {
    "name": {"en": "Sudan", "ru": "Судан", "uz": "Sudan"},
    "code": "SD",
    "dial_code": "+249"
  },
  {
    "name": {"en": "Suriname", "ru": "Суринам", "uz": "Surinam"},
    "code": "SR",
    "dial_code": "+597"
  },
  {
    "name": {
      "en": "Svalbard and Jan Mayen",
      "ru": "Шпицберген и Ян-Майен",
      "uz": "Shpitsbergen va Yan-Mayen"
    },
    "code": "SJ",
    "dial_code": "+47"
  },
  {
    "name": {"en": "Swaziland", "ru": "Эсватини", "uz": "Esvatini"},
    "code": "SZ",
    "dial_code": "+268"
  },
  {
    "name": {"en": "Sweden", "ru": "Швеция", "uz": "Shvetsiya"},
    "code": "SE",
    "dial_code": "+46"
  },
  {
    "name": {"en": "Switzerland", "ru": "Швейцария", "uz": "Shveytsariya"},
    "code": "CH",
    "dial_code": "+41"
  },
  {
    "name": {"en": "Syria", "ru": "Сирия", "uz": "Suriya"},
    "code": "SY",
    "dial_code": "+963"
  },
  {
    "name": {"en": "Taiwan", "ru": "Тайвань", "uz": "Tayvan"},
    "code": "TW",
    "dial_code": "+886"
  },
  {
    "name": {"en": "Tajikistan", "ru": "Таджикистан", "uz": "Tojikiston"},
    "code": "TJ",
    "dial_code": "+992"
  },
  {
    "name": {"en": "Tanzania", "ru": "Танзания", "uz": "Tanzaniya"},
    "code": "TZ",
    "dial_code": "+255"
  },
  {
    "name": {"en": "Thailand", "ru": "Таиланд", "uz": "Tailand"},
    "code": "TH",
    "dial_code": "+66"
  },
  {
    "name": {
      "en": "Timor-Leste",
      "ru": "Восточный Тимор",
      "uz": "Sharqiy Timor"
    },
    "code": "TL",
    "dial_code": "+670"
  },
  {
    "name": {"en": "Togo", "ru": "Того", "uz": "Togo"},
    "code": "TG",
    "dial_code": "+228"
  },
  {
    "name": {"en": "Tokelau", "ru": "Токелау", "uz": "Tokelau"},
    "code": "TK",
    "dial_code": "+690"
  },
  {
    "name": {"en": "Tonga", "ru": "Тонга", "uz": "Tonga"},
    "code": "TO",
    "dial_code": "+676"
  },
  {
    "name": {
      "en": "Trinidad and Tobago",
      "ru": "Тринидад и Тобаго",
      "uz": "Trinidad va Tobago"
    },
    "code": "TT",
    "dial_code": "+1868"
  },
  {
    "name": {"en": "Tunisia", "ru": "Тунис", "uz": "Tunis"},
    "code": "TN",
    "dial_code": "+216"
  },
  {
    "name": {"en": "Turkey", "ru": "Турция", "uz": "Turkiya"},
    "code": "TR",
    "dial_code": "+90"
  },
  {
    "name": {"en": "Turkmenistan", "ru": "Туркменистан", "uz": "Turkmaniston"},
    "code": "TM",
    "dial_code": "+993"
  },
  {
    "name": {
      "en": "Turks and Caicos Islands",
      "ru": "Острова Тёркс и Кайкос",
      "uz": "Turks va Kaykos orollari"
    },
    "code": "TC",
    "dial_code": "+1649"
  },
  {
    "name": {"en": "Tuvalu", "ru": "Тувалу", "uz": "Tuvalu"},
    "code": "TV",
    "dial_code": "+688"
  },
  {
    "name": {"en": "Uganda", "ru": "Уганда", "uz": "Uganda"},
    "code": "UG",
    "dial_code": "+256"
  },
  {
    "name": {"en": "Ukraine", "ru": "Украина", "uz": "Ukraina"},
    "code": "UA",
    "dial_code": "+380"
  },
  {
    "name": {
      "en": "United Arab Emirates",
      "ru": "Объединённые Арабские Эмираты",
      "uz": "Birlashgan Arab Amirliklari"
    },
    "code": "AE",
    "dial_code": "+971"
  },
  {
    "name": {
      "en": "United Kingdom",
      "ru": "Великобритания",
      "uz": "Buyuk Britaniya"
    },
    "code": "GB",
    "dial_code": "+44"
  },
  {
    "name": {
      "en": "United States",
      "ru": "Соединённые Штаты",
      "uz": "Qoʻshma Shtatlar"
    },
    "code": "US",
    "dial_code": "+1"
  },
  {
    "name": {"en": "Uruguay", "ru": "Уругвай", "uz": "Urugvay"},
    "code": "UY",
    "dial_code": "+598"
  },
  {
    "name": {"en": "Vanuatu", "ru": "Вануату", "uz": "Vanuatu"},
    "code": "VU",
    "dial_code": "+678"
  },
  {
    "name": {"en": "Venezuela", "ru": "Венесуэла", "uz": "Venesuela"},
    "code": "VE",
    "dial_code": "+58"
  },
  {
    "name": {"en": "Vietnam", "ru": "Вьетнам", "uz": "Vyetnam"},
    "code": "VN",
    "dial_code": "+84"
  },
  {
    "name": {
      "en": "British Virgin Islands",
      "ru": "Британские Виргинские острова",
      "uz": "Britaniya Virgin orollari"
    },
    "code": "VG",
    "dial_code": "+1284"
  },
  {
    "name": {
      "en": "United States Virgin Islands",
      "ru": "Виргинские острова США",
      "uz": "AQSh Virgin orollari"
    },
    "code": "VI",
    "dial_code": "+1340"
  },
  {
    "name": {
      "en": "Wallis and Futuna",
      "ru": "Уоллис и Футуна",
      "uz": "Uollis va Futuna"
    },
    "code": "WF",
    "dial_code": "+681"
  },
  {
    "name": {"en": "Yemen", "ru": "Йемен", "uz": "Yaman"},
    "code": "YE",
    "dial_code": "+967"
  },
  {
    "name": {"en": "Zambia", "ru": "Замбия", "uz": "Zambiya"},
    "code": "ZM",
    "dial_code": "+260"
  },
  {
    "name": {"en": "Zimbabwe", "ru": "Зимбабве", "uz": "Zimbabve"},
    "code": "ZW",
    "dial_code": "+263"
  },
];
