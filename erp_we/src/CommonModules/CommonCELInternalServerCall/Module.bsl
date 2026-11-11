
#Region Internal

Function SessionDate() Export
	Return CommonCEL.SessionDate();
EndFunction

#Region WorkingWithXML

// The function reads the XML root element.
//
// Parameters:
//  XMLLine - String - XML string.
//
// Returns:
//  Structure
//
Function ReadRootXMLElement(XMLLine) Export
	
	Return CommonCEL.ReadRootXMLElement(XMLLine);
	
EndFunction

// The function reads parameters from XML.
//
// Parameters:
//  XMLLine - String - XML string.
//
// Returns:
//  Structure
//
Function ReadParametersFromXML(XMLLine) Export
	
	Return CommonCEL.ReadParametersFromXML(XMLLine);
	
EndFunction    

#EndRegion

#Region JSON
// Formats the message text in JSON format
//
// Parameters:
//  JSONMessageText           - String - the text of the message that.
//  RemoveSpacesAndLineBreaks - Boolean - indicates the use of margins. False by default.
//  BASE64DeploymentKeys - Undefined -
//                            - Map of KeyAndValue:
//  * Key - String - Name of the property for the BASE64 reversal
//  * Value - Undefined - not used
// Returns:
//  String - formatted JSON string.
//
Function FormatJSON(JSONMessageText, RemoveSpacesAndLineBreaks = False, BASE64DeploymentKeys = Undefined) Export
	
	Return CommonCEL.FormatJSON(JSONMessageText, RemoveSpacesAndLineBreaks, BASE64DeploymentKeys);
	
EndFunction

#EndRegion

// Returns true if the authentication data of the Internet support user is filled in
//
// Returns:
//  Boolean
//
Function AuthenticationDataOfOnlineSupportUserFilled() Export
	
	// BEEP call
	If CommonCEL.SubsystemExists("OnlineUserSupport.CoreISL") Then
		ModuleOnlineUserSupport = CommonCEL.CommonModule("OnlineUserSupport");
		Return ModuleOnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled();
	EndIf;
	// End the BEEP Call
	
	Return False;
	
EndFunction

// Generates and outputs a message that can be associated with a form control.
//
// Parameters:
//   EventName - String
//   Comment - String, Undefined -
//   Var_Metadata - MetadataObject - 
//
Procedure WriteErrorToEventLog(EventName, Comment = Undefined, LevelPresentation = "Error", Var_Metadata = Undefined) Export
	
	CommonCEL.WriteErrorToEventLog(EventName, Comment, LevelPresentation, Var_Metadata);
	
EndProcedure

#EndRegion
