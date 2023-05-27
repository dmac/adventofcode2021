const std = @import("std");

const input = @embedFile("11.txt");

const Octopus = struct {
    energy: isize,
    flashed: bool = false,
};

const Grid = struct {
    items: []Octopus,
    rows: usize,
    cols: usize,
    flashes: usize = 0,

    fn at(self: Grid, row: usize, col: usize) *Octopus {
        return &self.items[row * self.cols + col];
    }

    fn flash(self: *Grid, row: usize, col: usize) void {
        var oct = self.at(row, col);
        std.debug.assert(!oct.flashed);
        oct.flashed = true;
        self.flashes += 1;
        const deltas = [_][2]isize{
            .{ -1, -1 },
            .{ -1, 0 },
            .{ -1, 1 },
            .{ 0, -1 },
            .{ 0, 1 },
            .{ 1, -1 },
            .{ 1, 0 },
            .{ 1, 1 },
        };
        for (deltas) |delta| {
            const nrow_s = @intCast(isize, row) + delta[0];
            const ncol_s = @intCast(isize, col) + delta[1];
            if (nrow_s < 0 or nrow_s >= self.rows or
                ncol_s < 0 or ncol_s >= self.cols)
            {
                continue;
            }
            const nrow = @intCast(usize, nrow_s);
            const ncol = @intCast(usize, ncol_s);
            var noct = self.at(nrow, ncol);
            noct.energy += 1;
            if (noct.energy > 9 and !noct.flashed) {
                self.flash(nrow, ncol);
            }
        }
    }

    fn print(self: Grid) void {
        for (self.items, 0..) |oct, i| {
            if (i > 0 and i % self.cols == 0) {
                std.debug.print("\n", .{});
            }
            std.debug.print("{d}", .{oct.energy});
        }
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const rows = std.mem.count(u8, input, "\n");
    const cols = std.mem.indexOf(u8, input, "\n").?;
    var backing = try allocator.alloc(Octopus, rows * cols);
    {
        var i: usize = 0;
        for (input) |c| {
            if (!std.ascii.isDigit(c)) continue;
            backing[i] = Octopus{ .energy = c - '0' };
            i += 1;
        }
        std.debug.assert(i == backing.len);
    }
    var grid = Grid{ .items = backing, .rows = rows, .cols = cols };
    var step: isize = 0;
    sim: while (true) : (step += 1) {
        for (grid.items) |*oct| {
            oct.flashed = false;
            oct.energy += 1;
        }
        for (grid.items, 0..) |*oct, i| {
            if (oct.energy > 9 and !oct.flashed) {
                const row: usize = i / cols;
                const col: usize = i % cols;
                grid.flash(row, col);
            }
        }
        for (grid.items) |*oct| {
            if (oct.flashed) {
                oct.energy = 0;
            }
        }
        // Part 1
        if (step + 1 == 100) {
            std.debug.print("{d}\n", .{grid.flashes});
        }
        // Part 2
        for (grid.items) |oct| {
            if (!oct.flashed) break;
        } else {
            std.debug.print("{d}\n", .{step + 1});
            break :sim;
        }
    }
}
