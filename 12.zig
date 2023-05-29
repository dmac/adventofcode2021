const std = @import("std");

const input = @embedFile("12.txt");

const Cave = struct {
    name: []const u8,
    caves: std.ArrayList([]const u8),

    fn init(allocator: std.mem.Allocator, name: []const u8) Cave {
        return .{
            .name = name,
            .caves = std.ArrayList([]const u8).init(allocator),
        };
    }

    fn small(self: Cave) bool {
        return self.name[0] >= 'a' and self.name[0] <= 'z';
    }

    fn print(self: Cave) void {
        std.debug.print("{s}:", .{self.name});
        for (self.caves.items) |name| {
            std.debug.print(" {s},", .{name});
        }
        std.debug.print("\n", .{});
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var caves = std.StringHashMap(Cave).init(allocator);
    var lines = std.mem.tokenize(u8, input, "\r\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const i = std.mem.indexOf(u8, line, "-").?;
        const name0 = line[0..i];
        const name1 = line[i + 1 ..];
        if (!caves.contains(name0)) {
            try caves.put(name0, Cave.init(allocator, name0));
        }
        if (!caves.contains(name1)) {
            try caves.put(name1, Cave.init(allocator, name1));
        }
        var cave0 = caves.getPtr(name0).?;
        var cave1 = caves.getPtr(name1).?;
        try cave0.caves.append(cave1.name);
        try cave1.caves.append(cave0.name);
    }
    var exploring = std.ArrayList(*Cave).init(allocator);
    var visited = std.StringHashMap(usize).init(allocator);
    var finals = std.ArrayList(std.ArrayList(*Cave)).init(allocator);
    try exploring.append(caves.getPtr("start").?);
    try visited.put("start", 1);

    try explore(caves, &exploring, &visited, &finals, true);
    std.debug.print("{d}\n", .{finals.items.len});
    finals.clearRetainingCapacity();
    try explore(caves, &exploring, &visited, &finals, false);
    std.debug.print("{d}\n", .{finals.items.len});
}

fn explore(
    caves: std.StringHashMap(Cave),
    exploring: *std.ArrayList(*Cave),
    visited: *std.StringHashMap(usize),
    finals: *std.ArrayList(std.ArrayList(*Cave)),
    doubled: bool,
) !void {
    var cave = exploring.items[exploring.items.len - 1];
    if (std.mem.eql(u8, cave.name, "end")) {
        var final = try exploring.clone();
        try finals.append(final);
        return;
    }
    for (cave.caves.items) |name| {
        var next = caves.getPtr(name).?;
        const visits = visited.get(next.name) orelse 0;
        var dbl = doubled;
        if (next.small() and visits > 0) {
            if (std.mem.eql(u8, next.name, "start")) continue;
            if (doubled) continue;
            dbl = true;
        }
        try visited.put(next.name, visits + 1);
        try exploring.append(next);
        try explore(caves, exploring, visited, finals, dbl);
        _ = exploring.pop();
        try visited.put(next.name, visits);
    }
}
