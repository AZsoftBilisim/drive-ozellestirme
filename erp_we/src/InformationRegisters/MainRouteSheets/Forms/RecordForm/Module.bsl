#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	OnReadCreateAtServer();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.Department = Common.ObjectAttributeValue(CurrentObject.RouteSheet, "Department");
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ProductDataManagementClient.NotifyAboutRecordingOfMainRouteMap(Record);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RouteSheetOnChange(Item)
	
	WhenChangingRouteMap(True, CachedValues);
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Record.Characteristic);

	StringStructure = New Structure;
	StringStructure.Insert("Products",   Record.Products);
	StringStructure.Insert("Characteristic", Record.Characteristic);
	StringStructure.Insert("ItemVariantsAreUsed", ItemVariantsAreUsed);
	
	BatchProcessingOfTablePartClient.ProcessTSString(StringStructure, StructureOfActions, CachedValues);

	FillPropertyValues(Record, StringStructure);
	
	ItemVariantsAreUsed = StringStructure.ItemVariantsAreUsed;
	Items.Characteristic.Enabled = ItemVariantsAreUsed;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure OnReadCreateAtServer()

	WhenChangingRouteMap(Record.SourceRecordKey.IsEmpty(), Undefined);
	
EndProcedure

&AtServer
Procedure WhenChangingRouteMap(FillFields, CachedValues)

	Items.Products.ChoiceList.Clear();
	
	If Record.RouteSheet.IsEmpty() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	               |	ManufacturedProducts.Products,
	               |	ManufacturedProducts.Characteristic
	               |FROM
	               |	Catalog.RouteSheets.ManufacturedProducts AS ManufacturedProducts
	               |WHERE
	               |	ManufacturedProducts.Ref = &Object
	               |
	               |ORDER BY
	               |	ManufacturedProducts.LineNumber";
	
	Query.SetParameter("Object", Record.RouteSheet);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	// We will limit the selection of products to the list of products of the route map
	While Selection.Next() Do
		Items.Products.ChoiceList.Add(Selection.Products);
	EndDo;
	
	// If this is a new entry, then we will try to automatically fill in the Nomenclature and Characteristic fields.
	If FillFields Then
		If Items.Products.ChoiceList.Count() = 1 Then
			Selection.Reset();
			Selection.Next();
			Record.Products   = Selection.Products;
			Record.Characteristic = Selection.Characteristic;
		EndIf; 
	EndIf; 
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Record.Characteristic);

	StringStructure = New Structure;
	StringStructure.Insert("Products",   Record.Products);
	StringStructure.Insert("Characteristic", Record.Characteristic);
	StringStructure.Insert("ItemVariantsAreUsed", ItemVariantsAreUsed);
	
	BatchProcessingOfTablePartServer.ProcessTSString(StringStructure, StructureOfActions, CachedValues);

	FillPropertyValues(Record, StringStructure);
	
	ItemVariantsAreUsed = StringStructure.ItemVariantsAreUsed;
	Items.Characteristic.Enabled = ItemVariantsAreUsed;
	
EndProcedure

#EndRegion

#EndRegion
