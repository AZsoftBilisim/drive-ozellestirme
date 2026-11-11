
#Region FormCommandsEventHandlers

&AtClient
Procedure TestConnection(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		
		ShowMessageBox(,NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
							|ru = 'Команда не может быть выполнена для указанного объекта.';
							|en = 'Cannot execute the command for the object.'; fa = 'Cannot execute the command for the object.';
							|it = 'Команда не может быть выполнена для указанного объекта.';
							|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
							|tr = 'Belirtilen nesne için komut gerçekleştirilemez.'"));
		
		Return;
	EndIf;	
		
	FillParameters = New Structure();
	FillParameters.Insert("ServiceSettings", CurrentData.Ref);

	ExchangeWithBankFeedsServiceClient.CheckServiceConnection(FillParameters, ThisObject);	
	
EndProcedure

#EndRegion
