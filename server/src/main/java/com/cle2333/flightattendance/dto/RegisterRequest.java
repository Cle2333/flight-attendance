package com.cle2333.flightattendance.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank
        @Size(min = 3, max = 20)
        @Pattern(regexp = "^[a-zA-Z0-9_]+$",
                 message = "只能包含字母、数字、下划线")
        String account,

        @NotBlank @Size(min = 6) String password,
        String nickname
) {
}
