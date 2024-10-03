const std = @import("std");
const microzig = @This();

const target = @import("microzig-target");

pub const cpu = target.chip.cpu;
pub const chip = target.chip;

pub const has_hal = @hasDecl(target, "hal");
pub const hal = if (has_hal)
    target.hal
else
    @compileError(target.name ++ " has no HAL available.");

pub const has_board = @hasDecl(target, "board");
pub const board = if (has_board)
    target.board
else
    @compileError(target.name ++ " is not a board available.");

pub const StartupOptions = struct {
    entry_point: bool = false,
    std_options: bool = false,
};

pub fn startup(options: StartupOptions) type {
    return struct {
        pub usingnamespace if (options.entry_point)
            struct {
                pub const _start = entry_point;
            }
        else
            struct {};

        pub usingnamespace if (options.entry_point)
            struct {
                pub const std_options: std.Options = microzig.std_options;
            }
        else
            struct {};
    };
}

pub const std_options = std.Options{
    // .logFn =
};

pub fn entry_point() callconv(.Naked) noreturn {
    asm volatile ("");
    unreachable;
}
