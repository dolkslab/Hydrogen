const std = @import("std");
const Task = @import("task.zig");

const debug = std.debug;
const assert = debug.assert;
const testing = std.testing;
const SchedulerQueue = @This();
const Order = std.math.Order;

first: ?*Node = null,
last: ?*Node = null,
// these can basically just be some helper functions
// or maybe a bit more. should maybe make this type generic? idk ill just see if any of this works
//

pub fn insertAfterPriority(list: *SchedulerQueue, comptime ItemType: type, new_item: *ItemType, comptime compareFn: fn (a: ItemType, b: ItemType) Order) void {
    var it: ?*SchedulerQueue.Node = list.first;

    while (it) |n| {
        const existing_item: *ItemType = @fieldParentPtr("node", n);
        // we will insert the item at the edge of where the value increases.

        if (compareFn(existing_item.*, new_item.*) == Order.gt) {
            list.insertBefore(n, &new_item.node);
            break;
        }
        it = n.next;
    }
    list.append(&new_item.node);
}

/// This struct contains only the prev and next pointers and not any data
/// payload. The intended usage is to embed it intrusively into another data
/// structure and access the data with `@fieldParentPtr`.
pub const Node = struct {
    prev: ?*Node = null,
    next: ?*Node = null,
};

pub fn insertAfter(list: *SchedulerQueue, existing_node: *Node, new_node: *Node) void {
    new_node.prev = existing_node;
    if (existing_node.next) |next_node| {
        // Intermediate node.
        new_node.next = next_node;
        next_node.prev = new_node;
    } else {
        // Last element of the list.
        new_node.next = null;
        list.last = new_node;
    }
    existing_node.next = new_node;
}

pub fn insertBefore(list: *SchedulerQueue, existing_node: *Node, new_node: *Node) void {
    new_node.next = existing_node;
    if (existing_node.prev) |prev_node| {
        // Intermediate node.
        new_node.prev = prev_node;
        prev_node.next = new_node;
    } else {
        // First element of the list.
        new_node.prev = null;
        list.first = new_node;
    }
    existing_node.prev = new_node;
}

/// Concatenate list2 onto the end of list1, removing all entries from the former.
///
/// Arguments:
///     list1: the list to concatenate onto
///     list2: the list to be concatenated
pub fn concatByMoving(list1: *SchedulerQueue, list2: *SchedulerQueue) void {
    const l2_first = list2.first orelse return;
    if (list1.last) |l1_last| {
        l1_last.next = list2.first;
        l2_first.prev = list1.last;
    } else {
        // list1 was empty
        list1.first = list2.first;
    }
    list1.last = list2.last;
    list2.first = null;
    list2.last = null;
}

/// Insert a new node at the end of the list.
///
/// Arguments:
///     new_node: Pointer to the new node to insert.
pub fn append(list: *SchedulerQueue, new_node: *Node) void {
    if (list.last) |last| {
        // Insert after last.
        list.insertAfter(last, new_node);
    } else {
        // Empty list.
        list.prepend(new_node);
    }
}

/// Insert a new node at the beginning of the list.
///
/// Arguments:
///     new_node: Pointer to the new node to insert.
pub fn prepend(list: *SchedulerQueue, new_node: *Node) void {
    if (list.first) |first| {
        // Insert before first.
        list.insertBefore(first, new_node);
    } else {
        // Empty list.
        list.first = new_node;
        list.last = new_node;
        new_node.prev = null;
        new_node.next = null;
    }
}

/// Remove a node from the list.
///
/// Arguments:
///     node: Pointer to the node to be removed.
pub fn remove(list: *SchedulerQueue, node: *Node) void {
    if (node.prev) |prev_node| {
        // Intermediate node.
        prev_node.next = node.next;
    } else {
        // First element of the list.
        list.first = node.next;
    }

    if (node.next) |next_node| {
        // Intermediate node.
        next_node.prev = node.prev;
    } else {
        // Last element of the list.
        list.last = node.prev;
    }
}

/// Remove and return the last node in the list.
///
/// Returns:
///     A pointer to the last node in the list.
pub fn pop(list: *SchedulerQueue) ?*Node {
    const last = list.last orelse return null;
    list.remove(last);
    return last;
}

/// Remove and return the first node in the list.
///
/// Returns:
///     A pointer to the first node in the list.
pub fn popFirst(list: *SchedulerQueue) ?*Node {
    const first = list.first orelse return null;
    list.remove(first);
    return first;
}

/// Iterate over all nodes, returning the count.
///
/// This operation is O(N). Consider tracking the length separately rather than
/// computing it.
pub fn len(list: SchedulerQueue) usize {
    var count: usize = 0;
    var it: ?*const Node = list.first;
    while (it) |n| : (it = n.next) count += 1;
    return count;
}

pub fn is_empty(list: SchedulerQueue) bool {
    return list.first == null;
}
