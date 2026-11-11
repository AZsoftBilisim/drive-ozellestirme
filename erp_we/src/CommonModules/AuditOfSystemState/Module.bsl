////////////////////////////////////////////////////////////////////////////////
// Subsystem "System state audit".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region PerformingVerification

// Performing the specified system health check.
//
// Parameters:
// 	Validation - CatalogRef.AccountingCheckRules - Validation
// 	ValuesOfAdditionalParameters - Arbitrary - additional verification parameters
// 	
// Returns:
// 	Structure - See InitializeVerificationParameters
//
Function CheckSystemState(Validation, ValuesOfAdditionalParameters = Undefined) Export
	
	CheckDate = CurrentSessionDate();
	
	// Perform a check.
	VerificationDetails_1 = Common.ObjectAttributesValues(
		Validation,
		"Id, AccountingChecksContext, Handler, IssueSeverity, DetailsByCompany, DetailsByPeriod"); // CatalogRef.AccountingCheckRules
	
	Checks          = AccountingAuditInternalCached.AccountingChecks().Checks;
	CheckString    = Checks.Find(VerificationDetails_1.Id, "Id");
	
	If CheckString = Undefined Then
		CheckParameters = InitializeVerificationParameters(Validation);
		Return CheckParameters;
	EndIf;
	
	VerificationDetails_1.Handler = CheckString.HandlerChecks;
	
	// Determine the structure of the requested results.
	CheckParameters = InitializeVerificationParameters(
		Validation,
		VerificationDetails_1.AccountingChecksContext,
		ValuesOfAdditionalParameters);
	
	// Let's perform a check.
	ParametersArray = New Array;
	ParametersArray.Add(VerificationDetails_1.Id);
	ParametersArray.Add(CheckParameters); // The verification parameters will be changed in the handler
	
	Common.ExecuteConfigurationMethod(VerificationDetails_1.Handler, ParametersArray);
	
	// Let's process the results of the check.
	If Not CheckParameters.VerificationFailed Then
		CheckParameters.ReasonForCheckDecline = "";
	Else
		CheckParameters.IdentifiedProblems.Clear();
	EndIf;
	
	CheckParameters.IdentifiedProblems.Columns.Add("Issue1", New TypeDescription("UUID"));
	
	For Each ProblemString In CheckParameters.IdentifiedProblems Do
		
		If Not ValueIsFilled(ProblemString.Importance) Then
			ProblemString.Importance = VerificationDetails_1.IssueSeverity;
		EndIf;
		
		ProblemString.Issue1 = New UUID;
		
	EndDo;
	
	If CheckParameters.Filters.Count() = 0 Then
		CheckParameters.Filters.Add(); // checking without selections
	EndIf;
	
	ProblemsGrouped = New ValueTable;
	ProblemsGrouped.Columns.Add("Issue1",      	   New TypeDescription("UUID"));
	ProblemsGrouped.Columns.Add("Presentation",      New TypeDescription("String"));
	ProblemsGrouped.Columns.Add("Importance", 	 	   New TypeDescription("EnumRef.AccountingIssueSeverity")); // optional
	ProblemsGrouped.Columns.Add("IssuesCount",  New TypeDescription("Number"));
	ProblemsGrouped.Columns.Add("ObjectCount", New TypeDescription("Number"));
	
	For Each CurrentFilter In CheckParameters.Filters Do
		
		// Let's collect information about the problems found.
		TheStructureOfTheSearch = New Structure("Organization, CheckedPeriod");
		FillPropertyValues(TheStructureOfTheSearch, CurrentFilter);
		
		ProblemLines = CheckParameters.IdentifiedProblems.FindRows(TheStructureOfTheSearch);
		ObjectCount = 0;
		
		For Each ProblemString In ProblemLines Do
			
			ObjectCount = ObjectCount + Max(ProblemString.Objects.Count(), 1);
			
			ProblemLineGrouped = ProblemsGrouped.Add();
			
			FillPropertyValues(ProblemLineGrouped, ProblemString);
			
			ProblemLineGrouped.IssuesCount = 1;
			ProblemLineGrouped.ObjectCount = ProblemString.Objects.Count();
			
		EndDo;
		
		// We register the fact of the check and clear the results of the last check.
		SetOfValidationRecords = InformationRegisters.MonthEndChecklistsStatus.CreateRecordSet();
		ProblemRecordSet = InformationRegisters.SystemStatusIssues.CreateRecordSet();
		RecordsetObjects  = InformationRegisters.ObjectsOfSystemStatusIssues.CreateRecordSet();
		
		SetOfValidationRecords.Filter.Validation.Set(Validation);
		ProblemRecordSet.Filter.Validation.Set(Validation);
		RecordsetObjects.Filter.Validation.Set(Validation);
		
		If VerificationDetails_1.DetailsByCompany And ValueIsFilled(CurrentFilter.Organization) Then
			SetOfValidationRecords.Filter.Organization.Set(CurrentFilter.Organization);
			ProblemRecordSet.Filter.Organization.Set(CurrentFilter.Organization);
			RecordsetObjects.Filter.Organization.Set(CurrentFilter.Organization);
		EndIf;
		
		If VerificationDetails_1.DetailsByPeriod And ValueIsFilled(CurrentFilter.CheckedPeriod) Then
			SetOfValidationRecords.Filter.CheckedPeriod.Set(CurrentFilter.CheckedPeriod);
			ProblemRecordSet.Filter.CheckedPeriod.Set(CurrentFilter.CheckedPeriod);
			RecordsetObjects.Filter.CheckedPeriod.Set(CurrentFilter.CheckedPeriod);
		EndIf;
		
		RecordVerification = SetOfValidationRecords.Add();
		FillPropertyValues(RecordVerification, CurrentFilter);
		
		RecordVerification.Validation 				= Validation;
		RecordVerification.ExecutionDate   		= CheckDate;
		RecordVerification.IssuesAreDetected 		= (ObjectCount > 0);
		RecordVerification.ReasonForCheckDecline 	= CheckParameters.ReasonForCheckDecline;
		
		SetOfValidationRecords.Write(True);
		ProblemRecordSet.Write(True); // clearing the results of the last check
		RecordsetObjects.Write(True);  // clearing the results of the last check
		
		// Let's add an entry to the registration log.
		PresentationOfVerification = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kiểm tra ""%1"" cho doanh nghiệp ""%2"" trong kỳ %3';
				|ru = 'Проверка ""%1"" по организации ""%2"" за период %3';
				|en = 'The ""%1"" check of the ""%2"" company for the %3 period'; fa = 'The ""%1"" check of the ""%2"" company for the %3 period';
				|it = 'Controllo ""%1"" sull''organizzazione ""%2"" per il periodo %3';
				|pl = 'Weryfikacja ""%1"" według firmy ""%2"" za okres %3';
				|tr = '%3 dönemi için ""%2"" iş yerinin ""%1"" kontrolü'"),
			TrimAll(Validation),
			CurrentFilter.Organization,
			Format(CurrentFilter.CheckedPeriod, ""));
			
		If CheckParameters.VerificationFailed Then
			EventComment = NStr("vi = '%1 không thực hiện được do: %2.';
								|ru = '%1 не выполнена по причине: %2.';
								|en = '%1 is not executed. Reason: %2.'; fa = '%1 is not executed. Reason: %2.';
								|it = '%1 non eseguita a causa di: %2.';
								|pl = '%1 nie wykonana z powodu: %2.';
								|tr = '%1 %2 nedeniyle gerçekleştirilemedi.'");
		ElsIf ObjectCount > 0 Then
			EventComment = NStr("vi = '%1 đã hoàn tất, các vấn đề được phát hiện: %3.';
								|ru = '%1 завершена, выявлено проблем: %3.';
								|en = '%1 completed, detected issues: %3.'; fa = '%1 completed, detected issues: %3.';
								|it = '%1 terminata, problemi trovati: %3.';
								|pl = '%1 zakończona, wykryto problem: %3.';
								|tr = '%1 tamamlandı, ortaya çıkan problem: %3.'");
		Else
			EventComment = NStr("vi = '%1 đã hoàn tất thành công, không phát hiện vấn đề gì.';
								|ru = '%1 завершена успешно, проблем не выявлено.';
								|en = '%1 successfully completed, no issue detected.'; fa = '%1 successfully completed, no issue detected.';
								|it = '%1 terminata con successo, nessun problema rilevato.';
								|pl = '%1 zakończona pomyślnie, problemów nie wykryto.';
								|tr = '%1 başarıyla tamamlandı, problem çıkmadı.'");
		EndIf;
		
		EventComment = StringFunctionsClientServer.SubstituteParametersToString(
			EventComment,
			PresentationOfVerification,
			CheckParameters.ReasonForCheckDecline,
			ObjectCount);
		
		WriteLogEvent(
			AuditOfSystemStateClientServer.EventLogEventName(), 
			EventLogLevel.Information, 
			Metadata.Catalogs.AccountingCheckRules, 
			Validation, 
			EventComment);
		
	EndDo;
	
	If Not CheckParameters.VerificationFailed Then
		
		// We will write down detailed information on the found problems and problematic objects.
		ProblemRecordSet = InformationRegisters.SystemStatusIssues.CreateRecordSet();
		RecordsetObjects  = InformationRegisters.ObjectsOfSystemStatusIssues.CreateRecordSet();
		
		For Each IssueDetails In CheckParameters.IdentifiedProblems Do
			
			RecordingProblem = ProblemRecordSet.Add();
			FillPropertyValues(RecordingProblem, IssueDetails,,
				"AdditionalInformation"
				+ ?(Not VerificationDetails_1.DetailsByCompany, ", Organization", "")
				+ ?(Not VerificationDetails_1.DetailsByPeriod, ", CheckedPeriod", ""));
			
			RecordingProblem.Validation 				= Validation;
			RecordingProblem.AdditionalInformation = New ValueStorage(IssueDetails.AdditionalInformation, New Deflation(9));
			
			For Each ObjectDetails In IssueDetails.Objects Do
				
				ObjectRecord = RecordsetObjects.Add();
				FillPropertyValues(ObjectRecord, RecordingProblem);
				FillPropertyValues(ObjectRecord, ObjectDetails);
				
			EndDo;
			
		EndDo;
		
		If ProblemRecordSet.Count() > 0 Then
			ProblemRecordSet.Write(False);
		EndIf;
		If RecordsetObjects.Count() > 0 Then
			RecordsetObjects.Write(False);
		EndIf;
		
	EndIf;
	
	CheckParameters.Insert("ProblemsGrouped", ProblemsGrouped);
	
	Return CheckParameters;
	
EndFunction

// Clears the previous results of the specified checks.
//
Procedure ClearInspectionResults(ChecksArray, CompanyArray, BeginOfPeriod, EndOfPeriod = Undefined) Export
	
	If Not ValueIsFilled(ChecksArray) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	""MonthEndChecklistsStatus"" AS RegisterName,
	|	1 AS Order,
	|	ChecksResults.Validation AS Validation,
	|	ChecksResults.Organization AS Organization,
	|	ChecksResults.CheckedPeriod AS CheckedPeriod
	|FROM
	|	InformationRegister.MonthEndChecklistsStatus AS ChecksResults
	|WHERE
	|	ChecksResults.Validation IN(&ChecksArray)
	|	AND (NOT ChecksResults.Validation.DetailsByCompany
	|			OR ChecksResults.Organization IN (&CompanyArray))
	|	AND (NOT ChecksResults.Validation.DetailsByPeriod
	|			OR ChecksResults.CheckedPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""SystemStatusIssues"",
	|	2,
	|	ChecksResults.Validation,
	|	ChecksResults.Organization,
	|	ChecksResults.CheckedPeriod
	|FROM
	|	InformationRegister.SystemStatusIssues AS ChecksResults
	|WHERE
	|	ChecksResults.Validation IN(&ChecksArray)
	|	AND (NOT ChecksResults.Validation.DetailsByCompany
	|			OR ChecksResults.Organization IN (&CompanyArray))
	|	AND (NOT ChecksResults.Validation.DetailsByPeriod
	|			OR ChecksResults.CheckedPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""ObjectsOfSystemStatusIssues"",
	|	3,
	|	ChecksResults.Validation,
	|	ChecksResults.Organization,
	|	ChecksResults.CheckedPeriod
	|FROM
	|	InformationRegister.ObjectsOfSystemStatusIssues AS ChecksResults
	|WHERE
	|	ChecksResults.Validation IN(&ChecksArray)
	|	AND (NOT ChecksResults.Validation.DetailsByCompany
	|			OR ChecksResults.Organization IN (&CompanyArray))
	|	AND (NOT ChecksResults.Validation.DetailsByPeriod
	|			OR ChecksResults.CheckedPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|
	|ORDER BY
	|	Order DESC,
	|	Validation,
	|	Organization,
	|	CheckedPeriod";
	
	Query.SetParameter("ChecksArray",    ChecksArray);
	Query.SetParameter("CompanyArray", CompanyArray);
	Query.SetParameter("BeginOfPeriod",     BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", 	   ?(ValueIsFilled(EndOfPeriod), EndOfPeriod, BeginOfPeriod));
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		RecordSet = InformationRegisters[Selection.RegisterName].CreateRecordSet(); // InformationRegisterRecordSet.MonthEndChecklistsStatus, InformationRegisterRecordSet.SystemStatusIssues, InformationRegisterRecordSet.ObjectsOfSystemStatusIssues
		
		RecordSet.Filter.Validation.Set(Selection.Validation);
		RecordSet.Filter.Organization.Set(Selection.Organization);
		RecordSet.Filter.CheckedPeriod.Set(Selection.CheckedPeriod);
		
		RecordSet.Write(True);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ResultsOfVerification

// Returns a table of the results of the specified checks.
//
// Parameters:
// 	ChecksArray - Array -
// 	CompanyArray - Array - 
// 	BeginOfPeriod - Date - 
// 	EndOfPeriod - Date -
// 	
// Returns:
// 	ValueTable -
//
Function SystemStateProblemTable(ChecksArray, CompanyArray, BeginOfPeriod, EndOfPeriod = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Objects.Issue1,
	|	COUNT(Objects.Issue1) AS ObjectCount
	|INTO TTNumberOfObjects
	|FROM
	|	InformationRegister.ObjectsOfSystemStatusIssues AS Objects
	|WHERE
	|	Objects.Validation IN(&ChecksArray)
	|	AND (NOT Objects.Validation.DetailsByCompany
	|			OR Objects.Organization IN (&CompanyArray))
	|	AND (NOT Objects.Validation.DetailsByPeriod
	|			OR Objects.CheckedPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|
	|GROUP BY
	|	Objects.Issue1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Issues.Validation,
	|	Issues.Organization,
	|	Issues.CheckedPeriod,
	|	Issues.Issue1,
	|	CAST(Issues.Presentation AS STRING(1024)) AS Presentation,
	|	Issues.Importance AS Importance,
	|	CASE
	|		WHEN Issues.Importance = VALUE(Enum.AccountingIssueSeverity.Error)
	|			THEN 1
	|		WHEN Issues.Importance = VALUE(Enum.AccountingIssueSeverity.Warning)
	|			THEN 2
	|		WHEN Issues.Importance = VALUE(Enum.AccountingIssueSeverity.Information)
	|			THEN 4
	|		ELSE 3
	|	END AS Order,
	|	ISNULL(Objects.ObjectCount, 1) AS ObjectCount
	|FROM
	|	InformationRegister.SystemStatusIssues AS Issues
	|		LEFT JOIN TTNumberOfObjects AS Objects
	|		ON Issues.Issue1 = Objects.Issue1
	|WHERE
	|	Issues.Validation IN(&ChecksArray)
	|	AND (NOT Issues.Validation.DetailsByCompany
	|			OR Issues.Organization IN (&CompanyArray))
	|	AND (NOT Issues.Validation.DetailsByPeriod
	|			OR Issues.CheckedPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|
	|ORDER BY
	|	Order,
	|	Issues.Validation,
	|	Presentation";
	
	Query.SetParameter("ChecksArray",    ChecksArray);
	Query.SetParameter("CompanyArray", CompanyArray);
	Query.SetParameter("BeginOfPeriod",     BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", 	   ?(ValueIsFilled(EndOfPeriod), EndOfPeriod, BeginOfPeriod));
	
	ProblemTable = Query.Execute().Unload();
	
	Return ProblemTable;
	
EndFunction

// Returns a table of updated results of the specified checks.
//
// Parameters:
// 	ChecksArray - Array -
// 	CompanyArray - Array -
// 	BeginOfPeriod - Date -
// 	EndOfPeriod - Date -
// 	
// Returns:
// 	ValueTable -
//
Function TableOfSystemStateProblemObjects(ChecksArray, CompanyArray, BeginOfPeriod, EndOfPeriod = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Issues.Validation,
	|	Issues.Organization,
	|	Issues.CheckedPeriod,
	|	Issues.Issue1,
	|	CAST(Issues.Presentation AS STRING(1024)) AS IssuePresentation,
	|	Issues.Importance AS Importance,
	|	CASE
	|		WHEN Issues.Importance = VALUE(Enum.AccountingIssueSeverity.Error)
	|			THEN 1
	|		WHEN Issues.Importance = VALUE(Enum.AccountingIssueSeverity.Warning)
	|			THEN 2
	|		WHEN Issues.Importance = VALUE(Enum.AccountingIssueSeverity.Information)
	|			THEN 4
	|		ELSE 3
	|	END AS Order,
	|	CAST(Objects.Presentation AS STRING(1024)) AS ObjectPresentation
	|FROM
	|	InformationRegister.ObjectsOfSystemStatusIssues AS Objects
	|	INNER JOIN InformationRegister.SystemStatusIssues AS Issues
	|		ON Objects.Issue1 = Issues.Issue1
	|WHERE
	|	Objects.Validation IN(&ChecksArray)
	|	AND (NOT Objects.Validation.DetailsByCompany
	|			OR Objects.Organization IN (&CompanyArray))
	|	AND (NOT Objects.Validation.DetailsByPeriod
	|			OR Objects.CheckedPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|
	|ORDER BY
	|	Order,
	|	Issues.Validation,
	|	IssuePresentation,
	|	ObjectPresentation";
	
	Query.SetParameter("ChecksArray",    ChecksArray);
	Query.SetParameter("CompanyArray", CompanyArray);
	Query.SetParameter("BeginOfPeriod",     BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", 	   ?(ValueIsFilled(EndOfPeriod), EndOfPeriod, BeginOfPeriod));
	
	ProblemObjectTable = Query.Execute().Unload();
	
	Return ProblemObjectTable;
	
EndFunction

#EndRegion

#Region SearchForChecks

// Returns a table of checks for the specified selections.
//
// Parameters:
// 	AccountingChecksContext - Arbitrary -
// 	AccountingCheckContextClarification - Arbitrary -
// 	ExecutedOnlyInContext - Boolean -
// 	
// Returns:
// 	ValueTable -
//
Function TableOfChecksByContext(AccountingChecksContext, AccountingCheckContextClarification = Undefined, ExecutedOnlyInContext = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	T.Ref AS Validation,
	|	T.Id AS Id,
	|	T.CheckStartDate AS CheckStartDate,
	|	T.AccountingCheckContextClarification AS AccountingCheckContextClarification
	|FROM
	|	Catalog.AccountingCheckRules AS T
	|WHERE
	|	NOT T.DeletionMark
	|	AND NOT T.IsFolder
	|	AND T.AccountingChecksContext = &AccountingChecksContext
	|	AND (&ExecutedOnlyInContext = UNDEFINED OR T.ExecutedOnlyInContext = &ExecutedOnlyInContext)
	|	AND (&WithoutSpecifyingExecutionContext OR T.AccountingCheckContextClarification IN (&AccountingCheckContextClarification))
	|	AND NOT &SimplifiedAutoTesting
	|
	|ORDER BY
	|	Id";
	
	Query.SetParameter("AccountingChecksContext", AccountingChecksContext);
	Query.SetParameter("ExecutedOnlyInContext", ExecutedOnlyInContext);
	Query.SetParameter("SimplifiedAutoTesting", MonthEndTransactionsServer.SimplifiedAutoTesting());
	
	If AccountingCheckContextClarification = Undefined Then
		
		Query.SetParameter("AccountingCheckContextClarification", New Array);
		Query.SetParameter("WithoutSpecifyingExecutionContext", True);
		
	ElsIf TypeOf(AccountingCheckContextClarification) = Type("Array") Then
		
		Query.SetParameter("AccountingCheckContextClarification", AccountingCheckContextClarification);
		Query.SetParameter("WithoutSpecifyingExecutionContext", False);
		
	Else
		
		ArrayOfConstraints = New Array;
		ArrayOfConstraints.Add(AccountingCheckContextClarification);
		
		Query.SetParameter("AccountingCheckContextClarification", ArrayOfConstraints);
		Query.SetParameter("WithoutSpecifyingExecutionContext", False);
		
	EndIf;
	
	TableOfChecks = Query.Execute().Unload();
	
	Return TableOfChecks;
	
EndFunction

// Returns a check for the specified selections.
// 
// Parameters:
//  AccountingChecksContext - Arbitrary - The context of accounting checks
//  Id - String - Id
//  ReturnOnlyLink - Boolean - Return Only The Link
//  FillInChecksIfNotFound - Boolean - Fill In Checks If Not Found
// 
// Returns:
//  Undefined, Structure - verification parameters
Function FindValidationByKeyFields(AccountingChecksContext, Id, ReturnOnlyLink = True, FillInChecksIfNotFound = True) Export
	
	CheckByID = AccountingAudit.CheckByID(Id);
	
	If ValueIsFilled(CheckByID) Then
		
		If ReturnOnlyLink Then
			Return CheckByID;
		EndIf;
		
		Result = New Structure("Ref, Description, IssueSeverity, Id, Use, RunMethod,
			|AccountingChecksContext, AccountingCheckContextClarification, ExecutedOnlyInContext, PreviousCheck, Handler, Comment");
		FillPropertyValues(Result, CheckByID);
		
		Return Result;
		
	EndIf;
	
	If FillInChecksIfNotFound Then
		
		FillInSystemStateCheckCatalog();
		
		Return FindValidationByKeyFields(AccountingChecksContext, Id, ReturnOnlyLink, False);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region RegisteringRandomValidationIssues

// Generates a description of the problem identified during verification.
//
// Parameters:
// 	IssueText - String - 
// 	Importance - EnumRef.AccountingIssueSeverity -
// 	ClarificationText - String -
// 	Object - Arbitrary -
// 	AdditionalInformation - Arbitrary -
// 	
// Returns:
// 	Structure - LongDesc:
// * Object - Structure - LongDesc:
//  ** Presentation - String -
//  ** ThisIsACompositeObject - Boolean -
//  ** CompositeObject - UUID -
//  ** CompositeObjectDrillDown - ValueStorage -
//  ** Object - Arbitrary -
// * Issue1 - Structure - LongDesc:
//  ** Presentation - String -
//  ** Importance - EnumRef.AccountingIssueSeverity -
//  ** AdditionalInformation - ValueStorage - 
//
Function GenerateProblemDescription(IssueText, Importance = Undefined, ClarificationText = "",
			Object = Undefined, AdditionalInformation = Undefined) Export
	
	IssueDetails = New Structure;
	IssueDetails.Insert("Issue1", New Structure);
	IssueDetails.Insert("Object",   New Structure);
	
	// Fields of the register of system state problems.
	IssueDetails.Issue1.Insert("Presentation", IssueText);
	IssueDetails.Issue1.Insert("Importance",
		?(ValueIsFilled(Importance), Importance, Enums.AccountingIssueSeverity.Error));
	IssueDetails.Issue1.Insert("AdditionalInformation",
		New ValueStorage(AdditionalInformation, New Deflation(9)));
		
	// The fields of the register of the system state problem objects.
	If ValueIsFilled(ClarificationText) Or ValueIsFilled(Object) Then
		
		IssueDetails.Object.Insert("Presentation", ClarificationText);
		IssueDetails.Object.Insert("ThisIsACompositeObject",
			(Object = Undefined Or TypeOf(Object) = Type("Structure")));
		IssueDetails.Object.Insert("CompositeObject", New UUID);
		
		If IssueDetails.Object.ThisIsACompositeObject Then
			IssueDetails.Object.Insert("CompositeObjectDrillDown",
				New ValueStorage(Object, New Deflation(9)));
		Else
			IssueDetails.Object.Insert("Object", Object);
		EndIf;
		
	EndIf;
	
	Return IssueDetails;
	
EndFunction

// Registers information about the detected problem in the IB for any specified check.
//
// Parameters:
// 	Validation - CatalogRef.AccountingCheckRules - 
// 	Organization - CatalogRef.Companies - 
// 	CheckedPeriod - Date -
// 	IssueDetails - See AuditOfSystemState.GenerateProblemDescription
//
Procedure RegisterProblem(Validation, Organization, CheckedPeriod, IssueDetails) Export
	
	BeginTransaction();
	
	// Registration of the fact of verification.
	Try
		
		Block = New DataLock;
		
		LockItem = Block.Add("InformationRegister.MonthEndChecklistsStatus");
		LockItem.Mode = DataLockMode.Exclusive;
		
		LockItem.SetValue("Validation", 		  Validation);
		LockItem.SetValue("Organization", 	  Organization);
		LockItem.SetValue("CheckedPeriod", CheckedPeriod);
		
		LockItem = Block.Add("InformationRegister.SystemStatusIssues");
		LockItem.Mode = DataLockMode.Exclusive;
		
		LockItem.SetValue("Validation", 		  Validation);
		LockItem.SetValue("Organization", 	  Organization);
		LockItem.SetValue("CheckedPeriod", CheckedPeriod);
		
		Block.Lock();
		
		Query = New Query;
		
		Query.Text =
		"SELECT
		|	ChecksExecute.Validation
		|FROM
		|	InformationRegister.MonthEndChecklistsStatus AS ChecksExecute
		|WHERE
		|	ChecksExecute.Validation = &Validation
		|	AND ChecksExecute.Organization = &Organization
		|	AND ChecksExecute.CheckedPeriod = &CheckedPeriod";
		
		Query.SetParameter("Validation", 			Validation);
		Query.SetParameter("Organization", 		Organization);
		Query.SetParameter("CheckedPeriod", 	CheckedPeriod);
		
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			
			RecordSet = InformationRegisters.MonthEndChecklistsStatus.CreateRecordSet();
			
			RecordSet.Filter.Validation.Set(Validation);
			RecordSet.Filter.Organization.Set(Organization);
			RecordSet.Filter.CheckedPeriod.Set(CheckedPeriod);
			
			Record = RecordSet.Add();
			Record.Validation			 = Validation;
			Record.Organization		 = Organization;
			Record.CheckedPeriod = CheckedPeriod;
			Record.ExecutionDate	 = CurrentSessionDate();
			Record.IssuesAreDetected	 = True;
			
			If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
				InfobaseUpdate.WriteRecordSet(RecordSet, False);
			Else
				RecordSet.Write(False);
			EndIf;
			
		EndIf;
		
		// Registration of the identified problem.
		Query.Text =
		"SELECT
		|	Issues.Issue1
		|FROM
		|	InformationRegister.SystemStatusIssues AS Issues
		|WHERE
		|	Issues.Validation = &Validation
		|	AND Issues.Organization = &Organization
		|	AND Issues.CheckedPeriod = &CheckedPeriod
		|	AND Issues.Importance = &Importance
		|	AND CAST(Issues.Presentation AS STRING(1024)) = CAST(&IssuePresentation AS STRING(1024))";
		
		Query.SetParameter("IssuePresentation", IssueDetails.Issue1.Presentation);
		Query.SetParameter("Importance", 			   IssueDetails.Issue1.Importance);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			
			Issue1 = Selection.Issue1;
			
		Else
			
			Issue1 = New UUID;
			
			RecordSet = InformationRegisters.SystemStatusIssues.CreateRecordSet();
			
			Record = RecordSet.Add();
			FillPropertyValues(Record, IssueDetails.Issue1);
			
			Record.Validation			 = Validation;
			Record.Organization		 = Organization;
			Record.CheckedPeriod = CheckedPeriod;
			Record.Issue1			 = Issue1;
			
			If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
				InfobaseUpdate.WriteRecordSet(RecordSet, False);
			Else
				RecordSet.Write(False);
			EndIf;
			
		EndIf;
		
		// Registration of the problem object.
		If ValueIsFilled(IssueDetails.Object) Then
		
			RecordSet = InformationRegisters.ObjectsOfSystemStatusIssues.CreateRecordSet();
			
			Record = RecordSet.Add();
			FillPropertyValues(Record, IssueDetails.Object);
			
			Record.Validation			 = Validation;
			Record.Organization		 = Organization;
			Record.CheckedPeriod = CheckedPeriod;
			Record.Issue1			 = Issue1;
			
			If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
				InfobaseUpdate.WriteRecordSet(RecordSet, False);
			Else
				RecordSet.Write(False);
			EndIf;
			
		EndIf;
	
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = DetailErrorDescription(ErrorInfo());
		
		Raise ErrorText;
		
	EndTry;
	
EndProcedure

#EndRegion

#Region LoggingProblemsFromRunningCheck

// Adds a row to the table of identified issues. Called when performing a check.
//
// Parameters:
// 	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
// 	Organization - CatalogRef.Companies - 
// 	CheckedPeriod - Date -
// 	Presentation - String -
// 	Importance - EnumRef.AccountingIssueSeverity - 
// 	AdditionalInformation - Arbitrary -
//
Procedure AddRowToProblemTable(CheckParameters, Organization, CheckedPeriod, Presentation,
			Importance = Undefined, AdditionalInformation = Undefined) Export
	
	FoundProblem = CheckParameters.IdentifiedProblems.Add();
	
	FoundProblem.Organization				= Organization;
	FoundProblem.CheckedPeriod			= CheckedPeriod;
	FoundProblem.Presentation				= Presentation;
	
	FoundProblem.Importance					= Importance;
	FoundProblem.AdditionalInformation 	= New ValueStorage(AdditionalInformation, New Deflation(9));
	
EndProcedure

// Adds a reference object to the last row of the detected problems table. Called when performing a check.
//
// Parameters:
// 	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
// 	Object - Arbitrary -
// 	Presentation - String -
//
Procedure AddObjectToFixedProblem(CheckParameters, Object, Presentation = "") Export
	
	FoundProblem = CheckParameters.IdentifiedProblems[CheckParameters.IdentifiedProblems.Count() - 1];
	
	ObjectAlreadyAdded = False;
	
	For Each CurrentRow In FoundProblem.Objects Do
		
		If Not CurrentRow.ThisIsACompositeObject And CurrentRow.Object = Object Then
			CurrentRow.Presentation = CurrentRow.Presentation + Chars.LF + Presentation;
			ObjectAlreadyAdded = True;
			Break;
		EndIf;
		
	EndDo;
	
	If Not ObjectAlreadyAdded Then
		
		ObjectDetails = New Structure;
		ObjectDetails.Insert("ThisIsACompositeObject", False);
		ObjectDetails.Insert("Object", 			   Object);
		ObjectDetails.Insert("Presentation", 	   Presentation);
	
		FoundProblem.Objects.Add(ObjectDetails);
		
	EndIf;
	
EndProcedure

// Adds a non-reference object to the last row of the detected problems table. Called when performing a check.
//
// Parameters:
// 	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
// 	Details - Arbitrary -
// 	Presentation - String -
//
Procedure AddCompositeObjectToFixedProblem(CheckParameters, Details, Presentation = "") Export
	
	ObjectDetails = New Structure;
	ObjectDetails.Insert("ThisIsACompositeObject", 			 True);
	ObjectDetails.Insert("CompositeObject", 			 New UUID);
	ObjectDetails.Insert("CompositeObjectDrillDown", New ValueStorage(Details, New Deflation(9)));
	ObjectDetails.Insert("Presentation", 	   			 Presentation);
	
	FoundProblem = CheckParameters.IdentifiedProblems.Get(CheckParameters.IdentifiedProblems.Count() - 1);
	FoundProblem.Objects.Add(ObjectDetails);
	
EndProcedure

#EndRegion

#Region DescriptionOfChecks

// Returns a table of checks.
// 
// Returns:
// 	ValueTable - LongDesc:
// * ParentID - String -
// * Description - String -
// * ExecutionSchedule - JobSchedule -  
// * AdditionalParameterDescription - Arbitrary -
// 
Function SystemStateCheckTable() Export
	
	TableOfChecks = New ValueTable;
	
	StructureOfServiceParameters_ = New Structure("
		|GUIDScheduledJob, ScheduledJobPresentation,
		|Schedule, AdditionalAutoCheckParameters, AdditionalParameterDescription");
	
	TableOfChecks.Columns.Add("ParentID", New TypeDescription("String"));
	TableOfChecks.Columns.Add("Description", New TypeDescription("String"));
	TableOfChecks.Columns.Add("ExecutionSchedule");
	TableOfChecks.Columns.Add("AdditionalParameterDescription");
	
	For Each MetaAttribute In Metadata.Catalogs.AccountingCheckRules.Attributes Do
		If Not StructureOfServiceParameters_.Property(MetaAttribute.Name) Then
			TableOfChecks.Columns.Add(MetaAttribute.Name, MetaAttribute.Type);
		EndIf;
	EndDo;
	
	Return TableOfChecks;
	
EndFunction

// Generates a description of the system status check.
// 
// Parameters:
// 	Validation - CatalogRef.AccountingCheckRules - 
// 	AccountingChecksContext - DefinedType.AccountingChecksContext, Null -
// 	ValuesOfAdditionalParameters - Undefined, Structure - LongDesc
// Returns:
// 	Structure - LongDesc:
// * IdentifiedProblems - See AuditOfSystemState.TableOfDetectedProblemsDuringVerification
// * Filters - See AuditOfSystemState.TableOfSelectionsForVerification
// * ReasonForCheckDecline - String -
// * VerificationFailed - Boolean -
// * AccountingChecksContext - DefinedType.AccountingChecksContext, Null -
// * AdditionalParameters - Undefined -
//
Function InitializeVerificationParameters(Validation, AccountingChecksContext = NULL, ValuesOfAdditionalParameters = Undefined) Export
	
	If AccountingChecksContext = NULL Then
		AccountingChecksContext = Common.ObjectAttributeValue(Validation, "AccountingChecksContext");
	EndIf;
	
	CheckParameters = New Structure;
	
	CheckParameters.Insert("Validation", 				  Validation);
	CheckParameters.Insert("AdditionalParameters", ValuesOfAdditionalParameters);
	CheckParameters.Insert("AccountingChecksContext", 	  AccountingChecksContext);
	
	CheckParameters.Insert("VerificationFailed",  	  False);
	CheckParameters.Insert("ReasonForCheckDecline", "");
	
	CheckParameters.Insert("Filters", 			 	  TableOfSelectionsForVerification());
	CheckParameters.Insert("IdentifiedProblems", 	  TableOfDetectedProblemsDuringVerification());
	
	Return CheckParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region FillingInVerificationCatalog

// Returns a table of check groups.
// 
// Returns:
// 	ValueTable - LongDesc:
// * ParentID - String -
// * Description - String -
// * AccountingChecksContext - DefinedType.AccountingChecksContext -
// * Id - String -
//
Function TableOfSystemStateCheckGroups() Export
	
	TableOfInspectionGroups = New ValueTable;
	
	TableOfInspectionGroups.Columns.Add("ParentID", New TypeDescription("String"));
	TableOfInspectionGroups.Columns.Add("Description", 		   New TypeDescription("String"));
	TableOfInspectionGroups.Columns.Add("AccountingChecksContext",    New TypeDescription(Metadata.DefinedTypes.AccountingChecksContext.Type));
	TableOfInspectionGroups.Columns.Add("Id", 		   New TypeDescription("String"));
	
	Return TableOfInspectionGroups;
	
EndFunction

Function FillInSystemStateCheckCatalog(TypeOfExecutionContext = Undefined, CheckUpdateMode = False) Export
	
	// Let's call the BSP mechanism to fill in the checks
	AccountingAuditInternal.UpdateAuxiliaryRegisterDataByConfigurationChanges();
	
	Return True;
	
EndFunction

// It is intended for enabling your own accounting verification rules.
//
// Parameters:
//   ChecksGroups - ValueTable - the table to which the groups of checks are added:
//      * Description                 - String - name of the verification group.
//      * GroupID          - String - The string identifier of the verification group, for example: 
//                                       , "System checks", "Month closure", "Checkinds", etc. is
//                                       required to be filled in.
//      * Id                - String - string ID of the validation group. Required to fill in.
//                                       For uniqueness, the identifier format should be selected as follows:
//                                       "<Name of the software product>.<Verification ID>". 
//                                       For example: "Standard subsystems.System checks".
//      * AccountingChecksContext - DefinedType.AccountingChecksContext - A value that further
//                                       clarifies whether a group of accounting checks belongs to a certain
//                                       category.
//      * Comment                  - String - comment on the verification group.
//
//   Checks - ValueTable - the table to which the checks are added:
//      * GroupID          - String - The string identifier of the verification group, for example: 
//                                                , "System checks", "Month closure", "Checkinds", etc. is
//                                                 required to be filled in.
//      * Description                 - String - the name of the check displayed to the user.
//      * Reasons                      - String - description of the possible causes that lead to the problem.
//      * Recommendation                 - String - a recommendation to solve the problem.
//      * Id                - String - string ID of the element. Required to fill in.
//                                                The format of the ID should be as follows:
//                                                <Name of the software product>.<Verification ID>. For example:
//                                                Standard subsystems.System checks.
//      * CheckStartDate           - Date - a threshold date that indicates the boundary of the objects being checked
//                                              (only for objects with a date, such as documents). Objects with a date 
//                                              less than the specified date should not be checked. By default 
//                                              , it is not filled in (i.e. check everything).
//      * IssuesLimit                 - Number - the number of objects to check. The default is 1000. 
//                                               If 0 is specified, then all objects should be checked.
//      * HandlerChecks           - String - the name of the server shared module's export handler procedure
//                                                in the form of a module name.Procedure name.
//      * GoToCorrectionHandler - String - the name of the export procedure-handler of the client common module
//                                                  for the transition to fixing the problem in the form of "Module name.Procedure name"
//                                                  or the full name of the form that should be opened to fix the problem.
//                                                  The handler procedure accepts two parameters as input: 
//                                                    Correction Parametersconstruction - with properties:
//                                                      Verification ID - String - String verification ID;
//                                                      Check-out View - Reference Link.Type of check - a type of check
//                                                               that further clarifies the area of the problem correction;
//                                                    Additional parameters - Undefined - the parameter is not used.
//                                                 When opening a form, the same parameters as properties are passed to it 
//                                                 The correction parameters of the above structure.
//      * NoCheckHandler       - Boolean - indicates a service check that doesn't have a handler procedure.
//      * ImportanceChangeDenied   - Boolean - if True, then the administrator will not be able to reconfigure 
//                                                the importance of this check.
//      * AccountingChecksContext - DefinedType.AccountingChecksContext - A value that additionally 
//                                                specifies whether the accounting check belongs to a specific group 
//                                                or category.
//      * AccountingCheckContextClarification - DefinedType.AccountingCheckContextClarification - the second value, 
//                                                 which further clarifies whether the accounting check belongs 
//                                                 to a specific group or category.
//      * AdditionalParameters      - ValueStorage - arbitrary additional verification information
//                                                 for programmatic use.
//      * Comment                  - String - text comment on the review.
//      * TurnedOff                    - Boolean - if True, the check will not be performed in the background as scheduled.
//      * SupportsRandomCheck - Boolean - if True, then the check can be called to check a specific object.
//
// Example:
//   1) Adding validation
//      Verification = Verification.Add();
//      Verification.Group ID = "System Checks";
//      Verification.Name = NStr("ru='Demo: Checking comments in documents ""Demo: Receipt of goods""'");
//      Verification.Reasons = NStr("ru='No comment entered in the document.'");
//      Verification.Recommendation = NStr("ru='Enter a comment in the document.'");
//      Verification.ID = "Check the commentaryin the availability of products";
//      Verification.Check Handler = "_demostandard subsystems.Check the commentaryin the availability of goods";
//      Verification.Check Date = Date('20140101000000');
//      Verification.LimitProblem = 3;
//   2) Adding a group of checks
//      Test Group = Test group.Add();
//      The verification group.Name = NStr("ru='System checks'");
//      The verification group.ID = "Standard Subsystems.System checks";
//      The verification group.Contextcheckingaccounting = "Systemchecks";
//
Procedure OnDefineChecks(ChecksGroups, Checks) Export
	
	UpdateTransitionChecks();
	
	TableOfInspectionGroups = AuditOfSystemStateCached.FillInVerificationGroupsForRegistration();
	TableOfChecks = AuditOfSystemStateCached.FillOutChecksForRegistration();
	
	For Each CurrRow In TableOfInspectionGroups Do
		
		NwRw = ChecksGroups.Add();
		FillPropertyValues(NwRw, CurrRow);
		
	EndDo;
	
	For Each CurrRow In TableOfChecks Do
		
		NwRw = Checks.Add();
		FillPropertyValues(NwRw, CurrRow);
		
	EndDo;
		
EndProcedure


// Updates checks when switching to a new version of the program.
Procedure UpdateTransitionChecks()
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	T.Ref AS Ref
	|FROM
	|	Catalog.AccountingCheckRules AS T
	|		INNER JOIN Catalog.MonthEndClosingOperations AS Filter
	|		ON T.AccountingChecksContext = Filter.Ref
	|WHERE
	|	T.IsFolder
	|	AND T.Parent.Id = &IdOfMonthEndClosingGroup
	|	AND T.Id = &OldGroupId
	|	AND NOT T.DeletionMark";
	
	Query.SetParameter("IdOfMonthEndClosingGroup", "MonthEndTransactions");
	Query.SetParameter("OldGroupId", "GroupOfMonthClosingStageChecks");
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ChecksGroupObject = Selection.Ref.GetObject(); // CatalogObject.AccountingCheckRules
		ChecksGroupObject.Id = "Group" + "_" + Common.EnumerationValueName(ChecksGroupObject.AccountingChecksContext);
		ChecksGroupObject.AccountingCheckIsChanged = False;
		
		InfobaseUpdate.WriteData(ChecksGroupObject);
		
	EndDo;
	
	Query.Text =
	"SELECT
	|	T.Ref AS Ref
	|FROM
	|	Catalog.AccountingCheckRules AS T
	|WHERE
	|	T.AccountingChecksContext <> UNDEFINED
	|	AND T.AccountingCheckIsChanged
	|	AND NOT T.DeletionMark";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		CheckObject1 = Selection.Ref.GetObject(); // CatalogObject.AccountingCheckRules
		CheckObject1.AccountingCheckIsChanged = False;
		
		InfobaseUpdate.WriteData(CheckObject1);
		
	EndDo;
	
EndProcedure
	
// Accounting verification rules change before recording.
// 
// Parameters:
//  Source - CatalogObject.AccountingCheckRules - Source
//  Cancel - Boolean - Cancel
Procedure AccountingCheckRulesBeforeWrite(Source, Cancel) Export
	
	If Source.DeletionMark Or Cancel Then
		Return;
	EndIf;
	
	If Source.IsFolder Then
		DescriptionOfChecks = AuditOfSystemStateCached.FillInVerificationGroupsForRegistration();
	Else
		DescriptionOfChecks = AuditOfSystemStateCached.FillOutChecksForRegistration();
	EndIf;
	
	PropertiesToExclude = "";
	If Not Source.IsNew() And Not Source.IsFolder Then
		PropertiesToExclude = "IssueSeverity";
	EndIf;
	
	LongDesc = DescriptionOfChecks.Find(Source.Id, "Id");
	If LongDesc <> Undefined Then
		FillPropertyValues(Source, LongDesc, , PropertiesToExclude);
		Source.AccountingCheckIsChanged = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region BackgroundChecks

// performing a system State check with the general routine task "delete system state check".
// the method performs checks from the "accounting rules" Catalog with the "usage" attribute set
// and with an unspecified separate schedule.
//
Procedure PerformSystemStateChecks(FromRoutineTask = True) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DeleteSystemStateCheck);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Checks.Ref AS Validation,
	|	CASE
	|		WHEN &FromRoutineTask
	|			THEN Checks.AdditionalAutoCheckParameters
	|		ELSE Checks.AdditionalParameterDescription
	|	END AS CheckParameters
	|FROM
	|	Catalog.AccountingCheckRules AS Checks
	|WHERE
	|	Checks.Use
	|	AND NOT Checks.OnSeparateSchedule
	|
	|ORDER BY
	|	Checks.AccountingChecksContext,
	|	Checks.Id";
	
	Query.SetParameter("FromRoutineTask", FromRoutineTask);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		CheckSystemState(Selection.Validation, Selection.CheckParameters);
	EndDo;
	
EndProcedure

Procedure RunBackgroundChecks(Parameters, StorageAddress) Export
	
	ValuesOfAdditionalParameters = Undefined;
	Parameters.Property("ValuesOfAdditionalParameters", ValuesOfAdditionalParameters);
	ValuesOfAdditionalParametersMap = ValuesOfAdditionalParameters;
	
	For Each Validation In Parameters.ChecksArray Do
		
		If TypeOf(ValuesOfAdditionalParametersMap) = Type("Map") Then
			ValuesOfAdditionalParameters = ValuesOfAdditionalParametersMap.Get(Validation);
		EndIf;
		
		CheckSystemState(Validation, ValuesOfAdditionalParameters);
		
	EndDo;
	
EndProcedure

Function ScheduleSettingIsPossible() Export
	
	Return Not Common.DataSeparationEnabled() And Users.IsFullUser(, True);
	
EndFunction

#EndRegion

#Region DescriptionOfChecks

// Returns an empty selection table for checking.
//
// Returns:
// 	ValueTable - LongDesc:
// * Organization - CatalogRef.Companies -
// * CheckedPeriod - Date -
//
Function TableOfSelectionsForVerification() Export
	
	SelectionsForVerification = New ValueTable;
	SelectionsForVerification.Columns.Add("Organization", 	 	New TypeDescription("CatalogRef.Companies"));
	SelectionsForVerification.Columns.Add("CheckedPeriod", New TypeDescription("Date"));
	
	Return SelectionsForVerification;
	
EndFunction	

// Returns an empty table describing the detected problems during verification.
//
// Returns:
// 	ValueTable - LongDesc:
// * Organization - CatalogRef.Companies -
// * CheckedPeriod - Date -
// * Presentation - String -
// * Importance - EnumRef.AccountingIssueSeverity -
// * AdditionalInformation - Arbitrary - 
// * Objects - Array -
//
Function TableOfDetectedProblemsDuringVerification() Export
	
	IdentifiedProblems = New ValueTable;
	
	IdentifiedProblems.Columns.Add("Organization", 	 	 New TypeDescription("CatalogRef.Companies"));
	IdentifiedProblems.Columns.Add("CheckedPeriod", New TypeDescription("Date"));
	IdentifiedProblems.Columns.Add("Presentation", 	 New TypeDescription("String")); // for the Problem field
	IdentifiedProblems.Columns.Add("Importance", 	 	 New TypeDescription("EnumRef.AccountingIssueSeverity")); // optional
	IdentifiedProblems.Columns.Add("AdditionalInformation");
	
	IdentifiedProblems.Columns.Add("Objects", 		 	 New TypeDescription("Array"));
	
	IdentifiedProblems.Indexes.Add("Organization, CheckedPeriod");
	
	Return IdentifiedProblems;
	
EndFunction	

// This method is used to get arbitrary information related to the problem 
//	that is specified when the problem is detected at the time of verification.
//
// Parameters:
//	Issue1 - UUID - unique ID of the problem.
//
// Returns:
// 	Arbitrary - the value is of an arbitrary type or Undefined if the problem is not found
//
Function MoreInformationOnIssue(Issue1) Export
	
	QueryText = 
	"SELECT
	|	Issues.AdditionalInformation
	|FROM
	|	InformationRegister.SystemStatusIssues AS Issues
	|WHERE
	|	Issues.Issue1 = &Issue1";
	
	Query = New Query(QueryText);
	Query.SetParameter("Issue1", Issue1);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		AdditionalInformation = Selection.AdditionalInformation; // ValueStorage
		Return AdditionalInformation.Get();
	EndIf;
	
	Return Undefined;
	
EndFunction

// Starts checking the month's closing by its ID
//
// Parameters:
//   Validation            - CatalogRef.AccountingCheckRules, String - the check being executed or its ID.
//   CheckParameters   - See AuditOfSystemState.InitializeVerificationParameters
//
Procedure UniversalHandlerForMonthClosingChecks(Validation, CheckParameters) Export
	
	If TypeOf(Validation) <> Type("String") Then
		Return; // calling checks through standard BSP mechanics is not provided
	EndIf;
	
	TableOfChecks = AuditOfSystemStateCached.FillOutChecksForRegistration();
	
	CheckString = TableOfChecks.Find(Validation, "Id");
	If CheckString = Undefined Then
		Raise NStr("vi = 'Không tìm thấy thao tác kiểm tra với tên định danh';
					|ru = 'Не найдена проверка с идентификатором';
					|en = 'Check with ID is not found'; fa = 'Check with ID is not found';
					|it = 'Не найдена проверка с идентификатором';
					|pl = 'Check with ID is not found';
					|tr = 'Tanımlayıcı ile kontrol bulunamadı'") + " " + Validation;
	EndIf;
	
	ParametersArray = New Array;
	ParametersArray.Add(CheckParameters); // The verification parameters will be changed in the handler

	// Let's perform a check.
	Common.ExecuteConfigurationMethod(CheckString.SourceHandler, ParametersArray);
	
EndProcedure

#EndRegion

#EndRegion
