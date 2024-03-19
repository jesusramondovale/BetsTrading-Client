class GoogleRegisterRequest {
  final String id;
  final String displayName;
  final String email;
  final String photoUrl;
  final String serverAuthCode;

  GoogleRegisterRequest(this.serverAuthCode, {
    required this.id,
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

}