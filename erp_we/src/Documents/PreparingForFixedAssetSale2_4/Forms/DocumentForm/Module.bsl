
#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Parameters.Key.IsEmpty() Then
		OnReadCreateAtServer();
	EndIf;

	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	TMCommonUse.CustomizePeripherals(ThisObject);
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands


	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			FillPropertyValues(Object, ValueSelected);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	FillInInformationInBasement();

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	

	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_PreparingForFixedAssetSale2_4", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();


	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	
	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	OrganizationWhenChangedOnServer();
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	PriceIncludesVATOnChangeServer(CachedValues);
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	RecalculateAmountsByCurrency();
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	VATTaxationOnChangeServer();
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		Return;
	EndIf; 
	
	PartnerWhenChangesAreMadeOnServer()
	
EndProcedure

&AtClient
Procedure PostInAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.PostInAccounting = True;
	EndIf;
	
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "RecordInLocalAccounting,PostInAccounting");

EndProcedure

&AtClient
Procedure RecordInTAOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInTA = True;
	EndIf;

	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "RecordInLocalAccounting,RecordInTA");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "RecordInManAccounting");

EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return; // WE have an empty handler
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	CounterpartyWhenChangesAreMadeOnServer();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FAOnChange(Item)
	WhenChangingFAOnServer();
EndProcedure

&AtClient
Procedure FASumOnChange(Item)
	
	Actions = New Structure;
	AddVATRecalculationActions(Actions, Object);
	Actions.Insert("RecalculatePriceDiscountByAmountInSales", New Structure("QuantityName", "Count"));
	
	TSRow = CreateLineForRecalculatingAmounts(Items.FA.CurrentData);
	BatchProcessingOfTablePartClient.ProcessTSString(TSRow, Actions, CachedValues);
	FillPropertyValues(Items.FA.CurrentData, TSRow);
	
EndProcedure

&AtClient
Procedure FAVATRateOnChange(Item)
	
	Actions = New Structure;
	AddActionsForRecalculatingAmounts(Actions, Object);
	
	TSRow = CreateLineForRecalculatingAmounts(Items.FA.CurrentData);
	BatchProcessingOfTablePartClient.ProcessTSString(TSRow, Actions, CachedValues);
	FillPropertyValues(Items.FA.CurrentData, TSRow);
	
EndProcedure

&AtClient
Procedure FAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected).Count() <> 0 Then
		WhenChangingFAOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FAOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not Copy Then
		If Object.VATTaxation <> PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT") Then
			CurrentData = Items.FA.CurrentData;
			CurrentData.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	
	WhenChangingFAOnServer();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers


&AtClient
Procedure Pickup(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");

	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);

	OpenForm("Catalog.Assets.ChoiceForm", PickingParameters, Items.FA);
	
EndProcedure

&AtClient
Procedure OpenPrintOptions(Command)
	
	PrintDetails = New Structure();
	
	PrintDetails.Insert("ShipperBankAccount",  Object.ShipperBankAccount);
	PrintDetails.Insert("GoodsRecipientBankAccount",   Object.GoodsRecipientBankAccount);
	PrintDetails.Insert("CounterpartyBankAccount",       Object.CounterpartyBankAccount);
	PrintDetails.Insert("CompanyBankAccount",       Object.CompanyBankAccount);
	PrintDetails.Insert("ChiefAccountant",                Object.ChiefAccountant);
	PrintDetails.Insert("Shipper",                Object.Shipper);
	PrintDetails.Insert("GoodsRecipient",                 Object.GoodsRecipient);
	PrintDetails.Insert("Basis",                       Object.Basis);
	PrintDetails.Insert("ReferenceDocumentDateForPrintForms",                   Object.ReferenceDocumentDateForPrintForms);
	PrintDetails.Insert("BaseDocumentNumber",                  Object.BaseDocumentNumber);
	PrintDetails.Insert("IssuiedBy",                        Object.IssuiedBy);
	PrintDetails.Insert("IssuiedByJobTitle",               Object.IssuiedByJobTitle);
	PrintDetails.Insert("Director",                    Object.Director);
	
	FormParameters = New Structure("PrintDetails", PrintDetails);

	Handler = New CallbackDescription("SetPrintDetails", ThisObject);
	OpenForm("Document.PreparingForFixedAssetSale2_4.Form.PrintDetails",
				FormParameters,
				ThisObject,,,Undefined,
				Handler,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ImportDataFromPDT(Command)
	
	LoadDataFromTSD();
	
EndProcedure

#EndRegion

#Region AttachableCommands

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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtServer
Procedure ProcessBarcodes(Val BarcodeData_5)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	ObjectsArray = NonCurrentAssets.FindFixedAssetsByBarcodes(BarcodeData_5, PickingParameters);
	If NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ObjectsArray).Count() <> 0 Then
		WhenChangingFAOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadDataFromTSD()
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, AdditionalParameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure SetPrintDetails(Result, AddlParameters) Export
	
	If Result <> Undefined And Result.Count() > 0 Then
		FillPropertyValues(Object, Result);
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	DocumentCurrency = Object.Currency;
	
	FillParameters = Documents.PreparingForFixedAssetSale2_4.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(
		Items.VATTaxation, 
		Object.VATTaxation, 
		FillParameters, 
		VATAccountingCachedParameterValues);
	
	FillInInformationInBasement();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(CurrencyOld, CurrencyNew)
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	CoursesAreOld = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyOld, DocumentDate, LocalAccountingCurrency);
	CoursesAreNew = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyNew, DocumentDate, LocalAccountingCurrency);
	PriceManagementSystem.ConvertTabularAmountsToCurrency(
		Object.FA, Object.PriceIncludesVAT, CurrencyOld, CurrencyNew, CoursesAreOld, CoursesAreNew, , , "Count");
	
