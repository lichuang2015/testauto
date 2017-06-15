$LocalPort = 8980
$RemotePort = 8984

# Get the computer number
$computerNumberFile = Split-Path $MyInvocation.MyCommand.Path
$computerNumberFile = "$computerNumberFile\Number.txt"
if (!(Test-Path $computerNumberFile))
{
	Write-Host "Unable to access evaluations." -ForegroundColor Red
	Write-Host "This computer has not been assigned a number."
	Read-Host "Press <Enter> to close" | Out-Null
	Exit
}
$computerNumber = [System.Int32]::Parse([System.IO.File]::ReadAllText($computerNumberFile))

# Send the request
$sender = New-Object -TypeName System.Net.Sockets.UdpClient($LocalPort)
$endpoint = New-Object -TypeName System.Net.IPEndPoint([System.Net.IPAddress]::Broadcast, $RemotePort)
$sender.Connect($endpoint)
$sender.Send([Byte[]] $computerNumber, 1) | Out-Null
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
	$data = [System.Text.Encoding]::UTF8.GetString($receiver.EndReceive($result, [ref] $endpoint))
}
$receiver.Close()

# Show the received data
if ($data -eq $null)
{
	Write-Host "No response was received." -ForegroundColor Red
	Write-Host "Please check that the server is running, and try again."
	Read-Host "Press <Enter> to close" | Out-Null
}
else
{
	write-host $data
	Read-Host "Press <Enter> to close" | Out-Null
	# start $data
}
