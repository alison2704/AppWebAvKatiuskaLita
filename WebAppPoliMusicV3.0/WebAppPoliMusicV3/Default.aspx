<%@ Page Title="Inicio" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="WebAppPoliMusicV3._Default" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .home-hero {
            padding: 34px 0 26px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.12);
        }

        .home-cta {
            display: inline-flex;
            margin-top: 26px;
        }

        .home-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 16px;
            margin-top: 30px;
        }

        .home-card {
            padding: 20px 22px;
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: 12px;
            background-color: rgba(255, 255, 255, 0.06);
        }

        .home-card h2 {
            margin: 0 0 8px;
            font-size: 1rem;
            font-weight: 700;
            color: #FFFFFF;
        }

        .home-card p {
            margin: 0;
            font-size: 0.85rem;
            line-height: 1.55;
            color: rgba(255, 255, 255, 0.62);
        }

        .home-card code {
            font-family: Consolas, "Courier New", monospace;
            font-size: 0.78rem;
            color: #E11D2E;
        }
    </style>
</asp:Content>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <section class="home-hero">
        <p class="pm-eyebrow">Inicio</p>
        <h1 class="pm-title">Hola de nuevo</h1>
        <p class="pm-subtitle">Tu biblioteca musical de PoliMusic, ahora con arquitectura N-tier.</p>
        <a class="pm-btn pm-btn-primary home-cta" href="Song.aspx">Escuchar canciones</a>
    </section>

    <div class="home-grid">
        <section class="home-card">
            <h2>Canciones</h2>
            <p>Lista las canciones de la base de datos, reproduce el audio y lleva el contador de reproducciones.</p>
        </section>
        <section class="home-card">
            <h2>Administración</h2>
            <p>Con una cuenta de tipo administrador puedes registrar, editar y eliminar canciones.</p>
        </section>
        <section class="home-card">
            <h2>Arquitectura N-tier</h2>
            <p>
                La página web solo conoce la capa de negocio: <code>EntityLayer</code> &rarr;
                <code>DAL</code> &rarr; <code>BLL</code> &rarr; <code>WebAppPoliMusicV3</code>.
            </p>
        </section>
    </div>

</asp:Content>
