MySafar SDK — sotuvni oshirishi mumkin bo'lgan texnik ishlar
4-audit: qidiruv, bron, to'lov va ilova yadrosi bo'yicha

Sana: 24.09.2026. Joriy kod holati (commit qilinmagan o'zgarishlar bilan).
Holat: hammasi ❌ (hali qilinmagan).

Bu ro'yxat kod tahlili asosida tuzilgan, real sotuv ma'lumotlari asosida emas.
docs/sotuv_muammolari.md dagi №1–99 bu yerda takrorlanmaydi; raqamlash
davom ettirildi (№100–148).

Belgilar:
- [M] faqat mobil (SDK) · [B] faqat backend · [M+B] ikkalasi
- Ustuvorlik: (Y) yuqori · (O) o'rta · (P) past
- Hajm: S — kichik (1 kungacha) · M — o'rta · L — katta

Soni: 49 ta — qidiruv 11 · bron 13 · to'lov/buyurtmalar 11 · ilova yadrosi 14.


════════════════════════════════════════════════════════════════
ENG KATTA TA'SIR — BIRINCHI NAVBATDA
════════════════════════════════════════════════════════════════

№100 [M+B] (Y) S–M  To'lov muddati server muddatiga emas, qattiq 30 daqiqaga bog'langan.
   Server expire / expire_remain beradi (namunada ~5 kun, soat mintaqasi
   bilan), ilova esa createdAt + 1800 soniya hisoblaydi. Hali to'lash mumkin
   bo'lgan bron "muddati o'tdi" bo'lib, "To'lash" tugmasi yo'qoladi.
   Tuzatish: taymerni expire_remain / expire (offset bilan) dan olish;
   faqat ular yo'q bo'lsa 30 daqiqa. Backend: to'lov oynasini tasdiqlash.
   (payment_type.dart:41, formatters.dart:219, booking_confirm_page.dart:279,
   my_ticket_widget.dart:88; confirmed_ticket_models.dart:55)

№101 [M] (Y) S  WebView yopilishi bilan "To'lov amalga oshmadi" chiqadi — tekshiruv hali davom etayotganda.
   Birinchi javob "to'lanmagan" bo'lsa (bank xabari bir necha soniya
   kechikadi) to'lagan odamga ham shu xabar chiqadi — vahima, qo'ng'iroq,
   ikkinchi to'lov urinishi.
   Tuzatish: neytral "To'lov tekshirilmoqda — to'lagan bo'lsangiz, qayta
   to'lamang", xato matni faqat yakuniy "to'lanmagan" holatda.
   (booking_confirm_page.dart:581)

№102 [M+B] (Y) M  Bron yaratishda timeout / uzilish — natija noaniq, qayta urinish eski token bilan.
   Server bronni yaratgan bo'lishi mumkin, foydalanuvchi esa "5 daqiqadan
   keyin urinib ko'ring" ko'radi; qayta bossa takroriy bron yoki
   srv_ticket_awaiting_payment. Eng qimmat bosqichda xaridor yo'qoladi.
   Tuzatish: timeout / 5xx da 20–30 s davomida buyurtmani tid bo'yicha
   qidirish — topilsa to'lov sahifasini ochish; topilmasa reysni qayta
   tekshirib yangi tid bilan. Backend: idempotency kaliti yoki
   "tid bo'yicha bron".
   (booking_service.dart:51, booking_create_flow.dart:126,
   passenger_information_page.dart:489)

