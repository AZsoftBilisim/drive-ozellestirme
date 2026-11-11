#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	
EndProcedure

#EndRegion

#Region EventHandlers

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		If Not ValueIsFilled(Parameters.CommandParameter) Then
			CommonClientServer.MessageToUser(NStr("vi = 'Chưa thực hiện phân bổ hoặc không cần phân bổ nguyên vật liệu.';
													|ru = 'Распределение материала не выполнено или не требуется.';
													|en = 'Allocation of material is not performed or not required.'; fa = 'Allocation of material is not performed or not required.';
													|it = 'L''allocazione del materiale non è stata effettuata o non è richiesta.';
													|pl = 'Przydział materiału nie jest wykonany lub nie jest wymagany.';
													|tr = 'Malzeme dağıtımı gerçekleştirilmedi veya gerekli değildir.'"),,,,Cancel);
		EndIf;
		
		If TypeOf(Parameters.CommandParameter) = Type("DocumentRef.ProductionCostAllocation")
		 And ValueIsFilled(Parameters.CommandParameter) 
		 And Not Common.ObjectAttributeValue(Parameters.CommandParameter, "NewProduction") Then
			CommonClientServer.MessageToUser(NStr("vi = 'Báo cáo chỉ dành cho sử dụng với các chứng từ sản xuất, phiên bản 2.2.';
													|ru = 'Отчет предназначен для использования только для документов производства версии 2.2.';
													|en = 'The report is designed to be used only for production documents version 2.2.'; fa = 'The report is designed to be used only for production documents version 2.2.';
													|it = 'Il report è destinato esclusivamente all''uso con i documenti di produzione versione 2.2';
													|pl = 'Raport jest przeznaczona do stosowania tylko dla dokumentów produkcyjnych wersji 2.2.';
													|tr = 'Raporun yalnızca sürüm 2.2 üretim belgeleri için kullanılması amaçlandı.'"),,,,Cancel);
		EndIf;
		
		ThisForm.ParametersForm.Filter.Insert("Recorder", Parameters.CommandParameter);
		
	Else
		
		Cancel = True;
		Raise NStr("vi = 'Báo cáo chỉ nhằm mục đích mở trong chứng từ ""phân bổ vật liệu và công việc"".';
					|ru = 'Отчет предназначен только для открытия в документе ""Распределение материалов и работ"".';
					|en = 'You can open the report only in the ""Material and labor allocation"" document.'; fa = 'You can open the report only in the ""Material and labor allocation"" document.';
					|it = 'Il report viene aperto solo nel documento ""Allocazione dei materiali e lavori"".';
					|pl = 'Raport jest przeznaczony tylko do otwarcia w dokumencie ""Rozdział materiałów i prac"".';
					|tr = 'Rapor sadece ""Malzeme ve işçilik tahsisatı"" belgesinde açılmak üzere amaçlandı.'") ;
		
	EndIf;
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	LoggerParameter = DataCompositionClientServer.GetParameter(ReportSettings, "Recorder");
	Recorder         = LoggerParameter.Value;
	
	ThisIsWasteDistribution = TypeOf(Recorder) = Type("DocumentRef.RecyclableWasteAllocation");
	
	If ThisIsWasteDistribution Then
		Attributes = Common.ObjectAttributesValues(Recorder, "Date, Organization, AllocationBase, Products, Characteristic, Department");
	Else
		Attributes = Common.ObjectAttributesValues(Recorder, "Date, Organization, AllocationBase, Products, Characteristic, Warehouse, Department");
	EndIf;
	
	BeginOfPeriod     = BegOfMonth(Attributes.Date);
	CompanyArray = CommonClientServer.ValueInArray(Attributes.Organization);
	
	// Cost
	ArrayOfBaseAllocationTypesByCost = New Array();
	ArrayOfBaseAllocationTypesByCost.Add(Enums.TypesOfCostAllocatingBase.MaterialCostsAmount);
	ArrayOfBaseAllocationTypesByCost.Add(Enums.TypesOfCostAllocatingBase.TotalPayrollExpenses);
	ArrayOfBaseAllocationTypesByCost.Add(Enums.TypesOfCostAllocatingBase.StandardRemunerationLevel);
	ArrayOfBaseAllocationTypesByCost.Add(Enums.TypesOfCostAllocatingBase.TargetProductCost);
	
	// Count
	ArrayOfBaseDistributionTypesByQuantity = New Array();
	ArrayOfBaseDistributionTypesByQuantity.Add(Enums.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials);
	ArrayOfBaseDistributionTypesByQuantity.Add(Enums.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds);
	ArrayOfBaseDistributionTypesByQuantity.Add(Enums.TypesOfCostAllocatingBase.ProductsQuantity);
	
	// VolumeM3
	ArrayOfTypesOfBaseDistributionByVolume = New Array();
	ArrayOfTypesOfBaseDistributionByVolume.Add(Enums.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials);
	ArrayOfTypesOfBaseDistributionByVolume.Add(Enums.TypesOfCostAllocatingBase.ProductsVolume);
	
	// Weight
	ArrayOfBaseWeightDistributionTypes = New Array();
	ArrayOfBaseWeightDistributionTypes.Add(Enums.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials);
	ArrayOfBaseWeightDistributionTypes.Add(Enums.TypesOfCostAllocatingBase.ProductsWeight);
	
	TTM = CostCalculationMaterialCosts.DataForDecipheringDistributionOfProductsForProduction(BeginOfPeriod, CompanyArray, Recorder);
	
	Query = New Query;
	Query.TempTablesManager = TTM;
	Query.Text =
	"SELECT DISTINCT
	|	ProductionLots.ProductionLot
	|INTO StagesNotIncludedInDistribution
	|FROM
	|	ProductionBatchesAreSummarized AS ProductionLots
	|		LEFT JOIN DistributionBaseDetails AS DistributionBaseDetails
	|			ON ProductionLots.ProductionLot = DistributionBaseDetails.ProductionLot
	|WHERE
	|	DistributionBaseDetails.ProductionLot IS NULL
	|	AND ProductionLots.CostAllocationForIssue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	""ByRule""                AS EntryType,
	|	DD.Recorder               AS Recorder,
	|	DD.ProductionLot        AS ProductionLot,
	|	DD.Denominator               AS IndicatorValue,
	|	0                            AS Count,
	|	ISNULL(SettlementBatches.Count,0) AS QuantityIsAllocated,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	CASE
	|		WHEN DD.IndicatorKind = ""Material""
	|			THEN DD.Material
	|		WHEN DD.IndicatorKind = ""ManufacturedProduct""
	|			THEN DD.ManufacturedProduct
	|		WHEN DD.IndicatorKind = ""WorkKind""
	|			THEN DD.WorkKind
	|	END AS MaterialProductsTypeOfWork,
	|	DD.ProductsGroup AS ProductsGroup,
	|	1 AS OutputOrder,
	|	DocumentDistributions.AllocatedAccordingToRule AS AllocatedAccordingToRule,
	|	DocumentDistributions.AllocationBase AS AllocationBase
	|INTO DecryptionData
	|FROM
	|	DistributionBaseDetails AS DD
	|		INNER JOIN Document.ProductionCostAllocation AS DocumentDistributions
	|			ON DD.Recorder = DocumentDistributions.Ref
	|		LEFT JOIN TTProductionCostsCostOfGoods AS SettlementBatches
	|			ON DD.ProductionLot = SettlementBatches.CorLot
	|			AND SettlementBatches.RecordType = VALUE(AccumulationRecordType.Expense)
	|WHERE
	|	DD.Recorder = &Recorder
	|	AND DocumentDistributions.QuantityToAllocateAccordingToRule > 0
	|
	|UNION ALL
	|
	|SELECT
	|	""ByRule""                AS EntryType,
	|	DD.Recorder               AS Recorder,
	|	DD.ProductionLot        AS ProductionLot,
	|	DD.Denominator               AS IndicatorValue,
	|	0 AS                        Count,
	|	ISNULL(- SettlementBatches.Count,0) AS QuantityIsAllocated,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	CASE
	|		WHEN DD.IndicatorKind = ""Material""
	|			THEN DD.Material
	|		WHEN DD.IndicatorKind = ""ManufacturedProduct""
	|			THEN DD.ManufacturedProduct
	|		WHEN DD.IndicatorKind = ""WorkKind""
	|			THEN DD.WorkKind
	|	END AS MaterialProductsTypeOfWork,
	|	DD.ProductsGroup AS ProductsGroup,
	|	1 AS OutputOrder,
	|	DocumentDistributions.AllocatedAccordingToRule AS AllocatedAccordingToRule,
	|	DocumentDistributions.AllocationBase AS AllocationBase
	|FROM
	|	DistributionBaseDetails AS DD
	|		INNER JOIN Document.RecyclableWasteAllocation AS DocumentDistributions
	|			ON DD.Recorder = DocumentDistributions.Ref
	|		LEFT JOIN TTProductionCostsCostOfGoods AS SettlementBatches
	|			ON DD.ProductionLot = SettlementBatches.CorLot
	|			AND SettlementBatches.RecordType = VALUE(AccumulationRecordType.Expense)
	|WHERE
	|	DD.Recorder = &Recorder
	|	AND DocumentDistributions.QuantityAccordingToRule > 0
	|
	|UNION ALL
	|
	|SELECT
	|	""ByStagesManually"",
	|	DD.Ref,
	|	DD.ProductionLot,
	|	DD.Count,
	|	DD.Count,
	|	DD.Count,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	1,
	|	UNDEFINED,
	|	UNDEFINED
	|FROM
	|	Document.ProductionCostAllocation.ProductionLots AS DD
	|WHERE
	|	DD.Ref = &Recorder
	|
	|UNION ALL
	|
	|SELECT
	|	""ByStagesManually"",
	|	DD.Ref,
	|	DD.ProductionLot,
	|	DD.Count,
	|	DD.Count,
	|	DD.Count,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	1,
	|	UNDEFINED,
	|	UNDEFINED
	|FROM
	|	Document.RecyclableWasteAllocation.ProductionLots AS DD
	|WHERE
	|	DD.Ref = &Recorder
	|
	|UNION ALL
	|
	|SELECT
	|	""Nastati"",
	|	DD.Ref,
	|	UNDEFINED,
	|	DD.Count,
	|	DD.Count,
	|	DD.Count,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	UNDEFINED,
	|	UNDEFINED,
	|	1,
	|	UNDEFINED,
	|	UNDEFINED
	|FROM
	|	Document.ProductionCostAllocation.OtherExpenses AS DD
	|WHERE
	|	DD.Ref = &Recorder
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""ByRule"",
	|	UNDEFINED,
	|	VALUE(Document.ProductionStage2_2.EmptyRef),
	|	0,
	|	0,
	|	0,
	|	UNDEFINED,
	|	UNDEFINED,
	|	DD.ProductionLot,
	|	UNDEFINED,
	|	3,
	|	UNDEFINED,
	|	UNDEFINED
	|FROM
	|	StagesNotIncludedInDistribution AS DD
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherStageMaterials.ProductionLot AS ProductionLot,
	|	OtherStageMaterials.ProductsGroup AS ProductsGroup,
	|	2 AS OutputOrder,
	|	SUM(OtherStageMaterials.Count) AS Count,
	|	SUM(OtherStageMaterials.VolumeM3) AS VolumeM3,
	|	SUM(OtherStageMaterials.Weight) AS Weight,
	|	SUM(OtherStageMaterials.Cost) AS Cost,
	|	0 AS StandardCost
	|INTO DataNotIncludedInDistributionDatabase
	|FROM
	|	DataOnMaterialCosts AS OtherStageMaterials
	|		LEFT JOIN DistributionBaseDetails AS StageDistributionBase
	|		ON OtherStageMaterials.ProductionLot = StageDistributionBase.ProductionLot
	|		AND OtherStageMaterials.Material = StageDistributionBase.Material
	|		INNER JOIN DistributionBaseDetails AS FilterByBatches
	|		ON OtherStageMaterials.ProductionLot = FilterByBatches.ProductionLot
	|		AND OtherStageMaterials.Department = FilterByBatches.Department
	|
	|WHERE
	|	StageDistributionBase.Material IS NULL
	|	AND FilterByBatches.IndicatorKind = ""Material""
	|
	|GROUP BY
	|	OtherStageMaterials.ProductionLot,
	|	OtherStageMaterials.ProductsGroup
	|
	|UNION ALL
	|
	|SELECT
	|	OtherStageProduction.ProductionLot,
	|	OtherStageProduction.ProductsGroup,
	|	2,
	|	SUM(OtherStageProduction.Count),
	|	SUM(OtherStageProduction.VolumeM3),
	|	SUM(OtherStageProduction.Weight),
	|	SUM(OtherStageProduction.Cost),
	|	0
	|FROM
	|	ProductData_6 AS OtherStageProduction
	|		LEFT JOIN DistributionBaseDetails AS StageDistributionBase
	|		ON OtherStageProduction.ProductionLot = StageDistributionBase.ProductionLot
	|		AND OtherStageProduction.ManufacturedProduct = StageDistributionBase.ManufacturedProduct
	|		INNER JOIN DistributionBaseDetails AS FilterByBatches
	|		ON OtherStageProduction.ProductionLot = FilterByBatches.ProductionLot
	|		AND OtherStageProduction.Department = FilterByBatches.Department
	|
	|WHERE
	|	StageDistributionBase.ManufacturedProduct IS NULL
	|	AND FilterByBatches.IndicatorKind = ""ManufacturedProduct""
	|
	|GROUP BY
	|	OtherStageProduction.ProductionLot,
	|	OtherStageProduction.ProductsGroup
	|
	|UNION ALL
	|
	|SELECT
	|	OtherStageJobs.ProductionLot,
	|	OtherStageJobs.ProductsGroup,
	|	2,
	|	SUM(OtherStageJobs.Count),
	|	0,
	|	0,
	|	SUM(OtherStageJobs.Cost),
	|	SUM(OtherStageJobs.StandardCost)
	|FROM
	|	DataOnLaborCosts AS OtherStageJobs
	|		LEFT JOIN DistributionBaseDetails AS StageDistributionBase
	|		ON OtherStageJobs.ProductionLot = StageDistributionBase.ProductionLot
	|		AND OtherStageJobs.WorkKind = StageDistributionBase.WorkKind
	|		INNER JOIN DistributionBaseDetails AS FilterByBatches
	|		ON OtherStageJobs.ProductionLot = FilterByBatches.ProductionLot
	|		AND OtherStageJobs.Department = FilterByBatches.Department
	|
	|WHERE
	|	StageDistributionBase.WorkKind IS NULL
	|	AND FilterByBatches.IndicatorKind = ""WorkKind""
	|
	|GROUP BY
	|	OtherStageJobs.ProductionLot,
	|	OtherStageJobs.ProductsGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(CalculationOfSpecificGravity.IndicatorValue) AS IndicatorValue,
	|	COUNT(DISTINCT CalculationOfSpecificGravity.MaterialProductsTypeOfWork) AS QuantityOfMaterials
	|INTO DataForCalculatingSpecificGravity
	|FROM
	|	DecryptionData AS CalculationOfSpecificGravity
	|WHERE
	|	CalculationOfSpecificGravity.EntryType = ""ByRule""
	|	AND CalculationOfSpecificGravity.OutputOrder = 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.ProductionLot AS ProductionLot,
	|	DD.ProductsGroup AS ProductsGroup,
	|	DD.EntryType AS EntryType,
	|	DD.IndicatorValue AS IndicatorValue,
	|	DD.IndicatorValue * 100 / CASE
	|		WHEN SpecificGravityData.IndicatorValue = 0
	|			THEN 1
	|		ELSE SpecificGravityData.IndicatorValue
	|	END AS SpecificGravity,
	|	DD.Count AS Count,
	|	DD.OutputOrder AS OutputOrder,
	|	DD.Recorder AS Recorder,
	|	CASE
	|		WHEN DD.AllocationBase IN (&QuantityArray)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS SumUpQuantityByStage,
	|	DD.AllocatedAccordingToRule AS AllocatedAccordingToRule,
	|	DD.MaterialProductsTypeOfWork AS MaterialProductsTypeOfWork,
	|	DD.QuantityIsAllocated AS QuantityIsAllocated,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	DD.AllocationBase AS AllocationBase
	|FROM
	|	DecryptionData AS DD,
	|	DataForCalculatingSpecificGravity AS SpecificGravityData
	|
	|UNION ALL
	|
	|SELECT
	|	DataNotIncludedInDistributionDatabase.ProductionLot,
	|	DataNotIncludedInDistributionDatabase.ProductsGroup,
	|	""ByRule"",
	|	CASE
	|		WHEN &AllocationBase IN (&VolumeArray)
	|			THEN DataNotIncludedInDistributionDatabase.VolumeM3
	|		WHEN &AllocationBase IN (&WeightArray)
	|			THEN DataNotIncludedInDistributionDatabase.Weight
	|		ELSE 0
	|	END,
	|	0,
	|	0,
	|	DataNotIncludedInDistributionDatabase.OutputOrder,
	|	&Recorder,
	|	CASE
	|		WHEN &AllocationBase IN (&QuantityArray)
	|			THEN FALSE
	|		ELSE TRUE
	|	END,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	&AllocationBase
	|FROM
	|	DataNotIncludedInDistributionDatabase AS DataNotIncludedInDistributionDatabase
	|		LEFT JOIN StagesNotIncludedInDistribution AS StagesNotIncludedInDistribution
	|		ON DataNotIncludedInDistributionDatabase.ProductionLot = StagesNotIncludedInDistribution.ProductionLot
	|WHERE
	|	StagesNotIncludedInDistribution.ProductionLot IS NULL
	|
	|ORDER BY
	|	AllocationBase DESC";
	
	Query.SetParameter("Recorder",       Recorder);
	Query.SetParameter("QuantityArray",  ArrayOfBaseDistributionTypesByQuantity);
	Query.SetParameter("ArrayOfCosts",   ArrayOfBaseAllocationTypesByCost);
	Query.SetParameter("VolumeArray",      ArrayOfTypesOfBaseDistributionByVolume);
	Query.SetParameter("WeightArray",        ArrayOfBaseWeightDistributionTypes);
	Query.SetParameter("AllocationBase", Attributes.AllocationBase);
	
	QueryResult = Query.Execute();
	Allocation    = QueryResult.Unload();
	
	ExternalDataSets = New Structure("Allocation", Allocation);
	
	TemplateComposer   = New DataCompositionTemplateComposer;
	CompositionProcessor = New DataCompositionProcessor;
	CompositionTemplate     = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	// Post processing of the report.
	// We set the reflection of the distribution rules, change the column headers, etc.
	
	SpreadsheetDocument = OutputProcessor.EndOutput();
	
	Area = SpreadsheetDocument.FindText("%1"); // Title
	If Area <> Undefined Then
		If ThisIsWasteDistribution Then
			ReportHeader = NStr("vi = 'Phân bổ phế liệu thu hồi ""%1"" trong bộ phận "" %2""';
								|ru = 'Распределение возвратного отхода ""%1"" в подразделении ""%2""';
								|en = 'Recyclable waste allocation ""%1"" in business unit ""%2""'; fa = 'Recyclable waste allocation ""%1"" in business unit ""%2""';
								|it = 'Allocazione dei rifiuti riciclabili ""%1"" nel reparto ""%2""';
								|pl = 'Przydział odpadów zwrotnych ""%1"" w dziale ""%2""';
								|tr = '""%2"" departmanında geri dönüştürülebilir atık ""%1"" dağıtımı'");
				ReportHeader = StringFunctionsClientServer.SubstituteParametersToString(
					ReportHeader,
					ProductsClientServer.ProductPresentation(Attributes.Products, Attributes.Characteristic),
					Attributes.Department);
		Else
			If Common.ObjectAttributeValue(Attributes.Products, "ItemsType") = Enums.ItemsTypes.Work_5 Then
				ReportHeader = NStr("vi = 'Phân bổ công việc ""%1"" trong bộ phận "" %2"" cho %3';
									|ru = 'Распределение работы ""%1"" в подразделении ""%2"" за %3';
									|en = 'Allocation of work ""%1"" in business unit ""%2"" for %3'; fa = 'Allocation of work ""%1"" in business unit ""%2"" for %3';
									|it = 'Allocazione del lavoro ""%1"" nel reparto ""%2"" per %3';
									|pl = 'Przydział pracy ""%1"" w dziale ""%2"" za %3';
									|tr = '%3 karşılığında ""%2"" departmanında iş dağıtımı ""%1""'");
				ReportHeader = StringFunctionsClientServer.SubstituteParametersToString(
					ReportHeader,
					ProductsClientServer.ProductPresentation(Attributes.Products, Attributes.Characteristic),
					Attributes.Department,
					Format(Attributes.Date,NStr("vi = 'ДФ=''ММММ гггг''';
												|ru = 'ДФ=''ММММ гггг''';
												|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
												|it = 'ДФ=''ММММ гггг''';
												|pl = 'DF=''MMMM yyyy''';
												|tr = 'DF=''MMMM yyyy'''")));
			Else
				ReportHeader = NStr("vi = 'Phân bổ vật liệu ""%1"" trong kho tại xưởng "" %2"" cho %3';
									|ru = 'Распределение материала ""%1"" в кладовой ""%2"" за %3';
									|en = 'Allocation of material ""%1"" in storeroom ""%2"" for %3'; fa = 'Allocation of material ""%1"" in storeroom ""%2"" for %3';
									|it = 'Allocazione del materiale ""%1"" nel magazzino ""%2"" per %3';
									|pl = 'Przydział materiału ""%1"" w wytwórni ""%2"" za %3';
									|tr = '%3 karşılığında ""%2"" ambarda malzeme dağıtımı ""%1""'");
				ReportHeader = StringFunctionsClientServer.SubstituteParametersToString(
					ReportHeader,
					ProductsClientServer.ProductPresentation(Attributes.Products, Attributes.Characteristic),
					Attributes.Warehouse,
					Format(Attributes.Date,NStr("vi = 'ДФ=''ММММ гггг''';
												|ru = 'ДФ=''ММММ гггг''';
												|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
												|it = 'ДФ=''ММММ гггг''';
												|pl = 'DF=''MMMM yyyy''';
												|tr = 'DF=''MMMM yyyy'''")));
			EndIf;
		EndIf;
		Area.Text = StrReplace(Area.Text, "%1", ReportHeader);
	EndIf;
	
	RulePresentation    = NStr("vi = 'Quy tắc phân bổ khác %1';
								|ru = 'Прочее правило распределения %1';
								|en = 'Other allocation rule %1'; fa = 'Other allocation rule %1';
								|it = 'Altre regole di allocazione %1';
								|pl = 'Pozostałe reguły podziału %1';
								|tr = 'Diğer dağıtım kuralı %1'");
	IndicatorPresentation = NStr("vi = 'Giá trị chỉ tiêu';
								|ru = 'Значение показателя';
								|en = 'Indicator value'; fa = 'مقدار شاخص';
								|it = 'Valore dell''indicatore';
								|pl = 'Wartość wskaźnika';
								|tr = 'Gösterge değeri'");
	FilterByProductsGroups = Recorder.FilterByProductsGroups.Count() > 0;
	
	If Attributes.AllocationBase = Enums.TypesOfCostAllocatingBase.MaterialCostsAmount Then 
		
		PositionPresentation    = "";
		IndicatorPresentation = NStr("vi = 'Giá trị';
									|ru = 'Стоимость';
									|en = 'Cost'; fa = 'بهای تمام‌شده';
									|it = 'Costo';
									|pl = 'Wartość';
									|tr = 'Maliyet'");
		RulePresentation    = NStr("vi = 'Tỷ lệ với chi phí nguyên vật liệu %1';
									|ru = 'Пропорционально стоимости материальных затрат %1';
									|en = 'Proportionally to value of material costs %1'; fa = 'Proportionally to value of material costs %1';
									|it = 'Proporzionale ai costi materiali %1';
									|pl = 'Proporcjonalnie do wartości materialnych kosztów %1';
									|tr = 'Malzeme giderleri değeri ile orantılı %1'");
		
	ElsIf Attributes.AllocationBase = Enums.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials Then
		
		PositionPresentation    = NStr("vi = 'Nguyên vật liệu';
										|ru = 'Материалы';
										|en = 'Materials'; fa = 'مواد';
										|it = 'Materiali';
										|pl = 'Materiały';
										|tr = 'Malzemeler'");
		IndicatorPresentation = NStr("vi = 'Số lượng';
									|ru = 'Количество';
									|en = 'Quantity'; fa = 'مقدار';
									|it = 'Quantità';
									|pl = 'Ilość';
									|tr = 'Miktar'");
		RulePresentation    = NStr("vi = 'Tỷ lệ với số lượng vật liệu quy định%1';
									|ru = 'Пропорционально количеству указанных материалов %1';
									|en = 'Proportionally to quantity of specified materials %1'; fa = 'Proportionally to quantity of specified materials %1';
									|it = 'Proporzionale alla quantità dei materiali indicati %1';
									|pl = 'Proporcjonalnie do ilości podanych materiałów %1';
									|tr = 'Belirtilen malzeme miktarı ile orantılı %1'");
		
	ElsIf Attributes.AllocationBase = Enums.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials Then
		
		PositionPresentation    = NStr("vi = 'Nguyên vật liệu';
										|ru = 'Материалы';
										|en = 'Materials'; fa = 'مواد';
										|it = 'Materiali';
										|pl = 'Materiały';
										|tr = 'Malzemeler'");
		IndicatorPresentation = NStr("vi = 'Khối lượng';
									|ru = 'Объем';
									|en = 'Volume'; fa = 'حجم';
									|it = 'Volume';
									|pl = 'Objętość';
									|tr = 'Hacim'");
		RulePresentation    = NStr("vi = 'Tỷ lệ với khối lượng của các vật liệu này%1';
									|ru = 'Пропорционально объему указанных материалов %1';
									|en = 'Proportionally to volume of specified materials %1'; fa = 'Proportionally to volume of specified materials %1';
									|it = 'Proporzionale al volume dei materiali indicati %1';
									|pl = 'Proporcjonalnie do wolumenu podanych materiałów %1';
									|tr = 'Belirtilen malzeme hacmi ile orantılı %1'");
		
	ElsIf Attributes.AllocationBase = Enums.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials Then
		
		PositionPresentation    = NStr("vi = 'Nguyên vật liệu';
										|ru = 'Материалы';
										|en = 'Materials'; fa = 'مواد';
										|it = 'Materiali';
										|pl = 'Materiały';
										|tr = 'Malzemeler'");
		IndicatorPresentation = NStr("vi = 'Tỷ trọng';
									|ru = 'Вес';
									|en = 'Weight'; fa = 'وزن';
									|it = 'Peso';
									|pl = 'Waga';
									|tr = 'Ağırlık'");
		RulePresentation    = NStr("vi = 'Tỷ lệ với trọng lượng của các vật liệu này %1';
									|ru = 'Пропорционально весу указанных материалов %1';
									|en = 'Proportionally to weight of specified materials %1'; fa = 'Proportionally to weight of specified materials %1';
									|it = 'Proporzionale al peso dei materiali indicati %1';
									|pl = 'W stosunku do wagi określonych materiałów %1';
									|tr = 'Belirtilen malzeme ağırlığı ile orantılı %1'");
		
	ElsIf Attributes.AllocationBase = Enums.TypesOfCostAllocatingBase.TotalPayrollExpenses Then
		
		PositionPresentation    = "";
		IndicatorPresentation = NStr("vi = 'Giá trị';
									|ru = 'Стоимость';
									|en = 'Cost'; fa = 'بهای تمام‌شده';
									|it = 'Costo';
									|pl = 'Wartość';
									|tr = 'Maliyet'");
		RulePresentation    = NStr("vi = 'Tỷ lệ với chi phí lao động %1';
									|ru = 'Пропорционально сумме расходов на оплату труда %1';
									|en = 'In proportion to payroll expenses %1'; fa = 'In proportion to payroll expenses %1';
									|it = 'Proporzionale all''importo delle spese per il pagamento stipendi %1';
									|pl = 'Proporcjonalnie do wysokości kosztów pracy %1';
									|tr = 'İşçilik giderlerinin tutarı ile orantılı %1'");
		
	ElsIf Attributes.AllocationBase = Enums.TypesOfCostAllocatingBase.StandardRemunerationLevel Then
		
		PositionPresentation    = "";
		IndicatorPresentation = NStr("vi = 'Giá trị';
									|ru = 'Стоимость';
									|en = 'Cost'; fa = 'بهای تمام‌شده';
									|it = 'Costo';
									|pl = 'Wartość';
									|tr = 'Maliyet'");
		RulePresentation    = NStr("vi = 'Tỷ lệ với chi phí lao động tiêu chuẩn%1';
									|ru = 'Пропорционально нормативной сумме расходов на оплату труда %1';
									|en = 'In proportion to standard payroll expenses %1'; fa = 'In proportion to standard payroll expenses %1';
									|it = 'Proporzionale all''importo delle spese per il pagamento stipendi standard %1';
									|pl = 'Proporcjonalnie do normatywnej sumy wydatków na wynagrodzenia %1';
									|tr = 'İşçilik giderlerinin standart tutarıyla orantılı %1'");
		
	ElsIf Attributes.AllocationBase = Enums.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds Then
		
		PositionPresentation    = NStr("vi = 'Dạng công việc';
										|ru = 'Виды работ';
										|en = 'Activity kinds'; fa = 'انواع فعالیت';
										|it = 'Tipi di lavori';
										|pl = 'Rodzaje prac';
										|tr = 'İş türleri'");
		IndicatorPresentation = NStr("vi = 'Số lượng';
									|ru = 'Количество';
									|en = 'Quantity'; fa = 'مقدار';
									|it = 'Quantità';
									|pl = 'Ilość';
									|tr = 'Miktar'");
		RulePresentation    = NStr("vi = 'Tỷ lệ với số loại công việc được chỉ định%1';
									|ru = 'Пропорционально количеству указанных видов работ %1';
									|en = 'Proportionally to quantity of specified activity kinds %1'; fa = 'Proportionally to quantity of specified activity kinds %1';
									|it = 'Proporzionale al numero dei tipi di lavori indicati %1';
									|pl = 'Proporcjonalnie do ilości określonych rodzajów prac %1';
									|tr = 'Belirtilen iş türlerinin miktarıyla orantılı %1'");
		
	ElsIf Attributes.AllocationBase = Enums.TypesOfCostAllocatingBase.TargetProductCost Then
		
		PositionPresentation    = NStr("vi = 'Sản phẩm';
										|ru = 'Продукция';
										|en = 'Manufactured products'; fa = 'محصولات تولیدی';
										|it = 'Prodotti';
										|pl = 'Wiersze pozycji';
										|tr = 'İmal edilen ürünler'");
		IndicatorPresentation = NStr("vi = 'Giá trị';
									|ru = 'Стоимость';
									|en = 'Cost'; fa = 'بهای تمام‌شده';
									|it = 'Costo';
									|pl = 'Wartość';
									|tr = 'Maliyet'");
		RulePresentation    = NStr("vi = 'Tỷ lệ với chi phí sản xuất theo kế hoạch%1';
									|ru = 'Пропорционально плановой стоимости продукции %1';
									|en = 'Proportionally to standard product cost %1'; fa = 'Proportionally to standard product cost %1';
									|it = 'Proporzionale al costo obiettivo dei prodotti %1';
									|pl = 'Proporcjonalnie do planowanych kosztów produkcji %1';
									|tr = 'Planlanan standart imal edilen ürün maliyeti ile orantılı %1'");
		
	ElsIf Attributes.AllocationBase = Enums.TypesOfCostAllocatingBase.ProductsQuantity Then
		
		PositionPresentation    = NStr("vi = 'Sản phẩm';
										|ru = 'Продукция';
										|en = 'Manufactured products'; fa = 'محصولات تولیدی';
										|it = 'Prodotti';
										|pl = 'Wiersze pozycji';
										|tr = 'İmal edilen ürünler'");
		IndicatorPresentation = NStr("vi = 'Số lượng';
									|ru = 'Количество';
									|en = 'Quantity'; fa = 'مقدار';
									|it = 'Quantità';
									|pl = 'Ilość';
									|tr = 'Miktar'");
		RulePresentation    = NStr("vi = 'Tỷ lệ với số lượng sản phẩm%1';
									|ru = 'Пропорционально количеству продукции %1';
									|en = 'Proportionally to product quantity %1'; fa = 'Proportionally to product quantity %1';
									|it = 'Proporzionale alla quantità di prodotti %1';
									|pl = 'Proporcjonalnie do ilości produkcji %1';
									|tr = 'İmal edilen ürün miktarıyla orantılı %1'");
		
	ElsIf Attributes.AllocationBase = Enums.TypesOfCostAllocatingBase.ProductsVolume Then
		
		PositionPresentation    = NStr("vi = 'Sản phẩm';
										|ru = 'Продукция';
										|en = 'Manufactured products'; fa = 'محصولات تولیدی';
										|it = 'Prodotti';
										|pl = 'Wiersze pozycji';
										|tr = 'İmal edilen ürünler'");
		IndicatorPresentation = NStr("vi = 'Khối lượng';
									|ru = 'Объем';
									|en = 'Volume'; fa = 'حجم';
									|it = 'Volume';
									|pl = 'Objętość';
									|tr = 'Hacim'");
		RulePresentation    = NStr("vi = 'Tỷ lệ với khối lượng sản xuất%1';
									|ru = 'Пропорционально объему продукции %1';
									|en = 'In proportion to product volume %1'; fa = 'In proportion to product volume %1';
									|it = 'Proporzionale al volume di produzione %1';
									|pl = 'Proporcjonalnie do wolumenu produkcji %1';
									|tr = 'İmal edilen ürün hacmiyle orantılı %1'");
		
	ElsIf Attributes.AllocationBase = Enums.TypesOfCostAllocatingBase.ProductsWeight Then
		
		PositionPresentation    = NStr("vi = 'Sản phẩm';
										|ru = 'Продукция';
										|en = 'Manufactured products'; fa = 'محصولات تولیدی';
										|it = 'Prodotti';
										|pl = 'Wiersze pozycji';
										|tr = 'İmal edilen ürünler'");
		IndicatorPresentation = NStr("vi = 'Tỷ trọng';
									|ru = 'Вес';
									|en = 'Weight'; fa = 'وزن';
									|it = 'Peso';
									|pl = 'Waga';
									|tr = 'Ağırlık'");
		RulePresentation    = NStr("vi = 'Tỷ lệ với trọng lượng của sản phẩm%1';
									|ru = 'Пропорционально весу продукции %1';
									|en = 'Proportionally to product weight %1'; fa = 'Proportionally to product weight %1';
									|it = 'Proporzionale al peso dei prodotti %1';
									|pl = 'Proporcjonalnie do wagi produkcji %1';
									|tr = 'İmal edilen ürün ağırlığıyla orantılı %1'");
		
	EndIf;
	
	If FilterByProductsGroups Then
		RulePresentation = StrTemplate(RulePresentation, NStr("vi = 'để nhóm sản phẩm được chọn';
																|ru = 'на выбранные группы продукции';
																|en = 'on the selected item groups'; fa = 'on the selected item groups';
																|it = 'per gruppi dei prodotti selezionati';
																|pl = 'w wybranych grupach produktów';
																|tr = 'seçilen imal edilen ürün gruplarına'"));
	Else
		RulePresentation = StrTemplate(RulePresentation, "");
	EndIf;
	
	Area = SpreadsheetDocument.FindText("%2"); // PresentationOfDistributionRule
	If Area <> Undefined Then
		Area.Text = StrReplace(Area.Text, "%2", RulePresentation);
	EndIf;
	
	Area = SpreadsheetDocument.FindText("%PositionPresentation%");
	If Area <> Undefined Then
		Area.Text = PositionPresentation;
	EndIf;
	
	Area = SpreadsheetDocument.FindText("%IndicatorName%");
	If TypeOf(Area) <> Type("Undefined") Then
		Area.Text = IndicatorPresentation;
	EndIf;
	
	Area = SpreadsheetDocument.FindText("%PresentationOfPositionInRow%");
	While Area <> Undefined Do
		
		If PositionPresentation = NStr("vi = 'Sản phẩm';
										|ru = 'Продукция';
										|en = 'Manufactured products'; fa = 'محصولات تولیدی';
										|it = 'Prodotti';
										|pl = 'Wiersze pozycji';
										|tr = 'İmal edilen ürünler'") Then
			PresentationOfPositionInRow = NStr("vi = '<sản phẩm khác>';
												|ru = '<другая продукция>';
												|en = '<other products>'; fa = '<other products>';
												|it = '<altri prodotti>';
												|pl = '<inne wiersze pozycji>';
												|tr = '<diğer imal edilen ürünler>'");
		Else
			PresentationOfPositionInRow = StrTemplate(NStr("vi = '<khác %1>';
															|ru = '<другие %1>';
															|en = '<other %1>'; fa = '<other %1>';
															|it = '<altri%1>';
															|pl = '<inne %1>';
															|tr = '<diğer %1>'"), Lower(PositionPresentation));
		EndIf;
		
		Area.Text = StrReplace(Area.Text, "%PresentationOfPositionInRow%", PresentationOfPositionInRow);;
		Area = SpreadsheetDocument.FindText("%PresentationOfPositionInRow%");
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf

