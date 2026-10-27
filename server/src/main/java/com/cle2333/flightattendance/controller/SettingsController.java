package com.cle2333.flightattendance.controller;

import com.cle2333.flightattendance.dto.ApiResponse;
import com.cle2333.flightattendance.dto.SettingsDto;
import com.cle2333.flightattendance.dto.UpdateSettingsRequest;
import com.cle2333.flightattendance.security.UserPrincipal;
import com.cle2333.flightattendance.service.SettingsService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/settings")
public class SettingsController {

    private final SettingsService settings;

    public SettingsController(SettingsService settings) {
        this.settings = settings;
    }

    @GetMapping
    public ApiResponse<SettingsDto> get(@AuthenticationPrincipal UserPrincipal me) {
        return ApiResponse.ok(settings.get(me.userId()));
    }

    @PutMapping
    public ApiResponse<Void> update(@AuthenticationPrincipal UserPrincipal me,
                                    @RequestBody UpdateSettingsRequest req) {
        settings.update(me.userId(), req);
        return ApiResponse.ok(null);
    }
}
