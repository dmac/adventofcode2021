const std = @import("std");

const input = std.mem.trim(u8, @embedFile("10.txt"), "\n");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var it = std.mem.split(u8, input, "\n");
    var incomplete_score: i64 = 0;
    var complete_scores = std.ArrayList(i64).init(allocator);
    while (it.next()) |line| {
        if (try firstIllegal(allocator, line)) |bad| {
            incomplete_score += switch (bad) {
                ')' => 3,
                ']' => 57,
                '}' => 1197,
                '>' => 25137,
                else => unreachable,
            };
            continue;
        }
        try complete_scores.append(try completeScore(allocator, line));
    }
    std.sort.sort(i64, complete_scores.items, {}, std.sort.asc(i64));
    const complete_median = complete_scores.items[@divTrunc(complete_scores.items.len, 2)];

    std.debug.print("{d}\n", .{incomplete_score});
    std.debug.print("{d}\n", .{complete_median});
}

fn firstIllegal(allocator: std.mem.Allocator, line: []const u8) !?u8 {
    var stack = try std.ArrayList(u8).initCapacity(allocator, line.len);
    for (line) |c| {
        switch (c) {
            '(', '[', '{', '<' => {
                stack.appendAssumeCapacity(c);
            },
            else => {
                var b = stack.pop();
                if (b == '(' and c != ')' or
                    b == '[' and c != ']' or
                    b == '{' and c != '}' or
                    b == '<' and c != '>')
                {
                    return c;
                }
            },
        }
    }
    return null;
}

fn completeScore(allocator: std.mem.Allocator, line: []const u8) !i64 {
    var stack = try std.ArrayList(u8).initCapacity(allocator, line.len);
    for (line) |c| {
        switch (c) {
            '(', '[', '{', '<' => {
                stack.appendAssumeCapacity(c);
            },
            else => {
                _ = stack.pop();
            },
        }
    }
    var score: i64 = 0;
    while (stack.popOrNull()) |c| {
        score *= 5;
        switch (c) {
            '(' => score += 1,
            '[' => score += 2,
            '{' => score += 3,
            '<' => score += 4,
            else => unreachable,
        }
    }
    return score;
}
