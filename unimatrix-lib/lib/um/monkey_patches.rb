class Time
    def truncate resolution
        t = to_a
        case resolution
        when :min
            t[0] = 0
        when :hour
            t[0] = t[1] = 0
        when :day
            t[0] = t[1] = 0
            t[2] = 1
        when :month
            t[0] = t[1] = 0
            t[2] = t[3] = 1
        when :week
            t[0] = t[1] = 0
            t[2] = 1
            t[3] -= t[6] - 1
        when :year
            t[0] = t[1] = 0
            t[2] = t[3] = t[4] = 1
        end

        Time.local *t
    end
end
