
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnCreatReadAtServer();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ItemsAndDimensionsSelectionParameters = Documents.ARAPAdjustmentFinancialInstruments.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.ARAPAdjustmentFinancialInstruments.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	If Object.Patch Then
		Items.Debt_FillInByBalance.Visible = False;
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ARAPAdjustmentFinancialInstruments", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
		
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	ItemsAndDimensionsSelectionParameters = Documents.ARAPAdjustmentFinancialInstruments.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.ARAPAdjustmentFinancialInstruments.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	OnCreatReadAtServer();
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If Not ValueIsFilled(Object.BusinessOperation) Then
		Return;
	EndIf;
	
	ClearTablePart();
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	FillInDetailsForStatistics();
	FormItemsManagement();
	ConfigureDependentFormElementsOnServer("BusinessOperation");
	
	ItemsAndDimensionsSelectionParameters = Documents.ARAPAdjustmentFinancialInstruments.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.ARAPAdjustmentFinancialInstruments.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ClearTablePart();
	
EndProcedure

&AtClient
Procedure ContractKindOnChange(Item)
	
	ClearTablePart();
	
	If Not ValueIsFilled(Object.ContractKind) Then
		Object.ContractKind = Items.ContractKind.ChoiceList.Get(0).Value;
	EndIf;
	
	FormItemsManagement();
	
	ConfigureDependentFormElementsOnServer("ContractKind");
	
EndProcedure

&AtClient
Procedure ContractKindClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	ClearTablePart();
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	ClearTablePart();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ClearTablePart();
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	Object.ARAPCurrency = Common.ObjectAttributeValue(Object.Contract, "ARAPCurrency");
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	IncomeAndExpenseItemOnChangeServer(Item.Name);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpenseItemOnChangeServer(Item.Name);
	
EndProcedure

