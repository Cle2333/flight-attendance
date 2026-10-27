package com.cle2333.flightattendance.dto;

import com.cle2333.flightattendance.entity.Record;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;

public record RecordDto(Long id,
                        @JsonProperty("user_id") Long userId,
                        Instant time,
                        String note,
                        @JsonProperty("created_at") Instant createdAt) {
    public static RecordDto from(Record r) {
        return new RecordDto(r.getId(), r.getUserId(), r.getTime(), r.getNote(), r.getCreatedAt());
    }
}
