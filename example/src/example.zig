const std = @import("std");
const microzig = @import("microzig");

// Integrate the `startup` namespace
pub usingnamespace microzig.startup(.{
    // the following are default values:
    .entry_point = true,
    .std_options = microzig.has_hal,
});

pub fn main() void {
    //
}
