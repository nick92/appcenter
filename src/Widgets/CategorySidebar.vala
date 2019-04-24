/*
* Copyright (c) 2017 elementary LLC. (https://elementary.io)
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Lesser General Public License as published by
* the Free Software Foundation, either version 2.1 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Library General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

public class AppCenter.CategorySidebar : Gtk.ScrolledWindow {
    public signal bool changed (int i);

    private Gtk.ListBox listbox;
    static Gtk.CssProvider? previous_css_provider = null;

    construct {
        get_style_context ().add_class("sidebar");
        listbox = new Gtk.ListBox ();

        var frame = new Gtk.Frame (null);
        //frame.get_style_context ().add_class("sidebar_row");
        frame.add (listbox);

        add (frame);
        this.min_content_width = 250;
        vexpand = true;
        hexpand = true;

        reload_css ();

        listbox.row_selected.connect ((row) => {
            changed (row.get_index ());
        });
    }

    public void add_section (string name, string icon_name) {
        var icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DND);

        var label = new Gtk.Label (name);
        //label.get_style_context ().add_class ("h4");
        label.xalign = 0;

        var grid = new Gtk.Grid ();
        grid.margin = 10;
        grid.column_spacing = 10;
        grid.add (icon);
        grid.add (label);

        listbox.add (grid);
    }

    public void reload_css () {
        var provider = new Gtk.CssProvider ();
        try {
            string color_primary = DEFAULT_BANNER_COLOR_PRIMARY;
            string color_primary_text = DEFAULT_BANNER_COLOR_PRIMARY_TEXT;
            
            var colored_css = SIDEBAR_STYLE_CSS.printf (color_primary, color_primary_text);
            provider.load_from_data (colored_css, colored_css.length);

            if (previous_css_provider != null) {
                Gtk.StyleContext.remove_provider_for_screen (Gdk.Screen.get_default (), previous_css_provider);
            }

            previous_css_provider = provider;
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            critical (e.message);
        }
    }
}
