using System;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Text.RegularExpressions;

[Serializable]
[Microsoft.SqlServer.Server.SqlUserDefinedType(Format.Native)]
public static class Functions
{
    [SqlFunction(IsDeterministic = true)]
    public static SqlBoolean IsMatch(SqlString str, SqlString pattern)
    {
        var reg = new Regex(pattern.ToString());
        return (SqlBoolean)reg.IsMatch(str.ToString());
    }
}