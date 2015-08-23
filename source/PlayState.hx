package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxMath;
import flixel.util.FlxPoint;
import flixel.util.FlxRandom;
import openfl.Assets;

using flixel.util.FlxSpriteUtil;

class PlayState extends FlxState
{

    static inline var spawnDelay : Int = 5 * 60;
    static private var spawnPoints : Array<Array<Int>> = [
        [0, 1], [4, 0], [10, 0], [18, 0], [19, 5]
        ];
    static inline public var tileWidth : Int = 16;
    static inline public var tileHeight : Int = 16;

    private var adventurers : Array<Adventurer>;
    private var hud : HUD;
    private var deadState : Bool;
    private var lastAdvSpawn : Int;
    private var player : Player;
    private var shots : FlxGroup;
    private var ticks : Int;
    private var tilemap : FlxTilemap;
    private var treasure : FlxSprite;
    private var treasureCarrier : Null<Adventurer>;
    private var treasureTakenState : Bool;

    override public function create():Void {
        super.create();

        ticks = 0;
        lastAdvSpawn = -10000;

        deadState = false;
        treasureTakenState = false;

        tilemap = new FlxTilemap();
        tilemap.loadMap(Assets.getText("assets/data/sans-titre.csv"),
                        "assets/images/floortiles.png",
                        tileWidth, tileHeight, 0, 1);
        tilemap.setTileProperties(1, FlxObject.NONE);
        tilemap.setTileProperties(2, FlxObject.ANY);
        add(tilemap);

        FlxG.worldBounds.set(0, 0, tilemap.width, tilemap.height);

        player = new Player(9 * tileWidth, 11 * tileHeight, tilemap);
        add(player);

        FlxG.camera.follow(player.cube, FlxCamera.STYLE_LOCKON);

        hud = new HUD(player);
        add(hud);
        hud.update();

        treasure = new Treasure(9 * tileWidth, 17 * tileHeight);
        add(treasure);
        treasureCarrier = null;

        adventurers = new Array<Adventurer>();

        shots = new FlxGroup();
        shots.maxSize = 16;
        add(shots);
        for (i in 0...16) {
            shots.add(new Shot());
        }
    }

    private function spawnAdventurer() : Void {
        var spawn = FlxRandom.getObject(spawnPoints);
        var x = spawn[0];
        var y = spawn[1];
        var adv = new Adventurer(x, y, this, tilemap, player, treasure);
        adventurers.push(adv);
        add(adv);
    }

    public function shoot(adv : Adventurer, shotAngle : Float) {
        var shot = cast(shots.recycle(), Shot);
        if (shot != null) {
            shot.shoot(Math.floor(adv.x), Math.floor(adv.y), shotAngle);
        }
    }

    /**
     * Function that is called when this state is destroyed - you
     * might want to consider setting all objects this state uses
     * to null to help garbage collection.
     */
    override public function destroy():Void {
        super.destroy();
    }

    override public function update():Void {
        if (deadState || treasureTakenState) {
            if (FlxG.keys.justPressed.R) {
                FlxG.switchState(new PlayState());
            }
            return;
        }

        ticks += 1;

        FlxG.collide(shots, tilemap);

        super.update();

        // Collisions
        for (adv in adventurers) {
            if (player.cube.overlaps(adv)) {
                onAdventurerCollision(player, adv);
            }
            if (adv.overlaps(treasure)) {
                onPickupTreasure(adv);
            }
        }
        FlxG.overlap(shots, player.cube, onPlayerShot);

        hud.update();

        // spawn adventurer
        if (ticks - lastAdvSpawn > spawnDelay) {
            lastAdvSpawn = ticks;
            spawnAdventurer();
        }

        if (treasureCarrier != null) {
            treasure.x = treasureCarrier.x;
            treasure.y = treasureCarrier.y;
        }

        // check for adventurers escaping with treasure
        if (treasure.x < 4 || treasure.y < 4
            || treasure.x > FlxG.worldBounds.width - treasure.width - 4) {
            treasureTakenState = true;
            var followee = new FlxObject(player.cube.x + player.cube.width / 2,
                                         player.cube.y + player.cube.height / 2);
            FlxG.camera.follow(followee);
            FlxTween.tween(followee,
                           {x: treasure.x, y: treasure.y},
                           1.5,
                           {ease: FlxEase.quadInOut,
                            complete: onTreasureTweenComplete});
        }
    }

    private function onAdventurerCollision(player : Player, adv : Adventurer)
        : Void {
        if (player.exists && adv.exists) {
            if (adv.isCarryingTreasure()) {
                treasureCarrier = null;
                adv.dropTreasure();
            }
            player.eat(adv);
        }
    }

    private function onPlayerShot(shot: FlxObject, cube: FlxObject) {
        shot.kill();
        player.onShot();
        if (player.hp <= 0) {
            deadState = true;
            FlxTween.color(player.cube, 3.0,
                           player.cube.color, FlxColor.BLACK,
                           player.cube.alpha, 0.8,
                           {ease: FlxEase.quadInOut,
                            complete: playerDeathComplete});
        }
    }

    private function onPickupTreasure(adv : Adventurer) {
        if (treasureCarrier == null) {
            treasureCarrier = adv;
            adv.pickupTreasure();
        }
    }

    private function playerDeathComplete(t : FlxTween) : Void {
        var msg = new FlxText(0, 0, -1, "Game Over\nPress R to restart", 20);
        msg.alignment = "center";
        msg.scrollFactor.x = 0;
        msg.scrollFactor.y = 0;
        msg.screenCenter();
        add(msg);
    }

    private function onTreasureTweenComplete(t : FlxTween) : Void {
        var msg = new FlxText(0, 0, -1, "Game Over\nPress R to restart", 20);
        msg.alignment = "center";
        msg.scrollFactor.x = 0;
        msg.scrollFactor.y = 0;
        msg.screenCenter();
        add(msg);
    }

}
