//@strict-types

#Region Public

// The procedure sets the visibility of form elements by an array of names.
//
// Parameters:
//	Items - FormAllItems - Collection of form elements
//	ArrayOfAllProps - Array of String - Array of names of details to set visibility for
//	ArrayOnlyViewDetails - Array of String - Array of names of details that should be visible on the form.
//
Procedure SetOnlyViewOfElementsByArray(Items, Val ArrayOfAllProps, Val ArrayOnlyViewDetails) Export
	
	If TypeOf(ArrayOnlyViewDetails) <> Type("Array") Then
		ArrayOnlyViewDetails = New Array;
	EndIf;
	
	For Each ArrayElement In ArrayOfAllProps Do
		
		AttributeName = StrReplace(ArrayElement, ".", "");
		
		// If there is no Attribute in the array of view-only Attributes, we remove only the view of the form element.
		OnlyViewingProps = (ArrayOnlyViewDetails.Find(ArrayElement) <> Undefined);
		If Items.Find(AttributeName) <> Undefined
		 And Items[AttributeName].ReadOnly <> OnlyViewingProps Then
			Items[AttributeName].ReadOnly = OnlyViewingProps;
		EndIf;
		
	EndDo;
	
EndProcedure

// Check to set the value of the selection list.
// 
// Parameters:
//  Object - See Catalog.CustomerRebatesKinds.Form.ItemForm.Object
//  AttributePath1 - String - Path to the Attribute of the form object that stores the value 
//  AllowedValues - Array of EnumRef - Array of valid values for Attributes 
//
Procedure CheckSetValueOfSelectionList(Object, Val AttributePath1, Val AllowedValues) Export
	
	CurrentValue = Object[AttributePath1]; // EnumRef
	
	If AllowedValues.Count() = 0 Then
		
		Object[AttributePath1] = Undefined;
		 
	ElsIf AllowedValues.Find(CurrentValue) = Undefined Then
		
		Object[AttributePath1] = AllowedValues[0];
		
	EndIf;
	
EndProcedure

// Parameters for creating a list of available goods indicators
//
// Returns:
//  Structure - New Parameters Of Available Goods Indicators:
//	* WithoutCalculation - Boolean - 
//	* BonusType - EnumRef.VendorRebateTypes - 
//
Function NewParametersOfAvailableGoodsIndicators() Export
	
	NewParameters = New Structure;
	NewParameters.Insert("WithoutCalculation", False);
	NewParameters.Insert(
		"BonusType",
		PredefinedValue("Enum.VendorRebateTypes.EmptyRef"));
	
	Return NewParameters;
	
EndFunction

// Available list of sales figures
//
// Parameters:
// 	Parameters - See NewParametersOfAvailableGoodsIndicators
// 	  
// Returns:
//  Array of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
//
Function AvailableListOfGoodsIndicators(Parameters) Export
	
	WithoutCalculation = Parameters.WithoutCalculation;
	BonusType = Parameters.BonusType;
	
	Values = New Array; // Array of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	
	If WithoutCalculation Then
		
		Values.Add(PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.NotUsed"));
		
	ElsIf BonusType = PredefinedValue("Enum.VendorRebateTypes.Purchases")
		  Or BonusType = PredefinedValue("Enum.VendorRebateTypes.Sales") Then
		
		Values.Add(PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.NotUsed"));
		Values.Add(PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.Count"));
		Values.Add(PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.QuantityTotal"));
		Values.Add(PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.BatchOffer"));
		Values.Add(PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.Sum"));
		
	Else
		
		Values.Add(PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.NotUsed"));
		
	EndIf;
	
	Return Values;
	
EndFunction

// Parameters for generating a list of available sales calculation databases
//
// Returns:
//  Structure - New Parameters Of Available Sales Calculation Databases:
//	* WithoutCalculation - Boolean - 
//	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods -
//	* BonusType - EnumRef.VendorRebateTypes, Undefined - for the types of retro bonuses of suppliers, otherwise it is uncertain
//
Function NewParametersOfAvailableRebateCalculationBasesOfRetroBonuses() Export
	
	NewParameters = New Structure;
	NewParameters.Insert("WithoutCalculation", False);
	NewParameters.Insert(
		"GoodsIndicator",
		PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.EmptyRef"));
	NewParameters.Insert(
		"BonusType",
		Undefined);
	
	Return NewParameters;
	
EndFunction

// Available list of participants by type of retro bonus
//
// Parameters:
// 	Parameters - See NewParametersOfAvailableRebateCalculationBasesOfRetroBonuses
// 	  
// Returns:
//  Array of EnumRef.RebateCalculationBases
//
Function AvailableListOfRebateCalculationBasesForCalculationOfRetroBonuses(Parameters) Export
	
	WithoutCalculation = Parameters.WithoutCalculation;
	GoodsIndicator = Parameters.GoodsIndicator;
	BonusType = Parameters.BonusType;
	
	Values = New Array; // Array of EnumRef.RebateCalculationBases
	
	If WithoutCalculation
	 Or BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance") Then
		
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.EmptyRef"));
		
	ElsIf BonusType = PredefinedValue("Enum.VendorRebateTypes.Purchases") Then
		
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.PurchaseAmountLocalAccounting"));
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.PurchaseAmountARAPAccounting"));
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.PurchaseAmountBasePrices"));
		
	ElsIf BonusType = PredefinedValue("Enum.VendorRebateTypes.Sales") Then
		
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.RevenueLocalAccounting"));
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.RevenueBasePrices"));
		
	ElsIf GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.Sum") Then
		
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.RevenueManagementAccounting"));
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.RevenueLocalAccounting"));
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.RevenueBasePrices"));
		
	ElsIf GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.Count")
		  Or GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.QuantityTotal")
		  Or GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.BatchOffer")
		  Or GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.NotUsed") Then
		
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.RevenueManagementAccounting"));
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.RevenueLocalAccounting"));
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.RevenueARAPAccounting"));
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.RevenueBasePrices"));
		
	Else
		
		Values.Add(PredefinedValue("Enum.RebateCalculationBases.EmptyRef"));
		
	EndIf;
	
	Return Values;
	
EndFunction

// Parameters for creating a list of available orders for specifying goods
// 
// Returns:
//  Structure - New parameters for the available goods indication procedures:
//	* WithoutCalculation - Boolean - 
//	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods -
//	* BaseOfCalculation - EnumRef.RebateCalculationBases -
//	* UseProductSegments - Boolean -
//	* BonusType - EnumRef.VendorRebateTypes, Undefined - for the types of retro bonuses of suppliers, otherwise Uncertain 
// 
Function NewParametersOfAvailableGoodsCompositions() Export
	
	NewParameters = New Structure;
	NewParameters.Insert("WithoutCalculation", False);
	NewParameters.Insert(
		"GoodsIndicator",
		PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.EmptyRef"));
	NewParameters.Insert(
		"BaseOfCalculation",
		PredefinedValue("Enum.RebateCalculationBases.EmptyRef"));
	NewParameters.Insert("UseProductSegments", False);
	NewParameters.Insert(
		"BonusType",
		Undefined);
	
	Return NewParameters;
	
EndFunction

// Available list of goods by type of retro bonus
// 
// Parameters:
// 	Parameters - See NewParametersOfAvailableGoodsCompositions
// 
// Returns:
//  Array of EnumRef.RebatesItems
//
Function AvailableListCompositionOfGoods(Parameters) Export
	
	WithoutCalculation = Parameters.WithoutCalculation;
	BonusType = Parameters.BonusType;
	GoodsIndicator = Parameters.GoodsIndicator;
	BaseOfCalculation = Parameters.BaseOfCalculation;
	
	Values = New Array; // Array of EnumRef.RebatesItems
	
	If WithoutCalculation Then
		
		Values.Add(PredefinedValue("Enum.RebatesItems.EmptyRef"));
		
	ElsIf BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance") Then
		
		Values.Add(PredefinedValue("Enum.RebatesItems.Products"));
		
	ElsIf GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.Count")
		  Or GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.QuantityTotal")
		  Or GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.BatchOffer")
		  Or BaseOfCalculation = PredefinedValue("Enum.RebateCalculationBases.RevenueBasePrices")
		  Or BaseOfCalculation = PredefinedValue("Enum.RebateCalculationBases.PurchaseAmountBasePrices") Then
		
		Values.Add(PredefinedValue("Enum.RebatesItems.Products"));
		Values.Add(PredefinedValue("Enum.RebatesItems.ProductItemProperty"));
		
	Else
		
		Values.Add(PredefinedValue("Enum.RebatesItems.Products"));
		Values.Add(PredefinedValue("Enum.RebatesItems.ProductItemProperty"));
		If Parameters.UseProductSegments Then
			Values.Add(PredefinedValue("Enum.RebatesItems.ProductSegments"));
		EndIf;
		
	EndIf;
	
	Return Values;
	
EndFunction

// Parameters for creating a list of available product selections
//
// Returns:
//  Structure - New Parameters For Available Goods Selections:
//	* WithoutCalculation - Boolean - 
//	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods - 
//	* BaseOfCalculation - EnumRef.RebateCalculationBases - 
//	* ContentOfGoods - EnumRef.RebatesItems -
//	* BonusType - EnumRef.VendorRebateTypes, Undefined - for the types of retro bonuses of suppliers, otherwise it is uncertain
//
Function NewParametersForAvailableGoodsSelections() Export
	
	NewParameters = New Structure;
	NewParameters.Insert("WithoutCalculation", False);
	NewParameters.Insert(
		"GoodsIndicator",
		PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.EmptyRef"));
	NewParameters.Insert(
		"BaseOfCalculation",
		PredefinedValue("Enum.RebateCalculationBases.EmptyRef"));
	NewParameters.Insert(
		"ContentOfGoods",
		PredefinedValue("Enum.RebatesItems.EmptyRef"));
	NewParameters.Insert("BonusType", Undefined);
	
	Return NewParameters;
	
EndFunction

// Available list of product selections by type of retro bonus
// 
// Parameters:
// 	Parameters - See NewParametersForAvailableGoodsSelections
// 	  
// Returns:
//  Array of EnumRef.RebatesLists
//
Function AvailableListSelectionOfGoods(Parameters) Export
	
	WithoutCalculation = Parameters.WithoutCalculation;
	BaseOfCalculation = Parameters.BaseOfCalculation;
	GoodsIndicator = Parameters.GoodsIndicator;
	ContentOfGoods = Parameters.ContentOfGoods;
	BonusType = Parameters.BonusType;
	
	Values = New Array; // Array of EnumRef.RebatesLists
	
	If WithoutCalculation Then
		
		Values.Add(PredefinedValue("Enum.RebatesLists.EmptyRef"));
		
	ElsIf ContentOfGoods = PredefinedValue("Enum.RebatesItems.ProductSegments") Then
		
		Values.Add(PredefinedValue("Enum.RebatesLists.Selected_"));
		Values.Add(PredefinedValue("Enum.RebatesLists.ExceptForSelectedOnes"));
		
	ElsIf BaseOfCalculation = PredefinedValue("Enum.RebateCalculationBases.RevenueBasePrices")
	      Or BaseOfCalculation = PredefinedValue("Enum.RebateCalculationBases.PurchaseAmountBasePrices")
	      Or (GoodsIndicator <> PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.NotUsed")
	           And GoodsIndicator <> PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.Sum"))
	      Or BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance") Then
		
		Values.Add(PredefinedValue("Enum.RebatesLists.Selected_"));
		
	Else
		
		If ContentOfGoods <> PredefinedValue("Enum.RebatesItems.ProductItemProperty") Then
			Values.Add(PredefinedValue("Enum.RebatesLists.All"));
		EndIf;
		Values.Add(PredefinedValue("Enum.RebatesLists.Selected_"));
		Values.Add(PredefinedValue("Enum.RebatesLists.ExceptForSelectedOnes"));
		
	EndIf;
	
	Return Values;
	
EndFunction

// Parameters for creating a list of available participant lineups
// 
// Returns:
//  Structure - New Parameters For Available Goods Selections:
//	* WithoutCalculation - Boolean - 
//	* UsePartnersSegments - Boolean -
//	* BonusType - EnumRef.VendorRebateTypes, Undefined - for the types of retro bonuses of suppliers, otherwise Uncertain 
//	* UseContracts - Boolean -
//	* UseStandardConventions - Boolean -
//	* UseIndividualAgreements - Boolean -
// 
Function NewParametersOfAvailableParticipantLineups() Export
	
	NewParameters = New Structure;
	NewParameters.Insert("WithoutCalculation", False);
	NewParameters.Insert("UsePartnersSegments", False);
	NewParameters.Insert("UseContracts", False);
	NewParameters.Insert("UseStandardConventions", False);
	NewParameters.Insert("UseIndividualAgreements", False);
	NewParameters.Insert(
		"BonusType",
		Undefined);
	
	Return NewParameters;
	
EndFunction

// Available list of participants by type of retro bonus
// 
// Parameters:
// 	Parameters - See NewParametersOfAvailableParticipantLineups
// 
// Returns:
//  Array of EnumRef.RebatesParticipants
//
Function AvailableListCompositionOfParticipants(Parameters) Export
	
	BonusType = Parameters.BonusType;
	
	Values = New Array; // Array of EnumRef.RebatesParticipants
	
	If BonusType = Undefined Then
		
		If Parameters.WithoutCalculation Then
			
			Values.Add(PredefinedValue("Enum.RebatesParticipants.Counterparties"));
			Values.Add(PredefinedValue("Enum.RebatesParticipants.Customers"));
			
		Else
			
			Values.Add(PredefinedValue("Enum.RebatesParticipants.Counterparties"));
			Values.Add(PredefinedValue("Enum.RebatesParticipants.TIN"));
			Values.Add(PredefinedValue("Enum.RebatesParticipants.Customers"));
			If Parameters.UsePartnersSegments Then
				
				Values.Add(PredefinedValue("Enum.RebatesParticipants.PartnersSegments"));
				
			EndIf;
			
			If Parameters.UseContracts Then
				
				Values.Add(PredefinedValue("Enum.RebatesParticipants.Contracts"));
				
			EndIf;
			
			If Parameters.UseStandardConventions
			 Or Parameters.UseIndividualAgreements Then
				
				Values.Add(PredefinedValue("Enum.RebatesParticipants.Terms1"));
				
			EndIf;
			
		EndIf;
		
	ElsIf BonusType = PredefinedValue("Enum.VendorRebateTypes.Sales") Then
		
		Values.Add(PredefinedValue("Enum.RebatesParticipants.Counterparties"));
		Values.Add(PredefinedValue("Enum.RebatesParticipants.TIN"));
		
	Else
		
		Values.Add(PredefinedValue("Enum.RebatesParticipants.EmptyRef"));
	
	EndIf;
	
	Return Values;
	
EndFunction

// Parameters for creating a list of available product selections
// 
// Returns:
//  Structure - New Parameters For Available Goods Selections:
//	* WithoutCalculation - Boolean - 
//	* PartyList - EnumRef.RebatesParticipants - 
// 
Function NewParametersOfAvailableSelectionsOfParticipants() Export
	
	NewParameters = New Structure;
	NewParameters.Insert("WithoutCalculation", False);
	NewParameters.Insert(
		"PartyList",
		PredefinedValue("Enum.RebatesParticipants.EmptyRef"));
	
	Return NewParameters;
	
EndFunction

// Available list of selection of participants by type of retro bonus
// 
// Parameters:
//	Parameters - See NewParametersOfAvailableSelectionsOfParticipants
// 
// Returns:
//  Array of EnumRef.RebatesLists
//
Function AvailableListOfSelectionOfParticipants(Parameters) Export
	
	WithoutCalculation = Parameters.WithoutCalculation;
	PartyList = Parameters.PartyList;
	
	Values = New Array; // Array of EnumRef.RebatesLists
	
	If PartyList = PredefinedValue("Enum.RebatesParticipants.Contracts")
	 Or PartyList = PredefinedValue("Enum.RebatesParticipants.Terms1") Then
		
		Values.Add(PredefinedValue("Enum.RebatesLists.Selected_"));
	
	ElsIf PartyList = PredefinedValue("Enum.RebatesParticipants.PartnersSegments") Then
		
		Values.Add(PredefinedValue("Enum.RebatesLists.Selected_"));
		Values.Add(PredefinedValue("Enum.RebatesLists.ExceptForSelectedOnes"));
		
	ElsIf WithoutCalculation Then
		
		Values.Add(PredefinedValue("Enum.RebatesLists.Selected_"));
		
	Else
		
		Values.Add(PredefinedValue("Enum.RebatesLists.All"));
		Values.Add(PredefinedValue("Enum.RebatesLists.Selected_"));
		Values.Add(PredefinedValue("Enum.RebatesLists.ExceptForSelectedOnes"));
		
	EndIf;
	
	Return Values;
	
EndFunction

// Parameters for creating a list of available accrual time fences
// 
// Returns:
//  Structure - New Parameters For Available Goods Selections:
//	* GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods -
//	* ConditionFrequency - EnumRef.RebatesFrequencies -
//	* BonusType - EnumRef.VendorRebateTypes, Undefined - for the types of retro bonuses of suppliers, otherwise Uncertain
// 
Function NewParametersOfAvailableAccrualTimeFences() Export
	
	NewParameters = New Structure;
	NewParameters.Insert(
		"GoodsIndicator",
		PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.NotUsed"));
	NewParameters.Insert(
		"ConditionFrequency",
		PredefinedValue("Enum.RebatesFrequencies.EmptyRef"));
	NewParameters.Insert(
		"BonusType",
		Undefined);
		
	Return NewParameters;
	
EndFunction

// Available list of selection of participants by type of retro bonus
// 
// Parameters:
//	Parameters - See NewParametersOfAvailableAccrualTimeFences
// 
// Returns:
//  Array of EnumRef.RebatesFrequencies
//
Function AvailableListOfTimeFenceOfAccruals(Parameters) Export
	
	GoodsIndicator = Parameters.GoodsIndicator;
	ConditionFrequency = Parameters.ConditionFrequency;
	
	Values = New Array; // Array of EnumRef.RebatesFrequencies
	
	If Parameters.BonusType = PredefinedValue("Enum.VendorRebateTypes.Balance") Then
		
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.EmptyRef"));
		
	ElsIf GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.NotUsed") Then
		
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Single"));
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Day"));
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Week"));
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Month"));
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Quarter"));
		
	ElsIf ConditionFrequency = PredefinedValue("Enum.RebatesFrequencies.Week") Then
		
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Single"));
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Week"));
		
	ElsIf ConditionFrequency = PredefinedValue("Enum.RebatesFrequencies.Quarter") Then
		
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Single"));
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Quarter"));
		
	ElsIf ConditionFrequency = PredefinedValue("Enum.RebatesFrequencies.Month") Then
		
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Single"));
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Month"));
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Quarter"));
		
	ElsIf ConditionFrequency = PredefinedValue("Enum.RebatesFrequencies.Day") Then
		
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Single"));
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Day"));
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Week"));
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Month"));
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Quarter"));
		
	ElsIf ConditionFrequency = PredefinedValue("Enum.RebatesFrequencies.WholePeriod")
		  Or ConditionFrequency = PredefinedValue("Enum.RebatesFrequencies.EmptyRef") Then
		
		Values.Add(PredefinedValue("Enum.RebatesFrequencies.Single"));
		
	Else
		
		TextTemplate1 = NStr("vi = 'Giá trị không hợp lệ ""%1"" %2 trong %3';
							|ru = 'Недопустимое значение ""%1"" %2 в %3';
							|en = 'Invalid value ""%1"" %2 in %3'; fa = 'Invalid value ""%1"" %2 in %3';
							|it = 'Недопустимое значение ""%1"" %2 в %3';
							|pl = 'Invalid value ""%1"" %2 in %3';
							|tr = 'Geçersiz değer “%1” %2 içinde %3'");
		AttributeName = "Object.ConditionFrequency";
		CommonModuleName = "RebatesClientServer.AvailableListOfTimeFenceOfAccruals";
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			TextTemplate1,
			String(ConditionFrequency),
			AttributeName,
			CommonModuleName);
		Raise ExceptionText;
		
	EndIf;
	
	Return Values;
	
EndFunction

// Returns the page title based on the transmitted composition and selection settings
// 
// Parameters:
//  ListComposition - EnumRef.RebatesItems, EnumRef.RebatesParticipants -
//  ListFilter - EnumRef.RebatesLists -
//  SupplierBonus - Boolean - a sign of processing by supplier
// 
// Returns:
//  String - Page Title By Settings
//
Function PageTitleBySettings(ListComposition, ListFilter, SupplierBonus = False) Export
	
	PageHeader = "";
	SelectedValues = PredefinedValue("Enum.RebatesLists.Selected_");
	ExceptForSelectedOnes = PredefinedValue("Enum.RebatesLists.ExceptForSelectedOnes");
	
	#Region GoodsRebates_ItemList___________
	If ListComposition = PredefinedValue("Enum.RebatesItems.Products") Then
		
		If ListFilter = SelectedValues Then
			
			PageHeader = NStr("vi = 'Hàng hóa được chọn';
								|ru = 'Выбранные товары';
								|en = 'Selected goods'; fa = 'کالای انتخاب‌شده';
								|it = 'Выбранные товары';
								|pl = 'Wybrane towary';
								|tr = 'Seçili ürünler'");
			
		ElsIf ListFilter = ExceptForSelectedOnes Then
			
			PageHeader = NStr("vi = 'Ngoại trừ mặt hàng';
								|ru = 'Кроме товаров';
								|en = 'Except for goods'; fa = 'Except for goods';
								|it = 'Кроме товаров';
								|pl = 'Except for goods';
								|tr = 'Ürünler hariç'");
			
		Else
			
			PageHeader = NStr("vi = 'Hàng hóa';
								|ru = 'Товары';
								|en = 'Goods'; fa = 'کالاها';
								|it = 'Товары';
								|pl = 'Goods';
								|tr = 'Ürünler'");
			
		EndIf;
		
	EndIf;
	#EndRegion
	
	#Region CompositionOfItemsOfRebates_PropertyOfNomenclature
	If ListComposition = PredefinedValue("Enum.RebatesItems.ProductItemProperty") Then
		
		If ListFilter = SelectedValues Then
			
			PageHeader = NStr("vi = 'Giá trị thuộc tính được chọn';
								|ru = 'Выбранные значения свойства';
								|en = 'Selected property values'; fa = 'Selected property values';
								|it = 'Selected property values';
								|pl = 'Selected property values';
								|tr = 'Seçilen özellik değerleri'");
			
		ElsIf ListFilter = ExceptForSelectedOnes Then
			
			PageHeader = NStr("vi = 'Ngoài giá trị thuộc tính';
								|ru = 'Кроме значений свойств';
								|en = 'Except for property values'; fa = 'Except for property values';
								|it = 'Except for property values';
								|pl = 'Except for property values';
								|tr = 'Özellik değerleri dışında'");
			
		Else
			
			PageHeader = NStr("vi = 'Giá trị thuộc tính';
								|ru = 'Значения свойств';
								|en = 'Property values'; fa = 'مقادیر خصوصیت';
								|it = 'Property values';
								|pl = 'Property values';
								|tr = 'Özellik değerleri'");
			
		EndIf;
		
	EndIf;
	#EndRegion
	
	#Region CompositionOfRebateGoods_ItemSegments
	If ListComposition = PredefinedValue("Enum.RebatesItems.ProductSegments") Then
		
		If ListFilter = SelectedValues Then
			
			PageHeader = NStr("vi = 'Phân khúc được chọn';
								|ru = 'Выбранные сегменты товаров';
								|en = 'Selected goods segments'; fa = 'Selected goods segments';
								|it = 'Выбранные сегменты товаров';
								|pl = 'Selected goods segments';
								|tr = 'Seçili ürün segmentleri'");
			
		ElsIf ListFilter = ExceptForSelectedOnes Then
			
			PageHeader = NStr("vi = 'Ngoại trừ phân khúc mặt hàng';
								|ru = 'Кроме сегментов товаров';
								|en = 'Except for goods segments'; fa = 'Except for goods segments';
								|it = 'Кроме сегментов товаров';
								|pl = 'Except for goods segments';
								|tr = 'Ürün segmentleri hariç'");
			
		Else
			
			PageHeader = NStr("vi = 'Phân khúc mặt hàng';
								|ru = 'Сегменты товаров';
								|en = 'Goods segments'; fa = 'بخش‌های کالا';
								|it = 'Сегменты товаров';
								|pl = 'Goods segments';
								|tr = 'Ürün segmentleri'");
			
		EndIf;
		
	EndIf;
	#EndRegion
	
	#Region MembersOfRebatesOfVRetroBonuses_Counterparties
	If ListComposition = PredefinedValue("Enum.RebatesParticipants.Counterparties") Then
		
		If SupplierBonus Then
			
			If ListFilter = SelectedValues Then
				
				PageHeader = NStr("vi = 'Khách hàng: đối tác được chọn';
									|ru = 'Клиенты: выбранные контрагенты';
									|en = 'Customers: selected counterparties'; fa = 'Customers: selected counterparties';
									|it = 'Клиенты: выбранные контрагенты';
									|pl = 'Customers: selected counterparties';
									|tr = 'Müşteriler: Seçili cari hesaplar'");
				
			ElsIf ListFilter = ExceptForSelectedOnes Then
				
				PageHeader = NStr("vi = 'Khách hàng: ngoài đối tác';
									|ru = 'Клиенты: кроме контрагентов';
									|en = 'Customers: except for counterparties'; fa = 'Customers: except for counterparties';
									|it = 'Клиенты: кроме контрагентов';
									|pl = 'Customers: except for counterparties';
									|tr = 'Müşteriler: Cari hesaplar hariç'");
				
			Else
				
				PageHeader = NStr("vi = 'Khách hàng';
									|ru = 'Клиенты';
									|en = 'Customers'; fa = 'مشتریان';
									|it = 'Клиенты';
									|pl = 'Customers';
									|tr = 'Müşteriler'");
				
			EndIf;
			
		ElsIf ListFilter = SelectedValues Then
			
			PageHeader = NStr("vi = 'Đối tác được chọn';
								|ru = 'Выбранные контрагенты';
								|en = 'Selected counterparties'; fa = 'Selected counterparties';
								|it = 'Выбранные контрагенты';
								|pl = 'Selected counterparties';
								|tr = 'Seçili cari hesaplar'");
			
		ElsIf ListFilter = ExceptForSelectedOnes Then
			
			PageHeader = NStr("vi = 'Ngoại trừ đối tác';
								|ru = 'Кроме контрагентов';
								|en = 'Except for counterparties'; fa = 'Except for counterparties';
								|it = 'Кроме контрагентов';
								|pl = 'Except for counterparties';
								|tr = 'Cari hesaplar hariç'");
			
		Else
			
			PageHeader = NStr("vi = 'Đối tác';
								|ru = 'Контрагенты';
								|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
								|it = 'Контрагенты';
								|pl = 'Counterparties';
								|tr = 'Cari hesaplar'");
			
		EndIf;
	EndIf;
	#EndRegion
	
	#Region CompositionOfRebateMembersOfVRetroBonuses_Customers
	If ListComposition = PredefinedValue("Enum.RebatesParticipants.Customers") Then
		
		If ListFilter = SelectedValues Then
			
			PageHeader = NStr("vi = 'Khách hàng được chọn';
								|ru = 'Выбранные клиенты';
								|en = 'Selected customers'; fa = 'Selected customers';
								|it = 'Выбранные клиенты';
								|pl = 'Selected customers';
								|tr = 'Seçili müşteriler'");
			
		ElsIf ListFilter = ExceptForSelectedOnes Then
			
			PageHeader = NStr("vi = 'Ngoại trừ khách hàng';
								|ru = 'Кроме клиентов';
								|en = 'Except for customers'; fa = 'Except for customers';
								|it = 'Кроме клиентов';
								|pl = 'Except for customers';
								|tr = 'Müşteriler hariç'");
			
		Else
			
			PageHeader = NStr("vi = 'Khách hàng';
								|ru = 'Клиенты';
								|en = 'Customers'; fa = 'مشتریان';
								|it = 'Клиенты';
								|pl = 'Customers';
								|tr = 'Müşteriler'");
			
		EndIf;
	EndIf;
	#EndRegion
	
	#Region CompositionOfRebateMembersOf_INN
	If ListComposition = PredefinedValue("Enum.RebatesParticipants.TIN") Then
		
		If SupplierBonus Then
			
			If ListFilter = SelectedValues Then
				
				PageHeader = NStr("vi = 'Khách hàng: MST được chọn';
									|ru = 'Клиенты: выбранные ИНН';
									|en = 'Customers: selected TIN'; fa = 'Customers: selected TIN';
									|it = 'Клиенты: выбранные ИНН';
									|pl = 'Customers: selected TIN';
									|tr = 'Müşteriler: Seçili VKN''ler'");
				
			ElsIf ListFilter = ExceptForSelectedOnes Then
				
				PageHeader = NStr("vi = 'Khách hàng: ngoài MST';
									|ru = 'Клиенты: кроме ИНН';
									|en = 'Customers: except TIN'; fa = 'Customers: except TIN';
									|it = 'Клиенты: кроме ИНН';
									|pl = 'Customers: except TIN';
									|tr = 'Müşteriler: VKN''ler hariç'");
				
			Else
				
				PageHeader = NStr("vi = 'Khách hàng';
									|ru = 'Клиенты';
									|en = 'Customers'; fa = 'مشتریان';
									|it = 'Клиенты';
									|pl = 'Customers';
									|tr = 'Müşteriler'");
				
			EndIf;
			
		ElsIf ListFilter = SelectedValues Then
			
			PageHeader = NStr("vi = 'MST được chọn';
								|ru = 'Выбранные ИНН';
								|en = 'Selected TIN'; fa = 'Selected TIN';
								|it = 'Выбранные ИНН';
								|pl = 'Selected TIN';
								|tr = 'Seçili VKN''ler'");
			
		ElsIf ListFilter = ExceptForSelectedOnes Then
			
			PageHeader = NStr("vi = 'Ngoại trừ MST';
								|ru = 'Кроме ИНН';
								|en = 'Except for TIN'; fa = 'Except for TIN';
								|it = 'Кроме ИНН';
								|pl = 'Except for TIN';
								|tr = 'VKN hariç'");
			
		Else
			
			PageHeader = NStr("vi = 'MST';
								|ru = 'ИНН';
								|en = 'TIN'; fa = 'شناسه مالیاتی';
								|it = 'ИНН';
								|pl = 'TIN';
								|tr = 'VKN'");
			
		EndIf;
	EndIf;
	#EndRegion
	
	#Region CompositionOfRebateMembers_PartnerSegments
	If ListComposition = PredefinedValue("Enum.RebatesParticipants.PartnersSegments") Then
		
		If ListFilter = SelectedValues Then
			
			PageHeader = NStr("vi = 'Phân khúc khách hàng được chọn';
								|ru = 'Выбранные сегменты клиентов';
								|en = 'Selected customer segments'; fa = 'Selected customer segments';
								|it = 'Выбранные сегменты клиентов';
								|pl = 'Selected customer segments';
								|tr = 'Seçili müşteri segmentleri'");
			
		ElsIf ListFilter = ExceptForSelectedOnes Then
			
			PageHeader = NStr("vi = 'Ngoại trừ phân khúc khách hàng';
								|ru = 'Кроме сегментов клиентов';
								|en = 'Except for customer segments'; fa = 'Except for customer segments';
								|it = 'Кроме сегментов клиентов';
								|pl = 'Except for customer segments';
								|tr = 'Müşteri segmentleri hariç'");
			
		Else
			
			PageHeader = NStr("vi = 'Phân khúc khách hàng';
								|ru = 'Сегменты клиентов';
								|en = 'Customer segments'; fa = 'بخش‌های مشتری';
								|it = 'Сегменты клиентов';
								|pl = 'Segmenty klientów';
								|tr = 'Müşteri segmentleri'");
			
		EndIf;
	EndIf;
	#EndRegion
	
	Return PageHeader;
	
EndFunction

// Returns the title for the Warehouses page based on the passed list composition setting
// 
// Parameters:
//  SelectionOfWarehouses_ - EnumRef.RebatesLists -
// 
// Returns:
//  String - Page Title By Settings
//
Function PageTitleWarehouses(SelectionOfWarehouses_) Export
	
	SelectedValues = PredefinedValue("Enum.RebatesLists.Selected_");
	ExceptForSelectedOnes = PredefinedValue("Enum.RebatesLists.ExceptForSelectedOnes");
	
	If SelectionOfWarehouses_ = SelectedValues Then
			
		PageHeader = NStr("vi = 'Kho được chọn';
							|ru = 'Выбранные склады';
							|en = 'Selected warehouses'; fa = 'Selected warehouses';
							|it = 'Выбранные склады';
							|pl = 'Selected warehouses';
							|tr = 'Seçili ambarlar'");
		
	ElsIf SelectionOfWarehouses_ = ExceptForSelectedOnes Then
		
		PageHeader = NStr("vi = 'Ngoài kho bãi';
							|ru = 'Кроме складов';
							|en = 'Except warehouses'; fa = 'Except warehouses';
							|it = 'Кроме складов';
							|pl = 'Except warehouses';
							|tr = 'Ambarlar hariç'");
		
	Else
		
		PageHeader = NStr("vi = 'Kho bãi';
							|ru = 'Склады';
							|en = 'Warehouses'; fa = 'انبارها';
							|it = 'Склады';
							|pl = 'Warehouses';
							|tr = 'Ambarlar'");
		
	EndIf;
	
	Return PageHeader;
	
EndFunction

#EndRegion

#Region Internal

// Parameters:
//  GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods
// 
// Returns:
//  Boolean
//
Function PeriodOfGoodsConditionsIsUsed(GoodsIndicator) Export
	
	Result = True;
	
	If GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.QuantityTotal")
	 Or GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.BatchOffer") Then
		
		Result = False;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  Parameters - Structure:
// * Currency - CatalogRef.Currencies - 
// * CourseNumerator - Number - 
// * CourseDenominator - Number - 
// * ARAPCurrency - CatalogRef.Currencies -
//  Sum - Number -
// 	CurrencyOfComplianceAccounting - CatalogRef.Currencies -  
// 
// Returns:
//  Number
//
Function RecalculateAmountOfSettlementsInLine(Parameters, Val Sum, CurrencyOfComplianceAccounting) Export
	
	AmountARAP = 0;
	
	If Parameters.Currency = CurrencyOfComplianceAccounting
	   And Parameters.ARAPCurrency <> CurrencyOfComplianceAccounting Then
		
		NumeratorOfSettlementCurrency = Parameters.CourseNumerator;
		DenominatorOfSettlementCurrency = Parameters.CourseDenominator;
		NumeratorOfDocumentCurrency = 1;
		DenominatorOfDocumentCurrency = 1;
		
	Else
		
		NumeratorOfDocumentCurrency = Parameters.CourseNumerator;
		DenominatorOfDocumentCurrency = Parameters.CourseDenominator;
		NumeratorOfSettlementCurrency = 1;
		DenominatorOfSettlementCurrency = 1;
		
	EndIf;
	
	If Parameters.Currency = Parameters.ARAPCurrency Then
		
		AmountARAP = Sum;
		
	ElsIf Parameters.ARAPCurrency = CurrencyOfComplianceAccounting
		  Or Parameters.Currency = CurrencyOfComplianceAccounting Then
		
		CurrencySettingsDoc = New Structure("Currency, CourseNumerator, CourseDenominator",
			Parameters.Currency, NumeratorOfDocumentCurrency, DenominatorOfDocumentCurrency);
		TDCurrencySettings  = New Structure("Currency, CourseNumerator, CourseDenominator",
			Parameters.ARAPCurrency, NumeratorOfSettlementCurrency, DenominatorOfSettlementCurrency);
		
		AmountARAP = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
			Sum, CurrencySettingsDoc, TDCurrencySettings);
		
	Else
		
		If NumeratorOfDocumentCurrency = 0
		 Or DenominatorOfDocumentCurrency = 0 Then
			
			AmountARAP = 0;
			
		Else
			
			AmountARAP = Sum * NumeratorOfDocumentCurrency / DenominatorOfDocumentCurrency;
			
		EndIf;
		
	EndIf;
	
	Return AmountARAP;
	
EndFunction

// Parameters:
//  AllocationProcedure - EnumRef.RebatesAllocationProcedures -
//  WithoutCalculation - Boolean -
//  BonusType - EnumRef.VendorRebateTypes -
//  GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods -
//  BaseOfCalculation - EnumRef.RebateCalculationBases -
// 
// Returns:
//  EnumRef.RebatesAllocationProcedures
//
Function CheckResetAllocationOrder(AllocationProcedure, WithoutCalculation, BonusType, GoodsIndicator, BaseOfCalculation) Export
	
	NewValue = AllocationProcedure;
	
	If WithoutCalculation Then
		
		NewValue = PredefinedValue("Enum.RebatesAllocationProcedures.EmptyRef");
		
	Else
		
		AllocationIsAvailable =
			(BonusType = PredefinedValue("Enum.VendorRebateTypes.Purchases")
			 And BaseOfCalculation <> PredefinedValue("Enum.RebateCalculationBases.PurchaseAmountBasePrices")
			 And (GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.Count")
				Or GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.BatchOffer")));
		
		If Not AllocationIsAvailable Then
			
			NewValue = PredefinedValue("Enum.RebatesAllocationProcedures.EmptyRef");
			
		EndIf;
		
	EndIf;
	
	Return NewValue;
	
EndFunction

// Returns:
//  Structure - End Parameters For Specifying The Exchange Rate Currency:
// * ARAPCurrency - CatalogRef.Currencies - 
// * CourseNumerator - Number - 
// * CourseDenominator - Number -
// 
Function EndParametersForSpecifyingExchangeRateCurrency() Export
	
	Result = New Structure;
	Result.Insert("ARAPCurrency", PredefinedValue("Catalog.Currencies.EmptyRef"));
	
	Result.Insert("CourseNumerator", 0);
	Result.Insert("CourseDenominator", 0);
	
	Return Result;
	
EndFunction

// Returns:
//  Array of EnumRef.ContractTypes- Types of procurement Contract
//
Function TypesOfProcurementContracts() Export
	
	ContractTypes = New Array; // Array of EnumRef.ContractTypes
	ContractTypes.Add(PredefinedValue("Enum.ContractTypes.WithVendor"));
	ContractTypes.Add(PredefinedValue("Enum.ContractTypes.Import"));
	ContractTypes.Add(PredefinedValue("Enum.ContractTypes.PurchaseEAEU"));
	ContractTypes.Add(PredefinedValue("Enum.ContractTypes.ReceivingForCustody"));
	
	Return ContractTypes;
	
EndFunction

// Returns:
//  Array of EnumRef.BusinessTransactions
//
Function BusinessProcurementOperations() Export
	
	ArrayOfBusinessTransactions = New Array; // Array of EnumRef.BusinessTransactions
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier"));
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseByImport"));
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEU"));
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale"));
	
	Return ArrayOfBusinessTransactions;
	
EndFunction

// Set the title of the calculation scale group.
// 
// Parameters:
//  Form - See Document.ConditionsOfCustomerRebates.Form.DocumentForm
//        - See Document.ConditionsOfVendorRebates.Form.DocumentForm
//
Procedure SetTitleOfCalculationScaleGroup(Form) Export
	
	Result = NStr("vi = 'Chưa áp dụng tùy chỉnh';
					|ru = 'Настройка не применяется';
					|en = 'Setting is not used'; fa = 'Setting is not used';
					|it = 'Setting is not used';
					|pl = 'Setting is not used';
					|tr = 'Ayarlar uygulanmıyor'");
	LimitOfOutputToHeader = 2;
	Object = Form.Object;
	GoodsIndicator = Form.GoodsIndicator;
	
	If GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.Sum") Then
		
		If Object.CalculationScaleType = 1 Then // Progressive Scale
			
			If Object.CalculationScales.Count() = 0 Then
				
				Result = NStr("vi = 'Tùy chỉnh thang';
								|ru = 'Настроить шкалу';
								|en = 'Adjust the scale'; fa = 'Adjust the scale';
								|it = 'Adjust the scale';
								|pl = 'Adjust the scale';
								|tr = 'Ölçeği ayarla'");
				
			Else
				
				ValueTemplate = NStr("vi = '%1 (%2%)';
									|ru = '%1 (%2%)';
									|en = '%1 (%2%)'; fa = '%1 (%2%)';
									|it = '%1 (%2%)';
									|pl = '%1 (%2%)';
									|tr = '%1 (%2%)'");
				ScaleValues = New Array; // Array of String
				
				For Each ScaleLine In Object.CalculationScales Do
					
					If ScaleLine.LineNumber > LimitOfOutputToHeader Then
						Break;
					EndIf;
					
					ValuePresentation = StringFunctionsClientServer.SubstituteParametersToString(
						ValueTemplate,
						Format(ScaleLine.RangeFrom, "NFD=2;"),
						Format(ScaleLine.BonusPercent, "NFD=2; NZ=0;"));
					
					ScaleValues.Add(ValuePresentation);
					
				EndDo;
				
				ScalesUsed = StrConcat(ScaleValues, "; ");
				NumberOfScales = Object.CalculationScales.Count(); 
				
				If NumberOfScales <= LimitOfOutputToHeader Then
					
					TitleTemplate1 = NStr("vi = 'Thang: %1';
											|ru = 'Шкалы: %1';
											|en = 'Scales: %1'; fa = 'Scales: %1';
											|it = 'Scales: %1';
											|pl = 'Scales: %1';
											|tr = 'Ölçekler: %1'");
					Result = StringFunctionsClientServer.SubstituteParametersToString(
						TitleTemplate1,
						ScalesUsed);
					
				Else
					
					TitleTemplate1 = NStr("vi = 'Thang: %1 và hơn nữa %2';
											|ru = 'Шкалы: %1 и еще %2';
											|en = 'Scales: %1 and %2 more'; fa = 'Scales: %1 and %2 more';
											|it = 'Scales: %1 and %2 more';
											|pl = 'Scales: %1 and %2 more';
											|tr = 'Ölçekler: %1/%2'");
					Result = StringFunctionsClientServer.SubstituteParametersToString(
						TitleTemplate1,
						ScalesUsed,
						Format(NumberOfScales - LimitOfOutputToHeader, "NG=;"));
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If Object.CalculationScaleType = 2 Then // By Ranges
			
			If Object.CalculationScales.Count() = 0 Then
				
				Result = NStr("vi = 'Tùy chỉnh khoảng';
								|ru = 'Настроить диапазоны';
								|en = 'Configure ranges'; fa = 'Configure ranges';
								|it = 'Configure ranges';
								|pl = 'Configure ranges';
								|tr = 'Aralıkları ayarla'");
				
			Else
				
				RangeTemplate = NStr("vi = '%1 (%2%)';
									|ru = '%1 (%2%)';
									|en = '%1 (%2%)'; fa = '%1 (%2%)';
									|it = '%1 (%2%)';
									|pl = '%1 (%2%)';
									|tr = '%1 (%2%)'");
				RangeValues = New Array; // Array of String
				
				For Each ScaleLine In Object.CalculationScales Do
					
					If ScaleLine.LineNumber > LimitOfOutputToHeader Then
						Break;
					EndIf;
					
					ValuePresentation = StringFunctionsClientServer.SubstituteParametersToString(
						RangeTemplate,
						ScaleLine.RangeDesignation,
						Format(ScaleLine.BonusPercent, "NFD=2; NZ=0;"));
					
					RangeValues.Add(ValuePresentation);
					
				EndDo;
				
				RangesUsed = StrConcat(RangeValues, "; ");
				NumberOfRanges = Object.CalculationScales.Count(); 
				
				If NumberOfRanges <= LimitOfOutputToHeader Then
					
					TitleTemplate1 = NStr("vi = 'Khoảng thời gian: %1';
											|ru = 'Диапазоны: %1';
											|en = 'Ranges: %1'; fa = 'Ranges: %1';
											|it = 'Ranges: %1';
											|pl = 'Ranges: %1';
											|tr = 'Aralıklar: %1'");
					Result = StringFunctionsClientServer.SubstituteParametersToString(
						TitleTemplate1,
						RangesUsed);
					
				Else
					
					TitleTemplate1 = NStr("vi = 'Khoảng: %1 và hơn nữa %2';
											|ru = 'Диапазоны: %1 и еще %2';
											|en = 'Ranges: %1 and %2 more'; fa = 'Ranges: %1 and %2 more';
											|it = 'Ranges: %1 and %2 more';
											|pl = 'Ranges: %1 and %2 more';
											|tr = 'Aralıklar: %1/%2'");
					Result = StringFunctionsClientServer.SubstituteParametersToString(
						TitleTemplate1,
						RangesUsed,
						Format(NumberOfRanges - LimitOfOutputToHeader, "NG=;"));
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Form.TitleOfCalculationScaleSettingsGroup = Result;
	
EndProcedure

// Parameters:
//  Form - See Document.ConditionsOfCustomerRebates.Form.DocumentForm
//
Procedure GenerateNamesOfRangesOfCalculationScales(Form) Export
	
	Currency = Form.Object.Currency;
	If Currency.IsEmpty() Then
		CurrencyPresentation = NStr("vi = '<tiền tệ?>';
									|ru = '<валюта?>';
									|en = '<currency?>'; fa = '<currency?>';
									|it = '<currency?>';
									|pl = '<currency?>';
									|tr = '<para birimi?>'");
	Else
		CurrencyPresentation = String(Currency);
	EndIf;
	
	CalculationScales = Form.Object.CalculationScales;
	NumberOfIntervals_ = CalculationScales.Count();
	
	DesignationOfIntervalUpTo = NStr("vi = '≤ %1';
									|ru = '≤ %1';
									|en = '≤ %1'; fa = '≤ %1';
									|it = '≤ %1';
									|pl = '≤ %1';
									|tr = '≤ %1'");
	DesignationOfIntervalFromTo = NStr("vi = '> %1 và ≤ %2';
										|ru = '> %1 и ≤ %2';
										|en = '> %1 and ≤ %2'; fa = '> %1 and ≤ %2';
										|it = '> %1 and ≤ %2';
										|pl = '> %1 and ≤ %2';
										|tr = '> %1 ve ≤ %2'");
	DesignationOfIntervalOver = NStr("vi = '> %1';
									|ru = '> %1';
									|en = '> %1'; fa = '> %1';
									|it = '> %1';
									|pl = '> %1';
									|tr = '> %1'");
	
	NumberOfIntervals_ = CalculationScales.Count();
	
	// align the boundaries of the intervals, form the names
	If NumberOfIntervals_ = 1 Then
		
		FirstInterval = CalculationScales[0];
		
		FirstInterval.NameOfRange = NStr("vi = '<Cần giới hạn thứ hai>';
										|ru = '<Требуется вторая граница>';
										|en = '<Second border is required>'; fa = '<Second border is required>';
										|it = '<Second border is required>';
										|pl = '<Second border is required>';
										|tr = '<İkinci bir sınır gerekli>'"); 
		
		FirstInterval.RangeDesignation = StringFunctionsClientServer.SubstituteParametersToString(
			DesignationOfIntervalOver,
			FormatOfIntervalBoundary(FirstInterval.RangeFrom));
		
	ElsIf NumberOfIntervals_ > 1 Then
		
		FirstInterval = CalculationScales[0];
		SecondInterval = CalculationScales[1];
		
		FirstInterval.RangeBy = SecondInterval.RangeFrom;
		
		FirstInterval.NameOfRange = NameOfScaleRange(
			FirstInterval.RangeFrom, FirstInterval.RangeBy, CurrencyPresentation);
		
		FirstInterval.RangeDesignation = StringFunctionsClientServer.SubstituteParametersToString(
			DesignationOfIntervalUpTo,
			FormatOfIntervalBoundary(FirstInterval.RangeBy));
		
		For CurIndex__ = 1 To NumberOfIntervals_ - 2 Do
			
			ThisInterval = CalculationScales[CurIndex__];
			NextInterval_ = CalculationScales[CurIndex__ + 1];
			
			ThisInterval.RangeBy = NextInterval_.RangeFrom;
			
			ThisInterval.NameOfRange = NameOfScaleRange(
				ThisInterval.RangeFrom, ThisInterval.RangeBy, CurrencyPresentation);
			
			ThisInterval.RangeDesignation = StringFunctionsClientServer.SubstituteParametersToString(
				DesignationOfIntervalFromTo,
				FormatOfIntervalBoundary(ThisInterval.RangeFrom),
				FormatOfIntervalBoundary(ThisInterval.RangeBy));
			
		EndDo;
		
		LastInterval = CalculationScales[NumberOfIntervals_ - 1];
		
		LastInterval.RangeBy = 0;
		
		LastInterval.NameOfRange = NameOfScaleRange(
				LastInterval.RangeFrom, LastInterval.RangeBy, CurrencyPresentation);
		
		LastInterval.RangeDesignation = StringFunctionsClientServer.SubstituteParametersToString(
			DesignationOfIntervalOver,
			FormatOfIntervalBoundary(LastInterval.RangeFrom));
		
	EndIf;
	
EndProcedure

// Parameters:
//  RangeFrom - Number
//  RangeBy - Number
//  PresentationOfRangeUnit - String
// 
// Returns:
//  String - String name of the scale range
//
Function NameOfScaleRange(RangeFrom, RangeBy, PresentationOfRangeUnit) Export
	
	If RangeFrom = 0 Then
		
		If ValueIsFilled(PresentationOfRangeUnit) Then
			DescriptionTemplate = NStr("vi = 'trước %1%2 bao gồm';
										|ru = 'до %1 %2 включительно';
										|en = 'to %1 %2 inclusive'; fa = 'to %1 %2 inclusive';
										|it = 'to %1 %2 inclusive';
										|pl = 'to %1 %2 inclusive';
										|tr = '%1 %2 kadar dahil'");
		Else
			DescriptionTemplate = NStr("vi = 'trước %1 bao gồm';
										|ru = 'до %1 включительно';
										|en = 'to %1 inclusive'; fa = 'to %1 inclusive';
										|it = 'to %1 inclusive';
										|pl = 'to %1 inclusive';
										|tr = '%1 kadar dahil'");
		EndIf;
		
		NameOfRange = StringFunctionsClientServer.SubstituteParametersToString(
			DescriptionTemplate,
			FormatOfIntervalBoundary(RangeBy),
			PresentationOfRangeUnit);
		
	ElsIf RangeBy = 0 Then
		
		If ValueIsFilled(PresentationOfRangeUnit) Then
			DescriptionTemplate = NStr("vi = 'Cao hơn %1 %2';
										|ru = 'свыше %1 %2';
										|en = 'more than %1 %2'; fa = 'more than %1 %2';
										|it = 'more than %1 %2';
										|pl = 'more than %1 %2';
										|tr = '%1 %2 üstü'");
		Else
			DescriptionTemplate = NStr("vi = 'Cao hơn %1';
										|ru = 'свыше %1';
										|en = 'more than %1'; fa = 'more than %1';
										|it = 'more than %1';
										|pl = 'more than %1';
										|tr = '%1 üstü'");
		EndIf;
		
		NameOfRange = StringFunctionsClientServer.SubstituteParametersToString(
			DescriptionTemplate,
			FormatOfIntervalBoundary(RangeFrom),
			PresentationOfRangeUnit);
		
	Else
		
		If ValueIsFilled(PresentationOfRangeUnit) Then
			DescriptionTemplate = NStr("vi = 'cao hơn %1 %2 trước %3 bao gồm';
										|ru = 'свыше %1 %2 до %3 включительно';
										|en = 'more than %1 %2 to %3 inclusive'; fa = 'more than %1 %2 to %3 inclusive';
										|it = 'more than %1 %2 to %3 inclusive';
										|pl = 'more than %1 %2 to %3 inclusive';
										|tr = '%3 kadar dahil %1 %2 üzeri'");
		Else
			DescriptionTemplate = NStr("vi = 'cao hơn %1 trước %3 bao gồm';
										|ru = 'свыше %1 до %3 включительно';
										|en = 'more than %1 to %3 inclusive'; fa = 'more than %1 to %3 inclusive';
										|it = 'more than %1 to %3 inclusive';
										|pl = 'more than %1 to %3 inclusive';
										|tr = '%3 kadar dahil %1 üzeri'");
		EndIf;
		
		NameOfRange = StringFunctionsClientServer.SubstituteParametersToString(
			DescriptionTemplate,
			FormatOfIntervalBoundary(RangeFrom),
			PresentationOfRangeUnit,
			FormatOfIntervalBoundary(RangeBy));
		
	EndIf;
	
	Return NameOfRange;
	
EndFunction

// Parameters:
// ElementViewOfCalculationScale - FormField, FormFieldExtensionForATextBox -
// GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods
//
Procedure FillInValidOptionsForCalculationScales(ElementViewOfCalculationScale, GoodsIndicator) Export
	
	ScaleSelectionList = ElementViewOfCalculationScale.ChoiceList; // ValueList of Number
	ScaleSelectionList.Clear();
	If GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.Count") Then
		
		TextProgressiveScale = NStr("vi = 'Thang lũy tiến';
									|ru = 'Прогрессивная шкала';
									|en = 'Progressive scale'; fa = 'Progressive scale';
									|it = 'Progressive scale';
									|pl = 'Progressive scale';
									|tr = 'Aşamalı ölçek'");
		ScaleSelectionList.Add(0, TextProgressiveScale);
		
		TextByRanges = NStr("vi = 'Theo khoảng';
							|ru = 'По диапазонам';
							|en = 'By ranges'; fa = 'By ranges';
							|it = 'By ranges';
							|pl = 'By ranges';
							|tr = 'Aralıklara göre'");
		ScaleSelectionList.Add(1, TextByRanges);
		
	ElsIf GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.Sum") Then
		
		TextOneValue = NStr("vi = 'Một giá trị';
							|ru = 'Одно значение';
							|en = 'One value'; fa = 'One value';
							|it = 'One value';
							|pl = 'One value';
							|tr = 'Tekli değer'");
		ScaleSelectionList.Add(0, TextOneValue);
		
		TextProgressiveScale = NStr("vi = 'Thang lũy tiến';
									|ru = 'Прогрессивная шкала';
									|en = 'Progressive scale'; fa = 'Progressive scale';
									|it = 'Progressive scale';
									|pl = 'Progressive scale';
									|tr = 'Aşamalı ölçek'");
		ScaleSelectionList.Add(1, TextProgressiveScale);
		
		TextByRanges = NStr("vi = 'Theo khoảng';
							|ru = 'По диапазонам';
							|en = 'By ranges'; fa = 'By ranges';
							|it = 'By ranges';
							|pl = 'By ranges';
							|tr = 'Aralıklara göre'");
		ScaleSelectionList.Add(2, TextByRanges);
		
	EndIf;
	
EndProcedure

// Parameters:
//  IntervalEndpoint - Number
// 
// Returns:
//   String
//
Function FormatOfIntervalBoundary(IntervalEndpoint) Export 
	
	If Round(IntervalEndpoint) = IntervalEndpoint Then
		Return Format(IntervalEndpoint, "NFD=0; NZ=0;");
	Else
		Return Format(IntervalEndpoint, "NFD=2");
	EndIf;
	
EndFunction

// Returns:
//  Structure - Structure of the product line being deleted:
// * Products - CatalogRef.Products - 
// * Characteristic - CatalogRef.ItemsCharacteristics - 
// * ItemVariantsAreUsed - Boolean -
// 
Function StructureOfSavedProductLine() Export
	
	Result = New Structure;
	Result.Insert("Products", PredefinedValue("Catalog.Products.EmptyRef"));
	Result.Insert("Characteristic", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	Result.Insert("ItemVariantsAreUsed", False);
	
	Return Result;
	
EndFunction

// Parameters:
//  TypeOfScale - Number
//  GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods
// 
// Returns:
//  Boolean
Function ThisIsNumberByRanges(TypeOfScale, GoodsIndicator) Export
	
	Result = (TypeOfScale = 1 // For quantity, this is by ranges
	             And GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.Count"));
	
	Return Result;
	
EndFunction

// Returns:
//  Structure - Analytics parameters for filling in the line being changed:
// * CalculationScaleType - Number - 
// * GoodsIndicator - EnumRef.TargetSalesIndicatorsOfRebatesByGoods - 
// * Products - CatalogRef.Products - 
// * Characteristic - CatalogRef.ItemsCharacteristics - 
// * ItemVariantsAreUsed - Boolean -
// 
Function ParametersForFillingInAnalyticsOfRowBeingModified() Export
	
	Parameters = New Structure;
	
	Parameters.Insert("CalculationScaleType", 0);
	Parameters.Insert("GoodsIndicator", PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.EmptyRef"));
	Parameters.Insert("Products", PredefinedValue("Catalog.Products.EmptyRef"));
	Parameters.Insert("Characteristic", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	Parameters.Insert("ItemVariantsAreUsed", False);
	
	Return Parameters;
	
EndFunction

// Parameters:
//  Dimension - See RebatesClientServer.StructureOfSavedProductLine
//  FillParameters - See RebatesClientServer.ParametersForFillingInAnalyticsOfRowBeingModified
//
Procedure SaveAnalyticsOfProductLine(Dimension, Val FillParameters) Export
	
	TheseAreGoodsByRanges = ThisIsNumberByRanges(
		FillParameters.CalculationScaleType, FillParameters.GoodsIndicator);
	
	Dimension = StructureOfSavedProductLine();
	If TheseAreGoodsByRanges Then
		
		DataFilledIn = Not FillParameters.Products.IsEmpty();
		
		If DataFilledIn Then
			
			Dimension.Products = FillParameters.Products;
			Dimension.Characteristic = FillParameters.Characteristic;
			Dimension.ItemVariantsAreUsed = FillParameters.ItemVariantsAreUsed;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Item - FormField - for which settings are being made
//  AcceptablePropertyTypes - TypeDescription
//
Procedure SetDefaultPropertyValueFormat(Item, AcceptablePropertyTypes) Export
	
	TypesArray = AcceptablePropertyTypes.Types();
	If TypesArray.Count() = 1 Then
		
		If TypesArray[0] = Type("Date") Then
			
			SetDateFormatProperties(Item, AcceptablePropertyTypes);
			
		ElsIf TypesArray[0] = Type("Number") Then
			
			SetNumberFormatProperties(Item, AcceptablePropertyTypes, False)
			
		EndIf;
		
	Else
		
		SetDateFormatProperties(Item, AcceptablePropertyTypes);
		
	EndIf;
	
EndProcedure

// Parameters:
//  Item - FormField - for which settings are being made
//  AcceptablePropertyTypes - TypeDescription
//
Procedure SetDateFormatProperties(Item, AcceptablePropertyTypes) Export
	
	QualifierDate = New DateQualifiers(DateFractions.Date);
	QualifierTime = New DateQualifiers(DateFractions.Time);
	
	If AcceptablePropertyTypes.DateQualifiers = QualifierDate Then
		
		Format = "DLF=D;";
		
	ElsIf AcceptablePropertyTypes.DateQualifiers = QualifierTime Then
		
		Format = "DLF=T;";
		
	Else
		
		Format = "DLF=DT;";
		
	EndIf;
	
	Item.Format = Format;
	Item.EditFormat = Format;
	
EndProcedure

// Parameters:
//  Item - FormField - for which settings are being made
//  AcceptablePropertyTypes - TypeDescription
//  EditingFormatOnly - Boolean
//
Procedure SetNumberFormatProperties(Item, AcceptablePropertyTypes, EditingFormatOnly = True) Export
	
	NumberQualifiers = AcceptablePropertyTypes.NumberQualifiers;
	Digits = NumberQualifiers.Digits;
	FractionDigits = NumberQualifiers.FractionDigits;
	NumTemplate = "ND=%1; NFD=%2;";
	Format = StrTemplate(NumTemplate, Digits, FractionDigits);
	Item.EditFormat = Format;
	
	If Not EditingFormatOnly Then
		Item.Format = Format;
	EndIf;
	
EndProcedure

#Region BatchProcessingOfStrings

// Parameters:
//  CurrentRow - FormDataCollectionItem, ValueTableRow -
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  AdditionalFillingParameters - Structure, Undefined - Additional Filling Parameters
//
Procedure FieldsOfActionLine(CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters) Export
	
	Var ActionParameters; // Structure
	
	NameOfAgreementField = "";
	If StructureOfActions.Property("FillInAgreementAttributeInTSLine", NameOfAgreementField) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert(NameOfAgreementField);
		
		EditableFields = New Structure();
		EditableFields.Insert("ThisIsModelAgreement");
		
		BatchProcessingOfTablePartClientServer.AddFieldDescriptions(
			"FillInAgreementAttributeInTSLine",
			ReadableFields,
			EditableFields,
			CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInCurrencyIndicationForRebatesOfSuppliers", ActionParameters) Then
		
		ReadableFields = New Structure();
		EditableFields = New Structure();
		For Each Field In ActionParameters Do // KeyAndValue
			
			ReadableFields.Insert(String(Field.Key));
			EditableFields.Insert(String(Field.Value));
			
		EndDo;
		
		BatchProcessingOfTablePartClientServer.AddFieldDescriptions(
			"FillInCurrencyIndicationForRebatesOfSuppliers",
			ReadableFields,
			EditableFields,
			CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInCurrencyOfVendorSRebates", ActionParameters) Then
		
		ReadableFields = New Structure();
		EditableFields = New Structure();
		For Each Field In ActionParameters Do // KeyAndValue
			
			ReadableFields.Insert(String(Field.Key));
			EditableFields.Insert(String(Field.Value));
			
		EndDo;
		
		BatchProcessingOfTablePartClientServer.AddFieldDescriptions(
			"FillInCurrencyOfVendorSRebates",
			ReadableFields,
			EditableFields,
			CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInRebateTypeOfSuppliers", ActionParameters) Then
		
		ReadableFields = New Structure();
		EditableFields = New Structure();
		For Each Field In ActionParameters Do // KeyAndValue
			
			ReadableFields.Insert(String(Field.Key));
			EditableFields.Insert(String(Field.Value));
			
		EndDo;
		
		BatchProcessingOfTablePartClientServer.AddFieldDescriptions(
			"FillInRebateTypeOfSuppliers",
			ReadableFields,
			EditableFields,
			CachedValues);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion