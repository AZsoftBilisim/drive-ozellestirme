
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	CopyLink = Parameters.CopyingValue;
	If Not CopyLink.IsEmpty() Then
		Result = InformationRegisters.InterestRateOfFinancialInstruments.ReadCommissionInterestRate(CopyLink);
		InterestRate   = Result.Percent;
		Fee          = Result.Fee;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		If Not ValueIsFilled(Object.ARAPCurrency) Then
			Object.ARAPCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting();
		EndIf;
		OnReadCreateAtServer();
	EndIf;
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	FeeTypeIsLocked = True;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	LoanAndDepositContractsLocalization.WhenCreatingElementFormOnServer(ThisForm, Cancel, StandardProcessing);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Properties" subsystem
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	LoanAndDepositContractsLocalization.BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters, ThisForm);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If InterestRate <> 0 Or Fee <> 0 Then
		
		If CurrentObject.IsNew() Then
			LinkToCatalog = Catalogs.LoanAndDepositContracts.GetRef();
			CurrentObject.SetNewObjectRef(LinkToCatalog);
		Else
			LinkToCatalog = CurrentObject.Ref;
		EndIf;
		
		InformationRegisters.InterestRateOfFinancialInstruments.RecordCommissionSInterestRate(
			LinkToCatalog, InterestRate, Fee, Object.Date);
			
		RateHistoryIsAvailable = True;
		ConfigureDependentFormElementsOnServer("RateHistoryIsAvailable");
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	RefreshFormTitle();
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	FeeTypeIsLocked = True;
	LoanAndDepositContractsLocalization.AfterWriteAtServer(CurrentObject, WriteParameters, ThisForm);
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	LoanAndDepositContractsLocalization.FillCheckProcessingAtServer(Cancel, CheckedAttributes, ThisForm);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Record_VariantOfCreditAndDepositSchedules" Then
		ProcessEntry_OptionOfCreditAndDepositSchedules();
	EndIf;
	
	If EventName = "Write_InterestRateOfFinancialInstruments" Then
		ProcessEntry_InterestRatesOfLoansDeposits();
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure ProcessEntry_OptionOfCreditAndDepositSchedules()
	
	SetCurSchedule();
	ConfigureDependentFormElementsOnServer("ScheduleOption");
	
EndProcedure

&AtServer
Procedure ProcessEntry_InterestRatesOfLoansDeposits()
	
	SetCurInterestRates();
	ConfigureDependentFormElementsOnServer("RateHistoryIsAvailable");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region UniversalEventHandlers

&AtClient
Procedure Attachable_OnChangeAttribute(Item)
	LoanAndDepositContractsLocalizationClient.OnChangeAttribute(
		Item,
		ThisForm);
EndProcedure

&AtClient
Procedure Attachable_ProcessingTheFormSNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	LoanAndDepositContractsLocalizationClient.ProcessingTheFormSNavigationLink(Item,
		FormattedStringURL,
		StandardProcessing,
		ThisForm);
	
EndProcedure

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, AdditionalParameters) Export
	
	If AdditionalParameters.ServerCallRequired_ Then
		AtEndOfChangingLocalizationDetailsOnServer(TagName, AdditionalParameters.ProcessingParameters);
	EndIf;

EndProcedure

&AtServer
Procedure AtEndOfChangingLocalizationDetailsOnServer(TagName, ProcessingParameters)
	
	LoanAndDepositContractsLocalization.AtEndOfChangeOfProps(TagName, ThisForm, ProcessingParameters);
	
EndProcedure

#EndRegion

&AtClient
Procedure ContractKindOnChange(Item)
	
	ContractKindOnChangeServer();
	
EndProcedure

