///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	CheckDataProcessorAvailability();
	
	RefreshPresentation();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure BinaryDataStoragesSelection(Item, RowSelected, Field, StandardProcessing)
	EditStorage(Item);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddStorage(Command)

	Notification = New CallbackDescription("OnAddStorage", ThisObject);

	FormOpenParameters = New Structure("OpenByScenario", True);

	OpenForm(FormNameToOpen("AddStorage", FormName), FormOpenParameters, , , , , Notification, FormWindowOpeningMode.LockWholeInterface);

EndProcedure

&AtClient
Procedure EditStorage(Command)

	TheCurrentDataRow = Items.BinaryDataStorages.CurrentData;
	If TheCurrentDataRow <> Undefined Then
		Notification = New CallbackDescription("OnEditStorage", ThisObject);
		
		FormOpenParameters = New Structure("OpenByScenario", True);
		
		If TheCurrentDataRow.StorageAddress = "" Then
			OpenForm(FormNameToOpen("InternalStorage", FormName), FormOpenParameters, , , , , Notification, FormWindowOpeningMode .LockWholeInterface);
		Else
			FormOpenParameters.Insert("StorageName", TheCurrentDataRow.StorageName);

			OpenForm(FormNameToOpen("ExternalStorage", FormName), FormOpenParameters, , , , , Notification, FormWindowOpeningMode .LockWholeInterface);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure DeleteStorage(Command)

	TheCurrentDataRow = Items.BinaryDataStorages.CurrentData;
	If TheCurrentDataRow <> Undefined Then
		
		Notification = New CallbackDescription("DeleteBinaryDataStorage", ThisObject);
		
		QueryText = NStr("ru = 'Удалить хранилище двоичных данных?';
						|vi = 'Delete binary data storage?';
						|en = 'Delete binary data storage?'; fa = 'Delete binary data storage?';
						|it = 'Delete binary data storage?';
						|pl = 'Delete binary data storage?';
						|tr = 'İkili veri deposu silinsin mi?'");
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo,,DialogReturnCode.No);
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtClient
Function FormNameToOpen(Var_FormName, FullFormName)

	Path = Left(FullFormName,StrFind(FullFormName, ".", SearchDirection.FromEnd));
	Return Path + "." + Var_FormName;

EndFunction

&AtClient
Procedure OnAddStorage(Result, AdditionalParameters) Export
	RefreshPresentation();
EndProcedure

&AtClient
Procedure OnEditStorage(Result, AdditionalParameters) Export
	RefreshPresentation();
EndProcedure

