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

pub const rp2350_options: microzig.Options = .{
    .log_level = .debug,
    .logFn = rp2xxx.uart.logFn,
    .interrupts = .{
        .PendSV = .{ .naked = kernel.port.pendsv_isr },
        .SVCall = .{ .c = kernel.port.svcall_isr },
    },
};

pub const microzig_options = rp2350_options;

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
    led.toggle();
    microzig.cpu.interrupt.enable_interrupts();
    kernel.start();

    //led.set_function(.sio);

    while (true) {
        asm volatile ("wfi");
    }
}
