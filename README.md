# PSMySQL

<p>Edit the first few lines for a default MySQL Server</p>
<p>This is a very simple MySQL Module to easily run sql queries against a mysql database.</p>

```powershell
$Db = Get-MySQLConnection -Host domain.com -User root -Password "" -Database MyDB

# If you have the Defaults Set Then
$Db = Get-MySQLConnection MyDB

$Id = 10
$Query = "SELECT * FROM users WHERE id = @id"
$Params = @{ id = $Id }

Invoke-MySQLCommand -Connection $Db -Query $Query -Params $Params

## Returns PSObject(s):
# id: 10
# firstname: Foo
# lastname: Bar
```
