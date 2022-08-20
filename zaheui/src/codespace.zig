const std = @import("std");
const Hangul = @import("hangul.zig").Hangul;

const STDIN_MAX_SIZE = 256 * 1024 * 1024;

pub const Codespace = struct {
    allocator: std.mem.Allocator,
    width: usize,
    height: usize,
    space: Space,
    stdin: ?std.unicode.Utf8Iterator = null,

    // Cursor properties
    x: usize = 0,
    y: usize = 0,
    vx: i4 = 0,
    vy: i4 = 1,

    // Storage properties
    last: Hangul.Last = .@" ",
    storages: [27]Storage,

    const Row = std.ArrayList(?Hangul);
    const Space = std.ArrayList(Row);
    const Storage = std.ArrayList(i128);

    pub fn init(allocator: std.mem.Allocator, code: []u8) !Codespace {
        var width: usize = 0;
        var height: usize = 0;

        var space = Space.init(allocator);
        if (code.len > 0) {
            var row = Row.init(allocator);
            var codepointIterator = (try std.unicode.Utf8View.init(code)).iterator();

            while (codepointIterator.nextCodepoint()) |codepoint| {
                var newline = false;

                if (codepoint == '\r') {
                    const next = codepointIterator.peek(1);
                    if (next.len > 0 and (std.unicode.utf8Decode(next) catch 0) == '\n') {
                        _ = codepointIterator.nextCodepoint();
                        newline = true;
                    }
                }

                if (codepoint == '\n') {
                    newline = true;
                }

                if (newline) {
                    try space.append(row);
                    height += 1;
                    if (width < row.items.len) {
                        width = row.items.len;
                    }

                    row = Row.init(allocator);
                } else {
                    const hangul = Hangul.fromInt(codepoint);
                    try row.append(hangul);
                }
            }

            try space.append(row);
            height += 1;
            if (width < row.items.len) {
                width = row.items.len;
            }
        }

        var storages: [27]Storage = .{undefined} ** 27;
        var i: usize = 0;
        while (i < 27) : (i += 1) {
            storages[i] = Storage.init(allocator);
        }

        return Codespace{
            .allocator = allocator,
            .width = width,
            .height = height,
            .space = space,
            .storages = storages,
        };
    }

    fn at(self: *Codespace, x: usize, y: usize) ?Hangul {
        if (y >= self.space.items.len) {
            return null;
        }
        const row = self.space.items[y];
        if (x >= row.items.len) {
            return null;
        }
        return row.items[x];
    }

    pub fn deinit(self: *Codespace) void {
        for (self.space.toOwnedSlice()) |row| {
            row.deinit();
        }
        self.space.deinit();
    }

    fn currentStorage(self: *Codespace) !*Storage {
        if (self.last == .@"ㅎ") {
            return error.@"통로 NotImplemented";
        }
        return &self.storages[@enumToInt(self.last)];
    }

    fn countCurrentStorage(self: *Codespace) !usize {
        var storage = try self.currentStorage();
        return storage.items.len;
    }

    fn peekCurrentStorage(self: *Codespace) !?i128 {
        var storage = try self.currentStorage();
        if (storage.items.len == 0) {
            return null;
        }
        if (self.last == .@"ㅇ") {
            return storage.items[0];
        }
        return storage.items[storage.items.len - 1];
    }

    fn swapCurrentStorage(self: *Codespace) !bool {
        var storage = try self.currentStorage();
        if (storage.items.len < 2) {
            return false;
        }
        if (self.last == .@"ㅇ") {
            const first = storage.items[0];
            storage.items[0] = storage.items[1];
            storage.items[1] = first;
        } else {
            const last = storage.items[storage.items.len - 1];
            storage.items[storage.items.len - 1] = storage.items[storage.items.len - 2];
            storage.items[storage.items.len - 2] = last;
        }
        return true;
    }

    fn popCurrentStorage(self: *Codespace) !?i128 {
        var storage = try self.currentStorage();
        if (storage.items.len == 0) {
            return null;
        }

        if (self.last == .@"ㅇ") {
            return storage.orderedRemove(0);
        } else {
            return storage.pop();
        }
    }

    fn appendCurrentStorage(self: *Codespace, value: i128) !void {
        var storage = try self.currentStorage();
        try storage.append(value);
    }

    fn appendStorage(self: *Codespace, last: Hangul.Last, value: i128) !void {
        if (last == .@"ㅎ") {
            return error.@"통로 NotImplemented";
        }
        var storage = &self.storages[@enumToInt(last)];
        try storage.append(value);
    }

    fn doubleCurrentStorage(self: *Codespace) !?i128 {
        var storage = try self.currentStorage();
        if (storage.items.len == 0) {
            return null;
        }

        if (self.last == .@"ㅇ") {
            const value = storage.items[0];
            try storage.insert(0, value);
            return value;
        } else {
            const value = storage.items[storage.items.len - 1];
            try storage.append(value);
            return value;
        }
    }

    fn advance(self: *Codespace) void {
        var cursorX: i32 = @intCast(i32, self.x);
        cursorX += self.vx;
        if (cursorX < 0) {
            cursorX = @intCast(i32, self.width) - 1;
        }
        if (cursorX >= self.width) {
            cursorX = 0;
        }
        self.x = @intCast(usize, cursorX);

        var cursorY: i32 = @intCast(i32, self.y);
        cursorY += self.vy;
        if (cursorY < 0) {
            cursorY = @intCast(i32, self.height) - 1;
        }
        if (cursorY >= self.height) {
            cursorY = 0;
        }
        self.y = @intCast(usize, cursorY);
    }

    fn back(self: *Codespace) void {
        if (self.vx > 0) {
            self.vx = -1;
        } else if (self.vx < 0) {
            self.vx = 1;
        }

        if (self.vy > 0) {
            self.vy = -1;
        } else if (self.vy < 0) {
            self.vy = 1;
        }

        self.advance();
    }

    pub fn run(self: *Codespace) !void {
        while (true) {
            const current = self.at(self.x, self.y);

            if (current) |hangul| {
                const middle = hangul.middle;
                self.vx = middle.getXSpeed().apply(self.vx);
                self.vy = middle.getYSpeed().apply(self.vy);

                const first = hangul.first;
                switch (first) {
                    // Noop
                    .Other => {},
                    // Terminate
                    .@"ㅎ" => {
                        const value = (try self.popCurrentStorage()) orelse 0;
                        std.os.exit(@intCast(u8, @mod(value, 256)));
                    },
                    // Arithmetics
                    .@"ㄷ", .@"ㄸ", .@"ㅌ", .@"ㄴ", .@"ㄹ" => {
                        const len = try self.countCurrentStorage();
                        if (len >= 2) {
                            const rhs = (try self.popCurrentStorage()).?;
                            const lhs = (try self.popCurrentStorage()).?;
                            const result = switch (first) {
                                .@"ㄷ" => lhs + rhs,
                                .@"ㄸ" => lhs * rhs,
                                .@"ㅌ" => lhs - rhs,
                                .@"ㄴ" => @divFloor(lhs, rhs),
                                .@"ㄹ" => @mod(lhs, rhs),
                                else => unreachable,
                            };
                            try self.appendCurrentStorage(result);
                        } else {
                            self.back();
                            continue;
                        }
                    },
                    // Storing
                    .@"ㅁ" => {
                        const maybeValue = try self.popCurrentStorage();
                        if (maybeValue) |value| {
                            const last = hangul.last;
                            switch (last) {
                                .@"ㅇ" => {
                                    try Codespace.write(value, false);
                                },
                                .@"ㅎ" => {
                                    try Codespace.write(value, true);
                                },
                                else => {},
                            }
                        } else {
                            self.back();
                            continue;
                        }
                    },
                    .@"ㅂ" => {
                        const last = hangul.last;
                        switch (last) {
                            .@"ㅇ" => {
                                const value = blk: {
                                    var list = std.ArrayList(u8).init(self.allocator);

                                    if (self.stdin == null) {
                                        const reader = std.io.getStdIn().reader();
                                        var buffer = try reader.readAllAlloc(self.allocator, STDIN_MAX_SIZE);
                                        var stdin = (try std.unicode.Utf8View.init(buffer)).iterator();
                                        self.stdin = stdin;
                                    }

                                    while (true) {
                                        var stdin = &self.stdin.?;

                                        var next = stdin.peek(1);
                                        if (next.len == 1 and ((next[0] >= '0' and next[0] <= '9') or next[0] == '-')) {
                                            _ = stdin.nextCodepointSlice();
                                            try list.append(next[0]);
                                        } else {
                                            while (next.len == 1 and (next[0] == ' ' or next[0] == '\r' or next[0] == '\n')) {
                                                _ = stdin.nextCodepointSlice();
                                                next = stdin.peek(1);
                                            }
                                            const slice = list.toOwnedSlice();
                                            if (slice.len == 0) {
                                                break :blk @as(i128, -1);
                                            } else {
                                                break :blk (try std.fmt.parseInt(i128, slice, 10));
                                            }
                                        }
                                    }
                                };
                                try self.appendCurrentStorage(value);
                            },
                            // TODO: Implement
                            .@"ㅎ" => {
                                if (self.stdin == null) {
                                    const reader = std.io.getStdIn().reader();
                                    var buffer = try reader.readAllAlloc(self.allocator, STDIN_MAX_SIZE);
                                    var stdin = (try std.unicode.Utf8View.init(buffer)).iterator();
                                    self.stdin = stdin;
                                }

                                const value = blk: {
                                    var stdin = &self.stdin.?;
                                    const next = stdin.peek(1);
                                    if (next.len == 0) {
                                        break :blk 0;
                                    } else {
                                        _ = stdin.nextCodepointSlice();
                                        break :blk @as(i128, try std.unicode.utf8Decode(next));
                                    }
                                };
                                try self.appendCurrentStorage(value);
                            },
                            else => {
                                const value: i128 = last.getStrokeCount();
                                try self.appendCurrentStorage(value);
                            },
                        }
                    },
                    .@"ㅃ" => {
                        if ((try self.doubleCurrentStorage()) == null) {
                            self.back();
                            continue;
                        }
                    },
                    .@"ㅍ" => {
                        const result = try self.swapCurrentStorage();
                        if (!result) {
                            self.back();
                            continue;
                        }
                    },
                    // Controls
                    .@"ㅅ" => {
                        self.last = hangul.last;
                    },
                    .@"ㅆ" => {
                        const maybeValue = try self.popCurrentStorage();
                        if (maybeValue) |value| {
                            try self.appendStorage(hangul.last, value);
                        } else {
                            self.back();
                            continue;
                        }
                    },
                    .@"ㅈ" => {
                        const len = try self.countCurrentStorage();
                        if (len >= 2) {
                            const rhs = (try self.popCurrentStorage()).?;
                            const lhs = (try self.popCurrentStorage()).?;
                            const result: i128 = if (lhs >= rhs) 1 else 0;
                            try self.appendCurrentStorage(result);
                        } else {
                            self.back();
                            continue;
                        }
                    },
                    .@"ㅊ" => {
                        const maybeValue = try self.popCurrentStorage();
                        if (maybeValue) |value| {
                            if (value == 0) {
                                self.vx *= -1;
                                self.vy *= -1;
                            }
                        } else {
                            self.back();
                            continue;
                        }
                    },
                }
            }

            // self.printStorages();
            self.advance();
        }
    }

    fn write(value: i128, unicode: bool) !void {
        const stdout = std.io.getStdOut().writer();
        if (unicode) {
            if (value < 0) {
                return error.CodepointNegative;
            }
            var character: [4]u8 = undefined;
            const len = try std.unicode.utf8Encode(@intCast(u21, value), character[0..]);
            try stdout.print("{s}", .{character[0..len]});
        } else {
            try stdout.print("{}", .{value});
        }
    }

    // For debug use
    fn print(self: *Codespace) !void {
        for (self.space.items) |row| {
            for (row.items) |value| {
                if (value) |v| {
                    var character: [4]u8 = undefined;
                    const len = try v.toUnicode(character[0..]);
                    std.debug.print("{s} ", .{character[0..len]});
                } else {
                    std.debug.print("null ", .{});
                }
            }
            std.debug.print("\n", .{});
        }
    }

    fn printStorages(self: *Codespace) void {
        for (self.storages) |*storage, index| {
            if (storage.items.len == 0) continue;

            std.debug.print("> {any}: ", .{@intToEnum(Hangul.Last, index)});
            for (storage.items) |value| {
                std.debug.print("{any}, ", .{value});
            }
            std.debug.print("\n", .{});
        }
    }
};
