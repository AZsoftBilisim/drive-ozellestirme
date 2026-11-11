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
			ShowMessageBox(, NStr("vi = 'Hãy kiểm tra giá trị đã nhập: số bên trái nhỏ hơn số bên phải.';
									|ru = 'Проверьте введенные значения: левое число меньше правого.';
									|en = 'Verify the input: left number is less than the right number.'; fa = 'Verify the input: left number is less than the right number.';
									|it = 'Verificare inserimento valore: numero sinistro inferiore al destro.';
									|pl = 'Sprawdź wprowadzone wartości: lewa liczba jest mniejsza niż prawa.';
									|tr = 'Girilen değerleri kontrol et: soldaki sayı sağdakinden küçük.'"));
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