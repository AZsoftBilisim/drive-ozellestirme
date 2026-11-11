//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Rebates");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef.WriteOffVendorRebates, DocumentObject.WriteOffVendorRebates - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//	ValueList of String - a list of values containing query texts and their names.
//						Returned if the 'Get Request texts' property of the Dopparameters parameter
//						is set to True.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.WriteOffVendorRebates") Then
		
		DocumentObject = Document;
		DocumentRef = Document.Ref;
		
	Else
		
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
		
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList; // ValueList of String
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextTableVendorRebates(QueryTexts, Registers, DocumentObject);
		
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Adds a Command to create a document "Accrual of retro customer bonuses".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
//
Function AddGenerateCommand(GenerationCommands, Parameters) Export
	
	Result = Undefined;
	
	If AccessRight("Insert", Metadata.Documents.WriteOffVendorRebates) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.WriteOffVendorRebates.FullName();
		CreateBasedOnCommand.Presentation = Metadata.Documents.WriteOffVendorRebates.Synonym;
		CreateBasedOnCommand.WriteMode = "Post";
		
		Result = CreateBasedOnCommand;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Description of the logic of access rights restrictions
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array of String - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array; // Array of String
	
	NotAttributesToEdit.Add("*");
		
	Return NotAttributesToEdit;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	If GetFunctionalOption("DisplayFullNamesOfVendorRebates") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	
EndProcedure

// Parameters:
//  Data - Structure - Document data:
//  * Ref - DocumentRef.WriteOffVendorRebates
//  * Number - String -
//  * Date - Date
//  Presentation - String - Presentation
//  StandardProcessing - Boolean - Standard treatment
//
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If GetFunctionalOption("DisplayFullNamesOfVendorRebates") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If Data.Ref <> Undefined Then
		
		Presentation = RebatesServerCall.DocumentTitle(
			Data.Ref,
			Data.Number,
			Data.Date);
		
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Other

// Returns:
//  String
//
Function DocumentHeaderTemplate() Export
	
	If GetFunctionalOption("DisplayFullNamesOfVendorRebates") Then
		
		DocumentHeaderTemplate = NStr("vi = 'Giảm thưởng lũy kế của nhà cung cấp %1';
										|ru = 'Списание ретро-бонусов поставщика %1';
										|en = 'Write off %1 vendor rebates'; fa = 'Write off %1 vendor rebates';
										|it = 'Списание ретро-бонусов поставщика %1';
										|pl = 'Write off %1 vendor rebates';
										|tr = '%1 tedarikçisinin retro bonusu ayrıntıları'");
		
	Else
		
		DocumentHeaderTemplate = NStr("vi = 'Giảm thưởng lũy kế của nhà cung cấp %1';
										|ru = 'Списание ретро-бонусов поставщика %1';
										|en = 'Write off %1 vendor rebates'; fa = 'Write off %1 vendor rebates';
										|it = 'Списание ретро-бонусов поставщика %1';
										|pl = 'Write off %1 vendor rebates';
										|tr = '%1 tedarikçisinin retro bonusu ayrıntıları'");
		
	EndIf;
	
	Return DocumentHeaderTemplate;
	
EndFunction

#EndRegion

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Attributes = DocumentAttributes(Query);
	
	Query.SetParameter("Period", Attributes.Date);
	Query.SetParameter("Status", Attributes.Status);
	Query.SetParameter("Organization", Attributes.Organization);
	Query.SetParameter("Currency", Attributes.Currency);
	Query.SetParameter("Counterparty", Attributes.Counterparty);
	
EndProcedure

// The details of the document
// 
// Parameters:
//  Query - Query - Query
// 
// Returns:
//  QueryResultSelection - The details of the document:
// * Date - Date -  
// * Number - String -
// * Status - EnumRef.RebatesDocumentStatuses - 
// * Organization - CatalogRef.Companies -
// * Currency - CatalogRef.Currencies -
// * Counterparty - CatalogRef.Counterparties -
//
Function DocumentAttributes(Query)
	
	Query.Text =
	"SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.Status AS Status,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Counterparty AS Counterparty
	|FROM
	|	DocumentDataHeader AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Return Attributes;
	
EndFunction

Function QueryTextTableVendorRebates(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "VendorRebates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers)
	 Or (DocumentObject.Status <> Enums.RebatesDocumentStatuses.AwaitingApproval
		  And DocumentObject.Status <> Enums.RebatesDocumentStatuses.Approved) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(Enum.AccumulationRecordTypes.Expense) AS TypeOfRegisterMovement,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	TableData.Partner AS Partner,
	|	TableData.Contract AS Contract,
	|	TableData.BeginOfPeriod AS BeginOfPeriod,
	|	TableData.PeriodEnding AS PeriodEnding,
	|	TableData.TermDocument AS TermDocument,
	|	TableData.Currency AS Currency,
	|	TableData.Sum AS WrittenOff,
	|	0 AS ToWriteOff
	|FROM
	|	DocumentDataTableDecodingOfDebits AS TableData
	|WHERE
	|	TableData.Ref = &Ref
	|	AND &Status = VALUE(Enum.RebatesDocumentStatuses.Approved)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.AccumulationRecordTypes.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	TableData.Partner AS Partner,
	|	TableData.Contract AS Contract,
	|	TableData.BeginOfPeriod AS BeginOfPeriod,
	|	TableData.PeriodEnding AS PeriodEnding,
	|	TableData.TermDocument AS TermDocument,
	|	TableData.Currency AS Currency,
	|	0 AS WrittenOff,
	|	TableData.Sum AS ToWriteOff
	|FROM
	|	DocumentDataTableDecodingOfDebits AS TableData
	|WHERE
	|	TableData.Ref = &Ref
	|	AND &Status = VALUE(Enum.RebatesDocumentStatuses.AwaitingApproval)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region DocumentData

Procedure GetDocumentData(Query, DocumentRef)
	
	ListOfRequests = New Array; // Array of String
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDataTableDecryptionOfDebits(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.Status AS Status,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible
	|INTO DocumentDataHeader
	|FROM
	|	Document.WriteOffVendorRebates AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTableDecryptionOfDebits(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Partner AS Partner,
	|	DataTable.Contract AS Contract,
	|	DataTable.TermDocument AS TermDocument,
	|	DataTable.BeginOfPeriod AS BeginOfPeriod,
	|	DataTable.PeriodEnding AS PeriodEnding,
	|	DataTable.Sum AS Sum,
	|	DataTable.Currency AS Currency
	|INTO DocumentDataTableDecodingOfDebits
	|FROM
	|	Document.WriteOffVendorRebates.DrillDownDebits AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf