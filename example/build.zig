const std = @import("std");
const MicroZig = @import("microzig");

pub fn build(b: *std.Build) void {
    const microzig_dep = b.dependency("microzig", .{
        .rp2 = true,
    });

    const microzig = MicroZig.init(microzig_dep);

    b.installArtifact(microzig.get_tool_exe(.picotool));
    b.installArtifact(microzig.get_tool_exe(.uf2));

    const exe1 = microzig.add_embedded_executable(.{
        .target = MicroZig.port.rp2.boards.raspberrypi.pico,
        .optimize = .ReleaseFast,
        .root_source_file = b.path("src/example.zig"),
    });

    microzig.install_artifact(exe1);

    const exe2 = microzig.add_embedded_executable(.{
        .target = .{ .name = "rp2.board.raspberrypi-pico" },
        .optimize = .ReleaseSafe,
        .root_source_file = b.path("src/example.zig"),
    });

    microzig.install_artifact(exe2);
}
