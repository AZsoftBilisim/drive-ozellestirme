#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
#Region Public
// Determines the sources to clarify the account is available in the register and their properties.
//
//
// Parameters:
//  SourceProperties - String - "Field name" - the name of the attribute of the accumulation register, from which you plan to get the source
//                               of account refinement.
//
// Returns:
//  Map - The key is the name of the source of the invoice refinement. 
//                 Value - the structure of the properties of the invoice refinement source.
//
Function SourcesOfInvoiceRefinement(SourceProperties) Export
	
	SourcesOfInvoiceRefinement = New Map;
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfIncomeExpensesCr,
		New Structure(SourceProperties, "HFCRevenueExpenditure"));
		
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfIncomeExpensesDr,
		New Structure(SourceProperties, "CorHFCRevenueExpenditure"));
		
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfFixedAndIntangibleAssetsCr,
		New Structure(SourceProperties, "FinancialAccountingGroup"));
		
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfFixedAndIntangibleAssetsDr,
		New Structure(SourceProperties, "CorFinancialAccountingGroup"));
	
	Return SourcesOfInvoiceRefinement;
	
EndFunction

// Defines the sources of register divisions and their properties.
//
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDivisions() Export

	SourcesOfDivisions = New Map;
	
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.BusinessOperation, "Department");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.Department, "Department");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.DebitBusinessUnit, "DebitBusinessUnit");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.IncomeExpensesAccountingDimension, "RevenueExpenseAnalyticsDivision");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.OtherAssetLiabilityAccountingDimension, "AssetsLiabilitiesDimension");
	
	Return SourcesOfDivisions;
	
EndFunction

// Defines the sources of register directions and their properties.
//
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDirections() Export

	Result = New Map;
	
	SourcesOfDirections = Enums.SourceOfLinesOfBusinessOfAnalyticalRegister;
	Result.Insert(SourcesOfDirections.LineOfBusiness, "LineOfBusiness");
	Result.Insert(SourcesOfDirections.CorLineOfBusiness, "CorLineOfBusiness");

	Return Result;

EndFunction

// Defines the sources of sub-content filling.
//
//
// Returns:
//  Array - array of register attributes.
//
Function SourcesOfExtdimension() Export

	ExtDimensionArrayDr = New Array;
	ExtDimensionArrayDr.Add("CorItem");
	ExtDimensionArrayDr.Add("CorIncomeDimension");
	ExtDimensionArrayDr.Add("CorExpenditureDimension");
	ExtDimensionArrayDr.Add("CorDimensionOfAssetsLiabilities");
	ExtDimensionArrayDr.Add("SalaryTransactionKind");
	
	ExtDimensionArrayCr = New Array;
	ExtDimensionArrayCr.Add("AssetRef");
	ExtDimensionArrayCr.Add("DimensionOfRevenue");
	ExtDimensionArrayCr.Add("DimensionOfExpenses");
	ExtDimensionArrayCr.Add("AssetsLiabilitiesDimension");
	ExtDimensionArrayCr.Add("SalaryTransactionKind");

	Return New Structure("ExtDimensionDr, ExtDimensionCr", ExtDimensionArrayDr, ExtDimensionArrayCr);
	
EndFunction

// Identifies indicators in the currency of the register.
//
//
// Parameters:
//  PropertiesOfIndicators - String - "Sourcecurrency" - the currency source for the register indicator.
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function IndicatorsInCurrency(PropertiesOfIndicators) Export

	IndicatorsInCurrency = New Map;
	
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInCurrency, New Structure(PropertiesOfIndicators, "Currency"));
	
	Return IndicatorsInCurrency;

EndFunction

// Identifies indicators in the currency of the register.
//
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function QuantityIndicators() Export

	QuantityIndicators = New Map;
	Return QuantityIndicators;

EndFunction

