package ;

import flixel.FlxG;
import flixel.FlxSprite;

class Treasure extends FlxSprite {

    static var tileWidth : Int = PlayState.tileWidth;
    static var tileHeight : Int = PlayState.tileHeight;

    public function new(x : Int, y : Int) {
        super();

        this.x = x;
        this.y = y;

        loadGraphic("assets/images/treasure.png", false, 16, 16);
    }

    override public function update() : Void {
        super.update();
    }

}
