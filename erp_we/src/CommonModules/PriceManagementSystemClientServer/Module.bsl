////////////////////////////////////////////////////////////////////////////////
// The module contains procedures and functions for processing user actions
// in the process of working with prices.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Calculates the amount of VAT from the amount depending on the inclusion of VAT in the price.
//
// Parameters:
//  Sum           - Number - The amount from which you want to calculate the VAT amount.
//  VATRate       - CatalogRef.VATRates - VAT rate.
//  PriceIncludesVAT - Boolean - Indicates whether VAT is included in the price.
//  VATTaxation - EnumRef.VATTaxationTypes - document taxation
//
// Returns:
//  Number - amount of VAT.
//
Function CalculateVATAmount(Sum, VATRate, PriceIncludesVAT = True, VATTaxation = Undefined) Export
	
	Return VATAccountingERPClientServer.CalculateVATAmount(
		Sum,
		VATAccountingERPClientServer.ValueOfVATRate(VATRate),
		PriceIncludesVAT,
		VATTaxation)
	
EndFunction // Calculate Sums()

// Returns the numeric value of the VAT rate
//
// Parameters:
//  VATRate - CatalogRef.VATRates - the value of Stalkings.
//
// Returns:
//  Number - The value of the VAT rate is a number.
//
Function GetVATRateAsNumber(Val VATRate) Export
	
	Return VATAccountingERPClientServer.ValueOfVATRate(VATRate);
	
EndFunction // Get the number of seconds()

#Region ProceduresAndFunctionsOfWorkingWithResultsOfDocuments

// Returns the document amount including VAT
//
// Parameters:
//  Goods          - TabularSection - table part of the document for calculating the document amount.
//  PriceIncludesVAT - Boolean - indicates whether VAT is included in the document price.
//
// Returns:
//  Number - The amount of the document including VAT/.
//
Function GetDocumentAmount(Goods, Val PriceIncludesVAT) Export

	DocumentAmount = Goods.Total("Sum");

	If Not PriceIncludesVAT Then
		DocumentAmount = DocumentAmount + Goods.Total("VATAmount");
	EndIf;

	Return DocumentAmount;

EndFunction // Get the sum of the document()

#EndRegion

#Region ProceduresAndFunctionsForPerformingRounding

// Rounds the number in the specified order 
//
// Parameters:
//  Number              - Number - original number.
//  RoundingPrecision - Number - A number that determines the rounding accuracy.
//  RoundOffOption  - EnumRef.RoundingOptions - defines the rounding method.
//
// Returns:
//  Number - the original number rounded to the specified precision.
//
Function RoundUpPrice(Number, RoundingPrecision, RoundOffOption) Export

	Var Result;
		
	// calculate the number of intervals included in the number
	If RoundingPrecision <> 0 Then
		NumberOfIntervals_ = Number / RoundingPrecision;
	Else
		NumberOfIntervals_ = 0;
	EndIf;
	
	// calculate the integer number of intervals.
	NumberOfIntegerIntervals = Int(NumberOfIntervals_);
		
	If NumberOfIntervals_ = NumberOfIntegerIntervals Then
		// The numbers were completely divided. There is no need to round it up.
		Result = Number;
	Else
		If RoundOffOption = PredefinedValue("Enum.RoundingOptions.AlwaysForBenefitOfEnterprise") Then
			// With the rounding order "0.05", 0.371 should be rounded to 0.4
			Result = RoundingPrecision * (NumberOfIntegerIntervals + 1);
		ElsIf RoundOffOption = PredefinedValue("Enum.RoundingOptions.RoundingOptionForBenefitOfCustomer") Then
			// With the rounding order "0.05", 0.371 should be rounded to 0.35
			Result = RoundingPrecision * (NumberOfIntegerIntervals);
		Else
			// With the rounding order "0.05", 0.371 should be rounded to 0.35,
			// and 0.376 to 0.4.
			Result = RoundingPrecision * Round(NumberOfIntervals_, 0, RoundMode.Round15as20);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction // Round up the price()

// Applies "psychological rounding" to a number
//
// Parameters:
//  Number                     - Number - the number to which rounding is applied.
//  SmartRounding - Number - number, the value of "psychological rounding".
//
// Returns:
//  Number - The result of applying "psychological rounding" to a number.
//
Function ApplyPsychologicalRounding(Number, SmartRounding) Export
	
	If Number = 0 Or SmartRounding = 0 Then
		Return Number;
	Else
		RoundingResult = Number - SmartRounding;
		Return ?(RoundingResult < Number, RoundingResult, Number);
	EndIf;
	
