//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	DocumentModificationIsAvailable = AccessManagement.EditionAllowed(Object.Ref);
	If Not DocumentModificationIsAvailable
	   And Object.Rebates.Count() > 0 Then
		
		// All the conditions for retro bonuses are based on the availability of the organization in the act, so it's enough to check the first one in the list.
		// We don't check for the availability of metadata, because it may be available within another organization (not according to the one in the report).
		
		BonusDocumentsAreAvailable = True;
		For Each BonusLine In Object.Rebates Do
			
			BonusDocumentsAreAvailable = AccessManagement.ReadingAllowed(BonusLine.TermDocument);
			Break;
			
		EndDo;
		
		If Not BonusDocumentsAreAvailable Then
			
			FieldNamesVisibility = New Array; // Array of String
			FieldNamesVisibility.Add(Items.Rebates.Name);
			
			TMCommonUseClientServer.SetPropertyOfFormElements(
				Items,
				FieldNamesVisibility,
				"Visible",
				False,
				True);
			
		EndIf;
		
	EndIf;
	
	OnCreatReadAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.CustomerBonusCertificate.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.CustomerBonusCertificate.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
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
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnCreatReadAtServer();
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.CustomerBonusCertificate.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.CustomerBonusCertificate.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
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
	
	SetPropertiesOfDateOfRecognitionInAccounting(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
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
	
	Notify("Write_CustomerBonusCertificate", WriteParameters, Object.Ref);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	CalculateTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
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
Procedure StatusOnChange(Item)
	
	SetPropertiesOfDateOfRecognitionInAccounting(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure StatusClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer();
	
EndProcedure

// Parameters:
//  Item - FormDecoration - Item
//  StandardProcessing - Boolean
//
&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisObject, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure PresentationOfRecordingInComplAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
	
EndProcedure

&AtClient
Procedure ExpenseItemAssetsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseItemAssetsOnChange(Item)
	
	AssetRefOnChangeServer(Item.Name);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(
		ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(
		ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRebates

&AtClient
Procedure RebatesAfterDeleteRow(Item)
	
	If Object.Rebates.Count() = 0 Then
		
		Object.DocumentCurrency = PredefinedValue("Catalog.Currencies.EmptyRef");
		
	EndIf;
	
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
	CalculateTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure RebatesBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure RebatesBonusAmountOnChange(Item)
	
	CurrentData = Items.Rebates.CurrentData;
	CalculationParameters = StructureOfRecalculationOfAmountOfMutualSettlements(Object);
	CurrentData.AmountARAP = RebatesClientServer.RecalculateAmountOfSettlementsInLine(
		CalculationParameters, CurrentData.BonusAmount, CurrencyOfComplianceAccounting);
	
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
	CalculateTotals(ThisObject);
	
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
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

// StandardSubsystems.FilesOperations

// Parameters:
//  Command - FormCommand - executed command.
//
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
	
EndProcedure

// End StandardSubsystems.FilesOperations

// End StandardSubsystems.AttachableCommands

&AtClient
Procedure PickUpByBalance(Command)
	
	ClearMessages();
	Cancel = False;
	FieldKind = "Field";
	MessageKind = "FillType";
	
	If Not ValueIsFilled(Object.Organization) Then
		
		FieldName = NStr("vi = 'Doanh nghiệp';
						|ru = 'Организация';
						|en = 'Company'; fa = 'Company';
						|it = 'Организация';
						|pl = 'Firma';
						|tr = 'İş yeri'");
		MessageText = CommonClientServer.FillingErrorText(FieldKind, MessageKind, FieldName);
		CommonClient.MessageToUser(MessageText,, "Object.Organization",, Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Counterparty) Then
		
		FieldName = NStr("vi = 'Đối tác';
						|ru = 'Контрагент';
						|en = 'Counterparty'; fa = 'طرف حساب';
						|it = 'Контрагент';
						|pl = 'Kontrahent';
						|tr = 'Cari hesap'");
		MessageText = CommonClientServer.FillingErrorText(FieldKind, MessageKind, FieldName);
		CommonClient.MessageToUser(MessageText,, "Object.Counterparty",, Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Date) Then
		
		FieldName = NStr("vi = 'Ngày';
						|ru = 'Дата';
						|en = 'Date'; fa = 'تاریخ';
						|it = 'Дата';
						|pl = 'Date';
						|tr = 'Tarih'");
		MessageText = CommonClientServer.FillingErrorText(FieldKind, MessageKind, FieldName);
		CommonClient.MessageToUser(MessageText,, "Object.Date",, Cancel);
		
	EndIf;
	
	If Not Cancel Then
		
		PickUpByLeftoversPreparation();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region EventHandlersForFormHeaderElementsAuxiliary

&AtServer
Procedure DateOnChangeServer()
	
	FieldsNames = New Array; // Array of String
	FieldsNames.Add("Date");
	FieldsNames.Add("ARAPCurrency");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, FieldsNames);
	
	CalculationParameters = StructureOfRecalculationOfAmountOfMutualSettlements(Object);
	
	For Each TSRow In Object.Rebates Do
		
		TSRow.AmountARAP = RebatesClientServer.RecalculateAmountOfSettlementsInLine(
			CalculationParameters, TSRow.BonusAmount, CurrencyOfComplianceAccounting);
		
	EndDo;
	
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
	CalculateTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	SetupParameters = Documents.CustomerBonusCertificate.AccountingAccountSettings_();
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	If ValueIsFilled(Object.Counterparty) Then
		
		Object.Partner = Common.ObjectAttributeValue(Object.Counterparty, "Partner");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Partner");
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	NamesOfContractDetails = "ARAPCurrency,LineOfBusiness";
	ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, NamesOfContractDetails);
	Object.ARAPCurrency = ContractDetails_.ARAPCurrency;
	Object.LineOfBusiness = ContractDetails_.LineOfBusiness;
	
	FieldsNames = New Array; // Array of String
	FieldsNames.Add("Contract");
	FieldsNames.Add("ARAPCurrency");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, FieldsNames);
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	CalculationParameters = StructureOfRecalculationOfAmountOfMutualSettlements(Object);
	
	For Each TSRow In Object.Rebates Do
		
		TSRow.AmountARAP = RebatesClientServer.RecalculateAmountOfSettlementsInLine(
			CalculationParameters, TSRow.BonusAmount, CurrencyOfComplianceAccounting);
		
	EndDo;
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
	CalculateTotals(ThisObject);
	
EndProcedure

// Parameters:
//  ClosingResult - Undefined -
//  				  - Structure:
//  	* OldValuesOfChangedProps - Structure
//  	* RecalculateDocumentAmounts - Boolean
//  	* DocumentAmount - Number
//  AdditionalParameters - Arbitrary -
//
&AtClient
Procedure LabelCurrenciesClickCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(ClosingResult) = Type("Structure") Then
		
		ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
		
		If ChangedBankingDetails.Count() > 0 Then
			
			LabelCurrenciesClickCompletionServer(ClosingResult);
			
			If ClosingResult.RecalculateDocumentAmounts Then
				
				PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(
					DocumentCurrency, Object.DocumentCurrency);
				
			EndIf;
			
			LabelCurrenciesClickCompletionServer(ClosingResult);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	
	If ChangedBankingDetails.Property("Currency") Then
		
		DocumentCurrency = Object.DocumentCurrency;
		
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
	CalculateTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure AssetRefOnChangeServer(TagName)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	SetupParameters = Documents.CustomerBonusCertificate.AccountingAccountSettings_();
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure EstablishRelationshipsBetweenContractSelectionParameters()
	
	RelationshipsOfContractParameters = New Array(); // Array of ChoiceParameterLink
	
	NewLink = New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty");
	RelationshipsOfContractParameters.Add(NewLink);
	
	NewLink = New ChoiceParameterLink("Filter.Organization", "Object.Organization");
	RelationshipsOfContractParameters.Add(NewLink);
	
	NewLink = New ChoiceParameterLink("Partner", "Object.Partner");
	RelationshipsOfContractParameters.Add(NewLink);
	
	Items.Contract.ChoiceParameterLinks = New FixedArray(RelationshipsOfContractParameters);
	
	ContractSelectionParameters_ = New Array(); // Array of ChoiceParameter
	
	NewParameter1 = New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid);
	ContractSelectionParameters_.Add(NewParameter1);
	
	NewParameter1 = New ChoiceParameter("Filter.DeletionMark", False);
	ContractSelectionParameters_.Add(NewParameter1);
	
	BusinessTransactionSalesToClient = Enums.BusinessTransactions.SaleToCustomer;
	NewParameter1 = New ChoiceParameter("Filter.BusinessOperation", BusinessTransactionSalesToClient);
	ContractSelectionParameters_.Add(NewParameter1);
	
	Items.Contract.ChoiceParameters = New FixedArray(ContractSelectionParameters_);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	DocumentCurrency = Object.DocumentCurrency;
	EstablishRelationshipsBetweenContractSelectionParameters();
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	CalculateTotals(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetPropertiesOfDateOfRecognitionInAccounting(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	
	FillingIsMandatory = (Object.Status = PredefinedValue("Enum.CustomerBonusCertificateStatuses.Received"));
	
	ItemsNames = New Array; // Array of String
	ItemsNames.Add(Items.AccountingRecognitionDate.Name);
	ItemsNames.Add(Items.ExpenseItemAssets.Name);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemsNames,
		"AutoMarkIncomplete",
		FillingIsMandatory);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotals(Form)
	
	Object = Form.Object;
	Form.AmountOfDocumentBonuses = Object.Rebates.Total("BonusAmount");
	Form.AmountARAP = Object.Rebates.Total("AmountARAP");
	
EndProcedure

&AtClientAtServerNoContext
Function StructureOfRecalculationOfAmountOfMutualSettlements(Object)
	
	Result = New Structure;
	Result.Insert("Currency", Object.DocumentCurrency);
	Result.Insert("CourseNumerator", Object.CourseNumerator);
	Result.Insert("CourseDenominator", Object.CourseDenominator);
	Result.Insert("ARAPCurrency", Object.ARAPCurrency);
	
	Return Result;
	
EndFunction

#EndRegion

#Region SelectionByStock

&AtClient
Async Procedure PickUpByLeftoversPreparation()
	
	If Object.Posted Then
		
		QueryText = NStr("vi = 'Trước khi chọn phương án tính, cần hủy kết chuyển chứng từ. Tiếp tục?';
						|ru = 'Перед подбором начислений необходимо отменить проведение документа. Продолжить?';
						|en = 'Before you pick accruals, unpost the document. Continue?'; fa = 'Before you pick accruals, unpost the document. Continue?';
						|it = 'Перед подбором начислений необходимо отменить проведение документа. Продолжить?';
						|pl = 'Before you pick accruals, unpost the document. Continue?';
						|tr = 'Tahakkukları seçmeden önce belge işlemini iptal etmelisiniz. Devam edilsin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		
		If Response = DialogReturnCode.Yes Then
			
			WriteParameters = New Structure("WriteMode", DocumentWriteMode.UndoPosting);
			Write(WriteParameters);
			
		EndIf;
		
	EndIf;
	
	PickUpRebates();
	
EndProcedure

&AtClient
Procedure PickUpRebates()
	
	AddressOfTableOfSelectedRows = AddressOfTableOfSelectedRows();
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Counterparty", Object.Counterparty);
	PickingParameters.Insert("AddressOfTableOfSelectedRows", AddressOfTableOfSelectedRows);
	PickingParameters.Insert("ChoiceMode", True);
	PickingParameters.Insert("UpdateDate", Object.Date);
	
	If ValueIsFilled(Object.DocumentCurrency) Then
		PickingParameters.Insert("Currency", Object.DocumentCurrency);
	EndIf;
	Notification = New CallbackDescription("PickUpRebatesCompletion", ThisObject);
	
	OpenForm("AccumulationRegister.CustomerRebates.Form.FormForPickingByBalance",
		PickingParameters, ThisObject,,,, Notification);
	
EndProcedure

// Returns:
//	String
//
&AtServer
Function AddressOfTableOfSelectedRows()
	
	TypesDetailsBoolean = New TypeDescription("Boolean");
	TypesDetailsCurrency = New TypeDescription("CatalogRef.Currencies");
	
	Table_SelectedRows = Object.Rebates.Unload();
	Table_SelectedRows.Columns.Add("DocumentSelected", TypesDetailsBoolean);
	Table_SelectedRows.Columns.Add("Check", TypesDetailsBoolean);
	Table_SelectedRows.Columns.Add("Currency", TypesDetailsCurrency);
	
	For Each StringIsMatched In Table_SelectedRows Do
		
		StringIsMatched.DocumentSelected = True;
		StringIsMatched.Check = True;
		StringIsMatched.Currency = Object.DocumentCurrency;
		
	EndDo;
	
	AddressOfTableOfSelectedRows = PutToTempStorage(Table_SelectedRows, UUID);
	
	Return AddressOfTableOfSelectedRows;
	
EndFunction

// Parameters:
//  Result - Undefined, String - 
//  AdditionalParameters - Arbitrary -
//
&AtClient
Procedure PickUpRebatesCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined
	   And IsTempStorageURL(Result) Then
		
		ProcessSelectedRebates(Result);
		
		ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
		CalculateTotals(ThisObject);
		Modified = True;
		
	EndIf;
	
EndProcedure

// Parameters:
//  AddressInStorage - String
//
&AtServer
Procedure ProcessSelectedRebates(Val AddressInStorage)
	
	BalanceTable = TableOfSelectedBalances(AddressInStorage);
	DeleteFromTempStorage(AddressInStorage);
	Object.Rebates.Clear();
	
	If BalanceTable.Count() = 0 Then
		Object.DocumentCurrency = Catalogs.Currencies.EmptyRef();
	Else
		
		If Object.DocumentCurrency.IsEmpty() Then
			
			Object.DocumentCurrency = BalanceTable[0].Currency;
			
			FieldsNames = New Array; // Array of String
			FieldsNames.Add("Date");
			FieldsNames.Add("DocumentCurrency");
			ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, FieldsNames);
			
		EndIf;
		
		CalculationParameters = StructureOfRecalculationOfAmountOfMutualSettlements(Object);
		
		For Each RemainderLine_ In BalanceTable Do
			
			LineRB = Object.Rebates.Add();
			LineRB.TermDocument = RemainderLine_.TermDocument;
			LineRB.Partner = RemainderLine_.Partner;
			LineRB.BeginOfPeriod = RemainderLine_.BeginOfPeriod;
			LineRB.PeriodEnding = RemainderLine_.PeriodEnding;
			LineRB.BonusAmount = RemainderLine_.Sum;
			LineRB.AmountARAP = RebatesClientServer.RecalculateAmountOfSettlementsInLine(
				CalculationParameters, LineRB.BonusAmount, CurrencyOfComplianceAccounting);
			
		EndDo;
		
		ARAPAccountingClientServer.UpdateHyperlinkText(ThisObject);
		
	EndIf;
	
EndProcedure

// Parameters:
//  AddressInStorage - String - Address in the store
// 
// Returns:
//  ValueTable:
//   * TermDocument - DocumentRef.ConditionsOfCustomerRebates
//   * Partner - CatalogRef.Partners
//   * BeginOfPeriod - Date
//   * PeriodEnding - Date
//   * Sum - DefinedType.MonetaryAmountNonNegative
//   * Currency - CatalogRef.Currencies
//
&AtServer
Function TableOfSelectedBalances(AddressInStorage)
	
	Return GetFromTempStorage(AddressInStorage);
	
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

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

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
