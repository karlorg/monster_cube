package ;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;

class HUD extends FlxSpriteGroup {

    private var healthDisplay : FlxBar;
    private var player : Player;

    public function new(player : Player) {
        super();

        this.player = player;

        // don't scroll with map
        scrollFactor.x = 0;
        scrollFactor.y = 0;

        healthDisplay = new FlxBar(4, 4, FlxBar.FILL_LEFT_TO_RIGHT, 100, 4);
        healthDisplay.createFilledBar(FlxColor.CRIMSON, FlxColor.FOREST_GREEN);
        add(healthDisplay);
    }

    override public function update() {
        healthDisplay.currentValue = player.hp;
        healthDisplay.setRange(0, 10);
    }

}
