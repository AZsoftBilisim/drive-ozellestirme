////////////////////////////////////////////////////////////////////////////////
// The Assortment module contains procedures and functions for
// verifying the correctness of assortment change documents and setting assortment quotas,
// processing assortment registration in registers,
// processing user-entered data,
// and also contains a number of auxiliary functions and procedures.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.ProductRange);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.ProductMixQuotas);
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements to the slave control registers range.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ProductRange");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ProductMixQuotas");
	
EndProcedure

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsForCheckingCorrectnessOfFillingOutDocuments

// The function checks whether the requisite "Enablecheats"
// all prices in the table "Goods" document "Essentialisation"
// and the prices specified in the planning object of this document.
// If there are discrepancies, it displays an informational message
// Called BEFORE writing the corresponding document object.
//
// Parameters: 
//  DocumentObject - DocumentObject.ProductRangeChange
//
// Returns: 
//  Boolean - if the props "Price includes" all kinds of prices match, the Truth is returned, otherwise False.
//
Function TypesOfPricesChangesInAssortmentComplyWithRules(DocumentObject) Export
	ThatSRight=True;
	Query = New Query;
	QueryText = "
	               |SELECT
	               |	GoodsTable.LineNumber,
	               |	GoodsTable.PriceKind
				   |INTO GoodsTable
	               |FROM
	               |	&GoodsTable AS GoodsTable
				   |;
	               |SELECT
	               |	GoodsTable.LineNumber,
	               |	GoodsTable.PriceKind,
	               |	GoodsTable.PriceKind.Description AS TypeOfPricesName
	               |FROM
	               |	GoodsTable AS GoodsTable
	               |WHERE
	               |	GoodsTable.PriceKind.PriceIncludesVAT <> &PriceIncludesVAT
	               |	OR (NOT GoodsTable.PriceKind.UseWhileSellingToCustomers)";
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("GoodsTable", DocumentObject.Goods.Unload());
	ObjectAttributes = New Structure;
	ObjectAttributes.Insert("PriceIncludesVAT", "RetailPriceType.PriceIncludesVAT");
	PriceTypeData = Common.ObjectAttributesValues(DocumentObject.PlanningObject, ObjectAttributes);
	Query.SetParameter("PriceIncludesVAT", PriceTypeData.PriceIncludesVAT);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ThatSRight = False;
		MessageText = NStr("vi = 'Trong dòng %1đã chọn dạng giá %2 không đúng';
							|ru = 'В строке %1 выбран некорректный вид цен %2';
							|en = 'Incorrect price type %2 is selected in line %1'; fa = 'Incorrect price type %2 is selected in line %1';
							|it = 'Nella riga %1 è selezionato un tipo incorretto dei prezzi %2';
							|pl = 'W wierszu %1 został wybrany niepoprawny rodzaj ceny%2';
							|tr = '%1 satırında yanlış %2 fiyat türü seçildi'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
																				 Selection.LineNumber,
																				 Selection.TypeOfPricesName);
		CommonClientServer.MessageToUser(
			MessageText,
			DocumentObject,
			CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "PriceKind"),
			"Object",
			True);
	EndDo;
	
	Return ThatSRight;	
EndFunction

#EndRegion

// The function returns the value of the current assortment planning object, depending on the settings.
//
// Parameters:
//  VerificationObject  - CatalogRef.Warehouses, CatalogRef.StoreFormats - The warehouse or format for which
//                                                                                 the planning object is defined
//  OnDate  - Date - The date on which the current planning object is defined.
//
// Returns:
//   CatalogRef.StoreFormats, CatalogRef.Warehouses   - the current planning object, depending on the FO -
//   store format or warehouse-store.
//
Function PlanningObject(VerificationObject, Val OnDate = Undefined) Export 
	
	If Not ValueIsFilled(OnDate) Then
		OnDate = CurrentSessionDate();
	EndIf;
	
	If TypeOf(VerificationObject) = Type("CatalogRef.Warehouses") And GetFunctionalOption("UseStoreFormats") Then
		
		PlanningObject = InformationRegisters.HistoryOfStoreFormatChange.CurFormat(VerificationObject, OnDate);
	Else
		
		PlanningObject = VerificationObject;
		
	EndIf;
	
	Return PlanningObject;

EndFunction
 
#Region OtherProceduresAndFunctions_

