<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebPoliMusicV2.Song" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Song list - PoliMusic</title>
    <link href="<%= ResolveUrl("~/Content/site.css") %>" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="form1" runat="server">
        <header class="app-bar">
            <div class="brand"><span class="brand-mark">&#9835;</span> PoliMusic</div>
            <div class="app-bar-right">
                <asp:HyperLink ID="lnkLogout" runat="server" NavigateUrl="~/Logout.aspx" CssClass="btn btn-logout">Logout</asp:HyperLink>
            </div>
        </header>

        <div class="content">
            <section class="card">
                <div class="card-head">
                    <asp:Image ID="imgUserPhoto" runat="server" CssClass="avatar-lg" />
                    <div>
                        <h1 class="welcome">Welcome, <asp:Literal ID="litUserName" runat="server"></asp:Literal></h1>
                        <p class="welcome-sub">Song list:</p>
                    </div>
                </div>

                <asp:Repeater ID="rptSongs" runat="server">
                    <HeaderTemplate>
                        <div class="table-wrap">
                            <table class="song-table">
                                <thead>
                                    <tr>
                                        <th class="col-id">ID Canción</th>
                                        <th class="col-name">Nombre</th>
                                        <th class="col-path">Ruta</th>
                                        <th class="col-plays ta-center">Reproducciones</th>
                                        <th class="col-play">Reproducir</th>
                                    </tr>
                                </thead>
                                <tbody>
                    </HeaderTemplate>
                    <ItemTemplate>
                                        <tr>
                                            <td class="col-id"><%# Eval("ID_SONG") %></td>
                                            <td class="col-name"><%# Eval("SONG_NAME") %></td>
                                            <td class="col-path"><span class="path"><%# GetSongPath(Eval("SONG_PATH")) %></span></td>
                                            <td class="col-plays ta-center"><span class="badge"><%# Eval("PLAYS") %></span></td>
                                            <td class="col-play player">
                                                <audio controls="controls" preload="metadata" src='<%# GetSongUrl(Eval("SONG_PATH")) %>'></audio>
                                            </td>
                                        </tr>
                    </ItemTemplate>
                    <FooterTemplate>
                                </tbody>
                            </table>
                        </div>
                    </FooterTemplate>
                </asp:Repeater>

                <asp:Label ID="lblMessage" runat="server" CssClass="msg msg-error card-msg"></asp:Label>
            </section>
        </div>
    </form>
</body>
</html>
