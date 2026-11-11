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
		Record.AddedAutomatically = False;
	EndIf;
	
	If Record.AddedAutomatically Then
		ReadOnly = True;
	Else
		OnReadCreateAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If Not Record.AddedAutomatically Then
		OnReadCreateAtServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductsPrerequisiteOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Record.ItemVariantPrerequisite);

	StringStructure = New Structure;
	StringStructure.Insert("Products", Record.ProductsPrerequisite);
	StringStructure.Insert("Characteristic", Record.ItemVariantPrerequisite);
	StringStructure.Insert("ItemVariantsAreUsed", PrerequisiteCharacteristicsAreUsed);
	
	BatchProcessingOfTablePartClient.ProcessTSString(StringStructure, StructureOfActions, CachedValues);

	Record.ProductsPrerequisite                 = StringStructure.Products;
	Record.ItemVariantPrerequisite               = StringStructure.Characteristic;
	PrerequisiteCharacteristicsAreUsed          = StringStructure.ItemVariantsAreUsed;
	Items.ItemVariantPrerequisite.Enabled = PrerequisiteCharacteristicsAreUsed;
	
EndProcedure

&AtClient
Procedure ProductsResultOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Record.ItemVariantConsequence);

	StringStructure = New Structure;
	StringStructure.Insert("Products", Record.ProductsResult);
	StringStructure.Insert("Characteristic", Record.ItemVariantConsequence);
	StringStructure.Insert("ItemVariantsAreUsed", ConsequenceCharacteristicsAreUsed);
	
	BatchProcessingOfTablePartClient.ProcessTSString(StringStructure, StructureOfActions, CachedValues);

	Record.ProductsResult        = StringStructure.Products;
	Record.ItemVariantConsequence      = StringStructure.Characteristic;
	ConsequenceCharacteristicsAreUsed = StringStructure.ItemVariantsAreUsed;
	Items.ItemVariantConsequence.Enabled = ConsequenceCharacteristicsAreUsed;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	PrerequisiteCharacteristicsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Record.ProductsPrerequisite);
	Items.ItemVariantPrerequisite.Enabled = PrerequisiteCharacteristicsAreUsed;
	
	ConsequenceCharacteristicsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Record.ProductsResult);
	Items.ItemVariantConsequence.Enabled = ConsequenceCharacteristicsAreUsed;
	
EndProcedure

#EndRegion

#EndRegion
