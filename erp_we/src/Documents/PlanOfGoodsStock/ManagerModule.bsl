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
	
	If TypeOf(Document) = Type("DocumentObject.PlanOfGoodsStock") Then
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
		
		QueryTextTablePlansOfGoodsStock(Query, QueryTexts, Registers);
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
	
	
EndProcedure

// Adds a command of creation of the document "Plan of astakov".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.PlanOfGoodsStock) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PlanOfGoodsStock.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PlanOfGoodsStock);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePlanningOfGoodsStock";
	

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
	
	Return True; // There are no additional checks for the "PlanOstatkov" document
	
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
	|	Document.PlanOfGoodsStock AS DocumentsTable
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
	
	ThisIsASalesPlan 			= PlanProfile.PlanType = Enums.TypesOfPlans.PlanOfGoodsStock;
	CreatePropsWithSelection = PlanProfile.FillInWarehouse 
		Or (Scenario.PlanningByAssignments And Not PlanProfile.FillInAssignmentInTabularForm);
	UseRemainderPlans = GetFunctionalOption("UsePlanningOfGoodsStock") And Scenario.UseInBalancePlanning;
	ThisIsASalesPlan = PlanProfile.PlanType = Enums.TypesOfPlans.SalesPlan;
	ThisIsASalesPlanByCategory = PlanProfile.PlanType = Enums.TypesOfPlans.SalesPlanByCategories;
	ThisIsProcurementPlan = PlanProfile.PlanType = Enums.TypesOfPlans.PurchasePlan;
	ThisIsAnAssemblyDisassemblyPlan = PlanProfile.PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan;
	ThisIsTheProductionPlan = PlanProfile.PlanType = Enums.TypesOfPlans.ProductionPlan;
	ThisIsADomesticConsumptionPlan = PlanProfile.PlanType = Enums.TypesOfPlans.InventoryConsumptionPlan;
	FillInAssignmentInTabularForm	= PlanProfile.FillInAssignmentInTabularForm;
	PlanningByAssignments = Scenario.PlanningByAssignments;
	
	TheseAreExpensePlans = ThisIsASalesPlan
		Or ThisIsASalesPlanByCategory
		Or (ThisIsTheProductionPlan And Parameters.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly)
		Or (ThisIsAnAssemblyDisassemblyPlan And Parameters.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents)
		Or ThisIsADomesticConsumptionPlan;
	TheseAreParishPlans = Not TheseAreExpensePlans;
	
#Region PlansOfGoodsStock
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"PlansOfGoodsStock");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch số dư';
													|ru = 'План остатков';
													|en = 'Goods stock plan'; fa = 'برنامه موجودی کالا';
													|it = 'Piano di giacenze';
													|pl = 'Plan saldo';
													|tr = 'Mal stok planı'"));
	AddnlParameter_.Insert("CreateProps", 	UseRemainderPlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseRemainderPlans);
	AddnlParameter_.Insert("OperandHeader",	NStr("vi = 'Kế hoạch số dư';
													|ru = 'План остатков';
													|en = 'Goods stock plan'; fa = 'برنامه موجودی کالا';
													|it = 'Piano di giacenze';
													|pl = 'Plan saldo';
													|tr = 'Mal stok planı'"));
	AddnlParameter_.Insert("Details", 		"Document.PlanOfGoodsStock");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("PlansOfGoodsStock", AddnlParameter_);
#EndRegion
	
#Region BalancePlansWithFilter
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"BalancePlansWithFilter");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch số dư *';
													|ru = 'План остатков*';
													|en = 'Goods stock plan*'; fa = 'Goods stock plan*';
													|it = 'Piano di rimanenze*';
													|pl = 'Plan pozostałości*';
													|tr = 'Mal stok planı*'"));
	AddnlParameter_.Insert("CreateProps", 	UseRemainderPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseRemainderPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader",	NStr("vi = 'Kế hoạch số dư *';
													|ru = 'План остатков*';
													|en = 'Goods stock plan*'; fa = 'Goods stock plan*';
													|it = 'Piano di rimanenze*';
													|pl = 'Plan pozostałości*';
													|tr = 'Mal stok planı*'"));
	AddnlParameter_.Insert("Details", 		"Document.PlanOfGoodsStock");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("BalancePlansWithFilter", AddnlParameter_);
#EndRegion

#Region AvailableStock
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"AvailableStock");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Còn lại';
													|ru = 'Доступный остаток';
													|en = 'Available remaining stock'; fa = 'موجودی باقیمانده در دسترس';
													|it = 'Saldo disponibile';
													|pl = ' Dostępna pozostałość';
													|tr = 'Mevcut bakiye'"));
	AddnlParameter_.Insert("CreateProps", 	Not PlanningByAssignments);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	Not PlanningByAssignments);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Số dư tự do';
													|ru = 'Свободный остаток';
													|en = 'Available inventory'; fa = 'موجودی در دسترس';
													|it = 'Rimanenza libera';
													|pl = 'Wolny ostatek';
													|tr = 'Serbest bakiye'"));
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsFacts");
	
	AddlParameters.Insert("AvailableStock",AddnlParameter_);
