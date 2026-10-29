<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="WebAppPoliMusicV3.Login" %>
<!DOCTYPE html>

<html lang="es">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Iniciar sesión - PoliMusic</title>
    <link href="Content/polimusic.css" rel="stylesheet" />
</head>
<body>
    <form id="formLogin" runat="server">
        <main class="auth-page">
            <section class="auth-card">
                <a class="auth-brand" href="Login.aspx"><span class="pm-brand-dot"></span>PoliMusic</a>

                <p class="pm-eyebrow">Aplicaciones Web Avanzadas</p>
                <h1 class="auth-title">Inicia sesión</h1>
                <p class="auth-sub">Ingresa con una cuenta registrada en la base de datos.</p>

                <label class="auth-field">
                    <span>Usuario</span>
                    <asp:TextBox ID="txtLogin" runat="server" MaxLength="50" placeholder="usuario"></asp:TextBox>
                </label>

                <label class="auth-field">
                    <span>Contraseña</span>
                    <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" MaxLength="50" placeholder="contraseña"></asp:TextBox>
                </label>

                <asp:Button ID="btnLogin" runat="server" Text="Entrar" CssClass="auth-submit" OnClick="BtnLogin_Click" />

                <asp:Label ID="lblMessage" runat="server" CssClass="pm-msg"></asp:Label>

                <div class="auth-foot">
                    ¿No tienes cuenta?
                    <asp:LinkButton ID="LinkButtonNewUser" runat="server" OnClick="LinkButtonNewUser_Click">Regístrate</asp:LinkButton>
                </div>

                <p class="auth-hint">
                    Cuentas de prueba: <strong>userAdmin</strong>, <strong>userNormal</strong>, <strong>username1</strong><br />
                    contraseña <strong>12345678</strong>
                </p>
            </section>
        </main>
    </form>
</body>
</html>
