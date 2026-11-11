
#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Parameters - See DocumentsPosting.ParametersOfAccountingMechanism
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
Procedure AddParametersForDocument(Parameters, Document, Properties) Export
	
	
EndProcedure

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
	
EndProcedure

#EndRegion

#EndRegion
