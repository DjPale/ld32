import luxe.States;
import luxe.Input;
import luxe.Vector;

import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;

import luxe.physics.nape.DebugDraw;

import Main;

class GameView extends State
{
	var batcher : phoenix.Batcher;
	var global : GlobalData;

    var drawer : DebugDraw;

	public function new(name:String, _global:GlobalData, _batcher:phoenix.Batcher)
	{
		super({ name: name });

		batcher = _batcher;
		global = _global;
	}

	override function onenabled<T>(ignored:T)
    {
    	trace('enable $name');
    } //onenabled

    override function ondisabled<T>(ignored:T)
    {
    	trace('disable $name');
    } //ondisabled

    override function onenter<T>(ignored:T) 
    {
        trace('enter $name');

        setup();
    } //onenter

    override function onleave<T>(ignored:T)
    {
    	trace('leave $name');
    }

    function setup()
    {
        drawer = new DebugDraw();
        Luxe.physics.nape.debugdraw = drawer;

        tiles = new Array<Body>();
        gen_terrain();


        var p_body = new Body(BodyType.DYNAMIC);
        p_body.shapes.add(new Polygon(Polygon.box(64, 64)));
        p_body.position.setxy(150, Luxe.screen.mid.y);
        p_body.space = Luxe.physics.nape.space;
        p_body.allowRotation = false;

        drawer.add(p_body);
    }

    var tiles : Array<Body>;

    function gen_terrain(tilesize:Float = 30)
    {
        var sx : Int = 0;
        var sy : Int = Std.int((Luxe.screen.mid.y + 100) / tilesize);
        var ex : Int = Std.int(Luxe.screen.w / tilesize);
        var ey : Int = Std.int(Luxe.screen.h / tilesize);

        trace('$sx,$sy -> $ex,$ey');

        var ts_half = tilesize / 2.0;

        for (y in sy...ey)
        {
            for (x in sx...ex)
            {
                var b = new Body(BodyType.STATIC);
                b.shapes.add(new Polygon(Polygon.box(tilesize, tilesize)));

                var px = (x * tilesize) + ts_half;
                var py = (y * tilesize) + ts_half;

                b.position.setxy(px, py);
                b.space = Luxe.physics.nape.space;

                drawer.add(b);
            }
        }
    }

    function gen_projectile(pos:Vector)
    {
        var p_body = new Body(BodyType.DYNAMIC);
        p_body.shapes.add(new Polygon(Polygon.box(16, 16)));
        p_body.position.setxy(pos.x, pos.y);
        p_body.space = Luxe.physics.nape.space;

        drawer.add(p_body);

        p_body.applyImpulse(new Vec2(100, -50));
    }

    override function onmouseup(e:MouseEvent)
    {
        gen_projectile(e.pos);
    }
}