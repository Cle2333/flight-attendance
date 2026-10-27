package com.cle2333.flightattendance.exception;

import org.springframework.http.HttpStatus;

/**
 * 业务异常 —— controller 直接抛，会被 GlobalExceptionHandler 序列化成 {success:false, message:...}
 */
public class ApiException extends RuntimeException {

    private final HttpStatus status;

    public ApiException(String message) {
        this(message, HttpStatus.BAD_REQUEST);
    }

    public ApiException(String message, HttpStatus status) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}
