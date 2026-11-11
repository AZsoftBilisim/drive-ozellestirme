
#Region Public

// Fills in the image index for the price tree line
//
// Parameters:
//  PriceTreeString - FormDataTreeItemCollection,ValueTreeRow - element of the value tree.
//
Procedure FillInIndexOfEachRowOfPriceTree(PriceTreeString) Export
	
	ImageIndexGroup = 8;
	ImageIndexHierarchyElement = 4;
	ImageIndexProductItem = 0;
	ImageIndexCharacteristic = 2;
	
	If CommonClientServer.HasAttributeOrObjectProperty(PriceTreeString,"HierarchyIsGroup") Then
		
		If PriceTreeString.ThisIsHierarchy Then
			If PriceTreeString.HierarchyIsGroup Then
				PriceTreeString.PictureIndex = ImageIndexGroup;
			Else
				PriceTreeString.PictureIndex = ImageIndexHierarchyElement;
			EndIf;
		Else
			If ValueIsFilled(PriceTreeString.Characteristic) 
				Or ValueIsFilled(PriceTreeString.PricingVariant) 
				Or ValueIsFilled(PriceTreeString.PricingBatch) 
				Or ValueIsFilled(PriceTreeString.PricingPackage) Then
				PriceTreeString.PictureIndex = ImageIndexCharacteristic;
			Else
				PriceTreeString.PictureIndex = ImageIndexProductItem;
			EndIf;
		EndIf;
		
	Else
	 
		If TypeOf(PriceTreeString) = Type("FormDataTreeItem") Then
			If PriceTreeString.GetParent() = Undefined Then
				PriceTreeString.PictureIndex = 0;
			Else
				PriceTreeString.PictureIndex = 2;
			EndIf;
		ElsIf TypeOf(PriceTreeString) = Type("ValueTreeRow") Then
			If PriceTreeString.Parent = Undefined Then
				PriceTreeString.PictureIndex = 0;
			Else
				PriceTreeString.PictureIndex = 2;
			EndIf;
		EndIf;
	
	EndIf; 
	
EndProcedure

// Searches for a row with a certain type of price in the table
//
// Parameters:
//  SelectedPrices - FormDataCollection - Table where the search is performed
//  PriceKind - CatalogRef.TypesOfPrices - Link to the type of prices to find.
//
// Returns:
//  FormDataCollectionItem - the found type of prices contains:
//  * Ref - CatalogRef.TypesOfPrices
//
Function FindPriceTypeString(SelectedPrices, PriceKind) Export
	
	FoundRows = SelectedPrices.FindRows(New Structure("Ref", PriceKind));
	
	If FoundRows.Count()>0 Then
		Return FoundRows[0];
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Searches for a row with a certain type of price in the table by the name of the changed field.
//
// Parameters:
//  SelectedPrices - FormDataCollection - Table where the search is performed
//  ModifiedField - String - field name.
//
// Returns:
//  FormDataCollectionItem - the found type of prices.
//
Function PriceViewStringByFieldName(SelectedPrices, Val ModifiedField) Export
	
	ModifiedPriceViewLine = Undefined;
	For Each PriceTypeLine In SelectedPrices Do
		If PriceTypeLine.ColumnName = ModifiedField
			Or "Package" + PriceTypeLine.ColumnName = ModifiedField
			Or "OldPrice" + PriceTypeLine.ColumnName = ModifiedField
			Or "ChangePercentage" + PriceTypeLine.ColumnName = ModifiedField 
			Or "Formula" + PriceTypeLine.ColumnName = ModifiedField Then
			ModifiedPriceViewLine = PriceTypeLine;
			Break;
		EndIf;
	EndDo;
	
	Return ModifiedPriceViewLine;
	
EndFunction

// Marks all dependent prices in the table
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure SelectAllDependentPrices_(Form) Export
	
	FillIn = True;
	While FillIn Do
		
		FillIn = False;
		For Each CurRow In Form.SelectedPrices Do
			
			If CurRow.Selected_5 Then 
				
				For Each DependentPrice In CurRow.DependentPrices Do
					DependentPriceLine = FindPriceTypeString(Form.SelectedPrices, DependentPrice.Value);
					If DependentPriceLine <> Undefined And Not DependentPriceLine.Selected_5 And Not DependentPriceLine.ProhibitedPriceType Then
						DependentPriceLine.Selected_5 = True;
						Form.SelectedPricesWereChanged = True;
						DependentPriceLine.Edit = True;
						FillIn = True;
					EndIf;
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SettingPricesClientServer.AffixingFlagsAffectsDependsOnClient(Form);
	
EndProcedure

// Marks all influencing prices in the table
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure SelectAllInfluencingPrices_(Form) Export
	
	FillIn = True;
	While FillIn Do
		
		FillIn = False;
		For Each CurRow In Form.SelectedPrices Do
			
			If CurRow.Selected_5 Then 
				
				For Each InfluencingPrice In CurRow.InfluencingPrices Do
					SelectedPriceLine = FindPriceTypeString(Form.SelectedPrices, InfluencingPrice.Value);
					If Not SelectedPriceLine.Selected_5
						And Not SelectedPriceLine.ProhibitedPriceType Then
						SelectedPriceLine.Selected_5 = True;
						Form.SelectedPricesWereChanged = True;
						SelectedPriceLine.Edit = True;
						FillIn = True;
					EndIf;
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SettingPricesClientServer.AffixingFlagsAffectsDependsOnClient(Form);
	
EndProcedure

// Marks all influencing prices in the table without indicating the need for calculation
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure SelectAllInfluencingPricesWithoutCalculation(Form) Export
	
	For Each CurRow In Form.SelectedPrices Do
		
		If CurRow.Selected_5 Then 
			
			For Each InfluencingPrice In CurRow.InfluencingPrices Do
				
				SelectedPriceLine = FindPriceTypeString(Form.SelectedPrices, InfluencingPrice.Value);
				If Not SelectedPriceLine.Selected_5
					And Not SelectedPriceLine.ProhibitedPriceType Then
					SelectedPriceLine.Influences = True;
					SelectedPriceLine.Edit = False;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Inverts the marking of the selected prices in the table
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure InvertSelectedPrices(Form) Export
	
	For Each CurRow In Form.SelectedPrices Do
		
		CurRow.Selected_5 = Not CurRow.Selected_5; 
		
	EndDo;
		
EndProcedure

// Returns the selected price type rows
//
// Parameters:
//  Form - See SettingPricesServer.BuildPriceTree.Form
//  SelectInfluencers - Boolean - determines whether to include influencing prices in the array.
//
// Returns:
//  Array of FormDataCollectionItem - Selected Rows Of Price Types
//
Function SelectedRowsInPriceViewTable(Form, SelectInfluencers = False) Export
	
	TypesOfPrices = New Array();
	
	For Each CurRow In Form.SelectedPrices Do
		If CurRow.Selected_5 Or (SelectInfluencers And CurRow.Influences) Then
			TypesOfPrices.Add(CurRow);
		EndIf;
	EndDo;
	
	Return TypesOfPrices;
	
EndFunction

// Checks whether all dependent price types are selected
//
// Parameters:
//  Form - See SettingPricesServer.BuildPriceTree.Form
//
// Returns:
//  Boolean - True if unselected dependent prices are found in the form.
//
Function DependentPricesNotSelected(Form) Export
	
	For Each PriceViewString In SelectedRowsInPriceViewTable(Form) Do
		
		DependentPrices = New Array;
		For Each DependentPrice In PriceViewString.DependentPrices Do
			DependentPriceLine = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, DependentPrice.Value);
			If DependentPriceLine <> Undefined Then
				DependentPrices.Add(DependentPriceLine);
			EndIf;
		EndDo;
		
		For Each DependentPriceLine In DependentPrices Do
			
			If Not DependentPriceLine.Selected_5 Then
				Return True;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return False;
	
EndFunction

// Returns an array of links to the price types selected by the user
//
// Parameters:
//  Form - See SettingPricesServer.BuildPriceTree.Form
//  ForEditing - Boolean - Flag for editing
//
// Returns:
//  Array of CatalogRef.TypesOfPrices, CatalogRef.VendorPriceTypes - Array of links to the types of prices selected by the user.
//
Function SelectedTypesOfPrices(Form, ForEditing = False) Export
	
	TypesOfPrices = New Array();
	
	For Each CurRow In Form.SelectedPrices Do
		If (Not ForEditing And CurRow.Selected_5) Or (ForEditing And CurRow.Edit) Then
			TypesOfPrices.Add(CurRow.Ref);
		EndIf;
	EndDo;
	
	Return TypesOfPrices;
	
EndFunction

// Fills in the Affects and Depends flags in the table of selected prices
//
// Parameters:
//  Form - See SettingPricesServer.BuildPriceTree.Form
//
Procedure AffixingFlagsAffectsDependsOnClient(Form) Export
	
	For Each Price In Form.SelectedPrices Do
		
		Price.Depends = False;
		Price.Influences  = False;
		
	EndDo;
	
	For Each Price In Form.SelectedPrices Do
		
		If Price.Selected_5 Then 
			
			For Each DependentPrice In Price.DependentPrices Do
				
				DependentPriceLine         = FindPriceTypeString(Form.SelectedPrices, DependentPrice.Value);
				If DependentPriceLine <> Undefined Then
					DependentPriceLine.Depends = Not DependentPriceLine.Selected_5;
				EndIf;
				
			EndDo;
			
			For Each InfluencingPrice In Price.InfluencingPrices Do
				
				SelectedPriceLine        = FindPriceTypeString(Form.SelectedPrices, InfluencingPrice.Value);
				If SelectedPriceLine <> Undefined Then
					SelectedPriceLine.Influences = Not SelectedPriceLine.Selected_5;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Performs price rounding in accordance with the rounding rules for the price type
//
// Parameters:
//  PriceValue - Number - the price value you want to round
//  PriceCatalogLine - ValueTableRow - the type of price to round the price according to.
//
// Returns:
//  Number - Rounded price value.
//
Function RoundUpPrice(PriceValue, PriceCatalogLine) Export
	
	RowsCount = PriceCatalogLine.PriceRoundingRules.Count();
	
	For IndexOf = 1 To RowsCount Do
		
		RoundingRules = PriceCatalogLine.PriceRoundingRules[RowsCount - IndexOf];
		
		If RoundingRules.LowerBoundOfPriceRange <= PriceValue Then
			
			If ValueIsFilled(RoundingRules.RoundingPrecision) Then
				PriceValue = PriceManagementSystemClientServer.RoundUpPrice(PriceValue, RoundingRules.RoundingPrecision, PriceCatalogLine.RoundOffOption);
			EndIf;
			
			If ValueIsFilled(RoundingRules.SmartRounding) Then
				PriceValue = PriceManagementSystemClientServer.ApplyPsychologicalRounding(PriceValue, RoundingRules.SmartRounding);
			EndIf;
			
			Break;
			
		EndIf;
		
	EndDo;
	
	Return PriceValue;
	
EndFunction

// Returns a line of code in the 1C: Enterprise language for converting prices from package to package.
//
// Parameters:
//  PriceTableRow       							- FormDataCollectionItem - table row
//  PriceTypeSource   						    	- FormDataCollectionItem - the kind of prices that you want to convert
//  PriceTypePurpose  						    	- FormDataCollectionItem - the kind of prices that you want to convert
//  ComplianceOfFactorsOfPackagesOfProductRange  	- Map - key - <Item UID> + <The SDL package>, the value of the coefficient pairs of the item and packaging.
//
// Returns:
//  String - expression for converting the price from package to package.
//
Function LineForRecalculatingPackages(PriceTableRow,
	                            PriceTypeSource,
	                            PriceTypePurpose,
	                            ComplianceOfFactorsOfPackagesOfProductRange) Export
	
	LineForRecalculatingPackages = "";
	
	// Determination of the packing coefficient of the current price
	SourcePricePackaging = PriceTableRow["Package" + PriceTypeSource.ColumnName];
	SourcePricePackingRatio = 1;
	If ValueIsFilled(SourcePricePackaging) Then
		SearchResult = GetProductPackingRatio(ComplianceOfFactorsOfPackagesOfProductRange, 
																	PriceTableRow.Products, 
																	SourcePricePackaging);
		If SearchResult <> Undefined Then 
			SourcePricePackingRatio = SearchResult;
		EndIf;
	EndIf;
	
	// Determination of the packing coefficient of the influencing price
	DestinationPricePackaging = PriceTableRow["Package" + PriceTypePurpose.ColumnName];
	DestinationPricePackingRatio = 1;
	If ValueIsFilled(DestinationPricePackaging) Then	
		SearchResult = GetProductPackingRatio(ComplianceOfFactorsOfPackagesOfProductRange, 
																	PriceTableRow.Products, 
																	DestinationPricePackaging);		
		If SearchResult <> Undefined Then 
			DestinationPricePackingRatio = SearchResult;
		EndIf;																	
	EndIf;
	
	FormatString = "NDS=.; NG=0";
	If SourcePricePackingRatio <> DestinationPricePackingRatio Then
		LineForRecalculatingPackages = "/" + String(Format(SourcePricePackingRatio, FormatString))
		                          + "*" + String(Format(DestinationPricePackingRatio, FormatString));
	EndIf;
		
	Return LineForRecalculatingPackages;
	
EndFunction

// Returns a string for converting prices from currency to currency
//
// Parameters:
//  CurrencySource - CatalogRef.Currencies - the currency from which you want to convert
//  CurrencyDestination - CatalogRef.Currencies - the currency in which you want to convert.
//  MatchingCurrencies - Map - Currency exchange rates match.
//
// Returns:
//  String - expression for converting the price from currency to currency.
//
Function CurrencyConversionLine(CurrencySource, CurrencyDestination, MatchingCurrencies) Export
	
	If CurrencySource <> CurrencyDestination Then
		
		SourceCurrencyString  = FindCurrencyString(MatchingCurrencies, CurrencySource);
		DestinationCurrencyString = FindCurrencyString(MatchingCurrencies, CurrencyDestination);
		
		FormatString = "NDS=.; NG=0";
		If SourceCurrencyString <> Undefined And DestinationCurrencyString <> Undefined Then
			Return StrReplace("*(" + String(Format(SourceCurrencyString.CourseNumerator, FormatString))
			        + "*" + String(Format(DestinationCurrencyString.CourseDenominator, FormatString))
			        + ")/(" + String(Format(DestinationCurrencyString.CourseNumerator, FormatString)) + "*"
			        + String(Format(SourceCurrencyString.CourseDenominator, FormatString)) + ")", ",", ".");
		EndIf;
	EndIf;

	Return "";
	
EndFunction

