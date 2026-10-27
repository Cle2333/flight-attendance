package com.cle2333.flightattendance.controller;

import com.cle2333.flightattendance.dto.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/test")
public class TestController {

    @GetMapping
    public ApiResponse<Map<String, String>> ping() {
        return ApiResponse.ok(Map.of("message", "API works!"));
    }
}
