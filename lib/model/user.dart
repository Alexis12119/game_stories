class User {
  final String userID;
  final String email;
  final String username;

  User({
    required this.userID,
    required this.username,
    required this.email,
  });

  factory User.fromJSON(Map<String, dynamic> json) {
    return User(userID: json[''], username: json[''], email: json['']);
  }
}
