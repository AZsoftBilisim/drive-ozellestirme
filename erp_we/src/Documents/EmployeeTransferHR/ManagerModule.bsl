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
	
	If TypeOf(Document) = Type("DocumentObject.EmployeeTransferHR") Then
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

// Sets up automatic filling in of Attributes related to accounting for the document header and the tabular parts "Accruals" and "Deductions".
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the document for which the configuration is performed.
//   UpdateInHeader - Boolean - Determines whether the Attributes in the document header need to be updated.
//   UpdateInAccruals - Boolean - Determines the need to update the Attributes in the tabular part of the "Accruals".
//   UpdateInDeductions - Boolean - Determines the need to update the Attributes in the tabular part of the "Retention".
//
Procedure SetUpRegistrationForm(Form, UpdateInHeader = True, UpdateInAccruals = True, UpdateInDeductions = True) Export
	
	Object = Form.Object;
	FilterTable = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.NewFilterTable();
	
	Accrual = Object.BasicAccrual;
	Department = Object.Department;
	Employee = Object.Employee; 
	FilterDate = Object.DateOfTransition;
	
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
		DetailsOfFillingInForm.FilterDate = FilterDate;
		DetailsOfFillingInForm.ItIsADeduction = False;
		DetailsOfFillingInForm.RecordingSettingPresentation = "ReflectionInAccounting_Presentation";
		DetailsOfFillingInForm.ReflectionSettingIsCorrect = "ReflectionInAccounting_IsCorrect";
		
		SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.FillInAddedHeaderDetails(Form, ReflectionParameters, DetailsOfFillingInForm);
		
		// Filling in the header is old
		DetailsOfFillingInForm = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.AttributesOfFillingOutForm();
		DetailsOfFillingInForm.FilterTable = FilterTable;
		DetailsOfFillingInForm.ResultTableByFilter = ResultTableByFilter;
		DetailsOfFillingInForm.FilterDate = FilterDate-100;
		DetailsOfFillingInForm.ItIsADeduction = False;
		DetailsOfFillingInForm.RecordingSettingPresentation = "ReflectionInAccountingPresentationIsOld";
		DetailsOfFillingInForm.ReflectionSettingIsCorrect = "ReflectionInAccountingIsCorrectOld";

		ResultTableByFilter = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetFilterResult(FilterTable, FilterDate-100);
		
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
	|	BEGINOFPERIOD(Attributes.DateOfTransition, DAY) AS Period,
	|	Attributes.Organization AS Organization,
	|	Attributes.Department AS Department,
	|	Attributes.BusinessUnitOld AS BusinessUnitOld,
	|	Attributes.Employee AS Employee,
	|	Attributes.EmploymentKind AS EmploymentKind,
	|	Attributes.EmploymentKindOld AS EmploymentKindOld,
	|	Attributes.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	Attributes.WorkScheduleOld AS WorkScheduleOld,
	|	ENDOFPERIOD(Attributes.ContractEndDate, DAY) AS EndDate,
	|	ENDOFPERIOD(Attributes.ContractEndDateOld, DAY) AS EndDateIsOld
	|FROM
	|	Document.EmployeeTransferHR AS Attributes
	|WHERE
	|	Attributes.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(Type("DocumentRef.EmployeeTransferHR")));
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
	
	FullDocumentName = "Document.EmployeeTransferHR";
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.EmployeeTransferHR"));
	
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
	
	DetailsDocuments = "Organization, Employee, Department, BaseValue, Prepayment_, Ref, DateOfTransition, BasicAccrual, TimeKindForNorms";
	
	StructureOfDocumentParameters = Common.ObjectAttributesValues(Query.Parameters.Ref, DetailsDocuments); 
	
	StructureOfDocumentParameters.Insert("Accruals", Query.Parameters.Ref.Accruals.Unload());
	
	StructureOfDocumentParameters.Insert("Deductions", Query.Parameters.Ref.Deductions.Unload());
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) 
		Or Documents.EmployeeTransferHR.EmployeeWasHiredEarlierWithRegularAccrualsAndDeductions(StructureOfDocumentParameters) Then
		Return "";
	EndIf;
		
	QueryText = 
	"SELECT
	|	EmployeeTransferHR.Organization AS Organization,
	|	EmployeeTransferHR.Department AS Department,
	|	EmployeeTransferHR.Employee AS Employee,
	|	EmployeeTransferHR.BaseValue AS Value,
	|	EmployeeTransferHR.Prepayment_ AS Prepayment_,
	|	TRUE AS Valid,
	|	TRUE AS BasicEarnings,
	|	&Period AS Period,
	|	EmployeeTransferHR.BasicAccrual AS AccrualDeduction,
	|	EmployeeTransferHR.TimeKindForNorms AS TimeKindForNorms
	|FROM
	|	Document.EmployeeTransferHR AS EmployeeTransferHR
	|WHERE
	|	EmployeeTransferHR.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	EmployeeTransferHR.Organization,
	|	EmployeeTransferHR.Department,
	|	EmployeeTransferHR.Employee,
	|	EmployeeTransferHRAccruals.Value,
	|	0,
	|	TRUE,
	|	FALSE,
	|	&Period,
	|	EmployeeTransferHRAccruals.Accrual,
	|	UNDEFINED
	|FROM
	|	Document.EmployeeTransferHR.Accruals AS EmployeeTransferHRAccruals
	|		LEFT JOIN Document.EmployeeTransferHR AS EmployeeTransferHR
	|		ON EmployeeTransferHRAccruals.Ref = EmployeeTransferHR.Ref
	|WHERE
	|	EmployeeTransferHR.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	EmployeeTransferHR.Organization,
	|	EmployeeTransferHR.Department,
	|	EmployeeTransferHR.Employee,
	|	EmployeeTransferHRDeductions.Value,
	|	0,
	|	TRUE,
	|	FALSE,
	|	&Period,
	|	EmployeeTransferHRDeductions.Retention,
	|	UNDEFINED
	|FROM
	|	Document.EmployeeTransferHR.Deductions AS EmployeeTransferHRDeductions
	|		LEFT JOIN Document.EmployeeTransferHR AS EmployeeTransferHR
	|		ON EmployeeTransferHRDeductions.Ref = EmployeeTransferHR.Ref
	|WHERE
	|	EmployeeTransferHR.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	RegularAccrualsAndDeductionsHRSliceLast.Organization,
	|	RegularAccrualsAndDeductionsHRSliceLast.Department,
	|	RegularAccrualsAndDeductionsHRSliceLast.Employee,
	|	RegularAccrualsAndDeductionsHRSliceLast.Value,
	|	RegularAccrualsAndDeductionsHRSliceLast.Prepayment_,
	|	FALSE,
	|	FALSE,
	|	DATEADD(&Period, SECOND, -1),
	|	RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction,
	|	UNDEFINED
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(
	|			&Period,
	|			Organization = &Organization
	|				AND Employee = &Employee
	|				AND Department = &BusinessUnitOld
	|				AND NOT BasicEarnings
	|				AND NOT Recorder = &Ref) AS RegularAccrualsAndDeductionsHRSliceLast
	|WHERE
	|	RegularAccrualsAndDeductionsHRSliceLast.Valid
	|	AND NOT RegularAccrualsAndDeductionsHRSliceLast.BasicEarnings
	|
	|UNION ALL
	|
	|SELECT
	|	RegularAccrualsAndDeductionsHRSliceLast.Organization,
	|	RegularAccrualsAndDeductionsHRSliceLast.Department,
	|	RegularAccrualsAndDeductionsHRSliceLast.Employee,
	|	RegularAccrualsAndDeductionsHRSliceLast.Value,
	|	RegularAccrualsAndDeductionsHRSliceLast.Prepayment_,
	|	FALSE,
	|	TRUE,
	|	DATEADD(&Period, SECOND, -1),
	|	RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction,
	|	RegularAccrualsAndDeductionsHRSliceLast.TimeKindForNorms
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(
	|			&Period,
	|			Organization = &Organization
	|				AND Employee = &Employee
	|				AND Department = &BusinessUnitOld
	|				AND BasicEarnings
	|				AND NOT Recorder = &Ref) AS RegularAccrualsAndDeductionsHRSliceLast
	|WHERE
	|	RegularAccrualsAndDeductionsHRSliceLast.Valid
	|	AND RegularAccrualsAndDeductionsHRSliceLast.BasicEarnings";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextPersonnelHistory(Query, QueryTexts, Registers)
	
	RegisterName = "EmploymentRecord";
	
	DetailsDocuments = "Organization, Employee, Department, JobTitle, WorkScheduleCalendar, EmploymentKind, Ref, DateOfTransition";
	
	StructureOfDocumentParameters = Common.ObjectAttributesValues(Query.Parameters.Ref, DetailsDocuments);
		
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) 
		Or Documents.EmployeeTransferHR.EmployeeWasHiredEarlierWithPersonnelHistory(StructureOfDocumentParameters) Then
		Return "";
	EndIf;
	

	QueryText =
	"SELECT
	|	EmployeeTransferHR.Organization AS Organization,
	|	EmployeeTransferHR.Department AS Department,
	|	EmployeeTransferHR.DateOfTransition AS Period,
	|	EmployeeTransferHR.Employee AS Employee,
	|	EmployeeTransferHR.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	EmployeeTransferHR.JobTitle AS JobTitle,
	|	EmployeeTransferHR.Currency AS Currency,
	|	EmployeeTransferHR.ContractEndDate AS EndDate,
	|	VALUE(Enum.HREventKindsPayrollAndHumanResources.Move) AS EventKind,
	|	TRUE AS WorksInBusinessUnit,
	|	EmployeeTransferHR.EmploymentKind
	|FROM
	|	Document.EmployeeTransferHR AS EmployeeTransferHR
	|WHERE
	|	EmployeeTransferHR.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	EmployeeTransferHR.Organization,
	|	EmployeeTransferHR.BusinessUnitOld,
	|	EmployeeTransferHR.DateOfTransition,
	|	EmployeeTransferHR.Employee,
	|	EmployeeTransferHR.WorkScheduleOld,
	|	EmployeeTransferHR.JobTitleOld,
	|	EmployeeTransferHR.Currency,
	|	EmployeeTransferHR.ContractEndDateOld,
	|	VALUE(Enum.HREventKindsPayrollAndHumanResources.Move),
	|	FALSE AS WorksInBusinessUnit,
	|	EmployeeTransferHR.EmploymentKindOld
	|FROM
	|	Document.EmployeeTransferHR AS EmployeeTransferHR
	|WHERE
	|	EmployeeTransferHR.Ref = &Ref
	|	AND NOT EmployeeTransferHR.BusinessUnitOld = EmployeeTransferHR.Department";
	
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
	|	Document.EmployeeTransferHR AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function EmployeeWasHiredEarlierWithPersonnelHistory(StructureOfDocumentParameters) Export 
	
	If Not ValueIsFilled(StructureOfDocumentParameters.Employee)
		Or Not ValueIsFilled(StructureOfDocumentParameters.Organization)
		Or Not ValueIsFilled(StructureOfDocumentParameters.Department)
		Or Not ValueIsFilled(StructureOfDocumentParameters.WorkScheduleCalendar)
		Or Not ValueIsFilled(StructureOfDocumentParameters.JobTitle)
		Or Not ValueIsFilled(StructureOfDocumentParameters.EmploymentKind) Then
		Return False;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	EmploymentRecord.Employee AS Employee
	|FROM
	|	InformationRegister.EmploymentRecord AS EmploymentRecord
	|WHERE
	|	EmploymentRecord.Organization = &Organization
	|	AND EmploymentRecord.Employee = &Employee
	|	AND EmploymentRecord.Recorder <> &Ref
	|	AND EmploymentRecord.Department = &Department
	|	AND EmploymentRecord.JobTitle = &JobTitle
	|	AND EmploymentRecord.WorkScheduleCalendar = &WorkScheduleCalendar
	|	AND EmploymentRecord.Period < &DateOfTransition
	|	AND EmploymentRecord.EmploymentKind = &EmploymentKind");
	
	Query.SetParameter("Organization", StructureOfDocumentParameters.Organization);
	Query.SetParameter("Employee", StructureOfDocumentParameters.Employee);
	Query.SetParameter("Department", StructureOfDocumentParameters.Department);
	Query.SetParameter("JobTitle", StructureOfDocumentParameters.JobTitle);
	Query.SetParameter("WorkScheduleCalendar", StructureOfDocumentParameters.WorkScheduleCalendar);
	Query.SetParameter("EmploymentKind", StructureOfDocumentParameters.EmploymentKind);
	Query.SetParameter("Ref", StructureOfDocumentParameters.Ref);
	Query.SetParameter("DateOfTransition", StructureOfDocumentParameters.DateOfTransition); 
	
	Return Not Query.Execute().IsEmpty();
		
