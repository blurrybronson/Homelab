# parameter construction for the position flag 
# desk or entertainment
# display_switcher -Position desk || display_switcher -Position tv
param (
    [Parameter(Mandatory=$true)]
    [string]$Position
)

try{
    # verifying that config file exists and opening 
    $config_path = "C:\scripts\display_switcher\config.txt"
    if(-not(Test-Path -Path $config_path)){
        Write-Host "Config file not found. Please run setup.ps1 script first"
        Exit 1
    }
    $conf = Get-Content -Path $config_path -ErrorAction Stop
    if(-not($conf)){
        Write-Host "Config file is empty. Please run setup.ps1 first."
        Exit 1
    }
} catch {
    Write-Host "Failed to access config file: $($_.Exception.Message)"
    Write-Host "Please run the setup script and verify that the config.txt file exists"
    Exit 1
}

# getting display IDs based on provided position
# config file format (position: display, IDs : primary, displayID : current, 0/1)
# each line is split at the : and the 0 index is pulled to compare to the Position parameter passed into the script at runtime 
# new displays have to be enabled before disabling current displays
$primary = $active = $audio = $null
try{
    $cur = Get-DisplayInfo -ErrorAction Stop | Where-Object {$_.Active -match 'True'} | Select-Object DisplayId
} catch {
    Write-Host "Unable to load current display info. Please make sure the necessary modules are installed: $($_.Exception.Message)"
    Exit 1
}

foreach($item in $conf){
    $pos = $item.Split(":")[0]
    if($pos -ne $Position){
        Continue
    }

    # variable assignments for settings active devices
    $active = $item.Split(":")[1]
    $primary = $item.Split(":")[2].Split(",")[1]
    $audio = $item.Split(":")[3].Split(",")[1]

    # building the full set of display IDs that should be active for this position 
    # ($active is the comma-separated list from the config file, $primary may or may not already be included in it)
    $new_active = @($active.Split(","))
    if($new_active -notcontains $primary){
        $new_active += $primary
    }

    # if the currently active displays exactly match the new active set, we're already at this position - exit
    # Get-DisplayInfo returns objects, so $cur.DisplayId is already an array, no parsing needed
    # Exit instead of Exit 1 because an exit is what we want. The script isn't broken, we're already in the correct location
    if(-not (Compare-Object -ReferenceObject $cur.DisplayId -DifferenceObject $new_active)){
        Write-Host "Already at position '${Position}'. No changes needed."
        Exit
    }

    # enabling and setting new primary display 
    # looping over remaining active displays and enabling them
    # this would theoretically work for any number of connected displays so this can be expanded without being rewritten 
    try{
        Enable-Display -DisplayId $primary -ErrorAction Stop
        Set-DisplayPrimary -DisplayId $primary -ErrorAction Stop
        foreach($display in $active.Split(",")){
            Enable-Display -DisplayId $display -ErrorAction Stop
        }
    } catch {
        Write-Host "Exception thrown when setting the new active displays: $($_.Exception.Message)"
        Exit 1
    }
    # disabling displays that were active when the script was called
    try{
        foreach($display in $cur.DisplayId){
            Disable-Display -DisplayId $display -ErrorAction Stop
        }
    } catch {
        Write-Host "Exception thrown when disabling previous location displays: $($_.Exception.Message)"
        Exit 1
    }
    # pulling index of audio device for the new active location and setting it as active 
    # display must be enabled before this if the audio device is part of the display. An internal speaker on a TV or monitor
    try{ 
        $new_audio = Get-AudioDevice -List -ErrorAction Stop | Where-Object {$_.Name -eq $audio} | Select-Object Index
        if(-not($new_audio)){
            Write-Host "Audio device not found. Please verify that the device is connected."
            Exit 1
        }
        Set-AudioDevice -Index $new_audio.Index -ErrorAction Stop
    } catch {
        Write-Host "Exception thrown when setting new audio device: $($_.Exception.Message)"
        Exit 1
    }
}