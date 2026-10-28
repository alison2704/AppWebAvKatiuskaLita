using System;
using System.Collections.Generic;

using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebPoliMusicV2
{
    public partial class Logout : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // 1. Drop the authenticated user from the session.
            Session.Clear();
            Session.Abandon();

            // 2. Remove the forms authentication cookie.
            FormsAuthentication.SignOut();

            // 3. Back to the login screen.
            Response.Redirect("~/Login.aspx", true);
        }
    }

}
