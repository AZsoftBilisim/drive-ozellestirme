#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurInitialization;
Var CurFileName;
Var ReaderStream;
Var CurrentObject;
Var TypeOfCurrentObject;
Var CurArtifacts; // See CurObjectArtifacts
Var SkipErrors;
Var Errors; // See Errors

#EndRegion

#Region Internal

Procedure OpenFile(Val FileName, IgnoreErrors = False) Export
	
	If CurInitialization Then
		
		Raise NStr("vi = 'Đối tượng đã được khởi tạo trước đó.';
					|ru = 'Объект уже был инициализирован ранее.';
					|en = 'The object has already been initialized earlier.'; fa = 'The object has already been initialized earlier.';
					|it = 'L''oggetto è già stato precedentemente inizializzato.';
					|pl = 'Obiekt już był inicjowany wcześniej.';
					|tr = 'Nesne zaten daha önce başlatıldı.'");
		
	Else
		
		CurFileName = FileName;
	
		ReaderStream = New XMLReader();
		ReaderStream.OpenFile(FileName);
		ReaderStream.MoveToContent();

		If ReaderStream.NodeType <> XMLNodeType.StartElement
			Or ReaderStream.Name <> "Data" Then
			
			Raise(NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Chờ bắt đầu phần tử Data.';
						|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента Data.';
						|en = 'XML reading error. Invalid file format. Start of ""Data"" element is expected.'; fa = 'XML reading error. Invalid file format. Start of ""Data"" element is expected.';
						|it = 'Errore di lettura XML. Formato file errato. Atteso l''inizio dell''elemento Data.';
						|pl = 'Błąd odczytu XML. Nieprawidłowy format pliku. Oczekiwany jest początek elementu Data.';
						|tr = 'XML okuma hatası. Hatalı dosya formatı. Data öğesinin başlangıcı bekleniyor.'"));
		EndIf;
		
		TypeOfCurrentObject = ReaderStream.GetAttribute("Type");

		If Not ReaderStream.Read() Then
			Raise(NStr("vi = 'Lỗi đọc XML. Tìm thấy sự kết thúc tệp.';
						|ru = 'Ошибка чтения XML. Обнаружено завершение файла.';
						|en = 'XML reading error. File end is detected.'; fa = 'XML reading error. File end is detected.';
						|it = 'Errore di lettura XML. Esecuzione file rilevata.';
						|pl = 'Błąd odczytu XML. Wykryto zakończenie pliku.';
						|tr = 'XML okuma hatası. Dosyanın sonlandırıldığı tespit edildi.'"));
		EndIf;
		
		SkipErrors = IgnoreErrors;
		Errors = New Array();
			
		CurInitialization = True;
		
	EndIf;
	
EndProcedure

// Read the data object of the information database.
// 
// Returns: 
//  Boolean - True if the object is read.
Function ReadInformationDatabaseDataObject() Export
	
	If ReaderStream.NodeType <> XMLNodeType.StartElement Then
		CurrentObject = Undefined;
		CurArtifacts = Undefined;
		Return False;
	EndIf;
		
	If ReaderStream.Name <> "DumpElement" Then
		Raise NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Chờ bắt đầu phần tử DumpElement.';
					|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента DumpElement.';
					|en = 'XML reading error. Invalid file format. Start of ""DumpElement"" element is expected.'; fa = 'XML reading error. Invalid file format. Start of ""DumpElement"" element is expected.';
					|it = 'Errore di lettura XML. Formato file errato. Atteso l''inizio dell''elemento DumpElement.';
					|pl = 'Błąd odczytu XML. Nieprawidłowy format pliku. Oczekiwany jest początek elementu DumpElement.';
					|tr = 'XML okuma hatası. Hatalı dosya formatı. DumpElement öğesinin başlangıcı bekleniyor.'");
	EndIf;
	
	ReaderStream.Read(); // <DumpElement>
	
	CurArtifacts = New Array();
	
	If ReaderStream.Name = "Artefacts" Then
		
		ReaderStream.Read(); // <Artefacts>
		While ReaderStream.NodeType <> XMLNodeType.EndElement Do
			
			ElementURI = ReaderStream.NamespaceURI;
			TagName = ReaderStream.Name;
			ArtifactType = XDTOFactory.Type(ElementURI, TagName);
			
			Try
				
				Artifact = XDTOFactory.ReadXML(ReaderStream, ArtifactType);
				
			Except
				
				CauseExceptionErrorWhenReadingData();
				
			EndTry;
			
			CurArtifacts.Add(Artifact);
			
		EndDo;
		ReaderStream.Read(); // </Artefacts>
		
	EndIf;
	
	If SkipErrors Then
		
		ObjectFragment = ReadFragmentOfStream();
		ObjectReadingStream = FragmentReadingStream(ObjectFragment);
		
		Try
			CurrentObject = XDTOSerializer.ReadXML(ObjectReadingStream);
		Except
			
			OriginalException = CloudTechnology.DetailedErrorText(ErrorInfo());
			XMLReadingErrorText = XMLReadingErrorText(ObjectFragment, OriginalException);
				
			Errors.Add(XMLReadingErrorText);
			ReaderStream.Read();	
			Return ReadInformationDatabaseDataObject();
			
		EndTry;
		
	Else
		
		Try
			CurrentObject = XDTOSerializer.ReadXML(ReaderStream);
		Except
			CauseExceptionErrorWhenReadingData();
		EndTry;
		
	EndIf;
	
	ReaderStream.Read(); // </DumpElement>
	
	Return True;
	
EndFunction

// Returns: 
//  CatalogObject, DocumentObject, Structure - the current object.
Function CurrentObject() Export
	
	Return CurrentObject;
	
EndFunction

// Returns: 
//  String - the type of the current object.
Function TypeOfCurrentObject() Export
	
	Return TypeOfCurrentObject;
	
EndFunction

// artifacts of the current object.
// 
// Returns: 
//  Array of Arbitrary - artifacts of the current object.
Function CurObjectArtifacts() Export
	
	Return CurArtifacts;
	
EndFunction

// Returns errors.
// 
// Returns: 
//  Array of String
Function Errors() Export
	Return Errors;
EndFunction

Procedure Close() Export
	
	ReaderStream.Close();
	
EndProcedure

#EndRegion

#Region Private

// The current element is copied from the XML reading stream.
//
// Parameters:
//	Reading flow-Readingxml - read flow of the upload.
//
// Returns:
//	String - the text of the XML fragment.
//
Function ReadFragmentOfStream()
	
	RecordingFragment = New XMLWriter;
	RecordingFragment.SetString();
	
	FragmentNodeName = ReaderStream.Name;
	
	RootNode = True;
	Try
		
		While Not (ReaderStream.NodeType = XMLNodeType.EndElement
				And ReaderStream.Name = FragmentNodeName) Do
			
			RecordingFragment.WriteCurrent(ReaderStream);
			
			If ReaderStream.NodeType = XMLNodeType.StartElement Then
				
				If RootNode Then
					NamespaceURIs = ReaderStream.NamespaceContext.NamespaceURIs();
					For Each URI In NamespaceURIs Do
						RecordingFragment.WriteNamespaceMapping(ReaderStream.NamespaceContext.LookupPrefix(URI), URI);
					EndDo;
					RootNode = False;
				EndIf;
				
				ElementNamespaceURIPrefixes = ReaderStream.NamespaceContext.NamespaceMappings();
				For Each KeyAndValue In ElementNamespaceURIPrefixes Do
					Prefix = KeyAndValue.Key;
					URI = KeyAndValue.Value;
					RecordingFragment.WriteNamespaceMapping(Prefix, URI);
				EndDo;
				
			EndIf;
			
			ReaderStream.Read();
		EndDo;
		
		RecordingFragment.WriteCurrent(ReaderStream);
		
		ReaderStream.Read();
	Except
		TextLR = StrTemplate(NStr("vi = 'Đã xảy ra lỗi khi sao chép một đoạn của tệp gốc. Phần được sao chép một phần: 
                  |%1';
                  |ru = 'Ошибка копирования фрагмента исходного файла. Частично скопированный фрагмент:
                  |%1';
                  |en = 'An error occurred when copying the original file fragment. Partially copied fragment:
                  |%1'; fa = 'An error occurred when copying the original file fragment. Partially copied fragment:
                  |%1';
                  |it = 'Errore durante la copia del frammento del file originale. Frammento parzialmente copiato: 
                  |%1';
                  |pl = 'Błąd podczas kopiowania fragmentu oryginalnego pliku. Częściowo skopiowany fragment:
                  |%1';
                  |tr = 'Kaynak dosyanın parçası kopyalanırken hata oluştu. Kısmen kopyalanan parça:
                  |%1'"),
				RecordingFragment.Close());
		
		// @skip-check module-nstr-camelcase - verification error
		WriteLogEvent(NStr("vi = 'Kết xuất/kết nhập dữ liệu.Lỗi đọc XML';
							|ru = 'Выгрузка/загрузка данных.Ошибка чтения XML';
							|en = 'Data import/export. XML reading error'; fa = 'Data import/export. XML reading error';
							|it = 'Upload/ Download dati. Errore di lettura XML';
							|pl = 'Przesyłanie/pobieranie danych.Błąd odczytu XML';
							|tr = 'Veri dışa/içe aktarma. XML okuma hatası'", 
			Common.DefaultLanguageCode()), EventLogLevel.Error, , , TextLR);
		Raise;
	EndTry;
	
	Particle = RecordingFragment.Close();
	
	Return Particle;
	
EndFunction

Function FragmentReadingStream(Val Particle)
	
	ReadingFragment = New XMLReader();
	ReadingFragment.SetString(Particle);
	ReadingFragment.MoveToContent();
	
	Return ReadingFragment;
	
EndFunction

Function XMLReadingErrorText(Val Particle, Val ErrorText)
	
	Return StrTemplate(NStr("vi = 'Lỗi khi đọc dữ liệu từ tệp %1: trong khi đọc phân đoạn
              |
              |%2
              |
              |đã xảy ra lỗi:
              |
              |%3.';
              |ru = 'Ошибка при чтении данных из файла %1: при чтении фрагмента
              |
              |%2
              |
              |произошла ошибка:
              |
              |%3.';
              |en = 'An error occurred while reading data from file %1: error reading fragment
              |
              |%2
              |
              |error:
              |
              |%3.'; fa = 'An error occurred while reading data from file %1: error reading fragment
              |
              |%2
              |
              |error:
              |
              |%3.';
              |it = 'Errore durante la lettura dei dati dal file%1: durante la lettura del frammento 
              |
              |%2
              |
              | si è verificato un errore: 
              |
              |%3.';
              |pl = 'Błąd odczytu danych z pliku %1: podczas odczytu fragmentu
              |
              |%2
              |
              |wystąpił błąd:
              |
              |%3.';
              |tr = '%1 dosyadan veri okurken hata oluştu: 
              |
              |%2
              |fragman okunurken
              |hata oluştu:
              |
              |%3.'"),
		CurFileName,
		Left(Particle, 10000),
		ErrorText);
	
EndFunction

Procedure CauseExceptionErrorWhenReadingData()
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(CurFileName);
	ReaderStream.MoveToContent();
	ReaderStream.Read();
	
	While ReadProblematicObjectOfInformationBase() Do
		
	EndDo;
	
EndProcedure

Function ReadProblematicObjectOfInformationBase()
	
	If ReaderStream.NodeType <> XMLNodeType.StartElement Then
		CurrentObject = Undefined;
		CurArtifacts = Undefined;
		Return False;
	EndIf;
	
	If ReaderStream.Name <> "DumpElement" Then
		Raise NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Chờ bắt đầu phần tử DumpElement.';
					|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента DumpElement.';
					|en = 'XML reading error. Invalid file format. Start of ""DumpElement"" element is expected.'; fa = 'XML reading error. Invalid file format. Start of ""DumpElement"" element is expected.';
					|it = 'Errore di lettura XML. Formato file errato. Atteso l''inizio dell''elemento DumpElement.';
					|pl = 'Błąd odczytu XML. Nieprawidłowy format pliku. Oczekiwany jest początek elementu DumpElement.';
					|tr = 'XML okuma hatası. Hatalı dosya formatı. DumpElement öğesinin başlangıcı bekleniyor.'");
	EndIf;
	
	ReaderStream.Read(); // <DumpElement>
	
	If ReaderStream.Name = "Artefacts" Then
		
		ReaderStream.Read(); // <Artefacts>
		While ReaderStream.NodeType <> XMLNodeType.EndElement Do
			
			ElementURI = ReaderStream.NamespaceURI;
			TagName = ReaderStream.Name;
			ArtifactType = XDTOFactory.Type(ElementURI, TagName);
			
			ArtifactFragment = ReadFragmentOfStream();
			ArtifactReadingStream = FragmentReadingStream(ArtifactFragment);
			Try
				Artifact = XDTOFactory.ReadXML(ArtifactReadingStream, ArtifactType);
			Except
				OriginalException = CloudTechnology.ShortErrorText(ErrorInfo());
				Raise XMLReadingErrorText(ArtifactFragment, OriginalException);
			EndTry;
			
		EndDo;
		ReaderStream.Read(); // </Artefacts>
		
	EndIf;
	
	ObjectFragment = ReadFragmentOfStream();
	ObjectReadingStream = FragmentReadingStream(ObjectFragment);
		
	Try
		CurrentObject = XDTOSerializer.ReadXML(ObjectReadingStream);
	Except
		OriginalException = CloudTechnology.ShortErrorText(ErrorInfo());
		Raise XMLReadingErrorText(ObjectFragment, OriginalException);
	EndTry;
	
	ReaderStream.Read(); // </DumpElement>
	
	Return True;
	
EndFunction

#EndRegion

#Region Initialize

CurInitialization = False;

#EndRegion

#EndIf