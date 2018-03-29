// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014-2017 elementary LLC. (https://elementary.io)
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
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class AppCenter.Widgets.CategoryFlowBox : Gtk.FlowBox {
    public CategoryFlowBox () {
        Object (activate_on_single_click: true,
                homogeneous: true,
                margin_start: 12,
                margin_top: 24,
                margin_end: 34,
                margin_bottom: 34,
                min_children_per_line: 2);
    }

    construct {
        add (get_category (_("Audio"), "audio-speakers", {"Audio"}, "audio"));
        add (get_category (_("Development"), "applications-development", {"IDE", "Development"}, "development"));
        add (get_category (_("Accessories"), "applications-accessories", {"Utility"}, "accessories"));
        add (get_category (_("Office"), "applications-office", {"Office"}, "office"));
        add (get_category (_("System Tools"), "applications-system", {"System"}, "system"));
        add (get_category (_("Video"), "applications-multimedia", {"Video"}, "video"));
        add (get_category (_("Graphics"), "applications-graphics", {"Graphics"}, "graphics"));
        add (get_category (_("Games"), "applications-games", {"Game"}, "games"));
        add (get_category (_("Education"), "accessories-ebook-reader", {"Education"}, "education"));
        add (get_category (_("Internet"), "applications-internet", {"Network"}, "internet"));
        add (get_category (_("Science"), "applications-science", {"Science"}, "science"));
        add (get_category (_("Universal Access"), "accessibility", {"Accessibility"}, "accessibility"));

        /*add (get_category (_("Sound"), "", {"Audio"}, "audio"));
        add (get_category (_("Development"), "", {"IDE", "Development"}, "development"));
        add (get_category (_("Accessories"), "", {"Utility"}, "accessories"));
        add (get_category (_("Office"), "", {"Office"}, "office"));
        add (get_category (_("System Tools"), "", {"System"}, "system"));
        add (get_category (_("Video"), "", {"Video"}, "video"));
        add (get_category (_("Graphics"), "", {"Graphics"}, "graphics"));
        add (get_category (_("Games"), "", {"Game"}, "games"));
        add (get_category (_("Education"), "", {"Education"}, "education"));
        add (get_category (_("Internet"), "", {"Network"}, "internet"));
        add (get_category (_("Science"), "", {"Science"}, "science"));
        add (get_category (_("Universal Access"), "", {"Accessibility"}, "accessibility"));*/
    }

    private Widgets.CategoryItem get_category (string name, string icon, string[] groups, string style) {
        var category = new AppStream.Category ();
        category.set_name (name);
        category.set_icon (icon);

        foreach (var group in groups) {
            category.add_desktop_group (group);
        }

        var item = new Widgets.CategoryItem (category);
        item.add_category_class (style);

        return item;
    }
}
