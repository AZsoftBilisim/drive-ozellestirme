
#Region Public

// Procedure - the Object is not found
//
// Parameters:
//  Barcode - String - Barcode
//  SearchForAllObjects - Boolean - Search for all objects.
//
Procedure ObjectIsNotFound(Barcode, SearchForAllObjects = True) Export
	
	DisplayMessageObjectNotFound = True;
	
	If SearchForAllObjects Then
		Status(NStr("vi = 'Đang tìm kiếm chứng từ theo mã vạch trong tất cả các chứng từ của cơ sở thông tin.';
					|ru = 'Выполняется поиск документа по штрихкоду во всех документах информационной базы..';
					|en = 'Searching for the document by barcode in all documents of the infobase..'; fa = 'Searching for the document by barcode in all documents of the infobase..';
					|it = 'Ricerca del documento tramite codice a barre in tutti i documenti della base informativa in corso...';
					|pl = 'Dokument jest wyszukiwany przez kod kreskowy we wszystkich dokumentach bazy informacyjnej.';
					|tr = 'Infobase''deki tüm belgelerde barkoda göre bir belge ara.'"));
		ReferencesArrray = BarcodingOfPrintFormsServerCall.GetLinkFromBarcodeOfTabularDocument(Barcode);
		If ReferencesArrray.Count() > 0 Then
			DisplayMessageObjectNotFound = False;
			ShowValue(,ReferencesArrray[0]);
		EndIf;
	EndIf;
	
	If DisplayMessageObjectNotFound Then
		ClearMessages();
		CommonClientServer.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa tìm thấy đối tượng có mã vạch %1';
																										|ru = 'Объект со штрихкодом %1 не найден';
																										|en = 'Object with barcode %1 is not found'; fa = 'Object with barcode %1 is not found';
																										|it = 'Oggetto con codice a barre %1 non trovato';
																										|pl = 'Obiekt z kodem kreskowym %1 nie został znaleziony';
																										|tr = '%1 barkodlu nesne bulunamadı'"), Barcode));
	EndIf;
	
EndProcedure

// Function-Get a link based on the barcode of a table document
//
// Parameters:
//  Barcode - String - Barcode
//  Managers - Array - Document managers.
// 
// Returns:
//  Array - Array of links to the found documents.
//
Function GetLinkFromBarcodeOfTabularDocument(Barcode, Managers = Undefined) Export
	
	Status(NStr("vi = 'Đang tìm kiếm chứng từ theo mã vạch...';
				|ru = 'Выполняется поиск документа по штрихкоду...';
				|en = 'Searching for the document by barcode...'; fa = 'Searching for the document by barcode...';
				|it = 'Viene effettuata la ricerca del documento per codice a barre...';
				|pl = 'Wyszukiwanie dokumentu według kodu kreskowego...';
				|tr = 'Belge barkoda göre aranıyor...'"));
	Return BarcodingOfPrintFormsServerCall.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

#EndRegion
