function Get-ScheduledTaskLike {
	param(		
		[Parameter(Mandatory)]
		[string[]]$ComputerName,
		
		[Parameter(Mandatory)]
		[string]$SearchBase,
		
		[Parameter(Mandatory)]
		[string]$NameQuery,
		
		[Parameter(Mandatory)]
		[string]$CsvDir,
		
		[int]$ThrottleLimit = 50,
		
		[switch]$PassThru
	)
	
	function Get-TaskData($comps) {
		$comps | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
			$comp = $_.ToUpper()
			
			$nameQuery = $using:NameQuery
			try {
				Invoke-Command -ComputerName $_ -ErrorAction "Stop" -ScriptBlock {
					
					function Get-TasksViaPowershell {
						try {
							$tasks = Get-ScheduledTask | Where { ($_.TaskPath + $_.TaskName) -like $using:nameQuery }
						}
						catch {
							$err = $_
							$errMsg = $err.Exception.Message + " " + $_.ScriptStackTrace
						}
						
						if($err) {
							$tasks = [PSCustomObject]@{
								"PSComputerName" = $comp
								"Error" = $errMsg
							}
						}
						else {
							$tasks = $tasks | ForEach-Object {
								$_ | Add-Member -NotePropertyName "DataSource" -NotePropertyValue "Get-ScheduledTask"
								$_ | Add-Member -NotePropertyName "FullTaskName" -NotePropertyValue ($_.TaskPath + $_.TaskName)
								$_ | Add-Member -NotePropertyName "Command" -NotePropertyValue ($_.Actions.Execute + " " + $_.Actions.Arguments)
								$_ | Add-Member -NotePropertyName "StartTime" -NotePropertyValue (Get-Date $_.Triggers.StartBoundary)
								$_
							}
						}
						
						$tasks
					}
					
					function Get-TasksViaSchtasks {
						try {
							#$tasks = schtasks /fo csv /v | ConvertFrom-Csv | Where { $_.TaskName -like $using:nameQuery }
							# Above doesn't work because when schtasks outputs CSV data, it encloses each field in double quotes, but doesn't escape any double quotes within the data in a field
							
							$tasks = ([xml](schtasks /query /xml ONE)).Tasks.Task | Where { $_.RegistrationInfo.URI -like $using:nameQuery }
						}
						catch {
							$err = $_
							$errMsg = $err.Exception.Message + " " + $_.ScriptStackTrace
						}
						
						if($err) {
							$tasks = [PSCustomObject]@{
								"PSComputerName" = $comp
								"Error" = $errMsg
							}
						}
						else {
							$tasks = $tasks | ForEach-Object {
								$_ | Add-Member -NotePropertyName "DataSource" -NotePropertyValue "schtasks"
								#$_ | Add-Member -NotePropertyName "FullTaskName" -NotePropertyValue $_.TaskName
								$_ | Add-Member -NotePropertyName "FullTaskName" -NotePropertyValue $_.RegistrationInfo.URI
								#$_ | Add-Member -NotePropertyName "Command" -NotePropertyValue $_."Task To Run"
								$_ | Add-Member -NotePropertyName "Command" -NotePropertyValue ($_.Actions.Exec.Command + " " + $_.Actions.Exec.Arguments)
								#$_ | Add-Member -NotePropertyName "StartTime" -NotePropertyValue (Get-Date ($_."Start Date" + " " + $_."Start Time"))
								$_ | Add-Member -NotePropertyName "StartTime" -NotePropertyValue (Get-Date ($_.Triggers.CalendarTrigger.StartBoundary))
								$_
							}
						}
						
						$tasks
					}
					
					$comp = ($env:ComputerName).ToUpper()
					
					$tasksPowershell = Get-TasksViaPowershell
					$tasksSchtasks = Get-TasksViaSchtasks
					
					@($tasksPowershell) + @($tasksSchtasks)
				}
			}
			catch {
				$err = $_
				$errMsg = $err.Exception.Message + " " + $_.ScriptStackTrace
				[PSCustomObject]@{
					"PSComputerName" = $comp
					"Error" = $errMsg
				}
			}
		}
	}

	function Get-Comps {
		$ComputerName | ForEach-Object {
			Get-ADComputer -SearchBase $SearchBase -Filter "name -like `"$_`"" | Select -ExpandProperty "Name"
		}
	}
	
	function Export-Tasks($tasks) {
		if($CsvDir) {
			$ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
			$Csv = "$($CsvDir)\Get-ScheduledTaskLike_$($ts).csv"
			$tasksFormatted = $tasks | Select "PSComputerName","Error","DataSource","FullTaskName","Command","StartTime" | Sort "PSComputerName","TaskName"
			$tasksFormatted | Export-Csv -Path $Csv -Encoding "Ascii" -NoTypeInformation
		}
	}

	function Do-Stuff {
		$comps = Get-Comps
		$tasks = Get-TaskData $comps
		Export-Tasks $tasks
		if($PassThru) {
			$tasks
		}
	}

	Do-Stuff
	
}