&AtServer
Procedure AddStorageToTable(StorageName, StorageAddress, BDSRecordReadMode, DefaultStorage, DataMinimumSize, StorageClearingDate)

	HDDString = BinaryDataStorages.Add();
	HDDString.StorageName = StorageName;	
	HDDString.StorageAddress = StorageAddress;

	If BDSRecordReadMode = BinaryDataStorageReadWriteMode.ReadOnly Then
 		HDDString.UsageMode = NStr("ru = 'Только чтение';
									|vi = 'Read only';
									|en = 'Read only'; fa = 'فقط خواندنی';
									|it = 'Solo lettura';
									|pl = 'Tylko odczyt';
									|tr = 'Sadece okuma'", Common.DefaultLanguageCode());
		HDDString.DataMinimumSize = "";
	Else 
		HDDString.UsageMode = NStr("ru = 'Чтение и запись';
									|vi = 'Read and write';
									|en = 'Read and write'; fa = 'Read and write';
									|it = 'Read and write';
									|pl = 'Read and write';
									|tr = 'Okuma ve yazma'", Common.DefaultLanguageCode());
		HDDString.DataMinimumSize = DataMinimumSize;
	EndIf;

	HDDString.DefaultStorage = ?(DefaultStorage, 0, 1);	
	
	If HDDString.StorageClearingDate <> Undefined Then
		HDDString.StorageClearingDate = StorageClearingDate;
	EndIf;

EndProcedure

&AtServer
Procedure RefreshPresentation()

	BinaryDataStorages.Clear();
	
	// Internal storage
	UsageMode = BinaryDataStorage.GetBinaryDataStorageUseMode();
	If UsageMode = BinaryDataStorageUseMode.Enable Then
		StorageName = NStr("ru = 'Встроенное хранилище';
							|vi = 'Internal storage';
							|en = 'Internal storage'; fa = 'ذخیره‌ساز داخلی';
							|it = 'Internal storage';
							|pl = 'Internal storage';
							|tr = 'Dahili depo'", Common.DefaultLanguageCode());
		StorageAddress = "";
		BDSRecordReadMode = False;
		DataMinimumSize = 2048;
		DefaultStorage = False;
		StorageClearingDate = Undefined;

		Try
			BDSRecordReadMode = BinaryDataStorage.GetBinaryDataStorageReadWriteMode();
			DataMinimumSize = BinaryDataStorage.GetMinWriteDataSize();

			DefaultStorage = (BDSRecordReadMode <> BinaryDataStorageReadWriteMode.ReadOnly);
			If DefaultStorage Then
				// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
				Execute("DefaultStorage = BinaryDataStorage.GetUsingAsDefaultStorage()");
				// ACC:487-on				
			EndIf; 
			
			StorageInformation = BinaryDataStorage.GetInformation();
			If StorageInformation.LastClearingDate > Date(1, 1, 1) Then
				StorageClearingDate = StorageInformation.LastClearingDate;
			EndIf;
		Except
			WriteLogEvent(NStr("ru = 'Управление хранилищем двоичных данных';
								|vi = 'Manage binary data storage';
								|en = 'Manage binary data storage'; fa = 'مدیریت ذخیره‌سازی داده‌های باینری';
								|it = 'Manage binary data storage';
								|pl = 'Manage binary data storage';
								|tr = 'İkili veri deposu yönetimi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			NStr("ru = 'Ошибка получения параметров встроенного хранилища';
				|vi = 'Error getting internal storage parameters';
				|en = 'Error getting internal storage parameters'; fa = 'Error getting internal storage parameters';
				|it = 'Error getting internal storage parameters';
				|pl = 'Error getting internal storage parameters';
				|tr = 'Dahili depo parametreleri alınırken hata oluştu'", Common.DefaultLanguageCode()));
		EndTry;
		
    	AddStorageToTable(StorageName, StorageAddress, BDSRecordReadMode, DefaultStorage, DataMinimumSize, StorageClearingDate);

	EndIf; 
	
	// External storages
	For Each StorageManager In BinaryDataExternalStorages Do

		StorageName			= "";
		StorageAddress			= "";
		BDSRecordReadMode	= False;
		DataMinimumSize = 2048;
		DefaultStorage	= False;
		StorageClearingDate	= Undefined;

		Try
			StorageName			= StorageManager.Name;
			BDSRecordReadMode	= StorageManager.ReadWriteMode;
			DataMinimumSize = StorageManager.MinWriteDataSize ;
			DefaultStorage	= (BDSRecordReadMode <> BinaryDataStorageReadWriteMode.ReadOnly) And StorageManager.DefaultStorage;

			If StorageManager.LastClearingDate > Date(1,1,1) Then
				StorageClearingDate = StorageManager.LastClearingDate;
			EndIf;			

			StorageAddress	= StorageManager.ConnectionParameters.URL;

		Except
			WriteLogEvent(NStr("ru = 'Управление хранилищем двоичных данных';
								|vi = 'Manage binary data storage';
								|en = 'Manage binary data storage'; fa = 'مدیریت ذخیره‌سازی داده‌های باینری';
								|it = 'Manage binary data storage';
								|pl = 'Manage binary data storage';
								|tr = 'İkili veri deposu yönetimi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			NStr("ru = 'Ошибка получения параметров внешнего хранилища';
				|vi = 'Error getting external storage parameters';
				|en = 'Error getting external storage parameters'; fa = 'Error getting external storage parameters';
				|it = 'Error getting external storage parameters';
				|pl = 'Error getting external storage parameters';
				|tr = 'Harici depo parametreleri alınırken hata oluştu'", Common.DefaultLanguageCode()));
		EndTry;
			
    	AddStorageToTable(StorageName, StorageAddress, BDSRecordReadMode, DefaultStorage, DataMinimumSize, StorageClearingDate);

	EndDo;	                 

	EditCommandsAvailability = BinaryDataStorages.Count() > 0;

	Items.EditStorage.Enabled = EditCommandsAvailability;
	Items.DeleteStorage.Enabled		= EditCommandsAvailability;

EndProcedure

&AtClient
Procedure DeleteBinaryDataStorage(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;	
	
	TheCurrentDataRow = Items.BinaryDataStorages.CurrentData;
	
	If TheCurrentDataRow = Undefined Then
		Return;
	EndIf;
	
	DeleteStorageAtServer(TheCurrentDataRow.StorageAddress, TheCurrentDataRow.StorageName);
	
EndProcedure

&AtServer
Procedure DeleteStorageAtServer(Val StorageAddress, Val StorageName)
	
	If StorageAddress = "" Then 
		BinaryDataStorage.SetBinaryDataStorageUseMode(BinaryDataStorageUseMode.Disable);
	Else
		StorageManager = BinaryDataExternalStorages[StorageName];
		BinaryDataExternalStorages.Delete(StorageManager);
	EndIf;
	
	RefreshPresentation();
	
EndProcedure

&AtServer
Procedure CheckDataProcessorAvailability()

	ExceptionText = "";

	If Common.FileInfobase() Then
		ExceptionText = NStr("ru = 'Обработка не предназначена для использования в файловой информационной базе.';
							|vi = 'The data processor doesn''t support file infobases.';
							|en = 'The data processor doesn''t support file infobases.'; fa = 'The data processor doesn''t support file infobases.';
							|it = 'The data processor doesn''t support file infobases.';
							|pl = 'The data processor doesn''t support file infobases.';
							|tr = 'İşlem, dosya tabanlı bilgi tabanında kullanılmak üzere tasarlanmamıştır.'");
	ElsIf Not FileArchiveManagementServer.AreChangesInFilesStorageMethodsAvailable() Then
		ExceptionText = NStr("ru = 'Обработка не предназначена для использования на версиях платформы 1С:Предприятие ниже 8.3.26.';
							|vi = 'The data processor supports 1C:Enterprise v.8.3.26 and later.';
							|en = 'The data processor supports 1C:Enterprise v.8.3.26 and later.'; fa = 'The data processor supports 1C:Enterprise v.8.3.26 and later.';
							|it = 'The data processor supports 1C:Enterprise v.8.3.26 and later.';
							|pl = 'The data processor supports 1C:Enterprise v.8.3.26 and later.';
							|tr = 'İşlem, 8.3.26 altındaki 1C:Enterprise platform sürümlerinde kullanılmak üzere tasarlanmamıştır.'");
	ElsIf Common.DataSeparationEnabled() Then
		IBUser = InfoBaseUsers.CurrentUser();
		If IBUser.DataSeparation.Count() <> 0 Then
			ExceptionText = NStr("ru = 'Обработка не предназначена для использования в разделенном сеансе.';
								|vi = 'The data processor doesn''t support separated sessions.';
								|en = 'The data processor doesn''t support separated sessions.'; fa = 'The data processor doesn''t support separated sessions.';
								|it = 'The data processor doesn''t support separated sessions.';
								|pl = 'The data processor doesn''t support separated sessions.';
								|tr = 'İşlem, ayrılmış oturumda kullanılmak üzere tasarlanmamıştır.'");
		EndIf;
	EndIf;

	If ExceptionText <> "" Then
		Raise ExceptionText;
	EndIf;
		
EndProcedure

#EndRegion