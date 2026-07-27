/// MRZ test qatorlari (ICAO namunalar, mrz_parser testlaridan mos).
library;

const td3Line1 = 'P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<';
const td3Line2 = 'L898902C36UTO7408122F1204159ZE184226B<<<<<10';

const td1Line1 = 'I<SWE59000002<8198703142391<<<';
const td1Line2 = '8703145M1701027SWE<<<<<<<<<<<8';
const td1Line3 = 'SPECIMEN<<SVEN<<<<<<<<<<<<<<<<';

/// TD1 — hujjat raqami check-digit xato (strict yiqiladi).
const td1Line1BadDocCheck = 'I<SWE59000002<0198703142391<<<';

const td2Line1 = 'P<D<<MUSTERMANN<<ERIKA<<<<<<<<<<<<<<';
const td2Line2 = 'C01X00T478D<<6408125F2702283<<<<<<<4';

String fitMrzLine(String line, int length) {
  if (line.length >= length) return line.substring(0, length);
  return line.padRight(length, '<');
}

/// TD3 ikki qatorni bitta uzun qatorga (OCR birlashgan holat).
String get td3Merged88 => td3Line1 + td3Line2;

/// TD3 line2 dan birinchi belgi tushgan (43 belgi) — prefix repair uchun.
String get td3Line2MissingPrefix =>
    td3Line2.length == 44 ? td3Line2.substring(1) : td3Line2;

/// Millat maydonida OCR: UTO → 0ZB.
String get td3Line2NatOcr0ZB => td3Line2.replaceFirst('UTO', '0ZB');
