#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("PersonnelAccountingHR");
	DocumentMechanisms.Add("DocumentsRegistry");
	
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
	
	If TypeOf(Document) = Type("DocumentObject.DismissalHR") Then
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
		
		QueryTextPersonnelHistory(Query, QueryTexts, Registers);
		QueryTextTableRegularAccrualsAndDeductions(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

#EndRegion

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
	|	ENDOFPERIOD(Attributes.DateOfDismissal, DAY) AS Period,
	|	Attributes.Organization AS Organization,
	|	Attributes.Department AS Department,
	|	Attributes.Employee AS Employee,
	|	Attributes.EmploymentKind,
	|	Attributes.WorkScheduleCalendar
	|FROM
	|	Document.DismissalHR AS Attributes
	|WHERE
	|	Attributes.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(Type("DocumentRef.DismissalHR")));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
EndProcedure

// Returns the adapted Query Text of Registered Records by case
// 
// Parameters:
//  RegisterName - String - Name of the register for receiving the adapted request 
// 
// Returns:
//  See InfobaseUpdateTM.ResultOfRequestAdaptation
//
Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.DismissalHR";
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.DismissalHR"));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText, FullDocumentName, SynonymForDocumentTable, True);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction
#EndRegion

Function QueryTextTableRegularAccrualsAndDeductions(Query, QueryTexts, Registers)
	
	RegisterName = "RegularAccrualsAndDeductionsHR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
		
	QueryText = 
	"SELECT
	|	DismissalHR.Organization AS Organization,
	|	DismissalHR.Department AS Department,
	|	DismissalHR.Employee AS Employee,
	|	RegularAccrualsAndDeductionsHRSliceLast.Value AS Value,
	|	FALSE AS Valid,
	|	TRUE AS BasicEarnings,
	|	DismissalHR.DateOfDismissal AS Period,
	|	RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction AS AccrualDeduction
	|FROM
	|	Document.DismissalHR AS DismissalHR
	|		LEFT JOIN InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(&Period, Organization = &Organization
	|		AND Employee = &Employee
	|		AND Department = &Department
	|		AND BasicEarnings) AS RegularAccrualsAndDeductionsHRSliceLast
	|		ON RegularAccrualsAndDeductionsHRSliceLast.Organization = DismissalHR.Organization
	|		AND RegularAccrualsAndDeductionsHRSliceLast.Department = DismissalHR.Department
	|		AND RegularAccrualsAndDeductionsHRSliceLast.Employee = DismissalHR.Employee
	|WHERE
	|	DismissalHR.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	RegularAccrualsAndDeductionsHRSliceLast.Organization,
	|	RegularAccrualsAndDeductionsHRSliceLast.Department,
	|	RegularAccrualsAndDeductionsHRSliceLast.Employee,
	|	RegularAccrualsAndDeductionsHRSliceLast.Value,
	|	FALSE,
	|	FALSE,
	|	&Period,
	|	RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(&Period, Organization = &Organization
	|	AND Employee = &Employee
	|	AND Department = &Department
	|	AND NOT BasicEarnings) AS RegularAccrualsAndDeductionsHRSliceLast";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextPersonnelHistory(Query, QueryTexts, Registers)
	
	RegisterName = "EmploymentRecord";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	

	QueryText =
	"SELECT
	|	DismissalHR.Organization AS Organization,
	|	DismissalHR.Department AS Department,
	|	DismissalHR.DateOfDismissal AS Period,
	|	DismissalHR.Employee AS Employee,
	|	DismissalHR.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	DismissalHR.JobTitle AS JobTitle,
	|	DismissalHR.Currency AS Currency,
	|	EmploymentRecordSliceLast.EndDate AS EndDate,
	|	VALUE(Enum.HREventKindsPayrollAndHumanResources.Dismissal) AS EventKind,
	|	FALSE AS WorksInBusinessUnit,
	|	DismissalHR.EmploymentKind
	|FROM
	|	Document.DismissalHR AS DismissalHR
	|		LEFT JOIN InformationRegister.EmploymentRecord.SliceLast(&Period, Organization = &Organization
	|		AND Employee = &Employee
	|		AND Department = &Department) AS EmploymentRecordSliceLast
	|		ON EmploymentRecordSliceLast.Organization = DismissalHR.Organization
	|		AND EmploymentRecordSliceLast.Department = DismissalHR.Department
	|		AND EmploymentRecordSliceLast.Employee = DismissalHR.Employee
	|		AND EmploymentRecordSliceLast.JobTitle = DismissalHR.JobTitle
	|WHERE
	|	DismissalHR.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	UNDEFINED AS RecordSeparator,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	DocumentData.Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.PieceworkRegistration) AS BusinessOperation,
	|	UNDEFINED AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	"""" AS More,
	|	DocumentData.Date AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	UNDEFINED AS StorageLocation,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	DocumentData.Date AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.DismissalHR AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Read", Metadata.Documents.WorkOutput) Then
		DismissalHRLocalization.AddPrintCommands(PrintCommands);
	EndIf;
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	DismissalHRLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

