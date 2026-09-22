MySafar SDK — bilet kam sotilishiga sabab bo'layotgan muammolar

Sana: 22.09.2026. Tuzatishlar: commitlar 847bce6 va e068992 (branch rustam).
Holat: ✅ tuzatildi · 🟡 qisman tuzatildi · ❌ tuzatilmagan

Bu ro'yxat kod tahlili asosida tuzilgan, real sotuv ma'lumotlari asosida emas.
Birinchi tahlil qidiruvdan to'lovgacha bo'lgan yo'lni ko'rdi (1–20). Ikkinchi tahlil ilova tezligi, bilet olish qulayligi, qamrab olinmagan oqimlar va tuzatishlarning o'zini tekshirdi (21–56 va E bo'limi).


A. Pulni to'g'ridan-to'g'ri yo'qotadiganlar

1. ✅ To'lov natijasi aniqlanmas edi.
   To'lov sahifasi yopilgach natija tekshirilmas edi. Pul to'lagan odam "to'lov vaqti tugadi" deb qidiruvga qaytarilishi va ikkinchi marta to'lashi mumkin edi.
   Tuzatildi: sahifa yopilgach buyurtma holati 60 soniyagacha tekshiriladi, shu vaqtda to'lov tugmasi o'chiq turadi. To'langan, kutilmoqda va to'lanmagan holatlari ko'rsatiladi. To'lov analitikaga yuboriladi.
   Qolgan: bank to'lovdan keyin mysafar.uz/payment?billing_id=... manziliga qaytaradi, lekin to'lov sahifasi shu manzilni ko'rib avtomatik yopilmaydi. Foydalanuvchi uni o'zi yopishi va "yopasizmi?" oynasini tasdiqlashi kerak.

2. ✅ Android "orqaga" tugmasi (embed rejimda) to'lov himoyasini chetlab o'tar edi.
   Karta yoki 3DS sahifasida bir bosish butun to'lovni yopar edi. Bron yaratilayotgan paytda bosilsa, bron sahifasi yopilib ketar edi.
   Tuzatildi: "orqaga" sahifadagi himoyani hisobga oladi. Bron yuklanish oynasini "orqaga" bilan yopib bo'lmaydi.

3. ✅ Qayta qidiruvda reyslar yo'qolar edi.
   Birinchi natijadagi aviakompaniyalar keyingi so'rovga filtr sifatida yuborilar edi, shuning uchun boshqa aviakompaniyalar chiqmas edi.
   Tuzatildi: filtrga faqat foydalanuvchi o'zi tanlagan aviakompaniyalar yuboriladi.

4. ✅ Noto'g'ri "reys topilmadi".
   Bir manba bo'sh qaytib, boshqasi xato bersa, "reys yo'q" deb ko'rsatilar va qayta urinish tugmasi bo'lmas edi.
   Tuzatildi: manba timeout, ulanish yoki 5xx xatosi bersa, "Qayta urinish" tugmali xato chiqadi.

5. ✅ Narx noto'g'ri ko'rsatilar edi.
   - "Eng yaxshi takliflar"da narx "— UZS" chiqar, takliflar esa 1 kattalar uchun hisoblanar edi.
   - USD yoki RUB narxi bo'lmasa, UZS summasi "USD" belgisi bilan yoki "0 USD" bo'lib chiqar edi.
   - Narx oshgandan keyin to'lov sahifasida eski narx turar edi.
   Tuzatildi: uchala holat ham.
   Qolgan: USD tanlagan foydalanuvchi uchun bron avvalgidek RUBda yaratiladi, bu haqda oldindan aytilmaydi (backend bilan tasdiqlash kerak).

6. ✅ Yo'lovchi ma'lumoti faqat "bo'sh emasmi" deb tekshirilar edi.
   Yarim yozilgan sana, muddati o'tgan pasport, yoshga mos kelmaydigan tug'ilgan kun, kirill harfli ism o'tib ketar, server esa ularni faqat oxirgi qadamda rad etar edi.
   Tuzatildi: bular bron yuborilishidan oldin tekshiriladi. Urg'uli lotin harflari (Ç, İ, Ş, Ü) asosiy harfga keltiriladi, apostrof olib tashlanadi. Kirillcha yozilsa, "pasportdagidek lotincha yozing" xatosi chiqadi. Safar davomida 2 yoshga to'ladigan bola "bola" sifatida bron qilinadi.
   Qolgan: hujjat turi (P/A) fuqarolikka qarab belgilanadi, backend bilan tasdiqlash kerak.

