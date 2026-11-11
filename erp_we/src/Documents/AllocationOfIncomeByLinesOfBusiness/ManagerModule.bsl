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
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("FinancialResult");
	DocumentMechanisms.Add("DocumentsRegistry");
	
	AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.AllocationOfIncomeByLinesOfBusiness") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableFinancialResults(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		If Query.Parameters.ThereAreOtherExpenses Then
			QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		EndIf;
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.AddRequestTexts(Query,
																											QueryTexts,
																											Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create the "income and expense Distribution" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.AllocationOfIncomeByLinesOfBusiness) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.AllocationOfIncomeByLinesOfBusiness.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.AllocationOfIncomeByLinesOfBusiness);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "GenerateFinancialResult";
	

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Creates distribution documents for the specified month
//
//	Parameters:
//		Period - Date - The beginning of the month for which you need to create documents.
//		Organization - Array, Undefined - List of organizations for which documents are generated. If the list is empty,
//												documents are generated for all organizations.
//		Cancel - Boolean - Used when calling from the month closing form. When set to True, no further operations
//							will be performed.
Procedure CreateDocumentsForPeriod(Period, Organization = Undefined, Cancel = False) Export
	
	CheckBlockingIncomingDataWhenUpdatingInformationSecurity(NStr("vi = 'Phân bổ thu chi theo mảng hoạt động';
																	|ru = 'Распределение доходов и расходов по направлениям деятельности';
																	|en = 'Allocation of income and expenses by lines of business'; fa = 'Allocation of income and expenses by lines of business';
																	|it = 'Ripartizione delle entrate e delle spese nei settori di attività';
																	|pl = 'Podział dochodów i wydatków według kierunków działalności';
																	|tr = 'Gelir ve giderlerin iş kollarına göre dağıtımı'"));
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("MonthEndTransactions.AllocationOfIncomeByLinesOfBusiness");
	
	TempTablesManager = New TempTablesManager;
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT ALLOWED
	|	CatalogData.Ref AS Organization
	|INTO TTOrganizations
	|FROM
	|	Catalog.Companies AS CatalogData
	|WHERE
	|	(CatalogData.Ref = &Organization
	|		OR &ByAllCompanies)
	|	AND (CatalogData.Ref <> VALUE(Catalog.Companies.ManagementCompany)
	|		OR &ConsiderManOrganization)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Doc.Ref AS Ref,
	|	Doc.Organization AS Organization
	|INTO TTDocuments
	|FROM
	|	Document.AllocationOfIncomeByLinesOfBusiness AS Doc
	|
	|	INNER JOIN TTOrganizations AS TTOrganizations
	|	ON Doc.Organization = TTOrganizations.Organization
	|WHERE
	|	Doc.Date BETWEEN &StartDate AND &EndDate
	|	AND Doc.DeletionMark = FALSE
	|	AND Doc.AllocationByAllCompanies = FALSE
	|	AND
	|	(Doc.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|		OR &ConsiderManOrganization)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTOrganizations.Organization AS Organization,
	|	TTDocuments.Ref AS Document
	|FROM
	|	TTOrganizations AS TTOrganizations
	|
	|	LEFT JOIN TTDocuments AS TTDocuments
	|	ON TTOrganizations.Organization = TTDocuments.Organization
	|";

	Query.SetParameter("StartDate", BegOfMonth(Period));
	Query.SetParameter("EndDate", EndOfMonth(Period));
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ByAllCompanies", (Organization = Undefined Or Organization = Catalogs.Companies.EmptyRef()));
	Query.SetParameter("ConsiderManOrganization", GetFunctionalOption("UseManagementCompany"));
	
	QueryResult = Query.Execute();
	
	AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.BeforeCreatingDocumentsForPeriod(Period, Organization, TempTablesManager);
	
	DistributionDocuments = QueryResult.Select();
	While DistributionDocuments.Next() Do 
		
		If DistributionDocuments.Document = Null Then
			DocumentDistributions = Documents.AllocationOfIncomeByLinesOfBusiness.CreateDocument();
			DocumentDistributions.Date = EndOfMonth(Period);
			DocumentDistributions.AllocationByAllCompanies 	= False;
			DocumentDistributions.Organization = DistributionDocuments.Organization;
			DocumentDistributions.EmployeeResponsible = Users.CurrentUser();
		Else
			DocumentDistributions = DistributionDocuments.Document.GetObject();
		EndIf;
		
		If DocumentDistributions.Posted Then
			ClearedRegisters = New	Array;
			ClearedRegisters.Add("OtherIncome");
			For Each RegisterName In ClearedRegisters Do
				RegisterRecords = AccumulationRegisters[RegisterName].CreateRecordSet(); // AccumulationRegisterRecordSet
				RegisterRecords.Filter.Recorder.Set(DocumentDistributions.Ref);
				RegisterRecords.Write();
			EndDo;
		EndIf;
		
		DocumentDistributions.FillInExpensesOnBalances();
		DocumentDistributions.FillInIncomeOnBalances();
		
		DocumentDistributions.Write(DocumentWriteMode.Write);
		
		// Let's check the correctness of filling out the document.
		ErrorText = CostCalculationAppliedAlgorithms.CheckIfObjectIsFullWithMessageInterception(DocumentDistributions);
		
		If ValueIsFilled(ErrorText) Then
			
			// Checking the completion of the document found errors.
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi kiểm tra chứng từ ""%1"" đã tìm thấy lỗi:
					|%2';
					|ru = 'При проверке документа ""%1"" были обнаружены ошибки:
					|%2';
					|en = 'Errors were detected while checking the ""%1"" document:
					|%2'; fa = 'Errors were detected while checking the ""%1"" document:
					|%2';
					|it = 'Durante il controllo dei documenti ""%1"" sono stati riscontrati errori:
					|%2';
					|pl = 'Podczas sprawdzenia dokumentu ""%1"" wykryto błędy: 
					|%2';
					|tr = '""%1"" belgesini kontrol ederken hatalar bulundu:
					|%2'", Common.DefaultLanguageCode()),
				TrimAll(DocumentDistributions),
				CostCalculationProtocol.PresentationOfMultilineText(ErrorText, " - "));
			
		Else
			
			// Let's hold the document.
			ErrorText = CostCalculationAppliedAlgorithms.ConductDocumentWithMessageInterception(DocumentDistributions);
			
			If ValueIsFilled(ErrorText) Then
				// The document was executed with errors.
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi kết chuyển chứng từ ""%1"" đã tìm thấy lỗi:
						|%2';
						|ru = 'При проведении документа ""%1"" были обнаружены ошибки:
						|%2';
						|en = 'Errors occurred when posting the ""%1"" document:
						|%2'; fa = 'Errors occurred when posting the ""%1"" document:
						|%2';
						|it = 'Durante la registrazione del documento ""%1"" sono stati riscontrati errori:
						|%2';
						|pl = 'Podczas zaksięgowania dokumentu ""%1"" wykryto błędy:
						|%2';
						|tr = '""%1"":
						|%2 belgesinin kaydı sırasında hatalar bulundu'", Common.DefaultLanguageCode()),
					TrimAll(DocumentDistributions),
					CostCalculationProtocol.PresentationOfMultilineText(ErrorText, " - "));
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(ErrorText) Then
			
			RegistrationParameters = MonthEndTransactionsServer.InitializeParametersForRegisteringCalculationProblem(
				Catalogs.MonthEndClosingOperations.AllocationOfIncomeByLinesOfBusiness,
				DistributionDocuments.Organization,
				BegOfMonth(Period));
			
			MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
				RegistrationParameters,
				NStr("vi = 'Khi phân bổ thu nhập và chi phí theo doanh nghiệp ""%1"" trong kỳ %2, đã chẩn đoán được các lỗi';
					|ru = 'При распределение доходов и расходов по организации ""%1"" за период %2 были диагностированы ошибки';
					|en = 'Errors were found when allocating income and expenses of the ""%1"" company for period %2'; fa = 'Errors were found when allocating income and expenses of the ""%1"" company for period %2';
					|it = 'Durante la ripartizione di entrate e uscite in base alle società ""%1"" per il periodo %2 sono stati riscontrati errori';
					|pl = 'Podczas podziału dochodów i wydatków według firmy ""%1"" za okres %2 wykryto błędy.';
					|tr = '""%1"" iş yeri için %2 dönemine ait gelir ve giderlerin dağıtımı sırasında hatalar tespit edildi'", Common.DefaultLanguageCode()),
				,
				ErrorText,
				DocumentDistributions.Ref);
			
		EndIf;
		
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DistributionDocuments.Count());
	
