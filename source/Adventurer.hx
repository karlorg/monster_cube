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

    static var speedRun : Float = 0.9;
    static var tileWidth : Int = PlayState.tileWidth;
    static var tileHeight : Int = PlayState.tileHeight;

    public var path : FlxPath;

    private var behavior : Behavior;
    private var nodes : Array<FlxPoint>;
    private var player : Player;
    private var tilemap : FlxTilemap;

    public function new(x : Int, y : Int,
                        tilemap : FlxTilemap, player : Player) {
        super();
        this.tilemap = tilemap;
        this.player = player;
        this.x = x * tileWidth + 3;
        this.y = y * tileWidth + 3;
        this.behavior = Idle;

        makeGraphic(10, 10, FlxColor.WHITE);

        path = new FlxPath();
    }

    override public function update() : Void {
        super.update();

        var startPoint = FlxPoint.get(x + width / 2,
                                      y + height / 2);
        var playerPoint = FlxPoint.get(player.x + player.width / 2,
                                       player.y + player.height / 2);
        switch (behavior) {
        case Idle:
            if (tilemap.ray(startPoint, playerPoint)) {
                var distance = startPoint.distanceTo(playerPoint);
                if (distance / tileWidth < 5) {
                    this.behavior = Running;
                    makeGraphic(10, 10, FlxColor.RED);
                }
            }

        case Running:
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
                                    Math.floor(point.y / tileHeight)) == 1) {
                    destPoint = point;
                    break;
                }
            }
            nodes = tilemap.findPath(startPoint, destPoint, false);
            path.start(this, nodes, speedRun * 60);

        }
    }

}
