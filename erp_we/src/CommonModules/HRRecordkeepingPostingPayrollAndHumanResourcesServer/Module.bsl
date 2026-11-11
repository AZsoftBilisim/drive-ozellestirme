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
		
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.EmploymentRecord);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.RegularAccrualsAndDeductionsHR);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.Deductions_HR);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.NonTaxableAccrualsHR);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.TaxRatesHR);
		
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
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "EmploymentRecord");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "RegularAccrualsAndDeductionsHR");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "Deductions_HR");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "NonTaxableAccrualsHR");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "TaxRatesHR");
	
EndProcedure

// The procedure checks the availability of personnel records for an employee after the date of admission or transfer
//
// Parameters:
//	Employee - CatalogRef.EmployeesHR - the employee for whom you need to check the personnel history
//	Organization - CatalogRef.Companies - The company that the employee was admitted to
//	Date - Date - date of acceptance or transfer
//  DocumentObject - DocumentObject - recordable document
//	Cancel - Boolean - a sign of refusal to cancel the document.
//
Procedure ControlOfCancellationOfPersonnelDocument(Employee, Organization, Date, DocumentObject, Cancel) Export
	
	Query = New Query(
	"SELECT TOP 1
	|	EmploymentRecord.Period AS Period
	|FROM
	|	InformationRegister.EmploymentRecord AS EmploymentRecord
	|WHERE
	|	EmploymentRecord.Employee = &Employee
	|	AND EmploymentRecord.Organization = &Organization
	|	AND EmploymentRecord.Period > &Date
	|
	|ORDER BY
	|	EmploymentRecord.Period DESC");
	
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Date", Date);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then 
		
		MessageText = NStr("ru = 'Отмена проведения не выполнена, сотрудник %1 уже уволен или переведен';
							|vi = 'Cannot cancel posting, employee %1 is already dismissed or transferred';
							|en = 'Cannot cancel posting, employee %1 is already dismissed or transferred'; fa = 'Cannot cancel posting, employee %1 is already dismissed or transferred';
							|it = 'Cannot cancel posting, employee %1 is already dismissed or transferred';
							|pl = 'Cannot cancel posting, employee %1 is already dismissed or transferred';
							|tr = 'Kaydın iptali gerçekleştirilemedi, %1 çalışanı zaten işten çıkarılmış veya transfer edilmiş'");
		
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(MessageText, Employee), DocumentObject, , ,Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