EndProcedure

// Returns parameters for selecting articles in the document.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ChoiceParametersArray = New Array;
	
	#Region IncomeIncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Income";
	ChoiceParameters.AssetRef = "IncomeItem";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("IncomeDimensionOfRevenue");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region ExpensesExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Expenses";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionOfExpenses");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	Return ChoiceParametersArray;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region Internal

#Region HandlersForMonthClosingStages

#Region AllocationOfIncomeAndExpensesByLinesOfBusiness

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable 
// 	CurrentParent - String - group ID.
Procedure AddStage_AllocationOfIncomeByLinesOfBusiness(StepsTable,CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.AllocationOfIncomeByLinesOfBusiness);
		
	NewRow.MultilingualName = "vi = 'Phân bổ thu nhập theo lĩnh vực hoạt động';
								|ru = 'Распределение доходов по направлениям деятельности';
								|en = 'Allocation of income by lines of business';
								|it = 'Ripartizione delle entrate e delle spese nei settori di attività';
								|pl = 'Podział dochodów według kierunków działalności';
								|tr = 'Faaliyet alanlarına göre gelir dağılımı'"; // @NStr-1
	PreviousStages_ = NewRow.PreviousStages_; // Array
	PreviousStages_.Add(Catalogs.MonthEndClosingOperations.LotsAndCostCalculation);
	PreviousStages_.Add(Catalogs.MonthEndClosingOperations.RegistrationOfCostAllocationDocuments);
	NewRow.TextExecute = NStr("vi = 'Phân bổ';
								|ru = 'Распределить';
								|en = 'Allocate'; fa = 'تسهیم';
								|it = 'Ripartire';
								|pl = 'Allocate';
								|tr = 'Dağıt'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.AllocationOfIncomeByLinesOfBusiness.Use_DistributionOfIncomeByAreasOfActivity");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"Documents.AllocationOfIncomeByLinesOfBusiness.Perform_DistributionOfIncomeByLineOfBusiness");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.AllocationOfIncomeByLinesOfBusiness.Forms.ListForm.FullName());
		
EndProcedure

// Stage handlers.

Procedure Use_DistributionOfIncomeByAreasOfActivity(HandlerParameters) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT DISTINCT
	|	Income.Organization
	|FROM
	|	AccumulationRegister.OtherIncome.Turnovers(&BeginOfPeriod, &BorderEndOfPeriod, , Organization IN (&CompanyArray)) AS Income
	|WHERE
	|	Income.SumTurnover <> 0
	|	OR Income.SumManTurnover <> 0
	|	OR Income.SumComplTurnover <> 0";
	
	QueryResult = Query.Execute();
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, QueryResult.Unload().Count());
	
	ThereIsTaskForCalculation = MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, False);
	If QueryResult.IsEmpty() And Not ThereIsTaskForCalculation Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có doanh thu theo các biểu ghi thu nhập khác trong giai đoạn %1';
					|ru = 'Нет оборотов по регистрам прочих доходов за период %1';
					|en = 'No turnovers for registers of income for period %1'; fa = 'No turnovers for registers of income for period %1';
					|it = 'Non ci sono fatturati nei registri di altre entrate  per il periodo %1';
					|pl = 'Brak obrotów wg rejestrów innych dochodów  za okres %1';
					|tr = 'Dönem içinde diğer gelir kayıtlarında ciro mevcut değil %1'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(HandlerParameters.CalculationParameters.RegistrationPeriod)));
		Return;
		
	EndIf;
	
	Query.Text =
		"SELECT
		|	TasksTo_Close.Organization AS Organization
		|INTO TTTasksForDistributionOfIncomeByLB
		|FROM
		|	InformationRegister.JobsForMonthEndClosing AS TasksTo_Close
		|WHERE
		|	TasksTo_Close.Organization IN (&CompanyArray)
		|	AND TasksTo_Close.Month = &EndOfPeriod
		|	AND TasksTo_Close.Operation = VALUE(Catalog.MonthEndClosingOperations.AllocationOfIncomeByLinesOfBusiness)
		|;
		|SELECT DISTINCT
		|	Jobs.Organization
		|FROM
		|	TTTasksForDistributionOfIncomeByLB AS Jobs";
	
	Selection = Query.Execute().Select();
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, Selection.Count());
	
	If Selection.Count() > 0 Then
		
		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tính toán lại cho giai đoạn %1 là bắt buộc.';
					|ru = 'Требуется пересчет за период %1.';
					|en = 'Recalculation for period %1 is required.'; fa = 'Recalculation for period %1 is required.';
					|it = 'È necessario un ricalcolo per il periodo %1.';
					|pl = 'Potrzebne jest przeliczenie za okres %1.';
					|tr = '%1 dönemi için yeniden hesaplama gerekmektedir.'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(HandlerParameters.CalculationParameters.RegistrationPeriod)));
		
	EndIf;
				
EndProcedure

