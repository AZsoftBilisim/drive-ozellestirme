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

	If Not Parameters.OpenByScenario Then
		Raise NStr("ru = 'Форма не предназначена для непосредственного использования.';
					|vi = 'The form cannot be opened manually.';
					|en = 'The form cannot be opened manually.'; fa = 'The form cannot be opened manually.';
					|it = 'Il modello non è destinato per l''uso diretto.';
					|pl = 'Formularz nie jest przeznaczony dla bezpośredniego użycia.';
					|tr = 'Form doğrudan kullanım için uygun değildir.'");
	EndIf;	
	
	If Not BinaryDataEmbeddedStorageAvailability() Then
		Items.StoreType.ChoiceList.Add(0, NStr("ru = 'Встроенное хранилище';
												|vi = 'Internal storage';
												|en = 'Internal storage'; fa = 'ذخیره‌ساز داخلی';
												|it = 'Internal storage';
												|pl = 'Internal storage';
												|tr = 'Dahili depo'", Common.DefaultLanguageCode()));
		StoreType = 0;
	Else
		StoreType = 1;
	EndIf;
	Items.StoreType.ChoiceList.Add(1, NStr("ru = 'Внешнее хранилище по протоколу S3';
											|vi = 'S3 external storage';
											|en = 'S3 external storage'; fa = 'ذخیره‌ساز خارجی S3';
											|it = 'S3 external storage';
											|pl = 'S3 external storage';
											|tr = 'S3 protokolü üzerinden harici depo'", Common.DefaultLanguageCode()));
	Items.StoreType.ChoiceList.Add(2, NStr("ru = 'Внешнее хранилище по протоколу S3 (виртуальный хост)';
											|vi = 'S3 external storage (virtual host)';
											|en = 'S3 external storage (virtual host)'; fa = 'S3 external storage (virtual host)';
											|it = 'S3 external storage (virtual host)';
											|pl = 'S3 external storage (virtual host)';
											|tr = 'S3 protokolü üzerinden harici depo (sanal ana makine)'", Common.DefaultLanguageCode()));

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	UpdateForm();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StoreTypeOnChange(Item)
    UpdateForm();
EndProcedure

&AtClient
Procedure StorageNameOnChange(Item)
	UpdateForm();
EndProcedure

&AtClient
Procedure ConnectionAddressOnChange(Item)
	UpdateForm();
EndProcedure

&AtClient
Procedure AccessIDOnChange(Item)
	UpdateForm();
EndProcedure

&AtClient
Procedure SecretKeyOnChange(Item)
	UpdateForm();
EndProcedure

&AtClient
Procedure StateOnChange(Item)
	UpdateForm();
EndProcedure

&AtClient
Procedure AllowRecordingOnChange(Item)

	Items.WrittenDataMinimumSize.Enabled = AllowRecording;	

	If AllowRecording Then
		WrittenDataMinimumSize = 2048;
	Else                    
		WrittenDataMinimumSize = 0;
	EndIf;	
	
EndProcedure

&AtClient
Procedure WrittenDataMinimumSizeOnChange(Item)
	UpdateForm();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)

    AddStorage();
	Close(True);

EndProcedure

&AtClient
Procedure Cancel(Command)

	Close(False);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddStorage()

	// Internal storage
	If StoreType = 0 Then

		BinaryDataStorage.SetBinaryDataStorageUseMode(BinaryDataStorageUseMode.Enable);

		If AllowRecording Then
			BinaryDataStorage.SetBinaryDataStorageReadWriteMode(BinaryDataStorageReadWriteMode.ReadAndWrite);
		Else 
			BinaryDataStorage.SetBinaryDataStorageReadWriteMode(BinaryDataStorageReadWriteMode.ReadOnly);
		EndIf;		

		Return;
	EndIf;

	// External storage
	// Connection parameters
	ConnectionParameters = New BinaryDataExternalStorageConnectionParameters();
	ConnectionParameters.URL = ConnectionAddress;
	
	// ACC:216-off - Enumeration member contains Latin and Cyrillic letters.
	If StoreType = 1 Then                                      
		ConnectionParameters.URLType = BinaryDataExternalStorageURLType.S3HostWithBucketInPath ;
	ElsIf StoreType = 2 Then
		ConnectionParameters.URLType = BinaryDataExternalStorageURLType.S3VirtualHost;
	EndIf;
	// ACC:216-on

	// Access parameters
	AccessToBDSParameters = Undefined;

	// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
	Execute("AccessToBDSParameters = New BinaryDataExternalStorageAccessParameters()");
	// ACC:487-on	

	AccessToBDSParameters.AccessID	= AccessID;
	AccessToBDSParameters.SecretKey			= SecretKey;
	AccessToBDSParameters.State					= State;

	ExternalBDS = BinaryDataExternalStorages.Add(StorageName, ConnectionParameters, AccessToBDSParameters);
	
	If AllowRecording Then
		ExternalBDS.ReadWriteMode = BinaryDataStorageReadWriteMode.ReadAndWrite;
		ExternalBDS.MinWriteDataSize = WrittenDataMinimumSize;
		
		ExternalBDS.Write();
	EndIf;

EndProcedure

&AtServer
Function BinaryDataEmbeddedStorageAvailability()

	UsageMode = BinaryDataStorage.GetBinaryDataStorageUseMode();
	Result = UsageMode = BinaryDataStorageUseMode.Enable;

	Return Result;

EndFunction

&AtClient
Procedure UpdateForm()

	IsExternalBDS = StoreType <> 0;

	Items.StorageName			.Enabled = IsExternalBDS;
	Items.ConnectionAddress		.Enabled = IsExternalBDS;
	Items.AccessID	.Enabled = IsExternalBDS;
	Items.SecretKey			.Enabled = IsExternalBDS;
	Items.State					.Enabled = IsExternalBDS;	

	ButtonOKAvailability = True;

	If IsExternalBDS Then
		If StorageName = "" Or ConnectionAddress = "" Or AccessID = "" Or SecretKey = "" Or State = "" Then
			ButtonOKAvailability = False;
		EndIf;	
	EndIf;

	If AllowRecording And ButtonOKAvailability Then
		ButtonOKAvailability = WrittenDataMinimumSize >= 2048;
	EndIf;

	Items.OKButton.Enabled = ButtonOKAvailability;

EndProcedure

#EndRegion