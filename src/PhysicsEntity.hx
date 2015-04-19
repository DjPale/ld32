import luxe.Component;
import luxe.Vector;
import nape.phys.Body;

class PhysicsEntity extends Component
{
	public var body : Body;

	public function new(_body:Body)
	{
		super({name: 'PhysicsEntity'});

		body = _body;
	}

	override function update(dt:Float)
	{
		if (entity != null && body != null && !body.isSleeping)
		{
			if (body.allowMovement)	entity.pos.set_xy(body.position.x, body.position.y);
			if (body.allowRotation) entity.rotation.setFromEuler(new Vector(0, 0, body.rotation));

			if (!luxe.utils.Maths.within_range(entity.pos.x, 0, Luxe.screen.w) || 
				(entity.pos.y > Luxe.screen.h))
			{
				Luxe.events.fire('PhysicsEntity.OOB', this);
			}
		}
	}

}