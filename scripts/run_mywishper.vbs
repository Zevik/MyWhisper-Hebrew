' Launch MyWhisper silently (no console window).
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
rootDir = fso.GetParentFolderName(scriptDir)
venvPythonw = fso.BuildPath(rootDir, ".venv\Scripts\pythonw.exe")
mainPy = fso.BuildPath(rootDir, "app\main.py")

Set shell = CreateObject("WScript.Shell")
shell.CurrentDirectory = rootDir

basePythonw = ""
cfgPath = fso.BuildPath(rootDir, ".venv\pyvenv.cfg")
If fso.FileExists(cfgPath) Then
    On Error Resume Next
    Set f = fso.OpenTextFile(cfgPath, 1)
    If Err.Number = 0 Then
        Do Until f.AtEndOfStream
            line = f.ReadLine
            If LCase(Left(LTrim(line), 4)) = "home" Then
                pos = InStr(line, "=")
                If pos > 0 Then
                    homeDir = Trim(Mid(line, pos + 1))
                    candidate = fso.BuildPath(homeDir, "pythonw.exe")
                    If fso.FileExists(candidate) Then basePythonw = candidate
                End If
            End If
        Loop
        f.Close
    End If
    On Error GoTo 0
End If

If basePythonw <> "" And fso.FileExists(basePythonw) Then
    shell.Environment("PROCESS")("__PYVENV_LAUNCHER__") = venvPythonw
    shell.Run """" & basePythonw & """ """ & mainPy & """", 0, False
Else
    shell.Run """" & venvPythonw & """ """ & mainPy & """", 0, False
End If
