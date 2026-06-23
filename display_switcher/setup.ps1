# please note that all audio devices must be connected and active when running the setup script 
# if an audio out is a TV, and the TV is technically disconnected or inactive (off), it will not show up in the list of audio devices during setup 
# setup can always be re-ran as the config file is backed up, wiped, and rewritten

# verifying that script has been launched as admin 
# module installation requires admin rights
#Requires -RunAsAdministrator

# verifying that the DisplayConfig package is installed
# if the module is missing, it will be installed and imported 
# script execution will halt on exception 
try {
    if (-not (Get-InstalledModule -Name DisplayConfig -ErrorAction SilentlyContinue)){
        Install-Module -Name DisplayConfig -Force -Confirm:$false -ErrorAction Stop
        Import-Module -Name DisplayConfig -ErrorAction Stop
    }
} catch {
    Write-Host "Failed to install or load the DisplayConfig Module: $($_.Exception.Message)"
    Exit 1
}
# verifying that the AudioDeviceCmdlets package is installed
# if the module is missing, it will be installed and imported 
# script execution will halt on exception 
try{
    if(-not(Get-InstalledModule -Name AudioDeviceCmdlets -ErrorAction SilentlyContinue)){
        Install-Module -Name AudioDeviceCmdlets -Force -Confirm:$false -ErrorAction Stop
        Import-Module -Name AudioDeviceCmdlets -ErrorAction Stop
    }
} catch {
    Write-Host "Failed to install or load the AudioDeviceCmdlets Module: $($_.Exception.Message)"
    Exit 1
}

# gathering display locations from the user
# a do while loop is used to verify that at least one location is entered 
# strings are also compared against a regex for input validation. Not super necessary, but good practice to include 
$location_match = "^[a-zA-Z0-9_ ]+(,\s*[a-zA-Z0-9_ ]+)*$"
do {
    Write-Host "What locations will you be connecting this device to? Please separate values with a comma."
    $locations = Read-Host

    if($locations -notmatch $location_match) {
        Write-Host "Please enter at least one location."
    }
} while ($locations -notmatch $location_match)

# creating container array to store display and audio config temporarily 
# looping over $locations variable and matching each location to the corresponding display IDs
# gathering primary display for each location
# gathering audio out for each location 
# display and audio info is then written to array 
# audio devices are referenced as the name, rather than the index. This way we don't run into issues with indexes changing if new devices are attached. Much more likely than additional displays 
# format ex: (desk: 1, 2 : Primary, 2 : Audio, Speakers (High Definition Audio Device))
$container_arr = @()
$id_pattern = "^\d+(,\d+)*$"
$single_pattern = "^\d+$"
foreach ($location in $locations.Split(",").Trim()){
    # gathering display IDs from the user
    Write-Host "Please make note of the display information below. It will show you the various displays currently connected to this device. You will need to match display IDs to each location. Please press enter to proceed ..."
    Read-Host
    Get-DisplayInfo 

    # matching display IDs to the current location
    # regex and duplicate checks make sure that no invalid, duplicate, or blank repsonses are entered 
    do {
        Write-Host "What display IDs, separated by a comma, will go be connected at the ${location}"
        $temp_displays = ((Read-Host).Split(",") | Foreach-Object {$_.Trim() }) -join ","

        $format_valid = $temp_displays -match $id_pattern
        $has_duplicates = $false

        if ($format_valid){
            $id_list = $temp_displays.Split(",")
            $unique_list = $id_list | Select-Object -Unique
            $has_duplicates = $id_list.Count -ne $unique_list.Count
        }

        if (-not ($format_valid)){
            Write-Host "Please enter one or more integers, separated by a comma. Please do not include any spaces."
        }
        if($has_duplicates){
            Write-Host "Please enter each display ID only once, without duplicates."
        }
    } while((-not $format_valid) -or $has_duplicates)

    # setting the primary display for the current location 
    # if a single display is selected, $primary_display is set automatically 
    # if multiples are entered, input is validated before primary is determined 
    if($temp_displays.Split(",").Length -eq 1) { 
        Write-Host "Setting primary display for ${location} automatically."
        $primary_display = $temp_displays
    } else {
        do {
            Write-Host "What display ID is going to be the primary for this area? "
            $primary_display = (Read-Host).Trim()

            if($primary_display -notmatch $single_pattern) {
                Write-Host "Please enter a single Display ID. "
            }
        } while($primary_display -notmatch $single_pattern)
    }

    # gathering audio indexes from the user 
    Write-Host "Next, please make note of the audio devices below. You will need to match the Index value to a location Please press enter to proceed ..."
    Read-Host 
    Get-AudioDevice -List | Select-Object Name, Index

    # pulling audio source name for the current locaiton 
    do {
        Write-Host "What audio device (Index) is going to be used at the ${location}"
        $primary_audio = Read-Host

        if($primary_audio -notmatch $single_pattern){
            Write-Host "Please enter a single Audio ID"
        } else {
            $audio_name = Get-AudioDevice -Index $primary_audio | Select-Object Name
        }
    } while($primary_audio -notmatch $single_pattern)

    # updating container array to store audio/video info for the given location 
    # audio_name had to be referenced as an expression, {}'s interpret the variable name literally, so it looks for a variable named audio_name.Name, which doesn't exist 
    $container_arr += "${location}:${temp_displays}:Primary,${primary_display}:Audio,$($audio_name.Name)"

    # clearing host to help with readability 
    Clear-Host
}

