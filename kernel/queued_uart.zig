const std = @import("std");
const zig_lpc = @import("zig-lpc");
const chip = zig_lpc.chip;
const cpu = @import("zig-lpc").cpu;
const interrupt = zig_lpc.interrupt;
const hal = zig_lpc.hal;

pub const QueuedUart = struct {
    uart: *Uart,
    tx_stream: zig_lpc.util.AtomicStream,
    rx_stream: zig_lpc.util.AtomicStream,

    pub const Writer = std.io.GenericWriter(*QueuedUart, Error, generic_writer_fn);
    pub const Reader = std.io.GenericReader(*QueuedUart, Error, generic_reader_fn);

    pub fn writer(self: *QueuedUart) Writer {
        return .{ .context = self };
    }

    pub fn reader(self: *QueuedUart) Reader {
        return .{ .context = self };
    }

    fn writer_callback(opt_context: ?*QueuedUart) u8 {
        var self = opt_context orelse unreachable;
        if (self.tx_stream.read()) |value| {
            if (self.tx_stream.is_empty()) {
                self.uart.interrupt_transmit_end();
            }
            return value;
        } else |_| {
            self.uart.interrupt_transmit_end();
            return 0;
        }
    }

    fn reader_callback(opt_context: ?*QueuedUart, err_data: hal.uart.RecieveError!u8) void {
        var self = opt_context orelse unreachable;
        // just ignore errors for now and return if there is one.
        const data = err_data catch return;

        // same thing here, if we cant push we just continue and
        // hope that by next time some data is freed up.
        // Could potentially be changed such that it stops the interrupt for reading.

        self.rx_stream.write(data) catch return;
    }

    pub fn start_listening(self: *QueuedUart) void {
        self.uart.interrupt_recieve_start(hal.uart.ReaderCallback.create(
            QueuedUart,
            reader_callback,
            self,
        ));
    }

    pub fn available_space(self: *const QueuedUart) usize {
        return self.tx_stream.available_space();
    }

    pub fn available_data(self: *const QueuedUart) usize {
        return self.rx_stream.len();
    }

    pub fn read_byte(self: *QueuedUart) Error!u8 {
        return self.rx_stream.read();
    }

    pub fn read_slice(self: *QueuedUart, buffer: []u8) Error!void {
        return self.rx_stream.read_slice(buffer);
    }

    /// Backing function for GenericReader. Can read less than the size of the passed
    /// buffer, if there are less bytes available to read. Returns this amount.
    /// Can return zero, this is not an error condition
    pub fn generic_reader_fn(self: *QueuedUart, buffer: []u8) Error!usize {
        const bytes_read: usize = @min(buffer.len, self.rx_stream.len());
        try self.rx_stream.read_slice(buffer[0..bytes_read]);
        return bytes_read;
    }

    pub fn peek_last(self: *QueuedUart) Error!u8 {
        return self.rx_stream.peek_last();
    }

    pub fn write_byte(self: *QueuedUart, data: u8) Error!void {
        return self.tx_stream.write(data);
    }

    pub fn write_slice(self: *QueuedUart, buffer: []const u8) Error!void {
        try self.tx_stream.write_slice(buffer);

        if (!self.uart.is_interrupt_transmit_in_progress()) {
            self.uart.interrupt_transmit_start(hal.uart.WriterCallback.create(
                QueuedUart,
                writer_callback,
                self,
            ));
        }
    }

    /// Backing function for GenericWriter. Can write less than the passed buffer size,
    /// depending on the space avialable in the write stream.
    pub fn generic_writer_fn(self: *QueuedUart, buffer: []const u8) Error!usize {
        const bytes_written: usize = @min(buffer.len, self.tx_stream.available_space());
        try self.write_slice(buffer[0..bytes_written]);
        return bytes_written;
    }

    pub const Error = zig_lpc.util.AtomicStream.Error;
};

pub fn create(uart: *Uart, tx_buffer: []u8, rx_buffer: []u8) QueuedUart {
    return QueuedUart{
        .uart = uart,
        .tx_stream = zig_lpc.util.AtomicStream.init(tx_buffer),
        .rx_stream = zig_lpc.util.AtomicStream.init(rx_buffer),
    };
}

const Uart = hal.uart.Uart;
