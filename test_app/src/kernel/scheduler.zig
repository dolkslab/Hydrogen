const std = @import("std");
const Task = @import("task.zig");
const microzig = @import("microzig");

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

// The actual queue of tasks to run




var active_task: u16 = undefined;
pub var temp_shit = [2]Task{ undefined, undefined };

// The current active task.
var current_task: *Task = undefined;

pub fn init_queue(allocator: std.mem.Allocator, base_task: Task) void {
    task_queue = Queue.init(allocator, {});
    //add_task(base_task) catch unreachable;

    // we shall just simulate the queue for now
    active_task = 0;
    temp_shit[active_task] = base_task;

    current_task = &temp_shit[active_task];
}

pub fn add_task(new_task: Task) !void {
    try task_queue.add(new_task);
}

pub fn get_next_ready_task() ?*Task {
    // var task_iterator = task_queue.iterator();

    // while (task_iterator.next()) |task| {
    //     if (task.state == .READY) return &task;
    // }

    // return null;
    active_task = blk: {
        if (active_task == temp_shit.len - 1) {
            break :blk 0;
        } else {
            break :blk active_task + 1;
        }
    };
    return &temp_shit[active_task];
}

pub fn start_first_task() void {
    //@breakpoint();
    asm volatile (
        \\ mov r0, #0       
        \\ msr control, r0  
        \\ cpsie i          
        \\ cpsie f          
        \\ dsb              
        \\ isb             
        \\ svc #0x69            
        \\ nop
        : //outputs
        : //inputs
        : "r0");
}

// has to be export since we link into this from inline asm
export fn switch_current_task() void {
    current_task = get_next_ready_task() orelse &temp_shit[0];
}

const max_prio_level = std.fmt.parseInt(u8, microzig.chip.properties.@"cpu.nvicPrioBits", 10) catch unreachable;

pub fn pendsv_isr() callconv(.Naked) void {
    asm volatile (
        \\
        // Store the context to the stack that was not saved on exception entry.
        // Test for bit 4 in the LR to check if FPU was active, if so, save its context (expensive!)
        \\ mrs          r0, psp
        \\
        \\ tst          r14, #0x10
        \\ it eq
        \\ vstmdbeq     r0!, {s16-s31}
        \\     
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
        \\
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
          [max_prio_lvl] "i" (max_prio_level),
    );
}

pub fn svcall_isr() callconv(.C) void {
    //@breakpoint();
    const sp_addr: [*]align(8) usize = current_task.top_of_stack;
    // look ma no compiler
    asm volatile (
        \\ ldmia r0!, {r4-r11, r14}
        \\ msr psp, r0
        \\ isb
        \\ mov r0, #0
        \\ msr basepri, r0
        \\ mov r14, #0xfffffffd
        \\ bx r14
        : //outputs
        : [sp_addr] "{r0}" (sp_addr),
        : ".ltorg"
    );
}

pub fn systick_isr() callconv(.C) void {}