Procedure Perform_DistributionOfIncomeByLineOfBusiness(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	NumberOfFederalLaws = CalculationOfCostCached.ValuesOfTechnologicalParameters(Catalogs.MonthEndClosingOperations.EmptyRef()).MaximumNumberOfFederalLawsForFormationOfDocuments;
	RowsCount = CalculationParameters.CompanyArray.Count();
	LinesOfVFZ = Int(RowsCount / ?(NumberOfFederalLaws = 0, 1, NumberOfFederalLaws));
	
	If NumberOfFederalLaws < 2 Or LinesOfVFZ < 1 Then
		
		// Single-threaded distribution
		AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.DistributeIncomeByLineOfBusiness(
			HandlerParameters,
			CalculationParameters.CompanyArray);
		
	Else

		//Multithreaded distribution
		ProcessedRows_     = 0;
		ArrayOfTasks       = New Array;
		PortionOfOrganizations   = New Array;
		
		While ProcessedRows_ <= RowsCount Do
			
			If ProcessedRows_ = 0 Or ProcessedRows_ = RowsCount
			 // The task is started when the result table is filled with the number of registrars equal to the number of columns.
			 // All the remaining registrars are placed in the last task, even if there are more of them than the row of the register.
			 Or (Int(ProcessedRows_/LinesOfVFZ) = ProcessedRows_/LinesOfVFZ And ArrayOfTasks.Count() < NumberOfFederalLaws-1) Then
				
				If ProcessedRows_ > 0 Then
					
					// We are launching a new Federal law
					ParametersArray = New Array;                                                                      
					ParametersArray.Add(HandlerParameters);
					ParametersArray.Add(PortionOfOrganizations);
					
					JobKey = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Nhiệm vụ nền số %1 - %2 (%3)';
							|ru = 'ФЗ №%1 - %2 (%3)';
							|en = 'FZ No.%1 - %2 (%3)'; fa = 'FZ No.%1 - %2 (%3)';
							|it = 'ФЗ №%1 - %2 (%3)';
							|pl = 'UF nr%1 - %2 (%3)';
							|tr = 'FZ №%1 - %2 (%3)'", Common.DefaultLanguageCode()),
						TrimAll(ArrayOfTasks.Count() + 1),
						TrimAll(HandlerParameters.Data_Stage.Code),
						TrimAll(HandlerParameters.CalculationID));
					
					Job = MonthEndTransactionsServer.StartSubordinateBackgroundTaskOfCalculationStage(
						HandlerParameters.CalculationID,
						"AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.DistributeIncomeByLineOfBusiness",
						ParametersArray,
						JobKey,
						NStr("vi = 'Tạo hàng loạt chứng từ';
							|ru = 'Пакетное формирование документов';
							|en = 'Package document generation'; fa = 'Package document generation';
							|it = 'Пакетное формирование документов';
							|pl = 'Tworzenie pakietów dokumentów';
							|tr = 'Toplu belge oluşturma'"));
						
			        ArrayOfTasks.Add(Job);
					
				EndIf;
				
				If ProcessedRows_ = RowsCount Then
					// All tasks are running
					Break;
				EndIf;
				
				PortionOfOrganizations = New Array;
				
			EndIf;
			
			PortionOfOrganizations.Add(CalculationParameters.CompanyArray[ProcessedRows_]);
			
			ProcessedRows_ = ProcessedRows_ + 1;
			
		EndDo;
		
		TasksAreCompleted = False;;
		
		While Not TasksAreCompleted Do
			
			Tasks_Completed = BackgroundJobs.WaitForExecutionCompletion(ArrayOfTasks);
			
			ArrayOfTasks = New Array;
			
			For Each Job In Tasks_Completed Do
				
				If Job.State = BackgroundJobState.Active Then
					
					ArrayOfTasks.Add(Job);
					
				ElsIf Job.State <> BackgroundJobState.Completed Then

					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Nhiệm vụ nền tạo chứng từ %1
						|%2';
						|ru = 'Фоновое задание формирования документов %1
						|%2';
						|en = 'Background job of creating documents: %1
						|%2'; fa = 'Background job of creating documents: %1
						|%2';
						|it = 'Фоновое задание формирования документов %1
						|%2';
						|pl = 'Background job of creating documents: %1
						|%2';
						|tr = 'Arka plan belgesi oluşturma işi %1
						|%2'", Common.DefaultLanguageCode()),
						?(Job.State = BackgroundJobState.Canceled,
							NStr("vi = 'đã hủy';
								|ru = 'отменено';
								|en = 'canceled'; fa = 'canceled';
								|it = 'отменено';
								|pl = 'anulowano';
								|tr = 'iptal edildi'", Common.DefaultLanguageCode()),
							NStr("vi = 'kết thúc bất thường';
								|ru = 'завершено аварийно';
								|en = 'aborted'; fa = 'aborted';
								|it = 'завершено аварийно';
								|pl = 'zakończone awaryjnie';
								|tr = 'arızalı tamamlandı'", Common.DefaultLanguageCode())),
						?(Job.ErrorInfo = Undefined,
							NStr("vi = '<Không có mô tả lỗi>';
								|ru = '<Нет описания ошибки>';
								|en = '<No error description>'; fa = '<No error description>';
								|it = '<Нет описания ошибки>';
								|pl = '<Brak opisu błędu>';
								|tr = '<Hata ayrıntıları mevcut değil>'", Common.DefaultLanguageCode()),
							DetailErrorDescription(Job.ErrorInfo)));
							
					MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
						HandlerParameters,
						ErrorText);
					
				EndIf;
				
			EndDo;
			
			TasksAreCompleted = (ArrayOfTasks.Count() = 0);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfInspections_DistributionOfIncomeByAreasOfActivity(TableOfChecks) Export
	
	// Setting up cost allocation.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"CheckingOtherIncomeBalances",
		Catalogs.MonthEndClosingOperations.AllocationOfIncomeByLinesOfBusiness,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.AfterCalculation,
		"Documents.AllocationOfIncomeByLinesOfBusiness.CheckingOtherIncomeBalances");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Không phân bổ thu nhập khác vào kết quả kinh doanh';
			|ru = 'Не распределены прочие доходы на финансовый результат';
			|en = 'Income for the financial result is not allocated'; fa = 'Income for the financial result is not allocated';
			|it = 'Le altre entrate e spese non sono state allocate sul risultato finanziario';
			|pl = 'Nie są podzielone inne dochody do wyniku finansowego';
			|tr = 'Diğer gelirler finansal sonuçlara dağıtılmadı'", Common.DefaultLanguageCode()),
		NStr("vi = 'Cần phân bổ tất cả thu nhập khác vào kết quả kinh doanh.';
			|ru = 'Все прочие доходы должны быть распределены на финансовый результат.';
			|en = 'All income must be allocated for the financial result.'; fa = 'All income must be allocated for the financial result.';
			|it = 'Tutte le altre entrate devono essere allocate sul risultato finanziario';
			|pl = 'Wszystkie inne dochody powinny być podzielone do wyniku finansowego.';
			|tr = 'Diğer tüm gelirler finansal sonuçlara dağıtılacaktır.'", Common.DefaultLanguageCode()));
	
EndProcedure

Procedure CheckingOtherIncomeBalances(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 			NStr("vi = 'Doanh nghiệp';
													|ru = 'Организация';
													|en = 'Company'; fa = 'Company';
													|it = 'Azienda';
													|pl = 'Organizacja';
													|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTTasksForDistributionOfIncomeByLB",
		NStr("ru = 'По организации ""%1"" на конец периода %2 не выполнено распределение прочих доходов по направлениям деятельности.';
			|vi = 'For the ""%1"" company at the end of period %2, other income is not allocated to lines of business.';
			|en = 'For the ""%1"" company at the end of period %2, other income is not allocated to lines of business.'; fa = 'For the ""%1"" company at the end of period %2, other income is not allocated to lines of business.';
			|it = 'For the ""%1"" company at the end of period %2, other income is not allocated to lines of business.';
			|pl = 'For the ""%1"" company at the end of period %2, other income is not allocated to lines of business.';
			|tr = '%2 dönemi sonu itibarıyla ""%1"" iş yerinde diğer gelirlerin faaliyet alanlarına göre dağıtımı yapılmamıştır.'", Common.DefaultLanguageCode()),
		FieldList,
		,
		Metadata.AccumulationRegisters.OtherIncome.FullName());
	
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
		
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If Not Data.Property("Ref") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	Table.Ref AS Ref,
		|	AllocationOfIncomeByLinesOfBusiness.Number AS Number,
		|	AllocationOfIncomeByLinesOfBusiness.Date AS Date
		|FROM
		|	Document.AllocationOfIncomeByLinesOfBusiness.Expenses AS Table
		|		INNER JOIN Document.AllocationOfIncomeByLinesOfBusiness AS AllocationOfIncomeByLinesOfBusiness
		|		ON Table.Ref = AllocationOfIncomeByLinesOfBusiness.Ref
		|WHERE
		|	Table.Ref = &Ref";
	
	Query.SetParameter("Ref", Data.Ref);
	
	Result = Query.Execute();	
	
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	StandardProcessing = False;
	TemplateOfPresentation = NStr("vi = '%1 %2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%3 tarihli %1 %2'");
	Presentation = StrTemplate(TemplateOfPresentation,
		PresentationOfEarlyDocuments(),
		Selection.Number,
		Selection.Date);
	
EndProcedure

#EndRegion

#Region Other

// Returns a representation of the document, in the period when the paper also carried out the distribution costs.
// Returns:
//	String - presentation of the document.
//
Function PresentationOfEarlyDocuments() Export
	
	Return NStr("vi = 'Phân bổ thu nhập và chi phí';
				|ru = 'Распределение доходов и расходов';
				|en = 'Allocation of income and expenses'; fa = 'Allocation of income and expenses';
				|it = 'Ripartizione dei profitti e delle spese';
				|pl = 'Przydział przychodów i rozchodów';
				|tr = 'Gelir ve giderlerin dağıtımı'");
	
EndFunction

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - The text of the reflection request in the regl. accounting.
//
Function TextOfReflectionInLocalAccounting() Export

	Return AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	TempTablesManager = Undefined;
	
	If AddlParameters <> Undefined
		And AddlParameters.Property("TempTablesManager", TempTablesManager) Then
		
		TempTablesManager = ?(TempTablesManager = Undefined,
									New TempTablesManager,
									TempTablesManager);
		
	Else
		TempTablesManager = New TempTablesManager;
	EndIf;
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "
	|SELECT TOP 1
	|	DocumentData.Ref AS Ref,
	|	TRUE AS ThereAreOtherExpenses
	|INTO DocumentDataExpenses
	|FROM
	|	Document.AllocationOfIncomeByLinesOfBusiness.Expenses AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.AllocationByAllCompanies AS AllocationByAllCompanies,
	|	DocumentData.Number AS Number,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	ISNULL(DocumentDataExpenses.ThereAreOtherExpenses, FALSE) AS ThereAreOtherExpenses
	|FROM
	|	Document.AllocationOfIncomeByLinesOfBusiness AS DocumentData
	|		LEFT JOIN DocumentDataExpenses AS DocumentDataExpenses
	|		ON DocumentDataExpenses.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|";

	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period", Attributes.Period);
	Query.SetParameter("Organization", Attributes.Organization);
	Query.SetParameter("AllocationByAllCompanies", Attributes.AllocationByAllCompanies);
	Query.SetParameter("StartDate_1", BegOfMonth(Attributes.Period));
	Query.SetParameter("ConDate", EndOfMonth(Attributes.Period));
	Query.SetParameter("InitialBorder", New Boundary(BegOfMonth(Attributes.Period), BoundaryType.Including));
	Query.SetParameter("ConBorder", New Boundary(EndOfMonth(Attributes.Period), BoundaryType.Including));
	Query.SetParameter("GenerateFinancialResult",	GetFunctionalOption("GenerateFinancialResult"));
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID("Document.AllocationOfIncomeByLinesOfBusiness"));
	Query.SetParameter("Number", Attributes.Number);
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("Comment", Attributes.Comment);
	Query.SetParameter("Posted", Attributes.Posted);
	Query.SetParameter("DeletionMark", Attributes.DeletionMark);
	Query.SetParameter("HouseholdOperationForRegistry", Enums.BusinessTransactions.AllocationOfIncomeByLinesOfBusiness);
	Query.SetParameter("EmployeeResponsible", Attributes.EmployeeResponsible);
	Query.SetParameter("ThereAreOtherExpenses", Attributes.ThereAreOtherExpenses);
	
EndProcedure

// The text of the query of the temporal table "Unprocedural".
//
// Parameters:
//	Query - Query - the request for the formation of movements
//  QueryTexts - ValueList - List of texts of the request for holding.
//
// Returns:
//	String - Query text
//
Function QueryTextTableTTOtherIncome(Query, QueryTexts = Undefined) Export
	
	RegisterName = "TTOtherIncome";
	
	If Query.TempTablesManager.Tables.Find("TTOtherIncome") <> Undefined Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	OtherIncome.LineNumber AS LineNumber,
	|	OtherIncome.Organization AS Organization,
	|	OtherIncome.Department AS Department,
	|	OtherIncome.IncomeItem AS IncomeItem,
	|	OtherIncome.DimensionOfRevenue AS DimensionOfRevenue,
	|	OtherIncome.LineOfBusiness AS LineOfBusiness,
	|	OtherIncome.LineOfBusinessAllocationMethod AS LineOfBusinessAllocationMethod,
	|
	|	OtherIncome.Sum AS Sum,
	|	OtherIncome.SumMan AS SumMan,
	|	OtherIncome.SumCompl AS SumCompl
	|
	|INTO TTOtherIncome
	|FROM
	|	Document.AllocationOfIncomeByLinesOfBusiness.Income AS OtherIncome
	|WHERE
	|	OtherIncome.Ref = &Ref
	|";
	
	If TypeOf(QueryTexts) = Type("ValueList") Then
		QueryTexts.Add(QueryText, RegisterName);
	EndIf;
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
		
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	GenerateTTFinancialResults(Query);
	
	QueryText = "SELECT
	|	&Period                                  AS Period,
	|	TableRevenue.Organization                AS Organization,
	|	TableRevenue.Department              AS Department,
	|	TableRevenue.InitialDirectionOfActivity AS LineOfBusiness,
	|	TableRevenue.IncomeItem              AS IncomeItem,
	|	TableRevenue.DimensionOfRevenue           AS DimensionOfRevenue,
	|	VALUE(Enum.BusinessTransactions.AllocationOfIncomeByLinesOfBusiness) AS BusinessOperation,
	|	TableRevenue.LineOfBusiness    AS CorLineOfBusiness,
	|
	|	SUM(-TableRevenue.Income)              AS Sum,
	|	SUM(-TableRevenue.ManSIncome)           AS SumMan,
	|	SUM(-TableRevenue.LocalRevenues)          AS SumCompl,
	|	
	|	TableRevenue.FinRecordID     AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AllocationOfIncomeByLinesOfBusiness) AS BusinessTransactionSetting
	|FROM
	|	TTFinancialResults AS TableRevenue
	|WHERE
	|	(TableRevenue.Income <> 0
	|			OR TableRevenue.ManSIncome <> 0
	|			OR TableRevenue.LocalRevenues <> 0)
	|	AND TableRevenue.InitialDirectionOfActivity <> TableRevenue.LineOfBusiness
	|
	|GROUP BY
	|	TableRevenue.Organization,
	|	TableRevenue.Department,
	|	TableRevenue.LineOfBusiness,
	|	TableRevenue.IncomeItem,
	|	TableRevenue.DimensionOfRevenue,
	|	TableRevenue.InitialDirectionOfActivity,
	|	TableRevenue.FinRecordID 
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                  AS Period,
	|	TableRevenue.Organization                AS Organization,
	|	TableRevenue.Department              AS Department,
	|	TableRevenue.LineOfBusiness AS LineOfBusiness,
	|	TableRevenue.IncomeItem              AS IncomeItem,
	|	TableRevenue.DimensionOfRevenue           AS DimensionOfRevenue,
	|	VALUE(Enum.BusinessTransactions.AllocationOfIncomeByLinesOfBusiness) AS BusinessOperation,
	|	TableRevenue.InitialDirectionOfActivity    AS CorLineOfBusiness,
	|
	|	SUM(TableRevenue.Income)              AS Sum,
	|	SUM(TableRevenue.ManSIncome)           AS SumMan,
	|	SUM(TableRevenue.LocalRevenues)          AS SumCompl,
	|
	|	TableRevenue.FinRecordID     AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AllocationOfIncomeByLinesOfBusiness) AS BusinessTransactionSetting
	|FROM
	|	TTFinancialResults AS TableRevenue
	|WHERE
	|	(TableRevenue.Income <> 0
	|			OR TableRevenue.ManSIncome <> 0
	|			OR TableRevenue.LocalRevenues <> 0)
	|	AND TableRevenue.InitialDirectionOfActivity <> TableRevenue.LineOfBusiness
	|
	|GROUP BY
	|	TableRevenue.Organization,
	|	TableRevenue.Department,
	|	TableRevenue.IncomeItem,
	|	TableRevenue.DimensionOfRevenue,
	|	TableRevenue.FinRecordID,
	|	TableRevenue.LineOfBusiness,
	|	TableRevenue.InitialDirectionOfActivity";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

// The text of the query of the temporal table "Unproceeded".
//
// Parameters:
//	Query - Query - the request for the formation of movements
//  QueryTexts - ValueList - List of texts of the request for holding.
//
// Returns:
//	String - Query text
//
Function QueryTextTableTTOtherExpenses_(Query, QueryTexts = Undefined) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Query.TempTablesManager.Tables.Find("TTOtherExpenses_") <> Undefined Then
		Return "";
	EndIf;
	
	If Query.Parameters.ThereAreOtherExpenses Then
		QueryText = "
		|SELECT
		|	OtherExpenses.LineNumber AS LineNumber,
		|	OtherExpenses.Organization AS Organization,
		|	OtherExpenses.Department AS Department,
		|	OtherExpenses.ExpenseItem AS ExpenseItem,
		|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
		|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
		|	OtherExpenses.LineOfBusinessAllocationMethod AS LineOfBusinessAllocationMethod,
		|	FALSE AS Normalized,
		|
		|	OtherExpenses.Sum AS Sum,
		|	OtherExpenses.SumMan AS SumMan,
		|	OtherExpenses.SumCompl AS SumCompl,
		|	OtherExpenses.PermanentDifference AS PermanentDifference,
		|	OtherExpenses.CostTD AS CostTD
		|
		|INTO TTOtherExpenses_
		|FROM
		|	Document.AllocationOfIncomeByLinesOfBusiness.Expenses AS OtherExpenses
		|
		|WHERE
		|	OtherExpenses.Ref = &Ref
		|";
	
		AllocationOfIncomeAndExpensesByLinesOfBusinessLocalization.ChangeQueryTextOfTableTTOtherExpenses(
			QueryText, Query, QueryTexts);
	Else
		QueryText = "
		|SELECT TOP 0
		|	OtherExpenses.LineNumber AS LineNumber,
		|	OtherExpenses.Organization AS Organization,
		|	OtherExpenses.Department AS Department,
		|	OtherExpenses.ExpenseItem AS ExpenseItem,
		|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
		|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
		|	OtherExpenses.LineOfBusinessAllocationMethod AS LineOfBusinessAllocationMethod,
		|	FALSE AS Normalized,
		|
		|	OtherExpenses.Sum AS Sum,
		|	OtherExpenses.SumMan AS SumMan,
		|	OtherExpenses.SumCompl AS SumCompl,
		|	OtherExpenses.PermanentDifference AS PermanentDifference,
		|	OtherExpenses.CostTD AS CostTD
		|
		|INTO TTOtherExpenses_
		|FROM
		|	Document.AllocationOfIncomeByLinesOfBusiness.Expenses AS OtherExpenses
		|";
	EndIf;
	
	If TypeOf(QueryTexts) = Type("ValueList") Then
		QueryTexts.Add(QueryText, RegisterName);
	EndIf;
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	GenerateTTFinancialResults(Query);
	
	QueryText = "
	|SELECT
	|	&Period                                   AS Period,
	|	VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|	TableExpenses.Organization                AS Organization,
	|	TableExpenses.Department              AS Department,
	|	TableExpenses.InitialDirectionOfActivity AS LineOfBusiness,
	|	TableExpenses.ExpenseItem             AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses          AS DimensionOfExpenses,
	|	VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness) AS BusinessOperation,
	|	TableExpenses.LineOfBusiness    AS CorLineOfBusiness,
	|
	|	SUM(TableExpenses.Expenses)             AS Sum,
	|	SUM(TableExpenses.ManSExpenses)          AS SumMan,
	|	SUM(TableExpenses.LocalExpenses)         AS SumCompl,
	|	SUM(TableExpenses.PermanentDifference)   AS PermanentDifference,
	|	SUM(TableExpenses.CostTD)    AS CostTD,
	|	
	|	TableExpenses.FinRecordID     AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AllocationOfExpensesByLinesOfBusiness) AS BusinessTransactionSetting
	|FROM
	|	TTFinancialResults AS TableExpenses
	|WHERE
	|	TableExpenses.Expenses <> 0
	|	OR TableExpenses.ManSExpenses <> 0
	|	OR TableExpenses.LocalExpenses <> 0
	|	OR TableExpenses.PermanentDifference <> 0
	|	OR TableExpenses.CostTD <> 0
	|
	|GROUP BY
	|	TableExpenses.Organization,
	|	TableExpenses.Department,
	|	TableExpenses.LineOfBusiness,
	|	TableExpenses.ExpenseItem,
	|	TableExpenses.DimensionOfExpenses,
	|	TableExpenses.InitialDirectionOfActivity,
	|	TableExpenses.FinRecordID
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Function QueryTextTableFinancialResults(Query, QueryTexts, Registers)
	
	RegisterName = "FinancialResults";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	GenerateTTFinancialResults(Query);
	
	QueryText = "
	|SELECT
	|	Table.Period                  AS Period,
	|	Table.Recorder             AS Recorder,
	|	Table.LineNumber             AS LineNumber,
	|	Table.Organization             AS Organization,
	|	Table.Department           AS Department,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|	Table.IncomeItem           AS IncomeItem,
	|	Table.ExpenseItem          AS ExpenseItem,
	|	SUM(Table.Income)           AS Income,
	|	SUM(Table.Expenses)          AS Expenses,
	|	Table.LineOfBusinessAllocationMethod     AS LineOfBusinessAllocationMethod
	|FROM
	|	TTFinancialResults AS Table
	|WHERE
	|	&GenerateFinancialResult
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	Table.LineNumber,
	|	Table.Organization,
	|	Table.Department,
	|	Table.LineOfBusiness,
	|	Table.IncomeItem,
	|	Table.ExpenseItem,
	|	Table.LineOfBusinessAllocationMethod
	|HAVING
	|	SUM(Table.Income) <> 0
	|	OR SUM(Table.Expenses) <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Function QueryTextTableIncomeExpensesForDistribution()
	
	QueryText = "
	|SELECT
	|	MAX(TableRevenue.LineNumber) AS LineNumber,
	|	&Period                             AS Period,
	|	TableRevenue.Organization           AS Organization,
	|	TableRevenue.Department         AS Department,
	|	TableRevenue.LineOfBusiness AS InitialDirectionOfActivity,
	|	TableRevenue.IncomeItem         AS IncomeItem,
	|	TableRevenue.DimensionOfRevenue      AS DimensionOfRevenue,
	|	UNDEFINED                        AS ExpenseItem,
	|	UNDEFINED                        AS DimensionOfExpenses,
	|	(CASE
	|		WHEN TableRevenue.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN VALUE(Catalog.AllocationMethodsByLinesOfBusiness.EmptyRef)
	|		ELSE TableRevenue.LineOfBusinessAllocationMethod END) AS LineOfBusinessAllocationMethod,
	|
	|	(CASE
	|		WHEN TableRevenue.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN TableRevenue.LineOfBusiness
	|		WHEN TableRevenue.DimensionOfRevenue REFS Catalog.LinesOfBusiness
	|			THEN TableRevenue.DimensionOfRevenue
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) END) AS LineOfBusiness,
	|	FALSE AS Normalized,
	|
	|	SUM(TableRevenue.Sum)          AS Income,
	|	SUM(TableRevenue.SumMan)       AS ManSIncome,
	|	SUM(TableRevenue.SumCompl)      AS LocalRevenues,
	|	0                                   AS Expenses,
	|	0                                   AS ManSExpenses,
	|	0                                   AS LocalExpenses,
	|	0                                   AS PermanentDifference,
	|	0                                   AS CostTD
	|FROM
	|	TTOtherIncome AS TableRevenue
	|
	|GROUP BY
	|	TableRevenue.Organization,
	|	TableRevenue.Department,
	|	TableRevenue.LineOfBusiness,
	|	TableRevenue.IncomeItem,
	|	TableRevenue.DimensionOfRevenue,
	|	(CASE
	|		WHEN TableRevenue.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN VALUE(Catalog.AllocationMethodsByLinesOfBusiness.EmptyRef)
	|		ELSE TableRevenue.LineOfBusinessAllocationMethod END),
	|	(CASE
	|		WHEN TableRevenue.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN TableRevenue.LineOfBusiness
	|		WHEN TableRevenue.DimensionOfRevenue REFS Catalog.LinesOfBusiness
	|			THEN TableRevenue.DimensionOfRevenue
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) END)
	|
 	|UNION ALL
 	|
	|SELECT
	|	MAX(TableExpenses.LineNumber)    AS LineNumber,
	|	&Period                                 AS Period,
	|	TableExpenses.Organization              AS Organization,
	|	TableExpenses.Department            AS Department,
	|	TableExpenses.LineOfBusiness  AS InitialDirectionOfActivity,
	|	UNDEFINED                            AS IncomeItem,
	|	UNDEFINED                            AS DimensionOfRevenue,
	|	TableExpenses.ExpenseItem           AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses        AS DimensionOfExpenses,
	|	(CASE
	|		WHEN TableExpenses.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN VALUE(Catalog.AllocationMethodsByLinesOfBusiness.EmptyRef)
	|		ELSE TableExpenses.LineOfBusinessAllocationMethod END) AS LineOfBusinessAllocationMethod,
	|
	|	(CASE
	|		WHEN TableExpenses.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN TableExpenses.LineOfBusiness
	|		WHEN TableExpenses.DimensionOfExpenses REFS Catalog.LinesOfBusiness
	|			THEN TableExpenses.DimensionOfExpenses
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) END) AS LineOfBusiness,
	|	TableExpenses.Normalized              AS Normalized,
	|
	|	0                                       AS Income,
	|	0                                       AS ManSIncome,
	|	0                                       AS LocalRevenues,
	|	SUM(TableExpenses.Sum)             AS Expenses,
	|	SUM(TableExpenses.SumMan)          AS ManSExpenses,
	|	SUM(TableExpenses.SumCompl)         AS LocalExpenses,
	|	SUM(TableExpenses.PermanentDifference) AS PermanentDifference,
	|	SUM(TableExpenses.CostTD)  AS CostTD
	|FROM
	|	TTOtherExpenses_ AS TableExpenses
	|
	|GROUP BY
	|	TableExpenses.Organization,
	|	TableExpenses.Department,
	|	TableExpenses.LineOfBusiness,
	|	TableExpenses.ExpenseItem,
	|	TableExpenses.DimensionOfExpenses,
	|	(CASE
	|		WHEN TableExpenses.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN VALUE(Catalog.AllocationMethodsByLinesOfBusiness.EmptyRef)
	|		ELSE TableExpenses.LineOfBusinessAllocationMethod END),
	|	(CASE
	|		WHEN TableExpenses.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN TableExpenses.LineOfBusiness
	|		WHEN TableExpenses.DimensionOfExpenses REFS Catalog.LinesOfBusiness
	|			THEN TableExpenses.DimensionOfExpenses
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) END),
	|	TableExpenses.Normalized
	|ORDER BY
	|	Organization,
	|	Department,
	|	LineOfBusinessAllocationMethod,
	|	IncomeItem,
	|	DimensionOfRevenue,
	|	ExpenseItem,
	|	DimensionOfExpenses
	|";
	
	Return QueryText;
