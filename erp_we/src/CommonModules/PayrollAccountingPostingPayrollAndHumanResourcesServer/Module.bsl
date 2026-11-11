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
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.TaxesContributionsHR);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.AccrualsHR);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.DeductionsHR);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.PayrollCalculationsHR);
		Parameters.SubordinateRegisters.Add(
				Metadata.AccumulationRegisters.DataOnEmployeeTimesheet);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.PayrollCalculationsHR);
		
	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.TaxesContributionsHR);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.AccrualsHR);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.DeductionsHR);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.PayrollCalculationsHR);
		Parameters.ControlRegistersBanDate.Add(
									Metadata.AccumulationRegisters.DataOnEmployeeTimesheet);
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
	
	QueriesTexts = New Map();
	
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
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements to the slave control registers repairs.
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
	
	RegisterName_ = "TaxesContributionsHR";
	If TablesForRegisteredRecords.Property("Table" + RegisterName_) Then
		For Each CurrentRow In TablesForRegisteredRecords["Table" + RegisterName_] Do 
			CurrentRow.RowID = New UUID;
		EndDo;	
	EndIf;		
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "TaxesContributionsHR");
	
	RegisterName_ = "DeductionsHR";
	If TablesForRegisteredRecords.Property("Table" + RegisterName_) Then
		For Each CurrentRow In TablesForRegisteredRecords["Table" + RegisterName_] Do 
			CurrentRow.RowID = New UUID;                                                 
		EndDo;
	EndIf;
		
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "DeductionsHR");

	RegisterName_ = "AccrualsHR";
	If TablesForRegisteredRecords.Property("Table" + RegisterName_) Then
		For Each CurrentRow In TablesForRegisteredRecords["Table" + RegisterName_] Do 
			CurrentRow.RowID = New UUID;  
			CalculationParameters = SetUpCalculationFormula.RestoreFormSettingsUsingCalculationFormula(
												CurrentRow.CalculationFormula);
			If CalculationParameters.UseCoefficient Then									
				CurrentRow.Sum = CurrentRow.Sum * CalculationParameters.ZoomRatio;
			EndIf;
		EndDo;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "AccrualsHR");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "PayrollCalculationsHR");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, 
			"DataOnEmployeeTimesheet");
	
EndProcedure

#EndRegion

#EndRegion
