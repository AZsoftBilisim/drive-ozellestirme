
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
	InterestScheduleUpdated = True;
	DisplayGraphOfPercentagesFromRegister = True;

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
		
	Notify("Write_ChangeRentalTerms", WriteParameters, Object.Ref);
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
	
	ForceCloseTheForm = False;
	
	If WriteParameters.Property("ForceCloseTheForm", ForceCloseTheForm)
		And Not ForceCloseTheForm 
		Or WriteParameters.WriteMode = DocumentWriteMode.UndoPosting Then

		LeasedAssetAccounting.FillInGraphFilledColumn(
			Object.FA,
			Object.ServicePaymentSchedule,
			Object.ServiceAccrualSchedule);
				
		CalculateRateOfReturnOnServer(False, False);
		
	EndIf;

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

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If InterestScheduleUpdated Then
		InterestScheduleUpdated = Object.InterestAccrualSchedule.Count();
	EndIf;
	CurrentObject.AdditionalProperties.Insert("InterestScheduleUpdated", InterestScheduleUpdated);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);

	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChange(Item)
	
	If GeneratedDocument Then
		
		ListFilter = New Structure;
		ListFilter.Insert("Posted", True);
		If ValueIsFilled(Object.Organization) Then
			ListFilter.Insert("Organization", Object.Organization);
		EndIf;
		If ValueIsFilled(FormServiceParameters.ContractDetails_.LeaseContracts) Then
			ListFilter.Insert("Contract", FormServiceParameters.ContractDetails_.LeaseContracts);
		EndIf;

		CallbackDescription = New CallbackDescription("GeneratedDocumentOnChangeCompletion", ThisObject);

		FormParameters = New Structure;
		FormParameters.Insert("Filter", ListFilter);
		OpenForm("Document.LeaseTermAdjustment.ChoiceForm", FormParameters,,,,, CallbackDescription);

	Else

		Object.DocumentBasis = PredefinedValue("Document.LeaseTermAdjustment.EmptyRef");
		ConfigureDependentFormElements();
		
	EndIf;
	
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
	
	If Field.Name = "FARateOfReturn" Then
		ShowCalculation(Items.FA.CurrentData);
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

