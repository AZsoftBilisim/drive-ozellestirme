
#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(Object.Calendar) Then
		DeferredPaymentMode = 1;
	Else
		Items.Calendar.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If DeferredPaymentMode = 1 And Not ValueIsFilled(Object.Calendar) Then
		
		ErrorText = NStr("vi = 'Chưa chỉ ra lịch để tính khoảng thời gian theo ngày làm việc.';
						|ru = 'Не указан календарь для учета интервалов по рабочим дням.';
						|en = 'No calendar is specified for workday intervals.'; fa = 'No calendar is specified for workday intervals.';
						|it = 'Il calendario per la contabilizzazione degli intervalli nei giorni lavorativi non è specificato.';
						|pl = 'Nie określono kalendarza do ewidencji interwałów w dniach roboczych.';
						|tr = 'İş günlerinde aralıkları hesaba katacak bir takvim belirtilmemiştir.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			Object.Ref,
			"Object.Calendar",
			,
			Cancel);
		
	EndIf;

EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DeferredPaymentModeOnChange(Item)
	
	Items.Calendar.Enabled = ?(DeferredPaymentMode = 1, True, False);
	Items.Calendar.AutoMarkIncomplete = ?(DeferredPaymentMode = 1, True, False);
	
	If DeferredPaymentMode = 1 Then
		FillProductionCalendarOnServer();
	Else
		Object.Calendar = PredefinedValue("Catalog.BusinessCalendars.EmptyRef");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIntervals

&AtClient
Procedure IntervalsOnChange(Item)
	
	FormBorderNames();
	
EndProcedure

&AtClient
Procedure IntervalsOnEditEnd(Item, NewRow, CancelEdit)
	
	FormBorderNames();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure FormBorderNames()
	
	Intervals = Object.Intervals;
	NumberOfIntervals_ = Intervals.Count();
	NameOfTimeInterval = NStr("vi = '%LowerBoundOfInterval% và nhiều ngày hơn';
								|ru = '%LowerBoundOfInterval% и более дней';
								|en = '%LowerBoundOfInterval% and more days'; fa = '%LowerBoundOfInterval% and more days';
								|it = '%LowerBoundOfInterval% e più giorni';
								|pl = '%LowerBoundOfInterval% i więcej dni';
								|tr = '%LowerBoundOfInterval% ve daha fazla gün'");
	NameOfIntervalFromTo  = NStr("vi = 'Từ %LowerBoundOfInterval% đến %UpperBoundOfInterval% %DaysOfDays%';
								|ru = 'От %LowerBoundOfInterval% до %UpperBoundOfInterval% %DaysOfDays%';
								|en = '%LowerBoundOfInterval% to %UpperBoundOfInterval% %DaysOfDays%'; fa = '%LowerBoundOfInterval% to %UpperBoundOfInterval% %DaysOfDays%';
								|it = 'Da %LowerBoundOfInterval% a %UpperBoundOfInterval% %DaysOfDays%';
								|pl = 'Od %LowerBoundOfInterval% do %UpperBoundOfInterval% %DaysOfDays%';
								|tr = '%LowerBoundOfInterval%''dan %UpperBoundOfInterval%%DaysOfDays%'");
	UpperBoundOfInterval    = 9999999999;
	
	For CurIndex__ = 1 To NumberOfIntervals_-1 Do
		PreviousStage = Intervals[CurIndex__-1];
		ThisStage = Intervals[CurIndex__];
		If ThisStage.LowerBoundOfInterval = 0 Then
			ThisStage.LowerBoundOfInterval = PreviousStage.LowerBoundOfInterval + 1;
		EndIf;
		While (CurIndex__ - 1 >= 0) And ThisStage.LowerBoundOfInterval < Intervals[CurIndex__-1].LowerBoundOfInterval Do
			Intervals.Move(CurIndex__,-1);
			CurIndex__ = CurIndex__ - 1;
		EndDo;
	EndDo;

	If NumberOfIntervals_ = 1 Then
		
		Intervals[0].LowerBoundOfInterval = 1;
		Intervals[0].UpperBoundOfInterval = UpperBoundOfInterval;
		Intervals[0].IntervalName = StrReplace(NameOfTimeInterval, "%LowerBoundOfInterval%", Intervals[0].LowerBoundOfInterval);
		
	ElsIf NumberOfIntervals_ > 1 Then
		
		Intervals[0].LowerBoundOfInterval = 1;
		
		For CurIndex__ = 1 To NumberOfIntervals_-1 Do
			
			PreviousStage = Intervals[CurIndex__-1];
			
			ThisStage = Intervals[CurIndex__];
			
			If ThisStage.LowerBoundOfInterval = PreviousStage.LowerBoundOfInterval Then
				ThisStage.LowerBoundOfInterval = PreviousStage.LowerBoundOfInterval + 1;
			EndIf;
			
			If CurIndex__ < NumberOfIntervals_ Then
				
				PreviousStage.UpperBoundOfInterval = Intervals[CurIndex__].LowerBoundOfInterval-1;
				NameOfIntervalFromToPresentation = StrReplace(NameOfIntervalFromTo, "%LowerBoundOfInterval%", PreviousStage.LowerBoundOfInterval);
				NameOfIntervalFromToPresentation = StrReplace(NameOfIntervalFromToPresentation, "%UpperBoundOfInterval%", PreviousStage.UpperBoundOfInterval);
				NameOfIntervalFromToPresentation = StrReplace(NameOfIntervalFromToPresentation, "%DaysOfDays%", ?(PreviousStage.UpperBoundOfInterval = 1,NStr("vi = 'ngày';
																																								|ru = 'дня';
																																								|en = 'day'; fa = 'روز';
																																								|it = 'del giorno';
																																								|pl = 'dnia';
																																								|tr = 'gün'"),NStr("vi = 'ngày';
																																												|ru = 'дней';
																																												|en = 'days'; fa = 'روز';
																																												|it = 'di giorni';
																																												|pl = 'dni';
																																												|tr = 'günler'")));
				PreviousStage.IntervalName = NameOfIntervalFromToPresentation;
				
			EndIf;
			
			Intervals[NumberOfIntervals_-1].UpperBoundOfInterval = UpperBoundOfInterval;
			Intervals[NumberOfIntervals_-1].IntervalName = StrReplace(NameOfTimeInterval, "%LowerBoundOfInterval%", Intervals[NumberOfIntervals_-1].LowerBoundOfInterval);
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillProductionCalendarOnServer()
	
	CalendarSchedules.FillBusinessCalendarInForm(ThisForm, "Object.Calendar");
	
EndProcedure

#EndRegion

#EndRegion
