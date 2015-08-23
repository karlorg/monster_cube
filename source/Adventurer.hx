package ;

import flixel.FlxSprite;
import flixel.tile.FlxTilemap;
import flixel.util.FlxAngle;
import flixel.util.FlxColor;
import flixel.util.FlxPath;
import flixel.util.FlxPoint;
import flixel.util.FlxRandom;

enum Behavior {
    Idle;
    Running;
    Shooting;
}

class Adventurer extends FlxSprite {

    static var speedIdle : Float = 0.3;
    static var speedRun : Float = 1.1;
    static var tileWidth : Int = PlayState.tileWidth;
    static var tileHeight : Int = PlayState.tileHeight;

    public var path : FlxPath;

    private var behavior : Behavior;
    private var lastShot : Int;
    private var lastPathed : Int;
    private var lastSawCube : Int;
    private var nodes : Array<FlxPoint>;
    private var player : Player;
    private var ticks : Int;
    private var ticksToRun : Int;
    private var tilemap : FlxTilemap;
    private var treasure : FlxSprite;

    public function new(x : Int, y : Int,
                        tilemap : FlxTilemap, player : Player,
                        treasure : FlxSprite) {
        super();
        this.tilemap = tilemap;
        this.player = player;
        this.treasure = treasure;
        this.x = x * tileWidth + 3;
        this.y = y * tileWidth + 3;
        this.behavior = Idle;

        loadGraphic("assets/images/archer.png",
                    true,  // animated
                    16, 16);
        width = height = 10;
        offset.x = offset.y = 3;
        animation.add("down", [0, 1, 0, 2]);
        animation.add("up", [3, 4, 3, 5]);
        animation.add("right", [6, 7, 6, 8]);
        animation.add("left", [9, 10, 9, 11]);

        path = new FlxPath();

        ticks = 0;
        lastPathed = -10000;
        lastSawCube = -10000;
        ticksToRun = -1;
    }

    override public function update() : Void {
        super.update();

        ticks += 1;

        var startPoint = FlxPoint.get(x + width / 2,
                                      y + height / 2);
        var playerPoint = FlxPoint.get(player.cube.x + player.cube.width / 2,
                                       player.cube.y + player.cube.height / 2);
        var treasurePoint = FlxPoint.get(treasure.x + treasure.width / 2,
                                         treasure.y + treasure.height / 2);

        function canSeePlayer() : Bool {
            if ((!player.hiding) &&
                tilemap.ray(startPoint, playerPoint)) {
                var distance = startPoint.distanceTo(playerPoint);
                if (distance / tileWidth < 5) {
                    return true;
                }
            }
            return false;
        }

        switch (behavior) {

        case Idle:
            if (ticks - lastPathed > 59) {
                nodes = tilemap.findPath(startPoint, treasurePoint, false);
                if (nodes != null && nodes.length > 0) {
                    path.start(this, nodes, speedIdle * 60);
                    lastPathed = ticks;
                }
            }

            if (canSeePlayer()) {
                this.behavior = Shooting;
                lastShot = ticks;
                lastSawCube = ticks;
                lastPathed = -10000;  // force re-path
            }

        case Running:
            if (ticksToRun < 0) {
                ticksToRun = FlxRandom.intRanged(24, 34);
            }
            if (ticks - lastPathed > ticksToRun) {
                ticksToRun = -1;
                this.behavior = Shooting;
                lastShot = ticks;
            }
            if (canSeePlayer()) {
                lastSawCube = ticks;
            // Check if we should stop running
            } else if (ticks - lastSawCube > 8 * 60) {
                behavior = Idle;
            }

            if (!path.finished && path.nodes != null) {
                if (path.angle >= -45 && path.angle <= 45) {
                    animation.play("up");
                } else if (path.angle >= 135 || path.angle <= -135) {
                    animation.play("down");
                } else if (path.angle > 45 && path.angle < 135) {
                    animation.play("right");
                } else {
                    animation.play("left");
                }
            } else {
                animation.curAnim.curFrame = 0;
                animation.curAnim.stop();
                nodes = null;
            }

        case Shooting:
            path.cancel();
            var anglePlayerToMe = FlxAngle.angleBetween(player.cube, this,
                                                        true);  // asDegrees
            if (ticks - lastShot < 10) {
                if (canSeePlayer()) {
                    var faceAngle = anglePlayerToMe + 90 + 180;
                    while (faceAngle > 180) { faceAngle -= 360; }
                    if (faceAngle <= 45 && faceAngle >= -45) {
                        animation.play("up");
                    } else if (faceAngle >= 135 || faceAngle <= -135) {
                        animation.play("down");
                    } else if (faceAngle > 45 && faceAngle < 135) {
                        animation.play("right");
                    } else {
                        animation.play("left");
                    }
                    animation.curAnim.curFrame = 0;
                    animation.curAnim.stop();
                }
            } else {

                // pick a new path and start running again
                anglePlayerToMe = FlxAngle.getAngle(
                    startPoint, playerPoint) + 90;
                function candidate(dist : Float,
                                   rot : Float = 0.0) : FlxPoint {
                    var result = new FlxPoint(dist * tileWidth, 0);
                    result = FlxAngle.rotatePoint(result.x, result.y,
                                                  0, 0,
                                                  rot + anglePlayerToMe);
                    result.addPoint(startPoint);
                    return result;
                }
                var destPoint = startPoint;
                for (xy in [[6,0],
                            [5,0], [5,10], [5,-10],
                            [4,0], [4,30], [4,-30], [4,50], [4,-50],
                            [3,0], [3,50], [3,-50], [3,70], [3,-70],
                            [2,0], [2,70], [2,-70], [2,90], [2,-90],
                            [1,0], [1,90], [1,-90]]) {
                    var point = candidate(xy[0], xy[1]);
                    if (tilemap.getTile(Math.floor(point.x / tileWidth),
                                        Math.floor(point.y / tileHeight))
                        == 1) {
                        destPoint = point;
                        break;
                    }
                }
                nodes = tilemap.findPath(startPoint, destPoint, false);
                if (nodes != null && nodes.length > 0) {
                    path.start(this, nodes, speedRun * 60);
                }
                lastPathed = ticks;
                this.behavior = Running;

            }
        }

    }

}
