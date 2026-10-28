using System;
using System.Collections.Generic;
using System.Data;
using System.Web;

namespace WebPoliMusicV2.BLL
{
    public class User
    {
        private string strConnectionString;
        public User(string strConnString)
        {
            strConnectionString = strConnString;
        }
        public int Save(global::WebPoliMusicV2.User user)
        {
            return new DAL.User(strConnectionString).Save(user);
        }
        public DataTable Read()
        {
            return new DAL.User(strConnectionString).Read();
        }

        public int Update(global::WebPoliMusicV2.User user)
        {
            return new DAL.User(strConnectionString).Update(user);
        }

        public int Delete(int id)
        {
            return new DAL.User(strConnectionString).Delete(id);
        }
        public DataTable AuthenticateUser(string login, string password)
        {
            return new DAL.User(strConnectionString).AuthenticateUser(login, password);
        }
        public int CheckExistUser(string userName)
        {
            return new DAL.User(strConnectionString).CheckExistUser(userName);
        }
        public int CheckExistEmail(string email)
        {
            return new DAL.User(strConnectionString).CheckExistEmail(email);
        }
        public string ValidationsDuplicated(global::WebPoliMusicV2.User user)
        {
            int returnValue = CheckExistUser(user.UserName);
            if (returnValue != 0)
            {
                return "Username already registered!";
            }
            returnValue = CheckExistEmail(user.Email);
            if (returnValue != 0)
            {
                return "Email already used!.";
            }
            return string.Empty;
        }
    }

}