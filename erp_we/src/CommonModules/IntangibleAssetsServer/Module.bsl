
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
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.IntangibleAssetsAmortizationCharge);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.IntangibleAssetsOperatingTime);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.IACost);
		
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.IntangibleAssetsRegistrationPlace);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.IADepreciationParametersBookkeepingAndTaxAccounting);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.IntangibleAssetAmortizationParametersManagementAccounting);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.InitialIntangibleAssetsInformation);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.IntangibleAssetsAccountingProcedure);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.IntangibleAssetsAccountingProcedureManagementAccounting);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.IntangibleAssetsAmortizationCharge);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.IntangibleAssetsOperatingTime);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.IACost);
		
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.IntangibleAssetsRegistrationPlace);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.IADepreciationParametersBookkeepingAndTaxAccounting);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.IntangibleAssetAmortizationParametersManagementAccounting);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.InitialIntangibleAssetsInformation);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.IntangibleAssetsAccountingProcedure);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.IntangibleAssetsAccountingProcedureManagementAccounting);
		
	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.IntangibleAssetsAmortizationCharge);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.IACost);
	EndIf;
		
	Parameters.IndependentRegisters.Add(Metadata.InformationRegisters.IntangibleAssetsDocuments);
	
	IntangibleAssetsLocalization.AddParametersForDocument(Parameters, Document, Properties);
	
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
	MatchingQueryTexts.Insert("IntangibleAssetsAmortizationChargeUpdate", AccumulationRegisters.IntangibleAssetsAmortizationCharge.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("IACostUpdate", AccumulationRegisters.IACost.RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of intangible assets.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "IntangibleAssetsAmortizationCharge");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "IntangibleAssetsOperatingTime");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "IACost");
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "IntangibleAssetsRegistrationPlace");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "IADepreciationParametersBookkeepingAndTaxAccounting");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "IntangibleAssetAmortizationParametersManagementAccounting");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "InitialIntangibleAssetsInformation");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "IntangibleAssetsAccountingProcedure");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "IABookkeepingProcedureBookkeepingAndTaxAccounting");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "IntangibleAssetsAccountingProcedureManagementAccounting");
	
	IntangibleAssetsLocalization.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel);
	
EndProcedure

// Procedure for forming movements in independent registers of intangible assets.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	Document - DocumentRef - link to the document
//	TempTablesManager - TempTablesManager - Manager temporary tables in the document
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure WriteData(TablesForRegisteredRecords, Document, TempTablesManager, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	TableName = "Table" + "IntangibleAssetsDocuments";
	
	If TablesForRegisteredRecords.Property(TableName) Then
		
		Set = InformationRegisters.IntangibleAssetsDocuments.CreateRecordSet();
		Set.Filter.Ref.Set(Document);
		Set.Load(TablesForRegisteredRecords[TableName]);
		Set.Write();
		
		InfobaseUpdateTM.MarkInteractiveProcessing(Set);
		
	EndIf;
	
	IntangibleAssetsLocalization.WriteData(TablesForRegisteredRecords, Document, TempTablesManager, Cancel);
	
EndProcedure

#EndRegion

#EndRegion