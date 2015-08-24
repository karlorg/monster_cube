package ;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxTypedSpriteGroup;
import flixel.system.FlxSound;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxRandom;

class Player extends FlxSpriteGroup {

    static inline var alphaHiding : Float = 0.03;
    static inline var alphaHurt : Float = 0.7;
    static inline var alphaMoving : Float = 0.3;
    static inline var colorHurt = FlxColor.RED;
    static inline var colorNormal = FlxColor.AQUAMARINE;
    static inline var hideDelay : Float = 0.3;
    static inline var moveSndDelayMin : Int = 25;
    static inline var moveSndDelayMax : Int = 40;
    static inline var speed : Float = 1.3;
    static var tileWidth : Int = PlayState.tileWidth;
    static var tileHeight : Int = PlayState.tileHeight;

    public var cube : FlxSprite;
    public var hp(default, null) : Int;
    public var hiding(get, null) : Bool;
    public var tilemap : FlxTilemap;

    private var alphaTween : Null<FlxTween>;
    private var digestees : FlxTypedSpriteGroup<Digestee>;
    private var lastMoved : Int;
    private var lastMoveSnd : Int;
    private var sndDigest : FlxSound;
    private var sndMovement : Array<FlxSound>;
    private var ticks : Int;
    private var wasMoving : Bool;

    public function new(X : Float = 0, Y : Float = 0, tilemap : FlxTilemap) {
        super(X, Y);

        this.tilemap = tilemap;

        cube = new FlxSprite(0, 0);
        cube.makeGraphic(32, 32, colorNormal);
        cube.alpha = alphaHiding;

        digestees = new FlxTypedSpriteGroup<Digestee>();
        digestees.maxSize = 8;
        for (i in 0...8) {
            digestees.add(new Digestee(cube));
        }
        add(digestees);
        add(cube);

        sndDigest = FlxG.sound.load("assets/sounds/digest.wav");

        sndMovement = new Array<FlxSound>();
        sndMovement.push(
            FlxG.sound.load("assets/sounds/slurp0.wav"));
        sndMovement.push(
            FlxG.sound.load("assets/sounds/slurp1.wav"));
        sndMovement.push(
            FlxG.sound.load("assets/sounds/slurp2.wav"));
        sndMovement.push(
            FlxG.sound.load("assets/sounds/slurp3.wav"));
        sndMovement.push(
            FlxG.sound.load("assets/sounds/slurp4.wav"));
        sndMovement.push(
            FlxG.sound.load("assets/sounds/slurp5.wav"));
        sndMovement.push(
            FlxG.sound.load("assets/sounds/slurp6.wav"));
        sndMovement.push(
            FlxG.sound.load("assets/sounds/slurp7.wav"));
        sndMovement.push(
            FlxG.sound.load("assets/sounds/slurp8.wav"));
        sndMovement.push(
            FlxG.sound.load("assets/sounds/slurp9.wav"));
        sndMovement.push(
            FlxG.sound.load("assets/sounds/slurp10.wav"));

        wasMoving = false;

        ticks = 0;
        lastMoved = -10000;
        lastMoveSnd = -10000;
        alphaTween = null;

        hp = 10;
    }

    override public function destroy() : Void {
        sndMovement = FlxDestroyUtil.destroyArray(sndMovement);
        super.destroy();
    }

    public function get_hiding() : Bool {
        return (!wasMoving)
            && (digestees.countLiving() == 0)
            && (ticks - lastMoved > hideDelay * 60 / 2);
    }

    public function eat(adv : Adventurer) : Void {
        var xStart = cube.x + adv.x - this.x;
        var yStart = cube.y + adv.y - this.y;

        var digestee : Digestee = cast(digestees.recycle(), Digestee);
        if (digestee == null) {
            digestee = cast(digestees.getRandom(), Digestee);
            digestee.kill();
        }
        digestee.spawn(Std.int(xStart), Std.int(yStart));

        adv.kill();
    }

    public function onShot() : Void {
        if (hp > 0) {
            hp -= 1;
        }

        var targetAlpha : Float = 0;
        if (wasMoving) {
            targetAlpha = alphaMoving;
        } else {
            targetAlpha = alphaHiding;
        }
        FlxTween.color(cube, 0.3,
                       colorHurt, colorNormal,
                       alphaHurt, targetAlpha);
    }

