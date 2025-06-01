# Function to stress CPU for specific duration
$stressCPU = {
    param(
        [int]$targetPercent = 80,
        [int]$durationMinutes = 5
    )
    
    $cpuCores = (Get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors
    $coresToStress = [math]::Ceiling(($cpuCores * $targetPercent) / 100)
    $endTime = (Get-Date).AddMinutes($durationMinutes)
    
    $jobs = @()
    foreach ($i in 1..$coresToStress) {
        $jobs += Start-Job -ScriptBlock {
            $result = 1
            while ($true) {
                $result *= 1.000001
                if ($result -gt [double]::MaxValue / 2) {
                    $result = 1
                }
            }
        }
    }
    
    # Monitor until time expires
    while ((Get-Date) -lt $endTime) {
        $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        Write-Host "$(Get-Date -Format 'HH:mm:ss'): CPU Usage: $([math]::Round($cpu,2))%"
        Start-Sleep -Seconds 2
    }
    
    # Cleanup
    $jobs | Stop-Job
    $jobs | Remove-Job
}

# Start the stress test for 5 minutes
$mainJob = Start-Job -ScriptBlock $stressCPU -ArgumentList @(80, 5)

# To monitor
Receive-Job $mainJob -Wait
