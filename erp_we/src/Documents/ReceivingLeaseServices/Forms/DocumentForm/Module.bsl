#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.DocumentGroup_2.BackColor = New Color();
	EndIf;
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		Object.Date = CurrentSessionDate();
	EndIf;
	
	FillInListOfSelectedAccrualTypes();
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	ChangeDisplayOfTotals(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.ReceivingLeaseServices.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SetupParameters = Documents.ReceivingLeaseServices.AccountingAccountSettings_(Object.Contract);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);	

	#Region StandardSubsystems
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	OnReadCreateAtServer();
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	ItemsAndDimensionsSelectionParameters = Documents.ReceivingLeaseServices.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SetupParameters = Documents.ReceivingLeaseServices.AccountingAccountSettings_(Object.Contract);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ReceivingLeaseServices", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	CustomizeInvoicePresentation();
	
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject, CurrentObject.AdditionalProperties);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
		
		SelectedRows = Items.Accruals.SelectedRows;
		
		For Each String In SelectedRows Do
			RowData = Object.Accruals.FindByID(String);
			RowData.Department = ValueSelected;
		EndDo;
		
	EndIf;
	
	If VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		CustomizeInvoicePresentation();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
	Return; // WE have an empty handler

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	DateOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdatePurchaseForActivity();
	
	ConfigureDependentFormElements(Item);
	
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	WhenChangingVATTaxationServer();
	ChangeDisplayOfTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure AmountIncludesVATOnChange(Item)
	
	AmountIncludesVATOnChangeServer();
	
EndProcedure

&AtClient
Procedure AdjustmentModeFromPreviousDateOnChange(Item)
	
	If AdjustmentModeFromPreviousDate And Not ValueIsFilled(Object.ActualTransactionDate) Then
		Object.ActualTransactionDate = Object.Date;
	ElsIf Not AdjustmentModeFromPreviousDate Then
		Object.ActualTransactionDate = Date(1,1,1);
	EndIf;
	
	Items.ActualTransactionDate.Enabled = AdjustmentModeFromPreviousDate;
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer();
	
	UpdateColumnHeaders(Items, Object.Currency, Object.ARAPCurrency);
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClickCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(ClosingResult) = Type("Structure") Then
		
		ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
		If ChangedBankingDetails.Count() > 0 Then
			LabelCurrenciesClickCompletionServer(ClosingResult);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	
	If ClosingResult.RecalculateDocumentAmounts Then
		DocumentAmountOnChangeServer(ClosingResult.DocumentAmount);
	EndIf;
	
	UpdateColumnHeaders(Items, Object.Currency, Object.ARAPCurrency);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtClient
Procedure PurchaseForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region FormTableItemsEventHandlersAccruals

&AtClient
Procedure AccrualsSelection(Item, RowSelected, Field, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);

EndProcedure

&AtClient
Procedure AccrualsOnStartEdit(Item, NewRow, Copy)
	
	TableRow = Items.Accruals.CurrentData;
	
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, TableRow, "Object.Accruals");
	
	If Object.VATTaxation <> PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT") Then
		TableRow.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
	EndIf;
	
	//Setting up accounting accounts 
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure AccrualsVATRateOnChange(Item)
	
	
	CurrentRow = Items.Accruals.CurrentData;
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure AccrualsVATAmountOnChange(Item)
	
	CurrentRow = Items.Accruals.CurrentData;
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure AccrualsSumOnChange(Item)
	
	
	CurrentRow = Items.Accruals.CurrentData;
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure AccrualsARAPDocumentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.Organization) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
										|ru = 'Не заполнено поле ""Организация""';
										|en = 'The ""Company"" field is not filled in'; fa = 'The ""Company"" field is not filled in';
										|it = 'Il campo ""Azienda"" non è stato compilato';
										|pl = 'Nie jest wypełnione pole ""Firma""';
										|tr = '""İş Yeri"" alanı doldurulmadı'"), , , , Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Counterparty) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Đối tác""';
										|ru = 'Не заполнено поле ""Контрагент""';
										|en = 'The field ""Counterparty"" is not filled in'; fa = 'The field ""Counterparty"" is not filled in';
										|it = 'Non è compilato il campo ""Contraente""';
										|pl = 'Nie wypełniono pole ""Kontrahent""';
										|tr = '""Cari hesap"" alanı doldurulmadı'"), , , , Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Hợp đồng""';
										|ru = 'Не заполнено поле ""Договор""';
										|en = 'The ""Contract"" field is not filled in'; fa = 'The ""Contract"" field is not filled in';
										|it = 'Il campo ""Contratto"" non è compilato';
										|pl = 'Nie wypełniono pola ""Umowa""';
										|tr = '""Sözleşme"" alanı doldurulmamış'"), , , , Cancel);
	EndIf;
	
	TableRow = Items.Accruals.CurrentData;
	If TableRow = Undefined Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chọn dòng tính toán';
										|ru = 'Не выбрана строка начислений';
										|en = 'An accrual line is not selected'; fa = 'An accrual line is not selected';
										|it = 'Не выбрана строка начислений';
										|pl = 'An accrual line is not selected';
										|tr = 'Tahakkuk satırı seçilmedi'"), , , , Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Counterparty", Object.Counterparty);
	FormParameters.Insert("Contract", Object.Contract);
	FormParameters.Insert("TypeOfLeasePayment", TableRow.AccrualType);
	FormParameters.Insert("SelectedARAPDocument", ?(TableRow = Undefined, Undefined, TableRow.ARAPDocument));
	
	OpenForm("Catalog.LeaseContract.Form.SelectARAPDocument", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure AccrualsARAPDocumentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		TableRow = Items.Accruals.CurrentData;
		TableRow.ARAPDocument = ValueSelected.ARAPDocument;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccrualsExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AccrualsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AccrualsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AccrualsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AccrualsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInTheAccruals(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Accruals;
	
	Notification = New CallbackDescription("FillInTheAccrualsCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#Region AttachableCommands

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

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#EndRegion

#Region Private

#Region OnChangeAttributes

// Parameters:
// 	ChangedDetailsOrElement - FormField, String - 
&AtClient
Procedure ConfigureDependentFormElements(Val ChangedDetailsOrElement = "")

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	EndIf;

EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		ParentCompany = AccountingPoliciesTaxSettingsCached.ParentCompany(Object.Organization);
		SetFormFunctionalOptionParameters(New Structure("Organization", ParentCompany));
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"VNAManagementIsUsed_2_4",
			NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date),
			FormServiceParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization") Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date),
			FormServiceParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		AttributesList = "AssetHolder,RecognizeLeasedItemsInLocalAccounting,RecognizeLeasedAssetsInManagementAccounting,VATTaxation";
		If ValueIsFilled(Object.Contract) Then
			ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, AttributesList);
		Else
			ContractDetails_ = New Structure(AttributesList);
		EndIf;
				
		NonCurrentAssetsInternal.SetStructureProperty(
			"ContractDetails_",
			ContractDetails_,
			FormServiceParameters);
		
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisForm, ChangedBankingDetails);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails)
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;

	Object = Form.Object;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ContractDetails_", Form.FormServiceParameters.ContractDetails_);
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", Form.FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed);
	
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_ReceiptOfRentalServices(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "FA,ServicePaymentSchedule,ServiceAccrualSchedule,InterestAccrualSchedule");
	EndIf;
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	Return StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract");

EndFunction

&AtServer
Procedure WhenChangingVATTaxationServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	If Object.VATTaxation <> Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
		StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	EndIf;
	BatchProcessingOfTablePartServer.TreatTS(Object.Accruals, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Accruals,
		CachedValues);
	
	CustomizeInvoicePresentation();
	
EndProcedure

&AtServer
Procedure AmountIncludesVATOnChangeServer()
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Accruals, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	CompleteVATTaxation();
	WhenChangingVATTaxationServer();
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	Contract = Catalogs.LeaseContract.DefaultContract(
					Object.Organization, Object.Partner, Object.Counterparty, Object.Contract);
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		AgreementWhenModifiedOnServer();
	EndIf;
	
	CustomizeInvoicePresentation();
	
	UpdatePurchaseForActivity();
	
	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	Contract = Catalogs.LeaseContract.DefaultContract(
				Object.Organization, Object.Partner, Object.Counterparty, Object.Contract);
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		AgreementWhenModifiedOnServer();
	EndIf;
	
	CustomizeInvoicePresentation();
	
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	Object.ARAPCurrency = Common.ObjectAttributeValue(Object.Contract, "ARAPCurrency");
	
	CurrencyOfMutualSettlementsOfTheDocument = Object.ARAPCurrency;
	Object.Currency = Object.ARAPCurrency;
	
	CompleteVATTaxation();
	WhenChangingVATTaxationServer();
	
	ChangeDisplayOfTotals(ThisForm);
	
	DocumentOfConclusionOfContractOfLease = Catalogs.LeaseContract.DocumentOfConclusionOfContractOfLease(Object.Contract);
	If ValueIsFilled(DocumentOfConclusionOfContractOfLease) Then 
		Object.PurchaseForActivity = Common.ObjectAttributeValue(DocumentOfConclusionOfContractOfLease, "PurchaseForActivity");
	EndIf;
	
	UpdatePurchaseForActivity();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness,, Object.Contract);
	EndIf;
	
	ConfigureDependentFormElementsOnServer("Contract");
	FillInListOfSelectedAccrualTypes();
	
	CustomizeInvoicePresentation();
	
	SetupParameters = Documents.ReceivingLeaseServices.AccountingAccountSettings_(Object.Contract);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	
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

#EndRegion

#Region WorkingWithCounterparties


&AtClient
Procedure CheckCounterparties(Command)
	
	
	Return; // WE have an empty handler

EndProcedure

#EndRegion

#Region FillType

&AtClient
Procedure FillInTheAccrualsCompletion(Result, AdditionalParameters) Export
	
	If Not CheckSelectionFields() Then
		Return;
	EndIf;
			
	FillInAccrualsOnServer();
	
	If Not Object.Accruals.Count() Then
		Text = StrTemplate(NStr("vi = 'Theo hợp đồng ""%1"" không có lịch biểu tính lãi %2';
								|ru = 'По договору ""%1"" отсутствует график начислений на %2';
								|en = 'There is no accruals schedule for %2 as per contract ""%1""'; fa = 'There is no accruals schedule for %2 as per contract ""%1""';
								|it = 'Per l''accordo ""%1"" manca il grafico di maturazione per %2';
								|pl = 'Dla umowy ""%1"" nie ma harmonogramu naliczeń na %2';
								|tr = '%2 sözleşme için %1''lik bir tahakkuk çizelgesi bulunmamaktadır'"),
			Object.Contract,
			Format(Object.Date, "DLF=D;"));
		CommonClient.MessageToUser(Text);
	EndIf;
	
EndProcedure

&AtClient
Function CheckSelectionFields()
	
	HasErrors = False;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Contract) Then
		Text = NStr("vi = 'Để điền tính lãi, cần chỉ ra doanh nghiệp';
					|ru = 'Для заполнения начислений требуется указание договора';
					|en = 'Specify the contract to fill in accruals'; fa = 'Specify the contract to fill in accruals';
					|it = 'Per la compilazione delle maturazioni è necessario indicare l''accordo';
					|pl = 'Dla wypełnienia naliczeń należy podać umowę';
					|tr = 'Tahakkukları doldurmak için, sözleşmenin bir göstergesi gereklidir'");
		CommonClient.MessageToUser(Text,, "Contract", "Object", HasErrors);
	EndIf;
	
	If Not ValueIsFilled(Object.Date) Then
		Text = NStr("vi = 'Để điền tính lãi, cần chỉ ra ngày chứng từ';
					|ru = 'Для заполнения начислений требуется указание даты документа';
					|en = 'Specify the document date to fill in accruals'; fa = 'Specify the document date to fill in accruals';
					|it = 'Per la compilazione delle maturazioni è necessario indicare la data del documento';
					|pl = 'W celu wypełnienia naliczeń wymagane jest podanie daty dokumentu';
					|tr = 'Tahakkukları doldurmak için belgenin tarihini belirtmeniz gerekir'");
		CommonClient.MessageToUser(Text,, "Date", "Object", HasErrors);
	EndIf;
	
	Return Not HasErrors;
	
EndFunction

&AtServer
Procedure FillInAccrualsOnServer()
	
	Object.Accruals.Clear();
	
	QueryText = 
	"SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TermsOfLeaseContracts.VATRate AS VATRate
	|INTO TTTermsOfLeaseAgreements
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(&Date, Contract = &Contract) AS TermsOfLeaseContracts
	|WHERE TermsOfLeaseContracts.State = VALUE(Enum.CounterpartyContractStates.Valid)
	|
	|INDEX BY
	|	EffectiveContractTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MAX(Schedule.Contract.ExpenseItemServices), UNDEFINED) AS ExpenseItem,
	|	ISNULL(MAX(Schedule.Contract.ExpensesDimensionServices), UNDEFINED) AS DimensionOfExpenses,
	|	ISNULL(MAX(Schedule.Contract.BusinessUnitServices), UNDEFINED) AS Department,
	|	ISNULL(SUM(Schedule.RentalService), 0) AS RentalService,
	|	ISNULL(SUM(Schedule.RentalServiceVAT), 0) AS RentalServiceVAT,
	|	ISNULL(SUM(Schedule.DepositPayment), 0) AS SecurityPaymentSettlement,
	|	ISNULL(SUM(Schedule.SecurityPaymentVATAmount), 0) AS OffsetOfSecurityPaymentOfVAT,
	|	ISNULL(MAX(TermsOfLeaseContracts.VATRate), UNDEFINED) AS VATRate
	|FROM
	|	TTTermsOfLeaseAgreements AS TermsOfLeaseContracts
	|		INNER JOIN InformationRegister.LeaseServicesAccrualSchedule AS Schedule
	|		ON Schedule.EffectiveContractTerms = TermsOfLeaseContracts.EffectiveContractTerms
	|		AND Schedule.Contract = &Contract
	|		AND Schedule.Date BETWEEN &StartDate AND &EndDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FinancialInstrumentsARAPBalance.ARAPDocument      AS ARAPDocument,
	|	FinancialInstrumentsARAPBalance.ARAPDocument.Date AS APARDocumentDate,
	|	FinancialInstrumentsARAPBalance.SumBalance           AS AmountInContractCurrency
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(&DocumentBorder,
	|		AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|	AND Contract = &Contract) AS FinancialInstrumentsARAPBalance
	|WHERE
	|	FinancialInstrumentsARAPBalance.SumBalance > 0
	|
	|ORDER BY
	|	APARDocumentDate";
	
	Query = New Query(QueryText);
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("StartDate", BegOfDay(Object.Date));
	Query.SetParameter("EndDate", EndOfDay(Object.Date));
	Query.SetParameter("DocumentBorder", 
								New Boundary(New PointInTime(Object.Date, Object.Ref), BoundaryType.Excluding));
	
	SamplingPackage = Query.ExecuteBatch();
	Selection = SamplingPackage.Get(1).Select();
	
	TableOfSecurityPayments = SamplingPackage.Get(2).Unload();
	BalanceOfSecurityPayment = TableOfSecurityPayments.Total("AmountInContractCurrency");
	
	While Selection.Next() Do
		
		If Selection.RentalService <> 0 Then
			
			NewRow = Object.Accruals.Add();
			NewRow.AccrualType = Enums.TypesOfLeasePayments.RentalService;
			NewRow.VATRate = Selection.VATRate;
			NewRow.LineOfBusiness = LineOfBusiness;
			
			If Items.AccrualsExpenseItem.Visible Then
				NewRow.ExpenseItem = Selection.ExpenseItem;
				NewRow.DimensionOfExpenses = Selection.DimensionOfExpenses;
				NewRow.Department = Selection.Department;
			EndIf;

			NewRow.AmountIncludingVAT = Selection.RentalService;
			NewRow.VATAmount = Selection.RentalServiceVAT;
			
			If Object.PriceIncludesVAT Then
				NewRow.Sum = Selection.RentalService;
			Else
				NewRow.Sum = Selection.RentalService - Selection.RentalServiceVAT;
			EndIf;
			
		EndIf;
		
		If Selection.SecurityPaymentSettlement <> 0 Then
			
			AmountOfSecurityPaymentToBeClosed = Selection.SecurityPaymentSettlement;
			
			VATOnAllPayments = 0;
			
			
			For Each DepositPayment In TableOfSecurityPayments Do
				
				If AmountOfSecurityPaymentToBeClosed = 0 Then
					Break;
				EndIf;
				
				If DepositPayment.AmountInContractCurrency = 0 Then
					Continue;
				EndIf;
				
				If DepositPayment.AmountInContractCurrency >= AmountOfSecurityPaymentToBeClosed Then
					DepositPayment.AmountInContractCurrency = DepositPayment.AmountInContractCurrency
																- AmountOfSecurityPaymentToBeClosed;
					AmountPerDocument = AmountOfSecurityPaymentToBeClosed;
					AmountOfSecurityPaymentToBeClosed = 0;
				Else
					AmountPerDocument = DepositPayment.AmountInContractCurrency;
					AmountOfSecurityPaymentToBeClosed = AmountOfSecurityPaymentToBeClosed - AmountPerDocument;
					DepositPayment.AmountInContractCurrency = 0;
				EndIf;

				NewRow = Object.Accruals.Add();
				NewRow.AccrualType = Enums.TypesOfLeasePayments.DepositPayment;
				NewRow.VATRate = Selection.VATRate;
				NewRow.LineOfBusiness = LineOfBusiness;

				If Items.AccrualsExpenseItem.Visible Then
					NewRow.ExpenseItem = Selection.ExpenseItem;
					NewRow.DimensionOfExpenses = Selection.DimensionOfExpenses;
					NewRow.Department = Selection.Department;
				EndIf;
				
				// We count VAT by the amount in the document as a share.
				NDSVDocument = Round(Selection.OffsetOfSecurityPaymentOfVAT * AmountPerDocument/Selection.SecurityPaymentSettlement,2);
				VATOnAllPayments = VATOnAllPayments + NDSVDocument;

				NewRow.AmountIncludingVAT = AmountPerDocument;
				NewRow.VATAmount =  NDSVDocument;

				If Object.PriceIncludesVAT Then
					NewRow.Sum = AmountPerDocument;
				Else
					NewRow.Sum = AmountPerDocument - NDSVDocument;
				EndIf;
				
				NewRow.ARAPDocument = DepositPayment.ARAPDocument;
	
			EndDo;
			
			// With full closure, the VAT error will be attributed to the last line of security payments.
			If AmountOfSecurityPaymentToBeClosed = 0 Then
				
				VATError = Selection.OffsetOfSecurityPaymentOfVAT - VATOnAllPayments;
				NewRow.VATAmount = NewRow.VATAmount + VATError;
				
				If Not Object.PriceIncludesVAT Then
					NewRow.Sum = NewRow.Sum - VATError;
				EndIf;
				
			EndIf;
			
			
		EndIf;
		
	EndDo;
	
	IncomeAndExpensesServer.UpdateServiceDetails(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ClearAmountOfSettlements");

	If Object.VATTaxation <> Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
		StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Accruals, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetCorrectionModeFromLastDate()
	
	AdjustmentModeFromPreviousDate = ValueIsFilled(Object.ActualTransactionDate);
	Items.ActualTransactionDate.Enabled = AdjustmentModeFromPreviousDate;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisObject,
		"AccrualsVATRate",
		"AccrualsVATAmount",
		"AccrualsAmountIncludingVAT");
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject, "AccrualsAmountIncludingVAT");
	
	#Region AccrualSecurityPayment_NotRequired
	
	ListOfPayment = New ValueList;
	ListOfPayment.Add(Enums.TypesOfLeasePayments.DepositPayment);
	ListOfPayment.Add(Enums.TypesOfLeasePayments.RentalServicePrepayment);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsARAPDocument.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Accruals.AccrualType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ListOfPayment;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<Не требуется>';
													|en = '<Not needed>'; fa = '<Not needed>';
													|it = '<non richiesto>';
													|pl = '<Nie jest wymagane>';
													|tr = '<Gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region AccrualsAccrualType_RentalService
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsAccrualType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Accruals.AccrualType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfLeasePayments.RentalService;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Dịch vụ thuê';
													|ru = 'Услуга по аренде';
													|en = 'Rental service'; fa = 'خدمات اجاره';
													|it = 'Servizio relativo all''affitto';
													|pl = 'Usługa dotycząca dzierżawy';
													|tr = 'Kiralama hizmeti'"));
	#EndRegion
	
	#Region AccrualsAccrualType_SecurityPayment
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsAccrualType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Accruals.AccrualType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfLeasePayments.DepositPayment;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đối trừ thanh toán đảm bảo';
													|ru = 'Зачет обеспечительного платежа';
													|en = 'Security deposit offset'; fa = 'تهاتر سپرده تضمین';
													|it = 'Compensazione del pagamento cauzionale';
													|pl = 'Zaliczenie płatności zabezpieczającej';
													|tr = 'Teminat ödemesinin mahsubu'"));
	#EndRegion
	
	#Region AccrualsExpenseAnalytics_ViewOnly
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsDimensionOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Accruals.ExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region AccrualsSettlementAmount_Visibility
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualsAmountARAP.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.ARAPCurrency");
	
	Item.Appearance.SetParameterValue("Visible", False);
	#EndRegion
	
EndProcedure

&AtClientAtServerNoContext
Function FieldsForRecalculatingAmountOfNDSInTSLine(Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Form.Object);
	
	Return StructureOfRecalculationOfAmount;
	
EndFunction

&AtServer
Procedure OnReadCreateAtServer()
	
	InitializeServiceParametersOfForm();

	DocumentCurrency = Object.Currency;
	CurrencyOfMutualSettlementsOfTheDocument = Object.ARAPCurrency;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
	UpdateColumnHeaders(Items, Object.Currency, Object.ARAPCurrency);
	
	CustomizeInvoicePresentation();
	
	FillParameters = Documents.ReceivingLeaseServices.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
		
	UpdatePurchaseForActivity(False);
	
	ConfigureDependentFormElementsOnServer();
	
	SetCorrectionModeFromLastDate();
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		Items.AccrualsExpenseItem.Title = NStr("vi = 'Dạng chi phí';
												|ru = 'Статья расходов';
												|en = 'Expense item'; fa = 'قلم هزینه';
												|it = 'Voce di spese';
												|pl = 'Rodzaj kosztu';
												|tr = 'Gider kalemi'");
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness,, Object.Contract);
	EndIf;
	
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
EndProcedure

&AtClient
Procedure TextInvoiceURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesReceived(Object);
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(
		ThisForm,
		FormattedStringURL,
		StandardProcessing,
		RegistrationParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ChangeDisplayOfTotals(Form)
	
	PurchaseIsSubjectToVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(Form.Object.VATTaxation);
	If Not PurchaseIsSubjectToVAT Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeInvoicePresentation()
			
	RegistrationParameters = ParametersForRegisteringInvoicesReceived(Object);
	InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
	
	InvoiceTextReceived = InvoicesReceivedOnBasisOf.Presentation;	
	
EndProcedure

&AtServer
Procedure UpdatePurchaseForActivity(Fill = True)
	
	FillParameters = Documents.ReceivingLeaseServices.ParametersForFillingInVATActivityType(Object);
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.PurchaseForActivity, 
			FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	VATAccountingERP.FillInActivitySelectionList(
		Items.PurchaseForActivity,
		Object.PurchaseForActivity,
		FillParameters, 
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	ArrayOfAmounts = New Array;
	For Each CurRow In Object.Accruals Do
		ArrayOfAmounts.Add(CurRow.AmountIncludingVAT);
	EndDo;
	
	ArrayOfAmounts = Common.DistributeAmountInProportionToCoefficients(DocumentAmount, ArrayOfAmounts);
	
	If ArrayOfAmounts <> Undefined Then
		
		For N1 = 0 To Object.Accruals.Count()-1 Do
			
			CurRow = Object.Accruals[N1];
			CurRow.AmountIncludingVAT = ArrayOfAmounts[N1];
			
			VATRateByNumber = VATAccountingERPClientServer.ValueOfVATRate(CurRow.VATRate);
			
			If ValueIsFilled(CurRow.AmountIncludingVAT) Then
				CurRow.VATAmount = Round(CurRow.AmountIncludingVAT * (VATRateByNumber/(100+VATRateByNumber)), 2);
				CurRow.Sum = CurRow.AmountIncludingVAT - ?(Object.PriceIncludesVAT, 0, CurRow.VATAmount);
			EndIf;
			
			CurRow.AmountARAP = 0;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInListOfSelectedAccrualTypes()
	
	SelectionListAccrualType = Items.AccrualsAccrualType.ChoiceList;
	
	PaymentTypes = Catalogs.LeaseContract.TypesOfPaymentsUnderAgreement(Object.Contract);
	SelectionListAccrualType.LoadValues(PaymentTypes);
	
	ListItem = SelectionListAccrualType.FindByValue(Enums.TypesOfLeasePayments.BuyoutValue);
	If ListItem <> Undefined Then
		SelectionListAccrualType.Delete(ListItem);
	EndIf;
	
	ListItem = SelectionListAccrualType.FindByValue(Enums.TypesOfLeasePayments.RentalService);
	If ListItem <> Undefined Then
		ListItem.Presentation = NStr("vi = 'Dịch vụ thuê';
									|ru = 'Услуга по аренде';
									|en = 'Rental service'; fa = 'خدمات اجاره';
									|it = 'Servizio relativo all''affitto';
									|pl = 'Usługa dotycząca dzierżawy';
									|tr = 'Kiralama hizmeti'");
	EndIf;
	
	ListItem = SelectionListAccrualType.FindByValue(Enums.TypesOfLeasePayments.DepositPayment);
	If ListItem <> Undefined Then
		ListItem.Presentation = NStr("vi = 'Đối trừ thanh toán đảm bảo';
									|ru = 'Зачет обеспечительного платежа';
									|en = 'Security deposit offset'; fa = 'تهاتر سپرده تضمین';
									|it = 'Compensazione del pagamento cauzionale';
									|pl = 'Zaliczenie płatności zabezpieczającej';
									|tr = 'Teminat ödemesinin mahsubu'");
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("ContractDetails_");

	ParameterValue = NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date);
	NewServiceParametersOfForm.Insert("VNAManagementIsUsed_2_4", ParameterValue);

	ParameterValue = LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date);
	NewServiceParametersOfForm.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", ParameterValue);

	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

EndProcedure

&AtClientAtServerNoContext
Procedure UpdateColumnHeaders(Items, Currency, ARAPCurrency)
	
	If ValueIsFilled(Currency) Then
		Items.AccrualsSum.Title = StrTemplate(NStr("vi = 'Số tiền (%1)';
													|ru = 'Сумма (%1)';
													|en = 'Amount (%1)'; fa = 'Amount (%1)';
													|it = 'Totale (%1)';
													|pl = 'Wartość (%1)';
													|tr = 'Tutar (%1)'"), Currency);
	Else
		Items.AccrualsSum.Title = NStr("vi = 'Tổng số';
										|ru = 'Сумма';
										|en = 'Amount'; fa = 'مبلغ';
										|it = 'Importo';
										|pl = 'Amount';
										|tr = 'Tutar'");
	EndIf;
	
	If ValueIsFilled(ARAPCurrency) Then
		Items.AccrualsAmountARAP.Title = StrTemplate(NStr("vi = 'Số tiền hạch toán công nợ (%1)';
															|ru = 'Сумма взаиморасчетов (%1)';
															|en = 'AR/AP amount (%1)'; fa = 'AR/AP amount (%1)';
															|it = 'Importo dei pagamenti reciproci (%1)';
															|pl = 'Wartość rozliczeń wzajemnych (%1)';
															|tr = 'Borç-alacak muhasebesi tutarı (%1)'"), ARAPCurrency);
	Else
		Items.AccrualsAmountARAP.Title = NStr("vi = 'Số tiền hạch toán';
												|ru = 'Сумма взаиморасчетов';
												|en = 'AR/AP amount'; fa = 'مبلغ دریافتنی/پرداختنی';
												|it = 'Importo dei pagamenti reciproci';
												|pl = 'Wartość rozliczeń wzajemnych';
												|tr = 'Borç-alacak muhasebesi tutarı'");
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function ParametersForRegisteringInvoicesReceived(Object)
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	RegistrationParameters.Ref = Object.Ref;
	RegistrationParameters.Date = Object.Date;
	RegistrationParameters.Organization = Object.Organization;
	RegistrationParameters.Counterparty = Object.Counterparty;
	RegistrationParameters.VATTaxation = Object.VATTaxation;
	RegistrationParameters.PurchaseOfGoodsWorksServices = True;
	
	Return RegistrationParameters;
	
EndFunction

&AtServer
Procedure CompleteVATTaxation()
	
	FillParameters = Documents.ReceivingLeaseServices.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	
EndProcedure

// StandardSubsystems.Properties

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
