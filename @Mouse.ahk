#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

XButton1::Send, ^|          ; Ditto - abrir interfaz
XButton2::Send, ^!j         ; ShareX - captura
^p::Send, ^!f               ; ShareX - fijar desde pantalla