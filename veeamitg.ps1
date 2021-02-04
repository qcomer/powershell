#####################################################################
$APIKEy = "ITG.88109d3af56a0f3f45a3476a2da3bc12.Mz68t5IGnFllu5yDIXEtGuj4W5IoxxoKwJwyDgD1zXU1d-0ffZRYznhnIRxt6BHf"
$APIEndpoint = "https://api.itglue.com"
$orgID = "478188"
$FlexAssetName = "Veeam Backup][Auto]"
$Description = "All configuration settings for VBR"
$TableStyling = "<th>", "<th style=`"background-color:#4CAF50`">"
#####################################################################
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if(!(Get-PackageProvider -Name "Nuget"))
{Install-PackageProvider -Name "Nuget" -Force}
If (Get-Module -ListAvailable -Name "ITGlueAPI") {
Import-module ITGlueAPI }
Else 
{install-module ITGlueAPI -Force; import-module ITGlueAPI }

Add-ITGlueBaseURI -base_uri $APIEndpoint
Add-ITGlueAPIKey $APIKEy
#Checking if the FlexibleAsset exists. If not, create a new one.
$FilterID = (Get-ITGlueFlexibleAssetTypes -filter_name $FlexAssetName).data
if (!$FilterID) { 
    $NewFlexAssetData = 
    @{
        type          = 'flexible-asset-types'
        attributes    = @{
            name        = $FlexAssetName
            icon        = 'sitemap'
            description = $description
        }
        relationships = @{
            "flexible-asset-fields" = @{
                data = @(
                    @{
                        type       = "flexible_asset_fields"
                        attributes = @{
                            order           = 1
                            name            = "Backup Job Name"
                            kind            = "Text"
                            required        = $true
                            "show-in-list"  = $true
                            "use-for-title" = $true
                        }
                    },
                    @{
                        type       = "flexible_asset_fields"
                        attributes = @{
                            order          = 2
                            name           = "Protected Servers"
                            kind           = "Text"
                            required       = $false
                            "show-in-list" = $true
                        }
                    },
                    @{
                        type       = "flexible_asset_fields"
                        attributes = @{
                            order          = 3
                            name           = "Job Type"
                            kind           = "Textbox"
                            required       = $false
                            "show-in-list" = $true
                        }
                    },
                    @{
                        type       = "flexible_asset_fields"
                        attributes = @{
                            order          = 4
                            name           = "Job Schedule"
                            kind           = "Textbox"
                            required       = $false
                            "show-in-list" = $talse
                        }
                    }
                )
            }
        }
                 
    }
    New-ITGlueFlexibleAssetTypes -Data $NewFlexAssetData
    $FilterID = (Get-ITGlueFlexibleAssetTypes -filter_name $FlexAssetName).data
}
Add-PSSnapin VeeamPSSnapin
Connect-VBRServer
$BackupJobList = Get-VBRJob | ?{$_.isscheduleenabled -eq "True"}
$BackupJobInfo = foreach ($Backup in $BackupJobList) {
    $JobName = $Backup.Name
    #$ProtectedServers = Get-VBRObject -Job $JobName  | %{$TaggedResource = (Get-ITGlueConfigurations -organization_id $ITGlueOrgID -filter_name $_.Name).data}
    $ProtectedServers = Get-VBRjobObject -Job $JobName
    $JobType = Get-VBRJob -Name $Backup | Select TypeToString
    #$jobSchedule = Get-VBRJobScheduleOptions -Job $JobName | Select $_.StartDateTimeLocal.ToString("hh:mm tt")
    #,@{N='Job End';E={$($Backup.EndDateTimeLocal.ToString("hh:mm tt"))}},RepeatNumber,RepeatTimeUnit,RetryTimes,@{N='Daily Option';E=$($backup.OptionsDaily.Enabled)},@{N='Daily Schedule';E=$($Backup.OptionsDaily.DayNumberinMonth)}
    #$jobScheduleHTML = ($jobschedule | convertto-html -fragment | out-string) -replace $TableStyling
}
 
foreach ($BackupItem in $BackupJobInfo) {
    $FlexAssetBody = 
    @{
        type       = 'flexible-assets'
        attributes = @{
            name   = $FlexAssetName
            traits = @{
                "backup-job-name"       =$BackupItem.JobName
                "protected-servers"     = $BackupItem.ProtectedServers
                "job-type"        = $BackupItem.JobType
                "job-schedule" = ""
                }
            }
        }
    }
     
 
    #Upload data to IT-Glue. We try to match the Server name to current computer name.
    $ExistingFlexAsset = (Get-ITGlueFlexibleAssets -filter_flexible_asset_type_id $Filterid.id -filter_organization_id $orgID).data | Where-Object { $_.attributes.traits.name -eq $BackupItem.JobName }
    #If the Asset does not exist, we edit the body to be in the form of a new asset, if not, we just upload.
    if (!$ExistingFlexAsset) {
        $FlexAssetBody.attributes.add('organization-id', $orgID)
        $FlexAssetBody.attributes.add('flexible-asset-type-id', $FilterID.id)
        Write-Host "Creating new flexible asset"
        New-ITGlueFlexibleAssets -data $FlexAssetBody
        #Set-ITGlueFlexibleAssets -id $newID.ID -data $Attachment
    }
    else {
        Write-Host "Updating Flexible Asset"
        $ExistingFlexAsset = $ExistingFlexAsset | select-object -last 1
        Set-ITGlueFlexibleAssets -id $ExistingFlexAsset.id  -data $FlexAssetBody
    }
