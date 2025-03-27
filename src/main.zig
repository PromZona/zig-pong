const std = @import("std");
const rl = @import("raylib");

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "Pong");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var state: GameState = GameState.init();
    while (!rl.windowShouldClose()) {
        Input(&state);
        Update(&state);
        Draw(&state);
    }
}

const MAXSPEED: i32 = 300;

const GameState = struct {
    // Allocator: std.mem.Allocator,

    ScreenHeight: f32,
    ScreenWidth: f32,
    LeftPlayerPos: rl.Rectangle,
    RightPlayerPos: rl.Rectangle,
    PlayerSpeed: f32,
    BallPos: rl.Rectangle,
    BallDir: rl.Vector2,
    BallSpeed: f32,
    LefScore: i32 = 0,
    RightScore: i32 = 0,

    pub fn init() GameState {
        const h: f32 = @as(f32, @floatFromInt(rl.getScreenHeight()));
        const w: f32 = @as(f32, @floatFromInt(rl.getScreenWidth()));
        const halfScreenY: f32 = h / 2.0;
        const halfScreenX: f32 = w / 2.0;
        const xPadding: f32 = w - 50.0;
        return GameState{
            .ScreenHeight = h,
            .ScreenWidth = w,
            .LeftPlayerPos = rl.Rectangle{ .x = 10, .y = halfScreenY, .width = 20, .height = 120 },
            .RightPlayerPos = rl.Rectangle{ .x = xPadding, .y = halfScreenY, .width = 20, .height = 120 },
            .PlayerSpeed = 500.0,
            .BallPos = rl.Rectangle{ .x = halfScreenX, .y = halfScreenY, .width = 20.0, .height = 20 },
            .BallDir = .{ .x = 1.0, .y = 0.0 },
            .BallSpeed = MAXSPEED,
        };
    }
};

fn Input(state: *GameState) void {
    const frameTime: f32 = rl.getFrameTime();

    if (rl.isKeyDown(.s)) {
        state.*.LeftPlayerPos.y += state.*.PlayerSpeed * frameTime;
    }

    if (rl.isKeyDown(.w)) {
        state.*.LeftPlayerPos.y -= state.*.PlayerSpeed * frameTime;
    }

    if (rl.isKeyDown(.down)) {
        state.*.RightPlayerPos.y += state.*.PlayerSpeed * frameTime;
    }

    if (rl.isKeyDown(.up)) {
        state.*.RightPlayerPos.y -= state.*.PlayerSpeed * frameTime;
    }
}
fn Update(state: *GameState) void {
    const ballVelocity: rl.Vector2 = .{ .x = state.*.BallDir.x * state.*.BallSpeed, .y = state.*.BallDir.y * state.*.BallSpeed };
    const frameTime: f32 = rl.getFrameTime();
    state.*.BallSpeed += 1;

    state.*.BallPos.x += ballVelocity.x * frameTime;
    state.*.BallPos.y += ballVelocity.y * frameTime;

    // BALL TO PANES COLLISION
    if (rl.checkCollisionRecs(state.*.LeftPlayerPos, state.*.BallPos)) {
        const colRec: rl.Rectangle = rl.getCollisionRec(state.*.LeftPlayerPos, state.*.BallPos);
        state.*.BallPos.x += colRec.width;
        state.*.BallDir = getBallToPaneReflection(state.*.BallPos, state.*.LeftPlayerPos, .{ .x = 1.0, .y = 0.0 });
    }

    if (rl.checkCollisionRecs(state.*.RightPlayerPos, state.*.BallPos)) {
        const colRec: rl.Rectangle = rl.getCollisionRec(state.*.RightPlayerPos, state.*.BallPos);
        state.*.BallPos.x -= colRec.width;
        state.*.BallDir = getBallToPaneReflection(state.*.BallPos, state.*.RightPlayerPos, .{ .x = -1.0, .y = 0.0 });
    }
    // END

    // BALL TO SCREEN COLLISION
    if (state.*.BallPos.y <= 0 or state.*.BallPos.y + state.*.BallPos.height >= state.*.ScreenHeight) {
        state.*.BallDir.y = -state.*.BallDir.y;
    }

    if (state.*.BallPos.x <= 0) {
        state.*.RightScore += 1;
        state.*.BallSpeed = MAXSPEED;
        std.debug.print("Right Scored! {} : {}\n", .{ state.*.LefScore, state.*.RightScore });
        state.*.BallPos.x = state.*.ScreenWidth / 2.0;
        state.*.BallPos.y = state.*.ScreenHeight / 2.0;
        state.*.BallDir = .{ .x = 1.0, .y = 0.0 };
    }

    if (state.*.BallPos.x + state.*.BallPos.width > state.*.ScreenWidth) {
        state.*.LefScore += 1;
        state.*.BallSpeed = MAXSPEED;
        std.debug.print("Left Scored! {} : {}\n", .{ state.*.LefScore, state.*.RightScore });
        state.*.BallPos.x = state.*.ScreenWidth / 2.0;
        state.*.BallPos.y = state.*.ScreenHeight / 2.0;
        state.*.BallDir = .{ .x = -1.0, .y = 0.0 };
    }
    //END

    // PANES TO SCREEN COLLISION
    if (state.*.LeftPlayerPos.y < 0) {
        state.*.LeftPlayerPos.y = 0;
    }
    if (state.*.LeftPlayerPos.y + state.*.LeftPlayerPos.height > state.*.ScreenHeight) {
        state.*.LeftPlayerPos.y = state.*.ScreenHeight - state.*.LeftPlayerPos.height;
    }

    if (state.*.RightPlayerPos.y < 0) {
        state.*.RightPlayerPos.y = 0;
    }
    if (state.*.RightPlayerPos.y + state.*.RightPlayerPos.height > state.*.ScreenHeight) {
        state.*.RightPlayerPos.y = state.*.ScreenHeight - state.*.RightPlayerPos.height;
    }
    // END
}
fn Draw(state: *GameState) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(.gray);

    rl.drawRectangleRec(state.*.LeftPlayerPos, .dark_green);
    rl.drawRectangleRec(state.*.RightPlayerPos, .dark_purple);
    rl.drawRectangleRec(state.*.BallPos, .red);

    const scoreY: i32 = 80;
    const scoreXMiddle: i32 = @divFloor(rl.getScreenWidth(), 2);
    const xPadding: i32 = 50;
    rl.drawText(rl.textFormat("%i", .{state.*.LefScore}), scoreXMiddle - xPadding, scoreY, 32, .red);
    rl.drawText(rl.textFormat("%i", .{state.*.RightScore}), scoreXMiddle + xPadding, scoreY, 32, .red);
}

fn getBallToPaneReflection(ball: rl.Rectangle, pane: rl.Rectangle, paneNormal: rl.Vector2) rl.Vector2 {
    const ballCenterY: f32 = ball.y + (ball.height / 2.0);
    const paneBottomY: f32 = pane.y + pane.height;
    var normilizedCollision: f32 = rl.math.normalize(ballCenterY, pane.y, paneBottomY);
    normilizedCollision = rl.math.clamp(normilizedCollision, 0, 1); // [0; 1], where 0 is top of the pane and 1 is bottom of the pane
    normilizedCollision = rl.math.remap(normilizedCollision, 0, 1, -1, 1); // [0; 1] -> [-1; 1]

    const finalDir: rl.Vector2 = rl.Vector2.rotate(paneNormal, (30.0 * (paneNormal.x * normilizedCollision)) * (3.14 / 180.0));
    return finalDir;
}
