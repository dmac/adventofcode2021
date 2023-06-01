const std = @import("std");

const input = @embedFile("14.txt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var counts = std.AutoHashMap(u8, usize).init(allocator);
    var pairs = std.AutoHashMap([2]u8, usize).init(allocator);
    var lines = std.mem.tokenize(u8, input, "\r\n");
    {
        const line = lines.next().?;
        for (0..line.len - 1) |i| {
            const key = [2]u8{ line[i], line[i + 1] };
            const value = try pairs.getOrPut(key);
            if (!value.found_existing) {
                value.value_ptr.* = 0;
            }
            value.value_ptr.* += 1;
            try tally(&counts, line[i], 1);
        }
        try tally(&counts, line[line.len - 1], 1);
    }

    var rules = std.StringHashMap(u8).init(allocator);
    while (lines.next()) |line| {
        var it = std.mem.split(u8, line, " -> ");
        try rules.put(it.next().?, it.next().?[0]);
        if (it.next() != null) unreachable;
    }

    for (0..40) |i| {
        var new_pairs = std.AutoHashMap([2]u8, usize).init(allocator);
        var it = pairs.iterator();
        while (it.next()) |entry| {
            const v = rules.get(entry.key_ptr);
            if (v == null) continue;
            const c = v.?;
            try tally(&counts, c, entry.value_ptr.*);
            const key0 = .{ entry.key_ptr.*[0], c };
            const key1 = .{ c, entry.key_ptr.*[1] };
            for ([_][2]u8{ key0, key1 }) |key| {
                const value = try new_pairs.getOrPut(key);
                if (!value.found_existing) {
                    value.value_ptr.* = 0;
                }
                value.value_ptr.* += entry.value_ptr.*;
            }
        }
        pairs.clearRetainingCapacity();
        pairs = try new_pairs.clone();

        if (i == 9 or i == 39) {
            var max: usize = 0;
            var min: usize = std.math.maxInt(usize);
            var counts_it = counts.valueIterator();
            while (counts_it.next()) |count| {
                max = std.math.max(max, count.*);
                min = std.math.min(min, count.*);
            }
            std.debug.print("{d}\n", .{max - min});
        }
    }
}

fn tally(counts: *std.AutoHashMap(u8, usize), c: u8, n: usize) !void {
    var value = try counts.getOrPut(c);
    if (!value.found_existing) {
        value.value_ptr.* = 0;
    }
    value.value_ptr.* += n;
}
