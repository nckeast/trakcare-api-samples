Include %occErrors

/// Updated at 08/26/2020 06:29:27
Class Custom.GS2020.Lab [ Abstract, ProcedureBlock ]
{

/// Sample output:
///    >d ##class(Custom.GS2020.Lab).Registration()
///    Enter Patient: katie
///    Options:
///     1. Davitt, Katie
///     2. Lawrence, Katie
///    
///    Please select an option: 2
///    Options:
///     1. 20/052842668146, CF
///     2. 20/052842668147, CF
///     3. 20/052851571484, CF
///     4. 20/052851571485, CF
///    
///    Please select an option: 4
///                     MRN DBG00000199
///                  Number 20/052851571485
///                CareProv Adam Demo
///         PatientLocation Anaesthetics
///          CollectionDate 28/05/2020
///            ReceivedDate
///    >
ClassMethod Registration()
{
    set status = $$$OK 

    try {
        write #
        set PAPersonID = ..GetPatient()
        if PAPersonID = "" quit 
        set LBEpisodeID = ..GetEpisode(PAPersonID)
        if LBEpisodeID = "" quit 
        do ..DisplayEpisode(LBEpisodeID)
    }
    catch (ex) {
        if ex.Name '= $$$Interrupt {
            set status = ex.AsStatus()
        }  
    }
    if $$$ISERR(status) do $system.Status.DisplayError(status)
    quit
}

ClassMethod GetPatient()
{
    // Find Patient
    read !, "Enter Patient: ", patient

    for field = "MedicalRecordNo", "PAPERName" {
        set params = {}
        set $property(params, field) = patient
        set status = ..GetQueryAPI("PAPerson.List", params, .PAPersonList)
        if $$$ISERR(status) {
            do $system.Status.DisplayError(status)
            quit status
        }
        kill list
        while PAPersonList.Next() {
            set list($increment(list)) = $listbuild(PAPersonList.Data("Name") _ ", " _ PAPersonList.Data("Name2"), PAPersonList.Data("ID"))
        }
        if $data(list) {
            set option = $listget(..GetSelection(.list), 2)
            set PAPersonID = option
        }
    }
    if '$data(PAPersonID) {
        write !, "No patient found"
        quit ""
    }
    quit PAPersonID
}

ClassMethod GetEpisode(PAPersonID)
{
    // Find Episode
    set status = ..GetQueryAPI("LBEpisode.List", { "PatientID": (PAPersonID) } , .LBEpisodeList)
    if $$$ISERR(status) {
        do $system.Status.DisplayError(status)
        quit ""
    }
    kill list
    set list($increment(list)) = $listbuild("New lab episode", "")
    while LBEpisodeList.Next() {
        set list($increment(list)) = $listbuild(LBEpisodeList.Data("LBEpisodeNo") _ ", " _ LBEpisodeList.Data("Status"), LBEpisodeList.Data("LBEpisodeID"))
    }

    if $data(list) {
        set option = $listget(..GetSelection(.list), 2)
        set LBEpisodeID = option
        if (LBEpisodeID = "") {
            set LBEpisodeID = ..CreateEpisode(PAPersonID)
        }
    }
    if '$data(LBEpisodeID) {
        write !, "No lab episode found"
        quit ""
    }
    quit LBEpisodeID
}

ClassMethod CreateEpisode(PAPersonID As %String) As %String
{
	set LBEpisodeID = ""
	set status = ..GetEditAPI("LBEpisode.Edit", LBEpisodeID, .LBEpisode)
	if $$$ISERR(status) {
		do $system.Status.DisplayError(status)
		quit ""
	}

    set status = ..GetEditAPI("PAPerson.Edit", PAPersonID, .PAPerson)

    #define CTCareProvCode "ADEMO"
    #define CTLocCode "H1E1ED"
    #define CTLocCodeLab "H1MLB"
    #define LBCTestSetCode "ESR"

	read !, "Care Provider :    ", careProvider
    if (careProvider = "") {
        set careProvider = $$$CTCareProvCode
        write careProvider _ " (Defaulted)" 
    }
	read !, "Location      :    ", location
    if (location = "") {
        set location = $$$CTLocCode
        write location _ " (Defaulted)" 
    }
	read !, "Collected     :    ", collected
    if (collected = "") {
        set collected = $zdt($horolog, 4, 2)
        write collected _ " (Defaulted)" 
    }
	read !, "Received      :    ", received
    if (received = "") {
        set received = $zdt($horolog, 4, 2)
        write received _ " (Defaulted)" 
    }
	
    // Use patient demographics for request
    set LBEpisode.PatientID = PAPersonID
	set LBEpisode.LBEPFirstName = PAPerson.PAPERName2 
    set LBEpisode.LBEPSurname = PAPerson.PAPERName
	set LBEpisode.LBEPDOB = PAPerson.PAPERDob
	set LBEpisode.LBEPCareProvDR = careProvider
	set LBEpisode.LBEPPatientLocationDR = location
	set LBEpisode.LBEPCollectionDate = $p(collected, " ")
	set LBEpisode.LBEPCollectionTime = $p(collected, " ", 2)
	set LBEpisode.LBEPReceivedDate = $p(received, " ")
	set LBEpisode.LBEPReceivedTime = $p(received, " ", 2)
	set LBEpisode.LBEPLabSiteDR = $$$CTLocCodeLab

	for {
        read !, "Test Set      :    ", testSet
        if testSet = "" quit 

		set status = ..GetQueryAPI("LBCTestSetRevision.FindList", { "Code": (testSet) } , .LBCTestSetRevisionFindList)
		if $$$ISERR(status) {
			do $system.Status.DisplayError(status)
			return ""
		}
		if LBCTestSetRevisionFindList.Next() {
            set LBCTestSetRevisionID = LBCTestSetRevisionFindList.Data("LBCTSRRowId")
		}

		set status = ..GetEditAPI("LBTestSet.Msg.Edit", "", .LBTestSetMsg)
		if $$$ISERR(status) {
			do $system.Status.DisplayError(status)
			return ""
		}

		set LBTestSetMsg.LBCTestSetRevisionID = LBCTestSetRevisionID
		set LBTestSetMsg.LBTSTestSetDR = testSet
		
		set status = LBTestSetMsg.Save()
		if $$$ISERR(status) {
			do $system.Status.DisplayError(status)
			return ""
		}
	}
	set status = LBEpisode.Save()
	if $$$ISERR(status) {
		do $system.Status.DisplayError(status)
		quit ""
	}

	// Return Lab Episode ID
	set LBEpisodeID = LBEpisode.ID
	quit LBEpisodeID
}

