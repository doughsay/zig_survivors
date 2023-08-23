const raylib = @import("raylib");

const Vector2 = raylib.Vector2;
const Color = raylib.Color;
const Texture2D = raylib.Texture2D;

pub const Bunny = struct {
    position: Vector2,
    speed: Vector2,
    color: Color,

    pub var texture: Texture2D = undefined;

    pub fn init() void {
        texture = raylib.LoadTexture("resources/wabbit_alpha.png");
    }

    pub fn deinit() void {
        raylib.UnloadTexture(texture);
    }

    pub fn move(self: *Bunny) void {
        self.position.x += self.speed.x;
        self.position.y += self.speed.y;
    }

    pub fn reverse_x(self: *Bunny) void {
        self.speed.x *= -1;
    }

    pub fn reverse_y(self: *Bunny) void {
        self.speed.y *= -1;
    }

    pub fn render(self: Bunny) void {
        raylib.DrawTextureV(texture, self.position, self.color);
    }
};
