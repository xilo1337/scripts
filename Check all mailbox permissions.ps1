Connect-ExchangeOnline
# Step 1: Connect to Exchange Online
Connect-ExchangeOnline -UserPrincipalName adminUPN -ShowBanner:$false
 
# Step 2: Get All Mailboxes
$Mailboxes = Get-Mailbox -ResultSize Unlimited | Where {$_.DisplayName -ne "Discovery Search Mailbox"}
$ReportData = @()
$MailboxCount = $Mailboxes.count
 
# Step 3: Gather Mailbox Permissions
$MailboxCounter = 0
ForEach ($Mailbox in $Mailboxes) {
    #Get All Full Permissions - Other than Mailbox Owners
    $Permissions = Get-MailboxPermission -Identity $Mailbox.UserPrincipalName | Where {$_.User -ne "NT AUTHORITY\SELF" } 
    foreach ($Permission in $Permissions) {
        $info = New-Object PSObject -Property @{
            Mailbox        = $mailbox.UserPrincipalName
            UserName       = $mailbox.DisplayName
            UserID         = $permission.User
            AccessRights   = $Permission | Select -ExpandProperty AccessRights
            MailboxType    = $Mailbox.RecipientTypeDetails
        }
        $ReportData += $info
    }
 
    #Get all "Send as" Permissions
    $SendAsPermissions = Get-RecipientPermission -Identity $Mailbox.UserPrincipalName | Where {$_.Trustee -ne "NT AUTHORITY\SELF"}
    ForEach ($Permission in $SendAsPermissions) {
       $info = New-Object PSObject -Property @{
           Mailbox     = $mailbox.UserPrincipalName
           UserName    = $mailbox.DisplayName
           UserID  = $Permission.Trustee
           AccessRights = $Permission | Select -ExpandProperty AccessRights
           MailboxType = $Mailbox.RecipientTypeDetails
         }
        $ReportData += $info
    }
 
    #Get all "Send on Behald of" permissions
    If ($Mailbox.GrantSendOnBehalfTo -ne $null)
    {
        ForEach ($Permission in $mailbox.GrantSendOnBehalfTo) {
            $info = New-Object PSObject -Property @{
                Mailbox     = $mailbox.UserPrincipalName
                UserName    = $mailbox.DisplayName
                UserID  =  $Permission
                AccessRights = "Send on Behalf Of"
                MailboxType = $Mailbox.RecipientTypeDetails 
                }
        $ReportData += $info
        }
     }
 
    $MailboxCounter++
    $ProgressStatus = "$($Mailbox.UserPrincipalName) ($MailboxCounter of $MailboxCount)"
    Write-Progress -Activity "Processing Mailbox" -Status $ProgressStatus -PercentComplete (($MailboxCounter/$MailboxCount)*100)
}
 
# Step 4: Export Report to CSV
$ReportData | Export-Csv -Path "C:\Temp\MailboxPermissionsReport.csv" -NoTypeInformation
$ReportData | Format-Table
 
# Step 5: Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false


#Read more: https://www.sharepointdiary.com/2021/11/check-mailbox-permissions-office-365.html#ixzz8uCT3evcT