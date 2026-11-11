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
	
	TooBigFiles = Parameters.TooBigFiles;
	
	MaxFileSize = Int(FilesOperations.MaxFileSize() / (1024 * 1024));
	
	Message = StringFunctionsClientServer.SubstituteParametersToString(
	    NStr("vi = 'Một số tệp vượt quá giới hạn kích thước (%1 Mb) và sẽ không được thêm vào kho lưu trữ.
	               |Bạn có muốn tiếp tục kết nhập không?';
	               |ru = 'Некоторые файлы превышают предельный размер (%1 Мб) и не будут добавлены в хранилище.
	               |Продолжить импорт?';
	               |en = 'Some files exceed the size limit (%1 MB) and will not be added to the storage.
	               |Do you want to continue the upload?'; fa = 'Some files exceed the size limit (%1 MB) and will not be added to the storage.
	               |Do you want to continue the upload?';
	               |it = 'Alcuni file superano il limite di dimensione massima (%1 MB) e non verranno aggiunti al deposito.
	               |Continuare l''upload?';
	               |pl = 'Niektóre pliki przekraczają limit rozmiaru (%1 MB) i nie zostaną dodane do repozytorium.
	               |Kontynuować import?';
	               |tr = 'Bazı dosyalar boyut sınırını (%1Mb) aşıyor ve depolama alanına eklenmeyecek.
	               | İçe aktarmaya devam edilsin mi?'"),
	    String(MaxFileSize) );
	
	Title = Parameters.Title;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion
