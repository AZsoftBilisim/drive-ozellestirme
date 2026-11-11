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
	
	If TypeOf(Document) = Type("DocumentObject.HiringHR") Then
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

// Sets up the filling of data to be reflected in accounting in the header and tabular parts of the document.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the document for which the configuration is performed
//   UpdateInHeader - Boolean - Indicates whether the data should be updated in the document header
//   UpdateInAccruals - Boolean - Indication of the need to update the data in the tabular part of the "Accruals"
//   UpdateInDeductions - Boolean - A sign of the need to update the data in the table part of the "Retention"
//
Procedure SetUpRegistrationForm(Form, UpdateInHeader = True, UpdateInAccruals = True, UpdateInDeductions = True) Export
	
	Object = Form.Object;
	FilterTable = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.NewFilterTable();
	
	Accrual = Object.BasicAccrual;
	Department = Object.Department;
	Employee = Object.Employee; 
	FilterDate = Object.DateOfAdmission;
	
	If UpdateInHeader Then
		// Adding from the header
		NewRow = FilterTable.Add();
		NewRow.TypeOfAccrualDeduction = Accrual; 
		NewRow.Employee = Employee; 
		NewRow.Department = Department;   
		
		ResultTableByFilter = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetFilterResult(FilterTable, FilterDate);
		
		ReflectionParameters	= SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.FillReflectionParameters(Accrual);
		
		// Filling in the header
		DetailsOfFillingInForm = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.AttributesOfFillingOutForm();
		DetailsOfFillingInForm.FilterTable = FilterTable;
		DetailsOfFillingInForm.ResultTableByFilter = ResultTableByFilter;
		DetailsOfFillingInForm.FilterDate = Object.DateOfAdmission;
		DetailsOfFillingInForm.ItIsADeduction = False;
		DetailsOfFillingInForm.RecordingSettingPresentation = "ReflectionInAccounting_Presentation";
		DetailsOfFillingInForm.ReflectionSettingIsCorrect = "ReflectionInAccounting_IsCorrect";
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.FillInAddedHeaderDetails(Form, ReflectionParameters, DetailsOfFillingInForm);
		
		FilterTable.Clear();
		ResultTableByFilter.Clear();
		
	EndIf;                   	
	
	If UpdateInAccruals Then
		// Adding from the tabular part of the Accrual
		Accruals = Object.Accruals;
		For Each CurrentAccrualLine In Accruals Do
			
			NewRow = FilterTable.Add();
			NewRow.TypeOfAccrualDeduction = CurrentAccrualLine.Accrual; 
			NewRow.Employee = Object.Employee; 
			NewRow.Department = Object.Department; 
			NewRow.RowIndex = DocumentsPayrollAndHumanResourcesServer.GetRowIndex(CurrentAccrualLine, 
																											Accruals);
			
		EndDo;	
		
		ResultTableByFilter = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetFilterResult(
		FilterTable, FilterDate);
		
		// Filling in the tabular part of the Accrual
		DetailsOfFillingInForm = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.AttributesOfFillingOutForm();
		DetailsOfFillingInForm.FilterTable = FilterTable;
		DetailsOfFillingInForm.ResultTableByFilter = ResultTableByFilter;
		DetailsOfFillingInForm.ItIsADeduction = False;
		DetailsOfFillingInForm.FilterDate = FilterDate;
		DetailsOfFillingInForm.RecordingSettingPresentation = "ReflectionInAccounting_Presentation";
		DetailsOfFillingInForm.ReflectionSettingIsCorrect = "ReflectionInAccountingIsCorrect";
		DetailsOfFillingInForm.ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingAccruals();
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.FillInAddedDetailsOfTablePart(
		Form, DetailsOfFillingInForm, "Accruals");
		
		FilterTable.Clear();
		ResultTableByFilter.Clear();
		
	EndIf;                   	
	
	If UpdateInDeductions Then
		// Adding from the tabular part of the Deductions
		
		Deductions = Object.Deductions;
		For Each CurrentRetentionLine In Deductions Do
			
			NewRow = FilterTable.Add();
			NewRow.TypeOfAccrualDeduction = CurrentRetentionLine.Retention; 
			NewRow.Employee = Employee; 
			NewRow.Department = Department; 
			NewRow.RowIndex = DocumentsPayrollAndHumanResourcesServer.GetRowIndex(CurrentRetentionLine, 
																										Deductions);
			
		EndDo;	
		
		ResultTableByFilter = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetFilterResult(
		FilterTable, FilterDate);
		
		// Filling in the tabular part of the Accrual
		DetailsOfFillingInForm = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.AttributesOfFillingOutForm();
		DetailsOfFillingInForm.FilterTable = FilterTable;
		DetailsOfFillingInForm.ResultTableByFilter = ResultTableByFilter;
		DetailsOfFillingInForm.ItIsADeduction = False;
		DetailsOfFillingInForm.FilterDate = FilterDate;
		DetailsOfFillingInForm.RecordingSettingPresentation = "ReflectionInAccounting_Presentation";
		DetailsOfFillingInForm.ReflectionSettingIsCorrect = "ReflectionInAccountingIsCorrect";
		DetailsOfFillingInForm.ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingDeductions();
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.FillInAddedDetailsOfTablePart(
		Form, DetailsOfFillingInForm, "Deductions");
		
	EndIf;	
	
