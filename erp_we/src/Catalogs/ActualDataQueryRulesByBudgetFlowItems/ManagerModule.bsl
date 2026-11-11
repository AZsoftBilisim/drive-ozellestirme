#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Starts a background task for registering documents to reflect the fact
// 
// Parameters:
// 	Rule - CatalogRef.ActualDataQueryRulesByBudgetFlowItems - The rule of obtaining a fact. 
// 	BeginOfPeriod - Date - the beginning of the period.
// 	EndOfPeriod - Date - end of the period.
// 	ComparisonAttributes - Structure - Valid, Valid according to the fact receipt Rule before recording.
// 	ReflectByRule - Boolean - the need to reflect the documents in budgeting according to the specified rule.
//
Procedure StartDocumentRegistrationForBackgroundReflection(Rule, Val BeginOfPeriod, Val EndOfPeriod,
	ComparisonAttributes, ReflectByRule) Export
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(ComparisonAttributes) And ComparisonAttributes.Property("ValidFrom") Then
		If ComparisonAttributes.ValidFrom <> BeginOfPeriod Then
			BeginOfPeriod = Min(BeginOfPeriod, ComparisonAttributes.ValidFrom);
		EndIf;
		
		If ComparisonAttributes.ValidTo <> EndOfPeriod And ValueIsFilled(EndOfPeriod) Then
			If ValueIsFilled(ComparisonAttributes.ValidTo) Then
				EndOfPeriod = Max(EndOfPeriod, ComparisonAttributes.ValidTo);
			Else
				EndOfPeriod = ComparisonAttributes.ValidTo;
			EndIf;
		EndIf;
	EndIf;
	
	RuleDescription_ = Rule.GetObject(); 
	DocumentsKinds = ActualBudgetingDataServer.DetermineTypesOfDCSDocuments(RuleDescription_);
	
	Var_Key = "RegisterDocumentsForRecordingFact" + String(Rule.UUID());
	
	Filter = New Structure();
	Filter.Insert("Key", Var_Key);
	Filter.Insert("State", BackgroundJobState.Active);
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	
	If ActiveTasks.Count() > 0 Then
		For Each ActiveTask In ActiveTasks Do
			ActiveTask.Cancel();
		EndDo;
	EndIf;
	
	JobDescription = NStr("vi = 'Đăng ký chứng từ được thực hiện để phản ánh thực tế';
							|ru = 'Выполняется регистрация документов для отражения факта';
							|en = 'Registering documents for recording actual data'; fa = 'Registering documents for recording actual data';
							|it = 'Registrazione documenti per visualizzazione del fatto è in corso';
							|pl = 'Trwa rejestracja dokumentów do odzwierciedlenia faktu';
							|tr = 'Yansıma bilgileri için belge kayıt işlemi kaydediliyor'");
	
	ExportProcedureParameters = New Array();
	ExportProcedureParameters.Add(DocumentsKinds);
	ExportProcedureParameters.Add(Rule);
	ExportProcedureParameters.Add(BeginOfPeriod);
	ExportProcedureParameters.Add(EndOfPeriod);
	ExportProcedureParameters.Add(ReflectByRule);
	
	JobParameters = New Array();
	JobParameters.Add("Catalogs.ActualDataQueryRulesByBudgetFlowItems.RegisterDocumentsForReflection");
	JobParameters.Add(ExportProcedureParameters);
	
	BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, Var_Key, JobDescription);
	
EndProcedure

