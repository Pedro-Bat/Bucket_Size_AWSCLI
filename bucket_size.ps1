# Cria diretório se não existir
if (!(Test-Path "PATH")) {
    New-Item -Path "PATH" -ItemType Directory | Out-Null
}

# Função para formatar tamanhos de arquivo
function Format-FileSize {
    param ([long]$size)

    if ($size -ge 1TB) { return "{0:n2} TB" -f ($size / 1TB) }
    elseif ($size -ge 1GB) { return "{0:n2} GB" -f ($size / 1GB) }
    elseif ($size -ge 1MB) { return "{0:n2} MB" -f ($size / 1MB) }
    elseif ($size -ge 1KB) { return "{0:n2} KB" -f ($size / 1KB) }
    else { return "$size B" }
}


# Executa o comando AWS CLI -- Cuidado caso tente fazer numa pasta com nome parecido ex: teste/ teste_new/ só que sem a barra '/' pois o parametro recursive meio que coloca um * na consulta
# então a consulta do teste/ também vai trazer o teste_new ai para não ter isso coloque sempre a barra no final

$output = aws s3 ls "s3://bucketname" --recursive

# Data de processamento
$dataProcessamento = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Lista otimizada para armazenar os dados
$results = New-Object 'System.Collections.Generic.List[object]'

# Processa cada linha da saída
$output | ForEach-Object {
    if ($_ -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+(\d+)\s+(.*)$') {
        $results.Add([PSCustomObject]@{
            Path = $matches[3]
            FileDate = $matches[1]
            SizeBytes = [long]$matches[2]
        })
    }
}

# Agrupa por pasta e calcula os totais
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
        DATA_PROCESSAMENTO = $dataProcessamento
    }
}

# Calcula o total geral
$totalGeral = $results | Measure-Object -Property SizeBytes -Sum | Select-Object -ExpandProperty Sum

# Cria linha de total geral
$totalRow = [PSCustomObject]@{
    DATA_PROCESSAMENTO = $dataProcessamento
    FolderPath = "TOTAL GERAL"
    TotalSizeBytes = $totalGeral
    TotalSizeKB = [math]::Round($totalGeral / 1KB, 2)
    TotalSizeMB = [math]::Round($totalGeral / 1MB, 2)
    TotalSizeGB = [math]::Round($totalGeral / 1GB, 2)
    TotalSizeTB = [math]::Round($totalGeral / 1TB, 2)
    TotalSizeFormatted = (Format-FileSize $totalGeral)
    FileCount = $results.Count
}

# Prepara os dados para exportação
$exportData = @($totalRow) + $folderStats

# Exporta para CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = "PATH"

$exportData |
    Select-Object DATA_PROCESSAMENTO, FolderPath, TotalSizeBytes, TotalSizeKB, TotalSizeMB, TotalSizeGB, TotalSizeTB, TotalSizeFormatted, FileCount |
    Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
