///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Deletes unused common add-ins.
//
Procedure RemoveUnusedAddIns() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.RemoveUnusedAddIns);
	If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
			"SELECT
			|	CommonAddIns.Ref AS Ref
			|FROM
			|	Catalog.CommonAddIns AS CommonAddIns
			|WHERE
			|	NOT CommonAddIns.DeletionMark
			|	AND NOT CommonAddIns.Id IN (&IDs)";
		
	Query.SetParameter("IDs", AddInsInternal.SuppliedAddIns());
		
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Catalog.CommonAddIns");
			LockItem.SetValue("Ref", Selection.Ref);
			Block.Lock();

			Object = Selection.Ref.GetObject();
			Object.DeletionMark = True;
			Object.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteLogEvent(NStr("vi = 'Các cấu phần bên ngoài được cung cấp. Loại bỏ các cấu phần không sử dụng';
								|ru = 'Поставляемые внешние компоненты.Удаление неиспользуемой компоненты';
								|en = 'Built-in add-ins.Delete unused add-in'; fa = 'Built-in add-ins.Delete unused add-in';
								|it = 'Поставляемые внешние компоненты.Удаление неиспользуемой компоненты';
								|pl = 'Built-in add-ins.Delete unused add-in';
								|tr = 'Sağlanan harici bileşenler. Kullanılmayan bileşenin silinmesi'",
				Common.DefaultLanguageCode()),
				EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(
				ErrorInfo()));
			Raise;
		EndTry;
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Parameters:
//  ComponentDetails - See AddInsServer.SuppliedSharedAddInDetails.
//
Procedure UpdateSharedAddIn(ComponentDetails) Export
	
	If Not Common.DataSeparationEnabled() Or Common.SeparatedDataUsageAvailable() Then 
		Raise(NStr("vi = 'Kết nhập cấu phần ngoài không khả dụng.';
					|ru = 'Загрузка общих внешних компонент недоступна.';
					|en = 'Import of add-ins is unavailable.'; fa = 'Import of add-ins is unavailable.';
					|it = 'Import of add-ins is unavailable.';
					|pl = 'Import of add-ins is unavailable.';
					|tr = 'Ortak harici eklentiler yüklenemiyor.'"), 
			ErrorCategory.AccessViolation);
	EndIf;
	
	SetPrivilegedMode(True);
	
	WriteLogEvent(NStr("vi = 'Cấu phần ngoài sẵn có.Kết nhập cấu phần sẵn có';
						|ru = 'Поставляемые внешние компоненты.Загрузка поставляемой компоненты';
						|en = 'Built-in add-ins.Import built-in add-in'; fa = 'Built-in add-ins.Import built-in add-in';
						|it = 'Componenti esterni forniti. Download dei componenti forniti.';
						|pl = 'Dostarczane komponenty zewnętrzne. Pobierane dostarczanego komponentu';
						|tr = 'Yerleşik add-in''ler.Yerleşik add-in içe aktar'", 
		Common.DefaultLanguageCode()),
		EventLogLevel.Information,,,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã khởi tạo kết nhập bộ xử lý được cung cấp
			           |%1';
			           |ru = 'Инициирована загрузка поставляемой обработки
			           |%1';
			           |en = 'Built-in data processor import is initiated
			           |%1'; fa = 'Built-in data processor import is initiated
			           |%1';
			           |it = 'Download dell''elaborazione fornita avviato 
			           |%1';
			           |pl = 'Inicjowane pobieranie dostarczenego przetwarzania 
			           |%1';
			           |tr = 'Sağlanan veri işlemcisinin kurulumu başlatıldı
			           |%1'"),
		AddInsInternal.AddInPresentation(ComponentDetails.Id, 
			ComponentDetails.Version)));
	
	BeginTransaction();
	Try
		Ref = Catalogs.CommonAddIns.FindByID(ComponentDetails.Id, 
			ComponentDetails.Version);
		
		If Ref.IsEmpty() Then
			SharedAddIn = Catalogs.CommonAddIns.CreateItem();
		Else
			Block = New DataLock;
			LockItem = Block.Add("Catalog.CommonAddIns");
			LockItem.SetValue("Ref", Ref);
			Block.Lock();
			
			SharedAddIn = Ref.GetObject();
			SharedAddIn.Lock();
			SharedAddIn.DeletionMark = False;
		EndIf;
		
		SharedAddIn.Fill(Undefined);
		
		ComponentBinaryData = New BinaryData(ComponentDetails.PathToFile);
		Information = AddInsInternal.InformationOnAddInFromFile(ComponentBinaryData, False);
		
		If Not Information.Disassembled Then 
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể phân tích cấu phần được cung cấp
				           |theo nguyên nhân:
				           |%1 %2';
				           |ru = 'Поставляемую компоненту не удалось разобрать
				           |по причине:
				           |%1 %2';
				           |en = 'Cannot parse the built-in add-in
				           |due to:
				           |%1 %2'; fa = 'Cannot parse the built-in add-in
				           |due to:
				           |%1 %2';
				           |it = 'Поставляемую компоненту не удалось разобрать
				           |по причине:
				           |%1 %2';
				           |pl = 'Cannot parse the built-in add-in
				           |due to:
				           |%1 %2';
				           |tr = 'Sağlanan bileşenin ayrıştırılamama
				           |nedeni:
				           |%1 %2'"),
				Information.ErrorDescription, 
				?(Information.ErrorInfo = Undefined, "", 
					": " + ErrorProcessing.BriefErrorDescription(Information.ErrorInfo)));
		EndIf;
		
		FillPropertyValues(SharedAddIn, Information.Attributes); // By manifest data.
		FillPropertyValues(SharedAddIn, ComponentDetails);   // By data from the website.
		
		SharedAddIn.TargetPlatforms = New ValueStorage(Information.Attributes.TargetPlatforms);
		SharedAddIn.AddInStorage = New ValueStorage(ComponentBinaryData);
		
		SharedAddIn.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(
			NStr("vi = 'Cấu phần ngoài sẵn có.Kết nhập cấu phần sẵn có';
				|ru = 'Поставляемые внешние компоненты.Загрузка поставляемой компоненты';
				|en = 'Built-in add-ins.Import built-in add-in'; fa = 'Built-in add-ins.Import built-in add-in';
				|it = 'Componenti esterni forniti. Download dei componenti forniti.';
				|pl = 'Dostarczane komponenty zewnętrzne. Pobierane dostarczanego komponentu';
				|tr = 'Yerleşik add-in''ler.Yerleşik add-in içe aktar'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

Function IsComponentFromStorage(Location) Export
	
	Return StrStartsWith(Location, "e1cib/data/Catalog.CommonAddIns.AddInStorage");
	
EndFunction

// Parameters:
//   Result     - See AddInsInternal.SavedAddInInformation
//   Id - String - ID of the add-in object.
//   Version – String - Add-in version.
// 
Procedure FillAddInInformation(Result, Version, Id) Export
	
	ReferenceFromSharedStorage = Catalogs.CommonAddIns.FindByID(Id, Version);
	ReferenceFromStorage = Catalogs.AddIns.FindByID(Id, Version);
		
	If ReferenceFromStorage.IsEmpty() Then
		If ReferenceFromSharedStorage.IsEmpty() Then
			Result.State = "NotFound1";
		Else
			Result.State = "FoundInSharedStorage";
			Result.Ref = ReferenceFromSharedStorage;
		EndIf;
		Return;
	EndIf;

	If ReferenceFromSharedStorage.IsEmpty() Then
		Result.State = "FoundInStorage";
		Result.Ref = ReferenceFromStorage;
		Return;
	EndIf;

	If ValueIsFilled(Version) Then
		// The same version of an add-in is present in both the common storage and data area storage.
		// The add-in in the data area has a higher priority.
		Result.State = "FoundInStorage";
		Result.Ref = ReferenceFromStorage;
		Return;
	EndIf;

	StorageVersion = Common.ObjectAttributeValue(ReferenceFromStorage, "VersionDate");
	SharedStorageVersion = Common.ObjectAttributeValue(ReferenceFromSharedStorage, "VersionDate");
	If SharedStorageVersion > StorageVersion Then
		Result.State = "FoundInSharedStorage";
		Result.Ref = ReferenceFromSharedStorage;
	Else
		// The add-in is present in both the common storage and area storage.
		// The add-in in the area has a higher priority.
		Result.State = "FoundInStorage";
		Result.Ref = ReferenceFromStorage;
	EndIf;

EndProcedure

Function SharedAddInVersions() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CommonAddIns.Ref AS Ref,
	|	CommonAddIns.DataVersion AS DataVersion
	|FROM
	|	Catalog.CommonAddIns AS CommonAddIns";
	
	Return Query.Execute().Select();

EndFunction


#Region ConfigurationSubsystemsEventHandlers

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	
	Objects.Insert(Metadata.Catalogs.CommonAddIns.FullName(), "AttributesToEditInBatchProcessing");
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	ModuleExportImportData = Common.CommonModule("ExportImportData");
	ModuleExportImportData.AddTypeExcludedFromUploadingUploads(Types,
		Metadata.Catalogs.CommonAddIns,
		ModuleExportImportData.ActionWithClearLinks());
	
EndProcedure

// See StandardSubsystemsServer.
Procedure OnSendDataToMaster(DataElement, ItemSend, Recipient) Export
	
	If TypeOf(DataElement) = Type("CatalogObject.CommonAddIns") Then
		ItemSend = DataItemSend.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave.
Procedure OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient) Export
	
	If TypeOf(DataElement) = Type("CatalogObject.CommonAddIns") Then
		ItemSend = DataItemSend.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromMaster.
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender) Export
	
	If TypeOf(DataElement) = Type("CatalogObject.CommonAddIns") Then
		ItemReceive = DataItemReceive.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromSlave.
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender) Export
	
	If TypeOf(DataElement) = Type("CatalogObject.CommonAddIns") Then
		ItemReceive = DataItemReceive.Ignore;
	EndIf;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.9.221";
	Handler.SharedData = True;
	Handler.Id = New UUID("a76bc949-68aa-4ba3-b9f3-a03b530da817");
	Handler.Procedure = "Catalogs.CommonAddIns.HandleCommonAddIns";
	Handler.Comment = NStr("vi = 'Điền mục tin tương thích của cấu phần chung.';
							|ru = 'Заполнение реквизитов совместимости общих компонент.';
							|en = 'Fill in compatibility attributes of common add-ins.'; fa = 'Fill in compatibility attributes of common add-ins.';
							|it = 'Заполнение реквизитов совместимости общих компонент.';
							|pl = 'Fill in compatibility attributes of common add-ins.';
							|tr = 'Ortak bileşenlerin uyumluluk özniteliklerinin doldurulması.'");
	Handler.ExecutionMode = "Seamless";
	
EndProcedure

#EndRegion

#EndRegion


