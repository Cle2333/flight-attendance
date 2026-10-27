/// 纯本地资料。没有账号、密码或角色。
class LocalProfile {
  final String nickname;
  final String avatar;

  const LocalProfile({this.nickname = '本地用户', this.avatar = '✈️'});

  factory LocalProfile.fromJson(Map<String, dynamic> json) {
    final nickname = (json['nickname'] as String?)?.trim();
    final avatar = (json['avatar'] as String?)?.trim();
    return LocalProfile(
      nickname: nickname == null || nickname.isEmpty ? '本地用户' : nickname,
      avatar: avatar == null || avatar.isEmpty ? '✈️' : avatar,
    );
  }

  Map<String, dynamic> toJson() => {'nickname': nickname, 'avatar': avatar};

  LocalProfile copyWith({String? nickname, String? avatar}) => LocalProfile(
    nickname: nickname ?? this.nickname,
    avatar: avatar ?? this.avatar,
  );
}
