const std = @import("std");
const raylib = @import("raylib");

const Rng = std.rand.DefaultPrng;
const Vector2 = raylib.Vector2;
const Color = raylib.Color;

const ArrayList = std.ArrayList;

const MAX_BATCH_ELEMENTS = 8_192;

const Bunny = struct {
    var texture: raylib.Texture2D = undefined;

    position: Vector2,
    speed: Vector2,
    color: Color,

    fn init() void {
        texture = raylib.LoadTexture("resources/wabbit_alpha.png");
    }

    fn deinit() void {
        raylib.UnloadTexture(texture);
    }

    fn move(self: *Bunny) void {
        self.position.x += self.speed.x;
        self.position.y += self.speed.y;
    }

    fn reverse_x(self: *Bunny) void {
        self.speed.x *= -1;
    }

    fn reverse_y(self: *Bunny) void {
        self.speed.y *= -1;
    }

    fn render(self: Bunny) void {
        raylib.DrawTextureV(texture, self.position, self.color);
    }
};

var rng = Rng.init(0);

fn intToFloat(i: i32) f32 {
    return @as(f32, @floatFromInt(i));
}

fn randomFloat(min: f32, max: f32) f32 {
    return std.math.lerp(min, max, rng.random().float(f32));
}

fn randomByte(min: u8, max: u8) u8 {
    return rng.random().uintAtMost(u8, max - min) + min;
}

fn randomBunnyAt(position: Vector2) Bunny {
    return Bunny{
        .position = position,
        .speed = Vector2{
            .x = randomFloat(-250.0, 250.0) / 60.0,
            .y = randomFloat(-250.0, 250.0) / 60.0,
        },
        .color = Color{
            .a = 255,
            .r = randomByte(50, 240),
            .g = randomByte(80, 240),
            .b = randomByte(100, 240),
        },
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true, .FLAG_MSAA_4X_HINT = true });
    raylib.InitWindow(800, 800, "raylib [textures] example - bunnymark");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)
    Bunny.init();
    defer Bunny.deinit();

    const texture_halfwidth = @divTrunc(Bunny.texture.width, 2);
    const texture_halfheight = @divTrunc(Bunny.texture.height, 2);

    var bunnies = ArrayList(Bunny).init(allocator);
    defer bunnies.deinit();

    var label_buffer: [1024]u8 = undefined;

    while (!raylib.WindowShouldClose()) {
        const width = raylib.GetScreenWidth();
        const height = raylib.GetScreenHeight();
        const right_edge = intToFloat(width - texture_halfwidth);
        const left_edge = intToFloat(-texture_halfwidth);
        const bottom_edge = intToFloat(height - texture_halfheight);
        const top_edge = intToFloat(40 - texture_halfheight);

        // Create more bunnies
        if (raylib.IsMouseButtonDown(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
            const position = raylib.GetMousePosition();

            for (0..100) |_| {
                try bunnies.append(randomBunnyAt(position));
            }
        }

        // Update bunnies
        for (bunnies.items) |*bunny| {
            bunny.move();

            if (bunny.position.x > right_edge or bunny.position.x < left_edge)
                bunny.reverse_x();

            if (bunny.position.y > bottom_edge or bunny.position.y < top_edge)
                bunny.reverse_y();
        }

        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(raylib.RAYWHITE);

        for (bunnies.items) |bunny| {
            bunny.render();
        }

        raylib.DrawRectangle(0, 0, width, 40, raylib.BLACK);

        raylib.DrawText(try std.fmt.bufPrintZ(
            &label_buffer,
            "bunnies: {d}",
            .{bunnies.items.len},
        ), 120, 10, 20, raylib.GREEN);

        raylib.DrawText(try std.fmt.bufPrintZ(
            &label_buffer,
            "batched draw calls: {d}",
            .{1 + bunnies.items.len / MAX_BATCH_ELEMENTS},
        ), 320, 10, 20, raylib.MAROON);

        raylib.DrawFPS(10, 10);
    }
}
