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

    public async bool update_package (Package package, owned ChangeInformation.ProgressCallback cb, Cancellable cancellable) throws GLib.Error {
        bool binstall = false;

        try{
            binstall = yield client.install2_async(Snapd.InstallFlags.CLASSIC, snap.get_name(), null, null, cb, cancellable);
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

   public async bool install_package (Package package, owned ChangeInformation.ProgressCallback cb, Cancellable cancellable) throws GLib.Error {
      bool binstall = false;

      try{
         binstall = yield client.install2_async(Snapd.InstallFlags.CLASSIC, snap.get_name(), null, null, cb, cancellable);
      } catch (Error e) {
         critical(e.message);
         return(false);
      }

      return(binstall);
   }

    public async Gee.Collection<Package> get_installed_applications (Cancellable? cancellable = null) {
        var installed_apps = new Gee.HashSet<Package> ();
        var snaps = new GLib.GenericArray <weak Snapd.Snap> (); 

        if (client == null) {
            critical ("Couldn't get installed apps due to no snap installation");
            return installed_apps;
        }

        try {
            snaps = client.list_sync(null);
        } catch (Error e) {
            critical ("Unable to get installed snaps: %s", e.message);
            return installed_apps;
        }


        

        return(snaps);
    }

   public async GLib.GenericArray <weak Snapd.Snap> getInstalledPackagesAsync()
   {
      GLib.GenericArray <weak Snapd.Snap> snaps = yield client.list_async(cancellable);

      return(snaps);
   }

   public GLib.GenericArray <weak Snapd.Snap> getPackagesForSection(AppStream.Category section)
   {
      GLib.GenericArray <weak Snapd.Snap> snaps = client.find_section_sync(Snapd.FindFlags.NONE, convertCategoryToSection(section.name), null, null, cancellable);

      return(snaps);
   }

   public GLib.GenericArray <weak Snapd.Snap> getFeaturedSnaps()
   {
      GLib.GenericArray <weak Snapd.Snap> snaps = client.find_section_sync(Snapd.FindFlags.NONE, "featured", null, null, cancellable);

      return(snaps);
   }

   public GLib.GenericArray <weak Snapd.Snap> getRefreshablePackages()
   {
      GLib.GenericArray <weak Snapd.Snap> snaps = client.find_refreshable_sync();

      return(snaps);
   }

   public async GLib.GenericArray <weak Snapd.Snap> getRefreshablePackagesAsync()
   {
      GLib.GenericArray <weak Snapd.Snap> snaps = yield client.find_refreshable_async(cancellable);

      return(snaps);
   }

   public GLib.GenericArray <weak Snapd.Alias> getSnapAlias()
   {
      GLib.GenericArray <weak Snapd.Alias> alias = client.get_aliases_sync(null);

      return(alias);
   }

   public GLib.GenericArray <weak Snapd.Snap> getPackageByName(string searchWord = "")
   {
      try{
         GLib.GenericArray <weak Snapd.Snap> snaps = client.find_sync(Snapd.FindFlags.NONE, searchWord, null, cancellable);
         return(snaps);
      } catch (Snapd.Error e) {
         critical(e.message);
         return(null);
      }

      return(null);
   }

   public GLib.GenericArray <weak Snapd.Snap> getSpecificPackageByName(string searchWord = "")
   {
      try{
         GLib.GenericArray <weak Snapd.Snap> snaps = client.find_sync(Snapd.FindFlags.MATCH_NAME, searchWord, null, cancellable);
         return(snaps);
      } catch (Snapd.Error e) {
         critical("Error on Snap: " + searchWord + " Message: " + e.message);
         return(null);
      }

      return(null);
   }

   private string convertCategoryToSection(string category)
   {
      switch (category)
      {
      case "Audio":
         return("music");

         break;

      case "Development":
         return("developers");

         break;

      case "Accessories":
         return("utilities");

         break;

      case "Office":
         return("finance");

         break;

      case "System":
         return("utilities");

         break;

      case "Internet":
         return("social-networking");

         break;

      case "Science":
         return("poductivity");

         break;

      case "Education":
         return("poductivity");

         break;

      case "Accessibility":
         return("utilities");

         break;

      default:
         return(category);
      }
   }

    private static GLib.Once<SnapBackend> instance;
    public static unowned SnapBackend get_default () {
        return instance.once (() => { return new SnapBackend (); });
    }

}