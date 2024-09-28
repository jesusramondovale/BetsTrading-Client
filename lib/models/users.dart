class User {
  final String id;
  String? idcard;
  final String fullname;
  final String password;
  final String country;
  final String gender;
  final String email;
  final DateTime birthday;
  final DateTime signinDate;
  DateTime lastSession;
  final String creditCard;
  final String username;
  DateTime? tokenExpiration;
  bool isActive;
  int failedAttempts;
  DateTime? lastLoginAttempt;
  DateTime? lastPasswordChange;
  String? profilePic;
  int points;

  User({
    required this.id,
    this.idcard,
    required this.fullname,
    required this.password,
    required this.country,
    required this.gender,
    required this.email,
    required this.birthday,
    required this.signinDate,
    required this.lastSession,
    required this.creditCard,
    required this.username,
    this.points = 0,
    this.tokenExpiration,
    this.isActive = true,
    this.failedAttempts = 0,
    this.lastLoginAttempt,
    this.lastPasswordChange,
    this.profilePic,
  });

  // From Json
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      idcard: json['idcard'],
      fullname: json['fullname'],
      password: json['password'],
      country: json['country'],
      gender: json['gender'],
      email: json['email'],
      birthday: DateTime.parse(json['birthday']),
      signinDate: DateTime.parse(json['signin_date']),
      lastSession: DateTime.parse(json['last_session']),
      creditCard: json['credit_card'],
      username: json['username'],
      points: json['points'] ?? 0.0,
      tokenExpiration: json['token_expiration'] != null ? DateTime.parse(json['token_expiration']) : null,
      isActive: json['is_active'] ?? true,
      failedAttempts: json['failed_attempts'] ?? 0,
      lastLoginAttempt: json['last_login_attempt'] != null ? DateTime.parse(json['last_login_attempt']) : null,
      lastPasswordChange: json['last_password_change'] != null ? DateTime.parse(json['last_password_change']) : null,
      profilePic: json['profile_pic'],
    );
  }
}