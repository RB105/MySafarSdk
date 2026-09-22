MySafar SDK — bilet kam sotilishiga sabab bo'layotgan muammolar

Sana: 22.09.2026. Tuzatishlar: commit 847bce6 (branch rustam).
Holat: ✅ tuzatildi · 🟡 qisman tuzatildi · ❌ tuzatilmagan

Bu ro'yxat kod tahlili asosida tuzilgan, real sotuv ma'lumotlari asosida emas.


A. Pulni to'g'ridan-to'g'ri yo'qotadiganlar

1. ✅ To'lov natijasi aniqlanmas edi.
   To'lov sahifasi yopilgach natija tekshirilmas edi. Pul to'lagan odam "to'lov vaqti tugadi" deb qidiruvga qaytarilishi va ikkinchi marta to'lashi mumkin edi.
   Tuzatildi: sahifa yopilgach buyurtma holati 60 soniyagacha tekshiriladi, shu vaqtda to'lov tugmasi o'chiq turadi. To'langan, kutilmoqda va to'lanmagan holatlari ko'rsatiladi. To'lov analitikaga yuboriladi.

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
   Qolgan: USD tanlagan foydalanuvchi uchun bron avvalgidek RUBda yaratiladi (backend bilan tasdiqlash kerak).

6. ✅ Yo'lovchi ma'lumoti faqat "bo'sh emasmi" deb tekshirilar edi.
   Yarim yozilgan sana, muddati o'tgan pasport, yoshga mos kelmaydigan tug'ilgan kun, kirill harfli ism o'tib ketar, server esa ularni faqat oxirgi qadamda rad etar edi.
   Tuzatildi: bular bron yuborilishidan oldin tekshiriladi. Kirillcha ism avtomatik lotinga o'giriladi, apostrof olib tashlanadi.
   Qolgan: hujjat turi (P/A) fuqarolikka qarab belgilanadi, backend bilan tasdiqlash kerak.

7. ✅ Bron va to'lov so'rovlari qayta yuborilar edi.
   POST so'rovlar 502/503/504 xatosida qayta jo'natilib, ikkinchi bron yaratishi mumkin edi. Xato ~3 daqiqadan keyin chiqar edi.
   Tuzatildi: bron va to'lov so'rovlari qayta yuborilmaydi, qidiruv so'rovlari avvalgidek qayta yuboriladi. Ulanish kutish vaqti 60 → 20 soniya.


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
    Qolgan: taymer telefon soati va qattiq yozilgan 1800 soniyaga tayanadi; server vaqti o'qilmasa, foydalanuvchi sahifadan darhol chiqarib yuboriladi.

17. ❌ Sessiya.
    Yashirin ro'yxatdan o'tish buzilsa, qayta tiklanmaydi: saqlangan yo'lovchilar va email yo'qoladi. Birinchi ochilishda 10 soniyagacha spinner turadi. Partner token xatosi "Internet yo'q" bo'lib ko'rinadi.

18. ❌ "Buyurtmalarim"dan to'lash va to'langan biletlar.
    Keyin to'lashda narx doim UZS summasi bo'yicha chiqadi. To'lov oynasini ochganda ilova qulashi mumkin. "To'landi, bilet chiqarilmoqda" holati yo'q, bilet ro'yxati bo'sh bo'lsa sahifa qulaydi.


C. O'lchab bo'lmaslik va mayda muammolar

19. 🟡 Analitika teshik.
    Tuzatildi: to'lov muvaffaqiyati, daromad va to'lov xatolari endi yuboriladi.
    Qolgan: asosiy qidiruv yo'lida ticket_searched yo'q; "natijalar chiqdi"/"natija yo'q", booking_failed hodisalari va ekran nomlari yo'q.

20. ❌ Mayda muammolar.
    Qattiq yozilgan o'zbekcha matnlar bor; ticket_url_not_found kaliti tarjima fayllarida yo'q. "Oferta" havolasi maxfiylik siyosati sahifasini ochadi. Yangi manba kelganda ro'yxat tepaga sakraydi. Bir reys ikki marta chiqishi mumkin. Ishlatilmaydigan ~6 MB asset bor.


Qo'shimcha

✅ Pasport skaneri xira rasm yuborar edi.
   Tuzatildi: avtofokus, maksimal sifatda suratga olish, ramka atrofidan kesish va yuqori sifatli JPEG. Pasport matni avvalgidan ~2 barobar tiniqroq yuboriladi.


Yaxshi ishlayotganlar
- Bron uchun majburiy login yo'q.
- Bitta manba xato bersa, boshqasining reyslari ko'rsatiladi.
- Eng arzonlari birinchi chiqadi.
- Shahar qidiruvi kod, kirill va lotin bo'yicha yaxshi ishlaydi.
- Ikki marta bosishdan himoya bor.
- Barcha 6 tilda kalitlar soni bir xil.
