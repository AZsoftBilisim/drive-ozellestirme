
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
	
	Items.GroupEnterBalanceBy.Visible = GetFunctionalOption("UseLocal");
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	SetTitleOfThisForm();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	If Object.Patch Then
		Items.FillInTheAcquiringCalculationsAccordingToTheReports.Visible = False;
	EndIf;
	
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
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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

#Region FormTableItemsEventHandlersAcquiringContractARAP

&AtServer
Procedure CalculateAmounts(Sum, SumCompl, SumMan, AcquiringContract)
	
	DocumentDate = Object.Date;
	
	Currency = Catalogs.AcquiringContracts.ContractDetails_(AcquiringContract).Currency;
	
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
Procedure OnChangeAttribute()
	
	CurrentRow = Items.AcquiringContractARAP.CurrentData;

	If Not UseMultipleCurrencies Then
		CurrentRow.Currency = LocalAccountingCurrency;
	EndIf;
	
	CalculateAmounts(
		CurrentRow.Sum, 
		CurrentRow.SumCompl, 
		CurrentRow.SumMan, 
		CurrentRow.AcquiringContract); 
		
EndProcedure

&AtClient
Procedure AcquiringContractARAPAcquiringContractOnChange(Item)
	
	CurrentRow = Items.AcquiringContractARAP.CurrentData;

	WhenChangingAgreement(
		CurrentRow.Sum, 
		CurrentRow.SumCompl, 
		CurrentRow.SumMan, 
		CurrentRow.AcquiringContract);
	
		CurrentRow.Currency = ContractCurrency;

EndProcedure
	
&AtClient
Procedure AcquiringContractARAPPOSTerminalOnChange(Item)
	
	OnChangeAttribute();
	
	
EndProcedure

&AtClient
Procedure AcquiringContractARAPSumOnChange(Item)
	
	OnChangeAttribute();
	
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
Procedure FillInWithAcquiringReportData(Command)
	
	If Object.AcquiringContractARAP.Count() > 0 Then
		QueryText = NStr("vi = 'Trước khi thực hiện thao tác, phần bảng sẽ bị xóa. Tiếp tục?';
						|ru = 'Перед выполнением операции табличная часть будет очищена. Продолжить?';
						|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
						|it = 'Prima dell''esecuzione dell''operazione, la parte tabulare sarà cancellata. Continuare?';
						|pl = 'Przed wykonaniem operaji część tabelaryczna będzie oczyszczona. Kontynuować?';
						|tr = 'İşlem gerçekleştirilmeden önce tablo bölümü temizlenecektir. Devam edilsin mi?'");
		ShowQueryBox(New CallbackDescription("FillInWithAcquiringReportDataCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
		Return;
	EndIf;
	
	FillInFragmentAccordingToAcquiringReports();
	
EndProcedure

&AtClient
Procedure FillInWithAcquiringReportDataCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    
    FillInFragmentAccordingToAcquiringReports();

EndProcedure

&AtClient
Procedure FillInFragmentAccordingToAcquiringReports()
    
    FillInWithAcquiringReportDataServer();

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.AcquiringContractARAPPaymentDate.Name);
	
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.RecordInOperationalAccounting", False);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
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
Procedure FillInWithAcquiringReportDataServer()
	
	CurObject = FormAttributeToValue("Object");
	CurObject.FillInAcquiringData();
	ValueToFormAttribute(CurObject, "Object");
	
EndProcedure

&AtServer
Procedure WhenChangingAgreement(Sum, SumCompl, SumMan, AcquiringContract)

	If Not UseMultipleCurrencies Then
		ContractCurrency = LocalAccountingCurrency;
	Else
		ContractCurrency = Catalogs.AcquiringContracts.ContractDetails_(AcquiringContract).Currency;
	EndIf;

	CalculateAmounts(
		Sum, 
		SumCompl, 
		SumMan, 
		AcquiringContract); 
	
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
