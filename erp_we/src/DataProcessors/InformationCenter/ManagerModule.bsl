#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Sets the sign of the truth of the properties of the Hyperlink scenery forms.
// 
// Parameters:
// 	Label - Label - form decoration.
Procedure SetHyperlinkAttribute(Label) Export
	
	Label.Hyperlink = True;
	
EndProcedure

// Adds information about the current app to the message text from the user.
//
// Parameters:
//  HTMLText - String - text of the user's message.
//  HTMLAttachments - Structure - images embedded in the user's message
//  AdditionalData - Structure, Undefined - arbitrary data that can be sent to circulation 
//                                                   in the form of a structure converted to JSON
//
Procedure AddAppInformation(HTMLText, HTMLAttachments, AdditionalData = Undefined) Export
	
	AdditionalDataAsString = """""";
	If AdditionalData <> Undefined Then
		AdditionalDataAsString = SaaSOperationsCTL.StringFromJSONStructure(AdditionalData)
	EndIf;
    
    SystemInfo = New SystemInfo();
    
    ParametersString1 = 
    	"<!-- @AddInfo 
        |{
        |   ""base_id"": ""%1"",
        |   ""platformVersion"": ""%2"",
        |   ""configVersion"": ""%3"",
        |   ""configName"": ""%4"",
		|	""descriptionImages"": %5,
		|	""additionalData"": %6
        |} 
        |-->"; // @Non-NLS
        
    HTMLText = HTMLText + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString( 
        ParametersString1, 
		Constants.InfoBaseID.Get(), 
        SystemInfo.AppVersion,
        Metadata.Version,
        Metadata.Name,
		SaaSOperationsCTL.StringFromJSONStructure(HTMLAttachments),
		AdditionalDataAsString
	);
	
EndProcedure

Procedure AddValueToXDTOList(Object, ListBox, Val Value) Export

	List = Object[ListBox]; // XDTOList
	List.Add(Value);
	
EndProcedure

#EndRegion

#EndIf