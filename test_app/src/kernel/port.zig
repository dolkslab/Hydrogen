const std = @import("std");
const microzig = @import("microzig");
const scheduler = @import("scheduler.zig");
const Task = @import("task.zig");

pub fn jump_to_first_task() void {
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

const max_prio_level = std.fmt.parseInt(u8, microzig.chip.properties.@"cpu.nvicPrioBits", 10) catch unreachable;

fn pendsv_isr_fpu() callconv(.Naked) void {
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
        \\ str          r0, [r1], #[task_sp_offset]
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
        : [current_task_ptr] "{r2}" (&scheduler.current_task),
          [max_prio_lvl] "i" (max_prio_level),
          [task_sp_offset] "I" (@offsetOf(Task, "top_of_stack")),
    );
}

fn pendsv_isr_no_fpu() callconv(.Naked) void {
    asm volatile (
        \\
        // Store the context to the stack that was not saved on exception entry.
        // Test for bit 4 in the LR to check if FPU was active, if so, save its context (expensive!)
        \\ mrs          r0, psp
        \\     
        \\ stmdb        r0!, {r4-r11, r14}
        \\
        // Obtain the active task by dereferencing r2.
        // when we deref it again this gives the SP location.
        \\ ldr          r1,  [r2] 
        \\ str          r0, [r1], #[task_sp_offset]
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
        \\ msr          psp, r0
        \\ isb
        // The psp now holds the stack frame of the new task as if it was just interrupted.
        // R14 holds the execution mode for this task. BX exits the handler.
        \\ bx           r14
        : //outputs
        : [current_task_ptr] "{r2}" (&scheduler.current_task),
          [max_prio_lvl] "i" (max_prio_level),
          [task_sp_offset] "I" (@offsetOf(Task, "top_of_stack")),
    );
}

pub const pendsv_isr = blk: {
    if (microzig.cpu.fpu.present) {
        break :blk pendsv_isr_fpu;
    } else {
        break :blk pendsv_isr_no_fpu;
    }
};

pub fn svcall_isr() callconv(.C) void {
    //@breakpoint();
    const sp_addr: [*]align(8) usize = scheduler.current_task.top_of_stack;
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

pub fn pend_context_switch() void {
    microzig.cpu.interrupt.exception.set_pending(.PendSV);
}

pub fn start_systick() void {
    const systick_rate = 1000;
    const rp2xxx_ticks_rate = 1_000_000;

    // for now i will assume ticks_rate = 1MHz
    const systick_div: u32 = comptime rp2xxx_ticks_rate / systick_rate;
    microzig.chip.peripherals.PPB.SYST_RVR.write_raw(systick_div - 1);
    // enable, use external ref clk, generate interrupt.
    microzig.chip.peripherals.PPB.SYST_CSR.write_raw(0b011);
}

pub fn systick_isr() callconv(.C) void {
    if (scheduler.tick()) {
        pend_context_switch();
    }
}
