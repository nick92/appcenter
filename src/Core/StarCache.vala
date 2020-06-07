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
    public StarCache? cache { get; }
    private const int MAX_CACHE_SIZE = 100000000;
    private Soup.Session session;

    public static StarCache? new_cache () {
        var session = new Soup.Session ();
        session.timeout = 5;

        var cache = new StarCache ();
        cache.session = session;
        return cache;
    }

    public void add_apps (Gee.ArrayList<AppStar> _apps) {
        apps = _apps;
    }

    //  public static StarCache? get_cache () {
    //      return cache;
    //  }

}