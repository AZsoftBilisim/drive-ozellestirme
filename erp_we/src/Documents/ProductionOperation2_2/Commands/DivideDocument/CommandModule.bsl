
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If Not ValueIsFilled(CommandParameter)Then
		ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn.';
								|ru = 'Команда не может быть выполнена для выбранной строки.';
								|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
								|it = 'Il comando non può essere eseguito per la riga selezionata.';
								|pl = 'Polecenie nie może być wykonane dla wybranego wiersza';
								|tr = 'Seçili satır için komut gerçekleştirilemez.'"));
		Return;
	EndIf;
	
	UID = CommandExecuteParameters.Source.UUID;
	BlockData_(CommandParameter, UID);
	
	OpenForm(
		"Document.ProductionOperation2_2.Form.DocumentDivision",
		New Structure("Ref", CommandParameter),
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,
		,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure BlockData_(Ref, UID)
	
	LockDataForEdit(Ref,, UID);	
	
EndProcedure

#EndRegion
