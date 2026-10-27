package com.cle2333.flightattendance.security;

import com.cle2333.flightattendance.entity.User;

import java.io.Serializable;

public record UserPrincipal(Long userId, String account, String role) implements Serializable {

    public static UserPrincipal from(User u) {
        return new UserPrincipal(u.getId(), u.getAccount(), u.getRole());
    }
}
