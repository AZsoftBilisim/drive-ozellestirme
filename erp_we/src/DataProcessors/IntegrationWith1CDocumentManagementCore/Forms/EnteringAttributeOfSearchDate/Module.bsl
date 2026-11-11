#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = Parameters.Title;
	Value = Parameters.Value;
	ComparisonType = ?(ValueIsFilled(Parameters.ComparisonOperator), Parameters.ComparisonOperator, ">=");
	If ValueIsFilled(Parameters.ComparisonOperator2) Then
		ComparisonType = "Between_";
		Value2 = Parameters.Value2;
	EndIf;
	
	If ComparisonType <> "="
			And ComparisonType <> ">="
			And ComparisonType <> "<="
			And ComparisonType <> "Between_" Then
		ComparisonType = "=";
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetVisibility1();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ComparisonTypeOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ExecuteSelection(False);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure ToSearch(Command)
	
	ExecuteSelection(True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetVisibility1()
	
	Items.ValueIs.Visible = (ComparisonType = "=");
	Items.ValueFrom_2.Visible = (ComparisonType = ">=");
	Items.ValueTo.Visible = (ComparisonType = "<=");
	Items.GroupBetween.Visible = (ComparisonType = "Between_");
	
EndProcedure

&AtClient
Procedure ExecuteSelection(FindImmediately)
	
	Result = New Structure;
	Result.Insert("Value", Value);
	If ComparisonType = "Between_" Then
		If Value2 < Value Then
			ShowMessageBox(, NStr("vi = 'Hãy kiểm tra giá trị đã nhập: ngày bên trái muộn hơn ngày bên phải.';
									|ru = 'Проверьте введенные значения: левая дата позже правой.';
									|en = 'Verify the input: left date is greater than the right date.'; fa = 'Verify the input: left date is greater than the right date.';
									|it = 'Verificare l''inserimento del valore: data sinistra successiva alla destra.';
									|pl = 'Sprawdź wprowadzone wartości: lewa data jest późniejsza od prawej.';
									|tr = 'Girilen değerleri kontrol et: soldaki tarih sağdakinden geç.'"));
			Return;
		EndIf;
		Result.Insert("ComparisonOperator", ">=");
		Result.Insert("Value2", Value2);
		Result.Insert("ComparisonOperator2", "<=");
	Else
		Result.Insert("ComparisonOperator", ComparisonType);
		Result.Insert("ComparisonOperator2", "");
	EndIf;
	Result.Insert("FindImmediately", FindImmediately);
	Close(Result);
	
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
