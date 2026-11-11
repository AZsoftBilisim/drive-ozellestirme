#Region Variables

&AtClient
Var CachedValues;

&AtServer
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	EstablishVisibilityOfRNPTQuantity();

	#Region StandardSubsystems
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	

	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	UseTrackingOfTraceableItems = GetFunctionalOption("UseTraceableImportedGoodsAccounting");
	Items.GoodsCCDNumber.Visible = UseTrackingOfTraceableItems;
	Items.GoodsQuantityByGBRN.Visible = UseTrackingOfTraceableItems;

	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, 
		Items.GoodsCCDNumber.Name);

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion	

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.TransferInOperation));
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	SetVisibilityOfSeriesElements();
	FillInServiceDetailsOfTS();
	
	Items.DocumentBasis.Visible = ValueIsFilled(Object.DocumentBasis);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.LotsOfInventoryInOperation.Form.PickForm" 
		And ValueSelected.Count() > 0 Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
	
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	

	FillInServiceDetailsOfTS();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	

	Notify("Write_TransferInOperation", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	CheckToFillInBatchOfGoodsAndMaterialsInOperation();
	
	DateOnChangeServer();
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	EstablishVisibilityOfRNPTQuantity();
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	CheckToFillInBatchOfGoodsAndMaterialsInOperation();
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()

	RecalculateNumberOfRNPT();

EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	CheckToFillInBatchOfGoodsAndMaterialsInOperation();
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object);
	
	AddActionsWhenChangingProducts(StructureOfActions, ThisObject, CurrentRow);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Department");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberOnChange(Item)

	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillParameters = New Structure("CCDNumber", CurrentData.CCDNumber);
	
	Actions = New Structure;
	Actions.Insert("FillInCCDNumberType", FillParameters);
	Actions.Insert("FillInCountryOfOriginForCCDNumber", FillParameters);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions,
		"Department");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);

EndProcedure

&AtClient
Procedure GoodsCountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsIndividualOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsAssetIDAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	PickingParameters = InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation(Object.Date, Object.Organization, Object.Department);
	PickingParameters.CurrentRegistrar = Object.Ref;

	InventoryInOperationClient.AutoSelectionByInventoryNumber(
		Text, 
		PickingParameters,
		ChoiceData,
		StandardProcessing);

EndProcedure

&AtClient
Procedure GoodsAssetIDChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) <> Type("Structure") Then
		Return;
	EndIf;

	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentData.AssetID = ValueSelected.AssetID;
	CurrentData.Products = ValueSelected.Products;
	CurrentData.Characteristic = ValueSelected.Characteristic;
	CurrentData.Series = ValueSelected.Series;
	CurrentData.Individual = ValueSelected.Individual;
	CurrentData.Lot = ValueSelected.Lot;
	CurrentData.LineOfBusinessSender = ValueSelected.LineOfBusiness;
	CurrentData.StocktakingRecord = ValueSelected.StocktakingRecord;
	CurrentData.AccountingForIndividuals = ValueSelected.AccountingForIndividuals;
	
	StructureOfActions = New Structure;
	AddActionsWhenChangingProducts(StructureOfActions, ThisObject, CurrentData);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsLotChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) <> Type("Structure") Then
		Return;
	EndIf;

	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentData.AssetID = ValueSelected.AssetID;
	CurrentData.Lot = ValueSelected.Lot;
	CurrentData.StocktakingRecord = ValueSelected.StocktakingRecord;
	CurrentData.AccountingForIndividuals = ValueSelected.AccountingForIndividuals;

EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pickup(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CloseOnChoice", False);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Department", Object.Department);
	FormParameters.Insert("CurrentRegistrar", Object.Ref);
	
	OpenForm("Catalog.LotsOfInventoryInOperation.Form.PickForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();

EndProcedure

&AtClient
Procedure FillInIndividualRecipient(Command)
	
	InventoryInOperationClient.FillInIndividual(Object.Goods, Items.Goods.SelectedRows, "IndividualRecipient");
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

#Region AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
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

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem


#EndRegion

#EndRegion

#Region Private

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)

	If Not ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm, SeriesSpecificationParameters, Text, CurrentData) Then
		Return;
	EndIf;
		
	If CurrentData = Undefined Then
		CurDataId = Items.Goods.CurrentData.GetID();
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

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer(UpdateParametersForSpecifyingSeries = False)
	
	If UpdateParametersForSpecifyingSeries Then
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.TransferInOperation));
	EndIf; 
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns = "Products,Characteristic,Series,AssetID,Individual,Lot,Count";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	
	AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object);
	
	RowsToProcess = New Array;
	
	For Each TSRow In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, TSRow);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	FillInServiceDetailsOfTS();
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	
	InventoryInOperationServer.SetConditionalRegistrationOfInventoryNumber(ThisObject);
	InventoryInOperationServer.EstablishConditionalRegistrationOfIndividual(ThisObject, "GoodsIndividual");
	InventoryInOperationServer.EstablishConditionalRegistrationOfIndividual(ThisObject, "GoodsIndividualRecipient");
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, True);
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsCCDNumberOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfInputFieldCountryOfOrigin = "GoodsCCDNumberOriginCountry";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	AccountingForTraceableGoodsLocalization.EstablishConditionalAppearanceInDocumentPurchaseOfGoodsServices(ThisForm);
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	
EndProcedure

&AtServer
Procedure CheckToFillInBatchOfGoodsAndMaterialsInOperation()
	
	If Object.Goods.Count() = 0 Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	If ValueSelected.Count() = 0 Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(Object, StructureOfActions, "Department");
	
	RowsToProcess = New Array;
	
	For Each ArrayElement In ValueSelected Do
		NewRow = Object.Goods.Add();
		If Type("Structure") = TypeOf(ArrayElement) Then
			FillPropertyValues(NewRow, ArrayElement);
			NewRow.LineOfBusinessSender = ArrayElement.LineOfBusiness;
			NewRow.LineOfBusinessRecipient = ArrayElement.LineOfBusiness;
		Else
			NewRow.Lot = ArrayElement;
		EndIf;
		RowsToProcess.Add(NewRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);

	FillInServiceDetailsOfTS();
	
EndProcedure
 
&AtServer
Procedure FillInServiceDetailsOfTS()

	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
											New Structure("Products", "TheRecordsAreKeptByCCD"));
											
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
		
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);

	InventoryInOperationServer.FillInServiceDetailsForBatchOfGoodsAndMaterials(Object.Goods);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingProducts(StructureOfActions, Form, CurrentRow)
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters, Warehouse", Form.SeriesSpecificationParameters, Undefined);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object)

	ChoiceParameters = InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation();
	ChoiceParameters.Date = Object.Date;
	ChoiceParameters.Organization = Object.Organization;
	ChoiceParameters.Department = Object.Department;
	ChoiceParameters.CurrentRegistrar = Object.Ref;
	
	StructureOfActions.Insert("FillInBatchOfTMTSV", ChoiceParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Form.Object,
		StructureOfActions,
		"Department");
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If ValueIsFilled(Object.Department)
		And ValueIsFilled(Object.Organization) Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												"Department");
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfRNPTQuantity()
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
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
