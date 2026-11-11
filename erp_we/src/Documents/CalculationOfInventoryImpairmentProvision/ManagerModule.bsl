#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Calculates reserves for inventory impairment.
// Parameters:
// 	Period - Date - the period of allocation of costs.
//	Companies - Array - list of organizations to distribute to.
Procedure CalculateReserves(Period, Companies) Export
	
	KeyOperation = "MonthEndTransactions.CalculationOfInventoryImpairmentProvision";
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
	NumberOfProcessedData = 0;
	
	TempTablesManager = New TempTablesManager;
	
	CreateAnalyticsKeysForPartners(Companies, Period);
	ClearRegisteredRecordsOnReserveDocuments(Period, Companies, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = QueryTextRules_();
	
	Query.SetParameter("Period", Period);
	Query.SetParameter("Companies", Companies);
	Query.SetParameter("CompanyManagementAccounting", CalculationOfCostCached.CompanyManagementAccounting(Period));
	Query.SetParameter("BatchAccountingVersion22", CalculationOfCostCached.BatchAccountingVersion22(Period));
	
	Result = Query.Execute();
	SelectionByOrganization_ = Result.Select(QueryResultIteration.ByGroups);
	While SelectionByOrganization_.Next() Do
		
		Recorder = SelectionByOrganization_.Recorder;
		If Recorder = Undefined Then
			
			ReserveDocument = Documents.CalculationOfInventoryImpairmentProvision.CreateDocument();
			ReserveDocument.Organization = SelectionByOrganization_.Organization;
			ReserveDocument.Date = Period;
			ReserveDocument.Write(DocumentWriteMode.Posting);
			
			Recorder = ReserveDocument.Ref;
			
		EndIf;
		
		Selection = SelectionByOrganization_.Select();
		
		TempTablesManager = New TempTablesManager;
		NumberOfTemporaryTables = 
			Catalogs.RulesForCalculationOfInventoryImpairmentProvision.CreateTemporaryTablesOfBalancesByRules(
				Selection, 
				New Boundary(Period, BoundaryType.Including), 
				TempTablesManager,
				True);
					
		BeginTransaction();
		Try
			
				
			If NumberOfTemporaryTables <> 0 Then
							
				PutParameters = New Structure;
				PutParameters.Insert("TempTableName", "TableOfBalancesByRule");
				PutParameters.Insert("TemporaryTableNumber", NumberOfTemporaryTables);
					
				Data = GenerateSummaryTableOfReserves(TempTablesManager, PutParameters);
				NumberOfProcessedData = Data.Count();
				
				TMCommonUse.AddIdentifiersToValueTable(Data);	
			
				RecordSet = AccumulationRegisters.InventoryCost.CreateRecordSet();
				RecordSet.AdditionalProperties.Insert(CostCalculationAppliedAlgorithms.NameOfObjectSServiceAdditionalProperty());
				RecordSet.Filter.Recorder.Set(Recorder);
				RecordSet.Write = True;
				RecordSet.Load(Data);
				RecordSet.Write();
				
				Data.Columns.Delete(Data.Columns.Find("ProvisionForImpairmentLocal"));
				Data.Columns.Delete(Data.Columns.Find("ProvisionForImpairmentMan"));
				Data.Columns.Find("ProvisionForImpairmentOfLocalRevenue").Name = "ProvisionForImpairmentLocal";
				Data.Columns.Find("ProvisionForImpairmentOfManRevenue").Name = "ProvisionForImpairmentMan";
				
				RecordSet = AccumulationRegisters.RevenueAndCOGS.CreateRecordSet();
				RecordSet.AdditionalProperties.Insert(CostCalculationAppliedAlgorithms.NameOfObjectSServiceAdditionalProperty());
				RecordSet.Filter.Recorder.Set(Recorder);
				RecordSet.Write = True;
				RecordSet.Load(Data);
				RecordSet.Write();
				
			Else
				
				RecordSet = AccumulationRegisters.InventoryCost.CreateRecordSet();
				RecordSet.AdditionalProperties.Insert(CostCalculationAppliedAlgorithms.NameOfObjectSServiceAdditionalProperty());
				RecordSet.Filter.Recorder.Set(Recorder);
				RecordSet.Write = True;
				RecordSet.Write();
				
				RecordSet = AccumulationRegisters.RevenueAndCOGS.CreateRecordSet();
				RecordSet.AdditionalProperties.Insert(CostCalculationAppliedAlgorithms.NameOfObjectSServiceAdditionalProperty());
				RecordSet.Filter.Recorder.Set(Recorder);
				RecordSet.Write = True;
				RecordSet.Write();
			
			EndIf;
			DocumentsToBeReflected = GenerateTableOfDocumentsToBeReflected(Recorder, SelectionByOrganization_.Organization, Period);
			FinancialAccountingPostingServer.ReturnDocumentsToReflection(DocumentsToBeReflected);
			InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(
				AddMonth(BegOfMonth(Period), 1),
				Recorder, 
				SelectionByOrganization_.Organization);
			
			If SelectionByOrganization_.Recorder <> Undefined Then
				CalculationOfInventoryImpairmentProvisionLocalization.RegisterDocumentReflection(Recorder);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = NStr("vi = 'Không thể tính dự phòng theo doanh nghiệp ""%1"" do nguyên nhân: %2';
								|ru = 'Не удалось рассчитать резервы по организации ""%1"" по причине: %2';
								|en = 'Cannot calculate provisions of ""%1"" company. Reason: %2'; fa = 'Cannot calculate provisions of ""%1"" company. Reason: %2';
								|it = 'Impossibile calcolare le scorte per l''azienda ""%1"" a causa di: %2';
								|pl = 'Nie udało się rozliczyć rezerw według firmy ""%1"" z powodu: %2';
								|tr = '""%1"" iş yeri için rezervler şu sebepten dolayı hesaplanamadı: %2'");
			MessageText = StrTemplate(MessageText, SelectionByOrganization_.Organization, DetailErrorDescription(ErrorInfo()));
				
			RegistrationParameters = MonthEndTransactionsServer.InitializeParametersForRegisteringCalculationProblem(
				Catalogs.MonthEndClosingOperations.AccualOfInventoryImpairmentProvision,
				SelectionByOrganization_.Organization,
				Period);
			
			MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
				RegistrationParameters,
				NStr("vi = 'Khi tính dự phòng giảm giá đã xảy ra lỗi.';
					|ru = 'При расчете резервов под обесценение диагностированы ошибки.';
					|en = 'Errors were detected when calculating provisions for impairment.'; fa = 'Errors were detected when calculating provisions for impairment.';
					|it = 'Durante il calcolo delle scorte in deterioramento sono stati rilevati degli errori.';
					|pl = 'Przy rozliczeniu rezerw pod utratę wartości wykryto błędy.';
					|tr = 'Değer düşüklüğü rezervlerinin hesaplanmasında hatalar tespit edildi.'", Common.DefaultLanguageCode()),
				"",
				MessageText,
				Selection.Recorder);
			
		EndTry;
		
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, NumberOfProcessedData / 1000);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	
	CalculationOfInventoryImpairmentProvisionLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
// 	See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.CalculationOfInventoryImpairmentProvision") Then
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
		
		QueryTextTableDocumentPostingInFinancialAccounting(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		CalculationOfInventoryImpairmentProvisionLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

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

#Region LocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//   String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CalculationOfInventoryImpairmentProvisionLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//   String - The text of the temporary table query.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return CalculationOfInventoryImpairmentProvisionLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region HandlersForMonthClosingStages

#Region AccualOfInventoryImpairmentProvision

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
//
Procedure AddStage_AccualOfInventoryImpairmentProvision(StepsTable, CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.AccualOfInventoryImpairmentProvision);
	PreviousStages_ = NewRow.PreviousStages_; // Array
	PreviousStages_.Add(Catalogs.MonthEndClosingOperations.LotsAndCostCalculation);
	
	NewRow.MultilingualName = "vi = 'Lập dự phòng giảm giá hàng tồn kho';
								|ru = 'Формирование резервов под обесценение запасов';
								|en = 'Generate provisions for impairment of inventory';
								|it = 'Creazione delle scorte in deterioramento';
								|pl = 'Utworzenie rezerw pod utratę wartości zapasów';
								|tr = 'Stok değer düşüklüğü rezervlerinin oluşturma'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Lập báo cáo';
								|ru = 'Сформировать';
								|en = 'Generate'; fa = 'ایجاد';
								|it = 'Creare';
								|pl = 'Generate';
								|tr = 'Oluştur'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.CalculationOfInventoryImpairmentProvision.Use_ProvisionForImpairmentOfInventories");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"Documents.CalculationOfInventoryImpairmentProvision.Perform_FormationOfReservesForImpairmentOfInventories");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.CalculationOfInventoryImpairmentProvision.Forms.ListForm.FullName());
	 	
EndProcedure

// Stage handlers.

Procedure Use_ProvisionForImpairmentOfInventories(HandlerParameters) Export
	
	If Not GetFunctionalOption("AccualInventoryImpairmentProvision") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không sử dụng lập dự phòng giảm giá vật tư.';
				|ru = 'Формирование резервов под обесценение запасов не используется.';
				|en = 'Generation of provisions for impairment of inventory is not used.'; fa = 'Generation of provisions for impairment of inventory is not used.';
				|it = 'Non è utilizzata la creazione di riserve in deterioramento.';
				|pl = 'Utworzenie rezerw pod utratę wartości zapasów nie jest używane.';
				|tr = 'Stok değer düşüklüğü rezervleri kullanılmıyor.'", Common.DefaultLanguageCode()));
	
		Return;
		
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text = "
	|SELECT TOP 1
	|	Rules.Ref AS Rule
	|FROM
	|	Catalog.RulesForCalculationOfInventoryImpairmentProvision AS Rules
	|WHERE
	|	&BatchAccountingVersion22
	|	AND BEGINOFPERIOD(Rules.ValidOnDate, MONTH) <= &BeginOfPeriod
	|	AND (ENDOFPERIOD(Rules.ValidToDate, MONTH) >= &EndOfPeriod
	|		OR Rules.ValidToDate = DATETIME(1,1,1))
	|	AND (Rules.LocalAccounting
	|		OR Rules.ManagementAccounting)
	|";
	
	QueryResult = Query.Execute();
	
	ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(Metadata.Reports.StatementOfInventoryImpairmentProvisionChange.FullName() + ".Form", True);
	ActionMoreDetails.FormParameters.Insert("GenerateOnOpen", True);
	ActionMoreDetails.FormParameters.Insert("AllCompanies", HandlerParameters.CalculationParameters.AllCompanies);
	ThereIsTaskForCalculation = MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, True,,, ActionMoreDetails);
	
	If QueryResult.IsEmpty() Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần lập dự phòng giảm giá hàng tồn kho vào cuối kỳ %1';
					|ru = 'Не требуется формирование резервов под обесценение запасов на конец периода %1';
					|en = 'Generation of provisions for impairment of inventory at the end of period %1 is not required'; fa = 'Generation of provisions for impairment of inventory at the end of period %1 is not required';
					|it = 'Non è richiesta la creazione di scorte in deterioramento alla fine del periodo %1';
					|pl = 'Nie wymaga się tworzenia rezerw pod utratę wartości zapasów na koniec okresu %1';
					|tr = 'Dönem sonunda stok değer düşüklüğü için rezerv ayrılmasına gerek yoktur %1'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(HandlerParameters.CalculationParameters.RegistrationPeriod)));
		
	ElsIf ThereIsTaskForCalculation Then
		
		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Cần lập dự phòng giảm giá hàng tồn kho vào cuối kỳ %1.';
					|ru = 'Требуется сформировать резервы под обесценение запасов на конец периода %1.';
					|en = 'Generate provisions for impairment of inventory at the end of period %1.'; fa = 'Generate provisions for impairment of inventory at the end of period %1.';
					|it = 'È richiesta la creazione di scorte in deterioramento alla fine del periodo %1.';
					|pl = 'Wymagane jest utworzenie rezerw pod utratę wartości zapasów na konie okresu %1.';
					|tr = 'Dönem sonu stok değer düşüklüğü rezervlerinin %1 olması gerekmektedir.'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(HandlerParameters.CalculationParameters.RegistrationPeriod)));
		
	EndIf;
	
