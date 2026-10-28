using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebPoliMusicV2
{
    public partial class Login : System.Web.UI.Page
    {
        string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                lblMessage.Text = string.Empty;

                // Coming back from SignUp.aspx: the account was created successfully.
                if (Request.QueryString["registered"] == "1")
                {
                    lblMessage.CssClass = "msg msg-success";
                    lblMessage.Text = "Your account was created successfully. Please sign in.";
                }

                // A user that is already authenticated does not need the login screen again.
                if (Session[Util.Constants.USER] != null)
                {
                    Response.Redirect("~/Song.aspx", true);
                    return;
                }
            }
        }

        protected void BtnLogin_Click(object sender, EventArgs e)
        {
            lblMessage.CssClass = "msg msg-error";

            string login = txtLogin.Text.Trim();
            string password = txtPassword.Text;

            if (login == string.Empty || password == string.Empty)
            {
                lblMessage.Text = "Please, write a login/password.";
                return;
            }

            password = Util.Hash.GeneratePasswordHash(password);
            DataTable dtUser = new BLL.User(strConnString).AuthenticateUser(login, password);

            if (dtUser == null || dtUser.Rows.Count == 0)
            {
                lblMessage.Text = "Login/password incorrect, try again.";
                return;
            }

            global::WebPoliMusicV2.User user = new global::WebPoliMusicV2.User();
            user.ID = Convert.ToInt32(dtUser.Rows[0]["ID_USER"]);
            user.UserName = dtUser.Rows[0]["USERNAME"].ToString();
            user.Email = dtUser.Rows[0]["EMAIL"].ToString();
            user.Birthday = dtUser.Rows[0]["BIRTHDAY"].ToString();
            user.UserType = Convert.ToInt32(dtUser.Rows[0]["USER_TYPE"]);
            user.Photo = dtUser.Rows[0]["USER_PHOTO"].ToString();

            if (user.UserType != Util.Constants.ID_USER_NORMAL && user.UserType != Util.Constants.ID_USER_ADMIN)
            {
                lblMessage.Text = "Login/password incorrect, try again.";
                return;
            }

            // The authenticated user is stored in session: Song.aspx shows this name.
            Session[Util.Constants.USER] = user;
            FormsAuthentication.RedirectFromLoginPage(user.UserName, true);
        }

        protected void LinkButtonNewUser_Click(object sender, EventArgs e)
        {
            Response.Redirect("~/SignUp.aspx", true);
        }
    }

}
