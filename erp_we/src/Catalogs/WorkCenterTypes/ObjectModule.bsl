#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	SubsystemSettings = ProductionServer.SubsystemSettingsProduction();
	PlannedSchedule =
		SubsystemSettings.TheProductionScheduleIsPlanned;
	
	If Not PlannedSchedule Then
		NotCheckedAttributeArray.Add("MaximumWorkCenterAvailability");
		NotCheckedAttributeArray.Add("UnitOfMeasureOfWorkCenterSchedule");
		NotCheckedAttributeArray.Add("MaximumLoad");
	Else
		CheckMaximumRCAvailability(Cancel);
	EndIf;
	
	If Not SetupSettingsAreUsed Then
		NotCheckedAttributeArray.Add("ChangeoverTimeUnit");
	EndIf; 
	
	If Not ParallelLoad Then
		NotCheckedAttributeArray.Add("UnitOfMeasureOfLoad");
		NotCheckedAttributeArray.Add("ImportOption");
		NotCheckedAttributeArray.Add("MaximumLoad");
	EndIf; 
	
	If Not ParallelLoad 
		Or ImportOption <> Enums.WorkCenterLoadOptions.Synchronous 
		Or SetupSettingsAreUsed Then
		NotCheckedAttributeArray.Add("OperationTime");
		NotCheckedAttributeArray.Add("UnitOfMeasure");
	EndIf; 
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsFolder Then
		Return;
	EndIf;
		
EndProcedure

#EndRegion

#Region Private

Procedure CheckMaximumRCAvailability(Cancel)

	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Department);
	
	PlanningInterval = DivisionParameters.PlanningInterval;
	
	If Not ValueIsFilled(PlanningInterval) Or PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		Return;
	EndIf;
	
	If ValueIsFilled(MaximumWorkCenterAvailability) And ValueIsFilled(UnitOfMeasureOfWorkCenterSchedule) Then
		
		MaximumAvailabilityOfRTSInSeconds = ProductionPlanningClientServer.GetTimeInSeconds(MaximumWorkCenterAvailability, UnitOfMeasureOfWorkCenterSchedule);
		
		If PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
			IntervalInSeconds = 3600;
		ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Day
			Or PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
			IntervalInSeconds = 86400;
		ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
			IntervalInSeconds = 604800;
		ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
			IntervalInSeconds = 2592000;
		EndIf;
		
		If MaximumAvailabilityOfRTSInSeconds > IntervalInSeconds Then
			MessageText = NStr("vi = 'Tính khả dụng tối đa không thể vượt quá khoảng thời gian lập kế hoạch.';
								|ru = 'Максимальная доступность не должна превышать интервал планирования.';
								|en = 'Maximum capacity should not exceed planning interval.'; fa = 'Maximum capacity should not exceed planning interval.';
								|it = 'La disponibilità massima non deve superare l''intervallo di pianificazione.';
								|pl = 'Maksymalna dostępność nie może przekraczać okresu planowania.';
								|tr = 'Maksimum kullanılabilirlik, planlama aralığını aşmamalıdır.'");
			CommonClientServer.MessageToUser(MessageText, ThisObject, "MaximumWorkCenterAvailability",, Cancel);
		EndIf;
		
	EndIf; 
	
EndProcedure

#EndRegion

#EndIf
