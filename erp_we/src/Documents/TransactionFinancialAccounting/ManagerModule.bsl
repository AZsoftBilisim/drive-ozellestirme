#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = Documents.TransactionFinancialAccounting.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.Presentation = NStr("vi = 'Đảo ngược: Giao dịch (kế toán quốc tế)';
									|ru = 'Сторно: Операция (международный учет):';
									|en = 'Storno: Transaction (financial accounting):'; fa = 'Storno: Transaction (financial accounting):';
									|it = 'Storno: Operazione (contabilità internazionale):';
									|pl = 'Storno: Operacja (ewidencja międzynarodowa):';
									|tr = 'İptal: İşlem (uluslararası muhasebe):'");
	EndIf;
	
EndProcedure

// Adds the "Operation (international accounting)" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 
// Returns:
//  ValueTableRow, Undefined - Add a create command based on:
// * Presentation - String -
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.TransactionFinancialAccounting) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.TransactionFinancialAccounting.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.TransactionFinancialAccounting);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseFinancialAccounting";
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Return; //In the future, the command code will be added
	
EndProcedure

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Accounting reference
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "AccountingStatement";
	PrintCommand.Presentation = NStr("vi = 'Chứng chỉ kế toán (kế toán quốc tế)';
									|ru = 'Бухгалтерская справка (международный учет)';
									|en = 'Accounting statement (financial accounting)'; fa = 'Accounting statement (financial accounting)';
									|it = 'Бухгалтерская справка (международный учет)';
									|pl = 'Accounting statement (financial accounting)';
									|tr = 'Muhasebe belgesi (uluslararası muhasebe)'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.PrintManager = "DataProcessor.PrintAccountingStatementFinancialAccounting";
	PrintCommand.AdditionalParameters.Insert("FieldContentOfOperation", "TransactionContent");
	PrintCommand.AdditionalParameters.Insert("DocumentType", "TransactionFinancialAccounting");
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndIf
