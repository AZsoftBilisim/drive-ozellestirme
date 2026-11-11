
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Object.Copies = 1;
	Object.LabelsTemplate        = Catalogs.LabelAndPriceTagTemplates.DefaultTemplate(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins);
	Object.TemplateAssignment = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins;
		
	If IsTempStorageURL(Parameters.AddressInStorage) Then
		StructureOfParameters = GetFromTempStorage(Parameters.AddressInStorage);
		
		Warehouse     = StructureOfParameters.Warehouse;
		Premise = StructureOfParameters.Premise;
		
		Object.StorageBins.Load(StructureOfParameters.Cells);
		
		For Each RowOfTables In Object.StorageBins Do
			RowOfTables.Barcode = NumericCodeFromLink(RowOfTables.Cell); 
		EndDo;
		
	EndIf;
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse",Warehouse));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	SetFormFunctionalOptionParameters(New Structure("Warehouse",Warehouse));
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStorageBins

&AtClient
Procedure StorageBinsOnEditEnd(Item, NewRow, CancelEdit)
	CurrentData = Item.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.Cell) Then
		CurrentData.Barcode = NumericCodeFromLink(CurrentData.Cell);
	Else
		CurrentData.Barcode = "";
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Print(Command)
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CommandParameter = New Array;
	CommandParameter.Add(PredefinedValue("Catalog.StorageBins.EmptyRef"));
	
	PrintManagementClient.ExecutePrintCommand(
		"DataProcessor.PrintPriceTagsAndLabels",
		"LabelStorageCells",
		CommandParameter,
		ThisForm,
		GetParametersForStorageCells());

EndProcedure

#Region Other

&AtServer
Function GetParametersForStorageCells()
	
	StorageBins = Object.StorageBins.Unload();
	
	PrintParameters = New Structure;
	PrintParameters.Insert("StorageBins",        PutToTempStorage(StorageBins, UUID));
	PrintParameters.Insert("LabelsTemplate",         Object.LabelsTemplate);
	PrintParameters.Insert("Copies",  Object.Copies);
	PrintParameters.Insert("StructureOfTemplateTemplate", Undefined);
	
	Return PrintParameters;
	
EndFunction

&AtServerNoContext
Function NumericCodeFromLink(Cell)
	Return BarcodingOfPrintForms.NumericCodeFromLink(Cell);
EndFunction

#EndRegion

#EndRegion
