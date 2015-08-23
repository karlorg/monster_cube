package ;

import flixel.FlxSprite;
import flixel.tile.FlxTilemap;
import flixel.util.FlxAngle;
import flixel.util.FlxColor;
import flixel.util.FlxPath;
import flixel.util.FlxPoint;

enum Behavior {
    Idle;
    Running;
}

class Adventurer extends FlxSprite {

    static var speedIdle : Float = 0.3;
    static var speedRun : Float = 0.9;
    static var tileWidth : Int = PlayState.tileWidth;
    static var tileHeight : Int = PlayState.tileHeight;

    public var path : FlxPath;

    private var behavior : Behavior;
    private var lastPathed : Int;
    private var lastSawCube : Int;
    private var nodes : Array<FlxPoint>;
    private var player : Player;
    private var ticks : Int;
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
                this.behavior = Running;
                lastSawCube = ticks;
                lastPathed = -10000;  // force re-path
            }

        case Running:
            if (ticks - lastPathed > 29) {
                var anglePlayerToMe = FlxAngle.angleBetween(player, this);
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
                for (point in [candidate(6, 0),
                               candidate(5, 0),
                               candidate(5, 10),
                               candidate(5, -10),
                               candidate(4, 0),
                               candidate(4, 30),
                               candidate(4, -30),
                               candidate(4, 50),
                               candidate(4, -50),
                               candidate(3, 0),
                               candidate(3, 50),
                               candidate(3, -50),
                               candidate(3, 70),
                               candidate(3, -70),
                               candidate(2, 0),
                               candidate(2, 70),
                               candidate(2, -70),
                               candidate(2, 90),
                               candidate(2, -90),
                               candidate(1, 0),
                               candidate(1, 90),
                               candidate(1, -90)]) {
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

                // Check if we should stop running
                if (canSeePlayer()) {
                    lastSawCube = ticks;
                }
                if (ticks - lastSawCube > 8 * 60) {
                    behavior = Idle;
                }
            }

        }

        if (!path.finished && path.nodes != null) {
            if (path.angle <= 45 && path.angle >= -45) {
                animation.play("up");
            } else if (path.angle >= 135 && path.angle <= -135) {
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

    }

}
