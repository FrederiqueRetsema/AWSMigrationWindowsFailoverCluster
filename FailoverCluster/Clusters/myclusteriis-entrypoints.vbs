' wsfc-check.vbs
' ==============
' Based on: (most of the script) https://docs.microsoft.com/en-us/troubleshoot/iis/configure-w3svc-wsfc
' and (AWS part): https://www.it-knowledge.info/windows-failover-cluster-in-amazon-ec2/
' I rewrote all VBS to PowerShell.

Option Explicit

'Cluster resource entry points. More details here:
'http://msdn.microsoft.com/en-us/library/aa372846(VS.85).aspx
'Cluster resource Online entry point
'Make sure the website, the application pool and the service are started
Function Online( )
    Dim objShell
    Dim result	

  	Set objShell = CreateObject("Wscript.shell")
    result = objShell.run("C:\windows\system32\WindowsPowerShell\v1.0\powershell -executionpolicy bypass -file c:\ClusterScripts\Cluster-Online.ps1",0,True)

	Online = (result = 0)

End Function

'Cluster resource offline entry point
'Stop the website, application pool and service
Function Offline( )
    Dim objShell
    Dim result	

  	Set objShell = CreateObject("Wscript.shell")
    result = objShell.run("C:\windows\system32\WindowsPowerShell\v1.0\powershell -executionpolicy bypass -file c:\ClusterScripts\Cluster-Offline.ps1",0,True)

    Offline = (result = 0)
End Function

'Cluster resource LooksAlive entry point
'Check for the health of the website, the application pool and the service
Function LooksAlive( )
    Dim objShell
    Dim result	

  	Set objShell = CreateObject("Wscript.shell")
    result = objShell.run("C:\windows\system32\WindowsPowerShell\v1.0\powershell -executionpolicy bypass -file c:\ClusterScripts\Cluster-LooksAlive.ps1",0,True)

    LooksAlive = (result = 0)

End Function

'Cluster resource IsAlive entry point
'Do a more extensive health check than LooksAlive
Function IsAlive()
	Dim objShell
    Dim result	

  	Set objShell = CreateObject("Wscript.shell")
    result = objShell.run("C:\windows\system32\WindowsPowerShell\v1.0\powershell -executionpolicy bypass -file c:\ClusterScripts\Cluster-IsAlive.ps1",0,True)

    IsAlive = (result = 0)
End Function

'Cluster resource Open entry point
Function Open()
	Dim objShell
    Dim result	

  	Set objShell = CreateObject("Wscript.shell")
    result = objShell.run("C:\windows\system32\WindowsPowerShell\v1.0\powershell -executionpolicy bypass -file c:\ClusterScripts\Cluster-Open.ps1",0,True)

    Open = (result = 0)
End Function

'Cluster resource Close entry point
Function Close()
	Dim objShell
	Dim result

  	Set objShell = CreateObject("Wscript.shell")
    result = objShell.run("C:\windows\system32\WindowsPowerShell\v1.0\powershell -executionpolicy bypass -file c:\ClusterScripts\Cluster-Close.ps1",0,True)

    Close = (result = 0)
End Function

'Cluster resource Terminate entry point
Function Terminate()
	Dim objShell
	Dim result

  	Set objShell = CreateObject("Wscript.shell")
    result = objShell.run("C:\windows\system32\WindowsPowerShell\v1.0\powershell -executionpolicy bypass -file c:\ClusterScripts\Cluster-Terminate.ps1")

    Terminate = (result = 0)
End Function
