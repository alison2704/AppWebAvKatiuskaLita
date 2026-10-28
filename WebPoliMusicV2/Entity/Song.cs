using System;
using System.Collections.Generic;
using System.Web;

namespace WebPoliMusicV2.Entity
{
    /// <summary>
    /// Entity that represents a row of the TBL_SONG table.
    /// It lives in the WebPoliMusicV2.Entity namespace because the name "Song"
    /// is already used by the page class of Song.aspx (WebPoliMusicV2.Song).
    /// </summary>
    public class Song
    {
        public Song()
        {
        }
        public Song(int id, string name, string path, int plays)
        {
            ID = id;
            Name = name;
            Path = path;
            Plays = plays;
        }
        public int ID { get; set; }
        public string Name { get; set; }
        public string Path { get; set; }
        public int Plays { get; set; }
    }

}
