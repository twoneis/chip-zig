const std = @import("std");
const Display = @import("display.zig").Display;
const Bitmap = @import("bitmap.zig").Bitmap;
const Emulator = @import("emulator.zig").Emulator;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    defer if (gpa.deinit() == .leak) @panic("Memory leaked");

    var args = std.process.args();
    _ = args.skip();
    const rom_path = args.next() orelse {
        std.debug.print("Please provide the path to a ROM-image as an argument\n", .{});
        return;
    };

    var emulator = Emulator.init(allocator);
    defer emulator.deinit();
    emulator.loadROM(rom_path);

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
