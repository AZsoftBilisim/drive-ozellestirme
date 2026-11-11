#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurContainer;
Var CurrentMetadataObject1; // MetadataObject - the current metadata object.
Var CurHandlers;
Var CurStreamOfRecordOfRecreatedLinks;
Var CurFlowRecordsOfMappedLinks;
Var CurSerializer;
Var CurrentNode;
Var FixObjectProcessing;
Var HandlersAvailability; // Structure

#EndRegion

#Region Internal


// Initializes data upload / download processing.
// 
// Parameters:
// 	Container - DataProcessorObject.ExportImportDataContainerManager - 
// 	MetadataObject - MetadataObject -
// 	Node - ExchangePlanRef.ApplicationsMigration - 
// 	Handlers - ValueTable - 
// 	Serializer - XDTOSerializer - 
// 	StreamRecordingOfReCreatedLinks - DataProcessorObject.ExportImportDataRegeneratedReferencesWritingStream - 
// 	RecordFlowOfMappedLinks - DataProcessorObject.ExportImportDataMappedReferencesWritingStream - 
//
Procedure Initialize(Container, MetadataObject, Node, Handlers, Serializer, StreamRecordingOfReCreatedLinks, RecordFlowOfMappedLinks) Export
	
	CurContainer = Container;
	FixObjectProcessing = Container.FixState(); 
	
	CurrentMetadataObject1 = MetadataObject; // MetadataObject
	CurrentNode = Node;
	CurHandlers = Handlers;
	CurSerializer = Serializer;
	CurStreamOfRecordOfRecreatedLinks = StreamRecordingOfReCreatedLinks;
	CurFlowRecordsOfMappedLinks = RecordFlowOfMappedLinks;
    	 
EndProcedure

Procedure ExportData() Export
	
	If FixObjectProcessing Then
		CurContainer.RecordStartOfMetadataObjectProcessing(CurrentMetadataObject1.FullName());
	EndIf;
		
	Cancel = False;
	HandlersAvailability = CurHandlers.MetadataObjectHandlersAvailability(CurrentMetadataObject1);
	
	If HandlersAvailability.BeforeUnloadingType Then
		CurHandlers.BeforeUnloadingType(CurContainer, CurSerializer, CurrentMetadataObject1, Cancel);
	EndIf;
	
	If Cancel And FixObjectProcessing Then
		CurContainer.ObjectsAreProcessed(
			CurContainer.ObjectsToBeProcessedByMetadataObject(CurrentMetadataObject1));
	ElsIf Not Cancel Then
		UploadMetadataObjectData();
	EndIf;
	
	If HandlersAvailability.AfterUnloadingType Then
		CurHandlers.AfterUnloadingType(CurContainer, CurSerializer, CurrentMetadataObject1);
	EndIf;
	
	If FixObjectProcessing Then
		CurContainer.CommitMetadataObjectProcessingEnd(CurrentMetadataObject1.FullName());
	EndIf;
		
EndProcedure

// Performs actions to re-create links to when you download.
//
// Parameters:
//	Ref - AnyRef - object reference.
//
Procedure YouNeedToRecreateLinkWhenUploading(Val Ref) Export
	
	CurStreamOfRecordOfRecreatedLinks.RecreateLinkWhenUploading(Ref);
	
EndProcedure

// Performs the action for matching links to when you download.
//
// Parameters:
//	Ref - AnyRef - object reference.
//	NaturalKey - Structure - where the key is the name of the natural key, and the value is an arbitrary value of the natural key.
//
Procedure YouNeedToMatchLinkWhenDownloading(Val Ref, Val NaturalKey) Export
	
	CurFlowRecordsOfMappedLinks.MatchLinkWhenUploading(Ref, NaturalKey);
	
EndProcedure

Procedure Close() Export
	
	Return;
	
EndProcedure

#EndRegion

#Region Private