    override public function update() : Void {
        super.update();

        ticks += 1;

        // Digest stuff
        digestees.forEachAlive(function (d : Digestee) {
                if (d.isDigested()) {
                    d.kill();
                    if (hp < 10) {
                        hp += 1;
                    }
                    sndDigest.play();
                }
            });

        // Movement
        //
        // this whole complex movement system is built on the
        // assumption that we will only ever move inside corridors
        // exactly wide enough to hold us.  Things will probably go
        // wonky if the maps ever break that assumption.

        var up  = FlxG.keys.anyPressed(["UP", "W"]);
        var down  = FlxG.keys.anyPressed(["DOWN", "S"]);
        var left  = FlxG.keys.anyPressed(["LEFT", "A"]);
        var right  = FlxG.keys.anyPressed(["RIGHT", "D"]);

        if (up && down) { up = down = false; }
        if (left && right) { left = right = false; }

        inline function isWall(tileIndex : Int) : Bool {
            return (tilemap.getTileCollisions(tileIndex) != FlxObject.NONE);
        }

        // Cornering
        //
        // Adjust our requested movement direction and, if necessary,
        // move laterally so that we are lined up with the corridor
        // we're supposed to be moving along.

        if (left) {
            var tile_top = tilemap.getTile(Math.floor((x-1) / tileWidth),
                                           Math.floor(y / tileHeight));
            var tile_near_top = tilemap.getTile(
                Math.floor((x-1) / tileWidth),
                Math.floor((y+speed) / tileHeight));
            var tile_above_center = tilemap.getTile(
                Math.floor((x-1) / tileWidth),
                Math.floor((y+15) / tileHeight));
            var tile_below_center = tilemap.getTile(
                Math.floor((x-1) / tileWidth),
                Math.floor((y+16) / tileHeight));
            var tile_near_bottom = tilemap.getTile(
                Math.floor((x-1) / tileWidth),
                Math.floor((y+31-speed) / tileHeight));
            var tile_bottom = tilemap.getTile(Math.floor((x-1) / tileWidth),
                                              Math.floor((y+31) / tileHeight));
            if (isWall(tile_above_center) || isWall(tile_below_center)) {
                // Don't try to move if our centre would hit a wall
                left = false;
            } else if (isWall(tile_near_top) && isWall(tile_near_bottom)) {
                // don't try to move if we'd run into walls near both
                // our top and bottom edges
                left = false;
            } else if (isWall(tile_top)) {
                // only top is blocked
                if (isWall(tile_near_top)) {
                    // not far enough down to slip into the requested
                    // corridor; we'll move down toward the junction
                    // instead
                    left = false;
                    down = true;
                } else {
                    // we're close enough to the junction that we
                    // should just pop ourselves into the new corridor
                    y = Math.ceil(y / tileHeight) * tileHeight;
                }
            } else if (isWall(tile_bottom)) {
                // only bottom is blocked
                if (isWall(tile_near_bottom)) {
                    // not far enough down to slip into the requested
                    // corridor; we'll move up toward the junction
                    // instead
                    left = false;
                    up = true;
                } else {
                    // we're close enough to the junction that we
                    // should just pop ourselves into the new corridor
                    y = Math.floor(y / tileHeight) * tileHeight;
                }
            }
        }

        if (right) {
            var tile_top = tilemap.getTile(Math.floor((x+32) / tileWidth),
                                           Math.floor(y / tileHeight));
            var tile_near_top = tilemap.getTile(
                Math.floor((x+32) / tileWidth),
                Math.floor((y+speed) / tileHeight));
            var tile_above_center = tilemap.getTile(
                Math.floor((x+32) / tileWidth),
                Math.floor((y+15) / tileHeight));
            var tile_below_center = tilemap.getTile(
                Math.floor((x+32) / tileWidth),
                Math.floor((y+16) / tileHeight));
            var tile_near_bottom = tilemap.getTile(
                Math.floor((x+32) / tileWidth),
                Math.floor((y+31-speed) / tileHeight));
            var tile_bottom = tilemap.getTile(Math.floor((x+32) / tileWidth),
                                              Math.floor((y+31) / tileHeight));
            if (isWall(tile_above_center) || isWall(tile_below_center)) {
                // Don't try to move if our centre would hit a wall
                right = false;
            } else if (isWall(tile_near_top) && isWall(tile_near_bottom)) {
                // don't try to move if we'd run into walls near both
                // our top and bottom edges
                right = false;
            } else if (isWall(tile_top)) {
                // only top is blocked
                if (isWall(tile_near_top)) {
                    // not far enough down to slip into the requested
                    // corridor; we'll move down toward the junction
                    // instead
                    right = false;
                    down = true;
                } else {
                    // we're close enough to the junction that we
                    // should just pop ourselves into the new corridor
                    y = Math.ceil(y / tileHeight) * tileHeight;
                }
            } else if (isWall(tile_bottom)) {
                // only bottom is blocked
                if (isWall(tile_near_bottom)) {
                    // not far enough down to slip into the requested
                    // corridor; we'll move up toward the junction
                    // instead
                    right = false;
                    up = true;
                } else {
                    // we're close enough to the junction that we
                    // should just pop ourselves into the new corridor
                    y = Math.floor(y / tileHeight) * tileHeight;
                }
            }
        }

        if (down) {
            var tile_left = tilemap.getTile(Math.floor(x / tileWidth),
                                            Math.floor((y+32) / tileHeight));
            var tile_near_left = tilemap.getTile(
                Math.floor((x+speed) / tileWidth),
                Math.floor((y+32) / tileHeight));
            var tile_left_of_center = tilemap.getTile(
                Math.floor((x+15) / tileWidth),
                Math.floor((y+32) / tileHeight));
            var tile_right_of_center = tilemap.getTile(
                Math.floor((x+16) / tileWidth),
                Math.floor((y+32) / tileHeight));
            var tile_near_right = tilemap.getTile(
                Math.floor((x+31-speed) / tileWidth),
                Math.floor((y+32) / tileHeight));
            var tile_right = tilemap.getTile(Math.floor((x+31) / tileWidth),
                                             Math.floor((y+32) / tileHeight));
            if (isWall(tile_left_of_center) || isWall(tile_right_of_center)) {
                // Don't try to move if our centre would hit a wall
                down = false;
            } else if (isWall(tile_near_left) && isWall(tile_near_right)) {
                // don't try to move if we'd run into walls near both
                // our left and right edges
                down = false;
            } else if (isWall(tile_left)) {
                // only left is blocked
                if (isWall(tile_near_left)) {
                    // not far enough right to slip into the requested
                    // corridor; we'll move right toward the junction
                    // instead
                    down = false;
                    right = true;
                } else {
                    // we're close enough to the junction that we
                    // should just pop ourselves into the new corridor
                    x = Math.ceil(x / tileWidth) * tileWidth;
                }
            } else if (isWall(tile_right)) {
                // only right is blocked
                if (isWall(tile_near_right)) {
                    // not far enough left to slip into the requested
                    // corridor; we'll move left toward the junction
                    // instead
                    down = false;
                    left = true;
                } else {
                    // we're close enough to the junction that we
                    // should just pop ourselves into the new corridor
                    x = Math.floor(x / tileWidth) * tileWidth;
                }
            }
        }

        if (up) {
            var tile_left = tilemap.getTile(Math.floor(x / tileWidth),
                                            Math.floor((y-1) / tileHeight));
            var tile_near_left = tilemap.getTile(
                Math.floor((x+speed) / tileWidth),
                Math.floor((y-1) / tileHeight));
            var tile_left_of_center = tilemap.getTile(
                Math.floor((x+15) / tileWidth),
                Math.floor((y-1) / tileHeight));
            var tile_right_of_center = tilemap.getTile(
                Math.floor((x+16) / tileWidth),
                Math.floor((y-1) / tileHeight));
            var tile_near_right = tilemap.getTile(
                Math.floor((x+31-speed) / tileWidth),
                Math.floor((y-1) / tileHeight));
            var tile_right = tilemap.getTile(Math.floor((x+31) / tileWidth),
                                             Math.floor((y-1) / tileHeight));
            if (isWall(tile_left_of_center) || isWall(tile_right_of_center)) {
                // Don't try to move if our centre would hit a wall
                up = false;
            } else if (isWall(tile_near_left) && isWall(tile_near_right)) {
                // don't try to move if we'd run into walls near both
                // our left and right edges
                up = false;
            } else if (isWall(tile_left)) {
                // only left is blocked
                if (isWall(tile_near_left)) {
                    // not far enough right to slip into the requested
                    // corridor; we'll move right toward the junction
                    // instead
                    up = false;
                    right = true;
                } else {
                    // we're close enough to the junction that we
                    // should just pop ourselves into the new corridor
                    x = Math.ceil(x / tileWidth) * tileWidth;
                }
            } else if (isWall(tile_right)) {
                // only right is blocked
                if (isWall(tile_near_right)) {
                    // not far enough left to slip into the requested
                    // corridor; we'll move left toward the junction
                    // instead
                    up = false;
                    left = true;
                } else {
                    // we're close enough to the junction that we
                    // should just pop ourselves into the new corridor
                    x = Math.floor(x / tileWidth) * tileWidth;
                }
            }
        }

        // No moving diagonally!  If we're still trying to go
        // diagonally at this point, we arbitrarily pick a single
        // direction to move.
        if (up || down) { left = right = false; }

        // Movement along corridors
        //
        // Here we assume we are lined up to move along a corridor in
        // the direction we're trying to go (the cornering system
        // above should have taken care of this).
        if (up) {
            y -= speed;
            var tile0 = tilemap.getTile(Math.floor(x / tileWidth),
                                        Math.floor(y / tileHeight));
            var tile1 = tilemap.getTile(Math.floor(x / tileWidth) + 1,
                                        Math.floor(y / tileHeight));
            if (isWall(tile0) || isWall(tile1)) {
                y = Math.floor(y / tileHeight + 1) * tileHeight;
            }
        } else if (down) {
            y += speed;
            var tile0 = tilemap.getTile(Math.floor(x / tileWidth),
                                        Math.floor((y+31) / tileHeight));
            var tile1 = tilemap.getTile(Math.floor(x / tileWidth) + 1,
                                        Math.floor((y+31) / tileHeight));
            if (isWall(tile0) || isWall(tile1)) {
                y = Math.floor(y / tileHeight) * tileHeight;
            }
        }
        if (left) {
            x -= speed;
            var tile0 = tilemap.getTile(Math.floor(x / tileWidth),
                                        Math.floor(y / tileHeight));
            var tile1 = tilemap.getTile(Math.floor(x / tileWidth),
                                        Math.floor(y / tileHeight) + 1);
            if (isWall(tile0) || isWall(tile1)) {
                x = Math.floor(x / tileWidth + 1) * tileWidth;
            }
        } else if (right) {
            x += speed;
            var tile0 = tilemap.getTile(Math.floor((x+31) / tileWidth),
                                        Math.floor(y / tileHeight));
            var tile1 = tilemap.getTile(Math.floor((x+31) / tileWidth),
                                        Math.floor(y / tileHeight) + 1);
            if (isWall(tile0) || isWall(tile1)) {
                x = Math.floor(x / tileWidth) * tileWidth;
            }
        }

        if (up || down || left || right) {
            lastMoved = ticks;
            if (ticks - lastMoveSnd > FlxRandom.intRanged(
                    moveSndDelayMin, moveSndDelayMax)) {
                var snd : FlxSound = FlxRandom.getObject(sndMovement);
                snd.play(true);
                lastMoveSnd = ticks;
            }
        }

        if (!wasMoving) {
            if (up || down || left || right) {
                wasMoving = true;
                if (alphaTween != null) { alphaTween.cancel(); }
                alphaTween = FlxTween.tween(cube,
                                            {alpha: alphaMoving}, hideDelay,
                                            {ease: FlxEase.quadIn});
            }
        } else {
            if (!(up || down || left || right)) {
                wasMoving = false;
                if (alphaTween != null) { alphaTween.cancel(); }
                alphaTween = FlxTween.tween(cube,
                                            {alpha: alphaHiding}, hideDelay,
                                            {ease: FlxEase.quadIn});
            }
        }
    }

}

