package com.cle2333.flightattendance.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record AuthData(
        Long userId,
        String account,
        String nickname,
        String role,
        String accessToken,
        String refreshToken,
        long accessTokenExpiresIn,   // 秒
        long refreshTokenExpiresIn   // 秒
) {
    /**
     * 向后兼容：老 Flutter / 旧版客户端读 d['token']。
     * 等所有客户端都切到 accessToken 后可删除（建议保留 ≥ 一个大版本）。
     */
    @JsonProperty("token")
    public String legacyToken() {
        return accessToken;
    }
}
