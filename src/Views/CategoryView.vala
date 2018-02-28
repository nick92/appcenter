// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014-2016 elementary LLC. (https://elementary.io)
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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

using AppCenterCore;

public class AppCenter.Views.CategoryView : View {
    //AppListUpdateView app_list_view;
    Widgets.CategoryFlowBox category_flow;
    private string current_category;
    public AppStream.Category currently_viewed_category;
    public bool viewing_package { get; private set; default = false; }

    construct {
        /*var categories_label = new Gtk.Label (_("Categories"));
        categories_label.get_style_context ().add_class ("h4");
        categories_label.xalign = 0;
        categories_label.margin_start = 12;
        categories_label.margin_top = 24;*/

        category_flow = new Widgets.CategoryFlowBox ();
        //category_flow.valign = Gtk.Align.CENTER;

        add (category_flow);

        category_flow.child_activated.connect ((child) => {
            var item = child as Widgets.CategoryItem;
            if (item != null) {
                currently_viewed_category = item.app_category;
                show_app_list_for_category (item.app_category);
            }
        });

        category_flow.set_sort_func ((child1, child2) => {
            var item1 = child1 as Widgets.CategoryItem;
            var item2 = child2 as Widgets.CategoryItem;
            if (item1 != null && item2 != null) {
                return item1.app_category.name.collate (item2.app_category.name);
            }

            return 0;
        });
    }

    private void show_app_list_for_category (AppStream.Category category) {
        subview_entered (_("Categories"), true, category.name, _("Search %s").printf (category.name));
        current_category = category.name;
        var child = get_child_by_name (category.name);
        if (child != null) {
            set_visible_child (child);
            return;
        }

        var app_list_view = new Views.AppListView ();
        app_list_view.show_all ();
        add_named (app_list_view, category.name);
        set_visible_child (app_list_view);

        app_list_view.show_app.connect ((package) => {
            viewing_package = true;
            base.show_package (package);
            subview_entered (category.name, false, "");
        });

        unowned Client client = Client.get_default ();
        var apps = client.get_applications_for_category (category);
        app_list_view.add_packages (apps);
    }

    public override void return_clicked () {
        if (previous_package != null) {
            //show_package (previous_package);
            subview_entered (C_("view", "Category"), false, null);
        } else {
            set_visible_child (category_flow);
            subview_entered (null, false);
        }
    }
}
