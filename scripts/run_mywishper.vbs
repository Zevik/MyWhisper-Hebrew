' Launch MyWhisper using the venv pythonw interpreter directly.
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
rootDir = fso.GetParentFolderName(scriptDir)
venvPythonw = fso.BuildPath(rootDir, ".venv\Scripts\pythonw.exe")
mainPy = fso.BuildPath(rootDir, "app\main.py")

Set shell = CreateObject("WScript.Shell")
shell.CurrentDirectory = rootDir
shell.Run """" & venvPythonw & """ """ & mainPy & """", 0, False
