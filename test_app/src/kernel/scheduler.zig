const std = @import("std");
const hydrogen_options = @import("kernel.zig").hydrogen_options;
const Task = @import("task.zig");
const microzig = @import("microzig");
const SchedulerList = @import("SchedulerList.zig");
const port = @import("port.zig");

var n_tasks: u32 = 0;

/// stack buffer and task buffer
var stacks: [hydrogen_options.max_n_tasks][256]usize align(8) = undefined;
var task_buffer: [@sizeOf(Task) * hydrogen_options.max_n_tasks]u8 align(@alignOf(Task)) = undefined;
var task_allocator: std.heap.FixedBufferAllocator = undefined;

/// special spot for the idle task only
var default_idle_task_stack: [32]usize align(8) = undefined;
var default_idle_task: Task = undefined;

var ready_queue: SchedulerList = .{};
var delayed_queue: SchedulerList = .{};

// The current active task. may have to move this to port
pub var current_task: *Task = undefined;

pub fn init() void {
    task_allocator = std.heap.FixedBufferAllocator.init(&task_buffer);

    default_idle_task = Task.init(idle_task_fn, hydrogen_options.lowest_priority() + 1, &default_idle_task_stack);

    enqueue_ready_task(&default_idle_task);
}

fn enqueue_ready_task(task: *Task) void {
    task.sched_list_item = .{ .value = .{ .priority = task.base_priority } };
    task.state = @enumFromInt(1);

    ready_queue.insertAfterPriority(Task.SchedulerListItem, &task.sched_list_item, Task.SchedulerListItem.compare);
}

fn enqueue_delayed_task(task: *Task, delay_ticks: hydrogen_options.tickcount_type) void {
    task.sched_list_item = .{ .value = .{ .ticks = delay_ticks } };

    task.state = .BLOCKED;
    delayed_queue.insertAfterPriority(Task.SchedulerListItem, &task.sched_list_item, Task.SchedulerListItem.compare);
}

pub fn create_ready_task(main_entry: Task.MainEntry, base_priority: hydrogen_options.priority_type) !void {
    const new_task = try task_allocator.allocator().create(Task);
    new_task.* = Task.init(main_entry, base_priority, &stacks[n_tasks]);

    enqueue_ready_task(new_task);

    n_tasks += 1;
}

pub fn start_first_task() void {
    std.debug.assert(!ready_queue.is_empty());

    current_task = get_next_ready_task() orelse @panic("Create a task you lazy bum");
    _ = ready_queue.popFirst();
    current_task.state = @enumFromInt(1);

    port.jump_to_first_task();
}

/// Returns the highest priority ready task in the queue or returns null when there are no ready tasks.
/// Does NOT pop the task from the queue. this has to be done afterwards if switching.
pub fn get_next_ready_task() ?*Task {
    const first_ready_node = ready_queue.first orelse return null;

    const item: *Task.SchedulerListItem = @alignCast(@fieldParentPtr("node", first_ready_node));

    const ret: *Task = @fieldParentPtr("sched_list_item", item);
    return ret;
}

pub fn get_current_task() *const Task {
    return current_task;
}

// has to be export since we link into this from inline asm
export fn switch_current_task() void {
    if (@intFromEnum(current_task.state) > 0) {
        enqueue_ready_task(current_task);
    }

    if (get_next_ready_task()) |next_ready_task| {
        _ = ready_queue.popFirst();

        current_task = next_ready_task;
        current_task.state = @enumFromInt(1);
    } else {
        @panic("SHITTT");
    }
}

var tickcount: hydrogen_options.tickcount_type = 0;
var tick_rollovers: u32 = 0;

const led = microzig.hal.gpio.num(25);
pub fn tick() bool {
    const const_ticks = tickcount + 1;

    var switch_required = false;
    var it: ?*SchedulerList.Node = delayed_queue.first;
    while (it) |n| {
        const existing_item: *Task.SchedulerListItem = @alignCast(@fieldParentPtr("node", n));

        if (const_ticks >= existing_item.value.ticks) {
            // move the task to the ready queue, popping it from the delayed list.
            const task: *Task = @fieldParentPtr("sched_list_item", existing_item);
            _ = delayed_queue.popFirst();
            enqueue_ready_task(task);

            switch_required = true;
        } else {
            break;
        }

        it = n.next;
    }

    tickcount = const_ticks;

    return switch_required;
}

pub fn yield() void {
    port.pend_context_switch();
    microzig.cpu.dsb();
    microzig.cpu.isb();
}

pub fn delay(ticks: hydrogen_options.tickcount_type) void {
    {
        // enter critical section
        const cs = microzig.interrupt.enter_critical_section();
        defer cs.leave();
        enqueue_delayed_task(current_task, tickcount + ticks);
    }
    yield();

    return;
}

fn idle_task_fn() i32 {
    //@breakpoint();
    var a: u32 = 0;
    while (true) {
        a +%= 1;
        asm volatile ("nop");
    }
}
