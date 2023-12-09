const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const Bitmap = @import("bitmap.zig").Bitmap;

pub const Display = struct {
    const Self = @This();
    screen: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    framebuffer: *c.SDL_Texture,
    win_width: u8 = 128,
    win_height: u8 = 64,
    scale_factor: u8 = 10,
    open: bool,

    pub fn init() !Self {
        var this: Self = .{ .screen = undefined, .renderer = undefined, .framebuffer = undefined, .open = true };

        // Initialize SDL
        if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_AUDIO) != 0) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        // Create window
        this.screen = c.SDL_CreateWindow("CHIP-Zig", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, @as(c_int, this.scale_factor) * @as(c_int, this.win_width), @as(c_int, this.scale_factor) * @as(c_int, this.win_height), c.SDL_WINDOW_OPENGL) orelse {
            c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        // Create renderer on window
        this.renderer = c.SDL_CreateRenderer(this.screen, -1, 0) orelse {
            c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
            c.SDL_DestroyWindow(this.screen);
            c.SDL_Quit();
            return error.SDLInitializationFailed;
        };

        // Create framebuffer
        this.framebuffer = c.SDL_CreateTexture(this.renderer, c.SDL_PIXELFORMAT_RGBA8888, c.SDL_TEXTUREACCESS_STREAMING, @as(c_int, this.win_width) * @as(c_int, this.scale_factor), @as(c_int, this.win_height) * @as(c_int, this.scale_factor)) orelse {
            c.SDL_Log("Unable to create framebuffer: %s", c.SDL_GetError());
            c.SDL_DestroyRenderer(this.renderer);
            c.SDL_DestroyWindow(this.screen);
            c.SDL_Quit();
            return error.SDLInitializationFailed;
        };

        return this;
    }

    pub fn input(self: *Self) void {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => self.open = false,
                else => {},
            }
        }
    }

    pub fn draw(self: *Self, bitmap: *Bitmap) void {
        if (bitmap.width != self.win_width or bitmap.height != self.win_height) return;

        const col = c.SDL_Color{
            .r = 0,
            .g = 255,
            .b = 0,
            .a = 255,
        };
        const no_col = c.SDL_Color{
            .r = 0,
            .g = 0,
            .b = 0,
            .a = 255,
        };
        var pixels: ?*anyopaque = null;
        var pitch: i32 = 0;

        if (c.SDL_LockTexture(self.framebuffer, null, &pixels, &pitch) != 0) {
            c.SDL_Log("Failed to lock texture: %s", c.SDL_GetError());
            return;
        }

        var upixels: [*]u32 = @ptrCast(@alignCast(pixels.?));

        var y: u16 = 0;
        while (y < @as(u16, self.win_height) * @as(u16, self.scale_factor)) : (y += 1) {
            var x: u16 = 0;
            while (x < @as(u16, self.win_width) * @as(u16, self.scale_factor)) : (x += 1) {
                const idx: usize = @as(usize, x) + @as(usize, y) * @as(usize, self.win_width) * @as(usize, self.scale_factor);
                const shift_x = @as(u8, @intCast(x / @as(u16, self.scale_factor)));
                const shift_y = @as(u8, @intCast(y / @as(u16, self.scale_factor)));
                var color = if (bitmap.getPixel(shift_x, shift_y) == 1) col else no_col;
                var r: u32 = @as(u32, color.r) << 24;
                var g: u32 = @as(u32, color.g) << 16;
                var b: u32 = @as(u32, color.b) << 8;
                var a: u32 = @as(u32, color.a) << 0;
                upixels[idx] = r | g | b | a;
            }
        }

        _ = c.SDL_UnlockTexture(self.framebuffer);
        _ = c.SDL_RenderClear(self.renderer);
        _ = c.SDL_RenderCopy(self.renderer, self.framebuffer, null, null);
        _ = c.SDL_RenderPresent(self.renderer);
    }

    pub fn deinit(self: *Self) void {
        c.SDL_DestroyRenderer(self.renderer);
        c.SDL_DestroyWindow(self.screen);
        c.SDL_Quit();
    }
};
