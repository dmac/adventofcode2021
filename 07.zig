const std = @import("std");

const input = std.mem.trim(u8, @embedFile("07.txt"), "\n");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    var crabs = std.ArrayList(isize).init(allocator);
    {
        var it = std.mem.tokenize(u8, input, ",");
        while (it.next()) |s| {
            const n = try std.fmt.parseInt(isize, s, 10);
            try crabs.append(n);
        }
    }

    try simulate(allocator, crabs.items, unit_fuel_part1);
    try simulate(allocator, crabs.items, unit_fuel_part2);
}

fn simulate(allocator: std.mem.Allocator, crabs: []isize, comptime unit_fuel_fn: FuelFn) !void {
    var max: isize = 0;
    for (crabs) |crab| max = std.math.max(max, crab);

    var space = try allocator.alloc(isize, @intCast(usize, max + 1));
    for (space) |*s| s.* = 0;
    for (crabs) |crab| {
        space[@intCast(usize, crab)] += 1;
    }
    var min_fuel: isize = std.math.maxInt(isize);
    var min_candidate: isize = std.math.maxInt(isize);
    for (space, 0..) |_, candidate| {
        var fuel: isize = 0;
        for (space, 0..) |num_crabs, i| {
            const dist = try std.math.absInt(@intCast(isize, candidate) - @intCast(isize, i));
            fuel += unit_fuel_fn(dist) * num_crabs;
        }
        if (fuel < min_fuel) {
            min_fuel = fuel;
            min_candidate = @intCast(isize, candidate);
        }
    }

    std.debug.print("fuel={d} position={d}\n", .{ min_fuel, min_candidate });
}

const FuelFn = fn (dist: isize) isize;

fn unit_fuel_part1(dist: isize) isize {
    return dist;
}

fn unit_fuel_part2(dist: isize) isize {
    return @divTrunc((dist * (dist + 1)), 2);
}
