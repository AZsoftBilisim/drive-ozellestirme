////////////////////////////////////////////////////////////////////////////////
// Subsystem "System state audit".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a view of the task schedule for performing checks.
//
// Parameters:
//	Schedule - JobSchedule
//
// Returns:
//	String - presentation of the schedule.
//
Function SchedulePresentation(Schedule) Export
	
	If Schedule = Undefined Or String(Schedule) = String(New JobSchedule) Then
		Result = NStr("vi = 'Lịch biểu chưa được chỉ ra';
						|ru = 'Расписание не задано';
						|en = 'Schedule is not set'; fa = 'Schedule is not set';
						|it = 'Orario non è impostato';
						|pl = 'Harmonogram nie jest zadany';
						|tr = 'Plan ayarlanmadı'");
	Else
		Result = String(Schedule);
	EndIf;
	
	Return	Result;
	
EndFunction

#EndRegion

#Region Private

// Returns the name of the log events to register, used for selection.
//
// Returns:
//	String - Event name
//
Function EventLogEventName() Export
	
	Return NStr("vi = 'Kiểm tra trạng thái hệ thống';
				|ru = 'Аудит состояния системы';
				|en = 'System state audit'; fa = 'ممیزی وضعیت سیستم';
				|it = 'Auidit stato del sistema';
				|pl = 'Audyt statusu systemu';
				|tr = 'Sistem durum denetimi'");
	
EndFunction

#EndRegion
