const std = @import("std");

const input = @embedFile("04.txt");

const Board = struct {
    id: isize,
    items: [5][5]isize = .{.{0} ** 5} ** 5,
    hits: [5][5]bool = .{.{false} ** 5} ** 5,

    fn mark(self: *Board, n: isize) void {
        for (0..5) |row| {
            for (0..5) |col| {
                if (self.items[row][col] == n) {
                    self.hits[row][col] = true;
                    return;
                }
            }
        }
    }

    fn won(self: Board) bool {
        rowblk: for (0..5) |row| {
            for (0..5) |col| {
                if (!self.hits[row][col]) {
                    continue :rowblk;
                }
            }
            return true;
        }

        colblk: for (0..5) |col| {
            for (0..5) |row| {
                if (!self.hits[row][col]) {
                    continue :colblk;
                }
            }
            return true;
        }
        return false;
    }

    fn score(self: Board) isize {
        var scr: isize = 0;
        for (0..5) |row| {
            for (0..5) |col| {
                if (!self.hits[row][col]) {
                    scr += self.items[row][col];
                }
            }
        }
        return scr;
    }

    fn reset(self: *Board) void {
        self.hits = std.mem.zeroes(@TypeOf(self.hits));
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = std.ArrayList([]const u8).init(allocator);
    {
        var it = std.mem.split(u8, input, "\n");
        while (it.next()) |line| {
            try lines.append(line);
        }
    }

    var numbers = std.ArrayList(isize).init(allocator);
    {
        var it = std.mem.split(u8, lines.items[0], ",");
        while (it.next()) |s| {
            const n = try std.fmt.parseInt(isize, s, 10);
            try numbers.append(n);
        }
    }

    var boards = std.ArrayList(Board).init(allocator);
    {
        var id: isize = 1;
        var board = Board{ .id = id };
        var row: usize = 0;
        var col: usize = 0;
        for (lines.items[2..]) |line| {
            if (std.mem.eql(u8, line, "")) {
                try boards.append(board);
                id = id + 1;
                board = Board{ .id = id };
                row = 0;
                col = 0;
                continue;
            }
            var it = std.mem.tokenize(u8, line, " ");
            while (it.next()) |s| {
                const n = try std.fmt.parseInt(isize, s, 10);
                board.items[row][col] = n;
                col += 1;
            }
            row += 1;
            col = 0;
        }
    }

    // Part 1
    outer: for (numbers.items) |n| {
        for (boards.items) |*board| {
            board.mark(n);
            if (board.won()) {
                std.debug.print("{}\n", .{board.score() * n});
                break :outer;
            }
        }
    }

    // Part 2
    var playing = std.ArrayList(*Board).init(allocator);
    for (boards.items) |*board| {
        board.reset();
        try playing.append(board);
    }
    for (numbers.items) |n| {
        var i: usize = 0;
        while (i < playing.items.len) {
            var board = playing.items[i];
            board.mark(n);
            if (board.won()) {
                _ = playing.swapRemove(i);
                if (playing.items.len == 0) {
                    std.debug.print("{}\n", .{board.score() * n});
                }
                continue;
            }
            i += 1;
        }
    }
}
