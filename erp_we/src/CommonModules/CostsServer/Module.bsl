////////////////////////////////////////////////////////////////////////////////
//
// Cost Server: Distribution of production costs and work-in-progress costs.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// The procedure checks the document date for compliance with the date of transition to batch accounting version 2.2.
// the Check is performed for documents of new production.
//
// Parameters:
//	Object - DocumentObject.ProductionStage2_2, DocumentObject.MovementOfProductsAndMaterials - document being checked,
//	Date - Date - date on which the check is performed,
//	Cancel - Boolean - set to TRUE if the date of transition to the new batch accounting is greater than the transmitted date.
//
Procedure CheckUseOfBatchAccounting22(Object, Date, Cancel) Export
	
	If Not ValueIsFilled(Date) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("BaseVersion")
		And (Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		Or Object.BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense
		Or Object.BusinessOperation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor) Then
		Return;
	EndIf;
	
	DateOfMigrationToBatchAccounting22 = CalculationOfCostCached.DateOfMigrationToBatchAccounting22();
	
	ErrorText = Undefined;
	
	If Not CalculationOfCostCached.BatchAccountingVersion22() Then
		
		ErrorText = NStr("vi = 'Đối với các hoạt động có sẵn từ phiên bản 2.2, cần thiết lập chế độ tương ứng ghi nhận lô hàng.';
						|ru = 'Для операций, доступных с версии 2.2, требуется установить соответствующий режим партионного учета.';
						|en = 'For operations available from version 2.2, set a corresponding lot accounting mode.'; fa = 'For operations available from version 2.2, set a corresponding lot accounting mode.';
						|it = 'Per le operazioni disponibili nella versione 2.2 è richiesta l''installazione della corrispondente modalità di contabilità per lotti';
						|pl = 'Dla operacji, dostępnych w wersji 2.2, należy ustawić odpowiedni tryb ewidencji partii.';
						|tr = 'Sürüm 2.2''den itibaren erişilebilen işlemler, uygun lot muhasebesi modunun ayarlanmasını gerektirir.'");
		
	ElsIf DateOfMigrationToBatchAccounting22 > BegOfMonth(Date) Then
		
		ErrorText = NStr("vi = 'Không thể ghi nhận các giao dịch có sẵn từ phiên bản 2.2 sớm hơn ngày chuyển sang kế toán theo lô của phiên bản 2.2.
								|Cần thay đổi ngày giao dịch (%1) hoặc ngày chuyển sang kế toán theo lô 2.2 (%2).';
								|ru = 'Регистрация операций, доступных с версии 2.2, раньше даты перехода на партионный учет версии 2.2 недоступна.
								|Требуется изменить дату операции (%1) или дату перехода на партионный учет 2.2 (%2).';
								|en = 'Cannot register transactions available from version 2.2 earlier than date of transfer to lot accounting of version 2.2.
								|Change transaction date (%1) or date of migration to lot accounting 2.2 (%2).'; fa = 'Cannot register transactions available from version 2.2 earlier than date of transfer to lot accounting of version 2.2.
								|Change transaction date (%1) or date of migration to lot accounting 2.2 (%2).';
								|it = 'Registrazione non disponibile delle operazioni accessibili nella versione 2.2 precedenti alla data del passaggio alla contabilità per lotti della versione 2.2.
								| Necessaria modifica della data dell''operazione (%1) o della data del passaggio alla contabilità per lotti 2.2 (%2).';
								|pl = 'Rejestracja operacji, dostępnych z wersji 2.2, wcześniej od daty przejścia do ewidencji partii wersji 2.2 jest niedostępna.
								|Należy zmienić datę operacji (%1) lub datę przejścia do ewidencji partii 2.2 (%2).';
								|tr = 'Sürüm 2.2''den beri erişilebilir olan işlemlerin kaydı, lot muhasebesi sürüm 2.2''ye geçiş tarihinden önce mümkün değildir.
								|İşlem tarihini (%1) veya lot muhasebesi 2.2''ye (%2) geçiş tarihinin değiştirilmesi gerekir.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorText,
			Format(Date, "DLF=D"),
			Format(DateOfMigrationToBatchAccounting22, "DLF=D"));
			
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		CommonClientServer.MessageToUser(ErrorText, Object,,, Cancel);
	EndIf;
	
EndProcedure

// Sets the selection parameters for the distribution rule depending on the method of accounting for production costs.
//
// Parameters:
//	Department - CatalogRef.BusinessStructure - the division where the distribution is performed
//	AllocationOption - EnumRef.MethodsOfExpenseItemAllocations - distribution option
//	ElementDistributionRule - FormField - Field for entering the distribution rule
//	Purpose - CatalogRef.Assignments - The purpose of the expense.
//
Procedure ConfigureParametersForSelectingDistributionRules(Department, AllocationOption, ElementDistributionRule, Purpose) Export
	
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameter("Filter.AssignRule", Purpose));
	
	If ValueIsFilled(Department)
		And (AllocationOption = Enums.MethodsOfExpenseItemAllocations.ByStagesAccToRuleInBusinessUnit Or AllocationOption = Undefined) Then
		
		Attributes = Common.ObjectAttributesValues(Department, "ProductionByOrders, RecordingExpensesOnProcustCostIsUsed");
		
		If Not Attributes.ProductionByOrders And Not Attributes.RecordingExpensesOnProcustCostIsUsed Then
			
			ArrayOfDistributionBases = New Array;
			ArrayOfDistributionBases.Add(Enums.TypesOfCostAllocatingBase.ProductsQuantity);
			ArrayOfDistributionBases.Add(Enums.TypesOfCostAllocatingBase.ProductsWeight);
			ArrayOfDistributionBases.Add(Enums.TypesOfCostAllocatingBase.ProductsVolume);
			ArrayOfDistributionBases.Add(Enums.TypesOfCostAllocatingBase.TargetProductCost);
			ArrayOfDistributionBases.Add(Enums.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials);
			ArrayOfDistributionBases.Add(Enums.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials);
			ArrayOfDistributionBases.Add(Enums.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials);
			ArrayOfDistributionBases.Add(Enums.TypesOfCostAllocatingBase.StandardMaterialConsumption);
			ArrayOfDistributionBases.Add(Enums.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds);
			
			ParametersArray.Add(New ChoiceParameter("Filter.AllocationBase", New FixedArray(ArrayOfDistributionBases)));
			
		EndIf;
		
	EndIf;
	
	ElementDistributionRule.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

