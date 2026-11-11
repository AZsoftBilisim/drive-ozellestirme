
#Region Variables

&AtClient
Var PreviousValues;
&AtClient
Var KeyAttributes;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ThisIsReconciliationBetweenOrganizations = TypeOf(Object.Counterparty) = Type("CatalogRef.Companies");
	If Not ValueIsFilled(Object.ContactPerson) Then
		Object.ContactPerson = ?(
			ThisIsReconciliationBetweenOrganizations, 
			Catalogs.Users.EmptyRef(),
			Catalogs.ContactPersonsForPartners.EmptyRef());
	EndIf;
	FillInListOfCalculationTypesToSelect();
	
	SetConditionalAppearance();
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	Documents.ARAPReconciliation2_5_11.InitializeSettingsComposer(LinkerSelection, UUID);
	Try
		DocumentObject_ = FormAttributeToValue("Object");
		Filter_Settings = DocumentObject_.Filter_Settings.Get();
		If Filter_Settings = Undefined Then
			If Parameters.Property("CopyingValue") And ValueIsFilled(Parameters.CopyingValue) Then
				SettingsStorage = Common.ObjectAttributeValue(Parameters.CopyingValue,"Filter_Settings");
				Filter_Settings = SettingsStorage.Get();
			EndIf;
		EndIf;
	Except
		// We don't do anything. The selection settings are updated before recording.
	EndTry;
	If ValueIsFilled(Filter_Settings) Then
		DataCompositionClientServer.CopyElements(LinkerSelection.Settings.Filter, Filter_Settings.Filter);
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			Documents.ARAPReconciliation2_5_11.CompletePartnerSelectionByCounterparty(LinkerSelection.Settings.Filter, Object.Counterparty);
		EndIf;
	EndIf;
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	Items.CurrencyGroup_2.Visible = UseMultipleCurrencies;
	
	ShowSummaryRecords = True;
	Items.EmployeeInCharge_.ChoiceList.Add(Enums.PersonsResponsibleAndCompanies.Director);
	Items.EmployeeInCharge_.ChoiceList.Add(Enums.PersonsResponsibleAndCompanies.ChiefAccountant);
	Items.CounterpartyCompanyPersonResponsible.ChoiceList.Add(Enums.PersonsResponsibleAndCompanies.Director);
	Items.CounterpartyCompanyPersonResponsible.ChoiceList.Add(Enums.PersonsResponsibleAndCompanies.ChiefAccountant);
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	If Not ValueIsFilled(Object.Counterparty) Then
		Object.Counterparty = Catalogs.Counterparties.EmptyRef();
	EndIf;
	Items.DecorationCompany.Visible = UseMultipleCompanies;
	Items.Counterparty.ChooseType = UseMultipleCompanies;
	Items.ThisIsReconciliationBetweenOrganizations.Visible = UseMultipleCompanies;
	Items.DecorationCounterparty.Visible = Not UseMultipleCompanies;
	
	If Not ValueIsFilled(Object.Ref) Then
		FormItemsManagement();
		If Object.SummaryRecords.Count() > 0 Then
			ARAPAccountingClientServer.CalculateAttributesOfFinalRecordsForm(Object.SummaryRecords, Object.ThereAreDiscrepancies);
			ARAPAccountingClientServer.CalculateAttributesOfDetailedRecordsForm(Object.DetailedRecords, Object.ThereAreDiscrepancies);
			ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);
		EndIf;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	Partner = CounterpartySPartner(Object.Counterparty);
	ShowSummaryRecords = True;
	ThisIsReconciliationBetweenOrganizations = TypeOf(Object.Counterparty) = Type("CatalogRef.Companies");
	DocumentEDI = Undefined;
	DocumentParticipatesInFEA = DocumentEDI <> Undefined;
	FormItemsManagement();

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	

	ARAPAccountingClientServer.CalculateAttributesOfFinalRecordsForm(Object.SummaryRecords, Object.ThereAreDiscrepancies);
	ARAPAccountingClientServer.CalculateAttributesOfDetailedRecordsForm(Object.DetailedRecords, Object.ThereAreDiscrepancies);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	

	ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);
	StatusOnChangeClient();
	RecalculationOfResults = False;
	ShowSummaryRecordsOnChangeClient(RecalculationOfResults);
	InitializePreviousValues();
	KeyAttributes = "PaymentType_, Partner, Contract, ARAPObject";
	SetVisibilityOfKeyFieldsOfDetailedRecords(False);

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("CatalogRef.ContactPersonsForPartners") Then
		If CurrentItem <> Undefined Then
			If CurrentItem.Name = "ContactPerson" Then
				Object.ContactPerson = ValueSelected;
			ElsIf CurrentItem.Name = "FullNameOfCounterpartyExecutive" Then
				Object.FullNameOfCounterpartyExecutive = String(ValueSelected);
				FillPositionBySelectedValue(ValueSelected)
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	CurrentObject.Filter_Settings = New ValueStorage(LinkerSelection.GetSettings());
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	If Not ShowSummaryRecords Then
		CalculateTotalsOfTotalRecordsOnServer();
	EndIf;

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	
	DocumentEDI = Undefined;
	DocumentParticipatesInFEA = DocumentEDI <> Undefined;

	SetAvailabilityOfItemsByStatus();
	ARAPAccountingClientServer.CalculateAttributesOfFinalRecordsForm(Object.SummaryRecords, Object.ThereAreDiscrepancies);
	ARAPAccountingClientServer.CalculateAttributesOfDetailedRecordsForm(Object.DetailedRecords, Object.ThereAreDiscrepancies);
	
	UnlockFormDataForEdit();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	

	SetSelectionOfFinalRecords();
	SetSelectionOfDetailedRecords();
	SetExplanatoryStatusLabel();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CounterpartyOnChange(Item)

	If Not ValueIsFilled(Object.Counterparty) Then
		Return;
	EndIf;  
	KeyAttributesWhenChanging("Counterparty");
	
EndProcedure

&AtClient
Procedure ThisIsReconciliationBetweenOrganizationsOnChange(Item)
	
	If TypeOf(Object.Counterparty) = Type("CatalogRef.Counterparties") Then
		PreviousValues.ExternalCounterparty_ = Object.Counterparty;
	ElsIf TypeOf(Object.Counterparty) = Type("CatalogRef.Companies") Then
		PreviousValues.CounterpartyIsOurCompany = Object.Counterparty;
	EndIf;
	
	KeyAttributesWhenChanging("ThisIsReconciliationBetweenOrganizations");
	
EndProcedure

&AtClient
Procedure ReconciliationInCurrencyOnChange(Item)

	Items.Currency.ReadOnly = Not Object.ReconciliationInCurrency;
	If Not Object.ReconciliationInCurrency And Object.Currency <> CurrencyOfComplianceAccounting Then
		KeyAttributesWhenChanging("ReconciliationInCurrency");
	EndIf;

EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)

	KeyAttributesWhenChanging("Currency");

EndProcedure

&AtClient
Procedure ContactPersonStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not ThisIsReconciliationBetweenOrganizations Then
		StandardProcessing = False;
		ManagerSFullNameContactPersonStartOfSelection();
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	StatusOnChangeClient();
	
EndProcedure

&AtClient
Procedure FullNameOfCounterpartyExecutiveStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ManagerSFullNameContactPersonStartOfSelection();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	KeyAttributesWhenChanging("Organization");
	
EndProcedure

&AtClient
Procedure EmployeeInCharge_OnChange(Item)
	
	ShowChiefAccountant = Object.EmployeeInCharge_ = PredefinedValue("Enum.PersonsResponsibleAndCompanies.ChiefAccountant");
	Items.ChiefAccountant.Visible = ShowChiefAccountant;
	Items.Director.Visible = Not Items.ChiefAccountant.Visible;
	
EndProcedure

&AtClient
Procedure CounterpartyCompanyPersonResponsibleOnChange(Item)
	
	ShowChiefAccountant = Object.CounterpartyCompanyPersonResponsible = PredefinedValue("Enum.PersonsResponsibleAndCompanies.ChiefAccountant");
	Items.ChiefAccountantOfCounterpartyCompany.Visible = ShowChiefAccountant;
	Items.CounterpartyCompanyManager.Visible = Not Items.ChiefAccountantOfCounterpartyCompany.Visible;
	
EndProcedure

&AtClient
Procedure ThereAreDiscrepanciesOnChange(Item)

	SetVisibility1();
	ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);

	If Not DocumentParticipatesInFEA And Object.ThereAreDiscrepancies Then
		For Each FinalRecord In Object.SummaryRecords Do
			If Not FinalRecord.ThereIsDataOfCounterparty Then
				FinalRecord.OpeningBalanceDrCounterparty = FinalRecord.OpeningBalanceDr;
				FinalRecord.OpeningBalanceCrCounterparty = FinalRecord.OpeningBalanceCr;
				FinalRecord.TurnoverDrCounterparty = FinalRecord.TurnoverDr;
				FinalRecord.TurnoverCrCounterparty = FinalRecord.TurnoverCr;
				FinalRecord.ClosingBalanceDrCounterparty = FinalRecord.ClosingBalanceDr;
				FinalRecord.ClosingBalanceCrCounterparty = FinalRecord.ClosingBalanceCr;
				FinalRecord.ContractNumberCounterparty = FinalRecord.ContractNumber;
				FinalRecord.ContractDateCounterparty = FinalRecord.ContractDate_;
				FinalRecord.ContractNameCounterparty = FinalRecord.ContractName;
				FinalRecord.ThereIsDataOfCounterparty = True;
			EndIf;
		EndDo;
		For Each DetailRecord In Object.DetailedRecords Do
			If Not DetailRecord.ThereIsDataOfCounterparty Then
				DetailRecord.AmountDebitCounterparty = DetailRecord.DebitAmount;
				DetailRecord.AmountCreditCounterparty = DetailRecord.LoanAmount_;
				DetailRecord.IncomingNumberCounterparty = DetailRecord.DocumentNumber;
				DetailRecord.DocumentDateCounterparty = DetailRecord.DocumentDate;
				DetailRecord.DocumentNameCounterparty = DetailRecord.DocumentName3;
				DetailRecord.ThereIsDataOfCounterparty = True;
			EndIf;
		EndDo;
	EndIf;

	ARAPAccountingClientServer.CalculateAttributesOfFinalRecordsForm(Object.SummaryRecords, Object.ThereAreDiscrepancies);
	ARAPAccountingClientServer.CalculateAttributesOfDetailedRecordsForm(Object.DetailedRecords, Object.ThereAreDiscrepancies);

	MatchingFilterSummaryRecords = 0;
	SetSelectionOfFinalRecords();
	MatchingFilterDetailedRecords = 0;
	SetSelectionOfDetailedRecords();

EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure DecorationExplanatoryInscriptionURLProcessing(Item, FormattedStringURL, StandardProcessing)

	StandardProcessing = False;
	SetReconciliationStatus(FormattedStringURL);
	Modified = True;

EndProcedure

&AtClient
Procedure ModeOfARAPTotalsReconciliationOnChange(Item)

	KeyAttributesWhenChanging("ModeOfARAPTotalsReconciliation");

EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.PageSettlements Then
		ShowSummaryRecordsOnChangeClient();
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowSummaryRecordsOnChange(Item)
	
	ShowSummaryRecordsOnChangeClient();
	
EndProcedure

&AtClient
Procedure FilterCalculationsClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterCalculations = -1;
	
	ShowInformationOnSelectionOfCalculations();
	SetSelectionOfDetailedRecords();
	SetVisibilityOfStringConcatenationCommands();
	OutputKeyFields();
	
EndProcedure

&AtClient
Procedure FilterCalculationsOnChange(Item)
	
	ShowInformationOnSelectionOfCalculations();
	SetSelectionOfDetailedRecords();
	SetVisibilityOfStringConcatenationCommands();
	OutputKeyFields();
	
EndProcedure

&AtClient
Procedure DescriptionOfOutgoingDocumentsOnChange(Item)
	KeyAttributesWhenChanging("DescriptionOfOutgoingDocuments");
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSummaryRecords

&AtClient
Procedure FinalRecordsAreObjectOfCalculationsARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	Cancel = False;
	If Not ValueIsFilled(Object.Organization) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
				|ru = 'Поле ""Организация"" не заполнено';
				|en = 'The ""Company"" field is required'; fa = 'The ""Company"" field is required';
				|it = 'Поле ""Организация"" не заполнено';
				|pl = 'Nie wypełniono pola ""Firma""';
				|tr = '""İş yeri"" alanı doldurulmadı'"),
			,
			"Organization",
			"Object",
			Cancel);
	EndIf;
	If Not ValueIsFilled(Object.Counterparty) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Đối tác""';
				|ru = 'Поле ""Контрагент"" не заполнено';
				|en = 'The ""Counterparty"" field is required'; fa = 'The ""Counterparty"" field is required';
				|it = 'Поле ""Контрагент"" не заполнено';
				|pl = 'Pole ""Kontrahent"" nie jest wypełnione';
				|tr = '""Cari hesap"" alanı doldurulmadı'"),
			,
			"Counterparty",
			"Object",
			Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	CurrentRow = Items.SummaryRecords.CurrentData;
	PaymentType_ = CurrentRow.PaymentType_;
	Filter = SelectingContractSearch();
	If PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting")
			Or PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting") Then
		OpenForm(
			"Catalog.LoanAndDepositContracts.ChoiceForm",
			New Structure("Filter", Filter),
			Item);
	ElsIf PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor") Then
		OpenForm(
			"Catalog.LeaseContract.ChoiceForm",
			New Structure("Filter", Filter),
			Item);
	Else
		FilterValues = New Structure;
		FilterValues.Insert("PaymentType_", CurrentRow.PaymentType_);
		FilterValues.Insert("Organization", Object.Organization);
		FilterValues.Insert("Counterparty",  Object.Counterparty);
		FilterValues.Insert("PaymentsAsPer275FZ" , False);

		If TypeOf(FilterValues.Counterparty) = Type("CatalogRef.Companies") Then
			FilterValues.Insert("Partner", PredefinedValue("Catalog.Partners.OurEnterprise"));
		Else
			FilterValues.Insert("Partner", CurrentRow.Partner);
		EndIf;

		SelectionSettings_ = New Structure;
		SelectionSettings_.Insert("SelectingThePaymentBasis", False);
		SelectionSettings_.Insert("EditableDocument", Object.Ref);
		SelectionSettings_.Insert("Sum", 0);
		SelectionSettings_.Insert("Filter", FilterValues);
		SelectionSettings_.Insert("SelectAccountsReceivable", True);
		SelectionSettings_.Insert("ReturnStructure", True);
		SelectionSettings_.Insert("CurrentRow", CurrentRow.ARAPObject);

		OpenForm("Catalog.ARAPObjects.ChoiceForm", SelectionSettings_, Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FinalRecordsAreObjectOfCalculationsARAPObjectChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.SummaryRecords.CurrentData;
	If TypeOf(ValueSelected) = Type("Structure") Then
		CurrentData.ARAPObject = ValueSelected.ARAPObject;
		CurrentData.Partner = ValueSelected.Partner;
		CurrentData.Contract = ValueSelected.Contract;
		CurrentData.Currency = ValueSelected.ARAPCurrency;
	Else
		CurrentData.ARAPObject = ValueSelected;
		CurrentData.Contract = ValueSelected;
	EndIf;
	
EndProcedure

&AtClient
Procedure SummaryRecordsOnStartEdit(Item, NewRow, Copy)

	If Object.SplitByARAPTypes And Not ValueIsFilled(Item.CurrentData.PaymentType_) Then
		Item.CurrentData.PaymentType_ = Object.PaymentType_;
	ElsIf Object.SplitByContracts And Not ValueIsFilled(Item.CurrentData.Contract) Then
		Item.CurrentData.Contract = Object.Contract;
	ElsIf Object.SplitByPartners And Not ValueIsFilled(Item.CurrentData.Partner) Then
		Item.CurrentData.Partner = Object.Partner;
	EndIf;
	FillPropertyValues(PreviousValues, Item.CurrentData, KeyAttributes);

EndProcedure

&AtClient
Procedure SummaryRecordsBeforeDeleteRow(Item, Cancel)

	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	Cancel = True;
	// When using Asyncs for the procedure of the event itself, the Failure = True is ignored and the lines are immediately deleted
	DeleteFinalRecordsAsyncs();

EndProcedure

&AtClient
Async Procedure SummaryRecordsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)

	If CancelEdit Or Cancel Then
		Return;
	EndIf;

	// checking for duplicates based on the Cur values of key Attributes
	FilterParameters = New Structure(KeyAttributes);
	FillPropertyValues(FilterParameters, Item.CurrentData, KeyAttributes);
	RowsSet = Object.SummaryRecords.FindRows(FilterParameters);
	
	ReconciliationUnderContracts = Object.ModeOfARAPTotalsReconciliation = PredefinedValue("Enum.ModeOfARAPTotalsReconciliation.ByContracts");
	If ReconciliationUnderContracts Then
		MessageTextTemplate = NStr("vi = 'Bản ghi có các giá trị như vậy của nút chính ""Kiểu hạch toán"", ""Bạn hàng"" và ""Hợp đồng"" đã tồn tại (dòng số %1). Giá trị trường chính cần phải khác nhau.';
									|ru = 'Запись с такими значениями ключевых полей ""Тип расчетов"", ""Партнер"" и ""Договор"" уже существует (строка № %1). Значения ключевых полей должны отличаться.';
									|en = 'A record with such values of the ""Payment type"", ""Partner"", and ""Contract"" key fields already exists (line %1). Key field values must differ.'; fa = 'A record with such values of the ""Payment type"", ""Partner"", and ""Contract"" key fields already exists (line %1). Key field values must differ.';
									|it = 'Запись с такими значениями ключевых полей ""Тип расчетов"", ""Партнер"" и ""Договор"" уже существует (строка № %1). Значения ключевых полей должны отличаться.';
									|pl = 'A record with such values of the ""Payment type"", ""Partner"", and ""Contract"" key fields already exists (line %1). Key field values must differ.';
									|tr = '""Alacak/Borç muhasebesi tipi"", ""İş ortağı"" ve ""Sözleşme"" anahtar alanlarının bu değerlerine sahip kaydı zaten mevcut (satır no. %1). Anahtar alanların değerleri farklı olmalıdır.'");
	Else
		MessageTextTemplate = NStr("vi = 'Bản ghi có các giá trị như vậy của các trường khóa ""Kiểu hạch toán"", ""Bạn hàng"", ""Hợp đồng"" và ""Đối tượng hạch toán"" đã tồn tại (dòng số %1). Các giá trị của trường khóa phải khác nhau.';
									|ru = 'Запись с такими значениями ключевых полей ""Тип расчетов"", ""Партнер"", ""Договор"" и ""Объект расчетов"" уже существует (строка № %1). Значения ключевых полей должны отличаться.';
									|en = 'A record with such values of the ""Payment type"", ""Partner"", ""Contract"", and ""AR/AP object"" key fields already exists (line %1). Key field values must differ.'; fa = 'A record with such values of the ""Payment type"", ""Partner"", ""Contract"", and ""AR/AP object"" key fields already exists (line %1). Key field values must differ.';
									|it = 'Запись с такими значениями ключевых полей ""Тип расчетов"", ""Партнер"", ""Договор"" и ""Объект расчетов"" уже существует (строка № %1). Значения ключевых полей должны отличаться.';
									|pl = 'A record with such values of the ""Payment type"", ""Partner"", ""Contract"", and ""AR/AP object"" key fields already exists (line %1). Key field values must differ.';
									|tr = '""Alacak/Borç muhasebesi tipi"", ""İş ortağı"" ve ""Alacak/Borç nesnesi"" anahtar alanlarının bu değerlerine sahip kaydı zaten mevcut (satır no. %1). Anahtar alanların değerleri farklı olmalıdır.'");
	EndIf;
	For Each FinalRecord In RowsSet Do
		If FinalRecord <> Item.CurrentData Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTextTemplate,
				FinalRecord.LineNumber);
			CommonClient.MessageToUser(MessageText,,
				StringFunctionsClientServer.SubstituteParametersToString("SummaryRecords[%1]",
					Format(Object.SummaryRecords.IndexOf(FinalRecord), "NZ=0; NG=")),
				"Object",
				Cancel);
		EndIf;
	EndDo;

	If Cancel Then
		Return;
	EndIf;

	// checking the availability of detailed records for previous values of key Attributes
	If Not ValueIsFilled(PreviousValues.PaymentType_) Then	// New or unmapped string
		Return;
	EndIf;

	FilterParameters = New Structure(KeyAttributes);
	FillPropertyValues(FilterParameters, PreviousValues, KeyAttributes);

	HasChanges = False;
	For Each KeyAttribute In FilterParameters Do
		If Item.CurrentData[KeyAttribute.Key] <> KeyAttribute.Value Then
			If ValueIsFilled(Item.CurrentData[KeyAttribute.Key])	// warning comparing empty reference and undefined in Contract
				Or ValueIsFilled(KeyAttribute.Value) Then
				HasChanges = True;
				Break;
			EndIf;
		EndIf;
	EndDo;

	If Not HasChanges Then	// The key fields have not been changed
		Return;
	EndIf;

	RowsSet = Object.DetailedRecords.FindRows(FilterParameters);
	If RowsSet.Count() = 0 Then	// There are no subordinate detailed records
		Return;
	EndIf;

	// Either return the values, or delete the details.
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã thay đổi các giá trị của trường khóa.
		|Các bản ghi chi tiết trực thuộc (%1) sẽ bị xóa.
		|Tiếp nhận?';
		|ru = 'Были изменены значения ключевых полей.
		|Подчиненные детальные записи (%1) будут удалены.
		|Продолжить?';
		|en = 'Key field values were changed.
		|Subordinate detailed records (%1) will be deleted.
		|Continue?'; fa = 'Key field values were changed.
		|Subordinate detailed records (%1) will be deleted.
		|Continue?';
		|it = 'Были изменены значения ключевых полей.
		|Подчиненные детальные записи (%1) будут удалены.
		|Продолжить?';
		|pl = 'Key field values were changed.
		|Subordinate detailed records (%1) will be deleted.
		|Continue?';
		|tr = 'Anahtar alanların değerleri değiştirildi.
		|Alt ayrıntılı kayıtlar (%1) silinecektir.
		|Devam edilsin mi?'"),
		RowsSet.Count());
		
	Response = Await DoQueryBoxAsync(QueryText,
					QuestionDialogMode.YesNo,
					,
					DialogReturnCode.No,
					NStr("vi = 'Thay đổi trường chính';
						|ru = 'Изменение ключевых полей';
						|en = 'Edit key fields'; fa = 'Edit key fields';
						|it = 'Изменение ключевых полей';
						|pl = 'Edit key fields';
						|tr = 'Anahtar alan değişikliği'"));
	If Response = DialogReturnCode.Yes Then // Delete lines
		For Each DetailRecord In RowsSet Do
			Object.DetailedRecords.Delete(DetailRecord);
		EndDo;
	Else // Roll back field values
		FillPropertyValues(Items.SummaryRecords.CurrentData, PreviousValues, KeyAttributes);
	EndIf;
	
EndProcedure

&AtClient
Procedure SummaryRecordsOnChange(Item)

	CurrentData = Items.SummaryRecords.CurrentData;
	If CurrentData = Undefined Then	// Deleting an entry
		Return;
	EndIf;
	If Not ValueIsFilled(CurrentData.Contract) Then
		CurrentData.Contract = Undefined;
	EndIf;

	ARAPAccountingClientServer.CalculateAttributesOfFinalRecordsForm(Object.SummaryRecords, Object.ThereAreDiscrepancies, CurrentData);
	ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);
	
EndProcedure

&AtClient
Procedure SummaryRecordsAfterDeleteRow(Item)
	
	ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);
	
EndProcedure

&AtClient
Procedure FinalEntriesContractOnChange(Item)
	
	CurrentRow = Items.SummaryRecords.CurrentData;
	PaymentType_ = CurrentRow.PaymentType_;
	If Not ValueIsFilled(CurrentRow.Contract)
		And (PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting")
			Or PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting")
			Or PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor")) Then
		CurrentRow.ARAPObject = Undefined;
	EndIf;
	
	If ValueIsFilled(CurrentRow.Contract) Then
		ContractDetails_ = ContractDetails_Server(CurrentRow.Contract);
		CurrentRow.ContractName = ContractDetails_.NameForPrinting;
		CurrentRow.ContractNumber = ContractDetails_.Number;
		CurrentRow.ContractDate_ = ContractDetails_.Date;
	Else
		CurrentRow.ContractName = "";
		CurrentRow.ContractNumber = "";
		CurrentRow.ContractDate_ = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure FinalEntriesContractStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	ContractStartChoice(Item);
EndProcedure

&AtClient
Procedure FinalEntriesContractChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	
	PaymentType_ = Item.Parent.CurrentData.PaymentType_;
	If PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting")
		Or PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting")
		Or PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor") Then
		Items.SummaryRecords.CurrentData.ARAPObject = ValueSelected;
	EndIf;
	
EndProcedure

&AtClient
Procedure FinalEntriesContractAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)

	DataGetParameters.Filter = SelectingContractSearch();

EndProcedure

&AtClient
Procedure FinalEntriesContractTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)

	DataGetParameters.Filter = SelectingContractSearch();

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDetailedRecords

&AtClient
Procedure DetailedRecordsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)

	If FilterCalculations = -1 Then
		ClearMessages();
		MessageText = NStr("vi = 'Chỉ có thể thêm dòng chỉ khi lọc được thiết lập theo bản ghi tổng số.';
							|ru = 'Добавление строк возможно только при установленном отборе по итоговой записи.';
							|en = 'You can only add rows if the filter by summary record is set.'; fa = 'You can only add rows if the filter by summary record is set.';
							|it = 'Добавление строк возможно только при установленном отборе по итоговой записи.';
							|pl = 'You can only add rows if the filter by summary record is set.';
							|tr = 'Satır eklemek sadece toplam kayda göre filtre yapılandırıldığında mümkündür.'");
		CommonClient.MessageToUser(MessageText,,,,Cancel);
	EndIf;
	
	ThisIsNewLineOfDetailedRecords = True;

EndProcedure

&AtClient
Procedure DetailedRecordsOnActivateRow(Item)

	If ThisIsNewLineOfDetailedRecords And FilterCalculations <> Undefined Then
		FinalRecord = LineOfFinalRecordForSelectionOfCalculations();
		If FinalRecord <> Undefined And Item.CurrentData <> Undefined Then
			FillPropertyValues(Item.CurrentData, FinalRecord, KeyAttributes);
			Item.CurrentData.DocumentCurrency = Object.Currency;
		EndIf;
		ThisIsNewLineOfDetailedRecords = False;
	EndIf;

EndProcedure

&AtClient
Procedure DetailedRecordsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentRow = Items.DetailedRecords.CurrentData;
	If CurrentRow = Undefined Or CancelEdit Then
		Return;
	EndIf;
	
	ARAPAccountingClientServer.CalculateAttributesOfDetailedRecordsForm(Object.DetailedRecords, Object.ThereAreDiscrepancies, CurrentRow);
	ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);
	SetSelectionOfDetailedRecords();
	CalculateTotalsOfTotalRecordsOnServer();
	
EndProcedure

