
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	TemplateData = Parameters.TemplateData;
	
EndProcedure

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
Function CodeCorrespondsToMKPattern(TrackData, TemplateData)
	
	OneTrackIsPresent = False;
	CheckPassed = True;
	
	For Iterator_SSLy = 1 To 3 Do
		If TemplateData["TrackAvailability"+String(Iterator_SSLy)] Then
			OneTrackIsPresent = True;
			CurRow = TrackData[Iterator_SSLy - 1];
			If Right(CurRow, StrLen(TemplateData["Suffix" + String(Iterator_SSLy)])) <> TemplateData["Suffix" + String(Iterator_SSLy)] Then
				CommonCELClient.MessageToUser(NStr("vi = 'Đường dẫn';
													|ru = 'Дорожка';
													|en = 'Track'; fa = 'Track';
													|it = 'Traccia';
													|pl = 'Track';
													|tr = 'Parça'") + Chars.NBSp + String(Iterator_SSLy) 
					+ ". "+NStr("vi = 'Hậu tố của thẻ không tương ứng với hậu tố của khuôn mẫu.';
								|ru = 'Суффикс карты не соответствует суффиксу шаблона.';
								|en = 'Card suffix does not correspond to the template suffix.'; fa = 'Card suffix does not correspond to the template suffix.';
								|it = 'Il suffisso della carta non corrisponde al suffisso del modello.';
								|pl = 'Sufiks karty nie jest zgodny z sufiksem szablonu.';
								|tr = 'Kart eki, şablon ekine uygun değil.'"));
				CheckPassed = False;
			EndIf;
			
			If Left(CurRow, StrLen(TemplateData["Prefix" + String(Iterator_SSLy)])) <> TemplateData["Prefix" + String(Iterator_SSLy)] Then
				CommonCELClient.MessageToUser(NStr("vi = 'Đường dẫn';
													|ru = 'Дорожка';
													|en = 'Track'; fa = 'Track';
													|it = 'Traccia';
													|pl = 'Track';
													|tr = 'Parça'") + Chars.NBSp + String(Iterator_SSLy) 
					+ ". " + NStr("vi = 'Tiền tố của thẻ không tương ứng với tiền tố khuôn mẫu.';
									|ru = 'Префикс карты не соответствует префиксу шаблона.';
									|en = 'Card prefix does not correspond to the template prefix.'; fa = 'Card prefix does not correspond to the template prefix.';
									|it = 'Il prefisso della carta non corrisponde al prefisso del modello.';
									|pl = 'Prefiks karty nie jest zgodny z prefiksem szablonu.';
									|tr = 'Kart öneki, şablon önekine uygun değil.'"));
				CheckPassed = False;
			EndIf;
			
			If Find(CurRow, TemplateData["BlockSeparator"+String(Iterator_SSLy)]) = 0 Then
				CommonCELClient.MessageToUser(NStr("vi = 'Đường dẫn';
													|ru = 'Дорожка';
													|en = 'Track'; fa = 'Track';
													|it = 'Traccia';
													|pl = 'Track';
													|tr = 'Parça'") + Chars.NBSp + String(Iterator_SSLy) 
					+ ". "+NStr("vi = 'Đường chia tách khối thẻ không tương ứng với đường chia tách khối khuôn mẫu.';
								|ru = 'Разделитель блоков карты не соответствует разделителю блоков шаблона.';
								|en = 'Card block separator does not correspond to template block separator.'; fa = 'Card block separator does not correspond to template block separator.';
								|it = 'Il separatore del blocco della carta non corrisponde al separatore del blocco del modello.';
								|pl = 'Separator bloków karty nie jest zgodny z separatorem bloków szablonu.';
								|tr = 'Kart blok ayırıcı, şablon bloğu ayırıcısına karşılık gelmez.'"));
				CheckPassed = False;
			EndIf;
				
			If StrLen(CurRow) <> TemplateData["CodeLength"+String(Iterator_SSLy)] Then
				CommonCELClient.MessageToUser(NStr("vi = 'Đường dẫn';
													|ru = 'Дорожка';
													|en = 'Track'; fa = 'Track';
													|it = 'Traccia';
													|pl = 'Track';
													|tr = 'Parça'") + Chars.NBSp + String(Iterator_SSLy) 
					+ ". " + NStr("vi = 'Chiều dài của mã thẻ không tương ứng với chiều dài của mã khuôn mẫu.';
									|ru = 'Длина кода карты не соответствует длине кода шаблона.';
									|en = 'Card code length does not correspond to the template code length.'; fa = 'Card code length does not correspond to the template code length.';
									|it = 'La lunghezza del codice della carta non corrisponde alla lunghezza del codice del modello.';
									|pl = 'Długość kodu karty nie odpowiada długości kodu szablonu.';
									|tr = 'Kart kod uzunluğu, şablon kod uzunluğuna uygun değil.'"));
				CheckPassed = False;
			EndIf;
			
			If Not CheckPassed Then
				Return False;
			EndIf;
		EndIf;
	EndDo;
	
	If OneTrackIsPresent Then 
		Return True;
	Else
		CommonCELClient.MessageToUser(NStr("vi = 'Trong khuôn mẫu chưa chỉ ra bất kỳ một đường dẫn hợp lệ nào.';
											|ru = 'В шаблоне не указано ни одной доступной дорожки.';
											|en = 'No available track is specified in the template.'; fa = 'No available track is specified in the template.';
											|it = 'Nel modello non è indicata alcuna traccia disponibile.';
											|pl = 'W szablonie nie wskazano ani jednej dostępnej ścieżki.';
											|tr = 'Şablonda uygun parça belirtilmemiş.'"));
		Return False;
	EndIf;
	
EndFunction

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "TracksData" Then
			TrackData = Parameter.TrackData;
			
			ClearMessages();
			If Not CodeCorrespondsToMKPattern(TrackData, TemplateData) Then
				CommonCELClient.MessageToUser(NStr("vi = 'Thẻ không tương ứng với khuôn in.';
													|ru = 'Карта не соответствует шаблону.';
													|en = 'The card does not match template.'; fa = 'The card does not match template.';
													|it = 'La carta non corrisponde al modello.';
													|pl = 'Karta nie odpowiada szablonowi.';
													|tr = 'Kart numune ile eşleşmiyor.'"));
				Return;
			EndIf;
			
			// Output encrypted fields
			If Parameter.TemplateList = Undefined Or Parameter.TemplateList.Count() = 0 Then
				CommonCELClient.MessageToUser(NStr("vi = 'Không thể nhận biết bất kỳ trường nào. Có thể là, đã tùy chỉnh sai các trường trong khuôn mẫu.';
													|ru = 'Не удалось распознать ни одного поля. Возможно, поля шаблона настроены неверно.';
													|en = 'Failed to identify any field. Maybe, template fields configured incorrectly.'; fa = 'Failed to identify any field. Maybe, template fields configured incorrectly.';
													|it = 'Impossibile riconoscere alcun campo. I campi del modello potrebbero non essere configurati correttamente.';
													|pl = 'Nie udało się rozpoznać ani jednego pola. Możliwe, że pola szablonu zostały ustawione niepoprawnie.';
													|tr = 'Herhangi bir alan belirlenemedi. Şablon alanları yanlış yapılandırılmış olabilir.'"));
			Else
				TemplateFound = Undefined;
				For Each CurPattern In Parameter.TemplateList Do
					If CurPattern.Template = TemplateData.Ref Then
						TemplateFound = CurPattern;
					EndIf;
				EndDo;
				If TemplateFound = Undefined Then
					CommonCELClient.MessageToUser(NStr("vi = 'Mã không tương ứng với khuôn mẫu này. Có thể là, đã tùy chỉnh sai khuôn mẫu.';
														|ru = 'Код не соответствует данному шаблону. Возможно, шаблон настроен неверно.';
														|en = 'The code does not match this template. Maybe, the template is configured incorrectly.'; fa = 'The code does not match this template. Maybe, the template is configured incorrectly.';
														|it = 'Il codice non corrisponde a questo modello. Il modello potrebbe essere configurato in modo errato.';
														|pl = 'Kod nie odpowiada danemu szablonowi. Być może szablon został ustawiony nieprawidłowo.';
														|tr = 'Kod bu şablonla eşleşmiyor. Şablon yanlış yapılandırılmış olabilir.'"));
				Else
					MessageText = NStr("vi = 'Thẻ tương ứng với khuôn mẫu và có các trường sau:';
										|ru = 'Карта соответствует шаблону и содержит следующие поля:';
										|en = 'The card matches the template and contains the following fields:'; fa = 'The card matches the template and contains the following fields:';
										|it = 'La carta corrisponde allo schema e contiene i seguenti campi:';
										|pl = 'Karta nie odpowiada szablonowi i zawiera następujące pola:';
										|tr = 'Kart, şablonla eşleşti ve aşağıdaki alanları içerir:'") + Chars.LF + Chars.LF;
					Iterator_SSLy = 1;
					For Each CurField In TemplateFound.TrackData Do
						MessageText = MessageText + String(Iterator_SSLy)+". "+?(ValueIsFilled(CurField.Field), String(CurField.Field), "")+" = " + String(CurField.Simple)+Chars.LF;
						Iterator_SSLy = Iterator_SSLy + 1;
					EndDo;
					ShowMessageBox(,MessageText, , NStr("vi = 'Kết quả diễn giải mã thẻ';
														|ru = 'Результат расшифровки кода карты';
														|en = 'Card code analysis result'; fa = 'Card code analysis result';
														|it = 'Risultato della decodifica del codice della carta';
														|pl = 'Wynik rozszyfrowania kodu karty';
														|tr = 'Kart kodu şifre çözme sonucu'"));
				EndIf;
			EndIf;
			
		EndIf;
	EndIf;
	// End Peripherals
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