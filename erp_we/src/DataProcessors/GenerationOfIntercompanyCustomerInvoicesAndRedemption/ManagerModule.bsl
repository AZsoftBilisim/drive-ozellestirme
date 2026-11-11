#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Parameters:
// 	Parameters - Structure - Where:
// 		* Organization - CatalogRef.Companies
// 		* Period - StandardPeriod
// 		* InventoryType - EnumRef.InventoryTypes
// 		* SelectedSenders - ValueTable
// 		* SenderSelectionOption - String
// 		* MakeTransfers - Boolean
// 		* IssueRansoms - Boolean
// 		* CreatedDocuments - Array
// 		* DocumentGenerationFrequency - String
// 		* CompositionSettings - DataCompositionSettings
// 		* TemplateName - String
// 		* ActionWithTransferPrices - String
// 	TempStorageAddress - UUID, String - 
//
Procedure CreateTransferDocuments(Parameters, TempStorageAddress) Export
	
	Var Result;
	
	CreatedDocuments = Parameters.CreatedDocuments;
	
	CurrentDay = Parameters.Period.StartDate;
	If Parameters.MakeTransfers Then
		ActionWithTransferPrices = Parameters.ActionWithTransferPrices;
	Else
		ActionWithTransferPrices = "DontCheck";
	EndIf;
	
	RequestParametersForNegativeBalances = RequestParametersForNegativeBalances(Parameters);
	                           
	TableOfProductsWithNegativeResidues = DataCompositionServer.UploadDCSResults(RequestParametersForNegativeBalances);
	TableOfProductsWithNegativeResidues.Indexes.Add("ItemsLocationAttributes, CCDNumber, Period");	
	
	QueryText =
	"SELECT DISTINCT
	|	TableOfProductsWithNegativeResidues.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfProductsWithNegativeResidues.VATTaxationOfInventoryKind AS VATTaxationOfInventoryKind,
	|	TableOfProductsWithNegativeResidues.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfProductsWithNegativeResidues.InventoryType AS InventoryType,
	|	TableOfProductsWithNegativeResidues.GoodsInventoryKindOwner AS GoodsInventoryKindOwner,
	|	TableOfProductsWithNegativeResidues.Products AS Products,
	|	TableOfProductsWithNegativeResidues.VATRate AS VATRate,
	|	TableOfProductsWithNegativeResidues.ItemsType AS ItemsType,
	|	TableOfProductsWithNegativeResidues.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TableOfProductsWithNegativeResidues.Characteristic AS Characteristic,
	|	TableOfProductsWithNegativeResidues.Series AS Series,
	|	TableOfProductsWithNegativeResidues.StorageLocation AS StorageLocation,
	|	TableOfProductsWithNegativeResidues.StorageLocationWarehouse AS StorageLocationWarehouse,
	|	TableOfProductsWithNegativeResidues.StorageLocationContract AS StorageLocationContract,
	|	TableOfProductsWithNegativeResidues.StorageLocationCounterparty AS StorageLocationCounterparty,
	|	TableOfProductsWithNegativeResidues.StorageLocationPartner AS StorageLocationPartner,
	|	TableOfProductsWithNegativeResidues.StorageLocationDepartment AS StorageLocationDepartment,
	|	TableOfProductsWithNegativeResidues.StorageType AS StorageType,
	|	TableOfProductsWithNegativeResidues.Purpose AS Purpose,
	|	TableOfProductsWithNegativeResidues.CCDNumber AS CCDNumber,
	|	TableOfProductsWithNegativeResidues.QuantityToTransfer AS QuantityToTransfer,
	|	TableOfProductsWithNegativeResidues.Period AS Period
	|INTO NameTTNegativeResiduals
	|FROM
	|	&TableOfProductsWithNegativeResidues AS TableOfProductsWithNegativeResidues
	|
	|INDEX BY
	|	Period,
	|	InventoryType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTNegativeBalances.Period AS Period
	|INTO TableOfPeriodsForQuery
	|FROM
	|	NameTTNegativeResiduals AS TTNegativeBalances
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfPeriodsForQuery.Period AS Period
	|FROM
	|	TableOfPeriodsForQuery AS TableOfPeriodsForQuery
	|
	|ORDER BY
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT &TTTextSendersForRequest;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CASE
	|		WHEN VALUETYPE(SelectedSenders.Sender) = TYPE(Catalog.Companies)
	|			THEN SelectedSenders.Sender
	|		ELSE &Organization
	|	END AS Organization,
	|	CASE
	|		WHEN VALUETYPE(SelectedSenders.Sender) = TYPE(Catalog.Partners)
	|			THEN SelectedSenders.Sender
	|		ELSE VALUE(Catalog.Partners.EmptyRef)
	|	END AS Depositor,
	|	SelectedSenders.PricesKind AS PricesKind,
	|	SelectedSenders.InventoryType AS InventoryType,
	|	SelectedSenders.Contract AS Contract,
	|	SelectedSenders.BusinessOperation AS BusinessOperation,
	|	SelectedSenders.Priority AS Priority
	|INTO TTSenders
	|FROM
	|	TTSendersForRequest AS SelectedSenders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTSendersForRequest
	|";
	
	If Parameters.ActionWithTransferPrices <> "DontCheck" Then
		QueryText = QueryText + Common.QueryBatchSeparator();
		QueryText = QueryText + 
		"SELECT DISTINCT
		|	TTNegativeBalances.Products AS Products,
		|	TTNegativeBalances.Characteristic AS Characteristic,
		|	TTNegativeBalances.ItemsType AS ItemsType,
		|	TTSenders.PricesKind
		|INTO #TTPriceSelections
		|FROM
		|	NameTTNegativeResiduals AS TTNegativeBalances
		|		INNER JOIN TTSenders AS TTSenders
		|		ON (VALUETYPE(TTSenders.PricesKind) = TYPE(Catalog.TypesOfPrices))
		|WHERE
		|	&MakeTransfers
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	PricesKind";
		
		ProductTableName_ = "TTPriceSelections";
		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(Parameters.Period.StartDate);
		If UsePriceManagementSystem25 Then
	
			ProductTableName_ = "TTPriceSelectionsPreliminary";
			
			Settings = PriceManagementSystemClientServer.SettingsForTemporaryTableWithAdditionForPricing();
			
			Settings.SourceOfGoods = ProductTableName_;
			Settings.ReceiverOfGoods = "TTPriceSelections";
			Settings.ListOfOtherFields = "ItemsType, PricesKind";
			Settings.FieldSeries = "";
			Settings.PackagingField = "";
			
			TextOfRequestForAdditionalPrices = PriceManagementSystemClientServer.TextOfTemporaryTableRequestWithAddendumForPricing(
													Settings,
													UsePriceManagementSystem25);
			QueryText = QueryText + 
			"
			|;
			|";
			QueryText = QueryText + TextOfRequestForAdditionalPrices;
			
		EndIf;
		
	EndIf;
	
	If ActionWithTransferPrices = "ExcludeProductsWithoutPrices" Then
		QueryText = QueryText + Common.QueryBatchSeparator();
	
		QueryText = QueryText + 
		"SELECT DISTINCT
		|	TTPriceSelections.Products AS Products,
		|	TTPriceSelections.Characteristic AS Characteristic
		|INTO UnsetPrices
		|FROM
		|	TTPriceSelections AS TTPriceSelections
		|		LEFT JOIN &ItemsPrices AS ItemPricesCrossSectionOfTheLatest
		|		ON &ItemPriceConnectionCondition
		|WHERE
		|	&MakeTransfers
		|	AND ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) = 0
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTNegativeBalancesForRequest.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	TTNegativeBalancesForRequest.VATTaxationOfInventoryKind AS VATTaxationOfInventoryKind,
		|	TTNegativeBalancesForRequest.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	TTNegativeBalancesForRequest.InventoryType AS InventoryType,
		|	TTNegativeBalancesForRequest.GoodsInventoryKindOwner AS GoodsInventoryKindOwner,
		|	TTNegativeBalancesForRequest.Products AS Products,
		|	TTNegativeBalancesForRequest.VATRate AS VATRate,
		|	TTNegativeBalancesForRequest.ItemsType AS ItemsType,
		|	TTNegativeBalancesForRequest.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	TTNegativeBalancesForRequest.Characteristic AS Characteristic,
		|	TTNegativeBalancesForRequest.Series AS Series,
		|	TTNegativeBalancesForRequest.Purpose AS Purpose,
		|	TTNegativeBalancesForRequest.StorageLocation AS StorageLocation,
		|	TTNegativeBalancesForRequest.StorageLocationWarehouse AS StorageLocationWarehouse,
		|	TTNegativeBalancesForRequest.StorageLocationContract AS StorageLocationContract,
		|	TTNegativeBalancesForRequest.StorageLocationCounterparty AS StorageLocationCounterparty,
		|	TTNegativeBalancesForRequest.StorageLocationPartner AS StorageLocationPartner,
		|	TTNegativeBalancesForRequest.StorageLocationDepartment AS StorageLocationDepartment,
		|	TTNegativeBalancesForRequest.StorageType AS StorageType,
		|	TTNegativeBalancesForRequest.CCDNumber AS CCDNumber,
		|	TTNegativeBalancesForRequest.QuantityToTransfer AS QuantityToTransfer,
		|	TTNegativeBalancesForRequest.Period AS Period
		|INTO TTNegativeBalances
		|FROM
		|	TTNegativeBalancesForRequest AS TTNegativeBalancesForRequest
		|		LEFT JOIN UnsetPrices AS UnsetPrices
		|		ON TTNegativeBalancesForRequest.Products = UnsetPrices.Products
		|			AND TTNegativeBalancesForRequest.Characteristic = UnsetPrices.Characteristic
		|WHERE
		|	UnsetPrices.Products IS NULL
		|	OR TTNegativeBalancesForRequest.ItemsType <> VALUE(Enum.ItemsTypes.OwnGoods)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTNegativeBalancesForRequest
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTPriceSelections";
	ElsIf ActionWithTransferPrices = "Validate" Then
		QueryText = QueryText + Common.QueryBatchSeparator();
		QueryText = QueryText +
		"SELECT
		|	TTPriceSelections.Products AS Products,
		|	TTPriceSelections.Characteristic AS Characteristic,
		|	TTPriceSelections.PricesKind AS PriceKind
		|FROM
		|	TTPriceSelections AS TTPriceSelections
		|		LEFT JOIN &ItemsPrices AS ItemPricesCrossSectionOfTheLatest
		|		ON &ItemPriceConnectionCondition
		|WHERE
		|	&MakeTransfers
		|	AND (ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) = 0
		|		AND TTPriceSelections.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods))
		|
		|ORDER BY
		|	TTPriceSelections.Products.Description,
		|	TTPriceSelections.Characteristic.Description
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTPriceSelections";
	EndIf;
	
	If Parameters.ActionWithTransferPrices <> "DontCheck" Then
		
		QueryText = StrReplace(QueryText, "#TTPriceSelections", ProductTableName_);
		
		QueryText = StrReplace(QueryText,
			"&ItemsPrices",
			PriceManagementSystemClientServer.QueryTextInformationRegisterItemsPrices("TTPriceSelections",
				"&BeginOfPeriod",
				New Structure("InTable", "PricesKind"),
				UsePriceManagementSystem25));
				
		QueryText = StrReplace(QueryText,
			"&ItemPriceConnectionCondition",
			PriceManagementSystemClientServer.RequestTextInformationRegisterItemPricesConnectionCondition(
			"TTPriceSelections",
			"ItemPricesCrossSectionOfTheLatest",
			"TTPriceSelections.PricesKind",
			UsePriceManagementSystem25));
		
	EndIf;

	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("MakeTransfers", Parameters.MakeTransfers);
	Query.SetParameter("IssueRansoms", Parameters.IssueRansoms);
	Query.SetParameter("InventoryType", Parameters.InventoryType);
	
	If Parameters.SenderSelectionOption = "AccordingToSpecifiedPriorities" Then
		TTTextSendersForRequest =
		"SELECT
		|	SelectedSenders.Sender AS Sender,
		|	SelectedSenders.PricesKind AS PricesKind,
		|	SelectedSenders.Contract AS Contract,
		|	SelectedSenders.BusinessOperation AS BusinessOperation,
		|	SelectedSenders.InventoryType AS InventoryType,
		|	SelectedSenders.LineNumber AS Priority
		|INTO TTSendersForRequest
		|FROM
		|	&SelectedSenders AS SelectedSenders";
	Else
		Query.SetParameter("GeneratedDocuments_", Parameters.GeneratedDocuments_);
		TTTextSendersForRequest = QueryTextSendersByTransferSettings(Query, "TTSendersForRequest");
	EndIf;
	QueryText = StrReplace(QueryText, "SELECT &TTTextSendersForRequest;", TTTextSendersForRequest + Common.QueryBatchSeparator());
	
	If ActionWithTransferPrices = "ExcludeProductsWithoutPrices" Then
		QueryText = StrReplace(QueryText, "NameTTNegativeResiduals", "TTNegativeBalancesForRequest");		
	Else
		QueryText = StrReplace(QueryText, "NameTTNegativeResiduals", "TTNegativeBalances");		
	EndIf;	
	
	Query.Text = QueryText;
	Query.SetParameter("SelectedSenders", Parameters.SelectedSenders);
	Query.SetParameter("TableOfProductsWithNegativeResidues", TableOfProductsWithNegativeResidues);
	Query.SetParameter("BeginOfPeriod", BegOfDay(Parameters.Period.StartDate));
	Query.SetParameter("EndOfPeriod", EndOfDay(Parameters.Period.EndDate));
	Query.SetParameter("Organization", Parameters.Organization);
	
	QueryResults   = Query.ExecuteBatch();
	
	If ActionWithTransferPrices = "Validate" Then
		UnsetPrices = QueryResults[QueryResults.UBound()-1].Unload();
		
		If UnsetPrices.Count() > 0 Then
			AddTableToResult(Result, "UnsetPrices", UnsetPrices); 
			PutToTempStorage(Result, TempStorageAddress);
			Return;
		EndIf;
	EndIf;
	
	SelectionOfPeriods = QueryResults[2].Select();
	
	While SelectionOfPeriods.Next() Do
		
		AllConducted = 
			CreateDocumentsByPeriod(SelectionOfPeriods.Period,
				TableOfProductsWithNegativeResidues,
				TempTablesManager,
				Parameters,
				CreatedDocuments); 
		If Not AllConducted Then
			Break;
		EndIf;
		
	EndDo;
	
	AddTableToResult(Result, "CreatedDocuments", TableOfCreatedDocuments(Parameters, CreatedDocuments)); 
	FillInListOfProblemOrganizations(Parameters,, Result, True);
	
	PutToTempStorage(Result, TempStorageAddress);
	
