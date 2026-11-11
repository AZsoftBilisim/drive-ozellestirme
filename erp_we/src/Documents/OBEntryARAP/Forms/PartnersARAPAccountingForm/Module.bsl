#Region Variables

&AtClient
Var TimeConsumingOperationForm Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseCustomerInvoiceIntercompany = GetFunctionalOption("UseCustomerInvoiceIntercompany");
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	UseTollManufacturing2_5 =
		GetFunctionalOption("UseTollManufacturing2_5");
	UseProductionByThirdParty2_5 =
		GetFunctionalOption("UseProductionByThirdParty2_5");
	Items.RecordInMA.Visible = GetFunctionalOption("KeepManagementAccountingOnSelfFinancingChartOfAccounts");
	SetParametersForSelectingCounterpartySPartnerAndFieldHeaders();
	SetVisibility1();
	
	Items.GroupEnterBalanceBy.Visible = GetFunctionalOption("UseLocal");
	Items.PartnersARAPAccountingCounterparty.ChooseType = UseCustomerInvoiceIntercompany
		And Not GetFunctionalOption("UsePartnersAndCounterparties");
	Items.Organization.Visible = GetFunctionalOption("NotBaseVersion");
	
	SetTitleOfThisForm();
	
	If Not ValueIsFilled(Object.Ref) Then 
		OnCreatReadAtServer();
	EndIf;

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
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
	
	OnCreatReadAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	SetTitleOfThisForm();
	
	FillInServiceAttributesOfCalculationsWithPartnersTable();
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("BusinessOperation",  Object.BusinessOperation);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	SetVisibility1();
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	OrganizationWhenChangedOnServer();
EndProcedure

&AtClient
Procedure OrganizationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected <> Object.Organization Then
		ClearNumberAndDateOfCalculationObjects();
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordInOperationalAccountingOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure PostInFinancialAndTaxAccountingOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure RecordInMAOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(ThisObject, FormattedStringURL, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPartnersARAPAccounting

&AtClient
Procedure SettlementsWithPartnersPartnerOnChange(Item)
	
	CurrentData = Items.PartnersARAPAccounting.CurrentData;
	IDCurrentRow = CurrentData.GetID();
	PartnerOnChange(CurrentData.Partner, CurrentData.Counterparty, IDCurrentRow);
	
EndProcedure

&AtClient
Procedure SettlementsWithPartnersCounterpartyOnChange(Item)

	CurrentData = Items.PartnersARAPAccounting.CurrentData;
	CurrentData.ARAPObject            = Undefined;
	CurrentData.ARAPObjectSender = Undefined;
	CurrentData.Contract                   = Undefined;
	CurrentData.ARAPObjectSettings           = Undefined;
	CurrentData.CentralizedContract   = Undefined;
	CurrentData.DocumentOfARAPAccounting          = Undefined;

EndProcedure

&AtClient
Procedure SettlementsWithPartnersAmountOnChange(Item)

	CurrentData = Items.PartnersARAPAccounting.CurrentData;
	CalculatedAmounts = CalculateAmounts(
		CurrentData.Sum,
		0,
		CurrentData.ARAPCurrency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency,
		Object.Date,
		CurrentData.DocumentOfARAPAccounting);
	FillPropertyValues(CurrentData, CalculatedAmounts, "SumCompl, SumMan");

EndProcedure

&AtClient
Procedure PartnersARAPAccountingOnStartEdit(Item, NewRow, Copy)
	
	FillInCurrencyOfSettlementsInLine(Items.PartnersARAPAccounting.CurrentData);
	InitializeCounterpartyInLine(Items.PartnersARAPAccounting.CurrentData, NewRow, Copy);
	
EndProcedure

&AtClient
Procedure SettlementsWithPartnersARAPDocumentStartChoice(Item, ChoiceData, StandardProcessing)
	SetParametersForSelectingSettlementDocument(Item.Name, Item.Parent.CurrentData);
EndProcedure

&AtClient
Procedure SettlementsWithPartnersARAPDocumentCreating(Item, StandardProcessing)
	SetParametersForSelectingSettlementDocument(Item.Name, Item.Parent.CurrentData, True);
EndProcedure

&AtClient
Procedure SettlementsWithPartnersARAPDocumentEditTextChange(Item, Text, StandardProcessing)
	SetParametersForSelectingSettlementDocument(Item.Name, Item.Parent.CurrentData);
EndProcedure

&AtClient
Procedure SettlementsWithPartnersARAPDocumentAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	ProcessingOfReceivingDataOfPrimaryDocumentSelection(ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure SettlementsWithPartnersARAPDocumentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	CheckAttributesOfSelectedValue(ValueSelected, StandardProcessing, Items.PartnersARAPAccounting.CurrentData);
EndProcedure

&AtClient
Procedure SettlementsWithPartnersARAPObjectSenderStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	CurrentData = Items.PartnersARAPAccounting.CurrentData; 
	PaymentType_ = ?(
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerBonuses"),
		PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"),
		PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting"));
	ARAPObjectStartChoice(
		Item, 
		CurrentData, 
		PaymentType_,
		True);
EndProcedure

&AtClient
Procedure SettlementsWithPartnersARAPObjectSenderAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	CurrentData = Items.PartnersARAPAccounting.CurrentData;
	PaymentType_ = ?(
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerBonuses"),
		PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"),
		PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting"));
	ARAPObjectAutoComplete(
		Text,
		ChoiceData,
		CurrentData,
		StandardProcessing,
		PaymentType_,
		True);
EndProcedure

&AtClient
Procedure SettlementsWithPartnersARAPObjectSenderTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	CurrentData = Items.PartnersARAPAccounting.CurrentData;
	PaymentType_ = ?(
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerBonuses"),
		PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"),
		PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting"));
	ARAPObjectAutoComplete(
		Text,
		ChoiceData,
		CurrentData,
		StandardProcessing,
		PaymentType_,
		True);
EndProcedure

&AtClient
Procedure SettlementsWithPartnersARAPObjectSenderChoiceProcessing(Item, ValueSelected, StandardProcessing)
	CurrentData = Items.PartnersARAPAccounting.CurrentData;
	CalculationObjectSelectionProcessing(ValueSelected, CurrentData, StandardProcessing);
EndProcedure

&AtClient
Procedure PartnersARAPAccountingARAPObjectSenderCreating(Item, StandardProcessing)
	ARAPObjectCreating(Item, StandardProcessing);
EndProcedure

&AtClient
Procedure SettlementsWithPartnersARAPObjectSenderOnChange(Item)
	CurrentData = Items.PartnersARAPAccounting.CurrentData;
	If CurrentData <> Undefined 
		And Not ValueIsFilled(CurrentData.ARAPObjectSender) Then
		CurrentData.DocumentOfARAPAccounting = PredefinedValue("Document.SourceDocument.EmptyRef");
		CurrentData.Contract = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
		CurrentData.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.EmptyRef");
		CurrentData.CentralizedContract = False;
	EndIf;
EndProcedure

&AtClient
Procedure SettlementsWithPartnersDiscountAmountOnChange(Item)
	
	CurrentData = Items.PartnersARAPAccounting.CurrentData;
	CalculatedAmounts = CalculateAmounts(
		CurrentData.Sum,
		CurrentData.DiscountingAmount,
		CurrentData.ARAPCurrency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency,
		Object.Date,
		CurrentData.DocumentOfARAPAccounting);
	FillPropertyValues(CurrentData, CalculatedAmounts, "DiscountingAmountCompl, DiscountingAmountMan");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

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

&AtClient
Procedure FillInByBalance(Command)
	If Object.PartnersARAPAccounting.Count() Then
		AlertQuestionFillInByBalances = New CallbackDescription("AlertHandlerIssueFillInByBalances", ThisObject);
		QueryText = NStr("vi = 'Khi điền, dữ liệu hiện tại của phần bảng sẽ bị xóa. Tiếp tục?';
						|ru = 'При заполнении текущие данные табличной части будут очищены. Продолжить?';
						|en = 'Current table data will be cleared. Continue?'; fa = 'Current table data will be cleared. Continue?';
						|it = 'I dati correnti della parte tabulare verranno cancellati durante la compilazione. Continuare?';
						|pl = 'Przy wypełnieniu bieżące dane części tabelarycznej będą oczyszczone. Kontynuować?';
						|tr = 'Tablo bölümünün mevcut verileri tamamlandığında silinecektir. Devam edilsin mi?'");
		ShowQueryBox(AlertQuestionFillInByBalances, QueryText, QuestionDialogMode.YesNo,,,  NStr("vi = 'Nhập số dư kế toán tài chính theo dữ liệu của kế toán hoạt động';
																								|ru = 'Ввод остатков регл. учета по данным оперативного';
																								|en = 'Enter local accounting balance according to real-time accounting data'; fa = 'Enter local accounting balance according to real-time accounting data';
																								|it = 'Immissione delle rimanenze della contabilità regolamentare in base ai dati di contabilità operativa';
																								|pl = 'Wprowadzenie ostatków ewidencji reglamentowanej według danych operacyjnej';
																								|tr = 'Operasyonel verilere dayalı olarak yerel muhasebe bakiyelerinin girilmesi'"));
	Else
		FillByBalancesOnServer();
	EndIf;
	Return;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// Removing the blank mark in the "Regulated" accounting section
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.PartnersARAPAccountingPaymentDate.Name);
	
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.RecordInOperationalAccounting", False);
	BsnsTransactions = New ValueList;
	BsnsTransactions.Add(Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable);
	BsnsTransactions.Add(Enums.BusinessTransactions.OBEntryCustomerBonuses);
	BsnsTransactions.Add(Enums.BusinessTransactions.OBEntryVendorBonuses);
	BsnsTransactions.Add(Enums.BusinessTransactions.OBEntryVendorAccountsPayable);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.BusinessOperation", BsnsTransactions, DataCompositionComparisonType.InList);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	// Advance payment date
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.PartnersARAPAccountingPaymentDate.Name);
	
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.PartnersARAPAccounting.PaymentDate", , DataCompositionComparisonType.NotFilled);
	BsnsTransactions = New ValueList;
	BsnsTransactions.Add(Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer);
	BsnsTransactions.Add(Enums.BusinessTransactions.OBEntryCustomerBonuses);
	BsnsTransactions.Add(Enums.BusinessTransactions.OBEntryVendorBonuses);
	BsnsTransactions.Add(Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.BusinessOperation", BsnsTransactions, DataCompositionComparisonType.InList);
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tự động>';
													|ru = '<автоматически>';
													|en = '<automatically>'; fa = '<automatically>';
													|it = '<автоматически>';
													|pl = '<automatically>';
													|tr = '<otomatik olarak>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	Items.SettlementsWithPartnersARAPDocument.Visible   = Object.RecordInOperationalAccounting;
	
	FillInServiceAttributesOfCalculationsWithPartnersTable();
	
	If ValueIsFilled(Object.Organization) Then
		CompanyDetails = Common.ObjectAttributesValues(Object.Organization, "ParentCompany, TransactionsUsingParentCompanyAreAllowed");
		ParentCompany = CompanyDetails.ParentCompany;
		TransactionsUsingParentCompanyAreAllowed = CompanyDetails.TransactionsUsingParentCompanyAreAllowed;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceAttributesOfCalculationsWithPartnersTable()
	
	ArrayOfCalculationObjects_ = New Array;
	ArrayOfContracts = New Array;
	For Each TableRow In Object.PartnersARAPAccounting Do
		If ValueIsFilled(TableRow.ARAPObject)
			And ObjectWithOrderOfCalculations(TableRow.ARAPObject) Then
			ArrayOfCalculationObjects_.Add(TableRow.ARAPObject);
		EndIf;
		If ValueIsFilled(TableRow.Contract)
			And TypeOf(TableRow.Contract) = Type("CatalogRef.CounterpartyContracts") Then
			ArrayOfContracts.Add(TableRow.Contract);
		EndIf;
	EndDo;
	
	CalculationProcedures = Common.ObjectsAttributeValue(ArrayOfCalculationObjects_, "ARAPObjectSettings");
	CDArray = Common.ObjectsAttributeValue(ArrayOfContracts, "CentralizedContract");
	
	For Each TableRow In Object.PartnersARAPAccounting Do
		If CalculationProcedures[TableRow.ARAPObject] <> Undefined Then
			TableRow.ARAPObjectSettings = CalculationProcedures[TableRow.ARAPObject];
		Else
			TableRow.ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		EndIf;
		If CDArray[TableRow.Contract] <> Undefined Then
			TableRow.CentralizedContract = CDArray[TableRow.Contract];
		Else
			TableRow.CentralizedContract = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	VisibilityOfFillingByBalances = Not Object.RecordInOperationalAccounting And (Object.PostInFinancialAndTaxAccounting Or  Object.RecordInMA) And Not Object.Patch;
	Items.PartnersARAPAccountingFillInByBalance.Visible = VisibilityOfFillingByBalances;
	
	VisibilityOfManAmount = Object.RecordInOperationalAccounting Or Object.RecordInMA; 
	Items.PartnersARAPAccountingSumMan.Visible = VisibilityOfManAmount;
	
	VisibilityOfLocalSum = Object.RecordInOperationalAccounting Or Object.PostInFinancialAndTaxAccounting; 
	Items.PartnersARAPAccountingSumCompl.Visible = VisibilityOfLocalSum;
	
	Items.SettlementsWithPartnersARAPDocument.Visible    = Object.RecordInOperationalAccounting;

	If ValueIsFilled(Object.Organization)
		And Object.BusinessOperation = Enums.BusinessTransactions.OBEntryVendorAccountsPayable Then
		CurrentAccountingPolicySettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("FinancialAccountingPolicy", Object.Organization, Object.Date);
		Discount_ = CurrentAccountingPolicySettings.AccountingForDiscountedAccountsPayableToVendors;
		Items.PartnersARAPAccountingDiscountingAmount.Visible     = Discount_;
		Items.PartnersARAPAccountingDiscountingAmountCompl.Visible = Discount_ And VisibilityOfLocalSum;
		Items.PartnersARAPAccountingDiscountingAmountMan.Visible  = Discount_ And VisibilityOfManAmount;
	Else
		Items.PartnersARAPAccountingDiscountingAmount.Visible     = False;
		Items.PartnersARAPAccountingDiscountingAmountCompl.Visible = False;
		Items.PartnersARAPAccountingDiscountingAmountMan.Visible  = False;
	EndIf;
	
	Items.PartnersARAPAccountingDeferredIncomeTA.Visible = False;
	Items.PartnersARAPAccountingDeferredExpenseTA.Visible = False;
	
EndProcedure

&AtServer
Procedure SetTitleOfThisForm()
	
	AutoTitle = False;
	
	Title = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Object.Ref,
		Object.Number,
		Object.Date,
		Object.BusinessOperation);
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	If ValueIsFilled(Object.Organization) Then
		CompanyDetails = Common.ObjectAttributesValues(Object.Organization, "ParentCompany, TransactionsUsingParentCompanyAreAllowed");
		ParentCompany = CompanyDetails.ParentCompany;
		TransactionsUsingParentCompanyAreAllowed = CompanyDetails.TransactionsUsingParentCompanyAreAllowed;
	EndIf;
	Object.PartnersARAPAccounting.Clear();
	SetVisibility1();
EndProcedure

&AtServer
Procedure PartnerOnChange(Partner, Counterparty, RowID)
	
	PartnerOnChangeServer(Partner, Counterparty);
	CurrentRow = Object.PartnersARAPAccounting.FindByID(RowID);
	CurrentRow.ARAPObject            = Undefined;
	CurrentRow.ARAPObjectSender = Undefined;
	CurrentRow.Contract                   = Undefined;
	CurrentRow.ARAPObjectSettings           = Undefined;
	CurrentRow.CentralizedContract   = Undefined;
	CurrentRow.DocumentOfARAPAccounting          = Undefined;
	
EndProcedure

&AtServerNoContext
Function CalculateAmounts(Sum, InterestAmount, Currency, ComplCurrency, CurrencyOfMan, DocumentDate, DocumentOfARAPAccounting)
	
	Query = New Query;
	ArrayOfCurrencies = New Array;
	ArrayOfCurrencies.Add(Currency);
	ArrayOfCurrencies.Add(ComplCurrency);
	ArrayOfCurrencies.Add(CurrencyOfMan);
	Query.SetParameter("CurrencyOfMan",         CurrencyOfMan);
	Query.SetParameter("ArrayOfCurrencies",       ArrayOfCurrencies);
	Query.SetParameter("Period",            DocumentDate);
	Query.SetParameter("SourceDocument", DocumentOfARAPAccounting);
	Query.Text = CourseRequestText();
	
	CourseNumerator       = 1;
	CourseDenominator     = 1;
	CourseNumeratorMan    = 1;
	CourseDenominatorMan  = 1;
	CourseNumeratorLocal   = 1;
	CourseDenominatorLocal = 1;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Selection.Currency = Currency Then
			CourseNumerator   = Selection.CourseNumerator;
			CourseDenominator = Selection.CourseDenominator;
		EndIf;
		If Selection.Currency = ComplCurrency Then
			CourseNumeratorLocal   = Selection.CourseNumerator;
			CourseDenominatorLocal = Selection.CourseDenominator;
		EndIf;
		If Selection.Currency = CurrencyOfMan Then
			CourseNumeratorMan   = Selection.CourseNumerator;
			CourseDenominatorMan = Selection.CourseDenominator;
		EndIf;
	EndDo;
	
	If Currency = ComplCurrency Then
		SumCompl          = Sum;
		LocalInterestAmount = InterestAmount;
	Else
		ConversionFactor_ = CourseNumerator * CourseDenominatorLocal / (CourseDenominator * CourseNumeratorLocal);
		SumCompl          = Round(Sum * ConversionFactor_, 2, 1);
		LocalInterestAmount = Round(InterestAmount * ConversionFactor_, 2, 1);
	EndIf;
	
	If Currency = CurrencyOfMan Then
		SumMan          = Sum;
		AmountOfInterestMan = InterestAmount;
	Else
		ConversionFactor_ = CourseNumerator * CourseDenominatorMan / (CourseDenominator * CourseNumeratorMan);
		SumMan          = Round(Sum * ConversionFactor_, 2, 1);
		AmountOfInterestMan = Round(InterestAmount * ConversionFactor_, 2, 1);
	EndIf;
	
	CalculatedAmounts = New Structure();
	CalculatedAmounts.Insert("SumCompl",          SumCompl);
	CalculatedAmounts.Insert("SumMan",           SumMan);
	CalculatedAmounts.Insert("DiscountingAmountCompl", LocalInterestAmount);
	CalculatedAmounts.Insert("DiscountingAmountMan",  AmountOfInterestMan);
	
	Return CalculatedAmounts;
	
EndFunction

&AtServerNoContext
Function CourseRequestText()
	
	Return
	"SELECT
	|	ISNULL(
	|		ISNULL(IntercompanyContracts.Ref, 
	|				CounterpartyContracts.Ref), 
	|		UNDEFINED)                                            AS Contract,
	|	ISNULL(
	|		ISNULL(IntercompanyContracts.Date, 
	|				CounterpartyContracts.Date), 
	|		&Period)                                                 AS Date,
	|	ISNULL(
	|		ISNULL(IntercompanyContracts.ContractRateOption,
	|				CounterpartyContracts.ContractRateOption), 
	|		VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption,
	|	ISNULL(
	|		ISNULL(IntercompanyContracts.ARAPCurrency,
	|				CounterpartyContracts.ARAPCurrency), 
	|		SourceDocument.Currency)                                AS ARAPCurrency,
	|	SourceDocument.Currency                                     AS DocumentCurrency,
	|	SourceDocument.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	SourceDocument.Ref                                     AS Document,
	|	SourceDocument.SourceDocumentType                     AS SourceDocumentType
	|INTO ContractData
	|FROM
	|	Document.SourceDocument AS SourceDocument
	|		LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
	|		ON SourceDocument.Contract = IntercompanyContracts.Ref
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON SourceDocument.Contract = CounterpartyContracts.Ref
	|WHERE
	|	SourceDocument.Ref = &SourceDocument
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SourceDocument.Ref AS Ref,
	|	SourceDocument.Date AS DateOfCourse,
	|	DocumentCurrenciesAndRates.DocumentCurrency AS DocumentCurrency,
	|	DocumentCurrenciesAndRates.ARAPCurrency AS ARAPCurrency,
	|	DocumentCurrenciesAndRates.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentCurrenciesAndRates.RateARAPCurrencyNumerator AS RateARAPCurrencyNumerator,
	|	DocumentCurrenciesAndRates.RateARAPCurrencyDenominator AS RateARAPCurrencyDenominator,
	|	DocumentCurrenciesAndRates.RateManagementAccountingCurrencyNumerator AS RateManagementAccountingCurrencyNumerator,
	|	DocumentCurrenciesAndRates.RateManagementAccountingCurrencyDenominator AS RateManagementAccountingCurrencyDenominator,
	|	DocumentCurrenciesAndRates.RateDocumentCurrencyNumerator AS RateDocumentCurrencyNumerator,
	|	DocumentCurrenciesAndRates.RateDocumentCurrencyDenominator AS RateDocumentCurrencyDenominator
	|INTO TTFixedRate
	|FROM
	|	Document.SourceDocument AS SourceDocument
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON SourceDocument.ARAPObject = ARAPObjects.Ref
	|		INNER JOIN ContractData AS ContractData
	|		ON SourceDocument.Contract = ContractData.Contract
	|		INNER JOIN InformationRegister.DocumentCurrenciesAndRates AS DocumentCurrenciesAndRates
	|		ON SourceDocument.Ref = DocumentCurrenciesAndRates.Document
	|WHERE
	|	ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|	AND ContractData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContractData.ARAPCurrency           AS Currency,
	|	ContractData.LocalAccountingCurrency AS BaseCurrency,
	|	RatesByContracts.Period                       AS DateOfCourse,
	|	RatesByContracts.CourseNumerator                AS CourseNumerator,
	|	RatesByContracts.CourseDenominator              AS CourseDenominator
	|FROM
	|	ContractData AS ContractData
	|	INNER JOIN InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(
	|				&Period,
	|				Contract IN
	|					(SELECT
	|						ContractData.Contract
	|					FROM
	|						ContractData)) AS RatesByContracts
	|		ON ContractData.Contract = RatesByContracts.Contract
	|WHERE
	|	ContractData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|	AND (ContractData.DocumentCurrency = ContractData.LocalAccountingCurrency
	|		OR NOT ContractData.SourceDocumentType IN (VALUE(Enum.SourceDocumentTypes.PaymentFromCustomer),
	|		                                                VALUE(Enum.SourceDocumentTypes.PaymentToVendor)))
	|UNION ALL
	|
	|SELECT
	|	RelativeCourses.Currency          AS Currency,
	|	RelativeCourses.BaseCurrency   AS BaseCurrency,
	|	RelativeCourses.Period          AS DateOfCourse,
	|	RelativeCourses.CourseNumerator   AS CourseNumerator,
	|	RelativeCourses.CourseDenominator AS CourseDenominator
	|FROM
	|	ContractData AS ContractData
	|	INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|				&Period,
	|				Currency IN (&ArrayOfCurrencies)
	|				AND BaseCurrency IN (SELECT ContractData.LocalAccountingCurrency FROM ContractData)) AS RelativeCourses
	|		ON ContractData.LocalAccountingCurrency = RelativeCourses.BaseCurrency
	|WHERE
	|	NOT(ContractData.ARAPCurrency = RelativeCourses.Currency
	|				AND ContractData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND (ContractData.DocumentCurrency = ContractData.LocalAccountingCurrency
	|					OR NOT ContractData.SourceDocumentType IN (VALUE(Enum.SourceDocumentTypes.PaymentFromCustomer),
	|		                                                            VALUE(Enum.SourceDocumentTypes.PaymentToVendor))))
	|	AND NOT ContractData.Document IN
	|				(SELECT
	|					T.Ref
	|				FROM
	|					TTFixedRate AS T)
	|
	|UNION ALL
	|
	|SELECT
	|	TTFixedRate.DocumentCurrency                AS Currency,
	|	TTFixedRate.LocalAccountingCurrency AS BaseCurrency,
	|	TTFixedRate.DateOfCourse                      AS DateOfCourse,
	|	TTFixedRate.RateDocumentCurrencyNumerator   AS CourseNumerator,
	|	TTFixedRate.RateDocumentCurrencyDenominator AS CourseDenominator
	|FROM
	|	TTFixedRate AS TTFixedRate
	|
	|UNION ALL
	|
	|SELECT
	|	TTFixedRate.ARAPCurrency                AS Currency,
	|	TTFixedRate.LocalAccountingCurrency      AS BaseCurrency,
	|	TTFixedRate.DateOfCourse                           AS DateOfCourse,
	|	TTFixedRate.RateARAPCurrencyNumerator   AS CourseNumerator,
	|	TTFixedRate.RateARAPCurrencyDenominator AS CourseDenominator
	|FROM
	|	TTFixedRate AS TTFixedRate
	|
	|UNION ALL
	|
	|SELECT
	|	&CurrencyOfMan                                                    AS Currency,
	|	TTFixedRate.LocalAccountingCurrency            AS BaseCurrency,
	|	TTFixedRate.DateOfCourse                                 AS DateOfCourse,
	|	TTFixedRate.RateManagementAccountingCurrencyNumerator   AS CourseNumerator,
	|	TTFixedRate.RateManagementAccountingCurrencyDenominator AS CourseDenominator
	|FROM
	|	TTFixedRate AS TTFixedRate
	|
	|UNION ALL
	|
	|SELECT
	|	TTFixedRate.LocalAccountingCurrency AS Currency,
	|	TTFixedRate.LocalAccountingCurrency AS BaseCurrency,
	|	TTFixedRate.DateOfCourse                      AS DateOfCourse,
	|	1                                                  AS CourseNumerator,
	|	1                                                  AS CourseDenominator
	|FROM
	|	TTFixedRate AS TTFixedRate
	|";
	
EndFunction

&AtServerNoContext
Procedure PartnerOnChangeServer(Partner, Counterparty)
	
	If Partner = Catalogs.Partners.OurEnterprise 
		And TypeOf(Counterparty) <> Type("CatalogRef.Companies") Then
		Counterparty = Catalogs.Companies.EmptyRef();
	Else
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetParametersForSelectingSettlementDocument(NameOfCalculationDocumentElement, TableRow, CreateNewAccessValue = False)
	
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	TheseAreRemnantsOfAdvance = Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer")
	                   Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor");
	ArrayOfCalculationDocumentParameters = New Array;
	CompanyArray = New Array;
	CompanyArray.Add(Object.Organization);
	If TableRow.CentralizedContract 
		And (ParentCompany = Object.Organization
			And (TheseAreRemnantsOfAdvance
					And TableRow.ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")
				Or Not TheseAreRemnantsOfAdvance
					And TableRow.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts"))
			Or ParentCompany <> Object.Organization
				And TheseAreRemnantsOfAdvance
				And (TableRow.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByOrders")
					Or TableRow.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice"))) Then
		CommonClientServer.SupplementArray(CompanyArray, AvailableCompaniesContracts(TableRow.Contract, Object.Organization), True);
		CompanyArray.Add(ParentCompany);
	ElsIf Not TableRow.CentralizedContract
		And ParentCompany <> Object.Organization
		And TheseAreRemnantsOfAdvance 
		And TableRow.ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments") Then
		CompanyArray.Add(ParentCompany);
	EndIf;
	ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.Organization",          New FixedArray(CompanyArray)));
	ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.Partner",              TableRow.Partner));
	ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.Counterparty",           TableRow.Counterparty));
	ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.ARAPCurrency", TableRow.ARAPCurrency));
	
	If Not CreateNewAccessValue Then
		ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.Date",        Object.Date));
	EndIf;
	
	If TypeOf(TableRow.ARAPObject) = Type("CatalogRef.CounterpartyContracts") Then
		ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.ARAPObjectSettings", TableRow.ARAPObjectSettings));
	ElsIf TypeOf(TableRow.ARAPObject) = Type("DocumentRef.SourceDocument") Then
		ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.ARAPObjectSettings", TableRow.ARAPObjectSettings));
	ElsIf TableRow.ARAPObject = Undefined Then
		ArrayOfARAPObjectsSettings = New Array;
		ArrayOfARAPObjectsSettings.Add(PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice"));
		ArrayOfARAPObjectsSettings.Add(PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice"));
		ArrayOfARAPObjectsSettings.Add(PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments"));
		
		ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.ARAPObjectSettings", New FixedArray(ArrayOfARAPObjectsSettings)));
	ElsIf ValueIsFilled(TableRow.ARAPObjectSettings)
		And TypeOf(TableRow.ARAPObject) <> Type("CatalogRef.Complaints")
		And TypeOf(TableRow.ARAPObject) <> Type("CatalogRef.GiftCertificates") Then 
		ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.ARAPObjectSettings", TableRow.ARAPObjectSettings));
	EndIf;
	If ValueIsFilled(TableRow.Contract) Then
		ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.Contract", TableRow.Contract));
	EndIf;
	
	ArrayOfPrimaryDocumentTypes = New Array;
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable") Then
		If TypeOf(TableRow.ARAPObject) <> Type("DocumentRef.MaterialProviderOrder2_5")
			Or Not UseTollManufacturing2_5 Then
		ArrayOfPrimaryDocumentTypes.Add(PredefinedValue("Enum.SourceDocumentTypes.SaleToCustomer"));
		EndIf;
		If TypeOf(TableRow.ARAPObject) <> Type("DocumentRef.SalesOrder")
			And TypeOf(TableRow.ARAPObject) <> Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
			And UseTollManufacturing2_5 Then
			ArrayOfPrimaryDocumentTypes.Add(PredefinedValue("Enum.SourceDocumentTypes.ReportToMaterialProvider"));
		EndIf;
		ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.SourceDocumentType", New FixedArray(ArrayOfPrimaryDocumentTypes)));
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer") Then
		ArrayOfPrimaryDocumentTypes.Add(PredefinedValue("Enum.SourceDocumentTypes.PaymentFromCustomer"));
		ArrayOfPrimaryDocumentTypes.Add(PredefinedValue("Enum.SourceDocumentTypes.SaleAdjustment"));
		ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.SourceDocumentType", New FixedArray(ArrayOfPrimaryDocumentTypes)));
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryVendorAccountsPayable") Then
		If TypeOf(TableRow.ARAPObject) <> Type("DocumentRef.SubcontractOrder2_5")
			Or Not UseProductionByThirdParty2_5 Then
		ArrayOfPrimaryDocumentTypes.Add(PredefinedValue("Enum.SourceDocumentTypes.PurchaseFromVendor"));
		EndIf;
		If TypeOf(TableRow.ARAPObject) <> Type("DocumentRef.PurchaseOrder")
			And UseProductionByThirdParty2_5 Then
			ArrayOfPrimaryDocumentTypes.Add(PredefinedValue("Enum.SourceDocumentTypes.SubcontractorReport"));
		EndIf;
		ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.SourceDocumentType", New FixedArray(ArrayOfPrimaryDocumentTypes)));
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor") Then
		ArrayOfPrimaryDocumentTypes.Add(PredefinedValue("Enum.SourceDocumentTypes.PaymentToVendor"));
		ArrayOfPrimaryDocumentTypes.Add(PredefinedValue("Enum.SourceDocumentTypes.PurchaseAdjustment"));
		ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.SourceDocumentType", New FixedArray(ArrayOfPrimaryDocumentTypes)));
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerBonuses") Then
		ArrayOfPrimaryDocumentTypes.Add(PredefinedValue("Enum.SourceDocumentTypes.CustomerBonusCertificate"));
		ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.SourceDocumentType", New FixedArray(ArrayOfPrimaryDocumentTypes)));
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryVendorBonuses") Then
		ArrayOfPrimaryDocumentTypes.Add(PredefinedValue("Enum.SourceDocumentTypes.VendorBonusCertificate"));
		ArrayOfCalculationDocumentParameters.Add(New ChoiceParameter("Filter.SourceDocumentType", New FixedArray(ArrayOfPrimaryDocumentTypes)));
	EndIf;
	
	Items[NameOfCalculationDocumentElement].ChoiceParameters = New FixedArray(ArrayOfCalculationDocumentParameters);
	
EndProcedure

&AtServerNoContext
Function AvailableCompaniesContracts(Contract, CurrentOrganization)
	
	Result = New Array;
	
	Query = New Query;
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("Organization", CurrentOrganization);
	Query.Text = 
		"SELECT
		|	CounterpartyContractsBranchOffices_.Organization AS Organization,
		|	CounterpartyContractsBranchOffices_.Ref.Organization AS ParentCompany
		|FROM
		|	Catalog.CounterpartyContracts.BranchOffices_ AS CounterpartyContractsBranchOffices_
		|WHERE
		|	CounterpartyContractsBranchOffices_.Ref = &Contract
		|	AND CASE
		|			WHEN CounterpartyContractsBranchOffices_.Ref.Organization <> &Organization
		|				THEN CounterpartyContractsBranchOffices_.Ref.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed
		|			ELSE TRUE
		|		END";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Add(Selection.Organization);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetParametersForSelectingCounterpartySPartnerAndFieldHeaders()

	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerBonuses
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer Then
		
		ParametersArray = New Array;
		ChoiceParameter   = New ChoiceParameter("Filter.Client", True);
		
		ParametersArray.Add(ChoiceParameter);
		
		If UseCustomerInvoiceIntercompany Then
			
			ChoiceParameter = New ChoiceParameter("SetSelectionByPartnerTypeAsOR", True);
			ParametersArray.Add(ChoiceParameter);
			
			ChoiceParameter = New ChoiceParameter("Filter.OurEnterprise", True);
			ParametersArray.Add(ChoiceParameter);
			
		EndIf;
		
		Items.PartnersARAPAccountingPartner.ChoiceParameters = New FixedArray(ParametersArray);
		Items.PartnersARAPAccountingPartner.Title       = NStr("vi = 'Khách hàng';
																|ru = 'Клиент';
																|en = 'Customer'; fa = 'مشتری';
																|it = 'Cliente';
																|pl = 'Klient';
																|tr = 'Müşteri'");
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OBEntryVendorAccountsPayable
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor Then
		
		ParametersArray = New Array;
		ChoiceParameter   = New ChoiceParameter("Filter.Vendor", True);
		
		ParametersArray.Add(ChoiceParameter);
		
		If UseCustomerInvoiceIntercompany Then
			
			ChoiceParameter = New ChoiceParameter("SetSelectionByPartnerTypeAsOR", True);
			ParametersArray.Add(ChoiceParameter);
			
			ChoiceParameter = New ChoiceParameter("Filter.OurEnterprise", True);
			ParametersArray.Add(ChoiceParameter);
			
		EndIf;
		
		Items.PartnersARAPAccountingPartner.ChoiceParameters = New FixedArray(ParametersArray);
		Items.PartnersARAPAccountingPartner.Title       = NStr("vi = 'Nhà cung cấp';
																|ru = 'Поставщик';
																|en = 'Vendor'; fa = 'تأمین‌کننده';
																|it = 'Fornitore';
																|pl = 'Dostawca';
																|tr = 'Tedarikçi'");
		
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor Then
		
		Items.PartnersARAPAccountingPaymentDate.Title = NStr("vi = 'Ngày thanh lý';
															|ru = 'Дата погашения';
															|en = 'Repayment date'; fa = 'تاریخ بازپرداخت';
															|it = 'Дата погашения';
															|pl = 'Repayment date';
															|tr = 'Geri ödeme tarihi'");
		
	EndIf;
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		
		Items.PartnersARAPAccountingCounterparty.ChoiceParameterLinks = New FixedArray(New Array);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInCurrencyOfSettlementsInLine(String)

	If Not ValueIsFilled(String.ARAPCurrency) And Not UseMultipleCurrencies Then
		String.ARAPCurrency = LocalAccountingCurrency;
	EndIf;

EndProcedure

&AtClient
Procedure InitializeCounterpartyInLine(String, NewRow, Copy)
	
	If NewRow And Not Copy Then
		String.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearNumberAndDateOfCalculationObjects()
	
	For Each Item In Object.PartnersARAPAccounting Do
		Item.NumberOfARAPDocument = "";
		Item.APARDocumentDate = Date(1,1,1);
	EndDo;
	
EndProcedure

&AtClient
Procedure CheckAttributesOfSelectedValue(ValueSelected, StandardProcessing, CurrentData = Undefined)
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		ARAPDocument = ValueSelected.Object;
		If ValueIsFilled(ARAPDocument) And Not ValueIsFilled(ValueSelected.ARAPObject) Then
			// Created an AR/AP object with incorrect details
			StandardProcessing = False;
			WarningText = NStr("vi = '""%1"" không tương ứng với điều kiện lựa chọn';
								|ru = '""%1"" не соответствует условиям выбора';
								|en = '""%1"" does not meet the selection criteria'; fa = '""%1"" does not meet the selection criteria';
								|it = '""%1"" не соответствует условиям выбора';
								|pl = '""%1"" does not meet the selection criteria';
								|tr = '""%1"" seçim koşullarıyla eşleşmiyor'");
			WarningText = StrTemplate(WarningText, String(ARAPDocument));
			ShowMessageBox(, WarningText);
		EndIf;
		If Not ValueSelected.Property("CentralizedContract")
			And ValueIsFilled(ValueSelected.Contract)
			And TypeOf(ValueSelected.Contract) = Type("CatalogRef.CounterpartyContracts") Then
			ValueSelected.Insert("CentralizedContract", GeneralPurposeTMServerCall.ObjectAttributeValue(ValueSelected.Contract, "CentralizedContract"));
		EndIf;
	Else
		ARAPDocument = ValueSelected;
	EndIf;
	If ValueIsFilled(ARAPDocument) 
		And TypeOf(ARAPDocument) = Type("DocumentRef.SourceDocument") Then
		If TypeOf(ValueSelected) = Type("Structure") Then
			AttributesOfPrimaryDocument = ValueSelected;
		Else 
			AttributesOfPrimaryDocument = GeneralPurposeTMServerCall.ObjectAttributesValues(ValueSelected, "Date, ARAPCurrency");
		EndIf;
		If CurrentData <> Undefined
			And TypeOf(ValueSelected) <> Type("Structure")
			And AttributesOfPrimaryDocument.ARAPCurrency <> CurrentData.ARAPCurrency Then
			StandardProcessing = False;
			WarningText = NStr("vi = '""%1"" - tiền tệ hạch toán của chứng từ hạch toán được chọn khác với tiền tệ hạch toán của đối tượng hạch toán';
								|ru = '""%1"" - валюта взаиморасчетов выбираемого расчетного документа отличается от валюты взаиморасчетов объекта расчетов';
								|en = '""%1"": the AR/AP currency of the selected AR/AP document differs from the AR/AP currency of the AR/AP object'; fa = '""%1"": the AR/AP currency of the selected AR/AP document differs from the AR/AP currency of the AR/AP object';
								|it = '""%1"" - валюта взаиморасчетов выбираемого расчетного документа отличается от валюты взаиморасчетов объекта расчетов';
								|pl = '""%1"": the AR/AP currency of the selected AR/AP document differs from the AR/AP currency of the AR/AP object';
								|tr = '""%1"" - seçilen alacak/borç belgesinin mutabakatlarının para birimi, alacak/borç nesnesinin mutabakatlarının para biriminden farklıdır'");
			WarningText = StrTemplate(WarningText, String(ValueSelected));
			ShowMessageBox(, WarningText);
		ElsIf AttributesOfPrimaryDocument.Date > EndOfDay(Object.Date) Then
			StandardProcessing = False;
			WarningText = NStr("vi = '""%1"" - ngày chứng từ được chọn không thể lớn hơn ngày nhập số dư đầu';
								|ru = '""%1"" - дата выбираемого документа не может быть больше даты ввода начальных остатков';
								|en = '""%1"": the selected document date cannot be later than the date of opening balance entry'; fa = '""%1"": the selected document date cannot be later than the date of opening balance entry';
								|it = '""%1"" - дата выбираемого документа не может быть больше даты ввода начальных остатков';
								|pl = '""%1"": the selected document date cannot be later than the date of opening balance entry';
								|tr = '""%1"" - seçilen belgenin tarihi ilk bakiyelerin girildiği tarihten büyük olamaz'");
			WarningText = StrTemplate(WarningText, ARAPDocument);
			ShowMessageBox(, WarningText);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPObjectStartChoice(Item, CurrentRow, PaymentType_, SelectAccountsReceivable)
	
	FilterValues = New Structure;
	FilterValues.Insert("PaymentType_", PaymentType_);
	FilterValues.Insert("Organization", Object.Organization);
	If ValueIsFilled(CurrentRow.Counterparty) Then
		FilterValues.Insert("Counterparty",  CurrentRow.Counterparty);
	EndIf;
	If ValueIsFilled(CurrentRow.Partner) Then
		FilterValues.Insert("Partner", CurrentRow.Partner);
	EndIf;
	
	SelectionSettings_ = New Structure;
	SelectionSettings_.Insert("RecordBranches", False);
	SelectionSettings_.Insert("SelectingThePaymentBasis", False);
	SelectionSettings_.Insert("EditableDocument", Object.Ref);
	SelectionSettings_.Insert("Currency", CurrentRow.ARAPCurrency);
	SelectionSettings_.Insert("Filter", FilterValues);
	SelectionSettings_.Insert("ReturnStructure", True);
	SelectionSettings_.Insert("SelectAccountsReceivable", SelectAccountsReceivable);
	SelectionSettings_.Insert("OBEntry", True);
	SelectionSettings_.Insert("BusinessOperation", Object.BusinessOperation);
	SelectionSettings_.Insert(
		"ChoosingAdvancePayment", 
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor"));
	If ValueIsFilled(CurrentRow.ARAPObjectSender) Then
		SelectionSettings_.Insert("CurrentValue", CurrentRow.ARAPObjectSender);
	EndIf;
	
	OpenForm("Catalog.ARAPObjects.Form.ChoiceForm", SelectionSettings_, Item);
	
EndProcedure

&AtClient
Procedure ARAPObjectAutoComplete(Text, ChoiceData, CurrentRow, StandardProcessing, PaymentType_, SelectAccountsReceivable)
	
	If ValueIsFilled(Text) Then
		StandardProcessing = False;
		SelectionSettings_ = ARAPAccountingClientServer.SelectionDataSelectionStructure();
		SelectionSettings_.EditableDocument          = Object.Ref;
		SelectionSettings_.SelectAccountsReceivable = SelectAccountsReceivable; 
		SelectionSettings_.RecordBranches               = False; 
		SelectionSettings_.Organization                    = Object.Organization;
		SelectionSettings_.PaymentType_                    = PaymentType_;
		SelectionSettings_.Text                          = Text;
		SelectionSettings_.Counterparty                     = CurrentRow.Counterparty;
		SelectionSettings_.Partner                        = CurrentRow.Partner;
		SelectionSettings_.OBEntry                   = True;
		SelectionSettings_.BusinessTransactionOfEnteringBalances = Object.BusinessOperation;
		SelectionSettings_.ChoosingAdvancePayment = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor");
		
		ARAPAccountingServerCall.ObjectOfCalculationsBasisOfPaymentProcessingOfReceiptOfSelectionData(
			ChoiceData, 
			SelectionSettings_, 
			False,
			True);
	EndIf;

EndProcedure

&AtClient
Procedure CalculationObjectSelectionProcessing(ValueSelected, CurrentRow, StandardProcessing)
	
	CheckAttributesOfSelectedValue(ValueSelected, StandardProcessing, CurrentRow);
	
	If StandardProcessing Then
		StandardProcessing = False;
		FillPropertyValues(
			CurrentRow, 
			ValueSelected,,
			"Partner, Counterparty");
		If Not (ValueSelected.Property("FeeViaEndCustomers") And ValueSelected.FeeViaEndCustomers)
			And Not (ValueSelected.Property("ItIsAllowedToWorkWithSubsidiaryPartners") And ValueSelected.ItIsAllowedToWorkWithSubsidiaryPartners) Then
			CurrentRow.Partner = ValueSelected.Partner;
		EndIf;
		If Not (ValueSelected.Property("FeeViaEndCustomers") And ValueSelected.FeeViaEndCustomers) Then
			CurrentRow.Counterparty = ValueSelected.Counterparty;
		EndIf;
		CurrentRow.ARAPObjectSender = ValueSelected.ARAPObject;
		CurrentRow.ARAPObject = ValueSelected.Object;
		If TypeOf(ValueSelected.Object) = Type("DocumentRef.SourceDocument") Then
			CurrentRow.DocumentOfARAPAccounting = ValueSelected.Object;
		Else 
			CurrentRow.DocumentOfARAPAccounting = PredefinedValue("Document.SourceDocument.EmptyRef");
		EndIf;
		ARAPObjectProcessingSelectionOnServer(CurrentRow.GetID());
	EndIf;
	
EndProcedure

&AtServer
Procedure ARAPObjectProcessingSelectionOnServer(RowID)
	
	CurrentRow = Object.PartnersARAPAccounting.FindByID(RowID);
	
	If ValueIsFilled(CurrentRow.ARAPObject)
		And ObjectWithOrderOfCalculations(CurrentRow.ARAPObject) Then
		CurrentRow.ARAPObjectSettings = Common.ObjectAttributeValue(CurrentRow.ARAPObject, "ARAPObjectSettings");
	EndIf;
	
	CalculationResult2 = CalculateAmounts(CurrentRow.Sum,
	                     ?(CurrentRow.Property("DiscountingAmount"), CurrentRow.DiscountingAmount, 0),
	                     CurrentRow.ARAPCurrency, 
	                     LocalAccountingCurrency, 
	                     ManagementAccountingCurrency, 
	                     Object.Date,
	                     CurrentRow.DocumentOfARAPAccounting);
	CurrentRow.SumCompl = CalculationResult2.SumCompl;
	CurrentRow.SumMan = CalculationResult2.SumMan;
	
EndProcedure

&AtClient
Procedure ARAPObjectCreating(Item, StandardProcessing)
	StandardProcessing = False;
	CurrentData = Item.Parent.CurrentData;
	OpeningParameters = New Structure;
	OpeningParameters.Insert("BusinessOperation", Object.BusinessOperation);
	OpeningParameters.Insert("TheseAreSettlementsBetweenOrganizations", CurrentData.Partner = PredefinedValue("Catalog.Partners.OurEnterprise"));
	OpeningParameters.Insert("ThisIsRetailBuyer", CurrentData.Partner = PredefinedValue("Catalog.Partners.RetailCustomer"));
	CallbackDescription = New CallbackDescription("ARAPObjectCreationProcessingOfTypeSelection", ThisObject);
	OpenForm("Document.OBEntryARAP.Form.TypeChoiceForm", OpeningParameters, Item,,,, CallbackDescription);
EndProcedure 

&AtClient
Procedure ARAPObjectCreationProcessingOfTypeSelection(Result, AdditionalParameters)Export 
	If Result <> Undefined Then
		CurrentData = Items.PartnersARAPAccounting.CurrentData;
		FillingValues = New Structure;
		FillingValues.Insert("Organization", Object.Organization);
		FillingValues.Insert("Counterparty", CurrentData.Counterparty);
		FillingValues.Insert("Partner", CurrentData.Partner);
		FillingValues.Insert("ConductComplaintARAP", True);
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer") Then
			FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"));
			FillingValues.Insert("ThisIsClaimToVendor", False);
		ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor") Then
			FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier"));
			FillingValues.Insert("ThisIsClaimToVendor", True);
		ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable") Then
			FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"));
			FillingValues.Insert("ThisIsClaimToVendor", False);
		ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryVendorAccountsPayable") Then
			FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier"));
			FillingValues.Insert("ThisIsClaimToVendor", True);
		ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerBonuses") Then
			FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerBonuses"));
			FillingValues.Insert("ConductComplaintARAP", False);
			FillingValues.Insert("ThisIsClaimToVendor", False);
		EndIf;
		ParametersStructure = New Structure;
		ParametersStructure.Insert("FillingValues", FillingValues);
		ParametersStructure.Insert("NotifyAboutCreationOfCalculationObject", True);
		If TypeOf(Result) = Type("Structure") Then
			MetadataObjectName = Result.MetadataObjectName;
			FillingValues.Insert("SourceDocumentType", Result.SourceDocumentType);
		Else
			MetadataObjectName = Result;
		EndIf;
		OpenForm(MetadataObjectName + ".ObjectForm", ParametersStructure, Items.PartnersARAPAccountingARAPObjectSender);
	EndIf;
EndProcedure

&AtServerNoContext
Procedure ProcessingOfReceivingDataOfPrimaryDocumentSelection(ChoiceData, ChoiceParameters, StandardProcessing)
	
	If Not ValueIsFilled(ChoiceParameters.SearchString) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 10
	|	Table.Ref,
	|	Table.DeletionMark
	|FROM
	|	Document.SourceDocument AS Table
	|WHERE
	|	Table.Number LIKE &SearchString
	|	AND &FilterConditions
	|";
	
	TextOfFilterConditions = New Array;
	TextOfFilterConditions.Add("TRUE");
	For Each FilterCriterion In ChoiceParameters.Filter Do 
		TemplateText = "%1 = &%1"; // @query-part
		If TypeOf(FilterCriterion.Value) = Type("FixedArray") Then
			TemplateText = "%1 IN (&%1)"; // @query-part
		ElsIf TypeOf(FilterCriterion.Value) = Type("Date") Then
			TemplateText = "%1 <= (&%1)"; // @query-part
		EndIf;
		TextOfFilterConditions.Add(StrTemplate(TemplateText, FilterCriterion.Key));
		Query.SetParameter(FilterCriterion.Key, FilterCriterion.Value);
	EndDo;
	Query.Text = StrReplace(Query.Text, "&FilterConditions", StrConcat(TextOfFilterConditions, " AND ")); // @query-part-2
	
	Query.SetParameter("SearchString", ChoiceParameters.SearchString + "%");
	Result = Query.Execute();
	SelectionDetailRecords = Result.Select();
	
	List = New ValueList;
	While SelectionDetailRecords.Next() Do
		Structure = New Structure;
		Structure.Insert("Value", SelectionDetailRecords.Ref);
		Structure.Insert("DeletionMark", SelectionDetailRecords.DeletionMark);
		
		List.Add(Structure);
	EndDo;
	
	ChoiceData = List;
	
EndProcedure

&AtServerNoContext
Function ObjectWithOrderOfCalculations(Ref)
	
	Return TypeOf(Ref) <> Type("DocumentRef.ExpenseReport") 
		And TypeOf(Ref) <> Type("DocumentRef.ElectronicTicketTransaction")
		And TypeOf(Ref) <> Type("DocumentRef.IntercompanyGoodsReturn")
		And TypeOf(Ref) <> Type("DocumentRef.ReturnOfGoodsToVendor")
		And TypeOf(Ref) <> Type("DocumentRef.PaymentCardTransaction")
		
		
		And TypeOf(Ref) <> Type("CatalogRef.LeaseContract")
		And TypeOf(Ref) <> Type("DocumentRef.BankAccountReceiptNote")
		And TypeOf(Ref) <> Type("DocumentRef.CashAccountReceiptNote")
		And TypeOf(Ref) <> Type("DocumentRef.CashVoucher")
		And TypeOf(Ref) <> Type("DocumentRef.BankAccountIssue")
		And TypeOf(Ref) <> Type("CatalogRef.LoanAndDepositContracts")
		And TypeOf(Ref) <> Type("CatalogRef.Complaints");
	
EndFunction

&AtServer
Procedure FillByBalancesOnServer()
	
	TabPart = FormAttributeToValue("Object.PartnersARAPAccounting");
	TabPart.Clear();
	
	KeyFields = Documents.OBEntryARAP.KeyFieldsOfLocalAccountingByTypeOfOperation(Object.BusinessOperation);
	Filter        = New Structure;
	
	For Each KeyField In KeyFields Do
		If Not KeyField = "Organization" And ValueIsFilled(Object[KeyField]) Then
			Filter.Insert(KeyField, Object[KeyField]);
		EndIf;
	EndDo;
	
	Balance = Documents.OBEntryARAP.BalancesByTypeOfOperation(Object.Date, Object.BusinessOperation, Object.Organization, Filter);
	
	For Each Var_91_Balance In Balance Do
		Page1 = TabPart.Add();
		FillPropertyValues(Page1, Var_91_Balance);
	EndDo;
	
EndProcedure

&AtClient
Procedure AlertHandlerIssueFillInByBalances(QuestionResult, AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillByBalancesOnServer();
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
