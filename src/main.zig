const std = @import("std");
const IO = @import("io.zig").IO;
const Bitmap = @import("bitmap.zig").Bitmap;
const ROM = @import("rom.zig").ROM;

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

    var rom = try ROM.init(allocator);
    defer rom.deinit();
    if (!rom.loadROM(rom_path)) {
        std.debug.print("Could not load {s}\n", .{rom_path});
        return;
    }

    var io = try IO.init();
    defer io.deinit();

    var bitmap = try Bitmap.init(allocator, io.win_width, io.win_height);
    defer bitmap.free();
    _ = bitmap.setPixel(5, 5);

    while (io.open) {
        io.input();
        io.draw(&bitmap);
    }
}
