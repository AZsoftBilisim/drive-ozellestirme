
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Partner") Then
		Partner = Parameters.Partner;
	EndIf;
	
	If Parameters.Property("Terms") Then
		Terms = Parameters.Terms;
	EndIf;
	
	If Parameters.Property("BucketData") Then
		CustomerShoppingCart.Load(Parameters.BucketData.Unload(,"Products,Characteristic,Package,NumberOfPackages"));
	EndIf;
	
	If Parameters.Property("Currency") Then
		Currency = Parameters.Currency;
	EndIf;
	
	If Parameters.Property(PriceIncludesVAT) Then
		PriceIncludesVAT = Parameters.PriceIncludesVAT;
	EndIf;
	
	If Parameters.Property(VATTaxation) Then
		VATTaxation = Parameters.VATTaxation;
	EndIf;
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(
					Common.ObjectAttributeValue(Terms, "Organization"));
	EndIf;
	
	GenerateOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	GenerateOnServer();
	
EndProcedure 

#EndRegion

#Region Private

&AtServer
Procedure GenerateOnServer()
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	DocumentCustomerTermsOfSales.Ref,
	|	DocumentCustomerTermsOfSales.Currency,
	|	DocumentCustomerTermsOfSales.Description,
	|	DocumentCustomerTermsOfSales.Warehouse,
	|	DocumentCustomerTermsOfSales.PriceIncludesVAT,
	|	DocumentCustomerTermsOfSales.Counterparty,
	|	ISNULL(PaymentSchedules.Description, """") AS PaymentScheduleName,
	|	PaymentSchedules.Ref AS PaymentSchedule,
	|	ISNULL(Warehouses.Description, &StringWithoutRestrictions) AS WarehouseName,
	|	ISNULL(Counterparties.Description, &StringWithoutRestrictions) AS CounterpartyName_,
	|	DocumentCustomerTermsOfSales.BusinessOperation AS BusinessOperation,
	|	Currencies.Description AS CurrencyName
	|INTO AvailablePartnerAgreements
	|FROM
	|	Catalog.TermsOfSale AS DocumentCustomerTermsOfSales
	|		LEFT JOIN Catalog.PaymentSchedules AS PaymentSchedules
	|		ON DocumentCustomerTermsOfSales.PaymentSchedule = PaymentSchedules.Ref
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON DocumentCustomerTermsOfSales.Warehouse = Warehouses.Ref
	|		LEFT JOIN Catalog.Counterparties AS Counterparties
	|		ON DocumentCustomerTermsOfSales.Counterparty = Counterparties.Ref
	|		LEFT JOIN Catalog.Currencies AS Currencies
	|		ON DocumentCustomerTermsOfSales.Currency = Currencies.Ref
	|WHERE
	|	DocumentCustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|	AND (DocumentCustomerTermsOfSales.Partner = &Partner
	|			OR DocumentCustomerTermsOfSales.PartnersSegment IN
	|				(SELECT
	|					SegmentPartners.Segment
	|				FROM
	|					InformationRegister.SegmentPartners AS SegmentPartners
	|				WHERE
	|					SegmentPartners.Partner = &Partner) OR (DocumentCustomerTermsOfSales.Standard_
	|					AND DocumentCustomerTermsOfSales.PartnersSegment = VALUE(Catalog.PartnersSegments.EmptyRef)))
	|	AND (DocumentCustomerTermsOfSales.ValidityStartDate = DATETIME(1, 1, 1)
	|			OR BEGINOFPERIOD(&CurrentDate, DAY) >= DocumentCustomerTermsOfSales.ValidityStartDate)
	|	AND (DocumentCustomerTermsOfSales.ValidityEndDate = DATETIME(1, 1, 1)
	|			OR BEGINOFPERIOD(&CurrentDate, DAY) <= DocumentCustomerTermsOfSales.ValidityEndDate)
	|	AND NOT DocumentCustomerTermsOfSales.DeletionMark AND DocumentCustomerTermsOfSales.AvailableToExternalUsers
	|	AND CASE
	|		WHEN &OnlyStandard = TRUE
	|				AND &OnlyPersonal = FALSE
	|				AND DocumentCustomerTermsOfSales.Standard_
	|			THEN TRUE
	|		WHEN &OnlyPersonal = TRUE
	|				AND NOT &OnlyStandard = TRUE
	|				AND NOT DocumentCustomerTermsOfSales.Standard_
	|			THEN TRUE
	|		WHEN &OnlyStandard = FALSE
	|				AND &OnlyPersonal = FALSE
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST (CustomerShoppingCart.Products AS Catalog.Products) AS Products,
	|	CustomerShoppingCart.Characteristic,
	|	CustomerShoppingCart.Package,
	|	CustomerShoppingCart.PutFileDate,
	|	CustomerShoppingCart.NumberOfPackages
	|INTO CustomerShoppingCart
	|FROM
	|	&CustomerShoppingCart AS CustomerShoppingCart
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerShoppingCart.Products,
	|	CustomerShoppingCart.Characteristic,
	|	CustomerShoppingCart.Package,
	|	CustomerShoppingCart.NumberOfPackages,
	|	CustomerShoppingCart.PutFileDate,
	|	CatProducts.PriceGroup,
	|	ISNULL(&QueryTextPackagingFactor1, 0) AS PackagingFactor
	|INTO BucketData
	|FROM
	|	CustomerShoppingCart AS CustomerShoppingCart
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CustomerShoppingCart.Products = CatProducts.Ref
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON CustomerShoppingCart.Package = ProductPackages.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CustomerTermsOfSales.Ref AS Terms,
	|	AgreementWithCustomerGoods.Products,
	|	AgreementWithCustomerGoods.Characteristic,
	|	AgreementWithCustomerGoods.Package,
	|	AgreementWithCustomerGoods.Price,
	|	VALUE(Catalog.TypesOfPrices.EmptyRef) AS PriceKind,
	|	CustomerTermsOfSales.Currency AS Currency,
	|	CustomerTermsOfSales.PriceIncludesVAT
	|INTO ProductPriceAgreement
	|FROM
	|	BucketData AS BucketData
	|		INNER JOIN Catalog.TermsOfSale.Goods AS AgreementWithCustomerGoods
	|			INNER JOIN Catalog.TermsOfSale AS CustomerTermsOfSales
	|			ON AgreementWithCustomerGoods.Ref = CustomerTermsOfSales.Ref
	|		ON BucketData.Products = AgreementWithCustomerGoods.Products
	|			AND BucketData.Characteristic = AgreementWithCustomerGoods.Characteristic
	|WHERE
	|	AgreementWithCustomerGoods.Ref IN
	|			(SELECT
	|				AvailablePartnerAgreements.Ref
	|			FROM
	|				AvailablePartnerAgreements AS AvailablePartnerAgreements)
	|	AND AgreementWithCustomerGoods.Price > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	BucketData.Products,
	|	BucketData.Characteristic,
	|	AgreementWithCustomerGoods.PriceKind,
	|	CustomerTermsOfSales.Ref
	|INTO TypeOfPriceTermsOfAgreement
	|FROM
	|	BucketData AS BucketData
	|		INNER JOIN Catalog.TermsOfSale.Goods AS AgreementWithCustomerGoods
	|			INNER JOIN Catalog.TermsOfSale AS CustomerTermsOfSales
	|			ON AgreementWithCustomerGoods.Ref = CustomerTermsOfSales.Ref
	|		ON BucketData.Products = AgreementWithCustomerGoods.Products
	|			AND BucketData.Characteristic = AgreementWithCustomerGoods.Characteristic
	|WHERE
	|	AgreementWithCustomerGoods.Price = 0
	|	AND AgreementWithCustomerGoods.Ref IN
	|			(SELECT
	|				AvailablePartnerAgreements.Ref
	|			FROM
	|				AvailablePartnerAgreements AS AvailablePartnerAgreements)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CustomerAgreementPriceGroups.Ref AS DocumentTerms,
	|	BucketData.Products,
	|	BucketData.Characteristic,
	|	CustomerAgreementPriceGroups.PricesKind
	|INTO DataOnPriceGroups
	|FROM
	|	BucketData AS BucketData
	|		INNER JOIN Catalog.TermsOfSale.PriceGroups AS CustomerAgreementPriceGroups
	|		ON BucketData.PriceGroup = CustomerAgreementPriceGroups.PriceGroup
	|WHERE
	|	CustomerAgreementPriceGroups.Ref IN
	|			(SELECT
	|				AvailablePartnerAgreements.Ref
	|			FROM
	|				AvailablePartnerAgreements AS AvailablePartnerAgreements)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DataOnPriceGroups.DocumentTerms,
	|	DataOnPriceGroups.Products,
	|	DataOnPriceGroups.Characteristic,
	|	DataOnPriceGroups.PricesKind
	|INTO PriceTypeByPriceGroup
	|FROM
	|	DataOnPriceGroups AS DataOnPriceGroups
	|		LEFT JOIN ProductPriceAgreement AS ProductPrice_1
	|		ON DataOnPriceGroups.DocumentTerms = ProductPrice_1.Terms
	|			AND DataOnPriceGroups.Products = ProductPrice_1.Products
	|			AND DataOnPriceGroups.Characteristic = ProductPrice_1.Characteristic
	|		LEFT JOIN TypeOfPriceTermsOfAgreement AS TypeOfPriceTermsOfAgreement
	|		ON DataOnPriceGroups.Products = TypeOfPriceTermsOfAgreement.Products
	|			AND DataOnPriceGroups.Characteristic = TypeOfPriceTermsOfAgreement.Characteristic
	|			AND DataOnPriceGroups.DocumentTerms = TypeOfPriceTermsOfAgreement.Ref
	|WHERE
	|	DataOnPriceGroups.DocumentTerms IN
	|			(SELECT
	|				AvailablePartnerAgreements.Ref
	|			FROM
	|				AvailablePartnerAgreements AS AvailablePartnerAgreements)
	|	AND TypeOfPriceTermsOfAgreement.Products IS NULL 
	|	AND ProductPrice_1.Products IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrencyRatesCut.Currency,
	|	CurrencyRatesCut.CourseNumerator,
	|	CurrencyRatesCut.CourseDenominator
	|INTO ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(, BaseCurrency = &BaseCurrency) AS CurrencyRatesCut
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT ALLOWED
	|	BucketData.Products,
	|	BucketData.Characteristic,
	|	CustomerTermsOfSales.Ref,
	|	CustomerTermsOfSales.PricesKind
	|INTO DataTypeOfPriceAgreement
	|FROM
	|	BucketData AS BucketData,
	|	Catalog.TermsOfSale AS CustomerTermsOfSales
	|WHERE
	|	CustomerTermsOfSales.Ref IN
	|			(SELECT
	|				AvailablePartnerAgreements.Ref
	|			FROM
	|				AvailablePartnerAgreements AS AvailablePartnerAgreements)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataTypeOfPriceAgreement.Products,
	|	DataTypeOfPriceAgreement.Characteristic,
	|	DataTypeOfPriceAgreement.Ref,
	|	DataTypeOfPriceAgreement.PricesKind
	|INTO PriceTypeByTerms
	|FROM
	|	DataTypeOfPriceAgreement AS DataTypeOfPriceAgreement
	|		LEFT JOIN PriceTypeByPriceGroup AS PriceTypeByPriceGroup
	|		ON DataTypeOfPriceAgreement.Products = PriceTypeByPriceGroup.Products
	|			AND DataTypeOfPriceAgreement.Characteristic = PriceTypeByPriceGroup.Characteristic
	|			AND DataTypeOfPriceAgreement.Ref = PriceTypeByPriceGroup.DocumentTerms
	|		LEFT JOIN ProductPriceAgreement AS ProductPrice_1
	|		ON DataTypeOfPriceAgreement.Products = ProductPrice_1.Products
	|			AND DataTypeOfPriceAgreement.Characteristic = ProductPrice_1.Characteristic
	|			AND DataTypeOfPriceAgreement.Ref = ProductPrice_1.Terms
	|		LEFT JOIN TypeOfPriceTermsOfAgreement AS TypeOfPriceTermsOfAgreement
	|		ON DataTypeOfPriceAgreement.Products = TypeOfPriceTermsOfAgreement.Products
	|			AND DataTypeOfPriceAgreement.Characteristic = TypeOfPriceTermsOfAgreement.Characteristic
	|			AND DataTypeOfPriceAgreement.Ref = TypeOfPriceTermsOfAgreement.Ref
	|WHERE
	|	ProductPrice_1.Products IS NULL 
	|	AND PriceTypeByPriceGroup.Products IS NULL 
	|	AND TypeOfPriceTermsOfAgreement.Products IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TypeOfPriceTermsOfAgreement.Ref AS Terms,
	|	TypeOfPriceTermsOfAgreement.Products,
	|	TypeOfPriceTermsOfAgreement.Characteristic,
	|	TypeOfPriceTermsOfAgreement.PriceKind AS PriceKind
	|INTO ProductsByPriceType
	|FROM
	|	TypeOfPriceTermsOfAgreement AS TypeOfPriceTermsOfAgreement
	|
	|UNION ALL
	|
	|SELECT
	|	PriceTypeByPriceGroup.DocumentTerms,
	|	PriceTypeByPriceGroup.Products,
	|	PriceTypeByPriceGroup.Characteristic,
	|	PriceTypeByPriceGroup.PricesKind
	|FROM
	|	PriceTypeByPriceGroup AS PriceTypeByPriceGroup
	|
	|UNION ALL
	|
	|SELECT
	|	PriceTypeByTerms.Ref,
	|	PriceTypeByTerms.Products,
	|	PriceTypeByTerms.Characteristic,
	|	PriceTypeByTerms.PricesKind
	|FROM
	|	PriceTypeByTerms AS PriceTypeByTerms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ProductsByPriceType.Terms,
	|	ProductsByPriceType.Products,
	|	ProductsByPriceType.Characteristic,
	|	ProductsByPriceType.PriceKind,
	|	MAX(ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0)) AS Price,
	|	MAX(ISNULL(ItemPricesCrossSectionOfTheLatest.Currency, VALUE(Catalog.Currencies.EmptyRef))) AS Currency,
	|	MAX(ISNULL(ItemPricesCrossSectionOfTheLatest.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))) AS Package
	|INTO ProductsPricesInPriceCurrency
	|FROM
	|	ProductsByPriceType AS ProductsByPriceType
	|		INNER JOIN AvailablePartnerAgreements AS AvailablePartnerAgreements
	|		ON ProductsByPriceType.Terms = AvailablePartnerAgreements.Ref
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(
	|				ENDOFPERIOD(&CurrentDate, DAY),
	|				Products IN
	|						(SELECT DISTINCT
	|							ProductsByPriceType.Products
	|						FROM
	|							ProductsByPriceType AS ProductsByPriceType)
	|					AND Characteristic IN
	|						(SELECT DISTINCT
	|							ProductsByPriceType.Characteristic
	|						FROM
	|							ProductsByPriceType AS ProductsByPriceType)
	|					AND PriceKind IN
	|						(SELECT DISTINCT
	|							ProductsByPriceType.PriceKind
	|						FROM
	|							ProductsByPriceType AS ProductsByPriceType)) AS ItemPricesCrossSectionOfTheLatest
	|		ON ProductsByPriceType.Products = ItemPricesCrossSectionOfTheLatest.Products
	|			AND ProductsByPriceType.Characteristic = ItemPricesCrossSectionOfTheLatest.Characteristic
	|			AND ProductsByPriceType.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
	|
	|GROUP BY
	|	ProductsByPriceType.Terms,
	|	ProductsByPriceType.Products,
	|	ProductsByPriceType.Characteristic,
	|	ProductsByPriceType.PriceKind
	|
	|UNION ALL
	|
	|SELECT
	|	ProductPriceAgreement.Terms,
	|	ProductPriceAgreement.Products,
	|	ProductPriceAgreement.Characteristic,
	|	ProductPriceAgreement.PriceKind,
	|	ProductPriceAgreement.Price,
	|	ProductPriceAgreement.Currency,
	|	ProductPriceAgreement.Package
	|FROM
	|	ProductPriceAgreement AS ProductPriceAgreement
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ProductsPricesInPriceCurrency.Terms AS Terms,
	|	ProductsPricesInPriceCurrency.Products AS Products,
	|	ProductsPricesInPriceCurrency.Characteristic,
	|	ProductsPricesInPriceCurrency.Package,
	|	CASE
	|		WHEN &Currency = ProductsPricesInPriceCurrency.Currency
	|			THEN ProductsPricesInPriceCurrency.Price
	|		WHEN ProductsPricesInPriceCurrency.Price = 0
	|			THEN 0
	|		ELSE ProductsPricesInPriceCurrency.Price * CASE
	|				WHEN ISNULL(ExchangeRates.CourseDenominator, 0) > 0
	|						AND ISNULL(ExchangeRates.CourseNumerator, 0) > 0
	|						AND ISNULL(ExchangeRatesTypeOfPrice.CourseDenominator, 0) > 0
	|						AND ISNULL(ExchangeRatesTypeOfPrice.CourseNumerator, 0) > 0
	|					THEN ExchangeRatesTypeOfPrice.CourseNumerator * ExchangeRates.CourseDenominator / (ExchangeRates.CourseNumerator * ExchangeRatesTypeOfPrice.CourseDenominator)
	|				ELSE 0
	|			END
	|	END AS Price,
	|	ProductsPricesInPriceCurrency.PriceKind,
	|	ISNULL(&QueryTextPackagingFactor2, 0) AS ZoomRatio
	|INTO AllPricesInReportCurrency
	|FROM
	|	ProductsPricesInPriceCurrency AS ProductsPricesInPriceCurrency
	|		LEFT JOIN ExchangeRates AS ExchangeRates
	|		ON (&Currency = ExchangeRates.Currency)
	|		LEFT JOIN ExchangeRates AS ExchangeRatesTypeOfPrice
	|		ON ProductsPricesInPriceCurrency.Currency = ExchangeRatesTypeOfPrice.Currency
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON ProductsPricesInPriceCurrency.Package = ProductPackages.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllPricesInReportCurrency.Terms,
	|	AllPricesInReportCurrency.Products,
	|	AllPricesInReportCurrency.Characteristic,
	|	AllPricesInReportCurrency.PriceKind,
	|	CASE
	|		WHEN BucketData.PackagingFactor = AllPricesInReportCurrency.ZoomRatio
	|			THEN AllPricesInReportCurrency.Price
	|		WHEN BucketData.PackagingFactor = 0
	|				AND AllPricesInReportCurrency.ZoomRatio <> 0
	|			THEN AllPricesInReportCurrency.Price / AllPricesInReportCurrency.ZoomRatio
	|		WHEN BucketData.PackagingFactor <> 0
	|				AND AllPricesInReportCurrency.ZoomRatio = 0
	|			THEN AllPricesInReportCurrency.Price * BucketData.PackagingFactor
	|		ELSE AllPricesInReportCurrency.Price / AllPricesInReportCurrency.ZoomRatio * BucketData.PackagingFactor
	|	END AS Price,
	|	BucketData.Package
	|INTO ProductsBasketsPricesCurrencyOfReportOnPackages
	|FROM
	|	AllPricesInReportCurrency AS AllPricesInReportCurrency
	|		INNER JOIN BucketData AS BucketData
	|		ON (BucketData.Characteristic = AllPricesInReportCurrency.Characteristic)
	|			AND (BucketData.Products = AllPricesInReportCurrency.Products)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsBasketsPricesCurrencyOfReportOnPackages.Terms AS Terms,
	|	ProductsBasketsPricesCurrencyOfReportOnPackages.Products AS Products,
	|	ProductsBasketsPricesCurrencyOfReportOnPackages.Characteristic AS Characteristic,
	|	ProductsBasketsPricesCurrencyOfReportOnPackages.Package AS Package,
	|	CASE
	|		WHEN AvailablePartnerAgreements.PriceIncludesVAT = &PriceIncludesVAT
	|			THEN ProductsBasketsPricesCurrencyOfReportOnPackages.Price
	|		ELSE CASE
	|				WHEN AvailablePartnerAgreements.PriceIncludesVAT
	|						AND (NOT &PriceIncludesVAT)
	|					THEN ProductsBasketsPricesCurrencyOfReportOnPackages.Price * (1
	|							/ (1 + (ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1))
	|				ELSE ProductsBasketsPricesCurrencyOfReportOnPackages.Price
	|						* (1 + (ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1)
	|			END
	|	END AS Price,
	|	ProductsBasketsPricesCurrencyOfReportOnPackages.PriceKind,
	|	BucketData.NumberOfPackages AS NumberOfPackages,
	|	ProductsBasketsPricesCurrencyOfReportOnPackages.Price * BucketData.NumberOfPackages AS Sum,
	|	CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))
	|		ELSE VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|	END AS VATRate,
	|	CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN CASE
	|					WHEN AvailablePartnerAgreements.PriceIncludesVAT
	|						THEN ProductsBasketsPricesCurrencyOfReportOnPackages.Price * BucketData.NumberOfPackages
	|								* (ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1
	|								/ (1 + (ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1)
	|					ELSE ProductsBasketsPricesCurrencyOfReportOnPackages.Price * BucketData.NumberOfPackages * (ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1
	|				END
	|		ELSE 0
	|	END AS VATAmount,
	|	BucketData.NumberOfPackages * ProductsBasketsPricesCurrencyOfReportOnPackages.Price + CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN CASE
	|					WHEN AvailablePartnerAgreements.PriceIncludesVAT
	|						THEN 0
	|					ELSE ProductsBasketsPricesCurrencyOfReportOnPackages.Price * BucketData.NumberOfPackages
	|							* (ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1
	|				END
	|		ELSE 0
	|	END AS AmountTotal,
	|	BucketData.Products.UnitOfMeasure AS UnitOfMeasure
	|FROM
	|	ProductsBasketsPricesCurrencyOfReportOnPackages AS ProductsBasketsPricesCurrencyOfReportOnPackages
	|		INNER JOIN BucketData AS BucketData
	|		ON ProductsBasketsPricesCurrencyOfReportOnPackages.Products = BucketData.Products
	|			AND ProductsBasketsPricesCurrencyOfReportOnPackages.Characteristic = BucketData.Characteristic
	|			AND ProductsBasketsPricesCurrencyOfReportOnPackages.Package = BucketData.Package
	|		INNER JOIN AvailablePartnerAgreements AS AvailablePartnerAgreements
	|		ON ProductsBasketsPricesCurrencyOfReportOnPackages.Terms = AvailablePartnerAgreements.Ref
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&CurrentDate, Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
	|		ON ProductsBasketsPricesCurrencyOfReportOnPackages.Products = ProductsVATRates.Products
	|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&CurrentDate, Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS BasicVATRates
	|		ON TRUE
	|
	|ORDER BY
	|	AvailablePartnerAgreements.Description,
	|	BucketData.PutFileDate
	|TOTALS BY
	|	Products,
	|	Characteristic,
	|	Package,
	|	UnitOfMeasure,
	|	NumberOfPackages,
	|	Terms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AvailablePartnerAgreements.Ref AS Ref,
	|	AvailablePartnerAgreements.Description AS Description,
	|	AvailablePartnerAgreements.BusinessOperation AS AgreementKind,
	|	AvailablePartnerAgreements.CurrencyName AS Currency,
	|	AvailablePartnerAgreements.WarehouseName AS Warehouse,
	|	AvailablePartnerAgreements.PaymentScheduleName AS PaymentSchedule,
	|	AvailablePartnerAgreements.PriceIncludesVAT,
	|	AvailablePartnerAgreements.CounterpartyName_ AS Counterparty,
	|	0 AS Total
	|FROM
	|	AvailablePartnerAgreements AS AvailablePartnerAgreements
	|
	|ORDER BY
	|	Description";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPackages",
			"CatProducts"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPackages",
			"ProductsPricesInPriceCurrency.Products"));
		
	Table = CustomerShoppingCart.Unload();
	Table.GroupBy("Products, Characteristic, Package, PutFileDate", "NumberOfPackages");
	
	Query.SetParameter("Partner",Partner);
	Query.SetParameter("CustomerShoppingCart", Table);
	Query.SetParameter("CurrentDate",CurrentSessionDate());
	Query.SetParameter("Currency",Currency);
	Query.SetParameter("PriceIncludesVAT",PriceIncludesVAT);
	Query.SetParameter("VATTaxation",VATTaxation);
	Query.SetParameter("StringWithoutRestrictions",NStr("vi = 'Không giới hạn';
														|ru = 'Без ограничений';
														|en = 'Without restrictions'; fa = 'بدون محدودیت';
														|it = 'Senza restrizioni';
														|pl = 'Bez ograniczeń';
														|tr = 'Kısıtlamasız'"));
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(
		Common.ObjectAttributeValue(Terms, "Organization")));
	
	UseStandardTermsOfSalesWithCustomers			= GetFunctionalOption("UseStandardTermsOfSalesWithCustomers");
	UseCustomerTermsOfSales	= GetFunctionalOption("UseCustomerTermsOfSales");
	OnlyStandard = UseStandardTermsOfSalesWithCustomers And Not UseCustomerTermsOfSales;
	OnlyPersonal = Not UseStandardTermsOfSalesWithCustomers And UseCustomerTermsOfSales;
	Query.SetParameter("OnlyStandard",OnlyStandard);
	Query.SetParameter("OnlyPersonal",OnlyPersonal);
	
	QueryResultsArray1 = Query.ExecuteBatch();
	
	If QueryResultsArray1[15].IsEmpty() Then
		Return;
	EndIf;
	
	If Not QueryResultsArray1[14].IsEmpty() Then
		OutputToSpreadsheetDocument(QueryResultsArray1[14], QueryResultsArray1[15]);
	EndIf;
	
EndProcedure

&AtServer
Function ConditionName(Name)
	
	If Name = "PaymentSchedule" Then
		Return NStr("vi = 'Lịch biểu thanh toán';
					|ru = 'График оплаты';
					|en = 'Payment schedule'; fa = 'برنامه پرداخت';
					|it = 'Calendario dei pagamenti';
					|pl = 'Harmonogram płatności';
					|tr = 'Ödeme planı'");
	ElsIf Name = "VATTaxation" Then
		Return NStr("vi = 'Tính thuế';
					|ru = 'Налогообложение';
					|en = 'Taxation'; fa = 'مالیات‌ستانی';
					|it = 'Tassazione';
					|pl = 'Taxation';
					|tr = 'Vergilendirme'");
	ElsIf Name = "AgreementKind" Then
		Return NStr("vi = 'Dạng khế ước';
					|ru = 'Вид соглашения';
					|en = 'Agreement kind'; fa = 'Agreement kind';
					|it = 'Tipo di accordo';
					|pl = 'Rodzaj umowy';
					|tr = 'Anlaşma türü'");
	ElsIf Name = "PriceIncludesVAT" Then
		Return NStr("vi = 'Giá gồm thuế GTGT';
					|ru = 'Цена включает НДС';
					|en = 'Price includes VAT'; fa = 'قیمت شامل مالیات بر ارزش افزوده است';
					|it = 'Il prezzo include l''IVA';
					|pl = 'Cena zawiera VAT';
					|tr = 'Fiyata KDV dahildir'");
	Else
		Return Name;
	EndIf;
	
EndFunction

// Generates a table document
// 
// Parameters:
//  QueryResult           - QueryResult - 
// 	AgreementRequestResult - QueryResult - 
&AtServer
Procedure OutputToSpreadsheetDocument(QueryResult,AgreementRequestResult)
	
	SpreadsheetDocument.Clear();
	
	Template = DataProcessors.SelfServiceWorkplacePartners.GetTemplate("PricesAndAmountsByTermsOfSales");
	
	EmptyStringArea = Template.GetArea("IsBlankString");
	SubtitleArea = Template.GetArea("Subtitle|Title");
	
	SpreadsheetDocument.Put(EmptyStringArea);
	SubtitleArea.Parameters.Text = NStr("vi = 'Điều kiện mà phụ thuộc vào thỏa thuận';
										|ru = 'Условия, зависящие от соглашения';
										|en = 'Conditions depending on agreement'; fa = 'Conditions depending on agreement';
										|it = 'Condizioni dipendenti dall''accordo';
										|pl = 'Warunki, które zależą od umowy';
										|tr = 'Anlaşmaya bağlı koşullar'");
	SpreadsheetDocument.Put(SubtitleArea);
	SpreadsheetDocument.Put(EmptyStringArea);
	
	//TermsOfAgreement__
	ConditionHeaderArea     = Template.GetArea("ConditionHeader|Condition");
	AgreementHeaderArea  = Template.GetArea("ConditionHeader|AgreementCondition");
	
	FieldStringCondition    = Template.GetArea("StringCondition|Condition");
	AreaStringAgreement = Template.GetArea("StringCondition|AgreementCondition"); 
	
	SpreadsheetDocument.Put(ConditionHeaderArea);
	AgreementSelection = AgreementRequestResult.Select();
	While AgreementSelection.Next() Do
		
		AgreementHeaderArea.Parameters.Terms = AgreementSelection.Description;
		SpreadsheetDocument.Join(AgreementHeaderArea);
		
	EndDo; 
	
	AgreementTable = AgreementRequestResult.Unload();
	For Indus = 2 To AgreementTable.Columns.Count()-2 Do
		
		TableColumn2 = AgreementTable.Columns[Indus]; // ValueTableColumn
		FieldStringCondition.Parameters.Condition = ConditionName(TableColumn2.Name);
		SpreadsheetDocument.Put(FieldStringCondition);
		
		For IndusAgreements = 0 To AgreementTable.Count() - 1 Do
			AreaStringAgreement.Parameters.ConditionValue = AgreementTable[IndusAgreements][Indus];
			SpreadsheetDocument.Join(AreaStringAgreement);
		EndDo;
		
	EndDo;
	
	SpreadsheetDocument.Put(EmptyStringArea); 
	SubtitleArea.Parameters.Text = NStr("vi = 'Đơn giá và số tiền phụ thuộc vào thỏa thuận';
										|ru = 'Цены и суммы в зависимости от соглашения';
										|en = 'Prices and amounts according to the agreement'; fa = 'Prices and amounts according to the agreement';
										|it = 'I prezzi e gli importi a seconda dell''accordo';
										|pl = 'Ceny i wartości w zależności od umowy';
										|tr = 'Anlaşmaya bağlı fiyat ve tutarlar'");
	SpreadsheetDocument.Put(SubtitleArea);
	SpreadsheetDocument.Put(EmptyStringArea);
	
	// Prices and amounts
	UsingProductCharacteristics = GetFunctionalOption("UseItemVariants");
	
	AreaProductHeader              = Template.GetArea("Header|Products");
	AreaHeaderCharacteristic            = Template.GetArea("Header|Characteristic");
	AreaCapPackingQuantity        = Template.GetArea("Header|PackingQuantity_");
	AgreementHeaderArea                = Template.GetArea("Header|Terms");
	
	ScopeAndProducts             = Template.GetArea("String|Products");
	ScopeAndCharacteristics           = Template.GetArea("String|Characteristic");
	ScopeStringPackingQuantity       = Template.GetArea("String|PackingQuantity_");
	AreaStringAgreement               = Template.GetArea("String|Terms");
	
	SpreadsheetDocument.Put(AreaProductHeader);
	If UsingProductCharacteristics Then
		SpreadsheetDocument.Join(AreaHeaderCharacteristic);
	EndIf;
	
	SpreadsheetDocument.Join(AreaCapPackingQuantity);
	AgreementSelection = AgreementRequestResult.Select();
	While AgreementSelection.Next() Do
		
		AgreementHeaderArea.Parameters.Terms = AgreementSelection.Description;
		SpreadsheetDocument.Join(AgreementHeaderArea);
		
	EndDo;
	
	LineNumber = 0;
	
	SelectionOfProducts = QueryResult.Select(QueryResultIteration.ByGroups);
	While SelectionOfProducts.Next() Do
		SampleCharacteristics = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
		While SampleCharacteristics.Next() Do
			SamplePackaging = SampleCharacteristics.Select(QueryResultIteration.ByGroups);
			While SamplePackaging.Next() Do
				SampleUnits = SamplePackaging.Select(QueryResultIteration.ByGroups);
				While SampleUnits.Next() Do
					SampleQuantity = SampleUnits.Select(QueryResultIteration.ByGroups);
					While SampleQuantity.Next() Do
						LineNumber = LineNumber + 1;
						ScopeAndProducts.Parameters.LineNumber  = LineNumber;
						ScopeAndProducts.Parameters.Products = SelectionOfProducts.Products;
						SpreadsheetDocument.Put(ScopeAndProducts);
						If UsingProductCharacteristics Then
							ScopeAndCharacteristics.Parameters.Characteristic = SampleCharacteristics.Characteristic;
							SpreadsheetDocument.Join(ScopeAndCharacteristics);
						EndIf;
						ScopeStringPackingQuantity.Parameters.Package = ?(SampleQuantity.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(),
						                                                       SampleQuantity.UnitOfMeasure,
						                                                       String(SampleQuantity.Package)+ ","+ String(SampleQuantity.UnitOfMeasure));
						ScopeStringPackingQuantity.Parameters.Count = SampleQuantity.NumberOfPackages;
						SpreadsheetDocument.Join(ScopeStringPackingQuantity);
						SampleAgreement = SampleQuantity.Select(QueryResultIteration.ByGroups);
						While SampleAgreement.Next() Do
							CurRowAgreementTable = AgreementTable.Find(SampleAgreement.Terms,"Ref");
							DetailsSelection = SampleAgreement.Select();
							While DetailsSelection.Next() Do 
								AreaStringAgreement.Parameters.Price 	= DetailsSelection.Price;
								AreaStringAgreement.Parameters.Total = DetailsSelection.AmountTotal;
								CurRowAgreementTable.Total	= CurRowAgreementTable.Total + DetailsSelection.AmountTotal;
								SpreadsheetDocument.Join(AreaStringAgreement);
							EndDo;
						EndDo;
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
	AreaTotalProducts              = Template.GetArea("InTotal|Products");
	AreaTotalCharacteristic            = Template.GetArea("InTotal|Characteristic");
	AreaTotalPackagingQuantity        = Template.GetArea("InTotal|PackingQuantity_");
	AreaTotalAgreement                = Template.GetArea("InTotal|Terms");
	
	SpreadsheetDocument.Put(AreaTotalProducts);
	If UsingProductCharacteristics Then
		SpreadsheetDocument.Join(AreaTotalCharacteristic);
	EndIf;
	
	SpreadsheetDocument.Join(AreaTotalPackagingQuantity);
	For Each RowOfAgreementTable In AgreementTable Do
	
		AreaTotalAgreement.Parameters.Total = RowOfAgreementTable.Total;
		SpreadsheetDocument.Join(AreaTotalAgreement);
	
	EndDo;
	
EndProcedure

#EndRegion