7. ✅ Bron va to'lov so'rovlari qayta yuborilar edi.
   POST so'rovlar 502/503/504 xatosida qayta jo'natilib, ikkinchi bron yaratishi mumkin edi. Xato ~3 daqiqadan keyin chiqar edi.
   Tuzatildi: bron va to'lov so'rovlari qayta yuborilmaydi, faqat o'qiydigan so'rovlar qayta yuboriladi. Ulanish kutish vaqti 60 → 20 soniya.


B. Ishonch va qulaylikni buzadiganlar

8. 🟡 Xato matnlari yordam bermaydi.
   Tuzatildi: bron va to'lov xatolari foydalanuvchi tilida chiqadi, yuklanish oynasi osilib qolmaydi.
   Qolgan: server xatolarida hali ham "5 daqiqadan keyin urinib ko'ring" chiqadi; bron xatosi oynasida "Qayta urinish" yo'q.

9. ❌ Natijalar 5 daqiqada majburan eskiradi.
   Chiqqan oynani yopib bo'lmaydi, qayta qidirishdan boshqa tugma yo'q.

10. ✅ "Reys topilmadi" ekranida hech qanday tugma yo'q edi.
    Tuzatildi: "Qayta qidirish" va "Qidiruvni o'zgartirish" tugmalari qo'shildi.

11. ❌ Reysni qayta tekshirish xato bersa, davom etib bo'lmaydi.
    Qisqa internet uzilishi ham "Bron qilish"ni o'chiradi. Tarif tanlanganda qayta tekshirilgan bron tokeni yo'qoladi. Kechikib kelgan tekshiruv javobi tanlangan tarifni bekor qiladi.

12. ❌ Orqaga qaytilganda kiritilgan yo'lovchi ma'lumotlari yo'qoladi.
    Qoralama saqlanmaydi.

13. ❌ Chaqaloqlar soni kattalardan ko'p bo'lishi mumkin.
    Buning xatosi faqat bron qadamida chiqadi.

14. ❌ Kontakt maydonlari.
    Email formati tekshirilmaydi. Telefonda +998 avtomatik qo'yilmaydi. "Telefon yo'lovchiga tegishli bo'lishi shart" degan yozuv boshqa odam uchun bilet olayotganlarni cho'chitadi.

15. ❌ To'lov usullari.
    "Rossiya kartalari" (PAYGINE) QR sahifani o'sha telefonning o'zida ochadi. Hostdagi saqlangan xorijiy kartalar taklif qilinmaydi. To'lov usullari valyutaga qarab filtrlanmaydi.

16. 🟡 To'lov taymeri ishonchsiz.
    Tuzatildi: to'lagan yoki to'lovi tekshirilayotgan foydalanuvchi "vaqt tugadi" deb chiqarib yuborilmaydi.
    Qolgan: server bron vaqtini (created_at) soat mintaqasiz Toshkent vaqtida yuboradi, ilova esa uni telefon vaqti deb o'qiydi. Qirg'iziston va Sibir kabi UTC+6 va sharqroqdagi telefonlarda bron darhol "muddati o'tgan" bo'lib, foydalanuvchi to'lov sahifasidan chiqarib yuboriladi. Moskva va Turkiyada esa taymer ~2.5 soat uzun bo'lib, muddati o'tgan bronga "To'lash" tugmasi ko'rinadi. Serverdagi expire maydoni ishlatilmaydi.

17. ❌ Sessiya.
    Yashirin ro'yxatdan o'tish buzilsa, qayta tiklanmaydi: saqlangan yo'lovchilar va email yo'qoladi. Birinchi ochilishda 10 soniyagacha spinner turadi. Partner token xatosi "Internet yo'q" bo'lib ko'rinadi.

18. ❌ "Buyurtmalarim"dan to'lash va to'langan biletlar.
    Keyin to'lashda narx doim UZS summasi bo'yicha chiqadi. To'lov oynasini ochganda ilova qulashi mumkin. "To'landi, bilet chiqarilmoqda" holati yo'q, bilet ro'yxati bo'sh bo'lsa sahifa qulaydi. Buyurtma kartasida response!.data! bor, shuning uchun muvaffaqiyatsiz bron yozuvi bo'sh kulrang quti bo'lib chiqadi.


C. O'lchab bo'lmaslik va mayda muammolar

19. 🟡 Analitika teshik.
    Tuzatildi: to'lov muvaffaqiyati, daromad va to'lov xatolari endi yuboriladi.
    Qolgan: asosiy qidiruv yo'lida ticket_searched yo'q; "natijalar chiqdi"/"natija yo'q", booking_failed hodisalari va ekran nomlari yo'q.