// Defines register metrics.
//
//
// Parameters:
//  Properties - Structure - containing the keys of the properties of Indicators, properties of Resources.
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function Indicators(Properties) Export

	Indicators = New Map;
	
	PropertiesOfIndicators = Properties.PropertiesOfIndicators;
	ResourceProperties = Properties.ResourceProperties;
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "SumMan", "CurrencyOfMan"));
    ArrayOfResources.Add(New Structure(ResourceProperties, "SumCompl", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountInCurrency", "Currency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	Return Indicators;
	
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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.61";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("bc5ba003-4dfe-45a1-a408-74ea54ea4f13");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("ru = 'Обновление регистра ""Движения Доходы/Расходы - Прочие активы/пассивы"":';
								|vi = 'Update the ""Income/Expenses - Other assets/liabilities"" register:';
								|en = 'Update the ""Income/Expenses - Other assets/liabilities"" register:'; fa = 'Update the ""Income/Expenses - Other assets/liabilities"" register:';
								|it = 'Update the ""Income/Expenses - Other assets/liabilities"" register:';
								|pl = 'Update the ""Income/Expenses - Other assets/liabilities"" register:';
								|tr = '""Gelir/Gider - Diğer Varlıklar/Yükümlülükler Hareketleri"" kaydının güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("ru = '- Заменяет некорректные ссылки на статьи ""Основные средства"" и ""Нематериальные активы""';
								|vi = '- Replaces incorrect links to the ""Fixed assets"" and ""Intangible assets"" items';
								|en = '- Replaces incorrect links to the ""Fixed assets"" and ""Intangible assets"" items'; fa = '- Replaces incorrect links to the ""Fixed assets"" and ""Intangible assets"" items';
								|it = '- Replaces incorrect links to the ""Fixed assets"" and ""Intangible assets"" items';
								|pl = '- Replaces incorrect links to the ""Fixed assets"" and ""Intangible assets"" items';
								|tr = '- ""Sabit kıymetler"" ve ""maddi olmayan duran varlıklar"" kalemlerine olan geçersiz bağlantıları değiştirir'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Data logging handler for updates
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	RegisterMetadata = Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities;
	FullRegisterName = RegisterMetadata.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	Query.Parameters.Insert("PointInTime", New PointInTime('00010101'));
	
	Query.Text = "
	|SELECT DISTINCT
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.PointInTime AS PointInTime
	|INTO TTRecordersForProcessing
	|FROM
	|	AccumulationRegister.RecordsIncomeExpensesOtherAssetsLiabilities AS RegisterRecords
	|WHERE
	|	RegisterRecords.Active
	|	AND (
	|		RegisterRecords.AssetRef = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IntangibleAssets)
	|	OR
	|		RegisterRecords.AssetRef = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.FixedAssets)
	|	OR
	|		RegisterRecords.CorItem = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IntangibleAssets)
	|	OR
	|		RegisterRecords.CorItem = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.FixedAssets)
	|	)
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
	
	RegisterMetadata = Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities;
	FullRegisterName = RegisterMetadata.FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	AssetLiabilityItemManager = ChartsOfCharacteristicTypes.AssetLiabilityItems;
	
	For Each DataString1 In UpdatedData Do
		Recorder = DataString1.Recorder;
		
		ExceptionReason = "";
		Recommendation = "";
	
		ListOfDescriptions = New Array;
		ListOfDescriptions.Add(NStr("ru = 'Не удалось обработать набор записей регистра накопления ""Движения Доходы/Расходы - Прочие активы/пассивы"":';
									|vi = 'Cannot process the record set of the ""Income/Expenses - Other assets/liabilities"" accumulation register:';
									|en = 'Cannot process the record set of the ""Income/Expenses - Other assets/liabilities"" accumulation register:'; fa = 'Cannot process the record set of the ""Income/Expenses - Other assets/liabilities"" accumulation register:';
									|it = 'Cannot process the record set of the ""Income/Expenses - Other assets/liabilities"" accumulation register:';
									|pl = 'Cannot process the record set of the ""Income/Expenses - Other assets/liabilities"" accumulation register:';
									|tr = 'Birikim kaydı ""Gelir/Gider - Diğer Varlıklar/Yükümlülükler Hareketleri"" kayıt kümesi işlenemedi:'"));
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.RecordsIncomeExpensesOtherAssetsLiabilities.RecordSet");
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
			
			RecordSet = AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Recorder);
			RecordSet.Read();
			
			For Each Record In RecordSet Do
				If Record.AssetRef = AssetLiabilityItemManager.IntangibleAssets Then
					Record.AssetRef = AssetLiabilityItemManager.ManBalanceIntangibleAssets;
					ListOfDescriptions.Add(NStr("ru = '- Не удалось заменить некорректную ссылку на статью ""Нематериальные активы""';
												|vi = '- Cannot replace the incorrect link to the ""Intangible assets"" item';
												|en = '- Cannot replace the incorrect link to the ""Intangible assets"" item'; fa = '- Cannot replace the incorrect link to the ""Intangible assets"" item';
												|it = '- Cannot replace the incorrect link to the ""Intangible assets"" item';
												|pl = '- Cannot replace the incorrect link to the ""Intangible assets"" item';
												|tr = '""Maddi olmayan duran varlıklar"" kalemine olan geçersiz bağlantı değiştirilemedi'"));
				ElsIf Record.AssetRef = AssetLiabilityItemManager.FixedAssets Then
					Record.AssetRef = AssetLiabilityItemManager.ManBalanceFixedAssets;
					ListOfDescriptions.Add(NStr("ru = '- Не удалось заменить некорректную ссылку на статью ""Основные средства""';
												|vi = '- Cannot replace the incorrect link to the ""Fixed assets"" item';
												|en = '- Cannot replace the incorrect link to the ""Fixed assets"" item'; fa = '- Cannot replace the incorrect link to the ""Fixed assets"" item';
												|it = '- Cannot replace the incorrect link to the ""Fixed assets"" item';
												|pl = '- Cannot replace the incorrect link to the ""Fixed assets"" item';
												|tr = '""Sabit kıymetler"" kalemine olan geçersiz bağlantı değiştirilemedi'"));
				EndIf;
				
				If Record.CorItem = AssetLiabilityItemManager.IntangibleAssets Then
					Record.CorItem = AssetLiabilityItemManager.ManBalanceIntangibleAssets;
					ListOfDescriptions.Add(NStr("ru = '- Не удалось заменить некорректную ссылку на статью ""Нематериальные активы""';
												|vi = '- Cannot replace the incorrect link to the ""Intangible assets"" item';
												|en = '- Cannot replace the incorrect link to the ""Intangible assets"" item'; fa = '- Cannot replace the incorrect link to the ""Intangible assets"" item';
												|it = '- Cannot replace the incorrect link to the ""Intangible assets"" item';
												|pl = '- Cannot replace the incorrect link to the ""Intangible assets"" item';
												|tr = '""Maddi olmayan duran varlıklar"" kalemine olan geçersiz bağlantı değiştirilemedi'"));
				ElsIf Record.CorItem = AssetLiabilityItemManager.FixedAssets Then
					Record.CorItem = AssetLiabilityItemManager.ManBalanceFixedAssets;
					ListOfDescriptions.Add(NStr("ru = '- Не удалось заменить некорректную ссылку на статью ""Основные средства""';
												|vi = '- Cannot replace the incorrect link to the ""Fixed assets"" item';
												|en = '- Cannot replace the incorrect link to the ""Fixed assets"" item'; fa = '- Cannot replace the incorrect link to the ""Fixed assets"" item';
												|it = '- Cannot replace the incorrect link to the ""Fixed assets"" item';
												|pl = '- Cannot replace the incorrect link to the ""Fixed assets"" item';
												|tr = '""Sabit kıymetler"" kalemine olan geçersiz bağlantı değiştirilemedi'"));
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