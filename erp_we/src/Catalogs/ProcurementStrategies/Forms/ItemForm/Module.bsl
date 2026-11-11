
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("SupplyType", Object.SupplyType);
	Notify("Write_ProcurementStrategy", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If OneSource = 1 And Not ValueIsFilled(Object.SourceOfDemandSupply) Then
		
		If Object.SupplyType = Enums.SupplyTypes.Purchase Then
			MessageText = NStr("vi = 'Chưa điền trường ""Nhà cung cấp""';
								|ru = 'Поле ""Поставщик"" не заполнено';
								|en = '""Vendor"" is required'; fa = '""Vendor"" is required';
								|it = 'Il campo ""Fornitore"" non è compilato';
								|pl = 'Nie wypełniono pola ""Dostawca""';
								|tr = '""Tedarikçi"" alanı doldurulmadı'");
		ElsIf Object.SupplyType = Enums.SupplyTypes.Move Then
			MessageText = NStr("vi = 'Trường ""Trung tâm phân phối"" chưa điền';
								|ru = 'Поле ""Распределительный центр"" не заполнено';
								|en = '""Distribution center"" is required'; fa = '""Distribution center"" is required';
								|it = 'Il campo ""Centro di distribuzione"" non è compilato';
								|pl = 'Pole ""Centrum przydziałowy"" nie jest wypełnione';
								|tr = '""Dağıtım merkezi"" alanı doldurulmadı'");
		ElsIf Object.SupplyType = Enums.SupplyTypes.ProductionByThirdParty Then
			MessageText = NStr("vi = 'Trường ""Bên nhận gia công"" chưa điền';
								|ru = 'Поле ""Переработчик"" не заполнено';
								|en = '""Subcontractor"" is required'; fa = '""Subcontractor"" is required';
								|it = 'Il campo ""subfornitore"" non è compilato';
								|pl = 'Nie wypełniono pola ""Przetwórca""';
								|tr = '""Fason üretici"" alanı doldurulmadı'");
		ElsIf Object.SupplyType = Enums.SupplyTypes.Production Then
			MessageText = NStr("vi = 'Trường ""Bộ phận-điều phối"" chưa điền';
								|ru = 'Поле ""Подразделение-диспетчер"" не заполнено';
								|en = '""Dispatching unit"" is required'; fa = '""Dispatching unit"" is required';
								|it = 'Il campo ""Reparto di controllo"" non è compilato';
								|pl = 'Pole ""Dział-dyspozytor"" nie jest wypełnione';
								|tr = '""Üretim planlama departmanı"" alanı doldurulmadı'");
		EndIf;
		
		Common.MessageToUser(MessageText, , "SourceOfDemandSupply", "Object"); 
		Cancel = True;
	EndIf;
	
	If Not Object.GenerateOrdersOnSchedule And Not Object.GenerateOrdersByReorderPoint Then
		
		MessageText = NStr("vi = 'Chưa điền quy tắc tạo đơn hàng (theo điểm đặt hàng hoặc theo lịch biểu)';
							|ru = 'Не заполнено правило формирования заказов (по точке заказа или по графику)';
							|en = 'Lead time settings are not filled in (by reorder point or on schedule)'; fa = 'Lead time settings are not filled in (by reorder point or on schedule)';
							|it = 'Не заполнено правило формирования заказов (по точке заказа или по графику)';
							|pl = 'Lead time settings are not filled in (by reorder point or on schedule)';
							|tr = 'Sipariş oluşturma kuralı doldurulmamış (yeniden sipariş noktasına göre veya programa göre)'");
		Common.MessageToUser(MessageText, , "GenerateOrdersByReorderPoint", "Object"); 
		Cancel = True;
		
	EndIf;
	
	If Not ValueIsFilled(Object.CoveredPeriodOption) Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Khoảng thời gian được đảm bảo bởi đơn hàng""';
							|ru = 'Не заполнен поле ""Период обеспечиваемый заказом""';
							|en = 'The ""Covered period"" field is not filled in'; fa = 'The ""Covered period"" field is not filled in';
							|it = 'Не заполнен поле ""Период обеспечиваемый заказом""';
							|pl = 'The ""Covered period"" field is not filled in';
							|tr = '""Siparişin sağlandığı dönem"" alanı doldurulmamış'");
		Common.MessageToUser(MessageText, , "CoveredPeriodOption", "Object"); 
		Cancel = True;
		
	EndIf;
	
	If Object.GenerateOrdersOnSchedule Then
		
		If SwitchMethodForSettingDeliverySchedules = 0 Then
			
			If Not ValueIsFilled(Object.NumberOfPeriodsBetweenDeliveries) Then
				MessageText = NStr("vi = 'Chưa điền số lượng kỳ trong khoảng thời gian giữa các lần giao hàng';
									|ru = 'Не заполнено количество периодов в интервале между поставками';
									|en = 'The number of periods in the interval between deliveries is not filled in'; fa = 'The number of periods in the interval between deliveries is not filled in';
									|it = 'Не заполнено количество периодов в интервале между поставками';
									|pl = 'The number of periods in the interval between deliveries is not filled in';
									|tr = 'Teslimatlar aralığındaki dönem sayısı doldurulmadı'");
				Common.MessageToUser(MessageText, , "NumberOfPeriodsBetweenDeliveries", "Object"); 
				Cancel = True;
			EndIf;
			
			If Not ValueIsFilled(Object.DeliveryScheduleFrequency) Then
				MessageText = NStr("vi = 'Chưa điền tần suất giao hàng';
									|ru = 'Не заполнена периодичность поставок';
									|en = 'Delivery frequency is not filled in'; fa = 'Delivery frequency is not filled in';
									|it = 'Не заполнена периодичность поставок';
									|pl = 'Delivery frequency is not filled in';
									|tr = 'Tedarik sıklığı doldurulmamış'");
				Common.MessageToUser(MessageText, , "DeliveryScheduleFrequency", "Object"); 
				Cancel = True;
			EndIf;
			
			If Not ValueIsFilled(Object.FirstDateInDeliverySchedule) Then
				MessageText = NStr("vi = 'Chưa điền ngày đầu tiên trong lịch biểu giao hàng';
									|ru = 'Не заполнена первая дата в графике поставок';
									|en = 'The first date in the delivery schedule is not filled in'; fa = 'The first date in the delivery schedule is not filled in';
									|it = 'Не заполнена первая дата в графике поставок';
									|pl = 'The first date in the delivery schedule is not filled in';
									|tr = 'Tedarik programındaki ilk tarih doldurulmamış'");
				Common.MessageToUser(MessageText, , "FirstDateInDeliverySchedule", "Object"); 
				Cancel = True;
			EndIf;
			
		Else
			
			If Not ValueIsFilled(Object.DeliverySchedule) Then
				MessageText = NStr("vi = 'Chưa điền trường ""Lịch biểu giao hàng""';
									|ru = 'Не заполнено поле ""График поставок""';
									|en = 'The ""Delivery schedule"" field is not filled in'; fa = 'The ""Delivery schedule"" field is not filled in';
									|it = 'Не заполнено поле ""График поставок""';
									|pl = 'The ""Delivery schedule"" field is not filled in';
									|tr = '""Tedarik Programı"" alanı doldurulmamış'");
				Common.MessageToUser(MessageText, , "DeliverySchedule", "Object"); 
				Cancel = True;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TypeOfSecurityWhenChanging(Item)
	
	Modified = True;
	
	Object.SourceOfDemandSupply = Undefined;
	Object.Terms = Undefined;
	Object.VendorPriceKind = Undefined;
	If Object.SupplyType = PredefinedValue("Enum.SupplyTypes.AssemblyDisassembly") Then
		OneSource = 0;
		ActivateUsageModePage(Items, False);
	EndIf;
	
	If Object.SupplyType <> PredefinedValue("Enum.SupplyTypes.Move")
			And Object.SupplyType <> PredefinedValue("Enum.SupplyTypes.AssemblyDisassembly") Then
		Object.ProductionDurationDays = 0;
	EndIf;
	Object.SemiFinishedProductPlanningMethod = Undefined;
	If Object.SupplyType = PredefinedValue("Enum.SupplyTypes.Production") Then
		Object.Department = Undefined;
		Object.SemiFinishedProductPlanningMethod = PredefinedValue("Enum.SemiFinishedProductPlanningMethods.Automatically");
		SwitchSemiFinishedProductsToScheduleAutomatically = 1;
		SwitchSemiFinishedProductsToPlanManually       = 0;
	EndIf;
	ConfigureFormBySoftwareType();
	TermsOnChangeServer(True);
	
EndProcedure

&AtClient
Procedure PurchasePeriodOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("OrderFulfillmentPeriod");
	
EndProcedure

&AtClient
Procedure TransferPeriodOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("OrderFulfillmentPeriod");
	
EndProcedure

&AtClient
Procedure AssemblyPeriodOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("OrderFulfillmentPeriod");
	
EndProcedure

&AtClient
Procedure ProductionPeriodOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("OrderFulfillmentPeriod");
	
EndProcedure

&AtClient
Procedure ProcessingPeriodOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("OrderFulfillmentPeriod");
	
EndProcedure

&AtClient
Procedure GenerateOrdersByReorderPointOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("GenerateOrdersByReorderPoint");
	
EndProcedure

&AtClient
Procedure CoveredPeriodOptionOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("CoveredPeriodOption");
	
EndProcedure

&AtClient
Procedure CertainNumberOfDaysOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("CoveredPeriod");
	
EndProcedure

&AtClient
Procedure GenerateOrdersOnScheduleOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("GenerateOrdersOnSchedule");
	
EndProcedure

&AtClient
Procedure NumberOfPeriodsBetweenDeliveriesOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("NumberOfPeriodsBetweenDeliveries");
	
EndProcedure

&AtClient
Procedure DeliveryScheduleFrequencyOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("DeliveryScheduleFrequency");
	
EndProcedure

&AtClient
Procedure FirstDateInDeliveryScheduleOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	OnChangingPlanningAttributesAtClient("FirstDateInDeliverySchedule");
	
EndProcedure

&AtClient
Procedure DeliveryScheduleOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("DeliverySchedule");
	
EndProcedure

&AtClient
Procedure SwitchMethodForSettingDeliveryScheduleIntervalOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("SwitchMethodForSettingDeliverySchedules");
	
EndProcedure

&AtClient
Procedure SwitchMethodForSettingDeliveryScheduleScheduleOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("SwitchMethodForSettingDeliverySchedules");
	
EndProcedure

&AtClient
Procedure SwitchSemiFinishedProductsToScheduleAutomaticallyOnChange(Item)
	
	SwitchSemiFinishedProductsToScheduleAutomatically = 1;
	SwitchSemiFinishedProductsToPlanManually       = 0;
	
	Object.SemiFinishedProductPlanningMethod = PredefinedValue("Enum.SemiFinishedProductPlanningMethods.Automatically");
	
	Return;
	
EndProcedure

&AtClient
Procedure SwitchSemiFinishedProductsToPlanManuallyOnChange(Item)
	
	SwitchSemiFinishedProductsToScheduleAutomatically = 0;
	SwitchSemiFinishedProductsToPlanManually       = 1;
	
	Object.SemiFinishedProductPlanningMethod = PredefinedValue("Enum.SemiFinishedProductPlanningMethods.Manually");
	
	Return;
	
EndProcedure

&AtClient
Procedure TheModeOfUseOfSeveralSourcesWhenYouChange(Item)
	
	Object.SourceOfDemandSupply = Undefined;
	Object.Terms = Undefined;
	TermsOnChangeServer(True);
	
	ActivateUsageModePage(Items, False);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure VendorOnChange(Item)
	
	TermsOnChangeServer(True);
	
EndProcedure


&AtClient
Procedure TheModeOfUseOfOneSourceWhenChanging(Item)
	
	ActivateUsageModePage(Items, True);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure BuildDurationInDaysOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("ProductionDurationDays");
	
EndProcedure

&AtClient
Procedure MoveDurationInDaysOnChange(Item)
	
	OnChangingPlanningAttributesAtClient("ProductionDurationDays");
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	TermsOnChangeServer(True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region OtherProceduresAndFunctions_

&AtServer
Procedure OnReadCreateAtServer()
	
	OneSource = ValueIsFilled(Object.SourceOfDemandSupply);
	ChoiceList = FillSecurityTypeSelectionList();
	
	// Bringing the value of the security type to an acceptable one.
	If ChoiceList.FindByValue(Object.SupplyType) = Undefined Then
		If ChoiceList.FindByValue(Enums.SupplyTypes.Purchase) <> Undefined Then
			Object.SupplyType = Enums.SupplyTypes.Purchase;
		ElsIf ChoiceList.Count() > 0 Then
			Object.SupplyType = ChoiceList[0].Value;
		EndIf;
	EndIf;

	If ChoiceList.Count() = 1 Then
		Items.SupplyType1.Visible = False;
		Items.SupplyType2.Visible = False;
		Items.SupplyType3.Visible = False;
		Items.SupplyType4.Visible = False;
		Items.SupplyType5.Visible = False;
	EndIf;

	ConfigureFormBySoftwareType();
	TermsOnChangeServer(False);
	ActivateUsageModePage(Items, OneSource);
	OnChangingPlanningAttributes(ThisObject, Undefined);
	GenerateExplanatoryCaptions();

	Items.Vendor.TypeRestriction              = New TypeDescription("CatalogRef.Partners");
	Items.Warehouse.TypeRestriction                  = New TypeDescription("CatalogRef.Warehouses");
	Items.Toller.TypeRestriction           = New TypeDescription("CatalogRef.Partners");
	Items.ProductionDispatcherBusinessUnit.TypeRestriction = New TypeDescription("CatalogRef.BusinessStructure");
	SwitchSemiFinishedProductsToScheduleAutomatically = ?(Object.SemiFinishedProductPlanningMethod = Enums.SemiFinishedProductPlanningMethods.Automatically, 1, 0);
	SwitchSemiFinishedProductsToPlanManually       = ?(Object.SemiFinishedProductPlanningMethod = Enums.SemiFinishedProductPlanningMethods.Automatically, 0, 1);
	If Not GetFunctionalOption("UseGoodsQualityControl") Then
		Items.HintQualityControl.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure OnChangingPlanningAttributes(Form, AttributeName)
	
	If AttributeName = Undefined Or AttributeName = "GenerateOrdersOnSchedule" Then
	
		ElementAvailability = Form.Object.GenerateOrdersOnSchedule;
		Form.Items.SwitchMethodForSettingDeliveryScheduleInterval.Enabled = ElementAvailability;
		
		If Not ElementAvailability Then
			Form.SwitchMethodForSettingDeliverySchedules = 2;
		ElsIf ValueIsFilled(Form.Object.DeliverySchedule) Then
			Form.SwitchMethodForSettingDeliverySchedules = 1;
		Else
			Form.SwitchMethodForSettingDeliverySchedules = 0;
		EndIf;
		
		AvailableValues = New Array();
		AvailableValues.Add(PredefinedValue("Enum.CoveredPeriodOptions.CertainNumberOfDays"));
		If Form.Object.GenerateOrdersOnSchedule Then
			AvailableValues.Add(PredefinedValue("Enum.CoveredPeriodOptions.UpToTheNextDeliveryDate"));
		EndIf;
		AvailableValues.Add(PredefinedValue("Enum.CoveredPeriodOptions.NoExpiration"));
		Form.Items.CoveredPeriodOption.ChoiceList.LoadValues(AvailableValues);
		
	EndIf;
	
	If AttributeName = Undefined
			Or AttributeName = "GenerateOrdersOnSchedule"
			Or AttributeName = "SwitchMethodForSettingDeliverySchedules" Then
		
		ElementAvailability = Form.Object.GenerateOrdersOnSchedule;
		Form.Items.SwitchMethodForSettingDeliveryScheduleSchedule.Enabled = ElementAvailability;
		
		ElementAvailability = Form.Object.GenerateOrdersOnSchedule
			And Form.SwitchMethodForSettingDeliverySchedules = 0;
		Form.Items.NumberOfPeriodsBetweenDeliveries.Enabled = ElementAvailability;
		Form.Items.DeliveryScheduleFrequency.Enabled = ElementAvailability;
		Form.Items.FirstDateInDeliverySchedule.Enabled = ElementAvailability;
		
		ElementAvailability = Form.Object.GenerateOrdersOnSchedule
			And Form.SwitchMethodForSettingDeliverySchedules = 1;
		Form.Items.DeliverySchedule.Enabled = ElementAvailability;
		
	EndIf;
	
	If AttributeName = Undefined Or AttributeName = "CoveredPeriodOption" Then
		
		ElementAvailability = Form.Object.CoveredPeriodOption
			= PredefinedValue(
					"Enum.CoveredPeriodOptions.CertainNumberOfDays");
		Form.Items.CertainNumberOfDays.Enabled = ElementAvailability;
		
	EndIf;
	
	CalculationParameters = ProvisionInDocumentsClientServer.SupplyCycleCalculationParameters();
	FillPropertyValues(CalculationParameters, Form.Object);
	Result = CalculationOfNearestSupplyCycle(CalculationParameters);
	FillPropertyValues(Form, Result);
	
EndProcedure

&AtServerNoContext
Function CalculationOfNearestSupplyCycle(CalculationParameters)
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	
	// Next, you need an arbitrary value.
	Query.SetParameter("Ref", 1);
	
	Texts = New Array();
	
	Text =
		"SELECT
		|	&OrderFulfillmentPeriod AS OrderFulfillmentPeriod,
		|	&GenerateOrdersByReorderPoint AS GenerateOrdersByReorderPoint,
		|	&GenerateOrdersOnSchedule AS GenerateOrdersOnSchedule,
		|	&DeliverySchedule AS DeliverySchedule,
		|	&FirstDateInDeliverySchedule AS FirstDateInDeliverySchedule,
		|	&DeliveryScheduleFrequency AS DeliveryScheduleFrequency,
		|	&NumberOfPeriodsBetweenDeliveries AS NumberOfPeriodsBetweenDeliveries,
		|	&CoveredPeriodOption AS CoveredPeriodOption,
		|	&CoveredPeriod AS CoveredPeriod,
		|	&Ref AS SupplyMethod
		|INTO SupplyMethods
		|;
		|SELECT
		|	&OrderFulfillmentPeriod AS OrderFulfillmentPeriod,
		|	&GenerateOrdersByReorderPoint AS GenerateOrdersByReorderPoint,
		|	&GenerateOrdersOnSchedule AS GenerateOrdersOnSchedule,
		|	&DeliverySchedule AS DeliverySchedule,
		|	&FirstDateInDeliverySchedule AS FirstDateInDeliverySchedule,
		|	&DeliveryScheduleFrequency AS DeliveryScheduleFrequency,
		|	&NumberOfPeriodsBetweenDeliveries AS NumberOfPeriodsBetweenDeliveries,
		|	&CoveredPeriodOption AS CoveredPeriodOption,
		|	&CoveredPeriod AS CoveredPeriod,
		|	&Ref AS Ref
		|INTO SimulationOfRecordedObject";
		
	Texts.Add(Text);
	
	For Each Item In CalculationParameters Do
		Query.SetParameter(Item.Key, Item.Value);
	EndDo;
	Query.SetParameter("BeginningOfThisDay", BegOfDay(CurrentSessionDate()));
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.Execute();
	
	ProvisionInDocumentsServer.TempTableNearestCycleBySupplyMethods(
		TempTablesManager,
		"SimulationOfRecordedObject");
		
	Texts = New Array();
	
	Texts.Add(ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule());
	
	Text =
		"SELECT
		|	Table.DemandConversionOption AS DemandConversionOption,
		|	Table.ShipmentDate AS ShipmentDate,
		|	Table.BoundaryOfCoveredPeriod AS BoundaryOfCoveredPeriod,
		|	Table.GenerateOrdersOnSchedule AS GenerateOrdersOnSchedule,
		|	Table.DeliveryDateOnSchedule AS DeliveryDateOnSchedule,
		|	Table.CoveredPeriodBoundaryOnSchedule AS CoveredPeriodBoundaryOnSchedule,
		|	Table.DaysBeforePlannedOrder AS DaysBeforePlannedOrder,
		|	Table.PlannedOrderDate AS PlannedOrderDate,
		|	Table.GenerateOrdersByReorderPoint AS GenerateOrdersByReorderPoint,
		|	Table.DeliveryDateByReorderPoint AS DeliveryDateByReorderPoint,
		|	Table.CoveredPeriodBoundaryByReorderPoint AS CoveredPeriodBoundaryByReorderPoint,
		|	Table.DeliverySchedule AS DeliverySchedule,
		|	Table.CoveredPeriodOption AS CoveredPeriodOption
		|FROM
		|	NextCycleBySupplyMethods AS Table";
	
	Texts.Add(Text);
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Result = New Structure();
	Result.Insert("DateOfOrderPlacementInfo", NStr("vi = '-';
													|ru = '-';
													|en = '-'; fa = '-';
													|it = '-';
													|pl = '-';
													|tr = '-'"));
	Result.Insert("TheEarliestDeliveryDateInfo", NStr("vi = '-';
														|ru = '-';
														|en = '-'; fa = '-';
														|it = '-';
														|pl = '-';
														|tr = '-'"));
	Result.Insert("CoveredPeriodBoundaryInfo", NStr("vi = '-';
													|ru = '-';
													|en = '-'; fa = '-';
													|it = '-';
													|pl = '-';
													|tr = '-'"));
	Result.Insert("OrderDate2", NStr("vi = '-';
									|ru = '-';
									|en = '-'; fa = '-';
									|it = '-';
									|pl = '-';
									|tr = '-'"));
	Result.Insert("ShipmentDate2", NStr("vi = '-';
										|ru = '-';
										|en = '-'; fa = '-';
										|it = '-';
										|pl = '-';
										|tr = '-'"));
	Result.Insert("PeriodBoundary2", NStr("vi = '-';
											|ru = '-';
											|en = '-'; fa = '-';
											|it = '-';
											|pl = '-';
											|tr = '-'"));
	Result.Insert("GuaranteedDate2", NStr("vi = '-';
											|ru = '-';
											|en = '-'; fa = '-';
											|it = '-';
											|pl = '-';
											|tr = '-'"));
	Result.Insert("OrderDateScheduleIsNotFilledIn", "");
	Result.Insert("DeliveryDateNotCompletedSchedule", "");
	Result.Insert("PeriodBoundaryIsNotFilledInSchedule", "");
	Result.Insert("GuaranteedDateScheduleIsNotFilled", "");
	
	TodayOrderIsScheduled = False;
	If Selection.GenerateOrdersOnSchedule Then
		
		If ValueIsFilled(Selection.PlannedOrderDate) Then
			If Selection.PlannedOrderDate = BegOfDay(CurrentSessionDate()) Then
				TodayOrderIsScheduled = True;
			EndIf;
			Result.OrderDate2 = Format(Selection.PlannedOrderDate, "DLF=D;");
		Else
			Result.OrderDateScheduleIsNotFilledIn = NStr("vi = 'Chưa điền lịch biểu làm việc';
														|ru = 'Не заполнен график работы';
														|en = 'The work schedule is not filled in'; fa = 'The work schedule is not filled in';
														|it = 'Не заполнен график работы';
														|pl = 'The work schedule is not filled in';
														|tr = 'Çalışma takvimi doldurulmamış'");
		EndIf;
		If ValueIsFilled(Selection.DeliveryDateOnSchedule) Then
			Result.ShipmentDate2 = Format(Selection.DeliveryDateOnSchedule, "DLF=D;");
		Else
			Result.DeliveryDateNotCompletedSchedule = NStr("vi = 'Chưa điền lịch biểu làm việc';
															|ru = 'Не заполнен график работы';
															|en = 'The work schedule is not filled in'; fa = 'The work schedule is not filled in';
															|it = 'Не заполнен график работы';
															|pl = 'The work schedule is not filled in';
															|tr = 'Çalışma takvimi doldurulmamış'");
		EndIf;
		If ValueIsFilled(Selection.CoveredPeriodBoundaryOnSchedule) Then
			Result.PeriodBoundary2 = Format(Selection.CoveredPeriodBoundaryOnSchedule, "DLF=D;");
		Else
			If Selection.CoveredPeriodOption
						= Enums.CoveredPeriodOptions.CertainNumberOfDays
					Or Selection.CoveredPeriodOption
							= Enums.CoveredPeriodOptions.UpToTheNextDeliveryDate Then
				Result.PeriodBoundaryIsNotFilledInSchedule = NStr("vi = 'Chưa điền lịch biểu làm việc';
																	|ru = 'Не заполнен график работы';
																	|en = 'The work schedule is not filled in'; fa = 'The work schedule is not filled in';
																	|it = 'Не заполнен график работы';
																	|pl = 'The work schedule is not filled in';
																	|tr = 'Çalışma takvimi doldurulmamış'");
			EndIf;
		EndIf;
	EndIf;
	
	If Selection.GenerateOrdersByReorderPoint Then
		
		If TodayOrderIsScheduled Then
			
			Result.DateOfOrderPlacementInfo = Result.OrderDate2;
			Result.TheEarliestDeliveryDateInfo = Result.ShipmentDate2;
			Result.CoveredPeriodBoundaryInfo = Result.PeriodBoundary2;
			
		Else
			
			Result.DateOfOrderPlacementInfo = Format(BegOfDay(CurrentSessionDate()), "DLF=D;");
			If ValueIsFilled(Selection.DeliveryDateByReorderPoint) Then
				Result.TheEarliestDeliveryDateInfo = Format(Selection.DeliveryDateByReorderPoint, "DLF=D;");
			Else
				Result.DeliveryDateNotCompletedSchedule = NStr("vi = 'Chưa điền lịch biểu làm việc';
																|ru = 'Не заполнен график работы';
																|en = 'The work schedule is not filled in'; fa = 'The work schedule is not filled in';
																|it = 'Не заполнен график работы';
																|pl = 'The work schedule is not filled in';
																|tr = 'Çalışma takvimi doldurulmamış'")
			EndIf;
			If ValueIsFilled(Selection.CoveredPeriodBoundaryByReorderPoint) Then
				Result.CoveredPeriodBoundaryInfo = Format(Selection.CoveredPeriodBoundaryByReorderPoint, "DLF=D;");
			Else
				If Selection.CoveredPeriodOption
							= Enums.CoveredPeriodOptions.CertainNumberOfDays
						Or Selection.CoveredPeriodOption
								= Enums.CoveredPeriodOptions.UpToTheNextDeliveryDate Then
					Result.PeriodBoundaryIsNotFilledInSchedule = NStr("vi = 'Chưa điền lịch biểu làm việc';
																		|ru = 'Не заполнен график работы';
																		|en = 'The work schedule is not filled in'; fa = 'The work schedule is not filled in';
																		|it = 'Не заполнен график работы';
																		|pl = 'The work schedule is not filled in';
																		|tr = 'Çalışma takvimi doldurulmamış'")
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure OnChangingPlanningAttributesAtClient(Var_AttributeName)
	
	If Var_AttributeName = "OrderFulfillmentPeriod" Or Var_AttributeName = "ProductionDurationDays" Then
		
		If Object.OrderFulfillmentPeriod < Object.ProductionDurationDays Then
			
			If Object.SupplyType = PredefinedValue("Enum.SupplyTypes.Move") Then
				ErrorText = NStr("vi = 'Thời hạn điều chuyển không thể nhỏ hơn thời gian điều chuyển. Đã tăng thời hạn điều chuyển.';
								|ru = 'Срок перемещения не может быть меньше длительности перемещения. Срок перемещения увеличен.';
								|en = 'Transfer period cannot be less than the transfer duration. Transfer period is increased.'; fa = 'Transfer period cannot be less than the transfer duration. Transfer period is increased.';
								|it = 'Срок перемещения не может быть меньше длительности перемещения. Срок перемещения увеличен.';
								|pl = 'Termin przemieszczenia nie może być mniejszy od czasu trwania przemieszczenia. Termin przemieszczenia został zwiększony.';
								|tr = 'Transfer dönemi, transfer süresinden az olamaz. Transfer dönemi uzatıldı.'");
			ElsIf Object.SupplyType = PredefinedValue("Enum.SupplyTypes.AssemblyDisassembly") Then
				ErrorText = NStr("vi = 'Thời hạn đóng bộ không thể nhỏ hơn thời gian đóng bộ/tách bộ. Đã tăng thời hạn đóng bộ.';
								|ru = 'Срок сборки не может быть меньше длительности сборки/разборки. Срок сборки увеличен.';
								|en = 'Kitting period cannot be less than the kitting duration. Kitting period is increased.'; fa = 'Kitting period cannot be less than the kitting duration. Kitting period is increased.';
								|it = 'Срок сборки не может быть меньше длительности сборки/разборки. Срок сборки увеличен.';
								|pl = 'Termin montażu nie może być mniejszy od czasu trwania montażu/demontażu. Termin montażu został zwiększony.';
								|tr = 'Montaj süresi, montaj/demontaj süresinden az olamaz. Montaj süresi arttırıldı.'");
			Else
				ErrorText = "";
			EndIf;
			
			If ErrorText <> "" Then
				
				ShowUserNotification(NStr("vi = 'Thay đổi mục tin liên kết';
											|ru = 'Изменение связанных реквизитов';
											|en = 'Change linked attributes'; fa = 'Change linked attributes';
											|it = 'Изменение связанных реквизитов';
											|pl = 'Zmiana powiązanych atrybutów';
											|tr = 'İlgili özniteliklerinin değiştirilmesi'"),,ErrorText);
				Object.OrderFulfillmentPeriod = Object.ProductionDurationDays;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Var_AttributeName = "GenerateOrdersOnSchedule" Then
		
		If Object.CoveredPeriodOption = PredefinedValue("Enum.CoveredPeriodOptions.UpToTheNextDeliveryDate")
				And Not Object.GenerateOrdersOnSchedule Then
			Object.CoveredPeriodOption = PredefinedValue("Enum.CoveredPeriodOptions.NoExpiration");
		EndIf;
		
		If Object.GenerateOrdersOnSchedule Then
			
			Object.NumberOfPeriodsBetweenDeliveries = 1;
			Object.DeliveryScheduleFrequency = PredefinedValue("Enum.ScheduleTimeFence.Day");
			Object.FirstDateInDeliverySchedule = BegOfDay(CommonClient.SessionDate());
			Object.DeliverySchedule = PredefinedValue("Catalog.Calendars.EmptyRef");
			
		Else
			
			If Object.CoveredPeriodOption = PredefinedValue(
					"Enum.CoveredPeriodOptions.UpToTheNextDeliveryDate") Then
				
				Object.CoveredPeriodOption = PredefinedValue(
					"Enum.CoveredPeriodOptions.NoExpiration");
					
			EndIf;
			
			Object.NumberOfPeriodsBetweenDeliveries = 0;
			Object.DeliveryScheduleFrequency = PredefinedValue("Enum.ScheduleTimeFence.EmptyRef");
			Object.FirstDateInDeliverySchedule = '00010101';
			Object.DeliverySchedule = PredefinedValue("Catalog.Calendars.EmptyRef");
			
		EndIf;
		
	EndIf;
	
	If Var_AttributeName = "CoveredPeriodOption" Or Var_AttributeName = "GenerateOrdersOnSchedule" Then
		
		If Object.CoveredPeriodOption
				= PredefinedValue("Enum.CoveredPeriodOptions.CertainNumberOfDays") Then
			
			If Object.CoveredPeriod = 0 Then
				Object.CoveredPeriod = 1;
			EndIf;
			
		Else
			
			Object.CoveredPeriod = 0;
			
		EndIf;
		
	EndIf;
	
	If Var_AttributeName = "SwitchMethodForSettingDeliverySchedules" Then
		
		If SwitchMethodForSettingDeliverySchedules = 0 Then
			
			Object.DeliverySchedule = PredefinedValue("Catalog.Calendars.EmptyRef");;
			
		EndIf;
		
	EndIf;
	
	OnChangingPlanningAttributes(ThisObject, Var_AttributeName);
	
EndProcedure

&AtServer
Procedure GenerateExplanatoryCaptions()
	
	ExplanationOfSecurityType = "";
	If Object.SupplyType = Enums.SupplyTypes.Purchase Then
		Items.PagesCalculationOfProvisionCycle.CurrentPage = Items.CalculationPurchasePage;
		ExplanationOfSecurityType = NStr("vi = 'Phương thức đảm bảo này cho phép lập đơn hàng đặt nhà cung cấp.';
										|ru = 'Данный способ обеспечения позволяет формировать заказы поставщику.';
										|en = 'This procurement strategy allows you to generate purchase orders.'; fa = 'This procurement strategy allows you to generate purchase orders.';
										|it = 'Questo metodo di approvvigionamento consente di creare ordini al fornitore.';
										|pl = 'Dany sposób zaspokojenia pozwala tworzyć zamówienia do dostawcy.';
										|tr = 'Bu tedarik stratejisi satın alma siparişini oluşturmaya imkan verir.'");
	ElsIf Object.SupplyType = Enums.SupplyTypes.Move Then
		Items.PagesCalculationOfProvisionCycle.CurrentPage = Items.PageCalculationTransfer;
		ExplanationOfSecurityType = NStr("vi = 'Phương thức đảm bảo này cho phép lập đơn hàng điều chuyển.';
										|ru = 'Данный способ обеспечения позволяет формировать заказы на перемещение.';
										|en = 'This procurement strategy allows you to generate transfer orders.'; fa = 'This procurement strategy allows you to generate transfer orders.';
										|it = 'Questo metodo di approvvigionamento consente di creare ordini di movimento.';
										|pl = 'Dany sposób zaspokojenia pozwala tworzyć zamówiena na przesunięcie.';
										|tr = 'Bu tedarik stratejisi transfer siparişlerini oluşturmaya izin verir.'");
		If GetFunctionalOption("UseProductionManagement2_2") Then
			ExplanationOfSecurityType = NStr("vi = 'Phương pháp hỗ trợ này cho phép bạn tạo ra các đơn đặt hàng cho sự di chuyển và đơn đặt hàng vật liệu trong các xưởng sản xuất.';
											|ru = 'Данный способ обеспечения позволяет формировать заказы на перемещение и заказы материалов в цеховые кладовые.';
											|en = 'This procurement strategy allows you to generate transfer orders and orders for materials to shop floor stockrooms.'; fa = 'This procurement strategy allows you to generate transfer orders and orders for materials to shop floor stockrooms.';
											|it = 'Questo metodo di approvvigionamento consente di creare ordini di movimento e di ordine dei materiali nei magazzini dei reparti.';
											|pl = 'Dany sposób zaspokojenia pozwala tworzyć zamówienia na przesunięcie i zamówienia na materiały do magazynów spiżarni.';
											|tr = 'Bu tedarik stratejisi transfer siparişlerini ve atölye depoları için malzeme siparişlerini oluşturmaya imkan verir.'");
		EndIf;
	ElsIf Object.SupplyType = Enums.SupplyTypes.AssemblyDisassembly Then
		Items.PagesCalculationOfProvisionCycle.CurrentPage = Items.CalculationKitReverseKitPage;
		ExplanationOfSecurityType = NStr("vi = 'Phương thức đảm bảo này cho phép lập đơn hàng đóng bộ.';
										|ru = 'Данный способ обеспечения позволяет формировать заказы на сборку.';
										|en = 'This procurement strategy allows you to generate kitting orders.'; fa = 'This procurement strategy allows you to generate kitting orders.';
										|it = 'Questo metodo di approvvigionamento consente di creare ordini di montaggio.';
										|pl = 'Dany sposób zaspokojenia pozwala tworzyć zamówienia montażu.';
										|tr = 'Bu tedarik stratejisi montaj emirlerini oluşturmaya imkan verir.'");
	ElsIf Object.SupplyType = Enums.SupplyTypes.Production Then
		Items.PagesCalculationOfProvisionCycle.CurrentPage = Items.PageCalculationProduction;
		ExplanationOfSecurityType = NStr("vi = 'Phương thức đảm bảo này cho phép lập đơn hàng sản xuất.';
										|ru = 'Данный способ обеспечения позволяет формировать заказы на производство.';
										|en = 'This procurement strategy allows you to generate production orders.'; fa = 'This procurement strategy allows you to generate production orders.';
										|it = 'Questo metodo di approvvigionamento consente d creare ordini di produzione.';
										|pl = 'Dany sposób zaspokojenia pozwala tworzyć zamówienia produkcyjne.';
										|tr = 'Bu tedarik stratejisi üretim emirleri oluşturmaya imkan verir.'");
	ElsIf Object.SupplyType = Enums.SupplyTypes.ProductionByThirdParty Then
		Items.PagesCalculationOfProvisionCycle.CurrentPage = Items.CalculationProcessingPage;
		ExplanationOfSecurityType = NStr("vi = 'Phương pháp cung cấp này cho phép bạn tạo các đơn đặt hàng cho bên nhận gia công.';
										|ru = 'Данный способ обеспечения позволяет формировать заказы переработчику.';
										|en = 'This procurement strategy allows you to generate subcontracting purchase orders.'; fa = 'This procurement strategy allows you to generate subcontracting purchase orders.';
										|it = 'Questo metodo di approvvigionamento consente di creare ordini per il subfornitore.';
										|pl = 'Dany sposób zaspokojenia pozwala tworzyć zamówienia do przetwórcy.';
										|tr = 'Bu tedarik stratejisi verilen fason satın alma siparişlerini oluşturmaya imkan verir.'");
	EndIf;
	
	Items.ExplanationOfTheTypeOfSecurity.Title = ExplanationOfSecurityType;
	
EndProcedure

&AtServer
Procedure ConfigureFormBySoftwareType()
	
	Items.Terms.Visible = False;
	Items.VendorPriceKind.Visible = False;
	Items.OrganizationByAgreementPage.Visible = False;
	If Object.SupplyType = Enums.SupplyTypes.Purchase Then
		
		Items.EmployeeResponsible.Visible = True;
		Items.PagesUsageMode.Visible = True;
		Items.SecurityTypePages.Visible = False;
		Items.Terms.Visible = True;
		Items.VendorPriceKind.Visible = True;
		Items.OrganizationByAgreementPage.Visible = True;
		
		Items.PagesUsageMode.CurrentPage = Items.TheModePageOfThePurchase;
		Items.PagesSupplyDate.CurrentPage    = Items.PagePurchasePeriod;
		
	ElsIf Object.SupplyType = Enums.SupplyTypes.Move Then
		
		Items.EmployeeResponsible.Visible              = False;
		Items.PagesUsageMode.Visible = True;
		Items.SecurityTypePages.Visible     = True;
		
		Items.PagesUsageMode.CurrentPage = Items.PageModeUseTheMove;
		Items.SecurityTypePages.CurrentPage     = Items.MovePage;
		Items.PagesSupplyDate.CurrentPage    = Items.PageTransferPeriod;
		
	ElsIf Object.SupplyType = Enums.SupplyTypes.AssemblyDisassembly Then
		
		Items.EmployeeResponsible.Visible              = False;
		Items.PagesUsageMode.Visible = False;
		Items.SecurityTypePages.Visible     = True;
		
		Items.SecurityTypePages.CurrentPage  = Items.BuildPage;
		Items.PagesSupplyDate.CurrentPage = Items.PageAssemblyPeriod;
	ElsIf Object.SupplyType = Enums.SupplyTypes.Production Then
		
		Items.EmployeeResponsible.Visible              = False;
		Items.PagesUsageMode.Visible = True;
		Items.SecurityTypePages.Visible     = False;
		
		Items.PagesUsageMode.CurrentPage = Items.TheModePageUseTheProduction;
		Items.PagesSupplyDate.CurrentPage    = Items.PageProductionPeriod;
		
	ElsIf Object.SupplyType = Enums.SupplyTypes.ProductionByThirdParty Then
		
		Items.EmployeeResponsible.Visible              = False;
		Items.PagesUsageMode.Visible = True;
		Items.SecurityTypePages.Visible     = False;
		
		Items.PagesUsageMode.CurrentPage = Items.PageUsageModeRecycling;
		Items.PagesSupplyDate.CurrentPage    = Items.PageProcessingPeriod;
	EndIf;
	
	Items.Department.Visible = Object.SupplyType <> Enums.SupplyTypes.Production;
	
	ItemVisibility = False;
	ItemVisibility = Object.SupplyType = Enums.SupplyTypes.Production
		And GetFunctionalOption("DynamicStructureOfProductionOrders");
	Items.SwitchSemiFinishedProductsToScheduleAutomatically.Visible = ItemVisibility;
	Items.SwitchSemiFinishedProductsToPlanManually.Visible = ItemVisibility;
	
	GenerateExplanatoryCaptions();
	
EndProcedure

&AtClientAtServerNoContext
Procedure ActivateUsageModePage(Items, OneSource)
	
	Items.PagesUsageModePurchaseExplanation.CurrentPage = ?(OneSource,
		Items.TheModeOfUsingASingleProviderExplanation, Items.TheModeOfUseOfMultipleProvidersExplanation);
		
	Items.PagesUsageModeMoveExplanation.CurrentPage = ?(OneSource,
		Items.TheModeOfUsingOneStorageExplanation, Items.TheModeOfUseOfSeveralWarehousesExplanation);
	
	Items.Vendor.Enabled = OneSource;
	Items.Warehouse.Enabled     = OneSource;
	
	Items.VendorPriceKind.Enabled = OneSource;
	Items.Terms.Enabled        = OneSource;
	Items.PagesUsageModeProductionExplanation.CurrentPage = ?(OneSource,
		Items.UsageModeSingleDivisionManagerExplanation,
		Items.UsageModeMultipleDispatcherDivisionsExplanation);
		
	Items.PagesUsageModeRecyclingExplanation.CurrentPage = ?(OneSource,
		Items.UsageModeSingleProcessorExplanation, Items.TheModeOfUseOfSeveralProcessorsExplanation);
	
	Items.ProductionDispatcherBusinessUnit.Enabled = OneSource;
	Items.Toller.Enabled           = OneSource;
EndProcedure

&AtServer
Function FillSecurityTypeSelectionList()
	
	// Filling in the selection list of available types of collateral.
	ChoiceList = New ValueList;
	
	// We fill in the possible types of collateral depending on the functional options.
	If GetFunctionalOption("UsePurchaseOrders") Then
		ChoiceList.Add(Enums.SupplyTypes.Purchase);
	EndIf;
	If GetFunctionalOption("UseGoodsTransfer")
		Or GetFunctionalOption("UseTransferOrders")
		Or GetFunctionalOption("UseProductionManagement2_2")
		Then
		ChoiceList.Add(Enums.SupplyTypes.Move);
	EndIf;
	If GetFunctionalOption("UseAssemblyDisassembly")
		Or GetFunctionalOption("UseAssemblyDisassemblyOrders") Then
		ChoiceList.Add(Enums.SupplyTypes.AssemblyDisassembly, NStr("vi = 'Đóng bộ';
																	|ru = 'Сборка';
																	|en = 'Kitting'; fa = 'کیت‌سازی';
																	|it = 'Montaggio';
																	|pl = 'Kitting';
																	|tr = 'Montaj'"));
	EndIf;
	If GetFunctionalOption("UseProduction") 
		And GetFunctionalOption("EnterpriseManagement") Then
		
		Presentation =
			?(GetFunctionalOption("UseSubcontractOrders2_5")
				Or False,
			NStr("vi = 'Sản xuất riêng';
				|ru = 'Собственное производство';
				|en = 'In-house production'; fa = 'تولید داخلی';
				|it = 'Produzione propria';
				|pl = 'Własna produkcja';
				|tr = 'Şirket içi üretim'"),
			NStr("vi = 'Sản xuất';
				|ru = 'Производство';
				|en = 'Production'; fa = 'تولید';
				|it = 'Produzione';
				|pl = 'Produkcja';
				|tr = 'Üretim'"));
			
		ChoiceList.Add(Enums.SupplyTypes.Production, Presentation);
		
	EndIf;
	
	If GetFunctionalOption("UseSubcontractOrders2_5")
		Or False Then
		ChoiceList.Add(Enums.SupplyTypes.ProductionByThirdParty);
	EndIf;
	For SwitchNumber = 1 To 5 Do
		TagName = "SupplyType" + SwitchNumber;
		Items[TagName].ChoiceList.Clear();
		If SwitchNumber <= ChoiceList.Count() Then
			SelectionValue = ChoiceList.Get(SwitchNumber-1);
			Items[TagName].ChoiceList.Add(SelectionValue.Value, SelectionValue.Presentation);
		Else
			Items[TagName].Visible = False;
		EndIf;
	EndDo; 
	
	Return ChoiceList;

EndFunction

&AtServer
Procedure TermsOnChangeServer(ClearSubordinateDetails)
	
	If ClearSubordinateDetails Then
		Object.VendorPriceKind = Undefined;
		Object.Organization = Undefined;
	EndIf;
	
	If ValueIsFilled(Object.Terms)
			And Not ValueIsFilled(Object.VendorPriceKind)
			And Not ValueIsFilled(Object.Organization) Then
		AttributesValues = Common.ObjectAttributesValues(Object.Terms,
			"VendorPriceKind,Organization,ShipmentDueDate,DeliveryTime");
		PriceTypeByTerms = AttributesValues.VendorPriceKind;
		OrganizationByTerms = AttributesValues.Organization;
		If ClearSubordinateDetails Then
			Object.OrderFulfillmentPeriod = AttributesValues.ShipmentDueDate + AttributesValues.DeliveryTime;
		EndIf;
		Items.OrganizationPages.CurrentPage = Items.OrganizationByAgreementPage;
	Else
		Items.OrganizationPages.CurrentPage = Items.OrganizationPage;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_FirstDateInDeliverySchedule" Then
		FirstDateInDeliveryScheduleOnChange(Items.FirstDateInDeliverySchedule);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