EndFunction  

Function EmployeeWasHiredEarlierWithRegularAccrualsAndDeductions(StructureOfDocumentParameters) Export 
	
	If Not ValueIsFilled(StructureOfDocumentParameters.Employee)
		Or Not ValueIsFilled(StructureOfDocumentParameters.Organization)
		Or Not ValueIsFilled(StructureOfDocumentParameters.Department)
		Or Not ValueIsFilled(StructureOfDocumentParameters.BaseValue)
		Or Not ValueIsFilled(StructureOfDocumentParameters.BasicAccrual) Then
		Return False;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	RegularAccrualsAndDeductionsHR.AccrualDeduction AS AccrualDeduction,
	|	RegularAccrualsAndDeductionsHR.Value AS Value,
	|	RegularAccrualsAndDeductionsHR.Prepayment_ AS Prepayment_,
	|	RegularAccrualsAndDeductionsHR.BasicEarnings AS BasicEarnings,
	|	RegularAccrualsAndDeductionsHR.TimeKindForNorms AS TimeKindForNorms
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR AS RegularAccrualsAndDeductionsHR
	|WHERE
	|	RegularAccrualsAndDeductionsHR.Organization = &Organization
	|	AND RegularAccrualsAndDeductionsHR.Department = &Department
	|	AND RegularAccrualsAndDeductionsHR.Employee = &Employee
	|	AND RegularAccrualsAndDeductionsHR.Period < &DateOfTransition
	|	AND RegularAccrualsAndDeductionsHR.Recorder <> &Ref");
	
	Query.SetParameter("Organization", StructureOfDocumentParameters.Organization);
	Query.SetParameter("Employee", StructureOfDocumentParameters.Employee);
	Query.SetParameter("Department", StructureOfDocumentParameters.Department);
	Query.SetParameter("Ref", StructureOfDocumentParameters.Ref);
	Query.SetParameter("DateOfTransition", StructureOfDocumentParameters.DateOfTransition); 
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		TableOfAccrualsAndDeductions = Query.Execute().Unload(); 
		
		UniqueAccrualDeductionFound = False;
		
		DataStructureAccrualWithholding = New Structure("AccrualDeduction, Value, Prepayment_, BasicEarnings, TimeKindForNorms");
		
		DataStructureAccrualWithholding.AccrualDeduction = StructureOfDocumentParameters.BasicAccrual;
		DataStructureAccrualWithholding.Value = StructureOfDocumentParameters.BaseValue;
		DataStructureAccrualWithholding.Prepayment_ = StructureOfDocumentParameters.Prepayment_;
		DataStructureAccrualWithholding.BasicEarnings = True;
		DataStructureAccrualWithholding.TimeKindForNorms = StructureOfDocumentParameters.TimeKindForNorms;
		
		UniqueAccrualDeductionFound = CheckingUniquenessAccrualWithholding(DataStructureAccrualWithholding, TableOfAccrualsAndDeductions);
		
		If UniqueAccrualDeductionFound Then 
			Return False;
		EndIf;
		
		For Each VTItem1 In StructureOfDocumentParameters.Accruals Do
			DataStructureAccrualWithholding.AccrualDeduction = VTItem1.Accrual;
			DataStructureAccrualWithholding.Value = VTItem1.Value;
			DataStructureAccrualWithholding.Prepayment_ = 0;
			DataStructureAccrualWithholding.BasicEarnings = False;
			
			UniqueAccrualDeductionFound = CheckingUniquenessAccrualWithholding(DataStructureAccrualWithholding, TableOfAccrualsAndDeductions);
			
			If UniqueAccrualDeductionFound Then 
				Return False;
			EndIf;
		EndDo; 
		
		For Each VTItem1 In StructureOfDocumentParameters.Deductions Do
			DataStructureAccrualWithholding.AccrualDeduction = VTItem1.Retention;
			DataStructureAccrualWithholding.Value = VTItem1.Value;
			DataStructureAccrualWithholding.Prepayment_ = 0;
			DataStructureAccrualWithholding.BasicEarnings = False;
			
			UniqueAccrualDeductionFound = CheckingUniquenessAccrualWithholding(DataStructureAccrualWithholding, TableOfAccrualsAndDeductions);
			
			If UniqueAccrualDeductionFound Then 
				Return False;
			EndIf;
		EndDo; 
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

Function CheckingUniquenessAccrualWithholding(DataStructureAccrualWithholding, TableOfAccrualsAndDeductions); 
	
	ArrayOfFoundStrings = TableOfAccrualsAndDeductions.FindRows(DataStructureAccrualWithholding);
	
	If ArrayOfFoundStrings.Count() > 0 Then
		Return False;
	Else
		Return True;
	EndIf;

EndFunction

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Read", Metadata.Documents.WorkOutput) Then
		EmployeeTransferHRLocalization.AddPrintCommands(PrintCommands);	
	EndIf;
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	EmployeeTransferHRLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

