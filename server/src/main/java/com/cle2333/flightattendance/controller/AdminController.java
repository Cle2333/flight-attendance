package com.cle2333.flightattendance.controller;

import com.cle2333.flightattendance.dto.AdminStats;
import com.cle2333.flightattendance.dto.ApiResponse;
import com.cle2333.flightattendance.dto.LeaderboardEntry;
import com.cle2333.flightattendance.dto.UserDto;
import com.cle2333.flightattendance.security.UserPrincipal;
import com.cle2333.flightattendance.service.AdminService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Admin 接口 —— 现在已经加鉴权（SecurityConfig 里 hasRole("ADMIN")）。
 * 所有调用都会记录审计日志：操作者 + 操作。
 */
@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private static final Logger log = LoggerFactory.getLogger(AdminController.class);

    private final AdminService admin;

    public AdminController(AdminService admin) {
        this.admin = admin;
    }

    @GetMapping("/users")
    public ApiResponse<List<UserDto>> listUsers(@AuthenticationPrincipal UserPrincipal me) {
        log.info("[admin] {} 列出全部用户", me.account());
        return ApiResponse.ok(admin.listUsers());
    }

    @DeleteMapping("/users/{id}")
    public ApiResponse<Void> deleteUser(@AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        log.warn("[admin] {} 删除用户 id={}", me.account(), id);
        admin.deleteUser(id);
        return ApiResponse.ok(null);
    }

    @GetMapping("/leaderboard")
    public ApiResponse<List<LeaderboardEntry>> leaderboard(
            @AuthenticationPrincipal UserPrincipal me,
            @RequestParam(required = false, defaultValue = "all") String type) {
        // leaderboard 是公开读（SecurityConfig 里 permitAll），me 可能为 null
        String who = me == null ? "anonymous" : me.account();
        log.info("[admin] {} 查看榜单 type={}", who, type);
        return ApiResponse.ok(admin.leaderboard(type));
    }

    @GetMapping("/users/{id}")
    public ApiResponse<AdminService.UserDetail> getUserDetail(
            @AuthenticationPrincipal UserPrincipal me, @PathVariable Long id) {
        log.info("[admin] {} 查看用户详情 id={}", me.account(), id);
        return ApiResponse.ok(admin.getUserDetail(id));
    }

    @GetMapping("/stats")
    public ApiResponse<AdminStats> stats(@AuthenticationPrincipal UserPrincipal me) {
        log.info("[admin] {} 查看统计数据", me.account());
        return ApiResponse.ok(admin.stats());
    }
}
