#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
// 	Array of String - names of blocked Bank details:
//		* AttributeToLock - String - Name of the blocked account.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		Result.Add("DimensionKind" + DimensionNumber);
	EndDo;
	Result.Add("RecordByQuantity");
	Result.Add("RecordByCurrency");
	Result.Add("IndicatorType");
	
	Return Result;
	
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
	|	IsFolder OR
	|	ValueAllowed(Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Internal

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	Reports.TrialBalanceForBudgetBalanceItems.AddReportCommand(ReportsCommands);
	If Parameters.IsObjectForm Then
		Reports.ResultOfActualDataQuery.AddBudgetIndicatorReportCommand(ReportsCommands);
	Else
		Reports.ResultOfActualDataQuery.AddBudgetMetricsReportCommand(
			ReportsCommands);
	EndIf;
EndProcedure

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.BudgetBalanceItems.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.5";
	Handler.ExecutionMode = "Deferred";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Id = New UUID("a30b5516-bfa7-4eb8-a4c5-a595ad8ef62b");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.BudgetBalanceItems.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Điền danh mục ""Quy tắc tính toán số dư và phát sinh liên quan của ngân sách""';
								|ru = 'Заполнение справочника ""Правила расчета связанных остатков и оборотов бюджетов""';
								|en = 'Fill in the ""Rules for calculating related budget balances and turnovers"" catalog'; fa = 'Fill in the ""Rules for calculating related budget balances and turnovers"" catalog';
								|it = 'Fill in the ""Rules for calculating related budget balances and turnovers"" catalog';
								|pl = 'Fill in the ""Rules for calculating related budget balances and turnovers"" catalog';
								|tr = '""İlgili bütçe bakiyelerinin ve cirolarının hesaplanma kuralları"" kataloğunun güncellenmesi'"));
	ListOfDescriptions.Add(NStr("vi = 'theo chỉ tiêu ngân sách từ chứng từ Kế hoạch số dư.';
								|ru = 'по показателям бюджетов из документов Планы остатков.';
								|en = 'by budget balance items from the goods stock plan documents.'; fa = 'by budget balance items from the goods stock plan documents.';
								|it = 'by budget balance items from the goods stock plan documents.';
								|pl = 'by budget balance items from the goods stock plan documents.';
								|tr = 'Mal Stok Planları belgelerindeki bütçe kalemleri kapsamında.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.BudgetBalanceItems.FullName());
	ItemsToRead.Add(Metadata.Catalogs.PlanProfiles.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	ToLock = New Array;
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.BudgetBalanceItems.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	New_Items = New Array;
	New_Items.Add(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.FullName());
	Handler.NewObjects = StrConcat(New_Items, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	SelectionParameters.OrderingFieldsOnUserOperations.Add("BudgetFlowItem DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("BudgetFlowItem DESC");

	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	PlanProfiles.DeleteBudgetFlowItem AS BudgetFlowItem
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	NOT PlanProfiles.DeleteBudgetFlowItem IN (UNDEFINED, VALUE(Catalog.BudgetBalanceItems.EmptyRef))
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PlanOfGoodsStock)
	|	AND NOT PlanProfiles.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|				WHERE
	|					PlanProfiles.DeleteBudgetFlowItem = CalculationsRules.Receiver
	|					AND CalculationsRules.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.PlansOfGoodsStock))";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("BudgetFlowItem"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	Query = New Query;
	Query.SetParameter("BudgetFlowItems", UpdatedData.UnloadColumn("Ref"));
	Query.Text = 
	"SELECT
	|	PlanProfiles.Ref AS PlanProfile,
	|	PlanProfiles.DeleteBudgetFlowItem AS BudgetFlowItem,
	|	VALUE(Enum.DataSourceTypesForBudgeting.PlansOfGoodsStock) AS SourceType,
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.EmptyRef) AS AmountSource,
	|	1 AS NumberOfArticles
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeleteBudgetFlowItem IN (&BudgetFlowItems)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PlanOfGoodsStock)
	|	AND NOT PlanProfiles.DeletionMark";
	ResultTable1 = Query.Execute().Unload();
	RulesOnBudgetItems = ResultTable1.Copy(, "BudgetFlowItem,SourceType,AmountSource,NumberOfArticles");
	RulesOnBudgetItems.GroupBy("BudgetFlowItem,SourceType,AmountSource,NumberOfArticles");
	
	NumberOfArticlesBySourceType = RulesOnBudgetItems.Copy(, "SourceType,AmountSource,NumberOfArticles");
	NumberOfArticlesBySourceType.GroupBy("SourceType,AmountSource", "NumberOfArticles");
	
	TheStructureOfTheSearch = New Structure;
	StructureOfSearchForTypesOfPlans = New Structure("SourceType,BudgetFlowItem");
	StructureOfSearchForNumberOfArticles = New Structure("SourceType,AmountSource");
	
	For Each TheseBudgetItems In UpdatedData Do
		
		TheStructureOfTheSearch.Insert("BudgetFlowItem", TheseBudgetItems.Ref);
		
		RulesForBudgetItem = RulesOnBudgetItems.FindRows(TheStructureOfTheSearch);
		
		BeginTransaction();
		
		Try
		
			For Each StringRule In RulesForBudgetItem Do
				FillPropertyValues(StructureOfSearchForNumberOfArticles, StringRule);
				NumberOfArticles = NumberOfArticlesBySourceType.FindRows(StructureOfSearchForNumberOfArticles)[0].NumberOfArticles;
				PlanProfiles = New Array;
				If NumberOfArticles > 1 Then
					FillPropertyValues(StructureOfSearchForTypesOfPlans, StringRule);
					PlanProfiles = ResultTable1.Copy(StructureOfSearchForTypesOfPlans, "PlanProfile").UnloadColumn("PlanProfile");
				EndIf;
				Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.CreateCalculationRuleBasedOnSourceType(
					StringRule.SourceType, StringRule.BudgetFlowItem, StringRule.AmountSource, PlanProfiles);
			EndDo;
			
			InfobaseUpdate.MarkProcessingCompletion(TheseBudgetItems.Ref);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), TheseBudgetItems.Ref);
			InfobaseUpdate.MarkProcessingCompletion(TheseBudgetItems.Ref);
			InfobaseUpdate.FileIssueWithData(TheseBudgetItems.Ref,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndIf
