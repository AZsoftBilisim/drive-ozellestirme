#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.FixedAssetsInitialRecognition2_4.AddGenerateCommand(GenerationCommands, 1);
	Documents.FixedAssetsCostAdditions2_4.AddGenerateCommand(GenerationCommands);
	Documents.AllocateVariancesToFixedAssetCost.AddGenerateCommand(GenerationCommands);
	
	ConstructionObjectsLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export

	Command = Reports.CapitalizationExpenseStructure.AddReportCommand(ReportsCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm, ListForm";
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf