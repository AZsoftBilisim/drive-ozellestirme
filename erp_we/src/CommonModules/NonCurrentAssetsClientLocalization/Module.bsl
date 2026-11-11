////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "Non-current assets" intended for localization.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// LongDesc
// 
// Parameters:
// 	Command - FormCommand - 
// 	Form - ClientApplicationForm - 
Procedure OnExecuteCommand(Command, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueCommandExecution = True;
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

Procedure PerformActionAfterCalculation(Form, ActionAfterCalculation) Export


EndProcedure

Function NameOfFormDocumentsForMainFacility() Export

	FormName = Undefined;
	
	
	Return FormName;
	
EndFunction

Function FormNameDocumentsOnIntangibleAsset() Export

	FormName = Undefined;
	
	
	Return FormName;
	
EndFunction

Procedure WhenChangingDetailsOfAcceptanceForAccountingFA(Item, Form, AdditionalParameters, ServerCallRequired_) Export

	
EndProcedure

Procedure WhenYouChangeDetailsOfFAUnion(Item, Form, AdditionalParameters, ServerCallRequired_) Export

	
EndProcedure

#Region MasterDataSectionNonCurrentAssets

Procedure WhenExecuting_CommandNonCurrentAssetsReferencePanel(Command, Form) Export

	
EndProcedure

#EndRegion


#EndRegion

#Region Private

Function ProcessingActionDetailsOfMonthClosingFormAndFADepreciation(Parameters) Export

	ProcessSucceeded = False;
	
	
	Return ProcessSucceeded;
	
EndFunction

Function ProcessingOfActionDetailsOfMonthClosingFormAndDepreciationOfIA(Parameters) Export

	ProcessSucceeded = False;
	
	
	Return ProcessSucceeded;
	
EndFunction


#EndRegion
