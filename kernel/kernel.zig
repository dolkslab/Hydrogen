const std = @import("std");

const zig_lpc = @import("zig-lpc");
const Scheduler = @import("scheduler.zig");
const Task = @import("task.zig");
const hal = zig_lpc.hal;

const KERNEL_MAX_TASKS = 20;

var task_queue_buffer: [@sizeOf(Scheduler.Queue) * KERNEL_MAX_TASKS]u8 = undefined;
var stacks: [2][1024]usize align(8) = undefined;

/// Start the kernel.
/// Will require certain start conditions.
/// Clocks setup, any hardware for basic operation.
/// Priveleged mode, SP = MSP.
pub fn start() void {
    zig_lpc.cpu.peripherals.SCB.SHCSR.modify(.{
        .MEMFAULTENA = .{ .raw = 1 },
        .BUSFAULTENA = .{ .raw = 1 },
        .USGFAULTENA = .{ .raw = 1 },
    });

    zig_lpc.cpu.peripherals.SCB.FPCCR.modify(.{ .LSPACT = .{ .raw = 1 } });

    const idle_task = Task.init(idle_task_fn, &stacks[0], std.math.minInt(i16));

    var task_queue_allocator = std.heap.FixedBufferAllocator.init(&task_queue_buffer);
    Scheduler.init_queue(task_queue_allocator.allocator(), idle_task);

    const other_task = Task.init(other_task_fn, &stacks[1], 1);
    Scheduler.temp_shit[1] = other_task;

    // the FPU should be enabled just before starting the first task.
    hal.enable_fpu();
    Scheduler.start_first_task();
}

fn idle_task_fn() i32 {
    //@breakpoint();
    var a: u32 = 0;
    while (true) {
        a +%= 1;
        asm volatile ("nop");
        if (a % 10000 == 0) {
            asm volatile ("nop");
            zig_lpc.cpu.set_pendsv();
        }
    }
}

fn other_task_fn() i32 {
    var a: u32 = 0;
    while (true) {
        a += 1;
        asm volatile ("nop");
        if (a % 10000 == 0) {
            asm volatile ("nop");
            zig_lpc.cpu.set_pendsv();
        }
    }
}
