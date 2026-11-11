
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.CalculateStatistics Then
		
		TimeConsumingOperation = GetConsumptionStatisticsInBackground();
		
	ElsIf TypeOf(Parameters.ConsumptionStatistics) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, Parameters.ConsumptionStatistics);
		
	EndIf;
	
	SettingSpecificationMethod = "";
	If Parameters.OpeningMode = "Full" Or Parameters.OpeningMode = "ParametersOnly" Then
		
		// Obtaining a record of the register of Commodity restrictions.
		SettingValue = InformationRegisters.ProductRestrictions.ParametersForMaintainingStockOfGoodsInStock(Parameters.NeedKey);
		SettingSpecificationMethod = SettingValue.SettingSpecificationMethod;
		GroupingProductRestrictions = SettingValue.GroupingProductRestrictions;
		StrategyOfProcurement  = SettingValue.InventoryReplenishmentMethod;
		MinimumInventory  = SettingValue.MinimumInventoryQuantity;
		MaximumInventory = SettingValue.MaximumInventoryAmount;
		SafetyStock    = SettingValue.SafetyStockQuantity;
		OrderPackage    = SettingValue.OrderPackage;
		OrderFulfillmentWithinInventoryReplenishment = SettingValue.OrderFulfillmentWithinInventoryReplenishment;
		ConsumptionRate  = SettingValue.ConsumptionRate;
		
	EndIf;
	
	If Parameters.OpeningMode = "Full" Or Parameters.OpeningMode = "OnlyWay" Then
		// Initialization of the provision method and the parameters of the provision method.
		GetCustomizedAndLegacyWaysOfProvidingOnServer(Parameters.NeedKey);
		MethodIndividualOld = TheMethodIsIndividual;
		
		BeginOfPeriod = BegOfDay(CurrentSessionDate());
		
		If ValueIsFilled(InheritedMethod) Then
			ParametersOfTheDeliveryCycleAccordingToTheWorkScheduleInherited = DeliveryCycleParametersAccordingToWorkSchedule(
				Parameters.NeedKey, InheritedMethod, BeginOfPeriod);
		Else
			ParametersOfTheDeliveryCycleAccordingToTheWorkScheduleInherited = StructureOfDeliveryCycleParametersAccordingToWorkSchedule();
		EndIf;
			
		If ValueIsFilled(TheMethodIsIndividual) Then
			ParametersOfTheDeliveryCycleAccordingToTheWorkScheduleAreIndividual = DeliveryCycleParametersAccordingToWorkSchedule(
				Parameters.NeedKey, TheMethodIsIndividual, BeginOfPeriod);
		Else
			ParametersOfTheDeliveryCycleAccordingToTheWorkScheduleAreIndividual = StructureOfDeliveryCycleParametersAccordingToWorkSchedule();
		EndIf;
		
		MethodSwitch = ?(ValueIsFilled(TheMethodIsIndividual), 1, 0);
	EndIf;
	
	If TypeOf(Parameters.NeedKey) = Type("Structure")
		And Parameters.NeedKey.Property("Products") Then
		
		Products = Parameters.NeedKey.Products;
		UnitOfMeasure = Common.ObjectAttributeValue(
			Products, "UnitOfMeasure");
		
	EndIf;
	
	If Parameters.OpeningMode = "MethodOnly" Then
		
		StrategyOfProcurement = Parameters.NeedKey.StrategyOfProcurement;
		
	EndIf;
	
	// Configuring the form interface.
	
	SettingIsSpecifiedForGroup = SettingSpecificationMethod = "FOR_GROUP_Products"
		Or SettingSpecificationMethod = "FOR_CHARACTERISTICSOfProduct";
	
	If Parameters.OpeningMode = "ParametersOnly" 
		And ((SettingSpecificationMethod = "FOR_GROUP_Products" And Not ValueIsFilled(Parameters.NeedKey.Products))
			Or (SettingSpecificationMethod = "FOR_CHARACTERISTICSOfProduct" And Not ValueIsFilled(Parameters.NeedKey.Characteristic))) Then
			Items.GroupWarningAboutTheProhibitionOfEditingParameters.Visible	= False;
			Items.TheGroupMethodOfProviding.Enabled								= True;
		Else
			Items.GroupWarningAboutTheProhibitionOfEditingParameters.Visible	= SettingIsSpecifiedForGroup;
			Items.TheGroupMethodOfProviding.Enabled								= Not SettingIsSpecifiedForGroup;
	EndIf;
	If SettingSpecificationMethod = "FOR_GROUP_Products" Then
		
		TextTemplate1 = NStr("vi = 'Các tham số phương thức và đảm bảo được đặt cho nhóm được sử dụng: %1';
							|ru = 'Используются метод и параметры обеспечения, установленные для группы: %1';
							|en = 'Inventory replenishment method and procurement parameters set for the group: %1'; fa = 'Inventory replenishment method and procurement parameters set for the group: %1';
							|it = 'Vengono utilizzati il metodo e i parametri di approvvigionamento stabiliti per il gruppo: %1';
							|pl = 'Zastosowano metodę i parametry zestawu zabezpieczeń dla grupy: %1';
							|tr = 'Grup için ayarlanan tedarik yöntemi ve parametreler kullanılır: %1'");
		Items.PictureCannotEditParameters.ExtendedTooltip.Title =
			StrTemplate(TextTemplate1, GroupingProductRestrictions);
		
	ElsIf SettingSpecificationMethod = "FOR_CHARACTERISTICSOfProduct" Then
		
		TextTemplate1 = NStr("vi = 'Phương thức và tham số của đảm bảo được đặt toàn bộ cho Mặt hàng được sử dụng: %1';
							|ru = 'Используются метод и параметры обеспечения, установленные в целом для номенклатуры: %1';
							|en = 'Inventory replenishment method and procurement parameters set for products as a whole are used: %1'; fa = 'Inventory replenishment method and procurement parameters set for products as a whole are used: %1';
							|it = 'Vengono utilizzati il metodo e i parametri di approvvigionamento stabiliti per l'' articolo in toto: %1';
							|pl = 'Stosuje się metodę i parametry zabezpieczenia, stosowane w całej nomenklaturze: %1';
							|tr = 'Ürün gamı için genel olarak ayarlanan tedarik yöntemi ve parametreler kullanılıyor: %1'");
		Items.PictureCannotEditParameters.ExtendedTooltip.Title =
			StrTemplate(TextTemplate1, Parameters.NeedKey.Products);
		
	EndIf;
	
	If Parameters.OpeningMode = "Full" Or Parameters.OpeningMode = "OnlyWay" 
		Or Parameters.OpeningMode = "ParametersOnly" Then
		// 1) Setting the form header.
		If Parameters.NeedKey.Property("GroupingProductRestrictions") Then
			Items.KeyWithString.Title = 
				StrTemplate(NStr("vi = 'Phân nhóm: %1.';
								|ru = 'Группировка: %1.';
								|en = 'Grouping: %1'; fa = 'Grouping: %1';
								|it = 'Raggruppamento: %1.';
								|pl = 'Grupowanie: %1.';
								|tr = 'Gruplama: %1.'"),Parameters.NeedKey.GroupingProductRestrictions);
		Else
			TextCharacteristics = ?(ValueIsFilled(Parameters.NeedKey.Characteristic),
				StrTemplate(NStr("vi = ', Đặc tính: %1';
								|ru = ', Характеристика: %1';
								|en = ', Variant: %1'; fa = ', Variant: %1';
								|it = ', Caratteristica: %1';
								|pl = ', Charakterystyka: %1';
								|tr = ', Özellik: %1'"), Parameters.NeedKey.Characteristic), "");
			TextWarehouse = ?(Parameters.NeedKey.ThisIsWork, "",
				StrTemplate(NStr("vi = ', Kho bãi: %1';
								|ru = ', Склад: %1';
								|en = ', Warehouse: %1'; fa = ', Warehouse: %1';
								|it = ', Magazzino: %1';
								|pl = ', Magazyn: %1';
								|tr = ', Ambar: %1'"), Parameters.NeedKey.Warehouse));
			
			Items.KeyWithString.Title = StrTemplate(NStr("vi = 'Mặt hàng: %1%2%3.';
														|ru = 'Номенклатура: %1%2%3.';
														|en = 'Items: %1%2%3.'; fa = 'Items: %1%2%3.';
														|it = 'Articolo: %1%2%3.';
														|pl = 'Nomenklatura: %1%2%3.';
														|tr = 'Ürün gamı: %1%2%3.'"),
				Parameters.NeedKey.Products, TextCharacteristics, TextWarehouse);
		EndIf;
			
		// 2) Filling in the list of switches of the security method.
		If Parameters.OpeningMode <> "ParametersOnly" Then
			Items.InheritedMethodSwitch.ChoiceList[0].Presentation =
				?(Not ValueIsFilled(InheritedMethod),
					NStr("vi = 'Không sử dụng (đặt tham số đảm bảo trong quá trình lập đơn hàng)';
						|ru = 'Не использовать (задавать параметры обеспечения в процессе формирования заказа)';
						|en = 'Do not use (set fulfillment parameters when placing order)'; fa = 'Do not use (set fulfillment parameters when placing order)';
						|it = 'Non usare (impostare i parametri di approvvigionamento nel corso di generazione ordine)';
						|pl = 'Nie używaj (ustaw parametry zabezpieczenia w procesie zamawiania)';
						|tr = 'Kullanma (sipariş oluşturma sürecinde tedarik parametrelerini ayarla)'"),
					StrTemplate(NStr("vi = '""%1"" (được cài đặt cho sơ đồ hỗ trợ mặt hàng)';
									|ru = '""%1"" (настроенный для схемы обеспечения номенклатуры)';
									|en = '""%1""  (set for the products supply scheme)'; fa = '""%1""  (set for the products supply scheme)';
									|it = '""%1"" (configurato per lo schema di approvvigionamento della articolo)';
									|pl = '""%1"" (skonfigurowany do schematu konserwacji nomenklatury)';
									|tr = '""%1"" (ürün gamı arz şeması için ayarlanmış)'"), InheritedMethod));
		EndIf;
	EndIf;
	
	If Parameters.OpeningMode = "Full" Then
		
		Items.OKCancel.Visible = False;
		Title = NStr("vi = 'Tham số đảm bảo nhu cầu';
					|ru = 'Параметры обеспечения потребностей';
					|en = 'Demand fulfillment parameters'; fa = 'پارامترهای تأمین نیاز';
					|it = 'I parametri di approvvigionamento dei fabbisogni';
					|pl = 'Parametry zaspokojenia zapotrzebowania';
					|tr = 'Talebi karşılama parametreleri'");
		
	ElsIf Parameters.OpeningMode = "ParametersOnly" Then
		
		Items.OKCancel.Visible = False;
		Items.TheGroupIsAWayToEnsure.Visible = False;
		Items.SwitchToOrderUnderOrder.Visible = False;
		Items.HintCustomMadeToOrder.Visible     = False;
		
		Title = NStr("vi = 'Tham số bảo đảm';
					|ru = 'Параметры поддержания запаса';
					|en = 'Inventory replenishment settings'; fa = 'Inventory replenishment settings';
					|it = 'Parametri di mantenimento delle scorte';
					|pl = 'Opcje konserwacji zapasów';
					|tr = 'Stok yenileme parametreleri'");
		
	ElsIf Parameters.OpeningMode = "OnlyWay" Then
		
		Items.OKCancel.Visible = False;
		Items.TheGroupMethodOfProviding.Visible = False;
		Title = NStr("vi = 'Tham số đảm bảo nhu cầu';
					|ru = 'Параметры обеспечения потребностей';
					|en = 'Demand fulfillment parameters'; fa = 'پارامترهای تأمین نیاز';
					|it = 'I parametri di approvvigionamento dei fabbisogni';
					|pl = 'Parametry zaspokojenia zapotrzebowania';
					|tr = 'Talebi karşılama parametreleri'");
		
	ElsIf Parameters.OpeningMode = "MethodOnly" Then
		
		OrderFulfillmentWithinInventoryReplenishment = Enums.OrderFulfillmentWithinInventoryReplenishment.SupplyFromStock;
		Items.KeyWithString.Visible   = False;
		Items.TheGroupIsAWayToEnsure.Visible  = False;
		Items.MethodForProvidingAString.Visible = False;
		
		Items.SwitchToOrderUnderOrder.Visible = False;
		Items.HintCustomMadeToOrder.Visible     = False;
		
		If Not ValueIsFilled(Products) Then
			Items.UnitOfMeasure.Visible      = False;
			Items.UnitOfMeasurementMin.Visible   = False;
			Items.UnitOfMeasureMax.Visible  = False;
			Items.UnitOfMeasurementFear.Visible = False;
		EndIf;
		
		Items.WriteClose.Visible          = False;
		Items.OK.DefaultButton               = True;
		
		Title = NStr("vi = 'Tham số bảo đảm';
					|ru = 'Параметры поддержания запаса';
					|en = 'Inventory replenishment settings'; fa = 'Inventory replenishment settings';
					|it = 'Parametri di mantenimento delle scorte';
					|pl = 'Opcje konserwacji zapasów';
					|tr = 'Stok yenileme parametreleri'");
		
	EndIf;
	
	UsePackages = Parameters.OpeningMode = "Full"
		And GetFunctionalOption("UseItemPackages");
	If Not UsePackages Then
		Items.ThePackagingOfTheOrderHeader.Visible = False;
		Items.PagesPackagingValues.Visible = False;
	EndIf;
	
	AccessRights = SupplyServer.WriteAccessRightsForMethodOrMethod();
	ArrayOfElementNames = New Array();
	If Not AccessRights.SupplyOptions Then
		ArrayOfElementNames.Add("TheGroupIsAWayToEnsure");
	EndIf;
	
	If Not AccessRights.ProductRestrictions Then
		ArrayOfElementNames.Add("TheGroupMethodOfProviding");
	EndIf;
	
	If Not AccessRights.SupplyOptions And Not AccessRights.ProductRestrictions Then
		ArrayOfElementNames.Add("FormWriteAndClose");
		ArrayOfElementNames.Add("FormWrite");
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Enabled", False);
	
	ErrorColor = Metadata.StyleItems.ErrorNoteText.Value;
	HelpTextColor = Metadata.StyleItems.NoteText.Value;
	ColorFromStyle = Items.MinimumLineMargin.TextColor;

	CloseOnChoice = False;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(TimeConsumingOperation) Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
			New CallbackDescription("GetConsumptionStatisticsInBackgroundCompletion", ThisObject),
			IdleParameters);
	EndIf;
	
	WhenSwitchingProvisionMethod();
	WhenSwitchingCollateralMethod();
	CalculateInventory();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ConsumptionRateOnChange(Item)
	CalculateInventory();
EndProcedure

&AtClient
Procedure TheMethodIsIndividualOnChange(Item)
	
	If ValueIsFilled(TheMethodIsIndividual)Then
		BeginOfPeriod = BegOfDay(CommonClient.SessionDate());
		ParametersOfTheDeliveryCycleAccordingToTheWorkScheduleAreIndividual = DeliveryCycleParametersForServerCallSchedule(
			Parameters.NeedKey, TheMethodIsIndividual, BeginOfPeriod)
	Else
		ParametersOfTheDeliveryCycleAccordingToTheWorkScheduleAreIndividual = StructureOfDeliveryCycleParametersAccordingToWorkSchedule();
	EndIf;
	
	WhenSwitchingProvisionMethod();
	CalculateInventory();

EndProcedure

&AtClient
Procedure SwitchToOrderUnderOrderOnChange(Item)
	StrategyOfProcurement = PredefinedValue("Enum.InventoryReplenishmentMethods.OrderAgainstOrder");
	WhenSwitchingCollateralMethod();
EndProcedure

&AtClient
Procedure SwitchMinMaxOnChange(Item)
	StrategyOfProcurement = PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentMinMax");
	WhenSwitchingCollateralMethod();
EndProcedure

&AtClient
Procedure SwitchForAPeriodOfTimeAccordingToTheNormOnChange(Item)
	StrategyOfProcurement = PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentByStandard");
	WhenSwitchingCollateralMethod();
	CalculateInventory();
EndProcedure

&AtClient
Procedure TimeLimitSwitchForStatisticsOnChange(Item)
	StrategyOfProcurement = PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentByStatistics");
	WhenSwitchingCollateralMethod();
	CalculateInventory();
EndProcedure

&AtClient
Procedure InheritedMethodSwitchOnChange(Item)
	MethodSwitch = 0;
	WhenSwitchingProvisionMethod();
	CalculateInventory();
EndProcedure

&AtClient
Procedure SwitchWayOfTheIndividualOnChange(Item)
	MethodSwitch = 1;
	WhenSwitchingProvisionMethod();
	CalculateInventory();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Write(Command)
	
	WriteAtClient();
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)

	If WriteAtClient() Then
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure OK(Command)
	
	If Not ValueIsFilled(StrategyOfProcurement) Or
		StrategyOfProcurement = PredefinedValue("Enum.InventoryReplenishmentMethods.OrderAgainstOrder") Then
		MessageText = NStr("vi = 'Phương pháp yêu cầu không được chỉ định';
							|ru = 'Не указан метод обеспечения потребностей';
							|en = 'Inventory replenishment method is not specified'; fa = 'Inventory replenishment method is not specified';
							|it = 'Il metodo di approvvigionamento dei fabbisogni non è indicato';
							|pl = 'Brak metody zaspokajania potrzeb';
							|tr = 'Talebi karşılama yöntemi belirtilmedi'");
		CommonClient.MessageToUser(MessageText,,,"StrategyOfProcurement");
		Return;
	EndIf;
	
	ValueSelected = New Structure;
	ValueSelected.Insert("InventoryReplenishmentMethod",			StrategyOfProcurement);
	ValueSelected.Insert("MinimumInventoryQuantity",			MinimumInventory);
	ValueSelected.Insert("MaximumInventoryAmount",			MaximumInventory);
	ValueSelected.Insert("SafetyStockQuantity",				SafetyStock);
	ValueSelected.Insert("ConsumptionRate",						ConsumptionRate);
	ValueSelected.Insert("OrderFulfillmentWithinInventoryReplenishment",OrderFulfillmentWithinInventoryReplenishment);
	
	NotifyChoice(ValueSelected);
	Close();

EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetConsumptionStatisticsInBackground()
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("NeedKey", Parameters.NeedKey);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tính toán thống kê tiêu thụ';
														|ru = 'Расчет статистики потребления';
														|en = 'Calculation of consumption statistics'; fa = 'Calculation of consumption statistics';
														|it = 'Calcolo delle statistiche di consumo';
														|pl = 'Obliczanie statystyk zużycia';
														|tr = 'Tüketim istatistikleri hesaplama'");
	ExecutionParameters.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.DemandFulfillment.ConsumptionStatistics",
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure GetConsumptionStatisticsInBackgroundCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	Else
		FillInConsumptionStatisticsOnServer(Result);
		CalculateInventory();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInConsumptionStatisticsOnServer(Result)
	
	ConsumptionStatistics = GetFromTempStorage(Result.ResultAddress);
	FillPropertyValues(ThisObject, ConsumptionStatistics);
	TimeConsumingOperation = Undefined;
	
EndProcedure

&AtServer
Procedure GetCustomizedAndLegacyWaysOfProvidingOnServer(NeedKey)
	
	QueryText =
		"SELECT
		|	&Products   AS Products,
		|	&Characteristic AS Characteristic,
		|	&Warehouse          AS Warehouse
		|INTO TTProducts_1
		|;
		|
		|//////////////////////////////////////
		|" + InformationRegisters.SupplySchemes.TemporaryTableWaysToEnsure("CALCULATE") + "
		|;
		|
		|////////////////////////////////////
		|SELECT
		|Table.ProcurementStrategy               AS ProcurementStrategy,
		|Table.WayToEnsureNeedsIsInherited AS WayToEnsureNeedsIsInherited,
		|Table.SettingSource                           AS SettingSource
		|FROM
		|	TTWaysToEnsure AS Table";
	
	Query = New Query(QueryText);
	Query.SetParameter("Warehouse",          NeedKey.Warehouse);
	Query.SetParameter("Products",   NeedKey.Products);
	Query.SetParameter("Characteristic", NeedKey.Characteristic);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		If Selection.SettingSource = "ProductDescriptionWarehouse" Then
			
			TheMethodIsIndividual = Selection.ProcurementStrategy;
			
		EndIf;
		InheritedMethod = Selection.WayToEnsureNeedsIsInherited;
		
	EndIf;

EndProcedure

&AtServerNoContext
Function DeliveryCycleParametersAccordingToWorkSchedule(NeedKey, SupplyMethod, BeginOfPeriod)
	
	TempTablesManager = New TempTablesManager();
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CurrentDayStart" , BeginOfPeriod);
	Query.SetParameter("SupplyMethod" , SupplyMethod);
	Query.SetParameter("Warehouse" , NeedKey.Warehouse);
	Query.Text =
		"SELECT
		|	&SupplyMethod
		|INTO SupplyMethods";
	Query.Execute();
	
	ProvisionInDocumentsServer.TempTableNearestCycleBySupplyMethods(TempTablesManager);
	
	QueriesTexts = New Array();
	
	UseQualityControl = GetFunctionalOption("UseGoodsQualityControl")
		And TypeOf(NeedKey.Warehouse) = Type("CatalogRef.Warehouses");
	
	If UseQualityControl Then
		
		Query.SetParameter("Products", NeedKey.Products);
		Query.SetParameter("Warehouse", NeedKey.Warehouse);
		
		QueriesTexts.Add(ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule());
		
		Text =
			"SELECT
			|	CASE
			|		WHEN Table.ShipmentDate = DATETIME(1, 1, 1)
			|			THEN DATETIME(1, 1, 1)
			|		ELSE CalculationOfControlPeriodsOverridable.DateFound
			|	END AS ShipmentDate,
			|	Table.BoundaryOfCoveredPeriod AS BoundaryOfCoveredPeriod
			|INTO NextCycleOfSupplyMethodsIsStage1
			|FROM
			|	NextCycleBySupplyMethods AS Table
			|		LEFT JOIN CalculationOfControlPeriodsOverridable ON TRUE";
			
			Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar(
				"Table.ShipmentDate",
				"CASE
				|	WHEN CAST(&Products AS Catalog.Products).ControlQualityOfReceivedGoods
				|			AND CAST(&Warehouse AS Catalog.Warehouses).ControlQualityOfReceivedGoods
				|		THEN CAST(&Products AS Catalog.Products).TermOfQualityControl
				|	ELSE 0
				|END");
			
			Text = StrReplace(Text, "CalculationOfControlPeriodsOverridable.DateFound", Substitutions.Field);
			Text = StrReplace(Text, "LEFT JOIN CalculationOfControlPeriodsOverridable ON TRUE", Substitutions.Joins);
			
		QueriesTexts.Add(Text);
		
		Text =
			"SELECT
			|	Table.ShipmentDate AS ShipmentDate,
			|	CASE
			|		WHEN Table.BoundaryOfCoveredPeriod = DATETIME(1, 1, 1)
			|			THEN DATETIME(1, 1, 1)
			|		ELSE CalculationOfControlPeriodsOverridable.DateFound 
			|	END AS BoundaryOfCoveredPeriod
			|INTO NextCycleOnSupplyMethodsTakingIntoAccountQualityControl
			|FROM
			|	NextCycleOfSupplyMethodsIsStage1 AS Table
			|		LEFT JOIN CalculationOfControlPeriodsOverridable ON TRUE";
			
			Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar(
				"Table.BoundaryOfCoveredPeriod",
				"CASE
				|	WHEN CAST(&Products AS Catalog.Products).ControlQualityOfReceivedGoods
				|			AND CAST(&Warehouse AS Catalog.Warehouses).ControlQualityOfReceivedGoods
				|		THEN CAST(&Products AS Catalog.Products).TermOfQualityControl
				|	ELSE 0
				|END");
			
			Text = StrReplace(Text, "CalculationOfControlPeriodsOverridable.DateFound", Substitutions.Field);
			Text = StrReplace(Text, "LEFT JOIN CalculationOfControlPeriodsOverridable ON TRUE", Substitutions.Joins);
			
		QueriesTexts.Add(Text);
		
	EndIf;
	
	Text =
		// Calendars where to look for the delivery date and the period provided.
		"SELECT DISTINCT
		|	Set.Calendar AS Calendar,
		|	Set.PeriodStartDate AS PeriodStartDate,
		|	Set.PeriodEndDate AS PeriodEndDate,
		|	Set.YearOfStartInterval AS YearOfStartInterval,
		|	Set.YearOfEndOfInterval AS YearOfEndOfInterval
		|INTO ToSearchForNumberOfDaysInInterval
		|FROM(
		|	SELECT
		|		CASE
		|			WHEN ISNULL(CAST(&Warehouse AS Catalog.Warehouses).Calendar,
		|					VALUE(Catalog.Calendars.EmptyRef)) = VALUE(Catalog.Calendars.EmptyRef)
		|				THEN MainEnterpriseCalendar.Value
		|			ELSE CAST(&Warehouse AS Catalog.Warehouses).Calendar
		|		END AS Calendar,
		|		&CurrentDayStart PeriodStartDate,
		|		Method.ShipmentDate PeriodEndDate,
		|		YEAR(&CurrentDayStart) AS YearOfStartInterval,
		|		YEAR(Method.ShipmentDate) AS YearOfEndOfInterval
		|FROM
		|	NextCycleBySupplyMethods AS Method
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON TRUE
		|WHERE
		// Calculation of warehouse working days, to calculate the minimum stock.
		|	Method.ShipmentDate > DATETIME(1, 1, 1)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CASE
		|			WHEN ISNULL(CAST(&Warehouse AS Catalog.Warehouses).Calendar,
		|					VALUE(Catalog.Calendars.EmptyRef)) = VALUE(Catalog.Calendars.EmptyRef)
		|				THEN MainEnterpriseCalendar.Value
		|			ELSE CAST(&Warehouse AS Catalog.Warehouses).Calendar
		|		END AS Calendar,
		|		Method.ShipmentDate PeriodStartDate,
		|		Method.BoundaryOfCoveredPeriod PeriodEndDate,
		|		YEAR(Method.ShipmentDate) AS YearOfStartInterval,
		|		YEAR(Method.BoundaryOfCoveredPeriod) AS YearOfEndOfInterval
		|FROM
		|	NextCycleBySupplyMethods AS Method
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON TRUE
		|WHERE
		// Calculation of workdays of the warehouse, between the date of delivery and the border of the secured period
		|		Method.ShipmentDate > DATETIME(1, 1, 1)
		|			AND Method.BoundaryOfCoveredPeriod > DATETIME(1, 1, 1)) AS Set
		|INDEX BY
		|	Calendar, YearOfStartInterval, YearOfEndOfInterval";
		
	If UseQualityControl Then
		Text = StrReplace(Text, "NextCycleBySupplyMethods", "NextCycleOnSupplyMethodsTakingIntoAccountQualityControl");
	EndIf;
	
	QueriesTexts.Add(Text);
	QueriesTexts.Add(ProvisionInDocumentsServer.TempTableResultsOfCalculationOfNumberOfDaysInInterval());
	
	Text =
		"SELECT
		|	CASE
		|		WHEN IntervalBeforeDeliveryDate.DaysCount IS NULL AND TableOfSecurityMethods.ShipmentDate > DATETIME(1, 1, 1)
		|			THEN DATEDIFF(&CurrentDayStart, TableOfSecurityMethods.ShipmentDate, DAY)
		|		ELSE ISNULL(IntervalBeforeDeliveryDate.DaysCount, 0)
		|	END AS OrderFulfillmentPeriod,
		|	
		|	TableOfSecurityMethods.ShipmentDate = DATETIME(1, 1, 1) AS ErrorSettingIntervalToDeliveryDate,
		|	
		|	TableOfSecurityMethods.ShipmentDate > DATETIME(1, 1, 1)
		|		AND IntervalBeforeDeliveryDate.DaysCount IS NULL AS ErrorInCalculatingIntervalBeforeDeliveryDate,
		|	
		|	CASE
		|		WHEN IntervalBetweenDeliveries.DaysCount IS NULL
		|				AND TableOfSecurityMethods.ShipmentDate > DATETIME(1, 1, 1)
		|				AND TableOfSecurityMethods.BoundaryOfCoveredPeriod > DATETIME(1, 1, 1)
		|			THEN DATEDIFF(TableOfSecurityMethods.ShipmentDate, TableOfSecurityMethods.BoundaryOfCoveredPeriod, DAY)
		|		ELSE ISNULL(IntervalBetweenDeliveries.DaysCount, 0)
		|	END AS CoveredPeriod,
		|	
		|	TableOfSecurityMethods.ShipmentDate > DATETIME(1, 1, 1)
		|		AND TableOfSecurityMethods.BoundaryOfCoveredPeriod > DATETIME(1, 1, 1)
		|		AND IntervalBetweenDeliveries.DaysCount IS NULL AS ErrorInCalculatingIntervalBetweenDeliveries,
		|	TableOfSecurityMethods.ShipmentDate = DATETIME(1, 1, 1)
		|			OR TableOfSecurityMethods.BoundaryOfCoveredPeriod = DATETIME(1, 1, 1) AS ErrorSettingIntervalBetweenDeliveries
		|FROM
		|	NextCycleBySupplyMethods AS TableOfSecurityMethods
		|		
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON TRUE
		|		
		|		LEFT JOIN ResultsOfCalculatingNumberOfDaysInInterval AS IntervalBeforeDeliveryDate
		|		ON IntervalBeforeDeliveryDate.Calendar =
		|			CASE
		|				WHEN ISNULL(CAST(&Warehouse AS Catalog.Warehouses).Calendar,
		|						VALUE(Catalog.Calendars.EmptyRef)) = VALUE(Catalog.Calendars.EmptyRef)
		|					THEN MainEnterpriseCalendar.Value
		|				ELSE CAST(&Warehouse AS Catalog.Warehouses).Calendar
		|			END
		|		 AND IntervalBeforeDeliveryDate.PeriodStartDate = &CurrentDayStart
		|		 AND IntervalBeforeDeliveryDate.PeriodEndDate = TableOfSecurityMethods.ShipmentDate
		|
		|		LEFT JOIN ResultsOfCalculatingNumberOfDaysInInterval AS IntervalBetweenDeliveries
		|		ON IntervalBetweenDeliveries.Calendar =
		|			CASE
		|				WHEN ISNULL(CAST(&Warehouse AS Catalog.Warehouses).Calendar,
		|						VALUE(Catalog.Calendars.EmptyRef)) = VALUE(Catalog.Calendars.EmptyRef)
		|					THEN MainEnterpriseCalendar.Value
		|				ELSE CAST(&Warehouse AS Catalog.Warehouses).Calendar
		|			END
		|		 AND IntervalBetweenDeliveries.PeriodStartDate = TableOfSecurityMethods.ShipmentDate
		|		 AND IntervalBetweenDeliveries.PeriodEndDate = TableOfSecurityMethods.BoundaryOfCoveredPeriod";
		
	If UseQualityControl Then
		Text = StrReplace(Text, "NextCycleBySupplyMethods", "NextCycleOnSupplyMethodsTakingIntoAccountQualityControl");
	Else
		Text = StrReplace(Text, "DeliveryDateExcludingQualityControl", "ShipmentDate");
	EndIf;
	
	QueriesTexts.Add(Text);
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Selection = Query.Execute().Select();
	
	Result = StructureOfDeliveryCycleParametersAccordingToWorkSchedule();
	
	If Selection.Next() Then
		FillPropertyValues(Result, Selection, "OrderFulfillmentPeriod,CoveredPeriod");
		Result.CompanyCalendarIsNotFilledIn = Selection.ErrorSettingIntervalToDeliveryDate
			Or Selection.ErrorSettingIntervalBetweenDeliveries;
		Result.WarehouseCalendarIsNotFilledIn = Selection.ErrorInCalculatingIntervalBeforeDeliveryDate
			Or Selection.ErrorInCalculatingIntervalBetweenDeliveries;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient

// Returns:
//  See StructureOfDeliveryCycleParametersAccordingToWorkSchedule
Function DeliveryCycleParametersOfMainMethodOfProvision()
	
	Return ?(MethodSwitch = 1, ParametersOfTheDeliveryCycleAccordingToTheWorkScheduleAreIndividual,
			                            ParametersOfTheDeliveryCycleAccordingToTheWorkScheduleInherited);
	
EndFunction

&AtClientAtServerNoContext
Function StructureOfDeliveryCycleParametersAccordingToWorkSchedule()
	
	ParametersStructure = New Structure();
	
	ParametersStructure.Insert("OrderFulfillmentPeriod", 0);
	ParametersStructure.Insert("CoveredPeriod", 0);
	ParametersStructure.Insert("CompanyCalendarIsNotFilledIn", False);
	ParametersStructure.Insert("WarehouseCalendarIsNotFilledIn", False);
	
	Return ParametersStructure;
	
EndFunction

&AtClientAtServerNoContext
Function ThereAreDeliveryCycleErrors(DeliveryCycleParameters)
	
	Return DeliveryCycleParameters.CompanyCalendarIsNotFilledIn
			Or DeliveryCycleParameters.WarehouseCalendarIsNotFilledIn;
	
EndFunction

&AtClientAtServerNoContext
Function DeliveryCycleErrorText(DeliveryCycleParameters)
	
	Text = "";
	If DeliveryCycleParameters.CompanyCalendarIsNotFilledIn Then
		
		Text = NStr("vi = 'Lỗi tính ngày giao hàng và/hoặc biên của kỳ  được đảm bảo theo phương thức đảm bảo. Hãy điền lịch của doanh nghiệp';
					|ru = 'Ошибка расчета даты поставки и/или границы обеспечиваемого периода по способу обеспечения. Заполните календарь предприятия';
					|en = 'An error occurred when calculating the delivery date and/or the covered period boundary by the procurement strategy. Populate the enterprise calendar'; fa = 'An error occurred when calculating the delivery date and/or the covered period boundary by the procurement strategy. Populate the enterprise calendar';
					|it = 'Ошибка расчета даты поставки и/или границы обеспечиваемого периода по способу обеспечения. Заполните календарь предприятия';
					|pl = 'An error occurred when calculating the delivery date and/or the covered period boundary by the procurement strategy. Populate the enterprise calendar';
					|tr = 'Teminat yöntemine göre teslim tarihi ve/veya teminat süresi sınırlamasının hesaplanmasında hata yaşandı. işletme takvimini doldurun'");
		
	ElsIf DeliveryCycleParameters.WarehouseCalendarIsNotFilledIn Then
		
		Text = NStr("vi = 'Lỗi tính khoảng thời gian đến ngày giao hàng và / hoặc giữa các lần giao hàng. Hãy điền lịch làm việc của kho';
					|ru = 'Ошибка расчета интервала до даты поставки и / или между поставками. Заполните календарь работы склада';
					|en = 'An error occurred when calculating the interval before the delivery date and/or between deliveries. Populate the warehouse calendar'; fa = 'An error occurred when calculating the interval before the delivery date and/or between deliveries. Populate the warehouse calendar';
					|it = 'Ошибка расчета интервала до даты поставки и / или между поставками. Заполните календарь работы склада';
					|pl = 'An error occurred when calculating the interval before the delivery date and/or between deliveries. Populate the warehouse calendar';
					|tr = 'Teslimat tarihi ve/veya teslimatlar arası aralığın hesaplanmasında hata yaşandı. Ambar takvimini doldurun'");
		
	EndIf;
	
	Return Text;
	
EndFunction

&AtClient
Function FormFilledInCorrectly()
	
	If MethodSwitch = 1 And Not ValueIsFilled(TheMethodIsIndividual) Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Hãy chỉ ra phương thức đảm bảo';
										|ru = 'Укажите способ обеспечения';
										|en = 'Specify procurement strategy'; fa = 'Specify procurement strategy';
										|it = 'Indicare la modalità di approvvigionamento';
										|pl = 'Określ metodę zabezpieczenia';
										|tr = 'Tedarik stratejisini belirt'"),,, "TheMethodIsIndividual",);
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

&AtClient
Function WriteAtClient(NotCheckFilling = False)

	If Not NotCheckFilling And Not FormFilledInCorrectly() Then
		Return False;
	EndIf;
	WriteAtServer();
	If Parameters.OpeningMode <> "ParametersOnly" Then
		ValueSelected = New Structure("SupplyMethod",
			?(MethodSwitch = 1, TheMethodIsIndividual, InheritedMethod));
		
	Else
		ValueSelected = "ParameterRecorded";
	EndIf;
	NotifyChoice(ValueSelected);
	Return True;
	
EndFunction

&AtClient
Procedure WhenSwitchingProvisionMethod()
	
	If Parameters.OpeningMode = "MethodOnly" Or Parameters.OpeningMode = "ParametersOnly" Then
		Return;
	EndIf;
	
	Items.PagesIndividualMethod.CurrentPage = ?(MethodSwitch = 1,
		Items.PageUseMethod,
		Items.PageDoNotUseMethod);
		
	Deadlines = DeliveryCycleParametersOfMainMethodOfProvision();
	
	MethodForProvidingAString =
		?(MethodSwitch = 1 And Not ValueIsFilled(TheMethodIsIndividual), "",
		?(ThereAreDeliveryCycleErrors(Deadlines), DeliveryCycleErrorText(Deadlines), 
		?(Deadlines.OrderFulfillmentPeriod > 0 And Deadlines.CoveredPeriod > 0, StrTemplate(
			NStr("vi = 'Tiếp nhận gần nhất (bổ sung vật tư) dự kiến trong %1 ngày và đảm bảo kỳ %2 ngày.';
				|ru = 'Ближайшее поступление (пополнение запаса) ожидается через %1 дн и обеспечивает период %2 дн.';
				|en = 'Next receipt (inventory replenishment) is expected in %1 days and covers the period of %2 days.'; fa = 'Next receipt (inventory replenishment) is expected in %1 days and covers the period of %2 days.';
				|it = 'L''arrivo più vicino (integrazione delle scorte) è previsto tra %1 giorni e garantisce il periodo di %2 giorni.';
				|pl = 'Najbliższy wpływ (uzupełnienie zapasu) jest oczekiwany przez %1 dni i zapewnia okres %2 dni.';
				|tr = 'Bir sonraki alım (stok dolumu) %1 gün olarak bekleniyor ve %2 günlük bir süre sağlar.'"),
			Deadlines.OrderFulfillmentPeriod,
			Deadlines.CoveredPeriod),
		?(Deadlines.OrderFulfillmentPeriod = 0 And Deadlines.CoveredPeriod = 0,
			NStr("vi = 'Có thể tiếp nhận (bổ sung vật tư) tại ngày bất kỳ, kỳ đảm bảo không hạn chế.';
				|ru = 'Поступление (пополнение запаса) возможно в любой день, обеспечиваемый период не ограничен.';
				|en = 'Receipt (stock replenishment) is possible in any day, covered period is not limited.'; fa = 'Receipt (stock replenishment) is possible in any day, covered period is not limited.';
				|it = 'L''arrivo (integrazione delle scorte) è possibile in qualsiasi giorno, il periodo da rifornire non è limitato.';
				|pl = 'Wpływ (uzupełnienie) jest możliwe w dowolnym dniu, podany okres nie jest ograniczony.';
				|tr = 'Alım (stok dolumu) herhangi bir günde mümkündür, tedarik dönemi sınırlı değildir.'"),
		?(Deadlines.OrderFulfillmentPeriod > 0 And Deadlines.CoveredPeriod = 0, StrTemplate(
				NStr("vi = 'Tiếp nhận gần nhất (bổ sung thêm vật tư) dự tính trong %1 ngày, kỳ đảm bảo không giới hạn.';
					|ru = 'Ближайшее поступление (пополнение запаса) ожидается через %1 дн, обеспечиваемый период не ограничен.';
					|en = 'Next receipt (inventory replenishment) is expected in %1 days and covered period is unlimited.'; fa = 'Next receipt (inventory replenishment) is expected in %1 days and covered period is unlimited.';
					|it = 'L''arrivo più vicino (integrazione delle scorte) è previsto tra %1 giorni, il periodo da rifornire non è limitato.';
					|pl = 'Najbliższy wpływ (uzupełnienie zapasu) jest oczekiwany przez %1 dni, podany okres nie jest ograniczony.';
					|tr = 'Bir sonraki alım (stok dolumu) %1 gün olarak bekleniyor, tedarik dönemi sınırlı değildir.'"),
				Deadlines.OrderFulfillmentPeriod),
		StrTemplate(
			NStr("vi = 'Có thể tiếp nhận (bổ sung vật tư) vào ngày bất kỳ và đảm bảo kỳ %1 ngày.';
				|ru = 'Поступление (пополнение запаса) возможно в любой день и обеспечивает период %1 дн.';
				|en = 'Receipt (stock replenishment) is possible in any day and covers the period of %1 days.'; fa = 'Receipt (stock replenishment) is possible in any day and covers the period of %1 days.';
				|it = 'L''arrivo (integrazione delle scorte) è possibile in qualsiasi giorno e garantisce il periodo di %1 giorni.';
				|pl = 'Wpływ (uzupełnienie zapasu) jest możliwy w dowolnym dniu i zapewnia okres %1 dni.';
				|tr = 'Alım (stok dolumu) herhangi bir günde mümkündür ve sağlanan süre %1 gün olarak.'"),
			Deadlines.CoveredPeriod))))));
	
EndProcedure

&AtClient
Procedure WhenSwitchingCollateralMethod()
	
	If Parameters.OpeningMode = "OnlyWay" Then
		Return;
	EndIf;
	
	SwitchToOrderUnderOrder      = 0;
	SwitchMinMax            = 0;
	SwitchForAPeriodOfTimeAccordingToTheNorm      = 0;
	TimeLimitSwitchForStatistics = 0;
	
	If StrategyOfProcurement = PredefinedValue("Enum.InventoryReplenishmentMethods.OrderAgainstOrder") Then
		SwitchToOrderUnderOrder = 1;
	ElsIf StrategyOfProcurement = PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentMinMax") Then
		SwitchMinMax = 1;
	ElsIf StrategyOfProcurement = PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentByStandard") Then
		SwitchForAPeriodOfTimeAccordingToTheNorm = 1;
	Else
		// We are working out the Method of providing = "Maintenance of the inventory statistics".
		TimeLimitSwitchForStatistics = 1;
	EndIf;

	If Not ValueIsFilled(OrderFulfillmentWithinInventoryReplenishment) Then
		OrderFulfillmentWithinInventoryReplenishment = PredefinedValue("Enum.OrderFulfillmentWithinInventoryReplenishment.SupplyFromStock");
	EndIf;

	// Setting up the visibility of stock maintenance parameters.
	If StrategyOfProcurement
		= PredefinedValue("Enum.InventoryReplenishmentMethods.OrderAgainstOrder") Then
		
		Items.PagesStandardAverageDailyTitle.CurrentPage = Items.PageConsumptionRateHeader;
		Items.PagesStandardValues.CurrentPage      = Items.PageStandardNotUsed;
		Items.PagesMinInventoryValues.CurrentPage   = Items.PageMinInventoryNotUsed;
		Items.PagesMaxValueMargin.CurrentPage  = Items.PageMaxTheSupplyNotUsed;
		Items.InsuranceValuePages.CurrentPage = Items.InsuranceStockPageNotUsed;
		Items.PagesOrderAccounting.CurrentPage        = Items.OrderTrackingPageNotUsed;
		
	ElsIf StrategyOfProcurement
		= PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentMinMax") Then
		
		Items.PagesStandardAverageDailyTitle.CurrentPage = Items.PageConsumptionRateHeader;
		Items.PagesStandardValues.CurrentPage      = Items.PageStandardNotUsed;
		Items.PagesMinInventoryValues.CurrentPage   = Items.PageMinInventory;
		Items.PagesMaxValueMargin.CurrentPage  = Items.PageMaxTheSupply;
		Items.InsuranceValuePages.CurrentPage = Items.InsuranceStockPageNotUsed;
		Items.PagesOrderAccounting.CurrentPage        = Items.OrderTrackingPage;
		
	ElsIf StrategyOfProcurement
		= PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentByStandard") Then
		
		Items.PagesStandardAverageDailyTitle.CurrentPage = Items.PageConsumptionRateHeader;
		Items.PagesStandardValues.CurrentPage      = Items.PageStandard;
		Items.PagesMinInventoryValues.CurrentPage   = Items.PageMinInventoryAsAString;
		Items.PagesMaxValueMargin.CurrentPage  = Items.PageMaxStockByLine;
		Items.InsuranceValuePages.CurrentPage = Items.InsuranceStockPage;
		Items.PagesOrderAccounting.CurrentPage        = Items.OrderTrackingPage;
		
	ElsIf StrategyOfProcurement
		= PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentByStatistics") Then
		
		Items.PagesStandardAverageDailyTitle.CurrentPage = Items.PageAverageDailyConsumptionTitle;
		Items.PagesStandardValues.CurrentPage      = Items.PageDailyMeanConsumptionAsAString;
		Items.PagesMinInventoryValues.CurrentPage   = Items.PageMinInventoryAsAString;
		Items.PagesMaxValueMargin.CurrentPage  = Items.PageMaxStockByLine;
		Items.InsuranceValuePages.CurrentPage = Items.InsuranceStockPage;
		Items.PagesOrderAccounting.CurrentPage        = Items.OrderTrackingPage;
		
	EndIf;
	
	If Not ValueIsFilled(Products) Then
		Items.PagesPackagingValues.CurrentPage = Items.PagePackagingAsAString;
	Else
		Items.PagesPackagingValues.CurrentPage = Items.PagePackaging;
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateInventory()
	
	CalculatedIndividually = NStr("vi = 'hạch toán riêng biệt cho mặt hàng';
									|ru = 'индивидуальный расчет для номенклатуры';
									|en = 'individual calculation for products'; fa = 'individual calculation for products';
									|it = 'il calcolo individuale per l''articolo';
									|pl = 'indywidualne obliczenia dla nomenklatury';
									|tr = 'ürün gamı için bireysel hesaplama'");
	CalculationErrorDeliveryCycle   = NStr("vi = 'lỗi tính (không có dữ liệu của lịch làm việc)';
											|ru = 'ошибка расчета (нет данных графика работы)';
											|en = 'calculation error (no work schedule data)'; fa = 'calculation error (no work schedule data)';
											|it = 'ошибка расчета (нет данных графика работы)';
											|pl = 'calculation error (no work schedule data)';
											|tr = 'hesaplama hatası (çalışma takvimi verisi yok)'");
	
	If Parameters.OpeningMode = "MethodOnly" Or Parameters.OpeningMode = "ParametersOnly" Then
		MinimumLineMargin = CalculatedIndividually;
		MaximumLineMargin = CalculatedIndividually;
		AverageDailyConsumptionByLine = CalculatedIndividually;
		Items.MinimumLineMargin.TextColor = HelpTextColor;
		Items.MaximumLineMargin.TextColor = HelpTextColor;
		Items.AverageDailyConsumptionByLine.TextColor = HelpTextColor;
		
		Return;
	EndIf;
	
	Deadlines = DeliveryCycleParametersOfMainMethodOfProvision();
	ThereAreDeliveryCycleErrors = ThereAreDeliveryCycleErrors(Deadlines);
	
	If StrategyOfProcurement = PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentByStandard") Then
		
		If Not ThereAreDeliveryCycleErrors Then
			MinimumInventoryCalculated  = Deadlines.OrderFulfillmentPeriod * ConsumptionRate;
			MaximumInventoryCalculated = Deadlines.CoveredPeriod * ConsumptionRate;
		Else
			MinimumInventoryCalculated  = 0;
			MaximumInventoryCalculated = 0;
		EndIf;
		
		MinimumLineMargin =
			?(ThereAreDeliveryCycleErrors, CalculationErrorDeliveryCycle,
			
			?(ConsumptionRate = 0,
				NStr("vi = 'hãy xác định định mức nhu cầu';
					|ru = 'задайте норму потребления';
					|en = 'set consumption rate'; fa = 'set consumption rate';
					|it = 'impostare la norma di consumo';
					|pl = 'ustawić szybkość zużycia';
					|tr = 'tüketim oranı girin'"),
			
			?(Deadlines.OrderFulfillmentPeriod = 0, StrTemplate(
				NStr("vi = '0.000 %1 (cho 0 ngày)';
					|ru = '0.000 %1 (на 0 дн)';
					|en = '0.000 %1 (for 0 days)'; fa = '0.000 %1 (for 0 days)';
					|it = '0.000 %1 (per 0 giorni)';
					|pl = '0.000 %1 (na 0 dni)';
					|tr = '0.000 %1 (0 gün olarak)'"),
				UnitOfMeasure),
					
			StrTemplate(
				NStr("vi = '%1 %2 (cho %3 ngày)';
					|ru = '%1 %2 (на %3 дн)';
					|en = '%1 %2 (for %3 days)'; fa = '%1 %2 (for %3 days)';
					|it = '%1 %2 (per %3 giorni)';
					|pl = '%1 %2 (na %3 dn)';
					|tr = '%1 %2 (%3 gün olarak)'"),
				Format(MinimumInventoryCalculated, "NFD=3"),
				UnitOfMeasure,
				Deadlines.OrderFulfillmentPeriod))));
		
		MaximumLineMargin =
			?(ThereAreDeliveryCycleErrors, CalculationErrorDeliveryCycle,
		
			?(ConsumptionRate = 0,
				NStr("vi = 'hãy xác định định mức nhu cầu';
					|ru = 'задайте норму потребления';
					|en = 'set consumption rate'; fa = 'set consumption rate';
					|it = 'impostare la norma di consumo';
					|pl = 'ustawić szybkość zużycia';
					|tr = 'tüketim oranı girin'"),
				
			?(Deadlines.CoveredPeriod = 0, StrTemplate(
				NStr("vi = '0.000 %1 (cho 0 ngày)';
					|ru = '0.000 %1 (на 0 дн)';
					|en = '0.000 %1 (for 0 days)'; fa = '0.000 %1 (for 0 days)';
					|it = '0.000 %1 (на 0 дн)';
					|pl = '0.000 %1 (na 0 dni)';
					|tr = '0.000 %1 (0 gün olarak)'"),
				UnitOfMeasure),
				
			StrTemplate(
				NStr("vi = '%1 %2 (cho %3 ngày)';
					|ru = '%1 %2 (на %3 дн)';
					|en = '%1 %2 (for %3 days)'; fa = '%1 %2 (for %3 days)';
					|it = '%1 %2 (per %3 giorni)';
					|pl = '%1 %2 (na %3 dn)';
					|tr = '%1 %2(%3 gün olarak)'"),
				Format(MaximumInventoryCalculated, "NFD=3"),
				UnitOfMeasure,
				Deadlines.CoveredPeriod))));
		
		Items.MinimumLineMargin.TextColor = ?(ThereAreDeliveryCycleErrors Or ConsumptionRate = 0,
			ErrorColor, ColorFromStyle);
			
		Items.MaximumLineMargin.TextColor = ?(ThereAreDeliveryCycleErrors Or ConsumptionRate = 0,
			ErrorColor, ColorFromStyle);
		
	ElsIf StrategyOfProcurement = PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentByStatistics") Then
		
		If Not ThereAreDeliveryCycleErrors Then
			MinimumInventoryCalculated  = Deadlines.OrderFulfillmentPeriod    * AverageDailyConsumption;
			MaximumInventoryCalculated = Deadlines.CoveredPeriod    * AverageDailyConsumption;
		Else
			MinimumInventoryCalculated  = 0;
			MaximumInventoryCalculated = 0;
		EndIf;
		
		MinimumLineMargin =
			?(ThereAreDeliveryCycleErrors, CalculationErrorDeliveryCycle,
			
			?(AverageDailyConsumption = 0,
				NStr("vi = 'không có tiêu dùng theo thống kê';
					|ru = 'нет потребления по статистике';
					|en = 'no consumption by statistics'; fa = 'no consumption by statistics';
					|it = 'nessun consumo nelle statistiche';
					|pl = 'brak konsumpcji według statystyk';
					|tr = 'istatistiksel olarak tüketim mevcut değildir'"),
			
			?(Deadlines.OrderFulfillmentPeriod = 0, StrTemplate(
				NStr("vi = '0.000 %1 (cho 0 ngày)';
					|ru = '0.000 %1 (на 0 дн)';
					|en = '0.000 %1 (for 0 days)'; fa = '0.000 %1 (for 0 days)';
					|it = '0.000 %1 (per 0 giorni)';
					|pl = '0.000 %1 (na 0 dni)';
					|tr = '0.000 %1 (0 gün olarak)'"),
				UnitOfMeasure),
				
			StrTemplate(
				NStr("vi = '%1 %2 (cho %3 ngày)';
					|ru = '%1 %2 (на %3 дн)';
					|en = '%1 %2 (for %3 days)'; fa = '%1 %2 (for %3 days)';
					|it = '%1 %2 (per %3 giorni)';
					|pl = '%1 %2 (na %3 dn)';
					|tr = '%1 %2 (%3 gün olarak)'"),
				Format(MinimumInventoryCalculated, "NFD=3"),
				UnitOfMeasure,
				Deadlines.OrderFulfillmentPeriod))));
		
		MaximumLineMargin =
			?(ThereAreDeliveryCycleErrors, CalculationErrorDeliveryCycle,
			
			?(AverageDailyConsumption = 0,
				NStr("vi = 'không có tiêu dùng theo thống kê';
					|ru = 'нет потребления по статистике';
					|en = 'no consumption by statistics'; fa = 'no consumption by statistics';
					|it = 'nessun consumo nelle statistiche';
					|pl = 'brak konsumpcji według statystyk';
					|tr = 'istatistiksel olarak tüketim mevcut değildir'"),
				
			?(Deadlines.CoveredPeriod = 0, StrTemplate(
				NStr("vi = '0.000 %1 (cho 0 ngày)';
					|ru = '0.000 %1 (на 0 дн)';
					|en = '0.000 %1 (for 0 days)'; fa = '0.000 %1 (for 0 days)';
					|it = '0.000 %1 (на 0 дн)';
					|pl = '0.000 %1 (na 0 dni)';
					|tr = '0.000 %1 (0 gün olarak)'"),
				UnitOfMeasure),
				
			StrTemplate(
				NStr("vi = '%1 %2 (cho %3 ngày)';
					|ru = '%1 %2 (на %3 дн)';
					|en = '%1 %2 (for %3 days)'; fa = '%1 %2 (for %3 days)';
					|it = '%1 %2 (per %3 giorni)';
					|pl = '%1 %2 (na %3 dn)';
					|tr = '%1 %2(%3 gün olarak)'"),
				Format(MaximumInventoryCalculated, "NFD=3"),
				UnitOfMeasure,
				Deadlines.CoveredPeriod))));
		
		AverageDailyConsumptionByLine =
			?(ValueIsFilled(TimeConsumingOperation), NStr("vi = 'số liệu thống kê được tính toán ...';
															|ru = 'статистика рассчитывается...';
															|en = 'calculating statistics...'; fa = 'calculating statistics...';
															|it = 'la statistica è in fase di calcolo...';
															|pl = 'statystyki są obliczane...';
															|tr = 'istatistik hesaplanıyor...'"),
			
			?(ThereAreDeliveryCycleErrors, CalculationErrorDeliveryCycle,
			
			?(AverageDailyConsumption = 0, StrTemplate(
				NStr("vi = 'không có thống kê trong %1 - %2';
					|ru = 'нет статистики за %1 - %2';
					|en = 'no statistics for %1 - %2'; fa = 'no statistics for %1 - %2';
					|it = 'manca la statistica per %1 - %2';
					|pl = 'brak statystyk za %1 - %2';
					|tr = '%1 - %2 için istatistik mevcut değildir'"),
				Format(DataOverPeriod.StartDate,    "DLF=D"),
				Format(DataOverPeriod.EndDate, "DLF=D")),
				
			StrTemplate(
				NStr("vi = '%1 (+/- %2) %3 (thống kê trong %4 - %5)';
					|ru = '%1 (+/- %2) %3 (статистика за %4 - %5)';
					|en = '%1 (+/- %2) %3 (statistics for %4 - %5)'; fa = '%1 (+/- %2) %3 (statistics for %4 - %5)';
					|it = '%1 (+/- %2) %3 (statistica per %4- %5)';
					|pl = '%1 (+/- %2) %3 (statystyka za %4 - %5)';
					|tr = '%1 (+/- %2) %3 (%4 - %5 için istatistik)'"),
				Format(AverageDailyConsumption, "NFD=3"),
				Format(AverageVariance, "NFD=3; NZ=0.000"),
				UnitOfMeasure,
				Format(DataOverPeriod.StartDate,    "DLF=D"),
				Format(DataOverPeriod.EndDate, "DLF=D")))));
		
		Items.MinimumLineMargin.TextColor = ?(ThereAreDeliveryCycleErrors Or AverageDailyConsumption = 0,
			ErrorColor, ColorFromStyle);
			
		Items.MaximumLineMargin.TextColor = ?(ThereAreDeliveryCycleErrors Or AverageDailyConsumption = 0,
			ErrorColor, ColorFromStyle);
			
		Items.AverageDailyConsumptionByLine.TextColor = ?(AverageDailyConsumption = 0,
			ErrorColor, ColorFromStyle);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteAtServer()
	
	AccessRights = SupplyServer.WriteAccessRightsForMethodOrMethod();
	If Parameters.OpeningMode <> "ParametersOnly"
		And (SettingSpecificationMethod = "FOR_CHARACTERISTICSOfProduct" Or SettingSpecificationMethod = "FOR_GROUP_Products") Then
		AccessRights.ProductRestrictions = False;
	EndIf;
	
	BeginTransaction();
	
	Try
	
		If AccessRights.ProductRestrictions Then
			// Record of the product restriction.
			If Parameters.NeedKey.Property("GroupingProductRestrictions") And 
				ValueIsFilled(Parameters.NeedKey.GroupingProductRestrictions) Then
				RecordKey = InformationRegisters.ProductRestrictions.KeyForRecordingDimensions();
			ElsIf ValueIsFilled(Parameters.NeedKey.Characteristic) Then
				RecordKey = InformationRegisters.ProductRestrictions.FeatureRecordingKey();
			Else
				RecordKey = InformationRegisters.ProductRestrictions.ProductEntryKey();
			EndIf;
			FillPropertyValues(RecordKey, Parameters.NeedKey);
			If Parameters.OpeningMode = "Full" Then
				If StrategyOfProcurement = Enums.InventoryReplenishmentMethods.OrderAgainstOrder Then
					InformationRegisters.ProductRestrictions.RemoveStockMaintenance(RecordKey);
				EndIf;
				InformationRegisters.ProductRestrictions.SetProductPackaging(Parameters.NeedKey.Products,
					Parameters.NeedKey.Characteristic, Parameters.NeedKey.Warehouse, OrderPackage);
			EndIf;
			If StrategyOfProcurement = Enums.InventoryReplenishmentMethods.StockReplenishmentMinMax Then
				WriteParameters = InformationRegisters.ProductRestrictions.ParametersMinMax();
				WriteParameters.MinimumInventoryQuantity				= MinimumInventory;
				WriteParameters.MaximumInventoryAmount			= MaximumInventory;
				WriteParameters.OrderFulfillmentWithinInventoryReplenishment	= OrderFulfillmentWithinInventoryReplenishment;
				InformationRegisters.ProductRestrictions.AddStockMaintenanceMinMax(RecordKey, WriteParameters);
			ElsIf StrategyOfProcurement = Enums.InventoryReplenishmentMethods.StockReplenishmentByStandard Then
				WriteParameters = InformationRegisters.ProductRestrictions.ParametersCalculationByNorm();
				WriteParameters.ConsumptionRate						= ConsumptionRate;
				WriteParameters.SafetyStockQuantity				= SafetyStock;
				WriteParameters.OrderFulfillmentWithinInventoryReplenishment	= OrderFulfillmentWithinInventoryReplenishment;
				InformationRegisters.ProductRestrictions.AddStockMaintenanceRateCalculation(RecordKey, WriteParameters);
			ElsIf StrategyOfProcurement = Enums.InventoryReplenishmentMethods.StockReplenishmentByStatistics Then
				WriteParameters = InformationRegisters.ProductRestrictions.ParametersCalculationBasedOnStatistics();
				WriteParameters.SafetyStockQuantity				= SafetyStock;
				WriteParameters.OrderFulfillmentWithinInventoryReplenishment	= OrderFulfillmentWithinInventoryReplenishment;
				InformationRegisters.ProductRestrictions.AddStockMaintenanceCalculationByStatistics(RecordKey, WriteParameters);
			EndIf;
			
		EndIf;
	
		If AccessRights.SupplyOptions And Parameters.OpeningMode <> "ParametersOnly" Then
			
			RecordSet = ?(Parameters.NeedKey.ThisIsWork,
				InformationRegisters.WorksProcurementStrategy.CreateRecordSet(),
				InformationRegisters.GoodsProcurementStrategy.CreateRecordSet());
			RecordSet.Filter.Products.Value = Parameters.NeedKey.Products;
			RecordSet.Filter.Products.Use = True;
			RecordSet.Filter.Characteristic.Value = Parameters.NeedKey.Characteristic;
			RecordSet.Filter.Characteristic.Use = True;
			If Not Parameters.NeedKey.ThisIsWork Then
				RecordSet.Filter.Warehouse.Value          = Parameters.NeedKey.Warehouse;
				RecordSet.Filter.Warehouse.Use = True;
			EndIf;
			RecordSet.AdditionalProperties.Insert("UpdatePropsForOrdering", False);
			RecordSet.Filter.ProcurementStrategy.Use = True;
			
			// Removal of a previously valid individual security method.
			If ValueIsFilled(MethodIndividualOld) Then
				
				RecordSet.Filter.ProcurementStrategy.Value = MethodIndividualOld;
				RecordSet.Read();
				RecordSet[0].AddlOrderingAttribute = 2;
				RecordSet.Write(True);
				
			EndIf;
			
			// Reading and writing a new individual method as the main method.
			If MethodSwitch = 1 And ValueIsFilled(TheMethodIsIndividual) Then
				
				RecordSet.Filter.ProcurementStrategy.Value = TheMethodIsIndividual;
				RecordSet.Read();
				
				If RecordSet.Count() > 0 Then
					Record = RecordSet[0];
				Else
					Record = RecordSet.Add();
					FillPropertyValues(Record, Parameters.NeedKey);
					Record.ProcurementStrategy = TheMethodIsIndividual;
				EndIf;
				
				Record.AddlOrderingAttribute = 1;
				RecordSet.Write(True);
				MethodIndividualOld = TheMethodIsIndividual;
				
			EndIf;
			
		EndIf;
		
		Modified = False;
		DataRecorded = True;
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
		
EndProcedure

&AtServerNoContext
Function DeliveryCycleParametersForServerCallSchedule(NeedKey, SupplyMethod, BeginOfPeriod)
	Return DeliveryCycleParametersAccordingToWorkSchedule(NeedKey, SupplyMethod, BeginOfPeriod);
EndFunction

#EndRegion
