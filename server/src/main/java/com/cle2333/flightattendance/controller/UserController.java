package com.cle2333.flightattendance.controller;

import com.cle2333.flightattendance.dto.ApiResponse;
import com.cle2333.flightattendance.dto.UpdateProfileRequest;
import com.cle2333.flightattendance.dto.UserDto;
import com.cle2333.flightattendance.security.UserPrincipal;
import com.cle2333.flightattendance.service.UserService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/user")
public class UserController {

    private final UserService users;

    public UserController(UserService users) {
        this.users = users;
    }

    @GetMapping("/profile")
    public ApiResponse<UserDto> profile(@AuthenticationPrincipal UserPrincipal me) {
        return ApiResponse.ok(users.getProfile(me.userId()));
    }

    @PutMapping("/profile")
    public ApiResponse<UserDto> updateProfile(@AuthenticationPrincipal UserPrincipal me,
                                              @RequestBody UpdateProfileRequest req) {
        return ApiResponse.ok(users.updateProfile(me.userId(), req.nickname(), req.avatar()));
    }
}
