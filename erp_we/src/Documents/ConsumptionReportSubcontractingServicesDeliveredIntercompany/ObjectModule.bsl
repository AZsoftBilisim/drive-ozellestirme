#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.ConsumptionReportSubcontractingServicesDeliveredIntercompany - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.VendorInvoice.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingForm();
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.FillOutTypesOfStockWhenExchanging(ThisObject, Cancel, DocumentTables);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	BasisType = TypeOf(FillingData);
	
	If BasisType = Type("Structure") Then
		
		FillPropertyValues(ThisObject, FillingData);
		
		// If a Month is transferred, then this is filling in by order.
		If CommonClientServer.HasAttributeOrObjectProperty(FillingData, "Month") Then
			
			Date = EndOfMonth(FillingData.Month);
			
			RequestParametersForBalances = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ParametersForRequestingReportBalancesForRegistration();
			FillPropertyValues(RequestParametersForBalances, FillingData);
			
			Query = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.RequestRemainingReportsToBeProcessed(RequestParametersForBalances);
			Query = RequestSchemes.ChangeAliasOfSelectionFieldInRequest(Query, "Products",   "MainProductProducts");
			Query = RequestSchemes.ChangeAliasOfSelectionFieldInRequest(Query, "Characteristic", "MainProductCharacteristic");
			
			Goods.Load(Query.Execute().Unload());
			
		EndIf;
		
	EndIf;
	
	InitializeDocument(FillingData);
	
	If Not Goods.Count() = 0 Then
		
		SelectingTypeOfPrices = New Structure;
		SelectingTypeOfPrices.Insert("UseForIntercompanySales", True);
		SelectingTypeOfPrices.Insert("PriceIncludesVAT",                           PriceIncludesVAT);
		SelectingTypeOfPrices.Insert("Status",                                    Enums.StatusesOfPriceTypeValidity.Valid);
		
		DefaultPriceType = Undefined;
		DefaultPriceType = Catalogs.TypesOfPrices.DefaultPriceType(DefaultPriceType, SelectingTypeOfPrices);
		
		If ValueIsFilled(DefaultPriceType) Then
			For Each CurrentData In Goods Do
				CurrentData.PriceKind = DefaultPriceType;
			EndDo;
		EndIf;
		
	EndIf;
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	MaximumRowCodeGoods = 0;
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods");
	
	InitializeDocument();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckOrganizations(Cancel);
	CheckBankAccounts(Cancel);
	
	#Region Goods
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	CheckProducts(NotCheckedAttributeArray, Cancel);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	// The end of the selection of articles and analytics.
	
	#EndRegion
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	DocumentAmount = Goods.Total("AmountIncludingVAT");
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	// The end of the selection of articles and analytics.
	
	RegistrationParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "Goods", "MaximumRowCodeGoods");
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods");
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingForm();
	EndIf;
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
	GLAccountSettingsServer.BeforeWrite(ThisObject, Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.AccountingAccountSettings_());
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RegistrationParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RegistrationParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocumentBeforeFillingItOut()
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany;
	EndIf;
	
	Organization         = SettingsValueCached.GetDefaultOrganization(Organization);
	Currency               = SettingsValueCached.ManagementAccountingCurrency();
	ARAPCurrency = Currency;
	
	Author = Users.CurrentUser();
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	If ValueIsFilled(Contract) Then
		
		FieldsNames = "LineOfBusiness, NameForPrinting, ARAPObjectSettings, Number, Date,
			|ARAPCurrency, ForeignCurrencyTransaction";
		ContractDetails_       = Common.ObjectAttributesValues(Contract, FieldsNames);
		LineOfBusiness = ContractDetails_.LineOfBusiness;
		ARAPObjectSettings         = ContractDetails_.ARAPObjectSettings;
		Basis               = ContractDetails_.NameForPrinting;
		BaseDocumentNumber          = ContractDetails_.Number;
		ReferenceDocumentDateForPrintForms           = ContractDetails_.Date;
		ARAPCurrency    = ContractDetails_.ARAPCurrency;
		ForeignCurrencyTransaction           = ContractDetails_.ForeignCurrencyTransaction;
		
	EndIf;
	
	If Not ValueIsFilled(VATTaxation) Then
		CompleteVATTaxation();
	EndIf;
	
	If Not ValueIsFilled(SubcontractorAccount) Or Not ValueIsFilled(MaterialProviderAccount) Then
		SalesServer.FillInBankAccountsUnderAgreement(Contract,
			?(ValueIsFilled(SubcontractorAccount), Undefined, SubcontractorAccount),
			?(ValueIsFilled(MaterialProviderAccount), Undefined, MaterialProviderAccount));
	EndIf;
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = ComplCurrency;
	SubcontractorAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		SubcontractorAccount);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(MaterialProvider);
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = ComplCurrency;
	MaterialProviderAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		MaterialProviderAccount);
	
	Department = SettingsValueCached.UserDivision(Author, Department);
	
	If Not ValueIsFilled(PaymentDate) Then
		PaymentDate = Date;
	EndIf;
	
	SubcontractorFinancialAccountingGroup = Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation);
	MaterialProviderFinancialAccountingGroup      = Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(MaterialProvider, ARAPCurrency, BusinessOperation, True);
	
	If Not ValueIsFilled(CostsAllocationMethod) Then
		CostsAllocationMethod = Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

