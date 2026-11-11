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
	
	If TypeOf(Document) = Type("DocumentObject.ProductionPlan") Then
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
		
		QueryTextTableProductionPlans(Query, QueryTexts, Registers);
		QueryTextTableReleasePlans(Query, QueryTexts, Registers);
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
	Documents.StandardCosting2_2.AddGenerateCommand(GenerationCommands);
EndProcedure

// Adds the "production Plan" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ProductionPlan) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ProductionPlan.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ProductionPlan);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProductionPlanning";
	

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
	Reports.ProductionPlanProductsAndSemiFinishedProducts.AddReportCommand(ReportsCommands);
	Reports.PlannedDemandForWorkCenterTypes.AddReportCommand(ReportsCommands);
	Reports.PlannedDemandForMaterials.AddReportCommand(ReportsCommands);
	Reports.PlannedDemandForSemiFinishedProducts.AddReportCommand(ReportsCommands);
	Reports.PlannedDemandForHumanResources.AddReportCommand(ReportsCommands);
EndProcedure

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
	
	Return True; // There are no additional checks for the document "Production plan"
	
EndFunction

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
	|	Document.ProductionPlan AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|ORDER BY
	|	Date
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
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
	
	ThisIsTheProductionPlan		= PlanProfile.PlanType = Enums.TypesOfPlans.ProductionPlan;
	ThisIsProcurementPlan 			= PlanProfile.PlanType = Enums.TypesOfPlans.PurchasePlan;
	ThisIsAnAssemblyDisassemblyPlan 		= PlanProfile.PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan;
	ThisIsTheRemainderPlan 			= PlanProfile.PlanType = Enums.TypesOfPlans.PlanOfGoodsStock;
	CreatePropsWithSelection = (PlanProfile.FillInBusinessUnit And ThisIsTheProductionPlan)
							Or (Scenario.PlanningByAssignments And Not PlanProfile.FillInAssignmentInTabularForm);
	
	UseProductionPlanning 	= GetFunctionalOption("UseProductionPlanning") And Scenario.UseInProductionPlanning;
	UseForMaterialsPlanning	= GetFunctionalOption("UseProductionPlanning") And Scenario.UseForMaterialsPlanning;
	UseRemainderPlans 				= GetFunctionalOption("UsePlanningOfGoodsStock") And Scenario.UseInBalancePlanning;
	UseProduction 				= GetFunctionalOption("UseProduction");
	
	DescriptionOfManufacturingProcessTypeIsAvailable = False;
	DescriptionOfManufacturingProcessTypeIsAvailable = ProductDataManagement.DescriptionOfManufacturingProcessTypeIsAvailable();
	ReadingProductionFact					= AccessRight("Read", Metadata.AccumulationRegisters.ProductsRelease);
	ReadingFactOfProductionMaterials		= AccessRight("Read", Metadata.AccumulationRegisters.MaterialsAndWorksInProduction);
	
