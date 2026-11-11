
#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AttributesList = "Ref, Department, DateOfMaterialWorkConsumption, Purpose, ConsumptionInOneDay";
	ObjectStructure = New Structure(AttributesList);
	
	If Parameters.Property("Ref") Then
		FillPropertyValues(ObjectStructure, Parameters, "Ref");
	EndIf;
	
	If Parameters.Property("AddressMaterialsForSeries") Then
		AddressMaterialsForSeries = Parameters.AddressMaterialsForSeries;
	EndIf;
	GetMaterialsForSpecifyingSeriesFromTemporaryStorage();
	
	If Parameters.Property("SeriesSpecificationParameters") Then
		SeriesSpecificationParameters = Common.CopyRecursive(Parameters.SeriesSpecificationParameters);
		SeriesSpecificationParameters.NameOfValueSourceInObjectForm = "ObjectStructure";
	EndIf;
	
	If Parameters.Property("Department") Then
		ObjectStructure.Department = Parameters.Department;
	EndIf;
	
	If Parameters.Property("DateOfMaterialWorkConsumption") Then
		ObjectStructure.DateOfMaterialWorkConsumption = Parameters.DateOfMaterialWorkConsumption;
	EndIf;
	
	If Parameters.Property("Purpose") Then
		ObjectStructure.Purpose = Parameters.Purpose;
	EndIf;
	
	If Parameters.Property("ConsumptionInOneDay") Then
		ObjectStructure.ConsumptionInOneDay = Parameters.ConsumptionInOneDay;
	EndIf;
	
	If Parameters.Property("SeriesState") Then
		SeriesState = Parameters.SeriesState;
		SetSelectionBySeriesStatus(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	ProductsServer.CheckSeriesCompletion(ThisForm, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SeriesStateOnChange(Item)
	
	SetSelectionBySeriesStatus(ThisForm);
	
EndProcedure

&AtClient
Procedure SeriesStateClearing(Item, StandardProcessing)
	
	SetSelectionBySeriesStatus(ThisForm);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndWorksConsumption

&AtClient
Procedure MaterialsAndWorksConsumptionSeriesOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = CurrentData.Series;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	If CheckFilling() Then
		PlaceMaterialsForSpecifyingSeriesInStorage();
		Close(DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.AllowZeroCount = False;
	
	Notification = New CallbackDescription("BreakTSStringCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(MaterialsAndWorksConsumption, Items.MaterialsAndWorksConsumption, Notification,
		StringSplittingParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region StandardAppearance
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "MaterialsAndWorksConsumptionProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "MaterialsAndWorksConsumption.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
		
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
		"MaterialsAndWorksConsumptionCharacteristic",
		"MaterialsAndWorksConsumption.ItemVariantsAreUsed");
		
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisForm,
		"SeriesAlwaysWHGoods",
		"MaterialsAndWorksConsumptionSeries",
		"MaterialsAndWorksConsumption.BatchesIndicationStatus",
		"MaterialsAndWorksConsumption.ItemsType");
	
	#EndRegion
	
	StatusesList = New ValueList;
	StatusesList.Add(1);
	StatusesList.Add(13);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	NewItem = ConditionalAppearanceItem.Fields.Items.Add();
	NewItem.Field = New DataCompositionField(Items.MaterialsAndWorksConsumptionSeries.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MaterialsAndWorksConsumption.BatchesIndicationStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = StatusesList;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionBySeriesStatus(Form)
	
	ItemTableExpense = Form.Items.MaterialsAndWorksConsumption;
	
	If Form.SeriesState = "1" Then
		FilterStructure1 = New FixedStructure("BatchesIndicationStatus", 1);
		ItemTableExpense.RowFilter = FilterStructure1;
	Else
		FilterStructure1 = New FixedStructure("BatchesIndicationStatus", 2);
		ItemTableExpense.RowFilter = FilterStructure1;
	EndIf;
	
EndProcedure

#Region FormServiceCommandHandlers

&AtClient
Procedure BreakTSStringCompletion(NewRow, AdditionalParameters) Export 
	
	If NewRow = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
	
	RowsArray = New Array;
	RowsArray.Add(CurrentData.GetID());
	RowsArray.Add(NewRow.GetID());
	AfterChangingTSStringsProgrammaticallyOnServer(RowsArray, StructureOfActions);

EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(
							ThisForm,
							SeriesSpecificationParameters,
							Text,
							CurrentData);
	
	If NeedServerCall Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.MaterialsAndWorksConsumption.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		AdditionalParameters = New Structure("SeriesSpecificationParameters,ParametersOfSeriesIndicationForm", 
											SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,
					ParametersOfSeriesIndicationForm,
					ThisForm,,,,
					CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		ProcessSeriesIndication_Server(
				AdditionalParameters.SeriesSpecificationParameters,
				AdditionalParameters.ParametersOfSeriesIndicationForm);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(Val SeriesSpecificationParameters, Val ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(
		ThisForm,
		SeriesSpecificationParameters,
		ParametersOfSeriesIndicationForm,
		Undefined);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(
		ThisForm,
		SeriesSpecificationParameters,
		CurDataId,
		ThisForm);
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure FillInServiceDetailsOfTableParts(FillInLines = Undefined)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		
	ProductsServer.FillInServiceDetailsForProductInCollection(
		MaterialsAndWorksConsumption,
		StructureOfActions,
		FillInLines);
	
EndProcedure

// This procedure should be used if the rows were added programmatically (not interactively) when splitting the rows.
// The procedure performs actions that depend on the data in the rows.
//
&AtServer
Procedure AfterChangingTSStringsProgrammaticallyOnServer(ArrayOfRowIDs_ = Undefined, StructureOfPreviouslyPerformedActions = Undefined)

	RowsArray = Undefined;
	RowsCollection = MaterialsAndWorksConsumption;
	If ArrayOfRowIDs_ <> Undefined Then
		RowsArray = New Array;
		For Each RowID In ArrayOfRowIDs_ Do
			RowsArray.Add(MaterialsAndWorksConsumption.FindByID(RowID));
		EndDo;
		RowsCollection = RowsArray;
	EndIf;
	
	If StructureOfPreviouslyPerformedActions = Undefined Then
		StructureOfPreviouslyPerformedActions = New Structure;
	EndIf;
	
	If Not StructureOfPreviouslyPerformedActions.Property("FillInFeatureAttribute")
		Or Not StructureOfPreviouslyPerformedActions.Property("FillInArticleAttribute")
		Or Not StructureOfPreviouslyPerformedActions.Property("FillInProductTypeAttribute_") Then
		FillInServiceDetailsOfTableParts(RowsArray);
	EndIf;
	
	For Each CurrentData In RowsCollection Do
		If ObjectStructure.ConsumptionInOneDay And ObjectStructure.DateOfMaterialWorkConsumption <> '000101010000' Then
			CurrentData.DateOfMaterialWorkConsumption = ObjectStructure.DateOfMaterialWorkConsumption;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure PlaceMaterialsForSpecifyingSeriesInStorage()
	
	Table = MaterialsAndWorksConsumption.Unload();
	If IsTempStorageURL(AddressMaterialsForSeries) Then
		PutToTempStorage(Table, AddressMaterialsForSeries);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetMaterialsForSpecifyingSeriesFromTemporaryStorage()
	
	If IsTempStorageURL(AddressMaterialsForSeries) Then
		Table = GetFromTempStorage(AddressMaterialsForSeries);
		MaterialsAndWorksConsumption.Load(Table);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
