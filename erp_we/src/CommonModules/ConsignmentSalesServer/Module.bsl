#Region Public

// The procedure checks whether the beginning and end of the period are filled in correctly.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	Cancel - Boolean - Indicates that you don't want to continue working.
//
Procedure CheckIfPeriodIsCorrect(DocumentObject, Cancel) Export
	
	If ValueIsFilled(DocumentObject.BeginOfPeriod)
	 And DocumentObject.BeginOfPeriod > DocumentObject.EndOfPeriod Then
	 
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Ngày đầu kỳ không được lớn hơn ngày cuối kỳ %1';
				|ru = 'Дата начала периода не должна быть больше окончания периода %1';
				|en = 'Period start date cannot exceed period end date %1'; fa = 'Period start date cannot exceed period end date %1';
				|it = 'Data di inizio del periodo non deve essere successiva alla data di fine periodo %1';
				|pl = 'Data rozpoczęcia okresu nie może być większa niż koniec okresu %1';
				|tr = 'Dönemin başlangıç tarihi, %1dönemin bitiş tarihinden sonra olmamalıdır'"),
			Format(DocumentObject.EndOfPeriod, "DLF=DD"));
		CommonClientServer.MessageToUser(
			ErrorText,
			DocumentObject,
			"EndOfPeriod",
			, // DataPath
			Cancel);
	 
	EndIf;
	
EndProcedure

