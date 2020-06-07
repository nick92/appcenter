public class AppCenterCore.AppStar : GLib.Object {
    public string app_name { get; construct; }
    public int64 app_star { get; construct; }
    
    public AppStar (string _name, int64 _star) {
        Object ( 
            app_name: _name, 
            app_star: _star 
        );
    }
}

public class AppCenterCore.StarCache {
    public Gee.ArrayList<AppStar> apps { get; private set; }
    public static StarCache? cache { get; private set; }
    private const int MAX_CACHE_SIZE = 100000000;
    private Soup.Session session;

    public static StarCache? new_cache () {
        var session = new Soup.Session ();
        session.timeout = 5;

        var _cache = new StarCache ();
        _cache.session = session;

        cache = _cache;
        return _cache;
    }

    public void add_apps (Gee.ArrayList<AppStar> _apps) {
        apps = _apps;
    }

    public string get_stars_for_app (string app_name) {
        int64 stars = 0;
        
        foreach (var app in apps) {
            if (app.app_name == app_name){
                stars = app.app_star;
                break;
            }
        }

        return stars.to_string ();
    }

}