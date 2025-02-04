<#
  Ryan Lubach - IT 490 Capstone - Spring 2024
  -------------------------------------------
  Script for automating the lookup of an Active Directory user
  Wildcard user name matches can be suggested without an exact match
#>


# Toggle bool for similar user results returned without exact match
# Can be disabled if too many users are returned on wildcard search
[bool] $check_close_matches = $true

# Prompt to enter user name
Write-Host "Running user lookup script...`n"
[string] $user_input = Read-Host "Enter user to look up"

# Uncomment line below to override searched user
# $user_input = "ExampleUserName"

# Search AD for exact and similar matches for entered user name.
# Terminate search on error (e.g. empty search field)
try {
    $like_users = Get-ADUser -Filter "SamAccountName -like '*$user_input*'"
    $matched_user = $like_users | Where-Object {$_.SamAccountName -eq "$user_input"}
}
catch {
    Write-Host "`nERROR - SEARCH TERMINATED" -ForegroundColor Red
    Write-Host "Make sure to enter a valid user name and try again.`n"
    throw
}

if ($null -ne $matched_user) {
    # Exact user match found
    Write-Host "`nExact match found for user " -NoNewline
    Write-Host $user_input -ForegroundColor Green -NoNewline
    Write-Host ":" -NoNewline
    $matched_user
}
else {
    # User not found
    Write-Host "`nUser " -ForegroundColor Red -NoNewline
    Write-Host $user_input -ForegroundColor Green -NoNewline
    Write-Host " not found." -ForegroundColor Red

    # Check for users containing entered string (-like)
    # This only runs if $check_close_matches is True
    if ($null -ne $like_users -and $check_close_matches) {
        # Like user(s) found
        Write-Host "Did you mean to search for any of the following users?:" -ForegroundColor Green
        $like_users.SamAccountName
    }
    elseif ($check_close_matches) {
        # No similar user matches (null $like_users)
        Write-Host "No close matches found." -ForegroundColor Red
    }
}


<# DEBUG - Content of Like+Matched
Write-Host "`nDEBUG INFO:" -ForegroundColor Black -BackgroundColor White
Write-Host "`n MATCHED " -ForegroundColor Black -BackgroundColor Yellow
$matched_user.SamAccountName
Write-Host "`n LIKE " -ForegroundColor Black -BackgroundColor Yellow
$like_users.SamAccountName

# DEBUG - Check if user lists -eq null
Write-Host "`n Matched = null? " -ForegroundColor Black -BackgroundColor Cyan
$null -eq $matched_user
Write-Host "`n Like = null? " -ForegroundColor Black -BackgroundColor Cyan
$null -eq $like_users
#>
