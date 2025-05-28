const std = @import("std");
const zig_lpc = @import("zig-lpc");

const Self = @This();

top_of_stack: [*]align(8) usize,
stack_size: usize,

main_entry: *const MainEntry,

state: State,

priority: Priority,

pub fn init(main_entry: *const MainEntry, stack_buf: []align(8) usize, base_priority: Priority) Self {
    var unaligned_stack: *usize = &stack_buf[stack_buf.len - 1];
    // terrible no good
    unaligned_stack = @ptrFromInt(@intFromPtr(unaligned_stack) & @as(usize, 0xFFFFFFF8));

    const aligned_top_of_stack: *align(8) usize = @alignCast(unaligned_stack);

    var new_task: Self = .{
        .top_of_stack = @ptrCast(aligned_top_of_stack),
        .stack_size = stack_buf.len,
        .main_entry = main_entry,
        .state = .READY,
        .priority = base_priority,
    };

    new_task.init_stack();
    return new_task;
}

/// Initialise the stack frame of this task to simulate exception entry
fn init_stack(self: *Self) void {
    // decrement the stack pointer first since the stack grows downwards
    self.top_of_stack -= BasicContext.Size / @sizeOf(usize) + 1;
    const initial_context: *BasicContext = (@ptrCast(self.top_of_stack));

    initial_context.return_state = .{
        .active_stack_pointer = .PSP,
        .exec_mode = .THREAD,
        .fpu_state = .INACTIVE,
    };

    initial_context.LR = @intFromPtr(&default_return);
    initial_context.return_adress = @intFromPtr(self.main_entry) & 0xFFFFFFFE;
    initial_context.xPSR = INITIAL_XPSR;
    initial_context.a1 = 1000;
    initial_context.a2 = 1001;
    initial_context.a3 = 1002;
    initial_context.a4 = 1003;
    initial_context.IP = 1012;
}

// POSIX style main entry argc: i32, argv: [][:0]u8.
pub const MainEntry = fn () i32;

pub const State = enum {
    READY,
    RUNNING,
    BLOCKED,
};

pub const Priority = i16;

//for now i will put this here

// pub const xPSRType = packed struct(usize) {
//     reserved8: u8 = 0,
//     padded_frame: bool,
//     reserved23: u23 = 0,
// };

pub const ReturnState = packed struct(usize) {
    _reserved2: u2 = 0b01,
    active_stack_pointer: enum(u1) {
        MSP = 0x0,
        PSP = 0x1,
    },
    exec_mode: enum(u1) { HANDLER = 0x0, THREAD = 0x1 },
    fpu_state: enum(u1) {
        ACTIVE = 0x0,
        INACTIVE = 0x1,
    },
    _reserved: u27 = std.math.maxInt(u27),
};

pub const BasicContext = packed struct(u544) {
    // remaining context to be saved
    v1: usize,
    v2: usize,
    v3: usize,
    v4: usize,
    v5: usize,
    v6: usize,
    v7: usize,
    v8: usize,
    return_state: ReturnState,

    // AAPCS frame
    a1: usize,
    a2: usize,
    a3: usize,
    a4: usize,
    IP: usize,
    LR: usize,
    return_adress: usize,
    xPSR: usize,
    const Size = 17 * 4;
};

pub const ExtendedContext = packed struct {
    // remaining context to be saved
    v1: usize,
    v2: usize,
    v3: usize,
    v4: usize,
    v5: usize,
    v6: usize,
    v7: usize,
    v8: usize,
    return_state: ReturnState,
    //remaining floating point registers
    FP_s2: [16]usize, //s16-31

    // AAPCS extended frame
    a1: usize,
    a2: usize,
    a3: usize,
    a4: usize,
    IP: usize,
    LR: usize,
    return_adress: usize,
    xPSR: usize,
    //extended floating point context
    FP_s: [16]usize, //s0-15
    FPSCR: usize,
    _reserved0: usize,
};

// set bit 24 of the XPSR to indicate thumb mode, other bits can be left zero
const INITIAL_XPSR: usize = 1 << 24;

//start initial task in thread mode, use PSP
const INITIAL_LR_EXC_RET: usize = 0xFFFFFFFD;

// this should not be here either
fn default_return() void {
    zig_lpc.halt(-31);
}
