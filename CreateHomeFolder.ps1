<#

Author:  Lee Buskey Lee.buskey.ctr@ablcda.navy.mil 

#>

param
(
	[String]$Path,
	[String]$UserList,
	[String[]]$FullControlMember
)


$PSEmailServer = "10.20.1.53"								
# The utterly fictitious address that the mailed messages should appear to be from.  
$from = "noreply@sked.abl.navy.mil"									 
#Subject of the emails
$subject = "[SKED] Admin notification of user home folder creation"	
#Body of the email 	
$body = ""

#$FullControlMember = "SG-SKED-SVR"
$Path =  "\\spablskxa8r01\Homedrives"
Import-Module ActiveDirectory
$users = get-aduser -filter * -searchbase "OU=Standard Users,OU=SKED Users,OU=SKED,DC=sked,DC=ABLU,DC=NAVY,DC=MIL" | select SamAccountName -expandproperty SamAccountName  | Sort-Object 
#$users = get-aduser -filter * -searchbase "OU=SKED Users,OU=SKED,DC=sked,DC=ABLU,DC=NAVY,DC=MIL" | select SamAccountName -expandproperty SamAccountName  | Sort-Object 
$Results=@()
Import-Module ActiveDirectory

#Check whether the input AD member is correct
if ($FullControlMember)
{
	$FullControlMember|ForEach-Object {
		if (-not(Get-ADObject -Filter 'SamAccountName -Like $_'))
            {
			$FullControlMember= $FullControlMember -notmatch $_; Write-Error -Message "Cannot find an object with name:'$_'"
		    }
	}
}
$FullControlMember+="NT AUTHORITY\SYSTEM","BUILTIN\Administrators"

foreach($User in $Users)
   {
        $HomeFolderACL=Get-Acl $Path
	    $HomeFolderACL.SetAccessRuleProtection($true,$false)
	    $Result=New-Object PSObject
	     If (-not(test-path -path "$Path\$User"))
           
            {
    	    New-Item -ItemType directory -Path "$Path\$User"|Out-Null
            New-Item -ItemType directory -Path "$Path\$User\outbound"|Out-Null
            New-Item -ItemType directory -Path "$Path\$User\inbound"|Out-Null
            write-host "$user - SKED user's home directories have been created."
            $Body+= "$user - SKED home directories have been created.`n"

            }

		    #set acl to folder
		    $FCList=$FullControlMember+$User
		    $FCList|ForEach-Object {
		    $ACL=New-Object System.Security.AccessControl.FileSystemAccessRule($_,"FullControl","ContainerInherit,ObjectInherit","None","Allow")
			$HomeFolderACL.AddAccessRule($ACL)
            Set-Acl -Path "$Path\$User" $HomeFolderACL
            $Results+=$Result
            

	}


}

 
#Generate a report

If ($body -ne "") {Send-MailMessage -From $from -To "PMO-IT_LCS-SKED_Support_Desk@ablcda.navy.mil"  -Subject $subject -Body $body -ErrorAction Stop
Write-host "Mail message sent"}
	

