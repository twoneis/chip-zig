const std = @import("std");
const Display = @import("display.zig").Display;
const Bitmap = @import("bitmap.zig").Bitmap;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    defer if (gpa.deinit() == .leak) @panic("Memory leaked");

    var display = try Display.init();
    defer display.deinit();

    var bitmap = try Bitmap.init(allocator, display.win_width, display.win_height);
    defer bitmap.free();
    _ = bitmap.setPixel(5, 5);

    while (display.open) {
        display.input();
        display.draw(&bitmap);
    }
}
