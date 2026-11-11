
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.ValueType = Type("String") Then
		
		ThisForm.Title = NStr("vi = 'Hãy đặt giá trị lọc';
								|ru = 'Установите значение отбора';
								|en = 'Set filter value'; fa = 'تعیین مقدار فیلتر';
								|it = 'Impostate il valore della selezione';
								|pl = 'Ustaw wartość wyboru';
								|tr = 'Filtre değerini ayarla'");
		Items.FilterTypesPages.CurrentPage = Items.PageLineEntry;
		SelectionValueString = Parameters.FilterValue;
		
		Items.SelectionValueString.ChoiceList.Clear();
		For Each ListItem In Parameters.ListOfSelectionLines Do
			Items.SelectionValueString.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	Else
		
		ThisForm.Title = NStr("vi = 'Hãy đặt khoảng giá trị lọc';
								|ru = 'Установите интервал значений отбора';
								|en = 'Set filter value interval'; fa = 'Set filter value interval';
								|it = 'Impostate l''intervallo dei valori della selezione';
								|pl = 'Ustaw interwał wartości wyboru';
								|tr = 'Filtre aralık değerini ayarla'");
		Items.FilterTypesPages.CurrentPage = Items.PageIntervalEntry;
		
		If Parameters.ValueType = Type("Date") Then
			Items.IntervalTypesPages.CurrentPage = Items.DateTypePage;
			ValueDateFrom   = Parameters.ValueFrom_2;
			ValueDateBefore   = Parameters.ValueUpTo;
			DateValueType  = True;
		Else
			Items.IntervalTypesPages.CurrentPage = Items.NumberTypePage;
			ValueNumberFrom   = Parameters.ValueFrom_2;
			ValueNumberUpTo   = Parameters.ValueUpTo;
		EndIf;
		
	EndIf;
	
	AttributeName = Parameters.AttributeName;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	IncorrectInterval = False;
	
	If Items.FilterTypesPages.CurrentPage = Items.PageIntervalEntry Then
		
		ReturnStructure = New Structure("IntervalFrom, IntervalTo");
		
		If DateValueType Then
			ReturnStructure.IntervalFrom = ValueDateFrom;
			ReturnStructure.IntervalTo = ValueDateBefore;
			
			IncorrectInterval = (ValueDateFrom > ValueDateBefore);
		Else
			ReturnStructure.IntervalFrom = ValueNumberFrom;
			ReturnStructure.IntervalTo = ValueNumberUpTo;
			
			IncorrectInterval = (ValueNumberFrom > ValueNumberUpTo);
		EndIf;
		
	Else
		ReturnStructure = New Structure("FilterValue", SelectionValueString);
	EndIf;
	
	If IncorrectInterval Then
		ShowMessageBox(Undefined, NStr("vi = 'Đã chỉ định sai khoảng giá trị!';
										|ru = 'Указан неверный диапазон значений!';
										|en = 'Invalid value range.'; fa = 'Invalid value range.';
										|it = 'È specificato un intervallo di valori non valido!';
										|pl = 'Wskazano nieprawidłowy zakres wartości!';
										|tr = 'Geçersiz değer aralığı belirtildi!'"));
		Return;
	EndIf;
	
	Close(ReturnStructure);
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	TMCommonUseClient.EditPeriod(ThisForm, New Structure("StartDate, EndDate", "ValueDateFrom", "ValueDateBefore"));
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

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
