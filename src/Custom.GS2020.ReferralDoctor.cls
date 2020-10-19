/// set status = ##class(Custom.GS2020.ReferralDoctor).Run()
Class Custom.GS2020.ReferralDoctor [ Abstract ]
{

/// Source of data external to TrakCare
ClassMethod GetReferralDoctors() As %DynamicObject
{
    quit [
        {
            "FirstName":    "Jennifer",
            "LastName":     "Glen",
            "Number":       "API-5789"
        },
        {
            "FirstName":    "Bill",
            "LastName":     "Peters",
            "Number":       "API-5524"
        },
        {
            "FirstName":    "Ursula",
            "LastName":     "Bowden",
            "Number":       "API-5027"
        },
        {
            "FirstName":    "Geoff",
            "LastName":     "Alexander",
            "Number":       "API-5450"
        }
    ]
}

/// Add list of referring doctors
/// set status = ##class(Custom.GS2020.ReferralDoctor).Run()
ClassMethod Run() As %Status
{
    set sc = $$$OK
    try {
        // Get Credentials
        set status = ##class(Ens.Config.Credentials).GetCredentialsObj(.trakCare, "", "Ens.Config.Credentials", "TrakCare")
        if $$$ISERR(status) quit 

        set list = ..GetReferralDoctors()
        set listCount = list.%Size()
		for i = 0:1:(listCount - 1) {
			set referralDoctor = list.%Get(i)

        // Find existing record with matching number.
        // Create API objects
        set PACRefDoctorCTFindList = ##class(WSClient.PACRefDoctorCT.FindList.TCwsPACRefDoctorCTFindListSoap).%New()
        set parameters = ##class(WSClient.PACRefDoctorCT.FindList.Params).%New()
        set PACRefDoctorCTEdit = ##class(WSClient.PACRefDoctorCT.Edit.TCwsPACRefDoctorCTEditSoap).%New()

        // Apply credentials           
        set parameters.TUSERNAME = trakCare.Username
        set parameters.TPASSWORD = trakCare.Password

        // Apply search criteria
        set parameters.Code = referralDoctor.Number

        // Execute search
        set dataSet = PACRefDoctorCTFindList.ExecuteQuery(,parameters)
        
        if dataSet.Count() {
            // Update existing record
            set PACRefDoctorCTID = dataSet.GetAt(1).REFDRowId
            
            // Open existing record
            set PACRefDoctorCT = PACRefDoctorCTEdit.Open(,PACRefDoctorCTID, trakCare.Username, trakCare.Password)
        }
        else {
            // Create new record
            set PACRefDoctorCT = ##class(WSClient.PACRefDoctorCT.Edit.TC.api.PACRefDoctorCT.Edit).%New()
        }
                
        set PACRefDoctorCT.REFDDesc = referralDoctor.LastName
        set PACRefDoctorCT.REFDForename = referralDoctor.FirstName
        set PACRefDoctorCT.REFDCode = referralDoctor.Number
        if PACRefDoctorCT.ID = "" {
            // Details specific to new records
            set PACRefDoctorCT.REFDDateActiveFrom = $zdate($horolog, 4)
        }
        set RowID = PACRefDoctorCTEdit.Save(, PACRefDoctorCT, trakCare.Username, trakCare.Password)
        if RowID = "" {
            // Get fault information
            set status = $get(%objlasterror, $$$ERROR($$$GeneralError, "Error occurred during save"))
            do $system.Status.DisplayError(status)
            quit 
        }
        write !, "Updated [ REFDRowId: " _ RowID _ " - " _ referralDoctor.LastName _ ", " _ referralDoctor.FirstName _ " ]"
        }
    }
    catch (ex) {
        set status = ex.AsStatus()
    }

    quit status
}

}
