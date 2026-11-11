#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("Budgeting");
	DocumentMechanisms.Add("InventoryPlanning");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * Table - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.AssemblyDisassemblyPlan") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableAssemblyDisassemblyPlans(Query, QueryTexts, Registers);
		QueryTextTableAssemblyDisassemblyPlansForUncoupling(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.AdjustmentOfPlannedDemand.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the command to create the document "Assembly (disassembly) Plan".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.AssemblyDisassemblyPlan) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.AssemblyDisassemblyPlan.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.AssemblyDisassemblyPlan);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseAssemblyDisassemblyPlanning";
	

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
	
	Reports.PlansEquilibriumTM.AddBalancedPlansTeam(ReportsCommands);
	
	
	
EndProcedure

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.PlanStatuses[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.AssemblyDisassemblyPlan AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|ORDER BY
	|	Date";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef.PlanStatuses - New plan status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks for the "Assembly and Disassembly" document
	
EndFunction

// Forms the structure of additional details for the document
//
// Parameters:
// Parameters     - Structure - Values of additional banking details
// AddlParameters  - Structure - The composition of operands for the specified type of plan and scenario.
//
Procedure AdditionalParametersForFormulaCalculation(Parameters, AddlParameters) Export
	
	PlanProfile				= Parameters.TypeOfPlanDetails;
	Scenario 				= Parameters.ScenarioDetails;
	AttributePath1			= Parameters.AttributePath1;
	
	ThisIsAnAssemblyDisassemblyPlan			= PlanProfile.PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan;
	ThisIsProcurementPlan 					= PlanProfile.PlanType = Enums.TypesOfPlans.PurchasePlan;
	ThisIsTheProductionPlan				= PlanProfile.PlanType = Enums.TypesOfPlans.ProductionPlan;
	ThisIsTheRemainderPlan 				= PlanProfile.PlanType = Enums.TypesOfPlans.PlanOfGoodsStock;
	ThisIsASalesPlan 					= PlanProfile.PlanType = Enums.TypesOfPlans.SalesPlan;
	ThisIsASalesPlanByCategory		= PlanProfile.PlanType = Enums.TypesOfPlans.SalesPlanByCategories;
	ThisIsADomesticConsumptionPlan 	= PlanProfile.PlanType = Enums.TypesOfPlans.InventoryConsumptionPlan;
	
	CreatePropsWithSelection = PlanProfile.FillInWarehouse
		Or PlanProfile.FillInBusinessUnit
		Or (Scenario.PlanningByAssignments And Not PlanProfile.FillInAssignmentInTabularForm);
	UseBuildPlans   = GetFunctionalOption("UseAssemblyDisassemblyPlanning") And Scenario.UseInAssemblyDisassemblyPlanning;
	UseAssemblyDisassembly = GetFunctionalOption("UseAssemblyDisassembly");
	UseRemainderPlans 		= GetFunctionalOption("UsePlanningOfGoodsStock") And Scenario.UseInBalancePlanning;
	ReadingFactOfAssemblyDisassembly		= AccessRight("Read", Metadata.AccumulationRegisters.ProductStock);
	
#Region AssemblyPlansKits
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"AssemblyPlansKits");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch đóng bộ (bộ đóng gói)';
													|ru = 'План сборки (комплекты)';
													|en = 'Kitting plan (kits)'; fa = 'برنامه کیت‌سازی (کیت‌ها)';
													|it = 'Piano di assemblaggio (kit)';
													|pl = 'Plan montażu (komplety)';
													|tr = 'Montaj planı (ürün setleri)'"));
	AddnlParameter_.Insert("CreateProps", 	UseBuildPlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseBuildPlans);
	AddnlParameter_.Insert("OperandHeader",	NStr("vi = 'Kế hoạch đóng bộ (bộ đóng gói)';
													|ru = 'План сборки (комплекты)';
													|en = 'Kitting plan (kits)'; fa = 'برنامه کیت‌سازی (کیت‌ها)';
													|it = 'Piano di assemblaggio (kit)';
													|pl = 'Plan montażu (komplety)';
													|tr = 'Montaj planı (ürün setleri)'"));
	AddnlParameter_.Insert("Details", 		"Document.AssemblyDisassemblyPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("AssemblyPlansKits",AddnlParameter_);
#EndRegion
	
#Region AssemblyPlansKitsWithSelection
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"AssemblyPlansKitsWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch đóng bộ (bộ đóng gói)*';
													|ru = 'План сборки (комплекты)*';
													|en = 'Kitting plan (kits)*'; fa = 'Kitting plan (kits)*';
													|it = 'Piano di assemblaggio (i kit)*';
													|pl = 'Plan montażu (zestawy)*';
													|tr = 'Montaj planı (ürün setleri)*'"));
	AddnlParameter_.Insert("CreateProps", 	UseBuildPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseBuildPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch đóng bộ (bộ đóng gói)*';
													|ru = 'План сборки (комплекты)*';
													|en = 'Kitting plan (kits)*'; fa = 'Kitting plan (kits)*';
													|it = 'Piano di assemblaggio (i kit)*';
													|pl = 'Plan montażu (zestawy)*';
													|tr = 'Montaj planı (ürün setleri)*'"));
	AddnlParameter_.Insert("Details", 		"Document.AssemblyDisassemblyPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("AssemblyPlansKitsWithSelection",AddnlParameter_);
#EndRegion

#Region DisassemblyPlansKits
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"DisassemblyPlansKits");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch tháo gỡ (bộ dụng cụ)';
													|ru = 'План разборки (комплекты)';
													|en = 'Reverse kitting plan (kits)'; fa = 'برنامه کیت‌گشایی (کیت‌ها)';
													|it = 'Piano di disassemblaggio (kit)';
													|pl = 'Plan demontażu (komplety)';
													|tr = 'Demontaj planı (ürün setleri)'"));
	AddnlParameter_.Insert("CreateProps", 	UseBuildPlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseBuildPlans);
	AddnlParameter_.Insert("OperandHeader",	NStr("vi = 'Kế hoạch tháo gỡ (bộ dụng cụ)';
													|ru = 'План разборки (комплекты)';
													|en = 'Reverse kitting plan (kits)'; fa = 'برنامه کیت‌گشایی (کیت‌ها)';
													|it = 'Piano di disassemblaggio (kit)';
													|pl = 'Plan demontażu (komplety)';
													|tr = 'Demontaj planı (ürün setleri)'"));
	AddnlParameter_.Insert("Details", 		"Document.AssemblyDisassemblyPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("DisassemblyPlansKits",AddnlParameter_);
#EndRegion
	
#Region DisassemblyPlansKitsWithSelection
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"DisassemblyPlansKitsWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch tháo gỡ (bộ dụng cụ) *';
													|ru = 'План разборки (комплекты)*';
													|en = 'Reverse kitting plan (kits)*'; fa = 'Reverse kitting plan (kits)*';
													|it = 'Piano di dasassemblaggio (i kit)*';
													|pl = 'Plan demontażu (zestawy)*';
													|tr = 'Demontaj planı (ürün setleri)*'"));
	AddnlParameter_.Insert("CreateProps", 	UseBuildPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseBuildPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch tháo gỡ (bộ dụng cụ) *';
													|ru = 'План разборки (комплекты)*';
													|en = 'Reverse kitting plan (kits)*'; fa = 'Reverse kitting plan (kits)*';
													|it = 'Piano di dasassemblaggio (i kit)*';
													|pl = 'Plan demontażu (zestawy)*';
													|tr = 'Demontaj planı (ürün setleri)*'"));
	AddnlParameter_.Insert("Details", 		"Document.AssemblyDisassemblyPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("DisassemblyPlansKitsWithSelection",AddnlParameter_);
#EndRegion

#Region BuildPlansComponents
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"BuildPlansComponents");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch đóng bộ (thành phần chi tiết)';
													|ru = 'План сборки (комплектующие)';
													|en = 'Kitting plan (components)'; fa = 'برنامه کیت‌سازی (اجزا)';
													|it = 'Piano di assemblaggio (componenti)';
													|pl = 'Plan montażu (składniki)';
													|tr = 'Montaj planı (bileşenler)'"));
	AddnlParameter_.Insert("CreateProps", 	UseBuildPlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseBuildPlans);
	AddnlParameter_.Insert("OperandHeader",	NStr("vi = 'Kế hoạch đóng bộ (thành phần chi tiết)';
													|ru = 'План сборки (комплектующие)';
													|en = 'Kitting plan (components)'; fa = 'برنامه کیت‌سازی (اجزا)';
													|it = 'Piano di assemblaggio (componenti)';
													|pl = 'Plan montażu (składniki)';
													|tr = 'Montaj planı (bileşenler)'"));
	AddnlParameter_.Insert("Details", 		"Document.AssemblyDisassemblyPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("BuildPlansComponents",AddnlParameter_);
#EndRegion
	
#Region BuildPlansComponentsWithSelection
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"BuildPlansComponentsWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch đóng bộ (thành phần chi tiết)*';
													|ru = 'План сборки (комплектующие)*';
													|en = 'Kitting plan (components)*'; fa = 'Kitting plan (components)*';
													|it = 'Piano di assemblaggio (componenti)*';
													|pl = 'Plan montażu (składniki)*';
													|tr = 'Montaj planı (bileşenler)*'"));
	AddnlParameter_.Insert("CreateProps", 	UseBuildPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseBuildPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch đóng bộ (thành phần chi tiết)*';
													|ru = 'План сборки (комплектующие)*';
													|en = 'Kitting plan (components)*'; fa = 'Kitting plan (components)*';
													|it = 'Piano di assemblaggio (componenti)*';
													|pl = 'Plan montażu (składniki)*';
													|tr = 'Montaj planı (bileşenler)*'"));
	AddnlParameter_.Insert("Details", 		"Document.AssemblyDisassemblyPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("BuildPlansComponentsWithSelection",AddnlParameter_);
#EndRegion

#Region DisassemblyPlansComponents
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"DisassemblyPlansComponents");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch tháo gỡ (phụ kiện)';
													|ru = 'План разборки (комплектующие)';
													|en = 'Reverse kitting plan (components)'; fa = 'برنامه کیت‌گشایی (اجزا)';
													|it = 'Piano di disassemblaggio (componenti)';
													|pl = 'Plan demontażu (składniki)';
													|tr = 'Demontaj planı (bileşenler)'"));
	AddnlParameter_.Insert("CreateProps", 	UseBuildPlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseBuildPlans);
	AddnlParameter_.Insert("OperandHeader",	NStr("vi = 'Kế hoạch tháo gỡ (phụ kiện)';
													|ru = 'План разборки (комплектующие)';
													|en = 'Reverse kitting plan (components)'; fa = 'برنامه کیت‌گشایی (اجزا)';
													|it = 'Piano di disassemblaggio (componenti)';
													|pl = 'Plan demontażu (składniki)';
													|tr = 'Demontaj planı (bileşenler)'"));
	AddnlParameter_.Insert("Details", 		"Document.AssemblyDisassemblyPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("DisassemblyPlansComponents",AddnlParameter_);
#EndRegion
	
#Region DisassemblyPlansComponentsWithSelection
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"DisassemblyPlansComponentsWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch tháo gỡ (phụ kiện) *';
													|ru = 'План разборки (комплектующие)*';
													|en = 'Reverse kitting plan (components)*'; fa = 'Reverse kitting plan (components)*';
													|it = 'Piano di dasassemblaggio (componenti)*';
													|pl = 'Plan demontażu (składniki)*';
													|tr = 'Demontaj planı (bileşenler)*'"));
	AddnlParameter_.Insert("CreateProps", 	UseBuildPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseBuildPlans	And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch tháo gỡ (phụ kiện) *';
													|ru = 'План разборки (комплектующие)*';
													|en = 'Reverse kitting plan (components)*'; fa = 'Reverse kitting plan (components)*';
													|it = 'Piano di dasassemblaggio (componenti)*';
													|pl = 'Plan demontażu (składniki)*';
													|tr = 'Demontaj planı (bileşenler)*'"));
	AddnlParameter_.Insert("Details", 		"Document.AssemblyDisassemblyPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("DisassemblyPlansComponentsWithSelection",AddnlParameter_);
#EndRegion
	
#Region FactsOfAssemblySets
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"FactsOfAssemblySets");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			?(CreatePropsWithSelection, NStr("vi = 'Thực tế lắp ráp (đóng bộ) *';
																				|ru = 'Факт сборки (комплекты)*';
																				|en = 'Actual kitting (kits)*'; fa = 'Actual kitting (kits)*';
																				|it = 'Assemblaggio effettivo (i kit)*';
																				|pl = 'Fakt montażu (zestawy)*';
																				|tr = 'Montaj bilgisi (ürün setleri)*'"), 
		NStr("vi = 'Thực tế đóng bộ (bộ)';
			|ru = 'Факт сборки (комплекты)';
			|en = 'Actual kitting (kits)'; fa = 'Actual kitting (kits)';
			|it = 'Assemblaggio effettivo (i kit)';
			|pl = 'Fakt montażu (zestawy)';
			|tr = 'Montaj bilgisi (ürün setleri)'")));
	AddnlParameter_.Insert("CreateProps", 	UseAssemblyDisassembly And ReadingFactOfAssemblyDisassembly);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand",  UseAssemblyDisassembly And ReadingFactOfAssemblyDisassembly);
	AddnlParameter_.Insert("OperandHeader", ?(CreatePropsWithSelection, NStr("vi = 'Thực tế lắp ráp (đóng bộ) *';
																			|ru = 'Факт сборки (комплекты)*';
																			|en = 'Actual kitting (kits)*'; fa = 'Actual kitting (kits)*';
																			|it = 'Assemblaggio effettivo (i kit)*';
																			|pl = 'Fakt montażu (zestawy)*';
																			|tr = 'Montaj bilgisi (ürün setleri)*'"), 
		NStr("vi = 'Thực tế đóng bộ (bộ)';
			|ru = 'Факт сборки (комплекты)';
			|en = 'Actual kitting (kits)'; fa = 'Actual kitting (kits)';
			|it = 'Assemblaggio effettivo (i kit)';
			|pl = 'Fakt montażu (zestawy)';
			|tr = 'Montaj bilgisi (ürün setleri)'")));
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsFacts");
	
	AddlParameters.Insert("FactsOfAssemblySets", AddnlParameter_);
#EndRegion

#Region FactsOfAssemblyComponents
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"FactsOfAssemblyComponents");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			?(CreatePropsWithSelection, NStr("vi = 'Thực tế lắp ráp (đóng bộ) *';
																				|ru = 'Факт сборки (комплектующие)*';
																				|en = 'Actual kitting (components)*'; fa = 'Actual kitting (components)*';
																				|it = 'Assemblaggio effettivo (componenti)*';
																				|pl = 'Fakt montażu (składniki)*';
																				|tr = 'Montaj bilgi (bileşenler)*'"), 
		NStr("vi = 'Thực tế đóng bộ (thành phần chi tiết)';
			|ru = 'Факт сборки (комплектующие)';
			|en = 'Actual kitting (components)'; fa = 'Actual kitting (components)';
			|it = 'Assemblaggio effettivo (componenti)';
			|pl = 'Fakt montażu (składniki)';
			|tr = 'Montaj bilgi (bileşenler)'")));
	AddnlParameter_.Insert("CreateProps", 	UseAssemblyDisassembly And ReadingFactOfAssemblyDisassembly);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand",  UseAssemblyDisassembly And ReadingFactOfAssemblyDisassembly);
	AddnlParameter_.Insert("OperandHeader", ?(CreatePropsWithSelection, NStr("vi = 'Thực tế lắp ráp (đóng bộ) *';
																			|ru = 'Факт сборки (комплектующие)*';
																			|en = 'Actual kitting (components)*'; fa = 'Actual kitting (components)*';
																			|it = 'Assemblaggio effettivo (componenti)*';
																			|pl = 'Fakt montażu (składniki)*';
																			|tr = 'Montaj bilgi (bileşenler)*'"), 
		NStr("vi = 'Thực tế đóng bộ (thành phần chi tiết)';
			|ru = 'Факт сборки (комплектующие)';
			|en = 'Actual kitting (components)'; fa = 'Actual kitting (components)';
			|it = 'Assemblaggio effettivo (componenti)';
			|pl = 'Fakt montażu (składniki)';
			|tr = 'Montaj bilgi (bileşenler)'")));
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsFacts");
	
	AddlParameters.Insert("FactsOfAssemblyComponents", AddnlParameter_);
#EndRegion

#Region DisassemblyFactsSets
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"DisassemblyFactsSets");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			?(CreatePropsWithSelection, NStr("vi = 'Thực tế tách bộ (bộ sản phẩm) *';
																				|ru = 'Факт разборки (комплекты)*';
																				|en = 'Actual reverse kitting (kits)*'; fa = 'Actual reverse kitting (kits)*';
																				|it = 'Disassemblaggio effettivo (i kit)*';
																				|pl = 'Fakt demontażu (zestawy)*';
																				|tr = 'Demontaj bilgisi (ürün setleri)*'"), 
		NStr("vi = 'Thực tế tách bộ (bộ sản phẩm)';
			|ru = 'Факт разборки (комплекты)';
			|en = 'Actual reverse kitting (kits)'; fa = 'Actual reverse kitting (kits)';
			|it = 'Disassemblaggio effettivo (i kit)';
			|pl = 'Fakt demontażu (zestawy)';
			|tr = 'Demontaj bilgisi (ürün setleri)'")));
	AddnlParameter_.Insert("CreateProps", 	UseAssemblyDisassembly And ReadingFactOfAssemblyDisassembly);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand",  UseAssemblyDisassembly And ReadingFactOfAssemblyDisassembly);
	AddnlParameter_.Insert("OperandHeader", ?(CreatePropsWithSelection, NStr("vi = 'Thực tế tách bộ (bộ sản phẩm) *';
																			|ru = 'Факт разборки (комплекты)*';
																			|en = 'Actual reverse kitting (kits)*'; fa = 'Actual reverse kitting (kits)*';
																			|it = 'Disassemblaggio effettivo (i kit)*';
																			|pl = 'Fakt demontażu (zestawy)*';
																			|tr = 'Demontaj bilgisi (ürün setleri)*'"), 
		NStr("vi = 'Thực tế tách bộ (bộ sản phẩm)';
			|ru = 'Факт разборки (комплекты)';
			|en = 'Actual reverse kitting (kits)'; fa = 'Actual reverse kitting (kits)';
			|it = 'Disassemblaggio effettivo (i kit)';
			|pl = 'Fakt demontażu (zestawy)';
			|tr = 'Demontaj bilgisi (ürün setleri)'")));
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsFacts");
	
	AddlParameters.Insert("DisassemblyFactsSets", AddnlParameter_);
#EndRegion

#Region DisassemblyFactsComponents
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"DisassemblyFactsComponents");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			?(CreatePropsWithSelection, NStr("vi = 'Thực tế tách bộ (thành phần chi tiết) *';
																				|ru = 'Факт разборки (комплектующие)*';
																				|en = 'Actual reverse kitting (components)*'; fa = 'Actual reverse kitting (components)*';
																				|it = 'Disassemblaggio effettivo (componenti)*';
																				|pl = 'Fakt demontażu (składniki)*';
																				|tr = 'Demontaj planı (bileşenler)*'"), 
		NStr("vi = 'Thực tế tách bộ (thành phần chi tiết)';
			|ru = 'Факт разборки (комплектующие)';
			|en = 'Actual reverse kitting (components)'; fa = 'Actual reverse kitting (components)';
			|it = 'Disassemblaggio effettivo (componenti)';
			|pl = 'Fakt demontażu (składniki)';
			|tr = 'Demontaj planı (bileşenler)'")));
	AddnlParameter_.Insert("CreateProps", 	UseAssemblyDisassembly And ReadingFactOfAssemblyDisassembly);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand",  UseAssemblyDisassembly And ReadingFactOfAssemblyDisassembly);
	AddnlParameter_.Insert("OperandHeader", ?(CreatePropsWithSelection, NStr("vi = 'Thực tế tách bộ (thành phần chi tiết) *';
																			|ru = 'Факт разборки (комплектующие)*';
																			|en = 'Actual reverse kitting (components)*'; fa = 'Actual reverse kitting (components)*';
																			|it = 'Disassemblaggio effettivo (componenti)*';
																			|pl = 'Fakt demontażu (składniki)*';
																			|tr = 'Demontaj planı (bileşenler)*'"), 
		NStr("vi = 'Thực tế tách bộ (thành phần chi tiết)';
			|ru = 'Факт разборки (комплектующие)';
			|en = 'Actual reverse kitting (components)'; fa = 'Actual reverse kitting (components)';
			|it = 'Disassemblaggio effettivo (componenti)';
			|pl = 'Fakt demontażu (składniki)';
			|tr = 'Demontaj planı (bileşenler)'")));
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsFacts");
	
	AddlParameters.Insert("DisassemblyFactsComponents", AddnlParameter_);
#EndRegion
	
EndProcedure

// Returns the operand layouts for this plan
//
// Parameters:
//  Templates  - Map - A General list of layouts to which layouts for this document are added.
//
// Returns:
//   Map   - Layouts for operands.
//
Function PlanOperandTemplates(Templates = Undefined) Export

	If Templates = Undefined Then
		Templates = New Map;
	EndIf; 
	
	Templates.Insert("AssemblyPlansKits",               GetTemplate("DCS_AssemblyPlansKits"));
	Templates.Insert("AssemblyPlansKitsWithSelection",       GetTemplate("DCS_AssemblyPlansKitsWithSelection"));
	Templates.Insert("BuildPlansComponents",           GetTemplate("DCS_AssemblyPlansComponents"));
	Templates.Insert("BuildPlansComponentsWithSelection",   GetTemplate("DCS_AssemblyPlansComponentsWithSelection"));
	Templates.Insert("DisassemblyPlansKits",             GetTemplate("DCS_DisassemblyPlansKits"));
	Templates.Insert("DisassemblyPlansKitsWithSelection",     GetTemplate("DCS_DisassemblyPlansKitsWithSelection"));
	Templates.Insert("DisassemblyPlansComponents",         GetTemplate("DCS_DisassemblyPlansComponents"));
	Templates.Insert("DisassemblyPlansComponentsWithSelection", GetTemplate("DCS_DisassemblyPlansComponentsWithSelection"));
	
	Templates.Insert("FactsOfAssemblySets",             GetTemplate("DCS_FactsOfAssemblySets"));
	Templates.Insert("FactsOfAssemblyComponents",         GetTemplate("DCS_FactsOfAssemblyComponents"));
	Templates.Insert("DisassemblyFactsSets",           GetTemplate("DCS_DisassemblyFactsSets"));
	Templates.Insert("DisassemblyFactsComponents",       GetTemplate("DCS_DisassemblyFactsComponents"));
	Templates.Insert("AssemblyKitsOptions",          GetTemplate("DCS_AssemblyKitsOptions"));
	Templates.Insert("AssemblyKits",                  GetTemplate("DCS_AssemblyKits"));
	
	Return Templates;

EndFunction

// The procedure fills in the tabular part of the document using formulas or a rule for filling in planning data sources
// . it is intended for filling in the document in the background.
//
// Parameters:
//  Parameters  - Structure - Settings to fill in
//  StorageAddress - String - The address of the temporary storage where the result of the task will be placed
//  StorageAddressAdditional - String
//
Procedure FillInDocument(Val Parameters, Val StorageAddress, Val StorageAddressAdditional = "") Export
	
	Settings = Common.CommonSettingsStorageLoad(Parameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+Parameters.UUID);
	
	If TypeOf(Settings) <> Type("Structure") Then
		
		Return;
		
	EndIf;
	
	Parameters.Insert("TimeIntervals", Settings.TimeIntervals);
	
	If Parameters.Property("FillInUsingFormula") Then
		
		Parameters.Insert("PopulatedTS", Settings.PopulatedTS);
		FillInDocumentUsingFormula(Parameters, StorageAddress, StorageAddressAdditional);
		
	ElsIf Parameters.Property("FillInRule") Then
		
		Parameters.Insert("FillingRule", Settings.FillingRule);
		Parameters.Insert("UserSettings", Settings.UserSettings);
		Parameters.Insert("PopulatedTS", Settings.PopulatedTS);
		
		FillInAccordingToTheFillingRule(Parameters, StorageAddress);
		
	ElsIf Parameters.Property("FillInForReplacement") Then
		
		Parameters.Insert("PopulatedTS", Settings.PopulatedTS);
		FillInReplacementDocument(Parameters, StorageAddress);
		
	EndIf; 
	
	SetPrivilegedMode(True);
	Common.CommonSettingsStorageDelete(Parameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+Parameters.UUID, Users.CurrentUser());
	
EndProcedure

// The procedure fills in the tabular part of the document using formulas
// Parameters:
//  Parameters  - Structure - Settings to fill in:
//  	* PopulatedTS - ValueTable -
//  StorageAddress - String - The address of the temporary storage where the result of the task will be placed
//  StorageAddressAdditional - String
//
Procedure FillInDocumentUsingFormula(Val Parameters, Val StorageAddress, Val StorageAddressAdditional) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.AssemblyDisassemblyPlan.ManagerModule.FillInDocumentUsingFormula");
	
	If Not Parameters.Property("FillInUsingFormula") Then
		Return;
	EndIf; 
	
	PeriodColumnName = "DateOfAssemblyDisassembly";
	
	TimeIntervals = Parameters.TimeIntervals;
	Planning.PrepareTableOfPeriodsBeforeFillingIn(Parameters);
	Planning.FillInPeriodTable(TimeIntervals, Parameters.Periodicity, Parameters.OffsetPeriodStart, Parameters.OffsetPeriodEnd,,, Parameters.ActivePeriodStart);
	
	FoundPeriodStrings = TimeIntervals.FindRows(New Structure("Active_", True));
	TotalPeriods = FoundPeriodStrings.Count();
	If Parameters.CrossTable And TotalPeriods = 0 Then 
		
		PutToTempStorage(New ValueTable, StorageAddress);
		PutToTempStorage(Undefined, StorageAddressAdditional);
		
		Return;
		
	EndIf;
	
	Parameters.Insert("TimeIntervals", TimeIntervals); 
	
	PopulatedTS = Parameters.PopulatedTS;
	
	PeriodColumn = PopulatedTS.Columns[PeriodColumnName]; // ValueTableColumn - 
	PeriodColumn.Name = "CompositionPeriod";
	
	Result = Planning.FillInFormula(Parameters);
	
	If Result.Columns.Find("CompositionPeriod") = Undefined Then
		Result.Columns.Add("CompositionPeriod", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date))
	EndIf; 
	
	Result.Columns["CompositionPeriod"].Name = PeriodColumnName;
	PutToTempStorage(Result, StorageAddress);
	If Parameters.ActivePeriodStart > Parameters.OffsetPeriodStart Then
		PutToTempStorage(TimeIntervals, StorageAddressAdditional);
	Else
		PutToTempStorage(Undefined, StorageAddressAdditional);
	EndIf;
	
	ProcessedItemsCount = TimeIntervals.Count();
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ProcessedItemsCount);
	
EndProcedure

// The procedure fills in the tabular part of the document according to the filling rule from various sources.
//
// Parameters:
//  Parameters  - Structure - Settings to fill in:
//  	* PopulatedTS - ValueTable -
//  	* TimeIntervals See Planning.TablePeriods
//  StorageAddress - String - Address of the temporary storage where the task result will be placed
//  Settings-Structure-Additional settings for filling, filling Rule, user settings, PM
//                           filling.
//
Procedure FillInAccordingToTheFillingRule(Val Parameters, Val StorageAddress) Export
	
	If Not Parameters.Property("FillInRule") Then
		Return;
	EndIf; 
	
	PeriodColumnName = "DateOfAssemblyDisassembly";
	
	TimeIntervals = Parameters.TimeIntervals;
	
	FoundPeriodStrings = TimeIntervals.FindRows(New Structure("Active_", True));
	TotalPeriods = FoundPeriodStrings.Count();
	If Parameters.CrossTable And TotalPeriods = 0 Then 
		
		Return;
		
	EndIf;
	
	Coefficients = New Array;
	For IndexOf = 1 To TotalPeriods Do
		Coefficients.Add(1);
	EndDo;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DataParameters", Planning.GetPlanParameters(Parameters));
	If Parameters.Property("Filter") Then
		AdditionalParameters.Insert("Filter", Parameters.Filter);
	EndIf;
	
	If ValueIsFilled(Parameters.ChangeResultTo) Then
		
		AdditionalParameters.DataParameters.Insert("ZoomRatio", (100 + Parameters.ChangeResultTo) / 100);
		
	EndIf;
	
	If Parameters.Property("RoundingPrecision") Then
		AdditionalParameters.DataParameters.Insert("RoundingPrecision", Parameters.RoundingPrecision);
	EndIf;
	
	FillingRule = Parameters.FillingRule;
	UserSettings = Parameters.UserSettings;
	
	
	Result = Planning.SelectDataByRules(
		Enums.TypesOfPlans.AssemblyDisassemblyPlan, 
		FillingRule, 
		UserSettings, 
		AdditionalParameters);
	
	PopulatedTS = Parameters.PopulatedTS;
	
	If Result <> Undefined Then
		
		BitRounding = Parameters.RoundingPrecision + 3;
		
		For Each ResultString1 In Result Do
			
			If Parameters.RoundingPrecision <> 0 Then
				FunctionName = NStr("vi = 'Làm tròn(%1; %2)';
									|ru = 'Окр(%1; %2)';
									|en = 'Round(%1; %2)'; fa = 'Round(%1; %2)';
									|it = 'Окр(%1; %2)';
									|pl = 'Round(%1; %2)';
									|tr = 'Yuv(%1; %2)'");
				ResultString1.Details = StringFunctionsClientServer.SubstituteParametersToString(FunctionName, ResultString1.Details, Pow(10, -BitRounding));
				ResultString1.NumericalRepresentation = StringFunctionsClientServer.SubstituteParametersToString(FunctionName, ResultString1.NumericalRepresentation, Pow(10, -BitRounding));
			EndIf;
			
			If ResultString1.Count = null Then
				Continue;
			EndIf;
			
			If Int(ResultString1.Count * Pow(10, BitRounding)) = 0 Then
				
				Continue;
				
			EndIf;
			
			Count = Round(ResultString1.Count, BitRounding);
			
			If Parameters.CrossTable Then
				
				If ValueIsFilled(ResultString1.Period) 
					And ResultString1.Period >= Parameters.BeginOfPeriod 
					And ResultString1.Period <= Parameters.PeriodEnding Then
					
					// It is not necessary to distribute by periods
					ResultString1.Details = ResultString1.Details + " = " + ResultString1.NumericalRepresentation;
				
					If ResultString1.NumericalRepresentation <> String(Count) Then
						ResultString1.Details = ResultString1.Details + " = " + String(Count);
					EndIf;
					
					NewRow = PopulatedTS.Add();
					FillPropertyValues(NewRow, ResultString1);
					
					NewRow.Count = Count;
					NewRow.NumberOfPackages = NewRow.Count;
					NewRow[PeriodColumnName] = ResultString1.Period;
					
					Parameters.MaximumRowCodeGoods = Parameters.MaximumRowCodeGoods + 1;
					NewRow.RowCode = Parameters.MaximumRowCodeGoods;
					
					Continue;
					
				ElsIf ValueIsFilled(ResultString1.Period) Then
					// Exclude the line because it does not fall within the specified period of the plan
					Continue;
					
				EndIf; 
				
				If ResultString1.Count < 0 Then
					QuantitySign = -1;
				Else
					QuantitySign = 1;
				EndIf;
				
				QuantityDistribution = Planning.DistributeAmountInProportionToCoefficients(QuantitySign * ResultString1.Count, Coefficients, BitRounding);
				If QuantityDistribution = Undefined Then
					
					ResultString1.Details = ResultString1.Details + " = " + ResultString1.NumericalRepresentation;
					
					If ResultString1.NumericalRepresentation <> String(Count) Then
						ResultString1.Details = ResultString1.Details + " = " + String(Count);
					EndIf;
					
					Continue;
				EndIf; 
				
				// With a uniform distribution, the remainder of the rounding is subtracted from the first element, so we reset it if it went into negative.
				If QuantityDistribution[0] < 0 Then
					QuantityDistribution[0] = 0;
				EndIf;
				
				ResultString1.Details = "(" + ResultString1.Details + ") * " + NStr("vi = 'Hệ số phân bổ';
																					|ru = 'Коэфф распределения';
																					|en = 'Allocation factor'; fa = 'Allocation factor';
																					|it = 'Коэфф распределения';
																					|pl = 'Allocation factor';
																					|tr = 'Dağılım katsayısı'");
				ResultString1.NumericalRepresentation = "(" + ResultString1.NumericalRepresentation + ") * ";
				// The distribution is made starting from the last element, because the first one may be smaller than the others.
				IndexOf = QuantityDistribution.UBound();
				While IndexOf >= 0 Do
				
					Count = QuantityDistribution[IndexOf];
					PeriodDate_ = FoundPeriodStrings[FoundPeriodStrings.UBound() - IndexOf].StartDate;
					IndexOf = IndexOf - 1;
					
					If Count = 0 Then
						Continue;
					EndIf;
					
					NewRow = PopulatedTS.Add();
					FillPropertyValues(NewRow, ResultString1);
					
					NewRow.Count = QuantitySign * Count;
					NewRow.NumberOfPackages = NewRow.Count;
					NewRow[PeriodColumnName] = PeriodDate_;
					
					NewRow.Details = ResultString1.Details + " = "
						+ ResultString1.NumericalRepresentation
						+ String(Round(NewRow.Count/ResultString1.Count, 3, 1))
						+ " = " + String(NewRow.Count);
				EndDo; 
				
			Else
				
				ResultString1.Details = ResultString1.Details + " = " + ResultString1.NumericalRepresentation;
			
				If ResultString1.NumericalRepresentation <> String(Count) Then
					ResultString1.Details = ResultString1.Details + " = " + String(Count);
				EndIf;
				
				NewRow = PopulatedTS.Add();
				FillPropertyValues(NewRow, ResultString1);
				NewRow.Count = Count;
				NewRow.NumberOfPackages = NewRow.Count;
				NewRow[PeriodColumnName] = ResultString1.Period;
				
				Parameters.MaximumRowCodeGoods = Parameters.MaximumRowCodeGoods + 1;
				NewRow.RowCode = Parameters.MaximumRowCodeGoods;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	PutToTempStorage(PopulatedTS, StorageAddress);
	
EndProcedure

// The procedure fills in the tabular part of the document from the register
// Parameters:
//  Parameters  - Structure - Settings to fill in:
//  	* PopulatedTS - ValueTable -
//  StorageAddress - String - Address of the temporary storage where the task result will be placed.
//
Procedure FillInReplacementDocument(Val Parameters, Val StorageAddress) Export
	
	If Not Parameters.Property("FillInForReplacement") Then
		Return;
	EndIf; 
	
	PeriodColumnName = "DateOfAssemblyDisassembly";
	
	TimeIntervals = Parameters.TimeIntervals;
	
	FoundPeriodStrings = TimeIntervals.FindRows(New Structure("Active_", True));
	TotalPeriods = FoundPeriodStrings.Count();
	If Parameters.CrossTable And TotalPeriods = 0 Then 
		
		PutToTempStorage(New ValueTable, StorageAddress);
		Return;
		
	EndIf;
	
	Parameters.Insert("TimeIntervals", TimeIntervals); 
	
	PopulatedTS = Parameters.PopulatedTS;
	
	PeriodColumn = PopulatedTS.Columns[PeriodColumnName]; // ValueTableColumn - 
	PeriodColumn.Name = "CompositionPeriod";
	
	Result = Planning.FillInForReplacement(Parameters);
	
	If Result.Columns.Find("CompositionPeriod") = Undefined Then
		Result.Columns.Add("CompositionPeriod", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date))
	EndIf; 
	
	Result.Columns["CompositionPeriod"].Name = PeriodColumnName;
	
	PutToTempStorage(Result, StorageAddress);
	
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
	|	ValueAllowed(Warehouse)
	|	AND ValueAllowed(Scenario)
	|	AND ValueAllowed(PlanProfile)";

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

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Scenario AS Scenario,
	|	DocumentData.PlanProfile AS PlanProfile,
	|	DocumentData.Substitutional AS Substitutional,
	|	DocumentData.Status AS Status,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod,
	|	DocumentData.Warehouse.Department AS Department,
	|	DocumentData.BudgetingScenario AS BudgetingScenario,
	|	DocumentData.BudgetingScenario.Currency AS ScenarioCurrency,
	|	DocumentData.PeriodEnding AS PeriodEnding,
	|	DocumentData.Purpose AS Purpose,
	|	DocumentData.PlanProfile.FillInAssignmentInTabularForm AS FillInAssignmentInTabularForm
	|FROM
	|	Document.AssemblyDisassemblyPlan AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdditionalAttributes.LineNumber,
	|	AdditionalAttributes.Value
	|FROM
	|	Document.AssemblyDisassemblyPlan.AdditionalAttributes AS AdditionalAttributes
	|WHERE
	|	AdditionalAttributes.Ref = &Ref
	|";
	
	QueryResults = Query.ExecuteBatch(); 
	Attributes = QueryResults[0].Select();
	Attributes.Next();
	
	Query.SetParameter("Scenario",               Attributes.Scenario);
	Query.SetParameter("PlanProfile",               Attributes.PlanProfile);
	Query.SetParameter("Substitutional",             Attributes.Substitutional);
	Query.SetParameter("BusinessOperation",  Attributes.BusinessOperation);
	Query.SetParameter("PeriodEnding",       Attributes.PeriodEnding);
	Query.SetParameter("Status",                 Attributes.Status);
	Query.SetParameter("Purpose",             Attributes.Purpose);
	Query.SetParameter("FillInAssignmentInTabularForm", Attributes.FillInAssignmentInTabularForm);
	Query.SetParameter("Date",                      Attributes.Date);
	Query.SetParameter("BeginOfPeriod",             Attributes.BeginOfPeriod);
	Query.SetParameter("Department",             Attributes.Department);
	Query.SetParameter("BudgetingScenario",    Attributes.BudgetingScenario);
	Query.SetParameter("ScenarioCurrency",            Attributes.ScenarioCurrency);
	
	SelectionDetailRecords = QueryResults[1].Select();
	While SelectionDetailRecords.Next() Do
		If Not ValueIsFilled(SelectionDetailRecords.Value) Then
			Continue;
		EndIf;
		Query.SetParameter("AdditionalAttribute"+Format(SelectionDetailRecords.LineNumber, "NG=0"), SelectionDetailRecords.Value);
	EndDo;
EndProcedure

Function QueryTextTableAssemblyDisassemblyPlans(Query, QueryTexts, Registers)
	
	RegisterName = "AssemblyDisassemblyPlans";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Status AS Status,
	|	CASE
	|		WHEN GoodsTable.DateOfAssemblyDisassembly = DATETIME(1, 1, 1)
	|			THEN &PeriodEnding
	|		ELSE GoodsTable.DateOfAssemblyDisassembly
	|	END AS Period,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Warehouse AS Warehouse,
	|	&Scenario AS Scenario,
	|	&PlanProfile AS PlanProfile,
	|	GoodsTable.Ref AS AssemblyDisassemblyPlan,
	|	&BusinessOperation AS BusinessOperation,
	|	GoodsTable.ProductKit AS ProductKit,
	|	CASE
	|		WHEN GoodsTable.Substituted
	|			THEN 0
	|		ELSE GoodsTable.Count
	|	END AS Count,
	|	CASE
	|		WHEN &Status = VALUE(Enum.PlanStatuses.Upholded)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS ToOrder,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE GoodsTable.Purpose
	|	END AS Purpose,
	|	CASE
	|		WHEN GoodsTable.DemandRangeIsSpecified
	|			THEN 1
	|		ELSE 0
	|	END AS DemandRangeIsSpecified,
	|	GoodsTable.RangeOfDemandFrom    AS RangeOfDemandFrom,
	|	GoodsTable.RangeOfDemandTo    AS RangeOfDemandTo
	|FROM
	|	Document.AssemblyDisassemblyPlan.Goods AS GoodsTable
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON GoodsTable.Products = CatProducts.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND NOT GoodsTable.Canceled
	|	AND (NOT GoodsTable.Substituted
	|				AND &Status <> VALUE(Enum.PlanStatuses.Upholded)
	|			OR NOT GoodsTable.SubstitutedToOrder
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableAssemblyDisassemblyPlansForUncoupling(Query, QueryTexts, Registers)
	
	RegisterName = "AssemblyDisassemblyPlansForUncoupling";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords("ComponentsConsumptionPlans", Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	&Status AS Status,
	|	DATEADD(CASE
	|			WHEN DocumentTable.DateOfAssemblyDisassembly = DATETIME(1, 1, 1)
	|				THEN &PeriodEnding
	|			ELSE DocumentTable.DateOfAssemblyDisassembly
	|		END, DAY, -ProductKitConfigurations.AssemblyDisassemblyDurationDays) AS Period,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN &FillInAssignmentInTabularForm
	|			THEN DocumentTable.Purpose
	|		ELSE &Purpose
	|	END AS Purpose,
	|	DocumentTable.Warehouse AS Warehouse,
	|	&Scenario AS Scenario,
	|	&PlanProfile AS PlanProfile,
	|	DocumentTable.Ref AS AssemblyDisassemblyPlan,
	|	&BusinessOperation AS BusinessOperation,
	|	DocumentTable.ProductKit AS ProductKit,
	|	CASE
	|		WHEN DocumentTable.DateOfAssemblyDisassembly = DATETIME(1, 1, 1)
	|			THEN &PeriodEnding
	|		ELSE DocumentTable.DateOfAssemblyDisassembly
	|	END AS DateOfProduction,
	|	CASE
	|		WHEN DocumentTable.Substituted
	|			THEN 0
	|		ELSE DocumentTable.Count
	|	END AS Count,
	|	CASE
	|		WHEN &Status = VALUE(Enum.PlanStatuses.Upholded)
	|			THEN DocumentTable.Count
	|		ELSE 0
	|	END AS ToOrder
	|FROM
	|	Document.AssemblyDisassemblyPlan.Goods AS DocumentTable
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON DocumentTable.ProductKit = ProductKitConfigurations.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND NOT DocumentTable.Canceled
	|	AND (NOT DocumentTable.Substituted
	|				AND &Status <> VALUE(Enum.PlanStatuses.Upholded)
	|			OR NOT DocumentTable.SubstitutedToOrder
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	
	FullDocumentName = "Document.AssemblyDisassemblyPlan"; 
	ParameterValues = New Structure;
	
	RedefiningParameterCalculation = New Structure;
		
	If RegisterName = "AssemblyDisassemblyPlans" Then
	
		QueryText = QueryTextTableAssemblyDisassemblyPlans(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
				
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(QueryText,
																								FullDocumentName,
																								SynonymForDocumentTable,
																								RedefiningParameterCalculation);

	Return Result;

EndFunction

// Generates a request for calculating substituted and replacement plans
// 
// Parameters:
//  Parameters - Structure - Values of additional details.
// 
// Returns:
//  Query
Function RequestReplacementAndReplacementPlans(Parameters) Export

	Query = New Query;
	Query.Text = 
	"SELECT
	|	AssemblyDisassemblyReplacementPlan.Ref AS ReplacementPlan_3,
	|	CASE
	|		WHEN &BeginOfPeriod > AssemblyDisassemblyReplacementPlan.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE AssemblyDisassemblyReplacementPlan.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < AssemblyDisassemblyReplacementPlan.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE AssemblyDisassemblyReplacementPlan.PeriodEnding
	|	END AS PeriodEnding,
	|	AssemblyDisassemblyReplacementPlan.Status AS Status
	|FROM
	|	Document.AssemblyDisassemblyPlan AS AssemblyDisassemblyReplacementPlan
	|WHERE
	|	AssemblyDisassemblyReplacementPlan.PeriodEnding >= &BeginOfPeriod
	|	AND AssemblyDisassemblyReplacementPlan.BeginOfPeriod <= &PeriodEnding
	|	AND AssemblyDisassemblyReplacementPlan.Ref <> &Ref
	|	AND AssemblyDisassemblyReplacementPlan.Posted
	|	AND AssemblyDisassemblyReplacementPlan.PlanProfile = &PlanProfile
	|	AND (AssemblyDisassemblyReplacementPlan.Status.Order >= &StatusIndex
	|			OR AssemblyDisassemblyReplacementPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND AssemblyDisassemblyReplacementPlan.Date > &Date
	|	AND AssemblyDisassemblyReplacementPlan.BusinessOperation = &BusinessOperation
	|	AND AssemblyDisassemblyReplacementPlan.Warehouse = &Warehouse
	|	AND AssemblyDisassemblyReplacementPlan.Purpose = &Purpose
	|
	|ORDER BY
	|	BeginOfPeriod,
	|	Status
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AssemblyDisassemblySubstitutedPlan.Ref AS SubstitutedPlan,
	|	CASE
	|		WHEN &BeginOfPeriod > AssemblyDisassemblySubstitutedPlan.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE AssemblyDisassemblySubstitutedPlan.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < AssemblyDisassemblySubstitutedPlan.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE AssemblyDisassemblySubstitutedPlan.PeriodEnding
	|	END AS PeriodEnding,
	|	AssemblyDisassemblySubstitutedPlan.Status AS Status
	|FROM
	|	Document.AssemblyDisassemblyPlan AS AssemblyDisassemblySubstitutedPlan
	|WHERE
	|	AssemblyDisassemblySubstitutedPlan.PeriodEnding >= &BeginOfPeriod
	|	AND AssemblyDisassemblySubstitutedPlan.BeginOfPeriod <= &PeriodEnding
	|	AND AssemblyDisassemblySubstitutedPlan.Ref <> &Ref
	|	AND AssemblyDisassemblySubstitutedPlan.Posted
	|	AND AssemblyDisassemblySubstitutedPlan.PlanProfile = &PlanProfile
	|	AND (AssemblyDisassemblySubstitutedPlan.Status.Order <= &StatusIndex
	|			OR AssemblyDisassemblySubstitutedPlan.Status = VALUE(Enum.PlanStatuses.Upholded)
	|				AND &Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation))
	|	AND AssemblyDisassemblySubstitutedPlan.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND AssemblyDisassemblySubstitutedPlan.Date < &Date
	|	AND AssemblyDisassemblySubstitutedPlan.BusinessOperation = &BusinessOperation
	|	AND AssemblyDisassemblySubstitutedPlan.Warehouse = &Warehouse
	|	AND AssemblyDisassemblySubstitutedPlan.Purpose = &Purpose
	|
	|ORDER BY
	|	BeginOfPeriod,
	|	Status";
	
	Query.SetParameter("Ref", Parameters.Ref);
	Query.SetParameter("PlanProfile", Parameters.PlanProfile);
	Query.SetParameter("StatusIndex", Enums.PlanStatuses.IndexOf(Parameters.Status));
	Query.SetParameter("Status", Parameters.Status);
	Query.SetParameter("Date", Parameters.Date);
	Query.SetParameter("BusinessOperation", Parameters.BusinessOperation);
	Query.SetParameter("Warehouse", Parameters.Warehouse);
	Query.SetParameter("Purpose", Parameters.Purpose);
	Query.SetParameter("BeginOfPeriod", Parameters.BeginOfPeriod);
	Query.SetParameter("PeriodEnding", Parameters.PeriodEnding);
	Query.SetParameter("Periodicity", Parameters.Periodicity);
		
	Return Query;
	
EndFunction

// Generates a request to fill in the document
// 
// Parameters:
//  Parameters - Structure - Values of additional details.
// 
// Returns:
//  Query
Function ReplacementRequest(Parameters) Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	AssemblyPlansDisassemblyRevolutions.Period AS CompositionPeriod,
	|	AssemblyPlansDisassemblyRevolutions.Scenario,
	|	AssemblyPlansDisassemblyRevolutions.Status,
	|	AssemblyPlansDisassemblyRevolutions.Products,
	|	AssemblyPlansDisassemblyRevolutions.Characteristic,
	|	AssemblyPlansDisassemblyRevolutions.Purpose,
	|	AssemblyPlansDisassemblyRevolutions.Warehouse,
	|	AssemblyPlansDisassemblyRevolutions.CountTurnover AS NumberOfPackages
	|FROM
	|	AccumulationRegister.AssemblyDisassemblyPlans.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Record,
	|			Scenario = &Scenario
	|				AND PlanProfile = &PlanProfile
	|				AND (&FillInAssignmentInTabularForm OR Purpose = &Purpose)
	|				AND Status IN (&Statuses)
	|				AND &QueryTextFilterWarehouse
	|				AND &QueryTextFilterBusinessOperation) AS AssemblyPlansDisassemblyRevolutions";
		
	Query.SetParameter("EndOfPeriod",   Parameters.OffsetPeriodEnd);
	Query.SetParameter("BeginOfPeriod",  Parameters.OffsetPeriodStart);
	Query.SetParameter("Statuses",        Parameters.Statuses);
	Query.SetParameter("Scenario",       Parameters.Scenario);
	Query.SetParameter("PlanProfile",       Parameters.PlanProfile);
	Query.SetParameter("Warehouse",          Parameters.Warehouse);
	Query.SetParameter("BusinessOperation",  Parameters.BusinessOperation);
	Query.SetParameter("FillInAssignmentInTabularForm", Parameters.FillInAssignmentInTabularForm);
	Query.SetParameter("Purpose",             Parameters.Purpose);
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterWarehouse",
		?(ValueIsFilled(Parameters.Warehouse),"Warehouse = &Warehouse","True"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterBusinessOperation",
		?(ValueIsFilled(Parameters.BusinessOperation),"BusinessOperation = &BusinessOperation","True"));

	Return Query;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	
	// The needs for goods in stock in the header.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "SecuringWarehouseOrdersInHeader");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	
	// Needs for goods in stock in pm.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "ProvisionOfOrdersWarehouseVHF");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouseInTabularForm";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Goods.Warehouse";
	
	// Needs for goods in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.Goods.Purpose", "SecuringOrdersAllWarehouses");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse = FALSE AND Object.PlanProfile.FillInWarehouseInTabularForm = FALSE";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	
	// The needs for goods in stock in the header (by period).
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.GoodsByDates.Purpose", "SecuringOrdersForWarehousePeriodsInHeader");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.GoodsByDates.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.GoodsByDates.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	
	// Needs for goods in stock in pm (by period).
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.GoodsByDates.Purpose", "ProvisionOfOrdersForPeriodsWarehouseWH");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouseInTabularForm";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.GoodsByDates.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.GoodsByDates.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.GoodsByDates.Warehouse";
	
	// Needs for goods in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.GoodsByDates.Purpose", "SecuringOrdersForAllWarehousesByPeriod");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse = FALSE AND Object.PlanProfile.FillInWarehouseInTabularForm = FALSE";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.GoodsByDates.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.GoodsByDates.Characteristic";
	
	// All assignments for the Assignment field in the document header.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.Purpose");
	
	Return FormTemplate;
	
EndFunction

#EndRegion

#Region ImportDataFromFile

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
// 
// Parameters:
// 	AddressOfUploadedData- String - address of the temporary storage with a table of values that
//                                   contains the downloaded data from the file.
// 	AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                       which is a copy of the table part of the document 
//                                       that needs to be filled in from the addressable Data table.
// 	ConflictsList - ValueTable - consists of:
//  * Id - Number - Id
//  * Column - String - column name
// 	FullTabularSectionName - String - full name of the table part
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	Planning.MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters);
EndProcedure

Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	Planning.FillInListOfAmbiguities(ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters);
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Assembly (disassembly) plan
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "AssemblyDisassemblyPlan";
	PrintCommand.Presentation = NStr("vi = 'Kế hoạch đóng bộ (tách bộ)';
									|ru = 'План сборки (разборки)';
									|en = 'Kitting plan'; fa = 'برنامه کیت‌سازی';
									|it = 'Piano di assemblaggio (disassemblaggio)';
									|pl = 'Plan montażu (demontażu)';
									|tr = 'Montaj (demontaj) planı'");
	PrintCommand.CheckPostingBeforePrint = True;

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "AssemblyDisassemblyPlan") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"AssemblyDisassemblyPlan",
			NStr("vi = 'Kế hoạch đóng bộ (tách bộ)';
				|ru = 'План сборки (разборки)';
				|en = 'Kitting plan'; fa = 'برنامه کیت‌سازی';
				|it = 'Piano di assemblaggio (disassemblaggio)';
				|pl = 'Plan montażu (demontażu)';
				|tr = 'Montaj (demontaj) planı'"),
			CreatePrintedFormOfPlan(ObjectsArray, PrintObjects, PrintParameters));
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

// This function generates the printed form of the plan document
//
// Parameters:
//  Tipline        - Enum link.Plan type - the type of plan: Assembly plan, purchase Plan, etc.
//  ObjectsArray  - Array - Links to print objects
//  PrintObjects   - ValueList - list of print objects
//  PrintParameters - Structure - Additional printing options that allow you to customize the appearance of the printed form.
//
// Returns:
//   SpreadsheetDocument - A tabular document with all generated printed forms for objects.
//
Function CreatePrintedFormOfPlan(ObjectsArray, PrintObjects, PrintParameters)
	
	PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan;
	
	SetPrivilegedMode(True);
	
	If PrintParameters <> Undefined And PrintParameters.Property("CrossTable") Then
		DefaultCrossTable = PrintParameters.CrossTable = True;
		DefaultTable = PrintParameters.CrossTable = False;
	Else
		DefaultCrossTable = False;
		DefaultTable = False;
	EndIf; 
	
	DisplayHeader = True;
	If PrintParameters <> Undefined And PrintParameters.Property("DisplayHeader") Then
		DisplayHeader = PrintParameters.DisplayHeader;
	EndIf;
	
	OutputScript 		= True;
	DisplayPeriodStatus	= True;
	WithdrawWarehouse 			= True;
	DisplayVHFWarehouse 		= True;
	
	If PrintParameters <> Undefined And Not PrintParameters.Property("OutputScript", OutputScript) Then
		OutputScript 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("DisplayPeriodStatus", DisplayPeriodStatus) Then
		DisplayPeriodStatus 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("WithdrawWarehouse", WithdrawWarehouse) Then
		WithdrawWarehouse 			= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("DisplayVHFWarehouse", DisplayVHFWarehouse) Then
		DisplayVHFWarehouse 		= True;
	EndIf;
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
		
	Query = New Query(
	"SELECT
	|	DocumentTable.Ref                         AS Ref,
	|	DocumentTable.Number                          AS Number,
	|	DocumentTable.Date                           AS Date,
	|	DocumentTable.EmployeeResponsible                  AS EmployeeResponsible,
	|	DocumentTable.Status                         AS Status,
	|	DocumentTable.Periodicity                  AS Periodicity,
	|	DocumentTable.BeginOfPeriod                  AS BeginOfPeriod,
	|	DocumentTable.PeriodEnding               AS PeriodEnding,
	|	DocumentTable.Scenario                       AS Scenario,
	|	DocumentTable.PlanProfile                       AS PlanProfile,
	|	CASE
	|		WHEN &DefaultCrossTable
	|				OR DocumentTable.CrossTable
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                           AS CrossTable,
	|	DocumentTable.FilledAutomatically         AS FilledAutomatically,
	|	CatPlanProfiles.FillInBusinessUnit            AS FillInBusinessUnit,
	|	CatPlanProfiles.FillInPartner                 AS FillInPartner,
	|	CatPlanProfiles.FillInTermsOfSales               AS FillInTermsOfSales,
	|	CatPlanProfiles.FillInManager                AS FillInManager,
	|	CatPlanProfiles.FillInWarehouse                    AS FillInWarehouse,
	|	CatPlanProfiles.FillInStoreFormat           AS FillInStoreFormat,
	|	CatPlanProfiles.FillInPartnerInTabularForm              AS FillInPartnerInTabularForm,
	|	CatPlanProfiles.FillInAgreementInTabularForm            AS FillInAgreementInTabularForm,
	|	CatPlanProfiles.FillInWarehouseInTabularForm                 AS FillInWarehouseInTabularForm,
	|	PlanningScenarios.ShowNumberOfPeriod     AS ShowNumberOfPeriod,
	|	Users.Individual                     AS ResponsibleIndividual,
	|	DocumentTable.Warehouse                          AS Warehouse,
	|	DocumentTable.BusinessOperation          AS BusinessOperation,
	|	DocumentTable.Purpose AS Purpose,
	|	PlanningScenarios.PlanningByAssignments,
	|	CatPlanProfiles.FillInAssignmentInTabularForm
	|FROM
	|	Document.AssemblyDisassemblyPlan AS DocumentTable
	|		LEFT JOIN Catalog.SalesOperationsPlanningScenarios AS PlanningScenarios
	|		ON DocumentTable.Scenario = PlanningScenarios.Ref
	|		LEFT JOIN Catalog.PlanProfiles AS CatPlanProfiles
	|		ON DocumentTable.PlanProfile = CatPlanProfiles.Ref
	|		LEFT JOIN Catalog.Users AS Users
	|		ON DocumentTable.EmployeeResponsible = Users.Ref
	|WHERE
	|	DocumentTable.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref                            AS Ref,
	|	GoodsTable.Products                      AS Products,
	|	GoodsTable.Products.DescriptionFull   AS ProductNameFull_,
	|	GoodsTable.Products.Code                  AS Code,
	|	GoodsTable.Products.SKU              AS SKU,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE GoodsTable.Package
	|	END                                           AS UnitOfMeasure,
	|	GoodsTable.Characteristic.DescriptionFull AS CharacteristicFullName,
	|	GoodsTable.Characteristic                    AS Characteristic,
	|	GoodsTable.Package                          AS Package,
	|	GoodsTable.LineNumber                       AS LineNumber,
	|	GoodsTable.DateOfAssemblyDisassembly                AS PeriodDate_,
	|	GoodsTable.NumberOfPackages                AS Count,
	|	GoodsTable.Comment                       AS Comment,
	|	GoodsTable.Warehouse                             AS Warehouse,
	|	GoodsTable.ProductKit               AS ProductKit,
	|	GoodsTable.Purpose.Description           AS PurposeName,
	|	GoodsTable.Purpose                        AS Purpose
	|FROM
	|	Document.AssemblyDisassemblyPlan.Goods AS GoodsTable
	|WHERE
	|	(&DefaultTable
	|			OR NOT GoodsTable.Ref.CrossTable)
	|	AND GoodsTable.Ref IN(&DocumentsArray)
	|	AND NOT GoodsTable.Canceled
	|	AND &AdditionalTableConditions
	|
	|UNION ALL
	|
	|SELECT
	|	NestedQuery.Ref,
	|	NestedQuery.Products,
	|	NestedQuery.Products.DescriptionFull,
	|	NestedQuery.Products.Code,
	|	NestedQuery.Products.SKU,
	|	CASE
	|		WHEN NestedQuery.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN NestedQuery.Products.UnitOfMeasure
	|		ELSE NestedQuery.Package
	|	END,
	|	NestedQuery.Characteristic.DescriptionFull,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Package,
	|	MIN(NestedQuery.LineNumber),
	|	NestedQuery.PeriodDate_,
	|	SUM(NestedQuery.NumberOfPackages),
	|	MAX(NestedQuery.Comment),
	|	NestedQuery.Warehouse,
	|	NestedQuery.ProductKit,
	|	NestedQuery.Purpose.Description,
	|	NestedQuery.Purpose
	|FROM
	|	(SELECT
	|		GoodsTable.Ref AS Ref,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Package AS Package,
	|		CASE DocumentTable.Periodicity
	|			WHEN VALUE(Enum.Periodicity.YEAR)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfAssemblyDisassembly, YEAR)
	|			WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfAssemblyDisassembly, HALFYEAR)
	|			WHEN VALUE(Enum.Periodicity.QUARTER)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfAssemblyDisassembly, QUARTER)
	|			WHEN VALUE(Enum.Periodicity.MONTH)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfAssemblyDisassembly, MONTH)
	|			WHEN VALUE(Enum.Periodicity.TENDAYS)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfAssemblyDisassembly, TENDAYS)
	|			WHEN VALUE(Enum.Periodicity.WEEK)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfAssemblyDisassembly, WEEK)
	|			ELSE GoodsTable.DateOfAssemblyDisassembly
	|		END AS PeriodDate_,
	|		GoodsTable.LineNumber AS LineNumber,
	|		CASE WHEN GoodsTable.Canceled THEN 0 ELSE GoodsTable.NumberOfPackages END AS NumberOfPackages,
	|		CASE WHEN GoodsTable.Canceled THEN """" ELSE CAST(GoodsTable.Comment AS STRING(1000)) END AS Comment,
	|		GoodsTable.Warehouse                 AS Warehouse,
	|		GoodsTable.ProductKit   AS ProductKit,
	|		GoodsTable.Purpose AS Purpose
	|	FROM
	|		Document.AssemblyDisassemblyPlan.Goods AS GoodsTable
	|			INNER JOIN Document.AssemblyDisassemblyPlan AS DocumentTable
	|			ON GoodsTable.Ref = DocumentTable.Ref
	|	WHERE
	|		(&DefaultCrossTable
	|				OR GoodsTable.Ref.CrossTable)
	|		AND GoodsTable.Ref IN(&DocumentsArray)
	|		AND &AdditionalTableConditions
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.Products,
	|	NestedQuery.Products.DescriptionFull,
	|	NestedQuery.Products.Code,
	|	NestedQuery.Products.SKU,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Characteristic.DescriptionFull,
	|	NestedQuery.Purpose,
	|	NestedQuery.Purpose.Description,
	|	NestedQuery.Warehouse,
	|	NestedQuery.PeriodDate_,
	|	CASE
	|		WHEN NestedQuery.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN NestedQuery.Products.UnitOfMeasure
	|		ELSE NestedQuery.Package
	|	END,
	|	NestedQuery.Package,
	|	NestedQuery.ProductKit
	|
	|ORDER BY
	|	Ref,
	|	LineNumber,
	|	ProductNameFull_,
	|	CharacteristicFullName,
	|	PurposeName,
	|	Warehouse,
	|	ProductKit,
	|	UnitOfMeasure,
	|	PeriodDate_
	|TOTALS BY
	|	Ref");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_AssemblyDisassemblyPlan_AssemblyDisassemblyPlan";
	
	AdditionalTableConditions = "";
	
	If PrintParameters <> Undefined And PrintParameters.Property("DisplaySubassemblies") And Not PrintParameters.DisplaySubassemblies Then
		AdditionalTableConditions = "AND NOT GoodsTable.Subassembly";
	EndIf; 
	
	Query.Text = StrReplace(Query.Text, "AND &AdditionalTableConditions", AdditionalTableConditions);
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	Query.SetParameter("DefaultCrossTable", DefaultCrossTable);
	Query.SetParameter("DefaultTable", DefaultTable);
	
	ResultsArray 		= Query.ExecuteBatch(); 
	PrintData			= ResultsArray[0].Select();
	SelectionByDocuments 	= ResultsArray[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	ThereAreCrossTables = False;
	BeginningOfHeader = 0;
	EndOfHeader = 0;
	NumberWidth = 0;
	EndOfIssue = 0;
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		ProductSelection_1 = SelectionByDocuments.Select();
		
		CrossTable = PrintData.CrossTable;
		
		If CrossTable Then
			PeriodsTable = Planning.PeriodTableTemplate();
			Planning.FillInPeriodTable(PeriodsTable, 
				PrintData.Periodicity, 
				PrintData.BeginOfPeriod, 
				PrintData.PeriodEnding, 
				?(DisplayHeader, PrintData.ShowNumberOfPeriod, False));
			CrossTable = PeriodsTable.Count() > 1 Or Not DisplayHeader;
		EndIf;
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.AssemblyDisassemblyPlan.PF_MXL_AssemblyDisassemblyPlan");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the plan
		If DisplayHeader Then
			
			TemplateArea = Template.GetArea("Title");
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
			
			If PrintData.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
				TemplateTitleBar = NStr("vi = 'Kế hoạch đóng bộ';
										|ru = 'План сборки';
										|en = 'Kitting plan'; fa = 'برنامه کیت‌سازی';
										|it = 'Piano di assemblaggio';
										|pl = 'Plan montażu';
										|tr = 'Montaj planı'", Common.DefaultLanguageCode());
			Else
				TemplateTitleBar = NStr("vi = 'Kế hoạch tháo gỡ';
										|ru = 'План разборки';
										|en = 'Reverse kitting plan'; fa = 'Reverse kitting plan';
										|it = 'Piano di disassemblaggio';
										|pl = 'Plan demontażu';
										|tr = 'Demontaj planı'", Common.DefaultLanguageCode());
			EndIf; 
			TitleText = TMCommonUseClientServer.GenerateDocumentTitle(PrintData, TemplateTitleBar);
			
			TemplateArea.Parameters.TitleText = TitleText;
			SpreadsheetDocument.Put(TemplateArea);
			
			If OutputScript Then
				TemplateArea                                  = Template.GetArea("Scenario");
				ScriptPresentation                          = String(PrintData.Scenario) + ", "+ String(PrintData.Periodicity);
				TemplateArea.Parameters.ScriptPresentation  = ScriptPresentation;
				TemplateArea.Parameters.Scenario               = PrintData.Scenario;
				PresentationOfPlanView                         = String(PrintData.PlanProfile);
				TemplateArea.Parameters.PresentationOfPlanView = PresentationOfPlanView;
				TemplateArea.Parameters.PlanProfile               = PrintData.PlanProfile;
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
			
			If DisplayPeriodStatus Then
				TemplateArea                                = Template.GetArea("Period");
				PeriodPresentation                         = NStr("vi = 'Kỳ từ %1 đến %2';
																	|ru = 'Период с %1 по %2';
																	|en = 'Period from %1 to %2'; fa = 'Period from %1 to %2';
																	|it = 'Periodo da %1 a %2';
																	|pl = 'Okres od %1 do %2';
																	|tr = '%1 tarihinden %2 tarihine kadar dönem'", Common.DefaultLanguageCode());
				PeriodPresentation                         = StringFunctionsClientServer.SubstituteParametersToString(PeriodPresentation,
					Format(PrintData.BeginOfPeriod, "DLF=D"), 
					Format(PrintData.PeriodEnding, "DLF=D"));
				TemplateArea.Parameters.PeriodPresentation = PeriodPresentation;
				TemplateArea.Parameters.Status = String(PrintData.Status);
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
			
			If PrintData.FillInWarehouse And WithdrawWarehouse Then
				TemplateArea                               = Template.GetArea("Warehouse");
				WarehousePresentation_                         = String(PrintData.Warehouse);
				TemplateArea.Parameters.WarehousePresentation_ = WarehousePresentation_;
				TemplateArea.Parameters.Warehouse               = PrintData.Warehouse;
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
			
			If PrintData.PlanningByAssignments
				And Not PrintData.FillInAssignmentInTabularForm Then
				TemplateArea                                   = Template.GetArea("Purpose");
				PresentationPurpose                         = String(PrintData.Purpose);
				TemplateArea.Parameters.PresentationPurpose = PresentationPurpose;
				TemplateArea.Parameters.Purpose              = PrintData.Purpose;
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
			
		EndIf;
	
		// Output the title of the Products table
		Add_Fields = New Array; // Array of See Planning.StructureOfAdditionalField
		
		If PrintData.PlanningByAssignments
			And PrintData.FillInAssignmentInTabularForm Then
			StructureOfAdditionalField = New Structure;
			StructureOfAdditionalField.Insert("Title", NStr("vi = 'Ấn định';
															|ru = 'Назначение';
															|en = 'Assignment'; fa = 'تخصیص';
															|it = 'Destinazione';
															|pl = 'Przeznaczenie';
															|tr = 'Atama'", Common.DefaultLanguageCode()));
			StructureOfAdditionalField.Insert("ValueColumn_", "Purpose");
			Add_Fields.Add(StructureOfAdditionalField);
		EndIf;
		
		If PrintData.FillInWarehouseInTabularForm Then
			StructureOfAdditionalField = New Structure;
			StructureOfAdditionalField.Insert("Title", NStr("vi = 'Kho bãi';
															|ru = 'Склад';
															|en = 'Warehouse'; fa = 'Warehouse';
															|it = 'Magazzino';
															|pl = 'Magazyn';
															|tr = 'Ambar'", Common.DefaultLanguageCode()));
			StructureOfAdditionalField.Insert("ValueColumn_", "Warehouse");
			Add_Fields.Add(StructureOfAdditionalField);
		EndIf;
		StructureOfAdditionalField = New Structure;
		StructureOfAdditionalField.Insert("Title", NStr("vi = 'Đóng bộ';
														|ru = 'Комплектация';
														|en = 'Product kit'; fa = 'کیت کالا';
														|it = 'Componenti';
														|pl = 'Product kit';
														|tr = 'Ürün seti'", Common.DefaultLanguageCode()));
		StructureOfAdditionalField.Insert("ValueColumn_", "ProductKit");
		Add_Fields.Add(StructureOfAdditionalField);
		
		OwnGoods = ?(Not (DisplayHeader Or UseItemVariants), "ProductWithoutCharacteristics", "OwnGoods");
		Count = ?(CrossTable, "NumberOfCrosses","Count");
		
		// Calculation of the width of the product column
		ProductColumnWidth = Template.Area(OwnGoods).ColumnWidth * 2; // The area contains 2 columns - item and characteristics
		
		If Not OutputCodes Then
			ProductColumnWidth = ProductColumnWidth + Template.Area("ColumnOfCodes").ColumnWidth;
		EndIf; 
		If Add_Fields.Count() > 0 Then
			ProductColumnWidth = ProductColumnWidth -Template.Area("ProductAddField"+ Format(Add_Fields.Count(), "NFD=0; NG=0")).ColumnWidth * Add_Fields.Count();
		EndIf; 
		If DisplayHeader Or UseItemVariants Then
			ProductColumnWidth = ProductColumnWidth / 2;
		EndIf; 
		Template.Area(OwnGoods).ColumnWidth = ProductColumnWidth;
		
		TextOnFirstPage = 2;
		PeriodsOnPage = 7;
		
		RoomArea                   = Template.GetArea("TableHeader|LineNumber");
		UIArea                       = Template.GetArea("TableHeader|UniqueIdentifiers");
		AreaCodes                    = Template.GetArea("TableHeader|ColumnOfCodes");
		ProductArea                    = Template.GetArea(?(DisplayHeader, "TableHeader", "HeaderOfNHTable") + "|" + OwnGoods);
		DataArea                   = Template.GetArea(?(DisplayHeader Or CrossTable, "TableHeader", "HeaderOfNHTable") + "|" + Count);
		DataAreaCrossEnd     = Template.GetArea("TableHeader|NumberOfCrossEndings");
		AreaDatePeriod               = Template.GetArea("TableHeader|DatePeriod");
		AreaCrossUnitOfMeasurement    = Template.GetArea("TableHeader|CrossUnitOfMeasurement");
		If Add_Fields.Count() > 0 Then
			ProductFieldArea         = Template.GetArea("TableHeader|ProductAddField"+ Format(Add_Fields.Count(), "NFD=0; NG=0"));
		EndIf; 
		
		SpreadsheetDocument.Put(RoomArea);
		If Not DisplayHeader Then
			SpreadsheetDocument.Join(UIArea);
		EndIf;
		
		If OutputCodes Then
			AreaCodes.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		
		For Each AdditionalField_ In Add_Fields Do
			ProductFieldArea.Parameters.Title = AdditionalField_.Title;
			SpreadsheetDocument.Join(ProductFieldArea);
		EndDo; 
		
		PageNumber = 1;
		If CrossTable Then
			SpreadsheetDocument.Join(AreaCrossUnitOfMeasurement);
			For Each Period In PeriodsTable Do
				IndexOf = PeriodsTable.IndexOf(Period);
				If IndexOf = PeriodsTable.Count()-1 Then
					DataAreaCrossEnd.Parameters.Title = Period.Title;
					SpreadsheetDocument.Join(DataAreaCrossEnd);
				Else
					DataArea.Parameters.Title = Period.Title;
					SpreadsheetDocument.Join(DataArea);
				EndIf;
			EndDo;
		Else
			SpreadsheetDocument.Join(AreaDatePeriod);
			SpreadsheetDocument.Join(DataArea);
		EndIf; 
		
		BeginningOfHeader = SpreadsheetDocument.TableHeight - RoomArea.TableHeight +1;
		EndOfHeader = SpreadsheetDocument.TableHeight;
		NumberWidth = RoomArea.TableWidth;
		
		RoomArea                   = Template.GetArea("TableRow|LineNumber");
		UIArea                       = Template.GetArea("TableRow|UniqueIdentifiers");
		AreaCodes                    = Template.GetArea("TableRow|ColumnOfCodes");
		ProductArea                    = Template.GetArea("TableRow|" + OwnGoods);
		DataArea                   = Template.GetArea("TableRow|" + Count);
		DataAreaCrossEnd     = Template.GetArea("TableRow|NumberOfCrossEndings");
		AreaDatePeriod               = Template.GetArea("TableRow|DatePeriod");
		AreaCrossUnitOfMeasurement    = Template.GetArea("TableRow|CrossUnitOfMeasurement");
		If Add_Fields.Count() > 0 Then
			ProductFieldArea         = Template.GetArea("TableRow|ProductAddField"+ Format(Add_Fields.Count(), "NFD=0; NG=0") );
		EndIf;
		
		CurrentRow  = New Structure("Products, Characteristic, Purpose, ProductKit, Warehouse, UnitOfMeasure");
		CurrentPeriod  = 0;
		LineNumber    = 0;
	
		// Output the rows of the Goods table
		While ProductSelection_1.Next() Do
			
			IdenticalLines = True;
			If CrossTable Then
				For Each Item In CurrentRow Do
					If ProductSelection_1[Item.Key] <> Item.Value Then
						IdenticalLines = False;
						Break;
					EndIf; 
				EndDo; 
			EndIf;
			
			If Not CrossTable Or CrossTable And Not IdenticalLines Then
				
				// Additional product line formation if there is no data until the end of the period
				If CrossTable And CurrentPeriod <> 0 And CurrentPeriod < PeriodsTable.Count() Then
					While CurrentPeriod < PeriodsTable.Count() Do
						CurrentPeriod = CurrentPeriod + 1;
						If CurrentPeriod < PeriodsTable.Count() Then
							SpreadsheetDocument.Join(Template.GetArea("TableRow|" + Count));
						Else
							SpreadsheetDocument.Join(Template.GetArea("TableRow|NumberOfCrossEndings"));
						EndIf;
					EndDo;
				EndIf;
				
				FillPropertyValues(CurrentRow, ProductSelection_1);
				CurrentPeriod = 0;
				
				LineNumber = LineNumber + 1;
				
				RoomArea.Parameters.LineNumber = LineNumber;
				SpreadsheetDocument.Put(RoomArea);
				
				If Not DisplayHeader Then
					UIArea.Parameters.UniqueProductIdentifier          = String(ProductSelection_1.Products.UUID());
					UIArea.Parameters.UniqueIdentifierCharacteristic        = String(ProductSelection_1.Characteristic.UUID());
					UIArea.Parameters.UniqueIdentifierPackaging              = String(ProductSelection_1.Package.UUID());
					UIArea.Parameters.UniqueIdentifierPurpose            = String(ProductSelection_1.Purpose.UUID());
					
					If PlanType = Enums.TypesOfPlans.PurchasePlan 
						Or PlanType = Enums.TypesOfPlans.SalesPlan Then
						UIArea.Parameters.UniquePartnerID           = String(ProductSelection_1.Partner.UUID());
						UIArea.Parameters.UniqueIdentifierAgreement        = String(ProductSelection_1.Terms.UUID());
					EndIf; 
					If PlanType = Enums.TypesOfPlans.PurchasePlan 
						Or PlanType = Enums.TypesOfPlans.SalesPlan 
						Or PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
						UIArea.Parameters.UniqueWarehouseID             = String(ProductSelection_1.Warehouse.UUID());
					EndIf; 
					If PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
						UIArea.Parameters.UniqueIdentifierConfigurationOption = String(ProductSelection_1.ProductKit.UUID());
					EndIf; 
					
					SpreadsheetDocument.Join(UIArea);
				EndIf;
				
				If OutputCodes Then
					
					AreaCodes.Parameters.SKU = ProductSelection_1[NameOfCodeColumn];
					SpreadsheetDocument.Join(AreaCodes);
					
				EndIf;
				
				AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
				
				ProductArea.Parameters.Fill(ProductSelection_1);
				
				ProductArea.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
					ProductSelection_1.ProductNameFull_,
					ProductSelection_1.CharacteristicFullName,
					,
					,
					AdditionalParametersProductPresentation);
				
				SpreadsheetDocument.Join(ProductArea);
				
				For Each AdditionalField_ In Add_Fields Do
					ProductFieldArea.Parameters.Value = ProductSelection_1[AdditionalField_.ValueColumn_];
					SpreadsheetDocument.Join(ProductFieldArea);
				EndDo;
				
				If CrossTable Then
				
					AreaCrossUnitOfMeasurement.Parameters.Fill(ProductSelection_1);
					SpreadsheetDocument.Join(AreaCrossUnitOfMeasurement);
				
				EndIf; 
				
			EndIf;
			
			If CrossTable Then
				
				Period = PeriodsTable.Find(ProductSelection_1.PeriodDate_, "StartDate");
				
				IndexOf = PeriodsTable.IndexOf(Period);
				
				EmptyDataArea = Template.GetArea("TableRow|" + Count);
				EmptyDataAreaCrossEnding = Template.GetArea("TableRow|NumberOfCrossEndings");
				
				While CurrentPeriod < Period.ColumnNumber Do
					
					CurrentPeriod = CurrentPeriod + 1;
					DataArea = EmptyDataArea;
					DataAreaCrossEnd = EmptyDataAreaCrossEnding;
					
					If CurrentPeriod = Period.ColumnNumber Then
						If IndexOf < PeriodsTable.Count()-1 Then
							DataArea.Parameters.Fill(ProductSelection_1);
							Area = DataArea.Area("R1C1:R1C1");
							Area.Comment.Text = ProductSelection_1.Comment;
							SpreadsheetDocument.Join(DataArea);
						Else
							DataAreaCrossEnd.Parameters.Fill(ProductSelection_1);
							Area = DataAreaCrossEnd.Area("R1C1:R1C1");
							Area.Comment.Text = ProductSelection_1.Comment;
							SpreadsheetDocument.Join(DataAreaCrossEnd);
						EndIf; 
					Else
						SpreadsheetDocument.Join(DataArea);
					EndIf;
					
				EndDo;
				
				If CurrentPeriod = PeriodsTable.Count() Then
					CurrentPeriod = 0;
				EndIf;
				
			Else
				AreaDatePeriod.Parameters.Fill(ProductSelection_1);
				SpreadsheetDocument.Join(AreaDatePeriod);
				
				DataArea.Parameters.Fill(ProductSelection_1);
				Area = DataArea.Area("R1C1:R1C1");
				Area.Comment.Text = ProductSelection_1.Comment;
				SpreadsheetDocument.Join(DataArea);
			EndIf;
			
		EndDo;
		
		// Additional product line formation if there is no data until the end of the period
		If CrossTable And CurrentPeriod <> 0 And CurrentPeriod < PeriodsTable.Count() Then
			While CurrentPeriod < PeriodsTable.Count() Do
				CurrentPeriod = CurrentPeriod + 1;
				If CurrentPeriod < PeriodsTable.Count() Then
					SpreadsheetDocument.Join(Template.GetArea("TableRow|" + Count));
				Else
					SpreadsheetDocument.Join(Template.GetArea("TableRow|NumberOfCrossEndings"));
				EndIf;
			EndDo;
		EndIf;
		
		// We output the basement, in the event that we output the header
		If DisplayHeader Then
			RoomArea                   = Template.GetArea("TableFooter|LineNumber");
			UIArea                       = Template.GetArea("TableFooter|UniqueIdentifiers");
			AreaCodes                    = Template.GetArea("TableFooter|ColumnOfCodes");
			ProductArea                    = Template.GetArea("TableFooter|" + OwnGoods);
			DataArea                   = Template.GetArea("TableFooter|" + Count);
			DataAreaCrossEnd     = Template.GetArea("TableFooter|NumberOfCrossEndings");
			AreaDatePeriod               = Template.GetArea("TableFooter|DatePeriod");
			AreaCrossUnitOfMeasurement    = Template.GetArea("TableFooter|CrossUnitOfMeasurement");
			If Add_Fields.Count() > 0 Then
				ProductFieldArea         = Template.GetArea("TableFooter|ProductAddField"+ Format(Add_Fields.Count(), "NFD=0; NG=0") );
			EndIf;
			
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			SpreadsheetDocument.Join(ProductArea);
			For Each AdditionalField_ In Add_Fields Do
				SpreadsheetDocument.Join(ProductFieldArea);
			EndDo; 
			
			If CrossTable Then
				SpreadsheetDocument.Join(AreaCrossUnitOfMeasurement);
				
				For Each Period In PeriodsTable Do
					If Period.Active_ And Period.ColumnNumber <= 0 Then
						Continue;
					EndIf; 
					
					SpreadsheetDocument.Join(DataArea);
				EndDo;
			Else
				SpreadsheetDocument.Join(AreaDatePeriod);
				SpreadsheetDocument.Join(DataArea);
			EndIf;
			
			EndOfIssue = SpreadsheetDocument.TableHeight;
			
			// We output the Amount in words
			TemplateArea = Template.GetArea("TotalString");
			TotalString = NStr("vi = 'Toàn bộ tên gọi %NumberOfTitles%.';
								|ru = 'Всего наименований %NumberOfTitles%.';
								|en = 'Total items %NumberOfTitles%.'; fa = 'Total items %NumberOfTitles%.';
								|it = 'Totale articoli %NumberOfTitles%.';
								|pl = 'Razem przedmiotów %NumberOfTitles%.';
								|tr = 'Toplam tanım %NumberOfTitles%.'", Common.DefaultLanguageCode());
			TotalString = StrReplace(TotalString, "%NumberOfTitles%", LineNumber);
			TemplateArea.Parameters.TotalString = TotalString;
			
			SpreadsheetDocument.Put(TemplateArea);
			
			// Output signatures
			TemplateArea = Template.GetArea("Signatures");
			
			If ValueIsFilled(PrintData.ResponsibleIndividual) Then
				TemplateArea.Parameters.EmployeeResponsiblePresentation =
					PersonsTM.IndividualShortName(PrintData.ResponsibleIndividual, PrintData.Date);
				TemplateArea.Parameters.EmployeeResponsible = PrintData.ResponsibleIndividual;
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		
		SpreadsheetDocument.PutHorizontalPageBreak();
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
		If CrossTable Then
			ThereAreCrossTables = True;
		EndIf; 
		
	EndDo;
	
	If PrintData.Count() = 1 And ThereAreCrossTables Then
	
		HeaderArea = SpreadsheetDocument.Area(BeginningOfHeader, , EndOfHeader, );
		SpreadsheetDocument.RepeatOnRowPrint = HeaderArea;
		
		RoomArea = SpreadsheetDocument.Area(, 1, , NumberWidth);
		SpreadsheetDocument.RepeatOnColumnPrint = RoomArea;
	
	EndIf; 
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction

Function CreateAttachedExcelFile(DocumentRef, FormIdentifier) Export
	
	PrintParameters = New Structure;
	PrintParameters.Insert("DisplayHeader", False);
	PrintParameters.Insert("DisplaySubassemblies", False);
	
	DocumentsArray = New Array;
	DocumentsArray.Add(DocumentRef);
	
	PrintObjects = New ValueList;
	PrintObjects.Add(DocumentRef);
	
	SpreadsheetDocument = CreatePrintedFormOfPlan(DocumentsArray, PrintObjects, PrintParameters);
	TempFileName = GetTempFileName();
	SpreadsheetDocument.Write(TempFileName, SpreadsheetDocumentFileType.XLS97);
	
	FileAddressInTempStorage = PutToTempStorage(New BinaryData(TempFileName), FormIdentifier);
	CurrentDate = CurrentSessionDate();
	
	FileParameters = New Structure();
	FileParameters.Insert("Author", Users.AuthorizedUser());
	FileParameters.Insert("FilesOwner", DocumentRef);
	FileParameters.Insert("BaseName", "Excel" + " " + Format(CurrentDate, NStr("vi = 'ДФ=''дд.ММ.гггг ЧЧ.мм.сс''';
																				|ru = 'ДФ=''dd.MM.yyyy ЧЧ.мм.сс''';
																				|en = 'DF=''yyyy/MM/dd HH.mm.ss'''; fa = 'DF=''yyyy/MM/dd HH.mm.ss''';
																				|it = 'ДФ=''дд.ММ.гггг ЧЧ.мм.сс''';
																				|pl = 'DF=''dd.MM.yyyy HH.mm.ss''';
																				|tr = 'ДФ=''дд.ММ.гггг ЧЧ.мм.сс'''")));
	FileParameters.Insert("ExtensionWithoutPoint", "xls");
	FileParameters.Insert("ModificationTimeUniversal", CurrentDate);
	
	File = FilesOperations.AppendFile(FileParameters, FileAddressInTempStorage, Undefined);
	
	DeleteFiles(TempFileName);
	
	If File <> Undefined Then
		FilesOperationsInternal.BorrowFileToEditServer(File);
		FileData = FilesOperations.FileData(File, FormIdentifier, True);
		ExcelActionStructure = New Structure;
		ExcelActionStructure.Insert("AutoFilter", New Structure("RowStart1, ColumnStart1", 2, 2));
		
		// Hiding columns with the identifiers of the nomenclature and characteristics, packaging, partner, agreement, warehouse.
		ColumnsArray1 = New Array;
		ColumnsArray1.Add(3);
		ColumnsArray1.Add(4);
		ColumnsArray1.Add(5);
		ColumnsArray1.Add(6);
		ColumnsArray1.Add(7);
		ExcelActionStructure.Insert("HiddenColumns", ColumnsArray1);
		
		Return New Structure("FileData, File, ExcelActionStructure", FileData, File, ExcelActionStructure);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Document.AssemblyDisassemblyPlan.Form.ListForm";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.AssemblyDisassemblyPlan))
		And AccessRight("Insert", Metadata.Documents.AssemblyDisassemblyPlan)
		And GetFunctionalOption("UseAssemblyDisassemblyPlanning");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(*) AS AssemblyDisassemblyPlansPendingApproval,
	|	MIN(Plans.Status.Order) AS StatusOrder
	|FROM
	|	Document.AssemblyDisassemblyPlan AS Plans
	|WHERE
	|	BEGINOFPERIOD(&CurrentDate, DAY) <= Plans.PeriodEnding
	|	AND CASE
	|	WHEN NOT Plans.Substitutional
	|		THEN Plans.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|	WHEN Plans.Substitutional
	|			AND Plans.Status <> VALUE(Enum.PlanStatuses.Upholded)
	|			AND Plans.Status.Order >= 2
	|		THEN TRUE
	|	ELSE FALSE
	|	END
	|	AND Plans.Posted";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	UserTaskParent = ToDoList.Find("AssemblyDisassemblyPlans", "Id");
	If UserTaskParent = Undefined Then
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id  = "AssemblyDisassemblyPlans";
		UserTaskParent.Presentation  = NStr("vi = 'Kế hoạch phê duyệt dự tính';
											|ru = 'Планы ожидающие согласования';
											|en = 'Plans pending approval'; fa = 'Plans pending approval';
											|it = 'Piani in attesa di approvazione';
											|pl = 'Plany oczekujące na zatwierdzenie';
											|tr = 'Beklenen uyum planı'");
		UserTaskParent.Owner       = Planning.SubsystemPlanning();
	EndIf;
	
	// AssemblyDisassemblyPlansPendingApproval
	FilterParameters = New Structure;
	If Enums.PlanStatuses[Result.StatusOrder] = Enums.PlanStatuses.AwaitingConfirmation Then
		FilterParameters.Insert("Status", Enums.PlanStatuses.AwaitingConfirmation);
	EndIf;
	FilterParameters.Insert("DeletionMark", False);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "AssemblyDisassemblyPlansPendingApproval";
	ToDoItem.HasToDoItems       = Result.AssemblyDisassemblyPlansPendingApproval > 0;
	ToDoItem.Presentation  = NStr("vi = 'Kế hoạch đóng bộ (tách bộ)';
									|ru = 'Планы сборки (разборки)';
									|en = 'Kitting plans'; fa = 'برنامه‌های کیت‌سازی';
									|it = 'Piani di assemblaggio (disassemblaggio)';
									|pl = 'Plany montażu (demontażu)';
									|tr = 'Montaj (demontaj) programı'");
	ToDoItem.Count     = Result.AssemblyDisassemblyPlansPendingApproval;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "AssemblyDisassemblyPlans";
	
	If Result.AssemblyDisassemblyPlansPendingApproval > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
