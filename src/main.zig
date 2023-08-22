const std = @import("std");
const raylib = @import("raylib");

const Rng = std.rand.DefaultPrng;
const Vector2 = raylib.Vector2;
const Color = raylib.Color;

const ArrayList = std.ArrayList;

const MAX_BATCH_ELEMENTS = 8_192;

const Bunny = struct {
    position: Vector2,
    speed: Vector2,
    color: Color,
};

var rng = Rng.init(0);

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
    const texture = raylib.LoadTexture("resources/wabbit_alpha.png");
    defer raylib.UnloadTexture(texture);
    const texture_halfwidth = @divTrunc(texture.width, 2);
    const texture_halfheight = @divTrunc(texture.height, 2);

    var bunnies = ArrayList(Bunny).init(allocator);
    defer bunnies.deinit();

    var label_buffer: [1024]u8 = undefined;

    while (!raylib.WindowShouldClose()) {
        const width = raylib.GetScreenWidth();
        const height = raylib.GetScreenHeight();
        const right_edge = @as(f32, @floatFromInt(width - texture_halfwidth));
        const left_edge = @as(f32, @floatFromInt(-texture_halfwidth));
        const bottom_edge = @as(f32, @floatFromInt(height - texture_halfheight));
        const top_edge = @as(f32, @floatFromInt(40 - texture_halfheight));

        // Create more bunnies
        if (raylib.IsMouseButtonDown(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
            const position = raylib.GetMousePosition();

            for (0..100) |_| {
                try bunnies.append(randomBunnyAt(position));
            }
        }

        // Update bunnies
        for (bunnies.items) |*bunny| {
            bunny.position.x += bunny.speed.x;
            bunny.position.y += bunny.speed.y;

            if (bunny.position.x > right_edge or bunny.position.x < left_edge)
                bunny.speed.x *= -1;

            if (bunny.position.y > bottom_edge or bunny.position.y < top_edge)
                bunny.speed.y *= -1;
        }

        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(raylib.RAYWHITE);

        for (bunnies.items) |bunny| {
            raylib.DrawTextureV(texture, bunny.position, bunny.color);
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
