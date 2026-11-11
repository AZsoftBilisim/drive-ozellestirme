///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Not MobileStandaloneServer Then

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	AttributesToEdit = New Array;
	
	Return AttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// CloudTechnology.ExportImportData

// Returns the catalog attributes that naturally form a catalog item key.
//
// Returns:
//  Array of String - Array of attribute names used to generate a natural key.
//
Function NaturalKeyFields() Export
	
	Result = New Array;
	Result.Add("FullName");
	
	Return Result;
	
EndFunction

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing) Export
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Description");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing) Export
	
	If Not ValueIsFilled(Data.Ref) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Presentation = StandardSubsystemsCached.MetadataObjectIDPresentation(Data.Ref);
#Else
	Presentation = StandardSubsystemsClientCached.MetadataObjectIDPresentation(Data.Ref);
#EndIf
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Parameters:
//  SessionParametersNames - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(SessionParametersNames, SpecifiedParameters) Export
	
	If SessionParametersNames.Find("UpdateIDCatalogs") = Undefined Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("MetadataObjectIDs", False);
	Result.Insert("ExtensionObjectIDs", False);
	Result.Insert("UpdateInProgress", False);
	
	SessionParameters.UpdateIDCatalogs = New FixedStructure(Result);
	
	SpecifiedParameters.Add("UpdateIDCatalogs");
	
EndProcedure

// For internal use only.
Procedure CheckForUsage(ExtensionsObjects = False) Export
	
	If StandardSubsystemsCached.DisableMetadataObjectsIDs() Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Danh mục ""%1"" không được sử dụng.';
				|ru = 'Справочник ""%1"" не используется.';
				|en = 'The ""%1"" catalog is not used.'; fa = 'The ""%1"" catalog is not used.';
				|it = 'Il manuale ""%1"" non viene utilizzato.';
				|pl = 'Katalog ""%1"" nie jest używany.';
				|tr = 'Katalog ""%1"" kullanılmamaktadır.'"), CatalogDescription(ExtensionsObjects));
		Raise ErrorText;
	EndIf;
	
	If ExtensionsObjects And Not Common.SeparatedDataUsageAvailable() Then
		ErrorText = ExtensionObjectsIDsUnvailableInSharedModeErrorDescription();
		Raise ErrorText;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If ExchangePlans.MasterNode() = Undefined
	   And ValueIsFilled(Common.ObjectManagerByFullName("Constant.MasterNode").Get()) Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể sử dụng danh mục ""%1"" trong cơ sở thông tin
			           |,đồng thời hủy bỏ nút chính mà không xác nhận.
			           |
			           |Để khôi phục kết nối với nút chính, hãy khởi chạy 1C:Enterprise và nhấn vào nút Khôi phục 
					   |hoặc thiết lập nút chính theo chương trình mà được chỉ ra trong hằng Nút chính.
			           |
			           |Để xác nhận việc hủy kết nối với nút chính 
					   |, hãy khởi chạy 1C:Enterprise và nhấn vào nút Tắt 
					   | hoặc xóa hằng Nút chính theo chương trình.';
					   |ru = 'Справочник ""%1"" не может использоваться
					   |в информационной базе с неподтвержденной отменой главного узла.
					   |
					   |Для восстановления связи с главным узлом запустите 1С:Предприятие и нажмите кнопку Восстановить 
					   |или программно установите главный узел, указанный в константе Главный узел.
					   |
					   |Для подтверждения отмены связи с главным узлом 
					   |запустите 1С:Предприятие и нажмите кнопку Отключить 
					   |или программно очистите константу Главный узел.';
					   |en = 'Cannot use the ""%1"" catalog in an infobase whose
					   |master node disconnection was not confirmed.
					   |
					   |To reconnect with the master node, run 1C:Enterprise and click ""Restore"".
					   |Alternatively, set the master node programmatically in the ""Master node"" constant.
					   |
					   |To confirm the disconnection,
					   |run 1C:Enterprise and click ""Disconnect"".
					   |Alternatively, programmatically clear the value of the ""Master node"" constant.'; fa = 'Cannot use the ""%1"" catalog in an infobase whose
			           |master node disconnection was not confirmed.
			           |
			           |To reconnect with the master node, run 1C:Enterprise and click ""Restore"".
			           |Alternatively, set the master node programmatically in the ""Master node"" constant.
			           |
			           |To confirm the disconnection,
			           |run 1C:Enterprise and click ""Disconnect"".
			           |Alternatively, programmatically clear the value of the ""Master node"" constant.';
					   |it = 'Справочник ""%1"" не может использоваться
					   |в информационной базе с неподтвержденной отменой главного узла.
					   |
					   |Для восстановления связи с главным узлом запустите 1С:Предприятие и нажмите кнопку Восстановить 
					   |или программно установите главный узел, указанный в константе Главный узел.
					   |
					   |Для подтверждения отмены связи с главным узлом 
					   |запустите 1С:Предприятие и нажмите кнопку Отключить 
					   |или программно очистите константу Главный узел.';
					   |pl = 'Cannot use the ""%1"" catalog in an infobase whose
					   |master node disconnection was not confirmed.
					   |
					   |To reconnect with the master node, run 1C:Enterprise and click ""Restore"".
					   |Alternatively, set the master node programmatically in the ""Master node"" constant.
					   |
					   |To confirm the disconnection,
					   |run 1C:Enterprise and click ""Disconnect"".
					   |Alternatively, programmatically clear the value of the ""Master node"" constant.';
					   |tr = 'Ana düğüm ayrılmasının doğrulanmadığı Infobase''de
					   |""%1"" kataloğu kullanılamaz.
					   |
					   |Infobase''i master düğüme geri eklemek için 1C:Enterprise''ı çalıştırıp,
					   |""Ekle""ye tıklayın veya master düğümü programlamayla ayarlayın
					   |(""Master düğüm"" sabitinde bulunur).
					   |
					   |Master düğüm ayrılmasını doğrulamak için 1C:Enterprise''ı çalıştırıp,
					   |""Ayır""a tıklayın veya ""Ana düğüm"" sabitini programlamayla temizleyin.'"),
			CatalogDescription(ExtensionsObjects));
		Raise ErrorText;
	EndIf;
	
EndProcedure

// Returns True if the check, update, and search for duplicates are completed.
//
// Parameters:
//  Refresh - Boolean - If True, tries to update
//             the data. If fails, an exception is thrown.
//             If False, the function returns the data state.
//  
//  ExtensionsObjects - Boolean
//
// Returns:
//  Boolean
//
Function IsDataUpdated(Refresh = False, ExtensionsObjects = False) Export
	
	Try
		Updated = StandardSubsystemsServer.ApplicationParameter(
			"StandardSubsystems.Core.MetadataObjectIDs");
	Except
		If Refresh Then
			Raise;
		EndIf;
		Return False;
	EndTry;
	
	If Updated = Undefined Then
		If Refresh Then
			UpdateCatalogData();
		Else
			Return False;
		EndIf;
	EndIf;
	
	If ExtensionsObjects
	   And ValueIsFilled(SessionParameters.AttachedExtensions) Then
		
		If Not Common.SeparatedDataUsageAvailable() Then
			If Refresh Then
				ErrorText = ExtensionObjectsIDsUnvailableInSharedModeErrorDescription();
				Raise ErrorText;
			Else
				Return False;
			EndIf;
		EndIf;
		
		If Not Catalogs.ExtensionObjectIDs.CurrentVersionExtensionObjectIDsFilled() Then
			Catalogs.ExtensionObjectIDs.UpdateCatalogData();
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

// For internal use only.
//
// Parameters:
//  Objects - Array of CatalogObject.MetadataObjectIDs
//
Procedure ImportDataToSubordinateNode(Objects) Export
	
	If Common.DataSeparationEnabled() Then
		// Not supported in SaaS mode.
		Return;
	EndIf;
	
	If Not Common.IsSubordinateDIBNode() Then
		Return;
	EndIf;
	
	CheckForUsage();
	StandardSubsystemsServer.CheckApplicationVersionDynamicUpdate();
	
	Block = New DataLock;
	Block.Add("Catalog.MetadataObjectIDs");
	
	BeginTransaction();
	Try
		Block.Lock();
		
		// Preparing the outgoing table with renaming for searching for duplicates.
		Upload0 = ExportAllIDs();
		Upload0.Columns.Add("DuplicateUpdated", New TypeDescription("Boolean"));
		Upload0.Columns.Add("FullNameLowerCase", New TypeDescription("String"));
		
		// Applying a filter to the objects to be imported. The filter returns only objects that differ from the existing ones.
		ItemsToImportTable = New ValueTable;
		ItemsToImportTable.Columns.Add("Object");
		ItemsToImportTable.Columns.Add("Ref");
		ItemsToImportTable.Columns.Add("MetadataObjectByKey");
		ItemsToImportTable.Columns.Add("MetadataObjectByFullName");
		ItemsToImportTable.Columns.Add("Matches", New TypeDescription("Boolean"));
		
		For Each Object In Objects Do
			ItemToImportProperties = ItemsToImportTable.Add();
			ItemToImportProperties.Object = Object;
			
			If ValueIsFilled(Object.Ref) Then
				ItemToImportProperties.Ref = Object.Ref;
			Else
				ItemToImportProperties.Ref = Object.GetNewObjectRef();
				If Not ValueIsFilled(ItemToImportProperties.Ref) Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể kết nhập tên đối tượng metadata từ nút chính.
						           |Đối với phần tử mới, chưa chỉ ra tham chiếu của phần tử mới:
						           |""%1"".';
						           |ru = 'Невозможно загрузить идентификаторы объектов метаданных из главного узла.
						           |Для нового элемента не указана ссылка нового:
						           |""%1"".';
						           |en = 'Could not import the metadata object ids from the master node.
						           |No reference is specified for the new item:
						           |""%1"".'; fa = 'Could not import the metadata object ids from the master node.
						           |No reference is specified for the new item:
						           |""%1"".';
						           |it = 'Невозможно загрузить идентификаторы объектов метаданных из главного узла.
						           |Для нового элемента не указана ссылка нового:
						           |""%1"".';
						           |pl = 'Could not import the metadata object ids from the master node.
						           |No reference is specified for the new item:
						           |""%1"".';
						           |tr = 'Ana düğümden meta veri nesne kimlikleri yüklenemiyor.
						           |Yeni öğe  için link belirtilmedi: 
						           |""%1"".'"),
						Object.FullName);
					Raise ErrorText;
				EndIf;
			EndIf;
			
			// Preliminary processing.
			
			If Not IsCollection(ItemToImportProperties.Ref) Then
				ItemToImportProperties.MetadataObjectByKey = MetadataObjectByKey(
					Object.MetadataObjectKey.Get(), "", "", "");
				
				ItemToImportProperties.MetadataObjectByFullName =
					MetadataFindByFullName(Object.FullName);
				
				If ItemToImportProperties.MetadataObjectByKey = Undefined
				   And ItemToImportProperties.MetadataObjectByFullName = Undefined
				   And Object.DeletionMark <> True Then
					// If an imported object is missing from metadata,
					// it is marked for deletion.
					Object.DeletionMark = True;
				EndIf;
			EndIf;
			
			If Object.DeletionMark Then
				// Objects marked for deletion cannot have "proper" full names.
				// Therefore, to meet this condition, the procedure that updates the object's properties
				// is applied prior to the import.
				UpdateMarkedForDeletionItemProperties(Object);
			EndIf;
			
			Properties = Upload0.Find(ItemToImportProperties.Ref, "Ref");
			If Properties <> Undefined
			   And Properties.Description              = Object.Description
			   And Properties.Parent                  = Object.Parent
			   And Properties.CollectionOrder          = Object.CollectionOrder
			   And Properties.Name                       = Object.Name
			   And Properties.Synonym                   = Object.Synonym
			   And Properties.FullName                 = Object.FullName
			   And Properties.FullSynonym             = Object.FullSynonym
			   And Properties.NoData                 = Object.NoData
			   And Properties.EmptyRefValue      = Object.EmptyRefValue
			   And Properties.PredefinedDataName = Object.PredefinedDataName
			   And Properties.DeletionMark           = Object.DeletionMark
			   And IdenticalMetadataObjectKeys(Properties, Object) Then
				
				ItemToImportProperties.Matches = True;
			EndIf;
			
			If Properties <> Undefined Then
				Upload0.Delete(Properties); // Renaming items to be imported is not required.
			EndIf;
		EndDo;
		ItemsToImportTable.Indexes.Add("Ref");
		
		// Renaming the existing items (except for items to be overwritten during the import) to search for duplicates.
		
		RenameFullNames(Upload0);
		For Each String In Upload0 Do
			String.FullNameLowerCase = Lower(String.FullName);
		EndDo;
		Upload0.Indexes.Add("MetadataObjectKey");
		Upload0.Indexes.Add("FullNameLowerCase");
		
		// Prepare 
		
		ObjectsToWrite = New Array; // Array of CatalogObject.MetadataObjectIDs -
		FullNamesOfItemsToImport = New Map;
		KeysOfItemsToImport = New Map;
		
		For Each ItemToImportProperties In ItemsToImportTable Do
			Object = ItemToImportProperties.Object; // CatalogObject.MetadataObjectIDs
			Ref = ItemToImportProperties.Ref;
			
			If ItemToImportProperties.Matches Then
				Continue; // There is no need to import objects that are identical to existing ones.
			EndIf;
			
			If IsCollection(Ref) Then
				ObjectsToWrite.Add(Object);
				Continue;
			EndIf;
			
			// Checking the items to be imported for duplicates.
			
			If FullNamesOfItemsToImport.Get(Lower(Object.FullName)) <> Undefined Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể kết nhập tên đối tượng metadata từ nút chính.
					           |Trong hai phần tử, trùng tên đầy đủ:
					           |""%1"".';
					           |ru = 'Невозможно загрузить идентификаторы объектов метаданных из главного узла.
					           |У двух элементов совпадает полное имя:
					           |""%1"".';
					           |en = 'Could not import the metadata object ids from the master node.
					           |Two items have identical full names:
					           |""%1"".'; fa = 'Could not import the metadata object ids from the master node.
					           |Two items have identical full names:
					           |""%1"".';
					           |it = 'Невозможно загрузить идентификаторы объектов метаданных из главного узла.
					           |У двух элементов совпадает полное имя:
					           |""%1"".';
					           |pl = 'Could not import the metadata object ids from the master node.
					           |Two items have identical full names:
					           |""%1"".';
					           |tr = 'Ana düğümden meta veri nesne kimlikleri yüklenemiyor.
					           |İki öğe aynı tam ada sahip:
					           |""%1"".'"),
					Object.FullName);
				Raise ErrorText;
			EndIf;
			FullNamesOfItemsToImport.Insert(Lower(Object.FullName));
			
			MetadataObjectKey = Object.MetadataObjectKey.Get();
			If TypeOf(MetadataObjectKey) = Type("Type")
			   And MetadataObjectKey <> Type("Undefined") Then
				
				If KeysOfItemsToImport.Get(MetadataObjectKey) <> Undefined Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể kết nhập tên đối tượng metadata từ nút chính.
						           |Trong hai phần tử, trùng khóa đối tượng metadata:
						           |""%1"".';
						           |ru = 'Невозможно загрузить идентификаторы объектов метаданных из главного узла.
						           |У двух элементов совпадает ключ объекта метаданных:
						           |""%1"".';
						           |en = 'Could not import the metadata object ids from the master node.
						           |Two items have identical metadata object keys:
						           |""%1"".'; fa = 'Could not import the metadata object ids from the master node.
						           |Two items have identical metadata object keys:
						           |""%1"".';
						           |it = 'Невозможно загрузить идентификаторы объектов метаданных из главного узла.
						           |У двух элементов совпадает ключ объекта метаданных:
						           |""%1"".';
						           |pl = 'Could not import the metadata object ids from the master node.
						           |Two items have identical metadata object keys:
						           |""%1"".';
						           |tr = 'Ana düğümden meta veri nesne kimlikleri yüklenemiyor.
						           |İki öğe aynı meta veri nesne anahtarına sahip:
						           |""%1"".'"),
						String(MetadataObjectKey));
					Raise ErrorText;
				EndIf;
				KeysOfItemsToImport.Insert(MetadataObjectKey);
				
				If ItemToImportProperties.MetadataObjectByKey <> ItemToImportProperties.MetadataObjectByFullName Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể kết nhập tên đối tượng metadata từ nút chính.
						           |Khóa đối tượng metadata ""%1"" Không trùng với tên gọi đầy đủ ""%2"".';
						           |ru = 'Невозможно загрузить идентификаторы объектов метаданных из главного узла.
						           |Ключ объекта метаданных ""%1"" не соответствует полному имени ""%2"".';
						           |en = 'Could not import the metadata object ids from the master node.
						           |The metadata key ""%1"" does not correspond to the full name ""%2"".'; fa = 'Could not import the metadata object ids from the master node.
						           |The metadata key ""%1"" does not correspond to the full name ""%2"".';
						           |it = 'Невозможно загрузить идентификаторы объектов метаданных из главного узла.
						           |Ключ объекта метаданных ""%1"" не соответствует полному имени ""%2"".';
						           |pl = 'Could not import the metadata object ids from the master node.
						           |The metadata key ""%1"" does not correspond to the full name ""%2"".';
						           |tr = 'Ana düğümden meta veri nesne kimlikleri yüklenemiyor.
						           |meta veri nesne anahtarı %1tam adla eşleşmiyor:""%2"".'"),
						String(MetadataObjectKey), Object.FullName);
					Raise ErrorText;
				EndIf;
				
				If Not Object.DeletionMark Then
					// Searching existing metadata objects for duplicates by key.
					Filter = New Structure("MetadataObjectKey", MetadataObjectKey);
					FindDuplicatesOnImportDataToSubordinateNode(Upload0, Filter, Object, Ref, ItemsToImportTable);
				EndIf;
			EndIf;
			
			If Not Object.DeletionMark Then
				// Searching existing metadata objects for duplicates by full name.
				Filter = New Structure("FullNameLowerCase", Lower(Object.FullName));
				FindDuplicatesOnImportDataToSubordinateNode(Upload0, Filter, Object, Ref, ItemsToImportTable);
			EndIf;
			
			ObjectsToWrite.Add(Object);
		EndDo;
		
		// Update duplicates.
		Rows = Upload0.FindRows(New Structure("DuplicateUpdated", True));
		For Each Properties In Rows Do
			DuplicateObject1 = Properties.Ref.GetObject();
			FillPropertyValues(DuplicateObject1, Properties);
			DuplicateObject1.MetadataObjectKey = New ValueStorage(Properties.MetadataObjectKey);
			DuplicateObject1.DataExchange.Load = True;
			DuplicateObject1.Write();
		EndDo;
		
		PrepareNewSubsystemsListInSubordinateNode(ObjectsToWrite);
		
		// Import objects.
		For Each Object In ObjectsToWrite Do
			Object.DataExchange.Load = True;
			Object.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns references to a metadata object found by the full name of the deleted metadata object.
// Use this function to replace or clear a reference.
//
// Parameters:
//  FullNameOfDeletedItem - String - for example "Role.ReadBasicRegulatoryData".
//
// Returns:
//  Array - Has the following values:
//   * Value - CatalogRef.MetadataObjectIDs
//              - CatalogRef.ExtensionObjectIDs - found reference.
// 
Function DeletedMetadataObjectID(FullNameOfDeletedItem) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MetadataObjectIDs.Ref AS Ref,
	|	MetadataObjectIDs.FullName AS FullName
	|FROM
	|	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|WHERE
	|	MetadataObjectIDs.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	ExtensionObjectIDs.Ref,
	|	ExtensionObjectIDs.FullName
	|FROM
	|	Catalog.ExtensionObjectIDs AS ExtensionObjectIDs
	|WHERE
	|	ExtensionObjectIDs.DeletionMark";
	
	Selection = Query.Execute().Select();
	
	FoundRefs = New Array;
	While Selection.Next() Do
		If Not StrStartsWith(Selection.FullName, "? ") Then
			Continue;
		EndIf;
		CurrentFullNameOfDeletedItem = FullNameOfDeletedItem(Selection.FullName);
		If Upper(CurrentFullNameOfDeletedItem) = Upper(FullNameOfDeletedItem) Then
			FoundRefs.Add(Selection.Ref);
		EndIf;
	EndDo;
	
	Return FoundRefs;
	
EndFunction

// Parameters:
//  IDs - Array - Array of values.:
//                     * Value - CatalogRef.MetadataObjectIDs
//                                - CatalogRef.ExtensionObjectIDs - the IDs of
//                                    metadata objects in an application or an extension.
// Returns:
//  Map of KeyAndValue:
//   * Key     - CatalogRef.MetadataObjectIDs
//              - CatalogRef.ExtensionObjectIDs
//   * Value - String - Metadata object full name without a question mark ( ? ).
//
Function FullNamesofMetadataObjectsIncludingRemote(IDs) Export
	
	Query = New Query;
	Query.SetParameter("IDs", IDs);
	Query.Text =
	"SELECT
	|	MetadataObjectIDs.Ref AS Ref,
	|	MetadataObjectIDs.FullName AS FullName
	|FROM
	|	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|WHERE
	|	MetadataObjectIDs.Ref IN(&IDs)
	|
	|UNION ALL
	|
	|SELECT
	|	ExtensionObjectIDs.Ref,
	|	ExtensionObjectIDs.FullName
	|FROM
	|	Catalog.ExtensionObjectIDs AS ExtensionObjectIDs
	|WHERE
	|	ExtensionObjectIDs.Ref IN(&IDs)";
	
	Result = New Map;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If StrStartsWith(Selection.FullName, "? ") Then
			Result.Insert(Selection.Ref, FullNameOfDeletedItem(Selection.FullName));
		Else
			Result.Insert(Selection.Ref, Selection.FullName);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns:
//  Array of String - Names of collections of metadata objects this catalog supports.
//
Function ValidCollections() Export
	
	CollectionsProperties = StandardSubsystemsCached.MetadataObjectCollectionProperties();
	
	Return CollectionsProperties.UnloadColumn("Name");
	
EndFunction

// For internal use only.
// Parameters:
//  MetadataObjectRole - MetadataObject
// Returns:
//  String
//  Undefined
//
Function RoleMetadataObjectKey(MetadataObjectRole) Export
	Return KeyRole(MetadataObjectRole, False);
EndFunction

// For internal use only.
// Parameters:
//  IDsOfRole - Array of CatalogRef.MetadataObjectIDs
//                     - Array of CatalogRef.ExtensionObjectIDs
// Returns:
//  Map of KeyAndValue:
//   * Key - CatalogRef.MetadataObjectIDs
//          - CatalogRef.ExtensionObjectIDs
//   * Value - See RoleMetadataObjectKey
//
Function RolesKeys(IDsOfRole) Export
	
	Result = New Map;
	Values = Common.ObjectsAttributeValue(IDsOfRole, "MetadataObjectKey");
	
	For Each KeyAndValue In Values Do
		Result.Insert(KeyAndValue.Key, Undefined);
		If TypeOf(KeyAndValue.Value) <> Type("ValueStorage") Then
			Continue;
		EndIf;
		KeyRole = KeyAndValue.Value.Get();
		If TypeOf(KeyRole) <> Type("String")
		 Or Not StringFunctionsClientServer.IsUUID(KeyRole) Then
			Continue;
		EndIf;
		Result.Insert(KeyAndValue.Key, KeyRole);
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// This procedure updates catalog data using the configuration metadata.
//
// Parameters:
//  HasChanges  - Boolean - a return value). True is returned
//                   to this parameter if changes are saved. Otherwise, not modified.
//
//  HasDeletedItems  - Boolean - a return value. Receives
//                   True if a catalog item was marked
//                   for deletion. Otherwise, not modified.
//
//  IsCheckOnly - Boolean - make no changes, just set
//                   the HasChanges and HasDeleted flags.
//
Procedure UpdateCatalogData(HasChanges = False, HasDeletedItems = False, IsCheckOnly = False) Export
	
	RunDataUpdate(HasChanges, HasDeletedItems, IsCheckOnly);
	
EndProcedure

// Required to export all application metadata object IDs
// to subordinate DIB nodes if the catalog was not included into the DIB before.
// Also can be used to repair the catalog data in DIB nodes.
//
Procedure RegisterTotalChangeForSubordinateDIBNodes() Export
	
	CheckForUsage();
	
	If Common.IsSubordinateDIBNode()
	 Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	CatalogMetadata = Metadata.Catalogs.MetadataObjectIDs;
	
	DIBNodes = New Array;
	For Each ExchangePlan In Metadata.ExchangePlans Do
		If ExchangePlan.DistributedInfoBase
		   And ExchangePlan.Content.Contains(CatalogMetadata)Then
		
			ExchangePlanManager = Common.ObjectManagerByFullName(ExchangePlan.FullName());
			Selection = ExchangePlanManager.Select();
			While Selection.Next() Do
				If Selection.Ref <> ExchangePlanManager.ThisNode() Then
					DIBNodes.Add(Selection.Ref);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	If DIBNodes.Count() > 0 Then
		ExchangePlans.RecordChanges(DIBNodes, CatalogMetadata);
	EndIf;
	
EndProcedure

// This procedure updates catalog data using the configuration metadata.
//
// Parameters:
//  HasChanges - Boolean - a return value). True is returned
//                  to this parameter if changes are saved. Otherwise, not modified.
//
//  HasDeletedItems - Boolean - a return value. Receives
//                  True if at least one catalog item was marked
//                  for deletion. Otherwise, not modified.
//
//  IsCheckOnly - Boolean - make no changes,
//                   just set the HasChanges, HasDeleted, HasCriticalChanges, and ListOfCriticalChanges flags.
//
//  HasCriticalChanges - Boolean - a return value. Receives
//                  True if critical changes are found. Otherwise, not modified.
//                    Critical changes (only for items without a deletion mark):  
//                    FullName attribute change or adding a new catalog item.
//                  Generally the exclusive mode is required for any critical changes.
//
//  ListOfCriticalChanges - String - a return value. Contains full names
//                  of metadata objects that were added or must be added,
//                  and also whose names were changed or must be changed.
//
//  ExtensionsObjects - Boolean
//
Procedure RunDataUpdate(HasChanges, HasDeletedItems, IsCheckOnly,
			HasCriticalChanges = False, ListOfCriticalChanges = "", ExtensionsObjects = False) Export
	
	If Not UpdateIDCatalogs().UpdateInProgress Then
		InstallIdUpdateIsInProgress(True);
		Try
			PerformDataUpdateAfterLoopingCheck(HasChanges, HasDeletedItems, IsCheckOnly,
				HasCriticalChanges, ListOfCriticalChanges, ExtensionsObjects);
		Except
			InstallIdUpdateIsInProgress(False);
			Raise;
		EndTry;
		InstallIdUpdateIsInProgress(False);
		Return;
	EndIf;
	
	NamesOfServiceObjects = New Array;
	NamesOfServiceObjects.Add(Metadata.Catalogs.ExtensionsVersions.FullName());
	NamesOfServiceObjects.Add(Metadata.Catalogs.MetadataObjectIDs.FullName());
	NamesOfServiceObjects.Add(Metadata.Catalogs.ExtensionObjectIDs.FullName());
	NamesOfServiceObjects.Add(Metadata.InformationRegisters.ExtensionVersionObjectIDs.FullName());
	NamesOfServiceObjects.Add(Metadata.InformationRegisters.ApplicationRuntimeParameters.FullName());
	NamesOfServiceObjects.Add(Metadata.InformationRegisters.ExtensionVersionParameters.FullName());
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Недопустимое получение идентификаторов объектов метаданных в процессе их обновления.
		           |Следует исключать из подписок на события %1 служебные объекты, в частности:
		           |%2.';
		           |vi = 'Invalid retrieval of metadata object IDs during their update.
		           |Event subscriptions %1 should exclude internal objects, specifically:
		           |%2.';
		           |en = 'Invalid retrieval of metadata object IDs during their update.
		           |Event subscriptions %1 should exclude internal objects, specifically:
		           |%2.'; fa = 'Invalid retrieval of metadata object IDs during their update.
		           |Event subscriptions %1 should exclude internal objects, specifically:
		           |%2.';
		           |it = 'Invalid retrieval of metadata object IDs during their update.
		           |Event subscriptions %1 should exclude internal objects, specifically:
		           |%2.';
		           |pl = 'Invalid retrieval of metadata object IDs during their update.
		           |Event subscriptions %1 should exclude internal objects, specifically:
		           |%2.';
		           |tr = 'Meta veri nesnelerinin güncellenme sürecinde kimliklerinin alınmasına izin verilmez. 
		           | Olay aboneliklerinden %1 hizmet nesneleri hariç tutulmalıdır, özellikle:
		           |%2.'"),
		"BeforeWrite" + "/" + "OnWrite",
		"- " + StrConcat(NamesOfServiceObjects, "," + Chars.LF + "- "));
	
	Raise(ErrorText, ErrorCategory.ConfigurationError);
	
EndProcedure

