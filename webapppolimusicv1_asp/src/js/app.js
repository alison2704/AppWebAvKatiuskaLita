/* =====================================================================
   PoliMusic - app.js
   - Reproductor persistente (vive en el shell / index.asp)
   - Puente entre el iframe de contenido y el reproductor
   - Utilidades de UI: toasts, confirmaciones, tema, flash
   ===================================================================== */
(function () {
  "use strict";

  var IS_FRAME = (window.parent !== window);

  // Base de la aplicacion deducida de la ubicacion de este script
  var SCRIPT_SRC = (document.currentScript && document.currentScript.src) || "";
  var APP_BASE = SCRIPT_SRC.replace(/\/js\/app\.js(\?.*)?$/, "");

  var STORE = {
    queue: "poli.queue",
    index: "poli.index",
    pos: "poli.pos",
    playing: "poli.playing",
    shuffle: "poli.shuffle",
    repeat: "poli.repeat",
    vol: "poli.vol",
    theme: "poli.theme"
  };

  /* ------------------------------------------------------------------ */
  /*  Utilidades comunes                                                */
  /* ------------------------------------------------------------------ */
  function $(sel, root) { return (root || document).querySelector(sel); }
  function $$(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }

  function store(key, val) {
    try {
      if (val === undefined) {
        var v = sessionStorage.getItem(key);
        return v === null ? null : JSON.parse(v);
      }
      sessionStorage.setItem(key, JSON.stringify(val));
    } catch (e) { /* sessionStorage no disponible */ }
    return null;
  }

  function fmtTime(sec) {
    if (!isFinite(sec) || sec < 0) { sec = 0; }
    var m = Math.floor(sec / 60);
    var s = Math.floor(sec % 60);
    return m + ":" + (s < 10 ? "0" : "") + s;
  }

  /* ------------------------------- Toasts --------------------------- */
  function toast(msg, isError) {
    var host = $("#toastHost");
    if (!host) {
      host = document.createElement("div");
      host.id = "toastHost";
      document.body.appendChild(host);
    }
    var el = document.createElement("div");
    el.className = "toast" + (isError ? " err" : "");
    el.textContent = msg;
    host.appendChild(el);
    setTimeout(function () {
      el.style.transition = "opacity .25s, transform .25s";
      el.style.opacity = "0";
      el.style.transform = "translateX(20px)";
      setTimeout(function () { if (el.parentNode) { el.parentNode.removeChild(el); } }, 260);
    }, 3200);
  }

  /* --------------------------- Modal confirmacion -------------------- */
  function confirmDialog(message, onOk, okLabel) {
    var back = document.createElement("div");
    back.className = "modal-back";
    back.innerHTML =
      '<div class="modal" role="dialog" aria-modal="true">' +
      '  <h3>Confirmar accion</h3>' +
      '  <p></p>' +
      '  <div class="modal-actions">' +
      '    <button type="button" class="btn btn-ghost" data-x="no">Cancelar</button>' +
      '    <button type="button" class="btn btn-danger" data-x="si"></button>' +
      '  </div>' +
      '</div>';
    $("p", back).textContent = message;
    $('[data-x="si"]', back).textContent = okLabel || "Eliminar";
    document.body.appendChild(back);

    function close() { if (back.parentNode) { back.parentNode.removeChild(back); } }
    $('[data-x="no"]', back).addEventListener("click", close);
    $('[data-x="si"]', back).addEventListener("click", function () { close(); onOk(); });
    back.addEventListener("click", function (e) { if (e.target === back) { close(); } });
    document.addEventListener("keydown", function esc(e) {
      if (e.key === "Escape") { close(); document.removeEventListener("keydown", esc); }
    });
  }

  /* ------------------------------- Tema ------------------------------ */
  function applyTheme(t) {
    document.documentElement.setAttribute("data-theme", t);
    store(STORE.theme, t);
    try {
      var frame = document.getElementById("appFrame");
      if (frame && frame.contentDocument) {
        frame.contentDocument.documentElement.setAttribute("data-theme", t);
      }
    } catch (e) { /* ignorar */ }
  }

  function initTheme() {
    var t = store(STORE.theme) || "dark";
    document.documentElement.setAttribute("data-theme", t);
    var btn = $("#themeToggle");
    if (btn) {
      btn.textContent = (t === "dark") ? "\u263C" : "\u263D";
      btn.addEventListener("click", function () {
        t = (t === "dark") ? "light" : "dark";
        applyTheme(t);
        btn.textContent = (t === "dark") ? "\u263C" : "\u263D";
      });
    }
  }

  /* -------------------------- Helpers de UI -------------------------- */
  function initUi() {
    // Cierre automatico de los mensajes flash
    $$(".flash").forEach(function (f) {
      setTimeout(function () {
        f.style.transition = "opacity .4s, transform .4s";
        f.style.opacity = "0";
        f.style.transform = "translateY(-8px)";
        setTimeout(function () { if (f.parentNode) { f.parentNode.removeChild(f); } }, 420);
      }, 5200);
    });

    // Confirmacion de borrado
    $$("form[data-confirm]").forEach(function (form) {
      form.addEventListener("submit", function (e) {
        if (form.getAttribute("data-ok") === "1") { return; }
        e.preventDefault();
        confirmDialog(form.getAttribute("data-confirm"), function () {
          form.setAttribute("data-ok", "1");
          form.submit();
        }, form.getAttribute("data-ok-label") || "Eliminar");
      });
    });

    // Vista previa de imagenes antes de subir
    $$("input[type=file][data-preview]").forEach(function (inp) {
      inp.addEventListener("change", function () {
        var target = document.getElementById(inp.getAttribute("data-preview"));
        if (target && inp.files && inp.files[0]) {
          target.src = URL.createObjectURL(inp.files[0]);
        }
      });
    });

    // Botones que enlazan a otra pagina (dentro del iframe o arriba)
    $$("[data-href]").forEach(function (el) {
      el.addEventListener("click", function () {
        var url = el.getAttribute("data-href");
        if (el.getAttribute("data-target") === "top") { window.top.location.href = url; }
        else { window.location.href = url; }
      });
    });
  }

  /* ================================================================== */
  /*  MODO IFRAME: puente hacia el reproductor del shell                */
  /* ================================================================== */
  function initFrame() {
    var page = $(".page");
    var activeKey = page ? page.getAttribute("data-active") : "";

    function parentPlayer() {
      try {
        if (window.parent && window.parent.PoliPlayer) { return window.parent.PoliPlayer; }
      } catch (e) { /* cross-origin */ }
      return null;
    }

    // Informar al shell de la seccion activa
    try {
      window.parent.postMessage({ type: "poli:active", key: activeKey }, "*");
    } catch (e) { /* ignorar */ }

    // Recolectar la cola a partir de los elementos [data-track] de esta pagina
    function parseTrack(el) {
      var raw = el.getAttribute("data-track");
      if (!raw) { return null; }
      try {
        var t = JSON.parse(raw);
        return (t && t.url) ? t : null;
      } catch (e) { return null; }
    }

    // Click en cualquier fila/tarjeta reproducible
    document.addEventListener("click", function (e) {
      if (!e.target.closest) { return; }
      var trigger = e.target.closest("[data-track]");
      if (!trigger) { return; }
      // Si el clic fue sobre un control real (enlace, boton o campo) se respeta
      if (e.target.closest("a, button, input, select, textarea, label")) { return; }
      e.preventDefault();

      var list = [];
      var idx = 0;
      $$("[data-track]").forEach(function (el) {
        var t = parseTrack(el);
        if (!t) { return; }
        if (el === trigger) { idx = list.length; }
        list.push(t);
      });
      if (list.length === 0) { return; }

      var pp = parentPlayer();
      if (!pp) { toast("El reproductor no esta disponible.", true); return; }
      pp.setQueue(list, idx, activeKey);
    });

    // Boton "reproducir todo"
    document.addEventListener("click", function (e) {
      if (!e.target.closest) { return; }
      var btn = e.target.closest("[data-play-all]");
      if (!btn) { return; }
      e.preventDefault();
      var list = [];
      $$("[data-track]").forEach(function (el) {
        var t = parseTrack(el);
        if (t) { list.push(t); }
      });
      if (list.length === 0) { toast("No hay canciones para reproducir.", true); return; }
      var pp = parentPlayer();
      if (!pp) { toast("El reproductor no esta disponible.", true); return; }
      pp.setQueue(list, 0, activeKey);
    });

    // Resaltar la pista que esta sonando
    function markPlaying() {
      var pp = parentPlayer();
      var cur = pp && pp.currentTrack ? pp.currentTrack() : null;
      $$("[data-track]").forEach(function (el) {
        var row = el.closest(".list-row") || el.closest(".card");
        if (!row) { return; }
        var raw = el.getAttribute("data-track");
        var isCur = false;
        try { isCur = cur && JSON.parse(raw).url === cur.url; } catch (er) { isCur = false; }
        row.classList.toggle("playing", !!isCur);
        var num = row.querySelector(".lr-num");
        if (num) {
          var hasEq = num.querySelector(".eq");
          if (isCur && pp && pp.isPlaying()) {
            if (!hasEq) {
              var eq = document.createElement("span");
              eq.className = "eq";
              eq.innerHTML = "<i></i><i></i><i></i>";
              num.appendChild(eq);
            }
          } else if (hasEq) {
            hasEq.parentNode.removeChild(hasEq);
          }
        }
      });
    }

    try {
      window.parent.addEventListener("poli:player", markPlaying);
    } catch (e) { /* ignorar */ }
    window.addEventListener("load", markPlaying);

    // Si por alguna razon se renderiza una pagina autonoma dentro del frame
    // (por ejemplo al expirar la sesion) se saca a la ventana principal.
    if (document.body && document.body.classList.contains("standalone")) {
      try { window.top.location.href = window.location.href; } catch (e) { /* ignorar */ }
    }
  }

  /* ================================================================== */
  /*  MODO SHELL: reproductor persistente                               */
  /* ================================================================== */
  function initPlayer() {
    var host = $("#player");
    if (!host) { return; }

    var audio = $("#plAudio");
    var elCover = $("#plCover");
    var elTitle = $("#plTitle");
    var elArtist = $("#plArtist");
    var elPlay = $("#plPlay");
    var elPrev = $("#plPrev");
    var elNext = $("#plNext");
    var elShuffle = $("#plShuffle");
    var elRepeat = $("#plRepeat");
    var elSeek = $("#plSeek");
    var elCur = $("#plCur");
    var elDur = $("#plDur");
    var elVol = $("#plVol");
    var elMute = $("#plMute");
    var elHeart = $("#plHeart");
    var elCount = $("#plCount");
    var frame = $("#appFrame");

    var queue = store(STORE.queue) || [];
    var index = store(STORE.index) || 0;
    var shuffle = !!store(STORE.shuffle);
    var repeat = store(STORE.repeat) || "off";   // off | all | one
    var volume = (store(STORE.vol) === null) ? 0.85 : store(STORE.vol);
    var seeking = false;
    var lastVolume = volume > 0 ? volume : 0.85;

    var ICON_PLAY = '<svg class="ico" viewBox="0 0 24 24"><path d="M7 4.5l13 7.5-13 7.5z" fill="currentColor"/></svg>';
    var ICON_PAUSE = '<svg class="ico" viewBox="0 0 24 24"><path d="M8 5h3v14H8zM13 5h3v14h-3z" fill="currentColor"/></svg>';
    var ICON_VOL = '<svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M4 9.5h3.5L12 5.5v13L7.5 14.5H4z"/><path d="M16 9a4.5 4.5 0 0 1 0 6"/><path d="M18.8 6.4a8 8 0 0 1 0 11.2"/></svg>';
    var ICON_MUTE = '<svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M4 9.5h3.5L12 5.5v13L7.5 14.5H4z"/><path d="M16.5 9.5l5 5M21.5 9.5l-5 5"/></svg>';

    function persist() {
      store(STORE.queue, queue);
      store(STORE.index, index);
      store(STORE.shuffle, shuffle);
      store(STORE.repeat, repeat);
      store(STORE.vol, volume);
    }

    function emit() {
      try { window.dispatchEvent(new CustomEvent("poli:player")); } catch (e) { /* ignorar */ }
      if (frame && frame.contentWindow) {
        try { frame.contentWindow.dispatchEvent(new Event("poli:player")); } catch (e) { /* ignorar */ }
      }
    }

    function current() {
      if (queue.length === 0) { return null; }
      if (index < 0 || index >= queue.length) { index = 0; }
      return queue[index];
    }

    function render() {
      var t = current();
      if (t) {
        elTitle.textContent = t.title || "Sin titulo";
        elArtist.textContent = t.artist || "Artista desconocido";
        elTitle.setAttribute("href", t.href || "javascript:void(0)");
        if (t.cover) {
          elCover.innerHTML = '<img src="' + t.cover + '" alt="">';
        } else {
          elCover.innerHTML = '<svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"><circle cx="7" cy="18" r="3"/><circle cx="18" cy="16" r="3"/><path d="M10 18V6l11-2v12"/></svg>';
        }
        document.title = (t.title ? t.title + " \u00B7 " : "") + "PoliMusic";
      } else {
        elTitle.textContent = "\u2014";
        elArtist.textContent = "Selecciona una cancion";
        elCover.innerHTML = '<svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"><circle cx="7" cy="18" r="3"/><circle cx="18" cy="16" r="3"/><path d="M10 18V6l11-2v12"/></svg>';
      }
      elPlay.innerHTML = audio.paused ? ICON_PLAY : ICON_PAUSE;
      elCount.textContent = queue.length + (queue.length === 1 ? " cancion" : " canciones");
      elShuffle.classList.toggle("on", shuffle);
      elRepeat.classList.toggle("on", repeat !== "off");
      elRepeat.title = (repeat === "one") ? "Repetir una" : (repeat === "all" ? "Repetir todo" : "Repetir");
      elMute.innerHTML = (volume > 0) ? ICON_VOL : ICON_MUTE;
    }

    function countPlay(id) {
      if (!APP_BASE || !id) { return; }
      try {
        fetch(APP_BASE + "/api-play.asp?id=" + encodeURIComponent(id), { credentials: "same-origin" })
          .catch(function () { /* ignorar */ });
      } catch (e) { /* ignorar */ }
    }

    function load(t, autoplay, position) {
      if (!t) { return; }

      // Cancion sin archivo de audio disponible en el servidor
      if (!t.url) {
        audio.pause();
        audio.removeAttribute("src");
        try { audio.load(); } catch (e) { /* ignorar */ }
        render();
        toast('El archivo de audio de "' + (t.title || "esta cancion") +
              '" no esta disponible en el servidor.', true);
        return;
      }

      audio.src = t.url;
      audio.load();
      if (autoplay) { countPlay(t.id); }
      if (position && position > 0) {
        audio.addEventListener("loadedmetadata", function once() {
          audio.removeEventListener("loadedmetadata", once);
          try { audio.currentTime = position; } catch (e) { /* ignorar */ }
        });
      }
      if (autoplay) {
        var p = audio.play();
        if (p && p.catch) { p.catch(function () { render(); }); }
      }
      render();
    }

    function playAt(i, autoplay) {
      index = i;
      var t = current();
      persist();
      store(STORE.playing, !!autoplay);
      load(t, autoplay !== false, 0);
      emit();
    }

    function nextIndex(step) {
      if (queue.length === 0) { return -1; }
      if (shuffle) {
        if (queue.length === 1) { return 0; }
        var r = index;
        while (r === index) { r = Math.floor(Math.random() * queue.length); }
        return r;
      }
      var n = index + step;
      if (n >= queue.length) { n = 0; }
      if (n < 0) { n = queue.length - 1; }
      return n;
    }

    /* ------------------------------ API publica --------------------- */
    var api = {
      setQueue: function (tracks, i, context) {
        queue = tracks || [];
        index = i || 0;
        persist();
        playAt(index, true);
        toast("Reproduciendo: " + (current() ? current().title : ""));
      },
      play: function () { if (current()) { audio.play(); } },
      pause: function () { audio.pause(); },
      toggle: function () {
        if (!current()) { return; }
        if (audio.paused) { audio.play(); } else { audio.pause(); }
      },
      next: function () { var n = nextIndex(1); if (n >= 0) { playAt(n, true); } },
      prev: function () {
        if (audio.currentTime > 4) { audio.currentTime = 0; return; }
        var n = nextIndex(-1);
        if (n >= 0) { playAt(n, true); }
      },
      currentTrack: function () { return current(); },
      isPlaying: function () { return !audio.paused; },
      getQueue: function () { return queue.slice(); }
    };
    window.PoliPlayer = api;

    /* ------------------------------ Eventos ------------------------- */
    elPlay.addEventListener("click", function () { api.toggle(); });
    elNext.addEventListener("click", function () { api.next(); });
    elPrev.addEventListener("click", function () { api.prev(); });

    elShuffle.addEventListener("click", function () {
      shuffle = !shuffle;
      persist(); render(); emit();
      toast(shuffle ? "Modo aleatorio activado" : "Modo aleatorio desactivado");
    });

    elRepeat.addEventListener("click", function () {
      repeat = (repeat === "off") ? "all" : (repeat === "all" ? "one" : "off");
      persist(); render();
      toast(repeat === "off" ? "Repeticion desactivada" : (repeat === "one" ? "Repetir una cancion" : "Repetir toda la lista"));
    });

    elSeek.addEventListener("input", function () {
      seeking = true;
      if (audio.duration) { elCur.textContent = fmtTime(audio.duration * elSeek.value / 1000); }
    });
    elSeek.addEventListener("change", function () {
      if (audio.duration) { audio.currentTime = audio.duration * elSeek.value / 1000; }
      seeking = false;
    });

    elVol.addEventListener("input", function () {
      volume = elVol.value / 100;
      audio.volume = volume;
      if (volume > 0) { lastVolume = volume; }
      persist(); render();
    });

    elMute.addEventListener("click", function () {
      if (volume > 0) { lastVolume = volume; volume = 0; } else { volume = lastVolume || 0.85; }
      audio.volume = volume;
      elVol.value = Math.round(volume * 100);
      persist(); render();
    });

    elHeart.addEventListener("click", function () {
      elHeart.classList.toggle("on");
      toast(elHeart.classList.contains("on") ? "Agregado a favoritos" : "Quitado de favoritos");
    });

    audio.addEventListener("play", function () { store(STORE.playing, true); render(); emit(); });
    audio.addEventListener("pause", function () { store(STORE.playing, false); render(); emit(); });

    audio.addEventListener("timeupdate", function () {
      if (!seeking && audio.duration) {
        elSeek.value = Math.round(audio.currentTime / audio.duration * 1000);
      }
      elCur.textContent = fmtTime(audio.currentTime);
      store(STORE.pos, audio.currentTime);
    });

    audio.addEventListener("loadedmetadata", function () {
      elDur.textContent = fmtTime(audio.duration);
      render();
    });

    audio.addEventListener("ended", function () {
      if (repeat === "one") { audio.currentTime = 0; audio.play(); return; }
      var n = nextIndex(1);
      if (!shuffle && repeat === "off" && index === queue.length - 1) {
        audio.pause();
        audio.currentTime = 0;
        render();
        return;
      }
      if (n >= 0) { playAt(n, true); }
    });

    audio.addEventListener("error", function () {
      if (audio.src) { toast("No se pudo reproducir el archivo de audio.", true); }
      render();
    });

    /* ------------------- Comunicacion con el iframe ------------------ */
    window.addEventListener("message", function (e) {
      var d = e.data;
      if (!d || d.type !== "poli:active") { return; }
      $$("#mainNav .nav-item").forEach(function (a) {
        a.classList.toggle("active", a.getAttribute("data-key") === d.key);
      });
    });

    // Si el iframe navega por su cuenta hay que volver a avisar del estado
    if (frame) {
      frame.addEventListener("load", function () { emit(); });
    }

    /* --------------------------- Restauracion ----------------------- */
    audio.volume = volume;
    elVol.value = Math.round(volume * 100);
    if (queue.length > 0) {
      var pos = store(STORE.pos) || 0;
      var wasPlaying = !!store(STORE.playing);
      load(current(), wasPlaying, pos);
    }
    render();
    emit();

    // Guarda la posicion al cerrar para poder reanudar
    window.addEventListener("beforeunload", function () {
      persist();
      store(STORE.pos, audio.currentTime);
    });
  }

  /* ================================================================== */
  /*  Navegacion del shell                                              */
  /* ================================================================== */
  window.frameGo = function (delta) {
    var frame = document.getElementById("appFrame");
    if (frame && frame.contentWindow) {
      try { frame.contentWindow.history.go(delta); } catch (e) { /* ignorar */ }
    }
  };

  /* ------------------------------- Arranque -------------------------- */
  function boot() {
    initTheme();
    initUi();
    if (IS_FRAME) { initFrame(); } else { initPlayer(); }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }

  window.PoliUI = { toast: toast, confirm: confirmDialog };
})();