&AtServer
Procedure IncomeAndExpenseItemOnChangeServer(TagName)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpenseItemStartChoice(Item, StandardProcessing)
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpenseItemStartChoice(Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfTheCostReflectionInTheReglAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
EndProcedure

&AtClient
Procedure PresentationOfTheIncomeReflectionInTheReglAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDebt_

&AtClient
Procedure Debt_AmountTypeOnChange(Item)
	LineOfATabularSection = Items.Debt_.CurrentData;
	If LineOfATabularSection <> Undefined
		And LineOfATabularSection.AmountType <> PredefinedValue("Enum.TypesOfLeasePayments.DepositPayment")
		And Object.ContractKind <> PredefinedValue("Enum.ContractKindsOfFinancialInstruments.Lease") Then
		LineOfATabularSection.ARAPDocument = Undefined;
	EndIf;
	SettingUpSettlementDocument();
	Return;
	
EndProcedure

&AtClient
Procedure Debt_OnActivateRow(Item)
	SettingUpSettlementDocument();
	Return;
	
EndProcedure

&AtClient
Procedure Debt_ARAPDocumentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	LineOfATabularSection = Items.Debt_.CurrentData;
	
	DataParameters = New Structure;
	DataParameters.Insert("Contract", Object.Contract);
	DataParameters.Insert("Counterparty", Object.Counterparty);
	DataParameters.Insert("Organization", Object.Organization);
	DataParameters.Insert("TypeOfLeasePayment", LineOfATabularSection.AmountType);
	
	OpenForm("Catalog.LeaseContract.Form.SelectARAPDocument", DataParameters, Item);
	Return;
	
EndProcedure

&AtClient
Procedure Debt_ARAPDocumentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(ValueSelected) = Type("Structure") Then
		
		LineOfATabularSection = Items.Debt_.CurrentData;
		LineOfATabularSection.ARAPDocument = ValueSelected.ARAPDocument;
		Modified = True;
		
	EndIf;
	Return;
	
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
Procedure AutoTestFillInTheRemainingBalance(Command) Export
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Debt_;
	CheckParameters.CheckedAttributes.Insert("Organization",           NStr("vi = 'Doanh nghiệp';
																			|ru = 'Организация';
																			|en = 'Company'; fa = 'Company';
																			|it = 'Azienda';
																			|pl = 'Firma';
																			|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Counterparty",            NStr("vi = 'Đối tác';
																			|ru = 'Контрагент';
																			|en = 'Counterparty'; fa = 'طرف حساب';
																			|it = 'Controparte';
																			|pl = 'Kontrahent';
																			|tr = 'Cari hesap'"));
	CheckParameters.CheckedAttributes.Insert("BusinessOperation", NStr("vi = 'Ghi giảm';
																		|ru = 'Списание';
																		|en = 'Write-off'; fa = 'اسقاط';
																		|it = 'Storno';
																		|pl = 'Write-off';
																		|tr = 'Gider yazma'"));
	Notification = New CallbackDescription("AutoTestFillInTheRemainingBalanceCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure AutoTestFillInTheRemainingBalanceCompletion(Result, AdditionalParameters) Export
	
	FillInOutstandingBalancesServer();
	
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

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnCreatReadAtServer()
	
	FormFieldSettings = Documents.ARAPAdjustmentFinancialInstruments.FormFieldSettings();
	ValueToFormAttribute(FormFieldSettings, "FieldSettings");
	DependenciesOfFormFields = CashServer.DependenciesOfFormFields(FormFieldSettings);
	ValueToFormAttribute(DependenciesOfFormFields, "FieldDependencies");
	
	ComplAccountingIsUsed = GetFunctionalOption("UseLocal");
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		Items.ExpensesPage.Title = NStr("vi = 'Chi phí';
										|ru = 'Расходы';
										|en = 'Expenses'; fa = 'هزینه‌ها';
										|it = 'Spese';
										|pl = 'Expenses';
										|tr = 'Giderler'");
		Items.RevenuePage.Title = NStr("vi = 'Thu nhập';
										|ru = 'Доходы';
										|en = 'Income'; fa = 'درآمد';
										|it = 'Ricavi';
										|pl = 'Income';
										|tr = 'Gelirler'");
	EndIf;
	
	ToolSelectionList = Items.ContractKind.ChoiceList;
	ToolSelectionList.Clear();
	If GetFunctionalOption("UseLoanAndDepositContracts") Then
		ToolSelectionList.Add(Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
		ToolSelectionList.Add(Enums.ContractKindsOfFinancialInstruments.Deposit);
		ToolSelectionList.Add(Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing);
	EndIf;
	If NonCurrentAssets.VNAManagementIsUsed() Then
		ToolSelectionList.Add(Enums.ContractKindsOfFinancialInstruments.Lease);
	EndIf;
	FormItemsManagement();
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	If Object.ContractKind = Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing
		Or Object.ContractKind = Enums.ContractKindsOfFinancialInstruments.Deposit
		Or Object.ContractKind = Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing Then
		
		Items.Contract.TypeRestriction = New TypeDescription("CatalogRef.LoanAndDepositContracts");
		Items.Debt_AmountType.TypeRestriction = New TypeDescription("EnumRef.LoanAndDepositScheduleAmountTypes");
	ElsIf Object.ContractKind = Enums.ContractKindsOfFinancialInstruments.Lease Then
		Items.Contract.TypeRestriction = New TypeDescription("CatalogRef.LeaseContract");
		Items.Debt_AmountType.TypeRestriction = New TypeDescription("EnumRef.TypesOfLeasePayments");
	EndIf;
	
	ParametersForSelectingAmountType = New Array;
	ParametersForSelectingAmountType.Add(New ChoiceParameter("Filter.Contract", Object.Contract));
	ParametersForSelectingAmountType.Add(New ChoiceParameter("ARAPAdjustment", True));
	Items.Debt_AmountType.ChoiceParameters = New FixedArray(ParametersForSelectingAmountType);
	
	Items.Debt_Sum.Title = NStr("vi = 'Tổng số';
								|ru = 'Сумма';
								|en = 'Amount'; fa = 'مبلغ';
								|it = 'Importo';
								|pl = 'Amount';
								|tr = 'Tutar'") + " (" + String(Object.ARAPCurrency) + ")";
	CalculationDocumentSelectionParameters = New Array;
	CalculationDocumentSelectionParameters.Add(New ChoiceParameter("Filter.TranscriptOfPayment_LeaseAgreement", Object.Contract));
	CalculationDocumentSelectionParameters.Add(New ChoiceParameter("Filter.DecryptionOfPayment_TypeOfPaymentForRent", Enums.TypesOfLeasePayments.DepositPayment));
	CalculationDocumentSelectionParameters.Add(New ChoiceParameter("Filter.Counterparty", Object.Counterparty));
	ArrayOfCalculationDocumentSelectionParameters = New FixedArray(CalculationDocumentSelectionParameters);
	Items.Debt_ARAPDocument.ChoiceParameters = ArrayOfCalculationDocumentSelectionParameters;
EndProcedure

&AtClient
Procedure ClearTablePart()
	
	If Object.Debt_.Count() Then
		QueryText = NStr("vi = 'Số tiền điều chỉnh công nợ có thể sẽ không thiết thực.
			|Xóa danh sách công nợ?';
			|ru = 'Суммы корректировки задолженности могут стать неактуальными.
			|Очистить список задолженности?';
			|en = 'AR/AP adjustment amounts can become irrelevant.
			|Clear debt list?'; fa = 'AR/AP adjustment amounts can become irrelevant.
			|Clear debt list?';
			|it = 'Gli importi di regolazione dei debiti possono diventare obsoleti.
			|Cancellare i dati nell''elenco dei debiti?';
			|pl = 'Wartości zapisu korygującego zobowiązania mogą stać nieaktualnymi. 
			|Oczyścić listę zobowiązań?';
			|tr = 'Borç düzeltme tutarları geçerliliğini kaybedebilir.
			|Borç listesi temizlensin mi?'");
		ShowQueryBox(
			New CallbackDescription("ClearTablePartCompletion", ThisObject),
			QueryText,
			QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearTablePartCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Object.Debt_.Clear();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInOutstandingBalancesServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.APWriteOff Then
		DebtType = Enums.DebtTypes.AccountsPayableType;
	Else
		DebtType = Enums.DebtTypes.AccountsReceivableType;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Calculations.AmountType AS AmountType,
	|	CASE
	|		WHEN Calculations.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN Calculations.ARAPDocument
	|		ELSE UNDEFINED
	|	END AS ARAPDocument,
	|	-Calculations.SumBalance AS Sum
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(, Contract = &Contract) AS Calculations
	|WHERE
	|	Calculations.SumBalance < 0
	|	AND &DebtType = VALUE(Enum.DebtTypes.AccountsPayableType)
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.AmountType,
	|	CASE
	|		WHEN Calculations.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN Calculations.ARAPDocument
	|		ELSE UNDEFINED
	|	END AS ARAPDocument,
	|	Calculations.SumBalance
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(, Contract = &Contract) AS Calculations
	|WHERE
	|	Calculations.SumBalance > 0
	|	AND &DebtType = VALUE(Enum.DebtTypes.AccountsReceivableType)
	|";
	
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("DebtType", DebtType);
	
	Object.Debt_.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Procedure FillInDetailsForStatistics()
	
	If Not ValueIsFilled(Object.Organization)
		Or Not ValueIsFilled(Object.Counterparty)
		Or Not ValueIsFilled(Object.BusinessOperation) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	DocumentData.AssetsLiabilitiesDimension,
	|	DocumentData.GLAccountSettings,
	|	DocumentData.ExpenseItem,
	|	DocumentData.DimensionOfExpenses,
	|	DocumentData.IncomeItem,
	|	DocumentData.DimensionOfRevenue,
	|	DocumentData.Department
	|FROM
	|	Document.ARAPAdjustmentFinancialInstruments AS DocumentData
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.BusinessOperation = &BusinessOperation
	|	AND DocumentData.Counterparty = &Counterparty
	|	AND DocumentData.Date <= &Date
	|	AND DocumentData.Ref <> &Ref
	|
	|ORDER BY
	|	Date DESC
	|";
	
	Query.SetParameter("Ref",                    Object.Ref);
	Query.SetParameter("Date",                      EndOfDay(Object.Date));
	Query.SetParameter("Counterparty",                Object.Counterparty);
	Query.SetParameter("Organization",               Object.Organization);
	Query.SetParameter("BusinessOperation",     Object.BusinessOperation);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		FillPropertyValues(Object, Selection);
		Object.GLAccountSettings = GLAccountSettingsServer.CopyOfAccountSettings(Selection.GLAccountSettings, ThisObject);
		ConfigureDependentFormElementsOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("ArticleType");
	FormAttributes.Insert("ComplAccountingIsUsed");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtClient
Procedure IncomeAndExpenseItemStartChoice(Item, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure
&AtClient
Procedure SettingUpSettlementDocument()
	
	LineOfATabularSection = Items.Debt_.CurrentData;
	
	If LineOfATabularSection = Undefined Then
		Return;
	EndIf;
	
	If LineOfATabularSection.AmountType = PredefinedValue("Enum.TypesOfLeasePayments.DepositPayment")
			Or LineOfATabularSection.AmountType = PredefinedValue("Enum.TypesOfLeasePayments.RentalServicePrepayment") Then
		Items.Debt_ARAPDocument.ReadOnly = False;
	Else
		Items.Debt_ARAPDocument.ReadOnly = True;
		LineOfATabularSection.ARAPDocument = Undefined;
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