// The procedure verifies that the Commission fee service is specified correctly.
//
// Parameters:
//	DocumentObject - DocumentObject - Current document
//	Cancel - Boolean - Indicates that you don't want to continue working.
//
Procedure CheckCommissionService(DocumentObject, Cancel) Export
	
	If ValueIsFilled(DocumentObject.OperationService) Then
		
		ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(DocumentObject.OperationService);
		If ItemVariantsAreUsed Then
			ErrorText = NStr("vi = 'Cần chỉ ra dịch vụ mà không sử dụng đặc tính';
							|ru = 'Необходимо указать услугу для которой не используются характеристики';
							|en = 'Specify a service for which variants are not used'; fa = 'Specify a service for which variants are not used';
							|it = 'È necessario specificare un servizio per il quale non vengono utilizzate le caratteristiche';
							|pl = 'Należy podać usługę, dla której nie są stosowane charakterystyki';
							|tr = 'Varyantların kullanılmadığı hizmet belirtilmeli'");
			CommonClientServer.MessageToUser(
				ErrorText,
				DocumentObject,
				"OperationService",
				, // DataPath
				Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

// Procedure for filling out a document on product balances to issue reports to the Commitee on write-offs.
//
// Parameters:
//	Object - FormDataCollection - the object to fill in.
//	ThereIsCCDNumber - Boolean - a sign of the presence of the column 'NomerGTD' in the object table. The default value is False.
//	FillInVATRate - Boolean - indicates whether the VAT rate is filled in based on the Committee's settings. The default value is False.
//
Procedure FillInInformationOnBalancesForMakingReportsToCommitteeOnWriteOffs(Object, ThereIsCCDNumber = False, FillInVATRate = False) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InventoryKinds.Ref AS InventoryOwnerAttribute
	|
	|INTO InventoryKinds
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND InventoryKinds.Organization = &Organization
	|	AND InventoryKinds.GoodsOwner = &Consignor
	|	AND (InventoryKinds.Terms = &Terms
	|		OR &Terms IN (
	|			UNDEFINED,
	|			VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)))
	|	AND (InventoryKinds.Counterparty = &Counterparty
	|		OR &Counterparty IN (
	|			UNDEFINED,
	|			VALUE(Catalog.Counterparties.EmptyRef),
	|			VALUE(Catalog.Companies.EmptyRef)))	
	|	AND (InventoryKinds.Contract = &Contract
	|		OR (InventoryKinds.Contract IN (
	|			UNDEFINED,
	|			VALUE(Catalog.CounterpartyContracts.EmptyRef),
	|			VALUE(Catalog.IntercompanyContracts.EmptyRef)) AND
	|		&Contract IN (
	|			UNDEFINED,
	|			VALUE(Catalog.CounterpartyContracts.EmptyRef),
	|			VALUE(Catalog.IntercompanyContracts.EmptyRef))
	|		))
	|	AND (InventoryKinds.VATTaxation = &VATTaxation
	|		OR InventoryKinds.VATTaxation = VALUE(Enum.VATTaxationTypes.EmptyRef))
	|	AND InventoryKinds.Currency = &Currency
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Turnovers.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE
	|		WHEN &ThereIsCCDNumber
	|				AND ISNULL(Turnovers.ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|			THEN Turnovers.CCDNumber
	|		ELSE UNDEFINED
	|	END AS CCDNumber,
	|	Turnovers.ItemsLocationAttributes.Products AS Products,
	|	Turnovers.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	Turnovers.ItemsLocationAttributes.Series AS Series,
	|	SUM(Turnovers.QuantityConsumedForIncoiceRegistrationClosingBalance) AS Count
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.BalanceAndTurnovers(&BeginOfPeriod, &EndOfPeriod, Period,,
	|			InventoryOwnerAttribute IN
	|				(SELECT
	|					InventoryOwnerAttribute
	|				FROM
	|					InventoryKinds AS InventoryKinds)
	|			AND ItemsLocationAttributes.StorageLocation = &Consignor
	|	
	|	) AS Turnovers
	|
	|WHERE
	|	Turnovers.QuantityConsumedForIncoiceRegistrationClosingBalance <> 0
	|	AND (Turnovers.QuantityConsumedForIncoiceRegistrationReceipt <> 0
	|		OR Turnovers.QuantityConsumedForIncoiceRegistrationExpense <> 0)
	|
	|GROUP BY
	|	Turnovers.ItemsLocationAttributes,
	|	CASE
	|		WHEN &ThereIsCCDNumber
	|				AND ISNULL(Turnovers.ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|			THEN Turnovers.CCDNumber
	|		ELSE UNDEFINED
	|	END
	|
	|ORDER BY
	|	Turnovers.ItemsLocationAttributes.Products,
	|	Turnovers.ItemsLocationAttributes.Characteristic,
	|	Turnovers.ItemsLocationAttributes.Series";
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	Query.SetParameter("Currency", Object.Currency);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Consignor", Object.Partner);
	Query.SetParameter("Terms", Object.Terms);
	Query.SetParameter("Counterparty", Object.Counterparty);
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("VATTaxation", Object.VATTaxation);
	Query.SetParameter("BeginOfPeriod", ?(ValueIsFilled(Object.BeginOfPeriod), Object.BeginOfPeriod, '00010101'));
	Query.SetParameter("EndOfPeriod", ?(ValueIsFilled(Object.EndOfPeriod), EndOfDay(Object.EndOfPeriod), EndOfMonth(DocumentDate)));
	Query.SetParameter("ThereIsCCDNumber", ThereIsCCDNumber);
	
	Object.Goods.Clear();
	
	CachedValues = Undefined;
	StructureOfActions = New Structure;
	ActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	StructureOfActions.Insert("FillInVATRate", ActionParameters);
	
	If FillInVATRate
		And ValueIsFilled(Object.Counterparty)
		And Not ValueIsFilled(Object.Terms) Then
	
		BatchProcessingOfTablePartClientServerLocalization.AddActionOfFillingInVATRateForSettingUpAccounting(Object, StructureOfActions);

	EndIf;
		
	RowsToProcess = New Array();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.NumberOfPackages = NewRow.Count;
		
		RowsToProcess.Add(NewRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	If TypeOf(Object.Partner) = Type("CatalogRef.Partners") Then
		PartnersProductsServer.FillInPartnerProductsByProductsInTable(Object.Goods, Object.Partner);
	EndIf;
	
	If ValueIsFilled(Object.Terms) Then
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.Insert("PopulationFields", "Price, VATRate");
		FillParameters.Insert("Date", DocumentDate);
		FillParameters.Insert("Currency", Object.Currency);
		FillParameters.Insert("Terms", Object.Terms);
		FillParameters.Insert("VATTaxation", Object.VATTaxation);
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		
		If FillInVATRate
			And ValueIsFilled(Object.Counterparty) Then
			BatchProcessingOfTablePartClientServerLocalization.AddActionOfFillingInVATRateForSettingUpAccounting(Object, StructureOfActions);
		EndIf;
		
		PartnerPricesFillingServer.FillInPrices(
			Object.Goods,
			Undefined, // Array of strings
			FillParameters,
			StructureOfActions);
			
	EndIf;
	
EndProcedure

// Procedure for filling out a document on the results of sales for the period of goods for the preparation of reports to the Committee.
//
// Parameters:
//	Object - FormDataCollection - the object to fill in.
//	BeginOfPeriod - Date - start date of filling in.
//	EndOfPeriod - Date - completion date.
//	ThereIsCCDNumber - Boolean - a sign of the presence of the column 'NomerGTD' in the object table. The default value is False.
//	UsePartnerProducts - Boolean - indicates the presence of the column 'Partner Nomenclature' in the object table.
//										The default value is False.
//	FillInVATRate - Boolean - indicates whether the VAT rate is filled in based on the Committee's settings. The default value is False.
//
Procedure InformationOnGoodsForMakingReportsToCommitteeForPeriod(Object,
																BeginOfPeriod,
																EndOfPeriod,
																ThereIsCCDNumber = False,
																UsePartnerProducts = False,
																FillInVATRate = False) Export
	
	DocumentSales = Documents.CustomerInvoice.EmptyRef();
	
	ObjectType = TypeOf(Object);
	If FillInVATRate
		Or ((ObjectType = Type("Structure")
			Or ObjectType = Type("FormDataStructure"))
			And Object.Property("DocumentSales")) Then
		DocumentSales = Object.DocumentSales;
	EndIf;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Date",				Object.Date);
	ParametersStructure.Insert("Currency",				Object.Currency);
	ParametersStructure.Insert("Organization",			Object.Organization);
	ParametersStructure.Insert("Partner",				Object.Partner);
	ParametersStructure.Insert("Terms",			Object.Terms);
	ParametersStructure.Insert("Counterparty",			?(ValueIsFilled(Object.Counterparty),
															Object.Counterparty,
															Undefined));
	ParametersStructure.Insert("Contract",				?(ValueIsFilled(Object.Contract),
															Object.Contract,
															Undefined));
	ParametersStructure.Insert("VATTaxation",	Object.VATTaxation);
	ParametersStructure.Insert("BeginOfPeriod",		BeginOfPeriod);
	ParametersStructure.Insert("EndOfPeriod",		EndOfDay(?(ValueIsFilled(EndOfPeriod),
																	EndOfPeriod,
																	CurrentSessionDate())));
	ParametersStructure.Insert("ThereIsCCDNumber",		ThereIsCCDNumber);
	ParametersStructure.Insert("ThereIsVATSaleAmount",	True);
	ParametersStructure.Insert("DocumentSales",		DocumentSales);
	
	If FillInVATRate
		And ValueIsFilled(Object.Counterparty)
		And Not ValueIsFilled(Object.Terms) Then
			
 		StructureOfActions = New Structure;
		BatchProcessingOfTablePartClientServerLocalization.AddActionOfFillingInVATRateForSettingUpAccounting(Object, StructureOfActions);
		
		ParametersStructure.Insert("StructureOfActions", StructureOfActions);
			
	EndIf;
	
	TempTablesManager = New TempTablesManager;
	
	GenerateDataForReportToCommittee(ParametersStructure, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT
	|	GoodsServicesForRegistration.Products			AS Products,
	|	GoodsServicesForRegistration.Characteristic		AS Characteristic,
	|	GoodsServicesForRegistration.Count		AS Count,
	|	GoodsServicesForRegistration.CountBalance		AS CountBalance,
	|	GoodsServicesForRegistration.SalesAmount	AS SalesAmount,
	|	GoodsServicesForRegistration.TaxInvoiceDate		AS TaxInvoiceDate,
	|	GoodsServicesForRegistration.DateOfTaxInvoiceIssuedByCommissionAgent		AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	GoodsServicesForRegistration.TaxInvoiceNumber		AS TaxInvoiceNumber,
	|	GoodsServicesForRegistration.Customer			AS Customer,
	|	GoodsServicesForRegistration.CustomerInvoiceIssued			AS CustomerInvoiceIssued,
	|	GoodsServicesForRegistration.IssuedTaxInvoiceOfCommissionAgent			AS IssuedTaxInvoiceOfCommissionAgent,
	|	GoodsServicesForRegistration.CCDNumber				AS CCDNumber,
	|	GoodsServicesForRegistration.ThereIsVATSaleAmount	AS ThereIsVATSaleAmount
	|
	|FROM
	|	GoodsServicesForRegistration AS GoodsServicesForRegistration
	|
	|ORDER BY
	|	TaxInvoiceDate DESC
	|
	|TOTALS
	|	SUM(Count),
	|	SUM(CountBalance)
	|BY
	|	Products,
	|	Characteristic
	|";
	
	QueryResult = Query.Execute();
	
	FillInTsForGoodsForMakingReportsToCommitteeForPeriod(Object.Goods, QueryResult, ParametersStructure);
	
	If UsePartnerProducts Then
		PartnersProductsServer.FillInPartnerProductsByProductsInTable(Object.Goods, Object.Partner);
	EndIf;
	
	FillInSalePrices(Object);
	
EndProcedure

// Will fill in the sale price according to the document.
//
// Parameters:
//	Object - FormDataStructure - Document data
//
Procedure FillInSalePrices(Object) Export
	
	If ValueIsFilled(Object.Terms) Then
	
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		
		FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.Insert("PopulationFields",		"Price, VATRate");
		FillParameters.Insert("Date",				?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
		FillParameters.Insert("Currency",				Object.Currency);
		FillParameters.Insert("Terms",			Object.Terms);
		FillParameters.Insert("VATTaxation",	Object.VATTaxation);
		FillParameters.Insert("Organization",			Object.Organization);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount",		"NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountWithVAT",	StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateVATAmount",	StructureOfRecalculationOfAmount);
		
		If ValueIsFilled(Object.Counterparty) Then
			BatchProcessingOfTablePartClientServerLocalization.AddActionOfFillingInVATRateForSettingUpAccounting(Object, StructureOfActions);
		EndIf;
		
		PartnerPricesFillingServer.FillInPrices(Object.Goods, Undefined, FillParameters, StructureOfActions);
	Else
		FillInAmountWithVAT(Object.Goods, Object.PriceIncludesVAT);
	EndIf;
	
EndProcedure

// Recalculates the amounts of sales documents
// and Forms a temporary table of "Goods for registration" and "Services for registration" based on the results of sales of commission goods for the period.
//
// Parameters:
//	ParametersStructure - Structure - request parameters.
//	TempTablesManager - TempTablesManager - a temporary table manager that stores the query result.
//
Procedure GenerateDataForReportToCommittee(ParametersStructure, TempTablesManager) Export
	
	InitialDataForPreparationOfReportToCommitteeForPeriod(ParametersStructure, TempTablesManager);

	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.Text = 
		"SELECT
		|	GoodsSaleDocuments.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
		|	FROM DocumentsCustomerInvoice AS GoodsSaleDocuments
		|";
		
		DocumentsToBeRecalculated = Query.Execute().Unload().UnloadColumn("DocumentSalesOfGoodsAndServices");
		If DocumentsToBeRecalculated.Count() > 0 Then
			If ExchangePlans.MasterNode() = Undefined Then
				BackdateJobQueue.CompleteTasksInNonOperationalQueueBasedOnListOfDocuments(DocumentsToBeRecalculated,
					Catalogs.BackdateJobKinds.UpdateFinancialRegistersRecords);
			Else
				InformationRegisters.DocumentAmountsInAccountingCurrency.CalculateDocumentAmountsInAccountingCurrencies(DocumentsToBeRecalculated);
			EndIf;
		EndIf;
		
	EndIf;
	
	RequestForGoodsAndServicesForMakingReportsToCommitteeForPeriod(ParametersStructure, TempTablesManager);
	
EndProcedure

// Generates temporary tables for the subsequent receipt of data on the data for the report to the committee.
// "Vtobor" - initial parameters
// "Types of stocks" - types of stocks used
// "VtTovaryKOformleniyUtbor" - data on the goods sold by the committee for the period
// "Documentsrealization of goods and services" - data on sales documents of commission goods and services.
// Parameters:
//	ParametersStructure - Structure - request parameters.
//	TempTablesManager - TempTablesManager - a temporary table manager that stores the query result.
//
Procedure InitialDataForPreparationOfReportToCommitteeForPeriod(ParametersStructure, TempTablesManager) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	&Organization         AS Organization,
	|	&Consignor            AS Principal,
	|	&Currency              AS Currency,
	|	&Terms          AS Terms,
	|	&DocumentSales     AS DocumentSales,
	|	&ThereIsVATSaleAmount AS ThereIsVATSaleAmount
	|INTO TTSelection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.Ref AS InventoryOwnerAttribute
	|INTO TTTypesOfStocks
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|
	|WHERE
	|	InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND InventoryKinds.Organization = &Organization
	|	AND InventoryKinds.GoodsOwner = &Consignor
	|	AND (InventoryKinds.Terms = &Terms
	|		OR &Terms IN (UNDEFINED,
	|							VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)))
	|	AND (InventoryKinds.Counterparty = &Counterparty
	|		OR &Counterparty IN (UNDEFINED,
	|							VALUE(Catalog.Counterparties.EmptyRef),
	|							VALUE(Catalog.Companies.EmptyRef)))
	|	AND (InventoryKinds.Contract = &Contract
	|		OR InventoryKinds.Contract IN (UNDEFINED,
	|									VALUE(Catalog.CounterpartyContracts.EmptyRef),
	|									VALUE(Catalog.IntercompanyContracts.EmptyRef))
	|			AND &Contract IN (UNDEFINED,
	|							VALUE(Catalog.CounterpartyContracts.EmptyRef),
	|							VALUE(Catalog.IntercompanyContracts.EmptyRef)))
	|	AND (InventoryKinds.VATTaxation = &VATTaxation
	|		OR InventoryKinds.VATTaxation = VALUE(Enum.VATTaxationTypes.EmptyRef))
	|	AND InventoryKinds.Currency = &Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToBeRegisteredInReportsToConsignorBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsToBeRegisteredInReportsToConsignorBalance.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	GoodsToBeRegisteredInReportsToConsignorBalance.CCDNumber                   AS CCDNumber,
	|	GoodsToBeRegisteredInReportsToConsignorBalance.Currency                     AS Currency,
	|	GoodsToBeRegisteredInReportsToConsignorBalance.DocumentSales            AS DocumentSales,
	|	&ThereIsCCDNumber                                                       AS ThereIsCCDNumber,
	|	&Organization                                                        AS Organization,
	|	&ThereIsVATSaleAmount                                                AS ThereIsVATSaleAmount
	|INTO TTProductsForRegistrationSelection
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Balance(&BorderEndOfPeriod,
	|			InventoryOwnerAttribute IN
	|				(SELECT
	|					InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|				FROM
	|					TTTypesOfStocks AS InventoryKinds)
	|				AND DocumentSales = &DocumentSales
	|	
	|	) AS GoodsToBeRegisteredInReportsToConsignorBalance
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute,
	|	CCDNumber,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CASE
	|		WHEN GoodsForRegistration.Recorder REFS Document.SaleAdjustment
	|				AND (CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|				OR CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties))
	|			OR CAST(GoodsForRegistration.Recorder AS Document.ReturnOfGoodsFromCustomer).BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|			THEN GoodsForRegistration.Recorder
	|		WHEN NOT ReturnOfGoodsFromCustomer.Ref IS NULL
	|				AND NOT ReturnOfGoodsFromCustomer.CustomerVATExempt
	|			THEN UNDEFINED
	|		ELSE GoodsForRegistration.DocumentSalesOfGoodsAndServices
	|	END                                     AS DocumentSalesOfGoodsAndServices
	|
	|INTO DocumentsCustomerInvoice
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS GoodsForRegistration
	|		LEFT JOIN Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|		ON GoodsForRegistration.Recorder = ReturnOfGoodsFromCustomer.Ref
	|		
	|		LEFT JOIN Document.CustomerInvoice AS CustomerInvoice
	|		ON GoodsForRegistration.DocumentSalesOfGoodsAndServices = CustomerInvoice.Ref
	|		
	|		LEFT JOIN Document.CustomerInvoiceIntercompany AS GoodsHandover
	|		ON GoodsForRegistration.DocumentSalesOfGoodsAndServices = GoodsHandover.Ref
	|		
	|		INNER JOIN TTProductsForRegistrationSelection AS ProductsForRegistration_Selection
	|		ON GoodsForRegistration.ItemsLocationAttributes = ProductsForRegistration_Selection.ItemsLocationAttributes
	|			AND GoodsForRegistration.InventoryOwnerAttribute = ProductsForRegistration_Selection.InventoryOwnerAttribute
	|			AND GoodsForRegistration.CCDNumber = ProductsForRegistration_Selection.CCDNumber
	|			AND GoodsForRegistration.Currency = ProductsForRegistration_Selection.Currency
	|			AND GoodsForRegistration.DocumentSales = ProductsForRegistration_Selection.DocumentSales
	|		
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON GoodsForRegistration.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|
	|WHERE
	|	GoodsForRegistration.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND GoodsForRegistration.Active
	|	AND &NewOnlineARAPAccounting
	|
	|GROUP BY
	|	CASE
	|		WHEN GoodsForRegistration.Recorder REFS Document.SaleAdjustment
	|				AND (CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|				OR CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties))
	|			OR CAST(GoodsForRegistration.Recorder AS Document.ReturnOfGoodsFromCustomer).BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|			THEN GoodsForRegistration.Recorder
	|		WHEN NOT ReturnOfGoodsFromCustomer.Ref IS NULL
	|				AND NOT ReturnOfGoodsFromCustomer.CustomerVATExempt
	|			THEN UNDEFINED
	|		ELSE GoodsForRegistration.DocumentSalesOfGoodsAndServices
	|	END
	|
	|HAVING
	|	SUM(GoodsForRegistration.QuantityToRegister) <> 0
	|	OR SUM(GoodsForRegistration.RevenueAmountToRegister) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	ServicesForRegistration.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|
	|FROM
	|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal AS ServicesForRegistration
	|
	|	INNER JOIN TTSelection AS Filter
	|	ON ServicesForRegistration.Organization = Filter.Organization
	|		AND ServicesForRegistration.ItemsLocationAttributes.StorageLocation = Filter.Principal
	|		AND ServicesForRegistration.Currency = Filter.Currency
	|		AND ServicesForRegistration.Terms = Filter.Terms
	|		AND ServicesForRegistration.DocumentSales = Filter.DocumentSales
	|
	|WHERE
	|	ServicesForRegistration.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ServicesForRegistration.Active
	|	AND &NewOnlineARAPAccounting
	|
	|GROUP BY
	|	ServicesForRegistration.DocumentSalesOfGoodsAndServices
	|
	|HAVING
	|	SUM(CASE WHEN ServicesForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|		ServicesForRegistration.Count
	|	ELSE
	|		-ServicesForRegistration.Count
	|	END) <> 0
	|	OR SUM(CASE WHEN ServicesForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|		ServicesForRegistration.RevenueAmount
	|	ELSE
	|		-ServicesForRegistration.RevenueAmount
	|	END) <> 0
	|";
	
	Query.SetParameter("BeginOfPeriod",			ParametersStructure.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",			ParametersStructure.EndOfPeriod);
	Query.SetParameter("BorderEndOfPeriod",	New Boundary(ParametersStructure.EndOfPeriod,
																		BoundaryType.Including));
	Query.SetParameter("Organization",			ParametersStructure.Organization);
	Query.SetParameter("Consignor",				ParametersStructure.Partner);
	Query.SetParameter("Counterparty",				ParametersStructure.Counterparty);
	Query.SetParameter("Terms",				ParametersStructure.Terms);
	Query.SetParameter("Contract",				ParametersStructure.Contract);
	Query.SetParameter("Currency",					ParametersStructure.Currency);
	Query.SetParameter("VATTaxation",		ParametersStructure.VATTaxation);
	Query.SetParameter("ThereIsCCDNumber",			ParametersStructure.ThereIsCCDNumber);
	Query.SetParameter("ThereIsVATSaleAmount",	ParametersStructure.ThereIsVATSaleAmount);
	Query.SetParameter("DocumentSales",		ParametersStructure.DocumentSales);
	Query.SetParameter("NewOnlineARAPAccounting", GetFunctionalOption("NewOnlineARAPAccounting"));
	
	Query.Execute();
	
EndProcedure

// Generates a temporary table of "Merchandise services for registration" based on the results of sales of commission goods for the period.
//
// Parameters:
//	ParametersStructure - Structure - request parameters.
//	TempTablesManager - TempTablesManager - a temporary table manager that stores the query result.
//
Procedure RequestForGoodsAndServicesForMakingReportsToCommitteeForPeriod(ParametersStructure, TempTablesManager) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	ProductsForRegistration_Selection.Organization              AS Organization,
	|	GoodsForRegistration.ItemsLocationAttributes    AS ItemsLocationAttributes,
	|	InventoryLocationAttributeKeys.Products    AS Products,
	|	InventoryLocationAttributeKeys.Characteristic  AS Characteristic,
	|	SUM(CASE
	|			WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN GoodsForRegistration.QuantityToRegister
	|			ELSE -GoodsForRegistration.QuantityToRegister
	|		END)                                      AS Count,
	|	SUM(CASE
	|			WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN GoodsForRegistration.RevenueAmountToRegister
	|			ELSE -GoodsForRegistration.RevenueAmountToRegister
	|		END)                                      AS RevenueAmount,
	|	CASE
	|		WHEN GoodsForRegistration.Recorder REFS Document.SaleAdjustment
	|				AND (CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|				OR CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties))
	|			OR CAST(GoodsForRegistration.Recorder AS Document.ReturnOfGoodsFromCustomer).BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|			THEN GoodsForRegistration.Recorder
	|		WHEN NOT ReturnOfGoodsFromCustomer.Ref IS NULL
	|				AND NOT ReturnOfGoodsFromCustomer.CustomerVATExempt
	|			THEN UNDEFINED
	|		ELSE GoodsForRegistration.DocumentSalesOfGoodsAndServices
	|	END                                           AS DocumentSalesOfGoodsAndServices,
	|	GoodsForRegistration.TaxInvoiceDate              AS TaxInvoiceDate,
	|	GoodsForRegistration.TaxInvoiceNumber             AS TaxInvoiceNumber,
	|	CASE
	|		WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.RetailSalesReport)
	|			THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|		WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoice)
	|			THEN CustomerInvoice.Counterparty
	|		WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoiceIntercompany)
	|			THEN GoodsHandover.CompanyRecipient
	|		WHEN VALUETYPE(GoodsForRegistration.Recorder) = TYPE(Document.ReturnOfGoodsFromCustomer)
	|			THEN ReturnOfGoodsFromCustomer.Counterparty
	|		WHEN GoodsForRegistration.Customer = UNDEFINED
	|				OR GoodsForRegistration.Customer = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|		ELSE GoodsForRegistration.Customer
	|	END                                           AS Customer,
	|	CASE
	|		WHEN ProductsForRegistration_Selection.ThereIsCCDNumber
	|				AND ISNULL(InventoryLocationAttributeKeys.Products.TracedGoods, FALSE)
	|			THEN GoodsForRegistration.CCDNumber
	|		ELSE UNDEFINED
	|	END                                           AS CCDNumber,
	|	CASE
	|		WHEN GoodsForRegistration.QuantityToRegister >= 0
	|			THEN 1
	|		ELSE -1
	|	END                                           AS Character,
	|	ProductsForRegistration_Selection.ThereIsVATSaleAmount      AS ThereIsVATSaleAmount
	|INTO GoodsForRegistration
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS GoodsForRegistration
	|		LEFT JOIN Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|		ON GoodsForRegistration.Recorder = ReturnOfGoodsFromCustomer.Ref
	|		
	|		LEFT JOIN Document.CustomerInvoice AS CustomerInvoice
	|		ON GoodsForRegistration.DocumentSalesOfGoodsAndServices = CustomerInvoice.Ref
	|		
	|		LEFT JOIN Document.CustomerInvoiceIntercompany AS GoodsHandover
	|		ON GoodsForRegistration.DocumentSalesOfGoodsAndServices = GoodsHandover.Ref
	|		
	|		INNER JOIN TTProductsForRegistrationSelection AS ProductsForRegistration_Selection
	|		ON GoodsForRegistration.ItemsLocationAttributes = ProductsForRegistration_Selection.ItemsLocationAttributes
	|			AND GoodsForRegistration.InventoryOwnerAttribute = ProductsForRegistration_Selection.InventoryOwnerAttribute
	|			AND GoodsForRegistration.CCDNumber = ProductsForRegistration_Selection.CCDNumber
	|			AND GoodsForRegistration.Currency = ProductsForRegistration_Selection.Currency
	|			AND GoodsForRegistration.DocumentSales = ProductsForRegistration_Selection.DocumentSales
	|		
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON GoodsForRegistration.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|
	|WHERE
	|	GoodsForRegistration.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND GoodsForRegistration.Active
	|	AND GoodsForRegistration.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|
	|GROUP BY
	|	ProductsForRegistration_Selection.Organization,
	|	GoodsForRegistration.ItemsLocationAttributes,
	|	InventoryLocationAttributeKeys.Products,
	|	InventoryLocationAttributeKeys.Characteristic,
	|	CASE
	|		WHEN GoodsForRegistration.Recorder REFS Document.SaleAdjustment
	|				AND (CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|				OR CAST(GoodsForRegistration.Recorder AS Document.SaleAdjustment).AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties))
	|			OR CAST(GoodsForRegistration.Recorder AS Document.ReturnOfGoodsFromCustomer).BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|			THEN GoodsForRegistration.Recorder
	|		WHEN NOT ReturnOfGoodsFromCustomer.Ref IS NULL
	|				AND NOT ReturnOfGoodsFromCustomer.CustomerVATExempt
	|			THEN UNDEFINED
	|		ELSE GoodsForRegistration.DocumentSalesOfGoodsAndServices
	|	END,
	|	GoodsForRegistration.TaxInvoiceDate,
	|	GoodsForRegistration.TaxInvoiceNumber,
	|	CASE
	|		WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.RetailSalesReport)
	|			THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|		WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoice)
	|			THEN CustomerInvoice.Counterparty
	|		WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoiceIntercompany)
	|			THEN GoodsHandover.CompanyRecipient
	|		WHEN VALUETYPE(GoodsForRegistration.Recorder) = TYPE(Document.ReturnOfGoodsFromCustomer)
	|			THEN ReturnOfGoodsFromCustomer.Counterparty
	|		WHEN GoodsForRegistration.Customer = UNDEFINED
	|				OR GoodsForRegistration.Customer = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|		ELSE GoodsForRegistration.Customer
	|	END,
	|	CASE
	|		WHEN ProductsForRegistration_Selection.ThereIsCCDNumber
	|				AND ISNULL(InventoryLocationAttributeKeys.Products.TracedGoods, FALSE)
	|			THEN GoodsForRegistration.CCDNumber
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN GoodsForRegistration.QuantityToRegister >= 0
	|			THEN 1
	|		ELSE -1
	|	END,
	|	ProductsForRegistration_Selection.ThereIsVATSaleAmount
	|
	|HAVING
	|	SUM(GoodsForRegistration.QuantityToRegister) <> 0
	|	OR SUM(GoodsForRegistration.RevenueAmountToRegister) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	ProductsForRegistration_Selection.Organization              AS Organization,
	|	GoodsForRegistration.ItemsLocationAttributes    AS ItemsLocationAttributes,
	|	InventoryLocationAttributeKeys.Products    AS Products,
	|	InventoryLocationAttributeKeys.Characteristic  AS Characteristic,
	|	SUM(CASE
	|			WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN GoodsForRegistration.QuantityToRegister
	|			ELSE -GoodsForRegistration.QuantityToRegister
	|		END)                                      AS Count,
	|	SUM(CASE
	|			WHEN GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN GoodsForRegistration.RevenueAmountToRegister
	|			ELSE -GoodsForRegistration.RevenueAmountToRegister
	|		END)                                      AS RevenueAmount,
	|	SalesOfGoodsServicesGoods.SalesOrder       AS DocumentSalesOfGoodsAndServices,
	|	GoodsForRegistration.TaxInvoiceDate              AS TaxInvoiceDate,
	|	GoodsForRegistration.TaxInvoiceNumber             AS TaxInvoiceNumber,
	|	CASE
	|		WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoice)
	|			THEN SalesOfGoodsServicesGoods.Ref.Counterparty
	|		ELSE GoodsForRegistration.Customer
	|	END                                           AS Customer,
	|	CASE
	|		WHEN ProductsForRegistration_Selection.ThereIsCCDNumber
	|				AND ISNULL(InventoryLocationAttributeKeys.Products.TracedGoods, FALSE)
	|			THEN GoodsForRegistration.CCDNumber
	|		ELSE UNDEFINED
	|	END                                           AS CCDNumber,
	|	CASE
	|		WHEN GoodsForRegistration.QuantityToRegister >= 0
	|			THEN 1
	|		ELSE -1
	|	END                                           AS Character,
	|	ProductsForRegistration_Selection.ThereIsVATSaleAmount      AS ThereIsVATSaleAmount
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS GoodsForRegistration
	|		
	|		INNER JOIN TTProductsForRegistrationSelection AS ProductsForRegistration_Selection
	|		ON GoodsForRegistration.ItemsLocationAttributes = ProductsForRegistration_Selection.ItemsLocationAttributes
	|			AND GoodsForRegistration.InventoryOwnerAttribute = ProductsForRegistration_Selection.InventoryOwnerAttribute
	|			AND GoodsForRegistration.CCDNumber = ProductsForRegistration_Selection.CCDNumber
	|			AND GoodsForRegistration.Currency = ProductsForRegistration_Selection.Currency
	|			AND GoodsForRegistration.DocumentSales = ProductsForRegistration_Selection.DocumentSales
	|		
	|		LEFT JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|		ON SalesOfGoodsServicesGoods.Ref = GoodsForRegistration.DocumentSalesOfGoodsAndServices
	|			AND SalesOfGoodsServicesGoods.Products = GoodsForRegistration.Products
	|			AND SalesOfGoodsServicesGoods.Characteristic = GoodsForRegistration.Characteristic
	|		
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON GoodsForRegistration.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|
	|WHERE
	|	GoodsForRegistration.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND GoodsForRegistration.Active
	|	AND GoodsForRegistration.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|
	|GROUP BY
	|	ProductsForRegistration_Selection.Organization,
	|	GoodsForRegistration.ItemsLocationAttributes,
	|	InventoryLocationAttributeKeys.Products,
	|	InventoryLocationAttributeKeys.Characteristic,
	|	SalesOfGoodsServicesGoods.SalesOrder,
	|	GoodsForRegistration.TaxInvoiceDate,
	|	GoodsForRegistration.TaxInvoiceNumber,
	|	CASE
	|		WHEN VALUETYPE(GoodsForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.CustomerInvoice)
	|			THEN SalesOfGoodsServicesGoods.Ref.Counterparty
	|		ELSE GoodsForRegistration.Customer
	|	END,
	|	CASE
	|		WHEN ProductsForRegistration_Selection.ThereIsCCDNumber
	|				AND ISNULL(InventoryLocationAttributeKeys.Products.TracedGoods, FALSE)
	|			THEN GoodsForRegistration.CCDNumber
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN GoodsForRegistration.QuantityToRegister >= 0
	|			THEN 1
	|		ELSE -1
	|	END,
	|	ProductsForRegistration_Selection.ThereIsVATSaleAmount
	|
	|HAVING
	|	SUM(GoodsForRegistration.QuantityToRegister) <> 0
	|	OR SUM(GoodsForRegistration.RevenueAmountToRegister) <> 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServicesForRegistration.Organization                               AS Organization,
	|	ServicesForRegistration.ItemsLocationAttributes                AS ItemsLocationAttributes,
	|	ServicesForRegistration.ItemsLocationAttributes.Products   AS Products,
	|	ServicesForRegistration.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	ServicesForRegistration.DocumentSalesOfGoodsAndServices                        AS DocumentSalesOfGoodsAndServices,
	|	ServicesForRegistration.TaxInvoiceDate                          AS TaxInvoiceDate,
	|	ServicesForRegistration.TaxInvoiceNumber                         AS TaxInvoiceNumber,
	|	CASE
	|		WHEN VALUETYPE(ServicesForRegistration.DocumentSalesOfGoodsAndServices) = TYPE(Document.RetailSalesReport)
	|			THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|		WHEN ServicesForRegistration.Customer = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|		ELSE ServicesForRegistration.Customer
	|	END                                                       AS Customer,
	|	SUM(CASE WHEN ServicesForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|		ServicesForRegistration.Count
	|	ELSE
	|		-ServicesForRegistration.Count
	|	END)                                                      AS Count,
	|	
	|	SUM(CASE WHEN ServicesForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|		ServicesForRegistration.RevenueAmount
	|	ELSE
	|		-ServicesForRegistration.RevenueAmount
	|	END)                                                      AS RevenueAmount,
	|	Filter.ThereIsVATSaleAmount                                   AS ThereIsVATSaleAmount
	|
	|INTO ServicesForRegistration
	|FROM
	|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal AS ServicesForRegistration
	|
	|	INNER JOIN TTSelection AS Filter
	|	ON ServicesForRegistration.Organization = Filter.Organization
	|		AND ServicesForRegistration.ItemsLocationAttributes.StorageLocation = Filter.Principal
	|		AND ServicesForRegistration.Currency = Filter.Currency
	|		AND ServicesForRegistration.Terms = Filter.Terms
	|		AND ServicesForRegistration.DocumentSales = Filter.DocumentSales
	|
	|WHERE
	|	ServicesForRegistration.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ServicesForRegistration.Active
	|
	|GROUP BY
	|	ServicesForRegistration.Organization,
	|	ServicesForRegistration.ItemsLocationAttributes.Products,
	|	ServicesForRegistration.ItemsLocationAttributes.Characteristic,
	|	ServicesForRegistration.TaxInvoiceDate,
	|	ServicesForRegistration.TaxInvoiceNumber,
	|	ServicesForRegistration.Customer,
	|	ServicesForRegistration.ItemsLocationAttributes,
	|	ServicesForRegistration.DocumentSalesOfGoodsAndServices,
	|	Filter.ThereIsVATSaleAmount
	|
	|HAVING
	|	SUM(CASE WHEN ServicesForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|		ServicesForRegistration.Count
	|	ELSE
	|		-ServicesForRegistration.Count
	|	END) <> 0
	|	OR SUM(CASE WHEN ServicesForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|		ServicesForRegistration.RevenueAmount
	|	ELSE
	|		-ServicesForRegistration.RevenueAmount
	|	END) <> 0
	|
	|INDEX BY
	|	ServicesForRegistration.ItemsLocationAttributes.Products,
	|	ServicesForRegistration.ItemsLocationAttributes.Characteristic
	|";
	
	Query.SetParameter("BeginOfPeriod", ParametersStructure.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  ParametersStructure.EndOfPeriod);
	
	Query.Execute();
	
	VATAccountingERP.SupplementTableWithDataOfInvoicesIssuedToCustomers(TempTablesManager, "GoodsForRegistration");
	VATAccountingERP.SupplementTableWithDataOfInvoicesIssuedToCustomers(TempTablesManager, "ServicesForRegistration");
	
	Query.Text = 
	"SELECT
	|	GoodsForRegistration.Products			AS Products,
	|	GoodsForRegistration.Characteristic		AS Characteristic,
	|	SUM(GoodsForRegistration.Count)		AS Count,
	|	SUM(GoodsForRegistration.Count)		AS CountBalance,
	|	SUM(GoodsForRegistration.RevenueAmount)	AS SalesAmount,
	|	GoodsForRegistration.TaxInvoiceDate		AS TaxInvoiceDate,
	|	GoodsForRegistration.TaxInvoiceDate		AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	GoodsForRegistration.TaxInvoiceNumber		AS TaxInvoiceNumber,
	|	GoodsForRegistration.Customer			AS Customer,
	|	GoodsForRegistration.TaxInvoice			AS CustomerInvoiceIssued,
	|	GoodsForRegistration.TaxInvoice			AS IssuedTaxInvoiceOfCommissionAgent,
	|	GoodsForRegistration.CCDNumber				AS CCDNumber,
	|	GoodsForRegistration.ThereIsVATSaleAmount	AS ThereIsVATSaleAmount
	|INTO GoodsServicesForRegistration
	|FROM
	|	GoodsForRegistration AS GoodsForRegistration
	|
	|GROUP BY
	|	GoodsForRegistration.Products,
	|	GoodsForRegistration.Characteristic,
	|	GoodsForRegistration.TaxInvoiceDate,
	|	GoodsForRegistration.TaxInvoiceNumber,
	|	GoodsForRegistration.Customer,
	|	GoodsForRegistration.TaxInvoice,
	|	GoodsForRegistration.CCDNumber,
	|	GoodsForRegistration.ThereIsVATSaleAmount
	|
	|HAVING
	|	SUM(GoodsForRegistration.Count) <> 0
	|	OR SUM(GoodsForRegistration.RevenueAmount) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	ServicesForRegistration.Products			AS Products,
	|	ServicesForRegistration.Characteristic		AS Characteristic,
	|	SUM(ServicesForRegistration.Count)		AS Count,
	|	SUM(ServicesForRegistration.Count)		AS CountBalance,
	|	SUM(ServicesForRegistration.RevenueAmount)	AS SalesAmount,
	|	ServicesForRegistration.TaxInvoiceDate		AS TaxInvoiceDate,
	|	ServicesForRegistration.TaxInvoiceDate		AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	ServicesForRegistration.TaxInvoiceNumber		AS TaxInvoiceNumber,
	|	ServicesForRegistration.Customer			AS Customer,
	|	ServicesForRegistration.TaxInvoice			AS CustomerInvoiceIssued,
	|	ServicesForRegistration.TaxInvoice			AS IssuedTaxInvoiceOfCommissionAgent,
	|	UNDEFINED							AS CCDNumber,
	|	ServicesForRegistration.ThereIsVATSaleAmount	AS ThereIsVATSaleAmount
	|FROM
	|	ServicesForRegistration AS ServicesForRegistration
	|
	|
	|GROUP BY
	|	ServicesForRegistration.Products,
	|	ServicesForRegistration.Characteristic,
	|	ServicesForRegistration.TaxInvoiceDate,
	|	ServicesForRegistration.TaxInvoiceNumber,
	|	ServicesForRegistration.Customer,
	|	ServicesForRegistration.TaxInvoice,
	|	ServicesForRegistration.ThereIsVATSaleAmount
	|
	|HAVING
	|	SUM(ServicesForRegistration.Count) <> 0
	|	OR SUM(ServicesForRegistration.RevenueAmount) <> 0
	|
	|;
	|DROP GoodsForRegistration
	|;
	|DROP ServicesForRegistration
	|";
	
	Query.Execute();
	
