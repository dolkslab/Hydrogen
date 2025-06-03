const std = @import("std");

const SchedulerList = @import("SchedulerList.zig");
const port = @import("port.zig");

const hydrogen_options = @import("kernel.zig").hydrogen_options;

const Task = @This();
top_of_stack: port.Stack.StackPtr,
stack_size: usize,

main_entry: *const MainEntry,

state: State,
sched_list_item: SchedulerListItem,

base_priority: hydrogen_options.priority_type,

pub fn init(
    main_entry: *const MainEntry,
    base_priority: hydrogen_options.priority_type,
    stack_buf: []align(8) usize,
) Task {
    var unaligned_stack: *usize = &stack_buf[stack_buf.len - 1];
    // terrible no good
    unaligned_stack = @ptrFromInt(@intFromPtr(unaligned_stack) & @as(usize, 0xFFFFFFF8));

    const aligned_top_of_stack: *align(8) usize = @alignCast(unaligned_stack);

    var new_task: Task = .{
        .top_of_stack = @ptrCast(aligned_top_of_stack),
        .stack_size = stack_buf.len,
        .main_entry = main_entry,
        .state = .READY,
        .sched_list_item = undefined,
        .base_priority = base_priority,
    };

    port.Stack.init_stack(&new_task.top_of_stack, main_entry);

    return new_task;
}

// POSIX style main entry argc: i32, argv: [][:0]u8.
pub const MainEntry = fn () i32;

pub const State = enum(i32) {
    BLOCKED = -1,
    READY = 0,
    _,
};

pub const SchedulerListItem = struct {
    pub const ValueType = enum {
        ticks,
        priority,
    };

    value: union(ValueType) {
        ticks: hydrogen_options.tickcount_type,
        priority: hydrogen_options.priority_type,
    },

    node: SchedulerList.Node = .{ .prev = null, .next = null },

    pub fn compare(a: SchedulerListItem, b: SchedulerListItem) std.math.Order {
        // should probably assert the active tags are the same but eh
        return switch (a.value) {
            .ticks => std.math.order(a.value.ticks, b.value.ticks),
            .priority => std.math.order(a.value.priority, b.value.priority),
        };
    }
};
