#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
		UseLoyaltyCards = GetFunctionalOption("UseLoyaltyCards");
		
		If BusinessOperation = Enums.BusinessTransactions.OBEntryOpenGiftCards Then
			CreateGiftCertificates(Cancel);
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods Then
			PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation, Warehouse, Department, Partner);
			
			FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
			FieldsNames.Purpose = "";
			FieldsNames.BatchesIndicationStatus = "";
			FieldsNames.Series = "";
			
			InformationRegisters.ItemsLocationAttributes.FillInCollection(WholesaleSalesInPastPeriods, PlacesOfAccounting, FieldsNames);
			FillStockTypes();
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods Then
			
			If UseLoyaltyCards Then
				CreateLoyaltyCardsAndFillOutPartnerTrackingAnalytics();
			Else
				CompleteAccountingAnalyticsForPartners();
			EndIf;
			
			PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation, Warehouse, Department, Partner);
			
			FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
			FieldsNames.Purpose = "";
			FieldsNames.BatchesIndicationStatus = "";
			FieldsNames.Series = "";
			
			InformationRegisters.ItemsLocationAttributes.FillInCollection(RetailSales, PlacesOfAccounting, FieldsNames);
			FillStockTypes();
		EndIf;
		
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TMCommonUse.FillInDocumentIDs(	ThisObject, "WholesaleSalesInPastPeriods,RetailSales,GiftCertificates");

	OBEntryLocalization.OBEntrySalesForPastPeriodsBeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes", InventoriesServer.ParametersForFillingInventoryTypes());
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOfSalesForPastPeriodsProcessingOfTransactions(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes", InventoriesServer.ParametersForFillingInventoryTypes());
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOnSalesForPastPeriodsProcessingDeletions(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If Not RecordInOperationalAccounting
		And Not PostInFinancialAndTaxAccounting
		And Not RecordInMA Then
		
		MessageText = NStr("vi = 'Cần phản ánh hoạt động trong một trong số sổ kế toán';
							|ru = 'Операция должна отражаться в одном из учетов';
							|en = 'The operation must be recorded in one of accounting types'; fa = 'The operation must be recorded in one of accounting types';
							|it = 'L''operazione deve essere riportata in uno dei tipi della contabilità';
							|pl = 'Operacja powinna być odzwierciedlana w jednej z ewidencji';
							|tr = 'İşlemin hesaplardan birine yansıtılması gerekir'");
		Common.MessageToUser(MessageText, , 
			"Object.RecordInOperationalAccounting", , Cancel);
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	NotCheckedAttributeArray.Add("Manager");
	NotCheckedAttributeArray.Add("Counterparty");
	NotCheckedAttributeArray.Add("Department");
	NotCheckedAttributeArray.Add("VATTaxation");
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods Then
		NotCheckedAttributeArray.Add("Warehouse");
	EndIf;
	
	NotCheckedAttributeArray.Add("WholesaleSalesInPastPeriods.Package");
	NotCheckedAttributeArray.Add("RetailSales.Package");
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods Then
		NotCheckedAttributeArray.Add("Partner");
	EndIf;
	
	If Not RecordInOperationalAccounting
	 Or BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfOtherPLItemsInPastPeriods Then
		NotCheckedAttributeArray.Add("Currency");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryOpenGiftCards
		And RecordInOperationalAccounting Then
		
		GiftCertificatesServer.FillCheckProcessing(ThisObject, Cancel);
		AttributesValues = Common.ObjectAttributesValues(GiftCertificateKind, "CardType");
		If AttributesValues.CardType = Enums.CardTypes.Magnetic Then
			NotCheckedAttributeArray.Add("GiftCertificates.Barcode");
		ElsIf AttributesValues.CardType = Enums.CardTypes.Barcode_ Then
			NotCheckedAttributeArray.Add("GiftCertificates.MagneticCode");
		EndIf;
		NotCheckedAttributeArray.Add("Currency");
	Else
		NotCheckedAttributeArray.Add("GiftCertificateKind");
		NotCheckedAttributeArray.Add("GiftCertificates");
		NotCheckedAttributeArray.Add("GiftCertificates.Barcode");
		NotCheckedAttributeArray.Add("GiftCertificates.MagneticCode");
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryStatisticsOfOtherPLItemsInPastPeriods Then
		NotCheckedAttributeArray.Add("FinancialResultExpenses");
		NotCheckedAttributeArray.Add("FinancialResultExpenses.ExpenseItem");
		NotCheckedAttributeArray.Add("FinancialResultExpenses.DimensionOfExpenses");
		NotCheckedAttributeArray.Add("FinancialResultExpenses.DateRecord");
		NotCheckedAttributeArray.Add("FinancialResultIncome");
		NotCheckedAttributeArray.Add("FinancialResultIncome.IncomeItem");
		NotCheckedAttributeArray.Add("FinancialResultIncome.DimensionOfRevenue");
		NotCheckedAttributeArray.Add("FinancialResultIncome.DateRecord");
	Else
		If FinancialResultExpenses.Count() > 0 And FinancialResultIncome.Count() = 0 Then
			NotCheckedAttributeArray.Add("FinancialResultIncome");
			NotCheckedAttributeArray.Add("FinancialResultIncome.IncomeItem");
			NotCheckedAttributeArray.Add("FinancialResultIncome.DimensionOfRevenue");
			NotCheckedAttributeArray.Add("FinancialResultIncome.DateRecord");
		ElsIf FinancialResultExpenses.Count() = 0 And FinancialResultIncome.Count() > 0 Then
			NotCheckedAttributeArray.Add("FinancialResultExpenses");
			NotCheckedAttributeArray.Add("FinancialResultExpenses.ExpenseItem");
			NotCheckedAttributeArray.Add("FinancialResultExpenses.DimensionOfExpenses");
			NotCheckedAttributeArray.Add("FinancialResultExpenses.DateRecord");
		EndIf;
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods Then
		NotCheckedAttributeArray.Add("WholesaleSalesInPastPeriods");
		NotCheckedAttributeArray.Add("WholesaleSalesInPastPeriods.Products");
		NotCheckedAttributeArray.Add("WholesaleSalesInPastPeriods.Characteristic");
		NotCheckedAttributeArray.Add("WholesaleSalesInPastPeriods.Count");
		NotCheckedAttributeArray.Add("WholesaleSalesInPastPeriods.Sum");
		NotCheckedAttributeArray.Add("WholesaleSalesInPastPeriods.DateRecord");
		NotCheckedAttributeArray.Add("WholesaleSalesInPastPeriods.Package");
		NotCheckedAttributeArray.Add("WholesaleSalesInPastPeriods.NumberOfPackages");
		NotCheckedAttributeArray.Add("WholesaleSalesInPastPeriods.Price");
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods Then
		NotCheckedAttributeArray.Add("RetailSales");
		NotCheckedAttributeArray.Add("RetailSales.LoyaltyCardKind");
		NotCheckedAttributeArray.Add("RetailSales.LoyaltyCard");
		NotCheckedAttributeArray.Add("RetailSales.Products");
		NotCheckedAttributeArray.Add("RetailSales.Characteristic");
		NotCheckedAttributeArray.Add("RetailSales.Count");
		NotCheckedAttributeArray.Add("RetailSales.Sum");
		NotCheckedAttributeArray.Add("RetailSales.DateRecord");
		NotCheckedAttributeArray.Add("RetailSales.Package");
		NotCheckedAttributeArray.Add("RetailSales.NumberOfPackages");
		NotCheckedAttributeArray.Add("RetailSales.Price");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods Then
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "WholesaleSalesInPastPeriods";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel, CheckParameters);
		For RowIndex = 0 To WholesaleSalesInPastPeriods.Count()-1 Do
			If WholesaleSalesInPastPeriods.Get(RowIndex).DateRecord > Date Then
				ErrorText = NStr("vi = 'Giá trị của cột ""Kỳ"" trong dòng %LineNumber% không được lớn hơn ngày lập chứng từ';
								|ru = 'Значение колонки ""Период"" в строке %LineNumber% не должно быть больше даты документа';
								|en = 'The ""Period"" column value in line %LineNumber% cannot be greater than the document date'; fa = 'The ""Period"" column value in line %LineNumber% cannot be greater than the document date';
								|it = 'Il valore della colonna ""Periodo"" nella riga %LineNumber% non deve superare la data del documento';
								|pl = 'Wartość kolumny ""Период"" w wierszu %LineNumber% nie powinna być większa niż data dokumentu';
								|tr = '%LineNumber% satırındaki ""Dönem"" sütununun değeri belgenin tarihinden büyük olmamalıdır'");
				ErrorText =  StrReplace(ErrorText, "%LineNumber%", WholesaleSalesInPastPeriods.Get(RowIndex).LineNumber);
				Common.MessageToUser(
					ErrorText,
					ThisObject,
					CommonClientServer.PathToTabularSection("WholesaleSalesInPastPeriods", WholesaleSalesInPastPeriods.Get(RowIndex).LineNumber, "DateRecord"),
					,
					Cancel);
			EndIf;
		EndDo;
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods Then
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "RetailSales";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel, CheckParameters);
		For RowIndex = 0 To RetailSales.Count()-1 Do
			If RetailSales.Get(RowIndex).DateRecord > Date Then
				ErrorText = NStr("vi = 'Giá trị của cột ""Kỳ"" trong dòng %LineNumber% không được lớn hơn ngày lập chứng từ';
								|ru = 'Значение колонки ""Период"" в строке %LineNumber% не должно быть больше даты документа';
								|en = 'The ""Period"" column value in line %LineNumber% cannot be greater than the document date'; fa = 'The ""Period"" column value in line %LineNumber% cannot be greater than the document date';
								|it = 'Il valore della colonna ""Periodo"" nella riga %LineNumber% non deve superare la data del documento';
								|pl = 'Wartość kolumny ""Период"" w wierszu %LineNumber% nie powinna być większa niż data dokumentu';
								|tr = '%LineNumber% satırındaki ""Dönem"" sütununun değeri belgenin tarihinden büyük olmamalıdır'");
				ErrorText =  StrReplace(ErrorText, "%LineNumber%", RetailSales.Get(RowIndex).LineNumber);
				Common.MessageToUser(
					ErrorText,
					ThisObject,
					CommonClientServer.PathToTabularSection("RetailSales", RetailSales.Get(RowIndex).LineNumber, "DateRecord"),
					,
					Cancel);
			EndIf;
		EndDo;
	EndIf;
	
	AddVerifiedDetails(CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	OBEntryLocalization.EnteringSalesBalancesForPastPeriodsProcessingFillInChecks(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	InitializeDocument(FillingData);
	
	OBEntryLocalization.EnteringBalancesOfSalesForPastPeriodsProcessingFilling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Author = Users.CurrentUser();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "WholesaleSalesInPastPeriods,RetailSales,GiftCertificates");
	
	// Fill in the bid taking into account the current date of the document. We recalculate the related details of the tabular part.
	If BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods Then
		
		LocalAccountingCurrency            = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		ManagementAccountingCurrency                = Constants.ManagementAccountingCurrency.Get();
		FactorOfConversionFromManCurrencyToRegulCurrency      = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
														ManagementAccountingCurrency,
														LocalAccountingCurrency,
														?(Date = Date(1,1,1), CurrentSessionDate(), Date));
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
		
		StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
		StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;
		
		StructureOfVATRateActions = New Structure;
		StructureOfVATRateActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithoutVAT");
		StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
		
		If BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods Then
			
			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
			BatchProcessingOfTablePartServer.TreatTS(WholesaleSalesInPastPeriods, StructureOfVATRateActions, CachedValues);
			
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				CachedValues.ProcessedRows,
				StructureOfActions,
				WholesaleSalesInPastPeriods,
				Undefined);
		
		ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods Then
			
			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
			BatchProcessingOfTablePartServer.TreatTS(RetailSales, StructureOfVATRateActions, CachedValues);
			
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				CachedValues.ProcessedRows,
				StructureOfActions,
				RetailSales,
				Undefined);
			
		EndIf;
	
	EndIf;
	
	OBEntryLocalization.EnteringBalancesOfSalesForPastPeriodsWhenCopying(ThisObject, CopiedObject);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	OBEntryLocalization.EnteringBalancesOfSalesForPastPeriodsWhenRecording(ThisObject, Cancel);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return
	EndIf;
	
	OBEntryLocalization.EnteringBalancesAboutPastSalesBeforeDeleting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If ValueIsFilled(Organization) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	Else
		Currency = SettingsValueCached.ManagementAccountingCurrency();
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("BusinessOperation") Then
			BusinessOperation = FillingData.BusinessOperation;
		EndIf;
		
		If FillingData.Property("Comment") Then
			Comment = FillingData.Comment;
		EndIf;
		
		If FillingData.Property("CopyingValue") Then
			OBEntryServer.FillInValuesForOldInputBalances(ThisObject, FillingData.CopyingValue);
		EndIf;
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods Then
		
		Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes()

	Query = New Query("
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfGoods.ProductsGroup AS ProductsGroup
	|INTO TableOfGoodsVrem
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|WHERE
	|	TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|	OR &RefillInventoryKinds
	|;
	|
	|////////////////////////////////////////////////////////////////
	|SELECT
	|	T.LineNumber,
	|	T.Products,
	|	T.InventoryOwnerAttribute,
	|	T.ProductsGroup
	|INTO TableOfGoods
	|FROM
	|	TableOfGoodsVrem AS T
	|
	|	INNER JOIN Catalog.Products AS CatProducts
	|	ON T.Products = CatProducts.Ref
	|		AND CASE
	|			WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods),
	|				VALUE(Enum.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods))
	|			THEN
	|				CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|				OR CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			ELSE TRUE
	|			END
	|;
	|
	|////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	&Terms AS Terms,
	|	&Currency AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	UNDEFINED AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods)
	|
	|	UNION ALL
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
	|	TableOfGoods.ProductsGroup AS ProductsGroup,
	|	UNDEFINED AS PriceKind,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	&Terms AS Terms,
	|	&Currency AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	UNDEFINED AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	FALSE AS ActivitiesAreSubjectToUTII
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods)
	|;
	|////////////////////////////////////////////////////////////////
	|DROP TableOfGoodsVrem
	|;
	|////////////////////////////////////////////////////////////////
	|DROP TableOfGoods
	|");

	TempTablesManager        = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods Then
		
		TableOfGoods = WholesaleSalesInPastPeriods.Unload(, "LineNumber, Products, InventoryOwnerAttribute");
		TableOfGoods.Columns.Add("ProductsGroup", New TypeDescription("CatalogRef.AnalyticalInventoryGroups"));
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods Then
		
		TableOfGoods = RetailSales.Unload(, "LineNumber, Products, InventoryOwnerAttribute");
		TableOfGoods.Columns.Add("ProductsGroup", New TypeDescription("CatalogRef.AnalyticalInventoryGroups"));
		
	EndIf;
	
	Query.SetParameter("TableOfGoods",        TableOfGoods);
	Query.SetParameter("Organization",           Organization);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("Partner",               Partner);
	Query.SetParameter("Counterparty",            Counterparty);
	Query.SetParameter("Department",         Department);
	Query.SetParameter("Manager",              Manager);
	Query.SetParameter("Contract",               Contract);
	Query.SetParameter("Currency",                Currency);
	Query.SetParameter("Posted",              Posted);
	Query.SetParameter("VATTaxation",    VATTaxation);
	
	If BusinessOperation <> Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods Then
		Query.SetParameter("Terms", Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	Else
		Query.SetParameter("Terms", CustomerTermsOfSales);
	EndIf;
	
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Organization, Date);
	
	Query.SetParameter("TaxationOfOrganization",
		AccountingParametersForOrganization.BasicTaxationVATSales);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	Query.Execute();
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods Then
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, WholesaleSalesInPastPeriods);
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods Then
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, RetailSales);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure AddVerifiedDetails(CheckedAttributes)
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods Then
		ProductsArray = WholesaleSalesInPastPeriods.UnloadColumn("Products");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods Then
		ProductsArray = RetailSales.UnloadColumn("Products");
	Else
		ProductsArray = Undefined;
	EndIf;
	
	If ValueIsFilled(ProductsArray) Then
		
		Query = New Query;
		Query.SetParameter("ProductsArray", ProductsArray);
		Query.Text =
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	Catalog.Products AS ProductsTable
		|WHERE
		|	Ref IN (&ProductsArray)
		|	AND ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
		|		VALUE(Enum.ItemsTypes.ReusablePackage))";
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			CheckedAttributes.Add("Warehouse");
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CreateLoyaltyCardsAndFillOutPartnerTrackingAnalytics();
	
	LoyaltyCardDataStructure = LoyaltyCardsServer.InitializeLoyaltyCardData();
	For Each CurRow In RetailSales Do
		If Not ValueIsFilled(CurRow.LoyaltyCard) And ValueIsFilled(CurRow.LoyaltyCardKind) Then
			Result = LoyaltyCardsServer.FindLoyaltyCards(CurRow.Barcode, Enums.CardCodeTypes.Barcode);
			For Each Page1 In Result.RegisteredLoyaltyCards Do
				If Page1.MagneticCode = CurRow.MagneticCode And Page1.CardKind = CurRow.LoyaltyCardKind Then
					CurRow.LoyaltyCard = Page1.Ref;
					Break;
				EndIf;
			EndDo;
			If Not ValueIsFilled(CurRow.LoyaltyCard) Then
				LoyaltyCardDataStructure.CardKind = CurRow.LoyaltyCardKind;
				LoyaltyCardDataStructure.Barcode = CurRow.Barcode;
				LoyaltyCardDataStructure.MagneticCode = CurRow.MagneticCode;
				NewCard = LoyaltyCardsServer.CreatePartnerAndRegisterLoyaltyCard(LoyaltyCardDataStructure);
				CurRow.LoyaltyCard = NewCard;
			EndIf;
		EndIf;
		Attributes = New Structure;
		Attributes.Insert("Organization", Organization);
		Attributes.Insert("Partner", LoyaltyCardServerCall.GetLoyaltyCardDetails(CurRow.LoyaltyCard).Partner);
		Attributes.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
		Attributes.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
		Attributes.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
		CurRow.AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Attributes);
	EndDo;
	
