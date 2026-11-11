
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Warehouse = Parameters.Warehouse;
	Premise = Parameters.Premise;
	
	UnitOfMeasureForWeight   = Constants.UnitOfMeasureForWeight.Get();
	UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
	
	ScheduledJobAction = "";
	Parameters.Property("ScheduledJobAction", ScheduledJobAction);
	
	If ScheduledJobAction = "CreateJobs" Then
		Items.GroupParametersOfARoutineTask.Visible = False;
		Items.CreateJobs.Title = NStr("vi = 'Tạo nhiệm vụ';
										|ru = 'Создать задания';
										|en = 'Create jobs'; fa = 'ایجاد کارها';
										|it = 'Creare i task';
										|pl = 'Utwórz zadania';
										|tr = 'Görev oluştur'");
	Else
		FillPropertyValues(ThisObject, Parameters, 
			"ScheduledJobDescription, JobSchedule,
			|IfThereAreErrorsRepeatTheRoutineTask, IfThereAreErrorsRepeatThroughTheRoutineTask
			|");
		FillPropertyValues(ThisObject, Parameters.SettingsForCreatingMoves, 
			"CustomizeGenerationByWorkAreas, LimitationByWeight,
			|LimitationByVolume, LimitByWeight, LimitByVolume, 
			|TaskCreationRule, WarehouseZone
			|");
	EndIf;
		
	WarehouseZoneUsage = Common.ObjectAttributeValue(Warehouse, "WarehouseZoneUsage");
	If WarehouseZoneUsage = Enums.UseIsDeterminedInWarerooms.DeterminedByWareroomsSettings Then
		WarehouseZoneUsage = Common.ObjectAttributeValue(Premise, "WarehouseZoneUsage");
	EndIf;

	SetDefaultBankingDetails(
		WarehouseZoneUsage = Enums.UseIsDeterminedInWarerooms.Use);
	Items.JobCreationSettingsWorkAreas.Visible = 
		WarehouseZoneUsage = Enums.UseIsDeterminedInWarerooms.Use;
		
	If Not GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		Items.GroupTaskCreationRuleSelection.Visible = False;
		Items.GroupRuleForCreatingTasksRecharge.Visible = True;
		AutoTitle = False;
		Title = NStr("vi = 'Tạo các nhiệm vụ để bổ sung các vùng chọn nhanh';
					|ru = 'Создание заданий на подпитку зон быстрого отбора';
					|en = 'Create jobs for replenishment of quick filter areas'; fa = 'Create jobs for replenishment of quick filter areas';
					|it = 'Creazione di compiti per sovvenzionamento di zone a selezione rapida';
					|pl = 'Tworzenie zadań do podładowań stref szybkiej selekcji';
					|tr = 'Hızlı filtre alanlarının stok yenilenmesi için görevlerin oluşturulması'");
	EndIf;
	
	SetAvailability(ThisForm);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LimitByWeightOnChange(Item)
	Items.LimitationByWeight.Enabled = LimitByWeight;
EndProcedure

&AtClient
Procedure LimitByVolumeOnChange(Item)
	Items.LimitationByVolume.Enabled = LimitByVolume;
EndProcedure

&AtClient
Procedure CustomizeGenerationByWorkAreasOnChange(Item)
	If CustomizeGenerationByWorkAreas = "ByASingleWarehouseZone"
		And ValueIsFilled(WarehouseZone) Then
		WarehouseZoneOnChangeServer();
	EndIf;
	SetAvailability(ThisForm);
EndProcedure

&AtClient
Procedure TaskCreationRuleOnChange(Item)
	ScheduledJobDescription = GenerateNameOfRoutineTask(Warehouse, Premise, TaskCreationRule);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateJobs(Command)
	ClearMessages();
	If Not CheckFilling() Then 
		Return
	EndIf;
	
	CreationParameters = New Structure;
	CreationParameters.Insert("Premise",								Premise);
	CreationParameters.Insert("Warehouse",									Warehouse);
	CreationParameters.Insert("TaskCreationRule",				TaskCreationRule);
	CreationParameters.Insert("CustomizeGenerationByWorkAreas",CustomizeGenerationByWorkAreas);
	CreationParameters.Insert("WarehouseZone",						WarehouseZone);
	CreationParameters.Insert("LimitByWeight",					LimitByWeight);
	CreationParameters.Insert("LimitationByWeight",						LimitationByWeight);
	CreationParameters.Insert("LimitByVolume",					LimitByVolume);
	CreationParameters.Insert("LimitationByVolume",					LimitationByVolume);
		
	Result = New Structure("ScheduledJobAction, ScheduledJobDescription, IfThereAreErrorsRepeatTheRoutineTask,
					|IfThereAreErrorsRepeatThroughTheRoutineTask, JobSchedule");
	FillPropertyValues(Result, ThisObject);
	Result.Insert("Action", "CloseAndSaveTheScheduledJob");
	Result.Insert("SettingsForCreatingMoves", CreationParameters);
	Close(Result);
		
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close(New Structure("Action", "Cancel"));
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClientAtServerNoContext
Procedure SetAvailability(Form)
	
	Form.Items.WarehouseZone.Enabled 				= Form.CustomizeGenerationByWorkAreas = "ByASingleWarehouseZone";
	Form.Items.LimitationByVolume.Enabled 			= Form.LimitByVolume;
	Form.Items.UnitOfMeasureForVolume.Enabled 		= Form.LimitByVolume;
	Form.Items.LimitationByWeight.Enabled			= Form.LimitByWeight;
	Form.Items.UnitOfMeasureForWeight.Enabled			= Form.LimitByWeight;
	
	If Form.CustomizeGenerationByWorkAreas = "GroupByWarehouseZones" Then
		Form.Items.RestrictionSettingsGroup.CurrentPage = Form.Items.PageLimitLabel;
	Else
		Form.Items.RestrictionSettingsGroup.CurrentPage = Form.Items.PageLimitCheckBoxes;
	EndIf;
	
EndProcedure

&AtClient
Procedure JobScheduleClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ScheduleDialog1 = New ScheduledJobDialog(JobSchedule);
	Notification = New CallbackDescription("JobScheduleClickCompletion", ThisForm);
	ScheduleDialog1.Show(Notification);
	
EndProcedure

&AtClient
Procedure JobScheduleClickCompletion(Schedule, AdditionalParameters) Export
	
	If Schedule = Undefined Or Not TypeOf(Schedule) = Type("JobSchedule") Then
		Return;
	EndIf;
	
	JobSchedule = Schedule;
	Modified = True;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If CustomizeGenerationByWorkAreas <> "ByASingleWarehouseZone" Then
		NotCheckedAttributeArray.Add("WarehouseZone");	
	EndIf;
	
	If Not LimitByWeight Then
		NotCheckedAttributeArray.Add("LimitationByWeight");	
	EndIf;
	
	If Not LimitByVolume Then
		NotCheckedAttributeArray.Add("LimitationByVolume");	
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

&AtServer
Procedure WarehouseZoneOnChangeServer()
		
	FillPropertyValues(
		ThisForm, 
		Common.ObjectAttributesValues(
			WarehouseZone,
			"LimitByWeight,LimitationByWeight,LimitByVolume,LimitationByVolume"),
		"LimitByWeight,LimitationByWeight,LimitByVolume,LimitationByVolume");
	
EndProcedure

&AtServer
Procedure SetDefaultBankingDetails(UseWarehouseZones)
	
	If Not ValueIsFilled(CustomizeGenerationByWorkAreas) 
		Or Not UseWarehouseZones Then
		CustomizeGenerationByWorkAreas = "WithoutBreakdownByWarehouseZones";
	EndIf;
	
	If Not ValueIsFilled(TaskCreationRule) Or Not GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		TaskCreationRule = Enums.TransferJobCreationRules.ReplenishmentOfQuickAccessAreas;
	EndIf;
	
	If Not ValueIsFilled(ScheduledJobDescription) Then
		ScheduledJobDescription = GenerateNameOfRoutineTask(Warehouse, Premise, TaskCreationRule);
	EndIf;

EndProcedure

&AtServerNoContext
Function GenerateNameOfRoutineTask(Warehouse, Premise, TaskCreationRule)
	
	ScheduledJobDescription = 
		NStr("vi = 'Tạo công việc chuyển nhượng ""%Rule%"" cho kho ""%WarehousePresentation_%""';
			|ru = 'Создание заданий на перемещение ""%Rule%"" для склада ""%WarehousePresentation_%""';
			|en = 'Create transfer jobs ""%Rule%"" for warehouse ""%WarehousePresentation_%""'; fa = 'Create transfer jobs ""%Rule%"" for warehouse ""%WarehousePresentation_%""';
			|it = 'Creazione compiti per lo spostamento ""%Rule%"" per il magazzino ""%WarehousePresentation_%""';
			|pl = 'Tworzenie zadań przemieszczenia ""%Rule%"" na magazyn ""%WarehousePresentation_%""';
			|tr = 'Ambar ""%WarehousePresentation_%"" için transfer görevleri ""%Rule%"" oluştur'");
	ScheduledJobDescription = 
		StrReplace(ScheduledJobDescription, 
			"%Rule%", 
			GenerateRuleNameForRegTask(TaskCreationRule));
	ScheduledJobDescription = 
		StrReplace(ScheduledJobDescription, 
			"%WarehousePresentation_%", 
			WarehousesServer.GetWarehousePresentation(Warehouse, Premise));
			
	Return ScheduledJobDescription;

EndFunction

&AtServerNoContext
Function GenerateRuleNameForRegTask(TaskCreationRule)
	If TaskCreationRule = 
		Enums.TransferJobCreationRules.TransferByPlacementRulesForGoodsAssigned Then
		Return NStr("vi = 'Vị trí hàng hóa đặt riêng';
					|ru = 'Размещение обособленных товаров';
					|en = 'Put-away assigned inventory'; fa = 'Put-away assigned inventory';
					|it = 'Posizionamento delle merci separate';
					|pl = 'Rozlokowanie oddzielnych towarów';
					|tr = 'Ayrıştırılmış ürünlerin yerleştirilmesi'");
	ElsIf TaskCreationRule = 
		Enums.TransferJobCreationRules.ReplenishmentOfQuickAccessAreas Then
		Return NStr("vi = 'Bổ sung các vùng chọn nhanh';
					|ru = 'Подпитка зон быстрого отбора';
					|en = 'Replenishment of quick filter areas'; fa = 'تکمیل ناحیه‌های فیلتر سریع';
					|it = 'Sovvenzionamento delle zone di selezione';
					|pl = 'Podładowanie stref szybkiego filtru';
					|tr = 'Hızlı filtre stok yenileme alanı'");
	EndIf;
	Return "";
EndFunction

#EndRegion

#EndRegion