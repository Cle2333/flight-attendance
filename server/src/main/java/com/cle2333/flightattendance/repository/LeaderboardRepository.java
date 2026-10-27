package com.cle2333.flightattendance.repository;

import com.cle2333.flightattendance.dto.LeaderboardEntry;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;

/**
 * 排行榜 / 统计的复杂 SQL 走 JdbcTemplate，避免 JPA 投影的麻烦
 */
@Repository
public class LeaderboardRepository {

    private final JdbcTemplate jdbc;

    public LeaderboardRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<LeaderboardEntry> leaderboard(Instant fromOrNull) {
        String sql = """
                SELECT u.id            AS id,
                       u.account       AS username,
                       u.nickname      AS nickname,
                       COALESCE(u.avatar, '✈️') AS avatar,
                       COUNT(r.id)     AS cnt
                  FROM users u
             LEFT JOIN records r ON r.user_id = u.id
                                   AND (? IS NULL OR r.`time` >= ?)
              GROUP BY u.id, u.account, u.nickname, u.avatar
              ORDER BY cnt DESC
                """;
        Timestamp ts = fromOrNull == null ? null : Timestamp.from(fromOrNull);
        return jdbc.query(sql, (rs, n) -> new LeaderboardEntry(
                        rs.getLong("id"),
                        rs.getString("username"),
                        rs.getString("nickname"),
                        rs.getString("avatar"),
                        rs.getLong("cnt")),
                ts, ts);
    }

    public long countAllUsers() {
        Long c = jdbc.queryForObject("SELECT COUNT(*) FROM users", Long.class);
        return c == null ? 0L : c;
    }

    public long countAllRecords() {
        Long c = jdbc.queryForObject("SELECT COUNT(*) FROM records", Long.class);
        return c == null ? 0L : c;
    }

    public long countTodayRecords() {
        Long c = jdbc.queryForObject(
                "SELECT COUNT(*) FROM records WHERE DATE(`time`) = CURDATE()",
                Long.class);
        return c == null ? 0L : c;
    }
}
