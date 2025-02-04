<#
    Ryan Lubach - IT 490 Capstone - Spring 2024
    -------------------------------------------
    Script that uses a function for automating backup of a user's 
    files stored in the Documents directory. After file backup an 
    email will be sent reporting the success or failure of the backup.

#>


# Function to backup files and send email report
function Backup-UserFiles {

    param (

        [Parameter(Mandatory=$true)]
        [string] $User,

        [Parameter(Mandatory=$true)]
        [string] $DestDir,

        [Parameter(Mandatory=$true)]
        [string] $ToEmail,

        [Parameter(Mandatory=$true)]
        [string] $FromEmail,

        [Parameter(Mandatory=$true)]
        [string] $SmtpServer
    )
  
    # Set backup source to user's Documents directory
    [string] $SourceDir = "C:\Users\$User\Documents"
    
    # Create flag for marking backup success or failure
    [bool] $SuccessFlag = $false


    ## BEGIN BACKUP OPERATIONS ##

    # Silently create parent destination directory if it doesn't exist
    if (-not (Test-Path -Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir | Out-Null
    }

    # Define dated subdirirectory name string (not path)
    [string] $BackupDirString = "$User " + (Get-Date).ToString("yyyy-MM-dd-HHmmss")

    # Create dated backup subdirectory
    New-Item -ItemType Directory -Path "$DestDir\$BackupDirString"

    # Change destination directory to newly created dated subdirectory
    $DestDir = "$DestDir\$BackupDirString"


    ## START FILE COPY OPERATION ##
    # Copy items recursively from source directory to destination directory
    Write-Host "`nBeginning directory backup...`n" -ForegroundColor Magenta
    Copy-Item -Path $SourceDir\* -Recurse -Destination $DestDir -Verbose
    
    # Check success/failure status of last command (Copy-Item) and set status SuccessFlag appropriately
    if ($?) {
        Write-Host "`nBackup was successful.`n" -ForegroundColor Green
        $SuccessFlag = $true
    }
    else {
        Write-Host "`nBackup failed.`n" -ForegroundColor Red
    }


    # Define and choose success/failure subject and message for email report
    [string] $SuccessSubject = "SUCCESSFUL BACKUP FOR USER $User"
    [string] $FailureSubject = "BACKUP FOR USER $User FAILED"
    [string] $SuccessBody = "The backup operations for user $User were successful."
    [string] $FailureBody = "The backup operations for user $User were unsuccessful. Recheck settings."
    if ($SuccessFlag) {
        # Backup was successful
        [string] $EmailSubject = $SuccessSubject
        [string] $EmailBody = $SuccessBody
    }
    else {
        #Backup failed
        [string] $EmailSubject = $FailureSubject
        [string] $EmailBody = $FailureBody
    }

    # Build email fields for report message
    $reportMessageFields = @{
        From = $FromEmail
        To = $ToEmail
        Subject = $EmailSubject
        Body = $EmailBody
        DeliveryNotificationOption = 'OnSuccess', 'OnFailure'
        SmtpServer = $SmtpServer
    }

    # Send email report using hash table values
    # Sender will also receive report indicating email delivery
    # Also outputs script completion message and email operation status
    try {
        Send-MailMessage @reportMessageFields -ErrorAction Stop
        # Output for successfully sent email
        Write-Host "`nAll operations complete.`nCheck email for status report." -ForegroundColor Yellow
    }
    catch {
        # Output for failed email
        Write-Host "`nAll operations complete.`n" -ForegroundColor Yellow
        Write-Host "Warning:`n" -ForegroundColor Red -NoNewline
        Write-Host "Email report could not be sent.`nCheck your email addresses and SMTP settings." -ForegroundColor Yellow 
    }
}


#####################################


# Toggle user email address and server entry at runtime
[bool] $UseHardcodedEmailFields = $true


Write-Host "`nStarting Backup Operations`n" -ForegroundColor Yellow

# Define variables
[string] $BackupUser = Read-Host "Enter user"
[string] $DestinationPath = Read-Host "Enter path of backup destination"
if ($UseHardcodedEmailFields) {
    [string] $ToEmailAddress = "logs-backup@companyabc.com"
    [string] $FromEmailAddress = "backupresults@companyabc.com"
    [string] $SmtpEmailServer = "smtp.companyabc.com"
}
else {
    [string] $ToEmailAddress = Read-Host "Enter recipient email address for backup results"
    [string] $FromEmailAddress = Read-Host "Enter sender email address for backup results"
    [string] $SmtpEmailServer = Read-Host "Enter the SMTP server to use for backup results email"
}


# Run backup function with email reporting
Backup-UserFiles `
    -User $BackupUser `
    -DestDir $DestinationPath `
    -ToEmail $ToEmailAddress `
    -FromEmail $FromEmailAddress `
    -SmtpServer $SmtpEmailServer
