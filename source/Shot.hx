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
        this.angle = shotAngle;

        makeGraphic(2, 2, FlxColor.WHITE);
    }

    override public function update() : Void {
        super.update();

        var moveVector = FlxAngle.rotatePoint(0, -speed, 0, 0, angle);
        x += moveVector.x;
        y += moveVector.y;
    }

}
