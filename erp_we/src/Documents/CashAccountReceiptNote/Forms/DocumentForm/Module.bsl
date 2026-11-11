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
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.CashAccountReceiptNote.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	//Setting up accounting accounts	
	SetupParameters = Documents.CashAccountReceiptNote.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		If Parameters.Property("Basis") Then
			ExcludedTypesWhenFillingInAttributes = New Array;
			ExcludedTypesWhenFillingInAttributes.Add(Type("Structure"));
			ExcludedTypesWhenFillingInAttributes.Add(Type("CatalogRef.GiftCertificates"));
			If ValueIsFilled(Parameters.Basis) And ExcludedTypesWhenFillingInAttributes.Find(TypeOf(Parameters.Basis)) = Undefined Then
				Object.Application = TMCommonUse.GetDocumentPresentation(Parameters.Basis,
					ObjectsPrefixesClientServer.NumberForPrinting(Parameters.Basis.Number),
					Parameters.Basis.Date);
			EndIf;
			Basis = Parameters.Basis;
			Parameters.Property("IssuedLetterOfAuthority", Object.IssuedLetterOfAuthority);
		EndIf;
		
		If ValueIsFilled(Object.CashRegister) Then
			CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
			AccessRights = SalesSettingsForUsersServer.CWPAccessRights(Users.CurrentUser());
		EndIf;
		CashServer.CheckFillOutContract(Object);
	EndIf;
	
	Items.DecryptionWithoutSplittingRepaymentDate.ReadOnly = Not AccessRight(
		"Edit",
		Metadata.Documents.CashAccountReceiptNote.TabularSections.ARAPDetails.Attributes.MaturityDate);
	
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
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.CashAccountIssuer.ChoiceButton = True;
	EndIf;

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
	// End StandardSubsystems.AttachableCommands

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
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.CashAccountReceiptNote.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.CashAccountReceiptNote.AccountingAccountSettings_(Object.BusinessOperation);
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
	
	If Object.DocumentAmount = 0 Then
		Object.DocumentAmount = Object.ARAPDetails.Total("Sum");
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		FinancesClient.RecalculateAmountOfDocumentBasedOnPaymentDecryption(
			ThisForm,
			New CallbackDescription("BeforeRecordingOfferToRecalculateAmountOfDocument", ThisObject, AdditionalParameters));
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToRecalculateAmountOfDocument(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult Then
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_CashAccountReceiptNote", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
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
	
	//Setting up accounting accounts
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	FillInParametersOfCalculationObjectInDecryption();
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CompleteVATTaxation(False);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	
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
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	If Not DecryptionSwitch Then
		DocumentObject = FormAttributeToValue("Object");
		DocumentObject.AdditionalProperties.Insert("ExplanationWithoutSplit", True);
		
		If Not DocumentObject.CheckFilling() Then
			Cancel = True;
		EndIf;
		
		CheckedAttributes.Clear();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	CompleteVATTaxation();
	
	FillInCourseCourseDenominatorOfSettlements();
	CalculateAmountOfSettlements_();
	FillMultiplicityCourseWithText();
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
	UpdatePresentationOfMaturityDate();
	
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
	
	SetPossibleValuesForSenderSCashRegister();
	
	CFItemByBT = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Object.BusinessOperation);
	Object.CashFlowItem = CFItemByBT;
	For Each PaymentDecryptionString In Object.ARAPDetails Do
		PaymentDecryptionString.CashFlowItem = CFItemByBT;
	EndDo;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		And Not Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Object.Organization) Then
		
		Object.CashAccount = Undefined;
		Object.Organization = Undefined;
		CurrentCashAccount = Object.CashAccount;
		CurrencyOfComplianceAccounting = Undefined;
	EndIf;
	
	ArrayOfAllProps = New Array; ArrayOfOperationDetails = New Array;
	Documents.CashAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails);
	If ArrayOfOperationDetails.Find("Counterparty") = Undefined Then
		Object.Counterparty = Undefined;
		Object.Contract = Undefined;
		For Each CurDecryptionString In Object.ARAPDetails Do
			CurDecryptionString.PaymentPurpose = Undefined;
			CurDecryptionString.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(Object.Counterparty) Then
		ClearAdditionalReceiptInformation();
	EndIf;
	
	//Setting up accounting accounts
	AccountingAccountSettings_ = Documents.CashAccountReceiptNote.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, AccountingAccountSettings_);
	ItemsAndDimensionsSelectionParameters = Documents.CashAccountReceiptNote.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank)
		And Not ValueIsFilled(Object.BankAccount) Then
		
		GetDefaultBankAccount();
		If Not ValueIsFilled(Object.BankAccount) And Not GetFunctionalOption("UseMultipleBankAccounts") Then
			Raise NStr("vi = 'Không thể điền trường ""Tài khoản ngân hàng"". Có thể là trong cơ sở thông tin chưa nhập tài khoản ngân hàng nào của doanh nghiệp!';
						|ru = 'Не удалось заполнить поле ""Банковский счет"". Возможно, в информационной базе не введено ни одного банковского счета организации!';
						|en = 'Cannot fill in field ""Bank account"". Possibly no bank accounts of the company are entered into the infobase.'; fa = 'Cannot fill in field ""Bank account"". Possibly no bank accounts of the company are entered into the infobase.';
						|it = 'Non è stato possibile compilare il campo ""Conto bancario"". Probabilmente nel database informatico non è stato immesso nessun conto bancario della società!';
						|pl = 'Nie udało się wypełnić pola ""Банковский счет"". Możliwe, że do bazy informacyjnej nie wprowadzono ani jednego rachunku bankowego firmy!';
						|tr = '""Banka hesabı"" alanı doldurulamadı. Infobase''e iş yerine ait bir banka hesabı girilmemiş olabilir!'");
		EndIf;
	EndIf;
	
	GetDefaultContractServer();
	Object.LineOfBusiness = CashServer.LineOfBusiness(
		Object.BusinessOperation,
		Object.LineOfBusiness);
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	CompleteVATTaxation();
	FormItemsManagement();
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure CashAccountOnChange(Item)
	
	PropsStructures = DetailsOfCashRegisterAndCashRegister(Object.CashAccount, Object.CashRegister);
	StructureOfCashRegisterDetails = PropsStructures.CashRegisterAttributes;
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = StructureOfCashRegisterDetails.Currency;
	EndIf;
	
	If Not FinancesClient.CurrencyConversionRequired(Object, Object.Currency, StructureOfCashRegisterDetails.Currency) Then
		
		If Object.Currency <> StructureOfCashRegisterDetails.Currency Then
			FinancesClient.ClearAmountAndCurrencyOfSettlementsPaymentDecryption(Object);
		EndIf;
		CashAccountOnChangeServer(StructureOfCashRegisterDetails, False);
		
	Else
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tính lại số tiền trong chứng từ theo tiền tệ %1?';
				|ru = 'Пересчитать суммы в документе в валюту %1?';
				|en = 'Convert amounts in the document in %1?'; fa = 'Convert amounts in the document in %1?';
				|it = 'Ricalcolare gli importi del documento in valuta %1?';
				|pl = 'Przeliczyć kwoty w dokumencie na walutę %1?';
				|tr = 'Belgedeki tutarlar %1 para birimine göre yeniden hesaplansın mı?'"),
			StructureOfCashRegisterDetails.Currency);
		
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
			"CurrencyConversionAllowed", ThisObject, New Structure("PropsStructures", PropsStructures));
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogButtons);
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyConversionAllowed(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CurrentCurrency = Object.Currency;
		CashAccountOnChangeServer(AdditionalParameters.PropsStructures.CashRegisterAttributes, True);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(CurrentCurrency, Object.Currency);
	Else
		Object.CashAccount = CurrentCashAccount;
	EndIf;
	
EndProcedure

&AtServer
Procedure CashAccountOnChangeServer(AttributesStructure1, AmountsRecalculate)
	
	OrganizationChanged_ = (Object.Organization <> AttributesStructure1.Organization);
	CurrencyChanged_1 = (Object.Currency <> AttributesStructure1.Currency);
	
	CurrentCurrency        = Object.Currency;
	Object.Currency        = AttributesStructure1.Currency;
	Object.Organization   = AttributesStructure1.Organization;
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	AttributesArray = New Array;
	If OrganizationChanged_ Then
		AttributesArray.Add("Organization");
	EndIf;
	If CurrencyChanged_1 Then
		AttributesArray.Add("Currency");
	EndIf;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	If ValueIsFilled(Object.CashAccount) Then
		
		If ValueIsFilled(CurrentCurrency) And CurrencyChanged_1 Then
			
			Object.CashAccountIssuer                    = Catalogs.CashAccounts.EmptyRef();
			Object.BankAccount                      = Catalogs.CompaniesBankAccounts.EmptyRef();
			Object.CashRegister                            = Catalogs.CashRegisters.EmptyRef();
			
			If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
				CurrencyOfConversionOnChangeServer();
			EndIf;
		EndIf;
		
		GetDefaultContractServer();
		
		If OrganizationChanged_ Then
			Object.CashRegister = Catalogs.CashRegisters.EmptyRef();
			BranchesOfOrganization.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Object.Organization));
			ThereAreBranches = BranchesOfOrganization.Count() > 0;
			
			If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCashRegister Then
				Object.CashRegister = Catalogs.CashRegisters.CashRegisterByDefault(Object.Organization);
			EndIf;
			
			If ValueIsFilled(CounterpartyContract) Then
				PaymentType_ = ?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromVendor")
							Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany"),
					PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting"),
					PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"));
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
			
			CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
			
			CompleteVATTaxation();
			
			StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
			BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
			
			CashServer.FillInResponsiblePersonsOfCompany(Object);
			
		EndIf;
	Else
		BranchesOfOrganization.Clear();
	EndIf;
	
	If AmountsRecalculate Then
		CashServer.ConversionOfDocumentAmountsIntoCurrency(Object, CurrentCurrency, Object.Currency);
		
		VATConversionParameters = New Structure("PriceIncludesVAT", True);
		StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
		BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	EndIf;
	
	For Each TSRow In Object.ARAPDetails Do
		If CurrencyChanged_1 Then
			If Not ValueIsFilled(TSRow.ARAPObject)
				And Not ValueIsFilled(Object.Contract) Then
				TSRow.AmountARAP = TSRow.Sum;
				TSRow.ARAPCurrency = Object.Currency;
				TSRow.ExchangeRateNumeratorOfMutualSettlements = 1;
				TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
			EndIf;
			CashServer.CalculateExchangeRateNumeratorOfMutualSettlementsInDecryptionLine(TSRow, Object.Currency, CurrencyOfComplianceAccounting);
			CalculateAmountOfSettlements_();
		EndIf;
	EndDo;
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	If CurrencyChanged_1 Then
		CashServer.SetPaymentAmountHeader(Object.Currency, Items);
		Items.LabelCurrency.Title = String(Object.Currency);
		UpdateAmountUnallocated();
		GenerateHyperlinkCaptionPaymentObjectDetails();
	EndIf;
	
	SetPossibleValuesForSenderSCashRegister();
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank)
		And Not ValueIsFilled(Object.BankAccount) Then
		
		GetDefaultBankAccount();
	EndIf;
	
	FillInCashier();
	
	FormItemsManagement();
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	CurrentCashAccount = Object.CashAccount;
	
