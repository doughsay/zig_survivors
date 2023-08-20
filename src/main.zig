const std = @import("std");
const raylib = @import("raylib");

const Rng = std.rand.DefaultPrng;
const Vector2 = raylib.Vector2;
const Color = raylib.Color;

const max_bunnies = 50_000;
const max_batch_elements = 8_192;

const Bunny = struct {
    position: Vector2,
    speed: Vector2,
    color: Color,
};

fn intToFloat(i: i32) f32 {
    return @as(f32, @floatFromInt(i));
}

var rng = Rng.init(0);

fn randomFloat(min: f32, max: f32) f32 {
    return std.math.lerp(min, max, rng.random().float(f32));
}

pub fn main() !void {
    std.debug.print("\nrandom float: {d}\n", .{randomFloat(-250.0, 250.0)});
    std.debug.print("\nrandom float: {d}\n", .{randomFloat(-250.0, 250.0)});
    std.debug.print("\nrandom float: {d}\n", .{randomFloat(-250.0, 250.0)});

    raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true, .FLAG_MSAA_4X_HINT = true });
    raylib.InitWindow(800, 800, "raylib [textures] example - bunnymark");
    defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

    // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)
    const texture = raylib.LoadTexture("resources/wabbit_alpha.png");
    defer raylib.UnloadTexture(texture);

    var bunnies: [max_bunnies]Bunny = undefined;
    var bunnies_count: usize = 0;

    while (!raylib.WindowShouldClose()) {
        // Create more bunnies
        if (raylib.IsMouseButtonDown(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
            var i: usize = 0;
            while (i < 100) : (i += 1) {
                if (bunnies_count < max_bunnies) {
                    const speed = Vector2{
                        .x = randomFloat(-250.0, 250.0) / 60.0,
                        .y = randomFloat(-250.0, 250.0) / 60.0,
                    };
                    const color = Color{
                        .a = 255,
                        // TODO: get random byte
                        .r = @intCast(raylib.GetRandomValue(50, 240)),
                        .g = @intCast(raylib.GetRandomValue(80, 240)),
                        .b = @intCast(raylib.GetRandomValue(100, 240)),
                    };
                    bunnies[bunnies_count] = Bunny{
                        .position = raylib.GetMousePosition(),
                        .speed = speed,
                        .color = color,
                    };
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

        const bunnies_count_text = try raylib.TextFormat(std.heap.c_allocator, "bunnies: {d}", .{bunnies_count});
        raylib.DrawText(bunnies_count_text, 120, 10, 20, raylib.GREEN);

        const batched_calls_text = try raylib.TextFormat(std.heap.c_allocator, "batched draw calls: {d}", .{1 + bunnies_count / max_batch_elements});
        raylib.DrawText(batched_calls_text, 320, 10, 20, raylib.MAROON);

        raylib.DrawFPS(10, 10);
    }
}
