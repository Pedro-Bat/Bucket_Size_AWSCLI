$LogFile = "PATH_LOG$(Get-Date -Format 'yyyyMMdd').log"
$Global:LogLevel = "INFO"  # DEBUG, INFO, WARN, ERROR

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO",
        [string]$LogFile = "C:\temp\test.log"
    )

    $logLevels = @{ "DEBUG" = 0; "INFO" = 1; "WARN" = 2; "ERROR" = 3 }
    if ($logLevels[$Level] -lt $logLevels[$Global:LogLevel]) { return }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    Write-Output $logEntry
    Add-Content -Path $LogFile -Value $logEntry
}

# Create directory if it doesn't exist
if (!(Test-Path "PATH")) {
    New-Item -Path "PATH" -ItemType Directory | Out-Null
    Write-Log -Message "Directory PATH CREATED"
}

# Function to format file sizes
function Format-FileSize {
    param ([long]$size)

    if ($size -ge 1TB) { return "{0:n2} TB" -f ($size / 1TB) }
    elseif ($size -ge 1GB) { return "{0:n2} GB" -f ($size / 1GB) }
    elseif ($size -ge 1MB) { return "{0:n2} MB" -f ($size / 1MB) }
    elseif ($size -ge 1KB) { return "{0:n2} KB" -f ($size / 1KB) }
    else { return "$size B" }
}

# Run AWS CLI command
Write-Log -Message "Fetching AWS directory list"
$output = aws s3 ls "s3://ofsa-datalake/Vexpenses" --recursive

Write-Log -Message "Starting Table Processing"
# Processing date
$processingDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Optimized list to store the data
$results = New-Object 'System.Collections.Generic.List[object]'

# Process each output line
$output | ForEach-Object {
    if ($_ -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+(\d+)\s+(.*)$') {
        $results.Add([PSCustomObject]@{
            Path = $matches[3]
            FileDate = $matches[1]
            SizeBytes = [long]$matches[2]
            PROCESSING_DATE = $processingDate
        })
    }
}

# Group by folder and calculate totals
$folderStats = $results | Group-Object {
    if ($_.Path -match '^(.*/)[^/]+$') { $matches[1] } else { $_.Path }
} | ForEach-Object {
    $totalBytes = ($_.Group | Measure-Object -Property SizeBytes -Sum).Sum

    [PSCustomObject]@{
        FolderPath = $_.Name
        TotalSizeBytes = $totalBytes
        TotalSizeKB = [math]::Round($totalBytes / 1KB, 2)
        TotalSizeMB = [math]::Round($totalBytes / 1MB, 2)
        TotalSizeGB = [math]::Round($totalBytes / 1GB, 2)
        TotalSizeTB = [math]::Round($totalBytes / 1TB, 2)
        TotalSizeFormatted = (Format-FileSize $totalBytes)
        FileCount = $_.Count
        PROCESSING_DATE = $processingDate
    }
}

# Calculate overall total
$overallTotal = $results | Measure-Object -Property SizeBytes -Sum | Select-Object -ExpandProperty Sum

# Create overall total row
$totalRow = [PSCustomObject]@{
    PROCESSING_DATE = $processingDate
    FolderPath = "OVERALL TOTAL"
    TotalSizeBytes = $overallTotal
    TotalSizeKB = [math]::Round($overallTotal / 1KB, 2)
    TotalSizeMB = [math]::Round($overallTotal / 1MB, 2)
    TotalSizeGB = [math]::Round($overallTotal / 1GB, 2)
    TotalSizeTB = [math]::Round($overallTotal / 1TB, 2)
    TotalSizeFormatted = (Format-FileSize $overallTotal)
    FileCount = $results.Count
}

# Prepare data for export
$exportData = @($totalRow) + $folderStats

# Export to CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = "C:\talendTemp\DATALAKE_SIZE\datalake_$timestamp.csv"

$exportData |
    Select-Object PROCESSING_DATE, FolderPath, TotalSizeBytes, TotalSizeKB, TotalSizeMB, TotalSizeGB, TotalSizeTB, TotalSizeFormatted, FileCount |
    Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# Show summary
Write-Log "Report generated at: $csvPath"
Write-Log "Overall total: $($totalRow.TotalSizeFormatted) ($($totalRow.FileCount) files)"