20. ❌ Mayda muammolar.
    Qattiq yozilgan o'zbekcha matnlar bor; ticket_url_not_found kaliti tarjima fayllarida yo'q. "Oferta" havolasi maxfiylik siyosati sahifasini ochadi. Yangi manba kelganda ro'yxat tepaga sakraydi. Bir reys ikki marta chiqishi mumkin. Ishlatilmaydigan ~6 MB asset bor.


D. Ikkinchi tahlilda topilganlar

Bilet olish qulayligi

21. ❌ Birinchi yo'lovchi foydalanuvchining o'z ma'lumotlari bilan to'ldirilmaydi.
    Ko'pincha xaridorning o'zi 1-yo'lovchi, lekin ism va tug'ilgan kunni har safar qo'lda yozadi. Profilda ism bor, lekin faqat email va telefon olinadi. Host uzatadigan ma'lumotlarda (MySafarUserData) ism, tug'ilgan kun va pasport maydonlari umuman yo'q.

22. ❌ Reysni tanlashdan to'lovgacha qadamlar juda ko'p.
    Bitta kattalar uchun eng qisqa yo'l ~21 bosish, 9 ta ekran va 9 ta oyna. Har bir yo'lovchi alohida sahifada to'ldiriladi, 1 yo'lovchi bo'lsa ham forma o'zi ochilmaydi. Keyin alohida "Ma'lumotlarni tasdiqlash" sahifasi keladi, u faqat kiritilganlarni takrorlaydi va tugmasi oldingi sahifadagi bilan bir xil nomlangan.

23. ❌ Tasdiqlash va to'lov sahifasida nima uchun to'lanayotgani ko'rinmaydi.
    Yo'nalish, sana, bagaj va qaytarish shartlari yo'q, faqat to'lov usullari va buyurtma ID'si bor.

24. ❌ Qidiruvda ortiqcha bosishlar.
    Sana tanlangach, yo'lovchilar oynasi o'zi ochiladi, birinchi marta valyuta oynasi ham chiqadi, keyin yana "Qidirish" bosish kerak. Oraliqda qat'iy ~1 soniya kutishlar bor. Bosh sahifada tanlangan yo'nalish orqaga qaytilganda unutiladi.

25. ❌ Bosh sahifadagi "almashtirish" tugmasi boshi berk ko'chaga olib boradi.
    "Qayerga" saqlanmagani uchun almashtirish "Qayerdan"ni bo'shatadi. Undan keyin shahar tanlash hech narsa qilmaydi yoki qidiruv to'xtab qoladi. Toshkentga qaytayotganlar aynan shu tugmani ishlatadi.

26. ❌ Saqlangan yo'lovchilarga yetish qiyin.
    4 bosish kerak bo'ladi, ro'yxat yosh toifasi bo'yicha filtrlanmaydi, boshqa slotda allaqachon tanlanganlar ham ko'rinadi.

27. ❌ Forma standart qiymatlari.
    Fuqarolik bo'sh turadi va yozish o'rtasida davlat tanlagichi ochilib ketadi. Jins jimgina "Erkak" qilib tanlangan, bu noto'g'ri chiptaga olib kelishi mumkin. Bola va chaqaloq uchun tug'ilgan kun tanlagichi 1990-yildan boshlanadi.

28. ❌ Klaviatura.
    Hech bir maydonda avtoto'ldirish (autofill) yo'q. Sana maydonlarida iOS'da "Keyingi" tugmasi yo'q. Yo'lovchi formasidagi "Davom etish" tugmasi klaviatura ostida qolib ketadi.

29. ❌ Saqlangan karta tanlovida buyurtma summasi hisobga olinmaydi.
    Pul yetmaydigan karta tanlansa, xato faqat SMS kod bosqichida chiqadi. Oxirgi ishlatilgan karta oldindan tanlanmaydi.

30. ❌ Chiptani saqlash va ulashish qiyin.
    PDF ilovaning yopiq papkasiga saqlanadi, "ulashish" tugmasi yo'q. Telefonda PDF ko'ruvchi bo'lmasa hech narsa ochilmaydi va xato ham chiqmaydi.

31. ❌ Takroriy qidiruv noldan boshlanadi.
    Sanasi o'tgan so'nggi qidiruvlar butunlay yashiriladi. Yo'lovchilar soni va klass esa oldingi qidiruvdan olinmaydi.

32. ❌ Katta shrift va kichik tugmalar.
    Maydonlar balandligi qat'iy, katta tizim shriftida matn sig'maydi. Ba'zi tugmalar 34–36 dp (tavsiya ≥44 dp). Ba'zi yorliqlar 10.5 px va xira rangda. Ikonka tugmalarida ekran o'quvchi uchun nom yo'q.

Tezlik va silliqlik

33. ❌ Qidiruv natijalari UI oqimida nusxalanadi.
    Har bir manba javobi fon isolate'ga uzatilishidan oldin to'liq nusxalanadi (compute bilan Map). Reyslar chiqayotgan paytda past qurilmalarda ekran qotib qoladi.

34. ❌ Natijalar sahifasi har yangilanishda barcha reyslarni qayta saralaydi va guruhlaydi.
    Taqqoslashda narx matni har safar qayta o'qiladi. Bitta qidiruvda bu ~5 marta, har biri o'nlab millisekund.

35. ❌ Bosh sahifada animatsiyali fon ustida bir nechta blur effekti turadi.
    Past Android qurilmalarda sekinlashtiradi, yorug' rejimda esa blur umuman ko'rinmaydi. Fon rasmlarini oldindan yuklash ishlamaydi. Fon taymeri bosh sahifa yashiringanda ham ishlayveradi.

36. ❌ "Bron qilish" tugmasi reys qayta tekshirilguncha o'chiq turadi.
    GDS javobini kutish kerak bo'ladi. Uni fonda tekshirib, yo'lovchi formasini darhol ochish mumkin.

37. ❌ Bron oldidan keraksiz token tekshiruvi.
    Bron partner token bilan ketsa ham, avval qo'shimcha so'rov yuboriladi. U yopib bo'lmaydigan yuklanish oynasi ichida vaqt oladi.

38. ❌ To'lov usullari keshlanmaydi.
    Har bir to'lov sahifasida serverdan kutiladi va shu vaqtda "To'lash" tugmasi o'chiq turadi.

39. ❌ Oylik narxlar 2–3 marta so'raladi.
    Klass parametri turli joylarda har xil yuboriladi, keshning esa muddati va chegarasi yo'q.

40. ❌ Narx grafigini aylantirish og'ir.
    Har bir kun o'tganda 365 kunlik ro'yxat qayta quriladi.

41. ❌ Yo'lovchilarni profilga saqlash to'lov sahifasi yuklanishi bilan bir vaqtda ketadi.
    Bu to'lov sahifasini sekinlashtiradi.

42. ❌ Yo'lovchilar sahifasi har bir tugma bosilishida to'liq qayta quriladi.
    Email va telefon maydonlarida sezilarli.

43. ❌ Yo'nalish rasmlari to'liq o'lchamda dekodlanadi.
    Kichik kartalarda ham, bu xotirani ko'p egallaydi.

Qamrab olinmagan oqimlar

44. ❌ "Buyurtmalarim" serverdan yangilanmaydi.
    Keshdagi ro'yxat bor bo'lsa, faqat o'sha ko'rsatiladi. To'langan → bilet chiqarildi o'zgarishi va boshqa qurilmadagi buyurtmalar faqat qo'lda tortib yangilaganda chiqadi.

45. ❌ "AwaitPayment" holatidagi buyurtmada "To'lash" tugmasi yo'q.
    To'lovni davom ettirib bo'lmaydi.

46. ❌ Yo'nalish kartasidagi tugma boshqa marshrutni qidiradi.
    Kartada ko'rsatilgan marshrut va narx o'rniga doim Toshkentdan qidiriladi. Kod bo'lmasa, tugma jim turadi.

47. ❌ Yo'nalishlar qidiruvi faqat yuklangan sahifalar ichida qidiradi.
    Mavjud yo'nalish "topilmadi" deb chiqishi mumkin.

48. ❌ Internet yo'qligida.
    To'lov sahifasi yuklanmasa, telefonning o'z "sahifa mavjud emas" ekrani chiqadi, "Qayta yuklash" tugmasi yo'q. Ilovada internet yo'qligi haqida xabar hech qayerda yo'q.

49. ❌ Har ochilishda joylashuv so'raladi.
    Foydalanuvchi hech narsa qilmasdan ruxsat oynasi chiqadi, rad etilsa keyingi ochilishda yana so'raladi.

50. ❌ "Buyurtmalarim"dan tizimga kirgach bosh sahifaga otib yuboriladi.
    Buyurtmalar sahifasiga qaytarilmaydi.

51. ❌ Aqlli qidiruv yuklanishi osilib qolishi mumkin.
    Server javobida kerakli maydon bo'lmasa, yuklanish oynasi yopilmaydi.