// Searches for the currency exchange rate in the currency exchange rate table
//
// Parameters:
//  MatchingCurrencies - Map - exchange rate
//  Currency - CatalogRef.Currencies - link to the currency that you want to get the exchange rates for.
//
// Returns:
//  ValueTableRow - if the course is found, Undefined otherwise.
//
Function FindCurrencyString(MatchingCurrencies, Currency) Export

	If Not ValueIsFilled(Currency) Then
		Return Undefined;
	EndIf;

	CurrencyStructure = MatchingCurrencies.Get(Currency);
	
	If CurrencyStructure = Undefined Then
		CommonClientServer.MessageToUser(StrReplace(NStr("vi = 'Chưa ấn định tỷ giá ngoại tệ: %Currency%';
														|ru = 'Не установлен курс валюты: %Currency%';
														|en = 'Exchange rate is not specified: %Currency%'; fa = 'Exchange rate is not specified: %Currency%';
														|it = 'Tasso di cambio non impostato: %Currency%';
														|pl = 'Nie został ustawiony kurs waluty: %Currency%';
														|tr = 'Para birimi kuru ayarlanmadı: %Currency%'"), "%Currency%", Currency));
	EndIf;
	
	Return CurrencyStructure;
	
EndFunction

// Calculates the document date by date and number within a day
//
// Parameters:
//  DocumentDate - Date
//  RoomWithinADay - Number
//
// Returns:
//  Date - The calculated date of the document.
//
Function CalculateDocumentDate(DocumentDate, RoomWithinADay) Export
	
	Return BegOfDay(DocumentDate) + RoomWithinADay - 1;
	
EndFunction

// To note down recursively
//
// Parameters:
//  Parent - ValueTreeRow - The parent string.
//
Procedure MarkRecursivelyDown(Parent) Export
	
	For Each TreeRow In Parent.GetItems() Do
		
		TreeRow.Selected = Parent.Selected;
		
		MarkRecursivelyDown(TreeRow);
		
	EndDo;
	
EndProcedure

// Mark recursively up
//
// Parameters:
//  TreeRow - ValueTreeRow - The string tree.
//
Procedure MarkRecursivelyUpwards(TreeRow) Export
	
	Parent = TreeRow.GetParent();
	If Parent <> Undefined Then
		
		Selected = Undefined;
		For Each TSRow In Parent.GetItems() Do
			If TSRow.Selected And Selected = Undefined Then
				Selected = True;
			ElsIf Not TSRow.Selected And Selected = Undefined Then
				Selected = False;
			ElsIf Selected <> TSRow.Selected Then
				Selected = 2;
			EndIf;
		EndDo;
		
		If Selected = Undefined Then
			Selected = False;
		EndIf;
		
		Parent.Selected = Selected;
		
		MarkRecursivelyUpwards(Parent);
		
	EndIf;
	
EndProcedure

// Mark all elements of the parent recursively
//
// Parameters:
//  Parent - ValueTreeRow - The string tree.
//  On_ - Boolean - set value.
//
Procedure SetValueRecursivelyToAllElementsOfParent(Parent, On_) Export

	For Each It_ In Parent.GetItems() Do
		If Not It_.IsFolder Then
			It_.Selected = On_;
			It_.Edit = On_;	
		Else
			SettingPricesClientServer.SetValueRecursivelyToAllElementsOfParent(It_, On_);
		EndIf;
	EndDo;

EndProcedure 

// Add all elements of the parent recursively
//
// Parameters:
//  Parent - ValueTreeRow - The string tree.
//  TableOfPriceTypes - ValueTable - Data on types of prices.
//
Procedure AddRecursivelyAllSelectedElementsOfParent(Parent, TableOfPriceTypes) Export

	For Each It_ In Parent.GetItems() Do
		If Not It_.IsFolder And It_.Selected Then
			NwRw = TableOfPriceTypes.Add();
			NwRw.PriceKind = It_.Ref;
			NwRw.AddlOrderingAttribute = TableOfPriceTypes.Count();
		Else
			SettingPricesClientServer.AddRecursivelyAllSelectedElementsOfParent(It_, TableOfPriceTypes);
		EndIf;
	EndDo;

EndProcedure 


// Fill in all elements of the parent recursively
//
// Parameters:
//  Parent - ValueTreeRow - The string tree.
//  TableOfPriceTypes - ValueTable - Data on types of prices.
//
Procedure FillInPropertyValuesRecursively(Parent, TableOfPriceTypes) Export

	For Each TreeItem In Parent.Rows Do
		If Not TreeItem.IsFolder Then
			TableRow = TableOfPriceTypes.Find(TreeItem.Ref,"Ref");	
			If TableRow <> Undefined Then
				FillPropertyValues(TreeItem, TableRow);
				TreeItem.Selected = TableRow.Selected_5;
			EndIf;
		Else
			SettingPricesClientServer. FillInPropertyValuesRecursively(TreeItem, TableOfPriceTypes);
		EndIf;
	EndDo;

EndProcedure 

// Fill in the property value recursively
// 
// Parameters:
// 	Parent - FormDataTreeItem
// 	TableOfPriceTypes - ValueTable
Procedure FillPropertyValuesRecursivelyIntoTable(Parent, TableOfPriceTypes) Export

	For Each TreeItem In Parent.GetItems() Do
		If Not TreeItem.IsFolder Then
			TableRow = TableOfPriceTypes.Add();
			FillPropertyValues(TableRow, TreeItem);
			TableRow.Selected_5 = TreeItem.Selected;
		Else
			SettingPricesClientServer. FillPropertyValuesRecursivelyIntoTable(TreeItem, TableOfPriceTypes);
		EndIf;
	EndDo;

EndProcedure 

// Function to Obtain the coefficient of packing of the item
//
// Parameters:
//  MatchingCoefficients	 - 	Map 					- key - <Item UID> + <The SDL package>, the value of the coefficient pairs of the item and packaging
//  Products	 - 	CatalogRef.Products 				- the item to be searched for
//  Package		 - 	CatalogRef.PackagesAndUnitsOfMeasure 	- package/unit of measurement to be searched for.
// 
// Returns:
//  Number, Undefined - Packing coefficient relative to the nomenclature; Undefined - if the pair "Nomenclature +
//  Packaging" not found.
//
Function GetProductPackingRatio(MatchingCoefficients, Products, Package) Export
	
	SearchString = String(Products.UUID()) + String(Package.UUID());
	Return MatchingCoefficients.Get(SearchString);
	
EndFunction

// Function-Get the structure of item packages
// 
// Returns:
//  Structure - structure with the keys Nomenclature and Packaging.
//
Function InitializeProductPackagingDescription() Export
	
	Return New Structure("Products, Package");
	
EndFunction

// A function to Find the packing structure of items in the array
//
// Parameters:
//  StructuresArray	 - 	Array 										- Array of structures with the keys Nomenclature and Packaging
//  Products	 - 	CatalogRef.Products 				- the item to be searched for
//  Package		 - 	CatalogRef.PackagesAndUnitsOfMeasure 	- package/unit of measurement to be searched for.
// 
// Returns:
//  Structure, Undefined - the structure found or Undefined if nothing is found.
//
Function FindProductPackingStructureInArray(StructuresArray, Products, Package) Export 
	
	For Each Structure In StructuresArray Do
		
		If Structure.Products = Products And Structure.Package = Package Then
			Return Structure;
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

// New structure of form settings.
// 
// Returns:
//  Structure -New Form Settings Structure:
// * ValidPriceDate - Date -
// * ShowMarkupPercent - Boolean -
// * ShowPriceChange - Boolean -
// * ShowEffectivePrices - Boolean -
// * ShowFormulas - Boolean -
// * ShowCurrency - Boolean -
// * ShowVATRate - Boolean -
// * ShowUnitsOfMeasurement - Boolean -
// * ShowTheQuickEditPanel - Boolean -
// * OptionForSettingThePrice - Number -
// * FilterSettingsAreSet - Boolean -
// * ShowInfluencingPrices - Boolean -
// * UseOneColumnForThePriceKey - Boolean -
// * FixTheItemColumn - Boolean -
// * ProductKind - CatalogRef.ItemKinds -
// * NavigationOption - String -
// * GroupingOption - String -
// * SettingKind - String -
// * FilterParametersTable - ValueTable -
// * SelectedPrices - See SettingPricesClientServer.SelectedTypesOfPrices
// * SelectedPricesTable - See SettingPricesServer.SelectedTypesOfPricesInTable
// * ComposerSettings - DataCompositionSettings -
// * ColumnComposerSettings - DataCompositionSettings -
// * ColumnComposerSettings - String -
Function NewFormSettingsStructure() Export
	
	Result = New Structure();
	
	Result.Insert("ComposerSettings");
	Result.Insert("ColumnComposerSettings");
	Result.Insert("SelectedPrices");
	Result.Insert("SelectedPricesTable", Undefined);
	Result.Insert("FilterParametersTable");
	Result.Insert("SettingKind");
	Result.Insert("NavigationOption");
	Result.Insert("GroupingOption");
	Result.Insert("ProductKind");
	Result.Insert("FilterSettingsAreSet");
	Result.Insert("ShowEffectivePrices", False);
	Result.Insert("ShowPriceChange", False);
	Result.Insert("ShowMarkupPercent", False);
	Result.Insert("ShowFormulas", False);
	Result.Insert("ShowCurrency", True);
	Result.Insert("ShowVATRate", False);
	Result.Insert("ShowUnitsOfMeasurement", True);
	Result.Insert("CalculateAutomatically", True);
	Result.Insert("ShowInfluencingPrices", False);
	Result.Insert("UseOneColumnForThePriceKey", True);
	Result.Insert("OptionForSettingThePrice", 3);
	Result.Insert("FixTheItemColumn", True);
	Result.Insert("ShowTheQuickEditPanel", True);
	Result.Insert("ValidPriceDate");
	
	Return Result;
	
EndFunction

// Checks filling in the "VAT rates" field for price types selected by the user
//
// Parameters:
//  Form - Form - Formaclient applications.
//  Cancel - Boolean - indicates that the document was not recorded.
//  OnlyChangedItems - Boolean - indicates that only modified rows are checked.
//
Procedure CheckFillingInVATRateOfPriceTree(Form, Cancel, OnlyChangedItems = False) Export
	
	ArrayOfPriceTypes = New Array();
	For Each LineTypesOfPrice In Form.SelectedPrices Do
		
		If Not (LineTypesOfPrice.Selected_5 And LineTypesOfPrice.Edit) Then
			Continue;
		EndIf;
		
		If LineTypesOfPrice.OptionForSpecifyingVATRates = PredefinedValue("Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifiedVATRatesLineByLine") Then
			ArrayOfPriceTypes.Add(New Structure("Description, ColumnName", LineTypesOfPrice["Description"], LineTypesOfPrice.ColumnName));
		EndIf;
			
	EndDo;
	
	If Not ValueIsFilled(ArrayOfPriceTypes) Then
		Return;
	EndIf;
	
	ErrorsArray = New Array;
	FindVATRatesThatAreNotFilledInRecursively(Form.PriceTree.GetItems(), ArrayOfPriceTypes, ErrorsArray, OnlyChangedItems);
	
	If ValueIsFilled(ErrorsArray) Then
		For Each ArrayElement In ErrorsArray Do
			
			#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
				Common.MessageToUser(ArrayElement,,,, Cancel);
			#Else
				CommonClient.MessageToUser(ArrayElement,,,, Cancel);
			#EndIf
			
		EndDo;
	EndIf;
	
EndProcedure

// Returns an array of links to the price types selected by the user
//
// Parameters:
//  Parent - FormDataCollectionItem
//  ArrayOfPriceTypes - Array - Array of structures with Column Name and Column name keys.
//  ErrorsArray - Array - Array of errors.
//  OnlyChangedItems - Boolean - indicates that only modified rows are checked.
//
Procedure FindVATRatesThatAreNotFilledInRecursively(Parent, ArrayOfPriceTypes, ErrorsArray, OnlyChangedItems) Export
	
	For Each TreeItem In Parent Do
		
		If ErrorsArray.Count() > 10 Then
			Break;
		EndIf;
		
		ChildItems = TreeItem.GetItems();
		If ChildItems.Count() > 0 Then
			
			FindVATRatesThatAreNotFilledInRecursively(ChildItems, ArrayOfPriceTypes, ErrorsArray, OnlyChangedItems);
			
		Else
			
			ArrayOfBlankOnes = New Array;
			For Each PriceKind In ArrayOfPriceTypes Do
				
				If	OnlyChangedItems
						And Not TreeItem["ChangedManually" + PriceKind.ColumnName]
						And Not TreeItem["ChangedAutomatically" + PriceKind.ColumnName]
						And Not TreeItem["ManuallyChangedVATRate" + PriceKind.ColumnName]
						And Not TreeItem["VATRateChangedAutomatically" + PriceKind.ColumnName] Then
					Continue;
				EndIf;
				
				If Not ValueIsFilled(TreeItem["VATRate" + PriceKind.ColumnName]) Then
					ArrayOfBlankOnes.Add(PriceKind["Description"]);
				EndIf;
			EndDo;
			
			If ValueIsFilled(ArrayOfBlankOnes) Then
			
				ArrayNames = New Array;
				ArrayNames.Add(TreeItem.Products);
				
				If ValueIsFilled(TreeItem.PricingVariant) Then
					ArrayNames.Add(TreeItem.PricingVariant);
				EndIf;
				
				If ValueIsFilled(TreeItem.PricingBatch) Then
					ArrayNames.Add(TreeItem.PricingBatch);
				EndIf;
				
				If ValueIsFilled(TreeItem.PricingPackage) Then
					ArrayNames.Add(TreeItem.PricingPackage);
				EndIf;
				
				ErrorText = StrTemplate(
					NStr("ru = 'Для номенклатуры ""%1"" по виду цен ""%2"", не заполнено поле ""Ставка НДС"".';
						|vi = 'For the ""%1"" item, for the ""%2"" price type, the ""VAT rate"" field is not filled in.';
						|en = 'For the ""%1"" item, for the ""%2"" price type, the ""VAT rate"" field is not filled in.'; fa = 'For the ""%1"" item, for the ""%2"" price type, the ""VAT rate"" field is not filled in.';
						|it = 'For the ""%1"" item, for the ""%2"" price type, the ""VAT rate"" field is not filled in.';
						|pl = 'For the ""%1"" item, for the ""%2"" price type, the ""VAT rate"" field is not filled in.';
						|tr = '""%2"" fiyat türü kapsamında ""%1"" öğesi için ünde ""KDV oranı"" alanı doldurulmadı.'"),
					StrConcat(ArrayNames, ", "),
					StrConcat(ArrayOfBlankOnes, ", "));
			
				ErrorsArray.Add(ErrorText);
			
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion