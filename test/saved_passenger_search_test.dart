import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/booking/support/saved_passenger_search.dart';

UsersModel _user(String last, String first,
        {String? middle, String? doc, String? birth}) =>
    UsersModel(
      lastname: last,
      firstname: first,
      middlename: middle,
      docnum: doc,
      birthdate: birth,
    );

void main() {
  final vali = _user('ALIYEV', 'VALI', doc: 'AA 1234567', birth: '12.03.1990');
  final madina =
      _user('KARIMOVA', 'MADINA', middle: 'ALI QIZI', doc: 'FA7654321');
  final khurshid = _user("YO'LDOSHEV", 'KHURSHID', doc: 'AB0001112');
  final alisher = _user('NAVOIY', 'ALISHER', birth: '09.02.1985');
  final users = [madina, khurshid, alisher, vali];

  List<UsersModel> search(String q) => SavedPassengerSearch.filter(users, q);

  test('bo\'sh so\'rov — ro\'yxat o\'zgarmaydi', () {
    expect(search(''), users);
    expect(search('   '), users);
  });

  test('familiya/ism boshlanishi, katta-kichik harf farqsiz', () {
    // "aliy" yozilayotganda ALIYEV birinchi (Alisher / Ali qizi ham mos).
    expect(search('aliy').first, vali);
    expect(search('aliyev'), [vali]);
    expect(search('Madina'), [madina]);
  });

  test('bir nechta so\'z — hammasi mos kelishi kerak, tartib farqsiz', () {
    expect(search('ali val'), [vali]);
    expect(search('vali aliyev'), [vali]);
    expect(search('ali madina'), [madina]);
    expect(search('vali madina'), isEmpty);
  });

  test('ism/familiya boshlanganlar birinchi', () {
    // "ali" — ALIYEV (familiya), ALISHER (ism), ALI QIZI (otasining ismi).
    expect(search('ali'), [vali, alisher, madina]);
  });

  test('kirill yozuvi lotin nomni topadi', () {
    expect(search('алиев'), [vali]);
    expect(search('Мадина'), [madina]);
  });

  test('apostrof va kh/x farqi', () {
    expect(search('yoldosh'), [khurshid]);
    expect(search('yo‘ldoshev'), [khurshid]);
    expect(search('xurshid'), [khurshid]);
    expect(search('хуршид'), [khurshid]);
  });

  test('hujjat raqami bo\'shliqsiz ham, qismi bo\'yicha ham', () {
    expect(search('aa1234567'), [vali]);
    expect(search('AA 123'), [vali]);
    expect(search('7654'), [madina]);
  });

  test('tug\'ilgan sana bo\'yicha', () {
    expect(search('1985'), [alisher]);
    expect(search('12.03'), [vali]);
  });

  test('ajratib ko\'rsatish oraliqlari', () {
    expect(SavedPassengerSearch.highlightRanges('ALIYEV VALI', 'ali val'),
        [(0, 3), (7, 10)]);
    expect(SavedPassengerSearch.highlightRanges('ALIYEV VALI', ''), isEmpty);
  });
}
