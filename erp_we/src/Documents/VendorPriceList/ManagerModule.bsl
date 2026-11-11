#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("PricesAndDiscounts");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList, Structure - Data of the document for conducting
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.VendorPriceList") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		Query.SetParameter("Ref", DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextItemsPricesOfVendor(Query, QueryTexts, Registers);
		RequestTextDeliveryTerms(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command of creation of the document "Registration pricing vendor".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.VendorPriceList) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.VendorPriceList.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.VendorPriceList);
		CreateBasedOnCommand.WriteMode = "Post";

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Fills in the price registration of the supplier's item based on the receipt or order to the supplier.
//
// Parameters:
// 	Basis - DocumentRef.VendorInvoice, DocumentRef.PurchaseOrder - 
// 	DocumentObject - DocumentObject - 
//
Procedure FillInPriceRegistrationForPurchaseDocument(Basis, DocumentObject) Export
	
	TableName = Basis.Metadata().Name;
	
	QueryText =
	"SELECT
	|	DocumentPurchases.Date                         AS Date,
	|	DocumentPurchases.Currency                       AS Currency,
	|	DocumentPurchases.Partner                      AS Partner,
	|	DocumentPurchases.PriceIncludesVAT              AS PriceIncludesVAT,
	|	DocumentPurchases.Ref                       AS DocumentBasis,
	|	NOT DocumentPurchases.Posted                  AS ThereAreErrorsPosted,
	|	DocumentPurchases.RegisterVendorPrices AS RegisterVendorPrices
	|FROM
	|	Document.VendorInvoice AS DocumentPurchases
	|WHERE
	|	DocumentPurchases.Ref = &Ref
	|";
	QueryText = StrReplace(QueryText, "Document.VendorInvoice", "Document." + TableName);
	
	If TypeOf(Basis) = Type("DocumentRef.GoodsReceiptForStorage") Then
		QueryText = StrReplace(QueryText, "DocumentPurchases.PriceIncludesVAT", "UNDEFINED");
	EndIf;
	
	Query = New Query(QueryText);	
	Query.SetParameter("Ref", Basis);
	QueryResult = Query.Execute();
	HeaderSelection = QueryResult.Select();
	HeaderSelection.Next();
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.DocumentBasis,
		,
		HeaderSelection.ThereAreErrorsPosted,);
	ReportPriceRegistrationErrors(HeaderSelection.RegisterVendorPrices, HeaderSelection.DocumentBasis);
	FillPropertyValues(DocumentObject, HeaderSelection);
	
	QueryText = 
	"SELECT
	|	CurrencyRatesCut.Currency    AS Currency,
	|	CurrencyRatesCut.CourseNumerator AS CourseNumerator,
	|	CurrencyRatesCut.CourseDenominator AS CourseDenominator
	|INTO
	|	TemporaryTableCurrencyExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|				&Date,
	|				Currency=&Currency
	|					OR Currency IN (SELECT DISTINCT
	|										ISNULL(Goods.VendorPriceKind.Currency, VALUE(Catalog.Currencies.EmptyRef))
	|									FROM
	|										Document.VendorInvoice.Goods AS Goods
	|									WHERE Goods.Ref = &Ref)
	|					AND BaseCurrency = &BaseCurrency) AS CurrencyRatesCut
	|
	|INDEX BY
	|	Currency
	|;
	|SELECT
	|	Goods.PartnerProducts AS PartnerProducts,
	|	Goods.Products           AS Products,
	|	Goods.Characteristic         AS Characteristic,
	|	Goods.VendorPriceKind      AS VendorPriceKind,
	|	Goods.Package               AS Package,
	|	CAST(Goods.Price
	|				* CASE
	|					WHEN &PriceIncludesVAT = UNDEFINED
	|						THEN 1
	|					WHEN
	|						&PriceIncludesVAT 
	|							AND NOT ISNULL(Goods.VendorPriceKind.PriceIncludesVAT, FALSE)
	|					THEN
	|						CASE
	|							WHEN Goods.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|								THEN 1
	|							ELSE 100 / (100 + Goods.VATRate.Rate1)
	|						END
	|					WHEN
	|						NOT &PriceIncludesVAT
	|							AND ISNULL(Goods.VendorPriceKind.PriceIncludesVAT, FALSE)
	|						THEN (Goods.VATRate.Rate1 + 100) / 100
	|					ELSE
	|						1
	|					END
	|				* CASE
	|					WHEN
	|						&Currency <> ISNULL(Goods.VendorPriceKind.Currency, VALUE(Catalog.Currencies.EmptyRef))
	|					THEN
	|						CASE
	|							WHEN ISNULL(ExchangeRatesOfAgreement_.CourseDenominator, 0) > 0
	|								AND ISNULL(ExchangeRatesOfAgreement_.CourseNumerator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|							THEN 
	|								(Currency_Rates.CourseNumerator * ExchangeRatesOfAgreement_.CourseDenominator)
	|								/ (ExchangeRatesOfAgreement_.CourseNumerator * Currency_Rates.CourseDenominator)
	|							ELSE
	|								0
	|						END
	|					ELSE 
	|						1
	|				END AS NUMBER(31,2))
	|	AS Price
	|INTO
	|	Goods
	|FROM
	|	Document.VendorInvoice.Goods AS Goods
	|LEFT JOIN
	|	TemporaryTableCurrencyExchangeRates AS Currency_Rates
	|ON
	|	Currency_Rates.Currency = &Currency
	|LEFT JOIN
	|	TemporaryTableCurrencyExchangeRates AS ExchangeRatesOfAgreement_
	|ON
	|	ExchangeRatesOfAgreement_.Currency = ISNULL(Goods.VendorPriceKind.Currency, VALUE(Catalog.Currencies.EmptyRef))
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.VendorPriceKind <> VALUE(Catalog.VendorPriceTypes.EmptyRef)
	|;
	|SELECT
	|	Goods.Products                    AS Products,
	|	Goods.Characteristic                  AS Characteristic,
	|	Goods.VendorPriceKind               AS VendorPriceKind,
	|	AVG(
	|		Goods.Price / CASE
	|				WHEN
	|					Goods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN
	|					&QueryTextPackagingFactor
	|				ELSE
	|					1
	|			END
	|	) AS PricePerBaseUnit,
	|	COUNT(DISTINCT Goods.Package)  AS NumberOfDifferentPackages
	|INTO
	|	ProductsWithDifferentPackagingPrices
	|FROM
	|	Goods AS Goods
	|GROUP BY
	|	Products,
	|	Characteristic,
	|	VendorPriceKind
	|;
	|SELECT
	|	MAX(Goods.PartnerProducts) AS PartnerProducts,
	|	Goods.Products                     AS Products,
	|	Goods.Characteristic                   AS Characteristic,
	|	Goods.VendorPriceKind                AS VendorPriceKind,
	|	MIN(CASE
	|				WHEN
	|					ProductsWithDifferentPackagingPrices.NumberOfDifferentPackages > 1
	|				THEN
	|					VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				ELSE
	|					Goods.Package
	|				END
	|			) AS Package,
	|	AVG(CASE
	|				WHEN
	|					ProductsWithDifferentPackagingPrices.NumberOfDifferentPackages > 1
	|				THEN
	|					ProductsWithDifferentPackagingPrices.PricePerBaseUnit
	|				ELSE
	|					Goods.Price
	|				END
	|			) AS Price
	|FROM
	|	Goods AS Goods
	|LEFT JOIN
	|	ProductsWithDifferentPackagingPrices AS ProductsWithDifferentPackagingPrices
	|ON
	|	Goods.Products = ProductsWithDifferentPackagingPrices.Products
	|	AND Goods.Characteristic = ProductsWithDifferentPackagingPrices.Characteristic
	|	AND Goods.VendorPriceKind = ProductsWithDifferentPackagingPrices.VendorPriceKind
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.VendorPriceKind
	|";
	QueryText = StrReplace(QueryText, "Document.VendorInvoice", "Document." + TableName);
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
	
	Query = New Query;
	
	If TypeOf(Basis) = Type("DocumentRef.GoodsReceiptForStorage") Then
		
		QueryText = StrReplace(QueryText, "Goods.VendorPriceKind.Currency",				"&CurrencyOfPriceType");
		QueryText = StrReplace(QueryText, "Goods.VendorPriceKind.PriceIncludesVAT",	"NULL");
		QueryText = StrReplace(QueryText, "Goods.VendorPriceKind",					"&VendorPriceKind");
		QueryText = StrReplace(QueryText, "Goods.VATRate", "VALUE(Catalog.VATRates.EmptyRef)");
		
		VendorPriceKind = Common.ObjectAttributeValue(Basis, "VendorPriceKind");
		
		If Not ValueIsFilled(VendorPriceKind) Then
			Currency 			= Catalogs.Currencies.EmptyRef();
		Else
			
			DetailsOfSupplierSPriceType = Common.ObjectAttributesValues(VendorPriceKind, "Currency");
			
			Currency 			= DetailsOfSupplierSPriceType.Currency;

		EndIf;
		
		Query.SetParameter("CurrencyOfPriceType", 			Currency);
		Query.SetParameter("VendorPriceKind", 		VendorPriceKind);
		
	EndIf;
	
	Query.Text = QueryText;
	
	Query.SetParameter("Ref",          Basis);
	Query.SetParameter("Date",            HeaderSelection.Date);
	Query.SetParameter("Currency",          HeaderSelection.Currency);
	Query.SetParameter("PriceIncludesVAT", HeaderSelection.PriceIncludesVAT);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	QueryResult = Query.ExecuteBatch();
	DocumentObject.Goods.Load(QueryResult[3].Unload());
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// Fills in the price registration of the supplier's item based on the purchase of goods.
//
// Parameters:
//  Basis - DocumentRef.VendorInvoice - Link to the product purchase document.
//  DocumentObject - DocumentObject.VendorPriceList - The document to be filled in.
//
Procedure InformationOnReceiptOfGoods(Basis, DocumentObject) Export
	
	TableName = Basis.Metadata().Name;
	
	QueryText =
	"SELECT
	|	DocumentInflow.Date AS Date,
	|	DocumentInflow.Currency AS Currency,
	|	DocumentInflow.Partner AS Partner,
	|	DocumentInflow.PriceIncludesVAT AS PriceIncludesVAT,
	|	DocumentInflow.Ref AS DocumentBasis,
	|	NOT DocumentInflow.Posted AS ThereAreErrorsPosted,
	|	DocumentInflow.RegisterVendorPrices AS RegisterVendorPrices
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse AS DocumentInflow
	|WHERE
	|	DocumentInflow.Ref = &Ref";
	
	Query = New Query(QueryText);	
	Query.SetParameter("Ref", Basis);
	QueryResult = Query.Execute();
	HeaderSelection = QueryResult.Select();
	HeaderSelection.Next();
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.DocumentBasis,
		,
		HeaderSelection.ThereAreErrorsPosted,);
	ReportPriceRegistrationErrors(HeaderSelection.RegisterVendorPrices, HeaderSelection.DocumentBasis);
	FillPropertyValues(DocumentObject, HeaderSelection);
	
	QueryText = 
	"SELECT DISTINCT
	|	ReceiptOfGoodsToWarehouse.VendorPriceKind.Currency AS Currency
	|INTO Currencies
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse AS ReceiptOfGoodsToWarehouse
	|WHERE
	|	ReceiptOfGoodsToWarehouse.Ref = &Ref
	|	AND NOT ReceiptOfGoodsToWarehouse.VendorPriceKind = VALUE(Catalog.VendorPriceTypes.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	&Currency
	|
	|INDEX BY
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrencyRatesCut.Currency AS Currency,
	|	CurrencyRatesCut.CourseNumerator AS CourseNumerator,
	|	CurrencyRatesCut.CourseDenominator AS CourseDenominator
	|INTO TemporaryTableCurrencyExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency IN
	|		(SELECT DISTINCT
	|			Currencies.Currency
	|		FROM
	|			Currencies)
	|	AND BaseCurrency = &BaseCurrency) AS CurrencyRatesCut
	|
	|INDEX BY
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	DocumentInflow.VendorPriceKind AS VendorPriceKind,
	|	GoodsTable.Package AS Package,
	|	CAST(GoodsTable.Price * CASE
	|		WHEN &PriceIncludesVAT
	|		AND NOT DocumentInflow.VendorPriceKind.PriceIncludesVAT
	|			THEN CASE
	|				WHEN GoodsTable.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|					THEN 1
	|				ELSE 100 / (100 + GoodsTable.VATRate.Rate1)
	|			END
	|		WHEN NOT &PriceIncludesVAT
	|		AND DocumentInflow.VendorPriceKind.PriceIncludesVAT
	|			THEN (GoodsTable.VATRate.Rate1 + 100) / 100
	|		ELSE 1
	|	END * CASE
	|		WHEN &Currency <> DocumentInflow.VendorPriceKind.Currency
	|			THEN CASE
	|				WHEN ISNULL(ExchangeRatesOfAgreement_.CourseDenominator, 0) > 0
	|				AND ISNULL(ExchangeRatesOfAgreement_.CourseNumerator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN Currency_Rates.CourseNumerator * ExchangeRatesOfAgreement_.CourseDenominator / (ExchangeRatesOfAgreement_.CourseNumerator *
	|						Currency_Rates.CourseDenominator)
	|				ELSE 0
	|			END
	|		ELSE 1
	|	END AS NUMBER(31, 2)) AS Price
	|INTO Goods
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsTable
	|		LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS DocumentInflow
	|		ON (DocumentInflow.Ref = GoodsTable.Ref)
	|		LEFT JOIN TemporaryTableCurrencyExchangeRates AS Currency_Rates
	|		ON (Currency_Rates.Currency = &Currency)
	|		LEFT JOIN TemporaryTableCurrencyExchangeRates AS ExchangeRatesOfAgreement_
	|		ON (ExchangeRatesOfAgreement_.Currency = DocumentInflow.VendorPriceKind.Currency)
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND DocumentInflow.VendorPriceKind <> VALUE(Catalog.VendorPriceTypes.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.VendorPriceKind AS VendorPriceKind,
	|	AVG(GoodsTable.Price / CASE
	|		WHEN GoodsTable.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN &QueryTextPackagingFactor
	|		ELSE 1
	|	END) AS PricePerBaseUnit,
	|	COUNT(DISTINCT GoodsTable.Package) AS NumberOfDifferentPackages
	|INTO ProductsWithDifferentPackagingPrices
	|FROM
	|	Goods AS GoodsTable
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.VendorPriceKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(GoodsTable.PartnerProducts) AS PartnerProducts,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.VendorPriceKind AS VendorPriceKind,
	|	MIN(CASE
	|		WHEN ProductsWithDifferentPackagingPrices.NumberOfDifferentPackages > 1
	|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		ELSE GoodsTable.Package
	|	END) AS Package,
	|	AVG(CASE
	|		WHEN ProductsWithDifferentPackagingPrices.NumberOfDifferentPackages > 1
	|			THEN ProductsWithDifferentPackagingPrices.PricePerBaseUnit
	|		ELSE GoodsTable.Price
	|	END) AS Price
	|FROM
	|	Goods AS GoodsTable
	|		LEFT JOIN ProductsWithDifferentPackagingPrices AS ProductsWithDifferentPackagingPrices
	|		ON GoodsTable.Products = ProductsWithDifferentPackagingPrices.Products
	|		AND GoodsTable.Characteristic = ProductsWithDifferentPackagingPrices.Characteristic
	|		AND GoodsTable.VendorPriceKind = ProductsWithDifferentPackagingPrices.VendorPriceKind
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.VendorPriceKind";
	QueryText = StrReplace(QueryText, "Document.VendorInvoice", "Document." + TableName);
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsTable.Package",
		"GoodsTable.Products"));
		
	Query = New Query(QueryText);
		
	Query.SetParameter("Ref",                    Basis);
	Query.SetParameter("Date",                      HeaderSelection.Date);
	Query.SetParameter("Currency",                    HeaderSelection.Currency);
	Query.SetParameter("PriceIncludesVAT",           HeaderSelection.PriceIncludesVAT);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	QueryResult = Query.ExecuteBatch();
	DocumentObject.Goods.Load(QueryResult[3].Unload());
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion
// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function QueryTextItemsPricesOfVendor(Query, QueryTexts, Registers)
	
	RegisterName = "ItemsPricesOfVendor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	GoodsTable.PartnerProducts    AS PartnerProducts,
	|	GoodsTable.Products              AS Products,
	|	GoodsTable.Characteristic            AS Characteristic,
	|	GoodsTable.Package                  AS Package,
	|	GoodsTable.VendorPriceKind         AS VendorPriceKind,
	|	GoodsTable.Price                      AS Price,
	|	GoodsTable.VendorPriceKind.Currency  AS Currency,
	|	GoodsTable.Ref.Partner            AS Partner,
	|	GoodsTable.Ref.Date               AS Period,
	|	GoodsTable.OrderPackage            AS OrderPackage,
	|	GoodsTable.MinimumDeliveryLot AS MinimumDeliveryLot,
	|	GoodsTable.SettingConditions          AS SettingConditions
	|FROM
	|	Document.VendorPriceList.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products <> VALUE(Catalog.Products.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextDeliveryTerms(Query, QueryTexts, Registers)
	
	RegisterName = "PurchaseConditions";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	GoodsTable.Ref.Date               AS Period,
	|	GoodsTable.Products              AS Products,
	|	GoodsTable.Characteristic            AS Characteristic,
	|	GoodsTable.VendorPriceKind         AS VendorPriceKind,
	|	GoodsTable.OrderPackage            AS OrderPackage,
	|	GoodsTable.MinimumDeliveryLot AS MinimumDeliveryLot
	|FROM
	|	Document.VendorPriceList.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products <> VALUE(Catalog.Products.EmptyRef)
	|	AND GoodsTable.SettingConditions = TRUE
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Private

// Reports a creation error if price registration has already been created for the specified base.
//
// Parameters:
//   RegisterSupplierSPricesWithBasis - Boolean - True if a registration has already been created for this reason.
//   SupplierPriceRegistrationDocument       - DocumentRef.VendorPriceList - registration that was created earlier on the basis of the document.
//
Procedure ReportPriceRegistrationErrors(RegisterSupplierSPricesWithBasis, SupplierPriceRegistrationDocument) Export
	
	If RegisterSupplierSPricesWithBasis Then
		
		ErrorText = NStr("vi = 'Đơn giá đã được ghi nhận bằng chứng từ %Document%. Không cần nhập trên cơ sở.';
						|ru = 'Цены уже зарегистрированы документом %Document%. Ввод на основании не требуется.';
						|en = 'Prices have already been registered by document %Document%. Generation from base documents is not required.'; fa = 'Prices have already been registered by document %Document%. Generation from base documents is not required.';
						|it = 'I prezzi sono già registrati dal documento %Document%. Inserimento sulla base non è necessario.';
						|pl = 'Ceny są już zarejestrowane w dokumencie %Document%. Wprowadzenie na podstawie nie jest wymagane.';
						|tr = 'Fiyatlar zaten %Document% belgesiyle kaydedildi. Temele dayalı giriş gerekmemektedir.'");
		ErrorText = StrReplace(ErrorText, "%Document%", SupplierPriceRegistrationDocument);
		
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
