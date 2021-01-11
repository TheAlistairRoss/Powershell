<#
.Synopsis
   Creates a custom Log file for monitoring 
.DESCRIPTION
   This creates a log file based on the FinancialApplication.exe. It can output varing number of entries, entered over a given time period and formatted for different scenarios
.EXAMPLE
   ./New-FinancialApplication.ps1 

   This will enter 10,000 entries, over a 30 second period into "C:\Temp\FinancialApplication.txt" with the space character as the seperator.

   Entry example : 2021-01-11 18:09:45 1 More resource required
.EXAMPLE
   ./New-FinancialApplication.ps1 -Count 5000 TimeRange 120 -Directory C:\Logs -Type CommaDelimeter

   This will enter 5000 entries, over a 120 second period to C:\Logs\FinancialApplication.txt with the values seperated by a comma

   Entry example : 2021-01-11 18:09:45,1,More resource required
.EXAMPLE
   ./New-FinancialApplication.ps1  -Type NamedFields -ShowProgress

   This will enter 10,000 entries, over a 30 second period into "C:\Temp\FinancialApplication.txt" with the each field named and a progress bar shown.
   
   Entry example : TimeDate=2021-01-11 18:09:45 EventId=1 Message=More resource required
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   This was written for custom log file monitoring on windows OS
#>   
[CmdletBinding()]
param(
    [ValidateRange(1, 10000)]
    [int]
    $Count = 10000,
    #Number of entries to write. Between 1 and 10000. Default=100000
    [ValidateRange(0, 300)]
    [int]
    $TimeRange = 30,
    #Time span (in seconds) which to write the entries across. Between 0 and 300 seconds. Default=30

    [string]
    $Directory = "C:\Temp",
    #Output Directory. Default=C:\Temp

    [ValidateSet("SpaceDelimeter", "CommaDelimeter", "NamedFields")]
    [string]
    $Type = "SpaceDelimeter",
    # Changes the formatting of the log entry. Default=SpaceDelimeter

    [switch]
    $Force,
    #Overwrites the exisiting log file

    [switch]
    $ShowProgress 
    #Shows a progress bar using Write-Progress when writing the log entries
)

$Directory = $Directory.TrimEnd("\")
$FilePath = "$Directory\FinancialApplication.txt"

function New-LogFile {
    param (
        [string]
        $FilePath,

        [switch]
        $Force
    )

    Try {
        $LogFile = Get-Item -Path $FilePath -ErrorAction Stop
        If ($LogFile) {
            Write-Host "`'$FilePath`' found" -ForegroundColor Green
        }
        If ($Force) {
            Write-Host "Overwriting `'$FilePath`'" -ForegroundColor Yellow
        }
    }
    Catch {
        Try {
            $LogFile = New-Item -Path $FilePath -Force -ErrorAction Stop
            If ($LogFile) {
                Write-Host "`'$FilePath`' created" -ForegroundColor Green
            }
        }
        Catch {
            Write-Error -Message "Failed to create file `'$FilePath`', check permissions and try again"
            break
        }
        return $LogFile
    }
}

function New-RandomLogEntry {
    param(
        [ValidateSet("SpaceDelimeter", "CommaDelimeter", "NamedFields")]
        [string]
        $Type = "SpaceDelimeter"
    )
    $Date = Get-Date -UFormat "%Y-%m-%d %H:%M:%S"
    $Hash = @{
        1 = "More resource required"
        2 = "Restart required"
        3 = "Security Issue"
        4 = "Initialization completed"
    }
    $Rand = Get-Random -Minimum 1 -Maximum 4

    if ($Type -eq "CommaDelimeter") {
        $Output = "$Date,$Rand,$($Hash.$Rand)"
    }
    elseif ($Type -eq "NamedFields") {
        $Output = "TimeDate=$Date EventId=$Rand Message=$($Hash.$Rand)"
    }
    else {
        $Output = "$Date $Rand $($Hash.$Rand)"
    }

    return $Output
}


function Add-LogEntry {
    param (
        [ValidateRange(1, 10000)]
        [int]
        $Count = 1000,

        [ValidateRange(0, 300)]
        [int]
        $TimeRange = 60,

        [string]
        $FilePath,

        [bool]
        $ShowProgress
    
    )
   
    $Array = [string[]]::new($Count)
    New-LogFile -FilePath $FilePath
    
    if ($TimeRange -gt 0 ) {
        [int]$Pause = ($Count / $TimeRange)
        [int]$IntialDelay = $Pause
        Write-Host "This will take approximatly $TimeRange Seconds to complete. Use -ShowProgress to output the progress" -ForegroundColor Yellow
    }

    $Start = (Get-Content -Path $FilePath).count

    $i = 0
    do {
        if ($i -ge $Pause -and $TimeRange -gt 0) {
            Start-Sleep -Seconds 1
            $Pause = $Pause + $IntialDelay
            if ($ShowProgress -and $i -lt $Count) {
                $SecondsRemaining = $TimeRange - $SecondsPassed
                $PercentComplete = (100 / $TimeRange) * ($TimeRange - $SecondsRemaining)
                $SecondsPassed = $SecondsPassed + 1
                $SecondsRemaining = $TimeRange - $SecondsPassed
                Write-Progress -Activity "Writing Log Files" -Status "$i entries added" -SecondsRemaining $SecondsRemaining -PercentComplete $PercentComplete 
            }
        } 
        $Array[$i] = New-RandomLogEntry
        $i++
    }
    until (
        $i -ge $Count
    )
    if ($ShowProgress -and $TimeRange -gt 0) {
        Write-Progress -Activity "Writing Log Files" -Status "$i entries added" -SecondsRemaining $SecondsRemaining -PercentComplete $PercentComplete -Completed
    }
    $Array | Out-File -FilePath $FilePath -Append -Force
    $End = (Get-Content -Path $FilePath).count
    Write-Host "$($End - $Start) entries added"
}

Add-LogEntry -Count $Count -TimeRange $TimeRange -FilePath $FilePath -ShowProgress $ShowProgress
