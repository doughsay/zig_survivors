const std = @import("std");
const raylib = @import("raylib");

const Rng = std.rand.DefaultPrng;
const Vector2 = raylib.Vector2;
const Color = raylib.Color;

const MAX_BUNNIES = 50_000;
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
    raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true, .FLAG_MSAA_4X_HINT = true });
    raylib.InitWindow(800, 800, "raylib [textures] example - bunnymark");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)
    const texture = raylib.LoadTexture("resources/wabbit_alpha.png");
    defer raylib.UnloadTexture(texture);

    var bunnies: [MAX_BUNNIES]Bunny = undefined;
    var bunnies_count: usize = 0;
    var label_buffer: [1024]u8 = undefined;

    while (!raylib.WindowShouldClose()) {
        // Create more bunnies
        if (raylib.IsMouseButtonDown(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
            var i: usize = 0;
            while (i < 100) : (i += 1) {
                if (bunnies_count < MAX_BUNNIES) {
                    bunnies[bunnies_count] = randomBunnyAt(raylib.GetMousePosition());
                    bunnies_count += 1;
                }
            }
        }

        // Update bunnies
        var i: usize = 0;
        while (i < bunnies_count) : (i += 1) {
            bunnies[i].position.x += bunnies[i].speed.x;
            bunnies[i].position.y += bunnies[i].speed.y;

            if (@as(c_int, @intFromFloat(bunnies[i].position.x)) + @divTrunc(texture.width, 2) > raylib.GetScreenWidth() or
                @as(c_int, @intFromFloat(bunnies[i].position.x)) + @divTrunc(texture.width, 2) < 0)
                bunnies[i].speed.x *= -1;

            if (@as(c_int, @intFromFloat(bunnies[i].position.y)) + @divTrunc(texture.height, 2) > raylib.GetScreenHeight() or
                @as(c_int, @intFromFloat(bunnies[i].position.y)) + @divTrunc(texture.height, 2) - 40 < 0)
                bunnies[i].speed.y *= -1;
        }

        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(raylib.RAYWHITE);

        var j: usize = 0;
        while (j < bunnies_count) : (j += 1) {
            raylib.DrawTextureV(texture, bunnies[j].position, bunnies[j].color);
        }

        raylib.DrawRectangle(0, 0, raylib.GetScreenWidth(), 40, raylib.BLACK);

        raylib.DrawText(try std.fmt.bufPrintZ(
            &label_buffer,
            "bunnies: {d}",
            .{bunnies_count},
        ), 120, 10, 20, raylib.GREEN);

        raylib.DrawText(try std.fmt.bufPrintZ(
            &label_buffer,
            "batched draw calls: {d}",
            .{1 + bunnies_count / MAX_BATCH_ELEMENTS},
        ), 320, 10, 20, raylib.MAROON);

        raylib.DrawFPS(10, 10);
    }
}
