const std = @import("std");
const raylib = @import("raylib");
const Bunny = @import("./bunny.zig").Bunny;

const ArrayList = std.ArrayList;

const MAX_BATCH_ELEMENTS = 8_192;

fn intToFloat(i: i32) f32 {
    return @as(f32, @floatFromInt(i));
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

        // Create more bunnies
        if (raylib.IsMouseButtonDown(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
            const position = raylib.GetMousePosition();

            for (0..100) |_| {
                try bunnies.append(Bunny.newRandomAt(position));
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
