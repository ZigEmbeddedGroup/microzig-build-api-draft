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
        };
        gop.value_ptr.* = port;
        return port;
    }

    /// Adds a new target to port.
    pub fn add_target(port: *Port, alias: *TargetAlias, options: TargetCreateOptions) *Target {
        if (alias.* != .pointer) {
            std.debug.panic("`Port.add_target` must be called with a `.pointer` alias!", .{});
        }

        const gop = port.targets.getOrPut(alias.pointer.decl_name) catch @panic("out of memory");
        if (gop.found_existing) {
            std.debug.panic("Another target called '{}' does already exist in port '{}'", .{
                std.zig.fmtEscapes(alias.pointer.decl_name),
                std.zig.fmtEscapes(port.name),
            });
        }

        const target = port.b.allocator.create(Target) catch @panic("out of memory");
        target.* = Target{
            .kind = alias.pointer.decl_kind,
            .name = port.b.dupe(alias.pointer.decl_name),
        };

        alias.pointer.target = target;

        _ = options;

        gop.value_ptr.* = target;
        return target;
    }
};

pub const TargetCreateOptions = struct {
    //
};

/// Creates a new alias for chip.
pub fn create_chip(comptime name: []const u8) TargetAlias {
    return create_name(.chip, name);
}

/// Creates a new alias for board.
pub fn create_board(comptime name: []const u8) TargetAlias {
    return create_name(.board, name);
}

/// Creates a new target alias.
pub fn create_name(comptime target_kind: Target.Kind, comptime name: []const u8) TargetAlias {
    return .{
        .pointer = .{
            .decl_kind = target_kind,
            .decl_name = name,
            .target = null,
        },
    };
}

/// A target alias the user references from their build script.
pub const TargetAlias = union(enum) {
    name: []const u8,
    pointer: struct {
        decl_kind: Target.Kind,
        decl_name: []const u8,
        target: ?*Target,
    },
};

/// Actual MicroZig target you can compile for.
pub const Target = struct {
    kind: Kind,
    name: []const u8,

    pub const Kind = enum {
        board,
        chip,
    };
};

pub fn build(b: *std.Build) void {
    _ = b;
}