#Region ProductionPlans
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionPlans");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			?(DescriptionOfManufacturingProcessTypeIsAvailable, 
												NStr("vi = 'Kế hoạch sản xuất (đóng bộ)';
													|ru = 'План производства (сборка)';
													|en = 'Production plan (kitting)'; fa = 'Production plan (kitting)';
													|it = 'Piano di produzione (assemblaggio)';
													|pl = 'Plan produkcji (montaż)';
													|tr = 'Üretim planı(montaj)'"),
												NStr("vi = 'Kế hoạch sản xuất';
													|ru = 'План производства';
													|en = 'Production plan'; fa = 'برنامه تولید';
													|it = 'Piano di produzione';
													|pl = 'Plan produkcji';
													|tr = 'Üretim planı'")));
	AddnlParameter_.Insert("CreateProps", 	UseProductionPlanning);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseProductionPlanning);
	AddnlParameter_.Insert("OperandHeader", 	?(DescriptionOfManufacturingProcessTypeIsAvailable, 
												NStr("vi = 'Kế hoạch sản xuất (đóng bộ)';
													|ru = 'План производства (сборка)';
													|en = 'Production plan (kitting)'; fa = 'Production plan (kitting)';
													|it = 'Piano di produzione (assemblaggio)';
													|pl = 'Plan produkcji (montaż)';
													|tr = 'Üretim planı(montaj)'"),
												NStr("vi = 'Kế hoạch sản xuất';
													|ru = 'План производства';
													|en = 'Production plan'; fa = 'برنامه تولید';
													|it = 'Piano di produzione';
													|pl = 'Plan produkcji';
													|tr = 'Üretim planı'")));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("ProductionPlans", AddnlParameter_);
	
#EndRegion
	
#Region ProductionPlansWithPicking
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionPlansWithPicking");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			?(DescriptionOfManufacturingProcessTypeIsAvailable, 
												NStr("vi = 'Kế hoạch sản xuất (đóng bộ)*';
													|ru = 'План производства (сборка)*';
													|en = 'Production plan (kitting)*'; fa = 'Production plan (kitting)*';
													|it = 'Piano di produzione (disassemblaggio)*';
													|pl = 'Plan produkcji (montaż)*';
													|tr = 'Üretim planı (montaj)*'"),
												NStr("vi = 'Kế hoạch sản xuất *';
													|ru = 'План производства*';
													|en = 'Production plan*'; fa = 'Production plan*';
													|it = 'Piano di produzione*';
													|pl = 'Plan produkcji*';
													|tr = 'Üretim planı*'")));
	AddnlParameter_.Insert("CreateProps", 	UseProductionPlanning And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseProductionPlanning And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader", 	?(DescriptionOfManufacturingProcessTypeIsAvailable, 
												NStr("vi = 'Kế hoạch sản xuất (đóng bộ)*';
													|ru = 'План производства (сборка)*';
													|en = 'Production plan (kitting)*'; fa = 'Production plan (kitting)*';
													|it = 'Piano di produzione (disassemblaggio)*';
													|pl = 'Plan produkcji (montaż)*';
													|tr = 'Üretim planı (montaj)*'"),
												NStr("vi = 'Kế hoạch sản xuất *';
													|ru = 'План производства*';
													|en = 'Production plan*'; fa = 'Production plan*';
													|it = 'Piano di produzione*';
													|pl = 'Plan produkcji*';
													|tr = 'Üretim planı*'")));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("ProductionPlansWithPicking", AddnlParameter_);
	
#EndRegion

#Region ProductionPlansDisassembly
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionPlansDisassembly");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch sản xuất (tách bộ)';
													|ru = 'План производства (разборка)';
													|en = 'Production plan (reverse kitting)'; fa = 'Production plan (reverse kitting)';
													|it = 'Piano di produzione (disassemblaggio)';
													|pl = 'Plan produkcji (demontaż)';
													|tr = 'Üretim planı (demontaj)'"));
	AddnlParameter_.Insert("CreateProps", 	UseProductionPlanning And DescriptionOfManufacturingProcessTypeIsAvailable);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseProductionPlanning And DescriptionOfManufacturingProcessTypeIsAvailable);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch sản xuất (tách bộ)';
													|ru = 'План производства (разборка)';
													|en = 'Production plan (reverse kitting)'; fa = 'Production plan (reverse kitting)';
													|it = 'Piano di produzione (disassemblaggio)';
													|pl = 'Plan produkcji (demontaż)';
													|tr = 'Üretim planı (demontaj)'"));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("ProductionPlansDisassembly", AddnlParameter_);
	
#EndRegion
	
#Region ProductionPlansDisassemblyWithFilter
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionPlansDisassemblyWithFilter");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch sản xuất (tách bộ) *';
													|ru = 'План производства (разборка)*';
													|en = 'Production plan (reverse kitting)*'; fa = 'Production plan (reverse kitting)*';
													|it = 'Piano di produzione (disassemblaggio)*';
													|pl = 'Plan produkcji (demontaż)*';
													|tr = 'Üretim planı (demontaj)*'"));
	AddnlParameter_.Insert("CreateProps", 	UseProductionPlanning And DescriptionOfManufacturingProcessTypeIsAvailable And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseProductionPlanning And DescriptionOfManufacturingProcessTypeIsAvailable And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch sản xuất (tách bộ) *';
													|ru = 'План производства (разборка)*';
													|en = 'Production plan (reverse kitting)*'; fa = 'Production plan (reverse kitting)*';
													|it = 'Piano di produzione (disassemblaggio)*';
													|pl = 'Plan produkcji (demontaż)*';
													|tr = 'Üretim planı (demontaj)*'"));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("ProductionPlansDisassemblyWithFilter", AddnlParameter_);
	
#EndRegion

#Region ProductionRepairPlans
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionRepairPlans");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch sản xuất (sửa chữa)';
													|ru = 'План производства (ремонт)';
													|en = 'Production plan (R&M)'; fa = 'Production plan (R&M)';
													|it = 'Piano di produzione (manutenzione)';
													|pl = 'Plan produkcji (remont)';
													|tr = 'Üretim planı (onarım)'"));
	AddnlParameter_.Insert("CreateProps", 	UseProductionPlanning And DescriptionOfManufacturingProcessTypeIsAvailable);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseProductionPlanning And DescriptionOfManufacturingProcessTypeIsAvailable);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch sản xuất (sửa chữa)';
													|ru = 'План производства (ремонт)';
													|en = 'Production plan (R&M)'; fa = 'Production plan (R&M)';
													|it = 'Piano di produzione (manutenzione)';
													|pl = 'Plan produkcji (remont)';
													|tr = 'Üretim planı (onarım)'"));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("ProductionRepairPlans", AddnlParameter_);
	
#EndRegion
	
#Region ProductionPlansRepairWithSelection
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionPlansRepairWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch sản xuất (sửa chữa) *';
													|ru = 'План производства (ремонт)*';
													|en = 'Production plan (R&M)*'; fa = 'Production plan (R&M)*';
													|it = 'Piano di produzione (manutenzione)*';
													|pl = 'Plan produkcji (remont)*';
													|tr = 'Üretim planı (onarım)*'"));
	AddnlParameter_.Insert("CreateProps", 	UseProductionPlanning And DescriptionOfManufacturingProcessTypeIsAvailable And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseProductionPlanning And DescriptionOfManufacturingProcessTypeIsAvailable And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch sản xuất (sửa chữa) *';
													|ru = 'План производства (ремонт)*';
													|en = 'Production plan (R&M)*'; fa = 'Production plan (R&M)*';
													|it = 'Piano di produzione (manutenzione)*';
													|pl = 'Plan produkcji (remont)*';
													|tr = 'Üretim planı (onarım)*'"));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("ProductionPlansRepairWithSelection", AddnlParameter_);
	
#EndRegion
	
#Region ProductionPlansMaterials
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionPlansMaterials");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch sản xuất (nhu cầu nguyên vật liệu)';
													|ru = 'План производства (потребность в материалах)';
													|en = 'Production plan (demand for materials)'; fa = 'Production plan (demand for materials)';
													|it = 'Piano di produzione (fabbisogno di materiali)';
													|pl = 'Plan produkcji (zapotrzebowanie w materiałach)';
													|tr = 'Üretim planı (malzeme gereksinimleri)'"));
	AddnlParameter_.Insert("CreateProps", 	UseForMaterialsPlanning);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseForMaterialsPlanning);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch sản xuất (nhu cầu nguyên vật liệu)';
													|ru = 'План производства (потребность в материалах)';
													|en = 'Production plan (demand for materials)'; fa = 'Production plan (demand for materials)';
													|it = 'Piano di produzione (fabbisogno di materiali)';
													|pl = 'Plan produkcji (zapotrzebowanie w materiałach)';
													|tr = 'Üretim planı (malzeme gereksinimleri)'"));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("ProductionPlansMaterials", AddnlParameter_);
	
#EndRegion
	
#Region ProductionPlansMaterialsWithSelection
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionPlansMaterialsWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch sản xuất (yêu cầu nguyên vật liệu)*';
													|ru = 'План производства (потребность в материалах)*';
													|en = 'Production plan (demand for materials)*'; fa = 'Production plan (demand for materials)*';
													|it = 'Piano di produzione (fabbisogno di materiali)*';
													|pl = 'Plan produkcji (zapotrzebowanie w materiałach)*';
													|tr = 'Üretim planı (malzeme gereksinimleri)*'"));
	AddnlParameter_.Insert("CreateProps", 	UseForMaterialsPlanning And (CreatePropsWithSelection Or PlanProfile.FillInWarehouse));
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseForMaterialsPlanning And (CreatePropsWithSelection Or PlanProfile.FillInWarehouse));
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch sản xuất (yêu cầu nguyên vật liệu)*';
													|ru = 'План производства (потребность в материалах)*';
													|en = 'Production plan (demand for materials)*'; fa = 'Production plan (demand for materials)*';
													|it = 'Piano di produzione (fabbisogno di materiali)*';
													|pl = 'Plan produkcji (zapotrzebowanie w materiałach)*';
													|tr = 'Üretim planı (malzeme gereksinimleri)*'"));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("ProductionPlansMaterialsWithSelection", AddnlParameter_);
#EndRegion

#Region ProductionPlansSemiFinishedProducts
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionPlansSemiFinishedProducts");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch sản xuất (bán thành phẩm)';
													|ru = 'План производства (полуфабрикаты)';
													|en = 'Production plan (semi-finished products)'; fa = 'Production plan (semi-finished products)';
													|it = 'Piani di produzione (prodotti semilavorati)';
													|pl = 'Plan produkcji (półprodukty)';
													|tr = 'Üretim planı (yarı mamul ürünler)'"));
	AddnlParameter_.Insert("CreateProps", 	UseProductionPlanning);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseProductionPlanning);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch sản xuất (bán thành phẩm)';
													|ru = 'План производства (полуфабрикаты)';
													|en = 'Production plan (semi-finished products)'; fa = 'Production plan (semi-finished products)';
													|it = 'Piani di produzione (prodotti semilavorati)';
													|pl = 'Plan produkcji (półprodukty)';
													|tr = 'Üretim planı (yarı mamul ürünler)'"));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("ProductionPlansSemiFinishedProducts", AddnlParameter_);
	
#EndRegion
	
#Region ProductionPlansSemiFinishedProductsWithSelection
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionPlansSemiFinishedProductsWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch sản xuất (bán thành phẩm) *';
													|ru = 'План производства (полуфабрикаты)*';
													|en = 'Production plan (semi-finished products)*'; fa = 'Production plan (semi-finished products)*';
													|it = 'Piano di produzione (prodotti semilavorati)*';
													|pl = 'Plan produkcji (półprodukty)*';
													|tr = 'Üretim planı (yarı mamul ürünler)*'"));
	AddnlParameter_.Insert("CreateProps", 	UseProductionPlanning And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseProductionPlanning And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch sản xuất (bán thành phẩm) *';
													|ru = 'План производства (полуфабрикаты)*';
													|en = 'Production plan (semi-finished products)*'; fa = 'Production plan (semi-finished products)*';
													|it = 'Piano di produzione (prodotti semilavorati)*';
													|pl = 'Plan produkcji (półprodukty)*';
													|tr = 'Üretim planı (yarı mamul ürünler)*'"));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("ProductionPlansSemiFinishedProductsWithSelection", AddnlParameter_);
#EndRegion

#Region ProductionPlansNeedForSemiFinishedProducts
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionPlansNeedForSemiFinishedProducts");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch sản xuất (yêu cầu bán thành phẩm)';
													|ru = 'План производства (потребность в полуфабрикатах)';
													|en = 'Production plan (demand for semi-finished products)'; fa = 'Production plan (demand for semi-finished products)';
													|it = 'Piano di produzione (fabbisogno di prodotti semilavorati)';
													|pl = 'Plan produkcji (zapotrzebowanie na półprodukty)';
													|tr = 'Üretim planı (yarı mamul ürün gereksinimleri)'"));
	AddnlParameter_.Insert("CreateProps", 	UseForMaterialsPlanning);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseForMaterialsPlanning);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch sản xuất (yêu cầu bán thành phẩm)';
													|ru = 'План производства (потребность в полуфабрикатах)';
													|en = 'Production plan (demand for semi-finished products)'; fa = 'Production plan (demand for semi-finished products)';
													|it = 'Piano di produzione (fabbisogno di prodotti semilavorati)';
													|pl = 'Plan produkcji (zapotrzebowanie na półprodukty)';
													|tr = 'Üretim planı (yarı mamul ürün gereksinimleri)'"));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("ProductionPlansNeedForSemiFinishedProducts", AddnlParameter_);
	
#EndRegion
	
#Region ProductionPlansNeedForSemiFinishedProductsWithSelection
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionPlansNeedForSemiFinishedProductsWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch sản xuất (nhu cầu bán thành phẩm)*';
													|ru = 'План производства (потребность в полуфабрикатах)*';
													|en = 'Production plan (demand for semi-finished products)*'; fa = 'Production plan (demand for semi-finished products)*';
													|it = 'Piano di produzione (fabbisogno di prodotti semilavorati)*';
													|pl = 'Plan produkcji (zapotrzebowanie na półprodukty)*';
													|tr = 'Üretim planı (yarı mamul ürün gereksinimleri)*'"));
	AddnlParameter_.Insert("CreateProps", 	UseForMaterialsPlanning And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseForMaterialsPlanning And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch sản xuất (nhu cầu bán thành phẩm)*';
													|ru = 'План производства (потребность в полуфабрикатах)*';
													|en = 'Production plan (demand for semi-finished products)*'; fa = 'Production plan (demand for semi-finished products)*';
													|it = 'Piano di produzione (fabbisogno di prodotti semilavorati)*';
													|pl = 'Plan produkcji (zapotrzebowanie na półprodukty)*';
													|tr = 'Üretim planı (yarı mamul ürün gereksinimleri)*'"));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("ProductionPlansNeedForSemiFinishedProductsWithSelection", AddnlParameter_);
#EndRegion

#Region ProductionFacts
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ProductionFacts");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			?(CreatePropsWithSelection, NStr("vi = 'Thực tế sản xuất*';
																				|ru = 'Факт производства*';
																				|en = 'Actual production*'; fa = 'Actual production*';
																				|it = 'Produzione effettiva*';
																				|pl = 'Fakt produkcji*';
																				|tr = 'Üretim bilgileri*'"), 
		NStr("vi = 'Thực tế sản xuất';
			|ru = 'Факт производства';
			|en = 'Actual production'; fa = 'تولید واقعی';
			|it = 'Produzione effettiva';
			|pl = 'Fakt produkcji';
			|tr = 'Üretim bilgileri'")));
	AddnlParameter_.Insert("CreateProps", 	UseProduction And ReadingProductionFact);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", UseProduction And ReadingProductionFact);
	AddnlParameter_.Insert("OperandHeader", ?(CreatePropsWithSelection, NStr("vi = 'Thực tế sản xuất*';
																			|ru = 'Факт производства*';
																			|en = 'Actual production*'; fa = 'Actual production*';
																			|it = 'Produzione effettiva*';
																			|pl = 'Fakt produkcji*';
																			|tr = 'Üretim bilgileri*'"), 
		NStr("vi = 'Thực tế sản xuất';
			|ru = 'Факт производства';
			|en = 'Actual production'; fa = 'تولید واقعی';
			|it = 'Produzione effettiva';
			|pl = 'Fakt produkcji';
			|tr = 'Üretim bilgileri'")));
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsFacts");
	
	AddlParameters.Insert("ProductionFacts", AddnlParameter_);
#EndRegion
	
#Region ProductionFactsMaterials
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 			"ProductionFactsMaterials");
	AddnlParameter_.Insert("Type", 			New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 			AttributePath1);
	AddnlParameter_.Insert("Title", 		?(CreatePropsWithSelection, NStr("vi = 'Thực tế sản xuất (nguyên vật liệu)*';
																			|ru = 'Факт производства (материалы)*';
																			|en = 'Actual production (materials)*'; fa = 'Actual production (materials)*';
																			|it = 'Produzione effettiva (materiali)*';
																			|pl = 'Fakt produkcji (materiały)*';
																			|tr = 'Üretim bilgileri (malzemeler)*'"), 
		NStr("vi = 'Thực tế sản xuất (nguyên vật liệu)';
			|ru = 'Факт производства (материалы)';
			|en = 'Actual production (materials)'; fa = 'Actual production (materials)';
			|it = 'Produzione effettiva (materiali)';
			|pl = 'Fakt produkcji (materiały)';
			|tr = 'Üretim bilgileri (malzemeler)'")));
	AddnlParameter_.Insert("CreateProps", UseProduction And ReadingFactOfProductionMaterials);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", UseProduction And ReadingFactOfProductionMaterials);
	AddnlParameter_.Insert("OperandHeader", ?(CreatePropsWithSelection, NStr("vi = 'Thực tế sản xuất (nguyên vật liệu)*';
																			|ru = 'Факт производства (материалы)*';
																			|en = 'Actual production (materials)*'; fa = 'Actual production (materials)*';
																			|it = 'Produzione effettiva (materiali)*';
																			|pl = 'Fakt produkcji (materiały)*';
																			|tr = 'Üretim bilgileri (malzemeler)*'"), 
		NStr("vi = 'Thực tế sản xuất (nguyên vật liệu)';
			|ru = 'Факт производства (материалы)';
			|en = 'Actual production (materials)'; fa = 'Actual production (materials)';
			|it = 'Produzione effettiva (materiali)';
			|pl = 'Fakt produkcji (materiały)';
			|tr = 'Üretim bilgileri (malzemeler)'")));
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsFacts");
	
	AddlParameters.Insert("ProductionFactsMaterials", AddnlParameter_);
#EndRegion

#Region ReleasePlans
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ReleasePlans");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch sản xuất (toàn bộ xuất xưởng)';
													|ru = 'План производства (весь выпуск)';
													|en = 'Production plan (whole release)'; fa = 'برنامه تولید (کل خروجی)';
													|it = 'Produzione effettiva (produzione intera)';
													|pl = 'Plan produkcji (cala produkcja)';
													|tr = 'Üretim planı (çıkış ağırlığı)'"));
	AddnlParameter_.Insert("CreateProps", 	UseProductionPlanning);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseProductionPlanning);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch sản xuất (toàn bộ xuất xưởng)';
													|ru = 'План производства (весь выпуск)';
													|en = 'Production plan (whole release)'; fa = 'برنامه تولید (کل خروجی)';
													|it = 'Produzione effettiva (produzione intera)';
													|pl = 'Plan produkcji (cala produkcja)';
													|tr = 'Üretim planı (çıkış ağırlığı)'"));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("ReleasePlans", AddnlParameter_);
	
#EndRegion
	
#Region ReleasePlansWithSelection
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"ReleasePlansWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch sản xuất (toàn bộ xuất xưởng) *';
													|ru = 'План производства (весь выпуск)*';
													|en = 'Production plan (whole release)*'; fa = 'Production plan (whole release)*';
													|it = 'Produzione effettiva (produzione intera)*';
													|pl = 'Plan produkcji (cała produkcja)*';
													|tr = 'Üretim planı (çıkış ağırlığı)*'"));
	AddnlParameter_.Insert("CreateProps", 	UseProductionPlanning And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseProductionPlanning And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch sản xuất (toàn bộ xuất xưởng) *';
													|ru = 'План производства (весь выпуск)*';
													|en = 'Production plan (whole release)*'; fa = 'Production plan (whole release)*';
													|it = 'Produzione effettiva (produzione intera)*';
													|pl = 'Plan produkcji (cała produkcja)*';
													|tr = 'Üretim planı (çıkış ağırlığı)*'"));
	AddnlParameter_.Insert("Details", 		"Document.ProductionPlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("ReleasePlansWithSelection", AddnlParameter_);
	
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
	
	Templates.Insert("ProductionPlans",                                   GetTemplate("DCS_ProductionPlans"));
	Templates.Insert("ProductionPlansWithPicking",                           GetTemplate("DCS_ProductionPlansWithPicking"));
	Templates.Insert("ProductionPlansDisassembly",                           GetTemplate("DCS_ProductionPlansDisassembly"));
	Templates.Insert("ProductionPlansDisassemblyWithFilter",                   GetTemplate("DCS_ProductionPlansDisassemblyWithFilter"));
	Templates.Insert("ProductionRepairPlans",                             GetTemplate("DCS_ProductionRepairPlans"));
	Templates.Insert("ProductionPlansRepairWithSelection",                     GetTemplate("DCS_ProductionPlansRepairWithSelection"));
	Templates.Insert("ProductionPlansSemiFinishedProducts",                      GetTemplate("DCS_ProductionPlansSemiFinishedProducts"));
	Templates.Insert("ProductionPlansSemiFinishedProductsWithSelection",              GetTemplate("DCS_ProductionPlansSemiFinishedProductsWithSelection"));
	Templates.Insert("ProductionPlansMaterials",                          GetTemplate("DCS_ProductionPlansMaterials"));
	Templates.Insert("ProductionPlansMaterialsWithSelection",                  GetTemplate("DCS_ProductionPlansMaterialsWithSelection"));
	Templates.Insert("ProductionPlansNeedForSemiFinishedProducts",         GetTemplate("DCS_ProductionPlansNeedForSemiFinishedProducts"));
	Templates.Insert("ProductionPlansNeedForSemiFinishedProductsWithSelection", GetTemplate("DCS_ProductionPlansNeedForSemiFinishedProductsWithSelection"));
	Templates.Insert("ProductionFacts",                                   GetTemplate("DCS_ProductionFacts"));
	Templates.Insert("ProductionFactsMaterials",                          GetTemplate("DCS_ProductionFactsMaterials"));
	Templates.Insert("ManufacturedProducts",                               GetTemplate("DCS_ManufacturedProducts"));
	Templates.Insert("ReleasePlans",                                        GetTemplate("DCS_ReleasePlans"));
	Templates.Insert("ReleasePlansWithSelection",                                GetTemplate("DCS_ReleasePlansWithSelection"));
	
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
	
	Parameters.Insert("PopulatedTS", Settings.PopulatedTS);
	Parameters.Insert("TimeIntervals", Settings.TimeIntervals);

	If Parameters.Property("FillInUsingFormula") Then
		
		FillInDocumentUsingFormula(Parameters, StorageAddress, StorageAddressAdditional);
		
	ElsIf Parameters.Property("FillInRule") Then
		
		Parameters.Insert("FillingRule", Settings.FillingRule);
		Parameters.Insert("UserSettings", Settings.UserSettings);
		
		FillInAccordingToTheFillingRule(Parameters, StorageAddress);
		
	ElsIf Parameters.Property("FillInForReplacement") Then
		
		Parameters.Insert("PopulatedTS", Settings.PopulatedTS);
		FillInReplacementDocument(Parameters, StorageAddress);
		
	EndIf; 
	
	// Planning of semi-finished products after filling out the composition of the document
	If Parameters.Property("PlanningSemiFinishedProducts") Then
	
		FillDocumentWithSemiFinishedProducts(Parameters, StorageAddress);
	
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
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.ProductionPlan.ManagerModule.FillInDocumentUsingFormula");
	
	If Not Parameters.Property("FillInUsingFormula") Then
		Return;
	EndIf; 
	
	ProductionProcessType = Common.ObjectAttributeValue(Parameters.Ref, "ProductionProcessType");
	
	If ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
		PeriodColumnName = "StartDate2";
	Else
		PeriodColumnName = "DateOfProduction";
	EndIf;

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
	Parameters.Insert("PopulatedTS", Result);
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
	
	ProductionProcessType = Common.ObjectAttributeValue(Parameters.Ref, "ProductionProcessType");
	
	If ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
		PeriodColumnName = "StartDate2";
	Else
		PeriodColumnName = "DateOfProduction";
	EndIf;
	
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
	
	BOMSelectionParameters = Parameters.BOMSelectionParameters;
	
	CachedValues = Undefined;
	
	Result = Planning.SelectDataByRules(
		Enums.TypesOfPlans.ProductionPlan, 
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
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Parameters.Insert("PopulatedTS", PopulatedTS);
	PutToTempStorage(PopulatedTS, StorageAddress);
	
EndProcedure

// The procedure supplements the tabular part of the document with semi-finished products
// Parameters:
//  Parameters  - Structure - Settings to fill in:
//  	* PopulatedTS - ValueTable -
//  StorageAddress - String - Address of the temporary storage where the task result will be placed.
//
Procedure FillDocumentWithSemiFinishedProducts(Val Parameters, Val StorageAddress) Export
	
	If Not Parameters.Property("PlanningSemiFinishedProducts") Then
		Return;
	EndIf; 
	
	PopulatedTS = Parameters.PopulatedTS;
	
	If PopulatedTS.Columns.Find("SemiFinishedProduct") = Undefined Then
		PopulatedTS.Columns.Add("SemiFinishedProduct", New TypeDescription("Boolean"));
	EndIf; 
	
	If PopulatedTS.Columns.Find("Characteristic") = Undefined Then
		PopulatedTS.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	
	BOMSelectionParameters = Parameters.BOMSelectionParameters;
	
	MaterialSpecificationSelectionParameters = Common.CopyRecursive(BOMSelectionParameters, False);
	MaterialSpecificationSelectionParameters.AvailableTypes = CommonClientServer.ValueInArray(Enums.ProductionProcessTypes.Assembly);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	HowToCalculateLaunchDate = New Array;
	
	DataArray = New Array;
	RowsArray = New Array;
	RowsToProcess = New Array;
	For Each TSRow In PopulatedTS Do
		
		If Not ValueIsFilled(TSRow.BillOfMaterials) Then
			
			FillParameters = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
				Parameters, TSRow, BOMSelectionParameters,, New Structure("KeyOfDataPaths", "Object.ManufacturedProduct"));
			FillParameters.ProductData.ProductionStart = ?(Parameters.Property("OffsetPeriodStart"),
																		Parameters.OffsetPeriodStart,
																		Parameters.BeginOfPeriod);
			
			HowToCalculateLaunchDate.Add(TSRow);
			
			DataArray.Add(FillParameters.ProductData);
		
			RowsArray.Add(TSRow);
		EndIf;
		
		If TSRow.Count = 0
			And TSRow.NumberOfPackages <> 0 Then
			RowsToProcess.Add(TSRow);
		EndIf;
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		PopulatedTS,
		CachedValues);
			
	ProductDataManagement.FillInSpecificationInLines(RowsArray, DataArray, BOMSelectionParameters);
	
	If HowToCalculateLaunchDate.Count() > 0 Then
		Planning.GetDurationSpecificationsAndFillDatesOnSchedule(
			HowToCalculateLaunchDate,
			"DateOfProduction",
			"StartDate2",
			Parameters.Scenario,
			False,
			Parameters.DemandForMaterials);
	EndIf;
	
	ScheduleParameters = Undefined;
	
	SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters(
		"MaterialsAndServices",
		,
		ProductionSupply.SoftwareOptionAccordingToProductionVersion(Parameters.ProductionManagement2_2));
	SelectionParameters.MethodOfCalculationOfMaterials = Parameters.DemandForMaterials;
	SelectionParameters.RoundUpNumberOfUnitItems_ = False;
	
	PopulatedTS.Columns.Add("SpecificationsUsed");
	ThereIs_ColumnCanceled = PopulatedTS.Columns.Find("Canceled")<> Undefined;
	If PopulatedTS.Columns.Find("ReleaseDateOfProductsOrSemiFinishedProduct") = Undefined Then
		PopulatedTS.Columns.Add("ReleaseDateOfProductsOrSemiFinishedProduct", New TypeDescription("Date"));
	EndIf;
	
	For Each TSRow In PopulatedTS Do
		
		If Not ValueIsFilled(TSRow.BillOfMaterials) Or TSRow.Count = 0
			Or (ThereIs_ColumnCanceled And TSRow.Canceled) Then
			TSRow.SpecificationsUsed = Undefined;
			Continue;
		EndIf;
		
		QuantitySign = 1;
		
		ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
		FillPropertyValues(ItemData_3, TSRow);
		ItemData_3.ProductionDispatcherBusinessUnit  = Parameters.Department;
		ItemData_3.ProductionStart      = TSRow.StartDate2;
		
		If TSRow.Count < 0 Then
			ItemData_3.Count = -ItemData_3.Count;
			QuantitySign = -1;
		EndIf;
		
		SpecificationData = Catalogs.BillsOfMaterials.SpecificationDataBySemiFinishedProducts(
			ItemData_3,
			True,
			SelectionParameters);
		
		If Parameters.TransferDemandOfBusinesUnitsThroughTransfers Then
			CalculationOfProductionPlan.ForwardMovements(SpecificationData.MaterialsAndServices);
		EndIf;
		HowToCalculateLaunchDate.Clear();
		
		DataArray = New Array;
		RowsArray = New Array;
		
		// Data on materials
		For Each ElementMaterial In SpecificationData.MaterialsAndServices Do
			
			If Not ElementMaterial.ToPlan Then
				Continue;
			EndIf;
			
			NewRow = PopulatedTS.Add();
			FillPropertyValues(NewRow, ElementMaterial,	"Products,Characteristic, Count");
			NewRow.SemiFinishedProduct = ElementMaterial.ToPlan;
			NewRow.Count = QuantitySign * NewRow.Count;
			NewRow.NumberOfPackages = NewRow.Count;
			
			NewRow.DateOfProduction = GetDateBySchedule(TSRow.DateOfProduction, ElementMaterial.DaysFromDemand, ScheduleParameters);
			If ValueIsFilled(TSRow.ReleaseDateOfProductsOrSemiFinishedProduct) Then
				NewRow.ReleaseDateOfProductsOrSemiFinishedProduct = TSRow.ReleaseDateOfProductsOrSemiFinishedProduct;
			Else
				NewRow.ReleaseDateOfProductsOrSemiFinishedProduct =  PlanningClientServer.CalculateStartDateOfPeriod(TSRow.DateOfProduction, Parameters.Periodicity);
			EndIf;
			
			If ElementMaterial.WithAssignment Then
				NewRow.Purpose              = TSRow.Purpose;
				NewRow.LineOfBusiness = TSRow.LineOfBusiness;
			EndIf;
			
			If Parameters.FillInBOMByPeriods Then
				Date = NewRow.DateOfProduction;
			Else
				If Parameters.Property("OffsetPeriodStart") Then
					Date = Min(Parameters.OffsetPeriodStart, NewRow.DateOfProduction);
				ElsIf Parameters.Property("BeginOfPeriod") Then
					Date = Min(Parameters.BeginOfPeriod, NewRow.DateOfProduction);
				EndIf;
			EndIf;
			
			FillParameters = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
				Parameters, NewRow, MaterialSpecificationSelectionParameters);
			FillParameters.ProductData.ProductionStart = Date;
			
			DataArray.Add(FillParameters.ProductData);
		
			RowsArray.Add(NewRow);
			
			
		EndDo;
		
		ProductDataManagement.FillInSpecificationInLines(RowsArray, DataArray, BOMSelectionParameters);
		
		For Each NewRow In RowsArray Do
			If ValueIsFilled(TSRow.SpecificationsUsed) Then
				If TSRow.SpecificationsUsed.Find(NewRow.BillOfMaterials) <> Undefined Then
					NewRow.BillOfMaterials = Undefined;
					Continue;
				EndIf;
				
				FMSpecificationsUsed = New FixedArray(TSRow.SpecificationsUsed);
				SpecificationsUsed = New Array(FMSpecificationsUsed);
				
				SpecificationsUsed.Add(NewRow.BillOfMaterials);
				
				NewRow.SpecificationsUsed = SpecificationsUsed;
			Else
				SpecificationsUsed = New Array;
				SpecificationsUsed.Add(NewRow.BillOfMaterials);
				
				NewRow.SpecificationsUsed = SpecificationsUsed;
			EndIf;
			
			HowToCalculateLaunchDate.Add(NewRow);
			
		EndDo;
		
		If HowToCalculateLaunchDate.Count() > 0 Then
			Planning.GetDurationSpecificationsAndFillDatesOnSchedule(
				HowToCalculateLaunchDate,
				"DateOfProduction",
				"StartDate2",
				Parameters.Scenario,
				False,
				Parameters.DemandForMaterials);
		EndIf;
		
		TSRow.SpecificationsUsed = Undefined;
		
	EndDo;
	
	GroupingColumns = "";
	For Each Column In PopulatedTS.Columns Do
		If Column.Name = "Count"
			Or Column.Name = "NumberOfPackages" Then
			Continue;
		EndIf;
		If GroupingColumns <> "" Then
			GroupingColumns = GroupingColumns + ",";
		EndIf;
		GroupingColumns = GroupingColumns + Column.Name;
	EndDo;
	PopulatedTS.GroupBy(GroupingColumns, "Count, NumberOfPackages");
	
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
	
	ProductionProcessType = Common.ObjectAttributeValue(Parameters.Ref, "ProductionProcessType");
	
	If ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
		PeriodColumnName = "StartDate2";
	Else
		PeriodColumnName = "DateOfProduction";
	EndIf;

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

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	
	// Needs for goods in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.ManufacturedProduct.Purpose", "SecuringOrdersAllWarehouses");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse = FALSE AND Object.ManufacturedProduct.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProduct.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProduct.Characteristic";
	
	// All assignments for the works of the Product Assignment field.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.ManufacturedProduct.Purpose");
	
	// Needs for goods in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.ProductsByDate.Purpose", "SecuringOrdersForAllWarehousesByPeriod");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse = FALSE AND Object.ProductsByDate.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ProductsByDate.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ProductsByDate.Characteristic";
	
	// All assignments for works of the Product Assignment field by period.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.ProductsByDate.Purpose");
	
	// All assignments for the Assignment field in the document header.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.Purpose");
	
	Return FormTemplate;
	
EndFunction

// Returns parameters for selecting specifications for the items specified in the document.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of the choice specs.
//
// Returns:
//   Structure - A structure that overrides the defaults set in the management function of the Client Server's data items.Parameterselectionspecifications().
//
Function BOMSelectionParameters(Object) Export
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	BOMSelectionParameters.AvailableTypes.Add(Object.ProductionProcessType);
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	ThisIsDisassembly = (Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly);
	FillInBOMByPeriods = (Common.ObjectAttributeValue(Object.PlanProfile, "FillInBOMByPeriods") = True);
	
	// ManufacturedProduct
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	
	ChoiceParameterLinks.Products            = "Object.ManufacturedProduct.Products";
	ChoiceParameterLinks.Characteristic          = "Object.ManufacturedProduct.Characteristic";
	ChoiceParameterLinks.ProductionDispatcherBusinessUnit  = "Object.Department";
	ChoiceParameterLinks.LineOfBusiness = "Object.ManufacturedProduct.LineOfBusiness";
	If Not Object.CrossTable And FillInBOMByPeriods Then
		ChoiceParameterLinks.ProductionStart  = StrTemplate("Object.ManufacturedProduct.%1", ?(ThisIsDisassembly, "StartDate2", "DateOfProduction"));
	Else
		ChoiceParameterLinks.ProductionStart  = "Object.BeginOfPeriod";
	EndIf;
	BOMSelectionParameters.ChoiceParameterLinks.Insert("Object.ManufacturedProduct.BillOfMaterials", ChoiceParameterLinks);
	
	// Products by date
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	
	ChoiceParameterLinks.Products            = "ProductsByDate.Products";
	ChoiceParameterLinks.Characteristic          = "ProductsByDate.Characteristic";
	ChoiceParameterLinks.ProductionDispatcherBusinessUnit  = "Object.Department";
	ChoiceParameterLinks.LineOfBusiness = "ProductsByDate.LineOfBusiness";
	ChoiceParameterLinks.ProductionStart      = "Object.BeginOfPeriod";
	BOMSelectionParameters.ChoiceParameterLinks.Insert("ProductsByDate.BillOfMaterials", ChoiceParameterLinks);
	
	Return BOMSelectionParameters;
	
EndFunction

// The names of the details, the values of which depend on the selection parameters spec
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	AttributesNames = "PlanProfile,ProductionProcessType,Scenario,CrossTable";
	Return AttributesNames;
	
EndFunction

// Performs a complete recalculation of production plans (for calling through the mechanism of long operations).
//
// Parameters:
//  Parameters		 - Structure - contains the following data:
//  * References 			- Array - links to the plans of production for processing.
//  * RunJob 	- Boolean - indicates that after adding all tasks, you need to start their execution.
//  StorageAddress	 - String	 - address of the storage where the result of the procedure can be placed.
//
Procedure RecalculateProductionPlans(Parameters, StorageAddress) Export
	
	UnpostedDocuments = Common.CheckDocumentsPosting(Parameters.References);
	
	ConductErrors = Common.PostDocuments(UnpostedDocuments);
	
	If ConductErrors.Count() > 0 Then
		
		UnpostedDocuments = New Array();
		
		For Each ErrorDescription In ConductErrors Do
			UnpostedDocuments.Add(ErrorDescription.Ref);
		EndDo;
		
	EndIf;
	
	DocumentsList = CommonClientServer.ArraysDifference(Parameters.References,
																	 UnpostedDocuments);
	
	For Each Document In DocumentsList Do
		
		RecalculateProductionPlan(Document);
		
	EndDo;
	
	InformationRegisters.QueueOfProductionPlanCalculation.RunJob();
	
EndProcedure

// Performs a complete recalculation of production plans.
//
// Parameters:
//  Ref			 - DocumentRef.ProductionPlan	 - production plan.
//  RunJob - Boolean							 - flag, start the task to recalculate the production plan.
//
Procedure RecalculateProductionPlan(Ref, RunJob = False) Export
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Document.ProductionPlan");
		LockItem.SetValue("Ref", Ref);
		Block.Lock();
		
		DocumentObject = Ref.GetObject();
		
		DocumentObject.AdditionalProperties.Insert("CompleteRecalculation", True);
		
		DocumentObject.Write(DocumentWriteMode.Write);
		
		InformationRegisters.QueueOfProductionPlanCalculation.AddJob(DocumentObject.Scenario, Ref, RunJob);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		Event = CalculationOfProductionPlan.EventLogEvent();
		
		ErrorText = DetailErrorDescription(ErrorInfo());
		MessageText = StrTemplate(NStr("vi = 'Không thể đặt ranh giới tính toán mới trong chứng từ: %Ref% vì lý do: %Cause%';
										|ru = 'Не удалось установить новую границу расчета в документе: %Ref% по причине: %Cause%';
										|en = 'Cannot set a new calculation limit in the document: %Ref%. Reason: %Cause%'; fa = 'Cannot set a new calculation limit in the document: %Ref%. Reason: %Cause%';
										|it = 'Non è stato possibili impostare il nuovo limite di calcolo nel documento: %Ref% a causa di: %Cause%';
										|pl = 'Nie udało się ustawić nową granicę obliczenia w dokumencie: %Ref% z powodu: %Cause%';
										|tr = 'Belgede yeni sınır muhasebesi kurulamadı:%Ref% sebebinden dolayı: %Cause%'"), Ref, ErrorText);
		
		WriteLogEvent(
			Event,
			EventLogLevel.Error,
			Ref.Metadata(),
			Ref,
			MessageText);
		
	EndTry;
	
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
	|	ValueAllowed(Department)
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
	|	DocumentData.Status AS Status,
	|	DocumentData.Scenario AS Scenario,
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod,
	|	DocumentData.PeriodEnding AS PeriodEnding,
	|	DocumentData.Department AS Department,
	|	DocumentData.BudgetingScenario AS BudgetingScenario,
	|	DocumentData.BudgetingScenario.Currency AS ScenarioCurrency,
	|	DocumentData.Scenario AS PlanningScenario,
	|	DocumentData.PlanProfile AS PlanProfile,
	|	DocumentData.Scenario.Periodicity AS Periodicity,
	|	ISNULL(DocumentData.Scenario.UseForMaterialsPlanning, FALSE) AS UseForMaterialsPlanning,
	|	DocumentData.Purpose AS Purpose,
	|	DocumentData.Substitutional AS Substitutional,
	|	DocumentData.ProductionProcessType AS ProductionProcessType,
	|	DocumentData.PointInTime AS PointInTime,
	|	DocumentData.CalculationSeparator AS CalculationSeparator,
	|	DocumentData.PlanProfile.FillInAssignmentInTabularForm AS FillInAssignmentInTabularForm,
	|	DocumentData.PlanProfile.PlanSemiFinishedProductsAutomatically AS PlanSemiFinishedProductsAutomatically
	|FROM
	|	Document.ProductionPlan AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdditionalAttributes.LineNumber AS LineNumber,
	|	AdditionalAttributes.Value AS Value
	|FROM
	|	Document.ProductionPlan.AdditionalAttributes AS AdditionalAttributes
	|WHERE
	|	AdditionalAttributes.Ref = &Ref";
	
	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch(); 
	Attributes = QueryResults[0].Select();
	Attributes.Next();
	
	Query.SetParameter("Date",                         Attributes.Date);
	Query.SetParameter("Status",                       Attributes.Status);
	Query.SetParameter("Scenario",                     Attributes.Scenario);
	Query.SetParameter("PlanProfile",                     Attributes.PlanProfile);
	Query.SetParameter("BeginOfPeriod",                Attributes.BeginOfPeriod);
	Query.SetParameter("PeriodEnding",             Attributes.PeriodEnding);
	Query.SetParameter("Department",                Attributes.Department);
	Query.SetParameter("BudgetingScenario",       Attributes.BudgetingScenario);
	Query.SetParameter("ScenarioCurrency",               Attributes.ScenarioCurrency);
	Query.SetParameter("Purpose",                   Attributes.Purpose);
	Query.SetParameter("FillInAssignmentInTabularForm",       Attributes.FillInAssignmentInTabularForm);
	Query.SetParameter("Substitutional",                   Attributes.Substitutional);
	Query.SetParameter("ProductionProcessType", Attributes.ProductionProcessType);
	Query.SetParameter("Periodicity",                Attributes.Periodicity);
	Query.SetParameter("PointInTime",                Attributes.PointInTime);
	Query.SetParameter("CalculationSeparator",           Attributes.CalculationSeparator);
	Query.SetParameter("PlanSemiFinishedProductsAutomatically", Attributes.PlanSemiFinishedProductsAutomatically);
	Query.SetParameter("UseForMaterialsPlanning", Attributes.UseForMaterialsPlanning);
	
	SelectionDetailRecords = QueryResults[1].Select();
	While SelectionDetailRecords.Next() Do
		If Not ValueIsFilled(SelectionDetailRecords.Value) Then
			Continue;
		EndIf;
		Query.SetParameter("AdditionalAttribute"+Format(SelectionDetailRecords.LineNumber, "NG=0"), SelectionDetailRecords.Value);
	EndDo;
	
EndProcedure

Function QueryTextTableProductionPlans(Query, QueryTexts, Registers)
	
	RegisterName = "ProductionPlans";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTManufacturedProduct", QueryTexts) Then
		QueryTextTTManufacturedProduct(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	Table.Period                   AS Period,
	|	&Scenario                        AS Scenario,
	|	&Status                          AS Status,
	|	Table.Products             AS Products,
	|	Table.Characteristic           AS Characteristic,
	|	&Department                   AS Department,
	|	&Ref                          AS ProductionPlan,
	|	Table.BillOfMaterials             AS BillOfMaterials,
	|	Table.Purpose               AS Purpose,
	|	DATETIME(1,1,1)                 AS ProductionIssueDateOfIntermediateProducts,
	|	Table.DateOfOrderReleaseAndProductionIssue       AS DateOfOrderReleaseAndProductionIssue,
	|	FALSE                             AS ThisIsASemiFinishedProduct,
	|	&ProductionProcessType    AS ProductionProcessType,
	|	&PlanProfile                        AS PlanProfile,
	|	Table.Count               AS Count,
	|	Table.ToOrder                  AS ToOrder,
	|	Table.DemandRangeIsSpecified AS DemandRangeIsSpecified,
	|	Table.RangeOfDemandFrom    AS RangeOfDemandFrom,
	|	Table.RangeOfDemandTo    AS RangeOfDemandTo
	|FROM
	|	TTManufacturedProduct AS Table";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableReleasePlans(Query, QueryTexts, Registers)
	
	RegisterName = "ReleasePlansProducts_";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTManufacturedProduct", QueryTexts) Then
		QueryTextTTManufacturedProduct(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	Table.Period                                                 AS Period,
	|	&Scenario                                                      AS Scenario,
	|	&PlanProfile                                                      AS PlanProfile,
	|	&Status                                                        AS Status,
	|	Table.Products                                           AS Products,
	|	Table.Characteristic                                         AS Characteristic,
	|	Table.Purpose                                             AS Purpose,
	|	&Department                                                 AS ProductionDispatcherBusinessUnit,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)         AS AssigneeBusinessUnit,
	|	&Ref                                                        AS ProductionPlan,
	|	Table.BillOfMaterials                                           AS BillOfMaterials,
	|	VALUE(Enum.ReleaseTypesOfProductionPlan.Main) AS TypeOfProductionIssue,
	|	Table.Period                                                 AS ProductionDate,
	|	Table.BillOfMaterials                                           AS ProductBOM,
	|	Table.Purpose                                             AS AssignmentOfProducts,
	|	Table.Products                                           AS ProductsItems,
	|	Table.Characteristic                                         AS ItemVariant,
	|	Table.Count                                             AS Count,
	|	Table.ToOrder                                                AS ToOrder
	|FROM
	|	TTManufacturedProduct AS Table";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTManufacturedProduct(Query, QueryTexts)
	
	RegisterName = "TTManufacturedProduct";
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	CASE
	|		WHEN &ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|				AND Table.StartDate2 <> DATETIME(1, 1, 1)
	|			THEN Table.StartDate2
	|		WHEN &ProductionProcessType IN (VALUE(Enum.ProductionProcessTypes.Assembly), VALUE(Enum.ProductionProcessTypes.Repair))
	|				AND Table.DateOfProduction <> DATETIME(1, 1, 1)
	|			THEN Table.DateOfProduction
	|		ELSE Table.Ref.BeginOfPeriod
	|	END AS Period,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.BillOfMaterials AS BillOfMaterials,
	|	CASE
	|		WHEN CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE Table.Purpose
	|	END AS Purpose,
	|	CASE
	|		WHEN &ProductionProcessType IN (VALUE(Enum.ProductionProcessTypes.Assembly), VALUE(Enum.ProductionProcessTypes.Repair))
	|				AND Table.StartDate2 <> DATETIME(1, 1, 1)
	|			THEN Table.StartDate2
	|		ELSE DATETIME(1, 1, 1)
	|	END AS DateOfOrderReleaseAndProductionIssue,
	|	CASE
	|		WHEN Table.Substituted
	|			THEN 0
	|		ELSE Table.Count
	|	END AS Count,
	|	CASE
	|		WHEN &Status = VALUE(Enum.PlanStatuses.Upholded)
	|			THEN Table.Count
	|		ELSE 0
	|	END AS ToOrder,
	|	CASE
	|		WHEN Table.DemandRangeIsSpecified
	|			THEN 1
	|		ELSE 0
	|	END AS DemandRangeIsSpecified,
	|	Table.RangeOfDemandFrom AS RangeOfDemandFrom,
	|	Table.RangeOfDemandTo AS RangeOfDemandTo
	|INTO TTManufacturedProduct
	|FROM
	|	Document.ProductionPlan.ManufacturedProduct AS Table
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Table.Products = CatalogProducts.Ref
	|WHERE
	|	Table.Ref = &Ref
	|	AND (Table.Count <> 0
	|			OR Table.DemandRangeIsSpecified)
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND NOT Table.Canceled
	|	AND (NOT Table.Substituted
	|				AND &Status <> VALUE(Enum.PlanStatuses.Upholded)
	|			OR NOT Table.SubstitutedToOrder
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|	AND NOT &UseForMaterialsPlanning";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
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
	|	ReplacementProductionPlan.Ref AS ReplacementPlan_3,
	|	CASE
	|		WHEN &SubstitutionPeriodStart > ReplacementProductionPlan.SubstitutionPeriodStart
	|			THEN &SubstitutionPeriodStart
	|		ELSE ReplacementProductionPlan.SubstitutionPeriodStart
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < ReplacementProductionPlan.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE ReplacementProductionPlan.PeriodEnding
	|	END AS PeriodEnding,
	|	ReplacementProductionPlan.Status AS Status
	|FROM
	|	Document.ProductionPlan AS ReplacementProductionPlan
	|WHERE
	|	ReplacementProductionPlan.PeriodEnding >= &SubstitutionPeriodStart
	|	AND ReplacementProductionPlan.SubstitutionPeriodStart <= &PeriodEnding
	|	AND ReplacementProductionPlan.Ref <> &Ref
	|	AND ReplacementProductionPlan.Posted
	|	AND ReplacementProductionPlan.PlanProfile = &PlanProfile
	|	AND (ReplacementProductionPlan.Status.Order >= &StatusIndex
	|			OR ReplacementProductionPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND ReplacementProductionPlan.Date > &Date
	|	AND ReplacementProductionPlan.Department = &Department
	|	AND ReplacementProductionPlan.Purpose = &Purpose
	|
	|ORDER BY
	|	SubstitutionPeriodStart,
	|	Status
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionPlanSubstituted.Ref AS SubstitutedPlan,
	|	CASE
	|		WHEN &SubstitutionPeriodStart > ProductionPlanSubstituted.SubstitutionPeriodStart
	|			THEN &SubstitutionPeriodStart
	|		ELSE ProductionPlanSubstituted.SubstitutionPeriodStart
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < ProductionPlanSubstituted.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE ProductionPlanSubstituted.PeriodEnding
	|	END AS PeriodEnding,
	|	ProductionPlanSubstituted.Status AS Status
	|FROM
	|	Document.ProductionPlan AS ProductionPlanSubstituted
	|WHERE
	|	ProductionPlanSubstituted.PeriodEnding >= &SubstitutionPeriodStart
	|	AND ProductionPlanSubstituted.SubstitutionPeriodStart <= &PeriodEnding
	|	AND ProductionPlanSubstituted.Ref <> &Ref
	|	AND ProductionPlanSubstituted.Posted
	|	AND ProductionPlanSubstituted.PlanProfile = &PlanProfile
	|	AND (ProductionPlanSubstituted.Status.Order <= &StatusIndex
	|			OR ProductionPlanSubstituted.Status = VALUE(Enum.PlanStatuses.Upholded)
	|				AND &Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation))
	|	AND ProductionPlanSubstituted.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND ProductionPlanSubstituted.Date < &Date
	|	AND ProductionPlanSubstituted.Department = &Department
	|	AND ProductionPlanSubstituted.Purpose = &Purpose
	|
	|ORDER BY
	|	SubstitutionPeriodStart,
	|	Status";
	
	Query.SetParameter("Ref", Parameters.Ref);
	Query.SetParameter("PlanProfile", Parameters.PlanProfile);
	Query.SetParameter("StatusIndex", Enums.PlanStatuses.IndexOf(Parameters.Status));
	Query.SetParameter("Status", Parameters.Status);
	Query.SetParameter("Date", Parameters.Date);
	Query.SetParameter("Department", Parameters.Department);
	Query.SetParameter("Purpose", Parameters.Purpose);
	Query.SetParameter("SubstitutionPeriodStart", Parameters.SubstitutionPeriodStart);
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
	|	ProductionPlansTurnovers.Period AS CompositionPeriod,
	|	ProductionPlansTurnovers.Scenario AS Scenario,
	|	ProductionPlansTurnovers.Status AS Status,
	|	ProductionPlansTurnovers.Products AS Products,
	|	ProductionPlansTurnovers.Characteristic AS Characteristic,
	|	ProductionPlansTurnovers.Purpose AS Purpose,
	|	ProductionPlansTurnovers.Department AS Department,
	|	ProductionPlansTurnovers.ThisIsASemiFinishedProduct AS SemiFinishedProduct,
	|	ProductionPlansTurnovers.CountTurnover AS NumberOfPackages
	|FROM
	|	AccumulationRegister.ProductionPlans.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Record,
	|			Scenario = &Scenario
	|				AND PlanProfile = &PlanProfile
	|				AND (&FillInAssignmentInTabularForm
	|					OR Purpose = &Purpose)
	|				AND Status IN (&Statuses)
	|				AND NOT ToPlan
	|				AND &QueryTextFilterDepartment) AS ProductionPlansTurnovers
	|ORDER BY
	|	SemiFinishedProduct";
	
	Query.SetParameter("EndOfPeriod",           Parameters.OffsetPeriodEnd);
	Query.SetParameter("BeginOfPeriod",          Parameters.OffsetPeriodStart);
	Query.SetParameter("Department",          Parameters.Department);
	Query.SetParameter("Statuses",                Parameters.Statuses);
	Query.SetParameter("Scenario",               Parameters.Scenario);
	Query.SetParameter("PlanProfile",               Parameters.PlanProfile);
	Query.SetParameter("FillInAssignmentInTabularForm", Parameters.FillInAssignmentInTabularForm);
	Query.SetParameter("Purpose",             Parameters.Purpose);
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterDepartment",
		?(ValueIsFilled(Parameters.Department),"Department = &Department","True"));
		
	Return Query;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Production plan
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ProductionPlan";
	PrintCommand.Presentation = NStr("vi = 'Kế hoạch sản xuất';
									|ru = 'План производства';
									|en = 'Production plan'; fa = 'برنامه تولید';
									|it = 'Piano di produzione';
									|pl = 'Plan produkcji';
									|tr = 'Üretim planı'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ProductionPlanWithSemiFinishedProducts";
	PrintCommand.Presentation = NStr("vi = 'Kế hoạch sản xuất (với bán thành phẩm)';
									|ru = 'План производства (с полуфабрикатами)';
									|en = 'Production plan (with semi-finished products)'; fa = 'Production plan (with semi-finished products)';
									|it = 'План производства (с полуфабрикатами)';
									|pl = 'Production plan (with semi-finished products)';
									|tr = 'Üretim planı (yarı mamul ürünlerle)'");
	PrintCommand.CheckPostingBeforePrint = True;
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
		"ProductionProcessType",
		Enums.ProductionProcessTypes.PerformRM,
		DataCompositionComparisonType.NotEqual);
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ProductionPlan") Then
		If PrintParameters = Undefined Then
			PrintParameters = New Structure;
		EndIf;
		PrintParameters.Insert("IncludeSemiFinishedProducts", False);
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ProductionPlan",
			NStr("vi = 'Kế hoạch sản xuất';
				|ru = 'План производства';
				|en = 'Production plan'; fa = 'برنامه تولید';
				|it = 'Piano di produzione';
				|pl = 'Plan produkcji';
				|tr = 'Üretim planı'"),
			CreatePrintedFormOfPlan(ObjectsArray, PrintObjects, PrintParameters));
	ElsIf PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ProductionPlanWithSemiFinishedProducts") Then
		If PrintParameters = Undefined Then
			PrintParameters = New Structure;
		EndIf;
		PrintParameters.Insert("IncludeSemiFinishedProducts", True);
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ProductionPlanWithSemiFinishedProducts",
			NStr("vi = 'Kế hoạch sản xuất';
				|ru = 'План производства';
				|en = 'Production plan'; fa = 'برنامه تولید';
				|it = 'Piano di produzione';
				|pl = 'Plan produkcji';
				|tr = 'Üretim planı'"),
			CreatePrintedFormOfPlan(ObjectsArray, PrintObjects, PrintParameters));
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function CreatePrintedFormOfPlan(ObjectsArray, PrintObjects, PrintParameters)
	
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
	OutputDivision	= True;
	IncludeSemiFinishedProducts	= True;
	
	If PrintParameters <> Undefined And Not PrintParameters.Property("OutputScript", OutputScript) Then
		OutputScript 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("DisplayPeriodStatus", DisplayPeriodStatus) Then
		DisplayPeriodStatus 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("OutputDivision", OutputDivision) Then
		OutputDivision 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("IncludeSemiFinishedProducts", IncludeSemiFinishedProducts) Then
		IncludeSemiFinishedProducts 	= True;
	EndIf;
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
		
	Query = New Query(
		"SELECT
		|	DocumentTable.Ref AS Ref,
		|	DocumentTable.Number AS Number,
		|	DocumentTable.Date AS Date,
		|	DocumentTable.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentTable.Status AS Status,
		|	DocumentTable.Periodicity AS Periodicity,
		|	MIN(CASE
		|		WHEN &IncludeSemiFinishedProducts AND (&DefaultCrossTable OR DocumentTable.CrossTable) 
		|			AND ISNULL(ProductionPlans.ProductionIssueDateOfIntermediateProducts, DocumentTable.BeginOfPeriod) < DocumentTable.BeginOfPeriod
		|			THEN ProductionPlans.ProductionIssueDateOfIntermediateProducts
		|		ELSE DocumentTable.BeginOfPeriod
		|	END) AS BeginOfPeriod,
		|	DocumentTable.PeriodEnding AS PeriodEnding,
		|	DocumentTable.Scenario AS Scenario,
		|	DocumentTable.PlanProfile AS PlanProfile,
		|	CASE
		|		WHEN &DefaultCrossTable
		|				OR DocumentTable.CrossTable
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS CrossTable,
		|	DocumentTable.FilledAutomatically AS FilledAutomatically,
		|	DocumentTable.Department AS Department,
		|	DocumentTable.Purpose AS Purpose,
		|	DocumentTable.ProductionProcessType AS ProductionProcessType,
		|	CatPlanProfiles.FillInBusinessUnit AS FillInBusinessUnit,
		|	PlanningScenarios.UseForMaterialsPlanning AS FillInWHSpecification,
		|	PlanningScenarios.ShowNumberOfPeriod AS ShowNumberOfPeriod,
		|	Users.Individual AS ResponsibleIndividual,
		|	PlanningScenarios.PlanningByAssignments AS PlanningByAssignments,
		|	CatPlanProfiles.PlanSemiFinishedProductsAutomatically AS PlanSemiFinishedProductsAutomatically,
		|	CatPlanProfiles.FillInAssignmentInTabularForm AS FillInAssignmentInTabularForm
		|FROM
		|	Document.ProductionPlan AS DocumentTable
		|		LEFT JOIN Catalog.SalesOperationsPlanningScenarios AS PlanningScenarios
		|		ON DocumentTable.Scenario = PlanningScenarios.Ref
		|		LEFT JOIN Catalog.PlanProfiles AS CatPlanProfiles
		|		ON DocumentTable.PlanProfile = CatPlanProfiles.Ref
		|		LEFT JOIN Catalog.Users AS Users
		|		ON DocumentTable.EmployeeResponsible = Users.Ref
		|		{LEFT JOIN AccumulationRegister.ProductionPlans AS ProductionPlans
		|		ON &IncludeSemiFinishedProducts
		|		AND DocumentTable.Ref = ProductionPlans.ProductionPlan
		|		AND (&DefaultCrossTable OR DocumentTable.CrossTable)
		|		AND CatPlanProfiles.PlanSemiFinishedProductsAutomatically
		|		AND ProductionPlans.ThisIsASemiFinishedProduct}
		|WHERE
		|	DocumentTable.Ref IN(&DocumentsArray)
		|
		|GROUP BY
		|	DocumentTable.Ref,
		|	DocumentTable.Number,
		|	DocumentTable.Date,
		|	DocumentTable.EmployeeResponsible,
		|	DocumentTable.Status,
		|	DocumentTable.Periodicity,
		|	DocumentTable.BeginOfPeriod,
		|	DocumentTable.Scenario,
		|	DocumentTable.PlanProfile,
		|	DocumentTable.FilledAutomatically,
		|	DocumentTable.Department,
		|	DocumentTable.Purpose,
		|	DocumentTable.ProductionProcessType,
		|	CatPlanProfiles.FillInBusinessUnit,
		|	PlanningScenarios.UseForMaterialsPlanning,
		|	PlanningScenarios.ShowNumberOfPeriod,
		|	Users.Individual,
		|	PlanningScenarios.PlanningByAssignments,
		|	CatPlanProfiles.PlanSemiFinishedProductsAutomatically,
		|	CatPlanProfiles.FillInAssignmentInTabularForm
		|ORDER BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsTable.Ref AS Ref,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Products.DescriptionFull AS ProductNameFull_,
		|	GoodsTable.Products.Code AS Code,
		|	GoodsTable.Products.SKU AS SKU,
		|	CASE
		|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN GoodsTable.Products.UnitOfMeasure
		|		ELSE GoodsTable.Package
		|	END AS UnitOfMeasure,
		|	GoodsTable.Characteristic.DescriptionFull AS CharacteristicFullName,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Package AS Package,
		|	GoodsTable.LineNumber AS LineNumber,
		|	GoodsTable.SemiFinishedProduct AS SemiFinishedProduct,
		|	CASE
		|		WHEN GoodsTable.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
		|			THEN GoodsTable.StartDate2
		|		ELSE GoodsTable.DateOfProduction
		|	END AS PeriodDate_,
		|	GoodsTable.NumberOfPackages AS Count,
		|	GoodsTable.Comment AS Comment,
		|	GoodsTable.BillOfMaterials AS BillOfMaterials,
		|	GoodsTable.Purpose.Description AS PurposeName,
		|	GoodsTable.Purpose AS Purpose
		|FROM
		|	Document.ProductionPlan.ManufacturedProduct AS GoodsTable
		|WHERE
		|	(&DefaultTable
		|			OR NOT GoodsTable.Ref.CrossTable)
		|	AND (&IncludeSemiFinishedProducts OR GoodsTable.SemiFinishedProduct = FALSE)
		|	AND GoodsTable.Ref IN(&DocumentsArray)
		|	AND NOT GoodsTable.Canceled
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
		|	NestedQuery.SemiFinishedProduct,
		|	NestedQuery.PeriodDate_,
		|	SUM(NestedQuery.NumberOfPackages),
		|	MAX(NestedQuery.Comment),
		|	NestedQuery.BillOfMaterials,
		|	NestedQuery.Purpose.Description,
		|	NestedQuery.Purpose
		|FROM
		|	(SELECT
		|		GoodsTable.Ref AS Ref,
		|		GoodsTable.Products AS Products,
		|		GoodsTable.Characteristic AS Characteristic,
		|		GoodsTable.Package AS Package,
		|		CASE
		|			WHEN GoodsTable.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
		|				THEN CASE DocumentTable.Periodicity
		|						WHEN VALUE(Enum.Periodicity.YEAR)
		|							THEN BEGINOFPERIOD(GoodsTable.StartDate2, YEAR)
		|						WHEN VALUE(Enum.Periodicity.HALFYEAR)
		|							THEN BEGINOFPERIOD(GoodsTable.StartDate2, HALFYEAR)
		|						WHEN VALUE(Enum.Periodicity.QUARTER)
		|							THEN BEGINOFPERIOD(GoodsTable.StartDate2, QUARTER)
		|						WHEN VALUE(Enum.Periodicity.MONTH)
		|							THEN BEGINOFPERIOD(GoodsTable.StartDate2, MONTH)
		|						WHEN VALUE(Enum.Periodicity.TENDAYS)
		|							THEN BEGINOFPERIOD(GoodsTable.StartDate2, TENDAYS)
		|						WHEN VALUE(Enum.Periodicity.WEEK)
		|							THEN BEGINOFPERIOD(GoodsTable.StartDate2, WEEK)
		|						ELSE GoodsTable.StartDate2
		|					END
		|			ELSE CASE DocumentTable.Periodicity
		|					WHEN VALUE(Enum.Periodicity.YEAR)
		|						THEN BEGINOFPERIOD(GoodsTable.DateOfProduction, YEAR)
		|					WHEN VALUE(Enum.Periodicity.HALFYEAR)
		|						THEN BEGINOFPERIOD(GoodsTable.DateOfProduction, HALFYEAR)
		|					WHEN VALUE(Enum.Periodicity.QUARTER)
		|						THEN BEGINOFPERIOD(GoodsTable.DateOfProduction, QUARTER)
		|					WHEN VALUE(Enum.Periodicity.MONTH)
		|						THEN BEGINOFPERIOD(GoodsTable.DateOfProduction, MONTH)
		|					WHEN VALUE(Enum.Periodicity.TENDAYS)
		|						THEN BEGINOFPERIOD(GoodsTable.DateOfProduction, TENDAYS)
		|					WHEN VALUE(Enum.Periodicity.WEEK)
		|						THEN BEGINOFPERIOD(GoodsTable.DateOfProduction, WEEK)
		|					ELSE GoodsTable.DateOfProduction
		|				END
		|		END AS PeriodDate_,
		|		GoodsTable.LineNumber AS LineNumber,
		|		GoodsTable.SemiFinishedProduct AS SemiFinishedProduct,
		|		CASE
		|			WHEN GoodsTable.Canceled
		|				THEN 0
		|			ELSE GoodsTable.NumberOfPackages
		|		END AS NumberOfPackages,
		|		CASE
		|			WHEN GoodsTable.Canceled
		|				THEN """"
		|			ELSE CAST(GoodsTable.Comment AS STRING(1000))
		|		END AS Comment,
		|		GoodsTable.BillOfMaterials AS BillOfMaterials,
		|		GoodsTable.Purpose AS Purpose
		|	FROM
		|		Document.ProductionPlan.ManufacturedProduct AS GoodsTable
		|			INNER JOIN Document.ProductionPlan AS DocumentTable
		|			ON GoodsTable.Ref = DocumentTable.Ref
		|	WHERE
		|		(&DefaultCrossTable
		|				OR GoodsTable.Ref.CrossTable)
		|		AND (&IncludeSemiFinishedProducts OR GoodsTable.SemiFinishedProduct = FALSE)
		|		AND GoodsTable.Ref IN(&DocumentsArray)) AS NestedQuery
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
		|	NestedQuery.SemiFinishedProduct,
		|	NestedQuery.PeriodDate_,
		|	CASE
		|		WHEN NestedQuery.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN NestedQuery.Products.UnitOfMeasure
		|		ELSE NestedQuery.Package
		|	END,
		|	NestedQuery.Package,
		|	NestedQuery.BillOfMaterials
		|
		|UNION ALL
		|
		|SELECT
		|	NestedQuery.ProductionPlan,
		|	NestedQuery.Products,
		|	NestedQuery.Products.DescriptionFull,
		|	NestedQuery.Products.Code,
		|	NestedQuery.Products.SKU,
		|	NestedQuery.Products.UnitOfMeasure,
		|	NestedQuery.Characteristic.DescriptionFull,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Products.UnitOfMeasure,
		|	MIN(NestedQuery.LineNumber),
		|	NestedQuery.ThisIsASemiFinishedProduct,
		|	NestedQuery.Period,
		|	SUM(NestedQuery.Count),
		|	MAX(NestedQuery.Comment),
		|	NestedQuery.BillOfMaterials,
		|	NestedQuery.Purpose.Description,
		|	NestedQuery.Purpose
		|FROM
		|	(SELECT
		|		ProductionPlans.ProductionPlan AS ProductionPlan,
		|		ProductionPlans.Products     AS Products,
		|		ProductionPlans.Characteristic   AS Characteristic,
		|		ProductionPlans.Purpose       AS Purpose,
		|		ProductionPlans.BillOfMaterials     AS BillOfMaterials,
		|
		|		CASE DocumentTable.Periodicity
		|			WHEN VALUE(Enum.Periodicity.YEAR)
		|				THEN BEGINOFPERIOD(ProductionPlans.ProductionIssueDateOfIntermediateProducts, YEAR)
		|			WHEN VALUE(Enum.Periodicity.HALFYEAR)
		|				THEN BEGINOFPERIOD(ProductionPlans.ProductionIssueDateOfIntermediateProducts, HALFYEAR)
		|			WHEN VALUE(Enum.Periodicity.QUARTER)
		|				THEN BEGINOFPERIOD(ProductionPlans.ProductionIssueDateOfIntermediateProducts, QUARTER)
		|			WHEN VALUE(Enum.Periodicity.MONTH)
		|				THEN BEGINOFPERIOD(ProductionPlans.ProductionIssueDateOfIntermediateProducts, MONTH)
		|			WHEN VALUE(Enum.Periodicity.TENDAYS)
		|				THEN BEGINOFPERIOD(ProductionPlans.ProductionIssueDateOfIntermediateProducts, TENDAYS)
		|			WHEN VALUE(Enum.Periodicity.WEEK)
		|				THEN BEGINOFPERIOD(ProductionPlans.ProductionIssueDateOfIntermediateProducts, WEEK)
		|			ELSE ProductionPlans.ProductionIssueDateOfIntermediateProducts
		|		END AS Period,
		|
		|		1 AS LineNumber,
		|		ProductionPlans.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|		ProductionPlans.Count  AS Count,
		|		ProductionPlans.Comment AS Comment
		|	FROM
		|		AccumulationRegister.ProductionPlans AS ProductionPlans
		|		INNER JOIN Document.ProductionPlan AS DocumentTable
		|			ON ProductionPlans.ProductionPlan = DocumentTable.Ref
		|	WHERE
		|		&IncludeSemiFinishedProducts
		|		AND DocumentTable.Ref IN (&DocumentsArray)
		|		AND ProductionPlans.PlanProfile.PlanSemiFinishedProductsAutomatically
		|		AND ProductionPlans.ThisIsASemiFinishedProduct) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.ProductionPlan,
		|	NestedQuery.Products,
		|	NestedQuery.Products.DescriptionFull,
		|	NestedQuery.Products.Code,
		|	NestedQuery.Products.SKU,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Characteristic.DescriptionFull,
		|	NestedQuery.Purpose,
		|	NestedQuery.Purpose.Description,
		|	NestedQuery.Period,
		|	NestedQuery.Products.UnitOfMeasure,
		|	NestedQuery.ThisIsASemiFinishedProduct,
		|	NestedQuery.BillOfMaterials
		|
		|ORDER BY
		|	Ref,
		|	SemiFinishedProduct,
		|	LineNumber,
		|	ProductNameFull_,
		|	CharacteristicFullName,
		|	BillOfMaterials,
		|	PurposeName,
		|	UnitOfMeasure,
		|	PeriodDate_
		|TOTALS BY
		|	Ref");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ProductionPlan_ProductionPlan";
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	Query.SetParameter("DefaultCrossTable", DefaultCrossTable);
	Query.SetParameter("DefaultTable", DefaultTable);
	Query.SetParameter("IncludeSemiFinishedProducts", IncludeSemiFinishedProducts);
	
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
		Template = PrintManagement.PrintFormTemplate("Document.ProductionPlan.PF_MXL_ProductionPlan");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the plan
		If DisplayHeader Then
			
			TemplateArea = Template.GetArea("Title");
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
			
			TitleText = TMCommonUseClientServer.GenerateDocumentTitle(
				PrintData,
				NStr("vi = 'Kế hoạch sản xuất';
					|ru = 'План производства';
					|en = 'Production plan'; fa = 'برنامه تولید';
					|it = 'Piano di produzione';
					|pl = 'Plan produkcji';
					|tr = 'Üretim planı'", Common.DefaultLanguageCode()));
			
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
			
			If PrintData.FillInBusinessUnit And OutputDivision Then
				TemplateArea                                       = Template.GetArea("Department");
				DivisionRepresentation                          = String(PrintData.Department);
				TemplateArea.Parameters.DivisionRepresentation  = DivisionRepresentation;
				TemplateArea.Parameters.Department               = PrintData.Department;
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
			StructureOfAdditionalField.Insert("Title", NStr("vi = 'Mục đích';
															|ru = 'Назначение';
															|en = 'Assignment'; fa = 'تخصیص';
															|it = 'Destinazione';
															|pl = 'Przeznaczenie';
															|tr = 'Atama'", Common.DefaultLanguageCode()));
			StructureOfAdditionalField.Insert("ValueColumn_", "Purpose");
			Add_Fields.Add(StructureOfAdditionalField);
		EndIf;
		
		// Output the title of the Products table
		If PrintData.FillInWHSpecification Then
			StructureOfAdditionalField = New Structure;
			StructureOfAdditionalField.Insert("Title", NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
															|ru = 'Спецификация';
															|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
															|it = 'Specifica';
															|pl = 'Specafikacja';
															|tr = 'Ürün reçetesi'", Common.DefaultLanguageCode()));
			StructureOfAdditionalField.Insert("ValueColumn_", "BillOfMaterials");
			Add_Fields.Add(StructureOfAdditionalField);
		EndIf;
		
		Count = ?(CrossTable, "NumberOfCrosses","Count");
		
		OwnGoods = ?(Not (DisplayHeader Or UseItemVariants),"ProductWithoutCharacteristics", "OwnGoods");
		
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
		ProductArea                    = Template.GetArea(?(DisplayHeader,"TableHeader","HeaderOfNHTable") + "|" + OwnGoods);
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
			If PrintData.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
				AreaDatePeriod.Parameters.Title = NStr("vi = 'Ngày vận hành';
														|ru = 'Дата запуска';
														|en = 'Launch date'; fa = 'تاریخ شروع';
														|it = 'Data di avvio';
														|pl = 'Data uruchomienia';
														|tr = 'Başlangıç tarihi'", Common.DefaultLanguageCode());
			Else
				AreaDatePeriod.Parameters.Title = NStr("vi = 'Ngày xuất xưởng';
														|ru = 'Дата выпуска';
														|en = 'Release date'; fa = 'تاریخ انتشار';
														|it = 'Data di produzione';
														|pl = 'Data wydania';
														|tr = 'Çıkış tarihi'", Common.DefaultLanguageCode());
			EndIf;
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
		
		CurrentRow  = New Structure("Products, Characteristic, BillOfMaterials, Purpose, UnitOfMeasure");
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
					UIArea.Parameters.UniqueIdentifierSpecification          = String(ProductSelection_1.BillOfMaterials.UUID());
					UIArea.Parameters.UniqueIdentifierPurpose            = String(ProductSelection_1.Purpose.UUID());
					
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
				For MainIndex = CurrentPeriod To PeriodsTable.Count()-1 Do
					If MainIndex>IndexOf Then
						Continue;
					Else
						CurrentPeriod = CurrentPeriod + 1;
					EndIf;
					If IndexOf < PeriodsTable.Count()-1 Then
						If IndexOf = MainIndex Then
							DataArea.Parameters.Fill(ProductSelection_1);
							Area = DataArea.Area("R1C1:R1C1");
							Area.Comment.Text = ProductSelection_1.Comment;
							SpreadsheetDocument.Join(DataArea);
						ElsIf //The legs are not the same
							 MainIndex<IndexOf Then
							Area = DataArea.Area("R1C1:R1C1");
							DataArea.Parameters.Count = 0;
							SpreadsheetDocument.Join(DataArea);
						EndIf;
					Else
						If IndexOf = MainIndex Then
							DataAreaCrossEnd.Parameters.Fill(ProductSelection_1);
							Area = DataAreaCrossEnd.Area("R1C1:R1C1");
							Area.Comment.Text = ProductSelection_1.Comment;
							SpreadsheetDocument.Join(DataAreaCrossEnd);
						ElsIf //The legs are not the same
							 MainIndex<IndexOf Then
							Area = DataArea.Area("R1C1:R1C1");
							DataArea.Parameters.Count = 0;
							SpreadsheetDocument.Join(DataArea);
						EndIf;
					EndIf;
					
				EndDo;
				
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
			TotalString = NStr("vi = 'Tổng số mục %NumberOfTitles%.';
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
	
	FormName = "Document.ProductionPlan.Form.ListForm";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.ProductionPlan))
		And AccessRight("Insert", Metadata.Documents.ProductionPlan)
		And GetFunctionalOption("UseProductionPlanning");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
		Query.Text = 
	"SELECT ALLOWED
	|	COUNT(*) AS ProductionPlansAwaitingApproval,
	|	MIN(Plans.Status.Order) AS StatusOrder
	|FROM
	|	Document.ProductionPlan AS Plans
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
	UserTaskParent = ToDoList.Find("PurchasePlans", "Id");
	If UserTaskParent = Undefined Then
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id  = "PurchasePlans";
		UserTaskParent.Presentation  = NStr("vi = 'Kế hoạch thống nhất dự tính';
											|ru = 'Планы ожидающие согласования';
											|en = 'Plans pending approval'; fa = 'Plans pending approval';
											|it = 'Piani in attesa di approvazione';
											|pl = 'Plany oczekujące na zatwierdzenie';
											|tr = 'Beklenen uyum planı'");
		UserTaskParent.Owner       = Metadata.Subsystems.BudgetingAndPlanning;
	EndIf;
	
	// ProductionPlansAwaitingApproval
	FilterParameters = New Structure;
	If Enums.PlanStatuses[Result.StatusOrder] = Enums.PlanStatuses.AwaitingConfirmation Then
		FilterParameters.Insert("Status", Enums.PlanStatuses.AwaitingConfirmation);
	EndIf;
	FilterParameters.Insert("DeletionMark", False);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "ProductionPlansAwaitingApproval";
	ToDoItem.HasToDoItems       = Result.ProductionPlansAwaitingApproval > 0;
	ToDoItem.Presentation  = NStr("vi = 'Kế hoạch sản xuất';
									|ru = 'Планы производства';
									|en = 'Production plans'; fa = 'برنامه‌های تولید';
									|it = 'Piani di produzione';
									|pl = 'Plany produkcji';
									|tr = 'Üretim planları'");
	ToDoItem.Count     = Result.ProductionPlansAwaitingApproval;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "PurchasePlans";
	
	If Result.ProductionPlansAwaitingApproval > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region StatesOfProductionPlanCalculation

// Returns the status of the production plan calculation (material requirements, labor costs, and RPC).
//
// Parameters:
//  ReferencesArrray - Array	 - production plan.
// 
// Returns:
//  Map - where the key is a reference to the production plan, the value (number)
//  is the calculation State code (See ProductionPlanCalculationStatusCodes)
//                 .
//
Function StatesOfProductionPlanCalculation(ReferencesArrray) Export
	
	CalculationIsRunning = InformationRegisters.QueueOfProductionPlanCalculation.QueueProcessingIsInProgress();
	
	Query = New Query(
	"SELECT
	|	CalculationQueue.ProductionPlan AS ProductionPlan,
	|	CalculationQueue.HasErrors AS HasErrors
	|INTO CalculationQueue
	|FROM
	|	(SELECT
	|		CalculationQueue.ProductionPlan AS ProductionPlan,
	|		MAX(CalculationQueue.HasErrors) AS HasErrors
	|	FROM
	|		InformationRegister.QueueOfProductionPlanCalculation AS CalculationQueue
	|	WHERE
	|		CalculationQueue.State = VALUE(Enum.StatesOfProductionPlanCalculation.CalculationIsRequired)
	|		AND CalculationQueue.ProductionPlan IN(&ReferencesArrray)
	|	
	|	GROUP BY
	|		CalculationQueue.ProductionPlan) AS CalculationQueue
	|;
	|SELECT
	|	Table.Ref AS Ref,
	|
	|	CASE
	|		WHEN Table.Scenario.UseForMaterialsPlanning
	|			THEN CASE
	|					WHEN &CalculationIsRunning
	|							AND TRUE IN (
	|								SELECT TOP 1
	|									TRUE
	|								FROM
	|									InformationRegister.QueueOfProductionPlanCalculation AS ActiveTasks
	|								WHERE
	|									ActiveTasks.ProductionPlan = Table.Ref
	|									AND ActiveTasks.State = VALUE(Enum.StatesOfProductionPlanCalculation.Calculating)
	|							)
	|						THEN CASE
	|								WHEN Table.Posted
	|								THEN &Calculating
	|								ELSE &IsCancelled
	|							END
	|					WHEN CalculationQueue.ProductionPlan IS NOT NULL
	|						THEN CASE
	|								WHEN NOT CalculationQueue.HasErrors
	|								THEN &AwaitingCalculation
	|								ELSE &NotCalculatedHasErrors
	|							END
	|					ELSE
	|						CASE
	|							WHEN Table.Posted
	|							THEN &Calculated
	|							ELSE &NotCalculated
	|						END
	|				END
	|		ELSE &NotCalculated
	|	END AS Code
	|
	|FROM
	|	Document.ProductionPlan AS Table
	|
	|		LEFT JOIN CalculationQueue AS CalculationQueue
	|		ON Table.Ref = CalculationQueue.ProductionPlan
	|
	|WHERE
	|	Table.Ref IN(&ReferencesArrray)");
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Query.SetParameter("CalculationIsRunning", CalculationIsRunning);
	
	StateCodes = ProductionPlanCalculationStatusCodes();
	
	Query.SetParameter("NotCalculated",           StateCodes.NotCalculated);
	Query.SetParameter("Calculated",             StateCodes.Calculated);
	Query.SetParameter("AwaitingCalculation",        StateCodes.AwaitingCalculation);
	Query.SetParameter("Calculating",        StateCodes.Calculating);
	Query.SetParameter("IsCancelled",            StateCodes.IsCancelled);
	Query.SetParameter("NotCalculatedHasErrors", StateCodes.NotCalculatedHasErrors);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	AwaitingCalculation = False;
	Result = New Map;
	
	While Selection.Next() Do
		AwaitingCalculation = AwaitingCalculation Or Selection.Code = StateCodes.AwaitingCalculation;
		Result.Insert(Selection.Ref, New Structure("Code", Selection.Code));
	EndDo;
	
	If AwaitingCalculation
		And Not CalculationIsRunning Then
		InformationRegisters.QueueOfProductionPlanCalculation.RunJob();
	EndIf;
	
	Return Result;
	
EndFunction

// Returns status codes for calculating the production plan (production plans ' need for materials, labor, and VRC).
// 
// Returns:
//  FixedStructure - status codes.
//
Function ProductionPlanCalculationStatusCodes() Export
	
	States1 = New Structure();
	
	States1.Insert("NotCalculated",           0);
	States1.Insert("Calculated",             1);
	States1.Insert("AwaitingCalculation",        2);
	States1.Insert("Calculating",        3);
	States1.Insert("IsCancelled",            4);
	States1.Insert("NotCalculatedHasErrors", 5);
	
	Return New FixedStructure(States1);
	
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

#Region Other

Function GetDateBySchedule(Val DateFrom, Val DaysCount, ScheduleParameters) Export
	
	DateFrom = BegOfDay(DateFrom);
	
	If DaysCount = 0 Then
		Return DateFrom;
	EndIf;
	
	If ScheduleParameters = Undefined Then
		ScheduleParameters = New Structure;
	EndIf; 
	
	If Not ScheduleParameters.Property("Calendar") Or Not ValueIsFilled(ScheduleParameters.Calendar) Then
		ScheduleParameters.Insert("Calendar", Constants.MainEnterpriseCalendar.Get());
	EndIf;
	
	If Not ScheduleParameters.Property("CalendarSchedule") Then
		ScheduleParameters.Insert("CalendarSchedule", New Map);
		ScheduleParameters.Insert("Workdays", New Map);
		ScheduleParameters.Insert("DaysInSchedule", New Map);
	EndIf;
	
	YearOfSchedule = Year(DateFrom);
	
	If ScheduleParameters.CalendarSchedule.Get(YearOfSchedule) = Undefined Then
		
		GetChartDataForYear(ScheduleParameters, YearOfSchedule);
		
	EndIf; 
	
	CalendarScheduleYearOfSchedule = ScheduleParameters.CalendarSchedule.Get(YearOfSchedule);// Map
	CurBusinessDay = CalendarScheduleYearOfSchedule.Get(DateFrom);
	
	If CurBusinessDay = Undefined Then
		// There is no schedule - we count on calendar days
		Return DateFrom + DaysCount * 86400;
	
	EndIf; 
	
	If DaysCount > 0 Then
	
		DaysCountInSchedule = ScheduleParameters.DaysInSchedule.Get(YearOfSchedule);
		If DaysCountInSchedule = Undefined
			Or DaysCountInSchedule = 0 Then
			// There is no schedule - we count on calendar days
			Return DateFrom + DaysCount * 86400;
			
		ElsIf DaysCountInSchedule > CurBusinessDay + DaysCount Then
			
			WorkingDaysYearOfSchedule = ScheduleParameters.Workdays.Get(YearOfSchedule);// Map
			Return WorkingDaysYearOfSchedule.Get(CurBusinessDay + DaysCount);
		
		EndIf; 
		DaysLeft = DaysCount - DaysCountInSchedule + CurBusinessDay;
		While YearOfSchedule >= 0 Do
			
			YearOfSchedule = YearOfSchedule +1;
			If ScheduleParameters.CalendarSchedule.Get(YearOfSchedule) = Undefined Then
				
				GetChartDataForYear(ScheduleParameters, YearOfSchedule);
				
			EndIf; 
			
			DaysCountInSchedule = ScheduleParameters.DaysInSchedule.Get(YearOfSchedule);
			If DaysCountInSchedule = Undefined
				Or DaysCountInSchedule = 0 Then
				// There is no schedule - we count on calendar days
				Return DateFrom + DaysCount * 86400;
				
			ElsIf DaysCountInSchedule >= DaysLeft Then
				
				WorkingDaysYearOfSchedule = ScheduleParameters.Workdays.Get(YearOfSchedule);// Map
				Return WorkingDaysYearOfSchedule.Get(DaysCountInSchedule - DaysLeft);
				
			Else
				
				DaysLeft = DaysLeft - DaysCountInSchedule;
				
			EndIf; 
			
		EndDo;
	Else
		
		DaysCount = -DaysCount;
		If CurBusinessDay > DaysCount Then
		
			WorkingDaysYearOfSchedule = ScheduleParameters.Workdays.Get(YearOfSchedule);// Map
			Return WorkingDaysYearOfSchedule.Get(CurBusinessDay - DaysCount);
		
		EndIf;
		
		DaysLeft = DaysCount - CurBusinessDay;
		While YearOfSchedule >= 0 Do
			
			YearOfSchedule = YearOfSchedule -1;
			If ScheduleParameters.CalendarSchedule.Get(YearOfSchedule) = Undefined Then
				
				GetChartDataForYear(ScheduleParameters, YearOfSchedule);
				
			EndIf; 
			
			DaysCountInSchedule = ScheduleParameters.DaysInSchedule.Get(YearOfSchedule);
			If DaysCountInSchedule = Undefined Then
				// There is no schedule - we count on calendar days
				Return DateFrom - DaysCount * 86400;
				
			ElsIf DaysCountInSchedule > DaysLeft Then
				
				WorkingDaysYearOfSchedule = ScheduleParameters.Workdays.Get(YearOfSchedule);// Map
				Return WorkingDaysYearOfSchedule.Get(DaysCountInSchedule - DaysLeft);
				
			Else
				
				DaysLeft = DaysLeft - DaysCountInSchedule;
				
			EndIf; 
		EndDo; 
	
	EndIf; 
	
EndFunction

Procedure GetChartDataForYear(ScheduleParameters, YearOfSchedule)

	ScheduleParameters.CalendarSchedule.Insert(YearOfSchedule, New Map);
	ScheduleParameters.Workdays.Insert(YearOfSchedule, New Map);
	DaysCountInSchedule = 0;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CalendarSchedules.ScheduleDate,
	|	CalendarSchedules.DayAddedToSchedule
	|FROM
	|	InformationRegister.CalendarSchedules AS CalendarSchedules
	|WHERE
	|	CalendarSchedules.Year = &Year
	|	AND CalendarSchedules.Calendar = &Calendar
	|
	|ORDER BY
	|	CalendarSchedules.ScheduleDate";
	
	Query.SetParameter("Year", YearOfSchedule);
	Query.SetParameter("Calendar", ScheduleParameters.Calendar);
	
	SelectionDetailRecords = Query.Execute().Select();
	
	CalendarSchedule = ScheduleParameters.CalendarSchedule.Get(YearOfSchedule);
	Workdays = ScheduleParameters.Workdays.Get(YearOfSchedule);
	
	NumberOfWorkingDaysInScheduleSinceBeginningOfYear = 0;
	While SelectionDetailRecords.Next() Do
		
		If SelectionDetailRecords.DayAddedToSchedule Then
			NumberOfWorkingDaysInScheduleSinceBeginningOfYear = NumberOfWorkingDaysInScheduleSinceBeginningOfYear + 1;
			Workdays.Insert(NumberOfWorkingDaysInScheduleSinceBeginningOfYear, SelectionDetailRecords.ScheduleDate);
		EndIf;
		
		CalendarSchedule.Insert(SelectionDetailRecords.ScheduleDate, NumberOfWorkingDaysInScheduleSinceBeginningOfYear);
		
	EndDo;
	
	ScheduleParameters.DaysInSchedule.Insert(YearOfSchedule, NumberOfWorkingDaysInScheduleSinceBeginningOfYear);

EndProcedure

#EndRegion

#EndRegion

#EndIf
