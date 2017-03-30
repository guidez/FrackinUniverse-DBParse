$ErrorActionPreference = "Continue"

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
                'learnFrom'=@();
                'usedFor'=@();
                }

$errorPathArray = @()

#Uncomment this for first time run, or account for it in host window first
#$fuWikiDB = @()
$fuWikiOBJ = New-Object -TypeName PSObject –Prop $fuWikiProps
$fuWikiDB += $fuWikiOBJ

# -Exclude *.lua, *.ps1, *.csv, *.png, *.ogg, *.wav, *.txt, *.damage, *.frames, *.animation, *.activeitem, *.activeitem.patch, *.weather, *.treasurepools, *.npctype | 
$allFiles = Get-ChildItem -Path $fuPath\* -recurse -Include *.object, *.item |
                                Where-Object { $_.Attributes -ne "Directory"}
$allCount = $allFiles.Count
$lastCheck = ""

function ConstructDBEntry ($tmpFileJSON, $tmpName){
    
    #Check if item already exists
    $dbEntryIndex = -1
    for ($x = 0; $x -lt $fuWikiDB.Count; $x++){
        if ($fuWikiDB[$x].itemName -like $tmpName){
            $dbEntryIndex = $x;
            break
        }
    }

    #region Item Exists
    if ($dbEntryIndex -ge 0){
        Write-Host "Updating existing entry: $($fuWikiDB[$x].itemName)"
        if ($tmpFileJSON.rarity -notlike ""){
            $fuWikiDB[$x].rarity = $tmpFileJSON.rarity
        }

        if ($tmpFileJSON.category -notlike ""){
            $fuWikiDB[$x].category = $tmpFileJSON.category
        }

        if ($tmpFileJSON.price -notlike ""){
            $fuWikiDB[$x].price = $tmpFileJSON.price
        }

        if ($tmpFileJSON.shortdescription -notlike ""){
            $tmpNameCheck = $tmpFileJSON.shortdescription -match '\;(.*)\^'

            if($tmpNameCheck -eq $false){
                $tmpNameCheck = $tmpFileJSON.shortdescription -match '\;(.*)'
            }

            if($tmpNameCheck){
                $fuWikiDB[$x].fullName = $Matches[1]
            }
            else{
                $fuWikiDB[$x].fullName = $tmpFileJSON.shortdescription
            }
        }

        for ($y = 0; $y -lt $tmpFileJSON.learnBlueprintsOnPickup.Count; $y++){
            if ($fuWikiDB[$x].itemsLearned -notcontains $tmpFileJSON.learnBlueprintsOnPickup[$y]){
                $fuWikiDB[$x].itemsLearned += $tmpFileJSON.learnBlueprintsOnPickup[$y]
            }
        }

        for ($y = 0; $y -lt $tmpFileJSON.upgradeStages.interactData.Count; $y++){
            if ($fuWikiDB[$x].itemsLearned -notcontains $tmpFileJSON.upgradeStages.interactData.initialRecipeUnlocks[$y]){
                $fuWikiDB[$x].itemsLearned += $tmpFileJSON.upgradeStages.interactData.initialRecipeUnlocks[$y]
            }
        }
    }
    #endregion

    #region Item Doesn't exist
    else{
        Write-Host "Creating new entry: $tmpName"
        $fuWikiOBJ.itemName = $tmpName
        $fuWikiOBJ.rarity   = $tmpFileJSON.rarity
        $fuWikiOBJ.category = $tmpFileJSON.category
        $fuWikiOBJ.price    = $tmpFileJSON.price

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

        foreach($interactData in $tmpFileJSON.upgradeStages.interactData){
            if ($fuWikiOBJ.itemsLearned -notcontains $interactData.initialRecipeUnlocks){
                $fuWikiOBJ.itemsLearned += $interactData.initialRecipeUnlocks
            }  
        }

        #Script: part modifies the db/array variable outside of the function
        $script:fuWikiDB += $fuWikiOBJ
    }
    #endregion
}

foreach($file in $allFiles){
    
    #Clear any previous errors
    $error.clear()

    $fuWikiOBJ = New-Object -TypeName PSObject –Prop $fuWikiProps

    $filePath = $file.FullName
    $fileBaseName = $file.BaseName
    $fileExt = $file.Extension

    try {
        $fileJSON = Get-Content -Path $filePath -raw | ConvertFrom-Json
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

            ".recipe" {
            
            }

            ".patch" {
                if ($fileJSON.path -like '/learnBlueprintsOnPickup'){

                }
            }

            default {
                Write-Host "Unsupported File Extension"
            }
        }
    }  
}

$fuWikiOBJ = ""

for ($x = 0; $x -lt $fuWikiDB.Count; $x++){

    $currentItem = $fuWikiDB[$x].itemName

    for ($y = 0; $y -lt $fuWikiDB.Count; $y++){

     $itemIndex = $fuWikiDB[$y].itemsLearned.IndexOf($currentItem)

        if ($itemIndex -ge 0 -and $fuWikiDB[$x].learnFrom -notcontains $fuWikiDB[$y].fullName){
            
            $fuWikiDB[$x].learnFrom += $fuWikiDB[$y].fullName

        }
    }
    
}

$fuWikiDB 