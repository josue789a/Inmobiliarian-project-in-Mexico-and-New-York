; ┌─────────────────────────────────────────────────────────┐
; │  🎨 CSP ugee M708 — SCRIPT PRINCIPAL  (v25 - AHK v2)   │
; │                                                         │
; │  1. DIRECTIVAS GLOBALES                                 │
; │  2. ESTADO (objetos agrupados)                          │
; │  3. TIMERS                                              │
; │  4. HOTKEYS GLOBALES                                    │
; │  5. HOTKEYS CSP                                         │
; │     a) Selección y reselección                          │
; │     b) Deshacer / Rehacer                               │
; │     c) Herramientas (A E W Q S O V R)                   │
; │     d) Atajos con clic derecho                          │
; │     e) Modificadores de capa                            │
; │  6. CLASE BorderFrame                                   │
; │  7. FUNCIONES                                           │
; └─────────────────────────────────────────────────────────┘



; ┌───────────────────────────────────────────────────────┐
; │  1. DIRECTIVAS GLOBALES                               │
; └───────────────────────────────────────────────────────┘
#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Input")
SetWorkingDir(A_ScriptDir)
SetKeyDelay(-1, -1)
SetMouseDelay(-1)
SetDefaultMouseSpeed(0)
CoordMode("Mouse",   "Screen")
CoordMode("ToolTip", "Screen")
SetTitleMatchMode(2)



; ┌──────────────────────────────────────────────────────────┐
; │  2. ESTADO  (objetos agrupados — reemplaza ~25 globals)  │
; └──────────────────────────────────────────────────────────┘

; --- Sistema ---
sys := {
    lastModTime  : "",
    modoEscritura: false
}

; --- Stylus ---
stylus := { altActive: false }

; --- Selección / borde ---
sel := {
    estado    : 0,     ; 0=deselec, 1=reselec
    estadoAltX: false,
    estadoC   : 0
}

; --- Herramienta E (borrador) ---
E := {
    last           : 0,
    timerRunning   : 0,
    colorTransp    : false,
    procesando     : false
}

; --- Herramienta W (aerógrafo) ---
W := {
    last        : 0,
    timerRunning: 0,
    alpha       : false
}

; --- Herramienta Q / Estabilización ---
Q := {
    last            : 0,
    colorSecundario : false,
    estadoEstab     : 0
}

; --- Tecla A ---
A_state := { lastPress: 0 }

; --- Tecla S ---
S := {
    estadoCaracter: 0,
    skipNext      : false
}

; --- Tecla O ---
O := { ciclo: 0 }

; --- Numpad6 (escala de grises) ---
N6 := { estadoEscala: 0 }

; --- Historial de color ---
hist := {
    abierto: false,
    modo   : 1       ; 1=interactivo, 2=fijo
}

; --- Botones emergentes izquierda ---
btn := {
    b1: false,   ; y: 73–95   (arriba)
    b2: false,   ; y: 105–125 (medio)
    b3: false    ; y: 132–150 (abajo)
}

; --- Botones emergentes derecha ---
botDer := {
    b1: false,   ; puntos 1–4: x: 1331–1360, y: 73–101
    b2: false    ; puntos 5–8: x: 1332–1360, y: 101–124
}

; --- V: deslizador de colores ---
colorV := {
    activo : false,
    oculto : false,
    dsID   : 0,
    dsVis  : false,
    bDS    : 0,      ; BorderFrame naranja
    ; Zona del círculo de colores (anclado a CSP — coordenadas fijas)
    ccX1   : 1184,
    ccY1   : 94,
    ccX2   : 1359,
    ccY2   : 223
}

; --- Acceso rápido (Shift+Q) ---
ar := {
    id     : 0,
    activo : false,
    oculto : false,
    visible: false,
    bAR    : 0       ; BorderFrame cian
}

; --- GUIs flotantes ---
floatGui := {
    miniTip      : 0,
    miniGUI      : 0,
    tooltipToggle: 0
}

; --- Boost (SendKeyWithBoost) ---
boost := { holdDelay: 300, maxBoost: 5 }



; ┌──────────────────────────────────────────────────────────────────────┐
; │  3. TIMERS                                                           │
; └──────────────────────────────────────────────────────────────────────┘

SetTimer(CheckReload,            600)
SetTimer(ChequearZonaHistorial,  200)
SetTimer(ChequearZonaAltA,        30)
SetTimer(ChequearZonaDerecha,     30)
SetTimer(LoopColorV,              40)
SetTimer(LoopAccesoRapido,        40)

IniciarDeteccionDS()   ; busca el deslizador al arrancar



; ┌──────────────────────────────────────────────────────┐
; │  4. HOTKEYS GLOBALES (activas en cualquier ventana)  │
; └──────────────────────────────────────────────────────┘

; Numpad0 — alternar modo historial: interactivo ↔ fijo
Numpad0:: {
    hist.modo := (hist.modo = 1) ? 2 : 1
    ToolTip(hist.modo = 1 ? "🟢 HISTORIAL INTERACTIVO" : "🔒 HISTORIAL FIJO")
    SetTimer(QuitarToolTip, -10000)
}

; | — modo escritura / modo comandos AHK
#SuspendExempt
|:: {
    sys.modoEscritura := !sys.modoEscritura
    if (sys.modoEscritura) {
        Suspend(1)
        MostrarIndicador("🔴📝 MODO ESCRITURA — puedes escribir libremente 📝🔴")
    } else {
        Suspend(0)
        MostrarIndicador("🟢✅ MODO AHK ACTIVO — hotkeys habilitadas ✅🟢")
    }
}
#SuspendExempt False

; Space + RButton — voltear horizontal
Space & RButton:: {
    SendInput("!g")
    ToolTip("🎨 Space + RButton")
    SoundBeep(800, 100)
    SetTimer(QuitarToolTip, -700)
}

RButton:: SendInput("{RButton}")

; Tab — clic en dos puntos fijos del panel
Tab:: {
    MouseGetPos(&origX, &origY)
    MouseMove(32, 64, 0)
    Sleep(8)
    Click()
    Sleep(12)
    MouseMove(1400, 65, 0)
    Sleep(8)
    Click()
    Sleep(12)
    MouseMove(origX, origY, 0)
}

; Ctrl+S — guardar con sonido
^s:: {
    SendInput("^s")
    SoundBeep(600, 100)
    SoundBeep(900, 150)
    ToolTip("💾 GUARDADO Y MODIFICADO 💾")
    SetTimer(QuitarToolTip, -800)
}

; Ctrl+G — commit + push a GitHub
^g:: {
    ts       := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
    repoPath := "C:\Users\JOSUE\Desktop\AHK-global-main"
    cmd      := 'git -C "' repoPath '" add -A'
             .  ' && git -C "' repoPath '" commit -m "auto_' ts '"'
             .  ' && git -C "' repoPath '" push'
    Run("cmd /c " cmd, , "Hide")
    ToolTip("⏳ Guardando en GitHub...")
    SetTimer(_CheckGitDone, -3000)
}

; ~!b / ~!b up — stylus Alt+B
~!b::    stylus.altActive := true
~!b up:: stylus.altActive := false



; ┌──────────────────┐
; │  5. HOTKEYS CSP  │
; └──────────────────┘
#HotIf WinActive("ahk_exe CLIPStudioPaint.exe")

; ┌───────────────────────────────┐
; │  5a. SELECCIÓN Y RESELECCIÓN  │
; └───────────────────────────────┘

!x:: {
    if sel.estadoAltX {
        MostrarMiniTexto("👁 MOSTRAR BORDE", "2ECC71", 1200)
        sel.estadoAltX := false
    } else {
        MostrarMiniTexto("🚫 OCULTAR BORDE", "E74C3C", 1200)
        sel.estadoAltX := true
    }
    Send("{Alt down}{x}{Alt up}")
    SetTimer(ResetEstadoAltX, -3000)
}

c:: {
    if (sel.estadoC = 0) {
        MostrarMiniTexto("🔄 INV. ÁREA SELECC.", "FF6F61", 900)
        sel.estadoC := 1
    } else {
        MostrarMiniTexto("🔁 INV. ÁREA SELECC.", "000000", 900)
        sel.estadoC := 0
    }
    Send("c")
}

x:: {
    if (sel.estado = 0) {
        MostrarMiniTexto("❌ DESELECCIÓN", "C0392B", 700)
        Send("x")
        sel.estado := 1
    } else {
        MostrarMiniTexto("✅ RESELECCIÓN", "27AE60", 1200)
        Send("{F10}")
        sel.estado := 0
    }
}


; ┌──────────────────────────┐
; │  5b. DESHACER / REHACER  │
; └──────────────────────────┘

