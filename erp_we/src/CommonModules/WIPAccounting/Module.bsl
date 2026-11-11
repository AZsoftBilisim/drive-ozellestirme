
#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.OtherWorkInProgressExpenses);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.WIPLaborCosts);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.OtherWorkInProgressExpenses);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.WIPLaborCosts);
		
	EndIf;
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.OtherWorkInProgressExpenses);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.WIPLaborCosts);
	EndIf;
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.OtherWorkInProgressExpenses;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		AdditionalTermsAndConditions = "
		|	NOT RegisterData.CalculationOfCost
		|	AND NOT RegisterData.LotCalculation
		|";	
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument, AdditionalTermsAndConditions));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.WIPLaborCosts;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		AdditionalTermsAndConditions = "
		|	NOT RegisterData.LotCalculation
		|";
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument, AdditionalTermsAndConditions));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("ChangesTableOtherWorkInProgressExpenses", 
		AccumulationRegisters.OtherWorkInProgressExpenses.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("ChangesTableWIPLaborCosts", 
		AccumulationRegisters.WIPLaborCosts.RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of the accounting estimate.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "OtherWorkInProgressExpenses");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "WIPLaborCosts");
	
EndProcedure

#EndRegion

#EndRegion