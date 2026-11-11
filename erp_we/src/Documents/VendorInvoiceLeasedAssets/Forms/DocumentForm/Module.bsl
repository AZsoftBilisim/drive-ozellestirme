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
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	AccountingMechanismsWhenCreatedOnServer();
	
	AddressOffsetOfAdvances = PutToTempStorage(Undefined, UUID);
	
	#Region StandardSubsystems
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	
	If GetFunctionalOption("UseTraceableImportedGoodsAccounting") Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
		AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, 
			Items.TraceableGoodsCCDNumber.Name, True);		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnReadCreateAtServer();
	
	AccountingMechanismsWhenReadingOnServer();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting And Not DataOnTraceableGoodsIsCorrect() Then
		Cancel = True;	
	EndIf;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	

	Return; // WE have an empty handler

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
		
	Notify("Write_VendorInvoiceLeasedAssets", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	CustomizeInvoicePresentation();
	
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject, CurrentObject.AdditionalProperties);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		CustomizeInvoicePresentation();
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);

	DateOfChangeOnServer();
	
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	OrganizationWhenChangedOnServer();
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	FillInTheContract();

EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyWhenChangesAreMadeOnServer();
	FillInTheContract();
	

EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer();
	FillInTheContract();
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure TextInvoiceURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesReceived(Object);
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(
		ThisObject,
		FormattedStringURL,
		StandardProcessing,
		RegistrationParameters);
	
EndProcedure

&AtClient
Procedure IncomeItemBuyoutStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure IncomeItemBuyoutOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpenseItemTaxBuyoutStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemTaxBuyoutOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpensesDimensionInCaseOfEarlyBuyoutStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionInCaseOfEarlyBuyoutAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionInCaseOfEarlyBuyoutTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChange(Item)
	
	If Not Object.GeneratedDocument Then
		Object.DocumentBasis = Undefined;
		Return;
	EndIf; 
	

	ListFilter = New Structure;
	ListFilter.Insert("Posted", True);
	If ValueIsFilled(Object.Organization) Then
		ListFilter.Insert("Organization", Object.Organization);
	EndIf;
	
	CallbackDescription = New CallbackDescription("GeneratedDocumentOnChangeCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", ListFilter);
	OpenForm("Document.LeaseTermAdjustment.ChoiceForm", FormParameters,,,,, CallbackDescription);

EndProcedure

#EndRegion

#Region AdditionalPage

&AtClient
Procedure VATTaxationOnChange(Item)
	
	WhenChangingVATTaxationServer();
	
EndProcedure

&AtClient
Procedure PurchaseForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATWhenChangedOnServer();

EndProcedure

#EndRegion

#Region Localization

&AtClient
Procedure Attachable_OnChangeAttribute(Item)

	VendorInvoiceLeasedAssetsClientLocalization.OnChangeAttribute(Item, ThisObject);

EndProcedure

