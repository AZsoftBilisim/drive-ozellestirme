//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnCreatReadAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		ReadOnly = True;
		
	EndIf;
	
	CurrentConditionsDocument = Object.TermDocument;
	CurrentCounterparty = Object.Counterparty;
	CurPartner = Object.Partner;
	CurrentStartOfThePeriod = Object.BeginOfPeriod;
	CurrentEndOfThePeriod_3 = Object.PeriodEnding;
	CurrentCurrency = Object.Currency;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnCreatReadAtServer();
		
	EndIf;
	
	SetConditionalAppearance();
	SetHeader();
	
	UpdateLinksOfParametersForSelectingConditionDocument();
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetHeader();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.ShowConfirmationForClosingFormWithFiles(ThisObject, Cancel, Exit, Object.Ref);
	If Cancel Then
		Return;
	EndIf;
	// End StandardSubsystems.FilesOperations
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	UpdateVisibilityAvailabilityOfRosterFix();
	
EndProcedure

&AtClient
Procedure TermDocumentOnChange(Item)
	
	ClearMessages();
	If Object.TermDocument.IsEmpty() Then
		
		TermDocumentClearingServer();
		UpdateVisibilityAvailabilityOfRosterFix();
		
	ElsIf CurrentConditionsDocument <> Object.TermDocument Then
		
		CurrentConditionsDocument = Object.TermDocument;
		TermDocumentOnChangeServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TermDocumentClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	TermDocumentClearingServer();
	
EndProcedure

