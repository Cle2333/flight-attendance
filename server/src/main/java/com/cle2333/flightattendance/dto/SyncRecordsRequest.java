package com.cle2333.flightattendance.dto;

import jakarta.validation.constraints.NotNull;

import java.util.List;

public record SyncRecordsRequest(@NotNull List<SyncRecordItem> records) {
}
