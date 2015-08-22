package ;

import flixel.FlxSprite;
import flixel.tile.FlxTilemap;
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

        switch (behavior) {
        case Idle:
            var startPoint = FlxPoint.get(x + width / 2,
                                          y + height / 2);
            var playerPoint = FlxPoint.get(player.x + player.width / 2,
                                           player.y + player.height / 2);
            if (tilemap.ray(startPoint, playerPoint)) {
                var distance = startPoint.distanceTo(playerPoint);
                if (distance / tileWidth < 5) {
                    this.behavior = Running;
                    makeGraphic(10, 10, FlxColor.RED);
                }
            }
        case Running:
        }
    }

}
