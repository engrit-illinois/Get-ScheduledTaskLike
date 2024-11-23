# Summary
Gathers all scheduled tasks matching the given name query, from all AD computers matching the given name queries, and exports relevant data about them to a CSV.  

The data is more or less duplicated because it is gathered in two ways: via `Get-ScheduledTasks` and via `schtasks`. This is because some computers can be in a broken state where `Get-ScheduledTasks` doesn't work.  

# Requirements
- Powershell 7+ due to use of `ForEach-Object -Parallel`.  

# Usage
1. Download `Get-ScheduledTaskLike.psm1` to the appropriate subdirectory of your PowerShell [modules directory](https://github.com/engrit-illinois/how-to-install-a-custom-powershell-module).
2. Run it using the examples and parameter documentation below.

# Examples

### WIP
WIP

# Parameters

### -ComputerName [string[]]
Required string array.  
The list of computer names and/or computer name query strings to poll.  
Use an asterisk (`*`) as a wildcard.  

### -SearchBase [string]
Required string.  
The distinguished name of the OU to limit the computername search to.  

### -NameQuery [string]
Required string.  
A wildcard query against which to match task names. Only tasks with names which match the query will be returned.  
The full task name including its path (within the folder structure of Task Scheduler) will be queried against.  
Use an asterisk (`*`) as a wildcard.  

### -CsvDir \<string\>
Required string.  
The directory where the output CSV file will be created.  
If omitted, no CSV will be created.  
The file will be named like `Get-ScheduledTaskLike_<timestamp>.csv`.  

### -ThrottleLimit [int]
Optional integer.  
The maximum number of computers which will be asynchronously polled simultaneously.  
Default is `50`.   

### -PassThru
Optional switch.  
If specified, all of the task data gathered is returned in a PowerShell object.  
If not specified, nothing is returned to the output stream.  

# Notes
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.
