---
external help file: invoke-mimecast-help.xml
Module Name: invoke-mimecast
online version:
schema: 2.0.0
---

# Install-Mimecast

## SYNOPSIS
Installs the Mimecast for Outlook plugin

## SYNTAX

```
Install-Mimecast [[-64bit_msi_Name] <String>] [[-32bit_msi_Name] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Mimecast for Outlook plugin requires that Outlook be closed before installation. 
It also requires that the 32 bit version of the plugin be installed
if the installed Microsoft Office version is 32 bit. 
Likewise, if the installed Microsoft Office version is 64 bit, then the 64bit version of the Mimecast plugin needs to be installed.
This PowerShell script takes care of all of this.

## EXAMPLES

### EXAMPLE 1
```
Install-Mimecast -64bit_msi_Name "x64_Mimecast.msi"
```

### EXAMPLE 2
```
Install-Mimecast -32bit_msi_Name "x32_Mimecast.msi"
```

## PARAMETERS

### -64bit_msi_Name
The name of the 64 bit msi including the .msi extension.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Mimecast for outlook 7.7.0.362 (64 Bit).msi
Accept pipeline input: False
Accept wildcard characters: False
```

### -32bit_msi_Name
The name of the 32 bit msi including the .msi extension.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Mimecast for outlook 7.7.0.362 (32 Bit).msi
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
SCCM usage: Place this script and both msi's (32 and 64 bit) in the same source folder on your sccm server and create a new Application which deploys this script.
Example:for Installation Program use the following:  powershell.exe -executionpolicy bypass -file ".\install-mimecast.ps1"
Created by: OH
Date: 12-Oct-2018

#13-June-2019 - Version 1.1 - Added checking for O365 ProPlus installation

## RELATED LINKS
