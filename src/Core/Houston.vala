/* Copyright 2017 elementary LLC. (https://elementary.io)
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
 *
 * Authored by: Blake Kostner <blake@elementary.io>
 */

public class AppCenterCore.Houston : Object {
   //private const string HOUSTON_API_URL = "http://api.enso-os.site";
   private const string HOUSTON_API_URL = "https://nick92-appstar.herokuapp.com";

   private Soup.Session session;

   construct {
      session = new Soup.Session();
   }

   private Json.Object process_response(string res) throws Error
   {
      var parser = new Json.Parser();

      parser.load_from_data(res, -1);

      var root = parser.get_root().get_object();

      if (root.has_member("errors") && root.get_array_member("errors").get_length() > 0)
      {
         var err = root.get_array_member("errors").get_object_element(0).get_string_member("title");

         if (err != null)
         {
            throw new Error(0, 0, err);
         }
         else
         {
            throw new Error(0, 0, "Error while talking to Houston");
         }
      }

      return(root);
   }

   /*public string[] get_app_ids_sync (string endpoint) {
    *  var uri = HOUSTON_API_URL + endpoint;
    *  string[] app_ids = {};
    *
    *  debug ("Requesting newest applications from %s", uri);
    *
    *  var message = new Soup.Message ("GET", uri);
    *  session.send_message (message, (sess, mess) => {
    *      try {
    *          var res = process_response ((string) mess.response_body.data);
    *          if (res.has_member ("data")) {
    *              var data = res.get_array_member ("data");
    *
    *              foreach (var id in data.get_elements ()) {
    *                  app_ids += ((string) id.get_value ());
    *              }
    *          }
    *      } catch (Error e) {
    *          warning ("Houston: %s", e.message);
    *      }
    *
    *      //Idle.add (get_app_ids_sync.callback);
    *  });
    *          //warning(app_ids[0]);
    *  //yield;
    *  return app_ids;
    * }*/

   public async void star_app_by_name(string endpoint, string app_name)
   {
      var uri = HOUSTON_API_URL + endpoint;

      warning("Starring application name %s", app_name);

      var message = new Soup.Message("POST", uri + "?name=" + app_name);
      //message.request_headers.append ("Accepts", "application/vnd.api+json");
      message.request_headers.append("Content-Type", "application/x-www-form-urlencoded");
      session.send_message(message);

      Idle.add(star_app_by_name.callback);

      var data = new StringBuilder();
      foreach (var c in message.response_body.data)
      {
         data.append("%c".printf(c));
      }

      warning(data.str);
      yield;
   }

   public async string[] get_app_ids(string endpoint)
   {
      var uri = HOUSTON_API_URL + endpoint;

      string[] app_ids = {};

      debug("Requesting newest applications from %s", uri);

      var message = new Soup.Message("GET", uri);
      session.queue_message(message, (sess, mess) => {
         try {
            var res = process_response((string)mess.response_body.data);
            if (res.has_member("data"))
            {
               var data = res.get_array_member("data");

               foreach (var id in data.get_elements())
               {
                  app_ids += id.get_object().get_string_member("Appname");
               }
            }
         } catch (Error e) {
            warning("Houston: %s", e.message);
         }

         Idle.add(get_app_ids.callback);
      });

      yield;
      return(app_ids);
   }

   private static GLib.Once <Houston> instance;
   public static unowned Houston get_default()
   {
      return(instance.once(() => { return new Houston(); }));
   }
}
