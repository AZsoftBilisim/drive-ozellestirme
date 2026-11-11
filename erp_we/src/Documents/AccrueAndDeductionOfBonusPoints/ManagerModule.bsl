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
	
	DocumentMechanisms.Add("PricesAndDiscounts");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.AccrueAndDeductionOfBonusPoints") Then
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
		
		QueryTextBonusPoints(Query, QueryTexts, Registers);
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

// Adds the command to create the document "Accrual and deduction of bonus points".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.AccrueAndDeductionOfBonusPoints) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.AccrueAndDeductionOfBonusPoints.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.AccrueAndDeductionOfBonusPoints);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseLoyaltyPrograms";

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

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref                                   AS Ref,
	|	DocumentData.Date                                     AS Period,
	|	DocumentData.LoyaltyProgram              AS LoyaltyProgram,
	|	DocumentData.ActionPeriod                           AS ActionPeriod,
	|	DocumentData.NumberOfValidityPeriods               AS NumberOfValidityPeriods,
	|	DocumentData.PeriodOfActionStartDelay             AS PeriodOfActionStartDelay,
	|	DocumentData.NumberOfActionStartDelayPeriods AS NumberOfActionStartDelayPeriods,
	|	DocumentData.ValidTo               AS ValidTo
	|FROM
	|	Document.AccrueAndDeductionOfBonusPoints AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Ref",                                   Attributes.Ref);
	Query.SetParameter("Period",                                   Attributes.Period);
	Query.SetParameter("LoyaltyProgram",              Attributes.LoyaltyProgram);
	Query.SetParameter("ActionPeriod",                           Attributes.ActionPeriod);
	Query.SetParameter("NumberOfValidityPeriods",               Attributes.NumberOfValidityPeriods);
	Query.SetParameter("PeriodOfActionStartDelay",             Attributes.PeriodOfActionStartDelay);
	Query.SetParameter("NumberOfActionStartDelayPeriods", Attributes.NumberOfActionStartDelayPeriods);
	Query.SetParameter("ValidTo",               Attributes.ValidTo);
	Query.SetParameter("CurrentDate",                              CurrentUniversalDate());
	Query.SetParameter("StartDateOfBonusPointsMechanism_2_5", Constants.StartDateOfBonusPointsMechanism_2_5.Get());
	
	TheseAreUrgentBonusPoints = Attributes.NumberOfValidityPeriods > 0
		Or ValueIsFilled(Attributes.ValidTo);
	Query.SetParameter("TheseAreUrgentBonusPoints", TheseAreUrgentBonusPoints);    

	StartDateOfPointsValidity = StartDateOfPointsValidity(
		Attributes.Period,
		Attributes.PeriodOfActionStartDelay,
		Attributes.NumberOfActionStartDelayPeriods);
	Query.SetParameter("StartDateOfPointsValidity", StartDateOfPointsValidity);	
	
	ExpirationDateOfPoints = ExpirationDateOfPoints(
		StartDateOfPointsValidity,
		Attributes.ValidTo,
		Attributes.ActionPeriod,
		Attributes.NumberOfValidityPeriods);
	Query.SetParameter("ExpirationDateOfPoints", ExpirationDateOfPoints);
	
EndProcedure

Function QueryTextBonusPoints(Query, QueryTexts, Registers)
	
	RegisterName = "BonusPoints";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBonusPoints", QueryTexts) Then
		QueryTextTTBonusPoints(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	BonusPoints.Period                      AS Period,
	|	BonusPoints.ValidityStartDate          AS ValidityStartDate,
	|	BonusPoints.DateToProcess              AS DateToProcess,
	|	BonusPoints.RecordType                 AS RecordType,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner                     AS Partner,
	|	SUM(BonusPoints.Accrued)            AS Accrued,
	|	SUM(BonusPoints.ToWriteOff)            AS ToWriteOff
	|FROM
	|	TTBonusPoints AS BonusPoints
	|GROUP BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.Period,
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.DateToProcess,
	|	BonusPoints.RecordType
	|HAVING 
	|	SUM(BonusPoints.Accrued) <> 0 OR 
	|	SUM(BonusPoints.ToWriteOff) <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBonusPoints(Query, QueryTexts)
	
	RegisterName = "TTBonusPoints";
	
	QueryText = 
	"SELECT
	|	&StartDateOfPointsValidity AS Period,
	|	CASE
	|		WHEN &TheseAreUrgentBonusPoints
	|			THEN BEGINOFPERIOD(&StartDateOfPointsValidity, DAY)
	|		ELSE DATETIME(1, 1, 1)
	|	END AS ValidityStartDate,
	|	CASE
	|		WHEN &TheseAreUrgentBonusPoints
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END AS DateToProcess,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&LoyaltyProgram AS LoyaltyProgram,
	|	TabularSection.Partner AS Partner,
	|	TabularSection.Points AS Accrued,
	|	0 AS ToWriteOff
	|INTO TTBonusPoints
	|FROM
	|	Document.AccrueAndDeductionOfBonusPoints.Accrual AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	&ExpirationDateOfPoints,
	|	CASE
	|		WHEN BEGINOFPERIOD(&ExpirationDateOfPoints,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN BEGINOFPERIOD(&StartDateOfPointsValidity, DAY)
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	CASE
	|		WHEN BEGINOFPERIOD(&ExpirationDateOfPoints,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&LoyaltyProgram,
	|	TabularSection.Partner,
	|	0,
	|	TabularSection.Points
	|FROM
	|	Document.AccrueAndDeductionOfBonusPoints.Accrual AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &TheseAreUrgentBonusPoints
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(&Period, DAY),
	|	DATETIME(1, 1, 1),
	|	CASE
	|		WHEN BEGINOFPERIOD(&Period, DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	VALUE(AccumulationRecordType.Expense),
	|	&LoyaltyProgram,
	|	TabularSection.Partner,
	|	TabularSection.Points,
	|	CASE
	|		WHEN BEGINOFPERIOD(&Period, DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN 0
	|		ELSE TabularSection.Points
	|	END
	|FROM
	|	Document.AccrueAndDeductionOfBonusPoints.WriteOff AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

Function StartDateOfPointsValidity(Period, PeriodType, NumberOfDeferralPeriods)
	
   	StartDateOfPointsValidity = Period;
	
 	If NumberOfDeferralPeriods > 0 Then  
		StartDateOfPointsValidity = RetailSalesClientServer.CalculatePeriodInterval(
			Period,
			PeriodType,
			NumberOfDeferralPeriods);
	EndIf;
	
	Return BegOfDay(StartDateOfPointsValidity);
	
EndFunction

Function ExpirationDateOfPoints(PeriodBeginning, PeriodEnd, PeriodType, NumberOfDeferralPeriods)
	
	If Not ValueIsFilled(PeriodEnd) And NumberOfDeferralPeriods = 0 Then
		Return Date(1, 1, 1);
	EndIf;
	
	ExpirationDateOfPoints = PeriodEnd;
	
	If NumberOfDeferralPeriods > 0 Then
		
		ExpirationDateOfPoints = RetailSalesClientServer.CalculatePeriodInterval(
			PeriodBeginning,
			PeriodType,
			NumberOfDeferralPeriods);
		
	EndIf;
	
	Return BegOfDay(ExpirationDateOfPoints);
	
EndFunction

#EndRegion

#EndIf
