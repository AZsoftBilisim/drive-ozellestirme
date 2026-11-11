#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
	NameOfChangeTable = "ChangesTableOtherAssetsAndLiabilitiesRecords"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
	Return StructureOfQueryTexts_

EndFunction

// Generates the text of the request for the formation of a temporary table "Inmovement of certain activitiesam".
//
// Parameters:
//  AdditionalFields	 - String	 - List of additional fields.
//  DifferentPeriodsInRegisteredRecordsArePossible - Boolean - specifies where the batch accounting parameters are stored, in the query parameters or in the temporary table vtparametersparty accounting for processing
// 
// Returns:
//  String - The text of the request for the formation of a temporary table for the movement of certain active arrays.
//
Function QueryTextTableTTRegisteredRecordsInOtherAssetsLiabilities(AdditionalFields = "", DifferentPeriodsInRegisteredRecordsArePossible = False) Export
	
	QueryText = "
	|SELECT
	|	Rows.Period                           AS Period,
	|	Rows.Organization                      AS Organization,
	|	Rows.Department                    AS Department,
	|	Rows.AssetRef                           AS AssetRef,
	|	Rows.Dimension                        AS Dimension,
	|	(CASE
	|		WHEN ISNULL(LinesOfBusiness.CostAccounting, FALSE)
	|			THEN Rows.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) END) AS LineOfBusiness,
	|	Rows.GLAccountSettings AS GLAccountSettings,
	|	Rows.DebitCredit AS DebitCredit,
	|
	|	Rows.AmountIncludingVAT                        AS AmountIncludingVAT,
	|	Rows.AmountExcludingVAT                      AS AmountExcludingVAT,
	|	(CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN Rows.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				AND NOT &GenerateVATChargedWhenIncludingInCost
	|			THEN Rows.SumMan
	|		ELSE Rows.AmountExcludingVATMan END)  AS SumMan,
	|	(CASE
	|		WHEN Rows.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				AND NOT &GenerateVATChargedWhenIncludingInCost
	|			THEN Rows.SumCompl
	|		ELSE Rows.AmountExcludingVATCompl END) AS SumCompl,
	|
	|	Rows.PermanentDifference                AS PermanentDifference,
	|	Rows.CostTD                 AS CostTD,
	|
	|	Rows.FinRecordID           AS FinRecordID,
	|	Rows.BusinessTransactionSetting   AS BusinessTransactionSetting
	|
	|	,&AdditionalFields
	|
	|INTO TTRegisteredRecordsInOtherAssetsLiabilities
	|FROM
	|	TTInitialRegisteredRecordsOnOtherAssetsLiabilities AS Rows
	|
	|	LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
	|		ON LinesOfBusiness.Ref = Rows.LineOfBusiness
	|	LEFT JOIN Constants AS TableOfConstants_ ON TRUE
	|
	|UNION ALL
	|
	|SELECT
	|	Rows.Period                           AS Period,
	|	Rows.Organization                      AS Organization,
	|	Rows.Department                    AS Department,
	|	Rows.AssetRef                           AS AssetRef,
	|	Rows.Dimension                        AS Dimension,
	|	(CASE
	|		WHEN ISNULL(LinesOfBusiness.CostAccounting, FALSE)
	|			THEN Rows.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) END) AS LineOfBusiness,
	|	Rows.GLAccountSettings AS GLAccountSettings,
	|	Rows.DebitCredit AS DebitCredit,
	|	0                                       AS AmountIncludingVAT,
	|	0                                       AS AmountExcludingVAT,
	|	(CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			Rows.AmountIncludingVAT - Rows.AmountExcludingVAT
	|		END)                                AS SumMan,
	|	Rows.SumCompl - Rows.AmountExcludingVATCompl AS SumCompl,
	|
	|	Rows.PermanentDifference                AS PermanentDifference,
	|	Rows.CostTD                 AS CostTD,
	|
	|	&Id                          AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses) AS BusinessTransactionSetting
	|
	|	,&AdditionalFields
	|
	|FROM
	|	TTInitialRegisteredRecordsOnOtherAssetsLiabilities AS Rows
	|
	|	LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
	|		ON LinesOfBusiness.Ref = Rows.LineOfBusiness
	|	LEFT JOIN Constants AS TableOfConstants_ ON TRUE
	|WHERE
	|	&GenerateVATChargedWhenIncludingInCost
	|	AND Rows.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|";
	
	JoinText = "LEFT JOIN Constants AS TableOfConstants_ ON TRUE";
	
	If Not DifferentPeriodsInRegisteredRecordsArePossible Then
		
		QueryText = StrReplace(QueryText, JoinText, "");
		
	Else
		
		// Batch accounting parameters are stored not in the query parameters, but in the fields of the same name in the temporary table of the Batch Accounting parameters for the audit.
		QueryText = StrReplace(QueryText, JoinText,
			"INNER JOIN TTParametersOfBatchAccountingForConducting AS BatchAccountingParameters
			|	ON BatchAccountingParameters.Period = BEGINOFPERIOD(Rows.Period, MONTH)
			|	 AND BatchAccountingParameters.Organization = Rows.Organization");
		
		ParametersArray = New Array;
		ParametersArray.Add("CompanyManagementAccounting");
		ParametersArray.Add("GenerateVATChargedWhenIncludingInCost");
		
		For Each CurrentParameter In ParametersArray Do
			QueryText = StrReplace(QueryText, "&" + CurrentParameter, "BatchAccountingParameters." + CurrentParameter);
		EndDo;
		
	EndIf;
	
	If StrFind(AdditionalFields, "RowID") <> 0 Then
		QueryText = StrReplace(QueryText, "&Id", "Rows.RowID");
	Else
		QueryText = StrReplace(QueryText, "&Id", "Rows.FinRecordID");
	EndIf;
	
	AddAdditionalFieldsToRequestText(AdditionalFields, QueryText);
	
	Return QueryText;
	
EndFunction

// Generates the text of the request for the formation of movements in the register "Movements on other assets and liabilities".
//
// Parameters:
//  AdditionalFields	 - String	 - List of additional fields.
// 
// Returns:
//  String - The text of the request for the formation of movements in the register of movementreferencesactivities.
//
Function QueryTextTableOtherAssetsAndLiabilitiesRecords(AdditionalFields = "") Export
	
	QueryText = "
	|SELECT
	|	Rows.Period AS Period,
	|	Rows.Organization AS Organization,
	|	Rows.Department AS Department,
	|	CASE 
	|		WHEN ISNULL(LB.CostAccounting, FALSE) THEN
	|			Rows.LineOfBusiness
	|		ELSE
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	Rows.AssetRef AS AssetRef,
	|	Rows.Dimension AS Dimension,
	|	Rows.GLAccountSettings AS GLAccountSettings,
	|	Rows.DebitCredit AS DebitCredit,
	|
	|	Rows.SumCompl AS SumCompl,
	|	Rows.SumMan AS SumMan,
	|	Rows.AmountIncludingVAT AS AmountIncludingVAT,
	|	Rows.AmountExcludingVAT AS AmountExcludingVAT,
	|
	|	Rows.PermanentDifference AS PermanentDifference,
	|	Rows.CostTD AS CostTD,
	|
	|	Rows.FinRecordID AS FinRecordID,
	|	Rows.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|	,&AdditionalFields
	|
	|FROM
	|	TTRegisteredRecordsInOtherAssetsLiabilities AS Rows
	|	LEFT JOIN Catalog.LinesOfBusiness AS LB
	|		ON LB.Ref = Rows.LineOfBusiness
	|WHERE
	|	(Rows.AmountExcludingVAT <> 0 OR Rows.AmountIncludingVAT <> 0 OR Rows.SumMan <> 0
	|	OR Rows.SumCompl <> 0 OR Rows.PermanentDifference <> 0 OR Rows.CostTD <> 0)
	|";
	
	AddAdditionalFieldsToRequestText(AdditionalFields, QueryText);
	
	Return QueryText;
	
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
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.DataPathAccountingLocation = "Department";
	ReflectionParameters.PathToDataLineOfBusiness = "LineOfBusiness";
	ReflectionParameters.PathToDataDivision = "Department";
	ReflectionParameters.ManResources.Add("SumMan");
	ReflectionParameters.LocalResources.Add("SumCompl");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.OtherAssetsLiabilities;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.AssetAndLiabilityItem.DataPath = "AssetRef";
	ReflectionParameters.StructureOfAnalytics.AssetsLiabilitiesDimension.DataPath = "Dimension";
	ReflectionParameters.StructureOfAnalytics.FinancialAccountingGroup.Insert("Value", Undefined);
	ReflectionParameters.StructureOfAnalytics.Counterparty.Insert("Value", Undefined);
	ReflectionParameters.DataPathDopSettingUpHouseholdOfOperation = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.OtherExpenses)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.OtherExpensesLiabilities)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.OtherIncome)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.OtherIncomeAssetsLiabilities)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.ARWriteOff)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.ARWriteOffToAssetsLiabilities)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferForOtherPurposes)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.CloseFixedAssetWriteOffExpenses)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.DisposeFixedAssets)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.TransferOfGoodsBetweenBranchOffices)
		|			AND DataSourceAlias.DebitCredit = VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.InternalGoodsReceipt)
		|		WHEN DataSourceAlias.AssetRef IN (VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.RemunerationProvisions), VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProvisionsForInsurancePremiums))
		|			AND DataSourceAlias.DebitCredit = VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsWriteOff)
		|		WHEN DataSourceAlias.AssetRef = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle)
		|			AND DataSourceAlias.DebitCredit = VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualVATFromSalesOfGoodsInTransit)
		|		ELSE DataSourceAlias.BusinessTransactionSetting
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	IdentifyIndicators(ReflectionParameters);
	
	ReflectionParameters.DebitCondition = StrReplace(
		"DataSourceAlias.DebitCredit = VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
		
	ReflectionParameters.ConditionCredit = StrReplace(
		"DataSourceAlias.DebitCredit = VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)",
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
// It is called when carrying out a document in which it is necessary to calculate and record data in the register "Movements of Other assets and liabilities".
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - Undefined, TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
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
	TempTablesManager = Undefined, DataForRegisteringTasks = Undefined) Export
	
	If Not DataForRegisteringTasks = Undefined Then
		Return DataForRegisteringTasks;
	EndIf;

	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	
	Return DataTable;

EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure AddAdditionalFieldsToRequestText(AdditionalFields, QueryText)

	If Not ValueIsFilled(AdditionalFields) Then
		QueryText = StrReplace(QueryText, ",&AdditionalFields", "");
		Return;
	EndIf; 
	
	TextAdditionalFields = "";
	
	FieldList = StrSplit(AdditionalFields, ",");
	For Each FieldName In FieldList Do
		TextAdditionalFields = TextAdditionalFields + "
		|	,Rows." + FieldName;
	EndDo; 
	
	QueryText = StrReplace(QueryText, ",&AdditionalFields", TextAdditionalFields); 

EndProcedure

// Defines register indicators
//
// Parameters:
//  ReflectionParameters - See ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Procedure IdentifyIndicators(ReflectionParameters)
	
	// Sum
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("SumMan");
	IndicatorReflectionParameters.LocalResources.Add("SumCompl");
	IndicatorReflectionParameters.DataPathRecordFinID = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.AssetRef = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle)
		|			AND DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|			THEN DataSourceAlias.ARAPObject.UUID
		|		ELSE DataSourceAlias.FinRecordID
		|	END",
		"DataSourceAlias",
		FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, IndicatorReflectionParameters);
	
EndProcedure


#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.48";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("e8ea5d4b-ae61-1111-a34e-ce03ce438a26");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("ru = 'Обновление регистра ""Движения Прочие активы и пассивы"":';
								|vi = 'Update the ""Other assets and liabilities records"" register:';
								|en = 'Update the ""Other assets and liabilities records"" register:'; fa = 'Update the ""Other assets and liabilities records"" register:';
								|it = 'Update the ""Other assets and liabilities records"" register:';
								|pl = 'Update the ""Other assets and liabilities records"" register:';
								|tr = '""Diğer Varlıklar ve Yükümlülükler Hareketleri"" kaydının güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("ru = '- Очищает идентификатор финзаписи для распределения доходов по направлениям деятельности';
								|vi = '- Clears the financial record ID for income allocation to lines of business';
								|en = '- Clears the financial record ID for income allocation to lines of business'; fa = '- Clears the financial record ID for income allocation to lines of business';
								|it = '- Clears the financial record ID for income allocation to lines of business';
								|pl = '- Clears the financial record ID for income allocation to lines of business';
								|tr = 'Gelirlerin faaliyet alanlarına göre dağıtımı için finansal kayıt tanımlayıcısını temizler'"));
	ListOfDescriptions.Add(NStr("ru = '- Заменяет некорректные ссылки на статьи ""Основные средства"" и ""Нематериальные активы""';
								|vi = '- Replaces incorrect links to the ""Fixed assets"" and ""Intangible assets"" items';
								|en = '- Replaces incorrect links to the ""Fixed assets"" and ""Intangible assets"" items'; fa = '- Replaces incorrect links to the ""Fixed assets"" and ""Intangible assets"" items';
								|it = '- Replaces incorrect links to the ""Fixed assets"" and ""Intangible assets"" items';
								|pl = '- Replaces incorrect links to the ""Fixed assets"" and ""Intangible assets"" items';
								|tr = '""Sabit kıymetler"" ve ""Maddi olmayan duran varlıklar"" kalemlerine olan geçersiz bağlantıları değiştirir'"));
	ListOfDescriptions.Add(NStr("ru = '- Удаляет движения по непроведенным документам с акцизами';
								|vi = '- Deletes records for unposted documents with excises';
								|en = '- Deletes records for unposted documents with excises'; fa = '- Deletes records for unposted documents with excises';
								|it = '- Deletes records for unposted documents with excises';
								|pl = '- Deletes records for unposted documents with excises';
								|tr = '- Kaydedilmemiş belgelerdeki özel tüketim vergisi kayıtlarını siler'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.FullName());
	ItemsToRead.Add(Metadata.Documents.InventoryConsumption.FullName());
	ItemsToRead.Add(Metadata.Documents.WriteOffOfGoodsShortages.FullName());
	ItemsToRead.Add(Metadata.Documents.ReversingEntry.FullName());
	
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Data logging handler for updates
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	RegisterMetadata = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords;
	FullRegisterName = RegisterMetadata.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	Query.Parameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	Query.Parameters.Insert("PointInTime", New PointInTime('00010101'));
	
	Query.Text = "
	|SELECT DISTINCT
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.PointInTime AS PointInTime
	|INTO TTRecordersForProcessing
	|FROM
	|	AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS RegisterRecords
	|WHERE
	|	RegisterRecords.Active
	|	AND (
	|		RegisterRecords.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|		AND RegisterRecords.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.AllocationOfIncomeByLinesOfBusiness)
	|		AND RegisterRecords.FinRecordID <> &IDOfUnusedFinRecord
	|	OR
	|		RegisterRecords.AssetRef = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IntangibleAssets)
	|	OR
	|		RegisterRecords.AssetRef = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.FixedAssets)
	|	)
	|
	|UNION
	|
	|SELECT
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.PointInTime AS PointInTime
	|FROM
	|	AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS RegisterRecords
	|	INNER JOIN Document.InventoryConsumption AS DocumentInventoryConsumption
	|		ON DocumentInventoryConsumption.Ref = RegisterRecords.Recorder
	|		AND NOT DocumentInventoryConsumption.Posted
	|WHERE
	|	RegisterRecords.Active
	|
	|UNION
	|
	|SELECT
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.PointInTime AS PointInTime
	|FROM
	|	AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS RegisterRecords
	|	INNER JOIN Document.WriteOffOfGoodsShortages AS DocumentWriteOffOfGoodsShortages
	|		ON DocumentWriteOffOfGoodsShortages.Ref = RegisterRecords.Recorder
	|		AND NOT DocumentWriteOffOfGoodsShortages.Posted
	|WHERE
	|	RegisterRecords.Active
	|
	|UNION
	|
	|SELECT
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.PointInTime AS PointInTime
	|FROM
	|	AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS RegisterRecords
	|	INNER JOIN Document.ReversingEntry AS DocumentReversingEntry
	|		ON DocumentReversingEntry.Ref = RegisterRecords.Recorder
	|		AND NOT DocumentReversingEntry.Posted
	|WHERE
	|	RegisterRecords.Active
	|
	|INDEX BY
	|	Recorder
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegistrarsReadyForProcessing.Recorder AS Recorder,
	|	RegistrarsReadyForProcessing.PointInTime AS PointInTime
	|INTO TTVariousRecordersForProcessing
	|FROM
	|	TTRecordersForProcessing AS RegistrarsReadyForProcessing
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTRecordersForProcessing AS RecordersOtherPeriods
	|		WHERE
	|			RecordersOtherPeriods.Recorder = RegistrarsReadyForProcessing.Recorder
	|			AND RecordersOtherPeriods.PointInTime < RegistrarsReadyForProcessing.PointInTime
	|		)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTRecordersForProcessing
	|";
	
	Result = Query.Execute();
	
	Query.Text = "
	|SELECT TOP 1000
	|	RegistrarsReadyForProcessing.Recorder AS Recorder,
	|	RegistrarsReadyForProcessing.PointInTime AS PointInTime
	|FROM
	|	TTVariousRecordersForProcessing AS RegistrarsReadyForProcessing
	|WHERE
	|	RegistrarsReadyForProcessing.PointInTime > &PointInTime
	|ORDER BY
	|	RegistrarsReadyForProcessing.PointInTime
	|";
	
	Result = Query.Execute();
	
	While Not Result.IsEmpty() Do
		ResultTable2 = Result.Unload();
		Recorders = ResultTable2.UnloadColumn("Recorder");
		
		InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
		
		RowsCount = ResultTable2.Count();
		Query.SetParameter("PointInTime", ResultTable2[RowsCount - 1]["PointInTime"]);
		Result = Query.Execute();
	EndDo;
	
