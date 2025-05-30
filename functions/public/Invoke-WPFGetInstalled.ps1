function Invoke-WPFGetInstalled {
    <#
    TODO: Add the Option to use Chocolatey as Engine
    .SYNOPSIS
        Invokes the function that gets the checkboxes to check in a new runspace

    .PARAMETER checkbox
        Indicates whether to check for installed 'winget' programs or applied 'tweaks'

    #>
    param($checkbox)
    if ($sync.ProcessRunning) {
        $msg = "[Invoke-WPFGetInstalled] Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if (($sync.ChocoRadioButton.IsChecked -eq $false) -and ((Test-WinUtilPackageManager -winget) -eq "not-installed") -and $checkbox -eq "winget") {
        return
    }
    $managerPreference = $sync["ManagerPreference"]
    $sync.ItemsControl.Dispatcher.Invoke([action] {
            $sync.ItemsControl.Items | ForEach-Object { $_.Visibility = [Windows.Visibility]::Collapsed }
            $null = $sync.itemsControl.Items.Add($sync.LoadingLabel)
        })
    Invoke-WPFRunspace -ParameterList @(("managerPreference", $managerPreference),("checkbox", $checkbox),("ShowOnlyCheckedApps", ${function:Show-OnlyCheckedApps})) -DebugPreference $DebugPreference -ScriptBlock {
        param (
            [string]$checkbox,
            [PackageManagers]$managerPreference,
            [scriptblock]$ShowOnlyCheckedApps
        )
        $sync.ProcessRunning = $true
        $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "Indeterminate" })

        if ($checkbox -eq "winget") {
            Write-Host "Getting Installed Programs..."
            switch ($managerPreference) {
                "Choco"{$Checkboxes = Invoke-WinUtilCurrentSystem -CheckBox "choco"; break}
                "Winget"{$Checkboxes = Invoke-WinUtilCurrentSystem -CheckBox $checkbox; break}
            }
        }
        elseif ($checkbox -eq "tweaks") {
            Write-Host "Getting Installed Tweaks..."
            $Checkboxes = Invoke-WinUtilCurrentSystem -CheckBox $checkbox
        }

        $sync.form.Dispatcher.invoke({
            foreach ($checkbox in $Checkboxes) {
                $sync.$checkbox.ischecked = $True
            }
        })
        $sync.ItemsControl.Dispatcher.Invoke([action] {
            $ShowOnlyCheckedApps.Invoke($sync.SelectedApps)
            $sync["WPFSelectedFilter"].IsChecked = $true
            $sync.ItemsControl.Items.Remove($sync.LoadingLabel)
        })
        Write-Host "Done..."
        $sync.ProcessRunning = $false
        $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "None" })
    }
}
