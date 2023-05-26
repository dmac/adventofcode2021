const std = @import("std");

const input = @embedFile("09.txt");

const Cell = struct {
    row: usize,
    col: usize,
    val: u8,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const rows = std.mem.count(u8, input, "\n");
    const cols = std.mem.indexOf(u8, input, "\n").?;
    var backing = try allocator.alloc(u8, rows * cols);
    {
        var i: usize = 0;
        for (input) |c| {
            if (!std.ascii.isDigit(c)) continue;
            const n = try std.fmt.parseInt(u8, &[_]u8{c}, 10);
            backing[i] = n;
            i += 1;
        }
        std.debug.assert(i == backing.len);
    }
    var grid = try allocator.alloc([]u8, rows);
    for (grid, 0..) |*row, i| {
        row.* = backing[i * cols .. i * cols + cols];
    }

    var lows = std.ArrayList(Cell).init(allocator);
    var row: usize = 0;
    while (row < grid.len) : (row += 1) {
        var col: usize = 0;
        while (col < grid[0].len) : (col += 1) {
            const n = grid[row][col];
            if (row > 0 and grid[row - 1][col] <= n) continue;
            if (row < grid.len - 1 and grid[row + 1][col] <= n) continue;
            if (col > 0 and grid[row][col - 1] <= n) continue;
            if (col < grid[0].len - 1 and grid[row][col + 1] <= n) continue;
            const cell = .{
                .row = row,
                .col = col,
                .val = n,
            };
            try lows.append(cell);
        }
    }

    var part1: usize = 0;
    for (lows.items) |low| part1 += low.val + 1;
    std.debug.print("{d}\n", .{part1});

    var fills = std.ArrayList(usize).init(allocator);
    for (lows.items) |low| {
        try fills.append(try fillBasin(allocator, grid, low));
    }
    std.sort.sort(usize, fills.items, {}, std.sort.desc(usize));
    std.debug.print("{d}\n", .{fills.items[0] * fills.items[1] * fills.items[2]});
}

fn fillBasin(allocator: std.mem.Allocator, grid: [][]u8, low: Cell) !usize {
    var visited = try allocator.alloc([]bool, grid.len);
    for (visited) |*row| {
        row.* = try allocator.alloc(bool, grid[0].len);
        @memset(row.*, false);
    }
    var size: usize = 0;
    var work = std.ArrayList(Cell).init(allocator);
    try work.append(low);
    while (work.items.len > 0) {
        var cell = work.pop();
        const deltas = [_][2]isize{
            .{ -1, 0 },
            .{ 1, 0 },
            .{ 0, -1 },
            .{ 0, 1 },
        };
        for (deltas) |delta| {
            const nrow_s = @intCast(isize, cell.row) + delta[0];
            const ncol_s = @intCast(isize, cell.col) + delta[1];
            if (nrow_s >= 0 and nrow_s < grid.len and ncol_s >= 0 and ncol_s < grid[0].len) {
                const nrow = @intCast(usize, nrow_s);
                const ncol = @intCast(usize, ncol_s);
                const next = Cell{
                    .row = nrow,
                    .col = ncol,
                    .val = grid[nrow][ncol],
                };
                if (!visited[nrow][ncol] and next.val < 9) {
                    visited[next.row][next.col] = true;
                    try work.append(next);
                    size += 1;
                }
            }
        }
    }
    return size;
}
