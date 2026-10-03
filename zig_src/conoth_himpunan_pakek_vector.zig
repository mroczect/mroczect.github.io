const std = @import("std");

pub fn main() void {
    const bahasa_anti_gc = [_][]const u8{
        "C",
        "C++",
        "Rust",
        "Zig",
        "Ada",
    };
    for (bahasa_anti_gc) |bahasa| {
        std.debug.print("{s}\n", .{bahasa});
    }
}
