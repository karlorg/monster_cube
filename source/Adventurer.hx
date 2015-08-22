package ;

import flixel.FlxSprite;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;
import flixel.util.FlxPath;
import flixel.util.FlxPoint;

class Adventurer extends FlxSprite {

    static var tileWidth : Int = PlayState.tileWidth;
    static var tileHeight : Int = PlayState.tileHeight;

    public var path : FlxPath;

    private var nodes : Array<FlxPoint>;
    private var tilemap : FlxTilemap;

    public function new(x : Int, y : Int, tilemap : FlxTilemap) {
        super();
        this.tilemap = tilemap;
        this.x = x * tileWidth + 3;
        this.y = y * tileWidth + 3;

        makeGraphic(10, 10, FlxColor.WHITE);
    }
}
