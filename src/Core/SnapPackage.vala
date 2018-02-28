/* Copyright 2018 Nick Wilkins <nickawilkins@hotmail.com>
* Original Code from https://github.com/bartzaalberg/snaptastic
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

public class AppCenterCore.SnapPackage : Object {

    //private Snapd.Snap snap;
    public Snapd.Snap component { get; construct; }
    private GLib.Cancellable cancellable;
    public State state { public get; private set; default = State.NOT_INSTALLED; }

    /*public double progress {
        get {
            return change_information.progress;
        }
    }*/

    public enum State {
        NOT_INSTALLED,
        INSTALLED,
        INSTALLING,
        UPDATE_AVAILABLE,
        UPDATING,
        REMOVING
    }

    public bool installed {
        get {

            /*if (!installed_packages.is_empty) {
                return true;
            }

            if (component.get_id () == OS_UPDATES_ID) {
                return true;
            }

            Pk.Package? package = find_package ();
            if (package != null && package.info == Pk.Info.INSTALLED) {
                return true;
            }*/

            return false;
        }
    }

    public bool update_available {
        get {
            return state == State.UPDATE_AVAILABLE;
        }
    }

    public bool is_updating {
        get {
            return state == State.UPDATING;
        }
    }

    public bool changes_finished {
        get {
            return false;
        }
    }

    /*public bool is_os_updates {
        get {
            return component.id == OS_UPDATES_ID;
        }
    }

    /*public bool is_driver {
       get {
           return component.get_kind () == AppStream.ComponentKind.DRIVER;
       }
    }

    public bool is_local {
        get {
            return component.get_id ().has_suffix (LOCAL_ID_SUFFIX);
        }
    }*/

    public bool is_shareable {
        get {
            return false;
        }
    }

    /*public bool is_native {
        get {
            switch (component.get_origin ()) {
                case APPCENTER_PACKAGE_ORIGIN:
                case ELEMENTARY_STABLE_PACKAGE_ORIGIN:
                case ELEMENTARY_DAILY_PACKAGE_ORIGIN:
                    return true;
                default:
                    return false;
            }
            return false;
        }
    }*/

    private string? _author = null;
    public string author {
        get {
            if (_author != null) {
                return _author;
            }

            _author = component.developer;

            return _author;
        }
    }

    private string? _author_title = null;
    public string author_title {
        get {
            if (_author_title != null) {
                return _author_title;
            }

            _author_title = author;
            if (_author_title == null) {
                _author_title = _("The %s Developers").printf (get_name ());
            }

            return _author_title;
        }
    }

    private string? name = null;
    public string? description = null;
    private string? summary = null;
    private string? channel = null;
    private string? developer = null;
    private string? title = null;
    private string? icon = null;
    private string? version = null;
    public string? latest_version {
        private get { return version; }
        internal set { version = value; }
    }

    public SnapPackage(Snapd.Snap snap){
        Object(component : snap);
    }

    public string? get_name () {
        if (name != null) {
            return name;
        }
        name = component.get_name ();

        return name;
    }

    public string? get_description () {
        if (description != null) {
            return description;
        }

        description = component.get_description ();

        return description;
    }

    public string? get_summary () {
        if (summary != null) {
            return summary;
        }

        summary = component.get_summary ();

        return summary;
    }

    public GLib.Icon get_icon (uint size = 32) {
        GLib.Icon? icon = null;
        uint current_size = 0;

        bool is_stock = false;

        icon = new ThemedIcon (component.get_icon ());

        return icon;
    }

    public string? get_version () {
        if (latest_version != null) {
            return latest_version;
        }

        //var package = find_package ();
        //if (package != null) {
            latest_version = component.get_version ();
        //}

        return latest_version;
    }
}
