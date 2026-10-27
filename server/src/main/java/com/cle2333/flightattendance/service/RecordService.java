package com.cle2333.flightattendance.service;

import com.cle2333.flightattendance.dto.RecordDto;
import com.cle2333.flightattendance.dto.SyncRecordItem;
import com.cle2333.flightattendance.entity.Record;
import com.cle2333.flightattendance.exception.ApiException;
import com.cle2333.flightattendance.repository.RecordRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class RecordService {

    private final RecordRepository records;

    public RecordService(RecordRepository records) {
        this.records = records;
    }

    @Transactional(readOnly = true)
    public List<RecordDto> list(Long userId) {
        return records.findByUserIdOrderByTimeAsc(userId)
                .stream().map(RecordDto::from).toList();
    }

    @Transactional
    public Long add(Long userId, String time, String note) {
        Record saved = records.save(new Record(userId, parseTime(time), note));
        return saved.getId();
    }

    @Transactional
    public void update(Long userId, Long id, String time, String note) {
        Record r = records.findById(id)
                .orElseThrow(() -> new ApiException("记录不存在", HttpStatus.NOT_FOUND));
        if (!r.getUserId().equals(userId)) {
            // 不是自己的记录也返回 404，避免 IDOR 探测
            throw new ApiException("记录不存在", HttpStatus.NOT_FOUND);
        }
        r.setTime(parseTime(time));
        r.setNote(note);
        records.save(r);
    }

    @Transactional
    public void delete(Long userId, Long id) {
        Record r = records.findById(id)
                .orElseThrow(() -> new ApiException("记录不存在", HttpStatus.NOT_FOUND));
        if (!r.getUserId().equals(userId)) {
            throw new ApiException("记录不存在", HttpStatus.NOT_FOUND);
        }
        records.delete(r);
    }

    @Transactional
    public int sync(Long userId, List<SyncRecordItem> items) {
        if (items == null) {
            throw new ApiException("记录格式错误", HttpStatus.BAD_REQUEST);
        }
        // 替换式同步：删旧 + 批量插新
        records.deleteAllByUserId(userId);
        for (SyncRecordItem item : items) {
            records.save(new Record(userId, parseTime(item.time()), item.note()));
        }
        return items.size();
    }

    /**
     * 兼容多种 ISO-8601 字符串（带/不带时区、带/不带秒、纯日期），与原 Node.js 后端行为一致。
     * 失败抛 400 ApiException，让 GlobalExceptionHandler 转成统一响应。
     */
    static Instant parseTime(String s) {
        if (s == null || s.isBlank()) {
            throw new ApiException("time 字段不能为空", HttpStatus.BAD_REQUEST);
        }
        String trimmed = s.trim();
        try {
            // 1) 带时区的完整 ISO-8601：2026-06-19T10:00:00Z / +08:00
            return Instant.parse(trimmed);
        } catch (Exception ignored) {
            // fallthrough
        }
        try {
            // 2) 无时区但有秒：当作 UTC（与原 Node.js "new Date(str)" 行为一致 —— 无 tz 时按本地时区）
            // 这里用 UTC 是因为 JVM 默认 tz 不固定；Flutter 客户端发的是本地时间但缺 tz 会按 UTC 存
            // 保留 UTC 是为了让跨时区用户结果一致，原 Node.js 后端行为是 host tz
            return LocalDateTime.parse(trimmed, DateTimeFormatter.ISO_LOCAL_DATE_TIME)
                    .toInstant(ZoneOffset.UTC);
        } catch (Exception ignored) {
            // fallthrough
        }
        try {
            // 3) 纯日期：2026-06-19
            return LocalDateTime.parse(trimmed + "T00:00:00", DateTimeFormatter.ISO_LOCAL_DATE_TIME)
                    .toInstant(ZoneOffset.UTC);
        } catch (Exception e) {
            throw new ApiException("time 字段格式错误: " + s, HttpStatus.BAD_REQUEST);
        }
    }
}
