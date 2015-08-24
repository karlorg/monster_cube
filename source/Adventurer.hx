package ;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flixel.tile.FlxTilemap;
import flixel.util.FlxAngle;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPath;
import flixel.util.FlxPoint;
import flixel.util.FlxRandom;

enum Behavior {
    Idle;
    Running;
    Shooting;
}

class Adventurer extends FlxSprite {

    static var speedIdle : Float = 0.3;
    static var speedRun : Float = 1.1;
    static var tileWidth : Int = PlayState.tileWidth;
    static var tileHeight : Int = PlayState.tileHeight;
    // viewAngle is the number of degrees away from straight ahead the
    // cube can be in order to be seen.  Will probably break if set
    // higher than 90.
    static var viewAngle : Int = 80;

    public var path : FlxPath;

    private var behavior : Behavior;
    private var carryingTreasure : Bool;
    private var lastShot : Int;
    private var lastPathed : Int;
    private var lastSawCube : Int;
    private var nodes : Array<FlxPoint>;
    private var player : Player;
    private var playState : PlayState;
    private var sndScreams : Array<FlxSound>;
    private var sndShoot : FlxSound;
    private var ticks : Int;
    private var ticksToRun : Int;
    private var tilemap : FlxTilemap;
    private var treasure : FlxSprite;

    public function new(playState : PlayState,
                        tilemap : FlxTilemap, player : Player,
                        treasure : FlxSprite) {
        super();
        this.playState = playState;
        this.tilemap = tilemap;
        this.player = player;
        this.treasure = treasure;
        this.behavior = Idle;
        carryingTreasure = false;

        loadGraphic("assets/images/archer.png",
                    true,  // animated
                    16, 16);
        width = height = 10;
        offset.x = offset.y = 3;
        animation.add("down", [0, 1, 0, 2]);
        animation.add("up", [3, 4, 3, 5]);
        animation.add("right", [6, 7, 6, 8]);
        animation.add("left", [9, 10, 9, 11]);

        path = new FlxPath();

        sndScreams = new Array<FlxSound>();
        sndScreams.push(
            FlxG.sound.load("assets/sounds/WilhelmScreamGurgly.wav"));
        sndScreams.push(
            FlxG.sound.load("assets/sounds/HowieScreamGurgly.wav"));

        sndShoot = FlxG.sound.load("assets/sounds/bowshot.wav");

        exists = false;
    }

    public function spawn(x : Int, y : Int) {
        super.reset(x * tileWidth + 3, y * tileWidth + 3);

        solid = true;
        ticks = 0;
        lastPathed = -10000;
        lastSawCube = -10000;
        ticksToRun = -1;
    }

    /**
     * Do anything necessary in response to being eaten.
     *
     * This does not include dying; the caller will take care of that.
     * At the moment it's just playing a sound effect.
     */
    public function reactToEaten() : Void {
        var snd = FlxRandom.getObject(sndScreams);
        snd.play();
    }

    public function pickupTreasure() : Void {
        carryingTreasure = true;
    }

    public function dropTreasure() : Void {
        carryingTreasure = false;
    }

    public function isCarryingTreasure() : Bool {
        return carryingTreasure;
    }

    override public function destroy() : Void {
        sndScreams = FlxDestroyUtil.destroyArray(sndScreams);
        super.destroy();
    }

