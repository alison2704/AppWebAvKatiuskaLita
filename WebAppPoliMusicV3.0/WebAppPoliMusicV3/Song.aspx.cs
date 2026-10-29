using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV3
{
    public partial class Song : System.Web.UI.Page
    {
        string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        private EntityLayer.PoliMusicV3.User CurrentUser
        {
            get { return Session[EntityLayer.PoliMusicV3.Util.Constants.USER] as EntityLayer.PoliMusicV3.User; }
        }

        protected bool IsAdmin
        {
            get
            {
                return CurrentUser != null &&
                    CurrentUser.UserType == EntityLayer.PoliMusicV3.Util.Constants.ID_USER_ADMIN;
            }
        }

        private string CurrentFilter
        {
            get { return Convert.ToString(ViewState["SongFilter"] ?? string.Empty); }
            set { ViewState["SongFilter"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                lblMessage.Text = string.Empty;
                pnlAdmin.Visible = false;
                btnNew.Visible = IsAdmin;
                ShowWelcome();
                BindSongs();
            }
        }

        #region Pantalla

        private void ShowWelcome()
        {
            string userName = string.Empty;
            if (CurrentUser != null)
            {
                userName = CurrentUser.UserName;
            }
            else if (Context.User != null && Context.User.Identity.IsAuthenticated)
            {
                userName = Context.User.Identity.Name;
            }
            if (string.IsNullOrEmpty(userName))
            {
                userName = "invitado";
            }
            lblWelcome.Text = Server.HtmlEncode(userName);
        }

        private void BindSongs()
        {
            BLL.PoliMusicV3.Song bllSong = new BLL.PoliMusicV3.Song(strConnString);
            DataTable dtSongs = string.IsNullOrEmpty(CurrentFilter) ? bllSong.Read() : bllSong.ReadByName(CurrentFilter);

            rptSongs.DataSource = dtSongs;
            rptSongs.DataBind();
            pnlEmpty.Visible = dtSongs.Rows.Count == 0;

            int totalPlays = 0;
            foreach (DataRow row in dtSongs.Rows)
            {
                if (row["PLAYS"] != DBNull.Value)
                {
                    totalPlays += Convert.ToInt32(row["PLAYS"]);
                }
            }

            lblTotalSongs.Text = dtSongs.Rows.Count.ToString();
            lblStatSongs.Text = dtSongs.Rows.Count.ToString();
            lblTotalPlays.Text = totalPlays.ToString("N0");
            lblStatPlays.Text = totalPlays.ToString("N0");

            RegisterTracks(dtSongs);
        }

        /// <summary>
        /// Envia al reproductor del cliente la lista de canciones que se esta mostrando.
        /// </summary>
        private void RegisterTracks(DataTable dtSongs)
        {
            StringBuilder sbScript = new StringBuilder();
            sbScript.Append("window.PM_TRACKS=[");
            for (int i = 0; i < dtSongs.Rows.Count; i++)
            {
                if (i > 0)
                {
                    sbScript.Append(',');
                }
                sbScript.Append("{id:").Append(Convert.ToInt32(dtSongs.Rows[i]["ID_SONG"]));
                sbScript.Append(",name:\"").Append(JsonText(dtSongs.Rows[i]["SONG_NAME"])).Append('"');
                sbScript.Append(",url:\"").Append(JsonText(ResolveSongUrl(dtSongs.Rows[i]["SONG_PATH"]))).Append('"');
                sbScript.Append('}');
            }
            sbScript.Append("];");
            ClientScript.RegisterStartupScript(GetType(), "pmTracks", sbScript.ToString(), true);
        }

        /// <summary>
        /// Devuelve la letra que se muestra en la portada de cada cancion.
        /// </summary>
        public string Initial(object songName)
        {
            string name = Convert.ToString(songName);
            if (string.IsNullOrEmpty(name) || name.Trim() == string.Empty)
            {
                return "&#9835;";
            }
            return Server.HtmlEncode(name.Trim().Substring(0, 1).ToUpper());
        }

        /// <summary>
        /// Convierte la ruta guardada en la base (SONG_PATH) en una URL utilizable.
        /// </summary>
        public string ResolveSongUrl(object songPath)
        {
            string path = Convert.ToString(songPath);
            if (string.IsNullOrEmpty(path) || path.Trim() == string.Empty)
            {
                return string.Empty;
            }
            path = path.Trim().Replace('\\', '/');
            if (path.StartsWith("~/"))
            {
                return ResolveUrl(path);
            }
            if (path.StartsWith("~"))
            {
                return ResolveUrl("~/" + path.Substring(1).TrimStart('/'));
            }
            if (path.StartsWith("/"))
            {
                return ResolveUrl("~" + path);
            }
            return ResolveUrl("~/songFiles/" + path);
        }

        private static string JsonText(object value)
        {
            string text = Convert.ToString(value);
            if (text == null)
            {
                return string.Empty;
            }
            return text.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", string.Empty).Replace("\n", " ");
        }

        #endregion

        #region Busqueda

        protected void BtnSearch_Click(object sender, EventArgs e)
        {
            CurrentFilter = txtSearch.Text.Trim();
            lblMessage.Text = string.Empty;
            BindSongs();
        }

        protected void BtnClear_Click(object sender, EventArgs e)
        {
            CurrentFilter = string.Empty;
            txtSearch.Text = string.Empty;
            lblMessage.Text = string.Empty;
            BindSongs();
        }

        #endregion

        #region CRUD (administrador)

        protected void RptSongs_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int idSong;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out idSong))
            {
                return;
            }

            if (e.CommandName == "edit")
            {
                if (!IsAdmin)
                {
                    lblMessage.Text = "Only the administrator can edit songs.";
                    return;
                }
                LoadSong(idSong);
            }
            else if (e.CommandName == "delete")
            {
                if (!IsAdmin)
                {
                    lblMessage.Text = "Only the administrator can delete songs.";
                    return;
                }
                DeleteSong(idSong);
            }
        }

        private void LoadSong(int idSong)
        {
            DataTable dtSong = new BLL.PoliMusicV3.Song(strConnString).ReadById(idSong);
            if (dtSong.Rows.Count == 0)
            {
                lblMessage.Text = "The song does not exist anymore.";
                return;
            }
            hdnSongId.Value = idSong.ToString();
            txtSongName.Text = Convert.ToString(dtSong.Rows[0]["SONG_NAME"]);
            txtSongPath.Text = Convert.ToString(dtSong.Rows[0]["SONG_PATH"]);
            lblFormTitle.Text = "Editar canción #" + idSong;
            pnlAdmin.Visible = true;
            lblMessage.Text = string.Empty;
        }

        private void DeleteSong(int idSong)
        {
            new BLL.PoliMusicV3.Song(strConnString).Delete(idSong);
            if (hdnSongId.Value == idSong.ToString())
            {
                ClearForm();
            }
            BindSongs();
            lblMessage.Text = "Song deleted successfully!.";
        }

        protected void BtnNew_Click(object sender, EventArgs e)
        {
            if (!IsAdmin)
            {
                lblMessage.Text = "Only the administrator can register songs.";
                return;
            }
            ClearForm();
            pnlAdmin.Visible = true;
            lblFormTitle.Text = "Nueva canción";
            lblMessage.Text = string.Empty;
        }

        protected void BtnCancel_Click(object sender, EventArgs e)
        {
            ClearForm();
            lblMessage.Text = string.Empty;
        }

        protected void BtnSave_Click(object sender, EventArgs e)
        {
            if (!IsAdmin)
            {
                lblMessage.Text = "Only the administrator can save songs.";
                return;
            }

            int idSong = 0;
            int.TryParse(hdnSongId.Value, out idSong);

            EntityLayer.PoliMusicV3.Song song = new EntityLayer.PoliMusicV3.Song();
            song.ID = idSong;
            song.Name = txtSongName.Text.Trim();
            song.Path = txtSongPath.Text.Trim();

            if (song.Name == string.Empty)
            {
                lblMessage.Text = "Song name is required!";
                return;
            }

            BLL.PoliMusicV3.Song bllSong = new BLL.PoliMusicV3.Song(strConnString);

            if (idSong > 0)
            {
                DataTable dtSong = bllSong.ReadById(idSong);
                if (dtSong.Rows.Count > 0 && dtSong.Rows[0]["PLAYS"] != DBNull.Value)
                {
                    song.Plays = Convert.ToInt32(dtSong.Rows[0]["PLAYS"]);
                }
            }

            if (fupSongFile.HasFile)
            {
                string strSongFolder = ConfigurationManager.AppSettings["songFolderPath"];
                string strFileName = BuildFileName(song.Name);
                string messageUpload = new FileManagement().SaveSongOnServer(fupSongFile, strSongFolder, strFileName);
                if (messageUpload != string.Empty)
                {
                    lblMessage.Text = messageUpload;
                    return;
                }
                song.Path = "~/songFiles/" + strFileName + ".mp3";
            }

            string messageValidations = bllSong.ValidationsRequired(song);
            if (messageValidations != string.Empty)
            {
                lblMessage.Text = messageValidations;
                return;
            }

            if (idSong > 0)
            {
                bllSong.Update(song);
                lblMessage.Text = "Song updated successfully!.";
            }
            else
            {
                bllSong.Save(song);
                lblMessage.Text = "Song registered successfully!.";
            }

            ClearForm();
            BindSongs();
        }

        private void ClearForm()
        {
            hdnSongId.Value = "0";
            txtSongName.Text = string.Empty;
            txtSongPath.Text = string.Empty;
            lblFormTitle.Text = "Nueva canción";
            pnlAdmin.Visible = false;
        }

        private static string BuildFileName(string songName)
        {
            StringBuilder sbFileName = new StringBuilder();
            foreach (char character in songName)
            {
                if (char.IsLetterOrDigit(character))
                {
                    sbFileName.Append(character);
                }
                else if (character == ' ' || character == '-' || character == '_')
                {
                    sbFileName.Append('_');
                }
            }
            return sbFileName.Length == 0 ? "song" : sbFileName.ToString();
        }

        #endregion
    }
}
