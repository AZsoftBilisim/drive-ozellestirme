
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ChangeHeaderByOperationType();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
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
Procedure OperationTypeOnChange(Item)
	
	TypeOfOperationWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure TypeOfOperationWhenChangingOnServer()
	
	ChangeHeaderByOperationType();
	
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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	ChangeHeaderByOperationType();
	
EndProcedure

&AtServer
Procedure ChangeHeaderByOperationType()

	Creating = NStr("vi = '(tạo)';
					|ru = '(создание)';
					|en = '(Create)'; fa = '(Create)';
					|it = '(creazione)';
					|pl = '(utworzenie)';
					|tr = '(oluştur)'");
	TransactionTypes = Enums.PeriodEndTransactionsTypesFinancialAccounting;
	If Object.OperationType = TransactionTypes.ClosingOfGLAccountsOfIncomeAndExpenses Then
		If ValueIsFilled(Object.Ref) Then
			Title = StrTemplate(
							InternationalReportingServerCall.PresentationOfClosingIncomeExpenses(),
							Object.Number,
							Object.Date);
		Else
			Title = InternationalReportingServerCall.PresentationOfClosingIncomeExpenses(False) + " " + Creating;
		EndIf;
		
	ElsIf Object.OperationType = TransactionTypes.ExchangeDifferenceCalculationFunctionalCurrency Then
		If ValueIsFilled(Object.Ref) Then
			Title = StrTemplate(
							InternationalReportingServerCall.PresentationCalculationOfExchangeDifferencesInFunctionalCurrency(),
							Object.Number,
							Object.Date);
		Else
			Title = InternationalReportingServerCall.PresentationCalculationOfExchangeDifferencesInFunctionalCurrency(False) + " " + Creating;
		EndIf;
		
	ElsIf Object.OperationType = TransactionTypes.ExchangeDifferenceCalculationPresentationCurrency Then
		If ValueIsFilled(Object.Ref) Then
			Title = StrTemplate(
							InternationalReportingServerCall.PresentationCalculationOfExchangeDifferencesCurrencyOfPresentation(),
							Object.Number,
							Object.Date);
		Else
			Title = InternationalReportingServerCall.PresentationCalculationOfExchangeDifferencesCurrencyOfPresentation(False) + " " + Creating;
		EndIf;
		
	Else
		
		If ValueIsFilled(Object.Ref) Then
			Title = StrTemplate(
									NStr("vi = 'Hoạt động theo lịch trình (kế toán quốc tế) %1 từ %2';
										|ru = 'Регламентная операция (международный учет) %1 от %2';
										|en = 'Period-end transaction — Financial accounting %1 from %2'; fa = 'Period-end transaction — Financial accounting %1 from %2';
										|it = 'Operazione di manutenzione (contabilità internazionale) %1 del %2';
										|pl = 'Operacja reglamentowana (ewidencja międzynarodowa) %1 z dnia %2';
										|tr = 'Dönem sonu işlemi (uluslararası muhasebe) %1 %2 itibaren'"),
									Object.Number,
									Object.Date);
		Else
			Title = NStr("vi = 'Hoạt động theo lịch trình (kế toán quốc tế) (sáng tạo)';
						|ru = 'Регламентная операция (международный учет) (создание)';
						|en = 'Period-end transaction — Financial accounting (create)'; fa = 'Period-end transaction — Financial accounting (create)';
						|it = 'Operazione di manutenzione (contabilità internazionale) (creazione)';
						|pl = 'Operacja reglamentowana (ewidencja międzynarodowa) (utworzenie)';
						|tr = 'Dönem sonu işlemi - Finansal muhasebe (oluşturma)'");
		EndIf;
		
	EndIf;
	
EndProcedure

#Region StandardSubsystems_AdditionalReportingAndProcessing

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
