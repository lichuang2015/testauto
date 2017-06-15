$LocalPort = 8980
$GetRepositoryPort = 8981
$GetComputerNumberPort = 8983

function Get-Response($remotePort)
{
	# Send the request
	$sender = New-Object -TypeName System.Net.Sockets.UdpClient($LocalPort)
	$endpoint = New-Object -TypeName System.Net.IPEndPoint([System.Net.IPAddress]::Broadcast, $remotePort)
	$sender.Connect($endpoint)
	$sender.Send([Byte[]] 0, 1) | Out-Null
	$sender.Close()

	# Get the response
	$receiver = New-Object -TypeName System.Net.Sockets.UdpClient($LocalPort)
	$endpoint = New-Object -TypeName System.Net.IPEndPoint([System.Net.IPAddress]::Any, $LocalPort)
	$result = $receiver.BeginReceive($null, $null)
	for ($i = 0; $i -lt 200; $i++)
	{
		[System.Threading.Thread]::Sleep(5)
		if ($result.IsCompleted) { break }
	}
	if ($result.IsCompleted)
	{
		$data = $receiver.EndReceive($result, [ref] $endpoint)
	}
	$receiver.Close()
	
	return $data
}

# Connect to the repository path
Write-Host "Getting the path to the repository..."
$data = Get-Response $GetRepositoryPort
if ($data -eq $null)
{
	Write-Host "Unable to identify the URL." -ForegroundColor Red
	Write-Host "Please check that the server is running, and try again."
	$serverName = Read-Host "Alternatively, if you know the name of the server, enter it now"
	if ($serverName -ne "")
	{
		Write-Host "Connecting to the repository..."
		net use R: /delete 2>&1 | Out-Null
		$data = "\\$($serverName)\Repos"
		net use R: $data /persistent:yes /user:User1 Password. | Out-Null
	}
}
else
{
	$data = [System.Text.Encoding]::UTF8.GetString($data)
	Write-Host "Connecting to the repository $data ..."
	net use R: /delete 2>&1 | Out-Null
	net use R: $data /persistent:yes /user:User1 Password. | Out-Null
}
if ($LastExitCode -ne 0)
{
	Exit $LastExitCode
}

# Assign the computer number
$computerNumberFile = Split-Path $MyInvocation.MyCommand.Path
$computerNumberFile = "$computerNumberFile\Number.txt"
if (!(Test-Path $computerNumberFile))
{
	Write-Host "Getting the computer number..."
	$number = Get-Response($GetComputerNumberPort)
	if ($number -eq $null)
	{
		Write-Host "Unable to get the computer number." -ForegroundColor Red
		Write-Host "Please check that the server is running, and try again."
	}
	else
	{
		[System.IO.File]::WriteAllText($computerNumberFile, "$number")
		Write-Host "This is computer number $number"
	}
}
Read-Host "Press <Enter> to continue" | Out-Null
