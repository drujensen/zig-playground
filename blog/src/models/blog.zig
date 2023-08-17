const std = @import("std");

const Blog = struct {
    title: []const u8,
    body: []const u8,

    fn print(self: Blog) void {
        std.debug.print("title {s}, body {s}\n", .{ self.title, self.body });
    }
};
