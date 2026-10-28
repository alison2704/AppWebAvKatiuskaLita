using System;
using System.Collections.Generic;

using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebPoliMusicV2
{
    /// <summary>
    /// Entry point of the application. It only decides where the user has to go:
    /// Login.aspx when there is no authenticated user, Song.aspx when there is one.
    /// </summary>
    public partial class Default : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                if (Session[Util.Constants.USER] != null)
                {
                    Response.Redirect("~/Song.aspx", true);
                }
                else
                {
                    Response.Redirect("~/Login.aspx", true);
                }
            }
        }

    }

}