EndProcedure

Procedure Perform_FormationOfReservesForImpairmentOfInventories(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	BeginOfPeriod = BegOfMonth(CalculationParameters.RegistrationPeriod);
	EndOfPeriod  = EndOfMonth(CalculationParameters.RegistrationPeriod);
	
	TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber();
	
	BeginTransaction();
	
	Try
		
		MonthEndTransactionsServer.BlockTaskRegister(TaskNumberBeforeCalculation, CalculationParameters.CompanyArray, HandlerParameters.Data_Stage.Code);
		
		DataToDistribution = MonthEndTransactionsServer.MonthlyTasks(
			BeginOfPeriod,
			EndOfPeriod,
			TaskNumberBeforeCalculation,
			CalculationParameters.CompanyArray,
			HandlerParameters.Data_Stage.Code);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
				|%2';
				|ru = 'При выполнении расчета за период %1 произошла ошибка:
				|%2';
				|en = 'An error occurred when calculating for the %1 period:
				|%2'; fa = 'An error occurred when calculating for the %1 period:
				|%2';
				|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
				|%2';
				|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
				|%2';
				|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
				|%2'"),
			CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
			DetailErrorDescription(ErrorInfo()));
		
		MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
			HandlerParameters,
			ErrorText,
			CalculationParameters.CompanyArray,
			CalculationParameters.RegistrationPeriod);
		
	EndTry;
	
	CalculatedOrganizations = New Array;
	For Each CurrentCompany In CalculationParameters.CompanyArray Do
		
		Try
			
			Documents.CalculationOfInventoryImpairmentProvision.CalculateReserves(
				EndOfPeriod, 
				CurrentCompany);
				
			If Not DataToDistribution.Organization.Find(CurrentCompany) = Undefined
				And CalculatedOrganizations.Find(CurrentCompany) = Undefined Then
				CalculatedOrganizations.Add(CurrentCompany);
			EndIf;
			
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lập dự phòng giảm giá hàng tồn kho vào cuối kỳ %1 đã xảy ra lỗi:
					|%2';
					|ru = 'Формирование резервов под обесценение запасов на конец периода %1 завершилось с ошибкой:
					|%2';
					|en = 'An error:
					|%2 occurred when generating provisions for impairment of inventory at the end of period %1'; fa = 'An error:
					|%2 occurred when generating provisions for impairment of inventory at the end of period %1';
					|it = 'La creazione di scorte in deterioramento alla fine del periodo %1 è stata eseguita con errori:
					|%2';
					|pl = 'Tworzenie rezerw pod utratę wartości zapasów na koniec okresu %1 zostało zakończone z błędem:
					|%2';
					|tr = 'Dönem sonu stok değer düşüklüğü rezervleri %1 hata ile sona erdi:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(BeginOfPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				CurrentCompany);
			
		EndTry;
			
	EndDo;
	
	If CalculatedOrganizations.Count() > 0 Then
		
		BeginTransaction();
		
		Try
			
			MonthEndTransactionsServer.BlockTaskRegister(
				TaskNumberBeforeCalculation,
				CalculatedOrganizations,
				HandlerParameters.Data_Stage.Code);
			
			MonthEndTransactionsServer.FixCalculation(
				AddMonth(BeginOfPeriod, 1),
				HandlerParameters.Data_Stage.Code,
				DataToDistribution.TemporaryTable);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
					|%2';
					|ru = 'При выполнении расчета за период %1 произошла ошибка:
					|%2';
					|en = 'An error occurred when calculating for the %1 period:
					|%2'; fa = 'An error occurred when calculating for the %1 period:
					|%2';
					|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
					|%2';
					|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
					|%2';
					|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
					|%2'"),
				CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				CalculatedOrganizations,
				CalculationParameters.RegistrationPeriod);
			
		EndTry;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	CalculationOfInventoryImpairmentProvisionLocalization.AddPrintCommands(PrintCommands);

EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.StatementOfInventoryImpairmentProvisionChange.AddReportCommand(ReportsCommands);
	Reports.StatementOfInventoryImpairmentProvision.AddReportCommand(ReportsCommands);
	CalculationOfInventoryImpairmentProvisionLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#EndRegion

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export

	CalculationOfInventoryImpairmentProvisionLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "calculating the cost of goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 
// Returns:
//  Undefined 
//
Function AddGenerateCommand(GenerationCommands) Export

	Return Undefined;
EndFunction

#EndRegion

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Period,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Comment AS Comment
	|FROM
	|	Document.CalculationOfInventoryImpairmentProvision AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("MetadataIdentifier",
								Common.MetadataObjectID(Type("DocumentRef.CalculationOfInventoryImpairmentProvision")));
								
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("HouseholdOperationForRegistry", Enums.BusinessTransactions.CalculationOfInventoryImpairmentProvision);
	
EndProcedure

Function QueryTextTableDocumentPostingInFinancialAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText =
	"SELECT
	|	&Period 	 				 AS Period,
	|	&Organization 				 AS Organization,
	|	BEGINOFPERIOD(&Period, DAY) AS DateRecord
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

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
	|	UNDEFINED AS EmployeeResponsible,
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
	
	FullDocumentName = "Document.CalculationOfInventoryImpairmentProvision";
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.CalculationOfInventoryImpairmentProvision"));
	ParameterValues.Insert("HouseholdOperationForRegistry", Enums.BusinessTransactions.CalculationOfInventoryImpairmentProvision);
	
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

#Region CalculationOfReserves

Procedure CreateAnalyticsKeysForPartners(Companies, Period)
	
	Query = New Query;
	Query.Text = "
		|SELECT DISTINCT
		|	Balance.Organization AS Organization,
		|	ISNULL(Balance.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|		VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness
		|INTO TTBalanceAnalytics
		|FROM
		|	AccumulationRegister.InventoryCost.Balance(&Period, Organization IN (&Companies)) AS Balance
		|INDEX BY
		|	Organization,
		|	LineOfBusiness
		|;
		|SELECT
		|	Balance.Organization AS Organization,
		|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
		|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
		|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
		|	Balance.LineOfBusiness AS LineOfBusiness
		|FROM
		|	TTBalanceAnalytics AS Balance
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionPartner_
		|		ON (DimensionPartner_.Partner = VALUE(Catalog.Partners.EmptyRef))
		|		AND (DimensionPartner_.Organization = Balance.Organization)
		|		AND (DimensionPartner_.Counterparty = VALUE(Catalog.Counterparties.EmptyRef))
		|		AND (DimensionPartner_.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
		|		AND (DimensionPartner_.LineOfBusiness = Balance.LineOfBusiness)
		|WHERE
		|	DimensionPartner_.DimensionKey IS NULL";
	
	Query.SetParameter("Companies", Companies);
	Query.SetParameter("Period", New Boundary(Period, BoundaryType.Including));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
EndProcedure

Procedure ClearRegisteredRecordsOnReserveDocuments(Period, Companies, TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
		"SELECT
		|	Reserves.Ref AS Recorder,
		|	Companies.Ref AS Organization
		|INTO ReserveDocuments
		|FROM
		|	Catalog.Companies AS Companies
		|		INNER JOIN Document.CalculationOfInventoryImpairmentProvision AS Reserves
		|		ON Companies.Ref = Reserves.Organization
		|			AND Reserves.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|			AND Reserves.Posted
		|WHERE
		|	Companies.Ref IN (&Companies)
		|;
		|
		|SELECT
		|	T.Recorder
		|FROM
		|	ReserveDocuments AS T";
		
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Period));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Period));
	Query.SetParameter("Companies", Companies);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.InventoryCost.RecordSet");
			LockItem = Block.Add("AccumulationRegister.RevenueAndCOGS.RecordSet");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.SetValue("Recorder", Selection.Recorder);
			
			Block.Lock();
			
			RecordSet = AccumulationRegisters.InventoryCost.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Selection.Recorder);
			RecordSet.Write();
		
			RecordSet = AccumulationRegisters.RevenueAndCOGS.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Selection.Recorder);
			RecordSet.Write();
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = NStr("vi = 'Không thể xóa bản ghi kết chuyển theo biểu ghi ""Giá vốn hàng hóa"" và ""Doanh thu và giá vốn hàng bán"" của chứng từ ""%1"" do nguyên nhân: %2';
								|ru = 'Не удалось очистить движения по регистрам ""Себестоимость товаров"" и ""Выручка и себестоимость продаж"" документа ""%1"" по причине: %2';
								|en = 'Cannot clear records of registers ""Inventory cost"" and ""Revenue and cost of goods sold"" of the ""%1"" document. Reason: %2'; fa = 'Cannot clear records of registers ""Inventory cost"" and ""Revenue and cost of goods sold"" of the ""%1"" document. Reason: %2';
								|it = 'Non è stato possibile cancellare i movimenti per i registri ""Prezzo di costo delle merci"" e ""Ricavo e prezzo di costo delle vendite"" del documento ""%1"" a causa di: %2';
								|pl = 'Nie udało się wyczyścić przepływów według rejestrów ""Koszt własny towarów"" i ""Utarg i koszty własnych sprzedaży"" dokumentu ""%1"" z powodu: %2';
								|tr = '""%1"" belgesinin ""Stok maliyeti"" ve ""Gelir ve satışların maliyeti"" kayıtlarındaki hareketler temizlenemedi çünkü: %2'");
			MessageText = StrTemplate(MessageText, Selection.Recorder, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(
				NStr("vi = 'Tính toán dự phòng giảm giá.';
					|ru = 'Расчет резервов под обесценение.';
					|en = 'Calculate provisions for impairment.'; fa = 'Calculate provisions for impairment.';
					|it = 'Calcolo delle scorte in deterioramento.';
					|pl = 'Rozliczenie rezerw pod utratę wartości.';
					|tr = 'Rezerv değer düşüklüğü hesaplama.'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				,
				Selection.Recorder,
				MessageText);
			
		EndTry;
		
	EndDo;
	
EndProcedure
Function GenerateTableOfDocumentsToBeReflected(Document, Organization, Period)

	DocumentsToBeReflected = New ValueTable;
	DocumentsToBeReflected.Columns.Add("Document", New TypeDescription("DocumentRef.CalculationOfInventoryImpairmentProvision"));
	DocumentsToBeReflected.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	DocumentsToBeReflected.Columns.Add("Period", New TypeDescription("Date"));
	DocumentsToBeReflected.Columns.Add("DateRecord", New TypeDescription("Date"));
	
	NewRow = DocumentsToBeReflected.Add();
	
	NewRow.Document = Document;
	NewRow.Organization = Organization;
	NewRow.Period = Period;
	NewRow.DateRecord = Period;
	
	Return DocumentsToBeReflected;
	
EndFunction
Function GenerateSummaryTableOfReserves(TempTablesManager, PutParameters)
	
	QueryingResultingTemporaryTable = GenerateFinalReserveRequest(PutParameters);
	QueryingResultingTemporaryTable.TempTablesManager = TempTablesManager;
	TableOfReserves = QueryingResultingTemporaryTable.Execute().Unload();
	
	Return TableOfReserves;
	
EndFunction

Function GenerateFinalReserveRequest(PutParameters)
	
	FinalRequest = New Query;
	Schema = New QuerySchema;
	QueryText = TextOfFinalRequest();
	QueryText = StrReplace(QueryText, "&BalanceTable", PutParameters.TempTableName);
	Schema.SetQueryText(QueryText);
	
	Catalogs.RulesForCalculationOfInventoryImpairmentProvision.GenerateTemporaryTableJoinOperators(Schema, PutParameters.TempTableName, PutParameters.TemporaryTableNumber); 
	
	FinalRequest.Text = Schema.GetQueryText();
	
	Return FinalRequest;
	
EndFunction

Function TextOfFinalRequest()
	
	QueryText = 
	"SELECT
	|	BalanceTable.Period AS Period,
	|	BalanceTable.Rule AS Rule,
	|	BalanceTable.Priority AS Priority,
	|	BalanceTable.LocalAccounting AS LocalAccounting,
	|	BalanceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalanceTable.Warehouse AS Warehouse,
	|	BalanceTable.AccountingSection AS AccountingSection,
	|	BalanceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	BalanceTable.InventoryType AS InventoryType,
	|	BalanceTable.Organization AS Organization,
	|	BalanceTable.Lot AS Lot,
	|	BalanceTable.LotVendorAttributes AS LotVendorAttributes,
	|	BalanceTable.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	BalanceTable.VATActivityType AS VATActivityType,
	|	BalanceTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BalanceTable.BusinessOperation AS BusinessOperation,
	|	BalanceTable.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	BalanceTable.CalculationOfCost AS CalculationOfCost,
	|	BalanceTable.ProvisionForImpairmentLocal AS ProvisionForImpairmentLocal,
	|	BalanceTable.ProvisionForImpairmentMan AS ProvisionForImpairmentMan,
	|	BalanceTable.ProvisionForImpairmentOfLocalRevenue AS ProvisionForImpairmentOfLocalRevenue,
	|	BalanceTable.ProvisionForImpairmentOfManRevenue AS ProvisionForImpairmentOfManRevenue,
	|	BalanceTable.RecordType AS RecordType
	|INTO TemporaryTableOfBalances
	|FROM
	|	&BalanceTable AS BalanceTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	MIN(BalanceTable.Priority) AS Priority,
	|	BalanceTable.AccountingSection AS AccountingSection,
	|	BalanceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	BalanceTable.InventoryType AS InventoryType,
	|	BalanceTable.Organization AS Organization,
	|	BalanceTable.Lot AS Lot,
	|	BalanceTable.LotVendorAttributes AS LotVendorAttributes,
	|	BalanceTable.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	BalanceTable.VATActivityType AS VATActivityType,
	|	TRUE AS LocalAccounting,
	|	FALSE AS ManagementAccounting
	|INTO RulePriority
	|FROM
	|	TemporaryTableOfBalances AS BalanceTable
	|WHERE
	|	CAST(BalanceTable.Rule AS
	|		Catalog.RulesForCalculationOfInventoryImpairmentProvision).LocalAccounting
	|GROUP BY
	|	BalanceTable.ItemsLocationAttributes,
	|	BalanceTable.AccountingSection,
	|	BalanceTable.InventoryOwnerAttribute,
	|	BalanceTable.InventoryType,
	|	BalanceTable.Organization,
	|	BalanceTable.Lot,
	|	BalanceTable.LotVendorAttributes,
	|	BalanceTable.FinancialAccountingDimension,
	|	BalanceTable.VATActivityType
	|
	|UNION ALL
	|
	|SELECT
	|	BalanceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	MIN(BalanceTable.Priority) AS Priority,
	|	BalanceTable.AccountingSection AS AccountingSection,
	|	BalanceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	BalanceTable.InventoryType AS InventoryType,
	|	BalanceTable.Organization AS Organization,
	|	BalanceTable.Lot AS Lot,
	|	BalanceTable.LotVendorAttributes AS LotVendorAttributes,
	|	BalanceTable.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	BalanceTable.VATActivityType AS VATActivityType,
	|	FALSE AS LocalAccounting,
	|	TRUE AS ManagementAccounting
	|FROM
	|	TemporaryTableOfBalances AS BalanceTable
	|WHERE
	|	CAST(BalanceTable.Rule AS Catalog.RulesForCalculationOfInventoryImpairmentProvision).ManagementAccounting
	|GROUP BY
	|	BalanceTable.ItemsLocationAttributes,
	|	BalanceTable.AccountingSection,
	|	BalanceTable.InventoryOwnerAttribute,
	|	BalanceTable.InventoryType,
	|	BalanceTable.Organization,
	|	BalanceTable.Lot,
	|	BalanceTable.LotVendorAttributes,
	|	BalanceTable.FinancialAccountingDimension,
	|	BalanceTable.VATActivityType
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Priority,
	|	AccountingSection,
	|	InventoryOwnerAttribute,
	|	InventoryType,
	|	Organization,
	|	Lot,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType,
	|	LocalAccounting,
	|	ManagementAccounting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceTable.Period AS Period,
	|	BalanceTable.Rule AS Rule,
	|	BalanceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalanceTable.Warehouse AS Warehouse,
	|	BalanceTable.AccountingSection AS AccountingSection,
	|	BalanceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	BalanceTable.InventoryType AS InventoryType,
	|	BalanceTable.Organization AS Organization,
	|	BalanceTable.Lot AS Lot,
	|	BalanceTable.LotVendorAttributes AS LotVendorAttributes,
	|	BalanceTable.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	BalanceTable.VATActivityType AS VATActivityType,
	|	BalanceTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BalanceTable.BusinessOperation AS BusinessOperation,
	|	BalanceTable.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	BalanceTable.CalculationOfCost AS CalculationOfCost,
	|	BalanceTable.ProvisionForImpairmentLocal AS ProvisionForImpairmentLocal,
	|	0 AS ProvisionForImpairmentMan,
	|	BalanceTable.ProvisionForImpairmentOfLocalRevenue AS ProvisionForImpairmentOfLocalRevenue,
	|	0 AS ProvisionForImpairmentOfManRevenue,
	|	BalanceTable.RecordType AS RecordType
	|FROM
	|	TemporaryTableOfBalances AS BalanceTable
	|		INNER JOIN RulePriority AS RulePriority
	|		ON BalanceTable.ItemsLocationAttributes = RulePriority.ItemsLocationAttributes
	|		AND BalanceTable.AccountingSection = RulePriority.AccountingSection
	|		AND BalanceTable.InventoryOwnerAttribute = RulePriority.InventoryOwnerAttribute
	|		AND BalanceTable.Organization = RulePriority.Organization
	|		AND BalanceTable.Lot = RulePriority.Lot
	|		AND BalanceTable.LotVendorAttributes = RulePriority.LotVendorAttributes
	|		AND BalanceTable.FinancialAccountingDimension = RulePriority.FinancialAccountingDimension
	|		AND BalanceTable.VATActivityType = RulePriority.VATActivityType
	|		AND BalanceTable.Priority = RulePriority.Priority
	|WHERE
	|	RulePriority.LocalAccounting
	|	AND BalanceTable.LocalAccounting
	|	AND BalanceTable.ProvisionForImpairmentLocal <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	BalanceTable.Period AS Period,
	|	BalanceTable.Rule AS Rule,
	|	BalanceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	BalanceTable.Warehouse AS Warehouse,
	|	BalanceTable.AccountingSection AS AccountingSection,
	|	BalanceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	BalanceTable.InventoryType AS InventoryType,
	|	BalanceTable.Organization AS Organization,
	|	BalanceTable.Lot AS Lot,
	|	BalanceTable.LotVendorAttributes AS LotVendorAttributes,
	|	BalanceTable.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	BalanceTable.VATActivityType AS VATActivityType,
	|	BalanceTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BalanceTable.BusinessOperation AS BusinessOperation,
	|	BalanceTable.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	BalanceTable.CalculationOfCost AS CalculationOfCost,
	|	0 AS ProvisionForImpairmentLocal,
	|	BalanceTable.ProvisionForImpairmentMan AS ProvisionForImpairmentMan,
	|	0 AS ProvisionForImpairmentOfLocalRevenue,
	|	BalanceTable.ProvisionForImpairmentOfManRevenue AS ProvisionForImpairmentOfManRevenue,
	|	BalanceTable.RecordType AS RecordType
	|FROM
	|	TemporaryTableOfBalances AS BalanceTable
	|		INNER JOIN RulePriority AS RulePriority
	|		ON BalanceTable.ItemsLocationAttributes = RulePriority.ItemsLocationAttributes
	|		AND BalanceTable.AccountingSection = RulePriority.AccountingSection
	|		AND BalanceTable.InventoryOwnerAttribute = RulePriority.InventoryOwnerAttribute
	|		AND BalanceTable.Organization = RulePriority.Organization
	|		AND BalanceTable.Lot = RulePriority.Lot
	|		AND BalanceTable.LotVendorAttributes = RulePriority.LotVendorAttributes
	|		AND BalanceTable.FinancialAccountingDimension = RulePriority.FinancialAccountingDimension
	|		AND BalanceTable.VATActivityType = RulePriority.VATActivityType
	|		AND BalanceTable.Priority = RulePriority.Priority
	|WHERE
	|	RulePriority.ManagementAccounting
	|	AND NOT BalanceTable.LocalAccounting
	|	AND BalanceTable.ProvisionForImpairmentMan <> 0";
	
	Return QueryText
				
EndFunction

Function QueryTextRules_();
	
	QueryText =
	
	"SELECT
	|	ISNULL(ReserveDocuments.Recorder, UNDEFINED) AS Recorder,
	|	Rules.Ref AS Rule,
	|	Rules.Owner AS Organization,
	|	Rules.PriceKind AS PriceKind,
	|	Rules.StorageOfDataCompositionSettings AS DataCompositionSettings,
	|	Rules.LocalAccounting AS LocalAccounting,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN Rules.ManagementAccounting
	|		ELSE FALSE END) AS ManagementAccounting
	|FROM
	|	Catalog.RulesForCalculationOfInventoryImpairmentProvision AS Rules
	|		LEFT JOIN ReserveDocuments AS ReserveDocuments
	|		ON Rules.Owner = ReserveDocuments.Organization
	|WHERE
	|	&BatchAccountingVersion22
	|	AND BEGINOFPERIOD(Rules.ValidOnDate, MONTH) <= &Period
	|	AND (ENDOFPERIOD(Rules.ValidToDate, MONTH) >= &Period
	|		OR Rules.ValidToDate = DATETIME(1,1,1))
	|	AND NOT Rules.DeletionMark
	|	AND Rules.Owner IN(&Companies)
	|
	|ORDER BY
	|	Organization,
	|	Rules.Priority
	|TOTALS
	|	MAX(Recorder)
	|BY
	|	Organization";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
