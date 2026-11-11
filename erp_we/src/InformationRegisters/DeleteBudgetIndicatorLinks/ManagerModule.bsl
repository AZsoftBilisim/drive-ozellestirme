#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.DeleteBudgetIndicatorLinks.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.25.3";
	Handler.ExecutionMode = "Deferred";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Id = New UUID("a2527f5b-4896-44e9-9a19-bbe3490cd63b");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.DeleteBudgetIndicatorLinks.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Điền danh mục ""Quy tắc tính số dư và phát sinh liên quan của ngân sách"":';
								|ru = 'Заполнение справочника ""Правила расчета связанных остатков и оборотов бюджетов"":';
								|en = 'Fill in the ""Rules for calculating related budget balances and turnovers"" catalog:'; fa = 'Fill in the ""Rules for calculating related budget balances and turnovers"" catalog:';
								|it = 'Fill in the ""Rules for calculating related budget balances and turnovers"" catalog:';
								|pl = 'Fill in the ""Rules for calculating related budget balances and turnovers"" catalog:';
								|tr = '""İlgili bütçe bakiyelerinin ve cirolarının hesaplanma kuralları"" kataloğunun güncellenmesi'"));
	ListOfDescriptions.Add(NStr("vi = 'chuyển các bản ghi từ biểu ghi thông tin ""Mối liên kết giữa các chỉ số ngân sách""';
								|ru = 'перенос записей из регистра сведений ""Связи показателей бюджетов""';
								|en = 'transfer records from the ""Budget item links"" information register'; fa = 'transfer records from the ""Budget item links"" information register';
								|it = 'transfer records from the ""Budget item links"" information register';
								|pl = 'transfer records from the ""Budget item links"" information register';
								|tr = '""Bütçe öğesi bağlantıları"" bilgi kayıtlarından kayıtların aktarılması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.DeleteBudgetIndicatorLinks.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.DeleteBudgetIndicatorLinks.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.DeleteBudgetIndicatorLinks.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = Metadata.InformationRegisters.DeleteBudgetIndicatorLinks.FullName();
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName = FullRegisterName;

	Query = New Query;
	Query.Text = 
	"SELECT
	|	RegisterData.BudgetFlowItem AS BudgetFlowItem,
	|	RegisterData.AssociatedBudgetBalanceItem AS AssociatedBudgetBalanceItem
	|FROM
	|	InformationRegister.DeleteBudgetIndicatorLinks AS RegisterData
	|WHERE
	|	NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|				WHERE
	|					RegisterData.BudgetFlowItem = CalculationsRules.Source
	|					AND RegisterData.AssociatedBudgetBalanceItem = CalculationsRules.Receiver)";
	
	ResultTable1 = Query.Execute().Unload();
	
	InfobaseUpdate.MarkForProcessing(Parameters, ResultTable1, AdditionalParameters);
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ObjectMetadata = Metadata.InformationRegisters.DeleteBudgetIndicatorLinks;
	FullObjectName  = ObjectMetadata.FullName();
	
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName) Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For Each RegisterRecord In UpdatedData Do
		
		RecordSet = InformationRegisters.DeleteBudgetIndicatorLinks.CreateRecordSet();
		TypesOfIndicatorAnalytics = Common.ObjectAttributesValues(RegisterRecord.AssociatedBudgetBalanceItem,
			"DimensionKind1,DimensionKind2,DimensionKind3,DimensionKind4,DimensionKind5,DimensionKind6");
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			
			For Each DimensionItem In UpdatedData.Columns Do
				LockItem.SetValue(DimensionItem.Name, RegisterRecord[DimensionItem.Name]);
				RecordSet.Filter[DimensionItem.Name].Set(RegisterRecord[DimensionItem.Name]);
			EndDo;
			LockItem.Mode = DataLockMode.Shared;
			Block.Lock();

			ExceptionReason = "BadData";
			RecordSet.Read();
			For Each Record In RecordSet Do
				ObjectCalculationRule = Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.CreateItem();
				ObjectCalculationRule.SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers;
				ObjectCalculationRule.Receiver = RegisterRecord.AssociatedBudgetBalanceItem;
				ObjectCalculationRule.Source = RegisterRecord.BudgetFlowItem;
				ObjectCalculationRule.Description = Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.GenerateRuleName(
					ObjectCalculationRule.Description, ObjectCalculationRule.SourceType,
					ObjectCalculationRule.Source, ObjectCalculationRule.Receiver);
				ObjectCalculationRule.Status = Enums.BudgetingRuleStatuses.Valid;
				NewRow = ObjectCalculationRule.DataCalculationSettings.Add();
				NewRow.ZoomRatio = Record.ZoomRatio;
				NewRow.ReverseSign = Record.Expense;
				NewRow.AmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum;
				For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
					AnalyticsViewLine = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1",
						DimensionNumber);
					If Not ValueIsFilled(TypesOfIndicatorAnalytics[AnalyticsViewLine]) Then
						Continue;
					EndIf;
					NewRow = ObjectCalculationRule.DimensionFillingSettings.Add();
					NewRow.DimensionKind = TypesOfIndicatorAnalytics[AnalyticsViewLine];
					BroadcastAnalyticsLine = StringFunctionsClientServer.SubstituteParametersToString(
						"BroadcastAnalytics%1", DimensionNumber);
					If Not Record[BroadcastAnalyticsLine] Then
						NewRow.FillingMethod = Enums.MethodsOfFillingBudgetFlowItemDimensions.BySpecifiedValue;
						AnalyticsLine = StringFunctionsClientServer.SubstituteParametersToString("Dimension%1",
							DimensionNumber);
						NewRow.DimensionValue = Record[AnalyticsLine];
					Else
						NewRow.FillingMethod = Enums.MethodsOfFillingBudgetFlowItemDimensions.FromDataSource;
						AnalyticsBroadcastAddressString = StringFunctionsClientServer.SubstituteParametersToString(
							"DimensionTranslationAddress%1", DimensionNumber);
						NewRow.DimensionPopulationExpression = StringFunctionsClientServer.SubstituteParametersToString(
							"Dimension%1", Record[AnalyticsBroadcastAddressString]);
					EndIf;
				EndDo;
				ObjectCalculationRule.Write();
			EndDo;
			InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			If ExceptionReason = "BadData" Then
				InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), RegisterRecord.AssociatedBudgetBalanceItem);
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
				InfobaseUpdate.FileIssueWithData(RegisterRecord.AssociatedBudgetBalanceItem,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
		FullObjectName, New Structure);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf