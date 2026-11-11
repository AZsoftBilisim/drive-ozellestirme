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
	
	ReadOnly = True;
	
	FieldsCompositionDetails = FieldsCompositionDetails(Object.FieldsComposition);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
	ShowMessageBox(,
		NStr("vi = 'Không nên thay đổi khóa truy cập vì nó được ánh xạ tới các đối tượng khác nhau.
		           |Để khắc phục sự cố không chuẩn, hãy xóa khóa truy cập hoặc
		           | liên kết đăng ký tới nó và thực hiện quy trình cập nhật quyền truy cập.';
		           |ru = 'Ключ доступа не следует изменять, так как он сопоставлен с разными объектами.
		           |Чтобы исправить нестандартную проблему следует удалить ключ доступа или
		           |связь с ним в регистрах и выполнить процедуру обновления доступа.';
		           |en = 'It is recommended that you do not change the access key as it is mapped to different objects.
		           |To resolve the issue, delete the access key or
		           |delete the mapping between the key and the objects from the registers, and then run the access update.'; fa = 'It is recommended that you do not change the access key as it is mapped to different objects.
		           |To resolve the issue, delete the access key or
		           |delete the mapping between the key and the objects from the registers, and then run the access update.';
		           |it = 'Non bisogna modificare il codice d''accesso poiché esso è associato a oggetti multipli.
		           | Per risolvere un problema non standardizzato bisogna cancellare il codice d''accesso oppure
		           |il collegamento ad esso nei registri e effettuare la procedura di aggiornamento degli accessi.';
		           |pl = 'Klucz dostępu nie należy zmieniać, ponieważ on jest zestawiony z różnymi obiektami.
		           |Aby poprawić nietypowy problem należy usunąć klucz dostępu lub 
		           |związek z nim w rejestrach i wykonać procedurę aktualizacji dostępu.';
		           |tr = 'Farklı nesnelerle eşleştirildiğinden erişim anahtarı değiştirilmemelidir.
		           |Standart olmayan bir sorunu gidermek için, erişim anahtarını veya 
		           |kayıtlarda onunla bağlantıyı kaldırmanız ve erişim güncelleme işlemini gerçekleştirmeniz gerekir.'"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FieldsCompositionDetails(FieldsComposition)
	
	CurrentCount1 = FieldsComposition;
	Details = "";
	
	TabularSectionNumber = 0;
	While CurrentCount1 > 0 Do
		Balance = CurrentCount1 - Int(CurrentCount1 / 16) * 16;
		If TabularSectionNumber = 0 Then
			Details = NStr("vi = 'Phần đầu';
							|ru = 'Шапка';
							|en = 'Header'; fa = 'سرصفحه';
							|it = 'Testata';
							|pl = 'Nagłówek';
							|tr = 'Üst bilgi'") + ": " + Balance;
		Else
			Details = Details + ", " + NStr("vi = 'Phần bảng';
											|ru = 'Табличная часть';
											|en = 'Tabular section'; fa = 'Tabular section';
											|it = 'Parte di tabella';
											|pl = 'Sekcja tabelaryczna';
											|tr = 'Tablo bölümü'") + " " + TabularSectionNumber + ": " + Balance;
		EndIf;
		CurrentCount1 = Int(CurrentCount1 / 16);
		TabularSectionNumber = TabularSectionNumber + 1;
	EndDo;
	
	Return Details;
	
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
