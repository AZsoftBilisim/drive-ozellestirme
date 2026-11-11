#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
// 		NewStatus - String - Name of the status that will be set for orders
// 		AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
// 		Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	Status = Enums.GoodsAssemblyStatuses[NewStatus];
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.AssemblyFromComponents);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.TS);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.Header);
	Return CheckFilling();
	
EndFunction

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.AssemblyFromComponents - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes());
	
EndProcedure

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
//
Procedure FillInProductTrackingForm() Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	ItemsLocationAttributes = AnalysisOfAccountingForDocumentHeaderProducts();
	
EndProcedure

// This function generates temporary document data.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	QueryTexts = New Array;
	
	PartOfTheRequestText = 
	"SELECT
	|	&Organization AS Organization,
	|	&Date AS Date,
	|	&Warehouse AS Warehouse,
	|	&Status AS Status,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	&AssemblyForActivity AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers AND NOT ISNULL(SalesOpportunities.EnabledGoodsAssignmentInSalesOpportunity, FALSE)
	|				AND Departments.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers AND NOT ISNULL(SalesOpportunities.EnabledGoodsAssignmentInSalesOpportunity, FALSE)
	|				AND Departments.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END AS Manager,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesBySalesOpportunities AND SalesOpportunities.EnabledGoodsAssignmentInSalesOpportunity
	|			THEN &SalesOpportunity
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END AS SalesOpportunity,
	|	&ProductsOfMainComponent AS ProductsOfMainComponent,
	|	&MainComponentCharacteristic AS MainComponentCharacteristic,
	|	&BusinessUnitProduction AS BusinessUnitProduction,
	|	&SubjectToExcise AS SubjectToExcise,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS Departments
	|		ON Departments.Ref = &Department
	|		
	|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunities
	|		ON SalesOpportunities.Ref = &SalesOpportunity
	|
	|WHERE
	|	Companies.Ref = &Organization
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
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END AS QuantityByGBRN,
	|	&ByAssemblyDisassemblyOrder AS OrderDocument,
	|	TableOfGoods.RowCode AS RowCode,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber
	|INTO TTTableOfProductsWriteOff
	|FROM
	|	&TableOfProductsWriteOff AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	&Warehouse AS Warehouse,
	|	&SalesOpportunity AS SalesOpportunity,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TableOfGoods.Purpose AS Purpose,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfProductsWriteOff AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	&Warehouse AS Warehouse,
	|	&SalesOpportunity AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTInventoryTypesWriteOff
	|FROM
	|	&TableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	&Warehouse AS Warehouse,
	|	&SalesOpportunity AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTInventoryTypesWriteOff AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.Count AS Count
	|INTO TTTableOfGoodsRegistration
	|FROM
	|	&TableOfGoodsRegistration AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN
	|INTO TTInventoryTypesRegistration
	|FROM
	|	&TableTypesOfStocksRegistration AS TableTypesOfStocks_";
	QueryTexts.Add(PartOfTheRequestText);
	RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
	RequestTextParameters.ProductTableName_ = "TTTableOfGoodsRegistration";
	
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(, RequestTextParameters));
	PartOfTheRequestText = 
	"SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.AssemblyFromComponents) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	&AssemblyForActivity AS VATTaxation,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	UNDEFINED AS GoodsOwner,
	|	CASE
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN &SubjectToExcise
	|		ELSE FALSE
	|	END AS SubjectToExcise,
	|	CASE
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN &BusinessUnitProduction
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS BusinessUnitProduction,
	|	VALUE(Catalog.VendorPriceTypes.EmptyRef) AS PriceKind
	|INTO OriginalProductTable
	|FROM
	|	TTTableOfGoodsRegistration AS TableOfGoods
	|		LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON TableOfGoods.Products = Category_Data.Products
	|";
	QueryTexts.Add(PartOfTheRequestText);
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Query.TempTablesManager = TempTablesManager;
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Organization, Date);
	
	If AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
			And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined Then
		
		DocumentTables = AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange;
		
	Else
		DocumentTables = Documents.AssemblyFromComponents.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
		FillPropertyValues(DocumentTables.DocumentHeader, ThisObject);
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		TableOfProductsWriteOff		= DocumentTables.Goods;
		TableOfGoodsRegistration	= CreateTableOfProducts(DocumentTables.DocumentHeader);
	Else
		TableOfProductsWriteOff		= CreateTableOfProducts(DocumentTables.DocumentHeader);
		TableOfGoodsRegistration	= DocumentTables.Goods;
	EndIf;
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Manager", EmployeeResponsible);
	Query.SetParameter("Department", Department);
	Query.SetParameter("SalesOpportunity", SalesOpportunity);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("Series", Series);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("ByAssemblyDisassemblyOrder", ByAssemblyDisassemblyOrder);
	Query.SetParameter("AssemblyForActivity", AssemblyForActivity);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers", GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities", GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter("ProductsOfMainComponent", ProductsOfMainComponent);
	Query.SetParameter("MainComponentCharacteristic", MainComponentCharacteristic);
	Query.SetParameter("Status", Status);
	Query.SetParameter("TableOfProductsWriteOff", TableOfProductsWriteOff);
	Query.SetParameter("TableOfGoodsRegistration", TableOfGoodsRegistration);
	Query.SetParameter("TableTypesOfInventoryWriteOff", InventoryOwnerAttributesConsumption);
	Query.SetParameter("TableTypesOfStocksRegistration", InventoryOwnerAttributesGoodsReceipt);
	RegistrationCountry				= SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	UseExcisableGoods	= GetFunctionalOption("UseExcisableGoods");
	
	Query.SetParameter("Country",							RegistrationCountry);
	Query.SetParameter("SubjectToExcise",				SubjectToExcise);
	Query.SetParameter("BusinessUnitProduction",		BusinessUnitProduction);
	Query.SetParameter("UseExcisableGoods",	UseExcisableGoods);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		TableOfProductsWriteOff,
		Query.Text,
		"&FieldTextTableOfGoodsQuantityByGBRN_",
		"TableOfGoods",
		"QuantityByGBRN",
		"TableOfGoods.QuantityByGBRN",
		"0");
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		TableOfProductsWriteOff,
		Query.Text,
		"&FieldTextTableOfGoodsCCDNumber_",
		"TableOfGoods",
		"CCDNumber",
		"TableOfGoods.CCDNumber",
		"VALUE(Catalog.CCDNumbers.EmptyRef)");
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

