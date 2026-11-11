
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns an indication that a scenario selection is required to build a report based on the budget type.
//
// Parameters:
// 	BudgetProfile - CatalogRef.BudgetProfiles - Type of budget to analyze.
// 
// Returns:
// 	Boolean - Truth is Required, Falsehood is Not required.
//
Function SelectionAvailabilityParameters(BudgetProfile) Export
	
	// At the level of the budget type, the scenario of the items can be defined:
	// - in the selections of the articles themselves
	// - in table row/column groupings
	// - in top-level groupings.
	
	ColumnStructureOfDataTable = BudgetReportingCacheCalculationServer.ColumnsOfDataTable_(BudgetProfile);
	StructureOfBudgetProfileDescription = BudgetReportingCacheCalculationServer.DescriptionOfReport(
		BudgetProfile,
		ColumnStructureOfDataTable,
		Enums.ModesOfBudgetReportGeneration.Report);
	
	Result = New Structure;
	Result.Insert("YouCanSelectScenario", False);
	Result.Insert("YouCanSelectCompany", False);
	Result.Insert("YouCanSelectADepartment", False);
	
	For Each DataSource In StructureOfBudgetProfileDescription.DataSources Do
		
		FilterSource1 = DataSource.AdditionalSelection;
		If FilterSource1 = Undefined Then
			Continue;
		EndIf;
		
		FoundItems1 = New Array;
		If Not Result.YouCanSelectScenario
			And Not DataSource.Property("Scenario")
			And BudgetReportingCacheCalculationServer.FindSelectionByName(FilterSource1, "Scenario", FoundItems1) Then
			For Each Item In FoundItems1 Do
				If Item.RightValue = "<FillIn_scene>" Then
					Result.Insert("YouCanSelectScenario", True);
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		FoundItems1 = New Array;
		If Not Result.YouCanSelectCompany
			And Not DataSource.Property("Organization")
			And BudgetReportingCacheCalculationServer.FindSelectionByName(FilterSource1, "Organization", FoundItems1) Then
			For Each Item In FoundItems1 Do
				If Item.RightValue = "<FillIn_organization>" Then
					Result.Insert("YouCanSelectCompany", True);
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		FoundItems1 = New Array;
		If Not Result.YouCanSelectADepartment
			And Not DataSource.Property("Department")
			And BudgetReportingCacheCalculationServer.FindSelectionByName(FilterSource1, "Department", FoundItems1) Then
			For Each Item In FoundItems1 Do
				If Item.RightValue = "<FillIn_district>" Then
					Result.Insert("YouCanSelectADepartment", True);
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If Result.YouCanSelectScenario
			And Result.YouCanSelectCompany
			And Result.YouCanSelectADepartment Then
			
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// StandardSubsystems.ReportsOptions

// The configuration options for that report.
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings
//   DescriptionOfReport - See ReportsOptions.DescriptionOfReport
//
Procedure CustomizeReportOptions(Settings, DescriptionOfReport) Export
	
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndIf