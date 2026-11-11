
#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	If CommonCELClient.MagneticCardTemplatesAreUsed() Then

		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.MagneticStripeCardReaders = True;
	
		OnboardingAlerts = New CallbackDescription("ConnectEquipmentCompletion", ThisObject);    
		EquipmentManagerClient.StartConnectingEquipmentByType(OnboardingAlerts, UUID, SupportedTypes);    
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConnectEquipmentCompletion(ExecutionResult, Var_Parameters) Export
	
	If Not ExecutionResult.Result Then
		MessageText = NStr( "vi = 'Khi kết nối thiết bị, đã xảy ra lỗi:
				|""%ErrorDescription%"".';
				|ru = 'При подключении оборудования произошла ошибка:
				|""%ErrorDescription%"".';
				|en = 'An error occurred when connecting the equipment:
				|""%ErrorDescription%"".'; fa = 'An error occurred when connecting the equipment:
				|""%ErrorDescription%"".';
				|it = 'Si è verificato un errore durante il collegamento dell''apparecchiatura:
				|""%ErrorDescription%"".';
				|pl = 'Przy podłączeniu sprzętu zaistniał błąd:
				|""%ErrorDescription%"".';
				|tr = 'Ekipman bağlanırken hata oluştu:
				|""%ErrorDescription%"".'" );
		MessageText = StrReplace(MessageText, "%ErrorDescription%" , ExecutionResult.ErrorDescription);
		CommonCELClient.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If CommonCELClient.MagneticCardTemplatesAreUsed() Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.MagneticStripeCardReaders = True;
	
		EquipmentManagerClient.StartEquipmentDisablingByType(Undefined, UUID, SupportedTypes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "TracksData" Then
			// Opening matching templates.
			ClearMessages();
			If Parameter.TemplateList = Undefined Or Parameter.TemplateList.Count() = 0 Then
				CommonCELClient.MessageToUser(NStr("vi = 'Không thể đọc các trường. Có thể là đã tùy chỉnh sai khuôn mẫu.';
													|ru = 'Не удалось прочитать поля. Возможно, шаблон настроен неверно.';
													|en = 'Cannot read the fields. The template might be set up incorrectly.'; fa = 'Cannot read the fields. The template might be set up incorrectly.';
													|it = 'Non è stato possibile leggere i campi. Forse il modello è impostato in modo errato.';
													|pl = 'Nie udało się wczytać pól. Możliwe, że szablon jest ustawiony nieprawidłowo.';
													|tr = 'Alanlar okunamadı. Şablon yanlış yapılandırılmış olabilir.'"));
			Else
				TemplateFound = False;
				For Each CurPattern In Parameter.TemplateList Do
					TemplateFound = True;
					OpenForm("Catalog.MagneticStripeCardTemplates.ObjectForm", New Structure("Key", CurPattern.Template));
				EndDo;
				If Not TemplateFound Then
					CommonCELClient.MessageToUser(NStr("vi = 'Mã không tương ứng với khuôn mẫu này. Có thể là, đã tùy chỉnh sai khuôn mẫu.';
														|ru = 'Код не соответствует данному шаблону. Возможно, шаблон настроен неверно.';
														|en = 'The code does not match this template. Maybe, the template is configured incorrectly.'; fa = 'The code does not match this template. Maybe, the template is configured incorrectly.';
														|it = 'Il codice non corrisponde a questo modello. Il modello potrebbe essere configurato in modo errato.';
														|pl = 'Kod nie odpowiada danemu szablonowi. Być może szablon został ustawiony nieprawidłowo.';
														|tr = 'Kod bu şablonla eşleşmiyor. Şablon yanlış yapılandırılmış olabilir.'"));
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalEvent(Source, Event, Data)
	
	If IsInputAvailable() Then
		
		EventDescription1 = New Structure();
		ErrorDescription  = "";
		EventDescription1.Insert("Source", Source);
		EventDescription1.Insert("Event",  Event);
		EventDescription1.Insert("Data",   Data);
		
		ProcessingResult = EquipmentManagerClient.GetEventFromDevice(EventDescription1, ErrorDescription);
		If ProcessingResult = Undefined Then 
			MessageText = NStr("vi = 'Khi xử lý sự kiện ngoài từ thiết bị, đã xảy ra lỗi:';
								|ru = 'При обработке внешнего события от устройства произошла ошибка:';
								|en = 'An error occurred when processing an external event from the device:'; fa = 'An error occurred when processing an external event from the device:';
								|it = 'Si è verificato un errore durante l''elaborazione di un evento esterno al dispositivo:';
								|pl = 'Przy przetwarzaniu zdarzenia zewnętrznego od urządzenia zaistniał błąd:';
								|tr = 'Harici olayın cihazdan işlenmesi sırasında bir hata oluştu:'") + Chars.LF + ErrorDescription;
			CommonCELClient.MessageToUser(MessageText);
		Else
			NotificationProcessing(ProcessingResult.Event, ProcessingResult.Data, "Peripherals");
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
