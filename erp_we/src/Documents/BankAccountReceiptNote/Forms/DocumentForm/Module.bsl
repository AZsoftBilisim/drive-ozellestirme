#Region Variables

//used by the mechanism for processing changes in PM details
&AtClient
Var CachedValues; 

&AtClient
Var ParametersForRecording Export;


#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountReceiptNote.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	//Setting up accounting accounts
	SetupParameters =
		Documents.BankAccountReceiptNote.AccountingAccountSettings_(
		Object.BusinessOperation, Object.TaxType);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		
		If Parameters.Property("Basis") Then
			Basis = Parameters.Basis;
		EndIf;
		CashServer.CheckFillOutContract(Object);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);	
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);
	
	Items.DecryptionWithoutSplittingRepaymentDate.ReadOnly = Not AccessRight(
		"Edit",
		Metadata.Documents.BankAccountReceiptNote.TabularSections.ARAPDetails.Attributes.MaturityDate);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	If Not ValueIsFilled(Object.Ref) Then
		FinancesClient.CheckDocumentCompletionBasedOn(Object, Basis);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	If Not CurrentObject.ProcessedByBank Then
		CurrentObject.AdditionalProperties.Insert("CheckingDateWhenChangesWereBanned", False);
	EndIf;
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountReceiptNote.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	//Setting up accounting accounts
	SetupParameters =
		Documents.BankAccountReceiptNote.AccountingAccountSettings_(Object.BusinessOperation, Object.TaxType);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenReadingOnServer(ThisObject);
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		CallbackDescription = New CallbackDescription(
			"BeforeRecordingOfferToRecalculateAmountOfDocument", ThisObject, AdditionalParameters);
		
		FinancesClient.RecalculateAmountOfDocumentBasedOnPaymentDecryption(ThisForm, CallbackDescription);
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToRecalculateAmountOfDocument(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult Then
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_BankAccountReceiptNote", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromOtherCompany")
		And ValueIsFilled(InvertedPaymentReference)
		And Not CorrespondsToInvertedPayment Then
			ShowQueryBox(New CallbackDescription("AlignMirrorPaymentCompletion", ThisObject, False),
				StrTemplate(NStr("vi = 'Kết chuyển khớp %1?';
								|ru = 'Привести в соответствие %1?';
								|en = 'Adjust to %1?'; fa = 'Adjust to %1?';
								|it = 'Rendere conforme %1?';
								|pl = 'Uzgodnić %1?';
								|tr = '%1 ile uygun hale getirsin mi?'"), InvertedPaymentReference), QuestionDialogMode.YesNo);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	//Setting up accounting accounts
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	CompleteVATTaxation(False);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
	
	FillInParametersOfCalculationObjectInDecryption();
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	If ValueIsFilled(InvertedPaymentReference) 
		And Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
		
		CorrespondsToInvertedPayment = Documents.BankAccountReceiptNote.CorrespondsToInvertedPayment(
			Object.Ref,InvertedPaymentReference);
			
		If Not CorrespondsToInvertedPayment Then
			UpdateMirrorPaymentLabel();
		EndIf;
	EndIf;
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "GiftCertificateIsRead"
		And Parameter.OwnerForm = UUID Then
		
		ProcessGiftCertificate(Parameter.GiftCertificate);
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	PerformVerificationOfFillingOutContractOfCommission = (Object.RecordCommission And Object.FeeAmount <> 0
		And Object.KeepRecordsOfCommissionInARAPAccounting);
		
	ExcludeVerificationOfFillingInARAPObjectOfFee = False;
	If Not PerformVerificationOfFillingOutContractOfCommission Then
		NotCheckedAttributeArray.Add("CommissionAgreement");
		ExcludeVerificationOfFillingInARAPObjectOfFee = True;
	EndIf;
	
	If Not ValueIsFilled(CommissionAgreement) Then
		ExcludeVerificationOfFillingInARAPObjectOfFee = True; 
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not DecryptionSwitch Then
		DocumentObject = FormAttributeToValue("Object");
		DocumentObject.AdditionalProperties.Insert("ExplanationWithoutSplit", True);
		
		If ExcludeVerificationOfFillingInARAPObjectOfFee Then
			DocumentObject.AdditionalProperties.Insert("ExcludeVerificationOfFillingInARAPObjectOfFee", True);
		EndIf;
		
		If Not DocumentObject.CheckFilling() Then
			Cancel = True;
		EndIf;
		
		ObjectAttributesToBeChecked = CheckedAttributes.Find("Object");
		If ObjectAttributesToBeChecked <> Undefined Then
			CheckedAttributes.Delete(ObjectAttributesToBeChecked);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.ProcessedByBank Then
		CurrentDate = Object.Date;
		Object.BankPostingDate = Object.Date;
	EndIf;
	
	DateOnChangeServer();
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()

	CompleteVATTaxation();
	SetRestrictionOnTypeOfPaymentDecryptionContract();

EndProcedure

&AtClient
Procedure ProcessedByBankOnChange(Item)
	
	If Not Object.ProcessedByBank Then
		Object.BankPostingDate = Undefined;
	Else
		If Not ValueIsFilled(Object.BankPostingDate) Then
			Object.BankPostingDate = Object.Date;
		EndIf;
	EndIf;
	
	ProcessedByBankOnChangeServer();
	
EndProcedure

&AtServer
Procedure ProcessedByBankOnChangeServer()
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	FillInCourseCourseDenominatorOfSettlements();
	CalculateAmountOfSettlements_();
	FillMultiplicityCourseWithText();
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure BankPostingDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateWhenChangeWasMadeByBankOnServer();
	
EndProcedure

&AtServer
Procedure DateWhenChangeWasMadeByBankOnServer()
	
	FillInCourseCourseDenominatorOfSettlements();
	CalculateAmountOfSettlements_();
	FillMultiplicityCourseWithText();
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
	UpdatePresentationOfMaturityDate();
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	InitializePaymentDecryption();
	
	If ValueIsFilled(Object.DocumentBasis)
		And AvailableBaseOfOperations.FindByValue(Object.BusinessOperation) = Undefined Then
		
		Object.DocumentBasis = Undefined;
		AvailableBaseOfOperations.Clear();
		
	EndIf;
	
	CashServer.CheckFillOutContract(Object);
	
	For Each DecryptionString In Object.ARAPDetails Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, DecryptionString, "Object.ARAPDetails");
	EndDo;
	
	SetPossibleSenderAccountValues();
	
	If Not AccountCorrespondsToOwner() Then
		Object.CounterpartyBankAccount = Undefined;
	EndIf;
	
	CFItemByBT = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(
		Object.BusinessOperation);
	Object.CashFlowItem = CFItemByBT;
	For Each PaymentDecryptionString In Object.ARAPDetails Do
		PaymentDecryptionString.CashFlowItem = CFItemByBT;
	EndDo;
	
	ArrayOfAllProps = New Array; ArrayOfOperationDetails = New Array;
	Documents.BankAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		Object, ArrayOfAllProps, ArrayOfOperationDetails);
	If ArrayOfOperationDetails.Find("Counterparty") = Undefined Then
		Object.Counterparty = Undefined;
		Partner = Catalogs.Partners.EmptyRef();
		Object.Contract = Undefined;
		For Each CurDecryptionString In Object.ARAPDetails Do
			CurDecryptionString.Partner = Partner;
			CurDecryptionString.Contract = Object.Contract;
			CurDecryptionString.PaymentPurpose = Undefined;
			CurDecryptionString.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
		EndDo;
	EndIf;
	
	If ArrayOfOperationDetails.Find("CashAccountIssuer") <> Undefined
		And Not ValueIsFilled(Object.CashAccountIssuer) Then
		Object.CashAccountIssuer = Catalogs.CashAccounts.GetCheckoutByDefault(Object.Organization, Object.Currency);
	EndIf;
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment Then
		Object.RecordCommission = False;
	EndIf;
	
	//Setting up accounting accounts
	SetupParameters =
		Documents.BankAccountReceiptNote.AccountingAccountSettings_(
		Object.BusinessOperation, Object.TaxType);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountReceiptNote.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	GetDefaultContractServer();
	Object.LineOfBusiness = CashServer.LineOfBusiness(
		Object.BusinessOperation,
		Object.LineOfBusiness);
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
	CompleteVATTaxation();
	ProcessIPChange();
	UpdateMirrorPaymentLabel();
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	
	ReturnStructure = BankAccountOnChangeClient("CurrencyConversionAllowed");
	If ReturnStructure.NeedToSwitchToServer Then
		BankAccountOnChangeServer(ReturnStructure.BankAccountDetails, ReturnStructure.AmountsRecalculate);
	EndIf;
	
EndProcedure

&AtClient
Function BankAccountOnChangeClient(HandlerName)
	
	ReturnStructure = New Structure("NeedToSwitchToServer, BankAccountDetails, AmountsRecalculate");
	
	BankAccountDetails = GetBankAccountDetails(Object.BankAccount);
	
	If Not FinancesClient.CurrencyConversionRequired(Object, Object.Currency, BankAccountDetails.Currency) Then
		
		ReturnStructure.Insert("NeedToSwitchToServer", True);
		ReturnStructure.Insert("BankAccountDetails", BankAccountDetails);
		ReturnStructure.Insert("AmountsRecalculate", False);
	Else
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tính lại số tiền trong chứng từ theo tiền tệ %1?';
				|ru = 'Пересчитать суммы в документе в валюту %1?';
				|en = 'Convert amounts in the document in %1?'; fa = 'Convert amounts in the document in %1?';
				|it = 'Ricalcolare gli importi del documento in valuta %1?';
				|pl = 'Przeliczyć kwoty w dokumencie na walutę %1?';
				|tr = 'Belgedeki tutarlar %1 para birimine göre yeniden hesaplansın mı?'"),
			BankAccountDetails.Currency);
		
		QuestionDialogButtons = New ValueList;
		QuestionDialogButtons.Add(DialogReturnCode.Yes, NStr("vi = 'Tính lại';
															|ru = 'Пересчитать';
															|en = 'Recalculate'; fa = 'محاسبه مجدد';
															|it = 'Ricalcolare';
															|pl = 'Recalculate';
															|tr = 'Yeniden hesapla'"));
		QuestionDialogButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																|ru = 'Отменить';
																|en = 'Cancel'; fa = 'انصراف';
																|it = 'Annullare';
																|pl = 'Cancel';
																|tr = 'İptal et'"));
		
		CallbackDescription = New CallbackDescription(
			HandlerName, ThisObject, New Structure("AttributesStructure1", BankAccountDetails));
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogButtons);
		
		ReturnStructure.Insert("NeedToSwitchToServer", False);
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

&AtClient
Procedure CurrencyConversionAllowed(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		CurrentCurrency = Object.Currency;
		BankAccountOnChangeServer(AdditionalParameters.AttributesStructure1, True);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(CurrentCurrency, Object.Currency);
	Else
		
		Object.BankAccount = CurrentBankAccount;
	EndIf;
	
EndProcedure

&AtServer
Procedure BankAccountOnChangeServer(AttributesStructure1, AmountsRecalculate)
	
	OrganizationChanged_ = (Object.Organization <> AttributesStructure1.Organization);
	CurrencyChanged_1 = (Object.Currency <> AttributesStructure1.Currency);
	
	CurrentBankAccount   = Object.BankAccount;
	CurrentCurrency           = Object.Currency;
	Object.Currency           = AttributesStructure1.Currency;
	Object.Organization      = AttributesStructure1.Organization;
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	AttributesArray = New Array;
	If OrganizationChanged_ Then
		AttributesArray.Add("Organization");
	EndIf;
	If CurrencyChanged_1 Then
		AttributesArray.Add("Currency");
	EndIf;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	If ValueIsFilled(CurrentBankAccount) Then
		
		If ValueIsFilled(CurrentCurrency) And CurrencyChanged_1 Then
			
			Object.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
			Object.SenderBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			Object.CashAccountIssuer          = Catalogs.CashAccounts.EmptyRef();
			
			If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
				CurrencyOfConversionOnChangeServer();
			EndIf;
		EndIf;
		
		FillInInvoiceUnderAgreement = OrganizationChanged_ Or Not ValueIsFilled(Object.CounterpartyBankAccount);
		GetDefaultContractServer(FillInInvoiceUnderAgreement);
		CompleteVATTaxation();
		SetRestrictionOnTypeOfPaymentDecryptionContract();
		
		If OrganizationChanged_ Then
			BranchesOfOrganization.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Object.Organization));
			ThereAreBranches = BranchesOfOrganization.Count() > 0;
			
			If ValueIsFilled(CounterpartyContract) Then
				
				PaymentType_ = ?(Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
					Or Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany,
					Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting,
					Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
				
				ARAPObjectContract = ARAPObjectsServer.GetCalculationObjectFromLink(CounterpartyContract,,PaymentType_);
			EndIf;
			
			For Each TSRow In Object.ARAPDetails Do
				TSRow.Partner = Partner;
				If ValueIsFilled(CounterpartyContract) Then
					TSRow.PaymentPurpose = CounterpartyContract;
					TSRow.ARAPObject = ARAPObjectContract;
					TSRow.CashFlowItem = Object.CashFlowItem;
					TSRow.VATRate = VATRate;
				EndIf;
			EndDo;
			
			CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
			ProcessIPChange();
			StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
			BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
		EndIf;
	Else
		BranchesOfOrganization.Clear();
	EndIf;
	
	CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	
	If AmountsRecalculate Then
		CashServer.ConversionOfDocumentAmountsIntoCurrency(Object, CurrentCurrency, Object.Currency);
		
		VATConversionParameters = New Structure("PriceIncludesVAT", True);
		StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
		BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	EndIf;
	
	CashServer.UpdateSettlementCurrencyOfPaymentDecryption(
		"Document.BankAccountReceiptNote", Object, CurrencyOfComplianceAccounting, CurrencyChanged_1);
	
	CashServer.CheckFillOutContract(Object);
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	FillInContractFeeSVObjectOfSettlementARAPObject();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	If CurrencyChanged_1 Then
		CashServer.SetPaymentAmountHeader(Object.Currency, Items);
		Items.LabelCurrency.Title = String(Object.Currency);
		UpdateAmountUnallocated();
		GenerateHyperlinkCaptionPaymentObjectDetails();
	EndIf;
	
	SetPossibleSenderAccountValues();
	
	CashServer.SetParametersForDebitingFunds(Object, Items.WithdrawalDocument);
	
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure CounterpartyBankAccountOnChange(Item)
	
	CounterpartyBankAccountOnChangeServer();
	
EndProcedure

&AtServer
Procedure CounterpartyBankAccountOnChangeServer()
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure DocumentAmountOnChange(Item)
	
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.DocumentAmount, False);
	DocumentAmountOnChangeServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
	If ValueIsFilled(Object.Counterparty) Then
		
		Partner = CashServer.GetCounterpartyPartner(Object.Counterparty, Object.BusinessOperation);
		GetDefaultContractServer();
		
		If ValueIsFilled(CounterpartyContract) Then
			ARAPObjectContract = ARAPObjectsServer.GetCalculationObjectFromLink(CounterpartyContract)
		EndIf;
		
		For Each TSRow In Object.ARAPDetails Do
			TSRow.Partner = Partner;
			TSRow.ARAPCurrency = ARAPCurrency;
			If ValueIsFilled(CounterpartyContract) Then
				TSRow.PaymentPurpose = CounterpartyContract;
				TSRow.ARAPObject = ARAPObjectContract;
				TSRow.CashFlowItem = Object.CashFlowItem;
				TSRow.VATRate = VATRate;
				FillInCourseAndMultiplicityInDecryptionLine(TSRow);
				CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
					TSRow, Object.Currency, CurrencyOfComplianceAccounting);
				CashServer.FormCourseDenominatorByText(TSRow, Object.Currency, CurrencyOfComplianceAccounting);
				FillInCurrencyOfMutualSettlementsOfDocument();
			EndIf;
		EndDo;
		
		CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
		CashServer.CheckFillOutContract(Object);
		CashServer.SetDesignAccuracyOfCourse(ThisObject);
		ProcessIPChange();
		StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
		BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
		
		If Not ValueIsFilled(Object.CounterpartyBankAccount) Then
			Object.CounterpartyBankAccount =
				Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.Counterparty, Object.Currency);
		EndIf;
		
		ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, "Counterparty", , True);
		
		CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.ARAPDetailsLoanDepositContract);
		CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.DecryptionWithoutSplittingTheLoanDepositAgreement);
		
		If Object.BusinessOperation = Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment Then
			
			FilterParameters = Catalogs.AcquiringContracts.ParametersOfAcquisitionContractSelection();
			
			FilterParameters.Organization = Object.Organization;
			FilterParameters.Acquirer = Object.Counterparty;
			FilterParameters.BankAccount = Object.BankAccount;
			Object.AcquiringContract = Catalogs.AcquiringContracts.ContractOfAcquiringByDefault(FilterParameters);
			
			If ValueIsFilled(Object.AcquiringContract) Then
				AcquiringAgreementInCaseOfChangesOnServer();
			EndIf;
		EndIf;
		CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.ARAPDetailsLeaseContracts);
		CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.DecryptionWithoutSplittingTheLeaseAgreement);
	EndIf;
	FillInContractFeeSVObjectOfSettlementARAPObject();
	
	SetVisibilityOfGiftCertificateSelectionButton();
	
	If Not DecryptionSwitch Then
		SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	EndIf;
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	ConfigureDependentFormElementsOnServer("Counterparty");
	
EndProcedure

&AtClient
Procedure AcquiringContractOnChange(Item)
	
	AcquiringAgreementInCaseOfChangesOnServer();
	
EndProcedure

&AtServer
Procedure AcquiringAgreementInCaseOfChangesOnServer()
	
	AttributesValues = Catalogs.AcquiringContracts.ContractDetails_(Object.AcquiringContract);
	
	Object.CashFlowItem = AttributesValues.CashFlowItemCashReceipt;
	
	Object.RecordCommission = (AttributesValues.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.OnCashReceiving);
	
	If Object.RecordCommission Then
		
		If AttributesValues.FixedFeeRate Then
			CommissionRate = AttributesValues.CommissionRate;
			Object.FeeAmount = CashClientServer.CalculateCommissionAmount(Object.DocumentAmount, CommissionRate, "Inpayment");
		Else
			CommissionRate = 0;
		EndIf;
		
		Object.ExpenseItem          = AttributesValues.ExpenseItem;
		Object.DimensionOfExpenses       = AttributesValues.DimensionOfExpenses;
		Object.Department           = AttributesValues.ExpensesBusinessUnit;
		Object.LineOfBusiness = AttributesValues.LineOfBusiness;
		Object.KeepRecordsOfCommissionInARAPAccounting = AttributesValues.KeepRecordsOfCommissionInARAPAccounting;
		Object.CommissionARAPObject = AttributesValues.CommissionARAPObject;
		CommissionAgreement = ContractARAPObjectOfFee(Object.CommissionARAPObject);
	Else
		Object.FeeAmount = 0;
		Object.KeepRecordsOfCommissionInARAPAccounting = False;
		Object.CommissionARAPObject = Catalogs.ARAPObjects.EmptyRef();
		CommissionAgreement = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	KeepRecordsOfCommissionInMutualSettlementsSwitch = Object.KeepRecordsOfCommissionInARAPAccounting;
	
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountReceiptNote.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure AdvanceHolderOnChange(Item)
	
	AdvanceHolderOnChangeServer();
	
EndProcedure

&AtServer
Procedure AdvanceHolderOnChangeServer()
	
	If ValueIsFilled(Object.AdvanceHolder) And Not ValueIsFilled(Object.CounterpartyBankAccount) Then
		Object.CounterpartyBankAccount =
			Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Object.AdvanceHolder, Object.Currency);
	EndIf;
	
	ConfigureDependentFormElementsOnServer("AdvanceHolder");
	
EndProcedure

&AtClient
Procedure SenderBankAccountOnChange(Item)
	
	SenderBankAccountOnChangeServer();
	
EndProcedure

&AtServer
Procedure SenderBankAccountOnChangeServer()
	
	OnChangeSenderSBankAccount();
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CurrencyOfConversionOnChange(Item)
	
	CurrencyOfConversionOnChangeServer();
	
EndProcedure

&AtClient
Procedure ConversionRateOnChange(Item)
	
	RecalculateConversionParameters("ConversionRate");
	
EndProcedure

&AtClient
Procedure ConversionAmountOnChange(Item)
	
	RecalculateConversionParameters("ConversionAmount");
	
	If Object.ARAPDetails.Count() = 1 Then
		Object.ARAPDetails[0].Sum = Object.DocumentAmount;
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.TheDecryptionPage And Not DecryptionSwitch And Not ReadOnly Then
		ARAPDetailsOnStartEdit(Item, False, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure MirrorPaymentClick(Item, StandardProcessing)
	
	If ValueIsFilled(InvertedPaymentReference) Then
		StandardProcessing = False;
		ShowValue(,InvertedPaymentReference);
	EndIf;
	
EndProcedure

&AtClient
Procedure FiscalOperationStatusURLProcessing(Item, Var_URL, StandardProcessing)
	
	GeneratingFiscalChecksClient.FiscalOperationNavigationLinkProcessing(
		ThisObject, Var_URL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FiscalTransactionCompletion(Result, AdditionalParameters) Export
	
	FiscalOperationCompletionOnServer();
	
EndProcedure

&AtServer
Procedure FiscalOperationCompletionOnServer()
	
	GeneratingFiscalChecksServer.UpdateFiscalCheckBreakdownHyperlink(Object.Ref, ThisObject, FiscalOperationStatus);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	ClearCalculationObject(CurrentRow);
	
	If ValueIsFilled(Object.Contract) Then
		
		ContractDetails_ = Undefined;
		CashServer.FillInDataOfDocumentFormByContract(ThisObject, ContractDetails_);

		If CommonClientServer.HasAttributeOrObjectProperty(ContractDetails_, "FinancialAccountingGroup") Then
			Object.FinancialAccountingGroup = ContractDetails_.FinancialAccountingGroup;
		EndIf;

		If CommonClientServer.HasAttributeOrObjectProperty(ContractDetails_, "LineOfBusiness") Then
			Object.LineOfBusiness = CashServer.LineOfBusiness(
				Object.BusinessOperation, 
				ContractDetails_.LineOfBusiness);
		EndIf;

		FillInPaymentDecryptionLineUnderContract(CurrentRow, ContractDetails_);
		FillInCurrencyOfMutualSettlementsOfDocument();
		
	EndIf;
	
	CashServer.CheckFillInARAPObject(Object, Items.ARAPDetails.CurrentRow);
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
	
	CompleteVATTaxation();
	ProcessIPChange();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
	StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure ReturnAgreementCreating(Item, StandardProcessing)

	StandardProcessing = False;
	
	CashClient.OpenCreationOfRefundContract(ThisObject, Item);

EndProcedure

&AtClient
Procedure FeeAmountOnChange(Item)
	
	If Object.DocumentAmount <> 0 Then
		CommissionRate = CashClientServer.CalculateCommissionRate(
			Object.DocumentAmount, Object.FeeAmount, "Inpayment");
	Else
		CommissionRate = 0;
	EndIf;
	Items.GroupCommission.Title = NStr("vi = 'Phí ngân hàng';
										|ru = 'Комиссия';
										|en = 'Fee'; fa = 'کارمزد';
										|it = 'Commissione';
										|pl = 'Prowizja';
										|tr = 'Komisyon'") +
		" " + String(Object.FeeAmount) + " " + String(Object.Currency) + " " + String(CommissionRate) + "%";
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemStartListChoice(Item, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
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
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(ThisObject, FormattedStringURL, StandardProcessing);			
EndProcedure

&AtClient
Procedure CurrencyDecorationAndPaymentRateClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("CurrencyDecorationAndPaymentRateClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	//Moneysredstvaklient.Currencies and Payment methods(This Form, Element, Standard Processing, Notification);
	
EndProcedure

&AtClient
Procedure CurrencyDecorationAndPaymentRateClickCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrencyDecorationAndPaymentRateClickFinishOnServer();
	
EndProcedure

&AtServer
Procedure CurrencyDecorationAndPaymentRateClickFinishOnServer()
	
	FillMultiplicityCourseWithText();
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure BankConfirmationAboutCashReceiptOnEmployeeAccountOnChange(Item)

	ConfirmationOfSalaryTransferWhenChangeIsMadeOnServer();

EndProcedure

&AtClient
Procedure DecorationSparkriskieIndexesURLProcessing(Item, FormattedStringURL, StandardProcessing)

	
	Return;

EndProcedure

&AtClient
Procedure PaymentDocumentTypeOnChange(Item)
	
	If Not Object.ProcessedByBank Then
		
		If Object.PaymentDocumentType = PredefinedValue("Enum.TypesOfPaymentDocuments.CollectionOrder_2")
			Or Object.PaymentDocumentType = PredefinedValue("Enum.TypesOfPaymentDocuments.PaymentWarrant") Then
			
			Object.ProcessedByBank = True;
			Object.BankPostingDate = Object.Date;
		EndIf;
	EndIf;
	
	ConfigureDependentFormElements(Item.Name);
	
	Return;
	
EndProcedure

&AtClient
Procedure PaymentIDAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure PaymentIDChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	
EndProcedure

&AtClient
Procedure PaymentIDTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure WithdrawalDocumentOnChange(Item)
	
	WithdrawalDocumentOnChangeServer();
	
EndProcedure

&AtClient
Procedure WithdrawalDocumentStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts") Or
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram") Then
		
		Item.TypeRestriction = New TypeDescription("DocumentRef.BankAccountIssue");
		Item.ChooseType = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure TaxTypeOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure TextDetailsOfPaymentToBudgetClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure TransferOfTaxesAndContributionsOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure ConversionRateMultiplierOnChange(Item)

	MultiplicityOfConversionRateWhenChangingOnServer();

EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)

	DirectionOfActivityWhenChangingOnServer();

EndProcedure

&AtClient
Procedure FinancialAccountingGroupOnChange(Item)

	FinancialAccountingGroupOnChangeAtServer();

EndProcedure

&AtClient
Procedure DecryptionWithoutPartitioningPartnerOnChange(Item)

	ARAPDetailsPartnerOnChangeAtServer();

EndProcedure

&AtClient
Procedure CounterpartyBankAccountCreating(Item, StandardProcessing)
	CashClientLocalization.StartCreatingBankAccount(Object.Counterparty, StandardProcessing, ThisObject, "CounterpartyBankAccount");
EndProcedure

&AtClient
Procedure KeepRecordsOfCommissionInMutualSettlementsSwitchOnChange(Item)
	
	KeepRecordsOfCommissionInMutualSettlementsSwitchOnChangesAtServer();
	
EndProcedure

&AtClient
Procedure CommissionAgreementStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("DeletionMark", False);
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("Counterparty", Object.Counterparty);
	FilterStructure1.Insert("ARAPCurrency", Object.Currency);
	FilterStructure1.Insert("ARAPObjectSettings", PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts"));
	
	StructureOfSelectionParameters = New Structure;
	StructureOfSelectionParameters.Insert("ChoiceMode", True);
	StructureOfSelectionParameters.Insert("ContractTypes", ARAPAccountingClientServer.TypesOfContractsWithSupplier());
	StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
	
	OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm", StructureOfSelectionParameters, Item, Item);
	
EndProcedure

&AtClient
Procedure CommissionAgreementOnChange(Item)
	
	ContractFeesOnChangesATServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersARAPDetails

&AtClient
Procedure DecryptionSwitchOnChange(Item)
	
	If Not DecryptionSwitch Then
		If Object.ARAPDetails.Count() = 0 Then
			Object.ARAPDetails.Add();
			Items.ARAPDetails.CurrentRow = Object.ARAPDetails[0].GetID();
			ARAPDetailsOnStartEdit(Items.ARAPDetails, True, False);
		ElsIf Object.ARAPDetails.Count() = 1 Then
			If Items.ARAPDetails.CurrentRow = Undefined Then
				Items.ARAPDetails.CurrentRow = Object.ARAPDetails[0].GetID();
			EndIf;
		ElsIf Object.ARAPDetails.Count() > 1 Then
			ClearMessages();
			MessageText = NStr("vi = 'Chuyển sang chế độ không phân chia là không thể nếu có nhiều hơn một dòng được nhập vào giải mã thanh toán!';
								|ru = 'Переключение в режим без разбиения невозможно, если в расшифровке платежа введено более одной строки!';
								|en = 'Cannot switch to no-split mode if multiple lines are entered into the payment details.'; fa = 'Cannot switch to no-split mode if multiple lines are entered into the payment details.';
								|it = 'Passare alla modalità senza la partizione è impossibile se nella decifrazione del pagamento viene inserita più di una riga!';
								|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w szczegółach płatności wprowadzono więcej niż jeden wiersz!';
								|tr = 'Ödeme detayında birden fazla satır girilmişse ayrıştırılmış moda geçmek mümkün değildir!'");
			CommonClientServer.MessageToUser(MessageText);
			DecryptionSwitch = 1;
		EndIf;
	EndIf;
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure ARAPDetailsOnChange(Item)
	DetermineUseOfLeaseSettlementDocument();
	Return;

EndProcedure

&AtClient
Procedure ARAPDetailsOnStartEdit(Item, NewRow, Copy)
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	If Not ValueIsFilled(Partner) Then
		GetDefaultServerPartner(Object.Counterparty, Partner, Object.BusinessOperation);
	EndIf;
	
	FinancesClient.ARAPDetailsOnStartEdit(
		Object, Partner, CounterpartyContract, TableRow, NewRow, Copy, CashFlowItem);
		
	If NewRow Then
		If Not Copy Then
			
			TableRow.ARAPCurrency = Object.Currency;
			TableRow.ExchangeRateNumeratorOfMutualSettlements = 1;
			TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
			
			If Not ValueIsFilled(TableRow.CashFlowItem) Then
				TableRow.CashFlowItem = Object.CashFlowItem;
			EndIf;
			
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, TableRow, "Object.ARAPDetails");
		EndIf;
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			TableRow, Object.Currency, CurrencyOfComplianceAccounting);
		UpdateTaxRateRecalculateVATAmount(TableRow.GetID());
	EndIf;
	
	DecryptionOfPaymentAmountWhenChangedOnServer();
	
	//Setting up accounting accounts 
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
EndProcedure

&AtClient
Procedure ARAPDetailsOnEditEnd(Item, NewRow, CancelEdit)
	
	DecryptionOfPaymentAtEndOfEditingOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentAtEndOfEditingOnServer()
	
	CashServer.FillInCurrencyOfMutualSettlementsOfDocument(ThisObject);
	CurrencyDecorationAndPaymentRate = CashServer.CurrencyLabelAndPaymentRate(ThisObject);
	
EndProcedure

&AtClient
Procedure ARAPDetailsPaymentPurposeOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	TableRow.AmountARAP = 0;
	
	If Not ValueIsFilled(TableRow.PaymentPurpose) Then
		TableRow.ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
		TableRow.MaturityDate = Date(1, 1, 1);
	EndIf;
	
	DecryptionOfTheCalculationObjectWhenChangingServer(TableRow.GetID());
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtClient
Procedure ARAPDetailsSelection(Item, RowSelected, Field, StandardProcessing)
	If Field.Name = "ARAPDetailsPresentationOfRecordingInComplAccounting" Then
		GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure DecryptionOfTheCalculationObjectWhenChanging(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	TableRow.AmountARAP = 0;
	
	If Not ValueIsFilled(TableRow.ARAPObject) Then
		
		TableRow.PaymentPurpose = Undefined;
		TableRow.MaturityDate = Date(1, 1, 1);
		
	EndIf;
	
	DecryptionOfTheCalculationObjectWhenChangingServer(TableRow.GetID());
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtServer
Procedure DecryptionOfTheCalculationObjectWhenChangingServer(LineID)
	
	CashServer.CheckFillOutContract(Object, LineID);
	TableRow = Object.ARAPDetails.FindByID(LineID);
	CashServer.UpdateSettlementCurrencyOfPaymentDecryption(
		"Document.BankAccountReceiptNote", Object, CurrencyOfComplianceAccounting);
	
	CashServer.FormCourseDenominatorByText(TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	YouAreAllowedToWorkWithAffiliatedPartners(TableRow);
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(
		Object, Items.ARAPDetails.CurrentRow, True);
		
	If ValueIsFilled(TableRow.ARAPObject) Then
		TableRow.CashFlowItem = CashServer.ArticleOfCashFlowOfSettlementObject(
			TableRow.ARAPObject, Object.BusinessOperation);
	EndIf;
	
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	UpdateTaxRateRecalculateVATAmount(LineID);
	ProcessIPChange(TableRow);
	ARAPAccountingFormWork.BlockSettlementObjects(ThisObject);
	
EndProcedure

&AtClient
Procedure ARAPDetailsPaymentPurposeStartChoice(Item, ChoiceData, StandardProcessing)
	
	PaymentPurpose = Undefined;
	CurrentData = Items.ARAPDetails.CurrentData;
	If CurrentData <> Undefined Then
		PaymentPurpose = CurrentData.PaymentPurpose;
	EndIf;
	
	ARAPAccountingClient.ARAPObjectStartChoice(ThisForm, Item, StandardProcessing, True, PaymentPurpose);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	ARAPObject = Undefined;
	CurrentData = Items.ARAPDetails.CurrentData;
	If CurrentData <> Undefined Then
		ARAPObject = CurrentData.ARAPObject;
	EndIf;
	
	ARAPAccountingClient.ARAPObjectStartChoice(ThisForm, Item, StandardProcessing,, ARAPObject);
	
EndProcedure

&AtClient
Procedure ARAPDetailsPaymentPurposeAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, False);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, True);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectChoiceProcessing(Item, ValueSelected, AdditionalData,
	ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		PaymentDecryptionSettlementObjectSelectionProcessingOnServer(ValueSelected);
	EndIf;
	
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheCalculationObjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, True);
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheCalculationObjectChoiceProcessing(Item, ValueSelected, AdditionalData,
	ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		PaymentDecryptionSettlementObjectSelectionProcessingOnServer(ValueSelected);
	EndIf;
	
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheBasisOfThePaymentAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ARAPDetailsPaymentPurposeAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheBasisOfThePaymentChoiceProcessing(Item, ValueSelected, AdditionalData,
	ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		ARAPDetailsPaymentBasisChoiceProcessingAtServer(ValueSelected);
	EndIf;
	
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtClient
Procedure ARAPDetailsPaymentPurposeTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, False);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, True);
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheCalculationObjectTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, True);
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheBasisOfThePaymentTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, False);
	
EndProcedure

&AtClient
Procedure ARAPDetailsPaymentPurposeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		ARAPDetailsPaymentBasisChoiceProcessingAtServer(ValueSelected);
	EndIf;
	
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtServer
Procedure PaymentDecryptionSettlementObjectSelectionProcessingOnServer(ValueSelected)
	
	RowID = Items.ARAPDetails.CurrentRow;
	TableRow = Object.ARAPDetails.FindByID(RowID);
	
	TableRow.Organization = ValueSelected.Organization;
	TableRow.Partner = ValueSelected.Partner;
	TableRow.PaymentPurpose = ValueSelected.PaymentPurpose;
	TableRow.Contract = ValueSelected.Contract;
	TableRow.LineOfBusiness = ValueSelected.LineOfBusiness;
	TableRow.ItIsAllowedToWorkWithSubsidiaryPartners = ValueSelected.ItIsAllowedToWorkWithSubsidiaryPartners;
	TableRow.AmountARAP = ValueSelected.AmountARAP;
	TableRow.ARAPObject = ValueSelected.ARAPObject;
	TableRow.ARAPCurrency = ValueSelected.ARAPCurrency;
	TableRow.PaymentID = ValueSelected.PaymentID;
	TableRow.MaturityDate = ValueSelected.MaturityDate;
	
	ValueSelected.Insert("CashFlowItem");
	ValueSelected.Insert("ExchangeRateNumeratorOfMutualSettlements", 1);
	ValueSelected.Insert("TheExchangeRateIsTheDenominatorOfMutualSettlements", 1);
	
	AddSelectedValue(ValueSelected);
	
	If ValueIsFilled(ValueSelected.CashFlowItem) Then
		TableRow.CashFlowItem = ValueSelected.CashFlowItem;
	EndIf;
	
	TableRow.VATRate = ValueSelected.VATRate;
	TableRow.VATAmount = ValueSelected.VATAmount;
	TableRow.ExchangeRateNumeratorOfMutualSettlements = ValueSelected.ExchangeRateNumeratorOfMutualSettlements;
	TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = ValueSelected.TheExchangeRateIsTheDenominatorOfMutualSettlements;
	
	UpdateTaxRateRecalculateVATAmount(TableRow.GetID());
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.RefundFromAnotherCompany 
		And Object.BusinessOperation <> Enums.BusinessTransactions.RefundFromVendor Then
		Contracts = Object.ARAPDetails.Unload( , "Contract").UnloadColumn("Contract");
		Contracts = CommonClientServer.CollapseArray(Contracts);
		If Contracts.Count() = 1 Then
			Object.Contract = TableRow.Contract;
		EndIf;
	EndIf;
	
	Modified = True;
	ARAPAccountingFormWork.BlockSettlementObjects(ThisForm);
	
	If Not ValueIsFilled(TableRow.ARAPObject) Then
		
		If ValueIsFilled(TableRow.Contract) Then
			Object.Contract = TableRow.Contract;
			AgreementWhenModifiedOnServer();
		EndIf;
		
	EndIf;
	
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	
	CashServer.CheckFillOutContract(Object, RowID);
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, RowID, True);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
	GenerateHyperlinkCaptionPaymentObjectDetails();
	FillInCourseAndMultiplicityInDecryptionLine(TableRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	YouAreAllowedToWorkWithAffiliatedPartners(TableRow);
	ProcessIPChange(TableRow);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure ARAPDetailsPaymentBasisChoiceProcessingAtServer(ValueSelected)

	RowID = Items.ARAPDetails.CurrentRow;
	TableRow = Object.ARAPDetails.FindByID(RowID);
	
	TableRow.PaymentPurpose = ValueSelected.PaymentPurpose;
	TableRow.ARAPObject = ARAPObjectsServer.ARAPObjectOnBasisOfPayment(TableRow.PaymentPurpose);

	DecryptionOfTheCalculationObjectWhenChangingServer(RowID)

EndProcedure

&AtServer
Procedure AddSelectedValue(ValueSelected)
	
	ValueSelected.Insert("CashFlowItem",
		CashServer.ArticleOfCashFlowOfSettlementObject(ValueSelected.ARAPObject, Object.BusinessOperation));
	
	ARAPObjects = New Array;
	ARAPObjects.Add(ValueSelected.ARAPObject);
	
	VATTable = CashServer.TranscriptOfVATPayment(Object.Organization, Undefined, Undefined, ARAPObjects, ValueSelected.TheseAreSettlementsWithCustomers);
	If VATTable.Count() = 1 Then
		ValueSelected.Insert("VATRate", VATTable[0].VATRate);
		If ValueSelected.PaymentAmount = ValueSelected.OrderAmount Then
			ValueSelected.Insert("VATAmount", VATTable[0].VATAmount);
		EndIf;
	EndIf;
	
	If ValueIsFilled(ValueSelected.ARAPCurrency) Then
		CurrencyExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(ValueSelected.ARAPCurrency, Undefined,
						SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
		ValueSelected.Insert("ExchangeRateNumeratorOfMutualSettlements", CurrencyExchangeRate.CourseNumerator);
		ValueSelected.Insert("TheExchangeRateIsTheDenominatorOfMutualSettlements", CurrencyExchangeRate.CourseDenominator);
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPDetailsSumOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
	DecryptionOfPaymentAmountWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentAmountWhenChangedOnServer()
	
	CurrencyDecorationAndPaymentRate = CashServer.CurrencyLabelAndPaymentRate(ThisObject);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
EndProcedure

&AtClient
Procedure ARAPDetailsAmountARAPOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	If ValueIsFilled(TableRow.AmountARAP)
		And TableRow.ARAPCurrency = Object.Currency
		And TableRow.AmountARAP <> TableRow.Sum Then
		TableRow.AmountARAP = TableRow.Sum;
	Else
		DecryptionOfPaymentAmountOfSettlementsWhenChangingOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentAmountOfSettlementsWhenChangingOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	If CurrentRow.Sum = 0 Then
		CashClientServer.CalculateAmountInDecryptionLine(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	Else
		CashServer.CalculateExchangeRateNumeratorOfMutualSettlementsInDecryptionLine(
			CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndIf;
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPCurrencyOnChange(Item)
	
	DecryptionOfPaymentCurrencyOfSettlementsWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentCurrencyOfSettlementsWhenChangedOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	ArrayOfOperationDetails = New Array;
	Documents.BankAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		Object, Undefined, ArrayOfOperationDetails);
	
	If CurrentRow.ARAPCurrency <> ARAPCurrency
		And ArrayOfOperationDetails.Find("Contract") <> Undefined Then
		Object.Contract = Undefined;
		CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	EndIf;
	
	ClearCalculationObject(CurrentRow);
	FillInCourseAndMultiplicityInDecryptionLine(CurrentRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	UpdateTaxRateRecalculateVATAmount(Items.ARAPDetails.CurrentRow);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure ARAPDetailsExchangeRateNumeratorOfMutualSettlementsOnChange(Item)
	
	DecryptionOfPaymentExchangeRateNumeratorOfSettlementsWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentExchangeRateNumeratorOfSettlementsWhenChangedOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	
EndProcedure

&AtServer
Procedure FillInCourseAndMultiplicityInDecryptionLine(TSRow)
	
	DateOfCourse = ?(ValueIsFilled(Object.BankPostingDate), Object.BankPostingDate, Object.Date);
	CashServer.FillInCourseOfMutualSettlementsOfDecryptionLine(Object, CurrencyOfComplianceAccounting, DateOfCourse, TSRow);
	
EndProcedure

&AtClient
Procedure ARAPDetailsLoanDepositContractOnChange(Item)
	
	ARAPDetailsLoanDepositContractOnChangeServer();
	
EndProcedure

&AtServer
Procedure ARAPDetailsLoanDepositContractOnChangeServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	ContractDetails_ = Common.ObjectAttributesValues(CurrentRow.LoanDepositContract,
		"ARAPCurrency, ContractKind, CashFlowItemOfPrincipalDebt, CashFlowItemOfReceiptIssuie");
	
	CurrentRow.ARAPCurrency = ContractDetails_.ARAPCurrency;
	If ContractDetails_.ContractKind = Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing Then
		CurrentRow.CashFlowItem = ContractDetails_.CashFlowItemOfReceiptIssuie;
	Else
		
		If TakeIntoAccountTypeOfLoanAmountDeposit(CurrentRow.LoanAndDepositAmountType) Then
			CurrentRow.CashFlowItem =
				CashServer.ArticleOfDepositLoanContractByTypeOfDepositLoanAmount(
					CurrentRow.LoanDepositContract,
					CurrentRow.LoanAndDepositAmountType,
					Object.CashFlowItem);
		Else
			CurrentRow.CashFlowItem = ContractDetails_.CashFlowItemOfPrincipalDebt;
		EndIf;
		
	EndIf;
	
	FillInCourseAndMultiplicityInDecryptionLine(CurrentRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
EndProcedure

&AtClient
Procedure ARAPDetailsLoanAndDepositAmountTypeOnChange(Item)
	
	TypeOfDepositCreditAmountWhenServerChanges();
	
EndProcedure

&AtServer
Procedure TypeOfDepositCreditAmountWhenServerChanges()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty Then
		
		CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
		
		CurrentRow.CashFlowItem =
			CashServer.ArticleOfDepositLoanContractByTypeOfDepositLoanAmount(
				CurrentRow.LoanDepositContract,
				CurrentRow.LoanAndDepositAmountType,
				Object.CashFlowItem);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPDetailsIncomeItemOnChange(Item)
	
	ARAPDetailsIncomeItemOnChangeServer(Item.Name);
	
EndProcedure

&AtServer
Procedure ARAPDetailsIncomeItemOnChangeServer(TagName);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	
EndProcedure

&AtClient
Procedure ARAPDetailsIncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ARAPDetailsDimensionOfRevenueOnChange(Item)
	
	IncomeAndExpensesClientServer.DimensionOfRevenueOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ARAPDetailsAssetsLiabilitiesDimensionOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetsLiabilitiesDimensionOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure HyperlinkPaymentObjectDetailsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	BlockData_();
	
	CallbackDescription = New CallbackDescription("HyperlinkPaymentObjectDetailsClickCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromOtherCompany")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany") Then
		FormParameters.Insert("Counterparty",            CompanyPayer);
	Else
		FormParameters.Insert("Counterparty",            Object.Counterparty);
	EndIf;
	
	FormParameters.Insert("FinancialAccountingGroup",    Object.FinancialAccountingGroup);
	FormParameters.Insert("LineOfBusiness",   Object.LineOfBusiness);
	FormParameters.Insert("Contract",                   Object.Contract);
	FormParameters.Insert("Organization",               Object.Organization);
	FormParameters.Insert("Department",             Object.Department);
	FormParameters.Insert("VATTaxation",      Object.VATTaxation);
	FormParameters.Insert("ListOfVATTaxes", Items.DecodingWithoutSplittingVATTaxation.ChoiceList);
	FormParameters.Insert("DocumentRef",            Object.Ref);
	FormParameters.Insert("AddressInTempStorage", PlaceDecryptionInTemporaryStorage());

	OpenForm("CommonForm.FormForSelectionOfPaymentARAPObjectDetails", 
		FormParameters,
		ThisForm,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure HyperlinkPaymentObjectDetailsClickCompletion(Result, AdditionalParameters) Export
	
	UnlockData();
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.FinancialAccountingGroup  = Result.FinancialAccountingGroup;
	Object.LineOfBusiness = Result.LineOfBusiness;
	Object.Contract                 = Result.Contract;
	Object.Department           = Result.Department;
	HyperlinkDetailsOfSettlementObjectClickEndOnServer();
	ThereIsChangeInVATTaxation = ?(Object.VATTaxation = Result.VATTaxation, False, True);
	
	If ThereIsChangeInVATTaxation Then
		Object.VATTaxation = Result.VATTaxation;
		CompleteVATTaxation();
	EndIf;
	
EndProcedure

&AtServer
Procedure HyperlinkDetailsOfSettlementObjectClickEndOnServer()

	ModifiedRows = CashServer.CheckFillInARAPObject(Object);
	
	For Each IndexOf In ModifiedRows Do
		DecryptionString = Object.ARAPDetails[IndexOf]; 
		CashServer.CheckFillOutContract(Object, DecryptionString.GetID());
		CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, DecryptionString.GetID(), True);
		SetRestrictionOnTypeOfPaymentDecryptionContract();
		
		FillInCourseAndMultiplicityInDecryptionLine(DecryptionString);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
		YouAreAllowedToWorkWithAffiliatedPartners(DecryptionString);
		ProcessIPChange(DecryptionString);
	EndDo;
	
	If ValueIsFilled(Object.Contract) Then
		
		ContractDetails_ = Undefined;
		CashServer.FillInDataOfDocumentFormByContract(ThisObject, ContractDetails_);
		
		For Each DecryptionString In Object.ARAPDetails Do
			
			If (Not ValueIsFilled(DecryptionString.ARAPObject)
				Or DecryptionString.CalculationObject = Object.Ref) Then
				FillInPaymentDecryptionLineUnderContract(DecryptionString, ContractDetails_);
			EndIf;
			
		EndDo;
		
		FillInCurrencyOfMutualSettlementsOfDocument();
		
		StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
		BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
		
	Else
		CashServer.ClearPaymentDecryptionContract(Object);
	EndIf;
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();

EndProcedure

&AtClient
Procedure DecodingWithoutSplittingRepresentationOfReflectionInReglAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
	
EndProcedure

&AtClient
Procedure SettlementObjectContractStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("DeletionMark", False);
	
	StructureOfSelectionParameters = New Structure;
	StructureOfSelectionParameters.Insert("ChoiceMode", True);
	StructureOfSelectionParameters.Insert("AllowSelectionOfBranchContracts", True);
	StructureOfSelectionParameters.Insert("Partner", Partner);
	StructureOfSelectionParameters.Insert("Counterparty", Object.Counterparty);
	StructureOfSelectionParameters.Insert("Organization", Object.Organization);
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromOtherCompany") 
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany") Then
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany") Then
			FilterStructure1.Organization = CompanyPayer;
			FilterStructure1.Insert("CompanyRecipient", Object.Organization);
		Else
			FilterStructure1.Insert("CompanyRecipient", CompanyPayer);
		EndIf;
		
		StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
		OpenForm("Catalog.IntercompanyContracts.Form.ChoiceForm",
			StructureOfSelectionParameters,
			Item,
			Item,)
	Else
		FilterStructure1.Insert("Counterparty", Object.Counterparty);
		
		If FinancesClient.TheseAreSettlementsWithCustomers(Object.BusinessOperation) Then
			ContractTypes = ARAPAccountingClientServer.TypesOfContractsWithClient();
		Else
			ContractTypes = ARAPAccountingClientServer.TypesOfContractsWithSupplier();
		EndIf;
		
		ContractTypes.Add(PredefinedValue("Enum.ContractTypes.WithConsignor"));
		
		FilterStructure1.Insert("ContractType", New FixedArray(ContractTypes.UnloadValues()));
		FilterStructure1.Insert("Partner", Partner);
		StructureOfSelectionParameters.Insert("ShowSalesThroughCommissionAgent", True);
		
		StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
		OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm",
			StructureOfSelectionParameters,
			Item,
			Item,)
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPDetailsAfterDeleteRow(Item)
	
	ARAPDetailsAfterDeleteRowServer();
	
EndProcedure

&AtServer
Procedure ARAPDetailsAfterDeleteRowServer()
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	FillInCurrencyOfMutualSettlementsOfDocument();
	DefineUIPIsDifferent();
	ARAPAccountingFormWork.BlockSettlementObjects(ThisForm);
	
EndProcedure

&AtClient
Procedure ARAPDetailsVATRateOnChange(Item)
	
	CurrentRow = Items.ARAPDetails.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	Items.DecryptionWithoutSplittingTheVATAmount.ReadOnly =
		CashClientServer.ThisIsZeroVATRATE(CurrentRow.VATRate);
	
EndProcedure

&AtClient
Procedure ARAPDetailsLeaseContractsOnChange(Item)
	ARAPDetailsLeaseContractsOnChangeServer();
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	Return;
	
EndProcedure

&AtServer
Procedure ARAPDetailsLeaseContractsOnChangeServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	QueryText = 
	"SELECT
	|	LeaseContract.CashFlowItem AS CashFlowItem,
	|	LeaseContract.ARAPCurrency AS ARAPCurrency,
	|	TermsOfLeaseContracts.VATRate AS VATRate,
	|	LeaseContract.HasSecurityDeposit AS HasSecurityDeposit
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts.SliceLast(, Contract = &LeaseContracts) AS TermsOfLeaseContracts
	|		ON TermsOfLeaseContracts.Contract = &LeaseContracts
	|WHERE
	|	LeaseContract.Ref = &LeaseContracts";
	
	Query = New Query(QueryText);
	Query.SetParameter("LeaseContracts", CurrentRow.LeaseContracts);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		FillPropertyValues(CurrentRow, Selection);
		
		If Selection.HasSecurityDeposit Then
			CurrentRow.TypeOfLeasePayment = Enums.TypesOfLeasePayments.DepositPayment;
		Else
			CurrentRow.TypeOfLeasePayment = Enums.TypesOfLeasePayments.RentalService;
		EndIf;
		
	EndIf;
	
	CurrentRow.AmountARAP = 0;
	
	Items.DecryptionWithoutSplittingTheTypeOfRentPayment.ChoiceParameters = New FixedArray(New Array);
	TMCommonUseClientServer.AddSelectionParameter(
		Items.DecryptionWithoutSplittingTheTypeOfRentPayment, "Contract", CurrentRow.LeaseContracts);
	TMCommonUseClientServer.AddSelectionParameter(Items.DecryptionWithoutSplittingTheTypeOfRentPayment, "Payment_", True);
	
	Items.ARAPDetailsTypeOfLeasePayment.ChoiceParameters = New FixedArray(New Array);
	TMCommonUseClientServer.AddSelectionParameter(
		Items.DecryptionWithoutSplittingTheTypeOfRentPayment, "Contract", CurrentRow.LeaseContracts);
	TMCommonUseClientServer.AddSelectionParameter(Items.ARAPDetailsTypeOfLeasePayment, "Payment_", True);
	
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	DetermineUseOfLeaseSettlementDocument();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure
&AtClient
Procedure DecryptionWithoutSplittingTheTypeOfRentPaymentOnChange(Item)
	DetermineUseOfLeaseSettlementDocument();
	Return;
	
EndProcedure

&AtClient
Procedure ARAPDetailsTypeOfLeasePaymentOnChange(Item)
	DetermineUseOfLeaseSettlementDocument();
	Return;

EndProcedure

&AtClient
Procedure TranscriptTypeOfRentalPaymentStartOfSelection(Item, ChoiceData, StandardProcessing)
	CurrentData = Items.ARAPDetails.CurrentData;
	
	PaymentTypeSelectionParameters = New Array;
	PaymentTypeSelectionParameters.Add(New ChoiceParameter("Filter.Contract", CurrentData.LeaseContracts));
	PaymentTypeSelectionParameters.Add(New ChoiceParameter("Filter.Refund_", True));
	Items.ARAPDetailsTypeOfLeasePayment.ChoiceParameters = New FixedArray(PaymentTypeSelectionParameters);
	Items.DecryptionWithoutSplittingTheTypeOfRentPayment.ChoiceParameters = New FixedArray(PaymentTypeSelectionParameters);
	Return;
	
EndProcedure

&AtClient
Procedure DecodingWithoutSplittingVATTaxationOnChange(Item)
	
	CompleteVATTaxation();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	CompleteVATTaxation();
	
EndProcedure

&AtClient
Procedure ARAPDetailsOnActivateCell(Item)
	
	CashClient.SetAvailabilityOfPaymentDecryptionItemAmountOfSettlements(ThisObject, Object.Currency);
	CashClient.SetAvailabilityOfPaymentDecryptionContractElement(ThisObject);
	
EndProcedure

&AtClient
Procedure DecodingWithoutSplittingIsVariantOfContractCourseClick(Item, StandardProcessing)
	ARAPAccountingClient.TranscriptOfPaymentCourseOptionOfContractClick(Items.ARAPDetails.CurrentData, StandardProcessing);
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateOnChange(Item)
	
	Object.ARAPDetails[0].MaturityDate = MaturityDateWithoutSplitting;
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpeningParameters = New Structure("InitialValue", Object.ARAPDetails[0].MaturityDate);
	CallbackDescription = New CallbackDescription("DecryptionWithoutSplittingRepaymentDateEndOfSelection", ThisObject);
	OpenForm("CommonForm.SelectDate", OpeningParameters, ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Object.ARAPDetails[0].MaturityDate = Date(1, 1, 1);
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If TypeOf(MaturityDateWithoutSplitting) = Type("Date") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	DateInNumbers = StrConcat(StrSplit(Text, StrConcat(StrSplit(Text, "0123456789"))));
	If Not IsBlankString(DateInNumbers) Then
		SelectedDay  = Left(DateInNumbers, 2);
		If StrLen(DateInNumbers) > 2 Then
			SelectedMonth = Mid(DateInNumbers, 3, 2);
		Else
			SelectedMonth = Format(CommonClient.SessionDate(), "DF=MM")
		EndIf;
		If StrLen(DateInNumbers) > 4 Then
			SelectedYear = Mid(DateInNumbers, 5, 4);
		Else
			SelectedYear   = Format(CommonClient.SessionDate(), "DF=yyyy")
		EndIf;
		SelectedDateAsString = StrTemplate("%1.%2.%3", SelectedDay, SelectedMonth, SelectedYear);
		SelectedDate = StringFunctionsClientServer.StringToDate(SelectedDateAsString);
		Object.ARAPDetails[0].MaturityDate = SelectedDate;
		UpdatePresentationOfMaturityDate();
		ChoiceData = New ValueList();
		ChoiceData.Add(SelectedDate);
	EndIf;
	
EndProcedure

&AtClient
Procedure TranscriptOfPaymentContractOnChange(Item)
	
	LineOfATabularSection = Items.ARAPDetails.CurrentData;
	
	If LineOfATabularSection = Undefined Then
		Return;
	EndIf;
	
	Object.Contract = LineOfATabularSection.Contract;
	
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure TranscriptOfPaymentContractStartChoice(Item, ChoiceData, StandardProcessing)
	
	SettlementObjectContractStartOfSelection(Item, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ARAPDetailsPartnerOnChange(Item)

	ARAPDetailsPartnerOnChangeAtServer();

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
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SelectionByStock(Command)
	
	ThisIsComingFromAnotherOrganization =
		(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromOtherCompany")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany"));
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("BankAccount", NStr("vi = 'Tài khoản';
																|ru = 'Счет';
																|en = 'Account'; fa = 'حساب';
																|it = 'Conto';
																|pl = 'Account';
																|tr = 'Hesap'"));
	If ThisIsComingFromAnotherOrganization Then
		CheckParameters.CheckedAttributes.Insert("SenderBankAccount", NStr("vi = 'Người gửi';
																			|ru = 'Отправитель';
																			|en = 'Sender'; fa = 'فرستنده';
																			|it = 'Mittente';
																			|pl = 'Nadawca';
																			|tr = 'Gönderen'"));
	Else
		CheckParameters.CheckedAttributes.Insert("Counterparty", NStr("vi = 'Người nộp';
																		|ru = 'Плательщик';
																		|en = 'Payer'; fa = 'پرداخت‌کننده';
																		|it = 'Soggetto pagante';
																		|pl = 'Payer';
																		|tr = 'Ödeyen'"));
	EndIf;
	Notification = New CallbackDescription("SelectionBasedOnBalancesAfterVerification",
		ThisObject, New Structure("ThisIsComingFromAnotherOrganization", ThisIsComingFromAnotherOrganization));
	
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure PickUpGiftCertificate(Command)
	
	If GiftCertificatesClient.CheckPossibilityOfAddingGiftCertificate(ThisObject, False) Then
		DescriptionOfAssuranceNotification = New CallbackDescription("PickUpGiftCertificateCompletion", ThisObject);
		If Object.Posted Then
			RetailSalesClient.DisplayQuestionAboutNeedForUnverifiedDocument(ThisObject, DescriptionOfAssuranceNotification);
		Else
			RunCallback(DescriptionOfAssuranceNotification, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PickUpGiftCertificateCompletion(Result, AdditionalParameters) Export
	
	If Result = True Then
		StatusesForSelection = New Array;
		StatusesForSelection.Add(PredefinedValue("Enum.GiftCertificateStatuses.NotActivated"));
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Organization", Object.Organization);
		FilterParameters.Insert("Currency", CurrencyOfComplianceAccounting);
		FilterParameters.Insert("Status", StatusesForSelection);
		FilterParameters.Insert("GiftCardAccounting25", True);
		FilterParameters.Insert("OperationType", GiftCertificatesClientServer.TypeOfOperationForGiftCertificates(Object));
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Organization", Object.Organization);
		AdditionalParameters.Insert("DoNotUseManualInput", False);
		AdditionalParameters.Insert("Filter", FilterParameters);
		AdditionalParameters.Insert("RegisterNewOnes", True);
		
		OpenForm(
			"Catalog.GiftCertificates.Form.ReadGiftCard",
			AdditionalParameters,
			ThisObject,
			UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionBasedOnBalancesAfterVerification(Result, AdditionalParameters) Export 
	
	Notification = New CallbackDescription("SelectionByStockCompletion", ThisObject);
	PlacePaymentDecryptionInTemporaryStorage();
	
	ARAPAccountingClient.AddToPaymentDecryption(ThisForm, Items.ARAPDetailsSelectionByStock.Name, Notification);
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm, "ARAPDetailsSelectionByStock");
EndProcedure

&AtClient
Procedure SelectionByStockCompletion(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		SelectionByStockCompletionServer();
	EndIf;
EndProcedure

&AtServer
Procedure SelectionByStockCompletionServer()
	
	ARAPAccountingFormWork.DownloadPaymentTranscriptFromTemporaryStorage(ThisObject);
	DefaultCFItem =
		Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Object.BusinessOperation);
	ArticlesOfBusinessOfOperation =
		Catalogs.CashFlowReportItems.ArticlesOfBusinessOfOperation(Object.BusinessOperation);
	
	TableOfCalculationObjects = Object.ARAPDetails.Unload(, "ARAPObject");
	TableOfCalculationObjects.GroupBy("ARAPObject");
	TaxationOfSettlementObjects =
		Common.ObjectsAttributeValue(TableOfCalculationObjects.UnloadColumn("ARAPObject"), "VATTaxation");
	
	For Each TableRow In Object.ARAPDetails Do
		
		If ValueIsFilled(TableRow.ARAPObject) Then
			TableRow.VATTaxation = TaxationOfSettlementObjects[TableRow.ARAPObject];
		EndIf;
		
		If ArticlesOfBusinessOfOperation.Find(TableRow.CashFlowItem) = Undefined Then
			TableRow.CashFlowItem = DefaultCFItem;
		EndIf;
		FillInCourseAndMultiplicityInDecryptionLine(TableRow);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			TableRow, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndDo;
	
	CashServer.CheckFillOutContract(Object);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
	
	// If the selection is not for the entire amount of the document, then you need to fill in the VAT rate on the line without the calculation object
	For Each DecryptionString In Object.ARAPDetails Do
		If Not ValueIsFilled(DecryptionString.ARAPObject)
			Or DecryptionString.CalculationObject = Object.Ref Then
			If ValueIsFilled(DecryptionString.Contract) Then
				DecryptionString.VATRate = Common.ObjectAttributeValue(DecryptionString.Contract, "VATRate");
			EndIf;
			If ValueIsFilled(DecryptionString.VATRate) Then
				StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
				BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
			Else
				UpdateAllRowsOnServer(DecryptionString.GetID());
			EndIf;
		EndIf;
	EndDo;
	
	FillInParametersOfCalculationObjectInDecryption();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure FillInThePaymentExplanationOnLoansForCounterparty(Command)
	
	FillInThePaymentExplanationOnLoansForCounterpartyServer();
	
EndProcedure

&AtServer
Procedure FillInThePaymentExplanationOnLoansForCounterpartyServer()
	
	Object.ARAPDetails.Clear();
	
	CurrentAgreements = Catalogs.LoanAndDepositContracts.CurrentContractsForCounterparty(
		Object.Organization, Object.Counterparty, Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing);
	
	For Each Contract In CurrentAgreements Do
		
		DetailsData = Catalogs.LoanAndDepositContracts.PaymentDecryptionDataOfDDSDocument(Contract, True, Object.Ref);
		
		For Each String In DetailsData Do
			NewRow = Object.ARAPDetails.Add(); 
			FillPropertyValues(NewRow, String);
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, NewRow, "Object.ARAPDetails");
		EndDo;
	EndDo;
	
	Object.DocumentAmount = Object.ARAPDetails.Total("Sum");
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)

	ClearMessages();
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
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
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

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure FillInThePaymentExplanationOnLoansForEmployee(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure SelectionByUIP(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure CheckCounterparties(Command)
	
	Return;
	
EndProcedure

#EndRegion

#Region Private

#Region ElementEventHandlers

&AtServer
Procedure DocumentAmountOnChangeServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		CashServer.RecalculateConversionParameters(Object, CurrencyOfComplianceAccounting, "ConversionRate");
	EndIf;
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	
	If Object.RecordCommission Then
		Object.FeeAmount = CashClientServer.CalculateCommissionAmount(Object.DocumentAmount, CommissionRate, "Inpayment");
		Items.GroupCommission.Title = NStr("vi = 'Phí ngân hàng';
											|ru = 'Комиссия';
											|en = 'Fee'; fa = 'کارمزد';
											|it = 'Commissione';
											|pl = 'Fee';
											|tr = 'Komisyon'") +
			" " + String(Object.FeeAmount) + " " + String(Object.Currency) + " " + String(CommissionRate) + "%";
	EndIf;
	
	CalculateAmountOfSettlements_();
	FillInCurrencyOfMutualSettlementsOfDocument();
	
EndProcedure

&AtServer
Procedure CurrencyOfConversionOnChangeServer()
	
	CashServer.RecalculateConversionParameters(Object, CurrencyOfComplianceAccounting, "CurrencyOfConversion");
	SetConversionAmountHeader();
	
EndProcedure

&AtServer
Procedure MultiplicityOfConversionRateWhenChangingOnServer()

	RecalculateConversionParameters("ConversionRateMultiplier");

EndProcedure

&AtServer
Procedure OnChangeSenderSBankAccount()

	FillInPayerOrganization();

EndProcedure

&AtServer
Procedure ContractFeesOnChangesATServer()
	
	Object.CommissionARAPObject = ?(ValueIsFilled(CommissionAgreement),
		ARAPObjectsServer.GetCalculationObjectFromLink(CommissionAgreement), Catalogs.ARAPObjects.EmptyRef());
	
EndProcedure

&AtServer
Procedure KeepRecordsOfCommissionInMutualSettlementsSwitchOnChangesAtServer()
	
	Object.KeepRecordsOfCommissionInARAPAccounting = KeepRecordsOfCommissionInMutualSettlementsSwitch;
	
	If Not Object.KeepRecordsOfCommissionInARAPAccounting Then
		CommissionAgreement = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
		Object.CommissionARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	EndIf;
	ItemsAndDimensionsSelectionParameters = Documents.BankAccountReceiptNote.ItemsAndDimensionsSelectionParameters(
		Object.BusinessOperation, Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	ConfigureDependentFormElementsOnServer("KeepRecordsOfCommissionInARAPAccounting");
	
EndProcedure

#EndRegion

#Region Properties

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

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsARAPObject.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.ARAPObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.TheCalculationObjectMatchesTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chứng từ này>';
													|ru = '<этот документ>';
													|en = '<this document>'; fa = '<this document>';
													|it = '<questo documento>';
													|pl = '<ten dokument>';
													|tr = '<bu belge>'"));
	
	//ARAPCurrency
	CashServer.SetConditionalAppearanceOfSettlementCurrency(ThisObject);
	
	//Partner
	CashServer.SetPartnerConditionalAppearance(ThisObject);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsARAPDocumentForLease.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ARAPDetails.TypeOfLeasePayment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotInList;
	
	PaymentTypesSettlementDocument = New ValueList;
	PaymentTypesSettlementDocument.Add(Enums.TypesOfLeasePayments.DepositPayment);
	PaymentTypesSettlementDocument.Add(Enums.TypesOfLeasePayments.BuyoutValuePrepayment);
	ItemFilter.RightValue = PaymentTypesSettlementDocument;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<Не требуется>';
													|en = '<Not required>'; fa = '<Not required>';
													|it = '<non richiesto>';
													|pl = '<Nie jest wymagane>';
													|tr = '<Gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	//
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	// The course of settlements
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsExchangeRateNumeratorOfMutualSettlements.Name);
	
	Item.Appearance.SetParameterValue("Text", "");
	
	// Maturity Date
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsMaturityDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ARAPDetails.MaturityDate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tự động>';
													|ru = '<автоматически>';
													|en = '<automatically>'; fa = '<automatically>';
													|it = '<автоматически>';
													|pl = '<automatically>';
													|tr = '<otomatik olarak>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// VATAmount
	CashServer.SetConditionalAppearanceOfVATAmountOfPaymentDecryption(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	UseMultipleCurrencies             = GetFunctionalOption("UseMultipleCurrencies");
	UseIntercompanyContracts = GetFunctionalOption("UseIntercompanyContracts");
	UseCustomerContracts         = GetFunctionalOption("UseCustomerContracts");
	UseContractsWithVendors      = GetFunctionalOption("UseContractsWithVendors");
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ListingListOfAccountablePersons = GetFunctionalOption("UseCashDepositToListEmployees")
										And ValueIsFilled(Object.WithdrawalDocument)
										And TypeOf(Object.WithdrawalDocument) = Type("DocumentRef.BankAccountIssue")
										And Common.ObjectAttributeValue(Object.WithdrawalDocument, "PersonsList");
	
	CurrentBankAccount = Object.BankAccount;
	If ValueIsFilled(Object.Organization) Then
		BranchesOfOrganization.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Object.Organization));
		ThereAreBranches = BranchesOfOrganization.Count() > 0;
	Else
		BranchesOfOrganization.Clear();
	EndIf;
	
	If ValueIsFilled(Object.AcquiringContract) Then
		
		If Object.RecordCommission Then
			If Object.DocumentAmount <> 0 Then
				CommissionRate = CashClientServer.CalculateCommissionRate(
					Object.DocumentAmount, Object.FeeAmount, "Inpayment");
			Else
				CommissionRate = 0;
			EndIf;
			Items.GroupCommission.Title = NStr("vi = 'Phí ngân hàng';
												|ru = 'Комиссия';
												|en = 'Fee'; fa = 'کارمزد';
												|it = 'Commissione';
												|pl = 'Prowizja';
												|tr = 'Komisyon'") +
				" " + String(Object.FeeAmount) + " " + String(Object.Currency) + " " + String(CommissionRate) + "%";
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.CommissionARAPObject) Then
		CommissionAgreement = ContractARAPObjectOfFee(Object.CommissionARAPObject);
	EndIf;
	KeepRecordsOfCommissionInMutualSettlementsSwitch = Object.KeepRecordsOfCommissionInARAPAccounting;
	
	GetDefaultServerPartner(Object.Counterparty, Partner, Object.BusinessOperation);
	GetDefaultContractServer(False);
	
	InitializePaymentDecryption();
	
	FillInPayerOrganization();
	
	FillInListOfBusinessOperations();
	SpecifyListOfBusinessOperations();
	CashServer.GetAvailableBusinessOfOperationsBasedOn(
		Object.DocumentBasis, Enums.PaymentForms.BankAccountPayment, AvailableBaseOfOperations);
	
	SetHeadingIncomeExpenseItem();
	SetConversionAmountHeader();
	UpdateMirrorPaymentLabel();
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("ThereAreBranches");
	FormAttributes.Insert("UseMultipleCurrencies");
	FormAttributes.Insert("UsePayrollTM");
	FormAttributes.Insert("AmountUnallocated");
	FormAttributes.Insert("UseIntercompanyContracts");
	FormAttributes.Insert("UseCustomerContracts");
	FormAttributes.Insert("UseContractsWithVendors");
	FormAttributes.Insert("TheUseOfSparkrazIsAllowed");
	FormAttributes.Insert("ARAPCurrency");
	FormAttributes.Insert("CurrencyOfComplianceAccounting");
	FormAttributes.Insert("ContractRateOption");
	FormAttributes.Insert("ARAPObjectType");
	FormAttributes.Insert("ExchangeRateNumeratorOfMutualSettlements");
	FormAttributes.Insert("ListingListOfAccountablePersons");
	FormAttributes.Insert("ToUseARAPDocumentForLease");
	FormAttributes.Insert("MultipleARAPCurrency");
	FormAttributes.Insert("UIPIsDifferent");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtServer
Procedure InitializePaymentDecryption()
	
	ArrayOfAllProps = New Array; ArrayOfOperationDetails = New Array;
	Documents.BankAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		Object, ArrayOfAllProps, ArrayOfOperationDetails);
	
	If ArrayOfOperationDetails.Find("ARAPDetails") = Undefined Then
		Object.ARAPDetails.Clear();
		DecryptionSwitch = 0;
	Else
		If ArrayOfOperationDetails.Find("ARAPDetails.MaturityDate") = Undefined Then
			For Each DecryptionString In Object.ARAPDetails Do
				DecryptionString.MaturityDate = Date(1 , 1 ,1);
			EndDo;
		EndIf;
		If Object.ARAPDetails.Count() = 0 Then
			NewRow = Object.ARAPDetails.Add();
			Items.ARAPDetails.CurrentRow = NewRow.GetID();
			DecryptionSwitch = 0;
			NewRow.CashFlowItem = Object.CashFlowItem;
			NewRow.Sum = Object.DocumentAmount;
			NewRow.ARAPCurrency = Object.Currency;
			NewRow.ExchangeRateNumeratorOfMutualSettlements = 1;
			NewRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, NewRow, "Object.ARAPDetails");
			CompleteVATTaxation();
		ElsIf Object.ARAPDetails.Count() = 1 Then
			Items.ARAPDetails.CurrentRow = Object.ARAPDetails[0].GetID();
			DecryptionSwitch = 0;
			CompleteVATTaxation(False);
		Else
			DecryptionSwitch = 1;
			CompleteVATTaxation(False);
		EndIf;
		CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, , True);
		FillInParametersOfCalculationObjectInDecryption();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInParametersOfCalculationObjectInDecryption()
	ComplianceOfContractCurrencyExchangeRate = ARAPAccountingServer.ComplianceOfARAPObjectsAndParametersOfContract(
		Object.ARAPDetails.Unload(,"ARAPObject").UnloadColumn("ARAPObject"));
	For Each TSRow In Object.ARAPDetails Do
		TSRow.ContractRateOption = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].ContractRateOption;
		TSRow.ItIsAllowedToWorkWithSubsidiaryPartners = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].ItIsAllowedToWorkWithSubsidiaryPartners;
		TSRow.TheCalculationObjectMatchesTheDocument = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].Object = Object.Ref;
		If ValueIsFilled(TSRow.ARAPObject) Then
			TSRow.ARAPObjectType = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].ARAPObjectType;
		EndIf;
		FillInUIPIndexIsDifferent(TSRow);
	EndDo;
	DefineUIPIsDifferent();
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.BankAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		Object, ArrayOfAllProps, ArrayOfOperationDetails);
	
	If (ArrayOfOperationDetails.Find("ARAPDetails") <> Undefined) Then
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	Else
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	SetPossibleSenderAccountValues(False);
	
	CashServer.SetBankAccountSelectionParameters_(Object, Items.BankAccount);
	CashServer.SetCounterpartySelectionParameters(Object, Items.Counterparty);
	CashServer.SetPartnerSelectionParameters(Object, Items.ARAPDetailsPartner);
	CashServer.SetPartnerSelectionParameters(Object, Items.DecryptionWithoutPartitioningPartner);
	CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.ARAPDetailsLoanDepositContract);
	CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.DecryptionWithoutSplittingTheLoanDepositAgreement, True);
	CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.ARAPDetailsLeaseContracts);
	CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.DecryptionWithoutSplittingTheLeaseAgreement);
	CashServer.SetParametersForSelectingCounterpartySBankAccount(Object, Items.CounterpartyBankAccount);
	CashServer.SetParametersForDebitingFunds(Object, Items.WithdrawalDocument);
	CashServer.SetParametersForSelectingDirectionOfActivity(Object, Items.LineOfBusiness);
	CashServer.SetParametersForSelectingDirectionOfActivity(Object, Items.DirectionOfReturnActivity);
	
	If ArrayOfOperationDetails.Find("Contract") <> Undefined Then
		CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	EndIf;
	
	SetVisibilityOfGiftCertificateSelectionButton();
	
	CashServer.FillInListOfTypesOfAmountsOfLoansDeposits(
		Items.ARAPDetailsLoanAndDepositAmountType.ChoiceList, Object.BusinessOperation);
	CashServer.FillInListOfTypesOfAmountsOfLoansDeposits(
		Items.DecryptionWithoutSplittingTheTypeOfLoanAmountDeposit.ChoiceList, Object.BusinessOperation);
	
	CashServer.SetPaymentAmountHeader(Object.Currency, Items);
	Items.LabelCurrency.Title = String(Object.Currency);
	Items.LabelCurrencyCommission.Title = Items.LabelCurrency.Title;
	
	Items.GroupCommission.Title = NStr("vi = 'Phí ngân hàng';
										|ru = 'Комиссия';
										|en = 'Fee'; fa = 'کارمزد';
										|it = 'Commissione';
										|pl = 'Prowizja';
										|tr = 'Komisyon'") +
		" " + String(Object.FeeAmount) + " " + String(Object.Currency) + " " + String(CommissionRate) + "%";
	
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation(
		ThisObject, "ARAPDetailsPartner", Object.BusinessOperation);
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation(
		ThisObject, "DecryptionWithoutPartitioningPartner", Object.BusinessOperation);
		
	If DecryptionSwitch Then
		Items.ExplanationPages.CurrentPage = Items.ExplanationAsAList;
	Else
		Items.ExplanationPages.CurrentPage = Items.ExplanationWithoutSplit;
	EndIf;
	
	If Not DecryptionSwitch Then
		SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
		If Object.ARAPDetails.Count() > 0
			And ValueIsFilled(Object.ARAPDetails[0].MaturityDate) Then
			MaturityDateWithoutSplitting = Object.ARAPDetails[0].MaturityDate;
		Else
			MaturityDateWithoutSplitting = NStr("vi = '<tự động>';
												|ru = '<автоматически>';
												|en = '<automatically>'; fa = '<automatically>';
												|it = '<автоматически>';
												|pl = '<automatically>';
												|tr = '<otomatik olarak>'");
		EndIf;
	EndIf;
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	DetermineUseOfLeaseSettlementDocument();
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FillInListOfBusinessOperations()
	
	Operations = Enums.BusinessTransactions;
	AvailableTransactions = Items.BusinessOperation.ChoiceList;
	AvailableTransactions.Clear();
	
	AvailableTransactions.Add(Operations.CashReceiptFromCustomer);
	AvailableTransactions.Add(Operations.CashRecieptByAcquiringTransactionsPayment,                NStr("vi = 'Nhận tiền theo thẻ thanh toán';
																										|ru = 'Поступление оплаты по эквайрингу';
																										|en = 'Acquiring payment'; fa = 'پرداخت پذیرندگی';
																										|it = 'Pervenimento del pagamento  per acquiring';
																										|pl = 'Wpływ płatności przez centrum autoryzacyjne';
																										|tr = 'PoS ödemesi'"));
	AvailableTransactions.Add(Operations.CashReceiptFromOtherCompany,    NStr("vi = 'Thu tiền từ một doanh nghiệp khác';
																				|ru = 'Поступление от другой организации';
																				|en = 'Payment from another company'; fa = 'پرداخت از شرکت دیگر';
																				|it = 'Versamento da un''altra azienda';
																				|pl = 'Wpływ od innej firmy';
																				|tr = 'Başka bir iş yerinden ödeme'"));
	AvailableTransactions.Add(Operations.TransferCashBetweenCompanyAndItsBranchOffices,                NStr("vi = 'Chuyển tiền giữa doanh nghiệp và chi nhánh';
																											|ru = 'Передача между организацией и филиалом';
																											|en = 'Transfer between the company and its branch office'; fa = 'انتقال بین شرکت و شعبه آن';
																											|it = 'Trasferimento tra organizzazione e filiale';
																											|pl = 'Transfer między organizacją i filią';
																											|tr = 'İş yerleri ve şubeler arasında transfer'"));
	AvailableTransactions.Add(Operations.CashReceiptFromAnotherAccount,          NStr("vi = 'Thu từ tài khoản khác';
																						|ru = 'Поступление с другого счета';
																						|en = 'Transfer from another account'; fa = 'انتقال از حساب دیگر';
																						|it = 'Entrata da altro conto';
																						|pl = 'Wpływ z innego konta';
																						|tr = 'Diğer hesaptan giriş'"));
	AvailableTransactions.Add(Operations.CashReceiptFromCashRegisterToBankAccount, NStr("vi = 'Chuyển tiền đến ngân hàng';
																						|ru = 'Инкассация в банк';
																						|en = 'Cash deposit to bank'; fa = 'واریز وجه نقد به بانک';
																						|it = 'Incasso in banca';
																						|pl = 'Gromadzenie w banku';
																						|tr = 'bankaya nakit yatırma'"));
	
	If GetFunctionalOption("UseLoanAndDepositContracts") Then
		AvailableTransactions.Add(Operations.CashReceiptFromLoansRepayment,             NStr("vi = 'Thu tiền theo tín dụng và các khoản vay nhận được';
																							|ru = 'Поступление по кредитам и займам полученным';
																							|en = 'Loan repayment'; fa = 'بازپرداخت وام';
																							|it = 'Entrata relativa a crediti e prestiti ottenuti';
																							|pl = 'Wpływ z tytułu otrzymanych kredytów i pożyczek';
																							|tr = 'Alınan kredi ve borçlara ilişkin girişler'"));
		AvailableTransactions.Add(Operations.CashReceiptUnderDeposits,            NStr("vi = 'Thu tiền gửi (deposit)';
																						|ru = 'Поступление по депозитам';
																						|en = 'Deposit interest'; fa = 'سود سپرده';
																						|it = 'Entrata relativa a depositi';
																						|pl = 'Napływ wg depozytów';
																						|tr = 'Mevduatlara göre giriş'"));
		AvailableTransactions.Add(Operations.CashReceiptBorrowingsProvidedToCounterparty,       NStr("vi = 'Đối tác trả khoản vay';
																									|ru = 'Погашение займа контрагентом';
																									|en = 'Loan repayment by counterparty'; fa = 'بازپرداخت وام توسط طرف حساب';
																									|it = 'Rimborso del prestito dal controparte';
																									|pl = 'Spłata pożyczki kontrahentem';
																									|tr = 'Cari hesap borcunun geri ödenmesi'"));
	EndIf;
	
	AvailableTransactions.Add(Operations.LoanRepaymentByEmployee,                        NStr("vi = 'Nhân viên trả khoản vay';
																								|ru = 'Погашение займа сотрудником';
																								|en = 'Loan repayment by employee'; fa = 'بازپرداخت وام توسط کارمند';
																								|it = 'Rimborso del prestito dal dipendente';
																								|pl = 'Spłata pożyczki pracownikiem';
																								|tr = 'Çalışan borcunun geri ödenmesi'"));
	
	AvailableTransactions.Add(Operations.CurrencyConversion);
	AvailableTransactions.Add(Operations.OtherCashReceipt,                 NStr("vi = 'Thu khác';
																				|ru = 'Прочее поступление';
																				|en = 'Other payment'; fa = 'سایر پرداخت‌ها';
																				|it = 'Altri versamenti';
																				|pl = 'Inny napływ';
																				|tr = 'Diğer girişler'"));
	AvailableTransactions.Add(Operations.RefundFromVendor);
	AvailableTransactions.Add(Operations.CashReturnByAdvanceHolder,             NStr("vi = 'Nhận tiền hoàn lại từ người tạm ứng';
																					|ru = 'Возврат от подотчетника';
																					|en = 'Return from advance holder'; fa = 'برگشت از تنخواه‌گردان';
																					|it = 'Restituzione dal responsabile';
																					|pl = 'Zwrot od osoby rozliczającej się za wydatki';
																					|tr = 'Avans sahibinden iade'"));
	AvailableTransactions.Add(Operations.RefundFromAnotherCompany,        NStr("vi = 'Hoàn tiền từ một doanh nghiệp khác';
																				|ru = 'Возврат от другой организации';
																				|en = 'Refund from another company'; fa = 'Refund from another company';
																				|it = 'Restituzione da un'' altra azienda';
																				|pl = 'Zwrot od innej firmy';
																				|tr = 'Diğer iş yerinden iade'"));
	AvailableTransactions.Add(Operations.RefundFromLessor,             NStr("vi = 'Hoàn trả tiền lương chưa áp dụng vào tài khoản cá nhân';
																			|ru = 'Возврат от арендодателя';
																			|en = 'Lessor refund'; fa = 'بازپرداخت موجر';
																			|it = 'Reso da parte del locatore';
																			|pl = 'Zwrot od wynajemcy';
																			|tr = 'Kiraya verenden iade'"));
	AvailableTransactions.Add(Operations.ReturnOfPayrollPaymentByPayrollCardProgram, NStr("vi = 'Trả lại thanh toán chưa được chuyển khoản theo danh sách thanh toán';
																							|ru = 'Возврат неперечисленных по реестру платежей';
																							|en = 'Refund of payments not listed in payment list'; fa = 'بازپرداخت پرداخت‌های غیرفهرست‌شده در لیست پرداخت';
																							|it = 'Возврат неперечисленных по реестру платежей';
																							|pl = 'Refund of payments not listed in payment list';
																							|tr = 'Kayıtta listelenmeyen ödemelerin iadesi'"));
	AvailableTransactions.Add(Operations.TaxRefund);
	
EndProcedure

&AtServer
Procedure SpecifyListOfBusinessOperations()
	
	ItemBusinessOperation = Items.BusinessOperation;
	
	CashServer.EstablishVisibilityOfTransferOperationsBetweenOrganizations(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfInternalTransferOperations(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfTransactionsUnderLoanAndDepositAgreements(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfOperationOtherCashFlow(ItemBusinessOperation);
	CashServer.SetVisibilityOfCurrencyConversionNonCashOperation(ItemBusinessOperation);
	CashServer.SetVisibilityOfSalaryOperation(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfAcquiringOperations(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfOperationsToLoansToEmployees(ItemBusinessOperation);
	CashServer.SetVisibilityOfTransferOperationsToAnotherAccount(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfPaymentToLandlordOperation(ItemBusinessOperation);
EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning()
	
	CashServer.SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInPayerOrganization()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany
	Then
		AttributesStructure1 = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(Object.SenderBankAccount);
		If ValueIsFilled(AttributesStructure1.Organization) Then
			If ValueIsFilled(CompanyPayer)
				And CompanyPayer <> AttributesStructure1.Organization Then
				ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "SenderBankAccount.Owner");
			EndIf;
			CompanyPayer = AttributesStructure1.Organization;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure GetDefaultContractServer(FillInInvoiceUnderAgreement = True)
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.BankAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		Object, ArrayOfAllProps, ArrayOfOperationDetails);
		
	If ArrayOfOperationDetails.Find("ARAPDetails.ARAPObject") = Undefined Then
		Return;
	EndIf;
	
	If AccessRight("Read", Metadata.Catalogs.CounterpartyContracts) Then
		
		ContractBusinessTransaction = New Array;
		If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.SaleToCustomer);
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.RefundFromVendor Then
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.PurchaseByImport);
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.ImportFromEAEU);
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.ConsignmentProcurement);
		EndIf;
		
		CounterpartyContract = CashServer.DefaultContract(
			CounterpartyContract, Partner, Object.Counterparty, Object.Organization, ContractBusinessTransaction);
		
		If FillInInvoiceUnderAgreement Then
			SalesServer.FillInBankAccountsUnderAgreement(CounterpartyContract, , Object.CounterpartyBankAccount);
			If Object.Currency <> Common.ObjectAttributeValue(Object.CounterpartyBankAccount, "CashCurrency") Then
				Object.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
			EndIf;
		EndIf;
		
		If ValueIsFilled(CounterpartyContract) Then
			AccountingInformationUnderAgreement = Catalogs.CounterpartyContracts.AccountingInformationUnderAgreement(CounterpartyContract);
			If ValueIsFilled(AccountingInformationUnderAgreement) Then
				If Not ValueIsFilled(Object.CashFlowItem) Then
					AccountingInformationUnderAgreement.Property("CashFlowItem", Object.CashFlowItem);
				EndIf;
				AccountingInformationUnderAgreement.Property("VATRate", VATRate);
				AccountingInformationUnderAgreement.Property("ARAPCurrency", ARAPCurrency);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure GetDefaultServerPartner(Counterparty, Partner, BusinessOperation)
	
	Partner = CashServer.GetCounterpartyPartner(Counterparty, BusinessOperation);
	
EndProcedure

&AtServer
Procedure SetConversionAmountHeader()
	
	ConversionParameters_SSLy = CashServer.InitializeConversionParameters();
	FillPropertyValues(ConversionParameters_SSLy, Object);
	ConversionParameters_SSLy.CurrencyOfComplianceAccounting = CurrencyOfComplianceAccounting;
	
	CashServer.CurrencyHeadingExchangeRateAndConversionMultiplicity(ThisObject, ConversionParameters_SSLy);
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation(UpdateVATRateAndAmount = True)
	
	CashServer.CompleteVATTaxation(Object, Object.VATTaxation, Items.DecodingWithoutSplittingVATTaxation, Items.DecryptionWithoutDivisionTaxationVATRefund, UpdateVATRateAndAmount);
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	
EndProcedure

&AtServer
Procedure UpdateAllRowsOnServer(LineID)
	
	UpdateTaxRateRecalculateVATAmount(LineID);
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
EndProcedure

&AtServer
Procedure UpdateTaxRateRecalculateVATAmount(LineID)
	
	CashServer.UpdateTaxRateRecalculateVATAmount(Object, LineID);
	
EndProcedure

&AtClient
Procedure UpdatePresentationOfMaturityDate()
	If Object.ARAPDetails.Count() = 0 
		Or Not ValueIsFilled(Object.ARAPDetails[0].MaturityDate) Then
		MaturityDateWithoutSplitting = NStr("vi = '<tự động>';
											|ru = '<автоматически>';
											|en = '<automatically>'; fa = '<automatically>';
											|it = '<автоматически>';
											|pl = '<automatically>';
											|tr = '<otomatik olarak>'");
	Else
		MaturityDateWithoutSplitting = Object.ARAPDetails[0].MaturityDate;
	EndIf;
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateEndOfSelection(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Object.ARAPDetails[0].MaturityDate = Result;
		Modified = True;
	EndIf;
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtServer
Procedure SetRestrictionOnTypeOfPaymentDecryptionContract()

	CashServer.SetRestrictionOnTypeOfPaymentDecryptionContract(ThisObject);
	ConfigureDependentFormElementsOnServer("AmountUnallocated");

EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer()

	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	ClearCalculationObject(CurrentRow);

EndProcedure

&AtServer
Procedure FinancialAccountingGroupOnChangeAtServer()

	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	ClearCalculationObject(CurrentRow);

EndProcedure

&AtServer
Procedure ARAPDetailsPartnerOnChangeAtServer()

	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	ClearCalculationObject(CurrentRow);

EndProcedure

&AtServer
Procedure UpdateAmountUnallocated()

	AmountUnallocated = CashServer.UnallocatedPaymentBalance(Object);
	ConfigureDependentFormElementsOnServer("AmountUnallocated");

EndProcedure

&AtServer
Procedure ProcessIPChange(DecryptionString = Undefined)
	
	If DecryptionString <> Undefined Then
		FillInUIPIndexIsDifferent(DecryptionString);
	Else
		For Each TSRow In Object.ARAPDetails Do
			FillInUIPIndexIsDifferent(TSRow);
		EndDo;
	EndIf;
	
	DefineUIPIsDifferent();
	
EndProcedure

&AtServer
Procedure DefineUIPIsDifferent()
	
	UIPIsDifferent = Object.ARAPDetails.Total("UIPIndexIsDifferent") <> 0;
	ConfigureDependentFormElementsOnServer("UIPIsDifferent");
	
EndProcedure

&AtServer
Procedure FillInUIPIndexIsDifferent(DecryptionString)
	
	If ValueIsFilled(Object.PaymentID)
		And ValueIsFilled(DecryptionString.PaymentID)
		And DecryptionString.PaymentID <> Object.PaymentID Then
		DecryptionString.UIPIndexIsDifferent = 1;
	Else
		DecryptionString.UIPIndexIsDifferent = 0;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServerNoContext
Function GetBankAccountDetails(BankAccount)
	
	Return Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
	
EndFunction

&AtServer
Procedure UpdateMirrorPaymentLabel()
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.CashReceiptFromOtherCompany Then
		Return;
	EndIf;
	
	InvertedPaymentReference = Documents.BankAccountReceiptNote.FindMirrorPayment(Object.Ref);
	
	If ValueIsFilled(InvertedPaymentReference) Then
		Items.LabelInvertedPayment.Hyperlink = True;
		CorrespondsToInvertedPayment = Documents.BankAccountReceiptNote.CorrespondsToInvertedPayment(
			Object.Ref,InvertedPaymentReference);
		If CorrespondsToInvertedPayment Then
			Items.LabelInvertedPayment.TextColor = StyleColors.HyperlinkColor;
			LabelInvertedPayment = InvertedPaymentReference;
		Else
			Items.LabelInvertedPayment.TextColor = StyleColors.TextColorWarning;
			LabelInvertedPayment = StrTemplate(NStr("vi = '%1 (có sự khác biệt)';
													|ru = '%1 (есть различия)';
													|en = '%1 (there are differences)'; fa = '%1 (there are differences)';
													|it = '%1 (ci sono differenze)';
													|pl = '%1 (są różnice)';
													|tr = '%1 (farklılıklar bulunuyor)'"), InvertedPaymentReference);
		EndIf;
	Else
		Items.LabelInvertedPayment.TextColor = StyleColors.TextColorWarning; 
		Items.LabelInvertedPayment.Hyperlink = False;
		LabelInvertedPayment = NStr("vi = '<Không tìm thấy chi tiền mặt.>';
									|ru = '<Списание безналичных денежных средств не найдено.>';
									|en = '<""Outgoing payment — Bank account"" is not found.>'; fa = '<""Outgoing payment — Bank account"" is not found.>';
									|it = '<Storno dei mezzi monetari cashless non è stato trovato.>';
									|pl = '<Nie znaleziono wyksięgowania bezgotówkowych środków pieniężnych.>';
									|tr = '<Giden ödeme- banka hesabı bulunamadı.>'");
	EndIf;
	
EndProcedure

&AtClient
Procedure AlignMirrorPaymentCompletion(QuestionResult, InvertedPaymentOffsetBetweenCompanies) Export
	
	ResponseCode = QuestionResult;
	If ResponseCode = DialogReturnCode.Yes Then
		AlignMirrorPaymentOnServer();
	Else
		UpdateMirrorPaymentLabel();
	EndIf;
	
EndProcedure

&AtServer
Procedure AlignMirrorPaymentOnServer()
	
	MirrorPaymentObject = InvertedPaymentReference.GetObject();
	Success = Documents.BankAccountReceiptNote.AlignMirrorPayment(Object.Ref, MirrorPaymentObject);
	
	If Success Then
		Try
			MirrorPaymentObject.Write(?(MirrorPaymentObject.Posted, DocumentWriteMode.Posting, DocumentWriteMode.Write));
			UpdateMirrorPaymentLabel();
		Except
			WriteLogEvent(
				NStr("vi = 'Việc nhận tiền không dùng tiền mặt, một sự thay đổi gương trong chứng từ liên quan.';
					|ru = 'Поступление безналичных денежных средств, зеркальное изменение связанного документа.';
					|en = 'Incoming payment — Bank account, inverted change of the linked document.'; fa = 'Incoming payment — Bank account, inverted change of the linked document.';
					|it = 'Entrata dei mezzi monetari cashless, cambiamento speculare del documento associato.';
					|pl = 'Wpływ bezgotówkowych środków pieniężnych, zmiana lustrzana powiązanego dokumentu.';
					|tr = 'Gelen ödeme - banka hesabı, ilgili belgenin yansıtma değişimi'",
					CommonClientServer.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPossibleSenderAccountValues(ChangeSenderInvoice = True)
	
	Query = New Query("
	|SELECT ALLOWED
	|	BankAccounts.Ref AS Ref
	|FROM
	|	Catalog.CompaniesBankAccounts AS BankAccounts
	|
	|WHERE
	|	(BankAccounts.CashCurrency = &Currency OR NOT &SelectByCurrency)
	|	AND (BankAccounts.Owner IN (&Owner) OR NOT &SelectByOwner)
	|	AND BankAccounts.Owner NOT IN (&OwnerFilter_)
	|	AND BankAccounts.Ref <> &BankAccount
	|");
	
	Query.SetParameter("BankAccount", Object.BankAccount);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		And ValueIsFilled(Object.CurrencyOfConversion) Then
		
		Query.SetParameter("Currency", Object.CurrencyOfConversion);
		Query.SetParameter("SelectByCurrency", True);
	Else
		Query.SetParameter("Currency", Undefined);
		Query.SetParameter("SelectByCurrency", False);
	EndIf;
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherAccount
		Or Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion)
		And ValueIsFilled(Object.BankAccount)
		And ValueIsFilled(Object.Organization) Then
		
		Query.SetParameter("Owner", Object.Organization);
		Query.SetParameter("SelectByOwner", True);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		ArrayOfInterconnectedOrganizations = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Object.Organization);
		Query.SetParameter("Owner", ArrayOfInterconnectedOrganizations);
		Query.SetParameter("SelectByOwner", True);
	Else
		
		Query.SetParameter("Owner", Undefined);
		Query.SetParameter("SelectByOwner", False);
	EndIf;
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany)
		And ValueIsFilled(Object.BankAccount)
		And ValueIsFilled(Object.Organization) Then
		
		ArrayOfInterconnectedOrganizations = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Object.Organization);
		ArrayOfInterconnectedOrganizations.Add(Object.Organization);
		Query.SetParameter("OwnerFilter_", ArrayOfInterconnectedOrganizations);
		
	Else
		Query.SetParameter("OwnerFilter_", Undefined);
	EndIf;
	
	ArrayOfAccounts_ = Query.Execute().Unload().UnloadColumn("Ref");
	Items.SenderBankAccount.ChoiceList.LoadValues(ArrayOfAccounts_);
	
	If ChangeSenderInvoice Then
		If ArrayOfAccounts_.Count() = 1 Then
			
			Object.SenderBankAccount = ArrayOfAccounts_[0];
			OnChangeSenderSBankAccount();
			
		ElsIf ValueIsFilled(Object.SenderBankAccount)
			And ArrayOfAccounts_.Find(Object.SenderBankAccount) = Undefined Then
			
			Object.SenderBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			OnChangeSenderSBankAccount();
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetHeadingIncomeExpenseItem()
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		Items.DecodingWithoutSplittingTheIncomeItem.Title = NStr("vi = 'Dạng thu nhập';
																|ru = 'Статья доходов';
																|en = 'Income item'; fa = 'قلم درآمد';
																|it = 'Voce dei ricavi';
																|pl = 'Rodzaj przychodów';
																|tr = 'Gelir kalemi'");
		Items.ARAPDetailsIncomeItem.Title      = NStr("vi = 'Dạng thu nhập';
														|ru = 'Статья доходов';
														|en = 'Income item'; fa = 'قلم درآمد';
														|it = 'Voce dei ricavi';
														|pl = 'Rodzaj przychodów';
														|tr = 'Gelir kalemi'");
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateHyperlinkCaptionPaymentObjectDetails()
	CashServer.GenerateHyperlinkCaptionPaymentObjectDetails(ThisForm, Object, True);
EndProcedure

&AtServer
Function PlaceDecryptionInTemporaryStorage()
	Return PutToTempStorage(Object.ARAPDetails.Unload());
EndFunction

&AtServer
Procedure RecalculateConversionParameters(Var_AttributeName)
	
	CashServer.RecalculateConversionParameters(Object, CurrencyOfComplianceAccounting, Var_AttributeName);
	
EndProcedure

&AtServer
Function AccountCorrespondsToOwner()
	
	Result = True;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder
		Or Object.BusinessOperation = Enums.BusinessTransactions.LoanRepaymentByEmployee Then
		
		Result = Catalogs.CounterpartyBankAccounts.VerifyBankAccountHolder(
			Object.CounterpartyBankAccount, Object.AdvanceHolder);
	Else
		Result = Catalogs.CounterpartyBankAccounts.VerifyBankAccountHolder(
			Object.CounterpartyBankAccount, Object.Counterparty);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure BlockData_()
	LockDataForEdit(Object.Ref,,ThisForm.UUID);
EndProcedure

&AtServer
Procedure UnlockData()
	UnlockDataForEdit(,ThisForm.UUID);
EndProcedure

&AtServer
Procedure FillInCurrencyOfMutualSettlementsOfDocument()
	
	CashServer.FillInCurrencyOfMutualSettlementsOfDocument(ThisForm);
	CurrencyDecorationAndPaymentRate = CashServer.CurrencyLabelAndPaymentRate(ThisObject);
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FillInCourseCourseDenominatorOfSettlements()
	
	For Each TSRow In Object.ARAPDetails Do
		FillInCourseAndMultiplicityInDecryptionLine(TSRow);
	EndDo;
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
EndProcedure

&AtServer
Procedure FillMultiplicityCourseWithText()
	
	CalculationColumns = "TheExchangeRateIsTheDenominatorOfMutualSettlements, ExchangeRateNumeratorOfMutualSettlements, ARAPCurrency";
	SettlementData = Object.ARAPDetails.Unload(, CalculationColumns);
	SettlementData.GroupBy(CalculationColumns);
	SettlementData.Columns.Add("CourseDenominatorOfMutualSettlementsInscription", New TypeDescription("String"));
	SettlementData.Columns.Add("CourseNumeratorOfMutualSettlementsText", New TypeDescription("String"));
	
	For Each TSRow In SettlementData Do
		
		CashServer.FormCourseDenominatorByText(TSRow, Object.Currency, CurrencyOfComplianceAccounting);
		
		FilterParameters = New Structure(CalculationColumns);
		FillPropertyValues(FilterParameters, TSRow);
		FoundRows = Object.ARAPDetails.FindRows(FilterParameters);
		
		For Each TableRow In FoundRows Do
			FillPropertyValues(TableRow, TSRow, "CourseDenominatorOfMutualSettlementsInscription, CourseNumeratorOfMutualSettlementsText");
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateAmountOfSettlements_()
	
	For Each TSRow In Object.ARAPDetails Do
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			TSRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfGiftCertificateSelectionButton()
	Var SaleOfGiftCertificateIsAllowed;
	SaleOfGiftCertificateIsAllowed =
		RetailSalesLocalization.ItIsAllowedToSellGiftCertificateInDocument(Object.BusinessOperation);
	Items.ARAPDetailsPickUpGiftCertificate.Visible = SaleOfGiftCertificateIsAllowed;
EndProcedure

&AtServer
Procedure ProcessGiftCertificate(GiftCertificate)
	
	FoundRow = GiftCertificatesServer.AddGiftCertificateToTablePartOfPaymentDecryption(GiftCertificate, ThisObject);
	If FoundRow <> Undefined Then
		
		Modified = True;
		
		UpdateAllRowsOnServer(FoundRow.GetID());
		
		SetRestrictionOnTypeOfPaymentDecryptionContract();
		GenerateHyperlinkCaptionPaymentObjectDetails();
		SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
		
		FillInCourseAndMultiplicityInDecryptionLine(FoundRow);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			FoundRow, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(FoundRow, Object.Currency, CurrencyOfComplianceAccounting);
		FillInCurrencyOfMutualSettlementsOfDocument();
		CashServer.SetDesignAccuracyOfCourse(ThisObject);
		
		ConfigureDependentFormElementsOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfirmationOfSalaryTransferWhenChangeIsMadeOnServer()
	
	Object.WithdrawalDocument = Undefined;
	Object.DocumentAmount = 0;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BankConfirmationAboutCashReceiptOnEmployeeAccount.SourceDocument AS SourceDocument,
	|	SUM(BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.Sum) AS Sum
	|FROM
	|	Document.BankConfirmationAboutCashReceiptOnEmployeeAccount AS BankConfirmationAboutCashReceiptOnEmployeeAccount
	|		INNER JOIN Document.BankConfirmationAboutCashReceiptOnEmployeeAccount.EmployeesHR AS BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR
	|		ON BankConfirmationAboutCashReceiptOnEmployeeAccount.Ref = BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.Ref
	|WHERE
	|	BankConfirmationAboutCashReceiptOnEmployeeAccount.Ref = &Ref
	|	AND BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.SalaryCreditingResult <> VALUE(Enum.SalaryCreditingResults.Credited)
	|
	|GROUP BY
	|	BankConfirmationAboutCashReceiptOnEmployeeAccount.SourceDocument";
	
	Query.SetParameter("Ref", Object.BankConfirmationAboutCashReceiptOnEmployeeAccount);
	
	Result = Query.Execute().Select();
	
	If Result.Next() Then
		
		Object.WithdrawalDocument = Result.SourceDocument;
		Object.DocumentAmount = Result.Sum;
		
		DataOfIssuingDocument = Common.ObjectAttributesValues(Object.WithdrawalDocument, "Counterparty, CounterpartyBankAccount");
		Object.Counterparty = DataOfIssuingDocument.Counterparty;
		Object.CounterpartyBankAccount = DataOfIssuingDocument.CounterpartyBankAccount;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WithdrawalDocumentOnChangeServer()
	
	BankAccountSavedValue = Object.BankAccount;
	HeldByBankSavedValue = Object.ProcessedByBank;
	
	If ValueIsFilled(Object.WithdrawalDocument) Then
		DocumentObject = FormAttributeToValue("Object");
		DocumentObject.Fill(Object.WithdrawalDocument);
		ValueToFormAttribute(DocumentObject, "Object");
	EndIf;
	
	If Not ValueIsFilled(Object.BankAccount) Then
		Object.BankAccount = BankAccountSavedValue;
	EndIf;
	
	If Not Object.ProcessedByBank Then	
		Object.ProcessedByBank = HeldByBankSavedValue;
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.UnremittedSalaryReturnToPersonalAccounts Then
		Object.DocumentAmount = Common.ObjectAttributeValue(Object.WithdrawalDocument, "DocumentAmount");
	EndIf;
	
	If Object.ARAPDetails.Count() = 1 Then
		Object.ARAPDetails[0].Sum = Object.DocumentAmount;
	EndIf;
	
EndProcedure

&AtServer
Function TakeIntoAccountTypeOfLoanAmountDeposit(AmountType)

	Return (Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
		And ValueIsFilled(AmountType);

EndFunction

&AtServer
Procedure YouAreAllowedToWorkWithAffiliatedPartners(TableRow)
	
	ReferencesArrray = CommonClientServer.ValueInArray(TableRow.ARAPObject);
	ComplianceOfContractCurrencyExchangeRate = ARAPAccountingServer.ComplianceOfARAPObjectsAndParametersOfContract(ReferencesArrray);
	TableRow.ItIsAllowedToWorkWithSubsidiaryPartners = ComplianceOfContractCurrencyExchangeRate[TableRow.ARAPObject].ItIsAllowedToWorkWithSubsidiaryPartners;
	TableRow.TheCalculationObjectMatchesTheDocument = ComplianceOfContractCurrencyExchangeRate[TableRow.ARAPObject].Object = Object.Ref;
	
EndProcedure

&AtServer
Procedure ClearCalculationObject(DecryptionString)

	CashServer.ClearCalculationObject(Object, DecryptionString);
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();

EndProcedure

&AtServer
Procedure FillInPaymentDecryptionLineUnderContract(DecryptionString, ContractDetails_)

	FillPropertyValues(DecryptionString, ContractDetails_);
	DecryptionString.Contract = Object.Contract;
	
	FillInCourseAndMultiplicityInDecryptionLine(DecryptionString);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);

EndProcedure

&AtServer
Procedure DetermineUseOfLeaseSettlementDocument()

	FilterDepositPayment = New Structure;
	FilterDepositPayment.Insert("TypeOfLeasePayment", Enums.TypesOfLeasePayments.DepositPayment);
	HasSecurityDeposit = Object.ARAPDetails.FindRows(FilterDepositPayment).Count() > 0;
	
	FilterBuyoutValuePrepayment = New Structure;
	FilterBuyoutValuePrepayment.Insert("TypeOfLeasePayment", Enums.TypesOfLeasePayments.BuyoutValuePrepayment);
	ThereIsRedemptionCostAdvance = Object.ARAPDetails.FindRows(FilterBuyoutValuePrepayment).Count() > 0;
	
	ToUseARAPDocumentForLease = HasSecurityDeposit Or ThereIsRedemptionCostAdvance;
	
	ConfigureDependentFormElementsOnServer("ToUseARAPDocumentForLease");
	
EndProcedure

// The Contract of the fee settlement object.
// 
// Parameters:
//  ARAPObject - CatalogRef.ARAPObjects
// 
// Returns:
//  CatalogRef.CounterpartyContracts
//
&AtServerNoContext
Function ContractARAPObjectOfFee(Val ARAPObject)

	Return Common.ObjectAttributeValue(ARAPObject, "Contract");
	
EndFunction

&AtServer
Procedure FillInContractFeeSVObjectOfSettlementARAPObject()
	
	If Not ValueIsFilled(Object.Organization)
		Or Not ValueIsFilled(Object.Counterparty)
		Or Not ValueIsFilled(Object.Currency) Then
		CommissionAgreement = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;

	If ValueIsFilled(CommissionAgreement) Then
		
		ContractDetails_ = Common.ObjectAttributesValues(CommissionAgreement,
			"Organization, Counterparty, ARAPCurrency");
		
		Clear_Contract = (Object.Organization <> ContractDetails_.Organization
			Or Object.Counterparty <> ContractDetails_.Counterparty
			Or Object.Currency <> ContractDetails_.ARAPCurrency);
		
		If Clear_Contract Then
			CommissionAgreement = Catalogs.CounterpartyContracts.EmptyRef();
		EndIf;
	EndIf;

	Object.CommissionARAPObject = ?(ValueIsFilled(CommissionAgreement),
		ARAPObjectsServer.GetCalculationObjectFromLink(CommissionAgreement), Catalogs.ARAPObjects.EmptyRef());

EndProcedure

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
	ElsIf Item.Name = "sh_ShamsiInput_BankPostingDate" Then
		BankPostingDateOnChange(Items.BankPostingDate);
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