EndProcedure	

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
	|	ENDOFPERIOD(Attributes.DateOfAdmission, DAY) AS Period,
	|	Attributes.Organization AS Organization,
	|	Attributes.Department AS Department,
	|	Attributes.Employee AS Employee,
	|	Attributes.EmploymentKind,
	|	Attributes.WorkScheduleCalendar,
	|	ENDOFPERIOD(Attributes.ContractEndDate, DAY) AS EndDate
	|FROM
	|	Document.HiringHR AS Attributes
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
	
	FullDocumentName = "Document.HiringHR"; 
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.HiringHR"));
	
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
	|	HiringHR.Organization AS Organization,
	|	HiringHR.Department AS Department,
	|	HiringHR.Employee AS Employee,
	|	HiringHR.BaseValue AS Value,
	|	HiringHR.Prepayment_ AS Prepayment_,
	|	TRUE AS Valid,
	|	TRUE AS BasicEarnings,
	|	HiringHR.DateOfAdmission AS Period,
	|	HiringHR.BasicAccrual AS AccrualDeduction,
	|	HiringHR.TimeKindForNorms AS TimeKindForNorms
	|FROM
	|	Document.HiringHR AS HiringHR
	|WHERE
	|	HiringHR.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	HiringHR.Organization,
	|	HiringHR.Department,
	|	HiringHR.Employee,
	|	HiringHRAccruals.Value,
	|	HiringHR.Prepayment_,
	|	TRUE,
	|	FALSE,
	|	HiringHR.DateOfAdmission,
	|	HiringHRAccruals.Accrual,
	|	UNDEFINED
	|FROM
	|	Document.HiringHR.Accruals AS HiringHRAccruals
	|		LEFT JOIN Document.HiringHR AS HiringHR
	|		ON HiringHRAccruals.Ref = HiringHR.Ref
	|WHERE
	|	HiringHR.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	HiringHR.Organization,
	|	HiringHR.Department,
	|	HiringHR.Employee,
	|	HiringHRDeductions.Value,
	|	HiringHR.Prepayment_,
	|	TRUE,
	|	FALSE,
	|	HiringHR.DateOfAdmission,
	|	HiringHRDeductions.Retention,
	|	UNDEFINED
	|FROM
	|	Document.HiringHR.Deductions AS HiringHRDeductions
	|		LEFT JOIN Document.HiringHR AS HiringHR
	|		ON HiringHRDeductions.Ref = HiringHR.Ref
	|WHERE
	|	HiringHR.Ref = &Ref";
	
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
	|	HiringHR.Organization AS Organization,
	|	HiringHR.Department AS Department,
	|	HiringHR.DateOfAdmission AS Period,
	|	HiringHR.Employee AS Employee,
	|	HiringHR.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	HiringHR.JobTitle AS JobTitle,
	|	HiringHR.Currency AS Currency,
	|	HiringHR.ContractEndDate AS EndDate,
	|	VALUE(Enum.HREventKindsPayrollAndHumanResources.Reception) AS EventKind,
	|	TRUE AS WorksInBusinessUnit,
	|	HiringHR.EmploymentKind
	|FROM
	|	Document.HiringHR AS HiringHR
	|WHERE
	|	HiringHR.Ref = &Ref";
	
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
	|	DocumentData.BaseValue AS Sum,
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
	|	Document.HiringHR AS DocumentData
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
		HiringHRLocalization.AddPrintCommands(PrintCommands);
	EndIf;
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	HiringHRLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

