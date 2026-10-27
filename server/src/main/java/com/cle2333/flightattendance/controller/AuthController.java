package com.cle2333.flightattendance.controller;

import com.cle2333.flightattendance.dto.ApiResponse;
import com.cle2333.flightattendance.dto.AuthData;
import com.cle2333.flightattendance.dto.LoginRequest;
import com.cle2333.flightattendance.dto.LogoutRequest;
import com.cle2333.flightattendance.dto.RefreshRequest;
import com.cle2333.flightattendance.dto.RegisterRequest;
import com.cle2333.flightattendance.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    @PostMapping("/register")
    public ApiResponse<AuthData> register(@Valid @RequestBody RegisterRequest req) {
        return ApiResponse.ok(auth.register(req.account(), req.password(), req.nickname()));
    }

    @PostMapping("/login")
    public ApiResponse<AuthData> login(@Valid @RequestBody LoginRequest req) {
        return ApiResponse.ok(auth.login(req.account(), req.password()));
    }

    /** 用 refresh token 换新的 access + refresh（旧 refresh 自动撤销） */
    @PostMapping("/refresh")
    public ApiResponse<AuthData> refresh(@Valid @RequestBody RefreshRequest req) {
        return ApiResponse.ok(auth.refresh(req.refreshToken()));
    }

    /** 登出：撤销 refresh token。access token 仍会在短期内可用（无状态） */
    @PostMapping("/logout")
    public ApiResponse<Void> logout(@Valid @RequestBody LogoutRequest req) {
        auth.logout(req.refreshToken());
        return ApiResponse.ok(null);
    }
}
