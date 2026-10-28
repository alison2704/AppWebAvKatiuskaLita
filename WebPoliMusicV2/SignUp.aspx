<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SignUp.aspx.cs" Inherits="WebPoliMusicV2.SignUp" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Sign up - PoliMusic</title>
    <link href="<%= ResolveUrl("~/Content/site.css") %>" rel="stylesheet" type="text/css" />
</head>
<body class="auth-page">
    <form id="formLogin" runat="server" class="auth-card auth-card-wide">
        <div class="auth-brand"><span class="brand-mark">&#9835;</span> PoliMusic</div>

        <h1 class="auth-title">Create account</h1>
        <p class="auth-subtitle">Register a new user to start using your music library.</p>

        <div class="field">
            <label>User name *</label>
            <asp:TextBox ID="txtUserName" runat="server" CssClass="input" placeholder="name.lastname"></asp:TextBox>
        </div>

        <div class="field">
            <label>Email *</label>
            <asp:TextBox ID="txtEmail" runat="server" CssClass="input" placeholder="name@epn.edu.ec"></asp:TextBox>
        </div>

        <div class="field">
            <label>Password *</label>
            <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="input"></asp:TextBox>
        </div>

        <div class="field">
            <label>Confirm password *</label>
            <asp:TextBox ID="txtConfirmPassword" runat="server" TextMode="Password" CssClass="input"></asp:TextBox>
        </div>

        <div class="field">
            <label>Birth date</label>
            <asp:TextBox ID="txtBirthDate" runat="server" CssClass="input" placeholder="dd/MM/yyyy"></asp:TextBox>
            <span class="hint">Format: dd/MM/yyyy (optional)</span>
        </div>

        <div class="field">
            <label>Photo</label>
            <asp:FileUpload ID="fupPhoto" runat="server" CssClass="input-file" />
            <span class="hint">JPG or PNG, up to 10 MB. If you skip it, a default photo is used.</span>
        </div>

        <asp:Button ID="btnSumbit" runat="server" Text="Create account" CssClass="btn btn-primary btn-block" OnClick="btnSumbit_Click" />

        <asp:Panel ID="frmConfirmation" runat="server" Visible="true">
            <asp:Label ID="lblMessage" runat="server" CssClass="msg msg-error"></asp:Label>
        </asp:Panel>

        <div class="auth-footer">
            Already registered?
            <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl="~/Login.aspx" CssClass="link">Back to Login</asp:HyperLink>
        </div>
    </form>
</body>
</html>
