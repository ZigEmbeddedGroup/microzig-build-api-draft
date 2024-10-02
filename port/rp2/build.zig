//!
//! Build script for the MicroZig RP2 port.
//!
const std = @import("std");
const MicroZig = @import("microzig-internal");

pub const chips = struct {
    pub var rp2040 = MicroZig.create_chip("rp2040");
    pub var rp2350a = MicroZig.create_chip("rp2350a");
    pub var rp2350b = MicroZig.create_chip("rp2350b");
    pub var rp2354a = MicroZig.create_chip("rp2354a");
    pub var rp2354b = MicroZig.create_chip("rp2354b");
};

pub const boards = struct {
    pub const raspberrypi = struct {
        pub var pico = MicroZig.create_board("raspberrypi-pico");
        pub var pico2 = MicroZig.create_board("raspberrypi-pico2");
    };
};

pub fn build(b: *std.Build) void {
    const port = MicroZig.Port.register(b, "RP2");

    _ = port.add_target(&chips.rp2040, .{});
    _ = port.add_target(&chips.rp2350a, .{});
    _ = port.add_target(&chips.rp2350b, .{});
    _ = port.add_target(&chips.rp2354a, .{});
    _ = port.add_target(&chips.rp2354b, .{});
    _ = port.add_target(&boards.raspberrypi.pico, .{});
    _ = port.add_target(&boards.raspberrypi.pico2, .{});
}
