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

        makeGraphic(10, 10, FlxColor.WHITE);

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
        var playerPoint = FlxPoint.get(player.x + player.width / 2,
                                       player.y + player.height / 2);
        var treasurePoint = FlxPoint.get(treasure.x + treasure.width / 2,
                                         treasure.y + treasure.height / 2);
        switch (behavior) {

        case Idle:
            if (ticks - lastPathed > 59) {
                nodes = tilemap.findPath(startPoint, treasurePoint, false);
                if (nodes.length > 0) {
                    path.start(this, nodes, speedIdle * 60);
                    lastPathed = ticks;
                }
            }

            if (tilemap.ray(startPoint, playerPoint)) {
                var distance = startPoint.distanceTo(playerPoint);
                if (distance / tileWidth < 5) {
                    this.behavior = Running;
                    lastSawCube = ticks;
                    lastPathed = -10000;  // force re-path
                    makeGraphic(10, 10, FlxColor.RED);
                }
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
                               candidate(3, 0),
                               candidate(3, 50),
                               candidate(3, -50),
                               candidate(2, 0),
                               candidate(2, 70),
                               candidate(2, -70),
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
                path.start(this, nodes, speedRun * 60);
                lastPathed = ticks;

                // Check if we should stop running
                if (tilemap.ray(startPoint, playerPoint)) {
                    var distance = startPoint.distanceTo(playerPoint);
                    if (distance / tileWidth < 5) {
                        lastSawCube = ticks;
                    }
                }
                if (ticks - lastSawCube > 8 * 60) {
                    behavior = Idle;
                    makeGraphic(10, 10, FlxColor.WHITE);
                }
            }

        }
    }

}
