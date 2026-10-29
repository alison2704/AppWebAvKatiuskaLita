using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV3
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            EntityLayer.PoliMusicV3.User user = Session[EntityLayer.PoliMusicV3.Util.Constants.USER] as EntityLayer.PoliMusicV3.User;

            string userName = string.Empty;
            if (user != null && !string.IsNullOrEmpty(user.UserName))
            {
                userName = user.UserName;
            }
            else if (Context.User != null && Context.User.Identity.IsAuthenticated)
            {
                userName = Context.User.Identity.Name;
            }

            if (string.IsNullOrEmpty(userName))
            {
                userName = "Invitado";
            }

            lblSessionUser.Text = Server.HtmlEncode(userName);
            lblSessionRole.Text = (user != null && user.UserType == EntityLayer.PoliMusicV3.Util.Constants.ID_USER_ADMIN)
                ? "Administrador"
                : "Usuario";
            litUserInitial.Text = Server.HtmlEncode(userName.Trim().Substring(0, 1));

            SetActiveMenu();
        }

        private void SetActiveMenu()
        {
            string currentPage = VirtualPathUtility.GetFileName(Request.AppRelativeCurrentExecutionFilePath).ToLower();

            lnkHome.CssClass = currentPage == "default.aspx" ? "pm-active" : string.Empty;
            lnkSongs.CssClass = currentPage == "song.aspx" ? "pm-active" : string.Empty;
            lnkAbout.CssClass = currentPage == "about.aspx" ? "pm-active" : string.Empty;
            lnkContact.CssClass = currentPage == "contact.aspx" ? "pm-active" : string.Empty;
        }
    }
}