// Fills in the analytics of inventory items in the tabular part of the document that store information about goods.
//
Procedure FillInProductTrackingForm()
	
	PlacesOfAccounting =
		InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
			Enums.StorageLocationTypes.Department,
			Undefined,
			Department,
			Undefined);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Purpose          = "";
	FieldsNames.Series               = "";
	FieldsNames.BatchesIndicationStatus = "";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(Goods, PlacesOfAccounting, FieldsNames);
	
	ConsumptionReportSubcontractingServicesDeliveredIntercompanyLocalization.FillInProductTrackingForm(ThisObject);
	
EndProcedure

#EndRegion

#Region VATAccounting

Procedure CompleteVATTaxation()
	
	FillParameters = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ParametersForFillingInVATTaxation_(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure

#EndRegion

#Region Checks

Procedure CheckOrganizations(Cancel)
	
	If ValueIsFilled(Organization)
		And ValueIsFilled(MaterialProvider) Then
		
		If MaterialProvider = Organization Then
			
			MessageText = NStr("vi = 'Doanh nghiệp-người đặt gia công trùng với doanh nghiệp-người nhận gia công.';
								|ru = 'Организация-давалец совпадает с организацией-переработчиком.';
								|en = 'Material provider company and the subcontractor company are the same.'; fa = 'Material provider company and the subcontractor company are the same.';
								|it = 'Организация-давалец совпадает с организацией-переработчиком.';
								|pl = 'Material provider company and the subcontractor company are the same.';
								|tr = 'Tedarikçi iş yeri, fason üretici iş yeri ile aynıdır.'");
			Common.MessageToUser(MessageText, ThisObject, "MaterialProvider",, Cancel);
			
		EndIf;
		
		If Not MaterialProvider = Organization
			And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Organization, MaterialProvider) Then
			
			MessageText = NStr("vi = 'Doanh nghiệp đặt gia công không được phép có quan hệ với doanh nghiệp nhận gia công về cấu trúc tổ chức.';
								|ru = 'Организация-давалец не должна быть взаимосвязана с организацией-переработчиком по организационной структуре.';
								|en = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.'; fa = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.';
								|it = 'Организация-давалец не должна быть взаимосвязана с организацией-переработчиком по организационной структуре.';
								|pl = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.';
								|tr = 'Tedarikçi iş yeri, iş yeri yapısı bakımından fason üretici iş yeri ile bağlantılı olmamalıdır.'");
			Common.MessageToUser(MessageText, ThisObject, "MaterialProvider",, Cancel);
			
		EndIf;
		
		CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Organization, MaterialProvider);
		
		If Not CheckStructure.CurrenciesDoNotMatch Then
			ErrorText = NStr("vi = 'Tiền tệ của kế toán tài chính ""%1"" và ""%2"" cần trùng nhau.';
							|ru = 'Валюты регламентированного учета ""%1"" и ""%2"" должны совпадать.';
							|en = 'The %1 and %2 local accounting currencies must be the same.'; fa = 'The %1 and %2 local accounting currencies must be the same.';
							|it = 'Валюты регламентированного учета ""%1"" и ""%2"" должны совпадать.';
							|pl = 'The %1 and %2 local accounting currencies must be the same.';
							|tr = '""%1"" ve ""%2"" yerel muhasebe para birimleri eşleşmelidir.'");
			ErrorText = StrTemplate(ErrorText, Organization, MaterialProvider);
			Common.MessageToUser(ErrorText, ThisObject, "MaterialProvider",, Cancel);
		EndIf;
		
		If Not CheckStructure.CountriesMatch Then
			ErrorText = NStr("vi = 'Trang đăng ký ""%1"" và ""%2"" cần trùng nhau.';
							|ru = 'Страны регистрации ""%1"" и ""%2"" должны совпадать.';
							|en = 'The %1 and %2 countries of residence must be the same.'; fa = 'The %1 and %2 countries of residence must be the same.';
							|it = 'Страны регистрации ""%1"" и ""%2"" должны совпадать.';
							|pl = 'The %1 and %2 countries of residence must be the same.';
							|tr = '""%1"" ve ""%2"" kayıt ülkeleri eşleşmelidir.'");
			ErrorText = StrTemplate(ErrorText, Organization, MaterialProvider);
			Common.MessageToUser(ErrorText, ThisObject, "MaterialProvider",, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckBankAccounts(Cancel)
	
	If ValueIsFilled(SubcontractorAccount)
		And ValueIsFilled(MaterialProviderAccount) Then
		
		SenderSCurrency = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(SubcontractorAccount).Currency;
		RecipientSCurrency = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(MaterialProviderAccount).Currency;
		If SenderSCurrency <> RecipientSCurrency Then
			Text = NStr("vi = 'Tiền tệ trong tài khoản của người đặt gia công không tương ứng với tiền tệ trong tài khoản của người nhận gia công';
						|ru = 'Валюта счета давальца не соответствует валюте счета переработчика';
						|en = 'Account currency of the material provider does not match the subcontractor account currency'; fa = 'Account currency of the material provider does not match the subcontractor account currency';
						|it = 'Валюта счета давальца не соответствует валюте счета переработчика';
						|pl = 'Account currency of the material provider does not match the subcontractor account currency';
						|tr = 'Tedarikçinin hesabının para birimi, fason üreticinin hesabının para birimiyle eşleşmiyor'");
			Common.MessageToUser(Text, ThisObject, "MaterialProviderAccount",, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckProducts(NotCheckedAttributeArray, Cancel)
	
	NotCheckedAttributeArray.Add("Goods.VATRate");
	NotCheckedAttributeArray.Add("Goods.ProductCostElement");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Goods.LineNumber        AS LineNumber,
	|	Goods.ProductionLot AS ProductionLot,
	|	Goods.Products       AS Products,
	|	Goods.Characteristic     AS Characteristic,
	|	Goods.CostShare      AS CostShare,
	|	Goods.ProductCostElement  AS ProductCostElement,
	|	Goods.ToExpenseAs   AS ToExpenseAs,
	|	Goods.VATRate          AS VATRate
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	ProductionLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.ProductionLot                   AS ProductionLot,
	|	COUNT(DISTINCT Goods.Products)   AS QuantityProducts,
	|	COUNT(DISTINCT Goods.Characteristic) AS QuantityCharacteristic,
	|	SUM(Goods.CostShare)                 AS AmountShareOfCost
	|INTO ResultsForCostGroup
	|FROM
	|	TTProducts_1 AS Goods
	|
	|GROUP BY
	|	Goods.ProductionLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	TRUE AS CalculationArticleNotFilledIn,
	|	FALSE   AS VATRateIsNotFilledIn,
	|	FALSE   AS CostFractionNotFilledIn,
	|	FALSE   AS ReportHasAlreadyBeenEntered,
	|	FALSE   AS SeveralTraceableWorks
	|FROM
	|	TTProducts_1 AS Goods
	|WHERE
	|	NOT Goods.ToExpenseAs
	|	AND Goods.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	FALSE   AS CalculationArticleNotFilledIn,
	|	TRUE AS VATRateIsNotFilledIn,
	|	FALSE   AS CostFractionNotFilledIn,
	|	FALSE   AS ReportHasAlreadyBeenEntered,
	|	FALSE   AS SeveralTraceableWorks
	|FROM
	|	TTProducts_1 AS Goods
	|WHERE
	|	NOT Goods.ToExpenseAs
	|	AND Goods.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	FALSE   AS CalculationArticleNotFilledIn,
	|	FALSE   AS VATRateIsNotFilledIn,
	|	TRUE AS CostFractionNotFilledIn,
	|	FALSE   AS ReportHasAlreadyBeenEntered,
	|	FALSE   AS SeveralTraceableWorks
	|FROM
	|	TTProducts_1 AS Goods
	|	
	|	INNER JOIN ResultsForCostGroup AS ResultsForCostGroup
	|	ON Goods.ProductionLot = ResultsForCostGroup.ProductionLot
	|WHERE
	|	Goods.CostShare = 0
	|	AND (ResultsForCostGroup.QuantityProducts > 1
	|		OR ResultsForCostGroup.QuantityCharacteristic > 1
	|		OR NOT ResultsForCostGroup.AmountShareOfCost = 0)
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	FALSE   AS CalculationArticleNotFilledIn,
	|	FALSE   AS VATRateIsNotFilledIn,
	|	FALSE   AS CostFractionNotFilledIn,
	|	TRUE AS ReportHasAlreadyBeenEntered,
	|	FALSE   AS SeveralTraceableWorks
	|FROM
	|	TTProducts_1 AS Goods
	|	
	|WHERE
	|	TRUE IN(
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS BatchesOfCurrentMonth
	|			
	|			LEFT JOIN Document.ReversingEntry AS StornoData
	|			ON StornoData.ReversedDocument = BatchesOfCurrentMonth.Ref
	|			AND BEGINOFPERIOD(StornoData.Date, MONTH) = &Month
	|		
	|		WHERE
	|			Goods.ProductionLot = BatchesOfCurrentMonth.ProductionLot
	|			AND BatchesOfCurrentMonth.Ref.Organization = &Organization
	|			AND BEGINOFPERIOD(BatchesOfCurrentMonth.Ref.Date, MONTH) = &Month
	|			AND NOT BatchesOfCurrentMonth.Ref = &Ref
	|			AND BatchesOfCurrentMonth.Ref.Posted
	|			AND StornoData.Ref IS NULL
	|		)
	|
	|GROUP BY
	|	Goods.LineNumber
	|";
	
	Query.SetParameter("Ref",      Ref);
	Query.SetParameter("Date",        Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Month",       BegOfMonth(Date));
	Query.SetParameter("Goods",      Goods.Unload());
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.CalculationArticleNotFilledIn Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Dạng tính giá thành"" trong dòng %1 của danh sách ""Hàng hóa""';
							|ru = 'Не заполнено поле ""Статья калькуляции"" в строке %1 списка ""Товары""';
							|en = 'The ""Product cost element"" field in line %1 of the ""Goods"" list is not filled'; fa = 'The ""Product cost element"" field in line %1 of the ""Goods"" list is not filled';
							|it = 'Не заполнено поле ""Статья калькуляции"" в строке %1 списка ""Товары""';
							|pl = 'The ""Product cost element"" field in line %1 of the ""Goods"" list is not filled';
							|tr = '""Ürünler"" listesinin %1 satırındaki ""Ürün maliyet kalemi"" alanı doldurulmadı'");
			
			Common.MessageToUser(
				StrTemplate(ErrorText, Selection.LineNumber),
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "ProductCostElement"),,
				Cancel);
			
		EndIf;
		
		If Selection.VATRateIsNotFilledIn Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Thuế suất thuế GTGT"" trong dòng %1 của danh sách ""Hàng hóa""';
							|ru = 'Не заполнено поле ""Ставка НДС"" в строке %1 списка ""Товары""';
							|en = 'The ""VAT rate"" field in line %1 of the ""Goods"" list is not filled'; fa = 'The ""VAT rate"" field in line %1 of the ""Goods"" list is not filled';
							|it = 'Не заполнено поле ""Ставка НДС"" в строке %1 списка ""Товары""';
							|pl = 'The ""VAT rate"" field in line %1 of the ""Goods"" list is not filled';
							|tr = '""Ürünler"" listesinin %1 satırındaki ""KDV oranı"" alanı doldurulmadı'");
			
			Common.MessageToUser(
				StrTemplate(ErrorText, Selection.LineNumber),
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "VATRate"),,
				Cancel);
			
		EndIf;
		
		If Selection.CostFractionNotFilledIn Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Tỷ lệ giá trị"" trong dòng %1 của danh sách ""Hàng hóa""';
							|ru = 'Не заполнено поле ""Доля стоимости"" в строке %1 списка ""Товары""';
							|en = 'The ""Cost share"" field in line %1 of the ""Goods"" list is not filled'; fa = 'The ""Cost share"" field in line %1 of the ""Goods"" list is not filled';
							|it = 'Не заполнено поле ""Доля стоимости"" в строке %1 списка ""Товары""';
							|pl = 'The ""Cost share"" field in line %1 of the ""Goods"" list is not filled';
							|tr = '""Ürünler"" listesinin %1 satırındaki ""Maliyet payı"" alanı doldurulmadı'");
			
			Common.MessageToUser(
				StrTemplate(ErrorText, Selection.LineNumber),
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "CostShare"),,
				Cancel);
			
		EndIf;
		
		If Selection.ReportHasAlreadyBeenEntered Then
			
			ErrorText = NStr("vi = 'Trong dòng %1 của danh sách ""Hàng hóa"" đã chỉ ra lô sản xuất mà theo đó trong tháng hiện tại đã tạo bảng kê dành cho người đặt ký gửi.';
							|ru = 'В строке %1 списка ""Товары"" указана партия производства по которой в текущем месяце уже оформлен отчет давальцу.';
							|en = 'In line %1 of the ""Goods"" list, the production lot for which the ""Consumption report — subcontracting services delivered"" is already registered in this month is specified.'; fa = 'In line %1 of the ""Goods"" list, the production lot for which the ""Consumption report — subcontracting services delivered"" is already registered in this month is specified.';
							|it = 'В строке %1 списка ""Товары"" указана партия производства по которой в текущем месяце уже оформлен отчет давальцу.';
							|pl = 'In line %1 of the ""Goods"" list, the production lot for which the ""Consumption report — subcontracting services delivered"" is already registered in this month is specified.';
							|tr = '""Ürünler"" listesinin %1 satırında, cari ay içinde Tüketim raporu-Verilen fason hizmetleri düzenlenmiş olan üretim lotu bulunmaktadır.'");
			
			Common.MessageToUser(
				StrTemplate(ErrorText, Selection.LineNumber),
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "ProductionLot"),,
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf