/// 用户信息
class AppUser {
  final int id;
  final String account;
  final String nickname;
  final String? avatar;
  final String? role;  // 'USER' | 'ADMIN'

  const AppUser({
    required this.id,
    required this.account,
    required this.nickname,
    this.avatar,
    this.role,
  });

  bool get isAdmin => role == 'ADMIN';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        account: json['account'] as String? ?? '',
        nickname: json['nickname'] as String? ?? '',
        avatar: json['avatar'] as String?,
        role: json['role'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'account': account,
        'nickname': nickname,
        'avatar': avatar,
        'role': role,
      };

  AppUser copyWith({String? nickname, String? avatar, String? role}) => AppUser(
        id: id,
        account: account,
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
        role: role ?? this.role,
      );
}
