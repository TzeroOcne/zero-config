#SingleInstance

ReactivateWindow() {
  global activeWindow
  WinActivate(activeWindow)
}

SnippetTime() {
  SendText(FormatTime(, "yyyy-MM-dd HH:mm:ss"))
}

SnippetTimeName() {
  SendText(FormatTime(, "yyyy-MM-ddTHHmmss"))
}

SnippetNIK() {
  SendText(Random(1000000000000000, 9999999999999999))
}

SnippetPhone() {
  ; SendText("+62999" Random(10000000, 99999999))
  SendText("+62821" Random(10000000, 99999999))
}

^!s:: { ; Ctrl + Alt + S
  global activeWindow
  activeWindow := WinGetID("A")
  SnippetGUI := Gui("+AlwaysOnTop +ToolWindow -Caption")

  SnippetGUI.SetFont("s12 Bold")
  SnippetGUI.BackColor := "000000" ; Can be any RGB color (it will be made transparent below).
  SnippetGUI.SetFont("s12")
  textColor := "c00cfbf" ; #00cfbf

  SnippetGUI.Add("Text", textColor, "T: Timestamp")
  SnippetGUI.Add("Text", textColor, "t: Timestamp Name")
  SnippetGUI.Add("Text", textColor, "n: NIK")
  SnippetGUI.Add("Text", textColor, "p: Phone number")
  SnippetGUI.Show("x" Floor(A_ScreenWidth * 0.04) " y" Floor(SysGet(62) * 0.07))  ; NoActivate avoids deactivating the currently active window.

  ih := InputHook("L1 C", "{enter}.{esc}{tab}", "T,t,n,p")
  ih.Start()
  ih.Wait()

  ReactivateWindow()
  switch ih.Input {
    case "T":
      SnippetTime()
    case "t":
      SnippetTimeName()
    case "n":
      SnippetNIK()
    case "p":
      SnippetPhone()
  }

  SnippetGUI.Destroy()
}
