
#Region Public

// The procedure performs the processing of unknown barcodes. Depending on the user's rights, it displays a message
// about unknown barcodes or opens the registration form for new item barcodes.
//
// Parameters:
//  StructureOfActionParameters - See BarcodingOfItemsClientServer.BarcodeProcessingParameters.
//  CachedValues        - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//  OwnerForm               - ClientApplicationForm - The Form is the owner who initiated the event.
//
Procedure ProcessUnknownBarcodes(StructureOfActionParameters, CachedValues, OwnerForm) Export
	
	If StructureOfActionParameters.UnknownBarcodes.Count() > 0 Then
		
		If CachedValues <> Undefined
			And Not ((CachedValues.ProductBarcodeRegistrationRightIsAvailable = True
					Or (StructureOfActionParameters.TransferSpecifiedGoodsToDocument
						And StructureOfActionParameters.ActionsWithUnknownBarcodes <> "RegistrationRequired_"))
				And StructureOfActionParameters.ChangeQuantity) Then
			
			NonUniqueBarcodes = StructureOfActionParameters.NonUniqueBarcodes;
			
			If StructureOfActionParameters.ConsiderPackingLists Then
				TemplateUnknownBarcode = NStr("ru = 'Номенклатура или упаковочный лист со штрихкодом %1 не найдены';
												|vi = 'Items or packing list with barcode %1 are not found';
												|en = 'Items or packing list with barcode %1 are not found'; fa = 'Items or packing list with barcode %1 are not found';
												|it = 'Items or packing list with barcode %1 are not found';
												|pl = 'Items or packing list with barcode %1 are not found';
												|tr = '%1 barkodlu öğe veya paketleme listesi bulunamadı'");
			Else
				TemplateUnknownBarcode = NStr("ru = 'Номенклатура со штрихкодом %1 не найдена';
												|vi = 'Items with barcode %1 are not found';
												|en = 'Items with barcode %1 are not found'; fa = 'Items with barcode %1 are not found';
												|it = 'Items with barcode %1 are not found';
												|pl = 'Items with barcode %1 are not found';
												|tr = '%1 barkodlu öğe bulunamadı'");
			EndIf;
			
			TemplateIsNonUniqueBarcode = NStr("ru = 'Не удалось определить номенклатуру, так как штрихкоду %1 соответствует несколько товаров';
												|vi = 'Cannot identify the item, since several products correspond to barcode %1';
												|en = 'Cannot identify the item, since several products correspond to barcode %1'; fa = 'Cannot identify the item, since several products correspond to barcode %1';
												|it = 'Cannot identify the item, since several products correspond to barcode %1';
												|pl = 'Cannot identify the item, since several products correspond to barcode %1';
												|tr = '%1 barkoduna karşılık gelen birkaç öğe olduğu için öğe belirlenemedi'");
			
			For Each CurUnknownBarcode In StructureOfActionParameters.UnknownBarcodes Do
				Barcode = TrimAll(CurUnknownBarcode.Barcode);
				
				If NonUniqueBarcodes.Get(CurUnknownBarcode.Barcode) <> Undefined Then
					MessageString = StrTemplate(TemplateIsNonUniqueBarcode, Barcode);
				Else
					MessageString = StrTemplate(TemplateUnknownBarcode, Barcode);
				EndIf;
				
				CommonClient.MessageToUser(MessageString);
			EndDo;
			
		Else
			FormName = ?(StructureOfActionParameters.TransferSpecifiedGoodsToDocument,
						"CommonForm.SpecifyItemBarcode",
						"CommonForm.SearchProductsByBarcode");
			
			PerformanceMonitorClient.TimeMeasurement(FormName);
			
			OpenForm(FormName, StructureOfActionParameters, OwnerForm, New UUID);
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure shows the barcode input and notifies you if the input is successful
//
// Parameters:
//  NotificationOfSuccessfulInput - CallbackDescription - description of the successful barcode entry notification
//  Count - Number - the quantity of the product by barcode.
//  Title - String- an overriding title.
//
Procedure ShowBarcodeInput(NotificationOfSuccessfulInput, Count = Undefined, Title = "") Export 
	
	If Not ValueIsFilled(Title) Then
		Title = NStr("vi = 'Hãy nhập mã vạch';
					|ru = 'Введите штрихкод';
					|en = 'Enter barcode'; fa = 'Enter barcode';
					|it = 'Inserire codice a barre';
					|pl = 'Wprowadź kod kreskowy';
					|tr = 'Barkod girin'");
	EndIf;
	
	AdditionalParameters	= New Structure("NotificationOfSuccessfulInput, Count",
												NotificationOfSuccessfulInput, Count);
	CallbackDescription		= New CallbackDescription("ShowBarcodeInputCompletion",
														ThisObject,
														AdditionalParameters);
	
	ShowInputValue(CallbackDescription, "", Title);
	
EndProcedure

// Returns a structure of parameters for processing bar codes.
//
// Returns:
//	See BarcodingOfItemsClientServer.BarcodeProcessingParameters.
//
Function BarcodeProcessingParameters() Export
	
	Return BarcodingOfItemsClientServer.BarcodeProcessingParameters();
	
EndFunction

// Specifies whether to open the series indication form after processing barcodes.
// You need to open the form if you scanned a single barcode of the product that is used for tracking the series.
//
// Parameters:
//  BarcodeProcessingParameters - See BarcodingOfItemsClient.BarcodeProcessingParameters.
//
// Returns:
//  Boolean - True if you need to open the form.
//
Function YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(BarcodeProcessingParameters) Export
	
	OneBarcode = False;
	
	If TypeOf(BarcodeProcessingParameters.Barcodes) = Type("Array") Then
		OneBarcode = BarcodeProcessingParameters.Barcodes.Count() = 1;
	Else
		OneBarcode = True;
	EndIf;
	
	If OneBarcode
		And BarcodeProcessingParameters.ArrayOfRowsWithSeries_.Count() = 1
		And ProductsClientServer.ItIsNecessaryToRegisterSeries(
			BarcodeProcessingParameters.SeriesSpecificationParameters) Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Determines whether to open the form for specifying excise stamps after processing barcodes.
// The form must be opened if only one barcode of the alcohol product being marked has been scanned.
//
// Parameters:
//  BarcodeProcessingParameters - See BarcodingOfItemsClient.BarcodeProcessingParameters.
//
// Returns:
//  Boolean - True if you need to open the form.
//
Function YouNeedToOpenFormForSpecifyingExciseStampsAfterProcessingBarcodes(BarcodeProcessingParameters) Export
	
	OneBarcode = False;
	
	If TypeOf(BarcodeProcessingParameters.Barcodes) = Type("Array") Then
		OneBarcode = BarcodeProcessingParameters.Barcodes.Count() = 1;
	Else
		OneBarcode = True;
	EndIf;
	
	If OneBarcode
		And BarcodeProcessingParameters.ArrayOfRowsWithExciseStamps.Count() = 1 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns a structure that is then processed by PM filling procedures.
//
// Parameters:
//  Barcode - String - the barcode to be processed.
//  Count - Number - the number of products with the specified barcode.
//
// Returns:
//  Structure - structure with properties:
//   * Barcode - String - barcode.
//   * Count - Number - Quantity.
//
Function BarcodeDataStructure(Barcode, Count) Export
	
	Return New Structure("Barcode, Count", Barcode, Count);
	
EndFunction

// Determines whether the transmitted barcodes are valid or not.
// If the barcodes contain invalid characters, the code is considered invalid.
//
// Parameters:
//  Barcodes - Array of Structure, Structure - The data for barcodes.
//  DisplayAlert - Boolean - True, display an alert to the user.
//
// Returns:
//  Boolean - True if the barcodes are valid.
//
Function BarcodesAreValid(Barcodes, DisplayAlert = True) Export

	BarcodesAreValid = True;
	
	If TypeOf(Barcodes) = Type("Array") Then
		ArrayOfBarcodes = Barcodes;
	Else
		ArrayOfBarcodes = New Array;
		ArrayOfBarcodes.Add(Barcodes);
	EndIf;
	
	For Each CurBarcode In ArrayOfBarcodes Do
		#If WebClient Then
			If StrFind(CurBarcode.Barcode, Char(29)) <> 0 Then
				BarcodesAreValid = False;
				Break;
			EndIf;
		#Else
			If XMLStringProcessing.FindDisallowedXMLCharacters(CurBarcode.Barcode) <> 0 Then
				BarcodesAreValid = False;
				Break;
			EndIf;
		#EndIf
	EndDo;
	
	If Not BarcodesAreValid Then
		NotificationText1 = NStr("vi = 'Cần phải đọc mã sản phẩm được dán nhãn trong biểu mẫu kiểm tra và lựa chọn.';
								|ru = 'Коды маркируемой продукции необходимо считывать в форме проверки и подбора.';
								|en = 'The marked products codes must be read in the check and choice form.'; fa = 'The marked products codes must be read in the check and choice form.';
								|it = 'I codici dei prodotti etichettati devono essere letti nel form di verifica e selezione.';
								|pl = 'Kody znakowanej produkcji należy odczytywać w formie weryfikacji i wyboru.';
								|tr = 'Etiketli imal edilen ürünlerin kodları kontrol ve eşleştirme formunda okunmalıdır.'");
		
		ShowUserNotification(
			NStr("vi = 'Lỗi đọc mã vạch';
				|ru = 'Ошибка чтения штрихкода';
				|en = 'Barcode read error'; fa = 'Barcode read error';
				|it = 'Errore di lettura del codice a barre';
				|pl = 'Błąd odczytu kodu kreskowego';
				|tr = 'Barkod okuma hatası'"),
			,
			NotificationText1,
			PictureLib.Warning32);
	EndIf;
	
	Return BarcodesAreValid;

EndFunction

// Fills in condition parameters by item type.
//
// Parameters:
//	StructureOfActions - See BarcodeProcessingParameters.
//	ItemsTypes - ValueList of EnumRef.ItemsTypes,
//						Array Of the Link enumeration.Nomenclature types - data on item types.
//
Procedure DefineConditionsForTypesOfBarcodeProcessingItems(StructureOfActions, ItemsTypes) Export
	
	If TypeOf(ItemsTypes) = Type("ValueList") Then
		ItemTypesArray = ItemsTypes.UnloadValues();
	Else
		ItemTypesArray = ItemsTypes;
	EndIf;
	
	If ItemTypesArray.Find(PredefinedValue("Enum.ItemsTypes.OwnGoods")) <> Undefined Then
		ThereAreWorks = ItemTypesArray.Find(PredefinedValue("Enum.ItemsTypes.Work_5")) <> Undefined;
		ThereAreServices = ItemTypesArray.Find(PredefinedValue("Enum.ItemsTypes.OperationService")) <> Undefined;
		ThereIsPackage   = ItemTypesArray.Find(PredefinedValue("Enum.ItemsTypes.ReusablePackage")) <> Undefined;
		
		StructureOfActions.OnlyGoodsAndWork = ThereAreWorks And Not ThereAreServices;
		StructureOfActions.OnlyGoodsAndServices = Not ThereAreWorks And ThereAreServices;
		StructureOfActions.GoodsOnly        = Not ThereAreWorks And Not ThereAreServices;
		StructureOfActions.AddContainers      = ThereIsPackage
												And StructureOfActions.GoodsOnly;
		StructureOfActions.UseContainersAsGoods = ThereIsPackage
															And StructureOfActions.GoodsOnly;
	Else
		If ItemTypesArray.Find(PredefinedValue("Enum.ItemsTypes.OperationService")) <> Undefined Then
			StructureOfActions.ServicesOnly = True;
		ElsIf ItemTypesArray.Find(PredefinedValue("Enum.ItemsTypes.Work_5")) <> Undefined Then
			StructureOfActions.OnlyWorks = True;
		ElsIf ItemTypesArray.Find(PredefinedValue("Enum.ItemsTypes.ReusablePackage")) <> Undefined Then
			StructureOfActions.OnlyTara   = True;
		EndIf;
	EndIf;
	
EndProcedure

#Region RFID

// Function-server call is required for RFID processing
//
// Parameters:
//  LBLData	 - Array of Structure - placemark data
//  Form		 - ClientApplicationForm - the form from which the function is called.
// 
// Returns:
// Boolean - True if a server call is needed.
//
Function ServerCallIsNeededToHandleRFID(LBLData, Form) Export
	
	ThereIsFilledTID = False;
	For Each Label In LBLData Do
		
		// If the TID was not counted, then the tag reading cannot be considered successful
		If ValueIsFilled(Label.TID) Then
			ThereIsFilledTID = True;
			Break;
		EndIf;
		
	EndDo;
	
	If ThereIsFilledTID Then
		
		RFIDReaderOperationParameters = RFIDReaderOperationParameters();
		RFIDReaderOperationParameters.ChosenAction = "ReadProcessing";
		RFIDReaderOperationParameters.Form = Form;
		CloseRFIDReaderSession(Undefined, RFIDReaderOperationParameters);
			
		Return True;
		
	Else
		
		// If there are no correctly read labels, then we do nothing - we are waiting for more events from the equipment.
		// In the next event, the correct data may already arrive.
		Return False;
		
	EndIf;
	
EndFunction

// Procedure-Open an RFID reader session
//
// Parameters:
//  Form				 - ClientApplicationForm - the form from which the procedure is called
//  NextAction	 - CallbackDescription - description of the next action.
//
Procedure OpenRFIDReaderSession(Form, NextAction = Undefined) Export
	
	RFIDReaderSessionHasBeenOpened      = Form.RFIDReaderSessionHasBeenOpened;
	UUID           = Form.UUID;
	RFIDReaders                   = Form.RFIDReaders;
	
	If Not RFIDReaderSessionHasBeenOpened Then
		RFIDReaderOperationParameters = RFIDReaderOperationParameters();
		
		RFIDReaderOperationParameters.ChosenAction = "OpeningOfSession";
		RFIDReaderOperationParameters.NextAction = NextAction;
		RFIDReaderOperationParameters.Form = Form;
		
		DescriptionCompletionAlert = New CallbackDescription("CompletionOfRFIDReaderOperation", ThisObject, RFIDReaderOperationParameters);
		
		PeripheralsRFIDReaderClient.StartOpeningRFIDReaderSession(
			DescriptionCompletionAlert,
			UUID,
			RFIDReaders);
	EndIf;
	
EndProcedure

// Procedure-Work out the timeout for reading the placemark
//
// Parameters:
//  Form	 - ClientApplicationForm - the form from which the procedure is called.
//
Procedure WorkOutTimeoutWaitingForRFIDReading(Form) Export
	
	MessageText = NStr("vi = 'Đã hết thời gian chờ đọc nhãn RFID. Có thể có các sự cố: nhãn nằm ngoài vùng đọc, nhãn bị hỏng hoặc không sử dụng đọc nhãn xưởng sản xuất trong tùy chỉnh thiết bị.';
						|ru = 'Истекло время ожидания чтения RFID-метки. Возможные проблемы: метка находится вне зоны считывания, метка повреждена или чтение заводской метки в настройках оборудования не включено.';
						|en = 'Timeout of reading RFID tag. Possible issues: the tag is out of the reading range, the tag is corrupted or the factory tag reading is disabled in the equipment settings.'; fa = 'Timeout of reading RFID tag. Possible issues: the tag is out of the reading range, the tag is corrupted or the factory tag reading is disabled in the equipment settings.';
						|it = 'Il tag RFID è scaduto. Possibili problemi: l''etichetta è fuori dall''area di lettura, l''etichetta è danneggiata o la lettura dell''etichetta di fabbrica nelle impostazioni dell''apparecchio non è inclusa.';
						|pl = 'Odczekanie znacznika RFID przekroczyło limit czasu. Możliwe problemy: etykieta jest poza obszarem czytania, etykieta jest uszkodzona lub nie uwzględniono odczytu etykiety fabrycznej w ustawieniach urządzenia.';
						|tr = 'RFID etiketini okumak için bekleme süresi doldu. Olası sorunlar: Etiket okuma alanının dışında, etiket hasarlı veya fabrika etiketinin okunması ekipman ayarlarında etkinleştirilmedi.'");
	CommonClient.MessageToUser(MessageText);
	RFIDReaderOperationParameters = RFIDReaderOperationParameters();
	RFIDReaderOperationParameters.ChosenAction = "ReadWaitingTimeout";
	RFIDReaderOperationParameters.Form = Form;
	CloseRFIDReaderSession(Undefined, RFIDReaderOperationParameters);
	
EndProcedure

// Procedure-Write data to RFID
//
// Parameters:
//  Result	 - Undefined - service parameter for the notification description (not used)
//  Parameters	 - Structure - parameters with series data to record.
//
Procedure WriteDataToTFID(Result, Parameters) Export
	
	Form = Parameters.Form;
	SeriesData = Parameters.SeriesData;
	
	UUID      = Form.UUID;
	RFIDReaders              = Form.RFIDReaders;
	SeriesUseSettings  = Form.SeriesUseSettings;
	RFIDReaderSessionHasBeenOpened = Form.RFIDReaderSessionHasBeenOpened;
	GTIN                         = Form.GTIN;
	
	YouNeedToSaveMark = True;
	
	If SeriesData = Undefined Then
		MessageText = NStr("vi = 'Chọn dòng mà bạn muốn viết nhãn và đặt nhãn tương ứng trên thiết bị.';
							|ru = 'Выберите строку, по которой нужно записать метку и положите соответствующую метку на устройство.';
							|en = 'Select a line for which a tag must be saved and put the relevant tag on the device.'; fa = 'Select a line for which a tag must be saved and put the relevant tag on the device.';
							|it = 'Seleziona la linea su cui vuoi scrivere un''etichetta e inserisci l''etichetta appropriata sul dispositivo.';
							|pl = 'Wybierz linię, na której chcesz napisać etykietę i umieść odpowiednią etykietę na urządzeniu.';
							|tr = 'Etiketi kaydetmek istediğiniz satırı seç ve ilgili etiketi cihaza yerleştir.'");
		ShowMessageBox(,MessageText);
		YouNeedToSaveMark = False;
	ElsIf Not SeriesData.YouNeedToSaveMark Then
		MessageText = NStr("vi = 'Theo dòng hiện tại, không cần ghi đánh dấu.';
							|ru = 'По текущей строке не нужно записывать метку.';
							|en = 'Saving the mark is not required for the current line.'; fa = 'Saving the mark is not required for the current line.';
							|it = 'Sulla riga corrente non è necessario scrivere un''etichetta.';
							|pl = 'W bieżącej linii nie trzeba pisać etykiety.';
							|tr = 'Mevcut satıra etiket kaydetmeye gerek yoktur.'");
		ShowMessageBox(,MessageText);
		YouNeedToSaveMark = False;
	ElsIf SeriesUseSettings.SpecifyNumberWhenRegisteringBatch
		And Not ValueIsFilled(SeriesData.Number) Then
		MessageText = NStr("vi = 'Trước khi ghi đánh dấu, hãy chỉ ra số sê-ri.';
							|ru = 'Перед записью метки, укажите номер серии.';
							|en = 'Specify batch number before saving the mark.'; fa = 'Specify batch number before saving the mark.';
							|it = 'Prima della registrazione dell''etichetta indicare il numero di serie.';
							|pl = 'Przed nagraniem etykiety należy podać numer serii.';
							|tr = 'Etiket kaydı öncesi parti numarasını belirt.'");
		ShowMessageBox(,MessageText);
		YouNeedToSaveMark = False;
	ElsIf SeriesUseSettings.UseShelfLifeOnBatchRegistration
		And Not ValueIsFilled(SeriesData.ValidUntil_) Then
		MessageText = NStr("vi = 'Trước khi ghi đánh dấu, hãy chỉ ra hạn sử dụng.';
							|ru = 'Перед записью метки, укажите срок годности.';
							|en = 'Specify shelf life before saving the mark.'; fa = 'Specify shelf life before saving the mark.';
							|it = 'Prima della registrazione dell''etichetta, indicare la data di scadenza.';
							|pl = 'Przed nagraniem etykiety określ datę wygaśnięcia.';
							|tr = 'Etiket kaydı öncesi, son kullanma tarihini belirt.'");
		ShowMessageBox(,MessageText);
		YouNeedToSaveMark = False;
	EndIf;	
	
	RFIDReaderOperationParameters = RFIDReaderOperationParameters();
	RFIDReaderOperationParameters.Form = Form;
	If Not YouNeedToSaveMark Then
		If RFIDReaderSessionHasBeenOpened Then
			CloseRFIDReaderSession(Undefined, RFIDReaderOperationParameters);
		EndIf;
		Return;
	EndIf;
	
	If Not RFIDReaderSessionHasBeenOpened Then
		
		CurrentAction1 = New CallbackDescription("WriteDataToTFID", ThisObject,
			New Structure("Form,SeriesData",Form,SeriesData));
		OpenRFIDReaderSession(Form, CurrentAction1);
		Return;
		
	EndIf;
	
	OperationParametersList = PeripheralsRFIDReaderClient.RFIDTagRecordingParameters();
		OperationParametersList.TID = SeriesData.RFIDTID;
		OperationParametersList.EPC = SeriesData.RFIDEPC;
		OperationParametersList.Data = EquipmentManagerClientServer.GenerateSGTIN96Data(GTIN, SeriesData.Number, 1);
		OperationParametersList.MemoryBank = "EPC";
	
	RFIDReaderOperationParameters.ChosenAction = "RFIDRecording";
	RFIDReaderOperationParameters.NextAction = New CallbackDescription("WriteDataToTFIDCompletion",
		ThisObject,New Structure("Form,SeriesData",Form,SeriesData));
	
	DescriptionCompletionAlert = New CallbackDescription("CompletionOfRFIDReaderOperation", ThisObject, RFIDReaderOperationParameters);
	
	PeripheralsRFIDReaderClient.StartRecordingDataToRFIDTag(
		DescriptionCompletionAlert,
		UUID,
		RFIDReaders,
		OperationParametersList);
EndProcedure

// Procedure-Write data to RFID Completion
//
// Parameters:
//  Result	 - Structure - with properties:
//  	*Result - Boolean - indicates whether the previous operation was completed successfully
//  Parameters	 - Structure - with properties:
//  	*SeriesData - Structure - with series data in properties.
//
Procedure WriteDataToTFIDCompletion(Result, Parameters) Export
	
	SeriesData = Parameters.SeriesData;
	
	RFIDReaderOperationParameters = RFIDReaderOperationParameters();
	RFIDReaderOperationParameters.Form = Parameters.Form;
	CloseRFIDReaderSession(Undefined, RFIDReaderOperationParameters);
	
	If Result.Result Then
		SeriesData.RFIDEPC = EquipmentManagerClientServer.GenerateSGTIN96Data(Parameters.Form.GTIN, SeriesData.Number, 1);
		Notify("RFID_SeriesRecording", SeriesData);
	EndIf;
	
EndProcedure

// Procedure - Unplug the equipment
//
// Parameters:
//  Result	 - Undefined - not used (service parameter)
//  Parameters	 - Structure - Contains Properties:
//		*Form - ClientApplicationForm - the form from which the hardware shutdown was initiated.
//
Procedure DisableHardware(Result, Parameters) Export
	
	Form = Parameters.Form;
	
	If Not Form.RFIDReaderSessionHasBeenOpened Then
		EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, Form);
	Else
		RFIDReaderOperationParameters = RFIDReaderOperationParameters();
		RFIDReaderOperationParameters.Form = Form;
		RFIDReaderOperationParameters.NextAction = New CallbackDescription("DisableHardware", ThisObject, New Structure("Form",Form));
		
		CloseRFIDReaderSession(Undefined, RFIDReaderOperationParameters);
	EndIf;	
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure ShowBarcodeInputCompletion(Barcode, AdditionalParameters) Export
	
	NotificationOfSuccessfulInput	= AdditionalParameters.NotificationOfSuccessfulInput;
	Count					= AdditionalParameters.Count;
	
	If Barcode <> Undefined Then
		If Not IsBlankString(Barcode) Then
			If Count = Undefined Then
				Count = 1;
			EndIf;
			
			If StrLen(Barcode) > 200 Then
				MessageText = NStr("vi = 'Mã vạch không được vượt quá 200 ký tự.';
									|ru = 'Длина штрихкода не должна быть больше 200 символов.';
									|en = 'The barcode length must not exceed 200 symbols.'; fa = 'The barcode length must not exceed 200 symbols.';
									|it = 'Lunghezza del codice a barre non deve superare 200 caratteri.';
									|pl = 'Długość kodu kreskowego nie powinna zawierać ponad 200 symboli.';
									|tr = 'Barkod 200 karakterden uzun olmamalıdır.'");
				
				CommonClient.MessageToUser(MessageText);
				
				Return;
			EndIf;
			
			RunCallback(NotificationOfSuccessfulInput, BarcodeDataStructure(Barcode, Count));
		EndIf;
	EndIf;
	
EndProcedure

Procedure CloseRFIDReaderSession(Result, RFIDReaderOperationParameters)
	
	RFIDReaders = RFIDReaderOperationParameters.Form.RFIDReaders;
	UUID = RFIDReaderOperationParameters.Form.UUID;
	
	NewRFIDReaderOperationParameters = RFIDReaderOperationParameters();
	NewRFIDReaderOperationParameters.ChosenAction = "ClosingOfSession";
	
	NewRFIDReaderOperationParameters.Form = RFIDReaderOperationParameters.Form;
	If RFIDReaderOperationParameters.NextAction <> Undefined Then
		NewRFIDReaderOperationParameters.ChosenAction = "ClosingOfSession";
		NewRFIDReaderOperationParameters.NextAction   = RFIDReaderOperationParameters.NextAction;
	EndIf;
	
	DescriptionCompletionAlert = New CallbackDescription("CompletionOfRFIDReaderOperation", ThisObject, NewRFIDReaderOperationParameters);
	
	PeripheralsRFIDReaderClient.StartClosingRFIDReaderSession(
		DescriptionCompletionAlert,
		UUID,
		RFIDReaders);

EndProcedure

Procedure CompletionOfRFIDReaderOperation(ExecutionResult, RFIDReaderOperationParameters) Export

	If Not ExecutionResult.Result Then
		MessageText = NStr("vi = 'Đã hoàn tất thao tác đọc RFID với lỗi:""%ErrorDescription%""';
							|ru = 'Операция считывателя RFID завершилась с ошибкой:""%ErrorDescription%""';
							|en = 'RFID reader operation is completed with error:""%ErrorDescription%""'; fa = 'RFID reader operation is completed with error:""%ErrorDescription%""';
							|it = 'Operazione del lettore RFID fallita:""%ErrorDescription%""';
							|pl = 'Działanie czytnika RFID nie powiodło się z błędem: ""%ErrorDescription%""';
							|tr = 'RFID okuyucu işlemi aşağıdaki hata ile sona erdi:""%ErrorDescription%""'");
		MessageText = StrReplace(MessageText, "%ErrorDescription%" , ExecutionResult.ErrorDescription);
		CommonClient.MessageToUser(MessageText);
		RFIDReaderOperationParameters.Form.RFIDRecordingIsUnderway = False;
	ElsIf RFIDReaderOperationParameters.ChosenAction = "OpeningOfSession" Then
		RFIDReaderOperationParameters.Form.RFIDReaderSessionHasBeenOpened = True;
	ElsIf RFIDReaderOperationParameters.ChosenAction = "ClosingOfSession" Then
		RFIDReaderOperationParameters.Form.RFIDReaderSessionHasBeenOpened = False;
		RFIDReaderOperationParameters.Form.RFIDRecordingIsUnderway = False;
	EndIf;

	If RFIDReaderOperationParameters.NextAction <> Undefined Then
		RunCallback(RFIDReaderOperationParameters.NextAction, ExecutionResult);
	EndIf;
	
EndProcedure

Function RFIDReaderOperationParameters()
	
	Result = New Structure;
	Result.Insert("ChosenAction", "");
	Result.Insert("NextAction");
	Result.Insert("Form");
	
	Return Result;
	
EndFunction

#EndRegion
