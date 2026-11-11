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

	StorageName = Parameters.StorageName;

	ExternalBDS = BinaryDataExternalStorages.Find(StorageName);
	If ExternalBDS = Undefined Then
		Cancel = True;
		Return;
	EndIf;

	FillFormAttributes(ExternalBDS);

	Items.WrittenDataMinimumSize.Enabled = AllowRecording;	

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AllowRecordingOnChange(Item)
	
	Items.WrittenDataMinimumSize.Enabled = AllowRecording;	

	If AllowRecording Then     
		WrittenDataMinimumSize = OfWrittenDataMinimumSize(StorageName);
	Else                    
		WrittenDataMinimumSize = 0;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Clear(Command)

	ClearAtServer();

EndProcedure

&AtClient
Procedure OK(Command)

	WriteChangeToStorage();
	Close(True);

EndProcedure

&AtClient
Procedure Cancel(Command)

	Close(False);

EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function OfWrittenDataMinimumSize(Val StorageName)

	ExternalBDS = BinaryDataExternalStorages[StorageName];
	Return ExternalBDS.MinWriteDataSize;

EndFunction

&AtServer
Procedure FillFormAttributes(ExternalBDS)

	Name						= ExternalBDS.Name;
	AccessID	= ExternalBDS.AccessParameters.AccessID;
	SecretKey			= ExternalBDS.AccessParameters.SecretKey; 
	State					= ExternalBDS.AccessParameters.Region;

	AllowRecording = ExternalBDS.ReadWriteMode = BinaryDataStorageReadWriteMode.ReadAndWrite;

	If AllowRecording Then

		WrittenDataMinimumSize = ExternalBDS.MinWriteDataSize ;

	Else

		WrittenDataMinimumSize = 0;

	EndIf;

	If ExternalBDS.LastClearingDate > Date(1, 1, 1) Then
		LastClearingDate = ExternalBDS.LastClearingDate;
	Else
		LastClearingDate = Undefined;
	EndIf;	
	
EndProcedure

&AtServer
Procedure ClearAtServer()

	ExternalBDS = BinaryDataExternalStorages[StorageName];
	ExternalBDS.ClearUnusedSpaceByUniversalDate(ToUniversalTime(ClearDate));
	If ExternalBDS.LastClearingDate > Date(1, 1, 1) Then
		LastClearingDate = ExternalBDS.LastClearingDate;
	Else
		LastClearingDate = Undefined;
	EndIf;

EndProcedure

&AtServer
Procedure WriteChangeToStorage()

	AccessToBDSParameters = Undefined;

	// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
	Execute("AccessToBDSParameters = New BinaryDataExternalStorageAccessParameters()");
	// ACC:487-on

	AccessToBDSParameters.AccessID	= AccessID;
	AccessToBDSParameters.SecretKey			= SecretKey;
	AccessToBDSParameters.State					= State;
	
	ExternalBDS = BinaryDataExternalStorages[StorageName];	
	ExternalBDS.AccessParameters		= AccessToBDSParameters;
	ExternalBDS.Name					= Name;

	If AllowRecording Then
		ExternalBDS.ReadWriteMode = BinaryDataStorageReadWriteMode.ReadAndWrite;
		ExternalBDS.MinWriteDataSize = WrittenDataMinimumSize;
	Else
		ExternalBDS.ReadWriteMode = BinaryDataStorageReadWriteMode.ReadOnly;
	EndIf;
	
	ExternalBDS.Write();

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
