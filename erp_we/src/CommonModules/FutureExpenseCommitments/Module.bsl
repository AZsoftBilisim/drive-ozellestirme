
#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.FutureExpenseCommitments);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.ProvisionDiscountingRates);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.PeriodOfDiscountingOfProvisionsAndContingentLiabilities);
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.FutureExpenseCommitments);
	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.FutureExpenseCommitments);
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the register.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "FutureExpenseCommitments");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ProvisionDiscountingRates");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "PeriodOfDiscountingOfProvisionsAndContingentLiabilities");
	
EndProcedure

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("ChangesTableFutureExpenseCommitments", RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;
	
EndFunction

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.FutureExpenseCommitments.Name;
	NameOfChangeTable = "ChangesTableFutureExpenseCommitments"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
	Return StructureOfQueryTexts_

EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region JobsForMonthEndClosing

// Complements the request text of the mechanism for generating monthly closing tasks.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
Procedure AddTextOfRequestForTasksByEndOfMonth(Query, QueryText, TempTablesQueryText, TemporaryTableNames) Export
	
	MatchingRequests = MatchingRequestsToControlRegisters(Query);
	
	For Each MapItem In MatchingRequests Do
		MonthEndTransactionsServer.AddTableNamesForTasks(Query, MapItem.Key);
		MonthEndTransactionsServer.AddTaskRequestText(MapItem.Key,
			MapItem.Value,
			Query.TempTablesManager.Tables,
			QueryText,
			TempTablesQueryText,
			TemporaryTableNames);
	EndDo;
	
EndProcedure

#EndRegion

#Region HandlersForMonthClosingStages

#Region FutureExpenseCommitmentsAccrualWriteOff

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_FutureExpenseCommitmentsAccrualWriteOff(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.FutureExpenseCommitmentsAccrualWriteOff,
		False, True, False);
	
	NewRow.MultilingualName = "vi = 'trích và ghi giảm dự phòng cho các chi phí trong tương lai';
								|ru = 'Начисление и списание резервов предстоящих расходов';
								|en = 'Accrual and write-off of provisions and contingent liabilities';
								|it = 'Maturazione e storno delle riserve delle spese previste';
								|pl = 'Naliczanie i rozchód rezerw przyszłych rozchodów';
								|tr = 'Karşılıkların ve şarta bağlı yükümlülüklerin gider yazılması ve tahakkuku'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute = NStr("vi = 'Hiển thị';
								|ru = 'Отразить';
								|en = 'Record'; fa = 'ثبت';
								|it = 'Riportare';
								|pl = 'Record';
								|tr = 'Kaydet'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"FutureExpenseCommitments.Use_AccrualWriteOffOfProvisionsForUpcomingExpenses");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.FutureExpenseCommitmentsAccrualWriteOff.Forms.WorkplaceForm.FullName());
	NewRow.ActionExecute.FormParameters.Insert("AllCompanies");

EndProcedure

Procedure Use_AccrualWriteOffOfProvisionsForUpcomingExpenses(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT
	|	ProvisionObjects.Organization AS Organization,
	|	ProvisionObjects.ReserveKind AS ReserveKind,
	|	ProvisionObjects.Ref AS ProvisionObject
	|INTO TTReserves
	|FROM
	|	Catalog.AccountingObjectsOfFutureExpenseCommitments AS ProvisionObjects
	|WHERE
	|	ProvisionObjects.BeginOfPeriod <= &EndOfPeriod
	|	AND ProvisionObjects.EndOfPeriod = DATETIME(1,1,1)
	|	AND ProvisionObjects.Organization IN (&CompanyArray)
	|	AND NOT ProvisionObjects.DeletionMark
	|
	|UNION ALL
	|	
	|SELECT
	|	ProvisionObjects.Organization AS Organization,
	|	ProvisionObjects.ReserveKind AS ReserveKind,
	|	ProvisionObjects.Ref AS ProvisionObject
	|FROM
	|	Catalog.AccountingObjectsOfFutureExpenseCommitments AS ProvisionObjects
	|WHERE
	|	ProvisionObjects.BeginOfPeriod <= &EndOfPeriod
	|	AND ProvisionObjects.EndOfPeriod >= &EndOfPeriod
	|	AND ProvisionObjects.Organization IN (&CompanyArray)
	|	AND NOT ProvisionObjects.DeletionMark
	|
	|UNION ALL
	|	
	|SELECT
	|	FutureExpenseCommitments.Organization AS Organization,
	|	FutureExpenseCommitments.ReserveKind AS ReserveKind,
	|	FutureExpenseCommitments.ProvisionObject AS ProvisionObject
	|FROM
	|	AccumulationRegister.FutureExpenseCommitments.Balance(&EndOfPeriod, Organization IN (&CompanyArray)) AS FutureExpenseCommitments
	|WHERE
	|	FutureExpenseCommitments.SumManBalance <> 0
	|	OR FutureExpenseCommitments.SumComplBalance <> 0
	|	OR FutureExpenseCommitments.AmountFABalance <> 0
	|
	|INDEX BY
	|	Organization,
	|	ReserveKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	KindsOfReserves.Organization AS Organization,
	|	KindsOfReserves.ReserveKind AS ReserveKind
	|INTO TTProvisionsForRecognition
	|FROM
	|	TTReserves AS KindsOfReserves
	|		LEFT JOIN Document.FutureExpenseCommitmentsAccrualWriteOff AS ReflectionOfReserves
	|		ON (ReflectionOfReserves.Date = &EndOfPeriod)
	|			AND KindsOfReserves.Organization = ReflectionOfReserves.Organization
	|			AND (KindsOfReserves.ReserveKind = ReflectionOfReserves.ReserveKind)
	|			AND (ReflectionOfReserves.Posted)
	|WHERE
	|	ReflectionOfReserves.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ReserveObjects.Organization AS Organization,
	|	ReserveObjects.ReserveKind AS ReserveKind,
	|	ReserveObjects.ProvisionObject AS ProvisionObject,
	|	ReflectionOfReserves.Ref AS Document
	|INTO TTObjectsOfAccountingOfReservesForReflection
	|FROM
	|	TTReserves AS ReserveObjects
	|		INNER JOIN Document.FutureExpenseCommitmentsAccrualWriteOff AS ReflectionOfReserves
	|		ON (ReflectionOfReserves.Date = &EndOfPeriod)
	|			AND ReserveObjects.Organization = ReflectionOfReserves.Organization
	|			AND (ReserveObjects.ReserveKind = ReflectionOfReserves.ReserveKind)
	|			AND (ReflectionOfReserves.Posted)
	|		LEFT JOIN Document.FutureExpenseCommitmentsAccrualWriteOff.Reserves AS ProvisionsForReflectingReserves
	|		ON ReflectionOfReserves.Ref = ProvisionsForReflectingReserves.Ref
	|			AND (ReserveObjects.ProvisionObject = ProvisionsForReflectingReserves.ProvisionObject)
	|WHERE
	|	ProvisionsForReflectingReserves.ProvisionObject IS NULL";
	Query.Execute();
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.TTReserves = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có mục kế toán dự phòng yêu cầu phản ánh tích lũy hoặc ghi giảm dự phòng';
				|ru = 'Нет объектов учета резервов, требующих отражения начисления или списание резервов';
				|en = 'No provision objects that require accrual recording or reserve write-off'; fa = 'No provision objects that require accrual recording or reserve write-off';
				|it = 'Non ci sono oggetti di contabilità delle riserve, che necessitano una visualizzazione degli accrediti o uno storno delle riserve';
				|pl = 'Brak obiektów ewidencji rezerw, wymagających odzwierciedlenia naliczania lub wyksięgowanie rezerw';
				|tr = 'Karşılıkların tahakkuk ettirilmesini veya gider yazılmasına gerektiren herhangi bir karşılık muhasebesi nesnesi bulunmamaktadır'", Common.DefaultLanguageCode()));
		
	ElsIf TemporaryTableSizes.TTObjectsOfAccountingOfReservesForReflection <> 0 Then
		
		MonthEndTransactionsServer.SetStateExecutedWithErrors(
			HandlerParameters,
			NStr("vi = 'Đã thực hiện phản ánh dự phòng chi phí tương lai';
				|ru = 'Отражение резервов предстоящих расходов выполнено';
				|en = 'Reserve record of provisions and contingent liabilities complete'; fa = 'Reserve record of provisions and contingent liabilities complete';
				|it = 'Visualizzazione delle riserve delle spese imminenti effettuata';
				|pl = 'Odzwierciedlenie rezerw nadchodzących rozchodów jest wykonane';
				|tr = 'Karşılıklar ve şarta bağlı yükümlülüklerin yansıtılması gerçekleştirildi'", Common.DefaultLanguageCode()));
		
	ElsIf TemporaryTableSizes.TTProvisionsForRecognition = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Đã thực hiện phản ánh dự phòng chi phí tương lai';
				|ru = 'Отражение резервов предстоящих расходов выполнено';
				|en = 'Reserve record of provisions and contingent liabilities complete'; fa = 'Reserve record of provisions and contingent liabilities complete';
				|it = 'Visualizzazione delle riserve delle spese imminenti effettuata';
				|pl = 'Odzwierciedlenie rezerw nadchodzących rozchodów jest wykonane';
				|tr = 'Karşılıklar ve şarta bağlı yükümlülüklerin yansıtılması gerçekleştirildi'", Common.DefaultLanguageCode()));
		
	EndIf;	
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfChecks_AccrualWriteOffOfProvisionsForUpcomingExpenses(TableOfChecks) Export
	
	// Reflection of reserves.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"VerificationOfNecessityAccrualWriteOffOfProvisionsForUpcomingExpenses",
		Catalogs.MonthEndClosingOperations.FutureExpenseCommitmentsAccrualWriteOff,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"FutureExpenseCommitments.VerificationOfNecessityAccrualWriteOffOfProvisionsForUpcomingExpenses");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Không phản ánh trích / ghi giảm dự phòng cho các chi phí trong tương lai';
			|ru = 'Не отражена операция начисления/списания резервов предстоящих расходов';
			|en = 'Accrual/write-off transaction is not recorded for provisions and contingent liabilities'; fa = 'Accrual/write-off transaction is not recorded for provisions and contingent liabilities';
			|it = 'Non è visualizzata l''operazione di accredito/storno delle riserve delle spese imminenti';
			|pl = 'Nie jest pokazana operacja naliczania/wyksięgowania rezerw nadchodzących rozchodów';
			|tr = 'Karşılıklar ve şarta bağlı yükümlülükler tahakkuku/gider yazılması yansıtılmamıştır'", Common.DefaultLanguageCode()),
		NStr("vi = 'Đối với tất cả các loại dự phòng, chứng từ nên được tạo ra ""Tích lũy và ghi giảm dự phòng cho các chi phí trong tương lai.""';
			|ru = 'По всем видам резервов должны быть созданы документы ""Начисления и списания резервов предстоящих расходов"".';
			|en = 'The Accruals and deductions of documents for provisions and contingent liabilities must be created for all reserve kinds.'; fa = 'The Accruals and deductions of documents for provisions and contingent liabilities must be created for all reserve kinds.';
			|it = 'Per tutti i tipi delle riserve devono essere creati i documenti ""Accrediti e storni delle riserve delle spese imminenti"".';
			|pl = 'Wg wszystkich rodzajów rezerw powinny być utworzone dokumenty  ""Начисления и списания резервов предстоящих расходов"".';
			|tr = 'Tüm rezerv türleri için ""Karşılıklar ve şarta bağlı yükümlülükler için karşılıkların tahakkuku ve gider yazılması"" belgeleri oluşturulmalıdır.'", Common.DefaultLanguageCode()));
	
EndProcedure

// Handler for checking whether a stage needs to be completed 
//
//  Parameters:
//	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
//
Procedure VerificationOfNecessityAccrualWriteOffOfProvisionsForUpcomingExpenses(CheckParameters) Export
	
	FieldList = New ValueList;
	FieldList.Add("Organization", NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Company';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("ReserveKind", NStr("vi = 'Dạng dự phòng';
										|ru = 'Вид резервов';
										|en = 'Reserve kind'; fa = 'نوع ذخیره';
										|it = 'Tipo di riserve';
										|pl = 'Rodzaj rezerw';
										|tr = 'Rezerv türü'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTProvisionsForRecognition",
		NStr("vi = 'Chưa tạo chứng từ ""Tích lũy và ghi giảm dự phòng cho các chi phí trong tương lai"" cho doanh nghiệp ""%1"" trong kỳ %2';
			|ru = 'Не созданы документы ""Начисления и списания резервов предстоящих расходов"" по организации ""%1"" за период %2';
			|en = 'The Accruals and deductions of documents for provisions and contingent liabilities were not created for the %1 company for the period %2'; fa = 'The Accruals and deductions of documents for provisions and contingent liabilities were not created for the %1 company for the period %2';
			|it = 'I documenti ""Accantonamenti e riserve per spese future"" dell''organizzazione ""%1"" per il periodo %2 non sono stati creati';
			|pl = 'Nie są utworzone dokumenty  ""Начисления и списания резервов предстоящих расходов"" wg firm ""%1"" za okres %2';
			|tr = '""%1"" iş yeri için %2 dönemi için ""Karşılıklar ve şarta bağlı yükümlülükler için tahakkuklar ve karşılıkların gider yazılması"" belgesi oluşturulmadı'", Common.DefaultLanguageCode()),
		FieldList);
		
	If ValueIsFilled(CheckParameters.AdditionalParameters) Then
		DataVolume = CostCalculationAppliedAlgorithms.TemporaryTableSize(
			CheckParameters.AdditionalParameters.TempTablesManager,
			"TTProvisionsForRecognition");
		MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(
			CheckParameters.AdditionalParameters,
			DataVolume);
	EndIf;
		
	ErrorTextTemplate = NStr("vi = 'Đối với chứng từ ""Tích lũy và ghi giảm dự phòng cho các chi phí trong tương lai"" cho doanh nghiệp ""%1"" trong kỳ %2, đã chỉ ra không phải tất cả các đối tượng kế toán dự phòng';
							|ru = 'Для документов ""Начисления и списания резервов предстоящих расходов"" по организации ""%1"" за период %2 указаны не все объекты учета резервов';
							|en = 'Not all provision objects are specified for the ""Accruals and write-offs of provisions and contingent liabilities"" documents by the ""%1"" company for period %2'; fa = 'Not all provision objects are specified for the ""Accruals and write-offs of provisions and contingent liabilities"" documents by the ""%1"" company for period %2';
							|it = 'Per i documenti ""Accantonamenti e cancellazioni di riserve per spese future"" dell''organizzazione ""%1"" per il periodo %2 non sono indicati tutti gli oggetti di contabilità delle riserve';
							|pl = 'Dla dokumentów  ""Начисления и списания резервов предстоящих расходов"" wg firm ""%1"" za okres %2 są wskazane nie wszystkie obiekty ewidencji rezerw';
							|tr = '""%1"" iş yeri için %2 dönemine ait ""Karşılıklar ve şarta bağlı yükümlülükler için karşılıkların tahakkuku ve gider yazılması"" belgeleri için karşılıkların tüm muhasebe nesneleri belirtilmedi'", Common.DefaultLanguageCode());
	ExtendedListOfFields = FieldList.Copy();
	ExtendedListOfFields.Add("ProvisionObject", NStr("vi = 'Đối tượng kế toán dự phòng';
													|ru = 'Объект учета резервов';
													|en = 'Provision object'; fa = 'موضوع ذخیره';
													|it = 'Oggetto di contabilità delle riserve';
													|pl = 'Obiekt ewidencji zapasów';
													|tr = 'Rezerv muhasebesi nesnesi'", Common.DefaultLanguageCode()));
	ExtendedListOfFields.Add("Document", NStr("vi = 'Chứng từ trích và ghi giảm dự phòng';
												|ru = 'Документ начисления и списания резервов';
												|en = 'Document of reserve accrual and write-off'; fa = 'Document of reserve accrual and write-off';
												|it = 'Documento di accredito e storno delle riserve';
												|pl = 'Dokument naliczania i wyksięgowania rezerw';
												|tr = 'Karşılıkların tahakkuku ve gider yazılması için belge'", Common.DefaultLanguageCode()));
	MonthEndTransactionsServer.AddRegistrationAndVerificationParameters(RegistrationParameters, "TTObjectsOfAccountingOfReservesForReflection", ErrorTextTemplate, ExtendedListOfFields, "Document");
	
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion
#EndRegion

Procedure ReservesProcessingOfReceivingSelectionData(ChoiceData, Parameters, StandardProcessing) Export
	
	If Not Parameters.Property("Filter") Or TypeOf(Parameters.Filter) <> Type("Structure") Then
		Parameters.Insert("Filter", New Structure);
	EndIf;
	
	PurposeUseKey =
		CommonClientServer.StructureProperty(Parameters, "PurposeUseKey", "FutureExpenseCommitments");
	TypesOfReserves = Enums.TypesOfProvisionsAndContingentLiabilities.TypesOfReservesByPurpose(PurposeUseKey);
	CommonClientServer.SupplementStructure(Parameters.Filter, New Structure("ReserveType", TypesOfReserves), False);
	
EndProcedure

// Returns the use of discounting reserves by organization
//
// Parameters:
//  Period - Date - Period Of Validity Of The Setting
//  Organization - CatalogRef - Organization
//  Dopparameters - Structure - additional parameters for obtaining data that determine the context of the event.
//
// Returns:
//  Boolean - Using discounting
//
Function AccountingForDiscountingReservesIsUsed(Val Period, Val Organization) Export

	AccountingForDiscountingReservesIsUsed = False;
	
	ActiveParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		Metadata.InformationRegisters.FinancialAccountingPolicy.Name, Organization, Period);
	
	If ActiveParameters <> Undefined Then
		AccountingForDiscountingReservesIsUsed = ActiveParameters.AccountForDiscountingOfProvisionsAndContingentLiabilities;
	EndIf;
	
	Return AccountingForDiscountingReservesIsUsed;
	
EndFunction

#EndRegion

#Region Private

#Region CreatingTasksForEndOfMonth

Function MatchingRequestsToControlRegisters(Query)
	
	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("ChangesTableFutureExpenseCommitments",
		QueryTextTableOfChangesProvisionsAndContingentLiabilities(Query));
	Return MatchingQueryTexts;
	
EndFunction

Function QueryTextTableOfChangesProvisionsAndContingentLiabilities(Query)
	
	QueryText =
	"SELECT DISTINCT
	|	ChangesTable.Period AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.CalculationOfDiscountInterestExpenses) AS Operation,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.Recorder AS Document
	|FROM
	|	ChangesTableFutureExpenseCommitments AS ChangesTable
	|WHERE
	|	(ChangesTable.DiscountingAmountMan <> 0
	|	OR ChangesTable.DiscountingAmountCompl <> 0)
	|	AND VALUETYPE(ChangesTable.Recorder) <> TYPE(Document.CalculationOfDiscountInterestExpenses)";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(
		QueryText);
		
	Return StructureOfQueryTexts_;
	
EndFunction

#EndRegion

#EndRegion