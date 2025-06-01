const std = @import("std");
const DoublyLinkedList = std.DoublyLinkedList;

const Task = @import("task.zig");

// these can basically just be some helper functions
// or maybe a bit more. should maybe make this type generic? idk ill just see if any of this works
//


pub fn insertAfterPriority(list: *DoublyLinkedList, new_item: *Task.SchedulerListItem) void {
    var it: ?*const DoublyLinkedList.Node = list.first;
    var task: *Task.SchedulerListItem = undefined;
    while (it) |n| : (task = @fieldParentPtr("node", it)) {
        it = n.next;
        // we will insert the item at the edge of where the value increases.
        const edge_found: bool = switch (new_item.value) {
            .RUNNING => unreachable,
            .READY => |new_priority| new_priority > task.value.READY,
            .BLOCKED => |new_unblock_ticks| new_unblock_ticks > task.value.BLOCKED,
        };

        if (edge_found) {
            break;
        }
    }
    list.insertAfter(it, &new_item.node);
}