class Digestee extends FlxSprite {

    static inline var lifespan : Int = 400;
    private var cube : FlxSprite;
    private var rotRate : Float;  // rotation in degrees per frame
    private var ticks : Int;
    private var xTarget : Float;
    private var yTarget : Float;

    public function new(cube : FlxSprite) {
        super();
        this.cube = cube;
        loadGraphic("assets/images/archer.png",
                    true,  // animated
                    16, 16);
        animation.add("rot", [12, 13, 14]);
        animation.play("rot");
        animation.curAnim.stop();
        animation.curAnim.curFrame = 0;

        exists = false;
    }

    public function spawn(x : Int, y : Int) : Void {
        super.reset(x, y);
        ticks = 0;

        rotRate = FlxRandom.floatRanged(-20 / 60, 20 / 60);

        var targetAngle = FlxRandom.floatRanged(-180, 180);
        FlxTween.tween(this, {angle: targetAngle}, 0.5,
                       {ease: FlxEase.quadIn});

        // can't tween the movement from outside the cube to inside
        // since tweens apparently don't know to follow the host
        // group's movement
        xTarget = FlxRandom.floatRanged(3, cube.width - width - 3);
        yTarget = FlxRandom.floatRanged(3, cube.height - height - 3);

        animation.play("rot");
        animation.curAnim.stop();
        animation.curAnim.curFrame = 0;

        alive = true;
        exists = true;
    }

    public inline function isDigested() : Bool {
        return ticks >= lifespan;
    }

    override public function update() {
        super.update();

        ticks += 1;

        alpha = 0.3 + 0.7 * (1 - ticks / lifespan);
        angle += rotRate;

        // manually tween sprite into position at start of life
        x += (cube.x + xTarget - x) * 0.1;
        y += (cube.y + yTarget - y) * 0.1;

        if (ticks / lifespan > 0.66) {
            animation.curAnim.curFrame = 2;
        } else if (ticks / lifespan > 0.33) {
            animation.curAnim.curFrame = 1;
        }

        // wobble around a bit
        if (FlxRandom.chanceRoll(100/120)) {
            var offset : Float;
            if (FlxRandom.chanceRoll(50)) {
                offset = 1;
            } else {
                offset = -1;
            }
            if (FlxRandom.chanceRoll(50)) {
                xTarget += offset;
            } else {
                yTarget += offset;
            }
        }
    }

}