^z:: {
    SendInput("^z")
    ToolTipCS("🔴 DESHACER", 300)
}

!z:: {
    SendInput("^y")
    ToolTipCS("🟢 REHACER", 600)
}

; Stylus: z cuando Alt+B está presionado → rehacer
#HotIf stylus.altActive
z:: {
    SendInput("^y")
    ToolTipCS("🟢 REHACER", 600)
}
#HotIf

#HotIf WinActive("ahk_exe CLIPStudioPaint.exe")


; ┌────────────────────┐
; │  5c. HERRAMIENTAS  │
; └────────────────────┘

; ╔═══╗
; ║ A ║  simple, doble tap, Alt+A
; ╚═══╝
$a:: {
    now := A_TickCount
    if (now - A_state.lastPress < 2400) {
        A_state.lastPress := 0
        SendInput("{F7}")
        ToolTip("TODAS LAS CAPAS (2)")
        SetTimer(QuitarToolTip, -4300)
    } else {
        A_state.lastPress := now
        SendInput("{Blind}a")
        ToolTip("CAPA ACTUAL (1)")
        SetTimer(QuitarToolTip, -1300)
    }
}

!a:: {
    Send("ñ")
    ToolTip("CAPA REFERIDA")
    SetTimer(QuitarToolTip, -2300)
}

; ╔═══╗
; ║ E ║  simple, doble tap, RButton+E
; ╚═══╝
$e:: {
    now := A_TickCount
    if GetKeyState("Shift") {
        Send("e")
        return
    }
    if (now - E.last < 300) {
        SetTimer(__E_SEND_NORMAL, 0)
        E.timerRunning := 0
        Send("l")
        MostrarToolTipE("BORRADOR SUAVE  (2)")
        E.last := 0
        return
    }
    E.last         := now
    E.timerRunning := 1
    SetTimer(__E_SEND_NORMAL, -250)
}

RButton & e:: {
    if E.procesando
        return
    E.procesando := true
    if E.colorTransp {
        E.colorTransp := false
        MostrarToolTipE("🔴🔴COLOR🔴🔴")
    } else {
        E.colorTransp := true
        MostrarToolTipE("⚪ ALPHA ⚪")
        SoundPlay(A_WinDir "\Media\chimes.wav")
    }
    Send("k")
    SetTimer(ResetProcesando, -50)
}

^e:: {
    ToolTip("BORRADOR DE TODAS LAS CAPAS")
    Send("{F5}")
    SetTimer(QuitarToolTip, -800)
}

; ╔═══╗
; ║ W ║  simple, doble tap
; ╚═══╝
$w:: {
    now := A_TickCount
    if (now - W.last < 300) {
        SetTimer(__W_SEND_NORMAL, 0)
        W.timerRunning := 0
        if (!W.alpha) {
            SendInput("k")
            W.alpha := true
        }
        SendInput("{Blind}w")
        MostrarToolTipE("⚪ AERÓGRAFO ALPHA")
        SoundPlay(A_WinDir "\Media\chimes.wav")
        W.last := 0
        return
    }
    W.last         := now
    W.timerRunning := 1
    SetTimer(__W_SEND_NORMAL, -250)
}

; ╔═══╗
; ║ Q ║  simple, doble tap, RButton+Q (estabilización)
; ╚═══╝
$q:: {
    now := A_TickCount
    if (now - Q.last < 300) {
        Q.last := 0
        SetTimer(__Q_SEND_NORMAL, 0)
        SendInput("^2")
        Q.colorSecundario := !Q.colorSecundario
        if Q.colorSecundario {
            MostrarToolTipE("🟡 COLOR SECUNDARIO")
            SoundPlay(A_WinDir "\Media\Windows Battery Low.wav")
        } else {
            MostrarToolTipE("🔵 COLOR PRINCIPAL")
        }
        return
    }
    Q.last := now
    if GetKeyState("RButton", "P") {
        AlternarEstabilizacion()
        return
    }
    SetTimer(__Q_SEND_NORMAL, -50)
}

; ╔═══╗
; ║ - ║  alternar estabilización alta ↔ baja
; ╚═══╝
-:: AlternarEstabilizacion()

