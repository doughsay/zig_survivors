const raylib = @import("raylib");
const std = @import("std");

const Random = std.rand.Random;

const Vector2 = raylib.Vector2;
const Color = raylib.Color;
const Texture2D = raylib.Texture2D;

fn randomFloat(random: Random, min: f32, max: f32) f32 {
    return std.math.lerp(min, max, random.float(f32));
}

fn randomByte(random: Random, min: u8, max: u8) u8 {
    return random.uintAtMost(u8, max - min) + min;
}

pub const Bunny = struct {
    position: Vector2,
    speed: Vector2,
    color: Color,

    pub var texture: Texture2D = undefined;
    var random: Random = undefined;

    pub fn init(rand: Random) void {
        texture = raylib.LoadTexture("resources/wabbit_alpha.png");
        random = rand;
    }

    pub fn deinit() void {
        raylib.UnloadTexture(texture);
    }

    pub fn newRandomAt(position: Vector2) Bunny {
        return Bunny{
            .position = position,
            .speed = Vector2{
                .x = randomFloat(random, -250.0, 250.0) / 60.0,
                .y = randomFloat(random, -250.0, 250.0) / 60.0,
            },
            .color = Color{
                .a = 255,
                .r = randomByte(random, 50, 240),
                .g = randomByte(random, 80, 240),
                .b = randomByte(random, 100, 240),
            },
        };
    }

    pub fn move(self: *Bunny) void {
        self.position.x += self.speed.x;
        self.position.y += self.speed.y;
    }

    pub fn reverseX(self: *Bunny) void {
        self.speed.x *= -1;
    }

    pub fn reverseY(self: *Bunny) void {
        self.speed.y *= -1;
    }

    pub fn render(self: Bunny) void {
        raylib.DrawTextureV(texture, self.position, self.color);
    }
};
