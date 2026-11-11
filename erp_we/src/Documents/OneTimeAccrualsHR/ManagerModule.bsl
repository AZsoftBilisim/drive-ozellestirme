
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

// Sets up the filling in of data to reflect one-time accruals in the accounting for the document.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the document for which the filling is configured
//
Procedure SetUpRegistrationForm(Form) Export
	
	Object = Form.Object;
	FilterTable = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.NewFilterTable();
	
	Accrual = Object.Accrual;
	Department = Object.Department;
	DocumentCalculation = Object.Ref;
	
	AccruedByEmployees = Object.AccruedByEmployees;
	For Each CurrentLineAccruedByEmployees In AccruedByEmployees Do
		Employee = CurrentLineAccruedByEmployees.Employee;
		
		NewRow = FilterTable.Add();
		NewRow.TypeOfAccrualDeduction = Accrual; 
		NewRow.Department = Department; 
		NewRow.DocumentCalculation = DocumentCalculation; 
		NewRow.Employee = Employee; 
		NewRow.RowIndex = DocumentsPayrollAndHumanResourcesServer.GetRowIndex(CurrentLineAccruedByEmployees, 
																								AccruedByEmployees);
		
	EndDo;	

	ResultTableByFilter = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetFilterResult(
																FilterTable, Object.RegistrationMonth);
	
	// Filling in the tabular part is accrued to employees
	DetailsOfFillingInForm = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.AttributesOfFillingOutForm();
	DetailsOfFillingInForm.FilterTable = FilterTable;
	DetailsOfFillingInForm.ResultTableByFilter = ResultTableByFilter;
	DetailsOfFillingInForm.ItIsADeduction = False;
	DetailsOfFillingInForm.FilterDate = Object.RegistrationMonth;
	DetailsOfFillingInForm.RecordingSettingPresentation = "ReflectionInAccounting_Presentation";
	DetailsOfFillingInForm.ReflectionSettingIsCorrect = "ReflectionInAccountingIsCorrect";
	DetailsOfFillingInForm.ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingAccruals();

    SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.FillInAddedDetailsOfTablePart(
											Form, DetailsOfFillingInForm, "AccruedByEmployees");
	
EndProcedure	

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - an array of mechanisms for which
//              registration will be performed in the holding mechanism.
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
	
	If TypeOf(Document) = Type("DocumentObject.OneTimeAccrualsHR") Then
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
		
		QueryTextAccrualsHR(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

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
	|	Attributes.RegistrationMonth AS Period,
	|	Attributes.Organization AS Organization
	|FROM
	|	Document.OneTimeAccrualsHR AS Attributes
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

Function QueryTextAccrualsHR(Query, QueryTexts, Registers)
	
	RegisterName = "AccrualsHR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
		
	QueryText = 
	"SELECT
	|	OneTimeAccrualsOfHRAccruedForEmployees.Employee.Individual AS Individual,
	|	OneTimeAccrualsOfHRAccruedForEmployees.Sum AS Sum,
	|	OneTimeAccrualsHR.RegistrationMonth AS Period,
	|	OneTimeAccrualsHR.Organization AS Organization,
	|	OneTimeAccrualsHR.Department AS Department,
	|	OneTimeAccrualsHR.Accrual AS Accrual,
	|	TRUE AS ManualAccrual,
	|	UNDEFINED AS RowID,
	|	OneTimeAccrualsOfHRAccruedForEmployees.Employee AS Employee,
	|	AccrualAndDeductionKinds.CalculationFormula AS CalculationFormula,
	|	AccrualAndDeductionKinds.PayCode AS PayCode,
	|	ENDOFPERIOD(OneTimeAccrualsHR.RegistrationMonth, MONTH) AS PeriodEnding
	|FROM
	|	Document.OneTimeAccrualsHR.AccruedByEmployees AS OneTimeAccrualsOfHRAccruedForEmployees
	|		RIGHT JOIN Document.OneTimeAccrualsHR AS OneTimeAccrualsHR
	|			LEFT JOIN Catalog.AccrualAndDeductionKinds AS AccrualAndDeductionKinds
	|			ON OneTimeAccrualsHR.Accrual = AccrualAndDeductionKinds.Ref
	|				AND OneTimeAccrualsHR.Accrual = AccrualAndDeductionKinds.Ref
	|		ON OneTimeAccrualsOfHRAccruedForEmployees.Ref = OneTimeAccrualsHR.Ref
	|WHERE
	|	OneTimeAccrualsHR.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
