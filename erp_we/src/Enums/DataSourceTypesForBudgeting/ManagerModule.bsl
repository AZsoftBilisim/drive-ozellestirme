#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns an indication that only quantitative accounting is performed by source type.
//
// Parameters:
//  SourceType - EnumRef.DataSourceTypesForBudgeting
//
// Returns:
//	Boolean - True if only quantitative accounting is conducted by source type
//
Function OnlyQuantitativeAccountingBySourceType(SourceType) Export
	
	QuantitativeAccountingOnly = False;
	
	If SourceType = InventoryConsumptionPlans
		Or SourceType = PlansOfGoodsStock
		Or SourceType = SalesPlansByCategories
		Or SourceType = ProductionPlans
		Or SourceType = AssemblyDisassemblyPlans Then
		QuantitativeAccountingOnly = True;
	EndIf;
	
	Return QuantitativeAccountingOnly;
	
EndFunction

// Returns an indication that the organization is being accounted for by source type.
//
// Parameters:
//  SourceType - EnumRef.DataSourceTypesForBudgeting
//
// Returns:
//	Boolean - True if the type of source is recorded by organization
//
Function BySourceTypeRecordsAreKeptForCompany(SourceType) Export
	
	RecordsAreKeptForCompany = True;
	
	If SourceType = InventoryConsumptionPlans
		Or SourceType = PlansOfGoodsStock
		Or SourceType = SalesPlansByCategories
		Or SourceType = ProductionPlans
		Or SourceType = AssemblyDisassemblyPlans Then
		RecordsAreKeptForCompany = False;
	EndIf;
	
	Return RecordsAreKeptForCompany;
	
EndFunction

#EndRegion

#EndIf