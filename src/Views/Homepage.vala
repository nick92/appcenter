// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
* Copyright (c) 2016-2017 elementary LLC. (https://elementary.io)
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
* Authored by: Nathan Dyer <mail@nathandyer.me>
*              Dane Henson <thegreatdane@gmail.com>
*/

using AppCenterCore;

const int NUM_PACKAGES_IN_BANNER = 1;
const int NUM_PACKAGES_IN_CAROUSEL = 10;

namespace AppCenter {
    
    public class Category {
      public string name { get; set; }
      public string icon_name { get; set; }

      public Category (string name, string icon_name) {
        this.name = name;
        this.icon_name = icon_name;
      }
    }

    public class Homepage : View {
        private Gtk.FlowBox category_flow;
        private Gtk.ScrolledWindow category_scrolled;
        private Gtk.Paned paned;
        private string current_category;

        public bool viewing_package { get; private set; default = false; }

        public AppStream.Category currently_viewed_category;
        public MainWindow main_window { get; construct; }
        public Widgets.Banner newest_banner;
        public Gtk.Revealer switcher_revealer;

        private Widgets.UpdatesGrid updates_header;
        private Gtk.Button update_all_button;
        private AppCenterCore.Client client;

        private Gtk.Stack stack_featured;
        private AppCenterCore.Houston houston;

        private Widgets.Carousel useful_carousel;
        private Gtk.Revealer useful_revealer;
        private Gtk.Label useful_carousel_label;

        private Widgets.Carousel featured_carousel;
        private Gtk.Revealer featured_revealer;
        private Gtk.Label featured_carousel_label;

        private Widgets.Carousel office_carousel;
        private Gtk.Revealer office_revealer;
        private Gtk.Label office_carousel_label;

        private Widgets.Carousel development_carousel;
        private Gtk.Revealer development_revealer;
        private Gtk.Label development_carousel_label;

        private Widgets.Carousel multimedia_carousel;
        private Gtk.Revealer multimedia_revealer;
        private Gtk.Label multimedia_carousel_label;

        public Homepage (MainWindow main_window) {
            Object (main_window: main_window);
        }

        construct {
            houston = AppCenterCore.Houston.get_default ();
            /*client = AppCenterCore.Client.get_default ();
            updates_header = new Widgets.UpdatesGrid ();

                client.updates_available.connect (() => {
    				if(client.updates_number != 0U) {
    					warning(client.updates_number.to_string ());
    					updates_header.update (client.updates_number, 0, client.updating_cache);
    					updates_header.show_all ();
    				}
    			});*/

            var switcher = new Widgets.Switcher ();
            switcher.halign = Gtk.Align.CENTER;

            switcher_revealer = new Gtk.Revealer ();
            switcher_revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
            switcher_revealer.set_transition_duration (Widgets.Banner.TRANSITION_DURATION_MILLISECONDS);
            switcher_revealer.add (switcher);

            stack_featured = new Gtk.Stack();
            stack_featured.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;

            newest_banner = new Widgets.Banner (switcher);
            newest_banner.get_style_context ().add_class ("home");
            newest_banner.margin = 12;
            /*newest_banner.clicked.connect (() => {
                var package = newest_banner.get_package ();
                if (package != null) {
                    show_package (package);
                }
            });*/

            useful_carousel_label = new Gtk.Label (_("Useful Apps"));
            useful_carousel_label.get_style_context ().add_class ("h4");
            useful_carousel_label.xalign = 0;
            useful_carousel_label.margin_start = 10;

            useful_carousel = new Widgets.Carousel ();

            var useful_grid = new Gtk.Grid ();
            useful_grid.margin = 2;
            useful_grid.margin_top = 12;
            useful_grid.attach (useful_carousel_label, 0, 0, 1, 1);
            useful_grid.attach (useful_carousel, 0, 1, 1, 1);

            useful_revealer = new Gtk.Revealer ();
            useful_revealer.add (useful_grid);

            var featured_carousel_label = new Gtk.Label (_("Featured Snaps"));
            featured_carousel_label.get_style_context ().add_class ("h4");
            featured_carousel_label.xalign = 0;
            featured_carousel_label.margin_start = 10;

            featured_carousel = new Widgets.Carousel ();

            var featured_grid = new Gtk.Grid ();
            featured_grid.margin = 2;
            featured_grid.margin_top = 12;
            featured_grid.attach (featured_carousel_label, 0, 0, 1, 1);
            featured_grid.attach (featured_carousel, 0, 1, 1, 1);

            featured_revealer = new Gtk.Revealer ();
            featured_revealer.add (featured_grid );

            var office_carousel_label = new Gtk.Label (_("Office"));
            office_carousel_label.get_style_context ().add_class ("h4");
            office_carousel_label.xalign = 0;
            office_carousel_label.margin_start = 10;

            office_carousel = new Widgets.Carousel ();

            var office_grid = new Gtk.Grid ();
            office_grid.margin = 2;
            office_grid.margin_top = 12;
            office_grid.attach (office_carousel_label, 0, 0, 1, 1);
            office_grid.attach (office_carousel, 0, 1, 1, 1);

            office_revealer = new Gtk.Revealer ();
            office_revealer.add (office_grid);

            var development_carousel_label = new Gtk.Label (_("Development"));
            development_carousel_label.get_style_context ().add_class ("h4");
            development_carousel_label.xalign = 0;
            development_carousel_label.margin_start = 10;

            development_carousel = new Widgets.Carousel ();

            var development_grid = new Gtk.Grid ();
            development_grid.margin = 2;
            development_grid.margin_top = 12;
            development_grid.attach (development_carousel_label, 0, 0, 1, 1);
            development_grid.attach (development_carousel, 0, 1, 1, 1);

            development_revealer = new Gtk.Revealer ();
            development_revealer.add (development_grid);

            var multimedia_carousel_label = new Gtk.Label (_("Multimedia"));
            multimedia_carousel_label.get_style_context ().add_class ("h4");
            multimedia_carousel_label.xalign = 0;
            multimedia_carousel_label.margin_start = 10;

            multimedia_carousel = new Widgets.Carousel ();

            var multimedia_grid = new Gtk.Grid ();
            multimedia_grid.margin = 2;
            multimedia_grid.margin_top = 12;
            multimedia_grid.attach (multimedia_carousel_label, 0, 0, 1, 1);
            multimedia_grid.attach (multimedia_carousel, 0, 1, 1, 1);

            multimedia_revealer = new Gtk.Revealer ();
            multimedia_revealer.add (multimedia_grid);

            var grid = new Gtk.Grid ();
            grid.margin = 12;

            var grid_bottom = new Gtk.Grid ();
            grid_bottom.margin = 12;

            stack_featured.add_named (useful_revealer, "Recommended");
            stack_featured.add_named (office_revealer, "Office");
            stack_featured.add_named (development_revealer, "Development");
            stack_featured.add_named (multimedia_revealer, "Multimedia");
            stack_featured.set_visible_child_name ("Recommended");

            //var stack_sidebar = new Gtk.StackSidebar ();
            var stack_sidebar = new CategorySidebar ();

            var category_list = new Gee.LinkedList<Category> ();
            category_list.add (new Category ("Recommended", "applications-accessories"));
            category_list.add (new Category ("Office", "applications-office"));
            category_list.add (new Category ("Development", "applications-development"));
            category_list.add (new Category ("Multimedia", "audio-speakers"));

            category_list.foreach((category) => {
              stack_sidebar.add_section (category.name, category.icon_name);
              return true;
            });

            stack_sidebar.changed.connect((id) => {
              stack_featured.set_visible_child_name (category_list.get(id).name);
            });
            //stack_sidebar.stack = stack_featured;

            //grid_bottom.attach (box_button_view, 0, 1, 1, 1);
            //grid_bottom.attach (stack_featured, 0, 1, 1, 1);

            //grid.attach (updates_header, 0, 0, 1, 1);
            grid.attach (newest_banner, 0, 1, 1, 1);
            grid.attach (stack_featured, 0, 2, 1, 1);
            //grid.attach (switcher_revealer, 0, 1, 1, 1);
            //grid.attach (recently_updated_revealer, 0, 2, 1, 1);

            //grid.attach (categories_label, 0, 4, 1, 1);
            //grid.attach (category_flow, 0, 5, 1, 1);

            category_scrolled = new Gtk.ScrolledWindow (null, null);
            category_scrolled.add (grid);

            paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            paned.wide_handle = true;
            paned.add1 (stack_sidebar);
            paned.add2 (category_scrolled);

            add (paned);

            //show_all();

            /*var local_package = App.local_package;
            if (local_package != null) {
                newest_banner.add_package (local_package);
            }*/

            populate_app_carousels.begin ();
        }

        public async void populate_app_carousels()
        {
          //useful apps
          houston.get_app_ids ("/packages/useful/list", (obj, res) => {
    				var updated_ids = houston.get_app_ids.end (res);
    				//new Thread<void*> ("update-useful-carousel", () => {
              useful_carousel.clear();
              AppCenterCore.Package candidate_package = null;
    					var packages_for_carousel = new Gee.LinkedList<AppCenterCore.Package> ();
    						foreach (var package in updated_ids) {
                  if(package.substring(0,1) == "*"){
                    package = package.substring(1);
                    var snap = AppCenterCore.SnapClient.get_default ().getSpecificPackageByName (package);
                    if(snap != null)
                      candidate_package = AppCenterCore.Client.get_default ().convert_snap_to_component(snap.get(0));
                  }else{
      							var candidate = package + ".desktop";
      							candidate_package = AppCenterCore.Client.get_default ().get_package_for_component_id (candidate);
                  }
    							if (candidate_package != null) {
    								candidate_package.update_state ();
    								if (candidate_package.state == AppCenterCore.Package.State.NOT_INSTALLED) {
                      packages_for_carousel.add (candidate_package);
    								}
    							}
    						}

    						if (!packages_for_carousel.is_empty) {
                  packages_for_carousel.foreach((banner_package) => {
                    useful_carousel.add_package (banner_package);
                    return true;
                  });
                }

                useful_revealer.reveal_child = true;
                useful_carousel.package_activated.connect (show_package);
            });

            houston.get_app_ids ("/packages/office/list", (obj, res) => {
      				var updated_ids = houston.get_app_ids.end (res);
      				//new Thread<void*> ("update-office-carousel", () => {
                office_carousel.clear();
                AppCenterCore.Package candidate_package = null;
      					var packages_for_carousel = new Gee.LinkedList<AppCenterCore.Package> ();
      						foreach (var package in updated_ids) {
                    if(package.substring(0,1) == "*"){
                      package = package.substring(1);
                      var snap = AppCenterCore.SnapClient.get_default ().getSpecificPackageByName (package);
                      //warning(snap.get(0).name);
                      if(snap != null)
                        candidate_package = AppCenterCore.Client.get_default ().convert_snap_to_component(snap.get(0));
                    }else{
        							var candidate = package + ".desktop";
        							candidate_package = AppCenterCore.Client.get_default ().get_package_for_component_id (candidate);
                    }
      							if (candidate_package != null) {
      								candidate_package.update_state ();
      								if (candidate_package.state == AppCenterCore.Package.State.NOT_INSTALLED) {
      									packages_for_carousel.add (candidate_package);
      								}
      							}
      						}

      						if (!packages_for_carousel.is_empty) {
                    //Idle.add (() => {
        							packages_for_carousel.foreach((banner_package) => {
                        office_carousel.add_package (banner_package);
                        return true;
        							});
        							office_revealer.reveal_child = true;
                      //return false;
                    //});
                  }
                  //return null;
                //});
              office_carousel.package_activated.connect (show_package);
            });

            houston.get_app_ids ("/packages/development/list", (obj, res) => {
      				var updated_ids = houston.get_app_ids.end (res);
      				//new Thread<void*> ("update-development-carousel", () => {
                development_carousel.clear();
                AppCenterCore.Package candidate_package = null;
      					var packages_for_carousel = new Gee.LinkedList<AppCenterCore.Package> ();
      						foreach (var package in updated_ids) {
                    if(package.substring(0,1) == "*"){
                      package = package.substring(1);
                      var snap = AppCenterCore.SnapClient.get_default ().getSpecificPackageByName (package);
                      if(snap != null)
                        candidate_package = AppCenterCore.Client.get_default ().convert_snap_to_component(snap.get(0));
                    }else{
        							var candidate = package + ".desktop";
        							candidate_package = AppCenterCore.Client.get_default ().get_package_for_component_id (candidate);
                    }
      							if (candidate_package != null) {
      								//candidate_package.update_state ();
      								if (candidate_package.state == AppCenterCore.Package.State.NOT_INSTALLED) {
      									packages_for_carousel.add (candidate_package);
      								}
      							}
      						}

      						if (!packages_for_carousel.is_empty) {
                    //Idle.add (() => {
        							packages_for_carousel.foreach((banner_package) => {
                        development_carousel.add_package (banner_package);
                        return true;
        							});
        							development_revealer.reveal_child = true;
                      //return false;
                    //});
                  }
                 // return null;
                //});
              development_carousel.package_activated.connect (show_package);
            });

            houston.get_app_ids ("/packages/multimedia/list", (obj, res) => {
      				var updated_ids = houston.get_app_ids.end (res);
      				//new Thread<void*> ("update-multimedia-carousel", () => {
                multimedia_carousel.clear();
                AppCenterCore.Package candidate_package = null;
      					var packages_for_carousel = new Gee.LinkedList<AppCenterCore.Package> ();
      						foreach (var package in updated_ids) {
                    if(package.substring(0,1) == "*"){
                      package = package.substring(1);
                      var snap = AppCenterCore.SnapClient.get_default ().getSpecificPackageByName (package);
                      if(snap != null)
                        candidate_package = AppCenterCore.Client.get_default ().convert_snap_to_component(snap.get(0));
                    }else{
        							var candidate = package + ".desktop";
        							candidate_package = AppCenterCore.Client.get_default ().get_package_for_component_id (candidate);
                    }
      							if (candidate_package != null) {
      								//candidate_package.update_state ();
      								if (candidate_package.state == AppCenterCore.Package.State.NOT_INSTALLED) {
      									packages_for_carousel.add (candidate_package);
      								}
      							}
      						}

      						if (!packages_for_carousel.is_empty) {
                    //Idle.add (() => {
        							packages_for_carousel.foreach((banner_package) => {
                        multimedia_carousel.add_package (banner_package);
                        return true;
        							});
        							multimedia_revealer.reveal_child = true;
                      //return false;
                    //});
                  }
                  //return null;
                //});
              multimedia_carousel.package_activated.connect (show_package);
            });

            /*featured snaps
            new Thread<void*> ("update-featured-carousel", () => {
                var packages_for_carousel = new Gee.LinkedList<AppCenterCore.Package> ();
                //Idle.add (() => {
                var featured_snaps = AppCenterCore.SnapClient.get_default ().getFeaturedSnaps ();

                featured_snaps.foreach ((snap) => {
                    var package = AppCenterCore.Client.get_default ().convert_snap_to_component(snap);
                    if(package != null){
                        if (package.state == AppCenterCore.Package.State.NOT_INSTALLED) {
                            featured_carousel.add_package (package);
                        }
                        featured_revealer.reveal_child = true;
                    }
                });
                featured_carousel.package_activated.connect (show_package);
                return null;
            });*/
        }

        public override void show_package (AppCenterCore.Package package) {
            base.show_package (package);
            viewing_package = true;
            current_category = null;
            currently_viewed_category = null;
            subview_entered (_("Home"), false, "");
        }

        public override void return_clicked () {
            if (previous_package != null) {
                show_package (previous_package);
                if (current_category != null) {
                    subview_entered (current_category, false, "");
                } else {
                    subview_entered (_("Home"), false, "");
                }
            } else if (viewing_package && current_category != null) {
                set_visible_child_name (current_category);
                viewing_package = false;
                subview_entered (_("Home"), true, current_category, _("Search %s").printf (current_category));
            } else {
                set_visible_child (paned);
                viewing_package = false;
                currently_viewed_category = null;
                current_category = null;
                subview_entered (null, true);
            }
        }

        /*private void show_app_list_for_category (AppStream.Category category) {
            subview_entered (_("Home"), true, category.name, _("Search %s").printf (category.name));
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
        }*/
    }
}
