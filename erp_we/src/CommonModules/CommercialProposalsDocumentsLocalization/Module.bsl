////////////////////////////////////////////////////////////////////////////////
// Subsystem "Objects UT11, KA2, UP2".
// General module.Commercial propositiondocumentlocalization.
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region InitializingDocuments

// See CommercialProposalsDocumentsOverridable.ProcessingDocumentFilling.
//
Procedure ProcessingDocumentFilling(Object, FillingData, FillingText, StandardProcessing) Export


EndProcedure

// See CommercialProposalsDocumentsOverridable.WhenFillingInListOfCurOfBusinessCommercialOffers
//
// Parameters:
//  ToDoList - See CommercialProposalsDocumentsOverridable.WhenFillingInListOfCurOfBusinessCommercialOffers.ToDoList
//  DocumentName - See CommercialProposalsDocumentsOverridable.WhenFillingInListOfCurOfBusinessCommercialOffers.DocumentName
//
Procedure WhenFillingInListOfCurOfBusinessCommercialOffers(ToDoList, DocumentName) Export

	
EndProcedure

#EndRegion

#Region ObtainingInformationBaseData

Procedure FillInAddressInformation(FieldValues, DeliveryAddress) Export
	

EndProcedure

Procedure OffersFromSourcesOnRequestForCommercialOffers(Val ObjectReference, Val AnalyzedSources, FoundOffers) Export
	
	
EndProcedure

Procedure OnAddReportsCommands(ObjectName, ReportsCommands, Parameters) Export
	
	
EndProcedure

// Filling in parts of the entrepreneur's first name (Surname, First name, patronymic).
// 
// Parameters:
// 	FullName - String - name of the client.
// 	ParticipantData - Structure - data to fill in::
// 	  * LastName - String
// 	  * Name - String
// 	  * MiddleName - String
// 	
Procedure  FillInPartsOfEntrepreneurSName(Val FullName, ParticipantData) Export
	
	
EndProcedure

// Returns the flag for using the functionality of requests for commercial offers.
// 
// Returns:
//  Boolean
Function UseRequestsForCommercialOffersFromSuppliers() Export
	
	ReturnValue = False;
	
	
	Return ReturnValue;

EndFunction

// Fills in the purchase conditions in the table for commercial offers:
// 
// Parameters:
//  Goods - ValueTable, FormDataCollection - In which you need to fill in the prices and their source (partner, counterparty, VAT rate).
//  FillParameters - See CommercialProposalsDocumentsTM.ParametersForFillingInTermsOfPurchaseForCommercialOffers
// 
// Returns:
//  Structure:
// * Cancel - Boolean - If it is cocked, then the prices cannot be filled in, the reason for the error is indicated in the "Text errors".
// * ErrorText - String - Filled in if the "Failure" flag is set. Information about the reason why prices cannot be filled in.
// * LineNumbersWithBlankPurchaseConditions - Array of Number - line numbers for which there are no purchase conditions.
// * ModifiedRows - Array of ValueTableRow, FormDataCollectionItem - Changed (and added) rows of the table part.
Function FillInTermsOfPurchaseBasedOnCommercialOffers(Goods, FillParameters) Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Cancel", True);
	ReturnValue.Insert("ErrorText", NStr("ru = 'Функционал отсутствует в системе.';
										|vi = 'The functionality is missing in the system.';
										|en = 'The functionality is missing in the system.'; fa = 'The functionality is missing in the system.';
										|it = 'The functionality is missing in the system.';
										|pl = 'The functionality is missing in the system.';
										|tr = 'Sistemde fonksiyonellik mevcut değil'"));
	ReturnValue.Insert("LineNumbersWithBlankPurchaseConditions", New Array);
	ReturnValue.Insert("ModifiedRows", New Array);
	
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#Region AccessManagement

// See CommercialProposalsDocumentsOverridable.OnFillMetadataObjectsAccessRestrictionKinds.
//
Procedure OnFillMetadataObjectsAccessRestrictionKinds(ObjectName, LongDesc) Export
	
	
EndProcedure
	
// See CommercialProposalsDocumentsOverridable.OnFillAccessRestriction.
//
Procedure OnFillAccessRestriction(ObjectName, Restriction) Export

	
EndProcedure

#EndRegion

#Region FormEventHandlers

// See CommercialProposalsDocumentsOverridable.OnCreateAtServer.
//
// Parameters:
//  Form - See CommercialProposalsDocumentsOverridable.OnCreateAtServer.Form
//  Cancel - See CommercialProposalsDocumentsOverridable.OnCreateAtServer.Cancel
//  StandardProcessing - See CommercialProposalsDocumentsOverridable.OnCreateAtServer.StandardProcessing
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export 
	
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(Form);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.AfterWriteAtServer.
//
Procedure AfterWriteAtServer(Form, CurrentObject) Export


EndProcedure

// See CommercialProposalsDocumentsOverridable.FillCheckProcessing.
//
// Parameters:
//  DocumentObject - See CommercialProposalsDocumentsOverridable.FillCheckProcessing.DocumentObject
//  Cancel - See CommercialProposalsDocumentsOverridable.FillCheckProcessing.Cancel
//  CheckedAttributes - See CommercialProposalsDocumentsOverridable.FillCheckProcessing.CheckedAttributes
//  NotCheckedAttributeArray - See CommercialProposalsDocumentsOverridable.FillCheckProcessing.NotCheckedAttributeArray
//
Procedure FillCheckProcessing(DocumentObject, Cancel, CheckedAttributes, NotCheckedAttributeArray) Export
	
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.Posting.
//
Procedure Posting(DocumentObject, Cancel, PostingMode) Export

	
EndProcedure

// See CommercialProposalsDocumentsOverridable.UndoPosting.
//
Procedure UndoPosting(DocumentObject, Cancel) Export
	
	
EndProcedure

#EndRegion

#Region DocumentEventHandlers

// See CommercialProposalsDocumentsOverridable.OnWrite.
//
Procedure OnWrite(DocumentObject, Cancel) Export
	
	
EndProcedure

// See CommercialProposalsDocumentsOverridable.BeforeWrite.
//
Procedure BeforeWrite(DocumentObject, Cancel, WriteMode, PostingMode) Export
	
	
EndProcedure

#EndRegion

#Region ConditionalAppearance

// See CommercialProposalsDocumentsOverridable.WhenSettingConditionalAppearance
//
Procedure WhenSettingConditionalAppearance(Form) Export
	
	
EndProcedure

#EndRegion

#Region CommercialProposalForCustomer

Procedure CommercialOfferToClientFillingProcessing(Object, FillingData, FillingText, StandardProcessing) Export
	
	
EndProcedure

Function BaseTypeCommercialOfferToClientByDefault() Export

	Result = Type("Undefined");
	
	Return Result;
	
EndFunction

#EndRegion

#Region GenerationCommands

// Defines a list of creation commands based on.
//
// Parameters:
//   ObjectName - String - name of the object to add commands to.
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(ObjectName, GenerationCommands, Parameters) Export
	
	
EndProcedure

// Adds a command to create a document based on.
//
// Parameters:
//   ObjectName - String - the name of the metadata object.
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//   FormItems, Undefined - contains a description of the added command.
//
Function AddGenerateCommand(ObjectName, GenerationCommands) Export
	
	
	Return Undefined;
	
EndFunction


#EndRegion

#EndRegion

