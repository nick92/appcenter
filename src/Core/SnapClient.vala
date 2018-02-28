/* Copyright 2018 Nick Wilkins <nickawilkins@hotmail.com>
*
* This program is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see http://www.gnu.org/licenses/.
*/

public class AppCenterCore.SnapClient : Object {
    private Snapd.Client client;
    private GLib.Cancellable cancellable;
    private static SnapClient instance;

    public SnapClient(){
        client = new Snapd.Client();
        cancellable = new GLib.Cancellable ();

        if (!client.connect_sync (null)){
            //new Granite.Widgets.AlertView("An error occured","could not connect to snapd", "error");
        }
    }

    public async bool update_snap_package(Package snap, Snapd.ProgressCallback cb, GLib.Cancellable cancellable){
        bool binstall = false;

        try{
            binstall = yield client.install2_async (Snapd.InstallFlags.CLASSIC, snap.get_name (), null, null, cb, cancellable);
        } catch (SpawnError e) {
            stdout.printf(e.message);
        }

        return binstall;
    }

    public async bool remove_snap_package(Package snap, Snapd.ProgressCallback cb, GLib.Cancellable cancellable){
        bool binstall = false;

        try{
            binstall = yield client.remove_async (snap.get_name (), cb, cancellable);
        } catch (SpawnError e) {
            stdout.printf(e.message);
        }

        return binstall;
    }

    public async bool install_snap_package(Package snap, Snapd.ProgressCallback cb, GLib.Cancellable cancellable){
        bool binstall = false;

        try{
            binstall = yield client.install2_async (Snapd.InstallFlags.CLASSIC, snap.get_name (), null, null, cb, cancellable);
        } catch (SpawnError e) {
            stdout.printf(e.message);
        }

        return binstall;
    }


    public GLib.GenericArray<weak Snapd.Snap> getInstalledPackages() {

        GLib.GenericArray<weak Snapd.Snap> snaps = client.list_sync (null);

        /*bool asc = true;
	    snaps.sort_with_data (( a, b) => {
		    return (asc)? strcmp (a.name, b.name) : strcmp (b.name, a.name);
	    });*/

        return snaps;
    }

    public async GLib.GenericArray<weak Snapd.Snap> getInstalledPackagesAsync () {

        GLib.GenericArray<weak Snapd.Snap> snaps = yield client.list_async (cancellable);

        return snaps;
    }

    public GLib.GenericArray<weak Snapd.Snap> getPackagesForSection(AppStream.Category section) {

        //if(convertCategoryToSection(section.name).length > 0)
        GLib.GenericArray<weak Snapd.Snap> snaps = client.find_section_sync (Snapd.FindFlags.NONE, convertCategoryToSection(section.name), null, null, cancellable);

        return snaps;
    }

    public GLib.GenericArray<weak Snapd.Snap> getFeaturedSnaps() {

        //if(convertCategoryToSection(section.name).length > 0)
        GLib.GenericArray<weak Snapd.Snap> snaps = client.find_section_sync (Snapd.FindFlags.NONE, "featured", null, null, cancellable);

        return snaps;
    }

    public async GLib.GenericArray<weak Snapd.Snap> getRefreshablePackages() {

        GLib.GenericArray<weak Snapd.Snap> snaps = yield client.find_refreshable_async (cancellable);

        /*bool asc = true;
	    snaps.sort_with_data (( a, b) => {
		    return (asc)? strcmp (a.name, b.name) : strcmp (b.name, a.name);
	    });*/

        return snaps;
    }

    public GLib.GenericArray<weak Snapd.Alias> getSnapAlias() {

        GLib.GenericArray<weak Snapd.Alias> alias = client.get_aliases_sync (null);

        return alias;
    }

    public GLib.GenericArray<weak Snapd.Snap> getPackageByName(string searchWord = "") {
        //GLib.GenericArray<weak Snapd.Snap> snaps;

        try{
            GLib.GenericArray<weak Snapd.Snap> snaps = client.find_sync (Snapd.FindFlags.NONE, searchWord, null, cancellable);
            return snaps;
        } catch (Snapd.Error e) {
            critical(e.message);
            //new Granite.Widgets.AlertView("There was an error spawning the process. Details", e.message, "error");
        }

        return null;
    }

    private string convertCategoryToSection (string category){

        switch (category) {
            case "Audio":
                return "music";
            break;
            case "Development":
                return "developers";
            break;
            case "Accessories":
                return "utilities";
            break;
            case "Office":
                return "finance";
            break;
            case "System":
                return "utilities";
            break;
            case "Internet":
                return "social-networking";
            break;
            case "Science":
                return "poductivity";
            break;
            case "Education":
                return "poductivity";
            break;
            case "Accessibility":
                return "utilities";
            break;
            default:
                return category;
        }
    }

    public static SnapClient get_default () {
        if(instance == null)
            instance = new SnapClient ();

        return instance;
    }
}
