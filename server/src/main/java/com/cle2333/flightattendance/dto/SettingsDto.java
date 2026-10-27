package com.cle2333.flightattendance.dto;

import com.cle2333.flightattendance.entity.Settings;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public record SettingsDto(
        @JsonProperty("precision_setting") String precision,
        String effect,
        String theme,
        @JsonProperty("effectEmoji") String effectEmoji,
        List<String> quotes
) {
    public static SettingsDto from(Settings s) {
        return new SettingsDto(
                s.getPrecision(),
                s.getEffect(),
                s.getTheme(),
                s.getEffectEmoji(),
                parseQuotes(s.getQuotes())
        );
    }

    /**
     * 兼容旧 Node.js 端的"\\n"分隔格式（DB 里的内容可能是这两种之一）：
     *  - 真正的 JSON 数组字符串："[\"a\",\"b\"]"
     *  - 反斜杠-n 串："a\\nb\\nc"（旧版写入的）
     */
    @SuppressWarnings("unchecked")
    private static List<String> parseQuotes(String raw) {
        if (raw == null || raw.isBlank()) {
            return defaultQuotes();
        }
        String trimmed = raw.trim();
        if (trimmed.startsWith("[")) {
            try {
                com.fasterxml.jackson.databind.ObjectMapper m = new com.fasterxml.jackson.databind.ObjectMapper();
                List<String> parsed = m.readValue(trimmed, List.class);
                if (parsed != null) {
                    List<String> out = new ArrayList<>();
                    for (Object o : parsed) {
                        if (o != null) out.add(o.toString());
                    }
                    return out;
                }
            } catch (Exception ignored) {
            }
        }
        // 反斜杠-n 分隔
        List<String> out = new ArrayList<>();
        for (String s : Arrays.asList(raw.split("\\\\n"))) {
            if (!s.isEmpty()) out.add(s);
        }
        if (out.isEmpty()) return defaultQuotes();
        return Collections.unmodifiableList(out);
    }

    public static List<String> defaultQuotes() {
        return List.of(
                "飞行是对天空的诗意探索。",
                "天空是飞行员的画布。",
                "每一次起飞都是一次冒险。"
        );
    }
}
