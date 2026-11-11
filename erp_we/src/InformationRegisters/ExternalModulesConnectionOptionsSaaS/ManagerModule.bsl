#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns:
// Boolean, String, Undefined - safe mode status or Undefined.
//
Function ExternalModuleExecutionMode(Val ProgramModuleType, Val ModuleID) Export
	
	Manager = CreateRecordManager();
	Manager.ProgramModuleType = ProgramModuleType;
	Manager.ModuleID = ModuleID;
	Manager.Read();
	If Manager.Selected() Then
		
		Return Manager.SafeMode;
		
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction

#EndRegion

#EndIf