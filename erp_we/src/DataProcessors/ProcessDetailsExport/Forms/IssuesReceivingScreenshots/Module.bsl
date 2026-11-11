#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ProcessPassedParameters();
	
EndProcedure

#EndRegion 

#Region Private

#Region InitializeForm 

&AtServer
Procedure ProcessPassedParameters()

	If IsTempStorageURL(Parameters.TempStorageAddress) Then
	
		ErrorsTable = GetFromTempStorage(Parameters.TempStorageAddress);
		ErrorsInGettingScreenshots.Load(ErrorsTable);
	
	EndIf;

EndProcedure

#EndRegion 

#EndRegion