&AtServer
Procedure ContractKindOnChangeServer()
	
	If Object.ContractKind = Enums.ContractKindsOfFinancialInstruments.Deposit Then
		Object.PaymentMethod = Enums.PaymentForms.BankAccountPayment;
		Object.FeeType = Enums.LoanAndDepositFeeTypes.None;
	EndIf;
	
	SetContractType();
	SetCFItemsChoiceParameters();
	
	PartnersAndCounterparties.TitleOfPartnerElementDependsOnNatureOfLoanAndDepositAgreement(
		ThisObject, "Partner", Object.ContractKind);
	
	ClearDetailsFilledInBasedOnStatistics("ContractKind");
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "ContractKind");
	
	AtEndOfChangingLocalizationDetailsOnServer("ContractKind", Undefined);
	ConfigureDependentFormElementsOnServer("ContractKind");
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	If Not ValueIsFilled(Object.ARAPCurrency) Then
		Object.ARAPCurrency = LocalAccountingCurrency;
	EndIf;
	
	If Object.PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
		FillInCheckoutByDefault(Object.Organization, Object.CashAccount, Object.ARAPCurrency);
	Else
		FillInDefaultBankAccount(Object.Organization, Object.ForeignCurrencyTransaction, Object.BankAccount, Object.ARAPCurrency, LocalAccountingCurrency);
		ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Organization", , True);
	EndIf;
	
	SetBankAccountSelectionParameters();
	AtEndOfChangingLocalizationDetailsOnServer("Organization", Undefined);
	
EndProcedure

&AtClient
Procedure ARAPCurrencyOnChange(Item)
	
	ARAPCurrencyOnChangeServer();
	
EndProcedure

&AtServer
Procedure ARAPCurrencyOnChangeServer()
	
	Object.ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
		
	SetBankAccountSelectionParameters();
	AtEndOfChangingLocalizationDetailsOnServer("Currency", Undefined);
	
EndProcedure

&AtClient
Procedure DateOfFirstTrancheOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateScheduleDatesWhenChangedServer(Item.Name);
	
EndProcedure

&AtClient
Procedure LastPaymentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateScheduleDatesWhenChanged(Item);
	
EndProcedure

&AtClient
Procedure TermMonthsOnChange(Item)
	
	DateScheduleDatesWhenChanged(Item)
	
EndProcedure

&AtClient
Procedure TermDaysOnChange(Item)
	
	DateScheduleDatesWhenChanged(Item)
	
EndProcedure

