///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DaySchedule = Parameters.WorkSchedule;
	RollingShifts = Parameters.RollingShifts;
	AdjustTimeFieldsFormat();
	
	For Each IntervalDetails In DaySchedule Do
		FillPropertyValues(WorkSchedule.Add(), IntervalDetails);
	EndDo;
	
	If Not RollingShifts Then
		WorkSchedule.Sort("BeginTime");
	EndIf;
	
	Items.WorkSchedule.ChangeRowOrder = RollingShifts;
	
	If Common.IsMobileClient() Then
		Items.CommandBarBottom.Visible = False;
	Else
		CommandBarLocation = FormCommandBarLabelLocation.None;
		Items.OK.DefaultButton = True;
	EndIf;
	
	FillInTotalTime(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("SelectAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WorkScheduleOnEditEnd(Item, NewRow, CancelEdit)
		
	If CancelEdit Then
		Return;
	EndIf;
	
	If Not RollingShifts Then
		WorkSchedulesClient.RestoreCollectionRowOrderAfterEditing(WorkSchedule, "BeginTime", Item.CurrentData);
	EndIf;
	
	FillInTotalTime(ThisObject);
	
EndProcedure

&AtClient
Procedure WorkScheduleAfterDeleteRow(Item)
	
	FillInTotalTime(ThisObject);
	
EndProcedure
#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SelectAndClose();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Modified = False;
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function DaySchedule()
	
	Cancel = False;
	
	DaySchedule = New Array;
	
	If RollingShifts Then
		DayNumber = 1;
		EndDay = '00010101';
		For RowIndex = 0 To WorkSchedule.Count()-1 Do
			ScheduleString = WorkSchedule[RowIndex];
			
			If ScheduleString.BeginTime < EndDay Then
				DayNumber = DayNumber + 1;
			EndIf;
			
			If ScheduleString.BeginTime = ScheduleString.EndTime
				Or Not ValueIsFilled(ScheduleString.EndTime)
				Or ScheduleString.BeginTime > ScheduleString.EndTime Then
				DayNumber = DayNumber + 1;
			EndIf;
			
			EndDay = ScheduleString.EndTime;
			
			If DayNumber >= 3 And ValueIsFilled(EndDay) Then
				CommonClient.MessageToUser(
					NStr("vi = 'Tìm thấy khoản thời gian chồng chéo';
						|ru = 'Обнаружены пересекающиеся интервалы';
						|en = 'Overlapping intervals are detected.'; fa = 'Overlapping intervals are detected.';
						|it = 'Rilevati intervalli sovrapposti';
						|pl = 'Znaleziono pokrywające się interwały';
						|tr = 'Çakışan aralıklar tespit edildi'"), ,
					StringFunctionsClientServer.SubstituteParametersToString("WorkSchedule[%1].BeginTime", RowIndex), ,
					Cancel);
				Break;
			EndIf;
			
			DaySchedule.Add(New Structure("BeginTime, EndTime", ScheduleString.BeginTime, ScheduleString.EndTime));
		EndDo;
	Else
		EndDay = Undefined;
		For RowIndex = 0 To WorkSchedule.Count()-1 Do
			ScheduleString = WorkSchedule[RowIndex];
			If ScheduleString.BeginTime > ScheduleString.EndTime 
				And ValueIsFilled(ScheduleString.EndTime) Then
				CommonClient.MessageToUser(
					NStr("vi = 'Thời gian bắt đầu lớn hơn thời gian kết thúc';
						|ru = 'Время начала больше времени окончания';
						|en = 'The start time is greater than the end time.'; fa = 'The start time is greater than the end time.';
						|it = 'Il tempo d''inizio è superiore al tempo del termine';
						|pl = 'Czas rozpoczęcia jest późniejszy od czasu zakończenia';
						|tr = 'Başlangıç zamanı bitiş zamanından ileri'"), ,
					StringFunctionsClientServer.SubstituteParametersToString("WorkSchedule[%1].EndTime", RowIndex), ,
					Cancel);
			EndIf;
			If ScheduleString.BeginTime = ScheduleString.EndTime Then
				CommonClient.MessageToUser(
					NStr("vi = 'Thời gian của khoảng thời gian chưa xác định';
						|ru = 'Длительность интервала не определена';
						|en = 'The interval length is not specified.'; fa = 'The interval length is not specified.';
						|it = 'Durata dell''intervallo non definita';
						|pl = 'Czas trwania interwału nie został określony';
						|tr = 'Aralık süresi belirtilmedi'"), ,
					StringFunctionsClientServer.SubstituteParametersToString("WorkSchedule[%1].EndTime", RowIndex), ,
					Cancel);
			EndIf;
			If EndDay <> Undefined Then
				If EndDay > ScheduleString.BeginTime 
					Or Not ValueIsFilled(EndDay) Then
					CommonClient.MessageToUser(
						NStr("vi = 'Tìm thấy khoản thời gian chồng chéo';
							|ru = 'Обнаружены пересекающиеся интервалы';
							|en = 'Overlapping intervals are detected.'; fa = 'Overlapping intervals are detected.';
							|it = 'Rilevati intervalli sovrapposti';
							|pl = 'Znaleziono pokrywające się interwały';
							|tr = 'Çakışan aralıklar tespit edildi'"), ,
						StringFunctionsClientServer.SubstituteParametersToString("WorkSchedule[%1].BeginTime", RowIndex), ,
						Cancel);
				EndIf;
			EndIf;
			EndDay = ScheduleString.EndTime;
			DaySchedule.Add(New Structure("BeginTime, EndTime", ScheduleString.BeginTime, ScheduleString.EndTime));
		EndDo;
	EndIf;
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	Return DaySchedule;
	
EndFunction

&AtClient
Procedure SelectAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	DaySchedule = DaySchedule();
	If DaySchedule = Undefined Then
		Return;
	EndIf;
	
	Modified = False;
	NotifyChoice(New Structure("WorkSchedule", DaySchedule));
	
EndProcedure

&AtServer
Procedure AdjustTimeFieldsFormat()
	
	TimeFormat = ?(WorkSchedules.TwelveHourTimeFormat(),
		NStr("vi = 'DF=''hh:mm tt''; DE=';
			|ru = 'ДФ=''чч:мм вв''; ДП=';
			|en = 'DF=''hh:mm tt''; DE='; fa = 'DF=''hh:mm tt''; DE=';
			|it = 'DF=''hh:mm''; DE=';
			|pl = 'DF=''hh:mm''; DE=';
			|tr = 'DF=''hh:mm tt''; DE='"), NStr("vi = 'DF=HH:mm; DE=';
													|ru = 'ДФ=ЧЧ:мм; ДП=';
													|en = 'DF=''HH:mm''; DE='; fa = 'DF=''HH:mm''; DE=';
													|it = 'DF=HH:mm; DE=';
													|pl = 'DF=GG:mm; DE=';
													|tr = 'DF=HH:mm; DE='"));
	EditingTimeFormat = ?(WorkSchedules.TwelveHourTimeFormat(),
		NStr("vi = 'DF=''hh:mm tt''';
			|ru = 'ДФ=''чч:мм вв''';
			|en = 'DF=''hh:mm tt'''; fa = 'DF=''hh:mm tt''';
			|it = 'DF=''hh:mm''';
			|pl = 'DF=''hh:mm''';
			|tr = 'DF=''hh:mm tt'''"), NStr("vi = 'DF=HH:mm';
											|ru = 'ДФ=ЧЧ:мм';
											|en = 'DF=HH:mm'; fa = 'DF=HH:mm';
											|it = 'DF=HH:mm';
											|pl = 'DF=HH:mm';
											|tr = 'DF=HH:mm'"));
	
	Items.WorkScheduleBeginTime.Format = TimeFormat;
	Items.WorkScheduleBeginTime.EditFormat = EditingTimeFormat;
	
	Items.WorkScheduleEndTime.Format = TimeFormat;
	Items.WorkScheduleEndTime.EditFormat = EditingTimeFormat;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInTotalTime(Form)
	
	Seconds = 0;
	
	For Each String In Form.WorkSchedule Do
		If String.BeginTime = String.EndTime Then
			IntervalInSeconds = 86400;
		ElsIf String.BeginTime < String.EndTime Then
			IntervalInSeconds = String.EndTime - String.BeginTime;
		ElsIf Not ValueIsFilled(String.EndTime) Then
			IntervalInSeconds = EndOfDay(String.EndTime) - String.BeginTime + 1;
		Else
			IsMainPart = EndOfDay(String.BeginTime) - String.BeginTime + 1;
			RollingPart = String.EndTime - BegOfDay(String.EndTime);
			IntervalInSeconds = IsMainPart + RollingPart;
		EndIf;
		
		Seconds = Seconds + IntervalInSeconds;
	EndDo;
	
	Hours = Round(Seconds / 3600, 1);
	
	Form.Items.TotalTime.Title = StrTemplate(NStr("vi = 'Tổng số: %1 giờ';
													|ru = 'Всего: %1 ч.';
													|en = 'Total: %1 h.'; fa = 'Total: %1 h.';
													|it = 'Всего: %1 ч.';
													|pl = 'Total: %1 h.';
													|tr = 'Tümü: %1 s.'"), Hours);
	
EndProcedure

#EndRegion
