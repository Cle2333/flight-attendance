package com.cle2333.flightattendance.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * 旧 Node.js 版本只识别 precision/effect/theme/quotes，effectEmoji 是 Flutter
 * 端新加的字段，原后端会静默丢掉。这里把 effectEmoji 也接进来以修这个 bug。
 */
public record UpdateSettingsRequest(
        String precision,
        String effect,
        String theme,
        List<String> quotes,
        @JsonProperty("effectEmoji") String effectEmoji
) {
}
