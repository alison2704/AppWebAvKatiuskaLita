using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.PoliMusicV3
{
    public class Song
    {
        private string strConnectionString;
        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }
        public int Save(EntityLayer.PoliMusicV3.Song song)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Save(song);
        }
        public DataTable Read()
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Read();
        }
        public DataTable ReadById(int idSong)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).ReadById(idSong);
        }
        public DataTable ReadByName(string songName)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).ReadByName(songName);
        }
        public int Update(EntityLayer.PoliMusicV3.Song song)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Update(song);
        }
        public int IncrementPlays(int idSong)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).IncrementPlays(idSong);
        }
        public int Delete(int idSong)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Delete(idSong);
        }
        public string ValidationsRequired(EntityLayer.PoliMusicV3.Song song)
        {
            if (song.Name == null || song.Name.Trim() == string.Empty)
            {
                return "Song name is required!";
            }
            if (song.Name.Trim().Length > 50)
            {
                return "Song name cannot be longer than 50 characters!";
            }
            if (song.Path == null || song.Path.Trim() == string.Empty)
            {
                return "Song path is required!";
            }
            if (song.Path.Trim().Length > 255)
            {
                return "Song path cannot be longer than 255 characters!";
            }
            if (song.Plays < 0)
            {
                return "Plays cannot be a negative number!";
            }
            return string.Empty;
        }
    }


}
