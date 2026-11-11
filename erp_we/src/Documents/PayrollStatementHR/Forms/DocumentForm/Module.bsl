
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
		
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	FormEventDocumentsPayrollAndHumanResourcesServerOverridable.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands  
	
	SetVisibilityAvailabilityOnClient();
	
	If ValueIsFilled(ResultAddress) Then
		UpdateAmountsOnClient(ResultAddress);
		ResultAddress = "";
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates    
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	FormEventDocumentsPayrollAndHumanResourcesServerOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// Handler of the "Date-change" mechanism
	CurrentObject.AdditionalProperties.Insert("CheckingDateWhenChangesWereBanned", True);

	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
		
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventDocumentsPayrollAndHumanResourcesClientOverridable.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	FormEventDocumentsPayrollAndHumanResourcesServerOverridable.BeforeWriteAtServer(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SetVisibilityAvailabilityATServer();
	
	FormEventDocumentsPayrollAndHumanResourcesServerOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	FormEventDocumentsPayrollAndHumanResourcesClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventDocumentsPayrollAndHumanResourcesClientOverridable.NotificationProcessing(ThisObject, Object.Ref, EventName, 
	Parameter, Source);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi

	If Not ValueIsFilled(Object.DateOfPayment) Then
		Object.DateOfPayment = Object.Date;

		If Object.Content.Count() > 0 Then
			CheckFillOutDocument(True);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure DateOfPaymentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi

	If Object.Content.Count() > 0 Then
		CheckFillOutDocument(True);
	EndIf;

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)

	If Object.Content.Count() > 0 Then
		CheckFillOutDocument(True);
	EndIf;

EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)

	If Object.Content.Count() > 0 Then
		CheckFillOutDocument();
	EndIf;

EndProcedure

&AtClient
Procedure PaymentMethodHROnChange(Item)
	
	SetVisibilityAvailabilityOnClient();
	
EndProcedure

&AtClient
Procedure KindOfPaymentOnChange(Item)
	
	If Object.Content.Count()>0 Then
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.OK, NStr("ru = 'Пересчитать';
												|vi = 'Recalculate';
												|en = 'Recalculate'; fa = 'محاسبه مجدد';
												|it = 'Recalculate';
												|pl = 'Recalculate';
												|tr = 'Yeniden hesapla'"));
		Buttons.Add(DialogReturnCode.Cancel);
		QueryText = NStr("ru = 'При смене вида выплаты суммы к выплате будут пересчитаны. Продолжить?';
						|vi = 'If the payment kind is changed, the amounts to be paid will be recalculated. Continue?';
						|en = 'If the payment kind is changed, the amounts to be paid will be recalculated. Continue?'; fa = 'If the payment kind is changed, the amounts to be paid will be recalculated. Continue?';
						|it = 'If the payment kind is changed, the amounts to be paid will be recalculated. Continue?';
						|pl = 'If the payment kind is changed, the amounts to be paid will be recalculated. Continue?';
						|tr = 'Ödeme türü değiştirildiğinde ödenecek tutarlar yeniden hesaplanacaktır. Devam edilsin mi?'");
		Handler = New CallbackDescription("ContinueExecutingCommandsAfterChangingTypeOfPayment", ThisObject);
		ShowQueryBox(Handler, QueryText, Buttons);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersContent

&AtClient
Procedure ContentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueIsFilled(ValueSelected) Then
		If TypeOf(ValueSelected) = Type("CatalogRef.Persons") Then
			
			Item.CurrentData.Individual = ValueSelected;
			
			ArrayOfEmployees = New Array;
			ArrayOfEmployees.Add(ValueSelected);
			
			StartCalculationForEmployeesClient(ArrayOfEmployees);
			
		ElsIf TypeOf(ValueSelected) = Type("Array") Then
			
			For Each Individual In ValueSelected Do
				NewRow = Object.Content.Add();
				NewRow.Individual = Individual;
			EndDo;
			
			StartCalculationForEmployeesClient(ValueSelected);
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ContentIndividualStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	ParametersForOpeningSelection = New Structure();
	ParametersForOpeningSelection.Insert("Organization", Object.Organization);
	If ValueIsFilled(Object.Department) Then
		ParametersForOpeningSelection.Insert("Department", Object.Department);
	EndIf;
	ParametersForOpeningSelection.Insert("Period", EndOfDay(Object.Date));
	ParametersForOpeningSelection.Insert("MultipleChoice", False);
	ParametersForOpeningSelection.Insert("AddressOfListOfSelectedEmployees", AddressOfListOfSelectedPersons());
	
	DocumentsPayrollAndHumanResourcesClient.PersonsOfEmployeesSelection(ThisObject, ParametersForOpeningSelection, Items.Content);
	
EndProcedure

&AtClient
Procedure ContentIndividualOnChange(Item)
	
	ArrayOfEmployees = New Array;
	ArrayOfEmployees.Add(Items.Content.CurrentData.Individual);
	StartCalculationForEmployeesClient(ArrayOfEmployees);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region AttachableCommands

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands

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

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure Pickup(Command)
	
	ParametersForOpeningSelection = New Structure();
	ParametersForOpeningSelection.Insert("Organization", Object.Organization);
	If ValueIsFilled(Object.Department) Then
		ParametersForOpeningSelection.Insert("Department", Object.Department);
	EndIf;
	ParametersForOpeningSelection.Insert("Period", EndOfDay(Object.Date));
	ParametersForOpeningSelection.Insert("MultipleChoice", True);
	ParametersForOpeningSelection.Insert("AddressOfListOfSelectedEmployees", AddressOfListOfSelectedPersons());
	
	DocumentsPayrollAndHumanResourcesClient.PersonsOfEmployeesSelection(ThisObject, ParametersForOpeningSelection, Items.Content);
	
EndProcedure

&AtClient
Procedure FillInDocument(Command)

	If UsePaymentRequests And Not ValueIsFilled(Object.Department) Then
		ErrorText = NStr(
			"ru = 'Включено использование заявок на расходование денежных средств. Поле ""Подразделение"" обязательно для заполнения.';
			|vi = 'Payment requests are enabled. The ""Business unit"" field is required.';
			|en = 'Payment requests are enabled. The ""Business unit"" field is required.'; fa = 'Payment requests are enabled. The ""Business unit"" field is required.';
			|it = 'Payment requests are enabled. The ""Business unit"" field is required.';
			|pl = 'Payment requests are enabled. The ""Business unit"" field is required.';
			|tr = 'Nakit harcama talepleri kullanımı etkinleştirilmiştir. ""Departman"" alanının doldurulması zorunludur.'");
		CommonClient.MessageToUser(ErrorText, ,"Object.Department");
		Return;
	EndIf;

	CheckFillOutDocument();

EndProcedure

&AtClient
Procedure RecalculateDocument(Command)
	
	StartCalculationForEmployeesClient();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CheckFillOutDocument(UpdateHeader = False)

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("UpdateHeader", UpdateHeader);

	If Object.Ref.IsEmpty() Then
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.OK, NStr("vi = 'Ghi lại và tiếp tục';
												|ru = 'Записать и продолжить';
												|en = 'Save and continue'; fa = 'Save and continue';
												|it = 'Registrare e continuare';
												|pl = 'Zapisz i kontynuuj';
												|tr = 'Kaydet ve devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);
		QueryText = NStr("ru = 'Перед выполнением команды документ необходимо записать. Продолжить?';
						|vi = 'To perform this command, save the document. Continue?';
						|en = 'To perform this command, save the document. Continue?'; fa = 'To perform this command, save the document. Continue?';
						|it = 'To perform this command, save the document. Continue?';
						|pl = 'To perform this command, save the document. Continue?';
						|tr = 'Komut çalıştırılmadan önce belgenin kaydedilmesi gerekmektedir. Devam edilsin mi?'");
		Handler = New CallbackDescription("ProceedRunningCommandAfterRecordConfirmed", ThisObject,
			AdditionalParameters);
		ShowQueryBox(Handler, QueryText, Buttons);
		Return;
	EndIf;

	If Object.Content.Count() > 0 Then
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.OK, NStr("ru = 'Перезаполнить документ';
												|vi = 'Refill the document';
												|en = 'Refill the document'; fa = 'Refill the document';
												|it = 'Refill the document';
												|pl = 'Refill the document';
												|tr = 'Belgeyi yeniden doldu'"));
		Buttons.Add(DialogReturnCode.Cancel);
		QueryText = NStr("ru = 'В табличной части есть данные, они будут очищены. Продолжить?';
						|vi = 'The data in the table will be cleared. Continue?';
						|en = 'The data in the table will be cleared. Continue?'; fa = 'The data in the table will be cleared. Continue?';
						|it = 'The data in the table will be cleared. Continue?';
						|pl = 'The data in the table will be cleared. Continue?';
						|tr = 'Tablo kısmında veriler var, bunlar temizlenecek. Devam edilsin mi?'");
		Handler = New CallbackDescription("ContinueExecutingCommandsAfterCleaning", ThisObject,
			AdditionalParameters);
		ShowQueryBox(Handler, QueryText, Buttons);
		Return;
	EndIf;

	StartFillingInClientDocument(UpdateHeader);

EndProcedure

&AtClient
Procedure StartFillingInClientDocument(UpdateHeader)

	ProcessingResult = StartFillingATServer(UpdateHeader);

	If ProcessingResult.BackgroundExecution Then
		CallbackOnCompletion = New CallbackDescription("ProcessFillingResult", ThisObject);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(ProcessingResult.TimeConsumingOperation, CallbackOnCompletion,
			IdleParameters);
	Else
		If ProcessingResult.Error Then
			EventLogClient.AddMessageForEventLog(NStr("ru = 'Заполнение документа';
														|vi = 'Fill in document';
														|en = 'Fill in document'; fa = 'پرکردن سند';
														|it = 'Fill in document';
														|pl = 'Fill in document';
														|tr = 'Belge doldurma'"),
				ProcessingResult.Level, ProcessingResult.ErrorText);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure StartCalculationForEmployeesClient(ArrayOfEmployees = Undefined)

	If ArrayOfEmployees = Undefined Then
		ArrayOfEmployees = New Array;
	EndIf;

	ProcessingResult = StartCalculationAtServer(ArrayOfEmployees);

	If ProcessingResult.BackgroundExecution Then
		CallbackOnCompletion = New CallbackDescription("ProcessCalculationResult", ThisObject);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(ProcessingResult.TimeConsumingOperation, CallbackOnCompletion,
			IdleParameters);
	Else
		If ProcessingResult.Error Then
			EventLogClient.AddMessageForEventLog(NStr("ru = 'Расчет задолженности';
														|vi = 'Debt calculation';
														|en = 'Debt calculation'; fa = 'Debt calculation';
														|it = 'Debt calculation';
														|pl = 'Debt calculation';
														|tr = 'Borç hesaplama'"),
				ProcessingResult.Level, ProcessingResult.ErrorText);
		EndIf;
	EndIf;

EndProcedure

&AtServer
Function StartFillingATServer(UpdateHeader)
	
	If UpdateHeader Then
		Object.Currency = SettingsValueCached.DefaultBaseCurrency();
		If Object.PaymentMethodHR = Enums.PaymentMethodsHR.EmployeeSBankAccount Then
			BankAccount = CashServer.GetOrganizationSDefaultBankAccount();
			Object.Bank = Common.ObjectAttributeValue(BankAccount, "Owner");
		EndIf;
	EndIf;
	
	Result = New Structure;
	Result.Insert("BackgroundExecution", False);
	Result.Insert("Error", False);
	Result.Insert("Level", "Information");
	Result.Insert("ErrorText", "");
	
	DataParameters = GetParametersForFillInRequest();
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
	TimeConsumingOperations.FunctionExecutionParameters(UUID), 
	"DocumentsPayrollAndHumanResourcesServer.GetFillingDataForIndividuals", 
	DataParameters);
	
	Result.Insert("BackgroundExecution", True);
	Result.Insert("TimeConsumingOperation", TimeConsumingOperation);
	
	ResultAddress = TimeConsumingOperation.ResultAddress;
	
	Return Result;
	
EndFunction

&AtServer
Function StartCalculationAtServer(ArrayOfEmployees)
	
	Result = New Structure;
	Result.Insert("BackgroundExecution", False);
	Result.Insert("Error", False);
	Result.Insert("Level", "Information");
	Result.Insert("ErrorText", "");
	
	If ArrayOfEmployees.Count() = 0 Then
		ArrayOfEmployees = Object.Content.Unload(,"Individual").UnloadColumn("Individual");
	EndIf;
	
	If ArrayOfEmployees.Count() = 0 Then
		Result.Insert("Error", True);
		Result.Insert("ErrorText", NStr("ru = 'Нет данных для расчета';
										|vi = 'No data for calculation';
										|en = 'No data for calculation'; fa = 'No data for calculation';
										|it = 'No data for calculation';
										|pl = 'No data for calculation';
										|tr = 'Hesaplama için veri yok'"));
		Return Result;
	EndIf;
	
	DataParameters = GetParametersForFillInRequest(ArrayOfEmployees);
	If ArrayOfEmployees.Count() > 10 Then
		TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		TimeConsumingOperations.FunctionExecutionParameters(UUID), 
		"DocumentsPayrollAndHumanResourcesServer.GetCalculationDataForIndividuals", 
		DataParameters);
		
		Result.Insert("BackgroundExecution", True);
		Result.Insert("TimeConsumingOperation", TimeConsumingOperation);
		
		ResultAddress = TimeConsumingOperation.ResultAddress;
	Else
		Try
			PaymentData = DocumentsPayrollAndHumanResourcesServer.GetCalculationDataForIndividuals(DataParameters);
		Except
			Result.Insert("Error", True);
			Result.Insert("Level", "Error");
			Result.Insert("ErrorText", ErrorDescription());
			Return Result;
		EndTry;
		UpdateAmountsATServer(PutToTempStorage(PaymentData));
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function GetParametersForFillInRequest(ArrayOfEmployees = Undefined)
	
	DataParameters = New Structure;
	DataParameters.Insert("Period", Object.Date);
	DataParameters.Insert("PeriodLimit", New Boundary(New PointInTime(Object.Date, Object.Ref), BoundaryType.Excluding));
	DataParameters.Insert("Organization", Object.Organization);
	DataParameters.Insert("Department", Object.Department);
	
	DataParameters.Insert("ArrayOfEmployees", ArrayOfEmployees);

	DataParameters.Insert("GetDebts", True);
	DataParameters.Insert("GetAdvance", Object.KindOfPayment = Enums.SalaryPaymentKinds.Prepayment_);
	DataParameters.Insert("GetBankAccount", Object.PaymentMethodHR = Enums.PaymentMethodsHR.EmployeeSBankAccount);
	DataParameters.Insert("Bank", Object.Bank);
	
	Return DataParameters;
	
EndFunction

&AtClient
Procedure ProcessFillingResult(ProcessingResult, AdditionalParameters) Export

	If ProcessingResult = Undefined Then
		Return;
	EndIf;

	If ProcessingResult.Status = "Error" Then
		EventLogClient.AddMessageForEventLog(NStr("ru = 'Заполнение документа';
													|vi = 'Fill in document';
													|en = 'Fill in document'; fa = 'پرکردن سند';
													|it = 'Fill in document';
													|pl = 'Fill in document';
													|tr = 'Belge doldurma'"), "Error",
			ProcessingResult.DetailErrorDescription);
		TextErrors = NStr("ru = 'Ошибка заполнения документа:';
							|vi = 'Document filling error:';
							|en = 'Document filling error:'; fa = 'Document filling error:';
							|it = 'Document filling error:';
							|pl = 'Document filling error:';
							|tr = 'Belge doldurma hatası:'") + ProcessingResult.BriefErrorDescription;
		CommonClient.MessageToUser(TextErrors);
		Return;
	EndIf;

	Object.Content.Clear();
	Result = GetFromTempStorage(ProcessingResult.ResultAddress);

	For Each KeyAndValue In Result Do
		CompositionRow = Object.Content.Add();
		CompositionRow.Individual = KeyAndValue.Key;
		FillPropertyValues(CompositionRow, KeyAndValue.Value);
		If Object.KindOfPayment = PredefinedValue("Enum.SalaryPaymentKinds.Prepayment_") Then
			CompositionRow.ToBePaid = KeyAndValue.Value.Prepayment_;
		EndIf;
	EndDo;

EndProcedure 

&AtClient
Procedure ProcessCalculationResult(ProcessingResult, AdditionalParameters) Export

	If ProcessingResult = Undefined Then
		Return;
	EndIf;

	If ProcessingResult.Status = "Error" Then
		EventLogClient.AddMessageForEventLog(NStr("ru = 'Расчет задолженности';
													|vi = 'Debt calculation';
													|en = 'Debt calculation'; fa = 'Debt calculation';
													|it = 'Debt calculation';
													|pl = 'Debt calculation';
													|tr = 'Borç hesaplama'"),
			ProcessingResult.LevelPresentation, ProcessingResult.ErrorText);
		Return;
	EndIf;

	UpdateAmountsOnClient(ProcessingResult.ResultAddress);

EndProcedure 

&AtClient
Procedure UpdateAmountsOnClient(ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	
	For Each KeyAndValue In Result Do
		CompositionLines = Object.Content.FindRows(New Structure("Individual", KeyAndValue.Key));
		If CompositionLines.Count()>0 Then
				FillPropertyValues(CompositionLines[0], KeyAndValue.Value);
		EndIf;
	EndDo;
	
	Debt_Total = Object.Content.Total("Debt");
	
EndProcedure

&AtServer
Procedure UpdateAmountsATServer(ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	
	Modified = True;
	
	For Each KeyAndValue In Result Do
		CompositionLines = Object.Content.FindRows(New Structure("Individual", KeyAndValue.Key));
		If CompositionLines.Count()>0 Then
				FillPropertyValues(CompositionLines[0], KeyAndValue.Value);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ProceedRunningCommandAfterRecordConfirmed(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.OK Then
		ClearMessages();
		
		WriteMode = DocumentWriteMode.Write;
		
		Write(New Structure("WriteMode", WriteMode));
		
		If Object.Ref.IsEmpty() Or Modified Then
			Return;// The recording failed, the platform displays messages about the reasons.
		EndIf;
		
		CheckFillOutDocument(AdditionalParameters.UpdateHeader);
		
	ElsIf Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueExecutingCommandsAfterCleaning(Response, AdditionalParameters) Export

	If Response = DialogReturnCode.OK Then
		ClearMessages();

		Object.Content.Clear();
		Debt_Total = 0;

		CheckFillOutDocument(AdditionalParameters.UpdateHeader);

	ElsIf Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;

EndProcedure

&AtClient
Procedure ContinueExecutingCommandsAfterChangingTypeOfPayment(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.OK Then
		
		ClearMessages();
		StartCalculationForEmployeesClient();
		
	ElsIf Response = DialogReturnCode.Cancel Then
		
		If Object.KindOfPayment = PredefinedValue("Enum.SalaryPaymentKinds.Prepayment_") Then
			Object.KindOfPayment = PredefinedValue("Enum.SalaryPaymentKinds.Salary");
		Else
			Object.KindOfPayment = PredefinedValue("Enum.SalaryPaymentKinds.Prepayment_");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function AddressOfListOfSelectedPersons()
	
	SelectedPersons = CommonClientServer.CollapseArray(
	Object.Content.Unload( , "Individual").UnloadColumn("Individual"));
	
	Return PutToTempStorage(SelectedPersons, UUID);
	
EndFunction

&AtServer
Procedure OnReadCreateAtServer()

	UsePaymentRequests = GetFunctionalOption(
		"UsePaymentRequests");
	SetVisibilityAvailabilityATServer();

EndProcedure

&AtClient
Procedure SetVisibilityAvailabilityOnClient()
	
	Items.ContentAccrued.Visible = Object.KindOfPayment = PredefinedValue("Enum.SalaryPaymentKinds.Prepayment_");
	
	PaymentViaBank = 
	Object.PaymentMethodHR = PredefinedValue("Enum.PaymentMethodsHR.EmployeeSBankAccount");
	
	Items.Bank.Visible = PaymentViaBank;
	Items.ContentBankAccount.Visible = PaymentViaBank;
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityATServer()

	Items.ContentAccrued.Visible = Object.KindOfPayment = PredefinedValue(
		"Enum.SalaryPaymentKinds.Prepayment_");

	Items.Department.AutoMarkIncomplete = UsePaymentRequests;
	If Not Items.Find("FormDocumentPaymentRequestToCreateOnBasisOfStatementsForPayment")
		= Undefined Then
		Items.FormDocumentPaymentRequestToCreateOnBasisOfStatementsForPayment.Visible = UsePaymentRequests;
	EndIf;

	PaymentViaBank = Object.PaymentMethodHR = PredefinedValue(
		"Enum.PaymentMethodsHR.EmployeeSBankAccount");

	Items.Bank.Visible = PaymentViaBank;
	Items.ContentBankAccount.Visible = PaymentViaBank;

	If Not Items.Find("FormDocumentOutgoingPaymentBankAccountBeCreatedOnBasisOfStatementsOnPaymentHR")
		= Undefined Then
		Items.FormDocumentOutgoingPaymentBankAccountBeCreatedOnBasisOfStatementsOnPaymentHR.Visible = PaymentViaBank
			And Not UsePaymentRequests;
	EndIf;

	If Not Items.Find(
		"FormDocumentIsOutgoPaymentCashAccountToCreateOnBasisOfPayrollStatementsForPaymentOfHR") = Undefined Then
		Items.FormDocumentIsOutgoPaymentCashAccountToCreateOnBasisOfPayrollStatementsForPaymentOfHR.Visible = Not PaymentViaBank
			And Not UsePaymentRequests;
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
	ElsIf Item.Name = "sh_ShamsiInput_DateOfPayment" Then
		DateOfPaymentOnChange(Items.DateOfPayment);
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
