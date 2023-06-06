const std = @import("std");

const input = @embedFile("17.txt");
// const input = "target area: x=20..30, y=-10..-5";

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var it = std.mem.tokenize(u8, input, "target area: xy=.,\r\n");
    const xmin = try std.fmt.parseInt(isize, it.next().?, 10);
    const xmax = try std.fmt.parseInt(isize, it.next().?, 10);
    const ymin = try std.fmt.parseInt(isize, it.next().?, 10);
    const ymax = try std.fmt.parseInt(isize, it.next().?, 10);

    var xs = std.ArrayList(isize).init(allocator);
    {
        var dx_start: isize = 1;
        outer: while (dx_start <= xmax) : (dx_start += 1) {
            var dx = dx_start;
            var x: isize = 0;
            while (x <= xmax and dx > 0) {
                x += dx;
                if (dx > 0) dx -= 1;
                if (x >= xmin and x <= xmax) {
                    try xs.append(dx_start);
                    continue :outer;
                }
            }
        }
    }

    var ys = std.ArrayList(isize).init(allocator);
    {
        var dy_start: isize = -500;
        outer: while (dy_start < 500) : (dy_start += 1) {
            var dy = dy_start;
            var y: isize = 0;
            while (y >= ymin) {
                y += dy;
                dy -= 1;
                if (y >= ymin and y <= ymax) {
                    try ys.append(dy_start);
                    continue :outer;
                }
            }
        }
    }

    var highest_y: isize = 0;
    var count: isize = 0;
    for (xs.items) |dx_start| {
        for (ys.items) |dy_start| {
            var x: isize = 0;
            var y: isize = 0;
            var dx = dx_start;
            var dy = dy_start;
            var current_highest_y: isize = 0;
            var counted = false;
            while (x <= xmax and y >= ymin) {
                x += dx;
                y += dy;
                current_highest_y = std.math.max(current_highest_y, y);
                if (dx > 0) dx -= 1;
                dy -= 1;
                if (x >= xmin and x <= xmax and
                    y <= ymax and y >= ymin)
                {
                    if (!counted) {
                        counted = true;
                        count += 1;
                    }
                    highest_y = std.math.max(highest_y, current_highest_y);
                }
            }
        }
    }
    std.debug.print("{}\n", .{highest_y});
    std.debug.print("{}\n", .{count});
}