    override public function update() : Void {
        if (!alive) {
            exists = false;
            return;
        }

        super.update();

        ticks += 1;

        var startPoint = FlxPoint.get(x + width / 2,
                                      y + height / 2);
        var playerPoint = FlxPoint.get(player.cube.x + player.cube.width / 2,
                                       player.cube.y + player.cube.height / 2);
        var treasurePoint = FlxPoint.get(treasure.x + treasure.width / 2,
                                         treasure.y + treasure.height / 2);
        var spawnPoint = new FlxPoint(8, 24);
        var anglePlayerToMe = FlxAngle.getAngle(startPoint, playerPoint);

        function canSeePlayer() : Bool {
            if ((!player.hiding) &&
                tilemap.ray(startPoint, playerPoint)) {
                var distance = startPoint.distanceTo(playerPoint);
                if (distance / tileWidth < 5) {
                    return true;
                }
            }
            return false;
        }

        function lookingAtPlayer() : Bool {
            // both have line of sight to player, and are facing the
            // right way to see it
            if (canSeePlayer()) {
                // not sure why this isn't +180 degrees
                var angleToPlayer = anglePlayerToMe;
                while (angleToPlayer > 360) { angleToPlayer -= 360; }
                switch (facing) {
                case FlxObject.UP:
                    return (angleToPlayer > -viewAngle)
                        && (angleToPlayer < viewAngle);
                case FlxObject.RIGHT:
                    return (angleToPlayer > 90-viewAngle)
                        && (angleToPlayer < 90+viewAngle);
                case FlxObject.DOWN:
                    return (angleToPlayer > 180-viewAngle)
                        || (angleToPlayer < -180+viewAngle);
                case FlxObject.LEFT:
                    return (angleToPlayer > -90-viewAngle)
                        && (angleToPlayer < -90+viewAngle);
                }
            }
            return false;
        }

        switch (behavior) {

        case Idle:
            if (ticks - lastPathed > 59) {
                if (!carryingTreasure) {
                    nodes = tilemap.findPath(startPoint, treasurePoint, false);
                } else {
                    nodes = tilemap.findPath(startPoint, spawnPoint, false);
                }
                if (nodes != null && nodes.length > 0) {
                    path.start(this, nodes, speedIdle * 60);
                    lastPathed = ticks;
                }
            }

            if (lookingAtPlayer()) {
                this.behavior = Shooting;
                lastShot = ticks;
                lastSawCube = ticks;
                lastPathed = -10000;  // force re-path
            }

            setAnimAndFacingFromPath();

        case Running:
            if (ticksToRun < 0) {
                ticksToRun = FlxRandom.intRanged(24, 34);
            }
            if (ticks - lastPathed > ticksToRun) {
                ticksToRun = -1;
                this.behavior = Shooting;
                lastShot = ticks;
            }
            if (canSeePlayer()) {
                lastSawCube = ticks;
            // Check if we should stop running
            } else if (ticks - lastSawCube > 8 * 60) {
                behavior = Idle;
            }

            setAnimAndFacingFromPath();

        case Shooting:
            path.cancel();

            if (ticks - lastShot < 10) {
                var angleToPlayer = anglePlayerToMe + 180;
                while (angleToPlayer > 180) { angleToPlayer -= 360; }

                if (ticks - lastShot == 5 && canSeePlayer()) {
                    sndShoot.play();
                    playState.shoot(this, angleToPlayer);
                }

                if (canSeePlayer()) {
                    if (angleToPlayer <= 45 && angleToPlayer >= -45) {
                        animation.play("up");
                    } else if (angleToPlayer >= 135 || angleToPlayer <= -135) {
                        animation.play("down");
                    } else if (angleToPlayer > 45 && angleToPlayer < 135) {
                        animation.play("right");
                    } else {
                        animation.play("left");
                    }
                    animation.curAnim.curFrame = 0;
                    animation.curAnim.stop();
                }
            } else {

                // pick a new path and start running again
                function candidate(dist : Float,
                                   rot : Float = 0.0) : FlxPoint {
                    var result = new FlxPoint(0, -dist * tileWidth);
                    result = FlxAngle.rotatePoint(result.x, result.y,
                                                  0, 0,
                                                  rot + anglePlayerToMe);
                    result.addPoint(startPoint);
                    return result;
                }
                var destPoint = startPoint;
                for (xy in [[6,0],
                            [5,0], [5,10], [5,-10],
                            [4,0], [4,30], [4,-30], [4,50], [4,-50],
                            [3,0], [3,50], [3,-50], [3,70], [3,-70],
                            [2,0], [2,70], [2,-70], [2,90], [2,-90],
                            [1,0], [1,90], [1,-90]]) {
                    var point = candidate(xy[0], xy[1]);
                    if (tilemap.getTile(Math.floor(point.x / tileWidth),
                                        Math.floor(point.y / tileHeight))
                        == 1) {
                        destPoint = point;
                        break;
                    }
                }
                nodes = tilemap.findPath(startPoint, destPoint, false);
                if (nodes != null && nodes.length > 0) {
                    path.start(this, nodes, speedRun * 60);
                }
                lastPathed = ticks;
                this.behavior = Running;

            }
        }

    }

    private function setAnimAndFacingFromPath() : Void {
        if (!path.finished && path.nodes != null) {
            if (path.angle >= -45 && path.angle <= 45) {
                animation.play("up");
                facing = FlxObject.UP;
            } else if (path.angle >= 135 || path.angle <= -135) {
                animation.play("down");
                facing = FlxObject.DOWN;
            } else if (path.angle > 45 && path.angle < 135) {
                animation.play("right");
                facing = FlxObject.RIGHT;
            } else {
                animation.play("left");
                facing = FlxObject.LEFT;
            }
        } else {
            animation.curAnim.curFrame = 0;
            animation.curAnim.stop();
            nodes = null;
        }
    }

}
