
#Region Variables

&AtClient
Var IdleHandlerParameters;

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure


&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Object.Ref) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Cấm tạo trực tác chứng từ dạng này.
			|Đang tạo tự động các chứng từ,
			|khi thực hiện giao dịch thường kỳ đóng tháng tương ứng.';
			|ru = 'Интерактивное создание документов данного вида запрещено.
			|Создание документов выполняется автоматически,
			|при выполнении соответствующей регламентной операции закрытия месяца.';
			|en = 'Interactive document creation of this kind is prohibited. 
			|Documents are created automatically while the corresponding 
			|month-end transaction is executed.'; fa = 'Interactive document creation of this kind is prohibited. 
			|Documents are created automatically while the corresponding 
			|month-end transaction is executed.';
			|it = 'Creazione interattiva dei documenti di questo tipo non è consentita. 
			|Creazione dei documenti viene fatta automaticamente, 
			| durante l''esecuzione della relativa operazione regolamentata di chiusura del mese.';
			|pl = 'Interaktywne tworzenie dokumentów tego typu jest zabronione. 
			| Tworzenie dokumentów wykonuje się automatycznie,
			|podczas wykonania odpowiedniej operacji reglamentowanej zamknięcia miesiąca.';
			|tr = 'Bu tür belgelerin interaktif olarak oluşturulması yasaktır.
			|Belgelerin oluşturulması, ilgili ay sonu kapanış programlı işi
			|gerçekleştirildiğinde otomatik olarak gerçekleştirilir.'"),,,, Cancel);
		Return;
	EndIf;
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FillFormAttributes();
	FillInAdditionalDetailsOfAccountsReceivable();
	
	PeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Date);
	
	SetVisibilityAccessibilityOfElements();
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	FillFormAttributes();
	FillInAdditionalDetailsOfAccountsReceivable();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodPresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PeriodPresentationTuning(Item, Direction, StandardProcessing)
	
	Object.Date = BegOfMonth(Object.Date);
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(Direction, StandardProcessing,
		Object.Date, PeriodPresentation);
	
	Object.Date = EndOfMonth(Object.Date);
	
	WhenChangingDocumentDate();
	
EndProcedure

&AtClient
Procedure PeriodPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("PeriodPresentationStartChoiceCompletion", ThisObject);
	FormParameters = New Structure("Value, PeriodSelectionMode", Object.Date, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection", FormParameters, ThisObject, UUID, , ,
		CloseHandler, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod = Undefined Then
		Return;
	EndIf;
	
	Object.Date = EndOfMonth(SelectedPeriod);
	PeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Date);
	
	WhenChangingDocumentDate();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	FillFormAttributes();
	
	CheckChangesToHeaderDetails();
	
	SetVisibilityAccessibilityOfElements();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccountsReceivable

&AtClient
Procedure AccountsReceivableSelection(Item, RowSelected, Field, StandardProcessing)
	
	StructureShowValue = New Structure("Item,Attribute");
	StructureShowValue.Insert("AccountsReceivableCounterparty", "Counterparty");
	StructureShowValue.Insert("AccountsReceivableContract", "Contract");
	StructureShowValue.Insert("AccountsReceivableARAPDocument", "ARAPDocument");
	StructureShowValue.Insert("AccountsReceivablePartner", "Partner");
	StructureShowValue.Insert("AccountsReceivableLineOfBusiness", "LineOfBusiness");
	StructureShowValue.Insert("AccountsReceivableARAPObject", "ARAPObject");
	
	If Not Item.CurrentData.DebtKind = PredefinedValue("Enum.KindsOfDebt.Other") Then
		Attribute = "";
		If StructureShowValue.Property(Field.Name, Attribute) And ValueIsFilled(Item.CurrentData[Attribute]) Then
			ShowValue(, Item.CurrentData[Attribute]);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccountsReceivableOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		Item.CurrentData.DebtKind = PredefinedValue("Enum.KindsOfDebt.Other");
		Item.CurrentData.RowID = New UUID;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccountsReceivableOnActivateRow(Item)
	
	AccountsReceivableCurrentData = FillInCurDataOfDZ();
	
EndProcedure

&AtClient
Procedure AccountsReceivableBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy And Item.CurrentData <> Undefined Then
		Item.CurrentData.TAReserve = 0;
		Item.CurrentData.TAReserveWithinBorderOfLimit = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccountsReceivableBeforeDeleteRow(Item, Cancel)
	
	AccountsReceivableCurrentDataBeforeRemoval = FillInCurDataOfDZ();
	
EndProcedure

&AtClient
Procedure AccountsReceivableAfterDeleteRow(Item)
	
	AccountsReceivableCurrentData = AccountsReceivableCurrentDataBeforeRemoval;
	If AccountsReceivableCurrentData.AmountOfSecurityByDimension = 0 And AccountsReceivableCurrentData.MutualDebt = 0 Then
		// If the amounts of collateral and counter debt of the deleted line have not been established, then there is nothing to recalculate.
		Return;
	EndIf;
	
	ProcessChangeInAccountsReceivable();
	
EndProcedure

&AtClient
Procedure AccountsReceivableDoNotAccrueOnChange(Item)
	
	AccountsReceivableCurrentData = FillInCurDataOfDZ(); // Updating the Do not charge attribute
	ProcessChangeInAccountsReceivable();
	
EndProcedure

&AtClient
Procedure AccountsReceivablePartnerOnChange(Item)
	
	CurrentData = Items.AccountsReceivable.CurrentData;
	PartnerWhenChangesAreMadeOnServer(CurrentData.Partner, CurrentData.Counterparty);
	
EndProcedure

&AtClient
Procedure AccountsReceivableCounterpartyOnChange(Item)
	
	curData = Items.AccountsReceivable.CurrentData;
	If curData.DebtAmount = 0 Then
		AccountsReceivableCurrentData = FillInCurDataOfDZ();
		Return;
	EndIf;
	
	If AccountsReceivableCurrentData.Counterparty = curData.Counterparty Then
		Return;
	EndIf;
	
	ProcessChangeInAccountsReceivable(); // According to the old counterparty
	ProcessChangeInAccountsReceivable(); // And now for a new counterparty
	
EndProcedure

&AtClient
Procedure AccountsReceivableContractStartChoice(Item, ChoiceData, StandardProcessing)
	
	curData = Items.AccountsReceivable.CurrentData;
	ThisIsCounterparty = TypeOf(curData.Counterparty) = Type("CatalogRef.Counterparties");
	
	Items.AccountsReceivableContract.ChooseType = ThisIsCounterparty;
	
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.CounterpartyContracts"));
	TypesArray.Add(Type("CatalogRef.LoanAndDepositContracts"));
	
	Items.AccountsReceivableContract.TypeRestriction = ?(ThisIsCounterparty,
		New TypeDescription(TypesArray),
		New TypeDescription("CatalogRef.IntercompanyContracts"));
	
EndProcedure

&AtClient
Procedure AccountsReceivableAmountOfDebtLocalOnChange(Item)
	
	If AccountsReceivableCurrentData.AmountOfDebtLocal = Items.AccountsReceivable.CurrentData.AmountOfDebtLocal Then
		Return;
	EndIf;
	
	ProcessChangeInAccountsReceivable();
	
EndProcedure

&AtClient
Procedure AccountsReceivableDebtAmountOnChange(Item)
	
	If AccountsReceivableCurrentData.DebtAmount = Items.AccountsReceivable.CurrentData.DebtAmount Then
		Return;
	EndIf;
	
	ProcessChangeInAccountsReceivable();
	
EndProcedure

&AtClient
Procedure AccountsReceivableAmountOfSecurityByDimensionOnChange(Item)
	
	If AccountsReceivableCurrentData.AmountOfSecurityByDimension = Items.AccountsReceivable.CurrentData.AmountOfSecurityByDimension Then
		Return;
	EndIf;
	
	AccountsReceivableCurrentData = FillInCurDataOfDZ(); // Updating the amount of collateral for analytics
	ProcessChangeInAccountsReceivable();
	
EndProcedure

&AtClient
Procedure AccountsReceivableDateOfDebtOccurrenceOnChange(Item)
	
	curData = Items.AccountsReceivable.CurrentData;
	If AccountsReceivableCurrentData.DateOfDebtOccurrence = curData.DateOfDebtOccurrence Then
		Return;
	EndIf;
	
	FillInTermOfAccountsReceivable(curData);
	
	If Not curData.ManualAdjustment Then
		EvaluationParameters_ = New Structure("Organization,Period", Object.Organization, Object.Date);
		curData.Evaluation = GetEstimate(curData.DebtKind, curData.DoubtfulDebtPeriod, EvaluationParameters_);
	EndIf;
	
	// If the manual adjustment flag is set, then the estimate has not changed and the reserves of the BU do not need to be calculated.
	
	ProcessChangeInAccountsReceivable(Not curData.ManualAdjustment);
	
EndProcedure

&AtClient
Procedure AccountsReceivableEvaluationOnChange(Item)
	
	If AccountsReceivableCurrentData.Evaluation = Items.AccountsReceivable.CurrentData.Evaluation Then
		Return;
	EndIf;
	
	ProcessChangeInAccountsReceivable(, False);
	
EndProcedure

&AtClient
Procedure AccountsReceivableManualAdjustmentOnChange(Item)
	
	curData = Items.AccountsReceivable.CurrentData;
	
	// We process the change of manual adjustment for all lines of current debt.
	
	Dimension = AnalysisOfReservesCalculation();
	FillPropertyValues(Dimension, curData);
	
	EvaluationParameters_ = New Structure("Organization,Period", Object.Organization, Object.Date);
	RatingChanged = False;
	
	FoundRows = Object.AccountsReceivable.FindRows(Dimension);
	For Each FoundRow In FoundRows Do
		FoundRow.ManualAdjustment = curData.ManualAdjustment;
		If FoundRow.ManualAdjustment Then
			// If you decide to install a manual adjustment, then we only affect the conditional design of the form.
			Continue;
		EndIf;
		
		// Otherwise, we restore the estimate.
		
		FoundRow.Evaluation = GetEstimate(FoundRow.DebtKind, FoundRow.DoubtfulDebtPeriod, EvaluationParameters_);
		RatingChanged = True;
	EndDo;
	
	If Not RatingChanged Then
		// The estimate has not changed, there is nothing to recalculate.
		Return;
	EndIf;
	
	ProcessChangeInAccountsReceivable(, False);
	
EndProcedure

&AtClient
Procedure AccountsReceivableCurrencyOnChange(Item)
	
	If AccountsReceivableCurrentData.Currency = Items.AccountsReceivable.CurrentData.Currency Then
		Return;
	EndIf;
	
	ProcessChangeInAccountsReceivable(False, False);
	
EndProcedure

&AtClient
Procedure AccountsReceivableACReserveOnChange(Item)
	
	If AccountsReceivableCurrentData.ACReserve = Items.AccountsReceivable.CurrentData.ACReserve Then
		Return;
	EndIf;
	
	ProcessChangeInAccountsReceivable(False, False);
	
EndProcedure

&AtClient
Procedure AccountsReceivableReserveOnChange(Item)
	
	If AccountsReceivableCurrentData.Reserve = Items.AccountsReceivable.CurrentData.Reserve Then
		Return;
	EndIf;
	
	ProcessChangeInAccountsReceivable(False, False, False);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccountsPayable

&AtClient
Procedure AccountsPayableOnActivateRow(Item)
	
	AccountsPayableCurrentData = FillInCurDataKZ();
	
EndProcedure

&AtClient
Procedure AccountsPayableOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		Item.CurrentData.ManualAdjustment = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccountsPayableBeforeDeleteRow(Item, Cancel)
	
	AccountsPayableCurrentDataBeforeRemoval = FillInCurDataKZ();
	
EndProcedure

&AtClient
Procedure AccountsPayableAfterDeleteRow(Item)
	
	AccountsPayableCurrentData = AccountsPayableCurrentDataBeforeRemoval;
	If AccountsPayableCurrentData.Sum = 0 Then
		// If the amount of accounts payable of the deleted line has not been established, then there is nothing to recalculate.
		Return;
	EndIf;
	
	ProcessChangeInAccountsPayable();
	
EndProcedure

&AtClient
Procedure AccountsPayableManualAdjustmentOnChange(Item)
	
	If Items.AccountsPayable.CurrentData.ManualAdjustment Then
		Return;
	EndIf;
	
	// Restoring the values of the accounts payable line to the values from the database.
	// The current line can be deleted if there is no more debt.
	
	FillInAccountsPayable(Items.AccountsPayable.CurrentRow);
	AccountsPayableCurrentData = FillInCurDataKZ();
	
EndProcedure

&AtClient
Procedure AccountsPayablePartnerOnChange(Item)
	
	CurrentData = Items.AccountsPayable.CurrentData;
	PartnerWhenChangesAreMadeOnServer(CurrentData.Partner, CurrentData.Counterparty);
	
EndProcedure

&AtClient
Procedure AccountsPayableCounterpartyOnChange(Item)
	
	curData = Items.AccountsPayable.CurrentData;
	If curData.Sum = 0 Then
		AccountsPayableCurrentData = FillInCurDataKZ();
		Return;
	EndIf;
	
	If AccountsPayableCurrentData.Counterparty = curData.Counterparty Then
		Return;
	EndIf;
	
	curData.ManualAdjustment = True;
	
	ProcessChangeInAccountsPayable(); // According to the old counterparty
	ProcessChangeInAccountsPayable(); // And now for a new counterparty
	
EndProcedure

&AtClient
Procedure AccountsPayableSumOnChange(Item)
	
	curData = Items.AccountsPayable.CurrentData;
	If AccountsPayableCurrentData.Sum = curData.Sum Then
		Return;
	EndIf;
	
	curData.ManualAdjustment = True;
	
	ProcessChangeInAccountsPayable();
	
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