// The procedure checks the stage of the document " changing the Assortment"
// Called when processing the filling in of the document "setting prices " based on" changing the Assortment "
// if the document transfers goods to the stage" prohibited purchases and Sales"
// , an exception is forcibly called and the corresponding error text is generated.
// 
// Parameters: 
// 		DocumentBasis - DocumentRef.ProductRangeChange
Procedure CheckNeedToSetPricesBasedOn(DocumentBasis) Export
	If Common.ObjectAttributeValue(DocumentBasis, "Phase") = Enums.ProductRangePhases.SalesAndPurchasesAreProhibited Then
			
			ErrorText = NStr("vi = 'Chứng từ %1 cấm cả mua và bán. %2 Không thể đặt bảng giá trên cơ sở chứng từ này.';
							|ru = 'Документ %1 запрещает и закупки, и продажи.%2Установка цен на основании такого документа невозможна.';
							|en = 'The %1 document prohibits both purchases and sales.%2 Pricing based on such a document is not available.'; fa = 'The %1 document prohibits both purchases and sales.%2 Pricing based on such a document is not available.';
							|it = 'Il documento %1 non permette nè gli acquisti, nè le vendite.%2L''impostazione dei pressi sulla base di questo documento non è possibile.';
							|pl = 'Dokument %1 zabrania i zakupy, i sprzedaż. %2Ustawienie ceny na podstawie takiego dokumentu jest niemożliwe.';
							|tr = '%1 belgesi hem satın alımları hem de satışları yasaklamaktadır.%2Bu belge temelinde fiyatlandırma mümkün değildir.'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, DocumentBasis, Chars.LF);
			
			Raise ErrorText;
			
	EndIf;
EndProcedure

// The function gets tables of products and types of prices contained in the table part of the document "changing Assortment"
// is called when entering the price setting document based on changes in the assortment.
//
// Parameters:
//  DocumentBasis - DocumentRef.ProductRangeChange
//
// Returns:
//  Array - the result of executing a batch of requests.
//
Function ResultOfPackageTypesOfPricesAndProductsForInstallationByAssortment(DocumentBasis) Export
	
	Query=New Query;
	Query.Text =
	"SELECT ALLOWED
	|	ChangingProductRange.Products AS Products,
	|	ChangingProductRange.PriceKind AS PriceKind
	|FROM
	|	Document.ProductRangeChange.Goods AS ChangingProductRange
	|WHERE
	|	ChangingProductRange.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	ChangingProductRange.PriceKind AS PriceKind
	|FROM
	|	Document.ProductRangeChange.Goods AS ChangingProductRange
	|WHERE
	|	ChangingProductRange.Ref = &DocumentBasis";
	Query.SetParameter("DocumentBasis",DocumentBasis);
	
	PackageResult=Query.ExecuteBatch();
	
	Return PackageResult;
	
EndFunction

// The function returns the attribute for monitoring the assortment by the history of changes
//
// Parameters:
//  Warehouse  - CatalogRef.Warehouses - Warehouse / store for which assortment control is checked
//  OnDate  - Date - The date on which the product range control is checked.
//
// Returns:
//   Boolean   - True if the assortment is controlled in the warehouse and False if not.
//
Function ControlProductRange(Val Warehouse, Val OnDate = Undefined) Export 
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(OnDate) Then
		OnDate = CurrentSessionDate();
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	HistoryOfChangesToStoreFormatsCrossSection.ControlProductRange
	|FROM
	|	InformationRegister.HistoryOfStoreFormatChange.SliceLast(&OnDate, Warehouse = &Warehouse) AS HistoryOfChangesToStoreFormatsCrossSection";
	
	Query.SetParameter("OnDate", OnDate);
	Query.SetParameter("Warehouse", Warehouse);

	QueryResult = Query.Execute();

	SelectionDetailRecords = QueryResult.Select();

	If SelectionDetailRecords.Next() Then
		
		Return SelectionDetailRecords.ControlProductRange;
		
	EndIf;
	
	Return False;

EndFunction 
 
// The function returns the attribute for monitoring the assortment by the history of changes
//
// Parameters:
//  Warehouse  - CatalogRef.Warehouses - Warehouse / store for which assortment control is checked
//  OnDate  - Date - The date on which the product range control is checked.
//
// Returns:
//   Boolean   - True if the assortment is controlled in the warehouse and False if not.
//
Function StoreFormatByWarehouse(Val Warehouse, Val OnDate = Undefined) Export 
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(OnDate) Then
		OnDate = CurrentSessionDate();
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	HistoryOfChangesToStoreFormatsCrossSection.StoreFormat
	|FROM
	|	InformationRegister.HistoryOfStoreFormatChange.SliceLast(&OnDate, Warehouse = &Warehouse) AS
	|		HistoryOfChangesToStoreFormatsCrossSection
	|WHERE
	|	HistoryOfChangesToStoreFormatsCrossSection.StoreFormat <> VALUE(Catalog.StoreFormats.EmptyRef)";
	
	Query.SetParameter("OnDate", OnDate);
	Query.SetParameter("Warehouse", Warehouse);

	QueryResult = Query.Execute();

	SelectionDetailRecords = QueryResult.Select();

	If SelectionDetailRecords.Next() Then
		
		Return SelectionDetailRecords.StoreFormat;
		
	EndIf;
	
	Return Warehouse;

EndFunction 

// The procedure checks whether products in the selection that are not included in the base are included in the store's assortment on the specified date
// 
// Parameters:
// 	Object - DocumentObject.TransferOrder - selection object
// 	       - DocumentObject.PurchaseOrder - selection object 
// 	PropsNameWarehouse - String - indicates the details of the warehouse whose assortment is being checked
// 	TableOfGoods - ValueTable - table of products added to the table part of the document that need to be checked.
Procedure CheckAssortmentOfTableOfSelectedProducts(Object, PropsNameWarehouse, TableOfGoods = Undefined) Export
	
	// Document object.The order to the supplier -  
	 
	SetPrivilegedMode(True);
	
	Store = Object[PropsNameWarehouse];
	Date = ?(ValueIsFilled(Object.RequestedDeliveryDate), Object.RequestedDeliveryDate, Object.Date);
	Date = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
	
	ControlProductRange = ProductRangeServerCached.ControlProductRange(Store, Date);
	
	If ControlProductRange Then
		Query = New Query;
		If TypeOf(TableOfGoods) = Type("ValueTable") Then
			QueryText = "
			|SELECT
			|	Goods.Products AS Products
			|INTO Goods
			|FROM
			|	&Goods AS Goods
			|;
			|
			|SELECT
			|	DocumentGoods.LineNumber AS LineNumber,
			|	DocumentGoods.Products AS Products
			|INTO DocumentGoods
			|FROM
			|	&DocumentGoods AS DocumentGoods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DocumentGoods.LineNumber AS LineNumber,
			|	DocumentGoods.Products AS Products,
			|	DocumentGoods.Products.Description AS NomenclatureName
			|FROM
			|	DocumentGoods AS DocumentGoods
			|		INNER JOIN Goods AS Goods
			|		ON DocumentGoods.Products = Goods.Products
			|
			|		LEFT JOIN InformationRegister.ProductRange.SliceLast(ENDOFPERIOD(&Period, DAY), PlanningObject = &PlanningObject) AS ProductRange
			|		ON DocumentGoods.Products = ProductRange.Products
			|
			|		LEFT JOIN InformationRegister.ProductRange.SliceLast(ENDOFPERIOD(&Period, DAY), PlanningObject = &PlanningObject AND Products IN (SELECT DISTINCT T.Ref.Owner AS Products FROM Catalog.ProductKitConfigurations.Goods AS T INNER JOIN DocumentGoods AS SD ON T.Products = SD.Products)) AS AssortmentSets
			|		ON DocumentGoods.Products = AssortmentSets.Products
			|WHERE
			|	ISNULL(AssortmentSets.PurchasesAreAllowed, FALSE) = FALSE AND ISNULL(ProductRange.PurchasesAreAllowed, FALSE) = FALSE
			|
			|ORDER BY
			|	LineNumber";
			Query.SetParameter("Goods", TableOfGoods);
		Else
			QueryText = "
			|SELECT
			|	DocumentGoods.LineNumber AS LineNumber,
			|	DocumentGoods.Products AS Products
			|INTO DocumentGoods
			|FROM
			|	&DocumentGoods AS DocumentGoods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DocumentGoods.LineNumber AS LineNumber,
			|	DocumentGoods.Products AS Products,
			|	DocumentGoods.Products.Description AS NomenclatureName
			|FROM
			|	DocumentGoods AS DocumentGoods
			|		LEFT JOIN InformationRegister.ProductRange.SliceLast(ENDOFPERIOD(&Period, DAY), PlanningObject = &PlanningObject) AS ProductRange
			|		ON DocumentGoods.Products = ProductRange.Products
			|
			|		LEFT JOIN InformationRegister.ProductRange.SliceLast(ENDOFPERIOD(&Period, DAY), PlanningObject = &PlanningObject AND Products IN (SELECT DISTINCT T.Ref.Owner AS Products FROM Catalog.ProductKitConfigurations.Goods AS T INNER JOIN DocumentGoods AS SD ON T.Products = SD.Products)) AS AssortmentSets
			|		ON DocumentGoods.Products = AssortmentSets.Products
			|			AND AssortmentSets.PurchasesAreAllowed
			|WHERE
			|	ISNULL(AssortmentSets.PurchasesAreAllowed, FALSE) = FALSE AND ISNULL(ProductRange.PurchasesAreAllowed, FALSE) = FALSE
			|
			|ORDER BY
			|	LineNumber";
			
		EndIf;
		Query.Text = QueryText;
		Query.SetParameter("DocumentGoods", Object.Goods.Unload());
		
		Query.SetParameter("Period", Date);
		PlanningObject = ProductRangeServer.PlanningObject(Store, Date);
		Query.SetParameter("PlanningObject", PlanningObject);
		
		Result=Query.Execute();
		Selection = Result.Select();
		While Selection.Next() Do
			MessageText = NStr("vi = 'Hàng hóa ""%1"" không nằm trong danh điểm hoặc bị cấm mua.';
								|ru = 'Товар ""%1"" не включен в ассортимент или запрещен к закупке.';
								|en = 'The ""%1"" item is not included in the product range or prohibited for purchase.'; fa = 'The ""%1"" item is not included in the product range or prohibited for purchase.';
								|it = 'The ""%1"" item is not included in the product range or prohibited for purchase.';
								|pl = 'The ""%1"" item is not included in the product range or prohibited for purchase.';
								|tr = '""%1"" ürünü ürün gamına dahil değil veya satın almasına izin verilmemektedir.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, Selection.NomenclatureName);
			CommonClientServer.MessageToUser(
				MessageText,
				Object.Ref,
				CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "Products"),
				"Object",
				False);
		EndDo;
	EndIf;
	