EndFunction

Function QueryTextTableOfDistributionMethods()
	
	QueryText = "
	|SELECT DISTINCT
	|	DocumentData.Organization                              AS Organization,
	|	DocumentData.LineOfBusinessAllocationMethod                      AS LineOfBusinessAllocationMethod,
	|	DistributionMethods.AllocatedAccordingToRule                AS AllocatedAccordingToRule,
	|	(CASE
	|		WHEN DistributionMethods.AllocatedAccordingToRule <>
	|				VALUE(Enum.AllocationRulesByLinesOfBusiness.InProportionToFactors)
	|			THEN TRUE
	|		ELSE FALSE END) AS CalculationMethodAutomatically,
	|	ISNULL(Directions.LineOfBusiness, UNDEFINED) AS LineOfBusiness,
	|	ISNULL(Directions.ZoomRatio, 1) AS ZoomRatio
	|	
	|INTO TableOfDistributionMethods
	|FROM (
	|	SELECT DISTINCT
	|		TableRevenue.Organization AS Organization,
	|		TableRevenue.LineOfBusinessAllocationMethod AS LineOfBusinessAllocationMethod
	|	FROM
	|		TTOtherIncome AS TableRevenue
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		TableExpenses.Organization AS Organization,
	|		TableExpenses.LineOfBusinessAllocationMethod AS LineOfBusinessAllocationMethod
	|	FROM
	|		TTOtherExpenses_ AS TableExpenses
	|	) AS DocumentData
	|	LEFT JOIN Catalog.AllocationMethodsByLinesOfBusiness AS DistributionMethods
	|		ON DistributionMethods.Ref = DocumentData.LineOfBusinessAllocationMethod
	|	
	|	LEFT JOIN Catalog.AllocationMethodsByLinesOfBusiness.LinesOfBusiness AS Directions
	|		ON DocumentData.LineOfBusinessAllocationMethod = Directions.Ref
	|";
	
	Return QueryText;
