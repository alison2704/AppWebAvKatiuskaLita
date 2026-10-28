using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;

using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebPoliMusicV2
{
    public partial class Song : System.Web.UI.Page
    {
        string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            global::WebPoliMusicV2.User user = (global::WebPoliMusicV2.User)Session[Util.Constants.USER];
            if (user == null)
            {
                // No authenticated user in session: go back to the login screen.
                Response.Redirect("~/Login.aspx", true);
                return;
            }
            if (!Page.IsPostBack)
            {
                LoadUser(user);
                LoadSongs();
            }
        }

        /// <summary>
        /// Shows the name and the photo of the user that was authenticated on Login.aspx.
        /// </summary>
        private void LoadUser(global::WebPoliMusicV2.User user)
        {
            litUserName.Text = Server.HtmlEncode(user.UserName);

            string strPhoto = "~/userImages/default.jpg";
            if (user.Photo != null && user.Photo.Trim() != string.Empty)
            {
                strPhoto = user.Photo;
            }
            imgUserPhoto.ImageUrl = ResolveUrl(strPhoto);
            imgUserPhoto.AlternateText = user.UserName;
        }

        /// <summary>
        /// Gets the song list from the business layer and binds it to the repeater.
        /// </summary>
        private void LoadSongs()
        {
            DataTable dtSong = new BLL.Song(strConnString).Read();
            if (dtSong != null && dtSong.Rows.Count > 0)
            {
                rptSongs.DataSource = dtSong;
                rptSongs.DataBind();
                lblMessage.Text = string.Empty;
            }
            else
            {
                rptSongs.Visible = false;
                lblMessage.Text = "There are no songs registered in the database.";
            }
        }

        /// <summary>
        /// Path of the song as it is shown in the "Ruta" column.
        /// </summary>
        protected string GetSongPath(object songPath)
        {
            string strPath = (songPath == null) ? string.Empty : songPath.ToString();
            return Server.HtmlEncode(strPath.Replace("~/", "../"));
        }

        /// <summary>
        /// Application relative url used by the audio player of the "Reproducir" column.
        /// </summary>
        protected string GetSongUrl(object songPath)
        {
            string strPath = (songPath == null) ? string.Empty : songPath.ToString();
            if (strPath.Trim() == string.Empty)
            {
                return string.Empty;
            }
            if (strPath.StartsWith("~/"))
            {
                return ResolveUrl(strPath);
            }
            return strPath;
        }
    }

}
