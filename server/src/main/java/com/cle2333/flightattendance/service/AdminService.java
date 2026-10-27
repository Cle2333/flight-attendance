package com.cle2333.flightattendance.service;

import com.cle2333.flightattendance.dto.AdminStats;
import com.cle2333.flightattendance.dto.LeaderboardEntry;
import com.cle2333.flightattendance.dto.RecordDto;
import com.cle2333.flightattendance.dto.UserDto;
import com.cle2333.flightattendance.entity.Record;
import com.cle2333.flightattendance.entity.User;
import com.cle2333.flightattendance.exception.ApiException;
import com.cle2333.flightattendance.repository.LeaderboardRepository;
import com.cle2333.flightattendance.repository.RecordRepository;
import com.cle2333.flightattendance.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class AdminService {

    private final UserRepository users;
    private final RecordRepository records;
    private final LeaderboardRepository stats;

    public AdminService(UserRepository users, RecordRepository records, LeaderboardRepository stats) {
        this.users = users;
        this.records = records;
        this.stats = stats;
    }

    @Transactional(readOnly = true)
    public List<UserDto> listUsers() {
        return users.findAll().stream().map(UserDto::from).toList();
    }

    @Transactional
    public void deleteUser(Long id) {
        if (!users.existsById(id)) {
            throw new ApiException("用户不存在", HttpStatus.NOT_FOUND);
        }
        // ON DELETE CASCADE 会清掉 records / settings
        users.deleteById(id);
    }

    @Transactional(readOnly = true)
    public List<LeaderboardEntry> leaderboard(String type) {
        Instant from = null;
        if ("week".equalsIgnoreCase(type)) {
            from = Instant.now().minus(7, ChronoUnit.DAYS);
        }
        return stats.leaderboard(from);
    }

    @Transactional(readOnly = true)
    public UserDetail getUserDetail(Long id) {
        User u = users.findById(id)
                .orElseThrow(() -> new ApiException("用户不存在", HttpStatus.NOT_FOUND));
        List<RecordDto> rs = records.findByUserIdOrderByTimeAsc(id)
                .stream().map(RecordDto::from).toList();
        return new UserDetail(UserDto.from(u), rs);
    }

    @Transactional(readOnly = true)
    public AdminStats stats() {
        return new AdminStats(
                stats.countAllUsers(),
                stats.countAllRecords(),
                stats.countTodayRecords()
        );
    }

    public record UserDetail(UserDto user, List<RecordDto> records) {
    }
}
