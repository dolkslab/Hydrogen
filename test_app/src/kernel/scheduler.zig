const std = @import("std");
const Task = @import("task.zig");
const microzig = @import("microzig");
const SchedulerQueue = @import("SchedulerQueue.zig");
const port = @import("port.zig");

// so what we need for task queue list whatever
// ready task list. freertos uses an array of them matching the number of priorities configured
// delayed task list. freertos uses 2 of them, to deal with rollovers of the tick counter.
// it swaps them when there is a rollover. we can do the same or think of some other way to deal with this
// the delayed task list is essentially the blocked task list.
// by default all tasks are delayed for some time when they are blocked, with this delay being treated as a "timeout"
// it does also have suspended tasks if you configure it, but its not strictly required
// the actual list type they use is linked list, which seems smartaceous. but they do track in which list the item is,
// which is something we probably also want.
// for the delayed list the item value is the tick count at which the task is resumed
// for the ready lists the item value is meaningless ig
// i think for the ready queue/list we can try to use 1 list for now

pub const MAX_TASKS = 10;

var task_buffer: [@sizeOf(Task) * MAX_TASKS]u8 = undefined;
var task_allocator: std.heap.FixedBufferAllocator = undefined;

var stacks: [MAX_TASKS][256]usize align(8) = undefined;

var n_tasks: u32 = 0;

var ready_queue: SchedulerQueue = .{};
var delayed_queue: SchedulerQueue = .{};

var active_task: u16 = undefined;

// The current active task. may have to move this to port
pub var current_task: *Task = undefined;

pub fn init() void {
    task_allocator = std.heap.FixedBufferAllocator.init(&task_buffer);
}

fn enqueue_ready_task(new_task: *Task) void {
    new_task.sched_list_item = .{ .value = .{
        .priority = new_task.base_priority,
    } };
    ready_queue.insertAfterPriority(Task.SchedulerListItem, &new_task.sched_list_item, Task.SchedulerListItem.compare);
}

pub fn create_ready_task(main_entry: Task.MainEntry, base_priority: Task.Priority) !void {
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

    const item: *Task.SchedulerListItem = @fieldParentPtr("node", first_ready_node);

    const ret: *Task = @fieldParentPtr("sched_list_item", item);
    return ret;
}

pub fn get_current_task() *const Task {
    return current_task;
}

// has to be export since we link into this from inline asm
export fn switch_current_task() void {
    if (@intFromEnum(current_task.state) > 0) {
        return;
    } else if (get_next_ready_task()) |next_ready_task| {
        _ = ready_queue.popFirst();
        current_task = next_ready_task;
        current_task.state = @enumFromInt(1);
    } else {
        // now we should go to an idle task. for now we could just
        current_task.state = @enumFromInt(1);
    }
}

pub fn systick_isr() callconv(.C) void {}
