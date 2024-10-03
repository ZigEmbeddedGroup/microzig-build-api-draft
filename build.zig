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

    // TODO: Add shared/common modules here:

    // Tools are just public executables artifacts:

    {
        const exe = b.addExecutable(.{
            .name = "regz",
            .target = b.graph.host,
            .root_source_file = b.path("tools/regz.zig"),
        });
        b.installArtifact(exe);
    }

    {
        const exe = b.addExecutable(.{
            .name = "uf2",
            .target = b.graph.host,
            .root_source_file = b.path("tools/uf2.zig"),
        });
        b.installArtifact(exe);
    }

    {
        const exe = b.addExecutable(.{
            .name = "picotool",
            .target = b.graph.host,
            .root_source_file = b.path("tools/picotool.zig"),
        });
        b.installArtifact(exe);
    }
}

pub fn init(b: *std.Build, dep: *std.Build.Dependency) *MicroZig {
    const microzig = dep.builder.allocator.create(MicroZig) catch @panic("out of memory");
    microzig.* = .{
        .creating_builder = b,
        .dep = dep,
    };
    return microzig;
}

pub const MicroZig = struct {
    creating_builder: *std.Build,
    dep: *std.Build.Dependency,

    pub fn get_tool_exe(mz: *MicroZig, tool: Tool) *std.Build.Step.Compile {
        return mz.dep.artifact(@tagName(tool));
    }

    pub fn add_embedded_executable(mz: *MicroZig, options: EmbeddedExecutable.CreateOptions) *EmbeddedExecutable {
        const target = mz.resolve_target(null, options.target);

        const core_mod = mz.dep.builder.createModule(.{
            .root_source_file = mz.dep.builder.path("core/microzig.zig"),
        });

        core_mod.addImport("microzig-target", target.module);

        const exe: *EmbeddedExecutable = mz.dep.builder.allocator.create(EmbeddedExecutable) catch @panic("out of memory");
        exe.* = .{
            .artifact = mz.creating_builder.addExecutable(.{
                .name = options.name,
                .target = target.chip.cpu.target,
                .optimize = options.optimize,
                .root_source_file = options.root_source_file,
            }),
        };

        exe.artifact.root_module.addImport("microzig", core_mod);

        return exe;
    }

    pub fn install_artifact(mz: *MicroZig, exe: *EmbeddedExecutable) void {
        mz.creating_builder.installArtifact(exe.artifact);
    }

    fn resolve_target(mz: *MicroZig, port_hint: ?*internals.Port, alias: *const internals.TargetAlias) *const internals.Target {
        _ = mz;
        _ = alias;
        _ = port_hint;
        @panic("not done");
    }
};

pub const EmbeddedExecutable = struct {
    pub const CreateOptions = struct {
        name: []const u8,
        target: *const internals.TargetAlias,
        optimize: std.builtin.OptimizeMode,
        root_source_file: std.Build.LazyPath,
    };

    artifact: *std.Build.Step.Compile,
};

pub const Tool = enum {
    regz,
    uf2,
    zcom,
    picotool,
    // ...
};
