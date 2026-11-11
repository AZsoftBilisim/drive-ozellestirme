
#Region Internal

// for official use.
// Parameters:
//	HandlersTable - See ExportImportDataOverridable.OnRegisterDataExportHandlers.HandlersTable	
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
				
	MetadataList = ProcessingTypesExcludedFromUploadCached.MetadataThatHasReferencesToTypesThatAreExcludedFromUnloadingAndNeedToBeProcessed();
		
	For Each ListItem In MetadataList Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Metadata.FindByFullName(ListItem.Key);
		NewHandler.Handler = ProcessingTypesExcludedFromUpload;
		NewHandler.BeforeExportObject = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
		
EndProcedure

// Called before the object is unloaded.
// See OnRegisterDataExportHandlers
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	MetadataObject = Object.Metadata();
	
	ItemDetailsThatHaveLinksToItemsExcludedFromUploading = ItemDetailsThatHaveLinksToItemsExcludedFromUploading(MetadataObject);
	
	If ItemDetailsThatHaveLinksToItemsExcludedFromUploading = Undefined Then
		
		Raise StrTemplate(
			NStr("vi = 'Hàm sự kiện %2 không thể xử lý đối tượng metadata %1!';
				|ru = 'Объект метаданных %1 не может быть обработан обработчиком %2!';
				|en = 'The %2 handler cannot process the %1 metadata object.'; fa = 'The %2 handler cannot process the %1 metadata object.';
				|it = 'L''oggetto dei metadati %1 non può essere elaborato dal processore %2.';
				|pl = 'Obiekt metadanych %1 nie może być przetworzony przez procedurę przetwarzania %2.';
				|tr = '%1 meta veri nesnesi %2 işleyicisi tarafından işlenemez!'"),
			MetadataObject.FullName(),
			"ProcessingTypesExcludedFromUpload.BeforeExportObject");
		
	EndIf;
	
	If CommonCTL.IsConstant(MetadataObject) Then
		
		BeforeUnloadingConstant(Object, Cancel);
		
	ElsIf CommonCTL.IsRefData(MetadataObject) Then
		
		BeforeUnloadingReferenceObject(Object, Cancel, ItemDetailsThatHaveLinksToItemsExcludedFromUploading);
		
	ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
		
		BeforeExportRecordSet(MetadataObject, Object, ItemDetailsThatHaveLinksToItemsExcludedFromUploading);
		
	Else
		
		Raise StrTemplate(
			NStr("vi = 'Đối tượng metadata không mong đợi: %1!';
				|ru = 'Неожиданный объект метаданных: %1!';
				|en = 'Unexpected metadata object: %1.'; fa = 'Unexpected metadata object: %1.';
				|it = 'Oggetto di metadati imprevisto: %1!';
				|pl = 'Nieoczekiwany obiekt metadanych: %1!';
				|tr = 'Beklenmedik meta veri nesnesi: %1!'"),
			MetadataObject.FullName);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure BeforeUnloadingConstant(Object, Cancel)
	
	ProcessReferenceToObjectToExcludeFromUploading(Object.Value, Cancel);
	
EndProcedure

Procedure BeforeUnloadingReferenceObject(Object, Cancel, ItemDetailsThatHaveLinksToItemsExcludedFromUploading)
	
	For Each CurrentAttribute In ItemDetailsThatHaveLinksToItemsExcludedFromUploading Do
		
		AttributeName = CurrentAttribute.AttributeName;

		If CurrentAttribute.TabularSectionName = Undefined Then
						
			ProcessReferenceToObjectToExcludeFromUploading(Object[AttributeName], Cancel);		
			
		Else
			
			TabularSectionName = CurrentAttribute.TabularSectionName;
			
			For Each LineOfATabularSection In Object[TabularSectionName] Do 
				
				ProcessReferenceToObjectToExcludeFromUploading(LineOfATabularSection[AttributeName], Cancel);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure BeforeExportRecordSet(MetadataObject, RecordSet, ItemDetailsThatHaveLinksToItemsExcludedFromUploading)
	
	ArrayOfPossibleDimensions = New Array;
	ArrayOfPossibleDimensions.Add("Recorder");
	
	If CommonCTL.IsAccountingRegister(MetadataObject) Then
		ArrayOfPossibleDimensions.Add("AccountDr");
		ArrayOfPossibleDimensions.Add("AccountCr");		
		ArrayOfPossibleDimensions.Add("Account");
	EndIf;

	For Each MetadataObjectDimension In MetadataObject.Dimensions Do
		ArrayOfPossibleDimensions.Add(MetadataObjectName(MetadataObjectDimension));
	EndDo;
		
	For Each CurrentAttribute In ItemDetailsThatHaveLinksToItemsExcludedFromUploading Do
		
		PropertyName = CurrentAttribute.AttributeName;
		SetOfRecordsInBoundary = RecordSet.Count() - 1;
		
		If SetOfRecordsInBoundary < 0 Then
			Break;
		EndIf;
		
		For IndexOfRecord = 0 To SetOfRecordsInBoundary Do
			
			Record = RecordSet[SetOfRecordsInBoundary - IndexOfRecord];
			
			Cancel = False;
			If ProcessReferenceToObjectToExcludeFromUploading(Record[PropertyName], Cancel)  Then
				If Cancel Or ArrayOfPossibleDimensions.Find(PropertyName) <> Undefined Then
					RecordSet.Delete(Record);
				EndIf;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function ProcessReferenceToObjectToExcludeFromUploading(Ref, Cancel)
	
	If Not ValueIsFilled(Ref) Or Not Common.IsReference(TypeOf(Ref)) Then
		Return False;
	EndIf;
	
	ActionsWhenLinksAreDetected = ProcessingTypesExcludedFromUploadCached.ActionsWhenFindingReferencesToTypesExcludedFromUnloading();
	RefMetadata = Ref.Metadata();
	
	Action = ActionsWhenLinksAreDetected.Get(RefMetadata);	
	If Action = Undefined Or Action = ExportImportData.ActionWithLinksDoNotChange() Then
		Return False;
	EndIf;
	
	If Action = ExportImportData.ActionWithClearLinks() Then
		Ref = Undefined;		
	ElsIf Action = ExportImportData.ActionWithLinksDoNotUnloadObject() Then
		Cancel = True;
	Else
		Raise StrTemplate(
			NStr("vi = 'Đã phát hiện thao tác không hỗ trợ ''%1'' khi tìm thấy tham chiếu đến kiểu ''%2'' bị loại trừ khi kết xuất';
				|ru = 'Обнаружено неподдерживаемое действие ''%1'' при обнаружении ссылки на тип ''%2'' исключаемый из выгрузки';
				|en = 'Unsupported action ''%1'' was detected when a reference to the ''%2 '' type to be excluded from the export was detected'; fa = 'Unsupported action ''%1'' was detected when a reference to the ''%2 '' type to be excluded from the export was detected';
				|it = 'È stata rilevata una azione non supportata ''%1'' al rilevamento del collegamento al tipo ''%2'' escluso dall''upload';
				|pl = 'Wykryto nieobsługiwaną czynność ''%1'' przy wykryciu odnośnika do typu ''%2'' wykluczanego z eksportu';
				|tr = 'Dışa aktarmadan çıkarılan ''%2'' türünün bağlantısı tespit edildiğinde desteklenmeyen ''%1'' eylemi tespit edildi'"),
			Action,
			RefMetadata);
	EndIf;
		
	Return True;
	
EndFunction

Function ItemDetailsThatHaveLinksToItemsExcludedFromUploading(Val ObjectMetadata)
	
	FullMetadataName = ObjectMetadata.FullName();
	
	MetadataList = ProcessingTypesExcludedFromUploadCached.MetadataThatHasReferencesToTypesThatAreExcludedFromUnloadingAndNeedToBeProcessed();
	
	Return MetadataList.Get(FullMetadataName);
	
EndFunction

// Returns the name of the metadata object.
// 
// Parameters:
// 	MetadataObject - MetadataObject - metadata object.
// Returns:
// 	String - the name of the metadata object.
Function MetadataObjectName(MetadataObject)
	
	Return MetadataObject.Name;
	
EndFunction

#EndRegion
