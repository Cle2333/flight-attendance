package com.cle2333.flightattendance.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * 统一响应包装 —— 与旧 Node.js 版的 { success, data?, message? } 格式保持一致
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(boolean success, T data, String message) {

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null);
    }

    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, null, message);
    }
}
