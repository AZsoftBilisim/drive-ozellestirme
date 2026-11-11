#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	If ValueIsFilled(ExecutionResult) Then
		Close(ExecutionResult);
	Else
		Items.ExecutionResult.AutoMarkIncomplete = True;
		ClearMessages();
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Ghi chú""';
				|ru = 'Поле ""Комментарий"" не заполнено';
				|en = 'The field ""Comment"" is required'; fa = 'The field ""Comment"" is required';
				|it = 'Campo ""Commento"" non compilato';
				|pl = 'Pole ""Uwagi"" nie jest wypełnione';
				|tr = '""Yorum"" alanı doldurulmadı'"),,
			"ExecutionResult");
	EndIf;
	
EndProcedure

#EndRegion