EndFunction // Apply Psychological Rounding()

#EndRegion

#Region ProceduresAndFunctionsForSubstitutingQueryTexts

// The text of the request is the register of item price information.
// 
// Parameters:
//  SourceOfGoods - String - name of the table with products
//  DateParameter - String - parameter name Date
//  ConditionTypeOfPrice - Undefined, Structure - condition by type of prices
//  UsePriceManagementSystem25 - Undefined, Boolean - Pricing 2.5 is used
// 
// Returns:
//  String - Request text register of item price information
Function QueryTextInformationRegisterItemsPrices(SourceOfGoods,
													DateParameter = "&Date", 
													ConditionTypeOfPrice = Undefined,
													UsePriceManagementSystem25 = Undefined) Export
	
	If UsePriceManagementSystem25 = Undefined Then
		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	EndIf;
	
	If UsePriceManagementSystem25 Then
		QueryText = 
		"InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&DateParameter, DAY),
		|				&ConditionTypeOfPrice1 AND
		|				(&ConditionTypeOfPrice2, Products,PricingVariant,PricingBatch,PricingPackage) IN (
		|					SELECT
		|						&ConditionTypeOfPrice3,
		|						Goods.Products,
		|						Goods.PricingVariant,
		|						Goods.PricingBatch,
		|						Goods.PricingPackage
		|					FROM
		|						&SourceOfGoods AS Goods
		|					)
		|			)";
	Else
		QueryText = 
		"InformationRegister.ItemsPrices.SliceLast(ENDOFPERIOD(&DateParameter, DAY),
		|				&ConditionTypeOfPrice1 AND
		|				(&ConditionTypeOfPrice2, Products,Characteristic) IN (
		|					SELECT
		|						&ConditionTypeOfPrice3,
		|						Goods.Products,
		|						Goods.Characteristic
		|					FROM
		|						&SourceOfGoods AS Goods
		|					)
		|			)";
	EndIf;

	QueryText = StrReplace(QueryText, "&SourceOfGoods", SourceOfGoods);
	
	ReplacementTextConditionTypeOfPrice1 = "TRUE";
	ReplacementTextConditionTypeOfPrice2 = "";
	ReplacementTextConditionTypeOfPrice3 = "";
	
	If TypeOf(ConditionTypeOfPrice) = Type("Structure") Then
		If ConditionTypeOfPrice.Property("Constant") Then
			ReplacementTextConditionTypeOfPrice1 = 
				"PriceKind IN (
				|	SELECT
				|		&ConstantName AS PriceKind
				|	FROM
				|		Constants AS Constants)";
				
			ReplacementTextConditionTypeOfPrice1 = StrReplace(ReplacementTextConditionTypeOfPrice1, "&ConstantName", "Constants." + ConditionTypeOfPrice.Constant);
		ElsIf ConditionTypeOfPrice.Property("Parameter") Then
			ReplacementTextConditionTypeOfPrice1 = 
				"PriceKind = &ParameterName";
			ReplacementTextConditionTypeOfPrice1 = StrReplace(ReplacementTextConditionTypeOfPrice1, "&ParameterName", ConditionTypeOfPrice.Parameter);
		ElsIf ConditionTypeOfPrice.Property("InTable") Then 
			ReplacementTextConditionTypeOfPrice2 = "PriceKind,";
			If StrFind(ConditionTypeOfPrice.InTable, "&") = 0 Then
				ReplacementTextConditionTypeOfPrice3 = "Goods.";
			EndIf;
			ReplacementTextConditionTypeOfPrice3 = ReplacementTextConditionTypeOfPrice3 + ConditionTypeOfPrice.InTable + ",";
		EndIf;
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionTypeOfPrice1", ReplacementTextConditionTypeOfPrice1);
	QueryText = StrReplace(QueryText, "&ConditionTypeOfPrice2,", ReplacementTextConditionTypeOfPrice2);
	QueryText = StrReplace(QueryText, "&ConditionTypeOfPrice3,", ReplacementTextConditionTypeOfPrice3);
	
	QueryText = StrReplace(QueryText, "&DateParameter", DateParameter);
	
	Return QueryText;
	
EndFunction

// The text of the request is the register of information of the price of the item connection condition.
// 
// Parameters:
//  SourceOfGoods - String - name of the table with products
//  SourceOfPrices - String - name of the table with prices
//  SourceOfPriceTypes - String, Undefined - value, if it is necessary to connect to the connection by the type of prices
//  UsePriceManagementSystem25 - Undefined, Boolean - Pricing 2.5 is used
// 
// Returns:
//  String - Request text information register item prices Connection condition
Function RequestTextInformationRegisterItemPricesConnectionCondition(SourceOfGoods,
																	SourceOfPrices,
																	SourceOfPriceTypes = Undefined,
																	UsePriceManagementSystem25 = Undefined) Export
	
	If UsePriceManagementSystem25 = Undefined Then
		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	EndIf;
	
	QueriesTexts = New Array();
	If UsePriceManagementSystem25 Then
		QueryText = "
		|			&SourceOfGoods.Products = &SourceOfPrices.Products
		|			AND &SourceOfGoods.PricingVariant = &SourceOfPrices.PricingVariant
		|			AND &SourceOfGoods.PricingBatch = &SourceOfPrices.PricingBatch
		|			AND &SourceOfGoods.PricingPackage = &SourceOfPrices.PricingPackage";
	Else
		QueryText = "
		|			&SourceOfGoods.Products = &SourceOfPrices.Products
		|			AND &SourceOfGoods.Characteristic = &SourceOfPrices.Characteristic";
	EndIf;
	QueriesTexts.Add(QueryText);

	If SourceOfPriceTypes <> Undefined Then
		QueriesTexts.Add(Chars.LF + "		And ");
		QueriesTexts.Add(SourceOfPriceTypes);
		QueriesTexts.Add(" = &SourceOfPrices.PriceKind");
	EndIf;
		
	QueryText = StrConcat(QueriesTexts);
	
	QueryText = StrReplace(QueryText, "&SourceOfGoods", SourceOfGoods);
	
	QueryText = StrReplace(QueryText, "&SourceOfPrices", SourceOfPrices);
	
	Return QueryText;
	
EndFunction

// The text of the request for a temporary table with an addendum for pricing.
// 
// Parameters:
//  Settings - See SettingsForTemporaryTableWithAdditionForPricing
//  UsePriceManagementSystem25 - Undefined - Pricing 2.5 is used
// 
// Returns:
//  String - The text of the temporary table request with an addendum for pricing
Function TextOfTemporaryTableRequestWithAddendumForPricing(Settings,
																	UsePriceManagementSystem25 = Undefined) Export
	
	If UsePriceManagementSystem25 = Undefined Then
		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	EndIf;
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&ProductTableFields
	|INTO 
	|	#ReceiverOfGoods
	|FROM
	|	#SourceOfGoods
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON ItemKinds.Ref = &SourceOfTypeOfNomenclature
	|";
	
	QueryText = StrReplace(QueryText, "#SourceOfGoods", Settings.SourceOfGoods);
	QueryText = StrReplace(QueryText, "#ReceiverOfGoods", Settings.ReceiverOfGoods);

	QueryFields = New Array();
	QueryFields.Add(Settings.SourceOfGoods + "." + Settings.ProductsField);
	
	If ValueIsFilled(Settings.CharacteristicField) Then
		QueryFields.Add(Settings.SourceOfGoods + "." + Settings.CharacteristicField);
	EndIf;
	If ValueIsFilled(Settings.FieldSeries) Then
		QueryFields.Add(Settings.SourceOfGoods + "." + Settings.FieldSeries);
	EndIf;
	If ValueIsFilled(Settings.PackagingField) Then
		QueryFields.Add(Settings.SourceOfGoods + "." + Settings.PackagingField);
	EndIf;

	QueryFields.Add(TextOfFieldsForPricing(Settings,,UsePriceManagementSystem25));
	
	If ValueIsFilled(Settings.ListOfOtherFields) Then
		ListOfOtherFields = StrSplit(Settings.ListOfOtherFields, ",", False);
		For Each Field In ListOfOtherFields Do
			QueryFields.Add(Settings.SourceOfGoods + "." + TrimAll(Field));
		EndDo;
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ProductTableFields", StrConcat(QueryFields, "," + Chars.LF));
	
	QueryText = StrReplace(QueryText, "&SourceOfTypeOfNomenclature", Settings.SourceOfGoods + "." + Settings.ProductsField + ".ProductKind");
	
	Return QueryText;
	
EndFunction

