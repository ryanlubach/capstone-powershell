<#
  Ryan Lubach - IT 490 Capstone - Spring 2024
  -------------------------------------------
  Script for automating the setup of an Active Directory user using a 
  function, taking keyboard input for user info (name, domain, group, etc.).
#>


# Function for creating new AD user.
function Add-NewADUser
{
    param (
        [Parameter(Mandatory=$true)]
        [string] $UserName
    )

    # Get password for new user
    $securePassword = Read-Host -Prompt "Enter password for new user `"$UserName`" in the box:" -AsSecureString

    # Get first and last names
    [string] $FirstName = Read-Host "Enter GivenName"
    [string] $LastName = Read-Host "Enter Surname"

    # Get path
    [string] $UserPath = Read-Host "Enter valid LDAP/AD path`nExample: OU=Staff,DC=mydomain,DC=local"

    # Build hash table for user creation from previous keyboard input
    # To create users in an enabled state change "Enabled" to "$true"
    $userHashTable = @{
        GivenName       = $FirstName
        Surname         = $LastName
        Path            = $UserPath
        Name            = $UserName
        SamAccountName  = $UserName
        AccountPassword = $securePassword
        Enabled         = $false
        PassThru        = $true
    }

    # Attempt creation of Active Directory user with hash table values
    try {
        New-ADUser @$userHashTable
    }
    catch {
        Write-Host "`nAn error occured during user creation." -ForegroundColor Red
        Write-Host "Aborting new user setup.`n" -ForegroundColor Red
        throw "User Creation Error"
    }

    # Give option to add user to group
    [string] $AddGroupReply = Read-Host "Would you like to add $UserName to a group? (Y/n)"
    if ($AddGroupReply -ne "n" -and $AddGroupReply -ne "no") {
        $Group = Read-Host "Enter Group Name"
        Add-ADGroupMember -Identity $Group -Members $UserName
    }

    # User setup confirmation message
    Write-Host "`nNew user setup complete!`nUser " -ForegroundColor Yellow -NoNewline
    Write-Host $UserName -NoNewline
    Write-Host " created with the following properties:" -ForegroundColor Yellow
    Get-ADUser -Identity $UserName
}


# Function checking for existing AD user with same SamAccountName
function Find-ExistingUser
{
    param (
        [Parameter(Mandatory=$true)]
        [string] $User
    )

    # Return unique username, enter new username, or abort script
    if (Get-ADUser -Filter 'SamAccountName -eq $User') {
        Write-Host "`nA user with the username " -NoNewline
        Write-Host $User -ForegroundColor Green -NoNewline
        Write-Host " already exists.`nEnter a different and unused username to continue with user setup."
        Write-Host "`nWould you like to enter a new username?" -ForegroundColor Yellow -NoNewline
        [string] $continue = Read-Host " (Y/n)"
        if ($continue -eq "n" -or $continue -eq "no") {
            Write-Host "Confirmed: Aborting new user setup.`n" -ForegroundColor Red
            throw "Aborted new user setup"
        }
        else {
            # Restart username selection process
            return $false
        }
    }
    # Return the valid unique username
    return $true
}


# Beginning of new user setup
Write-Host "`nStarting new AD user setup..." -ForegroundColor Yellow

# Create unique AD username (disallows matching SamAccountName)
$isUniqueName = $false
while (-not $isUniqueName) {
    Write-Host "`nPlease enter the account name for the new user."
    $UserName = Read-Host "(This will be their Windows login name)"
    $isUniqueName = Find-ExistingUser -User $UserName
}

# Call AD user create function with unique username
Add-NewADUser -UserName $username
