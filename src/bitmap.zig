const std = @import("std");

pub const Bitmap = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    width: u8,
    height: u8,
    pixels: []u1,

    pub fn init(allocator: std.mem.Allocator, width: u8, height: u8) !Self {
        var this: Self = .{ .allocator = allocator, .width = width, .height = height, .pixels = undefined };
        this.pixels = try allocator.alloc(u1, @as(u16, width) * @as(u16, height));
        @memset(this.pixels, 0);
        return this;
    }

    pub fn free(self: *Self) void {
        self.allocator.free(self.pixels);
    }

    pub fn clear(self: *Self, value: u1) void {
        @memset(self.pixels, value);
    }

    pub fn setPixel(self: *Self, x: u8, y: u8) bool {
        if (x >= self.width or y >= self.height) {
            return false;
        }

        const idx: u16 = @as(u16, y) * @as(u16, self.width) + @as(u16, x);
        self.pixels[idx] ^= 1;
        return (self.pixels[idx] == 0);
    }

    pub fn getPixel(self: *Self, x: u8, y: u8) u1 {
        if (x >= self.width or y >= self.height) {
            return 0;
        }

        const idx: u16 = @as(u16, y) * @as(u16, self.width) + @as(u16, x);
        return self.pixels[idx];
    }
};
