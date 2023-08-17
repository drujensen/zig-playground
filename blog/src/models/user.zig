const std = @import("std");

const User = struct {
    name: []const u8,
    email: []const u8,

    fn print(self: User) void {
        std.debug.print("name {s}, email {s}\n", .{ self.name, self.email });
    }
};
