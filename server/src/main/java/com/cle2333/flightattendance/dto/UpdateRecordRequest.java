package com.cle2333.flightattendance.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateRecordRequest(@NotBlank String time, String note) {
}
