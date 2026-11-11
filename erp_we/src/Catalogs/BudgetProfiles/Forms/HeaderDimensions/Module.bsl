
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If IsTempStorageURL(Parameters.AddressOfTheAnalyticsList) Then
		HeaderDimensions = GetFromTempStorage(Parameters.AddressOfTheAnalyticsList);
		List.LoadValues(HeaderDimensions.UnloadColumn("DimensionKind"));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	Result = CommonClientServer.CollapseArray(List.UnloadValues());
	If Result.Count() > MaximumNumberOfAnalysts Then
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Số lượng đối tượng phân tích không thể vượt quá %1';
				|ru = 'Количество аналитик не может превышать %1';
				|en = 'Quantity of dimensions cannot exceed %1'; fa = 'Quantity of dimensions cannot exceed %1';
				|it = 'Il numero di analitiche non può essere superiore a%1';
				|pl = 'Ilość analityk nie może przekraczać %1';
				|tr = 'Tutar boyutu %1 değerini geçemez'"),
			MaximumNumberOfAnalysts);
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	Close(Result);
	
EndProcedure

#EndRegion