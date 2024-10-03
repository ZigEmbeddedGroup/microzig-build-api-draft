const std = @import("std");

const port_registry = struct {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    var ports = std.AutoArrayHashMap(*std.Build, *Port).init(arena.allocator());
};

/// A port is a container for MicroZig types.
/// Each port can be enabled/disabled separately.
pub const Port = struct {
    b: *std.Build,
    name: []const u8,

    targets: std.StringArrayHashMap(*Target),
    registered_targets: std.AutoArrayHashMap(*const TargetAlias, *Target),

    pub fn from_dependency(dep: *std.Build.Dependency) *Port {
        return port_registry.ports.get(dep.builder) orelse std.debug.panic(
            "Dependency {s} was not registered as a port with with `Port.register(b)`!",
            .{std.fs.path.basename(dep.builder.pathFromRoot("."))},
        );
    }

    pub fn register(b: *std.Build, name: []const u8) *Port {
        if (b.available_options_list.items.len > 0) {
            std.debug.panic("Port '{}' uses `b.option()`. This is currently not supported.", .{
                std.zig.fmtEscapes(name),
            });
        }

        const gop = port_registry.ports.getOrPut(b) catch @panic("out of memory");
        if (gop.found_existing) {
            std.debug.panic("Port '{}' registered twice! Did you call `b.dependency()` with different options?", .{
                std.zig.fmtEscapes(name),
            });
        }

        const port = b.allocator.create(Port) catch @panic("out of memory");
        port.* = .{
            .b = b,
            .name = b.dupe(name),
            .targets = std.StringArrayHashMap(*Target).init(b.allocator),
            .registered_targets = std.AutoArrayHashMap(*const TargetAlias, *Target).init(b.allocator),
        };
        gop.value_ptr.* = port;
        return port;
    }

    pub const AddCpuOptions = struct {
        root_source_file: std.Build.LazyPath,
        target: std.Target.Query,
        imports: []const std.Build.Module.Import = &.{},
    };
    pub fn create_cpu(port: *Port, name: []const u8, options: AddCpuOptions) *const Cpu {
        const cpu = port.b.allocator.create(Cpu) catch @panic("out of memory");
        cpu.* = Cpu{
            .name = port.b.dupe(name),
            .target = port.b.resolveTargetQuery(options.target),
            .module = port.b.createModule(.{
                .root_source_file = options.root_source_file,
                .imports = options.imports,
            }),
        };
        return cpu;
    }

    pub const AddChipOptions = struct {
        cpu: *const Cpu,
        root_source_file: std.Build.LazyPath,
        imports: []const std.Build.Module.Import = &.{},
    };
    pub fn create_chip(port: *Port, name: []const u8, options: AddChipOptions) *const Chip {
        const chip = port.b.allocator.create(Chip) catch @panic("out of memory");
        chip.* = Chip{
            .name = port.b.dupe(name),
            .cpu = options.cpu,
            .module = port.b.createModule(.{
                .root_source_file = options.root_source_file,
                .imports = options.imports,
            }),
        };

        return chip;
    }

    /// Adds a new target to port.
    pub fn add_target(port: *Port, alias: *const TargetAlias, options: TargetCreateOptions) *Target {
        const target_kind: Target.Kind, const target_name: []const u8 = switch (alias.*) {
            .name => std.debug.panic("`Port.add_target` must be called with a `.registered_chip` or `.registered_board` alias!", .{}),
            .registered_board => |name| .{ .board, name },
            .registered_chip => |name| .{ .chip, name },
        };

        const alias_gop = port.registered_targets.getOrPut(alias) catch @panic("out of memory");
        if (alias_gop.found_existing) {
            std.debug.panic("This alias is already associated with another target called '{}'", .{
                std.zig.fmtEscapes(alias_gop.value_ptr.*.name),
            });
        }

        const name_gop = port.targets.getOrPut(target_name) catch @panic("out of memory");
        if (name_gop.found_existing) {
            std.debug.panic("Another target called '{}' does already exist in port '{}'", .{
                std.zig.fmtEscapes(target_name),
                std.zig.fmtEscapes(port.name),
            });
        }

        const target = port.b.allocator.create(Target) catch @panic("out of memory");
        target.* = Target{
            .kind = target_kind,
            .name = port.b.dupe(target_name),
            .chip = options.chip,
            .hal = options.hal,
            .board = options.board,
            .module = port.b.createModule(.{
                .root_source_file = port.b.path("src/target.zig"),
                .imports = &.{
                    .{ .name = "microzig-chip", .module = options.chip.module },
                },
            }),
        };

        name_gop.value_ptr.* = target;
        alias_gop.value_ptr.* = target;
        return target;
    }
};

pub const Cpu = struct {
    name: []const u8,
    module: *std.Build.Module,
    target: std.Build.ResolvedTarget,
};

pub const Chip = struct {
    name: []const u8,
    module: *std.Build.Module,
    cpu: *const Cpu,
};

pub const TargetCreateOptions = struct {
    chip: *const Chip,
    hal: ?*std.Build.Module = null,
    board: ?*std.Build.Module = null,
};

/// Actual MicroZig target you can compile for.
pub const Target = struct {
    kind: Kind,

    name: []const u8,

    chip: *const Chip,
    hal: ?*std.Build.Module,
    board: ?*std.Build.Module,

    module: *std.Build.Module,

    pub const Kind = enum {
        board,
        chip,
    };
};
/// A target alias the user references from their build script.
pub const TargetAlias = union(enum) {
    // use to refer to a target by name:
    name: []const u8,

    // internal use, must be registered with the port:
    registered_board: []const u8,
    registered_chip: []const u8,

    pub fn board(name: []const u8) TargetAlias {
        return .{ .registered_board = name };
    }

    pub fn chip(name: []const u8) TargetAlias {
        return .{ .registered_chip = name };
    }
};

pub fn build(b: *std.Build) void {
    _ = b;
}
