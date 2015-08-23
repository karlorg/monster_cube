package ;

import flixel.FlxSprite;
import flixel.util.FlxAngle;
import flixel.util.FlxColor;

class Shot extends FlxSprite {

    static var speed : Float = 2.0;
    static var tileWidth : Int = PlayState.tileWidth;
    static var tileHeight : Int = PlayState.tileHeight;

    public function new(x : Float, y : Float,
                        shotAngle : Float) {
        super();
        this.x = x;
        this.y = y;

        loadGraphic("assets/images/arrow.png",
                    false,  // animated
                    16, 16);
        offset.x = 7;
        offset.y = 6;
        angle = shotAngle + 180;
    }

    override public function update() : Void {
        super.update();

        var moveVector = FlxAngle.rotatePoint(0, -speed, 0, 0, angle + 180);
        x += moveVector.x;
        y += moveVector.y;
    }

}