Procedure UploadMetadataObjectData()
	
	WriteLogEvent(
		NStr("vi = 'Kết xuất kết nhập dữ liệu. Kết xuất đối tượng metadata';
			|ru = 'Выгрузка загрузка данных. Выгрузка объекта метаданных';
			|en = 'Data export and import. Metadata object export'; fa = 'Data export and import. Metadata object export';
			|it = 'Upload download dati. Upload oggetto metadati';
			|pl = 'Eksportowanie pobieranie danych. Eksportowanie obiektu metadanych';
			|tr = 'Veri Dışa Aktarımı ve İçe Aktarımı.Meta veri nesnesi dışa aktarma'", Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		CurrentMetadataObject1,
		,
		StrTemplate(NStr("vi = 'Bắt đầu kết xuất dữ liệu của đối tượng metadata: %1';
						|ru = 'Начало выгрузки данных объекта метаданных: %1';
						|en = 'Starting to export metadata object data: %1'; fa = 'Starting to export metadata object data: %1';
						|it = 'Inizio upload dei dati dell''oggetto dei metadati: %1';
						|pl = 'Rozpoczęcie przesyłania danych obiektu metadanych: %1';
						|tr = 'Nesne meta veri dışa aktarma başlatma:%1'", Common.DefaultLanguageCode()),
			CurrentMetadataObject1.FullName()));
	
	If CommonCTL.IsConstant(CurrentMetadataObject1) Then
		
		UnloadConstant();
		
	ElsIf CommonCTL.IsRefData(CurrentMetadataObject1) Then
		
		UnloadReferenceObject();
		
	ElsIf CommonCTL.IsIndependentRecordSet(CurrentMetadataObject1) Then
		
		UnloadIndependentRecordset();
		
	ElsIf CommonCTL.IsRecordSet(CurrentMetadataObject1) Then 
		
		UnloadSetOfRecordsSubordinateToRegistrar();
		
	Else
		
		Raise StrTemplate(NStr("vi = 'Đối tượng metadata bất thường: %1';
								|ru = 'Неожиданный объект метаданных: %1';
								|en = 'Unexpected metadata object: %1'; fa = 'Unexpected metadata object: %1';
								|it = 'Oggetto di metadati imprevisto: %1';
								|pl = 'Nieoczekiwany obiekt metadanych: %1';
								|tr = 'Beklenmedik meta veri nesnesi: %1'"),
			CurrentMetadataObject1.FullName());
		
	EndIf;
 	
EndProcedure

Procedure UnloadConstant()
	
	If CurrentNode = Undefined Then
	
		ValueManager = Constants[CurrentMetadataObject1.Name].CreateValueManager();	
		ValueManager.Read();
		
		WriteStream = StartRecordingFile();
		RecordInformationBaseData(WriteStream, ValueManager);
		CompleteFileRecording(WriteStream);
		
	Else
		
		Selection = ExchangePlans.SelectChanges(CurrentNode, 1, CurrentMetadataObject1);
		While Selection.Next() Do
			
			ValueManager = Selection.Get();
			
			WriteStream = StartRecordingFile();
			RecordInformationBaseData(WriteStream, ValueManager);
			CompleteFileRecording(WriteStream);
			
		EndDo;
		
	EndIf;
	
	ExportImportExchangePlansNodes.UploadChanges(CurContainer, CurrentMetadataObject1, CurSerializer);
	
EndProcedure

Procedure UnloadReferenceObject()
	
	SupportsPredefined = 
		CommonCTL.IsRefDataSupportingPredefinedItems(CurrentMetadataObject1);
	
	CheckDuplicatesOfPredefined(SupportsPredefined);
	
	WriteStream = StartRecordingFile();
	
	ObjectName = CurrentMetadataObject1.FullName();
	If CurrentNode = Undefined 
		Or Metadata.ExchangePlans.Contains(CurrentMetadataObject1) Then
		ObjectManager = Common.ObjectManagerByFullName(ObjectName);
	
		Selection = ObjectManager.Select();
		While Selection.Next() Do
			Object = Selection.GetObject();
			FixNameOfPredefinedData(SupportsPredefined, ObjectManager, Object);
			RecordInformationBaseData(WriteStream, Object);
		EndDo;
		
	Else
		If SupportsPredefined Then
			ObjectManager = Common.ObjectManagerByFullName(ObjectName);
		EndIf;
		
		Selection = ExchangePlans.SelectChanges(CurrentNode, 1, CurrentMetadataObject1);
		While Selection.Next() Do
			Object = Selection.Get();
			If Object <> Undefined And TypeOf(Object) <> Type("ObjectDeletion") Then
				FixNameOfPredefinedData(SupportsPredefined, ObjectManager, Object);
			EndIf;
			RecordInformationBaseData(WriteStream, Object);
		EndDo;
	
	EndIf;
	
	CompleteFileRecording(WriteStream);
	
	ExportImportExchangePlansNodes.UploadChanges(CurContainer, CurrentMetadataObject1, CurSerializer);
	
EndProcedure

Procedure UnloadIndependentRecordset()
	
	WriteStream = StartRecordingFile();
	
	If CurrentNode = Undefined Then
		
		Dimensions = New Array();
		If CurrentMetadataObject1.InformationRegisterPeriodicity 
			<> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
			PropsPeriod = CurrentMetadataObject1.StandardAttributes.Period; // StandardAttributeDescription
			Dimensions.Add(PropsPeriod.Name);
		EndIf;
		For Each Dimension In CurrentMetadataObject1.Dimensions Do // MetadataObjectDimension
			Dimensions.Add(Dimension.Name);
		EndDo;
		
		ObjectManager = InformationRegisters[CurrentMetadataObject1.Name];
		RecordSet = ObjectManager.CreateRecordSet(); // Creating a set takes a significant amount of time
		For Each Dimension In Dimensions Do
			RecordSet.Filter[Dimension].Use = True;
		EndDo;
		
		Selection = ObjectManager.Select();
		While Selection.Next() Do
			RecordSet.Clear();
			For Each Dimension In Dimensions Do
				RecordSet.Filter[Dimension].Value = Selection[Dimension];
			EndDo;
			FillPropertyValues(RecordSet.Add(), Selection);
			RecordInformationBaseData(WriteStream, RecordSet);
		EndDo;
			
	Else
		
		Selection = ExchangePlans.SelectChanges(CurrentNode, 1, CurrentMetadataObject1);
		While Selection.Next() Do
			
			RecordSet = Selection.Get();
			RecordInformationBaseData(WriteStream, RecordSet);
			
		EndDo;
		
	EndIf;
	
	CompleteFileRecording(WriteStream);
	
	ExportImportExchangePlansNodes.UploadChanges(CurContainer, CurrentMetadataObject1, CurSerializer);
	
EndProcedure

Procedure UnloadSetOfRecordsSubordinateToRegistrar()
	
	If CommonCTL.IsRecalculationRecordSet(CurrentMetadataObject1) Then
		
		RecorderFieldName = "RecalculationObject";
		
		Substrings = StrSplit(CurrentMetadataObject1.FullName(), ".");
		TableName = Substrings[0] + "." + Substrings[1] + "." + Substrings[3];
		
	Else
		
		RecorderFieldName = "Recorder";
		TableName = CurrentMetadataObject1.FullName();
		
	EndIf;
	
	WriteStream = StartRecordingFile();
	
	If CurrentNode <> Undefined Then
		
		Selection = ExchangePlans.SelectChanges(CurrentNode, 1, CurrentMetadataObject1);
		While Selection.Next() Do
			
			RecordSet = Selection.Get();
			RecordInformationBaseData(WriteStream, RecordSet);
			
		EndDo;
	
	ElsIf CommonCTL.IsAccumulationRegister(CurrentMetadataObject1)
		Or CommonCTL.IsInformationRegister(CurrentMetadataObject1) Then
			
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Table.RecorderFieldName AS Recorder,
		|	COUNT(*) AS RecordsCount
		|FROM
		|	TableName AS Table
		|GROUP BY
		|	Table.RecorderFieldName";
		Query.Text = StrReplace(Query.Text, "TableName", TableName);
		Query.Text = StrReplace(Query.Text, "RecorderFieldName", RecorderFieldName);
		Result = Query.Execute();
		If Result.IsEmpty() Then
			CompleteFileRecording(WriteStream);
			Return;
		EndIf;
		
		LoggerSets = New Array;
		LoggerSets.Add(New Array);
		Selection = Result.Select();
		CurNumberOfRecords = 0;
		While Selection.Next() Do
			If CurNumberOfRecords + Selection.RecordsCount > 1000 And CurNumberOfRecords <> 0 Then
				LoggerSets.Add(New Array);
				CurNumberOfRecords = 0;
			EndIf;
			CurNumberOfRecords = CurNumberOfRecords + Selection.RecordsCount;
			LastItem = LoggerSets[LoggerSets.UBound()]; // Array
			LastItem.Add(Selection.Recorder);
		EndDo;
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	*
		|FROM
		|	TableName AS Table
		|WHERE
		|	Recorder IN (&Recorders)
		|ORDER BY
		|	Recorder, LineNumber
		|TOTALS BY
		|	Recorder";
		Query.Text = StrReplace(Query.Text, "TableName", TableName);
		Query.Text = StrReplace(Query.Text, "RecorderFieldName", RecorderFieldName);
		ObjectManager = Common.ObjectManagerByFullName(CurrentMetadataObject1.FullName());
		RecordSet = ObjectManager.CreateRecordSet(); // Creating a set takes a significant amount of time
		For Each Recorders In LoggerSets Do
			Query.SetParameter("Recorders", Recorders);
			SamplingByRegistrars = Query.Execute().Select(QueryResultIteration.ByGroups);
			While SamplingByRegistrars.Next() Do
				RecordSet.Clear();
				FilterElement = RecordSet.Filter[RecorderFieldName]; // FilterItem
				FilterElement.Set(SamplingByRegistrars.Recorder);
				SelectionByRecords = SamplingByRegistrars.Select();
				While SelectionByRecords.Next() Do
					FillPropertyValues(RecordSet.Add(), SelectionByRecords);
				EndDo;
				RecordInformationBaseData(WriteStream, RecordSet);
			EndDo;
		EndDo;
		
	Else
		
		Query = New Query;
		Query.Text = 
		"SELECT DISTINCT
		|	Table.RecorderFieldName AS Recorder
		|FROM
		|	TableName AS Table";
		Query.Text = StrReplace(Query.Text, "TableName", TableName);
		Query.Text = StrReplace(Query.Text, "RecorderFieldName", RecorderFieldName);
		
		Result = Query.Execute();
		If Result.IsEmpty() Then
			CompleteFileRecording(WriteStream);
			Return;
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(CurrentMetadataObject1.FullName());
		RecordSet = ObjectManager.CreateRecordSet(); // Creating a set takes a significant amount of time
		
		Selection = Result.Select();
		While Selection.Next() Do
			
			FilterElement = RecordSet.Filter[RecorderFieldName]; // FilterItem
			FilterElement.Set(Selection.Recorder);
			
			RecordSet.Read();
			
			RecordInformationBaseData(WriteStream, RecordSet);
			
		EndDo;
	
	EndIf;
	
	CompleteFileRecording(WriteStream);
	
	ExportImportExchangePlansNodes.UploadChanges(CurContainer, CurrentMetadataObject1, CurSerializer);
	
EndProcedure

// Writes an object in XML.
//
// Parameters:
//	WriteStream - DataProcessorObject.ExportImportDataInfobaseDataWritingStream - stream to write. 
//	Data - Arbitrary - the object being recorded.
//
Procedure RecordInformationBaseData(WriteStream, Data)
	
	Cancel = False;
	Artifacts = New Array();
	
	If HandlersAvailability.BeforeExportObject Then
		CurHandlers.BeforeExportObject(
			CurContainer, ThisObject, CurSerializer, Data, Artifacts, Cancel);
	EndIf;
	
	If Not Cancel Then
		WriteStream.WriteInformationDatabaseDataObject(Data, Artifacts);
	EndIf;
	
	If HandlersAvailability.AfterExportObject Then
		CurHandlers.AfterExportObject(CurContainer, ThisObject, CurSerializer, Data, Artifacts);
	EndIf;
	
	If FixObjectProcessing Then
		CurContainer.ObjectProcessed();	
	EndIf;
		
	If WriteStream.LargerThanRecommended() Then
		CompleteFileRecording(WriteStream);
		WriteStream = StartRecordingFile();
	EndIf;
	
EndProcedure

Function StartRecordingFile()
	
	FileName = CurContainer.CreateFile(
		ExportImportDataInternal.InfobaseData(), CurrentMetadataObject1.FullName());
	
	WriteStream = DataProcessors.ExportImportDataInfobaseDataWritingStream.Create();
	WriteStream.OpenFile(FileName, CurSerializer);
		
	Return WriteStream;
	
EndFunction

Procedure CompleteFileRecording(WriteStream)
	
	WriteStream.Close();
	
	ObjectCount = WriteStream.ObjectCount();
	If ObjectCount = 0 Then
		CurContainer.ExcludeFile(WriteStream.FileName());
	Else
		CurContainer.SetNumberOfObjects(WriteStream.FileName(), ObjectCount);
	EndIf;
	
	WriteLogEvent(
		NStr("vi = 'Kết xuất kết nhập dữ liệu. Kết xuất đối tượng metadata';
			|ru = 'Выгрузка загрузка данных. Выгрузка объекта метаданных';
			|en = 'Data export and import. Metadata object export'; fa = 'Data export and import. Metadata object export';
			|it = 'Upload download dati. Upload oggetto metadati';
			|pl = 'Eksportowanie pobieranie danych. Eksportowanie obiektu metadanych';
			|tr = 'Veri Dışa Aktarımı ve İçe Aktarımı.Meta veri nesnesi dışa aktarma'", Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		CurrentMetadataObject1,
		,
		StrTemplate(NStr("vi = 'Đã kết xuất xong dữ liệu của đối tượng metadata: %1 
		|Đã kết xuất: %2 đối tượng';
		|ru = 'Окончание выгрузки данных объекта метаданных: %1
		|Выгружено объектов: %2';
		|en = 'Finish exporting metadata object data: %1
		|Objects exported: %2'; fa = 'Finish exporting metadata object data: %1
		|Objects exported: %2';
		|it = 'Fine upload dei dati dell''oggetto dei metadati: %1
		| Oggetti caricati: %2';
		|pl = 'Koniec przesyłania danych obiektu metadanych: %1
		|Przesłane obiekty: %2';
		|tr = 'Meta veri nesne verileri dışa aktarma tamamlandı: %1
		|Dışa aktarılan nesneler: %2'", Common.DefaultLanguageCode()),
			CurrentMetadataObject1.FullName(), ObjectCount));
	
EndProcedure

Procedure CheckDuplicatesOfPredefined(SupportsPredefinedElements)
	
	If Not SupportsPredefinedElements Then
		Return;
	EndIf;
	
	CheckPredefinedDuplicationRequestTextTemplate = 
	"SELECT
	|	Table.PredefinedDataName AS PredefinedDataName
	|FROM
	|	&Table AS Table
	|WHERE
	|	Table.Predefined
	|GROUP BY
	|	Table.PredefinedDataName
	|HAVING
	|	COUNT(*) > 1
	|ORDER BY
	|	PredefinedDataName";
	
	FullName = CurrentMetadataObject1.FullName();
	
	
	Query = New Query;		
	Query.Text = StrReplace(CheckPredefinedDuplicationRequestTextTemplate, "&Table", FullName);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	PredefinedDataNames = QueryResult.Unload().UnloadColumn("PredefinedDataName");
	
	If PredefinedDataNames.Count() = 1 Then
		ErrorTextTemplate = NStr("vi = 'Đã tìm thấy dữ liệu định trước trùng lặp có tên %1 trong bảng %2
		|%3';
		|ru = 'Обнаружено дублирование предопределенных данных с именем %1 в таблице %2
		|%3';
		|en = 'Duplicate predefined data with the %1 name is found in the %2 table
		|%3'; fa = 'Duplicate predefined data with the %1 name is found in the %2 table
		|%3';
		|it = 'Rilevato duplicato dei dati predefiniti con nome %1 nella tabella %2
		|%3';
		|pl = 'Wykryto dublowanie predefiniowanych danych z nazwą %1 w tabeli %2
		|%3';
		|tr = '%2 tablosunda %1 adıyla yinelenen önceden tanımlanmış veriler tespit edildi
		|%3'")	
	Else
		ErrorTextTemplate = NStr("vi = 'Đã tìm thấy dữ liệu định trước trùng lặp có tên %1 trong bảng %2
		|%3';
		|ru = 'Обнаружено дублирование предопределенных данных с именами %1 в таблице %2
		|%3';
		|en = 'Duplicate predefined data with the %1 names is found in the %2 table
		|%3'; fa = 'Duplicate predefined data with the %1 names is found in the %2 table
		|%3';
		|it = 'Rilevato duplicato dei dati predefiniti con nomi %1 nella tabella %2
		|%3';
		|pl = 'Wykryto dublowanie predefiniowanych danych z nazwami %1 w tabeli %2
		|%3';
		|tr = '%2 tablosunda %1 adlarıyla yinelenen önceden tanımlanmış veriler tespit edildi
		|%3'")	
	EndIf;
	
	If SaaSOperations.DataSeparationEnabled() Then
		RecommendationText = NStr(
		"vi = 'Hãy liên hệ với bộ phận hỗ trợ kỹ thuật';
		|ru = 'Рекомендуется обратиться в службу технической поддержки';
		|en = 'Contact technical support'; fa = 'تماس با پشتیبانی فنی';
		|it = 'Si consiglia di rivolgersi al servizio di supporto tecnico';
		|pl = 'Zaleca się zwrócić się do służby pomocy technicznej';
		|tr = 'Teknik desteğe başvurmanız önerilir'"); 
	Else
		RecommendationText = NStr(
		"vi = 'Nên thử nghiệm và sửa chữa ở chế độ ''Kiểm tra tính toàn vẹn lô-gic của cơ sở thông tin''';
		|ru = 'Рекомендуется выполнить тестирование и исправление в режиме ''Проверка логической целостности информационной базы''';
		|en = 'Run infobase verification and repair in the ''Check logical infobase integrity'' mode'; fa = 'Run infobase verification and repair in the ''Check logical infobase integrity'' mode';
		|it = 'Si consiglia di eseguire il test e correzione della modalità ""Verifica integrità logica dell''infobase""';
		|pl = 'Zaleca się przeprowadzić testowanie i korektę w trybie ''Sprawdzanie logicznej integralności bazy informacyjnej''';
		|tr = '''Infobase''in mantıksal bütünlüğünü kontrol et'' modunda test edilmesi ve düzeltilmesi önerilir.'");
	EndIf;
	
	ErrorText = StrTemplate(
		ErrorTextTemplate,
		StrConcat(PredefinedDataNames, ", "),
		FullName,
		RecommendationText);
	
	CurContainer.AddWarning(ErrorText);
	
	
	DuplicatesOfPredefinedRequestTextTemplate = 
	"SELECT
	|	Table.PredefinedDataName AS PredefinedDataName,
	|	Table.Ref AS Ref
	|FROM
	|	&Table AS Table
	|WHERE
	|	Table.PredefinedDataName IN(&PredefinedDataNames)
	|
	|ORDER BY
	|	PredefinedDataName,
	|	Ref
	|TOTALS BY
	|	PredefinedDataName";
	
	Query = New Query;
	Query.SetParameter("PredefinedDataNames", PredefinedDataNames);
	Query.Text = StrReplace(DuplicatesOfPredefinedRequestTextTemplate, "&Table", FullName);
	
	Duplicates = New Structure;
	SelectionByPredefined = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SelectionByPredefined.Next() Do
		IDs = New Array;
		SelectionByRefs = SelectionByPredefined.Select();
		While SelectionByRefs.Next() Do
			IDs.Add(String(SelectionByRefs.Ref.UUID()));
		EndDo;
		Duplicates.Insert(SelectionByPredefined.PredefinedDataName, IDs);
	EndDo;
	
	CurContainer.AddDuplicatesOfPredefined(CurrentMetadataObject1, Duplicates);
	
EndProcedure

Procedure FixNameOfPredefinedData(SupportsPredefined, ObjectManager, Object)
	
	If Not SupportsPredefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.PredefinedDataName)
		And Not StrStartsWith(Object.PredefinedDataName, "#") 
		And ObjectManager[Object.PredefinedDataName] <> Object.Ref Then
		Object.PredefinedDataName = "";
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
