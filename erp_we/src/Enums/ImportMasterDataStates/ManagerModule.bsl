#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Properties OF THE DOWNLOAD State.
// 
// Parameters:
//  State - EnumRef.ImportMasterDataStates
// 
// Returns:
//  Structure - Loading State Properties:
// * State - EnumRef.ImportMasterDataStates
// * Color - String - the name of the color from the style
Function LoadingStateProperties(State) Export
	
	Result = New Structure("State,Color", State, "UnavailableTextColor");
	
	If State = DoNotPerformed Then
		Result.Color      = "UnavailableTextColor";
	ElsIf State = NoData1 Then
		Result.Color      = "UnavailableTextColor";
	ElsIf State = NotExecuted Then
		Result.Color      = "TextColorUncompletedImport";
	ElsIf State = WasCompletedWithErrors Then
		Result.Color      = "TextColorImportUnsuccessful";
	ElsIf State = SuccessfullyCompleted Then
		Result.Color      = "TextColorSuccessfulImport";
	ElsIf State = DeletePartiallyCompleted Then
		Result.Color      = "TextColorImportUnsuccessful";
	Else
		Result.State = DoNotPerformed;
	EndIf;
	
	Return Result;
	
EndFunction

// List of States indicating the presence of problems
// 
// Returns:
//  ValueList of EnumRef.ImportMasterDataStates -  Problematic States
Function ProblematicStates() Export
	
	Result = New ValueList();
	
	Result.Add(Enums.ImportMasterDataStates.NotExecuted);
	Result.Add(Enums.ImportMasterDataStates.WasCompletedWithErrors);
	Result.Add(Enums.ImportMasterDataStates.DeletePartiallyCompleted);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf