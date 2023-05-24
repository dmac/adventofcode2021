const std = @import("std");

pub fn main() !void {
    const f = try std.fs.cwd().openFile("02.txt", .{});
    defer f.close();

    var pos: i32 = 0;
    var depth1: i32 = 0;
    var depth2: i32 = 0;
    var aim: i32 = 0;

    var buf_reader = std.io.bufferedReader(f.reader());
    var buf: [32]u8 = undefined;
    while (try buf_reader.reader().readUntilDelimiterOrEof(buf[0..], '\n')) |line| {
        const dir = std.mem.sliceTo(line, ' ');
        const n = try std.fmt.parseInt(i32, line[dir.len + 1 ..], 10);
        if (std.mem.eql(u8, dir, "forward")) {
            pos += n;
            depth2 += aim * n;
        } else if (std.mem.eql(u8, dir, "up")) {
            depth1 -= n;
            aim -= n;
        } else if (std.mem.eql(u8, dir, "down")) {
            depth1 += n;
            aim += n;
        } else {
            unreachable;
        }
    }
    std.debug.print("pos({}) * depth1({}) = {}\n", .{ pos, depth1, pos * depth1 });
    std.debug.print("pos({}) * depth2({}) = {}\n", .{ pos, depth2, pos * depth2 });
}
