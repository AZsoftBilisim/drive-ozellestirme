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
	
	DocumentMechanisms.Add("AvailabilityOfWorkCenters");
	
EndProcedure

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Return; //In the future, the command code will be added
	
EndProcedure

// Adds a command to create the Document "availability of the work center view".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  - ValueTableRow
//  - Undefined
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.AvailabilityOfWorkCenterType) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.AvailabilityOfWorkCenterType.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.AvailabilityOfWorkCenterType);
		CreateBasedOnCommand.WriteMode = "Post";
		
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

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.AvailabilityOfWorkCenterType") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		Query.SetParameter("Ref", DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableAvailabilityOfWorkCenterTypes(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

Function QueryTextTableAvailabilityOfWorkCenterTypes(Query, QueryTexts, Registers)
	
	RegisterName = "AvailabilityOfWorkCenterTypes";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText =
	"SELECT
	|	Attributes.IntervalDate AS Period,
	|	Attributes.WorkCenterType AS WorkCenterType,
	|	Attributes.WorkCenterType.Department AS Department,
	|	Attributes.IntervalDate AS IntervalDate,
	|	Attributes.Count * 3600 AS WorkCenterTypeSchedule,
	|	CASE Attributes.WorkCenterType.UnitOfMeasureOfWorkCenterSchedule
	|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
	|			THEN 60
	|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
	|			THEN 3600
	|		ELSE 86400
	|	END * Attributes.WorkCenterType.MaximumWorkCenterAvailability AS MaximumAvailabilityByWorkCenterType,
	|	TRUE AS IsRecordOfWorkCentersCapacityChange,
	|	FALSE AS ThisIsProductionOrderrecord,
	|	FALSE AS ThisIsOperationSheetRecord
	|FROM
	|	Document.AvailabilityOfWorkCenterType AS Attributes
	|WHERE
	|	Attributes.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
