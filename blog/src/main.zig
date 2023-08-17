const std = @import("std");

// create an http server that listens on port 3000 in zig
pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var server = std.http.Server.init(allocator, .{ .reuse_address = true });
    defer server.deinit();

    const host_ip = "127.0.0.1";
    const port = 3000;
    const address = try std.net.Address.parseIp(host_ip, port);

    try server.listen(address);
    std.debug.print("Listening on ip: {s} port {d}\n", .{ .host_ip = host_ip, .port = port });

    while (true) {
        var res = try server.accept(.{ .allocator = allocator, .header_strategy = .{ .dynamic = 8192 } });
        defer _ = res.reset();
        defer res.deinit();

        try res.wait();

        const body: []const u8 = "<html><body><h1>Zig Server</h1><p>Hello, World!</p></body></html>";
        res.transfer_encoding = .{ .content_length = body.len };
        try res.headers.append("Content-Type", "text/html; charset=utf-8");
        try res.do();

        var buf: [128]u8 = undefined;
        _ = try res.readAll(&buf);
        _ = try res.writer().writeAll(body);
        try res.finish();
    }
}
