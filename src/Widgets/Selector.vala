/* Copyright 2015 Taken from Panther
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

namespace AppCenter {
	public class Selector : Gtk.ButtonBox {
	    public signal void mode_changed();

	    private int _selected;
	    public int selected {
	        get {
	            return this._selected;
	        }
	        set {
	            this.set_selector(value);
	        }
	    }

	    private Gtk.ToggleButton view_home;
	    private Gtk.ToggleButton view_cats;
	    private Gtk.ToggleButton view_installed;

	    public Selector(Gtk.Orientation orientation) {

	        this._selected = -1;
	        this.set_orientation(orientation);
	        //this.set_layout(Gtk.ButtonBoxStyle.START);
	        this.margin_start = 10;
	        this.margin_end = 10;

			view_home = new Gtk.ToggleButton();
			view_home.label = "Home";
	        this.pack_start (view_home,false,false,0);

	        view_cats = new Gtk.ToggleButton();
			view_cats.label = "Categories";
	        this.pack_start (view_cats,false,false,0);

	        view_installed = new Gtk.ToggleButton();
			view_installed.label = "Installed";
	        this.pack_start(view_installed,false,false,0);

	        view_home.button_release_event.connect( (bt) => {
	            if(view_home.active)
	                this.set_selector(0);
	            else
	                this.set_selector(1);

	            return true;
	        });
			view_cats.button_release_event.connect( (bt) => {
	            if(view_cats.active)
	                this.set_selector(0);
	            else
	                this.set_selector(1);

	            return true;
	        });
			view_installed.button_release_event.connect( (bt) => {
	            if(view_installed.active)
	                this.set_selector(0);
	            else
	                this.set_selector(1);

	            return true;
	        });
	    }

	    public int get_selector() {
	        return this._selected;
	    }

	    public void set_selector(int v) {
	        if (this._selected != v) {
	            this._selected = v;
	            switch(v) {
	            case 0:
	                
	                break;
	            case 1:

	                break;
	            case 2:

	                break;
	            }

	            this.mode_changed();
	        }
	    }
	}
}
