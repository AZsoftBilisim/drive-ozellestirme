
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	StageSchedulePlanning = Parameters.StageSchedulePlanning;
	ThereAreDynamicOrders = False;
	
	UploadFormSettings();
	
	If StageSchedulePlanning
		And ValueIsFilled(Parameters.Stages) Then
		
		Query = New Query(
			"SELECT
			|	SUM(
			|		CASE
			|			WHEN Stages.StagePlacementInProductionSchedule
			|				THEN 1
			|			ELSE 0
			|		END) AS Stages_WithManualPlacement,
			|	SUM(
			|		CASE
			|			WHEN Stages.DynamicStructure
			|				THEN 1
			|			ELSE 0
			|		END) AS StagesOfDynamicStructure
			|FROM
			|	Document.ProductionStage2_2 AS Stages
			|WHERE
			|	Stages.Ref IN(&Stages)");
		Query.SetParameter("Stages", Parameters.Stages);
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			If Selection.Stages_WithManualPlacement > 0 Then
				Items.TheLabelIsPlacedManually.Title = StrTemplate(
					NStr("vi = 'Có các công đoạn được lên lịch thủ công (tổng cộng: %1).';
						|ru = 'Имеются этапы, запланированные вручную (всего: %1).';
						|en = 'There are stages scheduled manually (total: %1).'; fa = 'There are stages scheduled manually (total: %1).';
						|it = 'Имеются этапы, запланированные вручную (всего: %1).';
						|pl = 'Są etapy, zaplanowane ręcznie (ogółem: %1).';
						|tr = 'Manuel olarak planlanan aşamalar mevcut (toplam: %1).'"),
					Selection.Stages_WithManualPlacement);
				Items.ManuallyPlacedGroup.Visible = True;
			Else
				Items.ManuallyPlacedGroup.Visible = False;
			EndIf;
			
			If Selection.StagesOfDynamicStructure > 0 Then
				Items.TheLabelTheRelevanceOfTheGraph.Title = StrTemplate(
					NStr("vi = 'Có các giai đoạn của cấu trúc động trong đơn hàng (tổng số: %1).
						|Để tính toán, cần cập nhật lại lịch biểu của toàn bộ đơn hàng.';
						|ru = 'Имеются этапы динамической структуры заказа (всего: %1).
						|Для их рассчета необходимо пересчитать график всего заказа.';
						|en = 'There are stages with dynamic structure of order (total: %1).
						|To calculate the structure, recalculate the whole schedule.'; fa = 'There are stages with dynamic structure of order (total: %1).
						|To calculate the structure, recalculate the whole schedule.';
						|it = 'There are stages with dynamic structure of order (total: %1).
						|To calculate the structure, recalculate the whole schedule.';
						|pl = 'There are stages with dynamic structure of order (total: %1).
						|To calculate the structure, recalculate the whole schedule.';
						|tr = 'Siparişin dinamik yapısının aşamaları vardır (toplam: %1).
						|Bunların hesaplanması için tüm siparişin programını yeniden hesaplamak gerekmektedir.'"),
					Selection.StagesOfDynamicStructure);
				Items.ChartRelevanceGroup.Visible = True;
			Else
				Items.ChartRelevanceGroup.Visible = False;
			EndIf;
		Else
			Items.ManuallyPlacedGroup.Visible = False;
			Items.ChartRelevanceGroup.Visible = False;
		EndIf;
		
		Items.GroupAvailabilityOfHigherPriorityOrders.Visible = False;
		
	ElsIf Not StageSchedulePlanning
		And ValueIsFilled(Parameters.References) Then
		
		Query = New Query(
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	Document.ProductionOrder2_2 AS Orders
			|WHERE
			|	Orders.Ref IN (&References)
			|	AND Orders.DynamicStructure");
		Query.SetParameter("References", Parameters.References);
		QueryResult = Query.Execute();
		ThereAreDynamicOrders = Not QueryResult.IsEmpty();
		
		PlacedManually_ = 0;
		CalculateTheSchedule = 0;
		ThereArePriorities = False;
		
		ReadInformationLabelData(
			PlacedManually_, CalculateTheSchedule, ThereArePriorities, Parameters.References);
		
		If PlacedManually_ > 0 Then
			Items.TheLabelIsPlacedManually.Title = StrTemplate(
				NStr("vi = 'Có các công đoạn được lên lịch thủ công (tổng cộng: %1).';
					|ru = 'Имеются этапы, запланированные вручную (всего: %1).';
					|en = 'There are stages scheduled manually (total: %1).'; fa = 'There are stages scheduled manually (total: %1).';
					|it = 'Имеются этапы, запланированные вручную (всего: %1).';
					|pl = 'Są etapy, zaplanowane ręcznie (ogółem: %1).';
					|tr = 'Manuel olarak planlanan aşamalar mevcut (toplam: %1).'"),
				PlacedManually_);
			Items.ManuallyPlacedGroup.Visible = True;
		Else
			Items.ManuallyPlacedGroup.Visible = False;
		EndIf;
		
		If CalculateTheSchedule > 0 Then
			If ThereAreDynamicOrders Then
				// In dean. The structure has Lot reference and order assignments
				Items.TheLabelTheRelevanceOfTheGraph.Title = NStr("vi = 'Chưa cập nhật lịch biểu.';
																	|ru = 'График не актуален.';
																	|en = 'Schedule is not relevant.'; fa = 'Schedule is not relevant.';
																	|it = 'График не актуален.';
																	|pl = 'Schedule is not relevant.';
																	|tr = 'Program güncel değil.'");
			Else
				Items.TheLabelTheRelevanceOfTheGraph.Title = StrTemplate(
					NStr("vi = 'Lịch trình không liên quan. Có những công đoạn yêu cầu lập kế hoạch lại (tổng: %1).';
						|ru = 'График не актуален. Имеются этапы, требующие перепланирования (всего: %1).';
						|en = 'Schedule is not relevant. There are stages which require rescheduling (total: %1).'; fa = 'Schedule is not relevant. There are stages which require rescheduling (total: %1).';
						|it = 'График не актуален. Имеются этапы, требующие перепланирования (всего: %1).';
						|pl = 'Harmonogram jest nieaktualny. Są etapy, które wymagają ponownego planowania (ogółem:%1).';
						|tr = 'Program güncel değil. Yeniden planlanması gereken aşamalar mevcut (toplam: %1).'"),
					CalculateTheSchedule);
			EndIf;
		Else
			Items.TheLabelTheRelevanceOfTheGraph.Title = NStr("vi = 'Lịch trình có liên quan.';
																|ru = 'График актуален.';
																|en = 'Schedule is relevant.'; fa = 'Schedule is relevant.';
																|it = 'График актуален.';
																|pl = 'Harmonogram jest aktualny.';
																|tr = 'Program güncel.'");
		EndIf;
		Items.ChartRelevanceGroup.Visible = True;
		
		Items.GroupAvailabilityOfHigherPriorityOrders.Visible = ThereArePriorities;
		
	EndIf;
	
	Items.FullReplanning.Visible = Not(StageSchedulePlanning Or ThereAreDynamicOrders);
	If ThereAreDynamicOrders Then
		FullReplanning = True;
	EndIf;
	
	Items.CancelManualChangesOfSchedule.Enabled = FullReplanning
		Or Not Items.FullReplanning.Visible;
	
	FillInSettingsExplanation(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FullReplanningOnChange(Item)
	
	Items.CancelManualChangesOfSchedule.Enabled = FullReplanning;
	If Not FullReplanning Then
		CancelManualChangesOfSchedule = False;
	EndIf;
	
	SaveFormSettingsClient();
	FillInSettingsExplanation(ThisObject);
	
EndProcedure

&AtClient
Procedure CancelManualChangesOfScheduleOnChange(Item)
	
	FillInSettingsExplanation(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToPlan_2(Command)
	
	PlanningSettings = New Structure;
	PlanningSettings.Insert("CancelManualChangesOfSchedule", CancelManualChangesOfSchedule);
	
	If Not StageSchedulePlanning Then
		PlanningSettings.Insert("FullReplanning", FullReplanning);
	EndIf;
	
	Close(PlanningSettings);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UploadFormSettings()
	
	Settings = Common.CommonSettingsStorageLoad(FormKey(), Undefined);
	
	If TypeOf(Settings) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, Settings);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveFormSettingsClient()
	
	Settings = New Structure;
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

&AtClientAtServerNoContext
Function FormKey()
	
	Return "DataProcessor.ProductionSchedulePlanning2_2.PlanningSettingsOfListOfReferencesAndStages";
	
EndFunction

&AtClientAtServerNoContext
Procedure FillInSettingsExplanation(Form)
	
	If Form.StageSchedulePlanning
		Or Form.ThereAreDynamicOrders Then
		Return;
	EndIf;
	
	ToolTip = ProductionManagementClientServer.DescriptionOfSchedulingSettings(
		Form.FullReplanning,
		Form.CancelManualChangesOfSchedule);
	
	Form.Items.Group1.ToolTip = ToolTip;
	
EndProcedure

&AtServer
Procedure ReadInformationLabelData(PlacedManually_, CalculateTheSchedule, ThereArePriorities, References)
	
	ReferenceOrder = OrderWithLowestPriority(References);
	
	TempTablesManager = New TempTablesManager;
	Documents.ProductionOrder2_2.CreateTTOrdersWithHighPriority(
		TempTablesManager,
		"TTPriorityOrders",
		ReferenceOrder);
	
	ExcludePlannedOrdersFromTT(
		TempTablesManager,
		"TTPriorityOrders",
		References);
	
	ThereAreEntriesInSchedule = False;
	
	DataProcessors.ProductionSchedulePlanning2_2.ReadNumberOfObjectsToSchedule(
		PlacedManually_,
		CalculateTheSchedule,
		ThereArePriorities,
		ThereAreEntriesInSchedule,
		References,
		TempTablesManager,
		"TTPriorityOrders");
	
EndProcedure

&AtServer
Function OrderWithLowestPriority(References)
	
	If References.Count() = 1 Then
		
		Result = References[0];
		
	Else
		
		Query = New Query(
		"SELECT TOP 1
		|	ProductionOrder2_2.Ref AS Ref
		|FROM
		|	Document.ProductionOrder2_2 AS ProductionOrder2_2
		|WHERE
		|	ProductionOrder2_2.Posted = TRUE
		|	AND ProductionOrder2_2.Ref IN(&References)
		|
		|ORDER BY
		|	ProductionOrder2_2.Priority.AddlOrderingAttribute DESC,
		|	ProductionOrder2_2.Department.AddlOrderingAttribute DESC,
		|	ProductionOrder2_2.Queue DESC");
		
		Query.SetParameter("References", References);
		Selection = Query.Execute().Select();
		Selection.Next();
		
		Result = Selection.Ref;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure ExcludePlannedOrdersFromTT(TempTablesManager, TempTableName, References)
	
	QueryText = 
	"SELECT
	|	TTPriorityOrders.Ref
	|INTO TTOrders
	|FROM
	|	TTPriorityOrders AS TTPriorityOrders
	|WHERE
	|	NOT TTPriorityOrders.Ref IN (&References)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTPriorityOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTOrders.Ref
	|INTO TTPriorityOrders
	|FROM
	|	TTOrders AS TTOrders";
	
	QueryText = StrReplace(QueryText, "TTPriorityOrders", TempTableName);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("References", References);
	Query.Execute();
	
EndProcedure

#EndRegion
