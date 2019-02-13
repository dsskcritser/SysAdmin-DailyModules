
function Get-MBXCleanupStatus ($DBName) {
    $StartTime = Get-Date -f g
    Write-Host  "Getting Database Status Info on $DBName at $starttime" -ForegroundColor White -BackgroundColor DarkRed 
    
    Get-MailboxDatabaseCopyStatus $DBName | ft -AutoSize
    Get-MailboxDatabase $DBName -Status | Select-Object Name, AvailableNewMailboxSpace | Format-Table -AutoSize
}
function Get-NonInheritedMailboxDBPermissions ($DBName) {
    # 
    $StartTime = Get-Date -f g
    Write-Host  "Getting Non Inherited Permissions on Database $DBName at $starttime" -ForegroundColor White -BackgroundColor DarkRed 
    get-mailboxdatabase $DBName | Get-Adpermission | Where {$_.IsInherited -eq $false} | ft -a
}

function Get-NonInheritedMailboxPermissions ($mailbox) {
    Get-MailboxPermission $mailbox | where {$_.IsInherited -ne “True”}| ft User,IsInherited,AccessRights -auto
}
]
function Decode-ProofPointURL([string]$URL) {
    $strDecoded = $URL
    $RegEx = '&d=DwMFAw'

    $strDecoded = $strDecoded.replace("https://urldefense.proofpoint.com/v2/url?u=","")
    $strDecoded = ($strDecoded -split $RegEx)[0]
    $strDecoded = $strDecoded.replace("-3A",":")
    $strDecoded = $strDecoded.replace("_","/")
    $strDecoded = $strDecoded.replace("-5F","_")
    $strDecoded = $strDecoded.replace("-3F","?")
    $strDecoded = $strDecoded.replace("-3D","=")
    $strDecoded = $strDecoded.replace("-40","@")
    $strDecoded = $strDecoded.replace("-21","!")
    $strDecoded = $strDecoded.replace("-22","`"")
    $strDecoded = $strDecoded.replace("-23","#")
    $strDecoded = $strDecoded.replace("-24","`$")
    $strDecoded = $strDecoded.replace("-25","`%")
    $strDecoded = $strDecoded.replace("-26","`&")
    $strDecoded = $strDecoded.replace("-27","`'")
    $strDecoded = $strDecoded.replace("-28","(")
    $strDecoded = $strDecoded.replace("-29",")")
    $strDecoded = $strDecoded.replace("-2A","*")
    $strDecoded = $strDecoded.replace("-2B","+")
    $strDecoded = $strDecoded.replace("-2C",",")
    $strDecoded = $strDecoded.replace("-2D","-")
    $strDecoded = $strDecoded.replace("-2E",".")
    $strDecoded = $strDecoded.replace("-2F","/")
    $strDecoded = $strDecoded.replace("-5B","[")
    $strDecoded = $strDecoded.replace("-5C","\")
    $strDecoded = $strDecoded.replace("-5D","]")
    $strDecoded = $strDecoded.replace("-5E","^")
    $strDecoded = $strDecoded.replace("-5F","_")
    $strDecoded = $strDecoded.replace("-3A",":")
    $strDecoded = $strDecoded.replace("-3B",";")
    $strDecoded = $strDecoded.replace("-3C","<")
    $strDecoded = $strDecoded.replace("-3D","=")
    $strDecoded = $strDecoded.replace("-3E",">")
    $strDecoded = $strDecoded.replace("-3F","?")
    $strDecoded = $strDecoded.replace("-40","@")

    Write-host ""
    Write-host "#################################" -foregroundcolor green
    Write-host "######### " -nonewline -foregroundcolor green
    Write-host "Decoded URL " -nonewline -foregroundcolor yellow
    Write-host "############" -foregroundcolor green
    Write-host "#################################" -foregroundcolor green
    Write-host ""
    Write-host " [+] " -nonewline -foregroundcolor green
    Write-host "$strDecoded" -foregroundcolor yellow
}
Function Remove-EmailUsingProofPointList
{
	Function Get-FileName($initialDirectory)
	{   
	 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	 $OpenFileDialog.initialDirectory = $initialDirectory
	 $OpenFileDialog.filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
	 $OpenFileDialog.ShowDialog() | Out-Null
	 $OpenFileDialog.filename
	}
	$ProofPointCSVFile = Get-FileName -initialDirectory "c:\" 
	$ProofPointCSVExport = Import-Csv "$($ProofPointCSVFile)"
	[string]$CurrentDate = $(get-date -Format yyyyMMdd-HHmm)

	foreach ($Line in $ProofPointCSVExport)
	{
		#$Line.Sender
		#$Line.Sender_Host
		#$Line.Recipients
		#$Line.Subject
		#$Line.Date
		#$Line.Message_ID

		if ($Line.Recipients -notmatch ",")
		{
			# 1 Recipient
			# in future check if the mailbox is the spam mailbox
            [string]$CMDToRun = "Search-Mailbox -Identity `"$($Line.Recipients)`" -SearchQuery subject:`'$($Line.Subject)`',from:`"$($Line.Sender)`" -TargetMailbox spam.email@jbssa.com -TargetFolder `"$($CurrentDate)`" -SearchDumpster -LogLevel Full -DeleteContent -Force"
            Write-Host "I'd run ... $CMDToRun"
			Invoke-Expression "$CMDToRun"
		}
		else
		{
			foreach ($Recipient in [array]$($Line.Recipients.Split(",")))
			{
				# Many Recipients
				# in future check if the mailbox is the spam mailbox
				[string]$CMDToRun = "Search-Mailbox -Identity `"$($Recipient)`" -SearchQuery subject:`'$($Line.Subject)`',from:`"$($Line.Sender)`" -TargetMailbox spam.email@jbssa.com -TargetFolder `"$($CurrentDate)`" -SearchDumpster -LogLevel Full -DeleteContent -Force"
                Write-Host "I'd run ... $CMDToRun"
                Invoke-Expression "$CMDToRun"
			}
		}
	}
}

<# 
New Function - MailboxInfo from List


$masterList = gc "C:\temp\5Rivers-Round1.txt"

foreach ($5rmbx in $masterlist) { 
    Try { $mbxstatTotal = get-mailboxstatistics $5rmbx -EA Stop | %{$_.TotalItemSize.Value.ToMB()} }
        Catch { $mbxstatTotal = "DNE-Error" }
    Try { $mbxstatDeleted = get-mailboxstatistics $5rmbx -EA Stop | %{$_.TotalDeletedItemSize.Value.ToMB()} }
        Catch { $mbxstatDeleted = "DNE-Error" }
    $value = $5rmbx+", "+$mbxstatTotal+",",$mbxstatDeleted
    $value >> C:\Temp\TestList.csv
}


}

#>


function Get-MBXSize {
    [CmdletBinding()]
    param (
        [string]$ImportFileName = $null
    )
    
    begin {
        # No export file specified
        if ($ExportFile -eq $null) { 
            
        }
    }
    
    process {
        if ($ImportFileName -ne $null)  {


        }
    
    
    
    }
    
    end {
    }
}

function Fix-IMCEAEX-NDR {
    <#
    .SYNOPSIS
    Exports a list of commands to add X500 addresses using legacyExchangeDNs extracted from NDRs.
    .DESCRIPTION
    Takes a csv file with 2 columns (IMCEAEX,Account) and exports a list of commands to add X500 addresses to respective accounts. Does not support recipient type MailNonUniversalGroup.
    .EXAMPLE
    Fix-IMCEAEX-NDR "c:\users\admin\desktop\accounts.csv" | Out-File commands.ps1
    .NOTES
    Script written by Matthew Huynh <mahuynh@microsoft.com> for MSSOLVE case 113101510864368.
    .LINK
    http://support.microsoft.com/kb/2807779
    #>
    
  [CmdletBinding()]
  Param(
  [Parameter(Mandatory=$true,Position=1)]
  [string]$csvFile
  )
  
  Write-Verbose "Importing csv file..."
  $userList = Import-Csv $csvFile
  
  foreach ($user in $userList) {
  
      $exchangeLegDN = CleanLegacyExchangeDN($user.IMCEAEX)
      $x500address = "X500:$exchangeLegDN"
  
      # check what recipient type is
      $recipientType = (Get-Recipient $user.Account).RecipientType
  
      # format command appropriately
      switch ($recipientType) {
          "DynamicDistributionGroup" {$command = "Set-DynamicDistributionGroup `"$($user.Account)`" -EmailAddresses @{Add=`"$x500address`"}"}
          "MailUniversalDistributionGroup" {$command = "Set-DistributionGroup `"$($user.Account)`" -EmailAddresses @{Add=`"$x500address`"}"}
          "MailUniversalSecurityGroup" {$command = "Set-DistributionGroup `"$($user.Account)`" -EmailAddresses @{Add=`"$x500address`"}"}
          "UserMailbox" {$command = "Set-Mailbox `"$($user.Account)`" -EmailAddresses @{Add=`"$x500address`"}"}
          "MailUser" {$command = "Set-MailUser `"$($user.Account)`" -EmailAddresses @{Add=`"$x500address`"}"}
          "MailContact" {$command = "Set-MailContact `"$($user.Account)`" -EmailAddresses @{Add=`"$x500address`"}"}
          "PublicFolder" {$command = "Set-MailPublicFolder `"$($user.Account)`" -EmailAddresses @{Add=`"$x500address`"}"}
      }
  
      # output command to console
      $command
  }
  
  }
  
  Function CleanLegacyExchangeDN ([string]$imceaex) {
      $imceaex = $imceaex.Replace("IMCEAEX-","")
      $imceaex = $imceaex.Replace("_","/")
      $imceaex = $imceaex.Replace("+20"," ")
      $imceaex = $imceaex.Replace("+28","(")
      $imceaex = $imceaex.Replace("+29",")")
      $imceaex = $imceaex.Replace("+2E",".")
      $imceaex = $imceaex.Replace("+21","!")
      $imceaex = $imceaex.Replace("+2B","+")
      $imceaex = $imceaex.Replace("+3D","=")
      $regex = New-Object System.Text.RegularExpressions.Regex('@.*')
      $imceaex = $regex.Replace($imceaex,"")
      $imceaex # return object
  }