/*-
 * Copyright 2019 elementary, Inc. (https://elementary.io)
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
 * Authored by: David Hewitt <davidmhewitt@gmail.com>
 */

public class AppCenterCore.SnapBackend : Backend, Object {
    // AppStream data has to be 1 hour old before it's refreshed
    public const uint MAX_APPSTREAM_AGE = 3600;

    private AsyncQueue<Job> jobs = new AsyncQueue<Job> ();
    private Thread<bool> worker_thread;

    private Gee.HashMap<string, Package> package_list;
    private AppStream.Pool appstream_pool;
    private Snapd.Client client;
    private GenericArray<Snapd.Snap> installed;


    // This is OK as we're only using a single thread
    // This would have to be done differently if there were multiple workers in the pool
    private bool thread_should_run = true;

    public bool working { public get; protected set; }

    private string local_metadata_path;

    private bool worker_func () {
        while (thread_should_run) {
            var job = jobs.pop ();
            working = true;
            switch (job.operation) {
                case Job.Type.REFRESH_CACHE:
                    refresh_cache_internal (job);
                    break;
                case Job.Type.INSTALL_PACKAGE:
                    install_package_internal (job);
                    break;
                case Job.Type.UPDATE_PACKAGE:
                    update_package_internal (job);
                    break;
                case Job.Type.REMOVE_PACKAGE:
                    remove_package_internal (job);
                    break;
                default:
                    assert_not_reached ();
            }

            working = false;
        }

        return true;
    }

    construct {
        worker_thread  = new Thread<bool> ("snap-worker", worker_func);
        appstream_pool = new AppStream.Pool ();
        package_list   = new Gee.HashMap<string, Package> (null, null);
        client         = new Snapd.Client();
        installed      = client.find_refreshable_sync();

        appstream_pool.set_cache_flags (AppStream.CacheFlags.NONE);

        local_metadata_path = Path.build_filename (
            Environment.get_user_cache_dir (),
            "io.elementary.appcenter",
            "snap-metadata"
        );

        reload_appstream_pool ();
    }

    static construct {
        try {
            //  installation = new Flatpak.Installation.system ();
        } catch (Error e) {
            critical ("Unable to get system default snap installation : %s", e.message);
        }
    }

    ~SnapBackend () {
        thread_should_run = false;
        worker_thread.join ();
    }

    private async Job launch_job (Job.Type type, JobArgs? args = null) {
        var job = new Job (type);
        job.args = args;

        SourceFunc callback = launch_job.callback;
        job.results_ready.connect (() => {
            Idle.add ((owned) callback);
        });

        jobs.push (job);
        yield;
        return job;
    }

    private void reload_appstream_pool () {
      appstream_pool.clear_metadata_locations ();
      appstream_pool.add_metadata_location (local_metadata_path);
      debug ("Loading snap pool");

      try {
          appstream_pool.load ();
      } catch (Error e) {
          warning ("Errors found in snap appdata, some components may be incomplete/missing: %s", e.message);
      } finally {
          var new_package_list = new Gee.HashMap<string, Package> ();
          var comp_validator = ComponentValidator.get_default ();
          appstream_pool.get_components ().foreach ((comp) => {
              if (!comp_validator.validate (comp)) {
                  return;
              }

              var bundle = comp.get_bundle (AppStream.BundleKind.SNAP);
              if (bundle != null) {
                  var key = "%s/%s".printf (comp.get_origin (), bundle.get_id ());
                  var package = package_list[key];
                  if (package != null) {
                      package.replace_component (comp);
                  } else {
                      package = new Package (this, comp);
                  }

                  new_package_list[key] = package;
              }
          });

          package_list = new_package_list;
      }
  }

    public async bool update_package (Package package, owned ChangeInformation.ProgressCallback cb, Cancellable cancellable) throws GLib.Error {
        bool binstall = false;

        try{
            binstall = yield client.install2_async(Snapd.InstallFlags.CLASSIC, package.get_name(), null, null, cb, cancellable);
        } catch (Error e) {
            critical(e.message);
            return(false);
        }

        return(binstall);
    }

   public async bool remove_package (Package package, owned ChangeInformation.ProgressCallback cb, Cancellable cancellable) throws GLib.Error {
      bool binstall = false;

      try{
         binstall = yield client.remove_async(package.get_name(), cb, cancellable);
      } catch (Error e) {
         critical(e.message);
         return(false);
      }

      return(binstall);
   }

   private void update_package_internal (Job job) {
      var args = (UpdatePackageArgs)job.args;
      var package = args.package;
      unowned ChangeInformation.ProgressCallback cb = args.cb;
      var cancellable = args.cancellable;

      job.result = Value (typeof (bool));
      job.result.set_boolean (success);
      job.results_ready ();
  }

   private void install_package_internal (Job job) {
      var args = (InstallPackageArgs)job.args;
      var package = args.package;
      unowned ChangeInformation.ProgressCallback cb = args.cb;
      var cancellable = args.cancellable;

      bool success = false;

      var bundle = package.component.get_bundle (AppStream.BundleKind.FLATPAK);
      if (bundle == null) {
          job.result = Value (typeof (bool));
          job.result.set_boolean (false);
          job.results_ready ();
          return;
      }

      try{
         success = client.install2_sync(Snapd.InstallFlags.CLASSIC, package.get_name (), null, null, cb, cancellable);
      } catch (Error e) {
         critical(e.message);
      }

      job.result = Value (typeof (bool));
      job.result.set_boolean (success);
      job.results_ready ();
  }

   public async bool install_package (Package package, owned ChangeInformation.ProgressCallback cb, Cancellable cancellable) throws GLib.Error {
      var job_args = new InstallPackageArgs ();
      job_args.package = package;
      job_args.cb = (owned)cb;
      job_args.cancellable = cancellable;

      var job = yield launch_job (Job.Type.INSTALL_PACKAGE, job_args);
      if (job.error != null) {
         throw job.error;
      }

      return job.result.get_boolean ();
   }

    public async Gee.Collection<Package> get_installed_applications (Cancellable? cancellable = null) {
        var installed_apps = new Gee.HashSet<Package> ();
        var snaps = new GLib.GenericArray <weak Snapd.Snap> (); 

        if (client == null) {
            critical ("Couldn't get installed apps due to no snap installation");
            return installed_apps;
        }

        try {
            snaps = yield client.list_async(cancellable);
        } catch (Error e) {
            critical ("Unable to get installed snaps: %s", e.message);
            return installed_apps;
        }

        for (int i = 0; i < snaps.length; i++) {
         if (cancellable.is_cancelled ()) {
             break;
         }

         unowned Snapd.Snap snap = snaps[i];

         var bundle_id = "%s/%s".printf (snap.channel, snap.name);
         var package = package_list[bundle_id];
         if (package != null) {
             package.mark_installed ();
             package.update_state ();
             installed_apps.add (package);
         }
     }
        

        return(installed_apps);
    }

   //  public async GLib.GenericArray <weak Snapd.Snap> getInstalledPackagesAsync()
   //  {
   //     GLib.GenericArray <weak Snapd.Snap> snaps = yield client.list_async(cancellable);

   //     return(snaps);
   //  }

   public Gee.Collection<Package> get_applications_for_category (AppStream.Category category) {
      unowned GLib.GenericArray<AppStream.Component> components = category.get_components ();
        if (components.length == 0) {
            var category_array = new GLib.GenericArray<AppStream.Category> ();
            category_array.add (category);
            AppStream.utils_sort_components_into_categories (appstream_pool.get_components (), category_array, true);
            components = category.get_components ();
        }

        var apps = new Gee.TreeSet<AppCenterCore.Package> ();
        components.foreach ((comp) => {
            var package = get_package_for_component_id (comp.get_id ());
            if (package != null) {
                apps.add (package);
            }
        });

        return apps;
      //  GLib.GenericArray <weak Snapd.Snap> snaps = client.find_section_sync(Snapd.FindFlags.NONE, convertCategoryToSection(section.name), null, null, cancellable);

      //  return(snaps);
   }

   public Gee.Collection<Package> search_applications (string query, AppStream.Category? category) {
      var apps = new Gee.TreeSet<AppCenterCore.Package> ();
      GLib.GenericArray<weak AppStream.Component> comps = appstream_pool.search (query);
      if (category == null) {
          comps.foreach ((comp) => {
              var package = get_package_for_component_id (comp.get_id ());
              if (package != null) {
                  apps.add (package);
              }
          });
      } else {
          var cat_packages = get_applications_for_category (category);
          comps.foreach ((comp) => {
              var package = get_package_for_component_id (comp.get_id ());
              if (package != null && package in cat_packages) {
                  apps.add (package);
              }
          });
      }

      return apps;
  }

  public Gee.Collection<Package> search_applications_mime (string query) {
   return new Gee.ArrayList<Package> ();
}

public Package? get_package_for_component_id (string id) {
   foreach (var package in package_list.values) {
       if (package.component.id == id) {
           return package;
       } else if (package.component.id == id + ".desktop") {
           return package;
       }
   }

   return null;
}

public Gee.Collection<Package> get_packages_for_component_id (string id) {
   var packages = new Gee.ArrayList<Package> ();
   foreach (var package in package_list.values) {
       if (package.component.id == id) {
           packages.add (package);
       } else if (package.component.id == id + ".desktop") {
           packages.add (package);
       }
   }

   return packages;
}

public Package? get_package_for_desktop_id (string desktop_id) {
   foreach (var package in package_list.values) {
       if (package.component.id == desktop_id ||
           package.component.id + ".desktop" == desktop_id
       ) {
           return package;
       }
   }

   return null;
}

public async uint64 get_download_size (Package package, Cancellable? cancellable) throws GLib.Error {
   var bundle = package.component.get_bundle (AppStream.BundleKind.FLATPAK);
   if (bundle == null) {
       return 0;
   }

   var id = "%s/%s".printf (package.component.get_origin (), bundle.get_id ());
   return yield get_download_size_by_id (id, cancellable);
}

public async uint64 get_download_size_by_id (string id, Cancellable? cancellable) throws GLib.Error {
   return 0;
}

public async bool is_package_installed (Package package) throws GLib.Error {
   var bundle = package.component.get_bundle (AppStream.BundleKind.SNAP);
   if (bundle == null) {
       return false;
   }

   var key = "%s/%s".printf (package.component.get_origin (), bundle.get_id ());

   for (int j = 0; j < installed.length; j++) {
       unowned Snapd.Snap snap = installed[j];

       var bundle_id = "%s/%s".printf (snap.channel, snap.name);
       if (key == bundle_id) {
           return true;
       }
   }

   return false;
}

public async PackageDetails get_package_details (Package package) throws GLib.Error {
   var details = new PackageDetails ();
   details.name = package.component.get_name ();
   details.description = package.component.get_description ();
   details.summary = package.component.get_summary ();

   var newest_version = package.get_newest_release ();
   if (newest_version != null) {
       details.version = newest_version.get_version ();
   }

   return details;
}

public async bool refresh_cache (Cancellable? cancellable) throws GLib.Error {
   var job_args = new RefreshCacheArgs ();
   job_args.cancellable = cancellable;

   var job = yield launch_job (Job.Type.REFRESH_CACHE, job_args);
   if (job.error != null) {
       throw job.error;
   }

   return job.result.get_boolean ();
}

public Gee.Collection<Package> get_packages_by_author (string author, int max) {
   return new Gee.ArrayList<Package> ();
}

private void refresh_cache_internal (Job job) {
   var args = (RefreshCacheArgs)job.args;
   var cancellable = args.cancellable;

   reload_appstream_pool ();

   job.result = Value (typeof (bool));
   job.result.set_boolean (true);
   job.results_ready ();
}

   //  public GLib.GenericArray <weak Snapd.Snap> getFeaturedSnaps()
   //  {
   //     GLib.GenericArray <weak Snapd.Snap> snaps = client.find_section_sync(Snapd.FindFlags.NONE, "featured", null, null, cancellable);

   //     return(snaps);
   //  }

   //  public GLib.GenericArray <weak Snapd.Snap> getRefreshablePackages()
   //  {
   //     GLib.GenericArray <weak Snapd.Snap> snaps = client.find_refreshable_sync();

   //     return(snaps);
   //  }

   //  public async GLib.GenericArray <weak Snapd.Snap> getRefreshablePackagesAsync()
   //  {
   //     GLib.GenericArray <weak Snapd.Snap> snaps = yield client.find_refreshable_async(cancellable);

   //     return(snaps);
   //  }

   //  public GLib.GenericArray <weak Snapd.Alias> getSnapAlias()
   //  {
   //     GLib.GenericArray <weak Snapd.Alias> alias = client.get_aliases_sync(null);

   //     return(alias);
   //  }

   //  public GLib.GenericArray <weak Snapd.Snap> getPackageByName(string searchWord = "")
   //  {
   //     try{
   //        GLib.GenericArray <weak Snapd.Snap> snaps = client.find_sync(Snapd.FindFlags.NONE, searchWord, null, cancellable);
   //        return(snaps);
   //     } catch (Snapd.Error e) {
   //        critical(e.message);
   //        return(null);
   //     }

   //     return(null);
   //  }

   //  public GLib.GenericArray <weak Snapd.Snap> getSpecificPackageByName(string searchWord = "")
   //  {
   //     try{
   //        GLib.GenericArray <weak Snapd.Snap> snaps = client.find_sync(Snapd.FindFlags.MATCH_NAME, searchWord, null, cancellable);
   //        return(snaps);
   //     } catch (Snapd.Error e) {
   //        critical("Error on Snap: " + searchWord + " Message: " + e.message);
   //        return(null);
   //     }

   //     return(null);
   //  }

   //  private string convertCategoryToSection(string category)
   //  {
   //     switch (category)
   //     {
   //     case "Audio":
   //        return("music");

   //        break;

   //     case "Development":
   //        return("developers");

   //        break;

   //     case "Accessories":
   //        return("utilities");

   //        break;

   //     case "Office":
   //        return("finance");

   //        break;

   //     case "System":
   //        return("utilities");

   //        break;

   //     case "Internet":
   //        return("social-networking");

   //        break;

   //     case "Science":
   //        return("poductivity");

   //        break;

   //     case "Education":
   //        return("poductivity");

   //        break;

   //     case "Accessibility":
   //        return("utilities");

   //        break;

   //     default:
   //        return(category);
   //     }
   //  }

    private static GLib.Once<SnapBackend> instance;
    public static unowned SnapBackend get_default () {
        return instance.once (() => { return new SnapBackend (); });
    }

}