<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="WebPoliMusicV2.Login" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Sign in - PoliMusic</title>
    <link href="<%= ResolveUrl("~/Content/site.css") %>" rel="stylesheet" type="text/css" />
</head>
<body class="auth-page">
    <form id="formLogin" runat="server" class="auth-card">
        <div class="auth-brand"><span class="brand-mark">&#9835;</span> PoliMusic</div>

        <h1 class="auth-title">Sign in</h1>
        <p class="auth-subtitle">Enter your credentials to open your music library.</p>

        <div class="field">
            <label>Username</label>
            <asp:TextBox ID="txtLogin" runat="server" CssClass="input" placeholder="your.username"></asp:TextBox>
        </div>

        <div class="field">
            <label>Password</label>
            <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="input" placeholder="Your password"></asp:TextBox>
        </div>

        <asp:Button ID="btnLogin" runat="server" Text="Sign in" CssClass="btn btn-primary btn-block" OnClick="BtnLogin_Click" />

        <asp:Label ID="lblMessage" runat="server" CssClass="msg msg-error"></asp:Label>

        <div class="auth-footer">
            Don't have an account yet?
            <asp:LinkButton ID="LinkButtonNewUser" runat="server" CssClass="link" OnClick="LinkButtonNewUser_Click">Enroll new user</asp:LinkButton>
        </div>
    </form>
</body>
</html>
