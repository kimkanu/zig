const std = @import("std");
const Codespace = @import("codespace.zig").Codespace;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var file = try std.fs.cwd().openFile(args[1], .{ .mode = .read_only });
    const file_size = (try file.stat()).size;
    var code = try allocator.alloc(u8, file_size);
    try file.reader().readNoEof(code);

    var codespace = try Codespace.init(allocator, code);
    defer codespace.deinit();

    // try codespace.print();
    try codespace.run();
}
