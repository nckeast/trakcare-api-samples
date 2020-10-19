/// set status = ##class(Custom.GS2020.Workload).Run()
Class Custom.GS2020.Workload [ Abstract ]
{

/// Get list of patient admitted today and whether they are discharged or not.
/// set status = ##class(Custom.GS2020.Workload).Run()
ClassMethod Run() As %Status
{
    set sc = $$$OK
    try	{
        // Get Credentials
        set status = ##class(Ens.Config.Credentials).GetCredentialsObj(.trakCare, "", "Ens.Config.Credentials", "TrakCare")
        if $$$ISERR(status) quit 
        
        // Create API objects
        set PAAdmListByLocType = ##class(WSClient.PAAdm.ListByLocType.TCwsPAAdmListByLocTypeSoap).%New()
        set parameters = ##class(WSClient.PAAdm.ListByLocType.Params).%New()

        // Apply credentials           
        set parameters.TUSERNAME = trakCare.Username
        set parameters.TPASSWORD = trakCare.Password

        // Apply search criteria
        set parameters.DateFrom = $horolog 

        // Execute search
        set dataSet = PAAdmListByLocType.ExecuteQuery(,parameters)
        
        write !, "Count", $char(9), "Name", $char(9,9), "Location"
        for i = 1:1:dataSet.Count() {
            set row = dataSet.GetAt(i)
            write !, $increment(counter), $char(9), row.Name _ ", " _ row.Name2, $char(9), row.Loc
        }
    }
    catch (ex) {
        set status = ex.AsStatus()
    }

    quit status
}

}
