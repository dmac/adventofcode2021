const std = @import("std");

const input = std.mem.trim(u8, @embedFile("08.txt"), "\n");

//  AAAA
// B    C
// B    C
//  DDDD
// E    F
// E    F
//  GGGG
//
// 1. Get A by finding letter in 3-segment but not in 2-segment.
// 2. Get B and D from 4-segment not in 1-segment: B appears in 6 digits, D in 7.
// 3. Get G from 6-segment digit with A+B+D + 2-segment (9); remainder is G.
// 4. Get F from 5-segment digit with A+B+D+G (5); remainder is F.
// 5. Get C from 2-segment digit with F (1); remainder is C.
// 6. Get E as final signal.

const Entry = struct {
    patterns: [10][]const u8 = std.mem.zeroes([10][]const u8),
    outputs: [4][]const u8 = std.mem.zeroes([4][]const u8),
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    var entries = std.ArrayList(Entry).init(allocator);
    {
        var it = std.mem.split(u8, input, "\n");
        while (it.next()) |line| {
            var entry = Entry{};
            const pipe = std.mem.indexOf(u8, line, "|").?;
            var pattern_it = std.mem.tokenize(u8, line[0..pipe], " ");
            var i: usize = 0;
            while (pattern_it.next()) |pat| {
                entry.patterns[i] = pat;
                i += 1;
            }
            std.debug.assert(i == 10);
            i = 0;
            var output_it = std.mem.tokenize(u8, line[pipe + 1 ..], " ");
            while (output_it.next()) |output| {
                entry.outputs[i] = output;
                i += 1;
            }
            std.debug.assert(i == 4);
            try entries.append(entry);
        }
    }
    var count: isize = 0;
    var sum: isize = 0;
    for (entries.items) |entry| {
        const sigA = findA(entry.patterns);
        const sigBD = findBD(entry.patterns);
        const sigB = sigBD[0];
        const sigD = sigBD[1];
        const sigG = findG(entry.patterns, sigA, sigB, sigD);
        const sigF = findF(entry.patterns, sigA, sigB, sigD, sigG);
        const sigC = findC(entry.patterns, sigF);
        const sigE = findE(sigA, sigB, sigC, sigD, sigF, sigG);
        const soln = [_]u8{ sigA, sigB, sigC, sigD, sigE, sigF, sigG };
        // std.debug.print("{s}\n", .{soln});
        for (entry.outputs, 0..) |output, i| {
            count += switch (output.len) {
                2, 3, 4, 7 => 1,
                else => 0,
            };
            const mask = outputToMask(output, &soln);
            const digit = maskToDigit(mask);
            // std.debug.print("soln={s} output={s} mask={b} digit={d}\n", .{ soln, output, mask, digit });
            const mag: isize = switch (i) {
                0 => 1000,
                1 => 100,
                2 => 10,
                3 => 1,
                else => unreachable,
            };
            sum += digit * mag;
        }
    }
    std.debug.print("{d}\n", .{count});
    std.debug.print("{d}\n", .{sum});
}

fn outputToMask(output: []const u8, soln: []const u8) u8 {
    var mask: u7 = 0;
    for (output) |c| {
        if (c == soln[0]) {
            mask |= (1 << 6);
        } else if (c == soln[1]) {
            mask |= (1 << 5);
        } else if (c == soln[2]) {
            mask |= (1 << 4);
        } else if (c == soln[3]) {
            mask |= (1 << 3);
        } else if (c == soln[4]) {
            mask |= (1 << 2);
        } else if (c == soln[5]) {
            mask |= (1 << 1);
        } else if (c == soln[6]) {
            mask |= (1 << 0);
        } else {
            unreachable;
        }
    }
    return mask;
}

fn maskToDigit(mask: u8) u8 {
    return switch (mask) {
        0b1110111 => 0,
        0b0010010 => 1,
        0b1011101 => 2,
        0b1011011 => 3,
        0b0111010 => 4,
        0b1101011 => 5,
        0b1101111 => 6,
        0b1010010 => 7,
        0b1111111 => 8,
        0b1111011 => 9,
        else => unreachable,
    };
}

