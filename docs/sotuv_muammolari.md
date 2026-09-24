MySafar SDK — bilet kam sotilishiga sabab bo'layotgan muammolar
Mobil (SDK) va backend bo'yicha ajratilgan ro'yxat

Sana: 24.09.2026. Tuzatishlar: commitlar 847bce6, e068992, 3b07721 va 1-bo'lim
bo'yicha keyingi tuzatishlar (branch rustam). "→" bilan boshlangan qator —
nima qilingani.
Holat: ✅ tuzatildi · 🟡 qisman tuzatildi · ❌ tuzatilmagan

Bu ro'yxat kod tahlili asosida tuzilgan, real sotuv ma'lumotlari asosida emas.
Raqamlar (№1–56) oldingi ro'yxatdagi raqamlar bilan bir xil — eski hujjatga
havola qilish uchun saqlab qolindi.

Taqsimot:
- 1-bo'lim — MOBIL: faqat SDK (Flutter) kodida hal bo'ladi, backend o'zgarishi shart emas.
- 2-bo'lim — BACKEND: API, server xabarlari yoki kontent tomonida hal bo'ladi.
- 3-bo'lim — IKKALASI: ikki tomon kelishuvi kerak, har biri uchun ulush yozilgan.
- 4-bo'lim — allaqachon tuzatilganlar (hammasi mobil tomonda).
- 5-bo'lim — 3-auditda yangi topilganlar (№57–99): mobil bandlar tuzatildi,
  [M+B] bandlar 3-bo'limga ko'chirildi.

Soni: mobil 30 ta · backend 10 ta · ikkalasi 6 ta · tuzatilgan 15 ta ·
yangi 43 ta (mobil 35 — tuzatildi · backend 1 · ikkalasi 7 — 3-bo'limda,
mobil qismi tuzatildi).


════════════════════════════════════════════════════════════════
1. MOBIL (SDK) TOMONDA HAL BO'LADI
════════════════════════════════════════════════════════════════

1.1. Pulni yo'qotadigan va ishonchni buzadiganlar

№9 ✅ Natijalar 5 daqiqada majburan eskiradi.
   Chiqqan oynani yopib bo'lmaydi, qayta qidirishdan boshqa tugma yo'q.
   → Oyna yopiladi; yopilgach ro'yxat ustida "Qayta qidirish" banneri qoladi. Bron oldidan reys baribir qayta tekshiriladi.

№12 ✅ Orqaga qaytilganda kiritilgan yo'lovchi ma'lumotlari yo'qoladi.
   Qoralama saqlanmaydi.
   → Qoralama xotirada saqlanadi (diskka emas); bron yaratilgach o'chiriladi.

№13 ✅ Chaqaloqlar soni kattalardan ko'p bo'lishi mumkin.
   Buning xatosi faqat bron qadamida chiqadi — yo'lovchi tanlash oynasida to'siladi.
   → Chaqaloqlar soni kattalardan oshmaydi, kattalar kamaysa chaqaloqlar ham kamayadi.

№14 ✅ Kontakt maydonlari.
   Email formati tekshirilmaydi. Telefonda +998 avtomatik qo'yilmaydi.
   "Telefon yo'lovchiga tegishli bo'lishi shart" degan yozuv boshqa odam uchun
   bilet olayotganlarni cho'chitadi.
   → Email formati tekshiriladi, bo'sh telefonga +998 qo'yiladi, ogohlantirish matni yumshatildi.

№20 ✅ Mayda muammolar.
   Qattiq yozilgan o'zbekcha matnlar bor; ticket_url_not_found kaliti tarjima
   fayllarida yo'q. "Oferta" havolasi maxfiylik siyosati sahifasini ochadi.
   Yangi manba kelganda ro'yxat tepaga sakraydi. Bir reys ikki marta chiqishi
   mumkin. Ishlatilmaydigan ~6 MB asset bor.
   → ticket_url_not_found kaliti, Oferta havolasi (/oferta), qattiq matnlar kalitga, ro'yxat sakramaydi ("Yangi reyslar" tugmasi), bir xil reyslar birlashtiriladi. Ishlatilmaydigan 105 ta asset (~4.4 MB) o'chirildi.

№30 ✅ Chiptani saqlash va ulashish qiyin.
   PDF ilovaning yopiq papkasiga saqlanadi, "ulashish" tugmasi yo'q. Telefonda
   PDF ko'ruvchi bo'lmasa hech narsa ochilmaydi va xato ham chiqmaydi.
   → PDF ulashsa bo'ladigan papkaga saqlanadi; "Ulashish" tugmasi (tizim oynasi, share_plus) chipta sahifasida va "Buyurtmalarim"da; ko'ruvchi bo'lmasa xato va "Brauzerda ochish".

№48 ✅ Internet yo'qligida.
   To'lov sahifasi yuklanmasa, telefonning o'z "sahifa mavjud emas" ekrani
   chiqadi, "Qayta yuklash" tugmasi yo'q. Ilovada internet yo'qligi haqida
   xabar hech qayerda yo'q.
   → To'lov sahifasida o'z xato ekrani va "Qayta yuklash"; butun SDK'da "Internet yo'q" xabari.

№49 ✅ Har ochilishda joylashuv so'raladi.
   Foydalanuvchi hech narsa qilmasdan ruxsat oynasi chiqadi, rad etilsa
   keyingi ochilishda yana so'raladi.
   → Ochilishda ruxsat so'ralmaydi — faqat "Joriy joylashuv" bosilganda.

№50 ✅ "Buyurtmalarim"dan tizimga kirgach bosh sahifaga otib yuboriladi.
   Buyurtmalar sahifasiga qaytarilmaydi.
   → Kirgach "Buyurtmalarim" bo'limiga qaytariladi.


1.2. Bilet olish qulayligi (konversiyaga eng ko'p ta'sir qiladi)

№22 ✅ Reysni tanlashdan to'lovgacha qadamlar juda ko'p.
   Bitta kattalar uchun eng qisqa yo'l ~21 bosish, 9 ta ekran va 9 ta oyna.
   Har bir yo'lovchi alohida sahifada to'ldiriladi, 1 yo'lovchi bo'lsa ham
   forma o'zi ochilmaydi. Keyin alohida "Ma'lumotlarni tasdiqlash" sahifasi
   keladi, u faqat kiritilganlarni takrorlaydi va tugmasi oldingi sahifadagi
   bilan bir xil nomlangan.
   → Alohida "Ma'lumotlarni tasdiqlash" sahifasi olib tashlandi: yo'lovchi sahifasidagi "Tasdiqlash va bron qilish" bronni darhol yaratadi va to'lovga o'tkazadi (narx, oferta matni tugma yonida). 1 yo'lovchida forma o'zi ochiladi.

