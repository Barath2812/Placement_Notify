class UserModel {
  final String uid;
  final String name;
  final String email;
  final String fcmToken;
  final List<String> bookmarks;
  final List<String> readNotices;
  final String? lastLogin;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.fcmToken,
    required this.bookmarks,
    required this.readNotices,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      fcmToken: json['fcmToken'] ?? '',
      bookmarks: (json['bookmarks'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [],
      readNotices: (json['readNotices'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [],
      lastLogin: json['lastLogin']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'fcmToken': fcmToken,
      'bookmarks': bookmarks,
      'readNotices': readNotices,
      'lastLogin': lastLogin,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? fcmToken,
    List<String>? bookmarks,
    List<String>? readNotices,
    String? lastLogin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      fcmToken: fcmToken ?? this.fcmToken,
      bookmarks: bookmarks ?? this.bookmarks,
      readNotices: readNotices ?? this.readNotices,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
