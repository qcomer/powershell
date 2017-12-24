<# TO DO LIST
Need to do:
-Remove withdrawn students from aeries
-clear out student files when withdrawn

#Set-ADAccountPassword $samid -NewPassword (ConvertTo-SecureString $PW -AsPlainText -force) -Reset

#>

<# INFORMATION
Updated 2013-11-13 2:27PM Pacific - Justin Cooper
 .Synopsis
    Active Directory student account and home directory modification and creation.
 .DESCRIPTION
    This script queries and SQL DB and created Student Active Directory User accounts and home directories from the results.
 .EXAMPLE
    Example of how to use this workflow
 .EXAMPLE
    Another example of how to use this workflow
 .INPUTS
	When Automating this script as a scheduled task please keep input files in the same directory as the script itself.
	Mandatory and in order on the powershell command line:
    Aeries SQL Server
	Aeries SQL DB
	Aeries Read-Only DB Account
	Aeries DB account password
	SQL txt-based query file
	LookUpTable txt/csv file
	LogFile to output results, INFO, and possible ERROR
 .OUTPUTS
    Student Active Directory User accounts and home directories are created.
 .NOTES
    Needs AD ADmin tools locally installed or run on a DC with PowerShell v2+
    Please keep associated files in the scripts root dir
	The account running the script must have permissions to:
		-Add/Move AD UserObjects
		-Modify Groups Memberships on AD Group Objects 
		-Create folders and set permissions on target Home folders.
		-Write access to the log file
 THe site lookup CSV file's columns headers are formatted as such:
SiteCode|SiteName|StudentOU|StaffSecurityGroup|StudentSecurityGroup|StudentHomeDir|8e6SecurityGroup
 .FUNCTIONALITY
    
 #>
Param(	
	[Parameter(Mandatory=$True)][ValidateNotNull()][STRING]$SCRIPT:AeriesServer,
	[Parameter(Mandatory=$True)][ValidateNotNull()][STRING]$SCRIPT:AeriesDB,
	[Parameter(Mandatory=$True)][ValidateNotNull()][STRING]$SCRIPT:AeriesDBAccount,
	[Parameter(Mandatory=$True)][ValidateNotNull()][STRING]$SCRIPT:AeriesPassword,
	[Parameter(Mandatory=$True)][ValidateNotNull()][String]$SCRIPT:sqlFile,
	[Parameter(Mandatory=$True)][ValidateNotNull()][STRING]$SCRIPT:ltTableFile,
	[Parameter(Mandatory=$True)][ValidateNotNull()][STRING]$SCRIPT:logFile
)
#CLS
#Begin Checking Snappins and modules
	IF ( !(Get-Module -ListAvailable | where {$_.Name -eq 'ActiveDirectory'}) )
	{
		Write-Host "Active Directory Tools not installed on $ENV:COMPUTERNAME`nScript Terminating" -ForeGroundColor Red
		Add-Content $logFile -value "$(Get-Date) [ERROR] Active Directory Tools not installed on $ENV:COMPUTERNAME`nScript Terminating"
	}
	ELSEIF ( !(Get-Module -Name ActiveDirectory) ) 
	{
		Import-Module ActiveDirectory
	}
#End Checking Snappins and modules
#Setting Script's Working Directory
	$cwd = Split-Path $MyInvocation.MyCommand.Path
	CD $cwd
	#sleep 30
#script variables
	$lookUpTable = Import-Csv $ltTableFile -Delimiter "|"
	$Query = Get-Content $sqlFile
