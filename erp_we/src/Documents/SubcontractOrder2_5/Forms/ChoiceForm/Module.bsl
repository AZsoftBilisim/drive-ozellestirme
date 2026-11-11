#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance(); 
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("Partner") And Not ValueIsFilled(Parameters.Filter.Partner) Then
		Parameters.Filter.Delete("Partner");
	EndIf; 
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region StandardCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)

	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);

EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	Documents.SubcontractOrder2_5.SetConditionalListAppearance(List);
	
EndProcedure

#EndRegion
