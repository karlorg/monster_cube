package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxMath;
import flixel.util.FlxRandom;
import openfl.Assets;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{

    static inline public var tileWidth : Int = 16;
    static inline public var tileHeight : Int = 16;

    private var adventurers : Array<Adventurer>;
    private var player : Player;
    private var shots : Array<Shot>;
    private var tilemap : FlxTilemap;
    private var treasure : FlxSprite;

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

        player = new Player(9 * tileWidth, 11 * tileHeight, tilemap);
        add(player);

        FlxG.camera.follow(player.cube, FlxCamera.STYLE_LOCKON);

        treasure = new FlxSprite(9 * tileWidth, 17 * tileHeight);
        treasure.makeGraphic(tileWidth, tileHeight, FlxColor.GOLDEN);
        add(treasure);

        adventurers = new Array<Adventurer>();
        for (i in 0...10) {
            spawnAdventurer();
        }

        shots = new Array<Shot>();
    }

    private function spawnAdventurer() : Void {
        var x = -1;
        var y = -1;
        do {
            x = FlxRandom.intRanged(0, 20);
            y = FlxRandom.intRanged(0, 20);
        } while (tilemap.getTile(x, y) != 1);
        var adv = new Adventurer(x, y, this, tilemap, player, treasure);
        adventurers.push(adv);
        add(adv);
    }

    public function shoot(adv : Adventurer, shotAngle : Float) {
        var shot = new Shot(adv.x, adv.y, shotAngle);
        shots.push(shot);
        add(shot);
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

        // Collisions
        for (adv in adventurers) {
            if (player.cube.overlaps(adv)) {
                onAdventurerCollision(player, adv);
            }
        }

        {
            var removees = new Array<Shot>();
            for (shot in shots) {
                if (tilemap.overlaps(shot)) {
                    removees.push(shot);
                }
            }
            for (removee in removees) {
                removees.remove(removee);
                removee.destroy();
            }
        }
    }

    private function onAdventurerCollision(player : Player, adv : Adventurer)
        : Void {
        if (player.exists && adv.exists) {
            player.eat(adv);
        }
    }

}
