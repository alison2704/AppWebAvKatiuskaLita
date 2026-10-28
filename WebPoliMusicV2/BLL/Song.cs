using System;
using System.Collections.Generic;
using System.Data;
using System.Web;

namespace WebPoliMusicV2.BLL
{
    public class Song
    {
        private string strConnectionString;
        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }
        public int Save(global::WebPoliMusicV2.Entity.Song song)
        {
            return new DAL.Song(strConnectionString).Save(song);
        }
        public DataTable Read()
        {
            return new DAL.Song(strConnectionString).Read();
        }
        public DataTable ReadById(int idSong)
        {
            return new DAL.Song(strConnectionString).ReadById(idSong);
        }
        public int Update(global::WebPoliMusicV2.Entity.Song song)
        {
            return new DAL.Song(strConnectionString).Update(song);
        }
        public int IncrementPlays(int idSong)
        {
            return new DAL.Song(strConnectionString).IncrementPlays(idSong);
        }
        public int Delete(int idSong)
        {
            return new DAL.Song(strConnectionString).Delete(idSong);
        }
        public string ValidationsRequired(global::WebPoliMusicV2.Entity.Song song)
        {
            if (song.Name == null || song.Name.Trim() == string.Empty)
            {
                return "Song name is required!";
            }
            if (song.Path == null || song.Path.Trim() == string.Empty)
            {
                return "Song path is required!";
            }
            if (song.Plays < 0)
            {
                return "Plays cannot be a negative number!";
            }
            return string.Empty;
        }
    }

}