&AtClient
Procedure DetailedRecordsAfterDeleteRow(Item)
	
	FinalRecord = LineOfFinalRecordForSelectionOfCalculations();
	If FinalRecord <> Undefined Then
		ARAPAccountingClientServer.CalculateAttributesOfFinalRecordsForm(Object.SummaryRecords, Object.ThereAreDiscrepancies, FinalRecord);
	EndIf;
	
	ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);
	
EndProcedure

&AtClient
Procedure DetailedRecordsOfARAPDocumentOnChange(Item)
	
	CurrentRow = Items.DetailedRecords.CurrentData;
	If Not ValueIsFilled(CurrentRow.ARAPDocument) Then
		Return;
	EndIf;
	If Not ValueIsFilled(CurrentRow.PaymentType_) Then
		FillPropertyValues(CurrentRow, Items.DetailedRecords.RowFilter);
	EndIf;
	
	FoundRow = Undefined;
	Filter = New Structure("ARAPDocument", CurrentRow.ARAPDocument);
	DocumentRows = Object.DetailedRecords.FindRows(Filter);
	If DocumentRows.Count() = 2 Then
		For Each String In DocumentRows Do
			If String.LineNumber = CurrentRow.LineNumber Then
				Continue;
			EndIf;
			FoundRow = String;
		EndDo;
	ElsIf DocumentRows.Count() > 2 Then
		CurrentRow.ARAPDocument = Undefined;
	EndIf;

	If FoundRow = Undefined Then
		Return;
	EndIf;

	If CurrentRow.ThereIsDataOfCounterparty = (Not FoundRow.ThereIsDataOfCounterparty) Then
		RowOfCounterparty = CurrentRow;
		OrganizationString = FoundRow;
		ListOfProperties = "IncomingNumberCounterparty, DocumentDateCounterparty, DocumentNameCounterparty,
		|AmountDebitCounterparty, AmountCreditCounterparty";
		FillPropertyValues(OrganizationString, RowOfCounterparty, ListOfProperties);
		Object.DetailedRecords.Delete(Object.DetailedRecords.IndexOf(RowOfCounterparty));
	Else
		CurrentRow.ARAPDocument = Undefined;
	EndIf;

	ARAPAccountingClientServer.CalculateAttributesOfDetailedRecordsForm(Object.DetailedRecords, Object.ThereAreDiscrepancies, OrganizationString);
	ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	FillInSelectionBalance();
	
EndProcedure

&AtClient
Procedure AdvancedFilter(Command)
	
	OpeningParameters = ParametersOfExtendedSelectionForm();
	
	CloseHandler = New CallbackDescription("SetAdvancedSelectionCompletion", ThisObject);
	OpenForm("Document.ARAPReconciliation2_5_11.Form.AdvancedFilter",
				OpeningParameters,
				ThisObject,
				,
				,
				,
				CloseHandler,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"));
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure PreviousSelectionValue(Command)
	
	FilterValuesList = Items.FilterCalculations.ChoiceList;
	If FilterValuesList.Count() < 2 Then
		Return;
	EndIf;
	
	CurSelectionElement = FilterValuesList.FindByValue(FilterCalculations);
	If CurSelectionElement = Undefined Then
		Return;
	EndIf;
	
	ElementIndex = FilterValuesList.IndexOf(CurSelectionElement);
	If ElementIndex > 0 Then
		FilterCalculations = FilterValuesList.Get(ElementIndex - 1).Value;
	EndIf;
	
	FilterCalculationsOnChangeClient();
	
EndProcedure

&AtClient
Procedure FollowingSelectionValue(Command)

	FilterValuesList = Items.FilterCalculations.ChoiceList;
	If FilterValuesList.Count() < 2 Then
		Return;
	EndIf;

	CurSelectionElement = FilterValuesList.FindByValue(FilterCalculations);
	If CurSelectionElement = Undefined Then
		Return;
	EndIf;

	ElementIndex = FilterValuesList.IndexOf(CurSelectionElement);
	If ElementIndex < FilterValuesList.Count() - 1 Then
		FilterCalculations = FilterValuesList.Get(ElementIndex + 1).Value;
	EndIf;
	
	FilterCalculationsOnChangeClient();
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure MergeRowsSummaryRecords(Command)

	ClearMessages();

	SelectedRows = Items.SummaryRecords.SelectedRows;

	ErrorMessageText = NStr("vi = 'Để hợp nhất, cần chọn hai dòng chưa so sánh: chỉ có dữ liệu của một bên và chỉ có dữ liệu của bên thứ hai.';
							|ru = 'Для объединения необходимо выделить две несопоставленные строки: с данными только одной стороны и с данными только второй стороны.';
							|en = 'To merge lines, select two unmapped lines: a line with one party''s data and a line with the other party''s data.'; fa = 'To merge lines, select two unmapped lines: a line with one party''s data and a line with the other party''s data.';
							|it = 'Для объединения необходимо выделить две несопоставленные строки: с данными только одной стороны и с данными только второй стороны.';
							|pl = 'To merge lines, select two unmapped lines: a line with one party''s data and a line with the other party''s data.';
							|tr = 'Birleştirmek için eşleşmeyen iki satırı seçmeniz gerekmektedir: Sadece bir taraftaki verilere sahip ve sadece ikinci taraftaki verilere sahip.'");
	If SelectedRows.Count() <> 2 Then
		CommonClient.MessageToUser(ErrorMessageText,, "Object.SummaryRecords", "Object");
		Return;
	EndIf;

	FirstRow = Object.SummaryRecords.FindByID(SelectedRows[0]);
	SecondLine = Object.SummaryRecords.FindByID(SelectedRows[1]);

	If FirstRow.TypeOfDiscrepancies <> 1
		Or SecondLine.TypeOfDiscrepancies <> 1
		Or FirstRow.ThereIsDataOfCounterparty = SecondLine.ThereIsDataOfCounterparty
		Or FirstRow.ThereIsOrganizationData = SecondLine.ThereIsOrganizationData
		Or FirstRow.ThereIsDataOfCounterparty = FirstRow.ThereIsOrganizationData Then
		CommonClient.MessageToUser(ErrorMessageText,, "Object.SummaryRecords", "Object");
		Return;
	EndIf;

	If FirstRow.ThereIsDataOfCounterparty Then
		RowOfCounterparty = FirstRow;
		OrganizationString = SecondLine;
	Else
		RowOfCounterparty = SecondLine;
		OrganizationString = FirstRow;
	EndIf;

	ListOfProperties = "OpeningBalanceDrCounterparty, OpeningBalanceCrCounterparty,
		|TurnoverDrCounterparty, TurnoverCrCounterparty, ClosingBalanceDrCounterparty, ClosingBalanceCrCounterparty,
		|ContractNumberCounterparty, ContractDateCounterparty, ContractNameCounterparty";
	FillPropertyValues(OrganizationString, RowOfCounterparty, ListOfProperties);

	Object.SummaryRecords.Delete(Object.SummaryRecords.IndexOf(RowOfCounterparty));

	ARAPAccountingClientServer.CalculateAttributesOfFinalRecordsForm(Object.SummaryRecords, Object.ThereAreDiscrepancies, OrganizationString);
	ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);

EndProcedure

&AtClient
Procedure MergeRowsOfDetailedRecords(Command)

	ClearMessages();

	SelectedRows = Items.DetailedRecords.SelectedRows;

	ErrorMessageText = NStr("vi = 'Để hợp nhất, cần chọn hai dòng chưa so sánh: chỉ có dữ liệu của một bên và chỉ có dữ liệu của bên thứ hai.';
							|ru = 'Для объединения необходимо выделить две несопоставленные строки: с данными только одной стороны и с данными только второй стороны.';
							|en = 'To merge lines, select two unmapped lines: a line with one party''s data and a line with the other party''s data.'; fa = 'To merge lines, select two unmapped lines: a line with one party''s data and a line with the other party''s data.';
							|it = 'Для объединения необходимо выделить две несопоставленные строки: с данными только одной стороны и с данными только второй стороны.';
							|pl = 'To merge lines, select two unmapped lines: a line with one party''s data and a line with the other party''s data.';
							|tr = 'Birleştirmek için eşleşmeyen iki satırı seçmeniz gerekmektedir: Sadece bir taraftaki verilere sahip ve sadece ikinci taraftaki verilere sahip.'");
	If SelectedRows.Count() <> 2 Then
		CommonClient.MessageToUser(ErrorMessageText,, "Object.DetailedRecords", "Object");
		Return;
	EndIf;

	FirstRow = Object.DetailedRecords.FindByID(SelectedRows[0]);
	SecondLine = Object.DetailedRecords.FindByID(SelectedRows[1]);

	If FirstRow.TypeOfDiscrepancies <> 1
		Or SecondLine.TypeOfDiscrepancies <> 1
		Or FirstRow.ThereIsDataOfCounterparty = SecondLine.ThereIsDataOfCounterparty
		Or FirstRow.ThereIsOrganizationData = SecondLine.ThereIsOrganizationData
		Or FirstRow.ThereIsDataOfCounterparty = FirstRow.ThereIsOrganizationData Then
		CommonClient.MessageToUser(ErrorMessageText,, "Object.DetailedRecords", "Object");
		Return;
	EndIf;

	If FirstRow.ThereIsDataOfCounterparty Then
		RowOfCounterparty = FirstRow;
		OrganizationString = SecondLine;
	Else
		RowOfCounterparty = SecondLine;
		OrganizationString = FirstRow;
	EndIf;

	ListOfProperties = "IncomingNumberCounterparty, DocumentDateCounterparty, DocumentNameCounterparty,
	|AmountDebitCounterparty, AmountCreditCounterparty";
	FillPropertyValues(OrganizationString, RowOfCounterparty, ListOfProperties);

	Object.DetailedRecords.Delete(Object.DetailedRecords.IndexOf(RowOfCounterparty));

	ARAPAccountingClientServer.CalculateAttributesOfDetailedRecordsForm(Object.DetailedRecords, Object.ThereAreDiscrepancies, OrganizationString);
	ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);

EndProcedure

&AtClient
Procedure DisconnectSummaryRecordsLine(Command)

	ClearMessages();

	SelectedRows = Items.SummaryRecords.SelectedRows;
	OrganizationString = Items.SummaryRecords.CurrentData;
	If SelectedRows.Count() <> 1
		Or Not OrganizationString.ThereIsOrganizationData
		Or Not OrganizationString.ThereIsDataOfCounterparty Then
		ErrorMessageText = NStr("vi = 'Để chia tách, cần chọn một dòng chưa so sánh.';
								|ru = 'Для разделения необходимо выделить одну сопоставленную строку.';
								|en = 'To split lines, select one mapped line.'; fa = 'To split lines, select one mapped line.';
								|it = 'Для разделения необходимо выделить одну сопоставленную строку.';
								|pl = 'To split lines, select one mapped line.';
								|tr = 'Ayırmak için eşleşen bir satırı seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(ErrorMessageText,, "Object.SummaryRecords", "Object");
		Return;
	EndIf;

	SelectedRow = Object.SummaryRecords.FindByID(SelectedRows[0]);
	IndexOfSelectedRow = Object.SummaryRecords.IndexOf(SelectedRow);
	RowOfCounterparty = Object.SummaryRecords.Insert(IndexOfSelectedRow);

	ListOfProperties = "OpeningBalanceDrCounterparty,OpeningBalanceCrCounterparty,TurnoverDrCounterparty,TurnoverCrCounterparty,ClosingBalanceDrCounterparty,ClosingBalanceCrCounterparty,ContractNumberCounterparty,ContractDateCounterparty,ContractNameCounterparty";
	FillPropertyValues(RowOfCounterparty, OrganizationString, "Currency," + ListOfProperties);

	TMCommonUseClientServer.ClearPropertyValues(OrganizationString, ListOfProperties);

	ARAPAccountingClientServer.CalculateAttributesOfFinalRecordsForm(Object.SummaryRecords, Object.ThereAreDiscrepancies, OrganizationString);
	ARAPAccountingClientServer.CalculateAttributesOfFinalRecordsForm(Object.SummaryRecords, Object.ThereAreDiscrepancies, RowOfCounterparty);
	ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);

EndProcedure

&AtClient
Procedure DisconnectLineDetailedRecords(Command)

	ClearMessages();

	SelectedRows = Items.DetailedRecords.SelectedRows;
	OrganizationString = Items.DetailedRecords.CurrentData;
	If SelectedRows.Count() <> 1
		Or Not OrganizationString.ThereIsOrganizationData
		Or Not OrganizationString.ThereIsDataOfCounterparty Then
		ErrorMessageText = NStr("vi = 'Để chia tách, cần chọn một dòng đã so sánh.';
								|ru = 'Для разделения необходимо выделить одну сопоставленную строку.';
								|en = 'To split lines, select one mapped line.'; fa = 'To split lines, select one mapped line.';
								|it = 'Для разделения необходимо выделить одну сопоставленную строку.';
								|pl = 'To split lines, select one mapped line.';
								|tr = 'Ayırmak için eşleşen bir satırı seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(ErrorMessageText,, "Object.DetailedRecords", "Object");
		Return;
	EndIf;

	SelectedRow = Object.DetailedRecords.FindByID(SelectedRows[0]);
	IndexOfSelectedRow = Object.DetailedRecords.IndexOf(SelectedRow);
	RowOfCounterparty = Object.DetailedRecords.Insert(IndexOfSelectedRow);

	StringOwnerProperties = "PaymentType_,Partner,ARAPObject,Contract,";
	ListOfProperties = "IncomingNumberCounterparty,DocumentDateCounterparty,DocumentNameCounterparty,AmountDebitCounterparty,AmountCreditCounterparty";
	FillPropertyValues(RowOfCounterparty, OrganizationString, "DocumentCurrency," + StringOwnerProperties + ListOfProperties);

	TMCommonUseClientServer.ClearPropertyValues(OrganizationString, ListOfProperties);

	ARAPAccountingClientServer.CalculateAttributesOfDetailedRecordsForm(Object.DetailedRecords, Object.ThereAreDiscrepancies, OrganizationString);
	ARAPAccountingClientServer.CalculateAttributesOfDetailedRecordsForm(Object.DetailedRecords, Object.ThereAreDiscrepancies, RowOfCounterparty);
	ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);

EndProcedure

&AtClient
Procedure FilterMatchingAll(Command)

	If ShowSummaryRecords Then
		MatchingFilterSummaryRecords = 0;
		SetSelectionOfFinalRecords();
	Else
		MatchingFilterDetailedRecords = 0;
		SetSelectionOfDetailedRecords();
	EndIf;

EndProcedure

&AtClient
Procedure MatchingFilterUnmapped(Command)

	If ShowSummaryRecords Then
		MatchingFilterSummaryRecords = 1;
		SetSelectionOfFinalRecords();
	Else
		MatchingFilterDetailedRecords = 1;
		SetSelectionOfDetailedRecords();
	EndIf;

EndProcedure

&AtClient
Procedure DiscrepancyMatchingFilter(Command)

	If ShowSummaryRecords Then
		MatchingFilterSummaryRecords = 2;
		SetSelectionOfFinalRecords();
	Else
		MatchingFilterDetailedRecords = 2;
		SetSelectionOfDetailedRecords();
	EndIf;

EndProcedure

&AtClient
Procedure FilterDrCrAll(Command)

	FilterDrCr = 0;
	SetSelectionOfDetailedRecords();

EndProcedure

&AtClient
Procedure FilterDrCrDebit(Command)

	FilterDrCr = 1;
	SetSelectionOfDetailedRecords();

EndProcedure

&AtClient
Procedure FilterDrCrCredit(Command)

	FilterDrCr = 2;
	SetSelectionOfDetailedRecords();

EndProcedure

&AtClient
Procedure ShowKeyFieldsOfDetailedRecords(Command)
	
	SetVisibilityOfKeyFieldsOfDetailedRecords(True);
	
EndProcedure

&AtClient
Procedure HideKeyFieldsOfDetailedRecords(Command)
	
	SetVisibilityOfKeyFieldsOfDetailedRecords(False);
	
EndProcedure
#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure CounterpartyOnChangeServer()
	
	Partner = CounterpartySPartner(Object.Counterparty);
	
	Object.CounterpartyCompanyManager = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
	Object.ChiefAccountantOfCounterpartyCompany = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
	Object.ContactPerson = Catalogs.ContactPersonsForPartners.EmptyRef();
	If ValueIsFilled(Object.Counterparty) Then
		If Not ThisIsReconciliationBetweenOrganizations Then
			DocumentData = Documents.ARAPReconciliation2_5_11.DetailsOfLastDocument(Object.Counterparty);
			FillPropertyValues(Object,DocumentData,,"FullNameOfCounterpartyExecutive, JobTitleOfCounterpartyExecutive, ContactPerson");
			
			If Not ValueIsFilled(Object.FullNameOfCounterpartyExecutive)
					And Not ValueIsFilled(Object.JobTitleOfCounterpartyExecutive) Then
			 	FillPropertyValues(Object, DocumentData, "FullNameOfCounterpartyExecutive, JobTitleOfCounterpartyExecutive");
			EndIf;
			
			If Not ValueIsFilled(Object.ContactPerson)
					Or Common.ObjectAttributeValue(Object.ContactPerson,"Owner") <> Partner Then
				If ValueIsFilled(DocumentData.ContactPerson) Then
					Object.ContactPerson = DocumentData.ContactPerson;
				Else
					Object.ContactPerson = PartnersAndCounterparties.GetDefaultPartnerContactPerson(Partner);
				EndIf;
			EndIf;
		Else
			ResponsiblePersons = ResponsiblePersonsServer.GetResponsiblePersonsOfOrganization(Object.Counterparty, Object.Date);
			Object.CounterpartyCompanyManager = ResponsiblePersons.DirectorRef;
			Object.ChiefAccountantOfCounterpartyCompany = ResponsiblePersons.ChiefAccountantRef;
			Object.ContactPerson = Catalogs.Users.EmptyRef();
			
		EndIf;
		FormItemsManagement();
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	If ThisIsReconciliationBetweenOrganizations Then
		If ValueIsFilled(Object.Counterparty) Then
			ResponsiblePersons = ResponsiblePersonsServer.GetResponsiblePersonsOfOrganization(Object.Counterparty, Object.Date);
			Object.CounterpartyCompanyManager = ResponsiblePersons.DirectorRef;
			Object.ChiefAccountantOfCounterpartyCompany = ResponsiblePersons.ChiefAccountantRef;
		EndIf;
	Else
		Object.CounterpartyCompanyManager = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
		Object.ChiefAccountantOfCounterpartyCompany = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
	EndIf;
	
EndProcedure

&AtServer
Procedure KeyAttributesWhenChangingServer(AdditionalParameters)

	// Cancellation of the event
	If AdditionalParameters.NeedToSpread Then
		WriteParameters = New Structure;
		WriteParameters.Insert("WriteMode", DocumentWriteMode.UndoPosting);
		RecordingResult = Write(WriteParameters);
	Else
		RecordingResult = True;
	EndIf;
	
	If Not RecordingResult Then
		Common.MessageToUser(NStr("vi = 'Không thể hủy bỏ kết chuyển chứng từ';
									|ru = 'Не удалось отменить проведение документа';
									|en = 'Cannot cancel document posting'; fa = 'Cannot cancel document posting';
									|it = 'Не удалось отменить проведение документа';
									|pl = 'Nie udało się anulować zatwierdzenie dokumentu';
									|tr = 'Belge kaydetme iptal edilemedi'"));
		AdditionalParameters.ItIsNecessaryToReFillTS = False;
		AdditionalParameters.Cancel = True;
	EndIf;

	// setting the currency when changing related Attributes
	If AdditionalParameters.Cancel = False
		And (AdditionalParameters.AttributeName = "Organization"
			Or (AdditionalParameters.AttributeName = "ReconciliationInCurrency" And Object.ReconciliationInCurrency = False)) Then

		CurrencyOfComplianceAccounting = SettingsValueClientServerCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		Object.Currency = CurrencyOfComplianceAccounting;
		Object.ReconciliationInCurrency = False;
		Items.Currency.ReadOnly = Not Object.ReconciliationInCurrency;

	EndIf;
	
	If AdditionalParameters.AttributeName = "ThisIsReconciliationBetweenOrganizations" 
			And Not ValueIsFilled(Object.Counterparty) Then
		Object.SummaryRecords.Clear();
		Object.DetailedRecords.Clear();
		AdditionalParameters.ItIsNecessaryToReFillTS = False;
	EndIf;
	
	// checking mandatory Attributes
	If AdditionalParameters.ItIsNecessaryToReFillTS Then
		ErrorTemplate = NStr("vi = 'Chưa điền trường ""%1""';
							|ru = 'Поле ""%1"" не заполнено';
							|en = 'The ""%1"" field is required'; fa = 'The ""%1"" field is required';
							|it = 'Поле ""%1"" не заполнено';
							|pl = 'Pole ""%1"" nie jest wypełnione';
							|tr = '""%1"" alanı doldurulmadı'");
		Cancel = False;
		For Each Item In AdditionalParameters.CheckedAttributes Do
			If Not ValueIsFilled(Object[Item.Key]) Then
				ErrorText = StrTemplate(ErrorTemplate, Item.Value);
				Common.MessageToUser(ErrorText,, Item.Key, "Object", Cancel);
			EndIf;
		EndDo;
		If Cancel Then
			Object.SummaryRecords.Clear();
			Object.DetailedRecords.Clear();
			AdditionalParameters.ItIsNecessaryToReFillTS = False;
		EndIf;
	EndIf;
	
	// Filling Table Parts
	If AdditionalParameters.ItIsNecessaryToReFillTS Then
		Object.SummaryRecords.Clear();
		Object.DetailedRecords.Clear();
		FillInByBalanceServer();
	EndIf; 
	
	If AdditionalParameters.Cancel = True Then
		Return;
	EndIf;

	// calling standard server handlers
	If AdditionalParameters.AttributeName = "Organization" Then 
		OrganizationOnChangeServer();
	ElsIf AdditionalParameters.AttributeName = "Counterparty" Then 
		CounterpartyOnChangeServer();
	ElsIf AdditionalParameters.AttributeName = "ThisIsReconciliationBetweenOrganizations" Then
		FillInListOfCalculationTypesToSelect();
		Items.GroupDataOfCounterpartySOrganization.Visible = ThisIsReconciliationBetweenOrganizations
			Or String(Object.ContactPerson) <> Object.FullNameOfCounterpartyExecutive;
	ElsIf AdditionalParameters.AttributeName = "ModeOfARAPTotalsReconciliation" Then
		SetVisibilityOfCalculationObject();
	ElsIf AdditionalParameters.AttributeName = "Currency" Then
		//
	EndIf;
	
	WhenChangingKeyDetailsStatusOfEDO();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	Object.CounterpartyCompanyManager = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
	Object.ChiefAccountantOfCounterpartyCompany = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
	
EndProcedure

&AtClient
Procedure ShowSummaryRecordsOnChangeClient(RecalculationOfResults = True)
	
	ClearMessages();
	
	If ShowSummaryRecords Then	// Summary Records
		CalculateTotalsOfTotalRecordsOnServer();
		
		// Setting the corresponding totals line
		FinalRecord = LineOfFinalRecordForDetailedRecord();
		
		If FinalRecord <> Undefined Then
			Items.SummaryRecords.CurrentRow = FinalRecord.GetID();
		EndIf;
		
		SetSelectionOfFinalRecords();
	Else // Detail record
		
		FinalRecord = Items.SummaryRecords.CurrentData;
		
		If FinalRecord = Undefined Then
			ShowSummaryRecords = True;
			CommonClient.MessageToUser(NStr("vi = 'Không thể chuyển đến các bản ghi chi tiết, bởi vì chưa chọn bản ghi tổng số.';
											|ru = 'Переход к детальным записям невозможен, т.к. не выбрана итоговая запись.';
											|en = 'Cannot navigate to detailed records as you did not select a summary record.'; fa = 'Cannot navigate to detailed records as you did not select a summary record.';
											|it = 'Переход к детальным записям невозможен, т.к. не выбрана итоговая запись.';
											|pl = 'Cannot navigate to detailed records as you did not select a summary record.';
											|tr = 'Özet kaydı seçilmediği için ayrıntılı kayıtlara geçiş mümkün değildir.'"), , "ShowSummaryRecords");
			Return;
		EndIf;
		
		// Selections are reset when you go to detailed records
		MatchingFilterDetailedRecords = 0;
		FilterDrCr = 0;
		
		SetCalculationSelectionSelectionList();
		SetCalculationSelectionLineForFinalRecord();
		ShowInformationOnSelectionOfCalculations();
		SetVisibilityOfStringConcatenationCommands();
		OutputKeyFields();
		SetSelectionOfDetailedRecords();
	EndIf;
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure FilterCalculationsOnChangeClient()
	
	ShowInformationOnSelectionOfCalculations();
	SetVisibilityOfStringConcatenationCommands();
	OutputKeyFields();
	SetSelectionOfDetailedRecords();
	
EndProcedure

&AtClient
Procedure StatusOnChangeClient()
	
	SetExplanatoryStatusLabel();
	SetAvailabilityOfItemsByStatus();
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure ContractStartChoice(Item)
	Cancel = False;
	If Not ValueIsFilled(Object.Organization) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
				|ru = 'Поле ""Организация"" не заполнено';
				|en = 'The ""Company"" field is required'; fa = 'The ""Company"" field is required';
				|it = 'Поле ""Организация"" не заполнено';
				|pl = 'Nie wypełniono pola ""Firma""';
				|tr = '""İş yeri"" alanı doldurulmadı'"),
			,
			"Organization",
			"Object",
			Cancel);
	EndIf;
	If Not ValueIsFilled(Object.Counterparty) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Đối tác""';
				|ru = 'Поле ""Контрагент"" не заполнено';
				|en = 'The ""Counterparty"" field is required'; fa = 'The ""Counterparty"" field is required';
				|it = 'Поле ""Контрагент"" не заполнено';
				|pl = 'Pole ""Kontrahent"" nie jest wypełnione';
				|tr = '""Cari hesap"" alanı doldurulmadı'"),
			,
			"Counterparty",
			"Object",
			Cancel);
	EndIf;
	If Not Cancel Then
		Filter = SelectingContractSearch();
		PaymentType_ = Item.Parent.CurrentData.PaymentType_;
		If ThisIsReconciliationBetweenOrganizations Then
			OpenForm(
				"Catalog.IntercompanyContracts.ChoiceForm",
				New Structure("Filter", Filter),
				Item);
		ElsIf PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting")
				Or PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting") Then
			OpenForm(
				"Catalog.LoanAndDepositContracts.ChoiceForm",
				New Structure("Filter", Filter),
				Item);
		ElsIf PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor") Then
			OpenForm(
				"Catalog.LeaseContract.ChoiceForm",
				New Structure("Filter", Filter),
				Item);
		Else
			OpenForm(
				"Catalog.CounterpartyContracts.ChoiceForm",
				New Structure("Filter", Filter),
				Item);
		EndIf;
	EndIf; 
EndProcedure

&AtClient
Function SelectingContractSearch()
	Filter = New Structure;
	Filter.Insert("Organization", Object.Organization);
	If ThisIsReconciliationBetweenOrganizations Then
		Filter.Insert("CompanyRecipient", Object.Counterparty);
	Else
		Filter.Insert("Counterparty", Object.Counterparty);
	EndIf;
	Return Filter;
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DetailedRecordsDocumentName3");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DetailedRecordsDocumentNumber");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DetailedRecordsDocumentDate");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DetailedRecordsDebitAmount");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DetailedRecordsLoanAmount_");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DetailedRecordsDocumentAmount");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DetailedRecordsDebtAmount_");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DetailedRecordsAmountPrepayment");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecords.PaymentType_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	TypeOfCalculationsFinTools = New ValueList;
	TypeOfCalculationsFinTools.Add(Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting);
	TypeOfCalculationsFinTools.Add(Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting);
	TypeOfCalculationsFinTools.Add(Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DetailedRecordsDebtAmount_");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DetailedRecordsAmountPrepayment");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DetailedRecords.PaymentType_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = TypeOfCalculationsFinTools;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không điền>';
													|ru = '<Не заполняется>';
													|en = '<Not filled>'; fa = '<Not filled>';
													|it = '<Не заполняется>';
													|pl = '<Not filled>';
													|tr = '<Doldurulmuyor>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	
	//
	
	SetDesignOfExplanatoryField("SummaryRecords", "Organization", NStr("vi = 'Doanh nghiệp';
																		|ru = 'Организация';
																		|en = 'Company'; fa = 'Company';
																		|it = 'Организация';
																		|pl = 'Firma';
																		|tr = 'İş yeri'"));
	SetDesignOfExplanatoryField("SummaryRecords", "Counterparty", NStr("vi = 'Đối tác';
																		|ru = 'Контрагент';
																		|en = 'Counterparty'; fa = 'طرف حساب';
																		|it = 'Контрагент';
																		|pl = 'Kontrahent';
																		|tr = 'Cari hesap'"));
	SetDesignOfExplanatoryField("DetailedRecords", "Organization", NStr("vi = 'Doanh nghiệp';
																		|ru = 'Организация';
																		|en = 'Company'; fa = 'Company';
																		|it = 'Организация';
																		|pl = 'Firma';
																		|tr = 'İş yeri'"));
	SetDesignOfExplanatoryField("DetailedRecords", "Counterparty", NStr("vi = 'Đối tác';
																		|ru = 'Контрагент';
																		|en = 'Counterparty'; fa = 'طرف حساب';
																		|it = 'Контрагент';
																		|pl = 'Kontrahent';
																		|tr = 'Cari hesap'"));

	//

	SetLayoutOfIndicatorField("SummaryRecords", "ContractNumber");
	SetLayoutOfIndicatorField("SummaryRecords", "ContractDate_");
	SetLayoutOfIndicatorField("SummaryRecords", "ContractName");
	SetLayoutOfIndicatorField("SummaryRecords", "OpeningBalanceDr");
	SetLayoutOfIndicatorField("SummaryRecords", "OpeningBalanceCr");
	SetLayoutOfIndicatorField("SummaryRecords", "TurnoverDr");
	SetLayoutOfIndicatorField("SummaryRecords", "TurnoverCr");
	SetLayoutOfIndicatorField("SummaryRecords", "ClosingBalanceDr");
	SetLayoutOfIndicatorField("SummaryRecords", "ClosingBalanceCr");

	//

	SetLayoutOfIndicatorField("DetailedRecords", "DocumentNumber");
	SetLayoutOfIndicatorField("DetailedRecords", "DocumentDate");
	SetLayoutOfIndicatorField("DetailedRecords", "DocumentName3");
	SetLayoutOfIndicatorField("DetailedRecords", "DebitAmount");
	SetLayoutOfIndicatorField("DetailedRecords", "LoanAmount_");

	//

	SetCheckForFillingInAnalytics("DetailedRecords", "DocumentNumber");
	SetCheckForFillingInAnalytics("DetailedRecords", "DocumentDate");
	SetCheckForFillingInAnalytics("DetailedRecords", "DocumentName3");

	//

	SetCheckForFillingInAnalytics("DetailedRecords", "DocumentNumber", True);
	SetCheckForFillingInAnalytics("DetailedRecords", "DocumentDate", True);
	SetCheckForFillingInAnalytics("DetailedRecords", "DocumentName3", True);

EndProcedure

&AtServer
Procedure SetDesignOfExplanatoryField(TypeOfRecords, FieldName, ToolTipText)

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[TypeOfRecords + FieldName].Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataCompositionFieldName = StringFunctionsClientServer.SubstituteParametersToString("Object.%1.%2", TypeOfRecords, FieldName);
	ItemFilter.LeftValue = New DataCompositionField(DataCompositionFieldName);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("Font", New Font(StyleFonts.NormalTextFont,,,,True));
	Item.Appearance.SetParameterValue("Text", ToolTipText + ":");

EndProcedure

&AtServer
Procedure SetCheckForFillingInAnalytics(TypeOfRecords, FieldName, AccordingToCounterparty = False);

	Item = ConditionalAppearance.Items.Add();

	If AccordingToCounterparty Then
		Postfix = "Counterparty";
		NameOfVerificationSideField = "ThereIsDataOfCounterparty";
	Else
		Postfix = "";
		NameOfVerificationSideField = "ThereIsOrganizationData";
	EndIf;

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(TypeOfRecords + FieldName + Postfix);

	ElementSelectionGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	ElementSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = ElementSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(
		StringFunctionsClientServer.SubstituteParametersToString("Object.%1.%2", TypeOfRecords, NameOfVerificationSideField));
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = ElementSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(
		StringFunctionsClientServer.SubstituteParametersToString("Object.%1.%2%3", TypeOfRecords, FieldName, Postfix));
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

EndProcedure

&AtServer
Procedure SetLayoutOfIndicatorField(TypeOfRecords, FieldName)

	Item = ConditionalAppearance.Items.Add();

	Postfix = "Counterparty";

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(TypeOfRecords + FieldName + Postfix);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataCompositionFieldName = StringFunctionsClientServer.SubstituteParametersToString("Object.%1.%2", TypeOfRecords, FieldName);
	ItemFilter.LeftValue = New DataCompositionField(DataCompositionFieldName);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField(DataCompositionFieldName + Postfix);

	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);

EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatus()
	
	OnlyViewItems = (Object.Status = Enums.StatusesOfARAPReconciliation2_5_11.ReconciledWithoutDisputes);
	
	ItemArray = New Array();
	
	// Header Controls
	ItemArray.Add("Date");
	ItemArray.Add("Organization");
	ItemArray.Add("BeginOfPeriod");
	ItemArray.Add("EndOfPeriod");
	ItemArray.Add("Counterparty");
	ItemArray.Add("ThereAreDiscrepancies");
	ItemArray.Add("FilterSettings_2");
	ItemArray.Add("FormFill");
		
	// Groups of controls
	ItemArray.Add("PageGeneral");
	ItemArray.Add("RecordsCalculations");
	ItemArray.Add("SummaryRecordsCombineRecords");
	ItemArray.Add("SummaryRecordsDisconnectRecords");
	ItemArray.Add("DetailedRecordsMergeRecords");
	ItemArray.Add("DetailedRecordsDisconnectRecords");

	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", OnlyViewItems);
	
	ItemArray = New Array();
	
	// Header Controls
	ItemArray.Add("SetDateInterval");
	ItemArray.Add("CalculationsCommandFillInOnBalances");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", Not OnlyViewItems);

EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;

	Items.HeaderDetailedRecords.Visible = Not ShowSummaryRecords;
	Items.HeaderDetailedRecords.Enabled =
		Not ARAPAccountingClientServer.ThereAreUnmappedRecords(Object.SummaryRecords);

	If ShowSummaryRecords Then
		Items.RecordsCalculations.CurrentPage = Items.SummaryRecordsPage;
	Else
		Items.RecordsCalculations.CurrentPage = Items.DetailedRecordsPage;
	EndIf;

	Items.ChiefAccountant.Visible = Object.EmployeeInCharge_ = Enums.PersonsResponsibleAndCompanies.ChiefAccountant;
	Items.Director.Visible = Not Items.ChiefAccountant.Visible;
	Items.ChiefAccountantOfCounterpartyCompany.Visible = Object.CounterpartyCompanyPersonResponsible = Enums.PersonsResponsibleAndCompanies.ChiefAccountant;
	Items.CounterpartyCompanyManager.Visible = Not Items.ChiefAccountantOfCounterpartyCompany.Visible;

	ParametersStructure = New Structure;
	ParametersStructure.Insert("ShowCalculationType", Not Object.SplitByARAPTypes);
	ParametersStructure.Insert("ShowContract", Not Object.SplitByContracts);
	
	Documents.ARAPReconciliation2_5_11.FillInNamesOfBusinessTransactionDetails(
		ParametersStructure, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);

	RecordsAreKeptUnderContracts = GetFunctionalOption("UseIntercompanyContracts")
		Or GetFunctionalOption("UseCustomerContracts")
		Or GetFunctionalOption("UseContractsWithVendors")
		Or AccessRight("View", Metadata.Catalogs.LeaseContract)
		Or GetFunctionalOption("UseLoanAndDepositContracts")
			And AccessRight("View", Metadata.Catalogs.LoanAndDepositContracts);

	If Not RecordsAreKeptUnderContracts Then
		Items.SummaryRecordsContract.Visible = False;
		Items.DetailedRecordsContract.Visible = False;
	EndIf;

	SetPartnerVisibility();
	SetVisibilityOfCounterpartySAttributes();
	SetVisibilityOfCalculationObject();

EndProcedure

&AtServer
Procedure SetVisibilityOfCounterpartySAttributes()

	AttributesAccordingToCounterparty = New Array;
	AttributesAccordingToCounterparty.Add("SummaryRecordsOfReconciliationParty");
	AttributesAccordingToCounterparty.Add("SummaryRecordsContractNameCounterparty");
	AttributesAccordingToCounterparty.Add("SummaryRecordsContractNumberCounterparty");
	AttributesAccordingToCounterparty.Add("SummaryRecordsContractDateCounterparty");
	AttributesAccordingToCounterparty.Add("SummaryRecordsOpeningBalanceDrCounterparty");
	AttributesAccordingToCounterparty.Add("SummaryRecordsOpeningBalanceCrCounterparty");
	AttributesAccordingToCounterparty.Add("SummaryRecordsTurnoverDrCounterparty");
	AttributesAccordingToCounterparty.Add("SummaryRecordsTurnoverCrCounterparty");
	AttributesAccordingToCounterparty.Add("SummaryRecordsClosingBalanceDrCounterparty");
	AttributesAccordingToCounterparty.Add("SummaryRecordsClosingBalanceCrCounterparty");
	AttributesAccordingToCounterparty.Add("DetailedRecordsGroupSideOfReconciliation");
	AttributesAccordingToCounterparty.Add("DetailedRecordsDocumentNameCounterparty");
	AttributesAccordingToCounterparty.Add("DetailedRecordsIncomingNumberCounterparty");
	AttributesAccordingToCounterparty.Add("DetailedRecordsDocumentDateCounterparty");
	AttributesAccordingToCounterparty.Add("DetailedRecordsAmountDebitCounterparty");
	AttributesAccordingToCounterparty.Add("DetailedRecordsAmountCreditCounterparty");

	AttributesAccordingToCounterparty.Add("SummaryRecordsGroupMerge");
	AttributesAccordingToCounterparty.Add("SummaryRecordsCalculationsFilterComparisons");
	AttributesAccordingToCounterparty.Add("DetailedRecordsGroupMerge");
	AttributesAccordingToCounterparty.Add("DetailedRecordsGroupFilterMapping");

	If Object.ThereAreDiscrepancies Then
		VisibleAttributes = AttributesAccordingToCounterparty;
	Else
		VisibleAttributes = New Array;
	EndIf;

	CashServer.SetVisibilityOfElementsByArray(
		Items,
		AttributesAccordingToCounterparty,
		VisibleAttributes);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfCalculationObject()
	
	ReconciliationBySettlementObjects = Object.ModeOfARAPTotalsReconciliation = Enums.ModeOfARAPTotalsReconciliation.ByARAPObjects;
	Items.SummaryRecordsARAPObject.Visible = ReconciliationBySettlementObjects;
	Items.DetailedRecordsARAPObject.Visible = ReconciliationBySettlementObjects;
	
EndProcedure

&AtServer
Procedure SetPartnerVisibility()
	
	ReconciliationBySettlementObjects = Object.ModeOfARAPTotalsReconciliation = Enums.ModeOfARAPTotalsReconciliation.ByARAPObjects;
	ShowPartnerTS = ReconciliationBySettlementObjects And Not Object.SplitByPartners;
	Items.GroupPartner.Visible = Object.SplitByPartners;
	
	Items.SummaryRecordsPartner.Visible = ShowPartnerTS;
	Items.DetailedRecordsPartner.Visible = ShowPartnerTS;
	If Not Object.SplitByPartners Then
		For Each Record In Object.SummaryRecords Do
			If ValueIsFilled(Record.Partner) Then
				Items.SummaryRecordsPartner.Visible = True;
				Items.DetailedRecordsPartner.Visible = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	Items.Currency.ReadOnly = Not Object.ReconciliationInCurrency;
	Items.ThereAreDiscrepancies.Enabled = Not DocumentParticipatesInFEA;
	SetVisibility1();
	SetAvailabilityOfItemsByStatus();
	
	Items.GroupDataOfCounterpartySOrganization.Visible = ThisIsReconciliationBetweenOrganizations;
	
	ParametersArray = New Array;
	If ThisIsReconciliationBetweenOrganizations Then
		TypeCounterparty = New TypeDescription("CatalogRef.Companies");
		TypeContracts = New TypeDescription("CatalogRef.IntercompanyContracts");
	Else
		TypeCounterparty = New TypeDescription("CatalogRef.Counterparties");
		ContractsWithCounterparties = New Array;
		ContractsWithCounterparties.Add("CatalogRef.CounterpartyContracts");
		ContractsWithCounterparties.Add("CatalogRef.LoanAndDepositContracts");
		ContractsWithCounterparties.Add("CatalogRef.LeaseContract");
		TypeContracts = New TypeDescription(ContractsWithCounterparties);
		ParametersArray.Add(New ChoiceParameterLink("Filter.Owner", "Partner"));
	EndIf;
	Items.Counterparty.TypeRestriction = TypeCounterparty;
	Items.SummaryRecordsContract.TypeRestriction = TypeContracts;
	Items.DetailedRecordsContract.TypeRestriction = TypeContracts;
	Items.ContactPerson.ChoiceParameterLinks = New FixedArray(ParametersArray);

EndProcedure

&AtServer
Procedure FillInByBalanceServer()
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Filter_Settings = New ValueStorage(LinkerSelection.GetSettings());
	Documents.ARAPReconciliation2_5_11.FillInCalculationData(DocumentObject);
	ValueToFormAttribute(DocumentObject, "Object");
	Object.ThereAreDiscrepancies = False;
	SetVisibilityOfCounterpartySAttributes();
	
	Items.GroupPages.CurrentPage = Items.PageSettlements;
	
	ARAPAccountingClientServer.CalculateAttributesOfFinalRecordsForm(Object.SummaryRecords, Object.ThereAreDiscrepancies);
	ARAPAccountingClientServer.CalculateAttributesOfDetailedRecordsForm(Object.DetailedRecords, Object.ThereAreDiscrepancies);
	ARAPAccountingClientServer.UpdateReconciliationStateInForm(ThisObject);

EndProcedure

&AtServerNoContext
Function CounterpartySPartner(Counterparty)
	
	If TypeOf(Counterparty) = Type("CatalogRef.Companies") Then
		Return Catalogs.Partners.OurEnterprise;
	ElsIf ValueIsFilled(Counterparty) Then 
		Return Common.ObjectAttributeValue(Counterparty, "Partner");
	Else
		Return Catalogs.Partners.EmptyRef();
	EndIf;
	
EndFunction

&AtClient
Procedure ManagerSFullNameContactPersonStartOfSelection()
	
	If ValueIsFilled(Object.Counterparty) Then
		Filter = New Structure("Owner", Partner);
		OpenForm("Catalog.ContactPersonsForPartners.ChoiceForm",
			New Structure("Filter", Filter),
			ThisObject);
	Else
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Đối tác""';
				|ru = 'Поле ""Контрагент"" не заполнено';
				|en = 'The ""Counterparty"" field is required'; fa = 'The ""Counterparty"" field is required';
				|it = 'Поле ""Контрагент"" не заполнено';
				|pl = 'Pole ""Kontrahent"" nie jest wypełnione';
				|tr = '""Cari hesap"" alanı doldurulmadı'"),
			,
			"Counterparty",
			"Object");
	EndIf; 
	
EndProcedure

&AtServer
Procedure FillPositionBySelectedValue(ContactPerson)
	Object.JobTitleOfCounterpartyExecutive = Common.ObjectAttributeValue(ContactPerson,"JobTitleOnBusinessCard");
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
Procedure SetCalculationSelectionSelectionList()

	ReconciliationUnderContracts = Object.ModeOfARAPTotalsReconciliation = PredefinedValue("Enum.ModeOfARAPTotalsReconciliation.ByContracts");
	If ReconciliationUnderContracts Then
		FilterFields = "PaymentType_, Partner, Contract";
	Else
		FilterFields = "ARAPObject";
	EndIf;

	ChoiceList = Items.FilterCalculations.ChoiceList;
	ChoiceList.Clear();

	If Not ARAPAccountingClientServer.ThereAreUnmappedRecords(Object.SummaryRecords) Then
		AllSelectionValues = Object.SummaryRecords.Unload(, FilterFields);
		AllSelectionValues.GroupBy(FilterFields);
		CalculationSelectionValues.Load(AllSelectionValues);
		If ReconciliationUnderContracts Then
			// counting the number of Contracts
			AllSelectionValues.Columns.Add("Count", New TypeDescription("Number"));
			AllSelectionValues.FillValues(1, "Count");
			AllSelectionValues.GroupBy("Contract", "Count");

			Contracts = AllSelectionValues.UnloadColumn("Contract");
			Result = Contracts.Find(Undefined);
			If Result <> Undefined Then
				Contracts.Delete(Result);
			EndIf;
			NamesOfContracts = Common.ObjectsAttributesValues(Contracts, "Description");

			For Each SelectionObjectString In CalculationSelectionValues Do
				If ValueIsFilled(SelectionObjectString.Contract) Then
					NamesOfContracts.Get(SelectionObjectString.Contract);
					SelectionObjectString.Presentation = NamesOfContracts[SelectionObjectString.Contract].Description;
				Else
					SelectionObjectString.Presentation = NStr("vi = 'Hợp đồng trống';
																|ru = 'Пустой договор';
																|en = 'Blank contract'; fa = 'Blank contract';
																|it = 'Пустой договор';
																|pl = 'Blank contract';
																|tr = 'Boş sözleşme'");
				EndIf;

				Postfix = "";
				ContractLine = AllSelectionValues.Find(SelectionObjectString.Contract, "Contract");
				If ContractLine <> Undefined And ContractLine.Count > 1 Then
					If SelectionObjectString.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
						Postfix = NStr("vi = ' với khách hàng';
										|ru = ' с клиентом';
										|en = ' with customer'; fa = ' with customer';
										|it = ' с клиентом';
										|pl = ' with customer';
										|tr = '/ müşteri ile'");
					ElsIf SelectionObjectString.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting Then
						Postfix = NStr("vi = ' với nhà cung cấp';
										|ru = ' с поставщиком';
										|en = ' with vendor'; fa = ' with vendor';
										|it = ' с поставщиком';
										|pl = ' with vendor';
										|tr = '/ tedarikçi ile'");
					EndIf;
				EndIf;
				SelectionObjectString.Presentation = SelectionObjectString.Presentation + Postfix;
				If Not ValueIsFilled(SelectionObjectString.Contract) Then
					SelectionObjectString.Presentation = "<" + SelectionObjectString.Presentation + ">";
				EndIf;
				ChoiceList.Add(SelectionObjectString.GetID(), SelectionObjectString.Presentation);
			EndDo;	
		Else
			For Each SelectionObjectString In CalculationSelectionValues Do
				If ValueIsFilled(SelectionObjectString[FilterFields]) Then
					SelectionObjectString.Presentation = SelectionObjectString[FilterFields];
				Else
					SelectionObjectString.Presentation = NStr("vi = '<Không có đối tượng hạch toán>';
																|ru = '<Без объекта расчета>';
																|en = '<Without AR/AP object>'; fa = '<Without AR/AP object>';
																|it = '<Без объекта расчета>';
																|pl = '<Without AR/AP object>';
																|tr = '<Alacak/Borç nesnesi olmadan>'");
				EndIf;
				ChoiceList.Add(SelectionObjectString.GetID(), SelectionObjectString.Presentation);
			EndDo;
		EndIf;
	EndIf;
	ChoiceList.SortByPresentation();
	ChoiceList.Insert(0, -1, NStr("vi = '<Chưa đặt bộ lọc>';
									|ru = '<Отбор не установлен>';
									|en = '<Filter is not set>'; fa = '<Filter is not set>';
									|it = '<Отбор не установлен>';
									|pl = '<Filter is not set>';
									|tr = '<Filtre yapılandırılmadı>'"));

EndProcedure

&AtServer
Function ParametersOfExtendedSelectionForm()
	
	FilterContractsWithoutTurnover = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "ContractsWithoutTurnover");
	If FilterContractsWithoutTurnover = Undefined Then
		FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "ContractsWithoutTurnover", True);
		FilterContractsWithoutTurnover = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "ContractsWithoutTurnover");
		FilterContractsWithoutTurnover.Presentation = NStr("vi = 'Bao gồm hợp đồng không có phát sinh trong kỳ';
															|ru = 'Включать договора без оборотов в периоде';
															|en = 'Include contracts without cash transactions during the given period'; fa = 'Include contracts without cash transactions during the given period';
															|it = 'Включать договора без оборотов в периоде';
															|pl = 'Uwzględnij umowy bez obrotu w tym okresie';
															|tr = 'Cirosu olmayan sözleşmeleri döneme dahil edin'");
	EndIf;
	
	Equal = DataCompositionComparisonType.Equal;
	FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "Organization", Object.Organization, Equal);
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		If TypeOf(Object.Counterparty) = Type("CatalogRef.Counterparties") Then
			Partner = Common.ObjectAttributeValue(Object.Counterparty, "Partner");
			FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "Partner", Partner, Equal);
			FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "CompanyCounterparty",,, False);
		Else
			FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "CompanyCounterparty", Object.Counterparty, Equal);
			FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "Partner",,, False);
		EndIf;
	Else
		FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "Counterparty", Object.Counterparty, Equal);
	EndIf;
	If Object.SplitByARAPTypes Then
		FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "PaymentType_", Object.PaymentType_, Equal);
	EndIf;
	If Object.SplitByPartners Then
		FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "Partner", Object.Partner, Equal);
	EndIf;
	If Object.SplitByContracts Then
		FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "Contract", Object.Contract, Equal);
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Filter_Settings", LinkerSelection.GetSettings());
	OpeningParameters.Insert("HideServiceSelections", True);
	OpeningParameters.Insert("DefaultButtonTitle", NStr("vi = 'Điền';
														|ru = 'Заполнить';
														|en = 'Fill'; fa = 'پرکردن';
														|it = 'Заполнить';
														|pl = 'Fill';
														|tr = 'Doldur'"));
	
	Return OpeningParameters;
	
EndFunction

&AtClient
Procedure SetAdvancedSelectionCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	InstallSelectionsOnServer(Result.Filter_Settings);
	FillInSelectionBalance();
	
EndProcedure

&AtServer
Procedure InstallSelectionsOnServer(Val Filter_Settings)
	
	Modified = Not DataCompositionClientServer.SelectionsUsedAreEqual(LinkerSelection.Settings, Filter_Settings);
	
	TheCounterpartyPriorToTheChange = Object.Counterparty;
	
	SetPropsBySelectionValue("PaymentType_", Filter_Settings);
	SetPropsBySelectionValue("Partner", Filter_Settings);
	SetPropsBySelectionValue("Contract", Filter_Settings);
	If UseMultipleCompanies Then
		SetPropsBySelectionValue("Organization", Filter_Settings);
	EndIf;
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		FilterElement = FinancialReportingServer.FindSelectionElement(Filter_Settings.Filter,"Partner",,DataCompositionComparisonType.Equal);
		If FilterElement <> Undefined And FilterElement.Use Then
			Counterparty = PartnersAndCounterparties.GetPartnerSDefaultCounterparty(FilterElement.RightValue);
			Object.Counterparty = Counterparty; 
		Else
			FilterElement = FinancialReportingServer.FindSelectionElement(Filter_Settings.Filter,"CompanyCounterparty",,DataCompositionComparisonType.Equal);
			If FilterElement <> Undefined And FilterElement.Use Then
				Object.Counterparty = FilterElement.RightValue;
			EndIf;
		EndIf;
	Else
		SetPropsBySelectionValue("Counterparty", Filter_Settings);
	EndIf;
	
	LinkerSelection.LoadSettings(Filter_Settings);
	
	If TheCounterpartyPriorToTheChange <> Object.Counterparty Then
		CounterpartyOnChangeServer();
	EndIf;
	
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure SetPropsBySelectionValue(Var_AttributeName, Filter_Settings)
	
	Object[Var_AttributeName] = Undefined;
	If Var_AttributeName = "PaymentType_" Then
		Object["SplitByARAPTypes"] = False;
		
	ElsIf Var_AttributeName = "Partner" Then
		Object["SplitByPartners"] = False;
		
	ElsIf Var_AttributeName = "Contract" Then
		Object["SplitByContracts"] = False;
		
	EndIf;
	
	FilterElement = FinancialReportingServer.FindSelectionElement(Filter_Settings.Filter,Var_AttributeName,,DataCompositionComparisonType.Equal);
	If FilterElement = Undefined Then
		Return;
	EndIf;
	
	If Var_AttributeName = "PaymentType_" Then
		Object["SplitByARAPTypes"] = FilterElement.Use;
		
	ElsIf Var_AttributeName = "Partner" Then
		Object["SplitByPartners"] = FilterElement.Use;
		
	ElsIf Var_AttributeName = "Contract" Then
		Object["SplitByContracts"] = FilterElement.Use;
		
	EndIf;
		
	If FilterElement.Use Then
		Object[Var_AttributeName] = FilterElement.RightValue;
	Else
		FilterElement.RightValue = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

&AtClient
Procedure InitializePreviousValues()

	PreviousValues = New Structure();
	PreviousValues.Insert("Organization", Object.Organization);
	PreviousValues.Insert("Counterparty", Object.Counterparty);
	PreviousValues.Insert("ModeOfARAPTotalsReconciliation", Object.ModeOfARAPTotalsReconciliation);
	PreviousValues.Insert("Currency", Object.Currency);
	PreviousValues.Insert("ReconciliationInCurrency", Object.ReconciliationInCurrency);
	PreviousValues.Insert("ThisIsReconciliationBetweenOrganizations", ThisIsReconciliationBetweenOrganizations);
	PreviousValues.Insert("PaymentType_");
	PreviousValues.Insert("Partner");
	PreviousValues.Insert("Contract");
	PreviousValues.Insert("ARAPObject");
	PreviousValues.Insert("ExternalCounterparty_");
	PreviousValues.Insert("CounterpartyIsOurCompany");
	PreviousValues.Insert("DescriptionOfOutgoingDocuments");
	If TypeOf(Object.Counterparty) = Type("CatalogRef.Counterparties") Then
		PreviousValues.ExternalCounterparty_ = Object.Counterparty;
	ElsIf TypeOf(Object.Counterparty) = Type("CatalogRef.Companies") Then
		PreviousValues.CounterpartyIsOurCompany = Object.Counterparty;
	EndIf;

EndProcedure

&AtServer
Procedure FillInListOfCalculationTypesToSelect()
	
	ChoiceList = Items.SummaryRecordsPaymentType_.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add(Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	ChoiceList.Add(Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
	If Not ThisIsReconciliationBetweenOrganizations Then
		ChoiceList.Add(Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting);
		ChoiceList.Add(Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting);
		ChoiceList.Add(Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor);
	EndIf;
	
EndProcedure
#EndRegion

&AtClient
Async Procedure SetReconciliationStatus(StatusName)

	Status = PredefinedValue("Enum.StatusesOfARAPReconciliation2_5_11." + StatusName);
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chứng từ sẽ đặt trạng thái ""%1"". Tiếp tục?';
			|ru = 'У документа будет установлен статус ""%1"". Продолжить?';
			|en = 'The document status will be set to ""%1"". Continue?'; fa = 'The document status will be set to ""%1"". Continue?';
			|it = 'У документа будет установлен статус ""%1"". Продолжить?';
			|pl = 'The document status will be set to ""%1"". Continue?';
			|tr = 'Belgede ""%1"" durumu ayarlanacaktır. Devam edilsin mi?'"),
		Status);
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo);
	If Response = DialogReturnCode.Yes Then
		Object.Status = Status;
		StatusOnChangeClient();
	EndIf;

EndProcedure

&AtServer
Procedure CalculateTotalsOfTotalRecordsOnServer()

	ReconciliationUnderContracts = Object.ModeOfARAPTotalsReconciliation = Enums.ModeOfARAPTotalsReconciliation.ByContracts;

	GroupingColumns = "PaymentType_, Partner, Contract, ARAPObject";
	TotalingColumns = "DebitAmount, AmountDebitCounterparty, LoanAmount_, AmountCreditCounterparty";
	DetailedRecordData = Object.DetailedRecords.Unload(, GroupingColumns + ", " + TotalingColumns);
	DetailedRecordData.GroupBy(GroupingColumns, TotalingColumns);

	For Each FinalRecord In Object.SummaryRecords Do
		If FinalRecord.ThereIsOrganizationData Then
			ARAPAccountingClientServer.CalculateFinalBalanceOfDrCr(FinalRecord, DetailedRecordData, ReconciliationUnderContracts);
			ARAPAccountingClientServer.CalculateFinalBalanceOfDrCr(FinalRecord, DetailedRecordData, ReconciliationUnderContracts, True);
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure SetSelectionOfFinalRecords()

	Items.FinalEntriesAreAll.Check = MatchingFilterSummaryRecords = 0;
	Items.ResultingRecordsAreNotMatched.Check = MatchingFilterSummaryRecords = 1;
	Items.SummaryRecordsOfDiscrepancy.Check = MatchingFilterSummaryRecords = 2;

	FilterParameters = New Structure();
	If MatchingFilterSummaryRecords > 0 Then
		FilterParameters.Insert("TypeOfDiscrepancies", MatchingFilterSummaryRecords);
	EndIf;

	If FilterParameters.Count() Then
		Items.SummaryRecords.RowFilter = New FixedStructure(FilterParameters);
	Else
		Items.SummaryRecords.RowFilter = Undefined;
	EndIf;

EndProcedure

&AtClient
Procedure SetSelectionOfDetailedRecords()

	Items.DetailedRecordsAreAll.Check = MatchingFilterDetailedRecords = 0;
	Items.DetailedRecordsAreNotMatched.Check = MatchingFilterDetailedRecords = 1;
	Items.DetailedRecordsOfDiscrepancy.Check = MatchingFilterDetailedRecords = 2;

	FilterParameters = New Structure();
	Items.ShowAllItems.Check = FilterDrCr = 0;
	Items.ShowDebit.Check = FilterDrCr = 1;
	Items.ShowCredit.Check = FilterDrCr = 2;

	If MatchingFilterDetailedRecords > 0 Then
		FilterParameters.Insert("TypeOfDiscrepancies", MatchingFilterDetailedRecords);
	EndIf;
	If FilterDrCr = 1 Then
		FilterParameters.Insert("IsTurnoverDr", True);
	ElsIf FilterDrCr = 2 Then
		FilterParameters.Insert("IsTurnoverCr", True);
	EndIf;

	If FilterCalculations <> -1
		And Not ARAPAccountingClientServer.ThereAreUnmappedRecords(Object.SummaryRecords) Then

		CalculationSelectionLine = CalculationSelectionValues.FindByID(FilterCalculations);
		If CalculationSelectionLine <> Undefined Then
			ReconciliationUnderContracts = Object.ModeOfARAPTotalsReconciliation = PredefinedValue("Enum.ModeOfARAPTotalsReconciliation.ByContracts");
			If ReconciliationUnderContracts Then
				FilterParameters.Insert("PaymentType_", CalculationSelectionLine.PaymentType_);
				FilterParameters.Insert("Partner", CalculationSelectionLine.Partner);
				FilterParameters.Insert("Contract", CalculationSelectionLine.Contract);
			Else
				FilterParameters.Insert("ARAPObject", CalculationSelectionLine.ARAPObject);
			EndIf;
		EndIf;

	EndIf;

	If FilterParameters.Count() Then
		Items.DetailedRecords.RowFilter = New FixedStructure(FilterParameters);
	Else
		Items.DetailedRecords.RowFilter = Undefined;
	EndIf;

EndProcedure

&AtClient
Function LineOfFinalRecordForDetailedRecord()

	LineOfDetailedRecord = Items.DetailedRecords.CurrentData;

	If LineOfDetailedRecord = Undefined
	Or Not LineOfDetailedRecord.ThereIsOrganizationData Then
		Return Undefined;
	EndIf;

	Filter = New Structure(KeyAttributes);
	FillPropertyValues(Filter, LineOfDetailedRecord, KeyAttributes);
	SearchResult = Object.SummaryRecords.FindRows(Filter);
	If SearchResult.Count() = 1 Then
		Return SearchResult[0];
	EndIf;

	Return Undefined;

EndFunction

&AtClient
Procedure SetCalculationSelectionLineForFinalRecord()

	FinalRecord = Items.SummaryRecords.CurrentData;
	If FinalRecord = Undefined Or Not FinalRecord.ThereIsOrganizationData Then
		FilterCalculations = -1;
		Return;
	EndIf;

	If ARAPAccountingClientServer.ThereAreUnmappedRecords(Object.SummaryRecords) Then
		FilterCalculations = -1;
		Return;
	EndIf;

	ReconciliationUnderContracts = Object.ModeOfARAPTotalsReconciliation = PredefinedValue("Enum.ModeOfARAPTotalsReconciliation.ByContracts");
	If ReconciliationUnderContracts Then
		FilterFields = "PaymentType_, Partner, Contract";
	Else
		FilterFields = "ARAPObject";
	EndIf;

	FilterParameters = New Structure(FilterFields);
	FillPropertyValues(FilterParameters, FinalRecord, FilterFields);
	Result = CalculationSelectionValues.FindRows(FilterParameters);
	If Result.Count() = 1 Then
		FilterCalculations = Result[0].GetID();
	EndIf;

EndProcedure

&AtClient
Function LineOfFinalRecordForSelectionOfCalculations()

	If FilterCalculations = -1 Then
		Return Undefined;
	EndIf;

	CalculationSelectionLine = CalculationSelectionValues.FindByID(FilterCalculations);
	If CalculationSelectionLine = Undefined Then
		Return Undefined;
	EndIf;

	ReconciliationUnderContracts = Object.ModeOfARAPTotalsReconciliation = PredefinedValue("Enum.ModeOfARAPTotalsReconciliation.ByContracts");
	If ReconciliationUnderContracts Then
		FilterFields = "PaymentType_, Partner, Contract";
	Else
		FilterFields = "ARAPObject";
	EndIf;

	FilterParameters = New Structure(FilterFields);
	FillPropertyValues(FilterParameters, CalculationSelectionLine, FilterFields);
	SearchResult = Object.SummaryRecords.FindRows(FilterParameters);
	If SearchResult.Count() = 1 Then
		Return SearchResult[0];
	Else
		Return Undefined;
	EndIf;

EndFunction

&AtClient
Procedure ShowInformationOnSelectionOfCalculations()

	FinalRecord = LineOfFinalRecordForSelectionOfCalculations();
	If FinalRecord = Undefined Or Not FinalRecord.ThereIsOrganizationData Then
		SelectionDetails = "";
		Return;
	EndIf;

	DetailsAttributes = New Array;
	If ValueIsFilled(FinalRecord.PaymentType_) Then
		DetailsAttributes.Add(FinalRecord.PaymentType_);
	EndIf;
	If ValueIsFilled(FinalRecord.Partner) Then
		DetailsAttributes.Add(FinalRecord.Partner);
	EndIf;
	If ValueIsFilled(FinalRecord.Contract) Then
		DetailsAttributes.Add(FinalRecord.Contract);
	EndIf;

	If DetailsAttributes.Count() Then
		SelectionDetails = StrConcat(DetailsAttributes, ";");
	Else
		SelectionDetails = "";
	EndIf;

EndProcedure

&AtClient
Procedure SetExplanatoryStatusLabel()

	LabelText = "";
	If Object.Status = PredefinedValue("Enum.StatusesOfARAPReconciliation2_5_11.OnReconciliation") Then
		LabelText = StringFunctionsClient.FormattedString(NStr(
		"vi = 'Thực hiện đối chiếu và đặt trạng thái ""<a href = ""%1"">Đã đối chiếu và không có chênh lệch</a>"" hoặc ""<a href = ""%2"">Đã đối chiếu và có chênh lệch</a>"" hoặc ""<a href = ""%3"">Hủy bỏ</a>""';
		|ru = 'Выполните сверку и установите статус ""<a href = ""%1"">Сверена без разногласий</a>"" или ""<a href = ""%2"">Сверена с разногласиями</a>"" или ""<a href = ""%3"">Отклонена</a>""';
		|en = 'Reconcile and set the ""<a href = ""%1"">Reconciled without discrepancies</a>"", ""<a href = ""%2"">Reconciled with discrepancies</a>"", or ""<a href = ""%3"">Rejected</a>"" status'; fa = 'Reconcile and set the ""<a href = ""%1"">Reconciled without discrepancies</a>"", ""<a href = ""%2"">Reconciled with discrepancies</a>"", or ""<a href = ""%3"">Rejected</a>"" status';
		|it = 'Выполните сверку и установите статус ""<a href = ""%1"">Сверена без разногласий</a>"" или ""<a href = ""%2"">Сверена с разногласиями</a>"" или ""<a href = ""%3"">Отклонена</a>""';
		|pl = 'Reconcile and set the ""<a href = ""%1"">Reconciled without discrepancies</a>"", ""<a href = ""%2"">Reconciled with discrepancies</a>"", or ""<a href = ""%3"">Rejected</a>"" status';
		|tr = 'Mutabakatı tamamlayın ve ""A<a href = ""%1"">nlaşmazlık olmadan mutabık kalındı</a>"" veya ""<a href = ""%2"">Anlaşmazlık ile mutabık kalındı</a>"" ya da ""<a href = ""%3"">Reddedildi</a>"" durumunu yapılandırın'"),
		"ReconciledWithoutDisputes",
		"ReconciledWithDisputes",
		"IsRejected");
	ElsIf Object.Status = PredefinedValue("Enum.StatusesOfARAPReconciliation2_5_11.CreatedOn_") Then
		LabelText = StringFunctionsClient.FormattedString(NStr(
		"vi = 'Hãy gửi biên bản đối chiếu cho đối tác và đặt trạng thái ""<a href = ""%1"">Đang đối chiếu</a>""';
		|ru = 'Отправьте акт сверки контрагенту и установите статус ""<a href = ""%1"">На сверке</a>""';
		|en = 'Send the reconciliation statement to the counterparty and set the ""<a href = ""%1"">In reconciliation</a>"" status'; fa = 'Send the reconciliation statement to the counterparty and set the ""<a href = ""%1"">In reconciliation</a>"" status';
		|it = 'Отправьте акт сверки контрагенту и установите статус ""<a href = ""%1"">На сверке</a>""';
		|pl = 'Send the reconciliation statement to the counterparty and set the ""<a href = ""%1"">In reconciliation</a>"" status';
		|tr = 'Mutabakat eylemini cari hesaba gönderin ve ""<a href = ""%1"">Mutabakatta</a>"" durumunu yapılandırın'"),
		"OnReconciliation");
	EndIf;

	Items.DecorationExplanatoryInscription.Title = LabelText;

EndProcedure

&AtClient
Async Procedure KeyAttributesWhenChanging(Var_AttributeName)
	
	AdditionalParameters = ParametersWhenChangingKeyAttributes(Var_AttributeName);
	Response = DialogReturnCode.Yes;
	If Not IsBlankString(AdditionalParameters.QueryText) Then
		Response = Await DoQueryBoxAsync(AdditionalParameters.QueryText, QuestionDialogMode.YesNo);
	EndIf;

	If Response = DialogReturnCode.No Then
		AdditionalParameters.NeedToSpread = False;
		AdditionalParameters.ItIsNecessaryToReFillTS = False;
		AdditionalParameters.Cancel = True;
		Modified = False;
	Else
		If Var_AttributeName = "ThisIsReconciliationBetweenOrganizations" Then
			If ThisIsReconciliationBetweenOrganizations Then
				Items.Counterparty.TypeRestriction = New TypeDescription("CatalogRef.Companies");
				Object.Counterparty = PreviousValues.CounterpartyIsOurCompany;
			Else
				Items.Counterparty.TypeRestriction = New TypeDescription("CatalogRef.Counterparties");
				Object.Counterparty = PreviousValues.ExternalCounterparty_;
			EndIf;
		EndIf;
		KeyAttributesWhenChangingServer(AdditionalParameters);
	EndIf;
	
	If AdditionalParameters.ItIsNecessaryToReFillTS Then
		MessageText = NStr("vi = 'Đã điền phần bảng ""Hạch toán công nợ"".';
							|ru = 'Табличная часть ""Взаиморасчеты"" заполнена.';
							|en = 'The ""AR/AP accounting"" table is filled.'; fa = 'The ""AR/AP accounting"" table is filled.';
							|it = 'Табличная часть ""Взаиморасчеты"" заполнена.';
							|pl = 'The ""AR/AP accounting"" table is filled.';
							|tr = '""Alacak/Borç muhasebesi"" tablosu doldurulmadı.'");
		ShowUserNotification(MessageText,,, PictureLib.Information32);
		ShowSummaryRecords = True;
		ShowSummaryRecordsOnChangeClient();
	EndIf; 
	
	If AdditionalParameters.Cancel Then
		If Var_AttributeName = "ThisIsReconciliationBetweenOrganizations" Then
			ThisIsReconciliationBetweenOrganizations = PreviousValues[Var_AttributeName];
		Else
			Object[Var_AttributeName] = PreviousValues[Var_AttributeName];
		EndIf;
		Items.Currency.ReadOnly = Not Object.ReconciliationInCurrency;
	Else
		If Var_AttributeName = "ThisIsReconciliationBetweenOrganizations" Then
			PreviousValues.Insert(Var_AttributeName, ThisIsReconciliationBetweenOrganizations);
		Else
			PreviousValues.Insert(Var_AttributeName, Object[Var_AttributeName]);
		EndIf;
		Modified = True;
	EndIf;
	
	If AdditionalParameters.NeedToSpread Then
	EndIf;
	
EndProcedure

&AtClient
Function ParametersWhenChangingKeyAttributes(Var_AttributeName)
	
	If Var_AttributeName = "ThisIsReconciliationBetweenOrganizations" Then
		AttributeValue = ThisForm[Var_AttributeName];
	Else
		AttributeValue = Object[Var_AttributeName];
	EndIf;

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("AttributeName", Var_AttributeName);
	AdditionalParameters.Insert("AttributeValue", AttributeValue);
	
	ValueIsRequired = ValueIsFilled(AttributeValue)
		Or Var_AttributeName = "DescriptionOfOutgoingDocuments";

	ItIsNecessaryToReFillTS = ValueIsRequired 
		And (ValueIsFilled(Object.SummaryRecords) Or ValueIsFilled(Object.DetailedRecords));
	NeedToSpread = ItIsNecessaryToReFillTS And Object.Posted And ValueIsFilled(Object.Ref) And ValueIsRequired;
	QueryText = "";
	If NeedToSpread And ItIsNecessaryToReFillTS Then
		QueryText = NStr("vi = 'Chỉ có thể điền phần bảng ""Hạch toán công nợ"" trong chứng từ chưa kết chuyển.
			|Sẽ điền lại phần bảng. Điền lại và hủy kết chuyển?';
			|ru = 'Заполнение табличной части ""Взаиморасчеты"" возможно только в непроведенном документе.
			|Табличная часть будет перезаполнена. Отменить проведение и перезаполнить?';
			|en = 'You can fill the ""AR/AP accounting"" table only in unposted documents.
			|The table will be refilled. Do you want to refill it and unpost the document?'; fa = 'You can fill the ""AR/AP accounting"" table only in unposted documents.
			|The table will be refilled. Do you want to refill it and unpost the document?';
			|it = 'Заполнение табличной части ""Взаиморасчеты"" возможно только в непроведенном документе.
			|Табличная часть будет перезаполнена. Отменить проведение и перезаполнить?';
			|pl = 'You can fill the ""AR/AP accounting"" table only in unposted documents.
			|The table will be refilled. Do you want to refill it and unpost the document?';
			|tr = '""Alacak/Borç muhasebesi"" tablosunun doldurulması sadece kaydedilmemiş bir belgede mümkündür.
			|Tablo yeniden doldurulacaktır. Yeniden doldurulup kayıt iptal edilsin mi?'");
	ElsIf NeedToSpread And Not ItIsNecessaryToReFillTS Then
		QueryText = NStr("vi = 'Chỉ có thể điền phần bảng ""Hạch toán công nợ"" trong chứng từ chưa kết chuyển. Hủy kết chuyển?';
						|ru = 'Заполнение табличной части ""Взаиморасчеты"" возможно только в непроведенном документе. Отменить проведение?';
						|en = 'You can fill the ""AR/AP accounting"" table only in unposted documents. Do you want to unpost the document?'; fa = 'You can fill the ""AR/AP accounting"" table only in unposted documents. Do you want to unpost the document?';
						|it = 'Заполнение табличной части ""Взаиморасчеты"" возможно только в непроведенном документе. Отменить проведение?';
						|pl = 'You can fill the ""AR/AP accounting"" table only in unposted documents. Do you want to unpost the document?';
						|tr = '""Alacak/Borç muhasebesi"" tablosunun doldurulması sadece kaydedilmemiş bir belgede mümkündür. Kayıt iptal edilsin mi?'");
	ElsIf Not NeedToSpread And ItIsNecessaryToReFillTS Then
		QueryText = NStr("vi = 'Sẽ điền lại phần bảng ""Hạch toán công nợ"", tiếp tục?';
						|ru = 'Табличная часть ""Взаиморасчеты"" будет перезаполнена, продолжить?';
						|en = 'The ""AR/AP accounting"" table will be refilled. Continue?'; fa = 'The ""AR/AP accounting"" table will be refilled. Continue?';
						|it = 'Табличная часть ""Взаиморасчеты"" будет перезаполнена, продолжить?';
						|pl = 'The ""AR/AP accounting"" table will be refilled. Continue?';
						|tr = '""Alacak/Borç muhasebesi"" tablosu yeniden doldurulacaktır, devam edilsin mi?'");
	EndIf;
	
	AdditionalParameters.Insert("NeedToSpread", NeedToSpread);
	AdditionalParameters.Insert("ItIsNecessaryToReFillTS", ItIsNecessaryToReFillTS);
	AdditionalParameters.Insert("QueryText", QueryText);
	AdditionalParameters.Insert("Cancel", False);
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.UndoPosting);
	AdditionalParameters.Insert("WriteParameters", WriteParameters);
	
	CheckedAttributes = New Structure;
	If UseMultipleCompanies Then
		CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Организация';
														|pl = 'Firma';
														|tr = 'İş yeri'"));
	EndIf;
	CheckedAttributes.Insert("Counterparty", NStr("vi = 'Đối tác';
													|ru = 'Контрагент';
													|en = 'Counterparty'; fa = 'طرف حساب';
													|it = 'Контрагент';
													|pl = 'Kontrahent';
													|tr = 'Cari hesap'"));
	CheckedAttributes.Insert("Currency", NStr("vi = 'Tiền tệ';
												|ru = 'Валюта';
												|en = 'Currency'; fa = 'ارز';
												|it = 'Валюта';
												|pl = 'Waluta';
												|tr = 'Para birimi'"));
	CheckedAttributes.Insert("EndOfPeriod", NStr("vi = 'Cuối kỳ';
												|ru = 'Конец периода';
												|en = 'Period end'; fa = 'پایان دوره';
												|it = 'Конец периода';
												|pl = 'Koniec okresu';
												|tr = 'Dönem sonu'"));
	AdditionalParameters.Insert("CheckedAttributes", CheckedAttributes);
	
	Return AdditionalParameters;
	
EndFunction

&AtClient
Procedure FillInSelectionBalance()
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection          = Object.SummaryRecords;
	CheckParameters.TitleOfTablePart = NStr("vi = 'Hạch toán công nợ';
											|ru = 'Взаиморасчеты';
											|en = 'AR/AP accounting'; fa = 'حسابداری دریافتنی/پرداختنی';
											|it = 'Взаиморасчеты';
											|pl = 'AR/AP accounting';
											|tr = 'Alacak/Borç muhasebesi'");
	If UseMultipleCompanies Then
		CheckParameters.CheckedAttributes.Insert("Organization",  NStr("vi = 'Doanh nghiệp';
																		|ru = 'Организация';
																		|en = 'Company'; fa = 'Company';
																		|it = 'Организация';
																		|pl = 'Firma';
																		|tr = 'İş yeri'"));
	EndIf;
	CheckParameters.CheckedAttributes.Insert("Counterparty",   NStr("vi = 'Đối tác';
																	|ru = 'Контрагент';
																	|en = 'Counterparty'; fa = 'طرف حساب';
																	|it = 'Контрагент';
																	|pl = 'Kontrahent';
																	|tr = 'Cari hesap'"));
	CheckParameters.CheckedAttributes.Insert("EndOfPeriod", NStr("vi = 'Cuối kỳ';
																|ru = 'Конец периода';
																|en = 'Period end'; fa = 'پایان دوره';
																|it = 'Конец периода';
																|pl = 'Koniec okresu';
																|tr = 'Dönem sonu'"));
	
	Notification = New CallbackDescription("FillInByBalanceCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInByBalanceCompletion(Result, AdditionalParameters) Export
	
	ShowSummaryRecords = True;
	SetVisibility1(); 
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ARAPReconciliation2_5_11.Form.DocumentForm.Fill");
	
	Object.SummaryRecords.Clear();
	Object.DetailedRecords.Clear();
	FillInByBalanceServer();
	
	MessageText = NStr("vi = 'Đã điền phần bảng ""Hạch toán công nợ"".';
						|ru = 'Табличная часть ""Взаиморасчеты"" заполнена.';
						|en = 'The ""AR/AP accounting"" table is filled.'; fa = 'The ""AR/AP accounting"" table is filled.';
						|it = 'Табличная часть ""Взаиморасчеты"" заполнена.';
						|pl = 'The ""AR/AP accounting"" table is filled.';
						|tr = '""Alacak/Borç muhasebesi"" tablosu doldurulmadı.'");
	ShowUserNotification(MessageText,,, PictureLib.Information32);
	
	SetSelectionOfFinalRecords();
	SetSelectionOfDetailedRecords();

EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure SetVisibilityOfStringConcatenationCommands()
	
	Items.DetailedRecordsMergeRecords.Visible = FilterCalculations = -1;
	Items.DetailedRecordsDisconnectRecords.Visible = FilterCalculations = -1;
	
EndProcedure

&AtClient
Procedure OutputKeyFields()
	
	ShowKey = FilterCalculations = -1 And Object.ThereAreDiscrepancies;
	SetVisibilityOfKeyFieldsOfDetailedRecords(ShowKey);
	
EndProcedure

&AtServer
Function ContractDetails_Server(Contract)
	
	ContractDetails_ = Common.ObjectAttributesValues(Contract,"NameForPrinting,Number,Date");
	Return ContractDetails_;
	
EndFunction

&AtClient
Async Procedure DeleteFinalRecordsAsyncs()
	
	QueryText = NStr("vi = 'Sẽ xóa bản ghi chi tiết trực thuộc.
		|Tiếp tục?';
		|ru = 'Подчиненные детальные записи будут удалены.
		|Продолжить?';
		|en = 'Subordinate detailed records will be deleted.
		|Continue?'; fa = 'Subordinate detailed records will be deleted.
		|Continue?';
		|it = 'Подчиненные детальные записи будут удалены.
		|Продолжить?';
		|pl = 'Subordinate detailed records will be deleted.
		|Continue?';
		|tr = 'Ayrıntılı alt kayıtları silinecektir. 
		|Devam edilsin mi?'");
	Response = Await DoQueryBoxAsync(QueryText,QuestionDialogMode.YesNo);
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ReconciliationUnderContracts = Object.ModeOfARAPTotalsReconciliation = PredefinedValue("Enum.ModeOfARAPTotalsReconciliation.ByContracts");
	If ReconciliationUnderContracts Then
		FilterFields = "PaymentType_, Partner, Contract";
	Else
		FilterFields = "ARAPObject";
	EndIf;
	
	RowsIDs = Items.SummaryRecords.SelectedRows;
	SelectedRows = New Array;
	For Each Id In RowsIDs Do
		Record = Object.SummaryRecords.FindByID(Id);
		If Record <> Undefined Then
			SelectedRows.Add(Record);
		EndIf;
	EndDo;
	If SelectedRows.Count() > 1 Then
		For Each Record In SelectedRows Do
			DeleteSubordinateDetailRecords(Record,FilterFields);
			Object.SummaryRecords.Delete(Record);
		EndDo;
		
	ElsIf SelectedRows.Count() = 1 Then
		DeleteSubordinateDetailRecords(SelectedRows[0],FilterFields);
		Object.SummaryRecords.Delete(SelectedRows[0]);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteSubordinateDetailRecords(RecordOwner,FilterFields)
	
	FilterParameters = New Structure(FilterFields);
	FillPropertyValues(FilterParameters, RecordOwner, FilterFields);
	RowOwner = Object.SummaryRecords.FindRows(FilterParameters);
	If RowOwner.Count() = 1 Then
		SubordinateRows = Object.DetailedRecords.FindRows(FilterParameters);
		For Each SubordinateRow In SubordinateRows Do
			Object.DetailedRecords.Delete(SubordinateRow);
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfKeyFieldsOfDetailedRecords(Show)
	
	Items.DetailedRecordsPaymentType_.Visible = False;
	Items.DetailedRecordsContract.Visible = False;
	Items.DetailedRecordsARAPObject.Visible = False;
	
	If Show Then
		ReconciliationUnderContracts = Object.ModeOfARAPTotalsReconciliation = PredefinedValue("Enum.ModeOfARAPTotalsReconciliation.ByContracts");
		If ReconciliationUnderContracts Then
			Items.DetailedRecordsContract.Visible = Show;
			Items.DetailedRecordsPaymentType_.Visible = Show;
			Items.DetailedRecordsPartner.Visible = Show;
		Else
			Items.DetailedRecordsARAPObject.Visible = Show;
		EndIf;
	EndIf;
	
EndProcedure

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
