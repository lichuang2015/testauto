Param
(
	[switch]$PauseAtEnd
)

# Ensure the script is running as administrator
$ParentInvocation = Get-Variable MyInvocation -Scope 1
$ThisScriptPath = $ParentInvocation.Value.MyCommand.Definition
$Pos1 = $ThisScriptPath.IndexOf(" ")
if ($Pos1 -ge 0) { $ThisScriptPath = $ThisScriptPath.Substring(0, $Pos1) }
$ThisScriptArguments = $ParentInvocation.Value.MyCommand.Definition.Substring($ThisScriptPath.Length).Trim()
if ($ThisScriptPath[0] -eq '&') { $ThisScriptPath = $ThisScriptPath.Substring(2, $ThisScriptPath.Length - 3) }
$ThisScriptPath = (Resolve-Path $ThisScriptPath).Path
$ThisScriptDirectory = Split-Path $ThisScriptPath
$CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$IsAdmin = $CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $IsAdmin)
{
	Write-Host "This script needs to be run as an administrator."
	Write-Host "Please answer yes if prompted to allow it."
	$IsRunningAsAdmin = $false
	while (-not $IsRunningAsAdmin)
	{
		try
		{
			if (!$ThisScriptArguments.Contains("-PauseAtEnd"))
			{
				$ThisScriptArguments = "$ThisScriptArguments -PauseAtEnd"
			}
			Start-Process "powershell.exe" -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Maximized ""&'$ThisScriptPath'"" $ThisScriptArguments"
			$IsRunningAsAdmin = $true
		}
		catch
		{
			$IsRunningAsAdmin = $false
			Write-Host "The script failed to run as an administrator." -ForegroundColor Red
			Write-Host "This script needs to be run as an administrator."
			Write-Host "Please answer yes if prompted to allow it."
			Read-Host "Press Enter when ready to try again"
		}
	}
	Write-Host "This script has been restarted as an administrator."
	Exit
	# throw "This script has been restarted as an administrator."
}

Write-Host "Preparing this instructor's host computer for AGA" -ForegroundColor Yellow

$NumberOfUsers = Read-Host "How many users do you want [1]"
if ($NumberOfUsers -eq "") { $NumberOfUsers = 1 }

# Globals
$OriginalInstallDirectory = "C:\AGA"
$InstallDirectory = Split-Path $ThisScriptDirectory
Set-Location $InstallDirectory
$AllRepositories = Get-ChildItem Repos
function Replace-InFile($fileName, $match, $replace)
{
	(Get-Content $fileName) -replace $match, $replace | Set-Content $fileName
}

# Update references to the installation directory
if ($InstallDirectory -ne $OriginalInstallDirectory)
{
	Write-Host "Updating references to the install directory"
	# $matchForWindows = $OriginalInstallDirectory -replace "\\", "\\"
	# $replaceForWindows = $InstallDirectory
	$matchForLinux = $OriginalInstallDirectory -replace "\\", "/"
	$replaceForLinux = $InstallDirectory -replace "\\", "/"
	$matchForURL = $OriginalInstallDirectory -replace "\\", "%5C"
	$replaceForURL = $InstallDirectory -replace "\\", "%5C"
	
	$AllRepositories | % { Replace-InFile Repos\$_\hooks\post-receive $matchForURL $replaceForURL }
	
	git clone Repos\GreenMart.git GM 2>&1 | Out-Null
	cd GM
	Replace-InFile app.config $matchForLinux $replaceForLinux
	git add app.config | Out-Null
	git commit -m "Corrected the location of the database." | Out-Null
	git push origin master 2>&1 | Out-Null
	cd .. | Out-Null
	Remove-Item GM -Recurse -Force
}

# Create new users or enable existing users
Write-Host "Creating/enabling users for participants"
1..$NumberOfUsers | % {
	# net user User$_ Password. /add 2>&1 | Out-Null
	# if ($LastExitCode -ne 0)
	# {
		# net user User$_ /active:yes | Out-Null
	# }
	net user User$_ Password. /add /active:yes /expires:never /passwordchg:no 2>&1 | Out-Null
}

# Set the permissions on the repositories
Write-Host "Setting the permissions on the repositories"
function Grant-FolderPermissions($folder, $sid, $permissions)
{
	$cmd = "icacls $folder /grant `"$sid`":$permissions"
	cmd /c $cmd | Out-Null
}
function Set-Permissions($sid)
{
	icacls Repos /remove $sid | Out-Null
	Grant-FolderPermissions Repos $sid "(OI)(CI)(RX)"
	$AllRepositories | % { Grant-FolderPermissions Repos\$_ $sid "(OI)(CI)(M)" }
}
icacls Repos /inheritance:d | Out-Null
"Everyone","Users","Authenticated Users" | % { Set-Permissions $_ }

# Share the repositories
Write-Host "Sharing the repositories"
net share | find `"Repos`" | Out-Null
if ($LastExitCode -eq 0)
{
	net share Repos /delete | Out-Null
}
# The following is run via cmd because otherwise it doesn't work on Windows 7
cmd /c "net share Repos=$InstallDirectory\Repos /grant:everyone,full" | Out-Null

# Add firewall rules
Write-Host "Adding firewall rules"
function Add-FirewallRule($name, $protocol, $ports)
{
	netsh advfirewall firewall show rule name="$name" 2>&1 | Out-Null
	if ($LastExitCode -eq 0)
	{
		netsh advfirewall firewall delete rule name="$name" 2>&1 | Out-Null
	}
	netsh advfirewall firewall add rule name="$name" dir=in action=allow protocol=$protocol localport=$ports 2>&1 | Out-Null
}
Add-FirewallRule Jenkins TCP 8882
Add-FirewallRule "Lab based course support" UDP "8980-8983"

# Update Git post-receive hooks to use this host name
Write-Host "Updating post-receive hooks to use this computer"
$AllRepositories | % { Replace-InFile Repos\$_\hooks\post-receive "localhost" $env:COMPUTERNAME }

# Start Jenkins
Write-Host "Starting Jenkins"
$si = New-Object System.Diagnostics.ProcessStartInfo
$si.FileName = "C:\jenkins\jenkins.cmd"
$si.WorkingDirectory = "C:\jenkins"
$si.UseShellExecute = $false
$si.RedirectStandardInput = $true
$si.RedirectStandardOutput = $true
$si.RedirectStandardError = $true
$Jenkins = [System.Diagnostics.Process]::Start($si)
while ($true)
{
	$o = $Jenkins.StandardError.ReadLine()
	if ($o -eq "INFO: Jenkins is fully up and running") { break }
}

# Download jenkins-cli.jar
Write-Host "Downloading jenkins-cli.jar"
# Invoke-WebRequest is PowerShell 3.0 only (after Windows 7)
# Invoke-WebRequest http://localhost:8882/jnlpJars/jenkins-cli.jar -OutFile jenkins-cli.jar
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile("http://localhost:8882/jnlpJars/jenkins-cli.jar", "$InstallDirectory\jenkins-cli.jar")

# Jenkins globals
function Get-FromJenkinsCLI($command)
{
	$cmd = "java -jar $InstallDirectory\jenkins-cli.jar -s http://localhost:8882 $command 2>&1"
	return cmd /c $cmd
}
function Run-JenkinsCLI($command)
{
	Get-FromJenkinsCLI $command | Out-Null
}
function Send-ToJenkins($command, $content)
{
	$cmd = "java -jar $InstallDirectory\jenkins-cli.jar -s http://localhost:8882 $command 2>&1"
	$content | cmd /c $cmd | Out-Null
}

# Create the Jenkins jobs
Write-Host "Creating the Jenkins jobs"
$AllPlugIns = Get-FromJenkinsCLI "list-plugins"
function Get-PlugInVersion($name)
{
	$matchPlugin = "$name\s{1,}[^\d]*([^\s]+)"
	$m = $AllPlugIns | Where { $_ -cmatch $matchPlugin }
	return $Matches[1]
}
$GitPlugInVersion = Get-PlugInVersion "git"
$AntPlugInVersion = Get-PlugInVersion "ant"
$JUnitPlugInVersion = Get-PlugInVersion "junit"
$CucumberPlugInVersion = Get-PlugInVersion "cucumber-testresult-plugin"
$CheckStylePlugInVersion = Get-PlugInVersion "checkstyle"
$AnalysisCorePlugInVersion = Get-PlugInVersion "analysis-core"
$JenkinsJobStandardBeforeGitDirectory = "<?xml version='1.0' encoding='UTF-8'?><project><actions/><description></description><keepDependencies>false</keepDependencies><properties/><scm class=`"hudson.plugins.git.GitSCM`" plugin=`"git@$GitPlugInVersion`"><configVersion>2</configVersion><userRemoteConfigs><hudson.plugins.git.UserRemoteConfig><url>"
$JenkinsJobStandardAfterGitDirectoryBeforeTriggers = "</url></hudson.plugins.git.UserRemoteConfig></userRemoteConfigs><branches><hudson.plugins.git.BranchSpec><name>*/master</name></hudson.plugins.git.BranchSpec></branches><doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations><submoduleCfg class=`"list`"/><extensions/></scm><canRoam>true</canRoam><disabled>false</disabled><blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding><blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>"
$JenkinsJobScmTriggers = "<triggers><hudson.triggers.SCMTrigger><spec></spec><ignorePostCommitHooks>false</ignorePostCommitHooks></hudson.triggers.SCMTrigger></triggers>"
$JenkinsJobUpstreamTriggerBeforeProjectName = "<triggers><jenkins.triggers.ReverseBuildTrigger><spec></spec><upstreamProjects>"
$JenkinsJobUpstreamTriggerAfterProjectName = "</upstreamProjects><threshold><name>SUCCESS</name><ordinal>0</ordinal><color>BLUE</color><completeBuild>true</completeBuild></threshold></jenkins.triggers.ReverseBuildTrigger></triggers>"
$JenkinsJobStandardAfterTriggersBeforeBuilders = "<concurrentBuild>false</concurrentBuild>"
$JenkinsJobAntBuildBeforeTargets = "<builders><hudson.tasks.Ant plugin=`"ant@$AntPluginVersion`"><targets>"
$JenkinsJobAntBuildAfterTargets = "</targets></hudson.tasks.Ant></builders>"
$JenkinsJobPublishersStart = "<publishers>"
$JenkinsJobPublisherJUnit = "<hudson.tasks.junit.JUnitResultArchiver plugin=`"junit@$JUnitPlugInVersion`"><testResults>results/*/*.xml</testResults><keepLongStdio>false</keepLongStdio><healthScaleFactor>1.0</healthScaleFactor><allowEmptyResults>false</allowEmptyResults></hudson.tasks.junit.JUnitResultArchiver>"
$JenkinsJobPublisherCucumberBeforeJsonFile = "<org.jenkinsci.plugins.cucumber.jsontestsupport.CucumberTestResultArchiver plugin=`"cucumber-testresult-plugin@$CucumberPlugInVersion`"><testResults>"
$JenkinsJobPublisherCucumberAfterJsonFile = "</testResults><ignoreBadSteps>false</ignoreBadSteps></org.jenkinsci.plugins.cucumber.jsontestsupport.CucumberTestResultArchiver>"
$JenkinsJobPublisherCheckStyle = "<hudson.plugins.checkstyle.CheckStylePublisher plugin=`"checkstyle@$CheckStylePlugInVersion`"><healthy></healthy><unHealthy></unHealthy><thresholdLimit>low</thresholdLimit><pluginName>[CHECKSTYLE] </pluginName><defaultEncoding></defaultEncoding><canRunOnFailed>false</canRunOnFailed><usePreviousBuildAsReference>false</usePreviousBuildAsReference><useStableBuildAsReference>false</useStableBuildAsReference><useDeltaValues>false</useDeltaValues><thresholds plugin=`"analysis-core@$AnalysisCorePlugInVersion`"><unstableTotalAll></unstableTotalAll><unstableTotalHigh></unstableTotalHigh><unstableTotalNormal></unstableTotalNormal><unstableTotalLow></unstableTotalLow><unstableNewAll></unstableNewAll><unstableNewHigh></unstableNewHigh><unstableNewNormal></unstableNewNormal><unstableNewLow></unstableNewLow><failedTotalAll></failedTotalAll><failedTotalHigh></failedTotalHigh><failedTotalNormal></failedTotalNormal><failedTotalLow></failedTotalLow><failedNewAll></failedNewAll><failedNewHigh></failedNewHigh><failedNewNormal></failedNewNormal><failedNewLow></failedNewLow></thresholds><shouldDetectModules>false</shouldDetectModules><dontComputeNew>true</dontComputeNew><doNotResolveRelativePaths>false</doNotResolveRelativePaths><pattern>results/checkstyle-result.xml</pattern></hudson.plugins.checkstyle.CheckStylePublisher>"
$JenkinsJobPublishersAndProjectEnd = "</publishers><buildWrappers/></project>"
function Create-JenkinsJob($jobName, $antTargets, $publishCucumber, $buildJob)
{
	Write-Host "> $jobName"
	Run-JenkinsCLI "delete-job `"$jobName`""
	$repositoryName = $jobName -replace " ",""
	$repositoryName = "$InstallDirectory\Repos\$repositoryName.git"
	$jobContent = $JenkinsJobStandardBeforeGitDirectory + $repositoryName + $JenkinsJobStandardAfterGitDirectoryBeforeTriggers + $JenkinsJobScmTriggers + $JenkinsJobStandardAfterTriggersBeforeBuilders + $JenkinsJobAntBuildBeforeTargets + $antTargets + $JenkinsJobAntBuildAfterTargets + $JenkinsJobPublishersStart + $JenkinsJobPublisherJUnit
	if ($publishCucumber) { $jobContent = $jobContent + $JenkinsJobPublisherCucumberBeforeJsonFile + "results/Cucumber.json" + $JenkinsJobPublisherCucumberAfterJsonFile }
	$jobContent = $jobContent + $JenkinsJobPublisherCheckStyle + $JenkinsJobPublishersAndProjectEnd
	Send-ToJenkins "create-job `"$jobName`"" $jobContent
	if ($buildJob)
	{
		Run-JenkinsCLI "build `"$jobName`" -f"
	}
}
Create-JenkinsJob "Build Data Warehouse" "clean build test style" $false $false
Create-JenkinsJob "GreenMart" "clean build test style" $false $true
Create-JenkinsJob "Web Services" "clean build unit cucumber soapui style" $true $true

Write-Host "> Web Services UI Tests"
Run-JenkinsCLI "delete-job `"Web Services UI Tests`""
$jobContent = $JenkinsJobStandardBeforeGitDirectory + "$InstallDirectory\Repos\WebServices.git" + $JenkinsJobStandardAfterGitDirectoryBeforeTriggers + $JenkinsJobUpstreamTriggerBeforeProjectName + "Web Services" + $JenkinsJobUpstreamTriggerAfterProjectName + $JenkinsJobStandardAfterTriggersBeforeBuilders + $JenkinsJobAntBuildBeforeTargets + "clean build selenium cucumberui" + $JenkinsJobAntBuildAfterTargets + $JenkinsJobPublishersStart + $JenkinsJobPublisherJUnit + $JenkinsJobPublisherCucumberBeforeJsonFile + "results/CucumberUI.json" + $JenkinsJobPublisherCucumberAfterJsonFile + $JenkinsJobPublishersAndProjectEnd
Send-ToJenkins "create-job `"Web Services UI Tests`"" $jobContent
Run-JenkinsCLI "build `"Web Services UI Tests`" -f"

# Add history to the Build Data Warehouse job in Jenkins
Write-Host "Adding history to the Build Data Warehouse job in Jenkins"
Rename-Item "$InstallDirectory\Repos\BuildDataWarehouse.git\hooks\post-receive" "$InstallDirectory\Repos\BuildDataWarehouse.git\hooks\post-receive.old"
git config -l | find `"user.name`" | Out-Null
if ($LastExitCode -ne 0)
{
	git config --global user.name "User"
	git config --global user.email "user@user.com"
}
git clone Repos\BuildDataWarehouse.git BDW 2>&1 | Out-Null
cd BDW
function Update-BuildDataWarehouse($testFileName)
{
	Write-Host '>' -NoNewLine
	Copy-Item "$InstallDirectory\Preparation\$testFileName" "test\BuildDataWarehousePresenterTest.java" -Force
	git add . | Out-Null
	$updateNumber = $testFileName.Substring($testFileName.Length - 6, 1)
	git commit -m "Update $testFileName" | Out-Null
	git push origin master 2>&1 | Out-Null
	Run-JenkinsCLI "build `"Build Data Warehouse`" -f"
}
Get-ChildItem $ThisScriptDirectory\*.java | % { Update-BuildDataWarehouse $_.Name }
Write-Host
cd ..
Remove-Item BDW -Recurse -Force
Rename-Item "$InstallDirectory\Repos\BuildDataWarehouse.git\hooks\post-receive.old" "$InstallDirectory\Repos\BuildDataWarehouse.git\hooks\post-receive"

# Stop Jenkins
Write-Host "Stopping Jenkins"
Write-Host "If this doesn't finish, just close the window"
Run-JenkinsCLI "safe-shutdown"
while ($true)
{
	$o = $Jenkins.StandardError.ReadLine()
	if ($o -eq "INFO: JVM is terminating. Shutting down Winstone") { break }
}

# Delete jenkins-cli.jar
Write-Host "Deleting jenkins-cli.jar"
Remove-Item jenkins-cli.jar

if ($PauseAtEnd) { Read-Host "Done" }
