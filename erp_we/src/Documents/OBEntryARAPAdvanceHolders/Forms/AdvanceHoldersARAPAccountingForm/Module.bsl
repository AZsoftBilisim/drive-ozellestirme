
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	
	Items.GroupEnterBalanceBy.Visible = GetFunctionalOption("UseLocal");
	
	SetTitleOfThisForm();
	
	If Not ValueIsFilled(Object.Ref) Then 
		
		OnCreatReadAtServer();
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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
	
	OnCreatReadAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("BusinessOperation", Object.BusinessOperation);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	DocumentCorrectionClient.AfterWrite(Object);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetTitleOfThisForm();
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
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

&AtClient
Procedure OrganizationOnChange(Item)
	OrganizationWhenChangedOnServer();
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAdvanceHoldersARAPAccounting_

&AtClient
Procedure AdvanceHoldersARAPAccounting_OnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.AdvanceHoldersARAPAccounting_.CurrentData;
	FillInCurrencyInLine(Items.AdvanceHoldersARAPAccounting_.CurrentData);
	
EndProcedure

&AtClient
Procedure AdvanceHoldersARAPAccounting_SumOnChange(Item)
	
	SumOnChange(Item);
	
EndProcedure

&AtClient
Procedure AdvanceHoldersARAPAccounting_CurrencyOnChange(Item)
	
	TableRow = Items.AdvanceHoldersARAPAccounting_.CurrentData;
	
	If TableRow.Sum > 0 Then
		SumOnChange(Item);
	EndIf;
	
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
	If Object.AdvanceHoldersARAPAccounting_.Count() Then
		AlertQuestionFillInByBalances = New CallbackDescription("AlertHandlerIssueFillInByBalances", ThisObject);
		QueryText = NStr("vi = 'Khi điền, dữ liệu hiện tại của phần bảng sẽ bị xóa. Tiếp tục?';
						|ru = 'При заполнении текущие данные табличной части будут очищены. Продолжить?';
						|en = 'Current table data will be cleared. Continue?'; fa = 'Current table data will be cleared. Continue?';
						|it = 'I dati correnti della parte tabulare verranno cancellati durante la compilazione. Continuare?';
						|pl = 'Przy wypełnieniu bieżące dane części tabelarycznej będą oczyszczone. Kontynuować?';
						|tr = 'Tablo bölümünün mevcut verileri tamamlandığında silinecektir. Devam edilsin mi?'");
		ShowQueryBox(AlertQuestionFillInByBalances, QueryText, QuestionDialogMode.YesNo,,,  NStr("vi = 'Nhập số dư kế toán tài chính theo dữ liệu của kế toán hoạt động';
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
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.Department.Name);
	
	ValueList = New ValueList;
	ValueList.Add(Enums.BusinessTransactions.OBEntryAdvanceHolderReceivables);
	ValueList.Add(Enums.BusinessTransactions.OBEntryOpenExpenseReportOfEmployees);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.BusinessOperation", ValueList, DataCompositionComparisonType.InList);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtClient
Procedure SumOnChange(Item)
	
	TableRow = Items.AdvanceHoldersARAPAccounting_.CurrentData;
	CalculateAmounts(TableRow.Sum,
		TableRow.SumCompl,
		TableRow.SumMan,
		TableRow.Currency);
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Items.GroupOfAccountablePersons.Title = Object.BusinessOperation;
	
	Items.AdvanceHoldersARAPAccounting_FillInByBalance.Visible = 
		Not Object.RecordInOperationalAccounting And (Object.PostInFinancialAndTaxAccounting Or Object.RecordInMA) And Not Object.Patch;
	Items.AdvanceHoldersARAPAccounting_SumCompl.Visible = Object.RecordInOperationalAccounting Or Object.PostInFinancialAndTaxAccounting;
	Items.AdvanceHoldersARAPAccounting_SumMan.Visible = Object.RecordInOperationalAccounting Or Object.RecordInMA;
	
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
Procedure CalculateAmounts(Sum, SumCompl, SumMan, Currency)
	
	DocumentDate = Object.Date;
	
	If Currency = LocalAccountingCurrency Then
		SumCompl = Sum;
	Else
		ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(Currency, LocalAccountingCurrency, DocumentDate);
		SumCompl = Round(Sum * ConversionFactor_, 2, 1);
	EndIf;
	
	If Currency = ManagementAccountingCurrency Then
		SumMan = Sum;
	Else
		ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(Currency, ManagementAccountingCurrency, DocumentDate);
		SumMan = Round(Sum * ConversionFactor_, 2, 1);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInCurrencyInLine(String)
	
	If Not ValueIsFilled(String.Currency) And Not UseMultipleCurrencies Then
		String.Currency = LocalAccountingCurrency;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillByBalancesOnServer()
	
	TabPart = FormAttributeToValue("Object.AdvanceHoldersARAPAccounting_");
	TabPart.Clear();
	KeyFields = Documents.OBEntryARAPAdvanceHolders.KeyFieldsOfLocalAccountingByTypeOfOperation(Object.BusinessOperation);
	Filter = New Structure;
	For Each KeyField In KeyFields Do
		If Not KeyField = "Organization" And ValueIsFilled(Object[KeyField]) Then
			Filter.Insert(KeyField, Object[KeyField]);
		EndIf;
	EndDo;
	
	Balance = Documents.OBEntryARAPAdvanceHolders.BalancesByTypeOfOperation(Object.Date, Object.BusinessOperation, Object.Organization, Filter);
	
	For Each Var_17_Balance In Balance Do
		Page1 = TabPart.Add();
		FillPropertyValues(Page1, Var_17_Balance);
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
