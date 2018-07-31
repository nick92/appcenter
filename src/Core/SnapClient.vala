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
            critical("Couldn't connect to Snapd");
        }
    }

    /** TODO -- possible future implemntation, but recieved error
    /**public GLib.Icon get_snap_icon (string name)
    {
      try{
        warning (name);
        var icon = client.get_icon_sync (name);
        return new BytesIcon(icon.get_data());
      }catch(Error error){
        warning(error.message);
        return null;
      }
      //var input_stream = new MemoryInputStream.from_bytes(icon.get_data());
      //return new Gdk.Pixbuf.from_stream_at_scale (input_stream, 32, 32, true);
    }*/

    public async bool update_snap_package(Package snap, Snapd.ProgressCallback cb, GLib.Cancellable cancellable){
        bool binstall = false;

        try{
            binstall = yield client.install2_async (Snapd.InstallFlags.CLASSIC, snap.get_name (), null, null, cb, cancellable);
        } catch (Error e) {
            critical(e.message);
            return false;
        }

        return binstall;
    }

    public async bool remove_snap_package(Package snap, Snapd.ProgressCallback cb, GLib.Cancellable cancellable){
        bool binstall = false;

        try{
            binstall = yield client.remove_async (snap.get_name (), cb, cancellable);
        } catch (Error e) {
            critical(e.message);
            return false;
        }

        return binstall;
    }

    public async bool install_snap_package(Package snap, Snapd.ProgressCallback cb, GLib.Cancellable cancellable){
        bool binstall = false;

        try{
            binstall = yield client.install2_async (Snapd.InstallFlags.CLASSIC, snap.get_name (), null, null, cb, cancellable);
        } catch (Error e) {
            critical(e.message);
            return false;
        }

        return binstall;
    }


    public GLib.GenericArray<weak Snapd.Snap> getInstalledPackages() {

        GLib.GenericArray<weak Snapd.Snap> snaps = client.list_sync (null);

        return snaps;
    }

    public async GLib.GenericArray<weak Snapd.Snap> getInstalledPackagesAsync () {

        GLib.GenericArray<weak Snapd.Snap> snaps = yield client.list_async (cancellable);

        return snaps;
    }

    public GLib.GenericArray<weak Snapd.Snap> getPackagesForSection(AppStream.Category section) {

        GLib.GenericArray<weak Snapd.Snap> snaps = client.find_section_sync (Snapd.FindFlags.NONE, convertCategoryToSection(section.name), null, null, cancellable);

        return snaps;
    }

    public GLib.GenericArray<weak Snapd.Snap> getFeaturedSnaps() {

        GLib.GenericArray<weak Snapd.Snap> snaps = client.find_section_sync (Snapd.FindFlags.NONE, "featured", null, null, cancellable);

        return snaps;
    }

    public GLib.GenericArray<weak Snapd.Snap> getRefreshablePackages() {

        GLib.GenericArray<weak Snapd.Snap> snaps = client.find_refreshable_sync ();

        return snaps;
    }

    public async GLib.GenericArray<weak Snapd.Snap> getRefreshablePackagesAsync() {

        GLib.GenericArray<weak Snapd.Snap> snaps = yield client.find_refreshable_async (cancellable);

        return snaps;
    }

    public GLib.GenericArray<weak Snapd.Alias> getSnapAlias() {

        GLib.GenericArray<weak Snapd.Alias> alias = client.get_aliases_sync (null);

        return alias;
    }

    public GLib.GenericArray<weak Snapd.Snap> getPackageByName(string searchWord = "") {
		    try{
            GLib.GenericArray<weak Snapd.Snap> snaps = client.find_sync (Snapd.FindFlags.NONE, searchWord, null, cancellable);
            return snaps;
        } catch (Snapd.Error e) {
            critical(e.message);
        }

        return null;
    }

    public GLib.GenericArray<weak Snapd.Snap> getSpecificPackageByName(string searchWord = "") {
		    try{
            GLib.GenericArray<weak Snapd.Snap> snaps = client.find_sync (Snapd.FindFlags.MATCH_NAME, searchWord, null, cancellable);
            return snaps;
        } catch (Snapd.Error e) {
            critical(e.message);
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
