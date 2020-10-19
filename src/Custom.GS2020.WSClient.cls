/// set status = ##class(Custom.GS2020.WSClient).Generate()
Class Custom.GS2020.WSClient [ Abstract ]
{

Parameter TCHOST = "localhost";

Parameter TCPORT = 52773;

Parameter TCWEBAPP = "/trakcare/dev";

/// Generate SOAP client classes
ClassMethod Generate() As %Status
{
    set status = $$$OK

    try {
        set reader = ##class(%SOAP.WSDL.Reader).%New()
		
        set remoteClassnames = $lb(
            "TC.ws.CTCareProv.FindList",
            "TC.ws.CTLoc.FindList",
            "TC.ws.LBCTestSetRevision.FindList",
            "TC.ws.LBEpisode.Edit",
            "TC.ws.LBEpisode.List",
            "TC.ws.LBTestSet.Msg.Edit",
            "TC.ws.Logon",
            "TC.ws.PAAdm.ListByLocType",
            "TC.ws.PACRefDoctorCT.FindList",
            "TC.ws.PACRefDoctorCT.Edit",
            "TC.ws.PAPerson.Edit",
            "TC.ws.PAPerson.List"            
        )

        set remoteClassnamePtr = 0
        while $listnext(remoteClassnames, remoteClassnamePtr, remoteClassname) {
            set url = "http://" _ ..#TCHOST _ ":" _ ..#TCPORT _ ..#TCWEBAPP _ "/" _ remoteClassname _ ".cls?WSDL=1" 
            set package = "WSClient."_$piece(remoteClassname,".",3,*)

            set clientClassname = package_"."_$zstrip(remoteClassname, "*P")_"Soap"

            set reader.Debug = 1
            set reader.MakeNamespace = 1
            set status = reader.Process(url,package)
            if $$$ISERR(status) {
                set status = $$$EMBEDSC($$$ERROR($$$GeneralError, "Failed to process WSDL '" _ url _ "'"), status)
                quit 
            }
            
            // Check for generated class
            if '##class(%Dictionary.CompiledClass).%ExistsId(clientClassname) {
                set status = $$$ERROR($$$GeneralError, "Failed to generate web service client class '" _ clientClassname _ "'")
            }

            do reader.Reset()
        }
    }
    catch (ex)	{
        set status = ex.AsStatus()
    }

    quit status
}

}
