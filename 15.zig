const std = @import("std");

const input = @embedFile("15.txt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const rows = std.mem.count(u8, input, "\n");
    const cols = std.mem.indexOfAny(u8, input, "\r\n").?;
    const grid = try allocator.alloc(u8, rows * cols);
    var lines = std.mem.tokenize(u8, input, "\r\n");
    {
        var row: usize = 0;
        while (lines.next()) |line| : (row += 1) {
            for (line, 0..) |c, col| {
                grid[row * cols + col] = c - '0';
            }
        }
    }
    std.debug.print("{d}\n", .{try searchGrid(allocator, grid, rows, cols)});

    const grid2 = try buildLargeGrid(allocator, grid, rows, cols);
    std.debug.print("{d}\n", .{try searchGrid(allocator, grid2, rows * 5, cols * 5)});
}

fn searchGrid(allocator: std.mem.Allocator, grid: []u8, rows: usize, cols: usize) !usize {
    var visited = try allocator.alloc(bool, rows * cols);
    @memset(visited, false);
    var risks = try allocator.alloc(usize, rows * cols);
    @memset(risks, std.math.maxInt(usize));
    risks[0] = 0;
    var unvisited = std.PriorityQueue(Node, void, riskCompare).init(allocator, {});
    for (0..risks.len) |i| {
        const node = Node{
            .index = i,
            .risk = risks[i],
        };
        try unvisited.add(node);
    }

    while (true) {
        var curr = unvisited.remove();
        visited[curr.index] = true;
        const row = @divTrunc(curr.index, rows);
        const col = @rem(curr.index, cols);
        if (row == rows - 1 and col == cols - 1) {
            return curr.risk;
        }
        const neighbors = [_][2]usize{
            .{ row -% 1, col },
            .{ row +% 1, col },
            .{ row, col -% 1 },
            .{ row, col +% 1 },
        };
        for (neighbors) |neighbor| {
            const r = neighbor[0];
            const c = neighbor[1];
            if (r >= 0 and
                r < rows and
                c >= 0 and
                c < cols and
                !visited[r * cols + c])
            {
                const index = r * cols + c;
                const prev_risk = risks[index];
                const next_risk = curr.risk + grid[index];
                if (next_risk < prev_risk) {
                    const prev = Node{
                        .index = index,
                        .risk = prev_risk,
                    };
                    const next = Node{
                        .index = index,
                        .risk = next_risk,
                    };
                    try unvisited.update(prev, next);
                    risks[index] = next_risk;
                }
            }
        }
    }
}

fn buildLargeGrid(allocator: std.mem.Allocator, orig_grid: []u8, orig_rows: usize, orig_cols: usize) ![]u8 {
    const rows = orig_rows * 5;
    const cols = orig_cols * 5;
    var grid = try allocator.alloc(u8, rows * cols);
    @memset(grid, 255);
    for (0..orig_rows) |orig_row| {
        for (0..orig_cols) |orig_col| {
            for (0..5) |dr| {
                for (0..5) |dc| {
                    const orig_risk = orig_grid[orig_row * orig_cols + orig_col];
                    const risk = @intCast(u8, @rem(orig_risk - 1 + dr + dc, 9) + 1);
                    const row = orig_row + (dr * orig_rows);
                    const col = orig_col + (dc * orig_cols);
                    grid[row * cols + col] = risk;
                }
            }
        }
    }
    return grid;
}

const Node = struct {
    index: usize,
    risk: usize,
};

fn riskCompare(_: void, a: Node, b: Node) std.math.Order {
    if (a.risk != b.risk) {
        return std.math.order(a.risk, b.risk);
    }
    return std.math.order(a.index, b.index);
}