#script functions

    function Add-HomeDirectory 
	{
        Param(
            [String]$f_homeRoot,
            [String]$f_homeDir,
			[String]$f_favDir,
            [String]$f_samid,
            [String]$f_StaffSecurityGroup
        )
        #Create Home Directory
        $homeTest = Test-Path $f_homeDir
        IF ( $homeTest -ne $True ) {
            Write-Host "Creating Directory" -ForegroundColor DarkGreen
			MD $f_homeRoot
            MD $f_homeDir
			MD $f_favDir
			#Set Homedir ACL's
			ICACLS $f_homeRoot /inheritance:r /grant "Domain Admins:(OI)(CI)(F)" "${f_StaffSecurityGroup}:(OI)(CI)(M)" "${f_samid}:(OI)(CI)(RX)"
			ICACLS $f_homeDir /inheritance:r /grant "Domain Admins:(OI)(CI)(F)" "${f_StaffSecurityGroup}:(OI)(CI)(M)" "${f_samid}:(OI)(CI)(M)"
			ICACLS $f_favDir /inheritance:r /grant "Domain Admins:(OI)(CI)(F)" "${f_StaffSecurityGroup}:(OI)(CI)(M)" "${f_samid}:(OI)(CI)(M)"
			#Log Home Directory Creation
			Add-Content $logFile -value "$(Get-Date) [INFO] $homeDir created"

        }
        ELSE { 
            Write-Host "Directory $homeDir already exists." -ForegroundColor Green
        }
    }
    function Add-UsertoADGroups
    {
        Param(
            [String]$f_samid,
            [String]$f_group1
            #,[String]$f_group2  #For adding to second group in future use
        )
        Write-Host "Setting Groups..."-ForegroundColor Green
        Add-ADGroupMember -Identity $f_group1 -Members $f_samid
        #Add-ADGroupMember -Identity $f_group2 -Members $f_samid	#For adding to second group in future use
    }
	#Removed function from foreach due to static value for Default Password. See Line 192.
	function Set-DefaultPassword
	{
		param(
			[STRING]$f_samid
		)
		Write-Host "Setting Default Password..." -ForeGroundColor Yellow
		Set-ADAccountPassword $f_samid -NewPassword (ConvertTo-SecureString "Password1" -AsPlainText -force) -Reset
	}
	Function Add-ADPhotoThumbnail
	{ 
		PARAM(
		[STRING]$F_SAMID,
		[STRING]$F_PICPATH
		)
		#Write-Host $F_SAMID -ForegroundColor Yellow
		#Write-Host $F_PICPATH -ForegroundColor Yellow
		$PhotoPath = Test-Path $F_PICPATH
		#Write-Host $PhotoPath -ForegroundColor Green
		if ( $PhotoPath -eq $TRUE)	#Photo is found
		{
			Write-Host "Setting Active Directory Thumbnail Photo" -ForegroundColor DarkGreen
			[byte[]] $jpg  = Get-Content $PICPATH -encoding byte
			Set-AdUser $F_SAMID -Replace @{thumbnailphoto=$jpg}
		}
		else	#If no photo is found
		{
			Write-Host "No photo found" -ForegroundColor Yellow
		}
	}
	

#Connect and Query Aeries Database and set results to a PS object "$dbResults"
	$ServerInstance = "$AeriesServer "
	$Database = "$AeriesDB "
	$ConnectionTimeout = 30
	$QueryTimeout = 120
	$conn=new-object System.Data.SqlClient.SQLConnection
	$ConnectionString = "Server={0};Database={1};Connect Timeout={2};User Id = $AeriesDBAccount; Password = $AeriesPassword" -f $ServerInstance,$Database,$ConnectionTimeout
	$conn.ConnectionString=$ConnectionString
	$conn.Open()
	$cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn)
	$cmd.CommandTimeout=$QueryTimeout
	$ds=New-Object system.Data.DataSet
	$da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
	[void]$da.fill($ds)
	$conn.Close()
	$dbResults = $ds.Tables.Rows | Select-Object -Property ln,fn,id,sc,ed,gr
#Set Counter
	$i = $dbResults | measure | select -Property count
	$i = $i.count

#Log Begin
	Add-Content $logFile -value "`nScript Begin - $(Get-Date) `nRunning as:$ENV:USERNAME`nScript Parameters: $AeriesServer $AeriesDB $AeriesDBAccount DBPASSWORDEXCLUDED $sqlFile $ltTableFile $logFile"

#Begin Parse Database Query Results
ForEach ( $dbRow in $dbResults ) 
{
	#CLS
	#Set User Related Variables
	$PW = "Password1"
	$UP = "@paradise.usd"
    $FN = $dbRow.FN
    $LN = $dbRow.LN
    $ID = $dbRow.ID
    $SC = $dbRow.SC
    $ED = $dbRow.ED
	$GR = $dbRow.GR
    $samid = $FN.substring(0,1)+$LN.substring(0,1)+$ID
	$date = Get-Date
	$PICPATH = "\\205.155.197.40\photos$\"+$ID+".jpg"
	#Write-host `n $i $samid `n -ForegroundColor Yellow
	$i--
	#Begin Check Site Code 
    ForEach ( $dbRow2 in $dbResults ) 
	{
        #Older and non-matching results are filter out here
        IF ( ($dbRow.ID -eq $dbRow2.ID) -and ($dbRow.ED -ge $dbRow2.ED) ) 
        {
            #Begin Parse LookUpTable
			ForEach ( $ltRow in $lookUpTable ) 
			{
				#Compare LookUpTable SiteCode to Aeries Result SiteCode
				IF ( $ltRow.SiteCode -eq $dbRow.SC ) 
				{
					#Set table-related variables
					$desc = $ltRow.SiteName+" Student"
					$OU =  $ltRow.StudentOU
					$homeRoot = $ltRow.StudentHomeDir+'\'+$samid
					$homeDir = $ltRow.StudentHomeDir+'\'+$samid+"\Documents"
					$favDir = $ltRow.StudentHomeDir+'\'+$samid+"\Favorites"
					$StaffSecurityGroup = $ltRow.StaffSecurityGroup
					$studentSecurityGroup = $ltRow.StudentSecurityGroup
					#$8e6SecurityGroup = $ltRow."8e6SecurityGroup"
				}
			}
            #End Parse LookUpTable
			#Creates object "$userObj" with "memberof" property included
            $userObj = Get-ADUser -LDAPFilter "(sAMAccountName=$samid)" -Properties memberof
			#Check AD for $userObj
            IF ( $userObj -eq $NULL )		#If User does not exist
            {
                #Create New User Object
                Write-Host "Creating User Account..." -ForegroundColor DarkGreen
				$descNew = "Created on: " + $date + " "+$FN+" "+$LN
                New-ADUser `
					-Name $samid `
					-DisplayName $samid `
					-SamAccountName $samid `
					-GivenName $FN `
					-SurName $LN `
					-UserPrincipalName $samid `
					-AccountPassword (ConvertTo-SecureString $PW -AsPlainText -force) `
					-PasswordNeverExpires $False `
					-CannotChangePassword $False `
					-Path $OU `
					-Enabled $True 
				Set-ADUser $samid -Description $descNew -ChangePasswordAtLogon $true -employeeID $ID
				#Set User Picture
				Add-ADPhotoThumbnail $samid $PICPATH
				
                #BEGIN Security Group(s) modification
                Add-UsertoADGroups $samid $studentSecurityGroup #Student Security Group
				IF ($SC -eq "8") #If student is at PineRidge, check grade for filter group
				{
					IF ($GR -le 5)
					{
						Write-Host " Adding to K-5 filter group..." -ForegroundColor Magenta
						Add-UsertoADGroups $samid "8e6_K-5" #K-5 Filter Security Group
					}
					ELSEIF ($GR -ge 6 -and $GR -le 12)
					{
						Write-Host " Adding to 6-12 filter group..." -ForegroundColor Magenta
						Add-UsertoADGroups $samid "8e6_6-12" #6-12 Filter Security Group
					}
				}
				#END Security Group(s) modification
				
				#BEGIN Check Object
				#Maximum wait time for each creation and propagation is 60 seconds.
				$i2 = 60
				Write-Host "`nWaiting for $samid UserObject to be created and replicated...`n" -ForegroundColor Yellow
				DO { Sleep 1; $i2-- }
				UNTIL ( $i2 -le 0 -or (Get-ADUser -LDAPFilter "(sAMAccountName=$samid)" -searchbase $OU ) )
				$userObj = Get-ADUser -LDAPFilter "(sAMAccountName=$samid)" -Properties memberof
				#If something goes really wrong the script ends and outputs an error to the log file.
				IF ( $userObj -eq $NULL ) 
				{
					#WARNING - This is an EXIT to catch errors in AD user object creation and prevent cascading account and folder creation issues.
					Write-host "User Object not created as expected!`nLogging error." -ForeGRoundColor Red
					Add-Content $logFile -value "$(Get-Date) [ERROR] Object not created,$samid"
					Add-Content $logFile -value "$(Get-Date) [FATAL ERROR] Script Process Terminating"
					EXIT
				}
				#End Check Object
				ELSE {
					#Display and log successful AD user object creation
					Write-host "`nUser Object created!" -ForeGRoundColor DarkGreen
					Add-Content $logFile -value "$(Get-Date) [INFO] $samid created - $desc"
				}
            }
            ELSEIF ( $userObj.DistinguishedName -notlike "*$OU*" )		#If User has moved to new school
            {
                #Move User Object
                Write-Host "Moving User Account..." -ForegroundColor Magenta
                $userObj | Move-ADObject -TargetPath $OU
				Write-Host "Resetting AD LDAP Account Info..." -ForegroundColor Magenta
				$descMove = "Moved on:  " + $date+" "+$FN+" "+$LN
                Set-ADUser `
					-Identity $samid `
					-DisplayName $samid `
					-GivenName $FN `
					-SurName $LN `
					-UserPrincipalName $samid
				Set-ADUser $samid -Description $descMove
                #Clear Old Groups
                ForEach ( $groupCN in $userObj.MemberOf )
				{
					IF ( $groupCN -notlike "*Domain User*" )
					{
                        Write-Host "Removing from group..." $groupCN -ForegroundColor Magenta
                        Remove-ADGroupMember -identity (Get-ADGroup -LDAPFilter "(DistinguishedName=$groupCN)" -property Name) -Members $samid -Confirm:$false
                    }
				}
                #Security Groups
				Write-Host "Adding to group..." $studentSecurityGroup -For/egroundColor Magenta
                Add-UsertoADGroups $samid $studentSecurityGroup #Student Security Group
				IF ($SC -eq "8") #If student is at PineRidge, check grade for filter group
				{
					IF ($GR -le 5)
					{
						Write-Host " Adding to K-5 filter group..." -ForegroundColor Magenta
						Add-UsertoADGroups $samid "8e6_K-5" #K-5 Filter Security Group
					}
					ELSEIF ($GR -ge 6 -and $GR -le 12)
					{
						Write-Host " Adding to 6-12 filter group..." -ForegroundColor Magenta
						Add-UsertoADGroups $samid "8e6_6-12" #6-12 Filter Security Group
					}
				}

				#Display and log AD user object move
				Write-host "`nUser Object moved." -ForeGRoundColor DarkGreen
				Add-Content $logFile -value "$(Get-Date) [INFO] $samid moved to $desc"

            }
            #Create HomeDir using Add-HomeDirectory function
            Add-HomeDirectory $homeRoot $homeDir $favDir $samid $StaffSecurityGroup
			#SLEEP 1
        }
    }
    #Begin Check Site Code 
}
#End Parse Database Query Results
#Log End
	Add-Content $logFile -value "Script End - $(Get-Date)"
#CLS
Write-Host "Script Completed - $(Get-Date)`n" -ForeGroundColor Yellow
#Script End