//!
//! Build script for the MicroZig RP2 port.
//!
const std = @import("std");
const MicroZig = @import("microzig-internal");

// this section is kinda footgunny, as you have to use `value = &TargetAlias{}` instead of
// `value = TargetAlias{}` for nice UX on the end, but i guess that's fine.
pub const chips = struct {
    pub const rp2040 = &MicroZig.TargetAlias.chip("rp2040");
    pub const rp2350a = &MicroZig.TargetAlias.chip("rp2350a");
    pub const rp2350b = &MicroZig.TargetAlias.chip("rp2350b");
    pub const rp2354a = &MicroZig.TargetAlias.chip("rp2354a");
    pub const rp2354b = &MicroZig.TargetAlias.chip("rp2354b");
};

pub const boards = struct {
    pub const raspberrypi = struct {
        pub const pico = &MicroZig.TargetAlias.board("raspberrypi-pico");
        pub const pico2 = &MicroZig.TargetAlias.board("raspberrypi-pico2");
    };
};

pub fn build(b: *std.Build) void {
    const port = MicroZig.Port.register(b, "RP2");

    // TODO: Open Questions
    // - How do you get the "CPU" module here?
    //

    const cortex_m0plus = port.create_cpu("cortex-m0+", .{
        .root_source_file = b.path("src/cpu.zig"),
        .target = .{},
    });
    const cortex_m33 = port.create_cpu("cortex-m33", .{
        .root_source_file = b.path("src/cpu.zig"),
        .target = .{},
    });

    const rp2040 = port.create_chip("rp2040", .{
        .root_source_file = b.path("src/chip/rp2040.zig"),
        .cpu = cortex_m0plus,
        .imports = &.{},
    });

    const rp2350 = port.create_chip("rp2350", .{
        .root_source_file = b.path("src/chip/rp2350.zig"),
        .cpu = cortex_m33,
        .imports = &.{},
    });

    const rp2_hal = b.createModule(.{
        .root_source_file = b.path("src/hal/rp2.zig"),
    });

    _ = port.add_target(chips.rp2040, .{
        .chip = rp2040,
        .hal = rp2_hal,
    });
    _ = port.add_target(chips.rp2350a, .{
        .chip = rp2350,
        .hal = rp2_hal,
    });
    _ = port.add_target(chips.rp2350b, .{
        .chip = rp2350,
        .hal = rp2_hal,
    });
    _ = port.add_target(chips.rp2354a, .{
        .chip = rp2350,
        .hal = rp2_hal,
    });
    _ = port.add_target(chips.rp2354b, .{
        .chip = rp2350,
        .hal = rp2_hal,
    });
    _ = port.add_target(boards.raspberrypi.pico, .{
        .chip = rp2040,
        .hal = rp2_hal,
        .board = b.createModule(.{
            .root_source_file = b.path("src/board/pico.zig"),
        }),
    });
    _ = port.add_target(boards.raspberrypi.pico2, .{
        .chip = rp2350,
        .hal = rp2_hal,
        .board = b.createModule(.{
            .root_source_file = b.path("src/board/pico2.zig"),
        }),
    });
}