EndProcedure

&AtClient
Procedure RecalculateAmountsByCurrency()
	
	If ValueIsFilled(Object.Currency) And DocumentCurrency<>Object.Currency And Object.FA.Count()>0 Then
		CurrencyOnChangeServer(DocumentCurrency, Object.Currency);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(ValuesCache)
	
	RecalculationActions = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	Actions = New Structure;
	Actions.Insert("RecalculateVATAmount", RecalculationActions);
	Actions.Insert("RecalculateAmountWithVAT", RecalculationActions);
	BatchProcessingOfTablePartServer.TreatTS(Object.FA, Actions, ValuesCache);
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.FA, StructureOfActions, CachedValuesInternal);
	
	RecalculationActions = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	Actions = New Structure();
	Actions.Insert("RecalculateVATAmount", RecalculationActions);
	Actions.Insert("RecalculateAmountWithVAT", RecalculationActions);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		StructureOfActions,
		Object.FA,
		Undefined);

EndProcedure

&AtClientAtServerNoContext
Procedure AddVATRecalculationActions(Actions, Object)
	
	RecalculationActions = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	Actions.Insert("RecalculateVATAmount", RecalculationActions);
	Actions.Insert("RecalculateAmountWithVAT", RecalculationActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsForRecalculatingAmounts(Actions, Object)
	
	AddVATRecalculationActions(Actions, Object);
	Actions.Insert("RecalculateAmount", "Count");
	
EndProcedure

&AtClientAtServerNoContext
Function CreateLineForRecalculatingAmounts(CurFALine)
	
	Structure = New Structure("Count, NumberOfPackages, Price, Sum, VATAmount, AmountIncludingVAT, VATRate");
	FillPropertyValues(Structure, CurFALine);
	Structure.Price = Structure.Sum;
	Structure.Count = 1;
	Structure.NumberOfPackages = 1;
	
	Return Structure;
	
EndFunction

&AtServer
Procedure DateOfChangeOnServer()
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	FillInInformationInBasement();
	
	ConfigureDependentFormElementsOnServer("Date");
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.CompanyBankAccount);
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();

	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	SalesServer.PartnerOnChange(Object);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject, "FAVATRate", "FAVATAmount", "FAAmountIncludingVAT");
	
EndProcedure

&AtServer
Procedure WhenChangingFAOnServer()
	
	FillInHeaderForSelectedFA();
	FillInInformationInBasement();
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedFA()

	ChangedBankingDetails = "";
	
	NonCurrentAssetsInternal.FillInHeaderForSelectedFA(
		"Organization,Department", 
		Object.FA, 
		Object, 
		ChangedBankingDetails);
	
	Documents.PreparingForFixedAssetSale2_4.FillInExpenseItemRetirement(
		Object.Organization, Object.Date, Object.FA, Object.RetirementItem);
	
	If StrSplit(ChangedBankingDetails, ",").Find("Organization") <> Undefined Then
		OrganizationWhenChangedOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.PreparingForFixedAssetSale2_4.ParametersForFillingInSalesVATTaxation(Object);
	
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	
	VATAccountingERP.FillInSalesVATTaxSelectionList(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, Val ChangedBankingDetails = "")

	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = (StructureOfChangedProps.Count() = 0);
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		Items.PostInAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.RecordInTA.Visible = FormServiceParameters.ComplianceCAAccountingIsKept;
		Items.RecordInManAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.DecorationIsReflectionOption.Visible = Items.PostInAccounting.Visible Or Items.RecordInManAccounting.Visible;
		
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently 
			And Not UpdateAll Then

			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = False;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = (StructureOfChangedProps.Count() = 0);
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
			
	EndIf;
	
	If UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);

	EndIf;

	PreparingForFixedAssetSaleLocalization.ConfigureDependentFormElements(ThisObject, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure FillInInformationInBasement()

	LabelTitle = New Array;
	
	
	If LabelTitle.Count() <> 0 Then
		Items.Information.Title = New FormattedString(LabelTitle);
		Items.PictureInformation.Visible = True;
		Items.Information.Visible = True;
	Else
		Items.PictureInformation.Visible = False;
		Items.Information.Visible = False;
	EndIf; 

EndProcedure

&AtServer
Procedure CounterpartyWhenChangesAreMadeOnServer()
	
	SalesServer.PartnerOnChange(Object);
	
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
