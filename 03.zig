const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = &arena.allocator;

    const f = try std.fs.cwd().openFile("03.txt", .{});
    defer f.close();

    var len: usize = 0;
    var zeroes = [_]i32{0} ** 32;
    var ones = [_]i32{0} ** 32;

    var o2Candidates = std.ArrayList(u32).init(allocator);
    var co2Candidates = std.ArrayList(u32).init(allocator);

    const reader = std.io.bufferedReader(f.reader()).reader();
    var buf: [32]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        len = line.len;
        var val: u32 = 0;
        for (line) |c, i| {
            if (c == '0') {
                zeroes[i] += 1;
            } else {
                val |= @intCast(u32, 1) << @intCast(u5, len - i - 1);
                ones[i] += 1;
            }
        }
        try o2Candidates.append(val);
        try co2Candidates.append(val);
    }

    var gamma: u32 = 0;
    var epsilon: u32 = 0;

    var i: usize = 0;
    while (i < len) : (i += 1) {
        if (ones[i] > zeroes[i]) {
            // Awkward RHS bit shift casting: https://github.com/ziglang/zig/issues/7605
            gamma |= @intCast(u32, 1) << @intCast(u5, len - i - 1);
        } else {
            epsilon |= @intCast(u32, 1) << @intCast(u5, len - i - 1);
        }
    }

    std.debug.print("gamma({}) * epsilon({}) = {}\n", .{ gamma, epsilon, gamma * epsilon });

    var pos: u32 = 0;
    while (o2Candidates.items.len > 1) : (pos += 1) {
        const mfbOneOrEven = mostFrequentBitOneOrEven(o2Candidates, pos, len);
        i = 0;
        while (i < o2Candidates.items.len) {
            const n = o2Candidates.items[i];
            const one: bool = (n & @intCast(u32, 1) << @intCast(u5, len - pos - 1)) > 0;
            if ((one and mfbOneOrEven) or (!one and !mfbOneOrEven)) {
                i += 1;
                continue;
            }
            _ = o2Candidates.swapRemove(i);
        }
    }
    const o2 = o2Candidates.items[0];

    pos = 0;
    while (co2Candidates.items.len > 1) : (pos += 1) {
        const lfbZeroOrEven = leastFrequentBitZeroOrEven(co2Candidates, pos, len);
        i = 0;
        while (i < co2Candidates.items.len) {
            const n = co2Candidates.items[i];
            const one: bool = (n & @intCast(u32, 1) << @intCast(u5, len - pos - 1)) > 0;
            if ((!one and lfbZeroOrEven) or (one and !lfbZeroOrEven)) {
                i += 1;
                continue;
            }
            _ = co2Candidates.swapRemove(i);
        }
    }
    const co2 = co2Candidates.items[0];

    std.debug.print("o2({}) * co2({}) = {}\n", .{ o2, co2, o2 * co2 });
}

fn mostFrequentBitOneOrEven(list: std.ArrayList(u32), pos: u32, len: usize) bool {
    var zeroes: i32 = 0;
    var ones: i32 = 0;
    for (list.items) |n| {
        const one: bool = (n & @intCast(u32, 1) << @intCast(u5, len - pos - 1)) > 0;
        if (one) {
            ones += 1;
        } else {
            zeroes += 1;
        }
    }
    return ones >= zeroes;
}

fn leastFrequentBitZeroOrEven(list: std.ArrayList(u32), pos: u32, len: usize) bool {
    var zeroes: i32 = 0;
    var ones: i32 = 0;
    for (list.items) |n| {
        const one: bool = (n & @intCast(u32, 1) << @intCast(u5, len - pos - 1)) > 0;
        if (one) {
            ones += 1;
        } else {
            zeroes += 1;
        }
    }
    return zeroes <= ones;
}
