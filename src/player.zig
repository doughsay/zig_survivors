const raylib = @import("raylib");

const Vector2 = raylib.Vector2;

pub const Player = struct {
    position: Vector2,
    direction: Vector2,
    moving: bool,

    pub fn move(self: *Player) void {
        if (self.moving) self.position.add(self.direction);
    }

    pub fn render(self: Player) void {
        raylib.DrawCircleV(self.position, 20.0, raylib.BLUE);
    }
};