// The procedure registers documents to reflect the fact.
// 
// Parameters:
//	DocumentsKinds - Array of String - Array of document type names from metadata.
//	Rule - CatalogRef.ActualDataQueryRulesByBudgetFlowItems - The rule of obtaining a fact.
//	BeginOfPeriod - Date - Optional. Start of the period.
//  EndOfPeriod - Date - Optional. End of the period.
//  ReflectByRule - Boolean - the need to reflect the documents in budgeting according to the specified rule.
//
Procedure RegisterDocumentsForReflection(DocumentsKinds, Rule, BeginOfPeriod, EndOfPeriod, ReflectByRule = False) Export
	
	ResetBudgetCache(Rule);
	
	If DocumentsKinds.Count() = 1 And DocumentsKinds[0] = Catalogs.MetadataObjectIDs.EmptyRef() Then
		DocumentsKinds = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
			Common.MetadataObjectIDs(Metadata.Documents), False);
	EndIf;
	NamesOfDocumentTypes = Common.ObjectsAttributesValues(DocumentsKinds, "Name, FullName");
	
	Separator = "
	|
	|UNION ALL
	|
	|";
	
	QueryTextTemplate2 =
	"SELECT
		|	Table.Ref AS Document,
		|	Table.Date AS RecordPeriod,
		|	&TextDocumentType AS DocumentKindName
		|FROM
		|	&Table AS Table
		|WHERE
		|	&ConditionText";
	
	QueryTexts = New Array;
	For Each KeyAndValue In NamesOfDocumentTypes Do
		
		QueryText = StrReplace(QueryTextTemplate2, "&Table", KeyAndValue.Value.FullName);
		QueryText = StrReplace(QueryText, "&TextDocumentType", """" + KeyAndValue.Value.Name + """");
		
		If Metadata.Documents[KeyAndValue.Value.Name].Posting = 
				Metadata.ObjectProperties.Posting.Allow Then
			ConditionText = "Table.Posted";
		Else
			ConditionText = "NOT Table.DeletionMark";
		EndIf;
		If ValueIsFilled(BeginOfPeriod) And ValueIsFilled(EndOfPeriod) Then
			ConditionText = ConditionText + Chars.LF + "AND Table.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod";
		ElsIf ValueIsFilled(BeginOfPeriod) Then
			ConditionText = ConditionText + Chars.LF + "AND Table.Date >= &BeginOfPeriod";
		ElsIf ValueIsFilled(EndOfPeriod) Then
			ConditionText = ConditionText + Chars.LF + "AND Table.Date <= &EndOfPeriod";
		EndIf;
		
		QueryText = StrReplace(QueryText, "&ConditionText", ConditionText);
		
		QueryTexts.Add(QueryText);
	EndDo;
	
	QueryText = StrConcat(QueryTexts, Separator);
	QueryText = RequestSchemes.SetRoomToTemporaryTable(QueryText, "DocumentsTable");
	
	BeginTransaction();
	
	Try
	
		Block = New DataLock;
		LockItem = Block.Add("Constant.NumberOfJobForPostingInBudgeting");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		QueryText = QueryText + ";
		| SELECT * FROM DocumentsTable";
		
		Var_Key = "DocumentPostingInBudgeting";
		
		Filter = New Structure();
		Filter.Insert("Key", Var_Key);
		Filter.Insert("State", BackgroundJobState.Active);
		
		ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
		If ActiveTasks.Count() = 0 Then
			QueryText = QueryText + "
			| WHERE NOT Document IN (SELECT DISTINCT Document FROM InformationRegister.JobsForPostingInBudgeting)";
		EndIf;
		
		Query = New Query(QueryText);
		Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
		Query.SetParameter("EndOfPeriod", ?(ValueIsFilled(EndOfPeriod), EndOfDay(EndOfPeriod), EndOfPeriod));
		
		DocumentsTable = Query.Execute().Unload();
		
		JobNumber = Constants.NumberOfJobForPostingInBudgeting.Get();
		JobNumber = JobNumber + 1;
		Constants.NumberOfJobForPostingInBudgeting.Set(JobNumber + 1);
	
		CommitTransaction();
	Except
		RollbackTransaction();
		LREvent = NStr("vi = 'Biểu ghi chứng từ phản ánh thực tế';
						|ru = 'Регистрация документов для отражения факта';
						|en = 'Register documents for recording actual data'; fa = 'Register documents for recording actual data';
						|it = 'Registrazione documenti per visualizzazione del fatto';
						|pl = 'Rejestracja dokumentów do odzwierciedlenia faktu';
						|tr = 'Belgelerin bilgiyi yansıtacak şekilde kaydedilmesi'", Common.DefaultLanguageCode());
		WriteLogEvent(
			LREvent, 
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
			
	For Each Page1 In DocumentsTable Do
		RecordSet = InformationRegisters.JobsForPostingInBudgeting.CreateRecordSet();
		RecordSet.Filter.JobNumber.Set(JobNumber);
		RecordSet.Filter.Document.Set(Page1.Document);
		
		BeginTransaction();
		
		Try
			Block = New DataLock;
			LockItem = Block.Add();
			LockItem.Region = "InformationRegister.JobsForPostingInBudgeting";
			LockItem.SetValue("JobNumber",	JobNumber);
			LockItem.SetValue("Document",		Page1.Document);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			RecordingReflection = RecordSet.Add();
			RecordingReflection.JobNumber = JobNumber;
			FillPropertyValues(RecordingReflection,Page1);
			RecordSet.Write(True);
		
			CommitTransaction();
		Except
			RollbackTransaction();
			LREvent = NStr("vi = 'Biểu ghi chứng từ phản ánh thực tế';
							|ru = 'Регистрация документов для отражения факта';
							|en = 'Register documents for recording actual data'; fa = 'Register documents for recording actual data';
							|it = 'Registrazione documenti per visualizzazione del fatto';
							|pl = 'Rejestracja dokumentów do odzwierciedlenia faktu';
							|tr = 'Belgelerin bilgiyi yansıtacak şekilde kaydedilmesi'", Common.DefaultLanguageCode());
			WriteLogEvent(
				LREvent,
				EventLogLevel.Error,,, 
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
		
	EndDo;
	
	If ReflectByRule Then
		ActualBudgetingDataServer.ReflectDocumentsInBudgeting(BeginOfPeriod, EndOfPeriod, , Rule);
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

Function ThereAreDisabledRulesForGettingFact(BudgetFlowItem = Undefined, DataSource = Undefined) Export
	
	QueryText = "
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRules_
	|WHERE
	|	ActualDataQueryRules_.DataSourceSection = VALUE(Enum.SectionsOfBudgetingDataSources.OperationalAccounting)
	|	AND ActualDataQueryRules_.RuleType = VALUE(Enum.ActualBudgetingDataQueryRuleType.ActualData)
	|	AND NOT ActualDataQueryRules_.DeletionMark
	|	AND &ThisIsDisabledSettingRule
	|	AND &SelectionConditionsForBudgetItem
	|	AND &SelectionCriteriaByDataSource
	|";
	
	If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
		ThisIsDisabledSettingRule = "VALUETYPE(ActualDataQueryRules_.DataSource) = TYPE(Catalog.BusinessTransactionsSettings)";
	Else
		ThisIsDisabledSettingRule = "VALUETYPE(ActualDataQueryRules_.DataSource) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)";
	EndIf;
	
	If ValueIsFilled(BudgetFlowItem) Then
		SelectionConditionsForBudgetItem = "ActualDataQueryRules_.BudgetFlowItem = &BudgetFlowItem";
	Else
		SelectionConditionsForBudgetItem = "TRUE";
	EndIf;
	
	If ValueIsFilled(DataSource) Then
		SelectionCriteriaByDataSource = "ActualDataQueryRules_.DataSource = &DataSource";
	Else
		SelectionCriteriaByDataSource = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ThisIsDisabledSettingRule", ThisIsDisabledSettingRule);
	QueryText = StrReplace(QueryText, "&SelectionConditionsForBudgetItem", SelectionConditionsForBudgetItem);
	QueryText = StrReplace(QueryText, "&SelectionCriteriaByDataSource", SelectionCriteriaByDataSource);
	
	Query = New Query(QueryText);
	Query.SetParameter("BudgetFlowItem", BudgetFlowItem);
	Query.SetParameter("DataSource", DataSource);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

Function RuleOnCorrespondenceTable(Rule) Export
	
	RuleType = TypeOf(Rule);
	
	If RuleType = Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems") Then
		AttributeValuesForRule = Common.ObjectAttributesValues(
			Rule, "DataSource,DataSourceSection,RuleType");
	ElsIf RuleType = Type("CatalogObject.ActualDataQueryRulesByBudgetFlowItems") Then
		AttributeValuesForRule = Rule;
	ElsIf (RuleType = Type("Structure") Or RuleType = Type("FormDataStructure"))
		And Rule.Property("DataSource")
		And Rule.Property("DataSourceSection")
		And Rule.Property("RuleType") Then
		AttributeValuesForRule = Rule;
	ElsIf RuleType = Type("ValueTableRow") Then
		RulesTable = Rule.Owner(); // ValueTable -
		ColumnsOfRulesTable = RulesTable.Columns;
		If ColumnsOfRulesTable.Find("DataSource") <> Undefined
		   And ColumnsOfRulesTable.Find("DataSourceSection") <> Undefined
		   And ColumnsOfRulesTable.Find("RuleType") <> Undefined Then
			AttributeValuesForRule = Rule;
		Else
			Return False;
		EndIf;
	Else
		Return False;
	EndIf;
	
	Return AttributeValuesForRule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
		And GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters")
		And ?(ValueIsFilled(AttributeValuesForRule.DataSource),
			DataSourcesServer.ThisIsSettingUpBusinessOfOperation(AttributeValuesForRule.DataSource),
			AttributeValuesForRule.RuleType <> Enums.ActualBudgetingDataQueryRuleType.ActualData
			Or Not GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems"));
	
EndFunction

Function RuleOnItemOfAssetsLiabilities(Rule) Export
	
	RuleType = TypeOf(Rule);
	
	If RuleType = Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems") Then
		AttributeValuesForRule = Common.ObjectAttributesValues(
			Rule, "DataSource,DataSourceSection,RuleType");
	ElsIf RuleType = Type("CatalogObject.ActualDataQueryRulesByBudgetFlowItems") Then
		AttributeValuesForRule = Rule;
	ElsIf (RuleType = Type("Structure") Or RuleType = Type("FormDataStructure"))
		And Rule.Property("DataSource")
		And Rule.Property("DataSourceSection")
		And Rule.Property("RuleType") Then
		AttributeValuesForRule = Rule;
	ElsIf RuleType = Type("ValueTableRow") Then
		RulesTable = Rule.Owner(); // ValueTable -
		ColumnsOfRulesTable = RulesTable.Columns;
		If ColumnsOfRulesTable.Find("DataSource") <> Undefined
		   And ColumnsOfRulesTable.Find("DataSourceSection") <> Undefined
		   And ColumnsOfRulesTable.Find("RuleType") <> Undefined Then
			AttributeValuesForRule = Rule;
		Else
			Return False;
		EndIf;
	Else
		Return False;
	EndIf;
	
	Return AttributeValuesForRule.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
		And ?(ValueIsFilled(AttributeValuesForRule.DataSource),
			DataSourcesServer.ThisIsItemOfAssetsLiabilities(AttributeValuesForRule.DataSource),
			AttributeValuesForRule.RuleType = Enums.ActualBudgetingDataQueryRuleType.ActualData
			And GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems"));
	
EndFunction

#EndRegion

#Region Private

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	Reports.ResultOfActualDataQuery.AddBudgetItemReportCommand(ReportsCommands);
	Return; // Not used in UT.
	
EndProcedure

#EndRegion

// Clears the auxiliary cache of budget types
// 
// Parameters:
//   Ref - CatalogRef.ActualDataQueryRulesByBudgetFlowItems
//
Procedure ResetBudgetCache(Ref)
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	FinancialReportItemsItemKindAttributes.Ref
		|INTO ElementsOfFinancialStatements
		|FROM
		|	Catalog.FinancialReportItems.ItemKindAttributes AS FinancialReportItemsItemKindAttributes
		|WHERE
		|	FinancialReportItemsItemKindAttributes.Attribute = &Attribute
		|	AND FinancialReportItemsItemKindAttributes.Value = &Value
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Catalog.Owner AS Ref
		|FROM
		|	ElementsOfFinancialStatements AS ElementsOfFinancialStatements
		|		LEFT JOIN Catalog.FinancialReportItems AS Catalog
		|		ON ElementsOfFinancialStatements.Ref = Catalog.Ref";
		
	ComparisonAttributes = Common.ObjectAttributesValues(Ref, "BudgetFlowItem");

	Query.SetParameter("Value", ComparisonAttributes.BudgetFlowItem);
	Query.SetParameter("Attribute", ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.BudgetFlowItem);
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		
		RecordSet = InformationRegisters.CacheOfAuxiliaryBudgetProfileData.CreateRecordSet();
		RecordSet.Filter.BudgetProfile.Set(SelectionDetailRecords.Ref);
		RecordSet.Write(True);
		
	EndDo;
	
EndProcedure

#Region SettingUpReceiptOfFactByCorrespondenceOfRegisters

Procedure ChangeOptionForSettingUpRulesForGettingFact (Parameters, StorageAddress) Export
	
	ByCorrespondingRegisters = Parameters.SettingUpRulesForObtainingFactsFromCorrespondingRegisters;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ActualDataQueryRulesByBudgetFlowItems.Ref AS Ref,
	|	ActualDataQueryRulesByBudgetFlowItems.DataSource AS DataSource,
	|	CAST(ActualDataQueryRulesByBudgetFlowItems.DataSource AS Catalog.BusinessTransactionsSettings).DataSource AS NameOfTheDataSourceTemplate,
	|	CAST(ActualDataQueryRulesByBudgetFlowItems.DataSource AS Catalog.BusinessTransactionsSettings).UseInBudgeting AS UseInBudgeting,
	|	CAST(ActualDataQueryRulesByBudgetFlowItems.DataSource AS Catalog.BusinessTransactionsSettings).Receipt AS Receipt,
	|	CAST(ActualDataQueryRulesByBudgetFlowItems.DataSource AS Catalog.BusinessTransactionsSettings).Expense AS Expense,
	|	ActualDataQueryRulesByBudgetFlowItems.RuleType
	|FROM
	|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|WHERE
	|	NOT ActualDataQueryRulesByBudgetFlowItems.DeletionMark
	|	AND ActualDataQueryRulesByBudgetFlowItems.DataSourceSection = VALUE(Enum.SectionsOfBudgetingDataSources.OperationalAccounting)
	|	AND VALUETYPE(ActualDataQueryRulesByBudgetFlowItems.DataSource) = TYPE(Catalog.BusinessTransactionsSettings)";
	
	BeginTransaction();
	
	Try
		
		ModifiedDataSources = DefineReplacementsForDataTypesAccountingForDataSources(ByCorrespondingRegisters);
		If Not ByCorrespondingRegisters
			And LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed() Then
			UnchangedDataSources = DefineReplacementsForDataTypesAccountingForDataSources(False, True);
			For Each KeyAndValue In UnchangedDataSources Do
				ModifiedDataSources.Delete(KeyAndValue.Key);
			EndDo;
		EndIf;
		ChangeWhetherDataSourcesAreUsedInBudgeting(ModifiedDataSources, ByCorrespondingRegisters);
		For Each DataSource In ModifiedDataSources Do
			DataSourceObject = DataSource.Key.GetObject();
			DataSourceObject.Lock();
			DataSourceParameters = DataSource.Value;
			If DataSourceParameters.Property("UseInBudgeting") Then
				DataSourceObject.UseInBudgeting = DataSourceParameters.UseInBudgeting;
			EndIf;
			If DataSourceParameters.Property("Receipt") Then
				DataSourceObject.Receipt = ?(TypeOf(DataSourceParameters.Receipt) = Type("Structure"), DataSourceParameters.Receipt.New, DataSourceParameters.Receipt);
			EndIf;
			If DataSourceParameters.Property("Expense") Then
				DataSourceObject.Expense = ?(TypeOf(DataSourceParameters.Expense) = Type("Structure"), DataSourceParameters.Expense.New, DataSourceParameters.Expense);
			EndIf;
			DataSourceObject.Write();
		EndDo;
		
		RecordSet = InformationRegisters.DocumentNameCacheForProcessingByRule.CreateRecordSet();
		RecordSet.Write();
		
		ResultTable1 = Query.Execute().Unload();
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.ActualDataQueryRulesByBudgetFlowItems");
		LockItem.DataSource = ResultTable1;
		LockItem.UseFromDataSource("Ref", "Ref");
		Block.Lock();
		
		For Each TableRow In ResultTable1 Do
			
			RuleObject_ = TableRow.Ref.GetObject();
			RuleObject_.Lock();
			If Not ByCorrespondingRegisters Then
				If RuleObject_.RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment
					Or RuleObject_.RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData Then
					RuleObject_.CachingOfRuleResults = False;
				EndIf;
				If Not TableRow.UseInBudgeting Then
					RuleObject_.SetDeletionMark(True);
				EndIf;
			EndIf;
			ReplaceRuleDataSource(RuleObject_, ByCorrespondingRegisters);
			ReplaceRuleAnalyticsFields(RuleObject_, TableRow.Receipt, TableRow.Expense,
				ModifiedDataSources, ByCorrespondingRegisters);
			ReplaceSourcesOfRuleAmount(RuleObject_, TableRow.Receipt, TableRow.Expense,
				ByCorrespondingRegisters);
			ReplaceRuleCoefficient(RuleObject_, TableRow.NameOfTheDataSourceTemplate);
			RuleObject_.Write();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		MessageText = StrTemplate(NStr("vi = 'Không thể thay đổi phương án tùy chỉnh nhận dữ liệu thực tế theo nguyên nhân: %1';
										|ru = 'Не удалось изменить вариант настройки получения фактических данных по причине: %1';
										|en = 'Cannot change the setup option of actual data receipt due to: %1'; fa = 'Cannot change the setup option of actual data receipt due to: %1';
										|it = 'Не удалось изменить вариант настройки получения фактических данных по причине: %1';
										|pl = 'Cannot change the setup option of actual data receipt due to: %1';
										|tr = 'Gerçek veri alımı için ayar seçeneği şu nedenden dolayı değiştirilemedi: %1'"),
		ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(
		NStr("vi = 'Thay đổi phương án tùy chỉnh nhận dữ liệu thực tế.';
			|ru = 'Изменение варианта настройки получения фактических данных.';
			|en = 'Change the setup option of actual data receipt.'; fa = 'Change the setup option of actual data receipt.';
			|it = 'Изменение варианта настройки получения фактических данных.';
			|pl = 'Change the setup option of actual data receipt.';
			|tr = 'Gerçek veri alımı ayarı seçeneğinin değiştirilmesi.'", Common.DefaultLanguageCode()), 
		EventLogLevel.Error, , , MessageText);
		
		Raise MessageText;
		
	EndTry;
	
	PutToTempStorage(Parameters, StorageAddress);
	
EndProcedure

// Returns the parameters of the HO settings that require the details to be adjusted when
// the fact collection option is enabled/disabled based on operational accounting data for corresponding registers.
//
// Parameters:
//  ByCorrespondingRegisters - Boolean - True if the fact collection is established by the balance registers
//  ByLimitRegisters - Undefined, Boolean - True if limit control is set to 2.5
//
// Returns:
//  Map of KeyAndValue:
//   * Key - CatalogRef.BusinessTransactionsSettings
//   * Value - Structure - the structure of the parameters for replacing the details of the HO:
//    ** Key - String - Receipt or Expense
//    ** Value - EnumRef.AccountingDataTypes
//
Function DefineReplacementsForDataTypesAccountingForDataSources(ByCorrespondingRegisters, ByLimitRegisters = Undefined) Export
	
	MatchingDataSources = New Map;
	
	// Receipt - Revenue expenditures on other activespasses
	DataSources = New Array;
	DataSources.Add(Catalogs.BusinessTransactionsSettings.CashIssueAsLoanToEmployee);
	DataSources.Add(Catalogs.BusinessTransactionsSettings.SalaryPaymentByPayrollCardProgram);
	DataSources.Add(Catalogs.BusinessTransactionsSettings.SalaryPaymentToBankAccounts);
	DataSources.Add(Catalogs.BusinessTransactionsSettings.SalaryPaymentToEmployee);
	DataSources.Add(Catalogs.BusinessTransactionsSettings.SalaryPaymentByDistributor);
	DataSources.Add(Catalogs.BusinessTransactionsSettings.SalaryPaymentViaCashAccount);
	DataSources.Add(Catalogs.BusinessTransactionsSettings.TransferOfTaxesAndContributions);
	If ByLimitRegisters = Undefined Then
		DataSources.Add(Catalogs.BusinessTransactionsSettings.TransferForOtherPurposes);
		If ByCorrespondingRegisters Then
			ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.IncomeExpenses,
			Enums.AccountingDataTypes.OtherAssetsLiabilities);
		Else
			ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.OtherAssetsLiabilities,
			Enums.AccountingDataTypes.IncomeExpenses);
		EndIf;
	Else
		If ByLimitRegisters Then
			ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.IncomeExpenses,
			Enums.AccountingDataTypes.OtherAssetsLiabilities);
		Else
			ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.OtherAssetsLiabilities,
			Enums.AccountingDataTypes.IncomeExpenses);
		EndIf;
	EndIf;
		
	For Each DataSource In DataSources Do
		MatchingDataSources.Insert(DataSource, New Structure("Receipt",
			Common.CopyRecursive(ReplacingAccountingDataType)));
	EndDo;
	If ByLimitRegisters <> Undefined Then
		Return MatchingDataSources;
	EndIf;
	
	// Expense - Income Expenditure on other activesarrays
	DataSources = New Array;
	DataSources.Add(Catalogs.BusinessTransactionsSettings.ReturnOfPayrollPaymentByPayrollCardProgram);
	DataSources.Add(Catalogs.BusinessTransactionsSettings.UnremittedSalaryReturnToPersonalAccounts);
	DataSources.Add(Catalogs.BusinessTransactionsSettings.LoanRepaymentByEmployee);
	DataSources.Add(Catalogs.BusinessTransactionsSettings.TaxRefund);
	If ByCorrespondingRegisters Then
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.IncomeExpenses,
			Enums.AccountingDataTypes.OtherAssetsLiabilities);
	Else
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.OtherAssetsLiabilities,
			Enums.AccountingDataTypes.IncomeExpenses);
	EndIf;
	For Each DataSource In DataSources Do
		MatchingDataSources.Insert(DataSource, New Structure("Expense",
			Common.CopyRecursive(ReplacingAccountingDataType)));
	EndDo;
	
	// Expense - Other income-related assets
	DataSources = New Array;
	DataSources.Add(Catalogs.BusinessTransactionsSettings.FixedAssetDepreciationWriteOff);
	DataSources.Add(Catalogs.BusinessTransactionsSettings.IntangibleAssetsInitialRecognition);
	If ByCorrespondingRegisters Then
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.OtherAssetsLiabilities,
			Enums.AccountingDataTypes.IncomeExpenses);
	Else
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.IncomeExpenses,
			Enums.AccountingDataTypes.OtherAssetsLiabilities);
	EndIf;
	For Each DataSource In DataSources Do
		MatchingDataSources.Insert(DataSource, New Structure("Expense",
			Common.CopyRecursive(ReplacingAccountingDataType)));
	EndDo;
	
	// Expense - Income expenditure on Counterparties
	DataSources = New Array;
	DataSources.Add(Catalogs.BusinessTransactionsSettings.RefundFromLessor);
	If ByCorrespondingRegisters Then
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.IncomeExpenses,
			Enums.AccountingDataTypes.Counterparties);
	Else
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Counterparties,
			Enums.AccountingDataTypes.IncomeExpenses);
	EndIf;
	For Each DataSource In DataSources Do
		MatchingDataSources.Insert(DataSource, New Structure("Expense",
			Common.CopyRecursive(ReplacingAccountingDataType)));
	EndDo;
	
	// Receipt - Funds to Counterparties
	DataSources = New Array;
	DataSources.Add(Catalogs.BusinessTransactionsSettings.DepositInterestCharge);
	DataSources.Add(Catalogs.BusinessTransactionsSettings.TransferToDeposits);
	If ByCorrespondingRegisters Then
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Cash,
			Enums.AccountingDataTypes.Counterparties);
	Else
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Counterparties,
			Enums.AccountingDataTypes.Cash);
	EndIf;
	For Each DataSource In DataSources Do
		MatchingDataSources.Insert(DataSource, New Structure("Receipt",
			Common.CopyRecursive(ReplacingAccountingDataType)));
	EndDo;
	
	// Expense - Cash on Counterparties
	DataSources = New Array;
	DataSources.Add(Catalogs.BusinessTransactionsSettings.CashReceiptUnderDeposits);
	If ByCorrespondingRegisters Then
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Cash,
			Enums.AccountingDataTypes.Counterparties);
	Else
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Counterparties,
			Enums.AccountingDataTypes.Cash);
	EndIf;
	For Each DataSource In DataSources Do
		MatchingDataSources.Insert(DataSource, New Structure("Expense",
			Common.CopyRecursive(ReplacingAccountingDataType)));
	EndDo;
		
	// Expense - Counterparties for monetary funds
	DataSources = New Array;
	DataSources.Add(Catalogs.BusinessTransactionsSettings.PurchaseViaAdvanceHolder);
	If ByCorrespondingRegisters Then
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Counterparties,
			Enums.AccountingDataTypes.Cash);
	Else
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Cash,
			Enums.AccountingDataTypes.Counterparties);
	EndIf;
	For Each DataSource In DataSources Do
		MatchingDataSources.Insert(DataSource, New Structure("Expense",
			Common.CopyRecursive(ReplacingAccountingDataType)));
	EndDo;
	
	// Receipt - Counterparties to other assets
	DataSources = New Array;
	DataSources.Add(Catalogs.BusinessTransactionsSettings.TransferCashBetweenCompanyAndItsBranchOffices);
	If ByCorrespondingRegisters Then
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Counterparties,
			Enums.AccountingDataTypes.OtherAssetsLiabilities);
	Else
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.OtherAssetsLiabilities,
			Enums.AccountingDataTypes.Counterparties);
	EndIf;
	For Each DataSource In DataSources Do
		MatchingDataSources.Insert(DataSource, New Structure("Receipt",
			Common.CopyRecursive(ReplacingAccountingDataType)));
	EndDo;
	
	// Receipt - Revenue spent on Items
	DataSources = New Array;
	DataSources.Add(Catalogs.BusinessTransactionsSettings.AccountSalesFromCommissionAgentCommissionFee);
	DataSources.Add(Catalogs.BusinessTransactionsSettings.GoodsLotsMisgrading);
	If ByCorrespondingRegisters Then
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.IncomeExpenses,
			Enums.AccountingDataTypes.Products);
	Else
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Products,
			Enums.AccountingDataTypes.IncomeExpenses);
	EndIf;
	For Each DataSource In DataSources Do
		MatchingDataSources.Insert(DataSource, New Structure("Receipt",
			Common.CopyRecursive(ReplacingAccountingDataType)));
	EndDo;
	
	// Expense - Item for other active items
	DataSources = New Array;
	DataSources.Add(Catalogs.BusinessTransactionsSettings.InternalGoodsReceipt);
	If ByCorrespondingRegisters Then
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Products,
			Enums.AccountingDataTypes.OtherAssetsLiabilities);
	Else
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.OtherAssetsLiabilities,
			Enums.AccountingDataTypes.Products);
	EndIf;
	For Each DataSource In DataSources Do
		MatchingDataSources.Insert(DataSource, New Structure("Expense",
			Common.CopyRecursive(ReplacingAccountingDataType)));
	EndDo;
	
	// Receipt - Item for other active items
	DataSources = New Array;
	DataSources.Add(Catalogs.BusinessTransactionsSettings.TransferOfGoodsBetweenBranchOffices);
	If ByCorrespondingRegisters Then
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Products,
			Enums.AccountingDataTypes.OtherAssetsLiabilities);
	Else
		ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.OtherAssetsLiabilities,
			Enums.AccountingDataTypes.Products);
	EndIf;
	For Each DataSource In DataSources Do
		MatchingDataSources.Insert(DataSource, New Structure("Receipt",
			Common.CopyRecursive(ReplacingAccountingDataType)));
	EndDo;
	
	// Receipt and Expense swap
	DataSource = Catalogs.BusinessTransactionsSettings.TransferToIntangibleAssetsAndRD;
	ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Products,
		Enums.AccountingDataTypes.IncomeExpenses);
	MatchingDataSources.Insert(DataSource, New Structure("Receipt", ReplacingAccountingDataType));
	ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.IncomeExpenses,
		Enums.AccountingDataTypes.Products);
	MatchingDataSources[DataSource].Insert("Expense", ReplacingAccountingDataType);

	DataSource = Catalogs.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods;
	ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Products,
		Enums.AccountingDataTypes.Counterparties);
	MatchingDataSources.Insert(DataSource, New Structure("Receipt", ReplacingAccountingDataType));
	ReplacingAccountingDataType = New Structure("Original, New", Enums.AccountingDataTypes.Counterparties,
		Enums.AccountingDataTypes.Products);
	MatchingDataSources[DataSource].Insert("Expense", ReplacingAccountingDataType);
	
	Return MatchingDataSources;
	
EndFunction

Procedure ReplaceRuleDataSource(Rule, ByCorrespondingRegisters)
	
	DataSource = Rule.DataSource;
	
	If ByCorrespondingRegisters Then
		
		If DataSource = Catalogs.BusinessTransactionsSettings.FixedAssetSale
			Or DataSource = Catalogs.BusinessTransactionsSettings.SaleOfIntangibleAssetsAndRD Then
			Rule.DataSource = Catalogs.BusinessTransactionsSettings.NonCurrentAssetsSale;
			Settings = Rule.SettingsComposer.Get();
			If TypeOf(Settings) = Type("DataCompositionSettings") Then
				If DataSource = Catalogs.BusinessTransactionsSettings.FixedAssetSale Then
					FilterField = "IncomeAndExpenseItem.IncomeByAssets";
				Else
					FilterField = "IncomeAndExpenseItem.IntangibleAssetsAndRDIncome";
				EndIf;
				DataCompositionClientServer.AddFilter(Settings, FilterField, True, DataCompositionComparisonType.Equal, True);
				Rule.SettingsComposer = New ValueStorage(Settings);
				Rule.FilterPresentation = String(Settings.Filter);
			EndIf;
		ElsIf DataSource = Catalogs.BusinessTransactionsSettings.IncomeFromGoodsRevaluation Then
			Rule.DataSource = Catalogs.BusinessTransactionsSettings.GoodsValueVarianceIncome;
		ElsIf DataSource = Catalogs.BusinessTransactionsSettings.ExpensesFromGoodsRevaluation Then
			Rule.DataSource = Catalogs.BusinessTransactionsSettings.GoodsValueVarianceExpenses;
		ElsIf DataSource = Catalogs.BusinessTransactionsSettings.GoodsMisgradingWithRevaluation Then
			Rule.DataSource = Catalogs.BusinessTransactionsSettings.GoodsMisgrading;
		ElsIf DataSource = Catalogs.BusinessTransactionsSettings.ReportToMaterialProvider2_5
			And Rule.TransactionAmountSource <> Enums.IndicatorsOfAnalyticalRegisters.Sum
			And Rule.TransactionAmountSource <> Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT
			And Rule.TransactionAmountSource <> Enums.IndicatorsOfAnalyticalRegisters.VATAmount
			And Rule.TransactionAmountSource <> Enums.IndicatorsOfAnalyticalRegisters.AmountSalesExpenses
			And Rule.TransactionAmountSource <> Enums.IndicatorsOfAnalyticalRegisters.TAmountSalesExpensesWithoutVAT Then
			Rule.DataSource = Catalogs.BusinessTransactionsSettings.TransferToMaterialProvider2_5;
		EndIf;
		
	Else
		
		If DataSource = Catalogs.BusinessTransactionsSettings.NonCurrentAssetsSale Then
			Settings = Rule.SettingsComposer.Get();
			If TypeOf(Settings) = Type("DataCompositionSettings") Then
				FilterItems1 = DataCompositionClientServer.GetSelectionElements(Settings.Filter);
				For Each FilterElement In FilterItems1 Do
					FilterField = TrimAll(FilterElement.LeftValue);
					If FilterField = "IncomeAndExpenseItem.IntangibleAssetsAndRDIncome" Then
						Rule.DataSource = Catalogs.BusinessTransactionsSettings.SaleOfIntangibleAssetsAndRD;
						Break;
					EndIf;
				EndDo;
				If Rule.DataSource <> Catalogs.BusinessTransactionsSettings.SaleOfIntangibleAssetsAndRD Then
					Rule.DataSource = Catalogs.BusinessTransactionsSettings.FixedAssetSale;
				EndIf;
			Else
				Rule.DataSource = Catalogs.BusinessTransactionsSettings.FixedAssetSale;
			EndIf;
		ElsIf DataSource = Catalogs.BusinessTransactionsSettings.GoodsValueVarianceIncome Then
			Rule.DataSource = Catalogs.BusinessTransactionsSettings.IncomeFromGoodsRevaluation;
		ElsIf DataSource = Catalogs.BusinessTransactionsSettings.GoodsValueVarianceExpenses Then
			Rule.DataSource = Catalogs.BusinessTransactionsSettings.ExpensesFromGoodsRevaluation;
		ElsIf DataSource = Catalogs.BusinessTransactionsSettings.GoodsMisgrading Then
			Rule.DataSource = Catalogs.BusinessTransactionsSettings.GoodsMisgradingWithRevaluation;
		ElsIf DataSource = Catalogs.BusinessTransactionsSettings.TransferToMaterialProvider2_5 Then
			Rule.DataSource = Catalogs.BusinessTransactionsSettings.ReportToMaterialProvider2_5;
		ElsIf DataSource = Catalogs.BusinessTransactionsSettings.DepositInterestCharge
			Or DataSource = Catalogs.BusinessTransactionsSettings.DepositInterestCharge
			Or DataSource = Catalogs.BusinessTransactionsSettings.TransferToDeposits Then
			Settings = Rule.SettingsComposer.Get();
			If TypeOf(Settings) = Type("DataCompositionSettings") Then
				DataCompositionClientServer.AddFilter(Settings, "CorCashType", Enums.CashTypes.Deposits, DataCompositionComparisonType.Equal, True);
				Rule.SettingsComposer = New ValueStorage(Settings);
				Rule.FilterPresentation = String(Settings.Filter);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ReplaceRuleAnalyticsFields(Rule, Receipt, Expense, ModifiedDataSources, ByCorrespondingRegisters)
	
	ModifiedDataSource = ModifiedDataSources.Get(Rule.DataSource);
	If ModifiedDataSource <> Undefined And Not ModifiedDataSource.Property("UseInBudgeting") Then
		If ModifiedDataSource.Property("Receipt")
			And Not ModifiedDataSource.Property("Expense") Then
			If ByCorrespondingRegisters Then
				MatchingNamesReceipt = MatchingNamesOfAnalyticsFields(Receipt, ModifiedDataSource.Receipt.Original,
				"Receipt", Undefined, True);
			Else
				MatchingNamesReceipt = MatchingNamesOfAnalyticsFields(ModifiedDataSource.Receipt.Original, Receipt,
				"Receipt", Undefined, False);
			EndIf;
			MatchingNamesExpense = MatchingNamesOfAnalyticsFields(Expense, Expense, "Expense", Undefined,
				ByCorrespondingRegisters);
		ElsIf ModifiedDataSource.Property("Expense") And Not ModifiedDataSource.Property("Receipt") Then
			MatchingNamesReceipt = MatchingNamesOfAnalyticsFields(Receipt, Receipt, "Receipt", Undefined,
				ByCorrespondingRegisters);
			If ByCorrespondingRegisters Then
				MatchingNamesExpense = MatchingNamesOfAnalyticsFields(Expense, ModifiedDataSource.Expense.Original,
					"Expense", Undefined, True);
			Else
				MatchingNamesExpense = MatchingNamesOfAnalyticsFields(ModifiedDataSource.Expense.Original, Expense,
					"Expense", Undefined, False);
			EndIf;
		Else
			MatchingNamesReceipt = MatchingNamesOfAnalyticsFields(Receipt, Receipt, "Receipt", Expense,
				ByCorrespondingRegisters);
			MatchingNamesExpense = MatchingNamesOfAnalyticsFields(Expense, Expense, "Expense", Receipt,
				ByCorrespondingRegisters);
		EndIf;
	Else
		MatchingNamesReceipt = MatchingNamesOfAnalyticsFields(Receipt, Receipt, "Receipt", Expense, ByCorrespondingRegisters);
		MatchingNamesExpense = MatchingNamesOfAnalyticsFields(Expense, Expense, "Expense", Receipt, ByCorrespondingRegisters);
	EndIf;
	
	For Counter = 1 To 6 Do
		For AdditionalTag = 1 To 2 Do
			If AdditionalTag = 1 Then
				DimensionPopulationExpression = Rule["DimensionPopulationExpression"+Counter];
			Else
				DimensionPopulationExpression = Rule["DimensionPopulationExpression"+Counter+"HistoryOfTransitionToNewFormulas"];
			EndIf;
			If ValueIsFilled(DimensionPopulationExpression) Then
				SeparatorPosition = StrFind(DimensionPopulationExpression, ".");
				If SeparatorPosition = 0 Then
					ReplacementExpression = DimensionPopulationExpression;
				Else
					ReplacementExpression = Left(DimensionPopulationExpression, SeparatorPosition-1);
				EndIf;
				ReplacementName = MatchingNamesReceipt.Get(ReplacementExpression);
				If ReplacementName = Undefined Then
					ReplacementName = MatchingNamesExpense.Get(ReplacementExpression);
				EndIf;
				If ReplacementName <> Undefined Then
					If SeparatorPosition > 0 Then
						ReplacementName = ReplacementName + Mid(DimensionPopulationExpression, SeparatorPosition);
					EndIf;
					If AdditionalTag = 1 Then
						Rule["DimensionPopulationExpression"+Counter] = ReplacementName;
					Else
						Rule["DimensionPopulationExpression"+Counter+"HistoryOfTransitionToNewFormulas"] = ReplacementName;
					EndIf;
				ElsIf AdditionalTag = 2 Then
					Rule["DimensionPopulationExpression"+Counter+"HistoryOfTransitionToNewFormulas"] = "";
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	Settings = Rule.SettingsComposer.Get();
	FilterChanged = False;
	If TypeOf(Settings) = Type("DataCompositionSettings") Then
		FilterItems1 = DataCompositionClientServer.GetSelectionElements(Settings.Filter, False);
		For Counter = 1 To FilterItems1.Count() Do
			FilterElement = FilterItems1[Counter-1]; // DataCompositionFilterItem -
			FilterFieldName = TrimAll(FilterElement.LeftValue);
			SeparatorPosition = StrFind(FilterFieldName, ".");
			If SeparatorPosition = 0 Then
				ReplacementExpression = FilterFieldName;
			Else
				ReplacementExpression = Left(FilterFieldName, SeparatorPosition-1);
			EndIf;
			ReplacementName = MatchingNamesReceipt.Get(ReplacementExpression);
			If ReplacementName = Undefined Then
				ReplacementName = MatchingNamesExpense.Get(ReplacementExpression);
			EndIf;
			If ReplacementName <> Undefined Then
				If IsBlankString(ReplacementName) Then
					If FilterElement.Parent = Undefined Then
						Settings.Filter.Items.Delete(FilterElement);
					Else
						FilterElement.Parent.Items.Delete(FilterElement);
					EndIf;
				Else
					If SeparatorPosition > 0 Then
						ReplacementName = ReplacementName + Mid(DimensionPopulationExpression, SeparatorPosition);
					EndIf;
					FilterElement.LeftValue = New DataCompositionField(ReplacementName);
				EndIf;
				FilterChanged = True;
			EndIf;
		EndDo;
	EndIf;
	If FilterChanged Then
		Rule.SettingsComposer = New ValueStorage(Settings);
		Rule.FilterPresentation = String(Settings.Filter);
	EndIf;
	
EndProcedure

Procedure ReplaceSourcesOfRuleAmount(Rule, Receipt, Expense, ByCorrespondingRegisters)
	
	If Receipt = Enums.AccountingDataTypes.Products
		And Expense <> Enums.AccountingDataTypes.Counterparties
		Or Expense = Enums.AccountingDataTypes.Products
		And Receipt <> Enums.AccountingDataTypes.Counterparties Then
		If ByCorrespondingRegisters Then
			If Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum Then
				Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Cost_;
			ElsIf Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT Then
				Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Cost_;
			ElsIf Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.VATAmount Then
				Rule.SetDeletionMark(True);
			ElsIf Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.SumCompl Then
				Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.CostLocal;
			EndIf;
		Else
			If Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Cost_ Then
				Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum;
			ElsIf Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.CostLocal Then
				Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.SumCompl;
			EndIf;
		EndIf;
	ElsIf Receipt = Enums.AccountingDataTypes.Products
		And Expense = Enums.AccountingDataTypes.Counterparties Then
		If ByCorrespondingRegisters Then
			If Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Cost Then
				Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum;
			ElsIf Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.CostExcludingVAT
				Or Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.LocalCost Then
				Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT;
			EndIf;
		Else
			If Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Cost_
				Or Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.CostLocal Then
				Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum;
			EndIf;
		EndIf;
	Else
		If Receipt = Enums.AccountingDataTypes.Counterparties
			And Expense = Enums.AccountingDataTypes.Cash
			Or Receipt = Enums.AccountingDataTypes.Cash
			And Expense = Enums.AccountingDataTypes.Counterparties Then
			If Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum Then
				Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.PayAmount;
			EndIf;
		Else
			If Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.PayAmount
				Or Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan
				Or Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.PostpaymentAmount Then
				Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum;
			EndIf;
		EndIf;
	EndIf;
	
	If Receipt = Enums.AccountingDataTypes.Cash
		Or Expense = Enums.AccountingDataTypes.Cash Then
		If Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.VATAmount Then
			Rule.SetDeletionMark(True);
		ElsIf Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT Then
			Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum;
		EndIf;
	EndIf;
	
	If Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.AmountSalesExpenses Then
		Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum;
	ElsIf Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.TAmountSalesExpensesWithoutVAT Then
		Rule.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT;
	EndIf;