# verifying path to config file exists
# if config file doesn't exist, it is created
# if it does exist, it is backed up before being overwritten 
$config_path = "config.txt"
$backup_path = "config.backup.txt"
try{
    if(-not (Test-Path -Path $config_path)){
        New-Item -ItemType File -Path $config_path -ErrorAction Stop | Out-Null
    } else {
        Copy-Item -Path $config_path -Destination $backup_path -ErrorAction Stop -Force | Out-Null
    }
} catch {
    Write-Host "Failed to prepare the config file $($_.Exception.Message)"
    Exit 1
}
# clearing config file content and re-writing so that old configurations are cleared 
try{
    Clear-Content -Path $config_path -ErrorAction Stop
    Add-Content -Path $config_path -Value $container_arr -ErrorAction Stop
} catch {
    Write-Host "Failed to write the config file: $($_.Exception.Message)"

    # attempting to restore previous backed up config if it exists
    if(Test-Path -Path $backup_path){
        Write-Host "Restoring previous config from backup"
        Copy-Item -Path $backup_path -Destination $config_path -ErrorAction Stop -Force | Out-Null
    }

    Exit 1
}

# creating the scheduled task to run on login (only if it doesn't exist)
# scheduled task has to run as logged in user so that displays and audio devices are detected
# they will not appear in a headless state 
try{
    $task_name = "Start DS Listener"
    if(-not (Get-ScheduledTask -TaskName $task_name -ErrorAction SilentlyContinue)){
        $listener_path = "c:\scripts\display_switcher\listener.ps1"
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ${listener_path}" -ErrorAction Stop
        $trigger = New-ScheduledTaskTrigger -AtLogOn -ErrorAction Stop
        $principal = New-ScheduledTaskPrincipal -LogonType Interactive -UserId $env:USERNAME -ErrorAction Stop
        $task_definition = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -ErrorAction Stop
        Register-ScheduledTask -TaskName $task_name -InputObject $task_definition -Force -ErrorAction Stop
    }
} catch {
    Write-Host "Failed to build/check scheduled task: $($_.Exception.Message)"
    Exit 1
}

# checking for existin ACL rule and creating if it doesn't exist 
# this is used to allow a non-admin to bind ports, vs. having to have the scheduled task (and the listener) execute as admin
$url_prefix = "http://192.168.1.6:8082/"
$acl_check = netsh http show urlacl url=$url_prefix

if($LASTEXITCODE -ne 0){
    Write-Host "Failed to query ACL reservations."
    Exit 1
}

if($acl_check -match "URL reservation information could not be found"){
    netsh http add urlacl url=$url_prefix user=$env:USERNAME
    if($LASTEXITCODE -ne 0){
        Write-Host "Failed to add URL ACL reservation."
        Exit 1
    }
}