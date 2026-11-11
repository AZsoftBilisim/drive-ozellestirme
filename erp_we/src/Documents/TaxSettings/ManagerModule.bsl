
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("PersonnelAccountingHR");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.TaxSettings") Then
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
		
		QueryTextNonTaxableAccrualsHR(Query, QueryTexts, Registers);
		QueryTextTableDeductions_HR(Query, QueryTexts, Registers);
		QueryTextTaxRatesHR(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Returns a list of available payment methods.
//
// Returns:
//   Structure - contains "key-value" pairs, where the key and value are the name of the accrual method:
//	* Automatically - String - name of the accrual method "Automatically"
//	* Manually - String - name of the accrual method "Manually"
//
Function ListOfAccrualMethods() Export
	
	List_AccrualMethods = New Structure();
	List_AccrualMethods.Insert("Automatically", "Automatically");
	List_AccrualMethods.Insert("Manually", "Manually");

	Return  List_AccrualMethods;

EndFunction
	
// Loads the list of available payment methods to the specified selection list.
//
// Parameters:
//   ListOfAccrualMethodsToSelect - Structure   - List to fill in with accrual methods
Procedure UploadListOfAccrualMethods(ListOfAccrualMethodsToSelect) Export
	
	ListOfAccrualMethods = ListOfAccrualMethods(); 
	
	ListOfAccrualMethodsToSelect.Clear();
	ListOfAccrualMethodsToSelect.Add(ListOfAccrualMethods.Automatically);
	ListOfAccrualMethodsToSelect.Add(ListOfAccrualMethods.Manually);
	
EndProcedure	

// Defines the accrual method depending on the automatic accrual flag.
//
// Parameters:
//   AccrueAutomatically - Boolean - indicates automatic accrual
//
// Returns:
//   Structure - contains the string:
//     * AccrualMethod - String - Accrual Method
//
Function DetermineAccrualMethod(AccrueAutomatically) Export
	
	ListOfAccrualMethods = ListOfAccrualMethods(); 
	
	If AccrueAutomatically Then
		
		Return  ListOfAccrualMethods.Automatically;
	EndIf;	
	
	Return ListOfAccrualMethods.Manually;	
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	Attributes.Ref AS Ref,
	|	Attributes.Date AS Date,
	|	Attributes.Number AS Number,
	|	Attributes.RegistrationMonth AS Period,
	|	Attributes.Organization AS Organization
	|FROM
	|	Document.TaxSettings AS Attributes
	|WHERE
	|	Attributes.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(Type("DocumentRef.HiringHR")));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
EndProcedure

#EndRegion

Function QueryTextNonTaxableAccrualsHR(Query, QueryTexts, Registers)
	
	RegisterName = "NonTaxableAccrualsHR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
		
	QueryText = 
	"SELECT
	|	TaxSettings.Organization AS Organization,
	|	TaxSettings.RegistrationMonth AS Period,
	|	TaxSettings.Ref AS DocumentRecorder
	|FROM
	|	Document.TaxSettings AS TaxSettings
	|WHERE
	|	TaxSettings.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDeductions_HR(Query, QueryTexts, Registers)
	
	RegisterName = "Deductions_HR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	QueryText = 
	"SELECT
	|	TaxSettings.Organization AS Organization,
	|	TaxSettings.RegistrationMonth AS Period,
	|	TaxSettings.Ref AS DocumentRecorder
	|FROM
	|	Document.TaxSettings AS TaxSettings
	|WHERE
	|	TaxSettings.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTaxRatesHR(Query, QueryTexts, Registers)
	
	RegisterName = "TaxRatesHR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	TaxSettings.Organization AS Organization,
	|	TaxSettings.RegistrationMonth AS Period,
	|	TaxSettings.Ref AS DocumentRecorder
	|FROM
	|	Document.TaxSettings AS TaxSettings
	|WHERE
	|	TaxSettings.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
