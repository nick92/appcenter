/*
* Copyright (c) 2020 Nick Wilkins (https://enso-os.site)
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
*/

public class AppCenter.Widgets.StarButton : Gtk.Grid {
    public uint64 count { get; construct; }
    public bool enabled { get; set; }
    public AppCenterCore.Package package { get; construct; }

    private Gtk.Label star_count_label;
    private Gtk.Revealer icon_revealer;
    protected Gtk.Button star_button;
    protected AppCenterCore.Houston houston;
    private Settings settings;
    private AppCenterCore.StarCache star_cache;
    private string package_id;

    public StarButton (AppCenterCore.Package _package) {
        Object (
            package: _package
        );
    }

    construct {
        this.hexpand = true;
        houston = AppCenterCore.Houston.get_default ();
        settings = Settings.get_default ();
        star_cache = AppCenterCore.StarCache.cache;
        star_button = new Gtk.Button ();
        
        if(package.is_snap){
            package_id = package.get_name ().replace(".snap", "");
        }
        else {
            package_id = package.component.get_id ().replace(".desktop","");
        }

        star_button.label = _(star_cache.get_stars_for_app(package_id));
        star_button.image_position = Gtk.PositionType.RIGHT;
        star_button.always_show_image = true;
        star_button.image = new Gtk.Image.from_icon_name ("user-bookmarks-symbolic", Gtk.IconSize.MENU);
        star_button.set_tooltip_text (_("Star this app ..."));
        star_button.clicked.connect (star_package_app);
        star_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        if (package_id in settings.stared_apps) {
            set_disabled ();
        }

        add (star_button);
        show_all ();
    }

    public void set_disabled () {
        this.star_button.sensitive = false;
        this.star_button.set_tooltip_text (_("Already Stared"));
    }

    private async void star_package_app () {
        try {
            if(this.star_button.sensitive){
                settings.add_stared_app (package_id);
                this.star_button.set_label((star_button.label.to_int() + 1).to_string());
                set_disabled ();
                yield houston.star_app_by_name ("/packages/appstar", package_id);
            }
        } catch (Error e) {
            warning(e.message);
        }
    }
}