EndProcedure

// Returns an array of price types that are assigned to the planning object on the date
//
// Parameters:
//  PlanningObject - CatalogRef.Warehouses,CatalogRef.StoreFormats
//  Date			 - Date 
//  SelectionByResources	 - Structure
// 
// Returns:
//  Array - Types of prices by assortment.
//
Function TypesOfPricesByAssortment(PlanningObject, Val Date, SelectionByResources = Undefined) Export
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	PlanningObject = PlanningObject(PlanningObject, Date);
	
	Query = New Query;
	
	QueryText =
	"SELECT DISTINCT
	|	ProductRange.PriceKind AS PriceKind
	|FROM
	|	InformationRegister.ProductRange.SliceLast(&Date, PlanningObject = &PlanningObject) AS ProductRange
	|WHERE
	|	TRUE
	|	AND &SelectionByResources";
	Query.SetParameter("Date", Date);
	Query.SetParameter("PlanningObject", PlanningObject);
	
	
	If SelectionByResources <> Undefined Then
		SelectionByResourcesLine = "TRUE";
	Else
		SelectionByResourcesLine = "";
		For Each KeyValue In SelectionByResources Do
			SelectionByResourcesLine = SelectionByResourcesLine + "
			|	 ProductRange." + KeyValue.Key + " = &" +  KeyValue.Key;
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	QueryText = StrReplace(QueryText,"&SelectionByResources", SelectionByResourcesLine);
	
	Query.Text = QueryText;
	Return Query.Execute().Unload().UnloadColumn("PriceKind");
	
EndFunction

// The function gets the value of the sales price
// according to the price type specified in the Assortment register
// for the item and warehouse on the specified date.
//
// Parameters: 
//		FilterParameters - Structure - Selection parameters for the price.
//
// Returns:
//  Number - Price
//
Function GetPriceByAssortment(FilterParameters) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	PlanningObject = ProductRangeServer.PlanningObject(FilterParameters.Warehouse, FilterParameters.Date);
	AssortmentStructure = StructureOfStateOfProductRangeInFormat(FilterParameters.Products, PlanningObject, FilterParameters.Date);
	
	PriceKind = AssortmentStructure.PriceKind;
	Query.SetParameter("PriceKind", PriceKind);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	For Each Parameter In FilterParameters Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	Query.Text =
	"
	|SELECT
	|	ISNULL(&QueryTextPackagingFactor1, 1)
	|	* ISNULL(ItemPricesCrossSectionOfTheLatest.Price,0)
	|	* CASE
	|		WHEN &Currency <> ItemPricesCrossSectionOfTheLatest.Currency
	|			THEN CASE
	|					WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|						AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN 
	|						(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|						/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END /ISNULL(&QueryTextPackagingFactor2,1) AS Price
	|FROM
	|	InformationRegister.ItemsPrices.SliceLast(ENDOFPERIOD(&Date, DAY), 
	|				PriceKind = CAST(&PriceKind AS Catalog.TypesOfPrices)
	|				AND Products = CAST(&Products AS Catalog.Products)
	|				AND Characteristic = CAST(&Characteristic AS Catalog.ItemsCharacteristics)
	|) AS ItemPricesCrossSectionOfTheLatest
	|LEFT JOIN
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
	|ON 
	|	ItemPricesCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency
	|	
	|LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
	|	ON TRUE
	|";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure)",
		"CAST(&Products AS Catalog.Products)"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ItemPricesCrossSectionOfTheLatest.Package",
		"ItemPricesCrossSectionOfTheLatest.Products"));	
	
	Price = 0;
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Price = Selection.Price;
	EndIf;
	Return Price;
	
EndFunction

// The function gets the current values of the Inventory information register resources for the specified date 
// for the product and store format.
//
// Parameters:
//  Products - CatalogRef.Products
//  VerificationObject - CatalogRef.StoreFormats, CatalogRef.Warehouses - Warehouse or store format
//  OnDate - Date - The date on which the current planning object is defined.
//
// Returns:
//  Structure - similar to the selection of all resources from the register.
//
Function StructureOfStateOfProductRangeInFormat(Products, VerificationObject, Val OnDate) Export
	
	If Not ValueIsFilled(OnDate) Then
		OnDate = CurrentSessionDate();
	EndIf;
	
	Query=New Query("SELECT ALLOWED
	|	ProductRange.ProductRangeRole AS ProductRangeRole,
	|	ProductRange.PurchasesAreAllowed AS PurchasesAreAllowed,
	|	ProductRange.SalesAreAllowed AS SalesAreAllowed,
	|	ProductRange.SalesRank AS SalesRank,
	|	ProductRange.PriceKind AS PriceKind
	|FROM
	|	InformationRegister.ProductRange.SliceLast(
	|			ENDOFPERIOD(&OnDate, DAY),
	|			PlanningObject = &PlanningObject
	|				AND (Products = &Products OR Products IN (SELECT DISTINCT T.Ref.Owner AS Products FROM Catalog.ProductKitConfigurations.Goods AS T WHERE T.Products = &Products))) AS ProductRange
	|");
	Query.SetParameter("Products",Products);
	
	PlanningObject = ProductRangeServer.PlanningObject(VerificationObject, OnDate);
	Query.SetParameter("PlanningObject", PlanningObject);
	
	Query.SetParameter("OnDate",OnDate);
	PackageResult=Query.ExecuteBatch();
	LastItemIndex=PackageResult.Count()-1;
	QueryResult=PackageResult[LastItemIndex]; // QueryResult - 
	
	StructureOfStateOfAssortment=New Structure;
	StructureOfStateOfAssortment.Insert("ProductRangeRole", Enums.ProductRangeRoles.EmptyRef());
	StructureOfStateOfAssortment.Insert("PurchasesAreAllowed", False);
	StructureOfStateOfAssortment.Insert("SalesAreAllowed", False);
	StructureOfStateOfAssortment.Insert("PriceKind",          Catalogs.TypesOfPrices.EmptyRef());
	StructureOfStateOfAssortment.Insert("SalesRank",    Catalogs.SalesRanks.EmptyRef());
	
	Selection=QueryResult.Select();
	If Selection.Next() Then
		FillPropertyValues(StructureOfStateOfAssortment, Selection);
	EndIf;
	
	Return StructureOfStateOfAssortment;
	
EndFunction

// The function gets the current values of the inventory Quota information register resources for the specified date 
// for the store category, brand, and format.
//
// Parameters:
//  PlanningObject - CatalogRef.StoreFormats, CatalogRef.Warehouses - The object on which the derived quota
//  ProductCategory - CatalogRef.ProductCategories
//  Brand - CatalogRef.Brands
//  OnDate - Date - date and time
//
// Returns:
// Structure - similar to the selection of all resources from the register.
//
Function QuotaStructureByCategory(PlanningObject, ProductCategory, Brand, Val OnDate) Export
	
	If Not ValueIsFilled(OnDate) Then
		OnDate = CurrentSessionDate();
	EndIf;
	
	QuotaStructure=New Structure;
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MAX(K.Period) AS Period
	|INTO CurQuotas
	|FROM
	|	InformationRegister.ProductMixQuotas AS K
	|WHERE
	|	K.Period <= &OnDate
	|	AND K.PlanningObject = &PlanningObject
	|	AND K.ProductCategory = &ProductCategory
	|	AND K.Brand = &Brand
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Quotas.Quota AS Quota,
	|	Quotas.VariancePercentage AS VariancePercentage
	|FROM
	|	InformationRegister.ProductMixQuotas AS Quotas
	|		INNER JOIN CurQuotas AS CurQuotas
	|		ON Quotas.Period = CurQuotas.Period
	|WHERE
	|	Quotas.PlanningObject = &PlanningObject
	|	AND Quotas.ProductCategory = &ProductCategory
	|	AND Quotas.Brand = &Brand";
	
	Query.SetParameter("ProductCategory",ProductCategory);
	Query.SetParameter("PlanningObject",PlanningObject);
	Query.SetParameter("Brand",Brand);
	Query.SetParameter("OnDate",OnDate);
	
	QueryResult=Query.Execute();
	
	If QueryResult.IsEmpty() Then
		QuotaStructure.Insert("Quota", 0);
		QuotaStructure.Insert("VariancePercentage", 0);
	Else
		Selection=QueryResult.Select();
		Selection.Next();
		QuotaStructure.Insert("Quota", Selection.Quota);
		QuotaStructure.Insert("VariancePercentage", Selection.VariancePercentage);
	EndIf;
	Return QuotaStructure;
EndFunction

// If the use of selection by assortment is enabled in the SKD settings,
// the procedure sets the service parameter for using selection by assortment.
//
//	Parameters:
//		SettingsComposer - DataCompositionSettingsComposer - the linker settings SKD.
//		
Procedure EnableSelectionByVSKDAssortment(SettingsComposer) Export
	
	ParameterSelectionByAssortmentIsUsed  = DataCompositionClientServer.GetParameter(
		SettingsComposer.Settings, 
		"FilterByProductRangeIsUsed");
	
	If ParameterSelectionByAssortmentIsUsed = Undefined Then
		Return;
	EndIf;
	
	ParameterSelectionByAssortmentIsUsed.Value      = False;
	ParameterSelectionByAssortmentIsUsed.Use = False;
	
	If TypeOf(SettingsComposer) = Type("DataCompositionNestedObjectSettings") Then
	
		MainCircuitSettings = SettingsComposer.Settings;
	
	Else
	
		MainCircuitSettings = SettingsComposer.GetSettings();
	
	EndIf;
	
	FilterByProductRangeIsUsed = False;
	
	FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(MainCircuitSettings.Filter,"PlanningObject");
	For Each FilterElement In FilterItems1 Do
		If FilterElement.Use Then  
			FilterByProductRangeIsUsed = True;
			Break;
		EndIf;
	EndDo;
	
	FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(MainCircuitSettings.Filter,"ItemsCollection");
	For Each FilterElement In FilterItems1 Do
		If FilterElement.Use Then  
			FilterByProductRangeIsUsed = True;
			Break;
		EndIf;
	EndDo;
	
	If TypeOf(SettingsComposer) = Type("DataCompositionNestedObjectSettings") Then
	
		FixedSettings = SettingsComposer.Settings;
	
	Else
	
		FixedSettings = SettingsComposer.FixedSettings;
	
	EndIf;
	
	ParameterSelectionByAssortmentIsUsed = DataCompositionClientServer.GetParameter(
		FixedSettings, 
		"FilterByProductRangeIsUsed");
	
	ParameterSelectionByAssortmentIsUsed.Value = True;
	ParameterSelectionByAssortmentIsUsed.Use = FilterByProductRangeIsUsed;
	
EndProcedure

#EndRegion

#Region BatchProcessingOfTableParts

// Adds a request to the request package to get the data needed to get the sales price for the assortment.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
Procedure CompleteQueryTextAndFillInSalesPriceByProductRange(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInSalePriceByProductRange",
		StructureOfActions,
		CachedValues,
		ActionParameters) Then
		
		PlanningObject = PlanningObject(ActionParameters.Warehouse, ActionParameters.Date);
		
		ListOfRequests = QueryTextsForFillingInPricesBatchProcessing();
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
		QueryDetails.QueryOptions.Insert("PlanningObject", PlanningObject);
		QueryDetails.QueryOptions.Insert("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
		QueryDetails.QueryOptions.Insert("Currency", ActionParameters.Currency);
		QueryDetails.QueryOptions.Insert("Date", ActionParameters.Date);
		
	EndIf;
	
EndProcedure

// Adds a query to the query package to get the data needed to check the row assortment.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
Procedure CompleteQueryTextCheckProductRangeOfLine(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"CheckRowAssortment",
		StructureOfActions,
		CachedValues,
		ActionParameters) Then
		
		PlanningObject = PlanningObject(ActionParameters.Warehouse, ActionParameters.Date);
		
		ListOfRequests = QueryTextsForCheckingProductRangeBatchProcessing(ActionParameters.Ref);
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
		QueryDetails.QueryOptions.Insert("PlanningObject", PlanningObject);
		QueryDetails.QueryOptions.Insert("Warehouse", ActionParameters.Warehouse);
		QueryDetails.QueryOptions.Insert("Date", ActionParameters.Date);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region BatchProcessingOfTablePartsIsService

// Returns query texts for sales prices by assortment.
// 
// Returns:
// 	ValueList of String
//
Function QueryTextsForFillingInPricesBatchProcessing()
	
	Result = New ValueList();
	
	QueryText =
	"SELECT DISTINCT
	|	TTDataSource.Products AS Products,
	|	ISNULL(TableOfComponents.Ref.Owner, VALUE(Catalog.Products.EmptyRef)) AS KitOwner
	|INTO BatchProcessing_ProductRange_KitOwners
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN Catalog.ProductKitConfigurations.Goods AS TableOfComponents
	|		ON TTDataSource.Products = TableOfComponents.Products
	|
	|INDEX BY
	|	Products,
	|	KitOwner";
	
	Result.Add(QueryText, "BatchProcessing_ProductRange_KitOwners");
	
	QueryText =
	"SELECT
	|	OwnersTable.Products AS Products,
	|	MAX(ISNULL(TableSlice.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef))) AS PriceKind
	|INTO BatchProcessing_ProductRange_ProductRange
	|FROM
	|	BatchProcessing_ProductRange_KitOwners AS OwnersTable
	|		LEFT JOIN InformationRegister.ProductRange.SliceLast(ENDOFPERIOD(&Date, DAY),
	|			PlanningObject = &PlanningObject
	|		AND Products IN
	|			(SELECT
	|				OwnersTable.Products AS Products
	|			FROM
	|				BatchProcessing_ProductRange_KitOwners AS OwnersTable
	|
	|			UNION ALL
	|
	|			SELECT
	|				OwnersTable.KitOwner AS KitOwner
	|			FROM
	|				BatchProcessing_ProductRange_KitOwners AS OwnersTable)) AS TableSlice
	|		ON TableSlice.Products IN (OwnersTable.Products, OwnersTable.KitOwner)
	|GROUP BY
	|	OwnersTable.Products
	|
	|INDEX BY
	|	Products";
	
	Result.Add(QueryText, "BatchProcessing_ProductRange_ProductRange");
	
	QueryText =
	"SELECT
	|	TableSlice.Products AS Products,
	|	TableSlice.Characteristic AS Characteristic,
	|	TableSlice.PriceKind AS PriceKind,
	|	TableSlice.Currency AS Currency,
	|	TableSlice.Package AS Package,
	|	TableSlice.Price AS Price
	|INTO BatchProcessing_ProductRange_ItemsPrices
	|FROM
	|	InformationRegister.ItemsPrices.SliceLast(ENDOFPERIOD(&Date, DAY), (Products, Characteristic) IN
	|		(SELECT
	|			TTDataSource.Products AS Products,
	|			TTDataSource.Characteristic AS Characteristic
	|		FROM
	|			TTDataSource AS TTDataSource)) AS TableSlice
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	PriceKind";
	
	Result.Add(QueryText, "BatchProcessing_ProductRange_ItemsPrices");
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	MAX(ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) * CASE
	|		WHEN &Currency <> ItemPricesCrossSectionOfTheLatest.Currency
	|			THEN CASE
	|				WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|				AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator / (Currency_Rates.CourseNumerator *
	|						CurrencyRatesPrices.CourseDenominator)
	|				ELSE 0
	|			END
	|		ELSE 1
	|	END / ISNULL(&QueryTextPackagingFactor2, 1)) AS Price
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN BatchProcessing_ProductRange_ProductRange AS ProductRange
	|		ON TTDataSource.Products = ProductRange.Products
	|		LEFT JOIN BatchProcessing_ProductRange_ItemsPrices AS ItemPricesCrossSectionOfTheLatest
	|		ON TTDataSource.Products = ItemPricesCrossSectionOfTheLatest.Products
	|		AND TTDataSource.Characteristic = ItemPricesCrossSectionOfTheLatest.Characteristic
	|		AND ProductRange.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS
	|			CurrencyRatesPrices
	|		ON (ItemPricesCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency)
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency
	|		AND BaseCurrency = &BaseCurrency) AS Currency_Rates
	|		ON (TRUE)
	|GROUP BY
	|	TTDataSource.IdOfTTRow";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TTDataSource.Package",
			"TTDataSource.Products"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
	
	Result.Add(QueryText, "FillInSalePriceByProductRange");
	
	Return Result;
	
