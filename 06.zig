const std = @import("std");

const input = std.mem.trim(u8, @embedFile("06.txt"), "\n");

pub fn main() !void {
    const p0 = try simulate(80);
    const p1 = try simulate(256);
    std.debug.print("{d}\n", .{p0});
    std.debug.print("{d}\n", .{p1});
}

fn simulate(days: isize) !isize {
    var buckets = std.mem.zeroes([9]isize);
    var it = std.mem.split(u8, input, ",");
    while (it.next()) |s| {
        const n = try std.fmt.parseInt(usize, s, 10);
        buckets[n] += 1;
    }

    var day: isize = 0;
    while (day < days) : (day += 1) {
        const zero: isize = buckets[0];
        for (0..8) |b| {
            buckets[b] = buckets[b + 1];
        }
        buckets[6] += zero;
        buckets[8] = zero;
    }

    var sum: isize = 0;
    for (buckets) |bucket| {
        sum += bucket;
    }
    return sum;
}
