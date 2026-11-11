
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	
	Items.GroupEnterBalanceBy.Visible = GetFunctionalOption("UseLocal");
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	              ThisObject, "Partner", NStr("vi = 'Đối tác';
												|ru = 'Контрагент';
												|en = 'Counterparty'; fa = 'طرف حساب';
												|it = 'Controparte';
												|pl = 'Counterparty';
												|tr = 'Cari hesap'"));
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
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
	ReadContractCurrency();
	OnReadCreateAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ReadContractCurrency();
	SetTitleOfThisForm();
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("BusinessOperation", Object.BusinessOperation);
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
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
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
	
	SetContractSelectionParameters();
	OrganizationWhenChangedOnServer();
	
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
	
		DocumentCorrectionClient.StringFixHandlingNavigationLinks(
			ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSettlementsOnCreditsDeposits

&AtClient
Procedure SettlementsOnCreditsDepositsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.SettlementsOnCreditsDeposits.CurrentData;
	If Item.CurrentItem.Name = "AmountType" And CurrentData <> Undefined Then
		ChoiceList = Item.CurrentItem.ChoiceList;
		ChoiceList.Clear();
		ChoiceList.Add(PredefinedValue("Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt"));
		ChoiceList.Add(PredefinedValue("Enum.LoanAndDepositScheduleAmountTypes.Interests"));
		If CurrentData.ContractKind = PredefinedValue("Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing") Then
			ChoiceList.Add(PredefinedValue("Enum.LoanAndDepositScheduleAmountTypes.Fee"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettlementsOnCreditsDepositsOnStartEdit(Item, NewRow, Copy)

	SetContractSelectionParameters();
	CurrentData = Items.SettlementsOnCreditsDeposits.CurrentData;
	If NewRow And Not Copy Then
		CurrentData.AmountType = PredefinedValue("Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt");
	EndIf;

EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	CurrentData = Items.SettlementsOnCreditsDeposits.CurrentData;
	PartnerWhenChangesAreMadeOnServer(CurrentData.Partner, CurrentData.Counterparty);
	SetContractSelectionParameters();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	SetContractSelectionParameters();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)

	CurrentData = Items.SettlementsOnCreditsDeposits.CurrentData;
	ContractData = ContractDetails_(CurrentData.Contract);
	FillPropertyValues(CurrentData,ContractData);
	If ContractData.ContractKind <> PredefinedValue("Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing") Then
		CurrentData.AmountType = PredefinedValue("Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt");
	EndIf;

EndProcedure

&AtClient
Procedure SumOnChange(Item)

	CurrentData = Items.SettlementsOnCreditsDeposits.CurrentData;
	CalculateAmounts(
		CurrentData.Sum,
		CurrentData.SumCompl,
		CurrentData.SumMan,
		CurrentData.ARAPCurrency);

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
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure FillInByBalance(Command)
	If Object.FinancialInstrumentsARAP.Count() Then
		AlertQuestionFillInByBalances = New CallbackDescription("AlertHandlerIssueFillInByBalances", ThisObject);
		QueryText = NStr("vi = 'Khi điền, dữ liệu hiện tại của phần bảng sẽ bị xóa. Tiếp tục?';
						|ru = 'При заполнении текущие данные табличной части будут очищены. Продолжить?';
						|en = 'Current table data will be cleared. Continue?'; fa = 'Current table data will be cleared. Continue?';
						|it = 'I dati correnti della parte tabulare verranno cancellati durante la compilazione. Continuare?';
						|pl = 'Przy wypełnieniu bieżące dane części tabelarycznej będą oczyszczone. Kontynuować?';
						|tr = 'Tablo bölümünün mevcut verileri tamamlandığında silinecektir. Devam edilsin mi?'");
		ShowQueryBox(AlertQuestionFillInByBalances, QueryText, QuestionDialogMode.YesNo,,,  NStr("vi = 'Nhập số dư kế toán theo hoạt động';
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
Procedure OnReadCreateAtServer()
	
	SetVisibility1();
	SetTitleOfThisForm();
	
EndProcedure

&AtServer
Procedure SetTitleOfThisForm()
	
	AutoTitle = False;
	
	Title = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Object.Ref,
		Object.Number,
		Object.Date,
		Object.BusinessOperation);
	
EndProcedure

&AtServerNoContext
Procedure PartnerWhenChangesAreMadeOnServer(Partner, Counterparty)
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
EndProcedure

&AtClient
Procedure SetContractSelectionParameters()

	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameter("Filter.DeletionMark",False));
	
	If ValueIsFilled(Object.Organization) Then
		ParametersArray.Add(New ChoiceParameter("Filter.Organization", Object.Organization));
	EndIf;
	CurrentData = Items.SettlementsOnCreditsDeposits.CurrentData;
	If CurrentData <> Undefined Then
		If ValueIsFilled(CurrentData.Partner) Then
			ParametersArray.Add(New ChoiceParameter("Filter.Partner", CurrentData.Partner));
		EndIf;
		If ValueIsFilled(CurrentData.Counterparty) Then
			ParametersArray.Add(New ChoiceParameter("Filter.Counterparty", CurrentData.Counterparty));
		EndIf;
	EndIf;
	Items.Contract.ChoiceParameters = New FixedArray(ParametersArray);

EndProcedure

&AtServerNoContext
Function ContractDetails_(Contract)

	Return Common.ObjectAttributesValues(Contract,"Partner,Counterparty,ARAPCurrency,ContractKind");

EndFunction

&AtServer
Procedure ReadContractCurrency()
	
	ArrayOfContracts = Object.FinancialInstrumentsARAP.Unload(,"Contract").UnloadColumn("Contract");
	SetPrivilegedMode(True);
	ContractData_ = Common.ObjectsAttributesValues(ArrayOfContracts, "ARAPCurrency, ContractKind");
	SetPrivilegedMode(False);
	For Each TableRow In Object.FinancialInstrumentsARAP Do
		If ContractData_[TableRow.Contract] <> Undefined Then
			FillPropertyValues(TableRow, ContractData_[TableRow.Contract]);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateAmounts(Sum, SumCompl, SumMan, ARAPCurrency)
	
	DocumentDate = Object.Date;
	
	If ARAPCurrency = LocalAccountingCurrency Then
		SumCompl = Sum;
	Else
		ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			ARAPCurrency, LocalAccountingCurrency, DocumentDate);
		SumCompl = Round(Sum * ConversionFactor_, 2, 1);
	EndIf;
	If ARAPCurrency = ManagementAccountingCurrency Then
		SumMan = Sum;
	Else
		ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			ARAPCurrency, ManagementAccountingCurrency, DocumentDate);
		SumMan = Round(Sum * ConversionFactor_, 2, 1);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Items.SettlementsOnCreditsDepositsFillInByBalance.Visible = 
		Not Object.RecordInOperationalAccounting And (Object.PostInFinancialAndTaxAccounting Or Object.RecordInMA) And Not Object.Patch;
		
	Items.SumCompl.Visible = Object.RecordInOperationalAccounting Or Object.PostInFinancialAndTaxAccounting;
	Items.SumMan.Visible = Object.RecordInOperationalAccounting Or Object.RecordInMA;
	
	Items.DeferredIncomeTA.Visible = False;
	Items.DeferredExpenseTA.Visible = False;
	
EndProcedure
&AtServer
Procedure FillByBalancesOnServer()
	
	TabPart = FormAttributeToValue("Object.FinancialInstrumentsARAP");
	TabPart.Clear();
	KeyFields = Documents.OBEntryFinancialInstruments.KeyFieldsOfLocalAccountingByTypeOfOperation(Object.BusinessOperation);
	Filter = New Structure;
	For Each KeyField In KeyFields Do
		If Not KeyField = "Organization" And ValueIsFilled(Object[KeyField]) Then
			Filter.Insert(KeyField, Object[KeyField]);
		EndIf;
	EndDo;
	
	Balance = Documents.OBEntryFinancialInstruments.BalancesByTypeOfOperation(Object.Date, Object.BusinessOperation, Object.Organization, Filter);
	
	For Each Var_24_Balance In Balance Do
		Page1 = TabPart.Add();
		FillPropertyValues(Page1, Var_24_Balance);
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
