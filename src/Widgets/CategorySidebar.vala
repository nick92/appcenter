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
    private Gtk.Label updates_badge;
    private Gtk.Label installed_label;
    private Gtk.Image installed_icon;

    construct {
        min_content_width = 250;
        vexpand = true;
        hexpand = true;
        
        listbox = new Gtk.ListBox ();
        var frame = new Gtk.Frame (null);
        frame.add (listbox);

        add (frame);

        listbox.row_selected.connect ((row) => {
            changed (row.get_index ());
        });
    }

    public void add_section (string name, string icon_name) {
        var icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.MENU);

        var label = new Gtk.Label (name);
        label.get_style_context ().add_class ("h4");
        label.xalign = 0;

        var grid = new Gtk.Grid ();
        grid.margin = 10;
        grid.column_spacing = 20;
        grid.row_spacing = 10;
        grid.add (icon);

        if(name == "Installed"){
            updates_badge = new Gtk.Label ("!");
            updates_badge.halign = Gtk.Align.END;
            updates_badge.valign = Gtk.Align.START;
            updates_badge.get_style_context ().add_class ("badge");
            set_widget_visibility (updates_badge, false);
            installed_label = label;
            installed_icon = icon;
            grid.add (installed_label);
            grid.add (updates_badge);
        }
        else {
            grid.add (label);
        }

        listbox.add (grid);
        listbox.select_row(listbox.get_row_at_index(0));
    }

    public void show_update_badge (uint updates_number) {
        if (updates_number == 0U) {
            set_widget_visibility (updates_badge, false);
        } else {
            updates_badge.label = updates_number.to_string ();
            set_widget_visibility (updates_badge, true);
            installed_label.set_text(_("Updates"));
            installed_icon.set_from_icon_name("software-update-available-symbolic", Gtk.IconSize.MENU);
        }
    }
}
