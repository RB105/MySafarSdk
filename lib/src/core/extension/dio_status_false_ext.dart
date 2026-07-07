
// catch exact error
extension ErrorMessage on dynamic {
  String catchError({String? msg}) {
    if (this['data'] != null) {
      if (this['data']['message'] != null) {
        return "${this['data']['message']}";
      } else {
        return msg ?? 'retry';
      }
    } 
    
    return msg ?? 'retry';
  }
}
