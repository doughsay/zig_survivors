const raylib = @import("raylib");

const Vector2 = raylib.Vector2;

pub const Enemy = struct {
    id: usize,
    position: Vector2,
    speed: f32,

    pub fn new(id: usize, speed: f32, position: Vector2) Enemy {
        return Enemy{
            .id = id,
            .speed = speed,
            .position = position,
        };
    }

    pub fn move(self: *Enemy, player_position: Vector2) void {
        const dir = player_position.sub(self.position).normalize();

        self.position.addSet(dir.scale(self.speed));
    }

    pub fn moveAwayFrom(self: *Enemy, other: *Enemy) void {
        const dir = other.position.sub(self.position).normalize();

        self.position.addSet(dir.neg().scale(self.speed));
    }

    pub fn render(self: Enemy) void {
        raylib.DrawCircleV(self.position, 15.0, raylib.RED);
    }

    pub fn tooClose(self: Enemy, other: *Enemy) bool {
        return self.position.distanceTo(other.position) < 30.0;
    }
};
