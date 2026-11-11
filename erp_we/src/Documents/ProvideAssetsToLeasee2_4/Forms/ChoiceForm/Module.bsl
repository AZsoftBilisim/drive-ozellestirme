
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("Organization")
			And Not ValueIsFilled(Parameters.Filter.Organization) Then
			Parameters.Filter.Delete("Organization");
		EndIf; 
		If Parameters.Filter.Property("Leaseholder")
			And Not ValueIsFilled(Parameters.Filter.Leaseholder) Then
			Parameters.Filter.Delete("Leaseholder");
		EndIf; 
		If Parameters.Filter.Property("Department")
			And Not ValueIsFilled(Parameters.Filter.Department) Then
			Parameters.Filter.Delete("Department");
		EndIf; 
	EndIf; 
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion
