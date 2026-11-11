
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("Owner") Then
		BillOfMaterials = Parameters.Filter.Owner;
		AllowChangeOfOwnership = Undefined;
		Items.BillOfMaterials.ReadOnly =
			Not Parameters.Property("AllowChangeOfOwnership", AllowChangeOfOwnership) Or AllowChangeOfOwnership <> True;
	Else
		SetSelectionBySpecification(ThisForm);
	EndIf;
	
	If Parameters.Property("ShowOnlyPredecessors") Then
		
		ReferencesArrray = CommonClientServer.ValueInArray(Parameters.ShowOnlyPredecessors);
		Predecessors = Catalogs.ProductionStages.Predecessors(ReferencesArrray)[ReferencesArrray[0]];
		
		CommonClientServer.SetDynamicListFilterItem(List, "Ref", Predecessors, DataCompositionComparisonType.InList,, True);
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BillOfMaterialsOnChange(Item)
	
	SetSelectionBySpecification(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClientAtServerNoContext
Procedure SetSelectionBySpecification(Form)

	CommonClientServer.SetDynamicListFilterItem(
			Form.List, 
			"Owner", 
			Form.BillOfMaterials,,, 
			True);

EndProcedure

#EndRegion

#EndRegion
