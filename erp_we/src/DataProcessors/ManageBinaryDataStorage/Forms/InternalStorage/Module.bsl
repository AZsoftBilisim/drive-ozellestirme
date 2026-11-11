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
	
	UpdateSettings2();

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)

	If CurrentPage.Name = "SettingsPage" Then
		UpdateSettings2();
	ElsIf CurrentPage.Name = "PageStorageInformation" Then
		RefreshInformationAtServer();
	EndIf;

EndProcedure

&AtClient
Procedure AllowRecordingOnChange(Item)

	Items.WrittenDataMinimumSize.Enabled = AllowRecording;	

	If AllowRecording Then

		WrittenDataMinimumSize = WrittenDataAtServerMinimumSize();

		OKButtonAvailability();
	Else

		WrittenDataMinimumSize = 0;
	EndIf;

EndProcedure

&AtClient
Procedure WrittenDataMinimumSizeOnChange(Item)

	OKButtonAvailability();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateInformation2(Command)

    RefreshInformationAtServer();

EndProcedure

&AtClient
Procedure ClearStorage(Command)

	If ClearDate = Date(1, 1, 1) Then
		Raise NStr("ru = 'Для запуска очистки хранилища двоичных данных нужно задать непустую дату очистки';
					|vi = 'Cleanup date is required';
					|en = 'Cleanup date is required'; fa = 'Cleanup date is required';
					|it = 'Cleanup date is required';
					|pl = 'Cleanup date is required';
					|tr = 'İkili veri deposu temizliğini başlatmak için boş olmayan bir temizleme tarihi belirtilmelidir'");	
	EndIf;

	Status(NStr("ru = 'Подождите';
				|vi = 'Wait please';
				|en = 'Wait please'; fa = 'Wait please';
				|it = 'Wait please';
				|pl = 'Wait please';
				|tr = 'Lütfen bekleyin'"), , StringFunctionsClientServer.SubstituteParametersToString(
											NStr("ru = 'Идет очистка на дату %1 ...';
												|vi = 'Cleaning up data through %1…';
												|en = 'Cleaning up data through %1…'; fa = 'Cleaning up data through %1…';
												|it = 'Cleaning up data through %1…';
												|pl = 'Cleaning up data through %1…';
												|tr = '%1 tarihine göre temizlik yapılıyor...'"), ClearDate));

	ClearStorageByClearingData(ClearDate); 

	Status("", , NStr("ru = 'Очистка завершена';
						|vi = 'Сleanup completed';
						|en = 'Сleanup completed'; fa = 'Сleanup completed';
						|it = 'Сleanup completed';
						|pl = 'Сleanup completed';
						|tr = 'Temizlik tamamlandı'"));

EndProcedure

&AtClient
Procedure OK(Command)

	Try

		ChangeStorageSettingsAtServer();

	Except
		UpdateSettings2();
		Raise;
	EndTry;

	Close(True);

EndProcedure

&AtClient
Procedure Cancel(Command)

	Close(False);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OKButtonAvailability()

	IsOKButtonAvailable = WrittenDataMinimumSize >= 2048;

	Items.OKButton.Enabled = IsOKButtonAvailable;

EndProcedure

&AtServer                 
Procedure UpdateSettings2()

	WrittenDataMinimumSize	= BinaryDataStorage.GetMinWriteDataSize();
	
	ReadWriteMode = BinaryDataStorage.GetBinaryDataStorageReadWriteMode();
	AreReadAndWriteAvailable = ReadWriteMode = BinaryDataStorageReadWriteMode.ReadAndWrite;

	If AreReadAndWriteAvailable Then 

		AllowRecording = True;

	Else
		AllowRecording			= False;		
	EndIf;

	Items.WrittenDataMinimumSize.Enabled = AreReadAndWriteAvailable;	

EndProcedure

&AtServer
Procedure RefreshInformationAtServer()

	StorageInformation = BinaryDataStorage.GetInformation();

	StoredDataSize						= StorageInformation.StoredDataSize;
	DeletedDataSize					= StorageInformation.DeletedDataSize;
    StoredItemsCount				= StorageInformation.StoredItemsCount;
	DeletedItemsCount			= StorageInformation.DeletedItemsCount;
	StoredDataSizeOnDisk				= StorageInformation.StoredDataSizeOnDisk;
	DeduplicatedItemsCount	= StorageInformation.DeduplicatedItemsCount;
	LastClearingDate					= ToLocalTime(StorageInformation.LastClearingDate);
	
EndProcedure

&AtServerNoContext
Procedure ClearStorageByClearingData(Val ClearDate)

	BinaryDataStorage.ClearUnusedSpaceByUniversalDate(ToUniversalTime(ClearDate));

EndProcedure

&AtServerNoContext
Function WrittenDataAtServerMinimumSize()

	Return BinaryDataStorage.GetMinWriteDataSize();

EndFunction

&AtServer
Procedure ChangeStorageSettingsAtServer()

	If AllowRecording Then
		BinaryDataStorage.SetBinaryDataStorageReadWriteMode(BinaryDataStorageReadWriteMode.ReadAndWrite);
	Else 
		BinaryDataStorage.SetBinaryDataStorageReadWriteMode(BinaryDataStorageReadWriteMode.ReadOnly);
	EndIf;

	BinaryDataStorage.SetMinWriteDataSize(WrittenDataMinimumSize);

EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
