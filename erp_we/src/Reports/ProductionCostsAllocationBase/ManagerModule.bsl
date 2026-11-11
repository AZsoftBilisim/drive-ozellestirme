#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//	ValueTableRow - description of the report command.
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ProductionCostsAllocationBase) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Id               = Metadata.Reports.ProductionCostsAllocationBase.FullName();
		ReportCommand.Manager                    = "Report.ProductionCostsAllocationBase";
		ReportCommand.Presentation               = NStr("vi = 'Phân bổ chi phí';
														|ru = 'Распределение расходов';
														|en = 'Line of business — allocation base'; fa = 'خط کسب‌وکار — مبنای تسهیم';
														|it = 'Ripartizione delle spese';
														|pl = 'Podział kosztów';
														|tr = 'Giderlerin dağıtımı'");
		
		ReportCommand.MultipleChoice          = False;
		ReportCommand.Importance                    = "Ordinary";
		ReportCommand.WriteMode                 = "Post";
		ReportCommand.VariantKey                = "FlowDistribution";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductionCostsAllocationBase);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Returns an array of document assignments for the allocation of other costs that the report supports
//
// Returns:
//   Array of EnumRef.AssignmentOfCostAllocationRules
//
Function SupportedTypesOfAllocationAssignments() Export 

	Result = New Array;
	
	Result.Add(Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost);
	Result.Add(Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots);
	Result.Add(Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult);
	Result.Add(Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter);
	Result.Add(Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnInventoryCosts);
	
	Return Result;

EndFunction

#EndRegion
		
#EndIf