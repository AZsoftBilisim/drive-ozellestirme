#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the parameters of the check the rules of reflection
//
// Returns:
// 	Structure - verification parameters:
// 		* ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - Selecting the chart of accounts for verification. If Undefined, then for all.
// 		* Organization - CatalogRef.Companies - Selecting an organization for verification. If Undefined, then for all.
// 		* Document - DocumentRef - Selecting a document for verification. If Undefined, then for all.
//
Function ParametersForCheckingReflectionRules() Export
	
	CheckParameters = New Structure;
	CheckParameters.Insert("ChartOfAccounts");
	CheckParameters.Insert("Organization");
	CheckParameters.Insert("Document");
	
	Return CheckParameters;
	
EndFunction


// Checks the settings for international accounting reflection rules
//
// Parameters:
// 	 CheckParameters - See ParametersForCheckingReflectionRules
//
// Returns:
//	Structure - A structure containing:
//		* BusinessTransactionsWithoutRecordingRules - See FinancialAccountingUponOperationalAccountingData.CheckRecordingRules
//		* AccountsWithoutRecordingRules - See FinancialAccountingUponLocalAccounting.CheckRecordingRules
//		* AccountingObjectsThatRequireConfiguration - See FinancialAccountingByFinancialRegisterData.CheckRecordingRules
Function CheckAccountingRulesSettings(CheckParameters) Export
	
	SetPrivilegedMode(True);
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT
	|	DocumentReflection.Recorder AS Recorder,
	|	DocumentReflection.Period AS Period,
	|	DocumentReflection.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentReflection.Organization AS Organization,
	|	DocumentReflection.DateRecord AS DateRecord,
	|	MAX(FinancialAccountingChartsOfAccountsForCompanies.Period) AS PeriodForSettingUpTransactionGeneration
	|INTO DocumentReflection
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentReflection
	|		INNER JOIN InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
	|		ON DocumentReflection.ChartOfAccounts = FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts
	|			AND DocumentReflection.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
	|			AND DocumentReflection.DateRecord >= FinancialAccountingChartsOfAccountsForCompanies.Period
	|WHERE
	|	(DocumentReflection.Recorder = &Document
	|			OR &Document = UNDEFINED)
	|	AND (DocumentReflection.ChartOfAccounts = &ChartOfAccounts
	|			OR &ChartOfAccounts = UNDEFINED)
	|	AND (DocumentReflection.Organization = &Organization
	|			OR &Organization = UNDEFINED)
	|	AND DocumentReflection.Status IN (
	|		VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting), 
	|		VALUE(Enum.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined))
	|
	|GROUP BY
	|	DocumentReflection.Recorder,
	|	DocumentReflection.Period,
	|	DocumentReflection.ChartOfAccounts,
	|	DocumentReflection.Organization,
	|	DocumentReflection.DateRecord
	|
	|INDEX BY
	|	ChartOfAccounts,
	|	Organization,
	|	PeriodForSettingUpTransactionGeneration
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsToBeReflected.Recorder AS Recorder,
	|	DocumentsToBeReflected.Period AS Period,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.Organization AS Organization,
	|	DocumentsToBeReflected.DateRecord AS DateRecord,
	|	FinancialAccountingChartsOfAccountsForCompanies.PostingGenerationSetting AS PostingGenerationSetting
	|INTO DocumentsToBeReflected
	|FROM
	|	DocumentReflection AS DocumentsToBeReflected
	|		LEFT JOIN InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
	|		ON DocumentsToBeReflected.ChartOfAccounts = FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts
	|			AND DocumentsToBeReflected.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
	|			AND DocumentsToBeReflected.PeriodForSettingUpTransactionGeneration = FinancialAccountingChartsOfAccountsForCompanies.Period
	|
	|INDEX BY
	|	DocumentsToBeReflected.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DocumentReflection";
	Query.SetParameter("ChartOfAccounts", CheckParameters.ChartOfAccounts);
	Query.SetParameter("Organization", CheckParameters.Organization);
	Query.SetParameter("Document", CheckParameters.Document);
	Query.Execute();
	
	OperationsWithoutReflectionRules = FinancialAccountingUponOperationalAccountingData.CheckRecordingRules(TempTablesManager, CheckParameters);
	AccountsWithoutRecordingRules    = FinancialAccountingUponLocalAccounting.CheckRecordingRules(TempTablesManager, CheckParameters);
	AccountingObjectsThatRequireConfiguration = FinancialAccountingByFinancialRegisterData.CheckRecordingRules(TempTablesManager, CheckParameters);
	
	Result = New Structure;
	Result.Insert("BusinessTransactionsWithoutRecordingRules", OperationsWithoutReflectionRules);
	Result.Insert("AccountsWithoutRecordingRules", AccountsWithoutRecordingRules);
	Result.Insert("AccountingObjectsThatRequireConfiguration", AccountingObjectsThatRequireConfiguration);
	
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// Returns parameters for counting the number of checked/unverified documents
//
// Returns:
// 	Structure - Parameters For Counting The Number Of Documents:
// 		* CompanyArray - CatalogRef.Companies, Array of CatalogRef.Companies - Selection by organizations for counting.
// 		* EndingDateOfPeriod - Date - Selection by Date for counting
// 		* ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - Selection of the chart of accounts for calculation.
// 		* JobKind - EnumRef.StatusOfFinancialDocumentVerification - type of documents to be counted ("Verified", "unverified" or "repeated verification")
//
Function ParametersForCountingNumberOfDocuments() Export
	
	Parameters = New Structure;
	Parameters.Insert("CompanyArray", New Array);
	Parameters.Insert("EndingDateOfPeriod", Date(1,1,1,0,0,0));
	Parameters.Insert("ChartOfAccounts", Catalogs.FinancialAccountingChartsOfAccounts.EmptyRef());
	Parameters.Insert("JobKind", Enums.StatusOfFinancialDocumentVerification.EmptyRef());
	
	Return Parameters;
	
EndFunction

// Returns an array of document types for selecting documents in international accounting
//
// Returns:
// 	Array of Type - Array of document types
//
Function TypesOfDocumentsForSelection() Export
	
	ArrayOfDocumentTypes_ = New Array;
	MetadataReflectionOfDocumentsInInternationalAccounting = Metadata.InformationRegisters.DocumentPostingInFinancialAccounting;
	For Each MetadataObject In Metadata.Documents Do
		If Not MetadataObject.RegisterRecords.Contains(MetadataReflectionOfDocumentsInInternationalAccounting) Then
			Continue;
		EndIf;
		ArrayOfDocumentTypes_.Add(Type("DocumentRef." + MetadataObject.Name));
	EndDo;
	
	Return ArrayOfDocumentTypes_;
	
EndFunction

// Counts the number of verified/unverified documents
//
// Parameters:
// 	 Parameters - See ParametersForCountingNumberOfDocuments
//
// Returns:
//	QueryResult - The result of the query
Function DocumentVerificationStatus(Parameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	&TextOfStartDateField AS StartDate,
	|	COUNT(1) AS Count
	|FROM
	|	InformationRegister.StatusOfDocumentVerification AS StatusOfDocumentVerification
	|WHERE
	|	StatusOfDocumentVerification.Organization IN(&CompanyArray)
	|	AND StatusOfDocumentVerification.Period <= &EndDate
	|	AND StatusOfDocumentVerification.CheckStatus IN (&CheckStatus)
	|	AND NOT VALUETYPE(StatusOfDocumentVerification.Document) IN (&ExcludedTypesToCheck)";
	
	Query.SetParameter("CompanyArray", Parameters.CompanyArray);
	Query.SetParameter("EndDate", ?(ValueIsFilled(Parameters.EndingDateOfPeriod), Parameters.EndingDateOfPeriod, Date(2399, 1, 1)));
	
	Query.Text = StrReplace(Query.Text, "&ExcludedTypesToCheck", DocumentVerificationServer.TypesOfUnverifiableDocumentsByString());
	
	Query.SetParameter("CheckStatus", Parameters.JobKind);
	
	If Parameters.JobKind = Enums.StatusOfFinancialDocumentVerification.Verified Then
		
		TextOfStartDateField = "MAX(StatusOfDocumentVerification.Period)";
		
	ElsIf Parameters.JobKind = Enums.StatusOfFinancialDocumentVerification.NotVerified 
		Or Parameters.JobKind = Enums.StatusOfFinancialDocumentVerification.ToReCheck Then
			
		TextOfStartDateField = "MIN(StatusOfDocumentVerification.Period)";
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&TextOfStartDateField", TextOfStartDateField);
	
	Return Query.Execute();
	
EndFunction

#EndRegion

#EndIf