
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
	
	If TypeOf(Document) = Type("DocumentObject.ManualTaxCalculation") Then
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

// Sets up filling in the tabular part of the "Accrued tax by employees" with data to be reflected in accounting.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the document "Manual calculation of Taxovzik", containing the object to configure.
//
Procedure SetUpRegistrationForm(Form) Export
	
	Object = Form.Object;
	FilterTable = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.NewFilterTable();
	
	TaxKind = Object.TaxKind;
	Department = Object.Department;
	DocumentCalculation = Object.Ref;

	For Each CurrentLineAccruedByEmployees In Object.EmployeeTaxIsAccrued Do
		Employee = CurrentLineAccruedByEmployees.Employee;
		
		NewRow = FilterTable.Add();
		NewRow.TypeOfAccrualDeduction = TaxKind; 
		NewRow.Department = Department; 
		NewRow.DocumentCalculation = DocumentCalculation; 
		NewRow.Employee = Employee; 
		NewRow.RowIndex = DocumentsPayrollAndHumanResourcesServer.GetRowIndex(CurrentLineAccruedByEmployees, 
																						Object.EmployeeTaxIsAccrued);
		
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
	
	ReflectionParameters = FillReflectionParameters(TaxKind, Object.RegistrationMonth);
	
    SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.FillInAddedDetailsOfTablePart(
											Form, DetailsOfFillingInForm, "EmployeeTaxIsAccrued", ReflectionParameters);
	
EndProcedure	

// Determines the parameters of tax reflection in accounting based on the settings.
//
// Parameters:
//   TaxKind - CatalogRef.AccrualAndDeductionKinds - Type of tax to reflect
//   FilterDate - Date - Date for current settings
//
// Returns:
//   Structure - Parameters of tax reflection in accounting:
//   * PostingOption - EnumRef.AccrualsDeductionsRecordOptions - The option of tax reflection in accounting
//   * RecordingSetting - Structure - Setting up tax reflection in accounting
//   * ReflectionSettingIsCorrect - Boolean - Indicates whether the tax reflection settings are correct in accounting
//   * RecordingSettingPresentation - String - Presentation of the tax reflection settings in accounting
//
Function FillReflectionParameters(TaxKind, FilterDate) Export

		ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingAccruals();   
		
		FillingSettings = New Structure("PostingOption");
		
		FillingSettings 
			= SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetAccrualRetentionSettings(TaxKind, FilterDate);
			
		If Not ValueIsFilled(FillingSettings.PostingOption) Then
				
			PostingOption =
				PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses");
		Else     
			PostingOption = FillingSettings.PostingOption;	
		EndIf;	
		
		ReflectionParameters = ReflectionOptions[PostingOption];   
		
		Return ReflectionParameters;
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
	|	Document.ManualTaxCalculation AS Attributes
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

Function QueryTextTaxesContributionsHR(Query, QueryTexts, Registers)
	
	RegisterName = "TaxesContributionsHR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
		
	QueryText = 
	"SELECT
	|	ManualTaxCalculationEmployeeTaxIsAccrued.Employee.Individual AS Individual,
	|	ManualTaxCalculationEmployeeTaxIsAccrued.Sum AS Sum,
	|	ManualTaxCalculation.RegistrationMonth AS Period,
	|	ManualTaxCalculation.Organization AS Organization,
	|	ManualTaxCalculation.Department AS Department,
	|	ManualTaxCalculation.TaxKind AS TaxKind,
	|	ManualTaxCalculation.TaxKind.DeductedFromEmployeeWages AS DeductedFromEmployeeWages,
	|	TRUE AS ManualTax,
	|	UNDEFINED AS RowID,
	|	ManualTaxCalculationEmployeeTaxIsAccrued.Employee AS Employee
	|FROM
	|	Document.ManualTaxCalculation.EmployeeTaxIsAccrued AS ManualTaxCalculationEmployeeTaxIsAccrued
	|		RIGHT JOIN Document.ManualTaxCalculation AS ManualTaxCalculation
	|		ON ManualTaxCalculationEmployeeTaxIsAccrued.Ref = ManualTaxCalculation.Ref
	|WHERE
	|	ManualTaxCalculation.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
