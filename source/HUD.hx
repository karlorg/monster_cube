package ;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;

class HUD extends FlxSpriteGroup {

    private var healthDisplay : FlxBar;
    private var player : Player;
    private var seconds : Int;
    private var timeDisplay : FlxText;

    public function new(player : Player) {
        super();

        this.player = player;
        seconds = 0;

        // don't scroll with map
        scrollFactor.x = 0;
        scrollFactor.y = 0;

        healthDisplay = new FlxBar(4, 4, FlxBar.FILL_LEFT_TO_RIGHT, 100, 4);
        healthDisplay.createFilledBar(FlxColor.CRIMSON, FlxColor.FOREST_GREEN);
        add(healthDisplay);

        timeDisplay = new FlxText(FlxG.width - 4 - 10, 4, -1,
                                  Std.string(seconds), 10, false);
        add(timeDisplay);
    }

    public function setSeconds(secs : Int) {
        seconds = secs;
    }

    override public function update() {
        healthDisplay.currentValue = player.hp;
        healthDisplay.setRange(0, 10);

        timeDisplay.x = FlxG.width - 4 - 10 * Std.string(seconds).length;
        timeDisplay.text = Std.string(seconds);
    }

}
