package com.cle2333.flightattendance.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.util.Objects;

/**
 * 用户设置。一对一映射到 users 表。
 */
@Entity
@Table(name = "settings")
public class Settings {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "precision_setting", nullable = false, length = 20)
    private String precision = "second";

    @Column(nullable = false, length = 20)
    private String effect = "plane";

    @Column(nullable = false, length = 20)
    private String theme = "dark";

    @Column(name = "effect_emoji", nullable = false, length = 20)
    private String effectEmoji = "✈️";

    @Column(columnDefinition = "TEXT")
    private String quotes;

    public Settings() {
    }

    public Settings(Long userId) {
        this.userId = userId;
    }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getPrecision() { return precision; }
    public void setPrecision(String precision) { this.precision = precision; }

    public String getEffect() { return effect; }
    public void setEffect(String effect) { this.effect = effect; }

    public String getTheme() { return theme; }
    public void setTheme(String theme) { this.theme = theme; }

    public String getEffectEmoji() { return effectEmoji; }
    public void setEffectEmoji(String effectEmoji) { this.effectEmoji = effectEmoji; }

    public String getQuotes() { return quotes; }
    public void setQuotes(String quotes) { this.quotes = quotes; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Settings that)) return false;
        return Objects.equals(userId, that.userId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId);
    }
}
