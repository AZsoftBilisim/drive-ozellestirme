#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Items.CostGroupsExpenseGroup.Title =
		ProcessingByThirdPartiesClientServer.CostGroupFieldHeader2_5(Parameters.CostGroupFields_);
	
	CostGroups.Load(GetFromTempStorage(Parameters.CostGroupStorageAddress));
	
	For Each GroupString In CostGroups Do
		
		If Parameters.CostGroupNumber = GroupString.CostGroupNumber Then
			Items.CostGroups.CurrentRow = GroupString.GetID();
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure ListOfGroupsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessGroupSelection();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectGroup(Command)
	
	ProcessGroupSelection();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessGroupSelection()

	CurrentData = Items.CostGroups.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("ExpenseGroup", CurrentData.ExpenseGroup);
	ChoiceParameters.Insert("CostGroupNumber", CurrentData.CostGroupNumber);
	ChoiceParameters.Insert("BillOfMaterials", CurrentData.BillOfMaterials);
	ChoiceParameters.Insert("SupplyAssignment", CurrentData.SupplyAssignment);
	ChoiceParameters.Insert("ThereIsImportedProduct", CurrentData.ThereIsImportedProduct);
	ChoiceParameters.Insert("ReferenceOrder", CurrentData.ReferenceOrder);
	ChoiceParameters.Insert("Stage", CurrentData.Stage);
	ChoiceParameters.Insert("OrderDocument", CurrentData.OrderDocument);
	ChoiceParameters.Insert("MethodOfAllocatingFinishedProductCosts", CurrentData.MethodOfAllocatingFinishedProductCosts);
	ChoiceParameters.Insert("ParametersForFillingAssignments", CurrentData.ParametersForFillingAssignments);
	ChoiceParameters.Insert("AppointmentSelectionList", CurrentData.AppointmentSelectionList);
	ChoiceParameters.Insert("TollManufacturing", CurrentData.TollManufacturing);
	Close(ChoiceParameters);
	
EndProcedure

#EndRegion
