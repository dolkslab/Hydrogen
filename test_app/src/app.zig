const std = @import("std");
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const time = rp2xxx.time;
const peripherals = microzig.chip.peripherals;
const interrupt = microzig.cpu.interrupt;

const led = rp2xxx.gpio.num(25);
const uart = rp2xxx.uart.instance.num(0);
const baud_rate = 115200;
const uart_tx_pin = rp2xxx.gpio.num(0);

const chip = rp2xxx.compatibility.chip;

const timer = if (chip == .RP2040) peripherals.TIMER else peripherals.TIMER0;
const timer_irq = if (chip == .RP2040) .TIMER_IRQ_0 else .TIMER0_IRQ_0;

pub const rp2040_options: microzig.Options = .{
    .log_level = .debug,
    .logFn = rp2xxx.uart.logFn,
    .interrupts = .{ .TIMER_IRQ_0 = .{ .c = timer_interrupt } },
};

pub const rp2350_options: microzig.Options = .{
    .log_level = .debug,
    .logFn = rp2xxx.uart.logFn,
    .interrupts = .{ .TIMER0_IRQ_0 = .{ .naked = timer_interrupt } },
};

pub const microzig_options = if (chip == .RP2040) rp2040_options else rp2350_options;

var balls: usize = 0;
var current_task: *usize = &balls;
export fn switch_current_task() void {
    current_task = &balls;
}

fn timer_interrupt() callconv(.naked) void {
    asm volatile (
        \\
        // Store the context to the stack that was not saved on exception entry.
        // Test for bit 4 in the LR to check if FPU was active, if so, save its context (expensive!)
        \\ mrs          r0, psp
        \\ tst          r14, 0x10 
        \\ it           eq
        \\ vstmdbeq     r0!, {s16-s31}
        \\ stmdb        r0!, {r4-r11, r14}
        \\
        // Obtain the active task by dereferencing r2.
        // when we deref it again this gives the SP location.
        \\ ldr          r1,  [r2] 
        \\ str          r0, [r1]
        \\ 
        // Save the relevant context for this function, which is only R2
        // Raise the basepri for some reason
        \\ stmdb        sp!, {r2}
        \\ mov          r1, %[max_prio_lvl]
        \\ msr          basepri, r1
        \\ isb
        \\
        // Branch to the switch_current_task function which will repopulate current_task with the new
        // task to execute.
        \\ bl           switch_current_task
        \\
        // Reset the basepri to 0
        \\ mov          r0, #0
        \\ msr          basepri, r0 
        \\
        // Restore R2, deref it into r1, this now has the new active task.
        \\ ldmia        sp!, {r2}
        \\ ldr          r1, [r2]
        \\ ldr          r0, [r1]
        \\
        // Now execute the context saving in reverse, pop registers from the stack
        \\ ldmia        r0!, {r4-r11, r14}
        \\ tst          r14, #0x10
        \\ it           eq
        \\ vldmiaeq     r0!, {s16-s31}
        \\
        \\ msr          psp, r0
        \\ isb
        // The psp now holds the stack frame of the new task as if it was just interrupted.
        // R14 holds the execution mode for this task. BX exits the handler.
        \\ bx           r14
        : //outputs
        : [current_task_ptr] "{r2}" (&current_task),
          [max_prio_lvl] "i" (0),
    );
}

pub fn set_alarm(us: u32) void {
    const Duration = microzig.drivers.time.Duration;
    const current = time.get_time_since_boot();
    const target = current.add_duration(Duration.from_us(us));

    timer.ALARM0.write_raw(@intCast(@intFromEnum(target) & 0xffffffff));
}

pub fn main() !void {
    // init uart logging
    uart_tx_pin.set_function(.uart);
    uart.apply(.{
        .baud_rate = baud_rate,
        .clock_config = rp2xxx.clock_config,
    });
    rp2xxx.uart.init_logger(uart);

    led.set_function(.sio);
    led.set_direction(.out);

    set_alarm(1_000_000);

    timer.INTE.toggle(.{ .ALARM_0 = 1 });

    interrupt.enable(timer_irq);

    // Enable machine external interrupts on RISC-V
    if (rp2xxx.compatibility.arch == .riscv) {
        microzig.cpu.interrupt.core.enable(.MachineExternal);
    }

    microzig.cpu.interrupt.enable_interrupts();

    while (true) {
        asm volatile ("wfi");
    }
}
