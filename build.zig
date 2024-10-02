const std = @import("std");
const internals = @import("microzig-internal");

pub const port = struct {
    pub const rp2 = @import("microzig-rp2");
};

pub fn build(b: *std.Build) void {
    const rp2_enable = b.option(bool, "rp2", "Enables the Raspberrypi RP2 port") orelse false;

    if (rp2_enable) {
        if (b.lazyDependency("microzig-rp2", .{})) |rp2_dep| {
            const rp2_port = internals.Port.from_dependency(rp2_dep);

            _ = rp2_port;
        }
    }
}

pub fn init(dep: *std.Build.Dependency) *MicroZig {
    const microzig = dep.builder.allocator.create(MicroZig) catch @panic("out of memory");
    microzig.* = .{
        .dep = dep,
    };
    return microzig;
}

pub const MicroZig = struct {
    dep: *std.Build.Dependency,

    pub fn get_tool_exe(mz: *MicroZig, tool: Tool) *std.Build.Step.Compile {
        // HACK: Return a distinct value
        const exe = mz.dep.builder.addExecutable(.{
            .name = @tagName(tool),
            .target = mz.dep.builder.graph.host,
        });
        return exe;
    }

    pub fn add_embedded_executable(mz: *MicroZig, options: EmbeddedExecutable.CreateOptions) *EmbeddedExecutable {
        const exe = mz.dep.builder.allocator.create(EmbeddedExecutable) catch @panic("out of memory");

        exe.* = .{
            //
        };

        _ = options;

        return exe;
    }

    pub fn install_artifact(mz: *MicroZig, exe: *EmbeddedExecutable) void {
        //
        _ = mz;
        _ = exe;
    }
};

pub const EmbeddedExecutable = struct {
    pub const CreateOptions = struct {
        target: internals.TargetAlias,
        optimize: std.builtin.OptimizeMode,
        root_source_file: std.Build.LazyPath,
    };
};

pub const Tool = enum {
    regz,
    uf2,
    zcom,
    picotool,
    // ...
};