&AtClient
Procedure DateScheduleDatesWhenChanged(Item)
	
	If ValueIsFilled(Object.LastPayment) And Object.LastPayment < Object.DateOfFirstTranche Then
		
		Text = NStr("vi = 'Ngày thanh toán cuối cùng không thể trước ngày của đợt thanh toán đầu tiên';
					|ru = 'Дата последнего платежа не может быть раньше даты первого транша';
					|en = 'Date of the last payment cannot be earlier than the date of the first tranche'; fa = 'Date of the last payment cannot be earlier than the date of the first tranche';
					|it = 'La data dell''ultimo pagamento non può essere anteriore alla data della prima tranche';
					|pl = 'Data ostatniej płatności nie może być wcześniejsza niż data pierwszej transzy';
					|tr = 'Son ödeme tarihi, ilk dilim tarihinden önce olamaz'");
		CommonClientServer.MessageToUser(Text,, "LastPayment", "Object");
		Object.LastPayment = Undefined;
		
	EndIf;
	
	DateScheduleDatesWhenChangedServer(Item.Name);
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	If Not ValueIsFilled(Object.NameForPrinting) Then
		Object.NameForPrinting = Object.Description;
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	PartnerOnChangeServer(Object.Partner, Object.Counterparty, Object.ForeignCurrencyTransaction, Object.CounterpartyBankAccount, Object.ARAPCurrency);
	AtEndOfChangingLocalizationDetailsOnServer("Counterparty", Undefined);
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer(Partner, Counterparty, ForeignCurrencyTransaction, CounterpartyBankAccount, ARAPCurrency)
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Counterparty, "LegalEntityIndividual");
	FillInDefaultBankAccount(Counterparty, ForeignCurrencyTransaction, CounterpartyBankAccount, ARAPCurrency, LocalAccountingCurrency);
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Counterparty", , True);
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtClient
Procedure TextUsedScheduleClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ScheduleOption.IsEmpty() Then
		If Not ValueIsFilled(Object.Ref) Then
			ShowQueryBox(New CallbackDescription("TextUsedScheduleClickCompletion", ThisObject),
				NStr("vi = 'Chỉ có thể nhập lịch biểu sau khi ghi lại hợp đồng.
					|Ghi lại và tiếp tục?';
					|ru = 'Ввод графика возможен только после записи договора.
					|Записать и продолжить?';
					|en = 'You can enter a schedule only after saving the contract.
					|Save and continue?'; fa = 'You can enter a schedule only after saving the contract.
					|Save and continue?';
					|it = 'L''inserimento del piano è possibile solo dopo la registrazione dell''accordo.
					|Registrare e continuare?';
					|pl = 'Wprowadzanie harmonogramu jest możliwe tylko po zapisaniu umowy.
					|Zapisać i kontynuować?';
					|tr = 'Programın girişi ancak sözleşmeyi kaydettikten sonra mümkündür.
					|Kaydedilip devam edilsin mi?'"),
				QuestionDialogMode.YesNo,,
				DialogReturnCode.Yes);
			Return;
		EndIf;
		
		TextUsedGraphClickFragment();
		
	Else
		FormParameters = New Structure;
		FormParameters.Insert("Key", ScheduleOption);
		
		OpenForm("Catalog.OptionsOfLoansAndDepositsSchedules.ObjectForm",
			FormParameters,
			ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure TextUsedScheduleClickCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	TextUsedGraphClickFragment();
	
EndProcedure

&AtClient
Procedure TextUsedGraphClickFragment()

	If Not ValueIsFilled(Object.Ref) Then
		Write();
	Else
		FormParameters = New Structure;
		FormParameters.Insert("Basis", New Structure("Owner", Object.Ref));
		
		OpenForm("Catalog.OptionsOfLoansAndDepositsSchedules.ObjectForm",
			FormParameters,
			ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure TypeOfContractOfUrgencyInCaseOfChange(Item)
	
	TypeOfContractOfUrgencyInCaseOfChangeServer(Item.Name);
	
EndProcedure

&AtServer
Procedure TypeOfContractOfUrgencyInCaseOfChangeServer(Var_AttributeName)
	
	ClearDetailsFilledInBasedOnStatistics(Var_AttributeName);
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, Var_AttributeName);
	AtEndOfChangingLocalizationDetailsOnServer("ContractType", Undefined);
	
EndProcedure

&AtClient
Procedure ChangeTheInterestRateClick(Item)
	
	Filter = New Structure("Contract", Object.Ref);
	FormParameters = New Structure("Filter", Filter);
	OpenForm("InformationRegister.InterestRateOfFinancialInstruments.ListForm", FormParameters, ThisForm,, Window);
	
EndProcedure

&AtClient
Procedure FeeTypeOnChange(Item)
	
	Fee = 0;
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure ControlTheLimitOnChange(Item)
	
	If Not ControlTheLimit And Object.LimitAmount > 0 Then
		Object.LimitAmount = 0;
	EndIf;
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure OnChangeAttribute(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure SupplyOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not Copy Then
		Item.CurrentData.Counterparty = Object.Counterparty;
		Item.CurrentData.Status = PredefinedValue("Enum.CounterpartyContractStatuses.NotApproved");
		Item.CurrentData.StartDate = Object.Date;
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure ForeignCurrencyTransactionOnChange(Item)
	
	ForeignCurrencyTransactionOnChangeServer();
	
EndProcedure

&AtServer
Procedure ForeignCurrencyTransactionOnChangeServer()
	
	SetBankAccountSelectionParameters();
	
	If Not BankAccountCorrespondsToPaymentProcedure(Object.BankAccount) Then
		Object.BankAccount = Undefined;
	EndIf;
	FillInDefaultBankAccount(Object.Organization, Object.ForeignCurrencyTransaction, Object.BankAccount, Object.ARAPCurrency, LocalAccountingCurrency);
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Organization", , True);
	
	If Not BankAccountCorrespondsToPaymentProcedure(Object.CounterpartyBankAccount) Then
		Object.CounterpartyBankAccount = Undefined;
	EndIf;
	FillInDefaultBankAccount(Object.Counterparty, Object.ForeignCurrencyTransaction, Object.CounterpartyBankAccount, Object.ARAPCurrency, LocalAccountingCurrency);
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Counterparty", , True);
	
	If Not BankAccountCorrespondsToPaymentProcedure(Object.InterestBankAccount) Then
		Object.InterestBankAccount = Undefined;
	EndIf;
	
	If Not BankAccountCorrespondsToPaymentProcedure(Object.BankAccountOfFee) Then
		Object.BankAccountOfFee = Undefined;
	EndIf;
	
	If Not BankAccountCorrespondsToPaymentProcedure(Object.CashAccount) Then
		Object.CashAccount = Undefined;
	EndIf;
	
	AtEndOfChangingLocalizationDetailsOnServer("Currency", Undefined);
	
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure ForeignExchangeControlUniqueNumberOnChange(Item)
	
	
EndProcedure

&AtClient
Procedure ForeignCounterpartyIncomeKindOnChange(Item)
	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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
// End StandardSubsystems.FilesOperations

#Region UniversalFormCommandHandlers

&AtClient
Procedure Attachable_ExecuteLocalizationCommand(Command)
	
	LoanAndDepositContractsLocalizationClient.ExecuteLocalizationCommand(Command, ThisForm);
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, AdditionalParameters) Export
	
	If AdditionalParameters.ServerCallRequired_ Then
		ContinueRunningLocalizationCommandOnServer(CommandName, AdditionalParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure ContinueRunningLocalizationCommandOnServer(CommandName, ProcessingParameters)
	
	LoanAndDepositContractsLocalization.ExecuteLocalizationCommand(ThisForm, CommandName, ProcessingParameters);
	
EndProcedure
	
#EndRegion

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("ProcessUnlockingOfBankingDetails", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm, ProcedureParameters);
	
EndProcedure

&AtClient
Procedure ProcessUnlockingOfBankingDetails(Result, AdditionalParameters) Export
	
	If Result = True Then
		FeeTypeIsLocked = False;
		ConfigureDependentFormElements("FeeTypeIsLocked");
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

#EndRegion

#Region Private

#Region FormHeaderElementHandlers

&AtServer
Procedure CounterpartyOnChangeServer()

	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	FillInDefaultBankAccount(Object.Counterparty, Object.ForeignCurrencyTransaction, Object.CounterpartyBankAccount, Object.ARAPCurrency, LocalAccountingCurrency);
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Counterparty", , True);
	AtEndOfChangingLocalizationDetailsOnServer("Counterparty", Undefined);

EndProcedure

#EndRegion

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	LoanAndDepositContractsLocalization.SetConditionalAppearance(ThisForm);
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	TradeManagement = Not GetFunctionalOption("EnterpriseManagement")
		                  And Not GetFunctionalOption("ComplexAutomation");
	
	FormFieldSettings = Catalogs.LoanAndDepositContracts.FormFieldSettings();
	ValueToFormAttribute(FormFieldSettings, "FieldSettings");
	DependenciesOfFormFields = CashServer.DependenciesOfFormFields(FormFieldSettings);
	ValueToFormAttribute(DependenciesOfFormFields, "FieldDependencies");
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	ControlTheLimit = (Object.LimitAmount > 0);
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	
	SetContractType();
	SetBankAccountSelectionParameters();
	SetCFItemsChoiceParameters();
	SetCurSchedule();
	SetCurInterestRates();
	
	RefreshFormTitle();
	
	PartnersAndCounterparties.TitleOfPartnerElementDependsOnNatureOfLoanAndDepositAgreement(
		ThisObject, "Partner", Object.ContractKind);
	
	LoanAndDepositContractsLocalization.OnReadCreateAtServer(ThisForm);
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	If Object.ContractKind = Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing Then
		TypePresentation = NStr("vi = 'Điều kiện đi vay';
								|ru = 'Условия кредита или займа';
								|en = 'Credit or loan terms'; fa = 'Credit or loan terms';
								|it = 'Termini di prestito o finanziamento';
								|pl = 'Warunki kredytu lub pożyczki';
								|tr = 'Kredi ve mevduat şartları'");
	ElsIf Object.ContractKind = Enums.ContractKindsOfFinancialInstruments.Deposit Then
		TypePresentation = NStr("vi = 'Điều kiện tiền gửi (deposit)';
								|ru = 'Условия депозита';
								|en = 'Deposit conditions'; fa = 'Deposit conditions';
								|it = 'Termini di deposito';
								|pl = 'Warunki depozytu';
								|tr = 'Mevduat şartları'");
	ElsIf Object.ContractKind = Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing Then
		TypePresentation = NStr("vi = 'Điều kiện cho vay';
								|ru = 'Условия выдачи займа';
								|en = 'Loan conditions'; fa = 'Loan conditions';
								|it = 'Termini di concessione del prestito';
								|pl = 'Warunki wydania pożyczki';
								|tr = 'Borç verme şartları'");
	Else
		TypePresentation = NStr("vi = 'Hợp đồng với đối tác';
								|ru = 'Договор с контрагентом';
								|en = 'Contract'; fa = 'قرارداد';
								|it = 'Contratto con la controparte';
								|pl = 'Umowa z kontrahentem';
								|tr = 'Cari hesap sözleşmesi'");
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		ThisForm.Title = TypePresentation + " (" + NStr("vi = 'tạo';
														|ru = 'создание';
														|en = 'create'; fa = 'ایجاد';
														|it = 'creazione';
														|pl = 'create';
														|tr = 'oluşturma'") + ")";
	Else
		ThisForm.Title = Object.Description + " (" + TypePresentation + ")";
	EndIf;
	
EndProcedure

&AtServer
Procedure SetContractType()
	
	ChoiceList = Items.ContractType.ChoiceList;
	ChoiceList.Clear();
	
	If Object.ContractKind = Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing Then
		
		ChoiceList.Add(Enums.LoanAndDepositContractTypes.BankLoan);
		ChoiceList.Add(Enums.LoanAndDepositContractTypes.ExternalLoan);
		ChoiceList.Add(Enums.LoanAndDepositContractTypes.InternalLoan);
		ChoiceList.Add(Enums.LoanAndDepositContractTypes.EmployeeDeposit);
		
	ElsIf Object.ContractKind = Enums.ContractKindsOfFinancialInstruments.Deposit Then
		
		ChoiceList.Add(Enums.LoanAndDepositContractTypes.DepositWithoutInterestCapitalization);
		ChoiceList.Add(Enums.LoanAndDepositContractTypes.DepositWithInterestCapitalization);
		
	ElsIf Object.ContractKind = Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing Then
		
		ChoiceList.Add(Enums.LoanAndDepositContractTypes.ExternalLoan);
		ChoiceList.Add(Enums.LoanAndDepositContractTypes.InternalLoan);
	EndIf;
	
	If ChoiceList.FindByValue(Object.ContractType) = Undefined And ChoiceList.Count() Then
		Object.ContractType = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetBankAccountSelectionParameters()
	
	ParametersArray = New Array;
	If Not Object.ForeignCurrencyTransaction Then
		ParametersArray.Add(New ChoiceParameter("Filter.CashCurrency", LocalAccountingCurrency));
	Else
		ParametersArray.Add(New ChoiceParameter("Filter.CashCurrency", Object.ARAPCurrency));
	EndIf;
	
	ParametersArray.Add(New ChoiceParameter("SelectingAccountsOfParentCompany", Undefined));
	ParametersArray.Add(New ChoiceParameter("Filter.Closed", False));
	
	AccountSelectionParameters = New FixedArray(ParametersArray);
	
	Items.BankAccount.ChoiceParameters            = AccountSelectionParameters;
	Items.CounterpartyBankAccount.ChoiceParameters = AccountSelectionParameters;
	Items.InterestBankAccount.ChoiceParameters   = AccountSelectionParameters;
	Items.BankAccountOfFee.ChoiceParameters    = AccountSelectionParameters;
	Items.CashAccount.ChoiceParameters                     = AccountSelectionParameters;
	
EndProcedure

&AtServer
Procedure SetCFItemsChoiceParameters()
	
	BO = Enums.BusinessTransactions;
	NatureOfContracts = Enums.ContractKindsOfFinancialInstruments;
	If Object.ContractKind <> NatureOfContracts.LoanOrBorrowing Then
		Items.ArticleDdsapplications.ChoiceParameters = CFItemSelectionParameters(Object.ContractKind);
		Items.CashFlowItemOfPrincipalDebt.ChoiceParameters = CFItemSelectionParameters(Object.ContractKind, True);
		If Object.ContractKind = NatureOfContracts.Deposit Then
			Items.CashFlowItemOfInterestPayment.ChoiceParameters = CFItemSelectionParameters(Object.ContractKind,, BO.DepositInterestCharge);
		Else
			Items.CashFlowItemOfInterestPayment.ChoiceParameters = CFItemSelectionParameters(Object.ContractKind,, BO.ReceiptOfInterestOfIssuedBorrowings);
		EndIf;
	Else
		Items.ArticleDdsapplications.ChoiceParameters = CFItemSelectionParameters(Object.ContractKind, True);
		Items.CashFlowItemOfPrincipalDebt.ChoiceParameters = CFItemSelectionParameters(Object.ContractKind);
		Items.CashFlowItemOfInterestPayment.ChoiceParameters = CFItemSelectionParameters(Object.ContractKind,, BO.LoanInterestPayment);
	EndIf;
	Items.CashFlowItemOfFeePayment.ChoiceParameters = CFItemSelectionParameters(Object.ContractKind);
	
EndProcedure

&AtServer
Function CFItemSelectionParameters(ContractKind, ThisIsAdmission = False, BusinessOperation = Undefined)
	
	ParametersArray = New Array;
	If BusinessOperation = Undefined Then
		BusinessOperation = Catalogs.LoanAndDepositContracts.OperationByNatureOfContract(ContractKind, ThisIsAdmission);
	EndIf;
	ParametersArray.Add(New ChoiceParameter("Filter.BusinessOperation", BusinessOperation));
	
	Return New FixedArray(ParametersArray);
	
EndFunction

&AtServer
Procedure DateScheduleDatesWhenChangedServer(TagName = "LastPayment")
	
	Catalogs.OptionsOfLoansAndDepositsSchedules.RecalculateTerms(Object, TagName);
	
EndProcedure

&AtServer
Function BankAccountCorrespondsToPaymentProcedure(BankAccount)
	
	Respond = True;
	
	If ValueIsFilled(BankAccount) Then
		AccountCurrency = Common.ObjectAttributeValue(BankAccount, "CashCurrency");
		If Object.ForeignCurrencyTransaction Then
			Respond = (AccountCurrency <> LocalAccountingCurrency);
		Else
			Respond = (AccountCurrency = LocalAccountingCurrency);
		EndIf;
	EndIf;
	
	Return Respond;
	
EndFunction

&AtServerNoContext
Procedure FillInDefaultBankAccount(AccountHolder, ForeignCurrencyTransaction, OwnerSBankAccount, ARAPCurrency, LocalAccountingCurrency)
	
	If (ValueIsFilled(OwnerSBankAccount)
		And AccountHolder = Common.ObjectAttributeValue(OwnerSBankAccount, "Owner"))
		Or Not ValueIsFilled(AccountHolder) Then
		Return;
	EndIf;
	
	OwnerSBankAccount = Undefined;
	
	Query = New Query("
	|SELECT TOP 2
	|	BankAccounts.Ref AS BankAccount,
	|	BankAccounts.Ref = &MainAccount AS Main,
	|	BankAccounts.CashCurrency AS CashCurrency
	|FROM
	|	Catalog.CompaniesBankAccounts AS BankAccounts
	|WHERE
	|	BankAccounts.Owner = &AccountHolder
	|	AND (BankAccounts.CashCurrency = &ComplCurrency AND NOT &ForeignCurrencyTransaction
	|		OR BankAccounts.CashCurrency <> &ComplCurrency AND &ForeignCurrencyTransaction)
	|	AND NOT BankAccounts.DeletionMark
	|
	|ORDER BY
	|	Main DESC");
	
	If TypeOf(AccountHolder) = Type("CatalogRef.Counterparties") Then
		Query.Text = StrReplace(Query.Text,"CompaniesBankAccounts","CounterpartyBankAccounts");
		MainAccount = Undefined;
	Else
		MainAccount = Catalogs.Companies.GetPrimaryBankAccount(AccountHolder);
	EndIf;
	
	Query.SetParameter("AccountHolder", AccountHolder);
	Query.SetParameter("ForeignCurrencyTransaction", ForeignCurrencyTransaction);
	Query.SetParameter("ComplCurrency", LocalAccountingCurrency);
	Query.SetParameter("MainAccount", MainAccount);
	
	Selection = Query.Execute().Select();
	If Selection.Next() And (Selection.Count() = 1 Or Selection.Main) Then
		OwnerSBankAccount = Selection.BankAccount;
		If Not ValueIsFilled(ARAPCurrency) Then
			ARAPCurrency = Selection.CashCurrency;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure FillInCheckoutByDefault(Organization, CashAccount, ARAPCurrency)
	
	If ValueIsFilled(CashAccount) Then
		Return;
	EndIf;
	
	CashAccount = Common.CommonSettingsStorageLoad("CurrentCashAccount", "");
	If Not ValueIsFilled(CashAccount) Then
		CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(Organization);
	EndIf;
	If ValueIsFilled(CashAccount) Then
		AttributesStructure1 = Catalogs.CashAccounts.GetCheckoutDetails(CashAccount);
		ARAPCurrency = AttributesStructure1.Currency;
	Else
		ARAPCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure SetCurSchedule()
	
	ScheduleOption = Catalogs.OptionsOfLoansAndDepositsSchedules.CurVersionOfGraph(Object.Ref);
	
	If ValueIsFilled(ScheduleOption) Then
		TextUsedSchedule = String(ScheduleOption);
	Else
		TextUsedSchedule = "<" + NStr("vi = 'Nhập';
										|ru = 'Ввести';
										|en = 'Enter'; fa = 'ورود';
										|it = 'Inserire';
										|pl = 'Wprowadź';
										|tr = 'Gir'")+ ">";
	EndIf;
	
EndProcedure

&AtServer
Procedure SetCurInterestRates()
	
	Result = InformationRegisters.InterestRateOfFinancialInstruments.ReadCommissionInterestRate(Object.Ref);
	
	InterestRate   = Result.Percent;
	Fee          = Result.Fee;
	RateHistoryIsAvailable = Result.ThereIsStory;
	
EndProcedure

&AtServer
Procedure ClearDetailsFilledInBasedOnStatistics(KeyAttribute)

	AttributesDetails1 = New Structure;
	Catalogs.LoanAndDepositContracts.EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1);
	
	For Each AttributeDetails In AttributesDetails1 Do
		If AttributeDetails.Value.Property(KeyAttribute) Then
			Object[AttributeDetails.Key] = Undefined;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("ControlTheLimit");
	FormAttributes.Insert("ScheduleOption");
	FormAttributes.Insert("RateHistoryIsAvailable");
	FormAttributes.Insert("FeeTypeIsLocked");
	LoanAndDepositContractsLocalizationClientServer.AddToListOfFormDetails(FormAttributes);
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

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
	If Item.Name = "sh_ShamsiInput_DateOfFirstTranche" Then
		DateOfFirstTrancheOnChange(Items.DateOfFirstTranche);
	ElsIf Item.Name = "sh_ShamsiInput_LastPayment" Then
		LastPaymentOnChange(Items.LastPayment);
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
