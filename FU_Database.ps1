$ErrorActionPreference = "Continue"

$keywordLookup = "circuitboard"

$fuPath = "F:\Steam\steamapps\common\Starbound\mods\FrackinUniverse"

$fuWikiProps = @{
                'itemName'="Item Name";
                'fullName'="Full Name";
                'rarity'="No Rarity";
                'category'="No Category";
                'price'="No Price";
                'itemsLearned'=@();
                'recipeItemName'=@();
                'recipeItemCount'=@();
                'learnFrom'="Not Learned";
                'usedFor'=@();
                }

$fuWikiDB = @()
$fuWikiOBJ = New-Object -TypeName PSObject –Prop $fuWikiProps
$fuWikiDB += $fuWikiOBJ

#This function just for reference from PullCraftingMaterialInfo script, will go away
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

# -Exclude *.lua, *.ps1, *.csv, *.png, *.ogg, *.wav, *.txt, *.damage, *.frames, *.animation, *.activeitem, *.activeitem.patch, *.weather, *.treasurepools, *.npctype | 
$allFiles = Get-ChildItem -Path $fuPath\* -recurse -Include *.object, *.item |
                                Where-Object { $_.Attributes -ne "Directory"}

$count = 1;
$allCount = $allFiles.Count
$lastCheck = ""

function ConstructNewObjectEntry ($tmpFileJSON, $tmpItemName){

    $fuWikiOBJ.itemName = $itemName
    $fuWikiOBJ.rarity   = $tmpFileJSON.rarity
    $fuWikiOBJ.category = $tmpFileJSON.category
    $fuWikiOBJ.price    = $tmpFileJSON.price

    $tmpNameCheck = $tmpFileJSON.shortdescription -match '\;(.*)\^'

    if($tmpNameCheck -eq $false){
        $tmpNameCheck = $tmpFileJSON.shortdescription -match '\;(.*)'
    }

    if($tmpNameCheck){
        $fuWikiOBJ.fullName = $Matches[1]
    }
    else{
        $fuWikiOBJ.fullName = $fileJSON.shortdescription
    }

    foreach ($bp in $tmpFileJSON.learnBlueprintsOnPickup){
        if ($fuWikiOBJ.itemsLearned -notcontains $bp){
            $fuWikiOBJ.itemsLearned += $bp
        }  
    }

    foreach($interactData in $fileJSON.upgradeStages.interactData){
        if ($fuWikiOBJ.itemsLearned -notcontains $interactData.initialRecipeUnlocks){
            $fuWikiOBJ.itemsLearned += $interactData.initialRecipeUnlocks
        }  
    }

    $fuWikiOBJ
}

function UpdateExistingObjectEntry (){

}

$count = 1

foreach($file in $allFiles){
    
    $fuWikiOBJ = New-Object -TypeName PSObject –Prop $fuWikiProps

    $filePath = $file.FullName
    $fileBaseName = $file.BaseName
    $fileName = $file.Name
    $fileExt = $file.Extension

    $fileJSON = Get-Content -Path $filePath -raw | ConvertFrom-Json

    Switch ($fileExt){

        ".object" {
            $itemName = $fileJSON.objectName
            $itemDBIndex = $fuWikiDB.itemName.IndexOf($itemName)

            if($itemDBIndex -gt -1){
                $fuWikiDB[$itemDBIndex] = ConstructNewObjectEntry $fileJSON $itemName
            }
            else{
                $fuWikiDB += ConstructNewObjectEntry $fileJSON $itemName
            }
        }

        ".item" {
            $itemName = $fileJSON.itemName
            $itemDBIndex = $fuWikiDB.itemName.IndexOf($itemName)

            if($itemDBIndex -gt -1){
                #Write-Host "Got here $itemName"
                #Already exists, add .object related stuffs here
            }
            else{
                $fuWikiDB += ConstructNewObjectEntry $fileJSON $itemName
            }
        }

        ".recipe" {
            
        }

        ".patch" {
            
        }

        default {
            "Unsupported File Extension"
        }
    }
}

$fuWikiOBJ = ""

$fuWikiDB