#requires -version 5.1
<# 
DDS2PNG-GUI.ps1
- WinForms GUI for converting DDS -> PNG via texconv.exe
- Drag & drop support
- STA guard so the window won't instantly close
#>

# Relaunch as STA if needed (WinForms needs STA)
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Write-Host "Restarting PowerShell in STA mode..."
    $argsList = @("-NoProfile", "-STA", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
    Start-Process -FilePath "powershell.exe" -ArgumentList $argsList | Out-Null
    exit
}

# Enable visual styles
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

function Show-ErrorDialog($msg) {
    [System.Windows.Forms.MessageBox]::Show($msg, "DDS → PNG Converter", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}

try {
    $fontRegular = New-Object System.Drawing.Font("Segoe UI", 10)
    $fontSmall = New-Object System.Drawing.Font("Segoe UI", 9)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "DDS → PNG Converter (texconv)"
    $form.Size = New-Object System.Drawing.Size(820, 620)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $false

    $lblTexconv = New-Object System.Windows.Forms.Label
    $lblTexconv.Text = "texconv.exe path:"
    $lblTexconv.Location = New-Object System.Drawing.Point(12, 15)
    $lblTexconv.AutoSize = $true
    $lblTexconv.Font = $fontRegular
    $lblTexconv.Anchor = 'Top, Right, Left'



    $btnBrowseTexconv = New-Object System.Windows.Forms.Button
    $btnBrowseTexconv.Text = "Browse..."
    $btnBrowseTexconv.Location = New-Object System.Drawing.Point(680, 10)
    $btnBrowseTexconv.Size = New-Object System.Drawing.Size(110, 28)
    $btnBrowseTexconv.Font = $fontRegular
    $btnBrowseTexconv.Anchor = 'Top, Right'


    $lblOut = New-Object System.Windows.Forms.Label
    $lblOut.Text = "Output folder:"
    $lblOut.Location = New-Object System.Drawing.Point(12, 55)
    $lblOut.AutoSize = $true
    $lblOut.Font = $fontRegular
    $lblOut.Anchor = 'Top, Right, Left'


    $txtOut = New-Object System.Windows.Forms.TextBox
    $txtOut.Location = New-Object System.Drawing.Point(140, 52)
    $txtOut.Size = New-Object System.Drawing.Size(530, 25)
    $txtOut.Font = $fontRegular
    $txtOut.Anchor = 'Top, Right, Left'

    $txtTexconv = New-Object System.Windows.Forms.TextBox
    $txtTexconv.Location = New-Object System.Drawing.Point(140, 12)
    $txtTexconv.Size = New-Object System.Drawing.Size(530, 25)
    $txtTexconv.Font = $fontRegular
    $txtTexconv.Anchor = 'Top, Right, Left'

    if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $scriptDir = Get-Location
    }
    else {
        $scriptDir = Split-Path -Parent $PSCommandPath
    }
    $defaultTexconv = Join-Path $scriptDir "assets\texconv.exe"
    if (Test-Path $defaultTexconv) {
        $txtTexconv.Text = $defaultTexconv
    }
    else {
        $txtTexconv.Text = "Please Select texconv.exe"
    }


    if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $scriptDir = Get-Location
    }
    else {
        $scriptDir = Split-Path -Parent $PSCommandPath
    }
    $defaultOut = Join-Path $scriptDir "png export"
    if (Test-Path $defaultOut) {
        $txtOut.Text = $defaultOut
    }
    else {
        $txtOut.Text = "Please Select A Path"
    }

    $btnBrowseOut = New-Object System.Windows.Forms.Button
    $btnBrowseOut.Text = "Browse..."
    $btnBrowseOut.Location = New-Object System.Drawing.Point(680, 50)
    $btnBrowseOut.Size = New-Object System.Drawing.Size(110, 28)
    $btnBrowseOut.Font = $fontRegular
    $btnBrowseOut.Anchor = 'Top, Right'

    $lblFiles = New-Object System.Windows.Forms.Label
    $lblFiles.Text = "DDS files (drag & drop or use Add Files):"
    $lblFiles.Location = New-Object System.Drawing.Point(12, 95)
    $lblFiles.AutoSize = $true
    $lblFiles.Font = $fontRegular
    $lblFiles.Anchor = 'Top, Right, Left'

    $listFiles = New-Object System.Windows.Forms.ListBox
    $listFiles.Location = New-Object System.Drawing.Point(15, 120)
    $listFiles.Size = New-Object System.Drawing.Size(650, 300)
    $listFiles.Font = $fontSmall
    $listFiles.SelectionMode = "MultiExtended"
    $listFiles.AllowDrop = $true
    $listFiles.Anchor = 'Top, Left, Right'

    $btnAdd = New-Object System.Windows.Forms.Button
    $btnAdd.Text = "Add Files..."
    $btnAdd.Location = New-Object System.Drawing.Point(680, 120)
    $btnAdd.Size = New-Object System.Drawing.Size(110, 30)
    $btnAdd.Font = $fontRegular
    $btnAdd.Anchor = 'Top, Right'

    $btnRemove = New-Object System.Windows.Forms.Button
    $btnRemove.Text = "Remove Selected"
    $btnRemove.Location = New-Object System.Drawing.Point(680, 160)
    $btnRemove.Size = New-Object System.Drawing.Size(110, 30)
    $btnRemove.Font = $fontRegular
    $btnRemove.Anchor = 'Top, Right'

    $btnClear = New-Object System.Windows.Forms.Button
    $btnClear.Text = "Clear All"
    $btnClear.Location = New-Object System.Drawing.Point(680, 200)
    $btnClear.Size = New-Object System.Drawing.Size(110, 30)
    $btnClear.Font = $fontRegular
    $btnClear.Anchor = 'Top, Right'

    $btnView = New-Object System.Windows.Forms.Button
    $btnView.Text = "View Selected"
    $btnView.Location = New-Object System.Drawing.Point(680, 240)
    $btnView.Size = New-Object System.Drawing.Size(110, 30)
    $btnView.Anchor = 'Top, Right'

    $grpOptions = New-Object System.Windows.Forms.GroupBox
    $grpOptions.Text = "Options"
    $grpOptions.Location = New-Object System.Drawing.Point(15, 430)
    $grpOptions.Size = New-Object System.Drawing.Size(650, 70)
    $grpOptions.Font = $fontRegular
    $grpOptions.Anchor = 'Top, Right, Left'

    $lblFmt = New-Object System.Windows.Forms.Label
    $lblFmt.Text = "Format:"
    $lblFmt.Location = New-Object System.Drawing.Point(15, 30)
    $lblFmt.AutoSize = $true
    $lblFmt.Font = $fontRegular
    $lblFmt.Anchor = 'Left'

    $cmbFmt = New-Object System.Windows.Forms.ComboBox
    $cmbFmt.Location = New-Object System.Drawing.Point(80, 26)
    $cmbFmt.Size = New-Object System.Drawing.Size(120, 25)
    $cmbFmt.DropDownStyle = "DropDownList"
    $cmbFmt.Font = $fontRegular
    [void]$cmbFmt.Items.Add("png")
    [void]$cmbFmt.Items.Add("jpg")
    [void]$cmbFmt.Items.Add("bmp")
    [void]$cmbFmt.Items.Add("tiff")
    [void]$cmbFmt.Items.Add("gif")
    [void]$cmbFmt.Items.Add("tga")
    [void]$cmbFmt.Items.Add("dds")
    $cmbFmt.SelectedIndex = 0

    $btnConvert = New-Object System.Windows.Forms.Button
    $btnConvert.Text = "Convert"
    $btnConvert.Location = New-Object System.Drawing.Point(680, 470)
    $btnConvert.Size = New-Object System.Drawing.Size(110, 34)
    $btnConvert.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10, [System.Drawing.FontStyle]::Bold)
    $btnConvert.Anchor = 'Top, Right'

    $lblLog = New-Object System.Windows.Forms.Label
    $lblLog.Text = "Log:"
    $lblLog.Location = New-Object System.Drawing.Point(12, 510)
    $lblLog.AutoSize = $true
    $lblLog.Font = $fontRegular

    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Location = New-Object System.Drawing.Point(60, 505)
    $txtLog.Size = New-Object System.Drawing.Size(730, 60)
    $txtLog.Multiline = $true
    $txtLog.ScrollBars = "Vertical"
    $txtLog.ReadOnly = $false
    $txtLog.Font = $fontSmall
    $txtLog.Anchor = 'Top, Left, Right, Bottom'


    $form.Controls.AddRange(@(
            $lblTexconv, $txtTexconv, $btnBrowseTexconv,
            $lblOut, $txtOut, $btnBrowseOut,
            $lblFiles, $listFiles, $btnAdd, $btnRemove, $btnClear,
            $btnView,
            $grpOptions, $btnConvert, $lblLog, $txtLog
        ))
    $grpOptions.Controls.AddRange(@($lblFmt, $cmbFmt))

    $btnBrowseTexconv.Add_Click({
            $ofd = New-Object System.Windows.Forms.OpenFileDialog
            $ofd.Filter = "texconv.exe|texconv.exe|Executable files|*.exe|All files|*.*"
            $ofd.Title = "Select texconv.exe"
            if ($ofd.ShowDialog() -eq 'OK') { $txtTexconv.Text = $ofd.FileName }
        })

    $btnAdd.Add_Click({
            $ofd = New-Object System.Windows.Forms.OpenFileDialog
            $ofd.Filter = "DDS textures|*.dds"
            $ofd.Multiselect = $true
            $ofd.Title = "Select .dds files"
            if ($ofd.ShowDialog() -eq 'OK') {
                foreach ($f in $ofd.FileNames) {
                    if (-not $listFiles.Items.Contains($f)) { [void]$listFiles.Items.Add($f) }
                }
            }
        })

    $btnView.Add_Click({
            if ($listFiles.SelectedItems.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show("Select at least one file.") | Out-Null
                return
            }

            $texconv = $txtTexconv.Text.Trim()
            if (-not (Test-Path $texconv)) {
                [System.Windows.Forms.MessageBox]::Show("texconv.exe not found.") | Out-Null
                return
            }

            $outDir = $txtOut.Text.Trim()
            $tmp = Join-Path $env:TEMP ("dds2png_preview_" + [Guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Force -Path $tmp | Out-Null

            foreach ($dds in $listFiles.SelectedItems) {
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($dds) + ".png"

                $candidate1 = Join-Path ([System.IO.Path]::GetDirectoryName($dds)) $baseName
                $candidate2 = if (-not [string]::IsNullOrWhiteSpace($outDir)) { Join-Path $outDir $baseName } else { $null }
                $candidate3 = Join-Path $tmp $baseName

                $target = $null
                if (Test-Path $candidate1) { $target = $candidate1 }
                elseif ($candidate2 -and (Test-Path $candidate2)) { $target = $candidate2 }
                else {
                    $args = @("-ft", "png", "-o", $tmp, "-y", $dds)
                    $psi = New-Object System.Diagnostics.ProcessStartInfo
                    $psi.FileName = $texconv
                    $psi.Arguments = ($args | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
                    $psi.RedirectStandardOutput = $true
                    $psi.RedirectStandardError = $true
                    $psi.UseShellExecute = $false
                    $psi.CreateNoWindow = $true
                    $p = New-Object System.Diagnostics.Process
                    $p.StartInfo = $psi
                    $null = $p.Start(); $null = $p.WaitForExit()
                    if (Test-Path $candidate3) { $target = $candidate3 }
                }

                if ($target -and (Test-Path $target)) {
                    Start-Process $target
                }
                else {
                    [System.Windows.Forms.MessageBox]::Show("Could not preview:`n$dds") | Out-Null
                }
            }
        })


    $listFiles.Add_SelectedIndexChanged({
            $n = $listFiles.SelectedItems.Count
            $btnView.Text = if ($n -gt 1) { "View $n Selected" } else { "View Selected" }
        })

    $btnRemove.Add_Click({
            $sel = @($listFiles.SelectedItems)
            foreach ($item in $sel) { $listFiles.Items.Remove($item) }
        })

    $btnClear.Add_Click({ $listFiles.Items.Clear() })

    $listFiles.Add_DragEnter({
            param($sender, $e)
            if ($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
                $e.Effect = [Windows.Forms.DragDropEffects]::Copy
            }
            else { $e.Effect = [Windows.Forms.DragDropEffects]::None }
        })
    $listFiles.Add_DragDrop({
            param($sender, $e)
            $paths = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
            foreach ($p in $paths) {
                if ([System.IO.File]::Exists($p) -and ([System.IO.Path]::GetExtension($p)).ToLower() -eq ".dds") {
                    if (-not $listFiles.Items.Contains($p)) { [void]$listFiles.Items.Add($p) }
                }
            }
        })

    function Write-Log($msg) {
        $txtLog.AppendText(([DateTime]::Now.ToString("HH:mm:ss")) + "  " + $msg + [Environment]::NewLine)
    }

    function Select-FolderExplorer {
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Title = "Choose output folder"
        $dlg.InitialDirectory = [Environment]::GetFolderPath('Desktop')
        $dlg.ValidateNames = $false
        $dlg.CheckFileExists = $false
        $dlg.CheckPathExists = $true
        $dlg.FileName = "Select Folder"
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            return [System.IO.Path]::GetDirectoryName($dlg.FileName)
        }
        return $null
    }

    $btnBrowseOut.Add_Click({
            $sel = Select-FolderExplorer
            if ($sel) { $txtOut.Text = $sel }
        })

    $btnConvert.Add_Click({
            try {
                $texconv = $txtTexconv.Text.Trim()
                $outDir = $txtOut.Text.Trim()
                $fmt = $cmbFmt.SelectedItem.ToString()

                if (-not (Test-Path $texconv)) {
                    Show-ErrorDialog "texconv.exe not found. Please select the correct path."
                    return
                }
                if (-not (Test-Path $outDir)) {
                    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
                }
                if ($listFiles.Items.Count -eq 0) {
                    [System.Windows.Forms.MessageBox]::Show("No files to convert. Add or drop .dds files.", "Nothing to do", 'OK', 'Information') | Out-Null
                    return
                }

                Write-Log "Starting conversion of $($listFiles.Items.Count) file(s) to .$fmt..."

                foreach ($inFile in $listFiles.Items) {
                    Write-Log "Converting: $inFile"
                    $outFile = Join-Path $outDir (([System.IO.Path]::GetFileNameWithoutExtension($inFile)) + '.' + $fmt)

                    if (Test-Path $outFile) {
                        $result = [System.Windows.Forms.MessageBox]::Show(
                            "File already exists:`n$outFile`nOverwrite?", 
                            "Confirm Overwrite", 
                            [System.Windows.Forms.MessageBoxButtons]::YesNo, 
                            [System.Windows.Forms.MessageBoxIcon]::Warning
                        )
                        if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
                            Write-Log "Skipped (exists): $outFile"
                            continue
                        }
                    }

                    $args = @("-ft", $fmt, "-o", $outDir, "-y", $inFile)

                    $psi = New-Object System.Diagnostics.ProcessStartInfo
                    $psi.FileName = $texconv
                    $psi.Arguments = ($args | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
                    $psi.RedirectStandardOutput = $true
                    $psi.RedirectStandardError = $true
                    $psi.UseShellExecute = $false
                    $psi.CreateNoWindow = $true

                    $proc = New-Object System.Diagnostics.Process
                    $proc.StartInfo = $psi
                    $null = $proc.Start()
                    $stdout = $proc.StandardOutput.ReadToEnd()
                    $stderr = $proc.StandardError.ReadToEnd()
                    $proc.WaitForExit()
                    if ($stdout) { Write-Log $stdout.Trim() }
                    if ($stderr) { Write-Log ("stderr: " + $stderr.Trim()) }

                    if ($proc.ExitCode -eq 0) {
                        $oldColor = [Console]::ForegroundColor
                        [Console]::ForegroundColor = 'Green'
                        Write-Log "OK → $outFile"
                        [Console]::ForegroundColor = $oldColor
                    }
                    else {
                        $oldColor = [Console]::ForegroundColor
                        [Console]::ForegroundColor = 'Red'
                        Write-Log "ERROR ($($proc.ExitCode)) for $inFile"
                        if ($stderr) { Write-Log $stderr }
                        [Console]::ForegroundColor = $oldColor
                    }
                }

                $oldColor = [Console]::ForegroundColor
                [Console]::ForegroundColor = 'Green'
                Write-Log "Done."
                [Console]::ForegroundColor = $oldColor

                Write-Log "Done."
            }
            catch {
                Show-ErrorDialog "Unexpected error: $($_.Exception.Message)"
            }
        })

    [void]$form.ShowDialog()
}
catch {
    Show-ErrorDialog "Startup error: $($_.Exception.Message)"
}
