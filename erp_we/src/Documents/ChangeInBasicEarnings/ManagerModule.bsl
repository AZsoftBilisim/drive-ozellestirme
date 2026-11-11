#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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

#EndRegion

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
	
	If TypeOf(Document) = Type("DocumentObject.ChangeInBasicEarnings") Then
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
		
		QueryTextTableRegularAccrualsAndDeductions(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Sets up filling in the tabular part of the "Main earnings" with data to be reflected in accounting.
//
// Parameters:
//   Form - ClientApplicationForm - A document Form containing an object to configure the filling
//
Procedure SetUpRegistrationForm(Form) Export
	
	Object = Form.Object;
	FilterTable = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.NewFilterTable();
	FilterDate = Object.ChangeDate;
	
	// Adding the main earnings from the tabular part
	For Each CurrentLineBasicEarnings In Object.BasicEarnings Do
		
		NewRow = FilterTable.Add();
		NewRow.TypeOfAccrualDeduction = CurrentLineBasicEarnings.Accrual; 
		NewRow.Employee = CurrentLineBasicEarnings.Employee; 
		NewRow.Department = Object.Department; 
		NewRow.RowIndex = DocumentsPayrollAndHumanResourcesServer.GetRowIndex(CurrentLineBasicEarnings, 
																								Object.BasicEarnings);
		
	EndDo;	
	
	ResultTableByFilter = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetFilterResult(
																	FilterTable, FilterDate-100);
	
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
	Form, DetailsOfFillingInForm, "BasicEarnings");


	ResultTableByFilter = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.GetFilterResult(
																	FilterTable, FilterDate);
	
	// Filling in the tabular part of the Accrual
	DetailsOfFillingInForm = SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.AttributesOfFillingOutForm();
	DetailsOfFillingInForm.FilterTable = FilterTable;
	DetailsOfFillingInForm.ResultTableByFilter = ResultTableByFilter;
	DetailsOfFillingInForm.ItIsADeduction = False;
	DetailsOfFillingInForm.FilterDate = FilterDate;
	DetailsOfFillingInForm.RecordingSettingPresentation = "ReflectionInAccountingPresentationNew";
	DetailsOfFillingInForm.ReflectionSettingIsCorrect = "ReflectionInAccountingIsCorrectNew";
	DetailsOfFillingInForm.ReflectionOptions = Catalogs.AccrualAndDeductionKinds.OptionsForReflectingAccruals();
	
	SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.FillInAddedDetailsOfTablePart(
	Form, DetailsOfFillingInForm, "BasicEarnings");
	
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
	|	ENDOFPERIOD(Attributes.ChangeDate, DAY) AS Period,
	|	Attributes.Organization AS Organization,
	|	Attributes.Department AS Department
	|FROM
	|	Document.ChangeInBasicEarnings AS Attributes
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
	
	FullDocumentName = "Document.ChangeInBasicEarnings";
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ChangeInBasicEarnings"));
	
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
	|	BasicEarnings.Ref.Organization AS Organization,
	|	BasicEarnings.Ref.Department AS Department,
	|	BasicEarnings.Employee AS Employee,
	|	BasicEarnings.NewValue_ AS Value,
	|	BasicEarnings.AdvancePaymentNew AS Prepayment_,
	|	TRUE AS Valid,
	|	TRUE AS BasicEarnings,
	|	BasicEarnings.Ref.ChangeDate AS Period,
	|	BasicEarnings.Accrual AS AccrualDeduction,
	|	BasicEarnings.PayCodeNew AS TimeKindForNorms
	|FROM
	|	Document.ChangeInBasicEarnings.BasicEarnings AS BasicEarnings
	|WHERE
	|	BasicEarnings.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	BasicEarningsDoc.Ref.Organization,
	|	BasicEarningsDoc.Ref.Department,
	|	BasicEarningsDoc.Employee,
	|	RegularAccrualsAndDeductionsHRSliceLast.Value,
	|	RegularAccrualsAndDeductionsHRSliceLast.Prepayment_,
	|	FALSE,
	|	TRUE,
	|	DATEADD(BasicEarningsDoc.Ref.ChangeDate, SECOND, -1),
	|	RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction,
	|	BasicEarningsDoc.TimeKindForNorms
	|FROM
	|	Document.ChangeInBasicEarnings.BasicEarnings AS BasicEarningsDoc
	|		LEFT JOIN InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(&Period, ) AS RegularAccrualsAndDeductionsHRSliceLast
	|		ON BasicEarningsDoc.Employee = RegularAccrualsAndDeductionsHRSliceLast.Employee
	|			AND BasicEarningsDoc.Ref.Organization = RegularAccrualsAndDeductionsHRSliceLast.Organization
	|			AND BasicEarningsDoc.Ref.Department = RegularAccrualsAndDeductionsHRSliceLast.Department
	|WHERE
	|	BasicEarningsDoc.Ref = &Ref
	|	AND RegularAccrualsAndDeductionsHRSliceLast.Valid
	|	AND RegularAccrualsAndDeductionsHRSliceLast.BasicEarnings";
	
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
	|	0 AS Sum,
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
	|	Document.ChangeInBasicEarnings AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf

