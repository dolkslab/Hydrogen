const std = @import("std");
const microzig = @import("microzig");
const scheduler = @import("scheduler.zig");
const Task = @import("task.zig");

pub const Stack = struct {
    pub const StackPtr = [*]align(8) usize;

    /// Initialise the stack frame of this task to simulate exception entry
    pub fn init_stack(stack_ptr: *StackPtr, main_entry: *const Task.MainEntry) void {
        // decrement the stack pointer first since the stack grows downwards
        stack_ptr.* -= BasicContext.Size / @sizeOf(usize) + 1;
        var initial_context: *BasicContext = (@ptrCast(stack_ptr.*));

        initial_context.return_state = .{
            .active_stack_pointer = .PSP,
            .exec_mode = .THREAD,
            .fpu_state = .INACTIVE,
        };

        initial_context.LR = @intFromPtr(&default_return);
        initial_context.return_adress = @intFromPtr(main_entry) & 0xFFFFFFFE;
        initial_context.xPSR = INITIAL_XPSR;
        initial_context.a1 = 1000;
        initial_context.a2 = 1001;
        initial_context.a3 = 1002;
        initial_context.a4 = 1003;
        initial_context.IP = 1012;
    }

    //for now i will put this here

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
        @panic("Illegal return from base process!");
    }
};

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
        \\ str          r0, [r1], #0
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
          //[task_sp_offset] "I" (@offsetOf(Task, "top_of_stack")),
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
        \\ str          r0, [r1], #0
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
          //[task_sp_offset] "I" (@offsetOf(Task, "top_of_stack")),
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
