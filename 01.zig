const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const f = try std.fs.cwd().openFile("01.txt", .{});
    defer f.close();

    var depths = std.ArrayList(i32).init(allocator);

    var buf_reader = std.io.bufferedReader(f.reader());
    var buf: [32]u8 = undefined;
    while (try buf_reader.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        const depth = try std.fmt.parseInt(i32, line, 10);
        try depths.append(depth);
    }

    var prev: i32 = 0;
    var count: i32 = 0;
    for (depths.items) |depth| {
        if (prev > 0 and depth > prev) {
            count += 1;
        }
        prev = depth;
    }
    std.debug.print("{}\n", .{count});

    prev = 0;
    count = 0;
    var i: usize = 0;
    while (i < depths.items.len - 2) : (i += 1) {
        const curr = depths.items[i] + depths.items[i + 1] + depths.items[i + 2];
        if (prev > 0 and curr > prev) {
            count += 1;
        }
        prev = curr;
    }
    std.debug.print("{}\n", .{count});
}