// This function generates a table of completed production stages.
//
// Parameters:
//	Parameters - Structure - Structure of transmitted parameters:
//		* BeginOfPeriod - Date - the beginning of the period of analysis of production stages.
//		* PeriodEnding - Date - end of the production stage analysis period.
//		* Department - CatalogRef.BusinessStructure - selection by division.
//		* Purpose - CatalogRef.Assignments - selection by appointment.
//		* ProductsGroup - CatalogRef.AnalyticalInventoryGroups - selection by product group.
//		* CurMonthOnly - Boolean - indicates the receipt of stages that were performed only in the transferred period.
//		* OrderDocument - DocumentRef.ProductionOrder2_2 - selection by production order.
//		* ExcludeProductionByThirdParties - Boolean - don't show the stages that are running on the side.
//
// Returns:
//	ValueTable - table of production stages.
//
Function ProductionStepsForCostAllocation(Parameters) Export
	
	Query = New Query("
	|
	|SELECT DISTINCT
	|	DD.ReferenceOrder.ReferenceOrder AS ProductionOrder,
	|	DD.ReferenceOrder.RowCode AS RowCode
	|INTO TTProductReleases
	|FROM
	|	AccumulationRegister.ProductsRelease.Turnovers(&PeriodBeginning, &PeriodEnd) AS DD
	|WHERE
	|	&BatchAccountingVersion22
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Orders.PurchaseOrder AS ProductionOrder,
	|	Orders.RowCode AS RowCodeProducts,
	|	UNDEFINED AS Stage,
	|	UNDEFINED AS BillOfMaterials,
	|	0 AS PlannedByOrder,
	|	0 AS Completed2
	|FROM
	|	AccumulationRegister.PurchaseOrders AS Orders
	|WHERE
	|	FALSE
	|
	|GROUP BY
	|
	|	Orders.PurchaseOrder,
	|	Orders.RowCode


	|
	|ORDER BY
	|	ProductionOrder");
	
	Purpose = Undefined;
	LineOfBusiness = Undefined;
	Department = Undefined;
	ProductsGroup = Undefined;
	OrderDocument = Undefined;
	Parameters.Property("Purpose", Purpose);
	Parameters.Property("LineOfBusiness", LineOfBusiness);
	Parameters.Property("Department", Department);
	Parameters.Property("ProductsGroup", ProductsGroup);
	Parameters.Property("OrderDocument", OrderDocument);
	
	Query.SetParameter("PeriodBeginning",	 Parameters.PeriodBeginning);
	Query.SetParameter("PeriodEnd", Parameters.PeriodEnd);
	Query.SetParameter("Organization",     Parameters.Organization);
	Query.SetParameter("Purpose",       Purpose);
	Query.SetParameter("ForAllAppointments", Not ValueIsFilled(Purpose));
	Query.SetParameter("LineOfBusiness",        LineOfBusiness);
	Query.SetParameter("InAllAreasOfActivity", Not ValueIsFilled(LineOfBusiness));
	Query.SetParameter("Department", Department);
	Query.SetParameter("ByAllBusinessUnits", Not ValueIsFilled(Department));
	Query.SetParameter("OrderDocument", OrderDocument);
	Query.SetParameter("ForAllOrders", Not ValueIsFilled(OrderDocument));
	Query.SetParameter("ProductsGroup", ProductsGroup);
	Query.SetParameter("ForAllProductGroups", Not ValueIsFilled(ProductsGroup));
	Query.SetParameter("NotCurMonthOnly", Not Parameters.CurMonthOnly);
	Query.SetParameter("BatchAccountingVersion22", Parameters.BatchAccountingVersion22);
	
	Return Query.Execute().Unload();
	
EndFunction


// This function generates a table of production batches.
//
// Parameters:
//	Filters - Structure - Structure of transmitted parameters:
//		* BeginOfPeriod - Date - the beginning of the period of analysis of production stages.
//		* PeriodEnding - Date - end of the production stage analysis period.
//		* Organization - CatalogRef.Companies, Array of CatalogRef.Companies - selection by organization. May be missing.
//		* LineOfBusiness - CatalogRef.LinesOfBusiness - selection by field of activity. May be missing.
//		* Department - CatalogRef.BusinessStructure - selection by division. May be missing.
//		* Purpose - CatalogRef.Assignments - selection by appointment. May be missing.
//		* CurMonthOnly - Boolean - indicates the receipt of stages that were performed only in the transferred period.
//		* DetailByStages - Boolean - detail by intermediate stages or by products. May be missing.
//		* ProductionOrder - DocumentRef.ProductionOrder2_2 - selection by production order. May be missing.
//		* ExcludeProductionByThirdParties - Boolean - don't show the stages that are running on the side. May be missing.
//
// Returns:
//	ValueTable - production batch table.
//
Function ProductionBatchesForCostSharing(Filters) Export
	
	TempTablesManager = New TempTablesManager;
	
	Organization = Undefined;
	Filters.Property("Organization", Organization);
	QueryOptions = DescriptionOfParametersForReceivingActiveBatchesWithoutSpecifications();
	FillPropertyValues(QueryOptions, Filters);
	
	If ValueIsFilled(Organization) Then
		QueryOptions.Companies = TMCommonUseClientServer.Array(Organization);
	EndIf;
	
	FormActiveBatchesWithoutSpecifications(QueryOptions, TempTablesManager);
	QueryTexts = New Array;
	// Stages of the current period.
	QueryTexts.Add(
	"SELECT
	|	Attributes.Organization           AS Organization,
	|	Attributes.Stage                  AS Stage,
	|	Attributes.Department         AS Department,
	|	Attributes.ProductionLot    AS ProductionLot,
	|	Attributes.ProductionProcessType AS ProductionProcessType,
	|	Attributes.InternalSubcontracting AS InternalSubcontracting,
	|	Attributes.MaterialProvider               AS MaterialProvider
	|INTO StagesOfCurPeriod
	|FROM
	|	(SELECT
	|		Attributes.Organization           AS Organization,
	|		Attributes.Ref                AS Stage,
	|		Attributes.Department         AS Department,
	|		Attributes.ProductionLot    AS ProductionLot,
	|		Attributes.ProductionProcessType AS ProductionProcessType,
	|		Attributes.InternalSubcontracting AS InternalSubcontracting,
	|		Attributes.MaterialProviderCompany    AS MaterialProvider
	|	FROM
	|		Document.ProductionStage2_2 AS Attributes
	|	WHERE
	|		(&ByAllCompanies
	|			OR Attributes.Organization IN(&Organization))
	|		AND Attributes.Posted
	|		AND (Attributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
	|				AND Attributes.ActualStageStart <= &PeriodEnding
	|			OR Attributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|				AND Attributes.ActualStageEnd >= &BeginOfPeriod)
	|
	|		AND (&AllDepartments OR Attributes.Department = &Department)
	|		AND (&AllProductionOrders OR Attributes.ReferenceOrder = &ProductionOrder)
	|		AND (&StagesForEntirePeriod
	|			OR Attributes.ActualStageStart <= &PeriodEnding
	|				AND (Attributes.ActualStageEnd = DATETIME(1, 1, 1) 
	|					OR Attributes.ActualStageEnd >= &BeginOfPeriod)
	|			OR Attributes.ProductionByThirdParty
	|			)
	|		AND (&AllAssignments OR Attributes.ProductionLot.Purpose = &Purpose)
	|		AND (&AllAreasOfActivity OR Attributes.ProductionLot.LineOfBusiness = &LineOfBusiness)
	|		AND (NOT &ExcludeProductionByThirdParties OR NOT Attributes.ProductionByThirdParty)
	|		AND (NOT &InternalSubcontracting OR Attributes.InternalSubcontracting)
	|		AND (&AllGivers OR Attributes.MaterialProviderCompany = &MaterialProvider)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Attributes.MaterialProviderCompany    AS Organization,
	|		Attributes.Ref                AS Stage,
	|		Attributes.Department         AS Department,
	|		Attributes.ProductionLot    AS ProductionLot,
	|		Attributes.ProductionProcessType AS ProductionProcessType,
	|		Attributes.InternalSubcontracting AS InternalSubcontracting,
	|		Attributes.MaterialProviderCompany    AS MaterialProvider
	|	FROM
	|		Document.ProductionStage2_2 AS Attributes
	|	WHERE
	|		Attributes.InternalSubcontracting
	|		AND (&ByAllCompanies
	|			OR Attributes.MaterialProviderCompany IN(&Organization))
	|		AND Attributes.Posted
	|		AND (Attributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
	|				AND Attributes.ActualStageStart <= &PeriodEnding
	|			OR Attributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|				AND Attributes.ActualStageEnd >= &BeginOfPeriod)
	|
	|		AND (&AllDepartments OR Attributes.Department = &Department)
	|		AND (&AllProductionOrders OR Attributes.ReferenceOrder = &ProductionOrder)
	|		AND (&StagesForEntirePeriod
	|			OR Attributes.ActualStageStart <= &PeriodEnding
	|				AND (Attributes.ActualStageEnd = DATETIME(1, 1, 1) 
	|					OR Attributes.ActualStageEnd >= &BeginOfPeriod)
	|			OR Attributes.ProductionByThirdParty
	|			)
	|		AND (&AllAssignments OR Attributes.ProductionLot.Purpose = &Purpose)
	|		AND (&AllAreasOfActivity OR Attributes.ProductionLot.LineOfBusiness = &LineOfBusiness)
	|		AND (NOT &ExcludeProductionByThirdParties OR NOT Attributes.ProductionByThirdParty)
	|		AND (NOT &InternalSubcontracting OR Attributes.InternalSubcontracting)
	|		AND (&AllGivers OR Attributes.MaterialProviderCompany = &MaterialProvider)
	|
	|	) AS Attributes
	|
	|GROUP BY
	|	Attributes.Organization,
	|	Attributes.Stage,
	|	Attributes.Department,
	|	Attributes.ProductionLot,
	|	Attributes.ProductionProcessType,
	|	Attributes.InternalSubcontracting,
	|	Attributes.MaterialProvider
	|");
	// Documents of Lot references of backflushed production.
	QueryTexts.Add(
	"SELECT ALLOWED
	|	PartyDocuments.Ref                              AS Ref,
	|	PartyDocuments.Organization                         AS Organization,
	|	PartyDocuments.Department                       AS Department,
	|	PartyDocuments.InternalSubcontracting               AS InternalSubcontracting,
	|	PartyDocuments.MaterialProviderCompany                  AS MaterialProviderCompany,
	|	PartyDocuments.Date                                AS Date,
	|	CatProductionLots.Ref                        AS ProductionLot,
	|	CatProductionLots.MainProductProducts   AS Products,
	|	CatProductionLots.MainProductCharacteristic AS Characteristic,
	|	CatProductionLots.BillOfMaterials                  AS BillOfMaterials,
	|	CatProductionLots.Purpose                    AS Purpose,
	|	CatProductionLots.Series                         AS Series,
	|	CatProductionLots.LineOfBusiness       AS LineOfBusiness
	|INTO TTDocumentsOfProductionBatchesWithoutOrder
	|FROM
	|	(SELECT
	|		DocumentAttributes.Ref            AS Ref,
	|		DocumentAttributes.Organization       AS Organization,
	|		DocumentAttributes.Department     AS Department,
	|		TableOfGoods.InternalSubcontracting AS InternalSubcontracting,
	|		TableOfGoods.MaterialProviderCompany    AS MaterialProviderCompany,
	|		DocumentAttributes.Date              AS Date,
	|		CASE
	|			WHEN DocumentAttributes.Patch
	|				AND DocumentAttributes.CorrectionSavesProductionLots
	|				THEN DocumentAttributes.CorrectedDocument
	|			ELSE DocumentAttributes.Ref
	|		END                                AS DocumentProductionLots,
	|		TableOfGoods.CostGroupNumber     AS CostGroupNumber
	|	FROM
	|		Document.BackflushProduction.ManufacturedProducts AS TableOfGoods
	|		
	|		INNER JOIN Document.BackflushProduction AS DocumentAttributes
	|		ON DocumentAttributes.Ref = TableOfGoods.Ref
	|		
	|	WHERE
	|		(&ByAllCompanies
	|			OR DocumentAttributes.Organization IN(&Organization))
	|		AND DocumentAttributes.Posted
	|		AND DocumentAttributes.Date BETWEEN &BeginOfPeriod AND ENDOFPERIOD(DATEADD(&PeriodEnding, MONTH, 1), MONTH)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentAttributes.Ref            AS Ref,
	|		TableOfGoods.MaterialProviderCompany    AS Organization,
	|
	|		DocumentAttributes.Department     AS Department,
	|		TableOfGoods.InternalSubcontracting AS InternalSubcontracting,
	|		TableOfGoods.MaterialProviderCompany    AS MaterialProviderCompany,
	|		DocumentAttributes.Date              AS Date,
	
	|		CASE
	|			WHEN DocumentAttributes.Patch
	|				AND DocumentAttributes.CorrectionSavesProductionLots
	|				THEN DocumentAttributes.CorrectedDocument
	|			ELSE DocumentAttributes.Ref
	|		END                                AS DocumentProductionLots,
	|		TableOfGoods.CostGroupNumber     AS CostGroupNumber
	|	FROM
	|		Document.BackflushProduction.ManufacturedProducts AS TableOfGoods
	|		
	|		INNER JOIN Document.BackflushProduction AS DocumentAttributes
	|		ON DocumentAttributes.Ref = TableOfGoods.Ref
	|		
	|	WHERE
	|		TableOfGoods.InternalSubcontracting
	|		AND (&ByAllCompanies
	|			OR TableOfGoods.MaterialProviderCompany IN(&Organization))
	|		AND DocumentAttributes.Posted
	|		AND DocumentAttributes.Date BETWEEN &BeginOfPeriod AND ENDOFPERIOD(DATEADD(&PeriodEnding, MONTH, 1), MONTH)
	|	) AS PartyDocuments
	|	
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = PartyDocuments.DocumentProductionLots
	|	AND CatProductionLots.Code = PartyDocuments.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	ON DocumentsRegistry.ReversedDocument = PartyDocuments.Ref
	|	AND DocumentsRegistry.IBDocumentDate BETWEEN BEGINOFPERIOD(PartyDocuments.Date, MONTH) AND ENDOFPERIOD(PartyDocuments.Date, MONTH)
	|	AND DocumentsRegistry.Posted
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	DocumentsRegistry.Ref IS NULL
	|	AND &AllProductionOrders
	|	AND (&AllDepartments OR PartyDocuments.Department = &Department)
	|	AND (&StagesForEntirePeriod OR PartyDocuments.Date BETWEEN &BeginOfPeriod AND &PeriodEnding)
	|	AND (&AllAssignments OR CatProductionLots.Purpose = &Purpose)
	|	AND (&AllAreasOfActivity OR CatProductionLots.LineOfBusiness = &LineOfBusiness)
	|	AND (NOT &InternalSubcontracting OR PartyDocuments.InternalSubcontracting)
	|	AND (&AllGivers OR PartyDocuments.MaterialProviderCompany = &MaterialProvider)
	|
	|GROUP BY
	|	PartyDocuments.Ref,
	|	PartyDocuments.Organization,
	|	PartyDocuments.Department,
	|	PartyDocuments.InternalSubcontracting,
	|	PartyDocuments.MaterialProviderCompany,
	|	PartyDocuments.Date,
	|	CatProductionLots.Ref,
	|	CatProductionLots.MainProductProducts,
	|	CatProductionLots.MainProductCharacteristic,
	|	CatProductionLots.BillOfMaterials,
	|	CatProductionLots.Purpose,
	|	CatProductionLots.Series,
	|	CatProductionLots.LineOfBusiness
	|
	|INDEX BY
	|	Ref
	|");
	
	QueryTexts.Add(
	"
	// Batch Production Without Order
	|SELECT ALLOWED
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.ProductionLot      AS ProductionLot,
	|	DocumentData.Department           AS Department,
	|	DocumentData.Ref                  AS Stage,
	|	DocumentData.Products            AS Products,
	|	DocumentData.Characteristic          AS Characteristic,
	|	DocumentData.BillOfMaterials            AS BillOfMaterials,
	|	DocumentData.Purpose              AS Purpose,
	|	DocumentData.Series                   AS Series,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                            AS ProductionOrder,
	|	DocumentData.Date BETWEEN &BeginOfPeriod AND &PeriodEnding AS CurMonthStage,
	|	DocumentData.InternalSubcontracting   AS InternalSubcontracting,
	|	DocumentData.MaterialProviderCompany      AS MaterialProvider,
	|	FALSE                                    AS ProductionByThirdParty
	|INTO TTStages
	|FROM
	|	TTDocumentsOfProductionBatchesWithoutOrder AS DocumentData
	|
	|UNION ALL
	|
	// Batch production on orders without specifications, including internal processing on behalf of the giver
	|SELECT
	|	ActiveBatchesWithoutSpecifications.Organization           AS Organization,
	|	ActiveBatchesWithoutSpecifications.ProductionLot    AS ProductionLot,
	|	ISNULL(Stages.Department, ProductionOrder.Department) AS Department,
	|	CASE
	|		WHEN &DetailByStages
	|			THEN ISNULL(Stages.Stage, UNDEFINED)
	|		ELSE UNDEFINED
	|	END                                               AS Stage,
	|	CatProductionLots.MainProductProducts   AS Products,
	|	CatProductionLots.MainProductCharacteristic AS Characteristic,
	|	CatProductionLots.BillOfMaterials                  AS BillOfMaterials,
	|	CatProductionLots.Purpose                    AS Purpose,
	|	CatProductionLots.Series                         AS Series,
	|	CatProductionLots.LineOfBusiness       AS LineOfBusiness,
	|	ProductionOrder.Ref                          AS ProductionOrder,
	|	TRUE                                              AS CurMonthStage,
	|	ActiveBatchesWithoutSpecifications.InternalSubcontracting AS InternalSubcontracting,
	|	ActiveBatchesWithoutSpecifications.MaterialProvider               AS MaterialProvider,
	|	FALSE                                                AS ProductionByThirdParty
	|FROM
	|	ActiveBatchesWithoutSpecifications AS ActiveBatchesWithoutSpecifications
	|	
	|	INNER JOIN Document.ProductionOrder2_2 AS ProductionOrder
	|	ON ActiveBatchesWithoutSpecifications.ProductionLot = ProductionOrder.ProductionLot
	|	
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Ref = ActiveBatchesWithoutSpecifications.ProductionLot
	|	
	|	LEFT JOIN StagesOfCurPeriod AS Stages
	|	ON Stages.ProductionLot = ActiveBatchesWithoutSpecifications.ProductionLot
	|	AND Stages.Organization = ActiveBatchesWithoutSpecifications.Organization
	|	AND Stages.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
	|
	|WHERE
	|	(&AllDepartments OR ISNULL(Stages.Department, ProductionOrder.Department) = &Department)
	|	AND (&AllProductionOrders OR ProductionOrder.Ref = &ProductionOrder)
	|	AND (&AllAssignments OR CatProductionLots.Purpose = &Purpose)
	|	AND (&AllAreasOfActivity OR CatProductionLots.LineOfBusiness = &LineOfBusiness)
	|	AND (NOT &InternalSubcontracting OR ActiveBatchesWithoutSpecifications.InternalSubcontracting)
	|	AND (&AllGivers OR ActiveBatchesWithoutSpecifications.MaterialProvider = &MaterialProvider)
	|
	|UNION ALL
	|
	// Batch production by order, including internal processing on behalf of the giver
	|SELECT
	|	StagesOfCurPeriod.Organization           AS Organization,
	|	PPDetails.Ref                         AS ProductionLot,
	|	Attributes.Department                    AS Department,
	|	CASE
	|		WHEN &DetailByStages
	|			THEN Attributes.Ref
	|		ELSE UNDEFINED
	|	END                                      AS Stage,
	|	PPDetails.MainProductProducts    AS Products,
	|	PPDetails.MainProductCharacteristic  AS Characteristic,
	|	PPDetails.BillOfMaterials                   AS BillOfMaterials,
	|	PPDetails.Purpose                     AS Purpose,
	|	PPDetails.Series                          AS Series,
	|	PPDetails.LineOfBusiness        AS LineOfBusiness,
	|	Attributes.ReferenceOrder                     AS ProductionOrder,
	|	Attributes.ActualStageStart <= &PeriodEnding
	|			AND Attributes.ActualStageEnd = DATETIME(1, 1, 1)
	|		OR Attributes.ActualStageStart >= &BeginOfPeriod
	|			AND Attributes.ActualStageEnd <= &PeriodEnding
	|			AND Attributes.ActualStageEnd <> DATETIME(1, 1, 1)
	|		OR Attributes.ProductionByThirdParty    AS CurMonthStage,
	|	StagesOfCurPeriod.InternalSubcontracting AS InternalSubcontracting,
	|	StagesOfCurPeriod.MaterialProvider               AS MaterialProvider,
	|	Attributes.ProductionByThirdParty            AS ProductionByThirdParty
	|FROM
	|	StagesOfCurPeriod AS StagesOfCurPeriod
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS Attributes
	|	ON StagesOfCurPeriod.Stage = Attributes.Ref
	|	
	|	INNER JOIN Catalog.ProductionLots AS PPDetails
	|	ON PPDetails.Ref = Attributes.ProductionLot
	|WHERE
	|	NOT StagesOfCurPeriod.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
	|
	|
	|UNION ALL
	|
	|SELECT
	|	Attributes.Organization								AS Organization,
	|	CatProductionLots.Ref						AS ProductionLot,
	|	Attributes.Department								AS Department,
	|	Attributes.Ref									AS Stage,
	|	CatProductionLots.MainProductProducts	AS Products,
	|	CatProductionLots.MainProductCharacteristic	AS Characteristic,
	|	CatProductionLots.BillOfMaterials					AS BillOfMaterials,
	|	CatProductionLots.Purpose					AS Purpose,
	|	CatProductionLots.Series							AS Series,
	|	CatProductionLots.LineOfBusiness		AS LineOfBusiness,
	|	UNDEFINED										AS ProductionOrder,
	|	TRUE												AS CurMonthStage,
	|	CatProductionLots.InternalSubcontracting			AS InternalSubcontracting,
	|	VALUE(Catalog.Companies.EmptyRef)		AS MaterialProvider,
	|	TRUE												AS ProductionByThirdParty
	|FROM
	|	Document.SubcontractorReport2_5 AS Attributes
	|	
	|	INNER JOIN Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|	ON Attributes.Ref = GoodsTable.Ref
	|	
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = GoodsTable.Ref
	|	AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|
	|WHERE
	|	(&ByAllCompanies
	|		OR Attributes.Organization IN(&Organization))
	|	AND Attributes.Posted
	|	AND Attributes.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|	AND Attributes.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND &AllProductionOrders
	|	AND (&AllDepartments OR Attributes.Department = &Department)
	|	AND (&AllAssignments OR CatProductionLots.Purpose = &Purpose)
	|	AND (&AllAreasOfActivity OR CatProductionLots.LineOfBusiness = &LineOfBusiness)
	|	AND (NOT &ExcludeProductionByThirdParties)
	|	AND (NOT &InternalSubcontracting OR CatProductionLots.InternalSubcontracting)
	|	AND (&AllGivers OR &MaterialProvider = VALUE(Catalog.Companies.EmptyRef))
	|
	|GROUP BY
	|	Attributes.Ref,
	|	CatProductionLots.Ref,
	|	CatProductionLots.Products,
	|	CatProductionLots.Characteristic,
	|	CatProductionLots.BillOfMaterials,
	|	CatProductionLots.Purpose,
	|	CatProductionLots.Series,
	|	CatProductionLots.InternalSubcontracting,
	|	CatProductionLots.LineOfBusiness
	|
	|INDEX BY
	|	CurMonthStage,
	|	Department,
	|	Purpose,
	|	LineOfBusiness
	|");
	QueryTexts.Add(Catalogs.ProductionLots.QueryTextOfProductionBatchIsInProgress("TTStages"));
	QueryTexts.Add(
	"SELECT
	|	TTStages.Organization                    AS Organization,
	|	TTStages.ProductionLot             AS ProductionLot,
	|	CASE
	|		WHEN PartiesInWork.ProductionLot IS NOT NULL
	|			THEN &TextStatusInProgress
	|		WHEN TRUE
	|			THEN &TextStatusCompleted
	|	END                                  AS Status,
	|	TTStages.Department                  AS Department,
	|	TTStages.Stage                           AS Stage,
	|	TTStages.InternalSubcontracting          AS InternalSubcontracting,
	|	TTStages.MaterialProvider                        AS MaterialProvider,
	|	TTStages.Products                   AS Products,
	|	TTStages.Characteristic                 AS Characteristic,
	|	TTStages.BillOfMaterials                   AS BillOfMaterials,
	|	TTStages.Purpose                     AS Purpose,
	|	TTStages.Series                          AS Series,
	|	TTStages.LineOfBusiness        AS LineOfBusiness,
	|	TTStages.ProductionOrder            AS ProductionOrder,
	|	TTStages.CurMonthStage             AS CurMonthStage
	|FROM
	|	TTStages AS TTStages
	|	
	|	LEFT JOIN PartiesInWork AS PartiesInWork
	|	ON PartiesInWork.ProductionLot = TTStages.ProductionLot
	|
	|GROUP BY
	|	TTStages.Organization,
	|	TTStages.Characteristic,
	|	TTStages.ProductionLot,
	|	TTStages.Stage,
	|	PartiesInWork.ProductionLot,
	|	TTStages.InternalSubcontracting,
	|	TTStages.MaterialProvider,
	|	TTStages.CurMonthStage,
	|	TTStages.BillOfMaterials,
	|	TTStages.Products,
	|	TTStages.Purpose,
	|	TTStages.Series,
	|	TTStages.LineOfBusiness,
	|	TTStages.ProductionOrder,
	|	TTStages.Department
	|");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Department       = Undefined;
	Purpose          = Undefined;
	ProductionOrder = Undefined;

	LineOfBusiness = Undefined;
	ExcludeProductionByThirdParties = Filters.Property("ExcludeProductionByThirdParties") And Filters.ExcludeProductionByThirdParties;
	
	Filters.Property("Department",           Department);
	Filters.Property("Purpose",              Purpose);

	Filters.Property("ProductionOrder",     ProductionOrder);
	Filters.Property("LineOfBusiness", LineOfBusiness);
	
	Query.SetParameter("BeginOfPeriod",                Filters.BeginOfPeriod);
	Query.SetParameter("PeriodEnding",             Filters.PeriodEnding);
	
	Query.SetParameter("Organization",                  Organization);
	Query.SetParameter("ByAllCompanies",           Not ValueIsFilled(Organization));
	
	Query.SetParameter("Department",                Department);
	Query.SetParameter("AllDepartments",             Not ValueIsFilled(Department));
	
	Query.SetParameter("Purpose",                   Purpose);
	Query.SetParameter("AllAssignments",                Not ValueIsFilled(Purpose));

	Query.SetParameter("ProductionOrder",          ProductionOrder);
	Query.SetParameter("AllProductionOrders",      Not ValueIsFilled(ProductionOrder));
	
	Query.SetParameter("LineOfBusiness",      LineOfBusiness);
	Query.SetParameter("AllAreasOfActivity",   Not ValueIsFilled(LineOfBusiness));
	
	Query.SetParameter("DetailByStages",       Filters.DetailByStages);
	Query.SetParameter("StagesForEntirePeriod",            Not Filters.CurMonthOnly);
	
	Query.SetParameter("ExcludeProductionByThirdParties", ExcludeProductionByThirdParties);
	Query.SetParameter("InternalSubcontracting", Filters.InternalSubcontracting);
	
	Query.SetParameter("MaterialProvider",               Filters.MaterialProvider);
	Query.SetParameter("AllGivers",           Not ValueIsFilled(Filters.MaterialProvider));
	Query.SetParameter("TextStatusCompleted", Catalogs.ProductionLots.StatusTextCompleted());
	Query.SetParameter("TextStatusInProgress",   Catalogs.ProductionLots.TextOfStatusInProgress());
	
	Return Query.Execute().Unload();
	
EndFunction

// Creates a temporary table of production batches with the type of production process "without specifications",
//	for which production is performed in the specified interval.
//
// Parameters:
//	QueryOptions - See CostsServer.DescriptionOfParametersForReceivingActiveBatchesWithoutSpecifications.
//	TempTablesManager - TempTablesManager - temporary table manager.
//	UpdateBatches - Boolean - get a new batch.
Procedure FormActiveBatchesWithoutSpecifications(QueryOptions, TempTablesManager, UpdateBatches = True) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager, "ActiveBatchesWithoutSpecifications") Then
		
		If Not UpdateBatches Then
			Return;
		EndIf;
		
		Query.Text =
			"DROP ActiveBatchesWithoutSpecifications";
		Query.Execute();
		
	EndIf;
	
	For Each Parameter In QueryOptions Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	
	Query.SetParameter("ByAllStandards", Not QueryOptions.Companies.Count());
	
	Query.Text = "
		// Production batches for orders for which production stages have not yet been introduced
		// or production stages have been introduced in the following periods.
		|SELECT ALLOWED
		|	ProductionLots.Organization           AS Organization,
		|	ProductionLots.ProductionLot    AS ProductionLot,
		|	ProductionLots.InternalSubcontracting AS InternalSubcontracting,
		|	ProductionLots.MaterialProvider               AS MaterialProvider
		|INTO ActiveBatchesWithoutSpecifications
		|FROM
		|	(SELECT
		|		ProductionOrder.Organization               AS Organization,
		|		ProductionOrder.ProductionLot        AS ProductionLot,
		|		FALSE                                          AS InternalSubcontracting,
		|		VALUE(Catalog.Companies.EmptyRef) AS MaterialProvider
		|	FROM
		|		Document.ProductionOrder2_2 AS ProductionOrder
		|		
		|		LEFT JOIN Document.ProductionStage2_2 AS ProductionStage
		|		ON ProductionOrder.ProductionLot = ProductionStage.ProductionLot
		|		AND ProductionStage.Posted
		|		AND ProductionStage.ActualStageStart <= &PeriodEnding
		|		AND ProductionStage.Status IN (
		|			VALUE(Enum.StatusesOfProductionStages2_2.Initiated),
		|			VALUE(Enum.StatusesOfProductionStages2_2.Completed))
		|	WHERE
		|		ProductionOrder.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
		|		AND ProductionOrder.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
		|		AND ProductionOrder.Posted
		|		AND ProductionOrder.Date <= &PeriodEnding
		|		AND (&ByAllStandards
		|			OR ProductionOrder.Organization IN (&Companies))
		|		AND ProductionStage.Ref IS NULL
		|	
		|	UNION ALL
		|	
		// Production batches for orders for which production stages have been entered.
		|	SELECT
		|		ProductionStage.Organization           AS Organization,
		|		ProductionOrder.ProductionLot AS ProductionLot,
		|		ProductionStage.InternalSubcontracting AS InternalSubcontracting,
		|		ProductionStage.MaterialProviderCompany    AS MaterialProvider
		|	FROM
		|		Document.ProductionOrder2_2 AS ProductionOrder
		|		
		|		INNER JOIN Document.ProductionStage2_2 AS ProductionStage
		|		ON ProductionOrder.ProductionLot = ProductionStage.ProductionLot
		|	WHERE
		|		(ProductionOrder.Status IN (
		|				VALUE(Enum.ProductionOrderStatuses2_2.ToProduce),
		|				VALUE(Enum.ProductionOrderStatuses2_2.Closed))
		|			AND ProductionOrder.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
		|			AND ProductionOrder.Posted)
		|		AND ProductionStage.Posted
		|		AND (&ByAllStandards
		|			OR ProductionStage.Organization IN(&Companies))
		|		AND ProductionStage.ActualStageStart <= &PeriodEnding
		|		AND (ProductionStage.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
		|			OR ProductionStage.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
		|				AND ProductionStage.ActualStageEnd >= &BeginOfPeriod)
		|	
		|	UNION ALL
		|	
		// Production batches for orders for which the stages of production of internal processing have been introduced on behalf of the giver.
		|	SELECT
		|		ProductionStage.MaterialProviderCompany    AS Organization,
		|		ProductionOrder.ProductionLot AS ProductionLot,
		|		ProductionStage.InternalSubcontracting AS InternalSubcontracting,
		|		ProductionStage.MaterialProviderCompany    AS MaterialProvider
		|	FROM
		|		Document.ProductionOrder2_2 AS ProductionOrder
		|	
		|		INNER JOIN Document.ProductionStage2_2 AS ProductionStage
		|		ON ProductionOrder.ProductionLot = ProductionStage.ProductionLot
		|	WHERE
		|		(ProductionOrder.Status IN (
		|				VALUE(Enum.ProductionOrderStatuses2_2.ToProduce),
		|				VALUE(Enum.ProductionOrderStatuses2_2.Closed))
		|			AND ProductionOrder.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
		|			AND ProductionOrder.Posted)
		|		AND ProductionStage.Posted
		|		AND (&ByAllStandards
		|			OR ProductionStage.MaterialProviderCompany IN(&Companies))
		|		AND ProductionStage.ActualStageStart <= &PeriodEnding
		|		AND (ProductionStage.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
		|			OR ProductionStage.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
		|				AND ProductionStage.ActualStageEnd >= &BeginOfPeriod)
		|	) AS ProductionLots
		|
		|GROUP BY
		|	ProductionLots.Organization,
		|	ProductionLots.ProductionLot,
		|	ProductionLots.InternalSubcontracting,
		|	ProductionLots.MaterialProvider
		|";
	
	Query.Execute();
	
EndProcedure

// Description of parameters for obtaining active production batches
//	with the "no specifications" type of production process.
//
// Returns:
//	Structure - LongDesc:
// * BeginOfPeriod - Date - 
// * PeriodEnding - Date - 
// * Companies - Array of CatalogRef.Companies - 
//
Function DescriptionOfParametersForReceivingActiveBatchesWithoutSpecifications() Export
	
	ParametersDetails = New Structure;
	ParametersDetails.Insert("BeginOfPeriod",    Date(1, 1, 1));
	ParametersDetails.Insert("PeriodEnding", Date(1, 1, 1));
	ParametersDetails.Insert("Companies",      New Array); // the value type of the element is a reference link.Organizations.
	
	Return ParametersDetails;
	
EndFunction
// The procedure fills in the characteristics of the main item in the collection for the production batch.
//
// Parameters:
//	Collection - ValueTable - Table where you need to fill in the characteristics of the main product.
//
Procedure FillInCharacteristicsOfProductsByBatchOfProduction(Collection) Export
	
	Query = New Query(
	"SELECT
	|	Collection.LineNumber,
	|	Collection.ProductionLot
	|INTO Collection
	|FROM
	|	&Collection AS Collection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Collection.LineNumber									AS IndexOf,
	|	CatProductionLots.MainProductProducts		AS Products,
	|	CatProductionLots.MainProductCharacteristic		AS Characteristic,
	|	CatProductionLots.BillOfMaterials						AS BillOfMaterials,
	|	CatProductionLots.Series								AS Series,
	|	CatProductionLots.Purpose						AS Purpose
	|FROM
	|	Collection AS Collection
	|
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = Collection.ProductionLot
	|
	|ORDER BY
	|	IndexOf");
	
	Query.SetParameter("Collection",	Collection.Unload(, "LineNumber, ProductionLot"));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	For Number = 0 To Collection.Count() - 1 Do
		Selection.Next(); // The number of rows in the query sample is always equal to the number of rows in PM
		FillPropertyValues(Collection[Number], Selection);
	EndDo;
	
EndProcedure

// Query Text production costs Inventory.
// 
// Returns:
//  Structure -  Query Text and resource set:
// * QueryText - String - Query text
// * Resources - Array of String - Set of request resources
Function QueryTextProductionMaterialCost() Export
	
	If Not AccessRight("Read", Metadata.Catalogs.CounterpartyContracts) Then
		
		QueryText = 
		"SELECT TOP 0
		|	UNDEFINED AS Ref
		|INTO TTCounterpartyContracts";
		
	Else
		
		QueryText = 
		"SELECT ALLOWED
		|	T.Ref AS Ref
		|INTO TTCounterpartyContracts
		|FROM
		|	Catalog.CounterpartyContracts AS T
		|WHERE
		|	(T.ContractType = VALUE(Enum.ContractTypes.TransferToTolling2_5)
		|	OR T.ContractType = VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
		|{WHERE 
		|	(T.Organization) AS Organization}
		|INDEX BY
		|	Ref";
	
	EndIf;
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|" + "
	|SELECT ALLOWED
	|	T.Ref AS Ref
	|INTO TTSelectionOfProductAnalytics
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS T
	|	LEFT JOIN TTCounterpartyContracts AS Filter
	|		ON T.Contract = Filter.Ref
	|WHERE
	|	(T.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|	OR (T.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		AND NOT Filter.Ref IS NULL)
	|	OR T.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|	OR T.StorageType = VALUE(Enum.StorageLocationTypes.Partner))
	|	AND T.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|	{WHERE
	|		T.Characteristic AS Characteristic,
	|		T.Products AS Products}
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT ALLOWED
	|	DD.Warehouse AS Warehouse,
	|	DD.PreliminaryDivision AS PreliminaryDivision,
	|	DD.ThisIsWarehouseNotShopFloorStockroom AS ThisIsWarehouseNotShopFloorStockroom
	|INTO DepotsDivisions
	|FROM
	|	(SELECT
	|		T.Ref AS Warehouse,
	|		T.Department AS PreliminaryDivision,
	|		NOT T.ShopFloorStockroom AS ThisIsWarehouseNotShopFloorStockroom
	|	FROM
	|		Catalog.Warehouses AS T
	|	WHERE
	|		T.ShopFloorStockroom
	|	{WHERE
	|		T.Department AS PreliminaryDivision}
	|	
	|	UNION ALL
	|
	|	SELECT
	|		T.Ref AS Warehouse,
	|		UNDEFINED AS PreliminaryDivision,
	|		TRUE AS ThisIsWarehouseNotShopFloorStockroom
	|	FROM
	|		Catalog.Warehouses AS T
	|	WHERE
	|		NOT T.ShopFloorStockroom
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T.Ref AS Warehouse,
	|		T.Ref AS PreliminaryDivision,
	|		FALSE AS ThisIsWarehouseNotShopFloorStockroom
	|	FROM
	|		Catalog.BusinessStructure AS T
	|	{WHERE
	|		T.Ref AS PreliminaryDivision}
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DD.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|		UNDEFINED AS PreliminaryDivision,
	|		FALSE AS ThisIsWarehouseNotShopFloorStockroom
	|	FROM
	|		AccumulationRegister.InventoryCost.BalanceAndTurnovers(
	|			&BeginOfPeriod, 
	|			&PeriodEnding, , , 
	|			ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|			{Organization AS Organization}
	|		) AS DD
	|	WHERE
	|		(DD.CountOpeningBalance <> 0
	|			OR DD.CountClosingBalance <> 0
	|			OR DD.CountReceipt <> 0
	|			OR DD.CountExpense <> 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DD.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|		UNDEFINED AS PreliminaryDivision,
	|		FALSE AS ThisIsWarehouseNotShopFloorStockroom
	|	FROM
	|		AccumulationRegister.InventoryCost.BalanceAndTurnovers(
	|			&BeginOfPeriod,
	|			&PeriodEnding,,,
	|			ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			AND ItemsLocationAttributes.Contract IN (SELECT Filter.Ref FROM TTCounterpartyContracts AS Filter) 
	|			{Organization AS Organization}
	|			) AS DD
	|	WHERE
	|		DD.CountOpeningBalance <> 0
	|			OR DD.CountClosingBalance <> 0
	|			OR DD.CountReceipt <> 0
	|			OR DD.CountExpense <> 0
	|	) AS DD
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	&UsedMaterials											   AS Table,
	|	DD.Content                                          AS Content,
	|	DD.Organization                                         AS Organization,
	|	DD.Department                                       AS Department,
	|	DD.Sender                                         AS Sender,
	|	DD.Recipient                                          AS Recipient,
	|	DD.WarehouseDivision                                  AS WarehouseDivision,
	|	DD.Recorder                                         AS Recorder,
	|	DD.ItemsLocationAttributes                          AS ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute                                          AS InventoryOwnerAttribute,
	|	DD.FinancialAccountingDimension                           AS FinancialAccountingDimension,
	|	DD.LotVendorAttributes                                AS LotVendorAttributes,
	|	DD.VATActivityType                                  AS VATActivityType,
	|	DD.Products                                        AS Products,
	|	DD.Characteristic                                      AS Characteristic,
	|	DD.Series                                               AS Series,
	|	DD.Purpose                                          AS Purpose,
	|	DD.LineOfBusiness                             AS LineOfBusiness,
	|	DD.ProductCostElement                                   AS ProductCostElement,
	|	DD.Lot                                              AS Lot,
	|	DD.ProductionLot                                  AS ProductionLot,
	|	DD.ProductionOrder                                 AS ProductionOrder,
	|	SUM(DD.InitialBalanceQuantity)                  AS InitialBalanceQuantity,
	|	SUM(DD.InitialBalanceCost)                   AS InitialBalanceCost,
	|	SUM(DD.InitialBalanceOfPD)                          AS InitialBalanceOfPD,
	|	SUM(DD.InitialBalanceOfTD)                          AS InitialBalanceOfTD,
	|	SUM(DD.InitialBalanceOffBalanceSheet)                AS InitialBalanceOffBalanceSheet,
	|	SUM(DD.ReceivedQuantity) AS ReceivedQuantity,
	|	SUM(DD.ReceivedCost) AS ReceivedCost,
	|	SUM(DD.ReceivedPD) AS ReceivedPD,
	|	SUM(DD.TDHasBeenReceived) AS TDHasBeenReceived,
	|	SUM(DD.ReceivedOffBalanceSheet) AS ReceivedOffBalanceSheet,
	|	SUM(DD.PurchasedQuantity_) AS PurchasedQuantity_,
	|	SUM(DD.PurchasedValue) AS PurchasedValue,
	|	SUM(DD.PurchasedPD) AS PurchasedPD,
	|	SUM(DD.AcquiredByTD) AS AcquiredByTD,
	|	SUM(DD.PurchasedOffBalanceSheet) AS PurchasedOffBalanceSheet,
	|	SUM(DD.MovementsQuantity) AS MovementsQuantity,
	|	SUM(DD.MovingCost) AS MovingCost,
	|	SUM(DD.PDMovements) AS PDMovements,
	|	SUM(DD.TDMovements) AS TDMovements,
	|	SUM(DD.OffBalanceSheetTransfers) AS OffBalanceSheetTransfers,
	|	SUM(DD.InclusionExclusionOfVAT) AS InclusionExclusionOfVAT,
	|	SUM(DD.AmountSpentOnProduction) AS AmountSpentOnProduction,
	|	SUM(DD.SpentOnProductionCost) AS SpentOnProductionCost,
	|	SUM(DD.SpentOnProductionOfPD) AS SpentOnProductionOfPD,
	|	SUM(DD.SpentOnProductionOfTD) AS SpentOnProductionOfTD,
	|	SUM(DD.SpentOnProductionOffBalanceSheet) AS SpentOnProductionOffBalanceSheet,
	|	SUM(DD.DebitedQuantity) AS DebitedQuantity,
	|	SUM(DD.DebitedCost) AS DebitedCost,
	|	SUM(DD.WrittenOffPD) AS WrittenOffPD,
	|	SUM(DD.TDWasWrittenOff) AS TDWasWrittenOff,
	|	SUM(DD.WrittenOffOffBalanceSheet) AS WrittenOffOffBalanceSheet,
	|	SUM(DD.FinalRemainderQuantity) AS FinalRemainderQuantity,
	|	SUM(DD.FinalRemainderCost) AS FinalRemainderCost,
	|	SUM(DD.FinalBalanceOfPD) AS FinalBalanceOfPD,
	|	SUM(DD.FinalBalanceOfTD) AS FinalBalanceOfTD,
	|	SUM(DD.FinalBalanceIsOffBalance) AS FinalBalanceIsOffBalance,
	|	SUM(DD.QuantityTransmitted) AS QuantityTransmitted,
	|	SUM(DD.TransferredCost) AS TransferredCost,
	|	SUM(DD.SubmittedByPD) AS SubmittedByPD,
	|	SUM(DD.SubmittedByTD) AS SubmittedByTD,
	|	SUM(DD.PassedOffBalanceSheet) AS PassedOffBalanceSheet,
	|	SUM(DD.ProducedQuantity) AS ProducedQuantity,
	|	SUM(DD.ProducedCost) AS ProducedCost,
	|	SUM(DD.ProducedByPD) AS ProducedByPD,
	|	SUM(DD.ProducedByTD) AS ProducedByTD,
	|	SUM(DD.ProducedOffBalanceSheet) AS ProducedOffBalanceSheet
	|{SELECT
	|Table,
	|Content,
	|Organization.*,
	|Department.*,
	|Sender.*,
	|Recipient.*,
	|WarehouseDivision.*,
	|Recorder.*,
	|ItemsLocationAttributes.*,
	|InventoryOwnerAttribute.*,
	|FinancialAccountingDimension.*,
	|LotVendorAttributes.*,
	|VATActivityType.*,
	|Products.*,
	|Characteristic.*,
	|Series.*,
	|Purpose.*,
	|LineOfBusiness.*,
	|ProductCostElement.*,
	|Lot.*,
	|ProductionLot.*,
	|ProductionOrder.*,
	|InitialBalanceQuantity,
	|InitialBalanceCost,
	|InitialBalanceOfPD,
	|InitialBalanceOfTD,
	|InitialBalanceOffBalanceSheet,
	|ReceivedQuantity,
	|ReceivedCost,
	|ReceivedPD,
	|TDHasBeenReceived,
	|ReceivedOffBalanceSheet,
	|PurchasedQuantity_,
	|PurchasedValue,
	|PurchasedPD,
	|AcquiredByTD,
	|PurchasedOffBalanceSheet,
	|MovementsQuantity,
	|MovingCost,
	|PDMovements,
	|TDMovements,
	|OffBalanceSheetTransfers,
	|InclusionExclusionOfVAT,
	|AmountSpentOnProduction,
	|SpentOnProductionCost,
	|SpentOnProductionOfPD,
	|SpentOnProductionOfTD,
	|SpentOnProductionOffBalanceSheet,
	|DebitedQuantity,
	|DebitedCost,
	|WrittenOffPD,
	|TDWasWrittenOff,
	|WrittenOffOffBalanceSheet,
	|FinalRemainderQuantity,
	|FinalRemainderCost,
	|FinalBalanceOfPD,
	|FinalBalanceOfTD,
	|FinalBalanceIsOffBalance,
	|QuantityTransmitted,
	|TransferredCost,
	|SubmittedByPD,
	|SubmittedByTD,
	|PassedOffBalanceSheet,
	|ProducedQuantity,
	|ProducedCost,
	|ProducedByPD,
	|ProducedByTD,
	|ProducedOffBalanceSheet}
	|FROM
	|
	|(SELECT
	|	&OpeningBalance                                      AS Content,
	|	DD.Organization                                         AS Organization,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|				AND DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN Dimension.Purpose.Contract.Department
	|		ELSE DepotsDivisions.PreliminaryDivision
	|	END                                                  AS Department,
	|	UNDEFINED                                           AS Sender,
	|	UNDEFINED                                           AS Recipient,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT Dimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.InventoryOwnerAttribute.Contract.Department
	|		ELSE Dimension.StorageLocation
	|	END                                                  AS WarehouseDivision,
	|	UNDEFINED                                           AS Recorder,
	|	DD.ItemsLocationAttributes                          AS ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute                                          AS InventoryOwnerAttribute,
	|	DD.FinancialAccountingDimension                           AS FinancialAccountingDimension,
	|	DD.LotVendorAttributes                                AS LotVendorAttributes,
	|	DD.VATActivityType                                  AS VATActivityType,
	|	Dimension.Products                                 AS Products,
	|	Dimension.Characteristic                               AS Characteristic,
	|	Dimension.Series                                        AS Series,
	|	Dimension.Purpose                                   AS Purpose,
	|	Dimension.Purpose.LineOfBusiness           AS LineOfBusiness,
	|	Dimension.ProductCostElement                            AS ProductCostElement,
	|	DD.Lot                                              AS Lot,
	|	CASE
	|		WHEN VALUETYPE(Dimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(Dimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ProductionLot
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END                                                  AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(Dimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(Dimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ReferenceOrder
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END                                                  AS ProductionOrder,
	|	DD.CountBalance                                   AS InitialBalanceQuantity,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.CostBalance + DD.AddExpensesForGoodsBalance + DD.LaborCostsBalance + DD.ItemizedFixedCostsIncludingVATBalance + DD.ItemizedVariableCostsIncludingVATBalance
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVATBalance + DD.AdditionalExpensesExcludingVATBalance + DD.LaborCostsBalance + DD.ItemizedFixedCostsExcludingVATBalance + DD.ItemizedVariableCostsExcludingVATBalance
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostManBalance + DD.AddExpensesManBalance + DD.LaborCostsManBalance + DD.ItemizedFixedCostsManagBalance + DD.ItemizedVariableCostsManagBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCostBalance + DD.AddExpensesLocalBalance + DD.LaborCostsLocalBalance + DD.ItemizedFixedCostsComplBalance + DD.ItemizedVariableCostsComplBalance
	|		ELSE	
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVATBalance + DD.AdditionalExpensesExcludingVATBalance + DD.LaborCostsBalance + DD.ItemizedFixedCostsExcludingVATBalance + DD.ItemizedVariableCostsExcludingVATBalance
	|			ELSE
	|				DD.CostManBalance + DD.AddExpensesManBalance + DD.LaborCostsManBalance + DD.ItemizedFixedCostsManagBalance + DD.ItemizedVariableCostsManagBalance
	|			END
	|	END                                                  AS InitialBalanceCost,
	|	DD.PermanentDifferenceBalance                            AS InitialBalanceOfPD,
	|	DD.CostTDBalance                             AS InitialBalanceOfTD,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN DD.OffBalanceCostBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.OffBalanceCostLocalBalance
	|	END                                                  AS InitialBalanceOffBalanceSheet,
	|	0 AS ReceivedQuantity,
	|	0 AS ReceivedCost,
	|	0 AS ReceivedPD,
	|	0 AS TDHasBeenReceived,
	|	0 AS ReceivedOffBalanceSheet,
	|	0 AS PurchasedQuantity_,
	|	0 AS PurchasedValue,
	|	0 AS PurchasedPD,
	|	0 AS AcquiredByTD,
	|	0 AS PurchasedOffBalanceSheet,
	|	0 AS MovementsQuantity,
	|	0 AS MovingCost,
	|	0 AS PDMovements,
	|	0 AS TDMovements,
	|	0 AS OffBalanceSheetTransfers,
	|	0 AS InclusionExclusionOfVAT,
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	0 AS DebitedQuantity,
	|	0 AS DebitedCost,
	|	0 AS WrittenOffPD,
	|	0 AS TDWasWrittenOff,
	|	0 AS WrittenOffOffBalanceSheet,
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance,
	|	0 AS QuantityTransmitted,
	|	0 AS TransferredCost,
	|	0 AS SubmittedByPD,
	|	0 AS SubmittedByTD,
	|	0 AS PassedOffBalanceSheet,
	|	0 AS ProducedQuantity,
	|	0 AS ProducedCost,
	|	0 AS ProducedByPD,
	|	0 AS ProducedByTD,
	|	0 AS ProducedOffBalanceSheet
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(
	|			{(&BeginOfPeriod)},
	|			NOT &WithoutFilterByPeriod
	|				AND ItemsLocationAttributes IN (SELECT Filter.Ref FROM TTSelectionOfProductAnalytics AS Filter)
	|					AND NOT AccountingSection IN (
	|						VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent),
	|						VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|					)
	|					AND (ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse) 
	|						AND (ItemsLocationAttributes.StorageLocation.ShopFloorStockroom 
	|							OR InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|							)
	|						OR ItemsLocationAttributes.StorageType <> VALUE(Enum.StorageLocationTypes.Warehouse)
	|					)
	|			{(Organization) AS Organization}) AS DD
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN DepotsDivisions AS DepotsDivisions
	|		ON (Dimension.StorageLocation = DepotsDivisions.Warehouse)
	|			AND (DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|
	|UNION ALL
	|
	|SELECT
	|	&ReceivedFromWarehouse AS Content,
	|	CASE
	|		WHEN DD.CorCompany = VALUE(Catalog.Companies.EmptyRef)
	|			THEN DD.Organization
	|		ELSE DD.CorCompany
	|	END,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|				AND CorWarehousesDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CorDimension.Purpose.Contract.Department
	|		ELSE CorWarehousesDivisions.PreliminaryDivision
	|	END,
	|	Dimension.StorageLocation,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT CorDimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.CorInventoryOwnerAttribute.Contract.Department
	|		ELSE CorDimension.StorageLocation
	|	END,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT CorDimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.CorInventoryOwnerAttribute.Contract.Department
	|		ELSE CorDimension.StorageLocation
	|	END,
	|	DD.Recorder AS Recorder,
	|	DD.CorItemsLocationAttributes,
	|	DD.CorInventoryOwnerAttribute,
	|	DD.CorControllingAttributes,
	|	DD.LotVendorAttributesCorr,
	|	DD.CorVATActivityTypes,
	|	CorDimension.Products,
	|	CorDimension.Characteristic,
	|	CorDimension.Series,
	|	CorDimension.Purpose,
	|	CorDimension.Purpose.LineOfBusiness,
	|	CorDimension.ProductCostElement,
	|	DD.Lot,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(CorDimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ProductionLot
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(CorDimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ReferenceOrder
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END,
	// Initial balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Inpayment
	|	CASE
	|		WHEN DepotsDivisions.PreliminaryDivision <> CorWarehousesDivisions.PreliminaryDivision
	|				OR DepotsDivisions.PreliminaryDivision IS NULL
	|			THEN DD.Count
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DepotsDivisions.PreliminaryDivision <> CorWarehousesDivisions.PreliminaryDivision
	|				OR DepotsDivisions.PreliminaryDivision IS NULL
	|			THEN CASE
	|					WHEN &Cost_Data = 1
	|						THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|					WHEN &Cost_Data = 2
	|						THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|					WHEN &Cost_Data = 3
	|						THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|					WHEN &Cost_Data = 4
	|						THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|					ELSE	
	|						CASE WHEN &ByEnterprise
	|							THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|						ELSE
	|							DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|						END
	|				END
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DepotsDivisions.PreliminaryDivision <> CorWarehousesDivisions.PreliminaryDivision
	|				OR DepotsDivisions.PreliminaryDivision IS NULL
	|			THEN DD.PermanentDifference
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DepotsDivisions.PreliminaryDivision <> CorWarehousesDivisions.PreliminaryDivision
	|				OR DepotsDivisions.PreliminaryDivision IS NULL
	|			THEN DD.CostTD
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DepotsDivisions.PreliminaryDivision <> CorWarehousesDivisions.PreliminaryDivision
	|				OR DepotsDivisions.PreliminaryDivision IS NULL
	|			THEN CASE
	|					WHEN &Cost_Data = 1
	|						THEN 0
	|					WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|						THEN OffBalanceCost
	|					WHEN &Cost_Data = 4
	|						THEN OffBalanceCostLocal
	|				END
	|		ELSE 0
	|	END,
	// Purchased
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Move
	|	CASE
	|		WHEN DepotsDivisions.PreliminaryDivision = CorWarehousesDivisions.PreliminaryDivision
	|			AND NOT DepotsDivisions.PreliminaryDivision = UNDEFINED
	|			THEN DD.Count
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DepotsDivisions.PreliminaryDivision = CorWarehousesDivisions.PreliminaryDivision
	|			AND NOT DepotsDivisions.PreliminaryDivision = UNDEFINED
	|			THEN CASE
	|					WHEN &Cost_Data = 1
	|						THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|					WHEN &Cost_Data = 2
	|						THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|					WHEN &Cost_Data = 3
	|						THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|					WHEN &Cost_Data = 4
	|						THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|					ELSE	
	|						CASE WHEN &ByEnterprise
	|							THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|						ELSE
	|							DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|						END
	|				END
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DepotsDivisions.PreliminaryDivision = CorWarehousesDivisions.PreliminaryDivision
	|			AND NOT DepotsDivisions.PreliminaryDivision = UNDEFINED
	|			AND &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DepotsDivisions.PreliminaryDivision = CorWarehousesDivisions.PreliminaryDivision
	|			AND NOT DepotsDivisions.PreliminaryDivision = UNDEFINED
	|			AND &Cost_Data = 4
	|			THEN DD.CostTD
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DepotsDivisions.PreliminaryDivision = CorWarehousesDivisions.PreliminaryDivision
	|			AND NOT DepotsDivisions.PreliminaryDivision = UNDEFINED
	|			THEN CASE
	|					WHEN &Cost_Data = 1
	|						THEN 0
	|					WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|						THEN DD.OffBalanceCost
	|					WHEN &Cost_Data = 4
	|						THEN DD.OffBalanceCostLocal
	|				END
	|		ELSE 0
	|	END,
	// Inclusion/exclusion of VAT in the cost
	|	0 AS InclusionExclusionOfVAT,
	// Spent on production
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// WrittenOff
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// The final balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Passed
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Manufactured
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CorDimension
	|		ON DD.CorItemsLocationAttributes = CorDimension.Ref
	|		LEFT JOIN DepotsDivisions AS CorWarehousesDivisions
	|		ON (CorDimension.StorageLocation = CorWarehousesDivisions.Warehouse)
	|			AND (CorWarehousesDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT CorWarehousesDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|		LEFT JOIN DepotsDivisions AS DepotsDivisions
	|		ON (Dimension.StorageLocation = DepotsDivisions.Warehouse)
	|			AND (DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|		INNER JOIN TTSelectionOfProductAnalytics AS FilterAnalysts
	|		ON DD.CorItemsLocationAttributes = FilterAnalysts.Ref
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND Dimension.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND (&Cost_Data < 3 
	// When generating a report on organizations
	// Transfer of goods between organizations is not a transfer, for the transferring organization it is a sale,
	// for the receiving organization it is an acquisition
	|		OR DD.CorCompany = VALUE(Catalog.Companies.EmptyRef)
	|		OR DD.Organization = DD.CorCompany
	|	)
	|	AND (CorDimension.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse) 
	|		AND (CorDimension.StorageLocation.ShopFloorStockroom 
	|			OR DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			)
	|		OR CorDimension.StorageType <> VALUE(Enum.StorageLocationTypes.Warehouse)
	|	)
	|{WHERE 
	|	CASE
	|		WHEN DD.CorCompany = VALUE(Catalog.Companies.EmptyRef)
	|			THEN DD.Organization
	|		ELSE DD.CorCompany
	|	END AS Organization,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|				AND CorWarehousesDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CorDimension.Purpose.Contract.Department
	|		ELSE CorWarehousesDivisions.PreliminaryDivision
	|	END AS Department,
	|	CorDimension.Products AS Products,
	|	CorDimension.Characteristic AS Characteristic}
	|
	|UNION ALL
	|
	|SELECT
	|	&ReceivedGNZP AS Content,
	|	DD.Organization,
	|	CorWarehousesDivisions.PreliminaryDivision,
	|	Dimension.StorageLocation,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT CorDimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.CorInventoryOwnerAttribute.Contract.Department
	|		ELSE CorDimension.StorageLocation
	|	END,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT CorDimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.CorInventoryOwnerAttribute.Contract.Department
	|		ELSE CorDimension.StorageLocation
	|	END,
	|	DD.Recorder AS Recorder,
	|	DD.CorItemsLocationAttributes,
	|	DD.CorInventoryOwnerAttribute,
	|	DD.CorControllingAttributes,
	|	DD.LotVendorAttributesCorr,
	|	DD.CorVATActivityTypes,
	|	CorDimension.Products,
	|	CorDimension.Characteristic,
	|	CorDimension.Series,
	|	CorDimension.Purpose,
	|	CorDimension.Purpose.LineOfBusiness,
	|	CorDimension.ProductCostElement,
	|	DD.Lot,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(CorDimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ProductionLot
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(CorDimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ReferenceOrder
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END,
	// Initial balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Inpayment
	|	DD.Count,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|		ELSE	
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|			ELSE
	|				DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|			END
	|	END,
	|	DD.PermanentDifference,
	|	DD.CostTD,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN OffBalanceCost
	|		WHEN &Cost_Data = 4
	|			THEN OffBalanceCostLocal
	|	END,
	// Purchased
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Move
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Inclusion/exclusion of VAT in the cost
	|	0 AS InclusionExclusionOfVAT,
	// Spent on production
	|	DD.Count,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|		ELSE	
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|			ELSE
	|				DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|			END
	|	END,
	|	DD.PermanentDifference,
	|	DD.CostTD,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN OffBalanceCost
	|		WHEN &Cost_Data = 4
	|			THEN OffBalanceCostLocal
	|	END,
	// WrittenOff
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// The final balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Passed
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Manufactured
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CorDimension
	|		ON DD.CorItemsLocationAttributes = CorDimension.Ref
	|		LEFT JOIN DepotsDivisions AS CorWarehousesDivisions
	|		ON (CorDimension.StorageLocation = CorWarehousesDivisions.Warehouse)
	|			AND (CorWarehousesDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT CorWarehousesDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|		LEFT JOIN DepotsDivisions AS DepotsDivisions
	|		ON (Dimension.StorageLocation = DepotsDivisions.Warehouse)
	|			AND (DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND NOT CorDimension.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|	AND Dimension.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|	AND NOT Dimension.WarehouseArea.ShopFloorStockroom
	|	AND Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND (CorDimension.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse) 
	|		AND (CorDimension.StorageLocation.ShopFloorStockroom 
	|			OR DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			)
	|		OR CorDimension.StorageType <> VALUE(Enum.StorageLocationTypes.Warehouse))
	|
	|{WHERE 
	|	(DD.Organization) AS Organization,
	|	CorWarehousesDivisions.PreliminaryDivision AS Department,
	|	CorDimension.Products AS Products,
	|	CorDimension.Characteristic AS Characteristic}
	|
	|UNION ALL
	|
	|SELECT
	|	&Expenses AS Content,
	|	DD.Organization,
	|	DepotsDivisions.PreliminaryDivision,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT Dimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.InventoryOwnerAttribute.Contract.Department
	|		ELSE Dimension.StorageLocation
	|	END,
	|	CorDimension.StorageLocation,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT Dimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.InventoryOwnerAttribute.Contract.Department
	|		ELSE Dimension.StorageLocation
	|	END,
	|	DD.Recorder AS Recorder,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.FinancialAccountingDimension,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Series,
	|	Dimension.Purpose,
	|	Dimension.Purpose.LineOfBusiness,
	|	Dimension.ProductCostElement,
	|	DD.Lot,
	|	CASE
	|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|			THEN DD.CorLot
	|		WHEN VALUETYPE(CorDimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(CorDimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ProductionLot
	|		WHEN VALUETYPE(Dimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(Dimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ProductionLot
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(CorDimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ReferenceOrder
	|		WHEN VALUETYPE(Dimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(Dimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ReferenceOrder
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END,
	// Initial balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Received
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Purchased
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Transfers
	|	CASE
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN 0
	|		WHEN DepotsDivisions.PreliminaryDivision = CorWarehousesDivisions.PreliminaryDivision
	|			AND NOT DepotsDivisions.PreliminaryDivision = UNDEFINED
	|			AND NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|											VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots),
	|											VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|											)
	|			AND (&Cost_Data < 3 
	|				OR DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|			THEN -1 * DD.Count
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN 0
	|		WHEN DepotsDivisions.PreliminaryDivision = CorWarehousesDivisions.PreliminaryDivision
	|			AND NOT DepotsDivisions.PreliminaryDivision = UNDEFINED
	|			AND NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|											VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots),
	|											VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|											)
	|			AND (&Cost_Data < 3 
	|				OR DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|			THEN -1 * CASE
	|					WHEN &Cost_Data = 1
	|						THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|					WHEN &Cost_Data = 2
	|						THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|					WHEN &Cost_Data = 3
	|						THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|					WHEN &Cost_Data = 4
	|						THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|					ELSE	
	|						CASE WHEN &ByEnterprise
	|							THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|						ELSE
	|							DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|						END
	|				END
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN 0
	|		WHEN DepotsDivisions.PreliminaryDivision = CorWarehousesDivisions.PreliminaryDivision
	|			AND NOT DepotsDivisions.PreliminaryDivision = UNDEFINED
	|			AND NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|											VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots),
	|											VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|											)
	|			AND (&Cost_Data < 3 
	|				OR DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|			THEN -1 * DD.PermanentDifference
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN 0
	|		WHEN DepotsDivisions.PreliminaryDivision = CorWarehousesDivisions.PreliminaryDivision
	|			AND NOT DepotsDivisions.PreliminaryDivision = UNDEFINED
	|			AND NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|											VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots),
	|											VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|											)
	|			AND (&Cost_Data < 3 
	|				OR DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|			THEN -1 * DD.CostTD
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN 0
	|		WHEN DepotsDivisions.PreliminaryDivision = CorWarehousesDivisions.PreliminaryDivision
	|			AND NOT DepotsDivisions.PreliminaryDivision = UNDEFINED
	|			AND NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|											VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots),
	|											VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|											)
	|			AND (&Cost_Data < 3 
	|				OR DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|			THEN -1 * CASE
	|					WHEN &Cost_Data = 1
	|						THEN 0
	|					WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|						THEN DD.OffBalanceCost
	|					WHEN &Cost_Data = 4
	|						THEN DD.OffBalanceCostLocal
	|				END
	|		ELSE 0
	|	END,
	// Inclusion/exclusion of VAT in the cost
	|	0 AS InclusionExclusionOfVAT,
	// Spent on production
	|	CASE
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|										VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots))
	|			THEN DD.Count
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|										VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots))
	|			THEN CASE
	|					WHEN &Cost_Data = 1
	|						THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|					WHEN &Cost_Data = 2
	|						THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|					WHEN &Cost_Data = 3
	|						THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|					WHEN &Cost_Data = 4
	|						THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|					ELSE	
	|						CASE WHEN &ByEnterprise
	|							THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|						ELSE
	|							DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|						END
	|				END
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|										VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots))
	|			THEN DD.PermanentDifference
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|										VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots))
	|			THEN DD.CostTD
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|										VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots))
	|			THEN CASE
	|					WHEN &Cost_Data = 1
	|						THEN 0
	|					WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|						THEN DD.OffBalanceCost
	|					WHEN &Cost_Data = 4
	|						THEN DD.OffBalanceCostLocal
	|				END
	|		ELSE 0
	|	END,
	// WriteOff
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// The final balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Transfer to the warehouse, to other divisions, implemented	
	|	CASE
	|		WHEN (DepotsDivisions.PreliminaryDivision <> CorWarehousesDivisions.PreliminaryDivision
	|				OR DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				OR CorWarehousesDivisions.PreliminaryDivision IS NULL
	|				OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|				OR (&Cost_Data > 2 
	|					AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|				)
	|				AND DD.BusinessOperation NOT IN(VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|										VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots))
	|			THEN DD.Count
	|		ELSE 0
	|	END * CASE 
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -1
	|		ELSE 1
	|	END,
	|	CASE
	|		WHEN (DepotsDivisions.PreliminaryDivision <> CorWarehousesDivisions.PreliminaryDivision
	|				OR DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				OR CorWarehousesDivisions.PreliminaryDivision IS NULL
	|				OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|				OR (&Cost_Data > 2 
	|					AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|				)
	|					AND DD.BusinessOperation NOT IN(VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|										VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots))
	|			THEN CASE
	|					WHEN &Cost_Data = 1
	|						THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|					WHEN &Cost_Data = 2
	|						THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|					WHEN &Cost_Data = 3
	|						THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|					WHEN &Cost_Data = 4
	|						THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|					ELSE	
	|						CASE WHEN &ByEnterprise
	|							THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|						ELSE
	|							DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|						END
	|				END
	|		ELSE 0
	|	END * CASE 
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -1
	|		ELSE 1
	|	END,
	|	CASE
	|		WHEN (DepotsDivisions.PreliminaryDivision <> CorWarehousesDivisions.PreliminaryDivision
	|				OR DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				OR CorWarehousesDivisions.PreliminaryDivision IS NULL
	|				OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|				OR (&Cost_Data > 2 
	|					AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|				)
	|					AND DD.BusinessOperation NOT IN(VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|										VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots))
	|			THEN DD.PermanentDifference
	|		ELSE 0
	|	END * CASE 
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -1
	|		ELSE 1
	|	END,
	|	CASE
	|		WHEN (DepotsDivisions.PreliminaryDivision <> CorWarehousesDivisions.PreliminaryDivision
	|				OR DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				OR CorWarehousesDivisions.PreliminaryDivision IS NULL
	|				OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|				OR (&Cost_Data > 2 
	|					AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|				)
	|					AND DD.BusinessOperation NOT IN(VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|										VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots))
	|			THEN DD.CostTD
	|		ELSE 0
	|	END * CASE 
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -1
	|		ELSE 1
	|	END,
	|	CASE
	|		WHEN (DepotsDivisions.PreliminaryDivision <> CorWarehousesDivisions.PreliminaryDivision
	|				OR DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				OR CorWarehousesDivisions.PreliminaryDivision IS NULL
	|				OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|				OR (&Cost_Data > 2 
	|					AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|				)
	|					AND DD.BusinessOperation NOT IN(VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|										VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots))
	|			THEN CASE
	|					WHEN &Cost_Data = 1
	|						THEN 0
	|					WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|						THEN DD.OffBalanceCost
	|					WHEN &Cost_Data = 4
	|						THEN DD.OffBalanceCostLocal
	|				END
	|		ELSE 0
	|	END * CASE 
	|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -1
	|		ELSE 1
	|	END,
	// Manufactured
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CorDimension
	|		ON DD.CorItemsLocationAttributes = CorDimension.Ref
	|		LEFT JOIN DepotsDivisions AS CorWarehousesDivisions
	|		ON (CorDimension.StorageLocation = CorWarehousesDivisions.Warehouse)
	|			AND (CorWarehousesDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT CorWarehousesDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|		LEFT JOIN DepotsDivisions AS DepotsDivisions
	|		ON (Dimension.StorageLocation = DepotsDivisions.Warehouse)
	|			AND (DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|		INNER JOIN TTSelectionOfProductAnalytics AS FilterAnalysts
	|		ON DD.ItemsLocationAttributes = FilterAnalysts.Ref
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND (DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|		OR VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment))
	|	AND NOT (DD.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand),
	|			VALUE(Enum.BusinessTransactions.TransferToIntangibleAssetsAndRD),
	|			VALUE(Enum.BusinessTransactions.TransferToFixedAssets),
	|			VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost),
	|			VALUE(Enum.BusinessTransactions.GoodsWriteOffAtToller),
	|			VALUE(Enum.BusinessTransactions.RedemptionOfGoodsByToller))
	|		OR DD.ExpenseItemOfWriteOff =
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.CostCalculationError))
	|	AND (Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse) 
	|		AND (Dimension.StorageLocation.ShopFloorStockroom 
	|			OR DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			)
	|		OR Dimension.StorageType <> VALUE(Enum.StorageLocationTypes.Warehouse))
	|
	|{WHERE 
	|	(DD.Organization) AS Organization,
	|	DepotsDivisions.PreliminaryDivision AS Department,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic}
	|
	|UNION ALL
	|
	|SELECT
	|	&InclusionExclusionOfVAT AS Content,
	|	DD.Organization,
	|	DepotsDivisions.PreliminaryDivision,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT Dimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.InventoryOwnerAttribute.Contract.Department
	|		ELSE Dimension.StorageLocation
	|	END,
	|	CorDimension.StorageLocation,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT Dimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.InventoryOwnerAttribute.Contract.Department
	|		ELSE Dimension.StorageLocation
	|	END,
	|	DD.Recorder AS Recorder,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.FinancialAccountingDimension,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Series,
	|	Dimension.Purpose,
	|	Dimension.Purpose.LineOfBusiness,
	|	Dimension.ProductCostElement,
	|	DD.Lot,
	|	0,
	|	0,
	// Initial balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Received
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Purchased
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Transfers
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Inclusion/exclusion of VAT in the cost
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT
	|			ELSE
	|				DD.CostMan
	|			END
	|	END AS InclusionExclusionOfVAT,
	// Spent on production
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// WriteOff
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// The final balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Transfer to the warehouse, to other divisions, implemented	
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Manufactured
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CorDimension
	|		ON DD.CorItemsLocationAttributes = CorDimension.Ref
	|		LEFT JOIN DepotsDivisions AS CorWarehousesDivisions
	|		ON (CorDimension.StorageLocation = CorWarehousesDivisions.Warehouse)
	|			AND (CorWarehousesDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT CorWarehousesDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|		LEFT JOIN DepotsDivisions AS DepotsDivisions
	|		ON (Dimension.StorageLocation = DepotsDivisions.Warehouse)
	|			AND (DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|		INNER JOIN TTSelectionOfProductAnalytics AS FilterAnalysts
	|		ON DD.ItemsLocationAttributes = FilterAnalysts.Ref
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|	AND DD.EntryType = VALUE(Enum.LotRecordTypes.InclusionExclusionOfVATInCost)
	|	AND (Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse) 
	|		AND (Dimension.StorageLocation.ShopFloorStockroom 
	|			OR DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			)
	|		OR Dimension.StorageType <> VALUE(Enum.StorageLocationTypes.Warehouse))
	|
	|{WHERE 
	|	(DD.Organization) AS Organization,
	|	DepotsDivisions.PreliminaryDivision AS Department,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic}
	|
	|UNION ALL
	|
	|SELECT
	|	&WriteOffsForExpenses AS Content,
	|	DD.Organization,
	|	DepotsDivisions.PreliminaryDivision,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT Dimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.InventoryOwnerAttribute.Contract.Department
	|		ELSE Dimension.StorageLocation
	|	END,
	|	DD.ExpenseItemOfWriteOff,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT Dimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.InventoryOwnerAttribute.Contract.Department
	|		ELSE Dimension.StorageLocation
	|	END,
	|	DD.Recorder AS Recorder,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.FinancialAccountingDimension,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Series,
	|	Dimension.Purpose,
	|	Dimension.Purpose.LineOfBusiness,
	|	Dimension.ProductCostElement,
	|	DD.Lot,
	|	CASE
	|		WHEN VALUETYPE(Dimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(Dimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ProductionLot
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END,
	|	CASE
	|		WHEN VALUETYPE(Dimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(Dimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ReferenceOrder
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END,
	// Initial balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Received
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Purchased
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Transfers
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Inclusion/exclusion of VAT in the cost
	|	0 AS InclusionExclusionOfVAT,
	// Spent on production
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// WriteOff
	|	DD.Count,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|		ELSE	
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|			ELSE
	|				DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|			END
	|	END,
	|	DD.PermanentDifference,
	|	DD.CostTD,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN DD.OffBalanceCost
	|		WHEN &Cost_Data = 3
	|			THEN DD.OffBalanceCostLocal
	|	END,
	// The final balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// transfer to the warehouse
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Manufactured
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CorDimension
	|		ON DD.CorItemsLocationAttributes = CorDimension.Ref
	|		LEFT JOIN DepotsDivisions AS CorWarehousesDivisions
	|		ON (CorDimension.StorageLocation = CorWarehousesDivisions.Warehouse)
	|			AND (CorWarehousesDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT CorWarehousesDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|		LEFT JOIN DepotsDivisions AS DepotsDivisions
	|		ON (Dimension.StorageLocation = DepotsDivisions.Warehouse)
	|			AND (DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|		INNER JOIN TTSelectionOfProductAnalytics AS FilterAnalysts
	|		ON DD.ItemsLocationAttributes = FilterAnalysts.Ref
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND (DD.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand),
	|			VALUE(Enum.BusinessTransactions.TransferToIntangibleAssetsAndRD),
	|			VALUE(Enum.BusinessTransactions.TransferToFixedAssets),
	|			VALUE(Enum.BusinessTransactions.GoodsWriteOffAtToller),
	|			VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost),
	|			VALUE(Enum.BusinessTransactions.RedemptionOfGoodsByToller))
	|		OR DD.ExpenseItemOfWriteOff = VALUE(ChartOfCharacteristicTypes.ExpenseItems.CostCalculationError))
	|	AND (Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse) 
	|		AND (Dimension.StorageLocation.ShopFloorStockroom 
	|			OR DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			)
	|		OR Dimension.StorageType <> VALUE(Enum.StorageLocationTypes.Warehouse))
	|{WHERE 
	|	DD.Organization AS Organization,
	|	DepotsDivisions.PreliminaryDivision AS Department,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic}
	|
	|UNION ALL
	|
	|SELECT
	|	&ParishesFromPostashchikov AS Content,
	|	DD.Organization,
	|	DepotsDivisions.PreliminaryDivision,
	|	CASE
	|		WHEN ProductionDetailsWithoutOrder.Department IS NOT NULL
	|			THEN ProductionDetailsWithoutOrder.Department
	|		WHEN ReportDetails_12_5.Department IS NOT NULL
	|			THEN ReportDetails_12_5.Department
	|		ELSE DepotsDivisions.PreliminaryDivision
	|	END,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT Dimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.InventoryOwnerAttribute.Contract.Department
	|		ELSE Dimension.StorageLocation
	|	END,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT Dimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.InventoryOwnerAttribute.Contract.Department
	|		ELSE Dimension.StorageLocation
	|	END,
	|	DD.Recorder AS Recorder,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.FinancialAccountingDimension,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Series,
	|	Dimension.Purpose,
	|	Dimension.Purpose.LineOfBusiness,
	|	Dimension.ProductCostElement,
	|	DD.Lot,
	|	CASE
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			THEN DD.Lot
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			AND ReportOutput_2_5.ProductionStage.ReferenceOrder IS NOT NULL
	|			THEN ReportOutput_2_5.ProductionStage.ReferenceOrder
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			AND ReportWaste2_5.ProductionStage.ReferenceOrder IS NOT NULL
	|			THEN ReportWaste2_5.ProductionStage.ReferenceOrder
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			AND VALUETYPE(DD.Lot) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(DD.Lot AS Document.ProductionStage2_2).ReferenceOrder
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END,
	// Initial balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Received
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Purchased
	|	CASE
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			THEN 0
	|		ELSE
	|			DD.Count
	|	END,
	|	CASE
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			THEN 0
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|		ELSE	
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|			ELSE
	|				DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|			END
	|	END,
	|	CASE
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			THEN 0
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|		ELSE
	|			0
	|	END,
	|	CASE
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			THEN 0
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|		ELSE
	|			0
	|	END,
	|	CASE
	|		WHEN DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			THEN 0
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN DD.OffBalanceCost
	|		WHEN &Cost_Data = 4
	|			THEN DD.OffBalanceCostLocal
	|		ELSE
	|			0
	|	END,
	// Transfers
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Inclusion/exclusion of VAT in the cost
	|	0 AS InclusionExclusionOfVAT,
	// Spent on production
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// WriteOff
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// The final balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// transfer to the warehouse
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Manufactured
	|	CASE
	|		WHEN NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			THEN 0
	|		ELSE
	|			DD.Count
	|	END,
	|	CASE
	|		WHEN NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			THEN 0
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|		ELSE	
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|			ELSE
	|				DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|			END
	|	END,
	|	CASE
	|		WHEN NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			THEN 0
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|	END,
	|	CASE
	|		WHEN NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			THEN 0
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|	END,
	|	CASE
	|		WHEN NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|			THEN 0
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN DD.OffBalanceCost
	|		WHEN &Cost_Data = 4
	|			THEN DD.OffBalanceCostLocal
	|	END
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN DepotsDivisions AS DepotsDivisions
	|		ON (Dimension.StorageLocation = DepotsDivisions.Warehouse)
	|			AND (DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|		LEFT JOIN Document.BackflushProduction AS ProductionDetailsWithoutOrder
	|		ON DD.Recorder = ProductionDetailsWithoutOrder.Ref
	|		LEFT JOIN Document.SubcontractorReport2_5 AS ReportDetails_12_5
	|		ON DD.Recorder = ReportDetails_12_5.Ref
	// the order for production according to the reports of the processor 2.5 by stages we choose from the stages
	|		LEFT JOIN Document.SubcontractorReport2_5.ManufacturedProducts AS ReportOutput_2_5
	|		ON DD.Recorder = ReportOutput_2_5.Ref
	|			AND DD.LotVendorAttributes.RowCode = ReportOutput_2_5.RowCodeProducts
	|			AND ReportOutput_2_5.Ref.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|		LEFT JOIN Document.SubcontractorReport2_5.SideAndIntermediateRelease AS ReportWaste2_5
	|		ON DD.Recorder = ReportWaste2_5.Ref
	|			AND DD.LotVendorAttributes.RowCode = ReportWaste2_5.RowCode
	|			AND ReportWaste2_5.Ref.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|		INNER JOIN TTSelectionOfProductAnalytics AS FilterAnalysts
	|		ON DD.ItemsLocationAttributes = FilterAnalysts.Ref
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND (DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|								VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost),
	|								VALUE(Enum.BusinessTransactions.ExpenseAllocationToCost),
	|								VALUE(Enum.BusinessTransactions.PurchaseFromSupplier))
	|		OR (&Cost_Data > 2 
	// If a report is generated on organizations, we add Receipts for transfer to other organizations
	// and internal receipt of works.
	|				AND DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
	|											VALUE(Enum.BusinessTransactions.InternalWorkReceipt)))
	|	)
	|	AND (Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse) 
	|		AND (Dimension.StorageLocation.ShopFloorStockroom 
	|			OR DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			)
	|		OR Dimension.StorageType <> VALUE(Enum.StorageLocationTypes.Warehouse)
	|	)
	|{WHERE 
	|	DD.Organization AS Organization,
	|	DepotsDivisions.PreliminaryDivision AS Department,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic}
	|
	|UNION ALL
	|
	|SELECT
	|	&ClosingBalance AS Content,
	|	DD.Organization,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|				AND DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN Dimension.Purpose.Contract.Department
	|		ELSE DepotsDivisions.PreliminaryDivision
	|	END,
	|	UNDEFINED,
	|	UNDEFINED,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.Warehouses)
	|		 AND NOT Dimension.StorageLocation.ShopFloorStockroom
	|		 AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN DD.InventoryOwnerAttribute.Contract.Department
	|		ELSE Dimension.StorageLocation
	|	END,
	|	UNDEFINED,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.FinancialAccountingDimension,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Series,
	|	Dimension.Purpose,
	|	Dimension.Purpose.LineOfBusiness,
	|	Dimension.ProductCostElement,
	|	DD.Lot,
	|	CASE
	|		WHEN VALUETYPE(Dimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(Dimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ProductionLot
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END,
	|	CASE
	|		WHEN VALUETYPE(Dimension.Purpose.OrderDocument) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(Dimension.Purpose.OrderDocument AS Document.ProductionStage2_2).ReferenceOrder
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END,
	// Initial balance
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Received
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Purchased
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Transfers
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Inclusion/exclusion of VAT in the cost
	|	0 AS InclusionExclusionOfVAT,
	// Spent on production
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// WriteOff
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// The final balance
	|	DD.CountBalance,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.CostBalance + DD.AddExpensesForGoodsBalance + DD.LaborCostsBalance + DD.ItemizedFixedCostsIncludingVATBalance + DD.ItemizedVariableCostsIncludingVATBalance
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVATBalance + DD.AdditionalExpensesExcludingVATBalance + DD.LaborCostsBalance + DD.ItemizedFixedCostsExcludingVATBalance + DD.ItemizedVariableCostsExcludingVATBalance
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostManBalance + DD.AddExpensesManBalance + DD.LaborCostsManBalance + DD.ItemizedFixedCostsManagBalance + DD.ItemizedVariableCostsManagBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCostBalance + DD.AddExpensesLocalBalance + DD.LaborCostsLocalBalance + DD.ItemizedFixedCostsComplBalance + DD.ItemizedVariableCostsComplBalance
	|		ELSE	
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVATBalance + DD.AdditionalExpensesExcludingVATBalance + DD.LaborCostsBalance + DD.ItemizedFixedCostsExcludingVATBalance + DD.ItemizedVariableCostsExcludingVATBalance
	|			ELSE
	|				DD.CostManBalance + DD.AddExpensesManBalance + DD.LaborCostsManBalance + DD.ItemizedFixedCostsManagBalance + DD.ItemizedVariableCostsManagBalance
	|			END
	|	END,
	|	DD.PermanentDifferenceBalance,
	|	DD.CostTDBalance,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN DD.OffBalanceCostBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.OffBalanceCostLocalBalance
	|	END,
	// transfer to the warehouse
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	// Manufactured
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(
	|			{(&EndOfPeriodLimit)},
	|				ItemsLocationAttributes IN (SELECT Filter.Ref FROM TTSelectionOfProductAnalytics AS Filter)
	|					AND NOT AccountingSection IN (
	|						VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent),
	|						VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|					)
	|					AND (ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse) 
	|						AND (ItemsLocationAttributes.StorageLocation.ShopFloorStockroom 
	|							OR InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|							)
	|						OR ItemsLocationAttributes.StorageType <> VALUE(Enum.StorageLocationTypes.Warehouse)
	|					)
	|			{(Organization) AS Organization}) AS DD
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN DepotsDivisions AS DepotsDivisions
	|		ON (Dimension.StorageLocation = DepotsDivisions.Warehouse)
	|			AND (DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom
	|				AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|					OR NOT DepotsDivisions.ThisIsWarehouseNotShopFloorStockroom)
	|) AS DD
	|
	|GROUP BY
	|
	|	DD.Content,
	|	DD.Organization,
	|	DD.Department,
	|	DD.Sender,
	|	DD.Recipient,
	|	DD.WarehouseDivision,
	|	DD.Recorder,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.FinancialAccountingDimension,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.Products,
	|	DD.Characteristic,
	|	DD.Series,
	|	DD.Purpose,
	|	DD.LineOfBusiness,
	|	DD.ProductCostElement,
	|	DD.Lot,
	|	DD.ProductionLot,
	|	DD.ProductionOrder
	|";
	
	Resources = New Array;
	
	Resources.Add("InitialBalanceQuantity");
	Resources.Add("InitialBalanceCost");
	Resources.Add("InitialBalanceOfPD");
	Resources.Add("InitialBalanceOfTD");
	Resources.Add("InitialBalanceOffBalanceSheet");
	
	Resources.Add("ReceivedQuantity");
	Resources.Add("ReceivedCost");
	Resources.Add("ReceivedPD");
	Resources.Add("TDHasBeenReceived");
	Resources.Add("ReceivedOffBalanceSheet");
	
	Resources.Add("PurchasedQuantity_");
	Resources.Add("PurchasedValue");
	Resources.Add("PurchasedPD");
	Resources.Add("AcquiredByTD");
	Resources.Add("PurchasedOffBalanceSheet");
	
	Resources.Add("MovementsQuantity");
	Resources.Add("MovingCost");
	Resources.Add("PDMovements");
	Resources.Add("TDMovements");
	Resources.Add("OffBalanceSheetTransfers");
	
	Resources.Add("InclusionExclusionOfVAT");
	
	Resources.Add("AmountSpentOnProduction");
	Resources.Add("SpentOnProductionCost");
	Resources.Add("SpentOnProductionOfPD");
	Resources.Add("SpentOnProductionOfTD");
	Resources.Add("SpentOnProductionOffBalanceSheet");
	
	Resources.Add("DebitedQuantity");
	Resources.Add("DebitedCost");
	Resources.Add("WrittenOffPD");
	Resources.Add("TDWasWrittenOff");
	Resources.Add("WrittenOffOffBalanceSheet");
	
	Resources.Add("FinalRemainderQuantity");
	Resources.Add("FinalRemainderCost");
	Resources.Add("FinalBalanceOfPD");
	Resources.Add("FinalBalanceOfTD");
	Resources.Add("FinalBalanceIsOffBalance");
	
	Resources.Add("QuantityTransmitted");
	Resources.Add("TransferredCost");
	Resources.Add("SubmittedByPD");
	Resources.Add("SubmittedByTD");
	Resources.Add("PassedOffBalanceSheet");
	
	Resources.Add("ProducedQuantity");
	Resources.Add("ProducedCost");
	Resources.Add("ProducedByPD");
	Resources.Add("ProducedByTD");
	Resources.Add("ProducedOffBalanceSheet");
	
	Return New Structure("QueryText, Resources", QueryText, Resources);
	
EndFunction

// The Query Text production costs are article-by-article.
// 
// Returns:
//  Structure -  Query Text and resource set:
// * QueryText - String - Query text
// * Resources - Array of String - Set of request resources
Function QueryTextItemizedProductionCosts() Export
	
	QueryText =
	"SELECT ALLOWED
	|	DD.Table                                             AS Table,
	|	DD.Content                                          AS Content,
	|	DD.Organization                                         AS Organization,
	|	DD.Department                                       AS Department,
	|	DD.Sender                                         AS Sender,
	|	DD.Recipient                                          AS Recipient,
	|	DD.Recorder                                         AS Recorder,
	|	DD.ExpenseItem                                      AS ExpenseItem,
	|	DD.DimensionOfExpenses                                   AS DimensionOfExpenses,
	|	DD.LineOfBusiness                             AS LineOfBusiness,
	|	DD.ProductionLot                                  AS ProductionLot,
	|	DD.ProductionOrder                                 AS ProductionOrder,
	|	SUM(DD.InitialBalanceCost)                   AS InitialBalanceCost,
	|	SUM(DD.InitialBalanceOfPD)                          AS InitialBalanceOfPD,
	|	SUM(DD.InitialBalanceOfTD)                          AS InitialBalanceOfTD,
	|	SUM(DD.ReceivedCost)                          AS ReceivedCost,
	|	SUM(DD.ReceivedPD)                                 AS ReceivedPD,
	|	SUM(DD.TDHasBeenReceived)                                 AS TDHasBeenReceived,
	|	SUM(DD.SpentOnProductionCost)        AS SpentOnProductionCost,
	|	SUM(DD.SpentOnProductionOfPD)               AS SpentOnProductionOfPD,
	|	SUM(DD.SpentOnProductionOfTD)               AS SpentOnProductionOfTD,
	|	SUM(DD.OtherWriteOffCost)               	   AS OtherWriteOffCost,
	|	SUM(DD.OtherWriteOffOfPD)               	           AS OtherWriteOffOfPD,
	|	SUM(DD.OtherWriteOffsOfTD)               	           AS OtherWriteOffsOfTD,
	|	SUM(DD.TransitBetweenHIACost)               	   AS TransitBetweenHIACost,
	|	SUM(DD.TransitBetweenOVZPR)               	           AS TransitBetweenOVZPR,
	|	SUM(DD.TransitBetweenHIA_)               	           AS TransitBetweenHIA_,
	|	SUM(DD.FinalRemainderCost)                    AS FinalRemainderCost,
	|	SUM(DD.FinalBalanceOfPD)                           AS FinalBalanceOfPD,
	|	SUM(DD.FinalBalanceOfTD)                           AS FinalBalanceOfTD
	|{SELECT
	|Table,
	|Content,
	|Organization.*,
	|Department.*,
	|Sender.*,
	|Recipient.*,
	|Recorder.*,
	|ExpenseItem.*,
	|DimensionOfExpenses.*,
	|LineOfBusiness.*,
	|ProductionLot.*,
	|ProductionOrder.*,
	|InitialBalanceCost,
	|InitialBalanceOfPD,
	|InitialBalanceOfTD,
	|ReceivedCost,
	|ReceivedPD,
	|TDHasBeenReceived,
	|SpentOnProductionCost,
	|SpentOnProductionOfPD,
	|SpentOnProductionOfTD,
	|OtherWriteOffCost,
	|OtherWriteOffOfPD,
	|OtherWriteOffsOfTD,
	|TransitBetweenHIACost,
	|TransitBetweenOVZPR,
	|TransitBetweenHIA_,
	|FinalRemainderCost,
	|FinalBalanceOfPD,
	|FinalBalanceOfTD}
	|	
	|FROM
	|
	|(SELECT
	|	&Itemized                                           AS Table,
	|	&OpeningBalance                                      AS Content,
	|	DD.Organization                                         AS Organization,
	|	DD.Department                                       AS Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Sender,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Recipient,
	|	CASE
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionStage2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|		ELSE UNDEFINED
	|	END                                                  AS Recorder,
	|	DD.ExpenseItem                                      AS ExpenseItem,
	|	DD.DimensionOfExpenses                                   AS DimensionOfExpenses,
	|	DD.LineOfBusiness                             AS LineOfBusiness,
	|	UNDEFINED                                           AS ProductionLot,
	|	UNDEFINED                                           AS ProductionOrder,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.SumBalance
	|		WHEN &Cost_Data = 2
	|			THEN DD.AmountExcludingVATBalance
	|		WHEN &Cost_Data = 3
	|			THEN DD.SumManBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.SumComplBalance
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.AmountExcludingVATBalance
	|			ELSE
	|				DD.SumManBalance
	|			END
	|	END                                                  AS InitialBalanceCost,
	|	DD.PermanentDifferenceBalance                            AS InitialBalanceOfPD,
	|	DD.CostTDBalance                             AS InitialBalanceOfTD,
	|	0                                                      AS ReceivedCost,
	|	0                                                      AS ReceivedPD,
	|	0                                                      AS TDHasBeenReceived,
	|	0                                                      AS SpentOnProductionCost,
	|	0                                                      AS SpentOnProductionOfPD,
	|	0                                                      AS SpentOnProductionOfTD,
	|	0                                                      AS OtherWriteOffCost,
	|	0                                                      AS OtherWriteOffOfPD,
	|	0                                                      AS OtherWriteOffsOfTD,
	|	0                                                      AS TransitBetweenHIACost,
	|	0                                                      AS TransitBetweenOVZPR,
	|	0                                                      AS TransitBetweenHIA_,
	|	0                                                      AS FinalRemainderCost,
	|	0                                                      AS FinalBalanceOfPD,
	|	0                                                      AS FinalBalanceOfTD
	|FROM
	|	AccumulationRegister.OtherExpenses.Balance(
	|		{(&BeginOfPeriod)},
	|		NOT &NoSelectionByStartPeriod
	|		AND (ExpenseItem IN (
	|			SELECT Ref 
	|			FROM ChartOfCharacteristicTypes.ExpenseItems AS Setting
	|			WHERE 
	|				Setting.CostAllocationOptionLocal 
	|					IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|						VALUE(Enum.CostAllocationOptions.ToCostCenters),
	|						VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|				OR Setting.CostAllocationOptionManag 
	|					IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|						VALUE(Enum.CostAllocationOptions.ToCostCenters),
	|						VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			)
	|		OR DimensionOfExpenses IN (
	|			SELECT Ref 
	|			FROM Catalog.CostCenters AS Setting
	|			WHERE 
	|				Setting.CostAllocationOptionLocal 
	|					IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|						VALUE(Enum.CostAllocationOptions.ToCostCenters),
	|						VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|				OR Setting.CostAllocationOptionManag 
	|					IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|						VALUE(Enum.CostAllocationOptions.ToCostCenters),
	|						VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			)
	|		)
	|		{
	|			Organization,
	|			Department,
	|			LineOfBusiness,
	|			ExpenseItem,
	|			DimensionOfExpenses
	|		}
	|	) AS DD
	|
	|UNION ALL
	|
	|SELECT
	|	&Itemized AS Table,
	|	&Registration AS Content,
	|	DD.Organization,
	|	DD.Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef),
	|	DD.Department,
	|	DD.Recorder,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.LineOfBusiness,
	|	UNDEFINED,
	|	UNDEFINED,
	|	0,
	|	0,
	|	0,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Sum
	|		WHEN &Cost_Data = 2
	|			THEN DD.AmountExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.SumMan
	|		WHEN &Cost_Data = 4
	|			THEN DD.SumCompl
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.AmountExcludingVAT
	|			ELSE
	|				DD.SumMan
	|			END
	|	END,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			AND NOT AssetRef.EnteredInTaxAccounting
	|			THEN DD.SumCompl
	|		ELSE
	|			0
	|	END,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			AND AssetRef.EnteredInTaxAccounting
	|			THEN DD.SumCompl
	|		ELSE
	|			0
	|	END,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.OtherExpenses AS DD
	|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
	|		ON DD.ExpenseItem = AssetRef.Ref
	|	LEFT JOIN Catalog.CostCenters AS ConstCenter
	|		ON DD.DimensionOfExpenses = ConstCenter.Ref
	|WHERE
	|	(&WithoutFilterByPeriod OR (&NoSelectionByStartPeriod OR DD.Period >= &BeginOfPeriod) AND DD.Period <= &PeriodEnding)
	|	AND	(ISNULL(ConstCenter.CostAllocationOptionLocal, AssetRef.CostAllocationOptionLocal) 
	|			IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|				VALUE(Enum.CostAllocationOptions.ToCostCenters), 
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|		OR ISNULL(ConstCenter.CostAllocationOptionManag, AssetRef.CostAllocationOptionManag) 
	|			IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|				VALUE(Enum.CostAllocationOptions.ToCostCenters), 
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|		)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|{ WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Itemized AS Table,
	|	&Registration AS Content,
	|	DD.Organization,
	|	DD.Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef),
	|	DD.Department,
	|	DD.Recorder,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.LineOfBusiness,
	|	UNDEFINED,
	|	UNDEFINED,
	
	|	0,
	|	0,
	|	0,
	
	|	0,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			AND NOT AssetRef.EnteredInTaxAccounting
	|			THEN DD.PermanentDifference - DD.SumCompl
	|		ELSE
	|			DD.PermanentDifference
	|	END,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			AND AssetRef.EnteredInTaxAccounting
	|			THEN DD.CostTD - DD.SumCompl
	|		ELSE
	|			DD.CostTD
	|	END,
	
	|	0,
	|	0,
	|	0,
	
	|	0,
	|	0,
	|	0,
	
	|	0,
	|	0,
	|	0,
	
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.OtherExpenses AS DD
	|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
	|		ON DD.ExpenseItem = AssetRef.Ref
	|	LEFT JOIN Catalog.CostCenters AS ConstCenter
	|		ON DD.DimensionOfExpenses = ConstCenter.Ref
	|WHERE
	|	(&WithoutFilterByPeriod OR (&NoSelectionByStartPeriod OR DD.Period >= &BeginOfPeriod) AND DD.Period <= &PeriodEnding)
	|	AND	(ISNULL(ConstCenter.CostAllocationOptionTax, AssetRef.CostAllocationOptionTax) 
	|			IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|				VALUE(Enum.CostAllocationOptions.ToCostCenters), 
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|		)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|{ WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Itemized AS Table,
	|	&DistributionToProduction AS Content,
	|	DD.Organization,
	|	Attributes.Department,
	|	Attributes.Department,
	|	DD.Department,
	|	DD.Recorder,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	Attributes.LineOfBusiness,
	|	CASE
	|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|			THEN DD.ProductionLot
	|		ELSE DD.ProductionOrder
	|	END,
	|	CASE
	|		WHEN CatProductionLots.Document IS NOT NULL
	|			AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT
	|			ELSE
	|				DD.CostMan
	|			END
	|	END,
	|	DD.PermanentDifference,
	|	DD.CostTD,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses AS DD
	|		LEFT JOIN Document.AllocationOfOtherCosts AS Attributes
	|		ON DD.Recorder = Attributes.Ref
	|
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|
	|WHERE
	|	(&WithoutFilterByPeriod OR (&NoSelectionByStartPeriod OR DD.Period >= &BeginOfPeriod) AND DD.Period <= &PeriodEnding)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|{ WHERE
	|	DD.Organization AS Organization,
	|	Attributes.Department AS Department,
	|	Attributes.LineOfBusiness AS LineOfBusiness,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Itemized AS Table,
	|	&Disposal AS Content,
	|	DD.Organization,
	|	DD.Department,
	|	DD.Department,
	|	DD.CorExpenseItem,
	|	DD.Recorder,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.LineOfBusiness,
	|	UNDEFINED,
	|	UNDEFINED,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Sum
	|		WHEN &Cost_Data = 2
	|			THEN DD.AmountExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.SumMan
	|		WHEN &Cost_Data = 4
	|			THEN DD.SumCompl
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.AmountExcludingVAT
	|			ELSE
	|				DD.SumMan
	|			END
	|	END,
	|	DD.PermanentDifference,
	|	DD.CostTD,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.OtherExpenses AS DD
	|	LEFT JOIN Catalog.CostCenters AS ConstCenter
	|		ON DD.DimensionOfExpenses = ConstCenter.Ref
	|WHERE
	|	(&WithoutFilterByPeriod OR (&NoSelectionByStartPeriod OR DD.Period >= &BeginOfPeriod) AND DD.Period <= &PeriodEnding)
	|	AND	(ISNULL(ConstCenter.CostAllocationOptionLocal, DD.ExpenseItem.CostAllocationOptionLocal) 
	|			IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect), 
	|				VALUE(Enum.CostAllocationOptions.ToCostCenters))
	|		OR ISNULL(ConstCenter.CostAllocationOptionManag, DD.ExpenseItem.CostAllocationOptionManag) 
	|			IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect), 
	|				VALUE(Enum.CostAllocationOptions.ToCostCenters))
	|		)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|		VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters))
	|{ WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Itemized AS Table,
	|	&Transfer AS Content,
	|	DD.Organization,
	|	DD.Department,
	|	DD.DimensionOfExpenses,
	|	DD.CorExpenditureDimension,
	|	DD.Recorder,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.LineOfBusiness,
	|	UNDEFINED,
	|	UNDEFINED,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Sum
	|		WHEN &Cost_Data = 2
	|			THEN DD.AmountExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.SumMan
	|		WHEN &Cost_Data = 4
	|			THEN DD.SumCompl
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.AmountExcludingVAT
	|			ELSE
	|				DD.SumMan
	|			END
	|	END,
	|	DD.PermanentDifference,
	|	DD.CostTD,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.OtherExpenses AS DD
	|	LEFT JOIN Catalog.CostCenters AS ConstCenter
	|		ON DD.DimensionOfExpenses = ConstCenter.Ref
	|WHERE
	|	(&WithoutFilterByPeriod OR (&NoSelectionByStartPeriod OR DD.Period >= &BeginOfPeriod) AND DD.Period <= &PeriodEnding)
	|	AND (ISNULL(ConstCenter.CostAllocationOptionLocal, DD.ExpenseItem.CostAllocationOptionLocal) = VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|					OR ISNULL(ConstCenter.CostAllocationOptionManag, DD.ExpenseItem.CostAllocationOptionManag) = VALUE(Enum.CostAllocationOptions.ToCostCenters))
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
	|{ WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Itemized AS Table,
	|	&ClosingBalance AS Content,
	|	DD.Organization,
	|	DD.Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef),
	|	VALUE(Catalog.BusinessStructure.EmptyRef),
	|	UNDEFINED,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.LineOfBusiness,
	|	UNDEFINED,
	|	UNDEFINED,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.SumBalance
	|		WHEN &Cost_Data = 2
	|			THEN DD.AmountExcludingVATBalance
	|		WHEN &Cost_Data = 3
	|			THEN DD.SumManBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.SumComplBalance
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.AmountExcludingVATBalance
	|			ELSE
	|				DD.SumManBalance
	|			END
	|	END,
	|	DD.PermanentDifferenceBalance,
	|	DD.CostTDBalance
	|FROM
	|	AccumulationRegister.OtherExpenses.Balance(
	|		{(&EndOfPeriodLimit)},
	|		ExpenseItem IN (
	|			SELECT Ref 
	|			FROM ChartOfCharacteristicTypes.ExpenseItems AS Setting
	|			WHERE 
	|				Setting.CostAllocationOptionLocal 
	|					IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|						VALUE(Enum.CostAllocationOptions.ToCostCenters),
	|						VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|				OR Setting.CostAllocationOptionManag 
	|					IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|						VALUE(Enum.CostAllocationOptions.ToCostCenters),
	|						VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			)
	|		OR DimensionOfExpenses IN (
	|			SELECT Ref 
	|			FROM Catalog.CostCenters AS Setting
	|			WHERE 
	|				Setting.CostAllocationOptionLocal 
	|					IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|						VALUE(Enum.CostAllocationOptions.ToCostCenters),
	|						VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|				OR Setting.CostAllocationOptionManag 
	|					IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
	|						VALUE(Enum.CostAllocationOptions.ToCostCenters),
	|						VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			)
	|	) AS DD
	|{ WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses
	|}
	|) AS DD
	|
	|GROUP BY
	|
	|	DD.Table,
	|	DD.Content,
	|	DD.Organization,
	|	DD.Department,
	|	DD.Sender,
	|	DD.Recipient,
	|	DD.Recorder,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.LineOfBusiness,
	|	DD.ProductionLot,
	|	DD.ProductionOrder";
	
	Resources = New Array;
	Resources.Add("InitialBalanceCost");
	Resources.Add("InitialBalanceOfPD");
	Resources.Add("InitialBalanceOfTD");
	
	Resources.Add("ReceivedCost");
	Resources.Add("ReceivedPD");
	Resources.Add("TDHasBeenReceived");
	
	Resources.Add("SpentOnProductionCost");
	Resources.Add("SpentOnProductionOfPD");
	Resources.Add("SpentOnProductionOfTD");
	
	Resources.Add("OtherWriteOffCost");
	Resources.Add("OtherWriteOffOfPD");
	Resources.Add("OtherWriteOffsOfTD");
	
	Resources.Add("TransitBetweenHIACost");
	Resources.Add("TransitBetweenOVZPR");
	Resources.Add("TransitBetweenHIA_");
	
	Resources.Add("FinalRemainderCost");
	Resources.Add("FinalBalanceOfPD");
	Resources.Add("FinalBalanceOfTD");
	
	Return New Structure("QueryText, Resources", QueryText, Resources);
	
