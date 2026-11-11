#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AddressInTempStorage = Parameters.AddressInTempStorage;
	BudgetFlowItems.Load(GetFromTempStorage(AddressInTempStorage));

	Items.BudgetFlowItems.Enabled = AccessRight("Update", Metadata.Catalogs.BudgetFlowItems);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBudgetFlowItems

&AtClient
Procedure BudgetFlowItemsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	For Each Value In ValueSelected Do
		If BudgetFlowItems.FindRows(New Structure("BudgetFlowItem", Value)).Count() > 0 Then
			Continue;
		EndIf;
		Record = BudgetFlowItems.Add();
		Record.BudgetFlowItem = Value;
	EndDo;
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	Dimension = PredefinedValue("ChartOfCharacteristicTypes.BudgetFlowItemDimensions.CashFlowReportItems");
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("CloseOnChoice", False);
	ChoiceFormParameters.Insert("CloseOnOwnerClose", True);
	ChoiceFormParameters.Insert("MultipleChoice", True);
	ChoiceFormParameters.Insert("ChoiceMode", True);
	ChoiceFormParameters.Insert("SelectGroups", False);
	ChoiceFormParameters.Insert("UsersGroupsSelection", False);
	ChoiceFormParameters.Insert("Dimension", Dimension);
	
	OpenForm("Catalog.BudgetFlowItems.Form.ChoiceFormByDimension", ChoiceFormParameters, Items.BudgetFlowItems);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	PutToTempStorageServer();
	Close(AddressInTempStorage);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure PutToTempStorageServer()
	
	PutToTempStorage(BudgetFlowItems.Unload(), AddressInTempStorage);
	
EndProcedure

#EndRegion
