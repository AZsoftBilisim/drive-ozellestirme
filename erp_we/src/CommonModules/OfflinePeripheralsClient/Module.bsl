
#Region Public

#Region FunctionsOfWorkingWithScalesWithLabelPrinting

// Uploads the changed data to a scale with label printing.
//
// Parameters:
//  CallbackDescriptionCompletion - CallbackDescription - Description of the completion notification,
//                                                    called after the end of unloading the goods to Libra.
//  DeviceArray - Array - links Spravochnike.Plug-in equipment to the devices that
//                             you want to upload data to.
//  ShowWarning - Boolean  - Flag that determines whether an end-of-action warning can be displayed.
//
Procedure ExportGoodsToScales(CallbackDescriptionCompletion, DeviceArray, ShowWarning = True) Export
	
	Status(NStr("vi = 'Đang thực hiện kết xuất hàng hóa ra cân có in nhãn tem...';
				|ru = 'Выполняется выгрузка товаров в весы с печатью этикеток...';
				|en = 'Exporting goods to label printing scales...'; fa = 'Exporting goods to label printing scales...';
				|it = 'Le merci vengono scaricate nella bilancia con la stampa di etichette...';
				|pl = 'Jest wykonywane wysłanie towarów do wagi z drukiem etykiet...';
				|tr = 'Etiket baskısı ile ürünler terazilere yükleniyor...'"));
	
	ExecutionState = New Structure;
	ExecutionState.Insert("ErrorsDescription", "");
	ExecutionState.Insert("Completed2",      0);
	ExecutionState.Insert("Processed",     0);
	ExecutionState.Insert("Required2Execute",           DeviceArray.Count());
	ExecutionState.Insert("ShowWarning",     ShowWarning);
	ExecutionState.Insert("CallbackDescriptionCompletion", CallbackDescriptionCompletion);
	
	For Each DeviceID In DeviceArray Do
		
		StructureData = OfflinePeripheralsServerCall.GetDataForWeights(DeviceID, True);
		If StructureData.Data.Count() = 0 Then
			
			Result = False;
			
			If StructureData.NumberOfUnloadedRowsWithErrors = 0 Then
				ExecutionState.ErrorsDescription = GenerateErrorDescriptionForDevice(
					DeviceID,
					Undefined,
					ExecutionState.ErrorsDescription,
					NStr("vi = 'Không có dữ liệu để kết xuất.';
						|ru = 'Нет данных для выгрузки.';
						|en = 'No data for export.'; fa = 'No data for export.';
						|it = 'Non ci sono dati da scaricare.';
						|pl = 'Brak danych do wysłania.';
						|tr = 'Dışa aktarılacak veri yok.'"));
			Else
				ExecutionState.ErrorsDescription = GenerateErrorDescriptionForDevice(
					DeviceID,
					Undefined,
					ExecutionState.ErrorsDescription,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Dữ liệu không được kết xuất. Tìm thấy lỗi"" %1';
							|ru = 'Данные не выгружены. Обнаружено ошибок: %1';
							|en = 'Data is not exported. Errors detected: %1'; fa = 'Data is not exported. Errors detected: %1';
							|it = 'I dati non sono stati scaricati Errori rilevati: %1';
							|pl = 'Dane nie są wysłane. Wykryto błędów: %1';
							|tr = 'Veri dışa aktarılmıyor. Hatalar tespit edildi: %1'"),
						StructureData.NumberOfUnloadedRowsWithErrors));
			EndIf;
			
		EndIf;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ExecutionState", ExecutionState);
		AdditionalParameters.Insert("StructureData", StructureData);
		
		OperationParametersList = PeripheralsWeighingEquipmentServerClientServer.OperationParametersScalesWithLabelPrinting();
		OperationParametersList.TableOfGoods = StructureData.Data;
		OperationParametersList.PartialUnloading = StructureData.PartialUnloading;
		
		PeripheralsWeighingEquipmentServerClient.StartUnloadingDataIntoScalesWithLabelPrinting(
			New CallbackDescription("UploadGoodsCompletion", ThisObject, AdditionalParameters),
			New UUID,
			DeviceID,
			OperationParametersList);
		
	EndDo;
	
EndProcedure

// Handler for notification when the product upload operation is completed.
//
// Parameters:
//  ExecutionResult - Boolean - the result of the operation.
//  Parameters - Structure - Notification handler parameters
//
Procedure UploadGoodsCompletion(ExecutionResult, Parameters) Export
	
	ExecutionState = Parameters.ExecutionState;
	StructureData = Parameters.StructureData;
	
	ExtendedUpload = ?(Parameters.StructureData.Property("ExtendedUpload"), 
		Parameters.StructureData.ExtendedUpload,
		False);
	
	ExecutionState.Processed = ExecutionState.Processed + 1;
	
	If Not ExecutionResult.Result Then
		ExecutionState.ErrorsDescription = GenerateErrorDescriptionForDevice(
			ExecutionResult.DeviceID,
			Undefined,
			ExecutionState.ErrorsDescription,
			ExecutionResult.ErrorDescription);
	Else
		ExecutionState.Completed2 = ExecutionState.Completed2 + 1;
		If StructureData.NumberOfUnloadedRowsWithErrors > 0 Then
			ExecutionState.ErrorsDescription = GenerateErrorDescriptionForDevice(
				ExecutionResult.DeviceID,
				Undefined,
				ExecutionState.ErrorsDescription,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa kết xuất dữ liệu về %1 hàng hóa.';
						|ru = 'Не выгружены данные о %1 товарах.';
						|en = 'Data on the %1 goods is not exported.'; fa = 'Data on the %1 goods is not exported.';
						|it = 'Dati non scaricati sulle %1 merci.';
						|pl = 'Nie są wysłane dane o %1 towarach.';
						|tr = '%1 ürün için veri yüklenmedi.'"),
					StructureData.NumberOfUnloadedRowsWithErrors));
		EndIf;
	EndIf;
	
	OfflinePeripheralsServerCall.WhenUploadingGoodsToDevice(
		ExecutionResult.DeviceID,
		StructureData,
		ExecutionResult.Result,
		ExtendedUpload);

	If ExecutionState.Processed = ExecutionState.Required2Execute Then
		
		If ExecutionState.Completed2 = ExecutionState.Required2Execute And Not ValueIsFilled(ExecutionState.ErrorsDescription) Then
			MessageText = NStr("vi = 'Hàng hóa đã kết xuất thành công!';
								|ru = 'Товары успешно выгружены!';
								|en = 'The goods have been successfully exported.'; fa = 'The goods have been successfully exported.';
								|it = 'Merci scaricate con successo!';
								|pl = 'Wiersze pozycji są pomyślnie wysłane!';
								|tr = 'Ürünler başarıyla dışa aktarıldı!'");
		ElsIf ExecutionState.Completed2 > 0 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Hàng hóa đã được kết xuất đối với %1 thiết bị từ %2.';
					|ru = 'Товары выгружены для %1 устройств из %2.';
					|en = 'Goods have been exported for %1 devices of %2.'; fa = 'Goods have been exported for %1 devices of %2.';
					|it = 'Merci scaricate per %1 dispositivi da %2.';
					|pl = 'Wiersze pozycji są wysłane dla %1 urządzeń z %2.';
					|tr = 'Ürünler %2''den %1 cihaz için yüklendi.'"),
				ExecutionState.Completed2,
				ExecutionState.Required2Execute) + ExecutionState.ErrorsDescription;
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể kết xuất hàng hóa: %1';
					|ru = 'Выгрузить товары не удалось: %1';
					|en = 'Failed to export goods: %1'; fa = 'Failed to export goods: %1';
					|it = 'Impossibile scaricare le merci: %1';
					|pl = 'Nie udało się przesłać wiersze pozycji: %1';
					|tr = 'Ürünlerin dışa aktarılması başarısız oldu: %1'"),
				ExecutionState.ErrorsDescription);
		EndIf;

		If ValueIsFilled(ExecutionState.ErrorsDescription) Then
			OfflinePeripheralsServerCall.WriteErrorToEventLog(
				"OfflinePeripheralsClient.UploadGoodsCompletion",
				MessageText);
		EndIf;
		
		If ExecutionState.ShowWarning Then
			ShowMessageBox(,MessageText, 10);
		Else
			If ExecutionState.CallbackDescriptionCompletion <> Undefined Then
				ReturnValue = New Structure;
				ReturnValue.Insert("Completed2", ExecutionState.Completed2);
				ReturnValue.Insert("Required2Execute", ExecutionState.Required2Execute);
				ReturnValue.Insert("MessageText", MessageText);
				RunCallback(ExecutionState.CallbackDescriptionCompletion, ReturnValue);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure uploads a complete list of products to the scales with label printing.
//
// Parameters:
//  CallbackDescriptionCompletion - CallbackDescription - Description of the completion notification,
//                                                      called after the end of unloading the goods to Libra.
//  DeviceArray - Array - links Spravochnike.Plug-in equipment to devices that
//                             you want to upload changes to.
//  ShowWarning - Boolean - Flag that determines whether an end-of-action warning can be displayed.
//
Procedure UploadFullListOfProductsToLibra(CallbackDescriptionCompletion, DeviceArray, ShowWarning = True) Export
	
	Status(NStr("vi = 'Đang thực hiện kết xuất hàng hóa ra cân có in nhãn tem...';
				|ru = 'Выполняется выгрузка товаров в весы с печатью этикеток...';
				|en = 'Exporting goods to label printing scales...'; fa = 'Exporting goods to label printing scales...';
				|it = 'Le merci vengono scaricate nella bilancia con la stampa di etichette...';
				|pl = 'Jest wykonywane wysłanie towarów do wagi z drukiem etykiet...';
				|tr = 'Etiket baskısı ile ürünler terazilere yükleniyor...'"));
	
	ExecutionState = New Structure;
	ExecutionState.Insert("ErrorsDescription", "");
	ExecutionState.Insert("Completed2",      0);
	ExecutionState.Insert("Processed",     0);
	ExecutionState.Insert("Required2Execute",           DeviceArray.Count());
	ExecutionState.Insert("ShowWarning",     ShowWarning);
	ExecutionState.Insert("CallbackDescriptionCompletion", CallbackDescriptionCompletion);
	
	For Each DeviceID In DeviceArray Do
		
		StructureData = OfflinePeripheralsServerCall.GetDataForWeights(DeviceID, False);
		If StructureData.Data.Count() = 0 Then
			
			Result = False;
			
			If StructureData.NumberOfUnloadedRowsWithErrors = 0 Then
				ExecutionState.ErrorsDescription = GenerateErrorDescriptionForDevice(
					DeviceID,
					Undefined,
					ExecutionState.ErrorsDescription,
					NStr("vi = 'Không có dữ liệu để kết xuất.';
						|ru = 'Нет данных для выгрузки.';
						|en = 'No data for export.'; fa = 'No data for export.';
						|it = 'Non ci sono dati da scaricare.';
						|pl = 'Brak danych do wysłania.';
						|tr = 'Dışa aktarılacak veri yok.'"));
			Else
				ExecutionState.ErrorsDescription = GenerateErrorDescriptionForDevice(
					DeviceID,
					Undefined,
					ExecutionState.ErrorsDescription,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Dữ liệu không được kết xuất. Tìm thấy lỗi"" %1';
							|ru = 'Данные не выгружены. Обнаружено ошибок: %1';
							|en = 'Data is not exported. Errors detected: %1'; fa = 'Data is not exported. Errors detected: %1';
							|it = 'I dati non sono stati scaricati Errori rilevati: %1';
							|pl = 'Dane nie są wysłane. Wykryto błędów: %1';
							|tr = 'Veri dışa aktarılmıyor. Hatalar tespit edildi: %1'"),
						StructureData.NumberOfUnloadedRowsWithErrors));
			EndIf;
			
		EndIf;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ExecutionState", ExecutionState);
		AdditionalParameters.Insert("StructureData", StructureData);
		
		OperationParametersList = PeripheralsWeighingEquipmentServerClientServer.OperationParametersScalesWithLabelPrinting();
		OperationParametersList.TableOfGoods = StructureData.Data;
		OperationParametersList.PartialUnloading = False;
		
		PeripheralsWeighingEquipmentServerClient.StartUnloadingDataIntoScalesWithLabelPrinting(
			New CallbackDescription("UploadGoodsCompletion", ThisObject, AdditionalParameters),
			New UUID,
			DeviceID,
			OperationParametersList);
		
	EndDo;
	
EndProcedure

// The procedure clears the list of products in scales with label printing.
//
// Parameters:
//  CallbackDescriptionCompletion - CallbackDescription - Description of the completion notification,
//                                                      called after the end of cleaning the goods in the balance.
//  DeviceArray - Array of CatalogRef.Peripherals - Devices in which
//                             you need to clear the list of products.
//  ShowWarning - Boolean - Flag that determines whether an end-of-action warning can be displayed.
//
Procedure ClearGoodsInLibra(CallbackDescriptionCompletion, DeviceArray, ShowWarning = True) Export
	
	Status(NStr("vi = 'Đang xóa hàng hóa trong cân có in nhãn tem...';
				|ru = 'Выполняется очистка товаров в весах с печатью этикеток...';
				|en = 'Removing goods from label printing scales...'; fa = 'Removing goods from label printing scales...';
				|it = 'Viene eseguita la pulizia degli articoli nelle bilance con stampa di etichette...';
				|pl = 'Jest wykonywane oczyszczenie towarów w wadze z drukiem etykiet...';
				|tr = 'Yazdırma baskısı ile ürünler terazilerde temizleniyor...'"));
	
	ExecutionState = New Structure;
	ExecutionState.Insert("ErrorsDescription", "");
	ExecutionState.Insert("Completed2",      0);
	ExecutionState.Insert("Processed",     0);
	ExecutionState.Insert("Required2Execute",           DeviceArray.Count());
	ExecutionState.Insert("ShowWarning",     ShowWarning);
	ExecutionState.Insert("CallbackDescriptionCompletion", CallbackDescriptionCompletion);
	
	For Each DeviceID In DeviceArray Do
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ExecutionState", ExecutionState);
		
		PeripheralsWeighingEquipmentServerClient.StartCleaningGoodsInScalesWithLabelPrinting(
			New CallbackDescription("ClearGoodsCompletion", ThisObject, AdditionalParameters),
			New UUID,
			DeviceID);
		
	EndDo;
	
EndProcedure

// Notification handler when the product cleaning operation is completed.
//
// Parameters:
//  ExecutionResult - Boolean - the result of the operation.
//  Parameters - Structure - Parameters of the notification handler.
//
Procedure ClearGoodsCompletion(ExecutionResult, Parameters) Export
	
	ExecutionState = Parameters.ExecutionState;
	
	ExecutionState.Processed = ExecutionState.Processed + 1;
	
	If Not ExecutionResult.Result Then
		ExecutionState.ErrorsDescription = GenerateErrorDescriptionForDevice(
			ExecutionResult.DeviceID,
			Undefined,
			ExecutionState.ErrorsDescription,
			ExecutionResult.ErrorDescription);
	Else
		ExecutionState.Completed2 = ExecutionState.Completed2 + 1;
	EndIf;
	
	OfflinePeripheralsServerCall.WhenClearingItemsInDevice(ExecutionResult.DeviceID, ExecutionResult.Result);

	If ExecutionState.Processed = ExecutionState.Required2Execute Then
		
		If ExecutionState.Completed2 = ExecutionState.Required2Execute And Not ValueIsFilled(ExecutionState.ErrorsDescription) Then
			MessageText = NStr("vi = 'Hàng hóa đã xóa bỏ thành công!';
								|ru = 'Товары успешно очищены!';
								|en = 'Goods are successfully cleared.'; fa = 'Goods are successfully cleared.';
								|it = 'Merci sgravate con successo!';
								|pl = 'Wiersze pozycji są pomyślnie oczyszczone!';
								|tr = 'Ürünler başarıyla temizlendi!'");
		ElsIf ExecutionState.Completed2 > 0 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Hàng hóa đã xóa bỏ thành công đối với %1 thiết bị từ %2.';
					|ru = 'Товары успешно очищены для %1 устройств из %2.';
					|en = 'Goods have been successfully cleared for %1 devices of %2.'; fa = 'Goods have been successfully cleared for %1 devices of %2.';
					|it = 'Merci sgravate con successo per %1 dispositivi da %2.';
					|pl = 'Wiersze pozycji są pomyślnie oczyszczone dla %1 urządzeń z %2.';
					|tr = 'Ürünler %2''den %1 cihaz için başarıyla temizlendi.'"),
				ExecutionState.Completed2,
				ExecutionState.Required2Execute) + ExecutionState.ErrorsDescription;
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xóa bỏ hàng hóa: %1';
					|ru = 'Очистить товары не удалось: %1';
					|en = 'Failed to clear the goods: %1'; fa = 'Failed to clear the goods: %1';
					|it = 'Impossibile sgravare le merci: %1';
					|pl = 'Oczyścić wiersze pozycji nie udało się: %1';
					|tr = 'Ürünler temizlenemiyor: %1'"),
				ExecutionState.ErrorsDescription);
		EndIf;
		
		If ExecutionState.ShowWarning Then
			ShowMessageBox(,MessageText, 10);
		Else
			If ExecutionState.CallbackDescriptionCompletion <> Undefined Then
				ReturnValue = New Structure;
				ReturnValue.Insert("Completed2", ExecutionState.Completed2);
				ReturnValue.Insert("Required2Execute", ExecutionState.Required2Execute);
				ReturnValue.Insert("MessageText", MessageText);
				RunCallback(ExecutionState.CallbackDescriptionCompletion, ReturnValue);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function GenerateErrorDescriptionForDevice(DeviceID, OutputParametersSet, ErrorsDescription, ErrorDescription)
	
	If StrFind(ErrorsDescription, ErrorDescription) Then
		Return ErrorsDescription;
	EndIf;
	
	Return ErrorsDescription
	      + Chars.LF
	      + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Mô tả lỗi cho thiết bị %1: %2';
																			|ru = 'Описание ошибок для устройства %1: %2';
																			|en = 'Description of the errors for device %1: %2'; fa = 'Description of the errors for device %1: %2';
																			|it = 'Descrizione errori per dispositivo %1: %2';
																			|pl = 'Opis błędów dla urządzenia %1: %2';
																			|tr = 'Cihazın hata %2 açıklaması: %1'"), DeviceID, ErrorDescription)
	      + ?(OutputParametersSet <> Undefined, Chars.LF + OutputParametersSet[1], "");
	
EndFunction

#EndRegion
