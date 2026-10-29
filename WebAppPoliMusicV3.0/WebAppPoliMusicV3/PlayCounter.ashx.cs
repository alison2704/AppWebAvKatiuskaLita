using System;
using System.Configuration;
using System.Data;
using System.Web;

namespace WebAppPoliMusicV3
{
    /// <summary>
    /// Incrementa el contador de reproducciones de una cancion (TBL_SONG.PLAYS)
    /// usando la capa de negocio, sin recargar la pagina.
    /// </summary>
    public class PlayCounter : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/plain";

            int idSong;
            if (!int.TryParse(context.Request.QueryString["id"], out idSong) || idSong <= 0)
            {
                context.Response.Write("0");
                return;
            }

            string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
            BLL.PoliMusicV3.Song bllSong = new BLL.PoliMusicV3.Song(strConnString);

            bllSong.IncrementPlays(idSong);

            DataTable dtSong = bllSong.ReadById(idSong);
            int plays = 0;
            if (dtSong.Rows.Count > 0 && dtSong.Rows[0]["PLAYS"] != DBNull.Value)
            {
                plays = Convert.ToInt32(dtSong.Rows[0]["PLAYS"]);
            }
            context.Response.Write(plays.ToString());
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}
