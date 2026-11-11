
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	TMCommonUse.CustomizePeripherals(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion

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
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
		
	Notify("Write_EnterRentalInvestmentBalance", WriteParameters, Object.Ref);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
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

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	LeasedAssetAccounting.FillInGraphFilledColumn(
		Object.FA,
		Object.ServicePaymentSchedule,
		Object.ServiceAccrualSchedule);
		
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
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
Procedure OrganizationOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfChangeOnServer();
	
EndProcedure

#Region StandardSubsystems

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FAFixedAssetOnChange(Item)
	
	WhenChangingFAOnServer();
	
EndProcedure

&AtClient
Procedure FAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected).Count() <> 0 Then
		WhenChangingFAOnServer();
	EndIf;

EndProcedure

&AtClient
Procedure FASelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "FAScheduleRef" Then
		OpenFillInSchedule(RowSelected);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure FABeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.FA.CurrentData;
	
	If CurrentData <> Undefined Then
		
		LeasedAssetAccountingClient.RemoveFAFromCharts(Object, CurrentData.FixedAsset);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
	
&AtClient
Procedure Pickup(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInCharts(Command)
	
	SelectedFA = New Array;
	For Each SelectedRow In Items.FA.SelectedRows Do
		RowData = Object.FA.FindByID(SelectedRow);
		SelectedFA.Add(RowData.FixedAsset);
	EndDo;
	
	AddressOfGraphs = PutGraphsInTemporaryStorage(Object, UUID);
	
	LeasedAssetAccountingClient.OpenFillingInRentalIncomeSchedules(
		Object,
		ThisObject,
		SelectedFA,
		AddressOfGraphs,
		New CallbackDescription("FillInScheduleOfPaymentsAndAccrualsEnd", ThisObject));
		
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

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands
	
#Region BarcodesAndTradeEquipment

&AtClient
Procedure ImportDataFromPDT(Command)
	
	LoadDataFromTSD();
	
EndProcedure

#EndRegion

#Region UniversalMechanisms_Commands

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

#EndRegion

#Region StandardSubsystems_Commands

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

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
	
	PeripheralsPortableDataTerminalsServerClient.StartDownloadingDataFromTSD(
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

&AtServer
Procedure OnReadCreateAtServer()
	
	ConfigureDependentFormElementsOnServer();
	
	DeleteIrrelevantGraphLines();
	
	LeasedAssetAccounting.FillInGraphFilledColumn(
		Object.FA,
		Object.ServicePaymentSchedule,
		Object.ServiceAccrualSchedule); 
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedDetailsOrElement = "")

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Val Form, Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Object = Form.Object;
	
	AuxiliaryAttributes = New Structure;
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_InputOfBalancesOfInvestmentInRent(
		Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters);
	EndIf; 
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		CurrencyOfMan = SettingsValueCached.ManagementAccountingCurrency();
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
		NonCurrentAssetsInternal.SetStructureProperty("CurrencyOfMan", CurrencyOfMan, FormServiceParameters);
		NonCurrentAssetsInternal.SetStructureProperty("ComplCurrency", ComplCurrency, FormServiceParameters);
		NonCurrentAssetsInternal.SetStructureProperty("CurrencyOfManPresentation", String(CurrencyOfMan), FormServiceParameters);
		NonCurrentAssetsInternal.SetStructureProperty("ComplCurrencyPresentation", String(ComplCurrency), FormServiceParameters);
		
		AddContractDetailsToServiceParametersOfForm();
		
		Items.FANonGuaranteedResidualValueLocal.Title = NonCurrentAssetsClientServer.AddCurrencyToLine(
				NStr("vi = 'KTDN';
					|ru = 'БУ';
					|en = 'LA'; fa = 'محلی';
					|it = 'БУ';
					|pl = 'EK';
					|tr = 'Muhasebe'"), 
				FormServiceParameters.ComplCurrencyPresentation);
				
		Items.FANonGuaranteedResidualValueManag.Title = NonCurrentAssetsClientServer.AddCurrencyToLine(
				NStr("vi = 'KTQT';
					|ru = 'УУ';
					|en = 'MA'; fa = 'مدیریت';
					|it = 'УУ';
					|pl = 'EZ';
					|tr = 'Yönetim muhasebesi'"), 
				FormServiceParameters.CurrencyOfManPresentation);
				
		Items.FARentalPayments.Title = NonCurrentAssetsClientServer.AddCurrencyToLine(
				NStr("vi = 'Thanh toán tiền thuê (không gồm thuế GTGT)';
					|ru = 'Арендные платежи (без НДС)';
					|en = 'Rental payments (excluding VAT)'; fa = 'Rental payments (excluding VAT)';
					|it = 'Арендные платежи (без НДС)';
					|pl = 'Rental payments (excluding VAT)';
					|tr = 'Kira ödemeleri (KDV hariç)'"), 
				FormServiceParameters.ContractDetails_.ARAPCurrencyPresentation);
			
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	Return StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization");

EndFunction

&AtServer
Procedure AddContractDetailsToServiceParametersOfForm()
	
	ContractDetails_ = LeasedAssetAccounting.AttributesOfCounterpartySContract(Object.Contract);
	ContractDetails_.Insert("ARAPCurrencyPresentation", String(ContractDetails_.ARAPCurrency));

	NonCurrentAssetsInternal.SetStructureProperty(
		"ContractDetails_",
		ContractDetails_,
		FormServiceParameters);
		
EndProcedure

&AtServer
Procedure WhenChangingFAOnServer()
	
	LeasedAssetAccounting.FillInGraphFilledColumn(
		Object.FA,
		Object.ServicePaymentSchedule,
		Object.ServiceAccrualSchedule);
	
EndProcedure

&AtClient
Procedure OpenFillInSchedule(ValueSelected)

	If ValueSelected = Undefined Then
		Return;
	EndIf;

	RowData = Object.FA.FindByID(ValueSelected);
	
	FixedAsset = RowData.FixedAsset;
	
	If Not ValueIsFilled(FixedAsset) Then
		Return;
	EndIf;
	
	If Not ReadOnly Then
		LockFormDataForEdit();
	EndIf;
	
	AddressOfGraphs = PutGraphsInTemporaryStorage(Object, UUID);
	
	If RowData.ScheduleIsFull Then
		
		LeasedAssetAccountingClient.OpenIncomeRentalCharts(
			Object,
			ThisObject,
			FixedAsset,
			AddressOfGraphs,
			New CallbackDescription("OpenPaymentAndAccrualScheduleCompletion", ThisObject));
			
	Else
			
		SelectedFA = New Array;
		SelectedFA.Add(FixedAsset);
		
		LeasedAssetAccountingClient.OpenFillingInRentalIncomeSchedules(
			Object,
			ThisObject,
			SelectedFA,
			AddressOfGraphs,
			New CallbackDescription("FillInScheduleOfPaymentsAndAccrualsEnd", ThisObject));
		
	EndIf;

EndProcedure

&AtServerNoContext
Function PutGraphsInTemporaryStorage(Val Object, Val UUID)

	ContractSchedules = New Structure;
	ContractSchedules.Insert("ServiceAccrualSchedule", Object.ServiceAccrualSchedule.Unload());
	ContractSchedules.Insert("ServicePaymentSchedule", Object.ServicePaymentSchedule.Unload());
	ContractSchedules.Insert("InterestAccrualSchedule", Object.InterestAccrualSchedule.Unload());
	ContractSchedules.Insert("FATable", Object.FA.Unload());

	Address = PutToTempStorage(ContractSchedules, UUID);
	
	Return Address;
	
EndFunction

&AtClient
Procedure OpenPaymentAndAccrualScheduleCompletion(ClosingResult, AddlParameters) Export

	If Not IsTempStorageURL(ClosingResult) Then
		Return
	EndIf;

	OpenPaymentAndAccrualScheduleDirectlyOnServer(ClosingResult);
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInScheduleOfPaymentsAndAccrualsEnd(ClosingResult, AddlParameters) Export

	If Not IsTempStorageURL(ClosingResult) Then
		Return
	EndIf;

	OpenPaymentAndAccrualScheduleDirectlyOnServer(ClosingResult);
	AttachableCommandsClient.StartCommandUpdate(ThisObject);

EndProcedure

&AtServer
Procedure OpenPaymentAndAccrualScheduleDirectlyOnServer(Val ClosingResult)
	
	Modified = True;

	ContractSchedules = GetFromTempStorage(ClosingResult);

	Object.ServicePaymentSchedule.Load(ContractSchedules.ServicePaymentSchedule);
	Object.ServiceAccrualSchedule.Load(ContractSchedules.ServiceAccrualSchedule);
	Object.InterestAccrualSchedule.Load(ContractSchedules.InterestAccrualSchedule);
	
	For Each RowData In ContractSchedules.FATable Do
		FAStrings = Object.FA.FindRows(New Structure("FixedAsset", RowData.FixedAsset));
		For Each FAString In FAStrings Do
			FAString.RentalEndDate = RowData.RentalEndDate;
		EndDo;
	EndDo;
	
	LeasedAssetAccounting.FillInGraphFilledColumn(
		Object.FA,
		Object.ServicePaymentSchedule,
		Object.ServiceAccrualSchedule);
	LeasedAssetAccounting.FillInAmountOfRentalPayments(
		Object,
		FormServiceParameters.ContractDetails_.ARAPCurrency);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region FAScheduleRef
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAScheduleRef.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ScheduleIsFull");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Điền...';
													|ru = 'Заполнить...';
													|en = 'Fill...'; fa = 'تکمیل...';
													|it = 'Заполнить...';
													|pl = 'Fill...';
													|tr = 'Doldur...'"));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAScheduleRef.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ScheduleIsFull");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Mở...';
													|ru = 'Открыть...';
													|en = 'Open…'; fa = 'باز کردن…';
													|it = 'Открыть...';
													|pl = 'Open…';
													|tr = 'Aç...'"));
	#EndRegion
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	AddContractDetailsToServiceParametersOfForm();
	ConfigureDependentFormElementsOnServer("Contract");
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	DeleteIrrelevantGraphLines();
	ConfigureDependentFormElementsOnServer("Date");
	
EndProcedure

&AtServer
Procedure DeleteIrrelevantGraphLines()
	
	StartDate = BegOfDay(Object.Date);
	
	TabularSectionNames = New Array;
	TabularSectionNames.Add("ServicePaymentSchedule");
	TabularSectionNames.Add("ServiceAccrualSchedule");
	TabularSectionNames.Add("InterestAccrualSchedule");
	
	For Each TabularSectionName In TabularSectionNames Do
		
		ArrayOfRowsToDelete_1 = New Array;
		
		For Each PlotLine In Object[TabularSectionName] Do
			If PlotLine.Date < StartDate Then
				ArrayOfRowsToDelete_1.Add(PlotLine);
			EndIf;
		EndDo;
		
		For Each RowToDelete In ArrayOfRowsToDelete_1 Do
			Object[TabularSectionName].Delete(RowToDelete);
		EndDo;
		
	EndDo;
	
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
