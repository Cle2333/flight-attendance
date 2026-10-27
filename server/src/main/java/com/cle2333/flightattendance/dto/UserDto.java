package com.cle2333.flightattendance.dto;

import com.cle2333.flightattendance.entity.User;

import java.time.Instant;

public record UserDto(Long id, String account, String nickname, String avatar, Instant createdAt) {
    public static UserDto from(User u) {
        return new UserDto(u.getId(), u.getAccount(), u.getNickname(), u.getAvatar(), u.getCreatedAt());
    }
}
