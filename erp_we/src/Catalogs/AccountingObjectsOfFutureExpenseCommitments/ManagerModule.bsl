#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region StandardSubsystems

// Enables / disables the use of directory properties.
//
Procedure SetUseOfProperties() Export
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.GenerateFutureExpenseCommitments.Get();
	
	PropertyManager.SetPropertySetParameters(
		"Catalog_AccountingObjectsOfFutureExpenseCommitments", SetParameters);
	
EndProcedure

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("ReserveKind");
	Result.Add("LineOfBusiness");
	Result.Add("Organization");
	Result.Add("UseReserve");
	
	Return Result;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsFolder OR
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// Returns parameters for selecting articles in the document.
//
// Parameters:
//  TypeOfReserve - CatalogRef.Reserves - type of document reserve.
// 
// Returns:
//  Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(TypeOfReserve = Undefined) Export
	
	ChoiceParametersArray = New Array;
	
	ReserveType = Undefined;
	If TypeOfReserve <> Undefined Then
		ReserveType = Common.ObjectAttributeValue(TypeOfReserve, "ReserveType");
	EndIf;
	
	#Region ExpenseItemAccruals
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "ExpenseItemAccruals";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionAccruals";
	
	OptionsArray = New Array;
	If ReserveType = PredefinedValue("Enum.TypesOfProvisionsAndContingentLiabilities.ResidualLiabilities") Then
		OptionsArray.Add(Enums.CostAllocationOptions.ToNonCurrentAssetCost);
		ChoiceParameters.SelectionOfExpenditureItems.Insert("ExpensesOnAssets", True)
	Else
		OptionsArray.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
		OptionsArray.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
		OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
		OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCosts);
		OptionsArray.Add(Enums.CostAllocationOptions.ToInventoryCost);
		OptionsArray.Add(Enums.CostAllocationOptions.ToCostCenters);
		OptionsArray.Add(Enums.CostAllocationOptions.ToCostOfGoodsSold);
		OptionsArray.Add(Enums.CostAllocationOptions.DoNotAllocate);
		OptionsArray.Add(Enums.CostAllocationOptions.ToNonCurrentAssetCost);
	EndIf;
	ChoiceParameters.SelectionOfExpenditureItems.CostAllocationOption = OptionsArray;
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemAccruals");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionAccruals");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region IncomeItemOfWriteOff
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "IncomeItemOfWriteOff";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "IncomeDimensionOfWriteOff";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItemOfWriteOff");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("IncomeDimensionOfWriteOff");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region UseReserveExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.UseReserve";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	OptionsArray = New Array;
	OptionsArray.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCosts);
	ChoiceParameters.SelectionOfExpenditureItems.CostAllocationOption = OptionsArray;
	
	ChoiceParameters.FormItems.AssetRef.Add("UseReserveExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("UseReserveDimensionOfExpenses");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	Return ChoiceParametersArray;
	
EndFunction

#EndRegion

#EndIf