#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = Parameters.Title;
	DelayedBeginningDays = Parameters.Days;
	DelayedBeginningHours = Parameters.Hours1;
	PostponedDate = Parameters.PostponedDate;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DelayedStartDaysOnChange(Item)
	
	PostponedDate = Undefined;
	
EndProcedure

&AtClient
Procedure DelayedStartHoursOnChange(Item)
	
	PostponedDate = Undefined;
	
EndProcedure

&AtClient
Procedure PostponedDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DelayedBeginningDays = 0;
	DelayedBeginningHours = 0;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	If ValueIsFilled(PostponedDate) And PostponedDate <= CurrentSessionDateAtServer() Then
		CommonClient.MessageToUser(
			NStr("vi = 'Ngày được chọn nhỏ hơn ngày hiện tại.
				|Hãy chỉ ra đúng ngày hoãn thực hiện.';
				|ru = 'Выбранная дата меньше текущей.
				|Укажите корректную дату отложенного выполнения.';
				|en = 'The selected date is earlier than the current one.
				|Select the correct deferred execution date.'; fa = 'The selected date is earlier than the current one.
				|Select the correct deferred execution date.';
				|it = 'Выбранная дата меньше текущей.
				|Укажите корректную дату отложенного выполнения.';
				|pl = 'The selected date is earlier than the current one.
				|Select the correct deferred execution date.';
				|tr = 'Seçilen tarih güncel tarihten daha öncedir.
				|Ertelenmiş yürütme için doğru tarihi belirtin.'"),, PostponedDate);
		Return;
	EndIf;
	
	ReturnData = New Structure;
	ReturnData.Insert("Days", DelayedBeginningDays);
	ReturnData.Insert("Hours1", DelayedBeginningHours);
	ReturnData.Insert("PostponedDate", PostponedDate);
	Close(ReturnData);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function CurrentSessionDateAtServer()
	
	Return CurrentSessionDate();
	
EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_PostponedDate" Then
		PostponedDateOnChange(Items.PostponedDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
