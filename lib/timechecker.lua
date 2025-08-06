local TimeChecker = Object:extend("TimeChecker")

local CHUNK_DURATION_SECONDS = 5 * 60
local MAX_CHUNKS = 60 / (CHUNK_DURATION_SECONDS / 60)

function TimeChecker:new()
    self:init()
end

function TimeChecker:start()
    self:init()
    self.started = true
end

function TimeChecker:init()
    self.fps = 60
    self.fps_samples = 1
    self.slowdown_detection_time = nil
    self.slowdown_detection_time_samples = 0

    self.ready_to_measure_os_time = false

    self.last_slowdown_detection_time = love.timer.get_time()
    self.last_slowdown_detection_time_os = os.time()

    -- rolling window chunk tracking
    self.current_chunk_ratio_sum = 0
    self.current_chunk_samples = 0
    self.chunks = {}
    self.chunk_duration = CHUNK_DURATION_SECONDS
    self.max_chunks = MAX_CHUNKS
    self.current_chunk_start_os = self.last_slowdown_detection_time_os

    -- permanent tracking of extreme chunk averages
    self.min_chunk_average = nil
    self.max_chunk_average = nil

    -- initialize FPS chunk tracking
    self.current_chunk_fps_sum = 0
    self.current_chunk_fps_samples = 0
    self.fps_chunks = {}
    self.min_fps_chunk_average = nil
    self.elapsed = 0
end

function TimeChecker:stop()
    self.started = false
end

local TIME_SAMPLE_INTERVAL = 10

function TimeChecker:update(dt)

    dt = seconds_to_frames(dt)

    self.elapsed = self.elapsed + dt

    if not self.started then
        return
    end
    
    local time = love.timer.get_time()
    local os_time = os.time()
    if not (self.last_slowdown_detection_time and self.last_slowdown_detection_time_os) then

        self.last_slowdown_detection_time = time
        self.last_slowdown_detection_time_os = os_time
    else

        local current_fps = love.timer.get_fps()
        self.fps_samples = self.fps_samples + 1
        self.fps = self.fps + current_fps

        self.current_chunk_fps_sum = self.current_chunk_fps_sum + current_fps
        self.current_chunk_fps_samples = self.current_chunk_fps_samples + 1


        if os_time - self.last_slowdown_detection_time_os > 0 then
            if not self.ready_to_measure_os_time then
                self.ready_to_measure_os_time = true
            else
                local ratio = (time - self.last_slowdown_detection_time) /
                (os_time - self.last_slowdown_detection_time_os)

                -- accumulate totals across the rolling window
                if self.slowdown_detection_time then
                    self.slowdown_detection_time = self.slowdown_detection_time + ratio
                else
                    self.slowdown_detection_time = ratio
                end
                self.slowdown_detection_time_samples = self.slowdown_detection_time_samples + 1

                -- accumulate current chunk statistics
                self.current_chunk_ratio_sum = self.current_chunk_ratio_sum + ratio
                self.current_chunk_samples = self.current_chunk_samples + 1
            end

            self.last_slowdown_detection_time = time
            self.last_slowdown_detection_time_os = os_time
        end

        -- check if we should roll the chunk window (independent of game speed measurement)
        if os_time - self.current_chunk_start_os >= self.chunk_duration then
            -- calculate the chunk average before storing
            local chunk_average = self.current_chunk_samples > 0 and (self.current_chunk_ratio_sum / self.current_chunk_samples) or 1
            
            -- update permanent extremes for game speed
            if self.min_chunk_average == nil or chunk_average < self.min_chunk_average then
                self.min_chunk_average = chunk_average
            end
            if self.max_chunk_average == nil or chunk_average > self.max_chunk_average then
                self.max_chunk_average = chunk_average
            end

            -- calculate FPS chunk average and update extremes
            local fps_chunk_average = self.current_chunk_fps_samples > 0 and (self.current_chunk_fps_sum / self.current_chunk_fps_samples) or 60
            
            
            if self.min_fps_chunk_average == nil or fps_chunk_average < self.min_fps_chunk_average then
                self.min_fps_chunk_average = fps_chunk_average
            end

            table.insert(self.chunks, {ratio_sum = self.current_chunk_ratio_sum, samples = self.current_chunk_samples})
            table.insert(self.fps_chunks, {fps_sum = self.current_chunk_fps_sum, samples = self.current_chunk_fps_samples})

            if #self.chunks > self.max_chunks then
                local removed = table.remove(self.chunks, 1)
                self.slowdown_detection_time = self.slowdown_detection_time - removed.ratio_sum
                self.slowdown_detection_time_samples = self.slowdown_detection_time_samples - removed.samples
                if self.slowdown_detection_time_samples == 0 then
                    self.slowdown_detection_time = nil
                end
            end

            if #self.fps_chunks > self.max_chunks then
                local removed_fps = table.remove(self.fps_chunks, 1)
                self.fps = self.fps - removed_fps.fps_sum
                self.fps_samples = self.fps_samples - removed_fps.samples
                if self.fps_samples == 0 then
                    self.fps = love.timer.get_fps()
                    self.fps_samples = 1
                end
            end

            -- reset current chunk data
            self.current_chunk_ratio_sum = 0
            self.current_chunk_samples = 0
            self.current_chunk_fps_sum = 0
            self.current_chunk_fps_samples = 0
            self.current_chunk_start_os = os_time
        end
    end
end

function TimeChecker:get_average_fps()
    return self.fps / self.fps_samples
end

function TimeChecker:get_relative_game_speed()
    if not self.slowdown_detection_time or self.slowdown_detection_time_samples == 0 then
        return 1
    end
    return self.slowdown_detection_time / self.slowdown_detection_time_samples
end

function TimeChecker:get_relative_game_speed_bounds()
    if self.min_chunk_average == nil or self.max_chunk_average == nil then
        return 1, 1
    end
    return self.min_chunk_average, self.max_chunk_average
end

function TimeChecker:get_average_fps_bound()
    if self.min_fps_chunk_average == nil then
        return 60
    end
    return self.min_fps_chunk_average
end

function TimeChecker:should_warn()
    if not self.started then
        return false
    end

    if self.elapsed < 600 then
        return false
    end
    local relative_game_speed = self:get_relative_game_speed()
    return relative_game_speed < conf.leaderboard_minimum_game_speed or relative_game_speed > conf.leaderboard_maximum_game_speed or self:get_average_fps() < conf.leaderboard_minimum_fps
    -- return relative_game_speed < conf.leaderboard_minimum_game_speed or relative_game_speed > conf.leaderboard_maximum_game_speed
end

function TimeChecker:is_valid_game_speed_for_leaderboard()
    local min_speed, max_speed = self:get_relative_game_speed_bounds()
    
    if min_speed < conf.leaderboard_minimum_game_speed or max_speed > conf.leaderboard_maximum_game_speed then
        return false
    end
    
    local min_fps = self:get_average_fps_bound()
    if min_fps < conf.leaderboard_minimum_fps then
        return false
    end

    return true
end

return TimeChecker
