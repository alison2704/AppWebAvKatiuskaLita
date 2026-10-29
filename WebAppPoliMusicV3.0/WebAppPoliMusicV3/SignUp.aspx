<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SignUp.aspx.cs" Inherits="WebAppPoliMusicV3.SignUp" %>

<!DOCTYPE html>

<html lang="es">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Registro - PoliMusic</title>
    <link href="Content/polimusic.css" rel="stylesheet" />
</head>
<body>
    <form id="formLogin" runat="server">
        <main class="auth-page">
            <section class="auth-card auth-card-wide">
                <a class="auth-brand" href="Login.aspx"><span class="pm-brand-dot"></span>PoliMusic</a>

                <p class="pm-eyebrow">Registro</p>
                <h1 class="auth-title">Crea tu cuenta</h1>
                <p class="auth-sub">Los usuarios nuevos se registran con el tipo de usuario normal.</p>

                <label class="auth-field">
                    <span>Usuario *</span>
                    <asp:TextBox ID="txtUserName" runat="server" MaxLength="50" placeholder="nombre.apellido"></asp:TextBox>
                </label>

                <label class="auth-field">
                    <span>Email *</span>
                    <asp:TextBox ID="txtEmail" runat="server" MaxLength="50" placeholder="usuario@epn.edu.ec"></asp:TextBox>
                </label>

                <label class="auth-field">
                    <span>Contraseña *</span>
                    <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" MaxLength="50"></asp:TextBox>
                </label>

                <label class="auth-field">
                    <span>Confirmar contraseña *</span>
                    <asp:TextBox ID="txtConfirmPassword" runat="server" TextMode="Password" MaxLength="50"></asp:TextBox>
                </label>

                <label class="auth-field">
                    <span>Fecha de nacimiento (dd/MM/yyyy)</span>
                    <asp:TextBox ID="txtBirthDate" runat="server" MaxLength="10" placeholder="15/12/2000"></asp:TextBox>
                </label>

                <label class="auth-field">
                    <span>Foto (opcional, JPG o PNG)</span>
                    <asp:FileUpload ID="fupPhoto" runat="server" />
                </label>

                <asp:Button ID="btnSumbit" runat="server" Text="Registrarme" CssClass="auth-submit" OnClick="btnSumbit_Click" />

                <asp:Panel ID="frmConfirmation" runat="server">
                    <asp:Label ID="lblMessage" runat="server" CssClass="pm-msg"></asp:Label>
                </asp:Panel>

                <div class="auth-foot">
                    ¿Ya tienes cuenta?
                    <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl="~/Login.aspx">Inicia sesión</asp:HyperLink>
                </div>
            </section>
        </main>
    </form>
</body>
</html>