EndFunction

// Query Text production costs by production batch.
// 
// Returns:
//  Structure -  Query Text and resource set:
// * QueryText - String - Query text
// * Resources - Array of String - Set of request resources
//
Function QueryTextProductionCostsByProductionLots() Export
	
	QueryText = "
	|SELECT DISTINCT
	|	DD.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	DD.FinRecordID AS FinRecordID,
	|	CorDimension.ProductCostElement.ExpenseType AS ExpenseType,
	|	CatCompanies.Ref AS Organization,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(CorDimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE CorDimension.StorageLocation
	|	END AS Department,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	ISNULL(CatProductionLots.LineOfBusiness, CorDimension.Purpose.LineOfBusiness) AS LineOfBusiness,
	|	CorDimension.ProductCostElement AS ProductCostElement,
	|	DD.CorItemsLocationAttributes AS ItemsLocationAttributes,
	|	CorDimension.Products AS Products,
	|	CorDimension.Characteristic AS Characteristic,
	|	CorDimension.Series AS Series,
	|	CorDimension.Purpose AS Purpose,
	|	DD.CorLot AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder
	|INTO TTAnalyticsForGNZPReceipts
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		INNER JOIN Catalog.Companies AS CatCompanies
	|			ON CASE WHEN DD.CorCompany = VALUE(Catalog.Companies.EmptyRef)
	|					THEN DD.Organization = CatCompanies.Ref
	|					ELSE DD.CorCompany = CatCompanies.Ref
	|				END
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON (DD.ItemsLocationAttributes = Dimension.Ref)
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS CorDimension
	|		ON (DD.CorItemsLocationAttributes = CorDimension.Ref)
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON (CatProductionLots.Ref = DD.CorLot)
	|			AND (CatProductionLots.Organization = CatCompanies.Ref OR NOT &ByEnterprise)
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND CorDimension.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|{WHERE
	|	(CatCompanies.Ref) AS Organization,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(CorDimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE CorDimension.StorageLocation
	|	END AS Department,
	|	CorDimension.Products AS Products,
	|	CorDimension.Characteristic AS Characteristic}  
	|INDEX BY
	|	Recorder,
	|	FinRecordID,
	|	BusinessTransactionSetting,
	|	Organization
	|;
	|
	|SELECT ALLOWED
	|	DD.Table                                AS Table,
	|	DD.Content                             AS Content,
	|	DD.ExpenseType                              AS ExpenseType,
	|	DD.CostKind                              AS CostKind,
	|	DD.Organization                            AS Organization,
	|	DD.Department                          AS Department,
	|	DD.SendingDepartment               AS SendingDepartment,
	|	DD.Recorder                            AS Recorder,
	|	DD.LineOfBusiness                AS LineOfBusiness,
	|	DD.ProductCostElement                      AS ProductCostElement,
	|	
	|	// material analysis
	|	DD.ItemsLocationAttributes             AS ItemsLocationAttributes,
	|	DD.Products                           AS Products,
	|	DD.Characteristic                         AS Characteristic,
	|	DD.Series                                  AS Series,
	|	DD.Purpose                             AS Purpose,
	|	
	|	// labor cost analytics
	|	DD.WorkKind                               AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	DD.ExpenseItem                         AS ExpenseItem,
	|	DD.DimensionOfExpenses                      AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	DD.ProductsAccountingDimension                AS ProductsAccountingDimension,
	|	DD.ManufacturedProduct                              AS ManufacturedProduct,
	|	DD.ItemVariant                AS ItemVariant,
	|	DD.ProductionSeries_                         AS ProductionSeries_,
	|	DD.AssignmentOfProducts                    AS AssignmentOfProducts,
	|	
	|	DD.ProductionLot                     AS ProductionLot,
	|	DD.ProductionOrder                    AS ProductionOrder,
	|	SUM(DD.InitialBalanceQuantity)     AS InitialBalanceQuantity,
	|	SUM(DD.InitialBalanceCost)      AS InitialBalanceCost,
	|	SUM(DD.InitialBalanceOfPD)             AS InitialBalanceOfPD,
	|	SUM(DD.InitialBalanceOfTD)             AS InitialBalanceOfTD,
	|	SUM(DD.InitialBalanceOffBalanceSheet)   AS InitialBalanceOffBalanceSheet,
	|	
	|	SUM(DD.AmountSpentOnProduction) AS AmountSpentOnProduction,
	|	SUM(DD.SpentOnProductionCost)  AS SpentOnProductionCost,
	|	SUM(DD.SpentOnProductionOfPD)         AS SpentOnProductionOfPD,
	|	SUM(DD.SpentOnProductionOfTD)         AS SpentOnProductionOfTD,
	|	SUM(DD.SpentOnProductionOffBalanceSheet) AS SpentOnProductionOffBalanceSheet,
	|	
	|	SUM(DD.InclusionExclusionOfVAT)         AS InclusionExclusionOfVAT,
	|	
	|	SUM(DD.ProductionCostsQuantity) AS ProductionCostsQuantity,
	|	SUM(DD.ProductionCostsCost)  AS ProductionCostsCost,
	|	SUM(DD.CostOfProductionPD)         AS CostOfProductionPD,
	|	SUM(DD.CostOfProductionOfTD)         AS CostOfProductionOfTD,
	|	SUM(DD.ProductionCostsOffBalanceSheet)AS ProductionCostsOffBalanceSheet,
	|	
	|	SUM(DD.FinalRemainderQuantity)      AS FinalRemainderQuantity,
	|	SUM(DD.FinalRemainderCost)       AS FinalRemainderCost,
	|	SUM(DD.FinalBalanceOfPD)              AS FinalBalanceOfPD,
	|	SUM(DD.FinalBalanceOfTD)              AS FinalBalanceOfTD,
	|	SUM(DD.FinalBalanceIsOffBalance)    AS FinalBalanceIsOffBalance
	|{SELECT
	|Table,
	|Content,
	|ExpenseType.*,
	|CostKind,
	|Organization.*,
	|Department.*,
	|SendingDepartment.*,
	|Recorder.*,
	|LineOfBusiness.*,
	|ProductCostElement.*,
	|ItemsLocationAttributes.*,
	|Products.*,
	|Characteristic.*,
	|Series.*,
	|Purpose.*,
	|WorkKind.*,
	|ExpenseItem.*,
	|DimensionOfExpenses.*,
	|ProductsAccountingDimension.*,
	|ManufacturedProduct.*,
	|ItemVariant.*,
	|ProductionSeries_.*,
	|AssignmentOfProducts.*,
	|ProductionLot.*,
	|ProductionOrder.*,
	|InitialBalanceQuantity,
	|InitialBalanceCost,
	|InitialBalanceOfPD,
	|InitialBalanceOfTD,
	|InitialBalanceOffBalanceSheet,
	|AmountSpentOnProduction,
	|SpentOnProductionCost,
	|SpentOnProductionOfPD,
	|SpentOnProductionOfTD,
	|SpentOnProductionOffBalanceSheet,
	|InclusionExclusionOfVAT,
	|ProductionCostsQuantity,
	|ProductionCostsCost,
	|CostOfProductionPD,
	|CostOfProductionOfTD,
	|ProductionCostsOffBalanceSheet,
	|FinalRemainderQuantity,
	|FinalRemainderCost,
	|FinalBalanceOfPD,
	|FinalBalanceOfTD,
	|FinalBalanceIsOffBalance}
	|FROM
	// UsedMaterials
	|(SELECT
	|	&Production AS Table,
	|	&OpeningBalance AS Content,
	|	Dimension.ProductCostElement.ExpenseType AS ExpenseType,
	|	CASE 
	|		WHEN Dimension.ProductCostElement.ExpenseType IN (
	|			VALUE(Enum.CostTypes.Material_),
	|			VALUE(Enum.CostTypes.RecyclableWaste))
	|			THEN &Material_
	|		ELSE
	|			&Services
	|	END AS CostKind,
	|	DD.Organization AS Organization,
	|	Dimension.Department AS Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS SendingDepartment,
	|	UNDEFINED AS Recorder,
	|	ISNULL(CatProductionLots.LineOfBusiness,
	|		Dimension.Purpose.LineOfBusiness) AS LineOfBusiness,
	|	Dimension.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|	
	|	DD.Lot AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	DD.CountBalance        AS InitialBalanceQuantity,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.CostBalance + DD.AddExpensesForGoodsBalance + DD.LaborCostsBalance + DD.ItemizedFixedCostsIncludingVATBalance + DD.ItemizedVariableCostsIncludingVATBalance
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVATBalance + DD.AdditionalExpensesExcludingVATBalance + DD.LaborCostsBalance + DD.ItemizedFixedCostsExcludingVATBalance + DD.ItemizedVariableCostsExcludingVATBalance
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostManBalance + DD.AddExpensesManBalance + DD.LaborCostsManBalance + DD.ItemizedFixedCostsManagBalance + DD.ItemizedVariableCostsManagBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCostBalance + DD.AddExpensesLocalBalance + DD.LaborCostsLocalBalance + DD.ItemizedFixedCostsComplBalance + DD.ItemizedVariableCostsComplBalance
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVATBalance + DD.AdditionalExpensesExcludingVATBalance + DD.LaborCostsBalance + DD.ItemizedFixedCostsExcludingVATBalance + DD.ItemizedVariableCostsExcludingVATBalance
	|			ELSE
	|				DD.CostManBalance + DD.AddExpensesManBalance + DD.LaborCostsManBalance + DD.ItemizedFixedCostsManagBalance + DD.ItemizedVariableCostsManagBalance
	|			END
	|	END                       AS InitialBalanceCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifferenceBalance
	|			ELSE 0
	|		END
	|	AS InitialBalanceOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTDBalance
	|			ELSE 0
	|		END
	|	AS InitialBalanceOfTD,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN DD.OffBalanceCostBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.OffBalanceCostLocalBalance
	|	END                       AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(
	|			{(&BeginOfPeriod)},
	|			NOT &WithoutFilterByPeriod
	|				AND ItemsLocationAttributes.StorageType IN (
	|					VALUE(Enum.StorageLocationTypes.Department),
	|					VALUE(Enum.StorageLocationTypes.CounterpartyContract))
	|				AND (ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|			)
	|			{
	|				Organization AS Organization,
	|				ItemsLocationAttributes.Department AS Department,
	|				ItemsLocationAttributes.Products AS Products,
	|				ItemsLocationAttributes.Characteristic AS Characteristic
	|			}
	|			) AS DD
	|
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.Lot
	|			AND (CatProductionLots.Organization = DD.Organization OR NOT &ByEnterprise)
	|
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ReceivedMaterials22 AS Content,
	|	DD.ExpenseType AS ExpenseType,
	|	&Material_ AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.SendingDepartment AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|
	|	// material analysis
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DD.Products AS Products,
	|	DD.Characteristic AS Characteristic,
	|	DD.Series AS Series,
	|	DD.Purpose AS Purpose,
	|
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|	DD.ProductionLot AS ProductionLot,
	|	DD.ProductionOrder AS ProductionOrder,
	|
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	RegisterRecordsReceipt.Count AS AmountSpentOnProduction,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN RegisterRecordsReceipt.Cost + RegisterRecordsReceipt.AddExpensesForGoods + RegisterRecordsReceipt.LaborCosts + RegisterRecordsReceipt.ItemizedFixedCostsIncludingVAT + RegisterRecordsReceipt.ItemizedVariableCostsIncludingVAT
	|		WHEN &Cost_Data = 2
	|			THEN RegisterRecordsReceipt.CostExcludingVAT + RegisterRecordsReceipt.AdditionalExpensesExcludingVAT + RegisterRecordsReceipt.LaborCosts + RegisterRecordsReceipt.ItemizedFixedCostsExcludingVAT + RegisterRecordsReceipt.ItemizedVariableCostsExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN RegisterRecordsReceipt.CostMan + RegisterRecordsReceipt.AddExpensesMan + RegisterRecordsReceipt.LaborCostsMan + RegisterRecordsReceipt.ItemizedFixedCostsManag + RegisterRecordsReceipt.ItemizedVariableCostsManag
	|		WHEN &Cost_Data = 4
	|			THEN RegisterRecordsReceipt.LocalCost + RegisterRecordsReceipt.AddExpensesLocal + RegisterRecordsReceipt.LaborCostsLocal + RegisterRecordsReceipt.ItemizedFixedCostsCompl + RegisterRecordsReceipt.ItemizedVariableCostsCompl
	|		ELSE CASE
	|				WHEN &ByEnterprise
	|					THEN RegisterRecordsReceipt.CostExcludingVAT + RegisterRecordsReceipt.AdditionalExpensesExcludingVAT + RegisterRecordsReceipt.LaborCosts + RegisterRecordsReceipt.ItemizedFixedCostsExcludingVAT + RegisterRecordsReceipt.ItemizedVariableCostsExcludingVAT
	|				ELSE RegisterRecordsReceipt.CostMan + RegisterRecordsReceipt.AddExpensesMan + RegisterRecordsReceipt.LaborCostsMan + RegisterRecordsReceipt.ItemizedFixedCostsManag + RegisterRecordsReceipt.ItemizedVariableCostsManag
	|			END
	|	END AS SpentOnProductionCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN RegisterRecordsReceipt.PermanentDifference
	|		ELSE 0
	|	END AS SpentOnProductionOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN RegisterRecordsReceipt.CostTD
	|		ELSE 0
	|	END AS SpentOnProductionOfTD,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2
	|				OR &Cost_Data = 3
	|			THEN RegisterRecordsReceipt.OffBalanceCost
	|		WHEN &Cost_Data = 4
	|			THEN RegisterRecordsReceipt.OffBalanceCostLocal
	|	END AS SpentOnProductionOffBalanceSheet,
	|	0 AS InclusionExclusionOfVAT,
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	TTAnalyticsForGNZPReceipts AS DD
	|		INNER JOIN AccumulationRegister.InventoryCost AS RegisterRecordsReceipt
	|		ON DD.Recorder = RegisterRecordsReceipt.Recorder
	|			AND DD.FinRecordID = RegisterRecordsReceipt.FinRecordID
	|			AND DD.BusinessTransactionSetting = RegisterRecordsReceipt.BusinessTransactionSetting
	|			AND (RegisterRecordsReceipt.RecordType = VALUE(AccumulationRecordType.Receipt))
	|			AND (DD.Organization = RegisterRecordsReceipt.Organization)
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&InclusionExclusionOfVAT AS Content,
	|	Dimension.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Material_ AS CostKind,
	|	DD.Organization AS Organization,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS Department,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	ISNULL(CatProductionLots.LineOfBusiness,
	|		Dimension.Purpose.LineOfBusiness) AS LineOfBusiness,
	|	Dimension.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	DD.Lot AS ProductionLot,
	|	CASE
	|		WHEN CatProductionLots.Document IS NOT NULL
	|			AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost + DD.AddExpensesForGoods + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan + DD.AddExpensesMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost + DD.AddExpensesLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|			ELSE
	|				DD.CostMan + DD.AddExpensesMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|			END
	|	END AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|			ON DD.ItemsLocationAttributes = Dimension.Ref
	|
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.Lot
	|
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|	AND DD.EntryType = VALUE(Enum.LotRecordTypes.InclusionExclusionOfVATInCost)
	|	AND (NOT &ByEnterprise
	|		OR CatProductionLots.Organization IS NULL
	|		OR CatProductionLots.Organization = DD.Organization)
	|{ WHERE
	|	DD.Organization AS Organization,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS Department,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&InclusionExclusionOfVAT AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Itemized AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	Attributes.Department AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	// analysis of item-by-item expense
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	CASE
	|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|			THEN DD.ProductionLot
	|		ELSE UNDEFINED
	|	END AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT
	|			ELSE
	|				DD.CostMan
	|			END
	|	END AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses AS DD
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|			AND (CatProductionLots.Organization = DD.Organization OR NOT &ByEnterprise)
	|
	|		LEFT JOIN Document.AllocationOfOtherCosts AS Attributes
	|		ON DD.Recorder = Attributes.Ref
	|
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND DD.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.InclusionExclusionOfVATInCost)
	|{WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ReceivedMaterials21 AS Content,
	|	CorDimension.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Material_ AS CostKind,
	|	DD.Organization AS Organization,
	|	CorDimension.StorageLocation AS Department,
	|	Dimension.StorageLocation AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	CorDimension.Purpose.LineOfBusiness AS LineOfBusiness,
	|	CorDimension.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	DD.CorItemsLocationAttributes AS ItemsLocationAttributes,
	|	CorDimension.Products AS Products,
	|	CorDimension.Characteristic AS Characteristic,
	|	CorDimension.Series AS Series,
	|	CorDimension.Purpose AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	DD.CorLot AS ProductionLot,
	|	DD.CorLot AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	DD.Count AS AmountSpentOnProduction,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|			ELSE
	|				DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|			END
	|	END AS SpentOnProductionCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|			ELSE 0
	|		END AS SpentOnProductionOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|			ELSE 0
	|		END AS SpentOnProductionOfTD,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN DD.OffBalanceCost
	|		WHEN &Cost_Data = 4
	|			THEN DD.OffBalanceCostLocal
	|	END AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|			ON DD.ItemsLocationAttributes = Dimension.Ref
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS CorDimension
	|			ON DD.CorItemsLocationAttributes = CorDimension.Ref
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|			ON CatProductionLots.Ref = DD.CorLot
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND (
	|		(DD.Recorder REFS Document.ProductionCostAllocation AND NOT CAST(DD.Recorder AS Document.ProductionCostAllocation).NewProduction)
	|		)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND (NOT &ByEnterprise
	|		OR CatProductionLots.Organization IS NULL
	|		OR CatProductionLots.Organization = DD.Organization)
	|	
	|{ WHERE
	|	DD.Organization AS Organization,
	|	CorDimension.StorageLocation AS Department,
	|	CorDimension.Products AS Products,
	|	CorDimension.Characteristic AS Characteristic
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ReceivedWaste AS Content,
	|	Dimension.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Material_ AS CostKind,
	|	DD.Organization AS Organization,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS Department,
	|	CASE
	|		WHEN VALUETYPE(CorDimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(CorDimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE CorDimension.StorageLocation
	|	END AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	ISNULL(CatProductionLots.LineOfBusiness,
	|		Dimension.Purpose.LineOfBusiness) AS LineOfBusiness,
	|	Dimension.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	DD.Lot AS ProductionLot,
	|	CASE
	|		WHEN CatProductionLots.Document IS NOT NULL
	|			AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	DD.Count AS AmountSpentOnProduction,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|			ELSE
	|				DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|			END
	|	END AS SpentOnProductionCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|			ELSE 0
	|		END AS SpentOnProductionOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|			ELSE 0
	|		END AS SpentOnProductionOfTD,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN DD.OffBalanceCost
	|		WHEN &Cost_Data = 4
	|			THEN DD.OffBalanceCostLocal
	|	END AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|			ON DD.ItemsLocationAttributes = Dimension.Ref
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS CorDimension
	|			ON DD.CorItemsLocationAttributes = CorDimension.Ref
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.Lot
	|			AND (NOT &ByEnterprise OR CatProductionLots.Organization = DD.Organization)
	|
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND Dimension.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|{ WHERE
	|	DD.Organization AS Organization,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS Department,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ServicesReceived22 AS Content,
	|	Dimension.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Services AS CostKind,
	|	DD.Organization AS Organization,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS Department,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	ISNULL(CatProductionLots.LineOfBusiness,
	|		Dimension.Purpose.LineOfBusiness) AS LineOfBusiness,
	|	Dimension.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	DD.Lot AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	DD.Count AS AmountSpentOnProduction,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|			ELSE
	|				DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|			END
	|	END AS SpentOnProductionCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|			ELSE 0
	|		END AS SpentOnProductionOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|			ELSE 0
	|		END AS SpentOnProductionOfTD,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN DD.OffBalanceCost
	|		WHEN &Cost_Data = 4
	|			THEN DD.OffBalanceCostLocal
	|	END AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|			AND Dimension.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef) 
	|
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.Lot
	|			AND (CatProductionLots.Organization = DD.Organization OR NOT &ByEnterprise)
	|
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt) 
	|	AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|{ WHERE
	|	DD.Organization AS Organization,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS Department,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&Expense22 AS Content,
	|	Dimension.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Material_ AS CostKind,
	|	DD.Organization AS Organization,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS Department,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	ISNULL(CatProductionLots.LineOfBusiness,
	|		Dimension.Purpose.LineOfBusiness) AS LineOfBusiness,
	|	Dimension.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	DD.CorItemsLocationAttributes AS ProductsAccountingDimension,
	|	ManufacturedProductDimension.Products AS ManufacturedProduct,
	|	ManufacturedProductDimension.Characteristic AS ItemVariant,
	|	ManufacturedProductDimension.Series AS ProductionSeries_,
	|	ManufacturedProductDimension.Purpose AS AssignmentOfProducts,
	|	
	|	DD.Lot AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	DD.Count AS ProductionCostsQuantity,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost + DD.AddExpensesForGoods + DD.LaborCosts + DD.ItemizedFixedCostsIncludingVAT + DD.ItemizedVariableCostsIncludingVAT
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost + DD.AddExpensesLocal + DD.LaborCostsLocal + DD.ItemizedFixedCostsCompl + DD.ItemizedVariableCostsCompl
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT + DD.LaborCosts + DD.ItemizedFixedCostsExcludingVAT + DD.ItemizedVariableCostsExcludingVAT
	|			ELSE
	|				DD.CostMan + DD.AddExpensesMan + DD.LaborCostsMan + DD.ItemizedFixedCostsManag + DD.ItemizedVariableCostsManag
	|			END
	|	END AS ProductionCostsCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|			ELSE 0
	|		END AS CostOfProductionPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|			ELSE 0
	|		END AS CostOfProductionOfTD,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN DD.OffBalanceCost
	|		WHEN &Cost_Data = 4
	|			THEN DD.OffBalanceCostLocal
	|	END AS ProductionCostsOffBalanceSheet,
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|			AND Dimension.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.Lot
	|			AND (CatProductionLots.Organization = DD.Organization OR NOT &ByEnterprise)
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS ManufacturedProductDimension
	|		ON DD.CorItemsLocationAttributes = ManufacturedProductDimension.Ref
	|
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|{ WHERE
	|	DD.Organization AS Organization,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS Department,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ClosingBalance AS Content,
	|	Dimension.ProductCostElement.ExpenseType AS ExpenseType,
	|	CASE 
	|		WHEN Dimension.ProductCostElement.ExpenseType IN (
	|			VALUE(Enum.CostTypes.Material_),
	|			VALUE(Enum.CostTypes.RecyclableWaste))
	|			THEN &Material_
	|		ELSE
	|			&Services
	|	END AS CostKind,
	|	DD.Organization AS Organization,
	|	CASE
	|		WHEN VALUETYPE(Dimension.StorageLocation) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(Dimension.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE Dimension.StorageLocation
	|	END AS Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS SendingDepartment,
	|	UNDEFINED AS Recorder,
	|	ISNULL(CatProductionLots.LineOfBusiness,
	|		Dimension.Purpose.LineOfBusiness) AS LineOfBusiness,
	|	Dimension.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	DD.Lot AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	DD.CountBalance AS FinalRemainderQuantity,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.CostBalance + DD.AddExpensesForGoodsBalance + DD.LaborCostsBalance + DD.ItemizedFixedCostsIncludingVATBalance + DD.ItemizedVariableCostsIncludingVATBalance
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVATBalance + DD.AdditionalExpensesExcludingVATBalance + DD.LaborCostsBalance + DD.ItemizedFixedCostsExcludingVATBalance + DD.ItemizedVariableCostsExcludingVATBalance
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostManBalance + DD.AddExpensesManBalance + DD.LaborCostsManBalance + DD.ItemizedFixedCostsManagBalance + DD.ItemizedVariableCostsManagBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCostBalance + DD.AddExpensesLocalBalance + DD.LaborCostsLocalBalance + DD.ItemizedFixedCostsComplBalance + DD.ItemizedVariableCostsComplBalance
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVATBalance + DD.AdditionalExpensesExcludingVATBalance + DD.LaborCostsBalance + DD.ItemizedFixedCostsExcludingVATBalance + DD.ItemizedVariableCostsExcludingVATBalance
	|			ELSE
	|				DD.CostManBalance + DD.AddExpensesManBalance + DD.LaborCostsManBalance + DD.ItemizedFixedCostsManagBalance + DD.ItemizedVariableCostsManagBalance
	|			END
	|	END AS FinalRemainderCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifferenceBalance
	|			ELSE 0
	|		END AS FinalBalanceOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTDBalance
	|			ELSE 0
	|		END AS FinalBalanceOfTD,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN 0
	|		WHEN &Cost_Data = 2 OR &Cost_Data = 3
	|			THEN DD.OffBalanceCostBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.OffBalanceCostLocalBalance
	|	END AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(
	|			{(&EndOfPeriodLimit)},
	|			ItemsLocationAttributes.StorageType IN (
	|					VALUE(Enum.StorageLocationTypes.Department),
	|					VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|				)
	|				AND (ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
	|			)
	|			{
	|				Organization AS Organization,
	|				ItemsLocationAttributes.Department AS Department,
	|				ItemsLocationAttributes.Products AS Products,
	|				ItemsLocationAttributes.Characteristic AS Characteristic
	|			}
	|			) AS DD
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.Lot
	|			AND (CatProductionLots.Organization = DD.Organization OR NOT &ByEnterprise)
	|
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|
	|UNION ALL
	|	
	// LaborCosts
	|SELECT
	|	&Production AS Table,
	|	&InitialBalanceLaborCosts22 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&LaborCosts AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS SendingDepartment,
	|	UNDEFINED AS Recorder,
	|	CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	DD.WorkKind AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	CASE
	|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|			THEN DD.ProductionLot
	|		ELSE UNDEFINED
	|	END AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	DD.CountBalance AS InitialBalanceQuantity,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCostBalance
	|		ELSE
	|			DD.CostBalance
	|	END AS InitialBalanceCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifferenceBalance
	|		ELSE 0
	|	END AS InitialBalanceOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTDBalance
	|		ELSE 0
	|	END AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.WIPLaborCosts.Balance(
	|			{(&BeginOfPeriod)},
	|			ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|			AND (ProductionLot.Organization = Organization OR NOT &ByEnterprise)
	|			AND NOT &WithoutFilterByPeriod
	|			{
	|				Organization,
	|				Department
	|				,(CAST(ProductionLot.Document AS Document.ProductionOrder2_2)) AS ProductionOrder
	|			}
	|	) AS DD
	|
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|	
	|UNION ALL
	|	
	|SELECT
	|	&Production AS Table,
	|	&InitialBalanceLaborCosts21 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&LaborCosts AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS SendingDepartment,
	|	UNDEFINED AS Recorder,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	DD.WorkKind AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	DD.ProductionOrder AS Lot,
	|	DD.ProductionOrder AS ProductionOrder,
	|	
	|	DD.CountBalance AS InitialBalanceQuantity,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCostBalance
	|		ELSE
	|			DD.CostBalance
	|	END AS InitialBalanceCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifferenceBalance
	|		ELSE 0
	|	END AS InitialBalanceOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTDBalance
	|		ELSE 0
	|	END AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.WIPLaborCosts.Balance(
	|			{(&BeginOfPeriod)},
	|			ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
	|			AND NOT &WithoutFilterByPeriod
	|			{
	|				Organization,
	|				Department
	|			}
	|			) AS DD
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ReceivedLaborCosts22 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&LaborCosts AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.Department AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	DD.WorkKind AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	DD.ProductionLot AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	DD.Count AS AmountSpentOnProduction,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost
	|		ELSE
	|			DD.Cost
	|	END AS SpentOnProductionCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|		ELSE 0
	|	END AS SpentOnProductionOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|		ELSE 0
	|	END AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.WIPLaborCosts AS DD
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|			AND (CatProductionLots.Organization = DD.Organization OR NOT &ByEnterprise)
	|
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|{WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ReceivedLaborCosts21 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&LaborCosts AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.Department AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	CASE
	|		WHEN TRUE
	|			THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	DD.WorkKind AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	DD.ProductionOrder AS ProductionLot,
	|	DD.ProductionOrder AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	DD.Count AS AmountSpentOnProduction,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost
	|		ELSE
	|			DD.Cost
	|	END AS SpentOnProductionCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|		ELSE 0
	|	END AS SpentOnProductionOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|		ELSE 0
	|	END AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.WIPLaborCosts AS DD
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|{WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ConsumptionLaborCosts22 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&LaborCosts AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.Department AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	DD.WorkKind AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	DD.CorDimensionOfProductsAccounting AS ProductsAccountingDimension,
	|	ManufacturedProductDimension.Products AS ManufacturedProduct,
	|	ManufacturedProductDimension.Characteristic AS ItemVariant,
	|	ManufacturedProductDimension.Series AS ProductionSeries_,
	|	ManufacturedProductDimension.Purpose AS AssignmentOfProducts,
	|
	|	CASE
	|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|			THEN DD.ProductionLot
	|		ELSE UNDEFINED
	|	END AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	DD.Count AS ProductionCostsQuantity,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost
	|		ELSE
	|			DD.Cost
	|	END AS ProductionCostsCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|		ELSE 0
	|	END AS CostOfProductionPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|		ELSE 0
	|	END AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.WIPLaborCosts AS DD
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|			AND (CatProductionLots.Organization = DD.Organization OR NOT &ByEnterprise)
	|
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS ManufacturedProductDimension
	|		ON DD.CorDimensionOfProductsAccounting = ManufacturedProductDimension.Ref
	|
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|{WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ConsumptionLaborCosts21 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&LaborCosts AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.Department AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	CASE
	|		WHEN TRUE
	|			THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	DD.WorkKind AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	DD.CorDimensionOfProductsAccounting AS ProductsAccountingDimension,
	|	ManufacturedProductDimension.Products AS ManufacturedProduct,
	|	ManufacturedProductDimension.Characteristic AS ItemVariant,
	|	ManufacturedProductDimension.Series AS ProductionSeries_,
	|	ManufacturedProductDimension.Purpose AS AssignmentOfProducts,
	|
	|	CASE
	|		WHEN TRUE
	|			THEN DD.DocumentOfProductionIssue
	|	END AS Lot,
	|	DD.ProductionOrder AS ProductionOrder,
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	DD.Count AS ProductionCostsQuantity,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost
	|		ELSE
	|			DD.Cost
	|	END AS ProductionCostsCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|		ELSE 0
	|	END AS CostOfProductionPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|		ELSE 0
	|	END AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.WIPLaborCosts AS DD
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS ManufacturedProductDimension
	|	ON DD.CorDimensionOfProductsAccounting = ManufacturedProductDimension.Ref
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|{WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Tables,
	|	&FinalBalanceLaborCosts22 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&LaborCosts AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS SendingDepartment,
	|	UNDEFINED AS Recorder,
	|	CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	DD.WorkKind AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	CASE
	|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|			THEN DD.ProductionLot
	|		ELSE UNDEFINED
	|	END AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	DD.CountBalance AS FinalRemainderQuantity,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCostBalance
	|		ELSE
	|			DD.CostBalance
	|	END AS FinalRemainderCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifferenceBalance
	|		ELSE 0
	|	END AS FinalBalanceOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTDBalance
	|		ELSE 0
	|	END AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.WIPLaborCosts.Balance(
	|			{(&EndOfPeriodLimit)},
	|			ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|			AND (ProductionLot.Organization = Organization OR NOT &ByEnterprise)
	|			{
	|				(CAST(ProductionLot.Document AS Document.ProductionOrder2_2)) AS ProductionOrder,
	|				Organization AS Organization,
	|				Department AS Department
	|			}
	|	) AS DD
	|
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&FinalBalanceLaborCosts21 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&LaborCosts AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS SendingDepartment,
	|	UNDEFINED AS Recorder,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	DD.WorkKind AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	DD.ProductionOrder AS ProductionLot,
	|	DD.ProductionOrder AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	DD.CountBalance AS FinalRemainderQuantity,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCostBalance
	|		ELSE
	|			DD.CostBalance
	|	END AS FinalRemainderCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifferenceBalance
	|		ELSE 0
	|	END AS FinalBalanceOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTDBalance
	|		ELSE 0
	|	END AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.WIPLaborCosts.Balance(
	|			{(&EndOfPeriodLimit)},
	|			ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
	|			{
	|				Organization AS Organization,
	|				Department AS Department
	|			}
	|			) AS DD
	|	
	|UNION ALL
	|	
	// Itemized
	|SELECT
	|	&Production AS Table,
	|	&InitialRemainderArticleByArticle22 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Itemized AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS SendingDepartment,
	|	UNDEFINED AS Recorder,
	|	CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	CASE
	|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|			THEN DD.ProductionLot
	|		ELSE UNDEFINED
	|	END AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	0                            AS InitialBalanceQuantity,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.CostBalance
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVATBalance
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostManBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCostBalance
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVATBalance
	|			ELSE
	|				DD.CostManBalance
	|			END
	|	END AS InitialBalanceCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifferenceBalance
	|			ELSE 0
	|		END AS InitialBalanceOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTDBalance
	|			ELSE 0
	|		END AS InitialBalanceOfTD,
	|	0                            AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS ReceivedQuantity,
	|	0 AS ReceivedCost,
	|	0 AS ReceivedPD,
	|	0 AS TDHasBeenReceived,
	|	0 AS ReceivedOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses.Balance(
	|			{(&BeginOfPeriod)},
	|			ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|			AND (ProductionLot.Organization = Organization OR NOT &ByEnterprise)
	|			AND NOT &WithoutFilterByPeriod
	|			{
	|				Organization,
	|				Department,
	|				ExpenseItem,
	|				DimensionOfExpenses,
	|				ProductionLot.Document AS ProductionOrder
	|			}
	|			) AS DD
	|		
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|			
	|	
	|UNION ALL
	|	
	|SELECT
	|	&Production AS Table,
	|	&InitialRemainderArticleByArticle21 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Itemized AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS SendingDepartment,
	|	UNDEFINED AS Recorder,
	|	DD.ProductionOrder.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	DD.ProductionOrder AS ProductionLot,
	|	DD.ProductionOrder AS ProductionOrder,
	|	
	|	0                            AS InitialBalanceQuantity,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.CostBalance
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVATBalance
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostManBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCostBalance
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVATBalance
	|			ELSE
	|				DD.CostManBalance
	|			END
	|	END AS InitialBalanceCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifferenceBalance
	|			ELSE 0
	|		END AS InitialBalanceOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTDBalance
	|			ELSE 0
	|		END AS InitialBalanceOfTD,
	|	0                            AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS ReceivedQuantity,
	|	0 AS ReceivedCost,
	|	0 AS ReceivedPD,
	|	0 AS TDHasBeenReceived,
	|	0 AS ReceivedOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses.Balance(
	|			{(&BeginOfPeriod)},
	|			ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
	|			AND NOT &WithoutFilterByPeriod
	|			{
	|				Organization,
	|				Department,
	|				ExpenseItem,
	|				DimensionOfExpenses,
	|				ProductionLot.Document AS ProductionOrder
	|			}
	|			) AS DD
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ReceivedArticleByArticle22 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Itemized AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	Attributes.Department AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	CASE
	|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|			THEN DD.ProductionLot
	|		ELSE UNDEFINED
	|	END AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT
	|			ELSE
	|				DD.CostMan
	|			END
	|	END AS SpentOnProductionCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|			ELSE 0
	|		END AS SpentOnProductionOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|			ELSE 0
	|		END AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses AS DD
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|			AND (CatProductionLots.Organization = DD.Organization OR NOT &ByEnterprise)
	|
	|		LEFT JOIN Document.AllocationOfOtherCosts AS Attributes
	|		ON DD.Recorder = Attributes.Ref
	|
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND DD.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.InclusionExclusionOfVATInCost)
	|{WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ReceivedArticleByArticle21 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Itemized AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	Attributes.Department AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	DD.ProductionOrder.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	DD.ProductionOrder AS ProductionLot,
	|	CASE
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT
	|			ELSE
	|				DD.CostMan
	|			END
	|	END AS SpentOnProductionCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|			ELSE 0
	|		END AS SpentOnProductionOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|			ELSE 0
	|		END AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses AS DD
	|	LEFT JOIN Document.AllocationOfOtherCosts AS Attributes
	|		ON DD.Recorder = Attributes.Ref
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|{WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ConsumptionArticleByArticle22 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Itemized AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.Department AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	DD.ProductsAccountingDimension AS ProductsAccountingDimension,
	|	ManufacturedProductDimension.Products AS ManufacturedProduct,
	|	ManufacturedProductDimension.Characteristic AS ItemVariant,
	|	ManufacturedProductDimension.Series AS ProductionSeries_,
	|	ManufacturedProductDimension.Purpose AS AssignmentOfProducts,
	|
	|	CASE
	|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|			THEN DD.ProductionLot
	|		ELSE UNDEFINED
	|	END AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT
	|			ELSE
	|				DD.CostMan
	|			END
	|	END AS ProductionCostsCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|			ELSE 0
	|		END AS CostOfProductionPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|			ELSE 0
	|		END AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses AS DD
	|
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|			AND (CatProductionLots.Organization = DD.Organization OR NOT &ByEnterprise)
	|
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS ManufacturedProductDimension
	|		ON DD.ProductsAccountingDimension = ManufacturedProductDimension.Ref
	|
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|{WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&ConsumptionArticleByArticle21 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Itemized AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.Department AS SendingDepartment,
	|	DD.Recorder AS Recorder,
	|	DD.ProductionOrder.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	DD.ProductsAccountingDimension AS ProductsAccountingDimension,
	|	ManufacturedProductDimension.Products AS ManufacturedProduct,
	|	ManufacturedProductDimension.Characteristic AS ItemVariant,
	|	ManufacturedProductDimension.Series AS ProductionSeries_,
	|	ManufacturedProductDimension.Purpose AS AssignmentOfProducts,
	|
	|	DD.ProductionOrder AS ProductionLot,
	|	CASE
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.Cost
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVAT
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostMan
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCost
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVAT
	|			ELSE
	|				DD.CostMan
	|			END
	|	END AS ProductionCostsCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifference
	|			ELSE 0
	|		END AS CostOfProductionPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTD
	|			ELSE 0
	|		END AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	0 AS FinalRemainderQuantity,
	|	0 AS FinalRemainderCost,
	|	0 AS FinalBalanceOfPD,
	|	0 AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses AS DD
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS ManufacturedProductDimension
	|	ON DD.ProductsAccountingDimension = ManufacturedProductDimension.Ref
	|WHERE
	|	(DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|			OR &WithoutFilterByPeriod)
	|	AND DD.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|{WHERE
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses
	|}
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&FinalRemainderArticleByArticle22 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Itemized AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS SendingDepartment,
	|	UNDEFINED AS Recorder,
	|	CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	CASE
	|		WHEN DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|			THEN DD.ProductionLot
	|		ELSE UNDEFINED
	|	END AS ProductionLot,
	|	CASE
	|		WHEN VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|			THEN CatProductionLots.Document
	|		WHEN TRUE
	|			THEN VALUE(Document.ProductionOrder2_2.EmptyRef)
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.CostBalance
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVATBalance
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostManBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCostBalance
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVATBalance
	|			ELSE
	|				DD.CostManBalance
	|			END
	|	END AS FinalRemainderCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifferenceBalance
	|			ELSE 0
	|		END AS FinalBalanceOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTDBalance
	|			ELSE 0
	|		END AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses.Balance(
	|			{(&EndOfPeriodLimit)},
	|			ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|				AND (ProductionLot.Organization = Organization OR NOT &ByEnterprise)
	|			{
	|				Organization,
	|				Department,
	|				ExpenseItem,
	|				DimensionOfExpenses,
	|				ProductionLot.Document AS ProductionOrder
	|			}
	|			) AS DD
	|
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|
	|UNION ALL
	|
	|SELECT
	|	&Production AS Table,
	|	&FinalRemainderArticleByArticle21 AS Content,
	|	DD.ProductCostElement.ExpenseType AS ExpenseType,
	|	&Itemized AS CostKind,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS SendingDepartment,
	|	UNDEFINED AS Recorder,
	|	DD.ProductionOrder.LineOfBusiness AS LineOfBusiness,
	|	DD.ProductCostElement AS ProductCostElement,
	|	
	|	// material analysis
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	
	|	// labor cost analytics
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	// product analytics
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ProductsAccountingDimension,
	|	VALUE(Catalog.Products.EmptyRef) AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS ProductionSeries_,
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentOfProducts,
	|
	|	DD.ProductionOrder AS ProductionLot,
	|	CASE
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END AS ProductionOrder,
	|	
	|	0 AS InitialBalanceQuantity,
	|	0 AS InitialBalanceCost,
	|	0 AS InitialBalanceOfPD,
	|	0 AS InitialBalanceOfTD,
	|	0 AS InitialBalanceOffBalanceSheet,
	|	
	|	0 AS AmountSpentOnProduction,
	|	0 AS SpentOnProductionCost,
	|	0 AS SpentOnProductionOfPD,
	|	0 AS SpentOnProductionOfTD,
	|	0 AS SpentOnProductionOffBalanceSheet,
	|	
	|	0 AS InclusionExclusionOfVAT,
	|	
	|	0 AS ProductionCostsQuantity,
	|	0 AS ProductionCostsCost,
	|	0 AS CostOfProductionPD,
	|	0 AS CostOfProductionOfTD,
	|	0 AS ProductionCostsOffBalanceSheet,
	|	
	|	0 AS FinalRemainderQuantity,
	|	CASE
	|		WHEN &Cost_Data = 1
	|			THEN DD.CostBalance
	|		WHEN &Cost_Data = 2
	|			THEN DD.CostExcludingVATBalance
	|		WHEN &Cost_Data = 3
	|			THEN DD.CostManBalance
	|		WHEN &Cost_Data = 4
	|			THEN DD.LocalCostBalance
	|		ELSE
	|			CASE WHEN &ByEnterprise
	|				THEN DD.CostExcludingVATBalance
	|			ELSE
	|				DD.CostManBalance
	|			END
	|	END AS FinalRemainderCost,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.PermanentDifferenceBalance
	|			ELSE 0
	|		END AS FinalBalanceOfPD,
	|	CASE
	|		WHEN &Cost_Data = 4
	|			THEN DD.CostTDBalance
	|			ELSE 0
	|		END AS FinalBalanceOfTD,
	|	0 AS FinalBalanceIsOffBalance
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses.Balance(
	|			{(&EndOfPeriodLimit)},
	|			ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
	|			{
	|				Organization,
	|				Department,
	|				ProductionOrder.LineOfBusiness AS LineOfBusiness,
	|				ExpenseItem,
	|				DimensionOfExpenses,
	|				ProductionOrder AS ProductionOrder
	|			}
	|			) AS DD
	|) AS DD
	|
	|GROUP BY
	|
	|	DD.Table,
	|	DD.Content,
	|	DD.ExpenseType,
	|	DD.CostKind,
	|	DD.Organization,
	|	DD.Department,
	|	DD.SendingDepartment,
	|	DD.Recorder,
	|	DD.LineOfBusiness,
	|	DD.ProductCostElement,
	|	
	|	// material analysis
	|	DD.ItemsLocationAttributes,
	|	DD.Products,
	|	DD.Characteristic,
	|	DD.Series,
	|	DD.Purpose,
	|	
	|	// labor cost analytics
	|	DD.WorkKind,
	|	
	|	// analysis of item-by-item expense
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	
	|	// product analytics
	|	DD.ProductsAccountingDimension,
	|	DD.ManufacturedProduct,
	|	DD.ItemVariant,
	|	DD.ProductionSeries_,
	|	DD.AssignmentOfProducts,
	|	
	|	DD.ProductionLot,
	|	DD.ProductionOrder
	|";
	
	Resources = New Array;
	
	Resources.Add("InitialBalanceQuantity");
	Resources.Add("InitialBalanceCost");
	Resources.Add("InitialBalanceOfPD");
	Resources.Add("InitialBalanceOfTD");
	Resources.Add("InitialBalanceOffBalanceSheet");
	
	Resources.Add("AmountSpentOnProduction");
	Resources.Add("SpentOnProductionCost");
	Resources.Add("SpentOnProductionOfPD");
	Resources.Add("SpentOnProductionOfTD");
	Resources.Add("SpentOnProductionOffBalanceSheet");

	Resources.Add("ProductionCostsQuantity");
	Resources.Add("ProductionCostsCost");
	Resources.Add("CostOfProductionPD");
	Resources.Add("CostOfProductionOfTD");
	Resources.Add("ProductionCostsOffBalanceSheet");

	Resources.Add("FinalRemainderQuantity");
	Resources.Add("FinalRemainderCost");
	Resources.Add("FinalBalanceOfPD");
	Resources.Add("FinalBalanceOfTD");
	Resources.Add("FinalBalanceIsOffBalance");
	
	Return New Structure("QueryText, Resources", QueryText, Resources);

EndFunction

// Adds a selection to the data set of the data layout scheme for the transferred resources.
// 
// Parameters:
// 	Resources - Array of String - names of resources to be selected for "<> 0".
// 	DataSet - DataCompositionTemplateDataSetQuery  - the corrected data set. 
Procedure AddSelectionForSelectedResources(Resources, DataSet) Export
	
	If StrFind(DataSet.Query, "HAVING") > 0 Then
		// there is already a selection in the request
		Return;
	EndIf;
	
	RequestStart = "
	|HAVING
	|	SUM(%1) <> 0";
	
	ResourceTemplate = "
	|	OR SUM(%1) <> 0";
	
	FilterText1 = "";

	For Each FieldDetails In DataSet.Fields Do
		If Resources.Find(FieldDetails.Name) <> Undefined Then
			
			If FilterText1 = "" Then
				FilterText1 = StringFunctionsClientServer.SubstituteParametersToString(RequestStart, FieldDetails.Name);
			Else
				FilterText1 = FilterText1 + StringFunctionsClientServer.SubstituteParametersToString(ResourceTemplate, FieldDetails.Name);
			EndIf;
			
		EndIf;
	EndDo;
	
	PositionArrange = StrFind(DataSet.Query, "ORDER", SearchDirection.FromEnd);
	If PositionArrange > 0 Then
		DataSet.Query = Left(DataSet.Query, PositionArrange - 1) + FilterText1 + Chars.LF + Mid(DataSet.Query, PositionArrange);
	Else
		DataSet.Query = DataSet.Query + FilterText1;
	EndIf;
		
EndProcedure

// Processes Directory objects.Expense allocation rules and Document.Distribution of work costs when updating information security.
// Parameters:
//	Object - CatalogObject.CostAllocationRules, DocumentObject.AllocationOfOtherCosts - object to update.
//	TemplatesForDistributionDatabases - Map of KeyAndValue- Templates of distribution bases by distribution base names:
//		* Key - String - simplified name of the distribution base (materials, products, etc.).
//		* Value - DataCompositionSchema - the scheme on the basis of which the settings will be filled in.
Procedure HandleFillingInLayoutSettings(Object, TemplatesForDistributionDatabases) Export

	If Object.AllocationDirectionSettingsChanged Or Object.SettingsOfBaseOfAllocationByLotsChanged Then
		// The objects have already been processed
		Return;
	EndIf;

	TabularPartsToBeProcessed = New Map;
	TabularPartsToBeProcessed.Insert("FilterByProductsGroups", "ProductsGroup");
	TabularPartsToBeProcessed.Insert("FilterByMaterials", "Material");
	TabularPartsToBeProcessed.Insert("FilterByActivityKind", "WorkKind");
	TabularPartsToBeProcessed.Insert("FilterByProducts", "ManufacturedProduct");

	DestinationDetails = "AssignAllocationSetting";
	If TypeOf(Object.Ref) = Type("CatalogRef.CostAllocationRules") Then
		DestinationDetails = "AssignRule";
	EndIf;
	
	If Object[DestinationDetails]= Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots
		And Not Object.AllocationDirection = Enums.AllocationDirectionByBusinessUnits.EmptyRef() Then
		
		DefaultSettings = TemplatesForDistributionDatabases["AllocationDirection"].DefaultSettings; // DataCompositionSettings
		DefaultSettings.Filter.Items.Clear();
		
		FilterByBusinessUnit = DefaultSettings.Filter.Items.Add(
			Type("DataCompositionFilterItem"));
		FilterByBusinessUnit.LeftValue = New DataCompositionField("Department");
		
		If Object.AllocationDirection = Enums.AllocationDirectionByBusinessUnits.CurrentBusinessUnit
			And TypeOf(Object.Ref) = Type("DocumentRef.AllocationOfOtherCosts") Then
			
			FilterByBusinessUnit.RightValue = New DataCompositionField("DataParameters.CurrentDepartment");
			FilterByBusinessUnit.ComparisonType = DataCompositionComparisonType.Equal;
			Object.AllocationDirectionSettingsChanged = True;
				
		ElsIf Object.AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Superior
			And TypeOf(Object.Ref) = Type("DocumentRef.AllocationOfOtherCosts") Then
			
			FilterByBusinessUnit.RightValue = New DataCompositionField("DataParameters.SuperiorDepartment");
			FilterByBusinessUnit.ComparisonType = DataCompositionComparisonType.Equal;
			Object.AllocationDirectionSettingsChanged = True;
				
		ElsIf Object.AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Subordinate
			And TypeOf(Object.Ref) = Type("DocumentRef.AllocationOfOtherCosts") Then
			
			FilterByBusinessUnit.RightValue = New DataCompositionField("DataParameters.CurrentDepartment");
			FilterByBusinessUnit.ComparisonType = DataCompositionComparisonType.InHierarchy;
			
			SelectionByDivisionIsNotEqualTo = DefaultSettings.Filter.Items.Add(
				Type("DataCompositionFilterItem"));
			SelectionByDivisionIsNotEqualTo.LeftValue = New DataCompositionField("Department");
			SelectionByDivisionIsNotEqualTo.ComparisonType = DataCompositionComparisonType.NotEqual;
			SelectionByDivisionIsNotEqualTo.RightValue = New DataCompositionField("DataParameters.CurrentDepartment");
			
			Object.AllocationDirectionSettingsChanged = True;
			
		ElsIf Object.AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Specified Then
			
			DepartmentList = New ValueList();
			DepartmentList.LoadValues(
				Object.FilterByBusinessUnits.UnloadColumn("Department"));
			FilterByBusinessUnit.RightValue = DepartmentList;
			FilterByBusinessUnit.ComparisonType = DataCompositionComparisonType.InList;
			Object.AllocationDirectionSettingsChanged = True;

		EndIf;

		If Object.AllocationDirectionSettingsChanged Then
			FilterByBusinessUnit.Use = True;
			Object.AllocationDirectionSettings = New ValueStorage(DefaultSettings);
		EndIf;
	
	EndIf;

	SchemaName = Enums.TypesOfCostAllocatingBase.NameOfDistributionBaseSchema(Object.BaseOfAllocationByLots);
	If IsBlankString(SchemaName) Then
		Return;
	EndIf;
	
	DefaultSettings = TemplatesForDistributionDatabases[SchemaName].DefaultSettings; // DataCompositionSettings
	DefaultSettings.Filter.Items.Clear();
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	T.Ref AS Material,
		|	T.IsFolder AS IsFolder
		|FROM
		|	Catalog.Products AS T
		|WHERE
		|	T.Ref IN (&MaterialList)";
	Query.SetParameter("MaterialList", Object.FilterByMaterials.UnloadColumn("Material"));
	
	For Each KeyAndValue In TabularPartsToBeProcessed Do
		
		If Object[KeyAndValue.Key].Count() = 0 Then
			Continue;
		EndIf;
		
		Object.SettingsOfBaseOfAllocationByLotsChanged = True;
		
		FilterItems1 = New ValueList;
		SelectionGroups = New ValueList;
		
		If KeyAndValue.Key = "FilterByMaterials" Then
			
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				If Selection.IsFolder Then
					SelectionGroups.Add(Selection.Material);
				Else
					FilterItems1.Add(Selection.Material);
				EndIf;
			EndDo;
			
		Else
			FilterItems1.LoadValues(Object[KeyAndValue.Key].UnloadColumn(KeyAndValue.Value));
		EndIf;
		
		Filter = Undefined;
		If SelectionGroups.Count() = 0 Then
			
			Filter = DefaultSettings.Filter.Items.Add(
				Type("DataCompositionFilterItem"));
			Filter.LeftValue = New DataCompositionField(KeyAndValue.Value);
			Filter.ComparisonType = DataCompositionComparisonType.InList;
			Filter.RightValue = FilterItems1;
		
		Else
			
			FilterItemsGroup = DefaultSettings.Filter.Items.Add(
					Type("DataCompositionFilterItemGroup"));
			FilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
			
			SelectionElementForGroups = FilterItemsGroup.Items.Add(
				Type("DataCompositionFilterItem"));
			SelectionElementForGroups.LeftValue = New DataCompositionField(KeyAndValue.Value);
			SelectionElementForGroups.ComparisonType = DataCompositionComparisonType.InListByHierarchy;
			SelectionElementForGroups.RightValue = SelectionGroups;
				
			SelectionElementForElements = FilterItemsGroup.Items.Add(
				Type("DataCompositionFilterItem"));
			SelectionElementForElements.LeftValue = New DataCompositionField(KeyAndValue.Value);
			SelectionElementForElements.ComparisonType = DataCompositionComparisonType.InList;
			SelectionElementForElements.RightValue = FilterItems1;
			
		EndIf;
		
	EndDo;

	If Object.SettingsOfBaseOfAllocationByLotsChanged Then
		Object.SettingsOfBaseOfAllocationByLots = New ValueStorage(DefaultSettings);
	EndIf;

EndProcedure

#EndRegion

#Region Internal

#Region HandlersForMonthClosingStages

#Region CorrectErrorsInInitialData

Procedure CheckingCorrectnessOfIndicationOfProductionBatches(CheckParameters) Export
	
	QueryText = " 
	|SELECT DISTINCT
	|	Allocation.Ref.Organization AS Organization,
	|	Allocation.Ref AS DocumentDistributions,
	|	Allocation.ProductionLot.Document AS BackflushProduction
	|
	|INTO DistributionDocumentsWithIrrelevantBatches
	|FROM
	|	Document.AllocationOfOtherCosts.ProductionLots AS Allocation
	|	
	|	INNER JOIN Document.BackflushProduction AS BackflushProduction
	|		ON BackflushProduction.Ref = Allocation.ProductionLot.Document
	|		
	|	LEFT JOIN Document.ReversingEntry AS DocumentReversingEntry
	|		ON DocumentReversingEntry.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentReversingEntry.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentReversingEntry.Posted
	|
	|	LEFT JOIN Document.BackflushProduction AS DocumentCorrections
	|		ON DocumentCorrections.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentCorrections.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentCorrections.Posted
	|WHERE
	|	Allocation.Ref.Posted
	|	AND Allocation.Ref.Organization IN(&CompanyArray)
	|	AND Allocation.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (NOT DocumentReversingEntry.Ref IS NULL
	|		OR NOT DocumentCorrections.Ref IS NULL
	|			AND NOT DocumentCorrections.CorrectionSavesProductionLots)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Allocation.Ref.Organization AS Organization,
	|	Allocation.Ref AS DocumentDistributions,
	|	Allocation.ProductionLot.Document AS BackflushProduction
	|FROM
	|	Document.ProductionCostAllocation.ProductionLots AS Allocation
	|	
	|	INNER JOIN Document.BackflushProduction AS BackflushProduction
	|		ON BackflushProduction.Ref = Allocation.ProductionLot.Document
	|		
	|	LEFT JOIN Document.ReversingEntry AS DocumentReversingEntry
	|		ON DocumentReversingEntry.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentReversingEntry.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentReversingEntry.Posted
	|
	|	LEFT JOIN Document.BackflushProduction AS DocumentCorrections
	|		ON DocumentCorrections.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentCorrections.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentCorrections.Posted
	|WHERE
	|	Allocation.Ref.Posted
	|	AND Allocation.Ref.Organization IN(&CompanyArray)
	|	AND Allocation.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (NOT DocumentReversingEntry.Ref IS NULL
	|		OR NOT DocumentCorrections.Ref IS NULL
	|			AND NOT DocumentCorrections.CorrectionSavesProductionLots)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Allocation.Ref.Organization AS Organization,
	|	Allocation.Ref AS DocumentDistributions,
	|	Allocation.ProductionLot.Document AS BackflushProduction
	|FROM
	|	Document.RecyclableWasteAllocation.ProductionLots AS Allocation
	|	
	|	INNER JOIN Document.BackflushProduction AS BackflushProduction
	|		ON BackflushProduction.Ref = Allocation.ProductionLot.Document
	|		
	|	LEFT JOIN Document.ReversingEntry AS DocumentReversingEntry
	|		ON DocumentReversingEntry.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentReversingEntry.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentReversingEntry.Posted
	|
	|	LEFT JOIN Document.BackflushProduction AS DocumentCorrections
	|		ON DocumentCorrections.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentCorrections.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentCorrections.Posted
	|WHERE
	|	Allocation.Ref.Posted
	|	AND Allocation.Ref.Organization IN(&CompanyArray)
	|	AND Allocation.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (NOT DocumentReversingEntry.Ref IS NULL
	|		OR NOT DocumentCorrections.Ref IS NULL
	|			AND NOT DocumentCorrections.CorrectionSavesProductionLots)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.Recorder AS DocumentDistributions,
	|	OtherExpenses.DimensionOfExpenses AS ProductionLot
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = OtherExpenses.DimensionOfExpenses
	|
	|	INNER JOIN Document.BackflushProduction AS BackflushProduction
	|		ON BackflushProduction.Ref = CatProductionLots.Document
	|
	|	LEFT JOIN Document.ReversingEntry AS DocumentReversingEntry
	|		ON DocumentReversingEntry.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentReversingEntry.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentReversingEntry.Posted
	|
	|	LEFT JOIN Document.BackflushProduction AS DocumentCorrections
	|		ON DocumentCorrections.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentCorrections.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentCorrections.Posted
	|WHERE
	|	OtherExpenses.Organization IN(&CompanyArray)
	|	AND OtherExpenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|	AND (NOT DocumentReversingEntry.Ref IS NULL
	|		OR NOT DocumentCorrections.Ref IS NULL
	|			AND NOT DocumentCorrections.CorrectionSavesProductionLots)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TabularSection.Ref.Organization AS Organization,
	|	TabularSection.Ref AS DocumentDistributions,
	|	TabularSection.ProductionLot.Document AS BackflushProduction
	|FROM
	|	Document.WIPOpeningBalancesByProductionLots.MaterialsAndWorks AS TabularSection
	|	
	|	INNER JOIN Document.BackflushProduction AS BackflushProduction
	|		ON BackflushProduction.Ref = TabularSection.ProductionLot.Document
	|		
	|	LEFT JOIN Document.ReversingEntry AS DocumentReversingEntry
	|		ON DocumentReversingEntry.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentReversingEntry.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentReversingEntry.Posted
	|
	|	LEFT JOIN Document.BackflushProduction AS DocumentCorrections
	|		ON DocumentCorrections.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentCorrections.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentCorrections.Posted
	|WHERE
	|	TabularSection.Ref.Posted
	|	AND TabularSection.Ref.Organization IN(&CompanyArray)
	|	AND TabularSection.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (NOT DocumentReversingEntry.Ref IS NULL
	|		OR NOT DocumentCorrections.Ref IS NULL
	|			AND NOT DocumentCorrections.CorrectionSavesProductionLots)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TabularSection.Ref.Organization AS Organization,
	|	TabularSection.Ref AS DocumentDistributions,
	|	TabularSection.ProductionLot.Document AS BackflushProduction
	|FROM
	|	Document.WIPOpeningBalancesByProductionLots.LaborCosts AS TabularSection
	|	
	|	INNER JOIN Document.BackflushProduction AS BackflushProduction
	|		ON BackflushProduction.Ref = TabularSection.ProductionLot.Document
	|		
	|	LEFT JOIN Document.ReversingEntry AS DocumentReversingEntry
	|		ON DocumentReversingEntry.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentReversingEntry.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentReversingEntry.Posted
	|
	|	LEFT JOIN Document.BackflushProduction AS DocumentCorrections
	|		ON DocumentCorrections.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentCorrections.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentCorrections.Posted
	|WHERE
	|	TabularSection.Ref.Posted
	|	AND TabularSection.Ref.Organization IN(&CompanyArray)
	|	AND TabularSection.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (NOT DocumentReversingEntry.Ref IS NULL
	|		OR NOT DocumentCorrections.Ref IS NULL
	|			AND NOT DocumentCorrections.CorrectionSavesProductionLots)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TabularSection.Ref.Organization AS Organization,
	|	TabularSection.Ref AS DocumentDistributions,
	|	TabularSection.ProductionLot.Document AS BackflushProduction
	|FROM
	|	Document.WIPOpeningBalancesByProductionLots.OtherExpenses AS TabularSection
	|	
	|	INNER JOIN Document.BackflushProduction AS BackflushProduction
	|		ON BackflushProduction.Ref = TabularSection.ProductionLot.Document
	|		
	|	LEFT JOIN Document.ReversingEntry AS DocumentReversingEntry
	|		ON DocumentReversingEntry.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentReversingEntry.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentReversingEntry.Posted
	|
	|	LEFT JOIN Document.BackflushProduction AS DocumentCorrections
	|		ON DocumentCorrections.ReversedDocument = BackflushProduction.Ref
	|		AND DocumentCorrections.Date BETWEEN BEGINOFPERIOD(BackflushProduction.Date, MONTH) AND ENDOFPERIOD(BackflushProduction.Date, MONTH)
	|		AND DocumentCorrections.Posted
	|WHERE
	|	TabularSection.Ref.Posted
	|	AND TabularSection.Ref.Organization IN(&CompanyArray)
	|	AND TabularSection.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (NOT DocumentReversingEntry.Ref IS NULL
	|		OR NOT DocumentCorrections.Ref IS NULL
	|			AND NOT DocumentCorrections.CorrectionSavesProductionLots)
	|";
	
	ObjectFieldName = "DocumentDistributions";
	
	TempTableName = "DistributionDocumentsWithIrrelevantBatches";
	ErrorTextTemplate  = NStr("vi = 'Đã tìm thấy chứng từ, trong đó đã chỉ ra chứng từ sản xuất đảo ngược mà không có đơn hàng, theo doanh nghiệp ""%1"" trong kỳ %2';
								|ru = 'Обнаружены документы, в которых указаны сторнированные или исправленные документы производства без заказов, по организации ""%1"" за период %2';
								|en = 'Documents were found, in which reversed or adjusted backflush production document were specified, for the ""%1"" company in the period %2'; fa = 'Documents were found, in which reversed or adjusted backflush production document were specified, for the ""%1"" company in the period %2';
								|it = 'Обнаружены документы, в которых указаны сторнированные или исправленные документы производства без заказов, по организации ""%1"" за период %2';
								|pl = 'Documents were found, in which reversed or adjusted backflush production document were specified, for the ""%1"" company in the period %2';
								|tr = '%2 dönemi için ""%1"" iş yerine göre, geriye dönük üretim olmaksızın tersine çevrilmiş veya değiştirilmiş üretim belgelerini belirten belgeler tespit edildi'", Common.DefaultLanguageCode());
	
	FieldList = New ValueList;
	FieldList.Add("Organization",  NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Company';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add(ObjectFieldName, NStr("vi = 'Chứng từ phân bổ';
										|ru = 'Документ распределения';
										|en = 'Allocation document'; fa = 'Allocation document';
										|it = 'Documento di ripartizione';
										|pl = 'Dokument przydziału';
										|tr = 'Dağıtım belgesi'", Common.DefaultLanguageCode()));
	FieldList.Add("BackflushProduction", NStr("vi = 'Lô sản xuất';
												|ru = 'Партия производства';
												|en = 'Production lot'; fa = 'بچ تولید';
												|it = 'Lotto di produzione';
												|pl = 'Partia produkcji';
												|tr = 'Üretim lotu'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(TempTableName,
		ErrorTextTemplate,
		FieldList,
		ObjectFieldName);
	
	MonthEndTransactionsServer.RegisterValidationIssues(CheckParameters, RegistrationParameters, QueryText);
	
EndProcedure

Procedure CheckingRelevanceOfSpecifiedProductionBatches(CheckParameters) Export
	
	QueryText = "
	|SELECT DISTINCT
	|	Allocation.Ref.Organization AS Organization,
	|	Allocation.Ref AS DocumentDistributions,
	|	Allocation.ProductionLot AS ProductionLot
	|
	|INTO DistributionDocumentsWithIrrelevantBatches
	|FROM
	|	Document.AllocationOfOtherCosts.ProductionLots AS Allocation
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = Allocation.ProductionLot
	|	LEFT JOIN Document.BackflushProduction.ManufacturedProducts AS BackflushProduction
	|		ON BackflushProduction.Ref = CatProductionLots.Document
	|		AND BackflushProduction.CostGroupNumber = CatProductionLots.Code
	|		AND NOT CatProductionLots.DeletionMark
	|		AND BackflushProduction.Ref.Posted
	|WHERE
	|	Allocation.Ref.Posted
	|	AND Allocation.Ref.Organization IN(&CompanyArray)
	|	AND Allocation.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|	AND BackflushProduction.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Allocation.Ref.Organization AS Organization,
	|	Allocation.Ref AS DocumentDistributions,
	|	Allocation.ProductionLot AS ProductionLot
	|FROM
	|	Document.ProductionCostAllocation.ProductionLots AS Allocation
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = Allocation.ProductionLot
	|	LEFT JOIN Document.BackflushProduction.ManufacturedProducts AS BackflushProduction
	|		ON BackflushProduction.Ref = CatProductionLots.Document
	|		AND BackflushProduction.CostGroupNumber = CatProductionLots.Code
	|		AND NOT CatProductionLots.DeletionMark
	|		AND BackflushProduction.Ref.Posted
	|WHERE
	|	Allocation.Ref.Posted
	|	AND Allocation.Ref.Organization IN(&CompanyArray)
	|	AND Allocation.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|	AND BackflushProduction.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Allocation.Ref.Organization AS Organization,
	|	Allocation.Ref AS DocumentDistributions,
	|	Allocation.ProductionLot AS ProductionLot
	|FROM
	|	Document.RecyclableWasteAllocation.ProductionLots AS Allocation
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = Allocation.ProductionLot
	|	LEFT JOIN Document.BackflushProduction.ManufacturedProducts AS BackflushProduction
	|		ON BackflushProduction.Ref = CatProductionLots.Document
	|		AND BackflushProduction.CostGroupNumber = CatProductionLots.Code
	|		AND NOT CatProductionLots.DeletionMark
	|		AND BackflushProduction.Ref.Posted
	|WHERE
	|	Allocation.Ref.Posted
	|	AND Allocation.Ref.Organization IN(&CompanyArray)
	|	AND Allocation.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|	AND BackflushProduction.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.Recorder AS DocumentDistributions,
	|	OtherExpenses.DimensionOfExpenses AS ProductionLot
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = OtherExpenses.DimensionOfExpenses
	|	LEFT JOIN Document.BackflushProduction.ManufacturedProducts AS BackflushProduction
	|		ON BackflushProduction.Ref = CatProductionLots.Document
	|		AND BackflushProduction.CostGroupNumber = CatProductionLots.Code
	|		AND NOT CatProductionLots.DeletionMark
	|		AND BackflushProduction.Ref.Posted
	|WHERE
	|	OtherExpenses.Organization IN(&CompanyArray)
	|	AND OtherExpenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|	AND BackflushProduction.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TabularSection.Ref.Organization AS Organization,
	|	TabularSection.Ref AS DocumentDistributions,
	|	TabularSection.ProductionLot AS ProductionLot
	|FROM
	|	Document.WIPOpeningBalancesByProductionLots.MaterialsAndWorks AS TabularSection
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = TabularSection.ProductionLot
	|	LEFT JOIN Document.BackflushProduction.ManufacturedProducts AS BackflushProduction
	|		ON BackflushProduction.Ref = CatProductionLots.Document
	|		AND BackflushProduction.CostGroupNumber = CatProductionLots.Code
	|		AND NOT CatProductionLots.DeletionMark
	|		AND BackflushProduction.Ref.Posted
	|WHERE
	|	TabularSection.Ref.Posted
	|	AND TabularSection.Ref.Organization IN(&CompanyArray)
	|	AND TabularSection.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|	AND BackflushProduction.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TabularSection.Ref.Organization AS Organization,
	|	TabularSection.Ref AS DocumentDistributions,
	|	TabularSection.ProductionLot AS ProductionLot
	|FROM
	|	Document.WIPOpeningBalancesByProductionLots.LaborCosts AS TabularSection
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = TabularSection.ProductionLot
	|	LEFT JOIN Document.BackflushProduction.ManufacturedProducts AS BackflushProduction
	|		ON BackflushProduction.Ref = CatProductionLots.Document
	|		AND BackflushProduction.CostGroupNumber = CatProductionLots.Code
	|		AND NOT CatProductionLots.DeletionMark
	|		AND BackflushProduction.Ref.Posted
	|WHERE
	|	TabularSection.Ref.Posted
	|	AND TabularSection.Ref.Organization IN(&CompanyArray)
	|	AND TabularSection.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|	AND BackflushProduction.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TabularSection.Ref.Organization AS Organization,
	|	TabularSection.Ref AS DocumentDistributions,
	|	TabularSection.ProductionLot AS ProductionLot
	|FROM
	|	Document.WIPOpeningBalancesByProductionLots.OtherExpenses AS TabularSection
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = TabularSection.ProductionLot
	|	LEFT JOIN Document.BackflushProduction.ManufacturedProducts AS BackflushProduction
	|		ON BackflushProduction.Ref = CatProductionLots.Document
	|		AND BackflushProduction.CostGroupNumber = CatProductionLots.Code
	|		AND NOT CatProductionLots.DeletionMark
	|		AND BackflushProduction.Ref.Posted
	|WHERE
	|	TabularSection.Ref.Posted
	|	AND TabularSection.Ref.Organization IN(&CompanyArray)
	|	AND TabularSection.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|	AND BackflushProduction.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	AttributesOfReportToGiver.Organization     AS Organization,
	|	AttributesOfReportToGiver.Ref          AS DocumentDistributions,
	|	BatchesOfReportToGiver.ProductionLot AS ProductionLot
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS AttributesOfReportToGiver
	|	
	|	INNER JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS BatchesOfReportToGiver
	|	ON AttributesOfReportToGiver.Ref = BatchesOfReportToGiver.Ref
	|	
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Ref = BatchesOfReportToGiver.ProductionLot
	|	AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|
	|WHERE
	|	AttributesOfReportToGiver.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND AttributesOfReportToGiver.Posted
	|	AND AttributesOfReportToGiver.Organization IN (&CompanyArray)
	// The report to the giver can be issued according to the Lot reference backflushed production, if there was a Registered Record of expenses in the current period.
	|	AND NOT TRUE IN(
	|		SELECT TOP 1
	|			TRUE
	|		FROM AccumulationRegister.InventoryCost AS ReceiptsOfUnfinishedProduction
	|		WHERE
	|			ReceiptsOfUnfinishedProduction.Lot = BatchesOfReportToGiver.ProductionLot
	|			AND ReceiptsOfUnfinishedProduction.Organization = AttributesOfReportToGiver.Organization
	|			AND ReceiptsOfUnfinishedProduction.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND NOT ReceiptsOfUnfinishedProduction.LotCalculation
	|			AND NOT ReceiptsOfUnfinishedProduction.CalculationOfCost
	|		)
	|	AND NOT TRUE IN(
	|		
	|		SELECT TOP 1
	|			TRUE
	|		FROM AccumulationRegister.OtherWorkInProgressExpenses AS ReceiptsOfUnfinishedProduction
	|		WHERE
	|			ReceiptsOfUnfinishedProduction.ProductionLot = BatchesOfReportToGiver.ProductionLot
	|			AND ReceiptsOfUnfinishedProduction.Organization = AttributesOfReportToGiver.Organization
	|			AND ReceiptsOfUnfinishedProduction.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND NOT ReceiptsOfUnfinishedProduction.LotCalculation
	|			AND NOT ReceiptsOfUnfinishedProduction.CalculationOfCost
	|		)
	|	AND NOT TRUE IN(
	|		SELECT TOP 1
	|			TRUE
	|		FROM AccumulationRegister.WIPLaborCosts AS ReceiptsOfUnfinishedProduction
	|		WHERE
	|			ReceiptsOfUnfinishedProduction.ProductionLot = BatchesOfReportToGiver.ProductionLot
	|			AND ReceiptsOfUnfinishedProduction.Organization = AttributesOfReportToGiver.Organization
	|			AND ReceiptsOfUnfinishedProduction.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND NOT ReceiptsOfUnfinishedProduction.LotCalculation
	|		)
	|	AND NOT TRUE IN(
	|		
	|		SELECT TOP 1
	|			TRUE
	|		FROM AccumulationRegister.OtherExpenses AS ReceiptsOfUnfinishedProduction
	|		WHERE
	|			ReceiptsOfUnfinishedProduction.DimensionOfExpenses = BatchesOfReportToGiver.ProductionLot
	|			AND ReceiptsOfUnfinishedProduction.Organization = AttributesOfReportToGiver.Organization
	|			AND ReceiptsOfUnfinishedProduction.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND NOT ReceiptsOfUnfinishedProduction.LotCalculation
	|			AND NOT ReceiptsOfUnfinishedProduction.CalculationOfCost
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	T.Organization,
	|	T.Ref,
	|	TSDocument.ProductionLot
	|FROM
	|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS T
	|		INNER JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS TSDocument
	|		ON T.Ref = TSDocument.Ref
	|			AND (T.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|			AND (T.Posted)
	|			AND (T.Organization IN (&CompanyArray))
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON (CatProductionLots.Ref = TSDocument.ProductionLot)
	|			AND (VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionStage2_2))
	|		LEFT JOIN Document.ProductionStage2_2.ManufacturedProducts AS ProductionStageOutputProducts
	|		ON (ProductionStageOutputProducts.Ref = CatProductionLots.Document)
	|			AND (NOT CatProductionLots.DeletionMark)
	|		LEFT JOIN Document.ProductionStage2_2 AS ProductionStage
	|		ON (ProductionStageOutputProducts.Ref = ProductionStage.Ref)
	|			AND (CatProductionLots.Ref = ProductionStage.ProductionLot)
	|			AND (ProductionStage.Posted)
	// The release of products must be in the same month as the Report to the giver between organizations
	|			AND (CASE
	|				WHEN ProductionStage.ProductionInOneDay
	|					THEN ProductionStage.ProductionDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|				ELSE ProductionStageOutputProducts.ProductionDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			END)
	|WHERE
	|	ProductionStage.Ref IS NULL
	|";
	
	ObjectFieldName = "DocumentDistributions";
	
	TempTableName = "DistributionDocumentsWithIrrelevantBatches";
	ErrorTextTemplate  = NStr("vi = 'Đã tìm thấy các chứng từ mà trong đó chỉ ra các lô hàng sản xuất đã cũ, theo doanh nghiệp ""%1"" trong kỳ %2';
								|ru = 'Обнаружены документы, в которых указаны неактуальные партии производства, по организации ""%1"" за период %2';
								|en = 'Documents with irrelevant production lots for ""%1"" company for the %2 period are found'; fa = 'Documents with irrelevant production lots for ""%1"" company for the %2 period are found';
								|it = 'Sono stati rilevati documenti nei quali sono indicati lotti di produzione non attuali, per l''azienda ""%1"" per il periodo %2';
								|pl = 'Wykryto dokumenty, w których są podane nieaktualne partie produkcji, według firmy ""%1"" za okres %2';
								|tr = '%2 dönemi için ""%1"" iş yeri için tarihi geçmiş üretim lotlarıyla birlikte belgeler bulundu'", Common.DefaultLanguageCode());
	
	FieldList = New ValueList;
	FieldList.Add("Organization",  NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Firma';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add(ObjectFieldName, NStr("vi = 'Chứng từ';
										|ru = 'Документ';
										|en = 'Document'; fa = 'سند';
										|it = 'Documento';
										|pl = 'Dokument';
										|tr = 'Belge'", Common.DefaultLanguageCode()));
	FieldList.Add("ProductionLot", NStr("vi = 'Lô sản xuất';
										|ru = 'Партия производства';
										|en = 'Production lot'; fa = 'بچ تولید';
										|it = 'Lotto di produzione';
										|pl = 'Partia produkcji';
										|tr = 'Üretim lotu'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(TempTableName,
		ErrorTextTemplate,
		FieldList,
		ObjectFieldName);
	
	MonthEndTransactionsServer.RegisterValidationIssues(CheckParameters, RegistrationParameters, QueryText);
	
EndProcedure

Procedure CheckingWhetherCalculationArticlesForSideOutputAreSpecifiedCorrectly(CheckParameters) Export
	
	QueryText = " 
	|SELECT
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS DocumentOfProductionIssue,
	|	RegisterRecords.ItemsLocationAttributes.ProductCostElement AS ProductCostElement
	|
	|INTO DocumentsWithIncorrectCostingArticles
	|FROM
	|	AccumulationRegister.InventoryCost AS RegisterRecords
	|WHERE
	|	RegisterRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RegisterRecords.Organization IN(&CompanyArray)
	|	AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RegisterRecords.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|	AND RegisterRecords.Count <> 0
	|	AND RegisterRecords.ItemsLocationAttributes.ProductCostElement <>
	|		VALUE(Catalog.ProductCostElements.SemiFinishedProductsProducedInProcess)
	|	AND NOT RegisterRecords.LotCalculation
	|	AND NOT RegisterRecords.CalculationOfCost
	|	AND NOT RegisterRecords.ReversingEntry
	|	AND NOT VALUETYPE(RegisterRecords.Recorder) = TYPE(Document.PurchaseAdjustment)
	|
	|GROUP BY
	|	RegisterRecords.Organization,
	|	RegisterRecords.Recorder,
	|	RegisterRecords.ItemsLocationAttributes.ProductCostElement
	|
	|HAVING
	|	SUM(RegisterRecords.Count) = 0
	|";
	
	ObjectFieldName = "DocumentOfProductionIssue";
	
	TempTableName = "DocumentsWithIncorrectCostingArticles";
	ErrorTextTemplate  = NStr("vi = 'Đã tìm thấy các chứng từ mà trong đó có các dạng tính giá thành giống nhau đối với nguyên vật liệu và sản lượng phụ theo giá trị cố định, theo doanh nghiệp ""%1"" trong kỳ %2.
		|Hãy chỉ ra dạng tính giá thành có kiểu chi phí ""Phế liệu thu hồi"" đối với sản lượng phụ theo giá trị cố định.';
		|ru = 'Обнаружены документы, в которых указаны одинаковые статьи калькуляции для материалов и для побочного выхода по фиксированной стоимости, по организации ""%1"" за период %2.
		|Укажите статью калькуляции с типом затрат ""Возвратные отходы"" для побочного выхода по фиксированной стоимости.';
		|en = 'Documents with specified identical product cost elements for materials and side product at a fixed cost are detected in the ""%1"" company for the %2 period.
		|Specify the product cost element with the ""Recyclable waste"" expense type for the side product at a fixed cost.'; fa = 'Documents with specified identical product cost elements for materials and side product at a fixed cost are detected in the ""%1"" company for the %2 period.
		|Specify the product cost element with the ""Recyclable waste"" expense type for the side product at a fixed cost.';
		|it = 'Sono stati rilevati documenti con le stesse voci di calcolo per i materiali e per prodotto secondario a prezzo fisso, per l''azienda ""%1"" per il periodo %2.
		|Si prega di indicare la voce di calcolo con il tipo di uscita ""Scarti riciclabili"" per prodotto secondario a prezzo fisso.';
		|pl = 'Wykryto dokumenty, w których podano jednakowe pozycje kalkulacji dla materiałów i dla ubocznej produkcji wg wartości stałej, wg firmy ""%1"" za okres %2.
		|Podaj pozycję kalkulacji z typem rozchodów ""Odpady zwrotne"" dla produkcji ubocznej wg stałej wartości.';
		|tr = '%2 döneminde ""%1"" iş yeri için malzemeler ve sabit maliyet tarafı çıktısı için aynı ürün maliyet kalemine sahip belgeler bulundu.
		|Sabit maliyet tarafı çıktısı için ""Geri dönüştürülebilir atık"" maliyet türüne sahip bir ürün maliyet öğesi belirt.'", Common.DefaultLanguageCode());
	
	FieldList = New ValueList;
	FieldList.Add("Organization",  NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Firma';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add(ObjectFieldName, NStr("vi = 'Chứng từ';
										|ru = 'Документ';
										|en = 'Document'; fa = 'سند';
										|it = 'Documento';
										|pl = 'Dokument';
										|tr = 'Belge'", Common.DefaultLanguageCode()));
	FieldList.Add("ProductCostElement", NStr("vi = 'Dạng tính giá thành';
											|ru = 'Статья калькуляции';
											|en = 'Product cost element'; fa = 'عنصر بهای تمام‌شده محصول';
											|it = 'Voce di calcolo';
											|pl = 'Rodzaj kosztu';
											|tr = 'Ürün maliyet kalemi'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(TempTableName,
		ErrorTextTemplate,
		FieldList,
		ObjectFieldName);
	
	MonthEndTransactionsServer.RegisterValidationIssues(CheckParameters, RegistrationParameters, QueryText);
	
EndProcedure

Procedure VerifyComplianceOfProcessorReportAndAdjustmentsOfProcessorReport(CheckParameters) Export
	
	QueryText = " 
	|SELECT
	|	PurchaseAdjustmentAttributes.Organization AS Organization,
	|	PurchaseAdjustmentAttributes.Ref AS PurchaseAdjustment,
	|	PurchaseAdjustmentAttributes.DocumentBasis AS SubcontractorReport
	|
	|INTO AcquisitionAdjustmentsInconsistentWithProcessorReports
	|FROM
	|	Document.PurchaseAdjustment AS PurchaseAdjustmentAttributes
	|		INNER JOIN Document.PurchaseAdjustment.Discrepancies AS Adjusting
	|		ON (PurchaseAdjustmentAttributes.Posted)
	|			AND (PurchaseAdjustmentAttributes.Organization IN (&CompanyArray))
	|			AND (PurchaseAdjustmentAttributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|			AND (PurchaseAdjustmentAttributes.BusinessOperation = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment))
	|		LEFT JOIN Document.SubcontractorReport2_5.ManufacturedProducts AS SubcontractorReport25ManufacturedProducts
	|		ON (SubcontractorReport25ManufacturedProducts.Ref = PurchaseAdjustmentAttributes.DocumentBasis)
	|			AND (SubcontractorReport25ManufacturedProducts.CostGroupNumber = Adjusting.CostGroupNumber)
	|			AND (SubcontractorReport25ManufacturedProducts.ProductionStage = Adjusting.ProductionStage)
	|		LEFT JOIN Document.SubcontractorReport2_5.SideAndIntermediateRelease AS SubcontractorReport25SideAndIntermediateRelease
	|		ON (SubcontractorReport25SideAndIntermediateRelease.Ref = PurchaseAdjustmentAttributes.DocumentBasis)
	|			AND (SubcontractorReport25SideAndIntermediateRelease.CostGroupNumber = Adjusting.CostGroupNumber)
	|			AND (SubcontractorReport25SideAndIntermediateRelease.ProductionStage = Adjusting.ProductionStage)
	|
	|GROUP BY
	|	PurchaseAdjustmentAttributes.Organization,
	|	PurchaseAdjustmentAttributes.Ref,
	|	PurchaseAdjustmentAttributes.DocumentBasis
	|
	|HAVING
	|	MAX(SubcontractorReport25ManufacturedProducts.Ref) IS NULL AND
	|	MAX(SubcontractorReport25SideAndIntermediateRelease.Ref) IS NULL
	|";
	
	ObjectFieldName = "PurchaseAdjustment";
	
	TempTableName = "AcquisitionAdjustmentsInconsistentWithProcessorReports";
	ErrorTextTemplate  = NStr("vi = 'Đã tìm thấy có điều chỉnh bảng kê của bên nhận gia công không tương ứng với việc điền bảng kê của bên nhận gia công theo doanh nghiệp ""%1"" trong kỳ %2.
		|Cần điền lại điều chỉnh';
		|ru = 'Обнаружены корректировки отчета переработчика не соответствующие заполнению отчета переработчика по организации ""%1"" за период %2.
		|Требуется перезаполнить корректировку';
		|en = 'Adjustments of ""Subcontracting services notification received"", which do not match filling of the ""Subcontracting services notification received"" of the ""%1"" company for the %2 period, are detected.
		|Refill the adjustment'; fa = 'Adjustments of ""Subcontracting services notification received"", which do not match filling of the ""Subcontracting services notification received"" of the ""%1"" company for the %2 period, are detected.
		|Refill the adjustment';
		|it = 'Sono state rilevati rettifiche di report dell''elaboratore non corrispondenti con la compilazione del report dell''elaboratore in base all''azienda ""%1"" per il periodo %2.
		|Si richiede di ricompilare la rettifica';
		|pl = 'Wykryto korekty raportu przetwórcy, które nie odpowiadają wypełnieniu raportu przetwórcy według firmy ""%1"" za okres %2.
		|Wymagane jest ponowne zapisywanie korekty';
		|tr = '""%1"" iş yeri için %2 dönemi için alınan fason hizmetleri bildirimi tamamlanmasıyla eşleşmeyen alınan fason hizmetleri bildirimini düzeltmeleri bulundu.
		|Düzeltmenin yeniden doldurulması gerekiyor'", Common.DefaultLanguageCode());
	
	FieldList = New ValueList;
	FieldList.Add("Organization",  NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Company';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add(ObjectFieldName, NStr("vi = 'Điều chỉnh bảng kê của bên nhận gia công';
										|ru = 'Корректировка отчета переработчика';
										|en = 'Adjust subcontracting services notification received'; fa = 'Adjust subcontracting services notification received';
										|it = 'Rettifica report elaboratore';
										|pl = 'Korekta raportu przetwórcy';
										|tr = 'fason üretici raporunun düzenlenmesi'", Common.DefaultLanguageCode()));
	FieldList.Add("SubcontractorReport", NStr("vi = 'Bảng kê hàng hóa của bên nhận gia công';
												|ru = 'Отчет переработчика';
												|en = 'Subcontracting services notification received'; fa = 'اعلامیه خدمات پیمانکاری فرعی دریافت‌شده';
												|it = 'Report subfornitore';
												|pl = 'Raport przetwórcy';
												|tr = 'Alınan fason üretici hizmetleri bildirimi'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(TempTableName,
		ErrorTextTemplate,
		FieldList,
		ObjectFieldName);
	
	MonthEndTransactionsServer.RegisterValidationIssues(CheckParameters, RegistrationParameters, QueryText);
	
EndProcedure

Procedure CheckingCorrectnessOfIndicationOfProductGroupsInProductionBatches(CheckParameters) Export
	
	QueryText = " 
	|SELECT DISTINCT
	|	OtherExpensesOfUnfinishedProduction.Organization AS Organization,
	|	OtherExpensesOfUnfinishedProduction.Recorder AS Document,
	|	OtherExpensesOfUnfinishedProduction.ProductionLot AS ProductionLot
	|
	|INTO BatchesWithIndicationOfProductGroups
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses AS OtherExpensesOfUnfinishedProduction
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = OtherExpensesOfUnfinishedProduction.ProductionLot
	|	LEFT JOIN Catalog.AnalyticalInventoryGroups AS ProductGroups_
	|		ON ProductionLot.ProductsGroup = ProductGroups_.Ref
	|WHERE
	|	OtherExpensesOfUnfinishedProduction.Active
	|	AND OtherExpensesOfUnfinishedProduction.Organization IN(&CompanyArray)
	|	AND OtherExpensesOfUnfinishedProduction.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND NOT ProductGroups_.Ref IS NULL";
	
	ObjectFieldName = "Document";
	
	TempTableName = "BatchesWithIndicationOfProductGroups";
	ErrorTextTemplate  = NStr("vi = 'Đã tìm thấy các lô hàng sản xuất đang sử dụng nhóm sản phẩm, mặc dù đã tắt tùy chọn kế toán theo nhóm sản phẩm tại doanh nghiệp ""%1"" trong kỳ %2';
								|ru = 'Обнаружены партии производства, использующие группы продукции, несмотря на отключенную опцию учета по группам продукции в организации ""%1"" за период %2';
								|en = 'Manufactured product groups are disabled in ""%1"" company for period %2 but still there are production lots, in which manufactured product groups are used'; fa = 'Manufactured product groups are disabled in ""%1"" company for period %2 but still there are production lots, in which manufactured product groups are used';
								|it = 'Sono stati rilevati lotti di produzione che utilizzano gruppi di produzione indipendentemente dall''opzione disabilitata di contabilità per gruppi di produzione nell''azienda ""%1"" per il periodo %2';
								|pl = 'Wykryto partie produkcji, używające grupy produkcji, chociaż jest wyłączona opcja ewidencji według grup produkcji w firmie ""%1"" za okres %2';
								|tr = 'İmal edilen ürün grubuna göre kayıt seçeneği %2 dönemi için ""%1"" iş yerinde devre dışı bırakılmış olmasına rağmen, imal edilen ürün grupları kullanılarak üretim lotları bulundu'", Common.DefaultLanguageCode());
	
	FieldList = New ValueList;
	FieldList.Add("Organization",  NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Firma';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add(ObjectFieldName, NStr("vi = 'Chứng từ';
										|ru = 'Документ';
										|en = 'Document'; fa = 'سند';
										|it = 'Documento';
										|pl = 'Dokument';
										|tr = 'Belge'", Common.DefaultLanguageCode()));
	FieldList.Add("ProductionLot", NStr("vi = 'Lô sản xuất';
										|ru = 'Партия производства';
										|en = 'Production lot'; fa = 'بچ تولید';
										|it = 'Lotto di produzione';
										|pl = 'Partia produkcji';
										|tr = 'Üretim lotu'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(TempTableName,
		ErrorTextTemplate,
		FieldList,
		ObjectFieldName);
	
	MonthEndTransactionsServer.RegisterValidationIssues(CheckParameters, RegistrationParameters, QueryText);
	
EndProcedure

#EndRegion

#Region ConfigureCostAllocation

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
Procedure AddStage_ConfigureCostAllocation(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.ConfigureCostAllocation);
	
	NewRow.MultilingualName = "vi = 'Tùy chỉnh phân bổ chi phí';
								|ru = 'Настройка распределения расходов';
								|en = 'Configure expense allocation';
								|it = 'Impostazione della ripartizione delle spese';
								|pl = 'Konfiguracja rozdziału rozchodów';
								|tr = 'Gider dağıtım ayarı'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Thực hiện';
								|ru = 'Выполнить';
								|en = 'Run'; fa = 'اجرا';
								|it = 'Eseguire';
								|pl = 'Run';
								|tr = 'Yürüt'");
	NewRow.ReadMoreText = MonthEndTransactionsServer.DefaultDetailsText();
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"CostsServer.Using_ConfiguringCostAllocation");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"CostsServer.Run_SettingUpCostAllocation");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.AllocationOfOtherCosts.Forms.WorkplaceForm.FullName());
	// Additional form parameters.
	NewRow.ActionMoreDetails.FormParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	NewRow.ActionMoreDetails.FormParameters.Insert("State", Enums.CostAllocationStates.DocumentGenerationIsRequired);
	NewRow.PerformedAtPreliminaryClosingOfMonth = True;
EndProcedure

// Stage handlers.

Procedure Using_ConfiguringCostAllocation(HandlerParameters) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	DistributionOptions = New Array();
	If HandlerParameters.CalculationParameters.MonthEndClosingMode <> Enums.MonthEndClosingModes.PreliminaryClosing Then
		DistributionOptions.Add(Enums.CostAllocationOptions.ToProductionCosts);
		DistributionOptions.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
		If (GetFunctionalOption("UseAccountingByExpenseObjects")) Then
			DistributionOptions.Add(Enums.CostAllocationOptions.ToCostCenters);
		EndIf;
	EndIf;
	If CalculationOfCostCached.BatchAccountingVersion22(HandlerParameters.CalculationParameters.RegistrationPeriod)
	 And (MonthEndTransactionsServer.GeneralParametersForClosingMonth().DistributionOfAdditionalCostsBetweenPartiesAndGoods
	 	Or HandlerParameters.CalculationParameters.MonthEndClosingMode <> Enums.MonthEndClosingModes.PreliminaryClosing) Then
		DistributionOptions.Add(Enums.CostAllocationOptions.ToInventoryCost);
	EndIf;
	
	If DistributionOptions.Count() = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có dữ liệu để phân bổ chi phí.';
				|ru = 'Нет данных для распределения расходов.';
				|en = 'No data for expense allocation.'; fa = 'No data for expense allocation.';
				|it = 'Non ci sono dati per l''allocazione delle spese.';
				|pl = 'Brak danych do przydziału rozchodów.';
				|tr = 'Gider dağıtımı için veri yoktur.'", Common.DefaultLanguageCode()));
		
		Return;
	
	EndIf;

	QueryOptions = Documents.AllocationOfOtherCosts.DescriptionOfParametersForRequestingDataForDistribution();
	QueryOptions.State = Enums.CostAllocationStates.DocumentGenerationIsRequired;
	QueryOptions.AllocationOption = DistributionOptions;
	QueryOptions.ExcludeTransportationCosts = True;
	Documents.AllocationOfOtherCosts.InitializeRequestToGetDataForDistribution(Query, QueryOptions);
	
	Query.Text = Documents.AllocationOfOtherCosts.QueryTextDataForDistribution(, True);
	
	Query.Execute();	
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.TTDataForDistribution = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có dữ liệu để phân bổ chi phí.';
				|ru = 'Нет данных для распределения расходов.';
				|en = 'No data for expense allocation.'; fa = 'No data for expense allocation.';
				|it = 'Non ci sono dati per l''allocazione delle spese.';
				|pl = 'Brak danych do przydziału rozchodów.';
				|tr = 'Gider dağıtımı için veri yoktur.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	If TemporaryTableSizes.StateOfCostAllocation = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Tất cả chi phí đã được phân bổ toàn bộ.';
				|ru = 'Все расходы полностью распределены.';
				|en = 'All expenses have been fully allocated.'; fa = 'All expenses have been fully allocated.';
				|it = 'Tutte le spese sono state completamente allocate.';
				|pl = 'Wszystkie rozchody zostały w całości przydzielone.';
				|tr = 'Tüm giderler tamamen dağıtıldı.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

Procedure Run_SettingUpCostAllocation(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	DistributionOptions = New Array;
	If HandlerParameters.CalculationParameters.MonthEndClosingMode <> Enums.MonthEndClosingModes.PreliminaryClosing Then
		DistributionOptions.Add(Enums.CostAllocationOptions.ToProductionCosts);
		DistributionOptions.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
		If (GetFunctionalOption("UseAccountingByExpenseObjects")) Then
			DistributionOptions.Add(Enums.CostAllocationOptions.ToCostCenters);
		EndIf;
	EndIf;
	If CalculationOfCostCached.BatchAccountingVersion22(CalculationParameters.RegistrationPeriod) Then
		DistributionOptions.Add(Enums.CostAllocationOptions.ToInventoryCost);
	EndIf;
	
	If DistributionOptions.Count() = 0 Then
		Return;
	EndIf;

	ArticlesForDistribution = Documents.AllocationOfOtherCosts.ArticlesForDistribution(
		CalculationParameters.RegistrationPeriod,
		CalculationParameters.CompanyArray,
		New Array,
		Enums.CostAllocationStates.DocumentGenerationIsRequired,
		DistributionOptions);
		
	If ArticlesForDistribution.Count() = 0 Then // there is no data for distribution
		Return;
	EndIf;
	
	ArticlesForDistribution.Columns.Add("Date", New TypeDescription("Date"));
	ArticlesForDistribution.Columns.Add("LineID", New TypeDescription("Number"));
	ArticlesForDistribution.FillValues(EndOfMonth(CalculationParameters.RegistrationPeriod), "Date");
	
	DistributionParameters = New Structure("ExpenseParameters", ArticlesForDistribution);
	DistributionParameters.Insert("CompanyArray", CalculationParameters.CompanyArray);
	DistributionParameters.Insert("RegistrationPeriod", CalculationParameters.RegistrationPeriod);
	
	// The formation of distribution documents is also carried out in the procedure of calculating the cost.Calculate the proposed cost().
	// When changing the procedure, perform_allocation adjustment() you need to check the code in the cost calculation.Calculate the approximate cost().
	
	Try
		FormationResults = Documents.AllocationOfOtherCosts.GenerateDocuments(DistributionParameters, Undefined);
	Except
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo chứng từ phân bổ trong kỳ %1. Cần phát sinh do lỗi:
				|%2';
				|ru = 'Не удалось создать документы распределения за период %1. Необходимость возникла из-за ошибки:
				|%2';
				|en = 'Cannot generate allocation document for the period %1. It is needed due to the error:
				|%2'; fa = 'Cannot generate allocation document for the period %1. It is needed due to the error:
				|%2';
				|it = 'Impossibile creare documenti di distribuzione per il periodo. %1. La necessità è causata da un errore:
				|%2';
				|pl = 'Nie można utworzyć dokumentów dystrybucyjnych za okres %1. Potrzeba powstała z powodu błędu:
				|%2';
				|tr = '%1 dönemi için dağıtım belgeleri oluşturulamadı. Gereklilik hata nedeniyle oluştu:
				|%2'", Common.DefaultLanguageCode()),
			CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
			DetailErrorDescription(ErrorInfo()));
		
		MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
			HandlerParameters,
			ErrorText);
		
	EndTry;
	
	For Each OrganizationResults In FormationResults Do
		
		FormationDetails = OrganizationResults.Value;
		
		If Not FormationDetails.ErrorsDescription.Count() Then
			Continue;
		EndIf;
		
		For Each ErrorDescription In FormationDetails.ErrorsDescription Do
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorDescription.ErrorText,
				OrganizationResults.Key,
				,
				,
				ErrorDescription.ExpenseItem);
		EndDo;
		
	EndDo;
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfChecks_ConfiguringCostAllocation(TableOfChecks) Export
	
	// Setting up cost allocation.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"ExpenseAllocationSettingsFailed",
		Catalogs.MonthEndClosingOperations.ConfigureCostAllocation,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"CostsServer.CheckingIfYouNeedToConfigureCostAllocation");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Tùy chỉnh phân bổ chi phí chưa thực hiện';
			|ru = 'Не выполненные настройки распределения расходов';
			|en = 'Not executed expense allocation settings'; fa = 'Not executed expense allocation settings';
			|it = 'Non è stata effettuata la configurazione dell''allocazione delle spese';
			|pl = 'Nie wykonane ustawienia podziału rozchodów';
			|tr = 'Gider dağıtımı ayarları gerçekleştirilmedi'", Common.DefaultLanguageCode()),
		NStr("vi = 'Cần phân bổ tất cả chi phí.';
			|ru = 'Все расходы должны быть распределены.';
			|en = 'All expenses should be allocated.'; fa = 'All expenses should be allocated.';
			|it = 'Tutte le spese devono essere allocate.';
			|pl = 'Wszystkie rozchody powinny być przydzielone.';
			|tr = 'Tüm giderler dağıtılmalıdır.'", Common.DefaultLanguageCode()));
	
EndProcedure

// Checking whether the cost allocation needs to be configured.
//
// Parameters:
//	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
//
Procedure CheckingIfYouNeedToConfigureCostAllocation(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	If CheckParameters.AdditionalParameters.AutoTesting Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 			NStr("vi = 'Doanh nghiệp';
													|ru = 'Организация';
													|en = 'Company'; fa = 'Company';
													|it = 'Azienda';
													|pl = 'Organizacja';
													|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Department", 			NStr("vi = 'Bộ phận';
												|ru = 'Подразделение';
												|en = 'Business unit'; fa = 'Business unit';
												|it = 'Reparto';
												|pl = 'Dział';
												|tr = 'Departman'", Common.DefaultLanguageCode()));
	FieldList.Add("LineOfBusiness", NStr("vi = 'Lĩnh vực hoạt động';
										|ru = 'Направление деятельности';
										|en = 'Line of business'; fa = 'خط کسب‌وکار';
										|it = 'Settore di attività';
										|pl = 'Rodzaj działalności';
										|tr = 'İş kolu'", Common.DefaultLanguageCode()));
	FieldList.Add("ExpenseItem", 			NStr("vi = 'Dạng chi phí';
													|ru = 'Статья расходов';
													|en = 'Expense item'; fa = 'قلم هزینه';
													|it = 'Voce di spese';
													|pl = 'Rodzaj kosztu';
													|tr = 'Gider kalemi'", Common.DefaultLanguageCode()));
	FieldList.Add("DimensionOfExpenses", 		NStr("vi = 'Chỉ số chi phí';
														|ru = 'Аналитика расходов';
														|en = 'Expense dimension'; fa = 'بُعد هزینه';
														|it = 'Analitica delle uscite';
														|pl = 'Analityka kosztów';
														|tr = 'Gider boyutu'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"StateOfCostAllocation",
		NStr("vi = 'Cần lập các chứng từ phân bổ chi phí theo doanh nghiệp ""%1"" trong kỳ %2';
			|ru = 'Требуется сформировать документы распределения расходов по организации ""%1"" в периоде %2';
			|en = 'Generate expense allocation documents for the ""%1"" company in the %2 period'; fa = 'Generate expense allocation documents for the ""%1"" company in the %2 period';
			|it = 'È richiesta la creazione di documenti di distribuzione delle spese per l''azienda ""%1"" nel periodo %2';
			|pl = 'Wymagana jest rejestracja dokumentów podziału rozchodów według firmy ""%1"" w okresie %2';
			|tr = '""%1"" iş yeri için %2 döneminde gider dağıtım belgelerinin oluşturulması gerekiyor'", Common.DefaultLanguageCode()),
		FieldList);
	
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
		
EndProcedure

#EndRegion

#Region ConfigureExpensesAllocationThatRequireManualInput

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
Procedure AddStage_ConfigureExpensesAllocationThatRequireManualInput(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.ConfigureExpensesAllocationThatRequireManualInput);
	
	NewRow.MultilingualName = "vi = 'Tùy chỉnh phân bổ chi phí cần nhập thủ công';
								|ru = 'Настройка распределения расходов, требующих ручного ввода';
								|en = 'Configure expenses allocation that require manual input';
								|it = 'Configurazione di allocazione delle spese che richiedono l''inserimento manuale';
								|pl = 'Ustawienie przydzielenia rozchodów, wymagających ręcznego wprowadzenia';
								|tr = 'Manuel giriş gerektiren gider dağıtım ayarı'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute = NStr("vi = 'Nhập';
								|ru = 'Ввести';
								|en = 'Enter'; fa = 'ورود';
								|it = 'Inserire';
								|pl = 'Enter';
								|tr = 'Gir'");
	NewRow.ReadMoreText = MonthEndTransactionsServer.DefaultDetailsText();
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"CostsServer.Using_ConfigureCostAllocationManually");
	NewRow.ActionExecute = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.AllocationOfOtherCosts.Forms.WorkplaceForm.FullName());
	// Additional form parameters.
	NewRow.ActionExecute.FormParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	NewRow.ActionExecute.FormParameters.Insert("State", Enums.CostAllocationStates.RequiresManualDocumentInput);

	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.AllocationOfOtherCosts.Forms.WorkplaceForm.FullName());
	// Additional form parameters.
	NewRow.ActionMoreDetails.FormParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	NewRow.ActionMoreDetails.FormParameters.Insert("State", Enums.CostAllocationStates.RequiresManualDocumentInput);
EndProcedure

// Stage handlers.

Procedure Using_ConfigureCostAllocationManually(HandlerParameters) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	DistributionOptions = New Array();
	DistributionOptions.Add(Enums.CostAllocationOptions.ToProductionCosts);
	DistributionOptions.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
	If (GetFunctionalOption("UseAccountingByExpenseObjects")) Then
		DistributionOptions.Add(Enums.CostAllocationOptions.ToCostCenters);
	EndIf;
	If CalculationOfCostCached.BatchAccountingVersion22(HandlerParameters.CalculationParameters.RegistrationPeriod) Then
		DistributionOptions.Add(Enums.CostAllocationOptions.ToInventoryCost);
	EndIf;
	
	If DistributionOptions.Count() = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có dữ liệu để phân bổ chi phí.';
				|ru = 'Нет данных для распределения расходов.';
				|en = 'No data for expense allocation.'; fa = 'No data for expense allocation.';
				|it = 'Non ci sono dati per l''allocazione delle spese.';
				|pl = 'Brak danych do przydziału rozchodów.';
				|tr = 'Gider dağıtımı için veri yoktur.'", Common.DefaultLanguageCode()));
		
		Return;
	
	EndIf;

	QueryOptions = Documents.AllocationOfOtherCosts.DescriptionOfParametersForRequestingDataForDistribution();
	QueryOptions.State = Enums.CostAllocationStates.RequiresManualDocumentInput;
	QueryOptions.AllocationOption = DistributionOptions;
	QueryOptions.ExcludeTransportationCosts = True;
	Documents.AllocationOfOtherCosts.InitializeRequestToGetDataForDistribution(Query, QueryOptions);
	
	Query.Text = Documents.AllocationOfOtherCosts.QueryTextDataForDistribution(, True);
	
	Query.Execute();	
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.TTDataForDistribution = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có dữ liệu để phân bổ chi phí.';
				|ru = 'Нет данных для распределения расходов.';
				|en = 'No data for expense allocation.'; fa = 'No data for expense allocation.';
				|it = 'Non ci sono dati per l''allocazione delle spese.';
				|pl = 'Brak danych do przydziału rozchodów.';
				|tr = 'Gider dağıtımı için veri yoktur.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	If TemporaryTableSizes.StateOfCostAllocation = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Tất cả chi phí sản xuất đều đã được phân bổ hoàn toàn theo dạng tính giá thành.';
				|ru = 'Все производственные расходы полностью распределены по статьям калькуляции.';
				|en = 'All production costs are completely allocated to product cost elements.'; fa = 'All production costs are completely allocated to product cost elements.';
				|it = 'Tutte le spese di produzione sono completamente allocate sugli elementi di calcolo.';
				|pl = 'Wszystkie wydatki produkcyjne w całości są podzielone wg pozycji kalkulacji.';
				|tr = 'Tüm üretim maliyetleri tamamen ürün maliyet kalemlerine dağıtılır.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfChecks_SettingUpCostAllocationManually(TableOfChecks) Export
	
	// Setting up cost allocation.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"NoManualCostAllocationSettings",
		Catalogs.MonthEndClosingOperations.ConfigureExpensesAllocationThatRequireManualInput,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"CostsServer.CheckingIfYouNeedToConfigureCostAllocationManually");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Chưa nhập tùy chỉnh phân bổ chi phí, cần nhập thủ công';
			|ru = 'Не внесены настройки распределения расходов, требующие ручной ввод';
			|en = 'Expense allocation settings that require manual entry have not been made'; fa = 'Expense allocation settings that require manual entry have not been made';
			|it = 'Non sono state inserite le impostazioni di allocazione delle spese richiedenti inserimento manuale';
			|pl = 'Nie wprowadzono ustawień przydzielenia rozchodów, wymagających ręcznego wprowadzenia';
			|tr = 'Manuel giriş gerektiren maliyet dağıtımı ayarları yapılmadı'", Common.DefaultLanguageCode()),
		NStr("vi = 'Tất cả chi phí sản xuất cần được phân bổ đầy đủ';
			|ru = 'Все производственные расходы должны быть полностью распределены';
			|en = 'All production costs must be fully allocated'; fa = 'All production costs must be fully allocated';
			|it = 'Tutte le spese di produzione devono essere completamente allocate';
			|pl = 'Wszystkie procesy produkcyjne powinny być w całości przydzielone';
			|tr = 'Tüm üretim maliyetleri tamamen dağıtılmalıdır'", Common.DefaultLanguageCode()));
	
EndProcedure

Procedure CheckingIfYouNeedToConfigureCostAllocationManually(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 			NStr("vi = 'Doanh nghiệp';
													|ru = 'Организация';
													|en = 'Company'; fa = 'Company';
													|it = 'Azienda';
													|pl = 'Organizacja';
													|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Department", 			NStr("vi = 'Bộ phận';
												|ru = 'Подразделение';
												|en = 'Business unit'; fa = 'Business unit';
												|it = 'Reparto';
												|pl = 'Dział';
												|tr = 'Departman'", Common.DefaultLanguageCode()));
	FieldList.Add("LineOfBusiness", NStr("vi = 'Lĩnh vực hoạt động';
										|ru = 'Направление деятельности';
										|en = 'Line of business'; fa = 'خط کسب‌وکار';
										|it = 'Settore di attività';
										|pl = 'Rodzaj działalności';
										|tr = 'İş kolu'", Common.DefaultLanguageCode()));
	FieldList.Add("ExpenseItem", 			NStr("vi = 'Dạng chi phí';
													|ru = 'Статья расходов';
													|en = 'Expense item'; fa = 'قلم هزینه';
													|it = 'Voce di spese';
													|pl = 'Rodzaj kosztu';
													|tr = 'Gider kalemi'", Common.DefaultLanguageCode()));
	FieldList.Add("DimensionOfExpenses", 		NStr("vi = 'Chỉ số chi phí';
														|ru = 'Аналитика расходов';
														|en = 'Expense dimension'; fa = 'بُعد هزینه';
														|it = 'Analitica delle uscite';
														|pl = 'Analityka kosztów';
														|tr = 'Gider boyutu'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"StateOfCostAllocation",
		NStr("vi = 'Đã tìm thấy dạng chi phí cần tùy chỉnh phân bổ thủ công, theo doanh nghiệp ""%1"" đến cuối kỳ %2';
			|ru = 'Обнаружены статьи расходов, требующие ручной настройки распределения, по организации ""%1"" на конец периода %2';
			|en = 'Expense items were detected that require manual allocation configuration for the ""%1"" company as of the end of %2 period'; fa = 'Expense items were detected that require manual allocation configuration for the ""%1"" company as of the end of %2 period';
			|it = 'Trovate le voci di spesa che richiedono l''aggiustamento manuale dell''allocazione, per l''organizzazione ""%1"" alla fine del periodo %2';
			|pl = 'Wykryto pozycje rozchodów, wymagające ręcznego ustawienia podziału, wg firm ""%1"" na koniec okresu %2';
			|tr = '%2 döneminin sonunda ""%1"" iş yeri için manuel dağıtım ayarlaması gerektiren gider kalemleri bulundu'", Common.DefaultLanguageCode()),
		FieldList);
	
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
		
EndProcedure

#EndRegion

#Region AllocationOfMaterialsAndWorksToProductsCost22

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
Procedure AddStage_AllocationOfMaterialsAndWorksToProductsCost22(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.AllocationOfMaterialsAndWorksToProductsCost22);
	
	NewRow.MultilingualName =
		"vi = 'Phân bổ nguyên vật liệu và công việc cho giá vốn sản phẩm (phiên bản 2.2)';
		|ru = 'Распределение материалов и работ на себестоимость продукции (версия 2.2)';
		|en = 'Material and labor allocation to product cost (version 2.2)';
		|it = 'Allocazione dei materiali e dei lavori sul costo di produzione dei prodotti (versione 2.2)';
		|pl = 'Dystrybucja materiałów i prac na koszt własny produkcji (wersja 2.2)';
		|tr = 'İmal edilen ürün maliyetine malzeme ve iş dağıtımı (2.2 sürümü)'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"CostsServer.Registration_DistributionOfMaterialsAndWorksAtCostOfProduction22");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"CostsServer.Use_DistributionOfMaterialsAndWorkAtCostOfProduction22");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.ProductionCostAllocation.Forms.MaterialAndLaborAllocationForm.FullName());
	// Additional form parameters.
	NewRow.ActionExecute.FormParameters.Insert("State",     		     		"AllocationIsRequired");
	NewRow.ActionExecute.FormParameters.Insert("Department", 		     		Catalogs.BusinessStructure.EmptyRef());
	NewRow.ActionExecute.FormParameters.Insert("ArrangeProductionWithoutOrders", False);
EndProcedure

// Stage handlers.

Procedure Use_DistributionOfMaterialsAndWorkAtCostOfProduction22(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("UseProduction") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không hạch toán hoạt động sản xuất';
				|ru = 'Учет производственных операций не ведется';
				|en = 'Production operation accounting is not kept'; fa = 'Production operation accounting is not kept';
				|it = 'La contabilizzazione delle operazioni di produzione non viene effettuata';
				|pl = 'Ewidencja operacji produkcyjnych nie jest prowadzona';
				|tr = 'Rota işlemleri muhasebesi yapılmamaktadır'", Common.DefaultLanguageCode()));
			
		Return;
		
	EndIf;
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	ProductionSettings = ProductionServer.SubsystemSettingsProduction();
	
	If Not ProductionSettings.ProductionIsUsed22 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không quản lý sản xuất (phiên bản 2.2)';
				|ru = 'Не используется управление производством (версия 2.2)';
				|en = 'Production management, version 2.2 is not used'; fa = 'Production management, version 2.2 is not used';
				|it = 'Gestione della produzione non utilizzata (versione 2.2)';
				|pl = 'Nie jest używane zarządzanie produkcją (wersja 2.2)';
				|tr = 'Üretim yönetimi kullanılmamaktadır (sürüm 2.2)'", Common.DefaultLanguageCode()));
			
		Return;
		
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text = Documents.ProductionCostAllocation.RequestTextForMaterialsAndWorksInStorerooms(True);
	
	// Additional request parameters.
	Query.SetParameter("AllRegisteredRecords",             True);
	Query.SetParameter("BeginOfPeriod",  	     Query.Parameters.BeginOfPeriod);
	Query.SetParameter("PeriodEnding",  	     Query.Parameters.EndOfPeriod);
	Query.SetParameter("BorderEndOfPeriod_", Query.Parameters.BorderEndOfPeriod);
	Query.SetParameter("AllCompanies",	         False);
	Query.SetParameter("Companies",       	     Query.Parameters.CompanyArray);
	Query.SetParameter("AllDepartments",  	     True);
	Query.SetParameter("Departments",     	     New Array);
	Query.SetParameter("AllTypesOfProducts",     True);
	Query.SetParameter("ItemsType",         Undefined);
	Query.SetParameter("AllAnalysts",	           True);
	Query.SetParameter("ItemsLocationAttributes",Undefined);
	
	Query.Execute();
	
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	DD.Organization
	|INTO MaterialRegisteredRecordsInProduction
	|FROM
	|	AccumulationRegister.MaterialsAndWorksInProduction AS DD
	|WHERE
	|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|	AND DD.Organization IN (&CompanyArray)
	|	AND DD.Active
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialsAndWorks.Organization,
	|	MaterialsAndWorks.Department,
	|	MaterialsAndWorks.Products,
	|	MaterialsAndWorks.Characteristic,
	|	MaterialsAndWorks.Series,
	|	MaterialsAndWorks.Allocate AS Count
	|INTO TTUnallocatedMaterialsAndWorks
	|FROM
	|	MaterialsAndWorks AS MaterialsAndWorks
	|WHERE
	|	MaterialsAndWorks.Allocate > 0
	|	AND MaterialsAndWorks.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT
	|	MaterialsAndWorks.Organization,
	|	MaterialsAndWorks.Department,
	|	MaterialsAndWorks.Products,
	|	MaterialsAndWorks.Characteristic,
	|	MaterialsAndWorks.Series,
	|	MaterialsAndWorks.Allocate AS Count
	|FROM
	|	MaterialsAndWorks AS MaterialsAndWorks
	|	LEFT JOIN MaterialRegisteredRecordsInProduction AS MaterialRegisteredRecordsInProduction
	|	ON MaterialsAndWorks.Organization = MaterialRegisteredRecordsInProduction.Organization
	|WHERE
	|	MaterialsAndWorks.Allocate > 0
	|	AND MaterialsAndWorks.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND MaterialRegisteredRecordsInProduction.Organization IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	MaterialsAndWorks.Organization
	|INTO TTDistributedMaterialsAndWorks
	|FROM
	|	MaterialsAndWorks AS MaterialsAndWorks
	|WHERE
	|	MaterialsAndWorks.Allocated > 0";
	
	Query.Execute();
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.TTUnallocatedMaterialsAndWorks = 0
	 And TemporaryTableSizes.TTDistributedMaterialsAndWorks = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có nguyên liệu và công việc để phân bổ cho các kỳ sản xuất';
				|ru = 'Нет материалов и работ для распределения на этапы производства';
				|en = 'No materials or works to allocate to production stages'; fa = 'No materials or works to allocate to production stages';
				|it = 'Non ci sono né materiali né lavori per la loro allocazione sulle fasi produzione';
				|pl = 'Brak materiałów i robót do przydziału do etapów produkcji';
				|tr = 'Üretim aşamalarına dağıtılacak malzeme ve iş bulunmamaktadır'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure



// Making an operation at the end of the month.
// 
// Parameters:
// 	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
Procedure Registration_DistributionOfMaterialsAndWorksAtCostOfProduction22(HandlerParameters) Export
	
	ProductionSettings = ProductionServer.SubsystemSettingsProduction();
	
	If Not (ProductionSettings.ProductionIsUsed21 And ProductionSettings.ProductionIsUsed22) Then
		HandlerParameters.Data_Stage.Description = NStr("vi = 'Phân bổ nguyên vật liệu và công việc vào giá vốn sản phẩm';
														|ru = 'Распределение материалов и работ на себестоимость продукции';
														|en = 'Material and labor allocation to product cost'; fa = 'تسهیم مواد و کار به بهای تمام‌شده محصول';
														|it = 'Allocazione dei materiali e dei lavori sul costo di produzione dei prodotti';
														|pl = 'Przydział materiałów i robót na koszty własne produkcji';
														|tr = 'İmal edilen ürünler maliyetine malzeme ve iş dağıtımı'");
	EndIf;
	
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Phân bổ';
													|ru = 'Распределить';
													|en = 'Allocate'; fa = 'تسهیم';
													|it = 'Ripartire';
													|pl = 'Allocate';
													|tr = 'Dağıt'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfInspections_DistributionOfMaterialsAndWorkOnCostOfProduction22(TableOfChecks) Export
	
	// Distribution of materials and works for the cost of production (2.2).
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"MaterialsAndWorksHaveNotBeenDistributedToCostOfProduction",
		Catalogs.MonthEndClosingOperations.AllocationOfMaterialsAndWorksToProductsCost22,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"CostsServer.VerificationOfNeedToDistributeMaterialsAndWorkToCostOfProduction22");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Nguyên liệu (công việc) chưa được phân bổ vào các công đoạn sản xuất';
			|ru = 'Не распределенные материалы (работы) на этапы производства';
			|en = 'Non-allocated materials (works) to production stages'; fa = 'Non-allocated materials (works) to production stages';
			|it = 'Materiali (lavori) non allocati sulle fasi di produzione';
			|pl = 'Nieprzydzielone materiały (roboty) do etapów produkcji';
			|tr = 'Üretim aşamalarına dağıtılmayan malzemeler (işler)'", Common.DefaultLanguageCode()),
		NStr("vi = 'Cần phân bổ tất cả các vật liệu và nhân công vào các giai đoạn sản xuất bằng các chứng từ ""Phân bổ vật liệu và nhân công"".';
			|ru = 'Должно быть оформлено распределение всех материалов и работ на этапы производства документами ""Распределение материалов и работ"".';
			|en = 'Allocation of all materials and works to production stages should be registered with the ""Material and labor allocation"" documents.'; fa = 'Allocation of all materials and works to production stages should be registered with the ""Material and labor allocation"" documents.';
			|it = 'Deve essere regolarizzata un''allocazione di tutti i materiali e dei lavori sulle fasi di produzione tramite i documenti ""Allocazione dei materiali e dei lavori"".';
			|pl = 'Musi być sporządzony przydział wszystkich materiałów i robót do etapów produkcji w dokumentach ""Распределение материалов и работ"".';
			|tr = 'Tüm malzeme ve işlerin üretim aşamalarına dağıtımı “Malzeme ve işçilik tahsisatı” belgeleri ile düzenlenmelidir.'", Common.DefaultLanguageCode()));
	
EndProcedure

Procedure VerificationOfNeedToDistributeMaterialsAndWorkToCostOfProduction22(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 	NStr("vi = 'Doanh nghiệp';
											|ru = 'Организация';
											|en = 'Company'; fa = 'Company';
											|it = 'Azienda';
											|pl = 'Organizacja';
											|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Department", 	NStr("vi = 'Bộ phận';
										|ru = 'Подразделение';
										|en = 'Business unit'; fa = 'Business unit';
										|it = 'Reparto';
										|pl = 'Dział';
										|tr = 'Departman'", Common.DefaultLanguageCode()));
	FieldList.Add("Products", 	NStr("vi = 'Mặt hàng';
										|ru = 'Номенклатура';
										|en = 'Items'; fa = 'اقلام';
										|it = 'Articolo';
										|pl = 'Produkt';
										|tr = 'Öğe'", Common.DefaultLanguageCode()));
	FieldList.Add("Characteristic", 	NStr("vi = 'Đặc tính';
											|ru = 'Характеристика';
											|en = 'Variant'; fa = 'گونه';
											|it = 'Caratteristica';
											|pl = 'Charakterystyka';
											|tr = 'Varyant'", Common.DefaultLanguageCode()));
	FieldList.Add("Series", 			NStr("vi = 'Seri';
											|ru = 'Серия';
											|en = 'Batch'; fa = 'بچ';
											|it = 'Serie';
											|pl = 'Seria';
											|tr = 'Parti'", Common.DefaultLanguageCode()));
	FieldList.Add("Count",		NStr("vi = 'Số lượng';
										|ru = 'Количество';
										|en = 'Quantity'; fa = 'مقدار';
										|it = 'Quantità';
										|pl = 'Ilość';
										|tr = 'Miktar'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTUnallocatedMaterialsAndWorks",
		NStr("vi = 'Đã tìm thấy chưa phân bổ vật liệu (nhân công) vào các giai đoạn sản xuất của doanh nghiệp ""%1"" vào cuối kỳ %2';
			|ru = 'Обнаружены не распределенные на этапы производства материалы (работы) организации ""%1"" на конец периода %2';
			|en = 'Materials (works) not allocated for production stages are detected for the ""%1"" company as of the end of %2 period'; fa = 'Materials (works) not allocated for production stages are detected for the ""%1"" company as of the end of %2 period';
			|it = 'Trovati dei materiali (lavori) non allocati sulle fasi di produzione dell''organizzazione ""%1"" per la fine del periodo %2';
			|pl = 'Wykryto nie przydzielone do etapów produkcji materiały (roboty) firmy ""%1"" na koniec okresu %2';
			|tr = '""%1"" iş yerinin üretim aşamalarına dağıtılmayan malzemeleri (işleri) %2 döneminin sonunda bulundu'", Common.DefaultLanguageCode()),
		FieldList);
	
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#Region ConfigureIndicatorsForCostAllocationToProductCost

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
Procedure AddStage_ConfigureIndicatorsForCostAllocationToProductCost(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.ConfigureIndicatorsForCostAllocationToProductCost);
	
	NewRow.MultilingualName =
		"vi = 'Cài đặt chỉ tiêu phân bổ chi phí trên giá thành sản xuất';
		|ru = 'Настройка показателей для распределения расходов на себестоимость продукции';
		|en = 'Configure indicators for expense allocation to product cost';
		|it = 'Inserimento degli indicatori per la ripartizione delle spese per il prezzo del costo di prodotti';
		|pl = 'Konfiguracja wskaźników do rozdziału rozchodów na koszty własne produkcji';
		|tr = 'Giderlerin imal edilen ürün maliyetine dağıtımı için göstergelerin ayarı'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute = NStr("vi = 'Tùy chỉnh';
								|ru = 'Настроить';
								|en = 'Customize'; fa = 'سفارشی‌سازی';
								|it = 'Impostare';
								|pl = 'Customize';
								|tr = 'Ayarla'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"CostsServer.Use_SettingIndicatorsForAllocatingCostsToCostOfProduction");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Catalogs.CostAllocationRules.Forms.ListFormManually.FullName());
	// Additional form parameters.
	NewRow.ActionExecute.FormParameters.Insert("OnlyEmpty", True);
EndProcedure

// Stage handlers.

Procedure Use_SettingIndicatorsForAllocatingCostsToCostOfProduction(HandlerParameters) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	QueryOptions = Documents.AllocationOfOtherCosts.DescriptionOfParametersForRequestingDataForDistribution();
	Documents.AllocationOfOtherCosts.InitializeRequestToGetDataForDistribution(Query, QueryOptions);
	
	Query.Text = "SELECT DISTINCT
	|	DD.Organization AS Organization,
	|	DD.Factor AS Factor
	|INTO TTIndicatorsUsed
	|FROM
	|	Document.AllocationOfOtherCosts AS DD
	|WHERE
	|	DD.Posted
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Organization IN (&CompanyArray)
	|	AND DD.AssignAllocationSetting IN (
	|		VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots),
	|		VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits)
	|	)
	|	AND DD.BaseOfAllocationByBusinessUnits IN (
	|		VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis),
	|		VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand)
	|	)";
	
	Query.Execute();	
	
	If MonthEndTransactionsServer.TemporaryTableSize(Query, "TTIndicatorsUsed", HandlerParameters) = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có dữ liệu để phân bổ chi phí.';
				|ru = 'Нет данных для распределения расходов.';
				|en = 'No data for expense allocation.'; fa = 'No data for expense allocation.';
				|it = 'Non ci sono dati per l''allocazione delle spese.';
				|pl = 'Brak danych do przydziału rozchodów.';
				|tr = 'Gider dağıtımı için veri yoktur.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	Query.Text =
	"SELECT
	|	T.Organization AS Organization,
	|	T.Factor AS Factor
	|INTO TTIncorrectMetrics
	|FROM
	|	TTIndicatorsUsed AS T
	|	INNER JOIN Catalog.CostAllocationRules AS Indicators
	|		ON Indicators.Ref = T.Factor
	|	LEFT JOIN InformationRegister.IndicatorValuesToAllocateCosts AS ValuesMonthly
	|		ON Indicators.Ref = ValuesMonthly.Factor
	|		AND (BEGINOFPERIOD(ValuesMonthly.Period, MONTH) = &BeginOfPeriod)
	|WHERE
	|	Indicators.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis)
	|	AND Indicators.AssignRule = VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits)
	|	AND ValuesMonthly.Factor IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	T.Organization,
	|	T.Factor
	|FROM
	|	TTIndicatorsUsed AS T
	|	INNER JOIN Catalog.CostAllocationRules AS Indicators
	|		ON Indicators.Ref = T.Factor
	|	LEFT JOIN InformationRegister.IndicatorValuesToAllocateCosts.SliceLast(&EndOfPeriod,) AS ValuesOnChange
	|		ON Indicators.Ref = ValuesOnChange.Factor
	|WHERE
	|	Indicators.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand)
	|	AND Indicators.AssignRule = VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits)
	|	AND ValuesOnChange.Factor IS NULL";
	
	Query.Execute();
	
	If MonthEndTransactionsServer.TemporaryTableSize(Query, "TTIncorrectMetrics", HandlerParameters) = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Đã thiết lập chính xác các chỉ tiêu phân bổ chi phí.';
				|ru = 'Все показатели распределения расходов настроены корректно.';
				|en = 'All expense allocation indicators are configured correctly.'; fa = 'All expense allocation indicators are configured correctly.';
				|it = 'Tutti gli indicatori dell''allocazione delle spese sono configurati correttamente.';
				|pl = 'Wszystkie wskaźniki przydziału rozchodów są ustawione poprawnie.';
				|tr = 'Tüm gider dağıtım göstergeleri doğru şekilde ayarlanmıştır.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfChecks_SettingUpIndicatorsForAllocatingCostsToCostOfProduction(TableOfChecks) Export
	
	// Setting up indicators for allocating costs to the cost of production.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"IndicatorsForAllocatingCostsToCostOfProductionWereNotConfigured",
		Catalogs.MonthEndClosingOperations.ConfigureIndicatorsForCostAllocationToProductCost,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"CostsServer.CheckingNeedToAdjustIndicatorsForAllocatingCostsToCostOfProduction");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Số liệu phân bổ chi phí chưa được xác định';
			|ru = 'Не заданные значения показателей распределения расходов';
			|en = 'Values of expense allocation indicators are not specified'; fa = 'Values of expense allocation indicators are not specified';
			|it = 'Indicatori di allocazione dei costi non indicati';
			|pl = 'Nie określone wartości wskaźników przydziału rozchodów';
			|tr = 'Gider dağıtım göstergeleri için belirtilmemiş değerler'", Common.DefaultLanguageCode()),
		NStr("vi = 'Đối với các chỉ tiêu có cơ sở phân bổ ""Được nhập hàng tháng"" và ""Được nhập khi thay đổi"" cần điền giá trị trong kỳ tính toán.';
			|ru = 'Для показателей с базами распределения ""Вводится ежемесячно"" и ""Вводится при изменении"" должны быть заполнены значения в рассчитываемом периоде.';
			|en = 'Values in the calculated period should be calculated for indicators with the ""Entered monthly"" and ""Entered on change"" allocation bases.'; fa = 'Values in the calculated period should be calculated for indicators with the ""Entered monthly"" and ""Entered on change"" allocation bases.';
			|it = 'Per gli indicatori con una base di allocazione, ""Introdotto mensilmente"" e ""Introdotto dopo il cambiamento"", i valori nel periodo calcolato devono essere riempiti.';
			|pl = 'Dla wskaźników z bazami przydziału ""Вводится ежемесячно"" i ""Вводится при изменении"" powinny być wypełnione wartości w obliczanym okresie.';
			|tr = '""Aylık girilir"" ve ""Değişirken girilir"" tahsisat tabanına sahip göstergeler için hesaplanan dönemdeki değerlerin doldurulması gerekir.'", Common.DefaultLanguageCode()));
	
EndProcedure

Procedure CheckingNeedToAdjustIndicatorsForAllocatingCostsToCostOfProduction(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Company';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Factor", 	NStr("vi = 'Chỉ tiêu';
									|ru = 'Показатель';
									|en = 'Indicator'; fa = 'شاخص';
									|it = 'Indicatore';
									|pl = 'Indicator';
									|tr = 'Gösterge'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTIncorrectMetrics",
		NStr("vi = 'Đã tìm thấy các chỉ số mà chưa xác định giá trị của chúng trong kỳ %2';
			|ru = 'Обнаружены показатели, значения которых не заданы в периоде %2';
			|en = 'Indicators detected whose values were not specified in %2 period'; fa = 'Indicators detected whose values were not specified in %2 period';
			|it = 'Trovati degli indicatori, i cui valori non sono indicati nel periodo %2';
			|pl = 'Wykryto wskaźniki, wartości których nie są określone w okresie %2';
			|tr = '%2 döneminde değerleri ayarlanmayan göstergeler bulundu'", Common.DefaultLanguageCode()),
		FieldList,
		"Factor");
	
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#Region ConfigureIndicatorsForExpensesAllocationBetweenExpenseObjects

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
Procedure AddStage_ConfigureIndicatorsForExpensesAllocationBetweenExpenseObjects(StepsTable,CurrentParent) Export

	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.ConfigureIndicatorsForExpensesAllocationBetweenExpenseObjects);
	
	NewRow.MultilingualName =
		"vi = 'Tùy chỉnh chỉ tiêu để phân bổ chi phí giữa các đối tượng phát sinh chi phí';
		|ru = 'Настройка показателей для распределения расходов между ОВЗ';
		|en = 'Configure indicators for expenses allocation between cost centers';
		|it = 'Configurazione di indicatori per allocazione delle spese tra CdC';
		|pl = 'Ustawienie wskaźników do przydzielenia rozchodów między obiektami tworzenia się rozchodów';
		|tr = 'Gider oluşum nesneleri arasında giderlerin dağıtımı için göstergelerin ayarı'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute = NStr("vi = 'Tùy chỉnh';
								|ru = 'Настроить';
								|en = 'Customize'; fa = 'سفارشی‌سازی';
								|it = 'Impostare';
								|pl = 'Customize';
								|tr = 'Ayarla'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"CostsServer.Using_ConfiguringMetricsForAllocatingCostsAmongHIA");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Catalogs.CostAllocationRules.Forms.ListFormManually.FullName());
	// Additional form parameters.
	NewRow.ActionExecute.FormParameters.Insert("OnlyEmpty", True);
	NewRow.ActionExecute.FormParameters.Insert("AssignRule", Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter);
	
	If Not (GetFunctionalOption("UseAccountingByExpenseObjects")) Then
		NewRow.DisabledByFO = True;
	EndIf;
		
EndProcedure

// Stage handlers.

Procedure Using_ConfiguringMetricsForAllocatingCostsAmongHIA(HandlerParameters) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	QueryOptions = Documents.AllocationOfOtherCosts.DescriptionOfParametersForRequestingDataForDistribution();
	Documents.AllocationOfOtherCosts.InitializeRequestToGetDataForDistribution(Query, QueryOptions);
	
	Query.Text = "SELECT DISTINCT
	|	DD.Organization AS Organization,
	|	DD.Factor AS Factor
	|INTO TTIndicatorsUsed
	|FROM
	|	Document.AllocationOfOtherCosts AS DD
	|WHERE
	|	DD.Posted
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Organization IN (&CompanyArray)
	|	AND DD.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationToCostCenter)
	|	AND DD.BaseOfAllocationByBusinessUnits IN (
	|		VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis),
	|		VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand)
	|	)";
	
	Query.Execute();	
	
	If MonthEndTransactionsServer.TemporaryTableSize(Query, "TTIndicatorsUsed", HandlerParameters) = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có dữ liệu để phân bổ chi phí.';
				|ru = 'Нет данных для распределения расходов.';
				|en = 'No data for expense allocation.'; fa = 'No data for expense allocation.';
				|it = 'Non ci sono dati per l''allocazione delle spese.';
				|pl = 'Brak danych do przydziału rozchodów.';
				|tr = 'Gider dağıtımı için veri yoktur.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	Query.Text =
	"SELECT
	|	T.Organization AS Organization,
	|	T.Factor AS Factor
	|INTO TTIncorrectMetrics
	|FROM
	|	TTIndicatorsUsed AS T
	|	INNER JOIN Catalog.CostAllocationRules AS Indicators
	|		ON Indicators.Ref = T.Factor
	|	LEFT JOIN InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects AS ValuesMonthly
	|		ON Indicators.Ref = ValuesMonthly.Factor
	|		AND (BEGINOFPERIOD(ValuesMonthly.Period, MONTH) = &BeginOfPeriod)
	|WHERE
	|	Indicators.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis)
	|	AND Indicators.AssignRule = VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationToCostCenter)
	|	AND ValuesMonthly.Factor IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	T.Organization,
	|	T.Factor
	|FROM
	|	TTIndicatorsUsed AS T
	|	INNER JOIN Catalog.CostAllocationRules AS Indicators
	|		ON Indicators.Ref = T.Factor
	|	LEFT JOIN InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects.SliceLast(&EndOfPeriod,) AS ValuesOnChange
	|		ON Indicators.Ref = ValuesOnChange.Factor
	|WHERE
	|	Indicators.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand)
	|	AND Indicators.AssignRule = VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationToCostCenter)
	|	AND ValuesOnChange.Factor IS NULL";
	
	Query.Execute();
	
	If MonthEndTransactionsServer.TemporaryTableSize(Query, "TTIncorrectMetrics", HandlerParameters) = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Đã thiết lập chính xác các chỉ tiêu phân bổ chi phí.';
				|ru = 'Все показатели распределения расходов настроены корректно.';
				|en = 'All expense allocation indicators are configured correctly.'; fa = 'All expense allocation indicators are configured correctly.';
				|it = 'Tutti gli indicatori dell''allocazione delle spese sono configurati correttamente.';
				|pl = 'Wszystkie wskaźniki przydziału rozchodów są ustawione poprawnie.';
				|tr = 'Tüm gider dağıtım göstergeleri doğru şekilde ayarlanmıştır.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfChecks_SettingIndicatorsForAllocatingExpensesBetweenHIA(TableOfChecks) Export
	
	If Not (GetFunctionalOption("UseAccountingByExpenseObjects")) Then
		Return
	EndIf;
	
	// Setting up indicators for allocating costs to the cost of production.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"IndicatorsForAllocationOfExpensesBetweenHIAWereNotConfigured",
		Catalogs.MonthEndClosingOperations.ConfigureIndicatorsForExpensesAllocationBetweenExpenseObjects,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"CostsServer.CheckingNeedToConfigureIndicatorsForDistributionOfCostsBetweenHIA");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Số liệu phân bổ chi phí chưa được xác định';
			|ru = 'Не заданные значения показателей распределения расходов';
			|en = 'Values of expense allocation indicators are not specified'; fa = 'Values of expense allocation indicators are not specified';
			|it = 'Indicatori di allocazione dei costi non indicati';
			|pl = 'Nie określone wartości wskaźników przydziału rozchodów';
			|tr = 'Gider dağıtım göstergeleri için belirtilmemiş değerler'", Common.DefaultLanguageCode()),
		NStr("vi = 'Đối với các chỉ tiêu có cơ sở phân bổ ""Được nhập hàng tháng"" và ""Được nhập khi thay đổi"" cần điền giá trị trong kỳ tính toán.';
			|ru = 'Для показателей с базами распределения ""Вводится ежемесячно"" и ""Вводится при изменении"" должны быть заполнены значения в рассчитываемом периоде.';
			|en = 'Values in the calculated period should be calculated for indicators with the ""Entered monthly"" and ""Entered on change"" allocation bases.'; fa = 'Values in the calculated period should be calculated for indicators with the ""Entered monthly"" and ""Entered on change"" allocation bases.';
			|it = 'Per gli indicatori con una base di allocazione, ""Introdotto mensilmente"" e ""Introdotto dopo il cambiamento"", i valori nel periodo calcolato devono essere riempiti.';
			|pl = 'Dla wskaźników z bazami przydziału ""Вводится ежемесячно"" i ""Вводится при изменении"" powinny być wypełnione wartości w obliczanym okresie.';
			|tr = '""Aylık girilir"" ve ""Değişirken girilir"" tahsisat tabanı sahip göstergeler için hesaplanan dönemdeki değerlerin doldurulması gerekir.'", Common.DefaultLanguageCode()));
	
EndProcedure

Procedure CheckingNeedToConfigureIndicatorsForDistributionOfCostsBetweenHIA(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Company';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Factor", 	NStr("vi = 'Chỉ tiêu';
									|ru = 'Показатель';
									|en = 'Indicator'; fa = 'شاخص';
									|it = 'Indicatore';
									|pl = 'Indicator';
									|tr = 'Gösterge'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTIncorrectMetrics",
		NStr("vi = 'Đã tìm thấy các chỉ số mà chưa xác định giá trị của chúng trong kỳ %2';
			|ru = 'Обнаружены показатели, значения которых не заданы в периоде %2';
			|en = 'Indicators detected whose values were not specified in %2 period'; fa = 'Indicators detected whose values were not specified in %2 period';
			|it = 'Trovati degli indicatori, i cui valori non sono indicati nel periodo %2';
			|pl = 'Wykryto wskaźniki, wartości których nie są określone w okresie %2';
			|tr = '%2 döneminde değerleri ayarlanmayan göstergeler bulundu'", Common.DefaultLanguageCode()),
		FieldList,
		,
		Metadata.InformationRegisters.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects.FullName());
	
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#Region VerificationOfComplianceOfOrganizationDivisionWithHIAData

Procedure VerificationOfComplianceOfOrganizationDivisionWithHIAData(CheckParameters) Export
	
	QueryText = CostCalculationItemizedCosts.TextInTPOOvz() + 
	"SELECT DISTINCT
	|	OtherExpenses.Recorder AS Document,
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.ExpenseItem,
	|	TTOvz.ConstCenter AS ConstCenter,
	|	TTOvz.Organization AS OrganizationOfHIA,
	|	TTOvz.Department AS HIADivision
	|INTO OrganizationDivisionDoesNotComplyWithHIAData
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|		INNER JOIN TTOvz AS TTOvz
	|		ON OtherExpenses.DimensionOfExpenses = TTOvz.ConstCenter
	|WHERE
	|	OtherExpenses.Organization IN (&CompanyArray)
	|	AND OtherExpenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (OtherExpenses.Organization <> TTOvz.Organization
	|	OR OtherExpenses.Department <> TTOvz.Department)
	|	AND OtherExpenses.Active
	|
	|UNION
	|
	|SELECT DISTINCT
	|	DD.Recorder AS Document,
	|	DD.Organization,
	|	FACost.Department,
	|	DD.ExpenseItemAccounting,
	|	TTOvz.ConstCenter AS ConstCenter,
	|	TTOvz.Organization AS OrganizationOfHIA,
	|	TTOvz.Department AS HIADivision
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU.SliceLast(&EndOfPeriod, Organization IN (&CompanyArray)) AS DD
	|		INNER JOIN AccumulationRegister.FACost.Balance(&EndOfPeriod,
	|			Organization IN (&CompanyArray)
	|		) AS FACost
	|		ON FACost.FixedAsset = DD.FixedAsset
	|			AND FACost.Organization = DD.Organization
	|		INNER JOIN TTOvz AS TTOvz
	|		ON DD.ExpensesDimensionAccounting = TTOvz.ConstCenter
	|WHERE
	|	FACost.LocalCostBalance <> 0
	|	AND (DD.Organization <> TTOvz.Organization
	|	OR FACost.Department <> TTOvz.Department)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	DD.Recorder AS Document,
	|	DD.Organization,
	|	FACost.Department,
	|	DD.ExpenseItemTaxAccounting,
	|	TTOvz.ConstCenter AS ConstCenter,
	|	TTOvz.Organization AS OrganizationOfHIA,
	|	TTOvz.Department AS HIADivision
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU.SliceLast(&EndOfPeriod, Organization IN (&CompanyArray)) AS DD
	|		INNER JOIN AccumulationRegister.FACost.Balance(&EndOfPeriod, 
	|			Organization IN (&CompanyArray)
	|		) AS FACost
	|		ON FACost.FixedAsset = DD.FixedAsset
	|			AND FACost.Organization = DD.Organization
	|		INNER JOIN TTOvz AS TTOvz
	|		ON DD.ExpensesDimensionTaxAccounting = TTOvz.ConstCenter
	|WHERE
	|	FACost.CostInTaxAccountingBalance <> 0
	|	AND (DD.Organization <> TTOvz.Organization
	|	OR FACost.Department <> TTOvz.Department)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	DD.Ref AS Document,
	|	DD.Organization,
	|	DD.FixedAssetsLocation,
	|	DD.ExpenseItemManagementAccounting,
	|	TTOvz.ConstCenter AS ConstCenter,
	|	TTOvz.Organization AS OrganizationOfHIA,
	|	TTOvz.Department AS HIADivision
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DD
	|		INNER JOIN TTOvz AS TTOvz
	|		ON DD.ExpensesDimensionManagementAccounting = TTOvz.ConstCenter
	|WHERE
	|	DD.Organization IN (&CompanyArray)
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Posted
	|	AND (DD.Organization <> TTOvz.Organization
	|	OR DD.FixedAssetsLocation <> TTOvz.Department)
	|
	|
	|UNION
	|
	|SELECT DISTINCT
	|	DD.Ref AS Document,
	|	DD.Organization,
	|	DD.FixedAssetsLocation,
	|	DD.ExpenseItemAccounting,
	|	TTOvz.ConstCenter AS ConstCenter,
	|	TTOvz.Organization AS OrganizationOfHIA,
	|	TTOvz.Department AS HIADivision
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DD
	|		INNER JOIN TTOvz AS TTOvz
	|		ON DD.ExpensesDimensionAccounting = TTOvz.ConstCenter
	|WHERE
	|	DD.Organization IN (&CompanyArray)
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Posted
	|	AND (DD.Organization <> TTOvz.Organization
	|	OR DD.FixedAssetsLocation <> TTOvz.Department)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	DD.Ref AS Document,
	|	DD.Organization,
	|	DD.FixedAssetsLocation,
	|	DD.ExpenseItemTaxAccounting,
	|	TTOvz.ConstCenter AS ConstCenter,
	|	TTOvz.Organization AS OrganizationOfHIA,
	|	TTOvz.Department AS HIADivision
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DD
	|		INNER JOIN TTOvz AS TTOvz
	|		ON DD.ExpensesDimensionTaxAccounting = TTOvz.ConstCenter
	|WHERE
	|	DD.Organization IN (&CompanyArray)
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Posted
	|	AND (DD.Organization <> TTOvz.Organization
	|	OR DD.FixedAssetsLocation <> TTOvz.Department)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	DD.Ref AS Document,
	|	DD.Organization,
	|	DD.FixedAssetsLocation,
	|	DD.ExpenseItemOfDepreciationAllowance,
	|	TTOvz.ConstCenter AS ConstCenter,
	|	TTOvz.Organization AS OrganizationOfHIA,
	|	TTOvz.Department AS HIADivision
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DD
	|		INNER JOIN TTOvz AS TTOvz
	|		ON DD.DepreciationAllowanceExpensesDimension = TTOvz.ConstCenter
	|WHERE
	|	DD.Organization IN (&CompanyArray)
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Posted
	|	AND (DD.Organization <> TTOvz.Organization
	|	OR DD.FixedAssetsLocation <> TTOvz.Department)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	DD.Ref AS Document,
	|	DD.Organization,
	|	DD.FixedAssetsLocation,
	|	DD.ExpenseItemForTax,
	|	TTOvz.ConstCenter AS ConstCenter,
	|	TTOvz.Organization AS OrganizationOfHIA,
	|	TTOvz.Department AS HIADivision
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DD
	|		INNER JOIN TTOvz AS TTOvz
	|		ON DD.ExpensesDimensionTax = TTOvz.ConstCenter
	|WHERE
	|	DD.Organization IN (&CompanyArray)
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Posted
	|	AND (DD.Organization <> TTOvz.Organization
	|	OR DD.FixedAssetsLocation <> TTOvz.Department)
	|	";
	
	ObjectFieldName = "Document";
	
	TempTableName = "OrganizationDivisionDoesNotComplyWithHIAData";
	ErrorTextTemplate  = NStr("vi = 'Trong chi phí doanh nghiệp ""%1"" trong kỳ %2 đã tìm thấy sự không khớp giữa doanh nghiệp/bộ phận trong chứng từ gốc và trong tùy chỉnh đối tượng phát sinh chi phí';
								|ru = 'В расходах организации ""%1"" за период %2 обнаружено несоответствие пары организация/подразделение в первичном документе и в настройке объекта возникновения затрат';
								|en = 'In the expenses of the company ""%1"" for the period %2, a mismatch was found between the company/business unit pair in the source document and in cost center settings'; fa = 'In the expenses of the company ""%1"" for the period %2, a mismatch was found between the company/business unit pair in the source document and in cost center settings';
								|it = 'Nelle spese dell''azienda ""%1"" per il periodo %2 non corrispondono abbinamenti azienda/reparto nel documento primario e nelle impostazioni del centro di costo';
								|pl = 'W rozchodach firmy ""%1"" za okres %2 wykryto niezgodność pary firma/dział w podstawowym dokumencie i w ustawieniach obiektu tworzenia się rozchodów';
								|tr = '%2 dönemi için ""%1"" iş yerinin giderleri, kaynak belgedeki ve özelleştirme maliyet nesnesindeki iş yeri/departman çifti arasında bir tutarsızlık buldu'", Common.DefaultLanguageCode());
	
	FieldList = New ValueList;
	FieldList.Add(ObjectFieldName,	NStr("vi = 'Văn bản';
											|ru = 'Документ';
											|en = 'Document'; fa = 'سند';
											|it = 'Documento';
											|pl = 'Document';
											|tr = 'Belge'", Common.DefaultLanguageCode()));
	FieldList.Add("CONSTCENTER",				NStr("vi = 'Đối tượng phát sinh chi phí';
													|ru = 'Объект возникновения затрат';
													|en = 'Cost center'; fa = 'مرکز هزینه';
													|it = 'Centro di costo';
													|pl = 'Obiekt tworzenia się rozchodów';
													|tr = 'Gider oluşum nesnesi'", Common.DefaultLanguageCode()));
	FieldList.Add("Organization",		NStr("vi = 'Doanh nghiệp (báo cáo)';
												|ru = 'Организация (док.)';
												|en = 'Company (doc.)'; fa = 'Company (doc.)';
												|it = 'Azienda (doc.)';
												|pl = 'Firma (dok.)';
												|tr = 'İş yeri (belge.)'", Common.DefaultLanguageCode()));
	FieldList.Add("OrganizationOfHIA",	NStr("vi = 'Doanh nghiệp (SXDD)';
												|ru = 'Организация (ОВЗ)';
												|en = 'Company (cost center)'; fa = 'Company (cost center)';
												|it = 'Azienda (CdC)';
												|pl = 'Firma (obiekt tworzenia się rozchodów)';
												|tr = 'İş yeri (MOM)'", Common.DefaultLanguageCode()));
	FieldList.Add("Department",	NStr("vi = 'Bộ phận (báo cáo)';
										|ru = 'Подразделение (док.)';
										|en = 'Business unit (doc.)'; fa = 'Business unit (doc.)';
										|it = 'Reparto (doc.)';
										|pl = 'Dział (dok.)';
										|tr = 'Departman (belge)'", Common.DefaultLanguageCode()));
	FieldList.Add("HIADivision",NStr("vi = 'Bộ phận (SXDD)';
									|ru = 'Подразделение (ОВЗ)';
									|en = 'Business unit (cost center)'; fa = 'Business unit (cost center)';
									|it = 'Reparto (CdC)';
									|pl = 'Dział (Obiekt tworzenia się rozchodów)';
									|tr = 'Departman (MOM)'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(TempTableName,
																									ErrorTextTemplate,
																									FieldList,
																									ObjectFieldName);
	
	MonthEndTransactionsServer.RegisterValidationIssues(CheckParameters, RegistrationParameters, QueryText);
	
EndProcedure

#EndRegion
#EndRegion

#Region WriteCheckHandlers
Procedure CheckOnRecordingOtherExpenses(Recorder, Cancel) Export
	
	#Region UnitVerificationTextForProductionArticle
	UnitVerificationTextForProductionArticle = "
	|SELECT DISTINCT
	|	1 AS ErrorCode,
	|	DD.Organization AS Parameter2,
	|	DD.Department AS Parameter3,
	|	DD.LineOfBusiness AS Parameter4,
	|	DD.ExpenseItem AS Parameter5,
	|	DD.DimensionOfExpenses AS Parameter6,
	|	UNDEFINED AS Parameter7,
	|	UNDEFINED AS Parameter8,
	|	UNDEFINED AS Parameter9
	|FROM AccumulationRegister.OtherExpenses AS DD
	|INNER JOIN ProductionArticles AS ARTICLES__
	|	ON DD.ExpenseItem = ARTICLES__.ExpenseItem_
	|WHERE DD.Recorder = &Recorder AND DD.Active
	|	AND DD.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|	AND NOT DD.CalculationOfCost
	|	AND NOT DD.LotCalculation
	|";
	#EndRegion
	
	#Region VerificationTextFromPreviousPeriod
	VerificationTextFromPreviousPeriod = "
	|SELECT DISTINCT
	|	2 AS ErrorCode,
	|	DD.Organization,
	|	DD.Department,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	Lots.Document,
	|	UNDEFINED,
	|	UNDEFINED
	|FROM AccumulationRegister.OtherExpenses AS DD
	|INNER JOIN CostOfProductionItems AS ARTICLES__
	|	ON DD.ExpenseItem = ARTICLES__.ExpenseItem_
	|INNER JOIN
	|	Catalog.ProductionLots AS Lots
	|	ON DD.DimensionOfExpenses = Lots.Ref
	|INNER JOIN
	|	Document.BackflushProduction AS Doc
	|	ON Lots.Document = Doc.Ref
	|WHERE
	|	DD.Recorder = &Recorder AND DD.Active
	|	AND BEGINOFPERIOD(DD.Period, MONTH) > BEGINOFPERIOD(Doc.Date, MONTH)
	|	AND NOT DD.CalculationOfCost
	|	AND NOT DD.LotCalculation
	// The costs of the production batch of the previous period cannot be reflected if the period of deviation 
	// does not correspond to the period of the production document or the period of deviation is not filled in.
	|	AND (BEGINOFPERIOD(DD.VariancePeriod, MONTH) <> BEGINOFPERIOD(Doc.Date, MONTH)
	|		OR DD.VariancePeriod = DATETIME(1,1,1))
	|";
	#EndRegion

	#Region VerificationTextOrganizationHIADivision
	VerificationTextOrganizationHIADivision = "
	|SELECT DISTINCT
	|	3 AS ErrorCode,
	|	DD.Organization,
	|	DD.Department,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED
	|FROM AccumulationRegister.OtherExpenses AS DD
	|INNER JOIN ArticlesOnHIA AS ARTICLES__
	|	ON DD.ExpenseItem = ARTICLES__.ExpenseItem_
	|LEFT JOIN
	|	Catalog.CostCenters AS ConstCenter
	|	ON DD.DimensionOfExpenses = ConstCenter.Ref
	|WHERE DD.Recorder = &Recorder AND DD.Active
	|	AND (DD.Organization <> ConstCenter.Organization OR DD.Department <> ConstCenter.Department)
	|	AND NOT DD.CalculationOfCost
	|	AND NOT DD.LotCalculation
	|";
	#EndRegion
	
	TextsOfChecks = New Array();
	TextsOfChecks.Add(UnitVerificationTextForProductionArticle);
	TextsOfChecks.Add(VerificationTextFromPreviousPeriod);
	If GetFunctionalOption("UseAccountingByExpenseObjects") Then
		TextsOfChecks.Add(VerificationTextOrganizationHIADivision);
	EndIf;
	
	ErrorsTexts = New Map();
	ErrorsTexts.Insert(1, NStr("vi = 'Đối với các dạng chi phí sản xuất ""%5"" cần chỉ ra bộ phận.';
								|ru = 'Для производственной статьи расходов ""%5"" требуется указать подразделение.';
								|en = 'Please specify business unit for the production expense item ""%5"".'; fa = 'Please specify business unit for the production expense item ""%5"".';
								|it = 'Per la voce ""%5"" relativa alle spese di produzione è necessario indicare il reparto.';
								|pl = 'Dla pozycji produkcyjnej rozchodów ""%5"" wymagane jest wskazanie działu.';
								|tr = '""%5"" üretim gider kalemi için departman belirtilmesi gerekir.'"));
	ErrorsTexts.Insert(2, NStr("vi = 'Đối với dạng chi phí ""%5"" trong đối tượng phân tích có chỉ ra lô hàng của kỳ trước ""%6"". Cần chỉ ra lô hàng của kỳ hiện tại hoặc kỳ tương lai.';
								|ru = 'Для статьи расходов ""%5"" в аналитике указана партия прошлого периода ""%6"". Требуется указать партию текущего или будущего периода.';
								|en = 'The dimension indicates the previous period lot ""%6"" for expense item ""%5"". Indicate the current or future period lot.'; fa = 'The dimension indicates the previous period lot ""%6"" for expense item ""%5"". Indicate the current or future period lot.';
								|it = 'Per la voce di spese ""%5"" nell''analitica è stato indicato il lotto del periodo precedente ""%6"". È necessario indicare un lotto del periodo corrente o futuro.';
								|pl = 'Dla pozycji rozchodów ""%5"" w analityce jest podana partia poprzedniego okresu ""%6"". Wymagane jest podanie partii bieżącego lub przyszłego okresu.';
								|tr = 'Boyuttaki ""%5"" gider kalemi için, önceki ""%6"" döneminin lotu belirtilir. Mevcut veya gelecekteki dönemin lotunun belirtilmesi gerekir.'"));
	ErrorsTexts.Insert(3, NStr("vi = 'Doanh nghiệp hoặc bộ phận đối tượng phát sinh chi phí ""%6"" không trùng với dữ liệu chứng từ';
								|ru = 'Организация или подразделение объекта возникновения затрат ""%6"" не совпадают с данными документа';
								|en = 'A company or business unit of cost center ""%6"" does not match document data'; fa = 'A company or business unit of cost center ""%6"" does not match document data';
								|it = 'L''azienda o il reparto del centro di costo ""%6"" non coincidono con i dati del documento';
								|pl = 'Firma lub dział obiektu tworzenia się rozchodów ""%6"" nie zbiega się z danymi dokumentu';
								|tr = '""%6"" maliyet nesnesinin iş yeri veya departmanı belge verileriyle eşleşmiyor'"));
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager();
	Query.Text = "SELECT 
	|	ARTICLES__.Ref AS ExpenseItem_
	|INTO ProductionArticles
	|FROM ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|WHERE
	|	ARTICLES__.CostAllocationOptionManag IN (&DistributionOptions)
	|	OR ARTICLES__.CostAllocationOptionLocal IN (&DistributionOptions)
	|INDEX BY
	|	ExpenseItem_;
	|	
	|SELECT 
	|	ARTICLES__.Ref AS ExpenseItem_
	|INTO ArticlesOnHIA
	|FROM ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|WHERE
	|	ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|	OR ARTICLES__.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|INDEX BY
	|	ExpenseItem_;
	|
	|SELECT 
	|	ARTICLES__.Ref AS ExpenseItem_
	|INTO CostOfProductionItems
	|FROM ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|WHERE
	|	ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
	|	OR ARTICLES__.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
	|INDEX BY
	|	ExpenseItem_;
	|";
	
	Query.Text = Query.Text + StrConcat(TextsOfChecks, TMCommonUse.QuerySeparatorInJoin());
	
	Query.SetParameter("Recorder", Recorder);
	Query.SetParameter("DistributionOptions", ProductionServerCached.GetProductionDistributionOptions());
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorsTexts.Get(Selection.ErrorCode),
			Recorder,
			Selection.Parameter2,
			Selection.Parameter3,
			Selection.Parameter4,
			Selection.Parameter5,
			Selection.Parameter6,
			Selection.Parameter7,
			Selection.Parameter8,
			Selection.Parameter9);
		WriteLogEvent(
			NStr("vi = 'Khi ghi vào bản ghi ""Chi phí khác"" đã xảy ra lỗi';
				|ru = 'При записи в регистр ""Прочие расходы"" произошла ошибка';
				|en = 'An error occurred when recording to the ""Other expenses"" register'; fa = 'An error occurred when recording to the ""Other expenses"" register';
				|it = 'Si è verificato un errore durante la scrittura nel registro ""Altre spese""';
				|pl = 'Podczas zapisu do rejestru ""Inne rozchody"" wystąpił błąd';
				|tr = '""Diğer giderler"" siciline kaydedilirken hata oluştu'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,Metadata.AccumulationRegisters.OtherExpenses,,
			ErrorText);
		Common.MessageToUser(ErrorText, Recorder,,, Cancel);
	EndDo;
	
EndProcedure
#EndRegion

#EndRegion

#Region Private


#EndRegion

