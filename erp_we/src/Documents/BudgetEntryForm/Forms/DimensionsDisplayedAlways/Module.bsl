#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	DimensionsDisplayedAlways = Parameters.DimensionsDisplayedAlways;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	If DimensionsDisplayedAlways.Count() > MaximumNumberOfAnalysts Then
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Có thể chọn nhiều nhất %1 chỉ số';
				|ru = 'Максимально можно выбрать %1 аналитик';
				|en = 'You can select not more than %1 dimensions'; fa = 'You can select not more than %1 dimensions';
				|it = 'Si possono selezionare al massimo %1 analitiche';
				|pl = 'Maksymalnie można wybrać %1 analityk';
				|tr = 'Maksimum seçilebilir %1 boyut'"), 
			MaximumNumberOfAnalysts);
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	Total = DimensionsDisplayedAlways.Count();
	For Cnt = 1 To Total Do
		ListItem = DimensionsDisplayedAlways[Total - Cnt];
		If Not ValueIsFilled(ListItem.Value) Then
			DimensionsDisplayedAlways.Delete(ListItem);
		EndIf;
	EndDo;
	
	Close(DimensionsDisplayedAlways);
	
EndProcedure

#EndRegion