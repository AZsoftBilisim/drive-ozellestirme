#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Object.Copies = 1;
	
	DefaultTemplate = Catalogs.LabelAndPriceTagTemplates.DefaultTemplate(
		Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationTape);
		
	If Not ValueIsFilled(DefaultTemplate) Then
		DefaultTemplate = Catalogs.LabelAndPriceTagTemplates.DefaultTemplate(
			Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper);
	EndIf;
	
	Object.LabelsTemplate = DefaultTemplate;
	
	If Parameters.Property("PrintFromDocument") Then
	
		PrintParameters = Parameters.PrintFromDocument; // Structure
		
		DataForPrint = PrintManagementTMServerCall.DataForPrintingPriceTagsAndLabels(
			PrintParameters.Id,
			PrintParameters.PrintObjects,
			PrintParameters.AdditionalParameters);
			
		CommonClientServer.SupplementTable(DataForPrint, Object.InventoryInOperation);
		
	EndIf;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, DataProcessors.PrintLabelsOfInventoryInOperation));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	FillInServiceDetailsOfTS();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.LotsOfInventoryInOperation.Form.PickForm"
		And ValueSelected.Count() > 0 Then
			
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInventoryInOperation

&AtClient
Procedure InventoryInOperationAssetIDChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) <> Type("Structure") Then
		Return;
	EndIf;

	StandardProcessing = False;
	
	CurrentData = Items.InventoryInOperation.CurrentData;
	
	CurrentData.AssetID = ValueSelected.AssetID;
	CurrentData.Products = ValueSelected.Products;
	CurrentData.Characteristic = ValueSelected.Characteristic;
	CurrentData.Series = ValueSelected.Series;
	CurrentData.Individual = ValueSelected.Individual;
	CurrentData.Lot = ValueSelected.Lot;
	CurrentData.StocktakingRecord = ValueSelected.StocktakingRecord;
	CurrentData.AccountingForIndividuals = ValueSelected.AccountingForIndividuals;
	
	StructureOfActions = New Structure;
	AddActionsWhenChangingProducts(StructureOfActions, ThisObject, CurrentData);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure InventoryInOperationAssetIDAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	InventoryInOperationClient.AutoSelectionByInventoryNumber(
		Text,
		Undefined,
		ChoiceData,
		StandardProcessing);

EndProcedure

&AtClient
Procedure InventoryInOperationLotChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) <> Type("Structure") Then
		Return;
	EndIf;

	StandardProcessing = False;
	
	CurrentData = Items.InventoryInOperation.CurrentData;
	CurrentData.Lot = ValueSelected.Lot;
	CurrentData.StocktakingRecord = ValueSelected.StocktakingRecord;
	CurrentData.AccountingForIndividuals = ValueSelected.AccountingForIndividuals;

EndProcedure

&AtClient
Procedure InventoryInOperationProductsOnChange(Item)
	
	CurrentRow = Items.InventoryInOperation.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsWhenChangingProducts(StructureOfActions, ThisObject, CurrentRow);
	AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object);
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure InventoryInOperationCharacteristicOnChange(Item)
	
	CurrentRow = Items.InventoryInOperation.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object);
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure InventoryInOperationSeriesOnChange(Item)
	
	CurrentRow = Items.InventoryInOperation.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

EndProcedure

&AtClient
Procedure InventoryInOperationSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PickUpShoppingCenter();
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CommandParameter = New Array;
	CommandParameter.Add(PredefinedValue("Catalog.LotsOfInventoryInOperation.EmptyRef"));
	
	PrintManagementClient.ExecutePrintCommand(
		"DataProcessor.PrintPriceTagsAndLabels",
		"LabelTMTSVOperation",
		CommandParameter,
		ThisObject,
		GetPrintSettings_());

EndProcedure

#EndRegion

#Region Private

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)

	If Not ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm, SeriesSpecificationParameters, Text, CurrentData) Then
		Return;
	EndIf;
		
	If CurrentData = Undefined Then
		CurDataId = Items.InventoryInOperation.CurrentData.GetID();
	Else
		CurDataId = CurrentData.GetID();
	EndIf;

	ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
	
	AddlParameters = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
	CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AddlParameters);
	
	OpenForm(
		ParametersOfSeriesIndicationForm.FormName,
		ParametersOfSeriesIndicationForm,
		ThisObject,,,, 
		CallbackDescription, 
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    If Result <> Undefined Then
        ProcessSeriesIndication_Server(AdditionalParameters.ParametersOfSeriesIndicationForm);
    EndIf;

EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
		
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);

EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisObject);
	
EndFunction

#EndRegion

#Region Other

&AtServer
Function GetPrintSettings_()
	
	PrintData = Object.InventoryInOperation.Unload();
	
	PrintParameters = New Structure;
	PrintParameters.Insert("AddressInStorage", PutToTempStorage(PrintData, UUID));
	PrintParameters.Insert("LabelsTemplate", Object.LabelsTemplate);
	PrintParameters.Insert("Copies", Object.Copies);
	
	Return PrintParameters;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		"InventoryInOperationCharacteristic",
		"Object.InventoryInOperation.ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject, 
		"SeriesAlwaysWHGoods",
		"InventoryInOperationSeries",
		"Object.InventoryInOperation.BatchesIndicationStatus",
		"Object.InventoryInOperation.ItemsType");
	
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(
		ThisObject, 
		True,
		"InventoryInOperationBatchesIndicationStatus",
		"Object.InventoryInOperation.BatchesIndicationStatus");
	
	InventoryInOperationServer.SetConditionalRegistrationOfInventoryNumber(
		ThisObject,
		"InventoryInOperationAssetID",
		"Object.InventoryInOperation.StocktakingRecord",
		"Object.InventoryInOperation.Lot");
	
	InventoryInOperationServer.EstablishConditionalRegistrationOfIndividual(
		ThisObject,
		"InventoryInOperationIndividual",
		"Object.InventoryInOperation.AccountingForIndividuals",
		"Object.InventoryInOperation.Lot");
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)

	If ValueSelected.Count() = 0 Then
		Return;
	EndIf;

	For Each ArrayElement In ValueSelected Do
		
		If Type("Structure") = TypeOf(ArrayElement) Then
			RowData = Object.InventoryInOperation.Add();
			FillPropertyValues(RowData, ArrayElement);
			RowData.Lot = ArrayElement.Lot;
		Else
			Object.InventoryInOperation.Add().Lot = ArrayElement;
		EndIf;
		
	EndDo;

	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);

	FillInServiceDetailsOfTS();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTS()

	If Object.InventoryInOperation.Count() = 0 Then
		Return;
	EndIf;

	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.InventoryInOperation, ParametersForFillingInBankingDetails);
	
	InventoryInOperationServer.FillInServiceDetailsForBatchOfGoodsAndMaterials(Object.InventoryInOperation);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingProducts(StructureOfActions, Form, CurrentRow)

	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters, Warehouse", Form.SeriesSpecificationParameters, Undefined);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object)

	StructureOfActions.Insert("FillInBatchOfTMTSV");
	
EndProcedure

&AtClient
Procedure PickUpShoppingCenter()
	
	FormParameters = New Structure;
	FormParameters.Insert("CloseOnChoice", False);
	
	OpenForm("Catalog.LotsOfInventoryInOperation.Form.PickForm", FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#EndRegion
