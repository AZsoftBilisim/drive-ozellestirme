//@strict-types

#Region Variables

&AtClient
Var CachedValues; // See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues

#EndRegion

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
	CurContract = Object.Contract;
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
	FillInServiceDetailsForProductRange();
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
Async Procedure ContractOnChange(Item)
	
	If CurContract <> Object.Contract
	   And WithoutCalculation
	   And Object.Accruals.Count() > 0 Then
		
		AccrualInformation = SignsOfAccruals();
		
		ChangeAContract = Await ContractNeedsToBeChangedInHeader(AccrualInformation);
		
		If ChangeAContract Then
			
			ProcessContractChangeInHeader();
			
		Else
			
			Object.Contract = CurContract;
			
		EndIf;
		
	Else
		
		ProcessContractChangeInHeader();
		
	EndIf;
	
	ConfigureFormVisibilityAccessibility();
	
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
		FixCompositionOfDocument();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccruals

&AtClient
Procedure AccrualsOnActivateRow(Item)
	
	SaveDataOfCurrentLine();
	
EndProcedure

&AtClient
Procedure AccrualsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Copy Then
		
		CurrentData.PopulationBySettlement = False;
		CurrentData.AmountAccruedBonus = 0;
		
	ElsIf NewRow Then
		
		FillInAccrualLineAccordingToHeaderData(CurrentData, Object);
		
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

&AtClient
Procedure AccrualsCounterpartyOnChange(Item)
	
	CurrentData = Items.Accruals.CurrentData;
	PreviousData = AccrualLineData; // See NewRowsData
	
	If CurrentData <> Undefined
	   And CurrentData.Counterparty <> PreviousData.Counterparty Then
		
		If ValueIsFilled(CurrentData.DocumentAcquisitions) Then
			CurrentData.DocumentAcquisitions = DefaultPurchaseDocument();
		EndIf;
		
		CurrentData.Contract = Undefined;
		
		SaveDataOfCurrentLine();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AccrualsPartnerOnChange(Item)
	
	CurrentData = Items.Accruals.CurrentData;
	PreviousData = AccrualLineData; // See NewRowsData
	
	If CurrentData <> Undefined
	   And CurrentData.Partner <> PreviousData.Partner Then
		
		If ValueIsFilled(CurrentData.DocumentAcquisitions) Then
			CurrentData.DocumentAcquisitions = DefaultPurchaseDocument();
		EndIf;
		
		ContractIsInAccruals = FillInVHFContract();
		
		If ContractIsInAccruals Then
			CurrentData.Contract = Undefined;
		EndIf;
		
		CurrentData.Terms = Undefined;
		
		SaveDataOfCurrentLine();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AccrualsContractOnChange(Item)
	
	CurrentData = Items.Accruals.CurrentData;
	PreviousData = AccrualLineData; // See NewRowsData
	
	If CurrentData <> Undefined
	   And CurrentData.Contract <> PreviousData.Contract Then
		
		If ValueIsFilled(CurrentData.Contract) Then
			
			ContractData = ContractDataTS(CurrentData.Contract);
			
			If Not ValueIsFilled(CurrentData.Counterparty) Then
				CurrentData.Counterparty = ContractData.Counterparty;
			EndIf;
			
			If Not ValueIsFilled(CurrentData.Partner) Then
				CurrentData.Partner = ContractData.Partner;
			EndIf;
			
		EndIf;
		
		CurrentData.DocumentAcquisitions = DefaultPurchaseDocument();
		
		SaveDataOfCurrentLine();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AccrualsTermsOnChange(Item)
	
	CurrentData = Items.Accruals.CurrentData;
	PreviousData = AccrualLineData; // See NewRowsData
	
	If CurrentData <> Undefined
	   And CurrentData.Terms <> PreviousData.Terms Then
		
		If ValueIsFilled(CurrentData.Terms) Then
			
			TheseAgreements = TheseAgreementsTS(CurrentData.Terms);
			
			If Not ValueIsFilled(CurrentData.Partner) Then
				CurrentData.Partner = TheseAgreements.Partner;
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(CurrentData.DocumentAcquisitions) Then
			CurrentData.DocumentAcquisitions = DefaultPurchaseDocument();
		EndIf;
		
		SaveDataOfCurrentLine();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AccrualsProductsOnChange(Item)
	
	CurrentData = Items.Accruals.CurrentData;
	
	StructureOfActions = New Structure; 
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		CurrentData,
		StructureOfActions,
		CachedValues);
	
EndProcedure

&AtClient
Procedure AccrualsTermsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	RowData = Items.Accruals.CurrentData;
	
	AgreementSelectionParameters = New Array; // Array of ChoiceParameter
	If RowData <> Undefined
	   And Not RowData.Partner.IsEmpty() Then
		
		NewFilter = New ChoiceParameter("Filter.Partner", RowData.Partner);
		AgreementSelectionParameters.Add(NewFilter);
		
	EndIf;
	
	Item.ChoiceParameters = New FixedArray(AgreementSelectionParameters);
	
EndProcedure

