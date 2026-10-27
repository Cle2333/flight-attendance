package com.cle2333.flightattendance.repository;

import com.cle2333.flightattendance.entity.Record;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface RecordRepository extends JpaRepository<Record, Long> {

    List<Record> findByUserIdOrderByTimeAsc(Long userId);

    List<Record> findByUserIdAndTimeGreaterThanEqualOrderByTimeAsc(Long userId, Instant from);

    long countByTimeGreaterThanEqual(Instant from);

    long deleteByUserIdAndId(Long userId, Long id);

    @Modifying
    @Query("DELETE FROM Record r WHERE r.userId = :userId")
    void deleteAllByUserId(@Param("userId") Long userId);
}
