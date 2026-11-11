
#Region Internal

// Describes the accounting mechanisms used in the localized configuration.
//
// Parameters:
//  ConfigurationMechanisms - Structure - a list of accounting mechanisms,
//              where the Key is the name of the mechanism, and the Value is the module that implements the management interface.
//
Procedure SupplementConfigurationAccountingMechanisms(ConfigurationMechanisms) Export
	
	
EndProcedure

// Creates jobs on the pending motion on the basis of the performed movements for the registers.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//      used for storing register change control tables.
//
Procedure CreateTasksForDeferredRegisteredRecords(Document, TempTablesManager) Export
	
	
EndProcedure

// Replaces the standard document Manager module when receiving data for conducting,
// for cases when the standard Manager module cannot be used
// (for example, when integrating conducting into library documents).
// 
// Parameters:
//  DocumentModule - DocumentManager - default document Manager module.
//
Procedure ReassignDocumentDataAcquisitionModule(DocumentModule) Export
	
	
EndProcedure

#Region ComplementingMechanismsWithLocalizedDocuments

// Complements the parameters for conducting a document on the registers of the accounting mechanism.
//
// Parameters:
//   AdditionalDocuments_ - Structure - registers and documents that require movement and control
//
Procedure FillInLocalCollateralDocuments(AdditionalDocuments_) Export
	
	Return;
	
EndProcedure

// Complements the parameters for conducting a document on the registers of the accounting mechanism.
//
// Parameters:
//   AdditionalDocuments_ - Structure - registers and documents that require movement and control
//
Procedure FillInLocalDocumentsOfMovementOfGoods(AdditionalDocuments_) Export
	
	Return;
	
EndProcedure

#EndRegion

// Re-examination of official documents.
// 
// Parameters:
// 	Recorder - DocumentRef - current document
// 	
// Returns:
// 	Boolean - the result of the re-examination
//
Function RecheckDocumentsOnAccumulationRegister(Recorder) Export

	RestorationOfRegisteredRecordsIsPerformed = CalculationOfCostLocalization.RestoreMovementOfDocumentsInAccumulationRegister(Recorder);
	
	Return RestorationOfRegisteredRecordsIsPerformed;
	
EndFunction


#EndRegion
