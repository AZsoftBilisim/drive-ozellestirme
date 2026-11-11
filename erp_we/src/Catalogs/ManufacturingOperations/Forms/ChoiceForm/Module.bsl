
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("FilterOwnerOfOperations", FilterOwnerOfOperations) Then
		
		SetUpSelectionElementOfOperationsByOwner();
		
		SetSelectionByOwnerOfOperations(ThisObject);
		
	Else
		
		Items.FilterOwnerOfOperations.Visible = False;
		
	EndIf; 

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectionOfOwnerOfOperationsOnChange(Item)
	
	SetSelectionByOwnerOfOperations(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure SetUpSelectionElementOfOperationsByOwner()
	
	OwnerMetadata = Metadata.FindByType(TypeOf(FilterOwnerOfOperations));
	If OwnerMetadata <> Undefined Then
		Items.FilterOwnerOfOperations.ReadOnly = True;
		Items.FilterOwnerOfOperations.Title = OwnerMetadata.ObjectPresentation;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByOwnerOfOperations(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"Owner",
		Form.FilterOwnerOfOperations,
		DataCompositionComparisonType.Equal,
		,
		True);
	
EndProcedure

#EndRegion

#EndRegion
