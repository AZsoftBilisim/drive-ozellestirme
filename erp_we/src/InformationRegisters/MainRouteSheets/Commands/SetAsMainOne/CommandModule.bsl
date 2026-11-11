
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ErrorStructure = New Structure;
	If Not ProductDataManagementServerCall.YouCanAssignRouteMapToMainOne(CommandParameter, ErrorStructure) Then
		ShowMessageBox(,ErrorStructure.ErrorText,, NStr("vi = 'Đặt làm bản đồ tuyến chính';
														|ru = 'Назначить основной маршрутной картой';
														|en = 'Set as main route sheet'; fa = 'تعیین به‌عنوان برگه مسیر اصلی';
														|it = 'Nominare il foglio di lavorazione principale';
														|pl = 'Przypisać przez podstawową kartę technologiczną';
														|tr = 'Temel rota olarak ata'"));
		Return;
	EndIf;
	
	FormParameters = New Structure("RouteSheet", CommandParameter);
	
	OpenForm("InformationRegister.MainRouteSheets.Form.SetAsMainOne", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion