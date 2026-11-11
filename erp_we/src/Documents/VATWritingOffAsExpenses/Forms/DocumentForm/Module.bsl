#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	SetConditionalAppearance();
	
	TypeDescriptionTaxInvoice = Metadata.DefinedTypes.TaxInvoice.Type;
	TypeDetailsBaseDocumentTaxInvoiceAdvancePaid = Metadata.DefinedTypes.BaseDocumentIssuedTaxInvoicePrepayment.Type;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.VATWritingOffAsExpenses.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	AccountSettings_ = Documents.VATWritingOffAsExpenses.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, AccountSettings_);
	Items.Assets_VATActivityType.ChoiceList.LoadValues(
		VATAccountingERP.TypesOfActivitiesVATIsAcceptedForReimbursement());

	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	VATAccountingERPInternal.ConfigureJointSelectionOfContractorsOrganizations(Items.Vendor);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	If Object.Patch Then
		Items.Assets_FillInAssets.Visible = False;
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);

	ItemsAndDimensionsSelectionParameters = Documents.VATWritingOffAsExpenses.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	AccountingAccountSettings_ = Documents.VATWritingOffAsExpenses.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, AccountingAccountSettings_);
	OnReadCreateAtServer();

	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	Notify("Write_VATWritingOffAsExpenses", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	DocumentCorrectionClient.AfterWrite(Object);

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

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TaxInvoiceOnChange(Item)
	
	If ValueIsFilled(Object.TaxInvoice) Then
		ShowQuestionClearingValues();
	EndIf;
	
EndProcedure

&AtClient
Procedure TaxInvoiceStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Object.TaxInvoice = Undefined Then
	
		StandardProcessing = False;
		
		FormParameters = New Structure;
		FormParameters.Insert("AvailableTypes", TypeDescriptionTaxInvoice);
		
		CallbackDescription = New CallbackDescription("ProcessingSelectingInvoiceType", ThisObject);
		OpenForm("CommonForm.SelectType", FormParameters, ThisObject, , , , CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentPaymentsStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Object.DocumentPayments = Undefined Then
	
		StandardProcessing = False;
		
		FormParameters = New Structure;
		FormParameters.Insert("AvailableTypes", TypeDetailsBaseDocumentTaxInvoiceAdvancePaid);
		
		CallbackDescription = New CallbackDescription("ProcessingSelectingPaymentDocumentType", ThisObject);
		OpenForm("CommonForm.SelectType", FormParameters, ThisObject, , , , CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TaxInvoiceClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Object.TaxInvoice = Undefined;
	
EndProcedure

&AtClient
Procedure DocumentPaymentsOnChange(Item)
	If ValueIsFilled(Object.DocumentPayments) Then
		ShowQuestionClearingAdvancesReceived();
	EndIf;
EndProcedure

&AtClient
Procedure DocumentPaymentsClearing(Item, StandardProcessing)
	StandardProcessing = False;
	Object.DocumentPayments = Undefined;
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
		DocumentCorrectionClient.StringFixHandlingNavigationLinks(
			ThisObject, FormattedStringURL, StandardProcessing);
			
EndProcedure

&AtClient
Procedure PresentationOfRecordingInComplAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return; // Empty handler for UT
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAssets_

&AtClient
Procedure Assets_OnChange(Item)
	
	Object.VATAmount = Object.Assets_.Total("VAT");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInAssets(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection            = Object.Assets_;
	CheckParameters.TitleOfTablePart   = NStr("vi = 'Công cụ, dụng cụ';
												|ru = 'Ценности';
												|en = 'Assets'; fa = 'دارایی‌ها';
												|it = 'Valori';
												|pl = 'Assets';
												|tr = 'Değerler'");
	CheckParameters.CheckForPromiscuity = False;
	CheckParameters.CheckedAttributes.Insert("Organization",  NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Counterparty",   NStr("vi = 'Đối tác';
																	|ru = 'Контрагент';
																	|en = 'Counterparty'; fa = 'طرف حساب';
																	|it = 'Contraente';
																	|pl = 'Kontrahent';
																	|tr = 'Cari hesap'"));
	CheckParameters.CheckedAttributes.Insert("TaxInvoice",  NStr("vi = 'Chứng từ-cơ sở';
																|ru = 'Документ-основание';
																|en = 'Base document'; fa = 'سند مبنا';
																|it = 'Documento-causale';
																|pl = 'Base document';
																|tr = 'Temel belge'"));
	Notification = New CallbackDescription("FillInValuesByClickingAfterVerification", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInAdvancesReceived(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection            = Object.PrepaymentsFromCustomer;
	CheckParameters.TitleOfTablePart   = NStr("vi = 'Nhận ứng trước';
												|ru = 'Авансы полученные';
												|en = 'Prepayments from customer'; fa = 'پیش‌دریافت‌ها از مشتری';
												|it = 'Pagamenti anticipati ricevuti';
												|pl = 'Otrzymane zaliczki';
												|tr = 'Alınan avanslar'");
	CheckParameters.CheckForPromiscuity = False;
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Counterparty",   NStr("vi = 'Đối tác';
																	|ru = 'Контрагент';
																	|en = 'Counterparty'; fa = 'طرف حساب';
																	|it = 'Contraente';
																	|pl = 'Kontrahent';
																	|tr = 'Cari hesap'"));
	CheckParameters.CheckedAttributes.Insert("DocumentPayments", NStr("vi = 'Chứng từ thanh toán';
																		|ru = 'Документ оплаты';
																		|en = 'AR/AP transaction'; fa = 'تراکنش دریافتنی/پرداختنی';
																		|it = 'Documento di pagamento';
																		|pl = 'Dokument płatności';
																		|tr = 'Ödeme belgesi'"));
	Notification = New CallbackDescription("FillInAdvancesReceivedImmediatelyAfterVerification", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);
	
EndProcedure

#Region StandardCommands

#Region AttachableCommands

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

#EndRegion

// IntegrationWith1CDocumentManagementSubsystem
#Region IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

#EndRegion
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#EndRegion

#Region Private

&AtClient
Procedure FillInValuesByClickingAfterVerification(Result, AdditionalParameters) Export 
	
	FillInAssetsServer();
	
EndProcedure

&AtClient
Procedure FillInAdvancesReceivedImmediatelyAfterVerification(Result, AdditionalParameters) Export 
	
	FillInAdvancesReceivedServer();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	SetFormItemsVisibility();
	EstablishRelationshipsOfInvoiceSelectionParameters();
	
EndProcedure

&AtServer
Procedure SetFormItemsVisibility()
	
	Items.ValueGroup_2.Visible = (Object.BusinessOperation = Enums.BusinessTransactions.VATOnAcquiredAssetsWriteOff);
	Items.GroupAdvancesReceived.Visible = (Object.BusinessOperation = Enums.BusinessTransactions.WriteOffVATFromPrepaymentFromCustomer);
	
	Items.TaxInvoice.Visible = (Object.BusinessOperation = Enums.BusinessTransactions.VATOnAcquiredAssetsWriteOff);
	Items.DocumentPayments.Visible = (Object.BusinessOperation = Enums.BusinessTransactions.WriteOffVATFromPrepaymentFromCustomer);
	
EndProcedure

&AtServer
Procedure FillInAssetsServer() 
	
	Documents.VATWritingOffAsExpenses.FillInValueTable(Object);
	
EndProcedure

&AtClient
Procedure ShowQuestionClearingValues()
	
	If Object.Assets_.Count() > 0 Then
		ShowQueryBox(New CallbackDescription("CleaningAndCompletion", ThisObject),
				NStr("vi = 'Danh sách ""Nguyên vật liệu"" sẽ bị xóa. Tiếp tục?';
					|ru = 'Список ""Ценности"" будет очищен. Продолжить?';
					|en = 'The Assets list will be cleared. Continue?'; fa = 'The Assets list will be cleared. Continue?';
					|it = 'Elenco ""Valori"" sarà cancellato. Continuare?';
					|pl = 'Lista ""Wartości"" zostanie wyczyszczona. Kontynuować?';
					|tr = '""Değerler"" listesi temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	Else
		FillInAssetsServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure CleaningAndCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Object.Assets_.Clear();
	FillInAssetsServer();
	
EndProcedure

&AtClient
Procedure ProcessingSelectingInvoiceType(Result, AdditionalParameters) Export
	
	FormParameters = ParametersForOpeningDocumentSelectionForm(Result);
	
	If FormParameters = Undefined Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("ProcessingInvoiceSelection", ThisObject);
	OpenForm(FormParameters.ChoiceFormName, FormParameters.OpeningParameters, ThisObject, , , , CallbackDescription); 
	
EndProcedure

&AtClient
Procedure ProcessingSelectingPaymentDocumentType(Result, AdditionalParameters) Export
	
	FormParameters = ParametersForOpeningDocumentSelectionForm(Result);
	
	If FormParameters = Undefined Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("ProcessingPaymentDocumentSelection", ThisObject);
	OpenForm(FormParameters.ChoiceFormName, FormParameters.OpeningParameters, ThisObject, , , , CallbackDescription); 
	
EndProcedure

&AtClient
Procedure ProcessingInvoiceSelection(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then 
		Object.TaxInvoice = Result;
		EstablishRelationshipsOfInvoiceSelectionParameters();
		ShowQuestionClearingValues();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingPaymentDocumentSelection(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then 
		Object.DocumentPayments = Result;
		ShowQuestionClearingAdvancesReceived();
	EndIf;
	
EndProcedure

&AtServer
Function ParametersForOpeningDocumentSelectionForm(ValueType)
	
	If ValueType = Undefined Then
		Return Undefined;
	EndIf;
	
	ChoiceFormName = Metadata.FindByType(ValueType).FullName() + ".ChoiceForm";
	
	Result = New Structure;
	Result.Insert("ChoiceFormName", ChoiceFormName);
	
	Filter = New Structure;
	For Each Parameter In LinksSelectionParameters(ValueType) Do
		If Parameter.Key = "Partner" Then
			If TypeOf(Object.Counterparty) = Type("CatalogRef.Counterparties") Then
				FilterPartner = Common.ObjectAttributeValue(Object.Counterparty, "Partner");
				Filter.Insert(Parameter.Key, FilterPartner);
			EndIf;
		Else
			Filter.Insert(Parameter.Key, Object[Parameter.Value]);
		EndIf;	
	EndDo;
	
	Result.Insert("OpeningParameters", New Structure("Filter", Filter));
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function LinksSelectionParameters(ValueType)
	
	LinksSelectionParameters = New Structure;
	If ValueType = Type("DocumentRef.CustomerInvoiceIntercompany") Then
		LinksSelectionParameters.Insert("Organization", "Counterparty");
		LinksSelectionParameters.Insert("CompanyRecipient", "Organization");
	ElsIf ValueType = Type("DocumentRef.IntercompanyGoodsReturn") Then
		LinksSelectionParameters.Insert("CompanyRecipient", "Organization");
		LinksSelectionParameters.Insert("Organization", "Counterparty");
	Else
		If GetFunctionalOption("UsePartnersAndCounterparties") Then
			LinksSelectionParameters.Insert("Organization", "Organization");
			If ValueType <> Type("DocumentRef.OBEntry") Then
				LinksSelectionParameters.Insert("Counterparty", "Counterparty");
			EndIf;
		Else
			LinksSelectionParameters.Insert("Organization", "Organization");
			If ValueType <> Type("DocumentRef.OBEntry") Then
				LinksSelectionParameters.Insert("Partner", "Partner");
			EndIf;
		EndIf;
	EndIf;
		
	Return LinksSelectionParameters;
	
EndFunction

&AtServer
Procedure EstablishRelationshipsOfInvoiceSelectionParameters()
	
	FilterParameters = LinksSelectionParameters(TypeOf(Object.TaxInvoice));
	
	ArrayOfSelections = New Array;
	For Each Filter In FilterParameters Do
		If Filter.Key = "Partner" Then
			If ValueIsFilled(Object.Counterparty)
				And TypeOf(Object.Counterparty) = Type("CatalogRef.Counterparties") Then
					Partner = Common.ObjectAttributeValue(Object.Counterparty, "Partner");
					ArrayOfSelections.Add(New ChoiceParameterLink("Filter." + Filter.Key, "Partner"));
			EndIf;
		Else
			ArrayOfSelections.Add(New ChoiceParameterLink("Filter." + Filter.Key, "Object." + Filter.Value));
		EndIf;
	EndDo;
	
	InvoiceSelectionParameters_ = New FixedArray(ArrayOfSelections);
	Items.TaxInvoice.ChoiceParameterLinks = InvoiceSelectionParameters_;
	
EndProcedure

&AtServer
Procedure FillInAdvancesReceivedServer() 
	
	Documents.VATWritingOffAsExpenses.FillInTableAdvancesReceived(Object);
	
EndProcedure

&AtClient
Procedure ShowQuestionClearingAdvancesReceived()
	
	If Object.Assets_.Count() > 0 Then
		ShowQueryBox(New CallbackDescription("ClearingAdvancesReceivedCompletion", ThisObject),
				NStr("vi = 'Danh sách ""Ứng trước đã nhận"" sẽ bị xóa. Tiếp tục?';
					|ru = 'Список ""Авансы полученные"" будет очищен. Продолжить?';
					|en = 'The ""Prepayments from customer"" list will be cleared. Continue?'; fa = 'The ""Prepayments from customer"" list will be cleared. Continue?';
					|it = 'Elenco ""Anticipi ricevuti"" sarà cancellato. Continuare?';
					|pl = 'Lista ""Zaliczki otrzymane"" zostanie wyczyszczona. Kontynuować?';
					|tr = '""Alınan avanslar"" listesi temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	Else
		FillInAssetsServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearingAdvancesReceivedCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Object.PrepaymentsFromCustomer.Clear();
	FillInAdvancesReceivedServer();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.VATOnAcquiredAssetsWriteOff Then
		Object.TaxInvoice = Undefined;
		If Object.Assets_.Count() > 0 Then
			Object.Assets_.Clear();
		EndIf;
	EndIf;
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.WriteOffVATFromPrepaymentFromCustomer Then
		Object.DocumentPayments = Undefined;
		If Object.PrepaymentsFromCustomer.Count() > 0 Then
			Object.PrepaymentsFromCustomer.Clear();
		EndIf;
	EndIf;
	
	SetFormItemsVisibility();
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
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
