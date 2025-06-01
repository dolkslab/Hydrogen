const std = @import("std");

const settings = struct {
    const tickcount_type = u32;
    const max_delay: tickcount_type = std.math.maxInt(tickcount_type);
};

var tickcount: settings.tickcount_type = 0;

pub fn increment_ticks() bool {
    const const_ticks = tickcount + 1;

    tickcount = const_ticks;

    // rollover detection?

}