EndProcedure

&AtClient
Procedure DocumentAmountOnChange(Item)
	
	If DocumentAmountOnChangeClient() Then
		DocumentAmountOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
	If ValueIsFilled(Object.Counterparty) Then
	
		If CurrentCounterparty <> Object.Counterparty Then
			ClearAdditionalReceiptInformation();
		EndIf;
		
		If Not ValueIsFilled(Object.ReceivedFrom) Then
			
			CounterpartyData = New Structure();
			PrintFormGeneration.FillInInformationAboutLegalEntity(CounterpartyData, Object.Counterparty, Object.Date);
			Object.ReceivedFrom = CounterpartyData.Presentation;
			
		EndIf;
		
		Partner = CashServer.GetCounterpartyPartner(Object.Counterparty, Object.BusinessOperation);
		GetDefaultContractServer();
		
		If ValueIsFilled(CounterpartyContract) Then
			PaymentType_ = ?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromVendor")
							Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany"),
				PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting"),
				PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"));
			ARAPObjectContract = ARAPObjectsServer.GetCalculationObjectFromLink(CounterpartyContract,,PaymentType_);
		EndIf;
		
		For Each TSRow In Object.ARAPDetails Do
			TSRow.Partner = Partner;
			If ValueIsFilled(CounterpartyContract) Then
				TSRow.PaymentPurpose = CounterpartyContract;
				TSRow.ARAPObject = ARAPObjectContract;
				TSRow.CashFlowItem = Object.CashFlowItem;
				TSRow.VATRate = VATRate;
				TSRow.ARAPCurrency = ARAPCurrency;
				FillInCourseAndMultiplicityInDecryptionLine(TSRow);
				CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
					TSRow, Object.Currency, CurrencyOfComplianceAccounting);
				CashServer.FormCourseDenominatorByText(TSRow, Object.Currency, CurrencyOfComplianceAccounting);
				FillInCurrencyOfMutualSettlementsOfDocument();
			EndIf;
		EndDo;
		
		CashServer.SetDesignAccuracyOfCourse(ThisObject);
		CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
		
		StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
		BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
		
		CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.ARAPDetailsLoanDepositContract);
		CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.DecryptionWithoutSplittingTheLoanDepositAgreement);
		CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.ARAPDetailsLeaseContracts);
		CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.DecryptionWithoutSplittingTheLeaseAgreement);
	Else
		ClearAdditionalReceiptInformation();
	EndIf;
	
	SetVisibilityOfGiftCertificateSelectionButton();
	
	If Not DecryptionSwitch Then
		SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	EndIf;
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure AdvanceHolderOnChange(Item)
	
	AdvanceHolderOnChangeServer();
	
EndProcedure

&AtServer
Procedure AdvanceHolderOnChangeServer()
	
	If ValueIsFilled(Object.AdvanceHolder) Then
		Object.ReceivedFrom = Common.ObjectAttributeValue(Object.AdvanceHolder, "Description");
	Else
		ClearAdditionalReceiptInformation();
	EndIf;
	
EndProcedure

&AtClient
Procedure CashRegisterOnChange(Item)
	
	CashRegisterOnChangeServer()
	
EndProcedure

&AtServer
Procedure CashRegisterOnChangeServer()
	
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	AccessRights = SalesSettingsForUsersServer.CWPAccessRights(Users.CurrentUser());
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CashTransferReferenceOrderOnChange(Item)
	
	If ValueIsFilled(Object.CashTransferReferenceOrder) Then
		CashTransferReferenceOrderOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CashTransferReferenceOrderOnChangeServer()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(Object.CashTransferReferenceOrder);
	ValueToFormAttribute(DocumentObject, "Object");
	
EndProcedure

&AtClient
Procedure CurrencyOfConversionOnChange(Item)
	
	CurrencyOfConversionOnChangeServer();
	
EndProcedure

&AtClient
Procedure CashAccountIssuerOnChange(Item)
	
	CashAccountIssuerOnChangeServer();
	
EndProcedure

&AtServer
Procedure CashAccountIssuerOnChangeServer()
	
	SourceCompanyPayer = CompanyPayer;
	
	FillInPayerOrganization();
	
	If Not ValueIsFilled(Object.CashAccountIssuer)
		And CompanyPayer <> SourceCompanyPayer Then
		ClearAdditionalReceiptInformation();
	EndIf;
	
	CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	
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
	
	FormParameters.Insert("FinancialAccountingGroup",  Object.FinancialAccountingGroup);
	FormParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	FormParameters.Insert("Contract",                 Object.Contract);
	FormParameters.Insert("Organization",             Object.Organization);
	FormParameters.Insert("Department",           Object.Department);
	FormParameters.Insert("VATTaxation",      Object.VATTaxation);
	FormParameters.Insert("ListOfVATTaxes",Items.DecodingWithoutSplittingVATTaxation.ChoiceList);
	FormParameters.Insert("DocumentRef",          Object.Ref);
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
	ThereIsChangeInVATTaxation = ?(Object.VATTaxation = Result.VATTaxation, False, True);
	HyperlinkDetailsOfSettlementObjectClickEndOnServer();
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
		ARAPDetailsARAPObjectOnChangeServer(DecryptionString.GetID());
		
		FillInCourseAndMultiplicityInDecryptionLine(DecryptionString);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
		YouAreAllowedToWorkWithAffiliatedPartners(DecryptionString);
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
Procedure SettlementObjectContractStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("DeletionMark", False);
	
	If ValueIsFilled(Items.ARAPDetails.CurrentData.ARAPCurrency) Then
		FilterStructure1.Insert("ARAPCurrency", Items.ARAPDetails.CurrentData.ARAPCurrency);
	EndIf;
	
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
Procedure ReturnAgreementCreating(Item, StandardProcessing)

	StandardProcessing = False;
	
	CashClient.OpenCreationOfRefundContract(ThisObject, Item);

EndProcedure

