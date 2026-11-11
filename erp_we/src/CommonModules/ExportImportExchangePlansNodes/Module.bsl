///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2021, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Fills in an array of types that need to be annotated
// with links in the upload files when uploading.
//
// Parameters:
//  Types - Array of MetadataObject - metadata object.
//
Procedure OnFillTypesThatRequireRefAnnotationOnImport(Types) Export
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		Types.Add(ExchangePlan);
		
	EndDo;
	
EndProcedure

// for official use.
// Parameters:
//  HandlersTable - See ExportImportDataOverridable.OnRegisterDataExportHandlers.HandlersTable
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = ExchangePlan;
		NewHandler.Handler = ExportImportExchangePlansNodes;
		NewHandler.BeforeExportObject = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
			
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = ExchangePlan;
		NewHandler.Handler = ExportImportExchangePlansNodes;
		NewHandler.AfterExportObject = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
	
EndProcedure

// for official use.
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	NewDelimiterValues = New Structure;
	NewDelimiterValues.Insert(SaaSOperations.MainDataSeparator(), 0);
	NewDelimiterValues.Insert(SaaSOperations.AuxiliaryDataSeparator(), 0);
	
	FillPropertyValues(Object, NewDelimiterValues);
	
EndProcedure

// for official use.
//
Procedure AfterExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts) Export
	
	ObjectMetadata = Object.Metadata(); // MetadataObject
	
	If CommonCTL.IsExchangePlan(ObjectMetadata) Then
	
		ObjectExportManager.YouNeedToRecreateLinkWhenUploading(Object.Ref);
		
	Else
		
		Raise StrTemplate(
			NStr("vi = 'Hàm sự kiện
				|ВыгрузкаЗагрузкаУзловПлановОбменов.ПослеВыгрузкиОбъекта() không thể xử lý đối tượng metadata %1';
				|ru = 'Объект метаданных %1 не может быть обработан обработчиком
				|ВыгрузкаЗагрузкаУзловПлановОбменов.ПослеВыгрузкиОбъекта()';
				|en = 'The ExportImportExchangePlansNodes.AfterExportObject() handler
				|cannot process the %1 metadata object'; fa = 'The ExportImportExchangePlansNodes.AfterExportObject() handler
				|cannot process the %1 metadata object';
				|it = 'L''oggetto dei metadati %1 non può essere elaborato dal processore
				|ВыгрузкаЗагрузкаУзловПлановОбменов.ПослеВыгрузкиОбъекта()';
				|pl = 'Obiekt metadanych %1 nie może być przetworzony przez procedurę przetwarzania
				|ВыгрузкаЗагрузкаУзловПлановОбменов.ПослеВыгрузкиОбъекта()';
				|tr = '%1 meta veri nesnesi 
				|ВыгрузкаЗагрузкаУзловПлановОбменов.ПослеВыгрузкиОбъекта() işleyicisi tarafından işlenemez.'", Metadata.DefaultLanguage.LanguageCode),
			ObjectMetadata.FullName());
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function UploadRegisteredChangesForExchangePlanNodes(Container) Export
	
	ExportingParameters = Container.ExportingParameters();
	
	UploadRegisteredChangesForExchangePlanNodes = False;
	
	Return ExportingParameters.Property("UploadRegisteredChangesForExchangePlanNodes", UploadRegisteredChangesForExchangePlanNodes) And UploadRegisteredChangesForExchangePlanNodes = True;
	
EndFunction

Function TypesOfUploadedMetadataObjectExchangePlans(Container, MetadataObject)
	
	TypesOfUploadedExchangePlans = New Array;
	
	TypesToExport = Container.ExportingParameters().TypesToExport;
	TypesToExclude = ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload();
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If TypesToExport.Find(ExchangePlan) <> Undefined
			And TypesToExclude.Find(ExchangePlan) = Undefined
			And ExchangePlan.Content.Find(MetadataObject) <> Undefined Then
			
			TypesOfUploadedExchangePlans.Add(Type("ExchangePlanRef." + ExchangePlan.Name));
			
		EndIf;
		
	EndDo;
	
	Return TypesOfUploadedExchangePlans;
	
EndFunction

Procedure UploadChanges(Container, MetadataObject, Serializer) Export
	
	If Not UploadRegisteredChangesForExchangePlanNodes(Container) Then
		
		Return;
		
	EndIf;
	
	TypesOfUploadedExchangePlans = TypesOfUploadedMetadataObjectExchangePlans(Container, MetadataObject);
	
	If TypesOfUploadedExchangePlans.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	WriteStream = StartRecordingFile(Container, MetadataObject, Serializer);
		
	Query = New Query(
	"SELECT
	|	*
	|FROM
	|	#ChangesTable1 AS ChangesTable1
	|WHERE
	|	VALUETYPE(ChangesTable1.Node) IN (&TypesOfUploadedExchangePlans)");
	
	Query.Text = StrReplace(Query.Text, "#ChangesTable1", MetadataObject.FullName() + ".Changes");
	Query.SetParameter("TypesOfUploadedExchangePlans", TypesOfUploadedExchangePlans);
	
	QueryResult = Query.Execute();
	
	RecordingChange = New Structure;
	
	For Each Column In QueryResult.Columns Do
		
		RecordingChange.Insert(Column.Name);
		
	EndDo;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		FillPropertyValues(RecordingChange, Selection);
		WriteStream.WriteInformationDatabaseDataObject(RecordingChange, New Array);
		
	EndDo;
	
	CompleteFileRecording(Container, MetadataObject, WriteStream);
		
EndProcedure

Function StartRecordingFile(Container, MetadataObject, Serializer)
	
	FileName = Container.CreateFile(
		ExportImportDataInternal.InfobaseData(), MetadataObject.FullName());
	
	WriteStream = DataProcessors.ExportImportDataInfobaseDataWritingStream.Create();
	WriteStream.OpenFile(FileName, Serializer, ExportImportDataInternal.InfobaseDataChanges());
	
	Return WriteStream;
	
EndFunction

Procedure CompleteFileRecording(Container, MetadataObject,  WriteStream)
	
	WriteStream.Close();
	
	ObjectCount = WriteStream.ObjectCount();
	
	If ObjectCount = 0 Then
		
		Container.ExcludeFile(WriteStream.FileName());
	Else
		
		Container.SetNumberOfObjects(WriteStream.FileName(), ObjectCount);
		
	EndIf;
	
	WriteLogEvent(
		NStr("vi = 'ВыгрузкаЗагрузкаДанных.ВыгрузкаИзмененийОбъектаМетаданных';
			|ru = 'ВыгрузкаЗагрузкаДанных.ВыгрузкаИзмененийОбъектаМетаданных';
			|en = 'ExportImportData.ExportMetadataObjectChanges'; fa = 'ExportImportData.ExportMetadataObjectChanges';
			|it = 'ВыгрузкаЗагрузкаДанных.ВыгрузкаИзмененийОбъектаМетаданных';
			|pl = 'ExportImportData.ExportMetadataObjectChanges';
			|tr = 'ВыгрузкаЗагрузкаДанных.ВыгрузкаИзмененийОбъектаМетаданных'", Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		MetadataObject,
		,
		StrTemplate(NStr("vi = 'Hoàn thành kết xuất những thay đổi của đối tượng metadata: %1
		|Đã kết xuất: %2 đối tượng';
		|ru = 'Окончание выгрузки изменений объекта метаданных: %1
		|Выгружено объектов: %2';
		|en = 'Finish exporting metadata object changes: %1
		|Objects exported: %2'; fa = 'Finish exporting metadata object changes: %1
		|Objects exported: %2';
		|it = 'Fine upload delle modifiche dell''oggetto di metadati: %1
		|Oggetti caricati: %2';
		|pl = 'Koniec eksportu zmian obiektu metadanych: %1
		|Wyeksportowano obiektów: %2';
		|tr = 'Meta veri nesne değişiklikleri dışa aktarma tamamlandı: %1
		|Yüklenen nesneler: %2'", Common.DefaultLanguageCode()),
			MetadataObject.FullName(), ObjectCount));
	
EndProcedure

#EndRegion