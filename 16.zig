const std = @import("std");

const input = @embedFile("16.txt");
// const input = "D2FE28";
// const input = "38006F45291200";
// const input = "EE00D40C823060";

const Packet = struct {
    version: u8,
    type_id: u8,
    value: usize,
    packets: std.ArrayList(Packet),

    pub fn parse(allocator: std.mem.Allocator, bp: *[]const u8) !Packet {
        var b = bp.*;
        defer bp.* = b;
        var p = Packet{
            .version = (b[0] - '0') << 2 | (b[1] - '0') << 1 | b[2] - '0',
            .type_id = (b[3] - '0') << 2 | (b[4] - '0') << 1 | b[5] - '0',
            .value = 0,
            .packets = std.ArrayList(Packet).init(allocator),
        };
        b = b[6..];
        if (p.type_id == 4) {
            p.parseLiteral(&b);
        } else {
            try p.parseOperator(allocator, &b);
        }
        return p;
    }

    fn parseLiteral(self: *@This(), bp: *[]const u8) void {
        var b = bp.*;
        defer bp.* = b;
        // process groups of 5 bits
        while (true) {
            const done = b[0] == '0';
            self.value = self.value * 2 + b[1] - '0';
            self.value = self.value * 2 + b[2] - '0';
            self.value = self.value * 2 + b[3] - '0';
            self.value = self.value * 2 + b[4] - '0';
            b = b[5..];
            if (done) {
                break;
            }
        }
    }

    fn parseOperator(self: *@This(), allocator: std.mem.Allocator, bp: *[]const u8) !void {
        var b = bp.*;
        defer bp.* = b;
        const length_type = b[0] - '0';
        b = b[1..];
        const length = blk: {
            const n: u8 = if (length_type == 0) 15 else 11;
            var l: u16 = 0;
            for (b[0..n]) |c| {
                l = l * 2 + c - '0';
            }
            b = b[n..];
            break :blk l;
        };
        if (length_type == 0) {
            try self.parseOperatorBitCount(allocator, &b, length);
        } else {
            try self.parseOperatorSubPacketCount(allocator, &b, length);
        }
        switch (self.type_id) {
            0 => {
                for (self.packets.items) |p| self.value += p.value;
            },
            1 => {
                self.value = 1;
                for (self.packets.items) |p| self.value *= p.value;
            },
            2 => {
                self.value = self.packets.items[0].value;
                for (self.packets.items[1..]) |p| {
                    self.value = std.math.min(self.value, p.value);
                }
            },
            3 => {
                self.value = self.packets.items[0].value;
                for (self.packets.items[1..]) |p| {
                    self.value = std.math.max(self.value, p.value);
                }
            },
            5 => {
                if (self.packets.items[0].value > self.packets.items[1].value) {
                    self.value = 1;
                }
            },
            6 => {
                if (self.packets.items[0].value < self.packets.items[1].value) {
                    self.value = 1;
                }
            },
            7 => {
                if (self.packets.items[0].value == self.packets.items[1].value) {
                    self.value = 1;
                }
            },
            else => unreachable,
        }
    }

    fn parseOperatorBitCount(self: *@This(), allocator: std.mem.Allocator, bp: *[]const u8, length: u16) std.mem.Allocator.Error!void {
        var b = bp.*;
        defer bp.* = b;
        var consumed: usize = 0;
        while (consumed < length) {
            const old_len = b.len;
            const p = try Packet.parse(allocator, &b);
            try self.packets.append(p);
            consumed += old_len - b.len;
        }
    }

    fn parseOperatorSubPacketCount(self: *@This(), allocator: std.mem.Allocator, bp: *[]const u8, length: u16) std.mem.Allocator.Error!void {
        var b = bp.*;
        defer bp.* = b;
        for (0..length) |_| {
            const p = try Packet.parse(allocator, &b);
            try self.packets.append(p);
        }
    }

    pub fn sum_versions(self: @This()) usize {
        var versions: usize = self.version;
        for (self.packets.items) |p| {
            versions += p.sum_versions();
        }
        return versions;
    }

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try std.fmt.format(writer, "Packet{{ .version={d}, .type_id={d}, .value={d}, .packets.items.len={d} }}", .{
            self.version,
            self.type_id,
            self.value,
            self.packets.items.len,
        });
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var binary = std.ArrayList(u8).init(allocator);
    for (std.mem.trim(u8, input, "\r\n")) |c| {
        const n = try std.fmt.parseInt(u8, &[_]u8{c}, 16);
        try std.fmt.format(binary.writer(), "{b:0>4}", .{n});
    }

    const b = &binary.items;
    const p = try Packet.parse(allocator, b);

    std.debug.print("{d}\n", .{p.sum_versions()});
    std.debug.print("{d}\n", .{p.value});
}
