#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	If Record.SourceRecordKey.IsEmpty() Then
		
		ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Record.Products);
		Items.Characteristic.Enabled = ItemVariantsAreUsed;
		
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") And Not ValueIsFilled(Record.Warehouse) Then
		Record.Warehouse = SettingsValueCached.GetDefaultWarehouse(Record.Warehouse, False);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Record.Products);
	Items.Characteristic.Enabled = ItemVariantsAreUsed;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductsOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Record.Characteristic);

	StringStructure = New Structure;
	StringStructure.Insert("Products", Record.Products);
	StringStructure.Insert("Characteristic", Record.Characteristic);
	StringStructure.Insert("ItemVariantsAreUsed", ItemVariantsAreUsed);
	
	BatchProcessingOfTablePartClient.ProcessTSString(StringStructure, StructureOfActions, CachedValues);

	FillPropertyValues(Record, StringStructure);
	
	ItemVariantsAreUsed = StringStructure.ItemVariantsAreUsed;
	Items.Characteristic.Enabled = ItemVariantsAreUsed;
	
EndProcedure

#EndRegion
