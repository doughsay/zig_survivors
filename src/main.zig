const std = @import("std");
const raylib = @import("raylib");
const Bunny = @import("./bunny.zig").Bunny;
const Player = @import("./player.zig").Player;

const Camera2D = raylib.Camera2D;
const Vector2 = raylib.Vector2;

const ArrayList = std.ArrayList;

fn intToFloat(i: i32) f32 {
    return @as(f32, @floatFromInt(i));
}

fn floatToInt(f: f32) i32 {
    return @as(i32, @intFromFloat(f));
}

fn drawBackground(camera: Camera2D) void {
    // TODO: make this smarter and only draw what's on screen
    _ = camera;
    const limit = 100_000;
    // const margin = 10;
    // const margin_top = 50;
    // const x1 = -floatToInt(camera.offset.x - camera.target.x) + margin;
    // const x2 = floatToInt(camera.offset.x + camera.target.x) - margin;

    // const y1 = -floatToInt(camera.offset.y - camera.target.y) + margin_top;
    // const y2 = floatToInt(camera.offset.y + camera.target.y) - margin;

    var y: i32 = -limit;
    while (y < limit) : (y += 100) {
        raylib.DrawLine(-limit, y, limit, y, raylib.LIGHTGRAY);
    }

    var x: i32 = -limit;
    while (x < limit) : (x += 100) {
        raylib.DrawLine(x, -limit, x, limit, raylib.LIGHTGRAY);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true, .FLAG_MSAA_4X_HINT = true });
    raylib.InitWindow(800, 800, "raylib [textures] example - bunnymark");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    var camera = Camera2D{ .target = Vector2{ .x = 0.0, .y = 0.0 } };
    var player = Player{
        .position = Vector2{ .x = 0.0, .y = 0.0 },
        .direction = Vector2{ .x = 1.0, .y = 0.0 },
        .moving = false,
    };

    // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)
    Bunny.init(random);
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

        camera.offset = Vector2{ .x = intToFloat(width) / 2.0, .y = intToFloat(height) / 2.0 };

        // Move player
        if (raylib.IsKeyDown(raylib.KeyboardKey.KEY_RIGHT)) {
            player.position.x += 2.0;
        } else if (raylib.IsKeyDown(raylib.KeyboardKey.KEY_LEFT)) {
            player.position.x -= 2.0;
        }

        if (raylib.IsKeyDown(raylib.KeyboardKey.KEY_DOWN)) {
            player.position.y += 2.0;
        } else if (raylib.IsKeyDown(raylib.KeyboardKey.KEY_UP)) {
            player.position.y -= 2.0;
        }

        // Center camera on player
        camera.target = player.position;

        // Create more bunnies
        if (raylib.IsMouseButtonDown(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
            const position = raylib.GetMousePosition();
            const actual_position = position.sub(camera.offset).add(camera.target);

            for (0..100) |_| {
                try bunnies.append(Bunny.newRandomAt(actual_position));
            }
        }

        // Update bunnies
        for (bunnies.items) |*bunny| {
            bunny.move();

            if (bunny.position.x > right_edge and bunny.speed.x > 0 or bunny.position.x < left_edge and bunny.speed.x < 0)
                bunny.reverseX();

            if (bunny.position.y > bottom_edge and bunny.speed.y > 0 or bunny.position.y < top_edge and bunny.speed.y < 0)
                bunny.reverseY();
        }

        // Draw
        {
            raylib.BeginDrawing();
            defer raylib.EndDrawing();

            raylib.ClearBackground(raylib.RAYWHITE);

            // Draw camera sensitive things
            {
                raylib.BeginMode2D(camera);
                defer raylib.EndMode2D();

                drawBackground(camera);

                for (bunnies.items) |bunny| {
                    bunny.render();
                }

                player.render();
            }

            raylib.DrawRectangle(0, 0, width, 40, raylib.BLACK);

            raylib.DrawText(try std.fmt.bufPrintZ(
                &label_buffer,
                "player: x:{d} y:{d}",
                .{ player.position.x, player.position.y },
            ), 120, 10, 20, raylib.GREEN);

            raylib.DrawText(try std.fmt.bufPrintZ(
                &label_buffer,
                "camera offset: x:{d} y:{d}",
                .{ camera.offset.x, camera.offset.y },
            ), 400, 10, 20, raylib.GREEN);

            raylib.DrawFPS(10, 10);
        }
    }
}