; ╔══════════╗
; ║ Shift+Q  ║  acceso rápido — hover invisible / modo oculto
; ╚══════════╝
+q:: {
    if (!ar.activo) {
        ar.id := 0
        for hwnd in WinGetList("ahk_exe CLIPStudioPaint.exe") {
            t := WinGetTitle("ahk_id " hwnd)
            if InStr(t, "Acceso r") && InStr(t, "pido") {
                ar.id := hwnd
                break
            }
        }
        if (!ar.id) {
            ToolTip("Abre primero el panel Acceso rapido en CSP")
            SetTimer(QuitarToolTip, -1800)
            return
        }
        ar.activo  := true
        ar.oculto  := false
        ar.visible := false
        ar.bAR     := BorderFrame("00FFFF")
        ToolTip("ACCESO RAPIDO - modo hover ON")
        SetTimer(QuitarToolTip, -1200)
        return
    }

    ar.oculto := !ar.oculto
    if (ar.oculto) {
        ar.bAR.Hide()
        WinSetTransparent(5,    "ahk_id " ar.id)
        WinSetExStyle("+0x20", "ahk_id " ar.id)
        ar.visible := false
        ToolTip("ACCESO RAPIDO - oculto")
    } else {
        WinSetTransparent(255,  "ahk_id " ar.id)
        WinSetExStyle("-0x20", "ahk_id " ar.id)
        ar.visible := true
        ToolTip("ACCESO RAPIDO - modo hover ON")
    }
    SetTimer(QuitarToolTip, -1200)
}

; ╔═══╗
; ║ S ║  simple, doble tap, Espacio+S
; ╚═══╝
$s:: {
    if (A_PriorHotkey = "$s" && A_TimeSincePriorHotkey < 250) {
        S.skipNext := true
        MostrarMiniGUI("🟢 ÁREA CON COLOR", "27AE60")
        SendInput("^x")
        SendInput("!x")
        SoundPlay(A_WinDir "\Media\Windows Exclamation.wav")
        return
    }
    if GetKeyState("Space", "P") {
        S.skipNext := true
        if (S.estadoCaracter = 0) {
            Send(",")
            MostrarTooltipToggle("AGREGAR A SELECCION", "+", "verde")
            S.estadoCaracter := 1
        } else {
            Send(".")
            MostrarTooltipToggle("ELIMINAR SELECCIÓN", "–", "rojo")
            S.estadoCaracter := 0
        }
        SetTimer(QuitarTooltipToggle, -1500)
        return
    }
    if S.skipNext {
        S.skipNext := false
        return
    }
    Send("s")
}

; ╔═══╗
; ║ O ║  ciclo 3 estados
; ╚═══╝
$o:: {
    O.ciclo := Mod(O.ciclo, 3) + 1
    if (O.ciclo = 1) {
        Send("h")
        ToolTip("BUSCAR CAPAS (1/3)")
    } else if (O.ciclo = 2) {
        SendInput("{Ctrl down}{Numpad1}{Ctrl up}")
        ToolTip("COLOR CAPA (2/3)")
    } else {
        SendInput("{Ctrl down}{Numpad2}{Ctrl up}")
        ToolTip("BORRAR COLOR CAPA (3/3)")
    }
    SetTimer(QuitarToolTip, -2000)
}

$Escape:: {
    if (O.ciclo != 0) {
        O.ciclo := 0
        ToolTip("CICLO O RESETADO")
        SetTimer(QuitarToolTip, -1000)
    }
    Send("{Escape}")
}

; ╔═══╗
; ║ V ║  hover del deslizador de colores
; ╚═══╝
;   1er tap → busca la ventana, crea borde naranja, activa hover
;   Taps sig → alterna hover-ON ↔ oculto total
v:: {
    ; ── Buscar/refrescar ID del deslizador ──────────────────────────────
    colorV.dsID := BuscarVentanaCSP(colorV.dsID, "eslizador", "colores")

    ; ── 1er tap: activar el sistema ─────────────────────────────────────
    if (!colorV.activo) {
        if (!colorV.dsID) {
            ToolTip("Abre primero el Deslizador de colores en CSP")
            SetTimer(QuitarToolTip, -1800)
            return
        }
        colorV.activo := true
        colorV.oculto := false
        colorV.dsVis  := false
        colorV.bDS    := BorderFrame("FF8C00")
        WinSetTransparent(5, "ahk_id " colorV.dsID)
        CustomToolTip("🟠 DESLIZADOR — hover ON")
        return
    }

    ; ── Taps siguientes: toggle hover ↔ oculto ──────────────────────────
    colorV.oculto := !colorV.oculto
    if (colorV.oculto) {
        colorV.bDS.Hide()
        OpacarVentana(colorV.dsID, "+0x20")
        colorV.dsVis := false
        CustomToolTip("⚫ DESLIZADOR — oculto")
    } else {
        colorV.dsVis := false
        OpacarVentana(colorV.dsID, "-0x20")
        if colorV.dsID
            WinSetTransparent(5, "ahk_id " colorV.dsID)
        CustomToolTip("🟠 DESLIZADOR — hover ON")
    }
}

