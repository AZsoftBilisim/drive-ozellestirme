
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
	
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	
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
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.DepositsWithdrawalsByLineOfBusiness") Then
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
		
		QueryTextOtherAssetsLiabilities(QueryTexts, Registers);
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
	|	DocumentData.Date                   AS Period,
	|	DocumentData.SourceArea AS SourceArea,
	|	DocumentData.DestinationArea  AS DestinationArea,
	|	DocumentData.EmployeeResponsible          AS EmployeeResponsible
	|
	|FROM
	|	Document.DepositsWithdrawalsByLineOfBusiness AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("ManagementAccountingCurrency",            Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Query.SetParameter("EmptyDirection",                     Catalogs.LinesOfBusiness.EmptyRef());
	
EndProcedure

Function QueryTextOtherAssetsLiabilities(QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"// Expenditure of indirect funds of the direction
	|SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	UNDEFINED                           AS Organization,
	|	UNDEFINED                           AS Department,
	|	DocumentData.SourceArea AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCashLineOfBusiness) AS AssetRef,
	|	UNDEFINED                           AS Dimension,
	|
	|	DocumentData.Sum                  AS Sum,
	|
	|	VALUE(Enum.MovementSourcesKinds.EmptyRef) AS SourceKind,
	|	VALUE(Enum.SourcesOfBalanceSheetStatement.EmptyRef) AS Source
	|
	|FROM
	|	Document.DepositsWithdrawalsByLineOfBusiness AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|// Withdrawal of own funds from the direction
	|SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	UNDEFINED                           AS Organization,
	|	UNDEFINED                           AS Department,
	|	DocumentData.SourceArea AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnFundsWithdrawals) AS AssetRef,
	|	UNDEFINED                           AS Dimension,
	|
	|	DocumentData.Sum                  AS Sum,
	|
	|	VALUE(Enum.MovementSourcesKinds.EmptyRef) AS SourceKind,
	|	VALUE(Enum.SourcesOfBalanceSheetStatement.EmptyRef) AS Source
	|
	|FROM
	|	Document.DepositsWithdrawalsByLineOfBusiness AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|// The arrival of indirect funds of the direction
	|SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	UNDEFINED                           AS Organization,
	|	UNDEFINED                           AS Department,
	|	DocumentData.DestinationArea  AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCashLineOfBusiness) AS AssetRef,
	|	UNDEFINED                           AS Dimension,
	|
	|	DocumentData.Sum                  AS Sum,
	|
	|	VALUE(Enum.MovementSourcesKinds.EmptyRef) AS SourceKind,
	|	VALUE(Enum.SourcesOfBalanceSheetStatement.EmptyRef) AS Source
	|
	|FROM
	|	Document.DepositsWithdrawalsByLineOfBusiness AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|// Putting your own funds in the direction of
	|SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	UNDEFINED                           AS Organization,
	|	UNDEFINED                           AS Department,
	|	DocumentData.DestinationArea  AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOwnFundsInvestments) AS AssetRef,
	|	UNDEFINED                           AS Dimension,
	|
	|	DocumentData.Sum                  AS Sum,
	|
	|	VALUE(Enum.MovementSourcesKinds.EmptyRef) AS SourceKind,
	|	VALUE(Enum.SourcesOfBalanceSheetStatement.EmptyRef) AS Source
	|
	|FROM
	|	Document.DepositsWithdrawalsByLineOfBusiness AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
