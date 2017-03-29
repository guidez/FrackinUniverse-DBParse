$ErrorActionPreference = "Continue"

$keywordLookup = "circuitboard"

$fuPath = "F:\Steam\steamapps\common\Starbound\mods\FrackinUniverse"

function PullData($tmpFilePath, $tmpFileExt, $tmpFileBaseName){
    
    $fileJSON = Get-Content -Path $tmpFilePath | ConvertFrom-Json

    #Learned From section
    if ($tmpFileExt -like '.patch' -and $fileJSON.path -like '/learnBlueprintsOnPickup'){
        Write-Output "$keywordLookup is learned from: $fileBaseName"
        Write-Output ""
    }
    elseif ($fileJSON.learnBlueprintsOnPickup -contains $keywordLookup){
        Write-Output "$keywordLookup is learned from: $fileBaseName"
        Write-Output ""
    }

    #Crafting Recipe section 1 - How to craft
    elseif ("$($tmpFileBaseName)$($tmpFileExt)" -like "$keywordLookup.recipe"){
        Write-Output "Recipe:"
        foreach ($inputVal in $fileJSON.input){
            Write-Output "$($inputVal.item)x$($inputVal.count)"
        }
        Write-Output ""
    }

    #Crafting Recipe section 2 - Used in crafting for
    elseif ("$($tmpFileExt)" -like ".recipe"){
        Write-Output "Used in crafting for: $($fileJSON.output[0].item)"
    }

    #HowToLearn Section
    elseif ($($fileJSON.upgradeStages.interactData.initialRecipeUnlocks) -contains $keywordLookup){
        foreach($interactData in $fileJSON.upgradeStages.interactData){
            
            if ($($interactData.initialRecipeUnlocks) -contains $keywordLookup){
                Write-Output "Learned from: $($interactData.filter[0])"
            }

        }
    }

    #Create Basic information
    else{
        if($fileJSON.itemName -notlike ''){
            $tmpItemID = $fileJSON.itemName
        }
        elseif ($fileJSON.objectName -notlike ''){
            $tmpItemID = $fileJSON.objectName
        }

        if($tmpItemID -like $keywordLookup){
            $tmpNameCheck = $fileJSON.shortdescription -match '\;(.*)\^'
    
            if($tmpNameCheck -eq $false){
                $tmpNameCheck = $fileJSON.shortdescription -match '\;(.*)'
            }

            if($tmpNameCheck){
                $tmpItemName = $Matches[1]
            }
            else{
                $tmpItemName = $fileJSON.shortdescription
            }

            Write-Output "Player Friendly Name: $tmpItemName"
            Write-Output "Rarity: $($fileJSON.rarity)"
            Write-Output "Category: $($fileJSON.category)"
            Write-Output "Price: $($fileJSON.price)"
            Write-Output "Icon: $($fileJSON.inventoryIcon)"
            Write-Output "Spawn Item Name: $tmpItemID"
            Write-Output ""
            Write-Output "Items Learned on Pickup:"
            foreach ($bp in $($fileJSON.learnBlueprintsOnPickup)){
                Write-Output "$bp"
            }
            Write-Output ""
            
        }
        
    }
}


$allFiles = Get-ChildItem -Path $fuPath\* -recurse -Exclude *.lua, *.ps1, *.csv, *.png, *.ogg, *.wav, *.txt, *.damage, *.frames, *.animation, *.weather | 
                                Where-Object { $_.Attributes -ne "Directory"}

$count = 1;
$allCount = $allFiles.Count
$lastCheck = ""
Write-Host ""

$parsedData = foreach($file in $allFiles){

    $filePath = $file.FullName
    $fileBaseName = $file.BaseName
    $fileName = $file.Name
    $fileExt = $file.Extension
    
    #$perc =  ($count/$allCount)*100

    #Write-Progress -Activity "Parsing files..." -PercentComplete $perc -Status "$perc% Complete"
    Write-Host "Processing file $count of $allCount"
    

    $fileContents = Get-Content -Path $filePath
    
    if ($fileContents -match $keywordLookup){
        Write-Output "`n--$filePath contains $keywordLookup--"
        #Write-Output $fileExt
        if($fileBaseName -like $keywordLookup){
            PullData $filePath $fileExt $fileBaseName
        }
        else{
            for ($x = 0; $x -lt $fileContents.Count; $x++){
                if ($fileContents[$x] -match $keywordLookup){
                    $dupCheck = PullData $filePath $fileExt $fileBaseName

                    if ($dupCheck -notlike $lastCheck){
                        $lastCheck = $dupCheck
                        $lastCheck
                    }

                }
            }
        }
    }

    $count++

} 

$parsedData 