52. ✅ Host tili server so'rovlariga o'tmas edi.
    Embed rejimda rus tilidagi foydalanuvchi uchun bron so'rovi, server xabarlari, davlat nomlari va oy nomlari o'zbekcha ketar edi.
    Tuzatildi: til SDK'ning faol tilidan olinadi.

53. ✅ Reysni qayta tekshirish so'roviga kk/tg/tr to'g'ridan-to'g'ri yuborilar edi.
    Backend faqat uz/ru/en qabul qilsa, qozoq, tojik va turk tilidagi foydalanuvchilar bron qila olmas edi.
    Tuzatildi: uz/ru/en ga moslab yuboriladi.

54. ✅ Davlat tanlagichidagi bayroqlar to'liq o'lchamda dekodlanar edi.
    256 ta 300×200 rasm scroll paytida ~60 MB xotira egallar edi.
    Tuzatildi.


E. Tuzatishlarning o'zida topilgan xatolar (847bce6) — hammasi e068992 da tuzatildi

55. ✅ Ismlar jimgina buzilar edi.
    İBRAHİM → BRAHM, ÇAĞLAR → ALAR bo'lib qolar edi. Kirillcha ХУРШИД ruscha qoidada KHURSHID bo'lar edi (o'zbek pasportida XURSHID).
    Tuzatildi: urg'uli harflar asosiy harfga keltiriladi, kirill o'zgartirilmaydi, lotincha yozish so'raladi.

56. ✅ To'lov holati tekshiruvidagi xatolar.
    - "Booked" javobi 12 soniyadan keyin "to'lanmagan" deb hisoblanar edi. Eski urinishdagi "Cancelled" esa darhol "muvaffaqiyatsiz" bo'lar edi. Shu sabab to'lagan odamga "to'lov o'tmadi" ko'rsatilib, u ikkinchi marta to'lashi mumkin edi.
    - Sekin tarmoqda tekshiruv daqiqalab cho'zilar edi.
    - "Kutilmoqda" holatida qayta to'lash imkoni yo'q edi.
    - "Elektron chiptani yuklab olish" chipta chiqarilmasdan taklif qilinar edi.
    Tuzatildi: tekshiruv 60 soniyalik oyna oxirigacha davom etadi, buyurtmaning hozirgi holati ustun, har so'rovga 10 s va jami 90 s chegara. "Kutilmoqda" oynasida "Pul yechilmagan — qayta to'lash" tugmasi bor. E-chipta faqat chipta chiqarilganda taklif qilinadi.

    Shu commitdagi boshqa tuzatishlar:
    - Safar davomida 2 yoshga to'ladigan bolani hech qaysi toifada bron qilib bo'lmas edi, endi u "bola" sifatida o'tadi.
    - Skaner 48–64 MP kamerali telefonlarda xotira yetmay yopilib qolishi mumkin edi, endi 4K bilan cheklandi.
    - Faqat o'qiydigan so'rovlar (buyurtmalar, to'lov holati, yo'nalishlar) qayta yuborish imkonini yo'qotgan edi, endi qaytarildi.


Qo'shimcha

✅ Pasport skaneri xira rasm yuborar edi.
   Tuzatildi: avtofokus, 4K sifatda suratga olish, ramka atrofidan kesish va yuqori sifatli JPEG. Pasport matni avvalgidan taxminan 2 barobar tiniqroq yuboriladi.


Yaxshi ishlayotganlar
- Bron uchun majburiy login yo'q.
- Bitta manba xato bersa, boshqasining reyslari ko'rsatiladi.
- Eng arzonlari birinchi chiqadi, natijalar ro'yxati tez ishlaydi.
- Shahar qidiruvi kod, kirill va lotin bo'yicha yaxshi ishlaydi.
- Ikki marta bosishdan himoya bor.
- To'lov taymeri faqat o'z kartasini yangilaydi.
- Barcha 6 tilda kalitlar soni bir xil.


Nimadan boshlash kerak (bilet olishni osonlashtirish uchun)
1. Birinchi yo'lovchini xaridor ma'lumotlari bilan to'ldirish va 1 yo'lovchida formani darhol ochish (21, 22).
2. To'lov sahifasini bank qaytish manzilida avtomatik yopish (1) va taymer soat mintaqasi (16).
3. Bosh sahifadagi almashtirish tugmasi (25) va qidiruvdagi ortiqcha bosishlar (24).
4. To'lov sahifasida nima uchun to'lanayotganini ko'rsatish (23) va "Buyurtmalarim"ni yangilash (44, 45, 18).
5. Tezlik: natijalarni fonda o'qish va saralashni keshlash (33, 34), bosh sahifadagi blur (35).
