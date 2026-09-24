// import 'package:flutter_test/flutter_test.dart';
// import 'package:mysafar_sdk/mysafar_sdk.dart';
//
// void main() {
//   test('sanitized drops invalid cards and blank email', () {
//     const data = MySafarUserData(
//       email: '  ',
//       uzsCards: [
//         MySafarUzsCard(cardNumber: '8600 1234 1234 1234', expire: '2812'),
//         MySafarUzsCard(cardNumber: '8600', expire: '2812'),
//         MySafarUzsCard(cardNumber: '8600123412341234', expire: '12/28'),
//       ],
//       foreignCards: [
//         MySafarForeignCard(cardToken: 'tok', cardMask: '4276 **** **** 1234'),
//         MySafarForeignCard(cardToken: ' ', cardMask: 'x'),
//       ],
//     );
//     final s = data.sanitized();
//     expect(s.email, isNull);
//     expect(s.uzsCards, hasLength(1));
//     expect(s.uzsCards.first.displayMask, '8600 **** **** 1234');
//     expect(s.foreignCards, hasLength(1));
//     expect(s.toString(), isNot(contains('8600 1234 1234 1234')));
//   });
//
//   test('updateUserData works without init', () {
//     expect(MySafarSdk.userData.hasCards, isFalse);
//     MySafarSdk.updateUserData(const MySafarUserData(email: ' a@b.uz '));
//     expect(MySafarSdk.userData.email, 'a@b.uz');
//     MySafarSdk.clearUserData();
//     expect(MySafarSdk.userData.hasEmail, isFalse);
//   });
//
//   test('identification is kept when useful and dropped when empty', () {
//     MySafarSdk.updateUserData(const MySafarUserData(
//       identification: MySafarUserIdentification(
//         firstName: ' VALI ',
//         lastName: 'ALIYEV',
//         birthDate: '1990-03-15',
//         passSeries: 'AA1234567',
//         passSeriesMask: 'AA*******',
//         passExpiry: '2030-03-15',
//         pinfl: '30103901234567',
//         pinflMask: '30103********',
//         isResident: true,
//       ),
//     ));
//     final id = MySafarSdk.userData.identification!;
//     expect(MySafarSdk.userData.hasIdentification, isTrue);
//     expect(id.firstName, 'VALI');
//     expect(id.normalizedBirthDate, '15.03.1990');
//     expect(id.normalizedPassExpiry, '15.03.2030');
//     expect(id.displayPassSeries, 'AA*******');
//     expect(id.displayPinfl, '30103********');
//
//     MySafarSdk.updateUserData(const MySafarUserData(
//       identification: MySafarUserIdentification(),
//     ));
//     expect(MySafarSdk.userData.hasIdentification, isFalse);
//     MySafarSdk.clearUserData();
//   });
//
//   test('identification fromJson maps snake_case fields', () {
//     final id = MySafarUserIdentification.fromJson({
//       'first_name': 'VALI',
//       'last_name': 'ALIYEV',
//       'middle_name': 'VALIYEVICH',
//       'address': 'Toshkent',
//       'pinfl': '30103901234567',
//       'pinfl_mask': '30103********',
//       'pass_series': 'AA1234567',
//       'pass_series_mask': 'AA*******',
//       'pass_expiry': '15.03.2030',
//       'birth_date': '15.03.1990',
//       'is_resident': true,
//     });
//     expect(id.firstName, 'VALI');
//     expect(id.lastName, 'ALIYEV');
//     expect(id.passExpiry, '15.03.2030');
//     expect(id.isResident, isTrue);
//     expect(id.hasUsefulData, isTrue);
//   });
//
//   test('displayOwner compacts masked name', () {
//     MySafarUzsCard card(String? owner) => MySafarUzsCard(
//         cardNumber: '8600123412341234', expire: '2812', owner: owner);
//     expect(card('ABDIRAXMONOV R********').displayOwner, 'ABDIRAXMONOV R.');
//     expect(card('  ALIYEV   V*****  S****** ').displayOwner, 'ALIYEV V. S.');
//     expect(card('R.**** ALIYEV').displayOwner, 'R. ALIYEV');
//     expect(card('ALIYEV VALI').displayOwner, 'ALIYEV VALI');
//     expect(card('ALIYEV ****').displayOwner, 'ALIYEV');
//     expect(card('  ').displayOwner, isNull);
//     expect(card(null).displayOwner, isNull);
//     expect(
//       const MySafarForeignCard(
//               cardToken: 't', cardMask: 'm', owner: 'ALIYEV V***')
//           .displayOwner,
//       'ALIYEV V.',
//     );
//   });
// }
