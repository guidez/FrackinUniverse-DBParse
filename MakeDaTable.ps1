#Don't Use me xD

$ErrorActionPreference = "SilentlyContinue"

$fuPath = "F:\Steam\steamapps\common\Starbound\mods\FrackinUniverse"

$allFiles2 = Get-ChildItem -Path $fuPath\* -recurse -Exclude *.ps1, *.csv, *.png, *.ogg, *.wav, *.dungeon, *.biome | 
                                Where-Object { $_.Attributes -ne "Directory"}

#Generate a name value, since it looks poopy otherwise
function GenName($tmpFileContents){

    $tmpName = $tmpFileContents.shortdescription -match '\;(.*)\^'
    
    if($tmpName -eq $false){
        $tmpName = $tmpFileContents.shortdescription -match '\;(.*)'
    }

    if($tmpName){
        $Matches[1]
    }
    else{
            $tmpFileContents.shortdescription
    }

}

#Generate a itemName value, since it can be a different property name
function GenItemName($tmpFileContents){

    if($tmpFileContents.itemName -notlike ''){
        $tmpFileContents.itemName
    }
    elseif ($tmpFileContents.objectName -notlike ''){
        $tmpFileContents.objectName
    }
    else{
        $outMe = "NameError!"
        $outMe
    }

}

#valType should be either "value", "learnBlueprintsOnPickup", or "upgradeStages.interactData.initialRecipeUnlocks".... <--Nasty
function ArrayOutString($tmpFileContents, $valType){

    $firstBP = $true;
    foreach($bp in $tmpFileContents.$($valType)){
        if ($firstBP){
            $firstBP = $false;
            $stringBP = $bp
        }
        else{
            $stringBP = $stringBP + ",$bp"
        }
    }

    $stringBP

}

function GenDescription($tmpFileContents){

    $outString = ""
    $tmpDescrip = $tmpFileContents.description.replace("`n"," ")
    
    write-host $tmpDescrip

    #$tmpMatch = $tmpDescrip -match '\;(.*)\^'
    #$Matches[3]
    if($tmpMatch){
        for ($x = 1; $x -le $Matches.Count; $x++){
        
            $tmpString = $Matches[$x]
            $outString = $outString + " $tmpString"
        }
        
        #$outString

    }
    else{
            #$tmpFileContents.description
    }

}

$count = 1;
$allCount = $allFiles.Count

$parsedData = foreach($file in $allFiles2){

    
    $filePath = $file.FullName
    $fileExt = $file.Extension
    Write-Host $filePath
    #Write-Host "Parsing file $count of $allCount"
    
        $fileContents = Get-Content -Path $filePath | ConvertFrom-Json
        
        if ($fileExt -like '.patch' -and $fileContents.path -like '/learnBlueprintsOnPickup'){

            $tmpName = $file.BaseName.Substring(0, $file.BaseName.IndexOf('.'))
            $fileContents[0] | Select @{Name="Name";Expression={$tmpName}},
                                    @{Name="ItemName";Expression={$tmpName}},
                                     @{Name="LearnedOnPickup";Expression={ArrayOutString $_ "value"}},
                                      @{Name="Description";Expression={$_.description}}
        }
        elseif ($fileContents.learnBlueprintsOnPickup.Count -gt 0 -and $fileContents.learnBlueprintsOnPickup[0] -notlike ''){
            $fileContents | #Select #@{Name="Name";Expression={GenName $_}},
                                    #@{Name="ItemName";Expression={GenItemName $_}},
                                     #@{Name="LearnedOnPickup";Expression={ArrayOutString $_ "learnBlueprintsOnPickup"}},
                                     select  @{Name="Description";Expression={GenDescription $_}}

        }
        elseif ($fileContents.upgradeStages.interactData.initialRecipeUnlocks.Count -gt 0){
        
            $interactData = $fileContents.upgradeStages.interactData;

            $fileContents | Select @{Name="Name";Expression={GenName $_}},
                                    @{Name="ItemName";Expression={GenItemName $_}},
                                     @{Name="LearnedOnPickup";Expression={ArrayOutString $interactData "initialRecipeUnlocks"}},
                                      @{Name="Description";Expression={$_.description}}
        }


    $fileContents = ''
    $tmpName = ''
    $interactData = ''

    $count++

    if($count -gt 3000){
        break
    }
} 

$parsedData 