<%@ Page Title="Canciones" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV3.Song" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* Ajustes propios de la pantalla de canciones (misma paleta de 3 colores) */
        .pm-hero {
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            justify-content: space-between;
            gap: 18px;
            padding-bottom: 22px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.12);
        }

        .pm-hero-stats {
            display: flex;
            gap: 26px;
        }

        .pm-stat-value {
            font-size: 1.5rem;
            font-weight: 800;
            line-height: 1;
            color: #FFFFFF;
        }

        .pm-stat-label {
            font-size: 0.68rem;
            letter-spacing: .12em;
            text-transform: uppercase;
            color: rgba(255, 255, 255, 0.62);
        }

        .pm-cell-actions {
            text-align: right;
            white-space: nowrap;
        }

        .pm-badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 999px;
            border: 1px solid rgba(255, 255, 255, 0.12);
            font-size: 0.66rem;
            letter-spacing: .1em;
            text-transform: uppercase;
            color: rgba(255, 255, 255, 0.62);
        }
    </style>
</asp:Content>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <section class="pm-hero">
        <div>
            <p class="pm-eyebrow">Tu biblioteca</p>
            <h1 class="pm-title">Bienvenido, <asp:Label ID="lblWelcome" runat="server" /></h1>
            <p class="pm-subtitle">
                Lista de canciones de PoliMusic &middot;
                <asp:Label ID="lblTotalSongs" runat="server" Text="0" /> canciones &middot;
                <asp:Label ID="lblTotalPlays" runat="server" Text="0" /> reproducciones
            </p>
        </div>
        <div class="pm-hero-stats">
            <div>
                <div class="pm-stat-value"><asp:Label ID="lblStatSongs" runat="server" Text="0" /></div>
                <div class="pm-stat-label">Canciones</div>
            </div>
            <div>
                <div class="pm-stat-value"><asp:Label ID="lblStatPlays" runat="server" Text="0" /></div>
                <div class="pm-stat-label">Reproducciones</div>
            </div>
        </div>
    </section>

    <div class="pm-toolbar">
        <asp:TextBox ID="txtSearch" runat="server" CssClass="pm-search" MaxLength="50" placeholder="Buscar una canción por nombre..." />
        <asp:Button ID="btnSearch" runat="server" Text="Buscar" CssClass="pm-btn pm-btn-primary" OnClick="BtnSearch_Click" />
        <asp:Button ID="btnClear" runat="server" Text="Limpiar" CssClass="pm-btn pm-btn-ghost" OnClick="BtnClear_Click" CausesValidation="false" />
        <asp:Button ID="btnNew" runat="server" Text="+ Nueva canción" CssClass="pm-btn pm-btn-primary" OnClick="BtnNew_Click" Visible="false" CausesValidation="false" />
    </div>

    <asp:Label ID="lblMessage" runat="server" CssClass="pm-msg" />

    <%-- Formulario de alta / edición: solo visible para el administrador --%>
    <asp:Panel ID="pnlAdmin" runat="server" CssClass="pm-panel" Visible="false">
        <h2><asp:Label ID="lblFormTitle" runat="server" Text="Nueva canción" /> <span class="pm-badge">Administrador</span></h2>

        <asp:HiddenField ID="hdnSongId" runat="server" Value="0" />

        <div class="pm-grid-2">
            <label class="pm-field">
                <span>Nombre de la canción</span>
                <asp:TextBox ID="txtSongName" runat="server" MaxLength="50" placeholder="Ej. Adventure" />
            </label>
            <label class="pm-field">
                <span>Ruta del archivo</span>
                <asp:TextBox ID="txtSongPath" runat="server" MaxLength="255" placeholder="~/songFiles/archivo.mp3" />
            </label>
        </div>

        <label class="pm-field">
            <span>Archivo MP3 (opcional: si lo sube, la ruta se genera sola)</span>
            <asp:FileUpload ID="fupSongFile" runat="server" CssClass="pm-file" />
        </label>

        <div class="pm-actions">
            <asp:Button ID="btnSave" runat="server" Text="Guardar" CssClass="pm-btn pm-btn-primary" OnClick="BtnSave_Click" />
            <asp:Button ID="btnCancel" runat="server" Text="Cancelar" CssClass="pm-btn pm-btn-ghost" OnClick="BtnCancel_Click" CausesValidation="false" />
        </div>
    </asp:Panel>

    <%-- Listado de canciones --%>
    <div class="pm-table-wrap">
        <table class="pm-table">
            <thead>
                <tr>
                    <th class="pm-index">ID</th>
                    <th>Nombre</th>
                    <th>Ruta</th>
                    <th>Reproducciones</th>
                    <th>Reproducir</th>
                    <th class="pm-cell-actions">Acciones</th>
                </tr>
            </thead>
            <tbody>
                <asp:Repeater ID="rptSongs" runat="server" OnItemCommand="RptSongs_ItemCommand">
                    <ItemTemplate>
                        <tr>
                            <td class="pm-index"><%# Eval("ID_SONG") %></td>
                            <td>
                                <div class="pm-cell-song">
                                    <div class="pm-cover"><%# Initial(Eval("SONG_NAME")) %></div>
                                    <div>
                                        <div class="pm-song-name"><%#: Eval("SONG_NAME") %></div>
                                        <div class="pm-song-sub">PoliMusic &middot; MP3</div>
                                    </div>
                                </div>
                            </td>
                            <td><span class="pm-path"><%#: Eval("SONG_PATH") %></span></td>
                            <td class="pm-plays" data-plays-for="<%# Eval("ID_SONG") %>"><%# Eval("PLAYS") %></td>
                            <td>
                                <button type="button" class="pm-play js-play"
                                    data-id="<%# Eval("ID_SONG") %>"
                                    data-name="<%#: Eval("SONG_NAME") %>"
                                    data-src="<%# ResolveSongUrl(Eval("SONG_PATH")) %>"
                                    title="Reproducir"><span aria-hidden="true">&#9654;</span></button>
                            </td>
                            <td class="pm-cell-actions">
                                <asp:LinkButton runat="server" CssClass="pm-mini" CommandName="edit"
                                    CommandArgument='<%# Eval("ID_SONG") %>' Visible='<%# IsAdmin %>'>Editar</asp:LinkButton>
                                <asp:LinkButton runat="server" CssClass="pm-mini pm-mini-danger" CommandName="delete"
                                    CommandArgument='<%# Eval("ID_SONG") %>' Visible='<%# IsAdmin %>'
                                    OnClientClick="return confirm('¿Eliminar esta canción?');">Eliminar</asp:LinkButton>
                            </td>
                        </tr>
                    </ItemTemplate>
                </asp:Repeater>
            </tbody>
        </table>

        <asp:Panel ID="pnlEmpty" runat="server" CssClass="pm-empty" Visible="false">
            No hay canciones que coincidan con la búsqueda.
        </asp:Panel>
    </div>

    <%-- Reproductor fijo (estilo Spotify) --%>
    <div class="pm-player">
        <div class="pm-now">
            <div class="pm-now-cover">&#9835;</div>
            <div>
                <div class="pm-now-name" id="pm-name">Selecciona una canción</div>
                <div class="pm-now-sub">PoliMusic</div>
            </div>
        </div>

        <div class="pm-controls">
            <button type="button" class="pm-ctrl" id="pm-prev" title="Anterior">&#9198;</button>
            <button type="button" class="pm-ctrl pm-ctrl-main" id="pm-toggle" title="Reproducir / Pausar">&#9654;</button>
            <button type="button" class="pm-ctrl" id="pm-next" title="Siguiente">&#9197;</button>
        </div>

        <div class="pm-progress">
            <span id="pm-cur">0:00</span>
            <input type="range" id="pm-seek" min="0" max="1000" value="0" step="1" />
            <span id="pm-dur">0:00</span>
        </div>
    </div>

    <audio id="pm-audio" preload="metadata"></audio>

    <script type="text/javascript">
        (function () {
            var audio = document.getElementById('pm-audio');
            if (!audio) { return; }

            var nameEl = document.getElementById('pm-name');
            var toggle = document.getElementById('pm-toggle');
            var prevBtn = document.getElementById('pm-prev');
            var nextBtn = document.getElementById('pm-next');
            var seek = document.getElementById('pm-seek');
            var curEl = document.getElementById('pm-cur');
            var durEl = document.getElementById('pm-dur');
            var current = -1;
            var seeking = false;

            function tracks() { return window.PM_TRACKS || []; }

            function formatTime(value) {
                if (!isFinite(value) || value < 0) { return '0:00'; }
                var minutes = Math.floor(value / 60);
                var seconds = Math.floor(value % 60);
                return minutes + ':' + (seconds < 10 ? '0' : '') + seconds;
            }

            function setToggleState() {
                toggle.innerHTML = audio.paused ? '&#9654;' : '&#10073;&#10073;';
            }

            function loadTrack(index, autoplay) {
                var list = tracks();
                if (index < 0 || index >= list.length) { return; }
                current = index;
                audio.src = list[index].url;
                nameEl.textContent = list[index].name;
                if (autoplay) {
                    var promise = audio.play();
                    if (promise && promise.catch) { promise.catch(function () { setToggleState(); }); }
                }
            }

            function playById(id) {
                var list = tracks();
                for (var i = 0; i < list.length; i++) {
                    if (list[i].id === id) { loadTrack(i, true); return; }
                }
            }

            function countPlay(id) {
                var url = 'PlayCounter.ashx?id=' + encodeURIComponent(id);
                if (window.fetch) {
                    window.fetch(url, { credentials: 'same-origin' }).then(function (response) {
                        return response.text();
                    }).then(function (text) {
                        var cell = document.querySelector('[data-plays-for="' + id + '"]');
                        if (cell && text) { cell.textContent = text; }
                    }).catch(function () { });
                } else {
                    var xhr = new XMLHttpRequest();
                    xhr.open('GET', url, true);
                    xhr.onreadystatechange = function () {
                        if (xhr.readyState === 4 && xhr.status === 200) {
                            var cell = document.querySelector('[data-plays-for="' + id + '"]');
                            if (cell && xhr.responseText) { cell.textContent = xhr.responseText; }
                        }
                    };
                    xhr.send();
                }
            }

            var buttons = document.querySelectorAll('.js-play');
            for (var b = 0; b < buttons.length; b++) {
                buttons[b].addEventListener('click', function () {
                    var id = parseInt(this.getAttribute('data-id'), 10);
                    playById(id);
                    countPlay(id);
                });
            }

            toggle.addEventListener('click', function () {
                if (!audio.src) {
                    if (tracks().length > 0) { loadTrack(0, true); }
                    return;
                }
                if (audio.paused) { audio.play(); } else { audio.pause(); }
            });

            prevBtn.addEventListener('click', function () {
                var list = tracks();
                if (!list.length) { return; }
                var index = current <= 0 ? list.length - 1 : current - 1;
                loadTrack(index, true);
            });

            nextBtn.addEventListener('click', function () {
                var list = tracks();
                if (!list.length) { return; }
                var index = current >= list.length - 1 ? 0 : current + 1;
                loadTrack(index, true);
            });

            audio.addEventListener('play', setToggleState);
            audio.addEventListener('pause', setToggleState);
            audio.addEventListener('ended', function () {
                var list = tracks();
                if (list.length > 1) { loadTrack(current >= list.length - 1 ? 0 : current + 1, true); }
                else { setToggleState(); }
            });

            audio.addEventListener('loadedmetadata', function () {
                durEl.textContent = formatTime(audio.duration);
            });

            audio.addEventListener('timeupdate', function () {
                curEl.textContent = formatTime(audio.currentTime);
                if (!seeking && audio.duration > 0) {
                    seek.value = Math.round((audio.currentTime / audio.duration) * 1000);
                }
            });

            seek.addEventListener('input', function () { seeking = true; });
            seek.addEventListener('change', function () {
                if (audio.duration > 0) {
                    audio.currentTime = (parseInt(seek.value, 10) / 1000) * audio.duration;
                }
                seeking = false;
            });

            setToggleState();
        })();
    </script>

</asp:Content>
