$username=$env:username
$domain=$env:userdomain
$temp=$env:temp
$photo = ([ADSISEARCHER]"samaccountname=$($username)").findone().properties.thumbnailphoto
if($photo -eq $null)
{
exit
}
else
{
$photo | set-content $temp\$domain+$username.jpg -Encoding byte
$command = "\\paradise.usd\\netlogon\usertile.exe $domain\$username $temp\$domain+$username.jpg"
}
cmd /c $command
