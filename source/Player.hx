package ;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxRandom;

class Player extends FlxSpriteGroup {

    static inline var alphaHiding : Float = 0.03;
    static inline var alphaMoving : Float = 0.3;
    static inline var hideDelay : Float = 0.3;
    static inline var speed : Float = 1.3;
    static var tileWidth : Int = PlayState.tileWidth;
    static var tileHeight : Int = PlayState.tileHeight;

    public var cube : FlxSprite;
    public var hiding(get, null) : Bool;
    public var tilemap : FlxTilemap;

    private var digestees : Array<Digestee>;
    private var lastMoved : Int;
    private var ticks : Int;
    private var wasMoving : Bool;

    public function new(X : Float = 0, Y : Float = 0, tilemap : FlxTilemap) {
        super(X, Y);

        this.tilemap = tilemap;

        cube = new FlxSprite(0, 0);
        add(cube);
        cube.makeGraphic(32, 32, FlxColor.AQUAMARINE);
        cube.alpha = alphaHiding;
        digestees = new Array<Digestee>();

        wasMoving = false;

        ticks = 0;
        lastMoved = -10000;
    }

    public function get_hiding() : Bool {
        return (!wasMoving) && (ticks - lastMoved > hideDelay * 60 / 2);
    }

    public function eat(adv : Adventurer) : Void {
        var digestee = new Digestee();
        digestee.x = FlxRandom.floatRanged(3,
                                           cube.width - digestee.width - 3);
        digestee.y = FlxRandom.floatRanged(3,
                                           cube.height - digestee.height - 3);
        digestees.push(digestee);
        add(digestee);
        adv.kill();
    }

    override public function update() : Void {
        super.update();

        ticks += 1;

        // Digest stuff
        var removees = new Array<Digestee>();
        for (digestee in digestees) {
            if (digestee.isDigested()) {
                removees.push(digestee);
            }
        }
        for (removee in removees) {
            digestees.remove(removee);
            removee.destroy();
        }

        // Movement
        //
        // this whole complex movement system is built on the
        // assumption that we will only ever move inside corridors
        // exactly wide enough to hold us.  Things will probably go
        // wonky if the maps ever break that assumption.

        var up  = FlxG.keys.anyPressed(["UP", "W"]);
        var down  = FlxG.keys.anyPressed(["DOWN", "R"]);
        var left  = FlxG.keys.anyPressed(["LEFT", "A"]);
        var right  = FlxG.keys.anyPressed(["RIGHT", "S"]);

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
        }

        if (!wasMoving) {
            if (up || down || left || right) {
                wasMoving = true;
                FlxTween.tween(cube, {alpha: alphaMoving}, hideDelay,
                               {ease: FlxEase.quadIn});
            }
        } else {
            if (!(up || down || left || right)) {
                wasMoving = false;
                FlxTween.tween(cube, {alpha: alphaHiding}, hideDelay,
                               {ease: FlxEase.quadIn});
            }
        }
    }

}

class Digestee extends FlxSprite {

    static inline var lifespan : Int = 400;
    private var ticks : Int;

    public function new() {
        super();
        ticks = 0;
        makeGraphic(10, 10, FlxColor.WHITE);
    }

    public inline function isDigested() : Bool {
        return ticks >= lifespan;
    }

    override public function update() {
        super.update();

        ticks += 1;

        alpha = 0.1 + 0.9 * (1 - ticks / lifespan);

        // wobble around a bit
        if (FlxRandom.chanceRoll(100/120)) {
            var offset : Float;
            if (FlxRandom.chanceRoll(50)) {
                offset = 1;
            } else {
                offset = -1;
            }
            if (FlxRandom.chanceRoll(50)) {
                x += offset;
            } else {
                y += offset;
            }
        }
    }

}
