const std = @import("std");
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const time = rp2xxx.time;
const peripherals = microzig.chip.peripherals;
const interrupt = microzig.cpu.interrupt;

const kernel = @import("kernel/kernel.zig");

const led = rp2xxx.gpio.num(25);
const uart = rp2xxx.uart.instance.num(0);
const baud_rate = 115200;
const uart_tx_pin = rp2xxx.gpio.num(0);

const chip = rp2xxx.compatibility.chip;

// const timer = if (chip == .RP2040) peripherals.TIMER else peripherals.TIMER0;
// const timer_irq = if (chip == .RP2040) .TIMER_IRQ_0 else .TIMER0_IRQ_0;

pub const microzig_options: microzig.Options = .{
    .log_level = .debug,
    .logFn = rp2xxx.uart.logFn,
    .interrupts = .{
        .PendSV = .{ .naked = kernel.port.pendsv_isr },
        .SVCall = .{ .c = kernel.port.svcall_isr },
        .SysTick = .{ .c = kernel.port.systick_isr },
    },
};

pub const hydrogen_options: kernel.Options = .{
    .tickcount_type = u32,
};

pub fn main() !void {
    // init uart logging
    uart_tx_pin.set_function(.uart);
    uart.apply(.{
        .baud_rate = baud_rate,
        .clock_config = rp2xxx.clock_config,
    });
    rp2xxx.uart.init_logger(uart);
    kernel.init();

    try kernel.scheduler.create_ready_task(blink_task_fn, 0);
    try kernel.scheduler.create_ready_task(blink_task_fn_2, 1);

    kernel.start();

    //led.set_function(.sio);

    while (true) {
        asm volatile ("wfi");
    }
}

fn blink_task_fn() i32 {
    var a: u32 = 0;
    var f: f32 = 1.5;
    led.set_function(.sio);
    led.set_direction(.out);
    led.put(0);
    while (true) {
        a +%= 1;
        f += 0.1;

        asm volatile ("nop");
        kernel.scheduler.delay(777);
        led.toggle();
    }

    return 0;
}

fn blink_task_fn_2() i32 {
    var a: u32 = 0;
    var f: f32 = 1.5;
    led.set_function(.sio);
    led.set_direction(.out);
    led.put(0);

    while (true) {
        a +%= 1;
        f += 0.1;

        asm volatile ("nop");
        kernel.scheduler.delay(1000);
        led.toggle();
    }

    return 0;
}
