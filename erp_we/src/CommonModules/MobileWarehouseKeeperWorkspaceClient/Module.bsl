#Region Public
  
// This procedure allows you to set a period using the standard period selection dialog
//
// Parameters:
//  Object                - Arbitrary - The object which establishes the values of the period
//  PeriodParameters_      - Structure - structure properties "Datacache", "Datacentre" and in the values field names
//                              object for the property "Version" - value variant of the standard period.
//  NotificationAfterSelection - CallbackDescription - Description of the notification that is executed after the period is set. 
//                              Post-processing can be set at the call location after the period is selected.
//
Procedure EditPeriod(Object, PeriodParameters_ = Undefined, NotificationAfterSelection = Undefined) Export
	
	Dialog = New StandardPeriodEditDialog();
	Dialog.Period.StartDate = Object[PeriodParameters_.StartDate];
	Dialog.Period.EndDate = Object[PeriodParameters_.EndDate];  
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",           Object);
	AdditionalParameters.Insert("PeriodParameters_", PeriodParameters_);
	AdditionalParameters.Insert("NotificationAfterSelection", NotificationAfterSelection); 
	
	Notification = New CallbackDescription(
		"EditPeriodCompletion", 
		ThisObject, 
		AdditionalParameters);
	
	Dialog.Show(Notification);

EndProcedure

// The End procedure for editing the period()
// for more information, see the procedure for editing the period.
// Parameters:
//  Period                  - StandardPeriod
//  AdditionalParameters - Structure - structure with properties:
//     Object - Arbitrary - The object in which the period values are set
//     Period parameters - Structure - structure with the properties "Datachal", "End date" and in the values the names
//                              of the object fields containing the start date and end date of the period.
//     NotificatiOnselEction - Description of the announcement - Description of the notification that is performed after setting the period. 
//                              Post-processing can be set at the call location after the period is selected.
//
Procedure EditPeriodCompletion(Period, AdditionalParameters) Export 

	PeriodParameters_ = AdditionalParameters.PeriodParameters_; // Structure
	Object           = AdditionalParameters.Object;
	
	If Period <> Undefined Then
		Object[PeriodParameters_.StartDate]= Period.StartDate;
		Object[PeriodParameters_.EndDate]= Period.EndDate;
	EndIf;
	
	RunCallback(AdditionalParameters.NotificationAfterSelection, Period);
	
EndProcedure

// See CommonClient.MessageToUser
// 
Procedure MessageToUser(Val MessageToUserText,	Val DataKey = Undefined,
	Val Field = "", Val DataPath = "", Cancel = False) Export
	
	Message = CommonInternalClientServer.UserMessage(MessageToUserText,
		DataKey, Field, DataPath, Cancel);
	
	Message.Message()
	
EndProcedure

// See EquipmentManagerTMClient.ThereIsRawEvent
// The function checks whether all events of the connected equipment have been processed
//
// Returns:
//  Boolean - True if there is an unprocessed event
Function ThereIsRawEvent() Export
	
	Return (HLConnectedHardwareEventProcessed = False);
	
EndFunction

// See EquipmentManagerTMClient.ConvertDataFromScannerToStructure
//
Function ConvertDataFromScannerToStructure(Parameter) Export
	
	ProcessEvent();
	
	If Parameter[1] = Undefined Then
		Data = New Structure("Barcode, Count", Parameter[0], 1);    // We get the barcode from the main data
	Else
		Data = New Structure("Barcode, Count", Parameter[1][1], 1); // We get the barcode from the additional data
	EndIf;
	
	Return Data;
	
EndFunction

// See EquipmentManagerTMClient.ProcessEvent
// 
Procedure ProcessEvent() Export
	
	HLConnectedHardwareEventProcessed = True;
	
EndProcedure

// See BarcodingOfItemsClient.BarcodesAreValid
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
			If Find(CurBarcode.Barcode, Char(29)) <> 0 Then
				BarcodesAreValid = False;
				Break;
			EndIf;
		#Else
			If FindDisallowedXMLCharacters(CurBarcode.Barcode) <> 0 Then
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

// See barcodingthe general purpose of the Client.Parametersthe completion of the processing of the barcode
// Initializes the structure to End barcode processing.
//
// Parameters:
//  ExecuteAction - String  - The name of the handler for the notification of the action after clarifying the data on the form
// ProcessBarcode  - String - Name of the notification handler for barcode re-processing.
// ProcessingCompletion - String - The name of the action notification handler after barcode processing is Ended.
//
// Returns:
//  Structure - LongDesc:
// * Form - ClientApplicationForm - The form for which processing is performed.
// * CallingFromDocumentForm - Boolean - True if the call is made from the document form, False if it is made from
// the verification and selection processing form.
// * ProcessingOfTSDData - Boolean - The truth is true if this is the processing of TSD data (used in the form of USAIS verification).
// * ScanningParameters - Structure
// * CachedValues - Structure - Contains fields of cached values.
// * BarcodeData_1 - Structure
// * BarcodeProcessingResult - Structure
// * ExecuteAction   - String - The name of the handler for the notification of the action after clarifying the data on the form.
// * ProcessBarcode  - String - Name of the notification handler for barcode re-processing.
// * ProcessingCompletion - String - The name of the action notification handler after barcode processing is Ended. 
Function BarcodeProcessingEndParameters(
	ExecuteAction   = "ProcessingCodeMarkingPerformAction",
	ProcessBarcode  = "ProcessMarkingCode",
	ProcessingCompletion = "AfterProcessingBarcodes") Export
	
	Parameters = New Structure;
	
	Parameters.Insert("Form");
	Parameters.Insert("CallingFromDocumentForm", True);
	Parameters.Insert("ProcessingOfTSDData",    False);
	Parameters.Insert("ScanningParameters");
	Parameters.Insert("CachedValues");
	
	Parameters.Insert("BarcodeData_1");
	Parameters.Insert("BarcodeProcessingResult");
	
	Parameters.Insert("ExecuteAction",   ExecuteAction);
	Parameters.Insert("ProcessBarcode",  ProcessBarcode);
	Parameters.Insert("ProcessingCompletion", ProcessingCompletion);
	
	//@skip-check constructor-function-return-section
	Return Parameters;
	