EndProcedure

// Fills in the tabular part of the object according to the temporary table "Product Registration".
//
// Parameters:
//	TabularSection - TabularSection - the tabular part of the object to fill in.
//	QueryResult - QueryResult - the result of the query, according to which it is necessary to fill in the object table.
//	FillParameters - Structure - parameters for filling in the table part that contain the following values:
//					* Date - Date - document date.
//					* Organization - CatalogRef.Companies - Organization of the document.
//					* VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the document.
//
Procedure FillInTsForGoodsForMakingReportsToCommitteeForPeriod(TabularSection,
																	QueryResult,
																	FillParameters) Export
	
	TabularSection.Clear();
	
	CachedValues = Undefined;
	
	StructureOfActions = New Structure;
	ActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(FillParameters);
	
	If FillParameters.Property("Partner")
		And TypeOf(FillParameters.Partner) = Type("CatalogRef.Companies") Then
		
		ActionParameters.Organization = FillParameters.Partner;
		
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", ActionParameters);
	
	If FillParameters.Property("StructureOfActions") Then
	 	CommonClientServer.SupplementStructure(StructureOfActions, FillParameters.StructureOfActions);
	EndIf;
	
	SelectionByProductType_ = QueryResult.Select(QueryResultIteration.ByGroups);
	DataIsAmountOfVATSales = New Map;

	While SelectionByProductType_.Next() Do
		
		SelectionByCharacteristic = SelectionByProductType_.Select(QueryResultIteration.ByGroups);
		
		While SelectionByCharacteristic.Next() Do
			
			If SelectionByCharacteristic.CountBalance >= SelectionByCharacteristic.Count Then
				
				Selection = SelectionByCharacteristic.Select();
				
				While Selection.Next() Do
					AddLineByProductToCommitteeSReportingForPeriod(TabularSection,
																				FillParameters,
																				Selection,
																				Selection.Count,
																				StructureOfActions,
																				CachedValues);
					DataIsAmountOfVATSales.Insert(
						TabularSection[TabularSection.Count()-1],
						Selection.ThereIsVATSaleAmount);
				EndDo;
				
			Else
				
				QuantityToDistribution = SelectionByCharacteristic.Count;
				
				Selection = SelectionByCharacteristic.Select();
				
				While Selection.Next() Do
				
					If Selection.Count <= QuantityToDistribution Then
						AddLineByProductToCommitteeSReportingForPeriod(TabularSection,
																					FillParameters,
																					Selection,
																					Selection.Count,
																					StructureOfActions,
																					CachedValues);
						
						QuantityToDistribution = QuantityToDistribution - Selection.Count;

						DataIsAmountOfVATSales.Insert(
							TabularSection[TabularSection.Count()-1],
							Selection.ThereIsVATSaleAmount);
					Else
						AddLineByProductToCommitteeSReportingForPeriod(TabularSection,
																					FillParameters,
																					Selection,
																					QuantityToDistribution,
																					StructureOfActions,
																					CachedValues);
						
						QuantityToDistribution = 0;

						DataIsAmountOfVATSales.Insert(
							TabularSection[TabularSection.Count()-1],
							Selection.ThereIsVATSaleAmount);
					EndIf;
					
					If QuantityToDistribution = 0 Then
						Break;
					EndIf;
				
				EndDo;
			
			EndIf;
			
		EndDo;
		
	EndDo;

	BatchProcessingOfTablePartServer.TreatTS(
		TabularSection, StructureOfActions, CachedValues);
		
	For Each TSRow In DataIsAmountOfVATSales Do
		If TSRow.Value Then
			TSRow.Key.AmountSalesVAT = AmountSalesVAT(
				TSRow.Key.SalesAmount, TSRow.Key.VATRate);
		EndIf;
	EndDo;
	