EndFunction

Function QueryTextTableTurnoverOfIncomeExpenses()
	
	QueryText = "
	|SELECT
	|	FinancialResults.LineOfBusiness AS LineOfBusiness,
	|	SUM(FinancialResults.Income) AS IncomeTurnover,
	|	SUM(FinancialResults.Expenses) AS ExpensesTurnover
	|INTO TurnoverOfIncomeExpenses
	|FROM
	|	AccumulationRegister.FinancialResults AS FinancialResults
	|WHERE
	|	FinancialResults.Period BETWEEN BEGINOFPERIOD(&Period, MONTH) AND ENDOFPERIOD(&Period, MONTH)
	|	AND FinancialResults.Active
	|	AND FinancialResults.Organization IN
	|		(SELECT
	|				TableOfDistributionMethods.Organization
	|			FROM
	|				TableOfDistributionMethods AS TableOfDistributionMethods)
	|	AND (FinancialResults.IncomeItem = VALUE(ChartOfCharacteristicTypes.IncomeItems.SalesRevenue)
	|		OR FinancialResults.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.SaleCost))
	|	AND (FinancialResults.Recorder REFS Document.InventoryCostCalculation
	|		OR FinancialResults.CalculationOfCost)
	|	
	|GROUP BY
	|	FinancialResults.LineOfBusiness
	|
	|INDEX BY
	|	LineOfBusiness
	|";
	
	Return QueryText;