EndProcedure

// The update handler
// 
// Parameters:
//  Parameters - Structure - Handler Parameters:
//   * SubsystemVersionAtStartUpdates - String - the version of the subsystem.
//   * HandlerName - String - name of the handler.
//   * UpdatedData - Structure
//   * ProcessingCompleted - Boolean, Undefined - indicates End of processing.
//   * Queue - Number - the queue.
//   * ExecutionProgress - Structure:
//     ** TotalObjectCount - Number - total objects processed.
//     ** ProcessedObjectsCount1 - Number - processed objects.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	RegisterMetadata = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords;
	FullRegisterName = RegisterMetadata.FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	IDOfUnusedFinRecord = DocumentsPosting.IDOfUnusedFinRecord();
	AssetLiabilityItemManager = ChartsOfCharacteristicTypes.AssetLiabilityItems;
	
	For Each DataString1 In UpdatedData Do
		Recorder = DataString1.Recorder;
		DocumentType = TypeOf(Recorder);
		ThisIsDistributionOfIncomeByAreasOfActivity = 
			DocumentType = Type("DocumentRef.AllocationOfIncomeByLinesOfBusiness");
		
		ExceptionReason = "";
		Recommendation = "";
	
		ListOfDescriptions = New Array;
		ListOfDescriptions.Add(NStr("ru = 'Не удалось обработать набор записей регистра накопления ""Движения Прочие активы и пассивы"":';
									|vi = 'Cannot process the record set of the ""Other assets and liabilities records"" accumulation register:';
									|en = 'Cannot process the record set of the ""Other assets and liabilities records"" accumulation register:'; fa = 'Cannot process the record set of the ""Other assets and liabilities records"" accumulation register:';
									|it = 'Cannot process the record set of the ""Other assets and liabilities records"" accumulation register:';
									|pl = 'Cannot process the record set of the ""Other assets and liabilities records"" accumulation register:';
									|tr = 'Birikim kaydı ""Diğer Varlıklar ve Yükümlülükler Hareketleri""  kayıt kümesi işlenemedi:'"));
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.OtherAssetsAndLiabilitiesRecords.RecordSet");
			LockItem.SetValue("Recorder", Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
				
			ExceptionReason = "BadData";
			Recommendation = NStr("vi = 'Hãy kết chuyển lại chứng từ một cách thủ công.';
									|ru = 'Перепроведите документ вручную.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Перепроведите документ вручную.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
			
			RecordSet = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Recorder);
			RecordSet.Read();
			
			If (DocumentType = Type("DocumentRef.InventoryConsumption")
				Or DocumentType = Type("DocumentRef.WriteOffOfGoodsShortages")
				Or DocumentType = Type("DocumentRef.ReversingEntry"))
				And Not Common.ObjectAttributeValue(Recorder, "Posted") = True Then
					RecordSet.Clear();
			EndIf;
			
			For Each Record In RecordSet Do
				If ThisIsDistributionOfIncomeByAreasOfActivity
					And Record.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.AllocationOfIncomeByLinesOfBusiness
					And Record.FinRecordID <> IDOfUnusedFinRecord Then
					Record.FinRecordID = IDOfUnusedFinRecord;
					ListOfDescriptions.Add(NStr("ru = '- Не удалось очистить идентификатор финзаписи для распределения доходов по направлениям деятельности';
												|vi = '- Cannot clear the financial record ID for income allocation to lines of business';
												|en = '- Cannot clear the financial record ID for income allocation to lines of business'; fa = '- Cannot clear the financial record ID for income allocation to lines of business';
												|it = '- Cannot clear the financial record ID for income allocation to lines of business';
												|pl = '- Cannot clear the financial record ID for income allocation to lines of business';
												|tr = 'Gelirlerin faaliyet alanlarına göre dağıtımı için finansal kayıt tanımlayıcısı temizlenemedi'"));
				EndIf;
				
				If Record.AssetRef = AssetLiabilityItemManager.IntangibleAssets Then
					Record.AssetRef = AssetLiabilityItemManager.ManBalanceIntangibleAssets;
					ListOfDescriptions.Add(NStr("ru = '- Не удалось заменить некорректную ссылку на статью ""Нематериальные активы""';
												|vi = '- Cannot replace the incorrect link to the ""Intangible assets"" item';
												|en = '- Cannot replace the incorrect link to the ""Intangible assets"" item'; fa = '- Cannot replace the incorrect link to the ""Intangible assets"" item';
												|it = '- Cannot replace the incorrect link to the ""Intangible assets"" item';
												|pl = '- Cannot replace the incorrect link to the ""Intangible assets"" item';
												|tr = '- ""Maddi olmayan duran varlıklar"" kalemine olan geçersiz bağlantı değiştirilemedi'"));
				ElsIf Record.AssetRef = AssetLiabilityItemManager.FixedAssets Then
					Record.AssetRef = AssetLiabilityItemManager.ManBalanceFixedAssets;
					ListOfDescriptions.Add(NStr("ru = '- Не удалось заменить некорректную ссылку на статью ""Основные средства""';
												|vi = '- Cannot replace the incorrect link to the ""Fixed assets"" item';
												|en = '- Cannot replace the incorrect link to the ""Fixed assets"" item'; fa = '- Cannot replace the incorrect link to the ""Fixed assets"" item';
												|it = '- Cannot replace the incorrect link to the ""Fixed assets"" item';
												|pl = '- Cannot replace the incorrect link to the ""Fixed assets"" item';
												|tr = '- ""Sabit kıymetler"" kalemine olan geçersiz bağlantı değiştirilemedi'"));
				EndIf;
			EndDo;
			
			ExceptionReason = "Record";
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteRecordSet(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Recorder);
			
			If ExceptionReason = "BadData" Then
				
				InfobaseUpdate.FileIssueWithData(Recorder, Recommendation, Parameters);
				
			ElsIf ExceptionReason = "Record" Then
				
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
	
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);

EndProcedure

#EndRegion

#EndRegion

#EndIf
