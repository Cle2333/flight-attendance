package com.cle2333.flightattendance.service;

import com.cle2333.flightattendance.dto.SettingsDto;
import com.cle2333.flightattendance.dto.UpdateSettingsRequest;
import com.cle2333.flightattendance.entity.Settings;
import com.cle2333.flightattendance.repository.SettingsRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class SettingsService {

    private final SettingsRepository repo;
    private final ObjectMapper json = new ObjectMapper();

    public SettingsService(SettingsRepository repo) {
        this.repo = repo;
    }

    @Transactional(readOnly = true)
    public SettingsDto get(Long userId) {
        Settings s = repo.findById(userId).orElseGet(() -> {
            Settings fresh = new Settings(userId);
            repo.save(fresh);
            return fresh;
        });
        return SettingsDto.from(s);
    }

    @Transactional
    public void update(Long userId, UpdateSettingsRequest req) {
        Settings s = repo.findById(userId).orElseGet(() -> new Settings(userId));

        if (req.precision() != null) s.setPrecision(req.precision());
        if (req.effect() != null)    s.setEffect(req.effect());
        if (req.theme() != null)     s.setTheme(req.theme());
        if (req.effectEmoji() != null) s.setEffectEmoji(req.effectEmoji());

        if (req.quotes() != null) {
            s.setQuotes(serializeQuotes(req.quotes()));
        }
        repo.save(s);
    }

    private String serializeQuotes(List<String> quotes) {
        if (quotes == null) return null;
        try {
            return json.writeValueAsString(quotes);
        } catch (JsonProcessingException e) {
            return String.join("\\n", quotes);
        }
    }
}