EndProcedure

// Procedure for filling in the document for the remaining goods transferred to the Commission
//
// Parameters:
//	Object - DocumentObject - Current document
//	EndOfPeriod - Date - Date of filling in
//	ThereIsSaleAmount - Boolean - The document provides information about the amount of the sale.
//
Procedure FillInBalanceOfGoodsTransferredToCommission(Object, EndOfPeriod, ThereIsSaleAmount) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsTransferred.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	CASE
	|		WHEN &TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
	|				OR NOT ISNULL(GoodsTransferred.ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|			THEN UNDEFINED
	|		ELSE GoodsTransferred.CCDNumber
	|	END										AS CCDNumber,
	|	SUM(GoodsTransferred.CountBalance)	AS CountBalance,
	|	SUM(CASE
	|			WHEN &TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
	|				THEN 0
	|			ELSE GoodsTransferred.QuantityByGBRNBalance
	|		END)									AS QuantityByGBRNBalance
	|INTO GoodsTransferred
	|FROM
	|	AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(&Boundary,
	|			Organization = &Organization
	|			AND ItemsLocationAttributes.Partner = &Partner
	|			AND Terms = &Terms
	|	
	|	) AS GoodsTransferred
	|
	|GROUP BY
	|	GoodsTransferred.ItemsLocationAttributes,
	|	CASE
	|		WHEN &TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
	|				OR NOT ISNULL(GoodsTransferred.ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|			THEN UNDEFINED
	|		ELSE GoodsTransferred.CCDNumber
	|	END
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTransferred.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	CASE
	|		WHEN &TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
	|				OR NOT ISNULL(GoodsTransferred.ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|			THEN UNDEFINED
	|		ELSE GoodsTransferred.CCDNumber
	|	END										AS CCDNumber,
	|	SUM(GoodsTransferred.CountBalance)	AS CountBalance,
	|	SUM(CASE
	|			WHEN &TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
	|				THEN 0
	|			ELSE GoodsTransferred.QuantityByGBRNBalance
	|		END)									AS QuantityByGBRNBalance,
	|	CASE
	|		WHEN GoodsTransferred.CountBalance < 0
	|			THEN -1
	|		ELSE 1
	|	END AS Character
	|INTO GoodsTransferredBalance
	|FROM
	|	AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(,
	|			Organization = &Organization
	|			AND ItemsLocationAttributes.Partner = &Partner
	|			AND Terms = &Terms
	|	
	|	) AS GoodsTransferred
	|
	|GROUP BY
	|	GoodsTransferred.ItemsLocationAttributes,
	|	CASE
	|		WHEN &TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
	|				OR NOT ISNULL(GoodsTransferred.ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|			THEN UNDEFINED
	|		ELSE GoodsTransferred.CCDNumber
	|	END,
	|	CASE
	|		WHEN GoodsTransferred.CountBalance < 0
	|			THEN -1
	|		ELSE 1
	|	END
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	CCDNumber
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTransferred.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	GoodsTransferred.ItemsLocationAttributes.Products	AS Products,
	|	GoodsTransferred.ItemsLocationAttributes.Characteristic	AS Characteristic,
	|	GoodsTransferred.ItemsLocationAttributes.Series			AS Series,
	|	GoodsTransferred.CCDNumber									AS CCDNumber,
	|	CASE
	|		WHEN ISNULL(GoodsTransferredBalance.CountBalance * GoodsTransferredBalance.Character, 0)
	|				< (GoodsTransferred.CountBalance * ISNULL(GoodsTransferredBalance.Character, 1))
	|			THEN ISNULL(GoodsTransferredBalance.CountBalance, 0)
	|		ELSE GoodsTransferred.CountBalance
	|	END AS Count,
	|	CASE
	|		WHEN ISNULL(GoodsTransferredBalance.QuantityByGBRNBalance * GoodsTransferredBalance.Character, 0)
	|				< (GoodsTransferred.QuantityByGBRNBalance * ISNULL(GoodsTransferredBalance.Character, 1))
	|			THEN ISNULL(GoodsTransferredBalance.QuantityByGBRNBalance, 0)
	|		ELSE GoodsTransferred.QuantityByGBRNBalance
	|	END AS QuantityByGBRN
	|FROM
	|	GoodsTransferred AS GoodsTransferred
	|		LEFT JOIN GoodsTransferredBalance AS GoodsTransferredBalance
	|		ON GoodsTransferred.ItemsLocationAttributes = GoodsTransferredBalance.ItemsLocationAttributes
	|			AND GoodsTransferred.CCDNumber = GoodsTransferredBalance.CCDNumber
	|
	|WHERE
	|	GoodsTransferred.CountBalance <> 0
	|	AND ISNULL(GoodsTransferredBalance.CountBalance, 0) <> 0
	|
	|ORDER BY
	|	GoodsTransferred.ItemsLocationAttributes";
	
	FillingDate	= ?(ValueIsFilled(EndOfPeriod), EndOfPeriod, CurrentSessionDate());
	Boundary			= New Boundary(EndOfDay(FillingDate), BoundaryType.Including);
	
	TheCommissionAgentDoesNotKeepRecordsOnTheRNPT = Not Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Object.Terms)
									Or Not AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	
	Query.SetParameter("Boundary",		Boundary);
	Query.SetParameter("Organization",	Object.Organization);
	Query.SetParameter("Partner",		Object.Partner);
	Query.SetParameter("Terms",		Object.Terms);
	Query.SetParameter("TheCommissionAgentDoesNotKeepRecordsOnTheRNPT", TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	
	Object.Goods.Clear();
	
	AddedRows = New Array();
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.NumberOfPackagesAccounting = NewRow.Count;
		NewRow.NumberOfPackages = NewRow.Count;
		AddedRows.Add(NewRow);
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	VATRateParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	VATRateParameters.Date = FillingDate;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", VATRateParameters);
	
	If ValueIsFilled(Object.Counterparty) Then
		
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
		ParametersFillInVATRate.Date = FillingDate; 
		StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
		
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", FillingDate);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind");
	
	EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	For Each TableRow In Object.Goods Do
		TableRow.AmountIncludingVAT = TableRow.Sum + ?(Object.PriceIncludesVAT, 0, TableRow.VATAmount);
		If ThereIsSaleAmount Then
			TableRow.SalesAmount = TableRow.AmountIncludingVAT;
			TableRow.AmountSalesVAT = AmountSalesVAT(TableRow.SalesAmount, TableRow.VATRate);
			TableRow.SellingPrice = ?(TableRow.NumberOfPackages <> 0, TableRow.SalesAmount / TableRow.NumberOfPackages, 0);
		EndIf;
	EndDo;
	
EndProcedure

// Procedure for filling in the document for the remaining goods transferred to the Commission
//
// Parameters:
//	Object - DocumentObject - Current document
//	ConsignmentReportFromCustomer - Boolean
//
Procedure FillInGoodsOnBalancesTransferredToCommissionUnderNewScheme(Object, ConsignmentReportFromCustomer = True) Export
	
	If ConsignmentReportFromCustomer Then
		ColumnNameSalePrice = "SellingPrice";
		ColumnNameTypeOfSalePrices = "SellingPriceType";
	Else
		ColumnNameSalePrice = "Price";
		ColumnNameTypeOfSalePrices = "PriceKind";
	EndIf;
	
	QueryText = 
		"SELECT
		|	DimensionKeys.Ref AS Ref
		|INTO DimensionKeys
		|FROM
		|	Catalog.InventoryLocationAttributeKeys AS DimensionKeys
		|WHERE
		|	DimensionKeys.StorageLocation = &Contract
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT ALLOWED
		|	GoodsTransferred.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CASE
		|		WHEN &TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
		|				OR NOT ISNULL(GoodsTransferred.ItemsLocationAttributes.Products.TracedGoods, FALSE)
		|			THEN VALUE(Catalog.CCDNumbers.EmptyRef)
		|		ELSE GoodsTransferred.CCDNumber
		|	END                                       AS CCDNumber,
		|	GoodsTransferred.CountBalance          AS CountBalance,
		|	GoodsTransferred.QuantityByGBRNBalance    AS QuantityByGBRNBalance
		|INTO GoodsTransferred
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(,
		|			ItemsLocationAttributes IN
		|					(SELECT
		|						DimensionKeys.Ref
		|					FROM
		|						DimensionKeys AS DimensionKeys)
		|			AND Organization = &Organization) AS GoodsTransferred
		|
		|WHERE
		|	GoodsTransferred.CountBalance > 0
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 2
		|SELECT
		|	ISNULL(DimensionKeys.Products,
		|		VALUE(Catalog.Products.EmptyRef)) AS Products,
		|	ISNULL(DimensionKeys.Characteristic,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
		|	CASE
		|		WHEN Goods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE DimensionKeys.Purpose
		|	END                                         AS Purpose,
		|	ISNULL(DimensionKeys.Series,
		|		VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
		|	GoodsTransferred.CCDNumber                     AS CCDNumber,
		|	GoodsTransferred.CCDNumber.OriginCountry AS OriginCountry,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	SUM(GoodsTransferred.CountBalance)     AS Count,
		|	SUM(GoodsTransferred.CountBalance)     AS NumberOfPackages,
		|	SUM(GoodsTransferred.CountBalance)     AS NumberOfPackagesAccounting,
		|	SUM(GoodsTransferred.QuantityByGBRNBalance) AS QuantityByGBRN
		|FROM
		|	GoodsTransferred AS GoodsTransferred
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
		|		ON GoodsTransferred.ItemsLocationAttributes = DimensionKeys.Ref
		|
		|		LEFT JOIN Catalog.Products AS Goods
		|		ON DimensionKeys.Products = Goods.Ref
		|
		|GROUP BY
		|	ISNULL(DimensionKeys.Products, VALUE(Catalog.Products.EmptyRef)),
		|	ISNULL(DimensionKeys.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
		|	CASE
		|		WHEN Goods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE DimensionKeys.Purpose
		|	END,
		|	ISNULL(DimensionKeys.Series, VALUE(Catalog.ItemsBatches.EmptyRef)),
		|	GoodsTransferred.CCDNumber,
		|	Goods.UnitOfMeasure
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Series,
		|	CASE
		|		WHEN Goods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE DimensionKeys.Purpose
		|	END,
		|	CCDNumber";
	
	Query = New Query;
	Query.Text = QueryText;
	
	TheCommissionAgentDoesNotKeepRecordsOnTheRNPT = Not Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Object.Terms)
								Or Not AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Contract",     Object.Contract);
	Query.SetParameter("TheCommissionAgentDoesNotKeepRecordsOnTheRNPT", TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	
	RowsArray = New Array;
	
	TableOfGoods = Query.Execute().Unload();
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = DocumentDate;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	PriceIncludesVAT = Undefined;
	
	TypeOfContractPrice = Common.ObjectAttributesValues(Object.Contract, "PriceTypeAccountingPriceType, SalesPriceType");
	If ConsignmentReportFromCustomer And ValueIsFilled(TypeOfContractPrice.PriceTypeAccountingPriceType) Then
		PriceIncludesVAT = Common.ObjectAttributeValue(TypeOfContractPrice.PriceTypeAccountingPriceType,"PriceIncludesVAT");
	ElsIf Not ConsignmentReportFromCustomer And ValueIsFilled(TypeOfContractPrice.SalesPriceType) Then
		PriceIncludesVAT = Common.ObjectAttributeValue(TypeOfContractPrice.SalesPriceType,"PriceIncludesVAT");
	EndIf;
	
	If PriceIncludesVAT = Object.PriceIncludesVAT Then
		
		PriceFillingParameters = New Structure();
		PriceFillingParameters.Insert("PopulationFields",     "PriceKind, Price, VATRate");
		PriceFillingParameters.Insert("Date",               DocumentDate);
		PriceFillingParameters.Insert("Currency",             Object.Currency);
		PriceFillingParameters.Insert("Organization",        Object.Organization);
		PriceFillingParameters.Insert("VATTaxation", Object.VATTaxation);
		PriceFillingParameters.Insert("PriceKind",
							?(ConsignmentReportFromCustomer, TypeOfContractPrice.PriceTypeAccountingPriceType, TypeOfContractPrice.SalesPriceType));
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		
		For Each RowOfProduct In Object.Goods Do
			
			RowOfProduct[ColumnNameTypeOfSalePrices] = TypeOfContractPrice.SalesPriceType;
			RowsArray.Add(RowOfProduct);
			
		EndDo;
		
		StructureOfPriceCalculationActions = New Structure;
		StructureOfPriceCalculationActions.Insert("RecalculateAmount");
		StructureOfPriceCalculationActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
		StructureOfPriceCalculationActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfPriceCalculationActions.Insert("RecalculateNumberOfPackages");
		
		ParametersForFillingInSalePrice = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
		ParametersForFillingInSalePrice.Insert("NameOfPriceField", ColumnNameSalePrice);
		ParametersForFillingInSalePrice.Insert("ColumnNamePriceType", ColumnNameTypeOfSalePrices);
		ParametersForFillingInSalePrice.Insert("Date", DocumentDate);
		
		StructureOfPriceCalculationActions.Insert("FillInSalePrice", ParametersForFillingInSalePrice);
		
		If ConsignmentReportFromCustomer Then
			StructureOfPriceCalculationActions.Insert("RecalculateSaleAmount");
			StructureOfPriceCalculationActions.Insert("RecalculateVATSalesAmount");
		EndIf;
		
		StructureOfPriceCalculationActions.Insert("FillInVATRate", ParametersFillInVATRate);
		
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object);
		ParametersFillInVATRate.Date = DocumentDate;
		StructureOfPriceCalculationActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
		
		EnterprisePricesFillingServer.FillInPrices(Object.Goods,
													RowsArray,
													PriceFillingParameters,
													StructureOfPriceCalculationActions);
		
	ElsIf ValueIsFilled(Object.Terms) 
		And ValueIsFilled(Object.Contract)
		And PriceIncludesVAT <> Undefined Then
		
		ErrorText = NStr("vi = 'Trong thỏa thuận và trong dạng giá của hợp đồng có khác biệt về giá trị của dấu hiệu Đơn giá gồm thuế GTGT. Chưa điền dạng giá và đơn giá';
						|ru = 'В соглашении и у вида цен в договоре различаются значения признака Цена включает НДС. Виды цен и цены не будут заполнены.';
						|en = 'The Price includes VAT flag values are different in the agreement and the contract price type. Price types and prices will not be filled in.'; fa = 'The Price includes VAT flag values are different in the agreement and the contract price type. Price types and prices will not be filled in.';
						|it = 'Nell''accordo e nel tipo di prezzo nel contratto differiscono i valori del segno Prezzo include IVA. I tipi di prezzo e prezzi non saranno compilati.';
						|pl = 'W umowie i w rodzaju cen w umowie różnią się wartości oznaki Cena brutto. Rodzaje cen i ceny nie będą wypełnione.';
						|tr = 'Sözleşmede ve sözleşmedeki fiyat türünde, Fiyata KDV dahildir özelliğinin değerleri farklılık gösterir. Fiyat türleri ve fiyatlar doldurulmayacaktır.'");
		Common.MessageToUser(
			ErrorText,
			Object);
		
	EndIf;
	
EndProcedure

// Procedure for filling in the document column based on accounting data.
//
// Parameters:
//	Object - DocumentObject - Current document
//	EndOfPeriod - Date - Date of filling in
//	ThereIsSaleAmount - Boolean - The document provides information about the amount of the sale
//	CalculateRemuneration - Boolean - Indicates whether the Commission fee should be calculated.
//	LineNumber - Undefined, Number - 
//
Procedure RecalculateBalancesBasedOnAccountingData(Object, EndOfPeriod, ThereIsSaleAmount, CalculateRemuneration = False, LineNumber  = Undefined) Export
	
	Query = New Query("
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.CCDNumber AS CCDNumber,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	Goods.Package AS Package
	|
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	&LineNumber = UNDEFINED
	|	OR Goods.LineNumber = &LineNumber
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Dimension.DimensionKey AS DimensionKey
	|
	|INTO TTAnalytics_
	|FROM
	|	InformationRegister.ItemsLocationAttributes AS Dimension
	|
	|	INNER JOIN
	|		Goods AS Goods
	|	ON
	|		Dimension.Products = Goods.Products
	|		AND Dimension.Characteristic = Goods.Characteristic
	|		AND Dimension.Series = Goods.Series
	|		AND Dimension.Purpose = Goods.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Dimension.StorageLocation = &Partner
	|	OR Dimension.StorageLocation = &Contract
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.ItemsLocationAttributes.Products AS Products,
	|	Balance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	CASE
	|		WHEN &TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
	|				OR NOT ISNULL(Balance.ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|			THEN VALUE(Catalog.CCDNumbers.EmptyRef)
	|		ELSE Balance.CCDNumber
	|	END AS CCDNumber,
	|	Balance.ItemsLocationAttributes.Series AS Series,
	|	Balance.ItemsLocationAttributes.Purpose AS Purpose,
	|	Balance.CountBalance AS NumberOfPackagesAccounting
	|
	|INTO GoodsTransferred
	|FROM
	|	AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(&Boundary,
	|		Organization = &Organization
	|		AND Terms = &Terms
	|		AND ItemsLocationAttributes IN (
	|			SELECT
	|				Dimension.DimensionKey
	|			FROM
	|				TTAnalytics_ AS Dimension
	|			)
	|	) AS Balance
	|
	|UNION ALL
	|
	|SELECT
	|	Balance.ItemsLocationAttributes.Products AS Products,
	|	Balance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	CASE
	|		WHEN &TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
	|				OR NOT ISNULL(Balance.ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|			THEN VALUE(Catalog.CCDNumbers.EmptyRef)
	|		ELSE Balance.CCDNumber
	|	END AS CCDNumber,
	|	Balance.ItemsLocationAttributes.Series AS Series,
	|	Balance.ItemsLocationAttributes.Purpose AS Purpose,
	|	Balance.CountBalance AS NumberOfPackagesAccounting
	|
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(&Boundary,
	|		Organization = &Organization
	|		AND ItemsLocationAttributes IN (
	|			SELECT
	|				Dimension.DimensionKey
	|			FROM
	|				TTAnalytics_ AS Dimension
	|			)
	|	) AS Balance
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	CCDNumber,
	|	Series
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.Purpose AS Purpose,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio,
	|	ISNULL(GoodsTransferred.NumberOfPackagesAccounting, 0) AS NumberOfPackagesAccounting
	|FROM
	|	Goods AS Goods
	|
	|	LEFT JOIN
	|		GoodsTransferred AS GoodsTransferred
	|	ON
	|		Goods.Products = GoodsTransferred.Products
	|		AND Goods.Characteristic = GoodsTransferred.Characteristic
	|		AND Goods.CCDNumber = GoodsTransferred.CCDNumber
	|		AND Goods.Series = GoodsTransferred.Series
	|		AND Goods.Purpose = GoodsTransferred.Purpose
	|
	|	LEFT JOIN
	|		Catalog.PackagesAndUnitsOfMeasure AS Packages
	|	ON
	|		Goods.Package = Packages.Ref
	|
	|ORDER BY
	|	LineNumber
	|");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Packages",
		"Goods.Products"));

	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Partner", Object.Partner);
	Query.SetParameter("Terms", Object.Terms);
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("LineNumber", LineNumber);
	
	FillingDate = ?(ValueIsFilled(EndOfPeriod), EndOfPeriod, CurrentSessionDate());
	Boundary = New Boundary(EndOfDay(FillingDate), BoundaryType.Including);
	Query.SetParameter("Boundary", Boundary);
	
	TheCommissionAgentDoesNotKeepRecordsOnTheRNPT = Not Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Object.Terms)
								Or Not AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	
	Query.SetParameter("TheCommissionAgentDoesNotKeepRecordsOnTheRNPT", TheCommissionAgentDoesNotKeepRecordsOnTheRNPT);
	
	Goods = Object.Goods.Unload();
	Query.SetParameter("Goods", Goods);
	
	CachedValues = Undefined;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateAmount");
	
	If TypeOf(Object) = Type("FormDataStructure") Then
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions,
			"Partner");
	EndIf;
	
	RowsToProcess = New Array();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		TableRow = Object.Goods[Selection.LineNumber - 1];
		NumberOfPackagesAccounting = ?(Selection.ZoomRatio <> 0, Round(Selection.NumberOfPackagesAccounting / Selection.ZoomRatio, 2, 1), 0);
		If TableRow.NumberOfPackagesAccounting <> NumberOfPackagesAccounting Then
			
			TableRow.NumberOfPackagesAccounting = NumberOfPackagesAccounting;
			TableRow.NumberOfPackages = Selection.NumberOfPackagesAccounting - TableRow.NumberOfPackagesReal;
			
			RowsToProcess.Add(TableRow);
			
			CalculateRemuneration = True;
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	For Each TableRow In RowsToProcess Do
		
		TableRow.AmountIncludingVAT = TableRow.Sum + ?(Object.PriceIncludesVAT, 0, TableRow.VATAmount);
		If ThereIsSaleAmount Then
			TableRow.SalesAmount = TableRow.SellingPrice * TableRow.NumberOfPackages;
			TableRow.AmountSalesVAT = AmountSalesVAT(TableRow.SalesAmount, TableRow.VATRate);
		EndIf;
		
	EndDo;
	
EndProcedure

// The procedure fills in the amount with VAT in the rows of the "Products" table part.
//
// Parameters:
//  Goods - FormDataCollection - the table on which you want to fill the field of Summands.
//  PriceIncludesVAT - Boolean - Indicates whether VAT is included in the price.
//
Procedure FillInAmountWithVAT(Goods, PriceIncludesVAT) Export
	
	For Each TableRow In Goods Do
		TableRow.AmountIncludingVAT = TableRow.Sum
			+ ?(PriceIncludesVAT, 0, TableRow.VATAmount);
	EndDo;
	
EndProcedure

// The procedure fills in the sales VAT amount in the rows of the "Products" table part.
//
// Parameters:
//  Goods - FormDataCollection - the table on which you want to fill the field of Compromisings.
//
Procedure FillInVATSaleAmount(Goods) Export
	
	For Each TableRow In Goods Do
		TableRow.AmountSalesVAT = AmountSalesVAT(TableRow.SalesAmount, TableRow.VATRate);
	EndDo;
	
EndProcedure

// The procedure calculates the Commission fee.
//
// Parameters:
//	Object - FormDataStructure, FormDataCollectionItem - The current document or the current line.
//	VATPercentage - Number - VAT percentage.
//
Procedure CalculateAmountOfVATRemuneration(Object, VATPercentage) Export
	
	Object.AmountVATRemuneration = Round(Object.CommissionAmount * VATPercentage / (100 + VATPercentage), 2, RoundMode.Round15as20);
	
EndProcedure

// The procedure calculates the Commission fee line by line.
//
// Parameters:
//	Object - FormDataStructure - Current document.
//	VATPercentage - Number - VAT percentage.
//
Procedure CalculateAmountOfVATRemunerationInLines(Object, VATPercentage) Export
	
	For Each RowOfGoods In Object.Goods Do
		CalculateAmountOfVATRemuneration(RowOfGoods, VATPercentage);
	EndDo;
	
	Object.AmountVATRemuneration = Object.Goods.Total("AmountVATRemuneration");
	
EndProcedure

// The procedure calculates the Commission fee.
//
// Parameters:
//  Object - FormDataCollection - the object where the calculation is performed.
//  SumColumn - String - name of the column with the amount of the item for which the remuneration is calculated.
//  ThereIsSumOfNDSV - Boolean - indicates that the VAT amount of remuneration is calculated line-by-line.
//
Procedure CalculateRewardAmount(Object, SumColumn = "SalesAmount", ThereIsSumOfNDSV = False) Export
	
	VATPercentage = VATAccountingERPClientServer.ValueOfVATRate(Object.VATRateOfRemuneration);
	TotalSumColumn = Object.Goods.Total(SumColumn);
	MaxAmount = 0;
	
	For Each RowOfGoods In Object.Goods Do
		
		If Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.PercentageOfDifferenceBetweenSaleAmountAndConsignorAmount Then
			RowOfGoods.CommissionAmount = (RowOfGoods[SumColumn] - RowOfGoods.AmountIncludingVAT) * Object.RemunerationPercentage / 100;
			
		ElsIf Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.SaleShare Then
			RowOfGoods.CommissionAmount = RowOfGoods[SumColumn] * Object.RemunerationPercentage / 100;
			
		ElsIf Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.ArbitraryAmount
			And Not TotalSumColumn = 0 Then
			RowOfGoods.CommissionAmount = RowOfGoods[SumColumn] / TotalSumColumn * Object.CommissionAmount;
			MaxAmount = Max(MaxAmount, RowOfGoods[SumColumn]);

		Else
			RowOfGoods.CommissionAmount = 0;
			
		EndIf;
		
		If ThereIsSumOfNDSV Then
			CalculateAmountOfVATRemuneration(RowOfGoods, VATPercentage);
		EndIf;
		
	EndDo;
	
	If Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.ArbitraryAmount Then
		
		If ThereIsSumOfNDSV Then
			CalculateAmountOfVATRemuneration(Object, VATPercentage);
			TotalVATAmountOfRemuneration = Object.Goods.Total("AmountVATRemuneration");
		EndIf;
		
		TotalCommissionAmount = Object.Goods.Total("CommissionAmount");
		MaxRows = Object.Goods.FindRows(New Structure(SumColumn, MaxAmount));
		For Each RowOfGoods In MaxRows Do
			RowOfGoods.CommissionAmount =
				RowOfGoods.CommissionAmount + (Object.CommissionAmount - TotalCommissionAmount);
			If ThereIsSumOfNDSV Then
				RowOfGoods.AmountVATRemuneration =
					RowOfGoods.AmountVATRemuneration + (Object.AmountVATRemuneration - TotalVATAmountOfRemuneration);
			EndIf;
			Break;
		EndDo;

		If Not TotalSumColumn = 0 Then
			Object.RemunerationPercentage = Object.CommissionAmount / TotalSumColumn * 100;
		Else
			Object.RemunerationPercentage = 0;
		EndIf;
	EndIf;

	Object.CommissionAmount = Object.Goods.Total("CommissionAmount");
	
	If ThereIsSumOfNDSV Then
		Object.AmountVATRemuneration = Object.Goods.Total("AmountVATRemuneration");
	Else
		CalculateAmountOfVATRemuneration(Object, VATPercentage);
	EndIf;
	
EndProcedure

// The procedure fills in the VAT rate for the Commission fee.
//
// Parameters:
//	Object - FormDataStructure - Current document
//	VATPercentage - Number - VAT percentage.
//  ThereIsSumOfNDSV - Boolean - indicates that the VAT amount of remuneration is calculated line-by-line.
//
Procedure FillInLBRateOfJointCommissionRemuneration(Object, VATPercentage = 0, ThereIsSumOfNDSV = False) Export
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Object.Organization, Object.Date);
	
	VATTaxation = AccountingParametersForOrganization.BasicTaxationVATSales;
		
	If VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
		Object.VATRateOfRemuneration = VATAccountingERP.VATRateForProductsAndTaxation(
				Object.OperationService, Object.VATTaxation, Object.Organization, Object.Date);
	Else
		Object.VATRateOfRemuneration = Catalogs.VATRates.EXCLUDINGVAT;
	EndIf;
	VATPercentage = VATAccountingERPClientServer.ValueOfVATRate(Object.VATRateOfRemuneration);
	
	If ThereIsSumOfNDSV Then
		CalculateAmountOfVATRemunerationInLines(Object, VATPercentage);
	Else
		CalculateAmountOfVATRemuneration(Object, VATPercentage);
	EndIf;
	
EndProcedure

// The procedure fills in the VAT amount of the Commission fee in the table part of the document.
//
// Parameters:
//  Goods - TabularSection - the table to fill in.
//  AmountVATRemuneration - Number - the amount of VAT remuneration.
//
Procedure FillInAmountOfVATRemunerationInTablePart(Goods, Val AmountVATRemuneration) Export
	
	TotalAmountOfRemuneration = Goods.Total("CommissionAmount");
	
	For Each TableRow In Goods Do
		
		TableRow.AmountVATRemuneration = ?(TotalAmountOfRemuneration <> 0, Round(AmountVATRemuneration * TableRow.CommissionAmount / TotalAmountOfRemuneration, 2, 1), 0);
		
		TotalAmountOfRemuneration = TotalAmountOfRemuneration - TableRow.CommissionAmount;
		AmountVATRemuneration = AmountVATRemuneration - TableRow.AmountVATRemuneration;
			
	EndDo;
	
EndProcedure

// The function returns the type of price from the sales commission agreement
//
// Parameters:
//  Contract     - CatalogRef.CounterpartyContracts - contract with the commission agent
//  TypeOfPriceType - Boolean - "True" to get the accounting type of price, "False" to get the type of sale price
//
// Returns:
//   CatalogRef.TypesOfPrices - Referenceslink.Price type - the type of price specified in the contract
//
Function TypeOfContractPrice(Contract, TypeOfPriceType) Export
	
	PriceKind = Catalogs.TypesOfPrices.EmptyRef();
	FieldPriceType = ?(TypeOfPriceType, "PriceTypeAccountingPriceType", "SellingPriceType");
	
	If ValueIsFilled(Contract) And Common.ObjectAttributeValue(Contract, "ConsignmentSales25") Then
		PriceKind = Common.ObjectAttributeValue(Contract, FieldPriceType);
	EndIf;
	
	Return PriceKind;
	
EndFunction

//The function returns a sign of the availability of documents for the commission version 2.0
//
// Returns:
//  Boolean - indicates the availability of documents for the old commission
Function ConsignmentSaleIsUsed20() Export
	
	Result = False;
	
	Query = New Query;
	Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.TransferToCommissionAgent);
	Query.SetParameter("SalesViaCommissionAgent", Enums.BusinessTransactions.SalesViaCommissionAgent);
	
	Query.Text =
	"SELECT TOP 1
	|	CustomerInvoice.Ref
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.BusinessOperation = &BusinessOperation
	|	AND CustomerInvoice.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	ConsignmentReportFromCustomer.Ref
	|FROM
	|	Document.ConsignmentReportFromCustomer AS ConsignmentReportFromCustomer
	|WHERE
	|	NOT ConsignmentReportFromCustomer.BusinessOperation = &SalesViaCommissionAgent
	|	AND ConsignmentReportFromCustomer.Posted";
	
	Selection = Query.Execute().Select();
	Result = Selection.Next();
	
	Return Result;
	
EndFunction

#Region SalesViaCommissionAgent

// Searches for a valid contract with the end customer using the specified details.
// If one valid contract is found, it returns a link to it, otherwise it returns an empty link.
//
// Parameters:
//   Object                  - DocumentObject - The object from which the main parameters for the search will be taken.
//   BusinessTransactions   - EnumRef.BusinessTransactions, Array of EnumRef.BusinessTransactions - One or more business
//                             transactions (contract type).
// 
// Returns:
//   CatalogRef.CounterpartyContracts  - the default counterparty agreement.
//
Function GetDefaultContract(
			Object,
			BusinessTransactions) Export
	
	If Not GetFunctionalOption("UseCustomerContracts") Then
		Return Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	PartnerList = New ValueList;
	PartnersAndCounterparties.FillInListOfPartnersWithParents(Object.CustomerPartner, PartnerList);
	
	Query = New Query("
	|SELECT
	|	CounterpartyContracts.Ref
	|
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|
	|WHERE
	|	(NOT CounterpartyContracts.DeletionMark)
	|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND CounterpartyContracts.Partner IN (&PartnerList)
	|	AND CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Organization = &Organization
	|	AND CounterpartyContracts.ContractWithCommissionAgent = &ContractWithCommissionAgent
	|	AND ((NOT &FilterBusinessOperation)
	|			OR CounterpartyContracts.BusinessOperation IN (&BusinessOperation))
	|	AND CounterpartyContracts.Ref = &CurContract;
	|
	|SELECT ALLOWED TOP 2
	|	CounterpartyContracts.Ref
	|
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|
	|WHERE
	|	(NOT CounterpartyContracts.DeletionMark)
	|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND CounterpartyContracts.Partner IN (&PartnerList)
	|	AND CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Organization = &Organization
	|	AND CounterpartyContracts.ContractWithCommissionAgent = &ContractWithCommissionAgent
	|	AND ((NOT &FilterBusinessOperation)
	|			OR CounterpartyContracts.BusinessOperation IN (&BusinessOperation))
	|");
	Query.SetParameter("CurContract", Object.CustomerContract);
	Query.SetParameter("PartnerList", PartnerList);
	Query.SetParameter("Counterparty", Object.CustomerCounterparty);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("ContractWithCommissionAgent", Object.Contract);
	Query.SetParameter("FilterBusinessOperation", ValueIsFilled(BusinessTransactions));
	Query.SetParameter("BusinessOperation", BusinessTransactions);
	
	ResultsArray = Query.ExecuteBatch();
	
	If Not ResultsArray[0].IsEmpty() Then
		
		Selection = ResultsArray[0].Select();
		Selection.Next();
		
		DefaultContract = Selection.Ref;
		
	Else
		Selection = ResultsArray[1].Select();
	
		If Not Selection.Next() Then
			DefaultContract = Catalogs.CounterpartyContracts.EmptyRef();
		ElsIf Selection.Count() = 1 Then
			DefaultContract = Selection.Ref;
		Else
			DefaultContract = Catalogs.CounterpartyContracts.EmptyRef();
		EndIf;
	EndIf;
	
	Return DefaultContract;
	
EndFunction

// Searches for a valid contract with a commission agent using the specified details.
// If one valid contract is found, it returns a link to it, otherwise it returns an empty link.
//
// Parameters:
//   Object - CatalogObject.CounterpartyContracts - The object from which the main parameters for the search will be taken.
//
// Returns:
//   CatalogRef.CounterpartyContracts  - the default counterparty agreement.
//
Function GetContractWithCommissionAgentByDefault(Object) Export
	
	If Not GetFunctionalOption("UseCustomerContracts") Then
		Return Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	PartnerList = New ValueList;
	PartnersAndCounterparties.FillInListOfPartnersWithParents(Object.CommissionAgentPartner, PartnerList);
	
	Query = New Query("
	|SELECT
	|	CounterpartyContracts.Ref
	|
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|
	|WHERE
	|	(NOT CounterpartyContracts.DeletionMark)
	|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND CounterpartyContracts.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|	AND CounterpartyContracts.ConsignmentSales25 = &ConsignmentSales25
	|	AND CounterpartyContracts.Partner IN (&PartnerList)
	|	AND CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Organization = &Organization
	|	AND CounterpartyContracts.Ref = &CurContract;
	|
	|SELECT ALLOWED TOP 2
	|	CounterpartyContracts.Ref
	|
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|
	|WHERE
	|	(NOT CounterpartyContracts.DeletionMark)
	|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND CounterpartyContracts.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|	AND CounterpartyContracts.ConsignmentSales25 = &ConsignmentSales25
	|	AND CounterpartyContracts.Partner IN (&PartnerList)
	|	AND CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Organization = &Organization
	|");
	Query.SetParameter("CurContract", Object.ContractWithCommissionAgent);
	Query.SetParameter("PartnerList", PartnerList);
	Query.SetParameter("Counterparty", Object.CounterpartyCommissionAgent);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("ConsignmentSales25", SalesViaCommissionAgent(Object.BusinessOperation)
		Or Object.ConsignmentSales25);
	
	ResultsArray = Query.ExecuteBatch();
	
	If Not ResultsArray[0].IsEmpty() Then
		
		Selection = ResultsArray[0].Select();
		Selection.Next();
		
		DefaultContract = Selection.Ref;
		
	Else
		Selection = ResultsArray[1].Select();
	
		If Not Selection.Next() Then
			DefaultContract = Catalogs.CounterpartyContracts.EmptyRef();
		ElsIf Selection.Count() = 1 Then
			DefaultContract = Selection.Ref;
		Else
			DefaultContract = Catalogs.CounterpartyContracts.EmptyRef();
		EndIf;
	EndIf;
	
	Return DefaultContract;
	
EndFunction

//The function returns the commission version that the document can use
//
// Parameters:
//  Id - CatalogRef.MetadataObjectIDs - document ID
//
// Returns:
//  String - commission versions
//
Function PostfixCommissionSchemes(Id = "") Export

	Version = "11.0";
	Version = "2.0";
	ObjectMetadata = Common.MetadataObjectByID(Id, False);
	
	If ObjectMetadata = Metadata.Documents.ReceiptOfGoodsFromCustodian 
		Or ObjectMetadata = Metadata.Documents.TransferOfGoodsToBailee 
		Or ObjectMetadata = Metadata.Documents.DiscrepancyReportFollowingReceipt 
		Or ObjectMetadata = Metadata.Documents.DiscrepancyReportFollowingShipment Then
		Version = "11.5";
		Version = "2.5";
	EndIf;

	Return Version;

EndFunction

//The function returns a postfix representation for the commission scheme version 2.5/11.5
//
// Returns:
//  String - commission versions
//
Function PostfixCommissionSchemes25() Export
	
	Version = "11.5";
	Version = "2.5";
	Return Version;

EndFunction

//The function returns the name with the postfix of the commission scheme 2.5/11.5, if necessary
//
// Parameters:
//  Description - String - Description
//  
// Returns:
//  String - name with commission version
//
Function AddCommissionPostfix25(Description) Export
	
	Version = " (11.5)";
	Version = " (2.5)";
	If GetFunctionalOption("OnlyConsignmentSales25") Then
		Version = "";
	EndIf;
	
	Return Description + Version;

EndFunction

//The function returns a postfix representation for the commission scheme version 2.0/11.0
//
// Returns:
//  String - commission versions
//
Function PostfixCommissionSchemes20() Export
	
	Version = "11.0";
	Version = "2.0";
	Return Version;

EndFunction

// A hint when choosing the version of commission trading.
// 
// Returns:
//  String - A Hint When Choosing The Version Of Commission Trading
Function HintWhenChoosingVersionOfCommissionTrading() Export
	
	TemplateHint = NStr(
		"vi = '%2 – chỉ sử dụng mô hình ký gửi %2, chứng từ ký gửi %1 được dùng để xem/soạn;
		|%1/%2 – sử dụng hai mô hình. Có thể nhập các chứng từ/danh mục mới đối với mô hình %1 và %2.';
		|ru = '%2 – используется только модель комиссии %2, документы по комиссии %1 доступны для просмотра/редактирования;
		|%1/%2 – используются обе модели. Ввод новых документов/справочников возможен как для модели %1, так и для %2.';
		|en = '%2: only consignment sales model %2 is used, but you can read/edit documents of consignment sales %1.
		|%1/%2: both models are used. You can enter new documents/catalogs for both %1 and %2 models.'; fa = '%2: only consignment sales model %2 is used, but you can read/edit documents of consignment sales %1.
		|%1/%2: both models are used. You can enter new documents/catalogs for both %1 and %2 models.';
		|it = '%2: only consignment sales model %2 is used, but you can read/edit documents of consignment sales %1.
		|%1/%2: both models are used. You can enter new documents/catalogs for both %1 and %2 models.';
		|pl = '%2: only consignment sales model %2 is used, but you can read/edit documents of consignment sales %1.
		|%1/%2: both models are used. You can enter new documents/catalogs for both %1 and %2 models.';
		|tr = '%2 - Sadece %2 komisyon modeli kullanılır, %1 komisyon modeli için belgeler görüntüleme/düzenleme için kullanılabilir; 
		|%1/%2 - Her iki model de kullanılır. Hem %1 modeli, hem de %2 modeli için yeni belgeler/kataloglar girilebilir.'");
	
	ToolTip = StrTemplate(TemplateHint, PostfixCommissionSchemes20(), PostfixCommissionSchemes25());
		
	Return ToolTip;
	
EndFunction

// Comment about using an outdated version of commission trading.
// 
// Returns:
//  String - Warning about outdated functionality.
//
Function CommentUsingOutdatedCommission() Export
	
	TemplateHint = NStr("ru = 'Внимание! Функциональность ""Комиссионных продаж версии %1"" устарела и будет удалена в версии %2. Пожалуйста, перейдите на ""Комиссионные продажи версии %3"".';
						|vi = 'Important. The ""Consignment sales version %1"" functionality is deprecated and will be removed in version %2. Please migrate to ""Consignment sales version %3"".';
						|en = 'Important. The ""Consignment sales version %1"" functionality is deprecated and will be removed in version %2. Please migrate to ""Consignment sales version %3"".'; fa = 'Important. The ""Consignment sales version %1"" functionality is deprecated and will be removed in version %2. Please migrate to ""Consignment sales version %3"".';
						|it = 'Important. The ""Consignment sales version %1"" functionality is deprecated and will be removed in version %2. Please migrate to ""Consignment sales version %3"".';
						|pl = 'Important. The ""Consignment sales version %1"" functionality is deprecated and will be removed in version %2. Please migrate to ""Consignment sales version %3"".';
						|tr = 'Dikkat! ""%1 sürümü Konsinye Satışları"" işlevi eskidi ve %2 sürümünde silinecek. Lütfen ""Konsinye Satışları %3  sürümüne"" geçin.'");
	
	Postfix20 = PostfixCommissionSchemes20();
	Postfix25 = PostfixCommissionSchemes25();
	DeletionVersion = StrReplace(Postfix20, ".0", ".6.3");
	
	ToolTip = StrTemplate(TemplateHint, Postfix20, DeletionVersion, Postfix25);
		
	Return ToolTip;
	
EndFunction

// Determines whether the business transaction relates to sales operations under the commission trading scheme version 2.5.
// 
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions
// 
// Returns:
//  Boolean
//
Function SalesViaCommissionAgent(BusinessOperation) Export
	
	Return BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
	
EndFunction

// Determines whether a business transaction is a transfer transaction for a commission
// 
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions
// 
// Returns:
//  Boolean
//
Function TransferToCommissionAgent(BusinessOperation) Export
	
	Return BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent;
	
EndFunction

// Determines whether the business transaction relates to the return operations under the commission trading scheme version 2.5.
// 
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions
// 
// Returns:
//  Boolean
//
Function ReturnOfGoodsViaCommissionAgent(BusinessOperation) Export
	
	Return BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent;
	
EndFunction

// Returns the text for substitution in the request for selection conditions for economic operations of implementation 
// according to the commission trading scheme version 2.5.
// 
// Parameters:
//  TextOfRequestToRedefineBusinessTransaction - String
// 
// Returns:
//  String
//
Function QueryTextSalesViaCommissionAgent(TextOfRequestToRedefineBusinessTransaction) Export
	
	Return StrTemplate("(%1 = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
		|	OR %1 = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))", 
		TextOfRequestToRedefineBusinessTransaction);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure AddLineByProductToCommitteeSReportingForPeriod(TabularSection,
																	FillParameters,
																	RowData,
																	Count,
																	StructureOfActions,
																	CachedValues)
	
	NewRow = TabularSection.Add();
	FillPropertyValues(NewRow, RowData);
	
	NewRow.Count			= Count;
	NewRow.NumberOfPackages	= Count;
	
	If RowData.Count < Count Then
		NewRow.SalesAmount = RowData.SalesAmount / RowData.Count * Count;
	EndIf;
	
	NewRow.SellingPrice = ?(NewRow.Count <> 0, NewRow.SalesAmount / NewRow.Count, 0);
	
EndProcedure

Function AmountSalesVAT(SalesAmount, VATRate) Export
	
	AmountSalesVAT = PriceManagementSystemClientServer.CalculateVATAmount(SalesAmount, VATRate);
	Return Round(AmountSalesVAT, 2, RoundMode.Round15as20);
	
EndFunction

#EndRegion
