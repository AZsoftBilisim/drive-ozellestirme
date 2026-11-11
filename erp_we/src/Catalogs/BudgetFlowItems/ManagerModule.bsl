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
	Result.Add("LimitedTransaction");
	
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

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	Var ParameterValue;
	
	If Parameters.Property("BudgetProfile", ParameterValue) Then
		
		StandardProcessing = False;
		
		Query = New Query;
		Query.Text = 
		"SELECT DISTINCT
		|	AddAttributes.Value AS BudgetFlowItem,
		|	AddAttributes.Value.Description AS TextPresentation,
		|	AddAttributes.Value.DeletionMark AS DeletionMark
		|FROM
		|	Catalog.FinancialReportItems AS ElementsOfBudgetTypes
		|		INNER JOIN Catalog.FinancialReportItems.ItemKindAttributes AS AddAttributes
		|		ON ElementsOfBudgetTypes.Ref = AddAttributes.Ref
		|			AND (AddAttributes.Attribute = VALUE(ChartOfCharacteristicTypes.ItemAttributesOfFinancialReports.BudgetFlowItem))
		|WHERE
		|	ElementsOfBudgetTypes.Owner = &BudgetProfile
		|	AND NOT ElementsOfBudgetTypes.DeletionMark";
		
		Query.SetParameter("BudgetProfile", ParameterValue);
		
	ElsIf Parameters.Property("ThereIsAnalytics", ParameterValue) Then
		
		StandardProcessing = False;
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	BudgetFlowItems.Ref AS BudgetFlowItem,
		|	BudgetFlowItems.Presentation  AS TextPresentation,
		|	BudgetFlowItems.DeletionMark AS DeletionMark
		|FROM
		|	Catalog.BudgetFlowItems AS BudgetFlowItems
		|WHERE
		|	&TextAnalyst_5";
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		TextAnalyst_5 = "";
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			TextAnalyst_5 = TextAnalyst_5
				+ ?(TextAnalyst_5 = "", "", Chars.LF + Chars.Tab + "And ")
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"BudgetFlowItems.DimensionKind%1 = &Dimension",
					DimensionNumber);
		EndDo;
		Query.Text = StrReplace(Query.Text, "&TextAnalyst_5", TextAnalyst_5);
		
		Query.SetParameter("Dimension", ParameterValue);

	EndIf;
	
	If Not StandardProcessing Then
		
		ChoiceData = New ValueList;
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			If Selection.DeletionMark Then
				StructureValue = New Structure("Value, DeletionMark", Selection.BudgetFlowItem, Selection.DeletionMark);
				ChoiceData.Add(StructureValue, Selection.TextPresentation, , PictureLib.ItemMarkedForDeletion);
			Else
				ChoiceData.Add(Selection.BudgetFlowItem, Selection.TextPresentation);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	Reports.BudgetingTurnoverBalanceReport.AddReportCommand(ReportsCommands);
	If Parameters.IsObjectForm Then
		Reports.ResultOfActualDataQuery.AddBudgetItemReportCommand(ReportsCommands);
	Else
		Reports.ResultOfActualDataQuery.AddReportCommandForBudgetItems(ReportsCommands);
	EndIf;
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.BudgetFlowItems.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.45";
	Handler.ExecutionMode = "Deferred";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Id = New UUID("de295837-c61c-47d3-80bc-80753d5525b6");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.BudgetFlowItems.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr(
		"vi = 'Điền danh mục ""Quy tắc tính số dư và phát sinh liên quan của ngân sách"" theo dạng ngân sách của các loại kế hoạch.';
		|ru = 'Заполнение справочника ""Правила расчета связанных остатков и оборотов бюджетов"" по статьям бюджетов видов планов.';
		|en = 'Fill in the ""Rules for calculating related budget balances and turnovers"" catalog by budget flow items of plan profiles.'; fa = 'Fill in the ""Rules for calculating related budget balances and turnovers"" catalog by budget flow items of plan profiles.';
		|it = 'Fill in the ""Rules for calculating related budget balances and turnovers"" catalog by budget flow items of plan profiles.';
		|pl = 'Fill in the ""Rules for calculating related budget balances and turnovers"" catalog by budget flow items of plan profiles.';
		|tr = 'Plan türlerinin bütçe kalemlerine göre ”İlişkili bütçe bakiyeleri ve ciroları hesaplama kuralları“ kataloğunun doldurulması.'"));
	ListOfDescriptions.Add(NStr(
		"vi = 'Điền mục tin ""Giao dịch bị giới hạn"" trong các khoản mục ngân sách liên quan đến quy tắc giới hạn bởi giá trị ""Lưu chuyển tiền tệ"".';
		|ru = 'Заполняет реквизит ""Лимитируемая операция"" в связанных с правилами лимитов статьях бюджетов значением ""Движение денежных средств"".';
		|en = 'Fills in the ""Limited operation"" attribute in budget flow items related to limit rules with the ""Cash flow"" value.'; fa = 'Fills in the ""Limited operation"" attribute in budget flow items related to limit rules with the ""Cash flow"" value.';
		|it = 'Fills in the ""Limited operation"" attribute in budget flow items related to limit rules with the ""Cash flow"" value.';
		|pl = 'Fills in the ""Limited operation"" attribute in budget flow items related to limit rules with the ""Cash flow"" value.';
		|tr = 'Limit kurallarıyla ilişkili bütçe kalemlerindeki ""Limite tabi işlem"" özniteliğini ""Nakit akışı"" değeriyle doldurur.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.BudgetFlowItems.FullName());
	ItemsToRead.Add(Metadata.Catalogs.PlanProfiles.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.BudgetFlowItems.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.BudgetFlowItems.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	New_Items = New Array;
	New_Items.Add(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.FullName());
	Handler.NewObjects = StrConcat(New_Items, ",");

EndProcedure

// LongDesc
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters = Undefined) Export
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
	|	NOT PlanProfiles.DeleteBudgetFlowItem IN (UNDEFINED, VALUE(Catalog.BudgetFlowItems.EmptyRef))
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.InventoryConsumptionPlan)
	|	AND NOT PlanProfiles.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|				WHERE
	|					PlanProfiles.DeleteBudgetFlowItem = CalculationsRules.Receiver
	|					AND CalculationsRules.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.InventoryConsumptionPlans))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PlanProfiles.DeleteBudgetFlowItem
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	NOT PlanProfiles.DeleteBudgetFlowItem IN (UNDEFINED, VALUE(Catalog.BudgetFlowItems.EmptyRef))
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PurchasePlan)
	|	AND NOT PlanProfiles.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|				WHERE
	|					PlanProfiles.DeleteBudgetFlowItem = CalculationsRules.Receiver
	|					AND CalculationsRules.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.PurchasePlans))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PlanProfiles.DeletePaymentBudgetFlowItemBeforeShipment
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeletePaymentBudgetFlowItemBeforeShipment <> VALUE(Catalog.BudgetFlowItems.EmptyRef)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PurchasePlan)
	|	AND NOT PlanProfiles.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|				WHERE
	|					PlanProfiles.DeletePaymentBudgetFlowItemBeforeShipment = CalculationsRules.Receiver
	|					AND CalculationsRules.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.CashFlowPlansVendors))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PlanProfiles.DeletePaymentBudgetFlowItemAfterShipment
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeletePaymentBudgetFlowItemAfterShipment <> VALUE(Catalog.BudgetFlowItems.EmptyRef)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PurchasePlan)
	|	AND NOT PlanProfiles.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|				WHERE
	|					PlanProfiles.DeletePaymentBudgetFlowItemAfterShipment = CalculationsRules.Receiver
	|					AND CalculationsRules.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.CashFlowPlansVendors))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PlanProfiles.DeleteBudgetFlowItem
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	NOT PlanProfiles.DeleteBudgetFlowItem IN (UNDEFINED, VALUE(Catalog.BudgetFlowItems.EmptyRef))
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlan)
	|	AND NOT PlanProfiles.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|				WHERE
	|					PlanProfiles.DeleteBudgetFlowItem = CalculationsRules.Receiver
	|					AND CalculationsRules.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.SalesPlans))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PlanProfiles.DeletePaymentBudgetFlowItemBeforeShipment
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeletePaymentBudgetFlowItemBeforeShipment <> VALUE(Catalog.BudgetFlowItems.EmptyRef)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlan)
	|	AND NOT PlanProfiles.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|				WHERE
	|					PlanProfiles.DeletePaymentBudgetFlowItemBeforeShipment = CalculationsRules.Receiver
	|					AND CalculationsRules.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.CashFlowPlansCustomers))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PlanProfiles.DeletePaymentBudgetFlowItemAfterShipment
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeletePaymentBudgetFlowItemAfterShipment <> VALUE(Catalog.BudgetFlowItems.EmptyRef)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlan)
	|	AND NOT PlanProfiles.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|				WHERE
	|					PlanProfiles.DeletePaymentBudgetFlowItemAfterShipment = CalculationsRules.Receiver
	|					AND CalculationsRules.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.CashFlowPlansCustomers))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PlanProfiles.DeleteBudgetFlowItem
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	NOT PlanProfiles.DeleteBudgetFlowItem IN (UNDEFINED, VALUE(Catalog.BudgetFlowItems.EmptyRef))
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlanByCategories)
	|	AND NOT PlanProfiles.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|				WHERE
	|					PlanProfiles.DeleteBudgetFlowItem = CalculationsRules.Receiver
	|					AND CalculationsRules.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.SalesPlansByCategories))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PlanProfiles.DeleteBudgetFlowItem
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	NOT PlanProfiles.DeleteBudgetFlowItem IN (UNDEFINED, VALUE(Catalog.BudgetFlowItems.EmptyRef))
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.ProductionPlan)
	|	AND NOT PlanProfiles.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|				WHERE
	|					PlanProfiles.DeleteBudgetFlowItem = CalculationsRules.Receiver
	|					AND CalculationsRules.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.ProductionPlans))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PlanProfiles.DeleteBudgetFlowItem
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	NOT PlanProfiles.DeleteBudgetFlowItem IN (UNDEFINED, VALUE(Catalog.BudgetFlowItems.EmptyRef))
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.AssemblyDisassemblyPlan)
	|	AND NOT PlanProfiles.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|				WHERE
	|					PlanProfiles.DeleteBudgetFlowItem = CalculationsRules.Receiver
	|					AND CalculationsRules.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.AssemblyDisassemblyPlans))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	BudgetingLimits.BudgetFlowOrBalanceItem
	|FROM
	|	Catalog.BudgetingLimits AS BudgetingLimits
	|WHERE
	|	BudgetingLimits.BudgetFlowOrBalanceItem.LimitedTransaction = VALUE(Enum.LimitedTransactions.EmptyRef)";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("BudgetFlowItem"));
	
EndProcedure

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
	|	VALUE(Enum.DataSourceTypesForBudgeting.InventoryConsumptionPlans) AS SourceType,
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.EmptyRef) AS AmountSource,
	|	1 AS NumberOfArticles
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeleteBudgetFlowItem IN (&BudgetFlowItems)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.InventoryConsumptionPlan)
	|	AND NOT PlanProfiles.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	PlanProfiles.Ref,
	|	PlanProfiles.DeleteBudgetFlowItem,
	|	VALUE(Enum.DataSourceTypesForBudgeting.PurchasePlans),
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.Sum),
	|	1 AS NumberOfArticles
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeleteBudgetFlowItem IN (&BudgetFlowItems)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PurchasePlan)
	|	AND NOT PlanProfiles.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	PlanProfiles.Ref,
	|	PlanProfiles.DeletePaymentBudgetFlowItemBeforeShipment,
	|	VALUE(Enum.DataSourceTypesForBudgeting.CashFlowPlansVendors),
	|	CASE
	|		WHEN PlanProfiles.DeletePaymentBudgetFlowItemAfterShipment = VALUE(Catalog.BudgetFlowItems.EmptyRef)
	|			THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.Sum)
	|		ELSE VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
	|	END,
	|	1 AS NumberOfArticles
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeletePaymentBudgetFlowItemBeforeShipment IN (&BudgetFlowItems)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PurchasePlan)
	|	AND NOT PlanProfiles.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	PlanProfiles.Ref,
	|	PlanProfiles.DeletePaymentBudgetFlowItemAfterShipment,
	|	VALUE(Enum.DataSourceTypesForBudgeting.CashFlowPlansVendors),
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount),
	|	1 AS NumberOfArticles
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeletePaymentBudgetFlowItemAfterShipment IN (&BudgetFlowItems)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PurchasePlan)
	|	AND NOT PlanProfiles.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	PlanProfiles.Ref,
	|	PlanProfiles.DeleteBudgetFlowItem,
	|	VALUE(Enum.DataSourceTypesForBudgeting.SalesPlans),
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.Sum),
	|	1 AS NumberOfArticles
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeleteBudgetFlowItem IN (&BudgetFlowItems)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlan)
	|	AND NOT PlanProfiles.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	PlanProfiles.Ref,
	|	PlanProfiles.DeletePaymentBudgetFlowItemBeforeShipment,
	|	VALUE(Enum.DataSourceTypesForBudgeting.CashFlowPlansCustomers),
	|	CASE
	|		WHEN PlanProfiles.DeletePaymentBudgetFlowItemAfterShipment = VALUE(Catalog.BudgetFlowItems.EmptyRef)
	|			THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.Sum)
	|		ELSE VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
	|	END,
	|	1 AS NumberOfArticles
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeletePaymentBudgetFlowItemBeforeShipment IN (&BudgetFlowItems)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlan)
	|	AND NOT PlanProfiles.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	PlanProfiles.Ref,
	|	PlanProfiles.DeletePaymentBudgetFlowItemAfterShipment,
	|	VALUE(Enum.DataSourceTypesForBudgeting.CashFlowPlansCustomers),
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount),
	|	1 AS NumberOfArticles
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeletePaymentBudgetFlowItemAfterShipment IN (&BudgetFlowItems)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlan)
	|	AND NOT PlanProfiles.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	PlanProfiles.Ref,
	|	PlanProfiles.DeleteBudgetFlowItem,
	|	VALUE(Enum.DataSourceTypesForBudgeting.SalesPlansByCategories),
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.EmptyRef),
	|	1 AS NumberOfArticles
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeleteBudgetFlowItem IN (&BudgetFlowItems)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlanByCategories)
	|	AND NOT PlanProfiles.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	PlanProfiles.Ref,
	|	PlanProfiles.DeleteBudgetFlowItem,
	|	VALUE(Enum.DataSourceTypesForBudgeting.ProductionPlans),
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.EmptyRef),
	|	1 AS NumberOfArticles
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeleteBudgetFlowItem IN (&BudgetFlowItems)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.ProductionPlan)
	|	AND NOT PlanProfiles.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	PlanProfiles.Ref,
	|	PlanProfiles.DeleteBudgetFlowItem,
	|	VALUE(Enum.DataSourceTypesForBudgeting.AssemblyDisassemblyPlans),
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.EmptyRef),
	|	1 AS NumberOfArticles
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.DeleteBudgetFlowItem IN (&BudgetFlowItems)
	|	AND PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.AssemblyDisassemblyPlan)
	|	AND NOT PlanProfiles.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BudgetingLimits.BudgetFlowOrBalanceItem AS BudgetFlowItem
	|FROM
	|	Catalog.BudgetingLimits AS BudgetingLimits
	|WHERE
	|	BudgetingLimits.BudgetFlowOrBalanceItem.LimitedTransaction = VALUE(Enum.LimitedTransactions.EmptyRef)
	|	AND BudgetingLimits.BudgetFlowOrBalanceItem IN (&BudgetFlowItems)";
	Results = Query.ExecuteBatch();
	ResultTable1 = Results[0].Unload();
	TableResultByLimits = Results[1].Unload();
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
			
			RowTableByLimits = TableResultByLimits.Find(TheseBudgetItems.Ref, "BudgetFlowItem");
			If RowTableByLimits <> Undefined Then
			
				Block = New DataLock;
				LockItem = Block.Add(FullObjectName);
				LockItem.SetValue("Ref", TheseBudgetItems.Ref);
				LockItem.Mode = DataLockMode.Exclusive;
				Block.Lock();
			
				BudgetFlowItemObject = TheseBudgetItems.Ref.GetObject();
				BudgetFlowItemObject.LimitedTransaction = Enums.LimitedTransactions.FlowOfCash;
				InfobaseUpdate.WriteObject(BudgetFlowItemObject);
				
			EndIf;
			
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

#EndIf
