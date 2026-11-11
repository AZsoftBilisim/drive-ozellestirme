
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"PriceKind", Parameters);
		
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "EmployeeResponsible", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.StandardCosting2_2") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableMultiplesOfLotsAndSemiFinishedProducts(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

Procedure FillInDocumentSettingProductPrices(DocumentInstallations_1, FillingData) Export
	
	CurrencySet = Constants.CreateSet("LocalAccountingCurrency, ManagementAccountingCurrency");
	CurrencySet.Read();
	
	PlannedPriceView = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory();
	PlanCurrency = Common.ObjectAttributeValue(PlannedPriceView, "PriceCurrency");
	UsePriceManagementSystem25 = GetFunctionalOption("UsePriceManagementSystem25");
	
	If UsePriceManagementSystem25 Then
		
		TabularPartProducts = "Goods2_5";
		QueryText = 
			"SELECT
			|	CostObjects.Products AS Products,
			|	CostObjects.Characteristic.ItemsCharacteristicForPricing AS PricingVariant,
			|	CostObjects.Products.UnitOfMeasure AS Package,
			|	&PlannedPriceView AS PriceKind,
			|	CAST(
			|		SUM(CASE
			|			WHEN &UseManAmount
			|				THEN MultiplesOfLotsAndSemiFinishedProducts.Cost
			|			WHEN &UseManAmountWithoutVAT
			|				THEN MultiplesOfLotsAndSemiFinishedProducts.CostExcludingVAT 
			|			WHEN &UseLocalSum
			|				THEN MultiplesOfLotsAndSemiFinishedProducts.LocalCost
			|			ELSE 0
			|		END) 
			|		/ SUM(MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct)
			|	AS NUMBER(31, 2)) AS Price
			|FROM
			|	Document.StandardCosting2_2.CostObjects AS CostObjects
			|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
			|		ON CostObjects.Ref = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate
			|		AND CostObjects.Products = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
			|		AND CostObjects.Characteristic = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
			|		AND CostObjects.Purpose = MultiplesOfLotsAndSemiFinishedProducts.Purpose
			|		AND MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
			|WHERE
			|	CostObjects.Ref = &Ref
			|
			|GROUP BY
			|	CostObjects.Products,
			|	CostObjects.Characteristic.ItemsCharacteristicForPricing,
			|	CostObjects.Products.UnitOfMeasure
			|
			|UNION ALL
			|
			|SELECT
			|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct AS Products,
			|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct.ItemsCharacteristicForPricing AS
			|		PricingVariant,
			|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct.UnitOfMeasure AS Package,
			|	&PlannedPriceView AS PriceKind,
			|	CAST(
			|		SUM(CASE
			|				WHEN &UseManAmount
			|					THEN MultiplesOfLotsAndSemiFinishedProducts.Cost
			|				WHEN &UseManAmountWithoutVAT
			|					THEN MultiplesOfLotsAndSemiFinishedProducts.CostExcludingVAT
			|				WHEN &UseLocalSum
			|					THEN MultiplesOfLotsAndSemiFinishedProducts.LocalCost
			|				ELSE 0
			|		END)
			|		/ SUM(MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct)
			|	AS NUMBER(31, 2)) AS Price
			|FROM
			|	Document.StandardCosting2_2.CostObjects AS CostObjects
			|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
			|		ON CostObjects.Ref = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate
			|		AND CostObjects.Products = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
			|		AND CostObjects.Characteristic = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
			|		AND CostObjects.Purpose = MultiplesOfLotsAndSemiFinishedProducts.Purpose
			|		AND MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct <> VALUE(Catalog.Products.EmptyRef)
			|WHERE
			|	CostObjects.Ref = &Ref
			|	AND MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct <> VALUE(Catalog.Products.EmptyRef)
			|
			|GROUP BY
			|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct,
			|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct.ItemsCharacteristicForPricing,
			|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct.UnitOfMeasure";
	
	Else
	
		TabularPartProducts = "Goods";
		QueryText = 
			"SELECT
			|	CostObjects.Products AS Products,
			|	CostObjects.Characteristic AS Characteristic,
			|	CostObjects.Products.UnitOfMeasure AS Package,
			|	&PlannedPriceView AS PriceKind,
			|	CAST(
			|		SUM(CASE
			|				WHEN &UseManAmount
			|					THEN MultiplesOfLotsAndSemiFinishedProducts.Cost
			|				WHEN &UseManAmountWithoutVAT
			|					THEN MultiplesOfLotsAndSemiFinishedProducts.CostExcludingVAT
			|				WHEN &UseLocalSum
			|					THEN MultiplesOfLotsAndSemiFinishedProducts.LocalCost
			|				ELSE 0
			|		END)
			|		/ SUM(MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct)
			|	AS NUMBER(31, 2)) AS Price
			|FROM
			|	Document.StandardCosting2_2.CostObjects AS CostObjects
			|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
			|		ON CostObjects.Ref = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate
			|			AND CostObjects.Products = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
			|			AND CostObjects.Characteristic = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
			|			AND CostObjects.Purpose = MultiplesOfLotsAndSemiFinishedProducts.Purpose
			|			AND (MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef))
			|WHERE
			|	CostObjects.Ref = &Ref
			|
			|GROUP BY
			|	CostObjects.Products,
			|	CostObjects.Characteristic,
			|	CostObjects.Products.UnitOfMeasure
			|
			|UNION ALL
			|
			|SELECT
			|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct AS Products,
			|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct AS Characteristic,
			|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct.UnitOfMeasure AS Package,
			|	&PlannedPriceView AS PriceKind,
			|	CAST(
			|		SUM(CASE
			|				WHEN &UseManAmount
			|					THEN MultiplesOfLotsAndSemiFinishedProducts.Cost
			|				WHEN &UseManAmountWithoutVAT
			|					THEN MultiplesOfLotsAndSemiFinishedProducts.CostExcludingVAT
			|				WHEN &UseLocalSum
			|					THEN MultiplesOfLotsAndSemiFinishedProducts.LocalCost
			|				ELSE 0
			|		END)
			|		/ SUM(MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct)
			|	AS NUMBER(31, 2)) AS Price
			|FROM
			|	Document.StandardCosting2_2.CostObjects AS CostObjects
			|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
			|		ON CostObjects.Ref = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate
			|			AND CostObjects.Products = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
			|			AND CostObjects.Characteristic = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
			|			AND CostObjects.Purpose = MultiplesOfLotsAndSemiFinishedProducts.Purpose
			|			AND (MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct <> VALUE(Catalog.Products.EmptyRef))
			|WHERE
			|	CostObjects.Ref = &Ref
			|
			|GROUP BY
			|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct,
			|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
			|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct.UnitOfMeasure";
		
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", FillingData);
	Query.SetParameter("PlannedPriceView", PlannedPriceView);
	Query.SetParameter("UseLocalSum", 
		(PlanCurrency = CurrencySet.LocalAccountingCurrency));
	PriceIncludesVAT = Common.ObjectAttributeValue(PlannedPriceView, "PriceIncludesVAT") = True;
	Query.SetParameter("UseManAmount", PlanCurrency = CurrencySet.ManagementAccountingCurrency 
		And PriceIncludesVAT);
	Query.SetParameter("UseManAmountWithoutVAT", PlanCurrency = CurrencySet.ManagementAccountingCurrency 
		And Not PriceIncludesVAT);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập thiết lập đơn giá mặt hàng trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить установку цен номенклатуры на основании документа %1';
				|en = 'It is not required to enter pricing of products based on document %1'; fa = 'It is not required to enter pricing of products based on document %1';
				|it = 'Non è necessario immettere l''impostazione prezzi di nomenclatura in base al documento %1';
				|pl = 'Nie trzeba wprowadzać ustalenia cen nomenklatury na podstawie dokumentu %1';
				|tr = '%1 belgesi temelinde öğe fiyatı girmeniz gerekli değildir'"),
			FillingData);
		Raise Text;
		
	ElsIf Not ValueIsFilled(PlannedPriceView) Then
		
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Loại giá kế hoạch không được thiết lập.';
				|ru = 'Не установлен плановый вид цены.';
				|en = 'Planned price type not set.'; fa = 'Planned price type not set.';
				|it = 'Il tipo obiettivo del prezzo non è impostato.';
				|pl = 'Nie ustawiony planowany widok ceny.';
				|tr = 'Planlı fiyat türü yapılandırılmadı.'"),
			FillingData);
		Raise Text;
		
	Else
		
		TheseProducts = QueryResult.Unload();
		DocumentInstallations_1.DocumentBasis = FillingData;
		DocumentInstallations_1[TabularPartProducts].Load(QueryResult.Unload());
		
		DocumentInstallations_1.TypesOfPrices.Load(TheseProducts);
		If TheseProducts.Find(PlannedPriceView, "PriceKind") = Undefined Then
			NewKindOfPrice = DocumentInstallations_1.TypesOfPrices.Add();
			NewKindOfPrice.PriceKind = PlannedPriceView;
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure for starting the execution of the background task is necessary to start in the background of carrying out or canceling the planned calculation.
// Parameters:
//   DocumentRef - DocumentRef.StandardCosting2_2 - reference to the planned calculation.
//   ThisIsHolding - Boolean - flag indicating which background task needs to be started.
//
Procedure StartingBackgroundJob(DocumentRef, ThisIsHolding) Export

	SetPrivilegedMode(True);
	
	UID = DocumentRef.UUID();
	KeyConducting = StrTemplate("%1 ThisIsHolding = %2", UID, True);
	CancellationKey = StrTemplate("%1 ThisIsHolding = %2", UID, False);
	
	FilterPosting = New Structure();
	FilterPosting.Insert("Key", KeyConducting);
	FilterPosting.Insert("State", BackgroundJobState.Active);
	ActiveTasksOfEvent = BackgroundJobs.GetBackgroundJobs(FilterPosting);
	
	FilterUndoPosting = New Structure();
	FilterUndoPosting.Insert("Key", CancellationKey);
	FilterUndoPosting.Insert("State", BackgroundJobState.Active);
	ActiveCancellationTasks = BackgroundJobs.GetBackgroundJobs(FilterUndoPosting);
	
	If ThisIsHolding Then
		If ActiveTasksOfEvent.Count() > 0 Then
			ArrayOfTasks = BackgroundJobs.WaitForExecutionCompletion(ActiveTasksOfEvent, 5);
			If HasActiveBackgroundJobs(ArrayOfTasks) Then
				Raise NStr("vi = 'Đang thực hiện nhiệm vụ nền kết chuyển chứng từ, để hủy nhiệm vụ nền kết chuyển chứng từ, cần hủy kết chuyển chứng từ.';
							|ru = 'Выполняется фоновое задание проведения документа, для отмены фонового задания проведения документа, необходимо распровести документ.';
							|en = 'The document posting background job is in progress. To cancel the background job, unpost the document.'; fa = 'The document posting background job is in progress. To cancel the background job, unpost the document.';
							|it = 'The document posting background job is in progress. To cancel the background job, unpost the document.';
							|pl = 'The document posting background job is in progress. To cancel the background job, unpost the document.';
							|tr = 'Arka planda belge işleme görevi yürütülmektedir. Arka planda belge işleme görevini iptal etmek için belgeyi yaymanız gerekmektedir.'");
			EndIf;
		EndIf;
		
		If ActiveCancellationTasks.Count() > 0 Then
			ArrayOfTasks = BackgroundJobs.WaitForExecutionCompletion(ActiveCancellationTasks, 5);
			If HasActiveBackgroundJobs(ArrayOfTasks) Then
				Raise NStr("vi = 'Đang thực hiện nhiệm vụ nền hủy kết chuyển, trước khi kết chuyển, cần chờ hủy kết chuyển. ';
							|ru = 'Выполняется фоновое задание отмены проведения, перед проведением необходимо дождаться отмены проведения.';
							|en = 'The posting cancellation background job is in progress. Before posting, wait for the posting to be canceled.'; fa = 'The posting cancellation background job is in progress. Before posting, wait for the posting to be canceled.';
							|it = 'The posting cancellation background job is in progress. Before posting, wait for the posting to be canceled.';
							|pl = 'The posting cancellation background job is in progress. Before posting, wait for the posting to be canceled.';
							|tr = 'Arka planda iptal işlemi gerçekleştiriliyor, devam etmeden önce olayın iptal edilmesini beklemeniz gerekmektedir.'");
			EndIf;
		EndIf;
		
	ElsIf ActiveTasksOfEvent.Count() > 0 Or ActiveCancellationTasks.Count() > 0 Then
		// In cases where the event is canceled and the task of conducting or canceling the event is active at that moment
		// , the background task does not need to be restarted, it is enough to register the task of canceling the event,
		// which is written to the information register of the queue for the calculation of scheduled statements, before starting this procedure.
		Return;
	EndIf;
	
	JobDescription = NStr("vi = 'Kết chuyển chứng từ: %Ref%';
							|ru = 'Проведение документа: %Ref%';
							|en = 'Posting the document: %Ref%'; fa = 'Posting the document: %Ref%';
							|it = 'Registrazione documento: %Ref%';
							|pl = 'Zatwierdzenie dokumentu: %Ref%';
							|tr = 'Belgenin kaydedilmesi: %Ref%'");
	JobDescription = StrReplace(JobDescription, "%Ref%", DocumentRef);
	
	ExportProcedureName = "InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.PerformSurvey";
	
	ExportProcedureParameters = New Array();
	ExportProcedureParameters.Add(New Structure("StandardCostEstimate, ThisIsHolding", DocumentRef, ThisIsHolding));
	
	JobParameters = New Array();
	JobParameters.Add(ExportProcedureName);
	JobParameters.Add(ExportProcedureParameters);
	
	Var_Key = ?(ThisIsHolding, KeyConducting, CancellationKey);
	BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, Var_Key, JobDescription);

EndProcedure

#Region AuditOfSystemState

// Adds a check to register errors.
// 
// Parameters:
// 	TableOfInspectionGroups - See AuditOfSystemState.TableOfSystemStateCheckGroups
//
Procedure FillInVerificationGroupsForRegistration(TableOfInspectionGroups) Export
	
	DescriptionOfInspectionGroup = TableOfInspectionGroups.Add();
	DescriptionOfInspectionGroup.ParentID = "";
	DescriptionOfInspectionGroup.Description = NStr("vi = 'Tính giá thành sản phẩm';
													|ru = 'Калькуляции продукции';
													|en = 'Product costings'; fa = 'Product costings';
													|it = 'Calcolo prodotti';
													|pl = 'Kalkulacje produkcji';
													|tr = 'İmal edilen ürün maliyetlendirmeleri'");
	DescriptionOfInspectionGroup.AccountingChecksContext = Documents.StandardCosting2_2.EmptyRef();
	DescriptionOfInspectionGroup.Id = "ProductCostings";
	
EndProcedure

// Fills in checks that are performed after the planned calculation is calculated.
// 
// Parameters:
// 	TableOfChecks - See AuditOfSystemState.SystemStateCheckTable
//
Procedure FillOutChecksForRegistration(TableOfChecks) Export
	
	// The presence of zero-cost movements.
	VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
		"ZeroCostRegisteredRecords",
		Documents.StandardCosting2_2.EmptyRef(),
		Enums.TimeOfStartingMonthEndClosingOperationCheck.AfterCalculation,
		"Documents.StandardCosting2_2.CheckingForZeroCostMoves");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Sự hiện diện của các Lưu chuyển với chi phí bằng không.';
			|ru = 'Наличие движений с нулевой стоимостью.';
			|en = 'There are movements with zero cost.'; fa = 'There are movements with zero cost.';
			|it = 'La presenza di movimenti a costo zero.';
			|pl = 'Obecność ruchów z wartością zerową.';
			|tr = 'Sıfır maliyetli hareketlerin mevcudiyeti.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Giá kế hoạch phải được chỉ định cho toàn bộ danh pháp và loại công việc.';
			|ru = 'Для всей номенклатуры и видов работ должны быть назначены плановые цены.';
			|en = 'Planned prices should be assigned for all products and activity kinds.'; fa = 'Planned prices should be assigned for all products and activity kinds.';
			|it = 'Per intera nomenclatura e tipi di lavoro devono essere assegnati i prezzi obiettivo.';
			|pl = 'Cały zakres produktów i rodzaje pracy powinny być przypisane do planowanych cen.';
			|tr = 'Tüm öğeler ve iş türleri için planlanan fiyatlar atanmalıdır.'", Common.DefaultLanguageCode()));
	
EndProcedure

// Checks whether the planned calculation is correct.
// 
// Parameters:
// 	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
//
Procedure CheckingForZeroCostMoves(CheckParameters) Export
	
	AdditionalParameters = CheckParameters.AdditionalParameters; // Structure
	Calculations_ = AdditionalParameters.Calculations_;
	
	TempTablesManager = New TempTablesManager;
	
	InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.GetProductPrices(Calculations_, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ArrayOfPlannedCalculations", Calculations_);
	
	ArrayOfRequestTexts = New Array();
	Query.SetParameter("UseLaborGradesOfEmployeeActivityRates",
		GetFunctionalOption("UseLaborGradesOfEmployeeActivityRates"));
	ArrayOfRequestTexts.Add(AccumulationRegisters.PlannedLaborCosts.QueryTextOfLaborCostsPricing(False));
	
	QueryText = "SELECT
		|	PlannedMaterialCosts.StandardCostEstimate AS StandardCostEstimate,
		|	""Material_"" AS TypeOfCosts,
		|	SUM(1) AS RowsCount
		|INTO Errors
		|FROM
		|	AccumulationRegister.PlannedMaterialCosts AS PlannedMaterialCosts
		|		LEFT JOIN ItemsPrices AS ItemsPrices
		|		ON PlannedMaterialCosts.StandardCostEstimate = ItemsPrices.StandardCostEstimate
		|			AND PlannedMaterialCosts.Products = ItemsPrices.Products
		|			AND PlannedMaterialCosts.Characteristic = ItemsPrices.Characteristic
		|			AND PlannedMaterialCosts.Period = ItemsPrices.Period
		|WHERE
		|	NOT PlannedMaterialCosts.ThisIsASemiFinishedProduct
		|	AND PlannedMaterialCosts.StandardCostEstimate IN (&ArrayOfPlannedCalculations)
		|	AND ISNULL(ItemsPrices.Price, 0) = 0
		|
		|GROUP BY
		|	PlannedMaterialCosts.StandardCostEstimate
		|
		|UNION ALL
		|
		|SELECT
		|	PlannedLaborCosts.StandardCostEstimate,
		|	""LaborCosts"",
		|	SUM(1)
		|FROM
		|	AccumulationRegister.PlannedLaborCosts AS PlannedLaborCosts
		|	LEFT JOIN Rates AS Rates
		|	ON PlannedLaborCosts.StandardCostEstimate = Rates.StandardCostEstimate
		|		AND PlannedLaborCosts.WorkKind = Rates.WorkKind
		|		AND PlannedLaborCosts.Period = Rates.Period
		|		AND PlannedLaborCosts.Department = Rates.Department
		|WHERE
		|	PlannedLaborCosts.StandardCostEstimate IN (&ArrayOfPlannedCalculations)
		|	AND ISNULL(Rates.Rate_, 0) = 0
		|
		|GROUP BY
		|	PlannedLaborCosts.StandardCostEstimate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ActivityKinds
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP Rates
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Errors.StandardCostEstimate AS StandardCostEstimate,
		|	Errors.TypeOfCosts AS TypeOfCosts,
		|	Errors.RowsCount AS RowsCount,
		|	Errors.StandardCostEstimate.Organization AS Organization
		|FROM
		|	Errors AS Errors
		|TOTALS BY
		|	Organization";
	
	ArrayOfRequestTexts.Add(QueryText);
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	Result = Query.Execute();
	SelectionByOrganization_ = Result.Select(QueryResultIteration.ByGroups);
	
	CalculationsWithCalculationErrors = New Array;;
	
	While SelectionByOrganization_.Next() Do
		
		AuditOfSystemState.AddRowToProblemTable(
			CheckParameters, 
			SelectionByOrganization_.Organization, 
			'00010101', 
			NStr("vi = 'Có các Lưu chuyển trên các nguyên vật liệu hoặc dạng công việc với chi phí bằng không.';
				|ru = 'Присутствуют движения по материалам или видам работы с нулевой стоимостью.';
				|en = 'There are movements of materials and activity kinds with zero value.'; fa = 'There are movements of materials and activity kinds with zero value.';
				|it = 'Ci sono movimenti per materiali o tipi di lavoro a costo zero.';
				|pl = 'Są obecne ruchy na materiałach lub rodzajach pracy przy zerowym koszcie.';
				|tr = 'Sıfır maliyetli malzeme veya iş türlerine yönelik hareketler bulunmaktadır.'"));
		
		DetailedSampling = SelectionByOrganization_.Select();
		While DetailedSampling.Next() Do
			
			If DetailedSampling.TypeOfCosts = "Material_" Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không có giá kế hoạch đã được đặt cho %1 mục mặt hàng.';
						|ru = 'Не заданы плановые цены для %1 позиций номенклатуры.';
						|en = 'Scheduled prices for the %1 items of products are not specified.'; fa = 'Scheduled prices for the %1 items of products are not specified.';
						|it = 'Nessun prezzo obiettivo specificato per %1 voci di nomenclatura.';
						|pl = 'Brak planowanych cen dla %1 pozycji produktów.';
						|tr = '%1 öğe pozisyonu için planlanan fiyatlar belirtilmedi.'"),
					DetailedSampling.RowsCount);
			Else
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Tỷ lệ kế hoạch cho %1 loại công việc không được đặt.';
						|ru = 'Не заданы плановые расценки для %1 видов работ.';
						|en = 'Planned rates for the %1 activity kinds are not specified.'; fa = 'Planned rates for the %1 activity kinds are not specified.';
						|it = 'Nessuna tariffa obiettivo specificata per %1 tipi di lavoro.';
						|pl = 'Brak planowanych cen dla %1 rodzajów prac.';
						|tr = '%1 etkinlik türü için planlanan oranlar belirtilmedi.'"),
					DetailedSampling.RowsCount);
				EndIf;
				
			AuditOfSystemState.AddObjectToFixedProblem(
				CheckParameters,
				DetailedSampling.StandardCostEstimate,
				Presentation);
				
			If CalculationsWithCalculationErrors.Find(DetailedSampling.StandardCostEstimate) = Undefined Then
				CalculationsWithCalculationErrors.Add(DetailedSampling.StandardCostEstimate);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	AdditionalParameters.Insert("CalculationsWithCalculationErrors", CalculationsWithCalculationErrors);
	
EndProcedure

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.PriceSetup.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Populates the list of creation commands based on.
//
// Parameters:
//  CreateCommandsBasedOn - ValueTable - The description in the creation of the base is undefined.Before adding a command to create a base
// Returns:
// 	ValueTableRow - The description in the creation of the base is undefined.Before adding a command to create a base.Teamsreferences 
Function AddGenerateCommand(CreateCommandsBasedOn) Export

	If AccessRight("Insert", Metadata.Documents.StandardCosting2_2) Then
		
		OnlyProduction22 = GetFunctionalOption("EnabledOnlyProductionManagement22");
		CreateBasedOnCommand = CreateCommandsBasedOn.Add();
		CreateBasedOnCommand.Id = Metadata.Documents.StandardCosting2_2.FullName();
		CreateBasedOnCommand.Manager = Metadata.Documents.StandardCosting2_2.FullName();
		CreateBasedOnCommand.MultipleChoice = True;
		CreateBasedOnCommand.FunctionalOptions = "UseProductionManagement2_2";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.StandardCosting2_2)
			+ ?(OnlyProduction22, "", " 2.2");

		Return CreateBasedOnCommand;
		
	EndIf;

	Return Undefined;
	
EndFunction

// Fills in the list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export

	If AccessRight("View", Metadata.Reports.ProductCostEstimate) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager			= Metadata.Reports.ProductCostEstimate.FullName();
		ReportCommand.Presentation		= NStr("vi = 'Chi phí sản xuất theo kế hoạch';
												|ru = 'Плановая себестоимость продукции';
												|en = 'Standard product cost'; fa = 'بهای استاندارد محصول';
												|it = 'Costo di produzione stimata';
												|pl = 'Planowane koszty własne produkcji';
												|tr = 'İmal edilen ürünlerin standart maliyeti'");
		ReportCommand.VisibilityInForms	= "DocumentForm, ListForm";
		ReportCommand.VariantKey 		= "PlannedCostOfProductionContext";
		ReportCommand.Order            = 1;
		ReportCommand.Importance 			= "Important";
		ReportCommand.MultipleChoice = False;
		
	EndIf;
	
	If AccessRight("View", Metadata.Reports.ErrorsOfProductsCostingCalculation) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager               = Metadata.Reports.ErrorsOfProductsCostingCalculation.FullName();
		ReportCommand.Presentation               = NStr("vi = 'Biên bản tính';
														|ru = 'Протокол расчета';
														|en = 'Calculation protocol'; fa = 'Calculation protocol';
														|it = 'Protocollo di calcolo';
														|pl = 'Protokół obliczeniowy';
														|tr = 'Hesaplama protokolü'");
		ReportCommand.VisibilityInForms            = "DocumentForm, ListForm";
		ReportCommand.Order                     = 1;
		ReportCommand.Importance = "Important";
		
	EndIf;
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PlannedCalculationIsSummarized";
	PrintCommand.Presentation = NStr("vi = 'Tóm tắt tính giá thành';
									|ru = 'Сводная калькуляция';
									|en = 'Summary cost estimate'; fa = 'Summary cost estimate';
									|it = 'Riepilogo del calcolo';
									|pl = 'Podsumowanie kalkulacji';
									|tr = 'Özet maliyetlendirme'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PlanningCalculationInDetail";
	PrintCommand.Presentation = NStr("vi = 'Chi tiết tính giá thành';
									|ru = 'Подробная калькуляция';
									|en = 'Detailed cost estimate'; fa = 'Detailed cost estimate';
									|it = 'Calcolo dettagliato';
									|pl = 'Szczegóły kalkulacji';
									|tr = 'Detaylı maliyetlendirme'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ErrorLog";
	PrintCommand.Order = 60;
	PrintCommand.Presentation = NStr("vi = 'Biên bản lỗi';
									|ru = 'Протокол ошибок';
									|en = 'Error log'; fa = 'گزارش خطا';
									|it = 'Registro errori';
									|pl = 'Protokół błędów';
									|tr = 'Hata protokolü'");
	PrintCommand.CheckPostingBeforePrint = True;
	
EndProcedure

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", True, "Object.CostObjects.Purpose");
	
	Return FormTemplate;
	
EndFunction

#EndRegion

// Returns parameters for selecting specifications for the items specified in the document.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of the choice specs.
//
// Returns:
//   Structure - A structure that overrides the defaults set in the management function of the Client Server's data items.Parameterselectionspecifications().
//
Function BOMSelectionParameters(Object) Export
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	BOMSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Assembly);
	BOMSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Repair);
	BOMSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.PerformRM);
	
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	ChoiceParameterLinks.Products            = "Object.CostObjects.Products";
	ChoiceParameterLinks.Characteristic          = "Object.CostObjects.Characteristic";
	ChoiceParameterLinks.ProductionStart      = "Object.Date";
	ChoiceParameterLinks.ProductionDispatcherBusinessUnit  = "Object.ProductionDispatcherBusinessUnit";
	
	BOMSelectionParameters.ChoiceParameterLinks.Insert("Object.CostObjects.Object", ChoiceParameterLinks);
	
	Return BOMSelectionParameters;
	
EndFunction

// The names of the details, the values of which depend on the selection parameters spec
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	AttributesNames = "";
	Return AttributesNames;
	
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

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region ObjectsVersioning

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndRegion

#Region FillingInDocuments

Function DescriptionOfPriceFillingParameterInCollection() Export
	
	LongDesc = New Structure;
	LongDesc.Insert("DocumentDate", Date(1, 1, 1));
	LongDesc.Insert("DocumentCurrency", Catalogs.Currencies.EmptyRef());
	LongDesc.Insert("StandardCostEstimate", Documents.StandardCosting2_2.EmptyRef());
	
	Return LongDesc;
	
EndFunction

Procedure FillInPricesByCalculationInCollection(Collection, RowsSet, FillParameters) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	Rows.Products AS Products,
		|	Rows.Characteristic AS Characteristic,
		|	Rows.Purpose AS Purpose,
		|	Rows.Count AS Count,
		|	&StandardCostEstimate AS StandardCostEstimate
		|INTO ProductTable
		|FROM
		|	&Collection AS Rows
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	StandardCostEstimate
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductTable.Products AS Products,
		|	ProductTable.Characteristic AS Characteristic,
		|	ProductTable.Purpose AS Purpose,
		|	ProductTable.StandardCostEstimate AS StandardCostEstimate,
		|	Multipliers.Cost AS Cost,
		|	Multipliers.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
		|	1 AS Priority
		|INTO ProductPrices_
		|FROM
		|	ProductTable AS ProductTable
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS Multipliers
		|		ON ProductTable.StandardCostEstimate = Multipliers.StandardCostEstimate
		|		AND ProductTable.Products = Multipliers.ManufacturedProduct
		|		AND ProductTable.Characteristic = Multipliers.ItemVariant
		|		AND ProductTable.Purpose = Multipliers.Purpose
		|		AND Multipliers.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	ProductTable.Products,
		|	ProductTable.Characteristic,
		|	ProductTable.Purpose,
		|	ProductTable.StandardCostEstimate,
		|	Multipliers.Cost,
		|	Multipliers.QuantityOfSemiFinishedProduct,
		|	2 AS Priority
		|FROM
		|	ProductTable AS ProductTable
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS Multipliers
		|		ON ProductTable.StandardCostEstimate = Multipliers.StandardCostEstimate
		|		AND ProductTable.Products = Multipliers.ManufacturedProduct
		|		AND ProductTable.Characteristic = Multipliers.ItemVariant
		|		AND Multipliers.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|		AND Multipliers.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	ProductTable.Products,
		|	ProductTable.Characteristic,
		|	ProductTable.Purpose,
		|	ProductTable.StandardCostEstimate,
		|	Multipliers.Cost,
		|	Multipliers.QuantityOfSemiFinishedProduct,
		|	3 AS Priority
		|FROM
		|	ProductTable AS ProductTable
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS Multipliers
		|		ON ProductTable.StandardCostEstimate = Multipliers.StandardCostEstimate
		|		AND ProductTable.Products = Multipliers.ManufacturedProduct
		|		AND ProductTable.Characteristic = Multipliers.ItemVariant
		|		AND Multipliers.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	Multipliers.SemiFinishedProduct AS Products,
		|	Multipliers.ItemVariantsOfIntermediateProduct AS Characteristic,
		|	ProductTable.Purpose AS Purpose,
		|	ProductTable.StandardCostEstimate AS StandardCostEstimate,
		|	Multipliers.Cost,
		|	Multipliers.QuantityOfSemiFinishedProduct,
		|	4 AS Priority
		|FROM
		|	ProductTable AS ProductTable
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS Multipliers
		|		ON ProductTable.StandardCostEstimate = Multipliers.StandardCostEstimate
		|		AND ProductTable.Products = Multipliers.SemiFinishedProduct
		|		AND ProductTable.Characteristic = Multipliers.ItemVariantsOfIntermediateProduct
		|		AND ProductTable.Purpose = Multipliers.Purpose
		|
		|UNION ALL
		|
		|SELECT
		|	Multipliers.SemiFinishedProduct AS Products,
		|	Multipliers.ItemVariantsOfIntermediateProduct AS Characteristic,
		|	ProductTable.Purpose,
		|	ProductTable.StandardCostEstimate,
		|	Multipliers.Cost,
		|	Multipliers.QuantityOfSemiFinishedProduct,
		|	5 AS Priority
		|FROM
		|	ProductTable AS ProductTable
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS Multipliers
		|		ON ProductTable.StandardCostEstimate = Multipliers.StandardCostEstimate
		|		AND ProductTable.Products = Multipliers.SemiFinishedProduct
		|		AND ProductTable.Characteristic = Multipliers.ItemVariantsOfIntermediateProduct
		|		AND Multipliers.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	Multipliers.SemiFinishedProduct AS Products,
		|	Multipliers.ItemVariantsOfIntermediateProduct AS Characteristic,
		|	ProductTable.Purpose,
		|	ProductTable.StandardCostEstimate,
		|	Multipliers.Cost,
		|	Multipliers.QuantityOfSemiFinishedProduct,
		|	6 AS Priority
		|FROM
		|	ProductTable AS ProductTable
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS Multipliers
		|		ON ProductTable.StandardCostEstimate = Multipliers.StandardCostEstimate
		|		AND ProductTable.Products = Multipliers.SemiFinishedProduct
		|		AND ProductTable.Characteristic = Multipliers.ItemVariantsOfIntermediateProduct
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	ProductPrices_.Products,
		|	ProductPrices_.Characteristic,
		|	ProductPrices_.Purpose,
		|	ProductPrices_.StandardCostEstimate,
		|	SUM(ProductPrices_.Cost) / SUM(ProductPrices_.QuantityOfSemiFinishedProduct) AS Price,
		|	ProductPrices_.Priority AS Priority
		|FROM
		|	ProductPrices_ AS ProductPrices_
		|
		|GROUP BY
		|	ProductPrices_.Products,
		|	ProductPrices_.Characteristic,
		|	ProductPrices_.Purpose,
		|	ProductPrices_.StandardCostEstimate,
		|	ProductPrices_.Priority
		|
		|ORDER BY
		|	Priority";
	
	Query.SetParameter("Collection", Collection.Unload(RowsSet));
	Query.SetParameter("StandardCostEstimate", FillParameters.StandardCostEstimate);
	
	Result = Query.Execute();
	Selection = Result.Select();

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	RecountIsRequired = Not (FillParameters.DocumentCurrency = CurrencyOfMan);
	If RecountIsRequired Then
		
		CalculationCourseParameters = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyOfMan, 
			FillParameters.DocumentDate);
		DocumentCourseParameters = ProcessingOfExchangeRatesTM.GetCurrencyRate(FillParameters.DocumentCurrency, 
			FillParameters.DocumentDate); 
		
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowData In RowsSet Do
		
		RowFilter = New Structure;
		RowFilter.Insert("Products", RowData.Products);
		RowFilter.Insert("Characteristic", RowData.Characteristic);
		If ValueIsFilled(RowData.Purpose) Then
			// We are looking for a price with an appointment only if it is filled in in the price receiver document.
			RowFilter.Insert("Purpose", RowData.Purpose);
		EndIf;

		Selection.Reset();
		If Not Selection.FindNext(RowFilter) Then
			If RowFilter.Property("Purpose") Then
				// The destination is indicated in the receiver document, but there is no price with such an appointment,
				// we are trying to find the price without selection for the intended purpose.
				RowFilter.Delete("Purpose");
				Selection.Reset();
				If Not Selection.FindNext(RowFilter) Then
					Continue;
				EndIf;
			Else
				Continue;
			EndIf;
		EndIf;
		
		If RecountIsRequired Then
			RowData.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(Selection.Price, 
				CalculationCourseParameters, DocumentCourseParameters);
		Else
			RowData.Price = Selection.Price;
		EndIf;
			
		RowsToProcess.Add(RowData);

	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Collection,
		CachedValues);
	
EndProcedure

#EndRegion

#Region Initialize

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;
	
	Return DataSources; 
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	DetailsOfDocuments = Common.ObjectAttributesValues(DocumentRef, "Date,Organization");
	
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("Period", EndOfDay(DetailsOfDocuments.Date));
	Query.SetParameter("PriceKind", Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory());
	Query.SetParameter("PeriodNotCalculatedForOrganization",
		InformationRegisters.JobsForCalculatingCost.GetUnCalculatedPeriodForOrganization(DetailsOfDocuments.Organization));
	
EndProcedure

Function RequestTextsForGeneratingRegisteredRecords(Query, QueryTexts)
	
	SetOutputProductsAccordingToSpecification(Query);
	QueryTextTTCostObjects(Query, QueryTexts);
	
	Return QueryTexts;
	
EndFunction

Procedure QueryTextTableMultiplesOfLotsAndSemiFinishedProducts(Query, QueryTexts, Registers)
	
	RegisterName = "MultiplesOfLotsAndSemiFinishedProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCalculationObjects", QueryTexts) Then
		RequestTextsForGeneratingRegisteredRecords(Query, QueryTexts);
	EndIf;
	
	Query.SetParameter("EmptyUID", CommonClientServer.BlankUUID());
	QueryText = "
		|SELECT
		|	VZ.Period AS Period,
		|	VZ.StandardCostEstimate AS StandardCostEstimate,
		|	VZ.ManufacturedProduct AS ManufacturedProduct,
		|	VZ.ItemVariant AS ItemVariant,
		|	VZ.Purpose AS Purpose,
		|	VZ.LotProductBOM AS LotProductBOM,
		|	VZ.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	VZ.KeyLot AS KeyLot,
		|	VZ.SemiFinishedProduct AS SemiFinishedProduct,
		|	VZ.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	VZ.Order AS Order,
		|	SUM(VZ.Numerator) AS Numerator,
		|	VZ.Denominator AS Denominator,
		|	SUM(VZ.QuantityOfSemiFinishedProduct) AS QuantityOfSemiFinishedProduct,
		|	VZ.CalculationIsCompleted AS CalculationIsCompleted,
		|	VZ.ProductionOrder AS ProductionOrder,
		|	VZ.LotIsReleased AS LotIsReleased
		|FROM
		|(
		|	SELECT
		|		BEGINOFPERIOD(OutputProductsOnRequest.ProductionDate, DAY) AS Period,
		|		&Ref AS StandardCostEstimate,
		|		TTCalculationObjects.Products AS ManufacturedProduct,
		|		TTCalculationObjects.Characteristic AS ItemVariant,
		|		TTCalculationObjects.Purpose AS Purpose,
		|		CASE WHEN OutputProductsOnRequest.ProductionByThirdParty AND NOT OutputProductsOnRequest.LotIsReleased
		|			THEN
		|				OutputProductsOnRequest.BillOfMaterials
		|			ELSE
		|				OutputProductsOnRequest.ReleasingStage
		|		END AS LotProductBOM,
		|		UNDEFINED AS LotSemiFinishedProductBOM,
		|		UUID(TTCalculationObjects.Characteristic) AS KeyLot,
		|		VALUE(Catalog.Products.EmptyRef) AS SemiFinishedProduct,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantsOfIntermediateProduct,
		|		CASE
		|			WHEN OutputProductsOnRequest.LotIsReleased
		|				THEN -100
		|			WHEN OutputProductsOnRequest.ToExpenseAs
		|				THEN -1
		|			ELSE 0
		|		END AS Order,
		|		OutputProductsOnRequest.CostShare AS Numerator,
		|		CASE
		//	Comment 1045.
		//	In one document, the stage of production2_2 Manufactured products can be partially released:
		//		1. Part of the lines with a jackdaw is produced, part without a jackdaw.
		//		2. Different release dates:
		//			2.1 Some release dates are in the closed period, some are not.
		//			2.2 Some release dates before the PC date, some after.
		|			WHEN OutputProductsOnRequest.LotIsReleased
		//	For the correct calculation of expenses for the issued Lot references, the denominator should be calculated only for the lines
		//		for which the batch is released = TRUE.
		|				THEN TotalCostShares.ShareByIssuedLotREFERENCES
		//	For correct calculation of unreleased Lot references, the denominator should be in general throughout the document.
		|			ELSE TotalCostShares.TotalShares
		|		END AS Denominator,
		|		OutputProductsOnRequest.Count AS QuantityOfSemiFinishedProduct,
		|		FALSE AS CalculationIsCompleted,
		|		TTCalculationObjects.Object AS ProductionOrder,
		|		OutputProductsOnRequest.LotIsReleased AS LotIsReleased
		|	FROM
		|		TTCalculationObjects AS TTCalculationObjects
		|			INNER JOIN OutputProductsOnRequest AS OutputProductsOnRequest
		|			ON TTCalculationObjects.Object = OutputProductsOnRequest.Object
		|				AND TTCalculationObjects.Products = OutputProductsOnRequest.Products
		|				AND TTCalculationObjects.Characteristic = OutputProductsOnRequest.Characteristic
		|				AND TTCalculationObjects.Purpose = OutputProductsOnRequest.Purpose
		|			INNER JOIN TotalCostShares AS TotalCostShares
		|			ON (OutputProductsOnRequest.ReleasingStage = TotalCostShares.Object)
		|	WHERE
		|		NOT (OutputProductsOnRequest.LotIsReleased AND OutputProductsOnRequest.ToExpenseAs)
		|
		|	UNION ALL
		|
		|	SELECT
		|		&Period AS Period,
		|		&Ref AS StandardCostEstimate,
		|		TTCalculationObjects.Products AS ManufacturedProduct,
		|		TTCalculationObjects.Characteristic AS ItemVariant,
		|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|		OutputProductsAccordingToSpecification.BillOfMaterials AS LotProductBOM,
		|		UNDEFINED AS LotSemiFinishedProductBOM,
		|		UUID(TTCalculationObjects.Characteristic) AS KeyLot,
		|		VALUE(Catalog.Products.EmptyRef) AS SemiFinishedProduct,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantsOfIntermediateProduct,
		|		0 AS Order,
		|		OutputProductsAccordingToSpecification.Numerator AS Numerator,
		|		OutputProductsAccordingToSpecification.Denominator AS Denominator,
		|		OutputProductsAccordingToSpecification.Count AS QuantityOfSemiFinishedProduct,
		|		FALSE AS CalculationIsCompleted,
		|		UNDEFINED AS ProductionOrder,
		|		FALSE AS LotIsReleased
		|	FROM
		|		TTCalculationObjects AS TTCalculationObjects
		|			INNER JOIN OutputProductsAccordingToSpecification AS OutputProductsAccordingToSpecification
		|			ON TTCalculationObjects.Object = OutputProductsAccordingToSpecification.BillOfMaterials
		|				AND TTCalculationObjects.Products = OutputProductsAccordingToSpecification.Products
		|				AND (TTCalculationObjects.Characteristic = OutputProductsAccordingToSpecification.Characteristic 
		|					OR OutputProductsAccordingToSpecification.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|
		|			INNER JOIN TotalCostShares AS TotalCostShares
		|			ON (OutputProductsAccordingToSpecification.BillOfMaterials = TotalCostShares.Object)
		|
		|			INNER JOIN Catalog.BillsOfMaterials AS BillsOfMaterials
		|			ON TTCalculationObjects.Object = BillsOfMaterials.Ref
		|				AND BillsOfMaterials.ProductionProcessType IN (
		|					VALUE(Enum.ProductionProcessTypes.Assembly), 
		|					VALUE(Enum.ProductionProcessTypes.Repair),
		|					VALUE(Enum.ProductionProcessTypes.PerformRM)
		|					)
		|
		|	UNION ALL
		|
		|	SELECT
		|		&Period AS Period,
		|		&Ref AS StandardCostEstimate,
		|		TTCalculationObjects.Products AS ManufacturedProduct,
		|		TTCalculationObjects.Characteristic AS ItemVariant,
		|		TTCalculationObjects.Purpose AS Purpose,
		|		CASE WHEN DD.ReleasingStage REFS Document.ProductionStage2_2
		|			THEN DD.ReleasingStage
		|			ELSE DD.BillOfMaterials
		|		END AS LotProductBOM,
		|		UNDEFINED AS LotSemiFinishedProductBOM,
		|		DD.KeyLot AS KeyLot,
		|		VALUE(Catalog.Products.EmptyRef) AS SemiFinishedProduct,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantsOfIntermediateProduct,
		// A sign of dean. Structure Order = -1024 cm. Processproduction by order.Processproduction by order
		|		-1024 AS Order,
		|		DD.CostShare AS Numerator,
		|		1 AS Denominator,
		|		DD.Count AS QuantityOfSemiFinishedProduct,
		|		FALSE AS CalculationIsCompleted,
		|		DD.Object AS ProductionOrder,
		|		FALSE AS LotIsReleased
		|	FROM
		|		TTCalculationObjects AS TTCalculationObjects
		|			INNER JOIN OutputFinishedProductsOnOrderDynamicStructure AS DD
		|			ON TTCalculationObjects.Object = DD.Object
		|				AND TTCalculationObjects.Products = DD.Products
		|				AND TTCalculationObjects.Characteristic = DD.Characteristic
		|				AND TTCalculationObjects.Purpose = DD.Purpose
		|) AS VZ
		|GROUP BY
		|	VZ.Period,
		|	VZ.StandardCostEstimate,
		|	VZ.ManufacturedProduct,
		|	VZ.ItemVariant,
		|	VZ.Purpose,
		|	VZ.LotProductBOM,
		|	VZ.LotSemiFinishedProductBOM,
		|	VZ.KeyLot,
		|	VZ.SemiFinishedProduct,
		|	VZ.ItemVariantsOfIntermediateProduct,
		|	VZ.Order,
		|	VZ.Denominator,
		|	VZ.CalculationIsCompleted,
		|	VZ.ProductionOrder,
		|	VZ.LotIsReleased
		|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

// The Query Text of the output products by order is a dynamic structure, it is necessary at the start of the PC calculation,
// for the initial data collection necessary for the calculation.
// 
// Returns:
//  String - Query Text output products by order dynamic structure
Function QueryText_OutputFinishedProductsByOrderDynamicStructure()
	Return "
	|SELECT
	|	ObjectsToBeUncoupled.Object AS Object,
	|	OrderStructure.BillOfMaterials AS BillOfMaterials,
	|	OrderStructure.KeyLot AS KeyLot,
	|	OrderStructure.Products AS Products,
	|	OrderStructure.Characteristic AS Characteristic,
	|	OrderStructure.Purpose AS Purpose,
	|	OrderStructure.Stage AS ReleasingStage,
	|	1 AS CostShare,
	|	SUM(OrderStructure.Scheduled) AS Count
	|INTO OutputFinishedProductsOnOrderDynamicStructure
	|FROM
	|	ObjectsToBeUncoupled AS ObjectsToBeUncoupled
	|		INNER JOIN InformationRegister.OrderStructure AS OrderStructure
	|		ON ObjectsToBeUncoupled.DynamicStructure
	|			AND ObjectsToBeUncoupled.Object = OrderStructure.ProductionOrder
	|			AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts)
	|			AND OrderStructure.Stage REFS Catalog.ProductionStages
	|
	|GROUP BY
	|	ObjectsToBeUncoupled.Object,
	|	OrderStructure.BillOfMaterials,
	|	OrderStructure.KeyLot,
	|	OrderStructure.Purpose,
	|	OrderStructure.Products,
	|	OrderStructure.Characteristic,
	|	OrderStructure.Stage
	|	
	|HAVING
	|	SUM(OrderStructure.Scheduled) > 0
	|";
	
EndFunction

Procedure QueryTextTTCostObjects(Query, QueryTexts)
	
	QueryText = 
		"SELECT DISTINCT
		|	CostObjects.Products,
		|	CostObjects.Characteristic,
		|	CostObjects.Purpose,
		|	CostObjects.Object
		|INTO TTCalculationObjects
		|FROM
		|	Document.StandardCosting2_2.CostObjects AS CostObjects
		|WHERE
		|	CostObjects.Ref = &Ref";
	QueryTexts.Add(QueryText, "TTCalculationObjects");
	
	QueryText = 
		"SELECT DISTINCT
		|	CostObjects.Object AS Object,
		|	CostObjects.Object REFS Document.ProductionOrder2_2
		|		AND CAST(CostObjects.Object AS Document.ProductionOrder2_2).DynamicStructure AS DynamicStructure
		|INTO ObjectsToBeUncoupled
		|FROM
		|	TTCalculationObjects AS CostObjects
		|
		|INDEX BY
		|	Object";
	QueryTexts.Add(QueryText, "TTCalculationObjects");
	
	QueryText = "SELECT
		|	ObjectsToBeUncoupled.Object AS Object,
		|	Attributes.ProductionByThirdParty
		|		OR Attributes.ProductionByThirdParty2_5
		|		OR Attributes.InternalSubcontracting AS ProductionByThirdParty,
		|	Attributes.BillOfMaterials AS BillOfMaterials,
		|	Products_1.Products AS Products,
		|	Products_1.Characteristic AS Characteristic,
		|	Products_1.Purpose AS Purpose,
		|	Products_1.Ref AS ReleasingStage,
		|	Products_1.ToExpenseAs AS ToExpenseAs,
		|	CASE
		|		WHEN Attributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
		|				OR Products_1.Manufactured
		|			THEN CASE
		|					WHEN Attributes.ProductionInOneDay
		|						THEN Attributes.ProductionDate <= &Period
		|								AND Attributes.ProductionDate < &PeriodNotCalculatedForOrganization
		|					ELSE Products_1.ProductionDate <= &Period
		|							AND Products_1.ProductionDate < &PeriodNotCalculatedForOrganization
		|				END
		|			ELSE FALSE
		|	END AS LotIsReleased,
		|	CASE
		|		WHEN Attributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
		|				OR Products_1.Manufactured
		|			THEN CASE
		|					WHEN Attributes.ProductionInOneDay
		|						THEN Attributes.ProductionDate
		|					ELSE Products_1.ProductionDate
		|				END
		|		ELSE Attributes.Date
		|	END AS ProductionDate,
		|	SUM(CASE
		|			WHEN Products_1.CostShare = 0
		|				THEN Products_1.Count
		|			ELSE Products_1.CostShare
		|		END) AS CostShare,
		|	SUM(Products_1.Count) AS Count
		|
		|INTO OutputProductsOnRequest
		|FROM
		|	ObjectsToBeUncoupled AS ObjectsToBeUncoupled
		|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS Products_1
		|		ON &ConnectionConditions
		|
		|		INNER JOIN Document.ProductionStage2_2 AS Attributes
		|		ON Products_1.Ref = Attributes.Ref
		|			AND Attributes.Posted
		|
		|GROUP BY
		|	ObjectsToBeUncoupled.Object,
		|	Attributes.Date,
		|	Attributes.BillOfMaterials,
		|	Attributes.ProductionByThirdParty,
		|	Attributes.ProductionByThirdParty2_5,
		|	Attributes.InternalSubcontracting,
		|	Products_1.Purpose,
		|	Products_1.Products,
		|	Products_1.Characteristic,
		|	Products_1.Ref,
		|	Products_1.ToExpenseAs,
		|	Attributes.Status,
		|	Attributes.ProductionInOneDay,
		|	Attributes.ProductionDate,
		|	Products_1.Manufactured,
		|	Products_1.ProductionDate
		|";
	
	SelectedFields = New Structure;
	SelectedFields.Insert("Products",   "ManufacturedProducts.Products");
	SelectedFields.Insert("Characteristic", "ManufacturedProducts.Characteristic");
	SelectedFields.Insert("Purpose",     "ManufacturedProducts.Purpose");
	SelectedFields.Insert("CostShare",  "ManufacturedProducts.CostShare");
	SelectedFields.Insert("Count",     "ManufacturedProducts.Count");
	
	QueryText = Documents.ProductionStage2_2.SubstituteSelectedFields(QueryText, SelectedFields);
	QueryText = Documents.ProductionStage2_2.SubstituteConnectionToGetOutputProducts(QueryText, 
		"ConnectionConditions",
		New Structure("ReferenceOrder", "ObjectsToBeUncoupled.Object"));
	QueryTexts.Add(QueryText, "OutputProductsOnRequest");
	
	QueryText = 
		"SELECT
		|	WaresFromSpecifications.Products AS Products,
		|	WaresFromSpecifications.Characteristic AS Characteristic,
		|	WaresFromSpecifications.BillOfMaterials AS BillOfMaterials,
		|	WaresFromSpecifications.CostShare AS CostShare,
		|	WaresFromSpecifications.TotalShares AS TotalShares,
		|	WaresFromSpecifications.ProductQuantity AS Count,
		|	WaresFromSpecifications.Numerator AS Numerator,
		|	WaresFromSpecifications.Denominator AS Denominator
		|
		|INTO NodulationResults
		|FROM
		|	&WaresFromSpecifications AS WaresFromSpecifications";
	QueryTexts.Add(QueryText, "NodulationResults");
	
	QueryText = 
		"SELECT
		|	TTCalculationObjects.Products AS Products,
		|	TTCalculationObjects.Characteristic AS Characteristic,
		|	TTCalculationObjects.Object AS BillOfMaterials,
		|	MAX(NodulationResults.CostShare) AS CostShare,
		|	MAX(NodulationResults.Count) AS Count,
		|	MAX(NodulationResults.Numerator) AS Numerator,
		|	MAX(NodulationResults.Denominator) AS Denominator
		|
		|INTO OutputProductsAccordingToSpecification
		|FROM
		|	TTCalculationObjects AS TTCalculationObjects
		|		INNER JOIN NodulationResults AS NodulationResults
		|		ON TTCalculationObjects.Products = NodulationResults.Products
		|			AND TTCalculationObjects.Characteristic = NodulationResults.Characteristic
		|			AND TTCalculationObjects.Object = NodulationResults.BillOfMaterials
		|
		|GROUP BY
		|	TTCalculationObjects.Products,
		|	TTCalculationObjects.Characteristic,
		|	TTCalculationObjects.Object";
	QueryTexts.Add(QueryText, "OutputProductsAccordingToSpecification");
	
	QueryTexts.Add(
		QueryText_OutputFinishedProductsByOrderDynamicStructure(),
		"OutputFinishedProductsOnOrderDynamicStructure"
	);
	
	QueryText = "
		|SELECT
		|	ObjectsToBeUncoupled.Object AS Object,
		|	MAX(NodulationResults.TotalShares) AS TotalShares,
		|	0 ShareByIssuedLotREFERENCES
		|INTO TotalCostShares
		|FROM
		|	ObjectsToBeUncoupled AS ObjectsToBeUncoupled
		|		
		|		INNER JOIN NodulationResults AS NodulationResults
		|		ON ObjectsToBeUncoupled.Object = NodulationResults.BillOfMaterials
		|
		|GROUP BY
		|	ObjectsToBeUncoupled.Object
		|
		|UNION ALL
		|
		|SELECT
		|	OutputProductsOnRequest.ReleasingStage AS ReleasingStage,
		|	SUM(OutputProductsOnRequest.CostShare) AS TotalShares,
		|	SUM(CASE
		|				WHEN OutputProductsOnRequest.LotIsReleased
		|					THEN OutputProductsOnRequest.CostShare
		|				ELSE
		|					0
		|	END) AS ShareByIssuedLotREFERENCES
		|FROM
		|	OutputProductsOnRequest AS OutputProductsOnRequest
		|
		|GROUP BY
		|	OutputProductsOnRequest.ReleasingStage
		|
		|INDEX BY
		|	Object";
	
	SubstitutionParameters = ProductionServer.SubstitutionParametersOfCostFractionCalculationAlgorithm("Products_1", "Attributes.MethodOfAllocatingFinishedProductCosts");
	SubstitutionParameters.CostShare = "&CostShare";
	SubstitutionParameters.CompoundShareCost = "AND &CompoundShareCost";
	SubstitutionParameters.Date = "&Period";
	
	ProductionServer.PerformSubstitutionOfCostFractionCalculationAlgorithm(QueryText, SubstitutionParameters);
	
	QueryTexts.Add(QueryText, "TotalCostShares");
			
EndProcedure

#EndRegion

#Region Private

#Region Other

Function HasActiveBackgroundJobs(ArrayOfTasks)

	For Each Job In ArrayOfTasks Do
		If Job.State = BackgroundJobState.Active Then
			Return True;
		EndIf;
	EndDo;
		
EndFunction

Procedure SetOutputProductsAccordingToSpecification(Query)
	
	Query.Text =
		"SELECT
		|	Objects.Products AS Products,
		|	Objects.Products.ProductKind AS ProductKind,
		|	Objects.Characteristic AS Characteristic,
		|	Objects.Count AS Count,
		|	Objects.Object AS BillOfMaterials,
		|	Attributes.Date AS ProductionStart,
		|	Attributes.ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
		|FROM
		|	Document.StandardCosting2_2.CostObjects AS Objects
		|		INNER JOIN Document.StandardCosting2_2 AS Attributes
		|		ON Objects.Ref = Attributes.Ref
		|WHERE
		|	Attributes.Ref = &Ref
		|	AND Attributes.CostObject = VALUE(Enum.CostObjects.BillOfMaterial)";
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ItemList = Catalogs.BillsOfMaterials.ItemList();
	While Selection.Next() Do
		
		NewRow = ItemList.Add();
		FillPropertyValues(NewRow, Selection);
		
	EndDo;
	
	KCH_10_3 = New NumberQualifiers(10, 3);
	KCH_31_6 = New NumberQualifiers(31, 6);
	Products_1 = New ValueTable;
	Products_1.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Products_1.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Products_1.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	Products_1.Columns.Add("CostShare", New TypeDescription("Number", KCH_10_3));
	Products_1.Columns.Add("TotalShares", New TypeDescription("Number", KCH_10_3));
	Products_1.Columns.Add("ProductQuantity", New TypeDescription("Number", KCH_10_3));
	Products_1.Columns.Add("Numerator", New TypeDescription("Number", KCH_31_6));
	Products_1.Columns.Add("Denominator", New TypeDescription("Number", KCH_31_6));
	
	SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters("ManufacturedProducts");
	SelectionParameters.OverridingReleasePartySetting.Use = True;
	SelectionParameters.RoundUpNumberOfUnitItems_ = False;
	SelectionParameters.CalculateShareOfCostOfOutputProducts = True;
	
	SelectionParameters.Insert("DisableCalculationOfParametricFormulas", True);
	
	SpecificationsData = Catalogs.BillsOfMaterials.SpecificationDataByProductsList(ItemList, SelectionParameters);
	
	IndexOf = 0;
	While IndexOf < SpecificationsData.Count() Do
		
		SpecificationData = SpecificationsData[IndexOf];
		ItemData_3 = ItemList[IndexOf];
		IndexOf = IndexOf + 1;
		
		ManufacturedProducts = SpecificationData.ManufacturedProducts;
		SearchKey = New Structure("Products, Characteristic");
		FillPropertyValues(SearchKey, ItemData_3);
		
		ProductData_3 = ManufacturedProducts.FindRows(SearchKey);
		If ProductData_3.Count() = 0 Then
			
			SearchKey.Characteristic = Catalogs.ItemsCharacteristics.EmptyRef();
			ProductData_3 = ManufacturedProducts.FindRows(SearchKey);
			
			If ProductData_3.Count() = 0 Then
				
				SearchKey = New Structure("ProductKind");
				FillPropertyValues(SearchKey, ItemData_3);
				
				ProductData_3 = ManufacturedProducts.FindRows(SearchKey);
				If ProductData_3.Count() = 0 Then
					Continue;
				EndIf;
				
			EndIf;
			
		EndIf;
		
		NewProduct = Products_1.Add();
		FillPropertyValues(NewProduct, ItemData_3);
		For Each Product In ProductData_3 Do
			
			NewProduct.ProductQuantity = ItemData_3.Count;
			NewProduct.Numerator = ItemData_3.Count;
			NewProduct.Denominator = Product.NumberOfPackagesPerUnitOfProductionBatch * Product.PackageData.Numerator / Product.PackageData.Denominator;
			If Product.CostSharePerUnit = 0 Then
				NewProduct.CostShare = 1;
			Else
				NewProduct.CostShare = NewProduct.CostShare + Product.CostSharePerUnit;
			EndIf;
			
		EndDo;
		
		For Each Product In ManufacturedProducts Do
			NewProduct.TotalShares = NewProduct.TotalShares + Product.CostSharePerUnit
				* Product.NumberOfPackagesPerUnitOfProductionBatch * Product.PackageData.Numerator / Product.PackageData.Denominator;
		EndDo;
		
	EndDo;
	
	Query.SetParameter("WaresFromSpecifications", Products_1);
	
EndProcedure

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PlannedCalculationIsSummarized") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "PlannedCalculationIsSummarized", NStr("vi = 'Tính giá thành sản phẩm (Tóm tắt)';
																															|ru = 'Калькуляция продукции (сводно)';
																															|en = 'Product costing (summary)'; fa = 'Product costing (summary)';
																															|it = 'Calcolo dei prodotti (riepilogo)';
																															|pl = 'Kalkulacja produkcji (krótko)';
																															|tr = 'Ürün maliyetlendirme (özet)'"), GeneratePrintedCalculationForm(ObjectsArray, PrintObjects, True));
	ElsIf PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PlanningCalculationInDetail") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "PlanningCalculationInDetail", NStr("vi = 'Tính giá thành sản phẩm (chi tiết)';
																														|ru = 'Калькуляция продукции (подробно)';
																														|en = 'Product costing (detailed)'; fa = 'Product costing (detailed)';
																														|it = 'Calcolo dei prodotti (dettagliato)';
																														|pl = 'Kalkulacja produkcji (szczegółowo)';
																														|tr = 'Ürün maliyetlendirme (detaylı)'"), GeneratePrintedCalculationForm(ObjectsArray, PrintObjects, False));
	ElsIf PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ErrorLog") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "ErrorLog", NStr("vi = 'Biên bản lỗi';
																									|ru = 'Протокол ошибок';
																									|en = 'Error log'; fa = 'گزارش خطا';
																									|it = 'Registro errori';
																									|pl = 'Protokół błędów';
																									|tr = 'Hata protokolü'"), GeneratePrintedErrorLogForm(ObjectsArray, PrintObjects));
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function GeneratePrintedCalculationForm(ObjectsArray, PrintObjects, Overall)
	
	SetPrivilegedMode(True);
	
	Template = PrintManagement.PrintFormTemplate("Document.StandardCosting2_2.PF_MXL_StandardCosting");
	
	Query = New Query;
	QueriesTexts = New Array();
	QueryText = "SELECT
		|	Attributes.Organization AS Organization,
		|	Attributes.Ref AS Ref,
		|	Attributes.CostObject AS CostObject,
		|	StandardCosting.Products AS Products,
		|	StandardCosting.Characteristic AS Characteristic,
		|	StandardCosting.Purpose AS Purpose,
		|	StandardCosting.Object AS Object,
		|	StandardCosting.Package AS Package,
		|	StandardCosting.Count AS Count,
		|	StandardCosting.NumberOfPackages AS NumberOfPackages,
		|	Attributes.Number AS Number,
		|	Attributes.Date AS Date,
		|	Attributes.EmployeeResponsible.Individual AS Person
		|INTO TableHeader
		|FROM
		|	Document.StandardCosting2_2.CostObjects AS StandardCosting
		|		INNER JOIN Document.StandardCosting2_2 AS Attributes
		|		ON StandardCosting.Ref = Attributes.Ref
		|WHERE
		|	Attributes.Ref IN(&ProductStandardCosts)
		|";
	QueriesTexts.Add(QueryText);
	QueriesTexts.Add(Reports.ProductCostEstimate.QueryText_ProductStandardCostData(True));
	QueryText = "
		|SELECT
		|	TableHeader.Organization AS Organization,
		|	TableHeader.Ref AS StandardCostEstimate,
		|	TableHeader.CostObject AS CostObject,
		|	TableHeader.Products AS ManufacturedProduct,
		|	TableHeader.Characteristic AS Characteristic,
		|	TableHeader.Purpose AS Purpose,
		|	TableHeader.Object AS Object,
		|	CASE
		|		WHEN TableHeader.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN PRESENTATION(TableHeader.Products.UnitOfMeasure)
		|		ELSE PRESENTATION(TableHeader.Package)
		|	END AS UnitOfMeasure,
		|	TableHeader.NumberOfPackages AS Count,
		|	TableHeader.Number AS Number,
		|	TableHeader.Date AS Date,
		|	TableHeader.Person AS Person,
		|	PRESENTATION(TableHeader.Ref) AS Presentation
		|FROM
		|	TableHeader AS TableHeader
		|
		|ORDER BY
		|	StandardCostEstimate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.StandardCostEstimate AS StandardCostEstimate,
		|	NestedQuery.Object AS Object,
		|	NestedQuery.ManufacturedProduct AS ManufacturedProduct,
		|	NestedQuery.ItemVariant AS Characteristic,
		|	NestedQuery.Purpose AS Purpose,
		|	NestedQuery.ExpenseType AS TypeOfCosts,
		|	NestedQuery.ProductCostElement AS ProductCostElement,
		|	NestedQuery.Products AS Cost_,
		|	NestedQuery.ProductsUnitOfMeasure AS UnitOfMeasure,
		|	NestedQuery.Characteristic AS CostCharacteristic,
		|	SUM(NestedQuery.Count) AS Count,
		|	SUM(NestedQuery.Cost) AS Sum,
		|	SUM(NestedQuery.OffBalanceCost) AS OffBalanceSheetAmount,
		|	CASE
		|		WHEN SUM(NestedQuery.Count) = 0
		|				THEN 0
		|			ELSE SUM(NestedQuery.Cost) / SUM(NestedQuery.Count)
		|		END AS Price,
		|	REFPRESENTATION(NestedQuery.Products) AS Cost_Presentation,
		|	REFPRESENTATION(NestedQuery.Characteristic) AS CostCharacteristicPresentation
		|FROM
		|	(SELECT
		|		PlannedCosts.StandardCostEstimate AS StandardCostEstimate,
		|		PlannedCosts.CostObject AS Object,
		|		PlannedCosts.ManufacturedProduct AS ManufacturedProduct,
		|		PlannedCosts.ItemVariant AS ItemVariant,
		|		PlannedCosts.Purpose AS Purpose,
		|		PlannedCosts.ExpenseType AS ExpenseType,
		|		PlannedCosts.ProductCostElement AS ProductCostElement,
		|		PlannedCosts.Products AS Products,
		|		PlannedCosts.Products.UnitOfMeasure AS ProductsUnitOfMeasure,
		|		PlannedCosts.Characteristic AS Characteristic,
		|		PlannedCosts.Count AS Count,
		|		CASE WHEN PlannedCosts.ThisIsASemiFinishedProduct
		|			THEN 0
		|			ELSE PlannedCosts.Cost
		|		END AS Cost,
		|		CASE WHEN PlannedCosts.ThisIsASemiFinishedProduct 
		|			THEN 0
		|			ELSE PlannedCosts.OffBalanceSheet
		|		END AS OffBalanceCost
		|	FROM
		|		Data AS PlannedCosts
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ActualCosts.StandardCostEstimate,
		|		ActualCosts.CostObject,
		|		ActualCosts.ManufacturedProduct,
		|		ActualCosts.ItemVariant,
		|		ActualCosts.Purpose,
		|		ActualCosts.ExpenseType,
		|		ActualCosts.ProductCostElement,
		|		ActualCosts.Products,
		|		ActualCosts.ProductsUnitOfMeasure,
		|		ActualCosts.Characteristic,
		|		CASE
		|			WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
		|				THEN ActualCosts.Count
		|			ELSE DefinitionOfSemiFinishedProducts.Count * ActualCosts.Numerator / ActualCosts.Denominator
		|		END,
		|		CASE
		|			WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
		|				THEN ActualCosts.Cost
		|			WHEN NOT DefinitionOfSemiFinishedProducts.FixedCost
		|				THEN 0
		|			ELSE DefinitionOfSemiFinishedProducts.Cost * ActualCosts.Numerator / ActualCosts.Denominator
		|		END,
		|		CASE
		|			WHEN DefinitionOfSemiFinishedProducts.ItemsLocationAttributes IS NULL
		|				THEN ActualCosts.OffBalanceSheet
		|			WHEN NOT DefinitionOfSemiFinishedProducts.FixedCost
		|				THEN 0
		|			ELSE DefinitionOfSemiFinishedProducts.OffBalanceCost * ActualCosts.Numerator / ActualCosts.Denominator
		|		END
		|	FROM
		|		ActualCosts AS ActualCosts
		|			LEFT JOIN DefinitionOfSemiFinishedProducts AS DefinitionOfSemiFinishedProducts
		|			ON ActualCosts.ItemsLocationAttributes = DefinitionOfSemiFinishedProducts.ItemsLocationAttributes
		|				AND (CASE
		|					WHEN ActualCosts.ThisIsOutput_
		|						THEN ActualCosts.LotProductBOM = DefinitionOfSemiFinishedProducts.LotProductBOM
		|					ELSE ActualCosts.SemiFinishedProductLot = DefinitionOfSemiFinishedProducts.LotProductBOM
		|					END)
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.ProductCostElement,
		|	NestedQuery.Object,
		|	NestedQuery.ProductsUnitOfMeasure,
		|	NestedQuery.Purpose,
		|	NestedQuery.Products,
		|	NestedQuery.ManufacturedProduct,
		|	NestedQuery.StandardCostEstimate,
		|	NestedQuery.ExpenseType,
		|	NestedQuery.ItemVariant,
		|	NestedQuery.Characteristic
		|
		|HAVING
		|	NOT SUM(NestedQuery.Count) = 0
		|		OR NOT SUM(NestedQuery.Cost) = 0";
	
	QueriesTexts.Add(QueryText);
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("ProductStandardCosts", ObjectsArray);
	Query.SetParameter("Cost_Data", 3);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.LeftMargin = 5;
	SpreadsheetDocument.RightMargin = 5;
	SpreadsheetDocument.HeaderSize = 0;
	SpreadsheetDocument.FooterSize = 0;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_StandardCosting";
	
	Query.Text = Documents.ProductionStage2_2.SubstituteSelectedFields(Query.Text, 
		New Structure("Count, RowCode", 
			"ProductionStage2_2OutputProducts.Count", "ProductionStage2_2OutputProducts.RowCode"));
	
	ConnectionFields = New Structure;
	ConnectionFields.Insert("Stage", "CommonMultipliers.LotProductBOM");
	ConnectionFields.Insert("Products", "CommonMultipliers.ManufacturedProduct");
	ConnectionFields.Insert("Characteristic", "CommonMultipliers.ItemVariant");
	ConnectionFields.Insert("Purpose", "CommonMultipliers.Purpose");
	Query.Text = Documents.ProductionStage2_2.SubstituteConnectionToGetOutputProducts(Query.Text, 
		"ConnectionConditions",
		ConnectionFields);
	
	ResultsArray  = Query.ExecuteBatch();
	
	HeaderData_ = ResultsArray[ResultsArray.Count() - 2].Select();
	DetailedRecords = ResultsArray[ResultsArray.Count() - 1].Unload(); // ValueTable
	If Overall Then
		DetailedRecords.GroupBy("ManufacturedProduct, Characteristic, Purpose, StandardCostEstimate, Object, TypeOfCosts, ProductCostElement", "Sum, OffBalanceSheetAmount");
	EndIf;
	
	DetailedRecords.Indexes.Add("StandardCostEstimate, Object, ManufacturedProduct, Characteristic, Purpose");
	
	FirstDocument = True;
		
	While HeaderData_.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
					
		// Output of the general details of the header.
		TemplateArea = Template.GetArea("Title");
		
		AreaParameters_ = New Structure("TitleText");
		AreaParameters_.TitleText = TMCommonUseClientServer.GenerateDocumentTitle(
			HeaderData_, NStr("vi = 'Tính giá thành sản phẩm';
								|ru = 'Калькуляция продукции';
								|en = 'Product costing'; fa = 'بهای‌یابی محصول';
								|it = 'Calcolo dei prodotti';
								|pl = 'Kalkulacja produkcji';
								|tr = 'Ürün maliyetlendirme'", Common.DefaultLanguageCode()));
		TemplateArea.Parameters.Fill(AreaParameters_);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, HeaderData_.StandardCostEstimate);
		SpreadsheetDocument.Put(TemplateArea);
		
		FirstDocument    = False;
		OrderCosting = HeaderData_.CostObject = Enums.CostObjects.ProductionOrder;

		TemplateArea = Template.GetArea("Title_Organization");
		AreaParameters_ = New Structure("Organization", HeaderData_.Organization);
		TemplateArea.Parameters.Fill(AreaParameters_);
		SpreadsheetDocument.Put(TemplateArea);
		
		If OrderCosting Then
			TemplateArea = Template.GetArea("Title_Order");
		Else
			TemplateArea = Template.GetArea("Title_Specification");
		EndIf;
		
		AreaParameters_ = New Structure("Count", 
			Format(HeaderData_.Count, "ND=10; NFD=3") + " " + HeaderData_.UnitOfMeasure);
		TemplateArea.Parameters.Fill(HeaderData_);
		TemplateArea.Parameters.Fill(AreaParameters_);
		SpreadsheetDocument.Put(TemplateArea);
		
		TheStructureOfTheSearch = New Structure("StandardCostEstimate, Object, ManufacturedProduct, Characteristic, Purpose");
		FillPropertyValues(TheStructureOfTheSearch, HeaderData_);
		
		SelectionWithoutOffBalance = New Structure("OffBalanceSheetAmount", 0);
		
		DetailedSetRecords = DetailedRecords.Copy(TheStructureOfTheSearch);
		If DetailedSetRecords.Count() - DetailedSetRecords.FindRows(SelectionWithoutOffBalance).Count() > 0 Then
			HeaderWithoutDetails = "HeaderWithoutDetailsAndOffBalance";
			TableRowsAreSummarized = "TableRowsAreSummarizedWithOffBalance";
			TableRowsSummaryTypeCosts = "TableRowsSummaryTypeCostsWithOffBalance";
			SummaryTableResults = "ResultsOfTableAreSummarizedWithOffBalance";
			HeaderDetails_1 = "DetailHeaderWithOffBalance";
			TableRowsInDetail = "TableRowsInDetailWithOffBalance";
			TableRowsDetailTypeOfCosts = "RowsInTableDetailTypeOfCostsWithOffBalance";
			TableRowsDetailArticleCalculation = "TableRowsDetailArticleOffBalanceCalculations";
			TableResultsInDetail = "TableResultsInDetailWithOffBalance";
		Else
			HeaderWithoutDetails = "HeaderWithoutDetails";
			TableRowsAreSummarized = "TableRowsAreSummarized";
			TableRowsSummaryTypeCosts = "TableRowsSummaryTypeCosts";
			SummaryTableResults = "SummaryTableResults";
			HeaderDetails_1 = "HeaderDetails_1";
			TableRowsInDetail = "TableRowsInDetail";
			TableRowsDetailTypeOfCosts = "TableRowsDetailTypeOfCosts";
			TableRowsDetailArticleCalculation = "TableRowsDetailArticleCalculation";
			TableResultsInDetail = "TableResultsInDetail";
		EndIf;
		
		If Overall Then
			
			HeaderArea = Template.GetArea(HeaderWithoutDetails);
			RowArea_ = Template.GetArea(TableRowsAreSummarized);
			ScopeTypeOfCosts = Template.GetArea(TableRowsSummaryTypeCosts);
			ScopeOfCalculation = Undefined;
			ScopeOfResults = Template.GetArea(SummaryTableResults);
			
		Else
			
			HeaderArea = Template.GetArea(HeaderDetails_1);
			RowArea_ = Template.GetArea(TableRowsInDetail);
			ScopeTypeOfCosts = Template.GetArea(TableRowsDetailTypeOfCosts);
			ScopeOfCalculation = Template.GetArea(TableRowsDetailArticleCalculation);
			ScopeOfResults = Template.GetArea(TableResultsInDetail);
			
		EndIf;
		
		SpreadsheetDocument.Put(HeaderArea);
		
		If Overall Then
			DetailedSetRecords.Sort("TypeOfCosts, ProductCostElement");
		Else
			DetailedSetRecords.Sort("TypeOfCosts, ProductCostElement, Cost_");
		EndIf;
		
		Material_ = 0;
		RecyclableWaste = 0;
		MaterialOffBalance = 0;
		Payroll = 0;

		OtherVariables = 0;
		OtherPermanent = 0;
		
		TypeOfCosts = "";
		ProductCostElement = Undefined;
		
		For Each DetailRecord In DetailedSetRecords Do
			
			If Not TypeOfCosts = DetailRecord.TypeOfCosts Then
				
				ProductCostElement = Undefined;
				TotalByCostType = 0;
				TotalByCostTypeOffBalance = 0;
				RowsByCostType = DetailedSetRecords.FindRows(New Structure("TypeOfCosts", DetailRecord.TypeOfCosts));
				
				For Each LineByCostType In RowsByCostType Do
					
					TotalByCostType = TotalByCostType + LineByCostType.Sum;
					TotalByCostTypeOffBalance = TotalByCostTypeOffBalance + LineByCostType.OffBalanceSheetAmount;
					
				EndDo;
				
				If DetailRecord.TypeOfCosts = "Material_" Then
					
					CostTypePresentation = NStr("vi = 'Nguyên vật liệu';
												|ru = 'Материальные';
												|en = 'Material'; fa = 'ماده';
												|it = 'Materiali';
												|pl = 'Materiałowe';
												|tr = 'Malzeme'", Common.DefaultLanguageCode());
					Material_ = TotalByCostType;
					MaterialOffBalance = TotalByCostTypeOffBalance;
					
				ElsIf DetailRecord.TypeOfCosts = "RecyclableWaste" Then
					
					CostTypePresentation = NStr("vi = 'Phế liệu thu hồi /Xuất sản phẩm phụ';
												|ru = 'Возвратные отходы/Побочный выпуск';
												|en = 'Recyclable waste/Side release'; fa = 'Recyclable waste/Side release';
												|it = 'Rifiuti riciclabili/Produzione secondaria';
												|pl = 'Odpady i półprodukty/Produkcja uboczna';
												|tr = 'Geri dönüştürülebilir atıklar/Yan ürün çıkışı'", Common.DefaultLanguageCode());
					RecyclableWaste = TotalByCostType;
					
				ElsIf DetailRecord.TypeOfCosts = "LaborCosts" Then
					
					CostTypePresentation = NStr("vi = 'Trả tiền lương';
												|ru = 'Оплата труда';
												|en = 'Payroll'; fa = 'حقوق و دستمزد';
												|it = 'Retribuzione';
												|pl = 'Wynagrodzenie';
												|tr = 'İşçilik ödemesi'", Common.DefaultLanguageCode());
					Payroll = TotalByCostType;
					
				ElsIf DetailRecord.TypeOfCosts = "OtherVariables" Then
					CostTypePresentation = NStr("vi = 'Mục hàng biến đổi';
												|ru = 'Постатейные переменные';
												|en = 'Variable costs'; fa = 'هزینه‌های متغیر';
												|it = 'Costi dettagliati variabili';
												|pl = 'Zmienne elementów zamówienia';
												|tr = 'Ayrıntılı değişken giderler'", Common.DefaultLanguageCode());
					OtherVariables = TotalByCostType;
					
				ElsIf DetailRecord.TypeOfCosts = "OtherPermanent" Then
					
					CostTypePresentation = NStr("vi = 'Mục hàng cố định';
												|ru = 'Постатейные постоянные';
												|en = 'Itemized fixed'; fa = 'ثابت تفکیکی';
												|it = 'Costi dettagliati fissi';
												|pl = 'Stałe elementów zamówienia';
												|tr = 'Ayrıntılı sabit giderler'", Common.DefaultLanguageCode());
					OtherPermanent = TotalByCostType;
					
				EndIf;
				
				AreaParameters_ = New Structure;
				AreaParameters_.Insert("TypeOfCosts", CostTypePresentation);
				AreaParameters_.Insert("Sum", TotalByCostType);
				AreaParameters_.Insert("OffBalanceSheetAmount", TotalByCostTypeOffBalance);
				ScopeTypeOfCosts.Parameters.Fill(AreaParameters_);
				
				SpreadsheetDocument.Put(ScopeTypeOfCosts);
				
			EndIf;
			
			If Not ScopeOfCalculation = Undefined And Not ProductCostElement = DetailRecord.ProductCostElement Then
				
				RowFilter = New Structure("TypeOfCosts, ProductCostElement", 
					DetailRecord.TypeOfCosts, DetailRecord.ProductCostElement);
					
				LinesByCalculationMethod = DetailedSetRecords.FindRows(RowFilter);
				TotalForArticle = 0;
				TotalForItemOffBalance = 0;
				
				For Each LineByArticle In LinesByCalculationMethod Do
					
					TotalForArticle = TotalForArticle + LineByArticle.Sum;
					TotalForItemOffBalance = TotalForItemOffBalance + LineByArticle.OffBalanceSheetAmount;
					
				EndDo;
				
				AreaParameters_ = New Structure;
				AreaParameters_.Insert("ProductCostElement", DetailRecord.ProductCostElement);
				AreaParameters_.Insert("Sum", TotalForArticle);
				AreaParameters_.Insert("OffBalanceSheetAmount", TotalForItemOffBalance);
				ScopeOfCalculation.Parameters.Fill(AreaParameters_);
				
				SpreadsheetDocument.Put(ScopeOfCalculation);
				
			EndIf;
			
			TypeOfCosts = DetailRecord.TypeOfCosts;
			ProductCostElement = DetailRecord.ProductCostElement;
			
			RowArea_.Parameters.Fill(DetailRecord);
			If Not Overall And ValueIsFilled(DetailRecord.CostCharacteristic) Then
				
				AreaParameters_ = New Structure("Cost_", 
					DetailRecord.Cost_Presentation + ", " + DetailRecord.CostCharacteristicPresentation);
				RowArea_.Parameters.Fill(AreaParameters_);
				
			EndIf;
			
			SpreadsheetDocument.Put(RowArea_);
			
		EndDo;
		
		AreaParameters_ = New Structure;
		AreaParameters_.Insert("TotalMaterial", Material_);
		AreaParameters_.Insert("TotalReturnableWaste", RecyclableWaste);
		AreaParameters_.Insert("TotalLaborCosts", Payroll);
		AreaParameters_.Insert("TotalArticleByArticle", OtherVariables + OtherPermanent);
		AreaParameters_.Insert("InTotal",
			Material_ + Payroll + OtherVariables + OtherPermanent + RecyclableWaste);
		AreaParameters_.Insert("TotalOffBalance", MaterialOffBalance);
		AreaParameters_.Insert("Currency", String(SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(HeaderData_.Organization)));
		ScopeOfResults.Parameters.Fill(AreaParameters_);
		
		SpreadsheetDocument.Put(ScopeOfResults);
		
		TemplateArea = Template.GetArea("Signatures");
		AreaParameters_ = New Structure("EmployeeResponsible",
			PersonsTM.IndividualShortName(HeaderData_.Person, HeaderData_.Date));
		TemplateArea.Parameters.Fill(AreaParameters_);
		
		SpreadsheetDocument.Put(TemplateArea);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function GeneratePrintedErrorLogForm(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	Template = PrintManagement.PrintFormTemplate("Document.StandardCosting2_2.PF_MXL_ErrorLog");
	TempTablesManager = New TempTablesManager;
	InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.GetProductPrices(ObjectsArray, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ArrayOfPlannedCalculations", ObjectsArray);
	
	ArrayOfRequestTexts = New Array();
	Query.SetParameter("UseLaborGradesOfEmployeeActivityRates",
		GetFunctionalOption("UseLaborGradesOfEmployeeActivityRates"));
	ArrayOfRequestTexts.Add(AccumulationRegisters.PlannedLaborCosts.QueryTextOfLaborCostsPricing(False));
	
	QueryText = "SELECT
		|	PlannedMaterialCosts.StandardCostEstimate AS Recorder,
		|	PlannedMaterialCosts.Products AS Cost_,
		|	PlannedMaterialCosts.Characteristic,
		|	""Material_"" AS TypeOfCosts
		|INTO Costs
		|FROM
		|	AccumulationRegister.PlannedMaterialCosts AS PlannedMaterialCosts
		|		LEFT JOIN ItemsPrices AS ItemsPrices
		|		ON PlannedMaterialCosts.StandardCostEstimate = ItemsPrices.StandardCostEstimate
		|			AND PlannedMaterialCosts.Products = ItemsPrices.Products
		|			AND PlannedMaterialCosts.Characteristic = ItemsPrices.Characteristic
		|			AND PlannedMaterialCosts.Period = ItemsPrices.Period
		|WHERE
		|	NOT PlannedMaterialCosts.ThisIsASemiFinishedProduct
		|	AND PlannedMaterialCosts.StandardCostEstimate IN (&ArrayOfPlannedCalculations)
		|	AND ISNULL(ItemsPrices.Price, 0) = 0
		|
		|GROUP BY
		|	PlannedMaterialCosts.StandardCostEstimate,
		|	PlannedMaterialCosts.Products,
		|	PlannedMaterialCosts.Characteristic
		|
		|UNION ALL
		|
		|SELECT
		|	PlannedLaborCosts.StandardCostEstimate AS Recorder,
		|	PlannedLaborCosts.WorkKind,
		|	UNDEFINED,
		|	""LaborCosts""
		|FROM
		|	AccumulationRegister.PlannedLaborCosts AS PlannedLaborCosts
		|	LEFT JOIN Rates AS Rates
		|	ON PlannedLaborCosts.StandardCostEstimate = Rates.StandardCostEstimate
		|		AND PlannedLaborCosts.WorkKind = Rates.WorkKind
		|		AND PlannedLaborCosts.Period = Rates.Period
		|		AND PlannedLaborCosts.Department = Rates.Department
		|WHERE
		|	PlannedLaborCosts.StandardCostEstimate IN (&ArrayOfPlannedCalculations)
		|	AND ISNULL(Rates.Rate_, 0) = 0
		|
		|GROUP BY
		|	PlannedLaborCosts.StandardCostEstimate,
		|	PlannedLaborCosts.WorkKind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Costs.Cost_ AS Cost_,
		|	Costs.Characteristic AS Characteristic,
		|	Costs.Recorder AS Recorder,
		|	Costs.TypeOfCosts AS TypeOfCosts,
		|	Attributes.Date AS Date,
		|	Attributes.Number AS Number
		|FROM
		|	Costs AS Costs
		|		LEFT JOIN Document.StandardCosting2_2 AS Attributes
		|		ON Costs.Recorder = Attributes.Ref
		|TOTALS BY
		|	Recorder";
		
	ArrayOfRequestTexts.Add(QueryText);
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	Costs = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.LeftMargin = 5;
	SpreadsheetDocument.RightMargin = 5;
	SpreadsheetDocument.HeaderSize = 0;
	SpreadsheetDocument.FooterSize = 0;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ErrorLog";
	
	FirstDocument = True;
	
	For Each LoggerString In Costs.Rows Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		// Output of the general details of the header.
		TemplateArea = Template.GetArea("Header");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, LoggerString.Recorder);
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Nhật ký lỗi %1';
				|ru = 'Протокол ошибок %1';
				|en = 'Error log %1'; fa = 'Error log %1';
				|it = 'Registro errori %1';
				|pl = 'Protokół błędów %1';
				|tr = 'Hata protokolü %1'", Common.DefaultLanguageCode()),
			TMCommonUseClientServer.GenerateDocumentTitle(LoggerString, NStr("vi = 'tính giá thành sản phẩm';
																			|ru = 'калькуляции продукции';
																			|en = 'product costings'; fa = 'product costings';
																			|it = 'calcolo prodotti';
																			|pl = 'kalkulacje produkcji';
																			|tr = 'imal edilen ürün maliyetlendirmeleri'", Common.DefaultLanguageCode())));
		TemplateArea.Parameters.TitleText = TitleText;
		SpreadsheetDocument.Put(TemplateArea);
		
		FirstDocument = False;
		
		CostLines = LoggerString.Rows;
		If CostLines.Count() = 0 Then
			Continue;
		EndIf;
		
		UsedMaterials = CostLines.FindRows(New Structure("TypeOfCosts", "Material_"));
		LaborCosts = CostLines.FindRows(New Structure("TypeOfCosts", "LaborCosts"));
		
		If UsedMaterials.Count() >= LaborCosts.Count() Then
			
			AreaName = "UsedMaterials";
			CrawlTable = UsedMaterials;
			Supplement_Table = LaborCosts;
			
			AreaField = "Products";
			ExtensionField = "KindOfWork";
			
		Else
			
			AreaName = "Works";
			CrawlTable = LaborCosts;
			Supplement_Table = UsedMaterials;
			
			AreaField = "KindOfWork";
			ExtensionField = "Products";
			
		EndIf;
		
		ExtensionArea = "";
		If UsedMaterials.Count() > 0 And LaborCosts.Count() > 0 Then
			Area_TableHeader = Template.GetArea("TableHeader");
		ElsIf UsedMaterials.Count() = 0 And LaborCosts.Count() > 0 Then
			
			Area_TableHeader = Template.GetArea("TableHeader|WorkColumn");
			ExtensionArea = "|WorkColumn";
			
		Else 
			
			Area_TableHeader = Template.GetArea("TableHeader|MaterialsColumn");
			ExtensionArea = "|MaterialsColumn";
			
		EndIf;
		
		SpreadsheetDocument.Put(Area_TableHeader);
		
		IndexOf = 0;
		For Each CostLine In CrawlTable Do
			
			ExtensionString = Undefined;
			If IndexOf < Supplement_Table.Count() Then
				
				TemplateArea = Template.GetArea("MaterialsOfWork");
				ExtensionString = Supplement_Table[IndexOf];
				
			Else
				TemplateArea = Template.GetArea(AreaName + ExtensionArea);
			EndIf;
			
			TemplateArea.Parameters.Fill(CostLine);
			TemplateArea.Parameters[AreaField] = CostLine.Cost_;
			
			If Not ExtensionString = Undefined Then
				
				TemplateArea.Parameters.Fill(ExtensionString);
				TemplateArea.Parameters[ExtensionField] = ExtensionString.Cost_;
				
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
		EndDo;
		
		StructureOfResults = New Structure();
		StructureOfResults.Insert("QuantityOfMaterials", UsedMaterials.Count());
		StructureOfResults.Insert("NumberOfWorks", LaborCosts.Count());
		
		TemplateArea = Template.GetArea("Footer" + ExtensionArea);
		TemplateArea.Parameters.Fill(StructureOfResults);
		
		SpreadsheetDocument.Put(TemplateArea);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#Region AuditOfSystemState

// Adds a new system health check to the check table and fills in its key fields.
//
// Parameters:
//	TableOfChecks 			 - See AuditOfSystemState.SystemStateCheckTable
//	Id 				 - String - unique string ID (code) of the check
//	AccountingChecksContext 			 - CatalogRef.MonthEndClosingOperations - the month closing stage (owner) that the check belongs to
//	AccountingCheckContextClarification - EnumRef.TimeOfStartingMonthEndClosingOperationCheck - when to perform a check
//	Handler 					 - String - full name of the export handler procedure that is called to perform the check
//	IssueSeverity 					 - EnumRef.AccountingIssueSeverity - default status for verification results.
// 
// Returns:
//	ValueTableRow - added row of the verification table.
//
Function AddDescriptionOfNewCheck(TableOfChecks, Id, AccountingChecksContext,
			AccountingCheckContextClarification, Handler, IssueSeverity = Undefined) Export
	
	VerificationDescription = TableOfChecks.Add();
	
	VerificationDescription.Id 				  = Id;
	VerificationDescription.ParentID 		 = "ProductCostings";
	VerificationDescription.AccountingChecksContext 		  = AccountingChecksContext;
	VerificationDescription.AccountingCheckContextClarification = AccountingCheckContextClarification;
	VerificationDescription.Handler 				  = Handler;
	VerificationDescription.IssueSeverity 					  =
		?(ValueIsFilled(IssueSeverity), IssueSeverity, Enums.AccountingIssueSeverity.Error);
		
	VerificationDescription.ExecutedOnlyInContext = True;
	VerificationDescription.CanEditImportance   = False;
	
	VerificationDescription.DetailsByCompany    = True;
	VerificationDescription.DetailsByPeriod        = False;
	VerificationDescription.Use			     = True;
	
	Return VerificationDescription;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
