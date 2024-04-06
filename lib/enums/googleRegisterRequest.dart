class GoogleRegisterRequest {
  final String id;
  final String displayName;
  final String email;
  final String photoUrl;
  final String serverAuthCode;
  final DateTime birthday;

  GoogleRegisterRequest(this.serverAuthCode, {
    required this.id,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.birthday,
  });

}