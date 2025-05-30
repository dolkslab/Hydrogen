const std = @import("std");
const microzig = @import("microzig");

pub const Scheduler = @import("scheduler.zig");
pub const Task = @import("task.zig");
const hal = microzig.hal;
const led = hal.gpio.num(25);

pub const KERNEL_MAX_TASKS = 20;

var task_queue_buffer: [@sizeOf(Scheduler.Queue) * KERNEL_MAX_TASKS]u8 = undefined;
var stacks: [2][1024]usize align(8) = undefined;

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

    const idle_task = Task.init(idle_task_fn, &stacks[0], std.math.minInt(i16));

    var task_queue_allocator = std.heap.FixedBufferAllocator.init(&task_queue_buffer);
    Scheduler.init_queue(task_queue_allocator.allocator(), idle_task);

    const other_task = Task.init(other_task_fn, &stacks[1], 1);
    Scheduler.temp_shit[1] = other_task;

    // the FPU should be enabled just before starting the first task.
    microzig.cpu.fpu.enable_full();
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
            microzig.cpu.interrupt.exception.set_pending(.PendSV);
        }
    }
}
