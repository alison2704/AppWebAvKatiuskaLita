<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Logout.aspx.cs" Inherits="WebPoliMusicV2.Logout" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Logout - PoliMusic</title>
    <link href="<%= ResolveUrl("~/Content/site.css") %>" rel="stylesheet" type="text/css" />
</head>
<body class="auth-page">
    <form id="form1" runat="server">
        <div class="auth-card" style="text-align: center;">
            <div class="auth-brand" style="justify-content: center;"><span class="brand-mark">&#9835;</span> PoliMusic</div>
            <h1 class="auth-title">Signing out...</h1>
            <p class="auth-subtitle">Your session is being closed.</p>
        </div>
    </form>
</body>
</html>
