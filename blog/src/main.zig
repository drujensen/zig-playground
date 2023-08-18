const std = @import("std");
const http = std.http;
const log = std.log.scoped(.server);

const server_addr = "0.0.0.0";
const server_port = 3000;

// Handle an individual request.
fn handleRequest(response: *http.Server.Response, allocator: std.mem.Allocator) !void {
    // Log the request details.
    log.info("{s} {s} {s}", .{ @tagName(response.request.method), @tagName(response.request.version), response.request.target });

    // Read the request body.
    const body = try response.reader().readAllAlloc(allocator, 8192);
    defer allocator.free(body);

    // Set "connection" header to "keep-alive" if present in request headers.
    if (response.request.headers.contains("connection")) {
        try response.headers.append("connection", "keep-alive");
    }

    // Check if the request target starts with "/get".
    if (std.mem.startsWith(u8, response.request.target, "/")) {
        const responseBody = "<html><body><h1>Hello, world!</h1></body></html>";
        response.transfer_encoding = .{ .content_length = responseBody.len };
        try response.headers.append("content-type", "text/html");
        try response.do();

        // Write the response body.
        if (response.request.method != .HEAD) {
            try response.writeAll(responseBody);
            try response.finish();
        }
    } else {
        // Set the response status to 404 (not found).
        response.status = .not_found;
        try response.do();
    }
}

// Run the server and handle incoming requests.
fn runServer(server: *http.Server, allocator: std.mem.Allocator) !void {
    outer: while (true) {
        // Accept incoming connection.
        var response = try server.accept(.{
            .allocator = allocator,
        });
        defer response.deinit();

        while (response.reset() != .closing) {
            // Handle errors during request processing.
            response.wait() catch |err| switch (err) {
                error.HttpHeadersInvalid => continue :outer,
                error.EndOfStream => continue,
                else => return err,
            };

            // Process the request.
            try handleRequest(&response, allocator);
        }
    }
}

// create an http server that listens on port 3000 in zig
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var server = std.http.Server.init(allocator, .{ .reuse_address = true });
    defer server.deinit();

    log.info("Listening on ip: {s}:{d}\n", .{ server_addr, server_port });

    const address = std.net.Address.parseIp(server_addr, server_port) catch unreachable;
    try server.listen(address);

    try runServer(&server, allocator);
}
