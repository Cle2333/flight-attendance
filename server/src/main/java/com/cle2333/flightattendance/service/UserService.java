package com.cle2333.flightattendance.service;

import com.cle2333.flightattendance.dto.UserDto;
import com.cle2333.flightattendance.entity.User;
import com.cle2333.flightattendance.exception.ApiException;
import com.cle2333.flightattendance.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository users;

    public UserService(UserRepository users) {
        this.users = users;
    }

    @Transactional(readOnly = true)
    public UserDto getProfile(Long userId) {
        User u = users.findById(userId)
                .orElseThrow(() -> new ApiException("用户不存在", HttpStatus.NOT_FOUND));
        return UserDto.from(u);
    }

    @Transactional
    public UserDto updateProfile(Long userId, String nickname, String avatar) {
        User u = users.findById(userId)
                .orElseThrow(() -> new ApiException("用户不存在", HttpStatus.NOT_FOUND));
        if (nickname != null && !nickname.isBlank()) {
            u.setNickname(nickname);
        }
        // avatar 允许设为 null（清空头像）
        if (avatar != null) {
            u.setAvatar(avatar);
        }
        return UserDto.from(users.save(u));
    }
}
