#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	EndIf;
	
	Items.GoodsSearchByBarcode.Visible = AccessRight("Read", Metadata.InformationRegisters.ItemsBarcodes);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsForProductRange();
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_GoodsShortageNote",WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals

	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, SelectionResult);
	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then	
		Items.Goods.CurrentData.Purpose = SelectionResult;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	WhenChangingWarehousePremisesDate();
	
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	
	WhenChangingWarehousePremisesDate();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	WhenChangingWarehousePremisesDate();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	Var CurrentRow;
	Var StructureOfActions;
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	If UseBinLocationWarehousing Then
		StructureOfActions.Insert("CheckFillPackageByOwner" , CurrentRow.Package);
	EndIf;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateWeightVolume");
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateWeightVolume");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisForm);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(
		New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow),
		UUID);
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(ExecutionResult, Var_Parameters) Export
	
	If ExecutionResult.Result Then
		ProcessBarcodes(ExecutionResult.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.MeasuredValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsUnitOfMeasureForWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsUnitOfMeasureForVolume.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInServiceDetailsForProductRange();
	WhenChangingWarehousePremisesDate(True);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WhenChangingWarehousePremisesDate(CallWhenReading = False)
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse,Premise",Object.Warehouse,Object.Premise));
	
	Items.Premise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.Date);
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, "GoodsPackage, GoodsCell", "Visible", UseBinLocationWarehousing);
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsShortageNote));
	
	If Not CallWhenReading Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		If Not(UseBinLocationWarehousing) Then
			For Each String In Object.Goods Do
				String.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
				String.Count = String.NumberOfPackages;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActionsWithAddedStrings.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActionsWithAddedStrings.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActionsWithAddedStrings.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActionsWithAddedStrings.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActionsWithAddedStrings.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.GoodsOnly                           = True;
	StructureOfActions.NotUsePackages                 = Not UseBinLocationWarehousing;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions,CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);

EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text, CurrentData) Then
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion",
														ThisObject,
														New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm));

		OpenForm(ParametersOfSeriesIndicationForm.FormName,
					ParametersOfSeriesIndicationForm,
					ThisForm,
					,
					,
					,
					CallbackDescription,
					FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
		
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
     
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(AdditionalParameters.ParametersOfSeriesIndicationForm, CachedValues);
    EndIf;

EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, CachedValues)
	
	Actions = New Structure;
	Actions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	Actions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	Actions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	Actions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	Actions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	Actions.Insert("RecalculateWeightVolume");
	Actions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters",
																				Object.Warehouse, SeriesSpecificationParameters));
	
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,Actions,CachedValues);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

#EndRegion

#Region Other

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateWeightVolume");

EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	ParametersForFillingInBankingDetails.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ParametersForFillingInBankingDetails.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ParametersForFillingInBankingDetails.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ParametersForFillingInBankingDetails.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateWeightVolume");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtClient
Procedure GoodsWeightOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByWeight");
	
	CurrentRow = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsVolumeM3OnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByVolume");
	
	CurrentRow = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