// The text of the fields for pricing.
// 
// Parameters:
//  Settings - Structure - Settings:
// * SourceOfGoods - String -
// * ReceiverOfGoods - String -
// * ProductsField - String -
// * CharacteristicField - String -
// * FieldSeries - String -
// * PackagingField - String -
// * ListOfOtherFields - String -
// ForDimensionFields  - Boolean - True, for a hollow grouping, do not assign synonyms
//  UsePriceManagementSystem25 - Undefined - Pricing 2.5 is used
// 
// Returns:
//  String - Text of pricing fields
Function TextOfFieldsForPricing(Settings, 
										ForDimensionFields = False,
										UsePriceManagementSystem25 = Undefined) Export
	
	QueryFields = New Array();

	If UsePriceManagementSystem25 = Undefined Then
		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	EndIf;
	
	If Not UsePriceManagementSystem25 Then
		Return "";
	EndIf;
	
	If ValueIsFilled(Settings.CharacteristicField) Then
		FieldText =	"CASE
						|	WHEN
						|		ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
						|		THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
						|	ELSE ISNULL(" + Settings.SourceOfGoods + "." + Settings.CharacteristicField + ".ItemsCharacteristicForPricing, 
						|			VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef))
						|END";
	Else
		FieldText =	"VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)";
	EndIf;
	FieldText = FieldText + ?(ForDimensionFields, ""," AS PricingVariant");
	QueryFields.Add(FieldText);
	
	If ValueIsFilled(Settings.FieldSeries) Then
		FieldText =	"CASE
						|	WHEN
						|		ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
						|			OR "+ Settings.SourceOfGoods + "." + Settings.FieldSeries + " = VALUE(Catalog.ItemsBatches.EmptyRef)
						|		THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
						|	ELSE ISNULL(" + Settings.SourceOfGoods + "." + Settings.FieldSeries + ".ItemsBatchForPricing, 
						|			VALUE(Catalog.ItemsBatchesForPricing.EmptyRef))
						|END";
	Else
		FieldText =	"VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)";
	EndIf;
	FieldText = FieldText + ?(ForDimensionFields, ""," AS PricingBatch");
	QueryFields.Add(FieldText);
	
	If ValueIsFilled(Settings.PackagingField) Then
		FieldText =	"CASE
						|	WHEN
						|		ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
						|		THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
						|	ELSE " + Settings.SourceOfGoods + "." + Settings.PackagingField + "
						|END";
	Else
		FieldText =	"VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)";
	EndIf;
	FieldText = FieldText + ?(ForDimensionFields, ""," AS PricingPackage");
	
	QueryFields.Add(FieldText);
	
	Return StrConcat(QueryFields, "," + Chars.LF);
	
EndFunction

// Settings for a temporary table with an addition for pricing.
// 
// Returns:
//  Structure - Settings For A Temporary Table With An Addition For Pricing:
// * SourceOfGoods - String - Names of the source table of goods
// * ReceiverOfGoods - String - Names of the goods receiver table
// * ProductsField - String - Name of the item field. If not, you need to assign a blank string
// * CharacteristicField - String - Name of the characteristic field. If not, you need to assign a blank string
// * FieldSeries - String - Name of the series field. If not, you need to assign a blank string
// * PackagingField - String - Name of the packaging field. If not, you need to assign a blank string
// * ListOfOtherFields - String - all other fields of the product source are separated by commas
//
Function SettingsForTemporaryTableWithAdditionForPricing() Export
	
	Settings = New Structure();
	
	Settings.Insert("SourceOfGoods", "");
	Settings.Insert("ReceiverOfGoods", "");
	Settings.Insert("ProductsField", "Products");
	Settings.Insert("CharacteristicField", "Characteristic");
	Settings.Insert("FieldSeries", "Series");
	Settings.Insert("PackagingField", "Package");
	Settings.Insert("ListOfOtherFields", "");
	
	Return Settings;
	
EndFunction

// Request text register of Product price information indexing.
// 
// Parameters:
//  UsePriceManagementSystem25 - Undefined, Boolean - Pricing 2.5 is used
// 
// Returns:
//  String - The Text Of The Request Register Of Information Prices Products Indexing
Function QueryTextRegisterOfInformationPricesProductsIndexing(UsePriceManagementSystem25 = Undefined) Export

	If UsePriceManagementSystem25 = Undefined Then
		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	EndIf;

	If UsePriceManagementSystem25 Then
		ReplacementText = "Products,
			|	PricingVariant,
			|	PricingBatch,
			|	PricingPackage,
			|	PriceKind";
	Else
		ReplacementText = "Products,
			|	Characteristic,
			|	PriceKind";
	EndIf;

	Return ReplacementText;

EndFunction

#EndRegion

#EndRegion
