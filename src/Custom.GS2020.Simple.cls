Class Custom.GS2020.Simple [ Abstract ]
{

/// set status = ##class(Custom.GS2020.Simple).PatientSearch()
ClassMethod PatientSearch() As %Status
{
    set status = $$$OK
    try {
        // Get Credentials
        set status = ##class(Ens.Config.Credentials).GetCredentialsObj(.trakCare, "", "Ens.Config.Credentials", "TrakCare")
        if $$$ISERR(status) quit 

        // Create API objects
        set PAPersonList = ##class(WSClient.PAPerson.List.TCwsPAPersonListSoap).%New()
        set parameters = ##class(WSClient.PAPerson.List.Params).%New()

        // Apply credentials           
        set parameters.TUSERNAME = trakCare.Username
        set parameters.TPASSWORD = trakCare.Password

        // Apply search criteria
        set parameters.PAPERName = "K"

        // Execute search
        set dataSet = PAPersonList.ExecuteQuery(,parameters)
        
        // Display search results 
        write !, "Count", $char(9), "Row ID", $char(9), "Name"
        for i = 1:1:dataSet.Count() {
            #dim row as WSClient.PAPerson.List.DataSet

            set row = dataSet.GetAt(i)
            write !, $increment(counter), $char(9), row.ID, $char(9), row.Name _ ", " _ row.Name2
        }
    }
    catch (ex) {
        set status = ex.AsStatus()
    }

    quit status
}

/// set status = ##class(Custom.GS2020.Simple).PatientCreate()
ClassMethod PatientCreate() As %Status
{
    set sc = $$$OK
    try	{
        // Get Credentials
        set status = ##class(Ens.Config.Credentials).GetCredentialsObj(.trakCare, "", "Ens.Config.Credentials", "TrakCare")
        if $$$ISERR(status) quit 

        // API web service client
        set PAPersonEdit = ##class(WSClient.PAPerson.Edit.TCwsPAPersonEditSoap).%New()

        // New record
        set PAPerson = ##class(WSClient.PAPerson.Edit.TC.api.PAPerson.Edit).%New()
        if $$$ISERR(status) {
            do $system.Status.DisplayError(status)
            quit 
        }
        
        // Set details
        set PAPerson.PAPERName = ##class(%PopulateUtils).LastName()
        set PAPerson.PAPERName2 = ##class(%PopulateUtils).FirstName() 
        set PAPerson.PAPERDob = ##class(%PopulateUtils).Date() 
        set PAPerson.CTSEXDesc = $case($random(2)\1,1:"M",:"F")

        // Save record
        set RowID = PAPersonEdit.Save(, PAPerson, trakCare.Username, trakCare.Password)
        if RowID = "" {
            // Get fault information
            set status = $get(%objlasterror, $$$ERROR($$$GeneralError, "Error occurred saving API"))
        }
        if $$$ISERR(status) {
            do $system.Status.DisplayError(status)
            quit 
        }

        write !, "       ", $char(9), "Row ID", $char(9), "Name"
        write !, "Created", $char(9), RowID, $char(9), PAPerson.PAPERName _ ", " _ PAPerson.PAPERName2
    }
    catch (ex) {
        set status = ex.AsStatus()
    }

    quit status
}

/// set status = ##class(Custom.GS2020.Simple).PatientRetrieve()
ClassMethod PatientRetrieve(PAPersonID As %String = 212) As %Status
{
    set sc = $$$OK
    try	{
        // Get Credentials
        set status = ##class(Ens.Config.Credentials).GetCredentialsObj(.trakCare, "", "Ens.Config.Credentials", "TrakCare")
        if $$$ISERR(status) quit 

        // API web service cilent
        set PAPersonEdit = ##class(WSClient.PAPerson.Edit.TCwsPAPersonEditSoap).%New()

        // Open existing record
        set PAPerson = PAPersonEdit.Open(,PAPersonID, trakCare.Username, trakCare.Password)
        if $$$ISERR(status) {
            do $system.Status.DisplayError(status)
            quit 
        }
        
        // Display details
        write !, "         ", $char(9), "Row ID", $char(9), "Name"
        write !, "Retrieved", $char(9), PAPersonID, $char(9), PAPerson.PAPERName _ ", " _ PAPerson.PAPERName2
        write !, $char(9), "---"
        write !, $char(9), "Number  ", $char(9), PAPerson.RegistrationNumber 
        write !, $char(9), "Age     ", $char(9), PAPerson.AgeDynamic _ " " _ PAPerson.AgeUnits
        write !, $char(9), "Sex     ", $char(9), PAPerson.CTSEXDesc
        write !, $char(9), "Hospital", $char(9), PAPerson.HOSPDesc
    }
    catch (ex) {
        set status = ex.AsStatus()
    }

    quit status
}

/// set status = ##class(Custom.GS2020.Simple).PatientUpdate()
ClassMethod PatientUpdate(PAPersonID As %String = 212) As %Status
{
    set sc = $$$OK
    try	{
        // Get Credentials
        set status = ##class(Ens.Config.Credentials).GetCredentialsObj(.trakCare, "", "Ens.Config.Credentials", "TrakCare")
        if $$$ISERR(status) quit 

        // API web service client
        set PAPersonEdit = ##class(WSClient.PAPerson.Edit.TCwsPAPersonEditSoap).%New()

        // Open existing record
        set PAPerson = PAPersonEdit.Open(,PAPersonID, trakCare.Username, trakCare.Password)
        if $$$ISERR(status) {
            do $system.Status.DisplayError(status)
            quit 
        }
        
        // Change details
        set originalPAPERTelH = PAPerson.PAPERTelH
        set PAPerson.PAPERTelH = ##class(%PopulateUtils).USPhone()
        set originalCTSECDesc = PAPerson.CTSEXDesc 
        set PAPerson.CTSEXDesc = $case(originalCTSECDesc,"Unknown":"Male",:"Unknown") 

        set RowID = PAPersonEdit.Save(, PAPerson, trakCare.Username, trakCare.Password)
        if RowID = "" {
            // Get fault information
            set status = $get(%objlasterror, $$$ERROR($$$GeneralError, "Error occurred saving API"))
        }
        if $$$ISERR(status) {
            do $system.Status.DisplayError(status)
            quit 
        }
        write !, "       ", $char(9), "Property", $justify("Old",15), " -> New"
        write !, "Updated", $char(9), "Phone   ", $justify(originalPAPERTelH,15), " -> " _ PAPerson.PAPERTelH
        write !, "Updated", $char(9), "Sex     ", $justify(originalCTSECDesc,15), " -> " _ PAPerson.CTSEXDesc
    }
    catch (ex) {
        set status = ex.AsStatus()
    }

    quit status
}

}