EndProcedure

Procedure ReplaceRuleCoefficient(Rule, NameOfTheDataSourceTemplate)
	
	If NameOfTheDataSourceTemplate = "FixedAssetsDepreciationCharge" Or NameOfTheDataSourceTemplate = "IntangibleAssetsAmortizationCharge" Then
		Rule.ZoomRatio = -Rule.ZoomRatio;
	EndIf;
	
EndProcedure

Procedure ChangeWhetherDataSourcesAreUsedInBudgeting(ModifiedDataSources, ByCorrespondingRegisters) Export
	
	DataSourceParameters = New Structure("UseInBudgeting, Receipt, Expense");
	DataSourceParameters.UseInBudgeting = ByCorrespondingRegisters;

	// NonCurrentAssetsSale
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.Counterparties;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.IncomeExpenses;
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.NonCurrentAssetsSale,
		Common.CopyRecursive(DataSourceParameters));
	
	// IncomingVATOnAcquisition
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.VAT;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.Counterparties;
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.IncomingVATOnAcquisition,
		Common.CopyRecursive(DataSourceParameters));
	
	// PaymentForLeaseServices
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.Counterparties;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.Cash;
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.PaymentForLeaseServices,
		Common.CopyRecursive(DataSourceParameters));
	
	// SecurityPayment
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.SecurityPayment,
		Common.CopyRecursive(DataSourceParameters));
	
	// LeaseBuyoutValuePayment
	ModifiedDataSources.Insert(
		Catalogs.BusinessTransactionsSettings.LeaseBuyoutValuePayment,
		Common.CopyRecursive(DataSourceParameters));
	
	// LeaseBuyoutValuePrepayment
	ModifiedDataSources.Insert(
		Catalogs.BusinessTransactionsSettings.LeaseBuyoutValuePrepayment,
		Common.CopyRecursive(DataSourceParameters));
	
	// SecurityPaymentReturn
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.Cash;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.Counterparties;
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.SecurityPaymentReturn,
		Common.CopyRecursive(DataSourceParameters));
	
	// RefundLeaseBuyoutValue
	ModifiedDataSources.Insert(
		Catalogs.BusinessTransactionsSettings.RefundLeaseBuyoutValue,
		Common.CopyRecursive(DataSourceParameters));
	
	// RefundPrepaymentLeaseBuyoutValue
	ModifiedDataSources.Insert(
		Catalogs.BusinessTransactionsSettings.RefundPrepaymentLeaseBuyoutValue,
		Common.CopyRecursive(DataSourceParameters));
	
	// DisposeFixedAssets
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.OtherAssetsLiabilities;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.IncomeExpenses;
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.DisposeFixedAssets,
		Common.CopyRecursive(DataSourceParameters));
	
	// AccrualOfLeaseInterest
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.IncomeExpenses;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.Counterparties;
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.AccrualOfLeaseInterest,
		Common.CopyRecursive(DataSourceParameters));
	
	// GenerationOfLeasedFixedAssetsCost
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.GenerationOfLeasedFixedAssetsCost,
		Common.CopyRecursive(DataSourceParameters));
	
	// RecordingLeaseServicesInExpenses
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.RecordingLeaseServicesInExpenses,
		Common.CopyRecursive(DataSourceParameters));
	
	// TransferToMaterialProvider
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.Products;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.Products;
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.TransferToMaterialProvider2_5,
		Common.CopyRecursive(DataSourceParameters));
	
	// VATIsAccruedByTaxAgent
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.VAT;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.VAT;
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.VATIsAccruedByTaxAgent,
		Common.CopyRecursive(DataSourceParameters));
	
	// AccrualVATFromSalesOfGoodsInTransit
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.OtherAssetsLiabilities;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.VAT;
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.AccrualVATFromSalesOfGoodsInTransit,
		Common.CopyRecursive(DataSourceParameters));
	
	// PersonalIncomeTaxRecord
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.OtherAssetsLiabilities;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.OtherAssetsLiabilities;
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.PersonalIncomeTaxRecord,
		Common.CopyRecursive(DataSourceParameters));
	
	// ExpenseAllocationOnCostOfGoodsSold
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.Products;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.IncomeExpenses;
	ModifiedDataSources.Insert(
		Catalogs.BusinessTransactionsSettings.ExpenseAllocationOnCostOfGoodsSold,
		Common.CopyRecursive(DataSourceParameters));
	
	// FutureExpenseCommitmentsWriteOff
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.OtherAssetsLiabilities;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.OtherAssetsLiabilities;
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.FutureExpenseCommitmentsWriteOff,
		Common.CopyRecursive(DataSourceParameters));
	
	// DebitNoteForPreviousPeriod
	DataSourceParameters.Receipt = Enums.AccountingDataTypes.Products;
	DataSourceParameters.Expense = Enums.AccountingDataTypes.Products;
	ModifiedDataSources.Insert(Catalogs.BusinessTransactionsSettings.DebitNoteForPreviousPeriod,
		Common.CopyRecursive(DataSourceParameters));
	
