Class Custom.GS2020.Location [ Abstract ]
{

/// Get list of locations
/// set status = ##class(Custom.GS2020.Location).Run()
ClassMethod Run() As %Status
{
    set sc = $$$OK
    try {
        // Get Credentials
        set status = ##class(Ens.Config.Credentials).GetCredentialsObj(.trakCare, "", "Ens.Config.Credentials", "TrakCare")
        if $$$ISERR(status) quit 

        // Create API objects
        set CTLocFindList = ##class(WSClient.CTLoc.FindList.TCwsCTLocFindListSoap).%New()
        set parameters = ##class(WSClient.CTLoc.FindList.Params).%New()

        // Apply credentials           
        set parameters.TUSERNAME = trakCare.Username
        set parameters.TPASSWORD = trakCare.Password

        // Execute search
        set dataSet = CTLocFindList.ExecuteQuery(,parameters)

        write !, "Count", $char(9), "Code", $char(9), "Description"
        for i = 1:1:dataSet.Count() {
            set row = dataSet.GetAt(i)
            write !, $increment(counter), $char(9), row.CTLOCCode, $char(9), row.CTLOCDesc
        }
    }
    catch (ex) {
        set status = ex.AsStatus()
    }

    quit status
}

}
