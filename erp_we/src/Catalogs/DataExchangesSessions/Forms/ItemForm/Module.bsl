///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormCommandsEventHandlers

&AtClient
Procedure PerformanceMeasurements(Command)
	
	FileAddress = GetFileAddressOnServer();
	Title = NStr("vi = 'Lưu lại tệp';
				|ru = 'Сохранение файла';
				|en = 'Save file'; fa = 'ذخیره فایل';
				|it = 'Salvataggio del file';
				|pl = 'Zapisywanie pliku';
				|tr = 'Dosyaların kaydedilmesi'");
		
	FileName = NStr("vi = 'Đo lường hiệu suất.zip';
					|ru = 'Замеры производительности.zip';
					|en = 'Samples.zip'; fa = 'Samples.zip';
					|it = 'Замеры производительности.zip';
					|pl = 'Samples.zip';
					|tr = 'Performans ölçütü.zip'", CommonClient.DefaultLanguageCode());
		
	DialogParameters = New GetFilesDialogParameters(Title, True);
	BeginGetFileFromServer(FileAddress, FileName, DialogParameters);

EndProcedure

&AtServer
Function GetFileAddressOnServer()
	
	BinaryData = FormAttributeToValue("Object").PerformanceMeasurements.Get();	
	Address = PutToTempStorage(BinaryData);
	
	Return Address;
	
EndFunction

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
