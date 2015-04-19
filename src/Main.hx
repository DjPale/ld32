import luxe.Input;
import luxe.States;

typedef GlobalData = {
    views: States
}

class Main extends luxe.Game 
{
    var global : GlobalData = { views: null };

    public static var GameViewState = 'GameView';

    override function config(config:luxe.AppConfig) : luxe.AppConfig
    {
        config.window.title = 'LD32';

        return config;
    }

    function setup()
    {
        // Set up batchers, states etc.
        global.views = new States({ name: 'views' });

        global.views.add(new GameView(GameViewState, global, Luxe.renderer.batcher));

        global.views.set(GameViewState);
    }

    function load_complete(_)
    {
        setup();
    }

    override function ready()
    {
        Luxe.loadJSON('assets/parcel.json', function(json_asset) 
            {
                var preload = new luxe.Parcel();
                preload.from_json(json_asset.json);

                new luxe.ParcelProgress({
                    parcel: preload,
                    background: new luxe.Color(0, 0, 0, 1),
                    bar: new luxe.Color(1, 1, 1, 1),
                    oncomplete: load_complete
                    });

                preload.load();
            }
        );

        // load_complete(null);
    } //ready

    override function onkeyup( e:KeyEvent ) 
    {
        if (e.keycode == Key.escape) 
        {
            Luxe.shutdown();
        }

    } //onkeyup

    override function update(dt:Float) 
    {
    } //update
    
} //Main