ClassMethod DisplayEpisode(LBEpisodeID)
{
    // Get Episode Details
    set status = ..GetEditAPI("LBEpisode.Edit", LBEpisodeID, .LBEpisodeEdit)
    if $$$ISERR(status) {
        do $system.Status.DisplayError(status)
        quit status
    }

    for property = "LBEPSurname", "LBEPFirstName", "LBEPNumber", "LBEPCareProvDR", "LBEPPatientLocationDR", "LBEPCollectionDate", "LBEPReceivedDate" {
        set caption = property
        set caption = $replace(caption, "LBEP", "")
        set caption = $replace(caption, "DR", "")
        write !, $justify(caption, 20) _ " " _ $property(LBEpisodeEdit, property)
    }

    quit $$$OK
}

/// Options format
/// subscript = key (numeric or alpha)
/// data = list
///     1 = Display Value
/// Return value = data for selected row
ClassMethod GetSelection(ByRef Options As %String) As %String
{
    #define PAGESIZE 20

    set pageStartKey = "", pageNextKey = "", pagePrevKey = ""
    for {
        write #, "Options:"
        set key = pageStartKey, pageNextKey = ""
        set count = 0
        for {
            set key = $order(Options(key), 1, optionData)
            if key = "" quit 

            write !, $justify(key,2) _ ". " _ $listget(optionData) 
            if $increment(count) > $$$PAGESIZE {
                set pageNextKey = key
                quit
            }
        }
        write !, $select(pageNextKey'="":"...", 1:"")
        
        for {
            write !, "Please select an option: "
            read input

            // Q = Quit
            if ($zconvert(input,"U") = "Q") $$$ThrowStatus($$$ERROR($$$Interrupt))

            if (input = ">") {
                set pagePrevKey = pageStartKey
                set pageStartKey = pageNextKey
                quit
            } 
            if (input = "<") {
                set pageNextKey = pageStartKey
                set pageStartKey = pagePrevKey
                for i=0:1:$$$PAGESIZE {
                    set pagePrevKey = $order(Options(pagePrevKey), -1)
                }
                quit
            }	
            if (input = "") || '$data(Options(input)) {
                write !,"You have entered an invalid selection, please try again"
                continue
            }
            quit
        }
        if $data(Options(input)) quit
    }
    quit Options(input)
}

/// Helper method to set authentication details
ClassMethod InitialiseAPI(APIObject) As %Status
{
    set status = ##class(Ens.Config.Credentials).GetCredentialsObj(.trakCare, "", "Ens.Config.Credentials", "TrakCare")
    if $$$ISERR(status) quit status
	
    set APIObject.TUSERNAME = trakCare.Username
    set APIObject.TPASSWORD = trakCare.Password
	
    quit $$$OK
}

/// Helper method to return API Query object
/// E.g. set status = ..GetQueryAPI("PAPerson.List", { "PAPERName": "Keast" }, .PAPersonList)
ClassMethod GetQueryAPI(ComponentName As %String, Parameters As %DynamicObject, Output QueryAPI As %RegisteredObject) As %Status
{
    set QueryAPI = $classmethod("TC.api."_ComponentName, "%New")
    do ..InitialiseAPI(QueryAPI)

    set parameters = $classmethod("TC.api."_ComponentName_".Params", "%New")
    do ..InitialiseAPI(parameters)

    set iterator = Parameters.%GetIterator()
    while iterator.%GetNext(.key, .value) {
        set $property(parameters, key) = value
    }
    set status = QueryAPI.Execute(,parameters)
    quit status
}

/// Helper method to return record matching search parameters
/// E.g. set status = ..GetRecordAPI("PAPerson.List", { "MedicalRecordNo": "DBG00000197" }, .data)
ClassMethod GetRecordAPI(ComponentName As %String, Parameters As %DynamicObject, Output Data As %RegisteredObject) As %Status
{
    kill Data
    set status = ..GetQueryAPI(ComponentName, Parameters , .QueryAPI)
    if $$$ISERR(status) {
        do $system.Status.DisplayError(status)
        quit status
    }
    if QueryAPI.Next() {
        merge Data = QueryAPI.Data
    }

    quit status
}

/// Helper method to return API Edit object
/// E.g. set status = ..GetEditAPI("PAPerson.Edit", PAPersonID, .PAPersonEdit)
ClassMethod GetEditAPI(ComponentName As %String, ID As %String, Output EditAPI As %RegisteredObject) As %Status
{
    set status = $$$OK

    set EditAPI = $classmethod("TC.api."_ComponentName, "%New")
    do ..InitialiseAPI(EditAPI)

    if (ID '= "") {
        set status = EditAPI.Open(,ID)
    }

    quit status
}

}
