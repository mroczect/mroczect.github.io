+++
title = "tetsing aja gsuh di liat"
date = 2026-10-02
+++

btw ini cuman mau tests ssg aja pakek zola bisa apa ngak

oke jadi bair ada gunaya ini tets blog cara nilsi hello world di `zig@0.16.0`

```zig
const std = @import("std");

pub fn main() void {
	const text : []const u8 = "kalau text ini muncul di terminal berarti berhasil";
	std.debug.print("{s}", .{text});
}
```

output

```sh
$ zig run a.zig
kalau text ini muncul di terminal berarti berhasil%
```

oke jadi dia wak.
