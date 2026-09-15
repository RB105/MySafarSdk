import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/mysafar_sdk.dart';

void main() {
  test('sanitized drops invalid cards and blank email', () {
    const data = MySafarUserData(
      email: '  ',
      uzsCards: [
        MySafarUzsCard(cardNumber: '8600 1234 1234 1234', expire: '2812'),
        MySafarUzsCard(cardNumber: '8600', expire: '2812'),
        MySafarUzsCard(cardNumber: '8600123412341234', expire: '12/28'),
      ],
      foreignCards: [
        MySafarForeignCard(cardToken: 'tok', cardMask: '4276 **** **** 1234'),
        MySafarForeignCard(cardToken: ' ', cardMask: 'x'),
      ],
    );
    final s = data.sanitized();
    expect(s.email, isNull);
    expect(s.uzsCards, hasLength(1));
    expect(s.uzsCards.first.displayMask, '8600 **** **** 1234');
    expect(s.foreignCards, hasLength(1));
    expect(s.toString(), isNot(contains('8600 1234 1234 1234')));
  });

  test('updateUserData works without init', () {
    expect(MySafarSdk.userData.hasCards, isFalse);
    MySafarSdk.updateUserData(const MySafarUserData(email: ' a@b.uz '));
    expect(MySafarSdk.userData.email, 'a@b.uz');
    MySafarSdk.clearUserData();
    expect(MySafarSdk.userData.hasEmail, isFalse);
  });

  test('displayOwner compacts masked name', () {
    MySafarUzsCard card(String? owner) => MySafarUzsCard(
        cardNumber: '8600123412341234', expire: '2812', owner: owner);
    expect(card('ABDIRAXMONOV R********').displayOwner, 'ABDIRAXMONOV R.');
    expect(card('  ALIYEV   V*****  S****** ').displayOwner, 'ALIYEV V. S.');
    expect(card('R.**** ALIYEV').displayOwner, 'R. ALIYEV');
    expect(card('ALIYEV VALI').displayOwner, 'ALIYEV VALI');
    expect(card('ALIYEV ****').displayOwner, 'ALIYEV');
    expect(card('  ').displayOwner, isNull);
    expect(card(null).displayOwner, isNull);
    expect(
      const MySafarForeignCard(cardToken: 't', cardMask: 'm', owner: 'ALIYEV V***')
          .displayOwner,
      'ALIYEV V.',
    );
  });
}