Procedure PerformDataUpdateAfterLoopingCheck(HasChanges, HasDeletedItems, IsCheckOnly,
			HasCriticalChanges, ListOfCriticalChanges, ExtensionsObjects)
	
	If ExtensionsObjects
	   And ValueIsFilled(SessionParameters.AttachedExtensions)
	   And Not Common.SeparatedDataUsageAvailable() Then
		
		RaiseByError(True,
			ExtensionObjectsIDsUnvailableInSharedModeErrorDescription());
	EndIf;
	
	CheckForUsage(ExtensionsObjects);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	HasCurrentChanges = False;
	If Not ExtensionsObjects Then
		ReplaceSubordinateNodeDuplicatesFoundOnImport(IsCheckOnly, HasCurrentChanges);
	EndIf;
	
	UpdateData1(HasCurrentChanges, HasDeletedItems, IsCheckOnly,
		HasCriticalChanges, ListOfCriticalChanges, ExtensionsObjects);
	
	If HasCurrentChanges Then
		HasChanges = True;
	EndIf;
	
	If Not ExtensionsObjects
	   And Not StandardSubsystemsServer.ApplicationVersionUpdatedDynamically() Then
		
		StandardSubsystemsServer.UpdateApplicationParameter(
			"StandardSubsystems.Core.MetadataObjectIDs", True);
	EndIf;
	
	If Not IsCheckOnly And Not TransactionActive() Then
		UpdateIsCompleted = New Structure(SessionParameters.UpdateIDCatalogs);
		If ExtensionsObjects Then
			UpdateIsCompleted.ExtensionObjectIDs = True;
		Else
			UpdateIsCompleted.MetadataObjectIDs = True;
		EndIf;
		SessionParameters.UpdateIDCatalogs = New FixedStructure(UpdateIsCompleted);
	EndIf;
	
EndProcedure

#Region ImplementationOfProceduresDeclaredInOtherModules

// See Common.MetadataObjectID.
Function MetadataObjectID(MetadataObjectDetails, RaiseException1) Export
	
	MetadataObjectDetailsType = TypeOf(MetadataObjectDetails);
	If MetadataObjectDetailsType = Type("Type") Then
		
		MetadataObject = Metadata.FindByType(MetadataObjectDetails);
		
		If MetadataObject <> Undefined Then
			FullMetadataObjectName = MetadataObject.FullName();
			
		ElsIf Not RaiseException1 Then
			Return Null;
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sai giá trị tham số %1 trong hàm %2.
				           |Đã chỉ ra đối tượng metadata không tồn tại: ""%3"".';
				           |ru = 'Некорректное значение параметра %1 в функции %2.
				           |Указан несуществующий объект метаданных: ""%3"".';
				           |en = 'Incorrect value of the %1 parameter in the %2 function.
				           |Non-existing metadata object is specified: ""%3"".'; fa = 'Incorrect value of the %1 parameter in the %2 function.
				           |Non-existing metadata object is specified: ""%3"".';
				           |it = 'Valore errato del parametro %1 nella funzione %2.
				           |Indicato un oggetto di metadati ""%3"" inesistente.';
				           |pl = 'Nieprawidłowa wartość parametru %1 funkcji %2.
				           |Podano nieistniejący obiekt metadanych: ""%3"".';
				           |tr = '%2 işlevinde yanlış %1 parametre değeri.
				           |Mevcut olmayan meta veri nesnesi belirtildi: ""%3"".'"),
				"MetadataObjectDetails",
				"Common.MetadataObjectID",
				MetadataObjectDetails);
			Raise ErrorText;
		EndIf;
		
	ElsIf MetadataObjectDetailsType = Type("String") Then
		FullMetadataObjectName = MetadataObjectDetails;
		
	ElsIf MetadataObjectDetailsType = Type("MetadataObject") Then
		FullMetadataObjectName = MetadataObjectDetails.FullName();
		
	ElsIf Not RaiseException1 Then
		Return Null;
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai kiểu tham số %1 trong hàm %2:
			           |""%3"".';
			           |ru = 'Некорректный тип параметра %1 в функции %2:
			           |""%3"".';
			           |en = 'Incorrect type of the %1 parameter in the %2 function:
			           |""%3"".'; fa = 'Incorrect type of the %1 parameter in the %2 function:
			           |""%3"".';
			           |it = 'Tipo errato di parametro %1 nella funzione %2:
			           |""%3"".';
			           |pl = 'Nieprawidłowy typ drugiego parametru %1 w funkcji %2:
			           |""%3"".';
			           |tr = '%2 işlevinde yanlış %1parametre tipi:
			           |""%3"".'"),
			"MetadataObjectDetails",
			"Common.MetadataObjectID",
			MetadataObjectDetailsType);
		Raise ErrorText;
	EndIf;
	
	Array = New Array;
	Array.Add(FullMetadataObjectName);
	
	IDs = MetadataObjectIDs(Array, RaiseException1, True);
	Id = IDs.Get(FullMetadataObjectName);
	If Id = Undefined Then
		Return Null;
	EndIf;
	
	Return Id;
	
EndFunction

// See Common.MetadataObjectIDs.
Function MetadataObjectIDs(MetadataObjectsDetails, RaiseException1 = True, OneItem = False) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	IDsByFullNames = IDCache().IDsByFullNames;
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Result = New Map;
	FullNamesWithoutCache = New Array;
	For Each MetadataObjectDetails In MetadataObjectsDetails Do
		
		MetadataObjectDetailsType = TypeOf(MetadataObjectDetails);
		If MetadataObjectDetailsType = Type("Type") Then
		
			MetadataObject = Metadata.FindByType(MetadataObjectDetails);
			If MetadataObject <> Undefined Then
				FullName = MetadataObject.FullName();
			ElsIf Not RaiseException1 Then
				Continue;
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sai giá trị tham số %1 của hàm %2:
					           |Đã chỉ ra đối tượng metadata không tồn tại: ""%3"".';
					           |ru = 'Некорректное значение параметра %1 функции %2:
					           |Указан несуществующий объект метаданных: ""%3"".';
					           |en = 'Incorrect value of parameter %1 in function %2.
					           |Non-existing metadata object is specified: ""%3"".'; fa = 'Incorrect value of parameter %1 in function %2.
					           |Non-existing metadata object is specified: ""%3"".';
					           |it = 'Valore errato del parametro %1 nella funzione %2:
					           |Indicato un oggetto di metadati ""%3"" inesistente.';
					           |pl = 'Nieprawidłowa wartość parametru %1 funkcji %2.
					           |Podano nieistniejący obiekt metadanych: ""%3"".';
					           |tr = '%2 işlevinde yanlış %1 parametre değeri:
					           |Mevcut olmayan meta veri nesnesi belirtildi: ""%3"".'"),
					"MetadataObjectsDetails",
					"Common.MetadataObjectIDs",
					MetadataObjectDetails);
				Raise ErrorText;
			EndIf;
			
		ElsIf MetadataObjectDetailsType = Type("String") Then
			FullName = MetadataObjectDetails;
			
		ElsIf MetadataObjectDetailsType = Type("MetadataObject") Then
			FullName = MetadataObjectDetails.FullName();
			
		ElsIf Not RaiseException1 Then
			Continue;
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sai kiểu tham số %1 của hàm %2:
				           |""%3"".';
				           |ru = 'Некорректный тип параметра %1 функции %2:
				           |""%3"".';
				           |en = 'Incorrect type of parameter %1 in function %2:
				           |""%3"".'; fa = 'Incorrect type of parameter %1 in function %2:
				           |""%3"".';
				           |it = 'Tipo errato di parametro %1 nella funzione %2:
				           |""%3"".';
				           |pl = 'Nieprawidłowy typ drugiego parametru %1 funkcji %2:
				           |""%3"".';
				           |tr = '%2 işlevinde yanlış %1parametre tipi:
				           |""%3"".'"),
				"MetadataObjectsDetails",
				"Common.MetadataObjectIDs",
				MetadataObjectDetailsType);
			Raise ErrorText;
		EndIf;
		Id = IDsByFullNames.Get(FullName);
		
		If Id = Undefined Then
			FullNamesWithoutCache.Add(FullName);
		Else
			Result.Insert(FullName, Id);
		EndIf;
	EndDo;
	
	If FullNamesWithoutCache.Count() = 0 Then
		Return Result;
	EndIf;
	
	IDs = MetadataObjectIDsWithRetryAttempt(FullNamesWithoutCache,
		RaiseException1, OneItem);
	
	For Each KeyAndValue In IDs Do
		Result.Insert(KeyAndValue.Key, KeyAndValue.Value);
		IDsByFullNames.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	Return Result;
	
EndFunction

// See Common.MetadataObjectByID.
Function MetadataObjectByID(Id, RaiseException1) Export
	
	IDs = New Array;
	IDs.Add(Id);
	
	MetadataObjects = MetadataObjectsByIDs(IDs, RaiseException1);
	
	If Id = Undefined Then
		Return Null;
	EndIf;
	
	Return MetadataObjects.Get(Id);
	
EndFunction

// See Common.MetadataObjectsByIDs.
Function MetadataObjectsByIDs(IDs, RaiseException1) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	DetailsOfMetadataObjectsByIDs = IDCache().DetailsOfMetadataObjectsByIDs;
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	RolesByKeys = Undefined;
	Result = New Map;
	IDsWithoutCache = New Array;
	For Each Id In IDs Do
		LongDesc = DetailsOfMetadataObjectsByIDs.Get(Id);
		
		If LongDesc = Undefined
		 Or RaiseException1
		   And LongDesc.Key = Undefined Then
			
			IDsWithoutCache.Add(Id);
			
		ElsIf LongDesc.Key = Undefined Then
			Result.Insert(Id, LongDesc.Object);
			
		ElsIf TypeOf(LongDesc.Key) = Type("Type") Then
			Result.Insert(Id, Metadata.FindByType(LongDesc.Key));
		ElsIf LongDesc.Key <> LongDesc.FullName Then
			If RolesByKeys = Undefined Then
				RolesByKeys = StandardSubsystemsCached.RolesByKeysMetadataObjects();
			EndIf;
			Result.Insert(Id, RolesByKeys.Get(LongDesc.Key));
		Else
			Result.Insert(Id, Common.MetadataObjectByFullName(LongDesc.Key));
		EndIf;
	EndDo;
	
	If IDsWithoutCache.Count() = 0 Then
		Return Result;
	EndIf;
	
	MetadataObjectsByIDs = MetadataObjectsByIDsWithRetryAttempt(IDsWithoutCache,
		RaiseException1);
	
	For Each KeyAndValue In MetadataObjectsByIDs Do
		MetadataObjectDetails = KeyAndValue.Value;
		If TypeOf(MetadataObjectDetails) = Type("Structure") Then
			Result.Insert(KeyAndValue.Key, MetadataObjectDetails.Object);
			MetadataObjectDetails.Object = Undefined;
		Else
			Result.Insert(KeyAndValue.Key, KeyAndValue.Value);
			MetadataObjectDetails = New Structure("Object, Key, FullName", KeyAndValue.Value)
		EndIf;
		DetailsOfMetadataObjectsByIDs.Insert(KeyAndValue.Key, MetadataObjectDetails);
	EndDo;
	
	Return Result;
	
EndFunction

// See Common.AddRenaming.
Procedure AddRenaming(Renamings, IBVersion, PreviousFullName, NewFullName, LibraryID = "") Export
	
	StandardSubsystemsCached.MetadataObjectIDsUsageCheck();
	
	PreviousCollectionName = Upper(CollectionName(PreviousFullName));
	NewCollectionName  = Upper(CollectionName(NewFullName));
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lỗi trong thủ tục %1 của mô-đun chung %2.';
			|ru = 'Ошибка в процедуре %1 общего модуля %2.';
			|en = 'Error in procedure %1 of common module %2.'; fa = 'Error in procedure %1 of common module %2.';
			|it = 'Errore di procedura %1 del modulo comune %2.';
			|pl = 'Błąd w procedurze %1 wspólnego modułu %2.';
			|tr = '%2genel modülün %1prosedüründe hata.'"),
		"OnAddMetadataObjectsRenaming",
		"CommonOverridable");
	
	If PreviousCollectionName <> NewCollectionName Then
		ErrorText = ErrorTitle + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tên các kiểu đối tượng metadata đã đổi tên không trùng nhau.
			           |Kiểu cũ: ""%1"",
			           |kiểu mới: ""%2"".';
			           |ru = 'Не совпадают имена типов переименованного объекта метаданных.
			           |Прежний тип: ""%1"",
			           |новый тип: ""%2"".';
			           |en = 'Type mismatch in the renamed metadata object.
			           |Previous type: ""%1"",
			           |new type: ""%2"".'; fa = 'Type mismatch in the renamed metadata object.
			           |Previous type: ""%1"",
			           |new type: ""%2"".';
			           |it = 'I nomi dei tipi dell''oggetto dei metadati rinominato non coincidono.
			           |Tipo precedente: ""%1"", 
			           |nuovo tipo: ""%2"".';
			           |pl = 'Nazwy typów określanego ponownie obiektu metadanych nie zgadzają się.
			           |Poprzedni typ: ""%1"",
			           |nowy typ: ""%2"".';
			           |tr = 'Yeniden adlandırılmış meta veri nesnesinin tür adları eşleşmiyor. 
			           |Önceki tip: %1
			           | yeni tip:""%2"".'"),
			PreviousFullName,
			NewFullName);
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	If Renamings.CollectionsWithoutKey[PreviousCollectionName] = Undefined Then
		
		AllowedTypesList = "";
		For Each KeyAndValue In Renamings.CollectionsWithoutKey Do
			AllowedTypesList = AllowedTypesList + KeyAndValue.Value + "," + Chars.LF;
		EndDo;
		AllowedTypesList = TrimR(AllowedTypesList);
		AllowedTypesList = ?(ValueIsFilled(AllowedTypesList),
			Left(AllowedTypesList, StrLen(AllowedTypesList) - 1), "");
		
		ErrorText = ErrorTitle + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần mô tả đổi tên đối với kiểu đối tượng metadata ""%1"",
			           |bởi vì thông tin về đối tượng metadata kiểu này được cập nhật tự động.
			           |
			           |Chỉ cần mô tả đổi tên đối với các kiểu đối tượng sau:
			           |%2.';
			           |ru = 'Для типа объекта метаданных ""%1"" не требуется описывать переименование,
			           |так как сведения об объектах метаданных этого типа обновляются автоматически.
			           |
			           |Описывать переименования требуется только для следующих типов:
			           |%2.';
			           |en = 'Describing the renaming of ""%1"" metadata object is not required,
			           |as the details of metadata objects of this type are updated automatically.
			           |
			           |It is required only for the following types:
			           |%2.'; fa = 'Describing the renaming of ""%1"" metadata object is not required,
			           |as the details of metadata objects of this type are updated automatically.
			           |
			           |It is required only for the following types:
			           |%2.';
			           |it = 'Per il tipo dell''oggetto dei metadati ""%1"" non è necessario descrivere la ridenominazione
			           |poiché le informazioni sugli oggetti dei metadati di questo tipo vengono aggiornate automaticamente.
			           |
			           |Descrivere la ridenominazione è necessario solo per i seguenti tipi:
			           |%2.';
			           |pl = 'Dla rodzaju obiektu metadanych ""%1"" nie jest wymagany opis zmiany nazwy,
			           |ponieważ informacje o obiektach metadanych tego typu są aktualizowane automatycznie.
			           |
			           |Opis zmiany nazwy jest wymagany tylko dla następujących typów:
			           |%2.';
			           |tr = 'Bu tür meta veri nesnesi hakkında bilgi otomatik olarak güncellendiği için, 
			           |meta veri nesne türü %1 için yeniden adlandırmanın tanımlanması gerekmez
			           |
			           |Yalnızca aşağıdaki türlerde yeniden adlandırmaları tanımlamak gerekir:
			           |%2.'"),
			PreviousFullName,
			AllowedTypesList);
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	If Not ValueIsFilled(LibraryID) Then
		LibraryID = Metadata.Name;
	EndIf;
	
	LibraryOrder = Renamings.LibrariesOrder[LibraryID];
	If LibraryOrder = Undefined Then
		LibraryOrder = Renamings.LibrariesOrder.Count();
		Renamings.LibrariesOrder.Insert(LibraryID, LibraryOrder);
	EndIf;
	
	LibraryVersion = Renamings.LibrariesVersions[LibraryID];
	If LibraryVersion = Undefined Then
		LibraryVersion = InfobaseUpdateInternal.IBVersion(LibraryID);
		Renamings.LibrariesVersions.Insert(LibraryID, LibraryVersion);
	EndIf;
	
	If LibraryVersion = "0.0.0.0" Then
		// No renaming is required during the initial filling.
		Return;
	EndIf;
	
	Result = CommonClientServer.CompareVersions(IBVersion, LibraryVersion);
	If Result > 0 Then
		VersionParts = StrSplit(IBVersion, ".");
		
		RenamingTable = Renamings.Table; // See RenamingTableForCurrentVersion
		RenamingDetails = RenamingTable.Add();
		RenamingDetails.LibraryOrder = LibraryOrder;
		RenamingDetails.VersionPart1      = Number(VersionParts[0]);
		RenamingDetails.VersionPart2      = Number(VersionParts[1]);
		RenamingDetails.VersionPart3      = Number(VersionParts[2]);
		RenamingDetails.VersionPart4      = Number(VersionParts[3]);
		RenamingDetails.PreviousFullName   = PreviousFullName;
		RenamingDetails.NewFullName    = NewFullName;
		RenamingDetails.AdditionOrder = RenamingTable.IndexOf(RenamingDetails);
	EndIf;
	
EndProcedure

#EndRegion

#Region AdditionalProceduresAndFunctionsToBeInvokedFromOtherModules

// For internal use only.
// FullName for the object must be specified and valid.
//
// Parameters:
//   Object - CatalogObject.MetadataObjectIDs
//          - CatalogObject.ExtensionObjectIDs
//          - FormDataStructure:
//             * Ref - CatalogRef.MetadataObjectIDs
//                      - CatalogRef.ExtensionObjectIDs
//
Procedure UpdateIDProperties(Object) Export
	
	If TypeOf(Object) <> Type("FormDataStructure") Then
		ExtensionsObjects = IsExtensionsObject(Object);
	Else
		ExtensionsObjects = IsExtensionsObject(Object.Ref);
	EndIf;
	
	If ExtensionsObjects
	   And Catalogs.ExtensionObjectIDs.ExtensionObjectDisabled(Object.Ref) Then
		Return;
	EndIf;
	
	FullName = Object.FullName;
	
	// Restore previous values.
	If ValueIsFilled(Object.Ref) Then
		PreviousValues1 = Common.ObjectAttributesValues(
			Object.Ref,
			"Description,
			|CollectionOrder,
			|Name,
			|FullName,
			|Synonym,
			|FullSynonym,
			|NoData,
			|EmptyRefValue,
			|MetadataObjectKey");
		FillPropertyValues(Object, PreviousValues1);
	EndIf;
	
	MetadataObject = MetadataFindByFullName(FullName);
	
	If MetadataObject = Undefined Then
		Object.DeletionMark       = True;
		Object.Parent              = EmptyCatalogRef(ExtensionsObjects);
		Object.Description          = InsertQuestionMark(Object.Description);
		Object.Name                   = InsertQuestionMark(Object.Name);
		Object.Synonym               = InsertQuestionMark(Object.Synonym);
		Object.FullName             = InsertQuestionMark(Object.FullName);
		Object.FullSynonym         = InsertQuestionMark(Object.FullSynonym);
		Object.EmptyRefValue  = Undefined;
		
		If ExtensionsObjects Then
			Object.ExtensionName           = InsertQuestionMark(Object.ExtensionName);
			Object.ExtensionID = InsertQuestionMark(Object.ExtensionID);
			Object.ExtensionHashsum      = InsertQuestionMark(Object.ExtensionHashsum);
		EndIf;
	Else
		Object.DeletionMark = False;
		
		FullName = MetadataObject.FullName();
		PointPosition = StrFind(FullName, ".");
		BaseTypeName = Left(FullName, PointPosition -1);
		
		CollectionsProperties = StandardSubsystemsCached.MetadataObjectCollectionProperties(ExtensionsObjects);
		Filter = New Structure("SingularName", BaseTypeName);
		Rows = CollectionsProperties.FindRows(Filter);
		
		MetadataObjectProperties1 = MetadataObjectProperties1(ExtensionsObjects,
			CollectionsProperties.Copy(Rows));
		
		ObjectProperties = MetadataObjectProperties1.Find(FullName, "FullName");
		
		FillPropertyValues(Object, ObjectProperties);
		
		If TypeOf(Object) <> Type("FormDataStructure") Then
			MetadataObjectKey = Object.MetadataObjectKey.Get();
			If MetadataObjectKey = Undefined
			 Or ObjectProperties.NoMetadataObjectKey
			     <> (MetadataObjectKey = Type("Undefined")) Then
				
				Object.MetadataObjectKey = New ValueStorage(MetadataObjectKey(ObjectProperties.FullName));
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// For internal use only.
//
// Returns:
//  ValueTable:
//   * LibraryOrder - Number
//   * VersionPart1 - Number
//   * VersionPart2 - Number
//   * VersionPart3 - Number
//   * VersionPart4 - Number
//   * AdditionOrder - Number
//   * PreviousFullName - String
//   * NewFullName - String
//
Function RenamingTableForCurrentVersion() Export
	
	RenamingTable = New ValueTable;
	RenamingTable.Columns.Add("LibraryOrder", New TypeDescription("Number"));
	RenamingTable.Columns.Add("VersionPart1",      New TypeDescription("Number"));
	RenamingTable.Columns.Add("VersionPart2",      New TypeDescription("Number"));
	RenamingTable.Columns.Add("VersionPart3",      New TypeDescription("Number"));
	RenamingTable.Columns.Add("VersionPart4",      New TypeDescription("Number"));
	RenamingTable.Columns.Add("AdditionOrder", New TypeDescription("Number"));
	RenamingTable.Columns.Add("PreviousFullName",   New TypeDescription("String"));
	RenamingTable.Columns.Add("NewFullName",    New TypeDescription("String"));
	
	CollectionsWithoutKey = New Map;
	
	Filter = New Structure("NoMetadataObjectKey", True);
	
	CollectionsWithoutMetadataObjectKey =
		StandardSubsystemsCached.MetadataObjectCollectionProperties().FindRows(Filter);
	
	For Each String In CollectionsWithoutMetadataObjectKey Do
		CollectionsWithoutKey.Insert(Upper(String.SingularName), String.SingularName);
	EndDo;
	CollectionsWithoutKey.Insert(Upper("Role"), "Role");
	
	Renamings = New Structure;
	Renamings.Insert("Table", RenamingTable);
	Renamings.Insert("CollectionsWithoutKey", CollectionsWithoutKey);
	Renamings.Insert("LibrariesVersions",  New Map);
	Renamings.Insert("LibrariesOrder", New Map);
	
	CommonOverridable.OnAddMetadataObjectsRenaming(Renamings);
	SSLSubsystemsIntegration.OnAddMetadataObjectsRenaming(Renamings);
	
	RenamingTable.Sort(
		"LibraryOrder ASC,
		|VersionPart1 ASC,
		|VersionPart2 ASC,
		|VersionPart3 ASC,
		|VersionPart4 ASC,
		|AdditionOrder ASC");
	
	Return RenamingTable;
	
EndFunction

// Parameters:
//  ExtensionsObjects - Boolean
//
// Returns:
//  ValueTable:
//   * Name              - String
//   * SingularName      - String
//   * Synonym          - String
//   * SingularSynonym  - String
//   * CollectionOrder - String
//   * NoData        - Boolean
//   * NoMetadataObjectKey - Boolean
//   * Id             - UUID
//   * ExtensionsObjects         - Boolean
//
Function MetadataObjectCollectionProperties(ExtensionsObjects = False) Export
	
	Result = New ValueTable;
	Result.Columns.Add("Name",                       New TypeDescription("String",, New StringQualifiers(50)));
	Result.Columns.Add("SingularName",               New TypeDescription("String",, New StringQualifiers(50)));
	Result.Columns.Add("Synonym",                   New TypeDescription("String",, New StringQualifiers(255)));
	Result.Columns.Add("SingularSynonym",           New TypeDescription("String",, New StringQualifiers(255)));
	Result.Columns.Add("CollectionOrder",          New TypeDescription("Number"));
	Result.Columns.Add("NoData",                 New TypeDescription("Boolean"));
	Result.Columns.Add("NoMetadataObjectKey", New TypeDescription("Boolean"));
	Result.Columns.Add("Id",             New TypeDescription("UUID"));
	Result.Columns.Add("ExtensionsObjects",         New TypeDescription("Boolean"));
	
	String = Result.Add();
	String.Id   = New UUID("627a6fb8-872a-11e3-bb87-005056c00008");
	String.Name             = "Constants";
	String.Synonym         = NStr("vi = 'Hằng';
									|ru = 'Константы';
									|en = 'Constants'; fa = 'ثابت‌ها';
									|it = 'Costanti';
									|pl = 'Constants';
									|tr = 'Sabitler'");
	String.SingularName     = "Constant";
	String.SingularSynonym = NStr("vi = 'Hằng';
									|ru = 'Константа';
									|en = 'Constant'; fa = 'ثابت';
									|it = 'Costante';
									|pl = 'Constant';
									|tr = 'Sabit'");
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("cdf5ac50-08e8-46af-9a80-4e63fd4a88ff");
	String.Name             = "Subsystems";
	String.Synonym         = NStr("vi = 'Phân hệ';
									|ru = 'Подсистемы';
									|en = 'Subsystems'; fa = 'Subsystems';
									|it = 'Sottosistemi';
									|pl = 'Subsystems';
									|tr = 'Alt sistemler'");
	String.SingularName     = "Subsystem";
	String.SingularSynonym = NStr("vi = 'Phân hệ';
									|ru = 'Подсистема';
									|en = 'Subsystem'; fa = 'زیرسیستم';
									|it = 'Sottosistema';
									|pl = 'Subsystem';
									|tr = 'Alt sistem'");
	String.NoData       = True;
	String.NoMetadataObjectKey = True;
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("115c4f55-9c20-4e86-a6d0-d0167ec053a1");
	String.Name             = "Roles";
	String.Synonym         = NStr("vi = 'Vai trò';
									|ru = 'Роли';
									|en = 'Roles'; fa = 'نقش‌ها';
									|it = 'Funzioni';
									|pl = 'Roles';
									|tr = 'Roller'");
	String.SingularName     = "Role";
	String.SingularSynonym = NStr("vi = 'Vai trò';
									|ru = 'Роль';
									|en = 'Role'; fa = 'نقش';
									|it = 'Ruolo';
									|pl = 'Role';
									|tr = 'Rol'");
	String.NoData       = True;
	String.NoMetadataObjectKey = False;
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("269651e0-4b06-4f9d-aaab-a8d2b6bc6077");
	String.Name             = "ExchangePlans";
	String.Synonym         = NStr("vi = 'Sơ đồ trao đổi';
									|ru = 'Планы обмена';
									|en = 'Exchange plans'; fa = 'Exchange plans';
									|it = 'Piani di scambio';
									|pl = 'Plany wymiany';
									|tr = 'Değiştirme planları'");
	String.SingularName     = "ExchangePlan";
	String.SingularSynonym = NStr("vi = 'Sơ đồ trao đổi';
									|ru = 'План обмена';
									|en = 'Exchange plan'; fa = 'طرح تبادل';
									|it = 'Piano di scambio';
									|pl = 'Plan wymiany';
									|tr = 'Değiştirme planı'");
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("ede89702-30f5-4a2a-8e81-c3a823b7e161");
	String.Name             = "Catalogs";
	String.Synonym         = NStr("vi = 'Danh mục';
									|ru = 'Справочники';
									|en = 'Catalogs'; fa = 'فهرست‌ها';
									|it = 'Directory';
									|pl = 'Catalogs';
									|tr = 'Kataloglar'");
	String.SingularName     = "Catalog";
	String.SingularSynonym = NStr("vi = 'Danh mục';
									|ru = 'Справочник';
									|en = 'Catalog'; fa = 'فهرست';
									|it = 'Directory';
									|pl = 'Catalog';
									|tr = 'Katalog'");
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("96c6ab56-0375-40d5-99a2-b83efa3dac8b");
	String.Name             = "Documents";
	String.Synonym         = NStr("vi = 'Chứng từ';
									|ru = 'Документы';
									|en = 'Documents'; fa = 'اسناد';
									|it = 'Documenti';
									|pl = 'Dokumenty';
									|tr = 'Belgeler'");
	String.SingularName     = "Document";
	String.SingularSynonym = NStr("vi = 'Chứng từ';
									|ru = 'Документ';
									|en = 'Document'; fa = 'سند';
									|it = 'Documento';
									|pl = 'Dokument';
									|tr = 'Belge'");
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("07938234-e29b-4cff-961a-9af07a4c6185");
	String.Name             = "DocumentJournals";
	String.Synonym         = NStr("vi = 'Nhật ký chứng từ';
									|ru = 'Журналы документов';
									|en = 'Document journals'; fa = 'Document journals';
									|it = 'Registri dei documenti';
									|pl = 'Dzienniki dokumentów';
									|tr = 'Belge günlükleri'");
	String.SingularName     = "DocumentJournal";
	String.SingularSynonym = NStr("vi = 'Nhật ký chứng từ';
									|ru = 'Журнал документов';
									|en = 'Document journal'; fa = 'دفتر اسناد';
									|it = 'File log';
									|pl = 'Dziennik dokumentów';
									|tr = 'Belge günlüğü'");
	String.NoData       = True;
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("706cf832-0ae5-45b5-8a4a-1f251d054f3b");
	String.Name             = "Reports";
	String.Synonym         = NStr("vi = 'Báo cáo';
									|ru = 'Отчеты';
									|en = 'Reports'; fa = 'گزارش‌ها';
									|it = 'Report';
									|pl = 'Reports';
									|tr = 'Raporlar'");
	String.SingularName     = "Report";
	String.SingularSynonym = NStr("vi = 'Báo cáo';
									|ru = 'Отчет';
									|en = 'Report'; fa = 'گزارش';
									|it = 'Report';
									|pl = 'Report';
									|tr = 'Rapor'");
	String.NoData       = True;
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("ae480426-487e-40b2-98ba-d207777449f3");
	String.Name             = "DataProcessors";
	String.Synonym         = NStr("vi = 'Bộ xử lý';
									|ru = 'Обработки';
									|en = 'Data processors'; fa = 'Data processors';
									|it = 'Elaborazioni';
									|pl = 'Data processors';
									|tr = 'Veri işlemcileri'");
	String.SingularName     = "DataProcessor";
	String.SingularSynonym = NStr("vi = 'Bộ xử lý';
									|ru = 'Обработка';
									|en = 'Data processor'; fa = 'پردازشگر داده';
									|it = 'Elaborazione';
									|pl = 'Data processor';
									|tr = 'Veri işlemcisi'");
	String.NoData       = True;
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("8b5649b9-cdd1-4698-9aac-12ba146835c4");
	String.Name             = "ChartsOfCharacteristicTypes";
	String.Synonym         = NStr("vi = 'Hệ thống dạng đặc tính';
									|ru = 'Планы видов характеристик';
									|en = 'Charts of characteristic types'; fa = 'Charts of characteristic types';
									|it = 'Piani dei tipi di caratteristiche';
									|pl = 'Plany rodzajów charakterystyk';
									|tr = 'Özellik türü listeleri'");
	String.SingularName     = "ChartOfCharacteristicTypes";
	String.SingularSynonym = NStr("vi = 'Hệ thống dạng đặc tính';
									|ru = 'План видов характеристик';
									|en = 'Chart of characteristic types'; fa = 'Chart of characteristic types';
									|it = 'Piano dei tipi di caratteristiche';
									|pl = 'Plan rodzajów charakterystyk';
									|tr = 'Özellik türü listesi'");
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("4295af27-543f-4373-bcfc-c0ace9b7620c");
	String.Name             = "ChartsOfAccounts";
	String.Synonym         = NStr("vi = 'Hệ thống tài khoản';
									|ru = 'Планы счетов';
									|en = 'Charts of accounts'; fa = 'سرفصل‌های حساب';
									|it = 'Piani dei conti';
									|pl = 'Plany rachunków';
									|tr = 'Hesap planları'");
	String.SingularName     = "ChartOfAccounts";
	String.SingularSynonym = NStr("vi = 'Hệ thống tài khoản';
									|ru = 'План счетов';
									|en = 'Chart of accounts'; fa = 'سرفصل حساب‌ها';
									|it = 'Piano dei conti';
									|pl = 'Plan rachunków';
									|tr = 'Hesap planı'");
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("fca3e7e1-1bf1-49c8-9921-aafb4e787c75");
	String.Name             = "ChartsOfCalculationTypes";
	String.Synonym         = NStr("vi = 'Hệ thống dạng tính toán';
									|ru = 'Планы видов расчета';
									|en = 'Charts of calculation types'; fa = 'Charts of calculation types';
									|it = 'Piani dei tipi di calcolo';
									|pl = 'Plany rodzajów obliczeń';
									|tr = 'Hesaplama türü planları'");
	String.SingularName     = "ChartOfCalculationTypes";
	String.SingularSynonym = NStr("vi = 'Hệ thống dạng tính toán';
									|ru = 'План видов расчета';
									|en = 'Chart of calculation types'; fa = 'Chart of calculation types';
									|it = 'Piano dei tipi di calcolo';
									|pl = 'Plan rodzajów rozliczenia';
									|tr = 'Hesaplama plan türü'");
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("d7ecc1e9-c068-44dd-83c2-1323ec52dbbb");
	String.Name             = "InformationRegisters";
	String.Synonym         = NStr("vi = 'Biểu ghi thông tin';
									|ru = 'Регистры сведений';
									|en = 'Information registers'; fa = 'ثبت‌های اطلاعاتی';
									|it = 'Registri delle informazioni';
									|pl = 'Rejestry informacji';
									|tr = 'Bilgi kayıtları'");
	String.SingularName     = "InformationRegister";
	String.SingularSynonym = NStr("vi = 'Biểu ghi thông tin';
									|ru = 'Регистр сведений';
									|en = 'Information register'; fa = 'Information register';
									|it = 'Registro dati';
									|pl = 'Rejestr informacji';
									|tr = 'Bilgi kaydı'");
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("74083488-b01e-4441-84a6-c386ce88cdb5");
	String.Name             = "AccumulationRegisters";
	String.Synonym         = NStr("vi = 'Biểu ghi tích lũy';
									|ru = 'Регистры накопления';
									|en = 'Accumulation registers'; fa = 'ثبت‌های انباشتی';
									|it = 'Registri di accumulo';
									|pl = 'Rejestry kumulacji';
									|tr = 'Birikim kayıtları'");
	String.SingularName     = "AccumulationRegister";
	String.SingularSynonym = NStr("vi = 'Biểu ghi tích lũy';
									|ru = 'Регистр накопления';
									|en = 'Accumulation register'; fa = 'Accumulation register';
									|it = 'Registro di accumulo';
									|pl = 'Rejestr akumulacji';
									|tr = 'Birikim kaydı'");
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("9a0d75ff-0eda-454e-b2b7-d2412ffdff18");
	String.Name             = "AccountingRegisters";
	String.Synonym         = NStr("vi = 'Biểu ghi kế toán';
									|ru = 'Регистры бухгалтерии';
									|en = 'Accounting registers'; fa = 'Accounting registers';
									|it = 'Registri contabilità';
									|pl = 'Rejestry księgowości';
									|tr = 'Muhasebe kayıtları'");
	String.SingularName     = "AccountingRegister";
	String.SingularSynonym = NStr("vi = 'Biểu ghi kế toán';
									|ru = 'Регистр бухгалтерии';
									|en = 'Accounting register'; fa = 'Accounting register';
									|it = 'Registro contabilità';
									|pl = 'Rejestr księgowości';
									|tr = 'Muhasebe kaydı'");
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("f330686a-0acf-4e26-9cda-108f1404687d");
	String.Name             = "CalculationRegisters";
	String.Synonym         = NStr("vi = 'Biểu ghi tính toán';
									|ru = 'Регистры расчета';
									|en = 'Calculation registers'; fa = 'Calculation registers';
									|it = 'Registri di calcolo';
									|pl = 'Rejestry rozliczenia';
									|tr = 'Mutabakat işlemleri kayıtları'");
	String.SingularName     = "CalculationRegister";
	String.SingularSynonym = NStr("vi = 'Biểu ghi tính toán';
									|ru = 'Регистр расчета';
									|en = 'Calculation register'; fa = 'Calculation register';
									|it = 'Registro di calcolo';
									|pl = 'Rejestr rozliczenia';
									|tr = 'Hesaplama kaydı'");
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("a8cdd0e0-c27f-4bf0-9718-10ec054dc468");
	String.Name             = "BusinessProcesses";
	String.Synonym         = NStr("vi = 'Quy trình nghiệp vụ';
									|ru = 'Бизнес-процессы';
									|en = 'Business processes'; fa = 'فرایندهای تجاری';
									|it = 'Processi aziendali';
									|pl = 'Business processes';
									|tr = 'İş süreçleri'");
	String.SingularName     = "BusinessProcess";
	String.SingularSynonym = NStr("vi = 'Quy trình nghiệp vụ';
									|ru = 'Бизнес-процесс';
									|en = 'Business process'; fa = 'فرایند کسب‌وکار';
									|it = 'Processo aziendale';
									|pl = 'Business process';
									|tr = 'İş süreci'");
	String.ExtensionsObjects = True;
	
	String = Result.Add();
	String.Id   = New UUID("8d9153ad-7cea-4e25-9542-a557ee59fd16");
	String.Name             = "Tasks";
	String.Synonym         = NStr("vi = 'Nhiệm vụ';
									|ru = 'Задачи';
									|en = 'Tasks'; fa = 'وظایف';
									|it = 'Obiettivi';
									|pl = 'Tasks';
									|tr = 'Görevler'");
	String.SingularName     = "Task";
	String.SingularSynonym = NStr("vi = 'Nhiệm vụ';
									|ru = 'Задача';
									|en = 'Task'; fa = 'وظیفه';
									|it = 'Obiettivo';
									|pl = 'Task';
									|tr = 'Görev'");
	String.ExtensionsObjects = True;
	
	For Each String In Result Do
		String.CollectionOrder = Result.IndexOf(String);
	EndDo;
	
	If ExtensionsObjects Then
		Result = Result.Copy(New Structure("ExtensionsObjects", True));
	EndIf;
	
	Result.Indexes.Add("Id");
	Result.Indexes.Add("Name");
	
	Return Result;
	
EndFunction

// Prevents illegal modification of the metadata object IDs.
// Processes duplicate objects in a subordinate node of the distributed infobase.
//
// Parameters:
//   Object - CatalogObject.MetadataObjectIDs
//          - CatalogObject.ExtensionObjectIDs
//
Procedure BeforeWriteObject(Object) Export
	
	// ACC:75-off - The DataExchange.Load check must follow the mandatory actions.
	ExtensionsObjects = IsExtensionsObject(Object);
	StandardSubsystemsCached.MetadataObjectIDsUsageCheck(, ExtensionsObjects);
	
	// Disabling the object registration mechanism.
	Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	
	// Registering the object in all DIB nodes.
	For Each ExchangePlan In StandardSubsystemsCached.DIBExchangePlans() Do
		StandardSubsystemsServer.RecordObjectChangesInAllNodes(Object, ExchangePlan, False);
	EndDo;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	UpdateIsCompleted = New Structure(SessionParameters.UpdateIDCatalogs);
	If ExtensionsObjects Then
		UpdateIsCompleted.ExtensionObjectIDs = False;
	Else
		UpdateIsCompleted.MetadataObjectIDs = False;
	EndIf;
	SessionParameters.UpdateIDCatalogs = New FixedStructure(UpdateIsCompleted);
	
	AdditionalProperties = New Structure("StandardSubsystemsOldValues");
	FillPropertyValues(AdditionalProperties, Object.AdditionalProperties);
	If AdditionalProperties.StandardSubsystemsOldValues = Undefined Then
		Object.AdditionalProperties.Insert("StandardSubsystemsOldValues",
			Common.ObjectAttributesValues(Object.Ref,
				New FixedStructure(PreviousValuesNewStructure())));
	EndIf;
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	// ACC:75-on
	
	If Object.DataExchange.Load Then
		Return;
	EndIf;
	
	CheckObjectBeforeWrite(Object);
	
EndProcedure

// Parameters:
//   Object - CatalogObject.MetadataObjectIDs
//          - CatalogObject.ExtensionObjectIDs
//
Procedure AtObjectWriting(Object) Export
	
	// ACC:75-off - The DataExchange.Load check must follow the mandatory actions.
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	AdditionalProperties = New Structure("StandardSubsystemsMetadataObject", "");
	FillPropertyValues(AdditionalProperties, Object.AdditionalProperties);
	If AdditionalProperties.StandardSubsystemsMetadataObject = "" Then
		IDs = CommonClientServer.ValueInArray(Object.Ref);
		If TypeOf(Object.Ref) = Type("CatalogRef.MetadataObjectIDs") Then
			ConfigurationIDs = CommonClientServer.ValueInArray(Object.Ref);
			ExtensionsIDs = New Array;
		Else
			ConfigurationIDs = New Array;
			ExtensionsIDs = CommonClientServer.ValueInArray(Object.Ref);
		EndIf;
		Try
			MetadataObjects = MetadataObjectsByIDsWithoutRetryAttempt(IDs,
				ConfigurationIDs, ExtensionsIDs, False);
			MetadataObjectDetails = MetadataObjects.Get(Object.Ref);
		Except
			MetadataObjectDetails = Null;
		EndTry;
		
		Object.AdditionalProperties.Insert("StandardSubsystemsMetadataObject",
			?(TypeOf(MetadataObjectDetails) = Type("Structure"),
				MetadataObjectDetails.Object, MetadataObjectDetails));
	EndIf;
	
	PreviousValues1 = Object.AdditionalProperties.StandardSubsystemsOldValues;
	
	If Common.SeparatedDataUsageAvailable()
	   And UsersInternal.ShouldRegisterChangesInAccessRights()
	   And Common.SubsystemExists("StandardSubsystems.AccessManagement")
	   And (IsRoleKey(Object.MetadataObjectKey.Get())
	      Or TypeOf(PreviousValues1.MetadataObjectKey) = Type("ValueStorage")
	        And IsRoleKey(PreviousValues1.MetadataObjectKey.Get())) Then
		
		ModuleAccessGroupsProfiles = Common.CommonModule("Catalogs.AccessGroupProfiles");
		ModuleAccessGroupsProfiles.RegisterChangeInProfilesRoles(Object,
			PreviousValues1, Object.AdditionalProperties.StandardSubsystemsMetadataObject);
	EndIf;
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	// ACC:75-on
	
	If Object.DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

// Prevents the metadata object IDs without deletion mark from being deleted.
//
// Parameters:
//   Object - CatalogObject.MetadataObjectIDs
//          - CatalogObject.ExtensionObjectIDs
//
Procedure BeforeDeleteObject(Object) Export
	
	ExtensionsObjects = IsExtensionsObject(Object);
	StandardSubsystemsCached.MetadataObjectIDsUsageCheck(, ExtensionsObjects);
	
	// Disable the object registration mechanism.
	// ID references are deleted independently in all nodes
	// by the marked object deletion mechanism.
	Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	
	If Object.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Object.DeletionMark Then
		RaiseByError(ExtensionsObjects,
			NStr("vi = 'Không được phép xóa tên định danh của các đối tượng có giá trị
			           |của mục tin ""Đặt dấu xóa"" đã thiết lập Sai.';
			           |ru = 'Удаление идентификаторов объектов, у которых значение
			           |реквизита ""Пометка удаления"" установлено Ложь недопустимо.';
			           |en = 'Cannot delete IDs of objects that have
			           |the ""Deletion mark"" attribute set to False.'; fa = 'Cannot delete IDs of objects that have
			           |the ""Deletion mark"" attribute set to False.';
			           |it = 'La cancellazione degli identificatori degli oggetti, il cui valore
			           |del requisito ""Contrassegno di cancellazione"" è impostato a Falso non è ammessa.';
			           |pl = 'Usuwanie identyfikatorów obiektów, dla których wartość
			           |atrybutu ""Zaznaczenie usunięcia"" ustawiono Fałsz jest niedozwolone.';
			           |tr = '""Silme işareti"" öznitelik değeri 
			           |""False"" olarak ayarlanmış olan meta veri nesnesi kimlik silme işlemi geçersizdir.'"));
	EndIf;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - ClientApplicationForm:
//   * List - DynamicList
//
Procedure ListFormOnCreateAtServer(Form) Export
	
	SetListOrderAndAppearance(Form);
	
	If Form.Parameters.ChoiceMode Then
		StandardSubsystemsServer.SetFormAssignmentKey(Form, "SelectionPick");
		Form.WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	Else
		Form.Items.List.ChoiceMode = False;
	EndIf;
	
	Form.SelectMetadataObjectsGroups = Form.Parameters.SelectMetadataObjectsGroups;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - ClientApplicationForm:
//   * Object - FormDataStructure:
//    ** Ref - CatalogRef.MetadataObjectIDs
//              - CatalogRef.ExtensionObjectIDs
//    
Procedure ItemFormOnCreateAtServer(Form) Export
	
	ExtensionsObjects = IsExtensionsObject(Form.Object.Ref);
	
	Items  = Form.Items;
	
	Form.ReadOnly = True;
	Form.EmptyRefPresentation = String(TypeOf(Form.Object.EmptyRefValue));
	
	If Not Users.IsFullUser(, Not ExtensionsObjects)
	 Or CannotChangeFullName(Form.Object)
	 Or Not ExtensionsObjects And Common.IsSubordinateDIBNode()
	 Or ExtensionsObjects And Catalogs.ExtensionObjectIDs.ExtensionObjectDisabled(Form.Object.Ref) Then
		
		Items.FormEnableEditing.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region AuxiliaryProceduresAndFunctions

// For the ImportDataToSubordinateNode procedure.
// 
// Parameters:
//  Upload0 - See ExportAllIDs
//
Procedure FindDuplicatesOnImportDataToSubordinateNode(Upload0, Filter, ObjectToImport, ObjectToImportRef, ItemsToImportTable)
	
	Rows = Upload0.FindRows(Filter);
	For Each String In Rows Do
		
		If String.Ref <> ObjectToImportRef
		   And ItemsToImportTable.Find(String.Ref, "Ref") = Undefined Then
			
			UpdateMarkedForDeletionItemProperties(String,,, True);
			String.NewRef = ObjectToImportRef;
			String.DuplicateUpdated = True;
			ObjectToImport.AdditionalProperties.Insert("IsDuplicateReplacement");
			// Replacing new references to the duplicate with a new reference specified for the duplicate (if any).
			PreviousDuplicates = Upload0.FindRows(New Structure("NewRef", String.Ref));
			For Each PreviousDuplicate In PreviousDuplicates Do
				UpdateMarkedForDeletionItemProperties(PreviousDuplicate,,, True);
				PreviousDuplicate.NewRef = ObjectToImportRef;
				PreviousDuplicate.DuplicateUpdated = True;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

Procedure UpdateData1(HasChanges, HasDeletedItems, IsCheckOnly,
			HasCriticalChanges, ListOfCriticalChanges, ExtensionsObjects)
	
	If ExtensionsObjects Then
		ExtensionProperties = New Structure;
		DatabaseExtensions = New Array;
		ExtensionKeyIds = ExtensionKeyIds(DatabaseExtensions);
		ExtensionProperties.Insert("AttachedExtensionsNames",
			ExtensionNames(ConfigurationExtensionsSource.SessionApplied, ExtensionKeyIds));
		ExtensionProperties.Insert("UnattachedExtensionsNames",
			ExtensionNames(ConfigurationExtensionsSource.SessionDisabled, ExtensionKeyIds));
		AddNamesOfUnconnectedExtensionsInSessionWithoutDelimiters(ExtensionProperties, DatabaseExtensions);
	EndIf;
	
	MetadataObjectProperties1 = MetadataObjectProperties1(ExtensionsObjects,, ExtensionKeyIds);
	
	// Found - this status indicates that ID is found for the metadata object.
	MetadataObjectProperties1.Columns.Add("Found", New TypeDescription("Boolean"));
	
	// Update procedure:
	// 1. Rename metadata objects considering the child subsystems.
	// 2. Update the IDs of predefined metadata object collections.
	// 3. Update the IDs of metadata objects that have metadata object keys.
	// 4. Update the IDs of metadata objects that don't have metadata object keys.
	// 5. Mark the duplicate IDs from steps 3 and 4 for deletion (by the objects' full names).
	// 6. Assign new IDs.
	// 7. Update the parents of the IDs and write them.
	
	ExtensionsVersion = SessionParameters.ExtensionsVersion;
	
	Block = New DataLock;
	LockItem = Block.Add(CatalogName(ExtensionsObjects));
	If ExtensionsObjects Then
		LockItem = Block.Add("InformationRegister.ExtensionVersionObjectIDs");
		LockItem.SetValue("ExtensionsVersion", ExtensionsVersion);
	EndIf;
	
	BeginTransaction();
	Try
		Block.Lock();
		
		Upload0 = ExportAllIDs(ExtensionsObjects);
		Upload0.Columns.Add("Updated", New TypeDescription("Boolean"));
		Upload0.Columns.Add("MetadataObject");
		Upload0.Columns.Delete("NewRef");
		
		MetadataObjectRenamingList = "";
		If Not ExtensionsObjects
		   And Not Common.IsSubordinateDIBNode() Then
			// Change the full names before processing (for DIB, it applies to the master node only).
			// Not supported for extensions.
			RenameFullNames(Upload0, MetadataObjectRenamingList, HasCriticalChanges);
		EndIf;
		
		ProcessMetadataObjectIDs(Upload0, MetadataObjectProperties1, ExtensionsObjects,
			ExtensionProperties, HasDeletedItems, HasCriticalChanges, MetadataObjectRenamingList);
		
		NewMetadataObjectsList = "";
		AddNewMetadataObjectsIDs(Upload0, MetadataObjectProperties1, ExtensionsObjects,
			HasCriticalChanges, NewMetadataObjectsList);
		
		ListOfCriticalChanges = "";
		If ValueIsFilled(MetadataObjectRenamingList) Then
			ListOfCriticalChanges = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đổi tên định danh đối tượng metadata %1 -> %2:';
					|ru = 'Переименование идентификаторов объектов метаданных %1 -> %2:';
					|en = 'Rename IDs of metadata objects %1->%2:'; fa = 'Rename IDs of metadata objects %1->%2:';
					|it = 'Denominazione ID oggetti di metadati %1 ->%2:';
					|pl = 'Zmiana nazwy identyfikatorów obiektów metadanych %1 -> %2:';
					|tr = 'Meta veri nesnelerinin kimliklerinin yeniden adlandırılması %1 -> %2:'"),
				"PreviousFullName",
				"NewFullName");
			ListOfCriticalChanges = ListOfCriticalChanges + Chars.LF
				+ MetadataObjectRenamingList + Chars.LF + Chars.LF;
		EndIf;
		If ValueIsFilled(NewMetadataObjectsList) Then
			ListOfCriticalChanges = ListOfCriticalChanges
				+ NStr("vi = 'Thêm tên định danh mới của đối tượng metadata:';
						|ru = 'Добавление новых идентификаторов объектов метаданных:';
						|en = 'Added metadata object IDs:'; fa = 'Added metadata object IDs:';
						|it = 'Aggiunta di nuovi identificatori degli oggetti dei metadati:';
						|pl = 'Dodawanie nowych identyfikatorów obiektów metadanych:';
						|tr = 'Yeni meta veri nesne tanımlayıcıları ekle:'")
				+ Chars.LF + NewMetadataObjectsList + Chars.LF;
		EndIf;
		
		If Not IsCheckOnly
		   And Not ExtensionsObjects
		   And ValueIsFilled(ListOfCriticalChanges)
		   And Common.IsSubordinateDIBNode() Then
			
			EventName = NStr("vi = 'Tên định danh đối tượng metadata. Cần kết nhập những thay đổi quan trọng';
							|ru = 'Идентификаторы объектов метаданных.Требуется загрузить критичные изменения';
							|en = 'Metadata object IDs.Import of critical changes required'; fa = 'Metadata object IDs.Import of critical changes required';
							|it = 'Identificatori degli oggetti dei metadati. È necessario caricare modifiche critiche';
							|pl = 'Identyfikatory obiektów metadanych.Wymagane jest pobranie krytycznych zmian.';
							|tr = 'Meta veri nesne kimlikleri. Kritik değişiklikleri içe aktar'",
				Common.DefaultLanguageCode());
			
			EventLog.AddMessageForEventLog(EventName, EventLogLevel.Error, , , ListOfCriticalChanges);
			
			RaiseByError(ExtensionsObjects,
				NStr("vi = 'Chỉ có thể thực hiện các thay đổi quan trọng
				           | trong nút chính của cơ sở thông tin phân tán.
				           |Thành phần các thay đổi cần thiết xem trong nhật ký sự kiện.';
				           |ru = 'Критичные изменения могут быть выполнены только
				           |в главном узле распределенной информационной базы.
				           |Состав требуемых изменений см. в журнале регистрации.';
				           |en = 'Critical changes can only be applied
				           |to the master node of the distributed infobase.
				           |For the list of changes, see the event log.'; fa = 'Critical changes can only be applied
				           |to the master node of the distributed infobase.
				           |For the list of changes, see the event log.';
				           |it = 'Modifiche critiche possono essere effettuate solo
				           |nel nodo principale del database informatico suddiviso.
				           |Vedere la composizione delle modifiche necessarie nel registro di registrazione.';
				           |pl = 'Zmiany krytyczne mogą zostać wykonane tylko
				           |w węźle głównym rozproszonej bazy informacyjnej.
				           |Skład wymaganych zmian zob. w dzienniku rejestracji.';
				           |tr = 'Önemli değişiklikler yalnızca
				           |dağıtılmış Infobase''in ana düğümüne uygulanabilir.
				           |Değişiklik listesi için olay günlüğüne bakın.'"));
		EndIf;
		
		HasCurrentChanges = False;
		UpdateMetadataObjectIDs(Upload0, MetadataObjectProperties1, ExtensionsObjects,
			ExtensionProperties, ExtensionsVersion, HasCurrentChanges, IsCheckOnly);
		
		If HasCurrentChanges Then
			HasChanges = True;
		EndIf;
		
		If Not IsCheckOnly Then
			If Not ExtensionsObjects And HasCurrentChanges Then
				StandardSubsystemsServer.CheckApplicationVersionDynamicUpdate();
			EndIf;
			If ValueIsFilled(ListOfCriticalChanges) Then
				EventLog.AddMessageForEventLog(?(ExtensionsObjects,
						NStr("vi = 'Tên định danh đối tượng phần mở rộng.Thực hiện các thay đổi quan trọng';
							|ru = 'Идентификаторы объектов расширений.Выполнены критичные изменения';
							|en = 'Extension object IDs.Critical changes applied'; fa = 'Extension object IDs.Critical changes applied';
							|it = 'Identificatori degli oggetti delle estensioni. Modifiche critiche effettuate';
							|pl = 'Identyfikatory obiektów rozszerzeń.Dokonano krytycznych zmian';
							|tr = 'Meta veri nesne kimlikleri. Kritik değişiklikler yapıldı'",
							Common.DefaultLanguageCode()),
						NStr("vi = 'Tên định danh đối tượng metadata. Đã thực hiện các thay đổi quan trọng';
							|ru = 'Идентификаторы объектов метаданных.Выполнены критичные изменения';
							|en = 'Metadata object IDs.Critical changes applied'; fa = 'Metadata object IDs.Critical changes applied';
							|it = 'Identificatori degli oggetti dei metadati. Modifiche critiche effettuate';
							|pl = 'Identyfikatory obiektów metadanych.Dokonano krytycznych zmian';
							|tr = 'Meta veri nesne kimlikleri. Kritik değişiklikler yapıldı'",
							Common.DefaultLanguageCode())),
					EventLogLevel.Information,,,
					ListOfCriticalChanges);
			EndIf;
			
			If Not ExtensionsObjects
			   And Not Common.IsSubordinateDIBNode() Then
				
				PrepareNewSubsystemsListInMasterNode(Upload0);
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns:
//  ValueTable:
//   * Ref - CatalogRef.MetadataObjectIDs
//            - CatalogRef.ExtensionObjectIDs
//   * PredefinedDataName - String
//   * Parent - CatalogRef.MetadataObjectIDs
//              - CatalogRef.ExtensionObjectIDs
//   * DeletionMark - Boolean
//   * Description - String
//   * CollectionOrder - Number
//   * Name - String
//   * Synonym - String
//   * FullName - String
//   * FullSynonym - String
//   * NoData - Boolean
//   * EmptyRefValue - CatalogRef.MetadataObjectIDs
//                          - CatalogRef.ExtensionObjectIDs
//   * KeyStorage - ValueStorage
//   * NewRef - CatalogRef.MetadataObjectIDs
//                 - CatalogRef.ExtensionObjectIDs
//   * ExtensionName - String
//   * ExtensionID - String
//   * ExtensionHashsum - String
//   * MetadataObjectKey - Type
//                           - String
//                           - Undefined
//   * NoMetadataObjectKey - Boolean
//   * IsCollection - Boolean
//   * IsNew - Boolean
//
Function ExportAllIDs(ExtensionsObjects = False)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	IDs.Ref AS Ref,
	|	IDs.PredefinedDataName AS PredefinedDataName,
	|	IDs.Parent AS Parent,
	|	IDs.DeletionMark AS DeletionMark,
	|	IDs.Description AS Description,
	|	IDs.CollectionOrder,
	|	IDs.Name,
	|	IDs.Synonym,
	|	IDs.FullName,
	|	IDs.FullSynonym,
	|	IDs.NoData,
	|	IDs.EmptyRefValue,
	|	IDs.MetadataObjectKey AS KeyStorage,
	|	IDs.NewRef,
	|	&ExtensionName AS ExtensionName,
	|	&ExtensionID AS ExtensionID,
	|	&ExtensionHashsum AS ExtensionHashsum
	|FROM
	|	Catalog.MetadataObjectIDs AS IDs";
	ClarifyCatalogNameInQueryText(Query.Text, ExtensionsObjects);
	Query.Text = StrReplace(Query.Text, "&ExtensionName",
		?(ExtensionsObjects, "IDs.ExtensionName", """"""));
	Query.Text = StrReplace(Query.Text, "&ExtensionID",
		?(ExtensionsObjects, "IDs.ExtensionID", """"""));
	Query.Text = StrReplace(Query.Text, "&ExtensionHashsum",
		?(ExtensionsObjects, "IDs.ExtensionHashsum", """"""));
	
	Upload0 = Query.Execute().Unload();
	Upload0.Columns.Add("MetadataObjectKey");
	Upload0.Columns.Add("NoMetadataObjectKey", New TypeDescription("Boolean"));
	Upload0.Columns.Add("IsCollection",              New TypeDescription("Boolean"));
	Upload0.Columns.Add("IsNew",                  New TypeDescription("Boolean"));
	
	// Ordering the IDs before processing.
	For Each String In Upload0 Do
		If Not ValueIsFilled(String.Ref) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Dữ liệu của danh mục %1 bị hỏng.
				           |Trong bộ thiết kế, menu ""Quản trị hệ thống"", hãy thực hiện ""Thử nghiệm và sửa chữa..."".';
				           |ru = 'Данные справочника %1 повреждены.
				           |В конфигураторе в меню ""Администрирование"" выполните ""Тестирование и исправление..."".';
				           |en = 'The catalog ""%1"" contains corrupted data.
				           |Open Designer and select Administration > Verify and repair…'; fa = 'The catalog ""%1"" contains corrupted data.
				           |Open Designer and select Administration > Verify and repair…';
				           |it = 'Данные справочника %1 повреждены.
				           |В конфигураторе в меню ""Администрирование"" выполните ""Тестирование и исправление..."".';
				           |pl = 'The catalog ""%1"" contains corrupted data.
				           |Open Designer and select Administration > Verify and repair…';
				           |tr = '%1Katalog verileri hasar gördü.
				           |Konfigürasyonda ""Yönetim"" menüsünde ""Test ve düzeltme"" yapın.'"),
				?(ExtensionsObjects, "ExtensionObjectIDs", "MetadataObjectIDs"));
			Raise ErrorText;
		EndIf;
		If TypeOf(String.KeyStorage) = Type("ValueStorage") Then
			String.MetadataObjectKey = String.KeyStorage.Get();
		Else
			String.MetadataObjectKey = Undefined;
		EndIf;
		String.NoMetadataObjectKey = String.MetadataObjectKey = Undefined
		                               Or String.MetadataObjectKey = Type("Undefined");
	EndDo;
	
	Upload0.Indexes.Add("Ref");
	Upload0.Indexes.Add("FullName");
	
	CollectionsProperties = StandardSubsystemsCached.MetadataObjectCollectionProperties(ExtensionsObjects);
	
	For Each CollectionProperties In CollectionsProperties Do
		CollectionID = CollectionID(CollectionProperties.Id, ExtensionsObjects);
		String = Upload0.Find(CollectionID, "Ref");
		If String = Undefined Then
			String = Upload0.Add();
			String.Ref   = CollectionID;
			String.IsNew = True;
		EndIf;
		String.IsCollection = True;
	EndDo;
	
	Upload0.Sort("IsCollection DESC,
	                     |DeletionMark ASC,
	                     |NoMetadataObjectKey ASC");
	
	Return Upload0;
	
EndFunction

Procedure RenameFullNames(Upload0, MetadataObjectRenamingList = "", HasCriticalChanges = False)
	
	RenamingTable = StandardSubsystemsCached.RenamingTableForCurrentVersion();
	RenamedItems = New Map;
	
	For Each RenamingDetails In RenamingTable Do
		PreviousFullNameLength = StrLen(RenamingDetails.PreviousFullName);
		IsSubsystem = Upper(Left(RenamingDetails.PreviousFullName,
			StrLen("Subsystem."))) = Upper("Subsystem.");
		
		For Each String In Upload0 Do
			If String.IsCollection Then
				Continue;
			EndIf;
			
			NewFullName = "";
			
			If IsSubsystem Then
				If Upper(Left(String.FullName, PreviousFullNameLength))
				     = Upper(RenamingDetails.PreviousFullName) Then
					
					NewFullName = RenamingDetails.NewFullName
						+ Mid(String.FullName, PreviousFullNameLength + 1);
				EndIf;
			Else
				If Upper(String.FullName) = Upper(RenamingDetails.PreviousFullName) Then
					NewFullName = RenamingDetails.NewFullName;
				EndIf;
			EndIf;
			
			If Not ValueIsFilled(NewFullName) Then
				Continue;
			EndIf;
			
			Renaming = RenamedItems.Get(String);
			If Renaming = Undefined Then
				Renaming = New Structure;
				Renaming.Insert("PreviousFullName", String.FullName);
				Renaming.Insert("NewFullName",  NewFullName);
				RenamedItems.Insert(String, Renaming);
			Else
				Renaming.NewFullName = NewFullName;
			EndIf;
			String.FullName = NewFullName;
			String.Updated = True;
		EndDo;
	EndDo;
	
	For Each String In Upload0 Do
		Renaming = RenamedItems.Get(String);
		If Renaming = Undefined Then
			Continue;
		EndIf;
		
		HasCriticalChanges = True;
		MetadataObjectRenamingList = MetadataObjectRenamingList
			+ ?(ValueIsFilled(MetadataObjectRenamingList), "," + Chars.LF, "")
			+ Renaming.PreviousFullName + " -> " + Renaming.NewFullName;
	EndDo;
	
EndProcedure

Procedure ProcessMetadataObjectIDs(Upload0, MetadataObjectProperties1, ExtensionsObjects,
			ExtensionProperties, HasDeletedItems, HasCriticalChanges, MetadataObjectRenamingList)
	
	// Processing the metadata object IDs.
	For Each Properties In Upload0 Do
		
		// Validating and updating properties of the metadata object collection IDs.
		If Properties.IsCollection Then
			CheckUpdateCollectionProperties(Properties, ExtensionsObjects);
			Continue;
		EndIf;
		
		If ExtensionsObjects
		   And (    ExtensionProperties.UnattachedExtensionsNames[Lower(Properties.ExtensionName)] <> Undefined
		      Or ExtensionProperties.UnattachedExtensionsNames[Lower(Properties.ExtensionID)] <> Undefined)Then
			// In case the extension is disabled and then enabled, make sure
			// the objects marked for deletion are the related data are not deleted.
			Continue;
		EndIf;
		
		If ExtensionsObjects
		   And ExtensionProperties.AttachedExtensionsNames[Lower(Properties.ExtensionName)] = Undefined
		   And ExtensionProperties.AttachedExtensionsNames[Lower(Properties.ExtensionID)] = Undefined Then
			
			PropertiesUpdated = False;
			UpdateMarkedForDeletionItemProperties(Properties, PropertiesUpdated, HasDeletedItems);
			If PropertiesUpdated Then
				Properties.Updated = True;
			EndIf;
		EndIf;
		
		MetadataObjectKey = Properties.MetadataObjectKey;
		MetadataObject = MetadataObjectByKey(MetadataObjectKey,
			Properties.ExtensionName, Properties.ExtensionID, Properties.ExtensionHashsum);
		
		If MetadataObject = Undefined Then
			If MetadataObjectKey = Type("Undefined") Then
				// If the metadata object has no key, it can be found by the full name only.
				MetadataObject = MetadataFindByFullName(Properties.FullName);
				If MetadataObject = Undefined And ExtensionsObjects Then
					MetadataObject = ExtensionMetadataFindByFullName(Properties);
				EndIf;
			EndIf;
		Else
			// If a metadata object was deleted in the course of restructuring,
			// then use the old ID for the new metadata object.
			// And create new IDs for old metadata objects.
			If Upper(Left(MetadataObject.Name, StrLen("Delete"))) =  Upper("Delete")
			   And Upper(Left(Properties.Name,         StrLen("Delete"))) <> Upper("Delete") Then
				
				NewMetadataObject = MetadataFindByFullName(Properties.FullName);
				If NewMetadataObject <> Undefined Then
					MetadataObject = NewMetadataObject;
					MetadataObjectKey = Undefined; // Required for the ID update.
				EndIf;
			EndIf;
		EndIf;
		
		// If the metadata object is found by key or full name,
		// prepare a string with the metadata object's properties.
		If MetadataObject <> Undefined Then
			ObjectProperties = MetadataObjectProperties1.Find(MetadataObject.FullName(), "FullName");
			If ObjectProperties = Undefined Then
				MetadataObject = Undefined;
			Else
				Properties.MetadataObject = MetadataObject;
			EndIf;
		EndIf;
		
		If MetadataObject = Undefined Or ObjectProperties.Found Then
			// If the object is not found or re-found,
			// mark its ID for deletion.
			IsDuplicate = MetadataObject <> Undefined And ObjectProperties.Found;
			PropertiesUpdated = False;
			UpdateMarkedForDeletionItemProperties(Properties, PropertiesUpdated, HasDeletedItems, IsDuplicate);
			If PropertiesUpdated Then
				Properties.Updated = True;
			EndIf;
		Else
			// Updating properties of the existing metadata objects (if any changes were made).
			ObjectProperties.Found = True;
			If Properties.Description              <> ObjectProperties.Description
			 Or Properties.CollectionOrder          <> ObjectProperties.CollectionOrder
			 Or Properties.Name                       <> ObjectProperties.Name
			 Or Properties.Synonym                   <> ObjectProperties.Synonym
			 Or Properties.FullName                 <> ObjectProperties.FullName
			 Or Properties.FullSynonym             <> ObjectProperties.FullSynonym
			 Or Properties.NoData                 <> ObjectProperties.NoData
			 Or Properties.EmptyRefValue      <> ObjectProperties.EmptyRefValue
			 Or Properties.ExtensionName             <> ObjectProperties.ExtensionName
			 Or Properties.ExtensionID   <> ObjectProperties.ExtensionID
			 Or Properties.ExtensionHashsum        <> ObjectProperties.ExtensionHashsum
			 Or Properties.PredefinedDataName <> ObjectProperties.PredefinedDataName
			 Or Properties.DeletionMark
			 Or MetadataObjectKey = Undefined
			 Or ObjectProperties.NoMetadataObjectKey
			     <> (MetadataObjectKey = Type("Undefined")) Then
				
				If Upper(Properties.FullName) <> Upper(ObjectProperties.FullName) Then
					HasCriticalChanges = True;
					MetadataObjectRenamingList = MetadataObjectRenamingList
						+ ?(ValueIsFilled(MetadataObjectRenamingList), "," + Chars.LF, "")
						+ Properties.FullName + " -> " + ObjectProperties.FullName;
				EndIf;
				
				// Setting new properties for the metadata object ID.
				FillPropertyValues(Properties, ObjectProperties);
				
				Properties.PredefinedDataName = ObjectProperties.PredefinedDataName;
				
				If MetadataObjectKey = Undefined
				 Or ObjectProperties.NoMetadataObjectKey
				     <> (MetadataObjectKey = Type("Undefined")) Then
					
					Properties.MetadataObjectKey = MetadataObjectKey(ObjectProperties.FullName);
				EndIf;
				
				Properties.DeletionMark = False;
				Properties.Updated = True;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Function ExtensionMetadataFindByFullName(Properties)
	
	If Properties.ExtensionName = ""
	 Or Not StrStartsWith(Properties.FullName, "? ") Then
		Return Undefined;
	EndIf;
	
	// Restore the link with the metadata object ID of the extension
	// that is being reinstalled.
	OriginalFullName = FullNameOfDeletedItem(Properties.FullName);
	MetadataObject = MetadataFindByFullName(OriginalFullName);
	
	If MetadataObject = Undefined Then
		Return Undefined;
	EndIf;
	
	ObjectExtension = MetadataObject.ConfigurationExtension();
	If ObjectExtension = Undefined Then
		Return Undefined;
	EndIf;
	
	If Lower(ObjectExtension.UUID) = Lower(Mid(Properties.ExtensionID, 3))
	 Or Lower(ObjectExtension.Name) = Lower(Mid(Properties.ExtensionName, 3)) Then
		
		Return MetadataObject;
	EndIf;
	
	Return Undefined;
	
EndFunction

Function ExtensionKeyIds(DatabaseExtensions = Undefined)
	
	Extensions = ConfigurationExtensions.Get();
	ExtensionKeyIds = New Map;
	For Each Extension In Extensions Do
		ExtensionKey = Lower(Extension.Name) + " " + Base64String(Extension.HashSum);
		ExtensionKeyIds.Insert(ExtensionKey, Lower(Extension.UUID));
		If TypeOf(DatabaseExtensions) = Type("Array") Then
			DatabaseExtensions.Add(Extension);
		EndIf;
	EndDo;
	
	Return ExtensionKeyIds;
	
EndFunction

Procedure AddNewMetadataObjectsIDs(Upload0, MetadataObjectProperties1, ExtensionsObjects,
			HasCriticalChanges, NewMetadataObjectsList)
	
	ObjectProperties = MetadataObjectProperties1.FindRows(New Structure("Found", False));
	
	For Each Var_166_ObjectProperties In ObjectProperties Do
		Properties = Upload0.Add();
		FillPropertyValues(Properties, Var_166_ObjectProperties);
		Properties.IsNew = True;
		Properties.Ref = NewCatalogRef(ExtensionsObjects);
		Properties.DeletionMark  = False;
		Properties.MetadataObject = Var_166_ObjectProperties.MetadataObject;
		Properties.MetadataObjectKey = MetadataObjectKey(Properties.FullName);
		HasCriticalChanges = True;
		NewMetadataObjectsList = NewMetadataObjectsList
			+ ?(ValueIsFilled(NewMetadataObjectsList), "," + Chars.LF, "")
			+ Var_166_ObjectProperties.FullName;
	EndDo;
	
EndProcedure

Procedure UpdateMetadataObjectIDs(Upload0, MetadataObjectProperties1, ExtensionsObjects,
			ExtensionProperties, ExtensionsVersion, HasChanges, IsCheckOnly)
		
	// ACC:1327-off #783.1.4.1 Managed lock is set in the calling code.
	If ExtensionsObjects Then
		RecordSet = InformationRegisters.ExtensionVersionObjectIDs.CreateRecordSet();
		RecordSet.Filter.ExtensionsVersion.Set(ExtensionsVersion);
		RecordSet.Read();
		RecordsTable = RecordSet.Unload();
		RecordsTable.Columns.Add("Delete", New TypeDescription("Boolean"));
		RecordsTable.FillValues(True, "Delete");
		RecordsTable.Indexes.Add("Id, FullObjectName, ExtensionsVersion");
		UpdateRecordSet = False;
	EndIf;
	
	For Each Properties In Upload0 Do
		
		// Updating parents of the metadata object IDs.
		If Not Properties.IsCollection Then
			ObjectProperties = MetadataObjectProperties1.Find(Properties.FullName, "FullName");
			NewParent = EmptyCatalogRef(ExtensionsObjects);
			
			If ObjectProperties <> Undefined Then
				If Not ValueIsFilled(ObjectProperties.FullParentName) Then
					// This is a collection of metadata objects.
					NewParent = ObjectProperties.Parent;
				Else
					// This is not a collection of metadata objects. Example: subsystem.
					ParentDetails = Upload0.Find(ObjectProperties.FullParentName, "FullName");
					If ParentDetails = Undefined Then
						NewParent = ObjectProperties.Parent;
					Else
						NewParent = ParentDetails.Ref;
					EndIf;
				EndIf;
			EndIf;
			
			If Properties.Parent <> NewParent Then
				Properties.Parent = NewParent;
				Properties.Updated = True;
			EndIf;
			
			If ExtensionsObjects
			   And Properties.DeletionMark = False
			   And ExtensionProperties.UnattachedExtensionsNames[Lower(Properties.ExtensionName)] = Undefined
			   And ExtensionProperties.UnattachedExtensionsNames[Lower(Properties.ExtensionID)] = Undefined Then
				
				Filter = New Structure;
				Filter.Insert("ExtensionsVersion", ExtensionsVersion);
				Filter.Insert("Id",    Properties.Ref);
				Filter.Insert("FullObjectName", Properties.FullName);
				Rows = RecordsTable.FindRows(Filter);
				If Rows.Count() = 0 Then
					UpdateRecordSet = True;
					FillPropertyValues(RecordsTable.Add(), Filter);
				Else
					Rows[0].Delete = False;
				EndIf;
			EndIf;
		EndIf;
		
		// Updating the metadata object IDs.
		If Not Properties.IsNew And Not Properties.Updated Then
			Continue;
		EndIf;
		
		HasChanges = True;
		If IsCheckOnly Then
			Return;
		EndIf;
		
		PreviousValues1 = PreviousValuesNewStructure();
		If Properties.IsNew Then
			TableObject = CreateCatalogItem(ExtensionsObjects);
			TableObject.SetNewObjectRef(Properties.Ref);
		Else
			TableObject = Properties.Ref.GetObject();
			FillPropertyValues(PreviousValues1, TableObject);
		EndIf;
		
		FillPropertyValues(TableObject, Properties);
		TableObject.MetadataObjectKey = New ValueStorage(Properties.MetadataObjectKey);
		TableObject.DataExchange.Load = True;
		// @skip-check query-in-loop - In the called version, the branch with the request is not used
		CheckObjectBeforeWrite(TableObject, True);
		TableObject.AdditionalProperties.Insert("StandardSubsystemsOldValues", PreviousValues1);
		TableObject.AdditionalProperties.Insert("StandardSubsystemsMetadataObject",
			?(TypeOf(Properties.MetadataObject) = Type("MetadataObject"), Properties.MetadataObject, Null));
		TableObject.Write();
	EndDo;
	
	If ExtensionsObjects Then
		RecordsTable.Indexes.Add("Delete");
		Rows = RecordsTable.FindRows(New Structure("Delete", True));
		If Rows.Count() > 0
		   And (Rows.Count() <> 1
		      Or ValueIsFilled(Rows[0].FullObjectName)
		        And Rows[0].ExtensionsVersion = ExtensionsVersion) Then
			UpdateRecordSet = True;
			For Each String In Rows Do
				RecordsTable.Delete(String);
			EndDo;
		EndIf;
		If RecordsTable.Count() = 0
		   And ValueIsFilled(ExtensionsVersion) Then
			// In case the extension has no metadata object, add one record
			// so that the cache check returns "True".
			RecordsTable.Add().ExtensionsVersion = ExtensionsVersion;
			UpdateRecordSet = True;
		EndIf;
		If UpdateRecordSet Then
			HasChanges = True;
			If IsCheckOnly Then
				Return;
			EndIf;
			RecordSet.Load(RecordsTable);
			RecordSet.Write();
		EndIf;
	EndIf;
	// ACC:1327-off.
	
EndProcedure

Procedure UpdateMarkedForDeletionItemProperties(Properties, PropertiesUpdated = False, HasDeletedItems = False, IsDuplicate = False)
	
	ExtensionsObjects = IsExtensionsObject(Properties.Ref);
	
	If IsDuplicate Then
		MetadataObjectKey = ?(TypeOf(Properties.MetadataObjectKey) = Type("ValueStorage"),
			Properties.MetadataObjectKey.Get(), Properties.MetadataObjectKey);
	EndIf;
	
	If Not Properties.DeletionMark
	 Or ValueIsFilled(Properties.Parent)
	 Or Left(Properties.Description, 1)  <> "?"
	 Or Left(Properties.Name, 1)           <> "?"
	 Or Left(Properties.Synonym, 1)       <> "?"
	 Or Left(Properties.FullName, 1)     <> "?"
	 Or Left(Properties.FullSynonym, 1) <> "?"
	 Or ExtensionsObjects And Left(Properties.ExtensionName, 1)           <> "?"
	 Or ExtensionsObjects And Left(Properties.ExtensionID, 1) <> "?"
	 Or ExtensionsObjects And Left(Properties.ExtensionHashsum, 1)      <> "?"
	 Or StrFind(Properties.FullName, "(") = 0
	 Or Properties.EmptyRefValue  <> Undefined
	 Or Properties.PredefinedDataName <> ""
	 Or IsDuplicate
	   And MetadataObjectKey <> Undefined Then
		
		If Not Properties.DeletionMark Or Left(Properties.FullName, 1) <> "?" Then
			HasDeletedItems = True;
		EndIf;
		
		// Setting new properties for the metadata object ID.
		Properties.DeletionMark       = True;
		Properties.Parent              = EmptyCatalogRef(IsExtensionsObject(Properties.Ref));
		Properties.Description          = InsertQuestionMark(Properties.Description);
		Properties.Name                   = InsertQuestionMark(Properties.Name);
		Properties.Synonym               = InsertQuestionMark(Properties.Synonym);
		Properties.FullName             = UniqueFullName(Properties);
		Properties.FullSynonym         = InsertQuestionMark(Properties.FullSynonym);
		Properties.EmptyRefValue  = Undefined;
		Properties.PredefinedDataName = "";
		
		If ExtensionsObjects Then
			Properties.ExtensionName           = InsertQuestionMark(Properties.ExtensionName);
			Properties.ExtensionID = InsertQuestionMark(Properties.ExtensionID);
			Properties.ExtensionHashsum      = InsertQuestionMark(Properties.ExtensionHashsum);
		EndIf;
		
		If IsDuplicate Then
			If TypeOf(Properties.MetadataObjectKey) = Type("ValueStorage") Then
				Properties.MetadataObjectKey = New ValueStorage(Undefined);
			Else
				Properties.MetadataObjectKey = Undefined;
			EndIf;
		EndIf;
		PropertiesUpdated = True;
	EndIf;
	
EndProcedure

Procedure CheckUpdateCollectionProperties(Val CurrentProperties, ExtensionsObjects)
	
	CollectionsProperties = StandardSubsystemsCached.MetadataObjectCollectionProperties(ExtensionsObjects);
	NewProperties = CollectionsProperties.Find(CurrentProperties.Ref.UUID(), "Id");
	
	CollectionDescription = NewProperties.Synonym;
	
	If CurrentProperties.Description              <> CollectionDescription
	 Or CurrentProperties.CollectionOrder          <> NewProperties.CollectionOrder
	 Or CurrentProperties.Name                       <> NewProperties.Name
	 Or CurrentProperties.Synonym                   <> NewProperties.Synonym
	 Or CurrentProperties.FullName                 <> NewProperties.Name
	 Or CurrentProperties.FullSynonym             <> NewProperties.Synonym
	 Or CurrentProperties.NoData                 <> False
	 Or CurrentProperties.EmptyRefValue      <> Undefined
	 Or CurrentProperties.PredefinedDataName <> ""
	 Or CurrentProperties.DeletionMark           <> False
	 Or CurrentProperties.MetadataObjectKey     <> Undefined Then
		
		// Set up new properties.
		CurrentProperties.Description              = CollectionDescription;
		CurrentProperties.CollectionOrder          = NewProperties.CollectionOrder;
		CurrentProperties.Name                       = NewProperties.Name;
		CurrentProperties.Synonym                   = NewProperties.Synonym;
		CurrentProperties.FullName                 = NewProperties.Name;
		CurrentProperties.FullSynonym             = NewProperties.Synonym;
		CurrentProperties.NoData                 = False;
		CurrentProperties.EmptyRefValue      = Undefined;
		CurrentProperties.PredefinedDataName = "";
		CurrentProperties.DeletionMark           = False;
		CurrentProperties.MetadataObjectKey     = Undefined;
		
		CurrentProperties.Updated = True;
	EndIf;
	
EndProcedure

// Parameters:
//  FullName - String
// 
// Returns:
//  - Type
//  - String
//
Function MetadataObjectKey(FullName)
	
	PointPosition = StrFind(FullName, ".");
	
	MetadataObjectClass = Upper(Left( FullName, PointPosition - 1));
	MetadataObjectName   = Mid(FullName, PointPosition + 1);
	
	If MetadataObjectClass = Upper("ExchangePlan") 
		Or MetadataObjectClass = Upper("Catalog")
		Or MetadataObjectClass = Upper("Document")
		Or MetadataObjectClass = Upper("ChartOfCharacteristicTypes")
		Or MetadataObjectClass = Upper("ChartOfAccounts")
		Or MetadataObjectClass = Upper("ChartOfCalculationTypes")
		Or MetadataObjectClass = Upper("BusinessProcess")
		Or MetadataObjectClass = Upper("Task") Then
		Return Type(MetadataObjectClass + "Ref." + MetadataObjectName);
		
	ElsIf MetadataObjectClass = Upper("Role") Then
		Return KeyRole(Metadata.Roles[MetadataObjectName]);
		
	ElsIf MetadataObjectClass = Upper("Constant")
		Or MetadataObjectClass = Upper("DocumentJournal") Then
		Return TypeOf(Common.ObjectManagerByFullName(FullName));
		
	ElsIf MetadataObjectClass = Upper("Report")
		Or MetadataObjectClass = Upper("DataProcessor") Then
		Return Type(MetadataObjectClass + "Object." + MetadataObjectName);
		
	ElsIf MetadataObjectClass = Upper("InformationRegister")
		Or MetadataObjectClass = Upper("AccumulationRegister")
		Or MetadataObjectClass = Upper("AccountingRegister")
		Or MetadataObjectClass = Upper("CalculationRegister") Then
		Return Type(MetadataObjectClass + "RecordKey." + MetadataObjectName);
	Else
		// No metadata object key.
		Return Type("Undefined");
	EndIf;
	
EndFunction 

Function IdenticalMetadataObjectKeys(Properties, Object)
	
	Return Properties.MetadataObjectKey = Object.MetadataObjectKey.Get();
	
EndFunction

// Parameters:
//  IDProperties - ValueTableRow:
//   * ExtensionID - String
//   * ExtensionName - String
//   * MetadataObjectKey - ValueStorage
//   * FullName - String
//   * FullCollectionName - String
//   * DeletionMark - Boolean
//   * Presentation - String
//   * Ref - CatalogRef.MetadataObjectIDs
//   * ExtensionHashsum - String
// 
// Returns:
//   Structure:
//     * NotRespond            - Boolean
//     * MetadataObjectKey      - Arbitrary
//     * MetadataObject           - MetadataObject
//     * RemoteMetadataObject - MetadataObject
//     * ViewOfTheRemote    - String
//
Function MetadataObjectKeyMatchesFullName(IDProperties)
	
	CheckResult = New Structure;
	CheckResult.Insert("NotRespond", True);
	CheckResult.Insert("MetadataObjectKey", Undefined);
	CheckResult.Insert("MetadataObject", Undefined);
	CheckResult.Insert("RemoteMetadataObject", Undefined);
	CheckResult.Insert("ViewOfTheRemote", "");
	
	MetadataObjectKey = IDProperties.MetadataObjectKey.Get();
	ExtensionsObjects = IsExtensionsObject(IDProperties.Ref);
	
	If MetadataObjectKey <> Undefined
	   And MetadataObjectKey <> Type("Undefined") Then
		// Key is specified; searching for metadata object by the key.
		CheckResult.MetadataObjectKey = MetadataObjectKey;
		MetadataObject = MetadataObjectByKey(MetadataObjectKey,
			IDProperties.ExtensionName,
			IDProperties.ExtensionID,
			IDProperties.ExtensionHashsum);
		If MetadataObject <> Undefined Then
			CheckResult.NotRespond = MetadataObject.FullName() <> IDProperties.FullName;
		EndIf;
	Else
		// Key is not specified; searching for metadata object by the full name.
		MetadataObject = MetadataFindByFullName(IDProperties.FullName);
		If MetadataObject = Undefined Then
			// A collection might have been specified.
			
			String = StandardSubsystemsCached.MetadataObjectCollectionProperties(ExtensionsObjects).Find(
				IDProperties.Ref.UUID(), "Id");
			
			If String <> Undefined Then
				MetadataObject = Metadata[String.Name];
				CheckResult.NotRespond = String.Name <> IDProperties.FullCollectionName;
			EndIf;
		Else
			CheckResult.NotRespond = False;
		EndIf;
	EndIf;
	
	CheckResult.MetadataObject = MetadataObject;
	
	If MetadataObject = Undefined
	   And IDProperties.DeletionMark
	   And StrStartsWith(IDProperties.FullCollectionName, "? ") Then
		
		CheckResult.RemoteMetadataObject = Common.MetadataObjectByFullName(
			FullNameOfDeletedItem(IDProperties.FullCollectionName));
	EndIf;
	If StrStartsWith(String(IDProperties.Presentation), "? ") Then
		CheckResult.ViewOfTheRemote =
			Mid(String(IDProperties.Presentation), 3);
	EndIf;
	
	Return CheckResult;
	
EndFunction

Function FullNameOfDeletedItem(FullName)
	
	FullNameOfDeletedItem = Mid(FullName, 3);
	ParenthesisPosition = StrFind(FullNameOfDeletedItem, "(");
	If ParenthesisPosition > 0 Then
		FullNameOfDeletedItem = Mid(FullNameOfDeletedItem, 1, ParenthesisPosition - 1);
	EndIf;
	
	Return TrimAll(FullNameOfDeletedItem);
	
EndFunction

Function CannotChangeFullName(Object)
	
	ExtensionsObjects = IsExtensionsObject(Object);
	If IsCollection(Object.Ref, ExtensionsObjects) Then
		Return True;
	EndIf;
	
	PointPosition = StrFind(Object.FullName, ".");
	BaseTypeName = Left(Object.FullName, PointPosition -1);
	
	CollectionsProperties = StandardSubsystemsCached.MetadataObjectCollectionProperties(ExtensionsObjects);
	CollectionProperties = CollectionsProperties.Find(BaseTypeName, "SingularName");
	
	If CollectionProperties <> Undefined
	   And Not CollectionProperties.NoMetadataObjectKey Then
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function MetadataObjectByKey(MetadataObjectKey, ExtensionName, ExtensionID, ExtensionHashsum)
	
	MetadataObject = Undefined;
	MetadataObjectKeyType = TypeOf(MetadataObjectKey);
	
	If MetadataObjectKeyType = Type("Type") Then
		MetadataObject = Metadata.FindByType(MetadataObjectKey);
	ElsIf MetadataObjectKeyType = Type("String") Then
		MetadataObject = StandardSubsystemsCached.RolesByKeysMetadataObjects().Get(MetadataObjectKey);
	EndIf;
	
	If MetadataObject = Undefined Then
		Return Undefined;
	EndIf;
	
	ObjectExtension = MetadataObject.ConfigurationExtension();
	If ObjectExtension = Undefined Then
		Return ?(ValueIsFilled(ExtensionName), Undefined, MetadataObject);
	EndIf;
	
	If Lower(ObjectExtension.UUID) = Lower(ExtensionID)
	 Or Lower(ObjectExtension.UUID) = Lower(Mid(ExtensionID, 3))
	 Or Lower(ObjectExtension.Name) = Lower(ExtensionName)
	 Or Lower(ObjectExtension.Name) = Lower(Mid(ExtensionName, 3)) Then
		
		Return MetadataObject;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Intended to be called from StandardSubsystemsCached.RolesByMetadataObjectsKeys.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String - Key of the "Role" metadata object.
//   * Value - MetadataObject - Role.
//
Function RolesByKeysMetadataObjects() Export
	
	RolesByKeys = New Map;
	For Each Role In Metadata.Roles Do
		RolesByKeys.Insert(KeyRole(Role), Role);
	EndDo;
	
	Return RolesByKeys;
	
EndFunction

Function IsRoleKey(MetadataObjectKey)
	Return TypeOf(MetadataObjectKey) = Type("String")
		And StringFunctionsClientServer.IsUUID(MetadataObjectKey);
EndFunction

Function KeyRole(MetadataObjectRole, RaiseException1 = True)
	
	IBUser = InfoBaseUsers.CreateUser();
	IBUser.Roles.Add(MetadataObjectRole);
	
	String = Lower(StrReplace(ValueToStringInternal(IBUser.Roles), Chars.LF, ""));
	SearchString = "{""#"",d6d05c81-8b72-4eef-96d3-f795c1424c29,{1,";
	Position = StrFind(String, SearchString);
	If Position = 1 Then
		Id = Mid(String, StrLen(SearchString) + 1, 36);
		If StringFunctionsClientServer.IsUUID(Id) Then
			Return Id;
		EndIf;
	EndIf;
	
	If Not RaiseException1 Then
		Return Undefined;
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể nhận khóa vai trò %1';
			|ru = 'Не удалось получить ключ роли %1';
			|en = 'Cannot receive a key of role %1'; fa = 'Cannot receive a key of role %1';
			|it = 'Non è stato possibile ricevere la chiave del ruolo %1';
			|pl = 'Nie udało się otrzymać klucza %1';
			|tr = '%1rol anahtarı alınamadı'"), MetadataObjectRole.Name);
	
	Raise ErrorText;
	
EndFunction

// Parameters:
//  ExtensionsObjects - Boolean
//  CollectionsProperties - See MetadataObjectCollectionProperties
//  ExtensionKeyIds - Map
//
// Returns:
//  ValueTable:
//   * Description         - String
//   * FullName            - String
//   * FullParentName    - String
//   * CollectionOrder     - Number
//   * Parent             - CatalogRef.MetadataObjectIDs
//                          - CatalogRef.ExtensionObjectIDs
//   * Name                  - String
//   * PredefinedDataName - String
//   * Synonym              - String
//   * FullSynonym        - String
//   * NoData            - Boolean
//   * NoMetadataObjectKey - Boolean
//   * ExtensionName        - String
//   * ExtensionID - String
//   * ExtensionHashsum   - String
//   * EmptyRefValue - AnyRef
//   * MetadataObject     - MetadataObject
//
Function MetadataObjectProperties1(ExtensionsObjects, CollectionsProperties = Undefined, ExtensionKeyIds = Undefined)
	
	ParentTypesArray = New Array;
	ParentTypesArray.Add(TypeOf(EmptyCatalogRef(ExtensionsObjects)));
	
	MetadataObjectProperties1 = New ValueTable;
	MetadataObjectProperties1.Columns.Add("Description",              New TypeDescription("String",, New StringQualifiers(150)));
	MetadataObjectProperties1.Columns.Add("FullName",                 New TypeDescription("String",, New StringQualifiers(510)));
	MetadataObjectProperties1.Columns.Add("FullParentName",         New TypeDescription("String",, New StringQualifiers(510)));
	MetadataObjectProperties1.Columns.Add("CollectionOrder",          New TypeDescription("Number"));
	MetadataObjectProperties1.Columns.Add("Parent",                  New TypeDescription(ParentTypesArray));
	MetadataObjectProperties1.Columns.Add("Name",                       New TypeDescription("String",, New StringQualifiers(150)));
	MetadataObjectProperties1.Columns.Add("PredefinedDataName", New TypeDescription("String",, New StringQualifiers(255)));
	MetadataObjectProperties1.Columns.Add("Synonym",                   New TypeDescription("String",, New StringQualifiers(255)));
	MetadataObjectProperties1.Columns.Add("FullSynonym",             New TypeDescription("String",, New StringQualifiers(510)));
	MetadataObjectProperties1.Columns.Add("NoData",                 New TypeDescription("Boolean"));
	MetadataObjectProperties1.Columns.Add("NoMetadataObjectKey", New TypeDescription("Boolean"));
	MetadataObjectProperties1.Columns.Add("ExtensionName",             New TypeDescription("String",, New StringQualifiers(128)));
	MetadataObjectProperties1.Columns.Add("ExtensionID",   New TypeDescription("String",, New StringQualifiers(38)));
	MetadataObjectProperties1.Columns.Add("ExtensionHashsum",        New TypeDescription("String",, New StringQualifiers(30)));
	MetadataObjectProperties1.Columns.Add("EmptyRefValue");
	MetadataObjectProperties1.Columns.Add("MetadataObject");
	
	If CollectionsProperties = Undefined Then
		CollectionsProperties = StandardSubsystemsCached.MetadataObjectCollectionProperties(ExtensionsObjects);
	EndIf;
	
	If ExtensionsObjects And ExtensionKeyIds = Undefined Then
		ExtensionKeyIds = ExtensionKeyIds();
	EndIf;
	
	PredefinedDataNames = ?(ExtensionsObjects,
		Metadata.Catalogs.ExtensionObjectIDs,
		Metadata.Catalogs.MetadataObjectIDs).GetPredefinedNames();
	
	PredefinedItemsNames = New Map;
	For Each PredefinedItemName In PredefinedDataNames Do
		PredefinedItemsNames.Insert(PredefinedItemName, False);
	EndDo;
	
	If Not ExtensionsObjects Or ValueIsFilled(SessionParameters.AttachedExtensions) Then
		For Each CollectionProperties In CollectionsProperties Do
			AddMetadataObjectProperties(Metadata[CollectionProperties.Name], CollectionProperties,
				MetadataObjectProperties1, ExtensionKeyIds, PredefinedItemsNames);
		EndDo;
		MetadataObjectProperties1.Indexes.Add("FullName");
	EndIf;
	
	Return MetadataObjectProperties1;
	
EndFunction

Procedure AddMetadataObjectProperties(Val MetadataObjectCollection,
                                             Val CollectionProperties,
                                             Val MetadataObjectProperties1,
                                             Val ExtensionKeyIds,
                                             Val PredefinedItemsNames,
                                             Val FullParentName = "",
                                             Val ParentFullSynonym = "")
	
	
	ExtensionsObjects = ExtensionKeyIds <> Undefined;
	
	For Each MetadataObject In MetadataObjectCollection Do
		
		FullName = MetadataObject.FullName();
		Extension = MetadataObject.ConfigurationExtension();
		ExtensionName           = ?(Extension = Undefined, "", Extension.Name);
		ExtensionID = ?(Extension = Undefined, "", Lower(Extension.UUID));
		ExtensionHashsum      = ?(Extension = Undefined, "", Base64String(Extension.HashSum));
		If ExtensionsObjects And Extension <> Undefined Then
			ExtensionKey = Lower(ExtensionName) + " " + ExtensionHashsum;
			NewExtensionId = ExtensionKeyIds.Get(ExtensionKey);
			If NewExtensionId <> Undefined
			   And NewExtensionId <> ExtensionID Then
				ExtensionID = NewExtensionId;
			EndIf;
		EndIf;
		
		Synonym = ?(ValueIsFilled(MetadataObject.Synonym),
			MetadataObject.Synonym, MetadataObject.Name);
		
		FullSynonym = ParentFullSynonym
			+ CollectionProperties.SingularSynonym + ". " + Synonym;
		
		If ValueIsFilled(ExtensionName) = ExtensionsObjects Then
			
			If Not CollectionProperties.NoData
			   And Not StandardSubsystemsServer.IsRegisterTable(CollectionProperties.SingularName)
			   And StrFind(CollectionProperties.SingularName, "Constant") = 0 Then
				
				RefTypeName1 = CollectionProperties.SingularName + "Ref." + MetadataObject.Name;
				TypeDetails = New TypeDescription(RefTypeName1);
				EmptyRefValue = TypeDetails.AdjustValue(Undefined);
			Else
				EmptyRefValue = Undefined;
			EndIf;
			
			NewRow = MetadataObjectProperties1.Add();
			FillPropertyValues(NewRow, CollectionProperties);
			NewRow.Parent          = CollectionID(CollectionProperties.Id, ExtensionsObjects);
			NewRow.Description      = MetadataObjectPresentation(MetadataObject, CollectionProperties);
			NewRow.FullName         = FullName;
			NewRow.FullParentName = FullParentName;
			NewRow.Name               = MetadataObject.Name;
			NewRow.Synonym           = Synonym;
			NewRow.FullSynonym     = FullSynonym;
			NewRow.EmptyRefValue    = EmptyRefValue;
			NewRow.MetadataObject        = MetadataObject;
			NewRow.ExtensionName           = ExtensionName;
			NewRow.ExtensionID = ExtensionID;
			NewRow.ExtensionHashsum      = ExtensionHashsum;
			
			PredefinedItemName = StrReplace(FullName, ".", "");
			If PredefinedItemsNames.Get(PredefinedItemName) <> Undefined Then
				NewRow.PredefinedDataName = PredefinedItemName;
				PredefinedItemsNames.Insert(PredefinedItemName, True);
			EndIf;
		EndIf;
		
		If CollectionProperties.Name = "Subsystems"
		   And (ExtensionsObjects Or Not ValueIsFilled(ExtensionName)) Then
			
			AddMetadataObjectProperties(
				MetadataObject.Subsystems,
				CollectionProperties,
				MetadataObjectProperties1,
				ExtensionKeyIds,
				PredefinedItemsNames,
				FullName,
				FullSynonym + ". ");
		EndIf;
	EndDo;
	
EndProcedure

Function MetadataObjectPresentation(Val MetadataObject, Val CollectionProperties)
	
	Postfix = "(" + CollectionProperties.SingularSynonym + ")";
	
	Synonym = ?(ValueIsFilled(MetadataObject.Synonym), MetadataObject.Synonym, MetadataObject.Name);
	
	SynonymMaxLength = 150 - StrLen(Postfix);
	If StrLen(Synonym) > SynonymMaxLength + 1 Then
		Return Left(Synonym, SynonymMaxLength - 2) + "..." + Postfix;
	EndIf;
	
	Return Synonym + " (" + CollectionProperties.SingularSynonym + ")";
	
EndFunction

Function InsertQuestionMark(Val String)
	
	If Not StrStartsWith(String, "?") Then
		If Not StrStartsWith(String, " ") Then
			String = "? " + String;
		Else
			String = "?" + String;
		EndIf;
	EndIf;
	
	Return String;
	
EndFunction

Function UniqueFullName(Properties)
	
	FullName = InsertQuestionMark(Properties.FullName);
	
	If StrFind(FullName, "(") = 0 Then
		FullName = FullName + " (" + String(Properties.Ref.UUID())+ ")";
	EndIf;
	
	Return FullName;
	
EndFunction

Function MetadataFindByFullName(FullName)
	
	If StrStartsWith(FullName, "?") Then
		Return Undefined;
	EndIf;
	
	Return Common.MetadataObjectByFullName(FullName);
	
EndFunction

Function FullNameUsed(Object, ExtensionObjects)
	
	Query = New Query;
	Query.SetParameter("FullName", Object.FullName);
	Query.SetParameter("Ref",    Object.Ref);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|WHERE
	|	MetadataObjectIDs.Ref <> &Ref
	|	AND MetadataObjectIDs.FullName = &FullName";
	ClarifyCatalogNameInQueryText(Query.Text, ExtensionObjects);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function IsCollection(Ref, ExtensionsObjects = False)
	
	CollectionsProperties = StandardSubsystemsCached.MetadataObjectCollectionProperties(ExtensionsObjects);
	Return CollectionsProperties.Find(Ref.UUID(), "Id") <> Undefined;
	
EndFunction

Procedure PrepareNewSubsystemsListInMasterNode(Upload0)
	
	FoundDetails = Upload0.Find(Metadata.Subsystems.StandardSubsystems, "MetadataObject");
	If FoundDetails = Undefined Then
		Return;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("IsNew", True);
	FoundADescriptionOf = Upload0.FindRows(Filter);
	
	InheritingSubsystems = New Array;
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
		ModuleFilesOperationsInternal.OnDefineSubsystemsInheritance(Upload0, InheritingSubsystems);
	EndIf;
	
	SearchString = Metadata.Subsystems.StandardSubsystems.FullName() + ".";
	NewSubsystems = New Array;
	AllNewSubsystems = New Array;
	For Each LongDesc In FoundADescriptionOf Do
		If InheritingSubsystems.Find(LongDesc) <> Undefined Then
			Continue;
		EndIf;
		If StrStartsWith(LongDesc.FullName, SearchString) Then
			NewSubsystems.Add(LongDesc.FullName);
		EndIf;
		
		If StrStartsWith(LongDesc.FullName, "Subsystem.") Then
			AllNewSubsystems.Add(LongDesc.FullName);
		EndIf;
	EndDo;
	
	UpdateNewSubsystemsList(NewSubsystems, AllNewSubsystems);
	
EndProcedure

Procedure PrepareNewSubsystemsListInSubordinateNode(ObjectsToWrite)
	
	NewSubsystems = New Array;
	AllNewSubsystems = New Array;
	NameBeginning = "Subsystem.StandardSubsystems.";
	KeyAllSubsystems = "Subsystem.";
	
	For Each Object In ObjectsToWrite Do
		If Not Object.IsNew()
			Or Object.AdditionalProperties.Property("IsDuplicateReplacement") Then
			Continue;
		EndIf;
		
		If Upper(Left(Object.FullName, StrLen(NameBeginning))) = Upper(NameBeginning) Then
			NewSubsystems.Add(Object.FullName);
		EndIf;
		
		If Upper(Left(Object.FullName, StrLen(KeyAllSubsystems))) = Upper(KeyAllSubsystems) Then
			AllNewSubsystems.Add(Object.FullName);
		EndIf;
	EndDo;
	
	UpdateNewSubsystemsList(NewSubsystems, AllNewSubsystems);
	
EndProcedure

Procedure UpdateNewSubsystemsList(NewSubsystems, AllNewSubsystems)
	
	InformationRecords = InfobaseUpdateInternal.InfobaseUpdateInfo();
	HasChanges = False;
	
	For Each SubsystemName In NewSubsystems Do
		If InformationRecords.NewSubsystems.Find(SubsystemName) = Undefined Then
			InformationRecords.NewSubsystems.Add(SubsystemName);
			HasChanges = True;
		EndIf;
	EndDo;
	
	// Removing the subsystem from the list of subsystems deleted from metadata.
	IndexOf = InformationRecords.NewSubsystems.Count() - 1;
	While IndexOf >= 0 Do
		SubsystemName = InformationRecords.NewSubsystems.Get(IndexOf);
		If Common.MetadataObjectByFullName(SubsystemName) = Undefined Then
			InformationRecords.NewSubsystems.Delete(IndexOf);
			HasChanges = True;
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	
	If AllNewSubsystems <> Undefined Then
		
		For Each SubsystemName In AllNewSubsystems Do
			If InformationRecords.AllNewSubsystems.Find(SubsystemName) = Undefined Then
				InformationRecords.AllNewSubsystems.Add(SubsystemName);
				HasChanges = True;
			EndIf;
		EndDo
		
	EndIf;
	
	If Not HasChanges Then
		Return;
	EndIf;
	
	InfobaseUpdateInternal.WriteInfobaseUpdateInfo(InformationRecords);
	
EndProcedure

Function CollectionID(UUID, ExtensionsObjects)
	
	If ExtensionsObjects Then
		Return Catalogs.ExtensionObjectIDs.GetRef(UUID);
	Else
		Return GetRef(UUID);
	EndIf;
	
EndFunction

Function IsExtensionsObject(ObjectOrRef)
	
	Return TypeOf(ObjectOrRef) = Type("CatalogObject.ExtensionObjectIDs")
		Or TypeOf(ObjectOrRef) = Type("CatalogRef.ExtensionObjectIDs");
	
EndFunction

Function CreateCatalogItem(ExtensionsObjects)
	
	If ExtensionsObjects Then
		Return Catalogs.ExtensionObjectIDs.CreateItem();
	Else
		Return CreateItem();
	EndIf;
	
EndFunction

Function EmptyCatalogRef(ExtensionsObjects)
	
	If ExtensionsObjects Then
		Return Catalogs.ExtensionObjectIDs.EmptyRef();
	Else
		Return EmptyRef();
	EndIf;
	
EndFunction

Function NewCatalogRef(ExtensionsObjects)
	
	If ExtensionsObjects Then
		Return Catalogs.ExtensionObjectIDs.GetRef();
	Else
		Return GetRef();
	EndIf;
	
EndFunction

Function CatalogName(ExtensionsObjects)
	
	If ExtensionsObjects Then
		Return "Catalog.ExtensionObjectIDs";
	Else
		Return "Catalog.MetadataObjectIDs";
	EndIf;
	
EndFunction

Function CatalogDescription(ExtensionsObjects)
	
	If ExtensionsObjects Then
		CatalogDescription = NStr("vi = 'Tên định danh đối tượng phần mở rộng';
									|ru = 'Идентификаторы объектов расширений';
									|en = 'Extension object IDs'; fa = 'شناسه‌های شیء افزونه';
									|it = 'Identificatori degli oggetti delle estensioni';
									|pl = 'Identyfikatory obiektów rozszerzeń';
									|tr = 'Meta veri nesne tanımlayıcısı'");
	Else
		CatalogDescription = NStr("vi = 'Tên định danh đối tượng metadata';
									|ru = 'Идентификаторы объектов метаданных';
									|en = 'Metadata object IDs'; fa = 'شناسه‌های شیء فراداده';
									|it = 'Identificatori degli oggetti dei metadati';
									|pl = 'Identyfikatory obiektów metadanych';
									|tr = 'Meta veri nesne tanımlayıcısı'");
	EndIf;
	
	Return CatalogDescription;
	
EndFunction

Procedure ClarifyCatalogNameInQueryText(QueryText, ExtensionsObjects)
	
	If ExtensionsObjects Then
		QueryText = StrReplace(QueryText, "Catalog.MetadataObjectIDs",
			CatalogName(ExtensionsObjects));
	EndIf;
	
EndProcedure

Procedure RaiseByError(ExtensionsObjects, ErrorText)
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lỗi khi làm việc với danh mục ""%1"".';
			|ru = 'Ошибка при работе со справочником ""%1"".';
			|en = '""%1"" catalog error.'; fa = '""%1"" catalog error.';
			|it = 'Errore durante il lavoro con l''elenco ""%1"".';
			|pl = 'Błąd podczas pracy z katalogiem ""%1"".';
			|tr = '""%1"" katalog ile çalışırken bir hata oluştu.'"),
		CatalogDescription(ExtensionsObjects));
	
	ErrorText = ErrorTitle + Chars.LF + Chars.LF + ErrorText;
	Raise ErrorText;
	
EndProcedure

Function IsSubsystem(MetadataObject, SubsystemsCollection = Undefined)
	
	If SubsystemsCollection = Undefined Then
		SubsystemsCollection = Metadata.Subsystems;
	EndIf;
	
	If SubsystemsCollection.Contains(MetadataObject) Then
		Return True;
	EndIf;
	
	For Each Subsystem In SubsystemsCollection Do
		If IsSubsystem(MetadataObject, Subsystem.Subsystems) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// For the AddRenaming procedure.
Function CollectionName(FullName)
	
	PointPosition = StrFind(FullName, ".");
	
	If PointPosition > 0 Then
		Return Left(FullName, PointPosition - 1);
	EndIf;
	
	Return "";
	
EndFunction

Function PreviousValuesNewStructure()
	
	Return New Structure("DeletionMark, Name, Synonym, MetadataObjectKey");
	
EndFunction

// For the RunDataUpdate and BeforeWriteObject procedures.
Procedure CheckObjectBeforeWrite(Object, AutoUpdate = False)
	
	ExtensionsObjects = IsExtensionsObject(Object);
	
	If Not AutoUpdate Then
		
		If Object.IsNew() Then
			
			RaiseByError(ExtensionsObjects,
				NStr("vi = 'Chỉ có thể tự động tạo mới tên định danh đối tượng mới
				           |khi cập nhật dữ liệu danh mục.';
				           |ru = 'Создание нового идентификатора объекта
				           |возможно только автоматически при обновлении данных справочника.';
				           |en = 'A new object ID can be created only automatically
				           |when updating catalog data.'; fa = 'A new object ID can be created only automatically
				           |when updating catalog data.';
				           |it = 'La creazione di un nuovo identificatore degli oggetti
				           |è possibile solo in modo automatico durante l''aggiornamento dei valori dell''elenco.';
				           |pl = 'Tworzenie nowego identyfikatora obiektu
				           |jest możliwe tylko automatycznie podczas aktualizacji danych katalogu.';
				           |tr = 'Yeni bir meta veri nesnesi 
				           |kimliğinin oluşturulması, yalnızca dizin verisi güncellenirken otomatik olarak mümkündür.'"));
				
		ElsIf CannotChangeFullName(Object) Then
			
			RaiseByError(ExtensionsObjects, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi thay đổi tên định danh của đối tượng
				           |có chỉ ra tên đầy đủ ""%1"" mà chỉ có thể
				           |thiết lập tự động khi cập nhật dữ liệu danh mục.';
				           |ru = 'При изменении идентификатора объекта указано
				           |полное имя ""%1"", которое может быть
				           |установлено только автоматически при обновлении данных справочника.';
				           |en = 'Cannot set the full name ""%1""
				           |specified when changing the object ID.
				           |It can be set only automatically when updating catalog data.'; fa = 'Cannot set the full name ""%1""
				           |specified when changing the object ID.
				           |It can be set only automatically when updating catalog data.';
				           |it = 'Durante la modifica dell''identificatore dell''oggetto è specificato
				           |un nome completo ""%1"" che può essere impostato
				           |solamente in modo automatico durante l''aggiornamento dei valori dell''elenco.';
				           |pl = 'Podczas zmiany identyfikatora obiektu wskazano
				           |pełną nazwę ""%1"", która może być
				           |ustawiona tylko automatycznie podczas aktualizacji danych katalogu.';
				           |tr = 'Nesne kimliği%1 değiştirildiğinde, yalnızca 
				           |dizin verisi güncellendiğinde otomatik olarak ayarlanabilen ""
				           |"" tam adı belirtilir.'"),
				Object.FullName));
		Else
			If FullNameUsed(Object, False) Then
				CatalogDescription = CatalogDescription(False);
				
			ElsIf ExtensionsObjects And FullNameUsed(Object, True) Then
				CatalogDescription = CatalogDescription(True);
			Else
				CatalogDescription = "";
			EndIf;
			If ValueIsFilled(CatalogDescription) Then
				RaiseByError(ExtensionsObjects, StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi thay đổi tên định danh đối tượng có chỉ ra
					           |tên đầy đủ ""%1""
					           |mà cs thể sử dụng trong danh mục ""%2"".';
					           |ru = 'При изменении идентификатора объекта указано
					           |полное имя ""%1"",
					           |которое уже используется в справочнике ""%2"".';
					           |en = 'Cannot set the full name ""%1""
					           |specified when changing the object ID.
					           |It is already in use in the ""%2"" catalog.'; fa = 'Cannot set the full name ""%1""
					           |specified when changing the object ID.
					           |It is already in use in the ""%2"" catalog.';
					           |it = 'Durante la modifica dell''identificatore dell''oggetto è specificato
					           |un nome completo ""%1"", 
					           | che è già in uso nell''elenco ""%2"".';
					           |pl = 'Podczas zmiany identyfikatora obiektu wskazano
					           |pełną nazwę ""%1"",
					           |która jest już używana w katalogu ""%2"".';
					           |tr = 'Nesne 
					           |kimliği değiştirildiğinde, dizinde zaten 
					           |kullanılan ""%1"" tam adı belirtilir.%2'"),
					Object.FullName, CatalogDescription));
			EndIf;
		EndIf;
		
		UpdateIDProperties(Object);
	EndIf;
	
	If Not ExtensionsObjects And Common.IsSubordinateDIBNode() Then
		
		If Object.IsNew()
		   And Not IsCollection(Object.GetNewObjectRef(), IsExtensionsObject(Object)) Then
			
			RaiseByError(ExtensionsObjects,
				NStr("vi = 'Có thể thêm phần tử mới 
				           | trong nút chính của cơ sở thông tin phân tán.';
				           |ru = 'Добавление новых элементов может быть выполнено
				           |только в главном узле распределенной информационной базы.';
				           |en = 'Adding items is only allowed
				           |in the main node of the distributed infobase.'; fa = 'Adding items is only allowed
				           |in the main node of the distributed infobase.';
				           |it = 'L''aggiunta di nuovi elementi è possibile
				           |solamente nel nodo principale del database informatico suddiviso.';
				           |pl = 'Dodawanie nowych elementów może być wykonane
				           |tylko w węźle głównym rozproszonej bazy informacyjnej.';
				           |tr = 'Yeni öğeler, 
				           |sadece dağıtılmış Infobase''in ana ünitesinde eklenebilir.'"));
		EndIf;
		
		If Not Object.DeletionMark
		   And Not IsCollection(Object.Ref, IsExtensionsObject(Object)) Then
			
			If Upper(Object.FullName) <> Upper(Common.ObjectAttributeValue(Object.Ref, "FullName")) Then
				RaiseByError(ExtensionsObjects,
					NStr("vi = 'Chỉ có thể thay đổi mục tin mục tin ""Tên đầy đủ""
					           |trong nút chính của cơ sở thông tin phân tán.';
					           |ru = 'Изменение реквизита ""Полное имя"" может быть выполнено
					           |только в главном узле распределенной информационной базы.';
					           |en = 'The ""Full name"" attribute can be changed
					           |only in the main node of the distributed infobase.'; fa = 'The ""Full name"" attribute can be changed
					           |only in the main node of the distributed infobase.';
					           |it = 'La modifica del requisito ""Nome completo"" può essere effettuata
					           |solamente nel nodo principale del database informatico suddiviso.';
					           |pl = 'Zmiana atrybutu ""Pełna nazwa"" może być wykonane
					           |tylko w węźle głównym rozproszonej bazy informacyjnej.';
					           |tr = '""Tam
					           | ad"" özniteliği sadece dağıtılmış Infobase''in ana ünitesinde değiştirilebilir.'"));
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// This method is required by CheckForUsage and DataUpdated procedures.
Function ExtensionObjectsIDsUnvailableInSharedModeErrorDescription()
	
	Return
		NStr("vi = 'Không thể sử dụng danh mục ""Tên định danh đối tượng phần mở rộng""
		           |trong chế độ không chia tách.';
		           |ru = 'Справочник ""Идентификаторы объектов расширений""
		           |не может использоваться в неразделенном режиме.';
		           |en = 'Cannot use the ""Extension object IDs"" catalog
		           |in shared mode.'; fa = 'Cannot use the ""Extension object IDs"" catalog
		           |in shared mode.';
		           |it = 'L''elenco ""Identificatori degli oggetti delle estensioni"" 
		           |non può essere usato in modalità non condivisa.';
		           |pl = 'Katalog ""Identyfikatory obiektów rozszerzeń""
		           |nie może być używany w trybie niepodzielnym.';
		           |tr = 'Uzantı nesne tanımlayıcıları 
		           |dizini bölünmemiş modda kullanılamaz.'");
	
EndFunction

// This method is required by OnCreateListFormAtServer procedure.
Procedure SetListOrderAndAppearance(Form)
	
	// Order.
	Order = Form.List.SettingsComposer.Settings.Order;
	Order.UserSettingID = "DefaultOrder";
	
	Order.Items.Clear();
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("DeletionMark");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("CollectionOrder");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Parent");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("FutureDeletionMark");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Synonym");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	// Appearance.
	AppearanceItem = Form.List.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	AppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	ColorItem = AppearanceItem.Appearance.Items.Find("TextColor");
	ColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	ColorItem.Use = True;
	
	FilterGroupItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroupItem.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterElement = FilterGroupItem.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField("DeletionMark");
	FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = True;
	FilterElement.Use  = True;
	
	FilterElement = FilterGroupItem.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField("FutureDeletionMark");
	FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = True;
	FilterElement.Use  = True;
	
EndProcedure

// This method is required by UpdateData procedure.
Function ExtensionNames(ExtensionSource, ExtensionKeyIds)
	
	ExtensionNames = New Map;
	Extensions = ConfigurationExtensions.Get(, ExtensionSource); // Array of ConfigurationExtension
	
	For Each Extension In Extensions Do
		ExtensionID = Lower(Extension.UUID);
		ExtensionNames.Insert(Lower(Extension.Name), Extension.Name);
		ExtensionNames.Insert(ExtensionID, Extension.Name);
		ExtensionKey = Lower(Extension.Name) + " " + Base64String(Extension.HashSum);
		NewExtensionId = ExtensionKeyIds.Get(ExtensionKey);
		If NewExtensionId <> Undefined
		   And NewExtensionId <> ExtensionID Then
			ExtensionNames.Insert(Lower(NewExtensionId), Extension.Name);
		EndIf;
	EndDo;
	
	Return ExtensionNames;
	
EndFunction

// Required by procedure "UpdateData".
Procedure AddNamesOfUnconnectedExtensionsInSessionWithoutDelimiters(ExtensionProperties, DatabaseExtensions)
	
	If Not StandardSubsystemsServer.ThisIsSplitSessionModeWithNoDelimiters() Then
		Return;
	EndIf;
	
	AttachedExtensionsNames   = ExtensionProperties.AttachedExtensionsNames;
	UnattachedExtensionsNames = ExtensionProperties.UnattachedExtensionsNames;
	
	For Each Extension In DatabaseExtensions Do
		ExtensionID = Lower(Extension.UUID);
		NameOfSearchExtension = Lower(Extension.Name);
		If AttachedExtensionsNames.Get(ExtensionID) <> Undefined
		 Or AttachedExtensionsNames.Get(NameOfSearchExtension) <> Undefined
		 Or UnattachedExtensionsNames.Get(ExtensionID) <> Undefined
		 Or UnattachedExtensionsNames.Get(NameOfSearchExtension) <> Undefined Then
			Continue;
		EndIf;
		UnattachedExtensionsNames.Insert(NameOfSearchExtension, Extension.Name);
		UnattachedExtensionsNames.Insert(Lower(ExtensionID), Extension.Name);
	EndDo;
	
EndProcedure

// This method is required by MetadataObjectIDByFullName and MetadataObjectIDs functions.
Function MetadataObjectIDsWithRetryAttempt(FullMetadataObjectsNames, RaiseException1, OneItem)
	
	StandardSubsystemsCached.MetadataObjectIDsUsageCheck(True,
		Common.SeparatedDataUsageAvailable());
	
	IDs = MetadataObjectIDsWithoutRetryAttempt(
		FullMetadataObjectsNames, RaiseException1, OneItem, True);
	
	If IDs = Undefined Then
		UpdateIsCompleted = UpdateIDCatalogs();
		
		If Not Common.DataSeparationEnabled()
		 Or Not Common.SeparatedDataUsageAvailable() Then
			
			If Not UpdateIsCompleted.MetadataObjectIDs Then
				UpdateCatalogData();
			EndIf;
		EndIf;
		
		If Common.SeparatedDataUsageAvailable() Then
			If Not UpdateIsCompleted.ExtensionObjectIDs Then
				Catalogs.ExtensionObjectIDs.UpdateCatalogData();
			EndIf;
		EndIf;
		
		IDs = MetadataObjectIDsWithoutRetryAttempt(
			FullMetadataObjectsNames, RaiseException1, OneItem);
	EndIf;
	
	Return IDs;
	
EndFunction

// This method is required by MetadataObjectIDs function.
Function MetadataObjectIDsWithoutRetryAttempt(FullMetadataObjectsNames,
			RaiseException1, OneItem, FirstAttempt = False)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	ExtensionObjectIDsAvailable =
		ValueIsFilled(SessionParameters.AttachedExtensions)
		And Common.SeparatedDataUsageAvailable();
	
	Query = New Query;
	Query.SetParameter("FullNames", FullMetadataObjectsNames);
	Query.Text =
	"SELECT
	|	IDs.Ref AS Ref,
	|	IDs.MetadataObjectKey AS MetadataObjectKey,
	|	IDs.FullName AS FullName,
	|	IDs.Description AS Presentation,
	|	IDs.FullName AS FullCollectionName,
	|	IDs.DeletionMark AS DeletionMark,
	|	"""" AS ExtensionName,
	|	"""" AS ExtensionID,
	|	"""" AS ExtensionHashsum
	|FROM
	|	Catalog.MetadataObjectIDs AS IDs
	|WHERE
	|	IDs.FullName IN(&FullNames)
	|	AND NOT IDs.DeletionMark";
	
	If ExtensionObjectIDsAvailable Then
		Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
		QueryText =
		"SELECT
		|	IDsVersions.Id AS Ref,
		|	IDs.MetadataObjectKey AS MetadataObjectKey,
		|	IDsVersions.FullObjectName AS FullName,
		|	IDs.Description AS Presentation,
		|	IDs.FullName AS FullCollectionName,
		|	IDs.DeletionMark AS DeletionMark,
		|	IDs.ExtensionName AS ExtensionName,
		|	IDs.ExtensionID AS ExtensionID,
		|	IDs.ExtensionHashsum AS ExtensionHashsum
		|FROM
		|	InformationRegister.ExtensionVersionObjectIDs AS IDsVersions
		|		INNER JOIN Catalog.ExtensionObjectIDs AS IDs
		|		ON (IDs.Ref = IDsVersions.Id)
		|			AND (IDsVersions.ExtensionsVersion = &ExtensionsVersion)
		|WHERE
		|	IDsVersions.FullObjectName IN(&FullNames)";
		
		Query.Text = Query.Text + "
		|
		|UNION ALL
		|
		|" + QueryText;
	EndIf;
	
	Upload0 = Query.Execute().Unload();
	Upload0.Indexes.Add("FullName");
	
	Errors = New Array;
	AddApplicationDeveloperParametersErrorClarification = False;
	
	Context = New Structure("DataBaseConfigurationChangedDynamically");
	IDsFromKeys = Undefined;
	
	Result = New Map;
	For Each FullMetadataObjectName In FullMetadataObjectsNames Do
		
		Filter = New Structure("FullName", FullMetadataObjectName);
		FoundRows = Upload0.FindRows(Filter);
		If FoundRows.Count() = 0 Then
			// One of the reasons why the ID is not found by the full name is that the full name is specified with an error.
			MetadataObject = Common.MetadataObjectByFullName(FullMetadataObjectName);
			If MetadataObject = Undefined Then
				If Not RaiseException1 Then
					Continue;
				EndIf;
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không tồn tại đối tượng metadata có tên gọi ""%1"".';
						|ru = 'Объект метаданных с именем ""%1"" не существует.';
						|en = 'The metadata object with the ""%1"" name does not exist.'; fa = 'The metadata object with the ""%1"" name does not exist.';
						|it = 'L''oggetto di metadati con nome ""%1"" è inesistente.';
						|pl = 'Nie istnieje obiektu metadanych o nazwie ""%1"".';
						|tr = '""%1"" adlı metaveri nesnesi mevcut değil.'"),
					FullMetadataObjectName);
				Errors.Add(ErrorDescription);
				Continue;
			EndIf;
			
			If Not Metadata.Roles.Contains(MetadataObject)
			   And Not Metadata.ExchangePlans.Contains(MetadataObject)
			   And Not Metadata.Constants.Contains(MetadataObject)
			   And Not Metadata.Catalogs.Contains(MetadataObject)
			   And Not Metadata.Documents.Contains(MetadataObject)
			   And Not Metadata.DocumentJournals.Contains(MetadataObject)
			   And Not Metadata.Reports.Contains(MetadataObject)
			   And Not Metadata.DataProcessors.Contains(MetadataObject)
			   And Not Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject)
			   And Not Metadata.ChartsOfAccounts.Contains(MetadataObject)
			   And Not Metadata.ChartsOfCalculationTypes.Contains(MetadataObject)
			   And Not Metadata.InformationRegisters.Contains(MetadataObject)
			   And Not Metadata.AccumulationRegisters.Contains(MetadataObject)
			   And Not Metadata.AccountingRegisters.Contains(MetadataObject)
			   And Not Metadata.CalculationRegisters.Contains(MetadataObject)
			   And Not Metadata.BusinessProcesses.Contains(MetadataObject)
			   And Not Metadata.Tasks.Contains(MetadataObject)
			   And Not IsSubsystem(MetadataObject) Then
				
				If Not RaiseException1 Then
					Continue;
				EndIf;
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không hỗ trợ đối tượng metadata:
					           | ""%1"".
					           |
					           |Chỉ cho phép các kiểu đối tượng metadata được liệt kê trong ghi chú kèm theo hàm.';
					           |ru = 'Объект метаданных не поддерживается:
					           |""%1"".
					           |
					           |Допустимы только типы объектов метаданных перечисленные в комментарии к функции.';
					           |en = 'The metadata object is not supported:
					           |""%1"".
					           |
					           |Only the metadata object types listed in the comments to the function are allowed.'; fa = 'The metadata object is not supported:
					           |""%1"".
					           |
					           |Only the metadata object types listed in the comments to the function are allowed.';
					           |it = 'L''oggetto metadati non è supportato:
					           |""%1"".
					           |
					           |Sono ammessi solo i tipi degli oggetti dei metadati elencati nel commento della funzione.';
					           |pl = 'Obiekt metadanych nie jest obsługiwany:
					           |""%1"".
					           |
					           |Są dozwolone tylko typy obiektów metadanych wymienione w komentarzu do funkcji.';
					           |tr = 'Meta veri nesnesi desteklenmiyor: %1""
					           |"". 
					           |
					           |Yalnızca işlev yorumunda listelenen meta veri nesne türleri kabul edilebilir.'"),
					FullMetadataObjectName);
				Errors.Add(ErrorDescription);
				Continue;
			EndIf;
			
			Extension = MetadataObject.ConfigurationExtension();
			If Extension <> Undefined
			   And Not Common.SeparatedDataUsageAvailable() Then
			
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không hỗ trợ tên định danh đối tượng metadata của phần mở rộng ở chế độ không chia tách.
					           |Không thể trả lại tên định danh đối tượng metadata ""%1""
					           |của phần mở rộng ""%2""phiên bản ""%3"".';
					           |ru = 'Идентификаторы объектов метаданных расширений не поддерживаются в неразделенном режиме.
					           |Невозможно вернуть идентификатор объекта метаданных ""%1""
					           |расширения ""%2"" версии ""%3"".';
					           |en = 'Extension metadata object IDs are not supported in shared mode.
					           |Cannot return the ID of metadata object ""%1""
					           |in extension ""%2"" version %3.'; fa = 'Extension metadata object IDs are not supported in shared mode.
					           |Cannot return the ID of metadata object ""%1""
					           |in extension ""%2"" version %3.';
					           |it = 'Gli identificatori degli oggetti dei metadati non sono supportati nel regime non condiviso.
					           |Impossibile ritornare l''identificatore dell''oggetto dei metadati ""%1"" 
					           | con estensione ""%2"" e versione ""%3"".';
					           |pl = 'Identyfikatory obiektów metadanych rozszerzeń nie są obsługiwane w trybie niepodzielonym.
					           |Nie można zwrócić identyfikator obiektu metadanych ""%1""
					           |rozszerzenia ""%2"" wersji ""%3"".';
					           |tr = 'Uzantı meta veri nesne tanımlayıcıları bölünmemiş modda desteklenmez. 
					           |""%2"" Sürümün ""
					           |"" metaveri uzantı nesne tanımlayıcısı ""%1"" geri yüklenemez. %3'"),
					FullMetadataObjectName, Extension.Name, Extension.Version);
				Errors.Add(ErrorDescription);
				Continue;
			EndIf;
			
			If DataBaseConfigurationChangedDynamicallyFromContext(Context) Then
				If IDsFromKeys = Undefined Then
					// @skip-check query-in-loop - Called no more than once
					IDsFromKeys = IDsFromKeys();
				EndIf;
				Id = IDsFromKeys.Get(FullMetadataObjectName);
				If Id = Undefined Then
					StandardSubsystemsServer.RequireRestartDueToApplicationVersionDynamicUpdate();
				EndIf;
				Result.Insert(FullMetadataObjectName, Id);
				Continue;
			EndIf;
			
			ErrorTemplate = ?(Extension <> Undefined,
				NStr("vi = 'Đối tượng metadata ""%1""
				           | không có tên định danh trong biểu ghi thông tin ""Tên định danh đối tượng phiên bản phần mở rộng"".';
				           |ru = 'Для объекта метаданных ""%1""
				           |не существует идентификатор в регистре сведений ""Идентификаторы объектов версий расширений"".';
				           |en = 'For metadata object ""%1"",
				           |no ID is found in the ""Extension version object IDs"" information register.'; fa = 'For metadata object ""%1"",
				           |no ID is found in the ""Extension version object IDs"" information register.';
				           |it = 'Per l''oggetto di metadati ""%1""
				           | non esiste ID nel registro informazioni ""ID degli oggetti delle versioni di estensioni"".';
				           |pl = 'Dla obiektu metadanych ""%1""
				           |nie istnieje identyfikatora w rejestrze danych ""Identyfikatory obiektów wersji rozszerzeń"".';
				           |tr = 'Meta veri nesnesi için ""%1"" uzantı sürüm nesne tanımlayıcıları ""
				           |kayıt bilgileri kimliği mevcut değil.'"),
				NStr("vi = 'Đối tượng metadata ""%1""
				           | không có tên định danh trong danh mục ""Tên định danh đối tượng metadata"".';
				           |ru = 'Для объекта метаданных ""%1""
				           |не существует идентификатор в справочнике ""Идентификаторы объектов метаданных"".';
				           |en = 'For metadata object ""%1""
				           |, no ID is found in the ""Metadata object IDs"" catalog.'; fa = 'For metadata object ""%1""
				           |, no ID is found in the ""Metadata object IDs"" catalog.';
				           |it = 'Non è stato trovato un identificatore per l''oggetto dei metadati ""%1"" 
				           | nella directory ""ID degli oggetti dei metadati"".';
				           |pl = 'Dla obiektu metadanych ""%1""
				           |nie istnieje identyfikatora w katalogu ""Identyfikatory obiektów metadanych"".';
				           |tr = 'Meta veri nesnesi için ""%1""
				           | Meta veri nesne tanımlayıcıları"" dizininde bir tanımlayıcı bulunamadı.'"));
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, FullMetadataObjectName);
			AddApplicationDeveloperParametersErrorClarification = True;
			Errors.Add(ErrorDescription);
			Continue;
			
		ElsIf FoundRows.Count() > 1 Then
			
			ErrorTemplate = ?(ExtensionObjectIDsAvailable,
				NStr("vi = 'Đã tìm thấy nhiều tên định danh đối với đối tượng metadata ""%1""
				           | trong danh mục ""Tên định danh đối tượng metadata"" và
				           | trong biểu ghi thông tin ""Tên định danh đối tượng phiên bản phần mở rộng"".';
				           |ru = 'Для объекта метаданных ""%1""
				           |найдено несколько идентификаторов в справочнике ""Идентификаторы объектов метаданных"" и
				           |регистре сведений ""Идентификаторы объектов версий расширений"".';
				           |en = 'For metadata object ""%1"",
				           |multiple IDs are found in the ""Metadata object IDs"" catalog
				           |and the ""Extension version object IDs"" information register.'; fa = 'For metadata object ""%1"",
				           |multiple IDs are found in the ""Metadata object IDs"" catalog
				           |and the ""Extension version object IDs"" information register.';
				           |it = 'Per l''oggetto dei metadati ""%1"" 
				           |sono stati trovati alcuni identificatori nell''elenco ""Identificatori degli oggetti dei metadati"" e
				           |nel registro delle informazioni ""Identificatori degli oggetti delle versioni delle estensioni"".';
				           |pl = 'Dla obiektu metadanych ""%1""
				           |znaleziono kilka identyfikatorów w katalogu ""Identyfikatory obiektów metadanych"" i
				           |w rejestrze informacji ""Identyfikatory obiektów wersji rozszerzeń"".';
				           |tr = 'Meta veri nesnesi için ""%1""
				           |meta veri nesne tanımlayıcıları""ve ""
				           |uzantı sürüm nesne tanımlayıcıları"" kayıt bilgileri başvurusu birden çok tanımlayıcı bulundu.'"),
				NStr("vi = 'Đã tìm thấy nhiều tên định danh đối với đối tượng metadata ""%1""
				           | trong danh mục ""Tên định danh đối tượng metadata"".';
				           |ru = 'Для объекта метаданных ""%1""
				           |найдено несколько идентификаторов в справочнике ""Идентификаторы объектов метаданных"".';
				           |en = 'For metadata object ""%1"",
				           |multiple IDs are found in the ""Metadata object IDs"" catalog.'; fa = 'For metadata object ""%1"",
				           |multiple IDs are found in the ""Metadata object IDs"" catalog.';
				           |it = 'Per l''oggetto dei metadati ""%1"" 
				           | sono stati trovati alcuni identificatori nell''elenco ""Identificatori degli oggetti dei metadati"".';
				           |pl = 'Dla obiektu metadanych ""%1""
				           |znaleziono kilka identyfikatorów w katalogu ""Identyfikatory obiektów metadanych"".';
				           |tr = 'Meta veri nesnesi için ""%1""
				           | Meta veri nesne tanımlayıcıları"" dizininde birkaç tanımlayıcı bulundu.'"));
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, FullMetadataObjectName);
			AddApplicationDeveloperParametersErrorClarification = True;
			Errors.Add(ErrorDescription);
			Continue;
			
		EndIf;
		
		// Checking whether the metadata object key matches the metadata object full name.
		TableRow = FoundRows[0];
		CheckResult = MetadataObjectKeyMatchesFullName(TableRow);
		If CheckResult.NotRespond Then
			CatalogDescription = CatalogDescription(IsExtensionsObject(TableRow.Ref));
			
			If CheckResult.MetadataObject = Undefined Then
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã tìm thấy tên định danh đối với đối tượng metadata ""%1""
					           | trong danh mục ""%2"",
					           |tương ứng với đối tượng metadata từ xa.';
					           |ru = 'Для объекта метаданных ""%1""
					           |найден идентификатор в справочнике ""%2"",
					           |которому соответствует удаленный объект метаданных.';
					           |en = 'For metadata object ""%1"",
					           |an ID matching a deleted metadata object 
					           |is found in the ""%2"" catalog.'; fa = 'For metadata object ""%1"",
					           |an ID matching a deleted metadata object 
					           |is found in the ""%2"" catalog.';
					           |it = 'Per l''oggetto dei metadati ""%1"" 
					           | è stato trovato un identificatore nell''elenco ""%2"" 
					           | al quale corrisponde un oggetto dei metadati cancellato.';
					           |pl = 'Dla obiektu metadanych ""%1""
					           |znaleziono identyfikator w katalogu ""%2"",
					           |któremu odpowiada usunięty obiekt metadanych.';
					           |tr = 'Meta veri nesnesi için ""%1""
					           | uzak meta veri nesnesine karşılık gelen ""%2"" 
					           |başvurusu kimliği bulundu.'"),
					FullMetadataObjectName, CatalogDescription);
			Else
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã tìm thấy tên định danh đối với đối tượng metadata ""%1""
					           | trong danh mục ""%2"",
					           |tương ứng với đối tượng metadata khác ""%3"".';
					           |ru = 'Для объекта метаданных ""%1""
					           |найден идентификатор в справочнике ""%2"",
					           |который соответствует другому объекту метаданных ""%3"".';
					           |en = 'For metadata object ""%1"",
					           |an ID matching another metadata object ""%3""
					           |is found in the ""%2"" catalog.'; fa = 'For metadata object ""%1"",
					           |an ID matching another metadata object ""%3""
					           |is found in the ""%2"" catalog.';
					           |it = 'Per l''oggetto dei metadati ""%1""
					           | è stato trovato un identificatore nell''elenco ""%2""
					           | al quale corrisponde un altro oggetto dei metadati ""%3"".';
					           |pl = 'Dla obiektu metadanych ""%1""
					           |znaleziono identyfikator w katalogu ""%2"",
					           |który odpowiada innemu obiektowi metadanych ""%3"".';
					           |tr = 'Meta veri nesnesi için ""%1""
					           | başka uzak meta veri nesnesine karşılık gelen ""%2"" 
					           |başvurusu kimliği bulundu.%3'"),
					FullMetadataObjectName, CatalogDescription, CheckResult.MetadataObject);
			EndIf;
			
			AddApplicationDeveloperParametersErrorClarification = True;
			Errors.Add(ErrorDescription);
			Continue;
		EndIf;
		
		Result.Insert(FullMetadataObjectName, TableRow.Ref);
	EndDo;
	
	If FirstAttempt And AddApplicationDeveloperParametersErrorClarification Then
		Return Undefined;
	EndIf;
	
	ErrorsCount = Errors.Count();
	If ErrorsCount > 0 Then
		
		If OneItem Then
			ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi khi thực hiện hàm %1.';
					|ru = 'Ошибка при выполнении функции %1.';
					|en = 'Error executing function ""%1"".'; fa = 'Error executing function ""%1"".';
					|it = 'Errore all''esecuzione della funzione %1.';
					|pl = 'Błąd podczas wykonywania funkcji %1.';
					|tr = '%1işlevin yürütülmesi esnasında hata oluştu.'"),
				"Common.MetadataObjectID");
			
		ElsIf ErrorsCount = 1 Then
			ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi khi thực hiện hàm %1.';
					|ru = 'Ошибка при выполнении функции %1.';
					|en = 'Error executing function ""%1"".'; fa = 'Error executing function ""%1"".';
					|it = 'Errore all''esecuzione della funzione %1.';
					|pl = 'Błąd podczas wykonywania funkcji %1.';
					|tr = '%1işlevin yürütülmesi esnasında hata oluştu.'"),
				"Common.MetadataObjectIDs");
		Else
			ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi khi thực hiện hàm %1.';
					|ru = 'Ошибки при выполнении функции %1.';
					|en = 'Errors when executing function %1.'; fa = 'Errors when executing function %1.';
					|it = 'Errore all''esecuzione della funzione %1.';
					|pl = 'Błędy podczas wykonania funkcji %1.';
					|tr = '%1işlevin yürütülmesi sırasında hatalar oluştu.'"),
				"Common.MetadataObjectIDs");
		EndIf;
		
		Separator = Chars.LF + Chars.LF;
		AllErrorsText = "";
		ErrorNumber = 0;
		For Each ErrorDescription In Errors Do
			ErrorNumber = ErrorNumber + 1;
			AllErrorsText = AllErrorsText + ?(ErrorNumber = 1, "", Separator) + ErrorDescription;
			If ErrorNumber = 3 And ErrorsCount > 5 Then
				
				ErrorDescription = "... " + StringFunctionsClientServer.StringWithNumberForAnyLanguage(
					NStr("vi = ';Và thêm %1 lỗi;;Và thêm %1 lỗi;Và thêm %1 lỗi;Và thêm %1 lỗi';
						|ru = ';И еще %1 ошибка;;И еще %1 ошибки;И еще %1 ошибок;И еще %1 ошибки';
						|en = ';and %1 more error;;;;and %1 more errors'; fa = ';and %1 more error;;;;and %1 more errors';
						|it = ';Anche %1 errore;;Anche %1 errori;Anche %1 di errori;Anche %1 errori';
						|pl = ';I jeszcze %1 błąd;;I jeszcze %1 błędy;I jeszcze %1 błędów;I jeszcze %1 błędy';
						|tr = ';Ve bir tane daha %1 hata;;ve yine %1 hatalar;Ve yine %1 hata;Ve yine %1 hatalar'"),
					(ErrorsCount - ErrorNumber));
				
				AllErrorsText = AllErrorsText + Separator + ErrorDescription;
				Break;
			EndIf;
		EndDo;
		
		AllErrorsText = AllErrorsText + ?(AddApplicationDeveloperParametersErrorClarification,
			StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper(), "");
		
		ErrorText = ErrorTitle + Separator + AllErrorsText;
		Raise ErrorText;
	EndIf;
	
	Return Result;
	
EndFunction

// Intended for functions MetadataObjectIDsWithoutRetryAttempt,
// MetadataObjectsByIDsWithoutRetryAttempt.
//
Function DataBaseConfigurationChangedDynamicallyFromContext(Context)
	
	If Context.DataBaseConfigurationChangedDynamically = Undefined Then
		Context.DataBaseConfigurationChangedDynamically = DataBaseConfigurationChangedDynamically();
	EndIf;
	
	Return Context.DataBaseConfigurationChangedDynamically;
	
EndFunction

// This method is required by MetadataObjectIDsWithoutRetryAttempt function.
Function IDsFromKeys()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	IDs.Ref AS Ref,
	|	IDs.MetadataObjectKey AS KeyStorage
	|FROM
	|	Catalog.MetadataObjectIDs AS IDs";
	
	Selection = Query.Execute().Select();
	
	IDsFromKeys = New Map;
	
	While Selection.Next() Do
		If TypeOf(Selection.KeyStorage) <> Type("ValueStorage") Then
			Continue;
		EndIf;
		MetadataObjectKey = Selection.KeyStorage.Get();
		
		If MetadataObjectKey = Undefined
		 Or MetadataObjectKey = Type("Undefined") Then
			Continue;
		EndIf;
		
		MetadataObject = MetadataObjectByKey(MetadataObjectKey, "", "", "");
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		
		FullName = MetadataObject.FullName();
		If IDsFromKeys.Get(FullName) <> Undefined Then
			StandardSubsystemsServer.RequireRestartDueToApplicationVersionDynamicUpdate();
		EndIf;
		
		IDsFromKeys.Insert(FullName, Selection.Ref);
	EndDo;
	
	Return IDsFromKeys;
	
EndFunction

// Intended for the functions MetadataObjectIDsWithRetryAttempt,
// MetadataObjectsByIDsWithRetryAttempt.
//
// Returns:
//  FixedStructure:
//   * MetadataObjectIDs - Boolean
//   * ExtensionObjectIDs - Boolean
//   * UpdateInProgress - Boolean
//
Function UpdateIDCatalogs()
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Result = SessionParameters.UpdateIDCatalogs;
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return Result;
	
EndFunction

Procedure InstallIdUpdateIsInProgress(UpdateInProgress)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	UpdatingCatalogs = New Structure(SessionParameters.UpdateIDCatalogs);
	
	UpdatingCatalogs.UpdateInProgress = UpdateInProgress;
	
	SessionParameters.UpdateIDCatalogs = New FixedStructure(UpdatingCatalogs);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// This method is required by MetadataObjectByID and MetadataObjectsByIDs functions.
Function MetadataObjectsByIDsWithRetryAttempt(IDs, RaiseException1)
	
	If IDs.Count() = 0 Then
		Return New Map;
	EndIf;
	
	ConfigurationIDs = New Array;
	ExtensionsIDs   = New Array;
	
	AddedConfigurationIDs = New Map;
	AddedExtensionsIDs   = New Map;
	
	ProcessedItems = New Map;
	
	For Each CurrentID In IDs Do
		If TypeOf(CurrentID) = Type("CatalogRef.MetadataObjectIDs")
		   And ValueIsFilled(CurrentID) Then
			
			If AddedConfigurationIDs[CurrentID] = Undefined Then
				ConfigurationIDs.Add(CurrentID);
				AddedConfigurationIDs.Insert(CurrentID, True);
			EndIf;
		
		ElsIf TypeOf(CurrentID) = Type("CatalogRef.ExtensionObjectIDs")
		   And ValueIsFilled(CurrentID) Then
			
			If AddedExtensionsIDs[CurrentID] = Undefined Then
				ExtensionsIDs.Add(CurrentID);
				AddedExtensionsIDs.Insert(CurrentID, True);
			EndIf;
		ElsIf RaiseException1 Then
			If TypeOf(CurrentID) = Type("CatalogRef.MetadataObjectIDs")
			 Or TypeOf(CurrentID) = Type("CatalogRef.ExtensionObjectIDs") Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Lỗi khi thực hiện hàm %1.
					           |
					           |Sai tên định danh: tham chiếu trống kiểu ""%2"".';
					           |ru = 'Ошибка при выполнении функции %1.
					           |
					           |Неверный идентификатор: пустая ссылка типа ""%2"".';
					           |en = 'Error executing function ""%1"".
					           |
					           |Invalid ID: Empty reference of type ""%2"".'; fa = 'Error executing function ""%1"".
					           |
					           |Invalid ID: Empty reference of type ""%2"".';
					           |it = 'Errore all''esecuzione della funzione %1.
					           |
					           | ID invalido: collegamento vuoto del tipo ""%2"".';
					           |pl = 'Błąd podczas wykonania funkcji %1.
					           |
					           |Błędny identyfikator: pusty odnośnik o typie ""%2"".';
					           |tr = '%1işlevin yürütülmesi sırasında hata oluştu.
					           |
					           |Yanlış kimlik: ""%2"" gibi boş bağlantı.'"),
					"Common.MetadataObjectByID",
					TypeOf(CurrentID));
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Lỗi khi thực hiện hàm %1.
					           |
					           |Sai kiểu tên định danh đối tượng metadata:
					           |""%2"".';
					           |ru = 'Ошибка при выполнении функции %1.
					           |
					           |Неверный тип идентификатора объекта метаданных:
					           |""%2"".';
					           |en = 'Error executing function ""%1"".
					           |
					           |Invalid metadata ID type:
					           |""%2"".'; fa = 'Error executing function ""%1"".
					           |
					           |Invalid metadata ID type:
					           |""%2"".';
					           |it = 'Errore all''esecuzione della funzione %1.
					           |
					           |Tipo di identificatore invalido dell''oggetto di metadati:
					           |""%2"".';
					           |pl = 'Błąd podczas wykonywania funkcji %1.
					           |
					           |Nieprawidłowy typ identyfikatora obiektu metadanych:
					           |""%2"".';
					           |tr = '%1 işlevi esnasında bir hata oluştu. 
					           |
					           | Metaveri nesne tanımlayıcısının türü yanlıştır: 
					           |""%2"".'"),
					"Common.MetadataObjectByID",
					TypeOf(CurrentID));
			EndIf;
			Raise ErrorText;
		Else
			ProcessedItems.Insert(CurrentID, Null);
		EndIf;
	EndDo;
	
	If ConfigurationIDs.Count() > 0 Then
		StandardSubsystemsCached.MetadataObjectIDsUsageCheck(True, False);
	EndIf;
	
	If ExtensionsIDs.Count() > 0 Then
		StandardSubsystemsCached.MetadataObjectIDsUsageCheck(True, True);
	EndIf;
	
	If ConfigurationIDs.Count() > 0 Or ExtensionsIDs.Count() > 0 Then
		FirstAttempt = Not Common.DataSeparationEnabled()
			Or Not Common.SeparatedDataUsageAvailable();
		
		MetadataObjects = MetadataObjectsByIDsWithoutRetryAttempt(IDs,
			ConfigurationIDs, ExtensionsIDs, RaiseException1, FirstAttempt);
	Else
		MetadataObjects = New Map;
	EndIf;
	
	If MetadataObjects = Undefined Then
		UpdateIsCompleted = UpdateIDCatalogs();
		If Not UpdateIsCompleted.MetadataObjectIDs Then
			UpdateCatalogData();
		EndIf;
		MetadataObjects = MetadataObjectsByIDsWithoutRetryAttempt(IDs,
			ConfigurationIDs, ExtensionsIDs, RaiseException1);
	EndIf;
	
	For Each KeyAndValue In ProcessedItems Do
		MetadataObjects.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	Return MetadataObjects;
	
EndFunction

// This method is required by MetadataObjectsByIDsWithRetryAttempt function.
Function MetadataObjectsByIDsWithoutRetryAttempt(IDs,
			ConfigurationIDs, ExtensionsIDs, RaiseException1, FirstAttempt = False)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Query = New Query;
	
	If ConfigurationIDs.Count() > 0 Then
		Query.SetParameter("ConfigurationIDs", ConfigurationIDs);
		Query.Text =
		"SELECT
		|	IDs.Ref AS Ref,
		|	IDs.MetadataObjectKey AS MetadataObjectKey,
		|	IDs.FullName AS FullName,
		|	IDs.Description AS Presentation,
		|	IDs.FullName AS FullCollectionName,
		|	IDs.DeletionMark AS DeletionMark,
		|	FALSE AS ExtensionObject,
		|	"""" AS ExtensionName,
		|	"""" AS ExtensionID,
		|	"""" AS ExtensionHashsum
		|FROM
		|	Catalog.MetadataObjectIDs AS IDs
		|WHERE
		|	IDs.Ref IN(&ConfigurationIDs)";
	EndIf;
	
	If ExtensionsIDs.Count() > 0 Then
		Query.SetParameter("ExtensionsIDs", ExtensionsIDs);
		Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
		If ValueIsFilled(Query.Text) Then
			Query.Text = Query.Text +
			"
			|
			|UNION ALL
			|
			|";
		EndIf;
		Query.Text = Query.Text +
		"SELECT
		|	IDs.Ref AS Ref,
		|	IDs.MetadataObjectKey AS MetadataObjectKey,
		|	ISNULL(IDsVersions.FullObjectName, """") AS FullName,
		|	IDs.Description AS Presentation,
		|	IDs.FullName AS FullCollectionName,
		|	IDs.DeletionMark AS DeletionMark,
		|	TRUE AS ExtensionObject,
		|	IDs.ExtensionName AS ExtensionName,
		|	IDs.ExtensionID AS ExtensionID,
		|	IDs.ExtensionHashsum AS ExtensionHashsum
		|FROM
		|	Catalog.ExtensionObjectIDs AS IDs
		|		LEFT JOIN InformationRegister.ExtensionVersionObjectIDs AS IDsVersions
		|		ON (IDsVersions.Id = IDs.Ref)
		|			AND (IDsVersions.ExtensionsVersion = &ExtensionsVersion)
		|WHERE
		|	IDs.Ref IN(&ExtensionsIDs)";
	EndIf;
	
	Upload0 = Query.Execute().Unload();
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lỗi khi thực hiện hàm %1.';
			|ru = 'Ошибка при выполнении функции %1.';
			|en = 'Error executing function ""%1""'; fa = 'Error executing function ""%1""';
			|it = 'Errore all''esecuzione della funzione %1.';
			|pl = 'Błąd podczas wykonywania funkcji %1.';
			|tr = '%1işlevin yürütülmesi esnasında hata oluştu.'"),
		"Common.MetadataObjectByID");
	
	IDsMetadataObjects = New Map;
	
	TotalIDs = ConfigurationIDs.Count() + ExtensionsIDs.Count();
	If Upload0.Count() < TotalIDs Then
		For Each Id In IDs Do
			If Upload0.Find(Id, "Ref") = Undefined Then
				If RaiseException1 Then
					Break;
				Else
					// The metadata object does not exist.
					IDsMetadataObjects.Insert(Id, Null);
					Continue;
				EndIf;
			EndIf;
		EndDo;
		If RaiseException1 Then
			If ExtensionsIDs.Find(Id) = Undefined Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đối tượng ""%1"" bị xóa trong phiên bản này của ứng dụng.
					           |Dữ liệu và tùy chỉnh liên quan đến đối tượng cũng không còn được sử dụng nữa.';
					           |ru = 'Объект ""%1"" удален в этой версии приложения.
					           |Связанные с ним данные и настройки также более недоступны.';
					           |en = 'The object ""%1"" was deleted from this app version.
					           |The related data and settings are no longer available.'; fa = 'The object ""%1"" was deleted from this app version.
					           |The related data and settings are no longer available.';
					           |it = 'Объект ""%1"" удален в этой версии приложения.
					           |Связанные с ним данные и настройки также более недоступны.';
					           |pl = 'The object ""%1"" was deleted from this app version.
					           |The related data and settings are no longer available.';
					           |tr = '""%1"" nesnesi uygulamanın bu sürümünde kaldırıldı.
					           |İlişkili veriler ve ayarlar da artık mevcut değil.'"),
					String(Id));
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đối tượng phần mở rộng ""%1"" bị xóa,
					           |bởi vì đã xóa phần mở rộng cùng với đối tượng hoặc đối tượng bị xóa khỏi phiên bản hiện tại của phần mở rộng.
					           |Dữ liệu và tùy chỉnh có liên quan đến đối tượng đó cũng không còn được sử dụng nữa.';
					           |ru = 'Объект расширения ""%1"" удален,
					           |т.к. вместе с ним удалено расширение или объект удален из текущей версии расширения.
					           |Связанные с ним данные и настройки также более недоступны.';
					           |en = 'The object ""%1"" is deleted since either
					           |its extension was removed or the object was deleted from the extensions version.
					           |The related data and settings are no longer available.'; fa = 'The object ""%1"" is deleted since either
					           |its extension was removed or the object was deleted from the extensions version.
					           |The related data and settings are no longer available.';
					           |it = 'Объект расширения ""%1"" удален,
					           |т.к. вместе с ним удалено расширение или объект удален из текущей версии расширения.
					           |Связанные с ним данные и настройки также более недоступны.';
					           |pl = 'The object ""%1"" is deleted since either
					           |its extension was removed or the object was deleted from the extensions version.
					           |The related data and settings are no longer available.';
					           |tr = 'Uzantı nesnesi ""%1"" silindi, 
					           |çünkü... Uzantı kendisiyle birlikte olan uzantı veya nesne, uzantının geçerli sürümünden kaldırıldı.
					           |Onunla ilişkili veriler ve ayarlar da artık mevcut değil.'"),
					String(Id));
			EndIf;
			Raise ErrorText;
		EndIf;
	EndIf;
	
	Context = New Structure("DataBaseConfigurationChangedDynamically");
	
	// Checking whether the metadata object key matches the metadata object full name.
	For Each Properties In Upload0 Do
		CheckResult = MetadataObjectKeyMatchesFullName(Properties);
		If CheckResult.NotRespond Then
			
			If CheckResult.MetadataObject = Undefined Then
				If ValueIsFilled(CheckResult.ViewOfTheRemote) Then
					IDPresentation = CheckResult.ViewOfTheRemote;
				Else
					IDPresentation = Properties.Presentation;
				EndIf;
				
				If Properties.ExtensionObject Then
					TheExtensionObjectDoesNotExist = Properties.DeletionMark;
					ExtensionName = "";
					ExtensionID = ?(StrStartsWith(Properties.ExtensionID, "? "),
						Mid(Properties.ExtensionID, 3), Properties.ExtensionID);
					If StringFunctionsClientServer.IsUUID(ExtensionID) Then
						Filter = New Structure("UUID", New UUID(ExtensionID));
						InstalledExtensions = ConfigurationExtensions.Get(Filter, ConfigurationExtensionsSource.Database);
						DetachedExtensions   = ConfigurationExtensions.Get(Filter, ConfigurationExtensionsSource.SessionDisabled);
						ActiveExtensions      = ConfigurationExtensions.Get(Filter, ConfigurationExtensionsSource.SessionApplied);
						If ActiveExtensions.Count() > 0 
							Or DetachedExtensions.Count() > 0 
							Or InstalledExtensions.Count() > 0 Then
							ExtensionName = InstalledExtensions[0].Name;
						EndIf;
					EndIf;
					If Not ValueIsFilled(ExtensionName) Then
						ExtensionName = ?(StrStartsWith(Properties.ExtensionName, "? "),
							Mid(Properties.ExtensionName, 3), Properties.ExtensionName);
						Filter = New Structure("Name", ExtensionName);
						InstalledExtensions = ConfigurationExtensions.Get(Filter, ConfigurationExtensionsSource.Database);
						DetachedExtensions   = ConfigurationExtensions.Get(Filter, ConfigurationExtensionsSource.SessionDisabled);
						ActiveExtensions      = ConfigurationExtensions.Get(Filter, ConfigurationExtensionsSource.SessionApplied);
					EndIf;
					If InstalledExtensions.Count() = 0 Then
						TheExtensionObjectDoesNotExist = True;
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Đối tượng ""%2"" không tồn tại, bởi vì đã xóa phần mở rộng ""%1"".
							           |Dữ liệu và tùy chỉnh có liên quan đến đối tượng cũng không còn được sử dụng nữa.';
							           |ru = 'Объект ""%2"" не существует, т.к. удалено расширение ""%1"".
							           |Связанные с ним данные и настройки более недоступны.';
							           |en = 'The object ""%2"" does not exist since its extension ""%1"" was uninstalled.
							           |The related data and settings are no longer available.'; fa = 'The object ""%2"" does not exist since its extension ""%1"" was uninstalled.
							           |The related data and settings are no longer available.';
							           |it = 'Объект ""%2"" не существует, т.к. удалено расширение ""%1"".
							           |Связанные с ним данные и настройки более недоступны.';
							           |pl = 'The object ""%2"" does not exist since its extension ""%1"" was uninstalled.
							           |The related data and settings are no longer available.';
							           |tr = '""%2"" nesnesi mevcut değil çünkü ""%1"" uzantısı kaldırıldı.
							           |Onunla ilişkili veriler ve ayarlar artık mevcut değil.'"),
							ExtensionName,
							IDPresentation);
						
					ElsIf Not InstalledExtensions[0].Active Then
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Đã cài đặt phần mở rộng ""%1"", nhưng nó đang bị vô hiệu.
							           |Hãy bật sử dụng phần mở rộng và khởi động lại phiên làm việc.';
							           |ru = 'Расширение ""%1"" установлено, но выключено.
							           |Включите расширение и перезапустите сеанс.';
							           |en = 'The extension ""%1"" is installed but disabled.
							           |Enable the extensions and restart the app.'; fa = 'The extension ""%1"" is installed but disabled.
							           |Enable the extensions and restart the app.';
							           |it = 'Расширение ""%1"" установлено, но выключено.
							           |Включите расширение и перезапустите сеанс.';
							           |pl = 'The extension ""%1"" is installed but disabled.
							           |Enable the extensions and restart the app.';
							           |tr = '""%1"" uzantısı yüklendi ancak devre dışı bırakıldı.
							           |Uzantıyı etkinleştirin ve oturumunuzu yeniden başlatın.'"),
							ExtensionName);
						
					ElsIf DetachedExtensions.Count() > 0 And Not DetachedExtensions[0].Active
					      Or DetachedExtensions.Count() = 0 And ActiveExtensions.Count() = 0 Then
						
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Đã cài đặt phần mở rộng ""%1"" sau khi khởi động phiên làm việc, do đó nó chưa được kết nối.
							           |Hãy khởi động lại phiên làm việc.';
							           |ru = 'Расширение ""%1"" установлено после запуска сеанса, поэтому не подключено.
							           |Перезапустите сеанс.';
							           |en = 'The extension ""%1"" is installed but the app requires a restart.
							           |Restart the app.'; fa = 'The extension ""%1"" is installed but the app requires a restart.
							           |Restart the app.';
							           |it = 'Расширение ""%1"" установлено после запуска сеанса, поэтому не подключено.
							           |Перезапустите сеанс.';
							           |pl = 'The extension ""%1"" is installed but the app requires a restart.
							           |Restart the app.';
							           |tr = '""%1"" uzantısı oturum başladıktan sonra yüklendi ve bu nedenle bağlı değil.
							           |Oturumu yeniden başlatın.'"),
							ExtensionName);
						
					ElsIf DetachedExtensions.Count() > 0 And DetachedExtensions[0].Active Then
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Đã cài đặt phần mở rộng ""%1"" nhưng nó đang bị vô hiệu khi khởi động phiên làm việc. 
							           |Điều này có nghĩa là đã xảy ra tình huống bất ngờ khi kết nối.';
							           |ru = 'Расширение ""%1"" установлено, но отключено при запуске сеанса.
							           |Это значит, что при его подключении возникла непредвиденная ситуация.';
							           |en = 'The extension ""%1"" is installed but it was disabled at the startup.
							           |This means that an unexpected exception occurred.'; fa = 'The extension ""%1"" is installed but it was disabled at the startup.
							           |This means that an unexpected exception occurred.';
							           |it = 'Расширение ""%1"" установлено, но отключено при запуске сеанса.
							           |Это значит, что при его подключении возникла непредвиденная ситуация.';
							           |pl = 'The extension ""%1"" is installed but it was disabled at the startup.
							           |This means that an unexpected exception occurred.';
							           |tr = '''%1'' uzantısı yüklendi ancak oturum başladığında devre dışı bırakıldı.
							           |Bu, bağlandığında beklenmeyen bir durumun meydana geldiği anlamına gelir.'"),
							ExtensionName);
						
					Else // ActiveExtensions.Count() > 0
						TheExtensionObjectDoesNotExist = True;
						
						If CheckResult.RemoteMetadataObject <> Undefined
						   And CheckResult.RemoteMetadataObject.ConfigurationExtension() <> Undefined
						   And CheckResult.RemoteMetadataObject.ConfigurationExtension().Name = ActiveExtensions[0].Name Then
							
							ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Tên đối tượng metadata ""%2"" của phần mở rộng ""%1"" bị đánh dấu xóa.
								           |Thông thường, điều này có nghĩa là, phần mở rộng đã bị xóa và thiết lập lại (thay vì cập nhật phần mở rộng lên phiên bản mới).
								           |Dữ liệu và tùy chỉnh liên quan đến phần mở rộng cũng không còn được sử dụng nữa.';
								           |ru = 'Идентификатор объекта метаданных ""%2"" расширения ""%1"" помечен на удаление.
								           |Обычно это значит, что расширение было удалено и установлено заново (вместо обновления расширения на новую версию).
								           |Связанные с ним данные и настройки более недоступны.';
								           |en = 'The id of the ""%2"" metadata object, which is a part of the ""%1"" extension, is marked for deletion.
								           |Usually, this happens when an extension is uninstalled and then reinstalled (instead of being updated).
								           |The related data and settings are no longer available.'; fa = 'The id of the ""%2"" metadata object, which is a part of the ""%1"" extension, is marked for deletion.
								           |Usually, this happens when an extension is uninstalled and then reinstalled (instead of being updated).
								           |The related data and settings are no longer available.';
								           |it = 'Идентификатор объекта метаданных ""%2"" расширения ""%1"" помечен на удаление.
								           |Обычно это значит, что расширение было удалено и установлено заново (вместо обновления расширения на новую версию).
								           |Связанные с ним данные и настройки более недоступны.';
								           |pl = 'The id of the ""%2"" metadata object, which is a part of the ""%1"" extension, is marked for deletion.
								           |Usually, this happens when an extension is uninstalled and then reinstalled (instead of being updated).
								           |The related data and settings are no longer available.';
								           |tr = '""%1"" uzantısının meta veri nesne kimliği ""%2"" silinmek üzere işaretlendi.
								           |Bu genellikle uzantının kaldırıldığı ve yeniden yüklendiği anlamına gelir (uzantının yeni bir sürüme güncellenmesi yerine).
								           |Uzantıyla ilişkili veriler ve ayarlar artık mevcut değil.'"),
								ExtensionName,
								IDPresentation);
						Else
							ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Đối tượng ""%2"" bị xóa trong phiên bản hiện tại của phần mở rộng ""%1"".
								           |Dữ liệu và tùy chỉnh liên quan đến đối tượng cũng không còn được sử dụng nữa.';
								           |ru = 'Объект ""%2"" удален в текущей версии расширения ""%1"".
								           |Связанные с ним данные и настройки более недоступны.';
								           |en = 'The object ""%2"" was deleted in the current version of the extension ""%1"".
								           |The related data and settings are no longer available.'; fa = 'The object ""%2"" was deleted in the current version of the extension ""%1"".
								           |The related data and settings are no longer available.';
								           |it = 'Объект ""%2"" удален в текущей версии расширения ""%1"".
								           |Связанные с ним данные и настройки более недоступны.';
								           |pl = 'The object ""%2"" was deleted in the current version of the extension ""%1"".
								           |The related data and settings are no longer available.';
								           |tr = '""%2"" nesnesi, ""%1"" uzantısının mevcut sürümünden kaldırıldı.
								           |İlişkili veriler ve ayarlar artık mevcut değil.'"),
								ExtensionName,
								IDPresentation);
						EndIf;
					EndIf;
					
					If RaiseException1 Then
						Raise ErrorText;
						
					ElsIf TheExtensionObjectDoesNotExist Then
						IDsMetadataObjects.Insert(Properties.Ref, Null);
					Else
						IDsMetadataObjects.Insert(Properties.Ref, Undefined);
						Continue;
					EndIf;
					
				ElsIf DataBaseConfigurationChangedDynamicallyFromContext(Context) Then
					// The metadata object might be available after restart.
					If RaiseException1 Then
						// Standard exception caused by dynamic update.
						StandardSubsystemsServer.RequireRestartDueToApplicationVersionDynamicUpdate();
					Else
						IDsMetadataObjects.Insert(Properties.Ref, Undefined);
						Continue;
					EndIf;
					
				ElsIf Not RaiseException1 Then
					// The metadata object does not exist.
					IDsMetadataObjects.Insert(Properties.Ref, Null);
					Continue;
					
				ElsIf CheckResult.RemoteMetadataObject <> Undefined
				        And CheckResult.RemoteMetadataObject.ConfigurationExtension() = Undefined Then
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Tên định danh đối tượng metadata ""%1"" bị đánh dấu xóa.
						           |Điều này có nghĩa là, đối tượng metadata bị xóa khỏi cấu hình, sau đó sẽ được thêm lại.
						           |Dữ liệu và tùy chỉnh liên quan đến đối tượng sẽ không còn được sử dụng nữa.';
						           |ru = 'Идентификатор объекта метаданных ""%1"" помечен на удаление.
						           |Это значит, что объект метаданных был удален из конфигурации, а позже снова добавлен.
						           |Связанные с ним данные и настройки более недоступны.';
						           |en = 'The id of the ""%1"" metadata object is marked for deletion.
						           |Usually, this happens when an object is deleted and then re-added.
						           |The related data and settings are no longer available.'; fa = 'The id of the ""%1"" metadata object is marked for deletion.
						           |Usually, this happens when an object is deleted and then re-added.
						           |The related data and settings are no longer available.';
						           |it = 'Идентификатор объекта метаданных ""%1"" помечен на удаление.
						           |Это значит, что объект метаданных был удален из конфигурации, а позже снова добавлен.
						           |Связанные с ним данные и настройки более недоступны.';
						           |pl = 'The id of the ""%1"" metadata object is marked for deletion.
						           |Usually, this happens when an object is deleted and then re-added.
						           |The related data and settings are no longer available.';
						           |tr = 'Meta veri nesnesi kimliği ""%1"" silinmek üzere işaretlendi.
						           |Bu, meta veri nesnesinin konfigürasyondan kaldırıldığı ve daha sonra tekrar eklendiği anlamına gelir.
						           |İlişkili veriler ve ayarlar artık mevcut değil.'"),
						IDPresentation);
					Raise ErrorText;
				Else
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Đối tượng metadata ""%1"" không tồn tại, bởi vì nó bị xóa trong phiên bản này của ứng dụng.
						           |Dữ liệu và tùy chỉnh liên quan đến đối tượng cũng không còn được sử dụng nữa.';
						           |ru = 'Объект метаданных ""%1"" не существует, т.к. удален в этой версии приложении.
						           |Связанные с ним данные и настройки более недоступны.';
						           |en = 'The object ""%1"" does not exist as it was removed from the current app version.
						           |The related data and settings are no longer available.'; fa = 'The object ""%1"" does not exist as it was removed from the current app version.
						           |The related data and settings are no longer available.';
						           |it = 'Объект метаданных ""%1"" не существует, т.к. удален в этой версии приложении.
						           |Связанные с ним данные и настройки более недоступны.';
						           |pl = 'The object ""%1"" does not exist as it was removed from the current app version.
						           |The related data and settings are no longer available.';
						           |tr = '''%1'' meta veri nesnesi mevcut değil çünkü uygulamanın bu sürümünde kaldırıldı.
						           |İlişkili veriler ve ayarlar artık mevcut değil.'"),
						IDPresentation);
					Raise ErrorText;
				EndIf;
				
			ElsIf DataBaseConfigurationChangedDynamicallyFromContext(Context) Then
				// The metadata object might have been renamed.
				ErrorDescription = "";
			Else
				If FirstAttempt Then
					Return Undefined;
				EndIf;
				ErrorDescription =  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Tên định danh ""%1"" từ danh mục ""%2"",
					           | tương ứng với đối tượng metadata ""%3"",
					           |mà tên đầy đủ của nó khác với tên đã đặt trong tên định danh.';
					           |ru = 'Идентификатору ""%1"" из справочника ""%2"",
					           |соответствует объект метаданных ""%3"",
					           |полное имя которого отличается от заданного в идентификаторе.';
					           |en = 'The id ""%1"" from the catalog ""%2""
					           |corresponds with the metadata object ""%3"", whose full name
					           |does not match the full name in the id.'; fa = 'The id ""%1"" from the catalog ""%2""
					           |corresponds with the metadata object ""%3"", whose full name
					           |does not match the full name in the id.';
					           |it = 'Идентификатору ""%1"" из справочника ""%2"",
					           |соответствует объект метаданных ""%3"",
					           |полное имя которого отличается от заданного в идентификаторе.';
					           |pl = 'The id ""%1"" from the catalog ""%2""
					           |corresponds with the metadata object ""%3"", whose full name
					           |does not match the full name in the id.';
					           |tr = '""%2"" dizinindeki ""%1"" tanımlayıcısı,
					           |tam adı tanımlayıcıda belirtilenden farklı olan
					           |""%3"" meta veri nesnesine karşılık gelir.'"),
					Properties.Presentation,
					CatalogDescription(False),
					CheckResult.MetadataObject.FullName())
					+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper();
			EndIf;
			
			If ValueIsFilled(ErrorDescription) Then
				ErrorText = ErrorTitle + Chars.LF + Chars.LF + ErrorDescription;
				Raise ErrorText;
			EndIf;
		EndIf;
		
		If Not Properties.ExtensionObject
		   And Properties.DeletionMark
		   And Not DataBaseConfigurationChangedDynamicallyFromContext(Context) Then
			
			If FirstAttempt Then
				Return Undefined;
			EndIf;
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tên định danh ""%1"" từ danh mục ""%2"" bị đặt dấu xóa.';
					|ru = 'Идентификатор ""%1"" из справочника ""%2"" помечен на удаление.';
					|en = 'The id ""%1"" from the catalog ""%2"" is marked for deletion.'; fa = 'The id ""%1"" from the catalog ""%2"" is marked for deletion.';
					|it = 'Идентификатор ""%1"" из справочника ""%2"" помечен на удаление.';
					|pl = 'The id ""%1"" from the catalog ""%2"" is marked for deletion.';
					|tr = '""%2"" dizinindeki ""%1"" tanımlayıcısı silinmek üzere işaretlendi.'"),
				Properties.Presentation,
				CatalogDescription(False));
			
			ErrorText = ErrorTitle + Chars.LF + Chars.LF + ErrorDescription
				+ StandardSubsystemsServer.ApplicationRunParameterErrorClarificationForDeveloper();
			Raise ErrorText;
		EndIf;
		
		MetadataObjectDetails = New Structure("Object, Key, FullName", CheckResult.MetadataObject);
		If CheckResult.MetadataObjectKey <> Undefined Then
			MetadataObjectDetails.Key = CheckResult.MetadataObjectKey;
		Else
			MetadataObjectDetails.Key      = Properties.FullName;
			MetadataObjectDetails.FullName = Properties.FullName;
		EndIf;
		IDsMetadataObjects.Insert(Properties.Ref, MetadataObjectDetails);
	EndDo;
	
	Return IDsMetadataObjects;
	
EndFunction

// This method is required by MetadataObjectsByIDs and MetadataObjectIDs functions.
Function IDCache()
	
	CachedDataKey = String(SessionParameters.CachedDataKey);
	
	Return StandardSubsystemsCached.MetadataObjectIDCache(CachedDataKey);
	
EndFunction

// Intended to be called from  StandardSubsystemsCached.MetadataObjectIDCache.
// 
// Parameters:
//  CachedDataKey - UUID
//
// Returns:
//  Structure:
//   * IDsByFullNames - Map
//   * DetailsOfMetadataObjectsByIDs - Map
//
Function MetadataObjectIDCache(CachedDataKey) Export
	
	Storage = New Structure;
	Storage.Insert("IDsByFullNames", New Map);
	Storage.Insert("DetailsOfMetadataObjectsByIDs", New Map);
	
	Return New FixedStructure(Storage);
	
EndFunction

// To be called from StandardSubsystemsCached.MetadataObjectIDPresentation.
// Used from the PresentationGetProcessing procedure.
// 
// Parameters:
//  Ref - CatalogRef.MetadataObjectIDs
//         - CatalogRef.ExtensionObjectIDs
//
// Returns:
//  String
//
Function IDPresentation(Ref) Export
	
	ExtensionsObjects = TypeOf(Ref) <> Type("CatalogRef.MetadataObjectIDs");
	CollectionsProperties = StandardSubsystemsCached.MetadataObjectCollectionProperties(ExtensionsObjects);
	
	CollectionProperties = CollectionsProperties.Find(Ref.UUID(), "Id");
	If CollectionProperties <> Undefined Then
		Return CollectionProperties.Synonym;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	
	If ExtensionsObjects Then
		Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
		Query.Text =
		"SELECT TOP 1
		|	ISNULL(ExtensionVersionObjectIDs.FullObjectName, ExtensionObjectIDs.FullName) AS FullName
		|FROM
		|	Catalog.ExtensionObjectIDs AS ExtensionObjectIDs
		|		LEFT JOIN InformationRegister.ExtensionVersionObjectIDs AS ExtensionVersionObjectIDs
		|		ON (ExtensionVersionObjectIDs.Id = ExtensionObjectIDs.Ref)
		|			AND (ExtensionVersionObjectIDs.ExtensionsVersion = &ExtensionsVersion)
		|WHERE
		|	ExtensionObjectIDs.Ref = &Ref";
	Else
		Query.Text =
		"SELECT TOP 1
		|	MetadataObjectIDs.FullName AS FullName
		|FROM
		|	Catalog.MetadataObjectIDs AS MetadataObjectIDs
		|WHERE
		|	MetadataObjectIDs.Ref = &Ref";
	EndIf;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FullName = Selection.FullName;
	Else
		FullName = Undefined;
	EndIf;
	
	If FullName = Undefined Then
		Return NStr("vi = 'Đối tượng không tồn tại.';
					|ru = 'Объект не существует.';
					|en = 'The object does not exist.'; fa = 'The object does not exist.';
					|it = 'Oggetto inesistente.';
					|pl = 'Obiektu nie istnieje.';
					|tr = 'Nesne mevcut değil.'");
	EndIf;
	
	If StrStartsWith(FullName, "?") Then
		Return "? " + StrSplit(FullName, " ")[1];
	EndIf;
	
	PointPosition = StrFind(FullName, ".");
	BaseTypeName = Left(FullName, PointPosition -1);
	
	Filter = New Structure("SingularName", BaseTypeName);
	Rows = CollectionsProperties.FindRows(Filter);
	
	If Rows.Count() <> 1 Then
		Return FullName;
	EndIf;
	
	MetadataObject = Common.MetadataObjectByFullName(FullName);
	If MetadataObject = Undefined Then
		Return FullName;
	EndIf;
	
	Return MetadataObjectPresentation(MetadataObject, Rows[0]);
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsToReplaceIDInDatabase

Procedure ReplaceSubordinateNodeDuplicatesFoundOnImport(IsCheckOnly, HasChanges)
	
	If Common.DataSeparationEnabled() Then
		// Not supported in SaaS mode.
		Return;
	EndIf;
	
	If Not Common.IsSubordinateDIBNode() Then
		Return;
	EndIf;
	
	// Replacing the duplicates in a subordinate DIB node.
	Query = New Query;
	Query.Text =
	"SELECT
	|	IDs.Ref,
	|	IDs.NewRef
	|FROM
	|	Catalog.MetadataObjectIDs AS IDs
	|WHERE
	|	IDs.NewRef <> VALUE(Catalog.MetadataObjectIDs.EmptyRef)";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	If IsCheckOnly Then
		HasChanges = True;
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	RefsToReplace = New Array;
	PreviousAndNewRefs = New Map;
	While Selection.Next() Do
		RefsToReplace.Add(Selection.Ref);
		PreviousAndNewRefs.Insert(Selection.Ref, Selection.NewRef);
	EndDo;
	
	CurrentAttempt = 1;
	While True Do
		DataFound = FindByRef(RefsToReplace);
		DataFound.Columns[0].Name = "Ref";
		DataFound.Columns[1].Name = "Data";
		DataFound.Columns[2].Name = "Metadata";
		DataFound.Columns.Add("isEnabled");
		DataFound.FillValues(True, "isEnabled");
		
		If DataFound.Count() = 0 Then
			Block = New DataLock;
			LockItem = Block.Add("Catalog.MetadataObjectIDs");
			For Each RefToReplace In RefsToReplace Do
				LockItem.SetValue("Ref", RefToReplace);
			EndDo;
			BeginTransaction();
			Try
				Block.Lock();
				// Clearing new references from the duplicates IDs.
				For Each RefToReplace In RefsToReplace Do
					DuplicateObject1 = RefToReplace.GetObject();
					DuplicateObject1.NewRef = Undefined;
					DuplicateObject1.DataExchange.Load = True;
					DuplicateObject1.Write();
				EndDo;
				CommitTransaction();
			Except
				RollbackTransaction();
				Raise;
			EndTry;
			Break;
		EndIf;
		
		If CurrentAttempt > 10 Then
			ErrorText =
				NStr("vi = 'Không thể thay thế phần tử trùng lặp tên định danh đối tượng metadata.
				           |Sau 10 lần thử, vẫn còn dữ liệu cần thay thế.
				           |Hãy thực hiện thao tác ở chế độ độc quyền.';
				           |ru = 'Не удалось выполнить замену дублей идентификаторов объектов метаданных.
				           |После 10 попыток все еще имеются данные, которые требуют замены.
				           |Выполните действие в монопольном режиме.';
				           |en = 'Cannot replace duplicates of metadata object IDs.
				           |After 10 attempts, there is still data to be replaced.
				           |Please perform this operation in exclusive mode.'; fa = 'Cannot replace duplicates of metadata object IDs.
				           |After 10 attempts, there is still data to be replaced.
				           |Please perform this operation in exclusive mode.';
				           |it = 'Sostituzione degli identificatori duplicati degli oggetti dei metadati non riuscita.
				           |Dopo 10 tentativi, sono ancora presenti dati che devono essere sostituiti.
				           |Eseguite l''operazione in modalità esclusiva.';
				           |pl = 'Zamiana duplikatów identyfikatorów metadanych nie powiodła się.
				           |Po 10 próbach nadal istnieją dane, które wymagają zamiany.
				           |Wykonaj działanie w trybie wyłącznym.';
				           |tr = 'Meta veri nesne kimlikleri çiftleri değiştirilemedi. 
				           |10 denemeden sonra, değiştirilmesi gereken veriler hala var. 
				           |Özel modda bir eylem gerçekleştirin.'");
			Raise ErrorText;
		EndIf;
		
		WithoutErrors = ExecuteItemReplacement(PreviousAndNewRefs, DataFound, True);
		If Not WithoutErrors Then
			ErrorText =
				NStr("vi = 'Không thể thay thế các tên định danh trùng lặp của đối tượng metadata.
				           |Chi tiết xem lỗi khi thay đổi tên định danh trong nhật ký sự kiện.';
				           |ru = 'Не удалось выполнить замену дублей идентификаторов объектов метаданных.
				           |Подробнее см. ошибки при замене идентификатора в журнале регистрации.';
				           |en = 'Cannot replace duplicate metadata object IDs.
				           |For more information, see the ID replacement errors in the event log.'; fa = 'Cannot replace duplicate metadata object IDs.
				           |For more information, see the ID replacement errors in the event log.';
				           |it = 'Sostituzione degli identificatori duplicati degli oggetti dei metadati non riuscita.
				           |Per maggiori informazioni controllare gli errori durante la sostituzione dell''identificatore nel registro di registrazione.';
				           |pl = 'Zamiana duplikatów identyfikatorów metadanych nie powiodła się.
				           |Szczegóły zob. błędy przy zamianie identyfikatora w dzienniku rejestracji.';
				           |tr = 'Meta veri nesne kimlikleri çiftleri değiştirilemedi. 
				           |Daha fazla bilgi için olay günlüğündeki ID değişiklik hatalarına bakın.'");
			Raise ErrorText;
		EndIf;
		CurrentAttempt = CurrentAttempt + 1;
	EndDo;
	
EndProcedure

// The function from the ValueSearchingAndReplacing universal data processor.
// Changes:
// - operations with the progress bar form are no longer supported;
// - the UserInterruptProcessing procedure is deleted;
// - the InformationRegisters[TableRow.Metadata.Name] is replaced with
//   Common.ObjectManagerByFullName(TableRow.Metadata.FullName()).
//
Function ExecuteItemReplacement(Val Replaceable, Val RefsTable, Val DisableWriteControl = False, Val ExtensionsObjects = False)
	
	// ACC:1327-off - No.783.1.4.1
	// 1. It's not a transaction since it can be long-running.
	// 2. The execution follows a data import (infobase update) from the master node.
// 3. It's executed when duplicates of metadata object IDs are found (a rare occurrence).
	Parameters = ItemsReplacementParameters();
	
	For Each AccountingRegister In Metadata.AccountingRegisters Do
		Parameters.Insert(AccountingRegister.Name + "ExtDimension",        AccountingRegister.ChartOfAccounts.MaxExtDimensionCount);
		Parameters.Insert(AccountingRegister.Name + "Correspondence", AccountingRegister.Correspondence);
	EndDo;
	
	RefToProcess = Undefined;
	HadExceptions = False;
	
	Try
		For Each TableRow In RefsTable Do
			If Not TableRow.isEnabled Then
				Continue;
			EndIf;
			CorrectItem = Replaceable[TableRow.Ref];
			
			Ref = TableRow.Ref;
			
			If RefToProcess <> TableRow.Data Then
				If RefToProcess <> Undefined And Parameters.Object <> Undefined Then
					
					Try
						Parameters.Object.DataExchange.Load = True;
						If DisableWriteControl Then
							Parameters.Object.AdditionalProperties.Insert("SkipObjectVersionRecord");
							InfobaseUpdate.WriteData(Parameters.Object, False);
						Else
							Parameters.Object.Write();
						EndIf;
					Except
						HadExceptions = True;
						ErrorInfo = ErrorInfo();
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Không thể ghi lại đối tượng ""%1"" theo nguyên nhân:
							           |%2';
							           |ru = 'Не удалось записать объект ""%1"" по причине:
							           |%2';
							           |en = 'Couldn''t write object ""%1"" due to:
							           |%2'; fa = 'Couldn''t write object ""%1"" due to:
							           |%2';
							           |it = 'Не удалось записать объект ""%1"" по причине:
							           |%2';
							           |pl = 'Couldn''t write object ""%1"" due to:
							           |%2';
							           |tr = '""%1"" nesnesi şu nedenle kaydedilemedi:
							           |%2'"),
							GetURL(Parameters.Object.Ref),
							ErrorProcessing.DetailErrorDescription(ErrorInfo));
						If TransactionActive() Then
							Raise ErrorText;
						EndIf;
						ReportError(ErrorText, ExtensionsObjects);
					EndTry;
					Parameters.Object = Undefined;
				EndIf;
				RefToProcess = TableRow.Data;
			EndIf;
			
			If Metadata.Documents.Contains(TableRow.Metadata) Then
				
				If Parameters.Object = Undefined Then
					Parameters.Object = TableRow.Data.GetObject();
				EndIf;
				
				For Each Attribute In TableRow.Metadata.Attributes Do
					If Attribute.Type.ContainsType(TypeOf(Ref)) And Parameters.Object[Attribute.Name] = Ref Then
						Parameters.Object[Attribute.Name] = CorrectItem;
					EndIf;
				EndDo;
					
				For Each TabularSection In TableRow.Metadata.TabularSections Do
					For Each Attribute In TabularSection.Attributes Do
						If Attribute.Type.ContainsType(TypeOf(Ref)) Then
							LineOfATabularSection = Parameters.Object[TabularSection.Name].Find(Ref, Attribute.Name);
							While LineOfATabularSection <> Undefined Do
								LineOfATabularSection[Attribute.Name] = CorrectItem;
								LineOfATabularSection = Parameters.Object[TabularSection.Name].Find(Ref, Attribute.Name);
							EndDo;
						EndIf;
					EndDo;
				EndDo;
				
				For Each Movement In TableRow.Metadata.RegisterRecords Do
					
					IsAccountingRegisterRecord = Metadata.AccountingRegisters.Contains(Movement);
					HasCorrespondence = IsAccountingRegisterRecord And Parameters[Movement.Name + "Correspondence"];
					
					RecordSet = Parameters.Object.RegisterRecords[Movement.Name];
					RecordSet.Read();
					MustWrite = False;
					SetTable = RecordSet.Unload();
					
					If SetTable.Count() = 0 Then
						Continue;
					EndIf;
					
					ColumnsNames = New Array;
					
					// Getting names of dimensions that might contain references.
					For Each Dimension In Movement.Dimensions Do
						
						If Dimension.Type.ContainsType(TypeOf(Ref)) Then
							
							If IsAccountingRegisterRecord Then
								
								If Dimension.AccountingFlag <> Undefined Then
									
									ColumnsNames.Add(Dimension.Name + "Dr");
									ColumnsNames.Add(Dimension.Name + "Cr");
								Else
									ColumnsNames.Add(Dimension.Name);
								EndIf;
							Else
								ColumnsNames.Add(Dimension.Name);
							EndIf;
						EndIf;
					EndDo;
					
					// Getting names of resources that might contain references.
					If Metadata.InformationRegisters.Contains(Movement) Then
						For Each Resource In Movement.Resources Do
							If Resource.Type.ContainsType(TypeOf(Ref)) Then
								ColumnsNames.Add(Resource.Name);
							EndIf;
						EndDo;
					EndIf;
					
					// Getting names of resources that might contain references.
					For Each Attribute In Movement.Attributes Do
						If Attribute.Type.ContainsType(TypeOf(Ref)) Then
							ColumnsNames.Add(Attribute.Name);
						EndIf;
					EndDo;
					
					// Making replacements in the table.
					For Each ColumnName In ColumnsNames Do
						TabSectionRow = SetTable.Find(Ref, ColumnName);
						While TabSectionRow <> Undefined Do
							TabSectionRow[ColumnName] = CorrectItem;
							MustWrite = True;
							TabSectionRow = SetTable.Find(Ref, ColumnName);
						EndDo;
					EndDo;
					
					If Metadata.AccountingRegisters.Contains(Movement) Then
						
						For ExtDimensionIndex = 1 To Parameters[Movement.Name + "ExtDimension"] Do
							If HasCorrespondence Then
								TabSectionRow = SetTable.Find(Ref, "ExtDimensionDr"+ExtDimensionIndex);
								While TabSectionRow <> Undefined Do
									TabSectionRow["ExtDimensionDr"+ExtDimensionIndex] = CorrectItem;
									MustWrite = True;
									TabSectionRow = SetTable.Find(Ref, "ExtDimensionDr"+ExtDimensionIndex);
								EndDo;
								TabSectionRow = SetTable.Find(Ref, "ExtDimensionCr"+ExtDimensionIndex);
								While TabSectionRow <> Undefined Do
									TabSectionRow["ExtDimensionCr"+ExtDimensionIndex] = CorrectItem;
									MustWrite = True;
									TabSectionRow = SetTable.Find(Ref, "ExtDimensionCr"+ExtDimensionIndex);
								EndDo;
							Else
								TabSectionRow = SetTable.Find(Ref, "ExtDimension"+ExtDimensionIndex);
								While TabSectionRow <> Undefined Do
									TabSectionRow["ExtDimension"+ExtDimensionIndex] = CorrectItem;
									MustWrite = True;
									TabSectionRow = SetTable.Find(Ref, "ExtDimension"+ExtDimensionIndex);
								EndDo;
							EndIf;
						EndDo;
						
						If Ref.Metadata() = Movement.ChartOfAccounts Then
							For Each TabSectionRow In SetTable Do
								If HasCorrespondence Then
									If TabSectionRow.AccountDr = Ref Then
										TabSectionRow.AccountDr = CorrectItem;
										MustWrite = True;
									EndIf;
									If TabSectionRow.AccountCr = Ref Then
										TabSectionRow.AccountCr = CorrectItem;
										MustWrite = True;
									EndIf;
								Else
									If TabSectionRow.Account = Ref Then
										TabSectionRow.Account = CorrectItem;
										MustWrite = True;
									EndIf;
								EndIf;
							EndDo;
						EndIf;
					EndIf;
					
					If Metadata.CalculationRegisters.Contains(Movement) Then
						TabSectionRow = SetTable.Find(Ref, "CalculationType");
						While TabSectionRow <> Undefined Do
							TabSectionRow["CalculationType"] = CorrectItem;
							MustWrite = True;
							TabSectionRow = SetTable.Find(Ref, "CalculationType");
						EndDo;
					EndIf;
					
					If MustWrite Then
						RecordSet.Load(SetTable);
						Try
							If DisableWriteControl Then
								RecordSet.AdditionalProperties.Insert("SkipObjectVersionRecord");
								InfobaseUpdate.WriteData(RecordSet, False);
							Else
								RecordSet.Write();
							EndIf;
						Except
							HadExceptions = True;
							ErrorInfo = ErrorInfo();
							ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Không thể ghi lại biến động của đối tượng ""%1"" trong ""%2"" theo nguyên nhân:
								           |%3';
								           |ru = 'Не удалось записать движения объекта ""%1"" в ""%2"" по причине:
								           |%3';
								           |en = 'Couldn''t add to ""%2"" a record for object ""%1"" due to:
								           |%3'; fa = 'Couldn''t add to ""%2"" a record for object ""%1"" due to:
								           |%3';
								           |it = 'Не удалось записать движения объекта ""%1"" в ""%2"" по причине:
								           |%3';
								           |pl = 'Couldn''t add to ""%2"" a record for object ""%1"" due to:
								           |%3';
								           |tr = '""%1"" nesnesinin ""%2"" nesnesine hareketleri şu nedenlerden dolayı kaydedilemedi:
								           |%3'"),
								GetURL(Parameters.Object.Ref),
								RecordSet.Metadata().FullName(),
								ErrorProcessing.DetailErrorDescription(ErrorInfo));
							If TransactionActive() Then
								Raise ErrorText;
							EndIf;
							ReportError(ErrorText, ExtensionsObjects);
						EndTry;
					EndIf;
				EndDo;
				
				For Each Sequence In Metadata.Sequences Do
					If Sequence.Documents.Contains(TableRow.Metadata) Then
						MustWrite = False;
						SingleRecordSet = Sequences[Sequence.Name].CreateRecordSet(); // SequenceRecordSet 
						SingleRecordSet.Filter.Recorder.Set(TableRow.Data);
						SingleRecordSet.Read();
						
						If SingleRecordSet.Count() > 0 Then
							For Each Dimension In Sequence.Dimensions Do
								If Dimension.Type.ContainsType(TypeOf(Ref)) And SingleRecordSet[0][Dimension.Name]=Ref Then
									SingleRecordSet[0][Dimension.Name] = CorrectItem;
									MustWrite = True;
								EndIf;
							EndDo;
							If MustWrite Then
								Try
									If DisableWriteControl Then
										SingleRecordSet.AdditionalProperties.Insert("SkipObjectVersionRecord");
										InfobaseUpdate.WriteData(SingleRecordSet, False);
									Else
										SingleRecordSet.Write();
									EndIf;
								Except
									HadExceptions = True;
									ErrorInfo = ErrorInfo();
									ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
											NStr("vi = 'Không thể ghi lại dữ liệu theo nguồn ghi ""%1"" trong ""%2"" theo nguyên nhân:
											           |%3';
											           |ru = 'Не удалось записать данные по регистратору ""%1"" в ""%2"" по причине:
											           |%3';
											           |en = 'Couldn''t add to ""%2"" data for recorder ""%1"" due to:
											           |%3'; fa = 'Couldn''t add to ""%2"" data for recorder ""%1"" due to:
											           |%3';
											           |it = 'Не удалось записать данные по регистратору ""%1"" в ""%2"" по причине:
											           |%3';
											           |pl = 'Couldn''t add to ""%2"" data for recorder ""%1"" due to:
											           |%3';
											           |tr = '""%1"" kaydediciden ""%2""ye veriler şu nedenlerden dolayı kaydedilemedi:
											           |%3'"),
											GetURL(TableRow.Data),
											SingleRecordSet.Metadata().FullName(),
											ErrorProcessing.DetailErrorDescription(ErrorInfo));
									If TransactionActive() Then
										Raise ErrorText;
									EndIf;
									ReportError(ErrorText, ExtensionsObjects);
								EndTry;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				
			ElsIf Metadata.Catalogs.Contains(TableRow.Metadata) Then
				
				If Parameters.Object = Undefined Then
					Parameters.Object = TableRow.Data.GetObject();
				EndIf;
				
				If TableRow.Metadata.Owners.Contains(Ref.Metadata()) And Parameters.Object.Owner = Ref Then
					Parameters.Object.Owner = CorrectItem;
				EndIf;
				
				If TableRow.Metadata.Hierarchical And Parameters.Object.Parent = Ref Then
					Parameters.Object.Parent = CorrectItem;
				EndIf;
				
				For Each Attribute In TableRow.Metadata.Attributes Do
					If Attribute.Type.ContainsType(TypeOf(Ref)) And Parameters.Object[Attribute.Name] = Ref Then
						Parameters.Object[Attribute.Name] = CorrectItem;
					EndIf;
				EndDo;
				
				For Each TS In TableRow.Metadata.TabularSections Do
					For Each Attribute In TS.Attributes Do
						If Attribute.Type.ContainsType(TypeOf(Ref)) Then
							TabSectionRow = Parameters.Object[TS.Name].Find(Ref, Attribute.Name);
							While TabSectionRow <> Undefined Do
								TabSectionRow[Attribute.Name] = CorrectItem;
								TabSectionRow = Parameters.Object[TS.Name].Find(Ref, Attribute.Name);
							EndDo;
						EndIf;
					EndDo;
				EndDo;
				
			ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(TableRow.Metadata)
			      Or Metadata.ChartsOfAccounts.Contains            (TableRow.Metadata)
			      Or Metadata.ChartsOfCalculationTypes.Contains      (TableRow.Metadata)
			      Or Metadata.Tasks.Contains                 (TableRow.Metadata)
			      Or Metadata.BusinessProcesses.Contains         (TableRow.Metadata) Then
				
				If Parameters.Object = Undefined Then
					Parameters.Object = TableRow.Data.GetObject();
				EndIf;
				
				For Each Attribute In TableRow.Metadata.Attributes Do
					If Attribute.Type.ContainsType(TypeOf(Ref)) And Parameters.Object[Attribute.Name] = Ref Then
						Parameters.Object[Attribute.Name] = CorrectItem;
					EndIf;
				EndDo;
				
				For Each TS In TableRow.Metadata.TabularSections Do
					For Each Attribute In TS.Attributes Do
						If Attribute.Type.ContainsType(TypeOf(Ref)) Then
							TabSectionRow = Parameters.Object[TS.Name].Find(Ref, Attribute.Name);
							While TabSectionRow <> Undefined Do
								TabSectionRow[Attribute.Name] = CorrectItem;
								TabSectionRow = Parameters.Object[TS.Name].Find(Ref, Attribute.Name);
							EndDo;
						EndIf;
					EndDo;
				EndDo;
				
			ElsIf Metadata.Constants.Contains(TableRow.Metadata) Then
				
				Common.ObjectManagerByFullName(
					TableRow.Metadata.FullName()).Set(CorrectItem);
				
			ElsIf Metadata.InformationRegisters.Contains(TableRow.Metadata) Then
				
				DimensionStructure = New Structure;
				RegisterManager = Common.ObjectManagerByFullName(TableRow.Metadata.FullName());
				RecordSet = RegisterManager.CreateRecordSet(); // InformationRegisterRecordSet
				For Each Dimension In TableRow.Metadata.Dimensions Do
					RecordSet.Filter[Dimension.Name].Set(TableRow.Data[Dimension.Name]);
					DimensionStructure.Insert(Dimension.Name, TableRow.Data[Dimension.Name]);
				EndDo;
				If TableRow.Metadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
					RecordSet.Filter["Period"].Set(TableRow.Data.Period);
				EndIf;
				RecordSet.Read();
				
				If RecordSet.Count() = 0 Then
					Continue;
				EndIf;
				
				SetTable = RecordSet.Unload();
				RecordSet.Clear();
				
				ErrorText = "";
				BeginTransaction();
				Try
					Try
						If DisableWriteControl Then
							RecordSet.AdditionalProperties.Insert("SkipObjectVersionRecord");
							InfobaseUpdate.WriteData(RecordSet, False);
						Else
							RecordSet.Write();
						EndIf;
					Except
						ErrorInfo = ErrorInfo();
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Chưa xóa bản ghi ""%1"" theo nguyên nhân:
							           |%2';
							           |ru = 'Не удалена запись ""%1"" по причине:
							           |%2';
							           |en = 'Record ""%1"" was not deleted due to:
							           |%2'; fa = 'Record ""%1"" was not deleted due to:
							           |%2';
							           |it = 'Не удалена запись ""%1"" по причине:
							           |%2';
							           |pl = 'Record ""%1"" was not deleted due to:
							           |%2';
							           |tr = '""%1"" kaydı şu nedenle silinmedi:
							           |%2'"),
							GetURL(RegisterManager.CreateRecordKey(DimensionStructure)),
							ErrorProcessing.DetailErrorDescription(ErrorInfo));
						Raise;
					EndTry;
					
					For Each Column In SetTable.Columns Do
						If SetTable[0][Column.Name] = Ref Then
							SetTable[0][Column.Name] = CorrectItem;
							If DimensionStructure.Property(Column.Name) Then
								RecordSet.Filter[Column.Name].Set(CorrectItem);
								DimensionStructure[Column.Name] = CorrectItem;
							EndIf;
						EndIf;
					EndDo;
					
					RecordSet.Load(SetTable);
					
					Try
						If DisableWriteControl Then
							RecordSet.AdditionalProperties.Insert("SkipObjectVersionRecord");
							InfobaseUpdate.WriteData(RecordSet, False);
						Else
							RecordSet.Write();
						EndIf;
					Except
						ErrorInfo = ErrorInfo();
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Không thể thêm bản ghi ""%1"" theo nguyên nhân:
							           |%2';
							           |ru = 'Не удалось добавить запись ""%1"" по причине:
							           |%2';
							           |en = 'Record ""%1"" was not added due to:
							           |%2'; fa = 'Record ""%1"" was not added due to:
							           |%2';
							           |it = 'Не удалось добавить запись ""%1"" по причине:
							           |%2';
							           |pl = 'Record ""%1"" was not added due to:
							           |%2';
							           |tr = '""%1"" kaydı şu nedenle eklenemedi:
							           |%2'"),
							GetURL(RegisterManager.CreateRecordKey(DimensionStructure)),
							ErrorProcessing.DetailErrorDescription(ErrorInfo));
						Raise;
					EndTry;
					
					CommitTransaction();
				Except
					RollbackTransaction();
					HadExceptions = True;
					If Not ValueIsFilled(ErrorText) Then
						Raise;
					EndIf;
					If TransactionActive() Then
						Raise ErrorText;
					EndIf;
					ReportError(ErrorText, ExtensionsObjects);
				EndTry;
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể thay thế giá trị trong dữ liệu kiểu: %1';
						|ru = 'Значения не заменяются в данных типа: %1';
						|en = 'Cannot replace the values in data of the following type: %1.'; fa = 'Cannot replace the values in data of the following type: %1.';
						|it = 'Non si sostituiscono i valori nei dati del tipo: %1';
						|pl = 'Wartości nie są zmieniane w danych typu: %1';
						|tr = 'Değerler şu tip verilerde değiştirilmez: %1'"),
					String(TableRow.Metadata));
					
				ReportError(ErrorText, ExtensionsObjects);
			EndIf;
		EndDo;
	
		If Parameters.Object <> Undefined Then
			Try
				If DisableWriteControl Then
					Parameters.Object.AdditionalProperties.Insert("SkipObjectVersionRecord");
					InfobaseUpdate.WriteData(Parameters.Object, False);
				Else
					Parameters.Object.Write();
				EndIf;
			Except
				HadExceptions = True;
				ErrorInfo = ErrorInfo();
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể ghi lại đối tượng ""%1"" theo nguyên nhân:
					           |%2';
					           |ru = 'Не удалось записать объект ""%1"" по причине:
					           |%2';
					           |en = 'Couldn''t write object ""%1"" due to:
					           |%2'; fa = 'Couldn''t write object ""%1"" due to:
					           |%2';
					           |it = 'Не удалось записать объект ""%1"" по причине:
					           |%2';
					           |pl = 'Couldn''t write object ""%1"" due to:
					           |%2';
					           |tr = '""%1"" nesnesi şu nedenle kaydedilemedi:
					           |%2'"),
					GetURL(Parameters.Object.Ref),
					ErrorProcessing.DetailErrorDescription(ErrorInfo));
				If TransactionActive() Then
					Raise ErrorText;
				EndIf;
				ReportError(ErrorText, ExtensionsObjects);
			EndTry;
		EndIf;
		
	Except
		HadExceptions = True;
		Raise;
	EndTry;
	
	Return Not HadExceptions;
	// ACC:1327-off.
	
EndFunction

// Returns:
//  Structure:
//   * Object - CatalogObject 
//            - Undefined
// 
Function ItemsReplacementParameters()
	
	Parameters = New Structure;
	Parameters.Insert("Object", Undefined);
	Return Parameters;
	
EndFunction


// Procedure from the ValueSearchingAndReplacing universal data processor.
// Changes:
// - the Message(…) method is replaced with the WriteLogEvent(…) method.
//
Procedure ReportError(Val LongDesc, ExtensionsObjects)
	
	WriteLogEvent(
		?(ExtensionsObjects,
			NStr("vi = 'Tên định danh đối tượng phần mở rộng.Thay thế tên định danh';
				|ru = 'Идентификаторы объектов расширений.Замена идентификатора';
				|en = 'Extension object IDs.ID replacement'; fa = 'Extension object IDs.ID replacement';
				|it = 'Identificatori degli oggetti delle estensioni. Sostituzione dell''identificatore';
				|pl = 'Identyfikatory obiektów rozszerzeń.Zamiana identyfikatora';
				|tr = 'Uzantı nesne tanımlayıcıları. Tanımlayıcı değiştirme'",
				Common.DefaultLanguageCode()),
			NStr("vi = 'Tên định danh đối tượng metadata.Thay thế tên định danh';
				|ru = 'Идентификаторы объектов метаданных.Замена идентификатора';
				|en = 'Metadata object IDs.ID replacement'; fa = 'Metadata object IDs.ID replacement';
				|it = 'Identificatori degli oggetti dei metadati. Sostituzione dell''identificatore';
				|pl = 'Identyfikatory obiektów metadanych.Zamiana identyfikatora';
				|tr = 'Metaveri nesne tanımlayıcıları. Tanımlayıcı değiştirme'",
				Common.DefaultLanguageCode())),
		EventLogLevel.Error,
		,
		,
		LongDesc,
		EventLogEntryTransactionMode.Independent);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#EndIf