// 1. Get A by finding letter in 3-segment but not in 2-segment.
fn findA(patterns: [10][]const u8) u8 {
    var pat2: []const u8 = "";
    var pat3: []const u8 = "";
    for (patterns) |pat| {
        if (pat.len == 2) {
            pat2 = pat;
        }
        if (pat.len == 3) {
            pat3 = pat;
        }
    }
    needle: for (pat3) |needle| {
        for (pat2) |c| {
            if (needle == c) {
                continue :needle;
            }
        } else {
            return needle;
        }
    }
    std.debug.print("pat2={s} pat3={s}\n", .{ pat2, pat3 });
    @panic("unable to find A");
}

// 2. Get B and D from 4-segment not in 2-segment: B appears in 6 digits, D in 7.
fn findBD(patterns: [10][]const u8) [2]u8 {
    var pat2: []const u8 = "";
    var pat4: []const u8 = "";
    for (patterns) |pat| {
        if (pat.len == 2) {
            pat2 = pat;
        }
        if (pat.len == 4) {
            pat4 = pat;
        }
    }
    var candidates = [_]u8{ 0, 0 };
    var idx: usize = 0;
    needle: for (pat4) |needle| {
        for (pat2) |c| {
            if (needle == c) {
                continue :needle;
            }
        } else {
            candidates[idx] = needle;
            idx += 1;
        }
    }
    var count0: isize = 0;
    for (patterns) |pat| {
        if (std.mem.indexOfScalar(u8, pat, candidates[0])) |_| {
            count0 += 1;
        }
    }
    if (count0 == 7) {
        const tmp = candidates[0];
        candidates[0] = candidates[1];
        candidates[1] = tmp;
    } else {
        std.debug.assert(count0 == 6);
    }

    return candidates;
}

// 3. Get G from 6-segment digit with A+B+D + 2-segment (9); remainder is G.
fn findG(patterns: [10][]const u8, sigA: u8, sigB: u8, sigD: u8) u8 {
    var pat2: []const u8 = "";
    for (patterns) |pat| {
        if (pat.len == 2) {
            pat2 = pat;
        }
    }
    for (patterns) |pat| {
        if (pat.len != 6) continue;
        if (!hasSignal(pat, sigA)) continue;
        if (!hasSignal(pat, sigB)) continue;
        if (!hasSignal(pat, sigD)) continue;
        if (!hasSignal(pat, pat2[0])) continue;
        if (!hasSignal(pat, pat2[1])) continue;
        for (pat) |c| {
            if (c == sigA) continue;
            if (c == sigB) continue;
            if (c == sigD) continue;
            if (c == pat2[0]) continue;
            if (c == pat2[1]) continue;
            return c;
        }
    }
    unreachable;
}

// 4. Get F from 5-segment digit with A+B+D+G (5); remainder is F.
fn findF(patterns: [10][]const u8, sigA: u8, sigB: u8, sigD: u8, sigG: u8) u8 {
    for (patterns) |pat| {
        if (pat.len != 5) continue;
        if (!hasSignal(pat, sigA)) continue;
        if (!hasSignal(pat, sigB)) continue;
        if (!hasSignal(pat, sigD)) continue;
        if (!hasSignal(pat, sigG)) continue;
        for (pat) |c| {
            if (c == sigA) continue;
            if (c == sigB) continue;
            if (c == sigD) continue;
            if (c == sigG) continue;
            return c;
        }
    }
    unreachable;
}

// 5. Get C from 2-segment digit with F (1); remainder is C.
fn findC(patterns: [10][]const u8, sigF: u8) u8 {
    for (patterns) |pat| {
        if (pat.len != 2) continue;
        for (pat) |c| {
            if (c == sigF) continue;
            return c;
        }
    }
    unreachable;
}

// 5. Get E as final signal.
fn findE(sigA: u8, sigB: u8, sigC: u8, sigD: u8, sigF: u8, sigG: u8) u8 {
    for ("abcdefg") |c| {
        if (c == sigA) continue;
        if (c == sigB) continue;
        if (c == sigC) continue;
        if (c == sigD) continue;
        if (c == sigF) continue;
        if (c == sigG) continue;
        return c;
    }
    unreachable;
}

fn hasSignal(pat: []const u8, sig: u8) bool {
    return std.mem.indexOfScalar(u8, pat, sig) != null;
}
