package ;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxAngle;
import flixel.util.FlxColor;

class Shot extends FlxSprite {

    static var speed : Float = 2.0;
    static var tileWidth : Int = PlayState.tileWidth;
    static var tileHeight : Int = PlayState.tileHeight;

    public function new() {
        super();

        loadGraphic("assets/images/arrow.png",
                    false,  // animated
                    16, 16);
        width = 3;
        height = 10;
        offset.x = 6;
        offset.y = 2;

        exists = false;
    }

    public function shoot(x : Int, y : Int, shotAngle: Float) : Void {
        super.reset(x, y);

        solid = true;
        angle = shotAngle + 180;
        var moveVector = FlxAngle.rotatePoint(0, -speed * 60,
                                              0, 0, angle + 180);
        velocity.x = moveVector.x;
        velocity.y = moveVector.y;
    }

    override public function update() : Void {
        if (!alive) {
            exists = false;
        }
        if (getScreenXY().x < -64 || getScreenXY().x > FlxG.width + 64) {
            // If the shot makes it 64 pixels off the side of the
            // screen, kill it
            kill();
        } else if (touching != 0) {
            kill();
        } else {
            super.update();
        }
    }

}
