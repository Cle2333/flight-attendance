/// 纯本地资料。没有账号、密码或角色。
class LocalProfile {
  final String nickname;
  final String? avatarPath;

  const LocalProfile({this.nickname = '本地用户', this.avatarPath});

  factory LocalProfile.fromJson(Map<String, dynamic> json) {
    final nickname = (json['nickname'] as String?)?.trim();
    final avatarPath = (json['avatar_path'] as String?)?.trim();
    return LocalProfile(
      nickname: nickname == null || nickname.isEmpty ? '本地用户' : nickname,
      avatarPath: avatarPath == null || avatarPath.isEmpty ? null : avatarPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'nickname': nickname,
    if (avatarPath != null) 'avatar_path': avatarPath,
  };

  LocalProfile copyWith({
    String? nickname,
    String? avatarPath,
    bool clearAvatarPath = false,
  }) => LocalProfile(
    nickname: nickname ?? this.nickname,
    avatarPath: clearAvatarPath ? null : avatarPath ?? this.avatarPath,
  );
}
