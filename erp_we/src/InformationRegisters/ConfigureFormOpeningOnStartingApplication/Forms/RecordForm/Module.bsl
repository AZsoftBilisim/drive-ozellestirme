
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	NewRecord =  Parameters.Key.IsEmpty();
	
	If NewRecord Then
		Record.User     = Parameters.User;
		Record.OpenedForm = Parameters.OpenedForm;
		
		OnReadCreateAtServer();		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	OnReadCreateAtServer();		
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	DimensionStructure = New Structure;
	DimensionStructure.Insert("User", Record.User);
	DimensionStructure.Insert("OpenedForm", Record.OpenedForm);
	
	Notify("Write_ConfigureFormOpeningOnStartingApplication", WriteParameters, DimensionStructure);
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	StructureOfFormParameters = OpenFormsOnApplicationStartClientServerOverridable.FormSettings(Record.OpenedForm);
	LaunchParameter = StructureOfFormParameters.LaunchParameter;
EndProcedure

#EndRegion

#EndRegion
