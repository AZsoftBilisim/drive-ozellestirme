#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.CustomerInvoiceIntercompany - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = ParametersForFillingInventoryTypes("CompanyRecipient", False);
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	DocumentObject.AdditionalProperties.Insert("UseFillingParametersForInventoryTypesInPreparation");
	
EndProcedure

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
//
Procedure FillInProductTrackingForm() Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.CustomerInvoiceIntercompany.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	If DocumentTables <> Undefined Then
		FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables);
		AdditionalProperties.Insert("TablesOfFillingOfTypesOfStocksAtExchange", DocumentTables);
	EndIf;
	
	FillStockTypes(Cancel);
	AdditionalProperties.Delete("TablesOfFillingOfTypesOfStocksAtExchange");
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	
	If InventoryKinds.Count() > 0 Then
		InventoryKinds.Clear();
	EndIf;
	
	ARAPDetailsWithCustomer.Clear();
	ARAPDetailsWithVendor.Clear();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	If Not ValueIsFilled(TransferForActivity_) Then
		FillInTransferUnderActivity();
	EndIf;
	
	If SpecifyCCDNumbers Then
		RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
								ThisObject);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	EndIf;
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);

	StructureOfActions = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	CustomerInvoiceIntercompanyLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

// Parameters:
//	FillingData - DocumentRef.InventoryTransfer
//					 - Structure - Contains:
//							* HeaderFields - Structure
//							* ThisIsTransferReturn21 - Boolean
//							* RegistrationDate - Date
//							* EndOfPeriod - Date
//							* Contract - CatalogRef.IntercompanyContracts
//							* PriceKind - CatalogRef.TypesOfPrices
//							* Currency - CatalogRef.Currencies
//							* ARAPCurrency - CatalogRef.Currencies
//							* InventoryType - EnumRef.InventoryTypes
//							* BusinessTransactions - EnumRef.BusinessTransactions
//							* FillInByOrganizationSProductReserves - Boolean
//	StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("ThisIsTransferReturn21")
		And FillingData.ThisIsTransferReturn21 Then
		
		FieldsToFillIn = "Organization, CompanyRecipient, Warehouse, BeginOfPeriod";
		FillPropertyValues(ThisObject, FillingData, FieldsToFillIn);
		
		Date = FillingData.RegistrationDate;
		
		If Not ValueIsFilled(Date)
			And ValueIsFilled(FillingData.EndOfPeriod)
			And FillingData.EndOfPeriod < CurrentSessionDate() Then
			
			Date = FillingData.EndOfPeriod;
			
		EndIf;
		
		If FillingData.Property("Contract") Then
			Contract = FillingData.Contract;
		EndIf;
		
		If FillingData.Property("PriceKind") Then
			PriceKind = FillingData.PriceKind;
		EndIf;
		
		If FillingData.Property("Currency")
			And ValueIsFilled(FillingData.Currency) Then
			
			Currency = FillingData.Currency;
			
		EndIf;
		
		If FillingData.Property("ARAPCurrency")
			And ValueIsFilled(FillingData.ARAPCurrency) Then
			
			ARAPCurrency = FillingData.ARAPCurrency;
			
		EndIf;
		
		If ValueIsFilled(FillingData.EndOfPeriod)
			Or ValueIsFilled(FillingData.RegistrationDate) Then
			
			EndOfPeriod = FillingData.EndOfPeriod;
			
		Else
			EndOfPeriod = CurrentSessionDate();
		EndIf;
		
		If FillingData.Property("InventoryType") Then
			If FillingData.InventoryType = Enums.InventoryTypes.ConsignedGoods Then
				BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany;
			Else
				BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
			EndIf;
		Else
			BusinessOperation = FillingData.BusinessOperation;
		EndIf;
		
		If ValueIsFilled(FillingData.TransferForActivity_) Then
			TransferForActivity_ = FillingData.TransferForActivity_;
			
			If BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany Then
				VATTaxation = TransferForActivity_;
			EndIf;
		EndIf;
		
		If ValueIsFilled(FillingData.RegistrationDate) Then
			FillInTransfer21ByRegistrationDate();
		Else
			CompleteTransfer21OnRemainingGoodsToTransfer();
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("HeaderFields") Then
		
		HeaderFields = FillingData.HeaderFields; 
		
		Date                  = HeaderFields.Period;
		Organization           = HeaderFields.Sender;
		CompanyRecipient = HeaderFields.Recipient;
		Warehouse                 = HeaderFields.StorageLocation;
		BusinessOperation = HeaderFields.BusinessOperation;
		PriceKind               = HeaderFields.PriceKind;
		Contract               = HeaderFields.Contract;
		Currency                = HeaderFields.Currency;
		VATTaxation    = HeaderFields.VATTaxation;
		// Counterparty - we do not take caps from the fields, because the counterparty is needed only for an intermediary
		
		If FillingData.Property("FillInByOrganizationSProductReserves") Then
			Query = New Query;
			
			For Each KeyValue In HeaderFields Do
				Query.SetParameter(KeyValue.Key, KeyValue.Value);
			EndDo;
			
			Query.SetParameter("BeginOfPeriod", BegOfMonth(HeaderFields.Period));
			Query.SetParameter("EndOfPeriod", EndOfMonth(HeaderFields.Period));
			Query.SetParameter("MakeTransfers", True);
			
			Query.Text = InventoriesServer.TextOfRequestForRegistrationOfReservesOfGoodsOrganizations(Query,"SelectingDocumentContent");
			ResultTable2 = Query.Execute().Unload();
			
			ResultTable2.Columns.Delete("InventoryOwnerAttribute");
			SenderSInventoryViewColumn = ResultTable2.Columns.SenderSInventoryType; // ValueTableColumn
			SenderSInventoryViewColumn.Name = "InventoryOwnerAttribute";
			
			InventoryKinds.Load(ResultTable2);
			
			ResultTable2.Columns.Delete("CCDNumber");
			ResultTable2.Columns.Delete("InventoryOwnerAttribute");
			RecipientInventoryViewColumn = ResultTable2.Columns.RecipientInventoryOwnerAttribute; // ValueTableColumn
			RecipientInventoryViewColumn.Name = "InventoryOwnerAttribute";
			Goods.Load(ResultTable2);
			
		EndIf;
	ElsIf TypeOf(FillingData) = Type("DocumentRef.InventoryTransfer") Then
		InstructionsForMovingGoods(FillingData,FillingData);
	EndIf;
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.CustomerInvoiceIntercompany.ItemsAndDimensionsSelectionParameters(
										BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	FillOutBankAccounts();
	
	InitializeDocument(FillingData);
	
	If SpecifyCCDNumbers Then
		RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
								ThisObject);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	EndIf;
	
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	CustomerInvoiceIntercompanyLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	CheckOrganizations(Cancel);
	
	If ValueIsFilled(Organization)
		And ValueIsFilled(CompanyRecipient) Then
		
		CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Organization, CompanyRecipient);
		
		If Not CheckStructure.CurrenciesDoNotMatch Then
			ErrorText = NStr("vi = 'Tiền tệ kế toán tài chính của người gửi %1 và người nhận %2 phải trùng nhau.';
							|ru = 'Валюты регламентированного учета отправителя %1 и получателя %2 должны совпадать.';
							|en = 'Local accounting currencies of the %1 sender and the %2 recipient must match.'; fa = 'Local accounting currencies of the %1 sender and the %2 recipient must match.';
							|it = 'Le valute della contabilità regolatoria del mittente %1 del destinatario %2 devono coincidere.';
							|pl = 'Waluty ewidencji reglamentowanej nadawcy %1 i odbiorcy %2 powinny być jednakowe.';
							|tr = 'Gönderici %1 ve alıcı %2''nin yerel muhasebesinin para birimleri eşleşmelidir.'");
			ErrorText = StrTemplate(ErrorText, Organization, CompanyRecipient);
			Common.MessageToUser(ErrorText, ThisObject, "Organization",, Cancel);
		EndIf;
		
		If Not CheckStructure.CountriesMatch Then
			ErrorText = NStr("vi = 'Quốc gia đăng ký của người gửi %1 và người nhận %2 phải trùng nhau.';
							|ru = 'Страны регистрации отправителя %1 и получателя %2 должны совпадать.';
							|en = 'Countries of residence of sender %1 and recipient %2 must be the same.'; fa = 'Countries of residence of sender %1 and recipient %2 must be the same.';
							|it = 'I paesi di registrazione del mittente %1 e del destinatario %2 devono corrispondere.';
							|pl = 'Kraje rejestracji nadawcy %1 i odbiorcy %2 powinny być zgodne.';
							|tr = 'Gönderici %1 ve alıcı %2''nin kayıtlı olduğu ülkeler eşleşmelidir.'");
			ErrorText = StrTemplate(ErrorText, Organization, CompanyRecipient);
			Common.MessageToUser(ErrorText, ThisObject, "Organization",, Cancel);
		EndIf;
		
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany Then
		NotCheckedAttributeArray.Add("VATTaxation");
		NotCheckedAttributeArray.Add("Goods.VATRate");
	EndIf;
	
	Documents.CustomerInvoiceIntercompany.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
			
	If Not ARAPAccountingViaSeparateCounterparty Then
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("Counterparty");
	EndIf;
	
	CheckBankAccounts(Cancel);
	
	ConsignmentSalesServer.CheckIfPeriodIsCorrect(ThisObject, Cancel);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CustomerInvoiceIntercompany),
												Cancel,
												NotCheckedAttributeArray);
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	
	CheckFillingOfDivisionInTablePart(Cancel);
	CheckAmountFilling(Cancel);
	CheckSalesOption(NotCheckedAttributeArray);
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date);
	
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	If SpecifyCCDNumbers
		And (ThisIsTraceableDocument
			Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers")) Then
		
		CheckParameters = InventoriesServer.ParametersForCheckingFillingInOfCCDNumbers();
		CheckParameters.CheckWorks = True;
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel, CheckParameters);
		
	EndIf;
	
	If ThisIsTraceableDocument Then
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject, Goods, Date);
	EndIf;
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName             = "Goods";
	CheckParameters.BankingDetailsNameExpenseItem    = "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(ThisObject,
																TransferForActivity_,
																CheckParameters,
																Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.CustomerInvoiceIntercompany.ItemsAndDimensionsSelectionParameters(
										BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes,
		ItemsAndDimensionsSelectionParameters);
	
	PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject,Cancel);
	CheckCorrectnessOfIndicationOfExcisableGoodsInTabularPartOfGoods(Cancel);
	
	VATAccountingLocalization.CheckServicesAtCommitteeSVATRate(ThisObject, Cancel);
	CustomerInvoiceIntercompanyLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
														ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CustomerInvoiceIntercompany));
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps		= New Array;
	ArrayOfOperationDetails	= New Array;
	
	Documents.CustomerInvoiceIntercompany.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
	
	If Not SpecifyCCDNumbers Then
		For Each RowOfGoods In Goods Do
			If RowOfGoods.QuantityByGBRN Then
				RowOfGoods.QuantityByGBRN = 0;
			EndIf;
			
			If ValueIsFilled(RowOfGoods.CCDNumber) Then
				RowOfGoods.CCDNumber = Undefined;
			EndIf;
		EndDo;
	EndIf;
	
	CalculationDocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Goods, PriceIncludesVAT);
	If DocumentAmount <> CalculationDocumentAmount Then
		DocumentAmount = CalculationDocumentAmount;
	EndIf;
	
	If Not ValueIsFilled(TransferForActivity_) Then
		FillInTransferUnderActivity();
	EndIf;
	
	If Not ValueIsFilled(ARAPCurrency)
		And BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany Then
		ARAPCurrency = Currency;
	EndIf;
	
	If ARAPAccountingViaSeparateCounterparty Then
		If Not ValueIsFilled(IncomingDocumentDate) Then
			IncomingDocumentDate = BegOfDay(Date);
		EndIf;
	Else
		If ValueIsFilled(IncomingDocumentDate) Then
			IncomingDocumentDate = Undefined;
		EndIf;
		If ValueIsFilled(IncomingDocumentNumber) Then
			IncomingDocumentNumber = "";
		EndIf;
		If ValueIsFilled(Partner) Then
			Partner = Undefined;
		EndIf;
		If ValueIsFilled(Counterparty) Then
			Counterparty = Undefined;
		EndIf;
		If ValueIsFilled(CounterpartyBankAccount) Then
			CounterpartyBankAccount = Undefined;
		EndIf;
	EndIf;
	
	If AdditionalProperties.Property("FilledInVersionOfSale") Then
		SaleRegistrationOption = AdditionalProperties.FilledInVersionOfSale;
	EndIf;
	
	AccountingForTraceableGoodsLocalization.ClearGTDUNumbersOfTraceableWorks(ThisObject);
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	If Not ValueIsFilled(PaymentID) Then
		PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	EndIf;
	
	RegistrationParameters = Documents.CustomerInvoiceIntercompany.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	RegistrationParameters = Documents.CustomerInvoiceIntercompany.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If Not ValueIsFilled(ARAPCurrency)
		And BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany Then
		ARAPCurrency = Currency;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.CustomerInvoiceIntercompany.ItemsAndDimensionsSelectionParameters(
										BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	CustomerInvoiceIntercompanyLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.Posting);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RegistrationParameters = Documents.CustomerInvoiceIntercompany.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	
	RegistrationParameters = Documents.CustomerInvoiceIntercompany.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
	CustomerInvoiceIntercompanyLocalization.Posting(ThisObject, Cancel, PostingMode);
	If Not Cancel Then
		ExcisableGoodsAccounting.CreateTaskToRecordAmountOfExciseTax(ThisObject);
	EndIf;
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.UndoPosting);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RegistrationParameters = Documents.CustomerInvoiceIntercompany.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
	RegistrationParameters = Documents.CustomerInvoiceIntercompany.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
	CustomerInvoiceIntercompanyLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	CustomerInvoiceIntercompanyLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	Prefix = TMCommonUseCached.AdditionalPrefixOfNumeratorDocumentsOfSaleOfGoods();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	Author = Users.CurrentUser();
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	EndIf;
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	If ValueIsFilled(Contract) Then
		FieldsNames = "LineOfBusiness, NameForPrinting, ARAPObjectSettings, Number, Date, ARAPCurrency";
		ContractDetails_ = Common.ObjectAttributesValues(Contract, FieldsNames);
		LineOfBusiness = ContractDetails_.LineOfBusiness;
		ARAPObjectSettings = ContractDetails_.ARAPObjectSettings;
		Basis = ContractDetails_.NameForPrinting;
		BaseDocumentNumber = ContractDetails_.Number;
		ReferenceDocumentDateForPrintForms = ContractDetails_.Date;
		ARAPCurrency = ContractDetails_.ARAPCurrency;
	EndIf;
	
	If Not ValueIsFilled(VATTaxation) Then
		CompleteVATTaxation();
	EndIf;
	
	If Not ValueIsFilled(TransferForActivity_) Then
		FillInTransferUnderActivity()
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		CompanyBankAccount);
	
	Department = SettingsValueCached.UserDivision(Users.CurrentUser(), Department);
	
	PriceKind = Catalogs.TypesOfPrices.DefaultPriceType(PriceKind,
		New Structure("UseForIntercompanySales, PriceIncludesVAT", True, PriceIncludesVAT));
	
	If ValueIsFilled(PriceKind) Then
		Attributes = Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind);
		PriceIncludesVAT = Attributes.PriceIncludesVAT;
		If Not ValueIsFilled(Currency) Then
			Currency = Attributes.PriceCurrency;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If Not ValueIsFilled(ARAPCurrency) Then
		ARAPCurrency = Currency;
	EndIf;
	
	SaleRegistrationOption = DefaultSalesOption();
	
	If Not ValueIsFilled(PaymentDate) Then
		PaymentDate = Date;
	EndIf;
	
	If ValueIsFilled(CompanyRecipient) And Not ValueIsFilled(DeliveryAddress) Then
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(
			CompanyRecipient,
			"Actual",
			CurrentSessionDate());
	EndIf;
	
	StructureOfResponsible = SalesServer.GetWarehouseManager(Warehouse);
	If StructureOfResponsible <> Undefined Then
		IssuiedBy = StructureOfResponsible.EmployeeResponsible;
		IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
	EndIf;
	
	FinancialAccountingGroup = Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation);
	FinancialAccountingGroupOfRecipient = Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation, True);
	
	FillInDefaultDetailsInTablePart();
	
EndProcedure

Procedure FillInDefaultDetailsInTablePart() Export
	
	If Goods.Count() = 0 Then
		Return;
	EndIf;
	
	If Not SpecifyCCDNumbers Then
		For Each RowOfTables In Goods Do
			RowOfTables.CCDNumber = Undefined;
		EndDo;
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CustomerInvoiceIntercompany);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	TMCommonUse.CollapseTablePart(ThisObject, "Goods", "BatchesIndicationStatus");	
	
	CachedValues = Undefined;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);

	If Not ValueIsFilled(PriceKind) Then
		PriceKind = Catalogs.TypesOfPrices.DefaultPriceType(PriceKind,
			New Structure("UseForIntercompanySales, PriceIncludesVAT", True, PriceIncludesVAT));
	EndIf;

	If ValueIsFilled(PriceKind) Then
		Attributes = Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind);
		If Currency = Catalogs.Currencies.EmptyRef() Then
			Currency = Attributes.PriceCurrency;
		EndIf;
		If Not ValueIsFilled(ARAPCurrency) Then
			ARAPCurrency = Attributes.PriceCurrency;
		EndIf;
		PriceIncludesVAT = Attributes.PriceIncludesVAT;
		
		FillParameters = New Structure();
		FillParameters.Insert("Date", Date);
		FillParameters.Insert("Organization", Organization);
		FillParameters.Insert("Currency", Currency);
		FillParameters.Insert("PriceKind", PriceKind);
		FillParameters.Insert("PopulationFields", "Price, PriceKind");
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(ThisObject));
		
		EnterprisePricesFillingServer.FillInPrices(Goods, , FillParameters, StructureOfActions);
	EndIf;
	