; ╔═══╗
; ║ R ║  reflejar horizontalmente
; ╚═══╝
+r:: {
    CustomToolTip("REFLEJAR HORIZONTALMENTE")
    Send("+r")
}

#HotIf


; ┌─────────────────────────────────────┐
; │  5d. ATAJOS CON CLIC DERECHO        │
; └─────────────────────────────────────┘

RButton & v:: {
    ToolTip("RELLENO DE COLOR")
    Send("{F11}")
    SetTimer(QuitarToolTip, -800)
}

RButton & s:: {
    ToolTip("LAZO CON AUTORELLENO")
    Send("{F9}")
    SetTimer(QuitarToolTip, -1200)
}

RButton & 1::
RButton & 2::
RButton & 3::
RButton & 4::
RButton & 5::
RButton & 6::
RButton & 7::
RButton & 8::
RButton & 9::
RButton & 0:: {
    key        := SubStr(A_ThisHotkey, StrLen(A_ThisHotkey))
    porcentaje := (key = "0") ? 100 : Integer(key) * 10
    ToolTip("OPACIDAD " porcentaje "%")
    Send("+" key)
    SetTimer(QuitarToolTip, -1500)
}


; ┌─────────────────────────────────────┐
; │  5e. MODIFICADORES DE CAPA          │
; └─────────────────────────────────────┘

~Space & NumpadAdd:: Send("+p")
~Space & NumpadSub:: Send("^+p")

~Space & Numpad1::
~Space & Numpad2::
~Space & Numpad3::
~Space & Numpad4::
~Space & Numpad5::
~Space & Numpad6:: {
    tecla := SubStr(A_ThisHotkey, StrLen(A_ThisHotkey))
    tipos := Map("1", "HSV (Hue / Sat / Val)"
               , "2", "Brillo / Contraste"
               , "3", "Equilibrio de color"
               , "4", "Curva de tonos"
               , "5", "Corrección de nivel"
               , "6", "Degradado")
    ToolTip("Capa: " tipos[tecla])
    Send("^!" tecla)
    SetTimer(QuitarToolTip, -500)
}

$Numpad6:: {
    if (N6.estadoEscala = 0) {
        Send("7")
        ToolTip("CAPA ESCALA DE GRISES")
        N6.estadoEscala := 1
    } else {
        Send("8")
        ToolTip("BORRAR CAPA DE CORRECCIÓN")
        N6.estadoEscala := 0
    }
    SetTimer(QuitarToolTip, -1200)
}

*Backspace:: {
    if GetKeyState("Space", "P") {
        Send("8")
        ToolTip("BORRAR CAPA DE CORRECCIÓN")
        SetTimer(QuitarToolTip, -1200)
        N6.estadoEscala := 0
        return
    }
    Send("{Backspace}")
}

~Space:: {
    ; passthrough — consume Space suelto sin acción extra
}

#HotIf



; ┌────────────────────────────────────────────────────────────────┐
; │  6. CLASE BorderFrame                                          │
; │     4 GUIs delgados que forman el borde visual de una ventana  │
; └────────────────────────────────────────────────────────────────┘
class BorderFrame {
    T := 0
    B := 0
    L := 0
    R := 0

    __New(color) {
        opts := "-Caption +AlwaysOnTop +ToolWindow +E0x20"
        for side in ["T", "B", "L", "R"] {
            g := Gui(opts)
            g.BackColor := color
            g.Show("w0 h0 NoActivate")
            this.%side% := g
        }
    }

    Show(x, y, w, h, g := 2) {
        this.T.Show("x" x           " y" y           " w" w " h" g " NoActivate")
        this.B.Show("x" x           " y" (y + h - g) " w" w " h" g " NoActivate")
        this.L.Show("x" x           " y" y           " w" g " h" h " NoActivate")
        this.R.Show("x" (x + w - g) " y" y           " w" g " h" h " NoActivate")
    }

