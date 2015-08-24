package ;

import flixel.FlxG;
import flixel.FlxSprite;

interface TreasureTeleportListener {
    public function onTreasureTeleport(trs : Treasure,
                                       oldX : Int, oldY : Int,
                                       newX : Int, newY : Int) : Void;
}

class Treasure extends FlxSprite {

    static inline var teleportDelay : Int = 60 * 15;
    static var tileWidth : Int = PlayState.tileWidth;
    static var tileHeight : Int = PlayState.tileHeight;

    private var carried : Bool;
    private var homeX : Int;
    private var homeY : Int;
    private var lastTouched : Int;
    private var teleportListeners : Array<TreasureTeleportListener>;
    private var ticks : Int;

    public function new(x : Int, y : Int) {
        super();

        this.x = x;
        this.y = y;
        homeX = x;
        homeY = y;
        carried = false;

        loadGraphic("assets/images/treasure.png", false, 16, 16);

        teleportListeners = new Array<TreasureTeleportListener>();

        ticks = 0;
        lastTouched = 0;
    }

    public function pickedUp() : Void {
        carried = true;
    }

    public function dropped() : Void {
        carried = false;
    }

    public function listenTeleport(l : TreasureTeleportListener) : Void {
        teleportListeners.push(l);
    }

    private function notifyTeleport() : Void {
        for (l in teleportListeners) {
            l.onTreasureTeleport(this, Std.int(x), Std.int(y), homeX, homeY);
        }
    }

    override public function update() : Void {
        ticks += 1;

        super.update();

        if (carried) {
            lastTouched = ticks;
        }

        if (x != homeX || y != homeY) {
            if (ticks - lastTouched > teleportDelay) {
                notifyTeleport();
                x = homeX;
                y = homeY;
            }
        }
    }

}
