CREATE TABLE IF NOT EXISTS `ft_weathersystem` (
    `id` INT(11) NOT NULL DEFAULT 1,
    `weather` VARCHAR(50) NOT NULL DEFAULT 'EXTRASUNNY',
    `time_seconds` INT(11) NOT NULL DEFAULT 28800,
    `freeze_time` TINYINT(1) NOT NULL DEFAULT 0,
    `blackout` TINYINT(1) NOT NULL DEFAULT 0,
    `dynamic_weather` TINYINT(1) NOT NULL DEFAULT 1,
    `weather_interval` INT(11) NOT NULL DEFAULT 10,
    `time_speed` INT(11) NOT NULL DEFAULT 1,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ft_weathersystem` (`id`, `weather`, `time_seconds`, `freeze_time`, `blackout`, `dynamic_weather`, `weather_interval`, `time_speed`)
VALUES (1, 'EXTRASUNNY', 28800, 0, 0, 1, 10, 1);