&AtClient
Procedure AccrualsDocumentAcquisitionsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterParameters = PurchaseDocumentSelectionParameters();
	DocumentIDs = AcceptableTypesOfPurchaseDocuments();
	BusinessTransactions = OfOperationsOfAcquisitionDocuments();
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("FilterDocumentTypes", DocumentIDs);
	FormParameters.Insert("FilterBusinessTransactions", BusinessTransactions);
	
	SaveDataOfCurrentLine();
	
	FormParameters.Insert("PurposeUseKey", "PurchaseDocumentsAllSelection");
	OpenForm(
		"DataProcessor.LogOfPurchaseDocuments.Form.DocumentsList",
		FormParameters,
		Items.AccrualsDocumentAcquisitions,
		UniqueKey,
		,
		,
		,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AccrualsDocumentAcquisitionsOnChange(Item)
	
	CurrentData = Items.Accruals.CurrentData;
	DocumentData = DataOfPurchaseDocument(CurrentData.DocumentAcquisitions);
	
	PreviousData = AccrualLineData; // See NewRowsData
	
	If Not ValueIsFilled(PreviousData.Counterparty) Then
		CurrentData.Counterparty = DocumentData.Counterparty;
	EndIf;
	
	If Not ValueIsFilled(PreviousData.Partner) Then
		CurrentData.Partner = DocumentData.Partner;
	EndIf;
	
	If Not ValueIsFilled(PreviousData.Contract) Then
		CurrentData.Contract = DocumentData.Contract;
	EndIf;
	
	If Not ValueIsFilled(PreviousData.Terms) Then
		CurrentData.Terms = DocumentData.Terms;
	EndIf;
	
	SaveDataOfCurrentLine();
	
EndProcedure

&AtClient
Procedure AccrualsContractStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	RowData = Items.Accruals.CurrentData;
	
	ContractParameters = ContractSelectionParameters_(RowData);
	Item.ChoiceParameters = New FixedArray(ContractParameters);
	
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
		
		If Object.BonusType <> PredefinedValue("Enum.VendorRebateTypes.Balance") Then
			CheckPeriodsByTimeFence(Cancel);
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		
		CheckFixationOfCompositionOfDocument(Cancel);
		
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
		
		If WithoutCalculation Then
			
			FillInAccrualsWithoutCalculation();
			
		Else
			
			CalculationParameters = RebatesCalculationParameters();
			CallbackOnCompletion = New CallbackDescription("FillInAccrualsAccordingToEndConditions", ThisObject);
			
			CommonClientServer.SetFormItemProperty(
				Items,
				Items.AccrualsFillInAccordingToConditions.Name,
				"Enabled",
				False);
			
			RebatesClient.RebatesForPeriodAccordingToPurchaseDocuments(
				CalculationParameters,
				ThisObject,
				CallbackOnCompletion);
			
		EndIf;
		
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
				
				Object.TermDocument = Documents.ConditionsOfVendorRebates.EmptyRef();
				CurrentConditionsDocument = Documents.ConditionsOfVendorRebates.EmptyRef();
				ClearDetailsByCondition(ThisObject);
				
			EndIf;
			
		EndIf;
		
	Else
		
		Object.TermDocument = Documents.ConditionsOfVendorRebates.EmptyRef();
		CurrentConditionsDocument = Documents.ConditionsOfVendorRebates.EmptyRef();
		ClearDetailsByCondition(ThisObject);
		
	EndIf;
	
	ConfigureFormVisibilityAccessibility();
	UpdateLinksOfParametersForSelectingConditionDocument();
	
EndProcedure

&AtServer
Procedure TermDocumentOnChangeServer()
	
	Object.Counterparty = Catalogs.Counterparties.EmptyRef();
	Object.Partner = Catalogs.Partners.EmptyRef();
	Object.Contract = Catalogs.CounterpartyContracts.EmptyRef();
	
	UpdateFlagForPossibilityOfChangingURB();
	FillInDataOfLastAdjustment();
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(Object.TermDocument);
	ValueToFormAttribute(DocumentObject, "Object");
	
	Object.Accruals.Clear();
	
	UpdateLinksOfParametersForSelectingConditionDocument();
	FillInServiceDetailsOfFormAccordingToCondition();
	SetTitleOfSceneryFixingComposition();
	
	ConfigureFormVisibilityAccessibility();
	SetRevenueColumnHeader();
	
	CalculateDocumentTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure TermDocumentClearingServer()
	
	CurrentConditionsDocument = PredefinedValue("Document.ConditionsOfVendorRebates.EmptyRef");
	Object.TermDocument = PredefinedValue("Document.ConditionsOfVendorRebates.EmptyRef");
	ClearDetailsByCondition(ThisObject);
	UpdateFlagForPossibilityOfChangingURB();
	SetTitleOfSceneryFixingComposition();
	ConfigureFormVisibilityAccessibility();
	SetRevenueColumnHeader();
	
EndProcedure

&AtClient
Async Procedure FixCompositionOfDocument()
	
	UpdateDataBeforeFixingComposition();
	If Not ThereIsAdjustmentOnApproval
	   And Not CompositionOfSegmentsIsFixed Then
		
		QueryText = NStr("vi = 'Ấn định thành phần phân khúc của chứng từ điều kiện?';
						|ru = 'Зафиксировать состав документа условий?';
						|en = 'Do you want to record the condition document?'; fa = 'Do you want to record the condition document?';
						|it = 'Do you want to record the condition document?';
						|pl = 'Do you want to record the condition document?';
						|tr = 'Şartlar belgesinin içeriği sabitlensin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		
		If Response = DialogReturnCode.Yes Then
			
			CallbackOnCompletion = New CallbackDescription("FixCompositionOfDocumentCompletion", ThisObject);
			NotificationOfOperationIsInProgress = New CallbackDescription(
				"OfOperationsArePerformedToFixCompositionOfDocument",
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
			MessageText = NStr("vi = 'Không thể ấn định thành phần phân khúc: đã nhập điều chỉnh trong trạng thái ""Cần thống nhất"".';
								|ru = 'Невозможно зафиксировать состав: введена корректировка в статусе ""На согласовании"".';
								|en = 'Cannot record the document: an adjustment is registered in the ""Pending approval"" status.'; fa = 'Cannot record the document: an adjustment is registered in the ""Pending approval"" status.';
								|it = 'Cannot record the document: an adjustment is registered in the ""Pending approval"" status.';
								|pl = 'Cannot record the document: an adjustment is registered in the ""Pending approval"" status.';
								|tr = 'İçerik sabitlenemiyor: ""Onay bekliyor"" durumunda düzeltme yapıldı.'");
		Else
			MessageText = NStr("vi = 'Đã ấn định thành phần chứng từ.';
								|ru = 'Состав документа уже зафиксирован.';
								|en = 'The document content is already recorded.'; fa = 'The document content is already recorded.';
								|it = 'The document content is already recorded.';
								|pl = 'The document content is already recorded.';
								|tr = 'Belge içeriği hâlihazırda sabitlendi.'");
		EndIf;
		
		CommonClient.MessageToUser(MessageText,, "TermDocument", "Object");
		ConfigureFormVisibilityAccessibility();
		SetRevenueColumnHeader();
		
	EndIf;
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure FixCompositionOfDocumentCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined
	   And Result.Status = "Error" Then
		
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		
	EndIf;
	
	UpdateDataBeforeFixingComposition();
	ConfigureFormVisibilityAccessibility();
	SetRevenueColumnHeader();
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure OfOperationsArePerformedToFixCompositionOfDocument(Result, AdditionalParameters) Export
	
	MessageText = NStr("vi = 'Theo chứng từ điều kiện, đã thực hiện các giao dịch ấn định thành phần. Hãy thử lại sau.';
						|ru = 'По документу условий уже выполняются операции по фиксации состава. Попробуйте позже.';
						|en = 'Recording operations for the condition document are already in process. Try again later.'; fa = 'Recording operations for the condition document are already in process. Try again later.';
						|it = 'Recording operations for the condition document are already in process. Try again later.';
						|pl = 'Recording operations for the condition document are already in process. Try again later.';
						|tr = 'Şartlar belgesi kapsamında içerik düzeltme işlemleri hâlihazırda gerçekleştirilmektedir. Daha sonra tekrar deneyin.'");
	
	CommonClient.MessageToUser(MessageText);
	ConfigureFormVisibilityAccessibility();
	SetRevenueColumnHeader();
	
EndProcedure

&AtServer
Procedure CheckPeriodsByTimeFence(Cancel)
	
	If Not Cancel
	   And (Object.BeginOfPeriod > EndDateOfCondition
	      Or Object.PeriodEnding < StartDateOfCondition) Then
		
		ErrorText = NStr("vi = 'Chứng từ điều kiện không có hiệu lực trong kỳ tính toán đã chọn';
						|ru = 'Документ условия не действует в указанном периоде начисления';
						|en = 'The condition document is not available for the specified accrual period.'; fa = 'The condition document is not available for the specified accrual period.';
						|it = 'Документ условия не действует в указанном периоде начисления';
						|pl = 'The condition document is not available for the specified accrual period.';
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
	
	TermsAndConditionsAttributes = Documents.ConditionsOfVendorRebates.UpToDateData(Object.TermDocument);
	
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

&AtClient
Async Function ContractNeedsToBeChangedInHeader(AccrualInformation)
	
	ChangeAContract = False;
	QueryText = TextOfQuestionAboutChangingContractInHeader(AccrualInformation);
	
	If Not IsBlankString(QueryText) Then
		
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		
		If Response = DialogReturnCode.Yes Then
			ChangeAContract = True;
		EndIf;
		
	Else
		ChangeAContract = True;
	EndIf;
	
	Return ChangeAContract;
	
EndFunction

&AtClient
Function TextOfQuestionAboutChangingContractInHeader(AccrualInformation)
	
	QueryText = "";
	If CurContract.IsEmpty() Then
		
		If AccrualInformation.ThereAreDocumentsOfAcquisitionsNotUnderContractInHeader 
		   And AccrualInformation.ThereIsContractThatIsNotEqualToFieldInHeader Then
			
			QueryText = NStr("vi = 'Sẽ thực hiện tính toán theo hợp đồng được chọn. Sẽ xóa chứng từ mua hàng theo hợp đồng được chọn.
								|Tiếp tục?';
								|ru = 'Начисление будет произведено по выбранному договору. Документы приобретения по договорам, отличным от выбранного, будут очищены.
								|Продолжить?';
								|en = 'The accrual will be made for the selected contract. Purchase documents under contracts other than the selected one will be cleared.
								|Continue?'; fa = 'The accrual will be made for the selected contract. Purchase documents under contracts other than the selected one will be cleared.
								|Continue?';
								|it = 'Начисление будет произведено по выбранному договору. Документы приобретения по договорам, отличным от выбранного, будут очищены.
								|Продолжить?';
								|pl = 'The accrual will be made for the selected contract. Purchase documents under contracts other than the selected one will be cleared.
								|Continue?';
								|tr = 'Seçili sözleşme için tahakkuk yapılacaktır. Seçili sözleşme dışındaki sözleşmeler için satın alma belgeleri temizlenecektir.
								|Devam edilsin mi?'");
		
		ElsIf AccrualInformation.ThereIsContractThatIsNotEqualToFieldInHeader Then
			
			QueryText = NStr("vi = 'Sẽ thực hiện tính toán theo hợp đồng được chọn.
								|Tiếp tục?';
								|ru = 'Начисление будет произведено по выбранному договору.
								|Продолжить?';
								|en = 'The accrual will be made for the selected contract.
								|Continue?'; fa = 'The accrual will be made for the selected contract.
								|Continue?';
								|it = 'Начисление будет произведено по выбранному договору.
								|Продолжить?';
								|pl = 'The accrual will be made for the selected contract.
								|Continue?';
								|tr = 'Tahakkuk, seçili sözleşme için gerçekleştirilecektir.
								|Devam edilsin mi?'");
			
		EndIf;
		
	ElsIf AccrualInformation.ThereAreAcquisitionDocuments
			And Not Object.Contract.IsEmpty() Then
		
		QueryText = NStr("vi = 'Chứng từ mua hàng trong bảng tính toán sẽ bị xóa.
							|Tiếp tục?';
							|ru = 'Документы приобретения в таблице начислений будут очищены.
							|Продолжить?';
							|en = 'Purchase documents in the accrual table will be cleared.
							|Continue?'; fa = 'Purchase documents in the accrual table will be cleared.
							|Continue?';
							|it = 'Документы приобретения в таблице начислений будут очищены.
							|Продолжить?';
							|pl = 'Purchase documents in the accrual table will be cleared.
							|Continue?';
							|tr = 'Tahakkuk tablosundaki belgeler temizlenecektir.
							|Devam edilsin mi?'");
		
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtClient
Procedure ProcessContractChangeInHeader()
	
	CurContract = Object.Contract;
	If Not WithoutCalculation
	 Or Not Object.Contract.IsEmpty() Then
		
		For Each AccrualLine In Object.Accruals Do
			
			If AccrualLine.Contract <> Object.Contract Then
				AccrualLine.DocumentAcquisitions = Undefined;
			EndIf;
			
			AccrualLine.Contract = Object.Contract;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsOfAccrualFormAuxiliary

&AtServerNoContext
Function DataOfPurchaseDocument(Val DocumentAcquisitions);
	
	AttributesNames = New Array; // Array of String
	AttributesNames.Add("Counterparty");
	AttributesNames.Add("Partner");
	AttributesNames.Add("Contract");
	AttributesNames.Add("Terms");
	
	DocumentData = Common.ObjectAttributesValues(DocumentAcquisitions, AttributesNames);
	Return DocumentData;
	
EndFunction

&AtServerNoContext
Function ContractDataTS(Val Contract);
	
	AttributesNames = New Array; // Array of String
	AttributesNames.Add("Counterparty");
	AttributesNames.Add("Partner");
	
	DocumentData = Common.ObjectAttributesValues(Contract, AttributesNames);
	Return DocumentData;
	
EndFunction

&AtServerNoContext
Function TheseAgreementsTS(Val Terms);
	
	AttributesNames = New Array; // Array of String
	AttributesNames.Add("Partner");
	
	DocumentData = Common.ObjectAttributesValues(Terms, AttributesNames);
	Return DocumentData;
	
EndFunction

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
	SetRevenueColumnHeader();
	FillInServiceDetailsForProductRange();
	CalculateDocumentTotals_(ThisObject);
	
	ContractTypes = RebatesClientServer.TypesOfProcurementContracts();
	SupportedContractTypes = New FixedArray(ContractTypes);
	TMCommonUseClientServer.AddSelectionParameter(Items.Contract, "ContractType", SupportedContractTypes);
	
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
		
		TermsAndConditionsAttributes = Documents.ConditionsOfVendorRebates.UpToDateData(Object.TermDocument);
		
		WithoutCalculation = TermsAndConditionsAttributes.WithoutCalculation;
		AccrualFrequency = TermsAndConditionsAttributes.AccrualFrequency;
		BaseOfCalculation = TermsAndConditionsAttributes.BaseOfCalculation;
		GoodsIndicator = TermsAndConditionsAttributes.GoodsIndicator;
		CurrentStartOfThePeriod = TermsAndConditionsAttributes.ValidOnDate;
		CurrentEndOfThePeriod_3 = TermsAndConditionsAttributes.ValidTo;
		StartDateOfCondition = TermsAndConditionsAttributes.ValidOnDate;
		EndDateOfCondition = TermsAndConditionsAttributes.ValidTo;
		DateOfRemainingGoods = TermsAndConditionsAttributes.DateOfRemainingGoods;
		CurrentCurrency = TermsAndConditionsAttributes.Currency;
		AmountBonus = TermsAndConditionsAttributes.AmountBonus;
		
		If CurrentCurrency = Catalogs.Currencies.EmptyRef() Then
			
			CurrentCurrency = Object.Currency;
			
		EndIf;
		 
		ThereIsContractInTermsDocument = ValueIsFilled(TermsAndConditionsAttributes.Contract);
		
		UpdateAvailabilityOfCompositionFixation(TermsAndConditionsAttributes);
		CompositionOfSegmentsIsFixed = TermsAndConditionsAttributes.RecordingIsCompleted;
		RebatesServer.CheckRebateKindOfTermsAndConditionsDocument(Object.TermDocument, TermsAndConditionsAttributes);
		
	Else
		
		ClearDetailsByCondition(ThisObject);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureFormVisibilityAccessibility()
	
	ElementNamesVisibilityAll = New Array; // Array of String
	ElementNamesVisibilityAll.Add(Items.Counterparty.Name);
	ElementNamesVisibilityAll.Add(Items.Partner.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsCounterparty.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsPartner.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsContract.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsCustomer.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsDocumentAcquisitions.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsProducts.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsCharacteristic.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsCalculationBase.Name);
	ElementNamesVisibilityAll.Add(Items.Contract.Name);
	ElementNamesVisibilityAll.Add(Items.Terms.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsTerms.Name);
	ElementNamesVisibilityAll.Add(Items.AccrualsRevenue.Name);
	ElementNamesVisibilityAll.Add(Items.BeginOfPeriod.Name);
	ElementNamesVisibilityAll.Add(Items.PeriodEnding.Name);
	ElementNamesVisibilityAll.Add(Items.SetDateInterval.Name);
	ElementNamesVisibilityAll.Add(Items.DateOfRemainingGoods.Name);
	ElementNamesVisibilityAll.Add(Items.DecorationFixComposition.Name);
	ElementNamesVisibilityAll.Add(Items.Currency.Name);
	
	ItemNamesOnlyViewAll = New Array; // Array of String
	ItemNamesOnlyViewAll.Add(Items.BeginOfPeriod.Name);
	ItemNamesOnlyViewAll.Add(Items.PeriodEnding.Name);
	ItemNamesOnlyViewAll.Add(Items.Currency.Name);
	ItemNamesOnlyViewAll.Add(Items.Contract.Name);
	ItemNamesOnlyViewAll.Add(Items.Terms.Name);
	
	NamesOfVisibleElements = New Array; // Array of String
	
	If CompositionFixationIsAvailable 
	   And Not CompositionOfSegmentsIsFixed Then
		
		NamesOfVisibleElements.Add(Items.DecorationFixComposition.Name);
		
	EndIf;
	
	ItemNamesAreViewOnly = New Array; // Array of String
	If AccrualFrequency = Enums.RebatesFrequencies.Single Then
		
		ItemNamesAreViewOnly.Add(Items.BeginOfPeriod.Name);
		ItemNamesAreViewOnly.Add(Items.PeriodEnding.Name);
		
	EndIf;
	
	If BaseOfCalculation <> Enums.RebateCalculationBases.PurchaseAmountARAPAccounting
	 Or Object.BonusType <> Enums.VendorRebateTypes.Purchases
	 Or GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
	 Or WithoutCalculation Then
		
		ItemNamesAreViewOnly.Add(Items.Currency.Name);
		
	EndIf;
	
	If Object.BonusType = Enums.VendorRebateTypes.Sales
	   Or Object.BonusType = Enums.VendorRebateTypes.Purchases
	   Or WithoutCalculation Then
		
		NamesOfVisibleElements.Add(Items.AccrualsRevenue.Name);
		
	EndIf;
	
	If Object.BonusType = Enums.VendorRebateTypes.Purchases Then
		
		ItemNamesAreViewOnly.Add(Items.Contract.Name);
		ItemNamesAreViewOnly.Add(Items.Terms.Name);
		
	ElsIf ThereIsContractInTermsDocument Then
		
		ItemNamesAreViewOnly.Add(Items.Contract.Name);
		
	EndIf;
	
	If ValueIsFilled(Object.TermDocument) Then
		
		VendorData = Documents.ConditionsOfVendorRebates.CurrentSupplierData(Object.TermDocument);
		
		VisibilityOfHeaderCounterparty = FillInCounterpartyInHeader(VendorData);
		VisibilityOfHeaderPartner = FillInPartnerInHeader(VendorData);
		VisibilityOfContractHeader = FillInContractInHeader(VendorData);
		VisibilityOfHeaderAgreement = FillInAgreementInHeader(VendorData);
		ContractVisibilityTS = FillInVHFContract();
		
		If VisibilityOfHeaderCounterparty Then
			NamesOfVisibleElements.Add(Items.Counterparty.Name);
		EndIf;
		
		If VisibilityOfHeaderPartner Then
			NamesOfVisibleElements.Add(Items.Partner.Name);
		EndIf;
		
		If VisibilityOfContractHeader Then
			NamesOfVisibleElements.Add(Items.Contract.Name);
		EndIf;
		
		If VisibilityOfHeaderAgreement Then
			NamesOfVisibleElements.Add(Items.Terms.Name);
		EndIf;
		
		If ContractVisibilityTS Then
			NamesOfVisibleElements.Add(Items.AccrualsContract.Name);
		EndIf;
		
		If Object.BonusType = Enums.VendorRebateTypes.Purchases Then
			
			If Not VisibilityOfHeaderCounterparty Then
				NamesOfVisibleElements.Add(Items.AccrualsCounterparty.Name);
			EndIf;
			
			If Not VisibilityOfHeaderPartner Then
				NamesOfVisibleElements.Add(Items.AccrualsPartner.Name);
			EndIf;
			
			If Not VisibilityOfHeaderAgreement Then
				NamesOfVisibleElements.Add(Items.AccrualsTerms.Name);
			EndIf;
			
		EndIf;
		
		If WithoutCalculation
		 Or Object.BonusType = Enums.VendorRebateTypes.Purchases Then
			
			NamesOfVisibleElements.Add(Items.AccrualsDocumentAcquisitions.Name);
			
		EndIf;
		
		If Object.BonusType = Enums.VendorRebateTypes.Sales Then
			
			NamesOfVisibleElements.Add(Items.AccrualsCustomer.Name);
			
		EndIf;
		
		If WithoutCalculation Then
			NamesOfVisibleElements.Add(Items.AccrualsDocumentAcquisitions.Name);
		EndIf;
		
		If Object.BonusType = Enums.VendorRebateTypes.Balance Then
			
			NamesOfVisibleElements.Add(Items.DateOfRemainingGoods.Name);
			NamesOfVisibleElements.Add(Items.AccrualsProducts.Name);
			NamesOfVisibleElements.Add(Items.AccrualsCharacteristic.Name);
			
		Else
			
			NamesOfVisibleElements.Add(Items.BeginOfPeriod.Name);
			NamesOfVisibleElements.Add(Items.PeriodEnding.Name);
			NamesOfVisibleElements.Add(Items.AccrualsCalculationBase.Name);
			If AccrualFrequency <> Enums.RebatesFrequencies.Single Then
				NamesOfVisibleElements.Add(Items.SetDateInterval.Name);
			EndIf;
			
		EndIf;
		
		NamesOfVisibleElements.Add(Items.Currency.Name);
		
	EndIf;
	
	Items.DecorationFixComposition.Enabled = ThereIsRightToChangeURB;
	
	TMCommonUseClientServer.SetVisibilityOfElementsByArray(
		Items, ElementNamesVisibilityAll, NamesOfVisibleElements);
	
	RebatesClientServer.SetOnlyViewOfElementsByArray(
		Items, ItemNamesOnlyViewAll, ItemNamesAreViewOnly);
	
EndProcedure

&AtServer
Function FillInVHFContract()
	
	Result = ValueIsFilled(Object.TermDocument)
				And (Object.BonusType = Enums.VendorRebateTypes.Purchases
				   Or WithoutCalculation)
				And Object.Contract.IsEmpty();
	
	Return Result;
	
EndFunction

&AtServer
Function FillInAgreementInHeader(VendorData)
	
	Result = ValueIsFilled(Object.TermDocument)
				And Object.BonusType = Enums.VendorRebateTypes.Purchases
				And Not VendorData.Terms.IsEmpty();
	
	Return Result;
	
EndFunction

&AtServer
Function FillInContractInHeader(VendorData)
	
	Result = ValueIsFilled(Object.TermDocument)
				And Object.BonusType <> Enums.VendorRebateTypes.Purchases
				Or Not VendorData.Contract.IsEmpty()
				Or WithoutCalculation;
	
	Return Result;
	
EndFunction

&AtServer
Function FillInPartnerInHeader(VendorData)
	
	Result = ValueIsFilled(Object.TermDocument)
				And Object.BonusType <> Enums.VendorRebateTypes.Purchases
				Or Not VendorData.Partner.IsEmpty();
	
	Return Result;
	
EndFunction

&AtServer
Function FillInCounterpartyInHeader(VendorData)
	
	Result = ValueIsFilled(Object.TermDocument)
				And Object.BonusType <> Enums.VendorRebateTypes.Purchases
				Or Not VendorData.Counterparty.IsEmpty();
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetRevenueColumnHeader()
	
	If Object.BonusType = Enums.VendorRebateTypes.Purchases
	 Or WithoutCalculation Then
		
		Items.AccrualsRevenue.Title = NStr("vi = 'Tổng tiền';
											|ru = 'Сумма закупки';
											|en = 'Purchase amount'; fa = 'مبلغ خرید';
											|it = 'Сумма закупки';
											|pl = 'Wartość zakupu';
											|tr = 'Satın alma tutarı'");
		
	Else
		
		Items.AccrualsRevenue.Title = NStr("vi = 'Doanh thu';
											|ru = 'Выручка';
											|en = 'Revenue'; fa = 'درآمد';
											|it = 'Выручка';
											|pl = 'Revenue';
											|tr = 'Gelir'");
		
	EndIf;
	
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
	Form.DateOfRemainingGoods = DateEmpty;
	Object.Currency = PredefinedValue("Catalog.Currencies.EmptyRef");
	Form.CurrentCurrency = PredefinedValue("Catalog.Currencies.EmptyRef");
	Object.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
	Form.CurrentCounterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");;
	Object.Partner = PredefinedValue("Catalog.Partners.EmptyRef");
	Form.CurPartner = PredefinedValue("Catalog.Partners.EmptyRef");
	Object.Contract = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
	Form.CurContract = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
	Object.Terms = PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef");
	Form.ThereIsContractInTermsDocument = False;
	Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.EmptyRef");
	Object.Accruals.Clear();
	
	Form.WithoutCalculation = False;
	Form.AccrualFrequency = PredefinedValue("Enum.RebatesFrequencies.EmptyRef");
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

&AtClient
Function PurchaseDocumentSelectionParameters()
	
	RowData = Items.Accruals.CurrentData;
	
	SelectionOfPurchaseDocument = New Structure();
	
	If Not Object.Organization.IsEmpty() Then
		SelectionOfPurchaseDocument.Insert("Organization", Object.Organization);
	EndIf;
	
	If RowData <> Undefined
	   And Not RowData.Counterparty.IsEmpty() Then
		
		SelectionOfPurchaseDocument.Insert("Counterparty", RowData.Counterparty);
		
	ElsIf Not Object.Counterparty.IsEmpty() Then
		SelectionOfPurchaseDocument.Insert("Counterparty", Object.Counterparty);
	EndIf;
	
	If RowData <> Undefined
	   And Not RowData.Partner.IsEmpty() Then
		
		SelectionOfPurchaseDocument.Insert("Partner", RowData.Partner);
		
	ElsIf Not Object.Partner.IsEmpty() Then
		SelectionOfPurchaseDocument.Insert("Partner", Object.Partner);
	EndIf;
	
	If RowData <> Undefined
	   And Not RowData.Contract.IsEmpty() Then
		
		SelectionOfPurchaseDocument.Insert("Contract", RowData.Contract);
		
	EndIf;
	
	If RowData <> Undefined
	   And Not RowData.Terms.IsEmpty() Then
		
		SelectionOfPurchaseDocument.Insert("Terms", RowData.Terms);
		
	EndIf;
	
	Return SelectionOfPurchaseDocument;
	
EndFunction

&AtServerNoContext
Function AcceptableTypesOfPurchaseDocuments()
	
	DocumentTypes = New Array; // Array of MetadataObjectDocument
	DocumentTypes.Add(Metadata.Documents.VendorInvoice);
	DocumentTypes.Add(Metadata.Documents.PurchaseAdjustment);
	DocumentTypes.Add(Metadata.Documents.ReturnOfGoodsToVendor);
	DocumentTypes.Add(Metadata.Documents.RedemptionOfGoodsFromStorage);
	
	DocumentIDs = New Array; // Array of CatalogRef.MetadataObjectIDs
	
	DocumentIdentifiersByType = Common.MetadataObjectIDs(DocumentTypes);
	For Each KeyAndValue In DocumentIdentifiersByType Do
		
		DocumentIDs.Add(KeyAndValue.Value);
		
	EndDo;
	
	Return DocumentIDs;
	
EndFunction

&AtClient
Function OfOperationsOfAcquisitionDocuments()
	
	ExcludedTransactions = New Array; // Array of EnumRef.BusinessTransactions
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsToVendor"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.RedemptionOfGoodsFromStorage"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ErrorCorrection"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.AdjustBeforeEnteringBalance"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEU"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorLocal"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseViaAdvanceHolder"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseByImport"));
	ExcludedTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportGoodsInTransit"));
	
	Return ExcludedTransactions;
	
EndFunction

&AtClient
Function ContractSelectionParameters_(RowData)
	
	ContractSelectionParameters_ = New Array(); // Array of ChoiceParameter
	
	FilterType = New ChoiceParameter("Filter.ContractType", SupportedContractTypes);
	ContractSelectionParameters_.Add(FilterType);
	
	FilterCheck = New ChoiceParameter("Filter.DeletionMark", False);
	ContractSelectionParameters_.Add(FilterCheck);
	
	If ValueIsFilled(RowData.Counterparty) Then
		
		NewFilter = New ChoiceParameter("Filter.Counterparty", RowData.Counterparty);
		ContractSelectionParameters_.Add(NewFilter);
		
	EndIf;
	
	If ValueIsFilled(RowData.Partner) Then
		
		NewFilter = New ChoiceParameter("Partner", RowData.Partner);
		ContractSelectionParameters_.Add(NewFilter);
		
	EndIf;
	
	Return ContractSelectionParameters_;
	
EndFunction

// Returns:
//  Structure - Signs of Accruals:
// * ThereAreAccrualsByCalculation - Boolean - 
// * ThereAreAcquisitionDocuments - Boolean - 
// * ThereAreContracts - Boolean - 
// * ThereIsContractThatIsNotEqualToFieldInHeader - Boolean - 
// * ThereAreDocumentsOfAcquisitionsNotUnderContractInHeader - Boolean - 
&AtClient
Function SignsOfAccruals()
	
	Result = New Structure;
	Result.Insert("ThereAreAccrualsByCalculation", False);
	Result.Insert("ThereAreAcquisitionDocuments", False);
	Result.Insert("ThereAreContracts", False);
	Result.Insert("ThereIsContractThatIsNotEqualToFieldInHeader", False);
	Result.Insert("ThereAreDocumentsOfAcquisitionsNotUnderContractInHeader", False);
	
	For Each AccrualLine In Object.Accruals Do
		
		If ValueIsFilled(AccrualLine.DocumentAcquisitions) Then
			
			Result.ThereAreAcquisitionDocuments = True;
			
			If AccrualLine.Contract <> Object.Contract Then
			
				Result.ThereAreDocumentsOfAcquisitionsNotUnderContractInHeader = True;
				
			EndIf; 
			
		EndIf;
		
		If ValueIsFilled(AccrualLine.Contract) Then
			
			Result.ThereAreContracts = True;
			
		EndIf;
		
		If AccrualLine.PopulationBySettlement Then
			
			Result.ThereAreAccrualsByCalculation = True;
			
		EndIf;
		
		If AccrualLine.Contract <> Object.Contract Then
			
			Result.ThereIsContractThatIsNotEqualToFieldInHeader = True;
			
		EndIf;
		
		If Result.ThereAreAccrualsByCalculation
		   And Result.ThereAreAcquisitionDocuments
		   And Result.ThereAreContracts
		   And Result.ThereIsContractThatIsNotEqualToFieldInHeader
		   And Result.ThereAreDocumentsOfAcquisitionsNotUnderContractInHeader Then
			
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
	
	If Object.BonusType = Enums.VendorRebateTypes.Sales Then
		FillInSalesAccruals(ResultAddress);
	ElsIf Object.BonusType = Enums.VendorRebateTypes.Purchases Then
		FillInChargesForPurchases(ResultAddress);
	ElsIf Object.BonusType = Enums.VendorRebateTypes.Balance Then
		FillInAccrualsForBalances(ResultAddress);
	EndIf;
	
	FillParameters = New Structure("Products", "ItemVariantsAreUsed");
	
	StructureOfActions = New Structure; 
	StructureOfActions.Insert("FillInFeatureAttribute", FillParameters);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Accruals, StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillInSalesAccruals(ResultAddress)
	
	BonusTable = RebatesBasedOnSalesDocuments(ResultAddress);
	
	RevenueColumnName = "";
	ConditionsOfRepublicOfBelarus = Documents.ConditionsOfVendorRebates.UpToDateData(Object.TermDocument);
	
	If BaseOfCalculation = Enums.RebateCalculationBases.RevenueManagementAccounting
	 Or BaseOfCalculation = Enums.RebateCalculationBases.RevenueLocalAccounting
	 Or BaseOfCalculation = Enums.RebateCalculationBases.RevenueARAPAccounting Then
		
		If ConditionsOfRepublicOfBelarus.ConsiderVAT Then
			RevenueColumnName = "AmountOfTurnoverWithVAT";
		Else
			RevenueColumnName = "AmountOfTurnoverExcludingVAT";
		EndIf;
		
	ElsIf BaseOfCalculation = Enums.RebateCalculationBases.RevenueBasePrices Then
		
		RevenueColumnName = "AmountInBasePrices";
		
	EndIf;
	
	Object.Accruals.Clear();
	For Each BonusLine In BonusTable Do
		
		AccrualLine = Object.Accruals.Add();
		
		FillInAccrualLineAccordingToHeaderData(AccrualLine, Object);
		AccrualLine.Customer = BonusLine.CounterpartyCustomer;
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
Procedure FillInChargesForPurchases(ResultAddress)
	
	BonusTable = RebatesAccordingToPurchaseDocuments(ResultAddress);
	
	RevenueColumnName = "";
	ConditionsOfRepublicOfBelarus = Documents.ConditionsOfVendorRebates.UpToDateData(Object.TermDocument);
	
	If BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountBasePrices Then
		
		RevenueColumnName = "AmountInBasePrices";
		
	Else
		
		If ConditionsOfRepublicOfBelarus.ConsiderVAT Then
			RevenueColumnName = "AmountOfTurnoverWithVAT";
		Else
			RevenueColumnName = "AmountOfTurnoverExcludingVAT";
		EndIf;
		
	EndIf;
	
	Object.Accruals.Clear();
	For Each BonusLine In BonusTable Do
		
		AccrualLine = Object.Accruals.Add();
		
		FillInAccrualLineAccordingToHeaderData(AccrualLine, Object);
		FillInAccrualLineBasedOnBonusData(AccrualLine, BonusLine);
		AccrualLine.Customer = BonusLine.CounterpartySupplier;
		AccrualLine.DocumentAcquisitions = BonusLine.DocumentRecorder;
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
Procedure FillInAccrualsForBalances(ResultAddress)
	
	BonusTable = BalanceRebates(ResultAddress);
	
	Object.Accruals.Clear();
	For Each BonusLine In BonusTable Do
		
		AccrualLine = Object.Accruals.Add();
		
		FillInAccrualLineAccordingToHeaderData(AccrualLine, Object);
		AccrualLine.Products = BonusLine.Products;
		AccrualLine.Characteristic = BonusLine.Characteristic;
		AccrualLine.AmountAccruedBonus = BonusLine.AmountBonus;
		AccrualLine.AmountBonusAccrued = BonusLine.AmountBonus;
		AccrualLine.PopulationBySettlement = True;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FillInAccrualsWithoutCalculation()
	
	Object.Accruals.Clear();
	FillInServiceDetailsOfFormAccordingToCondition();
	
	AccrualLine = Object.Accruals.Add();
	AccrualLine.Counterparty = Object.Counterparty;
	AccrualLine.Partner = Object.Partner;
	AccrualLine.Terms = Object.Terms;
	AccrualLine.Contract = Object.Contract;
	AccrualLine.AmountAccruedBonus = AmountBonus;
	AccrualLine.AmountBonusAccrued = AmountBonus;
	AccrualLine.PopulationBySettlement = True;
	
EndProcedure

&AtServer
Function RebatesCalculationParameters()
	
	CalculationParameters = Reports.CalculateVendorRebates.RebatesCalculationParameters();
	CalculationParameters.TermDocument = Object.TermDocument;
	CalculationParameters.StartDate = Object.BeginOfPeriod;
	CalculationParameters.EndDate = EndOfDay(Object.PeriodEnding);
	CalculationParameters.DateOfRemainingGoods = EndOfDay(DateOfRemainingGoods);
	CalculationParameters.Currency = Object.Currency;
	
	Return CalculationParameters;
	
EndFunction

// Parameters:
//  ResultAddress - String
// 
// Returns:
//  ValueTable:
//  * Currency - CatalogRef.Currencies
//  * CounterpartyCustomer - CatalogRef.Counterparties
//  * Organization - CatalogRef.Companies
//  * CalculationBase - Number
//  * AmountBonus - Number
//  * AmountInBasePrices - Number
//  * AmountOfTurnoverExcludingVAT - Number
//  * AmountOfTurnoverWithVAT - Number
//  * SumPlan - Number
//
&AtServerNoContext
Function RebatesBasedOnSalesDocuments(ResultAddress)
	
	BonusTable = GetFromTempStorage(ResultAddress);
	
	Return BonusTable;
	
EndFunction

// Parameters:
//  ResultAddress - String
// 
// Returns:
//  ValueTable:
//  * Currency - CatalogRef.Currencies
//  * CounterpartySupplier - CatalogRef.Counterparties
//  * PartnerVendor - CatalogRef.Partners
//  * SupplierAgreement - CatalogRef.CounterpartyContracts
//  * SupplierTerms - CatalogRef.TermsOfPurchaseFromVendors
//  * DocumentRecorder - DocumentRef.VendorInvoice, DocumentRef.PurchaseAdjustment, DocumentRef.ReturnOfGoodsToVendor, DocumentRef.RedemptionOfGoodsFromStorage -
//  * Organization - CatalogRef.Companies
//  * CalculationBase - Number
//  * AmountBonus - Number
//  * AmountInBasePrices - Number
//  * AmountOfTurnoverExcludingVAT - Number
//  * AmountOfTurnoverWithVAT - Number
//  * SumPlan - Number
//
&AtServerNoContext
Function RebatesAccordingToPurchaseDocuments(ResultAddress)
	
	BonusTable = GetFromTempStorage(ResultAddress);
	
	Return BonusTable;
	
EndFunction

// Parameters:
//  ResultAddress - String
// 
// Returns:
//  ValueTable:
//  * Products - CatalogRef.Products
//  * Characteristic - CatalogRef.ItemsCharacteristics
//  * AmountBonus - Number
//
&AtServerNoContext
Function BalanceRebates(ResultAddress)
	
	BonusTable = GetFromTempStorage(ResultAddress);
	
	Return BonusTable;
	
EndFunction

&AtServer
Procedure CheckFillingOfDocumentHeader(Cancel)
	
	ListOfVerifiedDetails = New ValueList; // ValueList of String
	ListOfVerifiedDetails.Add(Items.Organization.Name);
	ListOfVerifiedDetails.Add(Items.Currency.Name);
	
	If Object.BonusType <> Enums.VendorRebateTypes.Balance Then
		
		ListOfVerifiedDetails.Add(Items.BeginOfPeriod.Name);
		ListOfVerifiedDetails.Add(Items.PeriodEnding.Name);
		
	EndIf;
	
	VendorData = Documents.ConditionsOfVendorRebates.CurrentSupplierData(Object.TermDocument);
	CheckCounterparty = FillInCounterpartyInHeader(VendorData);
	CheckingPartner = FillInPartnerInHeader(VendorData);
	
	If CheckCounterparty Then
		ListOfVerifiedDetails.Add(Items.Counterparty.Name);
	EndIf;
	
	If CheckingPartner Then
		
		PartnerPresentation = NStr("vi = 'Nhà cung cấp';
									|ru = 'Поставщик';
									|en = 'Vendor'; fa = 'تأمین‌کننده';
									|it = 'Поставщик';
									|pl = 'Vendor';
									|tr = 'Tedarikçi'");
		ListOfVerifiedDetails.Add(Items.Partner.Name, PartnerPresentation);
		
	EndIf;
	
	For Each AttributeData In ListOfVerifiedDetails Do
		
		AttributeName = AttributeData.Value; // String
		If ValueIsFilled(AttributeData.Presentation) Then
			AttributeSynonym = AttributeData.Presentation;
		Else
			AttributeSynonym = AttributeName;
		EndIf; 
		
		If Not ValueIsFilled(Object[AttributeName]) Then
			
			ErrorText = CommonClientServer.FillingErrorText(,, AttributeSynonym);
			Common.MessageToUser(ErrorText,, AttributeName, "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CheckFixationOfCompositionOfDocument(Cancel)
	
	UpdateDataAboutFixationOfComposition();
	ItIsNecessaryToFixComposition = (CompositionFixationIsAvailable And Not CompositionOfSegmentsIsFixed);
	
	If Not TermsDocumentHasBeenAgreed Then
		
		MessageText = NStr("vi = 'Chưa thống nhất chứng từ điều kiện';
							|ru = 'Документ условий не согласован';
							|en = 'The condition document is not approved'; fa = 'The condition document is not approved';
							|it = 'Документ условий не согласован';
							|pl = 'The condition document is not approved';
							|tr = 'Koşullar belgesi kabul edilmemiş'");
		CommonClient.MessageToUser(MessageText,, "TermDocument", "Object", Cancel);
		
	ElsIf ItIsNecessaryToFixComposition Then
		
		MessageText = NStr("vi = 'Chưa ghi nhận thành phần của chứng từ điều kiện';
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
		
		FixText = NStr("vi = 'Đã nhập điều chỉnh có trạng thái ""Cần thống nhất"", cấm ấn định thành phần phân khúc';
						|ru = 'Введена корректировка в статусе ""На согласовании"", фиксация состава запрещена';
						|en = 'An adjustment is entered in the ""Pending approval"" status. Cannot record the document content'; fa = 'An adjustment is entered in the ""Pending approval"" status. Cannot record the document content';
						|it = 'An adjustment is entered in the ""Pending approval"" status. Cannot record the document content';
						|pl = 'An adjustment is entered in the ""Pending approval"" status. Cannot record the document content';
						|tr = '""Onay bekliyor"" durumunda düzeltme yapıldı, içeriğin sabitlenmesi yasaktır'");
		
	Else
		
		FixTemplate = NStr("vi = 'Chưa ấn định thành phần của chứng từ điều kiện. <a href=""%1"">Ấn định</a>.';
							|ru = 'Состав документа не зафиксирован. <a href=""%1"">Зафиксировать</a>.';
							|en = 'The document content is not recorded. <a href=""%1"">Record</a>.'; fa = 'The document content is not recorded. <a href=""%1"">Record</a>.';
							|it = 'The document content is not recorded. <a href=""%1"">Record</a>.';
							|pl = 'The document content is not recorded. <a href=""%1"">Record</a>.';
							|tr = 'Belgenin içeriği sabitlenmedi. <a href=""%1"">Sabitle</a>.'");
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
//
//#EndRegion

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.Accruals, ParametersForFillingInBankingDetails);
	
EndProcedure

&AtClient
Procedure SaveDataOfCurrentLine()
	
	RowData = NewRowsData();
	CurrentData = Items.Accruals.CurrentData;
	If CurrentData <> Undefined Then
		
		FillPropertyValues(RowData, CurrentData);
		
	EndIf;
	
	AccrualLineData = New FixedStructure(RowData);
	
EndProcedure

// New row data.
// 
// Returns:
//  Structure - New Row Data:
// * Counterparty - CatalogRef.Counterparties - 
// * Partner - CatalogRef.Partners - 
// * Contract - CatalogRef.CounterpartyContracts - 
// * Terms - CatalogRef.TermsOfPurchaseFromVendors - 
// * DocumentAcquisitions - Undefined -
//                        - See Document.AccrualOfVendorRebates.Accruals.DocumentAcquisitions
//
&AtClient
Function NewRowsData()
	
	RowData = New Structure;
	RowData.Insert("Counterparty", PredefinedValue("Catalog.Counterparties.EmptyRef"));
	RowData.Insert("Partner", PredefinedValue("Catalog.Partners.EmptyRef"));
	RowData.Insert("Contract", PredefinedValue("Catalog.CounterpartyContracts.EmptyRef"));
	RowData.Insert("Terms", PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef"));
	RowData.Insert("DocumentAcquisitions", Undefined);
	
	Return RowData;
	
EndFunction

&AtClientAtServerNoContext
Procedure FillInAccrualLineAccordingToHeaderData(RowData, Object)
	
	RowData.Counterparty = Object.Counterparty;
	RowData.Partner = Object.Partner;
	RowData.Contract = Object.Contract;
	RowData.Terms = Object.Terms;
	RowData.DocumentAcquisitions = DefaultPurchaseDocument();
	
EndProcedure

&AtServerNoContext
Procedure FillInAccrualLineBasedOnBonusData(RowData, BonusData)
	
	If Not ValueIsFilled(RowData.Counterparty) Then
		RowData.Counterparty = BonusData.CounterpartySupplier;
	EndIf;
	
	If Not ValueIsFilled(RowData.Partner) Then
		RowData.Partner = BonusData.PartnerVendor;
	EndIf;
	
	If Not ValueIsFilled(RowData.Contract) Then
		RowData.Contract = BonusData.SupplierAgreement;
	EndIf;
	
	If Not ValueIsFilled(RowData.Terms) Then
		RowData.Terms = BonusData.SupplierTerms;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAvailabilityOfCompositionFixation(TermsAndConditionsAttributes)
	
	If TermsAndConditionsAttributes.Count() = 0 Then
		
		CompositionFixationIsAvailable = False;
		
	ElsIf TermsAndConditionsAttributes.ContentOfGoods = Enums.RebatesItems.ProductSegments
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
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		"AccrualsCharacteristic",
		"Object.Accruals.ItemVariantsAreUsed");
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfLinesByCalculation()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsCounterparty.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsPartner.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsCustomer.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsContract.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsTerms.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsProducts.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsCharacteristic.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsDocumentAcquisitions.Name);
	
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

&AtClientAtServerNoContext
Function DefaultPurchaseDocument()
	
	Return PredefinedValue("Document.VendorInvoice.EmptyRef");
	
EndFunction

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
