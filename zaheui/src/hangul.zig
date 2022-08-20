const std = @import("std");

pub const Hangul = struct {
    first: Hangul.First,
    middle: Hangul.Middle,
    last: Hangul.Last,

    pub const First = enum {
        // Noop
        Other,
        // Terminate
        @"ㅎ",
        // Arithmetics
        @"ㄷ",
        @"ㅌ",
        @"ㄸ",
        @"ㄴ",
        @"ㄹ",
        // Storing
        @"ㅁ",
        @"ㅂ",
        @"ㅃ",
        @"ㅍ",
        // Controls
        @"ㅅ",
        @"ㅆ",
        @"ㅈ",
        @"ㅊ",

        fn fromInt(int: u21) First {
            return switch (int) {
                2 => .@"ㄴ",
                3 => .@"ㄷ",
                4 => .@"ㄸ",
                5 => .@"ㄹ",
                6 => .@"ㅁ",
                7 => .@"ㅂ",
                8 => .@"ㅃ",
                9 => .@"ㅅ",
                10 => .@"ㅆ",
                12 => .@"ㅈ",
                14 => .@"ㅊ",
                16 => .@"ㅌ",
                17 => .@"ㅍ",
                18 => .@"ㅎ",
                else => .Other,
            };
        }

        fn toInt(first: First) u21 {
            return switch (first) {
                .@"ㄴ" => 2,
                .@"ㄷ" => 3,
                .@"ㄸ" => 4,
                .@"ㄹ" => 5,
                .@"ㅁ" => 6,
                .@"ㅂ" => 7,
                .@"ㅃ" => 8,
                .@"ㅅ" => 9,
                .@"ㅆ" => 10,
                .@"ㅈ" => 12,
                .@"ㅊ" => 14,
                .@"ㅌ" => 16,
                .@"ㅍ" => 17,
                .@"ㅎ" => 18,
                else => 11,
            };
        }
    };

    pub const Middle = enum {
        // Noop
        Other,
        // Single move
        @"ㅏ",
        @"ㅓ",
        @"ㅗ",
        @"ㅜ",
        // Double move
        @"ㅑ",
        @"ㅕ",
        @"ㅛ",
        @"ㅠ",
        // Reflections
        @"ㅣ",
        @"ㅡ",
        @"ㅢ",

        pub const Speed = union(enum) {
            Absolute: i4,
            Reflect,
            Noop,

            pub fn apply(self: Speed, speed: i4) i4 {
                return switch (self) {
                    Speed.Absolute => |s| s,
                    Speed.Reflect => -speed,
                    Speed.Noop => speed,
                };
            }
        };

        fn fromInt(int: u21) Middle {
            return switch (int) {
                0 => .@"ㅏ",
                2 => .@"ㅑ",
                4 => .@"ㅓ",
                6 => .@"ㅕ",
                8 => .@"ㅗ",
                12 => .@"ㅛ",
                13 => .@"ㅜ",
                17 => .@"ㅠ",
                18 => .@"ㅡ",
                19 => .@"ㅢ",
                20 => .@"ㅣ",
                else => .Other,
            };
        }
        fn toInt(middle: Middle) u21 {
            return switch (middle) {
                .@"ㅏ" => 0,
                .@"ㅑ" => 2,
                .@"ㅓ" => 4,
                .@"ㅕ" => 6,
                .@"ㅗ" => 8,
                .@"ㅛ" => 12,
                .@"ㅜ" => 13,
                .@"ㅠ" => 17,
                .@"ㅡ" => 18,
                .@"ㅢ" => 19,
                .@"ㅣ" => 20,
                .Other => 1,
            };
        }
        pub fn getXSpeed(self: Middle) Speed {
            return switch (self) {
                .Other => Speed.Noop,
                .@"ㅏ" => Speed{ .Absolute = 1 },
                .@"ㅓ" => Speed{ .Absolute = -1 },
                .@"ㅗ" => Speed{ .Absolute = 0 },
                .@"ㅜ" => Speed{ .Absolute = 0 },
                .@"ㅑ" => Speed{ .Absolute = 2 },
                .@"ㅕ" => Speed{ .Absolute = -2 },
                .@"ㅛ" => Speed{ .Absolute = 0 },
                .@"ㅠ" => Speed{ .Absolute = 0 },
                .@"ㅣ" => Speed.Reflect,
                .@"ㅡ" => Speed.Noop,
                .@"ㅢ" => Speed.Reflect,
            };
        }
        pub fn getYSpeed(self: Middle) Speed {
            return switch (self) {
                .Other => Speed.Noop,
                .@"ㅏ" => Speed{ .Absolute = 0 },
                .@"ㅓ" => Speed{ .Absolute = 0 },
                .@"ㅗ" => Speed{ .Absolute = -1 },
                .@"ㅜ" => Speed{ .Absolute = 1 },
                .@"ㅑ" => Speed{ .Absolute = 0 },
                .@"ㅕ" => Speed{ .Absolute = 0 },
                .@"ㅛ" => Speed{ .Absolute = -2 },
                .@"ㅠ" => Speed{ .Absolute = 2 },
                .@"ㅣ" => Speed.Noop,
                .@"ㅡ" => Speed.Reflect,
                .@"ㅢ" => Speed.Reflect,
            };
        }
    };

    pub const Last = enum {
        @" ",
        @"ㄱ",
        @"ㄲ",
        @"ㄳ",
        @"ㄴ",
        @"ㄵ",
        @"ㄶ",
        @"ㄷ",
        @"ㄹ",
        @"ㄺ",
        @"ㄻ",
        @"ㄼ",
        @"ㄽ",
        @"ㄾ",
        @"ㄿ",
        @"ㅀ",
        @"ㅁ",
        @"ㅂ",
        @"ㅄ",
        @"ㅅ",
        @"ㅆ",
        @"ㅇ",
        @"ㅈ",
        @"ㅊ",
        @"ㅋ",
        @"ㅌ",
        @"ㅍ",
        @"ㅎ",

        fn fromInt(int: u21) Last {
            return @intToEnum(Last, int);
        }
        fn toInt(last: Last) u21 {
            return @enumToInt(last);
        }
        pub fn getStrokeCount(self: Last) u4 {
            return switch (self) {
                .@" " => 0,
                .@"ㄱ" => 2,
                .@"ㄲ" => 4,
                .@"ㄳ" => 4,
                .@"ㄴ" => 2,
                .@"ㄵ" => 5,
                .@"ㄶ" => 5,
                .@"ㄷ" => 3,
                .@"ㄹ" => 5,
                .@"ㄺ" => 7,
                .@"ㄻ" => 9,
                .@"ㄼ" => 9,
                .@"ㄽ" => 7,
                .@"ㄾ" => 9,
                .@"ㄿ" => 9,
                .@"ㅀ" => 8,
                .@"ㅁ" => 4,
                .@"ㅂ" => 4,
                .@"ㅄ" => 6,
                .@"ㅅ" => 2,
                .@"ㅆ" => 4,
                .@"ㅇ" => unreachable,
                .@"ㅈ" => 3,
                .@"ㅊ" => 4,
                .@"ㅋ" => 3,
                .@"ㅌ" => 4,
                .@"ㅍ" => 4,
                .@"ㅎ" => unreachable,
            };
        }
    };

    pub fn fromInt(codepoint: u21) ?Hangul {
        if (codepoint < 0xac00 or codepoint >= 0xd7a0) {
            return null;
        }

        var cp = codepoint - 0xac00;

        const last = Hangul.Last.fromInt(cp % 28);
        cp /= 28;

        const middle = Hangul.Middle.fromInt(cp % 21);
        cp /= 21;

        const first = Hangul.First.fromInt(cp);

        return Hangul{
            .first = first,
            .middle = middle,
            .last = last,
        };
    }

    pub fn toUnicode(self: Hangul, out: []u8) !u3 {
        const codepoint = 0xac00 + ((self.first.toInt() * 21 + self.middle.toInt()) * 28 + self.last.toInt());
        return try std.unicode.utf8Encode(@intCast(u21, codepoint), out);
    }
};

test "test parsing hangul" {
    try std.testing.expectEqual(
        Hangul.fromInt(try std.unicode.utf8Decode("가")),
        Hangul{
            .first = Hangul.First.Other,
            .middle = Hangul.Middle.@"ㅏ",
            .last = Hangul.Last.@" ",
        },
    );
    try std.testing.expectEqual(
        Hangul.fromInt(try std.unicode.utf8Decode("뱏")),
        Hangul{
            .first = Hangul.First.@"ㅂ",
            .middle = Hangul.Middle.@"ㅑ",
            .last = Hangul.Last.@"ㄳ",
        },
    );
    try std.testing.expectEqual(
        Hangul.fromInt(try std.unicode.utf8Decode("툞")),
        Hangul{
            .first = Hangul.First.@"ㅌ",
            .middle = Hangul.Middle.@"ㅛ",
            .last = Hangul.Last.@"ㄿ",
        },
    );
    try std.testing.expectEqual(
        Hangul.fromInt(try std.unicode.utf8Decode("?")),
        null,
    );
}