№103 [M] (Y) S–M  Bron xatosi oynasi boshi berk ko'cha.
   Yagona "Tushundim, yopish" tugmasi. Joy qolmagan / reys topilmadi
   xatolarida "Qayta qidirish" yo'q; pasport/familiya xatolari "yo'lovchilardan
   biri" deydi — qaysi biri va qaysi maydon ko'rsatilmaydi.
   Tuzatish: xatolarni ikkiga ajratish — joy/token → "Qayta qidirish" va
   qayta tekshirish; maydon xatosi → o'sha yo'lovchi formasini maydon
   belgilangan holda ochish (backend yo'lovchi indeksini qaytarsa yaxshi).
   (booking_create_flow.dart:129, response_state.dart:35, response_config.dart:106)

№104 [M] (Y) S–M  Reys faqat bir marta tekshiriladi — token forma to'ldirilguncha eskiradi.
   10–20 daqiqa forma to'ldirgan foydalanuvchi bron bosqichida server xatosini
   oladi (№103 dagi boshi berk oyna bilan).
   Tuzatish: oxirgi tekshiruv vaqtini saqlash; ~10 daqiqadan oshsa bron
   oldidan qayta tekshirish (narx o'zgarishi oqimi bilan); fondagi tekshiruv
   xato bersa yoki narx o'zgarsa darhol banner.
   (ticket_info_page.dart:241, passenger_information_page.dart:556)

№105 [M+B] (Y) S  Har manbadan faqat 30 ta reys so'raladi — mavjud reyslar yashirin qoladi.
   Barcha filtrlar faqat shu 30 ta ichida ishlaydi: "To'g'ri reys" yoki
   aviakompaniya filtri "reys yo'q" deydi, serverda esa bor. Saralash ham
   kesilgan ro'yxat ichida.
   Tuzatish: count ni oshirish (150–200) yoki filtr natijasi kam bo'lsa
   filtr bilan serverga qayta so'rov (SendFilterEvent hozir hech qayerdan
   chaqirilmaydi). Backend: yuk va limitni tasdiqlash.
   (recom_req_model.dart:231, ticket_page.dart:306)

№106 [M] (Y) S  Formadagi "To'g'ri reys" / "Bagaj bilan" natijalar sahifasida ko'rinmaydi va o'chirib bo'lmaydi.
   Foydalanuvchi "Bilet topilmadi" yoki qimmat natija sababini bilmaydi;
   arzon bagajsiz / ulanishli reyslar yashirin. So'nggi qidiruvlar bu
   filtrlarni jimgina qayta ishlatadi.
   Tuzatish: server filtrini natijalarda faol chip sifatida ko'rsatish,
   o'chirilsa qayta qidiruv; bo'sh holatda "Filtrni olib tashlash" tugmasi.
   (route_search_cubit.dart:512, _ticket_filters_sheet.dart:195,
   ticket_page.dart:641, recent_search_cache.dart:79)

№107 [M] (Y) S  Oylik narxlar doim bugundan 30 kun — uzoq sanalar uchun kalendar, grafik va lenta bo'sh.
   30 kundan uzoq safar rejalashtirayotganlar (ko'p pul to'laydigan segment)
   arzon sanalarni ko'rmaydi.
   Tuzatish: tanlangan sana / ko'rilayotgan oy atrofida date yuborish;
   grafik va kalendarda oy almashganda keyingi oynani yuklash.
   (avia_service.dart:191; ticket_page.dart:197, date_picker_cubit.dart:47,
   route_search_price_chart.dart:501)

№108 [M] (Y) M  To'langandan keyin chipta chiqishi kutilmaydi.
   Holat "to'langan" bo'lishi bilan tekshiruv to'xtaydi; PDF hali tayyor
   bo'lmasa faqat "Buyurtmalarga o'tish", u yerda esa "chiqarilmoqda" yozuvi
   o'zi yangilanmaydi. Qo'ng'iroq va qaytarish so'rovlari.
   Tuzatish: to'langandan keyin 3 daqiqagacha har 5–10 s ticket-data;
   tayyor bo'lsa tugma "Chiptani yuklab olish" ga almashadi. Buyurtmalarda
   "kutilmoqda" holati bor ekan — jim avto-yangilash.
   (booking_confirm_cubit.dart:223, booking_confirm_page.dart:727,
   my_ticket_widget.dart:766)

№109 [M] (Y) M  Host oldindan to'ldirilgan qidiruv, natijalar yoki "Buyurtmalar"ni ocha olmaydi.
   Faqat mysafar.uz/payment?billing_id qabul qilinadi. "Toshkent–Istanbul
   2.1 mln dan" banneri yoki "chiptangiz tayyor" push'i oddiy bosh sahifaga
   tushadi — har kampaniyada bir necha qadam yo'qoladi; qaysi kanal sotgani
   ham noma'lum.
   Tuzatish: MySafarEmbed(searchIntent:, initialTab:, entrySource:);
   /avia/search?from=&to=&date=&adt= va /orders/<id> deep-link'lari;
   entry_source har analitika hodisasida.
   (deep_link_gateway.dart:21, app.dart:433, router.dart:63, router.dart:102)

№110 [M] (Y, host AppMetrica ishlatsa) S  SDK AppMetrica'si host AppMetrica'si bilan to'qnashadi.
   SDK asosiy reporter sifatida activate qiladi va profil ID / app_version /
   lang ni o'rnatadi — host yoki SDK voronkasi va daromadi boshqasining
   hisobiga tushadi yoki ustidan yoziladi. Ikkala tomon raqamlariga ham
   ishonib bo'lmaydi.
   Tuzatish: AppMetrica.activateReporter(apiKey) va barcha chaqiruvlar
   getReporter(apiKey) orqali; asosiy reporter profiliga tegmaslik.
   (sdk.dart:212, appmetrica_analytics.dart, analytics_service.dart:188)

№111 [M+B] (Y) M  Masofaviy konfiguratsiya, feature flag va "o'chirish tugmasi" yo'q.
   remote_config_service hech narsani sinxronlamaydi — manbalar va
   bayroqlar amalda qattiq yozilgan. Tajriba (A/B) yoki ishlamay qolgan
   manbani o'chirish uchun Unired'ning yangi relizi kerak.
   Tuzatish: birinchi kadrdan keyin GET /sdk/config (partner bo'yicha),
   remote_config qutisida kesh; manbalar, bayroqlar, tajriba guruhi
   (analitikaga ham). README'dagi mavjud bo'lmagan enableFirestoreConfig
   ni olib tashlash.
   (remote_config_service.dart, tickets_cubit.dart:81, README.md:24)


════════════════════════════════════════════════════════════════
1. QIDIRUV VA NATIJALAR
════════════════════════════════════════════════════════════════

(№105, №106, №107 — yuqorida.)

№112 [M] (O) M  "Reys topilmadi" holatida aniq muqobil yo'q.
   "Boshqa sanalarda topdik" matni narx bor-yo'qligini tekshirmay chiqadi;
   borish-qaytish va ko'p segmentda sana lentasi umuman yo'q.
   Tuzatish: oylik narxlardan eng yaqin narxi bor sanani topib
   "12-okt · 1.9 mln — ko'rish" tugmasi; borish-qaytishda ±3 kun lentasi.
   (ticket_page.dart:789, ticket_page.dart:170)

№113 [M] (O) S  Bitta sekin manba yakuniy natijani 90 soniyagacha ushlab turadi.
   "Topilmadi" / xato faqat hamma manba tugagach; 5 daqiqalik taymer ham
   boshlanmaydi. "Kalit xatosi" juda keng aniqlanadi — ortiqcha qayta urinishlar.
   Tuzatish: qidiruvda manba uchun 25–30 s chegarasi; bir manba bo'sh,
   qolganlari kechiksa — bo'sh holatni erta ko'rsatish; qayta urinish faqat
   401 / aniq kod bo'yicha.
   (dio_client.dart:20, tickets_cubit.dart:131, tickets_cubit.dart:208)

№114 [M] (O) M  Natija kartasida qaror uchun kerakli ma'lumot yo'q.
   Qaytarish/almashtirish sharti, aeroport almashishi (SVO→DME), tungi yoki
   juda qisqa ulanish belgilanmaydi; narx yonida "N yo'lovchi uchun" yo'q.
   hasAirportChange kod null bo'lsa ham "almashadi" deydi.
   Tuzatish: kartaga "Qaytariladi", "Aeroport almashadi", "Tungi kutish",
   "<1 soat ulanish" belgilari va "2 yo'lovchi uchun" yozuvi.
   (_tickets_container_widgets.dart:719, flight_element_model.dart:253)

№115 [M] (O) S–M  Tafsilot oynasida tarif shartlari yuzaki.
   Qaytarish faqat ha/yo'q — bepul qaytarish va izohlar parse qilinadi, lekin
   ko'rsatilmaydi; yo'lovchi turi bo'yicha narx ko'rinmaydi; joy soni noma'lum
   (0) bo'lsa "Qolgan joylar: 0" — reys sotilib ketgandek.
   Tuzatish: "Bepul qaytarish" / jarima izohi; katta/bola/chaqaloq narxlari;
   0 ni yashirish, ≤3 bo'lsa "Oxirgi 3 ta joy".
   (ticket_info_price.dart:61, ticket_info_price.dart:84, element_segment_model.dart:208)

№116 [M] (O) S  Tekshiruvdan o'tmagan (sotilgan) reys ro'yxatda qoladi.
   Qayta bosilsa yana xato.
   Tuzatish: "Mavjud emas" deb belgilash yoki olib tashlash, keyingi eng
   arzon o'xshash reysni taklif qilish. (ticket_info_page.dart:209)

№117 [M] (P) S  "Ekonom" belgisi klassdan qat'i nazar birinchi 2 ta kartada.
   Biznes qidirgan foydalanuvchi "Ekonom" ko'radi.
   Tuzatish: belgini segment / so'rov klassidan olish yoki olib tashlash.
   (ticket_page.dart:1760, _tickets_container_widgets.dart:694)

№118 [M] (P) S  Vaqt va aviakompaniya filtrlari faqat borish va birinchi tashuvchiga qaraydi.
   Qaytish vaqtini filtrlab bo'lmaydi, ulanishli reyslarda aviakompaniya
   filtri noto'g'ri.
   Tuzatish: har yo'nalish uchun vaqt filtri, barcha segment tashuvchilari.
   (ticket_page.dart:321, _ticket_summary_widgets.dart:487)

№119 [M] (P) M–L  Reysni ulashish va narx kuzatuvi yo'q.
   Oilada birga qabul qilinadigan xaridlar yo'qoladi.
   Tuzatish: tafsilotda "Ulashish" (share_plus bor) — link №109 dagi
   deep-link bilan ochiladi; keyinroq yo'nalish bo'yicha narx kuzatuvi.
   (ticket_info_page.dart)


════════════════════════════════════════════════════════════════
2. YO'LOVCHI MA'LUMOTLARI VA BRON
════════════════════════════════════════════════════════════════

(№102, №103, №104 — yuqorida.)

№120 [M] (O) S  Narx oshishini rad etish yetim bron qoldiradi va qoralamani o'chiradi.
   Qoralama tozalash, profilga saqlash va kalendar hodisasi narx oshishi
   tasdig'idan OLDIN bajariladi. Rad etilsa: to'lanmagan bron
   "Buyurtmalarim"da qoladi, keyingi bosish eski tokenni yuboradi.
   Tuzatish: tozalash/saqlashni to'lov sahifasi ochilgach; rad etilganda
   (endpoint bo'lsa) bronni bekor qilish va yangi tekshiruv.
   (booking_create_flow.dart:110, passenger_information_page.dart:501)

№121 [M] (O) S  Yo'lovchi xatosi formani ochmaydi va maydonni belgilamaydi.
   Faqat snackbar va slotga scroll; forma ochilsa ham qizil maydon yo'q
   (18+ hamroh, yosh, pasport muddati xatolari).
   Tuzatish: xato bo'lsa o'sha yo'lovchi formasini xatolar bilan ochib,
   xato maydonga fokus. (passenger_information_page.dart:452,
   passenger_form_page.dart:122)

№122 [M] (O) S  Bir nechta yo'lovchi formasi ketma-ket ochilmaydi.
   Har "Davom etish"dan keyin ro'yxatga qaytib, keyingi slotni qo'lda bosish.
   Tuzatish: saqlangach keyingi to'ldirilmagan yo'lovchi ("2/3") avtomatik,
   hammasi tayyor bo'lsa email maydoniga fokus.
   (passenger_information_page.dart:226, :1024)

№123 [M] (O) M  Yosh toifasi mos kelmasa qayta qidiruv — kiritilgan hamma narsa yo'qoladi.
   Qoralama aynan tarkib bo'yicha saqlanadi (masalan uchish kuni 12 ga
   to'lgan bola). Xato matnida harakat yo'q.
   Tuzatish: qoralamani tug'ilgan kun va toifa bo'yicha moslab tiklash;
   xatoga "Toifani o'zgartirish" — sonlarni tug'ilgan kundan hisoblab
   qayta qidiruv. (passenger_draft_store.dart:25, passenger_cubit.dart:113)

№124 [M] (O) S–M  Oxirgi tugma oldida narx tarkibi va tarif shartlari yo'q.
   Alohida tasdiqlash sahifasi olib tashlangach (№22) qaror shu sahifada
   qabul qilinadi, lekin bagaj/qaytarish kartasi faqat to'lov sahifasida;
   narx tarkibi ("2 × katta, 1 × bola") hech qayerda.
   Tuzatish: yo'lovchi sahifasida ixcham reys xulosasi va ochiladigan narx
   tarkibi. (element_price_model.dart:48, passenger_information_page.dart:654)

№125 [M] (O) S  Kirill ism uchun faqat xato — transliteratsiya taklifi yo'q.
   Tuzatish: bir bosishda "XURSHID" kabi taklif chipi (o'zbek pasporti
   jadvali: Ш→SH, Ч→CH, Ю→YU, Я→YA, Ў→O, Ғ→G, Қ→Q, Ҳ→H; RU uchun KH),
   foydalanuvchi tasdiqlaydi. (passenger_rules.dart:106)

№126 [M+B] (O/P) M  Muddatsiz hujjatni kiritib bo'lmaydi.
   Amal qilish muddati majburiy, hujjat turi faqat A yoki P — bolaning
   tug'ilganlik guvohnomasi bilan MDHga uchadiganlar sana to'qib chiqaradi.
   Tuzatish: "Muddatsiz hujjat" belgisi va guvohnoma turi (backend bilan
   kelishib). (passenger_model.dart:183, passenger_card_widget.dart:234)

№127 [M] (P/O) S  Skaner o'qiy olmagan maydonlar ro'yxati tashlab yuboriladi.
   Skanerdan keyin xato ko'rsatilmaydi va birinchi bo'sh maydonga fokus yo'q.
   Tuzatish: to'liq natijani qaytarish, bo'sh maydonga fokus,
   "tekshiring: X o'qilmadi". (document_scan_service.dart:17, scan_page.dart:342)

№128 [M] (P/O) M  To'lov sahifasidan yo'lovchi ma'lumotini tuzatishga qaytib bo'lmaydi.
   Ism xatosi to'lovda sezilsa — qayta qidiruv va hammasini qayta yozish.
   Tuzatish: to'lov sahifasida ismlar va niqoblangan hujjat raqami;
   "Ma'lumotlarni tahrirlash" (yangi tekshiruv → yangi bron); qoralamani
   to'lov muvaffaqiyatigacha saqlash. (booking_confirm_page.dart:412,
   booking_create_flow.dart:112)

№129 [M+B] (P) M  Email majburiy.
   Host telefonni bergan UZ auditoriyasi uchun ortiqcha qadam.
   Tuzatish: telefon bo'lsa email ixtiyoriy, chipta SMS / "Buyurtmalarim"
   orqali (backend bilan kelishib). (passenger_cubit.dart:379, booking_service.dart:66)


════════════════════════════════════════════════════════════════
3. TO'LOV, CHIPTA VA TAKRORIY XARID
════════════════════════════════════════════════════════════════

(№100, №101, №108 — yuqorida. Hali ochiq: №1 — qaytish URL'i ushlanmaydi,
№18/№44 — buyurtmalar ro'yxati keshdan.)

№130 [M] (Y) M  Daromad analitikasi faqat foydalanuvchi to'lov sahifasida qolsa yoziladi.
   Tekshiruv paytida chiqib ketish, kechikkan webhook, deep-link orqali
   to'lov yoki tashqi ilovada to'lov — transaction_paid va daromad yo'qoladi.
   payment_started da summa va manba (yangi bron / buyurtmalar / deep-link /
   qayta bron) yo'q.
   Tuzatish: buyurtma birinchi marta "to'langan" ko'ringan joyda ham
   transaction_paid (billing_id bo'yicha bir marta); payment_started ga
   amount, currency, source. Idealda — server tomonda daromad.
   (booking_confirm_page.dart:675, ticketed_booking_search_page.dart:535)

№131 [M] (O) M  Host bron / to'lov hodisalarini olmaydi — tashlab ketilgan savatni qaytarish yo'q.
   Faqat auth, review va onCreateCardToken callback'lari. Unired "to'lashga
   15 daqiqa qoldi" yoki "chiptangiz tayyor" yubora olmaydi. Bosh sahifada
   to'lanmagan bron kartasi yo'q, buyurtmalarda kutilayotganlar tepada emas.
   README'dagi callbacks.getPushToken mavjud emas.
   Tuzatish: onBookingCreated(billingId, trId, amount, expiresAt),
   onPaymentResult, onTicketIssued; bosh sahifada "To'lovni yakunlang
   (mm:ss)" kartasi; kutilayotganlarni tepaga saralash; README'ni tuzatish.
   (callbacks.dart:3, deep_link_gateway.dart:21)

№132 [M] (O) S  Standart / eslab qolingan to'lov usuli yo'q.
   Bittadan ko'p usul bo'lsa har safar tanlash kerak, tanlamasdan "To'lash"
   xato beradi — takroriy xaridorlar uchun ham.
   Tuzatish: oxirgi muvaffaqiyatli usul (foydalanuvchi bo'yicha) yoki host
   UZS kartalari bo'lsa MYSAFARPAY oldindan tanlangan.
   (booking_confirm_page.dart:229)

№133 [M] (O) S  Saqlangan kartalar oynasi balansni ko'rsatadi, lekin buyurtma summasi bilan solishtirmaydi.
   Pul yetmaydigan karta tanlanadi va faqat SMS / bank bosqichida bilinadi
   (№29 ning mobil qismi).
   Tuzatish: summani oynaga uzatish, yetmaydigan kartalarni ogohlantirish /
   xiralashtirish, yetadiganlarni tepaga. (saved_cards_sheet.dart:245)

№134 [M] (O) S  SDK karta tokenini yarata olmasa ham saqlangan kartalar oynasi chiqadi.
   Callback yoki kalit berilmagan host'da har to'lovda ortiqcha oyna, xato
   toast va qo'lda karta kiritish.
   Tuzatish: oynani faqat token yaratish mumkin bo'lsa ko'rsatish;
   noto'g'ri sozlashni release'da ham loglash.
   (booking_confirm_page.dart:1445, :893; sdk.dart:104)

№135 [M] (O) M  Bankdan qaytish deep-link'i ochiq to'lov sahifasi ustiga bir martalik tekshiruv sahifasini ochadi.
   Webhook kechiksa buyurtma "Booked" va "To'lash" tugmasi bilan
   ko'rinadi — chalkashlik va ikki marta to'lash xavfi.
   Tuzatish: stekda shu billing_id li to'lov sahifasi bo'lsa unga qaytib
   tekshiruvni boshlash; aks holda to'lov sahifasidek kutish va "To'lash"ni
   yashirish. (deep_link_gateway.dart:27, ticketed_booking_search_cubit.dart:16)

№136 [M] (O/P) S–M  Chipta chiqqandan keyin takroriy xarid / qaytish reysi taklifi yo'q.
   Bir tomonga uchganlarga "Qaytish chiptasini oling", o'tgan safarlarga
   "Yana bron qilish" — eng qulay takroriy sotuv lahzalari ishlatilmaydi.
   Tuzatish: OrderRebook ni teskari yo'nalish, taklif sanasi va
   to'ldirilgan yo'lovchilar bilan qayta ishlatish.
   (order_rebook.dart:25, my_ticket_widget.dart:750, ticket_pdf_page.dart:75)

№137 [M] (P) S  Saqlangan chiptani internetsiz ochib bo'lmaydi.
   Aeroportda chipta ochilmaydi. Tuzatish: yuklash xato bersa diskdagi
   faylni ochish. (my_ticket_widget.dart:119, pdf_download_service.dart:30)

№138 [M] (P) S  Chiqarilgan chiptada qaytarish / almashtirish / yordam kirish nuqtasi yo'q.
   "Chek yuklab olish" tugmasi faqat izoh ko'rsatadi.
   Tuzatish: billing_id bilan "Buyurtma bo'yicha yordam" (host chat /
   Telegram); chek tugmasini ulash yoki yashirish.
   (my_ticket_widget.dart:750, ticket_pdf_page.dart:286)


════════════════════════════════════════════════════════════════
4. ILOVA YADROSI, TEZLIK VA INTEGRATSIYA
════════════════════════════════════════════════════════════════

(№109, №110, №111 — yuqorida.)

№139 [M] (O) M  Birinchi ochilishda 10 soniyagacha bo'sh spinner.
   Jim ro'yxatdan o'tish (webRegister + email) tugaguncha UI qurilmaydi,
   holbuki bosh sahifa login talab qilmaydi. Yangi foydalanuvchilar —
   eng qimmatli segment — birinchi tashrifda kutadi yoki chiqib ketadi.
   Tuzatish: darhol chizish, ro'yxatdan o'tishni fonda; faqat buyurtmalar,
   bron va profilda kutish. (app.dart:187, app.dart:361)

№140 [M] (O) S  Voronka hodisalarida SDK versiyasi, host/partner, to'g'ri til va vaqtlar yo'q.
   app_version — host versiyasi; lang saqlangan tildan (embed esa host tilini
   saqlamaydi); results_shown, booking_created, to'lov hodisalarida
   duration_ms yo'q; qadamlarni bog'laydigan search_id yo'q.
   Tuzatish: sdk_version, partner, entry_source, joriy til, search_id,
   davomiylik. (analytics_service.dart:63, analytics_service.dart:81, app.dart:199)

№141 [M] (O) S  Release'da xato / crash hisoboti yo'q.
   209 ta catch — asosan debugPrint, 18 tasi bo'sh; parse, WebView va
   to'lov xatolari ko'rinmaydi.
   Tuzatish: MySafarAnalytics.recordError(error, stack, context) (standart
   no-op) — qidiruv, bron, to'lov va WebView catch'larida. (app.dart:244)

№142 [M] (O/P) S  Bosh sahifa ~21 MB to'liq o'lchamli fon rasmlarini dekodlaydi.
   Barcha fonlar cacheWidth siz oldindan yuklanadi (2400×1600 — ~15 MB);
   past Android'da sekin birinchi kadr va host uchun xotira yetmasligi xavfi.
   Tuzatish: ~1080 px WebP, ResizeImage (ekran × dpr), faqat keyingisini
   oldindan yuklash. (home_background_carousel.dart:137)

№143 [M] (O) S  SDK assetlari 16 MB (506 fayl).
   airports_iata.json 6 MB (formatlangan; minify — 4 MB); 3 ta ustma-ust
   aeroport fayli; ishlatilmaydigan ~1.8 MB (main_bg.png, cloud.png,
   earth_day.jpg, main_plane.png); search_ticket_ic.png 1.1 MB, 52 px
   ko'rsatiladi. Host o'rnatish hajmi va yangilanish tezligiga ta'sir qiladi.

№144 [M] (P) S  Ishlatilmaydigan native plaginlar.
   audio_waveforms, syncfusion_flutter_calendar, latlong2,
   flutter_staggered_grid_view, expandable_page_view — hech qayerda import
   qilinmaydi; flutter_earth_globe faqat o'lik vidjetda; myid native SDK
   har host'ga bog'lanadi. Tuzatish: olib tashlash, MyID ni ixtiyoriy qilish.

№145 [M] (P) S  Pastki navigatsiyadagi blur doim yoqilgan.
   Har tabda (buyurtmalar ro'yxati ham) scroll paytida qimmat BackdropFilter
   (№35 faqat bosh sahifani tuzatgan).
   Tuzatish: yorug' rejim va Android'da blur o'rniga shaffof bo'lmagan fon.
   (bottom_nav_bar.dart:178, :271)

№146 [M] (P) S  Bosh sahifa yo'nalishlari keshlanmaydi va qayta ulanishda qayta urinmaydi.
   Tuzatish: PaymentTypeCache kabi kesh + fonda yangilash, qayta ulanishda
   qayta so'rov. (destination_list_cubit.dart:24)

№147 [M] (P) S  MySafarSdk.init barcha foydalanuvchilar uchun host ishga tushishini sekinlashtiradi.
   runApp'dan oldin AppMetrica, GetStorage, 5 ta Hive qutisi, til JSON,
   package_info ikki marta kutiladi — hatto avia ochmaydiganlar uchun ham.
   Tuzatish: init()da faqat sinxron konfiguratsiya, qolgani birinchi ochilishda
   (ensureReady), analitika kutilmasdan. (sdk.dart:191)

№148 [M] (P) S  Integratsiya xavflari.
   Google Maps kaliti bo'lmagan host'da yo'nalish xaritasi butun ilovani
   qulatishi mumkin (mapsEnabled bayrog'i va tashqi xarita zaxirasi kerak).
   Navbar tablarida Semantics(button, selected) yo'q.
   (destinations_info_map_page.dart:98, bottom_nav_bar.dart:364)


════════════════════════════════════════════════════════════════
NIMADAN BOSHLASH KERAK
════════════════════════════════════════════════════════════════

Tez natija beradigan kichik (S) ishlar — mobil, backend kutilmaydi:
1. To'lov tekshiruvi paytidagi xabar (№101).
2. Formadagi server filtrlarini natijalarda ko'rsatish (№106).
3. Oylik narxlarni tanlangan sana atrofida olish (№107).
4. Standart to'lov usuli va karta balansini summa bilan solishtirish (№132, №133, №134).
5. Internetsiz chipta ochish (№137), "Oxirgi N ta joy" / 0 joyni yashirish (№115 qismi).

Eng katta ta'sir (M, ba'zilari backend bilan):
1. To'lov muddatini server expire'dan olish (№100) — backend tasdig'i bilan.
2. Bron bosqichidagi xato va qayta urinish modeli (№102, №103, №104).
3. Har manbadan reyslar sonini oshirish (№105) — backend bilan.
4. To'langandan keyin chiptani kutish (№108) va daromad analitikasi (№130).
5. Host integratsiyasi: deep-link / qidiruv niyati, callback'lar, AppMetrica
   reporter, masofaviy konfiguratsiya (№109, №110, №111, №131).
6. Birinchi ochilishdagi spinner (№139).

Backend jamoasi bilan kelishish kerak: №100, №102, №105, №111, №126, №129
(va №103 da yo'lovchi indeksi).
