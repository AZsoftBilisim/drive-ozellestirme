
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function defines the details of the selected revenue item.
//
// Parameters:
//  IncomeItem - ChartOfCharacteristicTypesRef.IncomeItems - Link to the revenue item.
//
// Returns:
//	Structure - details of the income item.
//
Function GetDetailsOfIncomeItem(IncomeItem) Export
	
	Query = New Query("
	|SELECT
	|	IncomeItems.LineOfBusinessAllocationMethod AS LineOfBusinessAllocationMethod,
	|	IncomeItems.ValueType AS ValueType
	|FROM
	|	ChartOfCharacteristicTypes.IncomeItems AS IncomeItems
	|WHERE
	|	IncomeItems.Ref = &IncomeItem
	|");
	
	Query.SetParameter("IncomeItem", IncomeItem);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		LineOfBusinessAllocationMethod = Selection.LineOfBusinessAllocationMethod;
		AllocationMethodIsRequired = Not Selection.ValueType.ContainsType(Type("CatalogRef.LinesOfBusiness"));
	Else
		LineOfBusinessAllocationMethod = Undefined;
		AllocationMethodIsRequired = False;
	EndIf;
	
	AttributesStructure1 = New Structure("LineOfBusinessAllocationMethod, AllocationMethodIsRequired",
		LineOfBusinessAllocationMethod,
		AllocationMethodIsRequired);
	
	Return AttributesStructure1;

EndFunction

// The function defines revenue Analytics for substituting in a document for an item of revenue.
//
// Parameters:
//  IncomeItem - ChartOfCharacteristicTypesRef.IncomeItems - Link to source of income
//	Object - FormDataStructure - Current object 
//	Department - CatalogRef.BusinessStructure - Link to the Department specified in the document.
//
// Returns:
//	CatalogRef - the value of revenue analytics.
//
Function GetDefaultRevenueAnalytics(IncomeItem, Object, Department) Export
	
	Query = New Query("
	|SELECT
	|	IncomeItems.ValueType AS ValueType
	|FROM
	|	ChartOfCharacteristicTypes.IncomeItems AS IncomeItems
	|WHERE
	|	IncomeItems.Ref = &IncomeItem
	|");
	
	Query.SetParameter("IncomeItem", IncomeItem);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		TypeOfRevenueAnalyticsValue = Selection.ValueType;
	Else
		TypeOfRevenueAnalyticsValue = Undefined;
	EndIf;
	
	TypeDescription = New TypeDescription(TypeOfRevenueAnalyticsValue);
	DimensionOfRevenue = TypeDescription.AdjustValue();
	
	If TypeOfRevenueAnalyticsValue = New TypeDescription("CatalogRef.Partners")
		And Object.Property("Partner") Then
		
		DimensionOfRevenue = Object.Partner;
		
	ElsIf TypeOfRevenueAnalyticsValue = New TypeDescription("CatalogRef.Companies")
	   And Object.Property("Organization") Then
	   
		DimensionOfRevenue = Object.Organization;
		
	ElsIf TypeOfRevenueAnalyticsValue = New TypeDescription("CatalogRef.BusinessStructure") Then
		
		If Object.Property("Department") Then
			DimensionOfRevenue = Object.Department;
		Else
			DimensionOfRevenue = Department;
		EndIf;
		
	EndIf;
	
	Return DimensionOfRevenue;
	
EndFunction

// Checks filling in the details of the revenue item analyst in the transferred object.
//
// Parameters:
// 		Object - CatalogObject, DocumentObject, FormDataStructure - An information security object intended for verification
// 		Attributes - String, Structure, Array - Details of income items for verification
// 			<Line> Enumeration of pairs of details for verification in the format "revenue State1, revenue Analytic1, revenue State2, revenue Analytic2, ..."
// 				an Empty string is interpreted as " revenue State1, revenue Analytic1"
// 			<Structure> Key: a String with the name of the table part; Value-a String in notation as for the <String>type parameter
// 			< Array> an Array whose elements are either structures in the notation of a parameter with the <Structure> type, or strings in the <String>notation
// 		AttributesNotToCheck - Array - Array for accumulating non-verifiable details of the passed object
// 		Cancel - Boolean - Indicates whether there are errors in filling in the passed object's Analytics
// 		AdditionalParameters - Structure - If the "program Check" property is present, errors are written to this structure, but are not output to the user.
//
Procedure CheckAnalystCompletion(Object, Attributes = "", AttributesNotToCheck = Undefined, Cancel = False,
	AdditionalParameters = Undefined) Export
	
	Errors = New Structure;
	Errors.Insert("ErrorList", New Array);
	Errors.Insert("ErrorGroups", New Map);
	Errors.Insert("ObjectPrefix", ?(TypeOf(Object)=Type("ClientApplicationForm"), "", "Object."));
	
	ProcessingArray = New Array;
	If TypeOf(Attributes) = Type("Array") Then
		ProcessingArray = Attributes;
	Else
		ProcessingArray.Add(Attributes);
	EndIf;
	
	For Each ArrayElement In ProcessingArray Do
		
		If TypeOf(ArrayElement) = Type("Structure") Then
			CheckingFillingOfObjectSTSAnalyst(Object,
												ArrayElement,
												AttributesNotToCheck,
												Errors,
												AdditionalParameters);
		Else
			ThisIsObjectOnForm = False;
			If TypeOf(AdditionalParameters) = Type("Structure") Then
				AdditionalParameters.Property("ThisIsObjectOnForm", ThisIsObjectOnForm);
			EndIf;
			CheckingContentOfObjectAnalytics(Object, ArrayElement, AttributesNotToCheck, Errors, ThisIsObjectOnForm);
		EndIf;
		
	EndDo;
	
	If TypeOf(AdditionalParameters) = Type("Structure")
		And AdditionalParameters.Property("SoftwareVerification") Then
		AdditionalParameters.Insert("Errors", Errors);
	Else
		If Errors.ErrorList.Count() <> 0 Then
			CommonClientServer.ReportErrorsToUser(Errors, Cancel);
		EndIf;
	EndIf;
	
EndProcedure

// Returns revenue items that are not allowed to be used
//
// Returns:
// 	ValueList - A list of blocked income items.
//
Function BlockedRevenueItems() Export
	
	BlockedArticles = New ValueList;
	If GetFunctionalOption("BaseVersion") Then
		BlockedArticles.Add(ChartsOfCharacteristicTypes.IncomeItems.SalesRevenue);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.IncomeItems.ClosingOfBadDebtAlowances);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.IncomeItems.DifferencesInCostOfReturnAndActualCostOfGoods);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.IncomeItems.FixedAssetSale);
	EndIf;
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		BlockedArticles.Add(ChartsOfCharacteristicTypes.IncomeItems.ExchangeRateDifferences);
		BlockedArticles.Add(ChartsOfCharacteristicTypes.IncomeItems.CurrencyConversionIncome);
	EndIf;
	
	Return BlockedArticles;
	
EndFunction

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	#Region SalesRevenue
	Item = Items.Add();
	Item.PredefinedDataName = "SalesRevenue";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.LinesOfBusiness"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Doanh thu bán hàng';
																					|ru = 'Выручка от продаж';
																					|en = 'Sales revenue';
																					|it = 'Ricavo dalle vendite';
																					|pl = 'Przychód ze sprzedaży';
																					|tr = 'Satış geliri'", LanguagesCodes); // @NStr-2
	Item.Code = "000000001";
	Item.AddlOrderingAttribute = 1;
	Item.LoanAndDepositContracts = False;
	Item.EnteredInTaxAccounting = True;
	Item.IncomeByAssets = False;
	Item.IntangibleAssetsAndRDIncome = False;
	Item.ControlDimensionFilling = False;
	Item.ActivityTypeForTaxAccountingOfCosts = Enums.ActivityTypesForTaxAccountingOfCosts.MainSystem;
	#EndRegion

	#Region CurrencyConversionIncome
	Item = Items.Add();
	Item.PredefinedDataName = "CurrencyConversionIncome";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.ExchangeDifferencesDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thu nhập chuyển đổi tiền tệ';
																					|ru = 'Доходы при конвертации валюты';
																					|en = 'Currency conversion income';
																					|it = 'Redditi alla conversione di valuta';
																					|pl = 'Dochody podczas wymiany waluty';
																					|tr = 'Para birimi dönüştürmesinden gelir'", LanguagesCodes); // @NStr-2
	Item.Code = "000000007";
	Item.AddlOrderingAttribute = 4;
	Item.LoanAndDepositContracts = False;
	Item.EnteredInTaxAccounting = True;
	Item.IncomeByAssets = False;
	Item.IntangibleAssetsAndRDIncome = False;
	Item.ControlDimensionFilling = False;
	Item.ActivityTypeForTaxAccountingOfCosts = Enums.ActivityTypesForTaxAccountingOfCosts.MainSystem;
	#EndRegion

	#Region ClosingOfBadDebtAlowances
	Item = Items.Add();
	Item.PredefinedDataName = "ClosingOfBadDebtAlowances";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Companies"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đóng dự phòng cho các khoản nợ xấu';
																					|ru = 'Закрытие резервов по сомнительным долгам';
																					|en = 'Close loss allowance';
																					|it = 'Chiusura di accantonamenti per crediti dubbi';
																					|pl = 'Zamknięcie rezerw z według wątpliwych długów';
																					|tr = 'Şüpheli borç rezervlerinin kapatılması'", LanguagesCodes); // @NStr-2
	Item.Code = "000000006";
	Item.AddlOrderingAttribute = 2;
	Item.LoanAndDepositContracts = False;
	Item.EnteredInTaxAccounting = True;
	Item.IncomeByAssets = False;
	Item.IntangibleAssetsAndRDIncome = False;
	Item.ControlDimensionFilling = False;
	Item.ActivityTypeForTaxAccountingOfCosts = Enums.ActivityTypesForTaxAccountingOfCosts.MainSystem;
	#EndRegion

	#Region ExchangeRateDifferences
	Item = Items.Add();
	Item.PredefinedDataName = "ExchangeRateDifferences";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.ExchangeDifferencesDimension"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chênh lệch tỷ giá';
																					|ru = 'Курсовые разницы';
																					|en = 'Exchange differences';
																					|it = 'Differenze dei tassi di cambio';
																					|pl = 'Różnice kursowe';
																					|tr = 'Döviz kuru farkları'", LanguagesCodes); // @NStr-2
	Item.Code = "000000002";
	Item.AddlOrderingAttribute = 3;
	Item.LoanAndDepositContracts = False;
	Item.EnteredInTaxAccounting = True;
	Item.IncomeByAssets = False;
	Item.IntangibleAssetsAndRDIncome = False;
	Item.ControlDimensionFilling = False;
	Item.ActivityTypeForTaxAccountingOfCosts = Enums.ActivityTypesForTaxAccountingOfCosts.MainSystem;
	#EndRegion

	#Region ProfitLossOfPreviousYears
	Item = Items.Add();
	Item.PredefinedDataName = "ProfitLossOfPreviousYears";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Companies"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Lãi (lỗ) các năm trước';
																					|ru = 'Прибыль (убыток) прошлых лет';
																					|en = 'Previous years profit (loss)';
																					|it = 'Utile (perdita) degli anni passati';
																					|pl = 'Zysk (strata) z lat ubiegłych';
																					|tr = 'Geçmiş yıllardan gelen kâr (zarar)'", LanguagesCodes); // @NStr-2
	Item.Code = "000000005";
	Item.AddlOrderingAttribute = 5;
	Item.LoanAndDepositContracts = False;
	Item.EnteredInTaxAccounting = True;
	Item.IncomeByAssets = False;
	Item.IntangibleAssetsAndRDIncome = False;
	Item.ControlDimensionFilling = False;
	Item.ActivityTypeForTaxAccountingOfCosts = Enums.ActivityTypesForTaxAccountingOfCosts.MainSystem;
	#EndRegion

	#Region DifferencesInCostOfReturnAndActualCostOfGoods
	Item = Items.Add();
	Item.PredefinedDataName = "DifferencesInCostOfReturnAndActualCostOfGoods";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Partners"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chênh lệch giá trị trả lại và giá trị thực tế của hàng hóa';
																					|ru = 'Разницы стоимости возврата и фактической стоимости товаров';
																					|en = 'Differences in the cost of return and the actual cost of goods';
																					|it = 'Differenze nel costo del reso e nel costo effettivo della merce';
																					|pl = 'Różnice wartości zwrotu i wartości faktycznej towarów';
																					|tr = 'İade fiyatı ile malların gerçek fiyatı arasındaki farklar'", LanguagesCodes); // @NStr-2
	Item.Code = "000000003";
	Item.AddlOrderingAttribute = 6;
	Item.LoanAndDepositContracts = False;
	Item.EnteredInTaxAccounting = True;
	Item.IncomeByAssets = False;
	Item.IntangibleAssetsAndRDIncome = False;
	Item.ControlDimensionFilling = False;
	Item.ActivityTypeForTaxAccountingOfCosts = Enums.ActivityTypesForTaxAccountingOfCosts.MainSystem;
	#EndRegion
	#Region FixedAssetSale
	Item = Items.Add();
	Item.PredefinedDataName = "FixedAssetSale";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Assets"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Giao hàng TSCĐ';
																					|ru = 'Реализация ОС';
																					|en = 'Fixed assets sales';
																					|it = 'Vendita del capitale fisso';
																					|pl = 'Realizacja ŚT';
																					|tr = 'Sabit kıymet uygulaması'", LanguagesCodes); // @NStr-2
	Item.Code = "000000004";
	Item.AddlOrderingAttribute = 7;
	Item.LoanAndDepositContracts = False;
	Item.EnteredInTaxAccounting = True;
	Item.IncomeByAssets = True;
	Item.IntangibleAssetsAndRDIncome = False;
	Item.ControlDimensionFilling = False;
	Item.ActivityTypeForTaxAccountingOfCosts = Enums.ActivityTypesForTaxAccountingOfCosts.MainSystem;
	#EndRegion
	#Region GoodsValueVariance
	
	Item = Items.Add();
	Item.PredefinedDataName = "GoodsValueVariance";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Products"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
    NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Chênh lệch trong giá trị hàng hóa';
																					|ru = 'Отклонение в стоимости товаров';
																					|en = 'Goods cost variance';
																					|it = 'Variazione nel costo delle merci';
																					|pl = 'Odchylenie w wartości towarów';
																					|tr = 'Ürünlerin fiyatında sapma'", LanguagesCodes); // @NStr-2
	Item.Code = "000000008";
	Item.AddlOrderingAttribute = 8;
	Item.LoanAndDepositContracts = False;
	Item.EnteredInTaxAccounting = True;
	Item.IncomeByAssets = False;
	Item.IntangibleAssetsAndRDIncome = False;
	Item.ControlDimensionFilling = False;
	Item.ActivityTypeForTaxAccountingOfCosts = Enums.ActivityTypesForTaxAccountingOfCosts.MainSystem;
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - ChartOfCharacteristicTypesObject.IncomeItems - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// Fills in the details of the settings for revenue accounts that affect the setting,
// 	corresponding to the names of the accounting Analytics details.
//
// Parameters:
// 	MatchingNames - Map - the key is the name of the account that is used in setting up accounting accounts
// 		. the value is the corresponding name of the accounting Analytics account.
// 
Procedure FillInMatchingAccountSettingsDetails(MatchingNames) Export
	
	Return;
	
EndProcedure

// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	IncomeAndExpensesServer.ProcessingReceiptOfSelectionDataForIncomeItem(ChoiceData, Parameters, StandardProcessing);

EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region ServiceProceduresAndFunctionsForFillingInAnalytics

Function MandatoryArticles(ArrayOfArticles)
	
	Query = New Query(
	"SELECT
	|	ARTICLES__.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.IncomeItems AS ARTICLES__
	|WHERE
	|	ARTICLES__.Ref IN (&ArrayOfArticles)
	|	AND ARTICLES__.ControlDimensionFilling");
	
	Query.SetParameter("ArrayOfArticles", ArrayOfArticles);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

Function NamesOfArticleAndAnalyticsDetails(AttributesRow, AttributesNotToCheck = Undefined, TablePartPrefix = "")
	
	If IsBlankString(AttributesRow) Then
		If AttributesNotToCheck <> Undefined Then
			AttributesNotToCheck.Add(TablePartPrefix + "DimensionOfRevenue");
		EndIf;
		Return New Structure("IncomeItem", "DimensionOfRevenue");
	EndIf;
	
	DataProcessorStructure = New Structure(AttributesRow);
	ReturnStructure = New Structure;
	PreviousKey = Undefined;
	For Each KeyAndValue In DataProcessorStructure Do
		If PreviousKey = Undefined Then
			PreviousKey = KeyAndValue.Key;
		Else
			ReturnStructure.Insert(PreviousKey, KeyAndValue.Key);
			PreviousKey = Undefined;
			If AttributesNotToCheck <> Undefined Then
				AttributesNotToCheck.Add(TablePartPrefix + KeyAndValue.Key);
			EndIf;
		EndIf;
	EndDo;
	
	Return ReturnStructure;
	
EndFunction

Procedure CheckingContentOfObjectAnalytics(Object, Attributes, AttributesNotToCheck, Errors, ThisIsObjectOnForm = False)
	
	ObjectData		= Object;
	ArrayOfArticles		= New Array;
	AttributesStructure1	= NamesOfArticleAndAnalyticsDetails(Attributes, AttributesNotToCheck);
	
	
	If ThisIsObjectOnForm And TypeOf(Object) = Type("Structure")
		And CommonClientServer.HasAttributeOrObjectProperty(Object, "Object") Then
		
		ObjectData = Object.Object;
		
	EndIf;
	
	// Let's define a list of articles to control
	For Each KeyAndValue In AttributesStructure1 Do
		AssetRef = ObjectData[KeyAndValue.Key];
		
		If ValueIsFilled(AssetRef) Then
			ArrayOfArticles.Add(AssetRef);
		EndIf;
	EndDo;
	
	// Let's check the filling of the analytics
	MandatoryArticles = MandatoryArticles(ArrayOfArticles);
	For Each KeyAndValue In AttributesStructure1 Do
		AssetRef		= ObjectData[KeyAndValue.Key];
		Dimension	= ObjectData[KeyAndValue.Value];
		
		If Not (MandatoryArticles.Find(AssetRef) = Undefined Or ValueIsFilled(Dimension)) Then
			
			CommonClientServer.AddUserError(
				Errors,
				Errors.ObjectPrefix + KeyAndValue.Value,
				NStr("vi = 'Chỉ số thu nhập chưa điền';
					|ru = 'Аналитика доходов не заполнена';
					|en = 'Income dimension is required'; fa = 'بُعد درآمد الزامی است';
					|it = 'L''analitica delle entrate non è compilata';
					|pl = 'Nie wypełniono analityki dochodów';
					|tr = 'Gelir boyutu doldurulmamış'"), "");
			
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckingFillingOfObjectSTSAnalyst(Object,
												Attributes,
												AttributesNotToCheck,
												Errors,
												AdditionalParameters)
	
	// Let's define a list of articles to control
	GeneralArrayOfArticles = New Array;
	
	For Each DescriptionOfTS In Attributes Do
		TSName = DescriptionOfTS.Key;
		
		AttributesStructure1 = NamesOfArticleAndAnalyticsDetails(DescriptionOfTS.Value, AttributesNotToCheck, TSName + ".");
		
		For Each KeyAndValue In AttributesStructure1 Do
			ArrayOfArticles = Object[TSName].UnloadColumn(KeyAndValue.Key);
			
			For Each AssetRef In ArrayOfArticles Do
				GeneralArrayOfArticles.Add(AssetRef);
			EndDo;
		EndDo;
	EndDo;
	
	// Let's check the filling of the analytics
	MandatoryArticles = MandatoryArticles(GeneralArrayOfArticles);
	
	For Each DescriptionOfTS In Attributes Do // Table parts
		
		TSName	= DescriptionOfTS.Key;
		TS		= Object[TSName];
		
		If TypeOf(TS) = Type("ValueTable")
			And TypeOf(AdditionalParameters) = Type("Structure") Then
			
			TabularSection = Undefined;
			
			PresentationOfTS			= AdditionalParameters.PresentationOfTS;
			DetailsPresentations	= AdditionalParameters.DetailsPresentations;
			
		Else
			ObjectMetadata	= Object.Metadata();
			TabularSection		= ObjectMetadata.TabularSections.Find(TSName);
			
			PresentationOfTS			= TabularSection.Synonym;
			DetailsPresentations	= Undefined;
		EndIf;
		
		AttributesStructure1 = NamesOfArticleAndAnalyticsDetails(DescriptionOfTS.Value, Undefined, TSName + ".");
		
		For IndexOf = 0 To TS.Count() - 1 Do // Table part rows
			TSRow = TS[IndexOf];
			
			For Each KeyAndValue In AttributesStructure1 Do
				If TabularSection = Undefined Then
					AttributeRepresentation = DetailsPresentations[KeyAndValue.Value];
				Else
					AttributeRepresentation = TabularSection.Attributes.Find(KeyAndValue.Value).Synonym;
				EndIf;
				
				AssetRef		= TSRow[KeyAndValue.Key];
				Dimension	= TSRow[KeyAndValue.Value];
				
				If Not (MandatoryArticles.Find(AssetRef) = Undefined
					Or ValueIsFilled(Dimension)) Then
					
					CommonClientServer.AddUserError(
						Errors,
						Errors.ObjectPrefix + TSName + "[%1]." + KeyAndValue.Value,
						StrTemplate(NStr("vi = 'Trường ""%1"" trong hàng %2 của danh sách ""%3"" không được điền';
										|ru = 'Не заполнено поле ""%1"" в строке %2 списка ""%3""';
										|en = '""%1"" in line %2 of list ""%3"" is required'; fa = '""%1"" in line %2 of list ""%3"" is required';
										|it = 'Il campo ""%1"" nella riga ""%2"" dell''elenco ""%3"" non è compilato';
										|pl = 'Nie zostało wypełnione pole ""%1"" w wierszu %2 listy ""%3""';
										|tr = '""%3"" listesinin %2 satırındaki ""%1"" alanı doldurulmadı'"),
							AttributeRepresentation, TSRow.LineNumber, PresentationOfTS),
						TSName,
						IndexOf,
						StrTemplate(NStr("vi = 'Trường ""%1"" trong hàng %2 của danh sách ""%3"" không được điền';
										|ru = 'Не заполнено поле ""%1"" в строке %2 списка ""%3""';
										|en = '""%1"" in line %2 of list ""%3"" is required'; fa = '""%1"" in line %2 of list ""%3"" is required';
										|it = 'Il campo ""%1"" nella riga ""%2"" dell''elenco ""%3"" non è compilato';
										|pl = 'Nie zostało wypełnione pole ""%1"" w wierszu %2 listy ""%3""';
										|tr = '""%3"" listesinin %2 satırındaki ""%1"" alanı doldurulmadı'"),
							AttributeRepresentation, TSRow.LineNumber, PresentationOfTS));
					
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
