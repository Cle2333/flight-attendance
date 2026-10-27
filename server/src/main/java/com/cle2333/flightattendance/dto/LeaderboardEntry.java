package com.cle2333.flightattendance.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record LeaderboardEntry(
        Long id,
        @JsonProperty("username") String username,
        String nickname,
        String avatar,
        @JsonProperty("count") long count
) {
}
