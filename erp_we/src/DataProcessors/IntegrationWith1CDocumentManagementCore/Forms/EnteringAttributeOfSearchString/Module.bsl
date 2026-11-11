#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = Parameters.Title;
	Value = Parameters.Value;
	ComparisonType = ?(ValueIsFilled(Parameters.ComparisonOperator), Parameters.ComparisonOperator, "%LIKE%");
	If Left(Value, 1) = "%" Then
		ComparisonType = "%LIKE%";
		Value = Mid(Value, 2);
	EndIf;
	If Right(Value, 1) = "%" Then
		ComparisonType = "%LIKE%";
		Value = Left(Value, StrLen(Value) - 1);
	EndIf;
	
	If ComparisonType <> "="
			And ComparisonType <> "%LIKE%"
			And ComparisonType <> "LIKE%"
			And ComparisonType <> "%LIKE" Then
		ComparisonType = "%LIKE%";
	EndIf;
	
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
Procedure ExecuteSelection(FindImmediately)
	
	Result = New Structure("ComparisonOperator", "LIKE");
	If ComparisonType = "=" Then
		Result.Insert("Value", Value);
		Result.Insert("ComparisonOperator", "=");
	ElsIf ComparisonType = "%LIKE%" Then
		Result.Insert("Value", "%" + Value + "%");
	ElsIf ComparisonType = "%LIKE" Then
		Result.Insert("Value", "%" + Value);
	ElsIf ComparisonType = "LIKE%" Then
		Result.Insert("Value", Value + "%");
	EndIf;
	Result.Insert("FindImmediately", FindImmediately);
	Close(Result);
	
EndProcedure

#EndRegion