EndFunction

// Returns query texts for checking the assortment.
// 
// Returns:
// 	ValueList of String
//
Function QueryTextsForCheckingProductRangeBatchProcessing(DocumentRef)
	
	Result = New ValueList;
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	TTDataSource.Products AS Products,
	|	ISNULL(HistoryOfChange.ControlProductRange, FALSE) AS ControlProductRange,
	|	ISNULL(ProductRange.ProductRangeRole, VALUE(Enum.ProductRangeRoles.EmptyRef)) AS ProductRangeRole,
	|	ISNULL(ProductRange.PurchasesAreAllowed, FALSE) AS PurchasesAreAllowed,
	|	ISNULL(ProductRange.SalesAreAllowed, FALSE) AS SalesAreAllowed
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN InformationRegister.HistoryOfStoreFormatChange.SliceLast(&Date, Warehouse = &Warehouse) AS
	|			HistoryOfChange
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.ProductRange.SliceLast(ENDOFPERIOD(&Date, DAY),
	|			PlanningObject = &PlanningObject) AS ProductRange
	|		ON (TTDataSource.Products = ProductRange.Products
	|		OR TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Catalog.ProductKitConfigurations.Goods AS TableOfGoods
	|			WHERE
	|				TableOfGoods.Products = TTDataSource.Products))
	|WHERE
	|	TTDataSource.Products <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataSource.IdOfTTRow,
	|	&NameOfItemFieldOfSet,
	|	ISNULL(HistoryOfChange.ControlProductRange, FALSE),
	|	ISNULL(ProductRange.ProductRangeRole, VALUE(Enum.ProductRangeRoles.EmptyRef)),
	|	ISNULL(ProductRange.PurchasesAreAllowed, FALSE),
	|	ISNULL(ProductRange.SalesAreAllowed, FALSE)
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN InformationRegister.HistoryOfStoreFormatChange.SliceLast(&Date, Warehouse = &Warehouse) AS
	|			HistoryOfChange
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.ProductRange.SliceLast(ENDOFPERIOD(&Date, DAY),
	|			PlanningObject = &PlanningObject) AS ProductRange
	|		ON (&NameOfItemFieldOfSet = ProductRange.Products
	|		OR TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Catalog.ProductKitConfigurations.Goods AS TableOfGoods
	|			WHERE
	|				TableOfGoods.Products = &NameOfItemFieldOfSet))";
	
	ThereAreItemsOfSet = DocumentRef.Metadata().TabularSections.Goods.Attributes.Find("ProductsInSet") <> Undefined;
	If ThereAreItemsOfSet Then
		NameOfItemFieldOfSet = "TTDataSource.ProductsInSet";
	Else
		NameOfItemFieldOfSet = "NULL";
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"&NameOfItemFieldOfSet",
		NameOfItemFieldOfSet);
	
	Result.Add(QueryText, "CheckRowAssortment");
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

