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

    private const string SNAP_PACKAGE_ID = "%s;%s;amd64;installed:bionic-main";

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
        worker_thread   = new Thread<bool> ("snap-worker", worker_func);
        appstream_pool  = new AppStream.Pool ();
        package_list    = new Gee.HashMap<string, Package> (null, null);
        client          = new Snapd.Client();
        installed       = new GenericArray<Snapd.Snap> ();

        appstream_pool.set_cache_flags (AppStream.CacheFlags.NONE);

        local_metadata_path = Path.build_filename (
            Environment.get_user_cache_dir (),
            "io.elementary.appcenter",
            "snap-metadata"
        );

        reload_appstream_pool ();
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
          client.find_refreshable_sync ();
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
                  warning (key);
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
        var job_args = new UpdatePackageArgs ();
        job_args.package = package;
        job_args.cb = (owned)cb;
        job_args.cancellable = cancellable;

        var job = yield launch_job (Job.Type.UPDATE_PACKAGE, job_args);
        if (job.error != null) {
            throw job.error;
        }

        return job.result.get_boolean ();

        //  try{
        //      binstall = yield client.install2_async(Snapd.InstallFlags.CLASSIC, package.get_name(), null, null, cb, cancellable);
        //  } catch (Error e) {
        //      critical(e.message);
        //      return(false);
        //  }

        //  return(binstall);
    }

    private void remove_package_internal (Job job) {
        var args = (RemovePackageArgs)job.args;
        var package = args.package;
        unowned ChangeInformation.ProgressCallback cb = args.cb;
        var cancellable = args.cancellable;

        bool success = false;

        try{
            success = client.remove_sync(package.component.get_name (), 
            ((client, change, v) => {
                switch (change.status) {
                    case "Doing":
                    case "Do":
                        double progress_done = 0;
                        double progress_total = 0;
                        double progress = 0;
        
                        change.get_tasks().foreach ((task) => {
                                progress_done += task.get_progress_done ();
                                progress_total += task.get_progress_total ();
                        });
                        
                        progress = (progress_done / progress_total);
                        cb (true, _("Uninstalling"), progress, ChangeInformation.Status.RUNNING);
                    break;
                    case "Abort":
                        cb (false, _("Cancelling"), 1.0f, ChangeInformation.Status.CANCELLED);
                    break;
                    case "Done":
                        success = true;
                    break;
                    case "Error":
                        cb (false, _("Cancelling"), 1.0f, ChangeInformation.Status.CANCELLED);
                    break;
                }
            }), cancellable);

        } catch (Error e) {
            critical(e.message);
            job.result = Value (typeof (bool));
            job.result.set_boolean (false);
            job.results_ready ();
            return;
        }

        job.result = Value (typeof (bool));
        job.result.set_boolean (success);
        job.results_ready ();
    }

    public async bool remove_package (Package package, owned ChangeInformation.ProgressCallback cb, Cancellable cancellable) throws GLib.Error {
        var job_args = new RemovePackageArgs ();
        job_args.package = package;
        job_args.cb = (owned)cb;
        job_args.cancellable = cancellable;

        var job = yield launch_job (Job.Type.REMOVE_PACKAGE, job_args);
        if (job.error != null) {
            throw job.error;
        }

        return job.result.get_boolean ();  
    }

    private void update_package_internal (Job job) {
        var args = (UpdatePackageArgs)job.args;
        var package = args.package;
        unowned ChangeInformation.ProgressCallback cb = args.cb;
        var cancellable = args.cancellable;
        bool success = false;

        try{
            success = client.install2_sync(Snapd.InstallFlags.CLASSIC, package.get_name(), null, null, 
            ((client, change, v) => {
                switch (change.status) {
                    case "Doing":
                    case "Do":
                        double progress_done = 0;
                        double progress_total = 0;
                        double progress = 0;
        
                        change.get_tasks().foreach ((task) => {
                                progress_done += task.get_progress_done ();
                                progress_total += task.get_progress_total ();
                        });
                        
                        progress = (progress_done / progress_total);
                        cb (true, _("Updating"), progress, ChangeInformation.Status.RUNNING);
                    break;
                    case "Abort":
                        cb (false, _("Cancelling"), 1.0f, ChangeInformation.Status.CANCELLED);
                    break;
                    case "Done":
                        success = true;
                    break;
                    case "Error":
                        cb (false, _("Cancelling"), 1.0f, ChangeInformation.Status.CANCELLED);
                    break;
                }
            }), cancellable);
         } catch (Error e) {
            critical(e.message);
            job.result = Value (typeof (bool));
            job.result.set_boolean (false);
            job.results_ready ();
         }

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

        try{
            success = client.install2_sync(Snapd.InstallFlags.CLASSIC, package.component.get_name (), null, null, 
                ((client, change, v) => {
                    switch (change.status) {
                        case "Doing":
                        case "Do":
                            double progress_done = 0;
                            double progress_total = 0;
                            double progress = 0;
            
                            change.get_tasks().foreach ((task) => {
                                    progress_done += task.get_progress_done ();
                                    progress_total += task.get_progress_total ();
                            });
                            
                            progress = (progress_done / progress_total);
                            cb (true, _("Installing"), progress, ChangeInformation.Status.RUNNING);
                        break;
                        case "Abort":
                            cb (false, _("Cancelling"), 1.0f, ChangeInformation.Status.CANCELLED);
                        break;
                        case "Done":
                            success = true;
                        break;
                        case "Error":
                            cb (false, _("Cancelling"), 1.0f, ChangeInformation.Status.CANCELLED);
                        break;
                    }
                })
            , cancellable);
        } catch (Error e) {
            critical(e.message);
            job.result = Value (typeof (bool));
            job.result.set_boolean (false);
            job.results_ready ();
            return;
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
            snaps = client.list_sync(cancellable);
        } catch (Error e) {
            critical ("Unable to get installed snaps: %s", e.message);
            return installed_apps;
        }

        for (int i = 0; i < snaps.length; i++) {
            if (cancellable.is_cancelled ()) {
                break;
            }

            unowned Snapd.Snap snap = snaps[i];
            var package = convert_snap_to_component (snap);
            if (package != null) {
                package.mark_installed ();
                package.update_state ();
                installed_apps.add (package);
                installed.add(snap);
            }
        }
        
        return(installed_apps);
    }

    public Snapd.Snap get_specific_package_by_name (string searchWord = "")
    {
        GLib.GenericArray <weak Snapd.Snap> snaps = null;

        try{
            snaps = client.find_sync(Snapd.FindFlags.MATCH_NAME, searchWord, null, null);
        } catch (Snapd.Error e) {
            critical("Error on Snap: " + searchWord + " Message: " + e.message);
            return(null);
        }

        if(snaps == null)
            return null;

        return(snaps.get(0));
    }

    public Gee.Collection<Package> get_applications_for_category (AppStream.Category category) {
        var apps = new Gee.TreeSet<AppCenterCore.Package> ();
        var section = convertCategoryToSection(category.get_name());
        GLib.GenericArray <weak Snapd.Snap> snaps = client.find_section_sync(Snapd.FindFlags.NONE, section, "", null, null);

        if(snaps.length == 0)
            return null;

        snaps.foreach ((snap) => {
            var package = convert_snap_to_component (snap);
            apps.add (package);
        });

        return apps;
    }

    public Gee.Collection<Package> search_applications (string query, AppStream.Category? category) {
        var apps = new Gee.TreeSet<AppCenterCore.Package> ();
        GLib.GenericArray <weak Snapd.Snap> snaps = client.find_sync(Snapd.FindFlags.NONE, query, null, null);

        if (category == null) {
            snaps.foreach ((snap) => {
                var package = convert_snap_to_component (snap);
                if (package != null) {
                    apps.add (package);
                }
            });
        } else {
            var cat_packages = get_applications_for_category (category);
            if(cat_packages ==  null)
                return null;
        }

        return apps;
    }

    public Gee.Collection<Package> search_applications_mime (string query) {
        return new Gee.ArrayList<Package> ();
    }

    public Package? get_package_for_component_id (string id) {
        Package package = null;
        Snapd.Snap snap = null;

        if (id.substring(0, 1) == "*") {
            var component_id = id.substring(1);
            snap = get_specific_package_by_name (component_id);
        }
        else {
            return null;
        }

        if(snap != null){
            package = convert_snap_to_component(snap);            
        }

        return package;
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
        var bundle = package.component.get_bundle (AppStream.BundleKind.SNAP);
        if (bundle == null) {
            return 0;
        }

        var id = "%s/%s".printf (bundle.get_id (), Package.SNAP_ID_SUFFIX);
        warning(id);
        return yield get_download_size_by_id (id, cancellable);
    }

    public async uint64 get_download_size_by_id (string id, Cancellable? cancellable) throws GLib.Error {
        return 0;
    }

    public async bool is_package_installed (Package package) throws GLib.Error {
        for (int j = 0; j < installed.length; j++) {
            unowned Snapd.Snap snap = installed[j];

            var bundle_id = "%s/%s".printf(snap.get_id(), Package.SNAP_ID_SUFFIX);
            if (package.component.id == bundle_id) {
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

    public Package convert_snap_to_component(Snapd.Snap snap) {
        var icon = new AppStream.Icon();
        icon.set_name(snap.get_name());

        if (snap.get_icon() != null)
        {
            icon.set_url(snap.get_icon());
            icon.set_kind(AppStream.IconKind.REMOTE);
        }
        else
        {
            // fix to set icon path as Snapd client get_icon returns error
            icon.set_filename("/snap/" + snap.get_name() + "/current/usr/share/pixmaps/" + snap.get_name() + ".png");
            icon.set_kind(AppStream.IconKind.LOCAL);
        }

        var snap_component = new AppStream.Component();
        snap_component.id              =    "%s/%s".printf(snap.get_id(), Package.SNAP_ID_SUFFIX);
        snap_component.name            =    _(snap.get_name ());
        snap_component.developer_name  =    _(snap.get_developer ());
        snap_component.summary         =    _(snap.get_summary ());
        snap_component.description     =    _(snap.get_description ());
        snap_component.project_license =    _(snap.get_license ());

        snap.get_media().foreach ((media) => {
            if(media.get_media_type () == "screenshot"){
                var image = new AppStream.Image();
                var snap_screenshot = new AppStream.Screenshot();
                image.set_url(media.get_url());
                image.set_kind(AppStream.ImageKind.SOURCE);

                snap_screenshot.add_image(image);
                snap_component.add_screenshot(snap_screenshot);
            }
        });
        snap_component.add_icon(icon);

        var package = new Package (this, snap_component);
        package.name = snap.get_title();
        package.latest_version = snap.version;

        //  warning(snap.get_status ().to_string ());
        if(snap.get_status () == Snapd.SnapStatus.ACTIVE)
            package.mark_installed ();

        package.update_state ();
        //  var control = new Pk.Control();
        //  control.updates_changed.connect(updates_state);

        return package;
    }

    private string convertCategoryToSection(string category)
    {
        switch (category)
        {
            case "Audio":
                return("music-and-audio");

            case "Development":
                return("development");

            case "Communication":
                return("social");

            case "Accessories":
                return("utilities");

            case "Office":
                return("productivity");

            case "Internet":
                return("social-networking");

            case "Science":
                return("science");
            
            case "Finance":
                return("finance");

            case "Education":
                return("education");

            case "Accessibility":
            case "System":
                return("utilities");

            case "Graphics":
                return("art-and-design");

            case "Games":
                return("games");

            case "Video":
                return("photo-and-video");

            default:
                return(category);
        }
    }

    private static GLib.Once<SnapBackend> instance;
    public static unowned SnapBackend get_default () {
        return instance.once (() => { return new SnapBackend (); });
    }

}