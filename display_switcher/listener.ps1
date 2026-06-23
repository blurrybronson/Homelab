# script will run automatically at boot via a scheduled task 
# web listener will be hit via Apple HomeKit shortcut 

# starting logger
# if the log file path doesn't exist, there is an attempt to create it 
# the log appends data on each restart, rather than rewriting 
try{
    $logger_path = "C:\scripts\display_switcher\listener_log.txt"
    if(-not(Test-Path -Path $logger_path)){
        New-Item -ItemType File -Path $logger_path -ErrorAction Stop | Out-Null
    }
    Start-Transcript -Path $logger_path -Append -ErrorAction Stop
} catch {
    Write-Host "Unable to start logger. Please verify file path and permissions: $($_.Exception.Message)"
    Exit 1
}
# verifying that the config file exists before building the listener
# if it does not exist, script execution halts 
# this is used to verify locations/positions, so that only those values can be fed in 
# if the config file doesn't exist, the setup file likely wasn't ran, and the switcher script will not execute properly
try{
    $config_path = "C:\scripts\display_switcher\config.txt"
    if(-not(Test-Path -Path $config_path)){
        Write-Host "Config not found, killing script. Please run the setup.ps1 script."
        Exit 1
    }
    $conf = Get-Content -Path $config_path -ErrorAction Stop
} catch {
    Write-Host "Failed to test path to the config file: $($_.Exception.Message)"
    Exit 1
}

# parsing $conf variable and building an array of valid locations 
# these will be used to compare against the http request that this listens for later in the script, to verify that only valid input is accepted 
# if the array is empty after construction, execution halts 
# no error handling required here, as I am just updating variables. Errors would happen when the $conf variable is built above
$valid_locations = @()
foreach($destination in $conf){
    $valid_locations += $destination.Split(":")[0]
}
if($valid_locations.Count -eq 0){
    Write-Host "No valid locations found in config. Please run setup.ps1 first."
    Exit 1
}

# creating, configuring, and starting the listener object 
try{
    $listener = New-Object System.Net.HttpListener
    $url_prefix = 'http://192.168.1.6:8082/'
    $listener.Prefixes.Add($url_prefix) | Out-Null
    $listener.Start()
    Write-Host 'Listener started ...'
} catch {
    Write-Host "Failed to start listener: $($_.Exception.Message)"
    Exit 1
}

try{
    while ($listener.IsListening) {
        # pulling context to get the reuqest url 
        # return string must be split as it is returned as "/url"
        $context = $listener.GetContext()
        $request = $context.Request.RawUrl
        $request = $request.Split('/')[1]
        if($valid_locations -notcontains $request){
            Write-Host "Invalid location received in request."
            $context.Response.StatusCode = 400
            $context.Response.Close()
            Continue
        }
        Write-Host $request
        Write-Host 'Request logged ...'

        # calling the main display switcher script 
        Write-Host 'Initiating switcher script ...'
        Start-Process Powershell.exe -ArgumentList "-File c:\scripts\Display_Switcher\switcher.ps1 -Position ${request}" -ErrorAction Stop
        $context.Response.StatusCode = 200
        $context.Response.Close()
    }
} catch {
    Write-Host "The listener has encountered an error: $($_.Exception.Message)"
    Exit 1
} finally {
    # stopping the listener
    $listener.Stop()
}