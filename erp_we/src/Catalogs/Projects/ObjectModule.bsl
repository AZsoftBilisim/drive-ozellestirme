#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	Completed = False;
	PlannedStartDate = CurrentSessionDate();
	PlannedEndDate = Date(1,1,1);
	StartDate = CurrentSessionDate();
	PlannedEndDate = Date(1,1,1);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Interactions.SetActiveFlag(Ref, (Not Completed) And (Not DeletionMark));
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If ValueIsFilled(PlannedEndDate)
		And PlannedStartDate > PlannedEndDate Then
		
		MessageText = NStr("vi = 'Ngày kết thúc dự kiến ​​không được nhỏ hơn ngày bắt đầu dự kiến.';
							|ru = 'Плановая дата окончания не должна быть меньше плановой даты начала.';
							|en = 'Planned end date cannot be less than planned start date.'; fa = 'Planned end date cannot be less than planned start date.';
							|it = 'La data di fine pianificata non deve essere inferiore la data d''inizio pianificata.';
							|pl = 'Planowana data zakończenia nie może być wcześniejsza od planowanej daty rozpoczęcia.';
							|tr = 'Planlanan bitiş tarihi, planlanan başlangıç ​​tarihinden önce olmamalıdır.'");
		CommonClientServer.MessageToUser(MessageText,
		                                                  ThisObject,
		                                                  "PlannedEndDate",
		                                                  ,
		                                                  Cancel);
		
	EndIf;
	
	If ValueIsFilled(EndDate)
		And StartDate > EndDate Then
		
		MessageText = NStr("vi = 'Ngày kết thúc không được nhỏ hơn ngày bắt đầu.';
							|ru = 'Дата окончания не должна быть меньше даты начала.';
							|en = 'End date cannot be earlier than the start date.'; fa = 'End date cannot be earlier than the start date.';
							|it = 'La data di fine non deve essere inferiore la data d''inizio.';
							|pl = 'Data zakończenia nie może być wcześniejsza od planowanej daty rozpoczęcia.';
							|tr = 'Bitiş tarihi, başlangıç ​​tarihinden önce olmamalıdır.'");
		CommonClientServer.MessageToUser(MessageText,
		                                                  ThisObject,
		                                                  "EndDate",
		                                                  ,
		                                                  Cancel);
		
	EndIf;
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#EndIf