// Fills in the details that store information about the types of inventory and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular parts of the "Types of Inventory" and "Types of Inventory receipt".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.AssemblyFromComponents.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	ItemsLocationAttributes = AnalysisOfAccountingForDocumentHeaderProducts();

	If DocumentTables <> Undefined Then
		FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables);
		FillPropertyValues(DocumentTables.DocumentHeader, ThisObject, "ItemsLocationAttributes");
		AdditionalProperties.Insert("TablesOfFillingOfTypesOfStocksAtExchange", DocumentTables);
	EndIf;
	
	FillStockTypes(Cancel);
	AdditionalProperties.Delete("TablesOfFillingOfTypesOfStocksAtExchange");
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);

	Status = Metadata().Attributes.Status.FillValue;
	
	ByAssemblyDisassemblyOrder = Undefined;
	ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	InventoryOwnerAttributesAreSpecifiedManually = False;
	
	InventoryOwnerAttributesConsumption.Clear();
	InventoryOwnerAttributesGoodsReceipt.Clear();
	SetOfSeries.Clear();
	
	InitializeDocument();
	
	If BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		
		For Each TSRow In Goods Do
			
			TSRow.RowCode = 0;
			TSRow.RowID = "";
			
		EndDo;
		
		Table = New ValueTable();
		Structure = New Structure("IndexOf,Products,Purpose");
		For Each Field In Structure Do
			Table.Columns.Add(Field.Key, Field.Value);
		EndDo;
		
		TableRow = Table.Add();
		FillPropertyValues(TableRow, ThisObject);
		TableRow.IndexOf = 0;
		DefaultAssignment = LinesOfBusinessServer.PushingAssignment(LineOfBusiness);
		InvoicesServer.FillInAssignmentsInTablePart(Table, DefaultAssignment);
		Purpose = Table[0].Purpose;
		
	Else
		
		For Each TSRow In Goods Do
			
			TSRow.RowCode = 0;
			TSRow.RowID = "";
			
		EndDo;
		DefaultAssignment = LinesOfBusinessServer.PushingAssignment(LineOfBusiness);
		InvoicesServer.FillInAssignmentsInTablePart(Goods, DefaultAssignment);
		
	EndIf;
	
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryOwnerAttributesConsumption");
	
	AssemblyFromComponentsLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	NotCheckedAttributeArray = New Array;
	UseCharacteristics = GetFunctionalOption("UseItemVariants");
	BusinessTransactions = Enums.BusinessTransactions;
	
	// Checking the quantity in the header.
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TSName = "Object";
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);

	// Checking the quantity including goods.
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);

	// If the assembly - a share of the cost is not needed.
	If BusinessOperation = BusinessTransactions.AssemblyFromComponents Or Goods.Count() < 2 Then
		NotCheckedAttributeArray.Add("Goods.CostShare");
	EndIf;

	// If the invoice is for an order, then the line code must be filled in.
	If Not ValueIsFilled(ByAssemblyDisassemblyOrder) Then
		NotCheckedAttributeArray.Add("Goods.RowCode");
	EndIf;

	// Checking the characteristics in the header.
	If Not UseCharacteristics
		Or Not Catalogs.Products.ItemVariantsAreUsed(Products) Then
		
		NotCheckedAttributeArray.Add("Characteristic");
	
	EndIf;
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date);
	
	AttributesNames = "KeepRecordsByCCD, TracedGoods";
	ProductAttributes = TMCommonUse.DefaultValuesForItemDetails(Products, AttributesNames);
	
	TraceableKit = ProductAttributes.TracedGoods
								And UseTraceableImportedGoodsAccounting;
	MonitorCCDNumbers = RestrictGoodsReceiptWithoutCCDNumbers
								And ((ProductAttributes.KeepRecordsByCCD
										And BusinessOperation = BusinessTransactions.AssemblyFromComponents)
									Or Not ProductAttributes.KeepRecordsByCCD
										And BusinessOperation = BusinessTransactions.DisassemblyIntoComponents);
	
	If Not TraceableKit
		And ValueIsFilled(ProductsOfMainComponent)
		And BusinessOperation = BusinessTransactions.AssemblyFromComponents Then
		
		ViewOfTheMainComponent = ProductsClientServer.ProductPresentation(
											ProductsOfMainComponent,
											MainComponentCharacteristic);
		
		FilterOfProducts_ = New Structure("Products, Characteristic",
										ProductsOfMainComponent, MainComponentCharacteristic);
		
		If Goods.FindRows(FilterOfProducts_).Count() = 0 Then
			MessageText = NStr("vi = 'Thành phần chính `%ProductName_%` ''không được tìm thấy trong hàng hóa. 
				|Hãy chỉ ra thành phần chính từ danh sách hàng hóa';
				|ru = 'Основной компонент `%ProductName_%` в товарах не найден.
				|Укажите основной компонент из перечня товаров';
				|en = 'Main component ""%ProductName_%"" is not found in the list of goods.
				|Choose a main component from the list of goods'; fa = 'Main component ""%ProductName_%"" is not found in the list of goods.
				|Choose a main component from the list of goods';
				|it = 'Il componente principale `%ProductName_%` non è stato trovato nelle merci. 
				| Indicare il componente dalla lista della merce.';
				|pl = 'Głównego komponentu `%ProductName_%` w towarach nie znaleziono.
				|Podaj główny komponent z wykazu towarów';
				|tr = '`%ProductName_%` ana bileşeni ürünlerde bulunamadı.
				|Lütfen ürün listesinden ana bileşeni seçin.'");
			MessageText = StrReplace(MessageText, "%ProductName_%", ViewOfTheMainComponent);
			
			Common.MessageToUser(MessageText, Undefined, "", "Object", Cancel);
		EndIf;
		
		If MonitorCCDNumbers
			Or UseTraceableImportedGoodsAccounting Then
			
			AttributesOfMainComponent = TMCommonUse.DefaultValuesForItemDetails(
											ProductsOfMainComponent,
											AttributesNames);
			
		Else
			AttributesOfMainComponent = New Structure(AttributesNames, False, False);
		EndIf;
		
		If MonitorCCDNumbers
			And AttributesOfMainComponent.TracedGoods Then
			MessageText = NStr("vi = 'Đối với bộ không được truy xuất đã chỉ định thành phần chi tiết `%ProductName_%`theo số đăng ký lô hàng làm cấu phần chính.
				|Hãy chỉ định cấu phần chính không được truy xuất mà theo đó tiến hành kế toán theo tờ khai hải quan.';
				|ru = 'Для непрослеживаемого комплекта в качестве основного компонента указана прослеживаемая по РНПТ комплектующая `%ProductName_%`.
				|Укажите непрослеживаемый основной компонент, по которому ведется учет по ГТД.';
				|en = 'For an untraceable kit, the ""%ProductName_%"" RNPT-traceable component is specifed as a main component.
				|Specify an untraceable main component that has CCD records.'; fa = 'For an untraceable kit, the ""%ProductName_%"" RNPT-traceable component is specifed as a main component.
				|Specify an untraceable main component that has CCD records.';
				|it = 'For an untraceable kit, the ""%ProductName_%"" RNPT-traceable component is specifed as a main component.
				|Specify an untraceable main component that has CCD records.';
				|pl = 'For an untraceable kit, the ""%ProductName_%"" RNPT-traceable component is specifed as a main component.
				|Specify an untraceable main component that has CCD records.';
				|tr = 'Lot Kayıt Numarası bazında izlenebilir `%ProductName_%` parçası, izlenemeyen bir set için ana bileşen olarak  belirtilmiştir.
				|İzlenemeyen, Gümrük Kargo Beyannamesi kaydı tutulan bir ana bileşeni belirtiniz.'");
			MessageText = StrReplace(MessageText, "%ProductName_%", ViewOfTheMainComponent);
			
			Common.MessageToUser(MessageText, Undefined, "", "Object", Cancel);
			
		EndIf;
		
		If MonitorCCDNumbers Then
			If Not AttributesOfMainComponent.KeepRecordsByCCD Then
				If UseTraceableImportedGoodsAccounting Then
					RecommendationText = NStr("vi = 'Hãy chỉ định cấu phần chính không được truy xuất mà theo đó tiến hành kế toán theo tờ khai hải quan';
												|ru = 'Укажите непрослеживаемый основной компонент, по которому ведется учет по ГТД';
												|en = 'Specify an untraceable main component that has CCD records'; fa = 'Specify an untraceable main component that has CCD records';
												|it = 'Specify an untraceable main component that has CCD records';
												|pl = 'Specify an untraceable main component that has CCD records';
												|tr = 'İzlenemeyen, Gümrük Kargo Beyannamesi kaydı tutulan bir ana bileşeni belirtiniz.'");
				Else
					RecommendationText = NStr("vi = 'Hãy chỉ định cấu phần chính mà theo đó tiến hành kế toán theo tờ khai hải quan';
												|ru = 'Укажите основной компонент, по которому ведется учет по ГТД';
												|en = 'Specify a main component that has CCD records'; fa = 'Specify a main component that has CCD records';
												|it = 'Specify a main component that has CCD records';
												|pl = 'Specify a main component that has CCD records';
												|tr = 'Gümrük Kargo Beyannamesi kaydı tutulan bir ana bileşeni belirtiniz.'");
				EndIf;
				
				MessageText = NStr("vi = 'Theo cấu phần chính `%ProductName_%` không tiến hành kế toán theo tờ khai hải quan.
					|%RecommendationText%.';
					|ru = 'По основному компоненту `%ProductName_%` учет по ГТД не ведется.
					|%RecommendationText%.';
					|en = 'CCD records are not kept for the ""%ProductName_%"" main component.
					|%RecommendationText%.'; fa = 'CCD records are not kept for the ""%ProductName_%"" main component.
					|%RecommendationText%.';
					|it = 'CCD records are not kept for the ""%ProductName_%"" main component.
					|%RecommendationText%.';
					|pl = 'CCD records are not kept for the ""%ProductName_%"" main component.
					|%RecommendationText%.';
					|tr = '`%ProductName_%` ana bileşeni için Gümrük Kargo Beyannamesi kaydı tutulmaz.
					|%RecommendationText%.'");
				MessageText = StrReplace(MessageText, "%ProductName_%", ViewOfTheMainComponent);
				MessageText = StrReplace(MessageText, "%RecommendationText%", RecommendationText);
				
				Common.MessageToUser(MessageText, Undefined, "", "Object", Cancel);
			EndIf;
		EndIf;
		
		CheckComponentCharacteristics =
			UseCharacteristics
			And Not ValueIsFilled(MainComponentCharacteristic)
			And Catalogs.Products.ItemVariantsAreUsed(ProductsOfMainComponent);
		
		If CheckComponentCharacteristics Then
			CheckedAttributes.Add("MainComponentCharacteristic");
		EndIf;
		
	ElsIf Not TraceableKit
		And MonitorCCDNumbers
		And BusinessOperation = BusinessTransactions.AssemblyFromComponents Then
		
		If UseTraceableImportedGoodsAccounting Then
			RecommendationText = NStr("vi = 'Hãy chỉ định cấu phần chính không được truy xuất mà theo đó tiến hành kế toán theo tờ khai hải quan';
										|ru = 'Укажите непрослеживаемый основной компонент, по которому ведется учет по ГТД';
										|en = 'Specify an untraceable main component that has CCD records'; fa = 'Specify an untraceable main component that has CCD records';
										|it = 'Specify an untraceable main component that has CCD records';
										|pl = 'Specify an untraceable main component that has CCD records';
										|tr = 'İzlenemeyen, Gümrük Kargo Beyannamesi kaydı tutulan bir ana bileşeni belirtiniz.'");
		Else
			RecommendationText = NStr("vi = 'Hãy chỉ định cấu phần chính mà theo đó tiến hành kế toán theo tờ khai hải quan';
										|ru = 'Укажите основной компонент, по которому ведется учет по ГТД';
										|en = 'Specify a main component that has CCD records'; fa = 'Specify a main component that has CCD records';
										|it = 'Specify a main component that has CCD records';
										|pl = 'Specify a main component that has CCD records';
										|tr = 'Gümrük Kargo Beyannamesi kaydı tutulan bir ana bileşeni belirtiniz.'");
		EndIf;
		
		MessageText = NStr("vi = 'Cần xác định nước xuất xứ và số tờ khai hải quan của bộ.
			|%1.';
			|ru = 'Требуется определять страну происхождения и номера ГТД комплекта.
			|%1.';
			|en = 'Country of origin and CCD numbers of the kit are required.
			|%1.'; fa = 'Country of origin and CCD numbers of the kit are required.
			|%1.';
			|it = 'Country of origin and CCD numbers of the kit are required.
			|%1.';
			|pl = 'Country of origin and CCD numbers of the kit are required.
			|%1.';
			|tr = 'Setin menşei ülkesini ve GKB numarasını belirlemek gerekir.
			|%1.'");
		MessageText = StrTemplate(MessageText, RecommendationText);
		
		Common.MessageToUser(MessageText, Undefined, "", "Object", Cancel);
		
	ElsIf TraceableKit
		And BusinessOperation = BusinessTransactions.AssemblyFromComponents Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Components.LineNumber AS LineNumber,
		|	Components.Products AS Products
		|INTO Components
		|FROM &Components AS Components
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	Components.LineNumber
		|FROM
		|	Components AS Components
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON CatalogProducts.Ref = Components.Products
		|
		|WHERE
		|	CatalogProducts.TracedGoods";
		
		Query.SetParameter("Components", Goods.Unload( , "LineNumber, Products"));
		
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			MessageText = NStr("vi = 'Trong danh sách ""Thành phần chi tiết"" không có thành phần chi tiết được truy xuất theo số đăng ký lô hàng. 
			|Để đóng bộ bộ sản phẩm được truy xuất, cần chỉ ra ít nhất một thành phần chi tiết được truy xuất.';
			|ru = 'В списке ""Комплектующие"" отсутствуют прослеживаемые по РНПТ комплектующие.
			|Для сборки прослеживаемого комплекта необходимо указать хотя бы одну прослеживаемую комплектующую.';
			|en = 'The ""Components"" list does not include any RNPT-traceable components.
			|To assemble a traceable kit, specify at least one traceable component.'; fa = 'The ""Components"" list does not include any RNPT-traceable components.
			|To assemble a traceable kit, specify at least one traceable component.';
			|it = 'В списке ""Комплектующие"" отсутствуют прослеживаемые по РНПТ комплектующие.
			|Для сборки прослеживаемого комплекта необходимо указать хотя бы одну прослеживаемую комплектующую.';
			|pl = 'The ""Components"" list does not include any RNPT-traceable components.
			|To assemble a traceable kit, specify at least one traceable component.';
			|tr = 'В списке ""Комплектующие"" отсутствуют прослеживаемые по РНПТ комплектующие.
			|Для сборки прослеживаемого комплекта необходимо указать хотя бы одну прослеживаемую комплектующую.'");
			
			Common.MessageToUser(MessageText, Undefined, "", "Object", Cancel);
		EndIf;
		
	ElsIf (MonitorCCDNumbers
			Or (Not TraceableKit
				And UseTraceableImportedGoodsAccounting))
		And BusinessOperation = BusinessTransactions.DisassemblyIntoComponents Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Components.LineNumber AS LineNumber,
		|	Components.Products AS Products
		|INTO Components
		|FROM &Components AS Components
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Components.LineNumber		AS LineNumber,
		|	CASE
		|		WHEN NOT (NOT &TraceableKit
		|				AND CatalogProducts.TracedGoods
		|				AND &UseTraceableImportedGoodsAccounting)
		|			THEN &MonitorCCDNumbers
		|		ELSE FALSE
		|	END						AS KeepRecordsByCCD,
		|	CASE
		|		WHEN NOT &TraceableKit
		|				AND CatalogProducts.TracedGoods
		|				AND &UseTraceableImportedGoodsAccounting
		|			THEN TRUE
		|		ELSE FALSE
		|	END						AS TracedGoods
		|	
		|FROM
		|	Components AS Components
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON CatalogProducts.Ref = Components.Products
		|
		|WHERE
		|	CatalogProducts.KeepRecordsByCCD
		|	AND (&MonitorCCDNumbers
		|		OR (NOT &TraceableKit
		|			AND CatalogProducts.TracedGoods
		|			AND &UseTraceableImportedGoodsAccounting))";
		
		Query.SetParameter("Components", Goods.Unload( , "LineNumber, Products"));
		Query.SetParameter("TraceableKit", TraceableKit);
		Query.SetParameter("MonitorCCDNumbers", MonitorCCDNumbers);
		Query.SetParameter("UseTraceableImportedGoodsAccounting",
									UseTraceableImportedGoodsAccounting);
		
		QueryResult = Query.Execute();
		DataValidationTable = QueryResult.Unload();
		DataValidationTable.Indexes.Add("KeepRecordsByCCD");
		DataValidationTable.Indexes.Add("TracedGoods");
		
		SelectionOfImportedGoods		= New Structure("KeepRecordsByCCD", True);
		FilterOfTraceableGoods	= New Structure("TracedGoods", True);
		
		ImportedGoods			= DataValidationTable.FindRows(SelectionOfImportedGoods);
		TraceableGoods	= DataValidationTable.FindRows(FilterOfTraceableGoods);
		
		If ImportedGoods.Count() > 0 Then
			MessageTemplate = NStr("vi = 'Đối với thành phần chi tiết, trong dòng %LineNumber% của danh sách ""Thành phần chi tiết"" có ghi nhận theo tờ khai hải quan.
				|Các mục mặt hàng này không khả dụng, nếu đối với bộ sản phẩm được chia tách không ghi nhận theo tờ khai hải quan.';
				|ru = 'Для комплектующей в строке %LineNumber% списка ""Комплектующие"" ведется учет по ГТД.
				|Такие позиции недопустимы, если для разбираемого комплекта не ведется учет по ГТД.';
				|en = 'CCD records are kept for the component in line %LineNumber% of the ""Components"" list.
				|These items are invalid if the disassembled kit has no CCD records.'; fa = 'CCD records are kept for the component in line %LineNumber% of the ""Components"" list.
				|These items are invalid if the disassembled kit has no CCD records.';
				|it = 'Для комплектующей в строке %LineNumber% списка ""Комплектующие"" ведется учет по ГТД.
				|Такие позиции недопустимы, если для разбираемого комплекта не ведется учет по ГТД.';
				|pl = 'CCD records are kept for the component in line %LineNumber% of the ""Components"" list.
				|These items are invalid if the disassembled kit has no CCD records.';
				|tr = '""Ürünler"" listesi %LineNumber% satırında yer alan bileşen için Kargo Gümrük Beyannamesine göre muhasebeleştirme yapılır.
				|Ayrıştırılan setin Kargo Gümrük Beyannamesine göre muhasebesi tutulmadığı takdirde bu tür pozisyonlara izin verilmez.'");
			
			For Each TSRow In ImportedGoods Do
				MessageText = StrReplace(MessageTemplate, "%LineNumber%", TSRow.LineNumber);
				Field = CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "CCDNumber");
				
				Common.MessageToUser(MessageText, Undefined, Field, "Object", Cancel);
			EndDo;
		EndIf;
		
		If TraceableGoods.Count() > 0 Then
			MessageTemplate = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""Thành phần chi tiết"" đã chỉ ra thành phần chi tiết được truy xuất theo số đăng ký lô hàng. 
				|Những mục như vậy không được phép, nếu đang tách bộ của bộ sản phẩm không được truy xuất.';
				|ru = 'В строке %LineNumber% списка ""Комплектующие"" указана прослеживаемая по РНПТ комплектующая.
				|Такие позиции недопустимы, если выполняется разборка непрослеживаемого комплекта.';
				|en = 'In line %LineNumber% of the ""Components"" list, the RNPT-traceable component is specified.
				|These items are invalid if an untraceable kit is being disassembled.'; fa = 'In line %LineNumber% of the ""Components"" list, the RNPT-traceable component is specified.
				|These items are invalid if an untraceable kit is being disassembled.';
				|it = 'В строке %LineNumber% списка ""Комплектующие"" указана прослеживаемая по РНПТ комплектующая.
				|Такие позиции недопустимы, если выполняется разборка непрослеживаемого комплекта.';
				|pl = 'In line %LineNumber% of the ""Components"" list, the RNPT-traceable component is specified.
				|These items are invalid if an untraceable kit is being disassembled.';
				|tr = 'В строке %LineNumber% списка ""Комплектующие"" указана прослеживаемая по РНПТ комплектующая.
				|Такие позиции недопустимы, если выполняется разборка непрослеживаемого комплекта.'");
			
			For Each TSRow In TraceableGoods Do
				MessageText = StrReplace(MessageTemplate, "%LineNumber%", TSRow.LineNumber);
				Field = CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "CCDNumber");
				
				Common.MessageToUser(MessageText, Undefined, Field, "Object", Cancel);
			EndDo;
		EndIf;
	EndIf;

	// Checking the characteristics, including goods.
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	
	FilterOfProducts_ = New Structure("Products, Characteristic", Products, Characteristic);
	KitPresentation = ProductsClientServer.ProductPresentation(Products, Characteristic);
	For Each TSRow In Goods.FindRows(FilterOfProducts_) Do
		MessageText = NStr("vi = 'Trong dòng %LineNumber% đã chỉ định hàng hóa ""%ProductName_%"".
			|Một hàng hóa không thể đồng thời là một bộ sản phẩm và là một thành phần chi tiết.';
			|ru = 'В строке %LineNumber% указан товар ""%ProductName_%"".
			|Один и тот же товар не может являться и комплектом, и комплектующей одновременно.';
			|en = 'You have specified ""%ProductName_%"" in line %LineNumber%.
			|The same product cannot be both a set and a component.'; fa = 'You have specified ""%ProductName_%"" in line %LineNumber%.
			|The same product cannot be both a set and a component.';
			|it = 'La riga %LineNumber% contiene il prodotto ""%ProductName_%"".
			|Il prodotto non può essere un insieme e un componente allo stesso tempo.';
			|pl = 'W wierszu %LineNumber% jest podany towar ""%ProductName_%"".
			|Jeden i ten sam towar nie może być jednocześnie kompletem i komponentem.';
			|tr = '%LineNumber% satırında ürün belirtildi ""%ProductName_%"". 
			|Aynı ürün aynı anda hem set hem de bileşen olamaz.'");
		MessageText = StrReplace(MessageText, "%ProductName_%", KitPresentation);
		MessageText = StrReplace(MessageText, "%LineNumber%", TSRow.LineNumber);
	
		Field = CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "Products");
		Common.MessageToUser(MessageText, Undefined, Field, "Object", Cancel);
	EndDo;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.AssemblyFromComponents);
	ParametersArray = New Array;
	ParametersArray.Add(SeriesSpecificationParameters.TS);
	ParametersArray.Add(SeriesSpecificationParameters.Header);
	ProductsServer.CheckSeriesCompletion(ThisObject,
		ParametersArray,
		Cancel,
		NotCheckedAttributeArray);
		
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	If Not SubjectToExcise Then
		NotCheckedAttributeArray.Add("BusinessUnitProduction");
	Else
		CheckCorrectnessOfExciseItemIndication(Cancel);
	EndIf;
	If BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		
		QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
			ThisObject,
			NotCheckedAttributeArray,
			Cancel,
			Undefined,
			Undefined,
			"DateOfReceipt");
			
		NotCheckedAttributeArray.Add("Goods.QualityConfirmationDate");
		
	Else
	
		QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
			ThisObject,
			NotCheckedAttributeArray,
			Cancel,
			"Goods",
			NStr("vi = 'Hàng hóa';
				|ru = 'Товары';
				|en = 'Items'; fa = 'اقلام';
				|it = 'Merci';
				|pl = 'Wiersze pozycji';
				|tr = 'Ürünler'"),
			"DateOfReceipt");
			
		QualityControl.ProcessingVerificationOfCorrectnessOfConnectionWithBatches(
			ThisObject,
			SeriesSpecificationParameters.TS.LinkFields,
			"Goods",
			NStr("vi = 'Hàng hóa';
				|ru = 'Товары';
				|en = 'Items'; fa = 'اقلام';
				|it = 'Merci';
				|pl = 'Wiersze pozycji';
				|tr = 'Ürünler'"),
			Cancel);
		
		NotCheckedAttributeArray.Add("QualityConfirmationDate");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	AssemblyFromComponentsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName = "Goods";
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(ThisObject, AssemblyForActivity, CheckParameters, Cancel);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	RoundingParameters = ProductsServer.ParametersForRoundingNumberOfUnitProducts();
	RoundingParameters.TSName = "Object";
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	// Cleaning of unused details in PM Goods
	If BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		For Each OwnGoods In Goods Do
			If OwnGoods.CostShare <> 0 Then
				OwnGoods.CostShare = 0;
			EndIf;
		EndDo;
	EndIf;
	
	SeriesParameters_ = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.AssemblyFromComponents);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesParameters_);
	
	// Filling in inventory types.
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingForm();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryOwnerAttributesConsumption.Clear();
			InventoryOwnerAttributesGoodsReceipt.Clear();
		EndIf;
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryOwnerAttributesConsumption");
	
	// The mechanism of "Controlled Lot references".
	KeyAttributes = QualityControl.DetailsOfDeterminingNeedForLotReferenceInDocument(Warehouse, BusinessOperation);
	QualityControl.FillInControlledLotReferenceBeforeWritingDocument(ThisObject, KeyAttributes);
	
	AssemblyFromComponentsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateUpdateControlledLotReferenceWhenWritingDocument(ThisObject);
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	AssemblyFromComponentsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillingStructure = Undefined;
	
	ReferenceOrder = DocumentBaseWhenFillingIn(FillingData);
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(ReferenceOrder);
	
	// Filling in by order(s).
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("AnArrayOfOrders") Then
		
		FillingStructure = FillingData;
		FillingStructure.HeaderAttributes.Insert("GoodsReceiptOption", GoodsReceiptOption);
		
		FillInFromOrder(FillingStructure);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.AssemblyFromComponents") Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	AssemblyFromComponentsLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	AssemblyFromComponentsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	AssemblyFromComponentsLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//    Table - See AccessManagement.AccessValuesSetsTable
Procedure FillAccessValuesSets(Table) Export

	TabRow = Table.Add();
	TabRow.AccessValue = Organization;

	TabRow = Table.Add();
	TabRow.AccessValue = Warehouse;
	
EndProcedure

Procedure FillInFromOrder(FillingStructure)
	
	AnArrayOfOrders = FillingStructure.AnArrayOfOrders;
	
	FillParameters = Documents.AssemblyFromComponents.DocumentFillingParameters();
	FillPropertyValues(FillParameters, FillingStructure);
	Documents.AssemblyFromComponents.InitializeFillingParameters(FillParameters, FillingStructure.HeaderAttributes,
		AnArrayOfOrders);
	
	// Filling in the header
	Documents.AssemblyFromComponents.FillInHeaderOfOrderDocument(ThisObject, FillParameters, AnArrayOfOrders);
	
	InvoiceTable = Documents.AssemblyFromComponents.TableDataAndDocument(ThisObject.Ref);
	InvoiceByHeaderTable = Documents.AssemblyFromComponents.TableDataAndDocument(ThisObject.Ref, True);
	
	Resources = New Array(1);
	
	Resources[0] = "Kit";
	FillParameters.Resources = Resources;
	Documents.AssemblyFromComponents.FillInByOrdersOrders(InvoiceByHeaderTable, Ref, FillParameters, PackageBarcodes);
	
	Resources[0] = "Components";
	FillParameters.Resources = Resources;
	Documents.AssemblyFromComponents.FillInByOrdersOrders(InvoiceTable, Ref, FillParameters, PackageBarcodes);
	
	If FillParameters.FillByWarehouseDocument Then
		InvoiceByHeaderTable.Columns.Count.Name        = "QuantityBeforeChange_";
		InvoiceByHeaderTable.Columns.NoteQuantity.Name = "Count";
		
		InvoiceTable.Columns.Count.Name               = "QuantityBeforeChange_";
		InvoiceTable.Columns.NoteQuantity.Name        = "Count";
	Else
		InvoiceByHeaderTable.Columns.Count.Name        = "QuantityBeforeChange_";
		InvoiceByHeaderTable.Columns.QuantityInOrder.Name = "Count";
		
		InvoiceTable.Columns.Count.Name               = "QuantityBeforeChange_";
		InvoiceTable.Columns.QuantityInOrder.Name        = "Count";
	EndIf;
	
	Goods.Load(InvoiceTable);
	
	Documents.AssemblyFromComponents.ResubmitProductsInHeader(ThisObject, InvoiceByHeaderTable, AnArrayOfOrders[0]);
	
	Documents.AssemblyFromComponents.UpdateDependentDetailsOfTablePart(Goods, FillParameters);
	
	// Filling in the series.
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.AssemblyFromComponents);
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters.TS, False);
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters.Header, False);
	
	// Filling out the order in the header.
	ByAssemblyDisassemblyOrder = AnArrayOfOrders[0];
	
	// Filling in the cost shares
	If Not FillParameters.FillByWarehouseDocument
		And ValueIsFilled(ByAssemblyDisassemblyOrder) And ValueIsFilled(ProductKit)
		And BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		FillInCOSTShares();
	EndIf;
	
	If FillParameters.FillByWarehouseDocument Then
		Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled;
	EndIf;
	
EndProcedure

Procedure FillInCOSTShares()
	
	Query = New Query();
	Query.SetParameter("ByAssemblyDisassemblyOrder", ByAssemblyDisassemblyOrder);
	Query.Text = 
	"SELECT TOP 1
	|	Table.ToRegisterGoodsReceiptsExpense
	|FROM
	|	AccumulationRegister.GoodsToReceive.Turnovers(, , , DocumentInflow = &ByAssemblyDisassemblyOrder) AS Table";
	
	// Filling in the cost shares is possible only if there are no invoices (the first one is created)
	If Query.Execute().IsEmpty() Then
		
		Query = New Query();
		Query.TempTablesManager = New TempTablesManager();
		Query.SetParameter("KitCount", Count);
		Query.SetParameter("ProductKit", ProductKit);
		Query.SetParameter("Goods", Goods.Unload(,"LineNumber, Products, Characteristic, Package, Count"));
		
		// The share of the cost is filled in if the composition of the lines and the quantity match the configuration option.
		QueryText = 
		"SELECT
		|	Table.LineNumber     AS LineNumber,
		|	Table.Products    AS Products,
		|	Table.Characteristic  AS Characteristic,
		|	Table.Package        AS Package,
		|	Table.Count      AS Count
		|INTO TTProducts_1
		|FROM
		|	&Goods AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Products              AS Products,
		|	Table.Characteristic            AS Characteristic,
		|	Table.Package                  AS Package,
		|	&KitCount * Table.Count * CASE
		|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN 1
		|		ELSE &QueryTextPackagingFactor
		|	END / Table.Ref.Count AS Count,
		|	Table.CostShare             AS CostShare
		|INTO TTConfigurationOptions
		|FROM
		|	Catalog.ProductKitConfigurations.Goods AS Table
		|WHERE
		|	Table.Ref = &ProductKit
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Package
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	Set.Products      AS Products,
		|	Set.Characteristic    AS Characteristic,
		|	Set.Package          AS Package,
		|	SUM(Set.Count) AS Count,
		|	SUM(Set.ThereAreGoods)  AS ThereAreGoods
		|INTO TTThereAreDeviations
		|FROM
		|(
		|	SELECT
		|		Table.Products    AS Products,
		|		Table.Characteristic  AS Characteristic,
		|		Table.Package        AS Package,
		|		-Table.Count     AS Count,
		|		1                       AS ThereAreGoods
		|	FROM
		|		TTProducts_1 AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.Products    AS Products,
		|		Table.Characteristic  AS Characteristic,
		|		Table.Package        AS Package,
		|		Table.Count      AS Count,
		|		1                       AS ThereAreGoods
		|	FROM
		|		TTConfigurationOptions AS Table) AS Set
		|
		|GROUP BY
		|	Products,
		|	CHARACTERISTIC,
		|	Package
		|
		|HAVING
		|	SUM(Set.Count) <> 0 OR SUM(Set.ThereAreGoods) <> 2
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.LineNumber               AS LineNumber,
		|	ConfigurationTable_.CostShare AS CostShare
		|FROM
		|	TTProducts_1 AS Table
		|		LEFT JOIN TTConfigurationOptions AS ConfigurationTable_
		|		ON Table.Products = ConfigurationTable_.Products
		|			AND Table.Characteristic = ConfigurationTable_.Characteristic
		|			AND Table.Package = ConfigurationTable_.Package
		|			AND Table.Count = ConfigurationTable_.Count
		|		LEFT JOIN TTThereAreDeviations AS TTThereAreDeviations
		|		ON TRUE
		|	
		|WHERE
		|	NOT ConfigurationTable_.CostShare IS NULL
		|	AND TTThereAreDeviations.ThereAreGoods IS NULL";
		
		QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
		
		Query.Text = QueryText;
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			RowOfProductsTable = Goods[Selection.LineNumber - 1];
			RowOfProductsTable.CostShare = Selection.CostShare;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)

	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	EmployeeResponsible    = Users.CurrentUser();
	Department    = SettingsValueCached.UserDivision(EmployeeResponsible, Department);

	If Not GetFunctionalOption("UseGoodsAssemblyStatuses") Then
		Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled;
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.AssemblyFromComponents);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.TS);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.Header);
	
	FillParameters = Documents.AssemblyFromComponents.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(AssemblyForActivity, FillParameters);
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Header"));
	Header = New Structure(
		"Products,
		|ToControlQuality,
		|QualityConfirmationDate");
	FillPropertyValues(Header, ThisObject);
	BatchProcessingOfTablePartServer.ProcessTSString(Header, StructureOfActions, Undefined);
	FillPropertyValues(ThisObject, Header);
	
EndProcedure

Function DocumentBaseWhenFillingIn(FillingData)
	
	If FillingData = Undefined Then
		Return Undefined;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("AnArrayOfOrders") Then
		
		Return FillingData.AnArrayOfOrders[0];
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#Region InventoryKinds

Function CreateTableOfProducts(HeaderAttributes)
	
	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("LineNumber", New TypeDescription("Number"));
	TableOfGoods.Columns.Add("RowCode", New TypeDescription("Number"));
	TableOfGoods.Columns.Add("ItemsLocationAttributes", New TypeDescription("CatalogRef.InventoryLocationAttributeKeys"));
	TableOfGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfGoods.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	TableOfGoods.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	TableOfGoods.Columns.Add("BatchesIndicationStatus", New TypeDescription("Number"));
	TableOfGoods.Columns.Add("Count", New TypeDescription("Number"));
	TableOfGoods.Columns.Add("QuantityByGBRN", New TypeDescription("Number"));
	TableOfGoods.Columns.Add("CCDNumber", New TypeDescription("CatalogRef.CCDNumbers"));
	
	FillPropertyValues(TableOfGoods.Add(), HeaderAttributes);
	TableOfGoods[0].LineNumber = 1;
	
	Return TableOfGoods;
	
EndFunction

// The procedure creates a temporary table of products with separate accounting Analytics.
//
// Parameters:
//	TempTablesManager - TempTablesManager - A temp table of items with separate accounting analytics.
//
Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
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
	|	DocumentDataTable.Department,
	|	DocumentDataTable.Manager,
	|	DocumentDataTable.SalesOpportunity,
	|	TableOfGoods.Purpose AS Purpose,
	|
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|
	|	TableOfGoods.Count AS Count
	|	
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE";
	
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.AssemblyFromComponents.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.AssemblyFromComponents.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.AssemblyFromComponents,
					Warehouse,
					Department,
					Undefined);
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting);
	
EndProcedure

Function AnalysisOfAccountingForDocumentHeaderProducts()
	
	DocumentHeader = CreateTableOfProducts(ThisObject);
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.AssemblyFromComponents,
					Warehouse,
					Department,
					Undefined);
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(DocumentHeader, PlacesOfAccounting);
	
	Return DocumentHeader[0].ItemsLocationAttributes;
	
EndFunction

Function CheckChangesToDebitingDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Warehouse, Status";
	AttributesNames = AttributesNames + ", SubjectToExcise, BusinessUnitProduction";
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckChangesToDocumentDetailsRegistration(TempTablesManager)
	
	AttributesNames = "ProductsOfMainComponent, MainComponentCharacteristic";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckChangesInDebitedItems(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.Purpose AS Purpose,
	|		TableOfGoods.Count AS Count
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|		-TableTypesOfStocks_.Count AS Count
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Purpose
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Function CheckChangesToRegisteredProducts(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.Purpose AS Purpose,
	|		TableOfGoods.Count AS Count
	|	FROM
	|		TTTableOfGoodsRegistration AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|		-TableTypesOfStocks_.Count AS Count
	|	FROM
	|		TTInventoryTypesRegistration AS TableTypesOfStocks_
	|
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.Purpose,
	|	TableOfGoods.ItemsLocationAttributes
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

// Procedure for filling in the table part "types of document inventory".
//
// Parameters:
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager		= TemporaryDocumentDataTables();
	RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	InventoryTypesWriteOffOverfilled = False;
	InventoryOwnerAttributesRegistrationHasBeenOverfilled = False;
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDebitingDocumentDetails(TempTablesManager)
		Or CheckChangesInDebitedItems(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryOwnerAttributesConsumption.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber", "Count, QuantityByGBRN");
		
		SearchParameters = New Structure("Count", 0);
		ArrayOfRowsToDelete_1 = InventoryOwnerAttributesConsumption.FindRows(SearchParameters);
		
		For Each TableRow In ArrayOfRowsToDelete_1 Do
			InventoryOwnerAttributesConsumption.Delete(TableRow);
		EndDo;
		
		InventoryTypesWriteOffOverfilled = True;
		
	EndIf;
	
	If Not Posted
		Or RefillInventoryKinds
		Or InventoryTypesWriteOffOverfilled
		Or CheckChangesToDocumentDetailsRegistration(TempTablesManager)
		Or CheckChangesToRegisteredProducts(TempTablesManager) Then
		
		InventoryOwnerAttributesGoodsReceipt.Clear();
		
		If BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
			FillPropertyValues(InventoryOwnerAttributesGoodsReceipt.Add(), ThisObject);
		ElsIf BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
			For Each LineProducts_ In Goods Do
				FillPropertyValues(InventoryOwnerAttributesGoodsReceipt.Add(), LineProducts_);
			EndDo;
		EndIf;
		
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, InventoryOwnerAttributesGoodsReceipt);
		
		DistributeCCDNumbers(Cancel);
		InventoryOwnerAttributesRegistrationHasBeenOverfilled = True;
	EndIf;
	If Not Cancel
		And Not AdditionalProperties.Property("IgnoreResidueControlErrors")
		And SubjectToExcise
		And (InventoryTypesWriteOffOverfilled
			Or InventoryOwnerAttributesRegistrationHasBeenOverfilled) Then
		
		CheckQuantityOfExciseSet(Cancel);
		
	EndIf;
EndProcedure

Procedure DistributeCCDNumbers(Cancel) Export
	
	CheckParameters = AccountingForTraceableGoodsLocalization.ParametersForCheckingTraceableCCDNumbers();
	CheckParameters.TSName = "InventoryOwnerAttributesConsumption";
	AccountingForTraceableGoodsLocalization.CheckCorrectnessOfTraceableCCDNumbers(ThisObject, Cancel, CheckParameters);
	
	If Cancel Then
		Return;
	EndIf;
	
	TypesOfStocksForCreatingCompositeCCDNumbers = InventoryOwnerAttributesConsumption.Unload();
	
	If TypesOfStocksForCreatingCompositeCCDNumbers.Count() > 0 Then
		
		ThisIsBuild = BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents;
		TypesOfGTDRoomsInTable = PurchasesServer.TypesOfGTDRoomsInTable(TypesOfStocksForCreatingCompositeCCDNumbers);
		TraceableKit =
			Common.ObjectAttributeValue(Products, "TracedGoods")
			And AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date);
		ThereAreTraceableComponents = 0;
		
		If Not ThisIsBuild
			And TraceableKit Then
			
			Components = Goods.UnloadColumn("Products");
			Components = CommonClientServer.CollapseArray(Components);
			
			ComponentData = Common.ObjectsAttributeValue(Components, "TracedGoods");
			
			For Each KeyAndValue In ComponentData Do
				If KeyAndValue.Value Then
					ThereAreTraceableComponents = True;
					
					Break;
				EndIf;
			EndDo;
			
		EndIf;
		
		If ThisIsBuild
			And TraceableKit
			And TypesOfGTDRoomsInTable.NumberOfTraceableCCDNumbers
				+ TypesOfGTDRoomsInTable.NumberOfCompositeCCDNumbers > 1 Then
			DistributeCCDTraceableAssemblyNumbers(Cancel);
		ElsIf ThisIsBuild
			And TraceableKit
			And TypesOfGTDRoomsInTable.NumberOfCompositeCCDNumbers = 1
			And TypesOfGTDRoomsInTable.NumberOfTraceableCCDNumbers = 0 Then
			DistributeCCDNumbersTraceableToTransfer();
		ElsIf ThisIsBuild
			And TraceableKit
			And TypesOfGTDRoomsInTable.NumberOfCompositeCCDNumbers = 0
			And TypesOfGTDRoomsInTable.NumberOfTraceableCCDNumbers = 1 Then
			DistributeCCDTraceableAssemblyNumbers(Cancel);
		ElsIf Not ThisIsBuild
			And TraceableKit
			And ThereAreTraceableComponents
			And TypesOfGTDRoomsInTable.NumberOfTraceableCCDNumbers = 1
			And TypesOfGTDRoomsInTable.NumberOfCompositeCCDNumbers = 0 Then
			DistributeCCDNumbersTraceableToTransfer();
		ElsIf Not ThisIsBuild
			And ThereAreTraceableComponents
			And TypesOfGTDRoomsInTable.ThereIsCompositeCCDNumber Then
			DistributeCCDTraceableDisassemblyNumbers(Cancel);
		ElsIf TraceableKit
			And Not ThereAreTraceableComponents Then
			MessageText = NStr("vi = 'Không có thành phần chi tiết được truy xuất theo số đăng ký lô hàng với bộ sản phẩm được truy xuất.
				|Sẽ ghi giảm bộ sản phẩm được truy xuất.';
				|ru = 'Отсутствуют прослеживаемые по РНПТ комплектующие при прослеживаемом комплекте.
				|Будет произведено выбытие прослеживаемого комплекта.';
				|en = 'There are no RNPT-traceable components in a traceable kit.
				|Traceable kit will be disposed.'; fa = 'There are no RNPT-traceable components in a traceable kit.
				|Traceable kit will be disposed.';
				|it = 'Отсутствуют прослеживаемые по РНПТ комплектующие при прослеживаемом комплекте.
				|Будет произведено выбытие прослеживаемого комплекта.';
				|pl = 'There are no RNPT-traceable components in a traceable kit.
				|Traceable kit will be disposed.';
				|tr = 'Отсутствуют прослеживаемые по РНПТ комплектующие при прослеживаемом комплекте.
				|Будет произведено выбытие прослеживаемого комплекта.'");
			// The refusal is not missed in this case, since the exit scenario of the traceable kit is possible.
			// The message is intended to simply alert the user.
			Common.MessageToUser(MessageText);
		ElsIf Not TraceableKit
			And TypesOfGTDRoomsInTable.ThereIsTraceableCCDNumber Then
			MessageText = NStr("vi = 'Có thành phần chi tiết được truy xuất theo số đăng ký lô hàng với bộ sản phẩm chưa được truy xuất.
			|Sẽ ghi giảm thành phần chi tiết được truy xuất.';
			|ru = 'Имеется прослеживаемая по РНПТ комплектующая при непрослеживаемом комплекте.
			|Будет произведено выбытие прослеживаемых комплектующих.';
			|en = 'There is an RNPT-traceable component in an untraceable set.
			|Traceable components will be disposed.'; fa = 'There is an RNPT-traceable component in an untraceable set.
			|Traceable components will be disposed.';
			|it = 'Имеется прослеживаемая по РНПТ комплектующая при непрослеживаемом комплекте.
			|Будет произведено выбытие прослеживаемых комплектующих.';
			|pl = 'There is an RNPT-traceable component in an untraceable set.
			|Traceable components will be disposed.';
			|tr = 'İzlenebilir olmayan sette bir Lot Kayıt Numarası izlenebilir bileşeni mevcut.
			|İzlenebilir bileşenler imha edilecektir.'");
			// The failure is not missed in this case, since the scenario of the disposal of traceable components is possible.
			// The message is intended to simply alert the user.
			Common.MessageToUser(MessageText);
			
			DistributeCCDNumbersThatAreNotTraceable();
		Else
			DistributeCCDNumbersThatAreNotTraceable();
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure DistributeCCDNumbersTraceableToTransfer()
	
	Query = New Query();
	Query.Text = 
	// 0.
	"SELECT
	|	CAST(InventoryOwnerAttributesConsumption.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
	|	CAST(InventoryOwnerAttributesConsumption.CCDNumber AS Catalog.CCDNumbers) AS CCDNumber,
	|	CAST(InventoryOwnerAttributesConsumption.InventoryOwnerAttribute AS Catalog.InventoryKinds) AS InventoryOwnerAttribute,
	|	CAST(InventoryOwnerAttributesConsumption.QuantityByGBRN AS NUMBER(23, 11)) AS QuantityByGBRN,
	|	InventoryOwnerAttributesConsumption.RowID
	|INTO TTInventoryTypesWriteOff
	|FROM
	|	&InventoryOwnerAttributesConsumption AS InventoryOwnerAttributesConsumption
	|;
	|
	// 1.
	|SELECT
	|	CAST(InventoryOwnerAttributesGoodsReceipt.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
	|	CAST(InventoryOwnerAttributesGoodsReceipt.InventoryOwnerAttribute AS Catalog.InventoryKinds) AS InventoryOwnerAttribute
	|INTO TTInventoryTypesRegistration
	|FROM
	|	&InventoryOwnerAttributesGoodsReceipt AS InventoryOwnerAttributesGoodsReceipt
	|;
	|
	// 2.
	|SELECT DISTINCT
	|	WriteOff.ItemsLocationAttributes,
	|	WriteOff.CCDNumber,
	|	WriteOff.QuantityByGBRN,
	|	WriteOff.InventoryOwnerAttribute,
	|	WriteOff.RowID
	|FROM
	|	TTInventoryTypesWriteOff AS WriteOff
	|WHERE
	|	WriteOff.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber)
	|	OR WriteOff.CCDNumber.CCDNumberType = VALUE(Enum.CCDNumberTypes.KitRNPT)
	|;
	|
	// 3.
	|SELECT DISTINCT
	|	RecordingAsReceived.ItemsLocationAttributes,
	|	RecordingAsReceived.InventoryOwnerAttribute
	|FROM
	|	TTInventoryTypesRegistration AS RecordingAsReceived
	|WHERE
	|	RecordingAsReceived.ItemsLocationAttributes.Products.TracedGoods
	|";
	
	Query.SetParameter("InventoryOwnerAttributesConsumption", InventoryOwnerAttributesConsumption.Unload());
	Query.SetParameter("InventoryOwnerAttributesGoodsReceipt", InventoryOwnerAttributesGoodsReceipt.Unload());
	
	Result = Query.ExecuteBatch();
	ToWriteOff = Result[2].Unload();
	ToRecordAsReceived = Result[3].Unload();
	
	FoundLoggingLines = New Array();
	RowFilter = New Structure("ItemsLocationAttributes, InventoryOwnerAttribute");
	For Each String In ToRecordAsReceived Do
		FillPropertyValues(RowFilter, String);
		LoginStrings = InventoryOwnerAttributesGoodsReceipt.FindRows(RowFilter);
		CommonClientServer.SupplementArray(FoundLoggingLines, LoginStrings);
	EndDo;
	
	GTDCNumberForDebiting = ToWriteOff[0].CCDNumber; // A single CCD number with a traceable item is expected.
	AmountOfRNPTKWriteOff = ToWriteOff.Total("QuantityByGBRN");
	
	NumberOfLoginLines = FoundLoggingLines.Count(); // In the case of assembly, one line is always entered, during disassembly there may be several.
	
	ShareToDistribution = AmountOfRNPTKWriteOff / NumberOfLoginLines;
	BalanceOfDistribution = AmountOfRNPTKWriteOff - (ShareToDistribution * NumberOfLoginLines);
	
	For Each LineToLogIn In FoundLoggingLines Do
		LineToLogIn = LineToLogIn;
		LineToLogIn.CCDNumber = GTDCNumberForDebiting;
		LineToLogIn.QuantityByGBRN = ShareToDistribution;
	EndDo;
	LineToLogIn.QuantityByGBRN = LineToLogIn.QuantityByGBRN + BalanceOfDistribution;
	
EndProcedure

Procedure DistributeCCDTraceableAssemblyNumbers(Cancel)
	
	ColumnsNames = "ItemsLocationAttributes, CCDNumber, Count, QuantityByGBRN";
	TableOfSettlementCapacity = PurchasesServer.GetTraceableCCDNumbers(InventoryOwnerAttributesConsumption.Unload(, ColumnsNames));
	
	CreationParameters = PurchasesServer.ParametersForSearchingOrCreatingCompositeTraceableSets();
	CreationParameters.ExtractProductFromObjectInColumn = TableOfSettlementCapacity.Columns.ItemsLocationAttributes.Name;
	CreationParameters.ExtractCharacteristicFromObjectInColumn = TableOfSettlementCapacity.Columns.ItemsLocationAttributes.Name;
	CreationParameters.ExtractBatchFromObjectInColumn = TableOfSettlementCapacity.Columns.ItemsLocationAttributes.Name;
	CreationParameters.ItemOfHeader = Products;
	CreationParameters.CharacteristicsOfCap = Characteristic;
	CreationParameters.CapsBatch = Series;
	
	CompositeTraceableCCDNumbers = PurchasesServer.FindOrCreateCompositeTraceableCCDNumbers(TableOfSettlementCapacity,
		Count,
		Date,
		Cancel,
		CreationParameters);
	
	// When assembling into inventory types, one line corresponding to the set is selected (one to one).
	StockLogging = InventoryOwnerAttributesGoodsReceipt[0];
	
	QuantityByGBRN = StockLogging.QuantityByGBRN;
	If QuantityByGBRN = 0 Then
		QuantityByGBRN = StockLogging.Count;
	EndIf;
	
	If CompositeTraceableCCDNumbers.ResidualCompositeNumberOfCCD = Undefined Then
		StockLogging.CCDNumber = CompositeTraceableCCDNumbers.MainCompositeNumberOfCCD;
		StockLogging.QuantityByGBRN = QuantityByGBRN;
	Else
		RNPTUnit = StockLogging.Count / QuantityByGBRN;
		StockLogging.CCDNumber = CompositeTraceableCCDNumbers.MainCompositeNumberOfCCD;
		StockLogging.Count = StockLogging.Count - 1;
		StockLogging.QuantityByGBRN = QuantityByGBRN - RNPTUnit;
		
		NewRow = InventoryOwnerAttributesGoodsReceipt.Add();
		FillPropertyValues(NewRow, StockLogging);
		NewRow.CCDNumber = CompositeTraceableCCDNumbers.ResidualCompositeNumberOfCCD;
		NewRow.Count = 1;
		NewRow.QuantityByGBRN = RNPTUnit;
	EndIf;
	
EndProcedure

Procedure DistributeCCDTraceableDisassemblyNumbers(Cancel)
	
	GoodsToWriteOff = InventoryOwnerAttributesConsumption.Unload();
	GoodsToRecordAsReceived = InventoryOwnerAttributesGoodsReceipt.Unload();
	Result = PurchasesServer.DisassembleCompositeTraceableCCDNumbers(GoodsToWriteOff,
		GoodsToRecordAsReceived,
		Undefined,
		Undefined,
		Cancel);
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	DocumentTable.InventoryOwnerAttribute,
	|	DocumentTable.CCDNumber,
	|	DocumentTable.QuantityByGBRN,
	|	DocumentTable.Count,
	|	DocumentTable.ItemsLocationAttributes
	|INTO TTDocumentTable
	|FROM
	|	&DocumentTable AS DocumentTable
	|INDEX BY
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute
	|;
	|
	|SELECT
	|	DistributionTable_1.InventoryOwnerAttribute,
	|	DistributionTable_1.CCDNumber,
	|	DistributionTable_1.QuantityByGBRN,
	|	DistributionTable_1.Count,
	|	DistributionTable_1.ItemsLocationAttributes
	|INTO TTDistributionTable
	|FROM
	|	&DistributionTable_1 AS DistributionTable_1
	|INDEX BY
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute
	|
	|;
	|SELECT
	|	DocumentTable.InventoryOwnerAttribute,
	|	DocumentTable.CCDNumber,
	|	DocumentTable.QuantityByGBRN,
	|	DocumentTable.Count,
	|	DocumentTable.ItemsLocationAttributes
	|FROM
	|	TTDocumentTable AS DocumentTable
	|		LEFT JOIN TTDistributionTable AS DistributionTable_1
	|		ON DocumentTable.ItemsLocationAttributes = DistributionTable_1.ItemsLocationAttributes
	|		AND DocumentTable.InventoryOwnerAttribute = DistributionTable_1.InventoryOwnerAttribute
	|WHERE
	|	DistributionTable_1.ItemsLocationAttributes IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	DistributionTable_1.InventoryOwnerAttribute,
	|	DistributionTable_1.CCDNumber,
	|	DistributionTable_1.QuantityByGBRN,
	|	DistributionTable_1.Count,
	|	DistributionTable_1.ItemsLocationAttributes
	|FROM
	|	TTDistributionTable AS DistributionTable_1";
	
	Query.SetParameter("DocumentTable", GoodsToRecordAsReceived);
	Query.SetParameter("DistributionTable_1", Result);
	
	ProductsToBeRegisteredDistributed = Query.Execute().Unload();
	InventoryOwnerAttributesGoodsReceipt.Load(ProductsToBeRegisteredDistributed);
	
EndProcedure

Procedure DistributeCCDNumbersThatAreNotTraceable()
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	&UseTraceableImportedGoodsAccounting
	|	AND BEGINOFPERIOD(&Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|	AND ISNULL(CAST(&Products AS Catalog.Products).TracedGoods, FALSE) AS TrackingOfTraceableGoodsIsUsed";
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	Query.SetParameter("Products", Products);
	Query.SetParameter("Date", Date);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	DistributeOnlyToTraceableGoods = Selection.TrackingOfTraceableGoodsIsUsed;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ItemsLocationAttributes.Ref AS DimensionKey,
	|	CASE
	|		WHEN ItemsLocationAttributes.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Unit_,
	|	ISNULL(ItemsLocationAttributes.Products.KeepRecordsByCCD, FALSE) AS CCDAccounting,
	|	ISNULL(ItemsLocationAttributes.Products.TracedGoods, FALSE) AS AccountingForRNPT
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS ItemsLocationAttributes
	|WHERE
	|	ItemsLocationAttributes.Ref IN(&DimensionKeys)";
	
	Query.SetParameter("DimensionKeys", InventoryOwnerAttributesGoodsReceipt.UnloadColumn("ItemsLocationAttributes"));
	
	Selection = Query.Execute().Select();
	AccountingAnalystData = New Map;
	
	While Selection.Next() Do
		AccountingAnalystData.Insert(Selection.DimensionKey,
									New Structure("CCDAccounting, AccountingForRNPT, Unit_",
													Selection.CCDAccounting, Selection.AccountingForRNPT, Selection.Unit_));
	EndDo;
	
	Query.Text =
	"SELECT
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.Count,
	|	InventoryKinds.QuantityByGBRN,
	|	InventoryKinds.CCDNumber
	|INTO TTTypesOfStocks
	|FROM
	|	&InventoryKinds AS InventoryKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.Count,
	|	InventoryKinds.QuantityByGBRN,
	|	InventoryKinds.CCDNumber
	|FROM
	|	TTTypesOfStocks AS InventoryKinds";
	
	Query.SetParameter("InventoryKinds", InventoryOwnerAttributesConsumption);
	
	If BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		Query.Text = Query.Text + "
		|WHERE
		|	InventoryKinds.ItemsLocationAttributes.Products = &Products
		|	AND InventoryKinds.ItemsLocationAttributes.Characteristic = &Characteristic";
		Query.SetParameter("Products", ProductsOfMainComponent);
		Query.SetParameter("Characteristic", MainComponentCharacteristic);
	EndIf;
	
	WriteOffInventory = Query.Execute().Unload();
	
	IndexOf = InventoryOwnerAttributesGoodsReceipt.Count() - 1;
	
	While IndexOf >= 0 Do
		
		StockLogging = InventoryOwnerAttributesGoodsReceipt[IndexOf];
		AnalyticsData = AccountingAnalystData.Get(StockLogging.ItemsLocationAttributes);
		
		If Not AnalyticsData.CCDAccounting Then
			StockLogging.CCDNumber = Undefined;
			
			IndexOf = IndexOf - 1;
			
			Continue;
		EndIf;
		
		If DistributeOnlyToTraceableGoods
			And Not AnalyticsData.AccountingForRNPT Then
			StockLogging.CCDNumber = Undefined;
			IndexOf = IndexOf - 1;
			Continue;
		EndIf;
		
		Digits				= ?(AnalyticsData.Unit_
										And Int(StockLogging.Count) = StockLogging.Count
										And Not DistributeOnlyToTraceableGoods,
									0,
									3);
		RemainsToAllocate	= StockLogging.Count;
		CountTotal			= WriteOffInventory.Total("Count");
		TotalQuantityAccordingToRNPT	= WriteOffInventory.Total("QuantityByGBRN");
		
		For Each InventoryWriteOff In WriteOffInventory Do
			
			StockLogging.Count		= Round(RemainsToAllocate * InventoryWriteOff.Count / CountTotal,
														Digits,
														1);
			If AnalyticsData.AccountingForRNPT Then
				StockLogging.QuantityByGBRN = InventoryWriteOff.QuantityByGBRN;
			EndIf;
			StockLogging.CCDNumber			= InventoryWriteOff.CCDNumber;
			
			RemainsToAllocate	= RemainsToAllocate - StockLogging.Count;
			CountTotal			= CountTotal - InventoryWriteOff.Count;
			TotalQuantityAccordingToRNPT	= TotalQuantityAccordingToRNPT - InventoryWriteOff.QuantityByGBRN;
			
			If RemainsToAllocate <> 0 Then
				FillPropertyValues(InventoryOwnerAttributesGoodsReceipt.Insert(IndexOf), StockLogging);
			Else
				Break;
			EndIf;
			
		EndDo;
		
		IndexOf = IndexOf - 1;
		
	EndDo;
EndProcedure

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.NameTSTypesOfStocks = "InventoryOwnerAttributesConsumption";
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	FillParameters.ReversedDocument = ReversedDocument;
	If Documents.AssemblyFromComponents.ExcisableGoodsAreUsed(ThisObject) Then
		FillParameters.PriorityOfSelectionOfExcisableInventory = True;
		
		FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
		FillParameters.SelectionOfStockTypes_.BusinessUnitProduction = BusinessUnitProduction;
	EndIf;
	Return FillParameters;
	
EndFunction
Procedure CheckCorrectnessOfExciseItemIndication(Cancel)
	
	If Cancel
		Or Not SubjectToExcise Then
		
		Return;
		
	EndIf;
	
	QueryTexts = New Array;
	
	PartOfTheRequestText =
	"SELECT
	|	&Products AS Products
	|INTO KitTable";
	QueryTexts.Add(PartOfTheRequestText);
	
	RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
	RequestTextParameters.ProductTableName_ = "KitTable";
	
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(, RequestTextParameters));
	
	PartOfTheRequestText =
	"SELECT
	|	TableOfGoods.Products AS Products,
	|	ISNULL(Category_Data.ExcisableGoods, FALSE) AS ExcisableGoods,
	|	ISNULL(Category_Data.ItemCategory, &EmptyCategory) AS ItemCategory
	|FROM
	|	KitTable AS TableOfGoods
	|		LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON TableOfGoods.Products = Category_Data.Products
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|DROP TTExciseCategoriesOfItems
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|INDEX BY
	|	Products";
	QueryTexts.Add(PartOfTheRequestText);
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems());
	
	PartOfTheRequestText =
	"SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	ISNULL(Category_Data.ItemCategory, &EmptyCategory) AS ItemCategory
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON TableOfGoods.Products = Category_Data.Products
	|WHERE
	|	ISNULL(Category_Data.ExcisableGoods, FALSE)";
	QueryTexts.Add(PartOfTheRequestText);
	
	EmptyCategory		= Catalogs.ExcisableGoodsCategories.EmptyRef();
	RegistrationCountry	= SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Date",				Date);
	Query.SetParameter("Country",				RegistrationCountry);
	Query.SetParameter("Products",		Products);
	Query.SetParameter("EmptyCategory",	EmptyCategory);
	Query.SetParameter("TableOfGoods",		Goods.Unload(, "LineNumber, Products"));
	Query.SetParameter("UseExcisableGoods",
								GetFunctionalOption("UseExcisableGoods"));
	
	QueryResult = Query.ExecuteBatch();
	
	KitData = QueryResult[2].Select();
	KitData.Next();
	
	ComponentData = QueryResult[QueryResult.UBound()].Unload();
	NumberOfComponents_ = ComponentData.Count();
	
	ThisIsBuild = BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents;
	
	If ThisIsBuild
		And KitData.ExcisableGoods
		And NumberOfComponents_ = 0 Then
		
		MessageText = NStr("vi = 'Trong danh sách ""Thành phần chi tiết"" không có thành phần chi tiết chịu thuế TTĐB. 
			|Để đóng bộ bộ sản phẩm chịu thuế TTĐB, cần chỉ ra ít nhất một thành phần chi tiết chịu thuế TTĐB với thể loại ""%1"".';
			|ru = 'В списке ""Комплектующие"" отсутствуют подакцизные комплектующие.
			|Для сборки подакцизного комплекта необходимо указать хотя бы одну подакцизную комплектующую с категорией ""%1"".';
			|en = 'The ""Components"" list does not include any excisable components.
			|To assemble an excisable kit, specify at least one excisable component with the ""%1"" category.'; fa = 'The ""Components"" list does not include any excisable components.
			|To assemble an excisable kit, specify at least one excisable component with the ""%1"" category.';
			|it = 'The ""Components"" list does not include any excisable components.
			|To assemble an excisable kit, specify at least one excisable component with the ""%1"" category.';
			|pl = 'The ""Components"" list does not include any excisable components.
			|To assemble an excisable kit, specify at least one excisable component with the ""%1"" category.';
			|tr = '""Ürün setleri"" listesinde vergiye tabi setler bulunmamaktadır.
			|Tüketim vergisine tabi bir setin montajı için, ""%1"" kategorisinde en az bir tüketim vergisine tabi ürün setinin belirtilmesi gerekmektedir.'");
		MessageText = StrTemplate(MessageText, KitData.ItemCategory);
		
		Common.MessageToUser(MessageText, ThisObject, , , Cancel);
		
	ElsIf Not (ThisIsBuild
		Or KitData.ExcisableGoods)
		And NumberOfComponents_ > 0 Then
		
		FieldName		= "Products";
		RowFilter	= New Structure(FieldName);
		
		MessageTemplate = NStr("vi = 'Trong dòng %1 danh sách ""Thành phần chi tiết"" có chỉ định thành phần chi tiết chịu thuế TTĐB.
			|Các mục như vậy không khả dụng, nếu đang tách bộ sản phẩm không chịu thuế TTĐB.';
			|ru = 'В строке %1 списка ""Комплектующие"" указана подакцизная комплектующая.
			|Такие позиции недопустимы, если выполняется разборка неподакцизного комплекта.';
			|en = 'In line %1 of the ""Components"" list, the excisable component is specified.
			|These items are invalid if the non-excisable kit is being disassembled.'; fa = 'In line %1 of the ""Components"" list, the excisable component is specified.
			|These items are invalid if the non-excisable kit is being disassembled.';
			|it = 'In line %1 of the ""Components"" list, the excisable component is specified.
			|These items are invalid if the non-excisable kit is being disassembled.';
			|pl = 'In line %1 of the ""Components"" list, the excisable component is specified.
			|These items are invalid if the non-excisable kit is being disassembled.';
			|tr = '""Ürün setleri"" listesinin %1 satırında, tüketim vergisine tabi ürün seti belirtildi.
			|Tüketim vergisine tabi olmayan bir ürün setinin sökülmesi durumunda bu tür öğelere izin verilmez.'");
		
		For Each ProductData_1 In ComponentData Do
			MessageText = StrTemplate(MessageTemplate, ProductData_1.LineNumber);
			Field = CommonClientServer.PathToTabularSection("Goods", ProductData_1.LineNumber, FieldName);
			Common.MessageToUser(MessageText, ThisObject, Field, , Cancel);
		EndDo;
		
	EndIf;
	
	If Cancel
		Or Not KitData.ExcisableGoods Then
		
		Return;
		
	EndIf;
	
	OperationText = ?(ThisIsBuild, NStr("vi = 'đóng bộ';
										|ru = 'сборка';
										|en = 'kitting'; fa = 'kitting';
										|it = 'kitting';
										|pl = 'kitting';
										|tr = 'montaj'"), NStr("vi = 'tách bộ';
																|ru = 'разборка';
																|en = 'reverse kitting'; fa = 'reverse kitting';
																|it = 'reverse kitting';
																|pl = 'reverse kitting';
																|tr = 'demontaj'"));
	
	If ValueIsFilled(KitData.ItemCategory) Then
		MessageTemplate = NStr("vi = 'Trong dòng %1 danh sách ""Thành phần chi tiết"" chỉ định thành phần chi tiết có thể loại chịu thuế TTĐB khác với thể loại của bộ sản phẩm ""%ItemCategory%"".
			|Các mục này không khả dụng, nếu đang thực hiện %Operation% bộ sản phẩm chịu thuế TTĐB.';
			|ru = 'В строке %1 списка ""Комплектующие"" указана комплектующая с подакцизной категорией отличной от категории комплекта ""%ItemCategory%"".
			|Такие позиции недопустимы, если выполняется %Operation% подакцизного комплекта.';
			|en = 'In line %1 of the ""Components"" list, the excisable component with an excisable category different from the category of the ""%ItemCategory%"" kit is specified.
			|These items are invalid if performed %Operation% of the excisable kit.'; fa = 'In line %1 of the ""Components"" list, the excisable component with an excisable category different from the category of the ""%ItemCategory%"" kit is specified.
			|These items are invalid if performed %Operation% of the excisable kit.';
			|it = 'In line %1 of the ""Components"" list, the excisable component with an excisable category different from the category of the ""%ItemCategory%"" kit is specified.
			|These items are invalid if performed %Operation% of the excisable kit.';
			|pl = 'In line %1 of the ""Components"" list, the excisable component with an excisable category different from the category of the ""%ItemCategory%"" kit is specified.
			|These items are invalid if performed %Operation% of the excisable kit.';
			|tr = '""Ürün setleri"" listesinin %1 satırında, ""%ItemCategory%"" kümesinin kategorisinden farklı bir tüketim vergisine tabi kategoriye sahip ürün seti belirtildi.
			|Tüketim vergisine tabi kümenin %Operation% kadarı gerçekleştiriliyorsa bu tür öğelere izin verilmemektedir.'");
		MessageTemplate = StrReplace(MessageTemplate, "%ItemCategory%", KitData.ItemCategory);
	Else
		MessageTemplate = NStr("vi = 'Trong dòng %1 danh sách ""Thành phần chi tiết"" có chỉ định thành phần chi tiết chịu thuế TTĐB.
			|Các mục như vậy không khả dụng, nếu thực hiện %Operation% đóng bộ sản phẩm chịu thuế TTĐB.';
			|ru = 'В строке %1 списка ""Комплектующие"" указана комплектующая с подакцизной категорией отличной от категории комплекта.
			|Такие позиции недопустимы, если выполняется %Operation% подакцизного комплекта.';
			|en = 'In line %1 of the ""Components"" list, the excisable component with an excisable category different from the kit category is specified.
			|These items are invalid if %Operation% of the excisable kit is performed.'; fa = 'In line %1 of the ""Components"" list, the excisable component with an excisable category different from the kit category is specified.
			|These items are invalid if %Operation% of the excisable kit is performed.';
			|it = 'In line %1 of the ""Components"" list, the excisable component with an excisable category different from the kit category is specified.
			|These items are invalid if %Operation% of the excisable kit is performed.';
			|pl = 'In line %1 of the ""Components"" list, the excisable component with an excisable category different from the kit category is specified.
			|These items are invalid if %Operation% of the excisable kit is performed.';
			|tr = '""Ürün setleri"" listesinin %1 satırında, küme kategorisinden farklı bir tüketim vergisine tabi kategoriye sahip ürün seti belirtildi.
			|Tüketim vergisine tabi kümenin %Operation% kadarı gerçekleştiriliyorsa bu tür öğelere izin verilmemektedir.'");
	EndIf;
	
	MessageTemplate = StrReplace(MessageTemplate, "%Operation%", OperationText);
	
	FieldName		= "Products";
	RowFilter	= New Structure(FieldName);
	
	For Each ProductData_1 In ComponentData Do
		If ProductData_1.ItemCategory = KitData.ItemCategory Then
			Continue;
		EndIf;
		MessageText = StrTemplate(MessageTemplate, ProductData_1.LineNumber);
		Field = CommonClientServer.PathToTabularSection("Goods", ProductData_1.LineNumber, FieldName);
		Common.MessageToUser(MessageText, ThisObject, Field, , Cancel);
	EndDo;
	
	If Not Cancel
		And Not ValueIsFilled(KitData.ItemCategory) Then
		
		OperationText			= ?(ThisIsBuild, NStr("vi = 'đóng bộ';
														|ru = 'собираемого';
														|en = 'assembled'; fa = 'مونتاژشده';
														|it = 'assembled';
														|pl = 'assembled';
														|tr = 'toplanan'"), NStr("vi = 'tách bộ';
																				|ru = 'разбираемого';
																				|en = 'disassembled'; fa = 'disassembled';
																				|it = 'disassembled';
																				|pl = 'disassembled';
																				|tr = 'sökülen'"));
		KitPresentation	= ProductsClientServer.ProductPresentation(Products, Characteristic);
		
		MessageText = NStr("vi = 'Chưa đặt thể loại đối với %1 bộ sản phẩm chịu thuế TTĐB ""%2"".';
							|ru = 'Не задана категория для %1 подакцизного комплекта ""%2"".';
							|en = 'Category for %1 of the ""%2"" excisable kit is not specified.'; fa = 'Category for %1 of the ""%2"" excisable kit is not specified.';
							|it = 'Category for %1 of the ""%2"" excisable kit is not specified.';
							|pl = 'Category for %1 of the ""%2"" excisable kit is not specified.';
							|tr = 'Tüketim vergisine tabi ""%2"" setinin %1 kapsamında kategori belirtilmedi.'");
		MessageText = StrTemplate(MessageText, OperationText, KitPresentation);
		
		Common.MessageToUser(MessageText, ThisObject, , , Cancel);
		
	EndIf;
	
EndProcedure

Procedure CheckQuantityOfExciseSet(Cancel)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.Count AS Count
	|INTO TTInventoryTypesRegistration
	|FROM
	|	&InventoryOwnerAttributesGoodsReceipt AS GoodsTable
	|
	|INDEX BY
	|	InventoryOwnerAttribute,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.Count AS Count
	|INTO TTInventoryTypesWriteOff
	|FROM
	|	&InventoryOwnerAttributesConsumption AS GoodsTable
	|
	|INDEX BY
	|	InventoryOwnerAttribute,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DimensionKeys.Products		AS Products,
	|	SUM(GoodsTable.Count)	AS Count
	|INTO InventoryOwnerAttributesGoodsReceipt
	|FROM
	|	TTInventoryTypesRegistration AS GoodsTable
	|		INNER JOIN Catalog.InventoryKinds AS CatalogInventoryKinds
	|		ON GoodsTable.InventoryOwnerAttribute = CatalogInventoryKinds.Ref
	|		
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON GoodsTable.ItemsLocationAttributes = DimensionKeys.Ref
	|WHERE
	|	CatalogInventoryKinds.SubjectToExcise
	|
	|GROUP BY
	|	DimensionKeys.Products
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DimensionKeys.Products		AS Products,
	|	SUM(GoodsTable.Count)	AS Count
	|INTO InventoryOwnerAttributesConsumption
	|FROM
	|	TTInventoryTypesWriteOff AS GoodsTable
	|		INNER JOIN Catalog.InventoryKinds AS CatalogInventoryKinds
	|		ON GoodsTable.InventoryOwnerAttribute = CatalogInventoryKinds.Ref
	|		
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON GoodsTable.ItemsLocationAttributes = DimensionKeys.Ref
	|WHERE
	|	CatalogInventoryKinds.SubjectToExcise
	|
	|GROUP BY
	|	DimensionKeys.Products
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductItemsCategories.Products			AS Products,
	|	ProductItemsCategories.ConversionFactor_	AS ConversionFactor_,
	|	ProductItemsCategories.ExcisableGoodsCategory AS ItemCategory
	|INTO TTExciseCategoriesOfItems
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(
	|			&Date,
	|			Country = &Country
	|			AND Products IN
	|				(SELECT DISTINCT
	|					TableOfGoods.Products AS Products
	|				FROM
	|					InventoryOwnerAttributesGoodsReceipt AS TableOfGoods
	|				
	|				UNION ALL
	|				
	|				SELECT DISTINCT
	|					TableOfGoods.Products AS Products
	|				FROM
	|					InventoryOwnerAttributesConsumption AS TableOfGoods)
	|		) AS ProductItemsCategories
	|
	|WHERE
	|	ProductItemsCategories.ExcisableGoods
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(GoodsTable.Count * Category_Data.ConversionFactor_) AS Count
	|FROM
	|	InventoryOwnerAttributesGoodsReceipt AS GoodsTable
	|		INNER JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON GoodsTable.Products = Category_Data.Products
	|
	|HAVING
	|	SUM(GoodsTable.Count * Category_Data.ConversionFactor_) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(GoodsTable.Count * Category_Data.ConversionFactor_) AS Count
	|FROM
	|	InventoryOwnerAttributesConsumption AS GoodsTable
	|		INNER JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON GoodsTable.Products = Category_Data.Products
	|
	|HAVING
	|	SUM(GoodsTable.Count * Category_Data.ConversionFactor_) > 0";
	
	UnloadedColumns = "InventoryOwnerAttribute, ItemsLocationAttributes, Count";
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	
	Query.SetParameter("Date",	Date);
	Query.SetParameter("Country",	RegistrationCountry);
	Query.SetParameter("InventoryOwnerAttributesConsumption",		InventoryOwnerAttributesConsumption.Unload(, UnloadedColumns));
	Query.SetParameter("InventoryOwnerAttributesGoodsReceipt",	InventoryOwnerAttributesGoodsReceipt.Unload(, UnloadedColumns));
	
	QueryResult = Query.ExecuteBatchWithIntermediateData();
	
	NumberOfDebits		= 0;
	EntriesCount	= 0;
	
	If Not QueryResult[QueryResult.UBound()].IsEmpty() Then
		WriteOffData = QueryResult[QueryResult.UBound()].Select();
		WriteOffData.Next();
		
		NumberOfDebits = WriteOffData.Count;
	EndIf;
	
	If Not QueryResult[QueryResult.UBound() - 1].IsEmpty() Then
		LoginData = QueryResult[QueryResult.UBound() - 1].Select();
		LoginData.Next();
		
		EntriesCount = LoginData.Count;
	EndIf;
	
	OperationText			= ?(BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents,
								NStr("vi = 'đóng bộ';
									|ru = 'собираемого';
									|en = 'assembled'; fa = 'مونتاژشده';
									|it = 'assembled';
									|pl = 'assembled';
									|tr = 'toplanan'"),
								NStr("vi = 'tách bộ';
									|ru = 'разбираемого';
									|en = 'disassembled'; fa = 'disassembled';
									|it = 'disassembled';
									|pl = 'disassembled';
									|tr = 'sökülen'"));
	KitPresentation	= ProductsClientServer.ProductPresentation(Products, Characteristic);
	
	If EntriesCount = 0
		And NumberOfDebits = EntriesCount Then
		
		MessageText = NStr("vi = 'Chưa đặt hệ số tính lại đối với %1 bộ sản phẩm chịu thuế TTĐB ""%2"".';
							|ru = 'Не задан коэффициент пересчета для %1 подакцизного комплекта ""%2"".';
							|en = 'Conversion ratio for %1 of the ""%2"" excisable kit is not specified.'; fa = 'Conversion ratio for %1 of the ""%2"" excisable kit is not specified.';
							|it = 'Conversion ratio for %1 of the ""%2"" excisable kit is not specified.';
							|pl = 'Conversion ratio for %1 of the ""%2"" excisable kit is not specified.';
							|tr = 'Tüketim vergisine tabi ""%2"" setinin %1 kapsamında dönüştürme oranı belirlenmedi.'");
		MessageText = StrTemplate(MessageText, OperationText, KitPresentation);
		
		Common.MessageToUser(MessageText, ThisObject, , , Cancel);
		
	ElsIf NumberOfDebits <> EntriesCount Then
		
		Category_Data = QueryResult[QueryResult.UBound() - 2].Unload();
		Category_Data.Indexes.Add("Products");
		
		RowFilter = New Structure("Products", Products);
		KitCategories = Category_Data.FindRows(RowFilter);
		
		ItemCategory = String(KitCategories[0].ItemCategory);
		
		MessageText = NStr("vi = 'Số lượng %1 bộ sản phẩm chịu thuế TTĐB ""%2"" không tương ứng với số lượng thành phần chi tiết chịu thuế TTĐB theo đơn vị tính của thể loại chịu thuế TTĐB ""%3"" theo bộ phận ""%4"".';
							|ru = 'Количество %1 подакцизного комплекта ""%2"" не соответствует количеству подакцизных комплектующих в единице измерения подакцизной категории ""%3"" по подразделению ""%4"".';
							|en = 'The %1 quantity of the ""%2"" excisable kit does not match the quantity of excisable components in the unit of measure of the ""%3"" excisable category for the ""%4"" business unit.'; fa = 'The %1 quantity of the ""%2"" excisable kit does not match the quantity of excisable components in the unit of measure of the ""%3"" excisable category for the ""%4"" business unit.';
							|it = 'The %1 quantity of the ""%2"" excisable kit does not match the quantity of excisable components in the unit of measure of the ""%3"" excisable category for the ""%4"" business unit.';
							|pl = 'The %1 quantity of the ""%2"" excisable kit does not match the quantity of excisable components in the unit of measure of the ""%3"" excisable category for the ""%4"" business unit.';
							|tr = 'Tüketim vergisine tabi ""%2"" setinin %1 miktarı, ""%4"" departmanı kapsamında ""%3"" kategorisinin ölçü birimindeki tüketim vergisine tabi ürün setlerinin miktarına karşılık gelmemektedir.'");
		MessageText = StrTemplate(MessageText, OperationText, KitPresentation, ItemCategory,
			BusinessUnitProduction);
		
		Common.MessageToUser(MessageText, ThisObject, , , Cancel);
		
	EndIf;
	
EndProcedure
#EndRegion

#EndRegion

#EndIf
#EndIf
