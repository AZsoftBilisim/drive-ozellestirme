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
	
	If Common.FileInfobase() Then
		Items.WindowsArchivePath.Title = NStr("vi = 'Đối với máy chủ 1C:Enterprise dưới hệ điều hành Microsoft Windows';
												|ru = 'Для сервера 1С:Предприятия под управлением Microsoft Windows';
												|en = 'For 1C:Enterprise server on Microsoft Windows'; fa = 'برای سرور 1C:Enterprise روی Microsoft Windows';
												|it = 'Per il server 1C:Enterprise basato su Microsoft Windows';
												|pl = 'Dla serwera 1C:Enterprise z systemem Microsoft Windows';
												|tr = 'Microsoft Windows sisteminde 1C:Enterprise sunucusu için'"); 
	Else
		Items.WindowsArchivePath.ChoiceButton = False; 
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WindowsArchivePathStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not FilesOperationsInternalClient.Is1CEnterpriseExtensionAttached() Then
		FilesOperationsInternalClient.Show1CEnterpriseExtensionRequiredMessageBox(Undefined);
		Return;
	EndIf;
	
	Dialog = New FileDialog(FileDialogMode.Open);
	
	Dialog.Title                    = NStr("vi = 'Hãy chọn tệp';
											|ru = 'Выберите файл';
											|en = 'Select file'; fa = 'انتخاب فایل';
											|it = 'Selezionare un file';
											|pl = 'Wybierz plik';
											|tr = 'Dosya seç'");
	Dialog.FullFileName               = ?(WindowsArchivePath = "", "files.zip", WindowsArchivePath);
	Dialog.Multiselect           = False;
	Dialog.Preview      = False;
	Dialog.CheckFileExistence  = True;
	Dialog.Filter                       = NStr("vi = 'Tệp nén ZIP (*.zip)|*.zip';
												|ru = 'Архивы zip(*.zip)|*.zip';
												|en = 'ZIP archive (*.zip)|*.zip'; fa = 'ZIP archive (*.zip)|*.zip';
												|it = 'Archivi zip(*.zip)|*.zip';
												|pl = 'Archiwa zip(*.zip)|*.zip';
												|tr = 'Zip arşivleri(*.zip)|*.zip'");
	
	If Dialog.Choose() Then
		
		WindowsArchivePath = Dialog.FullFileName;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Place(Command)
	
	ClearMessages();
	
	If IsBlankString(WindowsArchivePath) And IsBlankString(PathToArchiveLinux) Then
		Text = NStr("vi = 'Chỉ định tên đầy đủ của tệp nén chứa
		                   |tệp hình ảnh ban đầu (tệp *.zip)';
		                   |ru = 'Укажите полное имя архива с
		                   |файлами начального образа (файл *.zip)';
		                   |en = 'Please specify the full name of the archive 
		                   |with initial image files (a *.zip file).'; fa = 'Please specify the full name of the archive 
		                   |with initial image files (a *.zip file).';
		                   |it = 'Indicate il nome completo dell''archivio con
		                   |i file dell''immagine iniziale (file *.zip)';
		                   |pl = 'Wskaż pełną nazwę archiwum z
		                   |plikami obrazu początkowego (plik *.zip)';
		                   |tr = 'Arşivin tam adını 
		                   |ilk görüntü dosyaları (dosya*.zip) ile belirtin'");
		CommonClient.MessageToUser(Text, , "WindowsArchivePath");
		Return;
	EndIf;
	
	If Not CommonClient.FileInfobase() Then
	
		If Not IsBlankString(WindowsArchivePath) And (Left(WindowsArchivePath, 2) <> "\\" Or StrFind(WindowsArchivePath, ":") <> 0) Then
			ErrorText = NStr("vi = 'Đường dẫn đến tệp nén chứa các tệp hình ảnh ban đầu
			                         |phải có định dạng UNC (\\servername\resource).';
			                         |ru = 'Путь к архиву с файлами начального образа
			                         |должен быть в формате UNC (\\servername\resource).';
			                         |en = 'The path to the archive with initial image files
			                         |must be in the UNC format (\\servername\resource).'; fa = 'The path to the archive with initial image files
			                         |must be in the UNC format (\\servername\resource).';
			                         |it = 'Il percorso dell''archivio con i file dell''immagine iniziale
			                         | deve essere in formato UNC (\servername\resource).';
			                         |pl = 'Ścieżka do archiwum z plikami początkowego obrazu
			                         |powinien być w formacie UNC (\\servername\resource).';
			                         |tr = 'İlk görüntü dosya arşivinin kısayolu
			                         |UNC formatında olmalı (\\servername\resource).'");
			CommonClient.MessageToUser(ErrorText, , "WindowsArchivePath");
			Return;
		EndIf;
	
	EndIf;
	
	AddFilesToVolumes();
	
	NotificationText1 = NStr("vi = 'Đã hoàn tất thành công việc đặt tệp từ kho lưu trữ với tệp
		| của hình ảnh ban đầu.';
		|ru = 'Размещение файлов из архива с файлами
		|начального образа успешно завершено.';
		|en = 'Files from the initial image archive
		|are stored to volumes.'; fa = 'Files from the initial image archive
		|are stored to volumes.';
		|it = 'Il posizionamento dei file dall''archivio con i file
		|dell''immagine iniziale è stato completato con successo.';
		|pl = 'rozmieszczanie plików z archiwum z plikami
		|obrazu początkowego zostało zakończone pomyślnie.';
		|tr = 'İlk görüntü dosyaları ile 
		|arşivden dosya yerleştirme başarıyla tamamlandı.'");
	ShowUserNotification(NStr("vi = 'Sắp xếp tệp';
								|ru = 'Размещение файлов';
								|en = 'Store files'; fa = 'ذخیره فایل‌ها';
								|it = 'Posizionamento dei file';
								|pl = 'rozmieszczanie plików';
								|tr = 'Dosya yerleştirme'"),, NotificationText1);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddFilesToVolumes()
	
	FilesOperationsInVolumesInternal.AddFilesToVolumes(WindowsArchivePath, PathToArchiveLinux);
	
EndProcedure

#EndRegion