&AtClient
Procedure Attachable_StartChoice(Item, ChoiceData, StandardProcessing)
	
	VendorInvoiceLeasedAssetsClientLocalization.StartChoice(Item, ChoiceData, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	VendorInvoiceLeasedAssetsClientLocalization.AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	VendorInvoiceLeasedAssetsClientLocalization.TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export
	
	Var ActionParameters;

	If NotificationParameters.ServerCallRequired_ Then
		WhenYouChangeDetailsOfCompletionOnServer(TagName, NotificationParameters.ProcessingParameters);
	EndIf;

	If Not NotificationParameters.ServerCallRequired_ Then
		
		If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
			ConfigureDependentFormElements(ActionParameters);
		EndIf;

	EndIf;
	
EndProcedure

&AtServer
Procedure WhenYouChangeDetailsOfCompletionOnServer(Val TagName, Val AdditionalParameters)
	
	Var ActionParameters;

	VendorInvoiceLeasedAssetsLocalization.OnChangeAttribute(TagName, ThisObject, AdditionalParameters);

	If AdditionalParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElementsOnServer(ActionParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FAOnStartEdit(Item, NewRow, Copy)
	
	TableRow = Items.FA.CurrentData;
	
	If Object.VATTaxation <> PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT") Then
		TableRow.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
	EndIf;

EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	
	FAIsPrimaryMeansWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure FASumOnChange(Item)
	
	CurrentRow = Items.FA.CurrentData;
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure FAVATRateOnChange(Item)
	
	CurrentRow = Items.FA.CurrentData;
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure FAVATAmountOnChange(Item)
	
	CurrentRow = Items.FA.CurrentData;
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure FAFixedAssetStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Object.GeneratedDocument Then
		StandardProcessing = False;
		
		Filter = New Structure;
		Filter.Insert("Ref", ListOfFoundationDocumentFA(Object.DocumentBasis));
		
		FormParameters = New Structure("Filter", Filter);
		
		OpenForm("Catalog.Assets.Form.ChoiceForm2_4", FormParameters, ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInTheRentedOnes(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Contract) Then
		MessageText = NStr("vi = 'Cần chọn hợp đồng';
							|ru = 'Необходимо выбрать договор';
							|en = 'Select a contract'; fa = 'Select a contract';
							|it = 'È necessario selezionare l''accordo';
							|pl = 'Należy wybrać umowę';
							|tr = 'Bir sözleşme seçmek gereklidir'");
		CommonClient.MessageToUser(MessageText,, "Contract", "Object");
		Return;
	EndIf;
	
	If Object.FA.Count() <> 0 Then
		QueryText = NStr("vi = 'Điền danh sách đối tượng thuê theo hợp đồng?';
						|ru = 'Заполнить список предметов аренды по договору?';
						|en = 'Populate the list of rental objects under the contract?'; fa = 'Populate the list of rental objects under the contract?';
						|it = 'Compilare l''elenco degli elementi di affitto in base all''accordo?';
						|pl = 'Wypełnić listę przedmiotów dzierżawy zgodnie z umową?';
						|tr = 'Sözleşme kapsamında kiralanan eşyaların listesini doldurun?'");
		CallbackDescription = New CallbackDescription("FillInTheRentedOnesCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		FillWithRentedOnServer();
	EndIf;

EndProcedure

&AtClient
Procedure PrepaymentsSettlement(Command)
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.Organization) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
										|ru = 'Не заполнено поле ""Организация""';
										|en = 'The ""Company"" field is not filled in'; fa = 'The ""Company"" field is not filled in';
										|it = 'Il campo ""Azienda"" non è stato compilato';
										|pl = 'Nie jest wypełnione pole ""Firma""';
										|tr = '""İş Yeri"" alanı doldurulmadı'"),,,, Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Counterparty) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Đối tác""';
										|ru = 'Не заполнено поле ""Контрагент""';
										|en = 'The field ""Counterparty"" is not filled in'; fa = 'The field ""Counterparty"" is not filled in';
										|it = 'Non è compilato il campo ""Contraente""';
										|pl = 'Nie wypełniono pole ""Kontrahent""';
										|tr = '""Cari hesap"" alanı doldurulmadı'"),,,, Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Hợp đồng""';
										|ru = 'Не заполнено поле ""Договор""';
										|en = 'The ""Contract"" field is not filled in'; fa = 'The ""Contract"" field is not filled in';
										|it = 'Il campo ""Contratto"" non è compilato';
										|pl = 'Nie wypełniono pola ""Umowa""';
										|tr = '""Sözleşme"" alanı doldurulmamış'"),,,, Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	PlaceOffsettingOfAdvancesInTemporaryStorage();
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref", Object.Ref);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Partner", Object.Partner);
	FormParameters.Insert("Counterparty", Object.Counterparty);
	FormParameters.Insert("Contract", Object.Contract);
	FormParameters.Insert("Currency", Object.Currency);
	FormParameters.Insert("ARAPCurrency", Object.ARAPCurrency);
	FormParameters.Insert("Rate", Object.CourseNumerator);
	FormParameters.Insert("Repetition", Object.CourseDenominator);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("DocumentAmount", PriceManagementSystemClientServer.GetDocumentAmount(Object.FA, Object.PriceIncludesVAT));
	FormParameters.Insert("AddressOffsetOfAdvances", AddressOffsetOfAdvances);
	FormParameters.Insert("ThereIsPrepaymentOfBuyoutValue", FormServiceParameters.ContractDetails_.ThereIsPrepaymentOfBuyoutValue);
	
	OpenForm("Document.VendorInvoiceLeasedAssets.Form.PrepaymentsSettlement",
		FormParameters,,,,, New CallbackDescription("PrepaymentsSettlementCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#Region AttachableCommands

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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)

	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

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
	
	If UpdateAll Then
		
		If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
			Items.DocumentGroup_2.BackColor = New Color();
		EndIf;
		
		Items.LineOfBusinessTaxAccounting.Visible = False;
		Items.LineOfBusinessBonusDepreciation.Visible = False;

	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrencyPresentation",
			String(SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization)),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrenciesDoNotMatch",
			FormServiceParameters.ComplCurrencyPresentation = FormServiceParameters.CurrencyOfManPresentation,
			FormServiceParameters);
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
		Or UpdateAll Then

		AccountingForTraceableGoodsLocalization.SetVisibilityOfTraceableGoodsPage(ThisObject, Object.Date);

	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization") Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date),
			FormServiceParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Currency")
		Or UpdateAll Then
		
		Items.FASum.Title = NonCurrentAssetsClientServer.AddCurrencyToLine(
				NStr("vi = 'Tổng số';
					|ru = 'Сумма';
					|en = 'Amount'; fa = 'مبلغ';
					|it = 'Importo';
					|pl = 'Wartość';
					|tr = 'Tutar'"),
				Object.Currency);
					
		Items.FAAmountARAP.Title = NonCurrentAssetsClientServer.AddCurrencyToLine(
			NStr("vi = 'Số tiền hạch toán';
				|ru = 'Сумма взаиморасчетов';
				|en = 'AR/AP amount'; fa = 'مبلغ دریافتنی/پرداختنی';
				|it = 'Importo dei pagamenti reciproci';
				|pl = 'Wartość rozliczeń wzajemnych';
				|tr = 'Borç-alacak muhasebesi tutarı'"), 
			Object.ARAPCurrency);
	
	EndIf;
	
	VendorInvoiceLeasedAssetsLocalization.ConfigureDependentFormElements(ThisObject, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisForm, ChangedBankingDetails);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails)
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;

	Object = Form.Object;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", True);
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", Form.FormServiceParameters.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("AssetHolder", Form.FormServiceParameters.ContractDetails_.AssetHolder);
	LeasedAssetAccountingClientServerLocalization.AddAuxiliaryDetails_RepurchaseOfLeasedFA(Form, AuxiliaryAttributes);
	
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_RedemptionOfLeasedFA(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "FA,ServicePaymentSchedule,ServiceAccrualSchedule,InterestAccrualSchedule");
	EndIf;

	If StructureOfChangedProps.Property("VATTaxation")
		Or UpdateAll Then
		
		PurchaseIsSubjectToVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(Form.Object.VATTaxation);
		
		If Not PurchaseIsSubjectToVAT Then
			Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
			Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
		Else
			Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
			Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
		EndIf;
	
	EndIf;
	
	LeasedAssetAccountingClientServerLocalization.ConfigureDependentFormElements_RedemptionOfLeasedFA(
		Form, StructureOfChangedProps);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	Return StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or VendorInvoiceLeasedAssetsClientLocalization.RequiresServerCallToConfigureFormElements(Object, StructureOfChangedProps);

EndFunction

#Region PageGeneral

&AtServer
Procedure DateOfChangeOnServer()
	
	UpdatePurchaseForActivity();
	
	ConfigureDependentFormElementsOnServer("Date");
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	Contract = Catalogs.LeaseContract.DefaultContract(
					Object.Organization, 
					Object.Partner, 
					Object.Counterparty, 
					Object.Contract, 
					Enums.TypesOfLeaseContracts.Leasing);
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		AgreementWhenModifiedOnServer();
	Else
		UpdateVATTaxation_();
		WhenChangingVATTaxationServer();
	EndIf;
	
	CustomizeInvoicePresentation();
	
	UpdatePurchaseForActivity();
	
	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	CounterpartyWhenChangesAreMadeOnServer();
	
EndProcedure

&AtServer
Procedure CounterpartyWhenChangesAreMadeOnServer()
	
	Contract = Catalogs.LeaseContract.DefaultContract(
					Object.Organization, 
					Object.Partner, 
					Object.Counterparty, 
					Object.Contract, 
					Enums.TypesOfLeaseContracts.Leasing);
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		AgreementWhenModifiedOnServer();
	EndIf;
	
	CustomizeInvoicePresentation();
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	AddContractDetailsToServiceParametersOfForm();

	Object.ARAPCurrency = Common.ObjectAttributeValue(Object.Contract, "ARAPCurrency");
	
	CurrencyOfMutualSettlementsOfTheDocument = Object.ARAPCurrency;
	Object.Currency = Object.ARAPCurrency;
	
	If Object.FA.Count() = 0 
		And Object.DocumentAmount = 0 
		And ValueIsFilled(Object.Contract) Then
		
		Documents.VendorInvoiceLeasedAssets.FillInBasedOnLeaseAgreement(Object);
	Else
		FillInTheContract = True;
	EndIf;

	WhenChangingVATTaxationServer();
	
	UpdateVATTaxation_();
	UpdatePurchaseForActivity();
	
	CustomizeInvoicePresentation();
	
	ConfigureDependentFormElementsOnServer("Contract");
	
EndProcedure

#Region OSPage

&AtServer
Procedure FAIsPrimaryMeansWhenChangingOnServer()

	FillInHeaderForSelectedFA();
	If GetFunctionalOption("UseTraceableImportedGoodsAccounting") Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region FillType

&AtClient
Procedure FillInTheContractCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInByAgreementOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInByAgreementOnServer()
		
	Documents.VendorInvoiceLeasedAssets.FillInBasedOnLeaseAgreement(Object, True);
	
EndProcedure

&AtClient
Procedure FillInTheContract()

	If Not FillInTheContract Or Not ValueIsFilled(Object.Contract) Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Điền chứng từ theo hợp đồng?';
					|ru = 'Заполнить документ по договору?';
					|en = 'Fill in the document under the contract?'; fa = 'Fill in the document under the contract?';
					|it = 'Compilare il documento in base all''accordo?';
					|pl = 'Wypełnij dokument zgodnie z umową?';
					|tr = 'Bir sözleşme belgesi mi dolduruyorsunuz?'");
	CallbackDescription = New CallbackDescription("FillInTheContractCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
	FillInTheContract = False;
	
EndProcedure

&AtClient
Procedure FillInTheRentedOnesCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ClearMessages();
		FillWithRentedOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillWithRentedOnServer()
		
	If Object.GeneratedDocument Then
		If LeasedAssetAccountingClientServer.ThisIsChangeInTermsOfLease(Object.DocumentBasis) Then
			FillInRentedOnesBasedOnChangeInConditions();
			Return;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Object.Contract) Then
		Return;
	EndIf;
	
	Object.FA.Clear();
	
	QueryText =
	"SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS TermsOfAgreement_,
	|	TermsOfLeaseContracts.AmountOfLeaseAssetsByuout AS AmountOfLeaseAssetsByuout,
	|	TermsOfLeaseContracts.VATRate AS VATRate,
	|	TermsOfLeaseContracts.Contract.ThereIsPrepaymentOfBuyoutValue AS ThereIsAdvancePayment
	|INTO TTPreviousConditions
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(
	|			&Date,
	|			Recorder <> &Ref
	|				AND Contract = &Contract) AS TermsOfLeaseContracts
	|
	|INDEX BY
	|	TermsOfAgreement_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset,
	|	LeasedAsset.Cost AS Cost
	|INTO TTLeasedFA
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(&Date, Recorder <> &Ref) AS LeasedAsset
	|WHERE
	|	LeasedAsset.Contract = &Contract
	|	AND LeasedAsset.State = VALUE(Enum.FixedAssetsStates.InLease)
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FixedAssetsAccountingProcedure.FixedAsset AS FixedAsset,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup AS FinancialAccountingGroup
	|INTO TTAccountingFA
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
	|			&DocumentBorder,
	|			FixedAsset IN
	|				(SELECT
	|					LeasedAsset.FixedAsset
	|				FROM
	|					TTLeasedFA AS LeasedAsset)) AS FixedAssetsAccountingProcedure
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(PaymentSchedule.BuyoutValuePrepayment + PaymentSchedule.BuyoutValue) AS RedemptionAmount
	|FROM
	|	InformationRegister.LeaseServicesPaymentSchedule AS PaymentSchedule
	|WHERE
	|	PaymentSchedule.EffectiveContractTerms IN
	|			(SELECT
	|				PreviousConditions.TermsOfAgreement_ AS TermsOfAgreement_
	|			FROM
	|				TTPreviousConditions AS PreviousConditions)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset,
	|	LeasedAsset.Cost AS Cost,
	|	0 AS AmountARAP,
	|	PreviousConditions.VATRate AS VATRate,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup AS FinancialAccountingGroup
	|FROM
	|	TTLeasedFA AS LeasedAsset
	|		INNER JOIN TTPreviousConditions AS PreviousConditions
	|		ON (TRUE)
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON LeasedAsset.FixedAsset = FixedAssetsAccountingProcedure.FixedAsset
	|
	|ORDER BY
	|	LeasedAsset.FixedAsset.Description,
	|	LeasedAsset.FixedAsset.AssetID";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Contract", Object.Contract);
	
	DateToFillIn = ?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate());
	
	Query.SetParameter("Date", DateToFillIn);
	Query.SetParameter("DocumentBorder", New Boundary(DateToFillIn,BoundaryType.Excluding));
	
	Results = Query.ExecuteBatch();
	
	FAResult = Results[Results.UBound()];
	If FAResult.IsEmpty() Then
		MessageText = NStr("vi = 'Theo hợp đồng không có tài sản cố định đã tiếp nhận vào kế toán.
							  |Có thể là tài sản cố định đã được mua lại hoặc đã chấm dứt hợp đồng thuê hoặc tài sản cố định chưa được tiếp nhận vào kế toán.';
							  |ru = 'По договору нет принятых к учету основных средств.
							  |Возможно, основные средства уже выкуплены или оформлено прекращение договора аренды, или основные средства не принимались к учету.';
							  |en = 'There are no recognized fixed assets under the contract.
							  |The fixed assets may have already been redeemed, or the rental termination may have been registered, or the fixed assets have not been recognized.'; fa = 'There are no recognized fixed assets under the contract.
							  |The fixed assets may have already been redeemed, or the rental termination may have been registered, or the fixed assets have not been recognized.';
							  |it = 'In base all''accordo non vi sono immobilizzazioni registrate in contabilità.
							  |Probabilmente le immobilizzazioni sono state già rimborsate o è stato terminato il contratto di affitto, oppure le immobilizzazioni non sono state registrate in contabilità.';
							  |pl = 'Zgodnie z umową nie ma przyjętych do ewidencji środków trwałych.
							  |Możliwe, że środki trwałe są już wykupione lub jest utworzone zawieszenie umowy dzierżawy, lub środki trwałe nie były przyjęte do ewidencji.';
							  |tr = 'Sözleşme kapsamında muhasebeleştirilen herhangi bir sabit kıymet bulunmamaktadır. 
							  | Sabit kıymetler geri alınmış veya kiralama sözleşmesi feshedilmiş olabilir ya da sabit kıymetler muhasebeleştirilmemiş olabilir.'");
		Common.MessageToUser(MessageText);
		Return;
	EndIf;
	
	FATable = FAResult.Unload();
	
	Selection = Results[Results.UBound() - 1].Select();
	Selection.Next();
	
	Coefficients = FATable.UnloadColumn("Cost");
	AllocationResult = Common.DistributeAmountInProportionToCoefficients(Selection.RedemptionAmount, Coefficients);
	If AllocationResult <> Undefined Then
		For IndexOf = 0 To AllocationResult.Count() - 1 Do
			FATable[IndexOf].AmountARAP = AllocationResult[IndexOf];
		EndDo;
	EndIf;
	
	Object.FA.Load(FATable);
	
	// Fill in the amount line by line in the currency of the document.
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	RowsToProcess = New Array();
	
	For Each CurrentRow In Object.FA Do	
	
		If Object.Currency <> Object.ARAPCurrency Then
			ConversionFactor_ = Object.CourseNumerator / Object.CourseDenominator;
		Else
			ConversionFactor_ = 1;
		EndIf;
		
		// In the Currency of the document.	
		CurrentRow.Sum = CurrentRow.AmountARAP * ConversionFactor_;
		
		CurrentRow.AmountVATARAP = VATAccountingERPClientServer.CalculateVATAmount(CurrentRow.AmountARAP,
																		CurrentRow.VATRate,
																		StructureOfRecalculationOfAmount.PriceIncludesVAT,
																		StructureOfRecalculationOfAmount.VATTaxation);
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.FA);
	
EndProcedure

&AtServer
Procedure FillInRentedOnesBasedOnChangeInConditions()
	
	DocumentBasis = Object.DocumentBasis;
	If Not ValueIsFilled(DocumentBasis) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	LeaseTermAdjustmentFA.FixedAsset AS FixedAsset,
	|	LeaseTermAdjustmentFA.BuyoutValue AS Sum,
	|	LeaseTermAdjustmentFA.BuyoutValue AS AmountARAP,
	|	LeaseTermAdjustmentFA.Ref.VATRate AS VATRate
	|FROM
	|	Document.LeaseTermAdjustment.FA AS LeaseTermAdjustmentFA
	|WHERE
	|	LeaseTermAdjustmentFA.Ref = &Basis
	|	AND LeaseTermAdjustmentFA.ActionWithRentalObject 
	|		= VALUE(Enum.ActionsWithRentalObjects.EarlyRedemption)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Basis", DocumentBasis);
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Object.FA.Clear();
	
	Selection = Result.Select();
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisObject);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	AddedRows = New Array();
	While Selection.Next() Do
		
		RowData = Object.FA.Add();
		FillPropertyValues(RowData, Selection);
		
		If Object.Currency <> Object.ARAPCurrency Then
			ConversionFactor_ = Object.CourseNumerator / Object.CourseDenominator;
		Else
			ConversionFactor_ = 1;
		EndIf;
		
		RowData.Sum = RowData.AmountARAP * ConversionFactor_;
		
		AddedRows.Add(RowData);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActions,
		Object.FA,
		CachedValues);
	
EndProcedure

#EndRegion

#Region AccountingMechanisms

&AtServer
Procedure AccountingMechanismsWhenCreatedOnServer()
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoiceLeasedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtServer
Procedure AccountingMechanismsWhenReadingOnServer()

	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoiceLeasedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtServer
Procedure AccountingMechanismsWhenReadingDataOnServer()
	
	UpdateVATTaxation_(False);
	UpdatePurchaseForActivity(False);
	CustomizeInvoicePresentation();
	
EndProcedure

&AtServer
Procedure AccountingMechanismsEstablishConditionalAppearance()
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(
		ThisObject,
		"FAVATRate",
		"FAVATAmount",
		"FAAmountIncludingVAT");
	
EndProcedure

&AtServer
Procedure UpdatePurchaseForActivity(Fill = True)
	
	FillParameters = Documents.VendorInvoiceLeasedAssets.ParametersForFillingInVATActivityType(Object);
	
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
Procedure UpdateVATTaxation_(Fill = True)

	FillParameters = Documents.VendorInvoiceLeasedAssets.ParametersForFillingInVATTaxationPurchases(Object);

	If Fill Then
		VATAccountingERP.FillInVATTaxationPurchases(
			Object.VATTaxation, 
			FillParameters, 
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInListOfVATTaxChoices(
		Items.VATTaxation, 
		Object.VATTaxation, 
		FillParameters, 
		VATAccountingCachedParameterValues);
			
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
Procedure CustomizeInvoicePresentation()
			
	RegistrationParameters = ParametersForRegisteringInvoicesReceived(Object);
	InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
	
	InvoiceTextReceived = InvoicesReceivedOnBasisOf.Presentation;	
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties


&AtClient
Procedure CheckCounterparties(Command)
	
	
	Return; // WE have an empty handler
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	InitializingFormWhenCreatingItOnServer();

	ConfigureDependentFormElementsOnServer();
	
	AccountingMechanismsWhenReadingDataOnServer();

	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject, "FAAmountIncludingVAT");
	
	AccountingMechanismsEstablishConditionalAppearance();
	
	#Region OS_AmountOfSettlements_Visibility
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAAmountARAP.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.ARAPCurrency");
	
	Item.Appearance.SetParameterValue("Visible", False);
	#EndRegion
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedFA()

	ChangedBankingDetails = "FixedAsset";
	NonCurrentAssetsInternal.FillInHeaderForLeasedFA(
		"Organization,Partner,Counterparty,Contract", 
		Object.FA, 
		Object, 
		ChangedBankingDetails);
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
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
	
	ConfigureDependentFormElementsOnServer("Currency");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ChangedBankingDetails, True);
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	ArrayOfAmounts = New Array;
	For Each CurRow In Object.FA Do
		ArrayOfAmounts.Add(CurRow.AmountIncludingVAT);
	EndDo;
	
	ArrayOfAmounts = Common.DistributeAmountInProportionToCoefficients(DocumentAmount, ArrayOfAmounts);
	
	If ArrayOfAmounts <> Undefined Then
		
		For N1 = 0 To Object.FA.Count()-1 Do
			
			CurRow = Object.FA[N1];
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
Procedure WhenChangingVATTaxationServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.FA, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.FA,
		Undefined);
	
	CustomizeInvoicePresentation();
	
	ConfigureDependentFormElementsOnServer("VATTaxation");
	
EndProcedure

&AtServer
Procedure PriceIncludesVATWhenChangedOnServer()
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.FA, StructureOfActions, CachedValues);
	
EndProcedure

&AtClientAtServerNoContext
Function FieldsForRecalculatingAmountOfNDSInTSLine(Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Form.Object);
	
	Return StructureOfRecalculationOfAmount;
	
EndFunction

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("ContractDetails_", Undefined);

	ParameterValue = NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date);
	NewServiceParametersOfForm.Insert("VNAManagementIsUsed_2_4", ParameterValue);

	ParameterValue = LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date);
	NewServiceParametersOfForm.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", ParameterValue);

	ParameterValue = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", ParameterValue);
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	NewServiceParametersOfForm.Insert("CurrencyOfManPresentation", String(CurrencyOfMan));
	NewServiceParametersOfForm.Insert("ComplCurrencyPresentation", String(ComplCurrency));
	NewServiceParametersOfForm.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

	AddContractDetailsToServiceParametersOfForm();

EndProcedure

&AtServer
Procedure AddContractDetailsToServiceParametersOfForm()
	
	AttributesList = "AssetHolder,ThereIsPrepaymentOfBuyoutValue";
	If ValueIsFilled(Object.Contract) Then
		ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, AttributesList);
	Else
		ContractDetails_ = New Structure(AttributesList);
		ContractDetails_.ThereIsPrepaymentOfBuyoutValue = False;
	EndIf;
			
	NonCurrentAssetsInternal.SetStructureProperty(
		"ContractDetails_",
		ContractDetails_,
		FormServiceParameters);
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClient
Procedure PrepaymentsSettlementCompletion(ClosingResult, AdditionalParameters) Export
	
	If TypeOf(ClosingResult) = Type("Structure") Then
		OffsettingAdvancesCompletionOnServer(ClosingResult);
	EndIf;
	
EndProcedure

&AtServer
Procedure OffsettingAdvancesCompletionOnServer(ClosingResult)

	Object.PrepaymentsSettlement.Clear();
	
	OffsetOfAdvancesInitial = GetFromTempStorage(AddressOffsetOfAdvances);
	CommonClientServer.SupplementTable(OffsetOfAdvancesInitial, Object.PrepaymentsSettlement);
	
EndProcedure

&AtServer
Procedure PlaceOffsettingOfAdvancesInTemporaryStorage()
	
	PutToTempStorage(Object.PrepaymentsSettlement.Unload(), AddressOffsetOfAdvances);
	
EndProcedure

&AtServer
Function AvailableFixedAssets()
	
	AvailableFixedAssets = Object.FA.Unload(,"FixedAsset").UnloadColumn("FixedAsset");  
	NodesList = NonCurrentAssets.GetFANodes(AvailableFixedAssets, Object.Date);
	
	While NodesList.Next() Do
		AvailableFixedAssets.Add(NodesList.FixedAsset);
	EndDo;
	
	Return AvailableFixedAssets;
	
EndFunction


&AtClient
Function DataOnTraceableGoodsIsCorrect()
	
	DataCorrect = True;
	FixedAssets = AvailableFixedAssets();
	For Each Page1 In Object.TraceableGoods Do
		If FixedAssets.Find(Page1.FixedAsset) = Undefined Then
			MessageString = NStr("vi = 'Dữ liệu phần bảng hàng hóa được truy xuất nguồn gốc không tương ứng với dữ liệu về tài sản cố định. 
			|Giá trị %1 không có trong phần bảng ""Tài sản cố định"".';
			|ru = 'Данные табличной части прослеживаемых товаров не соответствуют данным об основных средствах. 
			|Значение %1 отсутствует в табличной части ""Основные средства"".';
			|en = 'Data of the traceable goods table does not correspond to the data of fixed assets. 
			|The %1 value is missing in the ""Fixed assets"" table.'; fa = 'Data of the traceable goods table does not correspond to the data of fixed assets. 
			|The %1 value is missing in the ""Fixed assets"" table.';
			|it = 'I dati della parte tabellare degli articoli tracciabili non corrispondono ai dati sulle immobilizzazioni. 
			|Il valore %1 manca nella parte tabellare ""Immobilizzazioni"".';
			|pl = 'Dane sekcji tabelarycznej towarów identyfikowalnych nie są zgodne z danymi o środkach trwałych. 
			|Brak wartości %1 w sekcji tabelarycznej ""Środki trwałe"".';
			|tr = 'İzlenebilir mallar tablosundaki veriler sabit kıymetlerdeki verilerle uyuşmuyor. 
			|""Sabit kıymetler"" tablo bölümünde %1 değeri eksik.'"); 
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Page1.FixedAsset);
			CommonClient.MessageToUser(MessageString,Object.Ref);
			DataCorrect = False;	
		EndIf;	
	EndDo;

	Return DataCorrect;
EndFunction

&AtClient
Procedure GenerateStatement(Command)
	
	AvailableFixedAssets = AvailableFixedAssets();
	Filter = New Structure;
    Filter.Insert("Organization", Object.Organization);   
	Filter.Insert("FixedAsset", AvailableFixedAssets);
	ReportPeriod = New StandardPeriod();
	ReportPeriod.StartDate = BegOfDay(Object.Date);
	ReportPeriod.EndDate = EndOfDay(Object.Date);
 	Filter.Insert("Period", ReportPeriod);		
	FormParameters = New Structure("Filter, GenerateOnOpen, VariantKey", Filter, True, "Main");	
	AccountingForTraceableGoodsClientLocalization.GenerateStatement(FormParameters);
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.GroupPages.ChildItems.TraceableProductsPage Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
	EndIf;
	
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChangeCompletion(ClosingResult, AdditionalParameters) Export

	If ValueIsFilled(ClosingResult) Then
		Object.DocumentBasis = ClosingResult;
		Object.GeneratedDocument = True;
	Else
		Object.GeneratedDocument = False;
	EndIf;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		QueryText = NStr("vi = 'Điền chứng từ theo dữ liệu chứng từ cơ sở?';
						|ru = 'Заполнить документ по данным документа-основания?';
						|en = 'Fill in the document by base document data?'; fa = 'Fill in the document by base document data?';
						|it = 'Compilare il documento in base ai dati del documento principale?';
						|pl = 'Wypełnić dokument wg danych dokumentu-podstawy?';
						|tr = 'Belgeyi belge bazındaki verilere göre mi dolduruyorsunuz?'");
		CallbackDescription = New CallbackDescription("FillInAccordingToBaseEnd", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo); 
	EndIf; 
	
EndProcedure 

&AtClient
Procedure FillInAccordingToBaseEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInAccordingToBaseDataOnServer();
	EndIf;
			
EndProcedure

&AtServer
Procedure FillInAccordingToBaseDataOnServer()
	
	ErrorText = Documents.VendorInvoiceLeasedAssets.FillInOnBasisOfRentalTermsADJUSTMENTChanges(Object,
			Object.DocumentBasis);
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
	ConfigureDependentFormElementsOnServer("Organization, Contract");
	
EndProcedure

&AtServerNoContext
Function ListOfFoundationDocumentFA(Val DocumentBasis)
	
	If ValueIsFilled(DocumentBasis)
		And TypeOf(DocumentBasis) = Type("DocumentRef.LeaseTermAdjustment") Then
		
		Query = New Query;
		Query.Text = "SELECT
		|	LeaseTermAdjustmentFA.FixedAsset AS FixedAsset
		|FROM
		|	Document.LeaseTermAdjustment.FA AS LeaseTermAdjustmentFA
		|WHERE
		|	LeaseTermAdjustmentFA.Ref = &Ref
		|	AND LeaseTermAdjustmentFA.ActionWithRentalObject
		|		= VALUE(Enum.ActionsWithRentalObjects.EarlyRedemption)";
		Query.SetParameter("Ref", DocumentBasis);
		
		Return Query.Execute().Unload().UnloadColumn("FixedAsset");
		
	Else
		Return New Array;
	EndIf;
		
EndFunction

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
