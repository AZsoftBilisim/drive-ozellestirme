#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	Use = True;
	Schedule = New ValueStorage(Catalogs.JobsQueueHandlers.DefaultSchedule());
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Auto = False;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CheckForChanges();
	
	Validation = Methods.Unload(, "Method");
	Validation.GroupBy("Method");
	If Validation.Count() <> Methods.Count() Then
		Common.MessageToUser(NStr("vi = 'Đã tìm thấy phần tử trùng lặp của phương thức';
									|ru = 'Обнаружены дубли методов';
									|en = 'Method duplicates are found'; fa = 'Method duplicates are found';
									|it = 'Trovati metodi duplicati';
									|pl = 'Znaleziono zduplikowane metody';
									|tr = 'Yöntem kopyaları tespit edildi'"), , "Methods", , Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CheckForChanges();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CheckForChanges();
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckForChanges()
	
	If Auto Then
		Raise NStr("vi = 'Chỉ có thể soạn tùy chỉnh này trong Bộ quản lý dịch vụ';
					|ru = 'Редактирование этой настройки выполняется только в Менеджере сервиса';
					|en = 'This setting is edited in the Service Manager only'; fa = 'This setting is edited in the Service Manager only';
					|it = 'La modifica di questa impostazione viene eseguita solo nel Service Manager.';
					|pl = 'Edycja tego ustawienia jest wykonywana tylko w Menedżerze serwisu';
					|tr = 'Bu ayar yalnızca Servis Yöneticisi''nde düzenlenir'");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

