package com.cle2333.flightattendance.controller;

import com.cle2333.flightattendance.dto.ApiResponse;
import com.cle2333.flightattendance.dto.CreateRecordRequest;
import com.cle2333.flightattendance.dto.RecordDto;
import com.cle2333.flightattendance.dto.SyncRecordsRequest;
import com.cle2333.flightattendance.dto.UpdateRecordRequest;
import com.cle2333.flightattendance.security.UserPrincipal;
import com.cle2333.flightattendance.service.RecordService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/records")
public class RecordController {

    private final RecordService records;

    public RecordController(RecordService records) {
        this.records = records;
    }

    @GetMapping
    public ApiResponse<List<RecordDto>> list(@AuthenticationPrincipal UserPrincipal me) {
        return ApiResponse.ok(records.list(me.userId()));
    }

    @PostMapping
    public ApiResponse<Map<String, Long>> add(@AuthenticationPrincipal UserPrincipal me,
                                              @Valid @RequestBody CreateRecordRequest req) {
        Long id = records.add(me.userId(), req.time(), req.note());
        return ApiResponse.ok(Map.of("id", id));
    }

    @PutMapping("/{id}")
    public ApiResponse<Void> update(@AuthenticationPrincipal UserPrincipal me,
                                    @PathVariable Long id,
                                    @Valid @RequestBody UpdateRecordRequest req) {
        records.update(me.userId(), id, req.time(), req.note());
        return ApiResponse.ok(null);
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@AuthenticationPrincipal UserPrincipal me,
                                    @PathVariable Long id) {
        records.delete(me.userId(), id);
        return ApiResponse.ok(null);
    }

    @PostMapping("/sync")
    public ApiResponse<Map<String, Integer>> sync(@AuthenticationPrincipal UserPrincipal me,
                                                  @RequestBody SyncRecordsRequest req) {
        int n = records.sync(me.userId(), req.records());
        return ApiResponse.ok(Map.of("count", n));
    }
}
