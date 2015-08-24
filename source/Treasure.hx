package ;

import flixel.FlxG;
import flixel.FlxSprite;

class Treasure extends FlxSprite {

    static inline var teleportDelay : Int = 60 * 30;
    static var tileWidth : Int = PlayState.tileWidth;
    static var tileHeight : Int = PlayState.tileHeight;

    private var carried : Bool;
    private var homeX : Int;
    private var homeY : Int;
    private var lastTouched : Int;
    private var ticks : Int;

    public function new(x : Int, y : Int) {
        super();

        this.x = x;
        this.y = y;
        homeX = x;
        homeY = y;
        carried = false;

        loadGraphic("assets/images/treasure.png", false, 16, 16);

        ticks = 0;
        lastTouched = 0;
    }

    public function pickedUp() : Void {
        carried = true;
    }

    public function dropped() : Void {
        carried = false;
    }

    override public function update() : Void {
        ticks += 1;

        super.update();

        if (carried) {
            lastTouched = ticks;
        }

        if (x != homeX || y != homeY) {
            if (ticks - lastTouched > teleportDelay) {
                x = homeX;
                y = homeY;
            }
        }
    }

}
