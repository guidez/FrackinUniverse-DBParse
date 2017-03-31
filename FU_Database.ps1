#Next steps:
# PATCH FILES1!!!!1!!

$ErrorActionPreference = "Continue"

$fuPath = "F:\Steam\steamapps\common\Starbound\mods\FrackinUniverse"

$fuWikiProps = @{
                'itemName'="Item Name"
                'fullName'="Full Name"
                'rarity'="No Rarity"
                'category'="No Category"
                'price'="No Price"
                'upgradesFrom'=""
                'upgradesTo'=""
                'upgradeItemCostName'=@()
                'upgradeItemCostCount'=@()
                'itemsLearned'=@()
                'recipeItemName'=@()
                'recipeItemCount'=@()
                'learnFrom'=@()
                'usedFor'=@()
                'craftedAt'=@()
                }

$errorPathArray = @()

#Uncomment this for first time run, or account for it in host window first
$fuWikiDB = @()
$fuWikiOBJ = New-Object -TypeName PSObject –Prop $fuWikiProps
$fuWikiDB += $fuWikiOBJ

function CleanOutComments ($tmpFile){

    $starterJSON = "[`n";
    $reader = [System.IO.File]::OpenText($tmpFile.FullName)
    try {
        for() {
            $line = $reader.ReadLine()
            if ($line -eq $null) { break }
            $starterJSON += "  " + $line + "`n"
        }
    }
    finally {
        $reader.Close()
    }

    $starterJSON += "`n]"

    $blockRegex = "/\*[^*]*\*+(?:[^*/][^*]*\*+)*/";
    $lineRegex = "(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|(//.*)"

    $starterJSON = $starterJSON -replace $blockRegex;
    $starterJSON = $starterJSON -replace $lineRegex;

    $starterJSON

}

function ConstructDBEntry ($tmpFileJSON, $tmpName){

    $fuWikiOBJ.category = $tmpFileJSON.category

    if ($fuWikiOBJ.category -like "crafting"){
        for ($x = 0; $x -lt $tmpFileJSON.upgradeStages.Count; $x++){
            $fuWikiOBJWB = New-Object -TypeName PSObject –Prop $fuWikiProps

            $fuWikiOBJWB.itemName = $tmpFileJSON.upgradeStages[$x].interactData.filter[$x]
            $fuWikiOBJWB.fullName = ($tmpFileJSON.upgradeStages[$x].interactData.paneLayoutOverride.windowTitle.title).trim()
            $fuWikiOBJWB.rarity = $tmpFileJSON.rarity
            $fuWikiOBJWB.category = $tmpFileJSON.category

            if ($x -eq 0){
                $fuWikiOBJWB.price = $tmpFileJSON.price
            }
            else{
                $fuWikiOBJWB.price = $tmpFileJSON.upgradeStages[$x].itemSpawnParameters.price
                $fuWikiOBJWB.upgradesFrom = ($tmpFileJSON.upgradeStages[($x-1)].interactData.paneLayoutOverride.windowTitle.title).trim()
            }
            
            if ($x -lt $tmpFileJSON.upgradeStages.Count-1){
                $fuWikiOBJWB.upgradesTo = ($tmpFileJSON.upgradeStages[($x+1)].interactData.paneLayoutOverride.windowTitle.title).trim()
            }

            foreach ($tmpInput in $tmpFileJSON.upgradeStages[$x].interactData.upgradeMaterials){
                $fuWikiOBJWB.upgradeItemCostName += $tmpInput.item
                $fuWikiOBJWB.upgradeItemCostCount += $tmpInput.count
            }

            foreach($initialRecipe in $tmpFileJSON.upgradeStages[$x].interactData.initialRecipeUnlocks){
                if ($fuWikiOBJWB.itemsLearned -notcontains $initialRecipe){
                    $fuWikiOBJWB.itemsLearned += $initialRecipe
                }
            }

            foreach($learnedBP in $tmpFileJSON.upgradeStages[$x].learnBlueprintsOnPickup){
                
                if ($fuWikiOBJWB.itemsLearned -notcontains $learnedBP){
                    $fuWikiOBJWB.itemsLearned += $learnedBP
                }
            }
            
            $script:fuWikiDB += $fuWikiOBJWB
        }
    }
    else{
        $fuWikiOBJ.itemName = $tmpName
        $fuWikiOBJ.rarity = $tmpFileJSON.rarity
        $fuWikiOBJ.price = $tmpFileJSON.price

        #Regex section for removing the coloring codes from the full name of an object
        $tmpNameCheck = $tmpFileJSON.shortdescription -match '\;(.*)\^'

        if($tmpNameCheck -eq $false){
            $tmpNameCheck = $tmpFileJSON.shortdescription -match '\;(.*)'
        }

        if($tmpNameCheck){
            $fuWikiOBJ.fullName = $Matches[1]
        }
        else{
            $fuWikiOBJ.fullName = $tmpFileJSON.shortdescription
        }
        #--End regex section

        foreach ($bp in $tmpFileJSON.learnBlueprintsOnPickup){
            if ($fuWikiOBJ.itemsLearned -notcontains $bp){
                $fuWikiOBJ.itemsLearned += $bp
            }  
        }

        foreach($initialRecipe in $tmpFileJSON.upgradeStages.interactData){
            if ($fuWikiOBJ.itemsLearned -notcontains $initialRecipe){
                $fuWikiOBJ.itemsLearned += $initialRecipe
            }
        }

        #Script: part modifies the db/array variable outside of the function
        $script:fuWikiDB += $fuWikiOBJ
    }

}