№23 ✅ Tasdiqlash va to'lov sahifasida nima uchun to'lanayotgani ko'rinmaydi.
   Yo'nalish, sana, bagaj va qaytarish shartlari yo'q, faqat to'lov usullari
   va buyurtma ID'si bor. Ma'lumotlarning hammasi ilovada bor.
   → Reys xulosasi (yo'nalish, sana, bagaj, qaytarish/almashtirish shartlari) to'lov sahifasida chiqadi — "Buyurtmalarim"dan ochilganda ham (buyurtma ma'lumotidan).

№24 ✅ Qidiruvda ortiqcha bosishlar.
   Sana tanlangach, yo'lovchilar oynasi o'zi ochiladi, birinchi marta valyuta
   oynasi ham chiqadi, keyin yana "Qidirish" bosish kerak. Oraliqda qat'iy
   ~1 soniya kutishlar bor. Bosh sahifada tanlangan yo'nalish orqaga
   qaytilganda unutiladi.
   → Sanadan keyin kalendar o'zi ochiladi, uning tugmasi "Bilet izlash" — sana tanlanishi bilan qidiruv boshlanadi; yo'lovchi/klass kalendar ichida o'zgartiriladi. Qat'iy kutishlar olib tashlandi, yo'nalish esda qoladi.

№25 ✅ Bosh sahifadagi "almashtirish" tugmasi boshi berk ko'chaga olib boradi.
   "Qayerga" saqlanmagani uchun almashtirish "Qayerdan"ni bo'shatadi. Undan
   keyin shahar tanlash hech narsa qilmaydi yoki qidiruv to'xtab qoladi.
   Toshkentga qaytayotganlar aynan shu tugmani ishlatadi.
   → "Qayerga" saqlanadi, almashtirish ikkala tomonni to'g'ri almashtiradi.

№26 ✅ Saqlangan yo'lovchilarga yetish qiyin.
   4 bosish kerak bo'ladi, ro'yxat yosh toifasi bo'yicha filtrlanmaydi,
   boshqa slotda allaqachon tanlanganlar ham ko'rinadi.
   → Saqlangan yo'lovchilar formada chip ko'rinishida, yosh toifasi bo'yicha filtrlanadi, boshqa slotdagilar yashiriladi.

№27 ✅ Forma standart qiymatlari.
   Fuqarolik bo'sh turadi va yozish o'rtasida davlat tanlagichi ochilib
   ketadi. Jins jimgina "Erkak" qilib tanlangan, bu noto'g'ri chiptaga olib
   kelishi mumkin. Bola va chaqaloq uchun tug'ilgan kun tanlagichi 1990-yildan
   boshlanadi.
   → Fuqarolik UZ (yoki host qiymati), tanlagich o'zi ochilmaydi, jins majburiy tanlanadi, tug'ilgan kun toifaga mos yildan boshlanadi.

№28 ✅ Klaviatura.
   Hech bir maydonda avtoto'ldirish (autofill) yo'q. Sana maydonlarida iOS'da
   "Keyingi" tugmasi yo'q. Yo'lovchi formasidagi "Davom etish" tugmasi
   klaviatura ostida qolib ketadi.
   → Autofill, iOS'da "Keyingi", "Davom etish" klaviatura ustida.

№31 ✅ Takroriy qidiruv noldan boshlanadi.
   Sanasi o'tgan so'nggi qidiruvlar butunlay yashiriladi. Yo'lovchilar soni va
   klass oldingi qidiruvdan olinmaydi.
   → Eski sanali qidiruvlar "Sanani tanlang" bilan ko'rsatiladi, yo'lovchilar va klass oxirgi qidiruvdan olinadi.

№32 ✅ Katta shrift va kichik tugmalar.
   Maydonlar balandligi qat'iy, katta tizim shriftida matn sig'maydi. Ba'zi
   tugmalar 34–36 dp (tavsiya ≥44 dp). Ba'zi yorliqlar 10.5 px va xira rangda.
   Ikonka tugmalarida ekran o'quvchi uchun nom yo'q.
   → Maydon va tugmalar katta shriftda o'sadi, barcha kichik tugmalar (filtr/vaqt chiplari, orqaga, o'chirish, yopish) ≥44 dp bosiladi, 10.5 px yorliqlar 12 px, ikonka tugmalarga ekran o'quvchi nomi qo'shildi.


1.3. Tezlik va silliqlik

№33 ✅ Qidiruv natijalari UI oqimida nusxalanadi.
   Har bir manba javobi fon isolate'ga uzatilishidan oldin to'liq nusxalanadi
   (compute bilan Map). Reyslar chiqayotgan paytda past qurilmalarda ekran
   qotib qoladi.
   → Javob bayt ko'rinishida olinib, JSON o'qish va model fon isolate'da.

№34 ✅ Natijalar sahifasi har yangilanishda barcha reyslarni qayta saralaydi
   va guruhlaydi. Taqqoslashda narx matni har safar qayta o'qiladi. Bitta
   qidiruvda bu ~5 marta, har biri o'nlab millisekund.
   → Saralash/guruhlash keshlanadi, narx bir marta o'qiladi.

№35 ✅ Bosh sahifada animatsiyali fon ustida bir nechta blur effekti turadi.
   Past Android qurilmalarda sekinlashtiradi, yorug' rejimda esa blur umuman
   ko'rinmaydi. Fon rasmlarini oldindan yuklash ishlamaydi. Fon taymeri bosh
   sahifa yashiringanda ham ishlayveradi.
   → Blur faqat qorong'i rejimda, fon rasmlari oldindan yuklanadi, taymer sahifa yashiringanda to'xtaydi.

№36 ✅ "Bron qilish" tugmasi reys qayta tekshirilguncha o'chiq turadi.
   Uni fonda tekshirib, yo'lovchi formasini darhol ochish mumkin.
   → "Bron qilish" tekshiruvni kutmaydi — yo'lovchi formasi darhol ochiladi, tekshiruv fonda davom etadi va bron oldidan kutiladi. Narx o'zgarsa tasdiqlash so'raladi, xato bo'lsa "Qayta urinish" / "Qayta qidirish".

№38 ✅ To'lov usullari keshlanmaydi.
   Har bir to'lov sahifasida serverdan kutiladi va shu vaqtda "To'lash"
   tugmasi o'chiq turadi.
   → To'lov usullari keshlanadi (10 daqiqa), darhol ko'rsatiladi va fonda yangilanadi.

№39 ✅ Oylik narxlar 2–3 marta so'raladi.
   Klass parametri turli joylarda har xil yuboriladi, keshning esa muddati va
   chegarasi yo'q.
   → Klass bir xil yuboriladi; keshda muddat (15 daqiqa), chegara (40) va bir vaqtdagi so'rovlarni birlashtirish bor.

№40 ✅ Narx grafigini aylantirish og'ir.
   Har bir kun o'tganda 365 kunlik ro'yxat qayta quriladi.
   → 365 kunlik ro'yxat keshlanadi.

№41 ✅ Yo'lovchilarni profilga saqlash to'lov sahifasi yuklanishi bilan bir
   vaqtda ketadi va uni sekinlashtiradi.
   → Profilga saqlash bron muvaffaqiyatidan 3 soniya keyin fonda ketadi.

№42 ✅ Yo'lovchilar sahifasi har bir tugma bosilishida to'liq qayta quriladi.
   Email va telefon maydonlarida sezilarli.
   → Email/telefon yozilganda sahifa qayta qurilmaydi.

№43 ✅ Yo'nalish rasmlari to'liq o'lchamda dekodlanadi.
   Kichik kartalarda ham — xotirani ko'p egallaydi.
   → Barcha tarmoq rasmlari (yo'nalish kartalari, karusel, "issiq chipta", aviakompaniya logolari) ekran o'lchamiga mos dekodlanadi.


1.4. O'lchov va qamrab olinmagan oqimlar

№19 ✅ Analitika teshik.
   Tuzatildi: to'lov muvaffaqiyati, daromad va to'lov xatolari yuboriladi.
   Qolgan: asosiy qidiruv yo'lida ticket_searched yo'q; "natijalar chiqdi" /
   "natija yo'q", booking_failed hodisalari va ekran nomlari yo'q.
   → Hodisalar: ticket_searched, results_shown / no_results, flight_selected, passenger_form_started / completed, booking_created / booking_failed, payment_started, to'lov natijasi; har bir sahifa uchun screen_view (nomlangan route'lar). Ro'yxat README'da.

№37 ✅ Bron oldidan keraksiz token tekshiruvi.
   Bron partner token bilan ketsa ham, avval qo'shimcha so'rov yuboriladi. U
   yopib bo'lmaydigan yuklanish oynasi ichida vaqt oladi.
   (Bu so'rov umuman kerakmi — backend bilan tasdiqlash kerak, lekin olib
   tashlash mobil tomonda.)
   → Partner token bilan ketadigan bron/to'lov so'rovlaridan oldingi tekshiruv olib tashlandi (backend tasdiqlashi tavsiya etiladi).


════════════════════════════════════════════════════════════════
2. BACKEND TOMONDA HAL BO'LADI
════════════════════════════════════════════════════════════════

№5 🟡 Valyuta: USD tanlagan foydalanuvchi uchun bron avvalgidek RUBda
   yaratiladi, bu haqda oldindan aytilmaydi.
   Backend: bronni tanlangan valyutada yaratish yoki qaysi valyutalar
   qo'llab-quvvatlanishini aniq qaytarish.

№6 🟡 Hujjat turi (P/A) fuqarolikka qarab belgilanadi.
   Backend: qoidani tasdiqlash — qaysi fuqarolik uchun qaysi doctype
   yuborilishi kerakligini hujjatlashtirish.

№8 🟡 Server xato matnlari yordam bermaydi.
   Server xatolarida hali ham "5 daqiqadan keyin urinib ko'ring" chiqadi.
   Backend: xatolarga barqaror kod va foydalanuvchiga tushunarli matn
   (yoki ilova tarjima qila oladigan kod) berish.

№16 🟡 Bron vaqti soat mintaqasiz keladi.
   Server created_at ni Toshkent vaqtida, mintaqasiz yuboradi; ilova uni
   telefon vaqti deb o'qiydi. UTC+6 va sharqroqdagi telefonlarda bron darhol
   "muddati o'tgan" bo'ladi, Moskva va Turkiyada taymer ~2.5 soat uzun.
   Backend: sanalarni ISO-8601 formatida offset bilan (yoki UTC) berish va
   expire maydonini to'ldirish.

№18 ❌ "To'landi, bilet chiqarilmoqda" holati yo'q.
   Backend: to'langan, lekin hali chiqarilmagan buyurtma uchun alohida holat
   qaytarish (hozir ilova uni ko'rsata olmaydi).

№29 ❌ Kartada pul yetmasligi faqat SMS kod bosqichida ma'lum bo'ladi.
   Backend / to'lov provayderi: summani oldindan tekshirish yoki aniq xato
   kodi qaytarish.

№45 🟡 "AwaitPayment" holatidagi buyurtmani to'lashning yo'li yo'q.
   Backend: mavjud buyurtma uchun to'lov havolasini qayta berish
   (yoki qayta to'lash metodi).
   → Mobil: to'lov vaqti o'tgan (yoki to'lanmay bekor qilingan), lekin
   parvozi hali oldinda buyurtmada "Qayta bron qilish" tugmasi — o'sha
   yo'nalish, sana, klass va yo'lovchilar soni bo'yicha qidiruv ochiladi,
   yo'lovchilar formasi buyurtmadagi ma'lumotlar bilan to'ldiriladi
   (order_rebook.dart). "To'lovga o'tish" tugmasi va taymer to'lov
   sahifasidagi uslubga keltirildi. Backend qismi (eski bronni qayta to'lash)
   hali ochiq.

№46 ❌ Yo'nalish kartalarida marshrut kodlari yo'q.
   Kontent/CMS: kartalarda IATA kodlari to'ldirilishi kerak — hozir kod
   bo'lmagani uchun tugma jim turadi yoki doim Toshkentdan qidiradi.

№47 ❌ Yo'nalishlar qidiruvi uchun server endpointi yo'q.
   Hozir faqat ilovaga yuklangan sahifalar ichida qidiriladi, shuning uchun
   mavjud yo'nalish "topilmadi" bo'lib chiqishi mumkin.
   Backend: yo'nalishlar bo'yicha qidiruv (server-side search) berish.

№51 ❌ Aqlli qidiruv javobi kontrakti.
   Javobda kerakli maydon bo'lmasa, yuklanish oynasi yopilmaydi.
   Backend: maydonni doim qaytarish yoki xato kodi berish.
   (Ilova tomonida ham himoya qo'yiladi — 3-bo'limga qarang.)


════════════════════════════════════════════════════════════════
3. IKKALASI BIRGA (kelishuv kerak)
════════════════════════════════════════════════════════════════

№1 🟡 To'lovdan keyin sahifa o'zi yopilmaydi.
   Bank to'lovdan keyin mysafar.uz/payment?billing_id=... manziliga
   qaytaradi, lekin to'lov sahifasi shu manzilni ko'rib avtomatik yopilmaydi.
   Mobil: qaytish manzilini ushlab, sahifani o'zi yopish va holatni tekshirish.
   Backend: qaytish manzili formatini (success/fail/cancel) qat'iy
   belgilash va o'zgartirmaslik.

№11 ❌ Reysni qayta tekshirish xato bersa, davom etib bo'lmaydi.
   Mobil: qisqa uzilishda "Qayta urinish" berish, tarif tanlanganda bron
   tokenini saqlash, kechikkan javobni e'tiborsiz qoldirish.
   Backend: qayta tekshirish (GDS) so'roviga barqaror javob va timeout.

№15 ❌ To'lov usullari.
   Mobil: "Rossiya kartalari" (PAYGINE) QR sahifasini o'sha telefonda
   ochmaslik, hostdagi saqlangan xorijiy kartalarni taklif qilish.
   Backend: to'lov usullari ro'yxatini valyuta bo'yicha filtrlab berish.

№17 ❌ Sessiya.
   Mobil: yashirin ro'yxatdan o'tish buzilsa qayta tiklash (hozir saqlangan
   yo'lovchilar va email yo'qoladi), birinchi ochilishdagi 10 soniyalik
   spinnerni qisqartirish.
   Backend: partner token xatosini aniq kod bilan qaytarish — hozir u
   "Internet yo'q" bo'lib ko'rinadi.

№21 ❌ Birinchi yo'lovchi xaridor ma'lumotlari bilan to'ldirilmaydi.
   Ko'pincha xaridorning o'zi 1-yo'lovchi, lekin ism va tug'ilgan kunni har
   safar qo'lda yozadi.
   Mobil (SDK): MySafarUserData ga ism, tug'ilgan kun va pasport maydonlarini
   qo'shish va formani shu ma'lumot bilan to'ldirish.
   Host ilova: shu maydonlarni uzatish (hozir faqat email va telefon keladi).

№18/№44 ❌ "Buyurtmalarim" va keyin to'lash.
   Mobil: ro'yxatni serverdan yangilash (hozir kesh bo'lsa faqat o'sha
   ko'rsatiladi), keyin to'lashda narxni tanlangan valyutada ko'rsatish,
   to'lov oynasi va bo'sh ro'yxatdagi qulashlarni (response!.data!) tuzatish.
   Backend: buyurtma holatlari va chipta chiqarilishi haqida aniq status
   (№18 ga qarang).


№64 🟡 (O) Saqlangan karta bilan to'lovda imzolangan to'lov URL'i buziladi.
   card_token qo'shish uchun Uri.replace butun query'ni qayta kodlaydi —
   WebViewCompat aynan shundan himoya qilish uchun bor, bu yo'l uni chetlab
   o'tadi. HUMO/Uzcard saqlangan karta to'lovida "imzo noto'g'ri" xatosi
   bo'lishi mumkin. Backend/shlyuz: imzo qanday tekshirilishini tasdiqlash.
   (booking_confirm_page.dart)
   → Mobil ✅: card_token xom URL oxiriga qo'shiladi, qolgan imzolangan parametrlar qayta kodlanmaydi.
   → Backend ❌: to'lov shlyuzi imzoni qanday tekshirishini tasdiqlash.

№69 🟡 (O) Hujjat raqami tekshirilmaydi va normallashtirilmaydi.
   Faqat bo'sh joy taqiqlangan. Rus klaviaturasida kirill "АА1234567"
   lotin "AA"dan farq qilmaydi va shunday yuboriladi; kichik harf, "№", "-",
   "/" ham o'tadi. Xato faqat serverdan butun oqimdan keyin keladi.
   Mobil: katta harf, faqat A–Z0–9, kirill uchun aniq xabar. Backend: qabul
   qilinadigan formatlarni aytish.
   → Mobil ✅: Katta harf, o'xshash kirill harflari lotinga, "№", "-", "/" olib tashlanadi, noto'g'ri harfda aniq xabar; haqiqiy kirill seriyali guvohnomalar o'zgartirilmaydi.
   → Backend ❌: qabul qilinadigan hujjat formatlarini aytish.

№71 🟡 (O) Bola/chaqaloq bilan 18+ hamroh borligi tekshirilmaydi.
   "Katta" = 12+. 15 yoshli aka 1 yoshli bola bilan barcha tekshiruvdan o'tadi,
   keyin server srv_adult_required_for_child qaytaradi. accompanying_adult
   doim [] yuboriladi — backend bilan tasdiqlash kerak.
   (passenger_rules.dart, booking_service.dart)
   → Mobil ✅: Bola/chaqaloq bo'lsa kamida bitta 18+ katta borligi bron oldidan tekshiriladi.
   → Backend ❌: accompanying_adult maydoni formatini tasdiqlash (hozir [] yuboriladi).

№72 🟡 (O) Pasport muddati uchun 6 oylik qoida/ogohlantirish yo'q.
   Faqat oxirgi reys sanasigacha tekshiriladi. Qaytgandan 2 oy keyin tugaydigan
   pasport Turkiya/BAA/Misrga qabul qilinadi va to'lanadi — keyin ro'yxatdan
   o'tishda rad. Mobil: 6 oydan kam bo'lsa yumshoq ogohlantirish. Backend:
   yo'nalish bo'yicha qoida berish.
   → Mobil ✅: Pasport qaytgandan keyin 6 oydan kam amal qilsa yumshoq ogohlantirish (davom etish mumkin).
   → Backend ❌: yo'nalish bo'yicha qoida berish.

№77 🟡 (Y) Bitta buzuq maydon butun manba reyslarini yo'qotadi.
   duration/segments_count/direction/route_duration ga "" (String) int?
   o'rniga qo'yiladi; Baggage/RefundBlock/Provider va inclusion_carriers,
   predefined_airlines null bo'lsa fromJson/map qulaydi. Bitta reysda maydon
   yo'q bo'lsa o'sha manbaning hamma reyslari error_other bo'lib yo'qoladi;
   boshqa manba bo'sh bo'lsa — noto'g'ri "Bilet topilmadi". Qayta tekshiruvda
   inglizcha "Failed to parse flight info" chiqib bron to'siladi.
   Mobil: reys bo'yicha xavfsiz parse. Backend: format barqarorligi.
   (flight_element_model.dart, element_segment_model.dart, get_recom_res_model.dart)
   → Mobil ✅: Reyslar bittalab xavfsiz o'qiladi — buzuq reys tashlanadi, qolganlari ko'rinadi; qayta tekshiruv xatosi tarjima qilingan.
   → Backend ❌: javob formatini barqaror qilish.

№78 🟡 (O) AI/ovozli qidiruv sanasiz yoki ISO sana qaytarsa natijalar sahifasi qulaydi.
   date = "" → _parseDate FormatException build ichida; "2026-09-30" esa
   DateTime(30, 9, 2026) bo'ladi. Ko'p segmentli AI qidiruv doim "borib-kelish"
   deb ko'rsatiladi. Backend: doim dd.MM.yyyy yoki sanasiz bo'lsa body yo'q.
   (recom_req_model.dart)
   → Mobil ✅: Bo'sh / ISO sana qulatmaydi ("sana yo'q" xabari), ko'p segmentli qidiruv faqat haqiqiy qaytishda "borib-kelish".
   → Backend ❌: doim dd.MM.yyyy yoki sanasiz bo'lsa body yo'q.

№82 🟡 (O) Faqat USD/RUB narxli reys "Eng arzon" bo'lib chiqishi mumkin.
   UZS bloki bo'lmasa narx "0" → saralashda xom USD/RUB soni UZS bilan
   solishtiriladi: "250" "3 000 000 UZS" dan oldin va "Eng arzon" belgisi
   bilan. Backend: doim UZS summa. Mobil: konvertatsiya yoki oxiriga qo'yish.
   (element_price_model.dart, flight_element_model.dart computeSortPrice)
   → Mobil ✅: USD/RUB narxli reyslar UZS reyslardan keyin, "Eng arzon" belgisi faqat UZS narxli reysga.
   → Backend ❌: doim UZS summa qaytarish.

════════════════════════════════════════════════════════════════
4. ALLAQACHON TUZATILGAN (hammasi mobil tomonda)
════════════════════════════════════════════════════════════════

№1 ✅ To'lov natijasi endi aniqlanadi — sahifa yopilgach buyurtma holati
   60 soniyagacha tekshiriladi (qolgani 3-bo'limda).
№2 ✅ Android "orqaga" tugmasi to'lov himoyasini chetlab o'tmaydi.
№3 ✅ Qayta qidiruvda reyslar yo'qolmaydi — filtrga faqat foydalanuvchi
   tanlagan aviakompaniyalar yuboriladi.
№4 ✅ Noto'g'ri "reys topilmadi" yo'q — xato bo'lsa "Qayta urinish" chiqadi.
№5 ✅ Narx noto'g'ri ko'rsatilishi (— UZS, "0 USD", eski narx) tuzatildi.
№6 ✅ Yo'lovchi ma'lumoti to'liq tekshiriladi (sana, pasport muddati, yosh,
   kirill harflar, urg'uli lotin harflar).
№7 ✅ Bron va to'lov so'rovlari qayta yuborilmaydi; kutish 60 → 20 soniya.
№8 🟡 Bron va to'lov xatolari foydalanuvchi tilida chiqadi (qolgani 2-bo'limda).
№10 ✅ "Reys topilmadi" ekranida "Qayta qidirish" va "Qidiruvni o'zgartirish".
№16 🟡 To'lagan foydalanuvchi "vaqt tugadi" deb chiqarib yuborilmaydi
   (qolgani 2-bo'limda).
№52 🟡 Host tili server so'rovlariga o'tadi (qidiruv va tarif so'rovlari
   bundan mustasno — №81 ga qarang).
№53 ✅ Qayta tekshirish so'roviga til uz/ru/en ga moslab yuboriladi.
№54 ✅ Davlat bayroqlari kichik o'lchamda dekodlanadi (~60 MB tejaldi).
№55 ✅ Ismlar buzilmaydi (İBRAHİM, ÇAĞLAR, ХУРШИД holatlari).
№56 ✅ To'lov holati tekshiruvidagi xatolar (Booked/Cancelled, sekin tarmoq,
   "Kutilmoqda"da qayta to'lash, e-chipta) tuzatildi.
✅ Pasport skaneri: avtofokus, 4K, ramkadan kesish — matn ~2 barobar tiniqroq.


════════════════════════════════════════════════════════════════
5. YANGI TOPILGANLAR (3-audit, 24.09.2026)
════════════════════════════════════════════════════════════════

Ilova qidiruv, bron, to'lov/buyurtmalar, SDK yadrosi va commit qilinmagan
o'zgarishlar bo'yicha qayta tahlil qilindi. Quyidagilar №1–56 da yo'q.
[M] bandlar tuzatildi (✅, "→" — nima qilingani). [M+B] bandlar 3-bo'limga
ko'chirildi (mobil qismi bajarilgan). Belgi: [M] mobil · [B] backend.
Og'irlik: (Y) yuqori · (O) o'rta · (P) past.

5.1. Pulni yo'qotadigan va ishonchni buzadiganlar

№57 ✅ [M] (Y) To'lov oynasi ikki marta ochilishi mumkin — ikki marta to'lov xavfi.
   Tasdiqlash sahifasi ochilganda chipta ma'lumoti so'raladi. Uning javobi
   "To'lovga o'tish" bosilgandan keyin kelsa, yuklanish holati almashadi,
   tugma yana faol bo'ladi. Ikkinchi bosish ikkinchi confirmBooking va
   ikkinchi WebView ochadi. Birinchisida to'lab yopgan foydalanuvchi ostidagi
   to'lanmagan formani ko'radi va yana to'lashi mumkin.
   (booking_confirm_cubit.dart, booking_confirm_page.dart — tugma himoyasi
   faqat BookingConfirmLoadingState ga qaraydi.)
   → To'lov boshlangach tugma WebView ochilguncha qulflanadi; kechikkan chipta javobi uni qayta yoqmaydi, ikkinchi WebView ochilmaydi.

№58 ✅ [M] (Y) To'langan buyurtmalar "To'lanmagan" bo'limida chiqadi.
   "To'langan" bo'limiga faqat status == 'ticketed' tushadi. Paid,
   PartiallyTicketed, TicketedWaitingPNR "to'lanmagan" deb ko'rsatiladi.
   To'lovdan keyin foydalanuvchi aynan shu ro'yxatga yuboriladi — vahima,
   qo'ng'iroqlar, qayta to'lash urinishi. (booked_tickets_page.dart _isTicketed)
   → Paid, PartiallyTicketed, TicketedWaitingPNR va boshqa to'langan holatlar "To'langan" bo'limida (yagona holat klassifikatori).

№59 ✅ [M] (O) "Chiptani yuklab olish" tugmasi noto'g'ri holatlarda.
   Paid (chipta hali chiqmagan) buyurtmada tugma bor va ticket_url_not_found
   xatosini beradi; PartiallyTicketed / TicketedWaitingPNR da (chipta bor)
   tugma yo'q. (my_ticket_widget.dart, ticketed_booking_search_page.dart)
   → Yuklab olish faqat chipta bor holatlarda; Paid (chipta hali yo'q) — "Chipta chiqarilmoqda" yozuvi.

№60 ✅ [M] (Y) Qayta tekshiruvdan keyin narx o'zgarsa, foydalanuvchiga aytilmaydi.
   Kartada 3.0 mln, tekshiruv 3.4 mln qaytarsa faqat tugmadagi narx
   o'zgaradi — "narx o'zgardi: eski → yangi" oynasi yo'q. Keyingi narx
   tekshiruvi allaqachon yangi narx bilan solishtiradi. "Aldov" taassuroti,
   shikoyat va qaytarishlar. (ticket_info_page.dart, booking_create_flow.dart)
   → Tekshiruv narxi foydalanuvchi kartada ko'rgan narxdan farq qilsa "eski → yangi" oynasi chiqadi (ma'lumot oynasida ham, bron oldidan ham).

№61 ✅ [M] (O) Tarif tanlash noto'g'ri tarifni belgilaydi va tekshiruvsiz bron qiladi.
   Tekshiruvdan keyin reys id bron tokeniga almashadi, tarif oynasi tanlangan
   tarifni topa olmay 1-tarifni belgilaydi — "Tasdiqlash" bosilsa reys jimgina
   boshqa (qimmatroq yoki bagajsiz) tarifga almashadi. Tekshiruv ketayotganda
   tanlangan tarif esa umuman qayta tekshirilmay bron qilinadi.
   (ticket_tariffs_widget.dart, booking_gate.dart FlightValidation.keeping)
   → Tarif barqaror kalit (reys raqami, tarif kodi, bagaj) bo'yicha topiladi, jimgina 1-tarifga o'tmaydi; boshqa tarif tanlansa u qayta tekshiriladi. Backend tarif id'si bilan getFlightInfo'ni qabul qilishini tasdiqlash kerak.

№62 ✅ [M] (Y) Host foydalanuvchisi almashsa, oldingi odamning pasport va kartalari qoladi.
   Telefon almashganda faqat tokenlar va profil keshi tozalanadi. Saqlangan
   yo'lovchilar (cached_users, pasport raqamlari bilan), _userData (ism,
   pasport, kartalar), yo'lovchi qoralamasi, so'nggi qidiruvlar qoladi —
   B foydalanuvchi A ning yo'lovchilari va kartasini ko'radi. SDK ichidagi
   "Chiqish" va "Hisobni o'chirish" ham qoralamani tozalamaydi. Bundan
   tashqari har "Davom etish"da pasport raqami, tug'ilgan kun, ism diskka
   (GetStorage, avtoto'ldirish ro'yxati) ochiq yoziladi va chiqishda
   o'chmaydi. (sdk.dart ensureRegistered, passenger_storage_service.dart,
   project_dialogs.dart)
   → Foydalanuvchi almashganda, SDK'dan chiqishda va hisob o'chirilganda barcha shaxsiy ma'lumot (saqlangan yo'lovchilar, avtoto'ldirish, qoralama, qidiruvlar, keshlar, sessiya) o'chiriladi; pasport raqami, tug'ilgan kun va muddat diskka yozilmaydi.

№63 ✅ [M] (Y) Karta raqami, amal qilish muddati, SMS kod va JShShIR release loglarga yoziladi.
   debugPrint release'da ham ishlaydi; Android'da logcat orqali o'qiladi.
   PCI DSS talabiga zid, host bank ilovasi uchun xavf.
   (add_card_service.dart, my_contracts_service.dart)
   → Karta, muddat, SMS kod va JShShIR faqat debug build'da va niqoblangan holda loglanadi.

№65 ✅ [M] (O) To'lov WebView'dagi "Qayta yuklash" bank sahifasini qayta yuboradi.
   Xatodan keyin reload() chaqiriladi; POST bilan ochilgan bank/3DS
   sahifasida Android POST'ni qayta yuboradi — takroriy to'lov urinishi yoki
   "sessiya tugadi". Boshlang'ich to'lov URL'ini qayta ochish kerak.
   (webview_page.dart)
   → "Qayta yuklash" boshlang'ich to'lov URL'ini qayta ochadi (bank POST'i qayta yuborilmaydi).

№66 ✅ [M] (O) To'lov holati tekshirilayotganda "orqaga" bosh sahifaga otadi.
   60–90 soniyalik tekshiruv paytida ogohlantirishsiz bosh sahifaga o'tadi,
   tekshiruv to'xtaydi — to'lagan odam natijani ham, buyurtmasini ham
   ko'rmaydi. "Buyurtmalarim"ga o'tishi kerak. (booking_confirm_page.dart)
   → Tekshiruv paytida "orqaga" tasdiq so'raydi; to'langan/kutilayotgan holatda "Buyurtmalarim"ga o'tadi.


5.2. Bronni to'xtatadigan xatolar (forma va kirish)

№67 ✅ [M] (Y) Hujjat raqami tavsiyasi tanlansa seriya harflari tushib qoladi.
   "AA" yozib "AA1234567" tavsiyasi bosilsa maydonda "1234567" qoladi
   (_onSelected formatter bor maydonda faqat raqamlarni oladi). Fokus keyingi
   maydonga o'tib ketadi — sezilmaydi. Natija: "pasport raqami noto'g'ri"
   yoki noto'g'ri hujjatga chipta. Qaytgan xaridorlarga tegadi.
   (booking_form_fields.dart _onSelected)
   → Tavsiya tanlanganda seriya harflari saqlanadi.

№68 ✅ [M] (Y) Saqlangan yo'lovchi tanlansa sanalar ISO formatda tushadi va forma rad etadi.
   copyFromUser birthdate/docexp ni serverdagi "1990-03-12" ko'rinishida
   qo'yadi, forma esa dd.MM.yyyy kutadi — "Davom etish" ikki marta
   invalid_date_format beradi. №26 dagi "bir bosishda to'ldirish" amalda
   ishlamaydi. (passenger_model.dart copyFromUser)
   → Saqlangan yo'lovchi va skaner sanalari dd.MM.yyyy ga o'giriladi.

№70 ✅ [M] (O) Hujjat turi (P/A) fuqarolik qanday kiritilganiga qarab turlicha.
   Skaner va saqlangan yo'lovchi fuqarolikni copyWithCitizen emas, oddiy
   copyWith bilan qo'yadi: skanerlangan UZ yo'lovchi P, qo'lda kiritilgan A
   oladi; UZ slotda tanlangan RU yo'lovchi A bilan qoladi. №6 dagi qoidaga
   zid, srv_invalid_document_type. (passenger_model.dart mergeScan, copyFromUser)
   → Skaner va saqlangan yo'lovchida hujjat turi qo'lda kiritish bilan bir xil qoida bo'yicha (copyWithCitizen).

№73 ✅ [M] (P) Ism ichidagi bo'sh joy o'chiriladi.
   "ANNA MARIA" → "ANNAMARIA", bo'sh joy umuman yozilmaydi; skanerdagi qo'sh
   ismlar ham qo'shilib ketadi — ism pasportga mos kelmaydi.
   (passenger_rules.dart normalizeName)
   → Ism ichida bitta bo'sh joy saqlanadi ("ANNA MARIA").

№74 ✅ [M] (Y) "Kodni qayta yuborish"dan keyin SMS kod bilan kirib bo'lmaydi.
   Qayta yuborilganda yangi otpToken cubit holatiga yoziladi, tekshiruv esa
   eski widget.otpToken ni yuboradi. Kod qayta so'ragan har kim kira olmaydi
   — "Buyurtmalarim" va saqlangan yo'lovchilar yopiq. Qayta yuborish xatosi
   ko'rsatilmaydi, taymer 0 bo'lganda yozilayotgan kod o'chadi.
   (verify_otp_widget.dart)
   → Qayta yuborilgandan keyin yangi kod tokeni ishlatiladi, xato ko'rsatiladi, taymer tugaganda kod o'chmaydi.

№75 ✅ [M] (O) Karta qo'shishda "Kodni qayta yuborish" SMS yubormaydi.
   Tugma faqat maydonni tozalab taymerni qayta boshlaydi, sendCardOtp
   chaqirilmaydi. Birinchi kod eskirgach chiqishdan boshqa yo'l yo'q.
   (card_otp_page.dart)
   → "Kodni qayta yuborish" SMS'ni haqiqatan qayta yuboradi.

№76 ✅ [M] (O) Token yangilash xato bersa sessiya "o'lik" bo'lib qoladi.
   Tarmoq uzilishi ham token bekor qilingandek qabul qilinadi; haqiqiy xatoda
   tokenlar tozalanmaydi, isLoggedIn true qoladi — har so'rov 401 → refresh →
   xato. ensureRegistered qayta ro'yxatdan o'tkazmaydi. Buyurtmalar va
   saqlangan yo'lovchilar qayta o'rnatmaguncha ishlamaydi. Bu №17 ning aniq
   mexanizmi, tuzatish SDK tomonda. (dio_client.dart, sdk.dart)
   → Tarmoq xatosida sessiya saqlanadi; token haqiqatan bekor bo'lsa tozalanadi va host telefoni bilan jim qayta ro'yxatdan o'tiladi (60 s da ko'pi bilan bir marta, foydalanuvchi almashuvi bilan aralashmaydi).


5.3. Qidiruv va natijalar

№79 ✅ [M] (O) Yo'nalish sahifasi 3 ta yashirin to'liq qidiruv yuboradi.
   "Eng yaxshi takliflar" sahifa ochilganda va har yo'lovchi/filtr
   o'zgarishida hamma manbaga qidiruv yuboradi va asosiy qidiruvda bekor
   qilinmaydi (90 s gacha). Natijada 6 ta og'ir qidiruv parallel — birinchi
   natijalar sekinlashadi, GDS yuki ikki barobar. (route_search_cubit.dart)
   → Takliflar qidiruvi 700 ms kechiktiriladi, manbalar ketma-ket so'raladi, parametr o'zgarsa va asosiy qidiruv boshlanganda bekor qilinadi.

№80 ✅ [M] (O) Natijalardagi sana lentasi narxlari "To'g'ri reys"/"Bagaj" filtrini hisobga olmaydi.
   Lentada ulanishli reyslar narxi ko'rinadi, o'sha kun bosilsa narx yuqori
   yoki "topilmadi". (ticket_page.dart getPriceByMonth chaqiruvi)
   → Sana lentasi "To'g'ri reys" / "Bagaj" filtrlarini hisobga oladi.

№81 ✅ [M] (O) Qidiruv va tarif so'rovlari foydalanuvchi tilida emas (№52 to'liq emas).
   Qidiruv so'rovida lang ?? "en" — hech kim lang qo'ymaydi; tariflar uchun
   "lang": "ru" qattiq yozilgan. Natija kartalarida inglizcha shaharlar,
   tarif shartlari doim ruscha. Shahar qidiruvida xom e.toString() chiqadi.
   (recom_req_model.dart, avia_service.dart, city_choose_cubit.dart)
   → Qidiruv, tarif va tekshiruv so'rovlari foydalanuvchi tilida (uz/ru/en); shahar qidiruvi xatosi tarjima qilingan.

№83 ✅ [M] (P) "Bilet izlash" tez ikki bosilsa ikkita natijalar sahifasi ochiladi.
   Har biri 3 ta qidiruv; "orqaga" birinchi safar ishlamagandek tuyuladi.
   (route_search_page.dart, route_search_header.dart, main_search_form.dart)
   → "Bilet izlash" ikki marta bosilsa bitta sahifa ochiladi.

№84 ✅ [M] (P) Narx grafigi: eski javob yangisini bosadi, sanalar jimgina almashadi.
   Filtr tez o'zgartirilsa eski so'rov javobi yangisini yozib yuboradi;
   qaytish sanasi ketishdan oldin bo'lsa sanalar so'ramasdan almashtiriladi.
   (route_search_price_chart.dart)
   → Eski javob yangisini bosmaydi; qaytish sanasi ketishdan oldin bo'lsa ogohlantiriladi, sanalar almashtirilmaydi.

№85 ✅ [M] (P) Taklif kartasini ochish tanlangan sanalarni o'zgartiradi.
   _openOffer pickDay chaqiradi va qaytish sanasini o'chiradi — keyingi
   qidiruv boshqa sanada va bir tomonga ketadi. (route_search_page.dart)
   → Taklif kartasi forma sanalarini o'zgartirmaydi.

№86 ✅ [M] (P) "Yangi reyslar" tugmasi yangi reys bo'lmasa ham chiqadi; karta joyi siljiydi.
   Dublikatlar olib tashlangandan keyin ham yangi obyekt qaytgani uchun tugma
   chiqadi va bosilganda ro'yxat tepaga sakraydi. Arzonroq dublikat eski
   kartani almashtirsa (boshqa id), o'qilayotgan karta ro'yxat oxiriga
   ko'chadi. (ticket_page.dart, flight_results_utils.dart mergeDedupe)
   → Tugma faqat haqiqiy yangi reys kelganda chiqadi; arzonroq dublikat eski kartaning joyini egallaydi.


5.4. Buyurtmalar va profil

№87 ✅ [M] (O) Buyurtma ID bo'yicha qidiruv sahifasi qulaydi va holatni noto'g'ri o'qiydi.
   Normallashtirilgan orderStatus o'rniga xom callbackStatus o'qiladi (bo'sh
   yoki kichik harf bo'lsa holat va tugmalar yo'q). tickets?[0] bo'sh ro'yxatda
   RangeError. Kubitda tarjima qilinmagan o'zbekcha xato matni.
   (ticketed_booking_search_page.dart, ticketed_booking_search_cubit.dart)
   → Normallashtirilgan holat o'qiladi, bo'sh ro'yxatda qulamaydi, xato matni tarjima qilingan.

№88 ✅ [M] (O) Buyurtmalar ro'yxatidagi taymer ilova fonga ketgach orqada qoladi.
   Har tikda 1 ayiriladi, createdAt dan qayta hisoblanmaydi — iOS fonda
   taymerni to'xtatadi. Muddati o'tgan buyurtmada "To'lash" ko'rinadi, bosilsa
   darhol "vaqt tugadi" va bosh sahifa. Kartalarda key yo'q — yangilanishdan
   keyin boshqa buyurtmaning taymeri ko'rinishi mumkin.
   (expire_time_widget.dart, ticked_list_page.dart)
   → Qolgan vaqt har tikda createdAt'dan hisoblanadi; kartalarda key bor; muddati o'tganda "To'lash" yashiriladi.

№89 ✅ [M] (P) Bitta buzuq chek yoki shartnoma sahifani abadiy yuklanishda qoldiradi.
   amount int deb cast qilinadi, null sana DateTime.parse; shartnomalarda
   faqat Exception ushlanadi, TypeError emas. (account_service.dart,
   cheque_model.dart, my_contracts_service.dart)
   → Buzuq chek/shartnoma o'tkazib yuboriladi, barcha xatolar ushlanadi — sahifa yuklanishda qolmaydi.

№90 ✅ [M] (P) "Chiqish" qatori "Hisobni o'chirasizmi?" oynasini ochadi.
   Amalda faqat chiqadi, lekin "Ha, o'chirish" matni qo'rqitadi.
   (profile_page.dart)
   → "Chiqish" o'z tasdiq oynasini ochadi.

№91 ✅ [M] (P) "Saqlangan yo'lovchilarga qo'shish" tizimga kirmaganlarda ham yoqilgan turadi.
   Mehmon uchun hech narsa saqlanmaydi — keyingi safar ro'yxat bo'sh.
   Kirmaganlarda yashirish kerak. (passenger_form_page.dart)
   → Mehmon uchun "Saqlangan yo'lovchilarga qo'shish" yashirin.


5.5. Host ilova bilan integratsiya

№92 ✅ [M] (O) SDK ikki marta ochilsa qulaydi.
   Statik navigatorKey; host "Aviabilet"ni ikki marta bossa "Duplicate
   GlobalKey" — kulrang/bo'sh ekran. Ikkala nusxa webRegister qiladi,
   yuqoridagisi yopilganda pastkisidan chiqish buziladi. (app.dart)
   → Ikkinchi nusxa ochilmaydi (birinchisi ishlayveradi), webRegister bir marta ketadi; host embed'ni yangi key bilan qursa ishlayveradi.

№93 ✅ [M] (O) SDK host ilovaning ekran yo'nalishini o'zgartiradi.
   init() runApp dan oldin butun hostni portretga qulflaydi; chiqishda
   barcha yo'nalishlarni (landshaft, teskari) yoqadi — faqat portret host
   buziladi. (sdk.dart, app.dart)
   → init() host yo'nalishini qulflamaydi; portret faqat SDK ekranda. Chiqishda MySafarConfig.hostOrientations (yoki platforma standarti) tiklanadi.

№94 ✅ [M] (O) Hive global holati host bilan umumiy.
   Hive.initFlutter() subDir'siz — host (Unired hive ishlatadi) uchun global
   yo'lni almashtiradi; profile_cache, remote_config, tickets_cache kabi
   umumiy nomli qutilar to'qnashishi mumkin. (hive_service.dart)
   → Hive qutilari alohida papkada (mysafar_sdk) va mysafar_ prefiksi bilan; host'ning global Hive yo'liga tegilmaydi. Eski keshlar bir marta bo'sh ochiladi.

№95 ✅ [M] (O) CocoaPods host'larda iOS kamera ruxsati doim "rad etilgan".
   permission_handler CocoaPods'da PERMISSION_CAMERA=0 — so'rov oynasiz
   permanentlyDenied qaytaradi; Sozlamalarda kamera tugmasi ham yo'q.
   Pasport skaneri ishlamaydi. README'ga Podfile
   GCC_PREPROCESSOR_DEFINITIONS (PERMISSION_CAMERA=1, PERMISSION_MICROPHONE=1)
   qo'shilishi kerak. Example SPM bilan ishlagani uchun sezilmagan.
   → README'ga Podfile PERMISSION_CAMERA/MICROPHONE va Info.plist ruxsatlari qo'shildi; example Podfile ham.

№96 ✅ [M] (O) "Aqlli" tab ochilishi bilan mikrofon ruxsati so'raladi.
   №49 dagi xato qolip. Rad etilgach mikrofon tugmasi jim ishlamaydi
   (recorder.start tekshiruvsiz). NSMicrophoneUsageDescription yo'q hostda
   iOS qulashi xavfi. (widgets.dart SmartSearchWidget)
   → Mikrofon faqat tugma bosilganda so'raladi; rad etilsa xabar / Sozlamalar.


5.6. Analitika

№97 ✅ [M] (O) Voronka raqamlari solishtirib bo'lmaydi.
   - Profil ID avval telefon raqami (PII), keyin backend ID — bir odam ikki
     profil.
   - Har yashirin webRegister user_registered yuboradi — ro'yxatdan o'tishlar
     soni ma'nosiz.
   - ticket_searched faqat natijalar sahifasi ochilganda; sahifa ichidagi
     qayta qidiruvlarda yo'q, results_shown esa har safar — natijalar
     qidiruvlardan ko'p chiqadi. Hamma manba xato bersa no_results yo'q.
   - passenger_form_completed faqat bron muvaffaqiyatida — bron xatosi
     "formani tashlab ketdi" bo'lib ko'rinadi.
   - Qayta kirishda birinchi screen_view (tab_home) dublikat deb tashlanadi;
     trackButtonTap tarjima qilingan matn bilan — hodisa tilga bo'linadi.
   (auth_service.dart, profile_cubit.dart, router.dart, tickets_cubit.dart,
   booking_create_flow.dart, navigation_service.dart, profile_page.dart)
   → Profil ID telefon emas, backend ID; user_registered faqat yangi ro'yxatda (backend "yangi" belgisini yuborishi kerak); sahifa ichidagi qidiruvlar va hamma manba xatosi ham hisoblanadi; passenger_form_completed forma yuborilganda; qayta kirishda birinchi screen_view tashlanmaydi; tugma hodisalari barqaror id bilan.


5.7. Backend

№98 ❌ [B] (Y) /auth/web-register istalgan telefon raqamiga autentifikatsiyasiz JWT beradi.
   So'rov AuthMode.none bilan faqat {phone_number} yuboradi (partner token
   ham, OTP ham yo'q). Raqamni bilgan har kim hisob tokenini oladi:
   buyurtmalar, saqlangan pasportlar, profil. Backend: kamida partner token
   va host imzolagan tasdiq talab qilish; mobil shuni yuborishi kerak.
   (auth_service.dart, sdk.dart)


5.8. Reliz oldidan

№99 ✅ [M] (Y) Commit qilinmagan o'zgarishlar 9 ta git'da kuzatilmayotgan faylga bog'liq.
   passenger_draft_store, flight_results_utils, booking_gate,
   booking_create_flow, booking_passenger_saver, connectivity_banner,
   ticket_pdf_actions, booking_flight_summary_card, cover_image_cache_size.
   booking_create_page.dart o'chirilgani staged. Faqat o'zgargan fayllar
   commit qilinsa SDK kompilyatsiya bo'lmaydi — host'da bron umuman yo'q.
   Hozirgi holatda flutter analyze lib toza.
   → Commit qilinganda barcha yangi fayllar qo'shiladi (shu tuzatishlar bilan bitta commit).

Tahlilda tasdiqlangan ✅ bandlar: №12, №13, №14, №33, №38, №39 tavsifdagidek
ishlaydi. O'chirilgan 105 ta assetdan hech biri kodda ishlatilmaydi.


════════════════════════════════════════════════════════════════
YAXSHI ISHLAYOTGANLAR
════════════════════════════════════════════════════════════════
- Bron uchun majburiy login yo'q.
- Bitta manba xato bersa, boshqasining reyslari ko'rsatiladi.
- Eng arzonlari birinchi chiqadi, natijalar ro'yxati tez ishlaydi.
- Shahar qidiruvi kod, kirill va lotin bo'yicha yaxshi ishlaydi.
- Ikki marta bosishdan himoya bor.
- To'lov taymeri faqat o'z kartasini yangilaydi.
- Barcha 6 tilda kalitlar soni bir xil.


════════════════════════════════════════════════════════════════
NIMADAN BOSHLASH KERAK
════════════════════════════════════════════════════════════════

Mobil (SDK) jamoasi:
1. 1- va 5-bo'limdagi mobil bandlar tuzatildi. Commitda barcha yangi
   fayllar birga qo'shilsin (№99).
2. Qolgani 3-bo'limdagi umumiy bandlarning mobil qismi (№1, №11, №15, №17,
   №21, №18/№44) — backend bilan kelishilgach.
3. Backend tasdiqlashi kerak bo'lgan mobil taxminlar: tarif id'si bilan
   getFlightInfo (№61), webRegister javobidagi "yangi foydalanuvchi" belgisi
   (№97), qidiruv/tarif so'rovlarida "uz" tili (№81).

Backend jamoasi:
1. Bron vaqtini soat mintaqasi bilan berish va expire maydonini to'ldirish
   (№16) — hozir ba'zi mamlakatlarda bron darhol "muddati o'tgan" bo'ladi.
2. "To'landi, bilet chiqarilmoqda" holatini qaytarish (№18).
3. "AwaitPayment" buyurtmasi uchun to'lov havolasini qayta berish (№45).
4. Xatolarga barqaror kod va tushunarli matn (№8, №17).
5. Valyuta bo'yicha bron va to'lov usullari (№5, №15).
6. /auth/web-register ni autentifikatsiya bilan himoyalash (№98) — xavfsizlik.
7. Qidiruv javobi formatini barqaror qilish, doim UZS narx (№77, №82).
