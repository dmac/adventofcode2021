const std = @import("std");

const input = @embedFile("05.txt");

const Point = struct {
    x: usize,
    y: usize,
};

const Line = [2]Point;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    var lines = std.ArrayList(Line).init(allocator);
    {
        var it = std.mem.split(u8, input, "\n");
        while (it.next()) |l| {
            if (l.len == 0) {
                continue;
            }
            const line = try parseLine(l);
            try lines.append(line);
        }
    }

    var overlaps: isize = try countOverlaps(allocator, lines.items, false);
    std.debug.print("{d}\n", .{overlaps});
    overlaps = try countOverlaps(allocator, lines.items, true);
    std.debug.print("{d}\n", .{overlaps});
}

fn parseLine(s: []const u8) !Line {
    var it = std.mem.split(u8, s, " ");
    const p0 = try parsePoint(it.next().?);
    _ = it.next(); // discard "->"
    const p1 = try parsePoint(it.next().?);
    return Line{ p0, p1 };
}

fn parsePoint(s: []const u8) !Point {
    var it = std.mem.split(u8, s, ",");
    const x = try std.fmt.parseInt(usize, it.next().?, 10);
    const y = try std.fmt.parseInt(usize, it.next().?, 10);
    return Point{ .x = x, .y = y };
}

fn countOverlaps(allocator: std.mem.Allocator, lines: []Line, include_diagonals: bool) !isize {
    var max_x: usize = 0;
    var max_y: usize = 0;
    for (lines) |line| {
        max_x = std.math.max(max_x, line[0].x);
        max_x = std.math.max(max_x, line[1].x);
        max_y = std.math.max(max_y, line[0].y);
        max_y = std.math.max(max_y, line[1].y);
    }
    const grid = try allocator.alloc([]usize, max_y + 1);
    for (grid) |*row| {
        row.* = try allocator.alloc(usize, max_x + 1);
        for (row.*) |*n| n.* = 0;
    }
    for (lines) |line| {
        if (line[0].x == line[1].x) {
            const x = line[0].x;
            const y0 = std.math.min(line[0].y, line[1].y);
            const y1 = std.math.max(line[0].y, line[1].y);
            for (y0..y1 + 1) |y| {
                grid[y][x] += 1;
            }
        } else if (line[0].y == line[1].y) {
            const y = line[0].y;
            const x0 = std.math.min(line[0].x, line[1].x);
            const x1 = std.math.max(line[0].x, line[1].x);
            for (x0..x1 + 1) |x| {
                grid[y][x] += 1;
            }
        } else {
            if (!include_diagonals) {
                continue;
            }
            var p0 = line[0];
            var p1 = line[1];
            if (p1.x < p0.x) {
                const tmp = p0;
                p0 = p1;
                p1 = tmp;
            }
            var dy: isize = 1;
            if (p1.y < p0.y) {
                dy = -1;
            }
            for (0..(p1.x - p0.x + 1)) |i| {
                const x = p0.x + i;
                const y = @intCast(usize, @intCast(isize, p0.y) + (@intCast(isize, i) * dy));
                grid[y][x] += 1;
            }
        }
    }
    var overlaps: isize = 0;
    for (grid) |row| {
        for (row) |n| {
            if (n > 1) {
                overlaps += 1;
            }
        }
    }
    return overlaps;
}

fn printGrid(grid: [][]usize) void {
    for (grid) |row| {
        for (row) |n| {
            if (n == 0) {
                std.debug.print(".", .{});
            } else {
                std.debug.print("{d}", .{n});
            }
        }
        std.debug.print("\n", .{});
    }
}
