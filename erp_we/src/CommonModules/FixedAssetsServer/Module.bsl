
#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.FixedAssetsDepreciationCharge);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.FACost);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.InvestmentInRent);
		
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.FALocation);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.OSBUDepreciationParameters);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.FixedAssetDepreciationParametersManagementAccounting);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.InitialFixedAssetsInformation);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.FixedAssetsAccountingProcedure);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.AccountingProcedureForOSBU);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting);

		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.LeasedAsset);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.LeaseInterestAccrualSchedule);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.LeaseServicesAccrualSchedule);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.LeaseServicesPaymentSchedule);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.AssetsLeasedOut);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.TermsOfLeaseContracts);
		
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.ScheduleOfInterestChargesOnIncomeRental);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.ScheduleOfChargesForIncomeRentalServices);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.ScheduleOfPaymentsForIncomeRentalServices);
		
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.SubAssetsComponentsOfDepreciation);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.AssetActivityRecords);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.FixedAssetsDepreciationCharge);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.FACost);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.InvestmentInRent);
		
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.LeasedAsset);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.LeaseInterestAccrualSchedule);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.LeaseServicesPaymentSchedule);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.ScheduleOfInterestChargesOnIncomeRental);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.ScheduleOfPaymentsForIncomeRentalServices);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.FALocation);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.AssetActivityRecords);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.OSBUDepreciationParameters);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.FixedAssetDepreciationParametersManagementAccounting);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.InitialFixedAssetsInformation);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.FixedAssetsAccountingProcedure);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.AccountingProcedureForOSBU);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.SubAssetsComponentsOfDepreciation);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.TermsOfLeaseContracts);
		
	EndIf;
	
	
	Parameters.IndependentRegisters.Add(Metadata.InformationRegisters.FixedAssetsDocuments);
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.FixedAssetsDepreciationCharge);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.FACost);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.InvestmentInRent);
	EndIf;
	
	FixedAssetsLocalization.AddParametersForDocument(Parameters, Document, Properties);
	
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
	
	RegisterMetadata = Metadata.AccumulationRegisters.InvestmentInRent;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of fixed assets.
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
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "FixedAssetsDepreciationCharge");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "FACost");
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "FALocation");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "OSBUDepreciationParameters");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "FixedAssetDepreciationParametersManagementAccounting");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "InitialFixedAssetsInformation");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "FixedAssetsAccountingProcedure");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "AccountingProcedureForOSBU");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "FixedAssetsAccountingProcedureManagementAccounting");
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "InvestmentInRent");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ScheduleOfPaymentsForIncomeRentalServices");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ScheduleOfChargesForIncomeRentalServices");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ScheduleOfInterestChargesOnIncomeRental");
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "LeasedAsset");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "AssetsLeasedOut");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "TermsOfLeaseContracts");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "LeaseServicesPaymentSchedule");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "LeaseServicesAccrualSchedule");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "LeaseInterestAccrualSchedule");
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "AssetActivityRecords");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "SubAssetsComponentsOfDepreciation");

	FixedAssetsLocalization.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel);
	
EndProcedure

// Procedure for forming movements in independent registers of fixed assets.
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
	
	TableName = "Table" + "FixedAssetsDocuments";
	
	If TablesForRegisteredRecords.Property(TableName) Then
		
		Set = InformationRegisters.FixedAssetsDocuments.CreateRecordSet();
		Set.Filter.Ref.Set(Document);
		Set.Load(TablesForRegisteredRecords[TableName]);
		Set.Write();
		
		InfobaseUpdateTM.MarkInteractiveProcessing(Set);
		
	EndIf;
	
	FixedAssetsLocalization.WriteData(TablesForRegisteredRecords, Document, TempTablesManager, Cancel);
	
EndProcedure

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
	MatchingQueryTexts.Insert("FixedAssetsDepreciationChargeUpdate", AccumulationRegisters.FixedAssetsDepreciationCharge.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("FACostUpdate", AccumulationRegisters.FACost.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("InvestmentInRentUpdate", AccumulationRegisters.InvestmentInRent.RequestTextMonitoringBanDate(Query));
	
	Return MatchingQueryTexts;
	
EndFunction

#EndRegion

#EndRegion