&AtClient
Procedure FAOnActivateRow(Item)
	
	SetAvailabilityOfHelpPrinting(Item.CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
	
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
Procedure FillInTheRentedOnes(Command)

	ClearMessages();
	
	If Not ValueIsFilled(Object.Contract) Then
		MessageText = NStr("vi = 'Cần chọn hợp đồng';
							|ru = 'Необходимо выбрать договор';
							|en = 'Select a contract'; fa = 'Select a contract';
							|it = 'È necessario selezionare l''accordo';
							|pl = 'Należy wybrać umowę';
							|tr = 'Bir sözleşme seçmek gereklidir'");
		CommonClient.MessageToUser(MessageText,, "Contract", "Object");
		Return;
	EndIf;

	If Object.FA.Count() <> 0 Then
		QueryText = NStr("vi = 'Điền danh sách đối tượng thuê theo hợp đồng?';
						|ru = 'Заполнить список предметов аренды по договору?';
						|en = 'Populate the list of rental objects under the contract?'; fa = 'Populate the list of rental objects under the contract?';
						|it = 'Compilare l''elenco degli elementi di affitto in base all''accordo?';
						|pl = 'Wypełnić listę przedmiotów dzierżawy zgodnie z umową?';
						|tr = 'Sözleşme kapsamında kiralanan eşyaların listesini doldurun?'");
		CallbackDescription = New CallbackDescription("FillInTheRentedOnesCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		FillWithRentedOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateRateOfReturn(Command)
	
	ExecutionResult = CalculateRateOfReturnOnServerInBackground();
		
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);

	TimeConsumingOperationsClient.WaitCompletion(ExecutionResult,
		New CallbackDescription("CalculateRateOfReturnCompletion", ThisObject),
		IdleParameters);
	
EndProcedure

&AtClient
Procedure ReferenceCalculationOfAccrualOfInterest(Command)
	
	LeasedAssetAccountingClient.ReferenceCalculationOfAccrualOfInterest(ThisObject);
	
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

&AtClient
Procedure SetAvailabilityOfHelpPrinting(FAString)
	
	If FAString <> Undefined Then
		Items.FAReferenceCalculationOfAccrualOfInterest.Enabled = 
				Not FAString.TheInterestAccrualScheduleIsEnteredManually;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ConfigureDependentFormElementsOnServer();
	
	LeasedAssetAccounting.FillInGraphFilledColumn(
		Object.FA,
		Object.ServicePaymentSchedule,
		Object.ServiceAccrualSchedule); 
	CalculateRateOfReturnOnServer(False, False);
	
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
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ContractDetails_", FormServiceParameters.ContractDetails_);
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_ChangesInTermsOfTransferForRent(
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
	
	If StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		SetFASelectionParameters();
	EndIf;
	
	If UpdateAll Then
		
		ListOfAgreements = New Array;
		GeneratedDocument = ValueIsFilled(Object.DocumentBasis);
		
		If GeneratedDocument Then
			
			Query = New Query;
			Query.Text = 
			"SELECT ALLOWED
			|	CounterpartyContracts.Ref AS Contract
			|FROM
			|	Catalog.CounterpartyContracts AS CounterpartyContracts
			|WHERE
			|	CounterpartyContracts.LeaseContracts = &LeaseContracts
			|	AND CounterpartyContracts.ContractType = VALUE(Enum.ContractTypes.Sublease)
			|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
			|	AND NOT CounterpartyContracts.DeletionMark";
			Query.SetParameter(
				"LeaseContracts", Common.ObjectAttributeValue(Object.DocumentBasis, "Contract"));
			ListOfAgreements = Query.Execute().Unload().UnloadColumn("Contract");
			
		EndIf;
		
		Items.Contract.ListChoiceMode = GeneratedDocument;
		Items.Contract.ChoiceList.LoadValues(ListOfAgreements);
		Items.Contract.CreateButton = Not GeneratedDocument;
		
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
Procedure CalculateRateOfReturnOnServer(RecalculatePercentages = True, OutputMessages = True)
	
	CalculationParameters =
		LeasedAssetAccounting.ParametersForCalculatingInterestRatesOfProfitableLeases(Object, FormServiceParameters.ContractDetails_);
	CalculationParameters.ShouldCalculatePercentage = RecalculatePercentages;
	CalculationParameters.OutputMessages = OutputMessages;
	
	LeasedAssetAccounting.CalculateInterestRatesOfProfitableRent(CalculationParameters);
	LeasedAssetAccounting.FillInRateOfReturnInterestChart(ThisObject, CalculationParameters, RecalculatePercentages);
	
EndProcedure

&AtServer
Function CalculateRateOfReturnOnServerInBackground(RecalculatePercentages = True, OutputMessages = True)
	
	CalculationParameters =
		LeasedAssetAccounting.ParametersForCalculatingInterestRatesOfProfitableLeases(Object, FormServiceParameters.ContractDetails_);
	CalculationParameters.ShouldCalculatePercentage = RecalculatePercentages;
	CalculationParameters.OutputMessages = OutputMessages;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tính lãi suất theo hợp đồng chuyển cho thuê';
														|ru = 'Расчет процентной ставки по договору передачи в аренду';
														|en = 'Calculation of the interest rate under the rental contract'; fa = 'Calculation of the interest rate under the rental contract';
														|it = 'Расчет процентной ставки по договору передачи в аренду';
														|pl = 'Calculation of the interest rate under the rental contract';
														|tr = 'Kira devir sözleşmesi kapsamında faiz oranının hesaplanması'");
	ExecutionParameters.WaitCompletion = 0;
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"LeasedAssetAccounting.CalculateRentalInterestRatesInBackground",
		CalculationParameters);
	
EndFunction

&AtClient
Procedure CalculateRateOfReturnCompletion(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult = Undefined Then
		Return;
	EndIf;
	CalculateRateOfReturnEndOnServer(ExecutionResult);
		
EndProcedure

&AtServer
Procedure CalculateRateOfReturnEndOnServer(ExecutionResult)
	
	CalculationResult2 = GetFromTempStorage(ExecutionResult.ResultAddress);
	
	If CalculationResult2 <> Undefined Then
		LeasedAssetAccounting.FillInRateOfReturnInterestChart(ThisObject, CalculationResult2, True);
	EndIf;
	For Each CollectionItem In ExecutionResult.Messages Do
		CollectionItem.Message();
	EndDo;
	
EndProcedure

&AtServer
Procedure WhenChangingFAOnServer()
	
	LeasedAssetAccounting.FillInGraphFilledColumn(
		Object.FA,
		Object.ServicePaymentSchedule,
		Object.ServiceAccrualSchedule);
	InterestScheduleUpdated = False;
	
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
	
	SetAvailabilityOfHelpPrinting(Items.FA.CurrentData);

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
			FillPropertyValues(FAString, RowData, "TheInterestAccrualScheduleIsEnteredManually, RentalEndDate");
		EndDo;
	EndDo;
	
	LeasedAssetAccounting.FillInGraphFilledColumn(
		Object.FA,
		Object.ServicePaymentSchedule,
		Object.ServiceAccrualSchedule);
	LeasedAssetAccounting.FillInAmountOfRentalPayments(
		Object,
		FormServiceParameters.ContractDetails_.ARAPCurrency);
	InterestScheduleUpdated = False;
	
EndProcedure

&AtClient
Procedure FillInTheRentedOnesCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ClearMessages();
		FillWithRentedOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillWithRentedOnServer()

	If Not ValueIsFilled(Object.Contract) Or Not ValueIsFilled(Object.Organization) Then
		Return;
	EndIf;
	
	Documents.ChangeRentalTerms.FillInBasedOnAgreement(Object, Object.Contract);
	
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
	
	If GeneratedDocument And ValueIsFilled(Object.Contract) Then
		Object.Leaseholder = Common.ObjectAttributeValue(Object.Contract, "Counterparty");
	EndIf;
	FillWithRentedOnServer();
	AddContractDetailsToServiceParametersOfForm();
	ConfigureDependentFormElementsOnServer("Contract");
	
EndProcedure

&AtClient
Procedure ShowCalculation(FAString)
	
	If FAString.SettlementDetails = Undefined Then
		Return;
	EndIf;
	
	PaymentData = New Structure;
	PaymentData.Insert("SettlementDetails", FAString.SettlementDetails);
	PaymentData.Insert("DetailsType", "IUPA");
	
	OpenForm("Document.ProvideAssetsToLeasee2_4.Form.DrillDownForm",
				PaymentData,
				ThisObject,
				True,,,,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure SetFASelectionParameters()

	FAArray = LeasedAssetAccounting.LeasedFAUnderContract(Object.Contract, Object.Date);
	
	FASelectionOptions = New Array;
	
	ChoiceParameterFA = New ChoiceParameter("Filter.Ref", New FixedArray(FAArray));
	FASelectionOptions.Add(ChoiceParameterFA);
	
	Items.FAFixedAsset.ChoiceParameters = New FixedArray(FASelectionOptions);
	
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChangeCompletion(ClosingResult, AdditionalParameters) Export

	If ValueIsFilled(ClosingResult) Then
		Object.DocumentBasis = ClosingResult;
		GeneratedDocument = True;
	Else
		GeneratedDocument = False;
	EndIf;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		QueryText = NStr("vi = 'Điền chứng từ theo dữ liệu chứng từ cơ sở?';
						|ru = 'Заполнить документ по данным документа-основания?';
						|en = 'Fill in the document by base document data?'; fa = 'Fill in the document by base document data?';
						|it = 'Compilare il documento in base ai dati del documento principale?';
						|pl = 'Wypełnić dokument wg danych dokumentu-podstawy?';
						|tr = 'Belgeyi belge bazındaki verilere göre mi dolduruyorsunuz?'");
		CallbackDescription = New CallbackDescription("FillInAccordingToBaseEnd", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo); 
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAccordingToBaseEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInAccordingToBaseDataOnServer();
	EndIf;
			
EndProcedure

&AtServer
Procedure FillInAccordingToBaseDataOnServer()
	
	Documents.ChangeRentalTerms.FillInOnBasisOfRentalTermsADJUSTMENTChanges(Object, Object.DocumentBasis);
	ConfigureDependentFormElementsOnServer();
	
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