#EndRegion

#Region ActualStartBalance
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"ActualStartBalance");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			?(CreatePropsWithSelection, NStr("vi = 'Số dư đầu thực tế *';
																				|ru = 'Фактический начальный остаток*';
																				|en = 'Actual opening balance*'; fa = 'Actual opening balance*';
																				|it = 'Rimanenze effettive iniziali*';
																				|pl = 'Rzeczywiste początkowe pozostałości*';
																				|tr = 'Gerçek başlangıç bakiyesi*'"),
		NStr("vi = 'Số dư đầu thực tế';
			|ru = 'Фактический начальный остаток';
			|en = 'Actual opening balance'; fa = 'مانده افتتاحیه واقعی';
			|it = 'Rimanenze effettive iniziali';
			|pl = 'Rzeczywiste początkowe pozostałości';
			|tr = 'Gerçek başlangıç bakiyesi'")));
	AddnlParameter_.Insert("CreateProps", 	True);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	True);
	AddnlParameter_.Insert("OperandHeader", 	?(CreatePropsWithSelection, NStr("vi = 'Số dư đầu thực tế *';
																				|ru = 'Фактический начальный остаток*';
																				|en = 'Actual opening balance*'; fa = 'Actual opening balance*';
																				|it = 'Rimanenze effettive iniziali*';
																				|pl = 'Rzeczywiste początkowe pozostałości*';
																				|tr = 'Gerçek başlangıç bakiyesi*'"),
		NStr("vi = 'Số dư đầu thực tế';
			|ru = 'Фактический начальный остаток';
			|en = 'Actual opening balance'; fa = 'مانده افتتاحیه واقعی';
			|it = 'Rimanenze effettive iniziali';
			|pl = 'Rzeczywiste początkowe pozostałości';
			|tr = 'Gerçek başlangıç bakiyesi'")));
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsFacts");
	
	AddlParameters.Insert("ActualStartBalance",AddnlParameter_);
#EndRegion

#Region PlannedStartBalance
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"PlannedStartBalance");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Số dư đầu kế hoạch';
													|ru = 'Планируемый начальный остаток';
													|en = 'Planned opening balance'; fa = 'مانده افتتاحیه برنامه‌ریزی‌شده';
													|it = 'Rimanenze pianificate iniziali';
													|pl = 'Planowane początkowe resztę pozostałości';
													|tr = 'Planlanan başlangıç bakiyesi'"));
	AddnlParameter_.Insert("CreateProps", 	UseRemainderPlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	UseRemainderPlans);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Số dư đầu kế hoạch';
													|ru = 'Планируемый начальный остаток';
													|en = 'Planned opening balance'; fa = 'مانده افتتاحیه برنامه‌ریزی‌شده';
													|it = 'Rimanenze pianificate iniziali';
													|pl = 'Planowane początkowe resztę pozostałości';
													|tr = 'Planlanan başlangıç bakiyesi'"));
	AddnlParameter_.Insert("IncludedInOperand",		"MainOperands");
	
	AddlParameters.Insert("PlannedStartBalance",AddnlParameter_);
#EndRegion

#Region PlannedStartBalanceWithSelection
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"PlannedStartBalanceWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Số dư đầu kế hoạch*';
													|ru = 'Планируемый начальный остаток*';
													|en = 'Planned opening balance*'; fa = 'Planned opening balance*';
													|it = 'Rimanenze pianificate iniziali*';
													|pl = 'Planowane saldo początkowe *';
													|tr = 'Planlanan başlangıç bakiyesi*'"));
	AddnlParameter_.Insert("CreateProps", 	UseRemainderPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	UseRemainderPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Số dư đầu kế hoạch*';
													|ru = 'Планируемый начальный остаток*';
													|en = 'Planned opening balance*'; fa = 'Planned opening balance*';
													|it = 'Rimanenze pianificate iniziali*';
													|pl = 'Planowane saldo początkowe *';
													|tr = 'Planlanan başlangıç bakiyesi*'"));
	AddnlParameter_.Insert("IncludedInOperand",		"BasicOperandsWithSelection");
	
	AddlParameters.Insert("PlannedStartBalanceWithSelection",AddnlParameter_);
#EndRegion

#Region PlannedFinalBalances
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"PlannedFinalBalances");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Số dư cuối kế hoạch';
													|ru = 'Планируемый конечный остаток';
													|en = 'Planned closing balance'; fa = 'مانده اختتامیه برنامه‌ریزی‌شده';
													|it = 'Rimanenze pianificate finali';
													|pl = 'Planowane saldo końcowe';
													|tr = 'Planlanan kapanış bakiyesi'"));
	AddnlParameter_.Insert("CreateProps", 	UseRemainderPlans And TheseAreExpensePlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	UseRemainderPlans And TheseAreExpensePlans);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Số dư cuối kế hoạch';
													|ru = 'Планируемый конечный остаток';
													|en = 'Planned closing balance'; fa = 'مانده اختتامیه برنامه‌ریزی‌شده';
													|it = 'Rimanenze pianificate finali';
													|pl = 'Planowane saldo końcowe';
													|tr = 'Planlanan kapanış bakiyesi'"));
	AddnlParameter_.Insert("IncludedInOperand",		"MainOperands");
	
	AddlParameters.Insert("PlannedFinalBalances",AddnlParameter_);
#EndRegion

#Region PlannedFinalBalancesWithSelection
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"PlannedFinalBalancesWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Số dư cuối kế hoạch*';
													|ru = 'Планируемый конечный остаток*';
													|en = 'Planned closing balance*'; fa = 'Planned closing balance*';
													|it = 'Rimanenze pianificate finali*';
													|pl = 'Planowane saldo końcowe*';
													|tr = 'Planlanan kapanış bakiyesi*'"));
	AddnlParameter_.Insert("CreateProps", 	UseRemainderPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	UseRemainderPlans And CreatePropsWithSelection And TheseAreExpensePlans);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Số dư cuối kế hoạch*';
													|ru = 'Планируемый конечный остаток*';
													|en = 'Planned closing balance*'; fa = 'Planned closing balance*';
													|it = 'Rimanenze pianificate finali*';
													|pl = 'Planowane saldo końcowe*';
													|tr = 'Planlanan kapanış bakiyesi*'"));
	AddnlParameter_.Insert("IncludedInOperand",		"BasicOperandsWithSelection");
	
	AddlParameters.Insert("PlannedFinalBalancesWithSelection",AddnlParameter_);
#EndRegion

#Region PlannedFinalDeficit
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"PlannedFinalDeficit");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch thâm hụt dư cuối';
													|ru = 'Планируемый конечный дефицит';
													|en = 'Planned closing shortage'; fa = 'Planned closing shortage';
													|it = 'Disavanzo pianificato finale';
													|pl = 'Planowany deficyt końcowy';
													|tr = 'Planlanan nihai mali açık'"));
	AddnlParameter_.Insert("CreateProps", 	UseRemainderPlans And TheseAreParishPlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	UseRemainderPlans And TheseAreParishPlans);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch thâm hụt dư cuối';
													|ru = 'Планируемый конечный дефицит';
													|en = 'Planned closing shortage'; fa = 'Planned closing shortage';
													|it = 'Disavanzo pianificato finale';
													|pl = 'Planowany deficyt końcowy';
													|tr = 'Planlanan nihai mali açık'"));
	AddnlParameter_.Insert("IncludedInOperand",		"MainOperands");
	
	AddlParameters.Insert("PlannedFinalDeficit",AddnlParameter_);
#EndRegion

#Region PlannedFinalDeficitWithSelection
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"PlannedFinalDeficitWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch thâm hụt dư cuối*';
													|ru = 'Планируемый конечный дефицит*';
													|en = 'Planned closing shortage*'; fa = 'Planned closing shortage*';
													|it = 'Disavanzo pianificato finale*';
													|pl = 'Planowane braki końcowe*';
													|tr = 'Planlanan nihai mali açık*'"));
	AddnlParameter_.Insert("CreateProps", 	UseRemainderPlans And CreatePropsWithSelection And TheseAreParishPlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	UseRemainderPlans And CreatePropsWithSelection And TheseAreParishPlans);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch thâm hụt dư cuối*';
													|ru = 'Планируемый конечный дефицит*';
													|en = 'Planned closing shortage*'; fa = 'Planned closing shortage*';
													|it = 'Disavanzo pianificato finale*';
													|pl = 'Planowane braki końcowe*';
													|tr = 'Planlanan nihai mali açık*'"));
	AddnlParameter_.Insert("IncludedInOperand",		"BasicOperandsWithSelection");
	
	AddlParameters.Insert("PlannedFinalDeficitWithSelection",AddnlParameter_);
#EndRegion

#Region AccumulatedPlannedClosingShortage
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"AccumulatedPlannedClosingShortage");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Lũy kế thâm hụt cuối cùng theo kế hoạch';
													|ru = 'Накопленный планируемый конечный дефицит';
													|en = 'Accumulated planned closing shortage'; fa = 'Accumulated planned closing shortage';
													|it = 'Disavanzo accumulato pianificato finale';
													|pl = 'Zgromadzeni planowane braki końcowe';
													|tr = 'Birikmiş planlanan nihai mali açık'"));
	AddnlParameter_.Insert("CreateProps", 	UseRemainderPlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	False);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Lũy kế thâm hụt cuối cùng theo kế hoạch';
													|ru = 'Накопленный планируемый конечный дефицит';
													|en = 'Accumulated planned closing shortage'; fa = 'Accumulated planned closing shortage';
													|it = 'Disavanzo accumulato pianificato finale';
													|pl = 'Zgromadzeni planowane braki końcowe';
													|tr = 'Birikmiş planlanan nihai mali açık'"));
	AddnlParameter_.Insert("IncludedInOperand",		"MainOperands");
	
	AddlParameters.Insert("AccumulatedPlannedClosingShortage",AddnlParameter_);
#EndRegion

#Region AccumulatedPlannedClosingShortageWithSelection
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"AccumulatedPlannedClosingShortageWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Lũy kế thâm hụt cuối cùng theo kế hoạch*';
													|ru = 'Накопленный планируемый конечный дефицит*';
													|en = 'Accumulated planned closing shortage*'; fa = 'Accumulated planned closing shortage*';
													|it = 'Disavanzo accumulato pianificato finale*';
													|pl = 'Zgromadzeni planowane braki końcowe*';
													|tr = 'Birikmiş planlanan nihai mali açık*'"));
	AddnlParameter_.Insert("CreateProps", 	UseRemainderPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	False);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Lũy kế thâm hụt cuối cùng theo kế hoạch*';
													|ru = 'Накопленный планируемый конечный дефицит*';
													|en = 'Accumulated planned closing shortage*'; fa = 'Accumulated planned closing shortage*';
													|it = 'Disavanzo accumulato pianificato finale*';
													|pl = 'Zgromadzeni planowane braki końcowe*';
													|tr = 'Birikmiş planlanan nihai mali açık*'"));
	AddnlParameter_.Insert("IncludedInOperand",		"BasicOperandsWithSelection");
	
	AddlParameters.Insert("AccumulatedPlannedClosingShortageWithSelection",AddnlParameter_);
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
	
	Templates.Insert("PlansOfGoodsStock",                       GetTemplate("DCS_PlansOfGoodsStock"));
	Templates.Insert("BalancePlansWithFilter",               GetTemplate("DCS_BalancePlansWithFilter"));
	Templates.Insert("PlannedStartBalance",         GetTemplate("DCS_PlannedStartBalance"));
	Templates.Insert("PlannedStartBalanceWithSelection", GetTemplate("DCS_PlannedStartBalanceWithSelection"));
	Templates.Insert("AvailableStock",                    GetTemplate("DCS_AvailableStock"));
	Templates.Insert("ActualStartBalance",         GetTemplate("DCS_ActualStartBalance"));
	
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
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.PlanOfGoodsStock.ManagerModule.FillInDocumentUsingFormula");
	
	If Not Parameters.Property("FillInUsingFormula") Then
		Return;
	EndIf; 
	
	PeriodColumnName = "BalanceDate";
	
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
	
	PeriodColumnName = "BalanceDate";
	
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
		Enums.TypesOfPlans.PlanOfGoodsStock, 
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
			ResultString1.Details = ResultString1.Details + " = " + ResultString1.NumericalRepresentation;
			
			If ResultString1.NumericalRepresentation <> String(Count) Then
				ResultString1.Details = ResultString1.Details + " = " + String(Count);
			EndIf;
			
			If Parameters.CrossTable Then
				
				If ValueIsFilled(ResultString1.Period) 
					And ResultString1.Period >= Parameters.BeginOfPeriod 
					And ResultString1.Period <= Parameters.PeriodEnding Then
					
					// It is not necessary to distribute by periods
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
					Continue;
				EndIf; 
				
				// With a uniform distribution, the remainder of the rounding is subtracted from the first element, so we reset it if it went into negative.
				If QuantityDistribution[0] < 0 Then
					QuantityDistribution[0] = 0;
				EndIf;
				
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
					
				EndDo; 
				
			Else
				
				NewRow = PopulatedTS.Add();
				FillPropertyValues(NewRow, ResultString1);
				NewRow.Count = Count;
				NewRow.NumberOfPackages = NewRow.Count;
				NewRow[PeriodColumnName] = ResultString1.Period;
				
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
	
	PeriodColumnName = "BalanceDate";
	
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
	|	DocumentData.Status AS Status,
	|	DocumentData.Scenario AS Scenario,
	|	DocumentData.PlanProfile AS PlanProfile,
	|	DocumentData.Substitutional AS Substitutional,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.BudgetingScenario AS BudgetingScenario,
	|	DocumentData.BudgetingScenario.Currency AS Currency,
	|	DocumentData.Warehouse.Department AS Department,
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod,
	|	DocumentData.PeriodEnding AS PeriodEnding,
	|	DocumentData.Purpose AS Purpose,
	|	DocumentData.PlanProfile.FillInAssignmentInTabularForm AS FillInAssignmentInTabularForm
	|FROM
	|	Document.PlanOfGoodsStock AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdditionalAttributes.LineNumber,
	|	AdditionalAttributes.Value
	|FROM
	|	Document.PlanOfGoodsStock.AdditionalAttributes AS AdditionalAttributes
	|WHERE
	|	AdditionalAttributes.Ref = &Ref
	|";
	
	QueryResults = Query.ExecuteBatch(); 
	Attributes = QueryResults[0].Select();
	Attributes.Next();
	
	Query.SetParameter("BeginOfPeriod",          Attributes.BeginOfPeriod);
	Query.SetParameter("PeriodEnding",       Attributes.PeriodEnding);
	Query.SetParameter("Scenario",               Attributes.Scenario);
	Query.SetParameter("PlanProfile",               Attributes.PlanProfile);
	Query.SetParameter("Substitutional",             Attributes.Substitutional);
	Query.SetParameter("Status",                 Attributes.Status);
	Query.SetParameter("Purpose",             Attributes.Purpose);
	Query.SetParameter("FillInAssignmentInTabularForm", Attributes.FillInAssignmentInTabularForm);
	Query.SetParameter("Date",                                  Attributes.Date);
	Query.SetParameter("BudgetingScenario",                Attributes.BudgetingScenario);
	Query.SetParameter("Currency",                                Attributes.Currency);
	Query.SetParameter("Department",                         Attributes.Department);
	
	SelectionDetailRecords = QueryResults[1].Select();
	While SelectionDetailRecords.Next() Do
		If Not ValueIsFilled(SelectionDetailRecords.Value) Then
			Continue;
		EndIf;
		Query.SetParameter("AdditionalAttribute"+Format(SelectionDetailRecords.LineNumber, "NG=0"), SelectionDetailRecords.Value);
	EndDo;
EndProcedure

Function QueryTextTablePlansOfGoodsStock(Query, QueryTexts, Registers)
	
	RegisterName = "PlansOfGoodsStock";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.Ref AS PlanOfGoodsStock,
	|	&Status AS Status,
	|	&BeginOfPeriod AS Period,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService)  
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE GoodsTable.Purpose
	|	END AS Purpose,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService) 
	|				OR CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5) 
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE GoodsTable.Warehouse
	|	END AS Warehouse,
	|	&Scenario AS Scenario,
	|	&PlanProfile AS PlanProfile,
	|	CASE
	|		WHEN GoodsTable.Substituted
	|			THEN 0
	|		ELSE GoodsTable.Count
	|	END AS Count,
	|	CASE
	|		WHEN &Status = VALUE(Enum.PlanStatuses.Upholded)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS ToOrder
	|FROM
	|	Document.PlanOfGoodsStock.Goods AS GoodsTable
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON GoodsTable.Products = CatProducts.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Canceled
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND (NOT GoodsTable.Substituted
	|				AND &Status <> VALUE(Enum.PlanStatuses.Upholded)
	|			OR NOT GoodsTable.SubstitutedToOrder
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	
	FullDocumentName = "Document.PlanOfGoodsStock"; 
	ParameterValues = New Structure;
	
	RedefiningParameterCalculation = New Structure;
		
	If RegisterName = "PlansOfGoodsStock" Then
	
		QueryText = QueryTextTablePlansOfGoodsStock(Query, QueryTexts, RegisterName);
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
	|	ResidueReplacementPlan.Ref AS ReplacementPlan_3,
	|	CASE
	|		WHEN &BeginOfPeriod > ResidueReplacementPlan.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE ResidueReplacementPlan.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < ResidueReplacementPlan.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE ResidueReplacementPlan.PeriodEnding
	|	END AS PeriodEnding,
	|	ResidueReplacementPlan.Status AS Status
	|FROM
	|	Document.PlanOfGoodsStock AS ResidueReplacementPlan
	|WHERE
	|	ResidueReplacementPlan.PeriodEnding >= &BeginOfPeriod
	|	AND ResidueReplacementPlan.BeginOfPeriod <= &PeriodEnding
	|	AND ResidueReplacementPlan.Ref <> &Ref
	|	AND ResidueReplacementPlan.Posted
	|	AND ResidueReplacementPlan.PlanProfile = &PlanProfile
	|	AND (ResidueReplacementPlan.Status.Order >= &StatusIndex
	|			OR ResidueReplacementPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND ResidueReplacementPlan.Date > &Date
	|	AND ResidueReplacementPlan.Warehouse = &Warehouse
	|	AND ResidueReplacementPlan.Purpose = &Purpose
	|
	|ORDER BY
	|	BeginOfPeriod,
	|	Status
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ResiduesPlanSubstituted.Ref AS SubstitutedPlan,
	|	CASE
	|		WHEN &BeginOfPeriod > ResiduesPlanSubstituted.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE ResiduesPlanSubstituted.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < ResiduesPlanSubstituted.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE ResiduesPlanSubstituted.PeriodEnding
	|	END AS PeriodEnding,
	|	ResiduesPlanSubstituted.Status AS Status
	|FROM
	|	Document.PlanOfGoodsStock AS ResiduesPlanSubstituted
	|WHERE
	|	ResiduesPlanSubstituted.PeriodEnding >= &BeginOfPeriod
	|	AND ResiduesPlanSubstituted.BeginOfPeriod <= &PeriodEnding
	|	AND ResiduesPlanSubstituted.Ref <> &Ref
	|	AND ResiduesPlanSubstituted.Posted
	|	AND ResiduesPlanSubstituted.PlanProfile = &PlanProfile
	|	AND (ResiduesPlanSubstituted.Status.Order <= &StatusIndex
	|			OR ResiduesPlanSubstituted.Status = VALUE(Enum.PlanStatuses.Upholded)
	|				AND &Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation))
	|	AND ResiduesPlanSubstituted.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND ResiduesPlanSubstituted.Date < &Date
	|	AND ResiduesPlanSubstituted.Warehouse = &Warehouse
	|	AND ResiduesPlanSubstituted.Purpose = &Purpose
	|
	|ORDER BY
	|	BeginOfPeriod,
	|	Status";
	
	Query.SetParameter("Ref", Parameters.Ref);
	Query.SetParameter("PlanProfile", Parameters.PlanProfile);
	Query.SetParameter("Status", Parameters.Status);
	Query.SetParameter("StatusIndex", Enums.PlanStatuses.IndexOf(Parameters.Status));
	Query.SetParameter("Date", Parameters.Date);
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
		|	TurnoverBalancePlans.Period AS CompositionPeriod,
		|	TurnoverBalancePlans.Scenario,
		|	TurnoverBalancePlans.Status,
		|	TurnoverBalancePlans.Products,
		|	TurnoverBalancePlans.Characteristic,
		|	TurnoverBalancePlans.Purpose,
		|	TurnoverBalancePlans.Warehouse,
		|	TurnoverBalancePlans.Purpose,
		|	TurnoverBalancePlans.CountTurnover AS NumberOfPackages
		|FROM
		|	AccumulationRegister.PlansOfGoodsStock.Turnovers(
		|			&BeginOfPeriod,
		|			&EndOfPeriod,
		|			Record,
		|			Scenario = &Scenario
		|				AND PlanProfile = &PlanProfile
		|				AND &QueryTextFilterWarehouse
		|				AND (&FillInAssignmentInTabularForm OR Purpose = &Purpose)
		|				AND Status IN (&Statuses)) AS TurnoverBalancePlans";
		
	Query.SetParameter("EndOfPeriod",   Parameters.OffsetPeriodEnd);
	Query.SetParameter("BeginOfPeriod",  Parameters.OffsetPeriodStart);
	Query.SetParameter("Warehouse",          Parameters.Warehouse);
	Query.SetParameter("Statuses",        Parameters.Statuses);
	Query.SetParameter("Scenario",       Parameters.Scenario);
	Query.SetParameter("PlanProfile",       Parameters.PlanProfile);
	Query.SetParameter("FillInAssignmentInTabularForm", Parameters.FillInAssignmentInTabularForm);
	Query.SetParameter("Purpose",     Parameters.Purpose);
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterWarehouse",
		?(ValueIsFilled(Parameters.Warehouse),"Warehouse = &Warehouse","True"));
	
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
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse AND Object.Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	
	// Needs for goods in stock in pm.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "ProvisionOfOrdersWarehouseVHF");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouseInTabularForm AND Object.Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Goods.Warehouse";
	
	// Needs for goods in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.Goods.Purpose", "SecuringOrdersAllWarehouses");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse = FALSE AND Object.PlanProfile.FillInWarehouseInTabularForm = FALSE AND Object.Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
		
	// The needs for goods in stock in the header (by period).
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.GoodsByPeriod.Purpose", "SecuringOrdersForWarehousePeriodsInHeader");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse AND Object.GoodsByPeriod.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.GoodsByPeriod.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.GoodsByPeriod.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	
	// Needs for goods in stock in pm (by period).
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.GoodsByPeriod.Purpose", "ProvisionOfOrdersForPeriodsWarehouseWH");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouseInTabularForm AND Object.GoodsByPeriod.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.GoodsByPeriod.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.GoodsByPeriod.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.GoodsByPeriod.Warehouse";
	
	// Needs for goods in all warehouses (by period).
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.GoodsByPeriod.Purpose", "SecuringOrdersForAllWarehousesByPeriod");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse = FALSE AND Object.PlanProfile.FillInWarehouseInTabularForm = FALSE AND Object.GoodsByPeriod.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.GoodsByPeriod.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.GoodsByPeriod.Characteristic";
		
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

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Balance plan
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PlanOfGoodsStock";
	PrintCommand.Presentation = NStr("vi = 'Kế hoạch số dư';
									|ru = 'План остатков';
									|en = 'Goods stock plan'; fa = 'برنامه موجودی کالا';
									|it = 'Piano di giacenze';
									|pl = 'Plan saldo';
									|tr = 'Mal stok planı'");
	PrintCommand.CheckPostingBeforePrint = True;

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PlanOfGoodsStock") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"PlanOfGoodsStock",
			NStr("vi = 'Kế hoạch số dư';
				|ru = 'План остатков';
				|en = 'Goods stock plan'; fa = 'برنامه موجودی کالا';
				|it = 'Piano di giacenze';
				|pl = 'Plan saldo';
				|tr = 'Mal stok planı'"),
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
	WithdrawWarehouse 			= True;
	DisplayVHFWarehouse 		= True;
	
	If PrintParameters <> Undefined And Not PrintParameters.Property("OutputScript", OutputScript) Then
		OutputScript 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("DisplayPeriodStatus", DisplayPeriodStatus) Then
		DisplayPeriodStatus	= True;
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
	|	DocumentTable.BeginOfPeriod                  AS BalanceDate,
	|	DocumentTable.Scenario                       AS Scenario,
	|	DocumentTable.PlanProfile                       AS PlanProfile,
	|	CASE
	|		WHEN &DefaultCrossTable
	|				OR DocumentTable.CrossTable
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                           AS CrossTable,
	|	DocumentTable.FilledAutomatically         AS FilledAutomatically,
	|	CatPlanProfiles.FillInManager                AS FillInManager,
	|	CatPlanProfiles.FillInWarehouse                    AS FillInWarehouse,
	|	CatPlanProfiles.FillInStoreFormat           AS FillInStoreFormat,
	|	CatPlanProfiles.FillInWarehouseInTabularForm                 AS FillInWarehouseInTabularForm,
	|	PlanningScenarios.ShowNumberOfPeriod     AS ShowNumberOfPeriod,
	|	Users.Individual                     AS ResponsibleIndividual,
	|	DocumentTable.Warehouse                          AS Warehouse,
	|	DocumentTable.Purpose                     AS Purpose,
	|	PlanningScenarios.PlanningByAssignments  AS PlanningByAssignments,
	|	CatPlanProfiles.FillInAssignmentInTabularForm            AS FillInAssignmentInTabularForm
	|FROM
	|	Document.PlanOfGoodsStock AS DocumentTable
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
	|	GoodsTable.BalanceDate                       AS PeriodDate_,
	|	GoodsTable.NumberOfPackages                AS Count,
	|	GoodsTable.Comment                       AS Comment,
	|	GoodsTable.Warehouse                             AS Warehouse,
	|	GoodsTable.Purpose.Description           AS PurposeName,
	|	GoodsTable.Purpose                        AS Purpose
	|FROM
	|	Document.PlanOfGoodsStock.Goods AS GoodsTable
	|WHERE
	|	(&DefaultTable
	|			OR NOT GoodsTable.Ref.CrossTable)
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
	|	NestedQuery.PeriodDate_,
	|	SUM(NestedQuery.NumberOfPackages),
	|	MAX(NestedQuery.Comment),
	|	NestedQuery.Warehouse,
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
	|				THEN BEGINOFPERIOD(GoodsTable.BalanceDate, YEAR)
	|			WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|				THEN BEGINOFPERIOD(GoodsTable.BalanceDate, HALFYEAR)
	|			WHEN VALUE(Enum.Periodicity.QUARTER)
	|				THEN BEGINOFPERIOD(GoodsTable.BalanceDate, QUARTER)
	|			WHEN VALUE(Enum.Periodicity.MONTH)
	|				THEN BEGINOFPERIOD(GoodsTable.BalanceDate, MONTH)
	|			WHEN VALUE(Enum.Periodicity.TENDAYS)
	|				THEN BEGINOFPERIOD(GoodsTable.BalanceDate, TENDAYS)
	|			WHEN VALUE(Enum.Periodicity.WEEK)
	|				THEN BEGINOFPERIOD(GoodsTable.BalanceDate, WEEK)
	|			ELSE GoodsTable.BalanceDate
	|		END AS PeriodDate_,
	|		GoodsTable.LineNumber AS LineNumber,
	|		CASE WHEN GoodsTable.Canceled THEN 0 ELSE GoodsTable.NumberOfPackages END AS NumberOfPackages,
	|		CASE WHEN GoodsTable.Canceled THEN """" ELSE CAST(GoodsTable.Comment AS STRING(1000)) END AS Comment,
	|		GoodsTable.Warehouse                 AS Warehouse,
	|		GoodsTable.Purpose            AS Purpose
	|	FROM
	|		Document.PlanOfGoodsStock.Goods AS GoodsTable
	|			INNER JOIN Document.PlanOfGoodsStock AS DocumentTable
	|			ON GoodsTable.Ref = DocumentTable.Ref
	|	WHERE
	|		(&DefaultCrossTable
	|				OR GoodsTable.Ref.CrossTable)
	|		AND GoodsTable.Ref IN(&DocumentsArray)
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
	|	NestedQuery.Package
	|
	|ORDER BY
	|	Ref,
	|	LineNumber,
	|	ProductNameFull_,
	|	CharacteristicFullName,
	|	PurposeName,
	|	Warehouse,
	|	UnitOfMeasure,
	|	PeriodDate_
	|TOTALS BY
	|	Ref");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_PlanOfGoodsStock_PlanOfGoodsStock";
	
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
		Template = PrintManagement.PrintFormTemplate("Document.PlanOfGoodsStock.PF_MXL_PlanOfGoodsStock");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the plan
		If DisplayHeader Then
			
			TemplateArea = Template.GetArea("Title");
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
			
			TitleText = TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'Kế hoạch số dư';
																						|ru = 'План остатков';
																						|en = 'Goods stock plan'; fa = 'برنامه موجودی کالا';
																						|it = 'Piano di giacenze';
																						|pl = 'Plan saldo';
																						|tr = 'Mal stok planı'"));
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
				TemplateArea                                = Template.GetArea("PeriodStatus");
				TemplateArea.Parameters.BalanceDate          = Format(PrintData.BalanceDate, "DLF=D");
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
		
		Count = ?(CrossTable, "NumberOfCrosses", "Count");
		
		OwnGoods = ?(Not (DisplayHeader Or UseItemVariants), "ProductWithoutCharacteristics", "OwnGoods");
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
		DataArea                   = Template.GetArea(?(DisplayHeader Or CrossTable,"TableHeader","HeaderOfNHTable") + "|" + Count);
		DataAreaCrossEnd     = Template.GetArea("TableHeader|NumberOfCrossEndings");
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
		AreaCrossUnitOfMeasurement    = Template.GetArea("TableRow|CrossUnitOfMeasurement");
		If Add_Fields.Count() > 0 Then
			ProductFieldArea         = Template.GetArea("TableRow|ProductAddField"+ Format(Add_Fields.Count(), "NFD=0; NG=0") );
		EndIf;
		
		CurrentRow  = New Structure("Products, Characteristic, Purpose, Warehouse, UnitOfMeasure");
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
					
					UIArea.Parameters.UniqueWarehouseID                 = String(ProductSelection_1.Warehouse.UUID());
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
		ColumnsArray1.Add(8);
		ColumnsArray1.Add(9);
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
	
	FormName = "Document.PlanOfGoodsStock.Form.ListForm";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.PlanOfGoodsStock))
		And AccessRight("Insert", Metadata.Documents.PlanOfGoodsStock)
		And GetFunctionalOption("UsePlanningOfGoodsStock");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(*) AS BalancePlansPendingApproval,
	|	MIN(Plans.Status.Order) AS StatusOrder
	|FROM
	|	Document.PlanOfGoodsStock AS Plans
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
		UserTaskParent.Owner       = Planning.SubsystemPlanning();
	EndIf;
	
	// BalancePlansPendingApproval
	FilterParameters = New Structure;
	If Enums.PlanStatuses[Result.StatusOrder] = Enums.PlanStatuses.AwaitingConfirmation Then
		FilterParameters.Insert("Status", Enums.PlanStatuses.AwaitingConfirmation);
	EndIf;
	FilterParameters.Insert("DeletionMark", False);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "BalancePlansPendingApproval";
	ToDoItem.HasToDoItems       = Result.BalancePlansPendingApproval > 0;
	ToDoItem.Presentation  = NStr("vi = 'Kế hoạch số dư';
									|ru = 'Планы остатков';
									|en = 'Goods stock plans'; fa = 'برنامه‌های موجودی کالا';
									|it = 'Piani di giacenze';
									|pl = 'Plany sald';
									|tr = 'Mal stok planları'");
	ToDoItem.Count     = Result.BalancePlansPendingApproval;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "PurchasePlans";
	
	If Result.BalancePlansPendingApproval > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
