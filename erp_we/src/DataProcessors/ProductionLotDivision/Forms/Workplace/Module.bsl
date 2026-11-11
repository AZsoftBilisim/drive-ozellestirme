
#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ReadSettings();
	
	If TypeOf(Parameters.ProductionLot) = Type("UUID") Then
		Object.ProductionLot = Catalogs.ProductionLots.GetRef(Parameters.ProductionLot);
	Else
		Object.ProductionLot = Parameters.ProductionLot;
	EndIf;
	
	// This instalment
	Query = New Query(
		"SELECT
		|	ProductionLots.Document AS ReferenceOrder,
		|	CAST(ProductionLots.Document AS Document.ProductionOrder2_2).Number AS DocumentNumber,
		|	ISNULL(Stages.AssignmentProducts, ProductionLots.Purpose) AS AssignmentProducts,
		|	ProductionLots.Code AS Code
		|FROM
		|	Catalog.ProductionLots AS ProductionLots
		|
		|	LEFT JOIN Document.ProductionStage2_2 AS Stages
		|	ON Stages.Ref = &Stage
		|WHERE
		|	ProductionLots.Ref = &ProductionLot");
	Query.SetParameter("ProductionLot", Object.ProductionLot);
	Query.SetParameter("Stage", Parameters.Stage);
	AttributesValues = Query.Execute().Select();
	If AttributesValues.Next() Then
		FillPropertyValues(Object, AttributesValues, "ReferenceOrder, AssignmentProducts");
		PartyPresentation = PartyPresentation(AttributesValues.Code, AttributesValues.DocumentNumber);
	EndIf;
	
	BatchData = Documents.ProductionStage2_2.ProductionBatchData(
		Object.ReferenceOrder,
		Object.AssignmentProducts,
		Object.ProductionLot);
	FillPropertyValues(Object, BatchData,
		"Organization,
		|BusinessOperation,
		|Partner,
		|Contract,
		|LineOfBusiness,
		|BillOfMaterials,
		|ProductionProcessType,
		|ProductionDispatcherBusinessUnit,
		|ProductionStart,
		|MainProductProducts,
		|MainProductCharacteristic,
		|Products,
		|Characteristic,
		|Count,
		|DynamicStructure,
		|UnderRepairProduct,
		|UnderRepairVariant,
		|UnderRepairBatch");
	
	Query = New Query(
		"SELECT
		|	Products.Presentation AS Presentation,
		|	Products.UnitOfMeasure AS UnitOfMeasure,
		|	Products.ItemsType AS ItemsType
		|FROM
		|	Catalog.Products AS Products
		|WHERE
		|	Products.Ref = &Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ItemsCharacteristics.Presentation AS Presentation
		|FROM
		|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|WHERE
		|	ItemsCharacteristics.Ref = &Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	TRUE AS ThisIsFinishedProductOfOrder
		|FROM
		|	Document.ProductionOrder2_2.ManufacturedProduct AS Products_1
		|WHERE
		|	Products_1.Ref = &ReferenceOrder
		|	AND Products_1.Products = &Products
		|	AND Products_1.Characteristic = &Characteristic
		|	AND NOT Products_1.Canceled");
	Query.SetParameter("Products", Object.MainProductProducts);
	Query.SetParameter("Characteristic", Object.MainProductCharacteristic);
	Query.SetParameter("ReferenceOrder", Object.ReferenceOrder);
	ResultsArray = Query.ExecuteBatch();
	
	ProductAttributes = ResultsArray[0].Select();
	If ProductAttributes.Next() Then
		ProductProductRangePresentation = ProductAttributes.Presentation;
		ProductUnitOfMeasurement = ProductAttributes.UnitOfMeasure;
		FinishedProductTypeOfItem = ProductAttributes.ItemsType;
		Items.PackageOfLot.InputHint = ProductUnitOfMeasurement;
		Items.SimpleCutPackagingUnitLotReferenceMode.InputHint = ProductUnitOfMeasurement;
	EndIf;
	
	CharacteristicsAttributes = ResultsArray[1].Select();
	If CharacteristicsAttributes.Next() Then
		ProductFeaturePresentation = CharacteristicsAttributes.Presentation;
	EndIf;
	
	ThisIsFinishedProductOfOrder = Not ResultsArray[2].IsEmpty()
		And (Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
			Or Object.ProductionProcessType = Enums.ProductionProcessTypes.Repair
			Or Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM);
	
	AddressProductionProcessLotReference = ProductionProcessOfLotReferenceInStorage(
		Object.ProductionLot, UUID, False);
	
	If Not Object.BillOfMaterials.IsEmpty() Then
		AddressProductionProcess = ProductionProcessInWarehouse(Object.BillOfMaterials, UUID);
	EndIf;
	
	// Setting the action by parameters
	If Parameters.ReduceIncrease Then
		Object.Action = Actions().Reduce;
	ElsIf Parameters.Cancel Then
		Object.Action = Actions().Cancel;
	ElsIf Parameters.RecordDefectiveGoods Then
		Object.Action = Actions().DefectiveGoods;
	Else
		Object.Action = Actions().Split;
	EndIf;
	
	// Stage calculation
	If Parameters.Stage.IsEmpty() Then
		Query = New Query(
			"SELECT TOP 1
			|	Stages.Ref AS Stage
			|FROM
			|	Document.ProductionStage2_2 AS Stages
			|	
			|	LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS RegulatorySchedule
			|	ON Stages.Ref = RegulatorySchedule.ProductionStage
			|WHERE
			|	Stages.ProductionLot = &ProductionLot
			|	AND Stages.Posted
			|	AND Stages.Status <> VALUE(Enum.StatusesOfProductionStages2_2.Completed)
			|
			|ORDER BY
			|	ISNULL(RegulatorySchedule.DurationBeforeStart, -Stages.DurationBeforeProductionIssue)");
		Query.SetParameter("ProductionLot", Object.ProductionLot);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Object.Stage = Selection.Stage;
		EndIf;
	Else
		Object.Stage = Parameters.Stage;
	EndIf;
	
	// Calculation of the operation
	If Not Object.Stage.IsEmpty() Then
		TempTablesManager = New TempTablesManager();
		DataProcessors.ProductionLotDivision.CreateTTQueueOfOperationsForDivision(TempTablesManager, Object.Stage);
		Query = New Query(
			"SELECT TOP 1
			|	Queue.Operation AS Operation,
			|	Queue.OperationID AS OperationID,
			|	Queue.ProductionOperation AS ProductionOperation,
			|	Queue.Description AS Description,
			|	NOT TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			TTOperationQueue AS Predecessors
			|		WHERE
			|			Predecessors.NextOperation = Queue.OperationNumber) AS ThisIsFirstOperation,
			|	Queue.NextOperation = 0 AS ThisIsLastOperation
			|FROM
			|	TTOperationQueue AS Queue
			|WHERE
			|	(Queue.OperationsToDestination > 0 OR Queue.ThereIsDefectiveGoods)
			|	AND NOT TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			TTOperationQueue AS Successors
			|		WHERE
			|			Queue.NextOperation <> 0
			|			AND Successors.OperationNumber >= Queue.NextOperation
			|			AND Successors.IsStarted
			|	)
			|
			|ORDER BY
			|	Queue.OperationNumber");
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("Stage", Object.Stage);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Object.Operation = Selection.Operation;
			FillPropertyValues(Object, Selection,
				"Operation, OperationID, ProductionOperation, ThisIsFirstOperation, ThisIsLastOperation");
		EndIf;
	EndIf;
	
	// Stage data
	Data_Stage = Data_Stage(Object, ProductUnitOfMeasurement);
	If Data_Stage = Undefined Then
		Object.NumberOfPackages = Object.Count;
	Else
		FillInAccordingToStageData(Data_Stage);
		Object.NumberOfPackagingUnitsNonconformity = Data_Stage.NumberOfPackagingUnitsNonconformity;
	EndIf;
	
	// The parameters of the cost distribution
	Query = New Query("
		|SELECT
		|	MAX(Table.MethodOfAllocatingFinishedProductCosts) AS Value
		|FROM
		|	Document.ProductionStage2_2 AS Table
		|WHERE
		|	Table.ProductionLot = &ProductionLot
		|	AND NOT Table.DeletionMark
		|	AND Table.NextStageNo = 0 //This is the issuing step()
		|
		|HAVING
		|	COUNT(DISTINCT Table.MethodOfAllocatingFinishedProductCosts) = 1");
	Query.SetParameter("ProductionLot", Object.ProductionLot);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Object.MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		Object.MethodOfAllocatingFinishedProductCosts = Selection.Value;
	EndIf;
	
	StageEditingParameters = New FixedStructure(
		DataProcessors.ProductionLotDivision.StageEditingParameters());
	CostAllocationParameters = New FixedStructure(
		DataProcessors.ProductionLotDivision.CostAllocationParameters(Object.MethodOfAllocatingFinishedProductCosts));
	
	// Parameters for specifying series
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(Object, DataProcessors.ProductionLotDivision));
		
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	Items.Purpose.ChoiceParameterLinks = Items.LotsPurpose.ChoiceParameterLinks;
	Items.Purpose.ChoiceParameters = Items.LotsPurpose.ChoiceParameters;
	Items.Purpose.ChoiceForm = Items.LotsPurpose.ChoiceForm;
	
	// Assignments
	If BatchData.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
		And Object.DynamicStructure Then
		
		Query = New Query(
			"SELECT
			|	Products_1.Purpose        AS Purpose,
			|	SUM(Products_1.Count) AS Count
			|FROM
			|	Document.ProductionStage2_2 AS ProductionStage
			|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS Products_1
			|		ON Products_1.Ref = ProductionStage.Ref
			|		AND Products_1.Products = ProductionStage.ProductionLot.MainProductProducts
			|		AND Products_1.Characteristic = ProductionStage.ProductionLot.MainProductCharacteristic
			|WHERE
			|	ProductionStage.ProductionLot = &ProductionLot
			|	AND ProductionStage.Posted
			|	AND NOT Products_1.Canceled
			|GROUP BY
			|	Products_1.Purpose
			|ORDER BY
			|	MIN(Products_1.LineNumber)");
		Query.SetParameter("ProductionLot", Object.ProductionLot);
		AssignmentsStandards.Load(Query.Execute().Unload());
		
	EndIf;
	Items.SpecifyDestinations.Visible = AssignmentsStandards.Count() > 1;
	Items.PartyAssignmentGroup.Visible = AssignmentsStandards.Count() > 1;
	
	// Individual technological processes
	Query = New Query("
	|SELECT
	|	TRUE
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage
	|		INNER JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcesses
	|		ON ProductionStage.Ref = TechnicalProcesses.Stage
	|		AND TechnicalProcesses.TechnologicalProcessType = VALUE(Enum.TechnologicalProcessTypesOfStage.Individual_)
	|WHERE
	|	ProductionStage.ProductionLot = &ProductionLot
	|	AND ProductionStage.Posted");
	Query.SetParameter("ProductionLot", Object.ProductionLot);
	Items.DecorationHasIndividualProcessTechnology.Visible = Not Query.Execute().IsEmpty();
	
	// Initialization of other details
	ProcessingOfTabularForms.InitializeRowCache(Items.Lots);
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, DataProcessors.ProductionLotDivision);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.ContinueBOM, BOMSelectionParameters);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.LotsContinueBOM, BOMSelectionParameters);
	
	ItemsAndDimensionsSelectionParameters = DataProcessors.ProductionLotDivision.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SetupParameters = DataProcessors.ProductionLotDivision.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	DefaultWarehouse = TMCommonUse.GetCheckWarehouseByDefault();
	UseWriteOffForExpenses =
		Object.BusinessOperation <> Enums.BusinessTransactions.TollManufacturing2_5
		And (GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities")
			Or GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	UseAccountingOfOtherAssetsAndLiabilities = GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities");
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
		Or False Then
		PurposeOfTollRelease = Documents.ProductionStage2_2.DefaultAssignmentForByProducts(Object.ReferenceOrder);
	EndIf;
	
	ReadAutoSelectionParameters();
	
	ColorSelectedLink = StyleColors.FormTextColor;
	ColorNotSelectedLink = StyleColors.HyperlinkColor;
	
	// Setting up an action based on parameters
	If Object.Action = Actions().Reduce Then
		QuantityOfBatches = 1;
		AddBatch(0);
		Object.Lots[0].LotNumberOfPackages = Parameters.NumberOfPackages;
		Object.Lots[0].PackageOfLot = Parameters.Package;
		Object.Lots[0].LotQuantity = CalculateNumberOfBatchUnits(
			Object.MainProductProducts,
			Parameters.Package,
			Parameters.NumberOfPackages);
		OneAction = True;
		Title = StrTemplate(NStr("vi = 'Rút gọn lô hàng %1';
								|ru = 'Сокращение партии %1';
								|en = 'Reduce the %1 lot'; fa = 'Reduce the %1 lot';
								|it = 'Сокращение партии %1';
								|pl = 'Reduce the %1 lot';
								|tr = '%1 lotunun azaltılması'"), PartyPresentation);
	ElsIf Object.Action = Actions().Cancel Then
		OneAction = True;
		Title = StrTemplate(NStr("vi = 'Hủy bỏ lô %1';
								|ru = 'Отмена партии %1';
								|en = 'Cancel the %1 lot'; fa = 'Cancel the %1 lot';
								|it = 'Отмена партии %1';
								|pl = 'Cancel the %1 lot';
								|tr = '%1 lotunun iptali'"), PartyPresentation);
	ElsIf Object.Action = Actions().DefectiveGoods Then
		OneAction = True;
		Title = StrTemplate(NStr("vi = 'Phản ánh hàng hỏng trong lô %1';
								|ru = 'Отражение брака в партии %1';
								|en = 'Record nonconformity in the %1 lot'; fa = 'Record nonconformity in the %1 lot';
								|it = 'Отражение брака в партии %1';
								|pl = 'Record nonconformity in the %1 lot';
								|tr = '%1 lotta uygunsuzluk yansıması'"), PartyPresentation);
	Else
		If Parameters.Split Then
			OneAction = True;
			Title = StrTemplate(NStr("vi = 'Phân chia lô %1';
									|ru = 'Деление партии %1';
									|en = 'Divide the %1 lot'; fa = 'Divide the %1 lot';
									|it = 'Деление партии %1';
									|pl = 'Divide the %1 lot';
									|tr = '%1 lotunun bölünmesi'"), PartyPresentation);
		Else
			Title = StrTemplate(NStr("vi = 'Thay đổi lô %1';
									|ru = 'Изменение партии %1';
									|en = 'Lot change %1'; fa = 'Lot change %1';
									|it = 'Modifica del lotto %1';
									|pl = 'Zmiana partii %1';
									|tr = '%1 lotunun değişimi'"), PartyPresentation);
		EndIf;
		
		If ReleaseOfFinishedproducts.Count() > 0 Then
			QuantityOfBatches = ReleaseOfFinishedproducts.Count();
			TheNumberOfPartiesToShare = ReleaseOfFinishedproducts.Count();
		Else
			QuantityOfBatches = 2;
			TheNumberOfPartiesToShare = 2;
		EndIf;
	EndIf;
	
	Items.GroupActions.Visible = Not OneAction;
	Items.SimpleModeNumberOfPackagingUnitsNonconformity.Visible = OneAction;
	Items.ItemPackagePresentation2.Visible = OneAction;
	
	// Number of parties
	If QuantityOfBatches = 0 Then
		QuantityOfBatches = 1;
	EndIf;
	If TheNumberOfPartiesToShare = 0 Then
		TheNumberOfPartiesToShare = 2;
	EndIf;
	
	CurrentBatch = 0;
	PreviousBatch = PartyIndexes().Undefined;
	
	// share of cost, % less than 0.01 (Presentation)
	ShareOfCostIsLessThanPercentPresentation = NStr("vi = '<0,01%';
													|ru = '<0,01%';
													|en = '<0,01%'; fa = '<0,01%';
													|it = '<0,01%';
													|pl = '<0,01%';
													|tr = '<0,01%'");
	
	// Mode
	SimpleMode = Settings.EasyModeWhenOpening;
	SimpleFormMode = ?(SimpleMode, 1, 0);
	
	// Configuring elements
	Items.Lot100.Hyperlink = True;
	Items.Lot100.TextColor = ColorNotSelectedLink;
	Items.LotBalance.Hyperlink = True;
	Items.LotBalance.TextColor = ColorNotSelectedLink;
	Items.GroupSimpleModeNonconformityCancelFinishedProductInOrder.Visible = ThisIsFinishedProductOfOrder;
	Items.GroupSimpleModeCancelFinishedProductInOrder.Visible = ThisIsFinishedProductOfOrder;
	
	SetUpLotReferences();
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	WhenYouStartEditingBatch();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "CommonForm.EnterCostShare" Then
		
		ProcessingInputOfFractionOfCost(Items.Lots.CurrentData, ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	CheckedAttributes.Clear();
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
		Common.MessageToUser(
			NStr("vi = 'Thao tác không thể được thực hiện cho một đơn đặt hàng với loại quy trình sản xuất ""Không có bảng kê chi tiết các nguồn lực sản xuất""';
				|ru = 'Действие не может быть выполнено для заказа с типом производственного процесса ""Без спецификаций""';
				|en = 'The action cannot be executed for an order with ""No BOM"" type of production process.'; fa = 'The action cannot be executed for an order with ""No BOM"" type of production process.';
				|it = 'L''azione non può essere eseguita per l''ordine con il tipo di processo produttivo ""Senza specifiche""';
				|pl = 'Działanie nie może być wypełnione dla zamówienia o typie procesu produkcyjnego ""Bez specyfikacji""';
				|tr = '""Ürün Reçetesiz"" üretim süreci türü olan sipariş için eylem gerçekleştirilemez'"),,,,
			Cancel);
		Return;
	EndIf;
	
	Actions = Actions();
	
	// Header verification
	If Object.Stage.IsEmpty() Then
		MessageText = CommonClientServer.FillingErrorText(
			"Field", "FillType", NStr("vi = 'Công đoạn';
										|ru = 'Этап';
										|en = 'Stage'; fa = 'مرحله';
										|it = 'Этап';
										|pl = 'Stage';
										|tr = 'Aşama'"));
		Common.MessageToUser(MessageText,,, "StagePresentation", Cancel);
	EndIf;
	
	If Object.Action = Actions.Reduce Then
		If Not Object.Stage.IsEmpty()
			And OperationsOfStageHaveBegun() Then
			MessageText = NStr("vi = 'Việc thực hiện các công đoạn đã được bắt đầu.
				|Khuyến nghị chia lô và sau đó thay đổi kích thước của lô mới.';
				|ru = 'Выполнение операций этапа начато.
				|Рекомендуется разделить партию и после изменить размер новой партии.';
				|en = 'Stage operation execution is started.
				|It is recommended that you split the lot and then change the size of the new lot.'; fa = 'Stage operation execution is started.
				|It is recommended that you split the lot and then change the size of the new lot.';
				|it = 'Stage operation execution is started.
				|It is recommended that you split the lot and then change the size of the new lot.';
				|pl = 'Stage operation execution is started.
				|It is recommended that you split the lot and then change the size of the new lot.';
				|tr = 'Etap işlemlerinin uygulanması başlatıldı.
				| Lotun bölünmesi ve sonrasında yeni lotun boyutunun değiştirilmesi önerilir.'");
			Common.MessageToUser(MessageText,,, "StagePresentation", Cancel);
		ElsIf OfOperationSelected(Object)
			And Not Object.ThisIsFirstOperation Then
			MessageText = NStr("vi = 'Có thể rút gọn (tăng) lô chỉ với giao dịch đầu tiên.';
								|ru = 'Сократить (увеличить) партию можно только с первой операции.';
								|en = 'You can reduce or increase the lot only from the first operation.'; fa = 'You can reduce or increase the lot only from the first operation.';
								|it = 'Сократить (увеличить) партию можно только с первой операции.';
								|pl = 'You can reduce or increase the lot only from the first operation.';
								|tr = 'Lot sadece ilk işlemden itibaren azaltılabilir (artırılabilir).'");
			Common.MessageToUser(MessageText,,, "StagePresentation", Cancel);
		EndIf;
	EndIf;
	
	If Object.Action = Actions.DefectiveGoods
		And Object.NumberOfPackagingUnitsNonconformity = 0 Then
		MessageText = CommonClientServer.FillingErrorText(
			"Field", "FillType", NStr("vi = 'Số lượng sản phẩm bị lỗi';
										|ru = 'Количество бракованных изделий';
										|en = 'Number of nonconforming products'; fa = 'تعداد محصولات نامنطبق';
										|it = 'Количество бракованных изделий';
										|pl = 'Number of nonconforming products';
										|tr = 'Uygunsuz ürün sayısı'"));
		Common.MessageToUser(MessageText,, "Object.NumberOfPackagingUnitsNonconformity",, Cancel);
	EndIf;
	
	If Object.FromBeginningOfParty And Object.Action = Actions.Continue Then
		MessageText = NStr("vi = 'Không thể tạo xuất xưởng từ đầu lô hàng.';
							|ru = 'Нельзя оформить выпуск с начала партии.';
							|en = 'You cannot register the release from the beginning of the lot.'; fa = 'You cannot register the release from the beginning of the lot.';
							|it = 'Нельзя оформить выпуск с начала партии.';
							|pl = 'You cannot register the release from the beginning of the lot.';
							|tr = 'Lot başlangıcından itibaren ürün çıkışı düzenlenemez.'");
		Common.MessageToUser(MessageText,,, "StagePresentation", Cancel);
	EndIf;
	
	If Object.FromBeginningOfParty And Object.Action = Actions.DefectiveGoods Then
		MessageText = NStr("vi = 'Không nên phản ánh hàng hỏng từ đầu lô.';
							|ru = 'Нельзя отразить брак с начала партии.';
							|en = 'You cannot record nonconformity from the beginning of the lot.'; fa = 'You cannot record nonconformity from the beginning of the lot.';
							|it = 'Нельзя отразить брак с начала партии.';
							|pl = 'You cannot record nonconformity from the beginning of the lot.';
							|tr = 'Lot başlangıcından itibaren uygunsuzluk yansıtılamaz.'");
		Common.MessageToUser(MessageText,,, "StagePresentation", Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	// Checking Simple Mode Attributes
	If SimpleMode Then
		
		If Object.Action = Actions.Split Then
			
			If SimpleModeNumberOfPackagingunits = 0 Then
				MessageText = CommonClientServer.FillingErrorText(
					"Field", "FillType", NStr("vi = 'Kích thước lô hàng';
												|ru = 'Размер партии';
												|en = 'Lot size'; fa = 'اندازه لات';
												|it = 'Dimensione del lotto';
												|pl = 'Rozmiar partii';
												|tr = 'Lot büyüklüğü'"));
				Common.MessageToUser(MessageText,,, "SimpleModeNumberOfPackagingunits", Cancel);
			EndIf;
			
			If Not Object.FromBeginningOfParty
				And SimpleModeReleaseDirection = Enums.BusinessTransactions.ProductsReleaseToWarehouse
				And Not ValueIsFilled(SimpleRecipientMode) Then
				MessageText = CommonClientServer.FillingErrorText(
					"Field", "FillType", NStr("vi = 'Người nhận';
												|ru = 'Получатель';
												|en = 'Recipient'; fa = 'گیرنده';
												|it = 'Получатель';
												|pl = 'Recipient';
												|tr = 'Alıcı'"));
				Common.MessageToUser(MessageText,,, "SimpleRecipientMode", Cancel);
			EndIf;
			
		ElsIf Object.Action = Actions.DefectiveGoods
			Or Object.Action = Actions.Cancel And Not Object.FromBeginningOfParty Then
			
			If SimpleModeReleaseDirection = Enums.BusinessTransactions.ProductsReleaseToWarehouse
				And Not ValueIsFilled(SimpleRecipientMode) Then
				MessageText = CommonClientServer.FillingErrorText(
					"Field", "FillType", NStr("vi = 'Người nhận';
												|ru = 'Получатель';
												|en = 'Recipient'; fa = 'گیرنده';
												|it = 'Получатель';
												|pl = 'Recipient';
												|tr = 'Alıcı'"));
				Common.MessageToUser(MessageText,,, "SimpleRecipientMode", Cancel);
			EndIf;
			
			If SimpleModeReleaseDirection = Enums.BusinessTransactions.GoodsConsumptionOnDemand
				And Not ValueIsFilled(Object.Lots[0].ExpenseItem) Then
				MessageText = CommonClientServer.FillingErrorText(
					"Field", "FillType", NStr("vi = 'Dạng chi phí';
												|ru = 'Статья расходов';
												|en = 'Expense item'; fa = 'قلم هزینه';
												|it = 'Voce di spese';
												|pl = 'Rodzaj kosztu';
												|tr = 'Gider kalemi'"));
				Common.MessageToUser(MessageText,, "Items.Lots.CurrentData.ExpenseItem",, Cancel);
			EndIf;
			
		ElsIf Object.Action = Actions.Reduce Then
			
			If SimpleModeNumberOfPackagingunits = 0 Then
				MessageText = CommonClientServer.FillingErrorText(
					"Field", "FillType", NStr("vi = 'Kích thước lô hàng';
												|ru = 'Размер партии';
												|en = 'Lot size'; fa = 'اندازه لات';
												|it = 'Dimensione del lotto';
												|pl = 'Rozmiar partii';
												|tr = 'Lot büyüklüğü'"));
				Common.MessageToUser(MessageText,,, "SimpleModeNumberOfPackagingunits", Cancel);
			EndIf;
			
		EndIf;
		
		If Object.Action = Actions.Split
				And SimpleModeReleaseDirection <> DirectionToContinueProcessing()
			Or Object.Action = Actions.DefectiveGoods
			Or Object.Action = Actions.Cancel
			Or Object.Action = Actions.Reduce
				And Object.Lots[0].LotQuantity < Object.Count Then
			
			If EasyModeCancelFinishedProductInOrder
				And SimpleModeReasonForCancellationOfFinishedProduct.IsEmpty() Then
				MessageText = CommonClientServer.FillingErrorText(
					"Field", "FillType", NStr("vi = 'Nguyên nhân hủy bỏ';
												|ru = 'Причина отмены';
												|en = 'Cancellation reason'; fa = 'دلیل لغو';
												|it = 'Causa di annullamento';
												|pl = 'Przyczyna anulowania';
												|tr = 'İptal nedeni'"));
				Common.MessageToUser(MessageText,,, "SimpleModeReasonForCancellationOfFinishedProduct", Cancel);
			EndIf;
			
		EndIf;
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
	// Checking Lot References
	MessagesOfLotReference = New Array; // Index - Index Of The Lot Reference, Value - list of values with errors for this Lot Reference
	MessagesTable = New ValueList;
		
	ListName = NStr("vi = 'Lô hàng';
					|ru = 'Партии';
					|en = 'Lots'; fa = 'لات‌ها';
					|it = 'Lotti';
					|pl = 'Partie';
					|tr = 'Lotlar'");
	StatusesSeriesNotSpecified = ProductsClientServer.SeriesStatusesSeriesNotSpecified();
	
	ItemsTypes = New Map;
	If WorkPlanning Then
		ItemsTypes = Common.ObjectsAttributeValue(
			Object.Lots.Unload().UnloadColumn("Products"), "ItemsType");
	EndIf;
	
	For IndexOf = 0 To Object.Lots.Count()-1 Do
		
		String = Object.Lots[IndexOf];
		MessagesHeader = New ValueList;
		
		ThereIsRelease = Object.Action <> Actions.Reduce
			And Not Object.FromBeginningOfParty;
		
		// Products
		If String.Products.IsEmpty()
			And ThereIsRelease Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "ItemsForm"),
				CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Mặt hàng';
												|ru = 'Номенклатура';
												|en = 'Items'; fa = 'اقلام';
												|it = 'Articolo';
												|pl = 'Produkt';
												|tr = 'Öğe'"), String.LineNumber, ListName));
			
			MessagesHeader.Add(
				"Items.Lots.CurrentData.ItemsForm",
				CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Mặt hàng';
																				|ru = 'Номенклатура';
																				|en = 'Items'; fa = 'اقلام';
																				|it = 'Articolo';
																				|pl = 'Produkt';
																				|tr = 'Öğe'")));
			
		EndIf;
		
		If WorkPlanning
			And String.ContinueProcessing
			And Not String.Products.IsEmpty()
			And ItemsTypes[String.Products] <> Enums.ItemsTypes.Work_5 Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "ItemsForm"),
				StrTemplate(
					NStr("vi = 'Đối với công đoạn lập kế hoạch công việc, cần chỉ định mặt hàng kiểu ""Công việc"" trong dòng %1 của danh sách ""%2""';
						|ru = 'Для этапа планирования работ необходимо указать номенклатуру типа ""Работа"" в строке %1 списка ""%2""';
						|en = 'For the work planning stage, specify the item of the ""Work"" type in line %1 of the ""%2"" list'; fa = 'For the work planning stage, specify the item of the ""Work"" type in line %1 of the ""%2"" list';
						|it = 'For the work planning stage, specify the item of the ""Work"" type in line %1 of the ""%2"" list';
						|pl = 'For the work planning stage, specify the item of the ""Work"" type in line %1 of the ""%2"" list';
						|tr = 'İş planlama aşaması için, ""%2"" listesinin %1 . satırında “İş” türünün adlandırmasının belirtilmesi gerekmektedir.'"),
					String.LineNumber,
					ListName));
			
			MessagesHeader.Add(
				"Items.Lots.CurrentData.ItemsForm",
				NStr("vi = 'Đối với công đoạn lập kế hoạch công việc, cần chỉ định mặt hàng kiểu ""Công việc""';
					|ru = 'Для этапа планирования работ необходимо указать номенклатуру типа ""Работа""';
					|en = 'For the work planning stage, specify the item of the ""Work"" type'; fa = 'For the work planning stage, specify the item of the ""Work"" type';
					|it = 'For the work planning stage, specify the item of the ""Work"" type';
					|pl = 'For the work planning stage, specify the item of the ""Work"" type';
					|tr = 'İş planlama aşaması için ""İş"" türünün belirtilmesi gerekmektedir.'"));
			
		EndIf;
		
		// Characteristic
		If String.Characteristic.IsEmpty()
			And String.ItemVariantsAreUsed
			And ThereIsRelease Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "CharacteristicForm"),
				CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Đặc tính';
												|ru = 'Характеристика';
												|en = 'Variant'; fa = 'گونه';
												|it = 'Caratteristica';
												|pl = 'Charakterystyka';
												|tr = 'Varyant'"), String.LineNumber, ListName));
				
			MessagesHeader.Add(
				"Items.Lots.CurrentData.CharacteristicForm",
				CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Đặc tính';
																				|ru = 'Характеристика';
																				|en = 'Variant'; fa = 'گونه';
																				|it = 'Caratteristica';
																				|pl = 'Charakterystyka';
																				|tr = 'Varyant'")));
				
		EndIf;
		
		// SetOfSeries
		If StatusesSeriesNotSpecified.Find(String.BatchesIndicationStatus) <> Undefined
			And ThereIsRelease Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "Series"),
				CommonClientServer.FillingErrorText(
					"Column", "Correctness", NStr("vi = 'Seri';
													|ru = 'Серия';
													|en = 'Batch'; fa = 'بچ';
													|it = 'Serie';
													|pl = 'Seria';
													|tr = 'Parti'"), String.LineNumber, ListName));
			MessagesHeader.Add(
				"Items.Lots.CurrentData.Series",
				CommonClientServer.FillingErrorText("Field", "Correctness", NStr("vi = 'Seri';
																				|ru = 'Серия';
																				|en = 'Batch'; fa = 'بچ';
																				|it = 'Serie';
																				|pl = 'Seria';
																				|tr = 'Parti'")));
			
		EndIf;
		
		// Number of packages
		If String.NumberOfPackages = 0
			And Not String.AutomaticCalculationOfQuantity
			And ThereIsRelease Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "NumberOfPackages"),
				CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Số lượng';
												|ru = 'Количество';
												|en = 'Quantity'; fa = 'مقدار';
												|it = 'Quantità';
												|pl = 'Ilość';
												|tr = 'Miktar'"), String.LineNumber, ListName));
				
			MessagesHeader.Add(
				"Items.Lots.CurrentData.NumberOfPackages",
				CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Số lượng';
																				|ru = 'Количество';
																				|en = 'Quantity'; fa = 'مقدار';
																				|it = 'Quantità';
																				|pl = 'Ilość';
																				|tr = 'Miktar'")));
			
		EndIf;
		
		// Count
		If String.Count = 0
			And String.NumberOfPackages <> 0
			And ThereIsRelease Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "NumberOfPackages"),
				 StrTemplate(
				 	NStr("vi = 'Tìm thấy số lượng bằng 0 khi kiểm đếm theo đơn vị cất giữ tại dòng %1 của danh sách ""%2""';
							|ru = 'Обнаружено нулевое количество при пересчете в единицу хранения в строке %1 списка ""%2""';
							|en = 'Zero quantity detected when converted to storage unit in the line%1 of the list ""%2""'; fa = 'Zero quantity detected when converted to storage unit in the line%1 of the list ""%2""';
							|it = 'È stata rilevata la quantità pari a zero nel corso di ricalcolo in unità di stoccaggio nella riga %1 dell''elenco ""%2""';
							|pl = 'Wykryto zerową ilość podczas ponownego przeliczenia do jednostki przechowania w wierszu %1 listy ""%2""';
							|tr = '""%2"" listesinin %1 satırında stok ölçü birimine dönüştürülürken sıfır miktar bulundu'"),
					String.LineNumber,
					ListName));
			
			MessagesHeader.Add(
				"Items.Lots.CurrentData.NumberOfPackages",
				NStr("vi = 'Tìm thấy số lượng bằng 0 khi tính lại theo đơn vị lưu kho';
					|ru = 'Обнаружено нулевое количество при пересчете в единицу хранения';
					|en = 'Zero quantity is detected when converted to storage unit'; fa = 'Zero quantity is detected when converted to storage unit';
					|it = 'Durante il calcolo in unità di memoria si è rilevato un importo zero';
					|pl = 'Ujawniona jest zerowa ilość podczas przeliczenia do jednostki przechowywania';
					|tr = 'Stok ölçü birimine dönüştürülürken sıfır miktar bulundu'"));
			
		EndIf;
		
		// A fraction of the cost
		If String.CostShare = 0
			And (Object.Lots.Count() > 1 And Not Object.FromBeginningOfParty
				Or Object.Action = Actions.DefectiveGoods And Object.ThisIsLastStageAndOperation) Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "CostShare"),
				CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Tỷ lệ giá trị';
												|ru = 'Доля стоимости';
												|en = 'Cost share'; fa = 'سهم بها';
												|it = 'Quota del costo';
												|pl = 'Udział kosztów';
												|tr = 'Maliyet payı'"), String.LineNumber, ListName));
			
			MessagesHeader.Add(
				"Items.Lots.CurrentData.CostShare",
				CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Tỷ lệ giá trị';
																				|ru = 'Доля стоимости';
																				|en = 'Cost share'; fa = 'سهم بها';
																				|it = 'Quota del costo';
																				|pl = 'Udział kosztów';
																				|tr = 'Maliyet payı'")));
			
		EndIf;
		
		// Recipient
		If Not ValueIsFilled(String.Recipient)
			And Not String.ToExpenseAs
			And ThereIsRelease Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "Recipient"),
				CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Người nhận';
												|ru = 'Получатель';
												|en = 'Recipient'; fa = 'گیرنده';
												|it = 'Destinatario';
												|pl = 'Recipient';
												|tr = 'Alıcı'"), String.LineNumber, ListName));
			
			MessagesHeader.Add(
				"Items.Lots.CurrentData.Recipient",
				CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Người nhận';
																				|ru = 'Получатель';
																				|en = 'Recipient'; fa = 'گیرنده';
																				|it = 'Destinatario';
																				|pl = 'Recipient';
																				|tr = 'Alıcı'")));
			
		EndIf;
		
		// item of expenditure
		If Not ValueIsFilled(String.ExpenseItem)
			And String.ToExpenseAs
			And ThereIsRelease Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "ExpenseItem"),
				CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Dạng chi phí';
												|ru = 'Статья расходов';
												|en = 'Expense item'; fa = 'قلم هزینه';
												|it = 'Voce di spese';
												|pl = 'Rodzaj kosztu';
												|tr = 'Gider kalemi'"), String.LineNumber, ListName));
			
			MessagesHeader.Add(
				"Items.Lots.CurrentData.ExpenseItem",
				CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Dạng chi phí';
																				|ru = 'Статья расходов';
																				|en = 'Expense item'; fa = 'قلم هزینه';
																				|it = 'Voce di spese';
																				|pl = 'Rodzaj kosztu';
																				|tr = 'Gider kalemi'")));
			
		EndIf;
		
		// Batch size (number of packages)
		If String.LotNumberOfPackages = 0
			And 	(
				Object.Action = Actions.Reduce
				Or (
					Object.Action = Actions.Split
					And 	(
						Object.FromBeginningOfParty
						Or String.ContinueProcessing
						)
					)
				) Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "LotNumberOfPackages"),
				CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Kích thước lô';
												|ru = 'Размер партии';
												|en = 'Lot size'; fa = 'اندازه لات';
												|it = 'Dimensione del lotto';
												|pl = 'Rozmiar partii';
												|tr = 'Lot büyüklüğü'"), String.LineNumber, ListName));
			
			MessagesHeader.Add(
				"Items.Lots.CurrentData.LotNumberOfPackages",
				CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Kích thước lô';
																				|ru = 'Размер партии';
																				|en = 'Lot size'; fa = 'اندازه لات';
																				|it = 'Dimensione del lotto';
																				|pl = 'Rozmiar partii';
																				|tr = 'Lot büyüklüğü'")));
			
		EndIf;
		
		// Batch Size (quantity)
		If String.LotQuantity = 0
			And String.LotNumberOfPackages <> 0
			And (Object.Action = Actions.Reduce
				Or Object.Action = Actions.Split) Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "LotNumberOfPackages"),
				 StrTemplate(
				 	NStr("vi = 'Tìm thấy số lượng bằng 0 khi kiểm đếm theo đơn vị cất giữ tại dòng %1 của danh sách ""%2""';
							|ru = 'Обнаружено нулевое количество при пересчете в единицу хранения в строке %1 списка ""%2""';
							|en = 'Zero quantity detected when converted to storage unit in the line%1 of the list ""%2""'; fa = 'Zero quantity detected when converted to storage unit in the line%1 of the list ""%2""';
							|it = 'È stata rilevata la quantità pari a zero nel corso di ricalcolo in unità di stoccaggio nella riga %1 dell''elenco ""%2""';
							|pl = 'Wykryto zerową ilość podczas ponownego przeliczenia do jednostki przechowania w wierszu %1 listy ""%2""';
							|tr = '""%2"" listesinin %1 satırında stok ölçü birimine dönüştürülürken sıfır miktar bulundu'"),
					String.LineNumber,
					ListName));
			
			MessagesHeader.Add(
				"Items.Lots.CurrentData.LotNumberOfPackages",
				NStr("vi = 'Tìm thấy số lượng bằng 0 khi tính lại theo đơn vị lưu kho';
					|ru = 'Обнаружено нулевое количество при пересчете в единицу хранения';
					|en = 'Zero quantity is detected when converted to storage unit'; fa = 'Zero quantity is detected when converted to storage unit';
					|it = 'Durante il calcolo in unità di memoria si è rilevato un importo zero';
					|pl = 'Ujawniona jest zerowa ilość podczas przeliczenia do jednostki przechowywania';
					|tr = 'Stok ölçü birimine dönüştürülürken sıfır miktar bulundu'"));
			
		EndIf;
		
		If String.ContinueProcessing
			And (Object.Action = Actions.Split And Not Object.FromBeginningOfParty
				Or Object.Action = Actions.DefectiveGoods
				Or Object.Action = Actions.Continue) Then
			
			// New Product
			If String.ChangeProductToBeReleased
				And String.ContinueItem.IsEmpty() Then
				
				MessagesTable.Add(
					CommonClientServer.PathToTabularSection(
						"Object.Lots", String.LineNumber, "LotsTheDirectionOfTheReleaseForm"),
					CommonClientServer.FillingErrorText(
						"Column", "FillType", NStr("vi = 'Sản phẩm mới';
													|ru = 'Новое изделие';
													|en = 'New finished product'; fa = 'محصول ساخته‌شده جدید';
													|it = 'Новое изделие';
													|pl = 'New finished product';
													|tr = 'Yeni nihai ürün'"), String.LineNumber, ListName));
				
				MessagesHeader.Add(
					"Items.Lots.CurrentData.ContinueItem",
					CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Sản phẩm mới';
																					|ru = 'Новое изделие';
																					|en = 'New finished product'; fa = 'محصول ساخته‌شده جدید';
																					|it = 'Новое изделие';
																					|pl = 'New finished product';
																					|tr = 'Yeni nihai ürün'")));
				
			EndIf;
			
			If String.ChangeProductToBeReleased
				And String.ContinueVariant.IsEmpty()
				And String.ContinueCharacteristicsAreUsed Then
				
				MessagesTable.Add(
					CommonClientServer.PathToTabularSection(
						"Object.Lots", String.LineNumber, "LotsTheDirectionOfTheReleaseForm"),
					CommonClientServer.FillingErrorText(
						"Column", "FillType", NStr("vi = 'Đặc tính sản phẩm mới';
													|ru = 'Характеристика нового изделия';
													|en = 'Finished product variant'; fa = 'Finished product variant';
													|it = 'Характеристика нового изделия';
													|pl = 'Finished product variant';
													|tr = 'Yeni nihai ürün varyantı'"), String.LineNumber, ListName));
				
				MessagesHeader.Add(
					"Items.Lots.CurrentData.ContinueVariant",
					CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Đặc tính sản phẩm mới';
																					|ru = 'Характеристика нового изделия';
																					|en = 'Finished product variant'; fa = 'Finished product variant';
																					|it = 'Характеристика нового изделия';
																					|pl = 'Finished product variant';
																					|tr = 'Yeni nihai ürün varyantı'")));
				
			EndIf;
			
			// Continue - Specification
			If String.ContinueBOM.IsEmpty() Then
				
				MessagesTable.Add(
					CommonClientServer.PathToTabularSection(
						"Object.Lots", String.LineNumber, "ContinueBOM"),
					CommonClientServer.FillingErrorText(
						"Column", "FillType", NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
													|ru = 'Спецификация';
													|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
													|it = 'Specifica';
													|pl = 'Specafikacja';
													|tr = 'Ürün reçetesi'"), String.LineNumber, ListName));
				
				MessagesHeader.Add(
					"Items.Lots.CurrentData.ContinueBOM",
					CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
																					|ru = 'Спецификация';
																					|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
																					|it = 'Specifica';
																					|pl = 'Specafikacja';
																					|tr = 'Ürün reçetesi'")));
				
			EndIf;
			
			// Continue - stage
			If String.ContinueStage.IsEmpty() Then
				
				MessagesTable.Add(
					CommonClientServer.PathToTabularSection(
						"Object.Lots", String.LineNumber, "ContinueStagePresentation"),
					CommonClientServer.FillingErrorText(
						"Column", "FillType", NStr("vi = 'Công đoạn';
													|ru = 'Этап';
													|en = 'Stage'; fa = 'مرحله';
													|it = 'Fase';
													|pl = 'Etap';
													|tr = 'Aşama'"), String.LineNumber, ListName));
				
				MessagesHeader.Add(
					"Items.Lots.CurrentData.ContinueStagePresentation",
					CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Công đoạn';
																					|ru = 'Этап';
																					|en = 'Stage'; fa = 'مرحله';
																					|it = 'Fase';
																					|pl = 'Etap';
																					|tr = 'Aşama'")));
				
			EndIf;
			
		EndIf;
		
		// Department
		If String.Department.IsEmpty()
			And ThereIsRelease Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "Department"),
				CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Bộ phận';
												|ru = 'Подразделение';
												|en = 'Business unit'; fa = 'Business unit';
												|it = 'Reparto';
												|pl = 'Business unit';
												|tr = 'Departman'"), String.LineNumber, ListName));
			
			MessagesHeader.Add(
				"Items.Lots.CurrentData.Department",
				CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Bộ phận';
																				|ru = 'Подразделение';
																				|en = 'Business unit'; fa = 'Business unit';
																				|it = 'Reparto';
																				|pl = 'Business unit';
																				|tr = 'Departman'")));
			
		EndIf;
		
		// Party assignments
		If String.SpecifyTargets
			And String.ThereAreErrorsInFillingOutAssignments Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "LotNumberOfPackages"),
				 StrTemplate(
				 	NStr("vi = 'Đã phát hiện chênh lệch giữa kích thước và mục đích của lô hàng tại dòng %1 trong danh sách ""%2""';
							|ru = 'Обнаружено расхождение размера и назначений партии в строке %1 списка ""%2""';
							|en = 'A discrepancy of the size and assignments of the lot is found in the %1 line of the ""%2"" list'; fa = 'A discrepancy of the size and assignments of the lot is found in the %1 line of the ""%2"" list';
							|it = 'Sono state rilevate discrepanze di dimensione e assegnazioni dei lotti nella riga %1 dell''elenco ""%2""';
							|pl = 'Wykryto rozbieżność rozmiaru i przeznaczeń partii w wierszu %1 listy ""%2""';
							|tr = '""%2"" listesinin %1 satırındaki lot boyutu ve atamalarında tutarsızlık tespit edildi'"),
					String.LineNumber,
					ListName));
			
			MessagesHeader.Add(
				"Items.Lots.CurrentData.LotNumberOfPackages",
				NStr("vi = 'Đã phát hiện chênh lệch giữa kích thước và mục đích của lô hàng';
					|ru = 'Обнаружено расхождение размера и назначений партии';
					|en = 'A discrepancy of the size and assignments of the lot is found'; fa = 'A discrepancy of the size and assignments of the lot is found';
					|it = 'È stata rilevata una discrepanza della dimensione e assegnazione dei lotti';
					|pl = 'Wykryto rozbieżność rozmiaru i przeznaczeń partii';
					|tr = 'Lot boyutu ve atamalarında tutarsızlık tespit edildi'"));
			
		EndIf;
		
		// The reason for the cancellation of the finished product in the order
		If YouCanCancelFINISHEDProductInOrder(ThisObject, String)
			And String.CancelChangeFinishedProductInOrder
			And String.ReasonForCancelingFinishedProduct.IsEmpty() Then
			
			MessagesTable.Add(
				CommonClientServer.PathToTabularSection(
					"Object.Lots", String.LineNumber, "LotsTheDirectionOfTheReleaseForm"),
				CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Nguyên nhân hủy bỏ';
												|ru = 'Причина отмены';
												|en = 'Cancellation reason'; fa = 'دلیل لغو';
												|it = 'Causa di annullamento';
												|pl = 'Przyczyna anulowania';
												|tr = 'İptal nedeni'"), String.LineNumber, ListName));
			
			MessagesHeader.Add(
				"Items.Lots.CurrentData.ReasonForCancelingFinishedProduct",
				CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Nguyên nhân hủy bỏ';
																				|ru = 'Причина отмены';
																				|en = 'Cancellation reason'; fa = 'دلیل لغو';
																				|it = 'Causa di annullamento';
																				|pl = 'Przyczyna anulowania';
																				|tr = 'İptal nedeni'")));
			
		EndIf;
		
		MessagesOfLotReference.Insert(IndexOf, MessagesHeader);
		
	EndDo;
	
	If SimpleMode
		And MessagesTable.Count() <> 0 Then
		// Switching to advanced mode
		SimpleMode = False;
		SimpleFormMode = 0;
		ConfigureDependentFormElements(ThisObject);
	EndIf;
	
	If CurrentBatch = PartyIndexes().AllBatches Then
		
		For Each Item In MessagesTable Do
			Common.MessageToUser(Item.Presentation,, Item.Value,, Cancel);
		EndDo;
		
	ElsIf MessagesOfLotReference[CurrentBatch].Count() <> 0 Then
		
		For Each Item In MessagesOfLotReference[CurrentBatch] Do
			Common.MessageToUser(Item.Presentation,, Item.Value,, Cancel);
		EndDo;
		
	Else
		
		For IndexOf = 0 To MessagesOfLotReference.UBound() Do
			
			If MessagesOfLotReference[IndexOf].Count() <> 0 Then
				
				For Each Item In MessagesOfLotReference[IndexOf] Do
					Common.MessageToUser(Item.Presentation,, Item.Value,, Cancel);
				EndDo;
				
				// Page Switching
				PreviousBatch = CurrentBatch;
				CurrentBatch = IndexOf;
				ConfigureDependentFormElements(ThisObject, "CurrentBatch");
				
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TheProductIsTheInscriptionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#ShowProduct" Then
		
		ShowValue(, Object.MainProductProducts);
		
	ElsIf FormattedStringURL = "#ShowProductCharacteristics" Then
		
		ShowValue(, Object.MainProductCharacteristic);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StagePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	ThereAreOperations = False;
	AddressProductionProcessLotReference = ProductionProcessOfLotReferenceInStorage(
		Object.ProductionLot, UUID, ThereAreOperations);
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("AddressInStorage", AddressProductionProcessLotReference);
	
	If OfOperationSelected(Object) Then
		ParametersStructure.Insert("CurrentRef", Object.Operation);
		ParametersStructure.Insert("CurrentOperationId", Object.OperationID);
	Else
		ParametersStructure.Insert("CurrentRef", Object.Stage);
	EndIf;
	
	AdditionalAttributes = New Array;
	
	Attribute = New Structure;
	Attribute.Insert("Name", "DocumentNumber");
	Attribute.Insert("Title", NStr("vi = 'Số';
									|ru = 'Номер';
									|en = 'Number'; fa = 'شماره';
									|it = 'Номер';
									|pl = 'Numer';
									|tr = 'Numara'"));
	Attribute.Insert("Type", New TypeDescription("String",, New StringQualifiers));
	AdditionalAttributes.Add(Attribute);
	
	Attribute = New Structure;
	Attribute.Insert("Name", "Status");
	Attribute.Insert("Title", NStr("vi = 'Trạng thái';
									|ru = 'Статус';
									|en = 'Status'; fa = 'وضعیت';
									|it = 'Статус';
									|pl = 'Status';
									|tr = 'Durum'"));
	Attribute.Insert("Type", New TypeDescription("String",, New StringQualifiers));
	AdditionalAttributes.Add(Attribute);
	
	If ThereAreOperations Then
		Attribute = New Structure;
		Attribute.Insert("Name", "OperationsToDestinationPresentation");
		Attribute.Insert("Title", NStr("vi = 'Đến đích';
										|ru = 'К назначению';
										|en = 'To assign'; fa = 'برای تخصیص';
										|it = 'Da assegnare';
										|pl = 'Do przeznaczenia';
										|tr = 'Atanacak'"));
		Attribute.Insert("Type", New TypeDescription("String",, New StringQualifiers));
		AdditionalAttributes.Add(Attribute);
	EndIf;
	
	ParametersStructure.Insert("AdditionalAttributes", AdditionalAttributes);
	
	OpenForm(
		"Catalog.BillsOfMaterials.Form.ProductionProcessElementChoiceForm",
		ParametersStructure,
		ThisObject,,,,
		New CallbackDescription("StagePresentationSelection", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure StagePresentationSelection(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined Then
		
		Object.Stage = ClosingResult.Stage;
		
		If OfOperationSelected(ClosingResult) Then
			Object.Operation = ClosingResult.Operation;
			Object.OperationID = ClosingResult.OperationID;
			Object.ProductionOperation = ClosingResult.ProductionOperation;
		Else
			Object.Operation = Undefined;
			Object.OperationID = 0;
			Object.ProductionOperation = Undefined;
		EndIf;
		
		StagePresentationSelectionOnServer(CachedValues);
		
		If CurrentBatch <> PartyIndexes().AllBatches Then
			WhenYouStartEditingBatch();
		EndIf;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure StagePresentationSelectionOnServer(CachedValues)
	
	If OfOperationSelected(Object) Then
		Tree = GetFromTempStorage(AddressProductionProcessLotReference);
		LineOperation = Tree.Rows.Find(Object.OperationID, "OperationID", True);
		If LineOperation = Undefined
				Or LineOperation.Parent = Undefined Then
			Object.ThisIsFirstOperation = False;
			Object.ThisIsLastOperation = False;
		Else
			ParentRow = LineOperation.Parent; // ValueTreeRow
			Object.ThisIsFirstOperation = ParentRow.Rows.IndexOf(LineOperation) = 0;
			Object.ThisIsLastOperation = LineOperation.TheNumberOfTheNextOne = 0;
		EndIf;
	Else
		Object.ThisIsFirstOperation = False;
		Object.ThisIsLastOperation = False;
	EndIf;
	
	WhenChangingStage(CachedValues);
	
EndProcedure

&AtClient
Procedure StagePresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Object.Stage = Undefined;
	Object.Operation = Undefined;
	Object.OperationID = 0;
	Object.ProductionOperation = Undefined;
	Object.ThisIsFirstOperation = False;
	Object.ThisIsLastOperation = False;
	
	WhenChangingStage(CachedValues);
	
	If CurrentBatch <> PartyIndexes().AllBatches Then
		WhenYouStartEditingBatch();
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingStage(CachedValues)
	
	AttributesList = "Stage, Operation";
	Data_Stage = Data_Stage(Object, ProductUnitOfMeasurement);
	If Data_Stage <> Undefined Then
		FillInAccordingToStageData(Data_Stage);
		ReadAutoSelectionParameters();
		SetUpLotReferences();
		ConfigureDependentFormElements(ThisObject);
		
		If CurrentBatch <> PartyIndexes().AllBatches Then
			ProductsClientServer.UpdateCachedValuesToAccountForSeries(
				Object.Lots.FindByID(Items.Lots.CurrentRow),
				CachedValues,
				SeriesSpecificationParameters);
		EndIf;
	Else
		ConfigureDependentFormElements(ThisObject, AttributesList);
	EndIf;
	
EndProcedure

&AtClient
Procedure StagePresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not Object.Stage.IsEmpty() Then
		ShowValue(, Object.Stage);
	EndIf;
	
EndProcedure

&AtClient
Procedure ActionToReduceOnChange(Item)
	
	QuantityOfBatches = 1;
	WhenChangingAction();
	
EndProcedure

&AtClient
Procedure TheActionToCancelOnChange(Item)
	
	QuantityOfBatches = 1;
	WhenChangingAction();
	
EndProcedure

&AtClient
Procedure ActionToShareOnChange(Item)
	
	QuantityOfBatches = TheNumberOfPartiesToShare;
	WhenChangingAction();
	
EndProcedure

&AtClient
Procedure ActionToContinueOnChange(Item)
	
	QuantityOfBatches = 1;
	WhenChangingAction();
	
EndProcedure

&AtClient
Procedure ActionNonconformityOnChange(Item)
	
	WhenChangingAction();
	
EndProcedure

&AtClient
Procedure TheNumberOfPartiesToShareOnChange(Item)
	
	QuantityOfBatches = TheNumberOfPartiesToShare;
	WhenChangingAction();
	
EndProcedure

&AtClient
Procedure NumberOfPackagingUnitsNonconformityOnChange(Item)
	
	WhenChangingAction();
	
EndProcedure

&AtClient
Procedure Attachable_HyperlinkLotReferenceSplitClick(Item)
	
	ClearMessages(); // Clearing fill check messages
	
	PreviousBatch = CurrentBatch;
	CurrentBatch = Number(Right(Item.Name, 3));
	
	ConfigureDependentFormElements(ThisObject, "CurrentBatch");
	
	If CurrentBatch <> PartyIndexes().AllBatches Then
		
		WhenYouStartEditingBatch();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HyperlinkNonconformityClick(Item)
	
	ClearMessages(); // Clearing fill check messages
	
	PreviousBatch = CurrentBatch;
	CurrentBatch = 0;
	
	ConfigureDependentFormElements(ThisObject, "CurrentBatch");
	WhenYouStartEditingBatch();
	
EndProcedure

&AtClient
Procedure HyperlinkNonconformityBalanceClick(Item)
	
	ClearMessages(); // Clearing fill check messages
	
	PreviousBatch = CurrentBatch;
	CurrentBatch = 1;
	
	ConfigureDependentFormElements(ThisObject, "CurrentBatch");
	WhenYouStartEditingBatch();
	
EndProcedure

&AtClient
Procedure ItemsFormOpening(Item, StandardProcessing)
	
	CurrentData = Items.Lots.CurrentData;
	
	If CurrentData.AutomaticSelectionOfItems Then
		StandardProcessing = False;
		
		If CurrentData.AutoSelectingItemsIsWork
				Or CurrentData.AutoSelectionOfItemsIsIntermediateFinishedProduct Then
			ShowValue(, CurrentData.Products);
		ElsIf Object.Action = Actions().DefectiveGoods And CurrentData.LineNumber = 1 Then
			// Item - not Suitable
			If AutoSelectionParameters.ItemIsNotSuitable.IsEmpty() Then
				ShowValue(, CurrentData.Products);
			Else
				ShowValue(, AutoSelectionParameters.ItemIsNotSuitable);
			EndIf;
		Else
			// Item - limited use
			If AutoSelectionParameters.Products.IsEmpty() Then
				ShowValue(, CurrentData.Products);
			Else
				ShowValue(, AutoSelectionParameters.Products);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)
	
	// Changing the Attributes in the TS See LotsCharacteristicOnChange
	
	CurrentRow = Items.Lots.CurrentData;
	CurrentRow.Characteristic = CurrentRow.CharacteristicForm;
	
	CalculatePercentageOfCosts = ProductionClient.ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(
		Items.Lots,
		CostAllocationParameters,
		ProcessingOfTabularFormsClientServer.LineCache(Items.Lots, ThisObject));
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Items.Lots, CachedValues, SeriesSpecificationParameters);
	
	CharacteristicWhenChangingOnServer(CalculatePercentageOfCosts, UpdateSeriesStatuses, CachedValues);
	
	If CalculatePercentageOfCosts Then
		ProcessingOfTabularFormsClient.CacheCurLine(Items.Lots, ThisObject);
	EndIf;
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Items.Lots, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure CharacteristicWhenChangingOnServer(CalculatePercentageOfCosts, UpdateSeriesStatuses, CachedValues)
	
	CurrentRow = Object.Lots.FindByID(Items.Lots.CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	AttributesList = "";
	
	If CalculatePercentageOfCosts Then
		CalculatePercentageOfCostAllocationForOutputProducts();
		AttributesList = AttributesList
			+ ?(IsBlankString(AttributesList), "", ",")
			+ "CostSharePercentage";
	EndIf;
	
	If UpdateSeriesStatuses Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			Items.Lots.CurrentRow, CachedValues);
		AttributesList = AttributesList
			+ ?(IsBlankString(AttributesList), "", ",")
			+ "BatchesIndicationStatuses";
	EndIf;
	
	If Not IsBlankString(AttributesList) Then
		ConfigureDependentFormElements(ThisObject, AttributesList);
	EndIf;
	
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
			Items.Lots, CachedValues, SeriesSpecificationParameters) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			Items.Lots.CurrentRow, CachedValues);
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Items.Lots, CachedValues, SeriesSpecificationParameters);
		
		ConfigureDependentFormElements(ThisObject, "BatchesIndicationStatuses");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NumberOfPackagesOnChange(Item)
	
	// Changing the Attributes in the TS See LotsNumberOfPackagesOnChange
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	BatchProcessingOfTablePartClient.ProcessTSString(Items.Lots.CurrentData, StructureOfActions, CachedValues);
	
	CalculatePercentageOfCosts = ProductionClient.ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(
		Items.Lots,
		CostAllocationParameters,
		ProcessingOfTabularFormsClientServer.LineCache(Items.Lots, ThisObject));
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Items.Lots, CachedValues, SeriesSpecificationParameters);
	
	If CalculatePercentageOfCosts Or UpdateSeriesStatuses Then
		
		NumberOfPackagesWhenChangedOnServer(CalculatePercentageOfCosts, UpdateSeriesStatuses, CachedValues);
	
		If CalculatePercentageOfCosts Then
			ProcessingOfTabularFormsClient.CacheCurLine(Items.Lots, ThisObject);
		EndIf;
		
		If UpdateSeriesStatuses Then
			ProductsClient.UpdateCachedValuesToAccountForSeries(
				Items.Lots, CachedValues, SeriesSpecificationParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure NumberOfPackagesWhenChangedOnServer(CalculatePercentageOfCosts, UpdateSeriesStatuses, CachedValues)
	
	AttributesList = "";
	
	If CalculatePercentageOfCosts Then
		CalculatePercentageOfCostAllocationForOutputProducts();
		AttributesList = AttributesList
			+ ?(IsBlankString(AttributesList), "", ",")
			+ "CostSharePercentage";
	EndIf;
	
	If UpdateSeriesStatuses Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			Items.Lots.CurrentRow, CachedValues);
		AttributesList = AttributesList
			+ ?(IsBlankString(AttributesList), "", ",")
			+ "BatchesIndicationStatuses";
	EndIf;
	
	If Not IsBlankString(AttributesList) Then
		ConfigureDependentFormElements(ThisObject, AttributesList);
	EndIf;
	
EndProcedure

&AtClient
Procedure RecipientOnChange(Item)
	
	// Changing the Attributes in the TS See LotsRecipientOnChange
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Items.Lots, CachedValues, SeriesSpecificationParameters);
	
	RecipientWhenModifiedOnServer(Items.Lots.CurrentRow, UpdateSeriesStatuses, CachedValues);
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Items.Lots, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure RecipientWhenModifiedOnServer(IDCurrentRow, UpdateSeriesStatuses, CachedValues)
	
	CurrentData = Object.Lots.FindByID(IDCurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentData.Recipient, SeriesSpecificationParameters));
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If UpdateSeriesStatuses Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			CurrentData.GetID(), CachedValues);
		ConfigureDependentFormElements(ThisObject, "BatchesIndicationStatuses");
	EndIf;
	
EndProcedure

&AtClient
Procedure MethodOfAllocatingFinishedProductCostsOnChange(Item)
	
	WhenChangingMethodOfDistributionOfCostsForOutputProducts();
	
EndProcedure

&AtClient
Procedure CostSharePercentageClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenCostShareEntryForm();
	
EndProcedure

&AtClient
Procedure ShareOfCostIsLessThanPercentPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenCostShareEntryForm();
	
EndProcedure

&AtClient
Procedure ThereAreErrorsOfFillingInCostShareClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenCostShareEntryForm();
	
EndProcedure

&AtClient
Procedure CostShareOnChange(Item)
	
	If ProductionClient.ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(
			Items.Lots,
			CostAllocationParameters,
			ProcessingOfTabularFormsClientServer.LineCache(Items.Lots, ThisObject)) Then
		
		CalculatePercentageOfCostAllocationForOutputProducts();
		ProcessingOfTabularFormsClient.CacheCurLine(Items.Lots, ThisObject);
		ConfigureDependentFormElements(ThisObject, "CostSharePercentage");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TheDirectionOfTheReleaseFormOnChange(Item)
	
	// Changing the Attributes in the TS See LotsTheDirectionOfTheReleaseFormOnChange
	
	ReleaseDirectionFormWhenChangedOnServer(True, CachedValues);
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Lots, ThisObject);
		
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Items.Lots, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure ReleaseDirectionFormWhenChangedOnServer(UpdateRelatedData, CachedValues)
	
	CurrentData = Object.Lots.FindByID(Items.Lots.CurrentRow);
	
	If Not ValueIsFilled(CurrentData.TheDirectionOfTheReleaseForm)
		And Items.TheDirectionOfTheReleaseForm.ChoiceList.Count() <> 0 Then
		CurrentData.TheDirectionOfTheReleaseForm = Items.TheDirectionOfTheReleaseForm.ChoiceList[0].Value;
	EndIf;
	
	AttributesList = "TheDirectionOfTheReleaseForm";
	
	WhenReleaseDirectionChangesForm(CurrentData, AttributesList, CachedValues);
	ConfigureProductsAutoselection(CurrentData, AttributesList, CachedValues);
	
	If UpdateRelatedData Then
		CalculatePercentageOfCostAllocationForOutputProducts();
		AttributesList = AttributesList + ", CostSharePercentage";
	
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			CurrentData.GetID(), CachedValues);
		AttributesList = AttributesList + ", BatchesIndicationStatuses";
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, AttributesList);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.LotsExpenseItem);
	
	ConfigureDependentFormElements(ThisObject, "ExpenseItem");
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("AssetRef",          Items.Lots.CurrentData.ExpenseItem);
	FormParameters.Insert("ChoiceParameters", Item.ChoiceParameters);
	FormParameters.Insert("TypeRestriction", Item.TypeRestriction);
	
	OpenForm("CommonForm.SelectionFormOfItem", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure TransactionRecordingPresentationClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(
		ThisObject,
		Items.LotsTransactionRecordingPresentation,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure LotNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.Lots.CurrentData;
	
	CurrentData.LotQuantity = CalculateNumberOfBatchUnits(
		Object.MainProductProducts,
		CurrentData.PackageOfLot,
		CurrentData.LotNumberOfPackages);
	
	CurrentData.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(CurrentData);
	
	ConfigureDependentFormElements(ThisObject, "LotQuantity");
	
EndProcedure

&AtClient
Procedure PackageOfLotOnChange(Item)
	
	CurrentData = Items.Lots.CurrentData;
	
	CurrentData.LotQuantity = CalculateNumberOfBatchUnits(
		Object.MainProductProducts,
		CurrentData.PackageOfLot,
		CurrentData.LotNumberOfPackages);
	
	CurrentData.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(CurrentData);
	
	ConfigureDependentFormElements(ThisObject, "LotQuantity");
	
EndProcedure

&AtClient
Procedure ContinueBOMOnChange(Item)
	
	CurrentData = Items.Lots.CurrentData;
	
	CurrentData.ContinueStage = Undefined;
	CurrentData.ContinueStagePresentation = "";
	CurrentData.ContinueStageDepartment = Undefined;
	CurrentData.Continue_Operation = Undefined;
	CurrentData.ContinueOperationID = 0;
	
	If CurrentData.ContinueBOM.IsEmpty() Then
		CurrentData.AddressProductionProcess = "";
	ElsIf CurrentData.ContinueBOM = Object.BillOfMaterials Then
		CurrentData.AddressProductionProcess = AddressProductionProcess;
	Else
		CurrentData.AddressProductionProcess = ProductionProcessInWarehouse(
			CurrentData.ContinueBOM, UUID);
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "ContinueBOM");
	
EndProcedure

&AtClient
Procedure ContinueStagePresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Lots.CurrentData;
	CurrentData.ContinueStage = Undefined;
	CurrentData.ContinueStagePresentation = "";
	CurrentData.ContinueStageDepartment = Undefined;
	CurrentData.Continue_Operation = Undefined;
	CurrentData.ContinueOperationID = 0;
	
EndProcedure

&AtClient
Procedure ContinueStagePresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Lots.CurrentData;
	If Not CurrentData.ContinueStage.IsEmpty() Then
		ShowValue(, CurrentData.ContinueStage);
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueStagePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Lots.CurrentData;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("AddressInStorage", CurrentData.AddressProductionProcess);
	
	If CurrentData.Continue_Operation.IsEmpty() Then
		ParametersStructure.Insert("CurrentRef", CurrentData.ContinueStage);
	Else
		ParametersStructure.Insert("CurrentRef", CurrentData.Continue_Operation);
		ParametersStructure.Insert("CurrentOperationId", CurrentData.ContinueOperationID);
	EndIf;
	
	OpenForm(
		"Catalog.BillsOfMaterials.Form.ProductionProcessElementChoiceForm",
		ParametersStructure,
		ThisObject,,,,
		New CallbackDescription("ContinueStagePresentationStartChoiceCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SimpleModeOnChange(Item)
	
	SimpleMode = Boolean(SimpleFormMode);
	
	If SimpleMode Then
		SetUpLotReferences();
	Else
		WhenYouStartEditingBatch();
	EndIf;
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure SimpleModeExtendedTooltipURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	OpenSettings(Undefined);
	
EndProcedure

&AtClient
Procedure SimpleModeNumberOfPackagingunitsIsDividedOnChange(Item)
	
	SimpleModeNumberOfPackagingUnitsIsDividedWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure SimpleModeNumberOfPackagingUnitsIsDividedWhenChangingOnServer()
	
	// Setting Up Lot References
	If ReleaseOfFinishedproducts.Count() > 0 Then
		LastLotReference = Object.Lots[Object.Lots.Count()-1];
		
		LastLotReference.LotNumberOfPackages = SimpleModeNumberOfPackagingunits;
		LastLotReference.LotQuantity = CalculateNumberOfBatchUnits(
			Object.MainProductProducts,
			LastLotReference.PackageOfLot,
			LastLotReference.LotNumberOfPackages);
		
		If Not LastLotReference.AutoSelectingItemsIsWork Then
			LastLotReference.NumberOfPackages = LastLotReference.LotNumberOfPackages;
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
			BatchProcessingOfTablePartServer.ProcessTSString(LastLotReference, StructureOfActions, Undefined);
		EndIf;
		
		LastLotReference.CostShare = LastLotReference.LotNumberOfPackages;
	Else
		FirstLotReference = Object.Lots[0];
		SecondLotReference = Object.Lots[1];
		
		// The First Lot Reference
		FirstLotReference.LotNumberOfPackages = Object.NumberOfPackages - SimpleModeNumberOfPackagingunits;
		FirstLotReference.LotQuantity = CalculateNumberOfBatchUnits(
			Object.MainProductProducts,
			FirstLotReference.PackageOfLot,
			FirstLotReference.LotNumberOfPackages);
		
		If Not FirstLotReference.AutoSelectingItemsIsWork Then
			FirstLotReference.NumberOfPackages = FirstLotReference.LotNumberOfPackages;
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
			BatchProcessingOfTablePartServer.ProcessTSString(FirstLotReference, StructureOfActions, Undefined);
		EndIf;
		
		FirstLotReference.CostShare = FirstLotReference.LotNumberOfPackages;
		
		// Second Lot Reference
		SecondLotReference.LotNumberOfPackages = SimpleModeNumberOfPackagingunits;
		SecondLotReference.LotQuantity = CalculateNumberOfBatchUnits(
			Object.MainProductProducts,
			SecondLotReference.PackageOfLot,
			SecondLotReference.LotNumberOfPackages);
		
		If Not SecondLotReference.AutoSelectingItemsIsWork Then
			SecondLotReference.NumberOfPackages = SecondLotReference.LotNumberOfPackages;
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
			BatchProcessingOfTablePartServer.ProcessTSString(SecondLotReference, StructureOfActions, Undefined);
		EndIf;
		
		SecondLotReference.CostShare = SecondLotReference.LotNumberOfPackages;
	EndIf;
	
	// Official actions
	CalculatePercentageOfCostAllocationForOutputProducts();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure SimpleSplitContinueModeOnChange(Item)
	
	Object.Lots[Object.Lots.Count()-1].TheDirectionOfTheReleaseForm = SimpleModeReleaseDirection;
	SimpleModeSplitDirectionOfReleaseWhenChanging();
	
EndProcedure

&AtClient
Procedure SimpleModeSplitIntoWarehouseOnChange(Item)
	
	Object.Lots[Object.Lots.Count()-1].TheDirectionOfTheReleaseForm = SimpleModeReleaseDirection;
	SimpleModeSplitDirectionOfReleaseWhenChanging();
	
EndProcedure

&AtServer
Procedure SimpleModeSplitDirectionOfReleaseWhenChanging()
	
	LastLotReference = Object.Lots[Object.Lots.Count()-1];
	
	WhenReleaseDirectionChangesForm(LastLotReference, "");
	ConfigureProductsAutoselection(LastLotReference, "");
	
	If Not LastLotReference.ContinueProcessing Then
		LastLotReference.NumberOfPackages = SimpleModeNumberOfPackagingunits;
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
		BatchProcessingOfTablePartServer.ProcessTSString(LastLotReference, StructureOfActions, Undefined);
	EndIf;
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	SimpleRecipientMode = LastLotReference.Recipient;
	Items.SimpleSplitRecipientMode.TypeRestriction = LimitingRecipientType(LastLotReference);
	
	ConfigureDependentFormElements(ThisObject, "SimpleModeSplitReleaseDirection");
	
EndProcedure

&AtClient
Procedure SimpleSplitRecipientModeOnChange(Item)
	
	LastLotReference = Object.Lots[Object.Lots.Count()-1];
	LastLotReference.Recipient = SimpleRecipientMode;
	
	SimpleModeToSplitRecipientWhenChangingOnServer(LastLotReference.GetID());
	
EndProcedure

&AtServer
Procedure SimpleModeToSplitRecipientWhenChangingOnServer(IDCurrentRow)
	
	RecipientWhenModifiedOnServer(IDCurrentRow, False, Undefined);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure SimpleModeNonconformityItemPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not AutoSelectionParameters.ItemIsNotSuitable.IsEmpty() Then
		ShowValue(, AutoSelectionParameters.ItemIsNotSuitable);
	EndIf;
	
EndProcedure

&AtClient
Procedure SimpleModeNumberOfPackagingUnitsNonconformityOnChange(Item)
	
	WhenChangingActionOnServer();
	
EndProcedure

&AtClient
Procedure AdvancedModeNumberOfPackagingUnitsNonconformityOnChange(Item)
	
	WhenChangingAction();
	
EndProcedure

&AtClient
Procedure SimpleModeOfNonconformityToWarehouseOnChange(Item)
	
	Object.Lots[0].TheDirectionOfTheReleaseForm = SimpleModeReleaseDirection;
	SimpleModeNonconformityDirectionOfReleaseWhenChanging();
	
EndProcedure

&AtClient
Procedure SimpleModeNonconformityWriteOffOnChange(Item)
	
	Object.Lots[0].TheDirectionOfTheReleaseForm = SimpleModeReleaseDirection;
	SimpleModeNonconformityDirectionOfReleaseWhenChanging();
	
EndProcedure

&AtServer
Procedure SimpleModeNonconformityDirectionOfReleaseWhenChanging()
	
	FirstLotReference = Object.Lots[0];
	
	WhenReleaseDirectionChangesForm(FirstLotReference, "");
	ConfigureProductsAutoselection(FirstLotReference, "");
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	SimpleRecipientMode = FirstLotReference.Recipient;
	Items.SimpleModeNonconformityRecipient.TypeRestriction = LimitingRecipientType(FirstLotReference);
	
	ConfigureDependentFormElements(ThisObject, "SimpleModeNonconformityDirectionOfRelease");
	
EndProcedure

&AtClient
Procedure SimpleModeNonconformityRecipientOnChange(Item)
	
	FirstLotReference = Object.Lots[0];
	FirstLotReference.Recipient = SimpleRecipientMode;
	
	SimpleModeOfNonconformityOfRecipientWhenChangingOnServer(FirstLotReference.GetID());
	
EndProcedure

&AtServer
Procedure SimpleModeOfNonconformityOfRecipientWhenChangingOnServer(IDCurrentRow)
	
	RecipientWhenModifiedOnServer(IDCurrentRow, False, Undefined);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ConfigureDependentFormElements(ThisObject, "SimpleModeNonconformityRecipient");
	
EndProcedure

&AtClient
Procedure SimpleModeNonconformityExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.LotsExpenseItem);
	ConfigureDependentFormElements(ThisObject, "SimpleModeNonconformityExpenseItem");
	
EndProcedure

&AtClient
Procedure SimpleModeNonconformityExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FirstLotReference = Object.Lots[0];
	
	FormParameters = New Structure;
	FormParameters.Insert("AssetRef",          FirstLotReference.ExpenseItem);
	FormParameters.Insert("ChoiceParameters", Item.ChoiceParameters);
	FormParameters.Insert("TypeRestriction", Item.TypeRestriction);
	
	OpenForm("CommonForm.SelectionFormOfItem", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure SimpleModeCancelItemPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Object.Lots[0].AutoSelectionOfItemsIsIntermediateFinishedProduct Then
		ShowValue(, Object.IntermediateProductItem);
	ElsIf Not AutoSelectionParameters.Products.IsEmpty() Then
		ShowValue(, AutoSelectionParameters.Products);
	EndIf;
	
EndProcedure

&AtClient
Procedure SimpleCancelToWarehouseModeOnChange(Item)
	
	Object.Lots[0].TheDirectionOfTheReleaseForm = SimpleModeReleaseDirection;
	SimpleModeUndoReleaseDirectionWhenChanging();
	
EndProcedure

&AtClient
Procedure EasyModeCancelWriteOffOnChange(Item)
	
	Object.Lots[0].TheDirectionOfTheReleaseForm = SimpleModeReleaseDirection;
	SimpleModeUndoReleaseDirectionWhenChanging();
	
EndProcedure

&AtServer
Procedure SimpleModeUndoReleaseDirectionWhenChanging()
	
	FirstLotReference = Object.Lots[0];
	
	WhenReleaseDirectionChangesForm(FirstLotReference, "");
	ConfigureProductsAutoselection(FirstLotReference, "");
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	SimpleRecipientMode = FirstLotReference.Recipient;
	Items.SimpleModeCancelRecipient.TypeRestriction = LimitingRecipientType(FirstLotReference);
	
	ConfigureDependentFormElements(ThisObject, "SimpleModeUndoReleaseDirection");
	
EndProcedure

&AtClient
Procedure SimpleModeCancelRecipientOnChange(Item)
	
	FirstLotReference = Object.Lots[0];
	FirstLotReference.Recipient = SimpleRecipientMode;
	
	SimpleModeIsToCancelRecipientWhenChangeIsMadeOnServer(FirstLotReference.GetID());
	
EndProcedure

&AtServer
Procedure SimpleModeIsToCancelRecipientWhenChangeIsMadeOnServer(IDCurrentRow)
	
	RecipientWhenModifiedOnServer(IDCurrentRow, False, Undefined);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ConfigureDependentFormElements(ThisObject, "SimpleModeCancelRecipient");
	
EndProcedure

&AtClient
Procedure SimpleModeCancelExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.LotsExpenseItem);
	ConfigureDependentFormElements(ThisObject, "SimpleModeCancelExpenseItem");
	
EndProcedure

&AtClient
Procedure SimpleModeCancelExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FirstLotReference = Object.Lots[0];
	
	FormParameters = New Structure;
	FormParameters.Insert("AssetRef",          FirstLotReference.ExpenseItem);
	FormParameters.Insert("ChoiceParameters", Item.ChoiceParameters);
	FormParameters.Insert("TypeRestriction", Item.TypeRestriction);
	
	OpenForm("CommonForm.SelectionFormOfItem", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure SimpleModeToReduceNumberOfPackagingUnitsOfLotReferenceOnChange(Item)
	
	FirstLotReference = Object.Lots[0];
	
	FirstLotReference.LotNumberOfPackages = SimpleModeNumberOfPackagingunits;
	FirstLotReference.LotQuantity = CalculateNumberOfBatchUnits(
		Object.MainProductProducts,
		FirstLotReference.PackageOfLot,
		FirstLotReference.LotNumberOfPackages);
	
	FirstLotReference.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(FirstLotReference);
	
	ConfigureDependentFormElements(ThisObject, "SimpleModeNumberOfPackagingunits");
	
EndProcedure

&AtClient
Procedure SimpleCutPackagingUnitLotReferenceModeOnChange(Item)
	
	FirstLotReference = Object.Lots[0];
	
	FirstLotReference.PackageOfLot = SimplePackagingUnitMode;
	FirstLotReference.LotQuantity = CalculateNumberOfBatchUnits(
		Object.MainProductProducts,
		FirstLotReference.PackageOfLot,
		FirstLotReference.LotNumberOfPackages);
	
	FirstLotReference.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(FirstLotReference);
	
	ConfigureDependentFormElements(ThisObject, "SimpleModeNumberOfPackagingunits");
	
EndProcedure

&AtClient
Procedure BatchChangeFINISHEDProductOnChange(Item)
	
	CurrentData = Items.Lots.CurrentData;
	
	If CurrentData.ChangeProductToBeReleased Then
		CurrentData.ContinueItem = Undefined;
		CurrentData.ContinueVariant = Undefined;
	Else
		CurrentData.ContinueItem = Object.MainProductProducts;
		CurrentData.ContinueVariant = Object.MainProductCharacteristic;
		CurrentData.CancelChangeFinishedProductInOrder = False;
		CurrentData.ReasonForCancelingFinishedProduct = Undefined;
	EndIf;
	
	CurrentData.ContinueBOM = Undefined;
	CurrentData.ContinueStage = Undefined;
	CurrentData.ContinueStagePresentation = "";
	CurrentData.ContinueStageDepartment = Undefined;
	CurrentData.Continue_Operation = Undefined;
	CurrentData.ContinueOperationID = 0;
	CurrentData.AddressProductionProcess = "";
	
	ConfigureDependentFormElements(ThisObject,
		"ChangeProductToBeReleased,ContinueItem,ContinueBOM,CancelChangeFinishedProductInOrder");
	
EndProcedure

&AtClient
Procedure ContinueItemOnChange(Item)
	
	ContinueItemChangesOnServer();
	
EndProcedure

&AtServer
Procedure ContinueItemChangesOnServer()
	
	CurrentData = Object.Lots.FindByID(Items.Lots.CurrentRow);
	
	LineCopy = New Structure;
	LineCopy.Insert("Products", CurrentData.ContinueItem);
	LineCopy.Insert("Characteristic", CurrentData.ContinueVariant);
	LineCopy.Insert("ContinueBOM", CurrentData.ContinueBOM);
	LineCopy.Insert("ItemVariantsAreUsed", False);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.ContinueVariant);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("PropsNameSpecification", "ContinueBOM");
	
	FillParameters = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Object, CurrentData, BOMSelectionParameters, ThisObject, AdditionalParameters);
	StructureOfActions.Insert("CheckFillSpecification", FillParameters);
	
	BatchProcessingOfTablePartServer.ProcessTSString(LineCopy, StructureOfActions, Undefined);
	
	CurrentData.ContinueVariant = LineCopy.Characteristic;
	CurrentData.ContinueCharacteristicsAreUsed = LineCopy.ItemVariantsAreUsed;
	
	CurrentData.ContinueBOM = LineCopy.ContinueBOM;
	CurrentData.ContinueStage = Undefined;
	CurrentData.ContinueStagePresentation = "";
	CurrentData.ContinueStageDepartment = Undefined;
	CurrentData.Continue_Operation = Undefined;
	CurrentData.ContinueOperationID = 0;
	CurrentData.AddressProductionProcess = ProductionProcessInWarehouse(
		CurrentData.ContinueBOM, UUID);
	
	ConfigureDependentFormElements(ThisObject, "ContinueItem,ContinueBOM");
	
EndProcedure

&AtClient
Procedure CancelChangeFinishedProductInOrderOnChange(Item)
	
	CurrentData = Items.Lots.CurrentData;
	
	If Not CurrentData.CancelChangeFinishedProductInOrder Then
		CurrentData.ReasonForCancelingFinishedProduct = Undefined;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "CancelChangeFinishedProductInOrder");
	
EndProcedure

&AtClient
Procedure SimpleModeSplitCancelFinishedProductInOrderOnChange(Item)
	
	LastLotReference = Object.Lots[Object.Lots.Count()-1];
	
	LastLotReference.CancelChangeFinishedProductInOrder = EasyModeCancelFinishedProductInOrder;
	
	If Not EasyModeCancelFinishedProductInOrder Then
		LastLotReference.ReasonForCancelingFinishedProduct = Undefined;
		SimpleModeReasonForCancellationOfFinishedProduct = Undefined;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "SimpleModeSplitCancelFinishedProductInOrder");
	
EndProcedure

&AtClient
Procedure SimpleModeSplitCancelFinishedProductInOrderHeaderURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(, Object.ReferenceOrder);
	
EndProcedure

&AtClient
Procedure SimpleModeShareReasonForCancellationOfFinishedProductOnChange(Item)
	
	Object.Lots[Object.Lots.Count()-1].ReasonForCancelingFinishedProduct = SimpleModeReasonForCancellationOfFinishedProduct;
	
EndProcedure

&AtClient
Procedure SimpleModeNonconformityCancelFinishedProductInOrderOnChange(Item)
	
	Object.Lots[0].CancelChangeFinishedProductInOrder = EasyModeCancelFinishedProductInOrder;
	
	If Not EasyModeCancelFinishedProductInOrder Then
		Object.Lots[0].ReasonForCancelingFinishedProduct = Undefined;
		SimpleModeReasonForCancellationOfFinishedProduct = Undefined;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "SimpleModeNonconformityCancelFinishedProductInOrder");
	
EndProcedure

&AtClient
Procedure SimpleModeNonconformityReasonForCancellationOfFinishedProductOnChange(Item)
	
	Object.Lots[0].ReasonForCancelingFinishedProduct = SimpleModeReasonForCancellationOfFinishedProduct;
	
EndProcedure

&AtClient
Procedure SimpleModeNonconformityCancelFinishedProductInOrderHeaderURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(, Object.ReferenceOrder);
	
EndProcedure

&AtClient
Procedure EasyModeCancelFinishedProductInOrderOnChange(Item)
	
	Object.Lots[0].CancelChangeFinishedProductInOrder = EasyModeCancelFinishedProductInOrder;
	
	If Not EasyModeCancelFinishedProductInOrder Then
		Object.Lots[0].ReasonForCancelingFinishedProduct = Undefined;
		SimpleModeReasonForCancellationOfFinishedProduct = Undefined;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "EasyModeCancelFinishedProductInOrder");
	
EndProcedure

&AtClient
Procedure SimpleModeReasonForCancellationOfFinishedProductOnChange(Item)
	
	Object.Lots[0].ReasonForCancelingFinishedProduct = SimpleModeReasonForCancellationOfFinishedProduct;
	
EndProcedure

&AtClient
Procedure EasyModeCancelFinishedProductInOrderHeaderURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(, Object.ReferenceOrder);
	
EndProcedure

&AtClient
Procedure SimpleModeReduceCancelFINISHEDProductInOrderOnChange(Item)
	
	Object.Lots[0].CancelChangeFinishedProductInOrder = EasyModeCancelFinishedProductInOrder;
	
	If Not EasyModeCancelFinishedProductInOrder Then
		Object.Lots[0].ReasonForCancelingFinishedProduct = Undefined;
		SimpleModeReasonForCancellationOfFinishedProduct = Undefined;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "SimpleModeReduceCancelFINISHEDProductInOrder");
	
EndProcedure

&AtClient
Procedure SimpleModeReduceReasonForCancellationOfFinishedDProductOnChange(Item)
	
	Object.Lots[0].ReasonForCancelingFinishedProduct = SimpleModeReasonForCancellationOfFinishedProduct;
	
EndProcedure

&AtClient
Procedure SimpleCutModeCancelFinishedProductInOrderHeaderURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(, Object.ReferenceOrder);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLots

&AtClient
Procedure LotsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Lots.CurrentData;
	
	If (Field = Items.LotsSeries 
			Or Field = Items.LotsBatchesIndicationStatus)
		And CurrentData.BatchesIndicationStatus > 0
		And CurrentData.BatchesIndicationStatus <= 11 Then
		
		StandardProcessing = False;
		OpenSelectionOfSeries();
		
	EndIf;
	
	If (Field = Items.LotsCostSharePercentage
			Or Field = Items.LotsThereAreErrorsOfFillingInCostShare)
		And Object.MethodOfAllocatingFinishedProductCosts
			<> PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") Then
		
		StandardProcessing = False;
		OpenCostShareEntryForm();
		
	EndIf;
	
	If Field = Items.LotsAssignmentsPresentation
		And CurrentData.SpecifyTargets Then
		
		StandardProcessing = False;
		OpenAppointmentSelection();
		
	EndIf;
	
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LotsOnStartEdit(Item, NewRow, Copy)
	
	WhenYouStartEditingBatch();
	
	If NewRow And Copy Then
		
		// Setting up accounting accounts.
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LotsOnEditEnd(Item, NewRow, CancelEdit)
	
	AttributesList = "";
	
	If ProductionClient.ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(
			Item,
			CostAllocationParameters,
			ProcessingOfTabularFormsClientServer.LineCache(Items.Lots, ThisObject),
			NewRow) Then
			
		CalculatePercentageOfCostAllocationForOutputProducts();
		
		AttributesList = AttributesList
			+ ?(IsBlankString(AttributesList), "", ",")
			+ "CostSharePercentage";
		
	EndIf;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			Items.Lots.CurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item,CachedValues,SeriesSpecificationParameters);
		
		AttributesList = AttributesList
			+ ?(IsBlankString(AttributesList), "", ",")
			+ "BatchesIndicationStatuses";
		
	EndIf;
	
	If Not IsBlankString(AttributesList) Then
		ConfigureDependentFormElements(ThisObject, AttributesList);
	EndIf;
	
EndProcedure

&AtClient
Procedure LotsProductsOnChange(Item)
	
	CurrentRow = Items.Lots.CurrentData;
	CurrentRow.Products = CurrentRow.ItemsForm;
	
	UpdateRelatedData = (CurrentBatch <> PartyIndexes().AllBatches);
	
	LotReferencesItemFormWhenChangedOnServer(UpdateRelatedData, CachedValues);
	
	If UpdateRelatedData Then
		ProcessingOfTabularFormsClient.CacheCurLine(Items.Lots, ThisObject);
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Items.Lots, CachedValues, SeriesSpecificationParameters);
	EndIf;
	
	FillInSelectionListReleaseDirectionForm();
	
EndProcedure

&AtServer
Procedure LotReferencesItemFormWhenChangedOnServer(UpdateRelatedData, CachedValues)
	
	CurrentData = Object.Lots.FindByID(Items.Lots.CurrentRow);
	AttributesList = "Products";
	
	ConfigureProductsAutoselection(CurrentData, AttributesList, CachedValues);
	
	If Not CurrentData.ItemsForm.IsEmpty() Then
		BatchProductsWhenChangedOnServer(CurrentData, CachedValues);
		
		// Automatic Calculation of Quantity
		SetUpAutomaticQuantityCalculation(CurrentData, AttributesList, CachedValues);
		
		// Direction of release (control)
		ChoiceList = SelectionListReleaseDirectionForm(ThisObject, CurrentData);
		If ChoiceList.FindByValue(CurrentData.TheDirectionOfTheReleaseForm) = Undefined Then
			If CurrentData.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit
				And ChoiceList.FindByValue(Enums.BusinessTransactions.ProductsReleaseToWarehouse) <> Undefined Then
				CurrentData.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToWarehouse;
			ElsIf CurrentData.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToWarehouse
				And ChoiceList.FindByValue(Enums.BusinessTransactions.ProductsReleaseToBusinessUnit) <> Undefined Then
				CurrentData.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit;
			Else
				CurrentData.TheDirectionOfTheReleaseForm = ChoiceList[0].Value;
			EndIf;
			WhenReleaseDirectionChangesForm(CurrentData, AttributesList, CachedValues);
		Else
			If SpecifyRecipientType(CurrentData) Then
				RecipientWhenModifiedOnServer(CurrentData.GetID(), False, CachedValues);
			EndIf;
		EndIf;
	EndIf;
	
	If UpdateRelatedData Then
		CalculatePercentageOfCostAllocationForOutputProducts();
		AttributesList = AttributesList + ", CostSharePercentage";
	
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			CurrentData.GetID(), CachedValues);
		AttributesList = AttributesList + ", BatchesIndicationStatuses";
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, AttributesList);
	
EndProcedure

&AtServer
Procedure BatchProductsWhenChangedOnServer(CurrentData, CachedValues = Undefined)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentData.Package);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInUnitOfMeasurementAttribute", New Structure("Products", "UnitOfMeasure"));
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	StructureOfActions.Insert("CheckFillAssignment", ActionParameterFillInAssignment(CurrentData));
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentData.Recipient, SeriesSpecificationParameters));
	
	ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
		ReceivingBusinessUnit(CurrentData), StructureOfActions, "Recipient");
	
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(
		StructureOfActions, ThisObject, "Object.Lots");
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If Not CurrentData.AutomaticSelectionOfItems Then
		CurrentData.CharacteristicForm = CurrentData.Characteristic;
	EndIf;
	
EndProcedure

&AtClient
Procedure LotsItemsFormOpening(Item, StandardProcessing)
	
	ItemsFormOpening(Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LotsCharacteristicOnChange(Item)
	
	// Changing the props in the header See CharacteristicOnChange
	
	CurrentRow = Items.Lots.CurrentData;
	CurrentRow.Characteristic = CurrentRow.CharacteristicForm;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure LotsNumberOfPackagesOnChange(Item)
	
	// Changing the props in the header See NumberOfPackagesOnChange
	
	CurrentRow = Items.Lots.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure LotsPackageOnChange(Item)
	
	CurrentRow = Items.Lots.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure LotsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.Lots.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Lots.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
	
EndProcedure

&AtClient
Procedure LotsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure LotsRecipientOnChange(Item)
	
	// Changing the props in the header See RecipientOnChange
	
	RecipientWhenModifiedOnServer(Items.Lots.CurrentRow, False, CachedValues);
	
EndProcedure

&AtClient
Procedure LotsTheDirectionOfTheReleaseFormOnChange(Item)
	
	// Changing the props in the header See TheDirectionOfTheReleaseFormOnChange
	
	ReleaseDirectionFormWhenChangedOnServer(False, CachedValues);
	
EndProcedure

&AtClient
Procedure LotsExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	ConfigureDependentFormElements(ThisObject, "ExpenseItem");
	
EndProcedure

&AtClient
Procedure LotsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LotsLotNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.Lots.CurrentData;
	
	CurrentData.LotQuantity = CalculateNumberOfBatchUnits(
		Object.MainProductProducts,
		CurrentData.PackageOfLot,
		CurrentData.LotNumberOfPackages);
	
	CurrentData.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(CurrentData);
	
EndProcedure

&AtClient
Procedure LotsPackageOfLotOnChange(Item)
	
	CurrentData = Items.Lots.CurrentData;
	
	CurrentData.LotQuantity = CalculateNumberOfBatchUnits(
		Object.MainProductProducts,
		CurrentData.PackageOfLot,
		CurrentData.LotNumberOfPackages);
	
	CurrentData.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(CurrentData);
	
EndProcedure

&AtClient
Procedure LotsContinueBOMOnChange(Item)
	
	CurrentData = Items.Lots.CurrentData;
	
	CurrentData.ContinueStage = Undefined;
	CurrentData.ContinueStagePresentation = "";
	CurrentData.ContinueStageDepartment = Undefined;
	CurrentData.Continue_Operation = Undefined;
	CurrentData.ContinueOperationID = 0;
	
	If CurrentData.ContinueBOM.IsEmpty() Then
		CurrentData.AddressProductionProcess = "";
	ElsIf CurrentData.ContinueBOM = Object.BillOfMaterials Then
		CurrentData.AddressProductionProcess = AddressProductionProcess;
	Else
		CurrentData.AddressProductionProcess = ProductionProcessInWarehouse(
			CurrentData.ContinueBOM, UUID);
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "ContinueBOM");
	
EndProcedure

&AtClient
Procedure LotsContinueStagePresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Lots.CurrentData;
	CurrentData.ContinueStage = Undefined;
	CurrentData.ContinueStagePresentation = "";
	CurrentData.ContinueStageDepartment = Undefined;
	CurrentData.Continue_Operation = Undefined;
	CurrentData.ContinueOperationID = 0;
	
EndProcedure

&AtClient
Procedure LotsContinueStagePresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Lots.CurrentData;
	If Not CurrentData.ContinueStage.IsEmpty() Then
		ShowValue(, CurrentData.ContinueStage);
	EndIf;
	
EndProcedure

&AtClient
Procedure LotsContinueStagePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Lots.CurrentData;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("AddressInStorage", CurrentData.AddressProductionProcess);
	
	If CurrentData.Continue_Operation.IsEmpty() Then
		ParametersStructure.Insert("CurrentRef", CurrentData.ContinueStage);
	Else
		ParametersStructure.Insert("CurrentRef", CurrentData.Continue_Operation);
		ParametersStructure.Insert("CurrentOperationId", CurrentData.ContinueOperationID);
	EndIf;
	
	OpenForm(
		"Catalog.BillsOfMaterials.Form.ProductionProcessElementChoiceForm",
		ParametersStructure,
		ThisObject,,,,
		New CallbackDescription("ContinueStagePresentationStartChoiceCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExecutionResult

&AtClient
Procedure ExecutionResultSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ExecutionResult.CurrentData;
	
	If TypeOf(CurrentData.Ref) = Type("DocumentRef.ProductionStage2_2")
		Or TypeOf(CurrentData.Ref) = Type("DocumentRef.InventoryAssignmentAdjustment")
		Or TypeOf(CurrentData.Ref) = Type("DocumentRef.ProductionOrder2_2") Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Ref);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenSettings(Command)
	
	OpenForm("DataProcessor.ProductionLotDivision.Form.Settings",,
		ThisObject,,,,
		New CallbackDescription("OpenSettingsCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenSettingsCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		OnSettingsChange(CachedValues);
		WhenYouStartEditingBatch();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteAction(Command)
	
	ClearMessages();
	
	CurBatchCopy = CurrentBatch;
	SimpleCopyMode = SimpleMode;
	
	StartWaiting = PerformActionInBackground();
	
	// When checking the filling, the page or mode (from simple to advanced) can be switched
	If (CurBatchCopy <> CurrentBatch And CurrentBatch <> PartyIndexes().AllBatches)
		Or SimpleCopyMode <> SimpleMode Then
		WhenYouStartEditingBatch();
	EndIf;
	
	If StartWaiting Then
		
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New CallbackDescription("PerformActionInBackgroundCompletion", ThisObject),
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
			
	ElsIf OperationCompleted Then
		
		Notify("ChangingSequenceOfStages", Object.ProductionLot);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure SpecifyDestinations(Command)
	
	OpenAppointmentSelection();
	
EndProcedure

#EndRegion

#Region Private

#Region ConfiguringElements

&AtServer
Procedure SetConditionalAppearance()
	
	// Setting the layout of table elements placed in the header, See ConfigureDependentFormElements
	
	ConditionalAppearance.Items.Clear();
	
	// Standard design
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "LotsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Lots.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "LotsBatchProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Lots.PackageOfLot";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ExecutionResultBatchProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "ExecutionResult.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(
		ThisObject,
		Items.LotsPurpose.Name,
		"Object.Lots.ItemsType",
		False);
		
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject,
		False,
		"LotsSeries",
		"Object.Lots.BatchesIndicationStatus",
		"Object.Lots.ItemsType");
		
	//
	
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(
		ThisObject,
		False,
		"LotsBatchesIndicationStatus",
		"Object.Lots.BatchesIndicationStatus");
		
	//
	
	ProductionServer.SetConditionalAppearanceOfShareCostPercentageField(
		ThisObject,
		"Object",
		"Lots");
	
	// the purpose is not indicated when writing off expenses
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được sử dụng để khấu trừ chi phí>';
													|ru = '<не используется при списании на расходы>';
													|en = '<not used while writing off as expenses>'; fa = '<not used while writing off as expenses>';
													|it = '<non viene usato durante storno sulle spese>';
													|pl = '<nie używane podczas rozchodu na wydatki>';
													|tr = '<giderlere yazılırken kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// The destination is not specified when processing continues
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.ContinueProcessing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được sử dụng để tiếp tục xử lý>';
													|ru = '<не используется при продолжении обработки>';
													|en = '<not used when continue processing>'; fa = '<not used when continue processing>';
													|it = '<non è utilizzato in caso di proseguimento dell''elaborazione dei dati>';
													|pl = '<nie używane w przypadku kontynuowania przetwarzania>';
													|tr = '<işleme devam ederken kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// The focus of the issue
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsTheDirectionOfTheReleaseForm.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.TheDirectionOfTheReleaseForm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = DirectionToContinueProcessing();
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tiếp tục xử lý';
													|ru = 'Продолжить обработку';
													|en = 'Continue processing'; fa = 'ادامه پردازش';
													|it = 'Continuare elaborazione';
													|pl = 'Kontynuuj przetworzenie';
													|tr = 'İşlemeye devam et'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsTheDirectionOfTheReleaseForm.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.TheDirectionOfTheReleaseForm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ProductsReleaseToWarehouse;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Điều chuyển hàng hóa';
													|ru = 'На склад';
													|en = 'To warehouse'; fa = 'To warehouse';
													|it = 'Al magazzino';
													|pl = 'Na magazyn';
													|tr = 'Ambara'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsTheDirectionOfTheReleaseForm.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.TheDirectionOfTheReleaseForm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Sang bộ phận';
													|ru = 'В подразделение';
													|en = 'To business unit'; fa = 'To business unit';
													|it = 'Al reparto';
													|pl = 'Do działu';
													|tr = 'Departmana'"));

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsTheDirectionOfTheReleaseForm.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.TheDirectionOfTheReleaseForm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm vào chi phí';
													|ru = 'Списать на расходы';
													|en = 'Expense as'; fa = 'هزینه به عنوان';
													|it = 'Stornare sulle spese';
													|pl = 'Spisać w koszty';
													|tr = 'Gider olarak kaydet'"));
	
	// Expense Analytics
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsExpenseItem.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsDimensionOfExpenses.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsAssetsLiabilitiesDimension.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsTransactionRecordingPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// The recipient is the same as the issuing department
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsRecipient.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.Recipient");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.Lots.Department"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// Recipient mark blank
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsRecipient.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
		
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Recipient.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.Recipient");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Recipient.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.Recipient");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// To continue processing
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsContinueBOM.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsContinueStagePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.TheDirectionOfTheReleaseForm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ProductsReleaseToWarehouse;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được sử dụng khi nhập vào kho>';
													|ru = '<не используется при выпуске на склад>';
													|en = '<not used on release to warehouse>'; fa = '<not used on release to warehouse>';
													|it = '<non viene utilizzato al rilascio in magazzino>';
													|pl = '<nie używane w przypadku wyprodukowania do magazynu>';
													|tr = '<ambara ürün çıkışında kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsContinueBOM.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsContinueStagePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.TheDirectionOfTheReleaseForm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được sử dụng để xuất xưởng>';
													|ru = '<не используется при выпуске в подразделение>';
													|en = '<not used on release to business unit>'; fa = '<not used on release to business unit>';
													|it = '<Non viene utilizzato al rilascio nella suddivisione>';
													|pl = '<nie używane w przypadku wyprodukowania do działu>';
													|tr = '<departmana ürün çıkışında kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsContinueBOM.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsContinueStagePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.TheDirectionOfTheReleaseForm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được sử dụng để khấu trừ chi phí>';
													|ru = '<не используется при списании на расходы>';
													|en = '<not used while writing off as expenses>'; fa = '<not used while writing off as expenses>';
													|it = '<non viene usato durante storno sulle spese>';
													|pl = '<nie używane podczas rozchodu na wydatki>';
													|tr = '<giderlere yazılırken kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsContinueStagePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.ContinueBOM");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn bảng kê chi tiết>';
													|ru = '<выберите спецификацию>';
													|en = '<select a bill of materials>'; fa = '<select a bill of materials>';
													|it = '<выберите спецификацию>';
													|pl = '<select a bill of materials>';
													|tr = '<ürün reçetesi seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Displaying an image in the results tree
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExecutionResultPictureNumber.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExecutionResult.HidePicture");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Lot size
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsLotNumberOfPackages.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.TheDirectionOfTheReleaseForm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ProductsReleaseToWarehouse;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được sử dụng khi nhập vào kho>';
													|ru = '<не используется при выпуске на склад>';
													|en = '<not used on release to warehouse>'; fa = '<not used on release to warehouse>';
													|it = '<non viene utilizzato al rilascio in magazzino>';
													|pl = '<nie używane w przypadku wyprodukowania do magazynu>';
													|tr = '<ambara ürün çıkışında kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsLotNumberOfPackages.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.TheDirectionOfTheReleaseForm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được sử dụng để xuất xưởng>';
													|ru = '<не используется при выпуске в подразделение>';
													|en = '<not used on release to business unit>'; fa = '<not used on release to business unit>';
													|it = '<Non viene utilizzato al rilascio nella suddivisione>';
													|pl = '<nie używane w przypadku wyprodukowania do działu>';
													|tr = '<departmana ürün çıkışında kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsLotNumberOfPackages.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.TheDirectionOfTheReleaseForm");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được sử dụng để khấu trừ chi phí>';
													|ru = '<не используется при списании на расходы>';
													|en = '<not used while writing off as expenses>'; fa = '<not used while writing off as expenses>';
													|it = '<non viene usato durante storno sulle spese>';
													|pl = '<nie używane podczas rozchodu na wydatki>';
													|tr = '<giderlere yazılırken kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsPackageOfLot.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsBatchProductsUnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.ContinueProcessing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Documents with errors
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ExecutionResult.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExecutionResult.HasErrors");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	// Party assignments
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsAssignmentsPresentation.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsThereAreErrorsInFillingOutAssignments.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.SpecifyTargets");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// Characteristic (form)
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		Items.LotsCharacteristicForm.Name,
		"Object.Lots.ItemVariantsAreUsed");
	
	// Auto-Selection - Item List
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsItemsForm.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.AutomaticSelectionOfItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.Lots.AutoSelectionItemPresentation"));
	
	// Auto-Selection - Characteristics
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsCharacteristicForm.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.AutomaticSelectionOfItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.Lots.CharacteristicsOfAutoSelectionPresentation"));
	
	// Auto-Selection - Packaging Units
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LotsPackage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lots.AutomaticSelectionOfItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Object = Form.Object; // DataProcessorObject.ProductionLotDivision
	Items = Form.Items;
	
	Actions = Actions();
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("ProductProductRange")
		Or AttributesStructure1.Property("ProductFeature")
		Or AttributesStructure1.Property("NumberOfPackages")
		Or Initialize Then
		
		If Object.MainProductProducts.IsEmpty() Then
			Items.TheProductIsTheInscription.Visible = False;
		Else
			Items.TheProductIsTheInscription.Visible = True;
			
			RowsArray = New Array;
			RowsArray.Add(New FormattedString(Form.ProductProductRangePresentation,,,, "#ShowProduct"));
			If Not Object.MainProductCharacteristic.IsEmpty() Then
				RowsArray.Add(" / ");
				RowsArray.Add(New FormattedString(Form.ProductFeaturePresentation,,,, "#ShowProductCharacteristics"));
			EndIf;
			If Object.NumberOfPackages <> 0 Then
				RowsArray.Add(" ");
				RowsArray.Add(NStr("vi = 'Số lượng';
									|ru = 'Количество';
									|en = 'Quantity'; fa = 'مقدار';
									|it = 'Quantità';
									|pl = 'Quantity';
									|tr = 'Miktar'"));
				RowsArray.Add(": ");
				RowsArray.Add(Format(Object.NumberOfPackages, "NG="));
				RowsArray.Add(" ");
				RowsArray.Add(Form.ItemPackagePresentation);
			EndIf;
			Form.TheProductIsTheInscription = New FormattedString(RowsArray);
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("NumberOfPackages")
		Or Initialize Then
		
		Items.ActionToContinue.ChoiceList.Clear();
		Items.ActionToContinue.ChoiceList.Add(Actions.Continue,
			StrTemplate(NStr("vi = 'Tạo xuất xưởng và tiếp tục xử lý %1%2 bằng lô hàng mới';
							|ru = 'Оформить выпуск и продолжить обработку %1 %2 новой партией';
							|en = 'Register the release and continue processing %1 %2 of the new lot'; fa = 'Register the release and continue processing %1 %2 of the new lot';
							|it = 'Оформить выпуск и продолжить обработку %1 %2 новой партией';
							|pl = 'Register the release and continue processing %1 %2 of the new lot';
							|tr = 'Ürün çıkışını düzenle ve yeni lot ile %2 %1 işlemeye devam et'"),
				Object.NumberOfPackages,
				Form.ItemPackagePresentation));
		
	EndIf;
	
	If AttributesStructure1.Property("Action")
		Or Initialize Then
		
		Items.TheNumberOfPartiesToShare.Enabled =
			(Object.Action = Actions.Split)
			And Not Form.SimpleMode;
		Items.MethodOfAllocatingFinishedProductCosts.Enabled =
			(Object.Action = Actions.Split);
		
		Items.NumberOfPackagingUnitsNonconformity.Enabled =
			(Object.Action = Actions.DefectiveGoods);
		Items.TheDirectionOfTheReleaseForm.Enabled =
			(Object.Action <> Actions.Continue);
		
		RowsArray = New Array;
		RowsArray.Add(PictureLib.Information16);
		RowsArray.Add(" ");
		RowsArray.Add(?(Object.Action = Actions.Cancel,
			NStr("vi = 'Một công đoạn bổ sung sẽ được tạo ra để lập xuất xưởng.';
				|ru = 'Будет создан дополнительный этап для оформления выпуска';
				|en = 'Additional stage for release registration will be created'; fa = 'Additional stage for release registration will be created';
				|it = 'Sarà creata una fase aggiuntiva per registrare l''emissione della produzione';
				|pl = 'Zostanie utworzony dodatkowy etap do sporządzenia wydania';
				|tr = 'Ürün çıkışı için ek bir aşama oluşturulacaktır'"),
			NStr("vi = 'Một công đoạn bổ sung sẽ được tạo để lập xuất xưởng trung gian';
				|ru = 'Будет создан дополнительный этап для оформления промежуточного выпуска';
				|en = 'Additional stage for intermediate release registration will be created'; fa = 'Additional stage for intermediate release registration will be created';
				|it = 'Sarà creata una fase aggiuntiva per registrare l''emissione della produzione intermedia';
				|pl = 'Zostanie utworzony dodatkowy etap do sporządzenia produkcji pośredniej';
				|tr = 'Ara ürün çıkışı için ek bir aşama oluşturulacaktır'")));
		Items.TheStageWillBeCreated.Title = New FormattedString(RowsArray);
		
		Items.NumberOfPackagingUnitsNonconformity.AutoMarkIncomplete = (Object.Action = Actions.DefectiveGoods);
		
	EndIf;
	
	If AttributesStructure1.Property("Action")
		Or AttributesStructure1.Property("SimpleMode")
		Or AttributesStructure1.Property("Stage")
		Or Initialize Then
		
		Items.HyperlinkGroupSplit.Visible = 
			(Object.Action = Actions.Split)
			And Not Form.SimpleMode;
		
		Items.HyperlinkGroupNonconformity.Visible =
			(Object.Action = Actions.DefectiveGoods)
			And Not Form.SimpleMode;
		
		Items.UndoDecorationIsEmpty.Visible = 
			(Object.Action = Actions.Cancel)
			And Object.FromBeginningOfParty
			And Not Form.SimpleMode;
		
		Items.DecorationSimpleModeCancelEmpty.Visible = 
			(Object.Action = Actions.Cancel)
			And Object.FromBeginningOfParty
			And Form.SimpleMode;
		
		If Object.Action = Actions.Split Then
			Items.GroupSimpleMode.CurrentPage = Items.PageSimpleSplitMode;
		ElsIf Object.Action = Actions.DefectiveGoods Then
			Items.GroupSimpleMode.CurrentPage = Items.PageSimpleModeNonconformity;
		ElsIf Object.Action = Actions.Cancel Then
			Items.GroupSimpleMode.CurrentPage = Items.EasyModeCancelPage;
			Items.GroupSimpleModeCancelIntermediateRelease.Visible = Not Object.FromBeginningOfParty;
		ElsIf Object.Action = Actions.Reduce Then
			Items.GroupSimpleMode.CurrentPage = Items.PageSimpleModeReduce;
		Else
			Items.GroupSimpleMode.CurrentPage = Items.SimpleModePageIsEmpty;
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("Action")
		Or AttributesStructure1.Property("QuantityOfBatches")
		Or AttributesStructure1.Property("Stage")
		Or Initialize Then
		
		Items.GroupShareOfCost.Visible =
			Object.Action = Actions.Split
			Or Object.Action = Actions.DefectiveGoods
				And Form.QuantityOfBatches > 1
			Or Object.Action = Actions.DefectiveGoods
				And Object.ThisIsLastStageAndOperation
				And Object.CostSharesAreFilledInStage;
		
	EndIf;
	
	If AttributesStructure1.Property("MethodOfAllocatingFinishedProductCosts")
		Or Initialize Then
		
		DistributionByShares = Object.MethodOfAllocatingFinishedProductCosts
			= PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares");
		
		Items.CostShare.Visible = DistributionByShares;
		
		Items.CostSharePercentage.TitleLocation = ?(DistributionByShares,
			FormItemTitleLocation.None,
			FormItemTitleLocation.Auto);
		Items.CostSharePercentage.Hyperlink = Not DistributionByShares;
		
		Items.ThereAreErrorsOfFillingInCostShare.TitleLocation = ?(DistributionByShares,
			FormItemTitleLocation.None,
			FormItemTitleLocation.Auto);
		Items.ThereAreErrorsOfFillingInCostShare.Hyperlink = Not DistributionByShares;
		
		Items.ShareOfCostIsLessThanPercentPresentation.TitleLocation = ?(DistributionByShares,
			FormItemTitleLocation.None,
			FormItemTitleLocation.Auto);
		Items.ShareOfCostIsLessThanPercentPresentation.Hyperlink = Not DistributionByShares;
		
	EndIf;
	
	If AttributesStructure1.Property("TheNumberOfPartiesToShare")
		Or AttributesStructure1.Property("Stage")
		Or Initialize Then
		
		If Form.DivisionCancellationFromBeginningOfParty Then
			
			Items.MethodOfAllocatingFinishedProductCosts.Visible = False;
			Items.DecorationNumberOfParties.Title = 
				TMCommonUseClientServer.DeclensionOfWord(
					Form.TheNumberOfPartiesToShare,
					NStr("vi = 'lô, lô, lô, d';
						|ru = 'партию, партии, партий, ж';
						|en = 'lot, lots'; fa = 'lot, lots';
						|it = 'партию, партии, партий, ж';
						|pl = 'lot, lots';
						|tr = 'parti, partiler, partiler, j'"));
			
		Else
			
			Items.MethodOfAllocatingFinishedProductCosts.Visible = True;
			Items.DecorationNumberOfParties.Title = StrTemplate(NStr("vi = '%1, phân bổ chi phí';
																	|ru = '%1, распределить затраты';
																	|en = '%1, allocate costs'; fa = '%1, allocate costs';
																	|it = '%1, distribuire i costi';
																	|pl = '%1, przydziel wydatki';
																	|tr = '%1, giderleri dağıt'"),
				TMCommonUseClientServer.DeclensionOfWord(
					Form.TheNumberOfPartiesToShare,
					NStr("vi = 'lô, lô, lô, d';
						|ru = 'партию, партии, партий, ж';
						|en = 'lot, lots'; fa = 'lot, lots';
						|it = 'партию, партии, партий, ж';
						|pl = 'lot, lots';
						|tr = 'parti, partiler, partiler, j'"))
				);
				
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("CurrentBatch")
		Or Initialize Then
		
		Items["Lot" + Format(Form.CurrentBatch, "ND=3; NZ=000; NLZ=")].Hyperlink = False;
		Items["Lot" + Format(Form.CurrentBatch, "ND=3; NZ=000; NLZ=")].TextColor = Form.ColorSelectedLink;
		
		If Form.PreviousBatch <> PartyIndexes().Undefined Then
			
			Items["Lot" + Format(Form.PreviousBatch, "ND=3; NZ=000; NLZ=")].Hyperlink = True;
			Items["Lot" + Format(Form.PreviousBatch, "ND=3; NZ=000; NLZ=")].TextColor = Form.ColorNotSelectedLink;
			Form.PreviousBatch = PartyIndexes().Undefined;
			
		EndIf;
		
		Items.LotReferenceDefectiveFinishedproduct.Hyperlink = (Form.CurrentBatch <> 0);
		Items.LotReferenceDefectiveFinishedproduct.TextColor = ?(Form.CurrentBatch <> 0,
			Form.ColorNotSelectedLink, Form.ColorSelectedLink);
		
		Items.LotBalance.Hyperlink = (Form.CurrentBatch <> 1);
		Items.LotBalance.TextColor = ?(Form.CurrentBatch <> 1,
			Form.ColorNotSelectedLink, Form.ColorSelectedLink);
		
		If Form.CurrentBatch <> PartyIndexes().AllBatches Then
			
			Items.Lots.CurrentRow = Object.Lots[Form.CurrentBatch].GetID();
			
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("Action")
		Or AttributesStructure1.Property("QuantityOfBatches")
		Or AttributesStructure1.Property("CurrentBatch")
		Or Initialize Then
		
		If Object.Action = Actions.DefectiveGoods Then
			
			Items.GroupIntermediateRelease.ShowTitle = (Form.CurrentBatch = 1);
			Items.GroupIntermediateRelease.Title = NStr("vi = 'Xuất xưởng trung gian';
														|ru = 'Промежуточный выпуск';
														|en = 'Intermediate release'; fa = 'تولید میانی';
														|it = 'Produzione intermedia';
														|pl = 'Produkcja pośrednia';
														|tr = 'Ara ürün çıkışı'");
			
		Else
			
			Items.GroupIntermediateRelease.ShowTitle = True;
			If Object.Action = Actions.Cancel Then
				Items.GroupIntermediateRelease.Title = NStr("vi = 'Xuất xưởng';
															|ru = 'Выпуск';
															|en = 'Release'; fa = 'آزادسازی';
															|it = 'Produzione';
															|pl = 'Release';
															|tr = 'İmal edilen ürünler'");
			Else
				Items.GroupIntermediateRelease.Title = ?(Form.QuantityOfBatches > 1,
					StrTemplate(NStr("vi = 'Xuất xưởng trung gian %1';
									|ru = 'Промежуточный выпуск %1';
									|en = 'Intermediate release %1'; fa = 'Intermediate release %1';
									|it = 'Produzione intermedia %1';
									|pl = 'Produkcja pośrednia %1';
									|tr = '%1 ara ürün çıkışı'"), Form.CurrentBatch+1),
					NStr("vi = 'Xuất xưởng trung gian';
						|ru = 'Промежуточный выпуск';
						|en = 'Intermediate release'; fa = 'تولید میانی';
						|it = 'Produzione intermedia';
						|pl = 'Produkcja pośrednia';
						|tr = 'Ara ürün çıkışı'"));
			EndIf;
			
		EndIf;
		
		VisibilityNonconformityAdvancedMode = Object.Action = Actions.DefectiveGoods
			And Form.CurrentBatch = 0
			And Form.OneAction;
		Items.AdvancedModeNumberOfPackagingUnitsNonconformity.Visible = VisibilityNonconformityAdvancedMode;
		Items.ItemPackagePresentation3.Visible = VisibilityNonconformityAdvancedMode;
		
	EndIf;
	
	If AttributesStructure1.Property("QuantityOfBatches")
		Or AttributesStructure1.Property("CurrentBatch")
		Or Initialize Then
		
		Items.LotNumberOfPackages.Title = ?(Form.QuantityOfBatches > 1,
			StrTemplate(NStr("vi = 'Kích thước lô %1';
							|ru = 'Размер партии %1';
							|en = 'Lot size %1'; fa = 'Lot size %1';
							|it = 'Dimensione del lotto %1';
							|pl = 'Rozmiar partii %1';
							|tr = '%1 lotu büyüklüğü'"), Form.CurrentBatch+1),
			NStr("vi = 'Kích thước lô';
				|ru = 'Размер партии';
				|en = 'Lot size'; fa = 'اندازه لات';
				|it = 'Dimensione del lotto';
				|pl = 'Rozmiar partii';
				|tr = 'Lot büyüklüğü'"));
		
	EndIf;
	
	If AttributesStructure1.Property("QuantityOfBatches")
		Or Initialize Then
		
		Items.LotBalance.Enabled = Form.QuantityOfBatches >= 2;
		
	EndIf;
	
	If AttributesStructure1.Property("Action")
		Or AttributesStructure1.Property("Stage")
		Or AttributesStructure1.Property("CreateStage")
		Or Initialize Then
		
		VisibilityIntermediateRelease = 
			((Object.Action = Actions.Cancel Or Object.Action = Actions.Split)
				And Not Object.FromBeginningOfParty)
			Or Object.Action = Actions.Continue
			Or Object.Action = Actions.DefectiveGoods; // In Continue and Nonconformity, the Attributes are always visible, there is control in checking the filling
		
		Items.GroupIntermediateRelease.Visible = VisibilityIntermediateRelease;
		Items.BatchGroupIntermediateRelease1.Visible = VisibilityIntermediateRelease;
		Items.BatchGroupIntermediateRelease2.Visible = VisibilityIntermediateRelease;
		Items.BatchGroupIntermediateRelease3.Visible = VisibilityIntermediateRelease;
		Items.BatchGroupIntermediateRelease4.Visible = VisibilityIntermediateRelease;
		
		Items.TheStageWillBeCreated.Visible = VisibilityIntermediateRelease And Object.CreateStage;
		
	EndIf;
	
	If AttributesStructure1.Property("Action")
		Or AttributesStructure1.Property("Stage")
		Or AttributesStructure1.Property("CurrentBatch")
		Or Initialize Then
		
		If Form.SimpleMode Then
			Items.GroupPages.CurrentPage = Items.PageSimpleMode;
		ElsIf Form.CurrentBatch = PartyIndexes().AllBatches Then
			Items.GroupPages.CurrentPage = Items.AllBatchesPage;
		Else
			Items.GroupPages.CurrentPage = Items.BatchPage;
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("Stage")
		Or Initialize Then
		
		Items.TheActionToCancel.ChoiceList[0].Presentation = ?(Form.DivisionCancellationFromBeginningOfParty,
			NStr("vi = 'Hủy sản xuất';
				|ru = 'Отменить производство';
				|en = 'Cancel production'; fa = 'لغو تولید';
				|it = 'Annulla produzione';
				|pl = 'Anuluj produkcję';
				|tr = 'Üretimi iptal et'"),
			NStr("vi = 'Hủy bỏ sản xuất, tạo xuất xưởng';
				|ru = 'Отменить производство, оформить выпуск';
				|en = 'Stop production and register the release'; fa = 'Stop production and register the release';
				|it = 'Отменить производство, оформить выпуск';
				|pl = 'Stop production and register the release';
				|tr = 'Üretimi iptal et, ürün çıkışı düzenle'"));
		
	EndIf;
	
	If AttributesStructure1.Property("SeriesSpecificationParameters")
		Or Initialize Then
		
		Items.Series.Visible = Form.SeriesSpecificationParameters.UseItemsBatch;
		Items.BatchesIndicationStatus.Visible = Form.SeriesSpecificationParameters.UseItemsBatch;
		Items.SpecifySeries.Visible = Form.SeriesSpecificationParameters.UseItemsBatch;
		
		Items.LotsSeries.Visible = Form.SeriesSpecificationParameters.UseItemsBatch;
		Items.LotsBatchesIndicationStatus.Visible = Form.SeriesSpecificationParameters.UseItemsBatch;
		
	EndIf;
	
	If AttributesStructure1.Property("Stage")
		Or Initialize Then
		
		Items.BatchesFinishedProductGroup.ShowInHeader = Not Object.FromBeginningOfParty;
		
	EndIf;
	
	If AttributesStructure1.Property("Stage")
		Or AttributesStructure1.Property("Settings")
		Or Initialize Then
		
		VisibilityContinue = Not Object.FromBeginningOfParty;
		Items.LotsContinueBOM.Visible = VisibilityContinue;
		Items.LotsContinueStagePresentation.Visible = VisibilityContinue;
		
	EndIf;
	
	If AttributesStructure1.Property("SeriesSpecificationParameters")
		Or AttributesStructure1.Property("Action")
		Or AttributesStructure1.Property("Stage")
		Or Initialize Then
		
		Items.LotsSpecifySeries.Visible = Not Object.FromBeginningOfParty
			And Object.Action = Actions.Split
			And Form.SeriesSpecificationParameters.UseItemsBatch;
		
	EndIf;
	
	If AttributesStructure1.Property("SimpleModeSplitReleaseDirection")
		Or AttributesStructure1.Property("Stage")
		Or Initialize Then
		
		Items.SimpleSplitContinueMode.Visible = Not Object.FromBeginningOfParty;
		Items.SimpleModeSplitIntoWarehouse.Visible = Not Object.FromBeginningOfParty;
		Items.SimpleSplitRecipientMode.Visible = Not Object.FromBeginningOfParty
			And Form.SimpleModeReleaseDirection <> DirectionToContinueProcessing();
		Items.GroupSimpleModeSplitCancelFinishedProductInOrder.Visible = Form.ThisIsFinishedProductOfOrder
			And Not Object.FromBeginningOfParty
			And Form.SimpleModeReleaseDirection <> DirectionToContinueProcessing();
		
	EndIf;
	
	If AttributesStructure1.Property("SimpleModeNonconformityDirectionOfRelease")
		Or AttributesStructure1.Property("SimpleModeNonconformityExpenseItem")
		Or Initialize Then
		
		FirstLotReference = Object.Lots[0];
		
		Items.SimpleModeNonconformityExpenseItem.Visible = FirstLotReference.ToExpenseAs;
		
		Items.SimpleNonconformityModeExpenseAnalytics.Visible = FirstLotReference.ToExpenseAs
			And TypeOf(FirstLotReference.ExpenseItem) <> Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
		Items.SimpleNonconformityModeExpenseAnalytics.Enabled = ValueIsFilled(FirstLotReference.ExpenseItem);
		Items.SimpleNonconformityModeExpenseAnalytics.InputHint = ?(ValueIsFilled(FirstLotReference.ExpenseItem),
			"",
			NStr("vi = '<hãy chọn dạng chi phí>';
				|ru = '<выберите статью расходов>';
				|en = '<select an expense item>'; fa = '<select an expense item>';
				|it = '<selezionare la voce delle spese>';
				|pl = '<wybierz pozycję wydatków>';
				|tr = '<gider kalemini seçin>'"));
		
		Items.SimpleModeNonconformityAnalyticsOfAssetsLiabilities.Visible = FirstLotReference.ToExpenseAs
			And TypeOf(FirstLotReference.ExpenseItem) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
		Items.SimpleModeNonconformityAnalyticsOfAssetsLiabilities.Enabled = ValueIsFilled(FirstLotReference.ExpenseItem);
		Items.SimpleModeNonconformityAnalyticsOfAssetsLiabilities.InputHint = ?(ValueIsFilled(FirstLotReference.ExpenseItem),
			"",
			NStr("vi = '<hãy chọn dạng chi phí>';
				|ru = '<выберите статью расходов>';
				|en = '<select an expense item>'; fa = '<select an expense item>';
				|it = '<selezionare la voce delle spese>';
				|pl = '<wybierz pozycję wydatków>';
				|tr = '<gider kalemini seçin>'"));
		
	EndIf;
	
	If AttributesStructure1.Property("SimpleModeNonconformityDirectionOfRelease")
		Or AttributesStructure1.Property("SimpleModeNonconformityExpenseItem")
		Or AttributesStructure1.Property("SimpleModeNonconformityRecipient")
		Or Initialize Then
		
		FirstLotReference = Object.Lots[0];
		
		If FirstLotReference.ToExpenseAs Then
			Items.SimpleModeNonconformityRecipient.InputHint = FirstLotReference.Department;
			Items.SimpleModeNonconformityRecipient.AutoMarkIncomplete = False;
			Items.SimpleModeNonconformityRecipient.MarkIncomplete = False;
		Else
			Items.SimpleModeNonconformityRecipient.InputHint = "";
			Items.SimpleModeNonconformityRecipient.AutoMarkIncomplete = True;
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("SimpleModeUndoReleaseDirection")
		Or AttributesStructure1.Property("SimpleModeCancelExpenseItem")
		Or Initialize Then
		
		FirstLotReference = Object.Lots[0];
		
		Items.SimpleModeCancelExpenseItem.Visible = FirstLotReference.ToExpenseAs;
		
		Items.EasyModeCancelAnalyticsOfExpenses.Visible = FirstLotReference.ToExpenseAs
			And TypeOf(FirstLotReference.ExpenseItem) <> Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
		Items.EasyModeCancelAnalyticsOfExpenses.Enabled = ValueIsFilled(FirstLotReference.ExpenseItem);
		Items.EasyModeCancelAnalyticsOfExpenses.InputHint = ?(ValueIsFilled(FirstLotReference.ExpenseItem),
			"",
			NStr("vi = '<hãy chọn dạng chi phí>';
				|ru = '<выберите статью расходов>';
				|en = '<select an expense item>'; fa = '<select an expense item>';
				|it = '<selezionare la voce delle spese>';
				|pl = '<wybierz pozycję wydatków>';
				|tr = '<gider kalemini seçin>'"));
		
		Items.SimpleModeCancelAnalyticsOfAssetsLiabilities.Visible = FirstLotReference.ToExpenseAs
			And TypeOf(FirstLotReference.ExpenseItem) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
		Items.SimpleModeCancelAnalyticsOfAssetsLiabilities.Enabled = ValueIsFilled(FirstLotReference.ExpenseItem);
		Items.SimpleModeCancelAnalyticsOfAssetsLiabilities.InputHint = ?(ValueIsFilled(FirstLotReference.ExpenseItem),
			"",
			NStr("vi = '<hãy chọn dạng chi phí>';
				|ru = '<выберите статью расходов>';
				|en = '<select an expense item>'; fa = '<select an expense item>';
				|it = '<selezionare la voce delle spese>';
				|pl = '<wybierz pozycję wydatków>';
				|tr = '<gider kalemini seçin>'"));
		
	EndIf;
	
	If AttributesStructure1.Property("SimpleModeUndoReleaseDirection")
		Or AttributesStructure1.Property("SimpleModeCancelExpenseItem")
		Or AttributesStructure1.Property("SimpleModeCancelRecipient")
		Or Initialize Then
		
		FirstLotReference = Object.Lots[0];
		
		If FirstLotReference.ToExpenseAs Then
			Items.SimpleModeCancelRecipient.InputHint = FirstLotReference.Department;
			Items.SimpleModeCancelRecipient.AutoMarkIncomplete = False;
			Items.SimpleModeCancelRecipient.MarkIncomplete = False;
		Else
			Items.SimpleModeCancelRecipient.InputHint = "";
			Items.SimpleModeCancelRecipient.AutoMarkIncomplete = True;
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("Action")
		Or AttributesStructure1.Property("SimpleModeNumberOfPackagingunits")
		Or Initialize Then
		
		FirstLotReference = Object.Lots[0];
		
		Items.GroupSimpleModeReduceCancelFINISHEDProductInOrder.Visible = Form.ThisIsFinishedProductOfOrder
			And Object.Action = Actions.Reduce
			And FirstLotReference.LotQuantity < Object.Count;
		
	EndIf;
	
	If AttributesStructure1.Property("SimpleModeSplitCancelFinishedProductInOrder")
		Or Initialize Then
		
		LastLotReference = Object.Lots[Object.Lots.Count()-1];
		Items.SimpleModeShareReasonForCancellationOfFinishedProduct.Enabled = LastLotReference.CancelChangeFinishedProductInOrder;
		
	EndIf;
	
	If AttributesStructure1.Property("SimpleModeNonconformityCancelFinishedProductInOrder")
		Or Initialize Then
		
		FirstLotReference = Object.Lots[0];
		Items.SimpleModeNonconformityReasonForCancellationOfFinishedProduct.Enabled = FirstLotReference.CancelChangeFinishedProductInOrder;
		
	EndIf;
	
	If AttributesStructure1.Property("EasyModeCancelFinishedProductInOrder")
		Or Initialize Then
		
		FirstLotReference = Object.Lots[0];
		Items.SimpleModeReasonForCancellationOfFinishedProduct.Enabled = FirstLotReference.CancelChangeFinishedProductInOrder;
		
	EndIf;
	
	If AttributesStructure1.Property("SimpleModeReduceCancelFINISHEDProductInOrder")
		Or Initialize Then
		
		FirstLotReference = Object.Lots[0];
		Items.SimpleModeReduceReasonForCancellationOfFinishedDProduct.Enabled = FirstLotReference.CancelChangeFinishedProductInOrder;
		
	EndIf;
	
	If Items.Lots.CurrentRow <> Undefined
		And Form.CurrentBatch <> PartyIndexes().AllBatches Then
		
		CurrentData = Object.Lots.FindByID(Items.Lots.CurrentRow);
		
		// Design of header elements: Item, Characteristics, Packaging Units
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("Products")
			Or AttributesStructure1.Property("AutomaticSelectionOfItems")
			Or Initialize Then
			
			If CurrentData.AutomaticSelectionOfItems Then
				Items.ItemsForm.InputHint = CurrentData.AutoSelectionItemPresentation;
				Items.ItemsForm.AutoMarkIncomplete = False;
				Items.ItemsForm.MarkIncomplete = False;
			Else
				Items.ItemsForm.InputHint = "";
				Items.ItemsForm.AutoMarkIncomplete = True;
			EndIf;
			
			Items.CharacteristicForm.Enabled = CurrentData.ItemVariantsAreUsed
				And Not CurrentData.AutomaticSelectionOfItems;
			
			If Not CurrentData.ItemVariantsAreUsed Then
				Items.CharacteristicForm.InputHint = NStr("vi = '<không sử dụng đặc tính>';
															|ru = '<характеристики не используются>';
															|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
															|it = '<le caratteristiche non vengono usate>';
															|pl = '<charakterystyki nie dotyczą>';
															|tr = '<varyantlar kullanılmamaktadır>'");
			ElsIf CurrentData.AutomaticSelectionOfItems Then
				Items.CharacteristicForm.InputHint = CurrentData.CharacteristicsOfAutoSelectionPresentation;
			Else
				Items.CharacteristicForm.InputHint = "";
			EndIf;
			
			Items.Package.Enabled = Not CurrentData.AutomaticSelectionOfItems;
			Items.Package.InputHint = CurrentData.UnitOfMeasure;
			
		EndIf;
		
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("ContinueItem")
			Or Initialize Then
			
			Items.ContinueVariant.Enabled = CurrentData.ContinueCharacteristicsAreUsed;
			Items.ContinueVariant.InputHint = ?(CurrentData.ContinueCharacteristicsAreUsed, "",
				NStr("vi = '<không sử dụng đặc tính>';
					|ru = '<характеристики не используются>';
					|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
					|it = '<le caratteristiche non vengono usate>';
					|pl = '<charakterystyki nie dotyczą>';
					|tr = '<varyantlar kullanılmamaktadır>'"));
			
		EndIf;
		
		// Design of header elements: Purpose
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("Products")
			Or AttributesStructure1.Property("ToExpenseAs")
			Or AttributesStructure1.Property("ContinueProcessing")
			Or Initialize Then
			
			If CurrentData.ToExpenseAs Then
				
				Items.Purpose.Enabled = False;
				Items.Purpose.InputHint = NStr("vi = '<không được sử dụng để khấu trừ chi phí>';
												|ru = '<не используется при списании на расходы>';
												|en = '<not used while writing off as expenses>'; fa = '<not used while writing off as expenses>';
												|it = '<non viene usato durante storno sulle spese>';
												|pl = '<nie używane podczas rozchodu na wydatki>';
												|tr = '<giderlere yazılırken kullanılmamaktadır>'");
				
			ElsIf CurrentData.ContinueProcessing Then
				
				Items.Purpose.Enabled = False;
				Items.Purpose.InputHint = NStr("vi = '<không được sử dụng để tiếp tục xử lý>';
												|ru = '<не используется при продолжении обработки>';
												|en = '<not used when continue processing>'; fa = '<not used when continue processing>';
												|it = '<Non viene utilizzato nel proseguimento dell''elaborazione>';
												|pl = '<nie używane w przypadku kontynuowania przetwarzania>';
												|tr = '<işleme devam ederken kullanılmamaktadır>'");
				
			ElsIf CurrentData.ItemsType.IsEmpty()
				Or CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
				
				Items.Purpose.Enabled = False;
				Items.Purpose.InputHint = NStr("vi = '<dành cho hàng hóa và công việc>';
												|ru = '<для товаров и работ>';
												|en = '<for goods and labor>'; fa = '<for goods and labor>';
												|it = '<per beni e opere>';
												|pl = '<dla towarów i robót>';
												|tr = '<ürünler ve işler için>'");
				
			Else
				
				Items.Purpose.Enabled = True;
				Items.Purpose.InputHint = "";
				
			EndIf;
			
		EndIf;
		
		// Design of header elements: Series
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("Products")
			Or AttributesStructure1.Property("BatchesIndicationStatuses")
			Or Initialize Then
			
			If CurrentData.ItemsType.IsEmpty()
				Or CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
				
				Items.Series.Enabled = False;
				Items.Series.InputHint = NStr("vi = '<cho hàng hóa>';
												|ru = '<для товаров>';
												|en = '<for goods>'; fa = '<for goods>';
												|it = '<per le merci>';
												|pl = '<dla towarów>';
												|tr = '<ürünler için>'");
				Items.SpecifySeries.Enabled = False;
				
			ElsIf CurrentData.BatchesIndicationStatus = 0 Then
				
				Items.Series.Enabled = False;
				Items.Series.InputHint = NStr("vi = '<chưa chỉ ra sê-ri>';
												|ru = '<серия не указывается>';
												|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
												|it = '<serie non è indicata>';
												|pl = '<seria nie jest określana>';
												|tr = '<parti belirtilmemektedir>'");
				Items.SpecifySeries.Enabled = False;
				
			ElsIf ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(
				CurrentData.BatchesIndicationStatus,
				Form.SeriesSpecificationParameters) Then
				
				Items.Series.Enabled = True;
				Items.Series.InputHint = "";
				Items.SpecifySeries.Enabled = True;
				
			Else
				
				Items.Series.Enabled = False;
				Items.Series.InputHint = NStr("vi = '<chỉ ra số sê-ri riêng biệt>';
												|ru = '<серия указывается отдельно>';
												|en = '<batch is specified separately>'; fa = '<batch is specified separately>';
												|it = '<la serie è specificata separatamente>';
												|pl = '<seria jest wskazywana oddzielnie>';
												|tr = '<parti ayrı olarak belirtilmektedir>'");
				Items.SpecifySeries.Enabled = True;
				
			EndIf;
			
		EndIf;
		
		// The design of the header elements: The share of the cost
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("CostSharePercentage")
			Or AttributesStructure1.Property("Action")
			Or AttributesStructure1.Property("Stage")
			Or Initialize Then
			
			ThisIsNonconformityAtEndOfParty = Object.Action = Actions.DefectiveGoods
				And Object.ThisIsLastStageAndOperation;
			
			Items.CostSharePercentage.Visible = ValueIsFilled(CurrentData.CostSharePercentage)
				And Not ThisIsNonconformityAtEndOfParty;
			Items.ThereAreErrorsOfFillingInCostShare.Visible = Not ValueIsFilled(CurrentData.CostSharePercentage)
				And Not ThisIsNonconformityAtEndOfParty;
			Items.ShareOfCostIsLessThanPercentPresentation.Visible = Not CurrentData.ThereAreErrorsOfFillingInCostShare
				And Not ValueIsFilled(CurrentData.CostSharePercentage);
		EndIf;
		
		// Design of header elements: Cost Analytics
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("ToExpenseAs")
			Or AttributesStructure1.Property("ExpenseItem")
			Or Initialize Then
			
			Items.ExpenseItem.Visible = CurrentData.ToExpenseAs;
			Items.DimensionOfExpenses.Visible = CurrentData.ToExpenseAs
				And TypeOf(CurrentData.ExpenseItem) <> Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
			Items.AssetsLiabilitiesDimension.Visible = CurrentData.ToExpenseAs
				And TypeOf(CurrentData.ExpenseItem) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
			
			If Form.UseAccountingOfOtherAssetsAndLiabilities Then
				Items.TransactionRecordingPresentation.Visible = CurrentData.ToExpenseAs
					And TypeOf(CurrentData.ExpenseItem) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
			EndIf;
			
			Items.Recipient.InputHint = ?(CurrentData.ToExpenseAs, CurrentData.Department, "");
			
		EndIf;
		
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("ExpenseItem")
			Or Initialize Then
			
			Items.DimensionOfExpenses.Enabled = ValueIsFilled(CurrentData.ExpenseItem);
			Items.DimensionOfExpenses.InputHint = ?(ValueIsFilled(CurrentData.ExpenseItem),
				"",
				NStr("vi = '<hãy chọn dạng chi phí>';
					|ru = '<выберите статью расходов>';
					|en = '<select an expense item>'; fa = '<select an expense item>';
					|it = '<selezionare la voce delle spese>';
					|pl = '<wybierz pozycję wydatków>';
					|tr = '<gider kalemini seçin>'"));
			
			Items.AssetsLiabilitiesDimension.Enabled = ValueIsFilled(CurrentData.ExpenseItem);
			Items.AssetsLiabilitiesDimension.InputHint = ?(ValueIsFilled(CurrentData.ExpenseItem),
				"",
				NStr("vi = '<hãy chọn dạng chi phí>';
					|ru = '<выберите статью расходов>';
					|en = '<select an expense item>'; fa = '<select an expense item>';
					|it = '<selezionare la voce delle spese>';
					|pl = '<wybierz pozycję wydatków>';
					|tr = '<gider kalemini seçin>'"));
			
		EndIf;
		
		// Header elements design: Continue processing
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("ContinueProcessing")
			Or AttributesStructure1.Property("Action")
			Or AttributesStructure1.Property("Stage")
			Or AttributesStructure1.Property("Settings")
			Or AttributesStructure1.Property("ChangeProductToBeReleased")
			Or Initialize Then
			
			ShowContinuedProcessing = CurrentData.ContinueProcessing
				And (Object.Action = Actions.Split And Not Object.FromBeginningOfParty
					Or Object.Action = Actions.DefectiveGoods
					Or Object.Action = Actions.Continue);
			
			Items.GroupFinishedProduct.ShowTitle = ShowContinuedProcessing;
			Items.NewFinishedProductGroup.Visible = ShowContinuedProcessing
				And CurrentData.ChangeProductToBeReleased;
			Items.ContinueGroupBillOfMaterials.Visible = ShowContinuedProcessing;
			Items.BatchChangeFINISHEDProduct.Visible = ShowContinuedProcessing
				And (Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly")
				Or Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Repair")
				Or Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM"));
			
		EndIf;
		
		// Design of header elements: Batch size
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("Action")
			Or AttributesStructure1.Property("ContinueProcessing")
			Or AttributesStructure1.Property("Stage")
			Or Initialize Then
			
			Items.GroupBatchSize.Visible = 
				Object.Action = Actions.Reduce
				Or (
					Object.Action = Actions.Split
					And 	(
						Object.FromBeginningOfParty
						Or CurrentData.ContinueProcessing
						)
					);
			
		EndIf;
		
		// Design of header elements: Party assignments
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("SpecifyTargets")
			Or Initialize Then
			
			Items.SpecifyDestinations.Enabled = CurrentData.SpecifyTargets;
			Items.ThereAreErrorsInFillingOutAssignments.Visible = CurrentData.SpecifyTargets;
			
		EndIf;
		
		// Header elements design: Number of intermediate issues
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("AutomaticCalculationOfQuantity")
			Or Initialize Then
			
			Items.GroupQuantity.Visible = Not CurrentData.AutomaticCalculationOfQuantity;
			
		EndIf;
		
		// Header elements design: Continue stage
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("ContinueBOM")
			Or Initialize Then
			
			Items.ContinueStagePresentation.Enabled = Not CurrentData.ContinueBOM.IsEmpty();
			Items.ContinueStagePresentation.InputHint = ?(Not CurrentData.ContinueBOM.IsEmpty(),
				"",
				NStr("vi = '<hãy chọn bảng kê chi tiết>';
					|ru = '<выберите спецификацию>';
					|en = '<select a bill of materials>'; fa = '<select a bill of materials>';
					|it = '<выберите спецификацию>';
					|pl = '<select a bill of materials>';
					|tr = '<ürün reçetesi seçin>'"));
			
		EndIf;
		
		// Header elements design: Cancel the finished product in the order
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("Action")
			Or AttributesStructure1.Property("Stage")
			Or AttributesStructure1.Property("ChangeProductToBeReleased")
			Or AttributesStructure1.Property("ContinueProcessing")
			Or AttributesStructure1.Property("LotQuantity")
			Or Initialize Then
			
			YouCanCancelFINISHEDProductInOrder = YouCanCancelFINISHEDProductInOrder(Form, CurrentData);
			Items.GroupCancelFinishedProductInOrder.Visible = YouCanCancelFINISHEDProductInOrder;
			
			ThisIsFINISHEDProductChange = YouCanCancelFINISHEDProductInOrder
				And CurrentData.ContinueProcessing
				And CurrentData.ChangeProductToBeReleased;
			
			Template = ?(ThisIsFINISHEDProductChange,
				NStr("vi = 'Thay đổi sản phẩm trong <a href=""%1"">đơn hàng</a> theo nguyên nhân:';
					|ru = 'Изменить изделие в <a href=""%1"">заказе</a> по причине:';
					|en = 'Change the finished product in the <a href=""%1"">order</a>. Reason:'; fa = 'Change the finished product in the <a href=""%1"">order</a>. Reason:';
					|it = 'Изменить изделие в <a href=""%1"">заказе</a> по причине:';
					|pl = 'Change the finished product in the <a href=""%1"">order</a>. Reason:';
					|tr = '<a href=""%1"">Siparişteki</a> nihai ürünü şu sebeple değiştir:'"),
				NStr("vi = 'Hủy bỏ sản phẩm trong <a href=""%1"">đơn hàng</a> theo nguyên nhân:';
					|ru = 'Отменить изделие в <a href=""%1"">заказе</a> по причине:';
					|en = 'Cancel the finished product in the <a href=""%1"">order</a>. Reason:'; fa = 'Cancel the finished product in the <a href=""%1"">order</a>. Reason:';
					|it = 'Отменить изделие в <a href=""%1"">заказе</a> по причине:';
					|pl = 'Cancel the finished product in the <a href=""%1"">order</a>. Reason:';
					|tr = '<a href=""%1"">Siparişteki</a> nihai ürünü şu sebeple iptal et:'"));
			URL = GetURL(Object.ReferenceOrder);
			#If Client Then
				Items.CancelFinishedProductInOrderHeader.Title = StringFunctionsClient.FormattedString(
					Template, URL);
			#Else
				Items.CancelFinishedProductInOrderHeader.Title = StringFunctions.FormattedString(
					Template, URL);
			#EndIf
			
		EndIf;
		
		If AttributesStructure1.Property("CurrentBatch")
			Or AttributesStructure1.Property("CancelChangeFinishedProductInOrder")
			Or Initialize Then
			
			Items.ReasonForCancelingFinishedProduct.Enabled = CurrentData.CancelChangeFinishedProductInOrder;
			
		EndIf;
		
	EndIf;
	
	If Initialize Then
		Items.SimpleMode.Enabled = Form.Settings.SimpleModeIsAvailable;
		Items.SimpleMode.ToolTipRepresentation = ?(Form.Settings.SimpleModeIsAvailable,
			ToolTipRepresentation.None,
			ToolTipRepresentation.Button);
	EndIf;
	
EndProcedure

#EndRegion

#Region Lots

&AtClient
Procedure WhenChangingAction()
	
	WhenChangingActionOnServer();
	WhenYouStartEditingBatch();
	
EndProcedure

&AtServer
Procedure WhenChangingActionOnServer()
	
	Data_Stage = Data_Stage(Object, ProductUnitOfMeasurement);
	If Data_Stage <> Undefined Then
		FillInAccordingToStageData(Data_Stage);
		ReadAutoSelectionParameters();
	EndIf;
	
	SetUpLotReferences();
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure SetUpLotReferences(Settings_Changed = False)
	
	Actions = Actions();
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	// Number of parties
	If Object.Action = Actions().DefectiveGoods Then
		QuantityOfBatches = ?(Object.NumberOfPackagingUnitsNonconformity < Object.NumberOfPackages And Not Object.ThisIsLastStageAndOperation, 2, 1);
	ElsIf Object.Action = Actions.Split
		And SimpleMode Then
		If ReleaseOfFinishedproducts.Count() > 0 Then
			QuantityOfBatches = ReleaseOfFinishedproducts.Count();
			TheNumberOfPartiesToShare = ReleaseOfFinishedproducts.Count();
		Else
			QuantityOfBatches = 2;
			TheNumberOfPartiesToShare = 2;
		EndIf;
	EndIf;
	
	// Party composition
	If Object.Lots.Count() <> QuantityOfBatches Then
		If Object.Lots.Count() < QuantityOfBatches Then
			// Adding batches
			For IndexOf = Object.Lots.Count() To QuantityOfBatches-1 Do
				AddBatch(IndexOf);
				If IndexOf <> 0 Then
					NewItem = Items.Insert(
						"Lot" + Format(IndexOf, "ND=3; NZ=000; NLZ="),
						Type("FormDecoration"),
						Items.HyperlinkGroupSplit,
						Items.Lot100);
					NewItem.Type = FormDecorationType.Label;
					NewItem.Title = StrTemplate(NStr("vi = 'Lô hàng %1';
													|ru = 'Партия %1';
													|en = 'Lot %1'; fa = 'Lot %1';
													|it = 'Letto %1';
													|pl = 'Partia %1';
													|tr = '%1 lotu'"), IndexOf + 1);
					NewItem.Hyperlink = True;
					NewItem.TextColor = ColorNotSelectedLink;
					NewItem.SetAction("Click", "Attachable_HyperlinkLotReferenceSplitClick");
				EndIf;
			EndDo;
		ElsIf Object.Lots.Count() > QuantityOfBatches Then
			// Deleting batches
			For IndexOf = -Object.Lots.Count()+1 To -QuantityOfBatches Do
				Object.Lots.Delete(-IndexOf);
				
				For Each String In Object.SetOfSeries.FindRows(New Structure("LotIndex", -IndexOf)) Do
					Object.SetOfSeries.Delete(String);
				EndDo;
				
				Items.Delete(Items["Lot" + Format(-IndexOf, "ND=3; NZ=000; NLZ=")]);
			EndDo;
		EndIf;
		
		If CurrentBatch <> PartyIndexes().AllBatches
			And CurrentBatch > QuantityOfBatches-1 Then
			CurrentBatch = QuantityOfBatches-1;
		EndIf;
		
	EndIf;
	
	If CurrentBatch = PartyIndexes().AllBatches Then
		If Object.Action = Actions.Split Then
			If Object.Lots.FindByID(Items.Lots.CurrentRow) = Undefined Then
				Items.Lots.CurrentRow = Object.Lots[QuantityOfBatches-1].GetID();
			EndIf;
		Else
			CurrentBatch = 0;
			PreviousBatch = PartyIndexes().AllBatches;
		EndIf;
	ElsIf SimpleMode
		And (Object.Action = Actions.DefectiveGoods Or Object.Action = Actions.Cancel) Then
		CurrentBatch = 0;
	EndIf;
	
	// The Size of the Lot Reference, depending on the action
	ThisIsDivisionOfOperationStarted = False;
	If Object.Action = Actions.Continue Then
		String = Object.Lots[0];
		String.PackageOfLot = Object.Package;
		String.LotNumberOfPackages = Object.NumberOfPackages;
		String.LotQuantity = Object.Count;
		String.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(String);
	ElsIf Object.Action = Actions.DefectiveGoods
		And QuantityOfBatches = 2 Then
		String = Object.Lots[0];
		String.PackageOfLot = Object.Package;
		String.LotNumberOfPackages = Object.NumberOfPackagingUnitsNonconformity;
		String.LotQuantity = CalculateNumberOfBatchUnits(
			Object.MainProductProducts,
			String.PackageOfLot,
			String.LotNumberOfPackages);
		String.CostShare = Object.NumberOfPackagingUnitsNonconformity;
		
		String = Object.Lots[1]; // Balance Of The Lot Reference
		String.PackageOfLot = Object.Package;
		String.LotNumberOfPackages = Object.NumberOfPackages - Object.NumberOfPackagingUnitsNonconformity;
		String.LotQuantity = CalculateNumberOfBatchUnits(
			Object.MainProductProducts,
			String.PackageOfLot,
			String.LotNumberOfPackages);
		String.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(String);
		String.CostShare = String.LotNumberOfPackages;
		
		// The Balance Of The Lot Reference From The next operation/Stage
		If Object.OperationID <> 0 Then
			LotReferenceTree = GetFromTempStorage(AddressProductionProcessLotReference); // See DataProcessors.ProductionLotDivision.TreeProductionProcess
			LotReferenceOperation = LotReferenceTree.Rows.Find(Object.OperationID, "OperationID", True);
			OperationIsFullyScheduled = LotReferenceOperation <> Undefined
				And LotReferenceOperation.OperationsToDestination = 0;
			
			NextOperation = Undefined;
			NextStage = Undefined;
			FindNextPointOfProductionProcess(NextOperation, NextStage);
			
			If OperationIsFullyScheduled
				And (NextOperation <> Undefined
					Or NextStage <> Undefined) Then
				String.ContinueBOM = Object.BillOfMaterials;
				String.AddressProductionProcess = AddressProductionProcess;
				
				If NextOperation <> Undefined Then
					String.ContinueStage = BOMStage;
					String.ContinueStagePresentation = StrTemplate("%1 / %2", String(BOMStage), NextOperation.Description);
					String.ContinueStageDepartment = BillOfMaterialsStageDepartment;
					String.Continue_Operation = NextOperation.Ref;
					String.ContinueOperationID = NextOperation.OperationID;
				Else
					String.ContinueStage = NextStage.Ref;
					String.ContinueStagePresentation = NextStage.Description;
					String.ContinueStageDepartment = NextStage.Department;
					String.Continue_Operation = Undefined;
					String.ContinueOperationID = 0;
				EndIf;
				
				String.ChangeProductToBeReleased = False;
				String.ContinueItem = Object.MainProductProducts;
				String.ContinueVariant = Object.MainProductCharacteristic;
				String.CancelChangeFinishedProductInOrder = False;
				String.ReasonForCancelingFinishedProduct = Undefined;
			EndIf;
		EndIf;
	ElsIf Object.Action = Actions.DefectiveGoods
		And Object.ThisIsLastStageAndOperation
		And Not Object.CostSharesAreFilledInStage
		And Not SimpleMode Then
		Object.Lots[0].CostShare = Object.NumberOfPackagingUnitsNonconformity * PackagingFactor;
	ElsIf Object.Action = Actions.Split
		And QuantityOfBatches = 2
		And Object.OperationID <> 0 Then
		LotReferenceTree = GetFromTempStorage(AddressProductionProcessLotReference); // See DataProcessors.ProductionLotDivision.TreeProductionProcess
		LotReferenceOperation = LotReferenceTree.Rows.Find(Object.OperationID, "OperationID", True);
		OperationWasPartiallyPerformed = LotReferenceOperation <> Undefined
			And LotReferenceOperation.OperationsTotal > LotReferenceOperation.OperationsToDestination
			And LotReferenceOperation.OperationsToDestination > 0;
		
		NextOperation = Undefined;
		NextStage = Undefined;
		FindNextPointOfProductionProcess(NextOperation, NextStage);
		
		If OperationWasPartiallyPerformed
			And (NextOperation <> Undefined
				Or NextStage <> Undefined) Then
			ThisIsDivisionOfOperationStarted = True;
			
			// First Lot Reference - continue With the next operation
			String = Object.Lots[0];
			
			String.ContinueBOM = Object.BillOfMaterials;
			String.AddressProductionProcess = AddressProductionProcess;
			
			If NextOperation <> Undefined Then
				String.ContinueStage = BOMStage;
				String.ContinueStagePresentation = StrTemplate("%1 / %2", String(BOMStage), NextOperation.Description);
				String.ContinueStageDepartment = BillOfMaterialsStageDepartment;
				String.Continue_Operation = NextOperation.Ref;
				String.ContinueOperationID = NextOperation.OperationID;
			Else
				String.ContinueStage = NextStage.Ref;
				String.ContinueStagePresentation = NextStage.Description;
				String.ContinueStageDepartment = NextStage.Department;
				String.Continue_Operation = Undefined;
				String.ContinueOperationID = 0;
			EndIf;
			
			String.ChangeProductToBeReleased = False;
			String.ContinueItem = Object.MainProductProducts;
			String.ContinueVariant = Object.MainProductCharacteristic;
			String.CancelChangeFinishedProductInOrder = False;
			String.ReasonForCancelingFinishedProduct = Undefined;
			
			String.LotNumberOfPackages = Object.NumberOfPackages
				* (LotReferenceOperation.OperationsTotal - LotReferenceOperation.OperationsToDestination)
				/ LotReferenceOperation.OperationsTotal;
			String.PackageOfLot = Object.Package;
			String.LotQuantity = CalculateNumberOfBatchUnits(
				Object.MainProductProducts,
				String.PackageOfLot,
				String.LotNumberOfPackages);
			
			String.CostShare = String.LotNumberOfPackages;
			
			// Second Lot Reference - continue with the current operation
			String = Object.Lots[1];
			
			String.ContinueBOM = Object.BillOfMaterials;
			String.ContinueStage = BOMStage;
			String.ContinueStagePresentation = BOMStagePresentation;
			String.ContinueStageDepartment = BillOfMaterialsStageDepartment;
			String.Continue_Operation = Object.Operation;
			String.ContinueOperationID = Object.OperationID;
			String.AddressProductionProcess = AddressProductionProcess;
			
			String.ChangeProductToBeReleased = False;
			String.ContinueItem = Object.MainProductProducts;
			String.ContinueVariant = Object.MainProductCharacteristic;
			String.CancelChangeFinishedProductInOrder = False;
			String.ReasonForCancelingFinishedProduct = Undefined;
			
			String.LotNumberOfPackages = Object.NumberOfPackages - Object.Lots[0].LotNumberOfPackages;
			String.PackageOfLot = Object.Package;
			String.LotQuantity = CalculateNumberOfBatchUnits(
				Object.MainProductProducts,
				String.PackageOfLot,
				String.LotNumberOfPackages);
			
			String.CostShare = String.LotNumberOfPackages;
		EndIf;
	EndIf;
	
	FillInBatchesForProductionOfProducts = Object.Action = Actions.Split
		And QuantityOfBatches = ReleaseOfFinishedproducts.Count();
	
	If FillInBatchesForProductionOfProducts Then
		// Lot References Are filled in according To the Product release table
		// The last row in the table is the Balance For Production, the data of this row is edited on the form
		ReadyForProcessing_ = New Array;
		For IndexOf = 0 To ReleaseOfFinishedproducts.Count()-1 Do
			ProductionIssue = ReleaseOfFinishedproducts[IndexOf];
			String = Object.Lots[IndexOf];
			
			If ProductionIssue.ContinueProcessing Then
				String.TheDirectionOfTheReleaseForm = DirectionToContinueProcessing();
				WhenReleaseDirectionChangesForm(String, "");
				
				String.ItemsForm = Undefined;
				ConfigureProductsAutoselection(String, "");
				
				String.LotNumberOfPackages = ProductionIssue.NumberOfPackages;
				String.PackageOfLot = ProductionIssue.Package;
				String.LotQuantity = ProductionIssue.Count;
				
				If Not String.AutoSelectingItemsIsWork Then
					String.NumberOfPackages = String.LotNumberOfPackages;
					ReadyForProcessing_.Add(String);
				EndIf;
				
				String.Assignments.Clear();
				String.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(String);
				
				If String.ChangeProductToBeReleased Then
					InstallMainFinishedProduct(String);
				EndIf;
				
				String.CostShare = String.LotNumberOfPackages;
			Else
				// Products
				FillPropertyValues(String, ProductionIssue,
					"Products, Characteristic, Package, Count, NumberOfPackages");
				String.ItemsForm = String.Products;
				String.CharacteristicForm = String.Characteristic;
				String.Manufactured = True;
				ConfigureProductsAutoselection(String, "");
				BatchProductsWhenChangedOnServer(String);
				SetUpAutomaticQuantityCalculation(String, "");
				String.Recipient = ProductionIssue.Recipient;
				
				// The focus of the issue
				ChoiceList = SelectionListReleaseDirectionForm(ThisObject, String);
				If ChoiceList.FindByValue(Enums.BusinessTransactions.ProductsReleaseToWarehouse) <> Undefined Then
					String.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToWarehouse;
				Else
					String.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit;
				EndIf;
				WhenReleaseDirectionChangesForm(String, "");
				
				// Other banking details
				String.Purpose = ProductionIssue.Purpose;
				String.Assignments.Clear();
				String.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(String);
				String.CostShare = String.NumberOfPackages;
			EndIf;
		EndDo;
		
		If ReadyForProcessing_.Count() <> 0 Then
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateNumberOfUnits",
				ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
			
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				ReadyForProcessing_,
				StructureOfActions,
				Object.Lots,
				CachedValues);
		EndIf;
	ElsIf Not SimpleMode Then
		// General verification/Setup Of Lots Reference.
		// It is not needed if the Pro-Mode is enabled because in this case The Lot References Are Configured In - See SetUpSimpleMode.
		ReadyForProcessing_ = New Array;
		For Each String In Object.Lots Do
			// Use assignments
			String.SpecifyTargets = SpecifyTargets(Object.Action, Object.FromBeginningOfParty, String, Settings);
			
			// Direction of release (control)
			ChoiceList = SelectionListReleaseDirectionForm(ThisObject, String);
			If ChoiceList.FindByValue(String.TheDirectionOfTheReleaseForm) = Undefined Then
				If String.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit
					And ChoiceList.FindByValue(Enums.BusinessTransactions.ProductsReleaseToWarehouse) <> Undefined Then
					String.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToWarehouse;
				ElsIf String.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToWarehouse
					And ChoiceList.FindByValue(Enums.BusinessTransactions.ProductsReleaseToBusinessUnit) <> Undefined Then
					String.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit;
				Else
					String.TheDirectionOfTheReleaseForm = ChoiceList[0].Value;
				EndIf;
				WhenReleaseDirectionChangesForm(String, "");
			EndIf;
			
			// automatic selection of items
			ConfigureProductsAutoselection(String, "");
			
			// Automatic Calculation of Quantity
			If Not String.AutomaticSelectionOfItems Then
				SetUpAutomaticQuantityCalculation(String, "");
			EndIf;
			
			// Automatic calculation of quantity when Dividing
			If ThisIsDivisionOfOperationStarted
				And Not String.AutoSelectingItemsIsWork Then
				String.NumberOfPackages = String.LotNumberOfPackages;
				ReadyForProcessing_.Add(String);
			EndIf;
		EndDo;
		
		If ReadyForProcessing_.Count() <> 0 Then
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateNumberOfUnits",
				ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
			
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				ReadyForProcessing_,
				StructureOfActions,
				Object.Lots,
				CachedValues);
		EndIf;
	EndIf;
	
	// Filling in the recipient
	If Not FillInBatchesForProductionOfProducts Then
		PartyCopy = Object.Lots.Unload().CopyColumns();
		For Each String In Object.Lots Do
			If String.AutoSelectingItemsIsWork // For auto-operation, the recipient is a constant
				Or Settings_Changed And ValueIsFilled(String.Recipient) Then
				Continue;
			EndIf;
			LineCopy = PartyCopy.Add();
			FillPropertyValues(LineCopy, String);
			LineCopy.Department = ReceivingBusinessUnit(String);
		EndDo;
		
		StructureOfActions = New Structure;
		ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
			Undefined, StructureOfActions, "Recipient");
		BatchProcessingOfTablePartServer.TreatTS(PartyCopy, StructureOfActions, CachedValues);
		
		For Each LineCopy In PartyCopy Do
			Object.Lots[LineCopy.LotIndex].Recipient = LineCopy.Recipient;
			Object.Lots[LineCopy.LotIndex].ShopFloorStockroom = LineCopy.ShopFloorStockroom;
		EndDo;
	EndIf;
	
	// Setting up a simple mode
	If SimpleMode Then
		SetUpSimpleMode();
	EndIf;
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtClientAtServerNoContext
Function PartyIndexes()
	
	Return New Structure("AllBatches, Undefined", 100, -1);
	
EndFunction

&AtServer
Procedure InstallMainFinishedProduct(String)
	
	String.ChangeProductToBeReleased = False;
	String.ContinueItem = Object.MainProductProducts;
	String.ContinueVariant = Object.MainProductCharacteristic;
	
	String.ContinueBOM = Object.BillOfMaterials;
	String.ContinueStage = BOMStage;
	String.ContinueStagePresentation = BOMStagePresentation;
	String.ContinueStageDepartment = BillOfMaterialsStageDepartment;
	String.Continue_Operation = Object.Operation;
	String.ContinueOperationID = Object.OperationID;
	String.AddressProductionProcess = AddressProductionProcess;
	
	String.CancelChangeFinishedProductInOrder = False;
	String.ReasonForCancelingFinishedProduct = Undefined;
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(
		ThisObject, 
		SeriesSpecificationParameters, 
		Text, 
		CurrentData);
	
	If NeedServerCall Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.Lots.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		AdditionalParameters = New Structure("SeriesSpecificationParameters,ParametersOfSeriesIndicationForm", 
											SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName, 
						ParametersOfSeriesIndicationForm, 
						ThisObject,,,,
						CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(
		Object, 
		SeriesSpecificationParameters, 
		CurDataId, 
		ThisObject);
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeriesCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		ProcessSeriesIndication_Server(
				AdditionalParameters.SeriesSpecificationParameters, 
				AdditionalParameters.ParametersOfSeriesIndicationForm);
		ConfigureDependentFormElements(ThisObject, "BatchesIndicationStatuses");
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(Val SeriesSpecificationParameters, Val ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure;
	
	CurrentData = Object.Lots.FindByID(Items.Lots.CurrentRow);
	If Not CurrentData.AutomaticCalculationOfQuantity Then
		StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
		StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
		StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	EndIf;
	
	ProductsServer.ProcessSeriesIndication_(
		Object, 
		SeriesSpecificationParameters, 
		ParametersOfSeriesIndicationForm, 
		StructureOfActions);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
		Object, 
		SeriesSpecificationParameters,
		IDCurrentRow,
		CachedValues);
	
EndProcedure

#EndRegion

#Region CostShares

&AtClient
Procedure OpenCostShareEntryForm()

	If ProductionClient.CheckFillingBeforeEnteringCostFraction(
			Items.Lots.CurrentData,
			CostAllocationParameters) Then
		
		OpenForm("CommonForm.EnterCostShare",
			ParametersOfCostShareEntryForm_(Items.Lots.CurrentData.GetID()),
			ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingInputOfFractionOfCost(CurrentData, ValueSelected)
	
	If CurrentData.CostShare <> ValueSelected.CostShare Then
		
		ProductionClientServer.FillInCostFractionInLine(
			CurrentData,
			ValueSelected);
		CalculatePercentageOfCostAllocationForOutputProducts();
		ConfigureDependentFormElements(ThisObject, "CostSharePercentage")
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingMethodOfDistributionOfCostsForOutputProducts()
	
	CostAllocationParameters = New FixedStructure(
		DataProcessors.ProductionLotDivision.CostAllocationParameters(Object.MethodOfAllocatingFinishedProductCosts));
	
	ProductionServer.CalculateFractionOfCost(Object, CostAllocationParameters);
	CalculatePercentageOfCostAllocationForOutputProducts();
	
	ConfigureDependentFormElements(ThisObject, "MethodOfAllocatingFinishedProductCosts, CostSharePercentage");
	
EndProcedure

&AtServer
Procedure CalculatePercentageOfCostAllocationForOutputProducts()
	
	ProductionServer.CalculatePercentageOfCostAllocationForOutputProducts(Object, CostAllocationParameters);
	
EndProcedure

&AtServer
Function ParametersOfCostShareEntryForm_(CurDataId)
	
	Return ProductionServer.ParametersOfCostShareEntryForm(
		Object,
		CostAllocationParameters,
		CurDataId);
	
EndFunction

#EndRegion

#Region DirectionOfProductionIssue

&AtClient
Procedure FillInSelectionListReleaseDirectionForm()
	
	If Items.Lots.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Lots.FindByID(Items.Lots.CurrentRow);
	
	Items.TheDirectionOfTheReleaseForm.ChoiceList.Clear();
	Items.LotsTheDirectionOfTheReleaseForm.ChoiceList.Clear();
	
	For Each Item In SelectionListReleaseDirectionForm(ThisObject, CurrentData) Do
		Items.TheDirectionOfTheReleaseForm.ChoiceList.Add(Item.Value, Item.Presentation);
		Items.LotsTheDirectionOfTheReleaseForm.ChoiceList.Add(Item.Value, Item.Presentation);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function SelectionListReleaseDirectionForm(Form, CurrentData)
	
	Result = New ValueList;
	Actions = Actions();
	
	ThisIsDefectiveFinishedProduct = (Form.Object.Action = Actions.DefectiveGoods)
		And CurrentData.LineNumber = 1;
	ThisIsBalanceAfterNonconformity = (Form.Object.Action = Actions.DefectiveGoods)
		And CurrentData.LineNumber = 2;
	
	If Form.Object.Action <> Actions.Cancel
		And Not ThisIsDefectiveFinishedProduct Then
		Result.Add(DirectionToContinueProcessing(), NStr("vi = 'Tiếp tục xử lý';
														|ru = 'Продолжить обработку';
														|en = 'Continue processing'; fa = 'ادامه پردازش';
														|it = 'Continuare elaborazione';
														|pl = 'Kontynuuj przetworzenie';
														|tr = 'İşlemeye devam et'"));
	EndIf;
	
	If Form.Object.Action <> Actions.Continue Then
		For Each Item In ProductionManagementClientServer.ReleaseDirectionSelectionList(CurrentData, Form) Do
			If ThisIsBalanceAfterNonconformity
				And Item.Value = PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
				Continue;
			ElsIf (Form.Object.Action = Actions.Split Or ThisIsBalanceAfterNonconformity)
				And CurrentData.AutomaticSelectionOfItems
				And Item.Value = PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToBusinessUnit") Then
				// When the Item is Calculated Automatically, a Nonconforming Product is Delivered to the warehouse, and Not Work to the division
				// The Work is used only to continue processing
				Result.Add(
					PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse"),
					NStr("vi = 'Đến kho';
						|ru = 'На склад';
						|en = 'To warehouse'; fa = 'To warehouse';
						|it = 'Al magazzino';
						|pl = 'Na magazyn';
						|tr = 'Ambara'"));
			Else
				Result.Add(Item.Value, Item.Presentation);
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure WhenReleaseDirectionChangesForm(CurrentData, AttributesList, CachedValues = Undefined)
	
	If CurrentData.TheDirectionOfTheReleaseForm = DirectionToContinueProcessing() Then
		If CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods") Then
			CurrentData.DirectionOfProductionIssue = PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse");
		Else
			CurrentData.DirectionOfProductionIssue = PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToBusinessUnit");
		EndIf;
		CurrentData.ContinueProcessing = True;
	Else
		CurrentData.DirectionOfProductionIssue = CurrentData.TheDirectionOfTheReleaseForm;
		CurrentData.ContinueProcessing = False;
	EndIf;
	
	CurrentData.ToExpenseAs = CurrentData.DirectionOfProductionIssue
		= PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand");
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentData, "Object.Lots");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillAssignment", ActionParameterFillInAssignment(CurrentData));
	ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
		ReceivingBusinessUnit(CurrentData), StructureOfActions, "Recipient");
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If SpecifyRecipientType(CurrentData) Then
		RecipientWhenModifiedOnServer(CurrentData.GetID(), False, CachedValues);
	EndIf;
	
	CurrentData.SpecifyTargets = SpecifyTargets(
		Object.Action, Object.FromBeginningOfParty, CurrentData, Settings);
	
	AttributesList = AttributesList + ",ContinueProcessing, ToExpenseAs, SpecifyTargets, Recipient";
	
EndProcedure

&AtServer
Function SpecifyRecipientType(CurrentData)
	
	TypeRestriction = LimitingRecipientType(CurrentData);
	
	ValueBeforeChange = CurrentData.Recipient;
	CurrentData.Recipient = TypeRestriction.AdjustValue(CurrentData.Recipient);
	
	Items.Recipient.TypeRestriction = TypeRestriction;
	Items.LotsRecipient.TypeRestriction = TypeRestriction;
	
	Return CurrentData.Recipient <> ValueBeforeChange;
	
EndFunction

&AtClientAtServerNoContext
Function LimitingRecipientType(CurrentData)
	
	TypeRestriction = Undefined;
	If CurrentData.TheDirectionOfTheReleaseForm = DirectionToContinueProcessing() Then
		TypeRestriction = ?(CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods"),
			New TypeDescription("CatalogRef.Warehouses"),
			New TypeDescription("CatalogRef.BusinessStructure"));
	Else
		TypeRestriction = ?(CurrentData.TheDirectionOfTheReleaseForm = PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse"),
			New TypeDescription("CatalogRef.Warehouses"),
			New TypeDescription("CatalogRef.BusinessStructure"));
	EndIf;
	
	Return TypeRestriction;
	
EndFunction

&AtClientAtServerNoContext
Function DirectionToContinueProcessing()
	
	// Link to identify the "continue processing" action (there is no separate business operation)
	Return PredefinedValue("Enum.BusinessTransactions.TransferToProduction");
	
EndFunction

#EndRegion

#Region ActionsExecution

&AtServer
Function PerformActionInBackground()
	
	CreateAutoSelectionItem();
	
	If Not CheckFilling() Then
		Return False;
	EndIf;
	
	FillOutPartyAssignments();
	
	DataProcessorObject = FormAttributeToValue("Object");
	ProductsServer.ClearUnusedSeries(DataProcessorObject, SeriesSpecificationParameters);
	
	Lots = DataProcessorObject.Lots.Unload();
	Lots.Columns.Add("ManufacturedProductAssignments", New TypeDescription("ValueTable"));
	Lots.Columns.Add("AssignmentsOfMaterials", New TypeDescription("ValueTable"));
	
	For Each String In Lots Do
		FormString = Object.Lots[String.LineNumber-1];
		
		// Operation (continue)
		If Not String.Continue_Operation.IsEmpty() Then
			OperationProperties = PropertiesOfProductionProcessOperation(
				FormString.AddressProductionProcess,
				String.Continue_Operation,
				String.ContinueOperationID);
			String.Continue_Operation = OperationProperties.Operation;
			String.ContinueOperationID = OperationProperties.OperationID;
			String.ContinueThisIsFirstOperation = OperationProperties.ThisIsFirstOperation;
		EndIf;
		
		// Assignments
		String.ManufacturedProductAssignments = FormString.Assignments.Unload();
		String.AssignmentsOfMaterials = FormString.AssignmentsOfMaterials.Unload();
		
		// Cancel The FINISHEDProduct In The Order
		If String.CancelChangeFinishedProductInOrder
			And Not YouCanCancelFINISHEDProductInOrder(ThisObject, String) Then
			String.CancelChangeFinishedProductInOrder = False;
			String.ReasonForCancelingFinishedProduct = Undefined;
		EndIf;
		
		// From the point of view of the document, the initial nomenclature is an intermediate issue (including other quality)
		If Not String.ProductsOfOriginalQuality.IsEmpty()
			And Not Object.IntermediateProductItem.IsEmpty() Then
			String.ProductsOfOriginalQuality = Object.IntermediateProductItem;
			String.VariantOfOriginalQuality = Object.IntermediateProductVariant;
		EndIf;
	EndDo;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Lots", Lots);
	ProcedureParameters.Insert("SetOfSeries", DataProcessorObject.SetOfSeries.Unload());
	ProcedureParameters.Insert("FormIdentifier", UUID);
	
	For Each Attribute In DataProcessorObject.Metadata().Attributes Do
		ProcedureParameters.Insert(Attribute.Name, DataProcessorObject[Attribute.Name]);
	EndDo;
	
	For Each KeyAndValue In Settings Do
		ProcedureParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.RecordFormSInvoiceSettings(ThisObject);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Chia (giảm, hủy) của một lô sản xuất';
														|ru = 'Деление (сокращение, отмена) партии производства';
														|en = 'Delete (reduce, cancel) production lot'; fa = 'Delete (reduce, cancel) production lot';
														|it = 'Divisione (riduzione, annullamento) di un lotto di produzione';
														|pl = 'Dzielenie (zmniejszenie, anulowanie) partii produkcji';
														|tr = 'Üretim lotunun bölünmesi (azaltılması, iptali)'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ProductionLotDivision.PerformActionInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		StartWaiting = True;
		
	Else
		
		ProcessActionInBackground(TimeConsumingOperation);
		
		StartWaiting = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
	Return StartWaiting;
	
EndFunction

&AtClient
Procedure PerformActionInBackgroundCompletion(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		ProcessActionInBackground(Result);
		
		If OperationCompleted Then
			Notify("ChangingSequenceOfStages", Object.ProductionLot);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessActionInBackground(Result)
	
	If Result.Status = "Error" Then
		
		Raise Result.BriefErrorDescription;
		
	ElsIf Result.Status = "Completed2" Then
		
		ResultStructure = GetFromTempStorage(Result.ResultAddress);
		If TypeOf(ResultStructure) = Type("Structure") Then
		
			For Each Message In ResultStructure.Messages Do
				CommonClientServer.MessageToUser(Message);
			EndDo;
			
			If Not ResultStructure.Cancel Then
				OperationCompleted = True;
				ShowExecutionResult(ResultStructure)
			EndIf;
			
		EndIf;
		
		// Saving form settings
		If Settings.EasyModeWhenOpening <> SimpleMode Then
			SettingsValue = New Structure;
			SettingsValue.Insert("EasyModeWhenOpening", SimpleMode);
			Common.CommonSettingsStorageSave(
				"DataProcessor.ProductionLotDivision", "FormSettings", SettingsValue);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ShowExecutionResult(References)
	
	// Sample data
	Stages = New ValueTable;
	Stages.Columns.Add("Ref", New TypeDescription("DocumentRef.ProductionStage2_2"));
	Stages.Columns.Add("LongDesc", New TypeDescription("String",, New StringQualifiers(50)));
	Stages.Columns.Add("Created", New TypeDescription("Boolean"));
	Stages.Columns.Add("Changed", New TypeDescription("Boolean"));
	Stages.Columns.Add("HasErrors", New TypeDescription("Boolean"));
	
	If References.Property("StageRemoved") Then
		For Each Ref In References.StageRemoved Do
			NewRow = Stages.Add();
			NewRow.Ref = Ref;
			NewRow.LongDesc = NStr("vi = 'Đã xóa';
									|ru = 'Удален';
									|en = 'Removed'; fa = 'حذف‌شده';
									|it = 'Eliminato';
									|pl = 'Removed';
									|tr = 'Silindi'");
			NewRow.HasErrors = False;
		EndDo;
	EndIf;
	
	If References.Property("StageIsNotRecorded") Then
		For Each Ref In References.StageIsNotRecorded Do
			If Stages.Find(Ref, "Ref") <> Undefined Then
				Continue;
			EndIf;
			NewRow = Stages.Add();
			NewRow.Ref = Ref;
			NewRow.LongDesc = NStr("ru = 'Ошибка при записи, необходимо изменить вручную';
									|vi = 'An error occurred while saving, manual change is required';
									|en = 'An error occurred while saving, manual change is required'; fa = 'An error occurred while saving, manual change is required';
									|it = 'An error occurred while saving, manual change is required';
									|pl = 'An error occurred while saving, manual change is required';
									|tr = 'Kayıt sırasında hata, manuel olarak düzeltilmelidir'");
			NewRow.HasErrors = True;
		EndDo;
	EndIf;
	
	If References.Property("StageCreated") Then
		For Each Ref In References.StageCreated Do
			If Stages.Find(Ref, "Ref") <> Undefined Then
				Continue;
			EndIf;
			NewRow = Stages.Add();
			NewRow.Ref = Ref;
			NewRow.LongDesc = NStr("vi = 'Ngày tạo';
									|ru = 'Создан';
									|en = 'Created'; fa = 'ایجادشده';
									|it = 'Creato';
									|pl = 'Created';
									|tr = 'Oluşturuldu'");
			NewRow.Created = True;
			NewRow.HasErrors = False;
		EndDo;
	EndIf;
	
	If References.Property("ChangedStage") Then
		For Each Ref In References.ChangedStage Do
			If Stages.Find(Ref, "Ref") <> Undefined Then
				Continue;
			EndIf;
			NewRow = Stages.Add();
			NewRow.Ref = Ref;
			NewRow.LongDesc = NStr("vi = 'Thay đổi';
									|ru = 'Изменен';
									|en = 'Changed'; fa = 'تغییریافته';
									|it = 'Modificato';
									|pl = 'Changed';
									|tr = 'Değiştirildi'");
			NewRow.Changed = True;
			NewRow.HasErrors = False;
		EndDo;
	EndIf;
	
	Query = New Query(
		"SELECT
		|	Stages.Ref   AS Ref,
		|	Stages.LongDesc AS LongDesc,
		|	Stages.Created   AS Created,
		|	Stages.Changed  AS Changed,
		|	Stages.HasErrors AS HasErrors
		|INTO TTStages
		|FROM
		|	&Stages AS Stages
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductionStage2_2.ProductionLot           AS ProductionLot,
		|	ProductionStage2_2.ProductionLot.Code       AS BatchCode,
		|	ProductionStage2_2.ProductionLot.MainProductProducts AS BatchProducts,
		|	ProductionStage2_2.Ref                       AS Ref,
		|	ProductionStage2_2.Status                       AS Status,
		|	ProductionStage2_2.NumberOfPackagesPlan       AS NumberOfPackages,
		|	ProductionStage2_2.PackagePlan                 AS Package,
		|	ProductionStage2_2.Number                        AS Number,
		|	ProductionStage2_2.ReferenceOrder.Number           AS TheNumberOfTheOrder,
		|	ProductionStage2_2.StageName            AS StageName,
		|	ISNULL(TTStages.LongDesc, &DescriptionHasNotChanged) AS LongDesc,
		|	CASE
		|		WHEN ProductionStage2_2.DeletionMark
		|			THEN 2
		|		WHEN ProductionStage2_2.Posted
		|			THEN 1
		|		ELSE 0
		|	END                                            AS PictureNumber,
		|	(ISNULL(TTStages.Created, FALSE)
		|		OR ISNULL(TTStages.Changed, FALSE))
		|	AND (ProductionStage2_2.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
		|		OR (NOT ProductionStage2_2.Posted AND NOT ProductionStage2_2.DeletionMark))
		|	OR ISNULL(TTStages.HasErrors, FALSE)           AS HasErrors
		|FROM
		|	Document.ProductionStage2_2 AS ProductionStage2_2
		|	
		|	LEFT JOIN TTStages AS TTStages
		|	ON ProductionStage2_2.Ref = TTStages.Ref
		|WHERE
		|	ProductionStage2_2.ProductionLot IN
		|		(SELECT
		|			CAST(TTStages.Ref AS Document.ProductionStage2_2).ProductionLot
		|		FROM
		|			TTStages)
		|	AND (ProductionStage2_2.Posted OR TTStages.Ref IS NOT NULL)
		|
		|ORDER BY
		|	ProductionLot,
		|	ProductionStage2_2.StageNumber,
		|	ProductionStage2_2.NextStageNo
		|AUTOORDER
		|TOTALS BY
		|	ProductionLot");
	Query.SetParameter("Stages", Stages);
	Query.SetParameter("DescriptionHasNotChanged", NStr("vi = 'Không thay đổi';
														|ru = 'Не изменялся';
														|en = 'has not been changed'; fa = 'has not been changed';
														|it = 'Non è stato modificato';
														|pl = 'Nie był zmieniany';
														|tr = 'Değiştirilmedi'"));
	SampleResults = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	// Tree output
	ExecutionResult.GetItems().Clear();
	
	While SampleResults.Next() Do
		
		StringBatch = ExecutionResult.GetItems().Add();
		StringBatch.Ref = SampleResults.ProductionLot;
		
		StringBatch.HidePicture = True;
		
		Selection = SampleResults.Select();
		While Selection.Next() Do
			
			If IsBlankString(StringBatch.Presentation) Then
				StringBatch.Presentation = PartyPresentation(Selection.BatchCode, Selection.TheNumberOfTheOrder);
			EndIf;
			
			NewRow = StringBatch.GetItems().Add();
			FillPropertyValues(NewRow, Selection,
				"Ref, Status, LongDesc, PictureNumber, NumberOfPackages, Package, BatchProducts, HasErrors");
			NewRow.Presentation = Documents.ProductionStage2_2.PresentationStage(Selection);
			
		EndDo;
		
	EndDo;
	
	If References.Property("AdjustmentCreated") Then
		
		AttributesValues = Common.ObjectsAttributesValues(
			References.AdjustmentCreated,
			"Posted, Presentation");
		For Each Item In AttributesValues Do
			NewRow = ExecutionResult.GetItems().Add();
			NewRow.Ref = Item.Key;
			NewRow.Presentation = Item.Value.Presentation;
			NewRow.PictureNumber = ?(Item.Value.Posted, 1, 0);
			NewRow.LongDesc = NStr("vi = 'Ngày tạo';
									|ru = 'Создан';
									|en = 'Created'; fa = 'ایجادشده';
									|it = 'Creato';
									|pl = 'Created';
									|tr = 'Oluşturuldu'");
			NewRow.HasErrors = Not Item.Value.Posted;
		EndDo;
		
	EndIf;
	
	If References.Property("OrderChanged") Then
		
		AttributesValues = Common.ObjectsAttributesValues(
			References.OrderChanged,
			"Number, Date, Posted, Status");
		For Each Item In AttributesValues Do
			NewRow = ExecutionResult.GetItems().Add();
			NewRow.Ref = Item.Key;
			NewRow.Presentation = Documents.ProductionOrder2_2.OrderPresentation(
				Item.Key,, Item.Value);
			NewRow.PictureNumber = ?(Item.Value.Posted, 1, 0);
			NewRow.LongDesc = NStr("vi = 'Thay đổi';
									|ru = 'Изменен';
									|en = 'Changed'; fa = 'تغییریافته';
									|it = 'Modificato';
									|pl = 'Changed';
									|tr = 'Değiştirildi'");
			NewRow.HasErrors = Not Item.Value.Posted;
			NewRow.Status = Item.Value.Status;
		EndDo;
		
	EndIf;
	
	// Setting up the form
	Items.GroupSteps.CurrentPage = Items.ResultsPage;
	Items.ExecuteAction.Visible = False;
	Items.Close.Visible = True;
	Items.SimpleMode.Visible = False;
	
EndProcedure

#EndRegion

#Region PartyAssignments

&AtClient
Procedure OpenAppointmentSelection()
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Object.MainProductProducts);
	FormParameters.Insert("Package", Items.Lots.CurrentData.PackageOfLot);
	FormParameters.Insert("NumberOfPackages", Items.Lots.CurrentData.LotNumberOfPackages);
	
	TableAddresses = UploadTablesForSelectingAppointments(Items.Lots.CurrentRow);
	FormParameters.Insert("AddressStandards", TableAddresses.AddressStandards);
	FormParameters.Insert("AddressSelected", TableAddresses.AddressSelected);
	
	CallbackDescription = New CallbackDescription("SpecifyDestinationsCompletion", ThisObject);
	
	OpenForm("DataProcessor.ProductionLotDivision.Form.AssignmentSelection",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function UploadTablesForSelectingAppointments(RowID)
	
	String = Object.Lots.FindByID(RowID);
	
	Result = New Structure;
	Result.Insert(
		"AddressStandards",
		PutToTempStorage(AssignmentsStandards.Unload()));
	Result.Insert(
		"AddressSelected",
		PutToTempStorage(String.Assignments.Unload()));
	
	Return Result;
	
EndFunction

&AtClient
Procedure SpecifyDestinationsCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		UploadResultOfSelectionOfAppointments(ClosingResult, Items.Lots.CurrentRow);
	EndIf;
	
EndProcedure

&AtServer
Procedure UploadResultOfSelectionOfAppointments(CalculationResult1, RowID)
	
	String = Object.Lots.FindByID(RowID);
	If CalculationResult1.Count <> 0 Then
		String.LotNumberOfPackages = CalculationResult1.NumberOfPackages;
		String.LotQuantity = CalculationResult1.Count;
	EndIf;
	String.Assignments.Load(GetFromTempStorage(CalculationResult1.DestinationAddress));
	String.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(String);
	
EndProcedure

&AtClientAtServerNoContext
Function SpecifyTargets(Action, FromBeginningOfParty, CurrentData, Settings)
	
	Actions = Actions();
	
	Return
		Action = Actions.Split
			And (FromBeginningOfParty Or CurrentData.ContinueProcessing And Settings.FillInByBOM)
		Or Action = Actions.Reduce And Settings.FillInByBOM;
	
EndFunction

&AtClientAtServerNoContext
Function ThereAreErrorsInFillingOutAssignments(CurrentData)
	
	If CurrentData.Assignments.Count() = 0 Then
		Return False;
	EndIf;
	
	NumberOfAssignments = 0;
	For Each String In CurrentData.Assignments Do
		NumberOfAssignments = NumberOfAssignments + String.Count;
	EndDo;
	
	Return NumberOfAssignments <> CurrentData.LotQuantity;
	
EndFunction

&AtServer
Procedure FillOutPartyAssignments()
	
	Actions = Actions();
	
	If AssignmentsStandards.Count() <= 1
		Or Object.Action = Actions.Cancel Then
		Return;
	EndIf;
	
	If Object.Action = Actions.Continue Then
		
		Object.Lots[0].Assignments.Load(AssignmentsStandards.Unload());
		
	Else
		
		Table = AssignmentsStandards.Unload();
		Table.Indexes.Add("Purpose");
		
		Rows = New Array;
		For Each String In Object.Lots Do
			If Not String.SpecifyTargets Then
				Continue;
			ElsIf String.Assignments.Count() = 0 Then
				Rows.Add(String);
			Else
				
				For Each AssignmentRow In String.Assignments Do
					FoundRow = Table.Find(AssignmentRow.Purpose, "Purpose");
					If FoundRow <> Undefined Then
						If FoundRow.Count <= AssignmentRow.Count Then
							Table.Delete(FoundRow);
						Else
							FoundRow.Count = FoundRow.Count - AssignmentRow.Count;
						EndIf;
					EndIf;
				EndDo;
				
			EndIf;
		EndDo;
		
		For Each String In Rows Do
			
			Balance = String.LotQuantity;
			
			For IndexOf = 0 To Table.Count()-1 Do
				
				Line1_ = Table[IndexOf];
				If Line1_.Count = 0 Then
					Continue;
				EndIf;
				
				NewRow = String.Assignments.Add();
				NewRow.Purpose = Line1_.Purpose;
				NewRow.Count = Min(Line1_.Count, Balance);
				
				Line1_.Count = Line1_.Count - NewRow.Count;
				Balance = Balance - NewRow.Count;
				If Balance = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
			If Balance <> 0 Then
				TheStructureOfTheSearch = New Structure("Purpose", Catalogs.Assignments.EmptyRef());
				FoundRows = String.Assignments.FindRows(TheStructureOfTheSearch);
				If FoundRows.Count() = 0 Then
					NewRow = String.Assignments.Add();
					NewRow.Count = Balance;
				Else
					FoundRows[0].Count = FoundRows[0].Count + Balance;
				EndIf;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Products_1 = New ValueTable;
	Products_1.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Products_1.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Products_1.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	Products_1.Columns.Add("Count", New TypeDescription("Number"));
	
	For Each String In Object.Lots Do
		If String.SpecifyTargets Or Object.Action = Actions.Continue Then
			
			For Each AssignmentRow In String.Assignments Do
				NewRow = Products_1.Add();
				NewRow.Products = Object.MainProductProducts;
				NewRow.Characteristic = Object.MainProductCharacteristic;
				FillPropertyValues(NewRow, AssignmentRow, "Purpose, Count");
			EndDo;
			
			AssignmentsOfMaterials = ProductionSupply.CoefficientsOfSecurityAssignmentsInProductionStage(Object, Products_1);
			If AssignmentsOfMaterials <> Undefined Then
				String.AssignmentsOfMaterials.Load(AssignmentsOfMaterials);
			EndIf;
			
			Products_1.Clear();
			
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region AutomaticSelectionOfItems

&AtServer
Procedure ReadAutoSelectionParameters()
	
	ParametersStructure_ = New Structure;
	ParametersStructure_.Insert("UseWork", False);
	
	// Work_5
	ParametersStructure_.Insert("Work_5", Catalogs.Products.EmptyRef());
	ParametersStructure_.Insert("Work_5Presentation", "");
	ParametersStructure_.Insert("CharacteristicsOfWork", Catalogs.ItemsCharacteristics.EmptyRef());
	ParametersStructure_.Insert("CharacteristicsOfWorkPresentation", "");
	ParametersStructure_.Insert("CharacteristicsOfWorkOwner", Catalogs.Products.EmptyRef());
	
	ParametersStructure_.Insert("UseGoodsOfDifferentQuality", False);
	
	// Item - not Suitable
	ParametersStructure_.Insert("ItemIsNotSuitable", Catalogs.Products.EmptyRef());
	ParametersStructure_.Insert("ItemIsNotSuitablePresentation", "");
	
	// Item - limited use
	ParametersStructure_.Insert("Products", Catalogs.Products.EmptyRef());
	ParametersStructure_.Insert("ProductsPresentation", "");
	
	// Operation parameters
	If Settings.UseWork Then
		ParametersStructure_.UseWork = True;
		ParametersStructure_.Work_5 = Settings.Work_5;
		ParametersStructure_.Work_5Presentation = String(Settings.Work_5);
		CharacteristicsOfWorkOwner = Undefined;
		ItemVariantsAreUsed = Catalogs.Products.CheckUsageCharacteristicsAndGetOwnerToSelect(
			Settings.Work_5, CharacteristicsOfWorkOwner);
		If ItemVariantsAreUsed Then
			ParametersStructure_.CharacteristicsOfWorkPresentation = PartyPresentation;
			ParametersStructure_.CharacteristicsOfWorkOwner = CharacteristicsOfWorkOwner;
			Query = New Query(
				"SELECT TOP 1
				|	Table.Ref AS Ref,
				|	Table.Presentation AS Presentation
				|FROM
				|	Catalog.ItemsCharacteristics AS Table
				|WHERE
				|	Table.Owner = &Owner
				|	AND NOT Table.DeletionMark");
			Query.SetParameter("Owner", CharacteristicsOfWorkOwner);
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				// Any characteristic is used for the functioning of the form
				// New characteristics will be created when the action is performed
				ParametersStructure_.CharacteristicsOfWork = Selection.Ref;
			Else
				ParametersStructure_.CharacteristicsOfWork = CreateDescriptionOfWorkOfAutoSelection(ParametersStructure_);
				CharacteristicsOfAutoSelectionWork.Add(ParametersStructure_.CharacteristicsOfWork);
			EndIf;
		EndIf;
	EndIf;
	
	If Object.IntermediateProductItem.IsEmpty()
		Or IntermediateFinishedProductQuality <> Enums.QualityLevels.New Then
		Products = Object.MainProductProducts;
		ItemsType = FinishedProductTypeOfItem;
	Else
		Products = Object.IntermediateProductItem;
		ItemsType = IntermediateFinishedproductItemType;
	EndIf;
	
	// Parameters of Nonconforming Products
	If Settings.UseGoodsOfDifferentQuality
		And ItemsType <> Enums.ItemsTypes.Work_5 Then
		ParametersStructure_.UseGoodsOfDifferentQuality = True;
		
		Query = New Query(
			"SELECT TOP 1
			|	TRUE                                  AS NotUsable,
			|	Quality.OtherQualityGoods               AS Products,
			|	Quality.OtherQualityGoods.Presentation AS ProductsPresentation
			|FROM
			|	InformationRegister.AnotherQualityGoods AS Quality
			|
			|WHERE
			|	Quality.Products = &Products
			|	AND Quality.QualityGradation = VALUE(Enum.QualityLevels.NotUsable)
			|	AND Quality.Products.ProductKind = Quality.OtherQualityGoods.ProductKind
			|	AND Quality.Products.UseVariants = Quality.OtherQualityGoods.UseVariants
			|	AND Quality.Products.UnitOfMeasure = Quality.OtherQualityGoods.UnitOfMeasure
			|	AND Quality.Products.UsePackages = Quality.OtherQualityGoods.UsePackages
			|	AND NOT Quality.OtherQualityGoods.DeletionMark
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	FALSE                                    AS NotUsable,
			|	Quality.OtherQualityGoods               AS Products,
			|	Quality.OtherQualityGoods.Presentation AS ProductsPresentation
			|FROM
			|	InformationRegister.AnotherQualityGoods AS Quality
			|
			|WHERE
			|	Quality.Products = &Products
			|	AND Quality.QualityGradation = VALUE(Enum.QualityLevels.SuitableToALimitedExtent)
			|	AND Quality.Products.ProductKind = Quality.OtherQualityGoods.ProductKind
			|	AND Quality.Products.UseVariants = Quality.OtherQualityGoods.UseVariants
			|	AND Quality.Products.UnitOfMeasure = Quality.OtherQualityGoods.UnitOfMeasure
			|	AND Quality.Products.UsePackages = Quality.OtherQualityGoods.UsePackages
			|	AND NOT Quality.OtherQualityGoods.DeletionMark");
		Query.SetParameter("Products", Products);
		Selection = Query.Execute().Select();
		If Selection.FindNext(True, "NotUsable") Then
			ParametersStructure_.ItemIsNotSuitable = Selection.Products;
			ParametersStructure_.ItemIsNotSuitablePresentation = Selection.ProductsPresentation;
		Else
			ProductsPresentation = String(Products);
			ProductsPresentation = StrReplace(ProductsPresentation,
				", " + String(Enums.QualityLevels.SuitableToALimitedExtent),
				"");
			ProductsPresentation = ProductsPresentation
				+ ", " + String(Enums.QualityLevels.NotUsable);
			ParametersStructure_.ItemIsNotSuitablePresentation = ProductsPresentation;
		EndIf;
		
		Selection.Reset();
		If Selection.FindNext(False, "NotUsable") Then
			ParametersStructure_.Products = Selection.Products;
			ParametersStructure_.ProductsPresentation = Selection.ProductsPresentation;
		Else
			ProductsPresentation = String(Products);
			QualityPresentation = ", " + String(Enums.QualityLevels.SuitableToALimitedExtent);
			If StrFind(ProductsPresentation, QualityPresentation) = 0 Then
				ProductsPresentation = ProductsPresentation + QualityPresentation;
			EndIf;
			ParametersStructure_.ProductsPresentation = ProductsPresentation;
		EndIf;
		
	EndIf;
	
	AutoSelectionParameters = New FixedStructure(ParametersStructure_);
	
EndProcedure

&AtServer
Procedure ConfigureProductsAutoselection(CurrentData, AttributesList, CachedValues = Undefined)
	
	CurrentData.AutomaticSelectionOfItems = False;
	CurrentData.AutoSelectingItemsIsWork = False;
	CurrentData.AutoSelectionOfItemsIsIntermediateFinishedProduct = False;
	CurrentData.ProductsOfOriginalQuality = Undefined;
	CurrentData.VariantOfOriginalQuality = Undefined;
	
	AttributesList = AttributesList + ", AutomaticSelectionOfItems";
	
	If Not CurrentData.ItemsForm.IsEmpty() Then
		Return;
	EndIf;
	
	ItemCopy = CurrentData.Products;
	ThisIsDefectiveFinishedProduct = Object.Action = Actions().DefectiveGoods And CurrentData.LineNumber = 1;
	UseWork = CurrentData.ContinueProcessing
		And (Object.Action = Actions().Split
			Or Object.Action = Actions().DefectiveGoods);
	
	If Not Object.IntermediateProductItem.IsEmpty()
		And Not ThisIsDefectiveFinishedProduct 
		And (Object.FromBeginningOfStage
				And (Not ProducedInPredecessors Or Not UseWork)
			Or Not Object.FromBeginningOfStage
				And IntermediateFinishedProductQuality = Enums.QualityLevels.SuitableToALimitedExtent) Then
		
		// Auto-Selection: Intermediate Finished Product (Item transferred Between stages)
		CurrentData.AutomaticSelectionOfItems = True;
		CurrentData.AutoSelectionOfItemsIsIntermediateFinishedProduct = True;
		
		CurrentData.Products = Object.IntermediateProductItem;
		CurrentData.AutoSelectionItemPresentation = IntermediateProductItemPresentation;
		CurrentData.Characteristic = Object.IntermediateProductVariant;
		CurrentData.CharacteristicForm = Undefined;
		CurrentData.CharacteristicsOfAutoSelectionPresentation = String(Object.IntermediateProductVariant);
		CurrentData.Package = Object.IntermediateProductPackagingUnit;
		
	ElsIf UseWork Then
		
		// Auto-Selection: Work
		If AutoSelectionParameters.UseWork Then
			CurrentData.AutomaticSelectionOfItems = True;
			CurrentData.AutoSelectingItemsIsWork = True;
			
			CurrentData.Products = AutoSelectionParameters.Work_5;
			CurrentData.AutoSelectionItemPresentation = AutoSelectionParameters.Work_5Presentation;
			
			CurrentData.Characteristic = AutoSelectionParameters.CharacteristicsOfWork;
			CurrentData.CharacteristicForm = Undefined;
			CurrentData.CharacteristicsOfAutoSelectionPresentation = AutoSelectionParameters.CharacteristicsOfWorkPresentation;
			
			CurrentData.Package = Undefined;
			CurrentData.NumberOfPackages = 1;
		EndIf;
		
	Else
		
		// Auto-Selection: A Nonconforming Product
		If AutoSelectionParameters.UseGoodsOfDifferentQuality Then
			CurrentData.AutomaticSelectionOfItems = True;
			
			If ThisIsDefectiveFinishedProduct Then
				CurrentData.AutoSelectionItemPresentation = AutoSelectionParameters.ItemIsNotSuitablePresentation;
			Else
				CurrentData.AutoSelectionItemPresentation = AutoSelectionParameters.ProductsPresentation;
			EndIf;
			
			If Object.IntermediateProductItem.IsEmpty()
				Or IntermediateFinishedProductQuality <> Enums.QualityLevels.New Then
				CurrentData.Products = Object.MainProductProducts;
				CurrentData.Characteristic = Object.MainProductCharacteristic;
				CurrentData.CharacteristicForm = Undefined;
				CurrentData.CharacteristicsOfAutoSelectionPresentation = String(Object.MainProductCharacteristic);
				CurrentData.Package = Object.Package;
				CurrentData.ProductsOfOriginalQuality = Object.MainProductProducts;
				CurrentData.VariantOfOriginalQuality = Object.MainProductCharacteristic;
			Else
				CurrentData.Products = Object.IntermediateProductItem;
				CurrentData.Characteristic = Object.IntermediateProductVariant;
				CurrentData.CharacteristicForm = Undefined;
				CurrentData.CharacteristicsOfAutoSelectionPresentation = String(Object.IntermediateProductVariant);
				CurrentData.Package = Object.IntermediateProductPackagingUnit;
				CurrentData.ProductsOfOriginalQuality = Object.IntermediateProductItem;
				CurrentData.VariantOfOriginalQuality = Object.IntermediateProductVariant;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not CurrentData.AutomaticSelectionOfItems Then
		CurrentData.Products = Undefined;
	EndIf;
	
	If ItemCopy <> CurrentData.Products Then
		AttributesList = AttributesList + ", Products";
		BatchProductsWhenChangedOnServer(CurrentData, CachedValues);
	EndIf;
	
	If CurrentData.AutoSelectingItemsIsWork Then
		CurrentData.Recipient = CurrentData.ContinueStageDepartment;
	EndIf;
	
	// Automatic Calculation of Quantity
	SetUpAutomaticQuantityCalculation(CurrentData, AttributesList, CachedValues);
	
	// Direction of release (control)
	ChoiceList = SelectionListReleaseDirectionForm(ThisObject, CurrentData);
	If ChoiceList.FindByValue(CurrentData.TheDirectionOfTheReleaseForm) = Undefined Then
		If CurrentData.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit
			And ChoiceList.FindByValue(Enums.BusinessTransactions.ProductsReleaseToWarehouse) <> Undefined Then
			CurrentData.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToWarehouse;
		ElsIf CurrentData.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToWarehouse
			And ChoiceList.FindByValue(Enums.BusinessTransactions.ProductsReleaseToBusinessUnit) <> Undefined Then
			CurrentData.TheDirectionOfTheReleaseForm = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit;
		Else
			CurrentData.TheDirectionOfTheReleaseForm = ChoiceList[0].Value;
		EndIf;
		WhenReleaseDirectionChangesForm(CurrentData, AttributesList, CachedValues);
	Else
		If SpecifyRecipientType(CurrentData) Then
			RecipientWhenModifiedOnServer(CurrentData.GetID(), False, CachedValues);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateAutoSelectionItem()
	
	SeriesSearchStructure = New Structure("LotIndex");
	
	// Characteristics of The Work
	If ValueIsFilled(AutoSelectionParameters.CharacteristicsOfWorkOwner) Then
		
		Characteristics = CharacteristicsOfAutoSelectionWork.UnloadValues();
		IndexOfCharacteristic = 0;
		
		Query = New Query(
			"SELECT 
			|	COUNT(ItemsCharacteristics.Ref) AS Count
			|FROM
			|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
			|WHERE
			|	ItemsCharacteristics.Owner = &Owner
			|	AND ItemsCharacteristics.Description LIKE &Description
			|	AND NOT ItemsCharacteristics.Ref IN (&References)
			|
			|HAVING
			|	COUNT(ItemsCharacteristics.Ref) > 0");
		Query.SetParameter("References", Characteristics);
		Query.SetParameter("Description", AutoSelectionParameters.CharacteristicsOfWorkPresentation + "%");
		Query.SetParameter("Owner", AutoSelectionParameters.CharacteristicsOfWorkOwner);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			LotNumber = Selection.Count + 1;
		Else
			LotNumber = 1;
		EndIf;
		
		TheStructureOfTheSearch = New Structure("AutoSelectingItemsIsWork", True);
		FoundRows = Object.Lots.FindRows(TheStructureOfTheSearch);
		For Each String In FoundRows Do
			
			Postfix = ?(LotNumber = 1 And FoundRows.Count() = 1, 0, LotNumber);
			
			Characteristic = Undefined;
			If IndexOfCharacteristic <= Characteristics.UBound() Then
				Characteristic = Characteristics[IndexOfCharacteristic];
				UpdateAutoSelectionWorkCharacteristics(Characteristic, AutoSelectionParameters, Postfix);
				IndexOfCharacteristic = IndexOfCharacteristic + 1;
			Else
				Characteristic = CreateDescriptionOfWorkOfAutoSelection(AutoSelectionParameters, Postfix);
				CharacteristicsOfAutoSelectionWork.Add(Characteristic);
			EndIf;
			
			String.Characteristic = Characteristic;
			
			SeriesSearchStructure.LotIndex = String.LotIndex;
			For Each RowSeries In Object.SetOfSeries.FindRows(SeriesSearchStructure) Do
				RowSeries.Characteristic = String.Characteristic;
			EndDo;
			
			LotNumber = LotNumber + 1;
			
		EndDo;
		
	EndIf;
	
	// Other quality products
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("AutomaticSelectionOfItems", True);
	TheStructureOfTheSearch.Insert("AutoSelectionOfItemsIsIntermediateFinishedProduct", False);
	TheStructureOfTheSearch.Insert("AutoSelectingItemsIsWork", False);
	PartiesWithAutoElection = Object.Lots.FindRows(TheStructureOfTheSearch);
	
	ReadyForProcessing_ = New ValueTable;
	ReadyForProcessing_.Columns.Add("String");
	ReadyForProcessing_.Columns.Add("Products");
	ReadyForProcessing_.Columns.Add("Characteristic");
	ReadyForProcessing_.Columns.Add("Package");
	
	For Each String In PartiesWithAutoElection Do
		
		// Selection/creation of characteristics and Packaging Units
		If ValueIsFilled(String.Characteristic)
			Or ValueIsFilled(String.Package) Then
			NewRow = ReadyForProcessing_.Add();
			NewRow.String = String;
			FillPropertyValues(NewRow, String, "Products, Characteristic, Package");
		EndIf;
		
		ThisIsDefectiveFinishedProduct = (Object.Action = Actions().DefectiveGoods And String.LineNumber = 1);
		ProductsLink = ?(ThisIsDefectiveFinishedProduct,
			AutoSelectionParameters.ItemIsNotSuitable, AutoSelectionParameters.Products);
		
		If ProductsLink.IsEmpty() Then
			// Creating Products
			SetPrivilegedMode(True);
			Products = String.ProductsOfOriginalQuality.Copy();
			Products.Description = String.AutoSelectionItemPresentation;
			Products.DescriptionFull = String.AutoSelectionItemPresentation;
			Products.Quality = ?(ThisIsDefectiveFinishedProduct,
				Enums.QualityLevels.NotUsable,
				Enums.QualityLevels.SuitableToALimitedExtent);
			Products.PicturesFile = Catalogs.ProductsAttachedFiles.EmptyRef();
			Products.DescriptionFileForWebsite = Catalogs.ProductsAttachedFiles.EmptyRef();
			Products.Code = "";
			Products.SearchCode = "";
			Products.DeletionMark = False;
			Products.Write();
			
			InformationRegisters.AnotherQualityGoods.RecordLinkToProductOfDifferentQuality(
				String.ProductsOfOriginalQuality, Products.Ref);
			SetPrivilegedMode(False);
			
			// Updating auto-selection parameters
			ParametersCopy = New Structure(AutoSelectionParameters);
			If ThisIsDefectiveFinishedProduct Then
				ParametersCopy.ItemIsNotSuitable = Products.Ref;
			Else
				ParametersCopy.Products = Products.Ref;
			EndIf;
			AutoSelectionParameters = New FixedStructure(ParametersCopy);
			
			String.Products = Products.Ref;
		Else
			String.Products = ProductsLink;
		EndIf;
		
	EndDo;
	
	If ReadyForProcessing_.Count() > 0 Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		// Selection of characteristics and packages
		StructureOfActions = New Structure;
		StructureOfActions.Insert("CheckCharacteristicsByOwner");
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct");
		StructureOfActions.Insert("CheckFillPackageByOwner");
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods");
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ReadyForProcessing_.UnloadColumn("String"),
			StructureOfActions,
			Object.Lots,
			CachedValues);
		
		// Creation of characteristics and packages
		CreatedObjects = New Map;
		For Each FillingValues In ReadyForProcessing_ Do
			BatchString = FillingValues.String;
			If ValueIsFilled(FillingValues.Characteristic)
				And Not ValueIsFilled(BatchString.Characteristic) Then
				If CreatedObjects[FillingValues.Characteristic] = Undefined Then
					BatchString.Characteristic = Catalogs.ItemsCharacteristics.IdenticalCharacteristic(
						BatchString.Products, FillingValues.Characteristic);
					CreatedObjects.Insert(FillingValues.Characteristic, BatchString.Characteristic);
				Else
					BatchString.Characteristic = CreatedObjects[FillingValues.Characteristic];
				EndIf;
			EndIf;
			
			If ValueIsFilled(FillingValues.Package)
				And Not ValueIsFilled(BatchString.Package) Then
				If CreatedObjects[FillingValues.Package] = Undefined Then
					BatchString.Package = Catalogs.PackagesAndUnitsOfMeasure.IdenticalPackaging(
						FillingValues.Products, BatchString.Products, FillingValues.Package);
					CreatedObjects.Insert(FillingValues.Package, BatchString.Package);
				Else
					BatchString.Package = CreatedObjects[FillingValues.Package];
				EndIf;
			EndIf;
		EndDo;
		
		// Recalculating the quantity
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ReadyForProcessing_.UnloadColumn("String"),
			StructureOfActions,
			Object.Lots,
			CachedValues);
	EndIf;
	
	// Series adjustment
	For Each String In PartiesWithAutoElection Do
		SeriesSearchStructure.LotIndex = String.LotIndex;
		For Each RowSeries In Object.SetOfSeries.FindRows(SeriesSearchStructure) Do
			FillPropertyValues(RowSeries, String, "Products, Characteristic");
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Function CreateDescriptionOfWorkOfAutoSelection(FillingValues, Postfix = 0)
	
	Description = ?(Postfix = 0,
		FillingValues.CharacteristicsOfWorkPresentation,
		StrTemplate("%1 (%2)", FillingValues.CharacteristicsOfWorkPresentation, Postfix));
	
	SetPrivilegedMode(True);
	Characteristic = Catalogs.ItemsCharacteristics.CreateItem();
	Characteristic.Owner = FillingValues.CharacteristicsOfWorkOwner;
	Characteristic.Description = Description;
	Characteristic.Write();
	SetPrivilegedMode(False);
	
	Return Characteristic.Ref;
	
EndFunction

&AtServer
Procedure UpdateAutoSelectionWorkCharacteristics(Ref, FillingValues, Postfix = 0)
	
	Description = ?(Postfix = 0,
		FillingValues.CharacteristicsOfWorkPresentation,
		StrTemplate("%1 (%2)", FillingValues.CharacteristicsOfWorkPresentation, Postfix));
	
	DescriptionCurrent = Common.ObjectAttributeValue(Ref, "Description");
	
	If DescriptionCurrent <> Description Then
		SetPrivilegedMode(True);
		CatalogObject = Ref.GetObject();
		CatalogObject.Lock();
		CatalogObject.Description = Description;
		CatalogObject.Write();
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

#EndRegion

#Region SimpleMode

&AtServer
Procedure SetUpSimpleMode()
	
	Actions = Actions();
	
	If Object.Action = Actions.Split Then
		
		If ReleaseOfFinishedproducts.Count() > 0 Then
			// The batches are filled in according to the product table - See SetUpLotReferences.
			// The last row in the table is the Balance for production, 
			// the data of this row is edited on The Form - See Data_Stage
// (product table).
			LastLotReference = Object.Lots[Object.Lots.Count()-1];
			
			If LastLotReference.PackageOfLot = Object.Package Then
				SimpleModeNumberOfPackagingunits = LastLotReference.LotNumberOfPackages;
			Else
				SimpleModeNumberOfPackagingunits = 0;
			EndIf;
			
			SimpleModeReleaseDirection = LastLotReference.TheDirectionOfTheReleaseForm;
			SimpleRecipientMode = LastLotReference.Recipient;
			Items.SimpleSplitRecipientMode.TypeRestriction = LimitingRecipientType(LastLotReference);
		Else
			// 2 Lot References: the direction of the first Is to continue processing, the direction Of the Second is set on the form
			FirstLotReference = Object.Lots[0];
			SecondLotReference = Object.Lots[1];
			
			If SecondLotReference.PackageOfLot = Object.Package Then
				SimpleModeNumberOfPackagingunits = SecondLotReference.LotNumberOfPackages;
			Else
				SimpleModeNumberOfPackagingunits = 0;
			EndIf;
			
			// The First Lot Reference
			FirstLotReference.TheDirectionOfTheReleaseForm = DirectionToContinueProcessing();
			WhenReleaseDirectionChangesForm(FirstLotReference, "");
			
			FirstLotReference.ItemsForm = Undefined;
			ConfigureProductsAutoselection(FirstLotReference, "");
			
			FirstLotReference.LotNumberOfPackages = Object.NumberOfPackages - SimpleModeNumberOfPackagingunits;
			FirstLotReference.PackageOfLot = Object.Package;
			FirstLotReference.LotQuantity = CalculateNumberOfBatchUnits(
				Object.MainProductProducts,
				FirstLotReference.PackageOfLot,
				FirstLotReference.LotNumberOfPackages);
			
			If Not FirstLotReference.AutoSelectingItemsIsWork Then
				FirstLotReference.NumberOfPackages = FirstLotReference.LotNumberOfPackages;
				StructureOfActions = New Structure;
				StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
				BatchProcessingOfTablePartServer.ProcessTSString(FirstLotReference, StructureOfActions, Undefined);
			EndIf;
			
			FirstLotReference.Assignments.Clear();
			FirstLotReference.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(FirstLotReference);
			FirstLotReference.SpecifyTargets = SpecifyTargets(
				Object.Action, Object.FromBeginningOfParty, FirstLotReference, Settings);
			
			If FirstLotReference.ChangeProductToBeReleased Then
				InstallMainFinishedProduct(FirstLotReference);
			EndIf;
			
			FirstLotReference.CostShare = FirstLotReference.LotNumberOfPackages;
			
			// Second Lot Reference
			If SecondLotReference.TheDirectionOfTheReleaseForm <> Enums.BusinessTransactions.ProductsReleaseToWarehouse
				And SecondLotReference.TheDirectionOfTheReleaseForm <> DirectionToContinueProcessing() Then
				SecondLotReference.TheDirectionOfTheReleaseForm = DirectionToContinueProcessing();
				WhenReleaseDirectionChangesForm(SecondLotReference, "");
			EndIf;
			
			SecondLotReference.ItemsForm = Undefined;
			ConfigureProductsAutoselection(SecondLotReference, "");
			
			SecondLotReference.LotNumberOfPackages = SimpleModeNumberOfPackagingunits;
			SecondLotReference.PackageOfLot = Object.Package;
			SecondLotReference.LotQuantity = CalculateNumberOfBatchUnits(
				Object.MainProductProducts,
				SecondLotReference.PackageOfLot,
				SecondLotReference.LotNumberOfPackages);
			
			If Not SecondLotReference.AutoSelectingItemsIsWork Then
				SecondLotReference.NumberOfPackages = SecondLotReference.LotNumberOfPackages;
				StructureOfActions = New Structure;
				StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
				BatchProcessingOfTablePartServer.ProcessTSString(SecondLotReference, StructureOfActions, Undefined);
			EndIf;
			
			SecondLotReference.Assignments.Clear();
			SecondLotReference.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(SecondLotReference);
			SecondLotReference.SpecifyTargets = SpecifyTargets(
				Object.Action, Object.FromBeginningOfParty, SecondLotReference, Settings);
			
			If SecondLotReference.ChangeProductToBeReleased Then
				InstallMainFinishedProduct(SecondLotReference);
			EndIf;
			
			SecondLotReference.CostShare = SecondLotReference.LotNumberOfPackages;
			
			// Elements of the simple mode
			SimpleModeReleaseDirection = SecondLotReference.TheDirectionOfTheReleaseForm;
			SimpleRecipientMode = SecondLotReference.Recipient;
			EasyModeCancelFinishedProductInOrder = SecondLotReference.CancelChangeFinishedProductInOrder;
			SimpleModeReasonForCancellationOfFinishedProduct = SecondLotReference.ReasonForCancelingFinishedProduct;
			Items.SimpleSplitRecipientMode.TypeRestriction = LimitingRecipientType(SecondLotReference);
		EndIf;
		
	ElsIf Object.Action = Actions.DefectiveGoods Then
		
		// The First Lot Reference
		FirstLotReference = Object.Lots[0];
		
		ChoiceList = SelectionListReleaseDirectionForm(ThisObject, FirstLotReference);
		If ChoiceList.FindByValue(FirstLotReference.TheDirectionOfTheReleaseForm) = Undefined Then
			FirstLotReference.TheDirectionOfTheReleaseForm = ChoiceList[0].Value;
			WhenReleaseDirectionChangesForm(FirstLotReference, "");
		EndIf;
		
		FirstLotReference.ItemsForm = Undefined;
		ConfigureProductsAutoselection(FirstLotReference, "");
		
		FirstLotReference.Assignments.Clear();
		FirstLotReference.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(FirstLotReference);
		FirstLotReference.SpecifyTargets = SpecifyTargets(
			Object.Action, Object.FromBeginningOfParty, FirstLotReference, Settings);
		
		If Not Object.ThisIsLastStageAndOperation
			Or Not Object.CostSharesAreFilledInStage Then
			FirstLotReference.CostShare = Object.NumberOfPackagingUnitsNonconformity * PackagingFactor;
		EndIf;
		
		// Second Lot Reference
		If Object.Lots.Count() = 2 Then
		
			SecondLotReference = Object.Lots[1];
			
			SecondLotReference.TheDirectionOfTheReleaseForm = DirectionToContinueProcessing();
			WhenReleaseDirectionChangesForm(SecondLotReference, "");
			
			SecondLotReference.ItemsForm = Undefined;
			ConfigureProductsAutoselection(SecondLotReference, "");
			
			SecondLotReference.Assignments.Clear();
			SecondLotReference.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(SecondLotReference);
			SecondLotReference.SpecifyTargets = SpecifyTargets(
				Object.Action, Object.FromBeginningOfParty, SecondLotReference, Settings);
			
			If SecondLotReference.ChangeProductToBeReleased Then
				InstallMainFinishedProduct(SecondLotReference);
			EndIf;
			
			SecondLotReference.CostShare = (Object.NumberOfPackages - Object.NumberOfPackagingUnitsNonconformity) * PackagingFactor;
			
		EndIf;
		
		// Elements of the simple mode
		Items.SimpleModeNonconformityItemPresentation.Visible = 
			Not IsBlankString(AutoSelectionParameters.ItemIsNotSuitablePresentation);
		Items.SimpleModeNonconformityItemPresentation.Hyperlink =
			Not AutoSelectionParameters.ItemIsNotSuitable.IsEmpty();
		SimpleModeAutoSelectionItemPresentation = AutoSelectionParameters.ItemIsNotSuitablePresentation;
		
		SimpleModeReleaseDirection = FirstLotReference.TheDirectionOfTheReleaseForm;
		Items.GroupSimpleModeNonconformityDirectionOfRelease.Visible = ChoiceList.Count() > 1;
		
		SimpleRecipientMode = FirstLotReference.Recipient;
		Items.SimpleModeNonconformityRecipient.TypeRestriction = LimitingRecipientType(FirstLotReference);
		
		EasyModeCancelFinishedProductInOrder = FirstLotReference.CancelChangeFinishedProductInOrder;
		SimpleModeReasonForCancellationOfFinishedProduct = FirstLotReference.ReasonForCancelingFinishedProduct;
		
	ElsIf Object.Action = Actions.Cancel Then
		
		FirstLotReference = Object.Lots[0];
		
		ChoiceList = SelectionListReleaseDirectionForm(ThisObject, FirstLotReference);
		If ChoiceList.FindByValue(FirstLotReference.TheDirectionOfTheReleaseForm) = Undefined Then
			FirstLotReference.TheDirectionOfTheReleaseForm = ChoiceList[0].Value;
			WhenReleaseDirectionChangesForm(FirstLotReference, "");
		EndIf;
		
		FirstLotReference.ItemsForm = Undefined;
		ConfigureProductsAutoselection(FirstLotReference, "");
		
		FillPropertyValues(FirstLotReference, Object, "NumberOfPackages, Count");
		
		FirstLotReference.Assignments.Clear();
		FirstLotReference.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(FirstLotReference);
		FirstLotReference.SpecifyTargets = SpecifyTargets(
			Object.Action, Object.FromBeginningOfParty, FirstLotReference, Settings);
		
		// Elements of the simple mode
		If FirstLotReference.AutoSelectionOfItemsIsIntermediateFinishedProduct Then
			Items.SimpleModeCancelItemPresentation.Visible = True;
			Items.SimpleModeCancelItemPresentation.Hyperlink = True;
			SimpleModeAutoSelectionItemPresentation = IntermediateProductItemPresentation;
		Else
			Items.SimpleModeCancelItemPresentation.Visible = 
				Not IsBlankString(AutoSelectionParameters.ProductsPresentation);
			Items.SimpleModeCancelItemPresentation.Hyperlink =
				Not AutoSelectionParameters.Products.IsEmpty();
			SimpleModeAutoSelectionItemPresentation = AutoSelectionParameters.ProductsPresentation;
		EndIf;
		
		SimpleModeReleaseDirection = FirstLotReference.TheDirectionOfTheReleaseForm;
		Items.GroupSimpleModeUndoReleaseDirection.Visible = ChoiceList.Count() > 1;
		
		SimpleRecipientMode = FirstLotReference.Recipient;
		Items.SimpleModeCancelRecipient.TypeRestriction = LimitingRecipientType(FirstLotReference);
		
		EasyModeCancelFinishedProductInOrder = FirstLotReference.CancelChangeFinishedProductInOrder;
		SimpleModeReasonForCancellationOfFinishedProduct = FirstLotReference.ReasonForCancelingFinishedProduct;
		
	ElsIf Object.Action = Actions.Continue Then
		
		FirstLotReference = Object.Lots[0];
		
		FirstLotReference.TheDirectionOfTheReleaseForm = DirectionToContinueProcessing();
		WhenReleaseDirectionChangesForm(FirstLotReference, "");
		
		FirstLotReference.ItemsForm = Undefined;
		ConfigureProductsAutoselection(FirstLotReference, "");
		
		FirstLotReference.LotNumberOfPackages = Object.NumberOfPackages;
		FirstLotReference.PackageOfLot = Object.Package;
		FirstLotReference.LotQuantity = Object.Count;
		
		FillPropertyValues(FirstLotReference, Object, "NumberOfPackages, Count");
		
		FirstLotReference.Assignments.Clear();
		FirstLotReference.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(FirstLotReference);
		FirstLotReference.SpecifyTargets = SpecifyTargets(
			Object.Action, Object.FromBeginningOfParty, FirstLotReference, Settings);
		
		If FirstLotReference.ChangeProductToBeReleased Then
			InstallMainFinishedProduct(FirstLotReference);
		EndIf;
		
		EasyModeCancelFinishedProductInOrder = False;
		SimpleModeReasonForCancellationOfFinishedProduct = Undefined;
		
	ElsIf Object.Action = Actions.Reduce Then
		
		FirstLotReference = Object.Lots[0];
		
		FirstLotReference.Assignments.Clear();
		FirstLotReference.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(FirstLotReference);
		FirstLotReference.SpecifyTargets = SpecifyTargets(
			Object.Action, Object.FromBeginningOfParty, FirstLotReference, Settings);
		
		// Elements of the simple mode
		SimpleModeNumberOfPackagingunits = FirstLotReference.LotNumberOfPackages;
		SimplePackagingUnitMode = FirstLotReference.PackageOfLot;
		
		EasyModeCancelFinishedProductInOrder = FirstLotReference.CancelChangeFinishedProductInOrder;
		SimpleModeReasonForCancellationOfFinishedProduct = FirstLotReference.ReasonForCancelingFinishedProduct;
		
	Else
		
		FirstLotReference = Object.Lots[0];
		
		FirstLotReference.Assignments.Clear();
		FirstLotReference.ThereAreErrorsInFillingOutAssignments = ThereAreErrorsInFillingOutAssignments(FirstLotReference);
		FirstLotReference.SpecifyTargets = SpecifyTargets(
			Object.Action, Object.FromBeginningOfParty, FirstLotReference, Settings);
		
		If FirstLotReference.ChangeProductToBeReleased Then
			InstallMainFinishedProduct(FirstLotReference);
		EndIf;
		
		EasyModeCancelFinishedProductInOrder = False;
		SimpleModeReasonForCancellationOfFinishedProduct = Undefined;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region TreeProductionProcess

&AtServerNoContext
Function ProductionProcessInWarehouse(BillOfMaterials, UUID)
	
	Tree = New ValueTree();
	Tree.Columns.Add("ItemKind", New TypeDescription("String",, New StringQualifiers()));
	Tree.Columns.Add("OperationID", New TypeDescription("Number", New NumberQualifiers()));
	Tree.Columns.Add("Picture", New TypeDescription("Picture"));
	Tree.Columns.Add("Description", New TypeDescription("String",, New StringQualifiers()));
	Tree.Columns.Add("Number", New TypeDescription("Number", New NumberQualifiers()));
	Tree.Columns.Add("TheNumberOfTheNextOne", New TypeDescription("Number", New NumberQualifiers()));
	Tree.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	Tree.Columns.Add("ProductionByThirdParty", New TypeDescription("Boolean"));
	Tree.Columns.Add("WorkPlanning", New TypeDescription("Boolean"));
	Tree.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters, CatalogRef.WorkCenterTypes"));
	Tree.Columns.Add("Ref", New TypeDescription("CatalogRef.ProductionStages, CatalogRef.ManufacturingOperations"));
	Tree.Columns.Add("TechnologicalProcess", New TypeDescription("CatalogRef.TechnologicalProcesses"));
	Tree.Columns.Add("ReadOnly", New TypeDescription("Boolean"));
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("BillOfMaterials", BillOfMaterials);
	ProcedureParameters.Insert("ProductionProcessTree", Tree);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunNotInBackground1 = True;
	ExecutionParameters.RunInBackground = False;
	
	TimeConsumingOperations.ExecuteInBackground(
		"ProductionProcessEditor.StructureOfProductionProcessInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
	Return PutToTempStorage(Tree, UUID);
	
EndFunction

// Returns information about the process operation.
// 
// Parameters:
//  AddressProductionProcess - String - The address of the production process in the temporary storage
//  Operation - CatalogRef.ManufacturingOperations - Operation
//  OperationID - Number - operation ID
// 
// Returns:
//  Structure:
//   * Operation - CatalogRef.ManufacturingOperations - If the Operation is a technological process,
//     then its first operation is returned, otherwise the incoming value is returned.
//   * OperationID - Number - Filled in the same way as the Operation parameter.
//   * ThisIsFirstOperation - Boolean - True if the operation is the first in the stage.
//
&AtServerNoContext
Function PropertiesOfProductionProcessOperation(AddressProductionProcess, Operation, OperationID)
	
	Result = New Structure;
	Result.Insert("Operation", Operation);
	Result.Insert("OperationID", OperationID);
	Result.Insert("ThisIsFirstOperation", False);
	
	If Not IsTempStorageURL(AddressProductionProcess) Then
		Return Result;
	EndIf;
	
	Tree = GetFromTempStorage(AddressProductionProcess); //ValueTree
	LineOperation = Tree.Rows.Find(Operation, "Ref", True);
	If LineOperation = Undefined
			Or LineOperation.Parent = Undefined Then
		Return Result;
	EndIf;
	
	If TypeOf(LineOperation.Parent.Ref) = Type("CatalogRef.ProductionStages") Then
		If LineOperation.Rows.Count() > 0 Then
			// The operation is a technological process
			Result.Operation = LineOperation.Rows[0].Ref;
			Result.OperationID = LineOperation.Rows[0].OperationID;
		EndIf;
		StageString = LineOperation.Parent;
		Result.ThisIsFirstOperation = StageString.Rows.IndexOf(LineOperation) = 0;
	ElsIf TypeOf(LineOperation.Parent.Ref) = Type("CatalogRef.ManufacturingOperations") Then
		LineTechnologicalProcess = LineOperation.Parent;
		StageString = LineTechnologicalProcess.Parent;
		Result.ThisIsFirstOperation = StageString.Rows.IndexOf(LineTechnologicalProcess) = 0
			And LineTechnologicalProcess.Rows.IndexOf(LineOperation) = 0;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function ProductionProcessOfLotReferenceInStorage(ProductionLot, UUID, ThereAreOperations)
	
	Tree = DataProcessors.ProductionLotDivision.TreeProductionProcess(ProductionLot, True);
	ThereAreOperations = Tree.Rows.Find(False, "ThisIsAStep", True) <> Undefined;
	
	Return PutToTempStorage(Tree, UUID);
	
EndFunction

&AtServer
Procedure FindNextPointOfProductionProcess(NextOperation, NextStage)
	
	BOMTree = GetFromTempStorage(AddressProductionProcess); // ValueTree
	
	FoundRow = BOMTree.Rows.Find(BOMStage, "Ref", True);
	If FoundRow = Undefined Then
		Return;
	EndIf;
	
	OperationSpecifications = FoundRow.Rows.Find(Object.OperationID, "OperationID", True);
	If OperationSpecifications <> Undefined Then
		OperationSpecificationIndex = OperationSpecifications.Parent.Rows.IndexOf(OperationSpecifications);
		If OperationSpecificationIndex <> OperationSpecifications.Parent.Rows.Count() - 1 Then
			NextOperation = OperationSpecifications.Parent.Rows[OperationSpecificationIndex + 1];
		Else
			StageString = Undefined;
			If TypeOf(OperationSpecifications.Parent.Ref) = Type("CatalogRef.ManufacturingOperations") Then
				LineTechnologicalProcess = OperationSpecifications.Parent;
				StageString = LineTechnologicalProcess.Parent;
				TechnologicalProcessIndex = StageString.Rows.IndexOf(LineTechnologicalProcess);
				If TechnologicalProcessIndex <> StageString.Rows.Count() - 1 Then
					NextOperation = StageString.Rows[TechnologicalProcessIndex + 1];
				EndIf;
			Else
				StageString = OperationSpecifications.Parent;
			EndIf;
			
			If NextOperation = Undefined
				And StageString <> Undefined Then
				StageIndex = BOMTree.Rows.IndexOf(StageString);
				If StageIndex <> BOMTree.Rows.Count() - 1 Then
					NextStage = BOMTree.Rows[StageIndex + 1];
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure ReadSettings()
	
	FormSettings = New Structure;
	FormSettings.Insert("UseWork", False);
	FormSettings.Insert("Work_5", Catalogs.Products.EmptyRef());
	FormSettings.Insert("UseGoodsOfDifferentQuality", False);
	FormSettings.Insert("FillInByBOM", False);
	FormSettings.Insert("ReserveMaterials", False);
	FormSettings.Insert("ReplaceMaterialsWithAnalogs", False);
	FormSettings.Insert("SimpleModeIsAvailable", False);
	FormSettings.Insert("EasyModeWhenOpening", False);
	
	SetPrivilegedMode(True);
	SettingsValue = Constants.SettingsOfProductionLotDivision.Get().Get();
	SetPrivilegedMode(False);
	If TypeOf(SettingsValue) = Type("Structure") Then
		FillPropertyValues(FormSettings, SettingsValue);
	EndIf;
	
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.ProductionLotDivision", "");
	If TypeOf(SettingsValue) = Type("Structure") Then
		FillPropertyValues(FormSettings, SettingsValue);
	EndIf;
	
	FormSettings.SimpleModeIsAvailable = FormSettings.UseWork
		Or FormSettings.UseGoodsOfDifferentQuality;
	
	If FormSettings.SimpleModeIsAvailable Then
		SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.ProductionLotDivision", "FormSettings");
		If TypeOf(SettingsValue) = Type("Structure")
			And SettingsValue.Property("EasyModeWhenOpening") Then
			FormSettings.EasyModeWhenOpening = SettingsValue.EasyModeWhenOpening;
		EndIf;
	EndIf;
	
	Settings = New FixedStructure(FormSettings);
	
EndProcedure

&AtServer
Procedure OnSettingsChange(CachedValues)
	
	ReadSettings();
	ReadAutoSelectionParameters();
	
	If Not Settings.SimpleModeIsAvailable
		And SimpleMode Then
		SimpleMode = False;
		SimpleFormMode = 0;
	EndIf;
	
	SetUpLotReferences(True);
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Function Actions()
	
	Result = New Structure;
	Result.Insert("Reduce", 0);
	Result.Insert("Cancel", 1);
	Result.Insert("Split", 2);
	Result.Insert("Continue", 3);
	Result.Insert("DefectiveGoods", 5);
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function Data_Stage(Object, ProductUnitOfMeasurement)
	
	Result = Undefined;
	
	ProductionLot = Object.ProductionLot;
	Stage = Object.Stage;
	ThisIsFirstOperation = Object.ThisIsFirstOperation;
	ThisIsLastOperation = Object.ThisIsLastOperation;
	Action = Object.Action;
	
	If Stage.IsEmpty() Then
		
		QueryText = "
			|SELECT TOP 1
			|	Stages.PackagePlan AS Package,
			|	CASE
			|		WHEN Stages.PackagePlan = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|			THEN PRESENTATION(Stages.ProductionLot.MainProductProducts.UnitOfMeasure)
			|		ELSE PRESENTATION(Stages.PackagePlan)
			|	END AS ItemPackagePresentation,
			|	ISNULL(&PackagingFactor, 1) AS PackagingFactor
			|FROM
			|	Document.ProductionStage2_2 AS Stages
			|		LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS RegulatorySchedule
			|		ON Stages.Ref = RegulatorySchedule.ProductionStage
			|WHERE
			|	Stages.ProductionLot = &ProductionLot
			|	AND Stages.Posted
			|
			|ORDER BY
			|	ISNULL(RegulatorySchedule.DurationBeforeStart, -Stages.DurationBeforeProductionIssue)";
		
		QueryText = StrReplace(
			QueryText,
			"&PackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"Stages.PackagePlan",
				"Stages.ProductionLot.MainProductProducts"));
		
		Query = New Query(QueryText);
		Query.SetParameter("ProductionLot", ProductionLot);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			Result = New Structure;
			Result.Insert("Package", Selection.Package);
			Result.Insert("ItemPackagePresentation", Selection.ItemPackagePresentation);
			Result.Insert("PackagingFactor", Selection.PackagingFactor);
			Result.Insert("StagePresentation", "");
			Result.Insert("Department", Undefined);
			Result.Insert("Manufactured", False);
			Result.Insert("CreateStage", False);
			Result.Insert("BOMStage", Undefined);
			Result.Insert("BOMStagePresentation", "");
			Result.Insert("BillOfMaterialsStageDepartment", Undefined);
			Result.Insert("FromBeginningOfParty", True);
			Result.Insert("DivisionCancellationFromBeginningOfParty", True);
			Result.Insert("FromBeginningOfStage", True);
			Result.Insert("IntermediateProductItem", Undefined);
			Result.Insert("IntermediateProductVariant", Undefined);
			Result.Insert("IntermediateFinishedproductItemType", Undefined);
			Result.Insert("IntermediateProductPackagingUnit", Undefined);
			Result.Insert("IntermediateProductItemPresentation", "");
			Result.Insert("IntermediateFinishedProductQuality", Undefined);
			Result.Insert("ProducedInPredecessors", False);
			Result.Insert("NumberOfPackagingUnitsNonconformity", 0);
			Result.Insert("ReleaseOfFinishedproducts", Undefined);
			Result.Insert("ThisIsLastStageAndOperation", False);
			Result.Insert("CostSharesAreFilledInStage", False);
			Result.Insert("WorkPlanning", False);
			
		EndIf;
		
	Else
		
		TempTablesManager = New TempTablesManager;
		Documents.ProductionStage2_2.CreateTTPredecessors(TempTablesManager, Stage);
		
		QueryText = "
			|SELECT
			|	COUNT(Predecessors.Predecessor) AS Count,
			|	MIN(Predecessors.Predecessor.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)) AS Completed,
			|	MAX(Predecessors.Predecessor.WorkPlanning) AS WorkPlanning,
			|	MIN(Predecessors.Predecessor.Department) AS Department
			|INTO Predecessors
			|FROM
			|	TTPredecessors AS Predecessors
			|WHERE
			|	Predecessors.Predecessor.ProductionLot = &ProductionLot
			|HAVING
			|	COUNT(Predecessors.Predecessor) > 0
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT TOP 1
			|	TRUE AS ProducedInPredecessors
			|INTO PredecessorsProduced
			|FROM
			|	Document.ProductionStage2_2.SideAndIntermediateRelease AS SideAndIntermediateRelease
			|WHERE
			|	SideAndIntermediateRelease.Ref IN (
			|		SELECT
			|			Predecessors.Predecessor AS Ref
			|		FROM
			|			TTPredecessors AS Predecessors
			|		WHERE
			|			Predecessors.Predecessor.ProductionLot = &ProductionLot)
			|	AND SideAndIntermediateRelease.Manufactured
			|	AND NOT SideAndIntermediateRelease.Canceled
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Products_1.Products AS Products,
			|	Products_1.Characteristic AS Characteristic,
			|	Products_1.Recipient AS Recipient,
			|	Products_1.Purpose AS Purpose,
			|	Products_1.Count AS Count,
			|	Products_1.NumberOfPackages AS NumberOfPackages,
			|	Products_1.Package AS Package,
			|	Products_1.Manufactured AS Manufactured
			|INTO Products_1
			|FROM
			|	Document.ProductionStage2_2.ManufacturedProducts AS Products_1
			|WHERE
			|	Products_1.Ref = &Stage
			|	AND NOT Products_1.Canceled
			|	AND Products_1.Products = Products_1.Ref.ProductionLot.MainProductProducts
			|	AND Products_1.Characteristic = Products_1.Ref.ProductionLot.MainProductCharacteristic
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	FALSE AS ContinueProcessing,
			|	Products_1.Products AS Products,
			|	Products_1.Characteristic AS Characteristic,
			|	Products_1.Recipient AS Recipient,
			|	Products_1.Purpose AS Purpose,
			|	SUM(Products_1.Count) AS Count,
			|	CASE
			|		WHEN COUNT(DISTINCT Products_1.Package) = 1
			|			THEN MIN(Products_1.Package)
			|		ELSE UNDEFINED
			|	END AS Package,
			|	CASE
			|		WHEN COUNT(DISTINCT Products_1.Package) = 1
			|			THEN SUM(Products_1.NumberOfPackages)
			|		ELSE SUM(Products_1.Count)
			|	END AS NumberOfPackages
			|FROM
			|	Products_1 AS Products_1
			|WHERE
			|	Products_1.Manufactured
			|	AND TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			Products_1 AS ReverseFinishedProducts
			|		WHERE
			|			NOT ReverseFinishedProducts.Manufactured)
			|
			|GROUP BY
			|	Products_1.Products,
			|	Products_1.Characteristic,
			|	Products_1.Recipient,
			|	Products_1.Purpose
			|
			|HAVING
			|	SUM(Products_1.Count) > 0
			|
			|UNION ALL
			|
			|SELECT
			|	TRUE AS ContinueProcessing,
			|	UNDEFINED AS Products,
			|	UNDEFINED AS Characteristic,
			|	UNDEFINED AS Recipient,
			|	UNDEFINED AS Purpose,
			|	SUM(Products_1.Count) AS Count,
			|	CASE
			|		WHEN COUNT(DISTINCT Products_1.Package) = 1
			|			THEN MIN(Products_1.Package)
			|		ELSE UNDEFINED
			|	END AS Package,
			|	CASE
			|		WHEN COUNT(DISTINCT Products_1.Package) = 1
			|			THEN SUM(Products_1.NumberOfPackages)
			|		ELSE SUM(Products_1.Count)
			|	END AS NumberOfPackages
			|FROM
			|	Products_1 AS Products_1
			|WHERE
			|	NOT Products_1.Manufactured
			|	AND TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			Products_1 AS ReverseFinishedProducts
			|		WHERE
			|			ReverseFinishedProducts.Manufactured)
			|
			|HAVING
			|	SUM(Products_1.Count) > 0
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Stages.Number                           AS Number,
			|	Stages.StageName               AS StageName,
			|	Stages.Department                   AS Department,
			|	Stages.Stage                            AS Stage,
			|	PRESENTATION(Stages.Stage)             AS StagePresentation,
			|	Stages.Stage.Department              AS StageDivision,
			|	Stages.NumberOfPackagesPlan          AS NumberOfPackages,
			|	Stages.PackagePlan                    AS Package,
			|	CASE
			|		WHEN Stages.PackagePlan = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|			THEN PRESENTATION(Stages.ProductionLot.MainProductProducts.UnitOfMeasure)
			|		ELSE PRESENTATION(Stages.PackagePlan)
			|	END                                 AS ItemPackagePresentation,
			|	ISNULL(&PackagingFactor, 1)     AS PackagingFactor,
			|	ISNULL(&PackageType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PackagingPiece,
			|	Stages.WorkPlanning               AS WorkPlanning,
			|	
			|	Stages.Status IN (
			|		VALUE(Enum.StatusesOfProductionStages2_2.Initiated),
			|		VALUE(Enum.StatusesOfProductionStages2_2.Completed))
			|	OR TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			InformationRegister.OperationsToCreateShiftTasks AS AssignedOperations
			|		WHERE
			|			AssignedOperations.Stage = &Stage
			|			AND AssignedOperations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef))
			|	OR TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			Document.ProductionOperation2_2 AS Operations
			|		WHERE
			|			Operations.Stage = &Stage
			|			AND Operations.Posted) AS StageHasBegun,
			|	
			|	TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			InformationRegister.QueueOfProductionOperations AS OperationQueue
			|		WHERE
			|			OperationQueue.Stage = &Stage)       AS ThereAreOperations,
			|	
			|	TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			Document.ProductionStage2_2.ManufacturedProducts AS Products_1
			|		WHERE
			|			Products_1.Ref = &Stage
			|			AND NOT Products_1.Canceled
			|			AND Products_1.CostShare <> 0)       AS CostSharesAreFilledInStage,
			|	
			|	Predecessors.Count IS NULL        AS ThisIsTheFirstStep,
			|	Stages.NextStageNo = 0              AS ThisIsLastStage,
			|	ISNULL(Predecessors.Count, 0) > 1 AS SeveralPredecessors,
			|	ISNULL(Predecessors.Completed, FALSE)   AS PredecessorsCompleted,
			|	ISNULL(Predecessors.WorkPlanning, FALSE)     AS PredecessorsWorkPlanning,
			|	ISNULL(Predecessors.Department, UNDEFINED) AS PredecessorDivision,
			|
			|	ISNULL(PredecessorsProduced.ProducedInPredecessors, FALSE) AS ProducedInPredecessors
			|FROM
			|	Document.ProductionStage2_2 AS Stages
			|
			|	LEFT JOIN Predecessors AS Predecessors
			|	ON TRUE
			|
			|	LEFT JOIN PredecessorsProduced AS PredecessorsProduced
			|	ON TRUE
			|WHERE
			|	Stages.Ref = &Stage";
		
		QueryText = StrReplace(
			QueryText,
			"&PackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"Stages.PackagePlan",
				"Stages.ProductionLot.MainProductProducts"));
		
		QueryText = StrReplace(
			QueryText,
			"&PackageType",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
				"MeasuredValueType",
				"Stages.PackagePlan",
				"Stages.ProductionLot.MainProductProducts"));
		
		Query = New Query(QueryText); // The Query, Along with the TT And parameters, is also used below to calculate the intermediate Finished Product
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("ProductionLot", ProductionLot);
		Query.SetParameter("Stage", Stage);
		
		SetPrivilegedMode(True);
		ResultsArray = Query.ExecuteBatch();
		SetPrivilegedMode(False);
		ReleaseOfFinishedproducts = ResultsArray[ResultsArray.UBound()-1].Unload();
		SampleStage = ResultsArray[ResultsArray.UBound()].Select();
		SampleStage.Next();
		
		FromBeginningOfStage = Not (
			SampleStage.StageHasBegun
			Or Action = Actions().DefectiveGoods
			Or (OfOperationSelected(Object) And Not ThisIsFirstOperation)
		);
		DivisionCancellationFromBeginningOfStage = Not (
			SampleStage.StageHasBegun
			Or (OfOperationSelected(Object) And Not ThisIsFirstOperation)
		);
		FromBeginningOfParty = SampleStage.ThisIsTheFirstStep And FromBeginningOfStage;
		DivisionCancellationFromBeginningOfParty = SampleStage.ThisIsTheFirstStep And DivisionCancellationFromBeginningOfStage;
		
		ThisIsLastStageAndOperation = ?(SampleStage.ThereAreOperations,
			SampleStage.ThisIsLastStage And ThisIsLastOperation,
			SampleStage.ThisIsLastStage);
		
		OperationPresentation = OperationPresentation(Object);
		
		StagePresentation = ?(OfOperationSelected(Object),
			StrTemplate("%1 / %2 (%3)", SampleStage.StageName, OperationPresentation, SampleStage.Number),
			StrTemplate("%1 (%2)", SampleStage.StageName, SampleStage.Number));
		If FromBeginningOfParty Then
			StagePresentation = StagePresentation + " - " + NStr("vi = 'Từ đầu lô';
																|ru = 'с начала партии';
																|en = 'from the beginning of the lot'; fa = 'from the beginning of the lot';
																|it = 'с начала партии';
																|pl = 'from the beginning of the lot';
																|tr = 'lot başlangıcından itibaren'");
		EndIf;
		
		BOMStagePresentation = ?(OfOperationSelected(Object),
			StrTemplate("%1 / %2", SampleStage.StagePresentation, OperationPresentation),
			SampleStage.StagePresentation);
		
		CreateStage = False;
		Manufactured = False;
		If Action = Actions().DefectiveGoods Then
			Manufactured = True;
			CreateStage = SampleStage.WorkPlanning;
		ElsIf SampleStage.WorkPlanning And Not FromBeginningOfStage Then
			// The intermediate release will be reflected in the new follower stage
			CreateStage = True;
			Manufactured = True;
		ElsIf Not SampleStage.ThisIsTheFirstStep And FromBeginningOfStage Then
			// The intermediate release will be reflected in the predecessor stage
			CreateStage = SampleStage.SeveralPredecessors
				Or SampleStage.PredecessorsCompleted
				Or SampleStage.PredecessorsWorkPlanning;
			Manufactured = SampleStage.PredecessorsCompleted;
		EndIf;
		ProducedInPredecessors = SampleStage.ProducedInPredecessors; // In the previous stages there are lines with the flag Produced
		
		Department = ?(Not FromBeginningOfStage Or CreateStage Or SampleStage.PredecessorDivision = Undefined,
			SampleStage.Department, SampleStage.PredecessorDivision);
		
		// Calculation of the Finished Product that is transferred between stages (intermediate FinishedProduct)
		IntermediateProductItem = Undefined;
		IntermediateProductVariant = Undefined;
		IntermediateFinishedproductItemType = Undefined;
		IntermediateProductPackagingUnit = Undefined;
		IntermediateProductItemPresentation = "";
		IntermediateFinishedProductQuality = Undefined;
		If Not FromBeginningOfParty Then
			If FromBeginningOfStage Then
				// The release is in the predecessor, the provision is at the point of division
				QueryText = 
					"SELECT TOP 1
					|	ProductionIssue.Products                 AS Products,
					|	ProductionIssue.Products.ItemsType AS ItemsType,
					|	ProductionIssue.Products.Presentation   AS ProductsPresentation,
					|	ProductionIssue.Characteristic               AS Characteristic,
					|	ProductionIssue.Package                     AS Package,
					|	ProductionIssue.Products.Quality        AS Quality
					|FROM
					|	Document.ProductionStage2_2.SideAndIntermediateRelease AS ProductionIssue
					|WHERE
					|	ProductionIssue.Ref IN (
					|		SELECT
					|			Predecessors.Predecessor AS Ref
					|		FROM
					|			TTPredecessors AS Predecessors
					|		WHERE
					|			Predecessors.Predecessor.ProductionLot = &ProductionLot)
					|	AND TRUE IN (
					|		SELECT TOP 1
					|			TRUE
					|		FROM
					|			Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Supply
					|		WHERE
					|			Supply.Ref = &Stage
					|			AND Supply.Products = ProductionIssue.Products
					|			AND Supply.Characteristic = ProductionIssue.Characteristic
					|			AND NOT Supply.Canceled)
					|	AND NOT ProductionIssue.Canceled
					|	AND ProductionIssue.Products.UnitOfMeasure = &ProductUnitOfMeasurement
					|	AND ISNULL(&PackagingFactor, 1) = &FinishedProductPackagingUnitRatio";
				QueryText = StrReplace(
					QueryText,
					"&PackagingFactor",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"ProductionIssue.Package",
						"ProductionIssue.Products"));
				
				Query.Text = QueryText;
				Query.SetParameter("Stage", Stage);
				Query.SetParameter("ProductUnitOfMeasurement", ProductUnitOfMeasurement);
				Query.SetParameter("FinishedProductPackagingUnitRatio", SampleStage.PackagingFactor);
				SampleFinishedProduct = Query.Execute().Select();
				If SampleFinishedProduct.Next() Then
					IntermediateProductItem = SampleFinishedProduct.Products;
					IntermediateProductVariant = SampleFinishedProduct.Characteristic;
					IntermediateFinishedproductItemType = SampleFinishedProduct.ItemsType;
					IntermediateProductPackagingUnit = SampleFinishedProduct.Package;
					IntermediateProductItemPresentation = SampleFinishedProduct.ProductsPresentation;
					IntermediateFinishedProductQuality = SampleFinishedProduct.Quality;
				EndIf;
			Else
				// Release is at the point of division, provision is at the follower
				Documents.ProductionStage2_2.CreateTTFollowers(TempTablesManager, Stage);
				QueryText = 
					"SELECT TOP 1
					|	Supply.Products                 AS Products,
					|	Supply.Products.ItemsType AS ItemsType,
					|	Supply.Products.Presentation   AS ProductsPresentation,
					|	Supply.Characteristic               AS Characteristic,
					|	Supply.Package                     AS Package,
					|	Supply.Products.Quality        AS Quality
					|FROM
					|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Supply
					|WHERE
					|	Supply.Ref IN (
					|		SELECT
					|			Successors.Follower AS Ref
					|		FROM
					|			TTFollowers AS Successors
					|		WHERE
					|			Successors.Follower.ProductionLot = &ProductionLot)
					|	AND TRUE IN (
					|		SELECT TOP 1
					|			TRUE
					|		FROM
					|			Document.ProductionStage2_2.SideAndIntermediateRelease AS ProductionIssue
					|		WHERE
					|			ProductionIssue.Ref = &Stage
					|			AND ProductionIssue.Products = Supply.Products
					|			AND ProductionIssue.Characteristic = Supply.Characteristic
					|			AND NOT ProductionIssue.Canceled)
					|	AND NOT Supply.Canceled
					|	AND Supply.Products.UnitOfMeasure = &ProductUnitOfMeasurement
					|	AND ISNULL(&PackagingFactor, 1) = &FinishedProductPackagingUnitRatio";
				QueryText = StrReplace(
					QueryText,
					"&PackagingFactor",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"Supply.Package",
						"Supply.Products"));
				
				Query.Text = QueryText;
				Query.SetParameter("Stage", Stage);
				Query.SetParameter("ProductUnitOfMeasurement", ProductUnitOfMeasurement);
				Query.SetParameter("FinishedProductPackagingUnitRatio", SampleStage.PackagingFactor);
				SampleFinishedProduct = Query.Execute().Select();
				If SampleFinishedProduct.Next() Then
					IntermediateProductItem = SampleFinishedProduct.Products;
					IntermediateProductVariant = SampleFinishedProduct.Characteristic;
					IntermediateFinishedproductItemType = SampleFinishedProduct.ItemsType;
					IntermediateProductPackagingUnit = SampleFinishedProduct.Package;
					IntermediateProductItemPresentation = SampleFinishedProduct.ProductsPresentation;
					IntermediateFinishedProductQuality = SampleFinishedProduct.Quality;
				EndIf;
			EndIf;
		EndIf;
		
		// Calculation of the number of Nonconformities
		NumberOfPackagingUnitsNonconformity = 0;
		Query.Text = "
		|SELECT
		|	SUM(Queue.Required2)       AS Required2,
		|	SUM(Queue.DefectiveGoods)            AS DefectiveGoods
		|INTO Queue
		|FROM
		|	InformationRegister.QueueOfProductionOperations AS Queue
		|WHERE
		|	Queue.Department = &Department
		|	AND Queue.Stage = &Stage
		|	AND Queue.Required2 <> 0
		|	AND (Queue.DefectiveGoods <> 0
		|		OR Queue.Operation = VALUE(Catalog.ManufacturingOperations.EmptyRef))
		|GROUP BY
		|	CASE
		|		WHEN Queue.Operation = VALUE(Catalog.ManufacturingOperations.EmptyRef)
		|			THEN 0
		|		ELSE Queue.OperationID
		|	END,
		|	Queue.OperationNumber,
		|	Queue.NextOperation
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(&NumberOfPackages * Queue.DefectiveGoods / Queue.Required2) AS NumberOfPackagingUnitsNonconformity
		|FROM
		|	Queue AS Queue
		|HAVING
		|	SUM(Queue.DefectiveGoods / Queue.Required2) <= 1
		|";
		Query.SetParameter("Stage", Stage);
		Query.SetParameter("Department", SampleStage.Department);
		Query.SetParameter("NumberOfPackages", SampleStage.NumberOfPackages);
		SelectionDefectiveGoods = Query.Execute().Select();
		If SelectionDefectiveGoods.Next() Then
			NumberOfPackagingUnitsNonconformity = SelectionDefectiveGoods.NumberOfPackagingUnitsNonconformity;
			If Int(NumberOfPackagingUnitsNonconformity) <> NumberOfPackagingUnitsNonconformity
				And SampleStage.PackagingPiece
				And Int(SampleStage.NumberOfPackages) = SampleStage.NumberOfPackages Then
				NumberOfPackagingUnitsNonconformity = Int(NumberOfPackagingUnitsNonconformity) + 1;
			EndIf;
		EndIf;
		
		Result = New Structure;
		Result.Insert("StagePresentation", StagePresentation);
		Result.Insert("Department", Department);
		Result.Insert("Package", SampleStage.Package);
		Result.Insert("ItemPackagePresentation", SampleStage.ItemPackagePresentation);
		Result.Insert("PackagingFactor", SampleStage.PackagingFactor);
		Result.Insert("Manufactured", Manufactured);
		Result.Insert("CreateStage", CreateStage);
		Result.Insert("BOMStage", SampleStage.Stage);
		Result.Insert("BOMStagePresentation", BOMStagePresentation);
		Result.Insert("BillOfMaterialsStageDepartment", SampleStage.StageDivision);
		Result.Insert("FromBeginningOfParty", FromBeginningOfParty);
		Result.Insert("DivisionCancellationFromBeginningOfParty", DivisionCancellationFromBeginningOfParty);
		Result.Insert("FromBeginningOfStage", FromBeginningOfStage);
		Result.Insert("IntermediateProductItem", IntermediateProductItem);
		Result.Insert("IntermediateProductVariant", IntermediateProductVariant);
		Result.Insert("IntermediateFinishedproductItemType", IntermediateFinishedproductItemType);
		Result.Insert("IntermediateProductPackagingUnit", IntermediateProductPackagingUnit);
		Result.Insert("IntermediateProductItemPresentation", IntermediateProductItemPresentation);
		Result.Insert("IntermediateFinishedProductQuality", IntermediateFinishedProductQuality);
		Result.Insert("ProducedInPredecessors", ProducedInPredecessors);
		Result.Insert("NumberOfPackagingUnitsNonconformity", NumberOfPackagingUnitsNonconformity);
		Result.Insert("ReleaseOfFinishedproducts", ReleaseOfFinishedproducts);
		Result.Insert("ThisIsLastStageAndOperation", ThisIsLastStageAndOperation);
		Result.Insert("CostSharesAreFilledInStage", SampleStage.CostSharesAreFilledInStage);
		Result.Insert("WorkPlanning", SampleStage.WorkPlanning);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInAccordingToStageData(Data_Stage)
	
	FillPropertyValues(ThisObject, Data_Stage,
		"StagePresentation,
		|BOMStage,
		|BOMStagePresentation,
		|BillOfMaterialsStageDepartment,
		|Manufactured,
		|ProducedInPredecessors,
		|ItemPackagePresentation,
		|IntermediateFinishedproductItemType,
		|IntermediateProductItemPresentation,
		|IntermediateFinishedProductQuality,
		|DivisionCancellationFromBeginningOfParty,
		|PackagingFactor,
		|WorkPlanning");
	
	FillPropertyValues(Object, Data_Stage,
		"Department,
		|CreateStage,
		|Package,
		|FromBeginningOfParty,
		|FromBeginningOfStage,
		|IntermediateProductItem,
		|IntermediateProductVariant,
		|IntermediateProductPackagingUnit,
		|ThisIsLastStageAndOperation,
		|CostSharesAreFilledInStage");
	
	Object.NumberOfPackages = ?(Data_Stage.PackagingFactor <> 0,
		Object.Count/Data_Stage.PackagingFactor, 0);
	
	If TypeOf(Data_Stage.ReleaseOfFinishedproducts) = Type("ValueTable")
		And Data_Stage.ReleaseOfFinishedproducts.Count() > 0 Then
		ReleaseOfFinishedproducts.Load(Data_Stage.ReleaseOfFinishedproducts);
	Else
		ReleaseOfFinishedproducts.Clear();
	EndIf;
	
	For Each String In Object.Lots Do
		String.Manufactured = Manufactured;
		String.Department = Object.Department;
		
		If String.ContinueBOM = Object.BillOfMaterials Then
			String.ContinueStage = BOMStage;
			String.ContinueStagePresentation = BOMStagePresentation;
			String.ContinueStageDepartment = BillOfMaterialsStageDepartment;
			String.Continue_Operation = Object.Operation;
			String.ContinueOperationID = Object.OperationID;
			String.AddressProductionProcess = AddressProductionProcess;
		EndIf;
	EndDo;
	
	For Each String In Object.SetOfSeries Do
		String.Manufactured = Manufactured;
		String.Department = Object.Department;
	EndDo;
	
EndProcedure

&AtClient
Procedure WhenYouStartEditingBatch()
	
	If Items.Lots.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FillInSelectionListReleaseDirectionForm();
	
	CurrentData = Object.Lots.FindByID(Items.Lots.CurrentRow);
	TypeRestriction = LimitingRecipientType(CurrentData);
	Items.Recipient.TypeRestriction = TypeRestriction;
	Items.LotsRecipient.TypeRestriction = TypeRestriction;
	
	// Caching
	ProcessingOfTabularFormsClient.CacheCurLine(
		Items.Lots,
		ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Items.Lots,
		CachedValues,
		SeriesSpecificationParameters,
		False);
	
EndProcedure

&AtServer
Procedure AddBatch(LotIndex)
	
	NewRow = Object.Lots.Add();
	NewRow.LotIndex = LotIndex;
	NewRow.Manufactured = Manufactured;
	NewRow.ProductionDate = CurrentSessionDate();
	NewRow.Recipient = PredefinedValue("Catalog.Warehouses.EmptyRef");
	NewRow.DirectionOfProductionIssue = Enums.BusinessTransactions.ProductsReleaseToWarehouse;
	NewRow.TheDirectionOfTheReleaseForm = DirectionToContinueProcessing();
	NewRow.ContinueProcessing = True;
	NewRow.ContinueBOM = Object.BillOfMaterials;
	NewRow.ContinueStage = BOMStage;
	NewRow.ContinueStagePresentation = BOMStagePresentation;
	NewRow.ContinueStageDepartment = BillOfMaterialsStageDepartment;
	NewRow.Continue_Operation = Object.Operation;
	NewRow.ContinueOperationID = Object.OperationID;
	NewRow.AddressProductionProcess = AddressProductionProcess;
	NewRow.PackageOfLot = Object.Package;
	NewRow.BatchProducts = Object.MainProductProducts;
	NewRow.Department = Object.Department;
	NewRow.AssignmentsPresentation = NStr("vi = 'Chỉ ra mục đích';
											|ru = 'Указать назначения';
											|en = 'Specify assignments'; fa = 'تعیین تخصیص‌ها';
											|it = 'Indicare le assegnazioni';
											|pl = 'Określ przeznaczenia';
											|tr = 'Atama belirt'");
	NewRow.ContinueItem = Object.MainProductProducts;
	NewRow.ContinueVariant = Object.MainProductCharacteristic;
	
	WarehousesClientServer.FillDefaultWarehouse(
		UseSeveralWarehouses, 
		DefaultWarehouse, 
		NewRow,
		"Recipient");
	
	IncomeAndExpensesClientServer.WhenAddingRowToTable(
		ThisObject,
		NewRow,
		"Object.Lots");
	
EndProcedure

&AtServerNoContext
Function PartyPresentation(BatchCode, TheNumberOfTheOrder)
	
	Return TrimAll(ObjectsPrefixesClientServer.DeleteLeadingZerosFromObjectNumber(TheNumberOfTheOrder))
			+ "."
			+ Format(BatchCode, "NG=0");
	
EndFunction

&AtServerNoContext
Function CalculateNumberOfBatchUnits(Products, Package, NumberOfPackages)
	
	PackageData = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(
		Package,
		Products);
	
	Result = NumberOfPackages * PackageData.ZoomRatio;
		
	If PackageData.NeedToRoundUpQuantity Then
		Result = Round(Result, 0 ,RoundMode.Round15as20);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetUpAutomaticQuantityCalculation(CurrentData, AttributesList, CachedValues = Undefined)
	
	AttributesList = AttributesList + ", AutomaticCalculationOfQuantity";
	
	If Object.Action <> Actions().DefectiveGoods
			Or CurrentData.AutoSelectingItemsIsWork Then
		CurrentData.AutomaticCalculationOfQuantity = False;
		Return;
	ElsIf CurrentData.Products.IsEmpty() Then
		CurrentData.AutomaticCalculationOfQuantity = True;
		Return;
	EndIf;
	
	CurrentData.AutomaticCalculationOfQuantity = False;
	
	If Object.Package.IsEmpty() Then
		If ProductUnitOfMeasurement = CurrentData.UnitOfMeasure Then
			CurrentData.AutomaticCalculationOfQuantity = True;
			CurrentData.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		EndIf;
	ElsIf CurrentData.AutomaticSelectionOfItems Then
		CurrentData.AutomaticCalculationOfQuantity = True;
	Else
		// Search for an Identical PackagingUnit
		QueryText =
			"SELECT TOP 1
			|	ProductPackaging.Ref AS Package
			|FROM
			|	Catalog.PackagesAndUnitsOfMeasure AS FinishedProductPackagingUnits
			|
			|	INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackaging
			|	ON &QueryTextPackagingFactor1 = &QueryTextPackagingFactor2
			|		AND FinishedProductPackagingUnits.UnitOfMeasure = ProductPackaging.UnitOfMeasure
			|		AND FinishedProductPackagingUnits.WarehouseGroup = ProductPackaging.WarehouseGroup
			|WHERE
			|	FinishedProductPackagingUnits.Ref = &Ref
			|	AND ProductPackaging.Owner = 
			|		CASE
			|			WHEN CAST(&Products AS Catalog.Products).PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
			|				THEN &Products
			|			ELSE CAST(&Products AS Catalog.Products).PackagingGroup
			|		END
			|
			|ORDER BY
			|	ProductPackaging.Description,
			|	ProductPackaging.Ref";
		
		QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"FinishedProductPackagingUnits", Undefined));
			
		QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPackaging", Undefined));
		
		Query = New Query(QueryText);
		Query.SetParameter("Ref", Object.Package);
		Query.SetParameter("Products", CurrentData.Products);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			CurrentData.AutomaticCalculationOfQuantity = True;
			CurrentData.Package = Selection.Package;
		EndIf;
	EndIf;
	
	If CurrentData.AutomaticCalculationOfQuantity Then
		CurrentData.NumberOfPackages = ?(CurrentData.LineNumber = 1,
			Object.NumberOfPackagingUnitsNonconformity,
			Object.NumberOfPackages - Object.NumberOfPackagingUnitsNonconformity);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
		StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
		BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	EndIf;
	
EndProcedure

&AtServer
Function ActionParameterFillInAssignment(CurrentData)
	
	Return ?(CurrentData.ContinueProcessing Or CurrentData.ToExpenseAs,
		Catalogs.Assignments.EmptyRef(),
		PurposeOfTollRelease);
	
EndFunction

&AtClientAtServerNoContext
Function YouCanCancelFINISHEDProductInOrder(Form, CurrentData)
	
	Object = Form.Object; // DataProcessorObject.ProductionLotDivision
	Actions = Actions();
	
	Result = False;
	
	If Form.ThisIsFinishedProductOfOrder Then
		// Cancel
		If Object.Action = Actions.DefectiveGoods And CurrentData.LineNumber = 1
			Or Object.Action = Actions.Cancel Then
			Result = True;
		// Abbr
		ElsIf Object.Action = Actions.Reduce
			And CurrentData.LotQuantity < Object.Count Then
			Result = True;
		// Division with cancellation
		ElsIf Object.Action = Actions.Split
			And Not Object.FromBeginningOfParty
			And Not CurrentData.ContinueProcessing Then
			Result = True;
		// Changing the FINISHEDproduct
		ElsIf (Object.Action = Actions.Split And Not Object.FromBeginningOfParty
				Or Object.Action = Actions.DefectiveGoods And CurrentData.LineNumber = 2
				Or Object.Action = Actions.Continue)
			And CurrentData.ContinueProcessing
			And CurrentData.ChangeProductToBeReleased Then
			Result = True;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function OperationPresentation(Object)
	
	Result = "";
	
	If OfOperationSelected(Object) Then
		Source = ?(Not Object.Operation.IsEmpty(), Object.Operation, Object.ProductionOperation);
		Result = Common.ObjectAttributeValue(Source, "Description");
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function OfOperationSelected(RowData)
	
	Return RowData.OperationID <> 0;
	
EndFunction

&AtServer
Function OperationsOfStageHaveBegun()
	
	QueueManager = New TempTablesManager();
	DataProcessors.ProductionLotDivision.CreateTTQueueOfOperationsForDivision(QueueManager, Object.Stage);
	
	Query = New Query(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	TTOperationQueue AS Queue
		|WHERE
		|	Queue.IsStarted");
	Query.TempTablesManager = QueueManager;
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

Function ReceivingBusinessUnit(CurrentData)
	
	If CurrentData.ContinueProcessing
		And ValueIsFilled(CurrentData.ContinueStageDepartment) Then
		Return CurrentData.ContinueStageDepartment;
	Else
		Return CurrentData.Department;
	EndIf;
	
EndFunction

&AtClient
Procedure ContinueStagePresentationStartChoiceCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		
		CurrentData = Items.Lots.CurrentData;
		CurrentData.ContinueStage = ClosingResult.Stage;
		CurrentData.ContinueStageDepartment = ClosingResult.Department;
		
		If ValueIsFilled(ClosingResult.Operation) Then
			CurrentData.ContinueStagePresentation =
				StrTemplate("%1 / %2", ClosingResult.StagePresentation, ClosingResult.OperationPresentation);
			CurrentData.Continue_Operation = ClosingResult.Operation;
			CurrentData.ContinueOperationID = ClosingResult.OperationID;
		Else
			CurrentData.ContinueStagePresentation = ClosingResult.StagePresentation;
			CurrentData.Continue_Operation = Undefined;
			CurrentData.ContinueOperationID = 0;
		EndIf;
		
		If CurrentData.AutoSelectingItemsIsWork Then
			CurrentData.Recipient = CurrentData.ContinueStageDepartment;
		EndIf;
		
		ContinueStepOnChangeATServer(CachedValues);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ContinueStepOnChangeATServer(CachedValues)
	
	CurrentData = Object.Lots.FindByID(Items.Lots.CurrentRow);
	
	DataBeforeChange = New Structure;
	DataBeforeChange.Insert("Recipient", CurrentData.Recipient);
	DataBeforeChange.Insert("ShopFloorStockroom", CurrentData.ShopFloorStockroom);
	DataBeforeChange.Insert("BatchesIndicationStatus", CurrentData.BatchesIndicationStatus);
	DataBeforeChange.Insert("BatchesIndicationStatusSender", CurrentData.BatchesIndicationStatusSender);
	DataBeforeChange.Insert("BatchesIndicationStatusRecipient", CurrentData.BatchesIndicationStatusRecipient);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", CurrentData.Recipient, SeriesSpecificationParameters));
	
	If Not CurrentData.AutoSelectingItemsIsWork Then
		ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
			ReceivingBusinessUnit(CurrentData), StructureOfActions, "Recipient");
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If Not CurrentData.AutoSelectingItemsIsWork
		And Not ValueIsFilled(CurrentData.Recipient)
		And ValueIsFilled(DataBeforeChange.Recipient) Then
		FillPropertyValues(CurrentData, DataBeforeChange);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