EndProcedure

Function MatchingNamesOfAnalyticsFields(TypeOfAccountingData, SourceAccountingDataType, Direction, CorTypeOfAccountingData, ByCorrespondingRegisters)
	
	MatchingNames = New Map;
	
	If TypeOfAccountingData = SourceAccountingDataType
		Or TypeOfAccountingData = Enums.AccountingDataTypes.IncomeExpenses
		And SourceAccountingDataType = Enums.AccountingDataTypes.OtherAssetsLiabilities
		Or TypeOfAccountingData = Enums.AccountingDataTypes.OtherAssetsLiabilities
		And SourceAccountingDataType = Enums.AccountingDataTypes.IncomeExpenses Then
		If TypeOfAccountingData = Enums.AccountingDataTypes.IncomeExpenses Then
			If CorTypeOfAccountingData = Enums.AccountingDataTypes.IncomeExpenses
				Or CorTypeOfAccountingData = Enums.AccountingDataTypes.OtherAssetsLiabilities Then
				MatchingNames.Insert(?(Direction = "Receipt", "DebitBusinessUnit", "Department"), "IncomeExpenseBusinessUnit");
				MatchingNames.Insert(?(Direction = "Receipt", "CorLineOfBusiness", "LineOfBusiness"), "LineOfBusinessOfIncomeExpenses");
				MatchingNames.Insert(?(Direction = "Receipt", "CorItem", "AssetRef"), "IncomeAndExpenseItem");
			Else
				MatchingNames.Insert("LineOfBusinessItems", "LineOfBusinessOfIncomeExpenses");
				MatchingNames.Insert("AssetAndLiabilityItem", "IncomeAndExpenseItem");
				MatchingNames.Insert("AssetsLiabilitiesDimension", ?(Direction = "Receipt", "DimensionOfExpenses", "DimensionOfRevenue"));
			EndIf;
			If Direction = "Receipt" Then
				MatchingNames.Insert("CorCounterparty", "Counterparty");
			EndIf;
		ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.OtherAssetsLiabilities Then
			If CorTypeOfAccountingData = Enums.AccountingDataTypes.IncomeExpenses
				Or CorTypeOfAccountingData = Enums.AccountingDataTypes.OtherAssetsLiabilities Then
				MatchingNames.Insert(?(Direction = "Receipt", "DebitBusinessUnit", "Department"), "DivisionOfAssetsLiabilities");
				MatchingNames.Insert(?(Direction = "Receipt", "CorLineOfBusiness", "LineOfBusiness"), "LineOfBusinessOfAssetsLiabilities");
				MatchingNames.Insert(?(Direction = "Receipt", "CorItem", "AssetRef"), "AssetAndLiabilityItem");
			Else
				MatchingNames.Insert("LineOfBusinessItems", "LineOfBusinessOfAssetsLiabilities");
				MatchingNames.Insert("IncomeAndExpenseItem", "AssetAndLiabilityItem");
				MatchingNames.Insert("DimensionOfExpenses", "AssetsLiabilitiesDimension");
				MatchingNames.Insert("DimensionOfRevenue", "AssetsLiabilitiesDimension");
			EndIf;
			If Direction = "Receipt" Then
				MatchingNames.Insert("CorCounterparty", "Counterparty");
			EndIf;
		ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.Counterparties Then
			MatchingNames.Insert("SalesOrder", "ARAPObject");
		EndIf;
	EndIf;
	
	If TypeOfAccountingData = Enums.AccountingDataTypes.Counterparties
		And SourceAccountingDataType = Enums.AccountingDataTypes.Cash Then
		MatchingNames.Insert("Cash", "Contract");
		MatchingNames.Insert("PaymentCurrency", "Currency");
	ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.Counterparties
		And SourceAccountingDataType = Enums.AccountingDataTypes.IncomeExpenses Then
		MatchingNames.Insert("AssetsLiabilitiesDimension", "Contract");
	ElsIf TypeOfAccountingData = Enums.AccountingDataTypes.Products
		And TypeOfAccountingData = SourceAccountingDataType Then
		MatchingNames.Insert("ItemsType", "Products.ItemsType");
		MatchingNames.Insert("ProductKind", "Products.ProductKind");
		MatchingNames.Insert("UnitOfMeasure", "Products.UnitOfMeasure");
		MatchingNames.Insert("Brand", "Products.Brand");
		MatchingNames.Insert("Manufacturer", "Products.Manufacturer");
		MatchingNames.Insert("ItemsGroup", "Products.ItemsGroup");
		MatchingNames.Insert("PriceGroup", "Products.PriceGroup");
		MatchingNames.Insert("ProductCategory", "Products.ProductCategory");
		MatchingNames.Insert("InventoryType", "InventoryOwnerAttribute.InventoryType");
	EndIf;
	
	If Not ByCorrespondingRegisters And MatchingNames.Count() > 0 Then
		NameMatchingIsReversed = Common.CopyRecursive(MatchingNames);
		MatchingNames.Clear();
		For Each KeyAndValue In NameMatchingIsReversed Do
			MatchingNames.Insert(KeyAndValue.Value, KeyAndValue.Key);
		EndDo;
	EndIf;
	
	Return MatchingNames;
	
EndFunction

// Checks whether there are rules in the database for obtaining actual data without a stored fact according to the operational accounting data,
// which is an obstacle to including the collection of a fact according to corresponding registers.
//
// Returns:
//  Boolean - True if the fact storage is enabled by all rules
//
Function ByAllRulesStoredFactIsUsed() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	ActualDataQueryRulesByBudgetFlowItems.Ref AS Ref
	|FROM
	|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|WHERE
	|	ActualDataQueryRulesByBudgetFlowItems.DataSourceSection = VALUE(Enum.SectionsOfBudgetingDataSources.OperationalAccounting)
	|	AND NOT ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults";
	If LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed() Then
		Query.Text = Query.Text + "
		|	AND ActualDataQueryRulesByBudgetFlowItems.RuleType = VALUE(Enum.ActualBudgetingDataQueryRuleType.ActualData)";
	EndIf;
	
	Return Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region SettingUpLimitControlBasedOnBudgetingData2_5

Procedure ProcessRulesForGettingFact_BudgetExecution(ByRegisterOfLimits) Export
	
	ByCorrespondingRegisters = GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters");
	
	If Not ByCorrespondingRegisters Then
		ModifiedDataSources = DefineReplacementsForDataTypesAccountingForDataSources(False, ByRegisterOfLimits);
		For Each DataSource In ModifiedDataSources Do
			DataSourceObject = DataSource.Key.GetObject();
			DataSourceObject.Lock();
			DataSourceParameters = DataSource.Value;
			If DataSourceParameters.Property("Receipt") Then
				DataSourceObject.Receipt = ?(TypeOf(DataSourceParameters.Receipt) = Type("Structure"), DataSourceParameters.Receipt.New, DataSourceParameters.Receipt);
			EndIf;
			If DataSourceParameters.Property("Expense") Then
				DataSourceObject.Expense = ?(TypeOf(DataSourceParameters.Expense) = Type("Structure"), DataSourceParameters.Expense.New, DataSourceParameters.Expense);
			EndIf;
			DataSourceObject.Write();
		EndDo;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ActualDataQueryRulesByBudgetFlowItems.Ref AS Ref,
	|	CAST(ActualDataQueryRulesByBudgetFlowItems.DataSource AS Catalog.BusinessTransactionsSettings).Receipt AS Receipt,
	|	CAST(ActualDataQueryRulesByBudgetFlowItems.DataSource AS Catalog.BusinessTransactionsSettings).Expense AS Expense
	|FROM
	|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|WHERE
	|	NOT ActualDataQueryRulesByBudgetFlowItems.DeletionMark
	|	AND ActualDataQueryRulesByBudgetFlowItems.RuleType IN (VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillment), VALUE(Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData))";
	
	ResultTable1 = Query.Execute().Unload();
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.ActualDataQueryRulesByBudgetFlowItems");
	LockItem.DataSource = ResultTable1;
	LockItem.UseFromDataSource("Ref", "Ref");
	Block.Lock();
	
	AmountIndicators_ = DataSourcesCached.RegisteredRecordsOfCashDisbursements();
	
	For Each TableRow In ResultTable1 Do
		
		RuleObject_ = TableRow.Ref.GetObject();
		RuleObject_.Lock();
		
		CopyRule = False;
		
		If ByRegisterOfLimits Then
			If RuleObject_.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
				And AmountIndicators_.Get(RuleObject_.TransactionAmountSource) <> Undefined Then
				RuleObject_.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaid;
				If RuleObject_.RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData Then
					CopyRule = Not ByCorrespondingRegisters;
					RuleObject_.RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment;
				EndIf;
				RuleObject_.CachingOfRuleResults = False;
			Else
				If RuleObject_.RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData Then
					RuleObject_.RuleType = Enums.ActualBudgetingDataQueryRuleType.ActualData;
					RuleObject_.CachingOfRuleResults = False;
				Else
					RuleObject_.SetDeletionMark(True);
				EndIf;
			EndIf;
		ElsIf ByCorrespondingRegisters Then
			RuleObject_.CachingOfRuleResults = True;
		EndIf;
		If Not ByCorrespondingRegisters Then
			ReplaceRuleDataSource(RuleObject_, ByRegisterOfLimits);
			ReplaceRuleAnalyticsFields(RuleObject_, TableRow.Receipt, TableRow.Expense,
			ModifiedDataSources, ByRegisterOfLimits);
		EndIf;
		If CopyRule Then
			NewObjectRule = TableRow.Ref.Copy(); //CatalogObject -
			NewObjectRule.RuleType = Enums.ActualBudgetingDataQueryRuleType.ActualData;
			NewObjectRule.Write();
		EndIf;
		RuleObject_.Write();
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion 

#EndIf