EndProcedure

Procedure InstructionsForMovingGoods(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.DestinationWarehouse AS Warehouse,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.CompanyBankAccount AS CompanyBankAccount
	|FROM
	|	Document.InventoryTransfer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		FillingData = New Structure;
		For Each Column In QueryResult.Columns Do
			FillingData.Insert(Column.Name);
		EndDo;
		
		Selection = QueryResult.Select();
		Selection.Next();
		FillPropertyValues(FillingData, Selection);
		
		Organization = FillingData.Organization;
		
	EndIf;
	
	// Fill in the data of the tabular part of the "Goods" document.
	Query = New Query("
	|SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.Count AS Count
	|FROM
	|	Document.InventoryTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Goods.Load(QueryResult.Unload());
		FillInDefaultDetailsInTablePart();
		
	EndIf;
		
EndProcedure

Procedure CompleteTransfer21OnRemainingGoodsToTransfer()
	
	Query = New Query();
	Query.Text = QueryTextStockBalanceForTransfer();
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("CompanyRecipient", CompanyRecipient);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("TransferForActivity_", TransferForActivity_);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("FilterByContract", ValueIsFilled(Contract));
	If BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany Then
		InventoryType = Enums.InventoryTypes.OwnGoods;
	Else
		InventoryType = Enums.InventoryTypes.ConsignedGoods;
	EndIf;
	Query.SetParameter("InventoryType", InventoryType);
	
	StartDate = ?(ValueIsFilled(BeginOfPeriod), BegOfDay(BeginOfPeriod), '00010101');
	EndDate = ?(ValueIsFilled(EndOfPeriod), EndOfDay(EndOfPeriod), CurrentSessionDate());
	
	If StartDate > EndDate Then
		Raise NStr("vi = 'Ngày bắt đầu thời gian không thể dài hơn ngày kết thúc';
					|ru = 'Дата начала периода не может быть больше даты окончания периода';
					|en = 'The period start date cannot be greater than the period end date'; fa = 'The period start date cannot be greater than the period end date';
					|it = 'La data di inizio periodo non può essere superiore alla data del termine periodo';
					|pl = 'Data rozpoczęcia okresu nie może być dłuższa niż data zakończenia okresu';
					|tr = 'Dönemin başlangıç tarihi, dönemin bitiş tarihinden büyük olamaz'");
	EndIf;
	
	Query.SetParameter("BeginOfPeriod", StartDate);
	Query.SetParameter("EndOfPeriod", EndDate);

	Goods.Clear();
	GoodsTable = Goods.Unload();
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		NewRow = InventoryKinds.Add();
		FillPropertyValues(NewRow, Selection);
		
		NewProductRow = GoodsTable.Add();
		FillPropertyValues(NewProductRow, Selection);
		NewProductRow.NumberOfPackages = NewProductRow.Count;
		NewProductRow.ByUninvoicedGoods = True;
		
		If ValueIsFilled(Selection.CCDNumber) Then
			SpecifyCCDNumbers = True;
		EndIf;
		
	EndDo;
	
	GoodsTable.GroupBy(
		"Products, Characteristic, Purpose, Series, CCDNumber, VATRate, ByUninvoicedGoods, InventoryOwnerAttribute",
		"Count, NumberOfPackages");
	Goods.Load(GoodsTable);
	
	FillInDefaultDetailsInTablePart();
				
EndProcedure

Procedure FillInTransfer21ByRegistrationDate()
	Query = New Query("
	|SELECT
	|	Consumption_1.RegistrationDate,
	|	Consumption_1.Sender,
	|	Consumption_1.Recipient,
	|	Consumption_1.ItemsLocationAttributes, 
	|	Consumption_1.Warehouse,
	|	Consumption_1.Period,
	|	Consumption_1.InventoryOwnerAttribute,
	|	Consumption_1.RecipientInventoryOwnerAttribute,
	|	Consumption_1.InventoryType,
	|	Consumption_1.VATTaxation,
	|	Consumption_1.CCDNumber,
	|	Consumption_1.Consumed
	|INTO Consumption_1
	|FROM &GoodsToTransfer AS Consumption_1
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Consumption_1.ItemsLocationAttributes,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Series,
	|	Dimension.Purpose,
	|	Consumption_1.InventoryOwnerAttribute,
	|	Consumption_1.RecipientInventoryOwnerAttribute,
	|	Consumption_1.CCDNumber,
	|	SUM(Consumption_1.Consumed) AS Count
	|FROM
	|	Consumption_1 AS Consumption_1
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		Consumption_1.ItemsLocationAttributes = Dimension.Ref
	|
	|GROUP BY
	|	Consumption_1.ItemsLocationAttributes,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Series,
	|	Dimension.Purpose,
	|	Consumption_1.InventoryOwnerAttribute,
	|	Consumption_1.RecipientInventoryOwnerAttribute,
	|	Consumption_1.CCDNumber
	|");
	
	Filters = AccumulationRegisters.CompanyGoodsForTransfer.SelectionOfGoodsForTransfer();
	
	Filters.BeginOfPeriod = BegOfDay(BeginOfPeriod);
	Filters.EndOfPeriod = EndOfDay(?(ValueIsFilled(EndOfPeriod), EndOfPeriod, '39991231'));
	Filters.Warehouse = Warehouse;
	Filters.Organization = Organization;
	Filters.CompanyRecipient = CompanyRecipient;
	Filters.VATTaxation = TransferForActivity_;
	
	If BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany Then
		Filters.InventoryType = Enums.InventoryTypes.OwnGoods;
	Else
		Filters.InventoryType = Enums.InventoryTypes.ConsignedGoods;
	EndIf;
	
	Query.SetParameter("GoodsToTransfer", AccumulationRegisters.CompanyGoodsForTransfer.GoodsToTransfer(Filters));
		
	Goods.Clear();
	InventoryKinds.Clear();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		InventoryLine = InventoryKinds.Add();
		FillPropertyValues(InventoryLine, Selection);
		InventoryLine.NumberOfPackages = InventoryLine.Count;
		
		RowOfGoods = Goods.Add();
		FillPropertyValues(RowOfGoods, Selection);
		RowOfGoods.NumberOfPackages = RowOfGoods.Count;
		RowOfGoods.ByUninvoicedGoods = True;
		
	EndDo;
	
	Goods.GroupBy(
		"ItemsLocationAttributes, Products, Characteristic, Series, Purpose, VATRate, ByUninvoicedGoods",
		"Count, NumberOfPackages");
	
	FillInDefaultDetailsInTablePart();
EndProcedure

Procedure CompleteVATTaxation() Export
	
	FillParameters = Documents.CustomerInvoiceIntercompany.ParametersForFillingInVATTaxation_(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure

Procedure FillOutBankAccounts()
	
	If Not ValueIsFilled(CompanyBankAccount) Or Not ValueIsFilled(RecipientCompanyBankAccount) Then
		SalesServer.FillInBankAccountsUnderAgreement(Contract,
			?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
			?(ValueIsFilled(RecipientCompanyBankAccount), Undefined, RecipientCompanyBankAccount));
	EndIf;
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersOfAccount.Currency = ComplCurrency;
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		CompanyBankAccount);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(CompanyRecipient);
	ParametersOfAccount.Currency = ComplCurrency;
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	RecipientCompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		ParametersOfAccount, RecipientCompanyBankAccount);
	
EndProcedure

#EndRegion

#Region InventoryKinds

Function TemporaryDocumentDataTables(ByUninvoicedGoods = False) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Organization AS Partner,
	|	&Organization AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	&Currency AS Currency,
	|	&TransferForActivity_ AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Warehouse AS Warehouse,
	|	&Organization AS Partner,
	|	&Organization AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	&Currency AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO SenderDocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	TableOfGoods.AmountVATARAP AS AmountVATARAP,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	&Warehouse AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TRUE AS SelectTypesOfStocks,
	|	CASE
	|		WHEN &SpecifyCCDNumbers
	|			THEN TableOfGoods.CCDNumber
	|		ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|	END AS CCDNumber,
	|	TableOfGoods.ToExpenseAs AS ToExpenseAs
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.ByUninvoicedGoods = &ByUninvoicedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	TableOfGoods.AmountVATARAP AS AmountVATARAP,
	|	TableOfGoods.CommissionAmount AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration AS AmountVATRemuneration,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.SalesOpportunity AS SalesOpportunity,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfGoods.SelectTypesOfStocks AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.ToExpenseAs AS ToExpenseAs
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	CatalogProducts.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|											VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	TableOfGoods.AmountVATARAP AS AmountVATARAP,
	|	TableOfGoods.CommissionAmount AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration AS AmountVATRemuneration,
	|	Dimension.StorageLocation AS Warehouse,
	|	TableOfGoods.SalesOpportunity AS SalesOpportunity,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfGoods.SelectTypesOfStocks AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.ToExpenseAs AS ToExpenseAs
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	AND NOT &ByUninvoicedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	TableTypesOfStocks_.AmountVATARAP AS AmountVATARAP,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TableTypesOfStocks_.ExciseTaxAmount AS ExciseTaxAmount,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	&Warehouse AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.ToExpenseAs AS ToExpenseAs
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	TableTypesOfStocks_.AmountVATARAP AS AmountVATARAP,
	|	TableTypesOfStocks_.CommissionAmount AS CommissionAmount,
	|	TableTypesOfStocks_.AmountVATRemuneration AS AmountVATRemuneration,
	|	TableTypesOfStocks_.ExciseTaxAmount AS ExciseTaxAmount,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.ToExpenseAs AS ToExpenseAs
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS CatInventoryOwnerAttribute
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute = CatInventoryOwnerAttribute.Ref
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS CatRecipientInventoryOwnerAttribute
	|		ON TableTypesOfStocks_.RecipientInventoryOwnerAttribute = CatRecipientInventoryOwnerAttribute.Ref
	|WHERE
	|	CatInventoryOwnerAttribute.Organization = &Organization
	|	AND (ISNULL(CatRecipientInventoryOwnerAttribute.Organization, VALUE(Catalog.Companies.EmptyRef)) = &CompanyRecipient
	|		OR TableTypesOfStocks_.RecipientInventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef))
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&CompanyRecipient AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	UNDEFINED AS GoodsOwner,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	&TransferForActivity_ AS VATTaxation,
	|	&TaxationOfOrganization AS TaxationOfOrganization
	|INTO DocumentAttributes
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	AND NOT &ByUninvoicedGoods
	|
	|UNION ALL
	|
	|SELECT
	|	&CompanyRecipient AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.ConsignedGoods) AS InventoryType,
	|	&Organization AS GoodsOwner,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&Organization AS Counterparty,
	|	&Contract AS Contract,
	|	&ARAPCurrency AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	&TaxationOfOrganization AS TaxationOfOrganization
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
	|	AND NOT &ByUninvoicedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	InventoryTypeDetails.Organization AS Organization,
	|	InventoryTypeDetails.BusinessOperation AS BusinessOperation,
	|	InventoryTypeDetails.InventoryType AS InventoryType,
	|	InventoryTypeDetails.GoodsOwner AS GoodsOwner,
	|	InventoryTypeDetails.Terms AS Terms,
	|	InventoryTypeDetails.Counterparty AS Counterparty,
	|	InventoryTypeDetails.Contract AS Contract,
	|	InventoryTypeDetails.Currency AS Currency,
	|	InventoryTypeDetails.VATTaxation AS VATTaxation,
	|	InventoryTypeDetails.TaxationOfOrganization AS TaxationOfOrganization,
	|	VALUE(Catalog.VendorPriceTypes.EmptyRef) AS PriceKind
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN DocumentAttributes AS InventoryTypeDetails
	|		ON TRUE
	|WHERE
	|	CatalogProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|	AND (TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|			AND NOT &ByUninvoicedGoods
	|		OR &RefillInventoryKinds)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	InventoryTypeDetails.Organization AS Organization,
	|	InventoryTypeDetails.BusinessOperation AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.Work_5) AS InventoryType,
	|	InventoryTypeDetails.GoodsOwner AS GoodsOwner,
	|	InventoryTypeDetails.Terms AS Terms,
	|	InventoryTypeDetails.Counterparty AS Counterparty,
	|	InventoryTypeDetails.Contract AS Contract,
	|	InventoryTypeDetails.Currency AS Currency,
	|	InventoryTypeDetails.VATTaxation AS VATTaxation,
	|	InventoryTypeDetails.TaxationOfOrganization AS TaxationOfOrganization,
	|	VALUE(Catalog.VendorPriceTypes.EmptyRef) AS PriceKind
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN DocumentAttributes AS InventoryTypeDetails
	|		ON TRUE
	|WHERE
	|	CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	AND (TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|			AND NOT &ByUninvoicedGoods
	|		OR &RefillInventoryKinds)
	|";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Organization, Date);
	RowFilter = New Structure("ByUninvoicedGoods", ByUninvoicedGoods);
	UseSeparateAccountingByTaxation = AccountingPoliciesTaxSettingsCached.SeparateAccountingOfGoodsByVATTaxation(
													Organization,
													Date);
	
	Query.SetParameter("Ref",						Ref);
	Query.SetParameter("Date",						Date);
	Query.SetParameter("Warehouse",						Warehouse);
	Query.SetParameter("Organization",				Organization);
	Query.SetParameter("Contract",					Contract);
	Query.SetParameter("CompanyRecipient",		CompanyRecipient);
	Query.SetParameter("VATTaxation",			VATTaxation);
	Query.SetParameter("TransferForActivity_",	TransferForActivity_);
	Query.SetParameter("TaxationOfOrganization",	AccountingParametersForOrganization.BasicTaxationVATSales);
	Query.SetParameter("Currency",						Currency);
	Query.SetParameter("ARAPCurrency",		ARAPCurrency);
	Query.SetParameter("SpecifyCCDNumbers",			SpecifyCCDNumbers);
	Query.SetParameter("BusinessOperation",		BusinessOperation);
	Query.SetParameter("ByUninvoicedGoods",		ByUninvoicedGoods);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually",	InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("TableOfGoods",				TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",			InventoryKinds.Unload(RowFilter));
	Query.SetParameter("UseSeparateAccountingByTaxation",
								UseSeparateAccountingByTaxation);
	Query.SetParameter("Posted",					Posted);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus = 14
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfGoods.Warehouse,
	|
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.Users.EmptyRef) AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableOfGoods.Purpose AS Purpose,
	|
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&VATTaxation AS VATTaxation,
	|
	|	TableOfGoods.Count AS Count
	|	
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|");
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure FillInAdditionalStockTypes(ByUninvoicedGoods)
	
	GoodsTable = Goods.Unload(New Structure("ByUninvoicedGoods", ByUninvoicedGoods));
	GoodsTable.GroupBy("ItemsLocationAttributes, Package, InventoryOwnerAttribute, ByUninvoicedGoods, 
							|Department, ToExpenseAs, ExpenseItem, DimensionOfExpenses",
							"Count, NumberOfPackages, AmountARAP, AmountVATARAP, 
							|AmountIncludingVAT, VATAmount");
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, ByUninvoicedGoods");
	
	For Each RowOfGoods In GoodsTable Do
		
		NumberOfProductsPerLine		= RowOfGoods.Count;
		NumberOfPackagesPerLine		= RowOfGoods.NumberOfPackages;
		SumOfSNDSInLine				= RowOfGoods.AmountIncludingVAT;
		AmountOfNDSVLine					= RowOfGoods.VATAmount;
		AmountOfSettlementsInLine		= RowOfGoods.AmountARAP;
		AmountOfVATSettlementsInLine	= RowOfGoods.AmountVATARAP;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(NumberOfProductsPerLine, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			If Not ByUninvoicedGoods Then
				NewRow.RecipientInventoryOwnerAttribute = RowOfGoods.InventoryOwnerAttribute;
			EndIf;
			
			NewRow.Department			= RowOfGoods.Department;
			NewRow.ToExpenseAs		= RowOfGoods.ToExpenseAs;
			NewRow.ExpenseItem			= RowOfGoods.ExpenseItem;
			NewRow.DimensionOfExpenses		= RowOfGoods.DimensionOfExpenses;
			NewRow.Package				= RowOfGoods.Package;
			NewRow.NumberOfPackages		= ?(NumberOfProductsPerLine <> 0, NumberOfPackagesPerLine * Count / NumberOfProductsPerLine, 0);
			NewRow.Count				= Count;
			NewRow.QuantityByGBRN		= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			NewRow.AmountIncludingVAT				= ?(InventoryLine.Count <> 0, Count * SumOfSNDSInLine				/ NumberOfProductsPerLine, 0);
			NewRow.VATAmount				= ?(InventoryLine.Count <> 0, Count * AmountOfNDSVLine					/ NumberOfProductsPerLine, 0);
			NewRow.AmountARAP		= ?(NumberOfProductsPerLine <> 0, Count * AmountOfSettlementsInLine		/ NumberOfProductsPerLine, 0);
			NewRow.AmountVATARAP	= ?(NumberOfProductsPerLine <> 0, Count * AmountOfVATSettlementsInLine	/ NumberOfProductsPerLine, 0);
			NewRow.ExciseTaxAmount				= Count * InventoryLine.ExciseTaxAmount / InventoryLine.Count;
			InventoryLine.Count			= InventoryLine.Count			- NewRow.Count;
			InventoryLine.QuantityByGBRN		= InventoryLine.QuantityByGBRN	- NewRow.QuantityByGBRN;
			InventoryLine.AmountIncludingVAT				= InventoryLine.AmountIncludingVAT			- NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount				= InventoryLine.VATAmount			- NewRow.VATAmount;
			InventoryLine.ExciseTaxAmount			= InventoryLine.ExciseTaxAmount			- NewRow.ExciseTaxAmount;
			NumberOfProductsPerLine			= NumberOfProductsPerLine		- NewRow.Count;
			NumberOfPackagesPerLine			= NumberOfPackagesPerLine		- NewRow.NumberOfPackages;
			SumOfSNDSInLine					= SumOfSNDSInLine				- NewRow.AmountIncludingVAT;
			AmountOfNDSVLine						= AmountOfNDSVLine				- NewRow.VATAmount;
			AmountOfSettlementsInLine			= AmountOfSettlementsInLine	- NewRow.AmountARAP;
			AmountOfVATSettlementsInLine		= AmountOfVATSettlementsInLine	- NewRow.AmountVATARAP;
			
			If NumberOfProductsPerLine = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	ProductLinesForRegistration = Goods.FindRows(New Structure("ByUninvoicedGoods", True));
	
	ThereAreOnGoodsForRegistration = ProductLinesForRegistration.Count() > 0;
	ThereAreReserves           = ProductLinesForRegistration.Count() <> Goods.Count();
	InventoryTypesAreOverfilled = False;
	
	If ThereAreReserves Then
		TempTablesManager		= TemporaryDocumentDataTables(False);
		RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
		
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, Goods);
		
		ReformatDocumentDataTableBySender(TempTablesManager);
		
		If Not Posted
			Or RefillInventoryKinds
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckProductChanges_(TempTablesManager) Then
			
			InventoryTypesAreOverfilled = True;
			
			If ThereAreOnGoodsForRegistration Then
				TypesOfInventoryForRegistration = InventoryKinds.Unload(New Structure("ByUninvoicedGoods", True));
				InventoryKinds.Clear();
			EndIf;
			
			FillParameters = ParametersForFillingInventoryTypes("Organization", True);
			
			InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																	TempTablesManager,
																	Cancel,
																	FillParameters);
			
			NamesOfSummationColumns = "Count, QuantityByGBRN, AmountIncludingVAT, VATAmount";
			AdditionalProperties.Insert("WriteDownAmountOfExciseTax", FillParameters.CalculateAmountOfExciseTax);
			NamesOfSummationColumns = NamesOfSummationColumns + ", ExciseTaxAmount";
			ExcisableGoodsAccounting.CalculateAmountOfExciseTax(ThisObject, FillParameters, , Cancel);
			InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, RecipientInventoryOwnerAttribute, CCDNumber, VATRate,
								|ByUninvoicedGoods", NamesOfSummationColumns);
			
			FillInAdditionalStockTypes(False);
			
			If ThereAreOnGoodsForRegistration Then
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfInventoryForRegistration);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ThereAreOnGoodsForRegistration Then
		
		TempTablesManager		= TemporaryDocumentDataTables(True);
		RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
		
		ReformatDocumentDataTableBySender(TempTablesManager);
		
		If Not Posted
			Or RefillInventoryKinds
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckProductChanges_(TempTablesManager) Then
			
			InventoryTypesAreOverfilled = True;
			
			FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
			FillParameters.AvailableTypesOfStocksHaveAlreadyBeenFormed = True;
			FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
			FillParameters.NameOfRemainderTable = "CompanyGoodsForTransfer";
			
			TTAvailableInventoryTypesForGoodsToTransfer(TempTablesManager);
			
			If ThereAreReserves Then
				TypesOfStocksNotRelatedToRegistration = InventoryKinds.Unload(New Structure("ByUninvoicedGoods", False));
				InventoryKinds.Clear();
			EndIf;
			
			InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																	TempTablesManager,
																	Cancel,
																	FillParameters);
			
			For Each RowOfTables In InventoryKinds Do
				RowOfTables.ByUninvoicedGoods = True;
			EndDo;
			
			NamesOfSummationColumns = "Count, QuantityByGBRN, AmountIncludingVAT, VATAmount";
			AdditionalProperties.Insert("WriteDownAmountOfExciseTax", FillParameters.CalculateAmountOfExciseTax);
			NamesOfSummationColumns = NamesOfSummationColumns + ", ExciseTaxAmount";
			ExcisableGoodsAccounting.CalculateAmountOfExciseTax(ThisObject, FillParameters, , Cancel);
			InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, RecipientInventoryOwnerAttribute, CCDNumber, VATRate,
								|ByUninvoicedGoods", NamesOfSummationColumns);
			
			FillInAdditionalStockTypes(True);
			
			If ThereAreReserves Then
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStocksNotRelatedToRegistration);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Not InventoryTypesAreOverfilled
		And InventoryKinds.Find(Catalogs.InventoryKinds.EmptyRef(), "RecipientInventoryOwnerAttribute") <> Undefined Then
		
		ExceptionText = "vi = 'Chưa điền cột bổ sung trong phần bảng ""Dạng vật tư"".';
						|ru = 'Не заполнены дополнительные колонки в табличной части ""Виды запасов"".';
						|en = 'Additional columns in the ""Inventory owner attributes"" table are not filled in.';
						|it = 'Le colonne aggiuntive nella tabella ""Tipi di scorte"" non sono compilate.';
						|pl = 'Nie wypełniono dodatkowych kolumn w sekcji tabelarycznej ""Rodzaje zapasów"".';
						|tr = '""Stok türleri"" tablo bölümündeki ek sütunlar doldurulmadı.'";
		
		Raise ExceptionText;
		
	EndIf;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.CustomerInvoiceIntercompany.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.CustomerInvoiceIntercompany.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Warehouse,
																		Department,
																		Partner);
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting);
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckCorrectnessOfIndicationOfExcisableGoodsInTabularPartOfGoods(Cancel)
	
	If Not AccountingPoliciesTaxSettingsCached.SeparateAccountingOfGoodsByVATTaxation(Organization, Date) Then
		Return;
	EndIf;
	
	If TransferForActivity_ <> Enums.VATTaxationTypes.SaleIsSubjectToUTII Then
		Return;
	EndIf;
	
	Query = New Query("
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.LineNumber AS LineNumber
		|INTO
		|	TemporaryTableOfGoods_
		|FROM
		|	&Goods AS Goods"
		+ Common.QueryBatchSeparator()
		+ ExcisableGoodsAccounting.QueryTextTTExcisableItems("TemporaryTableOfGoods_")
		+ Common.QueryBatchSeparator() + "
		|SELECT
		|	TemporaryTableOfGoods_.LineNumber AS LineNumber
		|FROM
		|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
		|		INNER JOIN TTExcisableItems
		|		ON TemporaryTableOfGoods_.Products = TTExcisableItems.Products");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,LineNumber"));
	Query.SetParameter("TransferUnderActivityTaxableENVD", (TransferForActivity_ = Enums.VATTaxationTypes.SaleIsSubjectToUTII));
	Query.SetParameter("Date", Date);
	Query.SetParameter("Country", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
	QueryResult = Query.ExecuteBatch();
	
	If Not QueryResult[1].IsEmpty() Then
	
		Selection = QueryResult[1].Select();
		
		While Selection.Next() Do
			
			ErrorText = NStr("vi = 'Khi chuyển sang hoạt động chịu thuế khoán, cấm chọn hàng hóa chịu thuế tiêu thụ đặc biệt tại dòng %LineNumber% của ""Hàng hóa""';
							|ru = 'При передаче под деятельность, облагаемую ЕНВД, запрещено выбирать подакцизный товар в строке %LineNumber% списка ""Товары""';
							|en = 'You''re not allowed to select excisable goods in line %LineNumber% of the Item list while transferring goods for activities subject to UTII'; fa = 'You''re not allowed to select excisable goods in line %LineNumber% of the Item list while transferring goods for activities subject to UTII';
							|it = 'In caso di consegna per attività soggetta all''imposta unica sui redditi imputabili è vietato selezionare la merce soggetta ad accisa nella riga %LineNumber% dell''elenco ""Merci""';
							|pl = 'Przy przenoszeniu do działalności podlegającej JPD, zabrania się wyboru towarów podlegających podatkowi akcyzowemu w wierszu %LineNumber% listy ""Wiersze pozycji""';
							|tr = 'EGTV''ye tabi faaliyetler kapsamında transfer yaparken, ""Ürünler"" listesinin %LineNumber% satırında vergiye tabi ürünlerin seçilmesi yasaktır'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%",  Selection.LineNumber);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "Products"),
				,
				Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CheckBankAccounts(Cancel)
	
	If ValueIsFilled(CompanyBankAccount)
	   And ValueIsFilled(RecipientCompanyBankAccount)
	Then
		
		SenderSCurrency = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(CompanyBankAccount).Currency;
		RecipientSCurrency = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(RecipientCompanyBankAccount).Currency;
		If SenderSCurrency <> RecipientSCurrency Then
			Text = NStr("vi = 'Tiền tệ trong tài khoản của người nhận không tương ứng với tiền tệ trong tài khoản của người gửi';
						|ru = 'Валюта счета получателя не соответствует валюте счета отправителя';
						|en = 'Beneficiary account currency does not match the sender account currency'; fa = 'Beneficiary account currency does not match the sender account currency';
						|it = 'La valuta del conto di beneficiario non corrisponde alla valuta del conto del mittente';
						|pl = 'Waluta konta odbiorcy nie jest zgodna z walutą rachunku nadawcy';
						|tr = 'Alıcının hesabındaki para biriminin gönderenin hesabındaki para birimiyle eşleşmiyor'");
			Common.MessageToUser(
				Text,
				ThisObject,
				"RecipientCompanyBankAccount",
				,
				Cancel);
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(CompanyBankAccount)
	   And ValueIsFilled(CounterpartyBankAccount)
	Then
		
		OrganizationSCurrency = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(CompanyBankAccount).Currency;
		CounterpartyCurrency = Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(CounterpartyBankAccount).Currency;
		If OrganizationSCurrency <> CounterpartyCurrency Then
			Text = NStr("vi = 'Tiền tệ tài khoản ngân hàng của đối tác không phù hợp với tiền tệ tài khoản người gửi';
						|ru = 'Валюта банковского счета контрагента не соответствует валюте счета отправителя';
						|en = 'Currency of the counterparty bank account does not match the sender account currency'; fa = 'Currency of the counterparty bank account does not match the sender account currency';
						|it = 'La valuta del conto bancario del contraente non corrisponde alla valuta del conto del mittente';
						|pl = 'Waluta konta banku kontrahenta nie jest zgodna z walutą konta nadawcy';
						|tr = 'Cari hesap banka hesabının para biriminin gönderenin hesabındaki para birimiyle eşleşmiyor'");
			Common.MessageToUser(
				Text,
				ThisObject,
				"CounterpartyBankAccount",
				,
				Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckFillingOfDivisionInTablePart(Cancel)
	
	DocumentGoods = Goods.Unload(,"LineNumber, Products, Department, ToExpenseAs");
	ThisIsACommission     = BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectProducts.LineNumber   AS LineNumber,
	|	ObjectProducts.Products  AS Products,
	|	ObjectProducts.Department AS Department,
	|	ObjectProducts.ToExpenseAs AS ToExpenseAs
	|INTO Goods
	|FROM
	|	&ObjectProducts AS ObjectProducts
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.LineNumber  AS LineNumber
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON Goods.Products = CatProducts.Ref
	|WHERE
	|	CatProducts.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
	|		AND &ThisIsACommission
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.LineNumber AS LineNumber
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON Goods.Products = CatProducts.Ref
	|WHERE
	|	(CatProducts.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
	|		OR CatProducts.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|		AND Goods.ToExpenseAs)
	|	AND Goods.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|	AND NOT &ThisIsACommission
	|	AND &UseBusinessUnits";
	
	Query.SetParameter("ObjectProducts",             DocumentGoods);
	Query.SetParameter("ThisIsACommission",               ThisIsACommission);
	Query.SetParameter("UseBusinessUnits", GetFunctionalOption("UseBusinessUnits"));
	
	ResultsArray = Query.ExecuteBatch();
	
	QueryResult = ResultsArray[1]; // QueryResult
	ErrorSelectionProductType = QueryResult.Select();
	
	While ErrorSelectionProductType.Next() Do
		ErrorText = NStr("vi = 'Trong chứng từ dạng ""%BusinessTransaction%"" không thể chỉ ra dịch vụ và công việc. Cần xóa mặt hàng ""%Products%"" từ dòng %LineNumber% trong danh sách ""Hàng hóa"".';
						|ru = 'В документе вида ""%BusinessTransaction%"" нельзя указывать услуги и работы. Необходимо удалить номенклатуру ""%Products%"" из строки %LineNumber% списка ""Товары"".';
						|en = 'You cannot specify services and labor in the ""%BusinessTransaction%"" document kind. Delete the ""%Products%"" items from line %LineNumber% of the Item list.'; fa = 'You cannot specify services and labor in the ""%BusinessTransaction%"" document kind. Delete the ""%Products%"" items from line %LineNumber% of the Item list.';
						|it = 'Nel documento del tipo ""%BusinessTransaction%"" non è consentito indicare servizi e lavori. È necessario cancellare la nomenclatura ""%Products%"" dalla riga %LineNumber% dall''elenco ""Merci"".';
						|pl = 'W dokumencie typu ""%BusinessTransaction%"" nie można wskazać usług i prac. Musisz usunąć nomenklaturę ""%Products%"" z listy %LineNumber%""Wiersze pozycji"".';
						|tr = 'Hizmetler ve işler ""%BusinessTransaction%"" tipi belgede belirtilemez. ""Ürünler"" listesinin %LineNumber% satırından ""%Products%"" öğesini silmek gerekir.'");
		ErrorText = StrReplace(ErrorText, "%BusinessTransaction%",  Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany);
		ErrorText = StrReplace(ErrorText, "%Products%", ErrorSelectionProductType.Products);
		ErrorText = StrReplace(ErrorText, "%LineNumber%",  ErrorSelectionProductType.LineNumber);
		
		TSField = CommonClientServer.PathToTabularSection("Goods", ErrorSelectionProductType.LineNumber, "Products");
		
		Common.MessageToUser(ErrorText, ThisObject, TSField, , Cancel);
	EndDo;
	
	QueryResult = ResultsArray[2]; // QueryResult
	SelectingUnitErrors = QueryResult.Select();
	
	While SelectingUnitErrors.Next() Do
		ErrorText = NStr("vi = 'Cần điền bộ phận nhận đối với ""%Products%"" tại dòng %LineNumber% trong danh sách ""Hàng hóa""';
						|ru = 'Необходимо заполнить подразделение-получатель для позиции ""%Products%"" в строке %LineNumber% списка ""Товары""';
						|en = 'Fill in recipient business unit for position ""%Products%"" in line %LineNumber% of the Item list'; fa = 'Fill in recipient business unit for position ""%Products%"" in line %LineNumber% of the Item list';
						|it = 'È necessario compilare il reparto-destinatario per la posizione ""%Products%"" nella riga %LineNumber% dell''elenco ""Merci""';
						|pl = 'Konieczne jest wypełnienie działu odbiorcy dla pozycji ""%Products%"" w wierszu ""%LineNumber%"" na liście ""Wiersze pozycji""';
						|tr = '""Ürünler"" listesinin %LineNumber% satırında ""%Products%"" kalemi için alıcı departmanının doldurulması gerekmektedir'");
		ErrorText = StrReplace(ErrorText, "%Products%", SelectingUnitErrors.Products);
		ErrorText = StrReplace(ErrorText, "%LineNumber%",  SelectingUnitErrors.LineNumber);
		
		TSField = CommonClientServer.PathToTabularSection("Goods", SelectingUnitErrors.LineNumber, "Department");
		
		Common.MessageToUser(ErrorText, ThisObject, TSField, , Cancel);
	EndDo;
	
EndProcedure

Procedure CheckAmountFilling(Cancel)
	
	Query = New Query("
	|SELECT
	|	ObjectProducts.LineNumber,
	|	ObjectProducts.Products,
	|	ObjectProducts.Price,
	|	ObjectProducts.Sum,
	|	ObjectProducts.AmountIncludingVAT
	|INTO Goods
	|FROM
	|	&ObjectProducts AS ObjectProducts
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber,
	|	Goods.Products,
	|
	|	CASE WHEN Goods.Price = 0 
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS PriceNotFilledIn,
	|
	|	CASE WHEN Goods.Sum = 0 
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS AmountNotFilledIn,
	|
	|	CASE WHEN Goods.AmountIncludingVAT = 0 
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS AmountNotFilledWithVAT
	|FROM
	|	Goods
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatalogProducts
	|	ON
	|		Goods.Products = CatalogProducts.Ref
	|WHERE
	|	CatalogProducts.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND (Goods.Price = 0 OR Goods.Sum = 0 OR Goods.AmountIncludingVAT = 0)
	|");
	
	Query.SetParameter("ObjectProducts", Goods.Unload(,"LineNumber, Products, Price, Sum, AmountIncludingVAT"));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ErrorTextTemplate = NStr("vi = 'Chưa điền ""%ColumnName%"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнена ""%ColumnName%"" в строке %LineNumber% списка ""Товары""';
								|en = '""%ColumnName%"" is required in line %LineNumber% of the Item list'; fa = '""%ColumnName%"" is required in line %LineNumber% of the Item list';
								|it = 'Non è compilata %ColumnName% nella riga %LineNumber% dell''elenco ""Merci""';
								|pl = 'Niewypełnione ""%ColumnName%"" w wierszu %LineNumber% na liście ""Wiersze pozycji""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""%ColumnName%"" eksik'");
		ErrorTextTemplate = StrReplace(ErrorTextTemplate, "%LineNumber%",  Selection.LineNumber);
		
		If Selection.PriceNotFilledIn Then
			ReportErrorFillingInAmounts(ErrorTextTemplate, Selection.LineNumber, "Price", NStr("vi = 'Đơn giá';
																								|ru = 'Цена';
																								|en = 'Price'; fa = 'قیمت';
																								|it = 'Prezzo';
																								|pl = 'Cena';
																								|tr = 'Fiyat'"), Cancel);
		EndIf;
		If Selection.AmountNotFilledIn Then
			ReportErrorFillingInAmounts(ErrorTextTemplate, Selection.LineNumber, "Sum", NStr("vi = 'Tổng số';
																							|ru = 'Сумма';
																							|en = 'Amount'; fa = 'مبلغ';
																							|it = 'Importo';
																							|pl = 'Wartość';
																							|tr = 'Tutar'"), Cancel);
		EndIf;
		If Selection.AmountNotFilledWithVAT Then
			ReportErrorFillingInAmounts(ErrorTextTemplate, Selection.LineNumber, "AmountIncludingVAT", NStr("vi = 'Số tiền gồm thuế GTGT';
																											|ru = 'Сумма с НДС';
																											|en = 'Amount including VAT'; fa = 'مبلغ با احتساب مالیات بر ارزش افزوده';
																											|it = 'Importo IVA inclusa';
																											|pl = 'Wartość z VAT';
																											|tr = 'KDV dahil tutar'"), Cancel);
		EndIf;
	EndDo;
EndProcedure

Procedure ReportErrorFillingInAmounts(ErrorTextTemplate, LineNumber, FieldName, FieldTitle, Cancel)
	ErrorText = StrReplace(ErrorTextTemplate, "%ColumnName%", FieldTitle);
	Common.MessageToUser(
		ErrorText,
		ThisObject,
		CommonClientServer.PathToTabularSection("Goods", LineNumber, FieldName),
		,
		Cancel);
EndProcedure

Procedure CheckOrganizations(Cancel)
	
	If ValueIsFilled(Organization)
		And ValueIsFilled(CompanyRecipient) Then
		
		If Organization = CompanyRecipient Then
			
			Text = NStr("vi = 'Một doanh nghiệp không thể đồng thời là nơi gửi và nơi nhận';
						|ru = 'Одна и та же организация не может являться отправителем и получателем одновременно';
						|en = 'Same company cannot be both a sender and a recipient'; fa = 'Same company cannot be both a sender and a recipient';
						|it = 'La stessa società non può essere mittente e destinatario contemporaneamente';
						|pl = 'Jedna i ta sama firma nie może jednocześnie być nadawcą i odbiorcą';
						|tr = 'Aynı iş yeri aynı anda hem gönderici hem de alıcı olamaz'");
			Common.MessageToUser(
				Text,
				ThisObject,
				"Organization",
				,
				Cancel);
			
		ElsIf GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets")
			And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Organization, CompanyRecipient) Then
			
			Text = NStr("vi = 'Doanh nghiệp nhận hàng không được phép có quan hệ với doanh nghiệp gửi hàng theo cơ cấu tổ chức.';
						|ru = 'Организация-получатель не должна быть взаимосвязана с организацией-отправителем по организационной структуре.';
						|en = 'Receiving company should not be interrelated to the shipping company by the organizational structure.'; fa = 'Receiving company should not be interrelated to the shipping company by the organizational structure.';
						|it = 'La società-destinatario non deve essere interconnessa con la società-mittente per la struttura organizzativa.';
						|pl = 'Firma odbiorca nie powinna być wzajemnie powiązana z firmą nadawcą według struktury organizacyjnej.';
						|tr = 'Alıcı iş yeri, iş yeri yapısı bakımından gönderen iş yeri ile bağlantılı olmamalıdır.'");
			Common.MessageToUser(
				Text,
				ThisObject,
				"CompanyRecipient",
				,
				Cancel);
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure CheckSalesOption(NotCheckedAttributeArray)
	
	If Not ValueIsFilled(SaleRegistrationOption) Then
		
		FilledInVersionOfSale = DefaultSalesOption();
		If ValueIsFilled(FilledInVersionOfSale) Then
			ThisObject.AdditionalProperties.Insert("FilledInVersionOfSale", FilledInVersionOfSale);
			NotCheckedAttributeArray.Add("SaleRegistrationOption");
		EndIf;
		
	EndIf;
	
EndProcedure

Function DefaultSalesOption()
	
	FilledInVersionOfSale = Enums.SalesRegistrationOptions.CustomerInvoice;
	
	If Not GetFunctionalOption("UseDeedsOfTransfer") Then
		FilledInVersionOfSale = Enums.SalesRegistrationOptions.CustomerInvoice;
	Else
		Query = New Query(
		"SELECT
		|	Goods.Products AS Products
		|INTO
		|	TTProducts_1
		|FROM
		|	&Goods AS Goods
		|;
		|SELECT
		|	Goods.Products.Ref
		|FROM
		|	TTProducts_1 AS Goods
		|WHERE
		|	Goods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer)");
		
		Query.SetParameter("Goods", Goods.Unload(,"Products"));
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			FilledInVersionOfSale = Enums.SalesRegistrationOptions.CustomerInvoice;
		ElsIf QueryResult.Unload().Count() = Goods.Count() Then
			FilledInVersionOfSale = Enums.SalesRegistrationOptions.DeedOfTransfer;
		EndIf;
	EndIf;
	
	Return FilledInVersionOfSale;
	
EndFunction

Function QueryTextStockBalanceForTransfer()
	Return 
	"SELECT
	|	ProductsSold.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ProductsSold.SellerInventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|	ProductsSold.CCDNumber AS CCDNumber,
	|	ProductsSold.CountTurnover AS CountBalance
	|INTO ProductsSold
	|FROM
	|	AccumulationRegister.CompanyGoodsForTransfer.BalanceAndTurnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Period,
	|			,
	|			CompanyOwner = &Organization
	|				AND SellerInventoryOwnerAttribute.Organization = &CompanyRecipient
	|				AND SellerInventoryOwnerAttribute.InventoryType = &InventoryType
	|				AND &Warehouse IN (ItemsLocationAttributes.StorageLocation, VALUE(Catalog.Warehouses.EmptyRef))
	|				AND (SellerInventoryOwnerAttribute.VATTaxation = &TransferForActivity_
	|					OR SellerInventoryOwnerAttribute.VATTaxation = VALUE(Enum.VATTaxationTypes.EmptyRef))) AS ProductsSold
	|WHERE
	|	ProductsSold.CountTurnover > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsSold.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ProductsSold.SellerInventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|	ProductsSold.CCDNumber AS CCDNumber,
	|	ProductsSold.CountBalance AS CountBalance
	|INTO ProductsSoldBalance
	|FROM
	|	AccumulationRegister.CompanyGoodsForTransfer.Balance(
	|			,
	|			CompanyOwner = &Organization
	|				AND SellerInventoryOwnerAttribute.Organization = &CompanyRecipient
	|				AND SellerInventoryOwnerAttribute.InventoryType = &InventoryType
	|				AND &Warehouse IN (ItemsLocationAttributes.StorageLocation, VALUE(Catalog.Warehouses.EmptyRef))
	|				AND (SellerInventoryOwnerAttribute.VATTaxation = &TransferForActivity_
	|					OR SellerInventoryOwnerAttribute.VATTaxation = VALUE(Enum.VATTaxationTypes.EmptyRef))) AS ProductsSold
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	SellerInventoryOwnerAttribute,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(ProductsSold.ItemsLocationAttributes.Products, VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	ISNULL(ProductsSold.ItemsLocationAttributes.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
	|	ISNULL(ProductsSold.ItemsLocationAttributes.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	ISNULL(ProductsSold.ItemsLocationAttributes.Purpose, VALUE(Catalog.Assignments.EmptyRef)) AS Purpose,
	|	ISNULL(ProductsSold.SellerInventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner, VALUE(Catalog.InventoryKinds.EmptyRef)) AS InventoryOwnerAttribute,
	|	ISNULL(ProductsSold.SellerInventoryOwnerAttribute, VALUE(Catalog.InventoryKinds.EmptyRef)) AS RecipientInventoryOwnerAttribute,
	|	ISNULL(ProductsSold.CCDNumber, VALUE(Catalog.CCDNumbers.EmptyRef)) AS CCDNumber,
	|	CASE
	|		WHEN ISNULL(ProductsSoldBalance.CountBalance, 0) < ProductsSold.CountBalance
	|			THEN ISNULL(ProductsSoldBalance.CountBalance, 0)
	|		ELSE ProductsSold.CountBalance
	|	END AS Count
	|FROM
	|	ProductsSold AS ProductsSold
	|		LEFT JOIN ProductsSoldBalance AS ProductsSoldBalance
	|		ON ProductsSold.ItemsLocationAttributes = ProductsSoldBalance.ItemsLocationAttributes
	|			AND ProductsSold.SellerInventoryOwnerAttribute = ProductsSoldBalance.SellerInventoryOwnerAttribute
	|			AND ProductsSold.CCDNumber = ProductsSoldBalance.CCDNumber
	|WHERE
	|	ISNULL(ProductsSoldBalance.CountBalance, 0) > 0
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Purpose,
	|	InventoryOwnerAttribute,
	|	RecipientInventoryOwnerAttribute,
    |	CCDNumber";
	
EndFunction

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, VATTaxation, Warehouse, BusinessOperation";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate AS VATRate,
	|		TableOfGoods.CCDNumber AS CCDNumber,
	|		TableOfGoods.ToExpenseAs AS ToExpenseAs,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.AmountARAP AS AmountARAP,
	|		TableOfGoods.AmountVATARAP AS AmountVATARAP
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		CASE
	|			WHEN &SpecifyCCDNumbers
	|				THEN TableTypesOfStocks_.CCDNumber
	|			ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|		END AS CCDNumber,
	|		TableTypesOfStocks_.ToExpenseAs AS ToExpenseAs,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount AS VATAmount,
	|		-TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|		-TableTypesOfStocks_.AmountVATARAP AS AmountVATARAP
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.CCDNumber,
	|	TableOfGoods.ToExpenseAs
	|
	|HAVING
	|	(SUM(TableOfGoods.Count) <> 0
	|		OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|		OR SUM(TableOfGoods.VATAmount) <> 0
	|		OR SUM(TableOfGoods.AmountARAP) <> 0
	|		OR SUM(TableOfGoods.AmountVATARAP) <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)";
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("SpecifyCCDNumbers", SpecifyCCDNumbers);
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure ReformatDocumentDataTableBySender(TempTablesManager)
	
	Query = New Query;
	Query.Text = "
	|DROP DocumentDataTable
	|;
	|
	|//////////////////////////////////////
	|SELECT
	|	Table.Date AS Date,
	|	Table.Organization AS Organization,
	|	Table.Warehouse AS Warehouse,
	|	Table.Partner AS Partner,
	|	Table.Counterparty AS Counterparty,
	|	Table.Terms AS Terms,
	|	Table.Contract AS Contract,
	|	Table.Currency AS Currency,
	|	Table.VATTaxation AS VATTaxation,
	|	Table.BusinessOperation AS BusinessOperation,
	|	Table.ThereAreTransactionsInTablePart AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|FROM SenderDocumentDataTable AS Table
	|;
	|
	|//////////////////////////////////////
	|DROP SenderDocumentDataTable";
	
	Query.TempTablesManager = TempTablesManager;
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
EndProcedure

Function ParametersForFillingInventoryTypes(CompanyFieldName1, FillingStockTypes)
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.CompanyFieldName1 = CompanyFieldName1;
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	
	If FillingStockTypes Then
		FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
		FillParameters.CorTypesOfStocks = CommonClientServer.CollapseArray(Goods.UnloadColumn("InventoryOwnerAttribute"));
		
		If Not BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany Then
			FillParameters.SelectionOfStockTypes_.VATTaxation = VATTaxation;
			VATAccountingERP.ParametersForFillingTypesOfStocksForTaxation(FillParameters.SelectionOfStockTypes_,
																		ThisObject[CompanyFieldName1],
																		Date,
																		VATTaxation);
			VATAccountingERP.SetParametersForFillingInventoryTypesForCommissionSales(FillParameters);
		EndIf;
	EndIf;
	
	If CompanyFieldName1 = "Organization" Then
		FillParameters.WhenSelectingByIntercampanyExcludeOrganizations = CompanyRecipient;
		If Documents.CustomerInvoiceIntercompany.ExcisableGoodsAreUsed(ThisObject) Then
			FillParameters.CalculateAmountOfExciseTax = True;
			FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
		EndIf;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany Then
		InventoriesServer.ToSupplementSelectionOfInventoryOwnerAttributesByTypeOfInventory(FillParameters.SelectionOfStockTypes_,
															Enums.InventoryTypes.Work_5);
	EndIf;
	
	Return FillParameters;
	
EndFunction

Procedure TTAvailableInventoryTypesForGoodsToTransfer(TempTablesManager)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Sender AS ForCompany,
	|	PossibleTypesOfStocks.Ref AS InventoryOwnerAttribute,
	|	FALSE AS SelectionAccordingToCommitteeSVATRate,
	|	UNDEFINED AS CommitteeSVATRate
	|INTO AvailableTypesOfStocks
	|FROM
	|	Catalog.InventoryKinds AS PossibleTypesOfStocks
	|WHERE
	|	PossibleTypesOfStocks.SaleOfAnotherCompanyInventory
	|	AND PossibleTypesOfStocks.Organization = &Recipient
	|	AND PossibleTypesOfStocks.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization = &Sender
	|
	|INDEX BY
	|	InventoryOwnerAttribute";
	
	Query.SetParameter("Recipient", CompanyRecipient);	
	Query.SetParameter("Sender", Organization);
	
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure FillInTransferUnderActivity()
	
	FillParameters = Documents.CustomerInvoiceIntercompany.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(TransferForActivity_, FillParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
