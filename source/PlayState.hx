package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;
import openfl.Assets;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{

    static inline public var tileWidth : Int = 16;
    static inline public var tileHeight : Int = 16;

    private var player : Player;
    private var tilemap : FlxTilemap;

    /**
     * Function that is called up when to state is created to set
     * it up.
     */
    override public function create():Void {
        super.create();

        tilemap = new FlxTilemap();
        tilemap.loadMap(Assets.getText("assets/data/sans-titre.csv"),
                        "assets/images/floortiles.png",
                        tileWidth, tileHeight, 0, 1);
        tilemap.setTileProperties(1, FlxObject.NONE);
        tilemap.setTileProperties(2, FlxObject.ANY);
        add(tilemap);

        player = new Player(16, 16, tilemap);
        add(player);
    }

    /**
     * Function that is called when this state is destroyed - you
     * might want to consider setting all objects this state uses
     * to null to help garbage collection.
     */
    override public function destroy():Void {
        super.destroy();
    }

    /**
     * Function that is called once every frame.
     */
    override public function update():Void {
        super.update();
    }
}