EndFunction

// See ProductsClient.NotifyAboutChangesInUnitSelectionList
// 
Procedure NotifyAboutChangesInUnitSelectionList(NumberOfNewItems_, ItemArray) Export
	
	TitleText = NStr("vi = 'Thêm yếu tố';
					|ru = 'Добавление элементов';
					|en = 'Add items'; fa = 'افزودن اقلام';
					|it = 'Aggiunta degli elementi';
					|pl = 'Dodanie elementów';
					|tr = 'Öğe ekleme'");
	
	If NumberOfNewItems_ = 1 Then
		ItemToAdd = ItemArray[0];
		
		UnitReference__ = GetURL(ItemToAdd);
		
		MessageText = NStr("vi = 'Một đơn vị đo lường mới đã được thêm vào danh sách: %UnitOfMeasure%.';
							|ru = 'В список добавлена новая единица измерения: %UnitOfMeasure%.';
							|en = 'New unit of measure is added to the list: %UnitOfMeasure%.'; fa = 'New unit of measure is added to the list: %UnitOfMeasure%.';
							|it = 'lista aggiunta una nuova unità di Misura: %UnitOfMeasure%.';
							|pl = 'Do listy jest dodana nowa jednostka miary: %UnitOfMeasure%.';
							|tr = 'Listeye yeni bir ölçü birimi eklendi: %UnitOfMeasure%.'");
		MessageText = StrReplace(MessageText, "%UnitOfMeasure%", String(ItemToAdd));
	Else
		UnitReference__ = "";
		
		DeclinedExpression = InPlural(NStr("vi = 'đơn vị mới';
											|ru = 'новая единица измерения';
											|en = 'new unit of measure'; fa = 'new unit of measure';
											|it = 'nuova unità di misura';
											|pl = 'nowa jednostka miary';
											|tr = 'yeni ölçü birimi'"),
														NStr("vi = 'đơn vị mới';
															|ru = 'новых единиц измерений';
															|en = 'new units of measure'; fa = 'new units of measure';
															|it = 'di nuove unità di misura';
															|pl = 'nowych jednostek miary';
															|tr = 'yeni ölçü birimlerinin'"),
														NStr("vi = 'đơn vị mới';
															|ru = 'новых единиц измерений';
															|en = 'new units of measure'; fa = 'new units of measure';
															|it = 'di nuove unità di misura';
															|pl = 'nowych jednostek miary';
															|tr = 'yeni ölçü birimlerinin'"),
														NumberOfNewItems_);
		
		MessageText = NStr("vi = 'Đã thêm vào danh sách %NumberOfNewItems_% %DeclinedExpression%.';
							|ru = 'В список добавлено %NumberOfNewItems_% %DeclinedExpression%.';
							|en = '%NumberOfNewItems_% %DeclinedExpression% are added to the list.'; fa = '%NumberOfNewItems_% %DeclinedExpression% are added to the list.';
							|it = 'L''elenco contiene%NumberOfNewItems_% %DeclinedExpression%.';
							|pl = 'Do listy dodano %NumberOfNewItems_% %DeclinedExpression%.';
							|tr = 'Listeye eklendi %NumberOfNewItems_% %DeclinedExpression%.'");
		MessageText = StrReplace(MessageText, "%NumberOfNewItems_%", NumberOfNewItems_);
		MessageText = StrReplace(MessageText, "%DeclinedExpression%", DeclinedExpression);
	EndIf;
	
	ShowUserNotification(TitleText, UnitReference__, MessageText,
		PictureLib.Information32);
	
EndProcedure
	
// See EquipmentManagerTMClient.ConvertDataFromScannerToArray
// 
Function ConvertDataFromScannerToArray(Parameter) Export
	
	ProcessEvent();
	
	Data = New Array;
	Data.Add(ConvertDataFromScannerToStructure(Parameter));
	
	Return Data;
	
EndFunction

// See TMCommonUseClientServer.InPlural
//
Function InPlural(Word1, Word2, Word3, Val Integer1) Export
	
	// Let's change the sign of an integer, otherwise negative numbers will be converted incorrectly.
	If Integer1 < 0 Then
		Integer1 = -1 * Integer1;
	EndIf;
	
	If Integer1 <> Int(Integer1) Then 
		// for non-integers , it is always the second form
		Return Word2;
	EndIf;
	
	// Balance
	Balance = Integer1%10;
	If (Integer1 >10) And (Integer1<20) Then
		// for the second ten - always the third form
		Return Word3;
	ElsIf Balance=1 Then
		Return Word1;
	ElsIf (Balance>1) And (Balance<5) Then
		Return Word2;
	Else
		Return Word3;
	EndIf;

EndFunction

#EndRegion