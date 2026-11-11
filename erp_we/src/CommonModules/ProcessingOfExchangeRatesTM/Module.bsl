
#Region Public

#Region ProceduresAndFunctionsOfWorkingWithCurrencies

// The function gets the conversion factor from the current currency to the new currency.
//
// Parameters:
//	CurrentCurrency - CatalogRef.Currencies - The current document currency
//	NewCurrency - CatalogRef.Currencies - The new currency of the document
//	Date - Date - document date.
//	BaseCurrency - CatalogRef.Currencies - The base currency against which you need to get the rate.
//											If Undefined, then the rates are obtained relative to the value from the base constant of the default.
//	ParametersOfContractCourseOption - See ProcessingOfExchangeRatesTM.ParametersOfContractCourseOption
//
// Returns:
//	Number - Conversion factor to the new currency.
//
Function GetConversionFactorFromCurrencyToCurrency(CurrentCurrency, NewCurrency, Date, Val BaseCurrency = Undefined, ParametersOfContractCourseOption = Undefined) Export
	
	If Not ValueIsFilled(BaseCurrency) Then
		BaseCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	If ParametersOfContractCourseOption <> Undefined 
		And ParametersOfContractCourseOption.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract 
		And (ParametersOfContractCourseOption.ARAPCurrency = CurrentCurrency 
			Or ParametersOfContractCourseOption.ARAPCurrency = NewCurrency) Then
			If CurrentCurrency <> NewCurrency Then
				If CurrentCurrency = ParametersOfContractCourseOption.ARAPCurrency Then
					CurExchangeRate = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(ParametersOfContractCourseOption.Contract, Date);
				Else
					CurExchangeRate = GetCurrencyRate(CurrentCurrency, Date, BaseCurrency);
				EndIf;
				If NewCurrency = ParametersOfContractCourseOption.ARAPCurrency Then
					NewCurrencyRate = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(ParametersOfContractCourseOption.Contract, Date);
				Else
					NewCurrencyRate = GetCurrencyRate(NewCurrency, Date, BaseCurrency);
				EndIf;
				If NewCurrencyRate.CourseNumerator * CurExchangeRate.CourseDenominator <> 0 Then
					ConversionFactor_ = 
						(CurExchangeRate.CourseNumerator * NewCurrencyRate.CourseDenominator) 
						/ (NewCurrencyRate.CourseNumerator * CurExchangeRate.CourseDenominator);
				Else
					ConversionFactor_ = 0;
				EndIf;
			Else
				ConversionFactor_ = 1;
			EndIf;
	Else
		ARAPObject = Catalogs.ARAPObjects.EmptyRef();
		If ParametersOfContractCourseOption <> Undefined Then
			ARAPObject = ParametersOfContractCourseOption.ARAPObject;
		EndIf;
		If CurrentCurrency <> NewCurrency Then
			CurExchangeRate = GetCurrencyRate(CurrentCurrency, Date, BaseCurrency, ARAPObject);
			NewCurrencyRate = GetCurrencyRate(NewCurrency, Date, BaseCurrency, ARAPObject);
			If NewCurrencyRate.CourseNumerator * CurExchangeRate.CourseDenominator <> 0 Then
				ConversionFactor_ = 
					(CurExchangeRate.CourseNumerator * NewCurrencyRate.CourseDenominator) 
					/ (NewCurrencyRate.CourseNumerator * CurExchangeRate.CourseDenominator);
			Else
				ConversionFactor_ = 0;
			EndIf;
		Else
			ConversionFactor_ = 1;
		EndIf;
	EndIf;
	
	Return ConversionFactor_;
	
EndFunction // Get the performance of the account of the currency of the currency()

// Returns the currency exchange rate on the date.
//
// Parameters:
//   Currency    - CatalogRef.Currencies - the currency for which the exchange rate is obtained.
//   DateOfCourse - Date - the date on which the course is obtained.
//   BaseCurrency - CatalogRef.Currencies - The currency against which you need to get the exchange rate
//   ARAPObject - CatalogRef.ARAPObjects - Optional, a settlement object that determines the course option of the Contract
//   
// Returns: 
//   Structure:
//    * CourseNumerator - Number - The numerator of the currency exchange rate on the specified date.
//    * CourseDenominator - Number - The denominator of the currency exchange rate on the specified date.
//    * Currency    - CatalogRef.Currencies - the reference currency.
//    * DateOfCourse - Date - date the course was received.
//    * BaseCurrency - CatalogRef.Currencies - The currency against which the exchange rate is received.
//
Function GetCurrencyRate(Val Currency, Val DateOfCourse, Val BaseCurrency = Undefined, ARAPObject = Undefined) Export
	
	If Not ValueIsFilled(BaseCurrency) Then
		BaseCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	If Currency = BaseCurrency Then
		Result = New Structure();
		Result.Insert("Currency",    Currency);
		Result.Insert("DateOfCourse", DateOfCourse);
		Result.Insert("BaseCurrency", BaseCurrency);
		Result.Insert("CourseNumerator", 1);
		Result.Insert("CourseDenominator", 1);
	ElsIf ValueIsFilled(ARAPObject) Then
		ExchangeRates = GetCurrencyExchangeRateForSettlementObjects(
			CommonClientServer.ValueInArray(Currency),
			DateOfCourse,
			BaseCurrency,
			CommonClientServer.ValueInArray(ARAPObject));
		Result = New Structure();
		Result.Insert("Currency",    Currency);
		Result.Insert("DateOfCourse", DateOfCourse);
		Result.Insert("BaseCurrency", BaseCurrency);
		Result.Insert("CourseNumerator", 0);
		Result.Insert("CourseDenominator", 0);
		If ExchangeRates.Count() > 0 Then
			FillPropertyValues(Result, ExchangeRates[0]);
		EndIf;
	Else
		Result = InformationRegisters.RelativeExchangeRates.GetLast(DateOfCourse, New Structure("Currency, BaseCurrency", Currency, BaseCurrency));
		Result.Insert("Currency",    Currency);
		Result.Insert("DateOfCourse", DateOfCourse);
		Result.Insert("BaseCurrency", BaseCurrency);
	EndIf;
	
	Return Result;
	
EndFunction

// The function gets coefficients for converting amounts from the document currency to the currency of mutual settlements,
// to the currencies of management and regulated accounting.
//
// Parameters:
//	DocumentCurrency - CatalogRef.Currencies - The document currency
//	ARAPCurrency - CatalogRef.Currencies - Currency of mutual settlements of the document
//	Period - Date - Document date
//	Organization - CatalogRef.Companies - Organization of the document
//	CourseNumeratorOfDocument - Number - Optional, the exchange rate is the numerator of the document currency
//	CourseDenominatorDocument - Number - Optional, the exchange rate is the denominator of the document currency.
//	ARAPObject - CatalogRef.ARAPObjects - Optional,A calculation object for determining the source of the currency exchange rate.
//
// Returns:
//   Structure - Currency exchange rate parameters:
//	   * ConversionRateToSettlementCurrency 	- Number - Conversion coefficient to the currency of mutual settlements.
//	   * ConversionRateToManCurrency 			- Number - Conversion coefficient to the currency of management accounting.
//	   * FactorOfConversionToCurrencyOfRegul 			- Number - Conversion coefficient to the currency of regulated accounting.
//
Function GetCurrencyConversionRates_(DocumentCurrency, ARAPCurrency, Period, Organization, CourseNumeratorOfDocument = Undefined, CourseDenominatorDocument = Undefined, ARAPObject = Undefined) Export

	CurrencyOfMan  = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	Query = New Query;
	If ValueIsFilled(ARAPObject) Then
		ArrayOfCurrencies = New Array;
		ArrayOfCurrencies.Add(DocumentCurrency);
		ArrayOfCurrencies.Add(ARAPCurrency);
		ArrayOfCurrencies.Add(CurrencyOfMan);
		ArrayOfCurrencies.Add(ComplCurrency);
		RateTable = GetCurrencyExchangeRateForSettlementObjects(
			ArrayOfCurrencies, 
			Period, 
			ComplCurrency, 
			CommonClientServer.ValueInArray(ARAPObject));
	Else
		QueryText = "
			|SELECT
			|	RelativeExchangeRates.Currency AS Currency,
			|	RelativeExchangeRates.CourseNumerator AS CourseNumerator,
			|	RelativeExchangeRates.CourseDenominator AS CourseDenominator
			|FROM
			|	InformationRegister.RelativeExchangeRates.SliceLast(&Period,
			|		(Currency = &CurrencyOfMan OR Currency = &ComplCurrency OR Currency = &ARAPCurrency OR Currency = &DocumentCurrency) AND BaseCurrency = &ComplCurrency
			|	) AS RelativeExchangeRates
			|";
		Query.SetParameter("DocumentCurrency",      DocumentCurrency);
		Query.SetParameter("ARAPCurrency", ARAPCurrency);
		Query.SetParameter("Period",     Period);
		Query.SetParameter("CurrencyOfMan",  CurrencyOfMan);
		Query.SetParameter("ComplCurrency", ComplCurrency);
		Query.Text = QueryText;
		RateTable = Query.Execute().Unload();
	EndIf;

	ExchangeRateNumeratorOfManSCurrency = 1;
	ExchangeRateDenominatorCurrencyMan = 1;

	ExchangeRateNumeratorOfLocalCurrency = 1;
	ExchangeRateDenominatorOfLocalCurrency = 1;

	ExchangeRateNumeratorOfMutualSettlements = 1;
	TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;

	RateDocumentCurrencyNumerator = 1;
	RateDocumentCurrencyDenominator = 1;

	For Each CourseLine In RateTable Do

		If CourseLine.Currency = CurrencyOfMan Then

			ExchangeRateNumeratorOfManSCurrency = CourseLine.CourseNumerator;
			ExchangeRateDenominatorCurrencyMan = CourseLine.CourseDenominator;

		EndIf;

		If CourseLine.Currency = ComplCurrency Then

			ExchangeRateNumeratorOfLocalCurrency = CourseLine.CourseNumerator;
			ExchangeRateDenominatorOfLocalCurrency = CourseLine.CourseDenominator;

		EndIf;

		If CourseLine.Currency = ARAPCurrency Then

			ExchangeRateNumeratorOfMutualSettlements = CourseLine.CourseNumerator;
			TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseLine.CourseDenominator;

		EndIf;

		If CourseLine.Currency = DocumentCurrency Then

			RateDocumentCurrencyNumerator = CourseLine.CourseNumerator;
			RateDocumentCurrencyDenominator = CourseLine.CourseDenominator;

		EndIf;
	EndDo;

	If ValueIsFilled(CourseNumeratorOfDocument) Then
		
		If DocumentCurrency = ComplCurrency And Not ARAPCurrency = ComplCurrency Then
			ExchangeRateNumeratorOfMutualSettlements = CourseNumeratorOfDocument;
			TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseDenominatorDocument;
			RateDocumentCurrencyNumerator = 1;
			RateDocumentCurrencyDenominator = 1;
		Else
			RateDocumentCurrencyNumerator = CourseNumeratorOfDocument;
			RateDocumentCurrencyDenominator = CourseDenominatorDocument;
			ExchangeRateNumeratorOfMutualSettlements = 1;
			TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
		EndIf;
		
	EndIf;
	
	Result = New Structure("ConversionRateToSettlementCurrency, ConversionRateToManCurrency, FactorOfConversionToCurrencyOfRegul");

	Result.ConversionRateToManCurrency  = RateDocumentCurrencyNumerator * ExchangeRateDenominatorCurrencyMan / (RateDocumentCurrencyDenominator * ExchangeRateNumeratorOfManSCurrency); 
	Result.FactorOfConversionToCurrencyOfRegul = RateDocumentCurrencyNumerator * ExchangeRateDenominatorOfLocalCurrency / (RateDocumentCurrencyDenominator * ExchangeRateNumeratorOfLocalCurrency);
	Result.ConversionRateToSettlementCurrency = RateDocumentCurrencyNumerator * TheExchangeRateIsTheDenominatorOfMutualSettlements / (RateDocumentCurrencyDenominator * ExchangeRateNumeratorOfMutualSettlements);

	Return Result;

EndFunction

// The function gets the conversion factor from the current currency to the new currency.
//
// Parameters:
//	CurrentCurrency - CatalogRef.Currencies - The current document currency
//	NewCurrency - CatalogRef.Currencies - The new currency of the document
//	Date - Date - document date.
//	BaseCurrency - CatalogRef.Currencies - The base currency against which you need to get the rate.
//											If Undefined, then the rates are obtained relative to the value from the base constant of the default.
//	ARAPObjects - Array of CatalogRef.ARAPObjects
//
// Returns:
//	ValueTable - TableOfCoefficients:
//		* ARAPObject - CatalogRef.ARAPObjects - 
//		* ZoomRatio - Number - 
//
Function GetConversionFactorsForCalculationObjects(CurrentCurrency, NewCurrency, Date, Val BaseCurrency = Undefined, ARAPObjects) Export
	
	If Not ValueIsFilled(BaseCurrency) Then
		BaseCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	TableOfCoefficients = New ValueTable;
	TableOfCoefficients.Columns.Add("ARAPObject", New TypeDescription("CatalogRef.ARAPObjects"));
	TableOfCoefficients.Columns.Add("ZoomRatio", New TypeDescription("Number"));
	ArrayOfCurrencies = New Array;
	ArrayOfCurrencies.Add(CurrentCurrency);
	ArrayOfCurrencies.Add(NewCurrency);
	RateTable = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateForSettlementObjects(
		ArrayOfCurrencies, 
		Date,
		BaseCurrency,
		ARAPObjects);
	// For an empty calculation object, you need to add 2 rows of the course table
	If ARAPObjects.Find(Catalogs.ARAPObjects.EmptyRef()) <> Undefined Then
		CourseLine = RateTable.Add();
		FillPropertyValues(CourseLine, GetCurrencyRate(CurrentCurrency, Date, BaseCurrency));
		CourseLine.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
		CourseLine = RateTable.Add();
		FillPropertyValues(CourseLine, GetCurrencyRate(NewCurrency, Date, BaseCurrency));
		CourseLine.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
	EndIf;
	
	RateTable.Indexes.Add("ARAPObject");
	For Each ARAPObject In ARAPObjects Do
		CurrencyStrings = RateTable.FindRows(New Structure("ARAPObject", ARAPObject));
		ExchangeRateNumeratorOfCurrentCurrency   = 1;
		ExchangeRateDenominatorOfCurrentCurrency = 1;
		ExchangeRateNumeratorOfNewCurrency     = 1;
		ExchangeRateDenominatorOfNewCurrency   = 1;
		For Each CourseLine In CurrencyStrings Do
			If CourseLine.Currency = CurrentCurrency Then
				ExchangeRateNumeratorOfCurrentCurrency   = CourseLine.CourseNumerator;
				ExchangeRateDenominatorOfCurrentCurrency = CourseLine.CourseDenominator;
			EndIf;
			If CourseLine.Currency = NewCurrency Then
				ExchangeRateNumeratorOfNewCurrency   = CourseLine.CourseNumerator;
				ExchangeRateDenominatorOfNewCurrency = CourseLine.CourseDenominator;
			EndIf;
		EndDo;
		NewRow = TableOfCoefficients.Add();
		NewRow.ARAPObject = ARAPObject;
		NewRow.ZoomRatio = 
			(ExchangeRateNumeratorOfCurrentCurrency * ExchangeRateDenominatorOfNewCurrency) 
				/ (ExchangeRateNumeratorOfNewCurrency * ExchangeRateDenominatorOfCurrentCurrency);
	EndDo;
	
	Return TableOfCoefficients;
	
EndFunction

// Returns the currency exchange rate on the date.
//
// Parameters:
//   Currency - Array from the Reference Link.Currencies - currencies for which the exchange rate is obtained.
//   DateOfCourse - Date - the date on which the course is obtained.
//   BaseCurrency - CatalogRef.Currencies - The currency you need to get the exchange rate for
//   The object of accounts is an array from the Reference Link.Settlement objectsare settlement objects that determine the course option of the Contract
//   
// Returns: 
//   ValueTable:
//    * CourseNumerator    - Number - The numerator of the currency exchange rate on the specified date.
//    * CourseDenominator  - Number - The denominator of the currency exchange rate on the specified date.
//    * Currency           - CatalogRef.Currencies - the reference currency.
//    * ARAPObject   - CatalogRef.ARAPObjects - The object of calculations for which the course is determined
//    * DateOfCourse        - Date - date the course was received.
//    * BaseCurrency    - CatalogRef.Currencies - The currency against which the exchange rate is received.
//
Function GetCurrencyExchangeRateForSettlementObjects(Currencies, DateOfCourse, Val BaseCurrency = Undefined, ARAPObjects) Export
	
	If Not ValueIsFilled(BaseCurrency) Then
		BaseCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	Query = New Query;
	Query.Text = TextOfRequestForCoursesOnObjectOfCalculations();
		Query.SetParameter("CurrencyOfMan", SettingsValueCached.ManagementAccountingCurrency());
	Query.SetParameter("ARAPObjects", ARAPObjects);
	Query.SetParameter("Period", DateOfCourse);
	Query.SetParameter("ArrayOfCurrencies", Currencies);
	Query.SetParameter("ComplCurrency", BaseCurrency);
	
	Return Query.Execute().Unload();
	
EndFunction

// This function converts the document amount from the current currency to the new currency.
//
// Parameters:
//	DocumentAmount - Number - The current amount of the document
//	CurrentCurrency - CatalogRef.Currencies - The current document currency
//	NewCurrency - CatalogRef.Currencies - The new currency of the document
//	Date - Date - document date.
//	BaseCurrency - CatalogRef.Currencies - The currency against which it is necessary to receive rates.
//
// Returns:
//	Number - New amount of the document
//
Function ConvertDocumentAmountToCurrency(DocumentAmount, CurrentCurrency, NewCurrency, Date, BaseCurrency) Export
	
	StructureOfCurExchangeRates = GetCurrencyRate(CurrentCurrency, Date, BaseCurrency);
	StructureOfNewCurrencyRates = GetCurrencyRate(NewCurrency, Date, BaseCurrency);
	
	NewDocumentAmount = ConvertAtRate(DocumentAmount, StructureOfCurExchangeRates, StructureOfNewCurrencyRates);
	
	Return NewDocumentAmount;
	
EndFunction // Recalculate the sum of the document in the currency()

// Returns the exchange rate of the management accounting currency relative to the regulated currency.
//
// Parameters:
//  Date - Date - The date on which you need to get the currency exchange rate.
//  LocalAccountingCurrency - CatalogRef.Currencies - Currency of regulated accounting.
//  
// Returns:
//  Number - Management accounting currency exchange rate
//
Function GetExchangeRateOfManagementAccounting(Date, LocalAccountingCurrency) Export

	Filter = New Structure("Currency, BaseCurrency", 
				Constants.ManagementAccountingCurrency.Get(), LocalAccountingCurrency);
	RateStructure  = InformationRegisters.RelativeExchangeRates.GetLast(Date, Filter);
	Rate = RateStructure.CourseNumerator / RateStructure.CourseDenominator;
	Return Rate;

EndFunction

// The procedure fills in the document's default course number and Course signer
//
// Parameters:
//	CourseNumerator - Number - Course numerator for calculation
//	CourseDenominator - Number - The rate indicator for the calculation
//	DocumentCurrency - CatalogRef.Currencies - The document currency
//	ARAPCurrency - CatalogRef.Currencies - Currency of mutual settlements of the document
//	Organization - CatalogRef.Companies - Organization of the document
//	Date - Date - Optional, the date of the document.
//	Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - Contract for checking for course compliance
//	ARAPObject - CatalogRef.ARAPObjects - The account object used to determine the currency exchange rate
//
Procedure FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, DocumentCurrency, ARAPCurrency, Organization, Date = Undefined, Contract = Undefined, ARAPObject = Undefined) Export
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	If ValueIsFilled(Organization) Then
		BaseCurrency = CurrencyOfComplianceAccounting;
	Else
		BaseCurrency = Constants.DefaultBaseCurrency.Get();
	EndIf;
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	ContractRateOption = Enums.ContractRateOptions.Mutable;
	If ValueIsFilled(Contract) Then
		ContractRateOption = Common.ObjectAttributeValue(Contract, "ContractRateOption");
	EndIf;
	
	If DocumentCurrency = ARAPCurrency 
		Or Not ValueIsFilled(DocumentCurrency) 
		Or Not ValueIsFilled(ARAPCurrency) Then
		
		CourseNumerator = 1;
		CourseDenominator = 1;
		Return;
		
	ElsIf DocumentCurrency = CurrencyOfComplianceAccounting And Not ARAPCurrency = CurrencyOfComplianceAccounting Then
		
		If ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
			RateStructure = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(Contract, Date);
		Else
			RateStructure = GetCurrencyRate(ARAPCurrency, Date, BaseCurrency, ARAPObject);
		EndIf;
		
	ElsIf Not DocumentCurrency = CurrencyOfComplianceAccounting And ARAPCurrency = CurrencyOfComplianceAccounting Then
		
		RateStructure = GetCurrencyRate(DocumentCurrency, Date, BaseCurrency, ARAPObject);
		
	Else
		
		If ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
			MutualSettlementsExchangeRate = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(Contract, Date);
		Else
			MutualSettlementsExchangeRate = GetCurrencyRate(ARAPCurrency, Date, BaseCurrency, ARAPObject);
		EndIf;
		DocumentExchangeRate      = GetCurrencyRate(DocumentCurrency, Date, BaseCurrency, ARAPObject);
		RateStructure           = GetCrossCurrencyExchangeRate(DocumentExchangeRate, MutualSettlementsExchangeRate);
		
	EndIf;
	
	CourseNumerator      = RateStructure.CourseNumerator;
	CourseDenominator = RateStructure.CourseDenominator;
	
EndProcedure

// The function returns the cross rate of two currencies
//
// Parameters:
//	Currency1 - Structure - Exchange rate parameters of the currency against which the exchange rate is calculated:
//       * CourseNumerator      - Number - The exchange rate relative to the currency of regulated accounting.
//       * CourseDenominator - Number - The multiplicity of the currency relative to the currency of regulated accounting.
//	Currency2 - Structure - Parameters of the exchange rate of the currency, the rate of which is calculated:
//       * CourseNumerator      - Number - The exchange rate relative to the currency of regulated accounting.
//       * CourseDenominator - Number - Multiplicity relative to the currency of regulated accounting.
//	Accuracy - Number - the number of decimal places to round the numerator to.
//
// Returns: 
//   Structure - Cross-course parameters:
//       * CourseNumerator - Number - The numerator of the cross-course
//       * CourseDenominator - Number - Cross-course denominator
//
Function GetCrossCurrencyExchangeRate(Currency1, Currency2, Accuracy = Undefined) Export
	
	If Currency1.CourseNumerator <> 0
		And Currency1.CourseDenominator <> 0
		And Currency2.CourseNumerator <> 0
		And Currency2.CourseDenominator <> 0 Then
			
			NumeratorIsGiven = Currency1.CourseNumerator * Currency2.CourseDenominator / (Currency2.CourseNumerator * Currency1.CourseDenominator);
			DenominatorGiven = 1;
			
			If NumeratorIsGiven < 1 Then
				While NumeratorIsGiven * 10 < 1 Do
					NumeratorIsGiven = NumeratorIsGiven * 10;
					DenominatorGiven = DenominatorGiven * 10;
				EndDo;
			EndIf;
	Else
		NumeratorIsGiven = 1;
		DenominatorGiven = 1;
	EndIf;
	
	If Accuracy = Undefined Then
		Accuracy = Metadata.DefinedTypes.CurrencyExchangeRate.Type.NumberQualifiers.FractionDigits;
	EndIf;
	
	RateStructure = CurrencyExchangeRateStructure();
	RateStructure.CourseNumerator = Round(NumeratorIsGiven, Accuracy);
	RateStructure.CourseDenominator = DenominatorGiven;
	
	Return RateStructure;
	
EndFunction

// This function returns the structure of currency exchange rate parameters
//
// Parameters:
//	CourseNumerator - Number - Optional, the numerator of the currency exchange rate.
//	CourseDenominator - Number - Optional, the denominator of the currency exchange rate.
//
// Returns: 
//   Structure - Currency exchange rate parameters:
//	   * CourseNumerator - Number - exchange rate.
//	   * CourseDenominator - Number - multiplicity of the course.
//
Function CurrencyExchangeRateStructure(CourseNumerator = 0, CourseDenominator = 0) Export
	Structure = New Structure;
	Structure.Insert("CourseNumerator", CourseNumerator);
	Structure.Insert("CourseDenominator", CourseDenominator);
	Return Structure;
EndFunction

// Converts the amount from one currency to another.
//
// Parameters:
//  Sum          - Number - amount to be recalculated;
//  BaseCurrency - CatalogRef.Currencies - the currency against which the exchange rate is obtained;
//  SourceCurrency - CatalogRef.Currencies - currency to be converted;
//  NewCurrency    - CatalogRef.Currencies - the currency in which you want to convert;
//  Date           - Date - date of currency exchange rates.
//  ARAPObject - CatalogRef.ARAPObjects - Optional, a settlement object that determines the course option of the Contract
//
// Returns:
//  Number - recalculated amount.
//
Function ConvertToCurrency(Sum, BaseCurrency, SourceCurrency, NewCurrency, Date, ARAPObject = Undefined) Export
	
	Return ConvertAtRate(Sum,
		GetCurrencyRate(SourceCurrency, Date, BaseCurrency, ARAPObject),
		GetCurrencyRate(NewCurrency, Date, BaseCurrency, ARAPObject));
	
EndFunction

// Converts the amount from the current currency to the new currency based on their exchange rate parameters. 
// Options currencies it is possible to function Remotecharset.Getcurrencies.
//
// Parameters:
//   Sum - Number     - the amount should be recalculated.
//
//   SourceRateParameters - Structure - currency exchange rate parameters to be recalculated from:
//    * Currency - CatalogRef.Currencies - link to the currency being converted.
//    * CourseNumerator - Number - the exchange rate of the currency being converted.
//    * CourseDenominator - Number - multiplicity of the currency being recalculated.
//
//   NewRateParameters   - Structure - parameters of the currency exchange rate to be converted to:
//    * Currency - CatalogRef.Currencies - link to the currency that is being converted to.
//    * CourseNumerator - Number - the exchange rate is the numerator of the currency that is being converted.
//    * CourseDenominator - Number - the exchange rate is the denominator of the currency that is being converted.
//
// Returns: 
//   Number - the amount recalculated at the new exchange rate.
//
Function ConvertAtRate(Sum, SourceRateParameters, NewRateParameters) Export
	If SourceRateParameters.Currency = NewRateParameters.Currency
		Or (SourceRateParameters.CourseNumerator = NewRateParameters.CourseNumerator 
			And SourceRateParameters.CourseDenominator = NewRateParameters.CourseDenominator) Then
		
		Return Sum;
	EndIf;
	
	If SourceRateParameters.CourseNumerator = 0
		Or SourceRateParameters.CourseDenominator = 0
		Or NewRateParameters.CourseNumerator = 0
		Or NewRateParameters.CourseDenominator = 0 Then
		
		Return 0;
	EndIf;
	
	Return Round((Sum * SourceRateParameters.CourseNumerator * NewRateParameters.CourseDenominator) 
		/ (NewRateParameters.CourseNumerator * SourceRateParameters.CourseDenominator), 2);
EndFunction

// Generates a representation of the amount in words in the specified currency.
//
// Parameters:
//   AmountAsNumber - Number - the amount to be presented in words.
//   Currency - CatalogRef.Currencies - the currency in which to submit the amount.
//   OmitFractionalPart - Boolean - specify True if you want to get the amount without a fractional part (without kopecks).
//   LanguageCode - String - the language in which you want to get the amount in words.
//                       It consists of the ISO 639-1 language code and, optionally, the ISO 3166-1 country code, separated
//                       by an underscore. Examples: "en", "en_US", "en_GB", "ru", "ru_RU".
//                       The default value is the configuration language.
//
// Returns:
//   String - the amount in words.
//
Function GenerateAmountInWords(AmountAsNumber, Currency, OmitFractionalPart = False, Val LanguageCode = Undefined) Export
	
	If Not ValueIsFilled(LanguageCode) Then
		LanguageCode = Common.DefaultLanguageCode();
	EndIf;
	
	Sum = ?(AmountAsNumber < 0, -AmountAsNumber, AmountAsNumber);
	AmountInWordsParameters = Common.ObjectAttributeValue(Currency, "AmountInWordsParameters", , LanguageCode);
	Result = NumberInWords(Sum, "L=" + LanguageCode + ";DP=False", AmountInWordsParameters); // APK:1297 APK:1357
	If OmitFractionalPart And Int(Sum) = Sum Then
		Result = Left(Result, StrFind(Result, "0") - 1);
	EndIf;
	Return Result;
	
EndFunction

