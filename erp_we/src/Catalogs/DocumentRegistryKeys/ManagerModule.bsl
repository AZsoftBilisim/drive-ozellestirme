#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Compliance with the list of details that determine the uniqueness of the key
// 
// Returns:
//   Map - the key is the name of the props 
//
Function KeyAttributes() Export
	
	Result = New Map;
	Result.Insert("Key");
	
	Return Result;
	
EndFunction

// Calculates which registry keys to create (update) and updates them
//
// Parameters:
//  MetadataObjects			 - Map	 - metadata objects:
//  	* Key		- MetadataObjectDocument	 - the object metadata of the document.
//  	* Value	- Undefined					- empty value.
//  ElementToUpdateKey	 - AnyRef - link to the reference list item to use to create or update the key
//                                               if a parameter is passed, the first parameter is ignored
//
Procedure CreateUpdateRegistryKeys(MetadataObjects = Undefined, ElementToUpdateKey = Undefined) Export
	
	If ElementToUpdateKey <> Undefined Then
		
		MetadataObjects = New Map;
		MetadataObjects.Insert(Metadata.FindByType(TypeOf(ElementToUpdateKey)));
		
	ElsIf MetadataObjects = Undefined Then
		
		MetadataObjects = MetadataObjectsEncodedInRegistryKeys();
		
	EndIf;
		
	SetPrivilegedMode(True);
		
	ThereAreKeysToGenerate = True;
	
	While ThereAreKeysToGenerate Do
		
		KeyTable_ = RegistryKeysToUpdate(MetadataObjects, True, ,ElementToUpdateKey);
		
		ThereAreKeysToGenerate = KeyTable_.Count() > 0; 
		
		If Not ThereAreKeysToGenerate Then
			Return;
		EndIf;
	
		BeginTransaction();
		
		Try
			
			If Not ExclusiveMode() Then
				// When working in non-monopoly mode, it is necessary to ensure that the
				// keys have not been changed in a parallel session.
				
				Block = New DataLock;
				
				LockItem = Block.Add("Catalog.DocumentRegistryKeys");
				LockItem.DataSource = KeyTable_;
				LockItem.UseFromDataSource("Key", "Key");
				LockItem.Mode = DataLockMode.Exclusive;
				
				Block.Lock();
				
			EndIf;
			
			Query = New Query;
			Query.Text = 
			"SELECT
			|	KeyTable_.Key AS Key,
			|	KeyTable_.Organization AS Organization,
			|	KeyTable_.TIN AS TIN,
			|	KeyTable_.Description AS Description
			|INTO KeyTable_
			|FROM
			|	&KeyTable_ AS KeyTable_
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	KeyTable_.Key AS Key,
			|	KeyTable_.Organization AS Organization,
			|	KeyTable_.TIN AS TIN,
			|	KeyTable_.Description AS Description,
			|	ISNULL(DocumentRegistryKeys.Ref, VALUE(Catalog.DocumentRegistryKeys.EmptyRef)) AS Ref
			|FROM
			|	KeyTable_ AS KeyTable_
			|		LEFT JOIN Catalog.DocumentRegistryKeys AS DocumentRegistryKeys
			|		ON KeyTable_.Key = DocumentRegistryKeys.Key
			|WHERE
			|	(DocumentRegistryKeys.Ref IS NULL
			|			OR KeyTable_.Organization <> DocumentRegistryKeys.Organization
			|			OR KeyTable_.TIN <> DocumentRegistryKeys.TIN
			|			OR KeyTable_.Description <> DocumentRegistryKeys.Description)";
			
			Query.SetParameter("KeyTable_", KeyTable_);
			
			ReferencesSelection = Query.Execute().Select();
			
			While ReferencesSelection.Next() Do
				
				If ValueIsFilled(ReferencesSelection.Ref) Then
					KeyObject = ReferencesSelection.Ref.GetObject();
				Else
					KeyObject = Catalogs.DocumentRegistryKeys.CreateItem();
				EndIf;
				
				FillPropertyValues(KeyObject, ReferencesSelection);
				KeyObject.Write();
			EndDo;
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			MessageText = NStr("vi = 'Không thể xử lý khóa đăng ký chứng từ: %Cause%';
								|ru = 'Не удалось обработать ключи реестра документов: %Cause%';
								|en = 'Cannot process document registry keys. Reason: %Cause%'; fa = 'Cannot process document registry keys. Reason: %Cause%';
								|it = 'Non è stato possibile elaborare le chiavi del registro di documenti: %Cause%';
								|pl = 'Przetwarzanie kluczy rejestru dokumentów nie powiodło się: %Cause%';
								|tr = 'Belge kayıt anahtarları işlenemedi: %Cause%'");
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(NStr("vi = 'Tạo khóa phân tích sổ đăng ký chứng từ';
								|ru = 'Создание ключей аналитики реестра документов';
								|en = 'Create dimension keys of document registry'; fa = 'Create dimension keys of document registry';
								|it = 'Creazione delle chiavi di analisi del registro di documenti';
								|pl = 'Tworzenie kluczy analityki rejestru dokumentów';
								|tr = 'Belge kayıt boyut anahtarları oluşturma'",CommonClientServer.DefaultLanguageCode()),
				EventLogLevel.Error,
				Metadata.Catalogs.DocumentRegistryKeys,
				,
				MessageText);
		
			Raise;
		EndTry;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Returns an indication that the directory element is included in the document registry keys,
// so you need to use it to create or update a technology directory element.
//
// Parameters:
//	Object - Arbitrary - a database object, for example, a reference object.Organizations.
//
// Returns:
//	Boolean - True if the received object is reflected in the document registry via a process key.
//
Function ObjectIsRegistryKey(Object) Export
	
	If Not ValueIsFilled(Object) Then
		Return False;
	ElsIf Not Common.IsCatalog(Object.Metadata()) Then
		Return False;
	EndIf;
	
	CatalogRef	= Object.Ref;
	RefType		= TypeOf(CatalogRef);
	
	KeyMetadata_	= Metadata.FindByFullName("Catalog.DocumentRegistryKeys");
	SourceTypes		= KeyMetadata_.Attributes.Key.Type.Types();
	
	ProcessObject = SourceTypes.Find(RefType) <> Undefined;
	
	Return ProcessObject;
	
EndFunction

// Function-metadata Objects cached in registry keys
// 
// Returns:
//  Map - the keys contain objects of the Data Object type.
//
Function MetadataObjectsEncodedInRegistryKeys() Export 
	MetadataObjects = New Map;
	
	For Each KeyType In Metadata.Catalogs.DocumentRegistryKeys.Attributes.Key.Type.Types() Do
		
		ObjectMetadata = Metadata.FindByType(KeyType);
		MetadataObjects.Insert(ObjectMetadata);
		
	EndDo;
	
	Return MetadataObjects;
	
EndFunction

// Retrieves registry keys by reference values
//
// Parameters:
//    Values - Array, Arbitrary - link(s) in reference databases, for example, Spravochniki.Warehouse.
// 
// Returns:
//    Array - registry keys
//
Function KeysByValue(Values) Export
	
	Query = New Query("
	|SELECT
	|	Ref
	|FROM
	|	Catalog.DocumentRegistryKeys
	|WHERE
	|	Key IN (&Keys)
	|");
	
	Query.SetParameter("Keys", Values);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Finds duplicates of document registry keys and deletes them. 
// This deletes the document registry entries. If there is a key that
// was not recorded in the registry, but there were deleted keys, then the records are restored
// with the "correct" keys.
//
Procedure FindAndDeleteDuplicates() Export
	
	QueryResult = DuplicateKeys(True);
	DeleteDuplicates(QueryResult, False);
	
EndProcedure

#Region InterfaceImplementation

// Called when replacing duplicates in the Attributes of elements.
//
// Parameters:
//  ReplacementPairs - Map - contains the original and duplicate value pairs.
//  UnprocessedOriginalsValues - Array of Structure:
//    * ValueToReplace - AnyRef - the original value of the object being replaced.
//    * UsedLinks - See Common.SubordinateObjectsLinksByTypes
//    * KeyAttributesValue - Structure - Key - name of the item, value-value of the item.
//
Procedure OnSearchForReferenceReplacement(ReplacementPairs, UnprocessedOriginalsValues) Export
	
	For Each UnprocessedDuplicate In UnprocessedOriginalsValues Do
		
		ParametersOfKey = New Structure;
		For Each KeyAttribute In UnprocessedDuplicate.KeyAttributesValue Do
			ValueOfOriginal = ReplacementPairs.Get(KeyAttribute.Value);
			ParametersOfKey.Insert(KeyAttribute.Key, ?(ValueOfOriginal = Undefined, KeyAttribute.Value, ValueOfOriginal));
		EndDo;
		Catalogs.DocumentRegistryKeys.CreateUpdateRegistryKeys(, ParametersOfKey.Key);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function RegistryKeysToUpdate(MetadataObjects, InPortions, BlankRefs = "IncludeAll", ElementToUpdateKey = Undefined)

	QueryText =
	QueryTextTTObjectData_(MetadataObjects) +
	"SELECT &InPortions,
	|	NestedQuery.Key AS Key,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.TIN AS TIN,
	|	NestedQuery.Description AS Description,
	|	SUM(NestedQuery.Control) AS Control
	|FROM
	|	(SELECT
	|		ObjectData_.Key AS Key,
	|		ObjectData_.Organization AS Organization,
	|		ObjectData_.TIN AS TIN,
	|		ObjectData_.Description AS Description,
	|		1 AS Control,
	|		ISNULL(DocumentRegistryKeys.Ref, VALUE(Catalog.DocumentRegistryKeys.EmptyRef)) AS KeyRef
	|	FROM
	|		ObjectData_ AS ObjectData_
	|			LEFT JOIN Catalog.DocumentRegistryKeys AS DocumentRegistryKeys
	|			ON (DocumentRegistryKeys.Key = ObjectData_.Key)
	|	WHERE
	|	    &WithoutSelectionByLink
	|	    OR ObjectData_.Key = &ElementToUpdateKey 
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegistryKeys.Key,
	|		DocumentRegistryKeys.Organization,
	|		DocumentRegistryKeys.TIN,
	|		DocumentRegistryKeys.Description,
	|		-1,
	|		DocumentRegistryKeys.Ref
	|	FROM
	|		Catalog.DocumentRegistryKeys AS DocumentRegistryKeys
	|	WHERE
	|	    &WithoutSelectionByLink
	|	    OR DocumentRegistryKeys.Key = &ElementToUpdateKey) AS NestedQuery 
	|
	|GROUP BY
	|	NestedQuery.Organization,
	|	NestedQuery.Key,
	|	NestedQuery.Description,
	|	NestedQuery.TIN
	|
	|HAVING
	|	SUM(NestedQuery.Control) > 0";
	
	If InPortions Then
		QueryText = StrReplace(QueryText, "&InPortions,", "TOP 1000");
	Else
		QueryText = StrReplace(QueryText, "&InPortions,", "");
	EndIf;
	
	Query = New Query;
	
	If ElementToUpdateKey = Undefined Then
		Query.SetParameter("IncludeNotEmpty", BlankRefs = "IncludeAll" Or BlankRefs = "IncludeNotEmpty");
		Query.SetParameter("IncludeBlank", BlankRefs = "IncludeAll" Or BlankRefs = "IncludeBlank");
	Else
		Query.SetParameter("IncludeNotEmpty", True);
		Query.SetParameter("IncludeBlank", False);
	EndIf;	
		
	Query.SetParameter("WithoutSelectionByLink", ElementToUpdateKey = Undefined);
	Query.SetParameter("ElementToUpdateKey", ElementToUpdateKey);
	Query.Text = QueryText;
	
	KeyTable_ = Query.Execute().Unload();
	
	Return KeyTable_;
		
EndFunction

Function QueryTextTTObjectData_(MetadataObjects)
	QueryTexts = New Array;
	
	If TypeOf(MetadataObjects) = Type("Map") Then
		
		For Each ObjectDetails In MetadataObjects Do
			QueryText = TextOfCatalogDataRequest(ObjectDetails.Key);
			QueryTexts.Add(QueryText);
		EndDo;
		
		MergeQueryTemplate = "
		|
		|UNION ALL
		|
		|";
		
		QueryTextByObjects = StrConcat(QueryTexts, MergeQueryTemplate);
		
	ElsIf TypeOf(MetadataObjects) = Type("MetadataObject") Then	
		
		QueryTextByObjects = TextOfCatalogDataRequest(MetadataObjects);
		
	Else
		
		ExceptionText = NStr("vi = 'Chức năng không hỗ trợ kiểu %Type%';
							|ru = 'Тип %Type% не поддерживается функцией';
							|en = 'The %Type% type is not supported by the function'; fa = 'The %Type% type is not supported by the function';
							|it = 'Il tipo %Type% non viene supportato dalla funzione';
							|pl = 'Typ %Type% nie jest obsługiwany przez funkcję';
							|tr = '%Type% tipi fonksiyon ile desteklenmiyor'");
		ExceptionText = StrReplace(ExceptionText, "%Type%", String(TypeOf(MetadataObjects)));
		
		Raise ExceptionText;
		
	EndIf;
		
	QueryText = 
	"SELECT
	|	NestedQuery.Key AS Key,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.TIN AS TIN,
	|	NestedQuery.Description AS Description
	|INTO ObjectData_
	|FROM
	|	&QueryTextByObjects AS NestedQuery
	|INDEX BY Key
	|;";
	
	QueryText = StrReplace(QueryText, "&QueryTextByObjects", "(" + QueryTextByObjects + ")");
	
	Return QueryText;
	
EndFunction

Function TextOfCatalogDataRequest(MetadataObject)
	QueryTextTemplate2 =
	"SELECT
	|		CatalogSource.Ref AS Key,
	|		&TextOfOrganizationField AS Organization,
	|		&TinFieldText AS TIN,
	|		CatalogSource.Description AS Description
	|	FROM
	|		FullObjectName AS CatalogSource
	|	WHERE
	|		&IncludeNotEmpty
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VALUE(FullObjectName.EmptyRef),
	|		VALUE(Catalog.Companies.EmptyRef),
	|		"""",
	|		""""
	|	WHERE
	|		&IncludeBlank";
				
	QueryText = StrReplace(QueryTextTemplate2, "FullObjectName", MetadataObject.FullName());
	
	ThereIsOwnerOrganization = False;
	
	For Each Attribute In MetadataObject.StandardAttributes Do
		If Attribute.Name = "Owner" Then
			
			If Attribute.Type.AdjustValue() = Catalogs.Companies.EmptyRef() Then
				ThereIsOwnerOrganization = True;
			EndIf;
			
			Break;
		EndIf;
	EndDo;
	
	If ThereIsOwnerOrganization Then
		QueryText = StrReplace(QueryText, "&TextOfOrganizationField", "CatalogSource.Owner");
	Else
		QueryText = StrReplace(QueryText, "&TextOfOrganizationField", "VALUE(Catalog.Companies.EmptyRef)");
	EndIf;
	
	If MetadataObject.Attributes.Find("TIN") <> Undefined Then
		QueryText = StrReplace(QueryText, "&TinFieldText", "ISNULL(CatalogSource.TIN,"""")");
	Else
		QueryText = StrReplace(QueryText, "&TinFieldText", """""");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function DuplicateKeys(KeyResults)
	Query = New Query;
	
	QueryText = 	
	"SELECT
	|	DocumentRegistryKeys.Key AS Key,
	|	SUM(1) AS Control
	|INTO TTDoubles
	|FROM
	|	Catalog.DocumentRegistryKeys AS DocumentRegistryKeys
	|
	|GROUP BY
	|	DocumentRegistryKeys.Key
	|
	|HAVING
	|	SUM(1) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentRegistryKeys.Ref AS Ref,
	|	DocumentRegistryKeys.Key AS Key
	|FROM
	|	TTDoubles AS TTDoubles
	|		INNER JOIN Catalog.DocumentRegistryKeys AS DocumentRegistryKeys
	|		ON TTDoubles.Key = DocumentRegistryKeys.Key";
	
	If KeyResults Then
		QueryText = 	QueryText + "
		|
		|ORDER BY
		|	Key,
		|	Ref
		|TOTALS BY
		|	Key";
	EndIf;
	
	Query.Text = QueryText;
	
	Return Query.Execute();
EndFunction

Procedure DeleteDuplicates(QueryResult, ThisIsIBUpdate)
	
	Query = New Query;
	Query.SetParameter("ThisIsIBUpdate", ThisIsIBUpdate);
	Query.Text =
	"SELECT
	|	Ref AS Ref,
	|	TRUE AS RecordRemains
	|INTO DocumentsTable
	|FROM
	|	InformationRegister.DocumentsRegistry
	|WHERE
	|	&RemainingKey IN (StorageLocation, Counterparty)
	|
	|UNION
	|
	|SELECT
	|	Ref,
	|	FALSE
	|FROM
	|	InformationRegister.DocumentsRegistry
	|WHERE
	|	StorageLocation IN (&KeysToDelete)
	|	OR Counterparty IN (&KeysToDelete)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Ref AS Ref,
	|	Ref REFS Document.ReversingEntry AS ThisIsReverseTransaction,
	|	1 AS Order,
	|	MAX(RecordRemains) AS RecordRemains
	|FROM
	|	DocumentsTable
	|GROUP BY
	|	Ref,
	|	Ref REFS Document.ReversingEntry
	|HAVING
	|	MAX(RecordRemains) = FALSE
	|	OR &ThisIsIBUpdate
	|
	|UNION
	|
	|SELECT
	|	Ref,
	|	Ref REFS Document.ReversingEntry,
	|	2,
	|	FALSE
	|FROM
	|	InformationRegister.DocumentsRegistry
	|WHERE
	|	NOT AdditionalRecord
	|GROUP BY
	|	Ref,
	|	Ref REFS Document.ReversingEntry
	|HAVING
	|	COUNT(*) > 1
	|
	|ORDER BY
	|	Order,
	|	ThisIsReverseTransaction";
	
	SelectingKeys = QueryResult.Select(QueryResultIteration.ByGroups);
	While SelectingKeys.Next() Do
		
		SelectionByRefs = SelectingKeys.Select(QueryResultIteration.ByGroups);
		
		BeginTransaction();
		
		Try
			
			FirstLink = True;
			RemainingKey = Undefined;
			KeysToDelete = New Array;
			
			While SelectionByRefs.Next() Do
				
				If ThisIsIBUpdate Then
					InfobaseUpdate.MarkProcessingCompletion(SelectionByRefs.Ref);
				EndIf;
				
				If FirstLink Then
					RemainingKey = SelectionByRefs.Ref;
					FirstLink = False;
				Else
					KeysToDelete.Add(SelectionByRefs.Ref);
				EndIf;
				
			EndDo;
			
			Query.SetParameter("RemainingKey", RemainingKey);
			Query.SetParameter("KeysToDelete", KeysToDelete);
			
			DocumentsForReReflection = Query.Execute().Select();
			
			For Each KeyToDelete In KeysToDelete Do
				
				KeyObject = KeyToDelete.GetObject();
				
				SetPrivilegedMode(True);
				KeyObject.Delete();
				SetPrivilegedMode(False);
				
			EndDo;
			
			While DocumentsForReReflection.Next() Do
				
				RecordSet = InformationRegisters.DocumentsRegistry.CreateRecordSet();
				RecordSet.Filter.Ref.Set(DocumentsForReReflection.Ref);
				
				If DocumentsForReReflection.RecordRemains Then
					
					If ThisIsIBUpdate Then
						InfobaseUpdate.MarkProcessingCompletion(RecordSet);
					EndIf;
					
				Else
					
					SetPrivilegedMode(True);
					
					DataTables = DocumentsPosting.DocumentDataForPosting(
						DocumentsForReReflection.Ref,
						"DocumentsRegistry"
					);
					RecordSet.UploadWithProcessing(DataTables["Table" + "DocumentsRegistry"]);
					
					If ThisIsIBUpdate Then
						InfobaseUpdate.WriteData(RecordSet);
						Queue = InfobaseUpdate.DeferredUpdateHandlerQueue(
						"InformationRegisters.DocumentsRegistry.ProcessDataForMigrationToNewVersion");
						If Queue <> Undefined Then
							InfobaseUpdate.MarkProcessingCompletion(RecordSet,, Queue);
						EndIf;
					Else
						RecordSet.Write();
					EndIf;
					
					SetPrivilegedMode(False);
					
					If ThisIsIBUpdate Then		
						InfobaseUpdate.MarkProcessingCompletion(RecordSet,,
							InfobaseUpdate.DeferredUpdateHandlerQueue(
								"InformationRegisters.DocumentsRegistry.ProcessDataForMigrationToNewVersion"
							)
						);
					EndIf;
					
				EndIf;
				
			EndDo;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xóa phần tử trùng lặp khóa sổ đăng ký văn bản %1 do nguyên nhân: %2';
					|ru = 'Не удалось удалить дубли ключа реестра документов %1 по причине: %2';
					|en = 'Cannot delete duplicates of the %1 document registry key. Reason: %2'; fa = 'Cannot delete duplicates of the %1 document registry key. Reason: %2';
					|it = 'Не удалось удалить дубли ключа реестра документов %1 по причине: %2';
					|pl = 'Cannot delete duplicates of the %1 document registry key. Reason: %2';
					|tr = '%2 nedeniyle kayıt anahtarı belge %1 kopyalarını silinemedi'"),
				SelectingKeys.Key,
				DetailErrorDescription(ErrorInfo())
			);
			
			If ThisIsIBUpdate Then
				LogEvent = InfobaseUpdate.EventLogEvent();
			Else
				LogEvent = NameOfDuplicateDeletionLogEvent();
			EndIf;
			
			WriteLogEvent(LogEvent,
				EventLogLevel.Warning,
				SelectingKeys.Key.Metadata(),
				SelectingKeys.Key,
				MessageText
			);
			
		EndTry;
	
	EndDo;
	
EndProcedure

Function NameOfDuplicateDeletionLogEvent() Export
	
	Return NStr("vi = 'Xóa khóa đăng ký chứng từ';
				|ru = 'Удаление ключей реестра документов';
				|en = 'Delete document registry keys'; fa = 'Delete document registry keys';
				|it = 'Eliminazione delle chiavi del registro di documenti';
				|pl = 'Usunięcie kluczy rejestru dokumentów';
				|tr = 'Belge kayıt anahtarlarını silme'", CommonClientServer.DefaultLanguageCode());	
	
EndFunction

Function ThereAreDuplicates() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	DocumentRegistryKeys.Key AS Key,
	|	SUM(1) AS Validation
	|FROM
	|	Catalog.DocumentRegistryKeys AS DocumentRegistryKeys
	|
	|GROUP BY
	|	DocumentRegistryKeys.Key
	|
	|HAVING
	|	SUM(1) > 1";
	
	SetPrivilegedMode(True);
	ThereAreDuplicates = Not Query.Execute().IsEmpty();

	If ThereAreDuplicates Then
		If StandardSubsystemsCached.DIBUsed() Then
			If Common.IsSubordinateDIBNode() Then
				Return "ThereAreDuplicatesInSubordinateNodeRib";
			Else
				Return "ThereAreDuplicatesInMainRibNode";
			EndIf;
		Else
			Return "ThereAreDuplicatesInMainRibNode";
		EndIf;
	Else
		Return "None";
	EndIf;
	
	SetPrivilegedMode(False);

EndFunction

Function ThereAreKeysToGenerate() Export
	
	MetadataObjects = MetadataObjectsEncodedInRegistryKeys();
	SetPrivilegedMode(True);
	ThereAreKeysToGenerate = RegistryKeysToUpdate(MetadataObjects, True).Count() > 0; 
	SetPrivilegedMode(False);
	
	If ThereAreKeysToGenerate Then
		If StandardSubsystemsCached.DIBUsed() Then
			If Common.IsSubordinateDIBNode() Then
				Return "ThereAreElementsWithoutKeysInSubordinateNodeRib";
			Else
				Return "ThereAreElementsWithoutKeysInMainRibNode";
			EndIf;
		Else
			Return "ThereAreElementsWithoutKeysInMainRibNode";
		EndIf;
	Else
		Return "None";
	EndIf;

EndFunction

Function ResultOfBackgroundTasks()
	                                       
	Result = New Structure();
	Result.Insert("ThereAreDuplicates");
	Result.Insert("ThereAreItemsOfDirectoriesWithoutKeys");
	Result.Insert("ThereAreDocumentsForRemirrorInTheRegistry");
	
	Return Result;
	
EndFunction

Procedure FindAndDeleteDuplicatesInListForm(Parameters, TempStorageAddress) Export
	
	If Not InfobaseUpdate.DataProcessingCompleted(Undefined, "InformationRegister.DocumentsRegistry") Then
		ExceptionText = NStr("vi = 'Có xử lý cập nhật nổi bật trong sổ đăng ký chứng từ. Trước khi bắt đầu thủ tục, bạn phải đợi cho đến khi kết thúc thực hiện chúng.';
							|ru = 'По реестру документов есть невыполненные обработчики обновления. Перед запуском процедуры необходимо дождаться окончания их выполнения.';
							|en = 'There are incomplete update handlers in the document registry. Before run the procedure, you need to wait until the end of their execution.'; fa = 'There are incomplete update handlers in the document registry. Before run the procedure, you need to wait until the end of their execution.';
							|it = 'Per registro dei documenti ci sono gestori di aggiornamento non eseguiti. Prima di avviare una procedura è necessario attendere il termine della loro esecuzione.';
							|pl = 'W rejestrze dokumentów są niewykonane procedury przetwarzania aktualizacji. Przed uruchomieniem należy doczekać się zakończenia ich wykonania.';
							|tr = 'Belge kaydında tamamlanmayan güncelleme işleyicileri var. Prosedüre başlamadan önce, gerçekleştirmenin tamamlanmasını beklemek gerekir.'");
	    Raise ExceptionText;
	EndIf;

	Result = ResultOfBackgroundTasks();
	
	FindAndDeleteDuplicates();
	
	If ThereAreDuplicates() <> "None" Then
		Result.ThereAreDuplicates = "Error";
	Else
		Result.ThereAreDuplicates = "None";
	EndIf;	
	
	PutToTempStorage(Result, TempStorageAddress);
	
EndProcedure

Procedure CreateKeysInListForm(Parameters, TempStorageAddress) Export
	
	If Not InfobaseUpdate.DataProcessingCompleted(Undefined, "InformationRegister.DocumentsRegistry") Then
		ExceptionText = NStr("vi = 'Có xử lý cập nhật nổi bật trong sổ đăng ký chứng từ. Trước khi bắt đầu thủ tục, bạn phải đợi cho đến khi kết thúc thực hiện chúng.';
							|ru = 'По реестру документов есть невыполненные обработчики обновления. Перед запуском процедуры необходимо дождаться окончания их выполнения.';
							|en = 'There are incomplete update handlers in the document registry. Before run the procedure, you need to wait until the end of their execution.'; fa = 'There are incomplete update handlers in the document registry. Before run the procedure, you need to wait until the end of their execution.';
							|it = 'Per registro dei documenti ci sono gestori di aggiornamento non eseguiti. Prima di avviare una procedura è necessario attendere il termine della loro esecuzione.';
							|pl = 'W rejestrze dokumentów są niewykonane procedury przetwarzania aktualizacji. Przed uruchomieniem należy doczekać się zakończenia ich wykonania.';
							|tr = 'Belge kaydında tamamlanmayan güncelleme işleyicileri var. Prosedüre başlamadan önce, gerçekleştirmenin tamamlanmasını beklemek gerekir.'");
	    Raise ExceptionText;
	EndIf;
	
	Result = ResultOfBackgroundTasks();
	
	CreateUpdateRegistryKeys();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentsRegistry.Ref AS Ref
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.Posted
	|	AND DocumentsRegistry.StorageLocation = VALUE(Catalog.DocumentRegistryKeys.EmptyRef)";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		Cancel = False;
		Try
			DataTables = DocumentsPosting.DocumentDataForPosting(Selection.Ref, "DocumentsRegistry");
			InformationRegisters.DocumentsRegistry.WriteData(
				DataTables,
				Selection.Ref,
				Undefined,
				Cancel);
		Except
			WriteLogEvent(NStr("vi = 'Phản ánh lại chứng từ trong sổ đăng ký chứng từ';
								|ru = 'Переотражение документов в реестре документов';
								|en = 'Re-recording documents in documents registry'; fa = 'Re-recording documents in documents registry';
								|it = 'Nuovo rilevamento dei documenti nel registro dei documenti';
								|pl = 'Ponowne odzwierciedlenie dokumentów w rejestrze dokumentów';
								|tr = 'Belge kaydında belgelerin yeniden yansıtılması'",CommonClientServer.DefaultLanguageCode()),
				EventLogLevel.Error,
				Metadata.InformationRegisters.DocumentsRegistry,
				Selection.Ref,
				DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndDo;
	
	If ThereAreKeysToGenerate() <> "None" Then  
		Result.ThereAreItemsOfDirectoriesWithoutKeys = "Error";
	Else
		Result.ThereAreItemsOfDirectoriesWithoutKeys = "None";
	EndIf;
	
	PutToTempStorage(Result, TempStorageAddress);
	
EndProcedure

Procedure CheckNeedToReReflectDocumentsInRegistry(Parameters, TempStorageAddress) Export
	
	Types = InformationRegisters.DocumentsRegistry.TypesOfRegistryDocuments();
	HasErrors = False;
	
	For Each DocumentType In Types Do
		
		FullDocumentName = Metadata.FindByType(DocumentType).FullName();
		
		UnusedFields = New Array;
		UnusedFields.Add("More");
		UnusedFields.Add("RecordSeparator");
		UnusedFields.Add("SourceDocumentNumber");
		UnusedFields.Add("RecordID");
		
		SetPrivilegedMode(True);
		
		DocumentName = StrSplit(FullDocumentName, ".")[1];
		ResultOfRequestAdaptation = Documents[DocumentName].AdaptedCaseSensitiveQueryText("DocumentsRegistry");
		Recorders = InfobaseUpdateTM.IndependentRegisterDataForRecheck(
							ResultOfRequestAdaptation, 
							"InformationRegister.DocumentsRegistry", 
							FullDocumentName, 
							UnusedFields);
		
		SetPrivilegedMode(False);
							
		If Recorders.Count() > 0 Then
			HasErrors = True;						
		 	Break;
		EndIf;
		
	EndDo;
	
	Result = ResultOfBackgroundTasks();
	
	If HasErrors Then
		Result.ThereAreDocumentsForRemirrorInTheRegistry = "Is";
	Else
		Result.ThereAreDocumentsForRemirrorInTheRegistry = "None";
	EndIf;
	
	PutToTempStorage(Result, TempStorageAddress);
	
EndProcedure

Procedure FixErrorsInReflectingDocumentsInRegistry(Parameters, TempStorageAddress) Export
	
	If Not InfobaseUpdate.DataProcessingCompleted(Undefined, "InformationRegister.DocumentsRegistry") Then
		ExceptionText = NStr("vi = 'Có xử lý cập nhật nổi bật trong sổ đăng ký chứng từ. Trước khi bắt đầu thủ tục, bạn phải đợi cho đến khi kết thúc thực hiện chúng.';
							|ru = 'По реестру документов есть невыполненные обработчики обновления. Перед запуском процедуры необходимо дождаться окончания их выполнения.';
							|en = 'There are incomplete update handlers in the document registry. Before run the procedure, you need to wait until the end of their execution.'; fa = 'There are incomplete update handlers in the document registry. Before run the procedure, you need to wait until the end of their execution.';
							|it = 'Per registro dei documenti ci sono gestori di aggiornamento non eseguiti. Prima di avviare una procedura è necessario attendere il termine della loro esecuzione.';
							|pl = 'W rejestrze dokumentów są niewykonane procedury przetwarzania aktualizacji. Przed uruchomieniem należy doczekać się zakończenia ich wykonania.';
							|tr = 'Belge kaydında tamamlanmayan güncelleme işleyicileri var. Prosedüre başlamadan önce, gerçekleştirmenin tamamlanmasını beklemek gerekir.'");
		Raise ExceptionText;
	EndIf;
	
	Types = InformationRegisters.DocumentsRegistry.TypesOfRegistryDocuments();
	HasErrors = False;
	
	For Each DocumentType In Types Do
		
		FullDocumentName = Metadata.FindByType(DocumentType).FullName();
		
		UnusedFields = New Array;
		UnusedFields.Add("More");
		UnusedFields.Add("RecordSeparator");
		UnusedFields.Add("SourceDocumentNumber");
		UnusedFields.Add("RecordID");
		
		SetPrivilegedMode(True);
		
		DocumentName = StrSplit(FullDocumentName, ".")[1];
		ResultOfRequestAdaptation = Documents[DocumentName].AdaptedCaseSensitiveQueryText("DocumentsRegistry");
		DocumentRegistryData = InfobaseUpdateTM.IndependentRegisterDataForRecheck(
									ResultOfRequestAdaptation,
									"InformationRegister.DocumentsRegistry",
									FullDocumentName,
									UnusedFields);
		Recorders = DocumentRegistryData.UnloadColumn("Ref");
		
		For Each Recorder In Recorders Do
			
			Cancel = False;
			
			Try
				DataTables = DocumentsPosting.DocumentDataForPosting(Recorder, "DocumentsRegistry");
				InformationRegisters.DocumentsRegistry.WriteData(
					DataTables,
					Recorder,
					Undefined,
					Cancel);
				If Cancel Then
					HasErrors = True;
				EndIf;
			Except
				HasErrors = True;
				WriteLogEvent(NStr("vi = 'Phản ánh lại chứng từ trong sổ đăng ký chứng từ';
									|ru = 'Переотражение документов в реестре документов';
									|en = 'Re-recording documents in documents registry'; fa = 'Re-recording documents in documents registry';
									|it = 'Nuovo rilevamento dei documenti nel registro dei documenti';
									|pl = 'Ponowne odzwierciedlenie dokumentów w rejestrze dokumentów';
									|tr = 'Belge kaydında belgelerin yeniden yansıtılması'",CommonClientServer.DefaultLanguageCode()),
					EventLogLevel.Error,
					Metadata.InformationRegisters.DocumentsRegistry,
					Recorder,
					DetailErrorDescription(ErrorInfo()));
			EndTry;;
			
		EndDo;
		
		SetPrivilegedMode(False);
		
	EndDo;
	
	If HasErrors Then
		Result = ResultOfBackgroundTasks();
		Result.ThereAreDocumentsForRemirrorInTheRegistry = "Error";
		PutToTempStorage(Result, TempStorageAddress);
	Else
		CheckNeedToReReflectDocumentsInRegistry(Parameters, TempStorageAddress);
	EndIf;
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)

	If Data.Description = "" Then
		StandardProcessing = False;
		Presentation = "";
	EndIf;

EndProcedure

#Region InfobaseUpdate

#EndRegion

#EndRegion

#EndIf
