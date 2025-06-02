const std = @import("std");
const microzig = @import("microzig");

pub const Scheduler = @import("scheduler.zig");
pub const Task = @import("task.zig");
pub const port = @import("port.zig");

const hal = microzig.hal;
const led = hal.gpio.num(25);

/// Start the kernel.
/// Will require certain start conditions.
/// Clocks setup, any hardware for basic operation.
/// Priveleged mode, SP = MSP.
pub fn start() void {
    Scheduler.init();
    // zig_lpc.cpu.peripherals.SCB.SHCSR.modify(.{
    //     .MEMFAULTENA = .{ .raw = 1 },
    //     .BUSFAULTENA = .{ .raw = 1 },
    //     .USGFAULTENA = .{ .raw = 1 },
    // });

    microzig.chip.peripherals.PPB.FPCCR.modify(.{ .LSPACT = 1 });

    Scheduler.create_ready_task(idle_task_fn, -2) catch unreachable;
    Scheduler.create_ready_task(other_task_fn, 1) catch unreachable;

    // the FPU should be enabled just before starting the first task.
    microzig.cpu.fpu.enable_full();
    microzig.cpu.interrupt.enable_interrupts();
    Scheduler.start_first_task();
}

fn idle_task_fn() i32 {
    //@breakpoint();
    var a: u32 = 0;
    var f: f32 = 1.2;
    while (true) {
        a +%= 1;
        f += 0.2;
        asm volatile ("nop");
        if (a % 1000000 == 0) {
            asm volatile ("nop");
            led.put(0);
            microzig.cpu.interrupt.exception.set_pending(.PendSV);
        }
    }
}

fn other_task_fn() i32 {
    var a: u32 = 0;
    var f: f32 = 1.5;

    while (true) {
        a +%= 1;
        f += 0.1;
        asm volatile ("nop");
        if (a % 1000000 == 0) {
            led.put(1);
            asm volatile ("nop");
            // sort of a "yield" for now
            Scheduler.current_task.state = .READY;
            microzig.cpu.interrupt.exception.set_pending(.PendSV);
        }
    }
}