function ConstructDBRecipeEntry ($tmpFileJSON, $tmpRecipeName){
    
    for ($x = 0; $x -lt $fuWikiDB.Count; $x++){
        
        if ($fuWikiDB[$x].itemName -eq $tmpRecipeName -or $fuWikiDB[$x].itemName -like "$tmpRecipeName*"){
            
            foreach ($tmpInput in $tmpFileJSON.input){
                $fuWikiDB[$x].recipeItemName += $tmpInput.item
                $fuWikiDB[$x].recipeItemCount += $tmpInput.count
            }

            $fuWikiDB[$x].craftedAt = $tmpFileJSON.groups

            break
        }
    }

}

function ArrayOutString($tmpArray){

    $returnString = "."

    foreach($thing in $tmpArray){
        if ($returnString -eq "."){
            $returnString = "$thing"
        }
        else{
            $returnString = $returnString + "| $thing"
        }
        
    }

    $returnString
}

function ExportDBToCSV ($tmpDB){
    $tmpDB | Select  itemName,
                        fullName,
                        rarity,
                        category,
                        price,
                        upgradesFrom,
                        upgradesTo,
                        @{Name="upgradeItemCostName";Expression={ArrayOutString $_.upgradeItemCostName}},
                        @{Name="upgradeItemCostCount";Expression={ArrayOutString $_.upgradeItemCostCount}},
                        @{Name="itemsLearned";Expression={ArrayOutString $_.itemsLearned}},
                        @{Name="recipeItemName";Expression={ArrayOutString $_.recipeItemName}},
                        @{Name="recipeItemCount";Expression={ArrayOutString $_.recipeItemCount}},
                        @{Name="learnFrom";Expression={ArrayOutString $_.learnFrom}},
                        @{Name="usedFor";Expression={ArrayOutString $_.usedFor}},
                        @{Name="craftedAt";Expression={ArrayOutString $_.craftedAt}} | export-csv -Path ".\Export.Csv" -NoTypeInformation
}

Write-Host "Parsing OBJ/Items..."
#region Get Object files and Item files
$allFiles = Get-ChildItem -Path $fuPath\* -recurse -Include *.object, *.item | Where-Object { $_.Attributes -ne "Directory"}
$allCount = $allFiles.Count
$currCount = 1

foreach($file in $allFiles){
    
    #Write-Host "Parsing file $currCount of $($allFiles.Count)"

    #Clear any previous errors
    $error.clear()

    $fuWikiOBJ = New-Object -TypeName PSObject –Prop $fuWikiProps

    $filePath = $file.FullName
    $fileBaseName = $file.BaseName
    $fileExt = $file.Extension

    try {
        $cleanedFile = CleanOutComments $file
        
        $fileJSON = $cleanedFile | ConvertFrom-Json
    }
    catch{
        Write-Host "Could not convert $($file.Name) to JSON! Check path array."
        $errorPathArray += $filePath
    }

    #If no error from try/catch occurred, let's parse
    if(!$error){
        Switch ($fileExt){

            ".object" {
                ConstructDBEntry $fileJSON $fileJSON.objectName
            }

            ".item" {
                ConstructDBEntry $fileJSON $fileJSON.itemName
            }

            default {
                Write-Host "Unsupported File Extension"
            }
        }
    }

    $currCount++
}
#endregion

Write-Host "Parsing Recipes..."
#region Get Recipe files
$allFiles = Get-ChildItem -Path $fuPath\* -recurse -Include *.recipe | Where-Object { $_.Attributes -ne "Directory"}
$allCount = $allFiles.Count
$currCount = 1

foreach($file in $allFiles){

    #Clear any previous errors
    $error.clear()

    $fuWikiOBJ = New-Object -TypeName PSObject –Prop $fuWikiProps

    $filePath = $file.FullName
    $fileBaseName = $file.BaseName
    $fileExt = $file.Extension

    try {
        $cleanedFile = CleanOutComments $file
        
        $fileJSON = $cleanedFile | ConvertFrom-Json
    }
    catch{
        Write-Host "Could not convert recipe $($file.Name) to JSON! Check path array."
        $errorPathArray += $filePath
    }

    if(!$error){
        ConstructDBRecipeEntry $fileJSON $fileBaseName
    }
    
    $currCount++
}
#endregion

$fuWikiOBJ = ""

Write-Host "Correlating Item Names to Full Names..."
for ($x = 0; $x -lt $fuWikiDB.Count; $x++){
    
    #Write-Host "Clarifying $x of $($fuWikiDB.Count - 1)"

    $currentItem = $fuWikiDB[$x].itemName
    $currentItemFullName = $fuWikiDB[$x].fullName

    for ($y = 0; $y -lt $fuWikiDB.Count; $y++){

        $itemIndex = $fuWikiDB[$y].itemsLearned.IndexOf($currentItem)

        if ($itemIndex -ge 0 -and $fuWikiDB[$x].learnFrom -notcontains $fuWikiDB[$y].fullName){
            
            $fuWikiDB[$x].learnFrom += $fuWikiDB[$y].fullName

        }

        $itemIndex = $fuWikiDB[$y].recipeItemName.IndexOf($currentItem)

        if ($itemIndex -ge 0){
            $fuWikiDB[$y].recipeItemName[$itemIndex] = $currentItemFullName
        }
    }
}

Write-Host "Writing to CSV file..."
ExportDBToCSV $fuWikiDB