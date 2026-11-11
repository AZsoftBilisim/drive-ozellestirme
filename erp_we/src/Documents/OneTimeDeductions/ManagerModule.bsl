
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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)";

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
	
	DocumentMechanisms.Add("PayrollAccountingHR");
	
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
	
	If TypeOf(Document) = Type("DocumentObject.OneTimeDeductions") Then
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
		
		QueryTextTaxesContributionsHR(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Sets up filling in credentials for one-time deductions.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the document containing the object to configure
//
Procedure SetUpRegistrationForm(Form) Export
	
	Object = Form.Object;
	FilterTable = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.NewFilterTable();
	
	Retention = Object.Retention;
	Department = Object.Department;
	DocumentCalculation = Object.Ref;
	
	DeductedByEmployees = Object.DeductedByEmployees;
	For Each CurrentLineWithheldByEmployees In DeductedByEmployees Do
		Employee = CurrentLineWithheldByEmployees.Employee;
		
		NewRow = FilterTable.Add();
		NewRow.TypeOfAccrualDeduction = Retention; 
		NewRow.Department = Department; 
		NewRow.DocumentCalculation = DocumentCalculation; 
		NewRow.Employee = Employee; 
		NewRow.RowIndex = DocumentsPayrollAndHumanResourcesServer.GetRowIndex(CurrentLineWithheldByEmployees, 
																								DeductedByEmployees);
		
	EndDo;	

	ResultTableByFilter = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetFilterResult(
																FilterTable, Object.RegistrationMonth);
	
	// Filling in the tabular part is accrued to employees
	DetailsOfFillingInForm = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.AttributesOfFillingOutForm();
	DetailsOfFillingInForm.FilterTable = FilterTable;
	DetailsOfFillingInForm.ResultTableByFilter = ResultTableByFilter;
	DetailsOfFillingInForm.ItIsADeduction = True;
	DetailsOfFillingInForm.FilterDate = Object.RegistrationMonth;
	DetailsOfFillingInForm.RecordingSettingPresentation = "ReflectionInAccounting_Presentation";
	DetailsOfFillingInForm.ReflectionSettingIsCorrect = "ReflectionInAccountingIsCorrect";
	DetailsOfFillingInForm.ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingAccruals();

    SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.FillInAddedDetailsOfTablePart(
											Form, DetailsOfFillingInForm, "DeductedByEmployees");
	
EndProcedure	

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
	|	Document.OneTimeDeductions AS Attributes
	|WHERE
	|	Attributes.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(
																		Type("DocumentRef.HiringHR")));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
EndProcedure

#EndRegion

Function QueryTextTaxesContributionsHR(Query, QueryTexts, Registers)
	
	RegisterName = "DeductionsHR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
		
	QueryText = 
	"SELECT
	|	OneTimeDeductionsDeductedByEmployees.Employee.Individual AS Individual,
	|	OneTimeDeductionsDeductedByEmployees.Sum AS Sum,
	|	OneTimeDeductions.RegistrationMonth AS Period,
	|	OneTimeDeductions.Organization AS Organization,
	|	OneTimeDeductions.Department AS Department,
	|	OneTimeDeductions.Retention AS Retention,
	|	TRUE AS ManualDeduction,
	|	UNDEFINED AS RowID,
	|	OneTimeDeductionsDeductedByEmployees.Employee AS Employee,
	|	ENDOFPERIOD(OneTimeDeductions.RegistrationMonth, MONTH) AS PeriodEnding
	|FROM
	|	Document.OneTimeDeductions.DeductedByEmployees AS OneTimeDeductionsDeductedByEmployees
	|		RIGHT JOIN Document.OneTimeDeductions AS OneTimeDeductions
	|		ON OneTimeDeductionsDeductedByEmployees.Ref = OneTimeDeductions.Ref
	|WHERE
	|	OneTimeDeductions.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
