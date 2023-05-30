const std = @import("std");

const input = @embedFile("13.txt");

const Point = struct {
    x: usize,
    y: usize,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var points = std.ArrayList(Point).init(allocator);
    var folds = std.ArrayList(Point).init(allocator);
    var max_x: usize = 0;
    var max_y: usize = 0;
    {
        var it = std.mem.tokenize(u8, input, "\r\n");
        while (it.next()) |line| {
            if (line.len == 0) continue;
            if (std.mem.indexOf(u8, line, ",")) |i| {
                const x = try std.fmt.parseInt(usize, line[0..i], 10);
                const y = try std.fmt.parseInt(usize, line[i + 1 ..], 10);
                try points.append(Point{ .x = x, .y = y });
                max_x = std.math.max(x, max_x);
                max_y = std.math.max(y, max_y);
            } else {
                const i = std.mem.indexOf(u8, line, "=").?;
                const n = try std.fmt.parseInt(usize, line[i + 1 ..], 10);
                if (line[i - 1] == 'x') {
                    try folds.append(Point{ .x = n, .y = 0 });
                } else {
                    try folds.append(Point{ .x = 0, .y = n });
                }
            }
        }
    }

    const rows = max_y + 1;
    const cols = max_x + 1;
    var grid = try allocator.alloc(bool, rows * cols);
    @memset(grid, false);
    for (points.items) |p| {
        grid[p.y * cols + p.x] = true;
    }
    for (folds.items, 0..) |fold, i| {
        for (0..rows) |y| {
            for (0..cols) |x| {
                if (!grid[y * cols + x]) continue;
                if (fold.x != 0) {
                    if (x < fold.x) continue;
                    grid[y * cols + x] = false;
                    const nx = x - 2 * (x - fold.x);
                    grid[y * cols + nx] = true;
                } else {
                    if (y < fold.y) continue;
                    grid[y * cols + x] = false;
                    const ny = y - 2 * (y - fold.y);
                    grid[ny * cols + x] = true;
                }
            }
        }
        if (i == 0) {
            var count: usize = 0;
            for (grid) |c| {
                if (c) count += 1;
            }
            std.debug.print("{d}\n", .{count});
        }
    }
    for (0..6) |row| {
        for (0..39) |col| {
            if (grid[row * cols + col]) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}
