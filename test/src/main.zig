const std = @import("std");

const User = struct {
    name: []const u8,
    age: u32,

    fn print(self: User) void {
        std.debug.print("User {s} is {d} years old.\n", .{ self.name, self.age });
    }
};

const UserList = struct {
    users: std.ArrayList(User),

    fn init(allocator: std.mem.Allocator) UserList {
        return .{
            .users = std.ArrayList(User).init(allocator),
        };
    }

    fn append(self: *UserList, user: User) !void {
        try self.users.append(user);
    }

    fn print(self: *UserList) !void {
        for (self.users.items) |user| {
            user.print();
        }
    }

    fn deinit(self: *UserList) void {
        self.users.deinit();
    }
};

pub fn main() !void {
    var list = UserList.init(std.heap.page_allocator);
    defer list.deinit();

    try list.append(User{ .name = "Dave", .age = 37 });
    try list.append(User{ .name = "Bob", .age = 42 });
    try list.append(User{ .name = "Alice", .age = 27 });

    try list.print();
}
