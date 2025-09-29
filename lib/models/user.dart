class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String? website;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.website,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      if (phone != null) 'phone': phone,
      if (website != null) 'website': website,
    };
  }
}
