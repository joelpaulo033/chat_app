class UserModel {
  final String uid;
  final String email;

  UserModel({required this.uid, required this.email});

  // factory user fromMap
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
    );
  }

  // user toMap
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
    };
  }
}
