
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	PlanningSettings = DataProcessors.ProductionSchedulePlanning2_2.PreScheduleSchedulingSettings();
	PlanningSettings.ProductionOrder = Parameters.ProductionOrder;
	PlanningSettings.DynamicStructure = Parameters.DynamicStructure;
	
	DynamicStructure = Parameters.DynamicStructure;
	ActivateOrderAvailabilityReserve = Common.ObjectAttributeValue(
		Parameters.ProductionOrder, "UseAvailabilityReserve");
	
	UploadFormSettings();
	
	If PlanSchedule Then
		ActivateTheAvailabilityReserveSchedule = ActivateOrderAvailabilityReserve;
	EndIf;
	
	If PlanModel
		And Not UnlimitedEquipmentFleet Then
		ActivateTheAvailabilityReserveModel = ActivateOrderAvailabilityReserve;
	EndIf;
	
	ProductionSettings = ProductionServer.SubsystemSettingsProduction();
	
	HideDisableUnavailableSettings(ProductionSettings);
	
	FillInPlanSchedulePrompt(ProductionSettings);
	
	FillInOtherSettingsPrompt(ThisObject);
	
	AvailabilityControl(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PlanScheduleOnChange(Item)
	
	If PlanSchedule Then
		ActivateTheAvailabilityReserveSchedule = ActivateOrderAvailabilityReserve;
	Else
		ActivateTheAvailabilityReserveSchedule = False;
	EndIf;
	
	AvailabilityControl(ThisObject);
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure PlanModelOnChange(Item)
	
	If PlanModel Then
		ActivateTheAvailabilityReserveModel = ActivateOrderAvailabilityReserve;
	Else
		ActivateTheAvailabilityReserveModel = False;
	EndIf;
	
	AvailabilityControl(ThisObject);
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure UnlimitedEquipmentFleetOnChange(Item)
	
	If UnlimitedEquipmentFleet Then
		ActivateTheAvailabilityReserveModel = False;
	Else
		ActivateTheAvailabilityReserveModel = ActivateOrderAvailabilityReserve;
	EndIf;
	
	AvailabilityControl(ThisObject);
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure ActivateTheAvailabilityReserveScheduleOnChange(Item)
	
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure ActivateTheAvailabilityReserveModelOnChange(Item)
	
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure AllMaterialsInStockOnChange(Item)
	
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure RoundTheClockWorkSevenDaysAWeekOnChange(Item)
	
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure NoOtherOrdersOnChange(Item)
	
	SaveFormSettingsClient();
	
EndProcedure

&AtClient
Procedure FullReplanningOnChange(Item)
	
	AvailabilityControl(ThisObject);
	SaveFormSettingsClient();
	FillInOtherSettingsPrompt(ThisObject);
	
EndProcedure

&AtClient
Procedure CancelManualChangesOfScheduleOnChange(Item)
	
	FillInOtherSettingsPrompt(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToPlan_2(Command)
	
	If PlanSchedule Or PlanModel Then
		
		FillPropertyValues(PlanningSettings, ThisObject);
		Close(PlanningSettings);
		
	Else
		
		MessageText = NStr("vi = 'Cần chọn ít nhất một trong các tùy chọn lập kế hoạch (""Lập kế hoạch lịch trình"" và / hoặc ""Lập kế hoạch cho một mô hình"")';
							|ru = 'Необходимо выбрать хотя бы один из вариантов планирования (""Планировать график"" и/или ""Планировать модель"")';
							|en = 'Please select at least one of the scheduling options: Enable production scheduling model or Enable production scheduling'; fa = 'Please select at least one of the scheduling options: Enable production scheduling model or Enable production scheduling';
							|it = 'È necessario selezionare almeno una delle opzioni di pianificazione (""Programmare il piano"" e o ""Programmare il modello"")';
							|pl = 'Należy wybrać przynajmniej jedną z opcji planowania (""Planować harmonogram"" i/lub ""Planować model"")';
							|tr = 'Planlama seçeneklerinden en az birini seçmeniz gerekmektedir (""Programı planla"" ve/veya ""Modeli planla"")'");
		CommonClientServer.MessageToUser(MessageText,, "PlanSchedule");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SaveFormSettingsClient()
	
	Settings = New Structure;
	Settings.Insert("PlanSchedule", PlanSchedule);
	Settings.Insert("PlanModel", PlanModel);
	Settings.Insert("AllMaterialsInStock", AllMaterialsInStock);
	Settings.Insert("UnlimitedEquipmentFleet", UnlimitedEquipmentFleet);
	Settings.Insert("RoundTheClockWorkSevenDaysAWeek", RoundTheClockWorkSevenDaysAWeek);
	Settings.Insert("NoOtherOrders", NoOtherOrders);
	Settings.Insert("FullReplanning", FullReplanning);
	
	SaveFormSettingsServer(Settings);
	
EndProcedure

&AtServerNoContext
Procedure SaveFormSettingsServer(Settings)
	
	Common.CommonSettingsStorageSave(
		FormKey(),
		Undefined,
		Settings);
	
EndProcedure

&AtServer
Procedure UploadFormSettings()
	
	Settings = Common.CommonSettingsStorageLoad(
		FormKey(),
		Undefined);
	
	If TypeOf(Settings) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, Settings);
		
	EndIf;
	
	If Not PlanSchedule And Not PlanModel Then
		
		PlanSchedule = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure HideDisableUnavailableSettings(ProductionSettings)
	
	If Not ProductionSettings.PlanningByProductionResourcesIsUsed Then
		
		Items.ActivateTheAvailabilityReserveSchedule.Visible = False;
		Items.IndentDecoration1.Visible = False;
		ActivateTheAvailabilityReserveSchedule = False;
		
		Items.ActivateTheAvailabilityReserveModel.Visible = False;
		ActivateTheAvailabilityReserveModel = False;
		
		Items.UnlimitedEquipmentFleet.Visible = False;
		UnlimitedEquipmentFleet = False;
		
		Items.NoOtherOrders.Visible = False;
		NoOtherOrders = False;
		
	EndIf;
	
	If DynamicStructure Then
		Items.FullReplanning.Visible = False;
		Items.OtherSettingsGroup.ToolTipRepresentation = ToolTipRepresentation.None;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function FormKey()
	
	Return "DataProcessor.ProductionSchedulePlanning2_2.PlanningSettingsReferences";
	
EndFunction

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	Items = Form.Items;
	
	Items.ActivateTheAvailabilityReserveSchedule.Enabled = Form.PlanSchedule;
	
	Items.ActivateTheAvailabilityReserveModel.Enabled = Form.PlanModel
		And Not Form.UnlimitedEquipmentFleet;
	
	Items.AllMaterialsInStock.Enabled = Form.PlanModel;
	Form.AllMaterialsInStock = ?(Items.AllMaterialsInStock.Enabled,
		Form.AllMaterialsInStock, False);
	
	Items.UnlimitedEquipmentFleet.Enabled = Form.PlanModel;
	Form.UnlimitedEquipmentFleet = ?(Items.UnlimitedEquipmentFleet.Enabled,
		Form.UnlimitedEquipmentFleet, False);
		
	Items.RoundTheClockWorkSevenDaysAWeek.Enabled = Form.PlanModel;
	Form.RoundTheClockWorkSevenDaysAWeek = ?(Items.RoundTheClockWorkSevenDaysAWeek.Enabled,
		Form.RoundTheClockWorkSevenDaysAWeek, False);
	
	Items.NoOtherOrders.Enabled = Form.PlanModel
		And Not Form.UnlimitedEquipmentFleet;
	Form.NoOtherOrders = ?(Items.NoOtherOrders.Enabled,
		Form.NoOtherOrders, False);
	
	Items.CancelManualChangesOfSchedule.Enabled = Form.FullReplanning
		Or Form.DynamicStructure;
	Form.CancelManualChangesOfSchedule = ?(Items.CancelManualChangesOfSchedule.Enabled,
		Form.CancelManualChangesOfSchedule, False);
	
EndProcedure

&AtServer
Procedure FillInPlanSchedulePrompt(ProductionSettings)
	
	If ProductionSettings.PlanningByProductionResourcesIsUsed
		And ProductionSettings.PlanningByMaterialResourcesIsUsed Then
		
		Items.PlanSchedule.ToolTip = 
			NStr("vi = 'Khi lập kế hoạch, các hạn chế về vật liệu và thiết bị được tính đến.';
				|ru = 'При планировании учитываются ограничения по материалам и оборудованию.';
				|en = 'Production scheduling considers material and equipment limitations.'; fa = 'Production scheduling considers material and equipment limitations.';
				|it = 'La pianificazione tiene conto delle restrizioni per materiali e attrezzature.';
				|pl = 'Przy planowaniu uwzględnia się ograniczenia dotyczące materiałów i urządzeń.';
				|tr = 'Planlama sırasında malzeme ve ekipman kısıtlamaları dikkate alınmaktadır.'");
		
	ElsIf ProductionSettings.PlanningByProductionResourcesIsUsed Then
		
		Items.PlanSchedule.ToolTip = 
			NStr("vi = 'Khi lập kế hoạch, các hạn chế thiết bị được tính đến.';
				|ru = 'При планировании учитываются ограничения по оборудованию.';
				|en = 'Production scheduling considers equipment limitations.'; fa = 'Production scheduling considers equipment limitations.';
				|it = 'La pianificazione tiene conto delle restrizioni per le attrezzature.';
				|pl = 'Przy planowaniu uwzględnia się ograniczenia dotyczące urządzeń.';
				|tr = 'Planlama sırasında ekipman kısıtlamaları dikkate alınmaktadır.'");
		
	ElsIf ProductionSettings.PlanningByMaterialResourcesIsUsed Then
		
		Items.PlanSchedule.ToolTip = 
			NStr("vi = 'Khi lập kế hoạch, các hạn chế vật chất được tính đến.';
				|ru = 'При планировании учитываются ограничения по материалам.';
				|en = 'Production scheduling considers material limitations.'; fa = 'Production scheduling considers material limitations.';
				|it = 'La pianificazione tiene conto delle restrizioni per i materiali.';
				|pl = 'Przy planowaniu uwzględnia się ograniczenia dotyczące materiałów.';
				|tr = 'Planlama sırasında malzeme kısıtlamaları dikkate alınmaktadır.'");
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInOtherSettingsPrompt(Form)
	
	ToolTip = ProductionManagementClientServer.DescriptionOfSchedulingSettings(
		Form.FullReplanning,
		Form.CancelManualChangesOfSchedule);
	
	Form.Items.OtherSettingsGroup.ToolTip = ToolTip;
	
EndProcedure

#EndRegion