    Hide() {
        this.T.Hide()
        this.B.Hide()
        this.L.Hide()
        this.R.Hide()
    }
}



; ┌────────────────────────────────────────────────────────────────┐
; │  7. FUNCIONES                                                  │
; └────────────────────────────────────────────────────────────────┘

; ── Helpers internos ─────────────────────────────────────────────

; Busca el Deslizador de colores al arrancar el script.
; Si CSP no está abierto todavía, queda en 0 y v:: lo reintenta al primer tap.
IniciarDeteccionDS() {
    colorV.dsID := BuscarVentanaCSP(0, "eslizador", "colores")
}

; Busca ventana CSP por fragmentos de título. Devuelve hwnd o 0.
BuscarVentanaCSP(idActual, frag1, frag2) {
    if (idActual && WinExist("ahk_id " idActual))
        return idActual
    for hwnd in WinGetList("ahk_exe CLIPStudioPaint.exe") {
        t := WinGetTitle("ahk_id " hwnd)
        if InStr(t, frag1) && InStr(t, frag2)
            return hwnd
    }
    return 0
}

; Aplica transparencia 5 + ExStyle a una ventana (si existe)
OpacarVentana(id, exStyle) {
    if (id && WinExist("ahk_id " id)) {
        WinSetTransparent(5,      "ahk_id " id)
        WinSetExStyle(exStyle,   "ahk_id " id)
    }
}

; Lógica unificada de hover para una ventana + su BorderFrame.
; obj   = objeto que contiene el estado (colorV, ar, etc.)
; visKey = nombre de la propiedad booleana de visibilidad ("dsVis", "visible"...)
; Devuelve false si la ventana ya no existe (señal para limpiar el ID).
HoverFrame(id, obj, visKey, frame, mx, my) {
    if (!id || !WinExist("ahk_id " id)) {
        if (id && IsObject(frame))
            frame.Hide()
        return false
    }
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " id)
    dentro := (mx >= wx && mx <= wx+ww && my >= wy && my <= wy+wh)
    vis := obj.%visKey%
    if (dentro) {
        if (!vis) {
            obj.%visKey% := true
            WinSetTransparent(255,  "ahk_id " id)
            WinSetExStyle("-0x20", "ahk_id " id)
            frame.Hide()
        }
    } else {
        if (vis) {
            obj.%visKey% := false
            WinSetTransparent(5,    "ahk_id " id)
            WinSetExStyle("+0x20", "ahk_id " id)
        }
        if IsObject(frame)
            frame.Show(wx, wy, ww, wh)
    }
    return true
}

; ── Timers de recarga ─────────────────────────────────────────────

CheckReload() {
    newTime := FileGetTime(A_ScriptFullPath, "M")
    if (sys.lastModTime = "") {
        sys.lastModTime := newTime
        return
    }
    if (newTime != sys.lastModTime) {
        sys.lastModTime := newTime
        x := (A_ScreenWidth  // 2) - 120
        y := (A_ScreenHeight // 2) - 20
        ToolTip("💾 Script actualizado y recargado", x, y)
        SoundBeep(750, 180)
        SoundBeep(950, 180)
        SoundBeep(850, 180)
        Sleep(300)
        ToolTip()
        Reload()
    }
}

; ── Timers de zona ────────────────────────────────────────────────

ChequearZonaHistorial() {
    if !WinActive("ahk_exe CLIPStudioPaint.exe")
        return
    if (hist.modo = 2)
        return
    MouseGetPos(&mx, &my)
    enZona := (mx >= 79 && mx <= 1168 && my >= 626 && my <= 762)
    if (enZona && !hist.abierto) {
        hist.abierto := true
        Send("{Numpad9}")
    } else if (!enZona && hist.abierto) {
        hist.abierto := false
        Send("{Numpad9}")
    }
}

ChequearZonaAltA() {
    MouseGetPos(&mx, &my)

    enZona1 := (mx >= 5 && mx <= 34 && my >= 73  && my <= 95)
    if (enZona1 && !btn.b1) {
        btn.b1 := true
        Click()
    } else if (!enZona1 && btn.b1)
        btn.b1 := false

    enZona2 := (mx >= 5 && mx <= 34 && my >= 105 && my <= 125)
    if (enZona2 && !btn.b2) {
        btn.b2 := true
        Click()
    } else if (!enZona2 && btn.b2)
        btn.b2 := false

    enZona3 := (mx >= 5 && mx <= 31 && my >= 132 && my <= 150)
    if (enZona3 && !btn.b3) {
        btn.b3 := true
        Click()
    } else if (!enZona3 && btn.b3)
        btn.b3 := false
}

ChequearZonaDerecha() {
    MouseGetPos(&mx, &my)

    enZona1 := (mx >= 1331 && mx <= 1360 && my >= 73  && my <= 101)
    if (enZona1 && !botDer.b1) {
        botDer.b1 := true
        Click()
    } else if (!enZona1 && botDer.b1)
        botDer.b1 := false

    enZona2 := (mx >= 1332 && mx <= 1360 && my >= 101 && my <= 124)
    if (enZona2 && !botDer.b2) {
        botDer.b2 := true
        Click()
    } else if (!enZona2 && botDer.b2)
        botDer.b2 := false
}

; ── Timers de hover ───────────────────────────────────────────────

LoopColorV() {
    if (!colorV.activo || colorV.oculto)
        return
    MouseGetPos(&mx, &my)

    ; Ventana desapareció externamente — limpiar
    if (!colorV.dsID || !WinExist("ahk_id " colorV.dsID)) {
        if colorV.dsID
            colorV.bDS.Hide()
        colorV.dsID := 0
        return
    }

    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " colorV.dsID)

    enDS      := (mx >= wx          && mx <= wx+ww       && my >= wy          && my <= wy+wh)
    enCirculo := (mx >= colorV.ccX1 && mx <= colorV.ccX2 && my >= colorV.ccY1 && my <= colorV.ccY2)

    if (enDS || enCirculo) {
        ; Dentro del deslizador O del círculo → visible, sin borde
        if (!colorV.dsVis) {
            colorV.dsVis := true
            WinSetTransparent(255,   "ahk_id " colorV.dsID)
            WinSetExStyle("-0x20",  "ahk_id " colorV.dsID)
            colorV.bDS.Hide()
        }
    } else {
        ; Fuera de ambos → invisible + borde naranja
        if (colorV.dsVis) {
            colorV.dsVis := false
            WinSetTransparent(5,    "ahk_id " colorV.dsID)
            WinSetExStyle("+0x20", "ahk_id " colorV.dsID)
        }
        if IsObject(colorV.bDS)
            colorV.bDS.Show(wx, wy, ww, wh)
    }
}

LoopAccesoRapido() {
    if (!ar.activo || ar.oculto)
        return
    MouseGetPos(&mx, &my)
    if !HoverFrame(ar.id, ar, "visible", ar.bAR, mx, my) {
        ar.activo  := false
        ar.oculto  := false
        ar.id      := 0
        ar.visible := false
    }
}

; ── Timers de herramientas ────────────────────────────────────────

__E_SEND_NORMAL() {
    if E.timerRunning {
        Send("e")
        MostrarToolTipE("BORRADOR NORMAL  (1)")
        E.timerRunning := 0
        E.last         := 0
    }
}

ResetProcesando() => E.procesando := false

__W_SEND_NORMAL() {
    if W.timerRunning {
        if W.alpha {
            SendInput("k")
            W.alpha := false
        }
        SendInput("{Blind}w")
        MostrarToolTipE("💨 AERÓGRAFO")
        W.timerRunning := 0
        W.last         := 0
    }
}

__Q_SEND_NORMAL() => SendInput("q")

; ── Estabilización ───────────────────────────────────────────────

AlternarEstabilizacion() {
    if (Q.estadoEstab = 0) {
        SendInput("{Blind}{- 63}")
        Q.estadoEstab := 1
        msg := "🟢 Estabilización Alta"
        frq := 1200
    } else {
        SendInput("{Blind}{j 63}")
        Q.estadoEstab := 0
        msg := "🔵 Estabilización Baja"
        frq := 500
    }
    Sleep(10)
    ToolTip(msg)
    SetTimer(QuitarToolTip, -800)
    SoundBeep(frq, 300)
}

; ── GitHub ────────────────────────────────────────────────────────

_CheckGitDone() {
    ToolTip("✅ GitHub actualizado")
    SoundPlay(A_WinDir "\Media\Windows Navigation Start.wav")
    SetTimer(QuitarToolTip, -2000)
}

; ── Reset de estados ─────────────────────────────────────────────

ResetEstadoAltX() => sel.estadoAltX := false

; ── ToolTips (todos unificados en QuitarToolTip) ─────────────────

QuitarToolTip()      => ToolTip()
OcultarToolTip()     => ToolTip()
OcultarToolTipAltG() => ToolTip()
OcultarToolTipQ()    => ToolTip()
OcultarIndicador()   => ToolTip()

MostrarIndicador(texto) {
    ToolTip(texto)
    SetTimer(OcultarIndicador, -2500)
}

MostrarToolTipE(texto, duracion := 10050) {
    ToolTip(texto, A_ScreenWidth // 2, 115)
    SetTimer(QuitarToolTip, -duracion)
}

ToolTipCS(texto, duracion := 800) {
    WinGetPos(&wx, &wy, &ww, , "A")
    ToolTip(texto, wx + (ww // 2), wy + 125)
    SetTimer(QuitarToolTip, -duracion)
}

CustomToolTip(text, duration := 1500) {
    ToolTip(text, , , 2)
    SetTimer(RemoveCustomToolTip, -duration)
}

RemoveCustomToolTip() => ToolTip(, , , 2)

; ── GUIs flotantes ───────────────────────────────────────────────

MostrarMiniTexto(texto, colorHex := "222222", duracion := 800) {
    if IsObject(floatGui.miniTip)
        floatGui.miniTip.Destroy()
    g := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
    g.BackColor := colorHex
    g.SetFont("s6.5 Bold", "Segoe UI")
    g.AddText("cFFFFFF Center", texto)
    g.Show("NoActivate AutoSize")
    WinSetTransparent(200, "ahk_id " g.Hwnd)
    g.GetPos(, , &w, &h)
    sw := SysGet(78)
    sh := SysGet(79)
    g.Move((sw - w) // 2, Round(sh * 0.82))
    if (w > 300)
        g.Show("w300 h" h)
    floatGui.miniTip := g
    SetTimer(OcultarMiniTip, -duracion)
}

OcultarMiniTip() {
    if IsObject(floatGui.miniTip)
        floatGui.miniTip.Destroy()
    floatGui.miniTip := 0
}

MostrarMiniGUI(texto, colorHex := "222222", duracion := 1200) {
    if IsObject(floatGui.miniGUI)
        floatGui.miniGUI.Destroy()
    g := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
    g.BackColor := colorHex
    g.SetFont("s6.5 Bold", "Segoe UI")
    g.AddText("cFFFFFF Center", texto)
    g.Show("AutoSize NoActivate")
    WinSetTransparent(200, "ahk_id " g.Hwnd)
    g.GetPos(, , &w, &h)
    g.Move((A_ScreenWidth - w) // 2, Round(A_ScreenHeight * 0.02))
    floatGui.miniGUI := g
    SetTimer(OcultarMiniGUI, -duracion)
}

OcultarMiniGUI() {
    if IsObject(floatGui.miniGUI)
        floatGui.miniGUI.Destroy()
    floatGui.miniGUI := 0
}

MostrarTooltipToggle(titulo, simbolo, color) {
    if IsObject(floatGui.tooltipToggle)
        floatGui.tooltipToggle.Destroy()
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    if (color = "verde") {
        g.BackColor := "1F4D3A"
        g.SetFont("s7.5 Bold cWhite", "Segoe UI")
        simColor := "Lime"
    } else {
        g.BackColor := "D92B2B"
        g.SetFont("s7.5 Bold cWhite", "Segoe UI")
        simColor := "White"
    }
    g.AddText("x6 y4 w130 h14 Center", titulo)
    g.SetFont("s8.5 Bold c" simColor, "Segoe UI")
    g.AddText("x140 y2 w14 h14 Center", simbolo)
    g.Show("w155 h20 Center NoActivate")
    floatGui.tooltipToggle := g
}

QuitarTooltipToggle() {
    if IsObject(floatGui.tooltipToggle)
        floatGui.tooltipToggle.Destroy()
    floatGui.tooltipToggle := 0
}

; ── Boost ─────────────────────────────────────────────────────────

SendKeyWithBoost(key, startTick) {
    elapsed := A_TickCount - startTick
    if (elapsed < boost.holdDelay)
        return
    ratio := Min((elapsed - boost.holdDelay) / 100, 1)
    b     := Max(Round(boost.maxBoost * (ratio ** 0.1)), 1)
    Loop b
        SendInput("{Blind}" key)
}
