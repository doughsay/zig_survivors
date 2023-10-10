const raylib = @import("raylib");

const Vector2 = raylib.Vector2;

pub const Player = struct {
    position: Vector2,
    direction: Vector2,
    moving: bool,

    // pub fn move(self: *Player) void {
    //     if (self.moving) self.position.add(self.direction);
    // }

    pub fn render(self: Player) void {
        raylib.DrawRectangleV(self.position.sub(Vector2{ .x = 20.0, .y = 30.0 }), Vector2{ .x = 40.0, .y = 60.0 }, raylib.BLUE);
    }
};
