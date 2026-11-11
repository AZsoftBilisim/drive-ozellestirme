
#Region Public

#EndRegion

#Region Internal

// See CommonClientOverridable.BeforeStart
// 
// Parameters:
//	Parameters - See CommonClientOverridable.BeforeStart.Parameters
//
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientParameters.Property("DataAreaLocked") Then
		Parameters.Cancel = True;
		Parameters.InteractiveHandler = New CallbackDescription(
			"ShowMessageBoxAndContinue",
			StandardSubsystemsClient,
			ClientParameters.DataAreaLocked);
		Return;
	EndIf;
	
EndProcedure

#EndRegion