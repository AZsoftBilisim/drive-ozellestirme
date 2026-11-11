#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ThisAppointment = Parameters.ThisAppointment;
	If ThisAppointment Then
		Title = NStr("vi = 'Chỉ định vai trò';
					|ru = 'Назначить роли';
					|en = 'Assign roles'; fa = 'تعیین نقش‌ها';
					|it = 'Assegnare ruoli';
					|pl = 'Przydziel role';
					|tr = 'Roller atamak'");
		Items.Apply.Title = NStr("vi = 'Chỉ định vai trò';
								|ru = 'Назначить роли';
								|en = 'Assign roles'; fa = 'تعیین نقش‌ها';
								|it = 'Assegnare ruoli';
								|pl = 'Przydziel role';
								|tr = 'Roller atamak'");
	Else
		Title = NStr("vi = 'Xóa vai trò';
					|ru = 'Снять роли';
					|en = 'Clear roles'; fa = 'پاک کردن نقش‌ها';
					|it = 'Rimuovere ruoli';
					|pl = 'Usuń role';
					|tr = 'Rolleri kaldır'");
		Items.Apply.Title = NStr("vi = 'Xóa vai trò';
								|ru = 'Снять роли';
								|en = 'Clear roles'; fa = 'پاک کردن نقش‌ها';
								|it = 'Rimuovere ruoli';
								|pl = 'Usuń role';
								|tr = 'Rolleri kaldır'");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)

	ReturnStructure = New Structure();
	ReturnStructure.Insert("Picker",   Picker);
	ReturnStructure.Insert("Courier",    Courier);
	ReturnStructure.Insert("Dispatcher", Dispatcher);
	
	Close(ReturnStructure);
	
EndProcedure

#EndRegion