EndProcedure

Procedure CompleteAccountingAnalyticsForPartners()
	
	For Each CurRow In RetailSales Do
		Attributes = New Structure;
		Attributes.Insert("Organization", Organization);
		Attributes.Insert("Partner", Catalogs.Partners.EmptyRef());
		Attributes.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
		Attributes.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
		Attributes.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
		CurRow.AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Attributes);
	EndDo;
	
EndProcedure

Procedure CreateGiftCertificates(Cancel)
	
	SetPrivilegedMode(True);
	
	NewItems = New Array;
	
	Query = New Query("
	|SELECT
	|	Table.Barcode AS Barcode,
	|	Table.MagneticCode AS MagneticCode,
	|	Table.LineNumber AS LineNumber,
	|	Table.SerialNumber AS SerialNumber
	|INTO Table
	|FROM
	|	&GiftCertificates AS Table
	|;
	|
	|SELECT
	|	Table.LineNumber AS LineNumber,
	|	ISNULL(CatalogGiftCertificatesByBarcode.Ref,      VALUE(Catalog.GiftCertificates.EmptyRef)) AS BarcodeGiftCertificate,
	|	ISNULL(CatalogGiftCertificatesByMagneticCode.Ref, VALUE(Catalog.GiftCertificates.EmptyRef)) AS MagneticCodeGiftCertificate,
	|	ISNULL(CatalogGiftCertificateBySerialNumber.Ref, VALUE(Catalog.GiftCertificates.EmptyRef)) AS GiftCertificateBySerialNumber
	|FROM
	|	Table AS Table
	|		LEFT JOIN Catalog.GiftCertificates AS CatalogGiftCertificatesByBarcode
	|		ON CatalogGiftCertificatesByBarcode.Barcode = Table.Barcode
	|		AND CatalogGiftCertificatesByBarcode.Owner = &GiftCertificateKind
	|
	|		LEFT JOIN Catalog.GiftCertificates AS CatalogGiftCertificatesByMagneticCode
	|		ON CatalogGiftCertificatesByMagneticCode.MagneticCode = Table.MagneticCode
	|		AND CatalogGiftCertificatesByMagneticCode.Owner = &GiftCertificateKind
	|
	|		LEFT JOIN Catalog.GiftCertificates AS CatalogGiftCertificateBySerialNumber
	|		ON CatalogGiftCertificateBySerialNumber.Code = Table.SerialNumber
	|");
	
	Query.SetParameter("GiftCertificateKind", GiftCertificateKind);
	Query.SetParameter("GiftCertificates",     GiftCertificates.Unload());
	
	Table = Query.Execute().Unload();
	CardType = Common.ObjectAttributeValue(GiftCertificateKind, "CardType");
	
	For Each TSRow In GiftCertificates Do
		
		If Not ValueIsFilled(TSRow.GiftCertificate) Then
			
			FoundRow = Table.FindRows(New Structure("LineNumber", TSRow.LineNumber))[0];
			
			If CardType = Enums.CardTypes.Barcode_ Then
				
				If ValueIsFilled(FoundRow.GiftCertificateBySerialNumber)
					And ValueIsFilled(FoundRow.BarcodeGiftCertificate)
					And FoundRow.GiftCertificateBySerialNumber = FoundRow.BarcodeGiftCertificate Then
					TSRow.GiftCertificate = FoundRow.GiftCertificateBySerialNumber;
					Continue;
				EndIf;
				
			ElsIf CardType = Enums.CardTypes.Magnetic Then
				
				If ValueIsFilled(FoundRow.GiftCertificateBySerialNumber)
					And ValueIsFilled(FoundRow.MagneticCodeGiftCertificate)
					And FoundRow.GiftCertificateBySerialNumber = FoundRow.MagneticCodeGiftCertificate Then
					TSRow.GiftCertificate = FoundRow.GiftCertificateBySerialNumber;
					Continue;
				EndIf;
				
			Else
				
				If ValueIsFilled(FoundRow.GiftCertificateBySerialNumber)
					And ValueIsFilled(FoundRow.BarcodeGiftCertificate)
					And ValueIsFilled(FoundRow.MagneticCodeGiftCertificate)
					And FoundRow.GiftCertificateBySerialNumber = FoundRow.MagneticCodeGiftCertificate
					And FoundRow.GiftCertificateBySerialNumber = FoundRow.BarcodeGiftCertificate Then
					TSRow.GiftCertificate = FoundRow.GiftCertificateBySerialNumber;
					Continue;
				EndIf;
				
			EndIf;
			
			Try
				
				GiftCertificateDataStructure = GiftCertificatesServerCall.InitializeGiftCertificateDescription();
				GiftCertificateDataStructure.GiftCertificateKind = GiftCertificateKind;
				GiftCertificateDataStructure.MagneticCode              = TSRow.MagneticCode;
				GiftCertificateDataStructure.Barcode                  = TSRow.Barcode;
				GiftCertificateDataStructure.SerialNumber             = TSRow.SerialNumber;
				TSRow.GiftCertificate = GiftCertificatesServer.RegisterGiftCertificate(GiftCertificateDataStructure);
				
				NewItems.Add(TSRow);
				
			Except
				
				MessageText = NStr("vi = 'Lỗi tạo phiếu quà tặng: ""%ErrorDescription%""';
									|ru = 'Ошибка создания подарочного сертификата: ""%ErrorDescription%""';
									|en = 'Error creating gift card: ""%ErrorDescription%""'; fa = 'Error creating gift card: ""%ErrorDescription%""';
									|it = 'Errore durante la creazione del buono regalo: ""%ErrorDescription%""';
									|pl = 'Błąd utworzenia certyfikatu podarunkowego: ""%ErrorDescription%""';
									|tr = 'Hediye kartı oluşturulurken hata: ""%ErrorDescription%""'");
				Information = ErrorInfo();
				If Information.Cause <> Undefined Then
					ErrorText = Information.Cause.Description;
				Else
					ErrorText = DetailErrorDescription(Information);
				EndIf;
				MessageText = StrReplace(MessageText,"%ErrorDescription%",ErrorText);
				Common.MessageToUser(
					MessageText,
					,
					"Object.GiftCertificates" + "[" + Format(TSRow.LineNumber - 1,"NG=0") + "].SerialNumber",
					,
					Cancel);
				Break;
				
			EndTry;
			
		EndIf;
	EndDo;
	
	If Cancel Then
		For Each TSRow In NewItems Do
			TSRow.GiftCertificate = Undefined;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
