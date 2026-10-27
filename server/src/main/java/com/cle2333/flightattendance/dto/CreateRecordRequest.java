package com.cle2333.flightattendance.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * 创建打卡记录的请求体。
 *
 * <p>{@code time} 用 String 接收，保留与原 Node.js 后端相同的灵活性：
 * 任何 ISO-8601 字符串都接受（{@code "2026-06-19T10:00:00"}、
 * {@code "2026-06-19T10:00:00Z"}、{@code "2026-06-19T18:00:00+08:00"}），
 * 由 {@code RecordService.parseTime()} 做最终解析。</p>
 */
public record CreateRecordRequest(@NotBlank String time, String note) {
}
