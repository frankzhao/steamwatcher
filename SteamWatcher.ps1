<# Frank Zhao 2011
 # frankzhao.net
 #
 # To run:
 # 1. Make sure Windows is happy by running 
 #  "Set-ExecutionPolicy Unrestricted" in Powershell once as admin
 # 2. Either execute ./SteamWatcher_Extended.ps1 in Powershell
 #  or Right click -> Run in Powershell
 #>

param (
   $interval = 60,
   $folder = "$((get-itemproperty "hkcu:\Software\Valve\Steam\").SteamPath)/steamapps",
   $debug = $false
)

$runWatcher = $true

write-host -foregroundcolor "green" "----SteamWatcher----"
write-host "`n`n"
write-host -foregroundcolor "yellow" "Make sure you start your downloads in Steam before continuing!!"
start-sleep -s 3
write-host "`n`n"
$title = "-Steamapps directory check-"
$message = "SteamWatcher will be monitoring the folder at: $folder, is this correct?"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "SteamWatcher will use the detected location."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "If SteamWatcher detects the wrong location, you can cancel the script and use -folder to specify a different location."
$shutdown = New-Object System.Management.Automation.Host.ChoiceDescription "&Shutdown", "Shutdown computer after downloads complete."
$sleep = New-Object System.Management.Automation.Host.ChoiceDescription "S&leep", "Standby computer after downloads complete."

$options = [System.Management.Automation.Host.ChoiceDescription[]] ($yes, $no)
$optionspower = [System.Management.Automation.Host.ChoiceDescription[]] ($shutdown, $sleep)
$result = $host.ui.PromptForChoice($title, $message, $options, 0)

Function startWatcher ($folder, $interval, $debug) {
  #set our main "gettingBigger" variable as true to start.
  #When the folder stops growing this should change to false
  $gb = $true

  #run the checks
  do {
     $size1 = (get-childitem $folder -recurse | measure-object -property length -sum).sum
       if($debug) {
      write-host "$size1"
       }
     start-sleep -s $interval
     $size2 = (get-childitem $folder -recurse | measure-object -property length -sum).sum
       if($debug) {
      write-host "$size2"
       }
     if($size2 -eq $size1) {
      $gb = $false
     }
  } while ($gb)
}

switch ($result) {
  0 {
     write-host "`n`nSteamWatcher will now monitor: $folder. `nDebug mode is $debug."
     $resultpower = $host.ui.PromptForChoice("`n`n-Action to take-", "Would you like your computer to shutdown or sleep when downloads are complete?", $optionspower, 0)
      
      switch ($resultpower) {
      	0 {
          if($runWatcher) {          
          			write-host "Your PC will be shutdown when download activity is complete.`n`n"
          			startWatcher $folder $interval $debug
          			write-host -foregroundcolor "yellow" "`nDownload activity appears to be complete. Shutting down computer in 10 seconds."
          			start-sleep -s 10
          			add-content "SteamWatcher_log.txt" "$(get-date) --- Downloads appear to be complete. Shutting Down now."
          			stop-process -processname steam* -Force

          			stop-computer
          }
        }
        
        1 {
          if($runWatcher) {
                   
      			write-host "Your PC will standby when download activity is complete.`n`n"
      			startWatcher $folder $interval $debug
      			write-host -foregroundcolor "yellow" "`nDownload activity appears to be complete. Standing by computer in 10 seconds."
      			start-sleep -s 10
      			add-content "log.txt" "$(get-date) --- Downloads appear to be complete. Standing by now."
            
            Add-Type -Assembly System.Windows.Forms
            [System.Windows.Forms.Application]::SetSuspendState("Suspend", $false, $false)
          }  
        }
    }
  }
  
  1 {
		write-host "`n`nYou can specify the correct folder to be monitored by using the"
		write-host "-folder parameter, for eg: '.\steamwatcher.ps1 -folder C:\somewhere\steam\steamapps'`n`n"
		write-host "A custom check interval can also be set using '-interval XX' where XX = interval in seconds.`n`n"
		write-host "script will end in 20 seconds.  Hit Ctrl+C to end it now."
		start-sleep -s 20    
  }
}
