///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version          = "*";
	Handler.ExecutionMode = "Deferred";
	Handler.Id   = New UUID("c17ea385-6085-471f-ab94-219ec30a5a38");
	Handler.Comment     = NStr("vi = 'Đang cập nhật quy tắc kiểm tra kế toán phù hợp với thay đổi trong phiên bản mới của ứng dụng.
		|Trước khi hoàn tất xử lý, phần kiểm tra tiến hành kế toán sẽ không được sử dụng.';
		|ru = 'Обновляются правила проверки учета в соответствие с изменениями в новой версии приложения.
		|До завершения обработки часть проверок ведения учета будет недоступна.';
		|en = 'Updating data integrity checks to reflect the changes in the new version of the application.
		|Some of the checks will be unavailable until the update is complete.'; fa = 'Updating data integrity checks to reflect the changes in the new version of the application.
		|Some of the checks will be unavailable until the update is complete.';
		|it = 'Updating data integrity checks to reflect the changes in the new version of the application.
		|Some of the checks will be unavailable until the update is complete.';
		|pl = 'Updating data integrity checks to reflect the changes in the new version of the application.
		|Some of the checks will be unavailable until the update is complete.';
		|tr = 'Muhasebe kontrol kuralları, uygulamanın yeni sürümündeki değişikliklere göre güncelleniyor.
		|İşlem tamamlanana kadar bazı muhasebe kontrolleri kullanılamayacaktır.'");
	Handler.Procedure       = "AccountingAuditInternal.UpdateAuxiliaryRegisterDataByConfigurationChanges";
	
	Handler = Handlers.Add();
	Handler.Version                              = "3.0.1.25";
	Handler.Id                       = New UUID("4a240e04-87df-4c10-9f7f-97969c61e84f");
	Handler.Procedure                           = "InformationRegisters.AccountingCheckResults.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode                     = "Deferred";
	Handler.UpdateDataFillingProcedure = "InformationRegisters.AccountingCheckResults.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead                     = "InformationRegister.AccountingCheckResults";
	Handler.ObjectsToChange                   = "InformationRegister.AccountingCheckResults";
	Handler.ObjectsToLock                  = "InformationRegister.AccountingCheckResults";
	Handler.ExecutionPriorities                = InfobaseUpdate.HandlerExecutionPriorities();
	Handler.CheckProcedure                   = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment                         = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Bắt đầu điền dấu hiệu %1 và tính toán số tiền kiểm soát trong biểu ghi thông tin ""Kết quả kiểm tra kế toán"" để nâng cao hiệu suất.';
			|ru = 'Начальное заполнение признака %1 и расчет контрольных сумм в регистре сведений ""Результаты проверки учета"" для повышения производительности.';
			|en = 'Initial setting of the %1 flag and calculation of checksums in the ""Data integrity check results"" information register for better performance.'; fa = 'Initial setting of the %1 flag and calculation of checksums in the ""Data integrity check results"" information register for better performance.';
			|it = 'Начальное заполнение признака %1 и расчет контрольных сумм в регистре сведений ""Результаты проверки учета"" для повышения производительности.';
			|pl = 'Initial setting of the %1 flag and calculation of checksums in the ""Data integrity check results"" information register for better performance.';
			|tr = 'Performansı artırmak için ""Muhasebe kontrolü sonuçları"" bilgi kaydındaki %1 özelliğinin ilk doldurulması ve sağlama toplamlarının hesaplanması.'"),
		"IgnoreIssue");
	
	Handler = Handlers.Add();
	Handler.Version                              = "3.0.1.195";
	Handler.Id                       = New UUID("fcd45d27-8e5d-45dd-9648-deff60825ae1");
	Handler.Procedure                           = "Catalogs.AccountingCheckRules.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode                     = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.AccountingCheckRules.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead                     = "Catalog.AccountingCheckRules";
	Handler.ObjectsToChange                   = "Catalog.AccountingCheckRules";
	Handler.ObjectsToLock                  = "Catalog.AccountingCheckRules";
	Handler.ExecutionPriorities                = InfobaseUpdate.HandlerExecutionPriorities();
	Handler.CheckProcedure                   = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment                         = NStr("vi = 'Việc tắt sử dụng khởi động tự động hệ thống kiểm tra trong phân hệ kiểm soát tiến hành kế toán.';
													|ru = 'Отключение автоматического запуска системных проверок в подсистеме контроля ведения учета.';
													|en = 'Disabling automatic start of system checks in the ""Data integrity"" subsystem.'; fa = 'Disabling automatic start of system checks in the ""Data integrity"" subsystem.';
													|it = 'Disattivazione dell''avvio automatico delle verifiche di sistema nel sottosistema di controllo della contabilità.';
													|pl = 'Wyłączenie automatycznego uruchomienia sprawdzeń systemowych w podsystemie kontroli prowadzenia ewidencji.';
													|tr = 'Muhasebe kontrol alt sisteminde sistem kontrollerinin otomatik olarak başlatılmasını devre dışı bırakma.'");
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not SubsystemAvailable() Then
		Return;
	EndIf;
	
	AllIssues = SummaryInformationOnChecksKinds(Undefined, True, True);
	
	CheckKind = CheckKind("SystemChecks");
	Issues    = SummaryInformationOnChecksKinds(CheckKind, True, True);
	
	LastCheckInformation = LastAccountingCheckInformation();
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	Sections                 = ModuleToDoListServer.SectionsForObject("Report.AccountingCheckResults");
	FullUser = Users.IsFullUser();
	
	For Each Section In Sections Do
		
		OwnerID = "AccountingAudit" + StrReplace(Section.FullName(), ".", "_");
		If FullUser Then
			ToDoItem = ToDoList.Add();
			ToDoItem.Id  = OwnerID;
			ToDoItem.HasToDoItems       = AllIssues.HasErrors;
			ToDoItem.Important         = False;
			ToDoItem.Owner       = Section;
			ToDoItem.Presentation  = NStr("vi = 'Vấn đề tiến hành kế toán';
											|ru = 'Проблемы ведения учета';
											|en = 'Data integrity issues'; fa = 'Data integrity issues';
											|it = 'Problemi di contabilità';
											|pl = 'Problemy prowadzenia ewidencji';
											|tr = 'Muhasebe problemleri'");
			ToDoItem.Count     = AllIssues.Count;
			ToDoItem.FormParameters = New Structure;
			ToDoItem.Form          = "Report.AccountingCheckResults.Form";
		EndIf;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "AccountingAuditIncorrectData" + StrReplace(Section.FullName(), ".", "_");
		ToDoItem.HasToDoItems       = Issues.HasErrors;
		ToDoItem.Important         = True;
		ToDoItem.Owner       = ?(FullUser, OwnerID, Section);
		ToDoItem.Presentation  = NStr("vi = 'Dữ liệu sai';
										|ru = 'Некорректные данные';
										|en = 'Invalid data'; fa = 'داده‌های نامعتبر';
										|it = 'Dati errati';
										|pl = 'Niepoprawne dane';
										|tr = 'Hatalı veriler'");
		ToDoItem.Count     = Issues.Count;
		ToDoItem.FormParameters = New Structure("CheckKind", CheckKind);
		ToDoItem.Form          = "Report.AccountingCheckResults.Form";
		
		
		// No check was performed for a long time.
		If ValueIsFilled(LastCheckInformation.LastCheckDate) Then
			ToolTip = NStr("vi = 'Đã kiểm tra lần gần nhất %1.';
							|ru = 'Последняя проверка выполнялась %1.';
							|en = 'Last checked on %1.'; fa = 'Last checked on %1.';
							|it = 'Ultima verifica eseguita %1.';
							|pl = 'Ostatnie sprawdzenie zostało wykonane %1.';
							|tr = 'Son kontrol yapıldı %1.'");
			ToolTip = StringFunctionsClientServer.SubstituteParametersToString(ToolTip, 
				Format(LastCheckInformation.LastCheckDate, "DLF=D"));
		Else
			ToolTip = "";
		EndIf;
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "AccountingAuditCheckRequired" + StrReplace(Section.FullName(), ".", "_");
		ToDoItem.HasToDoItems       = LastCheckInformation.WarnSecondCheckRequired;
		ToDoItem.Important         = False;
		ToDoItem.Owner       = Section;
		ToDoItem.Presentation  = NStr("vi = 'Đã từ lâu không thực hiện kiểm tra tiến hành kế toán';
										|ru = 'Проверка ведения учета давно не выполнялась';
										|en = 'Data integrity has not been checked for a while'; fa = 'Data integrity has not been checked for a while';
										|it = 'Verifica di contabilità non eseguita da tempo';
										|pl = 'Sprawdzenie prowadzenia ewidencji nie było przeprowadzane przez długi czas';
										|tr = 'Muhasebe kontrolü uzun zamandır yapılmadı'");
		ToDoItem.ToolTip      = ToolTip;
		ToDoItem.Form          = "Catalog.AccountingCheckRules.ListForm";
	EndDo;
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	// Accounting integrity results will be generated at the next check. 
	// They shouldn't be imported or exported.
	Types.Add(Metadata.InformationRegisters.AccountingCheckResults);
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.AccountingCheck.Name);
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.InformationRegisters.AccountingCheckResults, True);
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ToDosBuiltIn = Common.SubsystemExists("StandardSubsystems.ToDoList");
	Count = 0;
	If Not Users.IsExternalUserSession() And Not ToDosBuiltIn Then
		Count = SummaryInformationOnChecksKinds(Undefined, True, True).Count;
	EndIf;
	
	Parameters.Insert("AccountingAudit",
		New FixedStructure("NotifyOfAccountingIssues1, AccountingIssuesCount",
			Not ToDosBuiltIn,
			Count));
	
EndProcedure

// See ODataInterfaceOverridable.OnPopulateDependantTablesForODataImportExport
Procedure OnPopulateDependantTablesForODataImportExport(Tables) Export
	
	Tables.Add(Metadata.InformationRegisters.AccountingCheckResults.FullName());
	
EndProcedure

// See ExportImportDataOverridable.OnRegisterDataExportHandlers
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	Handler = HandlersTable.Add();
	Handler.MetadataObject = Metadata.InformationRegisters.AccessKeysToRegisterAccountingCheckResults;
	Handler.Handler = InformationRegisters.AccessKeysToRegisterAccountingCheckResults;
	Handler.BeforeExportObject = True;
	Handler.Version = "1.0.0.1";
	
EndProcedure

// See CommonOverridable.OnSetUpValidationOfMethodsCalledAsArbitraryCode.
Procedure OnSetUpValidationOfMethodsCalledAsArbitraryCode(Settings) Export
	
	ProceduresNames = New Map;
	
	DescriptionOfChecks = AccountingAuditInternalCached.AccountingChecks();
	For Each Validation In DescriptionOfChecks.Checks Do
		ProceduresNames.Insert(Validation.HandlerChecks);
	EndDo;
	
	HandlerDetails = Settings.HandlersDetails.Add();
	HandlerDetails.ProceduresNames = ProceduresNames;
	HandlerDetails.ErrorTitle = NStr("vi = 'Hàm sự kiện kiểm tra tiến hành kế toán ""%1"".';
									|ru = 'Обработчик проверки ведения учета ""%1"".';
									|en = 'Data integrity check handler ""%1"".'; fa = 'Data integrity check handler ""%1"".';
									|it = 'Data integrity check handler ""%1"".';
									|pl = 'Data integrity check handler ""%1"".';
									|tr = '""%1"" muhasebe kontrol işleyicisi'");
	
	// Exceptions.
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.AccountingAuditInternal";
	CheckException.ProcedureName       = "ExecuteCheck";
	CheckException.ContentFragment = "Common.ExecuteConfigurationMethod(CheckString.HandlerChecks, HandlerParameters)";
	
EndProcedure

// Updates components of the system data integrity checks upon configuration change.
// 
// Parameters:
//  HasChanges - Boolean - return value. If recorded, True if data is changed; 
//                           otherwise, it is not changed.
//
Procedure UpdateAccountingChecksParameters(HasChanges = Undefined) Export
	
	SetPrivilegedMode(True);
	
	ChecksChecksum = ChecksChecksum();
	
	BeginTransaction();
	Try
		HasCurrentChanges = False;
		
		StandardSubsystemsServer.UpdateApplicationParameter(
			"StandardSubsystems.AccountingAudit.SystemChecks",
			ChecksChecksum, HasCurrentChanges);
		
		StandardSubsystemsServer.AddApplicationParameterChanges(
			"StandardSubsystems.AccountingAudit.SystemChecks",
			?(HasCurrentChanges, New FixedStructure("HasChanges", True), New FixedStructure()));
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If HasCurrentChanges Then
		HasChanges = True;
	EndIf;
	
EndProcedure

Function SystemCheckIssues() Export
	
	SummaryInformationOnChecksKinds = SummaryInformationOnChecksKinds("SystemChecks");
	Return SummaryInformationOnChecksKinds.Count > 0;
	
EndFunction

// Returns date and time of the current check as well as the need to display a warning
// about the second check.
//
Function LastAccountingCheckInformation(ChecksGroup = Undefined) Export
	
	Result = New Structure;
	Result.Insert("LastCheckDate", Undefined);
	Result.Insert("WarnSecondCheckRequired", False);
	
	Query = New Query(
		"SELECT
		|	ISNULL(MAX(AccountingChecksStates.LastRun), UNDEFINED) AS LastRun
		|FROM
		|	InformationRegister.AccountingChecksStates AS AccountingChecksStates
		|		LEFT JOIN Catalog.AccountingCheckRules AS AccountingCheckRules
		|		ON AccountingChecksStates.Validation = AccountingCheckRules.Ref
		|WHERE
		|	&FilterChecksGroup");
	If ChecksGroup = Undefined Then
		FilterChecksGroup = "TRUE";
	Else
		FilterChecksGroup = "AccountingCheckRules.AccountingChecksContext = &AccountingChecksContext";
	EndIf;	
	Query.Text = StrReplace(Query.Text, "&FilterChecksGroup", FilterChecksGroup);
	Query.SetParameter("AccountingChecksContext", "SystemChecks");
	SetPrivilegedMode(True);
	QueryResult = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Result.LastCheckDate = QueryResult[0].LastRun;
	If Result.LastCheckDate = Undefined Then
		Result.WarnSecondCheckRequired = True;
	Else
		TimeFromLastStart = (CurrentSessionDate() - Result.LastCheckDate) / (1000 * 60 * 60 * 30);
		Result.WarnSecondCheckRequired = TimeFromLastStart > 1; // More than 1 month.
	EndIf;
	
	Return Result;
	
EndFunction

Function AccountingSystemChecksInformation() Export
	
	Return LastAccountingCheckInformation("SystemChecks");
	
EndFunction

Function LastObjectCheck(Ref) Export
	Query = New Query;
	Query.Text =
		"SELECT TOP 1
		|	AccountingCheckResults.Detected AS Detected
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.ObjectWithIssue = &ObjectWithIssue
		|
		|ORDER BY
		|	Detected DESC";

	Query.SetParameter("ObjectWithIssue", Ref);

	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);

	Selection = QueryResult.Select();
	If Selection.Next() Then
		Result = Selection.Detected;
	Else
		Result = Undefined;
	EndIf;
	Return Result;
EndFunction

// Prepares the data required to perform a data integrity check.
//
// Parameters:
//     Validation - CatalogRef.AccountingCheckRules - a check, whose parameters
//                need to be prepared.
//     CheckExecutionParameters - Structure
//                                 - Array - Custom additional check parameters that define the check procedure and object.
//                                    
//                                 - Structure - A single check parameter. For the properties, See AccountingAudit.CheckExecutionParameters.
//                                 - Array - several check parameters (array elements of the Structure type, as
//                                            described above).
//
// Returns:
//   See AccountingAudit.IssueDetails.
//
Function PrepareCheckParameters(Val Validation, Val CheckExecutionParameters) Export
	
	CheckParameters = Common.ObjectAttributesValues(Validation, "CheckStartDate, Id,
		|ScheduledJobID, IssuesLimit, Description, IssueSeverity, RunMethod,
		|AccountingChecksContext, AccountingCheckContextClarification");
	
	If Not CheckParameters.Property("CheckWasStopped") Then
		CheckParameters.Insert("CheckWasStopped", False);
	EndIf;
	If Not CheckParameters.Property("ManualStart1") Then
		CheckParameters.Insert("ManualStart1", True);
	EndIf;
	
	AccountingChecks = AccountingAuditInternalCached.AccountingChecks().Checks;
	AllCheckProperties  = AccountingChecks.Find(CheckParameters.Id, "Id");
	
	CheckParameters.Insert("Validation",            Validation);
	CheckParameters.Insert("GlobalSettings", GlobalSettings());
	CheckParameters.Insert("CheckIteration",    1);
	If AllCheckProperties <> Undefined Then
		CheckParameters.Insert("SupportsRandomCheck", AllCheckProperties.SupportsRandomCheck);
	EndIf;
	
	If CheckExecutionParameters = Undefined Then
		ChecksGroup = Common.ObjectAttributeValue(Validation, "Parent");
		If ChecksGroup <> Undefined And Not ChecksGroup.IsEmpty() Then
			CheckID = Common.ObjectAttributeValue(ChecksGroup, "Id");
		Else
			CheckID = CheckParameters.Id;
		EndIf;
		CheckExecutionParameters = New Array;
		CheckExecutionParameters.Add(CheckExecutionParameters(CheckID));
	EndIf;
	CheckParameters.Insert("CheckExecutionParameters", CheckExecutionParameters);
	
	Return CheckParameters;
	
EndFunction

// Updates auxiliary data that partially depends on the configuration.
//
Procedure UpdateAuxiliaryRegisterDataByConfigurationChanges(Parameters = Undefined) Export
	
	BeginTransaction();
	Try
		Block = New DataLock;
		Block.Add("Catalog.AccountingCheckRules");
		Block.Lock();
		
		UpdateCatalogAuxiliaryDataByConfigurationChanges();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

// See AccountingAudit.SummaryInformationOnChecksKinds.
Function SummaryInformationOnChecksKinds(ChecksKind, SearchByExactMap = True, ConsiderPersonResponsible = False) Export
	
	SummaryInformation = New Structure;
	SummaryInformation.Insert("Count", 0);
	SummaryInformation.Insert("HasErrors", False);
	
	If Not AccessRight("Read", Metadata.InformationRegisters.AccountingCheckResults) Then
		Return SummaryInformation;
	EndIf;
	
	ChecksKinds = New Array;
	
	If TypeOf(ChecksKind) = Type("CatalogRef.ChecksKinds") Then
		ChecksKinds.Add(ChecksKind);
	ElsIf TypeOf(ChecksKind) = Type("String") Then
		CheckExecutionParameters = CheckExecutionParameters(ChecksKind);
		ChecksKinds = ChecksKinds(CheckExecutionParameters, SearchByExactMap);
	ElsIf ChecksKind <> Undefined Then
		CheckExecutionParameters = CheckExecutionParametersFromArray(ChecksKind);
		ChecksKinds = ChecksKinds(CheckExecutionParameters, SearchByExactMap);
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	COUNT(*) AS Count,
		|	ISNULL(MAX(CASE
		|				WHEN AccountingCheckResults.IssueSeverity = VALUE(Enum.AccountingIssueSeverity.Error)
		|					THEN TRUE
		|				ELSE FALSE
		|			END), FALSE) AS HasErrors
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.CheckRule.DeletionMark = FALSE
		|	AND NOT AccountingCheckResults.IgnoreIssue";
	If ChecksKind <> Undefined Then
		Query.Text = Query.Text + " AND AccountingCheckResults.CheckKind IN (&ChecksKinds)";
		Query.SetParameter("ChecksKinds", ChecksKinds);
	EndIf;
	If ConsiderPersonResponsible Then
		Query.Text = Query.Text + " AND AccountingCheckResults.EmployeeResponsible IN (&EmployeeResponsible)";
		EmployeeResponsible = New Array;
		EmployeeResponsible.Add(Catalogs.Users.EmptyRef());
		EmployeeResponsible.Add(Users.CurrentUser());
		Query.SetParameter("EmployeeResponsible", EmployeeResponsible);
	EndIf;
	Result = Query.Execute().Select();
	Result.Next();
	
	FillPropertyValues(SummaryInformation, Result);
	Return SummaryInformation;
	
EndFunction

// See AccountingAudit.DetailedInformationOnChecksKinds.
Function DetailedInformationOnChecksKinds(ChecksKind, SearchByExactMap = True) Export
	
	DetailedInformation        = New ValueTable;
	DetailedInformationColumns = DetailedInformation.Columns;
	DetailedInformationColumns.Add("ObjectWithIssue",         Common.AllRefsTypeDetails());
	DetailedInformationColumns.Add("IssueSeverity",         New TypeDescription("EnumRef.AccountingIssueSeverity"));
	DetailedInformationColumns.Add("CheckRule",          New TypeDescription("CatalogRef.AccountingCheckRules"));
	DetailedInformationColumns.Add("CheckKind",              New TypeDescription("CatalogRef.ChecksKinds"));
	DetailedInformationColumns.Add("IssueSummary",        New TypeDescription("String"));
	DetailedInformationColumns.Add("EmployeeResponsible",            New TypeDescription("CatalogRef.Users"));
	DetailedInformationColumns.Add("Detected",                 New TypeDescription("Date"));
	DetailedInformationColumns.Add("AdditionalInformation", New TypeDescription("ValueStorage"));
	
	ChecksKinds = New Array;
	
	If TypeOf(ChecksKind) = Type("CatalogRef.ChecksKinds") Then
		ChecksKinds.Add(ChecksKind);
	ElsIf TypeOf(ChecksKind) = Type("String") Then
		CheckExecutionParameters = CheckExecutionParameters(ChecksKind);
		ChecksKinds = ChecksKinds(CheckExecutionParameters, SearchByExactMap);
	Else
		CheckExecutionParameters = CheckExecutionParametersFromArray(ChecksKind);
		ChecksKinds = ChecksKinds(CheckExecutionParameters, SearchByExactMap);
	EndIf;
	
	If ChecksKinds.Count() = 0 Then
		Return DetailedInformation;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
	|	AccountingCheckResults.CheckRule AS CheckRule,
	|	AccountingCheckResults.IssueSeverity AS IssueSeverity,
	|	AccountingCheckResults.CheckKind AS CheckKind,
	|	AccountingCheckResults.IssueSummary AS IssueSummary,
	|	AccountingCheckResults.EmployeeResponsible AS EmployeeResponsible,
	|	AccountingCheckResults.Detected AS Detected,
	|	AccountingCheckResults.AdditionalInformation AS AdditionalInformation
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	AccountingCheckResults.CheckRule.DeletionMark = FALSE
	|	AND NOT AccountingCheckResults.IgnoreIssue
	|	AND AccountingCheckResults.CheckKind IN(&ChecksKinds)");
	
	Query.SetParameter("ChecksKinds", ChecksKinds);
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		DetailedInformation = Result.Unload();
	EndIf;
	
	Return DetailedInformation;
	
EndFunction

// See AccountingAudit.ChecksKinds.
Function ChecksKinds(ChecksKind, SearchByExactMap = True) Export
	
	If TypeOf(ChecksKind) = Type("CatalogRef.ChecksKinds") Then
		Result = New Array;
		Result.Add(ChecksKind);
		Return Result;
	EndIf;
	
	If TypeOf(ChecksKind) = Type("String") Then
		CheckExecutionParameters = CheckExecutionParameters(ChecksKind);
	ElsIf TypeOf(ChecksKind) = Type("Array") Then
		CheckExecutionParameters = CheckExecutionParametersFromArray(ChecksKind);
	Else
		CheckExecutionParameters = ChecksKind;
	EndIf;
	
	If TypeOf(CheckExecutionParameters) = Type("Structure") Then
		Return CheckKindRegularSearch(CheckExecutionParameters, SearchByExactMap);
		
	ElsIf TypeOf(CheckExecutionParameters) = Type("Array") Then
		
		If CheckExecutionParameters.Count() > PropertiesCount() Then
			Return CheckKindExtendedSearch(CheckExecutionParameters, CheckExecutionParameters.Count());
		Else
			Return CheckKindRegularSearch(CheckExecutionParameters, SearchByExactMap);
		EndIf;
		
	EndIf;
	
	Return New Array;
	
EndFunction

// See AccountingAudit.CheckKind.
Function CheckKind(Val CheckExecutionParameters, Val SearchOnly = False) Export
	
	If TypeOf(CheckExecutionParameters) = Type("String") Then
		CheckExecutionParameters = CheckExecutionParameters(CheckExecutionParameters);
	EndIf;
	
	BeginTransaction();
	Try
		Block = ChecksKindsLock(CheckExecutionParameters);
		Block.Lock();
		
		If CheckExecutionParameters.Count() - 1 > PropertiesCount() Then
			CheckKindArray = CheckKindExtendedSearch(CheckExecutionParameters, PropertiesCount());
		Else
			CheckKindArray = CheckKindRegularSearch(CheckExecutionParameters);
		EndIf;
		
		If CheckKindArray.Count() = 0 Then
			If SearchOnly Then
				CheckKind = Catalogs.ChecksKinds.EmptyRef();
			Else
				CheckKind = NewCheckKind(CheckExecutionParameters);
			EndIf;
		Else
			CheckKind = CheckKindArray.Get(0);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return CheckKind;
	
EndFunction

// Searches for a check type based on the passed parameters. 
//
// Parameters:
//   CheckExecutionParameters - See AccountingAudit.CheckExecutionParameters.
//   PropertiesCount           - Number - Number of properties to search by.
//
// Returns: 
//   CatalogRef.ChecksKinds - a catalog item, or an empty reference if the search returned no results.
//
Function CheckKindExtendedSearch(CheckExecutionParameters, PropertiesCount)
	
	Query = New Query(
	"SELECT
	|	ChecksKinds.Ref AS CheckKind
	|INTO TT_ChecksKinds
	|FROM
	|	Catalog.ChecksKinds AS ChecksKinds
	|WHERE
	|	&Condition
	|
	|GROUP BY
	|	ChecksKinds.Ref
	|
	|HAVING
	|	COUNT(ChecksKinds.ObjectProperties.Ref) = &ThresholdValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChecksKindsObjectProperties.Ref AS CheckKind,
	|	ChecksKindsObjectProperties.PropertyValue AS PropertyValue,
	|	ChecksKindsObjectProperties.PropertyName AS PropertyName
	|FROM
	|	TT_ChecksKinds AS TT_ChecksKinds
	|		INNER JOIN Catalog.ChecksKinds.ObjectProperties AS ChecksKindsObjectProperties
	|		ON TT_ChecksKinds.CheckKind = ChecksKindsObjectProperties.Ref
	|
	|ORDER BY
	|	CheckKind");
	
	ConditionsText           = " True ";
	ParametersCount   = CheckExecutionParameters.Count() - 1;
	Query.SetParameter("ThresholdValue", ParametersCount - PropertiesCount);
	
	For IndexOf = 1 To PropertiesCount Do
		
		Property  = "Property" + Format(IndexOf, "NG=0");
		Value  = CheckExecutionParameters[Property];
		
		ConditionsText = ConditionsText + " And " + Property + " = &" + Property;
		Query.SetParameter(Property, Value);
		
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "&Condition", ConditionsText);
	Result = Query.Execute().Unload();
	
	TransposedTable = New ValueTable;
	TableColumns1           = TransposedTable.Columns;
	TableColumns1.Add("CheckKind", New TypeDescription("CatalogRef.ChecksKinds"));
	
	TheStructureOfTheSearch = New Structure;
	SearchIndex    = "";
	
	For ThresholdIndex = PropertiesCount + 1 To ParametersCount Do
		
		ColumnName   = "Property" + Format(ThresholdIndex, "NG=0");
		SearchIndex = SearchIndex + ?(ValueIsFilled(SearchIndex), ", ", "") + ColumnName;
		TableColumns1.Add(ColumnName);
		
		TheStructureOfTheSearch.Insert(ColumnName, CheckExecutionParameters[ColumnName]);
		
	EndDo;
	
	CurrentCheckKind = Undefined;
	For Each ResultString1 In Result Do
		
		If CurrentCheckKind <> ResultString1.CheckKind Then
			
			CurrentCheckKind = ResultString1.CheckKind;
			NewRow = TransposedTable.Add();
			NewRow.CheckKind = CurrentCheckKind;
			
		EndIf;
		
		NewRow[ResultString1.PropertyName] = ResultString1.PropertyValue;
		
	EndDo;
	
	If TransposedTable.Count() > 1000 Then
		TransposedTable.Indexes.Add(SearchIndex);
	EndIf;
	
	FoundRows     = TransposedTable.FindRows(TheStructureOfTheSearch);
	ChecksKindsArray = New Array;
	For Each FoundRow In FoundRows Do
		ChecksKindsArray.Add(FoundRow.CheckKind);
	EndDo;
	
	Return ChecksKindsArray;
	
EndFunction

// In order to avoid conflicts when called from different scheduled jobs, locks 
// the CheckKinds catalog by the passed check execution parameters.
//
// Parameters:
//   CheckExecutionParameters - See AccountingAudit.CheckExecutionParameters.
//
// Returns:
//   DataLock  - a lock object of the ChecksKinds catalog.
//
Function ChecksKindsLock(CheckExecutionParameters)
	
	DataLock = New DataLock;
	DataLockItem = DataLock.Add("Catalog.ChecksKinds");
	
	If CheckExecutionParameters.Count() - 1 > PropertiesCount() Then
		IndexOf = 1;
		For Each SearchParameter In CheckExecutionParameters Do
			DataLockItem.SetValue("Property" + Format(IndexOf, "NG=0"), SearchParameter.Value);
			IndexOf = IndexOf + 1;
		EndDo;
	EndIf;
	
	Return DataLock;
	
EndFunction

// Searches for a check type based on the passed parameters. 
//
// Parameters:
//   CheckExecutionParameters - See AccountingAudit.CheckExecutionParameters.
//   SearchByExactMap - Boolean - If True, the search is conducted
//                                by the passed properties for equality, other properties must be equal
//                                Undefined (tabular section of additional properties has to be blank).
//                                If False, other property values can be arbitrary, the main thing is
//                                that the corresponding properties need to be equal to the structure properties. Default value is True.
//
// Returns: 
//   CatalogRef.ChecksKinds - a catalog item, or an empty reference if the search returned no results.
//
Function CheckKindRegularSearch(CheckExecutionParameters, SearchByExactMap = True)
	
	Query = New Query(
	"SELECT
	|	ChecksKinds.Ref AS CheckKind
	|FROM
	|	Catalog.ChecksKinds AS ChecksKinds
	|WHERE
	|	&Condition
	|
	|GROUP BY
	|	ChecksKinds.Ref
	|
	|HAVING
	|	COUNT(ChecksKinds.ObjectProperties.Ref) = 0");
	
	ConditionsText         = " True ";
	ParametersCount = CheckExecutionParameters.Count() - 1;
	PropertiesCount    = PropertiesCount();
	
	For IndexOf = 1 To PropertiesCount Do
		
		Property = "Property" + Format(IndexOf, "NG=0");
		If IndexOf > ParametersCount Then
			If SearchByExactMap Then
				ConditionsText = ConditionsText + " And " + Property + " = Undefined";
			EndIf;
		Else
			Value     = CheckExecutionParameters[Property];
			
			ConditionsText = ConditionsText + " And " + Property + " = &" + Property;
			Query.SetParameter(Property, Value);
		EndIf;
		
	EndDo;
	
	Query.Text = StrReplace(Query.Text, "&Condition", ConditionsText);
	Result = Query.Execute().Unload();
	
	Return Result.UnloadColumn("CheckKind");
	
EndFunction

// Creates a ChecksKinds catalog item based on the specified parameters.
//
// Parameters:
//   CheckExecutionParameters - See AccountingAudit.CheckExecutionParameters.
//
// Returns: 
//    CatalogRef.ChecksKinds - a created catalog item.
//
Function NewCheckKind(CheckExecutionParameters)
	
	AccountingChecks = AccountingAuditInternalCached.AccountingChecks();
	ChecksGroups = AccountingChecks.ChecksGroups;
	ChecksGroup = ChecksGroups.Find(CheckExecutionParameters.Description, "Id");
	
	NewCheckKind = Catalogs.ChecksKinds.CreateItem();
	If ChecksGroup = Undefined Then
		NewCheckKind.Description = CheckExecutionParameters.Description;
	Else
		NewCheckKind.Description = ChecksGroup.Description;
	EndIf;
	PropertiesCount    = PropertiesCount();
	ParametersCount = CheckExecutionParameters.Count() - 1;
	
	If PropertiesCount > ParametersCount Then
		For IndexOf = 1 To ParametersCount Do
			PropertyName = "Property" + Format(IndexOf, "NG=0");
			NewCheckKind[PropertyName] = CheckExecutionParameters[PropertyName];
		EndDo;
	Else
		For IndexOf = 1 To ParametersCount Do
			PropertyName = "Property" + Format(IndexOf, "NG=0");
			If IndexOf <= PropertiesCount Then
				NewCheckKind[PropertyName] = CheckExecutionParameters[PropertyName];
			Else
				FillPropertyValues(NewCheckKind.ObjectProperties.Add(),
					New Structure("PropertyName, PropertyValue", PropertyName, CheckExecutionParameters[PropertyName]));
			EndIf;
		EndDo;
	EndIf;
	
	NewCheckKind.Write();
	
	Return NewCheckKind.Ref;
	
EndFunction

// The number of properties in the ChecksKinds catalog header.
// 
// Returns: 
//   Number - value 5.
//
Function PropertiesCount()
	
	Return 5;
	
EndFunction

// See AccountingAuditOverridable.OnDefineSettings.
Function GlobalSettings() Export
	
	Settings = New Structure;
	Settings.Insert("IssuesIndicatorPicture",    PictureLib.Warning);
	Settings.Insert("IssuesIndicatorNote",   Undefined);
	Settings.Insert("IssuesIndicatorHyperlink", Undefined);
	
	AccountingAuditOverridable.OnDefineSettings(Settings);
	
	Return Settings;
	
EndFunction

// Returns an array of objects with issues. Maximum reduced to increase performance.
//
//  Parameters:
//    RowsKeys - Array - an array that contains all keys of the dynamic list rows.
//
// Returns:
//   Array of AnyRef - an array of problem objects.
//
Function ObjectsWithIssues(RowsKeys, IncludingImportance = False) Export
	
	CurrentUserIsFullUser = Users.IsFullUser();
	
	Query = New Query(
	"SELECT DISTINCT
	|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
	|	MIN(AccountingCheckResults.IssueSeverity.Order) AS IssueOrder
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	AccountingCheckResults.ObjectWithIssue IN(&ListOfObjects)
	|	AND NOT AccountingCheckResults.IgnoreIssue
	|
	|GROUP BY
	|	AccountingCheckResults.ObjectWithIssue");
	Query.SetParameter("ListOfObjects", RowsKeys);
	
	If Not CurrentUserIsFullUser Then
		SetPrivilegedMode(True);
	EndIf;
	
	If IncludingImportance Then
		ObjectsWithIssues = Query.Execute().Unload();
	Else
		ObjectsWithIssues = Query.Execute().Unload().UnloadColumn("ObjectWithIssue");
	EndIf;
	
	If Not CurrentUserIsFullUser Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return ObjectsWithIssues;
	
EndFunction

// See AccountingAudit.IssueDetails.
Function IssueDetails(ObjectWithIssue, CheckParameters) Export
	
	Result = New Structure;
	Result.Insert("ObjectWithIssue",         ObjectWithIssue);
	Result.Insert("CheckRule",          CheckParameters.Validation);
	Result.Insert("IssueSeverity",         CheckParameters.IssueSeverity);
	Result.Insert("IssueSummary",        "");
	Result.Insert("UniqueKey",         New UUID);
	Result.Insert("Detected",                 CurrentSessionDate());
	Result.Insert("AdditionalInformation", New ValueStorage(Undefined));
	Result.Insert("EmployeeResponsible",            Undefined);
	Result.Insert("CheckKind",              ?(CheckParameters.CheckExecutionParameters.Count() = 1,
		CheckKind(CheckParameters.CheckExecutionParameters[0]), Undefined));
	
	Return Result;
	
EndFunction

// See AccountingAudit.WriteIssue.
Procedure WriteIssue(CheckError, CheckParameters = Undefined) Export
	
	If CheckParameters <> Undefined And IsLastCheckIteration(CheckParameters) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CheckError.CheckKind) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi ghi lại vấn đề về kiểm tra ""%1"" chưa chỉ ra dạng kiểm tra.';
				|ru = 'При записи проблемы по проверке ""%1"" не указан вид проверки.';
				|en = 'The check type is missing when saving the issue for the ""%1"" check.'; fa = 'The check type is missing when saving the issue for the ""%1"" check.';
				|it = 'Durante il salvataggio del problema di verifica ""%1"" non è indicato il tipo di verifica.';
				|pl = 'Przy zapisie problemy dot. sprawdzenia ""%1"" nie określono rodzaju sprawdzenia.';
				|tr = '""%1"" kontrolündeki hata kaydedilirken kontrolün türü belirtilmedi.'"), 
				CheckError.CheckRule);
	EndIf;
	
	ObjectsToExclude = AccountingAuditInternalCached.ObjectsToExcludeFromCheck();
	
	ObjectWithIssue = CheckError.ObjectWithIssue;
	MetadataObject = ObjectWithIssue.Metadata();
	
	If ObjectsToExclude.Find(MetadataObject.FullName()) <> Undefined Then
		Return;
	EndIf;
	
	AttributesCollection = MetadataObject.Attributes;
	
	AccountingAuditOverridable.BeforeWriteIssue(CheckError, ObjectWithIssue, AttributesCollection);
	
	CheckError.Insert("Checksum", IssueChecksum(CheckError));
	If ThisIssueIgnored(CheckError.Checksum) Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.AccountingCheckResults.CreateRecordSet();
	Filter = RecordSet.Filter;
	Filter.ObjectWithIssue.Set(ObjectWithIssue);
	Filter.CheckRule.Set(CheckError.CheckRule);
	Filter.CheckKind.Set(CheckError.CheckKind);
	Filter.UniqueKey.Set(CheckError.UniqueKey);
	
	NewRecord = RecordSet.Add();
	FillPropertyValues(NewRecord, CheckError);
	
	SetPrivilegedMode(True);
	RecordSet.Write();
	SetPrivilegedMode(False);
	
EndProcedure

// See AccountingAudit.IgnoreIssue.
Procedure IgnoreIssue(IssueDetails, Value) Export
	
	BeginTransaction();
	Try
		DataLock        = New DataLock;
		DataLockItem = DataLock.Add("InformationRegister.AccountingCheckResults");
		DataLockItem.SetValue("ObjectWithIssue", IssueDetails.ObjectWithIssue);
		DataLockItem.SetValue("CheckRule", IssueDetails.CheckRule);
		DataLockItem.SetValue("CheckKind", IssueDetails.CheckKind);
		DataLock.Lock();
		
		Checksum = IssueChecksum(IssueDetails);
		
		Query = New Query(
		"SELECT
		|	AccountingCheckResults.IgnoreIssue AS IgnoreIssue,
		|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
		|	AccountingCheckResults.CheckRule AS CheckRule,
		|	AccountingCheckResults.CheckKind AS CheckKind,
		|	AccountingCheckResults.AdditionalInformation AS AdditionalInformation
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.Checksum = &Checksum");
		
		Query.SetParameter("Checksum", Checksum);
		Result = Query.Execute();
		If Result.IsEmpty() Then
			RollbackTransaction();
			Return;
		EndIf;
		
		PassedAddInfoChecksum = "";
		If IssueDetails.Property("AdditionalInformation") Then
			PassedAddInfoChecksum = Common.CheckSumString(IssueDetails.AdditionalInformation);
		EndIf;
		
		Selection = Result.Select();
		While Selection.Next() Do
			
			If ValueIsFilled(PassedAddInfoChecksum) Then
				
				FoundAddInfoChecksum  = Common.CheckSumString(Selection.AdditionalInformation);
				If FoundAddInfoChecksum <> PassedAddInfoChecksum Then
					Continue;
				EndIf;
				
			EndIf;
			
			If Selection.IgnoreIssue <> Value Then
				
				RecordSet = InformationRegisters.AccountingCheckResults.CreateRecordSet();
				RecordSet.Filter.ObjectWithIssue.Set(Selection.ObjectWithIssue);
				RecordSet.Filter.CheckRule.Set(Selection.CheckRule);
				RecordSet.Filter.CheckKind.Set(Selection.CheckKind);
				If IssueDetails.Property("UniqueKey") Then
					RecordSet.Filter.UniqueKey.Set(IssueDetails.UniqueKey);
				EndIf;
				RecordSet.Read();
				
				Record = RecordSet.Get(0);
				Record.IgnoreIssue = Value;
				RecordSet.Write();
				
			EndIf;
			
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns check parameters for the passed scheduled job ID.
//
// Parameters:
//  ScheduledJobID - String - a field to connect to the current background job.
//
// Returns:
//   Structure - with properties, Undefined:
//       * Id - String - Check string ID.
//
Function CheckByScheduledJobIDParameters(ScheduledJobID)
	
	Query = New Query(
	"SELECT TOP 1
	|	AccountingCheckRules.Id AS Id
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|WHERE
	|	AccountingCheckRules.ScheduledJobID = &ScheduledJobID
	|	AND AccountingCheckRules.Use");
	
	Query.SetParameter("ScheduledJobID", String(ScheduledJobID));
	Result = Query.Execute().Select();
	
	If Not Result.Next() Then
		Return Undefined;
	Else
		
		ReturnStructure = New Structure;
		ReturnStructure.Insert("Id", Result.Id);
		
		Return ReturnStructure;
		
	EndIf;
	
EndFunction

// Returns text and severity of the data integrity issue.
//
Function ObjectIssueInfo(ObjectReference) Export
	Query = New Query;
	Query.SetParameter("ObjectWithIssue", ObjectReference);
	Query.Text =
		"SELECT ALLOWED
		|	AccountingCheckResults.IssueSummary AS IssueText,
		|	AccountingCheckResults.IssueSeverity AS IssueSeverity
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.ObjectWithIssue = &ObjectWithIssue";
	Result = Query.Execute().Unload();
	
	InformationRecords = New Structure;
	InformationRecords.Insert("IssueText", "");
	InformationRecords.Insert("IssueSeverity", Undefined);
	
	If Result.Count() = 0 Then
		Return InformationRecords;
	EndIf;
	FillPropertyValues(InformationRecords, Result[0]);
	
	Return InformationRecords;
EndFunction

#Region ChecksCatalogUpdate

Function HasChangesOfAccountingChecksParameters() Export
	
	SetPrivilegedMode(True);
	LastChanges = StandardSubsystemsServer.ApplicationParameterChanges(
		"StandardSubsystems.AccountingAudit.SystemChecks");
	Return LastChanges = Undefined Or LastChanges.Count() > 0;
	
EndFunction

Procedure AddChecksGroups(ChecksGroups)
	
	ChecksInfoRecords = DataIntegrityChecksInfoRecords(ChecksGroups);
	
	For Each ChecksGroup In ChecksInfoRecords Do
		
		ChecksGroupByID = ChecksGroup.Validation;
		
		If Not ValueIsFilled(ChecksGroupByID) Then
			ChecksGroupObject = Catalogs.AccountingCheckRules.CreateFolder();
		Else
			
			If ChecksGroup.AccountingCheckIsChanged Then
				Continue;
			EndIf;
			
			ChecksGroupObject = ChecksGroupByID.GetObject();
			If ChecksGroupByID.DeletionMark Then
				ChecksGroupObject.SetDeletionMark(False);
			EndIf;
			
		EndIf;
		
		FillPropertyValues(ChecksGroupObject, ChecksGroup);
		
		CheckGroupParent        = ChecksGroup.CheckParent1;
		ChecksGroupObject.Parent = CheckGroupParent;
		
		If ValueIsFilled(CheckGroupParent) Then
			ChecksGroupObject.AccountingChecksContext = ChecksGroup.DataIntegrityCheckParentContext;
		Else
			ChecksGroupObject.AccountingChecksContext = ChecksGroup.AccountingChecksContext;
		EndIf;
		
		// ACC:1327-off A lock is set upper in the stack.
		InfobaseUpdate.WriteData(ChecksGroupObject);
		// ACC:1327-on
	EndDo;
	
	Query = New Query(
	"SELECT
	|	ChecksGroups.Id AS Id,
	|	ChecksGroups.Description AS Description
	|INTO TT_ChecksGroups
	|FROM
	|	&ChecksGroups AS ChecksGroups
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountingCheckRules.Ref AS Ref
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|		LEFT JOIN TT_ChecksGroups AS TT_ChecksGroups
	|		ON AccountingCheckRules.Id = TT_ChecksGroups.Id
	|WHERE
	|	TT_ChecksGroups.Description IS NULL
	|	AND AccountingCheckRules.IsFolder
	|	AND NOT AccountingCheckRules.Predefined
	|	AND NOT AccountingCheckRules.AccountingCheckIsChanged");
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("ChecksGroups", ChecksGroups);
	
	// ACC:1327-off A lock is set upper in the stack.
	Result = Query.Execute().Select();
	// ACC:1327-on
	While Result.Next() Do
		ChecksGroupObject = Result.Ref.GetObject();
		ChecksGroupObject.SetDeletionMark(True);
	EndDo;
	
	Query.TempTablesManager.Close();
	
EndProcedure

Procedure AddChecks(Checks)
	
	ChecksInfoRecords = DataIntegrityChecksInfoRecords(Checks);
	
	For Each CheckInfoRecords In ChecksInfoRecords Do
		
		If Not ValueIsFilled(CheckInfoRecords.Validation) Then
			
			CheckObject1 = Catalogs.AccountingCheckRules.CreateItem();
			CheckObject1.RunMethod = Enums.CheckMethod.ByCommonSchedule;
			CheckObject1.IssueSeverity = Enums.AccountingIssueSeverity.Error;
			
		Else
			
			If CheckInfoRecords.AccountingCheckIsChanged Then
				Continue;
			EndIf;
			
			CheckObject1 = CheckInfoRecords.Validation.GetObject();
			If CheckObject1.DeletionMark Then
				CheckObject1.SetDeletionMark(False);
			EndIf;
			
		EndIf;
		
		FillPropertyValues(CheckObject1, CheckInfoRecords);
		
		CheckParent1        = CheckInfoRecords.CheckParent1;
		CheckObject1.Parent = CheckParent1;
		
		If ValueIsFilled(CheckParent1) Then
			CheckObject1.AccountingChecksContext = CheckInfoRecords.DataIntegrityCheckParentContext;
		Else
			CheckObject1.AccountingChecksContext = CheckInfoRecords.AccountingChecksContext;
		EndIf;
		
		CheckObject1.Use = Not CheckInfoRecords.TurnedOff;
		
		If ValueIsFilled(CheckInfoRecords.IssuesLimit) Then
			CheckObject1.IssuesLimit = CheckInfoRecords.IssuesLimit;
		Else
			CheckObject1.IssuesLimit = 1000;
		EndIf;
		
		If ValueIsFilled(CheckInfoRecords.CheckStartDate) Then
			CheckObject1.CheckStartDate = CheckInfoRecords.CheckStartDate;
		EndIf;
		
		// ACC:1327-off A lock is set upper in the stack.
		InfobaseUpdate.WriteData(CheckObject1);
		// ACC:1327-on
	EndDo;
	
	Query = New Query(
	"SELECT
	|	Checks.Id AS Id,
	|	Checks.Description AS Description
	|INTO TT_Checks
	|FROM
	|	&Checks AS Checks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountingCheckRules.Ref AS Ref
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|		LEFT JOIN TT_Checks AS TT_Checks
	|		ON AccountingCheckRules.Id = TT_Checks.Id
	|WHERE
	|	TT_Checks.Description IS NULL
	|	AND NOT AccountingCheckRules.IsFolder
	|	AND NOT AccountingCheckRules.Predefined
	|	AND NOT AccountingCheckRules.AccountingCheckIsChanged");
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Checks", Checks);
	
	// ACC:1327-off A lock is set upper in the stack.
	Result = Query.Execute().Select();
	// ACC:1327-on
	While Result.Next() Do
		CheckObject1 = Result.Ref.GetObject();
		CheckObject1.SetDeletionMark(True);
	EndDo;
	
	Query.TempTablesManager.Close();
	
EndProcedure

Procedure UpdateCatalogAuxiliaryDataByConfigurationChanges()
	
	SetPrivilegedMode(True);
	AccountingChecks = AccountingAuditInternalCached.AccountingChecks();
	SpecifiedItemsUniquenessCheck(AccountingChecks.ChecksGroups, AccountingChecks.Checks);
	AddChecksGroups(AccountingChecks.ChecksGroups);
	AddChecks(AccountingChecks.Checks);
	
EndProcedure

Procedure SpecifiedItemsUniquenessCheck(ChecksGroups, Checks)
	
	Query = New Query(
	"SELECT
	|	Description AS Description,
	|	Id AS Id
	|INTO TT_ChecksGroups
	|FROM
	|	&ChecksGroups AS ChecksGroups
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Description AS Description,
	|	Id AS Id
	|INTO TT_Checks
	|FROM
	|	&Checks AS Checks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_ChecksGroups.Description AS Description,
	|	TT_ChecksGroups.Id AS Id
	|INTO TT_CommonTable
	|FROM
	|	TT_ChecksGroups AS TT_ChecksGroups
	|
	|UNION ALL
	|
	|SELECT
	|	TT_Checks.Description,
	|	TT_Checks.Id
	|FROM
	|	TT_Checks AS TT_Checks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_CommonTable.Id AS Id
	|INTO TTGroupByID
	|FROM
	|	TT_CommonTable AS TT_CommonTable
	|
	|GROUP BY
	|	TT_CommonTable.Id
	|
	|HAVING
	|	COUNT(TT_CommonTable.Id) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_CommonTable.Description AS Description,
	|	TT_CommonTable.Id AS Id
	|FROM
	|	TTGroupByID AS TTGroupByID
	|		INNER JOIN TT_CommonTable AS TT_CommonTable
	|		ON TTGroupByID.Id = TT_CommonTable.Id
	|
	|ORDER BY
	|	Id
	|TOTALS BY
	|	Id");
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("ChecksGroups", ChecksGroups);
	Query.SetParameter("Checks",       Checks);
	
	ExceptionText = "";
	Result       = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While Result.Next() Do
		
		ExceptionText = ExceptionText + ?(ValueIsFilled(ExceptionText), Chars.LF, "")
			+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tên trùng lặp: ""%1""';
																			|ru = 'Дублирующийся идентификатор: ""%1""';
																			|en = 'Duplicate ID: ""%1""'; fa = 'Duplicate ID: ""%1""';
																			|it = 'ID duplicato: ""%1""';
																			|pl = 'Duplikat identyfikatora: ""%1""';
																			|tr = 'Tekrarlanan kimlik: ""%1""'"), Result.Id);
			
		DetailedResult = Result.Select();
		While DetailedResult.Next() Do
			ExceptionText = ExceptionText + Chars.LF + "- " + DetailedResult.Description;
		EndDo;
		
	EndDo;
	
	Query.TempTablesManager.Close();
	
	If ValueIsFilled(ExceptionText) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong thủ tục %1, trùng tên định danh ở những lần kiểm tra tiếp theo:
		|%2';
		|ru = 'В процедуре %1 у следующих проверок совпадают идентификаторы:
		|%2';
		|en = 'In %1 procedure, the following checks have identical IDs:
		|%2'; fa = 'In %1 procedure, the following checks have identical IDs:
		|%2';
		|it = 'Nella procedura %1 delle ultime verifiche corrispondono gli ID:
		|%2';
		|pl = 'W procedurze %1 następujące sprawdzenia mają ten sam identyfikator:
		|%2';
		|tr = '%1 prosedüründe aşağıdaki kontrollerin kimlikleri aynıdır: 
		|%2'"), "AccountingAuditOverridable.OnDefineChecks", ExceptionText);
	EndIf;
	
EndProcedure

Function ChecksChecksum()
	
	ChecksData = New Map;
	
	AccountingChecks = AccountingAuditInternalCached.AccountingChecks();
	ChecksContent = New Array;
	
	For Each AccountingChecksItem In AccountingChecks Do
		
		ChecksItemValue = AccountingChecksItem.Value; // ValueTable
		ChecksItemColumns  = ChecksItemValue.Columns;
		
		For Each ChecksItemRow In ChecksItemValue Do
			
			CheckProperties = New Structure;
			For Each ChecksItemColumn In ChecksItemColumns Do
				CheckProperties.Insert(ChecksItemColumn.Name, ChecksItemRow[ChecksItemColumn.Name]);
			EndDo;
			If CheckProperties.Count() > 0 Then
				ChecksContent.Add(CheckProperties);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ChecksData.Insert(Common.CheckSumString(New FixedArray(ChecksContent)));
	Return New FixedMap(ChecksData);
	
EndFunction

#EndRegion

#Region ChecksToSupply

// Checks reference integrity.
//
Procedure CheckReferenceIntegrity(Validation, CheckParameters) Export
	
	CheckedRefs = New Map;
	
	CheckExecutionParameters = ReadParameters(CheckParameters.CheckExecutionParameters);
	If CheckExecutionParameters <> Undefined Then
		If CheckExecutionParameters.ValidationArea = "Registers" Then
			FindDeadRefsInRegisters(CheckExecutionParameters.MetadataObject, CheckParameters, CheckedRefs);
		Else
			FindDeadRefs(CheckExecutionParameters.MetadataObject, CheckParameters, CheckedRefs);
		EndIf;
		
		Return;
	EndIf;
	
	If CheckParameters.Property("ObjectsToCheck") And CheckParameters.ObjectsToCheck <> Undefined Then
		If TypeOf(CheckParameters.ObjectsToCheck) = Type("Array") Then
			MetadataObject = CheckParameters.ObjectsToCheck[0].Metadata();
		Else
			MetadataObject = CheckParameters.ObjectsToCheck.Metadata();
		EndIf;
		FindDeadRefs(MetadataObject, CheckParameters, CheckedRefs);
		Return;
	EndIf;
	
	ObjectsToExcludeFromCheck = AccountingAuditInternalCached.ObjectsToExcludeFromCheck();
	
	For Each MetadataKind In MetadataObjectsRefKinds() Do
		For Each MetadataObject In MetadataKind Do
			FullName = MetadataObject.FullName();
			If IsSharedMetadataObject(FullName) Then
				Continue;
			EndIf;
			If ObjectsToExcludeFromCheck.Find(FullName) <> Undefined Then
				Continue;
			EndIf;
			FindDeadRefs(MetadataObject, CheckParameters, CheckedRefs); // @skip-check query-in-loop - batch check of record keeping
		EndDo;
	EndDo;
	
	For Each MetadataKind In RegistersAsMetadataObjects() Do
		For Each MetadataObject In MetadataKind Do
			FullName = MetadataObject.FullName();
			If IsSharedMetadataObject(FullName) Then
				Continue;
			EndIf;
			If ObjectsToExcludeFromCheck.Find(FullName) <> Undefined Then
				Continue;
			EndIf;
			FindDeadRefsInRegisters(MetadataObject, CheckParameters, CheckedRefs); // @skip-check query-in-loop - batch check of record keeping
		EndDo;
	EndDo;
	
EndProcedure

// Checks filling of required attributes.
//
Procedure CheckUnfilledRequiredAttributes(Validation, CheckParameters) Export
	
	CheckExecutionParameters = ReadParameters(CheckParameters.CheckExecutionParameters);
	If CheckExecutionParameters <> Undefined Then
		If CheckExecutionParameters.ValidationArea = "Registers" Then
			
			MetadataObject = CheckExecutionParameters.MetadataObject; // MetadataObjectAccumulationRegister, MetadataObjectInformationRegister, MetadataObjectCalculationRegister, MetadataObjectAccountingRegister 
			FindNotFilledRequiredAttributesInRegisters(MetadataObject, CheckParameters);
		Else
			FindNotFilledRequiredAttributes(CheckExecutionParameters.MetadataObject, CheckParameters);
		EndIf;
		
		Return;
	EndIf;
	
	If CheckParameters.Property("ObjectsToCheck") And CheckParameters.ObjectsToCheck <> Undefined Then
		If TypeOf(CheckParameters.ObjectsToCheck) = Type("Array") Then
			MetadataObject = CheckParameters.ObjectsToCheck[0].Metadata();
		Else
			MetadataObject = CheckParameters.ObjectsToCheck.Metadata();
		EndIf;
		FindNotFilledRequiredAttributes(MetadataObject, CheckParameters);
		Return;
	EndIf;
	
	ObjectsToExcludeFromCheck = AccountingAuditInternalCached.ObjectsToExcludeFromCheck();
	
	For Each MetadataKind In MetadataObjectsRefKinds() Do
		
		For Each MetadataObject In MetadataKind Do
			FullName = MetadataObject.FullName();
			If IsSharedMetadataObject(FullName) Then
				Continue;
			EndIf;
			If Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
				Continue;
			EndIf;
			If ObjectsToExcludeFromCheck.Find(FullName) <> Undefined
				 Or StrStartsWith(MetadataObject.Name, "Delete") Then
					Continue;
			EndIf;
			FindNotFilledRequiredAttributes(MetadataObject, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
		EndDo;
		
	EndDo;
	
	For Each MetadataKind In RegistersAsMetadataObjects() Do
		For Each MetadataObject In MetadataKind Do
			FullName = MetadataObject.FullName();
			If IsSharedMetadataObject(FullName) Then
				Continue;
			EndIf;
			If Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
				Continue;
			EndIf;
			If ObjectsToExcludeFromCheck.Find(FullName) <> Undefined
				 Or StrStartsWith(MetadataObject.Name, "Delete") Then
					Continue;
			EndIf;
			FindNotFilledRequiredAttributesInRegisters(MetadataObject, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
		EndDo;
	EndDo;
	
EndProcedure

// Performs a check for circular references.
//
Procedure CheckCircularRefs(Validation, CheckParameters) Export
	
	For Each MetadataKind In MetadataObjectsRefKinds() Do
		For Each MetadataObject In MetadataKind Do
			If IsSharedMetadataObject(MetadataObject.FullName()) Then
				Continue;
			EndIf;
			If Not HasHierarchy(MetadataObject.StandardAttributes) Then
				Continue;
			EndIf;
			FindCircularRefs(MetadataObject, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
		EndDo;
	EndDo;
	
EndProcedure

Procedure FixInfiniteLoopInBackgroundJob(Val CheckParameters, StorageAddress = Undefined) Export
	
	Validation = CheckByID(CheckParameters.CheckID);
	If Not ValueIsFilled(Validation) Then
		Return;
	EndIf;
	
	CorrectCircularRefsProblem(Validation);
	
EndProcedure

// Checks if there are missing predefined items.
//
Procedure CheckMissingPredefinedItems(Validation, CheckParameters) Export
	
	// Clearing the cache before calling the CommonClientServer.PredefinedItem function.
	RefreshReusableValues();
	
	MetadataObjectsKinds = New Array;
	MetadataObjectsKinds.Add(Metadata.Catalogs);
	MetadataObjectsKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataObjectsKinds.Add(Metadata.ChartsOfAccounts);
	MetadataObjectsKinds.Add(Metadata.ChartsOfCalculationTypes);
	
	For Each MetadataKind In MetadataObjectsKinds Do
		For Each MetadataObject In MetadataKind Do
			If IsSharedMetadataObject(MetadataObject.FullName()) Then
				Continue;
			EndIf;
			If MetadataObject.PredefinedDataUpdate = Metadata.ObjectProperties.PredefinedDataUpdate.DontAutoUpdate Then
				Continue;
			EndIf;
			If StrStartsWith(MetadataObject.Name, "Delete") Then
				Continue;
			EndIf;
			FindMissingPredefinedItems(MetadataObject, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
		EndDo;
	EndDo;
	
EndProcedure

// Checks if there are duplicate predefined items.
//
Procedure CheckDuplicatePredefinedItems(Validation, CheckParameters) Export
	
	MetadataObjectsKinds = New Array;
	MetadataObjectsKinds.Add(Metadata.Catalogs);
	MetadataObjectsKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataObjectsKinds.Add(Metadata.ChartsOfAccounts);
	MetadataObjectsKinds.Add(Metadata.ChartsOfCalculationTypes);
	
	For Each MetadataKind In MetadataObjectsKinds Do
		
		If MetadataKind.Count() = 0 Then
			Continue;
		EndIf;
		
		FindPredefinedItemsDuplicates(MetadataKind, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
		
	EndDo;
	
EndProcedure

// Checks if there are missing predefined exchange plan nodes.
//
Procedure CheckPredefinedExchangePlanNodeAvailability(Validation, CheckParameters) Export
	
	MetadataExchangePlans = Metadata.ExchangePlans;
	For Each MetadataExchangePlan In MetadataExchangePlans Do
		
		If IsSharedMetadataObject(MetadataExchangePlan.FullName()) Then
			Continue;
		EndIf;
		If ExchangePlans[MetadataExchangePlan.Name].ThisNode() <> Undefined Then
			Continue;
		EndIf;
		
		Issue1 = IssueDetails(Common.MetadataObjectID(MetadataExchangePlan.FullName()), CheckParameters); // @skip-check query-in-loop - batch check of record keeping
		Issue1.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong sơ đồ trao đổi ""%1"" không có nút định trước (%2 = Không xác định).';
																							|ru = 'В плане обмена ""%1"" отсутствует предопределенный узел (%2 = Неопределено).';
																							|en = 'Predefined node is missing from exchange plan ""%1"" (%2 = Undefined).'; fa = 'Predefined node is missing from exchange plan ""%1"" (%2 = Undefined).';
																							|it = 'Nel piano di scambio ""%1"" manca il nodo predefinito (%2 = non definito).';
																							|pl = 'W planie wymiany ""%1"" brak predefiniowanego węzła (%2 = Nieokreślono).';
																							|tr = '""%1"" değişim planında önceden tanımlanmış düğüm eksik (%2 = Tanımsız).'"), MetadataExchangePlan.Name, "ThisNode()");
		WriteIssue(Issue1, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
		
	EndDo;
	
EndProcedure

#EndRegion

#Region UserErrorsIndication

// Parameters:
//   Form                - ClientApplicationForm
//   NamesUniqueKey - String
//   GroupParentName    - String
//                        - Undefined
//   OutputAtBottom        - Boolean
//
Function PlaceErrorIndicatorGroup(Form, NamesUniqueKey, GroupParentName = Undefined, OutputAtBottom = False) Export
	
	FormAllItems = Form.Items;
	
	If GroupParentName = Undefined Then
		PlaceContext = Form;
	Else
		GroupParent = FormAllItems.Find(GroupParentName);
		If GroupParent = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không tồn tại nhóm biểu mẫu đã chỉ ra: ""%1""';
																				|ru = 'Не существует указанная группа формы: ""%1""';
																				|en = 'The specified form group ""%1"" does not exist'; fa = 'The specified form group ""%1"" does not exist';
																				|it = 'Non esiste il gruppo del modulo indicato: ""%1""';
																				|pl = 'Nie istnieje określonej grupy formularza: ""%1""';
																				|tr = 'Belirtilen form grubu mevcut değil: ""%1""'"), GroupParentName);
		EndIf;
		PlaceContext = GroupParent;
	EndIf;
	
	ErrorIndicatorGroup = FormAllItems.Add("ErrorIndicatorGroup_" + NamesUniqueKey, Type("FormGroup"), PlaceContext); // FormTable
	ErrorIndicatorGroup.Type                      = FormGroupType.UsualGroup;
	ErrorIndicatorGroup.ShowTitle      = False;
	ErrorIndicatorGroup.Group              = ChildFormItemsGroup.AlwaysHorizontal;
	ErrorIndicatorGroup.HorizontalStretch = True;
	ErrorIndicatorGroup.BackColor                 = StyleColors.MasterFieldBackground;
	
	ContextSubordinateItems = PlaceContext.ChildItems;
	If OutputAtBottom Then
		FormAllItems.Move(ErrorIndicatorGroup, PlaceContext);
	Else
		If ContextSubordinateItems.Count() > 0 Then
			FormAllItems.Move(ErrorIndicatorGroup, PlaceContext, ContextSubordinateItems.Get(0));
		EndIf;
	EndIf;
	
	Return ErrorIndicatorGroup;
	
EndFunction

// Parameters:
//   Form - ClientApplicationForm
//   ErrorIndicatorGroup       - FormGroup
//   NamesUniqueKey         - String
//   IssuesIndicatorPicture - Picture
//                                - Undefined
//   MainRowIndicator         - FormattedString
//
Procedure FillErrorIndicatorGroup(Form, ErrorIndicatorGroup, NamesUniqueKey,
	MainRowIndicator, Settings) Export
	
	LastCheckDate     = Settings.LastCheckDate;
	ToolTip = NStr("vi = '(Theo tình trạng trên %1)';
					|ru = '(По состоянию на %1)';
					|en = '(As of %1)'; fa = '(As of %1)';
					|it = '(In base allo stato al %1)';
					|pl = '(Według stanu na %1)';
					|tr = '(%1 tarihi itibari ile)'");
	ToolTip = StringFunctionsClientServer.SubstituteParametersToString(ToolTip, LastCheckDate);
	
	ManagedFormItems = Form.Items;
	
	ErrorIndicatorPicture = ManagedFormItems.Add("PictureDecoration_" + NamesUniqueKey, Type("FormDecoration"), ErrorIndicatorGroup);
	ErrorIndicatorPicture.Type            = FormDecorationType.Picture;
	ErrorIndicatorPicture.Picture       = IssuePicture(Settings);
	ErrorIndicatorPicture.PictureSize = PictureSize.RealSize;
	
	LabelDecoration = ManagedFormItems.Add("LabelDecoration_" + NamesUniqueKey, Type("FormDecoration"), ErrorIndicatorGroup);
	LabelDecoration.Type                   = FormDecorationType.Label;
	LabelDecoration.Title             = MainRowIndicator;
	LabelDecoration.VerticalAlign = ItemVerticalAlign.Center;
	LabelDecoration.SetAction("URLProcessing", "Attachable_OpenIssuesReport");
	LabelDecoration.ToolTipRepresentation = ToolTipRepresentation.ShowRight;
	LabelDecoration.AutoMaxWidth = False;
	LabelDecoration.ExtendedTooltip.Title = ToolTip;
	LabelDecoration.ExtendedTooltip.Height = 1;
	
EndProcedure

// Generates a common string that indicates the existence of errors. It consists of an explanatory text and
// a hyperlink that opens the report on the object issues.
//
// Parameters:
//  ClientApplicationForm   - lientApplicationForm - an object form where the indicator group is placed.
//  ObjectReference               - AnyRef - a reference to the object, by which errors were found.
//  ObjectIssuesCount - Number - a quantity of the found object issues.
//  IssuesIndicatorNote - String, Undefined - a string that identifies issues that the current object has.
//                                 Can be overridden by the end developer - adding a parameter when calling is enough.
//  IssuesIndicatorHyperlink - String, Undefined - the string representing the hyperlink 
//                                 that opens and generates a report on the issues of the current object.
//
Function GenerateCommonStringIndicator(Form, ObjectReference, Settings) Export
	
	IssuesIndicatorNote   = Settings.IssuesIndicatorNote;
	IssuesIndicatorHyperlink = Settings.IssuesIndicatorHyperlink;
	IssuesCountByObject   = Settings.IssuesCount;
	TextRef = "Main";
	
	If Settings.DetailedKind And ValueIsFilled(Settings.IssueText) Then
		Return Settings.IssueText;
	EndIf;
	
	If IssuesIndicatorNote <> Undefined Then
		NoteLabel = IssuesIndicatorNote
	Else
		NoteLabel = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong này %1';
																					|ru = 'В этом %1';
																					|en = 'In this %1'; fa = 'In this %1';
																					|it = 'In questo %1';
																					|pl = 'W tym %1';
																					|tr = 'Bu %1'"), ObjectPresentationByType(ObjectReference));
	EndIf;
	
	If IssuesIndicatorHyperlink <> Undefined Then
		Hyperlink = IssuesIndicatorHyperlink;
	Else
		Hyperlink = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'đã tìm thấy vấn đề (%1)';
																					|ru = 'найдены проблемы (%1)';
																					|en = 'issues found (%1)'; fa = 'issues found (%1)';
																					|it = 'problemi trovati (%1)';
																					|pl = 'wykryto problemy (%1)';
																					|tr = 'problemler tespit edildi (%1)'"), Format(IssuesCountByObject, "NG=0"));
	EndIf;
	
	Return New FormattedString(NoteLabel + " ", New FormattedString(Hyperlink, , , , TextRef));
	
EndFunction

// See AccountingAuditOverridable.OnDetermineIndicationGroupParameters.
Procedure OnDetermineIndicationGroupParameters(IndicationGroupParameters, RefType) Export
	
	IndicationGroupParameters.Insert("GroupParentName", Undefined);
	IndicationGroupParameters.Insert("OutputAtBottom",     False);
	IndicationGroupParameters.Insert("DetailedKind",      True);
	
EndProcedure

// See AccountingAuditOverridable.OnDetermineIndicatiomColumnParameters.
Procedure OnDetermineIndicatiomColumnParameters(IndicationColumnParameters, FullName) Export
	
	IndicationColumnParameters.Insert("TitleLocation", FormItemTitleLocation.None);
	IndicationColumnParameters.Insert("Width",             2);
	IndicationColumnParameters.Insert("OutputLast",  False);
	
EndProcedure

#EndRegion

#Region ChecksExecute

// See AccountingAudit.ExecuteCheck.
Procedure ExecuteCheck(Validation, CheckExecutionParameters = Undefined, ObjectsToCheck = Undefined) Export
	
	If TypeOf(Validation) = Type("String") Then
		CheckToExecute = AccountingAudit.CheckByID(Validation);
	Else
		CheckToExecute = Validation;
	EndIf;
	
	If Not InfobaseUpdate.ObjectProcessed(CheckToExecute).Processed Then
		Return;
	EndIf;
	
	CheckExecutionParametersSpecified = CheckExecutionParameters <> Undefined;
	CheckParameters = PrepareCheckParameters(CheckToExecute, CheckExecutionParameters);
	If CheckRunning(CheckParameters.ScheduledJobID) Then
		Return;
	EndIf;
	
	If ValueIsFilled(ObjectsToCheck) And Not CheckParameters.SupportsRandomCheck Then
		Return;
	EndIf;
	
	AccountingChecks = AccountingAuditInternalCached.AccountingChecks();
	Checks             = AccountingChecks.Checks;
	CheckString       = Checks.Find(CheckParameters.Id, "Id");
	If CheckString = Undefined Then 
		Return;
	EndIf;
		
	If CheckString.NoCheckHandler Then
		Return;
	EndIf;
	
	CheckParameters.Insert("ObjectsToCheck", ObjectsToCheck);
	
	LastCheckResult = Undefined;
	If ValueIsFilled(ObjectsToCheck) Then
		LastCheckResult = LastObjectCheckResult(CheckParameters);
	ElsIf Not CheckExecutionParametersSpecified Then
		ClearResultsBeforeExecuteCheck(CheckToExecute);
	EndIf;
	
	ModulePerformanceMonitor = Undefined;
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		MeasurementDetails = ModulePerformanceMonitor.StartTimeConsumingOperationMeasurement(CheckParameters.Id);
	EndIf;
	
	SetAccountingCheckStatus(CheckToExecute);
	
	SessionParameters.AccountingIssuesCounter = 0;
	
	HandlerParameters = New Array;
	HandlerParameters.Add(CheckToExecute);
	HandlerParameters.Add(CheckParameters);
	Common.ExecuteConfigurationMethod(CheckString.HandlerChecks, HandlerParameters);
	
	If SessionParameters.AccountingIssuesCounter > 0
		And CheckParameters.IssueSeverity = Enums.AccountingIssueSeverity.Error Then
		Comment = NStr("vi = 'Khi thực hiện kiểm tra ""%1"" đã tìm thấy lỗi (%2)';
						|ru = 'При выполнении проверки ""%1"" обнаружены ошибки (%2)';
						|en = 'Errors (%2) occurred while checking ""%1""'; fa = 'Errors (%2) occurred while checking ""%1""';
						|it = 'Durante l''esecuzione della verifica ""%1"" sono stati rilevati degli errori (%2)';
						|pl = 'Podczas sprawdzenia ""%1"" wykryto błędy (%2)';
						|tr = '""%1"" kontrolü yapılırken hatalar tespit edildi (%2)'");
		Comment = StringFunctionsClientServer.SubstituteParametersToString(Comment,
			CheckParameters.Description, SessionParameters.AccountingIssuesCounter);
		WriteLogEvent(NStr("vi = 'Kiểm soát tiến hành kế toán';
							|ru = 'Контроль ведения учета';
							|en = 'Data integrity'; fa = 'یکپارچگی داده';
							|it = 'Controllo di contabilità';
							|pl = 'Kontrola prowadzenia ewidencji';
							|tr = 'Veri Bütünlüğü'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			Comment);
		
		SessionParameters.AccountingIssuesCounter = 0;
	EndIf;
	
	If LastCheckResult <> Undefined Then
		DeleteLastCheckResults(LastCheckResult);
	EndIf;
	
	If ModulePerformanceMonitor <> Undefined Then
		ModulePerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 0);
	EndIf;
	
EndProcedure

// To call from the AccountingAudit.AfterWriteAtServer procedure.
// Checks passed objects.
//
Procedure CheckObject(ObjectsToCheck, Checks) Export
	For Each Validation In Checks Do
		ExecuteCheck(Validation, , ObjectsToCheck); // @skip-check query-in-loop - batch check of record keeping
	EndDo;
EndProcedure

// AccountingCheck scheduled job handler. Designed to process the background
// startup of application checks.
//
//   Parameters:
//       ScheduledJobID - String
//                                         - Undefined - a string ID of the scheduled job.
//
Procedure CheckAccounting(ScheduledJobID = Undefined) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.AccountingCheck);
	
	If ScheduledJobID <> Undefined Then
		
		CheckParameters = CheckByScheduledJobIDParameters(ScheduledJobID);
		If CheckParameters <> Undefined Then
			ExecuteCheck(CheckParameters.Id);
		EndIf;
		
	Else
		
		Query = New Query(
		"SELECT
		|	AccountingCheckRules.Id AS Id
		|FROM
		|	Catalog.AccountingCheckRules AS AccountingCheckRules
		|WHERE
		|	AccountingCheckRules.RunMethod = VALUE(Enum.CheckMethod.ByCommonSchedule)
		|	AND AccountingCheckRules.Use");
		
		Result = Query.Execute().Select();
		While Result.Next() Do
			ExecuteCheck(Result.Id); // @skip-check query-in-loop - batch check of record keeping
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ExecuteChecks(Val Checks) Export
	
	For Each Validation In Checks Do
		ExecuteCheck(Validation); // @skip-check query-in-loop - batch check of record keeping
	EndDo;
	
EndProcedure

// See AccountingAudit.CheckByID.
Function CheckByID(Id) Export
	
	Query = New Query(
	"SELECT TOP 1
	|	AccountingCheckRules.Ref AS Validation
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|WHERE
	|	AccountingCheckRules.Id = &Id
	|	AND NOT AccountingCheckRules.DeletionMark");
	
	Query.SetParameter("Id", Id);
	Result = Query.Execute().Select();
	
	If Not Result.Next() Then
		Return Catalogs.AccountingCheckRules.EmptyRef();
	Else
		Return Result.Validation;
	EndIf;
	
EndFunction

Function DataIntegrityChecksInfoRecords(Checks)
	
	ColumnsNames = New Array;
	For Each Column In Checks.Columns Do
		If Column.Name = "Id"
			Or Column.Name = "GroupID" Then
			Continue;
		EndIf;
		ColumnsNames.Add("Checks" + "." + Column.Name);
	EndDo;
	
	Query = New Query(
	"SELECT
	|	Checks.Id AS Id,
	|	Checks.GroupID AS GroupID,
	|	&ColumnsToSelect
	|INTO VTChecks
	|FROM
	|	&Checks AS Checks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Checks.Id AS Id,
	|	Checks.GroupID AS GroupID,
	|	&ColumnsToSelect,
	|	ISNULL(AccountingChecks_.Ref, VALUE(Catalog.AccountingCheckRules.EmptyRef)) AS Validation,
	|	AccountingChecks_.AccountingCheckIsChanged AS AccountingCheckIsChanged,
	|	DataIntegrityCheckParents.Ref AS CheckParent1,
	|	DataIntegrityCheckParents.AccountingChecksContext AS DataIntegrityCheckParentContext
	|FROM
	|	VTChecks AS Checks
	|		LEFT JOIN Catalog.AccountingCheckRules AS AccountingChecks_
	|		ON Checks.Id = AccountingChecks_.Id
	|			AND (NOT AccountingChecks_.DeletionMark)
	|		LEFT JOIN Catalog.AccountingCheckRules AS DataIntegrityCheckParents
	|		ON Checks.GroupID = DataIntegrityCheckParents.Id
	|			AND (NOT DataIntegrityCheckParents.DeletionMark)");
	Query.Text = StrReplace(Query.Text, "&ColumnsToSelect", StrConcat(ColumnsNames, ","));
	
	Query.SetParameter("Checks", Checks);
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// See AccountingAudit.ExecuteChecksInContext.
Function ChecksByContext(AccountingChecksContext) Export
	
	Query = New Query(
	"SELECT
	|	""SelectionParentlessItemsConsideringContext"" AS QueryPurpose,
	|	VALUE(Catalog.AccountingCheckRules.EmptyRef) AS Parent,
	|	AccountingCheckRules.Ref AS Validation
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|WHERE
	|	NOT AccountingCheckRules.IsFolder
	|	AND AccountingCheckRules.Use
	|	AND AccountingCheckRules.Parent = VALUE(Catalog.AccountingCheckRules.EmptyRef)
	|	AND AccountingCheckRules.AccountingChecksContext = &AccountingChecksContext
	|
	|UNION ALL
	|
	|SELECT
	|	""SelectGroupsConsideringContext"",
	|	AccountingCheckRules.Parent,
	|	AccountingCheckRules.Ref
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|WHERE
	|	AccountingCheckRules.IsFolder
	|	AND AccountingCheckRules.AccountingChecksContext = &AccountingChecksContext
	|
	|UNION ALL
	|
	|SELECT
	|	""SelectionItemsWithParentsIgnoringContext"",
	|	AccountingCheckRules.Parent,
	|	AccountingCheckRules.Ref
	|FROM
	|	Catalog.AccountingCheckRules AS AccountingCheckRules
	|WHERE
	|	NOT AccountingCheckRules.IsFolder
	|	AND AccountingCheckRules.Use
	|	AND AccountingCheckRules.Parent <> VALUE(Catalog.AccountingCheckRules.EmptyRef)");
	
	Query.SetParameter("AccountingChecksContext", AccountingChecksContext);
	AllChecks = Query.Execute().Unload();
	
	Result  = New Array;
	ParentChecks = AllChecks.Copy(AllChecks.FindRows(
		New Structure("QueryPurpose", "SelectGroupsConsideringContext")), "Parent, Validation");
	
	For Each ResultString1 In AllChecks Do
		
		If ResultString1.QueryPurpose = "SelectionParentlessItemsConsideringContext"
			Or (ResultString1.QueryPurpose = "SelectionItemsWithParentsIgnoringContext"
			And ParentChecks.Find(ResultString1.Parent) <> Undefined) Then
			Result.Add(ResultString1.Validation);
		EndIf;
		
	EndDo;
	
	Return CommonClientServer.CollapseArray(Result);
	
EndFunction

// See AccountingAudit.CheckExecutionParameters.
Function CheckExecutionParameters(Val Property1, Val Property2 = Undefined, Val Property3 = Undefined,
	Val Property4 = Undefined, Val Property5 = Undefined, Val AdditionalProperties = Undefined) Export
	
	PropertiesCount             = PropertiesCount();
	LastValuableParameterFound = False;
	
	For IndexOf = 2 To PropertiesCount Do
		If IndexOf = 2 Then
			ParameterValue = Property2;
		ElsIf IndexOf = 3 Then
			ParameterValue = Property3;
		ElsIf IndexOf = 4 Then
			ParameterValue = Property4;
		ElsIf IndexOf = 5 Then
			ParameterValue = Property5;
		EndIf;
		If ParameterValue = Undefined Then
			If Not LastValuableParameterFound Then
				LastValuableParameterFound = True;
			EndIf;
		Else
			If LastValuableParameterFound Then
				MessageText = NStr("vi = 'Đã xác định tham số thực hiện kiểm tra không theo trình tự trong %1.';
									|ru = 'Параметры выполнения проверки заданы не по порядку в %1.';
									|en = 'The check parameters in %1 are not in correct order.'; fa = 'The check parameters in %1 are not in correct order.';
									|it = 'Parametri di esecuzione verifica indicati non in ordine in %1.';
									|pl = 'Parametry wykonania sprawdzenia są zadanie poza kolejnością w %1.';
									|tr = '%1''da kontrol parametreleri sıralarına göre ayarlanmamış.'");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, "AccountingAudit.CheckExecutionParameters");
				Raise MessageText;
			EndIf;
		EndIf;
	EndDo;
	
	If AdditionalProperties <> Undefined And Property5 = Undefined Then
		MessageText = NStr("vi = 'Đã xác định tham số thực hiện kiểm tra không theo trình tự trong %1.';
							|ru = 'Параметры выполнения проверки заданы не по порядку в %1.';
							|en = 'The check parameters in %1 are not in correct order.'; fa = 'The check parameters in %1 are not in correct order.';
							|it = 'Parametri di esecuzione verifica indicati non in ordine in %1.';
							|pl = 'Parametry wykonania sprawdzenia są zadanie poza kolejnością w %1.';
							|tr = '%1''da kontrol parametreleri sıralarına göre ayarlanmamış.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, "AccountingAudit.CheckExecutionParameters");
		Raise MessageText;
	EndIf;
	
	AllParameters = New Array;
	AllParameters.Add(Property1);
	For IndexOf = 2 To PropertiesCount Do
		
		If IndexOf = 2 Then
			PropertyValue = Property2;
		ElsIf IndexOf = 3 Then
			PropertyValue = Property3;
		ElsIf IndexOf = 4 Then
			PropertyValue = Property4;
		ElsIf IndexOf = 5 Then
			PropertyValue = Property5;
		EndIf;
		If PropertyValue = Undefined Then
			Break;
		EndIf;
		AllParameters.Add(PropertyValue);
		
	EndDo;
	
	If AdditionalProperties <> Undefined Then
		CommonClientServer.SupplementArray(AllParameters, AdditionalProperties); 
	EndIf;
	
	Return CheckExecutionParametersFromArray(AllParameters);
	
EndFunction

Function CheckExecutionParametersFromArray(Val Parameters)
	
	CheckKindDescription = "";
	IndexOf = 1;
	Result = New Structure;
	
	For Each CurrentParameter In Parameters Do
		
		CommonClientServer.CheckParameter("AccountingAudit.CheckExecutionParameters", 
			"Property" + Format(IndexOf, "NG=0"), CurrentParameter, ExpectedPropertiesTypesOfChecksKinds());
			
		CheckKindDescription = CheckKindDescription + ?(ValueIsFilled(CheckKindDescription), ", ", "") 
			+ Format(CurrentParameter, "DLF=D; NG=0");
		Result.Insert("Property" + Format(Parameters.Find(CurrentParameter) + 1, "NG=0"), CurrentParameter);
		
		IndexOf = IndexOf + 1;
		
	EndDo;
	
	Result.Insert("Description", CheckKindDescription);
	Return Result;

EndFunction

Procedure SetAccountingCheckStatus(Validation)
	
	SetPrivilegedMode(True);
	RecordManager = InformationRegisters.AccountingChecksStates.CreateRecordManager();
	RecordManager.Validation = Validation;
	RecordManager.LastRun = CurrentSessionDate();
	RecordManager.Write();
	
EndProcedure

#EndRegion

#Region RegistersInformation

Function InformationRegisterReferenceFields(MetadataObject)
	RegisterInformation = IndependentRegisterInformation(MetadataObject).RegisterInformation;
	Result = NewFieldsDetails();
	If MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
		Field = Result.Add();
		Field.Name = "Recorder";
		Field.PresentationToDescription = PresentationToDescription(MetadataObject.StandardAttributes.Recorder);
	EndIf;
	
	For Each AttributeInformation In RegisterInformation Do
		If AttributeInformation.ContainsRefType Then
			Field = Result.Add();
			Field.Name = AttributeInformation.NameOfMetadataObjects;
			Field.PresentationToDescription = AttributeInformation.PresentationToDescription;
		EndIf;
	EndDo;
	Return Result;
EndFunction

Function PresentationToDescription(FieldMetadata, Postfix = "")
	Result = FieldMetadata.Synonym;
	If ValueIsFilled(Result) Then
		SynonymWithoutSeparators = StrReplace(FieldMetadata.Synonym, " ", "");
		SynonymWithoutSeparators = StrReplace(SynonymWithoutSeparators, ":", "");
		SynonymWithoutSeparators = StrReplace(SynonymWithoutSeparators, "-", "");
		SynonymWithoutSeparators = StrReplace(SynonymWithoutSeparators, "(", "");
		SynonymWithoutSeparators = StrReplace(SynonymWithoutSeparators, ")", "");
		IsSynonymDerivedFromName = Lower(SynonymWithoutSeparators) = Lower(FieldMetadata.Name);
		If Not IsSynonymDerivedFromName Then
			Result = StrTemplate("%1 (%2)", FieldMetadata.Synonym, FieldMetadata.Name);	
		EndIf;
	Else
		Result = FieldMetadata.Name;
	EndIf;
	
	If ValueIsFilled(Postfix) Then
		Result = Result + " " + Postfix;
	EndIf;

	Return Result;
EndFunction

Procedure AddAttributesInformation(RegisterInformation, ItemsMeta, MetadataTypeInNominativeCase)
	For Each FieldMetadata In ItemsMeta Do
		AttributeInformation = RegisterInformation.Add();
		AttributeInformation.MetadataTypeInNominativeCase = MetadataTypeInNominativeCase;
		AttributeInformation.NameOfMetadataObjects = FieldMetadata.Name;
		AttributeInformation.ContainsRefType = ContainsRefType(FieldMetadata);
		AttributeInformation.IsItDimension = MetadataTypeInNominativeCase = "Dimension";
		AttributeInformation.PresentationToDescription = PresentationToDescription(FieldMetadata);
	EndDo;	
EndProcedure

Function IndependentRegisterInformation(MetadataObject, GetDimensions = True, GetResources = True, GetAttributes = True)
	
	RegisterInformation = New ValueTable;
	RegisterInformation.Columns.Add("MetadataTypeInNominativeCase", New TypeDescription("String", , , , New StringQualifiers(16)));
	RegisterInformation.Columns.Add("NameOfMetadataObjects",                    New TypeDescription("String", , , , New StringQualifiers(128)));
	RegisterInformation.Columns.Add("ContainsRefType", New TypeDescription("Boolean"));
	RegisterInformation.Columns.Add("AliasOfField");
	RegisterInformation.Columns.Add("IsItDimension", New TypeDescription("Boolean"));
	RegisterInformation.Columns.Add("PresentationToDescription");
	
	If GetDimensions Then
		AddAttributesInformation(RegisterInformation, MetadataObject.Dimensions, "Dimension");
	EndIf;
	
	If GetResources Then
		AddAttributesInformation(RegisterInformation, MetadataObject.Resources, "Resource");
	EndIf;
	
	If GetAttributes Then
		AddAttributesInformation(RegisterInformation, MetadataObject.Attributes, "Attribute");
	EndIf;
	
	ListOfSelectionFields = New Array();
	For Each AttributeInformation In RegisterInformation Do
		AliasOfField = StrTemplate("%1%2Ref", AttributeInformation.NameOfMetadataObjects, AttributeInformation.MetadataTypeInNominativeCase);  // @query-part
		ExpressionOfSelection = StrTemplate("SpecifiedTableAlias.%1 AS %2", AttributeInformation.NameOfMetadataObjects, AliasOfField);  // @query-part
		ListOfSelectionFields.Add(ExpressionOfSelection);
	EndDo;

	Result = New Structure;
	Result.Insert("RegisterInformation", RegisterInformation);
	Result.Insert("SelectionFields1", StrConcat(ListOfSelectionFields, ","));
	Return Result;
	
EndFunction

Function RecordPositionValue(RegisterDataSelection, RecordPositionFields)
	Result = New Structure;
	For Each Field In RecordPositionFields Do
		Simple = RegisterDataSelection[Field.Name];
		Result.Insert(Field.Name, Simple);
	EndDo;
	Return Result;
EndFunction

Function RecordPositionPresentation(RegisterDataSelection, RecordPositionFields)
	PresentationParts = New Array();
	For Each Field In RecordPositionFields Do
		FieldValueIntoPresentation = RegisterDataSelection[Field.Name];
		If Not ValueIsFilled(FieldValueIntoPresentation) Then
			FieldValueIntoPresentation = NStr("ru = '<не указан>';
												|vi = '<not specified>';
												|en = '<not specified>'; fa = '<مشخص نشده>';
												|it = '<not specified>';
												|pl = '<not specified>';
												|tr = '<belirtilmedi>'");
		EndIf;
		
		FieldPresentation = StrTemplate("%1 = %2", Field.PresentationToDescription, FieldValueIntoPresentation);
		If Field.Name = "Recorder" Then
			Template = NStr("ru = '%1 (номер строки = %2)';
							|vi = '%1 (string number = %2)';
							|en = '%1 (string number = %2)'; fa = '%1 (string number = %2)';
							|it = '%1 (string number = %2)';
							|pl = '%1 (string number = %2)';
							|tr = '%1 (satır numarası = %2)'");
			FieldPresentation = StringFunctionsClientServer.SubstituteParametersToString(Template, 
				FieldPresentation, Format(RegisterDataSelection.LineNumber, "NG=;"));
		EndIf;		
		PresentationParts.Add(FieldPresentation);
	EndDo;
	Result = StrConcat(PresentationParts, Chars.LF);
	Return Result;
EndFunction

Function RecordPositionFields(MetadataObject)
	Result = NewFieldsDetails();
	
	IsInformationRegisterWithoutRecorder = Common.IsInformationRegister(MetadataObject)
		And MetadataObject.WriteMode <> Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate;
	If IsInformationRegisterWithoutRecorder Then
		If MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
			Field = Result.Add();
			Field.Name = "Period";
			Field.PresentationToDescription = PresentationToDescription(MetadataObject.StandardAttributes.Period); 
		EndIf;
		For Each MetaDimension In MetadataObject.Dimensions Do			
			Field = Result.Add();
			Field.Name = MetaDimension.Name;
			Field.PresentationToDescription = PresentationToDescription(MetaDimension);
		EndDo;
	Else
		Field = Result.Add();
		Field.Name = "Recorder";
		Field.PresentationToDescription = PresentationToDescription(MetadataObject.StandardAttributes.Recorder);
	EndIf;
	Return Result;
EndFunction

Function FieldsOfRequiredAttributes(MetadataObject)
	Result = NewFieldsDetails();
	AttributesClasses = StrSplit("Dimensions,Attributes,Resources", ",");
	
	IsAccountingRegisterWithCorrespondence = Common.IsAccountingRegister(MetadataObject)
		And MetadataObject.Correspondence;
	For Each AttributesClass In AttributesClasses Do
		For Each FieldMetadata In MetadataObject[AttributesClass] Do
			If FieldMetadata.FillChecking <> FillChecking.ShowError Then
				Continue;
			EndIf;
			
			IsNotBalanceField = IsAccountingRegisterWithCorrespondence
				And (AttributesClass = "Dimensions" Or AttributesClass = "Resources")
				And Not FieldMetadata.Balance; 
			If IsNotBalanceField Then
				Field = Result.Add();
				Field.Name = FieldMetadata.Name + "Dr";
				Field.PresentationToDescription = PresentationToDescription(FieldMetadata, "DR");
				
				Field = Result.Add();
				Field.Name = FieldMetadata.Name + "Cr";
				Field.PresentationToDescription = PresentationToDescription(FieldMetadata, "CR");
			Else
				Field = Result.Add();
				Field.Name = FieldMetadata.Name;
				Field.PresentationToDescription = PresentationToDescription(FieldMetadata);
			EndIf;
		EndDo;
	EndDo;

	Return Result;
EndFunction

Function NewFieldsDetails()
	Result = New ValueTable();
	Result.Columns.Add("Name");
	Result.Columns.Add("PresentationToDescription");
	Return Result;	
EndFunction

Function RegisterDataSelection(FullName, CheckParameters, RecordPositionFields)
	RegisterManager = Common.ObjectManagerByFullName(FullName);
	
	ThereIsPeriod = RecordPositionFields.Find("Period", "Name") <> Undefined;
	CheckStartDate = CommonClientServer.StructureProperty(CheckParameters, "CheckStartDate");
	If ThereIsPeriod And ValueIsFilled(CheckStartDate) Then
		Result = RegisterManager.Select(CheckStartDate);
	Else 
		Result = RegisterManager.Select();
	EndIf;	
	Return Result;
EndFunction

#EndRegion

#Region RefIntegrityControl

Procedure FindDeadRefs(MetadataObject, CheckParameters, CheckedRefs)
	
	RefAttributes = ObjectRefAttributes(MetadataObject);
	If RefAttributes.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	HasRestrictionByDate = ValueIsFilled(CheckParameters.CheckStartDate) 
		And (Common.IsDocument(MetadataObject) Or Common.IsTask(MetadataObject) 
			Or Common.IsBusinessProcess(MetadataObject));
			
	If HasRestrictionByDate Then
		QueryText = 
		"SELECT TOP 1000
		|	SpecifiedTableAlias.Ref AS ObjectWithIssue,
		|	&RefAttributes
		|	,&TabularSectionsAttributes
		|FROM
		|	&MetadataObject AS SpecifiedTableAlias
		|WHERE
		|	&Condition
		|	AND SpecifiedTableAlias.Date > &CheckStartDate
		|	AND NOT SpecifiedTableAlias.DeletionMark
		|
		|ORDER BY
		|	SpecifiedTableAlias.Ref";
		Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
	Else
		QueryText = 
		"SELECT TOP 1000
		|	SpecifiedTableAlias.Ref AS ObjectWithIssue,
		|	&RefAttributes
		|	,&TabularSectionsAttributes
		|FROM
		|	&MetadataObject AS SpecifiedTableAlias
		|WHERE
		|	&Condition
		|	AND NOT SpecifiedTableAlias.DeletionMark
		|
		|ORDER BY
		|	SpecifiedTableAlias.Ref";
	EndIf;
	
	TableName = StrReplace(MetadataObject.FullName(), ".", "");
	If CheckParameters.Property("ObjectsToCheck") And CheckParameters.ObjectsToCheck <> Undefined Then
		Condition = TableName + ".Ref IN (&Ref)";
		Query.SetParameter("Ref", CheckParameters.ObjectsToCheck);
	Else
		Condition = TableName + ".Ref > &Ref";
		Query.SetParameter("Ref", "");
	EndIf;
	
	QueryText = StrReplace(QueryText, "SpecifiedTableAlias", TableName);
	QueryText = StrReplace(QueryText, "&Condition", Condition);
	QueryText = StrReplace(QueryText, "&MetadataObject", MetadataObject.FullName());
	QueryText = StrReplace(QueryText, "&RefAttributes", StrConcat(RefAttributes, ","));
	
	ObjectTabularSectionsAttributes = ObjectTabularSectionsRefAttributes(MetadataObject);
	If ObjectTabularSectionsAttributes.Count() > 0 Then
		Template = TableName + ".%1.(%2) AS %1";
		QueryTabularSections = "";
		For Each TabularSectionAttributes In ObjectTabularSectionsAttributes Do
			TabularSectionName    = TabularSectionAttributes.Key;
			AttributesString      = StrConcat(TabularSectionAttributes.Value, ",");
			FilledTemplate    = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				TabularSectionName,
				AttributesString);
			
			If ValueIsFilled(QueryTabularSections) Then
				QueryTabularSections = QueryTabularSections + "," + Chars.LF + FilledTemplate;
			Else
				QueryTabularSections = FilledTemplate;
			EndIf;
		EndDo;
		QueryText = StrReplace(QueryText, "&TabularSectionsAttributes", QueryTabularSections);
	Else
		QueryText = StrReplace(QueryText, ",&TabularSectionsAttributes", "");
	EndIf;
	
	Query.Text = QueryText;
	Result = Query.Execute().Unload();
	
	MaxCount = MaxCheckedRefsCount();
	HasEmployeeResponsible = MetadataObject.Attributes.Find("EmployeeResponsible") <> Undefined;
	
	While Result.Count() > 0 Do
		
		For Each ResultString1 In Result Do
			
			IssueSummary = "";
			
			ObjectReference = ResultString1.ObjectWithIssue;
			For IndexOf = 1 To Result.Columns.Count() - 1 Do
				RefToCheck = ResultString1[IndexOf];
				If IsDeadRef(RefToCheck, CheckedRefs) Then
					IssueSummary = IssueSummary + ?(ValueIsFilled(IssueSummary), Chars.LF, "")
						+ StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Trong đối tượng ""%1"" trong mục tin ""%2"" đã chỉ ra tham chiếu đến phần tử không tồn tại: ""%3"" (%4).';
								|ru = 'У объекта ""%1"" в реквизите ""%2"" указана ссылка на несуществующий элемент: ""%3"" (%4).';
								|en = 'The ""%2"" attribute of the ""%1"" object references an item that does not exist: ""%3"" (%4).'; fa = 'The ""%2"" attribute of the ""%1"" object references an item that does not exist: ""%3"" (%4).';
								|it = 'У объекта ""%1"" в реквизите ""%2"" указана ссылка на несуществующий элемент: ""%3"" (%4).';
								|pl = 'The ""%2"" attribute of the ""%1"" object references an item that does not exist: ""%3"" (%4).';
								|tr = '""%2"" özniteliğindeki ""%1"" nesnesi, var olmayan öğeye bağlantı içermektedir: ""%3"" (%4).'"), 
							ObjectReference, 
							Result.Columns[IndexOf].Name, 
							RefToCheck,
							TypeOf(RefToCheck));
				EndIf;
			EndDo;
			
			If CheckedRefs.Count() >= MaxCount Then
				CheckedRefs.Clear();
			EndIf;
			
			IssuesLimit    = 1;
			MoreIssues      = 0;
			If ObjectTabularSectionsAttributes.Count() > 0 Then
				For Each TabularSectionAttributes In ObjectTabularSectionsAttributes Do
					
					ObjectTabularSection = ResultString1[TabularSectionAttributes.Key];// ValueTable
					CurrentRowNumber1    = 1;
					
					For Each TSRow In ObjectTabularSection Do
						For Each CurrentColumn In ObjectTabularSection.Columns Do
							TSAttributeName = CurrentColumn.Name;
							DataToCheck1 = TSRow[TSAttributeName];
							If IsDeadRef(DataToCheck1, CheckedRefs) Then
								If IssuesLimit = 0 Then
									MoreIssues = MoreIssues + 1;
									Continue;
								EndIf;
								IssueSummary = IssueSummary + ?(ValueIsFilled(IssueSummary), Chars.LF, "")
									+ StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Trong đối tượng ""%1"" trong mục tin ""%2"" của phần bảng ""%3"" (dòng số %4) đã chỉ ra tham chiếu đến phần tử không tồn tại: ""%5"" (%6).';
											|ru = 'У объекта ""%1"" в реквизите ""%2"" табличной части ""%3"" (строка № %4) указана ссылка на несуществующий элемент: ""%5"" (%6).';
											|en = 'The ""%2"" attribute of the ""%3"" table (row #%4) in the ""%1"" object references an item that does not exist: ""%5"" (%6).'; fa = 'The ""%2"" attribute of the ""%3"" table (row #%4) in the ""%1"" object references an item that does not exist: ""%5"" (%6).';
											|it = 'У объекта ""%1"" в реквизите ""%2"" табличной части ""%3"" (строка № %4) указана ссылка на несуществующий элемент: ""%5"" (%6).';
											|pl = 'The ""%2"" attribute of the ""%3"" table (row #%4) in the ""%1"" object references an item that does not exist: ""%5"" (%6).';
											|tr = '""%3"" tablosunun (satır No. %4) ""%2"" özniteliğindeki ""%1"" nesnesi, var olmayan öğeye bağlantı içermektedir: ""%5"" (%6).'"),
										ObjectReference, TSAttributeName, StrReplace(TabularSectionAttributes.Key, TSAttributeName, ""), 
										CurrentRowNumber1, DataToCheck1, TypeOf(DataToCheck1));
								IssuesLimit = IssuesLimit - 1;
							EndIf;
						EndDo;
						CurrentRowNumber1 = CurrentRowNumber1 + 1;
					EndDo;
					
					If CheckedRefs.Count() >= MaxCount Then
						CheckedRefs.Clear();
					EndIf;
					
				EndDo;
			EndIf;
			
			If MoreIssues > 0 Then
				IssueSummary = IssueSummary + Chars.LF + NStr("vi = 'và còn hơn nữa';
																|ru = 'и еще проблем';
																|en = 'More issues'; fa = 'More issues';
																|it = 'e altri problemi';
																|pl = 'i jeszcze problem';
																|tr = 've daha fazla problem'") + ": " + String(MoreIssues);
			EndIf;
			
			If IsBlankString(IssueSummary) Then
				Continue;
			EndIf;
			
			Issue1 = IssueDetails(ObjectReference, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
			Issue1.IssueSummary = NStr("vi = 'Đã vi phạm tính toàn vẹn theo tham chiếu:';
										|ru = 'Нарушена ссылочная целостность:';
										|en = 'Reference integrity violation:'; fa = 'Reference integrity violation:';
										|it = 'È stata compromessa l''integrità del collegamento:';
										|pl = 'Naruszono jednolitość odnośnika:';
										|tr = 'Bağlantı bütünlüğü bozuldu:'") + Chars.LF + IssueSummary;
			If HasEmployeeResponsible Then
				Issue1.EmployeeResponsible = Common.ObjectAttributeValue(ObjectReference, "EmployeeResponsible");
			EndIf;
			WriteIssue(Issue1, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
			
		EndDo;
		
		If CheckParameters.Property("ObjectsToCheck") And CheckParameters.ObjectsToCheck <> Undefined Then
			Break;
		EndIf;
		
		Query.SetParameter("Ref", ResultString1.ObjectWithIssue);
		Result = Query.Execute().Unload(); // @skip-check query-in-loop - batch check of record keeping
		
	EndDo;
	
EndProcedure

Function ObjectRefAttributes(MetadataObject)
	
	Result = New Array;
	
	StandardAttributesDetails = MetadataObject.StandardAttributes;// StandardAttributeDescriptions
	For Each StandardAttribute In StandardAttributesDetails Do
		If StandardAttribute.Name = "Ref" Or StandardAttribute.Name = "RoutePoint" Then
			Continue;
		EndIf;
		If Not ContainsRefType(StandardAttribute) Then
			Continue;
		EndIf;
		Result.Add(StandardAttribute.Name);
	EndDo;
	
	AttributesDetails1 = MetadataObject.Attributes;// Array of MetadataObjectAttribute
	For Each Attribute In AttributesDetails1 Do
		If ContainsRefType(Attribute) Then
			Result.Add(Attribute.Name);
		EndIf;
	EndDo;
	
	If Common.IsTask(MetadataObject) Then
		
		AddressingAttributes = MetadataObject.AddressingAttributes;// Array of MetadataObjectAddressingAttribute
		For Each AddressingAttribute In AddressingAttributes Do
			If ContainsRefType(AddressingAttribute) Then
				Result.Add(AddressingAttribute.Name);
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ObjectTabularSectionsRefAttributes(MetadataObject)
	
	Result = New Map;
	For Each TabularSection In MetadataObject.TabularSections Do
		Attributes = New Array;
		TabularSectionAttributesDetails = TabularSection.Attributes;// Array of MetadataObjectAttribute
		For Each TabularSectionAttribute In TabularSectionAttributesDetails Do
			If ContainsRefType(TabularSectionAttribute) Then
				If TabularSectionAttribute.Name = "RoutePoint" Then
					Continue;
				EndIf;
				Attributes.Add(TabularSectionAttribute.Name);
			EndIf;
		EndDo;
		Result.Insert(TabularSection.Name, Attributes);
	EndDo;
	
	Return Result;
	
EndFunction

Function IsDeadRef(DataToCheck1, CheckedRefs) 
	
	If Not ValueIsFilled(DataToCheck1) Then
		Return False;
	EndIf;
	
	IsDeadRef = CheckedRefs[DataToCheck1];
	If IsDeadRef = False Then
		Return False;
	EndIf;
	
	CheckedDataType = TypeOf(DataToCheck1);
	If CheckedDataType = Type("Number") Then
		Return False;
	EndIf;
	
	If CheckedDataType = Type("Boolean") Then
		Return False;
	EndIf;
	
	If CheckedDataType = Type("String") Then
		Return False;
	EndIf;
	
	If CheckedDataType = Type("Date") Then
		Return False;
	EndIf;
	
	If CheckedDataType = Type("UUID") Then
		Return False;
	EndIf;
	
	If CheckedDataType = Type("ValueStorage") Then
		Return False;
	EndIf;
	
	If Not Common.RefTypeValue(DataToCheck1) Then
		Return False;
	EndIf;
	
	If CheckedDataType = Type("CatalogRef.MetadataObjectIDs")
		Or CheckedDataType = Type("CatalogRef.ExtensionObjectIDs") Then
		Return False;
	EndIf;
	
	If BusinessProcesses.RoutePointsAllRefsType().ContainsType(CheckedDataType) Then
		Return False;
	EndIf;
	
	If IsDeadRef = Undefined Then
		IsDeadRef = Not Common.RefExists(DataToCheck1);
		CheckedRefs[DataToCheck1] = IsDeadRef;
	EndIf;
	
	Return IsDeadRef;
	
EndFunction

Function MaxCheckedRefsCount()
	
	Return 100000;
	
EndFunction	

#Region RefIntegrityControlInRegisters

Procedure FindDeadRefsInRegisters(MetadataObject, CheckParameters, CheckedRefs)
	
	If MetadataObject.Dimensions.Count() = 0 Then
		Return;
	EndIf;
	
	If Common.IsAccumulationRegister(MetadataObject) Then
		FindDeadRefsInAccumulationRegisters(MetadataObject, CheckParameters, CheckedRefs);
	ElsIf Common.IsInformationRegister(MetadataObject) Then
		FindDeadRefsInInformationRegisters(MetadataObject, CheckParameters, CheckedRefs);
	ElsIf Common.IsAccountingRegister(MetadataObject) Then
		FindDeadRefsInAccountingRegisters(MetadataObject, CheckParameters, ExtDimensionTypes(MetadataObject), CheckedRefs);
	ElsIf Common.IsCalculationRegister(MetadataObject) Then
		FindDeadRefsInCalculationRegisters(MetadataObject, CheckParameters, CheckedRefs);
	EndIf;
	
EndProcedure

Procedure FindDeadRefsInAccumulationRegisters(MetadataObject, CheckParameters, CheckedRefs)
	
	MaxCount = MaxCheckedRefsCount();
	
	FullName         = MetadataObject.FullName();
	RegisterAttributes1 = RegisterRefAttributes(MetadataObject);
	
	QueryText =
	"SELECT TOP 1000
	|	MetadataObject.Recorder AS RecorderAttributeRef,
	|	MetadataObject.Period AS Period
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	MetadataObject.Period > &CheckStartDate
	|
	|GROUP BY
	|	MetadataObject.Period,
	|	MetadataObject.Recorder
	|
	|ORDER BY
	|	MetadataObject.Period";
	
	QueryText = StrReplace(QueryText, "&MetadataObject", FullName);
	
	Query = New Query(QueryText);
	Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
	Result = Query.Execute().Unload();
	
	RegisterManager = Common.ObjectManagerByFullName(FullName);
	
	While Result.Count() > 0 Do
		
		For Each ResultString1 In Result Do
			
			CurrentRecordSet = RegisterManager.CreateRecordSet(); // AccumulationRegisterRecordSet
			CurrentRecordSet.Filter.Recorder.Set(ResultString1.RecorderAttributeRef);
			CurrentRecordSet.Read();
			
			ProblemRecordsNumbers = "";
			For Each CurrentRecord In CurrentRecordSet Do
				For Each AttributeName In RegisterAttributes1 Do
					If IsDeadRef(CurrentRecord[AttributeName], CheckedRefs) Then
						ProblemRecordsNumbers = ProblemRecordsNumbers + ?(ValueIsFilled(ProblemRecordsNumbers), ", ", "")
							+ Format(CurrentRecordSet.IndexOf(CurrentRecord) + 1, "NG=0");
					EndIf;
				EndDo;
			EndDo;
			
			If CheckedRefs.Count() >= MaxCount Then
				CheckedRefs.Clear();
			EndIf;
			
			If IsBlankString(ProblemRecordsNumbers) Then
				Continue;
			EndIf;
			
			Issue1 = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters); // @skip-check query-in-loop - batch check of record keeping
			Issue1.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong biểu ghi tích lũy ""%1"" trong các bản ghi có các số thứ tự %2 theo nguồn ghi ""%3"" đã chỉ ra tham chiếu đến dữ liệu không tồn tại.';
					|ru = 'У регистра накопления ""%1"" в записях с номерами %2 по регистратору ""%3"" указаны ссылки на несуществующие данные.';
					|en = 'Records ""%2"" in recorder ""%3"" for accumulation register ""%1"" reference data that does not exist.'; fa = 'Records ""%2"" in recorder ""%3"" for accumulation register ""%1"" reference data that does not exist.';
					|it = 'Presso il registro di accumulo ""%1"" nelle registrazioni con numeri %2 in base al registratore ""%3"" sono indicati collegamenti a dati inesistenti.';
					|pl = 'Dla rejestru akumulacji ""%1"" we wpisach z numerami %2 według rejestratora ""%3"" są podane odnośniki do nieistniejących danych.';
					|tr = '""%1"" birikim kaydının ""%3"" kaydedicisinde %2 numaralı kayıtlarda var olmayan verilere referans belirtilmiş.'"),
				MetadataObject.Presentation(), ProblemRecordsNumbers, ResultString1.RecorderAttributeRef);
				
			AdditionalInformation = New Structure;
			AdditionalInformation.Insert("Recorder", ResultString1.RecorderAttributeRef);
			Issue1.AdditionalInformation = New ValueStorage(AdditionalInformation, New Deflation(9));
			
			WriteIssue(Issue1, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
			
		EndDo;
		
		Query.SetParameter("CheckStartDate", ResultString1.Period);
		Result = Query.Execute().Unload(); // @skip-check query-in-loop - batch check of record keeping
		
	EndDo;
	
EndProcedure

// Find broken links in the information registers.
// 
// Parameters:
//  MetadataObject - MetadataObjectInformationRegister
//  CheckParameters - See AccountingAudit.IssueDetails 
//  CheckedRefs - Map - cache of links being checked
//
Procedure FindDeadRefsInInformationRegisters(MetadataObject, CheckParameters, CheckedRefs)
	InformationRegisterReferenceFields = InformationRegisterReferenceFields(MetadataObject);
	If Not ValueIsFilled(InformationRegisterReferenceFields) Then
		Return;
	EndIf;
	
	RecordPositionFields = RecordPositionFields(MetadataObject);
	FullName = MetadataObject.FullName();
	MetadataObjectID = Common.MetadataObjectID(FullName);

	RegisterDataSelection = RegisterDataSelection(FullName, CheckParameters, RecordPositionFields);
	While RegisterDataSelection.Next() Do
		For Each Field In InformationRegisterReferenceFields Do
			Simple = RegisterDataSelection[Field.Name];
			If Not IsDeadRef(Simple, CheckedRefs) Then
				Continue;
			EndIf;

			Issue1 = IssueDetails(MetadataObjectID, CheckParameters); // @skip-check query-in-loop

			BrokenRefFieldPresentation = StrTemplate("%1: %2 (%3)", Field.PresentationToDescription, Simple, Simple.Metadata().FullName());
			RecordPositionPresentation = RecordPositionPresentation(RegisterDataSelection, RecordPositionFields);
			
			AdjustmentTemplate = NStr("ru = 'Нарушена ссылочная целостность поля:
			|%1
			|
			|Позиция записи:
			|%2';
			|vi = 'The referential integrity of the field is violated:
			|%1
			|
			|Record position:
			|%2';
			|en = 'The referential integrity of the field is violated:
			|%1
			|
			|Record position:
			|%2'; fa = 'The referential integrity of the field is violated:
			|%1
			|
			|Record position:
			|%2';
			|it = 'The referential integrity of the field is violated:
			|%1
			|
			|Record position:
			|%2';
			|pl = 'The referential integrity of the field is violated:
			|%1
			|
			|Record position:
			|%2';
			|tr = 'Alanın referans bütünlüğü ihlal edildi:
			|%1
			|
			| Kayıt konumu:
			|%2'");

			Issue1.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(AdjustmentTemplate, 
				BrokenRefFieldPresentation, RecordPositionPresentation);
				
			RecordPositionValue = RecordPositionValue(RegisterDataSelection, RecordPositionFields);
			Issue1.AdditionalInformation = New ValueStorage(RecordPositionValue, New Deflation(9));

			WriteIssue(Issue1, CheckParameters); // @skip-check query-in-loop
		EndDo;
	EndDo;
EndProcedure

// Parameters:
//   MetadataObject - MetadataObjectAccountingRegister
//   CheckParameters - See AccountingAudit.IssueDetails
//   ExtDimensionTypes - Array
//   CheckedRefs - Map
//
Procedure FindDeadRefsInAccountingRegisters(MetadataObject, CheckParameters, ExtDimensionTypes, CheckedRefs)
	
	MaxCount = MaxCheckedRefsCount();
	FullName                      = MetadataObject.FullName();
	
	RefAttributes = New Array;
	
	If Not MetadataObject.Correspondence Then
		If MetadataObject.ChartOfAccounts <> Undefined Then
			RefAttributes.Add("Account");
		EndIf;
	Else
		RefAttributes.Add("AccountDr");
		RefAttributes.Add("AccountCr");
	EndIf;
		
	For Each Dimension In MetadataObject.Dimensions Do
		
		If Not ContainsRefType(Dimension) Then
			Continue;
		EndIf;
		
		If Dimension.Balance Or Not MetadataObject.Correspondence Then
			RefAttributes.Add(Dimension.Name);
		Else
			RefAttributes.Add(Dimension.Name + "Dr");
			RefAttributes.Add(Dimension.Name + "Cr");
		EndIf;
		
	EndDo;
	
	For Each Attribute In MetadataObject.Attributes Do
		If Not ContainsRefType(Attribute) Then
			Continue;
		EndIf;
		RefAttributes.Add(Attribute.Name);
	EndDo;
	
	Query = New Query(
	"SELECT
	|	MetadataObject.Recorder AS RecorderAttributeRef,
	|	MetadataObject.Period AS Period
	|FROM
	|	&MetadataObject AS MetadataObject
	|
	|GROUP BY
	|	MetadataObject.Period,
	|	MetadataObject.Recorder
	|
	|ORDER BY
	|	MetadataObject.Period");
	
	Query.Text = StrReplace(Query.Text, "&MetadataObject", FullName + ".RecordsWithExtDimensions(, , Period > &CheckStartDate, , 1000)");
	Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
	Result = Query.Execute().Unload();
	
	RegisterManager = Common.ObjectManagerByFullName(FullName);
	
	While Result.Count() > 0 Do
		
		For Each ResultString1 In Result Do
			
			CurrentRecordSet = RegisterManager.CreateRecordSet(); // AccountingRegisterRecordSet
			CurrentRecordSet.Filter.Recorder.Set(ResultString1.RecorderAttributeRef);
			CurrentRecordSet.Read();
			
			ProblemRecordsNumbers = "";
			For Each CurrentRecord In CurrentRecordSet Do
				
				ObjectsToCheck = New Array;
				
				For Each ExtDimensionType In ExtDimensionTypes Do
					If Not MetadataObject.Correspondence Then
						ObjectsToCheck.Add(CurrentRecord.ExtDimensions[ExtDimensionType]);
					Else
						ObjectsToCheck.Add(CurrentRecord.ExtDimensionsDr[ExtDimensionType]);
						ObjectsToCheck.Add(CurrentRecord.ExtDimensionsCr[ExtDimensionType]);
					EndIf;
				EndDo;
				
				For Each AttributeName In RefAttributes Do
					ObjectsToCheck.Add(CurrentRecord[AttributeName]);
				EndDo;
				
				For Each ObjectToCheck In ObjectsToCheck Do
					If IsDeadRef(ObjectToCheck, CheckedRefs) Then
						ProblemRecordsNumbers = ProblemRecordsNumbers + ?(ValueIsFilled(ProblemRecordsNumbers), ", ", "")
							+ Format(CurrentRecordSet.IndexOf(CurrentRecord) + 1, "NG=0");
					EndIf;	
				EndDo;
				
			EndDo;
			
			If CheckedRefs.Count() >= MaxCount Then
				CheckedRefs.Clear();
			EndIf;
			
			If IsBlankString(ProblemRecordsNumbers) Then
				Continue;
			EndIf;
			
			Issue1 = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters); // @skip-check query-in-loop - batch check of record keeping
			Issue1.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong biểu ghi kế toán ""%1"" trong các bản ghi có các số thứ tự %2 theo nguồn ghi ""%3"" đã chỉ ra tham chiếu đến đối tượng không tồn tại.';
					|ru = 'У регистра бухгалтерии ""%1"" в записях с номерами %2 по регистратору ""%3"" указаны ссылки на несуществующие данные.';
					|en = 'Records ""%2"" in recorder ""%3"" for accounting register ""%1"" reference data that does not exist.'; fa = 'Records ""%2"" in recorder ""%3"" for accounting register ""%1"" reference data that does not exist.';
					|it = 'Presso il registro di contabilità ""%1"" nelle registrazioni con numeri %2 in base al registratore ""%3"" sono indicati collegamenti a dati inesistenti.';
					|pl = 'Dla rejestru księgowości ""%1"" we wpisach z numerami %2 według rejestratora ""%3"" są podane odnośniki do nieistniejących danych.';
					|tr = '""%1"" muhasebe kaydının ""%3"" kaydedicisinde %2 numaralı kayıtlarda var olmayan verilere referans belirtilmiş.'"),
				MetadataObject.Presentation(), ProblemRecordsNumbers, ResultString1.RecorderAttributeRef);
				
			AdditionalInformation = New Structure;
			AdditionalInformation.Insert("Recorder", ResultString1.RecorderAttributeRef);
			Issue1.AdditionalInformation = New ValueStorage(AdditionalInformation, New Deflation(9));
			
			WriteIssue(Issue1, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
			
		EndDo;
		
		Query.SetParameter("CheckStartDate", ResultString1.Period);
		Result = Query.Execute().Unload(); // @skip-check query-in-loop - batch check of record keeping
		
	EndDo;
	
EndProcedure

// Parameters:
//   MetadataObject - MetadataObjectCalculationRegister
//   CheckParameters - See AccountingAudit.IssueDetails
//   CheckedRefs - Map
//
Procedure FindDeadRefsInCalculationRegisters(MetadataObject, CheckParameters, CheckedRefs)
	
	MaxCount = MaxCheckedRefsCount();
	FullName         = MetadataObject.FullName();
	RegisterAttributes1 = RegisterRefAttributes(MetadataObject);
	
	Query = New Query(
	"SELECT TOP 1000
	|	MetadataObject.Recorder AS RecorderAttributeRef,
	|	MetadataObject.RegistrationPeriod AS Period
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	MetadataObject.RegistrationPeriod > &CheckStartDate
	|
	|GROUP BY
	|	MetadataObject.RegistrationPeriod,
	|	MetadataObject.Recorder
	|
	|ORDER BY
	|	MetadataObject.RegistrationPeriod");
	
	Query.Text = StrReplace(Query.Text, "&MetadataObject", FullName);
	Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
	Result = Query.Execute().Unload();
	
	RegisterManager = Common.ObjectManagerByFullName(FullName);
	
	While Result.Count() > 0 Do
		
		For Each ResultString1 In Result Do
			
			CurrentRecordSet = RegisterManager.CreateRecordSet(); // CalculationRegisterRecordSet
			CurrentRecordSet.Filter.Recorder.Set(ResultString1.RecorderAttributeRef);
			CurrentRecordSet.Read();
			
			ProblemRecordsNumbers = "";
			For Each CurrentRecord In CurrentRecordSet Do
				For Each AttributeName In RegisterAttributes1 Do
					CurrentRef = CurrentRecord[AttributeName];
					If IsDeadRef(CurrentRef, CheckedRefs) Then
						ProblemRecordsNumbers = ProblemRecordsNumbers + ?(ValueIsFilled(ProblemRecordsNumbers), ", ", "")
							+ Format(CurrentRecordSet.IndexOf(CurrentRecord) + 1, "NG=0");
					EndIf;	
				EndDo;
			EndDo;
			
			If CheckedRefs.Count() >= MaxCount Then
				CheckedRefs.Clear();
			EndIf;
			
			If IsBlankString(ProblemRecordsNumbers) Then
				Continue;
			EndIf;
			
			Issue1 = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters); // @skip-check query-in-loop - batch check of record keeping
			
			Issue1.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong biểu ghi tính toán ""%1"" trong các bản ghi có các số thứ tự %2 theo nguồn ghi ""%3"" đã chỉ ra tham chiếu đến dữ liệu không tồn tại.';
					|ru = 'У регистра расчета ""%1"" в записях с номерами %2 по регистратору ""%3"" указаны ссылки на несуществующие данные.';
					|en = 'Records ""%2"" in recorder ""%3"" for calculation register ""%1"" reference data that does not exist.'; fa = 'Records ""%2"" in recorder ""%3"" for calculation register ""%1"" reference data that does not exist.';
					|it = 'Presso il registro di calcolo ""%1"" nelle registrazioni con numeri %2 in base al registratore ""%3"" sono indicati collegamenti a dati inesistenti.';
					|pl = 'Dla rejestru rozliczenia ""%1"" we wpisach z numerami %2 według rejestratora ""%3"" są podane odnośniki do nieistniejących danych.';
					|tr = '""%1"" hesaplama kaydının ""%3"" kaydedicisinde %2 numaralı kayıtlarda var olmayan verilere referans belirtilmiş.'"),
				MetadataObject.Presentation(), ProblemRecordsNumbers, ResultString1.RecorderAttributeRef);
				
			AdditionalInformation = New Structure;
			AdditionalInformation.Insert("Recorder", ResultString1.RecorderAttributeRef);
			Issue1.AdditionalInformation = New ValueStorage(AdditionalInformation, New Deflation(9));
			
			WriteIssue(Issue1, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
			
		EndDo;
		
		Query.SetParameter("CheckStartDate", ResultString1.Period);
		Result = Query.Execute().Unload(); // @skip-check query-in-loop - batch check of record keeping
		
	EndDo;
	
EndProcedure

Function RegisterRefAttributes(MetadataObject)
	
	Dimensions = MetadataObject.Dimensions;
	Attributes = MetadataObject.Attributes;
	
	Result = New Array;
	
	For Each Attribute In Attributes Do
		If ContainsRefType(Attribute) Then
			Result.Add(Attribute.Name);
		EndIf;
	EndDo;
	
	If Common.IsCalculationRegister(MetadataObject) Then
		
		For Each Dimension In Dimensions Do
			If ContainsRefType(Dimension) Then
				Result.Add(Dimension.Name);
			EndIf;
		EndDo;
		
		StandardAttributes = MetadataObject.StandardAttributes;
		For Each StandardAttribute In StandardAttributes Do
			If StandardAttribute.Name = "Recorder" Or Not ContainsRefType(StandardAttribute) Then
				Continue;
			EndIf;
			Result.Add(StandardAttribute.Name);
		EndDo;
		
	ElsIf Common.IsInformationRegister(MetadataObject) Or Common.IsAccumulationRegister(MetadataObject) Then
		
		For Each Dimension In Dimensions Do
			If ContainsRefType(Dimension) Then
				Result.Add(Dimension.Name);
			EndIf;
		EndDo;
		
		Resources = MetadataObject.Resources;
		For Each Resource In Resources Do
			If ContainsRefType(Resource) Then
				Result.Add(Resource.Name);
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ContainsRefType(Attribute)
	
	AttributeTypes = Attribute.Type.Types();
	For Each Current_Type In AttributeTypes Do
		If Common.IsReference(Current_Type) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ExtDimensionTypes(MetadataObject)
	
	If MetadataObject.ChartOfAccounts = Undefined Then
		Return New Array;
	EndIf;
	
	ExtDimensionTypesMetadataObject = MetadataObject.ChartOfAccounts.ExtDimensionTypes;
	If ExtDimensionTypesMetadataObject = Undefined Or Not ContainsRefType(ExtDimensionTypesMetadataObject) Then
		Return New Array;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	Table.Ref AS ExtDimensionType
	|FROM
	|	&ChartOfCharacteristicTypes AS Table");
	
	Query.Text = StrReplace(Query.Text, "&ChartOfCharacteristicTypes", MetadataObject.ChartOfAccounts.ExtDimensionTypes.FullName());
	Return Query.Execute().Unload().UnloadColumn("ExtDimensionType");
	
EndFunction

#EndRegion

#EndRegion

#Region CheckRequiredAttributesFilling

// Parameters:
//   MetadataObject - Arbitrary
//   CheckParameters - See AccountingAudit.IssueDetails
//
Procedure FindNotFilledRequiredAttributes(MetadataObject, CheckParameters)
	
	ModulePerformanceMonitor = Undefined;
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
	EndIf;
	
	FullName = MetadataObject.FullName();
	Attributes = MetadataObject.Attributes;
	
	Query = New Query;
	Query.SetParameter("Ref", "");
	
	QueryText = 
	"SELECT TOP 1000
	|	SpecifiedTableAlias.Ref AS ObjectWithIssue
	|FROM
	|	&MetadataObject AS SpecifiedTableAlias
	|WHERE
	|	&Condition
	|	AND NOT SpecifiedTableAlias.DeletionMark
	|
	|ORDER BY
	|	SpecifiedTableAlias.Ref";
	
	TableName = StrReplace(FullName, ".", "");
	If CheckParameters.Property("ObjectsToCheck") And CheckParameters.ObjectsToCheck <> Undefined Then
		Condition = TableName + ".Ref IN (&Ref)";
		Query.SetParameter("Ref", CheckParameters.ObjectsToCheck);
	Else
		Condition = TableName + ".Ref > &Ref";
		Query.SetParameter("Ref", "");
	EndIf;
	
	QueryText = StrReplace(QueryText, "SpecifiedTableAlias", TableName);
	QueryText = StrReplace(QueryText, "&Condition", Condition);
	QueryText = StrReplace(QueryText, "&MetadataObject", FullName);
	
	Query.Text = QueryText;
	Result = Query.Execute().Unload();
	
	DataCountTotal = 0;
	RestrictionByDate     = CheckParameters.CheckStartDate;
	While Result.Count() > 0 Do
		
		If ModulePerformanceMonitor <> Undefined Then
			MeasurementDetails = ModulePerformanceMonitor.StartTimeConsumingOperationMeasurement(CheckParameters.Id + "." + FullName);
		EndIf;
		
		For Each ResultString1 In Result Do
			
			ObjectReference = ResultString1.ObjectWithIssue;
			
			If ValueIsFilled(RestrictionByDate)
				And Common.IsDocument(MetadataObject)
				And Common.ObjectAttributeValue(ObjectReference, "Date") < RestrictionByDate Then
				Continue;
			EndIf;
			
			If Common.IsDocument(MetadataObject) And Not Common.ObjectAttributeValue(ObjectReference, "Posted") Then
				Continue;
			EndIf;
			
			If Common.IsExchangePlan(MetadataObject) And ObjectReference.ThisNode Then
				Continue;
			EndIf;
			
			ObjectToCheck = ObjectReference.GetObject();
			If ObjectToCheck.CheckFilling() Then
				Continue;
			EndIf;
			
			Issue1 = IssueDetails(ObjectReference, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
			
			Issue1.IssueSummary = NStr("vi = 'Chưa điền mục tin mà bắt buộc điền:';
										|ru = 'Не заполнены реквизиты, обязательные к заполнению:';
										|en = 'Attributes required:'; fa = 'Attributes required:';
										|it = 'Non sono compilati gli attributi richiesti:';
										|pl = 'Nie wypełniono atrybutów, wymaganych do wypełnienia:';
										|tr = 'Doldurulması gereken öznitelikler doldurulmadı:'") + Chars.LF + ObjectFillingErrors();
			If Attributes.Find("EmployeeResponsible") <> Undefined Then
				Issue1.Insert("EmployeeResponsible", Common.ObjectAttributeValue(ObjectReference, "EmployeeResponsible"));
			EndIf;
			
			WriteIssue(Issue1, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
			
		EndDo;
		
		DataCountTotal = DataCountTotal + Result.Count();
		If ModulePerformanceMonitor <> Undefined Then
			ModulePerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataCountTotal);
		EndIf;
		
		If CheckParameters.Property("ObjectsToCheck") And CheckParameters.ObjectsToCheck <> Undefined Then
			Break;
		EndIf;
		
		Query.SetParameter("Ref", ResultString1.ObjectWithIssue);
		Result = Query.Execute().Unload(); // @skip-check query-in-loop - batch check of record keeping
		
	EndDo;
	
EndProcedure

Procedure FindNotFilledRequiredAttributesInRegisters(MetadataObject, CheckParameters)
	FullName = MetadataObject.FullName();
	If StrStartsWith(FullName, "Delete") Then
		Return;
	EndIf;
	RecordPositionFields = RecordPositionFields(MetadataObject);
	If Not ValueIsFilled(RecordPositionFields) Then
		Return;
	EndIf;
	FieldsOfRequiredAttributes = FieldsOfRequiredAttributes(MetadataObject);
	If Not ValueIsFilled(FieldsOfRequiredAttributes) Then
		Return;
	EndIf;
	
	MetadataObjectID = Common.MetadataObjectID(FullName);
	RegisterDataSelection = RegisterDataSelection(FullName, CheckParameters, RecordPositionFields);
	While RegisterDataSelection.Next() Do
		EmptyAttributes = New Array();
		For Each Field In FieldsOfRequiredAttributes Do
			Simple = RegisterDataSelection[Field.Name];
			If Not ValueIsFilled(Simple) Then
				EmptyAttributes.Add(Field.PresentationToDescription);
			EndIf;
		EndDo;
		If Not ValueIsFilled(EmptyAttributes) Then
			Continue;
		EndIf;
		
		Issue1 = IssueDetails(MetadataObjectID, CheckParameters); // @skip-check query-in-loop
		RecordPositionPresentation = RecordPositionPresentation(RegisterDataSelection, RecordPositionFields);

		Template = NStr("ru = 'У записи с полями:
			|%1
			|
			|обнаружены незаполненные данные, обязательные к заполнению:
			|%2';
			|vi = 'Error in record with the following fields:
			|%1
			|
			|Some values are required:
			|%2';
			|en = 'Error in record with the following fields:
			|%1
			|
			|Some values are required:
			|%2'; fa = 'Error in record with the following fields:
			|%1
			|
			|Some values are required:
			|%2';
			|it = 'Error in record with the following fields:
			|%1
			|
			|Some values are required:
			|%2';
			|pl = 'Error in record with the following fields:
			|%1
			|
			|Some values are required:
			|%2';
			|tr = 'Alanları: 
			|%1
			|
			|olan kayıtta, doldurulması zorunlu boş veriler tespit edildi:
			|%2'");
		Issue1.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(Template,
			RecordPositionPresentation, StrConcat(EmptyAttributes, Chars.LF));
		
		RecordPositionValue = RecordPositionValue(RegisterDataSelection, RecordPositionFields);
		Issue1.AdditionalInformation = New ValueStorage(RecordPositionValue, New Deflation(9));
		WriteIssue(Issue1, CheckParameters); // @skip-check query-in-loop
	EndDo;
EndProcedure

#EndRegion

#Region CheckCircularRefs1

Procedure FindCircularRefs(MetadataObject, CheckParameters)
	
	FullName = MetadataObject.FullName();
	Attributes = MetadataObject.Attributes;
	
	QueryText = 
	"SELECT TOP 1000
	|	SpecifiedTableAlias.Ref AS ObjectWithIssue,
	|	REFPRESENTATION(SpecifiedTableAlias.Ref) AS Presentation,
	|	SpecifiedTableAlias.Parent AS Parent
	|FROM
	|	&MetadataObject AS SpecifiedTableAlias
	|WHERE
	|	SpecifiedTableAlias.Ref > &Ref
	|
	|ORDER BY
	|	SpecifiedTableAlias.Ref";
	
	TableName = StrReplace(MetadataObject.FullName(), ".", "");
	QueryText = StrReplace(QueryText, "SpecifiedTableAlias", TableName);
	QueryText = StrReplace(QueryText, "&MetadataObject", FullName);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", "");
	
	Result = Query.Execute().Unload();
	
	CheckedItems = New Map;
	While Result.Count() > 0 Do
		
		For Each ResultString1 In Result Do
			
			ObjectReference = ResultString1.ObjectWithIssue;
			If CheckedItems[ObjectReference] <> Undefined Then
				Continue;
			EndIf;
			
			ItemsToCheck = New Array;
			If CheckLevelsLooping(ObjectReference, ResultString1.Parent, ItemsToCheck) Then
				
				Path = "";
				For Each LoopItem In ItemsToCheck Do
					Path = Path + ?(ValueIsFilled(Path), " -> ", "") + String(LoopItem);
					CheckedItems[LoopItem] = True;
				EndDo;
				
				ObjectPresentation = ResultString1.Presentation;
				If ValueIsFilled(Path) Then
					IssueSummary = ObjectPresentation + " -> " + Path + " -> " + ObjectPresentation;
				Else
					IssueSummary = ObjectPresentation + " -> " + ObjectPresentation;
				EndIf;
				
				Issue1 = IssueDetails(ObjectReference, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
				
				Issue1.IssueSummary = IssueSummary;
				If Attributes.Find("EmployeeResponsible") <> Undefined Then
					Issue1.Insert("EmployeeResponsible", Common.ObjectAttributeValue(ObjectReference, "EmployeeResponsible"));
				EndIf;
				
				WriteIssue(Issue1, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
				
			EndIf;
			
		EndDo;
		
		Query.SetParameter("Ref", ResultString1.ObjectWithIssue);
		Result = Query.Execute().Unload(); // @skip-check query-in-loop - batch check of record keeping
		
	EndDo;
	
EndProcedure

Function CheckLevelsLooping(Val ObjectReference, Val CurrentParent, Val AllItems)
	
	While ValueIsFilled(CurrentParent) Do
		If ObjectReference = CurrentParent Then
			Return True;
		EndIf;
		AllItems.Add(CurrentParent);
		CurrentParent = Common.ObjectAttributeValue(CurrentParent, "Parent");
	EndDo;
	Return False;
	
EndFunction

// Parameters:
//   StandardAttributes - StandardAttributeDescriptions
// Returns:
//   Boolean
//
Function HasHierarchy(StandardAttributes)
	
	HasHierarchy = False;
	For Each StandardAttribute In StandardAttributes Do
		If StandardAttribute.Name = "Parent" Then
			HasHierarchy = True;
			Break;
		EndIf;
	EndDo;
	
	Return HasHierarchy;
	
EndFunction

// Corrects circular references as follows: the one that has more terminal subordinate items 
// remains a parent.
//
// Parameters:
//   Validation - CatalogRef.AccountingCheckRules - a check, whose found issues are corrected
//              using this method.
//
Procedure CorrectCircularRefsProblem(Validation)
	
	DescendantsTable = New ValueTable;
	DescendantsTable.Columns.Add("LoopItem");
	DescendantsTable.Columns.Add("ChildrenCount", New TypeDescription("Number"));
	
	Query = New Query(
	"SELECT
	|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
	|	VALUETYPE(AccountingCheckResults.ObjectWithIssue) AS RefType
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	NOT AccountingCheckResults.IgnoreIssue
	|	AND AccountingCheckResults.CheckRule = &CheckRule
	|TOTALS BY
	|	RefType");
	
	Query.SetParameter("CheckRule", Validation);
	Result = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	For Each ObjectTypeString In Result.Rows Do
		FullTableName = Metadata.FindByType(ObjectTypeString.RefType).FullName();
		For Each StringObject In ObjectTypeString.Rows Do
			BeginTransaction();
			Try
				Block = New DataLock;
				LockItem = Block.Add(FullTableName);
				LockItem.SetValue("Ref", StringObject.ObjectWithIssue);
				Block.Lock();
				
				ProblemObjectRef = StringObject.ObjectWithIssue;
				Parent = Common.ObjectAttributeValue(ProblemObjectRef, "Parent");
				
				ItemsToCheck = New Array;
				If Not CheckLevelsLooping(ProblemObjectRef, Parent, ItemsToCheck) Then
					RollbackTransaction();
					Continue;
				EndIf;
					
				LoopLastObject = ItemsToCheck[ItemsToCheck.Count() - 1];
				
				FirstLoopChildrenCount = ChildItemsCount(ProblemObjectRef, Parent); // @skip-check query-in-loop - batch check of record keeping
				SecondLoopChildrenCount = ChildItemsCount(LoopLastObject, Parent); // @skip-check query-in-loop - batch check of record keeping
				
				ObjectWithIssue = ?(FirstLoopChildrenCount > SecondLoopChildrenCount, ProblemObjectRef, LoopLastObject);
				ObjectWithIssue = ObjectWithIssue.GetObject();
				ObjectWithIssue.Parent = Common.ObjectManagerByFullName(ProblemObjectRef.Metadata().FullName()).EmptyRef();
				ObjectWithIssue.DataExchange.Load = True;
				ObjectWithIssue.Write();
				
				CommitTransaction();
			Except
				RollbackTransaction();
				Raise;
			EndTry;
		EndDo;
	EndDo;
	
EndProcedure

Function ChildItemsCount(ObjectReference, SelectionExclusion, Val InitialValue = 0)
	
	ChildrenCount = InitialValue;
	
	Upload0 = SubordinateParentItems(ObjectReference, SelectionExclusion);
	ChildrenCount = ChildrenCount + Upload0.Count();
	For Each DescendantItem In Upload0 Do
		ChildrenCount = ChildItemsCount(DescendantItem.Ref, SelectionExclusion, ChildrenCount); // @skip-check query-in-loop - batch check of record keeping
	EndDo;
	Return ChildrenCount;
	
EndFunction

// Returns:
//   ValueTable:
//   * Ref - AnyRef
//
Function SubordinateParentItems(ObjectReference, Val SelectionExclusion)

	QueryText =
	"SELECT
	|	SpecifiedTableAlias.Ref AS Ref
	|FROM
	|	&MetadataObject AS SpecifiedTableAlias
	|WHERE
	|	SpecifiedTableAlias.Parent = &Parent
	|	AND SpecifiedTableAlias.Ref <> &SelectionExclusion";
	
	FullName = ObjectReference.Metadata().FullName();
	TableName = StrReplace(FullName, ".", "");
	QueryText = StrReplace(QueryText, "SpecifiedTableAlias", TableName);
	QueryText = StrReplace(QueryText, "&MetadataObject", FullName);
	
	Query = New Query(QueryText);
	Query.SetParameter("Parent",          ObjectReference);
	Query.SetParameter("SelectionExclusion", SelectionExclusion);
	Return Query.Execute().Unload();

EndFunction

#EndRegion

#Region CheckNoPredefinedItems

Procedure FindMissingPredefinedItems(MetadataObject, CheckParameters)
	
	FullName                = MetadataObject.FullName();
	PredefinedItems = MetadataObject.GetPredefinedNames();
	For Each PredefinedItem In PredefinedItems Do
		
		If StrStartsWith(Upper(PredefinedItem), "DELETE") Then
			Continue;
		EndIf;
		
		FoundItem = Common.PredefinedItem(FullName + "." + PredefinedItem);
		If FoundItem <> Undefined Then
			Continue;
		EndIf;
			
		Issue1 = IssueDetails(Common.MetadataObjectID(MetadataObject), CheckParameters); // @skip-check query-in-loop - batch check of record keeping
		Issue1.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Phần tử định trước ""%1"" không có trong cơ sở thông tin.';
																							|ru = 'Предопределенный элемент ""%1"" отсутствует в информационной базе.';
																							|en = 'Predefined item ""%1"" missing in information database.'; fa = 'Predefined item ""%1"" missing in information database.';
																							|it = 'L''elemento predefinito ""%1"" manca nell''infobase.';
																							|pl = 'Brak predefiniowanego elementu ""%1"" w bazie informacyjnej.';
																							|tr = '""%1"" önceden tanımlanmış öğesi Infobase''de mevcut değiş.'"), PredefinedItem);
		WriteIssue(Issue1, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
		
	EndDo;
	
EndProcedure

#EndRegion

#Region CheckDuplicatePredefinedItems1

Procedure FindPredefinedItemsDuplicates(MetadataKind, CheckParameters)
	
	TemporaryTableTemplate =
	"SELECT
	|	""&Table"" AS FullName,
	|	Table.PredefinedDataName AS PredefinedDataName 
	|INTO
	|#TempTable
	|FROM
	|	&Table AS Table
	|WHERE Table.Predefined
	|
	|GROUP BY
	|	Table.PredefinedDataName
	|
	|HAVING
	|	COUNT(DISTINCT Table.Ref) > 1";
	
	SelectionTemplate1 =
	"SELECT
	|	&ObjectWithIssue AS ObjectWithIssue, 
	|	TempTable.PredefinedDataName AS PredefinedDataName,
	|	REFPRESENTATION(Table.Ref) AS DuplicateItemRef
	|FROM
	|	&Table AS Table
	|		INNER JOIN #TempTable AS TempTable
	|		ON Table.PredefinedDataName = TempTable.PredefinedDataName";
	
	SelectionTotals = "
	|TOTALS BY ObjectWithIssue, PredefinedDataName"; // @query-part-1
	
	TemporaryTableText = "";
	SelectionText = "";
	
	Query = New Query;
	Iterator_SSLy = 0;
	QueriesArray = New Array;
	For Each MetadataObject In MetadataKind Do
		
		Iterator_SSLy = Iterator_SSLy + 1;
		
		TableName = MetadataObject.FullName();
		If IsSharedMetadataObject(TableName) Then
			Continue;
		EndIf;
		
		If StrStartsWith(MetadataObject.Name, "Delete") Then
			Continue;
		EndIf;
		
		If MetadataObject.PredefinedDataUpdate = Metadata.ObjectProperties.PredefinedDataUpdate.DontAutoUpdate Then
			Continue;
		EndIf;
		
		TempTableName = "TT_" + StrReplace(TableName, ".", "");
		
		QueryText = StrReplace(TemporaryTableTemplate, "#TempTable", TempTableName);
		QueryText = StrReplace(QueryText, "&Table", TableName);
		TemporaryTableText = TemporaryTableText + ?(ValueIsFilled(TemporaryTableText), ";", "") + QueryText;
		
		ParameterSuffix = StrReplace(TableName, ".", "_");
		ParameterName = "&ObjectWithIssue" + ParameterSuffix;
		QueryText = StrReplace(SelectionTemplate1, "&ObjectWithIssue",	ParameterName);
		QueryText = StrReplace(QueryText, "&Table", TableName);
		QueryText = StrReplace(QueryText, "#TempTable", TempTableName);
		SelectionText = SelectionText + ?(ValueIsFilled(SelectionText), " UNION ALL ", "") + QueryText;
		Query.SetParameter("ObjectWithIssue" + ParameterSuffix, Common.MetadataObjectID(TableName));
		
		If Iterator_SSLy = 100 Then
			// 100 tables are filtered to avoid overly complex queries.
			Query.Text = TemporaryTableText + ";" + SelectionText + SelectionTotals;
			IntermediateQuery = Query;
			QueriesArray.Add(IntermediateQuery);
			
			Query                = New Query;
			TemporaryTableText = "";
			SelectionText          = "";
			Iterator_SSLy              = 0;
		EndIf;
		
	EndDo;
	
	If Not ValueIsFilled(TemporaryTableText) And QueriesArray.Count() = 0 Then
		Return;
	EndIf;
	
	If ValueIsFilled(TemporaryTableText) Then
		Query.Text = TemporaryTableText + ";" + SelectionText + SelectionTotals;
		QueriesArray.Add(Query);
	EndIf;
	
	For Each Query In QueriesArray Do
		Result = Query.Execute().Select(QueryResultIteration.ByGroups);
		While Result.Next() Do
			
			IssueSummary = "";
			ResultByPredefinedItemName = Result.Select(QueryResultIteration.ByGroups);
			
			While ResultByPredefinedItemName.Next() Do
				
				PredefinedDataName = ResultByPredefinedItemName.PredefinedDataName;
				If StrStartsWith(Upper(PredefinedDataName), "DELETE") Then
					Continue;
				EndIf;
				
				IssueSummary = IssueSummary + ?(ValueIsFilled(IssueSummary), Chars.LF, "")
					+ NStr("vi = 'Tên phần tử định trước:';
							|ru = 'Имя предопределенного элемента:';
							|en = 'Name of the predefined item:'; fa = 'Name of the predefined item:';
							|it = 'Nome dell''elemento predefinito:';
							|pl = 'Nazwa predefiniowanego elementu:';
							|tr = 'Önceden tanımlanmış öğenin adı:'") + " """ + PredefinedDataName + """"
					+ Chars.LF + NStr("vi = 'Tham chiếu đến phần tử định trước:';
										|ru = 'Ссылки на предопределенный элемент:';
										|en = 'References to the predefined item:'; fa = 'References to the predefined item:';
										|it = 'Collegamenti all''elemento predefinito:';
										|pl = 'Odnośniki do predefiniowanego elementu:';
										|tr = 'Önceden tanımlanmış öğe URL:'");
					
				DetailedRecords = ResultByPredefinedItemName.Select();
				While DetailedRecords.Next() Do
					IssueSummary = IssueSummary + ?(ValueIsFilled(IssueSummary), Chars.LF, "")
						+ " • """ + DetailedRecords.DuplicateItemRef + """";
				EndDo;
				
			EndDo;
			
			If Not ValueIsFilled(IssueSummary) Then
				Continue;
			EndIf;
			
			Issue1 = IssueDetails(Result.ObjectWithIssue, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
			Issue1.IssueSummary = IssueSummary;
			WriteIssue(Issue1, CheckParameters); // @skip-check query-in-loop - batch check of record keeping
			
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function ReadParameters(CheckExecutionParameters)
	Result = New Structure("FullName, MetadataObject, ValidationArea");
	If CheckExecutionParameters.Count() <> 1 Then
		Return Undefined;
	EndIf;
	
	ParametersStructure = CheckExecutionParameters[0];
	If TypeOf(ParametersStructure) <> Type("Structure") Then
		Return Undefined;
	EndIf;
	
	If ParametersStructure.Property1 <> "ObjectToCheck" Then
		Return Undefined;
	EndIf;
	
	Result.FullName = ParametersStructure.Property2;
	If StandardSubsystemsServer.IsRegisterTable(Result.FullName) Then
		Result.ValidationArea = "Registers";
	Else
		Result.ValidationArea = "RefObjects";
	EndIf;
	Result.MetadataObject = Common.MetadataObjectByFullName(Result.FullName);
	
	Return Result;
EndFunction

Function ObjectWithIssuePresentation(ObjectWithIssue, ObjectWithIssuePresentation, AdditionalInformation) Export
	
	Result = ObjectWithIssuePresentation + " (" + ObjectWithIssue.Metadata().Presentation() + ")";
	If TypeOf(ObjectWithIssue) <> Type("CatalogRef.MetadataObjectIDs") Then
		Return Result;
	EndIf;
	
	Result = String(ObjectWithIssue) + "<DetailsList>" + Chars.LF + ObjectWithIssue.FullName;
	If Not Common.IsRegister(Common.MetadataObjectByFullName(ObjectWithIssue.FullName)) Then
		Return Result;
	EndIf;
		
	SetStructure  = AdditionalInformation.Get();
	If TypeOf(SetStructure) <> Type("Structure") Then
		Return Result;
	EndIf;
	
	For Each Set_Item In SetStructure Do
		
		FilterValue    = Set_Item.Value;
		ValueTypeFilter = TypeOf(FilterValue);
		TypeInformation   = "";
		
		If ValueTypeFilter = Type("Number") Then
			TypeInformation = "Number";
		ElsIf ValueTypeFilter = Type("String") Then
			TypeInformation = "String";
		ElsIf ValueTypeFilter = Type("Boolean") Then
			TypeInformation = "Boolean";
		ElsIf ValueTypeFilter = Type("Date") Then
			TypeInformation = "Date";
		ElsIf Common.IsReference(ValueTypeFilter) Then
			TypeInformation = FilterValue.Metadata().FullName();
		EndIf;
		
		Result = Result + Chars.LF + String(Set_Item.Key) + "~~~" + TypeInformation + "~~~" + String(XMLString(FilterValue));
		
	EndDo;
	
	Return Result;
	
EndFunction

Function DetailsCell(Ref, CheckRule, CheckKind, IssueSummary, UniqueKey) Export
	If Not Common.IsReference(TypeOf(Ref)) Then
		Return "";
	EndIf;
	
	Details = Ref.Metadata().FullName() + ";"
		+ Ref.UUID() + ";"
		+ CheckRule.UUID() + ";"
		+ CheckKind.UUID() + ";"
		+ IssueSummary + ";"
		+ UniqueKey;
	
	Return Details;
EndFunction

// See AccountingAudit.SubsystemAvailable.
Function SubsystemAvailable() Export
	
	Return AccessRight("View", Metadata.InformationRegisters.AccountingCheckResults);
	
EndFunction

Function IsSharedMetadataObject(FullName)
	
	If Not Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		Return Not ModuleSaaSOperations.IsSeparatedMetadataObject(FullName);
		
	EndIf;
	
	Return False;
	
EndFunction

Procedure FillPictureIndex(Rows, ListLine, RowKey, IndicatorColumn, ObjectsWithIssues) Export
	
	If Not ListLine.Data.Property(IndicatorColumn) Then
		Return;
	EndIf;
	
	CellText = ListLine.Appearance.Get(IndicatorColumn).FindParameterValue(New DataCompositionParameter("Text"));
	
	FoundRow = ObjectsWithIssues.Find(RowKey, "ObjectWithIssue");
	If FoundRow = Undefined Then
		ListLine.Data[IndicatorColumn] = 0;
		If CellText <> Undefined Then
			CellText.Value = 0;
		EndIf;
	Else
		If FoundRow.IssueOrder = 0
			Or FoundRow.IssueOrder = 1 Then
			ListLine.Data[IndicatorColumn] = 1
		ElsIf FoundRow.IssueOrder = 2
			Or FoundRow.IssueOrder = 3 Then
			ListLine.Data[IndicatorColumn] = 2
		ElsIf FoundRow.IssueOrder = 4 Then
			ListLine.Data[IndicatorColumn] = 3
		Else
			ListLine.Data[IndicatorColumn] = 1
		EndIf;
		
		If CellText <> Undefined Then
			CellText.Value = 1;
		EndIf;
	EndIf;
	
EndProcedure

Function ObjectFillingErrors()
	VerificationMessages = GetUserMessages(True);
	If ValueIsFilled(VerificationMessages) Then
		Texts = New Array();
		For Each VerificationMessage In VerificationMessages Do
			Texts.Add(VerificationMessage.Text);
		EndDo;
		Result = StrConcat(Texts, Chars.LF);
	Else
		Result = NStr("ru = 'Для подробной информации откройте форму объекта.';
						|vi = 'For more information, open the object form.';
						|en = 'For more information, open the object form.'; fa = 'For more information, open the object form.';
						|it = 'For more information, open the object form.';
						|pl = 'For more information, open the object form.';
						|tr = 'Ayrıntılı bilgi için nesne formunu açın.'");
	EndIf;
	Return Result;
EndFunction

Function CheckRunning(ScheduledJobID)
	
	Result = False;
	If ValueIsFilled(ScheduledJobID) Then
		Job = BackgroundJobs.FindByUUID(New UUID(ScheduledJobID));
		If Job <> Undefined And Job.State = BackgroundJobState.Active Then
			Result = True;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// See AccountingAudit.ClearPreviousCheckResults.
Procedure ClearPreviousCheckResults(Validation, CheckExecutionParameters) Export
	
	For Each CheckExecutionParameter In CheckExecutionParameters Do
		
		CheckKind = CheckKind(CheckExecutionParameter, True); // @skip-check query-in-loop - batch check of record keeping
		If Not ValueIsFilled(CheckKind) Then
			Continue;
		EndIf;

		Set = InformationRegisters.AccountingCheckResults.CreateRecordSet();
		Set.Filter.CheckRule.Set(Validation);
		Set.Filter.CheckKind.Set(CheckKind);
		Set.Filter.IgnoreIssue.Set(False);
		Set.Write();
		
	EndDo;
	
EndProcedure

Procedure ClearResultsBeforeExecuteCheck(Validation)
	Set = InformationRegisters.AccountingCheckResults.CreateRecordSet();
	Set.Filter.CheckRule.Set(Validation);
	Set.Filter.IgnoreIssue.Set(False);
	Set.Write();
EndProcedure

Function LastObjectCheckResult(CheckExecutionParameters)
	Query = New Query;
	Query.SetParameter("CheckRule", CheckExecutionParameters.Validation);
	Query.SetParameter("ObjectsWithIssues", CheckExecutionParameters.ObjectsToCheck);
	Query.Text =
		"SELECT
		|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
		|	AccountingCheckResults.CheckRule AS CheckRule,
		|	AccountingCheckResults.CheckKind AS CheckKind,
		|	AccountingCheckResults.UniqueKey AS UniqueKey,
		|	AccountingCheckResults.IgnoreIssue AS IgnoreIssue
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.CheckRule = &CheckRule
		|	AND AccountingCheckResults.ObjectWithIssue IN (&ObjectsWithIssues)
		|	AND AccountingCheckResults.IgnoreIssue = FALSE";
	
	Return Query.Execute().Unload();
EndFunction

Procedure DeleteLastCheckResults(LastCheckResult)
	
	For Each TableRow In LastCheckResult Do
		Set = InformationRegisters.AccountingCheckResults.CreateRecordSet();
		Set.Filter.ObjectWithIssue.Set(TableRow.ObjectWithIssue);
		Set.Filter.CheckRule.Set(TableRow.CheckRule);
		Set.Filter.CheckKind.Set(TableRow.CheckKind);
		Set.Filter.UniqueKey.Set(TableRow.UniqueKey);
		Set.Filter.IgnoreIssue.Set(TableRow.IgnoreIssue);
		
		SetPrivilegedMode(True);
		Set.Write();
		SetPrivilegedMode(False);
	EndDo;
	
EndProcedure

// Checks whether the number of the allowed limit check iterations is exceeded.
//
// Parameters:
//   CheckParameters - see the CheckParameters parameter in the AccountingAudit.IssueDetails.
//
// Returns:
//   Boolean - indicates whether the last iteration has been reached or not.
//
Function IsLastCheckIteration(CheckParameters)
	
	IsLastIteration = False;
	
	If CheckParameters.IssuesLimit <> 0 Then
		If CheckParameters.CheckIteration > CheckParameters.IssuesLimit Then
			IsLastIteration = True;
		Else
			CheckParameters.Insert("CheckIteration", CheckParameters.CheckIteration + 1);
		EndIf;
	EndIf;
	
	Return IsLastIteration;
	
EndFunction

// Returns a metadata object kind string presentation by the object type.
// Restriction: does not process business process route points.
//
// Parameters:
//  ObjectReference - AnyRef - a reference to an object with issues.
//
// Returns:
//  String - metadata object kind presentation. For example: "Catalog", "Document".
//
Function ObjectPresentationByType(ObjectReference)
	
	ObjectType = TypeOf(ObjectReference);
	
	If Catalogs.AllRefsType().ContainsType(ObjectType) Then
		
		Return NStr("vi = 'phần tử danh mục';
					|ru = 'элементе справочника';
					|en = 'catalog item'; fa = 'catalog item';
					|it = 'elemento di directory';
					|pl = 'elemencie katalogu';
					|tr = 'katalog öğesinde'");
	
	ElsIf Documents.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("vi = 'chứng từ';
					|ru = 'документе';
					|en = 'document'; fa = 'document';
					|it = 'documento';
					|pl = 'document';
					|tr = 'belgede'");
	
	ElsIf BusinessProcesses.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("vi = 'quy trình nghiệp vụ';
					|ru = 'бизнес процессе';
					|en = 'business process'; fa = 'business process';
					|it = 'processo aziendale';
					|pl = 'procesie biznesowym';
					|tr = 'iş sürecinde'");
	
	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("vi = 'hệ thống dạng đặc tính';
					|ru = 'плане видов характеристик';
					|en = 'chart of characteristic types'; fa = 'chart of characteristic types';
					|it = 'piano dei tipi di caratteristiche';
					|pl = 'planie rodzajów charakterystyk';
					|tr = 'özellik türü listesinde'");
	
	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("vi = 'hệ thống tài khoản';
					|ru = 'плане счетов';
					|en = 'chart of accounts'; fa = 'chart of accounts';
					|it = 'piano dei conti';
					|pl = 'planie kont';
					|tr = 'hesap planında'");
	
	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("vi = 'hệ thống dạng tính toán';
					|ru = 'плане видов расчета';
					|en = 'chart of calculation types'; fa = 'chart of calculation types';
					|it = 'piano dei tipi di calcolo';
					|pl = 'planie rodzajów obliczeń';
					|tr = 'hesaplama türleri çizelgesinde'");
	
	ElsIf Tasks.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("vi = 'nhiệm vụ';
					|ru = 'задаче';
					|en = 'task'; fa = 'task';
					|it = 'compito';
					|pl = 'task';
					|tr = 'görevde'");
	
	ElsIf ExchangePlans.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("vi = 'hệ thống trao đổi';
					|ru = 'плане обмена';
					|en = 'exchange plan'; fa = 'exchange plan';
					|it = 'piano di scambio';
					|pl = 'planie kont';
					|tr = 'değişim planında'");
	
	ElsIf Enums.AllRefsType().ContainsType(ObjectType) Then
		Return NStr("vi = 'liệt kê';
					|ru = 'перечислении';
					|en = 'enumeration'; fa = 'enumeration';
					|it = 'enumerazione';
					|pl = 'enumeration';
					|tr = 'transferde'");
	
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Sai kiểu giá trị tham số (%1)';
																			|ru = 'Неверный тип значения параметра (%1)';
																			|en = 'Invalid parameter value type (%1)'; fa = 'Invalid parameter value type (%1)';
																			|it = 'Il tipo di valore del parametro (%1) non è valido';
																			|pl = 'Błędny typ wartości parametrów (%1)';
																			|tr = 'Parametre değeri türü yanlış (%1)'"), String(ObjectType));
	
	EndIf;
	
EndFunction

// Returns the String, Array, and CatalogRef.ChecksKinds types
// to check the parameters of methods that handle check types.
//
// Returns:
//    Array - Object types.
//
Function TypeDetailsCheckKind() Export
	
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypesArray.Add(Type("Array"));
	TypesArray.Add(Type("CatalogRef.ChecksKinds"));
	
	Return TypesArray;
	
EndFunction

// Returns allowed parameter types of the check.
//
// Returns:
//   Structure:
//      * IssueSeverity - EnumRef.AccountingIssueSeverity
//      * GlobalSettings - Structure
//      * CheckStartDate - Date
//      * Id - String
//      * ScheduledJobID - String
//      * CheckIteration - Number
//      * IssuesLimit - Number
//      * Description - String
//      * Validation - CatalogRef.AccountingCheckRules
//
Function CheckParametersPropertiesExpectedTypes() Export
	
	PropertiesTypesToExpect = New Structure;
	PropertiesTypesToExpect.Insert("IssueSeverity",                  Type("EnumRef.AccountingIssueSeverity"));
	PropertiesTypesToExpect.Insert("GlobalSettings",               Type("Structure"));
	PropertiesTypesToExpect.Insert("CheckStartDate",                Type("Date"));
	PropertiesTypesToExpect.Insert("Id",                     Type("String"));
	PropertiesTypesToExpect.Insert("ScheduledJobID", Type("String"));
	PropertiesTypesToExpect.Insert("CheckIteration",                  Type("Number"));
	PropertiesTypesToExpect.Insert("IssuesLimit",                      Type("Number"));
	PropertiesTypesToExpect.Insert("Description",                      Type("String"));
	PropertiesTypesToExpect.Insert("Validation",                          Type("CatalogRef.AccountingCheckRules"));
	
	Return PropertiesTypesToExpect;
	
EndFunction

// Returns the valid property types for the given check type. See the Property1, Property2, ... attributes of the ChecksKinds catalog. 
//
// Returns:
//   TypeDescription - all reference types as well as the Boolean, String, Number, and Date types.
//
Function ExpectedPropertiesTypesOfChecksKinds() Export
	
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypesArray.Add(Type("String"));
	TypesArray.Add(Type("Date"));
	TypesArray.Add(Type("Number"));
	
	Return New TypeDescription(Common.AllRefsTypeDetails(), TypesArray);
	
EndFunction

// Returns allowed property types of issue description.
//
// Parameters:
//   IssueFullDetails          - Boolean - it affects the composition of return value properties.
//
// Returns:
//   Structure:
//        * ObjectWithIssue         - AnyRef - a reference to the object that is the Source of issues.
//        * CheckRule          - CatalogRef.AccountingCheckRules - a reference to the executed check.
//        * CheckKind              - CatalogRef.ChecksKinds - Reference to the check type. 
//                                     
//        * IssueSummary        - String - a string summary of the found issue.
//        * UniqueKey         - UUID - an issue unique key. 
//                                     It is returned if IssueFullDetails = True.
//        * IssueSeverity         - EnumRef.AccountingIssueSeverity - Severity level of a data integrity issue 
//                                     Information, Warning, Error, and UsefulTip.
//                                     It is returned if IssueFullDetails = True.
//        * EmployeeResponsible            - CatalogRef.Users - it is filled in if it is possible
//                                     to identify a person responsible for the problematic object.
//                                     It is returned if IssueFullDetails = True.
//        * IgnoreIssue     - Boolean - a flag of ignoring an issue. If the value is True,
//                                     the subsystem ignores the record about an issue.
//                                     It is returned if IssueFullDetails = True.
//        * AdditionalInformation - ValueStorage - a service property with additional
//                                     information related to the detected issue.
//                                     It is returned if IssueFullDetails = True.
//        * Detected                 - Date - server time of the issue identification.
//                                     It is returned if IssueFullDetails = True.
//
Function IssueDetailsPropertiesTypesToExpect(Val IssueFullDetails = True) Export
	
	PropertiesTypesToExpect = New Structure;
	PropertiesTypesToExpect.Insert("ObjectWithIssue",  Common.AllRefsTypeDetails());
	PropertiesTypesToExpect.Insert("CheckRule",   Type("CatalogRef.AccountingCheckRules"));
	PropertiesTypesToExpect.Insert("CheckKind",       Type("CatalogRef.ChecksKinds"));
	PropertiesTypesToExpect.Insert("IssueSummary", Type("String"));
	
	If IssueFullDetails Then
		PropertiesTypesToExpect.Insert("IssueSeverity",         Type("EnumRef.AccountingIssueSeverity"));
		PropertiesTypesToExpect.Insert("Detected",                 Type("Date"));
		PropertiesTypesToExpect.Insert("UniqueKey",         Type("UUID"));
		PropertiesTypesToExpect.Insert("AdditionalInformation", Type("ValueStorage"));
		ResponsiblePersonTypes = New Array;
		ResponsiblePersonTypes.Add(Type("CatalogRef.Users"));
		ResponsiblePersonTypes.Add(Type("Undefined"));
		PropertiesTypesToExpect.Insert("EmployeeResponsible", ResponsiblePersonTypes);
	EndIf;
	
	Return PropertiesTypesToExpect;
	
EndFunction

// Returns:
//   Array of MetadataObjectCatalog
//
Function MetadataObjectsRefKinds()
	
	Result = New Array;
	Result.Add(Metadata.Catalogs);
	Result.Add(Metadata.Documents);
	Result.Add(Metadata.ExchangePlans);
	Result.Add(Metadata.ChartsOfCharacteristicTypes);
	Result.Add(Metadata.ChartsOfAccounts);
	Result.Add(Metadata.ChartsOfCalculationTypes);
	Result.Add(Metadata.BusinessProcesses);
	Result.Add(Metadata.Tasks);
	Return Result;
	
EndFunction

Function RegistersAsMetadataObjects()
	
	Result = New Array;
	Result.Add(Metadata.AccountingRegisters);
	Result.Add(Metadata.AccumulationRegisters);
	Result.Add(Metadata.CalculationRegisters);
	Result.Add(Metadata.InformationRegisters);
	Return Result;
	
EndFunction

Function IssuePicture(Settings)
	IssuesIndicatorPicture = Settings.IssuesIndicatorPicture;
	IssueSeverity = Settings.IssueSeverity;
	
	If IssuesIndicatorPicture <> Undefined And IssuesIndicatorPicture <> PictureLib.Warning Then
		Picture = IssuesIndicatorPicture;
	ElsIf IssueSeverity = Enums.AccountingIssueSeverity.Error
		Or IssueSeverity = Enums.AccountingIssueSeverity.Warning Then
		Picture = PictureLib.Warning;
	ElsIf IssueSeverity = Enums.AccountingIssueSeverity.ImportantInformation
		Or IssueSeverity = Enums.AccountingIssueSeverity.Information Then
		Picture = PictureLib.Information;
	ElsIf IssueSeverity = Enums.AccountingIssueSeverity.UsefulTip Then
		Picture = PictureLib.UsefulTipAccountingAudit;
	Else
		Picture = PictureLib.Warning;
	EndIf;
	
	Return Picture;
EndFunction

#Region IgnoreIssuesInternal

// Generates the ObjectWithIssue, CheckRule, CheckKind dimensions checksum 
// and the IssueSummary resource by the MD5 algorithm.
//
// Parameters:
//   Issue1 - see the AccountingAudit.WriteIssue parameter.
//
// Returns:
//    String - a dimension checksum of the check result register: ProblemObject,
//             CheckRule, CheckKind, and the IssueSummary resource by the MD5 algorithm.
//
Function IssueChecksum(Issue1) Export
	
	IssueStructure = New Structure("ObjectWithIssue, CheckRule, CheckKind, IssueSummary");
	FillPropertyValues(IssueStructure, Issue1);
	Return Common.CheckSumString(IssueStructure);
	
EndFunction

// Returns True if an issue was ignored.
//
// Parameters:
//   Checksum - String - a register record checksum by the MD5 algorithm.
//
Function ThisIssueIgnored(Checksum)
	
	Query = New Query(
	"SELECT TOP 1
	|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	AccountingCheckResults.Checksum = &Checksum
	|	AND AccountingCheckResults.IgnoreIssue");
	
	Query.SetParameter("Checksum", Checksum);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("UpdateAuxiliaryRegisterDataByConfigurationChanges");
	Methods.Insert("CheckUnfilledRequiredAttributes");
	Methods.Insert("CheckPredefinedExchangePlanNodeAvailability");
	Methods.Insert("CheckDuplicatePredefinedItems");
	Methods.Insert("CheckMissingPredefinedItems");
	Methods.Insert("CheckCircularRefs");
	Methods.Insert("CheckReferenceIntegrity");
	Methods.Insert("ExecuteChecks", True);
	Methods.Insert("ExecuteCheck", True);
	Methods.Insert("CheckObject", True);
	Methods.Insert("FixInfiniteLoopInBackgroundJob", True);
	
EndProcedure

#EndRegion