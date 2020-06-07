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

    public StarButton (AppCenterCore.Package _package) {
        Object (
            package: _package
        );
    }

    construct {
        this.column_spacing = 15;
        houston = AppCenterCore.Houston.get_default ();
        settings = Settings.get_default ();

        star_button = new Gtk.ToggleButton ();
        star_button.label = _("10");
        star_button.image_position = Gtk.PositionType.RIGHT;
        star_button.always_show_image = true;
        star_button.image = new Gtk.Image.from_icon_name ("user-bookmarks-symbolic", Gtk.IconSize.MENU);
        star_button.set_tooltip_text (_("Star this app ..."));
        star_button.clicked.connect (star_package_app);

        if (package.component.get_id () in settings.stared_apps) {
            star_button.sensitive = false;
            star_button.set_tooltip_text (_("Already Stared"));
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
            if(package.is_snap){
                var id = package.get_name ().replace(".snap", "");
                yield houston.star_app_by_name ("/packages/appstar", id);
                settings.add_stared_app (id);
            }
            else {
                var id = package.component.get_id ().replace(".desktop","");
                yield houston.star_app_by_name ("/packages/appstar", id);
                settings.add_stared_app (id);
            }

            star_button.sensitive = false;
        } catch (Error e) {
            warning(e.message);
        }
    }
}
