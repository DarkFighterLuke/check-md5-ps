if($args.length -ne 3){
    Write-Output $("Wrong parameters number!\nThese 3 parameters are needed:`n - First checksum file`n - Second checksum file`n - File where to write negative results of the comparison`n")
    exit
}
$filepath1=$args[0]
$filepath2=$args[1]
$file1=Get-Content $args[0]
$file2=Get-Content $args[1]

$results=$args[2]
$matchFound=$True
$totalLines=$file1.length
$startIndex=0
$resumeData=@(0)*3

$scriptDataPath=".check_md5/.resume_data"

if(-not (Test-Path $results -PathType Leaf)){
    New-Item $results -Force | Out-Null
}

function generateResumeData{
    New-Item $scriptDataPath -Force | Out-Null
    Write-Output "Calculating md5 of the files to compare..."
    $integrity1=$(md5deep $filepath1).Substring(0, 32)
    $integrity2=$(md5deep $filepath2).Substring(0, 32)
    Add-Content -Path $scriptDataPath $integrity1 | Out-Null
    Add-Content -Path $scriptDataPath $integrity2 | Out-Null
    $resumeData[0]=$integrity1
    $resumeData[1]=$integrity2
    return
}

if(Test-Path $scriptDataPath -PathType Leaf){
    Write-Output "Parsing resume data..."
    $resumeData=Get-Content $scriptDataPath
    if($resumeData.length -ne 3){
        $resumeData=@(0)*3
        Write-Output "Corrupted resume data file. Deleting..."
        Remove-Item $scriptDataPath -Force
        generateResumeData
    }
    else{
        $oldIntegrity1=$resumeData[0]
        $oldIntegrity2=$resumeData[1]
        Write-Output "Calculating md5 of the files to compare..."
        $integrity1=(md5deep $args[0]).Substring(0, 32)
        $integrity2=(md5deep $args[1]).Substring(0, 32)
        if($integrity1 -eq $oldIntegrity1){
            Write-Output "Files to compare md5 matched! Starting from the last index before interruption."
            $startIndex=$resumeData[2] -as [int]
        }
        else{
            Write-Output "Files to compare md5 mismatch. Starting from the first index."
        }
    }
}
else{
    Write-Output "No old execution data found."
    generateResumeData
}

#TODO: Switch to mergesort + binary research
#TODO: Make the comparison multithread dividing file1 records in n_cpu_cores parts
Write-Output "`t--- Start of comparison ---`n"
for($i=$startIndex; $i -lt $file1.length; $i++){
    $line1=$file1[$i]
    $filename1=$line1.Substring(34)
    foreach($line2 in $file2){
        $filename2=$line2.Substring(34)
        if($filename1 -eq $filename2){
            $md51=$line1.Substring(0, 32)
            $md52=$line2.Substring(0, 32)
            if($md51 -ne $md52){
                Write-Output $($md51+"  "+$md52+"`t"+$filename1+"  NO!")| Out-File -Path $results -Append
            }
            else{
                Write-Output $($md51+"`t"+$filename1+"  OK"+"`t`t["+$($i+1)+"/"+$totalLines+"]")
            }
            $matchFound=$True;
        }
        elseif(-not $matchFound){
            Write-Host $($filename1+":`tRow not found!") | Out-File -Path $results -Append
        }
    }
    $resumeData[2]=$i
    $resumeData | Out-File -Path $scriptDataPath
}
Write-Output "`n`t--- End of comparison ---"
Remove-Item $scriptDataPath -Force
