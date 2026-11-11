#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

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
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.FinancialInstrumentsARAP);
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.FinancialInstrumentsARAP);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.FinancialInstrumentsARAP);
		Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.FinancialInstrumentsARAP);
	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.FinancialInstrumentsARAP);
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
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.FinancialInstrumentsARAP;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
			
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the register.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "FinancialInstrumentsARAP");
	
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
	MatchingQueryTexts.Insert("ChangesTableFinancialInstrumentsARAP", 
		AccumulationRegisters.FinancialInstrumentsARAP.RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;
	
EndFunction

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.FinancialInstrumentsARAP.Name;
	NameOfChangeTable = "ChangesTableFinancialInstrumentsARAP"; 
	
	QueryText =
	"SELECT
	|	Table.Period AS Period,
	|	PartnerAccountingAnalyticsKeys.Organization AS Organization,
	|	&RegisterName AS RegisterName,
	|	&Section AS SectionClosingDates
	|FROM
	|	&NameOfChangeTable AS Table
	|	INNER JOIN
	|		InformationRegister.AccountingDimensionByPartners AS PartnerAccountingAnalyticsKeys
	|	ON
	|		Table.AccountingDimensionByPartners = PartnerAccountingAnalyticsKeys.DimensionKey
	|WHERE
	|	Table.Sum <> 0
	|	OR Table.SumMan <> 0
	|	OR Table.SumCompl <> 0
	|";
	
	ParameterNameRegisterName = "RegisterName" + RegisterName;
	NameOfSectionParameter = "Section" + RegisterName;
	
	QueryText = StrReplace(QueryText,"&RegisterName", "&" + ParameterNameRegisterName);
	QueryText = StrReplace(QueryText,"&Section", "&" + NameOfSectionParameter);
	QueryText = StrReplace(QueryText,"&NameOfChangeTable", NameOfChangeTable);
	
	Query.SetParameter(ParameterNameRegisterName, RegisterName);
	Query.SetParameter(NameOfSectionParameter, "FinancialOutline");
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_

EndFunction

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsSettlementsOnFinancialInstrumentsChange") Then
		
		QueryText = "
		|SELECT
		|	BalanceTable.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	BalanceTable.Contract                           AS Contract,
		|	BalanceTable.AmountType                          AS AmountType,
		|	BalanceTable.ARAPDocument                 AS ARAPDocument,
		|	BalanceTable.Currency                            AS Currency,
		|	BalanceTable.BeingPaidBalance               AS BeingPaid,
		|	0                                                 AS Sum
		|
		|FROM
		|	AccumulationRegister.FinancialInstrumentsARAP.Balance(,
		|		(AccountingDimensionByPartners, Contract, AmountType, ARAPDocument, Currency) IN
		|		(SELECT
		|			Table.AccountingDimensionByPartners,
		|			Table.Contract,
		|			Table.AmountType,
		|			Table.ARAPDocument,
		|			Table.Currency
		|		FROM
		|			RegisteredRecordsSettlementsOnFinancialInstrumentsChange AS Table
		|		)
		|		) AS BalanceTable
		|
		|WHERE
		|	BalanceTable.BeingPaidBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	BalanceTable.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	BalanceTable.Contract                           AS Contract,
		|	BalanceTable.AmountType                          AS AmountType,
		|	BalanceTable.ARAPDocument                 AS ARAPDocument,
		|	BalanceTable.Currency                            AS Currency,
		|	0                                                 AS BeingPaid,
		|	BalanceTable.SumBalance                      AS Sum
		|
		|FROM
		|	AccumulationRegister.FinancialInstrumentsARAP.Balance(,
		|		(AccountingDimensionByPartners, Contract, AmountType, ARAPDocument, Currency) IN
		|		(SELECT
		|			Table.AccountingDimensionByPartners,
		|			Table.Contract,
		|			Table.AmountType,
		|			Table.ARAPDocument,
		|			Table.Currency
		|		FROM
		|			RegisteredRecordsSettlementsOnFinancialInstrumentsChange AS Table
		|		WHERE
		|			Table.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalService)
		|			AND Table.ARAPDocument = UNDEFINED
		|			AND CAST(Table.Contract AS Catalog.LeaseContract).KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments
		|		)
		|		) AS BalanceTable
		|
		|WHERE
		|	BalanceTable.SumBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	BalanceTable.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	BalanceTable.Contract                           AS Contract,
		|	BalanceTable.AmountType                          AS AmountType,
		|	BalanceTable.ARAPDocument                 AS ARAPDocument,
		|	BalanceTable.Currency                            AS Currency,
		|	0                                                 AS BeingPaid,
		|	BalanceTable.SumBalance                      AS Sum
		|
		|FROM
		|	AccumulationRegister.FinancialInstrumentsARAP.Balance(,
		|		(AccountingDimensionByPartners, Contract, AmountType, ARAPDocument, Currency) IN
		|		(SELECT
		|			Table.AccountingDimensionByPartners,
		|			Table.Contract,
		|			Table.AmountType,
		|			Table.ARAPDocument,
		|			Table.Currency
		|		FROM
		|			RegisteredRecordsSettlementsOnFinancialInstrumentsChange AS Table
		|		WHERE
		|			(Table.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
		|			OR Table.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment))
		|			AND Table.ARAPDocument <> UNDEFINED
		|		)
		|		) AS BalanceTable
		|
		|WHERE
		|	BalanceTable.SumBalance < 0
		|";
		
		QueryTexts.Add(QueryText, "ErrorsCalculationsOnFinancialInstruments");
		
	EndIf;
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsSettlementsOnFinancialInstrumentsChange") Then
		
		For Each ErrorString In ControlResults.ErrorsCalculationsOnFinancialInstruments Do
			If ErrorString.BeingPaid <> 0 Then 
				MessageText = StrTemplate(NStr("vi = 'Theo hợp đồng %1 được thanh toán lớn hơn số tiền đã duyệt trong giấy đề nghị thanh toán là %2 %3';
												|ru = 'По договору %1 оплачивается больше, чем утверждено в заявке, на %2 %3';
												|en = 'Under contract %1 payment is greater than confirmed in the request by %2 %3'; fa = 'Under contract %1 payment is greater than confirmed in the request by %2 %3';
												|it = 'In base al contratto %1 viene pagato più di quanto indicato nella richiesta, di %2%3';
												|pl = 'Wg kontraktu %1 wypłaca się więcej, niż zatwierdzono we wniosku o %2 %3';
												|tr = 'Sözleşme uyarınca, %1 başvuruda onaylanandan daha fazla ödeme yapılır, %2%3'"),
					ErrorString.Contract, ErrorString.BeingPaid, ErrorString.Currency);
				Common.MessageToUser(MessageText, Document,,, Cancel);
			ElsIf ErrorString.Sum > 0
				And ErrorString.ARAPDocument = Undefined Then 
				MessageText = StrTemplate(NStr("vi = 'Theo hợp đồng %1 đã thanh toán nhiều hơn số tiền đã chỉ ra trong chứng từ tiếp nhận dịch vụ thuê là %2 %3';
												|ru = 'По договору %1 оплачивается больше, чем указано в документах поступления услуг аренды, на %2 %3';
												|en = 'Under the %1 contract, payments exceed the amount specified in the rental service documents by %2 %3'; fa = 'Under the %1 contract, payments exceed the amount specified in the rental service documents by %2 %3';
												|it = 'По договору %1 оплачивается больше, чем указано в документах поступления услуг аренды, на %2 %3';
												|pl = 'Under the %1 contract, payments exceed the amount specified in the rental service documents by %2 %3';
												|tr = 'Sözleşme uyarınca,%1 kiralama hizmetlerinin alınması için %2%3 belgelerde belirtilenden daha fazla ödeme yapılır'"),
					ErrorString.Contract, ErrorString.Sum, ErrorString.Currency);
				Common.MessageToUser(MessageText, Document,,, Cancel);
			ElsIf ErrorString.Sum < 0
				And ErrorString.ARAPDocument <> Undefined Then 
				MessageText = StrTemplate(NStr("vi = 'Theo chứng từ %1 đã vượt quá số tiền khấu trừ ứng trước %2 %3';
												|ru = 'По документу %1 превышена сумма зачета аванса на %2 %3';
												|en = 'Under the %1 document, the prepayment offset amount is exceeded by %2 %3'; fa = 'Under the %1 document, the prepayment offset amount is exceeded by %2 %3';
												|it = 'По документу %1 превышена сумма зачета аванса на %2 %3';
												|pl = 'Under the %1 document, the prepayment offset amount is exceeded by %2 %3';
												|tr = '%1 belgesine göre, ön ödeme mahsubu tutarı %2%3 aşıldı'"),
					ErrorString.ARAPDocument, -ErrorString.Sum, ErrorString.Currency);
				Common.MessageToUser(MessageText, Document,,, Cancel);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN InformationRegister.AccountingDimensionByPartners AS T1 
	|	ON T.AccountingDimensionByPartners = T1.DimensionKey
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(T1.Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// Fills in the parameters for reflecting register movements in financial accounting
//
// Parameters:
//  RegisterMetadata - MetadataObjectAccumulationRegister - Metadata of the accumulation register
//  RegistrationForReflection - Boolean - Flag for getting parameters to register for accounting
//
// Returns:
// 	See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Function ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegisterMetadata = Undefined, RegistrationForReflection = False) Export
	
	ReflectionParameters = FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegistrationForReflection);
	ReflectionParameters.DataPathOrganization = "AccountingDimensionByPartners.Organization";
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.AllocationOfLongTermAssetsAndLiabilities = True;
	ReflectionParameters.DataPathConfigurationObject = "Contract.FinancialAccountingGroup";
	ReflectionParameters.PathToDataLineOfBusiness = "Contract.LineOfBusiness";
	ReflectionParameters.PathToDataDivision = "Contract.Department";
	ReflectionParameters.DataPathCurrency = "Currency";
	ReflectionParameters.ManResources.Add("SumMan");
	ReflectionParameters.LocalResources.Add("SumCompl");
	ReflectionParameters.ShaftResources.Add("Sum");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Counterparties;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.Contract.DataPath = "Contract";
	ReflectionParameters.StructureOfAnalytics.ARAPObject.Insert("Value", Undefined);
	ReflectionParameters.DataPathDopSettingUpHouseholdOfOperation = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
		|			THEN CASE
		|				WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.CashReceiptBorrowingsProvidedToCounterparty)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfInterestOfIssuedBorrowings)
		|				WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.PaymentOnLoansAndBorrowingsReceived)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.LoanInterestPayment)
		|				ELSE DataSourceAlias.BusinessTransactionSetting
		|			END
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfVATInPartOfLeaseService)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.RecordingLeaseServicesInExpenses)
		|		ELSE DataSourceAlias.BusinessTransactionSetting
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

#EndRegion

#Region BackdateJobQueue

// Data for the formation of tasks for non-operational document verification.
// Called when writing a set of register entries.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
// 
// Returns:
//  ValueTable - Data For The Formation Of Tasks For Non-Operational Document Verification:
// * Organization - CatalogRef.Companies - The organization for which the new task will be generated.
// * TaskPeriod  - Date - The task period. Coincides with the period of the recorded data in the register.
// * Document - DocumentRef - Link to the document for which the task will be registered.
// * JobKind - CatalogRef.BackdateJobKinds - Type of registered task.
//
Function DataForFormationOfTasksForNonOperationalDocumentVerification(RecordSet, KindsOfTasks,
	TempTablesManager, DataForRegisteringTasks = Undefined) Export
	
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();

	If KindsOfTasks.Find(Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords) <> Undefined Then

		Query = New Query;
		Query.TempTablesManager = TempTablesManager;

		Query.Text = "
		|SELECT DISTINCT
		|	CatalogAccountingDimensionByPartners.Organization AS Organization,
		|	DataForProcessing_.TaskPeriod AS TaskPeriod,
		|	DataForProcessing_.Document AS Document,
		|	VALUE(Catalog.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords) AS JobKind
		|FROM
		|	QueueDataForAdditionalDocumentsManBalance AS DataForProcessing_
		|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS CatalogAccountingDimensionByPartners
		|		ON DataForProcessing_.AccountingDimensionByPartners = CatalogAccountingDimensionByPartners.Ref";

		DataTable = Query.Execute().Unload();

		For Each CurrentTypeOfTask In KindsOfTasks Do

			If CurrentTypeOfTask = Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords Then

				Return DataTable;

			EndIf;

		EndDo;

	EndIf;

	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.FinancialInstrumentsARAP.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.40";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("51119c20-5762-5c1b-bdf7-3f0a1da27bec");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.FinancialInstrumentsARAP.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật biểu ghi ""Thanh toán theo các công cụ tài chính"":';
								|ru = 'Обновление регистра ""Расчеты по финансовым инструментам"":';
								|en = 'Update the ""Financial instruments AR/AP"" register:'; fa = 'Update the ""Financial instruments AR/AP"" register:';
								|it = 'Update the ""Financial instruments AR/AP"" register:';
								|pl = 'Update the ""Financial instruments AR/AP"" register:';
								|tr = '""Finansal araçlara dair muhasebeler"" kaydının güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Trường ""Đối tượng phân tích kế toán theo bạn hàng"" bị xóa khỏi lĩnh vực hoạt động';
								|ru = '- Поле ""Аналитика учета по партнерам"" очищается от направления деятельности';
								|en = '- The ""Accounting dimension by partners"" field is cleared of the line of business'; fa = '- The ""Accounting dimension by partners"" field is cleared of the line of business';
								|it = '- The ""Accounting dimension by partners"" field is cleared of the line of business';
								|pl = '- The ""Accounting dimension by partners"" field is cleared of the line of business';
								|tr = '- ""İş ortaklarına göre hesap analizi"" alanı iş kolundan kaldırılıyor'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.FinancialInstrumentsARAP.FullName());
	ItemsToRead.Add(Metadata.Catalogs.DimensionKeysOfAccountingByPartners.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.FinancialInstrumentsARAP.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.FinancialInstrumentsARAP.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = "AccumulationRegister.FinancialInstrumentsARAP";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();

	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	Register.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS Register
	|WHERE
	|	Register.AccountingDimensionByPartners.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|";
	
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Recorder"), SelectionParameters.FullRegistersNames);
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	FullObjectName = "AccumulationRegister.FinancialInstrumentsARAP";
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	ObjectsProcessed = 0;
	ExceptionsWhenUpdating = New Array;
	
	Query = New Query;
	Query.Text = "
		|SELECT DISTINCT
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Keys.Ref AS NewAccountingAnalyticsForPartners,
		|	Calculations.AccountingDimensionByPartners.Organization AS Organization,
		|	Calculations.AccountingDimensionByPartners.Partner AS Partner,
		|	Calculations.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|	Calculations.AccountingDimensionByPartners.Contract AS Contract,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
		|FROM
		|	AccumulationRegister.FinancialInstrumentsARAP AS Calculations
		|		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS Keys
		|			ON Keys.Organization = Calculations.AccountingDimensionByPartners.Organization
		|			AND Keys.Partner = Calculations.AccountingDimensionByPartners.Partner
		|			AND Keys.Counterparty = Calculations.AccountingDimensionByPartners.Counterparty
		|			AND Keys.Contract = Calculations.AccountingDimensionByPartners.Contract
		|			AND Keys.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|WHERE
		|	Calculations.Recorder = &Ref
		|";
		
	// The key is old analytics, the value is new
	Map = New Map();
	
	For Each DataString1 In UpdatedData Do
		
		ExceptionReason = "";
		Recommendation = "";
		
		BeginTransaction();
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			LockItem = Block.Add("AccumulationRegister.FinancialInstrumentsARAP.RecordSet");
			LockItem.SetValue("Recorder", DataString1.Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			ExceptionReason = "BadData"; 
			Recommendation = NStr("vi = 'Hãy kết chuyển lại chứng từ một cách thủ công.';
									|ru = 'Перепроведите документ вручную.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Перепроведите документ вручную.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
			
			RecordSet = AccumulationRegisters.FinancialInstrumentsARAP.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(DataString1.Recorder);
			RecordSet.Read();
			
			Query.SetParameter("Ref", DataString1.Recorder);
			AnalyticsData = Query.Execute().Unload();
			
			//AccountingDimensionByPartners
			For Each Record In RecordSet Do
				If Map.Get(Record.AccountingDimensionByPartners) = Undefined Then
					AnalyticsKeyData_ = AnalyticsData.FindRows(New Structure("AccountingDimensionByPartners",Record.AccountingDimensionByPartners));
					If AnalyticsKeyData_.Count() > 0 Then
						If ValueIsFilled(AnalyticsKeyData_[0].NewAccountingAnalyticsForPartners) Then
							NewKey = AnalyticsKeyData_[0].NewAccountingAnalyticsForPartners;
						Else
							NewKey = InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(AnalyticsKeyData_[0])
						EndIf;
						Map.Insert(Record.AccountingDimensionByPartners,NewKey);
						Record.AccountingDimensionByPartners = NewKey;
					EndIf;
				Else
					Record.AccountingDimensionByPartners = Map[Record.AccountingDimensionByPartners];
				EndIf;
			EndDo;
			
			ExceptionReason = "Record";
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), DataString1.Recorder);
			
			If ExceptionReason = "BadData" Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					DataString1.Recorder, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = "Record" Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(NStr("vi = 'Không thể xử lý tập hợp bản ghi của biểu ghi tích lũy ""Thanh toán theo các công cụ tài chính"".';
									|ru = 'Не удалось обработать набор записей регистра накопления ""Расчеты по финансовым инструментам"".';
									|en = 'Cannot process the ""Financial instruments AR/AP"" accumulation register record set.'; fa = 'Cannot process the ""Financial instruments AR/AP"" accumulation register record set.';
									|it = 'Cannot process the ""Financial instruments AR/AP"" accumulation register record set.';
									|pl = 'Cannot process the ""Financial instruments AR/AP"" accumulation register record set.';
									|tr = '""Finansal araçların mutabakatı"" birikim kaydına ait kayıt kümesi işlenemedi.'"), Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed > 0 Then
		InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
	EndIf;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
