class UserModel {
  final String userId;
  final String name;
  final String email;
  final String profilePhoto;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.profilePhoto,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'profile_photo': profilePhoto,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePhoto: map['profile_photo'] ?? '',
    );
  }
}