&AtClient
Procedure TheFillInDocumentCommand(Command)
	
	If Not ReadyToFill() Then
		Return;
	EndIf;
	
	If Object.AccountsReceivable.Count() > 0 Or Object.AccountsPayable.Count() > 0 Then
		NotificationParameters = New Structure("EventName", Command.Name);
		CallbackDescription = New CallbackDescription("QuestionOfUpdatingDocumentEnds", ThisObject, NotificationParameters);
		QueryText = NStr("vi = 'Sẽ cập nhật thông tin nợ, đã lưu các điều chỉnh thủ công. Tiếp tục?';
						|ru = 'Информация о задолженности будет обновлена, ручные корректировки сохранены. Продолжить?';
						|en = 'Debt information will be updated, manual adjustments are saved. Continue?'; fa = 'Debt information will be updated, manual adjustments are saved. Continue?';
						|it = 'I dati sul debito verranno aggiornati, le correzioni manuali saranno salvate. Continuare?';
						|pl = 'Informacje o długach zostaną zaktualizowane, a ręczne korekty zapisane. Kontynuować?';
						|tr = 'Borç bilgileri güncellenecek, manuel düzeltmeler korunacaktır. Devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	Else
		FillInDocumentOnClient("FillInDocument");
	EndIf;
	
EndProcedure

&AtClient
Procedure TheFillInAccountsReceivableCommand(Command)
	
	If Not ReadyToFill() Then
		Return;
	EndIf;
	
	If Object.AccountsReceivable.Count() > 0 Then
		NotificationParameters = New Structure("EventName", Command.Name);
		CallbackDescription = New CallbackDescription("QuestionOfUpdatingDocumentEnds", ThisObject, NotificationParameters);
		QueryText = NStr("vi = 'Sẽ cập nhật thông tin nợ, đã lưu các điều chỉnh thủ công. Tiếp tục?';
						|ru = 'Информация о задолженности будет обновлена, ручные корректировки сохранены. Продолжить?';
						|en = 'Debt information will be updated, manual adjustments are saved. Continue?'; fa = 'Debt information will be updated, manual adjustments are saved. Continue?';
						|it = 'I dati sul debito verranno aggiornati, le correzioni manuali saranno salvate. Continuare?';
						|pl = 'Informacje o długach zostaną zaktualizowane, a ręczne korekty zapisane. Kontynuować?';
						|tr = 'Borç bilgileri güncellenecek, manuel düzeltmeler korunacaktır. Devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	Else
		FillInDocumentOnClient("FillInAccountsReceivable");
	EndIf;
	
EndProcedure

&AtClient
Procedure TheTeamFillOutAccountsPayable(Command)
	
	If Not ReadyToFill() Then
		Return;
	EndIf;
	
	If Object.AccountsPayable.Count() > 0 Then
		NotificationParameters = New Structure("EventName", Command.Name);
		CallbackDescription = New CallbackDescription("QuestionOfUpdatingDocumentEnds", ThisObject, NotificationParameters);
		QueryText = NStr("vi = 'Sẽ cập nhật thông tin nợ, đã lưu các điều chỉnh thủ công. Tiếp tục?';
						|ru = 'Информация о задолженности будет обновлена, ручные корректировки сохранены. Продолжить?';
						|en = 'Debt information will be updated, manual adjustments are saved. Continue?'; fa = 'Debt information will be updated, manual adjustments are saved. Continue?';
						|it = 'I dati sul debito verranno aggiornati, le correzioni manuali saranno salvate. Continuare?';
						|pl = 'Informacje o długach zostaną zaktualizowane, a ręczne korekty zapisane. Kontynuować?';
						|tr = 'Borç bilgileri güncellenecek, manuel düzeltmeler korunacaktır. Devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	Else
		// &PerformanceMeasurement
		PerformanceMonitorClient.StartTimeMeasurement(True,
			"Document.AccrualAndWriteOffOfBadDebtAlowances.Form.DocumentForm.Command.FillInAccountsPayable");
		
		FillInAccountsPayable();
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionOfUpdatingDocumentEnds(QuestionResult, AdditionalParameters) Export
	
	If Not QuestionResult = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If AdditionalParameters.EventName = "FillInDocument" Then
		FillInDocumentOnClient("FillInDocument");
		FillInAdditionalDetailsOfAccountsReceivable();
	ElsIf AdditionalParameters.EventName = "FillInAccountsReceivable" Then
		FillInDocumentOnClient("FillInAccountsReceivable");
	ElsIf AdditionalParameters.EventName = "FillInAccountsPayable" Then
		
		// &PerformanceMeasurement
		PerformanceMonitorClient.StartTimeMeasurement(True,
			"Document.AccrualAndWriteOffOfBadDebtAlowances.Form.DocumentForm.Command.FillInAccountsPayable");
		
		FillInAccountsPayable();
	EndIf;
	
EndProcedure

&AtClient
Procedure CommandToUpdateTheSpendingLimitWELL(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.AccrualAndWriteOffOfBadDebtAlowances.Form.DocumentForm.Command.UpdateYourSpendingLimit");
	
	UpdateYourSpendingLimit();
	
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

#EndRegion

#Region Private

#Region FormControl

&AtClient
Procedure CheckChangesToHeaderDetails()
	
	If
		Object.AccountsReceivable.Count() = 0 And
		Object.AccountsPayable.Count() = 0
	Then
		Return;
	EndIf;
	
	HeaderAttributes = HeaderData_(Object.Ref);
	
	If
		HeaderAttributes.Organization = Object.Organization And
		HeaderAttributes.Date = Object.Date
	Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure("EventName, OldDetails", "ChangeAttributes", HeaderAttributes);
	CleaningTSDescriptionOfAlert = New CallbackDescription("IssueOfClearingTheTablePartCompletion", ThisObject, NotificationParameters);
	QueryText = NStr("vi = 'Sẽ xóa bảng nợ. Tiếp tục?';
					|ru = 'Таблицы задолженности будут очищены. Продолжить?';
					|en = 'Debt tables will be cleared. Continue?'; fa = 'Debt tables will be cleared. Continue?';
					|it = 'I dati nelle tabelle sul debito verranno cancellati. Continuare?';
					|pl = 'Tabele zadłużenia zostaną wyczyszczone. Kontynuować?';
					|tr = 'Borç tabloları temizlenecek. Devam edilsin mi?'");
	
	ShowQueryBox(CleaningTSDescriptionOfAlert, QueryText, QuestionDialogMode.YesNoCancel);
	
EndProcedure

&AtClient
Procedure IssueOfClearingTheTablePartCompletion(Result, AdditionalParameters = Undefined) Export
	
	If Result = DialogReturnCode.Yes Then
		Object.AccountsReceivable.Clear();
		Object.AccountsPayable.Clear();
	ElsIf Result = DialogReturnCode.Cancel And Not AdditionalParameters.EventName = "ChangeAttributes" Then
		Return;
	EndIf;
	
	If AdditionalParameters.EventName = "ChangeAttributes" And Not Result = DialogReturnCode.Yes Then
		Object.Organization = AdditionalParameters.OldDetails.Organization;
		Object.Date = AdditionalParameters.OldDetails.Date;
		
		PeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Date);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVisibilityAccessibilityOfElements()
	
	If Not ValueIsFilled(Object.Organization) Then
		AccountingPolicyHeader = NStr("vi = 'Chưa xác định trình tự đánh giá nợ. Trước tiên, bạn cần chọn một doanh nghiệp';
										|ru = 'Порядок оценки задолженности не определен. Сперва необходимо выбрать организацию';
										|en = 'The debt evaluation procedure is not defined. You must select a company first'; fa = 'The debt evaluation procedure is not defined. You must select a company first';
										|it = 'Il metodo di classificazione dell''indebitamento non è stato definito. Prima è necessario selezionare l''azienda';
										|pl = 'Procedura oceny zadłużenia nie jest zdefiniowana. Najpierw musisz wybrać firmę';
										|tr = 'Borç değerlendirme prosedürü tanımlanmamıştır. İlk olarak, iş yeri seçilmelidir'");
	ElsIf Not AccountingPolicyIsSet Then
		AccountingPolicyHeader = NStr("vi = 'Chưa xác định trình tự đánh giá nợ. Chưa xác định chính sách kế toán nào cho doanh nghiệp';
										|ru = 'Порядок оценки задолженности не определен. Для организации не задана учетная политика';
										|en = 'The debt evaluation procedure is not defined. The accounting policy is not specified for a company'; fa = 'The debt evaluation procedure is not defined. The accounting policy is not specified for a company';
										|it = 'Il metodo di classificazione dell''indebitamento non è stato definito. Per l''azienda non è stata impostata la politica contabile';
										|pl = 'Procedura oceny zadłużenia nie jest zdefiniowana. Firma nie ustawiła zasad rachunkowości';
										|tr = 'Borç değerleme prosedürü tanımlanmamıştır. İş yeri için herhangi muhasebe politikası belirlenmedi'");
	ElsIf AccountingPolicyIsSet Then
		Items.TheCommandToOpenTheAccountingPolicies.Visible = True;
		Items.AccountingPolicyDescription.Visible = False;
	EndIf;
	
	Items.AccountingPolicyDescription.Title = AccountingPolicyHeader;
	
	Items.AccountsReceivableAmountOfDebtLocal.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Công nợ, %1.';
					|ru = 'Задолженность, %1.';
					|en = 'Debt, %1.'; fa = 'Debt, %1.';
					|it = 'Debito, %1.';
					|pl = 'Zobowiązanie, %1.';
					|tr = 'Borç, %1.'"),
				LocalAccountingCurrency);
				
	If LocalizationRFService Then
		Items.LimitOfTAExpenses.ReadOnly = Not LimitOfTAExpensesEditingPermitted;
		Items.GroupAccountsPayable.Visible = TakeIntoAccountTheCounterDebt;
		Items.PostInFinancialAccounting.ReadOnly = Not ToForm;
		Items.RecordInTaxAccounting.ReadOnly = Not GenerateTA;
		Items.SPARKBanner.Visible = SPARKApplicationIsPermitted;
	Else
		Items.GroupLimitOfTAExpenses.Visible = False;
		Items.AccountingPolicySettingsGroup.Visible = False;
		Items.GroupHeaderRight.Visible = False;
		Items.GroupAccountsPayable.Visible = False;
		Items.GroupTotalAccountsReceivable.Visible = False;
		Items.AccountsReceivableMutualDebt.Visible = False;
		Items.AccountsReceivableTheGroupSReserves.Visible = False;
		Items.AccountsReceivableTAReserveWithinBorderOfLimit.Visible = False;
		Items.AccountsReceivableGroup1SPARK.Visible = False;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function HeaderData_(ObjectRef)
	
	Return Common.ObjectAttributesValues(ObjectRef, "Organization,Date");
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region ControlledTypesOfDebt
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	// Selection.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Object.AccountsReceivable.DebtKind");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = Enums.KindsOfDebt.Other;
	
	// Fields.
	
	FieldArray = New Array;
	FieldArray.Add(Items.AccountsReceivableCounterparty.Name);
	FieldArray.Add(Items.AccountsReceivableContract.Name);
	FieldArray.Add(Items.AccountsReceivableARAPDocument.Name);
	FieldArray.Add(Items.AccountsReceivableAmountType.Name);
	FieldArray.Add(Items.AccountsReceivableCurrency.Name);
	FieldArray.Add(Items.AccountsReceivableDebtAmount.Name);
	FieldArray.Add(Items.AccountsReceivableAmountOfDebtLocal.Name);
	FieldArray.Add(Items.AccountsReceivableDateOfDebtOccurrence.Name);
	FieldArray.Add(Items.AccountsReceivablePartner.Name);
	FieldArray.Add(Items.AccountsReceivableLineOfBusiness.Name);
	FieldArray.Add(Items.AccountsReceivableARAPObject.Name);
	
	For Each Field In FieldArray Do
		FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
		FieldItem.Field = New DataCompositionField(Field);
	EndDo;
	
	#EndRegion

	#Region SettlementDocument_Visibility
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	// Selection.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Object.AccountsReceivable.DebtKind");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = Enums.KindsOfDebt.IssuedBorrowings;
	
	// Fields.
	
	FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField(Items.AccountsReceivableARAPDocument.Name);
	
	#EndRegion
	
	#Region AmountType_Visibility
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	// Selection.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Object.AccountsReceivable.DebtKind");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = Enums.KindsOfDebt.IssuedBorrowings;
	
	// Fields.
	
	FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField(Items.AccountsReceivableAmountType.Name);
	
	#EndRegion
	
	#Region DonTCharge_RowColor
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
	// Selection.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Object.AccountsReceivable.DoNotAccrue");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	
	// Fields.
	
	FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField(Items.AccountsReceivable.Name);
	
	#EndRegion
	
	#Region DoNotCharge_NotApplicable
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Center);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", "x");
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	// Selection.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Object.AccountsReceivable.DoNotAccrue");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	
	// Fields.
	
	FieldArray = New Array;
	FieldArray.Add(Items.AccountsReceivableACReserve.Name);
	FieldArray.Add(Items.AccountsReceivableTAReserve.Name);
	FieldArray.Add(Items.AccountsReceivableTAReserveWithinBorderOfLimit.Name);
	FieldArray.Add(Items.AccountsReceivableReserve.Name);
	
	For Each Field In FieldArray Do
		FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
		FieldItem.Field = New DataCompositionField(Field);
	EndDo;
	
	#EndRegion
	
	#Region DonTCharge_OnlyView
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	// Selection.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Object.AccountsReceivable.DoNotAccrue");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	
	// Fields.
	
	FieldArray = New Array;
	FieldArray.Add(Items.AccountsReceivableCounterparty.Name);
	FieldArray.Add(Items.AccountsReceivableContract.Name);
	FieldArray.Add(Items.AccountsReceivableARAPDocument.Name);
	FieldArray.Add(Items.AccountsReceivableAmountType.Name);
	FieldArray.Add(Items.AccountsReceivableDebtAmount.Name);
	FieldArray.Add(Items.AccountsReceivableAmountOfSecurityByDimension.Name);
	FieldArray.Add(Items.AccountsReceivableManualAdjustment.Name);
	FieldArray.Add(Items.AccountsReceivableDateOfDebtOccurrence.Name);
	FieldArray.Add(Items.AccountsReceivableEvaluation.Name);
	FieldArray.Add(Items.AccountsReceivablePartner.Name);
	FieldArray.Add(Items.AccountsReceivableLineOfBusiness.Name);
	FieldArray.Add(Items.AccountsReceivableARAPObject.Name);
	
	For Each Field In FieldArray Do
		FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
		FieldItem.Field = New DataCompositionField(Field);
	EndDo;
	
	#EndRegion
	
	#Region PresentationOfCollateralAmount
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", New DataCompositionField("Object.AccountsReceivable.AmountOfSecurityPresentation"));
	
	// Selection.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Object.AccountsReceivable.AmountOfSecurityByDimension");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = New DataCompositionField("Object.AccountsReceivable.AmountOfSecurity");
	
	// Fields.
	
	FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField(Items.AccountsReceivableAmountOfSecurityByDimension.Name);
	
	#EndRegion
	
	#Region CounterDebt_Visibility
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	// Selection.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TakeIntoAccountTheCounterDebt");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	
	// Fields.
	
	FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField(Items.AccountsReceivableMutualDebt.Name);
	
	#EndRegion
	
	#Region CounterDebt_NotApplicable
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Center);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", "x");
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
	// Selection.
	
	FilterValue = New ValueList;
	FilterValue.Add(Enums.KindsOfDebt.CounterpartyAccountsReceivablesInForeignCurrency);
	FilterValue.Add(Enums.KindsOfDebt.ReceivablesFromCounterpartiesLocal);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Object.AccountsReceivable.DebtKind");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotInList;
	DataFilterItem.RightValue = FilterValue;
	
	// Fields.
	
	FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField(Items.AccountsReceivableMutualDebt.Name);
	
	#EndRegion
	
	#Region CheckRequired
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	// Selection.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Object.AccountsReceivable.CheckRequired");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	
	// Fields.
	
	FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField(Items.AccountsReceivableCheckRequired.Name);
	
	// The next element.
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	// Selection.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Object.AccountsReceivable.CheckRequired");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	
	// Fields.
	
	FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField(Items.AccountsReceivable.Name);
	
	#EndRegion
	
	#Region ManualAdjustment_EditFields
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	// Selection.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Object.AccountsReceivable.ManualAdjustment");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	
	// Fields.
	
	FieldArray = New Array;
	FieldArray.Add(Items.AccountsReceivableEvaluation.Name);
	FieldArray.Add(Items.AccountsReceivableACReserve.Name);
	FieldArray.Add(Items.AccountsReceivableReserve.Name);
	
	For Each Field In FieldArray Do
		FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
		FieldItem.Field = New DataCompositionField(Field);
	EndDo;
	
	#EndRegion

	#Region ReserveColumnsTa
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	// Decoration.
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	// Selection.
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("GenerateTA");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	
	// Fields.
	
	FieldArray = New Array;
	FieldArray.Add(Items.AccountsReceivableTAReserve.Name);
	FieldArray.Add(Items.AccountsReceivableTAReserveWithinBorderOfLimit.Name);
	
	For Each Field In FieldArray Do
		FieldItem = ConditionalAppearanceItem.Fields.Items.Add();
		FieldItem.Field = New DataCompositionField(Field);
	EndDo;
	
	#EndRegion

	AccrualAndWriteOffOfBadDebtAlowancesLocalization.SparkRisksConditionalAppearance(ThisForm);
	
EndProcedure

#EndRegion

#Region TimeConsumingOperations

&AtClient
Procedure FillInDocumentOnClient(EventName)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("EventName", EventName);
		
	TimeConsumingOperation = FillAccountsReceivableOnServer();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackDescription = New CallbackDescription("AfterFillingAccountsReceivable", ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtServer
Function FillAccountsReceivableOnServer()
	
	FillParameters = New Structure;
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("EmptyDocument", Object.AccountsReceivable.Count() = 0);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Điền công nợ phải thu';
														|ru = 'Заполнение дебиторской задолженности';
														|en = 'Filling receivables'; fa = 'Filling receivables';
														|it = 'Compilazione dei crediti contabili';
														|pl = 'Wypełnianie należności';
														|tr = 'Alacakların doldurulması'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"Documents.AccrualAndWriteOffOfBadDebtAlowances.PrepareAccountsReceivableData",
		FillParameters, ExecutionParameters);
	
	Return ExecutionResult;
	
EndFunction

&AtClient
Procedure AfterFillingAccountsReceivable(Result, AdditionalParameters) Export
	
	If Result.Status = "Error" Then
		MessageText = NStr("vi = 'Đã xảy ra lỗi khi điền các khoản phải thu:';
							|ru = 'Произошла ошибка заполнения дебиторской задолженности:';
							|en = 'An error occurred while filling receivables:'; fa = 'An error occurred while filling receivables:';
							|it = 'Si è verificato un errore di compilazione dei crediti contabili:';
							|pl = 'Wystąpił błąd wypełnienia należności:';
							|tr = 'Alacakların doldurulmasında hata oluştu:'") + Chars.LF + Result.BriefErrorDescription;
		CommonClientServer.MessageToUser(MessageText);
		
		Return;
	EndIf;
	
	LoadPreparedData(Result.ResultAddress, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure LoadPreparedData(ResultAddress, AdditionalParameters)
	
	AccountsReceivableData = GetFromTempStorage(ResultAddress);
	
	CurrentObject = FormAttributeToValue("Object");
	
	If AdditionalParameters.EventName = "FillInAccountsReceivable" Then
		CurrentObject.FillInAccountsReceivable(AccountsReceivableData);
		CurrentObject.CalculateReserves();
	ElsIf AdditionalParameters.EventName = "FillInDocument" Then
		CurrentObject.FillInDocument(AccountsReceivableData);
	EndIf;
	
	ValueToFormAttribute(CurrentObject, "Object");
	FillInAdditionalDetailsOfAccountsReceivable();
	
EndProcedure

#EndRegion

#Region FillingForm

#Region Header

&AtServer
Procedure UpdateYourSpendingLimit()
	
	CurrentObject = FormAttributeToValue("Object");
	CurrentObject.UpdateYourSpendingLimit(True, True);
	
	ValueToFormAttribute(CurrentObject, "Object");
	FillInAdditionalDetailsOfAccountsReceivable();
	
EndProcedure

#EndRegion

#Region AccountsReceivable

&AtServer
Procedure FillInAdditionalDetailsOfAccountsReceivable()
	
	ArrayOfCounterparties = TMCommonUse.DeleteDuplicateElementsFromArray(
		Object.AccountsReceivable.Unload(, "Counterparty").UnloadColumn("Counterparty"));
	SPARK_Data = AccrualAndWriteOffOfBadDebtAlowancesLocalization.SparkRisksGettingData(
		ArrayOfCounterparties, SPARKApplicationIsPermitted);
	
	For Each curData In Object.AccountsReceivable Do
		
		PresentationText = NStr("vi = '""%1 trong số ""%2""';
								|ru = '""%1"" из ""%2""';
								|en = '""%1"" out of ""%2""'; fa = '""%1"" out of ""%2""';
								|it = '""%1"" di ""%2""';
								|pl = '""%1"" z ""%2""';
								|tr = '""%2""''dan ""%1""'");
			
		curData.AmountOfSecurityPresentation = ?(curData.DebtAmount = 0 Or curData.AmountOfSecurity = 0, "",
			StrTemplate(PresentationText, Format(curData.AmountOfSecurity, NStr("vi = 'NFD=2;''NZ=;''';
																				|ru = 'ЧДЦ=2;''ЧН=;''';
																				|en = 'NFD=2;''NZ=;'''; fa = 'NFD=2;''NZ=;''';
																				|it = 'NFD=2; NZ=;''';
																				|pl = 'NFD=2;''NZ=;''';
																				|tr = 'NFD=2;''NZ=;'''")),
				Format(curData.AmountOfSecurityByDimension, NStr("vi = 'NFD=2;''NZ=;''';
																|ru = 'ЧДЦ=2;''ЧН=;''';
																|en = 'NFD=2;''NZ=;'''; fa = 'NFD=2;''NZ=;''';
																|it = 'NFD=2; NZ=;''';
																|pl = 'NFD=2;''NZ=;''';
																|tr = 'NFD=2;''NZ=;'''"))));
				
		If SPARKApplicationIsPermitted Then
			FoundRow = SPARK_Data.Find(curData.Counterparty, "Counterparty");
			If ValueIsFilled(FoundRow) Then
				FillPropertyValues(curData, FoundRow,, "Counterparty");
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure FillInTermOfAccountsReceivable(AccountsReceivableLineData = Undefined)
	
	ProcessingIterator = GetTableIterator(Object.AccountsReceivable, AccountsReceivableLineData);
	For Each curData In ProcessingIterator Do
		curData.DoubtfulDebtPeriod = Max(0, (BegOfDay(Object.Date) - curData.DateOfDebtOccurrence) / 86400);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function GetEstimate(DebtKind, DoubtfulDebtPeriod, AdditionalParameters)

	Return Documents.AccrualAndWriteOffOfBadDebtAlowances.GetEstimate(
		DebtKind, DoubtfulDebtPeriod, AdditionalParameters);

EndFunction

#EndRegion

#Region AccountsPayable

&AtServer
Procedure FillInAccountsPayable(AccountsPayableLine = Undefined)
	
	Dimension = Undefined;
	
	If Not AccountsPayableLine = Undefined Then
		RowData = Object.AccountsPayable.FindByID(AccountsPayableLine);
		If RowData = Undefined Then
			Return;
		EndIf;
		
		Dimension = New Structure("Counterparty,Contract,ARAPDocument");
		FillPropertyValues(Dimension, RowData);
	EndIf;
	
	CurrentObject = FormAttributeToValue("Object");
	CurrentObject.FillInAccountsPayable(Dimension);
	CurrentObject.CalculateReserves();
	
	ValueToFormAttribute(CurrentObject, "Object");
	FillInAdditionalDetailsOfAccountsReceivable();
	
EndProcedure

#EndRegion

#Region Reserves

&AtClient
Procedure ProcessChangeInAccountsReceivable(ACC = True, TA = True, MA = True)
	
	Dimension = AnalysisOfReservesCalculation();
	FillPropertyValues(Dimension, AccountsReceivableCurrentData);
	
	// Fill in the Amount of collateral for analytics for each row of current data debt.
	
	FoundRows = Object.AccountsReceivable.FindRows(Dimension);
	For Each FoundRow In FoundRows Do
		FoundRow.DoNotAccrue = AccountsReceivableCurrentData.DoNotAccrue;
		FoundRow.AmountOfSecurityByDimension = AccountsReceivableCurrentData.AmountOfSecurityByDimension;
	EndDo;
	
	CalculateReserves(Dimension, ACC, TA, MA);
	AccountsReceivableCurrentData = FillInCurDataOfDZ();
	
EndProcedure

&AtClient
Procedure ProcessChangeInAccountsPayable()
	
	Dimension = AnalysisOfReservesCalculation();
	FillPropertyValues(Dimension, AccountsPayableCurrentData);
	
	CalculateReserves(Dimension, True, True, True); // They always calculate the reserves of BU, WELL, and UU
	AccountsPayableCurrentData = FillInCurDataKZ();
	
EndProcedure

&AtServer
Procedure CalculateReserves(Dimension, ACC, TA, MA)
	
	CurrentObject = FormAttributeToValue("Object");
	CurrentObject.CalculateReserves(Dimension, ACC, TA, MA);
	
	ValueToFormAttribute(CurrentObject, "Object");
	FillInAdditionalDetailsOfAccountsReceivable();
	
EndProcedure

#EndRegion

#EndRegion

#Region OtherItems

&AtServer
Procedure FillFormAttributes()
	
	SetAccountingPoliciesForOrganizations();
	
	TakeIntoAccountTheCounterDebt = AccrualAndWriteOffOfBadDebtAlowancesLocalization.TakeIntoAccountTheCounterDebt(Object.Date);
	SPARKApplicationIsPermitted = AccrualAndWriteOffOfBadDebtAlowancesLocalization.SparkRisksUseIsPermitted();
	
	LimitOfTAExpensesEditingPermitted = AllowedToEditSpendingLimitTa(Object.Organization);
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	
EndProcedure

&AtServer
Procedure SetAccountingPoliciesForOrganizations()
	
	AccountingPolicyIsSet	= False;
	ToForm					= False;
	GenerateTA				= False;
	
	AccountingPolicySettings_ = AccrualAndWriteOffOfBadDebtAlowancesServer.GetCurrentAccountingPolicySettings(
		Object.Organization,
		Object.Date);
	
	AccountingPolicyParameters = AccountingPolicySettings_.FinancialAccountingPolicy;
	If AccountingPolicyParameters <> Undefined Then
		AccountingPolicyIsSet = True;
		ToForm = AccountingPolicyParameters.ToGenerateLossAllowance;
		
		If Object.Ref.IsEmpty() Then
			Object.PostInFinancialAccounting = ToForm
				And AccrualAndWriteOffOfBadDebtAlowancesServer.FormationOfReservesInSpecifiedPeriodIsRequired(
					AccountingPolicyParameters.FrequencyOfLossAllowance, Object.Date);
		EndIf;
	EndIf;
	
	AccountingPolicyParameters = AccountingPolicySettings_.ProfitTaxAccountingSettings;
	If AccountingPolicyParameters <> Undefined Then
		AccountingPolicyIsSet = True;
		GenerateTA = AccountingPolicyParameters.ToFormReservesForDoubtfulDebtsTa;
		
		If Object.Ref.IsEmpty() Then
			Object.RecordInTaxAccounting = GenerateTA
				And AccrualAndWriteOffOfBadDebtAlowancesServer.FormationOfReservesInSpecifiedPeriodIsRequired(
					AccountingPolicyParameters.PeriodicityOfProvisionsForDoubtfulDebtsTa, Object.Date);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingDocumentDate()
	
	CheckChangesToHeaderDetails();
	
	FillFormAttributes();
	
	FillInTermOfAccountsReceivable();
	SetVisibilityAccessibilityOfElements();
	
EndProcedure

&AtClient
Function ReadyToFill()
	
	If Not ValueIsFilled(Object.Organization) Then
		MessageText = NStr("vi = 'Trước khi điền vào chứng từ, cần điền doanh nghiệp';
							|ru = 'Перед заполнением документа необходимо заполнить организацию';
							|en = 'Fill the company before filling the document'; fa = 'Fill the company before filling the document';
							|it = 'Prima di compilare il documento è necessario compilare l''azienda';
							|pl = 'Przed wypełnieniem dokumentu musisz wypełnić firmę';
							|tr = 'Belgeyi doldurmadan önce, iş yeri doldurulmalıdır'");
		CommonClientServer.MessageToUser(MessageText, Object.Ref, "Organization", "Object.Organization");
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// We save the values of the fields of the current row of the table part of accounts receivable before changing it.
// Used to check for changes in the values of the corresponding fields of the "when Changing" event.
//
&AtClient
Function FillInCurDataOfDZ()
	
	Result = New Structure(
		"DebtKind,Counterparty,Contract, ARAPObject, ARAPDocument,AmountType," +
		"Currency,AmountOfDebtLocal,DebtAmount,AmountOfSecurityByDimension,MutualDebt," +
		"DoNotAccrue,ManualAdjustment,DateOfDebtOccurrence,Evaluation,ACReserve,Reserve");
	
	curData = Items.AccountsReceivable.CurrentData;
	If Not curData = Undefined Then
		FillPropertyValues(Result, curData);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Function FillInCurDataKZ()
	
	Result = New Structure("Counterparty,Sum");
	
	curData = Items.AccountsPayable.CurrentData;
	If Not curData = Undefined Then
		FillPropertyValues(Result, curData);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function AnalysisOfReservesCalculation()
	
	Return New Structure("DebtKind,Counterparty,Contract,ARAPDocument");
	
EndFunction

&AtServerNoContext
Procedure PartnerWhenChangesAreMadeOnServer(Partner, Counterparty)
	
	If Partner = Catalogs.Partners.OurEnterprise 
		And TypeOf(Counterparty) <> Type("CatalogRef.Companies") Then
		Counterparty = Catalogs.Companies.EmptyRef();
	Else
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty, True);
	EndIf;
	
EndProcedure

// Returns a collection of rows in the passed table.
// If the search Structure is set, we return the found rows based on the search structure filled with the string data.
// If string Data is specified, an array of this single string is returned.
// Otherwise, the table itself is returned.
//
&AtClientAtServerNoContext
Function GetTableIterator(Table, RowData, TheStructureOfTheSearch = Undefined)
	
	If RowData = Undefined Then
		Iterator_SSLy = Table;
	ElsIf TheStructureOfTheSearch = Undefined Then
		Iterator_SSLy = New Array;
		Iterator_SSLy.Add(RowData);
	Else
		FillPropertyValues(TheStructureOfTheSearch, RowData);
		Iterator_SSLy = Table.FindRows(TheStructureOfTheSearch);
	EndIf;
	
	Return Iterator_SSLy;
	
EndFunction

&AtClient
Procedure TheCommandToOpenTheAccountingPoliciesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
EndProcedure

&AtServerNoContext
Function AllowedToEditSpendingLimitTa(Organization)
	
	Return Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Organization);
	
EndFunction
#EndRegion

#EndRegion
