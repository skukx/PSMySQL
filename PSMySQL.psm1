[void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")

$USER = 'root'
$HOST = 'localhost'
$PASS = '#######'

# Alternative is store hashed password in config file
#$CONFIG = "$PSScriptRoot\mysql.config"


<#
    .SYNOPSIS
        Obtains a connection to MySQL database

    .DESCRIPTION
        Obtains a closed connection to MySQL database whether
        it is remote or local

    .EXAMPLE
        $db = Get-MySQLConnection my_local_database
        Obtain a connection to database on webtools named my_local_database

    .EXAMPLE
        $db = Get-MySQLConnection -Host mydomain.com -User myuser -Password mypassword -Database application_db
        Obtain a connection to a remote database

    .PARAMETER Host
        The host name of where the mysql server is running

    .PARAMETER User
        The MySQL user to authenticate with

    .PARAMETER Password
        The user's password to authenticate with

    .PARAMETER Database
        The name of the database to run queries on.
#>
function Get-MySQLConnection {
    [CmdletBinding(DefaultParameterSetName = "Local")]
    param (
        [Parameter(Mandatory=$True,
            ParameterSetName="Remote")]
        [String]
        $Host,

        [Parameter(Mandatory=$True,
            ParameterSetName="Remote")]
        [String]
        $User,

        [Parameter(Mandatory=$True,
            ParameterSetName="Remote")]
        [String]
        $Password,

        [Parameter(Mandatory=$True,
            Position = 0,
            ParameterSetName="Local")]
        [Parameter(Mandatory=$True,
            ParameterSetName="Remote")]
        [String]
        $Database
    )
    
    Write-Verbose "Using ParameterSet: $($PSCmdlet.ParameterSetName)"

    if ( $PSCmdlet.ParameterSetName -eq "Local" ) {
        # Unhash Password
        # Get Auth from config file
        #$json = Get-Content $Script:CONFIG | Out-String | ConvertFrom-Json
        #$SecureString = $json.auth | ConvertTo-SecureString
        #$UnicodePtr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($SecureString)
        #$Pass = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($UnicodePtr)

        $Host = $Script:HOST
        $User = $Script:USER
        $Password = $Script:PASS
    }

    # Get Connection String to Connect
    # With
    $ConnectionString = Get-ConnectionString -Host $Host -User $User -Password $Password -Databse $Database
    
    try {
        [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
        $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
        $Connection.ConnectionString = $ConnectionString
        $Connection
    } catch {
        Write-Error $_
    }
}

<#
    .SYNOPSIS
        Invokes a mysql command

    .DESCRIPTION
        Runs a mysql command on specified database

    .EXAMPLE
        $users = Invoke-MySQLCommand -Connection $db -Query "SELECT * FROM user"
        Grabs all rows and columns from user table

    .EXAMPLE
        $user = Invoke-MySQLCommand -Connection $db -Query "SELECT * From user WHERE id = @id" -Params @{"@id" = $id}
        Grabs user with parameters that ensure a sanitized query.

    .PARAMETER Connection
        The connection obtained from Get-MySQLConnection

    .PARAMETER Query
        The MySQL command to run

    .PARAMETER Params
        Any parameters to pass through
#>
function Invoke-MySQLCommand {
    param (
        [Parameter(Mandatory=$True)]
        [MySql.Data.MySqlClient.MySqlConnection]
        $Connection,

        [Parameter(Mandatory=$True)]
        [String]
        $Query,

        [HashTable]
        $Params = @{}
    )

    $Command = New-Object Mysql.Data.MySqlClient.MySqlCommand($Query, $Connection)
    $Command.CommandTimeout = 90
    
    ForEach ($param in $Params.Keys) {
        $key = $param
        $value = $Params[$param]

        $Command.Parameters.AddWithValue($key, $value) | Out-Null
    }

    $DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
    $DataSet = New-Object System.Data.DataSet

    $Count = $DataAdapter.Fill($DataSet, "data")
    $DataSet.Tables[0] | Select $DataSet.Tables[0].Columns.ColumnName
}

function Close-MySQLConnection {
    param (
        [Parameter(Mandatory=$True)]
        [MySql.Data.MySqlClient.MySqlConnection]
        $Connection
    )

    $Connection.Close()
    $Connection.Dispose()
}

function Get-ConnectionString {
    param (
        [Parameter(Mandatory=$True)]
        [String]
        $Host,
        
        [Parameter(Mandatory=$True)]
        [String]
        $User,

        [Parameter(Mandatory=$True)]
        [String]
        $Password,

        [Parameter(Mandatory=$True)]
        [String]
        $Databse
    )

    "server=$Host;port=3306;uid=$User;pwd=$Password;database=$Database"
}

Export-ModuleMember -Function Get-MySQLConnection, Invoke-MySQLCommand, Close-MySQLConnection