EndFunction

Function QueryTextTableAllocationBases()
	
	QueryText = "
	|SELECT
	|	TableOfDistributionMethods.Organization AS Organization,
	|	TableOfDistributionMethods.LineOfBusinessAllocationMethod AS LineOfBusinessAllocationMethod,
	|	ISNULL(
	|		TurnoverOfIncomeExpenses.LineOfBusiness,
	|		TableOfDistributionMethods.LineOfBusiness) AS LineOfBusiness,
	|
	|	SUM(
	|		CASE WHEN TableOfDistributionMethods.AllocatedAccordingToRule =
	|			VALUE(Enum.AllocationRulesByLinesOfBusiness.InProportionToFactors)
	|		THEN
	|			TableOfDistributionMethods.ZoomRatio
	|
	|		WHEN TableOfDistributionMethods.AllocatedAccordingToRule =
	|			VALUE(Enum.AllocationRulesByLinesOfBusiness.InProportionToSalesRevenue)
	|		THEN
	|			ISNULL(TurnoverOfIncomeExpenses.IncomeTurnover, 0)
	|		
	|		WHEN TableOfDistributionMethods.AllocatedAccordingToRule =
	|			VALUE(Enum.AllocationRulesByLinesOfBusiness.ByCosts)
	|		THEN
	|			ISNULL(TurnoverOfIncomeExpenses.ExpensesTurnover, 0)
	|		
	|		ELSE
	|			ISNULL(TurnoverOfIncomeExpenses.IncomeTurnover - TurnoverOfIncomeExpenses.ExpensesTurnover, 0)
	|		
	|		END
	|	) AS Base
	|FROM
	|	TableOfDistributionMethods AS TableOfDistributionMethods
	|	
	|	LEFT JOIN TurnoverOfIncomeExpenses AS TurnoverOfIncomeExpenses
	|	ON TableOfDistributionMethods.CalculationMethodAutomatically
	|		AND (TableOfDistributionMethods.LineOfBusiness = TurnoverOfIncomeExpenses.LineOfBusiness
	|			OR TableOfDistributionMethods.LineOfBusiness = UNDEFINED)
	|
	|GROUP BY
	| 	TableOfDistributionMethods.Organization,
	| 	TableOfDistributionMethods.LineOfBusinessAllocationMethod,
	|	ISNULL(
	|		TurnoverOfIncomeExpenses.LineOfBusiness,
	|		TableOfDistributionMethods.LineOfBusiness)
	|
	|ORDER BY
	|	Organization,
	| 	LineOfBusinessAllocationMethod,
	| 	LineOfBusiness
	|
	|TOTALS
	|	SUM(Base)
	|BY
	|	Organization,
	| 	LineOfBusinessAllocationMethod
	|";
	
	Return QueryText;
EndFunction

Procedure GenerateTTFinancialResults(Query, OutputMessagesToLog = False, Cancel = False) Export
	
	If Query.TempTablesManager.Tables.Find("TTFinancialResults") <> Undefined Then
		Return;
	EndIf;
	
	DistributionRequest = New Query;
	DistributionRequest.TempTablesManager = Query.TempTablesManager;
	
	QueryTexts = New Array(6);
	QueryTexts[0] = QueryTextTableTTOtherExpenses_(Query);
	QueryTexts[1] = QueryTextTableTTOtherIncome(Query);
	QueryTexts[2] = QueryTextTableOfDistributionMethods();
	QueryTexts[3] = QueryTextTableIncomeExpensesForDistribution();
	QueryTexts[4] = QueryTextTableTurnoverOfIncomeExpenses();
	QueryTexts[5] = QueryTextTableAllocationBases();
	DistributionRequest.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	DistributionRequest.SetParameter("Ref", Query.Parameters.Ref);
	DistributionRequest.SetParameter("Organization", Query.Parameters.Organization);
	DistributionRequest.SetParameter("AllocationByAllCompanies", Query.Parameters.AllocationByAllCompanies);
	DistributionRequest.SetParameter("Period", Query.Parameters.Period);
	DistributionRequest.SetParameter("StartDate_1", Query.Parameters.StartDate_1);
	DistributionRequest.SetParameter("ConDate", Query.Parameters.ConDate);
	DistributionRequest.SetParameter("InitialBorder", Query.Parameters.InitialBorder);
	DistributionRequest.SetParameter("ConBorder", Query.Parameters.ConBorder);
	
	Result = DistributionRequest.ExecuteBatch();
	LargestIndex = Result.UBound();
	TableIncomeExpensesForDistribution  = Result[LargestIndex - 2].Unload();
	QueryResultForDistributionDatabase = Result[LargestIndex];
	
	AllocationResult = DistributeIncomeAndExpensesAcrossDatabase(
		TableIncomeExpensesForDistribution, QueryResultForDistributionDatabase, Query.Parameters.Ref, OutputMessagesToLog, Cancel);
	
	DataRequest = New Query("
	|SELECT
	|	Table.Period                  AS Period,
	|	Table.Recorder             AS Recorder,
	|	Table.LineNumber             AS LineNumber,
	|	Table.Organization             AS Organization,
	|	Table.Department           AS Department,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|	Table.InitialDirectionOfActivity AS InitialDirectionOfActivity,
	|	Table.IncomeItem           AS IncomeItem,
	|	Table.DimensionOfRevenue        AS DimensionOfRevenue,
	|	Table.ExpenseItem          AS ExpenseItem,
	|	Table.DimensionOfExpenses       AS DimensionOfExpenses,
	|	Table.Income                  AS Income,
	|	Table.ManSIncome               AS ManSIncome,
	|	Table.LocalRevenues              AS LocalRevenues,
	|	Table.Expenses                 AS Expenses,
	|	Table.ManSExpenses              AS ManSExpenses,
	|	Table.LocalExpenses             AS LocalExpenses,
	|	Table.PermanentDifference       AS PermanentDifference,
	|	Table.CostTD        AS CostTD,
	|	Table.LineOfBusinessAllocationMethod     AS LineOfBusinessAllocationMethod,
	|	Table.FinRecordID  AS FinRecordID
	|INTO TTFinancialResults
	|FROM
	|	&TableFinancialResults AS Table
	|");
	DataRequest.TempTablesManager = Query.TempTablesManager;
	DataRequest.SetParameter("TableFinancialResults", AllocationResult);
	DataRequest.Execute();
	
EndProcedure

// The function distributes income and expenses across the distribution base.
//
// Parameters:
//	TableFinancialResults - ValueTable - table with columns:
//		* LineNumber - Number - line number of the table part of the document 
//
Function DistributeIncomeAndExpensesAcrossDatabase(TableFinancialResults, DatabaseQueryResult, DocumentReference, OutputMessagesToLog, Cancel)
	
	RecordSet = AccumulationRegisters.FinancialResults.CreateRecordSet().UnloadColumns();
	RecordSet.Columns.Add("InitialDirectionOfActivity", Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.Dimensions.CorLineOfBusiness.Type);
	RecordSet.Columns.Add("DimensionOfRevenue", Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.Dimensions.DimensionOfRevenue.Type);
	RecordSet.Columns.Add("DimensionOfExpenses", Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.Dimensions.DimensionOfExpenses.Type);
	RecordSet.Columns.Add("ManSIncome", Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.Resources.SumMan.Type);
	RecordSet.Columns.Add("LocalRevenues", Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.Resources.SumMan.Type);
	RecordSet.Columns.Add("ManSExpenses", Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.Resources.SumMan.Type);
	RecordSet.Columns.Add("LocalExpenses", Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.Resources.SumMan.Type);
	RecordSet.Columns.Add("PermanentDifference", Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.Resources.SumMan.Type);
	RecordSet.Columns.Add("CostTD", Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.Resources.SumMan.Type);
	RecordSet.Columns.Add("FinRecordID", Common.StringTypeDetails(36));
	RecordSet.Columns.Delete("Active");
	
	If TableFinancialResults.Count() = 0 Or DatabaseQueryResult.IsEmpty() Then
		Return RecordSet;
	EndIf;
	
	GenerateFinancialResult = GetFunctionalOption("GenerateFinancialResult");
	
	LanguageCode = Metadata.DefaultLanguage.LanguageCode;
	
	SummaryResources = New Structure("Income, ManSIncome, LocalRevenues, Expenses, ManSExpenses, LocalExpenses, PermanentDifference, CostTD");
	
	// Selection of distribution database rows by distribution method.
	SelectionByOrganization = DatabaseQueryResult.Select(QueryResultIteration.ByGroups);
	
	While SelectionByOrganization.Next() Do
		
		SamplingByDistributionMethod = SelectionByOrganization.Select(QueryResultIteration.ByGroups);
		
		While SamplingByDistributionMethod.Next() Do
			
			FilterStructure1 = New Structure;
			FilterStructure1.Insert("Organization", SamplingByDistributionMethod.Organization);
			FilterStructure1.Insert("LineOfBusinessAllocationMethod", SamplingByDistributionMethod.LineOfBusinessAllocationMethod);
			
			// We get an array of expenses that have the same analytics index corresponding to the current sample of the distribution base.
			// These costs will be distributed on the same distribution basis.
			ArrayOfTableRows = TableFinancialResults.FindRows(FilterStructure1);
			If ArrayOfTableRows.Count() = 0 Then
				Continue;
			EndIf;
			
			If SamplingByDistributionMethod.Base = 0
			 And ValueIsFilled(SamplingByDistributionMethod.LineOfBusinessAllocationMethod)
			 And GenerateFinancialResult Then
			
				If ArrayOfTableRows[0].Income <> 0
				 Or ArrayOfTableRows[0].LocalRevenues <> 0
				 Or ArrayOfTableRows[0].ManSIncome <> 0 Then
					
					Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không có cơ sở để phân bổ thu nhập theo phương pháp phân bổ ""%1"". Hãy chỉ ra phương thức phân bổ khác hoặc xóa dòng thu nhập khỏi chứng từ.';
							|ru = 'Отсутствует база для распределения доходов по способу распределения ""%1"". Укажите другой способ распределения или удалите строку доходов из документа.';
							|en = 'No base for income allocation according to the ""%1"" allocation method. Specify another allocation method or delete the income line from the document.'; fa = 'No base for income allocation according to the ""%1"" allocation method. Specify another allocation method or delete the income line from the document.';
							|it = 'Manca la base per la ripartizione di entrate secondo il metodo di ripartizione ""%1"". Indicate un altro metodo di ripartizione o eliminate la riga di entrate dal documento.';
							|pl = 'Nie ma bazy do przydziału dochodów według metody przydziału ""%1"". Określ inną metodę przydziału lub usuń wiersz dochodów z dokumentu.';
							|tr = '""%1"" dağıtım yöntemine göre gelir dağıtımı için bir taban yok. Başka bir dağıtım yöntemi belirt veya gelir satırını belgeden sil.'", LanguageCode),
						SamplingByDistributionMethod.LineOfBusinessAllocationMethod);
					
					If OutputMessagesToLog Then
						WriteLogEvent(
							NStr("vi = 'Lỗi khi kết chuyển chứng từ';
								|ru = 'Ошибка при проведении документа';
								|en = 'An error occurred while posting the document'; fa = 'An error occurred while posting the document';
								|it = 'Errore durante la registrazione del documento';
								|pl = 'Błąd podczas zaksięgowania dokumentu';
								|tr = 'Belge kaydı sırasında hata'", LanguageCode), 
							EventLogLevel.Error,
							Metadata.Documents.AllocationOfIncomeByLinesOfBusiness,
							DocumentReference,
							Text,
							EventLogEntryTransactionMode.Transactional);
					Else
						TableRow = ArrayOfTableRows[0]; // ValueTableRow
						Common.MessageToUser(
							Text,
							DocumentReference);
					EndIf;
					
				EndIf;
				
				If ArrayOfTableRows[0].Expenses <> 0
				 Or ArrayOfTableRows[0].LocalExpenses <> 0
				 Or ArrayOfTableRows[0].ManSExpenses <> 0
				 Or ArrayOfTableRows[0].PermanentDifference <> 0
				 Or ArrayOfTableRows[0].CostTD <> 0 Then
					
					Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không có cơ sở để phân bổ chi phí theo phương pháp phân bổ ""%1"". Hãy chỉ ra một phương thức phân bổ khác hoặc xóa dòng chi phí khỏi chứng từ.';
							|ru = 'Отсутствует база для распределения расходов по способу распределения ""%1"". Укажите другой способ распределения или удалите строку расходов из документа.';
							|en = 'No base for expense allocation according to the ""%1"" allocation method. Specify another allocation method or delete the expense line from the document.'; fa = 'No base for expense allocation according to the ""%1"" allocation method. Specify another allocation method or delete the expense line from the document.';
							|it = 'Manca la base per la ripartizione delle uscite in base al metodo di ripartizione ""%1"". Indicate un altro metodo di ripartizione o eliminate la riga di uscite dal documento.';
							|pl = 'Nie ma bazy do przydziału wydatków według metody przydziału ""%1"". Określ inną metodę przydziału lub usuń wiersz dochodów z dokumentu.';
							|tr = '""%1"" dağıtım yöntemine göre giderlerin dağıtımı için bir taban yok. Başka bir dağıtım yöntemi belirti veya gider satırını belgeden sil.'", LanguageCode),
						SamplingByDistributionMethod.LineOfBusinessAllocationMethod);
					
					If OutputMessagesToLog Then
						WriteLogEvent(
							NStr("vi = 'Lỗi khi kết chuyển chứng từ';
								|ru = 'Ошибка при проведении документа';
								|en = 'An error occurred while posting the document'; fa = 'An error occurred while posting the document';
								|it = 'Errore durante la registrazione del documento';
								|pl = 'Błąd podczas zaksięgowania dokumentu';
								|tr = 'Belge kaydı sırasında hata'", LanguageCode), 
							EventLogLevel.Error,
							Metadata.Documents.AllocationOfIncomeByLinesOfBusiness,
							DocumentReference,
							Text,
							EventLogEntryTransactionMode.Transactional);
					Else
						TableRow = ArrayOfTableRows[0]; // ValueTableRow
						Common.MessageToUser(
							Text,
							DocumentReference);
					EndIf;
					
				EndIf;
				
			EndIf;
			
			Selection = SamplingByDistributionMethod.Select(QueryResultIteration.ByGroups);
		
			For Each TableRow In ArrayOfTableRows Do
				
				If ValueIsFilled(TableRow.LineOfBusiness)
				 Or SamplingByDistributionMethod.Base = 0
				 Or Not GenerateFinancialResult Then
					
					NewRecord = RecordSet.Add();
					
					FillPropertyValues(NewRecord, TableRow);
					NewRecord.FinRecordID = String(New UUID());
					NewRecord.LineOfBusinessAllocationMethod = Undefined;
					
				Else
			
					FillPropertyValues(SummaryResources, TableRow);
					DatabaseOfEverything = SamplingByDistributionMethod.Base;
				
					// Selection of rows of the distribution base by the index of the distribution base
					Selection.Reset();
					While Selection.Next() Do
					
						NewRecord = RecordSet.Add();
						FillPropertyValues(NewRecord, TableRow);
						NewRecord.FinRecordID  = String(New UUID());
						NewRecord.LineOfBusiness = Selection.LineOfBusiness;
						
						Basis = ?(DatabaseOfEverything <> 0, Selection.Base / DatabaseOfEverything, 0);
						For Each ResourceName In SummaryResources Do
							NewRecord[ResourceName.Key] = Round(Basis * ResourceName.Value, 2, 1);
							SummaryResources[ResourceName.Key] = ResourceName.Value - NewRecord[ResourceName.Key];
						EndDo;
						
						DatabaseOfEverything = DatabaseOfEverything - Selection.Base;
					
					EndDo;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Return RecordSet;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	GenerateTTFinancialResults(Query);
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	FinancialResults.Organization AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	FinancialResults.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	SUM(FinancialResults.Expenses) AS Sum
	|FROM
	|	TTFinancialResults AS FinancialResults
	|
	|WHERE
	|	NOT FinancialResults.Expenses = 0
	|
	|GROUP BY
	|	FinancialResults.Organization,
	|	FinancialResults.LineOfBusiness
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Function QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	GenerateTTFinancialResults(Query);
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	VALUE(Enum.BusinessTransactions.AllocationOfIncomeByLinesOfBusiness) AS BusinessOperation,
	|	FinancialResults.Organization AS Organization,
	|
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	FinancialResults.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	FinancialResults.Organization AS AssetsLiabilitiesDimension,
	|
	|	FinancialResults.Department AS DebitBusinessUnit,
	|	FinancialResults.InitialDirectionOfActivity AS CorLineOfBusiness,
	|	FinancialResults.IncomeItem AS CorItem,
	|	FinancialResults.DimensionOfRevenue AS CorIncomeDimension,
	|	UNDEFINED AS CorExpenditureDimension,
	|	UNDEFINED AS CorDimensionOfAssetsLiabilities,
	|
	|	SUM(FinancialResults.Income) AS Sum,
	|	SUM(FinancialResults.ManSIncome) AS SumMan,
	|	SUM(FinancialResults.LocalRevenues) AS SumCompl
	|FROM
	|	TTFinancialResults AS FinancialResults
	|
	|WHERE
	|	FinancialResults.Income <> 0
	|	OR FinancialResults.ManSIncome <> 0
	|	OR FinancialResults.LocalRevenues <> 0
	|
	|GROUP BY
	|	FinancialResults.Organization,
	|	FinancialResults.Department,
	|	FinancialResults.InitialDirectionOfActivity,
	|	FinancialResults.LineOfBusiness,
	|	FinancialResults.IncomeItem,
	|	FinancialResults.DimensionOfRevenue
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness) AS BusinessOperation,
	|	FinancialResults.Organization AS Organization,
	|
	|	FinancialResults.Department AS Department,
	|	FinancialResults.InitialDirectionOfActivity AS LineOfBusiness,
	|	FinancialResults.ExpenseItem AS AssetRef,
	|	UNDEFINED AS DimensionOfRevenue,
	|	FinancialResults.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS DebitBusinessUnit,
	|	FinancialResults.LineOfBusiness AS CorLineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS CorItem,
	|	UNDEFINED AS CorIncomeDimension,
	|	UNDEFINED AS CorExpenditureDimension,
	|	FinancialResults.Organization AS CorDimensionOfAssetsLiabilities,
	|
	|	SUM(FinancialResults.Expenses) AS Sum,
	|	SUM(FinancialResults.ManSExpenses) AS SumMan,
	|	SUM(FinancialResults.LocalExpenses) AS SumCompl
	|FROM
	|	TTFinancialResults AS FinancialResults
	|
	|WHERE
	|	FinancialResults.Expenses <> 0
	|	OR FinancialResults.ManSExpenses <> 0
	|	OR FinancialResults.LocalExpenses <> 0
	|
	|GROUP BY
	|	FinancialResults.Organization,
	|	FinancialResults.Department,
	|	FinancialResults.InitialDirectionOfActivity,
	|	FinancialResults.LineOfBusiness,
	|	FinancialResults.ExpenseItem,
	|	FinancialResults.DimensionOfExpenses
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	GenerateTTFinancialResults(Query);
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	FinancialResults.Organization AS Organization,
	|	FinancialResults.Department AS Department,
	|	FinancialResults.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	SUM(FinancialResults.LocalExpenses)       AS SumCompl,
	|	SUM(FinancialResults.ManSExpenses)        AS SumMan,
	|	SUM(FinancialResults.ManSExpenses)        AS AmountIncludingVAT,
	|	SUM(FinancialResults.ManSExpenses)        AS AmountExcludingVAT,
	|	SUM(FinancialResults.PermanentDifference) AS PermanentDifference,
	|	SUM(FinancialResults.CostTD)  AS CostTD,
	|
	|	FinancialResults.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AllocationOfExpensesByLinesOfBusiness) AS BusinessTransactionSetting
	|FROM
	|	TTFinancialResults AS FinancialResults
	|WHERE
	|	FinancialResults.ManSExpenses <> 0
	|	OR FinancialResults.LocalExpenses <> 0
	|	OR FinancialResults.PermanentDifference <> 0
	|	OR FinancialResults.CostTD <> 0
	|GROUP BY
	|	FinancialResults.Organization,
	|	FinancialResults.Department,
	|	FinancialResults.LineOfBusiness,
	|	FinancialResults.FinRecordID
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier AS RefType,
	|	&HouseholdOperationForRegistry AS BusinessOperation,
	|	&Organization AS Organization,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	UNDEFINED AS Author,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Comment AS Comment,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	&Period AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	0 AS Sum,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.AllocationOfIncomeByLinesOfBusiness";
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.AllocationOfIncomeByLinesOfBusiness"));
	ParameterValues.Insert("HouseholdOperationForRegistry", Enums.BusinessTransactions.AllocationOfIncomeByLinesOfBusiness);
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText, FullDocumentName, SynonymForDocumentTable, False);
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

#Region BlockingWhenUpdatingInformationSecurity

Procedure CheckBlockingIncomingDataWhenUpdatingInformationSecurity(PresentationOperation)
	
	IncomingData = New Map;
	
	IncomingData.Insert(Metadata.Documents.AllocationOfIncomeByLinesOfBusiness);
	IncomingData.Insert(Metadata.AccumulationRegisters.OtherIncome);
	IncomingData.Insert(Metadata.AccumulationRegisters.OtherExpenses);
	
	MonthEndTransactionsServer.CheckBlockingIncomingDataWhenUpdatingInformationSecurity(IncomingData, PresentationOperation);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