EndProcedure

Function TableOfCreatedDocuments(Parameters, CreatedDocuments) Export
	
	RequestTextsForInformationOnCreatedDocuments = New Array;
	
	If Parameters.MakeTransfers Then
		QueryText =	
		"SELECT
		|	CustomerInvoiceIntercompany.Ref                AS Ref,
		|	CustomerInvoiceIntercompany.Posted              AS Posted,
		|	CustomerInvoiceIntercompany.Number                 AS Number,
		|	CustomerInvoiceIntercompany.Date                  AS Date,
		|	CustomerInvoiceIntercompany.Warehouse                 AS Warehouse,
		|	CustomerInvoiceIntercompany.Warehouse.Presentation   AS WarehousePresentation,
		|	CustomerInvoiceIntercompany.Organization           AS Sender,
		|	CustomerInvoiceIntercompany.Organization.Presentation AS SenderPresentation,
		|	CustomerInvoiceIntercompany.BusinessOperation AS BusinessOperation,
		|	CASE
		|		WHEN CustomerInvoiceIntercompany.Posted
		|			THEN 0
		|		WHEN CustomerInvoiceIntercompany.DeletionMark
		|			THEN 1
		|		ELSE 2
		|	END AS PictureIndex
		|FROM
		|	Document.CustomerInvoiceIntercompany AS CustomerInvoiceIntercompany
		|WHERE
		|	CustomerInvoiceIntercompany.Ref IN(&CreatedDocuments)";
		
		RequestTextsForInformationOnCreatedDocuments.Add(QueryText);
	EndIf;
	
	If Parameters.IssueRansoms Then
		QueryText =	
		"SELECT DISTINCT
		|	RedemptionOfGoodsFromStorage.Ref     AS Ref,
		|	RedemptionOfGoodsFromStorage.Posted   AS Posted,
		|	RedemptionOfGoodsFromStorage.Number      AS Number,
		|	RedemptionOfGoodsFromStorage.Date       AS Date,
		|	CASE
		|		WHEN GoodsTable.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN GoodsTable.Warehouse
		|		WHEN GoodsTable.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN GoodsTable.Department
		|		WHEN GoodsTable.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN GoodsTable.Contract
		|		ELSE UNDEFINED
		|	END                                     AS Warehouse,
		|	CASE
		|		WHEN GoodsTable.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN GoodsTable.Warehouse.Presentation
		|		WHEN GoodsTable.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN GoodsTable.Department.Presentation
		|		WHEN GoodsTable.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN GoodsTable.Contract.Presentation
		|		ELSE UNDEFINED
		|	END                                     AS WarehousePresentation,
		|	RedemptionOfGoodsFromStorage.Partner    AS Sender,
		|	RedemptionOfGoodsFromStorage.Partner.Presentation AS SenderPresentation,
		|	RedemptionOfGoodsFromStorage.BusinessOperation AS BusinessOperation,
		|	CASE
		|		WHEN RedemptionOfGoodsFromStorage.Posted
		|			THEN 0
		|		WHEN RedemptionOfGoodsFromStorage.DeletionMark
		|			THEN 1
		|		ELSE 2
		|	END                                    AS PictureIndex
		|FROM
		|	Document.RedemptionOfGoodsFromStorage AS RedemptionOfGoodsFromStorage
		|		LEFT JOIN Document.RedemptionOfGoodsFromStorage.Goods AS GoodsTable
		|		ON RedemptionOfGoodsFromStorage.Ref = GoodsTable.Ref
		|WHERE
		|	RedemptionOfGoodsFromStorage.Ref IN(&CreatedDocuments)";
		
		RequestTextsForInformationOnCreatedDocuments.Add(QueryText);
	EndIf;	
	
	QueryText = StrConcat(RequestTextsForInformationOnCreatedDocuments, TMCommonUse.QuerySeparatorInJoin());
	QueryText = QueryText + "
	|
	|ORDER BY
	|	DATE,
	|	WarehousePresentation,
	|	SenderPresentation";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("CreatedDocuments", CreatedDocuments);

	Return Query.Execute().Unload();
	
EndFunction

Function CreateDocumentsByPeriod(CurrentPeriod, TableOfProductsWithNegativeResidues, TempTablesManager, CreationParameters, CreatedDocuments)
	
	EndOfFormationPeriod = EndOfMonth(CreationParameters.Period.EndDate);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Recipient", CreationParameters.Organization);
	Query.SetParameter("Organization", CreationParameters.Organization);
	Query.SetParameter("EconomicOperationsOfRedemption", EconomicOperationsOfRedemption());
	Query.SetParameter("MakeTransfers", CreationParameters.MakeTransfers);
	Query.SetParameter("IssueRansoms", CreationParameters.IssueRansoms);
	Query.SetParameter("InventoryType", CreationParameters.InventoryType);
	Query.SetParameter("FormByDay", CreationParameters.DocumentGenerationFrequency = "ByDays");
	Query.SetParameter("GeneratedDocuments_", CreationParameters.GeneratedDocuments_);
	If CreationParameters.DocumentGenerationFrequency = "ByMonths" Then
		Query.SetParameter("CurrentPeriod", EndOfMonth(CurrentPeriod));
		Query.SetParameter("CurPeriodBoundary", New Boundary(EndOfMonth(CurrentPeriod), BoundaryType.Including));	
	Else
		Query.SetParameter("CurrentPeriod", EndOfDay(CurrentPeriod));
		Query.SetParameter("CurPeriodBoundary", New Boundary(EndOfDay(CurrentPeriod), BoundaryType.Including));	
	EndIf;
	
	QueryText =
	"SELECT
	|	TTSenders.Organization AS Organization,
	|	InventoryKinds.Ref AS InventoryOwnerAttribute
	|INTO TTAvailableTypesOfInventoryForSaleBuyback
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|		INNER JOIN TTSenders AS TTSenders
	|		ON (TTSenders.Organization = InventoryKinds.Organization)
	|			AND InventoryKinds.InventoryType = TTSenders.InventoryType
	|			AND (CASE
	|				WHEN TTSenders.BusinessOperation IN (&EconomicOperationsOfRedemption)
	|					THEN InventoryKinds.GoodsOwner = TTSenders.Depositor
	|							AND InventoryKinds.Contract = TTSenders.Contract
	|				WHEN TTSenders.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|					THEN TRUE
	|				ELSE FALSE
	|			END)
	|		LEFT JOIN InformationRegister.ObsoleteInventoryOwnerAttributesWithBalance AS ObsoleteInventoryOwnerAttributesWithBalance
	|		ON InventoryKinds.Ref = ObsoleteInventoryOwnerAttributesWithBalance.InventoryOwnerAttribute
	|WHERE
	|	&InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|	AND (NOT InventoryKinds.Organization IN (&Recipient)
	|			OR CASE
	|					WHEN &GeneratedDocuments_ = ""OnlyRedemptionOfGoodsInStorage""
	|						THEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|					WHEN &GeneratedDocuments_ = ""OnlyRedemptionOfGiverSGoods""
	|						THEN InventoryKinds.InventoryType IN (
	|											VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|											VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|											VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|					WHEN TRUE
	|						THEN InventoryKinds.InventoryType IN (
	|											VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|											VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|											VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|											VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
	|				END)
	|	AND (NOT InventoryKinds.Obsolete1
	|				AND NOT InventoryKinds.IsDuplicate
	|			OR NOT ObsoleteInventoryOwnerAttributesWithBalance.InventoryOwnerAttribute IS NULL)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	TTNegativeBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.Ref AS InventoryOwnerAttribute,
	|	TTNegativeBalances.GoodsInventoryKindOwner AS Organization,
	|	TTNegativeBalances.CCDNumber AS CCDNumber
	|INTO TTSelectionsOfBusinessBalances
	|FROM
	|	TTNegativeBalances AS TTNegativeBalances
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TTNegativeBalances.GoodsInventoryKindOwner = InventoryKinds.Organization
	|			AND (CASE
	|				WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|					THEN InventoryKinds.VATTaxation = TTNegativeBalances.VATTaxationOfInventoryKind
	|				ELSE TRUE
	|			END)
	|			AND (InventoryKinds.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods), VALUE(Enum.InventoryTypes.ConsignedGoods)))
	|WHERE
	|	&InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND TTNegativeBalances.Period = &CurrentPeriod
	|	AND TTNegativeBalances.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|UNION ALL
	|
	|SELECT
	|	TTNegativeBalances.ItemsLocationAttributes,
	|	TTAvailableTypesOfInventoryForSaleBuyback.InventoryOwnerAttribute,
	|	TTAvailableTypesOfInventoryForSaleBuyback.Organization,
	|	TTNegativeBalances.CCDNumber
	|FROM
	|	TTNegativeBalances AS TTNegativeBalances
	|		INNER JOIN TTAvailableTypesOfInventoryForSaleBuyback AS TTAvailableTypesOfInventoryForSaleBuyback
	|		ON (TRUE)
	|WHERE
	|	TTNegativeBalances.Period = &CurrentPeriod
	|	AND TTNegativeBalances.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute,
	|	Organization,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT &TextTTReservesOfGoodsOfOrganizations;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CompanySafeStock.Period AS Period,
	|	CompanySafeStock.CorCompany AS Organization,
	|	CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanySafeStock.SenderSInventoryType AS InventoryOwnerAttribute,
	|	CompanySafeStock.CCDNumber AS CCDNumber,
	|	SUM(-CompanySafeStock.Count) AS Count,
	|	SUM(-CompanySafeStock.QuantityByGBRN) AS QuantityByGBRN
	|INTO DocumentRegisterRecords
	|FROM
	|	TTReservesOfGoodsOfOrganizations AS CompanySafeStock
	|
	|GROUP BY
	|	CompanySafeStock.Period,
	|	CompanySafeStock.ItemsLocationAttributes,
	|	CompanySafeStock.CCDNumber,
	|	CompanySafeStock.SenderSInventoryType,
	|	CompanySafeStock.CorCompany
	|
	|INDEX BY
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentRegisterRecords.Period			AS Period,
	|	DocumentRegisterRecords.Organization		AS Organization,
	|	DocumentRegisterRecords.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DocumentRegisterRecords.InventoryOwnerAttribute		AS InventoryOwnerAttribute,
	|	DocumentRegisterRecords.CCDNumber			AS CCDNumber,
	|	DocumentRegisterRecords.Count		AS Count,
	|	DocumentRegisterRecords.QuantityByGBRN	AS QuantityByGBRN
	|INTO RegisteredRecordsOfCancelledDocument
	|FROM
	|	&RegisteredRecordsOfCancelledDocument AS DocumentRegisterRecords
	|
	|INDEX BY
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT &TextTTBalancesByMonth;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GroupedBalances.Organization AS Organization,
	|	GroupedBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GroupedBalances.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GroupedBalances.CCDNumber AS CCDNumber,
	|	MIN(GroupedBalances.CountBalance) AS CountBalance
	|INTO GroupedBalances
	|FROM
	|	(SELECT
	|		DATETIME(1, 1, 1) AS Period,
	|		BalancesAtEndOfPeriod.Organization AS Organization,
	|		BalancesAtEndOfPeriod.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		BalancesAtEndOfPeriod.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		BalancesAtEndOfPeriod.CCDNumber AS CCDNumber,
	|		1 AS PeriodCounter,
	|		1 AS PeriodNumber,
	|		BalancesAtEndOfPeriod.CountBalance AS CountBalance,
	|		BalancesAtEndOfPeriod.QuantityByGBRNBalance AS QuantityByGBRNBalance
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(
	|				&CurPeriodBoundary,
	|				&FormByDay AND (Organization, ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber) IN
	|					(SELECT
	|						TTSelectionsOfBusinessBalances.Organization AS Organization,
	|						TTSelectionsOfBusinessBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
	|						TTSelectionsOfBusinessBalances.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|						TTSelectionsOfBusinessBalances.CCDNumber AS CCDNumber
	|					FROM
	|						TTSelectionsOfBusinessBalances AS TTSelectionsOfBusinessBalances)) AS BalancesAtEndOfPeriod
	|
	|	,&TextBalancesByMonthMerge
	|
	|	) AS GroupedBalances
	|
	|GROUP BY
	|	Period,
	|	PeriodNumber,
	|	Organization,
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute,
	|	CCDNumber
	|
	|HAVING
	|	(MIN(GroupedBalances.CountBalance) > 0
	|	AND SUM(GroupedBalances.PeriodCounter) >= &TotalPeriods - GroupedBalances.PeriodNumber + 1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(ISNULL(CompanySafeStock.Count, 0)) AS ReserveByRecipient,
	|	ISNULL(CompanySafeStock.Period, DATETIME(1, 1, 1)) = &EndOfMonthForCurPeriod AS ThisIsReserveInCurPeriod,
	|	ISNULL(DatesOfCompanyGoodsReceipt.DateOfReceipt, DATETIME(1, 1, 1)) AS DateOfLastReceipt,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = &Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.GoodsOwner
	|		ELSE GroupedBalances.InventoryOwnerAttribute.Organization
	|	END AS Sender,
	|	GroupedBalances.Organization AS OrganizationOfBalance,
	|	GroupedBalances.InventoryOwnerAttribute AS TypeOfStockBalance,
	|	GroupedBalances.InventoryOwnerAttribute.Organization AS Organization,
	|	GroupedBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.InventoryType
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END AS InventoryType,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.VATTaxation
	|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END AS VATTaxationOfInventoryKind,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.Contract
	|		ELSE UNDEFINED
	|	END AS InventoryTypeContract,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.PriceKind
	|		ELSE VALUE(Catalog.TypesOfPrices.EmptyRef)
	|	END AS TypeOfPriceTypeOfInventory,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.PriceKind.Currency
	|		ELSE VALUE(Catalog.Currencies.EmptyRef)
	|	END AS CurrencyPriceTypeInventoryType,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.Counterparty
	|		ELSE UNDEFINED
	|	END AS InventoryTypeCounterparty,
	|	GroupedBalances.CCDNumber AS CCDNumber,
	|	GroupedBalances.CountBalance AS CountBalance,
	|	TTRansomSenders.Priority AS PriorityOfRansomSender
	|INTO GroupedBalancesWithReserveCheck
	|FROM
	|	GroupedBalances AS GroupedBalances
	|		LEFT JOIN TTReservesOfGoodsOfOrganizations AS CompanySafeStock
	|		ON GroupedBalances.Organization = CompanySafeStock.CorCompany
	|			AND GroupedBalances.ItemsLocationAttributes = CompanySafeStock.ItemsLocationAttributes
	|			AND GroupedBalances.InventoryOwnerAttribute = CompanySafeStock.SenderSInventoryType
	|			AND GroupedBalances.CCDNumber = CompanySafeStock.CCDNumber
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfCompanyGoodsReceipt
	|		ON GroupedBalances.ItemsLocationAttributes.Products = DatesOfCompanyGoodsReceipt.Products
	|			AND GroupedBalances.ItemsLocationAttributes.Characteristic = DatesOfCompanyGoodsReceipt.Characteristic
	|			AND GroupedBalances.ItemsLocationAttributes.Series = DatesOfCompanyGoodsReceipt.Series
	|			AND GroupedBalances.ItemsLocationAttributes.Purpose = DatesOfCompanyGoodsReceipt.Purpose
	|			AND GroupedBalances.InventoryOwnerAttribute = DatesOfCompanyGoodsReceipt.InventoryOwnerAttribute
	|			AND GroupedBalances.CCDNumber = DatesOfCompanyGoodsReceipt.CCDNumber
	|		LEFT JOIN TTSenders AS TTRansomSenders
	|		ON (&ConsiderSenderPriority)
	|			AND GroupedBalances.Organization = TTRansomSenders.Organization
	|			AND (TTRansomSenders.BusinessOperation IN (&EconomicOperationsOfRedemption))
	|			AND GroupedBalances.InventoryOwnerAttribute.GoodsOwner = TTRansomSenders.Depositor
	|			AND GroupedBalances.InventoryOwnerAttribute.Contract = TTRansomSenders.Contract
	|			AND GroupedBalances.InventoryOwnerAttribute.PriceKind = TTRansomSenders.PricesKind
	|
	|GROUP BY
	|	GroupedBalances.InventoryOwnerAttribute,
	|	CASE
	|		WHEN GroupedBalances.Organization = &Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.GoodsOwner
	|		ELSE GroupedBalances.Organization
	|	END,
	|	GroupedBalances.Organization,
	|	GroupedBalances.ItemsLocationAttributes,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = &Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END,
	|	GroupedBalances.InventoryOwnerAttribute.Organization,
	|	GroupedBalances.CCDNumber,
	|	GroupedBalances.CountBalance,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.InventoryType
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.VATTaxation
	|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.Contract
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.PriceKind
	|		ELSE VALUE(Catalog.TypesOfPrices.EmptyRef)
	|	END,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.PriceKind.Currency
	|		ELSE VALUE(Catalog.Currencies.EmptyRef)
	|	END,
	|	CASE
	|		WHEN GroupedBalances.InventoryOwnerAttribute.Organization = GroupedBalances.Organization
	|			THEN GroupedBalances.InventoryOwnerAttribute.Counterparty
	|		ELSE UNDEFINED
	|	END,
	|	TTRansomSenders.Priority,
	|	ISNULL(DatesOfCompanyGoodsReceipt.DateOfReceipt, DATETIME(1, 1, 1)),
	|	ISNULL(CompanySafeStock.Period, DATETIME(1, 1, 1)) = &EndOfMonthForCurPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GroupedBalances.Organization AS OrganizationOfBalance,
	|	GroupedBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GroupedBalances.InventoryOwnerAttribute AS TypeOfStockBalance,
	|	GroupedBalances.CCDNumber AS CCDNumber,
	|	GroupedBalances.CountBalance AS CountBalance
	|FROM
	|	GroupedBalances AS GroupedBalances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTNegativeBalances.Period AS Period,
	|	GroupedBalancesWithReserveCheck.Sender AS Sender,
	|	ISNULL(&Organization, VALUE(Catalog.Companies.EmptyRef)) AS Recipient,
	|	GroupedBalancesWithReserveCheck.InventoryTypeCounterparty AS Counterparty,
	|	TTNegativeBalances.StorageLocation AS StorageLocation,
	|	CASE
	|		WHEN TTNegativeBalances.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
	|		WHEN GroupedBalancesWithReserveCheck.Organization = &Organization
	|			THEN CASE
	|					WHEN TTNegativeBalances.StorageType IN(
	|							VALUE(Enum.StorageLocationTypes.Warehouse),
	|							VALUE(Enum.StorageLocationTypes.Department),
	|							VALUE(Enum.StorageLocationTypes.CounterpartyContract))
	|						THEN CASE
	|								WHEN TTNegativeBalances.InventoryType IN (
	|															VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|															VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|															VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|									THEN VALUE(Enum.BusinessTransactions.RedemptionOfProviderGoods)
	|								WHEN TRUE
	|									THEN VALUE(Enum.BusinessTransactions.RedemptionOfGoodsFromStorage)
	|							  END
	|					ELSE VALUE(Enum.BusinessTransactions.EmptyRef)
	|				END
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	END AS BusinessOperation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	CASE
	|		WHEN GroupedBalancesWithReserveCheck.Organization = &Organization
	|			THEN GroupedBalancesWithReserveCheck.InventoryTypeContract
	|		ELSE TTTransferSenders.Contract
	|	END AS Contract,
	|	CASE
	|		WHEN GroupedBalancesWithReserveCheck.Organization = &Organization
	|			THEN GroupedBalancesWithReserveCheck.TypeOfPriceTypeOfInventory
	|		ELSE TTTransferSenders.PricesKind
	|	END AS PriceKind,
	|	CASE
	|		WHEN GroupedBalancesWithReserveCheck.Organization = &Organization
	|			THEN GroupedBalancesWithReserveCheck.CurrencyPriceTypeInventoryType
	|		ELSE ISNULL(TypesOfTransferPrices.PriceCurrency, VALUE(Catalog.Currencies.EmptyRef))
	|	END AS Currency,
	|	CASE
	|		WHEN TTNegativeBalances.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN -1
	|		WHEN &ConsiderSenderPriority
	|			THEN ISNULL(GroupedBalancesWithReserveCheck.PriorityOfRansomSender, ISNULL(TTTransferSenders.Priority, 100000))
	|		WHEN GroupedBalancesWithReserveCheck.Organization = &Organization
	|			THEN 1
	|		ELSE 2
	|	END AS PriorityForBusinessOperations,
	|	GroupedBalancesWithReserveCheck.OrganizationOfBalance AS OrganizationOfBalance,
	|	GroupedBalancesWithReserveCheck.TypeOfStockBalance AS TypeOfStockBalance,
	|	GroupedBalancesWithReserveCheck.InventoryOwnerAttribute AS SenderSInventoryType,
	|	TTNegativeBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTNegativeBalances.StorageType AS StorageType,
	|	TTNegativeBalances.StorageLocationPartner AS StorageLocationPartner,
	|	TTNegativeBalances.StorageLocationWarehouse AS StorageLocationWarehouse,
	|	TTNegativeBalances.StorageLocationCounterparty AS StorageLocationCounterparty,
	|	TTNegativeBalances.StorageLocationContract AS StorageLocationContract,
	|	TTNegativeBalances.StorageLocationDepartment AS StorageLocationDepartment,
	|	TTNegativeBalances.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTNegativeBalances.Products AS Products,
	|	TTNegativeBalances.VATRate AS VATRate,
	|	TTNegativeBalances.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTNegativeBalances.Characteristic AS Characteristic,
	|	TTNegativeBalances.Series AS Series,
	|	TTNegativeBalances.Purpose AS Purpose,
	|	TTNegativeBalances.CCDNumber AS CCDNumber
	|FROM
	|	TTNegativeBalances AS TTNegativeBalances
	|		INNER JOIN GroupedBalancesWithReserveCheck AS GroupedBalancesWithReserveCheck
	|		ON TTNegativeBalances.ItemsLocationAttributes = GroupedBalancesWithReserveCheck.ItemsLocationAttributes
	|			AND TTNegativeBalances.CCDNumber = GroupedBalancesWithReserveCheck.CCDNumber
	|			AND (CASE
	|				WHEN TTNegativeBalances.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|					THEN TTNegativeBalances.GoodsInventoryKindOwner = GroupedBalancesWithReserveCheck.Organization
	|							AND CASE
	|								WHEN GroupedBalancesWithReserveCheck.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|									THEN TTNegativeBalances.VATTaxationOfInventoryKind = GroupedBalancesWithReserveCheck.VATTaxationOfInventoryKind
	|								ELSE TRUE
	|							END
	|				ELSE TRUE
	|			END)
	|		LEFT JOIN TTSenders AS TTTransferSenders
	|		ON (NOT TTTransferSenders.BusinessOperation IN (&EconomicOperationsOfRedemption))
	|			AND (GroupedBalancesWithReserveCheck.InventoryType = TTTransferSenders.InventoryType)
	|			AND (GroupedBalancesWithReserveCheck.Organization = TTTransferSenders.Organization)
	|		LEFT JOIN Catalog.TypesOfPrices AS TypesOfTransferPrices
	|		ON (TTTransferSenders.PricesKind = TypesOfTransferPrices.Ref)
	|WHERE
	|	TTNegativeBalances.Period = &CurrentPeriod
	|
	|ORDER BY
	|	PriorityForBusinessOperations,
	|	GroupedBalancesWithReserveCheck.ThisIsReserveInCurPeriod DESC,
	|	GroupedBalancesWithReserveCheck.ReserveByRecipient DESC,
	|	GroupedBalancesWithReserveCheck.DateOfLastReceipt,
	|	GroupedBalancesWithReserveCheck.CountBalance DESC,
	|	Period,
	|	Sender,
	|	Recipient,
	|	Counterparty,
	|	StorageLocation,
	|	BusinessOperation,
	|	VATTaxation,
	|	Contract,
	|	PriceKind,
	|	Currency";
	
	ParametersForAddingBalancesToRequestForEachMonth = InventoriesServer.ParametersForAddingBalancesToRequestForEachMonth();
	ParametersForAddingBalancesToRequestForEachMonth.ThereIsSelectionByCCDNumber = True;
	
	If SessionParameters.PostWithoutControlOfCompanyStockBalance 
		Or Not Constants.ControlCompanyStockBalance.Get() Then
		
		ParametersForAddingBalancesToRequestForEachMonth.EndOfControlPeriod = EndOfFormationPeriod;
		
	EndIf;
	
	NumberOfMonthsOfAnalysis = InventoriesServer.AddBalanceControlForEachMonthToRequest(Query,
																							QueryText,
																							ParametersForAddingBalancesToRequestForEachMonth,
																							CurrentPeriod);
	
	If Query.Parameters.FormByDay Then
		Query.SetParameter("TotalPeriods", NumberOfMonthsOfAnalysis + 1);
	Else
		Query.SetParameter("TotalPeriods", NumberOfMonthsOfAnalysis);
	EndIf;
	
	Query.SetParameter("BeginOfPeriod", BegOfMonth(CurrentPeriod));	
	Query.SetParameter("EndOfPeriod", EndOfMonth(InventoriesServer.DateOfLastMovement()));	
	Query.SetParameter("EndOfMonthForCurPeriod", EndOfMonth(CurrentPeriod));	
	TTReservesOfGoodsOfOrganizations = InventoriesServer.TextOfRequestForRegistrationOfReservesOfGoodsOrganizations(Query,"TTByProductRange","TTSelectionsOfBusinessBalances");
	TTReservesOfGoodsOfOrganizations = TTReservesOfGoodsOfOrganizations + Common.QueryBatchSeparator();
	QueryText = StrReplace(QueryText, "SELECT &TextTTReservesOfGoodsOfOrganizations;" ,TTReservesOfGoodsOfOrganizations);
	
	Query.SetParameter("ConsiderSenderPriority", CreationParameters.SenderSelectionOption <> "ByTransmissionSettings");
	Query.SetParameter("RegisteredRecordsOfCancelledDocument",
								AccumulationRegisters.CompanySafeStock.CreateRecordSet().UnloadColumns());
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.Text = QueryText;
	QueryResults = Query.ExecuteBatch(); 
	SamplingByNegativeResiduals = QueryResults[QueryResults.UBound()].Select();
	
	RemnantsOfOwners = QueryResults[QueryResults.UBound() - 1].Unload();
	IndexKeys = "OrganizationOfBalance,ItemsLocationAttributes,TypeOfStockBalance,CCDNumber";
	RemnantsOfOwners.Indexes.Add(IndexKeys);
	SelectionOfOwnersResidueSearch = New Structure(IndexKeys);	

	HeaderFields = InventoriesServer.FieldsInHeaderForRegistrationByOrganizationSProductReserves();	
	DocumentsBeingCreated = New ValueTable;
	
	For Each KeyValue In HeaderFields Do
		DocumentsBeingCreated.Columns.Add(KeyValue.Key);
	EndDo;
	
	DocumentsBeingCreated.Columns.Add("DocumentObject");
	
	SelectionOfNegativeResidueSearch = New Structure("ItemsLocationAttributes, CCDNumber, Period");
	
	DocumentObject        = Undefined;
	
	QueryAndTableTexts = New Array;
	QuerySchema = New QuerySchema();
	QuerySchema.SetQueryText(QueryText);
		
	For Each SchemaRequest In QuerySchema.QueryBatch Do
		If TypeOf(SchemaRequest) = Type("QuerySchemaSelectQuery")
			And ValueIsFilled(SchemaRequest.PlacementTable) Then
			QueryAndTableTexts.Add("DROP " + SchemaRequest.PlacementTable);
		EndIf;
	EndDo;

	DropQuery = New Query;
	DropQuery.TempTablesManager = TempTablesManager;
	DropQuery.Text = StrConcat(QueryAndTableTexts, Common.QueryBatchSeparator());
	DropQuery.Execute();
	
	DefaultInventoryViewStructure = New Structure("
		|FinancialAccountingGroup,
		|GoodsOwner,
		|Counterparty,
		|Terms,
		|Contract,
		|Currency,
		|VATTaxation,
		|TaxationOfOrganization,
		|InventoryType,
		|PriceKind
		|");
	
	DefaultInventoryViewStructure.InventoryType = Enums.InventoryTypes.OwnGoods;
	
	While SamplingByNegativeResiduals.Next() Do
		
		If Not TMCommonUseClientServer.StructuresAreEqual(HeaderFields, SamplingByNegativeResiduals) Then
			
			FillPropertyValues(HeaderFields, SamplingByNegativeResiduals);
			
			FoundRows = DocumentsBeingCreated.FindRows(HeaderFields);
			
			If FoundRows.Count() = 0 Then
			
				If SamplingByNegativeResiduals.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany
					Or SamplingByNegativeResiduals.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany Then
					DocumentObject = Documents.CustomerInvoiceIntercompany.CreateDocument();
					DocumentObject.Warehouse = HeaderFields.StorageLocationWarehouse;
					DetailsNameTypeOfInventoryOfRecipient = "RecipientInventoryOwnerAttribute";
					ThisIsTransfer = True;
				ElsIf EconomicOperationsOfRedemption().Find(SamplingByNegativeResiduals.BusinessOperation) <> Undefined Then
					DocumentObject = Documents.RedemptionOfGoodsFromStorage.CreateDocument();
					DetailsNameTypeOfInventoryOfRecipient = "RedeemedInventoryOwnerAttributes";
					ThisIsTransfer = False;
				Else
					ExceptionText = NStr("vi = 'Đối với giao dịch kinh doanh %BusinessOperation% không hỗ trợ tạo chứng từ.';
										|ru = 'По хозяйственной операции %BusinessOperation% оформление документов не поддерживается.';
										|en = 'Document registration is not supported for the %BusinessOperation% business transaction.'; fa = 'Document registration is not supported for the %BusinessOperation% business transaction.';
										|it = 'Per operazione commerciale %BusinessOperation% la regolarizzazione dei documenti non è supportata.';
										|pl = 'Według operacji gospodarczej %BusinessOperation% sporządzenie dokumentów nie jest obsługiwane.';
										|tr = 'Belge düzenleme işlemi %BusinessOperation% ticari işlem için desteklenmiyor.'");
					ExceptionText = StrReplace(ExceptionText, "%BusinessOperation%", SamplingByNegativeResiduals.BusinessOperation);
					Raise ExceptionText;
				EndIf;
				
				NewRow = DocumentsBeingCreated.Add();
				FillPropertyValues(NewRow, HeaderFields);
				NewRow.DocumentObject = DocumentObject;
				
			Else
				DocumentObject = FoundRows[0].DocumentObject;
			EndIf;
			
		EndIf;
		
		FillPropertyValues(SelectionOfNegativeResidueSearch, SamplingByNegativeResiduals);
		
		LineToTransmit = TableOfProductsWithNegativeResidues.FindRows(SelectionOfNegativeResidueSearch)[0];
		
		If LineToTransmit.QuantityToTransfer = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(SelectionOfOwnersResidueSearch, SamplingByNegativeResiduals);
		
		RemainderLine_ = RemnantsOfOwners.FindRows(SelectionOfOwnersResidueSearch)[0]; 
		
		If RemainderLine_.CountBalance <=0 Then
			Continue;
		EndIf;
		
		QuantityToTransfer = Min(LineToTransmit.QuantityToTransfer, RemainderLine_.CountBalance);
		
		RemainderLine_.CountBalance = RemainderLine_.CountBalance - QuantityToTransfer; 
		LineToTransmit.QuantityToTransfer = LineToTransmit.QuantityToTransfer - QuantityToTransfer;
		
		NewRow = DocumentObject.Goods.Add();
		
		If ThisIsTransfer Then
			FillPropertyValues(NewRow, SamplingByNegativeResiduals,,"CCDNumber");
		Else
			FillPropertyValues(NewRow, SamplingByNegativeResiduals);
			
			NewRow.Contract       = SamplingByNegativeResiduals.StorageLocationContract;
			NewRow.Custodian     = SamplingByNegativeResiduals.StorageLocationPartner;
			NewRow.Counterparty    = SamplingByNegativeResiduals.StorageLocationCounterparty;
			NewRow.Department = SamplingByNegativeResiduals.StorageLocationDepartment;
			NewRow.Warehouse         = SamplingByNegativeResiduals.StorageLocationWarehouse;
			
		EndIf;
		
		NewRow.Count         = QuantityToTransfer;
		NewRow.NumberOfPackages = QuantityToTransfer;
		
		NewRow = DocumentObject.InventoryKinds.Add();
		FillPropertyValues(NewRow, SamplingByNegativeResiduals);
		
		If Not ValueIsFilled(SamplingByNegativeResiduals.SenderSInventoryType) Then
			If SamplingByNegativeResiduals.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany Then
				DefaultInventoryViewStructure.FinancialAccountingGroup = SamplingByNegativeResiduals.FinancialAccountingGroup;
				InventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(
					CreationParameters.Organization,
					Enums.BusinessTransactions.GoodsSaleToAnotherCompany,
					DefaultInventoryViewStructure);
			Else
				ExceptionText = NStr("vi = 'Khi xác định nguồn chuyển hàng hóa, không thể xác định dạng vật tư. Hãy liên hệ với nhà phát triển.';
									|ru = 'При определении источников передачи товаров не удалось определить вид запасов. Обратитесь к разработчикам.';
									|en = 'Cannot determine inventory owner attributes when determining goods transfer sources. Contact developers.'; fa = 'Cannot determine inventory owner attributes when determining goods transfer sources. Contact developers.';
									|it = 'Nel determinare le fonti di trasferimento delle merci non è stato possibile determinare il tipo di giacenze. Contattare i progettatori.';
									|pl = 'Podczas określenia źródeł przekazania towarów nie udało się określić rodzaj pozycji. Zwróć się do programistów.';
									|tr = 'Ürün transfer kaynaklarını belirlerken stok türünü belirlemek mümkün olmadı. Geliştiricilerle iletişime geç.'");
				Raise ExceptionText;
			EndIf;
		Else
			NewRow.InventoryOwnerAttribute = SamplingByNegativeResiduals.SenderSInventoryType;
		EndIf;
		
		NewRow.Count           = QuantityToTransfer;
		NewRow.NumberOfPackages   = QuantityToTransfer;
		NewRow[DetailsNameTypeOfInventoryOfRecipient] = SamplingByNegativeResiduals.InventoryOwnerAttribute;
		
	EndDo;
	
	AllConducted = RecordDocuments(DocumentsBeingCreated, CreatedDocuments, EndOfFormationPeriod);
	
	Return AllConducted;
	
EndFunction

Function RecordDocuments(DocumentsBeingCreated, CreatedDocuments, EndOfFormationPeriod)
	
	AllConducted = True;
		
	HeaderFields = InventoriesServer.FieldsInHeaderForRegistrationByOrganizationSProductReserves();	
	For Each DocumentBeingCreated In DocumentsBeingCreated Do
		
		DocumentObject = DocumentBeingCreated.DocumentObject;
		
		If DocumentObject = Undefined Then
			Return AllConducted;
		EndIf;
		
		If DocumentObject.Goods.Count() = 0 Then
			Return AllConducted;
		EndIf;
		
		FillPropertyValues(HeaderFields, DocumentBeingCreated); 
		
		FillingData = New Structure;
		FillingData.Insert("HeaderFields", HeaderFields);
		
		DocumentObject.Fill(FillingData);
		
		If DocumentObject.CheckFilling() Then
			Try
				
				If SessionParameters.PostWithoutControlOfCompanyStockBalance 
					Or Not Constants.ControlCompanyStockBalance.Get() Then
					
					DocumentObject.AdditionalProperties.Insert("EndOfPeriodForCorrectingBalances", EndOfFormationPeriod);
					
				EndIf;
				
				DocumentObject.Write(DocumentWriteMode.Posting);
			Except
				// We do not write to the registration journal because the user will then manually conduct
				// the documents and see errors - the user needs to deal with them, not the administrator
				DocumentObject.Write(DocumentWriteMode.Write);
				AllConducted = False;	
			EndTry;
		Else
			DocumentObject.Write(DocumentWriteMode.Write);
			AllConducted = False;	
		EndIf;
		CreatedDocuments.Add(DocumentObject.Ref);
	EndDo;
	
	Return AllConducted;
	
EndFunction

Procedure FillInListOfProblemOrganizations(Parameters, TempStorageAddress = "", Result = Undefined, GetSettings_ = False) Export
	RequestParametersForNegativeBalances = RequestParametersForNegativeBalances(Parameters);
	
	If GetSettings_ Then
		RequestParametersForNegativeBalances.CompositionSettings = 
			LayoutSettingsByName(Parameters.CompositionSettings,
				"ProblematicOrganizations",
				Parameters.TemplateName,
				Parameters.Period,
				Parameters.DocumentGenerationFrequency,
				Undefined,
				Undefined);
	EndIf;
	
	ResultTable2 = DataCompositionServer.UploadDCSResults(RequestParametersForNegativeBalances);
	
	AddTableToResult(Result, "ProblematicOrganizations", ResultTable2); 
	
	If IsTempStorageURL(TempStorageAddress) Then
		PutToTempStorage(Result, TempStorageAddress);
	EndIf;
EndProcedure

Function RequestParametersForNegativeBalances(Parameters)
	RequestParametersForNegativeBalances = DataCompositionServer.ParametersUploadDCSResult();
	
	If Parameters.DocumentGenerationFrequency = "ByMonths" Then
		DataCompositionSchema = DataCompositionServer.LayoutDiagramByParameter(Parameters.TemplateName);
		
		QueryText = DataCompositionSchema.DataSets.FillingBySelection.Query;
		QueryText = StrReplace(QueryText, ", DAY)", ", MONTH)");
		QueryText = StrReplace(QueryText, "Day,", "Month,");
		DataCompositionSchema.DataSets.FillingBySelection.Query = QueryText;
		
		RequestParametersForNegativeBalances.CompositionSchema = DataCompositionSchema;
	Else	
		RequestParametersForNegativeBalances.CompositionSchema = Parameters.TemplateName;
	EndIf;	
	
	RequestParametersForNegativeBalances.CompositionSettings  = Parameters.CompositionSettings;
	
	RequestParametersForNegativeBalances.ExecuteInPrivilegedMode = False;
	
	TableOfColumnsDisabledByFO = New ValueTable;
	TableOfColumnsDisabledByFO.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfColumnsDisabledByFO.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	TableOfColumnsDisabledByFO.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	TableOfColumnsDisabledByFO.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	TableOfColumnsDisabledByFO.Columns.Add("CCDNumber", New TypeDescription("CatalogRef.CCDNumbers"));
	TableOfColumnsDisabledByFO.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	TableOfColumnsDisabledByFO.Columns.Add("FinancialAccountingGroup", New TypeDescription("CatalogRef.InventoryAccountingGroups"));
	TableOfColumnsDisabledByFO.Columns.Add("StorageLocationDepartment", New TypeDescription("CatalogRef.BusinessStructure"));
	
	RequestParametersForNegativeBalances.ExpectedColumns = TableOfColumnsDisabledByFO;	
	Return  RequestParametersForNegativeBalances;
EndFunction

Function QueryTextSendersByTransferSettings(Query, TTName = "") Export
	
	SampleTexts = New Array;
	
	If Query.Parameters.MakeTransfers Then
		QueryText = 
		"SELECT ALLOWED DISTINCT
		|	CustomizeCustomerInvoiceIntercompany.CompanyOwner AS Sender,
		|	CASE
		|		WHEN CustomizeCustomerInvoiceIntercompany.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.Sale)
		|			THEN VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
		|		ELSE VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
		|	END AS BusinessOperation,
		|	CustomizeCustomerInvoiceIntercompany.Contract AS Contract,
		|	CustomizeCustomerInvoiceIntercompany.PriceKind AS PricesKind,
		|	CustomizeCustomerInvoiceIntercompany.InventoryType AS InventoryType,
		|	1 AS Priority
		|,&TextNameTT
		|FROM
		|	InformationRegister.CustomizeCustomerInvoiceIntercompany AS CustomizeCustomerInvoiceIntercompany
		|WHERE
		|	CustomizeCustomerInvoiceIntercompany.CompanyCustomer = &Organization
		|	AND CASE
		|			WHEN &InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
		|				THEN CustomizeCustomerInvoiceIntercompany.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.Sale)
		|			WHEN &InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|				THEN CustomizeCustomerInvoiceIntercompany.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent)
		|			ELSE FALSE
		|		END";
		SampleTexts.Add(QueryText);
	EndIf;
	
	If Query.Parameters.IssueRansoms Then
		QueryText = 
		"SELECT DISTINCT &TextAllowed,
		|	NestedQuery.Owner AS Sender,
		|	CASE
		|		WHEN NestedQuery.InventoryType IN (
		|									VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
		|									VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|									VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
		|			THEN VALUE(Enum.BusinessTransactions.RedemptionOfProviderGoods)
		|		WHEN TRUE
		|			THEN VALUE(Enum.BusinessTransactions.RedemptionOfGoodsFromStorage)
		|	END AS BusinessOperation,
		|	NestedQuery.Contract AS Contract,
		|	NestedQuery.PriceKind AS PricesKind,
		|	NestedQuery.InventoryType AS InventoryType,
		|	0 AS Priority
		|,&TextNameTT
		|FROM
		|	(SELECT
		|		CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		CompanyGoodsBalance.CCDNumber AS CCDNumber,
		|		CompanyGoodsBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		CompanyGoodsBalance.InventoryOwnerAttribute.PriceKind AS PriceKind,
		|		CompanyGoodsBalance.InventoryOwnerAttribute.Contract AS Contract,
		|		CompanyGoodsBalance.InventoryOwnerAttribute.GoodsOwner AS Owner,
		|		CompanyGoodsBalance.InventoryOwnerAttribute.InventoryType AS InventoryType,
		|		Contract.ContractType AS ContractType
		|	FROM
		|		AccumulationRegister.CompanyGoods.Balance(
		|				,
		|				&InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
		|					AND Organization = &Organization
		|					AND CASE
		|						WHEN &GeneratedDocuments_ = ""OnlyRedemptionOfGoodsInStorage""
		|							THEN InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
		|						WHEN &GeneratedDocuments_ = ""OnlyRedemptionOfGiverSGoods""
		|							THEN InventoryOwnerAttribute.InventoryType IN (
		|												VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
		|												VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|												VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
		|						WHEN TRUE
		|							THEN InventoryOwnerAttribute.InventoryType IN (
		|									VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
		|									VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|									VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
		|									VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
		|					END) AS CompanyGoodsBalance
		|
		|		LEFT JOIN Catalog.CounterpartyContracts AS Contract
		|			ON Contract.Ref = CompanyGoodsBalance.InventoryOwnerAttribute.Contract
		|
		|	WHERE
		|		CompanyGoodsBalance.CountBalance > 0) AS NestedQuery
		|	
		|WHERE
		|	NestedQuery.ContractType IS NULL
		|	OR NOT NestedQuery.ContractType = VALUE(Enum.ContractTypes.CustomerInvoiceOutsourcedSale)";
		
		If Query.Parameters.MakeTransfers > 0 Then
			QueryText = StrReplace(QueryText, ",&TextNameTT", "");
			QueryText = StrReplace(QueryText, "&TextAllowed,", "");
		Else
			QueryText = StrReplace(QueryText, "&TextAllowed,", "ALLOWED");
		EndIf;
		
		SampleTexts.Add(QueryText);
		
	EndIf;
	
	QueryText = StrConcat(SampleTexts, TMCommonUse.QuerySeparatorInJoin());
	If IsBlankString(TTName) Then
		QueryText = StrReplace(QueryText, ",&TextNameTT", "");
	Else	
		QueryText = StrReplace(QueryText, ",&TextNameTT", "INTO " + TTName);
	EndIf;
		
	Return QueryText;
	
EndFunction

Procedure AddTableToResult(Result, TableName, Table)
	
	If Not ValueIsFilled(Result) Then
		Result = New ValueTable();
		Result.Columns.Add("TableName");
		Result.Columns.Add("Table");
	EndIf;
	
	NewRow = Result.Add();
	NewRow.Table = Table;
	NewRow.TableName = TableName;
	
EndProcedure

Function EconomicOperationsOfRedemption() Export
	
	Array = New Array;
	Array.Add(Enums.BusinessTransactions.RedemptionOfGoodsFromStorage);
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		Array.Add(Enums.BusinessTransactions.RedemptionOfProviderGoods);
	EndIf;
	Return Array;
	
EndFunction

Procedure MarkCreatedDocumentsForDeletion(Parameters, TempStorageAddress) Export
	
	Var Result;
	CreatedDocuments = Parameters.CreatedDocuments; 
	
	IndexOf = CreatedDocuments.Count();
	
	While IndexOf >0 Do
		IndexOf = IndexOf - 1;
		
		Try
			
			DocumentObject = CreatedDocuments[IndexOf].GetObject();
			If Not DocumentObject.DeletionMark Then 
				DocumentObject.SetDeletionMark(True);
			EndIf;
			
			CreatedDocuments.Delete(IndexOf);
			
		Except
			MessageText = NStr("vi = 'Không thể xử lý chứng từ: %Ref% do: %Cause%';
								|ru = 'Не удалось обработать документ: %Ref% по причине: %Cause%';
								|en = 'Cannot process the document: %Ref%. Reason: %Cause%'; fa = 'Cannot process the document: %Ref%. Reason: %Cause%';
								|it = 'Non è stato possibile elaborare il documento: %Ref% a causa di: %Cause%';
								|pl = 'Nie można przetworzyć dokumentu: %Ref% z powodu: %Cause%';
								|tr = '%Cause% nedeniyle %Ref% belgesi işlenemedi'");
			MessageText = StrReplace(MessageText, "%Ref%", DocumentObject.Ref);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			WriteLogEvent( NStr("vi = 'Tạo hàng loạt chứng từ';
								|ru = 'Пакетное формирование документов';
								|en = 'Package document generation'; fa = 'Package document generation';
								|it = 'Generazione dei documenti a pacchetti';
								|pl = 'Tworzenie pakietów dokumentów';
								|tr = 'Toplu belge oluşturma'", CommonClientServer.DefaultLanguageCode()),
				EventLogLevel.Error,
				DocumentObject.Metadata(),
				DocumentObject.Ref,
				MessageText);
		EndTry;
		
	EndDo;
	
	AddTableToResult(Result, "CreatedDocuments", TableOfCreatedDocuments(Parameters, CreatedDocuments)); 
	FillInListOfProblemOrganizations(Parameters,, Result);
	PutToTempStorage(Result, TempStorageAddress);

EndProcedure

Function LayoutSettingsByName(InitialSettings, SettingName, TemplateName, Period, DocumentGenerationFrequency, ByCompany, ByStockType) Export
	
	SettingsComposer = New DataCompositionSettingsComposer;
	
	CompositionSchema = TMCommonUse.TemplateByName(TemplateName);
	
	DataCompositionServer.InitializeSettingsComposer(SettingsComposer, CompositionSchema, SettingName);
	Settings = SettingsComposer.GetSettings();
	
	DataCompositionClientServer.CopyDataCompositionFilter(CompositionSchema, Settings, InitialSettings);
	
	If ValueIsFilled(ByCompany) Then
		DataCompositionClientServer.AddFilter(Settings, "Organization", ByCompany);
	Else
		DataCompositionClientServer.DeleteSelection(Settings.Filter, "Organization");
	EndIf;
	
	If ValueIsFilled(ByStockType) Then
		DataCompositionClientServer.AddFilter(Settings, "InventoryType", ByStockType);
	Else
		DataCompositionClientServer.DeleteSelection(Settings.Filter, "InventoryType");
	EndIf;
	
	SettingsComposer.LoadSettings(Settings);
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	Settings = SettingsComposer.GetSettings();
		
	If DocumentGenerationFrequency = "ByMonths" Then
		DataCompositionClientServer.SetParameter(Settings, "BeginOfPeriod", BegOfMonth(Period.StartDate));	
		DataCompositionClientServer.SetParameter(Settings, "EndOfPeriod", New Boundary(EndOfMonth(Period.EndDate), BoundaryType.Including));	
	Else	
		DataCompositionClientServer.SetParameter(Settings, "BeginOfPeriod", BegOfDay(Period.StartDate));	
		DataCompositionClientServer.SetParameter(Settings, "EndOfPeriod", New Boundary(EndOfDay(Period.EndDate), BoundaryType.Including));	
	EndIf;	
	
	Return Settings;
EndFunction

Procedure UpdateCreatedDocs(Parameters, TempStorageAddress) Export
	Var Result;
	
	AddTableToResult(Result, "CreatedDocuments", TableOfCreatedDocuments(Parameters, Parameters.CreatedDocuments)); 
	FillInListOfProblemOrganizations(Parameters,, Result, False);
	
	PutToTempStorage(Result, TempStorageAddress);
EndProcedure

Procedure FillInConsignors(Parameters, TempStorageAddress) Export
	
	Var Result;
	
	RequestParametersForNegativeBalances = RequestParametersForNegativeBalances(Parameters);
	TableOfCommittees = DataCompositionServer.UploadDCSResults(RequestParametersForNegativeBalances);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfCommittees.GoodsInventoryKindOwner AS Otpravitel
	|INTO TTCommittees
	|FROM
	|	&TableOfCommittees AS TableOfCommittees
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTCommittees.Otpravitel AS Sender,
	|	CustomizeCustomerInvoiceIntercompany.Contract AS Contract,
	|	CustomizeCustomerInvoiceIntercompany.PriceKind AS PricesKind,
	|	CustomizeCustomerInvoiceIntercompany.InventoryType AS InventoryType,
	|	VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany) AS BusinessOperation
	|FROM
	|	TTCommittees AS TTCommittees
	|		LEFT JOIN InformationRegister.CustomizeCustomerInvoiceIntercompany AS CustomizeCustomerInvoiceIntercompany
	|		ON TTCommittees.Otpravitel = CustomizeCustomerInvoiceIntercompany.CompanyOwner
	|			AND (CustomizeCustomerInvoiceIntercompany.CompanyCustomer = &Organization)
	|			AND (CustomizeCustomerInvoiceIntercompany.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent))";
	
	Query.SetParameter("TableOfCommittees", TableOfCommittees);
	Query.SetParameter("Organization", Parameters.Organization);
	
	AddTableToResult(Result, "SendersByFee", Query.Execute().Unload()); 
	
	PutToTempStorage(Result, TempStorageAddress);
	
EndProcedure

Procedure FillInSenders(Parameters, TempStorageAddress) Export
	
	Var Result;
	
	TableByTransferSettings = GetTableForTransmissionSettings(Parameters);
	
	AddTableToResult(Result, Parameters.TableName, TableByTransferSettings); 
	
	PutToTempStorage(Result, TempStorageAddress);
	
EndProcedure

// Parameters:
// 		QueryOptions - Structure:
// 			* Organization - CatalogRef.Companies
// 			* MakeTransfers - Boolean
// 			* IssueRansoms - Boolean
// 			* InventoryType - EnumRef.InventoryTypes
// 			* GeneratedDocuments_ - String
// 			
// Returns:
// 		ValueTable:
// 			* Sender - CatalogRef.Companies
// 			* Contract - CatalogRef.IntercompanyContracts
// 			* PricesKind - CatalogRef.TypesOfPrices
// 			* Priority - Number
// 			* BusinessOperation - EnumRef.BusinessTransactions
//
Function GetTableForTransmissionSettings(QueryOptions) Export
	
	Query = New Query;
	Query.SetParameter("Organization",       QueryOptions.Organization);
	Query.SetParameter("MakeTransfers", QueryOptions.MakeTransfers);
	Query.SetParameter("IssueRansoms",   QueryOptions.IssueRansoms);
	Query.SetParameter("InventoryType",        QueryOptions.InventoryType);
	Query.SetParameter("GeneratedDocuments_", QueryOptions.GeneratedDocuments_);
	Query.Text = QueryTextSendersByTransferSettings(Query);
	
	Return Query.Execute().Unload();
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not (AccessRight("Read", Metadata.AccumulationRegisters.CompanyGoods)
		 	And AccessRight("Use", Metadata.DataProcessors.GenerationOfIntercompanyCustomerInvoicesAndRedemption) 
				  And (GetFunctionalOption("UseCustomerInvoiceIntercompany")
					Or GetFunctionalOption("UseTollManufacturing2_5")
					Or GetFunctionalOption("UseCustodyDuringPurchase"))) Then
		Return Undefined;
	EndIf;
	
	If Not Parameters.Property("PurposeUseKey") Then
		PurposeUseKey = "";
	Else
		PurposeUseKey = Parameters.PurposeUseKey;
	EndIf;
	
	HyperlinkText = HeaderAndGeneratedDocumentsByUseDestinationKey(PurposeUseKey).Title;
	
	If Not ValueIsFilled(HyperlinkText) Then
		Return Undefined;
	EndIf;
	
	FormNameWorkplaceOrderToSupplier = "DataProcessor.GenerationOfIntercompanyCustomerInvoicesAndRedemption.Form.Main";
	Return New FormattedString(HyperlinkText,,,,
			FormNameWorkplaceOrderToSupplier);
	
EndFunction

Function HeaderAndGeneratedDocumentsByUseDestinationKey(PurposeUseKey) Export
	
	GeneratedDocuments_ = "";
	Title = "";
	
	If (GetFunctionalOption("UseCustodyDuringPurchase")
			Or GetFunctionalOption("UseTollManufacturing2_5")
			Or False)
		And GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		
		If Not ValueIsFilled(PurposeUseKey) Then
			GeneratedDocuments_ = "TransfersBetweenOrganizationsAndRepurchasesOfGoodsInStorage";
		ElsIf PurposeUseKey = "IntercampanyDocumets"	
			Or PurposeUseKey = "CustomerInvoiceIntercompany" Then	
			GeneratedDocuments_ = "OnlyTransfersBetweenOrganizations";
		ElsIf PurposeUseKey = "PurchaseDocumentsAll" 	
			Or PurposeUseKey = "RedemptionOfGoodsFromStorage" Then	
			GeneratedDocuments_ = "OnlyRedemptionOfGoodsInStorage";
		ElsIf PurposeUseKey =
						TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing() Then
			GeneratedDocuments_ = "OnlyRedemptionOfGiverSGoods";
		ElsIf PurposeUseKey = "MonthEndTransactions" Then
			GeneratedDocuments_ = "OnlyRedemptionOfGoods";
		EndIf;
		
		Title = NStr("vi = 'Trợ giúp tạo chuyển và mua lại';
					|ru = 'Помощник формирования передач и выкупов';
					|en = 'Intercompany documents generation wizard'; fa = 'دستیار ایجاد اسناد درون‌گروهی';
					|it = 'Assistente generazione dei trasferimenti e riscatti';
					|pl = 'Asystent utworzenia przekazań i wykupów';
					|tr = 'Transferlerin ve itfaların oluşturulma sihirbazı'");
		
	ElsIf GetFunctionalOption("UseCustomerInvoiceIntercompany")  Then
		
		If Not ValueIsFilled(PurposeUseKey)
			Or PurposeUseKey = "IntercampanyDocumets"
			Or PurposeUseKey = "CustomerInvoiceIntercompany" Then	
			
			GeneratedDocuments_ = "OnlyTransfersBetweenOrganizations";
			Title = NStr("vi = 'Trợ giúp cho việc tạo chuyển nhượng';
						|ru = 'Помощник формирования передач';
						|en = 'Transfer generation wizard'; fa = 'Transfer generation wizard';
						|it = 'Assistente di generazione trasferimenti';
						|pl = 'Asystent utworzenia przekazań';
						|tr = 'Transfer oluşturma sihirbazı'");
		
		EndIf;
		
	ElsIf GetFunctionalOption("UseCustodyDuringPurchase")
		  Or GetFunctionalOption("UseTollManufacturing2_5")
		Then
		
		If Not ValueIsFilled(PurposeUseKey)
			Or PurposeUseKey = "PurchaseDocumentsAll"
			Or PurposeUseKey = "RedemptionOfGoodsFromStorage" Then	
			
			GeneratedDocuments_ = "OnlyRedemptionOfGoodsInStorage";
			Title = NStr("vi = 'Trợ giúp tạo mua lại';
						|ru = 'Помощник формирования выкупов';
						|en = 'Redemption generation wizard'; fa = 'Redemption generation wizard';
						|it = 'Assistente di generazione riscatti';
						|pl = 'Asystent utworzenia wykupów';
						|tr = 'İtfa oluşturma sihirbazı'");
		ElsIf PurposeUseKey =
						TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing() Then
			
			GeneratedDocuments_ = "OnlyRedemptionOfGiverSGoods";
			Title = NStr("vi = 'Trợ giúp tạo mua lại';
						|ru = 'Помощник формирования выкупов';
						|en = 'Redemption generation wizard'; fa = 'Redemption generation wizard';
						|it = 'Assistente di generazione riscatti';
						|pl = 'Asystent utworzenia wykupów';
						|tr = 'İtfa oluşturma sihirbazı'");
		ElsIf PurposeUseKey = "MonthEndTransactions" Then
			GeneratedDocuments_ = "OnlyRedemptionOfGoods";
			Title = NStr("vi = 'Trợ giúp tạo mua lại';
						|ru = 'Помощник формирования выкупов';
						|en = 'Redemption generation wizard'; fa = 'Redemption generation wizard';
						|it = 'Assistente di generazione riscatti';
						|pl = 'Asystent utworzenia wykupów';
						|tr = 'İtfa oluşturma sihirbazı'");
		EndIf;
	EndIf;
	
	Result = New Structure("Title,GeneratedDocuments_",Title,GeneratedDocuments_);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf