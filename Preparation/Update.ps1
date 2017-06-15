Write-Host "Update WebServices ..."
Write-Host
Write-Host "Please make sure that Jenkins is running before continuing." -ForegroundColor White
Write-Host
Read-Host "Press <Enter> to continue" | Out-Null

function Replace-InFile($fileName, $match, $replace)
{
	(Get-Content $fileName) -replace $match, $replace | Set-Content $fileName
}

$gitConfig = git config -l
if (!($gitConfig -match "user.name"))
{
	Write-Host "Configuring Git user"
	git config --global user.name "Developer"
	git config --global user.email "developer@softed.com"
}

Write-Host "Updating ValidateCardHandler"
git clone ..\Repos\WebServices.git WS
cd WS
Replace-InFile "src\main\java\webservices\CardValidator.java" "status.name\(\);" "status.name().replace('_',' ');"
Replace-InFile "src\main\java\webservices\CardValidator.java" "return message;" "return message + '.';"
Replace-InFile "src\main\java\webservices\ValidateCardHandler.java" "INVALID_PARAMETER.name\(\);" "INVALID_PARAMETER.name().replace('_',' ');"
Replace-InFile "src\test\java\unit\CardValidatorTest.java" '_' ' '
git add .
git commit -m "Status codes and messages made more friendly by replacing the underscores with spaces and adding a period to the end of the message."
git push origin master
cd ..
Remove-Item WS -Recurse -Force

Write-Host "The Jenkins project should now be building."
Write-Host "Once it has finished, the project is ready."
Read-Host "Press <Enter> to continue" | Out-Null
