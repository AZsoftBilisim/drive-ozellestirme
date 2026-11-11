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
	
	If TypeOf(Document) = Type("DocumentObject.AdjustmentOfPlannedDemand") Then
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
		
		QueryTextTableAdjustmentsToPlannedDemands(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
EndProcedure

// Adds the command to create the document "Adjustment of planned needs".
// 
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 
// Returns:
//  ValueTableRow of See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.AdjustmentOfPlannedDemand) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.AdjustmentOfPlannedDemand.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(
													Metadata.Documents.AdjustmentOfPlannedDemand);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = False;
		CreateBasedOnCommand.FunctionalOptions = "UsePurchasePlanning,
														|UseProductionPlanning,
														|UseAssemblyDisassemblyPlanning";
		
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
	
EndProcedure

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef.StatusesOfPlanAdjustments - New adjustment status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks for the document "Adjustment of planned needs"
	
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
	
	MeaningOfNewStatus = Enums.StatusesOfPlanAdjustments[NewStatus];
	
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
	|	Document.AdjustmentOfPlannedDemand AS DocumentsTable
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


#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Scenario)
	|	AND ValueAllowed(PlanProfile)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	
	Query.Text = 
	"SELECT
	|	AdjustmentOfPlannedDemand.Plan AS Plan,
	|	AdjustmentOfPlannedDemand.PlanProfile AS PlanProfile,
	|	AdjustmentOfPlannedDemand.Scenario AS Scenario,
	|	AdjustmentOfPlannedDemand.Period AS Period,
	|	AdjustmentOfPlannedDemand.Status AS Status
	|FROM
	|	Document.AdjustmentOfPlannedDemand AS AdjustmentOfPlannedDemand
	|WHERE
	|	AdjustmentOfPlannedDemand.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	PlanProfileStage = Common.ObjectAttributeValue(Attributes.PlanProfile, "Parent");
	If Not ValueIsFilled(PlanProfileStage) Then
		PlanProfileStage = Attributes.PlanProfile;
	EndIf;
		
	Query.SetParameter("Plan",                  Attributes.Plan);
	Query.SetParameter("PlanProfile",              Attributes.PlanProfile);
	Query.SetParameter("PlanProfileStage",          PlanProfileStage);
	
	Query.SetParameter("Scenario",              Attributes.Scenario);
	Query.SetParameter("Period",                Attributes.Period);
	Query.SetParameter("Status",                Attributes.Status);
	
EndProcedure

Function QueryTextTableAdjustmentsToPlannedDemands(Query, QueryTexts, Registers)
	
	RegisterName = "AdjustmentsToPlannedDemands";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText =
	"SELECT
	|	&Scenario AS Scenario,
	|	&PlanProfile AS PlanProfile,
	|	&PlanProfileStage AS PlanProfileStage,
	|	&Ref AS AdjustmentOfPlannedDemand,
	|	&Period AS Period,
	|	&Plan AS Plan,
	|	&Status AS Status,
	|	DecreasedDemands.Products AS Products,
	|	DecreasedDemands.Characteristic AS Characteristic,
	|	DecreasedDemands.Purpose AS Purpose,
	|	-DecreasedDemands.Count AS Count
	|FROM
	|	Document.AdjustmentOfPlannedDemand.DecreasedDemands AS DecreasedDemands
	|WHERE
	|	DecreasedDemands.Ref = &Ref
	|	AND &Status <> VALUE(Enum.StatusesOfPlanAdjustments.RolledBack)
	|
	|UNION ALL
	|
	|SELECT
	|	&Scenario,
	|	&PlanProfile,
	|	&PlanProfileStage AS PlanProfileStage,
	|	&Ref,
	|	&Period,
	|	&Plan,
	|	&Status AS Status,
	|	IncreasedDemand.Products,
	|	IncreasedDemand.Characteristic,
	|	IncreasedDemand.Purpose,
	|	IncreasedDemand.Count
	|FROM
	|	Document.AdjustmentOfPlannedDemand.IncreasedDemand AS IncreasedDemand
	|WHERE
	|	IncreasedDemand.Ref = &Ref
	|	AND &Status <> VALUE(Enum.StatusesOfPlanAdjustments.RolledBack)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

#EndRegion

#EndRegion

#EndIf