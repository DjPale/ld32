import luxe.States;
import luxe.Input;
import luxe.Vector;
import luxe.Text;
import luxe.Sprite;
import luxe.importers.tiled.TiledMap;

import phoenix.geometry.LineGeometry;

import nape.geom.Vec2;
import nape.space.Space;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.callbacks.CbType;
import nape.callbacks.CbEvent;
import nape.callbacks.InteractionType;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionCallback;
import nape.dynamics.InteractionFilter;

import luxe.physics.nape.DebugDraw;

import Main;

typedef GunPoint = {
    pos: Vector,
    str: Vector
}

typedef EntityUserData = {
    pe: PhysicsEntity
}

typedef WeaponData = {
    name: String,
    radius: Float,
    strength: Float,
    idx: Int
}

class GameView extends State
{
	var batcher : phoenix.Batcher;
	var global : GlobalData;

    var drawer : DebugDraw;
    var space : Space;

    var p_body : Body;
    var aimline : LineGeometry;

    var p_gunpoint : GunPoint = { pos: new Vector(), str: new Vector() };

    var txt_debug : Text;
    var txt_info : Text;

    var weapons : Array<WeaponData>;

    var PROJECTILE : CbType;
    var GROUND : CbType;
    var PLAYER : CbType;

    static var MAX_FORCE = 250.0;
    static var FORCE_MULT = 1.0;

	public function new(name:String, _global:GlobalData, _batcher:phoenix.Batcher)
	{
		super({ name: name });

		batcher = _batcher;
		global = _global;

        GROUND = new CbType();
        PROJECTILE = new CbType();
        PLAYER = new CbType();

        weapons = [
            { name:'Explosive Cod (Sprængt Torsk)', radius: 50, strength: 5, idx: 0 },
            { name:'Flower Pot', radius: 70, strength: 3, idx: 1 }            
        ];
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
        txt_debug = new Text({
            name: 'txt_debug',
            point_size: 16,
            pos: new Vector(50, 20),
            });

        txt_info = new Text({
            name: 'txt_info',
            pos: new Vector(50, 40),
            text: 'Weapon: Exploding Cod (Sprængt Torsk)'
            });

        drawer = new DebugDraw();
        Luxe.physics.nape.debugdraw = drawer;

        space = Luxe.physics.nape.space;

        space.listeners.add(new InteractionListener(
            CbEvent.BEGIN,
            InteractionType.COLLISION,
            PROJECTILE,
            CbType.ANY_SHAPE,
            projectile_collision
            ));

        gen_terrain();

        p_body = new Body(BodyType.DYNAMIC);
        p_body.shapes.add(new Polygon(Polygon.box(64, 32)));
        p_body.position.setxy(150, Luxe.screen.mid.y);
        p_body.space = space;
        p_body.allowRotation = false;
        p_body.cbTypes.add(PLAYER);

        p_gunpoint.pos.set_xy(p_body.position.x, p_body.position.y - 32);

        drawer.add(p_body);

        aimline = Luxe.draw.line({
            p0: p_gunpoint.pos,
            p1: p_gunpoint.pos.clone().add_xyz(32, -32)
            });


        Luxe.events.listen('PhysicsEntity.OOB', entity_oob);
    }

    function entity_oob(e:PhysicsEntity)
    {
        destroy_body(e.body);
    }

    function projectile_collision(cb:InteractionCallback)
    {      
        var bullet = cb.int1;
        var target = cb.int2;

        if (cb.int2.cbTypes.has(PROJECTILE))
        {
            bullet = cb.int2;
            target = cb.int1;
        }

        trace('collision');

        var v = bullet.castBody.position.copy();

        destroy_body(bullet.castBody);
        hit_ground(new Vector(v.x, v.y));
    }


    function gen_terrain(tilesize:Float = 32)
    {
        var tiled = new TiledMap({
            tiled_file_data: Luxe.resources.find_text('assets/map1.tmx').text,
            asset_path: 'assets/'
            });


        var layer = tiled.layer('Ground');
        var tileset = tiled.tileset('tiles');

        for (tile_row in layer.tiles)
        {
            for (tile in tile_row)
            {
                if (tile.id != 0)
                {
                    var b = new Body(BodyType.DYNAMIC);
                    b.shapes.add(new Polygon(Polygon.box(tilesize, tilesize)));

                    var px = tile.pos.x;
                    var py = tile.pos.y;

                    b.allowMovement = false;
                    b.allowRotation = false;
                    b.position.setxy(px, py);
                    b.space = space;
                    b.cbTypes.add(GROUND);

                    //drawer.add(b);

                    var uv = tileset.pos_in_texture(tile.id);
                    trace('uv=$uv');

                    var spr = new Sprite({
                        name_unique: true,
                        texture: tileset.texture,
                        uv: new luxe.Rectangle(uv.x * tilesize, uv.y * tilesize, tilesize, tilesize),
                        pos: tile.pos,
                        size: new Vector(tilesize, tilesize),
                        depth: -1
                        });

                    var pe = spr.add(new PhysicsEntity(b));

                    b.userData.pe = pe;
                }
            }
        }
    }

    function get_random_weapon() : WeaponData
    {
        var r = Luxe.utils.random.int(0, weapons.length);
        var w = weapons[r];

        txt_info.text = 'Weapon: ' + w.name;

        return w;
    }

    function gen_projectile(pos:Vector)
    {
        var bullet_body = new Body(BodyType.DYNAMIC);
        bullet_body.shapes.add(new Polygon(Polygon.box(16, 16)));
        bullet_body.position.setxy(pos.x, pos.y);
        bullet_body.space = space;
        bullet_body.cbTypes.add(PROJECTILE);

        // drawer.add(bullet_body);

        var w = get_random_weapon();

        var spr = new Sprite({
            name_unique: true,
            pos: new Vector(pos.x, pos.y),
            texture: Luxe.resources.find_texture('assets/tiles.png'),
            uv: new luxe.Rectangle(w.idx * 64, 64, 64, 64),
            size: new Vector(64, 64)
            });

        var pe = spr.add(new PhysicsEntity(bullet_body));

        bullet_body.userData.pe = pe;

        bullet_body.applyImpulse(Vec2.weak(p_gunpoint.str.x * FORCE_MULT, p_gunpoint.str.y * FORCE_MULT));
        bullet_body.applyAngularImpulse(90);
    }

    function hit_ground(pos:Vector)
    {
        var list = space.bodiesInCircle(Vec2.weak(pos.x,pos.y), 75);

        trace('hit = ' + list.length);

        // if (list.length > 0)
        // {
        //     Luxe.camera.shake(10);
        // }

        while (list.length > 0)
        {
            var b = list.pop();

            // player
            if (b == p_body || !b.cbTypes.has(GROUND)) continue;

            if (Math.random() >= 0.75)
            {
                destroy_body(b);
            }
            else
            {
                if (b.userData.pe != null)
                {
                    b.userData.pe.shiftTexture();
                }
                awake_body(b);
                explosion(b);
            }
        }

        // list.foreach(destroy_body);
    }

    inline function explosion(b:Body, ?strength:Float = 6.0)
    {
        b.applyImpulse(Vec2.weak(Luxe.utils.random.float(-100 * strength, 100 * strength), Luxe.utils.random.float(-100 * strength / 2, -100 * strength)));
        b.applyAngularImpulse(Luxe.utils.random.float(strength * 10, strength / 2 * 100));
    }

    inline function awake_body(b:Body)
    {
        b.allowRotation = true;
        b.allowMovement = true;
    }

    inline function destroy_body(b:Body)
    {
        if (b.userData.pe != null)
        {
            b.userData.pe.entity.destroy();
        }

        drawer.remove(b);
        space.bodies.remove(b);
        b.space = null;
        b = null;
    }

    function update_aim()
    {
        var delta = Luxe.screen.cursor.pos.clone().subtract(p_gunpoint.pos);
        var v = delta.clone();
        v.normalize();
        v.multiplyScalar(Math.min(delta.length, MAX_FORCE));

        // txt_debug.text = 'd=$delta v=$v';      

        p_gunpoint.str = v;

        aimline.set_p0(p_gunpoint.pos);
        aimline.set_p1(p_gunpoint.str.clone().add(p_gunpoint.pos));
    }

    override function onmousemove(e:MouseEvent)
    {
        // update_aim(e.pos);
    }

    override function onmouseup(e:MouseEvent)
    {
        if (e.button == MouseButton.left)
        {
            gen_projectile(p_gunpoint.pos);
        }
        else if (e.button == MouseButton.right)
        {
            hit_ground(e.pos);
        }
    }

    override function update(dt:Float)
    {
        p_gunpoint.pos.set_xy(p_body.position.x, p_body.position.y - 32);
        update_aim();
    }
}