&AtClient
Procedure FiscalOperationStatusURLProcessing(Item, Var_URL, StandardProcessing)
	
	GeneratingFiscalChecksClient.FiscalOperationNavigationLinkProcessing(
		ThisObject, Var_URL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FiscalTransactionCompletion(Result, AdditionalParameters) Export
	
	ResultOfFiscalOperation = Undefined;
	If Result = False 
		And TypeOf(AdditionalParameters) = Type("Structure") 
		And AdditionalParameters.Property("ResultOfFiscalOperation", ResultOfFiscalOperation) 
		And TypeOf(ResultOfFiscalOperation) = Type("Structure")
		And ResultOfFiscalOperation.Property("Result")
		And Not ResultOfFiscalOperation.Result Then
		
		DocumentReference = Undefined;
		AdditionalParameters.Property("DocumentReference", DocumentReference);
		
	EndIf;
	
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
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	
	CompleteVATTaxation();
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
	StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
		DocumentCorrectionClient.StringFixHandlingNavigationLinks(
			ThisObject, FormattedStringURL, StandardProcessing);
			
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	ClearMessages();
	
	
	Return;
	
EndProcedure

&AtClient
Procedure CurrencyDecorationAndPaymentRateClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("CurrencyDecorationAndPaymentRateClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	
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

#EndRegion

#Region FormTableItemsEventHandlersARAPDetails

&AtClient
Procedure DecryptionSwitchOnChange(Item)
	
	If Not DecryptionSwitch Then
		If Object.ARAPDetails.Count() = 0 Then
			NewRow = Object.ARAPDetails.Add();
			Items.ARAPDetails.CurrentRow = NewRow.GetID();
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
Procedure ARAPDetailsSelection(Item, RowSelected, Field, StandardProcessing)
	If Field.Name = "ARAPDetailsPresentationOfRecordingInComplAccounting" Then
		GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	EndIf;
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
Procedure ARAPDetailsSumOnChange(Item)

	TableRow = Items.ARAPDetails.CurrentData;
	
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	
	Object.IncludingVAT = "";
	
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
Procedure ARAPDetailsPaymentPurposeOnChange(Item)
	
	Object.IncludingVAT = "";
	
	TableRow = Items.ARAPDetails.CurrentData;
	If Not ValueIsFilled(TableRow.PaymentPurpose) Then
		TableRow.ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
		TableRow.MaturityDate = Date(1, 1, 1);
	EndIf;
	
	UpdatePresentationOfMaturityDate();
	
	ARAPDetailsARAPObjectOnChangeServer(TableRow.GetID());
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectOnChange(Item)
	
	Object.IncludingVAT = "";
	
	TableRow = Items.ARAPDetails.CurrentData;
	If Not ValueIsFilled(TableRow.ARAPObject) Then
		TableRow.PaymentPurpose = Undefined;
		TableRow.MaturityDate = Date(1, 1, 1);
	EndIf;
	UpdatePresentationOfMaturityDate();
	
	ARAPDetailsARAPObjectOnChangeServer(TableRow.GetID());
	
EndProcedure

&AtServer
Procedure ARAPDetailsARAPObjectOnChangeServer(LineID)
	
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	
	CashServer.CheckFillOutContract(Object, LineID);
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, LineID);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
	GenerateHyperlinkCaptionPaymentObjectDetails();
	UpdateTaxRateRecalculateVATAmount(LineID);
	ARAPAccountingFormWork.BlockSettlementObjects(ThisForm);
	
	TableRow = Object.ARAPDetails.FindByID(LineID);
	YouAreAllowedToWorkWithAffiliatedPartners(TableRow);
	
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
Procedure DecryptionWithoutSplittingTheCalculationObjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
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
Procedure DecryptionWithoutSplittingTheCalculationObjectChoiceProcessing(Item, ValueSelected, AdditionalData,
	ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		PaymentDecryptionSettlementObjectSelectionProcessingOnServer(ValueSelected);
	EndIf;
	
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtClient
Procedure DecodingWithoutSplittingRepresentationOfReflectionInReglAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheBasisOfThePaymentAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ARAPDetailsPaymentPurposeAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing);
	
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
	TableRow.Contract = ValueSelected.Contract;
	TableRow.LineOfBusiness = ValueSelected.LineOfBusiness;
	TableRow.ItIsAllowedToWorkWithSubsidiaryPartners = ValueSelected.ItIsAllowedToWorkWithSubsidiaryPartners;
	TableRow.AmountARAP = ValueSelected.AmountARAP;
	TableRow.ARAPObject = ValueSelected.ARAPObject;
	TableRow.ARAPCurrency = ValueSelected.ARAPCurrency;

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
	
	UpdateAllRowsOnServer(TableRow.GetID());
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.RefundFromAnotherCompany 
		And Object.BusinessOperation <> Enums.BusinessTransactions.RefundFromVendor Then
		Contracts = Object.ARAPDetails.Unload( , "Contract").UnloadColumn("Contract");
		Contracts = CommonClientServer.CollapseArray(Contracts);
		If Contracts.Count() = 1 Then
			Object.Contract = TableRow.Contract;
		EndIf;
	EndIf;
	
	Object.IncludingVAT = "";
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
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, RowID);
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
	GenerateHyperlinkCaptionPaymentObjectDetails();
	FillInCourseAndMultiplicityInDecryptionLine(TableRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	YouAreAllowedToWorkWithAffiliatedPartners(TableRow);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure ARAPDetailsPaymentBasisChoiceProcessingAtServer(ValueSelected)

	RowID = Items.ARAPDetails.CurrentRow;
	TableRow = Object.ARAPDetails.FindByID(RowID);
	
	TableRow.PaymentPurpose = ValueSelected.PaymentPurpose;
	TableRow.ARAPObject = ARAPObjectsServer.ARAPObjectOnBasisOfPayment(TableRow.PaymentPurpose);
	
	ARAPDetailsARAPObjectOnChangeServer(RowID);

EndProcedure

&AtServer
Procedure AddSelectedValue(ValueSelected)
	
	ValueSelected.Insert("CashFlowItem",
		CashServer.ArticleOfCashFlowOfSettlementObject(ValueSelected.ARAPObject,
			Object.BusinessOperation));
	
	ARAPObjects = New Array;
	ARAPObjects.Add(ValueSelected.ARAPObject);
	
	ValueSelected.Insert("VATRate", CashServer.VATRateOfSettlementObject(Object.Organization, ARAPObjects));
	
	If ValueIsFilled(ValueSelected.ARAPCurrency) Then
		CurrencyExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(ValueSelected.ARAPCurrency, Undefined,
						SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
		ValueSelected.Insert("ExchangeRateNumeratorOfMutualSettlements", CurrencyExchangeRate.CourseNumerator);
		ValueSelected.Insert("TheExchangeRateIsTheDenominatorOfMutualSettlements", CurrencyExchangeRate.CourseDenominator);
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPCurrencyOnChange(Item)
	
	DecryptionOfPaymentCurrencyOfSettlementsWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentCurrencyOfSettlementsWhenChangedOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	ArrayOfOperationDetails = New Array;
	Documents.CashAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
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
	
	CourseAndMultiplicity = CashServer.CourseNumeratorAndCourseDenominatorOfMutualSettlements(
		Object.Currency, TSRow.ARAPCurrency, CurrencyOfComplianceAccounting, Object.Date, TSRow.ARAPObject, Object.Contract);
	TSRow.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
	TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;
	TSRow.ContractRateOption = CourseAndMultiplicity.ContractRateOption;
	TSRow.ARAPObjectType = CourseAndMultiplicity.ARAPObjectType;
	
EndProcedure

&AtClient
Procedure ARAPDetailsIncomeItemOnChange(Item)
	
	ARAPDetailsIncomeItemOnChangeServer(CachedValues, Item.Name);
	
EndProcedure

&AtServer
Procedure ARAPDetailsIncomeItemOnChangeServer(CachedValues, TagName);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	
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
	
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	
	ConfigureDependentFormElementsOnServer();
	
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
EndProcedure

&AtClient
Procedure ARAPDetailsIncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ARAPDetailsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ARAPDetailsDimensionOfExpensesOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
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
Procedure ARAPDetailsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ARAPDetailsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
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
Procedure ARAPDetailsAfterDeleteRow(Item)
	
	Object.IncludingVAT = "";
	ARAPDetailsAfterDeleteRowServer();
	
EndProcedure

&AtServer
Procedure ARAPDetailsAfterDeleteRowServer()
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
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
Procedure DepartmentOnChange(Item)
	
	CompleteVATTaxation();
	
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
	|	TermsOfLeaseContracts.VATRate AS VATRate
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
	EndIf;
	
	CurrentRow.AmountARAP = 0;
	CurrentRow.TypeOfLeasePayment = Enums.TypesOfLeasePayments.DepositPayment;
	
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
	ConfigureDependentFormElementsOnServer();
	
EndProcedure
&AtClient
Procedure DecryptionWithoutSplittingTheTypeOfRentPaymentOnChange(Item)
	ConfigureDependentFormElements("TypeOfLeasePayment");
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
Procedure TranscriptOfThePaymentTaxationOfPersonalIncomeTaxChanges(Item)
	
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
Procedure SelectionByStock(Command)
	
	ThisIsComingFromAnotherOrganization =
		(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromOtherCompany")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany"));
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("CashAccount", NStr("vi = 'Quỹ tiền mặt';
																|ru = 'Касса';
																|en = 'Cash account'; fa = 'صندوق';
																|it = 'Cassa';
																|pl = 'Kasa';
																|tr = 'Kasa hesabı'"));
	If ThisIsComingFromAnotherOrganization Then
		CheckParameters.CheckedAttributes.Insert("CashAccountIssuer", NStr("vi = 'Người gửi';
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
	Notification = New CallbackDescription("SelectionBasedOnBalancesAfterVerification", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
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
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	
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
Procedure InsertVATInclusive(Command)
	
	InsertIncludingVATOnServer();
	
EndProcedure

&AtServer
Procedure InsertIncludingVATOnServer()
	
	Object.IncludingVAT = CashServer.TextAmountOfVATPayment(Object.Organization, Object.Currency, Object.ARAPDetails, False);
	
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
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

&AtClient
Procedure FillInThePaymentExplanationOnLoansForEmployee(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure CheckCounterparties(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
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

#EndRegion

#Region Private

#Region ElementEventHandlers

&AtClient
Function DocumentAmountOnChangeClient()
	
	Object.IncludingVAT = "";
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.DocumentAmount, False);
	
	Return True;
	
EndFunction

&AtServer
Procedure DocumentAmountOnChangeServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		RecalculateConversionParameters("ConversionRate");
	EndIf;
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	
	CalculateAmountOfSettlements_();
	FillInCurrencyOfMutualSettlementsOfDocument();
	
EndProcedure

&AtServer
Procedure CurrencyOfConversionOnChangeServer()
	
	RecalculateConversionParameters("CurrencyOfConversion");
	SetConversionAmountHeader();
	
EndProcedure

&AtServer
Procedure MultiplicityOfConversionRateWhenChangingOnServer()

	RecalculateConversionParameters("ConversionRateMultiplier");

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

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Counterparty.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.OtherCashReceipt;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
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
													|en = '<Not needed>'; fa = '<Not needed>';
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
Procedure FormItemsManagement()
	
	SetSelectionParameters();
	SetPossibleValuesForSenderSCashRegister(False);
	
	Items.BusinessOperation.Enabled = Not Object.Patch;
	Items.DocumentAmount.Enabled = Not Object.Patch;
	Items.CashAccount.Enabled = Not Object.Patch;
	Items.Counterparty.Enabled = Not Object.Patch;
	Items.CashAccountIssuer.Enabled = Not Object.Patch;
	Items.BankAccount.Enabled = Not Object.Patch;
	Items.CashRegister.Enabled = Not Object.Patch;
	Items.AdvanceHolder.Enabled = Not Object.Patch;
	
	ArrayOfOperationDetails = New Array;
	Documents.CashAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation, Undefined, ArrayOfOperationDetails);
	
	CashServer.SetParametersForSelectingCashRegister(Object, Items.CashAccount);
	CashServer.SetCounterpartySelectionParameters(Object, Items.Counterparty);
	CashServer.SetPartnerSelectionParameters(Object, Items.ARAPDetailsPartner);
	CashServer.SetPartnerSelectionParameters(Object, Items.DecryptionWithoutPartitioningPartner);
	CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.ARAPDetailsLoanDepositContract);
	CashServer.SetParametersForSelectingLoanDepositAgreement(Object, Items.DecryptionWithoutSplittingTheLoanDepositAgreement);
	CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.ARAPDetailsLeaseContracts);
	CashServer.SetParametersForSelectingLeaseAgreement(Object, Items.DecryptionWithoutSplittingTheLeaseAgreement);
	If ArrayOfOperationDetails.Find("Contract") <> Undefined Then
		CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	EndIf;
	
	SetSelectionParametersForCashTransferOrder();
	CashServer.EstablishLinksBetweenVATRateSelectionParameters(Object, Items.DecodingWithoutSplittingTheVATRate);
	CashServer.EstablishLinksBetweenVATRateSelectionParameters(Object, Items.ARAPDetailsVATRate);
	CashServer.SetParametersForSelectingDirectionOfActivity(Object, Items.LineOfBusiness);
	CashServer.SetParametersForSelectingDirectionOfActivity(Object, Items.DirectionOfReturnActivity);
	
	SetVisibilityOfGiftCertificateSelectionButton();
	
	CashServer.FillInListOfTypesOfAmountsOfLoansDeposits(
		Items.ARAPDetailsLoanAndDepositAmountType.ChoiceList, Object.BusinessOperation);
	CashServer.FillInListOfTypesOfAmountsOfLoansDeposits(
		Items.DecryptionWithoutSplittingTheTypeOfLoanAmountDeposit.ChoiceList, Object.BusinessOperation);
	
	CashServer.SetPaymentAmountHeader(Object.Currency, Items);
	Items.LabelCurrency.Title = String(Object.Currency);
	
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
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("UseMultipleCurrencies");
	FormAttributes.Insert("UsePayrollTM");
	FormAttributes.Insert("ThereAreBranches");
	FormAttributes.Insert("AmountUnallocated");
	FormAttributes.Insert("UseIntercompanyContracts");
	FormAttributes.Insert("UseCustomerContracts");
	FormAttributes.Insert("UseContractsWithVendors");
	FormAttributes.Insert("ARAPCurrency");
	FormAttributes.Insert("CurrencyOfComplianceAccounting");
	FormAttributes.Insert("ContractRateOption");
	FormAttributes.Insert("ARAPObjectType");
	FormAttributes.Insert("ExchangeRateNumeratorOfMutualSettlements");
	FormAttributes.Insert("MultipleARAPCurrency");
	
	FillPropertyValues(FormAttributes, Form);
	
	If Form.Object.ARAPDetails.Count() Then
		FormAttributes.Insert("TypeOfLeasePayment", Form.Object.ARAPDetails[0].TypeOfLeasePayment);
	Else
		FormAttributes.Insert("TypeOfLeasePayment");
	EndIf;
	
	Return FormAttributes;
	
EndFunction

&AtServer
Procedure SetSelectionParameters()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount Then
		
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameterLink("Filter.Owner", "Object.Organization"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.CashCurrency", "Object.Currency"));
		Items.CashAccountIssuer.ChoiceParameterLinks = New FixedArray(ParametersArray);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany Then
		
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameterLink("Filter.CashCurrency", "Object.Currency"));
		Items.CashAccountIssuer.ChoiceParameterLinks = New FixedArray(ParametersArray);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameterLink("Filter.CashCurrency", "Object.Currency"));
		Items.CashAccountIssuer.ChoiceParameterLinks = New FixedArray(ParametersArray);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank Then
		
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameterLink("Filter.Owner", "Object.Organization"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.CashCurrency", "Object.Currency"));
		Items.BankAccount.ChoiceParameterLinks = New FixedArray(ParametersArray);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SpecifyListOfBusinessOperations()
	
	ItemBusinessOperation = Items.BusinessOperation;
	
	CashServer.EstablishVisibilityOfTransferOperationsBetweenOrganizations(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfInternalTransferOperations(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfTransactionsUnderLoanAndDepositAgreements(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfOperationOtherCashFlow(ItemBusinessOperation);
	CashServer.SetVisibilityOfCurrencyConversionCashOperation(ItemBusinessOperation);
	CashServer.SetVisibilityOfTransferOperationsBetweenCashRegisters(ItemBusinessOperation);
	CashServer.SetVisibilityOfOperationsWithCashRegisterCashRegisters(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfOperationsToLoansToEmployees(ItemBusinessOperation);
	CashServer.EstablishVisibilityOfPaymentToLandlordOperation(ItemBusinessOperation);
EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning()
	
	CashServer.SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning(ThisObject);
	
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

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure
&AtServer
Procedure UpdateAllRowsOnServer(LineID)
	
	UpdateTaxRateRecalculateVATAmount(LineID);
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	SetRestrictionOnTypeOfPaymentDecryptionContract();
	
EndProcedure

&AtServer
Procedure UpdateTaxRateRecalculateVATAmount(LineID )
	
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
Procedure YouAreAllowedToWorkWithAffiliatedPartners(TableRow)
	
	ReferencesArrray = CommonClientServer.ValueInArray(TableRow.ARAPObject);
	ComplianceOfContractCurrencyExchangeRate = ARAPAccountingServer.ComplianceOfARAPObjectsAndParametersOfContract(ReferencesArrray);
	TableRow.ItIsAllowedToWorkWithSubsidiaryPartners = ComplianceOfContractCurrencyExchangeRate[TableRow.ARAPObject].ItIsAllowedToWorkWithSubsidiaryPartners;
	TableRow.TheCalculationObjectMatchesTheDocument = ComplianceOfContractCurrencyExchangeRate[TableRow.ARAPObject].Object = Object.Ref;
	
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

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	UseMultipleCurrencies             = GetFunctionalOption("UseMultipleCurrencies");
	UseIntercompanyContracts = GetFunctionalOption("UseIntercompanyContracts");
	UseCustomerContracts         = GetFunctionalOption("UseCustomerContracts");
	UseContractsWithVendors      = GetFunctionalOption("UseContractsWithVendors");
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CurrentCashAccount = Object.CashAccount;
	
	If ValueIsFilled(Object.CashRegister) Then
		CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
		AccessRights = SalesSettingsForUsersServer.CWPAccessRights(Users.CurrentUser());
	EndIf;
	
	If ValueIsFilled(Object.Organization) Then
		BranchesOfOrganization.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Object.Organization));
		ThereAreBranches = BranchesOfOrganization.Count() > 0;
	EndIf;
	
	InitializePaymentDecryption();
	
	FillInPayerOrganization();
	GetDefaultServerPartner(Object.Counterparty, Partner, Object.BusinessOperation);
	GetDefaultContractServer();
	
	SpecifyListOfBusinessOperations();
	CashServer.GetAvailableBusinessOfOperationsBasedOn(
		Object.DocumentBasis, Enums.PaymentForms.CashAccountPayment_, AvailableBaseOfOperations);
	
	SetHeadingIncomeExpenseItem();
	SetConversionAmountHeader();
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure InitializePaymentDecryption()
	
	ArrayOfAllProps = New Array; ArrayOfOperationDetails = New Array;
	Documents.CashAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(Object.BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails);
	
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
		CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
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
	EndDo;
EndProcedure

&AtServer
Procedure FillInPayerOrganization()
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromOtherCompany")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundFromAnotherCompany")
	Then
		AttributesStructure1 = Catalogs.CashAccounts.GetCheckoutDetails(Object.CashAccountIssuer);
		If ValueIsFilled(AttributesStructure1.Organization) Then
			If ValueIsFilled(CompanyPayer)
				And CompanyPayer <> AttributesStructure1.Organization Then
				ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "CashAccountIssuer.Owner");
			EndIf;
			CompanyPayer = AttributesStructure1.Organization;
		EndIf;
	Else
		CompanyPayer = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure GetDefaultContractServer()
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.CashAccountReceiptNote.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails);
		
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
			ContractBusinessTransaction.Add(Enums.BusinessTransactions.ConsignmentProcurement);
		EndIf;
		
		CounterpartyContract = CashServer.DefaultContract(
			CounterpartyContract, Partner, Object.Counterparty, Object.Organization, ContractBusinessTransaction);
			
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

&AtServer
Procedure GetDefaultBankAccount()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.Currency = Object.Currency;
	Object.BankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
	
EndProcedure

&AtServerNoContext
Procedure GetDefaultServerPartner(Counterparty, Partner, BusinessOperation)
	
	Partner = CashServer.GetCounterpartyPartner(Counterparty, BusinessOperation);
	
EndProcedure

&AtServerNoContext
Function DetailsOfCashRegisterAndCashRegister(CashAccount, CashRegister)
	
	AttributesStructure1 = New Structure("CashRegisterAttributes, CashRegisterDetails", 
		Catalogs.CashAccounts.GetCheckoutDetails(CashAccount),
		Catalogs.CashRegisters.CashRegisterDetails(CashRegister));
	
	Return AttributesStructure1;
	
EndFunction

&AtServer
Procedure SetPossibleValuesForSenderSCashRegister(ChangeSenderSCashier = True)
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount
		And ValueIsFilled(Object.CashAccount) Then
		
		Query = New Query("
		|SELECT ALLOWED TOP 1
		|	Recipients.PaymentBeneficiary AS Ref
		|
		|FROM
		|	Catalog.CashAccounts.RecipientOfCashTransfer AS Recipients
		|
		|WHERE
		|	Recipients.PaymentBeneficiary = &CashAccountRecipient
		|");
		Query.SetParameter("CashAccountRecipient", Object.CashAccount);
		ThereAreCheckoutSenders = Not Query.Execute().IsEmpty();
	Else
		
		ThereAreCheckoutSenders = False;
	EndIf;
	
	Query = New Query("
	|SELECT ALLOWED
	|	CashAccounts.Ref AS Ref
	|
	|FROM
	|	Catalog.CashAccounts AS CashAccounts
	|
	|	LEFT JOIN
	|		Catalog.CashAccounts.RecipientOfCashTransfer AS RecipientsOfSenderCheckout
	|	ON
	|		RecipientsOfSenderCheckout.Ref = CashAccounts.Ref
	|		AND RecipientsOfSenderCheckout.PaymentBeneficiary = &CashAccountRecipient
	|		AND &SelectSendersByCheckout
	|
	|WHERE
	|	(CashAccounts.CashCurrency = &Currency OR NOT &SelectByCurrency)
	|	AND (CashAccounts.Owner IN (&Owner) OR NOT &SelectByOwner)
	|	AND CashAccounts.Owner NOT IN (&OwnerFilter_)
	|	AND (RecipientsOfSenderCheckout.PaymentBeneficiary IS NOT NULL OR NOT &SelectSendersByCheckout)
	|	AND CashAccounts.Ref <> &CashAccountRecipient
	|	
	|UNION ALL
	|	
	|SELECT
	|	CashAccounts.Ref AS Ref
	|
	|FROM
	|	Catalog.CashRegisters AS CashAccounts
	|
	|WHERE
	|	(CashAccounts.CashCurrency = &Currency OR NOT &SelectByCurrency)
	|	AND (CashAccounts.Owner IN (&Owner) OR NOT &SelectByOwner)
	|	AND CashAccounts.Owner NOT IN (&OwnerFilter_)
	|	AND CashAccounts.CashRegisterType NOT IN (VALUE(Enum.CashRegisterTypes.MobileCashRegister), VALUE(Enum.CashRegisterTypes.CashRegisterOffline))
	|");
	
	Query.SetParameter("CashAccountRecipient", Object.CashAccount);
	Query.SetParameter("SelectSendersByCheckout", ThereAreCheckoutSenders);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		And ValueIsFilled(Object.CurrencyOfConversion) Then
		
		Query.SetParameter("Currency", Object.CurrencyOfConversion);
		Query.SetParameter("SelectByCurrency", True);
		
	ElsIf ValueIsFilled(Object.Currency) Then
		
		Query.SetParameter("Currency", Object.Currency);
		Query.SetParameter("SelectByCurrency", True);
		
	Else
		
		Query.SetParameter("Currency", Undefined);
		Query.SetParameter("SelectByCurrency", False);
		
	EndIf;
	
	Query.SetParameter("Owner", Undefined);
	If (Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromAnotherCashAccount
		Or Object.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion)
		And ValueIsFilled(Object.CashAccount)
		And ValueIsFilled(Object.Organization) Then
		
		Query.SetParameter("Owner", Object.Organization);
		Query.SetParameter("SelectByOwner", True);
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		ArrayOfInterconnectedOrganizations = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Object.Organization);
		Query.SetParameter("Owner", ArrayOfInterconnectedOrganizations);
		Query.SetParameter("SelectByOwner", True);
		
	Else
		
		Query.SetParameter("SelectByOwner", False);
		
	EndIf;
	Query.SetParameter("OwnerFilter_", Undefined);
	If (Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany)
		And ValueIsFilled(Object.CashAccount)
		And ValueIsFilled(Object.Organization) Then
		
		ArrayOfInterconnectedOrganizations = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Object.Organization);
		ArrayOfInterconnectedOrganizations.Add(Object.Organization);
		Query.SetParameter("OwnerFilter_", ArrayOfInterconnectedOrganizations);
		
	EndIf;
	
	CheckoutArray = Query.Execute().Unload().UnloadColumn("Ref");
	Items.CashAccountIssuer.ChoiceList.LoadValues(CheckoutArray);
	
	If ChangeSenderSCashier Then
		If CheckoutArray.Count() = 1 Then
			
			Object.CashAccountIssuer = CheckoutArray[0];
			CashAccountIssuerOnChangeServer();
			
		ElsIf ValueIsFilled(Object.CashAccountIssuer)
			And CheckoutArray.Find(Object.CashAccountIssuer) = Undefined Then
			
			Object.CashAccountIssuer = Catalogs.CashAccounts.EmptyRef();
			CashAccountIssuerOnChangeServer();
			
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
		Items.ARAPDetailsIncomeItem.Title      = NStr("vi = 'Dạng thu nhập/chi phí';
														|ru = 'Статья доходов/расходов';
														|en = 'Item of income/expense'; fa = 'قلم درآمد/هزینه';
														|it = 'Voce di entrate/uscite';
														|pl = 'Rodzaj przychodów/wydatków';
														|tr = 'Gelir/gider kalemi'");
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
	
	ConversionParameters_SSLy = CashServer.InitializeConversionParameters();
	FillPropertyValues(ConversionParameters_SSLy, Object);
	ConversionParameters_SSLy.CurrencyOfComplianceAccounting = CurrencyOfComplianceAccounting;
	
	CashServer.CalculateConversionParameters(ConversionParameters_SSLy, Var_AttributeName);
	FillPropertyValues(Object, ConversionParameters_SSLy);
	
EndProcedure

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
	
	For Each TSRow In Object.ARAPDetails Do
		CashServer.FormCourseDenominatorByText(TSRow, Object.Currency, CurrencyOfComplianceAccounting);
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
	
	SaleOfGiftCertificateIsAllowed =
		RetailSalesLocalization.ItIsAllowedToSellGiftCertificateInDocument(Object.BusinessOperation);
	Items.ARAPDetailsPickUpGiftCertificate.Visible = SaleOfGiftCertificateIsAllowed;
	
EndProcedure

&AtServer
Procedure ProcessGiftCertificate(GiftCertificate)
	
	FoundRow = GiftCertificatesServer.AddGiftCertificateToTablePartOfPaymentDecryption(GiftCertificate, ThisObject);
	If FoundRow <> Undefined Then
		
		Modified = True;
		Object.IncludingVAT = "";
		
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
Function TakeIntoAccountTypeOfLoanAmountDeposit(AmountType)

	Return (Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
		And ValueIsFilled(AmountType);

EndFunction

&AtServer
Procedure SetSelectionParametersForCashTransferOrder()

	ChoiceParametersArray = New Array;
	
	ChoiceParametersArray.Add(
			New ChoiceParameter("Filter.Status", Enums.CashTransferOrderStatuses.AmountDue));
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashCollectionFromBank Then
		ChoiceParametersArray.Add(
			New ChoiceParameter("Filter.BusinessOperation", Enums.BusinessTransactions.WithdrawalFromBankAccount));
	Else
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.BusinessOperation", Object.BusinessOperation));
	EndIf;
	
	Items.CashTransferReferenceOrder.ChoiceParameters =
		New FixedArray(ChoiceParametersArray);

EndProcedure

&AtServer
Procedure FillInCashier()
	
	CashierCashAccounts = Common.ObjectAttributeValue(Object.CashAccount, "Cashier");
	If ValueIsFilled(CashierCashAccounts) Then
		Object.Cashier = CashierCashAccounts;
	Else
		Object.Cashier = CashServer.CashierOfLastACWOrICO(Object.Date, Object.Organization, Object.CashAccount);
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearAdditionalReceiptInformation()

	Object.ReceivedFrom = "";
	Object.Basis = "";
	Object.Application = "";
	Object.IssuedLetterOfAuthority = Documents.IssuedLetterOfAuthority.EmptyRef();

EndProcedure

&AtServer
Procedure ClearCalculationObject(DecryptionString)

	CashServer.ClearCalculationObject(Object, DecryptionString);

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
