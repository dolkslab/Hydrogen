const std = @import("std");
const microzig = @import("microzig");
const app = @import("../app.zig");

// we will do this in the jankhui way for now

pub const Options = struct {
    tickcount_type: type = u32,

    priority_type: type = i16,

    max_n_tasks: comptime_int = 10,

    max_delay: ?comptime_int = null,

    n_task_notifications: comptime_int = 2,

    pub fn lowest_priority(options: *const Options) comptime_int {
        return std.math.maxInt(options.priority_type) - 1;
    }

    pub fn highest_priority(options: *const Options) comptime_int {
        return std.math.minInt(options.priority_type);
    }

    pub fn get_max_delay(options: *const Options) comptime_int {
        if (options.max_delay) |max_delay| {
            return max_delay;
        } else {
            return std.math.maxInt(options.tickcount_type);
        }
    }
};

pub const hydrogen_options: Options = if (@hasDecl(app, "hydrogen_options")) app.hydrogen_options else .{};

pub const scheduler = @import("scheduler.zig");
pub const Task = @import("task.zig");
pub const port = @import("port.zig");

const hal = microzig.hal;
const led = hal.gpio.num(25);

pub fn init() void {
    scheduler.init();
}

/// Start the kernel.
/// Will require certain start conditions.
/// Clocks setup, any hardware for basic operation.
/// Priveleged mode, SP = MSP.
pub fn start() void {

    // zig_lpc.cpu.peripherals.SCB.SHCSR.modify(.{
    //     .MEMFAULTENA = .{ .raw = 1 },
    //     .BUSFAULTENA = .{ .raw = 1 },
    //     .USGFAULTENA = .{ .raw = 1 },
    // });

    microzig.chip.peripherals.PPB.FPCCR.modify(.{ .LSPACT = 1 });

    // the FPU should be enabled just before starting the first task.

    if (microzig.cpu.fpu.present) {
        microzig.cpu.fpu.enable_full();
    }

    microzig.cpu.interrupt.exception.set_priority(.PendSV, .lowest);
    microzig.cpu.interrupt.exception.set_priority(.SVCall, .lowest);
    microzig.cpu.interrupt.exception.set_priority(.SysTick, @enumFromInt(1));

    microzig.cpu.interrupt.enable_interrupts();
    port.start_systick();
    scheduler.start_first_task();
}
