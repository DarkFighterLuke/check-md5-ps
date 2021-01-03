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

$global:counter = 0 
 
# Merges two sorted halves of a subarray 
# $theArray is an array of comparable objects 
# $tempArray is an array to place the merged result 
# $leftPos is the left-most index of the subarray 
# $rightPos is the index of the start of the second half 
# $rightEnd is the right-most index of the subarray 
function merge($theArray, $tempArray, [int] $leftPos, [int] $rightPos, [int] $rightEnd) 
{ 
    $leftEnd = $rightPos - 1 
    $tmpPos = $leftPos 
    $numElements = $rightEnd - $leftPos + 1 
     
    # Main loop 
    while (($leftPos -le $leftEnd) -and ($rightPos -le $rightEnd)) 
    { 
        $global:counter++ 
        if ($theArray[$leftPos].CompareTo($theArray[$rightPos]) -le 0) 
        { 
            $tempArray[$tmpPos++] = $theArray[$leftPos++] 
        } 
        else 
        { 
            $tempArray[$tmpPos++] = $theArray[$rightPos++] 
        } 
    } 
     
    while ($leftPos -le $leftEnd) 
    { 
        $tempArray[$tmpPos++] = $theArray[$leftPos++] 
    } 
     
    while ($rightPos -le $rightEnd) 
    { 
        $tempArray[$tmpPos++] = $theArray[$rightPos++] 
    } 
     
    # Copy $tempArray back 
    for ($i = 0; $i -lt $numElements; $i++, $rightEnd--) 
    { 
        $theArray[$rightEnd] = $tempArray[$rightEnd] 
    } 
} 
 
# Makes recursive calls 
# $theArray is an array of comparable objects 
# $tempArray is an array to place the merged result 
# $left is the left-most index of the subarray 
# $right is the right-most index of the subarray 
function mergesorter( $theArray, $tempArray, [int] $left, [int] $right ) 
{ 
    if ($left -lt $right) 
    { 
        [int] $center = [Math]::Floor(($left + $right) / 2) 
        mergesorter $theArray $tempArray $left $center 
        mergesorter $theArray $tempArray ($center + 1) $right 
        merge $theArray $tempArray $left ($center + 1) $right 
    } 
}

function Binary-Search {
    Param (
        [Parameter(Mandatory=$True)
        ]

        $InputArray,
        $SearchVal,
        $Attribute)

    $LowIndex = 0                              #Low side of array segment
    $Counter = 0
    $TempVal = ""                              #Used to determine end of search where $Found = $False
    $HighIndex = $InputArray.count             #High Side of array segment
    [int]$MidPoint = ($HighIndex-$LowIndex)/2  #Mid point of array segment
    $found = $False


    While($LowIndex -le $HighIndex){
        $MidVal = $InputArray[$MidPoint]
                                                    
        If($TempVal -eq $MidVal){              #If identical, the search has completed and $Found = $False
            $found = $False
            Return
        }
        else{
            $TempVal = $MidVal                 #Update the TempVal. Search continues.
        }
        
        If($SearchVal -lt $MidVal) {
            $Counter++
            $HighIndex = $MidPoint 
            [int]$MidPoint = (($HighIndex-$LowIndex)/ 2 +$LowIndex)
        }
        If($SearchVal -gt $MidVal) {
            $Counter++
            $LowIndex = $MidPoint 
            [int]$MidPoint = ($MidPoint+(($HighIndex - $MidPoint) / 2))         
        }
        If($SearchVal -eq $MidVal) {
            $found = $True 
            break
        }
    }
    return $found
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

Write-Host "Sorting second file with MergeSort..."
$tempArray = New-Object Object[] $file2.Count 
mergesorter $file2 $tempArray 0 ($file2.Count - 1) 
Write-Host "MergeSort finished."

Write-Output "`t--- Start of comparison ---`n"
for($i=$startIndex; $i -lt $file1.length; $i++){
    $found=Binary-Search $file2 $file1[$i]
    if($found){
        Write-Output $($filename1+"  OK"+"`t`t["+$($i+1)+"/"+$totalLines+"]")
    }
    else{
        Write-Output $($file1[$i]+"  NO!"+"`t`t["+$($i+1)+"/"+$totalLines+"]")| Out-File -Path $results -Append
    }
    $resumeData[2]=$i
    $resumeData | Out-File -Path $scriptDataPath
}

Write-Output "`n`t--- End of comparison ---"
Remove-Item $scriptDataPath -Force