// Returns a list of base currencies that includes
// - currencies of regulated accounting of organizations
// - currency from the constant "Basic cryptocurrency to silence".
//
// Returns:
//  Array of CatalogRef.Currencies -
Function BaseCurrencies() Export
	
	BaseCurrencies = New Array;
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	BaseCurrencies.Currency AS Currency
	|FROM
	|	(SELECT
	|		Companies.LocalAccountingCurrency AS Currency
	|	FROM
	|		Catalog.Companies AS Companies
	|	WHERE
	|		NOT Companies.DeletionMark
	|
	|	UNION ALL
	|
	|	SELECT
	|		DefaultBaseCurrency.Value
	|	FROM
	|		Constant.DefaultBaseCurrency AS DefaultBaseCurrency) AS BaseCurrencies";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		BaseCurrencies.Add(Selection.Currency);
	EndDo;
	
	Return BaseCurrencies;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Constructor of parameters for the Contract course option
// 
// Returns:
//  Structure:
// * ContractRateOption - EnumRef.ContractRateOptions - The default value is Variable
// * Contract - Undefined, CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - Contract With A Fixed Course
// * ARAPCurrency - CatalogRef.Currencies - The currency of the Contract settlements
Function ParametersOfContractCourseOption() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("ContractRateOption", Enums.ContractRateOptions.Mutable);
	ParametersStructure.Insert("Contract", Undefined);
	ParametersStructure.Insert("ARAPCurrency", Catalogs.Currencies.EmptyRef());
	ParametersStructure.Insert("ARAPObject", Catalogs.ARAPObjects.EmptyRef());
	
	Return ParametersStructure;
	
EndFunction

// Performs synchronization between PCs.The exchange rate of the currency and RS.Relative courses are available.
//
// Parameters:
//  Source - InformationRegisterRecordSet - A set of PC records.The exchange rate of the currency or RS.Relative courses are available.
//
Procedure SynchronizeExchangeRates(Source) Export
	
	SetPrivilegedMode(True);
	
	BaseCurrency = Constants.LocalAccountingCurrency.Get();
	If Not ValueIsFilled(BaseCurrency) Then
		Return;
	EndIf;
	
	If TypeOf(Source) = Type("InformationRegisterRecordSet.ExchangeRates") Then
		Receiver = InformationRegisters.RelativeExchangeRates.CreateRecordSet();
		If Source.AdditionalProperties.Property("UploadingCurrencyExchangeRatesToRegionForEntirePeriod") Then
			Receiver.AdditionalProperties.Insert("UploadingCurrencyExchangeRatesToRegionForEntirePeriod");
		EndIf;
		RegisterName = Metadata.InformationRegisters.RelativeExchangeRates.Name;
	Else
		If Source.Filter.BaseCurrency.Value <> BaseCurrency Then
			Return;
		EndIf;
		Receiver = InformationRegisters.ExchangeRates.CreateRecordSet();
		BaseCurrency = Undefined;
		RegisterName = Metadata.InformationRegisters.ExchangeRates.Name;
	EndIf;
	
	If Source.Count() > 0 Then
		UpdateSynchronizedCourses(Source, Receiver, RegisterName, BaseCurrency);
	Else
		DeleteSynchronizedCourses(Source, Receiver, BaseCurrency)
	EndIf;
	
EndProcedure

// Checks the presence of the established relative exchange rate on January 1, 1980.
// In case of absence, sets the numerator rate and the denominator rate equal to one.
//
// Parameters:
//  Currency - CatalogRef.Currencies - a link to an element of the Currency directory.
//
Procedure CheckCorrectnessOfRelativeRateOn01_01_1980(Currency) Export
	
	DateOfCourse = Date("19800101");
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.RelativeExchangeRates");
	LockItem.SetValue("Period", DateOfCourse);
	LockItem.SetValue("Currency", Currency);
	LockItem.SetValue("BaseCurrency", Currency);
	
	BeginTransaction();
	Try
		Block.Lock();
		RateStructure = InformationRegisters.RelativeExchangeRates.GetLast(DateOfCourse, New Structure("Currency, BaseCurrency", Currency, Currency));
		
		If (RateStructure.CourseNumerator = 0) Or (RateStructure.CourseDenominator = 0) Then
			RecordSet = InformationRegisters.RelativeExchangeRates.CreateRecordSet();
			RecordSet.Filter.Period.Set(DateOfCourse);
			RecordSet.Filter.Currency.Set(Currency);
			RecordSet.Filter.BaseCurrency.Set(Currency);
			Record = RecordSet.Add();
			Record.Period = DateOfCourse;
			Record.Currency = Currency;
			Record.BaseCurrency = Currency;
			Record.CourseNumerator = 1;
			Record.CourseDenominator = 1;
			RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck");
			RecordSet.AdditionalProperties.Insert("DisableDependentCurrenciesControl");
			RecordSet.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#Region CurrencyExchangeRateCache

// The function returns a table-cache of currency rates
//
// Returns: 
//  ValueTable - A table containing columns:
//     * Currency 	- CatalogRef.Currencies -  element of the "Currencies" reference list.
//     
//	   * DateOfCourse 	- Date - date of the course.
//	   * CourseNumerator - Number - The numerator of the currency exchange rate.
//	   * CourseDenominator - Number - The denominator of the currency exchange rate.
//
Function InitializeCurrencyExchangeRateCache() Export
	
	RateCache = New ValueTable;
	RateCache.Columns.Add("Currency");
	RateCache.Columns.Add("BaseCurrency");
	RateCache.Columns.Add("DateOfCourse");
	RateCache.Columns.Add("CourseNumerator");
	RateCache.Columns.Add("CourseDenominator");
	
	RateCache.Indexes.Add("Currency, DateOfCourse, BaseCurrency");
	
	Return RateCache;
	
EndFunction // initializationcashcoursvalute()

// The function returns the ratio of the exchange rate to the multiplicity of the currency exchange rate on the date
//
// Parameters:
//  Currency - CatalogRef.Currencies - - The currency the exchange rate of which you need to get
//  DateOfCourse - Date-  The date on which the course should be received
//  RateCache - See InitializeCurrencyExchangeRateCache
//	BaseCurrency - CatalogRef.Currencies - The base currency against which you need to get the rate.
//											If Undefined, then the rates are obtained relative to the value from the base constant of the default.
//	
// Returns: 
//	Number      - Exchange rate
//
Function GetCurrencyExchangeRateFromCache(Val Currency, Val DateOfCourse, RateCache, Val BaseCurrency = Undefined) Export
	
	If Not ValueIsFilled(Currency) Then
		MessageText = NStr("vi = 'Lỗi nhận tỷ giá hối đoái: đã chuyển sang tiền tệ trống';
							|ru = 'Ошибка получения курса валют: передана пустая валюта';
							|en = 'An error occurred upon receiving the exchange rate: empty currency is submitted'; fa = 'An error occurred upon receiving the exchange rate: empty currency is submitted';
							|it = 'Errore di ricezione del tasso di cambio delle valute: è stata fornita una valuta vuota';
							|pl = 'Błąd otrzymania kursu walut: przekazano pustą walutę';
							|tr = 'Döviz kuru alınırken hata: boş para birimi transfer edildi'");
		Raise MessageText;
	EndIf;
	
	DateOfCourse = BegOfDay(DateOfCourse);
	
	If Not ValueIsFilled(BaseCurrency) Then
		BaseCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	TheStructureOfTheSearch = New Structure("Currency, DateOfCourse, BaseCurrency",
									   Currency, DateOfCourse, BaseCurrency);
	SearchResult = RateCache.FindRows(TheStructureOfTheSearch);
	
	If SearchResult.Count() = 0 Then
		RateStructure = GetCurrencyRate(Currency, DateOfCourse, BaseCurrency);
		WriteCache = RateCache.Add();
		WriteCache.Currency = TheStructureOfTheSearch.Currency;
		WriteCache.DateOfCourse = TheStructureOfTheSearch.DateOfCourse;
		WriteCache.BaseCurrency  = TheStructureOfTheSearch.BaseCurrency;
		WriteCache.CourseNumerator  = RateStructure.CourseNumerator;
		WriteCache.CourseDenominator = RateStructure.CourseDenominator;
	Else
		RateStructure = SearchResult[0];
	EndIf;
	
	If RateStructure.CourseNumerator = 0 Or RateStructure.CourseDenominator = 0 Then
		MessageText = StrTemplate(NStr("vi = 'Nhận tỷ giá hối đoái: đã tìm thấy tỷ giá bằng 0 của tiền tệ %1 theo tiền tệ cơ sở %2.';
										|ru = 'Получение курса валют: обнаружен нулевой курс валюты %1 относительно базовой валюты %2.';
										|en = 'Get an exchange rate: a zero exchange rate %1 relative to base currency %2 was detected.'; fa = 'Get an exchange rate: a zero exchange rate %1 relative to base currency %2 was detected.';
										|it = 'Ricezione tasso di cambio delle valute: è stato rilevato un tasso di cambio pari a zero %1 relativamente alla valuta di riferimento %2.';
										|pl = 'Pobieranie kursu walut: wykryto zerowy kurs waluty %1 w stosunku do podstawowej waluty %2.';
										|tr = 'Döviz kurunu alın: %1 para birimi için %2 temel para birimine karşı sıfır döviz kuru bulundu.'"), Currency, BaseCurrency);
		Common.MessageToUser(MessageText);
		Return 0;
	EndIf;
	
	Return RateStructure.CourseNumerator / RateStructure.CourseDenominator;
	
EndFunction // Get the Cashback Currency()

// The function returns a table-cache of currency rates
//
// Returns: 
//  ValueTable - A table containing columns:
//     * Contract 	- CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - Contract With A Fixed Course
//     
//	   * DateOfCourse 	- Date - date of the course.
//	   * CourseNumerator - Number - The numerator of the currency exchange rate.
//	   * CourseDenominator - Number - The denominator of the currency exchange rate.
//
Function InitializeCacheOfContractExchangeRates() Export
	
	RateCache = New ValueTable;
	RateCache.Columns.Add("Contract");
	RateCache.Columns.Add("DateOfCourse");
	RateCache.Columns.Add("CourseNumerator");
	RateCache.Columns.Add("CourseDenominator");
	
	RateCache.Indexes.Add("Contract, DateOfCourse");
	
	Return RateCache;
	
EndFunction // initializationcashcoursvalute()

// The function returns the ratio of the exchange rate to the multiplicity of the currency exchange rate on the date
//
// Parameters:
//  Contract - CatalogRef.Currencies - - The currency the exchange rate of which you need to get
//  DateOfCourse - Date-  The date on which the course should be received
//  RateCache - See InitializeCurrencyExchangeRateCache
//	
// Returns: 
//	Number      - Exchange rate
//
Function GetContractCurrencyExchangeRateFromCache(Val Contract, Val DateOfCourse, RateCache) Export
	
	If Not ValueIsFilled(Contract) Then
		MessageText = NStr("vi = 'Lỗi nhận tỷ giá ngoại tệ theo hợp đồng: đã chuyển hợp đồng trống';
							|ru = 'Ошибка получения курса валют по договору: передан пустой договор';
							|en = 'An error occurred when getting the contract exchange rate: a blank contract is passed'; fa = 'An error occurred when getting the contract exchange rate: a blank contract is passed';
							|it = 'Errore di ricezione del tasso di cambio valuta del contratto: trasmesso contratto vuoto';
							|pl = 'Błąd otrzymania kursu walut według umowy: została przekazana pusta umowa';
							|tr = 'Sözleşme için döviz kuru alınırken hata : boş bir sözleşme transfer edildi'");
		Raise MessageText;
	EndIf;
	
	DateOfCourse = BegOfDay(DateOfCourse);
	
	TheStructureOfTheSearch = New Structure("Contract, DateOfCourse",
									   Contract, DateOfCourse);
	SearchResult = RateCache.FindRows(TheStructureOfTheSearch);
	
	If SearchResult.Count() = 0 Then
		RateStructure = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(Contract, DateOfCourse);
		WriteCache = RateCache.Add();
		WriteCache.Contract = TheStructureOfTheSearch.Contract;
		WriteCache.DateOfCourse = TheStructureOfTheSearch.DateOfCourse;
		WriteCache.CourseNumerator  = RateStructure.CourseNumerator;
		WriteCache.CourseDenominator = RateStructure.CourseDenominator;
	Else
		RateStructure = SearchResult[0];
	EndIf;
	
	If RateStructure.CourseNumerator = 0 Or RateStructure.CourseDenominator = 0 Then
		MessageText = StrTemplate(NStr("vi = 'Nhận tỷ giá ngoại tệ: đã tìm thấy tỷ giá ngoại tệ bằng 0 trong hợp đồng %1.';
										|ru = 'Получение курса валют: обнаружен нулевой курс валюты договора %1.';
										|en = 'Get an exchange rate: a zero exchange rate of the %1 contract is detected.'; fa = 'Get an exchange rate: a zero exchange rate of the %1 contract is detected.';
										|it = 'Ricezione tasso di cambio valuta: rilevato tasso di cambio zero della valuta del contratto %1.';
										|pl = 'Otrzymanie kursu walut: wykryto kurs waluty umowy %1.';
										|tr = 'Döviz kuru alımı: %1 sözleşme döviz kuru sıfır tespit edildi.'"), Contract);
		Common.MessageToUser(MessageText);
		Return 0;
	EndIf;
	
	Return RateStructure.CourseNumerator / RateStructure.CourseDenominator;
	
EndFunction // Get the Cashback Currency()

#EndRegion

#EndRegion

#Region Private

// Fill in the ECB exchange rate data for the currency.
// 
// Parameters:
//  SelectedCurrency  - CatalogRef.Currencies - 
//  BaseCurrency - CatalogRef.Currencies - 
// 
// Returns:
//  Structure - Fill in ECB rate data for currency:
// 	* DateOfCourse - Date -
// 	* CourseNumerator - Number -
// 	* CourseDenominator - Number -
Function FillInECBRateDataForCurrency(SelectedCurrency, BaseCurrency) Export
	
	RateData = New Structure("DateOfCourse, CourseNumerator, CourseDenominator");
	
	Query = New Query;
	
	Query.Text = "SELECT
	               |	RegRates.Period AS Period,
	               |	RegRates.CourseNumerator AS CourseNumerator,
	               |	RegRates.CourseDenominator AS CourseDenominator
	               |FROM
	               |	InformationRegister.RelativeExchangeRates.SliceLast(
	               |			&ImportPeriodEnd,
	               |			Currency = &SelectedCurrency
	               |				AND BaseCurrency = &BaseCurrency) AS RegRates";
	Query.SetParameter("SelectedCurrency", SelectedCurrency);
	Query.SetParameter("BaseCurrency", BaseCurrency);
	Query.SetParameter("ImportPeriodEnd", CurrentSessionDate());
	
	SelectionRate = Query.Execute().Select();
	SelectionRate.Next();
	
	RateData.DateOfCourse = SelectionRate.Period;
	RateData.CourseNumerator = SelectionRate.CourseNumerator;
	RateData.CourseDenominator = SelectionRate.CourseDenominator;
	
	Return RateData;
	
EndFunction

Procedure DownloadCurrentECBRate(ImportParameters = Undefined, ResultAddress = Undefined) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DownloadingECBExchangeRates);
	
	If Metadata.DataProcessors.Find("DownloadingECBExchangeRates") <> Undefined And GetFunctionalOption("UseTheDownloadOfECBExchangeRates") Then
		DataProcessors["DownloadingECBExchangeRates"].ImportActualRate(ImportParameters, ResultAddress);
	EndIf;
	
EndProcedure

Procedure PerformRecording(Receiver)
	
	Receiver.AdditionalProperties.Insert("SynchronizationOfExchangeRates");
	Receiver.AdditionalProperties.Insert("DisableDependentCurrenciesControl");
	
	Receiver.Write();
	
EndProcedure

Procedure UpdateSynchronizedCourses(Source, Receiver, RegisterName, BaseCurrency)
	
	Period = Source.Filter.Period.Value;
	Currency = Source.Filter.Currency.Value;
	
	If ValueIsFilled(Period) Then
		Receiver.Filter.Period.Set(Period);
	EndIf;
	If ValueIsFilled(Currency) Then
		Receiver.Filter.Currency.Set(Currency);
	EndIf;
	If ValueIsFilled(BaseCurrency) Then
		Receiver.Filter.BaseCurrency.Set(BaseCurrency);
	EndIf;
	
	For Each RecordSource In Source Do
		
		NewReceiver = Receiver.Add();
		NewReceiver.Period = RecordSource.Period;
		NewReceiver.Currency = RecordSource.Currency;
		
		If ValueIsFilled(BaseCurrency) Then
			NewReceiver.BaseCurrency = BaseCurrency;
		EndIf;
		
		If RegisterName = Metadata.InformationRegisters.ExchangeRates.Name Then
			NewReceiver.Rate = RecordSource.CourseNumerator;
			NewReceiver.Repetition = RecordSource.CourseDenominator;
		Else
			NewReceiver.CourseNumerator = RecordSource.Rate;
			NewReceiver.CourseDenominator = RecordSource.Repetition;
		EndIf;
		
	EndDo;
	
	PerformRecording(Receiver);
	
EndProcedure

Procedure DeleteSynchronizedCourses(Source, Receiver, BaseCurrency)
	
	Period = Source.Filter.Period.Value;
	Currency = Source.Filter.Currency.Value;
	
	Receiver.Filter.Period.Set(Period);
	Receiver.Filter.Currency.Set(Currency);
	If ValueIsFilled(BaseCurrency) Then
		Receiver.Filter.BaseCurrency.Set(BaseCurrency);
	EndIf;
	
	PerformRecording(Receiver);
	
EndProcedure

// Relative courses are relevant.
// 
// Parameters:
//  BaseCurrency - CatalogRef.Currencies
// 
// Returns:
// 	Boolean - A sign of the relevance of relative courses.
//
Function RelativeCoursesAreRelevant(BaseCurrency) Export
	QueryText =
	"SELECT
	|	Currencies.Ref AS Ref
	|INTO ttCurrencies
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)
	|	AND Currencies.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	1 AS Field1
	|FROM
	|	ttCurrencies AS Currencies
	|		LEFT JOIN InformationRegister.RelativeExchangeRates AS RelativeExchangeRates
	|		ON Currencies.Ref = RelativeExchangeRates.Currency
	|			AND (RelativeExchangeRates.Period = &CurrentDate)
	|			AND (RelativeExchangeRates.BaseCurrency = &BaseCurrency)
	|WHERE
	|	RelativeExchangeRates.Currency IS NULL";
	
	Query = New Query;
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("BaseCurrency", BaseCurrency);
	Query.Text = QueryText;
	
	Return Query.Execute().IsEmpty();
EndFunction

// downloadable currencies.
// 
// Returns:
//  Array of CatalogRef.Currencies - downloadable currencies.
//
Function CurrenciesToImport() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Currencies.Ref AS Ref
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)
	|	AND NOT Currencies.DeletionMark
	|
	|ORDER BY
	|	Currencies.DescriptionFull";

	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// List of dependent currencies.
// 
// Parameters:
//  BaseCurrency - CatalogRef.Currencies - The currency for which you need to get dependent currencies
//  AdditionalProperties - Structure, Undefined - Additional properties for caching
// 
// Returns:
//  ValueTable - Table of dependent currencies:
//   * Ref - CatalogRef.Currencies
//   * Markup - Number
//   * RateSource - EnumRef.RateSources
//   * RateCalculationFormula - String
//
Function DependentCurrenciesList(BaseCurrency, AdditionalProperties = Undefined) Export
	
	Cached = (TypeOf(AdditionalProperties) = Type("Structure"));
	
	If Cached Then
		
		DependentCurrencies = AdditionalProperties.DependentCurrencies.Get(BaseCurrency);
		
		If TypeOf(DependentCurrencies) = Type("ValueTable") Then
			Return DependentCurrencies;
		EndIf;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CatCurrencies.Ref,
	|	CatCurrencies.Markup,
	|	CatCurrencies.RateSource,
	|	CatCurrencies.RateCalculationFormula
	|FROM
	|	Catalog.Currencies AS CatCurrencies
	|WHERE
	|	CatCurrencies.MainCurrency = &BaseCurrency
	|
	|UNION ALL
	|
	|SELECT
	|	CatCurrencies.Ref,
	|	CatCurrencies.Markup,
	|	CatCurrencies.RateSource,
	|	CatCurrencies.RateCalculationFormula
	|FROM
	|	Catalog.Currencies AS CatCurrencies
	|WHERE
	|	CatCurrencies.RateCalculationFormula LIKE &AlphabeticCode";
	
	Query.SetParameter("BaseCurrency", BaseCurrency);
	Query.SetParameter("AlphabeticCode", "%" + Common.ObjectAttributeValue(BaseCurrency, "Description") + "%");
	
	DependentCurrencies = Query.Execute().Unload();
	
	If Cached Then
		
		AdditionalProperties.DependentCurrencies.Insert(BaseCurrency, DependentCurrencies);
		
	EndIf;
	
	Return DependentCurrencies;
	
EndFunction

// See the subscription to the event "When recording courses in the Currency"
Procedure WhenRecordingCurrencyExchangeRatesOnWrite(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load And Not Source.AdditionalProperties.Property("UploadingCurrencyExchangeRatesToRegionForEntirePeriod") Then
		Return;
	EndIf;
	
	If Source.AdditionalProperties.Property("RecordingWhenUpdatingInformationBase") Then
		Return;
	EndIf;
	
	If Source.AdditionalProperties.Property("SynchronizationOfExchangeRates") Then
		Return;
	EndIf;
	
	ProcessingOfExchangeRatesTM.SynchronizeExchangeRates(Source);
	
EndProcedure

Function TextOfRequestForCoursesOnObjectOfCalculations()
	QueryText = 
	"SELECT
	|	ContractCourse.Period AS Period,
	|	ContractCourse.Contract AS Contract,
	|	ContractCourse.CourseNumerator AS CourseNumerator,
	|	ContractCourse.CourseDenominator AS CourseDenominator
	|INTO ContractTTCourses
	|FROM
	|	InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&Period) AS ContractCourse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ARAPObjects.Ref                                                 AS ARAPObject,
	|	CASE
	|		WHEN ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|				AND ISNULL(ARAPObjects.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable)) 
	|					= VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|			THEN VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		ELSE ISNULL(ARAPObjects.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable))
	|	END                                                                  AS ContractRateOption,
	|	ARAPObjects.ARAPObjectType                                     AS ARAPObjectType,
	|	ISNULL(DocumentCourses.RateARAPCurrencyNumerator, 0)         AS RateARAPCurrencyNumerator,
	|	ISNULL(DocumentCourses.RateARAPCurrencyDenominator, 0)       AS RateARAPCurrencyDenominator,
	|	ISNULL(DocumentCourses.RateManagementAccountingCurrencyNumerator, 0)   AS RateManagementAccountingCurrencyNumerator,
	|	ISNULL(DocumentCourses.RateManagementAccountingCurrencyDenominator, 0) AS RateManagementAccountingCurrencyDenominator,
	|	ISNULL(DocumentCourses.RateDocumentCurrencyNumerator, 0)              AS RateDocumentCurrencyNumerator,
	|	ISNULL(DocumentCourses.RateDocumentCurrencyDenominator, 0)            AS RateDocumentCurrencyDenominator,
	|	ISNULL(DocumentCourses.DocumentCurrency, 0)                           AS DocumentCurrency,
	|	ARAPObjects.ARAPCurrency                                   AS ARAPCurrency,
	|	ARAPObjects.Organization.LocalAccountingCurrency             AS LocalAccountingCurrency,
	|	ARAPObjects.Date                                                   AS Date,
	|	ISNULL(ContractRates.Period, DATETIME(1, 1, 1))                    AS ContractCoursePeriod,
	|	ISNULL(ContractRates.CourseNumerator, 0)                              AS ExchangeRateNumeratorOfContractCurrency,
	|	ISNULL(ContractRates.CourseDenominator, 0)                            AS ExchangeRateDenominatorOfContractCurrency
	|INTO CalculationObjectData
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|		LEFT JOIN InformationRegister.DocumentCurrenciesAndRates AS DocumentCourses
	|		ON ARAPObjects.Object = DocumentCourses.Document
	|		LEFT JOIN ContractTTCourses AS ContractRates
	|		ON ARAPObjects.Contract = ContractRates.Contract
	|WHERE
	|	ARAPObjects.Ref IN (&ARAPObjects)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationObjectData.ARAPObject                 AS ARAPObject,
	|	CalculationObjectData.DocumentCurrency                AS Currency,
	|	CalculationObjectData.LocalAccountingCurrency AS BaseCurrency,
	|	CalculationObjectData.Date                           AS DateOfCourse,
	|	CalculationObjectData.RateDocumentCurrencyNumerator   AS CourseNumerator,
	|	CalculationObjectData.RateDocumentCurrencyDenominator AS CourseDenominator
	|INTO TTCoursesArePre
	|FROM
	|	CalculationObjectData AS CalculationObjectData
	|WHERE
	|	CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|	AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|	AND CalculationObjectData.DocumentCurrency IN(&ArrayOfCurrencies)
	|
	|UNION ALL
	|
	|SELECT
	|	CalculationObjectData.ARAPObject                      AS ARAPObject,
	|	CalculationObjectData.ARAPCurrency                AS Currency,
	|	CalculationObjectData.LocalAccountingCurrency      AS BaseCurrency,
	|	CalculationObjectData.Date                                AS DateOfCourse,
	|	CalculationObjectData.RateARAPCurrencyNumerator   AS CourseNumerator,
	|	CalculationObjectData.RateARAPCurrencyDenominator AS CourseDenominator
	|FROM
	|	CalculationObjectData AS CalculationObjectData
	|WHERE
	|	CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|	AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|	AND CalculationObjectData.ARAPCurrency IN(&ArrayOfCurrencies)
	|
	|UNION ALL
	|
	|SELECT
	|	CalculationObjectData.ARAPObject                            AS ARAPObject,
	|	&CurrencyOfMan                                                      AS Currency,
	|	CalculationObjectData.LocalAccountingCurrency            AS BaseCurrency,
	|	CalculationObjectData.Date                                      AS DateOfCourse,
	|	CalculationObjectData.RateManagementAccountingCurrencyNumerator   AS CourseNumerator,
	|	CalculationObjectData.RateManagementAccountingCurrencyDenominator AS CourseDenominator
	|FROM
	|	CalculationObjectData AS CalculationObjectData
	|WHERE
	|	CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|	AND CalculationObjectData.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|	AND &CurrencyOfMan IN (&ArrayOfCurrencies)
	|
	|UNION ALL
	|
	|SELECT
	|	CalculationObjectData.ARAPObject                 AS ARAPObject,
	|	CalculationObjectData.ARAPCurrency           AS Currency,
	|	CalculationObjectData.LocalAccountingCurrency AS BaseCurrency,
	|	CalculationObjectData.ContractCoursePeriod            AS DateOfCourse,
	|	CalculationObjectData.ExchangeRateNumeratorOfContractCurrency    AS CourseNumerator,
	|	CalculationObjectData.ExchangeRateDenominatorOfContractCurrency  AS CourseDenominator
	|FROM
	|	CalculationObjectData AS CalculationObjectData
	|WHERE
	|	CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|	AND CalculationObjectData.ARAPCurrency IN(&ArrayOfCurrencies)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTCoursesArePre.ARAPObject  AS ARAPObject,
	|	TTCoursesArePre.Currency          AS Currency,
	|	TTCoursesArePre.BaseCurrency   AS BaseCurrency,
	|	TTCoursesArePre.DateOfCourse       AS DateOfCourse,
	|	TTCoursesArePre.CourseNumerator   AS CourseNumerator,
	|	TTCoursesArePre.CourseDenominator AS CourseDenominator
	|FROM
	|	TTCoursesArePre AS TTCoursesArePre
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ISNULL(CalculationObjectData.ARAPObject,
	|		VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
	|	RelativeExchangeRatesSliceLast.Currency            AS Currency,
	|	RelativeExchangeRatesSliceLast.BaseCurrency     AS BaseCurrency,
	|	RelativeExchangeRatesSliceLast.Period            AS DateOfCourse,
	|	RelativeExchangeRatesSliceLast.CourseNumerator     AS CourseNumerator,
	|	RelativeExchangeRatesSliceLast.CourseDenominator   AS CourseDenominator
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&Period,
	|			BaseCurrency = &ComplCurrency
	|				AND Currency IN (&ArrayOfCurrencies)) AS RelativeExchangeRatesSliceLast
	|		LEFT JOIN CalculationObjectData AS CalculationObjectData
	|		ON (TRUE)
	|WHERE
	|	NOT (RelativeExchangeRatesSliceLast.Currency, CalculationObjectData.ARAPObject)
	|		IN (SELECT T.Currency, T.ARAPObject FROM TTCoursesArePre AS T)
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion
