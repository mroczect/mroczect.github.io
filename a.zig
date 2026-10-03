const std = @import("std");

pub fn main() void {
	const text : []const u8 = "kalau text ini muncul di terminal berarti berhasil";
	std.debug.print("{s}", .{text});
}
