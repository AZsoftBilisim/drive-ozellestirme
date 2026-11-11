
#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	If Parameters.Key = Undefined Or Parameters.Key.IsEmpty() Then
		Object.BlockSeparator1 = "^";
		Object.BlockSeparator2 = "=";
		Object.BlockSeparator3 = "=";
		
		Object.CodeLength1 = 79;
		Object.CodeLength2 = 40;
		Object.CodeLength3 = 107;
		
		Object.Prefix1 = "%";
		Object.Prefix2 = ";";
		Object.Prefix3 = ";";
		
		Object.Suffix1 = "?";
		Object.Suffix2 = "?";
		Object.Suffix3 = "?";
		
		Object.TrackAvailability1 = True;
		Object.TrackAvailability2 = True;
		Object.TrackAvailability3 = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
	SupportedTypes.MagneticStripeCardReaders = True;
	
	OnboardingAlerts = New CallbackDescription("ConnectEquipmentCompletion", ThisObject);    
	EquipmentManagerClient.StartConnectingEquipmentByType(OnboardingAlerts, UUID, SupportedTypes);
	// End Peripherals
	
	SetTrackAvailability();
	
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
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "TracksData" Then
			// Output the read data
			If EquipmentManagerClient.InputDevicesEventNewFormat() Then
				Track1 = Parameter.TrackData[0];
				Track2 = Parameter.TrackData[1];
				Track3 = Parameter.TrackData[2];
			Else
				TrackData = Parameter[1][1];
				Track1 = TrackData[0];
				Track2 = TrackData[1];
				Track3 = TrackData[2];
			EndIf;
			Object.CodeLength1 = StrLen(Track1);
			Object.CodeLength2 = StrLen(Track2);
			Object.CodeLength3 = StrLen(Track3);
			Object.TrackAvailability1 = Not (StrLen(Track1) = 0);
			Object.TrackAvailability2 = Not (StrLen(Track2) = 0);
			Object.TrackAvailability3 = Not (StrLen(Track3) = 0);
			SetTrackAvailability();
			Modified = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	// Peripherals
	SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
	SupportedTypes.MagneticStripeCardReaders = True;     
	
	EquipmentManagerClient.StartEquipmentDisablingByType(Undefined, UUID, SupportedTypes);
	// End Peripherals
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// Checking for the presence of fields
	ClearMessages();
	FieldCounter = 0;
	If Object.TrackAvailability1 Then
		FieldCounter = FieldCounter + Object.TrackFields1.Count();
	EndIf;
	If Object.TrackAvailability2 Then
		FieldCounter = FieldCounter + Object.TrackFields2.Count();
	EndIf;
	If Object.TrackAvailability3 Then
		FieldCounter = FieldCounter + Object.TrackFields3.Count();
	EndIf;
	If FieldCounter = 0 Then
		CommonCELClient.MessageToUser(NStr("vi = 'Không thêm bất kỳ trường nào vào một trong các đường dẫn hợp lệ.';
											|ru = 'Не добавлено ни одного поля ни в одной из доступных дорожек.';
											|en = 'Not a single field was not added to the any of available tracks.'; fa = 'Not a single field was not added to the any of available tracks.';
											|it = 'Nessun campo aggiunto in nessuna delle tracce disponibili.';
											|pl = 'Nie dodano ani jednego pola w ani jednej z dostępnych ścieżek.';
											|tr = 'Mevcut parçalardan hiçbirine tek bir alan eklenmedi.'"), , , , Cancel);
	EndIf;
	
	FieldUniquenessControl(Cancel);
	
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
								|tr = 'Harici olayın cihazdan işlenmesi sırasında bir hata oluştu:'")
								+ Chars.LF + ErrorDescription;
			CommonCELClient.MessageToUser(MessageText);
		Else
			NotificationProcessing(ProcessingResult.EventName, ProcessingResult.Parameter, "Peripherals");
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TakeThePrefix1(Command)
	If StrLen(Items.Track1.SelectedText) > 0 Then
		Object.Prefix1 = Items.Track1.SelectedText;
	Else
		ClearMessages();
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn đoạn mã bằng chuột.';
											|ru = 'Выделите мышкой участок кода.';
											|en = 'Use mouse to select the part of the code.'; fa = 'Use mouse to select the part of the code.';
											|it = 'Selezionate l''area del codice con il mouse.';
											|pl = 'Zaznacz myszką obszar kodu.';
											|tr = 'Kodun bir bölümünü seçmek için imleci kullanın.'"));
	EndIf;
EndProcedure

&AtClient
Procedure TakeThePrefix2(Command)
	If StrLen(Items.Track2.SelectedText) > 0 Then
		Object.Prefix2 = Items.Track2.SelectedText;
	Else
		ClearMessages();
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn đoạn mã bằng chuột.';
											|ru = 'Выделите мышкой участок кода.';
											|en = 'Use mouse to select the part of the code.'; fa = 'Use mouse to select the part of the code.';
											|it = 'Selezionate l''area del codice con il mouse.';
											|pl = 'Zaznacz myszką obszar kodu.';
											|tr = 'Kodun bir bölümünü seçmek için imleci kullanın.'"));
	EndIf;
EndProcedure

&AtClient
Procedure TakeThePrefix3(Command)
	If StrLen(Items.Track3.SelectedText) > 0 Then
		Object.Prefix3 = Items.Track3.SelectedText;
	Else
		ClearMessages();
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn đoạn mã bằng chuột.';
											|ru = 'Выделите мышкой участок кода.';
											|en = 'Use mouse to select the part of the code.'; fa = 'Use mouse to select the part of the code.';
											|it = 'Selezionate l''area del codice con il mouse.';
											|pl = 'Zaznacz myszką obszar kodu.';
											|tr = 'Kodun bir bölümünü seçmek için imleci kullanın.'"));
	EndIf;
EndProcedure

&AtClient
Procedure TakeTheSuffix1(Command)
	If StrLen(Items.Track1.SelectedText) > 0 Then
		Object.Suffix1 = Items.Track1.SelectedText;
	Else
		ClearMessages();
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn đoạn mã bằng chuột.';
											|ru = 'Выделите мышкой участок кода.';
											|en = 'Use mouse to select the part of the code.'; fa = 'Use mouse to select the part of the code.';
											|it = 'Selezionate l''area del codice con il mouse.';
											|pl = 'Zaznacz myszką obszar kodu.';
											|tr = 'Kodun bir bölümünü seçmek için imleci kullanın.'"));
	EndIf;
EndProcedure

&AtClient
Procedure TakeTheSuffix2(Command)
	If StrLen(Items.Track2.SelectedText) > 0 Then
		Object.Suffix2 = Items.Track2.SelectedText;
	Else
		ClearMessages();
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn đoạn mã bằng chuột.';
											|ru = 'Выделите мышкой участок кода.';
											|en = 'Use mouse to select the part of the code.'; fa = 'Use mouse to select the part of the code.';
											|it = 'Selezionate l''area del codice con il mouse.';
											|pl = 'Zaznacz myszką obszar kodu.';
											|tr = 'Kodun bir bölümünü seçmek için imleci kullanın.'"));
	EndIf;
EndProcedure

&AtClient
Procedure TakeTheSuffix3(Command)
	If StrLen(Items.Track3.SelectedText) > 0 Then
		Object.Suffix3 = Items.Track3.SelectedText;
	Else
		ClearMessages();
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn đoạn mã bằng chuột.';
											|ru = 'Выделите мышкой участок кода.';
											|en = 'Use mouse to select the part of the code.'; fa = 'Use mouse to select the part of the code.';
											|it = 'Selezionate l''area del codice con il mouse.';
											|pl = 'Zaznacz myszką obszar kodu.';
											|tr = 'Kodun bir bölümünü seçmek için imleci kullanın.'"));
	EndIf;
EndProcedure

&AtClient
Procedure TakeTheSeparator1(Command)
	If StrLen(Items.Track1.SelectedText) > 0 Then
		Object.BlockSeparator1 = Items.Track1.SelectedText;
	Else
		ClearMessages();
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn đoạn mã bằng chuột.';
											|ru = 'Выделите мышкой участок кода.';
											|en = 'Use mouse to select the part of the code.'; fa = 'Use mouse to select the part of the code.';
											|it = 'Selezionate l''area del codice con il mouse.';
											|pl = 'Zaznacz myszką obszar kodu.';
											|tr = 'Kodun bir bölümünü seçmek için imleci kullanın.'"));
	EndIf;
EndProcedure

&AtClient
Procedure TakeTheSeparator2(Command)
	If StrLen(Items.Track2.SelectedText) > 0 Then
		Object.BlockSeparator2 = Items.Track2.SelectedText;
	Else
		ClearMessages();
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn đoạn mã bằng chuột.';
											|ru = 'Выделите мышкой участок кода.';
											|en = 'Use mouse to select the part of the code.'; fa = 'Use mouse to select the part of the code.';
											|it = 'Selezionate l''area del codice con il mouse.';
											|pl = 'Zaznacz myszką obszar kodu.';
											|tr = 'Kodun bir bölümünü seçmek için imleci kullanın.'"));
	EndIf;
EndProcedure

&AtClient
Procedure TakeTheSeparator3(Command)
	If StrLen(Items.Track3.SelectedText) > 0 Then
		Object.BlockSeparator3 = Items.Track3.SelectedText;
	Else
		ClearMessages();
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn đoạn mã bằng chuột.';
											|ru = 'Выделите мышкой участок кода.';
											|en = 'Use mouse to select the part of the code.'; fa = 'Use mouse to select the part of the code.';
											|it = 'Selezionate l''area del codice con il mouse.';
											|pl = 'Zaznacz myszką obszar kodu.';
											|tr = 'Kodun bir bölümünü seçmek için imleci kullanın.'"));
	EndIf;
EndProcedure

&AtClient
Procedure TakeField1Completion(Result, Var_Parameters) Export
	
	Items.TrackFields1.AddRow();
	NewField = Items.TrackFields1.CurrentData;
	NewField.BlockNumber = Result.BlockNumber;
	NewField.NumberOfFirstCharacter = Result.NumberOfFirstCharacter;
	NewField.FieldLength = Result.FieldLength;
	NewField.Field = PredefinedValue("Enum.MagneticStripeCardTemplateFields.Code");
	Items.TrackFields1.EndEditRow(False);
	
EndProcedure  

&AtClient
Procedure TakeField1(Command)
	
	Var NStr, NCount, ToRow, KKol;
	
	ClearMessages();
		
	If StrLen(Items.Track1.SelectedText) = 0 Then
		ClearMessages();
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn đoạn mã bằng chuột.';
											|ru = 'Выделите мышкой участок кода.';
											|en = 'Use mouse to select the part of the code.'; fa = 'Use mouse to select the part of the code.';
											|it = 'Selezionate l''area del codice con il mouse.';
											|pl = 'Zaznacz myszką obszar kodu.';
											|tr = 'Kodun bir bölümünü seçmek için imleci kullanın.'"));
		Return;
	EndIf;
	
	Notification = New CallbackDescription("TakeField1Completion", ThisObject, );

	Items.Track1.GetTextSelectionBounds(NStr, NCount, ToRow, KKol);
	
	DefineFieldCoordinates(Notification, Track1, Object.Prefix1, Object.Suffix1, Object.BlockSeparator1, NCount, KKol);
	
EndProcedure

&AtClient
Procedure TakeField2Completion(Result, Var_Parameters) Export
	
	Items.TrackFields2.AddRow();
	NewField = Items.TrackFields2.CurrentData;
	NewField.BlockNumber = Result.BlockNumber;
	NewField.NumberOfFirstCharacter = Result.NumberOfFirstCharacter;
	NewField.FieldLength = Result.FieldLength;
	NewField.Field = PredefinedValue("Enum.MagneticStripeCardTemplateFields.Code");
	Items.TrackFields2.EndEditRow(False);
	
EndProcedure  

&AtClient
Procedure TakeField2(Command)
	
	Var NStr, NCount, ToRow, KKol;
	
	ClearMessages();
	
	If StrLen(Items.Track2.SelectedText) = 0 Then
		ClearMessages();
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn đoạn mã bằng chuột.';
											|ru = 'Выделите мышкой участок кода.';
											|en = 'Use mouse to select the part of the code.'; fa = 'Use mouse to select the part of the code.';
											|it = 'Selezionate l''area del codice con il mouse.';
											|pl = 'Zaznacz myszką obszar kodu.';
											|tr = 'Kodun bir bölümünü seçmek için imleci kullanın.'"));
		Return;
	EndIf;
	
	Notification = New CallbackDescription("TakeField2Completion", ThisObject, Parameters);

	Items.Track2.GetTextSelectionBounds(NStr, NCount, ToRow, KKol);
	
	DefineFieldCoordinates(Notification, Track2, Object.Prefix2, Object.Suffix2, Object.BlockSeparator2, NCount, KKol);
	
EndProcedure

&AtClient
Procedure TakeField3Completion(Result, Var_Parameters) Export
	
	Items.TrackFields3.AddRow();
	NewField = Items.TrackFields3.CurrentData;
	NewField.BlockNumber = Result.BlockNumber;
	NewField.NumberOfFirstCharacter = Result.NumberOfFirstCharacter;
	NewField.FieldLength = Result.FieldLength;
	NewField.Field = PredefinedValue("Enum.MagneticStripeCardTemplateFields.Code");
	Items.TrackFields3.EndEditRow(False);
	
EndProcedure  

&AtClient
Procedure TakeField3(Command)
	
	Var NStr, NCount, ToRow, KKol;
	
	ClearMessages();
	
	If StrLen(Items.Track3.SelectedText) = 0 Then
		ClearMessages();
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn đoạn mã bằng chuột.';
											|ru = 'Выделите мышкой участок кода.';
											|en = 'Use mouse to select the part of the code.'; fa = 'Use mouse to select the part of the code.';
											|it = 'Selezionate l''area del codice con il mouse.';
											|pl = 'Zaznacz myszką obszar kodu.';
											|tr = 'Kodun bir bölümünü seçmek için imleci kullanın.'"));
		Return;
	EndIf;
	
	Notification = New CallbackDescription("TakeField3Completion", ThisObject, );

	Items.Track3.GetTextSelectionBounds(NStr, NCount, ToRow, KKol);
	
	DefineFieldCoordinates(Notification, Track3, Object.Prefix3, Object.Suffix3, Object.BlockSeparator3, NCount, KKol);
	//
EndProcedure

&AtClient
Procedure DefineFieldCoordinatesCompletion(Result, Context) Export
	
	If Result.Value = DialogReturnCode.No Then
		Context.Result.FieldLength = 0;
	EndIf;
	
	If Context <> Undefined And Context.NextAlert <> Undefined Then
		RunCallback(Context.NextAlert, Context.Result);
	EndIf;
	
EndProcedure
   
// Defines the coordinates of the field based on the selected section of the track code.
//
&AtClient
Procedure DefineFieldCoordinates(Notification, TrackData_, Prefix, Suffix, Separator, NCount, KKol)
	
	DataString_ = TrackData_;
	If Not IsBlankString(Prefix)
		And Prefix = Left(DataString_, StrLen(Prefix)) Then
		DataString_ = Right(DataString_, StrLen(DataString_)-StrLen(Prefix)); // we cut off the prefix if there is
		NCount = NCount - StrLen(Prefix);
		KKol = KKol - StrLen(Prefix);
		If NCount < 1 Then
			// The selected text climbs on the prefix.
			CommonCELClient.MessageToUser(NStr("vi = 'Đoạn mã được chọn không được giao nhau với hậu tố, tiền tố hoặc đường chia tách của các khối.';
												|ru = 'Выделенный участок кода не должен пересекаться с суффиксом, префиксом или разделителем блоков.';
												|en = 'Selected part of the code should not overlap the suffix, prefix or block separator.'; fa = 'Selected part of the code should not overlap the suffix, prefix or block separator.';
												|it = 'L''area di codice selezionato non deve intersecarsi con un suffisso, prefisso o delimitatore di blocchi.';
												|pl = 'Zaznaczony obszar kodu nie może pokrywać się z sufiksem, prefiksem lub separatorem bloków.';
												|tr = 'Kodun seçilen kısmı, sonek, önek veya blok ayırıcı ile çakışmamalıdır.'"));
			Return;
		EndIf;
	EndIf;
	
	If Not IsBlankString(Suffix)
		And Suffix = Right(DataString_, StrLen(Suffix)) Then
		DataString_ = Left(DataString_, StrLen(DataString_)-StrLen(Suffix)); // we cut off the suffix if there is
		If KKol-1 > StrLen(DataString_) Then
			// The selected text climbs on the suffix.
			CommonCELClient.MessageToUser(NStr("vi = 'Đoạn mã được chọn không được giao nhau với hậu tố, tiền tố hoặc đường chia tách của các khối.';
												|ru = 'Выделенный участок кода не должен пересекаться с суффиксом, префиксом или разделителем блоков.';
												|en = 'Selected part of the code should not overlap the suffix, prefix or block separator.'; fa = 'Selected part of the code should not overlap the suffix, prefix or block separator.';
												|it = 'L''area di codice selezionato non deve intersecarsi con un suffisso, prefisso o delimitatore di blocchi.';
												|pl = 'Zaznaczony obszar kodu nie może pokrywać się z sufiksem, prefiksem lub separatorem bloków.';
												|tr = 'Kodun seçilen kısmı, sonek, önek veya blok ayırıcı ile çakışmamalıdır.'"));
			Return;
		EndIf;
	EndIf;
	
	SeparatorFound = Find(Mid(DataString_, NCount, KKol-NCount), Separator);
	If Not IsBlankString(Separator) And SeparatorFound > 0 Then
		// The selected text intersects with the separator.
		CommonCELClient.MessageToUser(NStr("vi = 'Đoạn mã được chọn không được giao nhau với hậu tố, tiền tố hoặc đường chia tách của các khối.';
											|ru = 'Выделенный участок кода не должен пересекаться с суффиксом, префиксом или разделителем блоков.';
											|en = 'Selected part of the code should not overlap the suffix, prefix or block separator.'; fa = 'Selected part of the code should not overlap the suffix, prefix or block separator.';
											|it = 'L''area di codice selezionato non deve intersecarsi con un suffisso, prefisso o delimitatore di blocchi.';
											|pl = 'Zaznaczony obszar kodu nie może pokrywać się z sufiksem, prefiksem lub separatorem bloków.';
											|tr = 'Kodun seçilen kısmı, sonek, önek veya blok ayırıcı ile çakışmamalıdır.'"));
		Return;
	EndIf;
	
	BlockNumber = 1;
	NumberOfFirstCharacter = 1;
	FieldLength = 1;
	
	While StrLen(DataString_) > 0 Do
		SeparatorPosition = Find(DataString_, Separator);
		If SeparatorPosition > NCount Then
			NumberOfFirstCharacter = NCount;
			FieldLength = ?(KKol > SeparatorPosition, SeparatorPosition - NCount, KKol - NCount);
			Break;
		EndIf;
		
		If SeparatorPosition = 0 Or IsBlankString(Separator) Then
			NumberOfFirstCharacter = NCount;
			FieldLength = KKol - NCount;
			Break;
		ElsIf SeparatorPosition = 1 Then
			// The selected text intersects with the separator.
			CommonCELClient.MessageToUser(NStr("vi = 'Đoạn mã được chọn không được giao nhau với hậu tố, tiền tố hoặc đường chia tách của các khối.';
												|ru = 'Выделенный участок кода не должен пересекаться с суффиксом, префиксом или разделителем блоков.';
												|en = 'Selected part of the code should not overlap the suffix, prefix or block separator.'; fa = 'Selected part of the code should not overlap the suffix, prefix or block separator.';
												|it = 'L''area di codice selezionato non deve intersecarsi con un suffisso, prefisso o delimitatore di blocchi.';
												|pl = 'Zaznaczony obszar kodu nie może pokrywać się z sufiksem, prefiksem lub separatorem bloków.';
												|tr = 'Kodun seçilen kısmı, sonek, önek veya blok ayırıcı ile çakışmamalıdır.'"));
			Return;
		Else
			DataString_ = Right(DataString_, StrLen(DataString_)-SeparatorPosition);
			NCount = NCount - SeparatorPosition;
			KKol = KKol - SeparatorPosition;
		EndIf;
		BlockNumber = BlockNumber + 1;
	EndDo;
	
	If KKol = StrLen(DataString_)+1
		Or Mid(DataString_, KKol, 1) = Separator Then
		
		Result = New Structure("BlockNumber, NumberOfFirstCharacter, FieldLength", BlockNumber, NumberOfFirstCharacter, FieldLength);
		
		Context = New Structure;
		Context.Insert("NextAlert", Notification);
		Context.Insert("Result", Result);
		NextAlert = New CallbackDescription("DefineFieldCoordinatesCompletion", ThisObject, Context);
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Chiều dài trường là cố định';
													|ru = 'Длина поля фиксированная';
													|en = 'Field length fixed'; fa = 'Field length fixed';
													|it = 'La lunghezza del campo è fissa';
													|pl = 'Długość pola jest stała';
													|tr = 'Alan uzunluğu sabit'"));
		ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Chiều dài của trường bị giới hạn bởi đường chia tách hoặc kết thúc xâu ký tự';
													|ru = 'Длина поля ограничивается разделителем или концом строки';
													|en = 'Field length is limited by the separator or by the row end'; fa = 'Field length is limited by the separator or by the row end';
													|it = 'La lunghezza del campo è limitata dal delimitatore o dalla fine della riga';
													|pl = 'Długość pola jest ograniczona separatorem lub końcem wiersza';
													|tr = 'Alan uzunluğu ayırıcı veya satır sonu ile sınırlıdır'"));
		ShowChooseFromMenu(NextAlert, ButtonsList, );
		Return;
		
	EndIf;
	
	Result = New Structure("BlockNumber, NumberOfFirstCharacter, FieldLength", BlockNumber, NumberOfFirstCharacter, FieldLength);
	RunCallback(Notification, Result);
	
EndProcedure

&AtClient
Procedure FieldUniquenessControl(Cancel)
	
	ListOfTakes = New Array;
	For TimeIndex = 1 To 3 Do
		If Object["TrackAvailability"+String(TimeIndex)] Then
			For Each CurRow In Object["TrackFields"+String(TimeIndex)] Do
				FieldUniquenessControl_(ListOfTakes, CurRow.Field, CurRow.LineNumber, "TrackFields"+String(TimeIndex), Cancel);
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure FieldUniquenessControl_(ListOfTakes, Field, CurrentRowNumber, TableName, Cancel)
	If ValueIsFilled(Field) Then
		If ListOfTakes.Find(Field) = Undefined Then
			DoubleCounter = 0;
			For TimeIndex = 1 To 3 Do
				If Not Object["TrackAvailability"+String(TimeIndex)] Then
					Continue;
				EndIf;
				
				For Each CurField In Object["TrackFields"+String(TimeIndex)] Do
					If CurField.Field = Field Then
						DoubleCounter = DoubleCounter + 1;
						If DoubleCounter > 1 Then
							RowMessage = NStr("vi = 'Đường dẫn %1, dòng %2: Trường phải đơn trị.';
												|ru = 'Дорожка %1, строка %2: Поле должно быть уникальным.';
												|en = 'Track %1, line %2: The field must be unique.'; fa = 'Track %1, line %2: The field must be unique.';
												|it = 'Traccia %1, riga %2: Il campo deve essere unico.';
												|pl = 'Ścieżka %1, wiersz %2: Pole musi być unikalne.';
												|tr = '%1parçası, %2 satırı: Alan benzersiz olmalıdır.'");
							RowMessage = StrReplace(RowMessage, "%1", Right("TrackFields"+String(TimeIndex),1));
							RowMessage = StrReplace(RowMessage, "%2", String(CurField.LineNumber));
							CommonCELClient.MessageToUser(RowMessage
								, ,"Object."+"TrackFields"+String(TimeIndex)+"["+String(CurField.LineNumber-1)+"].Field", , Cancel);
						EndIf;
					EndIf;
				EndDo;
			EndDo;
			If DoubleCounter > 1 Then
				ListOfTakes.Add(Field);
			EndIf;
		EndIf;
		
	Else
		RowMessage = NStr("vi = 'Đường dẫn %1, dòng %2: Trường không thể trống.';
							|ru = 'Дорожка %1, строка %2: Поле не может быть пустым.';
							|en = 'Track %1, line %2: The field is required.'; fa = 'Track %1, line %2: The field is required.';
							|it = 'Traccia %1, riga %2: Il campo non può essere vuoto.';
							|pl = 'Ścieżka %1, wiersz %2: Pole nie może być puste.';
							|tr = '%1parçası, %2 satırı: Alan boş olamaz.'");
		RowMessage = StrReplace(RowMessage, "%1", Right(TableName,1));
		RowMessage = StrReplace(RowMessage, "%2", String(CurrentRowNumber));
		CommonCELClient.MessageToUser(RowMessage
			, ,"Object."+TableName+"["+String(CurrentRowNumber-1)+"].Field", , Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckTemplateFilling()
	
	TemplateData = New Structure();
	TemplateData.Insert("TrackAvailability1", Object.TrackAvailability1);
	TemplateData.Insert("TrackAvailability2", Object.TrackAvailability2);
	TemplateData.Insert("TrackAvailability3", Object.TrackAvailability3);
	TemplateData.Insert("Prefix1",   Object.Prefix1);
	TemplateData.Insert("Prefix2",   Object.Prefix2);
	TemplateData.Insert("Prefix3",   Object.Prefix3);
	TemplateData.Insert("CodeLength1", Object.CodeLength1);
	TemplateData.Insert("CodeLength2", Object.CodeLength2);
	TemplateData.Insert("CodeLength3", Object.CodeLength3);
	TemplateData.Insert("Suffix1",   Object.Suffix1);
	TemplateData.Insert("Suffix2",   Object.Suffix2);
	TemplateData.Insert("Suffix3",   Object.Suffix3);
	TemplateData.Insert("BlockSeparator1", Object.BlockSeparator1);
	TemplateData.Insert("BlockSeparator2", Object.BlockSeparator2);
	TemplateData.Insert("BlockSeparator3", Object.BlockSeparator3);
	TemplateData.Insert("Ref", Object.Ref);
	
	OpenForm("Catalog.MagneticStripeCardTemplates.Form.TemplateCheckForm"
		, New Structure("TemplateData", TemplateData), ThisObject, ,,,, FormWindowOpeningMode.LockWholeInterface);      
	
EndProcedure

&AtClient
Procedure CheckTemplateFillingCompletion(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		If Not ThisObject.Write() Then
			CommonCELClient.MessageToUser(NStr("vi = 'Không thể ghi lại khuôn mẫu';
												|ru = 'Не удалось записать шаблон';
												|en = 'Failed to record template'; fa = 'Failed to record template';
												|it = 'Non è stato possibile registrare il modello';
												|pl = 'Zapisywanie szablonu nie powiodło się';
												|tr = 'Şablon yazılamıyor'"));
			Return;
		EndIf;
		
		CheckTemplateFilling();
		
	EndIf;  
	
EndProcedure  

&AtClient
Procedure CheckTheTemplateCommand(Command)
	
	// We check the form for modification.
	// In order for the template changes to take effect, they must be recorded.
	If ThisObject.Modified Then
		QueryText = NStr("vi = 'Khuôn mẫu đã thay đổi, ghi lại thay đổi?';
						|ru = 'Шаблон был изменен, записать изменения?';
						|en = 'Template was changed, record changes?'; fa = 'Template was changed, record changes?';
						|it = 'Il modello è stato modificato, salvare i cambiamenti?';
						|pl = 'Szblon został zmieniony, zapisać zmiany?';
						|tr = 'Şablon değiştirildi. Değişiklikler kaydedilsin mi?'");
		Notification = New CallbackDescription("CheckTemplateFillingCompletion", ThisObject);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	Else
		CheckTemplateFilling();
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

// Sets the availability of track fields depending on the position of the corresponding flag.
&AtClient
Procedure TrackAvailability1OnChange(Item)
	
	SetTrackAvailability();
	
EndProcedure

&AtClient
Procedure TrackAvailability2OnChange(Item)
	
	SetTrackAvailability();
	
EndProcedure

&AtClient
Procedure TrackAvailability3OnChange(Item)
	
	SetTrackAvailability();
	
EndProcedure

&AtClient
Procedure SetTrackAvailability()
	
	For TimeIndex = 1 To 3 Do
		TrackAvailability = Object["TrackAvailability"+String(TimeIndex)];
		Items["Prefix"+String(TimeIndex)].Enabled 			= TrackAvailability;
		Items["CodeLength"+String(TimeIndex)].Enabled 		= TrackAvailability;
		Items["Suffix"+String(TimeIndex)].Enabled 			= TrackAvailability;
		Items["BlockSeparator"+String(TimeIndex)].Enabled = TrackAvailability;
		Items["TrackFields"+String(TimeIndex)].Enabled 		= TrackAvailability;
	EndDo;
	
EndProcedure

#EndRegion
