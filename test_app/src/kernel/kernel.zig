const std = @import("std");
const microzig = @import("microzig");

// we will do this in the jankhui way for now

const Options = struct {
    tickcount_type: type = u32,
    max_delay: Options.tickcount_type = std.math.maxInt(Options.tickcount_type),
    priority_type: type = i16,

    pub const min_priority = std.math.maxInt(Options.tickcount_type) - 1;
};

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
    microzig.cpu.interrupt.enable_interrupts();
    port.start_systick();
    scheduler.start_first_task();
}