&AtClient
Async Procedure CounterpartyOnChange(Item)
	
	If CurrentCounterparty <> Object.Counterparty
	   And Object.Accruals.Count() > 0 Then
		
		AccrualInformation = SignsOfAccruals();
		
		If AccrualInformation.ThereAreAccrualsByCalculation Then
			
			QueryText = NStr("vi = 'Danh sách tính toán sẽ bị xóa.
								|Tiếp tục?';
								|ru = 'Список начислений будет очищен.
								|Продолжить?';
								|en = 'List of accruals will be cleared.
								|Continue?'; fa = 'List of accruals will be cleared.
								|Continue?';
								|it = 'Список начислений будет очищен.
								|Продолжить?';
								|pl = 'List of accruals will be cleared.
								|Continue?';
								|tr = 'Tahakkuk listesi temizlenecek.
								|Devam edilsin mi?'");
			Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
			
			If Response = DialogReturnCode.Yes Then
				
				CurrentCounterparty = Object.Counterparty;
				Object.Accruals.Clear();
				CalculateDocumentTotals_(ThisObject);
				
			Else
				
				Object.Counterparty = CurrentCounterparty;
				
			EndIf;
			
		ElsIf AccrualInformation.ThereAreSalesDocuments Then
			
			QueryText = NStr("vi = 'Chứng từ bán hàng trong bảng tính toán sẽ bị xóa.
								|Tiếp tục?';
								|ru = 'Документы продажи в таблице начислений будут очищены.
								|Продолжить?';
								|en = 'Sales documents in the accrual table will be cleared.
								|Continue?'; fa = 'Sales documents in the accrual table will be cleared.
								|Continue?';
								|it = 'Документы продажи в таблице начислений будут очищены.
								|Продолжить?';
								|pl = 'Sales documents in the accrual table will be cleared.
								|Continue?';
								|tr = 'Tahakkuk tablosundaki satış belgeleri temizlenecektir.
								|Devam edilsin mi?'");
			Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
			
			If Response = DialogReturnCode.Yes Then
				
				CurrentCounterparty = Object.Counterparty;
				For Each AccrualLine In Object.Accruals Do
					
					AccrualLine.Counterparty = Object.Counterparty;
					AccrualLine.DocumentSales = Undefined;
					
				EndDo;
				
			Else
				
				Object.Counterparty = CurrentCounterparty;
				
			EndIf;
			
		Else
			
			CurrentCounterparty = Object.Counterparty;
			For Each AccrualLine In Object.Accruals Do
			
				AccrualLine.Counterparty = Object.Counterparty;
				
			EndDo;
			
		EndIf;
		
	Else
		
		CurrentCounterparty = Object.Counterparty;
		For Each AccrualLine In Object.Accruals Do
			
			AccrualLine.Counterparty = Object.Counterparty;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure PartnerOnChange(Item)
	
	If CurPartner <> Object.Partner
	   And Object.Accruals.Count() > 0 Then
		
		AccrualInformation = SignsOfAccruals();
		
		If AccrualInformation.ThereAreAccrualsByCalculation Then
			
			QueryText = NStr("vi = 'Danh sách tính toán sẽ bị xóa.
								|Tiếp tục?';
								|ru = 'Список начислений будет очищен.
								|Продолжить?';
								|en = 'List of accruals will be cleared.
								|Continue?'; fa = 'List of accruals will be cleared.
								|Continue?';
								|it = 'Список начислений будет очищен.
								|Продолжить?';
								|pl = 'List of accruals will be cleared.
								|Continue?';
								|tr = 'Tahakkuk listesi temizlenecek.
								|Devam edilsin mi?'");
			Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
			
			If Response = DialogReturnCode.Yes Then
				
				CurPartner = Object.Partner;
				Object.Accruals.Clear();
				CalculateDocumentTotals_(ThisObject);
				
			Else
				
				Object.Partner = CurPartner;
				
			EndIf;
			
		ElsIf AccrualInformation.ThereAreSalesDocuments Then
			
			QueryText = NStr("vi = 'Chứng từ bán hàng trong bảng tính toán sẽ bị xóa.
								|Tiếp tục?';
								|ru = 'Документы продажи в таблице начислений будут очищены.
								|Продолжить?';
								|en = 'Sales documents in the accrual table will be cleared.
								|Continue?'; fa = 'Sales documents in the accrual table will be cleared.
								|Continue?';
								|it = 'Документы продажи в таблице начислений будут очищены.
								|Продолжить?';
								|pl = 'Sales documents in the accrual table will be cleared.
								|Continue?';
								|tr = 'Tahakkuk tablosundaki satış belgeleri temizlenecektir.
								|Devam edilsin mi?'");
			Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
			
			If Response = DialogReturnCode.Yes Then
				
				CurPartner = Object.Partner;
				For Each AccrualLine In Object.Accruals Do
					
					AccrualLine.Partner = Object.Partner;
					AccrualLine.DocumentSales = Undefined;
					
				EndDo;
				
			Else
				
				Object.Partner = CurPartner;
				
			EndIf;
			
		Else
			
			CurPartner = Object.Partner;
			For Each AccrualLine In Object.Accruals Do
				
				AccrualLine.Partner = Object.Partner;
				
			EndDo;
			
		EndIf;
		
	Else
		
		CurPartner = Object.Partner;
		For Each AccrualLine In Object.Accruals Do
			
			AccrualLine.Partner = Object.Partner;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If CurrentStartOfThePeriod <> Object.BeginOfPeriod
	   And Object.Accruals.Count() > 0 Then
		
		AccrualInformation = SignsOfAccruals();
		
		If AccrualInformation.ThereAreAccrualsByCalculation Then
			
			QueryText = NStr("vi = 'Danh sách tính toán sẽ bị xóa.
								|Tiếp tục?';
								|ru = 'Список начислений будет очищен.
								|Продолжить?';
								|en = 'List of accruals will be cleared.
								|Continue?'; fa = 'List of accruals will be cleared.
								|Continue?';
								|it = 'Список начислений будет очищен.
								|Продолжить?';
								|pl = 'List of accruals will be cleared.
								|Continue?';
								|tr = 'Tahakkuk listesi temizlenecek.
								|Devam edilsin mi?'");
			Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
			
			If Response = DialogReturnCode.Yes Then
				
				CurrentStartOfThePeriod = Object.BeginOfPeriod;
				Object.Accruals.Clear();
				CalculateDocumentTotals_(ThisObject);
				
			Else
				
				Object.BeginOfPeriod = CurrentStartOfThePeriod;
				
			EndIf;
			
		ElsIf AccrualInformation.ThereAreSalesDocuments Then
			
			QueryText = NStr("vi = 'Chứng từ bán hàng trong bảng tính toán sẽ bị xóa.
								|Tiếp tục?';
								|ru = 'Документы продажи в таблице начислений будут очищены.
								|Продолжить?';
								|en = 'Sales documents in the accrual table will be cleared.
								|Continue?'; fa = 'Sales documents in the accrual table will be cleared.
								|Continue?';
								|it = 'Документы продажи в таблице начислений будут очищены.
								|Продолжить?';
								|pl = 'Sales documents in the accrual table will be cleared.
								|Continue?';
								|tr = 'Tahakkuk tablosundaki satış belgeleri temizlenecektir.
								|Devam edilsin mi?'");
			Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
			
			If Response = DialogReturnCode.Yes Then
				
				CurrentStartOfThePeriod = Object.BeginOfPeriod;
				For Each AccrualLine In Object.Accruals Do
					AccrualLine.DocumentSales = Undefined;
				EndDo;
				
			Else
				
				Object.BeginOfPeriod = CurrentStartOfThePeriod;
				
			EndIf;
			
		Else
			
			CurrentStartOfThePeriod = Object.BeginOfPeriod;
			
		EndIf;
		
	Else
		
		CurrentStartOfThePeriod = Object.BeginOfPeriod;
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure PeriodEndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If CurrentEndOfThePeriod_3 <> Object.PeriodEnding
	   And Object.Accruals.Count() > 0 Then
		
		AccrualInformation = SignsOfAccruals();
		
		If AccrualInformation.ThereAreAccrualsByCalculation Then
			
			QueryText = NStr("vi = 'Danh sách tính toán sẽ bị xóa.
								|Tiếp tục?';
								|ru = 'Список начислений будет очищен.
								|Продолжить?';
								|en = 'List of accruals will be cleared.
								|Continue?'; fa = 'List of accruals will be cleared.
								|Continue?';
								|it = 'Список начислений будет очищен.
								|Продолжить?';
								|pl = 'List of accruals will be cleared.
								|Continue?';
								|tr = 'Tahakkuk listesi temizlenecek.
								|Devam edilsin mi?'");
			Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
			
			If Response = DialogReturnCode.Yes Then
				
				CurrentEndOfThePeriod_3 = Object.PeriodEnding;
				Object.Accruals.Clear();
				CalculateDocumentTotals_(ThisObject);
				
			Else
				
				Object.PeriodEnding = CurrentEndOfThePeriod_3;
				
			EndIf;
			
		ElsIf AccrualInformation.ThereAreSalesDocuments Then
			
			QueryText = NStr("vi = 'Chứng từ bán hàng trong bảng tính toán sẽ bị xóa.
								|Tiếp tục?';
								|ru = 'Документы продажи в таблице начислений будут очищены.
								|Продолжить?';
								|en = 'Sales documents in the accrual table will be cleared.
								|Continue?'; fa = 'Sales documents in the accrual table will be cleared.
								|Continue?';
								|it = 'Документы продажи в таблице начислений будут очищены.
								|Продолжить?';
								|pl = 'Sales documents in the accrual table will be cleared.
								|Continue?';
								|tr = 'Tahakkuk tablosundaki satış belgeleri temizlenecektir.
								|Devam edilsin mi?'");
			Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
			
			If Response = DialogReturnCode.Yes Then
				
				CurrentEndOfThePeriod_3 = Object.PeriodEnding;
				For Each AccrualLine In Object.Accruals Do
					AccrualLine.DocumentSales = Undefined;
				EndDo;
				
			Else
				
				Object.PeriodEnding = CurrentEndOfThePeriod_3;
				
			EndIf;
			
		Else
			
			CurrentEndOfThePeriod_3 = Object.PeriodEnding;
			
		EndIf;
		
	Else
		
		CurrentEndOfThePeriod_3 = Object.PeriodEnding;
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure CurrencyOnChange(Item)
	
	If CurrentCurrency <> Object.Currency
	   And Object.Accruals.Count() > 0 Then
		
		AccrualInformation = SignsOfAccruals();
		
		If AccrualInformation.ThereAreAccrualsByCalculation Then
			
			QueryText = NStr("vi = 'Danh sách tính toán sẽ bị xóa.
								|Tiếp tục?';
								|ru = 'Список начислений будет очищен.
								|Продолжить?';
								|en = 'List of accruals will be cleared.
								|Continue?'; fa = 'List of accruals will be cleared.
								|Continue?';
								|it = 'Список начислений будет очищен.
								|Продолжить?';
								|pl = 'List of accruals will be cleared.
								|Continue?';
								|tr = 'Tahakkuk listesi temizlenecek.
								|Devam edilsin mi?'");
			Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
			
			If Response = DialogReturnCode.Yes Then
				
				CurrentCurrency = Object.Currency;
				Object.Accruals.Clear();
				CalculateDocumentTotals_(ThisObject);
				
			Else
				
				Object.Currency = CurrentCurrency;
				
			EndIf;
			
		Else
			
			CurrentCurrency = Object.Currency;
			
		EndIf;
		
	Else
		
		CurrentCurrency = Object.Currency;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationFixCompositionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	RefToProcess = "Commit";
	
	If FormattedStringURL = RefToProcess Then
		FixCompositionOfConditionsDocument();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccruals

&AtClient
Procedure AccrualsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Accruals.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Copy Then
		
		CurrentData.PopulationBySettlement = False;
		CurrentData.AmountAccruedBonus = 0;
		
	ElsIf NewRow Then
		
		CurrentData.Counterparty = Object.Counterparty;
		CurrentData.Partner = Object.Partner;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure AccrualsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateDocumentTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure AccrualsAfterDeleteRow(Item)
	
	CalculateDocumentTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure AccrualsAmountOfBonusAccruedOnChange(Item)
	
	CalculateDocumentTotals_(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);

EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);

EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
	
EndProcedure

// End StandardSubsystems.FilesOperations

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure SetDateInterval(Command)
	
	NotificationAfterSelection = New CallbackDescription("SetIntervalValueSelection", ThisObject);
	PeriodSelectionParameters = New Structure;
	PeriodSelectionParameters.Insert("StartDate", "BeginOfPeriod");
	PeriodSelectionParameters.Insert("EndDate", "PeriodEnding");
	
	TMCommonUseClient.EditPeriod(
		Object, 
		PeriodSelectionParameters,
		NotificationAfterSelection);
	
EndProcedure

&AtClient
Async Procedure FillInAccordingToConditions(Command)
	
	ClearMessages();
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.TermDocument) Then
		
		FieldPresentation = NStr("vi = 'Chứng từ điều kiện';
								|ru = 'Документ условий';
								|en = 'Condition document'; fa = 'سند شرایط';
								|it = 'Документ условий';
								|pl = 'Condition document';
								|tr = 'Koşullar belgesi'");
		MessageText = CommonClientServer.FillingErrorText(,, FieldPresentation);
		CommonClient.MessageToUser(MessageText,, "TermDocument", "Object", Cancel);
		
	Else
		
		CheckFillingOfDocumentHeader(Cancel);
		CheckPeriodsByTimeFence(Cancel);
		
	EndIf;
	
	If Not Cancel Then
		
		CheckWhetherCompositionOfConditionsDocumentHasBeenFixed(Cancel);
		
	EndIf;
	
	If Not Cancel
	   And Object.Accruals.Count() > 0 Then
		
		QueryText = NStr("vi = 'Bảng tính toán sẽ bị xóa.
								  |Tiếp tục?';
								  |ru = 'Таблица начислений будет очищена.
								  |Продолжить?';
								  |en = 'Accrual table will be cleared.
								  |Continue?'; fa = 'Accrual table will be cleared.
								  |Continue?';
								  |it = 'Таблица начислений будет очищена.
								  |Продолжить?';
								  |pl = 'Accrual table will be cleared.
								  |Continue?';
								  |tr = 'Tahakkuk tablosu temizlenecek.
								  |Devam edilsin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		
		If Response <> DialogReturnCode.Yes Then
			Cancel = True;
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		
		CalculationParameters = RebatesCalculationParameters();
		CallbackOnCompletion = New CallbackDescription("FillInAccrualsAccordingToEndConditions", ThisObject);
		
		CommonClientServer.SetFormItemProperty(
			Items,
			Items.AccrualsFillInAccordingToConditions.Name,
			"Enabled",
			False);
		
		RebatesClient.RebatesForPeriodAccordingToSalesDocuments(
			CalculationParameters,
			ThisObject,
			CallbackOnCompletion);
		
	EndIf;
	
	ConfigureFormVisibilityAccessibility();
	
EndProcedure

#EndRegion

#Region Private

#Region EventHandlersForFormHeaderElementsAuxiliary

&AtServer
Procedure OrganizationOnChangeServer()
	
	CompanyIsSpecified = Not Object.Organization.IsEmpty();
	
	If CompanyIsSpecified Then
		
		If Not Object.TermDocument.IsEmpty() Then
			
			DocumentOrganization = Common.ObjectAttributeValue(Object.TermDocument, "Organization");
			If DocumentOrganization <> Object.Organization Then
				
				Object.TermDocument = Documents.ConditionsOfCustomerRebates.EmptyRef();
				CurrentConditionsDocument = Documents.ConditionsOfCustomerRebates.EmptyRef();
				ClearDetailsByCondition(ThisObject);
				
			EndIf;
			
		EndIf;
		
	Else
		
		Object.TermDocument = Documents.ConditionsOfCustomerRebates.EmptyRef();
		CurrentConditionsDocument = Documents.ConditionsOfCustomerRebates.EmptyRef();
		ClearDetailsByCondition(ThisObject);
		
	EndIf;
	
	ConfigureFormVisibilityAccessibility();
	UpdateLinksOfParametersForSelectingConditionDocument();
	
EndProcedure

&AtServer
Procedure TermDocumentOnChangeServer()
	
	Object.Accruals.Clear();
	Object.Counterparty = Catalogs.Counterparties.EmptyRef();
	Object.Partner = Catalogs.Partners.EmptyRef();
	
	UpdateFlagForPossibilityOfChangingURB();
	FillInDataOfLastAdjustment();
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(Object.TermDocument);
	ValueToFormAttribute(DocumentObject, "Object");
	
	UpdateLinksOfParametersForSelectingConditionDocument();
	FillInServiceDetailsOfFormAccordingToCondition();
	SetTitleOfSceneryFixingComposition();
	
	ConfigureFormVisibilityAccessibility();
	
	CalculateDocumentTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure TermDocumentClearingServer()
	
	CurrentConditionsDocument = PredefinedValue("Document.ConditionsOfCustomerRebates.EmptyRef");
	Object.TermDocument = PredefinedValue("Document.ConditionsOfCustomerRebates.EmptyRef");
	ClearDetailsByCondition(ThisObject);
	UpdateFlagForPossibilityOfChangingURB();
	SetTitleOfSceneryFixingComposition();
	ConfigureFormVisibilityAccessibility();
	
EndProcedure

&AtClient
Async Procedure FixCompositionOfConditionsDocument()
	
	UpdateDataBeforeFixingComposition();
	If Not ThereIsAdjustmentOnApproval
	   And Not CompositionOfSegmentsIsFixed Then
		
		QueryText = NStr("vi = 'Ấn định thành phần của chứng từ điều kiện?';
						|ru = 'Зафиксировать состав документа условий?';
						|en = 'Do you want to record the condition document?'; fa = 'Do you want to record the condition document?';
						|it = 'Do you want to record the condition document?';
						|pl = 'Do you want to record the condition document?';
						|tr = 'Şartlar belgesinin içeriği sabitlensin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		
		If Response = DialogReturnCode.Yes Then
			
			CallbackOnCompletion = New CallbackDescription("FixCompositionOfConditionsDocumentCompletion", ThisObject);
			NotificationOfOperationIsInProgress = New CallbackDescription(
				"OfOperationsArePerformedToFixCompositionOfConditionsDocument",
				ThisObject);
			
			CommonClientServer.SetFormItemProperty(
				Items,
				Items.DecorationFixComposition.Name,
				"Enabled",
				False);
			
			RebatesClient.FixCompositionOfConditionsDocument(
				Object.TermDocument,
				ThisObject,
				CallbackOnCompletion,
				NotificationOfOperationIsInProgress);
			
		EndIf;
	
	Else
		
		If ThereIsAdjustmentOnApproval Then
			MessageText = NStr("vi = 'Không thể ấn định thành phần của chứng từ điều kiện: đã nhập điều chỉnh trong trạng thái ""Cần thống nhất""';
								|ru = 'Невозможно зафиксировать состав документа условий: введена корректировка в статусе ""На согласовании""';
								|en = 'Cannot record the condition document: an adjustment is registered in the ""Pending approval"" status.'; fa = 'Cannot record the condition document: an adjustment is registered in the ""Pending approval"" status.';
								|it = 'Cannot record the condition document: an adjustment is registered in the ""Pending approval"" status.';
								|pl = 'Cannot record the condition document: an adjustment is registered in the ""Pending approval"" status.';
								|tr = 'Şartlar belgesinin içeriği sabitlenemiyor: ""Onay bekliyor"" durumunda düzeltme yapıldı'");
		Else
			MessageText = NStr("vi = 'Đã ấn định thành phần chứng từ';
								|ru = 'Состав документа условий уже зафиксирован';
								|en = 'Condition document content is already recorded'; fa = 'Condition document content is already recorded';
								|it = 'Condition document content is already recorded';
								|pl = 'Condition document content is already recorded';
								|tr = 'Belge içeriği hâlihazırda sabitlendi'");
		EndIf;
		
		CommonClient.MessageToUser(MessageText,, "TermDocument", "Object");
		ConfigureFormVisibilityAccessibility();
		
	EndIf;
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure FixCompositionOfConditionsDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined
	   And Result.Status = "Error" Then
		
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		
	EndIf;
	
	UpdateDataBeforeFixingComposition();
	ConfigureFormVisibilityAccessibility();
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure OfOperationsArePerformedToFixCompositionOfConditionsDocument(Result, AdditionalParameters) Export
	
	MessageText = NStr("vi = 'Theo chứng từ điều kiện, đã thực hiện các giao dịch ấn định thành phần. Hãy thử lại sau';
						|ru = 'По документу условий уже выполняются операции по фиксации состава. Попробуйте позже';
						|en = 'Recording operations for the condition document are already in process. Try again later'; fa = 'Recording operations for the condition document are already in process. Try again later';
						|it = 'Recording operations for the condition document are already in process. Try again later';
						|pl = 'Recording operations for the condition document are already in process. Try again later';
						|tr = 'Şartlar belgesi kapsamında içerik düzeltme işlemleri hâlihazırda gerçekleştirilmektedir. Daha sonra tekrar deneyin'");
	
	CommonClient.MessageToUser(MessageText);
	ConfigureFormVisibilityAccessibility();
	
EndProcedure

&AtServer
Procedure CheckPeriodsByTimeFence(Cancel)
	
	If Not Cancel
	   And (Object.BeginOfPeriod > EndDateOfCondition
	  Or Object.PeriodEnding < StartDateOfCondition) Then
		
		ErrorText = NStr("vi = 'Chứng từ điều kiện không có hiệu lực trong kỳ tính toán đã chọn';
						|ru = 'Документ условия не действует в указанном периоде начисления';
						|en = 'The condition document is not available for the specified accrual period'; fa = 'The condition document is not available for the specified accrual period';
						|it = 'Документ условия не действует в указанном периоде начисления';
						|pl = 'The condition document is not available for the specified accrual period';
						|tr = 'Şartlar belgesi mevcut tahakkuk döneminde aktif değildir'");
		Common.MessageToUser(ErrorText,, "TermDocument", "Object", Cancel);
		
	EndIf;
		
	If Not Cancel Then
		
		CheckResult = RebatesServer.CheckPeriodsByTimeFence(
			AccrualFrequency,
			Object.BeginOfPeriod,
			Object.PeriodEnding,
			True);
			
		If CheckResult.ThereIsViolationOfBeginning Then
			
			Common.MessageToUser(
				CheckResult.TextOfStartError,
				,
				"BeginOfPeriod",
				"Object",
				Cancel);
			
		EndIf;
		
		If CheckResult.ThereIsViolationOfEnding Then
			
			Common.MessageToUser(
				CheckResult.TextOfEndingError,
				,
				"PeriodEnding",
				"Object",
				Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDataAboutFixationOfComposition()
	
	TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(Object.TermDocument);
	
	If TermsAndConditionsAttributes.Count() = 0 Then
		
		TermsDocumentHasBeenAgreed = False;
		CompositionFixationIsAvailable = False;
		CompositionOfSegmentsIsFixed = False;
		
	Else
		
		TermsDocumentHasBeenAgreed = True;
		UpdateAvailabilityOfCompositionFixation(TermsAndConditionsAttributes);
		
		CompositionOfSegmentsIsFixed = TermsAndConditionsAttributes.RecordingIsCompleted;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	UpdateFlagForPossibilityOfChangingURB();
	FillInDataOfLastAdjustment();
	SetTitleOfSceneryFixingComposition();
	
	FillInServiceDetailsOfFormAccordingToCondition();
	
	ConfigureFormVisibilityAccessibility();
	CalculateDocumentTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure SetHeader()
	
	AutoTitle = False;
	Title = RebatesServer.DocumentTitle(
		Object.Ref, Object.Number, Object.Date);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfFormAccordingToCondition()
	
	If ValueIsFilled(Object.TermDocument) Then
		
		TermsAndConditionsAttributes = Documents.ConditionsOfCustomerRebates.UpToDateData(Object.TermDocument);
		
		WithoutCalculation = TermsAndConditionsAttributes.WithoutCalculation;
		AccrualFrequency = TermsAndConditionsAttributes.AccrualFrequency;
		PartyCountDetails = TermsAndConditionsAttributes.PartyCountDetails;
		SalesCalculationBase = TermsAndConditionsAttributes.SalesCalculationBase;
		CurrentStartOfThePeriod = TermsAndConditionsAttributes.ValidOnDate;
		CurrentEndOfThePeriod_3 = TermsAndConditionsAttributes.ValidTo;
		StartDateOfCondition = TermsAndConditionsAttributes.ValidOnDate;
		EndDateOfCondition = TermsAndConditionsAttributes.ValidTo;
		CurrentCurrency = TermsAndConditionsAttributes.Currency;
		
		If CurrentCurrency = Catalogs.Currencies.EmptyRef() Then
			
			CurrentCurrency = Object.Currency;
			
		EndIf;
		
		UpdateAvailabilityOfCompositionFixation(TermsAndConditionsAttributes);
		CompositionOfSegmentsIsFixed = TermsAndConditionsAttributes.RecordingIsCompleted;
		RebatesServer.CheckRebateKindOfTermsAndConditionsDocument(Object.TermDocument, TermsAndConditionsAttributes);
		
	Else
		
		ClearDetailsByCondition(ThisObject);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureFormVisibilityAccessibility()
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	ElementNamesVisibilityAll = New Array; // Array of String
	ElementNamesVisibilityAll.Add(Items.Counterparty.Name);
	ElementNamesVisibilityAll.Add(Items.Partner.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsCounterparty.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsPartner.Name);
	ElementNamesVisibilityAll.Add(Items.BeginOfPeriod.Name);
	ElementNamesVisibilityAll.Add(Items.PeriodEnding.Name);
	ElementNamesVisibilityAll.Add(Items.SetDateInterval.Name);
	ElementNamesVisibilityAll.Add(Items.DecorationFixComposition.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsFillInAccordingToConditions.Name);
	ElementNamesVisibilityAll.Add(Items.Currency.Name);
	
	ItemNamesOnlyViewAll = New Array; // Array of String
	ItemNamesOnlyViewAll.Add(Items.BeginOfPeriod.Name);
	ItemNamesOnlyViewAll.Add(Items.PeriodEnding.Name);
	ItemNamesOnlyViewAll.Add(Items.Currency.Name);
	
	NamesOfVisibleElements = New Array; // Array of String
	If Not Object.TermDocument.IsEmpty() Then
		
		NamesOfVisibleElements.Add(Items.BeginOfPeriod.Name);
		NamesOfVisibleElements.Add(Items.PeriodEnding.Name);
		NamesOfVisibleElements.Add(Items.SetDateInterval.Name);
		NamesOfVisibleElements.Add(Items.Currency.Name);
		
	EndIf;
	
	If PartyCountDetails = Detailing.ByCounterparty Then
		
		NamesOfVisibleElements.Add(Items.Counterparty.Name);
		NamesOfVisibleElements.Add(Items.AccrualsPartner.Name);
		
	ElsIf PartyCountDetails = Detailing.ByCustomer Then
		
		NamesOfVisibleElements.Add(Items.Partner.Name);
		NamesOfVisibleElements.Add(Items.AccrualsCounterparty.Name);
		
	ElsIf PartyCountDetails = Detailing.ByCounterpartyAndCustomer Then
		
		NamesOfVisibleElements.Add(Items.Counterparty.Name);
		NamesOfVisibleElements.Add(Items.Partner.Name);
		
	EndIf;
	
	If CompositionFixationIsAvailable 
	   And Not CompositionOfSegmentsIsFixed Then
		
		NamesOfVisibleElements.Add(Items.DecorationFixComposition.Name);
		
	EndIf;
	
	If Not WithoutCalculation Then
		
		NamesOfVisibleElements.Add(Items.AccrualsFillInAccordingToConditions.Name);
		
	EndIf;
	
	ItemNamesAreViewOnly = New Array; // Array of String
	If AccrualFrequency = Enums.RebatesFrequencies.Single Then
		
		ItemNamesAreViewOnly.Add(Items.BeginOfPeriod.Name);
		ItemNamesAreViewOnly.Add(Items.PeriodEnding.Name);
		
		IndexOf = NamesOfVisibleElements.Find(Items.SetDateInterval.Name);
		If IndexOf <> Undefined Then
			NamesOfVisibleElements.Delete(IndexOf);
		EndIf;
		
	EndIf;
	
	If SalesCalculationBase <> Enums.RebateCalculationBases.RevenueARAPAccounting
	 Or WithoutCalculation Then
		
		ItemNamesAreViewOnly.Add(Items.Currency.Name);
		
	EndIf;
	
	Items.DecorationFixComposition.Enabled = ThereIsRightToChangeURB;
	
	TMCommonUseClientServer.SetVisibilityOfElementsByArray(
		Items, ElementNamesVisibilityAll, NamesOfVisibleElements);
	
	RebatesClientServer.SetOnlyViewOfElementsByArray(
		Items, ItemNamesOnlyViewAll, ItemNamesAreViewOnly);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ClearDetailsByCondition(Form)
	
	DateEmpty = Date(1, 1, 1);
	
	Object = Form.Object;
	
	Object.BeginOfPeriod = DateEmpty;
	Form.CurrentStartOfThePeriod = DateEmpty;
	Form.StartDateOfCondition = DateEmpty;
	Object.PeriodEnding = DateEmpty;
	Form.CurrentEndOfThePeriod_3 = DateEmpty;
	Form.EndDateOfCondition = DateEmpty;
	Object.Currency = PredefinedValue("Catalog.Currencies.EmptyRef");
	Form.CurrentCurrency = PredefinedValue("Catalog.Currencies.EmptyRef");
	Object.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
	Form.CurrentCounterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");;
	Object.Partner = PredefinedValue("Catalog.Partners.EmptyRef");
	Form.CurPartner = PredefinedValue("Catalog.Partners.EmptyRef");
	Object.MultipleCounterparties = False;
	Object.SeveralPartners = False;
	Object.Accruals.Clear();
	
	Form.WithoutCalculation = False;
	Form.PartyCountDetails = PredefinedValue("Enum.ARAPAccountingDrilldownsOfRebatesParticipants.EmptyRef");
	Form.AccrualFrequency = PredefinedValue("Enum.RebatesFrequencies.EmptyRef");
	Form.SalesCalculationBase = PredefinedValue("Enum.RebateCalculationBases.EmptyRef");
	Form.CompositionFixationIsAvailable = False;
	Form.CompositionOfSegmentsIsFixed = False;
	Form.ThereIsAdjustmentOnApproval = False;
	
	CalculateDocumentTotals_(Form);
	
EndProcedure

// Returns:
//  Array of ChoiceParameterLink
//
&AtClientAtServerNoContext
Function RelationshipsOfParametersForSelectingConditionDocument(Organization)
	
	ChoiceParameterLinks = New Array(); // Array of ChoiceParameterLink
	
	If Not Organization.IsEmpty() Then
		
		NewLink = New ChoiceParameterLink(
			"Filter.Organization",
			"Object.Organization",
			LinkedValueChangeMode.DontChange);
		ChoiceParameterLinks.Add(NewLink);
		
	EndIf;
	
	Return ChoiceParameterLinks;
	
EndFunction

&AtServer
Procedure UpdateLinksOfParametersForSelectingConditionDocument()
	
	ChoiceParameterLinks = RelationshipsOfParametersForSelectingConditionDocument(Object.Organization);
	Items.TermDocument.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateDocumentTotals_(Form);
	
	CollectionOfAccruals = Form.Object.Accruals;
	
	Form.TotalSettlementBonus = CollectionOfAccruals.Total("AmountAccruedBonus");
	Form.TotalBonusAccrued = CollectionOfAccruals.Total("AmountBonusAccrued");
	
EndProcedure

// Returns:
//  Structure - Signs of Accruals:
// * ThereAreAccrualsByCalculation - Boolean - 
// * ThereAreSalesDocuments - Boolean - 
//
&AtClient
Function SignsOfAccruals()
	
	Result = New Structure;
	Result.Insert("ThereAreAccrualsByCalculation", False);
	Result.Insert("ThereAreSalesDocuments", False);
	
	For Each AccrualLine In Object.Accruals Do
		
		If ValueIsFilled(AccrualLine.DocumentSales) Then
			
			Result.ThereAreSalesDocuments = True;
			
		EndIf;
		
		If AccrualLine.PopulationBySettlement Then
			
			Result.ThereAreAccrualsByCalculation = True;
			
		EndIf;
		
		If Result.ThereAreAccrualsByCalculation
		   And Result.ThereAreSalesDocuments Then
			
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure FillInAccrualsAccordingToEndConditions(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		If Result.Status = "Error" Then
			
			StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
			
		Else
			
			FillInAccrualsAccordingToServerConditions(Result.ResultAddress);
			
		EndIf;
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		Items.AccrualsFillInAccordingToConditions.Name,
		"Enabled",
		True);
	
	CalculateDocumentTotals_(ThisObject);
	
EndProcedure

// Parameters:
//  Period - StandardPeriod -
//	AdditionalParameters - Arbitrary - 
//
&AtClient
Async Procedure SetIntervalValueSelection(Period, AdditionalParameters) Export
	
	If Object.Accruals.Count() > 0 
	   And (CurrentStartOfThePeriod <> Object.BeginOfPeriod
		  Or CurrentEndOfThePeriod_3 <> Object.PeriodEnding) Then
		
		AccrualInformation = SignsOfAccruals();
		
		If AccrualInformation.ThereAreAccrualsByCalculation Then
			
			QueryText = NStr("vi = 'Danh sách tính toán sẽ bị xóa.
								|Tiếp tục?';
								|ru = 'Список начислений будет очищен.
								|Продолжить?';
								|en = 'List of accruals will be cleared.
								|Continue?'; fa = 'List of accruals will be cleared.
								|Continue?';
								|it = 'Список начислений будет очищен.
								|Продолжить?';
								|pl = 'List of accruals will be cleared.
								|Continue?';
								|tr = 'Tahakkuk listesi temizlenecek.
								|Devam edilsin mi?'");
			Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
			
			If Response = DialogReturnCode.Yes Then
				
				CurrentStartOfThePeriod = Object.BeginOfPeriod;
				CurrentEndOfThePeriod_3 = Object.PeriodEnding;
				Object.Accruals.Clear();
				CalculateDocumentTotals_(ThisObject);
				
			Else
				
				Object.BeginOfPeriod = CurrentStartOfThePeriod;
				Object.PeriodEnding = CurrentEndOfThePeriod_3;
				
			EndIf;
			
		ElsIf AccrualInformation.ThereAreSalesDocuments Then
			
			QueryText = NStr("vi = 'Chứng từ bán hàng trong bảng tính toán sẽ bị xóa.
								|Tiếp tục?';
								|ru = 'Документы продажи в таблице начислений будут очищены.
								|Продолжить?';
								|en = 'Sales documents in the accrual table will be cleared.
								|Continue?'; fa = 'Sales documents in the accrual table will be cleared.
								|Continue?';
								|it = 'Документы продажи в таблице начислений будут очищены.
								|Продолжить?';
								|pl = 'Sales documents in the accrual table will be cleared.
								|Continue?';
								|tr = 'Tahakkuk tablosundaki satış belgeleri temizlenecektir.
								|Devam edilsin mi?'");
			Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
			
			If Response = DialogReturnCode.Yes Then
				
				CurrentStartOfThePeriod = Object.BeginOfPeriod;
				CurrentEndOfThePeriod_3 = Object.PeriodEnding;
				For Each AccrualLine In Object.Accruals Do
					AccrualLine.DocumentSales = Undefined;
				EndDo;
				
			Else
				
				Object.BeginOfPeriod = CurrentStartOfThePeriod;
				Object.PeriodEnding = CurrentEndOfThePeriod_3;
				
			EndIf;
			
		Else
			
			CurrentStartOfThePeriod = Object.BeginOfPeriod;
			CurrentEndOfThePeriod_3 = Object.PeriodEnding
			
		EndIf;
		
	Else
		
		CurrentStartOfThePeriod = Object.BeginOfPeriod;
		CurrentEndOfThePeriod_3 = Object.PeriodEnding
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAccrualsAccordingToServerConditions(Val ResultAddress)
	
	BonusTable = RebatesBasedOnSalesDocuments(ResultAddress);
	
	RevenueColumnName = "";
	ConditionsOfRepublicOfBelarus = Documents.ConditionsOfCustomerRebates.UpToDateData(Object.TermDocument);
	
	If SalesCalculationBase = Enums.RebateCalculationBases.RevenueManagementAccounting
	 Or SalesCalculationBase = Enums.RebateCalculationBases.RevenueLocalAccounting
	 Or SalesCalculationBase = Enums.RebateCalculationBases.RevenueARAPAccounting Then
		
		If ConditionsOfRepublicOfBelarus.ConsiderVAT Then
			RevenueColumnName = "RevenueAmount";
		Else
			RevenueColumnName = "RevenueAmountExcludingVAT";
		EndIf;
		
	ElsIf SalesCalculationBase = Enums.RebateCalculationBases.RevenueBasePrices Then
		
		RevenueColumnName = "AmountInBasePrices";
		
	EndIf;
	
	Object.Accruals.Clear();
	For Each BonusLine In BonusTable Do
		
		AccrualLine = Object.Accruals.Add();
		AccrualLine.Counterparty = BonusLine.Counterparty;
		AccrualLine.Partner = BonusLine.Partner;
		AccrualLine.DocumentSales = BonusLine.DocumentSales;
		If Not IsBlankString(RevenueColumnName) Then
			
			RevenueByLine = BonusLine[RevenueColumnName]; // DefinedType.MonetaryAmountPositiveNegative
			AccrualLine.Revenue = RevenueByLine;
			
		EndIf;
		AccrualLine.CalculationBase = BonusLine.CalculationBase;
		AccrualLine.AmountAccruedBonus = BonusLine.AmountBonus;
		AccrualLine.AmountBonusAccrued = BonusLine.AmountBonus;
		AccrualLine.PopulationBySettlement = True;
		
	EndDo;
	
EndProcedure

&AtServer
Function RebatesCalculationParameters()
	
	Counterparty = Undefined;
	Partner = Undefined;
	
	Detailing = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	If PartyCountDetails = Detailing.ByCounterparty Then
		Counterparty = Object.Counterparty;
	ElsIf PartyCountDetails = Detailing.ByCustomer Then
		Partner = Object.Partner;
	ElsIf PartyCountDetails = Detailing.ByCounterpartyAndCustomer Then
		
		Counterparty = Object.Counterparty;
		Partner = Object.Partner;
		
	EndIf;
	
	CalculationParameters = Reports.CalculateCustomerRebates.RebatesCalculationParameters();
	CalculationParameters.TermDocument = Object.TermDocument;
	CalculationParameters.Organization = Object.Organization;
	CalculationParameters.StartDate = Object.BeginOfPeriod;
	CalculationParameters.EndDate = Object.PeriodEnding;
	CalculationParameters.Counterparty = Counterparty;
	CalculationParameters.Partner = Partner;
	CalculationParameters.Currency = Object.Currency;
	
	Return CalculationParameters;
	
EndFunction

// Parameters:
//  ResultAddress - String
// 
// Returns:
//  ValueTable:
//  * Currency - CatalogRef.Currencies
//  * DocumentSales - DocumentRef.CustomerInvoice, DocumentRef.SaleAdjustment, DocumentRef.CustomerInvoiceServices, DocumentRef.ReturnOfGoodsFromCustomer -
//  * Counterparty - CatalogRef.Counterparties
//  * Organization - CatalogRef.Companies
//  * Partner - CatalogRef.Partners
//  * CalculationBase - Number
//  * AmountBonus - Number
//  * AmountInBasePrices - Number
//  * RevenueAmount - Number
//  * RevenueAmountExcludingVAT - Number
//
&AtServerNoContext
Function RebatesBasedOnSalesDocuments(ResultAddress)
	
	BonusTable = GetFromTempStorage(ResultAddress);
	
	Return BonusTable;
	
EndFunction

&AtClient
Procedure CheckFillingOfDocumentHeader(Cancel)
	
	ListOfVerifiedDetails = New ValueList; // ValueList of String
	ListOfVerifiedDetails.Add("Organization");
	ListOfVerifiedDetails.Add("BeginOfPeriod");
	ListOfVerifiedDetails.Add("PeriodEnding");
	ListOfVerifiedDetails.Add("Currency");
	
	AttributeRepresentationClient = NStr("vi = 'Khách hàng';
										|ru = 'Клиент';
										|en = 'Customer'; fa = 'مشتری';
										|it = 'Клиент';
										|pl = 'Customer';
										|tr = 'Müşteri'");
	
	If PartyCountDetails = PredefinedValue("Enum.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterparty") Then
		
		ListOfVerifiedDetails.Add("Counterparty");
		
	ElsIf PartyCountDetails = PredefinedValue("Enum.ARAPAccountingDrilldownsOfRebatesParticipants.ByCustomer") Then
		
		ListOfVerifiedDetails.Add("Partner", AttributeRepresentationClient);
		
	ElsIf PartyCountDetails = PredefinedValue("Enum.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterpartyAndCustomer") Then
		
		ListOfVerifiedDetails.Add("Counterparty");
		ListOfVerifiedDetails.Add("Partner", AttributeRepresentationClient);
		
	EndIf;
	
	For Each AttributeData In ListOfVerifiedDetails Do
		
		AttributeName = AttributeData.Value;
		If ValueIsFilled(AttributeData.Presentation) Then
			AttributeSynonym = AttributeData.Presentation; // String
		Else
			AttributeSynonym = AttributeName; // String
		EndIf; 
		
		If Not ValueIsFilled(Object[AttributeName]) Then
			
			ErrorText = CommonClientServer.FillingErrorText(,, AttributeSynonym);
			CommonClient.MessageToUser(ErrorText,, AttributeName, "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CheckWhetherCompositionOfConditionsDocumentHasBeenFixed(Cancel)
	
	UpdateDataAboutFixationOfComposition();
	ItIsNecessaryToFixCompositionOfSegments = (CompositionFixationIsAvailable And Not CompositionOfSegmentsIsFixed);
	
	If Not TermsDocumentHasBeenAgreed Then
		
		MessageText = NStr("vi = 'Chưa thống nhất chứng từ điều kiện';
							|ru = 'Документ условий не согласован';
							|en = 'The condition document is not approved'; fa = 'The condition document is not approved';
							|it = 'Документ условий не согласован';
							|pl = 'The condition document is not approved';
							|tr = 'Koşullar belgesi kabul edilmemiş'");
		CommonClient.MessageToUser(MessageText,, "TermDocument", "Object", Cancel);
		
	ElsIf ItIsNecessaryToFixCompositionOfSegments Then
		
		MessageText = NStr("vi = 'Chưa ấn định thành phần của chứng từ điều kiện';
							|ru = 'Не зафиксирован состав документа условий';
							|en = 'Condition document is not recorded'; fa = 'Condition document is not recorded';
							|it = 'Condition document is not recorded';
							|pl = 'Condition document is not recorded';
							|tr = 'Şartlar belgesinin içeriği sabitlenmedi'");
		CommonClient.MessageToUser(MessageText,, "TermDocument", "Object", Cancel);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateFlagForPossibilityOfChangingURB()
	
	If ValueIsFilled(Object.TermDocument) Then
		ThereIsRightToChangeURB = AccessManagement.EditionAllowed(Object.TermDocument);
	Else
		ThereIsRightToChangeURB = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateVisibilityAvailabilityOfRosterFix()
	
	Items.DecorationFixComposition.Enabled = ThereIsRightToChangeURB;
	Items.DecorationFixComposition.Visible = (CompositionFixationIsAvailable And Not CompositionOfSegmentsIsFixed);
	
EndProcedure

&AtServer
Procedure SetTitleOfSceneryFixingComposition()
	
	If ThereIsAdjustmentOnApproval Then
		
		FixText = NStr("vi = 'Đã nhập điều chỉnh có trạng thái ""Cần thống nhất"", cấm ấn định thành phần của chứng từ điều kiện';
						|ru = 'Введена корректировка в статусе ""На согласовании"", фиксация состава документа условий запрещена';
						|en = 'An adjustment is entered in the ""Pending approval"" status. Cannot record the condition document'; fa = 'An adjustment is entered in the ""Pending approval"" status. Cannot record the condition document';
						|it = 'An adjustment is entered in the ""Pending approval"" status. Cannot record the condition document';
						|pl = 'An adjustment is entered in the ""Pending approval"" status. Cannot record the condition document';
						|tr = '""Onay bekliyor"" durumuna düzeltme yapıldı, şartlar belgesi içeriğinin sabitlenmesi yasaktır'");
		
	Else
		
		FixTemplate = NStr("vi = 'Chưa ấn định thành phần của chứng từ điều kiện. <a href=""%1"">Ấn định</a>.';
							|ru = 'Состав документа условий не зафиксирован. <a href=""%1"">Зафиксировать</a>.';
							|en = 'Condition document content is not recorded. <a href=""%1"">Record</a>.'; fa = 'Condition document content is not recorded. <a href=""%1"">Record</a>.';
							|it = 'Condition document content is not recorded. <a href=""%1"">Record</a>.';
							|pl = 'Condition document content is not recorded. <a href=""%1"">Record</a>.';
							|tr = 'Şartlar belgesinin içeriği sabitlenmedi. <a href=""%1"">Sabitle</a>.'");
		FixText = StringFunctionsClientServer.SubstituteParametersToString(
			FixTemplate, "Commit");
		
	EndIf;
	
	Items.DecorationFixComposition.Title = StringFunctions.FormattedString(FixText);
	
EndProcedure

&AtServer
Procedure FillInDataOfLastAdjustment()
	
	ThereIsAdjustmentOnApproval = False;
	If Not Object.TermDocument.IsEmpty() Then
		
		ThereIsAdjustmentOnApproval = RebatesServer.ThereIsAdjustmentOnApproval(Object.TermDocument);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDataBeforeFixingComposition()
	
	FillInDataOfLastAdjustment();
	If ThereIsAdjustmentOnApproval Then
		
		SetTitleOfSceneryFixingComposition();
		
	EndIf;
	
	UpdateDataAboutFixationOfComposition();
	
EndProcedure

&AtServer
Procedure UpdateAvailabilityOfCompositionFixation(TermsAndConditionsAttributes)
	
	If TermsAndConditionsAttributes.Count() = 0 Then
		
		CompositionFixationIsAvailable = False;
		
	ElsIf TermsAndConditionsAttributes.ContentOfGoods = Enums.RebatesItems.ProductSegments
		  Or TermsAndConditionsAttributes.PartyList = Enums.RebatesParticipants.PartnersSegments
		  Or Not IsBlankString(TermsAndConditionsAttributes.ProductItemProperty) Then
		
		CompositionFixationIsAvailable = True;
		
	Else
		
		CompositionFixationIsAvailable = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	SetConditionalAppearanceOfLinesByCalculation();
	SetConditionalAppearanceOfArbitraryLines();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfLinesByCalculation()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsPartner.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsCounterparty.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsDocumentSales.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsRevenue.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsCalculationBase.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsAmountAccruedBonus.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Accruals.PopulationBySettlement");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Font", StyleFonts.BoldFont);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfArbitraryLines()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsAmountAccruedBonus.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Accruals.PopulationBySettlement");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không tính>';
													|ru = '<Без расчета>';
													|en = '<Without calculation>'; fa = '<Without calculation>';
													|it = '<Без расчета>';
													|pl = '<Without calculation>';
													|tr = '<Alacak/Borç muhasebesi olmadan>'"));
	
EndProcedure

#EndRegion

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands

// The Attachable one continues to execute the Commands on the server.
// 
// Parameters:
//  ExecutionParameters - Structure -
//  AdditionalParameters - Structure -
//
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region StandardSubsystems_Properties

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

//@skip-check module-unused-method - implicit call from the property managementmiclient.Post-loadingadditional requirements
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

// End StandardSubsystems.Properties

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
	If Item.Name = "sh_ShamsiInput_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_PeriodEnding" Then
		PeriodEndingOnChange(Items.PeriodEnding);
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
